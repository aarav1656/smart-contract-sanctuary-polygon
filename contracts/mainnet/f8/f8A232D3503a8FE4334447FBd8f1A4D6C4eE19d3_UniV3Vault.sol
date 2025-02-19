// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "./Vault.sol";

/// @title Saffron Fixed Income Uniswap V3 Vault
/// @author psykeeper, supafreq, everywherebagel, maze, rx
/// @notice Vault implementation that supports Uniswap V3 adapters with two different earnings assets
contract UniV3Vault is Vault, IUniV3Vault {
  using SafeERC20 for IERC20;

  /// @notice earnings0 Settled earnings valued in adapter's token0
  uint256 public earnings0;
  /// @notice earnings1 Settled earnings valued in adapter's token1
  uint256 public earnings1;

  /// @inheritdoc IVault
  function initialize(
    uint256 _vaultId,
    uint256 _duration,
    address _adapterAddr,
    uint256 _srCapacity,
    uint256 _jrCapacity,
    address _jrAsset,
    uint256 _feePercent,
    address _feeReceiver
  ) public override(Vault, IVault) notInitialized {
    require(msg.sender == vFactory, "NF");
    super.initialize(_vaultId, _duration, _adapterAddr, _srCapacity, _jrCapacity, _jrAsset, _feePercent, _feeReceiver);
  }

  /// @notice Deposit assets into the vault
  /// @param amount Amount of asset to deposit
  /// @param tranche ID of tranche to deposit into
  /// @param data (unused)
  function deposit(
    uint256 amount,
    uint256 tranche,
    bytes calldata data
  ) public override isInitialized nonReentrant {
    // Can't deposit unless not started
    require(!isStarted, "DAS");
    require(tranche == SENIOR || tranche == JUNIOR, "T");

    if (tranche == JUNIOR) {
      // Deposit only up to capacity
      amount = (amount + jrBearerToken.totalSupply() >= jrCapacity)
        ? jrCapacity - jrBearerToken.totalSupply()
        : amount;

      require(amount > 0, "NZD"); // No Zero Deposit

      uint256 oldBalance = IERC20(jrAsset).balanceOf(address(this));
      IERC20(jrAsset).safeTransferFrom(address(msg.sender), address(this), amount);
      uint256 newBalance = IERC20(jrAsset).balanceOf(address(this));
      require(amount == newBalance - oldBalance, "NDT");

      // Mint LP tokens
      jrBearerToken.mint(address(msg.sender), amount);

      uint256[] memory amounts = new uint256[](1);
      amounts[0] = amount;
      emit FundsDeposited(amounts, tranche, msg.sender);
    }
    /* Senior Tranche */
    else {
      require(amount == 0, "OZD"); // Only Zero Deposit
      require(claimToken.totalSupply() == 0, "CTM");
      
      (uint256 amount0, uint256 amount1) = IUniV3Adapter(address(adapter)).deployCapital(msg.sender, data);
      // Mint LP token
      claimToken.mint(address(msg.sender), 1);

      uint256[] memory amounts = new uint256[](2);
      amounts[0] = amount0;
      amounts[1] = amount1;
      emit FundsDeposited(amounts, tranche, msg.sender);
    }

    // Start if we're at capacity
    if (claimToken.totalSupply() == 1 && jrBearerToken.totalSupply() == jrCapacity) {
      start();
    }
  }

  function withdraw(uint256 tranche, bytes calldata data) public override isInitialized nonReentrant {
    require(tranche == SENIOR || tranche == JUNIOR, "T");
    IUniV3Adapter adapter = IUniV3Adapter(address(adapter));

    // EARLY WITHDRAWAL

    // If not started, we can still withdraw without interest rate swap
    if (!isStarted && tranche == SENIOR) {
      uint256 amount = claimToken.balanceOf(address(msg.sender));
      require(amount > 0, "NCT");
      claimToken.burn(address(msg.sender), amount);

      (uint256 amount0, uint256 amount1) = adapter.earlyReturnCapital(msg.sender, tranche, data);

      logFundsWithdrawn(SENIOR, amount0, amount1, 2, true);
      return;
    }

    // If not started, junior tranche can still withdraw their full amount
    if (!isStarted && tranche == JUNIOR) {
      uint256 amount = jrBearerToken.balanceOf(address(msg.sender));
      jrBearerToken.burn(address(msg.sender), amount);
      IERC20(jrAsset).safeTransfer(address(msg.sender), amount);

      logFundsWithdrawn(JUNIOR, amount, 0, 1, true);
      return;
    }

    // NORMAL WITHDRAWAL

    require(isStarted && block.timestamp > endTime, "WBE"); // Withdraw before end

    uint256 amount0;
    uint256 amount1;

    // If vault is ended
    if (tranche == SENIOR) {
      // Only a senior holder can withdraw senior holdings
      uint256 bearerBalance = srBearerToken.balanceOf(msg.sender);
      require(bearerBalance > 0, "NS");
      if (!earningsSettled) {
        (earnings0, earnings1) = adapter.settleEarnings();
        earningsSettled = true;
        applyFee();
      }
      (amount0, amount1) = adapter.removeLiquidity(msg.sender, data);
      adapter.returnCapital(msg.sender, amount0, amount1, tranche);

      srBearerToken.burn(address(msg.sender), bearerBalance);

      logFundsWithdrawn(SENIOR, amount0, amount1, 2, false);
      return;
    }

    if (tranche == JUNIOR) {
      uint256 bearerBalance = jrBearerToken.balanceOf(address(msg.sender));
      require(bearerBalance > 0 || (msg.sender == feeReceiver && jrBearerToken.totalSupply() != 0), "NJ");
      if (!earningsSettled) {
        (earnings0, earnings1) = adapter.settleEarnings();
        earningsSettled = true;
        applyFee();
        if (msg.sender == feeReceiver) {
          bearerBalance = jrBearerToken.balanceOf(address(msg.sender));
        }
      }
      // determine amounts based on users bearer token amount and earnings
      amount0 = Math.mulDiv(Math.mulDiv(bearerBalance, 1e18, jrBearerToken.totalSupply()), earnings0, 1e18);
      amount1 = Math.mulDiv(Math.mulDiv(bearerBalance, 1e18, jrBearerToken.totalSupply()), earnings1, 1e18);
      earnings0 -= amount0;
      earnings1 -= amount1;
      adapter.returnCapital(msg.sender, amount0, amount1, tranche);
      jrBearerToken.burn(address(msg.sender), bearerBalance);

      logFundsWithdrawn(JUNIOR, amount0, amount1, 2, false);
      return;
    }
  }

  function logFundsWithdrawn(uint256 tranche, uint256 amount0, uint256 amount1, uint256 length, bool isEarly) internal {
    require(length == 1 || length == 2, 'ILL');

    uint256[] memory amounts = new uint256[](length);
    amounts[0] = amount0;
    if (length == 2) {
      amounts[1] = amount1;
    }
    emit FundsWithdrawn(amounts, tranche, msg.sender, isEarly);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./TrancheBearerToken.sol";
import "./adapters/AdapterBase.sol";
import "./interfaces/IVault.sol";
import "./Math.sol";

/// @title Saffron Fixed Income Vault
/// @author psykeeper, supafreq, everywherebagel, maze, rx
/// @notice Foundational contract for building vaults
/// @dev Extend this abstract class to implement Vaults
abstract contract Vault is IVault, ReentrancyGuard {
  using SafeERC20 for IERC20;
  /// @notice True when the vault is initialized, false if it isn't
  bool public initialized;
  /// @notice Vault factory address
  address public vFactory;

  /// @notice Adapter that manages senior deposit assets and associated earnings
  AdapterBase public adapter;

  /// @notice Vault identifier
  uint256 public vaultId;
  /// @notice How long assets are locked after vault starts, in seconds
  uint256 public duration;
  /// @notice End of duration; funds can be withdrawn after this time
  /// @dev Calculated when vault starts via (now + duration)
  uint256 public endTime;
  /// @inheritdoc IVault
  bool public override isStarted;
  /// @inheritdoc IVault
  bool public override earningsSettled;

  /// @notice Junior tranche ERC20 base asset
  /// @dev Senior tranche asset address is stored in the Adapter
  address public jrAsset;
  /// @inheritdoc IVault
  uint256 public override srCapacity;
  /// @notice Capacity in units of jrAsset
  uint256 public jrCapacity;

  /// @notice Saffron fee percentage cut
  uint256 public feeBps;
  /// @notice Address that collects protocol fee
  address public feeReceiver;

  /// @notice ERC20 bearer token that entitles owner to a portion of the senior tranche collateral
  TrancheBearerToken public srBearerToken;
  /// @notice ERC20 bearer token that entitles owner to a portion of the junior tranche earnings
  TrancheBearerToken public jrBearerToken;
  /// @notice ERC20 bearer token that entitles owner to a portion of the senior tranche bearer tokens
  TrancheBearerToken public claimToken;

  uint256 constant SENIOR = 0;
  uint256 constant JUNIOR = 1;

  /// @notice Emitted when funds are deposited into vault
  /// @param amounts Amounts deposited
  /// @param tranche Senior or Junior tranches (0 or 1)
  /// @param user Address of user
  event FundsDeposited(uint256[] amounts, uint256 tranche, address indexed user);

  /// @notice Emitted when funds are withdrawn from vault
  /// @param amounts Amounts withdrawn
  /// @param tranche Senior or Junior tranches (0 or 1)
  /// @param user Address of user
  event FundsWithdrawn(uint256[] amounts, uint256 tranche, address indexed user, bool indexed isEarly);

  /// @notice Emitted when Vault has filled and moved into the Started phase
  /// @param timestamp Time started
  /// @param user Address of user
  event VaultStarted(uint256 timestamp, address indexed user);

  /// @notice Emitted when Vault has past its expiration time and moved into the Ended phase
  /// @param timestamp Time started
  /// @param user Address of user
  event VaultEnded(uint256 timestamp, address indexed user);

  /// @dev Vault factory will always be msg.sender
  constructor() {
    vFactory = msg.sender;
  }

  modifier notInitialized() {
    require(!initialized, "AI");
    _;
  }

  modifier isInitialized() {
    require(initialized, "NI");
    _;
  }
  /// @inheritdoc IVault
  function initialize(
    uint256 _vaultId,
    uint256 _duration,
    address _adapterAddr,
    uint256 _srCapacity,
    uint256 _jrCapacity,
    address _jrAsset,
    uint256 _feeBps,
    address _feeReceiver
  ) public virtual override notInitialized {
    require(msg.sender == vFactory, "NF");
    /// vaultId is already checked in the VaultFactory
    require(_duration != 0, "NZI");
    require(_adapterAddr != address(0), "NZI");
    require(_jrCapacity != 0, "NZI");
    require(_srCapacity != 0, "NZI");
    require(_jrAsset != address(0), "NZI");
    require(_feeReceiver != address(0), "NZI");

    adapter = AdapterBase(_adapterAddr);
    require(adapter.factoryAddress() == vFactory, "AWF");

    initialized = true;
    vaultId = _vaultId;
    duration = _duration;
    jrAsset = _jrAsset;
    feeBps = _feeBps;
    feeReceiver = _feeReceiver;

    srCapacity = _srCapacity;
    jrCapacity = _jrCapacity;

    srBearerToken = new TrancheBearerToken("Saffron Vault Senior Bearer Token", "SAFF-BT");
    jrBearerToken = new TrancheBearerToken("Saffron Vault Junior Bearer Token", "SAFF-BT");
    claimToken = new TrancheBearerToken("Saffron Vault Senior Claim Token", "SAFF-CT");
  }

  /// @notice Claim senior bearer tokens with senior claim tokens
  function claim() public virtual isInitialized nonReentrant {
    require(isStarted, "CBS");


    // Cache balance for gas savings
    uint256 claimBal = claimToken.balanceOf(address(msg.sender));

    // Senior depositor gets a proportional share of the total junior deposits (their premium)
    // uint256 amount = claimBal * 1e18 / claimToken.totalSupply() * IERC20(jrAsset).balanceOf(address(this)) / 1e18;
    require(claimBal > 0, "NCT"); // No claim tokens
    uint256 amount = Math.mulDiv(
      Math.mulDiv(claimBal, 1e18, claimToken.totalSupply()),
      IERC20(jrAsset).balanceOf(address(this)),
      1e18
    );
    IERC20(jrAsset).safeTransfer(address(msg.sender), amount);

    // Mint LP token
    srBearerToken.mint(address(msg.sender), claimBal);

    // Burn claim tokens
    claimToken.burn(address(msg.sender), claimBal);
  }

  function start() internal virtual {
    isStarted = true;
    endTime = block.timestamp + duration;
    emit VaultStarted(block.timestamp, msg.sender);
  }

  function applyFee() internal virtual {
    uint256 fee = Math.mulDiv(jrBearerToken.totalSupply(), feeBps, 10_000 - feeBps);

    if (fee > 0) {
      // Mint LP tokens for fees
      jrBearerToken.mint(feeReceiver, fee);
    }
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @title Saffron Fixed Income Vault Bearer Token
/// @author psykeeper, supafreq, everywherebagel, maze, rx
/// @notice Vaults create these tokens to give Vault participants fungible ownership of their positions
contract TrancheBearerToken is ERC20 {
  /// @notice The address of the vault that owns this token
  address public vault;

  constructor(string memory name, string memory symbol) ERC20(name, symbol) {
    vault = msg.sender;
  }

  /// @notice Mints SAFF-BT tokens
  /// @param _to The address to mint to
  /// @param _amount The amount to mint
  /// @dev Only the owning vault can do this
  function mint(address _to, uint256 _amount) external {
    require(msg.sender == vault, "OVM");
    require(_amount > 0, "NZI");
    _mint(_to, _amount);
  }

  /// @notice Burns SAFF-BT tokens
  /// @param _account The address to burn from
  /// @param _amount The amount to burn
  /// @dev Only the owning vault can do this
  function burn(address _account, uint256 _amount) public {
    require(msg.sender == vault, "OVB");
    require(_amount > 0, "NZI");
    _burn(_account, _amount);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "../interfaces/IAdapter.sol";

/// @title Saffron Fixed Income Adapter
/// @author psykeeper, supafreq, everywherebagel, maze, rx
/// @notice Foundational contract for building Adapters
/// @dev Extend this abstract class to implement Adapters
abstract contract AdapterBase is IAdapter {
  /// @notice Address of vault associated with this adapter
  address public vaultAddress;

  /// @notice Address of factory that created this adapter
  address public factoryAddress;

  constructor() {
    factoryAddress = msg.sender;
  }

  modifier onlyWithoutVaultAttached() {
    require(vaultAddress == address(0x0), "NVA");
    _;
  }

  modifier onlyWithVaultAttached() {
    require(vaultAddress != address(0x0), "VA");
    _;
  }

  modifier onlyFactory() {
    require(factoryAddress == msg.sender, "NF");
    _;
  }

  modifier onlyVault() {
    require(vaultAddress == msg.sender, "NV");
    _;
  }

  /// @inheritdoc IAdapter
  function setVault(address _vaultAddress) virtual public override onlyWithoutVaultAttached onlyFactory {
    require(_vaultAddress != address(0), "NZI");
    vaultAddress = _vaultAddress;
  }

  /// @inheritdoc IAdapter
  function hasAccurateHoldings() virtual public view override returns (bool) {
    this;
    return true;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

/// @title Saffron Fixed Income Vault Interface
/// @author psykeeper, supafreq, everywherebagel, maze, rx
/// @notice Base interface for vaults
/// @dev When implementing new vault types, extend the abstract contract Vault
interface IVault {
  /// @notice Capacity of senior tranche
  /// @return Amount in units of adapter baseAsset
  function srCapacity() external view returns (uint256);

  /// @notice Vault initializer, runs upon vault creation
  /// @dev This is called by the parent factory's initializeVault function. Make sure that only the factory can call.
  function initialize(
    uint256 _vaultId,
    uint256 _duration,
    address _adapterAddr,
    uint256 _srCapacity,
    uint256 _jrCapacity,
    address _jrAsset,
    uint256 _feePercent,
    address _feeReceiver
  ) external;

  /// @notice Deposit assets into the vault
  /// @param amount Amount of asset to deposit
  /// @param tranche ID of tranche to deposit into
  /// @param data Data to pass, vault implementation dependent
  function deposit(
    uint256 amount,
    uint256 tranche,
    bytes calldata data
  ) external;

  /// @notice Withdraw assets out of the vault
  /// @param tranche ID of tranche to withdraw from
  /// @param data Data to pass, vault implementation dependent
  function withdraw(uint256 tranche, bytes calldata data) external;

  /// @notice Boolean indicating whether or not the vault has settled its earnings
  /// @return True if earnings are settled, false if not
  function earningsSettled() external view returns (bool);

  /// @notice Vault started state
  /// @return True if started, false if not
  function isStarted() external view returns (bool);
}

interface ISingleVault is IVault {}

interface IUniV3Vault is IVault {}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;



/// @title Math utility functions
/// @notice Collection of useful math functions
library Math {
  /// @notice Multiplies two numbers and divides the result
  /// @param a First multiplicand
  /// @param b Second multiplicand
  /// @param denominator Divisor
  /// @dev Author: Remco Bloemen - https://2π.com/21/muldiv/index.html - MIT License
  function mulDiv(
    uint256 a,
    uint256 b,
    uint256 denominator
  ) internal pure returns (uint256 result) {
    unchecked {
      // Handle division by zero
      require(denominator > 0);

      // 512-bit multiply [prod1 prod0] = a * b
      // Compute the product mod 2**256 and mod 2**256 - 1
      // then use the Chinese Remainder Theorem to reconstruct
      // the 512 bit result. The result is stored in two 256
      // variables such that product = prod1 * 2**256 + prod0
      uint256 prod0;
      // Least significant 256 bits of the product
      uint256 prod1;
      // Most significant 256 bits of the product
      assembly {
        let mm := mulmod(a, b, not(0))
        prod0 := mul(a, b)
        prod1 := sub(sub(mm, prod0), lt(mm, prod0))
      }

      // Short circuit 256 by 256 division
      // This saves gas when a * b is small, at the cost of making the
      // large case a bit more expensive. Depending on your use case you
      // may want to remove this short circuit and always go through the
      // 512 bit path.
      if (prod1 == 0) {
        assembly {
          result := div(prod0, denominator)
        }
        return result;
      }

      ///////////////////////////////////////////////
      // 512 by 256 division.
      ///////////////////////////////////////////////

      // Handle overflow, the result must be < 2**256
      require(prod1 < denominator);

      // Make division exact by subtracting the remainder from [prod1 prod0]
      // Compute remainder using mulmod
      // Note mulmod(_, _, 0) == 0
      uint256 remainder;
      assembly {
        remainder := mulmod(a, b, denominator)
      }
      // Subtract 256 bit number from 512 bit number
      assembly {
        prod1 := sub(prod1, gt(remainder, prod0))
        prod0 := sub(prod0, remainder)
      }

      // Factor powers of two out of denominator
      // Compute largest power of two divisor of denominator.
      // Always >= 1 unless denominator is zero, then twos is zero.
      uint256 twos = (0 - denominator) & denominator;
      // Divide denominator by power of two
      assembly {
        denominator := div(denominator, twos)
      }

      // Divide [prod1 prod0] by the factors of two
      assembly {
        prod0 := div(prod0, twos)
      }
      // Shift in bits from prod1 into prod0. For this we need
      // to flip `twos` such that it is 2**256 / twos.
      // If twos is zero, then it becomes one
      assembly {
        twos := add(div(sub(0, twos), twos), 1)
      }
      prod0 |= prod1 * twos;

      // Invert denominator mod 2**256
      // Now that denominator is an odd number, it has an inverse
      // modulo 2**256 such that denominator * inv = 1 mod 2**256.
      // Compute the inverse by starting with a seed that is correct
      // correct for four bits. That is, denominator * inv = 1 mod 2**4
      // If denominator is zero the inverse starts with 2
      uint256 inv = (3 * denominator) ^ 2;
      // Now use Newton-Raphson iteration to improve the precision.
      // Thanks to Hensel's lifting lemma, this also works in modular
      // arithmetic, doubling the correct bits in each step.
      // inverse mod 2**8
      inv *= 2 - denominator * inv;
      // inverse mod 2**16
      inv *= 2 - denominator * inv;
      // inverse mod 2**32
      inv *= 2 - denominator * inv;
      // inverse mod 2**64
      inv *= 2 - denominator * inv;
      // inverse mod 2**128
      inv *= 2 - denominator * inv;
      // inverse mod 2**256
      inv *= 2 - denominator * inv;
      // If denominator is zero, inv is now 128

      // Because the division is now exact we can divide by multiplying
      // with the modular inverse of denominator. This will give us the
      // correct result modulo 2**256. Since the preconditions guarantee
      // that the outcome is less than 2**256, this is the final result.
      // We don't need to compute the high bits of the result and prod1
      // is no longer required.
      result = prod0 * inv;
      return result;
    }
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

/// @title Saffron Fixed Income Adapter
/// @author psykeeper, supafreq, everywherebagel, maze, rx
/// @notice Manages funds deposited into vaults to generate yield
interface IAdapter {
  /// @notice Used to determine whether the asset balance that is returned from holdings() is representative of all the funds that this adapter maintains.
  /// @return True if holdings() is all-inclusive
  function hasAccurateHoldings() external view returns (bool);

  /// @notice Sets the vault ID that this adapter maintains assets for
  /// @param _vault Address of vault
  /// @dev Make sure this is only callable by the vault factory
  function setVault(address _vault) external;

  /// @notice Initializes the adapter
  /// @param id ID of adapter
  /// @param base Address of base asset
  /// @param data Data to pass, adapter implementation dependent
  /// @dev Make sure this is only callable by the vault creator
  function initialize(
    uint256 id,
    address base,
    uint256 depositTolerance,
    bytes calldata data
  ) external;
}

/// @title Saffron Fixed Income Single-Asset Adapter
/// @author psykeeper, supafreq, everywherebagel, maze, rx
/// @notice Manages a single asset deposited into vaults to generate yield
interface ISingleAdapter is IAdapter {
  /// @notice Deposit asset into underlying yield-generating contract
  /// @param user Address of user depositing asset
  /// @param amount Amount of asset being deposited
  /// @dev User should approve this adapter the appropriate transfer amount of asset before use
  function deployCapital(address user, uint256 amount) external;

  /// @notice Return asset back to user from underlying yield-generating contract
  /// @param to User to receive assets
  /// @param amount Amount user will receive
  /// @param data Data to pass, implementation dependent
  function returnCapital(
    address to,
    uint256 amount,
    bytes calldata data
  ) external;

  /// @notice Expected holdings, estimated due to lack of guarantees, used to give user some expectation of value
  /// @return estimate Estimated amount of holdings
  /// @dev Do not depend on this value to be guaranteed! In cases where exact holdings can be known, simply return holdings().
  function estimatedHoldings() external view returns (uint256 estimate);

  /// @notice Exact holdings value
  /// @return amount Amount of holdings
  /// @dev If a guaranteed value cannot be determined, an error should be thrown.
  function holdings() external view returns (uint256 amount);

  /// @notice Address of base asset used by adapter
  /// @return asset Base asset address
  function assetAddress() external view returns (address asset);

  /// @notice Collect earnings from underlying yield-generating contract and finalize earnings balance
  /// @param data Data to pass, implementation dependent
  /// @return Total earnings to be distributed to vault participants
  function settleEarnings(bytes calldata data) external returns (uint256);
}

/// @title Saffron Fixed Income Uniswap V3 Adapter
/// @author psykeeper, supafreq, everywherebagel, maze, rx
/// @notice Manages a pair of assets deposited into Uniswap V3 vaults
interface IUniV3Adapter is IAdapter {
  /// @notice Deposit assets into Uniswap V3 position
  /// @param user Address of user depositing assets
  /// @param data Used for data required to mint a Uniswap V3 position
  /// @return amount0 Amount of asset 0 deployed
  /// @return amount1 Amount of asset 1 deployed
  /// @dev User should approve this adapter the appropriate transfer amounts of underlying assets before use
  function deployCapital(address user, bytes calldata data) external returns (uint256 amount0, uint256 amount1);

  /// @notice Return assets back to user that have been withdrawn from Uniswap V3 position
  /// @param to User to receive assets
  /// @param amount0 Amount of token0 user will receive
  /// @param amount1 Amount of token1 user will receive
  /// @param tranche ID of tranche
  /// @dev Should only be callable by the vault, and should only be called during the withdraw process
  function returnCapital(
    address to,
    uint256 amount0,
    uint256 amount1,
    uint256 tranche
  ) external;

  /// @notice Return asset back to user before vault starts
  /// @param to User to receive assets
  /// @param tranche ID of tranche
  /// @dev This is needed because any earnings generated before the vault starts are entitled to the senior depositors
  function earlyReturnCapital(
    address to,
    uint256 tranche,
    bytes calldata data
  ) external returns (uint256, uint256);

  /// @notice Expected holdings, estimated due to lack of guarantees, used to give user some expectation of value
  /// @return estimate0 Estimated amount of holdings of token0
  /// @return estimate1 Estimated amount of holdings of token1
  /// @dev Do not depend on these values to be guaranteed! In cases where exact holdings can be known, simply return holdings().
  function estimatedHoldings() external view returns (uint256 estimate0, uint256 estimate1);

  /// @notice Exact holdings values
  /// @return amount0 Amount of holdings of token0
  /// @return amount1 Amount of holdings of token1
  /// @dev If guaranteed values cannot be determined, an error should be thrown.
  function holdings() external view returns (uint256 amount0, uint256 amount1);

  /// @notice Token addresses of token0 and token1
  /// @return token0 Address of token0
  /// @return token1 Address of token1
  function assetAddresses() external view returns (address token0, address token1);

  /// @notice Get current earnings for asset0 and asset1
  /// @return asset0 earnings
  /// @return asset1 earnings
  function getEarnings() external view returns (uint256, uint256);

  /// @notice Collect earnings from Uniswap V3 position and finalize earnings balance
  /// @return Total earnings of asset0 to be distributed to vault participants
  /// @return Total earnings of asset1 to be distributed to vault participants
  function settleEarnings() external returns (uint256, uint256);

  /// @notice Removes liquidity from Uniswap V3 position
  /// @param to Receiver of liquidity
  /// @param data Data passed to Uniswap V3 needed to remove liquidity
  function removeLiquidity(address to, bytes calldata data) external returns (uint256, uint256);
}