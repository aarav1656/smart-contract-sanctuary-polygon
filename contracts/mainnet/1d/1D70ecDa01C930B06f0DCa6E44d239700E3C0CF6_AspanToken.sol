//SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import {IERC20} from "../dependencies/openzeppelin/contracts/IERC20.sol";
import {GPv2SafeERC20} from "../dependencies/gnosis/contracts/GPv2SafeERC20.sol";
import {SafeCast} from "../dependencies/openzeppelin/contracts/SafeCast.sol";
import {Errors} from "../dependencies/helpers/Errors.sol";
import {WadRayMath} from "../dependencies/math/WadRayMath.sol";
import {IVault} from "../IVault.sol";
import {IAspanToken} from "./IAspanToken.sol";
import {IInitializableAspanToken} from "./IInitializableAspanToken.sol";
import {EIP712Base} from "../dependencies/openzeppelin/contracts/EIP712Base.sol";
import {ERC20} from "../dependencies/openzeppelin/contracts/ERC20.sol";
import {IPoolAddressesProvider} from "../dependencies/openzeppelin/contracts/IPoolAddressesProvider.sol";
import {IACLManager} from "../dependencies/openzeppelin/contracts/IACLManager.sol";

contract AspanToken is IAspanToken, ERC20, EIP712Base {
    using WadRayMath for uint256;
    using SafeCast for uint256;
    using GPv2SafeERC20 for IERC20;

    bytes32 public constant PERMIT_TYPEHASH =
        keccak256(
            "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
        );

    /**
     * @dev Only vault admin can call functions marked by this modifier.
     **/
    modifier onlyVaultAdmin() {
        //require(_msgSender() == address(), Errors.CALLER_MUST_BE_POOL);
        _;
    }

    /**
     * @dev Only vault can call functions marked by this modifier.
     **/
    modifier onlyVault() {
        require(_msgSender() == address(VAULT), Errors.CALLER_MUST_BE_POOL);
        _;
    }

    address internal _treasury;
    uint256 internal _aspanPrice; // in USDC
    //IPoolAddressesProvider internal immutable _addressesProvider;
    IVault public immutable VAULT;

    //ITokenPriceOracle internal oracle;

    /**
     * @dev Constructor.
     * @param vaultAddress The address of the vault
     */
    constructor(address vaultAddress) ERC20("AspanToken_IMPL", "AspanToken_IMPL") EIP712Base() {
        //_addressesProvider = pool.ADDRESSES_PROVIDER();
        VAULT = IVault(vaultAddress);
    }

    /// @inheritdoc IInitializableAspanToken
    function initialize(
        IVault initializingVault,
        address treasury,
        uint8 AspanTokenDecimals,
        string calldata AspanTokenName,
        string calldata AspanTokenSymbol,
        bytes calldata params
    ) external override {
        require(initializingVault == VAULT, Errors.POOL_ADDRESSES_DO_NOT_MATCH);
        _setName(AspanTokenName);
        _setSymbol(AspanTokenSymbol);
        _setDecimals(AspanTokenDecimals);

        _treasury = treasury;

        _domainSeparator = _calculateDomainSeparator();

        emit Initialized(
            address(VAULT),
            treasury,
            AspanTokenDecimals,
            AspanTokenName,
            AspanTokenSymbol,
            params
        );
    }

    /// @inheritdoc IAspanToken
    function mint(
        address caller,
        address onBehalfOf,
        uint256 amount
    ) external override onlyVault {
        _mintAspan(caller, onBehalfOf, amount);
        return;
    }

    function _mintAspan(
        address caller,
        address onBehalfOf,
        uint256 amount
    ) internal {
        require(amount != 0, Errors.INVALID_MINT_AMOUNT);
        emit Mint(caller, onBehalfOf, amount);
        _mint(onBehalfOf, amount);
        return;
    }

    /// @inheritdoc IAspanToken
    function burn(
        address from,
        address receiverOfUnderlying,
        uint256 amount
    ) external override onlyVault {
        _burnAspan(from, receiverOfUnderlying, amount);
    }

    function _burnAspan(
        address from,
        address receiverOfUnderlying,
        uint256 amount
    ) internal {
        require(amount != 0, Errors.INVALID_BURN_AMOUNT);
        _burn(from, amount);
        emit Burn(from, receiverOfUnderlying, amount);
    }

    /// @inheritdoc IAspanToken
    function mintToTreasury(uint256 amount) external override onlyVault {
        if (amount == 0) {
            return;
        }
        _mintAspan(address(VAULT), _treasury, amount);
    }

    /// @inheritdoc IAspanToken
    function transferOnLiquidation(
        address from,
        address to,
        uint256 value
    ) external override onlyVault {
        //intentially left blank
    }

    /// @inheritdoc IAspanToken
    function RESERVE_TREASURY_ADDRESS() external view override returns (address) {
        return _treasury;
    }

    /// @inheritdoc IAspanToken
    function handleRepayment(address user, uint256 amount) external virtual override onlyVault {
        // Intentionally left blank
    }

    /**
     * @notice Overrides the parent _transfer to force validated transfer() and transferFrom()
     * @param from The source address
     * @param to The destination address
     * @param amount The amount getting transferred
     **/
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal pure override {
        //intentially left blank
    }

    /**
     * @dev Overrides the base function to fully implement IAToken
     * @dev see `IncentivizedERC20.DOMAIN_SEPARATOR()` for more detailed documentation
     */
    function DOMAIN_SEPARATOR() public view override(IAspanToken, EIP712Base) returns (bytes32) {
        return super.DOMAIN_SEPARATOR();
    }

    /**
     * @dev Overrides the base function to fully implement AspanToken
     * @dev see `IncentivizedERC20.nonces()` for more detailed documentation
     */
    function nonces(address owner) public view override(IAspanToken, EIP712Base) returns (uint256) {
        return super.nonces(owner);
    }

    /// @inheritdoc EIP712Base
    function _EIP712BaseId() internal view override returns (string memory) {
        return name();
    }

    function rescueTokens(
        address token,
        address to,
        uint256 amount
    ) external override onlyVaultAdmin {
        //intentially left blank
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IVault {
    event Deposit(address user, uint256 aspanBalance, uint256 usdcDeposited);
    event Withdraw(address user, uint256 aspanBurned, uint256 usdcWithdrew);

    function deposit(
        uint256 _amount,
        bytes calldata dc2dtSwapCallData,
        bytes calldata dc2daiSwapCallData
    ) external;

    function withdraw(
        uint256 aspanTokenAmount,
        bytes calldata dt2dcSwapCallData,
        bytes calldata dai2dcSwapCallData
    ) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {IERC20} from '../dependencies/openzeppelin/contracts/IERC20.sol';
import {IInitializableAspanToken} from './IInitializableAspanToken.sol';

/**
 * @title IAspanToken
 * @author BuzzCai.eth
 * @notice Defines the basic interface for an AspanToken.
 **/
interface IAspanToken is IERC20, IInitializableAspanToken {
  /**
   * @dev Emitted during the transfer action
   * @param from The user whose tokens are being transferred
   * @param to The recipient
   * @param value The amount being transferred
   **/
  event BalanceTransfer(address indexed from, address indexed to, uint256 value);

  /**
   * @dev Emitted after the mint action
   * @param caller The address performing the mint
   * @param onBehalfOf The address of the user that will receive the minted tokens
   * @param value The amount being minted (user entered amount + balance increase from interest)
   **/
  event Mint(
    address indexed caller,
    address indexed onBehalfOf,
    uint256 value
  );

  /**
   * @dev Emitted after scaled balance tokens are burned
   * @param from The address from which the scaled tokens will be burned
   * @param target The address that will receive the underlying, if any
   * @param value The amount being burned (user entered amount - balance increase from interest)
   **/
  event Burn(
    address indexed from,
    address indexed target,
    uint256 value
  );

  /**
   * @notice Mints `amount` AspanTokens to `user`
   * @param caller The address performing the mint
   * @param onBehalfOf The address of the user that will receive the minted AspanTokens
   * @param amount The amount of tokens getting minted
   */
  function mint(
    address caller,
    address onBehalfOf,
    uint256 amount
  ) external;

  /**
   * @notice Burns AspanTokens from `user` and sends the equivalent amount of underlying to `receiverOfUnderlying`
   * @dev In some instances, the mint event could be emitted from a burn transaction
   * if the amount to burn is less than the interest that the user accrued
   * @param from The address from which the AspanTokens will be burned
   * @param receiverOfUnderlying The address that will receive the underlying
   * @param amount The amount being burned
   **/
  function burn(
    address from,
    address receiverOfUnderlying,
    uint256 amount
  ) external;

  /**
   * @notice Mints AspanTokens to the reserve treasury
   * @param amount The amount of tokens getting minted
   */
  function mintToTreasury(uint256 amount) external;

  /**
   * @notice Transfers AspanTokens in the event of a borrow being liquidated, in case the liquidators reclaims the AspanToken
   * @param from The address getting liquidated, current owner of the AspanTokens
   * @param to The recipient
   * @param value The amount of tokens getting transferred
   **/
  function transferOnLiquidation(
    address from,
    address to,
    uint256 value
  ) external;

  /**
   * @notice Handles the underlying received by the AspanToken after the transfer has been completed.
   * @dev The default implementation is empty as with standard ERC20 tokens, nothing needs to be done after the
   * transfer is concluded. However in the future there may be AspanTokens that allow for example to stake the underlying
   * to receive LM rewards. In that case, `handleRepayment()` would perform the staking of the underlying asset.
   * @param user The user executing the repayment
   * @param amount The amount getting repaid
   **/
  function handleRepayment(address user, uint256 amount) external;

  /**
   * @notice Returns the address of the Aave treasury, receiving the fees on this AspanToken.
   * @return Address of the Aave treasury
   **/
  function RESERVE_TREASURY_ADDRESS() external view returns (address);

  /**
   * @notice Get the domain separator for the token
   * @dev Return cached value if chainId matches cache, otherwise recomputes separator
   * @return The domain separator of the token at current chain
   */
  function DOMAIN_SEPARATOR() external view returns (bytes32);

  /**
   * @notice Returns the nonce for owner.
   * @param owner The address of the owner
   * @return The nonce of the owner
   **/
  function nonces(address owner) external view returns (uint256);

  /**
   * @notice Rescue and transfer tokens locked in this contract
   * @param token The address of the token
   * @param to The address of the recipient
   * @param amount The amount of token to transfer
   */
  function rescueTokens(
    address token,
    address to,
    uint256 amount
  ) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {IVault} from '../IVault.sol';

/**
 * @title IInitializableAspanToken
 * @author BuzzCai.eth
 * @notice Interface for the initialize function on AspanToken
 **/
interface IInitializableAspanToken {
  /**
   * @dev Emitted when an AspanToken is initialized
   * @param vault The address of the associated vault
   * @param treasury The address of the treasury
   * @param AspanTokenDecimals The decimals of the underlying
   * @param AspanTokenName The name of the AspanToken
   * @param AspanTokenSymbol The symbol of the AspanToken
   * @param params A set of encoded parameters for additional initialization
   **/
  event Initialized(
    address indexed vault,
    address treasury,
    uint8 AspanTokenDecimals,
    string AspanTokenName,
    string AspanTokenSymbol,
    bytes params
  );

  /**
   * @notice Initializes the AspanToken
   * @param vault The vault contract that is initializing this contract
   * @param treasury The address of the Aave treasury, receiving the fees on this AspanToken
   * @param AspanTokenDecimals The decimals of the AspanToken, same as the underlying asset's
   * @param AspanTokenName The name of the AspanToken
   * @param AspanTokenSymbol The symbol of the AspanToken
   * @param params A set of encoded parameters for additional initialization
   */
  function initialize(
    IVault vault,
    address treasury,
    uint8 AspanTokenDecimals,
    string calldata AspanTokenName,
    string calldata AspanTokenSymbol,
    bytes calldata params
  ) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

/**
 * @title Errors library
 * @author Aave
 * @notice Defines the error messages emitted by the different contracts of the Aave protocol
 */
library Errors {
  string public constant CALLER_NOT_POOL_ADMIN = '1'; // 'The caller of the function is not a pool admin'
  string public constant CALLER_NOT_EMERGENCY_ADMIN = '2'; // 'The caller of the function is not an emergency admin'
  string public constant CALLER_NOT_POOL_OR_EMERGENCY_ADMIN = '3'; // 'The caller of the function is not a pool or emergency admin'
  string public constant CALLER_NOT_RISK_OR_POOL_ADMIN = '4'; // 'The caller of the function is not a risk or pool admin'
  string public constant CALLER_NOT_ASSET_LISTING_OR_POOL_ADMIN = '5'; // 'The caller of the function is not an asset listing or pool admin'
  string public constant CALLER_NOT_BRIDGE = '6'; // 'The caller of the function is not a bridge'
  string public constant ADDRESSES_PROVIDER_NOT_REGISTERED = '7'; // 'Pool addresses provider is not registered'
  string public constant INVALID_ADDRESSES_PROVIDER_ID = '8'; // 'Invalid id for the pool addresses provider'
  string public constant NOT_CONTRACT = '9'; // 'Address is not a contract'
  string public constant CALLER_NOT_POOL_CONFIGURATOR = '10'; // 'The caller of the function is not the pool configurator'
  string public constant CALLER_NOT_ATOKEN = '11'; // 'The caller of the function is not an AToken'
  string public constant INVALID_ADDRESSES_PROVIDER = '12'; // 'The address of the pool addresses provider is invalid'
  string public constant INVALID_FLASHLOAN_EXECUTOR_RETURN = '13'; // 'Invalid return value of the flashloan executor function'
  string public constant RESERVE_ALREADY_ADDED = '14'; // 'Reserve has already been added to reserve list'
  string public constant NO_MORE_RESERVES_ALLOWED = '15'; // 'Maximum amount of reserves in the pool reached'
  string public constant EMODE_CATEGORY_RESERVED = '16'; // 'Zero eMode category is reserved for volatile heterogeneous assets'
  string public constant INVALID_EMODE_CATEGORY_ASSIGNMENT = '17'; // 'Invalid eMode category assignment to asset'
  string public constant RESERVE_LIQUIDITY_NOT_ZERO = '18'; // 'The liquidity of the reserve needs to be 0'
  string public constant FLASHLOAN_PREMIUM_INVALID = '19'; // 'Invalid flashloan premium'
  string public constant INVALID_RESERVE_PARAMS = '20'; // 'Invalid risk parameters for the reserve'
  string public constant INVALID_EMODE_CATEGORY_PARAMS = '21'; // 'Invalid risk parameters for the eMode category'
  string public constant BRIDGE_PROTOCOL_FEE_INVALID = '22'; // 'Invalid bridge protocol fee'
  string public constant CALLER_MUST_BE_POOL = '23'; // 'The caller of this function must be a pool'
  string public constant INVALID_MINT_AMOUNT = '24'; // 'Invalid amount to mint'
  string public constant INVALID_BURN_AMOUNT = '25'; // 'Invalid amount to burn'
  string public constant INVALID_AMOUNT = '26'; // 'Amount must be greater than 0'
  string public constant RESERVE_INACTIVE = '27'; // 'Action requires an active reserve'
  string public constant RESERVE_FROZEN = '28'; // 'Action cannot be performed because the reserve is frozen'
  string public constant RESERVE_PAUSED = '29'; // 'Action cannot be performed because the reserve is paused'
  string public constant BORROWING_NOT_ENABLED = '30'; // 'Borrowing is not enabled'
  string public constant STABLE_BORROWING_NOT_ENABLED = '31'; // 'Stable borrowing is not enabled'
  string public constant NOT_ENOUGH_AVAILABLE_USER_BALANCE = '32'; // 'User cannot withdraw more than the available balance'
  string public constant INVALID_INTEREST_RATE_MODE_SELECTED = '33'; // 'Invalid interest rate mode selected'
  string public constant COLLATERAL_BALANCE_IS_ZERO = '34'; // 'The collateral balance is 0'
  string public constant HEALTH_FACTOR_LOWER_THAN_LIQUIDATION_THRESHOLD = '35'; // 'Health factor is lesser than the liquidation threshold'
  string public constant COLLATERAL_CANNOT_COVER_NEW_BORROW = '36'; // 'There is not enough collateral to cover a new borrow'
  string public constant COLLATERAL_SAME_AS_BORROWING_CURRENCY = '37'; // 'Collateral is (mostly) the same currency that is being borrowed'
  string public constant AMOUNT_BIGGER_THAN_MAX_LOAN_SIZE_STABLE = '38'; // 'The requested amount is greater than the max loan size in stable rate mode'
  string public constant NO_DEBT_OF_SELECTED_TYPE = '39'; // 'For repayment of a specific type of debt, the user needs to have debt that type'
  string public constant NO_EXPLICIT_AMOUNT_TO_REPAY_ON_BEHALF = '40'; // 'To repay on behalf of a user an explicit amount to repay is needed'
  string public constant NO_OUTSTANDING_STABLE_DEBT = '41'; // 'User does not have outstanding stable rate debt on this reserve'
  string public constant NO_OUTSTANDING_VARIABLE_DEBT = '42'; // 'User does not have outstanding variable rate debt on this reserve'
  string public constant UNDERLYING_BALANCE_ZERO = '43'; // 'The underlying balance needs to be greater than 0'
  string public constant INTEREST_RATE_REBALANCE_CONDITIONS_NOT_MET = '44'; // 'Interest rate rebalance conditions were not met'
  string public constant HEALTH_FACTOR_NOT_BELOW_THRESHOLD = '45'; // 'Health factor is not below the threshold'
  string public constant COLLATERAL_CANNOT_BE_LIQUIDATED = '46'; // 'The collateral chosen cannot be liquidated'
  string public constant SPECIFIED_CURRENCY_NOT_BORROWED_BY_USER = '47'; // 'User did not borrow the specified currency'
  string public constant SAME_BLOCK_BORROW_REPAY = '48'; // 'Borrow and repay in same block is not allowed'
  string public constant INCONSISTENT_FLASHLOAN_PARAMS = '49'; // 'Inconsistent flashloan parameters'
  string public constant BORROW_CAP_EXCEEDED = '50'; // 'Borrow cap is exceeded'
  string public constant SUPPLY_CAP_EXCEEDED = '51'; // 'Supply cap is exceeded'
  string public constant UNBACKED_MINT_CAP_EXCEEDED = '52'; // 'Unbacked mint cap is exceeded'
  string public constant DEBT_CEILING_EXCEEDED = '53'; // 'Debt ceiling is exceeded'
  string public constant ATOKEN_SUPPLY_NOT_ZERO = '54'; // 'AToken supply is not zero'
  string public constant STABLE_DEBT_NOT_ZERO = '55'; // 'Stable debt supply is not zero'
  string public constant VARIABLE_DEBT_SUPPLY_NOT_ZERO = '56'; // 'Variable debt supply is not zero'
  string public constant LTV_VALIDATION_FAILED = '57'; // 'Ltv validation failed'
  string public constant INCONSISTENT_EMODE_CATEGORY = '58'; // 'Inconsistent eMode category'
  string public constant PRICE_ORACLE_SENTINEL_CHECK_FAILED = '59'; // 'Price oracle sentinel validation failed'
  string public constant ASSET_NOT_BORROWABLE_IN_ISOLATION = '60'; // 'Asset is not borrowable in isolation mode'
  string public constant RESERVE_ALREADY_INITIALIZED = '61'; // 'Reserve has already been initialized'
  string public constant USER_IN_ISOLATION_MODE = '62'; // 'User is in isolation mode'
  string public constant INVALID_LTV = '63'; // 'Invalid ltv parameter for the reserve'
  string public constant INVALID_LIQ_THRESHOLD = '64'; // 'Invalid liquidity threshold parameter for the reserve'
  string public constant INVALID_LIQ_BONUS = '65'; // 'Invalid liquidity bonus parameter for the reserve'
  string public constant INVALID_DECIMALS = '66'; // 'Invalid decimals parameter of the underlying asset of the reserve'
  string public constant INVALID_RESERVE_FACTOR = '67'; // 'Invalid reserve factor parameter for the reserve'
  string public constant INVALID_BORROW_CAP = '68'; // 'Invalid borrow cap for the reserve'
  string public constant INVALID_SUPPLY_CAP = '69'; // 'Invalid supply cap for the reserve'
  string public constant INVALID_LIQUIDATION_PROTOCOL_FEE = '70'; // 'Invalid liquidation protocol fee for the reserve'
  string public constant INVALID_EMODE_CATEGORY = '71'; // 'Invalid eMode category for the reserve'
  string public constant INVALID_UNBACKED_MINT_CAP = '72'; // 'Invalid unbacked mint cap for the reserve'
  string public constant INVALID_DEBT_CEILING = '73'; // 'Invalid debt ceiling for the reserve
  string public constant INVALID_RESERVE_INDEX = '74'; // 'Invalid reserve index'
  string public constant ACL_ADMIN_CANNOT_BE_ZERO = '75'; // 'ACL admin cannot be set to the zero address'
  string public constant INCONSISTENT_PARAMS_LENGTH = '76'; // 'Array parameters that should be equal length are not'
  string public constant ZERO_ADDRESS_NOT_VALID = '77'; // 'Zero address not valid'
  string public constant INVALID_EXPIRATION = '78'; // 'Invalid expiration'
  string public constant INVALID_SIGNATURE = '79'; // 'Invalid signature'
  string public constant OPERATION_NOT_SUPPORTED = '80'; // 'Operation not supported'
  string public constant DEBT_CEILING_NOT_ZERO = '81'; // 'Debt ceiling is not zero'
  string public constant ASSET_NOT_LISTED = '82'; // 'Asset is not listed'
  string public constant INVALID_OPTIMAL_USAGE_RATIO = '83'; // 'Invalid optimal usage ratio'
  string public constant INVALID_OPTIMAL_STABLE_TO_TOTAL_DEBT_RATIO = '84'; // 'Invalid optimal stable to total debt ratio'
  string public constant UNDERLYING_CANNOT_BE_RESCUED = '85'; // 'The underlying asset cannot be rescued'
  string public constant ADDRESSES_PROVIDER_ALREADY_ADDED = '86'; // 'Reserve has already been added to reserve list'
  string public constant POOL_ADDRESSES_DO_NOT_MATCH = '87'; // 'The token implementation pool address and the pool address provided by the initializing pool do not match'
  string public constant STABLE_BORROWING_ENABLED = '88'; // 'Stable borrowing is enabled'
  string public constant SILOED_BORROWING_VIOLATION = '89'; // 'User is trying to borrow multiple assets including a siloed one'
  string public constant RESERVE_DEBT_NOT_ZERO = '90'; // the total debt of the reserve needs to be 0
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

/**
 * @title WadRayMath library
 * @author Aave
 * @notice Provides functions to perform calculations with Wad and Ray units
 * @dev Provides mul and div function for wads (decimal numbers with 18 digits of precision) and rays (decimal numbers
 * with 27 digits of precision)
 * @dev Operations are rounded. If a value is >=.5, will be rounded up, otherwise rounded down.
 **/
library WadRayMath {
  // HALF_WAD and HALF_RAY expressed with extended notation as constant with operations are not supported in Yul assembly
  uint256 internal constant WAD = 1e18;
  uint256 internal constant HALF_WAD = 0.5e18;

  uint256 internal constant RAY = 1e27;
  uint256 internal constant HALF_RAY = 0.5e27;

  uint256 internal constant WAD_RAY_RATIO = 1e9;

  /**
   * @dev Multiplies two wad, rounding half up to the nearest wad
   * @dev assembly optimized for improved gas savings, see https://twitter.com/transmissions11/status/1451131036377571328
   * @param a Wad
   * @param b Wad
   * @return c = a*b, in wad
   **/
  function wadMul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // to avoid overflow, a <= (type(uint256).max - HALF_WAD) / b
    assembly {
      if iszero(or(iszero(b), iszero(gt(a, div(sub(not(0), HALF_WAD), b))))) {
        revert(0, 0)
      }

      c := div(add(mul(a, b), HALF_WAD), WAD)
    }
  }

  /**
   * @dev Divides two wad, rounding half up to the nearest wad
   * @dev assembly optimized for improved gas savings, see https://twitter.com/transmissions11/status/1451131036377571328
   * @param a Wad
   * @param b Wad
   * @return c = a/b, in wad
   **/
  function wadDiv(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // to avoid overflow, a <= (type(uint256).max - halfB) / WAD
    assembly {
      if or(iszero(b), iszero(iszero(gt(a, div(sub(not(0), div(b, 2)), WAD))))) {
        revert(0, 0)
      }

      c := div(add(mul(a, WAD), div(b, 2)), b)
    }
  }

  /**
   * @notice Multiplies two ray, rounding half up to the nearest ray
   * @dev assembly optimized for improved gas savings, see https://twitter.com/transmissions11/status/1451131036377571328
   * @param a Ray
   * @param b Ray
   * @return c = a raymul b
   **/
  function rayMul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // to avoid overflow, a <= (type(uint256).max - HALF_RAY) / b
    assembly {
      if iszero(or(iszero(b), iszero(gt(a, div(sub(not(0), HALF_RAY), b))))) {
        revert(0, 0)
      }

      c := div(add(mul(a, b), HALF_RAY), RAY)
    }
  }

  /**
   * @notice Divides two ray, rounding half up to the nearest ray
   * @dev assembly optimized for improved gas savings, see https://twitter.com/transmissions11/status/1451131036377571328
   * @param a Ray
   * @param b Ray
   * @return c = a raydiv b
   **/
  function rayDiv(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // to avoid overflow, a <= (type(uint256).max - halfB) / RAY
    assembly {
      if or(iszero(b), iszero(iszero(gt(a, div(sub(not(0), div(b, 2)), RAY))))) {
        revert(0, 0)
      }

      c := div(add(mul(a, RAY), div(b, 2)), b)
    }
  }

  /**
   * @dev Casts ray down to wad
   * @dev assembly optimized for improved gas savings, see https://twitter.com/transmissions11/status/1451131036377571328
   * @param a Ray
   * @return b = a converted to wad, rounded half up to the nearest wad
   **/
  function rayToWad(uint256 a) internal pure returns (uint256 b) {
    assembly {
      b := div(a, WAD_RAY_RATIO)
      let remainder := mod(a, WAD_RAY_RATIO)
      if iszero(lt(remainder, div(WAD_RAY_RATIO, 2))) {
        b := add(b, 1)
      }
    }
  }

  /**
   * @dev Converts wad up to ray
   * @dev assembly optimized for improved gas savings, see https://twitter.com/transmissions11/status/1451131036377571328
   * @param a Wad
   * @return b = a converted in ray
   **/
  function wadToRay(uint256 a) internal pure returns (uint256 b) {
    // to avoid overflow, b/WAD_RAY_RATIO == a
    assembly {
      b := mul(a, WAD_RAY_RATIO)

      if iszero(eq(div(b, WAD_RAY_RATIO), a)) {
        revert(0, 0)
      }
    }
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.10;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
  /**
   * @dev Returns the amount of tokens in existence.
   */
  function totalSupply() external view returns (uint256);

  /**
   * @dev Returns the amount of tokens owned by `account`.
   */
  function balanceOf(address account) external view returns (uint256);

  /**
   * @dev Moves `amount` tokens from the caller's account to `recipient`.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transfer(address recipient, uint256 amount) external returns (bool);

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
   * @dev Moves `amount` tokens from `sender` to `recipient` using the
   * allowance mechanism. `amount` is then deducted from the caller's
   * allowance.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeCast.sol)
pragma solidity 0.8.10;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
  /**
   * @dev Returns the downcasted uint224 from uint256, reverting on
   * overflow (when the input is greater than largest uint224).
   *
   * Counterpart to Solidity's `uint224` operator.
   *
   * Requirements:
   *
   * - input must fit into 224 bits
   */
  function toUint224(uint256 value) internal pure returns (uint224) {
    require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
    return uint224(value);
  }

  /**
   * @dev Returns the downcasted uint128 from uint256, reverting on
   * overflow (when the input is greater than largest uint128).
   *
   * Counterpart to Solidity's `uint128` operator.
   *
   * Requirements:
   *
   * - input must fit into 128 bits
   */
  function toUint128(uint256 value) internal pure returns (uint128) {
    require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
    return uint128(value);
  }

  /**
   * @dev Returns the downcasted uint96 from uint256, reverting on
   * overflow (when the input is greater than largest uint96).
   *
   * Counterpart to Solidity's `uint96` operator.
   *
   * Requirements:
   *
   * - input must fit into 96 bits
   */
  function toUint96(uint256 value) internal pure returns (uint96) {
    require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
    return uint96(value);
  }

  /**
   * @dev Returns the downcasted uint64 from uint256, reverting on
   * overflow (when the input is greater than largest uint64).
   *
   * Counterpart to Solidity's `uint64` operator.
   *
   * Requirements:
   *
   * - input must fit into 64 bits
   */
  function toUint64(uint256 value) internal pure returns (uint64) {
    require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
    return uint64(value);
  }

  /**
   * @dev Returns the downcasted uint32 from uint256, reverting on
   * overflow (when the input is greater than largest uint32).
   *
   * Counterpart to Solidity's `uint32` operator.
   *
   * Requirements:
   *
   * - input must fit into 32 bits
   */
  function toUint32(uint256 value) internal pure returns (uint32) {
    require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
    return uint32(value);
  }

  /**
   * @dev Returns the downcasted uint16 from uint256, reverting on
   * overflow (when the input is greater than largest uint16).
   *
   * Counterpart to Solidity's `uint16` operator.
   *
   * Requirements:
   *
   * - input must fit into 16 bits
   */
  function toUint16(uint256 value) internal pure returns (uint16) {
    require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
    return uint16(value);
  }

  /**
   * @dev Returns the downcasted uint8 from uint256, reverting on
   * overflow (when the input is greater than largest uint8).
   *
   * Counterpart to Solidity's `uint8` operator.
   *
   * Requirements:
   *
   * - input must fit into 8 bits.
   */
  function toUint8(uint256 value) internal pure returns (uint8) {
    require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
    return uint8(value);
  }

  /**
   * @dev Converts a signed int256 into an unsigned uint256.
   *
   * Requirements:
   *
   * - input must be greater than or equal to 0.
   */
  function toUint256(int256 value) internal pure returns (uint256) {
    require(value >= 0, 'SafeCast: value must be positive');
    return uint256(value);
  }

  /**
   * @dev Returns the downcasted int128 from int256, reverting on
   * overflow (when the input is less than smallest int128 or
   * greater than largest int128).
   *
   * Counterpart to Solidity's `int128` operator.
   *
   * Requirements:
   *
   * - input must fit into 128 bits
   *
   * _Available since v3.1._
   */
  function toInt128(int256 value) internal pure returns (int128) {
    require(
      value >= type(int128).min && value <= type(int128).max,
      "SafeCast: value doesn't fit in 128 bits"
    );
    return int128(value);
  }

  /**
   * @dev Returns the downcasted int64 from int256, reverting on
   * overflow (when the input is less than smallest int64 or
   * greater than largest int64).
   *
   * Counterpart to Solidity's `int64` operator.
   *
   * Requirements:
   *
   * - input must fit into 64 bits
   *
   * _Available since v3.1._
   */
  function toInt64(int256 value) internal pure returns (int64) {
    require(
      value >= type(int64).min && value <= type(int64).max,
      "SafeCast: value doesn't fit in 64 bits"
    );
    return int64(value);
  }

  /**
   * @dev Returns the downcasted int32 from int256, reverting on
   * overflow (when the input is less than smallest int32 or
   * greater than largest int32).
   *
   * Counterpart to Solidity's `int32` operator.
   *
   * Requirements:
   *
   * - input must fit into 32 bits
   *
   * _Available since v3.1._
   */
  function toInt32(int256 value) internal pure returns (int32) {
    require(
      value >= type(int32).min && value <= type(int32).max,
      "SafeCast: value doesn't fit in 32 bits"
    );
    return int32(value);
  }

  /**
   * @dev Returns the downcasted int16 from int256, reverting on
   * overflow (when the input is less than smallest int16 or
   * greater than largest int16).
   *
   * Counterpart to Solidity's `int16` operator.
   *
   * Requirements:
   *
   * - input must fit into 16 bits
   *
   * _Available since v3.1._
   */
  function toInt16(int256 value) internal pure returns (int16) {
    require(
      value >= type(int16).min && value <= type(int16).max,
      "SafeCast: value doesn't fit in 16 bits"
    );
    return int16(value);
  }

  /**
   * @dev Returns the downcasted int8 from int256, reverting on
   * overflow (when the input is less than smallest int8 or
   * greater than largest int8).
   *
   * Counterpart to Solidity's `int8` operator.
   *
   * Requirements:
   *
   * - input must fit into 8 bits.
   *
   * _Available since v3.1._
   */
  function toInt8(int256 value) internal pure returns (int8) {
    require(
      value >= type(int8).min && value <= type(int8).max,
      "SafeCast: value doesn't fit in 8 bits"
    );
    return int8(value);
  }

  /**
   * @dev Converts an unsigned uint256 into a signed int256.
   *
   * Requirements:
   *
   * - input must be less than or equal to maxInt256.
   */
  function toInt256(uint256 value) internal pure returns (int256) {
    // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
    require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
    return int256(value);
  }
}

// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity 0.8.10;

import {IERC20} from '../../openzeppelin/contracts/IERC20.sol';

/// @title Gnosis Protocol v2 Safe ERC20 Transfer Library
/// @author Gnosis Developers
/// @dev Gas-efficient version of Openzeppelin's SafeERC20 contract.
library GPv2SafeERC20 {
  /// @dev Wrapper around a call to the ERC20 function `transfer` that reverts
  /// also when the token returns `false`.
  function safeTransfer(
    IERC20 token,
    address to,
    uint256 value
  ) internal {
    bytes4 selector_ = token.transfer.selector;

    // solhint-disable-next-line no-inline-assembly
    assembly {
      let freeMemoryPointer := mload(0x40)
      mstore(freeMemoryPointer, selector_)
      mstore(add(freeMemoryPointer, 4), and(to, 0xffffffffffffffffffffffffffffffffffffffff))
      mstore(add(freeMemoryPointer, 36), value)

      if iszero(call(gas(), token, 0, freeMemoryPointer, 68, 0, 0)) {
        returndatacopy(0, 0, returndatasize())
        revert(0, returndatasize())
      }
    }

    require(getLastTransferResult(token), 'GPv2: failed transfer');
  }

  /// @dev Wrapper around a call to the ERC20 function `transferFrom` that
  /// reverts also when the token returns `false`.
  function safeTransferFrom(
    IERC20 token,
    address from,
    address to,
    uint256 value
  ) internal {
    bytes4 selector_ = token.transferFrom.selector;

    // solhint-disable-next-line no-inline-assembly
    assembly {
      let freeMemoryPointer := mload(0x40)
      mstore(freeMemoryPointer, selector_)
      mstore(add(freeMemoryPointer, 4), and(from, 0xffffffffffffffffffffffffffffffffffffffff))
      mstore(add(freeMemoryPointer, 36), and(to, 0xffffffffffffffffffffffffffffffffffffffff))
      mstore(add(freeMemoryPointer, 68), value)

      if iszero(call(gas(), token, 0, freeMemoryPointer, 100, 0, 0)) {
        returndatacopy(0, 0, returndatasize())
        revert(0, returndatasize())
      }
    }

    require(getLastTransferResult(token), 'GPv2: failed transferFrom');
  }

  /// @dev Verifies that the last return was a successful `transfer*` call.
  /// This is done by checking that the return data is either empty, or
  /// is a valid ABI encoded boolean.
  function getLastTransferResult(IERC20 token) private view returns (bool success) {
    // NOTE: Inspecting previous return data requires assembly. Note that
    // we write the return data to memory 0 in the case where the return
    // data size is 32, this is OK since the first 64 bytes of memory are
    // reserved by Solidy as a scratch space that can be used within
    // assembly blocks.
    // <https://docs.soliditylang.org/en/v0.7.6/internals/layout_in_memory.html>
    // solhint-disable-next-line no-inline-assembly
    assembly {
      /// @dev Revert with an ABI encoded Solidity error with a message
      /// that fits into 32-bytes.
      ///
      /// An ABI encoded Solidity error has the following memory layout:
      ///
      /// ------------+----------------------------------
      ///  byte range | value
      /// ------------+----------------------------------
      ///  0x00..0x04 |        selector("Error(string)")
      ///  0x04..0x24 |      string offset (always 0x20)
      ///  0x24..0x44 |                    string length
      ///  0x44..0x64 | string value, padded to 32-bytes
      function revertWithMessage(length, message) {
        mstore(0x00, '\x08\xc3\x79\xa0')
        mstore(0x04, 0x20)
        mstore(0x24, length)
        mstore(0x44, message)
        revert(0x00, 0x64)
      }

      switch returndatasize()
      // Non-standard ERC20 transfer without return.
      case 0 {
        // NOTE: When the return data size is 0, verify that there
        // is code at the address. This is done in order to maintain
        // compatibility with Solidity calling conventions.
        // <https://docs.soliditylang.org/en/v0.7.6/control-structures.html#external-function-calls>
        if iszero(extcodesize(token)) {
          revertWithMessage(20, 'GPv2: not a contract')
        }

        success := 1
      }
      // Standard ERC20 transfer returning boolean success value.
      case 32 {
        returndatacopy(0, 0, returndatasize())

        // NOTE: For ABI encoding v1, any non-zero value is accepted
        // as `true` for a boolean. In order to stay compatible with
        // OpenZeppelin's `SafeERC20` library which is known to work
        // with the existing ERC20 implementation we care about,
        // make sure we return success for any non-zero return value
        // from the `transfer*` call.
        success := iszero(iszero(mload(0)))
      }
      default {
        revertWithMessage(31, 'GPv2: malformed transfer result')
      }
    }
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.10;

/**
 * @title EIP712Base
 * @author Aave
 * @notice Base contract implementation of EIP712.
 */
abstract contract EIP712Base {
  bytes public constant EIP712_REVISION = bytes('1');
  bytes32 internal constant EIP712_DOMAIN =
    keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)');

  // Map of address nonces (address => nonce)
  mapping(address => uint256) internal _nonces;

  bytes32 internal _domainSeparator;
  uint256 internal immutable _chainId;

  /**
   * @dev Constructor.
   */
  constructor() {
    _chainId = block.chainid;
  }

  /**
   * @notice Get the domain separator for the token
   * @dev Return cached value if chainId matches cache, otherwise recomputes separator
   * @return The domain separator of the token at current chain
   */
  function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
    if (block.chainid == _chainId) {
      return _domainSeparator;
    }
    return _calculateDomainSeparator();
  }

  /**
   * @notice Returns the nonce value for address specified as parameter
   * @param owner The address for which the nonce is being returned
   * @return The nonce value for the input address`
   */
  function nonces(address owner) public view virtual returns (uint256) {
    return _nonces[owner];
  }

  /**
   * @notice Compute the current domain separator
   * @return The domain separator for the token
   */
  function _calculateDomainSeparator() internal view returns (bytes32) {
    return
      keccak256(
        abi.encode(
          EIP712_DOMAIN,
          keccak256(bytes(_EIP712BaseId())),
          keccak256(EIP712_REVISION),
          block.chainid,
          address(this)
        )
      );
  }

  /**
   * @notice Returns the user readable name of signing domain (e.g. token name)
   * @return The name of the signing domain
   */
  function _EIP712BaseId() internal view virtual returns (string memory);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

/**
 * @title IPoolAddressesProvider
 * @author Aave
 * @notice Defines the basic interface for a Pool Addresses Provider.
 **/
interface IPoolAddressesProvider {
  /**
   * @dev Emitted when the market identifier is updated.
   * @param oldMarketId The old id of the market
   * @param newMarketId The new id of the market
   */
  event MarketIdSet(string indexed oldMarketId, string indexed newMarketId);

  /**
   * @dev Emitted when the pool is updated.
   * @param oldAddress The old address of the Pool
   * @param newAddress The new address of the Pool
   */
  event PoolUpdated(address indexed oldAddress, address indexed newAddress);

  /**
   * @dev Emitted when the pool configurator is updated.
   * @param oldAddress The old address of the PoolConfigurator
   * @param newAddress The new address of the PoolConfigurator
   */
  event PoolConfiguratorUpdated(address indexed oldAddress, address indexed newAddress);

  /**
   * @dev Emitted when the price oracle is updated.
   * @param oldAddress The old address of the PriceOracle
   * @param newAddress The new address of the PriceOracle
   */
  event PriceOracleUpdated(address indexed oldAddress, address indexed newAddress);

  /**
   * @dev Emitted when the ACL manager is updated.
   * @param oldAddress The old address of the ACLManager
   * @param newAddress The new address of the ACLManager
   */
  event ACLManagerUpdated(address indexed oldAddress, address indexed newAddress);

  /**
   * @dev Emitted when the ACL admin is updated.
   * @param oldAddress The old address of the ACLAdmin
   * @param newAddress The new address of the ACLAdmin
   */
  event ACLAdminUpdated(address indexed oldAddress, address indexed newAddress);

  /**
   * @dev Emitted when the price oracle sentinel is updated.
   * @param oldAddress The old address of the PriceOracleSentinel
   * @param newAddress The new address of the PriceOracleSentinel
   */
  event PriceOracleSentinelUpdated(address indexed oldAddress, address indexed newAddress);

  /**
   * @dev Emitted when the pool data provider is updated.
   * @param oldAddress The old address of the PoolDataProvider
   * @param newAddress The new address of the PoolDataProvider
   */
  event PoolDataProviderUpdated(address indexed oldAddress, address indexed newAddress);

  /**
   * @dev Emitted when a new proxy is created.
   * @param id The identifier of the proxy
   * @param proxyAddress The address of the created proxy contract
   * @param implementationAddress The address of the implementation contract
   */
  event ProxyCreated(
    bytes32 indexed id,
    address indexed proxyAddress,
    address indexed implementationAddress
  );

  /**
   * @dev Emitted when a new non-proxied contract address is registered.
   * @param id The identifier of the contract
   * @param oldAddress The address of the old contract
   * @param newAddress The address of the new contract
   */
  event AddressSet(bytes32 indexed id, address indexed oldAddress, address indexed newAddress);

  /**
   * @dev Emitted when the implementation of the proxy registered with id is updated
   * @param id The identifier of the contract
   * @param proxyAddress The address of the proxy contract
   * @param oldImplementationAddress The address of the old implementation contract
   * @param newImplementationAddress The address of the new implementation contract
   */
  event AddressSetAsProxy(
    bytes32 indexed id,
    address indexed proxyAddress,
    address oldImplementationAddress,
    address indexed newImplementationAddress
  );

  /**
   * @notice Returns the id of the Aave market to which this contract points to.
   * @return The market id
   **/
  function getMarketId() external view returns (string memory);

  /**
   * @notice Associates an id with a specific PoolAddressesProvider.
   * @dev This can be used to create an onchain registry of PoolAddressesProviders to
   * identify and validate multiple Aave markets.
   * @param newMarketId The market id
   */
  function setMarketId(string calldata newMarketId) external;

  /**
   * @notice Returns an address by its identifier.
   * @dev The returned address might be an EOA or a contract, potentially proxied
   * @dev It returns ZERO if there is no registered address with the given id
   * @param id The id
   * @return The address of the registered for the specified id
   */
  function getAddress(bytes32 id) external view returns (address);

  /**
   * @notice General function to update the implementation of a proxy registered with
   * certain `id`. If there is no proxy registered, it will instantiate one and
   * set as implementation the `newImplementationAddress`.
   * @dev IMPORTANT Use this function carefully, only for ids that don't have an explicit
   * setter function, in order to avoid unexpected consequences
   * @param id The id
   * @param newImplementationAddress The address of the new implementation
   */
  function setAddressAsProxy(bytes32 id, address newImplementationAddress) external;

  /**
   * @notice Sets an address for an id replacing the address saved in the addresses map.
   * @dev IMPORTANT Use this function carefully, as it will do a hard replacement
   * @param id The id
   * @param newAddress The address to set
   */
  function setAddress(bytes32 id, address newAddress) external;

  /**
   * @notice Returns the address of the Pool proxy.
   * @return The Pool proxy address
   **/
  function getPool() external view returns (address);

  /**
   * @notice Updates the implementation of the Pool, or creates a proxy
   * setting the new `pool` implementation when the function is called for the first time.
   * @param newPoolImpl The new Pool implementation
   **/
  function setPoolImpl(address newPoolImpl) external;

  /**
   * @notice Returns the address of the PoolConfigurator proxy.
   * @return The PoolConfigurator proxy address
   **/
  function getPoolConfigurator() external view returns (address);

  /**
   * @notice Updates the implementation of the PoolConfigurator, or creates a proxy
   * setting the new `PoolConfigurator` implementation when the function is called for the first time.
   * @param newPoolConfiguratorImpl The new PoolConfigurator implementation
   **/
  function setPoolConfiguratorImpl(address newPoolConfiguratorImpl) external;

  /**
   * @notice Returns the address of the price oracle.
   * @return The address of the PriceOracle
   */
  function getPriceOracle() external view returns (address);

  /**
   * @notice Updates the address of the price oracle.
   * @param newPriceOracle The address of the new PriceOracle
   */
  function setPriceOracle(address newPriceOracle) external;

  /**
   * @notice Returns the address of the ACL manager.
   * @return The address of the ACLManager
   */
  function getACLManager() external view returns (address);

  /**
   * @notice Updates the address of the ACL manager.
   * @param newAclManager The address of the new ACLManager
   **/
  function setACLManager(address newAclManager) external;

  /**
   * @notice Returns the address of the ACL admin.
   * @return The address of the ACL admin
   */
  function getACLAdmin() external view returns (address);

  /**
   * @notice Updates the address of the ACL admin.
   * @param newAclAdmin The address of the new ACL admin
   */
  function setACLAdmin(address newAclAdmin) external;

  /**
   * @notice Returns the address of the price oracle sentinel.
   * @return The address of the PriceOracleSentinel
   */
  function getPriceOracleSentinel() external view returns (address);

  /**
   * @notice Updates the address of the price oracle sentinel.
   * @param newPriceOracleSentinel The address of the new PriceOracleSentinel
   **/
  function setPriceOracleSentinel(address newPriceOracleSentinel) external;

  /**
   * @notice Returns the address of the data provider.
   * @return The address of the DataProvider
   */
  function getPoolDataProvider() external view returns (address);

  /**
   * @notice Updates the address of the data provider.
   * @param newDataProvider The address of the new DataProvider
   **/
  function setPoolDataProvider(address newDataProvider) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {IPoolAddressesProvider} from './IPoolAddressesProvider.sol';

/**
 * @title IACLManager
 * @author Aave
 * @notice Defines the basic interface for the ACL Manager
 **/
interface IACLManager {
  /**
   * @notice Returns the contract address of the PoolAddressesProvider
   * @return The address of the PoolAddressesProvider
   */
  function ADDRESSES_PROVIDER() external view returns (IPoolAddressesProvider);

  /**
   * @notice Returns the identifier of the PoolAdmin role
   * @return The id of the PoolAdmin role
   */
  function POOL_ADMIN_ROLE() external view returns (bytes32);

  /**
   * @notice Returns the identifier of the EmergencyAdmin role
   * @return The id of the EmergencyAdmin role
   */
  function EMERGENCY_ADMIN_ROLE() external view returns (bytes32);

  /**
   * @notice Returns the identifier of the RiskAdmin role
   * @return The id of the RiskAdmin role
   */
  function RISK_ADMIN_ROLE() external view returns (bytes32);

  /**
   * @notice Returns the identifier of the FlashBorrower role
   * @return The id of the FlashBorrower role
   */
  function FLASH_BORROWER_ROLE() external view returns (bytes32);

  /**
   * @notice Returns the identifier of the Bridge role
   * @return The id of the Bridge role
   */
  function BRIDGE_ROLE() external view returns (bytes32);

  /**
   * @notice Returns the identifier of the AssetListingAdmin role
   * @return The id of the AssetListingAdmin role
   */
  function ASSET_LISTING_ADMIN_ROLE() external view returns (bytes32);

  /**
   * @notice Set the role as admin of a specific role.
   * @dev By default the admin role for all roles is `DEFAULT_ADMIN_ROLE`.
   * @param role The role to be managed by the admin role
   * @param adminRole The admin role
   */
  function setRoleAdmin(bytes32 role, bytes32 adminRole) external;

  /**
   * @notice Adds a new admin as PoolAdmin
   * @param admin The address of the new admin
   */
  function addPoolAdmin(address admin) external;

  /**
   * @notice Removes an admin as PoolAdmin
   * @param admin The address of the admin to remove
   */
  function removePoolAdmin(address admin) external;

  /**
   * @notice Returns true if the address is PoolAdmin, false otherwise
   * @param admin The address to check
   * @return True if the given address is PoolAdmin, false otherwise
   */
  function isPoolAdmin(address admin) external view returns (bool);

  /**
   * @notice Adds a new admin as EmergencyAdmin
   * @param admin The address of the new admin
   */
  function addEmergencyAdmin(address admin) external;

  /**
   * @notice Removes an admin as EmergencyAdmin
   * @param admin The address of the admin to remove
   */
  function removeEmergencyAdmin(address admin) external;

  /**
   * @notice Returns true if the address is EmergencyAdmin, false otherwise
   * @param admin The address to check
   * @return True if the given address is EmergencyAdmin, false otherwise
   */
  function isEmergencyAdmin(address admin) external view returns (bool);

  /**
   * @notice Adds a new admin as RiskAdmin
   * @param admin The address of the new admin
   */
  function addRiskAdmin(address admin) external;

  /**
   * @notice Removes an admin as RiskAdmin
   * @param admin The address of the admin to remove
   */
  function removeRiskAdmin(address admin) external;

  /**
   * @notice Returns true if the address is RiskAdmin, false otherwise
   * @param admin The address to check
   * @return True if the given address is RiskAdmin, false otherwise
   */
  function isRiskAdmin(address admin) external view returns (bool);

  /**
   * @notice Adds a new address as FlashBorrower
   * @param borrower The address of the new FlashBorrower
   */
  function addFlashBorrower(address borrower) external;

  /**
   * @notice Removes an admin as FlashBorrower
   * @param borrower The address of the FlashBorrower to remove
   */
  function removeFlashBorrower(address borrower) external;

  /**
   * @notice Returns true if the address is FlashBorrower, false otherwise
   * @param borrower The address to check
   * @return True if the given address is FlashBorrower, false otherwise
   */
  function isFlashBorrower(address borrower) external view returns (bool);

  /**
   * @notice Adds a new address as Bridge
   * @param bridge The address of the new Bridge
   */
  function addBridge(address bridge) external;

  /**
   * @notice Removes an address as Bridge
   * @param bridge The address of the bridge to remove
   */
  function removeBridge(address bridge) external;

  /**
   * @notice Returns true if the address is Bridge, false otherwise
   * @param bridge The address to check
   * @return True if the given address is Bridge, false otherwise
   */
  function isBridge(address bridge) external view returns (bool);

  /**
   * @notice Adds a new admin as AssetListingAdmin
   * @param admin The address of the new admin
   */
  function addAssetListingAdmin(address admin) external;

  /**
   * @notice Removes an admin as AssetListingAdmin
   * @param admin The address of the admin to remove
   */
  function removeAssetListingAdmin(address admin) external;

  /**
   * @notice Returns true if the address is AssetListingAdmin, false otherwise
   * @param admin The address to check
   * @return True if the given address is AssetListingAdmin, false otherwise
   */
  function isAssetListingAdmin(address admin) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import './Context.sol';
import './IERC20.sol';
import './SafeMath.sol';
import './Address.sol';

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
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
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
contract ERC20 is Context, IERC20 {
  using SafeMath for uint256;
  using Address for address;

  mapping(address => uint256) private _balances;

  mapping(address => mapping(address => uint256)) private _allowances;

  uint256 private _totalSupply;

  string private _name;
  string private _symbol;
  uint8 private _decimals;

  /**
   * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
   * a default value of 18.
   *
   * To select a different value for {decimals}, use {_setupDecimals}.
   *
   * All three of these values are immutable: they can only be set once during
   * construction.
   */
  constructor(string memory tokenName, string memory tokenSymbol) {
    _name = tokenName;
    _symbol = tokenSymbol;
    _decimals = 18;
  }

  /**
   * @dev Returns the name of the token.
   */
  function name() public view returns (string memory) {
    return _name;
  }

  /**
   * @dev Returns the symbol of the token, usually a shorter version of the
   * name.
   */
  function symbol() public view returns (string memory) {
    return _symbol;
  }

  /**
   * @dev Returns the number of decimals used to get its user representation.
   * For example, if `decimals` equals `2`, a balance of `505` tokens should
   * be displayed to a user as `5,05` (`505 / 10 ** 2`).
   *
   * Tokens usually opt for a value of 18, imitating the relationship between
   * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
   * called.
   *
   * NOTE: This information is only used for _display_ purposes: it in
   * no way affects any of the arithmetic of the contract, including
   * {IERC20-balanceOf} and {IERC20-transfer}.
   */
  function decimals() public view returns (uint8) {
    return _decimals;
  }

  /**
   * @dev See {IERC20-totalSupply}.
   */
  function totalSupply() public view override returns (uint256) {
    return _totalSupply;
  }

  /**
   * @dev See {IERC20-balanceOf}.
   */
  function balanceOf(address account) public view override returns (uint256) {
    return _balances[account];
  }

  /**
   * @dev See {IERC20-transfer}.
   *
   * Requirements:
   *
   * - `recipient` cannot be the zero address.
   * - the caller must have a balance of at least `amount`.
   */
  function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
    _transfer(msg.sender, recipient, amount);
    return false;
  }

  /**
   * @dev See {IERC20-allowance}.
   */
  function allowance(address owner, address spender)
    public
    view
    virtual
    override
    returns (uint256)
  {
    return _allowances[owner][spender];
  }

  /**
   * @dev See {IERC20-approve}.
   *
   * Requirements:
   *
   * - `spender` cannot be the zero address.
   */
  function approve(address spender, uint256 amount) public virtual override returns (bool) {
    _approve(_msgSender(), spender, amount);
    return true;
  }

  /**
   * @dev See {IERC20-transferFrom}.
   *
   * Emits an {Approval} event indicating the updated allowance. This is not
   * required by the EIP. See the note at the beginning of {ERC20};
   *
   * Requirements:
   * - `sender` and `recipient` cannot be the zero address.
   * - `sender` must have a balance of at least `amount`.
   * - the caller must have allowance for ``sender``'s tokens of at least
   * `amount`.
   */
  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) public virtual override returns (bool) {
    _transfer(sender, recipient, amount);
    return false;
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
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
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
  function decreaseAllowance(address spender, uint256 subtractedValue)
    public
    virtual
    returns (bool)
  {
    _approve(
      _msgSender(),
      spender,
      _allowances[_msgSender()][spender].sub(
        subtractedValue,
        'ERC20: decreased allowance below zero'
      )
    );
    return true;
  }

  /**
   * @dev Moves tokens `amount` from `sender` to `recipient`.
   *
   * This is internal function is equivalent to {transfer}, and can be used to
   * e.g. implement automatic token fees, slashing mechanisms, etc.
   *
   * Emits a {Transfer} event.
   *
   * Requirements:
   *
   * - `sender` cannot be the zero address.
   * - `recipient` cannot be the zero address.
   * - `sender` must have a balance of at least `amount`.
   */
  function _transfer(
    address sender,
    address recipient,
    uint256 amount
  ) internal virtual {
    require(sender != address(0), 'ERC20: transfer from the zero address');
    require(recipient != address(0), 'ERC20: transfer to the zero address');

    _beforeTokenTransfer(sender, recipient, amount);

    _balances[sender] = _balances[sender].sub(amount, 'ERC20: transfer amount exceeds balance');
    _balances[recipient] = _balances[recipient].add(amount);
    emit Transfer(sender, recipient, amount);
  }

  /** @dev Creates `amount` tokens and assigns them to `account`, increasing
   * the total supply.
   *
   * Emits a {Transfer} event with `from` set to the zero address.
   *
   * Requirements
   *
   * - `to` cannot be the zero address.
   */
  function _mint(address account, uint256 amount) internal virtual {
    require(account != address(0), 'ERC20: mint to the zero address');

    _beforeTokenTransfer(address(0), account, amount);

    _totalSupply = _totalSupply.add(amount);
    _balances[account] = _balances[account].add(amount);
    emit Transfer(address(0), account, amount);
  }

  /**
   * @dev Destroys `amount` tokens from `account`, reducing the
   * total supply.
   *
   * Emits a {Transfer} event with `to` set to the zero address.
   *
   * Requirements
   *
   * - `account` cannot be the zero address.
   * - `account` must have at least `amount` tokens.
   */
  function _burn(address account, uint256 amount) internal virtual {
    require(account != address(0), 'ERC20: burn from the zero address');

    _beforeTokenTransfer(account, address(0), amount);

    _balances[account] = _balances[account].sub(amount, 'ERC20: burn amount exceeds balance');
    _totalSupply = _totalSupply.sub(amount);
    emit Transfer(account, address(0), amount);
  }

  /**
   * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
   *
   * This is internal function is equivalent to `approve`, and can be used to
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
    require(owner != address(0), 'ERC20: approve from the zero address');
    require(spender != address(0), 'ERC20: approve to the zero address');

    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }

  /**
   * @dev Sets {decimals} to a value other than the default one of 18.
   *
   * WARNING: This function should only be called from the constructor. Most
   * applications that interact with token contracts will not expect
   * {decimals} to ever change, and may work incorrectly if it does.
   */
  function _setupDecimals(uint8 decimals_) internal {
    _decimals = decimals_;
  }

  /**
   * @dev Hook that is called before any transfer of tokens. This includes
   * minting and burning.
   *
   * Calling conditions:
   *
   * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
   * will be to transferred to `to`.
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
   * @notice Update the name of the token
   * @param newName The new name for the token
   */
  function _setName(string memory newName) internal {
    _name = newName;
  }

  /**
   * @notice Update the symbol for the token
   * @param newSymbol The new symbol for the token
   */
  function _setSymbol(string memory newSymbol) internal {
    _symbol = newSymbol;
  }

  /**
   * @notice Update the number of decimals for the token
   * @param newDecimals The new number of decimals for the token
   */
  function _setDecimals(uint8 newDecimals) internal {
    _decimals = newDecimals;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
  function _msgSender() internal view virtual returns (address payable) {
    return payable(msg.sender);
  }

  function _msgData() internal view virtual returns (bytes memory) {
    this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    return msg.data;
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.10;

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
   */
  function isContract(address account) internal view returns (bool) {
    // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
    // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
    // for accounts without code, i.e. `keccak256('')`
    bytes32 codehash;
    bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
    // solhint-disable-next-line no-inline-assembly
    assembly {
      codehash := extcodehash(account)
    }
    return (codehash != accountHash && codehash != 0x0);
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
    require(address(this).balance >= amount, 'Address: insufficient balance');

    // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
    (bool success, ) = recipient.call{value: amount}('');
    require(success, 'Address: unable to send value, recipient may have reverted');
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.10;

/// @title Optimized overflow and underflow safe math operations
/// @notice Contains methods for doing math operations that revert on overflow or underflow for minimal gas cost
library SafeMath {
  /// @notice Returns x + y, reverts if sum overflows uint256
  /// @param x The augend
  /// @param y The addend
  /// @return z The sum of x and y
  function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
    unchecked {
      require((z = x + y) >= x);
    }
  }

  /// @notice Returns x - y, reverts if underflows
  /// @param x The minuend
  /// @param y The subtrahend
  /// @return z The difference of x and y
  function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
    unchecked {
      require((z = x - y) <= x);
    }
  }

  /// @notice Returns x - y, reverts if underflows
  /// @param x The minuend
  /// @param y The subtrahend
  /// @param message The error msg
  /// @return z The difference of x and y
  function sub(
    uint256 x,
    uint256 y,
    string memory message
  ) internal pure returns (uint256 z) {
    unchecked {
      require((z = x - y) <= x, message);
    }
  }

  /// @notice Returns x * y, reverts if overflows
  /// @param x The multiplicand
  /// @param y The multiplier
  /// @return z The product of x and y
  function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
    unchecked {
      require(x == 0 || (z = x * y) / x == y);
    }
  }

  /// @notice Returns x / y, reverts if overflows - no specific check, solidity reverts on division by 0
  /// @param x The numerator
  /// @param y The denominator
  /// @return z The product of x and y
  function div(uint256 x, uint256 y) internal pure returns (uint256 z) {
    return x / y;
  }
}