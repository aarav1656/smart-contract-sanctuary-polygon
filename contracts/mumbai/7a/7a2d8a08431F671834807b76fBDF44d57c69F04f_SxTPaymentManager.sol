// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)

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
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
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
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
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
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
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
pragma solidity 0.8.7;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/// @title Admin related functionalities
/// @dev This contract is abstract. It is inherited in SxTRelay and SxTValidator to set and handle admin only functions

abstract contract AdminUpgradeable is Initializable {
    /// @dev Address of admin set by inheriting contracts
    address internal admin;

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __AdminUpgradeable_init() internal onlyInitializing {
        __AdminUpgradeable_init_unchained();
    }

    function __AdminUpgradeable_init_unchained() internal onlyInitializing {
        admin = msg.sender;
    }

    /// @notice Modifier for checking if Admin address has called the function
    modifier onlyAdmin() {
        require(msg.sender == getAdmin(), "admin only function");
        _;
    }

    /**
     * @notice Get the address of Admin wallet
     * @return adminAddress Address of Admin wallet set in the contract
     */
    function getAdmin() public view returns (address adminAddress) {
        return admin;
    }

    /**
     * @notice Set the address of Admin wallet
     * @param  adminAddress Address of Admin wallet to be set in the contract
     */
    function setAdmin(address adminAddress) public onlyAdmin {
        admin = adminAddress;
    }
}

/**
 ________  ________  ________  ________  _______   ________  ________   ________  _________  ___  _____ ______   _______      
|\   ____\|\   __  \|\   __  \|\   ____\|\  ___ \ |\   __  \|\   ___  \|\   ___ \|\___   ___\\  \|\   _ \  _   \|\  ___ \     
\ \  \___|\ \  \|\  \ \  \|\  \ \  \___|\ \   __/|\ \  \|\  \ \  \\ \  \ \  \_|\ \|___ \  \_\ \  \ \  \\\__\ \  \ \   __/|    
 \ \_____  \ \   ____\ \   __  \ \  \    \ \  \_|/_\ \   __  \ \  \\ \  \ \  \ \\ \   \ \  \ \ \  \ \  \\|__| \  \ \  \_|/__  
  \|____|\  \ \  \___|\ \  \ \  \ \  \____\ \  \_|\ \ \  \ \  \ \  \\ \  \ \  \_\\ \   \ \  \ \ \  \ \  \    \ \  \ \  \_|\ \ 
    ____\_\  \ \__\    \ \__\ \__\ \_______\ \_______\ \__\ \__\ \__\\ \__\ \_______\   \ \__\ \ \__\ \__\    \ \__\ \_______\
   |\_________\|__|     \|__|\|__|\|_______|\|_______|\|__|\|__|\|__| \|__|\|_______|    \|__|  \|__|\|__|     \|__|\|_______|
   \|_________|         
 */

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface ISxTPaymentLedger {

    struct Payment {
        address tokenAddress;
        uint128 amount;
        bool isNativePayment;
    }

    /**
     * Event emitted when new payment record is added in contract
     * @param  requestId ID for request for which payment record is to be added
     * @param  paymentReceived Payment amount received for this request
     */    
    event PaymentRecordAdded(        
        bytes32 requestId,
        address tokenAddress,
        uint128 paymentReceived,
        bool isNativePayment
    );

    /**
     * Event emitted when SxTPaymentManager contract is updated
     * @param paymentManagerAddress address of Payment Manager Contract Address
     */ 
    event SxTPaymentManagerUpdated(
        address paymentManagerAddress
    );

    /**
     * @notice Function to get payment record of a prepaid request
     * @param  requestId ID for request to fetch payment record
     */
    function getPaymentRecord(
        bytes32 requestId
    ) external returns (Payment memory);

    /**
     * @notice Function to add ERC20 payment record for a prepaid request
     * @param  requestId ID for request to add payment record for
     * @param  tokenAddress Token address for which the payment is received
     * @param  paymentReceived Payment received for the prepaid request
     */
    function addERC20PaymentRecord(
        bytes32 requestId,
        address tokenAddress,
        uint128 paymentReceived
    ) external;

    /**
     * @notice Function to add Native payment record for a prepaid request
     * @param  requestId ID for request to add payment record for
     * @param  paymentReceived Payment received for the prepaid request
     */
    function addNativePaymentRecord(
        bytes32 requestId,
        uint128 paymentReceived
    ) external;

    /**
     * @notice Function to update payment manager contract address
     * @param paymentManagerAddress address of Payment Manager Contract Address
     */
    function updatePaymentManager(
        address paymentManagerAddress
    ) external;
}

/**
 ________  ________  ________  ________  _______   ________  ________   ________  _________  ___  _____ ______   _______      
|\   ____\|\   __  \|\   __  \|\   ____\|\  ___ \ |\   __  \|\   ___  \|\   ___ \|\___   ___\\  \|\   _ \  _   \|\  ___ \     
\ \  \___|\ \  \|\  \ \  \|\  \ \  \___|\ \   __/|\ \  \|\  \ \  \\ \  \ \  \_|\ \|___ \  \_\ \  \ \  \\\__\ \  \ \   __/|    
 \ \_____  \ \   ____\ \   __  \ \  \    \ \  \_|/_\ \   __  \ \  \\ \  \ \  \ \\ \   \ \  \ \ \  \ \  \\|__| \  \ \  \_|/__  
  \|____|\  \ \  \___|\ \  \ \  \ \  \____\ \  \_|\ \ \  \ \  \ \  \\ \  \ \  \_\\ \   \ \  \ \ \  \ \  \    \ \  \ \  \_|\ \ 
    ____\_\  \ \__\    \ \__\ \__\ \_______\ \_______\ \__\ \__\ \__\\ \__\ \_______\   \ \__\ \ \__\ \__\    \ \__\ \_______\
   |\_________\|__|     \|__|\|__|\|_______|\|_______|\|__|\|__|\|__| \|__|\|_______|    \|__|  \|__|\|__|     \|__|\|_______|
   \|_________|         
 */

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./ISxTPaymentLedger.sol";

interface ISxTPaymentManager {

    struct TokenPrice {
        bool isActive;
        uint128 fees;
    }

    /**
     * event emitted when fees of a token is set in contract
     * @param  tokenAddress Token address to set the fees
     * @param  isActive Boolean for token active or not
     * @param  tokenFees Fees for the token
     */     
    event TokenDetailsUpdated(
        address tokenAddress,
        bool isActive,
        uint128 tokenFees
    );

    /**
     * Event emitted when SxTPaymentLedger contract is updated
     * @param paymentLedgerAddress address of Payment Ledger Contract Address
     */ 
    event SxTPaymentLedgerUpdated(
        ISxTPaymentLedger paymentLedgerAddress
    );

    /**
     * Event emitted when SxTRelay contract is updated
     * @param sxtRelayAddress address of SxTRelay Contract Address
     */ 
    event SxTRelayUpdated(
        address sxtRelayAddress
    );

    /**
     * Event emitted when new treasury wallet is updated in contract
     * @param treasuryWallet Address of new treasury wallet
     */    
    event SxTTreasuryRegistered(address indexed treasuryWallet);

    /**
     * @notice Function to get fees of a token address
     * @param  tokenAddress Symbol to identify currency
     */
    function getTokenDetails(
        address tokenAddress
    ) external returns (TokenPrice memory);

    /**
     * @notice Function to get fees native currency
     */
    function getNativeCurrencyDetails() external returns (uint128);

    /**
     * @notice Function to add Fees of a token address
     * @param  tokenAddress Symbol to identify currency
     */
    function hasTokenFees(
        address tokenAddress
    ) external returns (bool);

    /**
     * @notice Function to accept fees for request in ERC20 Token
     * @param  tokenAddress Symbol to identify currency
     * @param  requestId ID for request to pay fees
     */
    function acceptERC20Payment(
        bytes32 requestId, 
        address tokenAddress
    ) external;

    /**
     * @notice Function to accept fees for request in native currency
     * @param  requestId ID for request to pay fees
     */
    function acceptNativePayment(
        bytes32 requestId
    ) external payable;

    /**
     * Update Payment Ledger Contract Address
     * @param paymentLedgerAddress address of Payment Ledger Contract Address to set
     */
    function updatePaymentLedgerAddress(
        ISxTPaymentLedger paymentLedgerAddress
    ) external;

    /**
     * Update SxTRelay Contract Address
     * @param sxtRelayAddress address of SxTRelay Contract Address to set
     */

    function updateSxTRelayAddress(address sxtRelayAddress) external;
    /**
     * Update treasury address
     * @param treasuryWallet address of treasury wallet
     */
    function updateTreasuryAddress(address treasuryWallet) external;
}

/**
 ________  ________  ________  ________  _______   ________  ________   ________  _________  ___  _____ ______   _______      
|\   ____\|\   __  \|\   __  \|\   ____\|\  ___ \ |\   __  \|\   ___  \|\   ___ \|\___   ___\\  \|\   _ \  _   \|\  ___ \     
\ \  \___|\ \  \|\  \ \  \|\  \ \  \___|\ \   __/|\ \  \|\  \ \  \\ \  \ \  \_|\ \|___ \  \_\ \  \ \  \\\__\ \  \ \   __/|    
 \ \_____  \ \   ____\ \   __  \ \  \    \ \  \_|/_\ \   __  \ \  \\ \  \ \  \ \\ \   \ \  \ \ \  \ \  \\|__| \  \ \  \_|/__  
  \|____|\  \ \  \___|\ \  \ \  \ \  \____\ \  \_|\ \ \  \ \  \ \  \\ \  \ \  \_\\ \   \ \  \ \ \  \ \  \    \ \  \ \  \_|\ \ 
    ____\_\  \ \__\    \ \__\ \__\ \_______\ \_______\ \__\ \__\ \__\\ \__\ \_______\   \ \__\ \ \__\ \__\    \ \__\ \_______\
   |\_________\|__|     \|__|\|__|\|_______|\|_______|\|__|\|__|\|__| \|__|\|_______|    \|__|  \|__|\|__|     \|__|\|_______|
   \|_________|         
 */

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./abstract/Admin.sol";
import "./interfaces/ISxTPaymentManager.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

contract SxTPaymentManager is ISxTPaymentManager, AdminUpgradeable, PausableUpgradeable {

    // Zero Address
    address constant ZERO_ADDRESS = address(0);

    // PaymentLedger Contract
    ISxTPaymentLedger public paymentLedgerContract;

    // Address of treasury wallet
    address public treasury;

    // SxT Relay contract address
    address public sxtRelay;

    // Details for Native currency
    uint128 internal nativeCurrencyFee;

    // Mapping for ERC20 token details
    mapping (address => TokenPrice) internal erc20TokenDetails;

    /**
     * @dev This is the initializer function which sets the admin address of contract and initializes variables
     * @param nativeFees SxTRelay contract address
     * @param erc20TokenAddress SxTRelay contract address
     * @param activateErc20token SxTRelay contract address
     * @param erc20TokenFees SxTRelay contract address
     * @param _paymentLedgerContract SxTRelay contract address
     * @param _treasury treasury wallet contract address
     * @param _sxtRelay SxTRelay contract address
     */
    function initialize(
        uint128 nativeFees,
        address[] memory erc20TokenAddress,
        bool[] memory activateErc20token,
        uint128[] memory erc20TokenFees,
        ISxTPaymentLedger _paymentLedgerContract,
        address _treasury,
        address _sxtRelay
    ) initializer public {
        paymentLedgerContract = _paymentLedgerContract;
        treasury = _treasury;
        sxtRelay = _sxtRelay;
        __AdminUpgradeable_init();
        __Pausable_init();        
        setNativeCurrencyDetails(nativeFees);
        setBulkERC20TokenDetails(erc20TokenAddress, activateErc20token, erc20TokenFees);
    }

    /**
     * @notice Function to get fees of a token address
     * @param  tokenAddress Symbol to identify currency
     */
    function getTokenDetails(
        address tokenAddress
    ) public view override isTokenAvailable(tokenAddress) returns (TokenPrice memory){
        return erc20TokenDetails[tokenAddress];
    }

    /**
     * @notice Function to get fees of native currency
     */
    function getNativeCurrencyDetails() external view override isNativeCurrencyAvailable returns (uint128){
        return nativeCurrencyFee;
    }

    /**
     * @notice Function to set details of a currency for SxT  request fees payment
     * @param  tokenAddress Token address to set the fees
     * @param  isActive Should the currency state be activated
     * @param  tokenFees Fees for the currency
     */
    function setCurrencyDetails(
        address tokenAddress,
        bool isActive,
        uint128 tokenFees
    ) internal onlyAdmin {
        require(tokenFees != 0, "SxTPaymentManager: Cannot set to Zero Fees");
        TokenPrice memory currency = TokenPrice ({
            isActive: isActive,
            fees: tokenFees
        });
        erc20TokenDetails[tokenAddress] = currency;
        emit TokenDetailsUpdated(tokenAddress, isActive, tokenFees);
    }

    /**
     * @notice Function to set details of an ERC20 Token for SxT request fees payment
     * @param  tokenAddress Token address to set the fees
     * @param  isActive Should the token state be activated
     * @param  tokenFees Fees for the token
     */
    function setERC20TokenDetails(
        address tokenAddress,
        bool isActive,
        uint128 tokenFees
    ) public whenNotPaused onlyAdmin {
        require(tokenAddress != ZERO_ADDRESS, "SxTPaymentManager: Cannot set to Zero Address");
        setCurrencyDetails(tokenAddress, isActive, tokenFees);
    }

    /**
     * @notice Function to set details of multiple ERC20 Token in single function call for SxT request fees payment
     * @param  tokenAddress Array of Token addresses to set the fees
     * @param  isActive Array of activation status of tokens
     * @param  tokenFees array of fees for the token
     */
    function setBulkERC20TokenDetails(
        address[] memory tokenAddress,
        bool[] memory isActive,
        uint128[] memory tokenFees
    ) public whenNotPaused onlyAdmin {
        require(
            (tokenAddress.length == isActive.length)
            && (isActive.length == tokenFees.length), 
            "SxTPaymentManager: Array length should be equal"
        );
        for(uint16 index = 0; index < tokenAddress.length; index++){
            setERC20TokenDetails(tokenAddress[index], isActive[index], tokenFees[index]);
        }
    }

    /**
     * @notice Function to set details of Native currency for SxT request fees payment
     * @param  fees Fees for the currency
     */
    function setNativeCurrencyDetails(
        uint128 fees
    ) public whenNotPaused onlyAdmin {
        nativeCurrencyFee = fees; 
    }

    /**
     * @notice Function to accept fees for request in ERC20 Token
     * @param  tokenAddress Symbol to identify currency
     * @param  requestId ID for request to pay fees
     */
    function acceptERC20Payment(bytes32 requestId, address tokenAddress) external override whenNotPaused onlySxTRelay{
        TokenPrice memory currency = getTokenDetails(tokenAddress);
        IERC20 token = IERC20(tokenAddress);
        require(checkAllowance(uint256(currency.fees), token), "SxTPaymentManager: Insufficient Allowance" );
        paymentLedgerContract.addERC20PaymentRecord(requestId, tokenAddress, currency.fees);
        require(token.transferFrom(tx.origin, treasury, uint256(currency.fees)), "SxTPaymentManager: Could not transfer payment");
    }

    /**
     * @notice Function to accept fees for request in native currency
     * @param  requestId ID for request to pay fees
     */
    function acceptNativePayment(bytes32 requestId) external payable override whenNotPaused onlySxTRelay {
        require(msg.value >= uint256(nativeCurrencyFee), "SxTPaymentManager: Insufficient Native currency payment");
        paymentLedgerContract.addNativePaymentRecord(requestId, uint128(msg.value));
        address payable to = payable(treasury);
        to.transfer(msg.value);    
    }

    /**
     * Update Payment Ledger Contract Address
     * @param paymentLedgerAddress address of Payment Ledger Contract Address to set
     */
    function updatePaymentLedgerAddress(ISxTPaymentLedger paymentLedgerAddress) external override whenNotPaused onlyAdmin {
        paymentLedgerContract = paymentLedgerAddress;
        emit SxTPaymentLedgerUpdated(paymentLedgerContract);
    }

    /**
     * Update SxTRelay Contract Address
     * @param sxtRelayAddress address of SxTRelay Contract Address to set
     */
    function updateSxTRelayAddress(address sxtRelayAddress) external override whenNotPaused onlyAdmin {
        sxtRelay = sxtRelayAddress;
        emit SxTRelayUpdated(sxtRelay);
    }

    /**
     * Update treasury address
     * @param treasuryWallet address of treasury wallet
     */
    function updateTreasuryAddress(address treasuryWallet) external override whenNotPaused onlyAdmin {
        treasury = treasuryWallet;
        emit SxTTreasuryRegistered(treasury);
    }

    /**
     * @notice Internal function to check allowance provided by user wallet to SxTPaymentManager Contract
     * @param  amount Amount to check allowance for
     * @param  token ERC20 token instance for which allowance is to be checked
     */
    function checkAllowance(uint256 amount, IERC20 token) internal view returns (bool success){
        success = token.allowance(tx.origin, address(this)) >= amount;  
    }

    /**
     * @notice Function to check if the fees for currency is set in the contract
     * @param  tokenAddress Symbol to identify currency
     */
    function hasTokenFees(
        address tokenAddress
    ) public view override returns (bool){
        return (erc20TokenDetails[tokenAddress].fees > 0 && erc20TokenDetails[tokenAddress].isActive);
    }

    /**
     * @notice Modifier to check if the fees for currency is set in the contract
     * @param  tokenAddress Symbol to identify currency
     */
    modifier isTokenAvailable(
        address tokenAddress
    ) {
        require(hasTokenFees(tokenAddress), "SxTPaymentManager: Token fees not available");
        _;
    }

    /**
     * @notice Modifier to check if the fees for native currency is set in the contract
     */
    modifier isNativeCurrencyAvailable(
    ) {
        require(nativeCurrencyFee > 0, "SxTPaymentManager: Native currency fees not available");
        _;
    }

    /**
     * Modifier to check caller is SxTRelay Contract Address
     */
    modifier onlySxTRelay() {
        require(msg.sender == sxtRelay, "SxTPaymentManager: Caller not SxTRelay contract");
        _;
    }
}