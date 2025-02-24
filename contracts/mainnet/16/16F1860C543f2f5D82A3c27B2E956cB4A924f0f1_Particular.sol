//SPDX-License-Identifier: MIT                                                                                                 
/* ***************************************************************************************************/                                     
/*                                                          dddddddd                                 */
/* KKKKKKKKK    KKKKKKK  iiii                               d::::::dlllllll                          */
/* K:::::::K    K:::::K i::::i                              d::::::dl:::::l                          */
/* K:::::::K    K:::::K  iiii                               d::::::dl:::::l                          */
/* K:::::::K   K::::::K                                     d:::::d l:::::l                          */
/* KK::::::K  K:::::KKKiiiiiiinnnn  nnnnnnnn        ddddddddd:::::d  l::::lyyyyyyy           yyyyyyy */
/*  K:::::K K:::::K   i:::::in:::nn::::::::nn    dd::::::::::::::d  l::::l y:::::y         y:::::y   */
/*   K::::::K:::::K     i::::in::::::::::::::nn  d::::::::::::::::d  l::::l  y:::::y       y:::::y   */
/*   K:::::::::::K      i::::inn:::::::::::::::nd:::::::ddddd:::::d  l::::l   y:::::y     y:::::y    */
/*   K:::::::::::K      i::::i  n:::::nnnn:::::nd::::::d    d:::::d  l::::l    y:::::y   y:::::y     */
/*   K::::::K:::::K     i::::i  n::::n    n::::nd:::::d     d:::::d  l::::l     y:::::y y:::::y      */
/*   K:::::K K:::::K    i::::i  n::::n    n::::nd:::::d     d:::::d  l::::l      y:::::y:::::y       */
/* KK::::::K  K:::::KKK i::::i  n::::n    n::::nd:::::d     d:::::d  l::::l       y:::::::::y        */
/* K:::::::K   K::::::Ki::::::i n::::n    n::::nd::::::ddddd::::::ddl::::::l       y:::::::y         */
/* K:::::::K    K:::::Ki::::::i n::::n    n::::n d:::::::::::::::::dl::::::l        y:::::y          */
/* K:::::::K    K:::::Ki::::::i n::::n    n::::n  d:::::::::ddd::::dl::::::l       y:::::y           */
/* KKKKKKKKK    KKKKKKKiiiiiiii nnnnnn    nnnnnn   ddddddddd   dddddllllllll      y:::::y            */
/*                                                                              y:::::y              */
/*                                                                             y:::::y               */
/*                                                                           y:::::y                 */
/*                                                                          y:::::y                  */
/*                                                                          yyyyyyy                  */
/*****************************************************************************************************/

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "../interfaces/IChainlink.sol";
import "../interfaces/IUniswap.sol";

contract Particular is Initializable {

    IChainlink chainlink;
    IUniswap uniswap;
    address public admin;
    //CAN´T BE CHANGED RIGHT NOW AND CAN´T DEPLOY OTHER PARTICULAR CONTRACT
    uint256 public percent;
    address public wallet;

    event Transaction(address indexed from, address indexed to, uint256 amount, uint256 remaining);
    event ToSeeInETH(uint256 toSave, uint256 rest, uint256 toKindly, uint256 toONGs, uint256 toStable, uint256 toWallet);
    event ToSee(uint256 price, uint256 amountOutMin, uint256 amountToSave, uint256 amountToKindly, uint256 totalConverted);
    event Price(int256 price, uint256 uprice);
    event msgValue(uint256 value);

    function initialize (address _admin, uint256 _percent, address _wallet) virtual public initializer {
        // DATA FEED FOR MAINNET -> 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
        // DATA FEED FOR GOERLI -> 0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
        // DATA FEED FOR POLYGON - ETH/USD -> 0xF9680D99D6C9589e2a93a78A04A279e509205945
        // DATA FEED FOR POLYGON - MATIC/USD -> 0xAB594600376Ec9fD91F8e885dADF0CE036862dE0
        chainlink = IChainlink(0xAB594600376Ec9fD91F8e885dADF0CE036862dE0);
        // UNISWAP GOERLI -> 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        uniswap = IUniswap(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        admin = _admin;
        percent = _percent;
        wallet = _wallet;
    }

    /**
    * @dev splitts the money automaticly between the ONG and the wallet which will receive the rest
    */
    receive() external payable {
        emit msgValue(msg.value); // 0.01 ETH = 10000000000000000
        uint256 toSave = msg.value * percent / 100;
        uint256 rest = msg.value - toSave;
        uint256 toKindly = rest * 20 / 1000; // 20/1000 = 2%
        uint256 toONGs = rest * 15 / 1000; // 15/1000 = 1.5%
        uint256 toStable = toSave + toKindly + toONGs;
        uint256 toWallet = rest - toStable;
        emit ToSeeInETH(toSave, rest, toKindly, toONGs, toStable, toWallet);
        address [] memory path = new address[](2);
        path[0] = uniswap.WETH();
        // ADDRES OF USDC ON MAINNET -> 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48
        // ADRESS OF USDC ON MUMBAI -> 0xe6b8a5CF854791412c1f6EFC7CAf629f5Df1c747
        // ADRESS OF USDC ON POLYGON -> 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174
        // ADRESS OF USDC ON GÖERLI -> 0x07865c6E87B9F70255377e024ace6630C1Eaa37F
        path[1] = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;
        //PRICE IS IN USD TO 1 ETH
        //  1 ETH = 10^18 WEI -> 1 ETH = 1000000000000000000 WEI
        //  1 ETH = 170882557272 USDCWeis = 1708,82557272 USDC


        uint256 price = getLatestPrice(); // FORMATO DEL PRICE:  170882557272 = 1708,82557272

        uint256 amountOutMin = toStable * price;

        uniswap.swapExactETHForTokens{value: toStable}(amountOutMin, path, address(this), block.timestamp + 5 minutes);
        
        uint256 totalConverted = IERC20Upgradeable(path[1]).balanceOf(address(this));
        uint256 amountToKindly = toKindly * price;
        uint256 amountToSave = totalConverted - amountToKindly;
        //TODO: 2 wallets -> 1 for kindly and 1 for ongs
        emit ToSee(price, amountOutMin, amountToSave, amountToKindly, totalConverted);

        //TODO: 2 wallets -> 1 for kindly and 1 for ongs and fetch addresses from factory
        IERC20Upgradeable(path[1]).transfer(0xF2D03fc122038172F6D1ef7893135E8650C30542, amountToKindly);

        IERC20Upgradeable(path[1]).transfer(wallet, amountToSave);

        (bool success, ) = wallet.call{value: address(this).balance}("");
        require(success, "Error: could not send ETH to your desired address");
        emit Transaction(admin, 0xF2D03fc122038172F6D1ef7893135E8650C30542, amountToKindly, toWallet);
    }

    function getLatestPrice() public /*view*/ returns (uint256) {
        (
            /*uint80 roundID*/,
            int256 price,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = chainlink.latestRoundData();
        emit Price(price, uint256(price));
        return uint256(price);
    }
    
    /**
    * @dev setters
    */
    function setAdmin(address _admin) virtual public onlyAdmin {
        require(admin != _admin, "Error, admin already setted");
        admin = _admin;
    }

    function setWallet(address _wallet) virtual public onlyAdmin {
        require(wallet != _wallet, "Error: wallet already setted");
        wallet = _wallet;
    }

    modifier onlyAdmin {
        require(admin == msg.sender, "Error, only admin can call this function");
        _;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
pragma solidity ^0.8.0;

interface IChainlink {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IUniswap {
  function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
  external
  returns (uint[] memory amounts);

  function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
  external
  payable
  returns (uint[] memory amounts);

  function WETH() external pure returns (address);

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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