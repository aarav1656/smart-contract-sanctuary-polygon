// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/Initializable.sol)

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
     * @dev Internal function that returns the initialized version. Returns `_initialized`
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initializing`
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
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
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

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
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
        (bool success, bytes memory returndata) = target.delegatecall(data);
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "../interfaces/IDollar.sol";
import "../interfaces/ITreasury.sol";
import "../interfaces/IOracle.sol";
import "../interfaces/IPool.sol";
import "../interfaces/ICollateralReserve.sol";
import "../interfaces/IBasisAsset.sol";

//import "hardhat/console.sol";

contract Pool is OwnableUpgradeable, ReentrancyGuard, IPool {
    using SafeERC20 for IERC20;

    /* ========== ADDRESSES ================ */
    address public dollar; // DARK ::: (1 DARK) = (0.4 WCRO) + (0.4-WCRO in VVS) + (0.2-WCRO in SKY) if CR = 0.8
    address public share; // SKY

    address public mainCollateral; // WCRO
    address public secondCollateral; // VVS

    address public treasury;

    address public oracleDollar;
    address public oracleShare;
    address public oracleMainCollateral;
    address public oracleSecondCollateral;

    /* ========== STATE VARIABLES ========== */

    mapping(address => uint256) public redeem_main_collateral_balances;
    mapping(address => uint256) public redeem_second_collateral_balances;
    mapping(address => uint256) public redeem_share_balances;

    uint256 private unclaimed_pool_main_collateral_;
    uint256 private unclaimed_pool_second_collateral_;
    uint256 private unclaimed_pool_share_;

    mapping(address => uint256) public last_redeemed;

    // Constants for various precisions
    uint256 private constant PRICE_PRECISION = 1e18;

    // Number of seconds to wait before being able to collectRedemption()
    uint256 public redemption_delay;

    // AccessControl state variables
    bool public mint_paused = false;
    bool public redeem_paused = false;
    bool public contract_allowed = false;
    mapping(address => bool) public whitelisted;

    uint256 private targetCollateralRatio_;

    uint256 public updateStepTargetCR;

    uint256 public updateCoolingTimeTargetCR;

    uint256 public lastUpdatedTargetCR;

    mapping(address => bool) public strategist;

    uint256 public constant T_ZERO_TIMESTAMP = 1672531200; // (Sunday, 1 January 2023 00:00:00 UTC)

    mapping(uint256 => uint256) public totalMintedHourly; // hour_index => total_minted
    mapping(uint256 => uint256) public totalMintedDaily; // day_index => total_minted
    mapping(uint256 => uint256) public totalRedeemedHourly; // hour_index => total_redeemed
    mapping(uint256 => uint256) public totalRedeemedDaily; // day_index => total_redeemed

    uint256 private mintingLimitOnce_;
    uint256 private mintingLimitHourly_;
    uint256 private mintingLimitDaily_;

    /* =================== Added variables (need to keep orders for proxy to work) =================== */
    // ...

    /* ========== EVENTS ========== */

    event TreasuryUpdated(address indexed newTreasury);
    event StrategistStatusUpdated(address indexed account, bool status);
    event MintPausedUpdated(bool mint_paused);
    event RedeemPausedUpdated(bool redeem_paused);
    event ContractAllowedUpdated(bool contract_allowed);
    event WhitelistedUpdated(address indexed account, bool whitelistedStatus);
    event TargetCollateralRatioUpdated(uint256 targetCollateralRatio_);
    event Mint(address indexed account, uint256 dollarAmount, uint256 mainCollateralAmount, uint256 secondCollateralAmount, uint256 shareAmount, uint256 shareFee);
    event Redeem(address indexed account, uint256 dollarAmount, uint256 mainCollateralAmount, uint256 secondCollateralAmount, uint256 shareAmount, uint256 shareFee);
    event CollectRedemption(address indexed account, uint256 mainCollateralAmount, uint256 secondCollateralAmount, uint256 shareAmount);

    /* ========== MODIFIERS ========== */

    modifier onlyTreasury() {
        require(msg.sender == treasury, "!treasury");
        _;
    }

    modifier onlyTreasuryOrOwner() {
        require(msg.sender == treasury || msg.sender == owner(), "!treasury && !owner");
        _;
    }

    modifier onlyStrategist() {
        require(strategist[msg.sender] || msg.sender == treasury || msg.sender == owner(), "!strategist && !treasury && !owner");
        _;
    }

    modifier checkContract() {
        if (!contract_allowed && !whitelisted[msg.sender]) {
            uint256 size;
            address addr = msg.sender;
            assembly {
                size := extcodesize(addr)
            }
            require(size == 0, "contract not allowed");
            require(tx.origin == msg.sender, "contract not allowed");
        }
        _;
    }

    /* ========== CONSTRUCTOR ========== */

    function initialize(
        address _dollar,
        address _share,
        address _mainCollateral,
        address _secondCollateral,
        address _treasury
    ) external initializer {
        OwnableUpgradeable.__Ownable_init();

        dollar = _dollar; // DARK
        share = _share; // SKY
        mainCollateral = _mainCollateral; // CRO
        secondCollateral = _secondCollateral; // VVS

        treasury = _treasury;

        unclaimed_pool_main_collateral_ = 0;
        unclaimed_pool_second_collateral_ = 0;
        unclaimed_pool_share_ = 0;

        targetCollateralRatio_ = 9000; // 90%

        lastUpdatedTargetCR = block.timestamp;

        updateStepTargetCR = 25; // 0.25%

        updateCoolingTimeTargetCR = 6000; // to update every 2 hours

        mintingLimitOnce_ = 50000 ether;
        mintingLimitHourly_ = 100000 ether;
        mintingLimitDaily_ = 1000000 ether;

        redemption_delay = 10;
        mint_paused = false;
        redeem_paused = false;
        contract_allowed = false;
    }

    /* ========== VIEWS ========== */

    function info()
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            bool,
            bool
        )
    {
        return (
            unclaimed_pool_main_collateral_, // unclaimed amount of WCRO
            unclaimed_pool_second_collateral_, // unclaimed amount of VVS
            unclaimed_pool_share_, // unclaimed amount of SHARE
            PRICE_PRECISION, // collateral price
            mint_paused,
            redeem_paused
        );
    }

    function targetCollateralRatio() external override view returns (uint256) {
        return targetCollateralRatio_;
    }

    function unclaimed_pool_main_collateral() external override view returns (uint256) {
        return unclaimed_pool_main_collateral_;
    }

    function unclaimed_pool_second_collateral() external override view returns (uint256) {
        return unclaimed_pool_second_collateral_;
    }

    function unclaimed_pool_share() external override view returns (uint256) {
        return unclaimed_pool_share_;
    }

    function collateralReserve() public view returns (address) {
        return ITreasury(treasury).collateralReserve();
    }

    function getMainCollateralPrice() public view override returns (uint256) {
        address _oracle = oracleMainCollateral;
        return (_oracle == address(0)) ? PRICE_PRECISION : IOracle(oracleMainCollateral).consult();
    }

    function getSecondCollateralPrice() public view override returns (uint256) {
        address _oracle = oracleSecondCollateral;
        return (_oracle == address(0)) ? 1 : IOracle(oracleSecondCollateral).consult();
    }

    function getDollarPrice() public view override returns (uint256) {
        address _oracle = oracleDollar;
        return (_oracle == address(0)) ? PRICE_PRECISION : IOracle(_oracle).consult(); // DOLLAR: default = 1 WCRO
    }

    function getSharePrice() public view override returns (uint256) {
        address _oracle = oracleShare;
        return (_oracle == address(0)) ? PRICE_PRECISION / 100 : IOracle(_oracle).consult(); // SKY: default = 0.01 WCRO
    }

    function getTrueSharePrice() public view returns (uint256) {
        address _oracle = oracleShare;
        return (_oracle == address(0)) ? PRICE_PRECISION / 100 : IOracle(_oracle).consultTrue(); // SKY: default = 0.01 WCRO
    }

    function getRedemptionOpenTime(address _account) public view override returns (uint256) {
        uint256 _last_redeemed = last_redeemed[_account];
        return (_last_redeemed == 0) ? 0 : _last_redeemed + redemption_delay;
    }

    function mintingLimitOnce() public view returns (uint256 _limit) {
        _limit = mintingLimitOnce_;
        if (_limit > 0) {
            _limit = Math.max(_limit, IERC20(dollar).totalSupply() * 25 / 10000); // Max(50k, 0.25% of total supply)
        }
    }

    function mintingLimitHourly() public override view returns (uint256 _limit) {
        _limit = mintingLimitHourly_;
        if (_limit > 0) {
            _limit = Math.max(_limit, IERC20(dollar).totalSupply() * 50 / 10000); // Max(100K, 0.5% of total supply)
        }
    }

    function mintingLimitDaily() public override view returns (uint256 _limit) {
        _limit = mintingLimitDaily_;
        if (_limit > 0) {
            _limit = Math.max(_limit, IERC20(dollar).totalSupply() * 500 / 10000); // Max(1M, 5% of total supply)
        }
    }

    function calcMintableDollarHourly() public override view returns (uint256 _limit) {
        uint256 _mintingLimitHourly = mintingLimitHourly();
        if (_mintingLimitHourly == 0) {
            _limit = 1000000 ether;
        } else {
            uint256 _hourIndex = (block.timestamp - T_ZERO_TIMESTAMP) / 1 hours;
            uint256 _totalMintedHourly = totalMintedHourly[_hourIndex];
            if (_totalMintedHourly < _mintingLimitHourly) {
                _limit = _mintingLimitHourly - _totalMintedHourly;
            }
        }
    }

    function calcMintableDollarDaily() public override view returns (uint256 _limit) {
        uint256 _mintingLimitDaily = mintingLimitDaily();
        if (_mintingLimitDaily == 0) {
            _limit = 1000000 ether;
        } else {
            uint256 _dayIndex = (block.timestamp - T_ZERO_TIMESTAMP) / 1 days;
            uint256 _totalMintedDaily = totalMintedDaily[_dayIndex];
            if (_totalMintedDaily < _mintingLimitDaily) {
                _limit = _mintingLimitDaily - _totalMintedDaily;
            }
        }
    }

    function calcMintableDollar() public override view returns (uint256 _dollarAmount) {
        uint256 _mintingLimitOnce = mintingLimitOnce();
        _dollarAmount = (_mintingLimitOnce == 0) ? 1000000 ether : _mintingLimitOnce;
        if (_dollarAmount > 0) _dollarAmount = Math.min(_dollarAmount, calcMintableDollarHourly());
        if (_dollarAmount > 0) _dollarAmount = Math.min(_dollarAmount, calcMintableDollarDaily());
    }

    function calcRedeemableDollarHourly() public override view returns (uint256 _limit) {
        uint256 _mintingLimitHourly = mintingLimitHourly();
        if (_mintingLimitHourly == 0) {
            _limit = 1000000 ether;
        } else {
            uint256 _hourIndex = (block.timestamp - T_ZERO_TIMESTAMP) / 1 hours;
            uint256 _totalRedeemedHourly = totalRedeemedHourly[_hourIndex];
            if (_totalRedeemedHourly < _mintingLimitHourly) {
                _limit = _mintingLimitHourly - _totalRedeemedHourly;
            }
        }
    }

    function calcRedeemableDollarDaily() public override view returns (uint256 _limit) {
        uint256 _mintingLimitDaily = mintingLimitDaily();
        if (_mintingLimitDaily == 0) {
            _limit = 1000000 ether;
        } else {
            uint256 _dayIndex = (block.timestamp - T_ZERO_TIMESTAMP) / 1 days;
            uint256 _totalRedeemedDaily = totalRedeemedDaily[_dayIndex];
            if (_totalRedeemedDaily < _mintingLimitDaily) {
                _limit = _mintingLimitDaily - _totalRedeemedDaily;
            }
        }
    }

    function calcRedeemableDollar() public override view returns (uint256 _dollarAmount) {
        uint256 _mintingLimitOnce = mintingLimitOnce();
        _dollarAmount = (_mintingLimitOnce == 0) ? 1000000 ether : _mintingLimitOnce;
        if (_dollarAmount > 0) _dollarAmount = Math.min(_dollarAmount, calcRedeemableDollarHourly());
        if (_dollarAmount > 0) _dollarAmount = Math.min(_dollarAmount, calcRedeemableDollarDaily());
    }

    function calcMintInput(uint256 _dollarAmount) public view override returns (uint256 _mainCollateralAmount, uint256 _secondCollateralAmount, uint256 _shareAmount, uint256 _shareFee) {
        uint256 _second_collateral_price = getSecondCollateralPrice();
        uint256 _share_price = getTrueSharePrice();
        uint256 _targetCollateralRatio = targetCollateralRatio_;

        // _dollarFullValue = _dollarAmount (1:1)
        uint256 _collateralFullValue = _dollarAmount * _targetCollateralRatio / 10000;
        _mainCollateralAmount = _collateralFullValue / 2;
        _secondCollateralAmount = _mainCollateralAmount * PRICE_PRECISION / _second_collateral_price;

        uint256 _required_shareValue = _dollarAmount - _collateralFullValue;
        uint256 _mintingFee = ITreasury(treasury).minting_fee();
        uint256 _feePercentOnShare = _mintingFee * 10000 / (10000 - _targetCollateralRatio);

        uint256 _required_shareAmount = _required_shareValue * PRICE_PRECISION / _share_price;
        _shareFee = _required_shareAmount * _feePercentOnShare / 10000;
        _shareAmount = _required_shareAmount + _shareFee;
    }

    // Calculate other minting inputs and outputs from Main Collateral Amount: WCRO
    function calcMintOutputFromMainCollateral(uint256 _mainCollateralAmount) public view override returns (uint256 _dollarAmount, uint256 _secondCollateralAmount, uint256 _shareAmount, uint256 _shareFee) {
        uint256 _second_collateral_price = getSecondCollateralPrice();
        uint256 _share_price = getTrueSharePrice();
        uint256 _targetCollateralRatio = targetCollateralRatio_;

        // _collateralFullValue = _mainCollateralAmount * 2 (WCRO + VVS)
        // _dollarFullValue = _dollarAmount (1:1)
        _secondCollateralAmount = _mainCollateralAmount * PRICE_PRECISION / _second_collateral_price;
        _dollarAmount = _mainCollateralAmount * 20000 / _targetCollateralRatio;

        uint256 _required_shareValue = _dollarAmount - (_mainCollateralAmount * 2);
        uint256 _mintingFee = ITreasury(treasury).minting_fee();
        uint256 _feePercentOnShare = _mintingFee * 10000 / (10000 - _targetCollateralRatio);

        uint256 _required_shareAmount = _required_shareValue * PRICE_PRECISION / _share_price;
        _shareFee = _required_shareAmount * _feePercentOnShare / 10000;
        _shareAmount = _required_shareAmount + _shareFee;
    }

    // Calculate other minting inputs and outputs from Second Collateral Amount: VVS
    function calcMintOutputFromSecondCollateral(uint256 _secondCollateralAmount) public view override returns (uint256 _dollarAmount, uint256 _mainCollateralAmount, uint256 _shareAmount, uint256 _shareFee) {
        uint256 _second_collateral_price = getSecondCollateralPrice();
        uint256 _share_price = getTrueSharePrice();
        uint256 _targetCollateralRatio = targetCollateralRatio_;

        // _secondCollateralFullValue = _mainCollateralAmount
        // _dollarFullValue = _dollarAmount (1:1)
        _mainCollateralAmount = _secondCollateralAmount * _second_collateral_price / PRICE_PRECISION;
        _dollarAmount = _mainCollateralAmount * 20000 / _targetCollateralRatio;

        uint256 _required_shareValue = _dollarAmount - (_mainCollateralAmount * 2);
        uint256 _mintingFee = ITreasury(treasury).minting_fee();
        uint256 _feePercentOnShare = _mintingFee * 10000 / (10000 - _targetCollateralRatio);

        uint256 _required_shareAmount = _required_shareValue * PRICE_PRECISION / _share_price;
        _shareFee = _required_shareAmount * _feePercentOnShare / 10000;
        _shareAmount = _required_shareAmount + _shareFee;
    }

    // Calculate other minting inputs and outputs from Share Amount: SKY
    function calcMintOutputFromShare(uint256 _shareAmount) external view override returns (uint256 _dollarAmount, uint256 _mainCollateralAmount, uint256 _secondCollateralAmount, uint256 _shareFee) {
        if (_shareAmount > 0) {
            uint256 _second_collateral_price = getSecondCollateralPrice();
            uint256 _share_price = getTrueSharePrice();

            uint256 _targetReverseCR = 10000 - targetCollateralRatio_;
            uint256 _feePercentOnShare = ITreasury(treasury).minting_fee() * 10000 / _targetReverseCR;

            uint256 _shareAmountWithoutFee = _shareAmount * 10000 / (10000 + _feePercentOnShare);
            _shareFee = _shareAmount - _shareAmountWithoutFee;

            uint256 _shareFullValueWithoutFee = _shareAmountWithoutFee * _share_price / PRICE_PRECISION;

            // _dollarFullValue = _dollarAmount (1:1)
            _dollarAmount = _shareFullValueWithoutFee * 10000 / _targetReverseCR;

            _mainCollateralAmount = (_dollarAmount - _shareFullValueWithoutFee) / 2;
            _secondCollateralAmount = _mainCollateralAmount * PRICE_PRECISION / _second_collateral_price;
        }
    }

    function calcRedeemOutput(uint256 _dollarAmount) public view override returns (uint256 _mainCollateralAmount, uint256 _secondCollateralAmount, uint256 _shareAmount, uint256 _shareFee) {
        ITreasury _treasury = ITreasury(treasury);

        uint256 _second_collateral_price = getSecondCollateralPrice();
        uint256 _share_price = getTrueSharePrice();
        uint256 _dollar_totalSupply = IERC20(dollar).totalSupply();

        // uint256 _outputRatio = _dollarAmount * 1e18 / IERC20(dollar).totalSupply();

        _mainCollateralAmount = _treasury.globalMainCollateralBalance() * _dollarAmount / _dollar_totalSupply;
        _secondCollateralAmount = _treasury.globalSecondCollateralBalance() * _dollarAmount / _dollar_totalSupply;

        uint256 _collateralFullValue = _mainCollateralAmount + (_secondCollateralAmount * _second_collateral_price / PRICE_PRECISION);
        if (_collateralFullValue < _dollarAmount) {
            uint256 _required_shareValue = _dollarAmount - _collateralFullValue;
            uint256 _redemptionFee = ITreasury(treasury).redemption_fee();
            uint256 _feePercentOnShare = _redemptionFee * _dollarAmount / _required_shareValue;
            uint256 _required_shareAmount = _required_shareValue * PRICE_PRECISION / _share_price;
            if (_feePercentOnShare >= 10000) {
                _shareFee = _required_shareAmount;
                _shareAmount = 0;
            } else {
                _shareFee = _required_shareAmount * _feePercentOnShare / 10000;
                _shareAmount = _required_shareAmount - _shareFee;
            }
        }
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function _increaseMintedStats(uint256 _dollarAmount) internal {
        uint256 _hourIndex = (block.timestamp - T_ZERO_TIMESTAMP) / 1 hours;
        uint256 _dayIndex = (block.timestamp - T_ZERO_TIMESTAMP) / 1 days;
        totalMintedHourly[_hourIndex] = totalMintedHourly[_hourIndex] + _dollarAmount;
        totalMintedDaily[_dayIndex] = totalMintedDaily[_dayIndex] + _dollarAmount;
    }

    function _increaseRedeemedStats(uint256 _dollarAmount) internal {
        uint256 _hourIndex = (block.timestamp - T_ZERO_TIMESTAMP) / 1 hours;
        uint256 _dayIndex = (block.timestamp - T_ZERO_TIMESTAMP) / 1 days;
        totalRedeemedHourly[_hourIndex] = totalRedeemedHourly[_hourIndex] + _dollarAmount;
        totalRedeemedDaily[_dayIndex] = totalRedeemedDaily[_dayIndex] + _dollarAmount;
    }

    function mint(
        uint256 _mainCollateralAmount,
        uint256 _secondCollateralAmount,
        uint256 _shareAmount,
        uint256 _dollarOutMin
    ) external checkContract nonReentrant returns (uint256 _dollarOut, uint256 _required_main_collateralAmount, uint256 _required_second_collateralAmount, uint256 _required_shareAmount, uint256 _shareFee) {
        require(mint_paused == false, "Minting is paused");
        uint256 _mintableDollarLimit = calcMintableDollar() + 100;
        require(_dollarOutMin < _mintableDollarLimit, "over minting cap");

        (_dollarOut, _required_second_collateralAmount, _required_shareAmount, _shareFee) = calcMintOutputFromMainCollateral(_mainCollateralAmount);
        if (_required_second_collateralAmount > _secondCollateralAmount + 100) { // not enough VVS
            (_dollarOut, _required_main_collateralAmount, _required_shareAmount, _shareFee) = calcMintOutputFromSecondCollateral(_secondCollateralAmount);
            require(_required_main_collateralAmount <= _mainCollateralAmount, "not enough mainCol");
        }
        require(_required_shareAmount <= _shareAmount + 100, "not enough share");
        require(_dollarOut >= _dollarOutMin, "slippage");

        (_required_main_collateralAmount, _required_second_collateralAmount, _required_shareAmount, _shareFee) = calcMintInput(_dollarOut);

        // plus some dust for overflow
        require(_required_main_collateralAmount <= _mainCollateralAmount + 100, "not enough mainCol");
        require(_required_second_collateralAmount <= _secondCollateralAmount + 100, "not enough mainCol");
        require(_required_shareAmount <= _shareAmount + 100, "Not enough share");
        require(_dollarOut <= _mainCollateralAmount * 21000 / targetCollateralRatio_, "Insanely big _dollarOut"); // double check - we dont want to mint too much dollar

        _transferCollateralsToReserve(msg.sender, _required_main_collateralAmount, _required_second_collateralAmount);
        _requestToBurnShareFromSender(msg.sender, _required_shareAmount);

        IDollar(dollar).poolMint(msg.sender, _dollarOut);

        _increaseMintedStats(_dollarOut);
        emit Mint(msg.sender, _dollarOut, _required_main_collateralAmount, _required_second_collateralAmount, _required_shareAmount, _shareFee);
    }

    function redeem(
        uint256 _dollarAmount,
        uint256 _main_collateral_out_min,
        uint256 _second_collateral_out_min,
        uint256 _share_out_min
    ) external checkContract nonReentrant returns (uint256 _main_collateral_out, uint256 _second_collateral_out, uint256 _share_out, uint256 _shareFee) {
        require(redeem_paused == false, "Redeeming is paused");
        uint256 _redeemableDollarLimit = calcRedeemableDollar() + 100;
        require(_dollarAmount < _redeemableDollarLimit, "over redeeming cap");

        (_main_collateral_out, _second_collateral_out, _share_out, _shareFee) = calcRedeemOutput(_dollarAmount);
        require(_main_collateral_out >= _main_collateral_out_min, "short of mainCol");
        require(_second_collateral_out >= _second_collateral_out_min, "short of secondCol");
        require(_share_out >= _share_out_min, "short of share");

        redeem_main_collateral_balances[msg.sender] += _main_collateral_out;
        unclaimed_pool_main_collateral_ += _main_collateral_out;

        redeem_second_collateral_balances[msg.sender] += _second_collateral_out;
        unclaimed_pool_second_collateral_ += _second_collateral_out;

        redeem_share_balances[msg.sender] += _share_out;
        unclaimed_pool_share_ += _share_out;

        IDollar(dollar).poolBurnFrom(msg.sender, _dollarAmount);

        last_redeemed[msg.sender] = block.timestamp;
        _increaseRedeemedStats(_dollarAmount);
        emit Redeem(msg.sender, _dollarAmount, _main_collateral_out, _second_collateral_out, _share_out, _shareFee);
    }

    function collectRedemption() external {
        require(getRedemptionOpenTime(msg.sender) <= block.timestamp, "too early");

        uint256 _mainCollateralAmount = redeem_main_collateral_balances[msg.sender];
        if (_mainCollateralAmount > 0) {
            redeem_main_collateral_balances[msg.sender] = 0;
            unclaimed_pool_main_collateral_ -= _mainCollateralAmount;
            _requestTransferFromReserve(mainCollateral, msg.sender, _mainCollateralAmount);
        }

        uint256 _secondCollateralAmount = redeem_second_collateral_balances[msg.sender];
        if (_secondCollateralAmount > 0) {
            redeem_second_collateral_balances[msg.sender] = 0;
            unclaimed_pool_second_collateral_ -= _secondCollateralAmount;
            _requestTransferFromReserve(secondCollateral, msg.sender, _secondCollateralAmount);
        }

        uint256 _shareAmount = redeem_share_balances[msg.sender];
        if (_shareAmount > 0) {
            redeem_share_balances[msg.sender] = 0;
            unclaimed_pool_share_ = unclaimed_pool_share_ - _shareAmount;
            IDollar(share).poolMint(msg.sender, _shareAmount);
        }

        emit CollectRedemption(msg.sender, _mainCollateralAmount, _secondCollateralAmount, _shareAmount);
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    function _transferCollateralsToReserve(address _sender, uint256 _mainCollateralAmount, uint256 _secondCollateralAmount) internal {
        address _reserve = collateralReserve();
        require(_reserve != address(0), "zero");
        if (_mainCollateralAmount > 0) IERC20(mainCollateral).safeTransferFrom(_sender, _reserve, _mainCollateralAmount);
        if (_secondCollateralAmount > 0) IERC20(secondCollateral).safeTransferFrom(_sender, _reserve, _secondCollateralAmount);
        ITreasury(treasury).reserveReceiveCollaterals(_mainCollateralAmount, _secondCollateralAmount);
    }

    function _requestToBurnShareFromSender(address _sender, uint256 _amount) internal {
        if (_amount > 0) {
            IDollar(share).poolBurnFrom(_sender, _amount);
        }
    }

    function _requestTransferFromReserve(address _token, address _receiver, uint256 _amount) internal {
        if (_amount > 0 && _receiver != address(0)) {
            ITreasury(treasury).requestTransfer(_token, _receiver, _amount);
        }
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function setTreasury(address _treasury) external onlyOwner {
        require(_treasury != address(0), "zero");
        treasury = _treasury;
        emit TreasuryUpdated(_treasury);
    }

    function setStrategistStatus(address _account, bool _status) external onlyOwner {
        strategist[_account] = _status;
        emit StrategistStatusUpdated(_account, _status);
    }

    function toggleMinting() external onlyOwner {
        mint_paused = !mint_paused;
        emit MintPausedUpdated(mint_paused);
    }

    function toggleRedeeming() external onlyOwner {
        redeem_paused = !redeem_paused;
        emit RedeemPausedUpdated(redeem_paused);
    }

    function toggleContractAllowed() external onlyOwner {
        contract_allowed = !contract_allowed;
        emit ContractAllowedUpdated(contract_allowed);
    }

    function toggleWhitelisted(address _account) external onlyOwner {
        whitelisted[_account] = !whitelisted[_account];
        emit WhitelistedUpdated(_account, whitelisted[_account]);
    }

    function setMintingLimits(uint256 _mintingLimitOnce, uint256 _mintingLimitHourly, uint256 _mintingLimitDaily) external onlyOwner {
        mintingLimitOnce_ = _mintingLimitOnce;
        mintingLimitHourly_ = _mintingLimitHourly;
        mintingLimitDaily_ = _mintingLimitDaily;
    }

    function setOracleDollar(address _oracleDollar) external onlyOwner {
        require(_oracleDollar != address(0), "zero");
        oracleDollar = _oracleDollar;
    }

    function setOracleShare(address _oracleShare) external onlyOwner {
        require(_oracleShare != address(0), "zero");
        oracleShare = _oracleShare;
    }

    function setOracleMainCollateral(address _oracle) external onlyOwner {
        require(_oracle != address(0), "zero");
        oracleMainCollateral = _oracle;
    }

    function setOracleSecondCollateral(address _oracle) external onlyOwner {
        require(_oracle != address(0), "zero");
        oracleSecondCollateral = _oracle;
    }

    function setRedemptionDelay(uint256 _redemption_delay) external onlyOwner {
        redemption_delay = _redemption_delay;
    }

    function setTargetCollateralRatioConfig(uint256 _updateStepTargetCR, uint256 _updateCoolingTimeTargetCR) external onlyOwner {
        updateStepTargetCR = _updateStepTargetCR;
        updateCoolingTimeTargetCR = _updateCoolingTimeTargetCR;
    }

    function setTargetCollateralRatio(uint256 _targetCollateralRatio) external onlyTreasuryOrOwner {
        require(_targetCollateralRatio <= 9500 && _targetCollateralRatio >= 8000, "OoR");
        lastUpdatedTargetCR = block.timestamp;
        targetCollateralRatio_ = _targetCollateralRatio;
        emit TargetCollateralRatioUpdated(_targetCollateralRatio);
    }

    function updateTargetCollateralRatio() external override onlyStrategist {
        if (lastUpdatedTargetCR + updateCoolingTimeTargetCR <= block.timestamp) { // to avoid update too frequent
            lastUpdatedTargetCR = block.timestamp;
            uint256 _dollarPrice = getDollarPrice();
            if (_dollarPrice >= PRICE_PRECISION) {
                // When DARK is at or above 1 WCRO, meaning the market’s demand for DARK is high,
                // the system should be in de-collateralize mode by decreasing the collateral ratio, minimum to 80%
                targetCollateralRatio_ = Math.max(8000, targetCollateralRatio_ - updateStepTargetCR);
            } else {
                // When the price of DARK is below 1 WCRO, the function increases the collateral ratio, maximum to 95%
                targetCollateralRatio_ = Math.min(9500, targetCollateralRatio_ + updateStepTargetCR);
            }
            emit TargetCollateralRatioUpdated(targetCollateralRatio_);
        }
    }

    /* ========== EMERGENCY ========== */

    function rescueStuckErc20(address _token) external onlyOwner {
        IERC20(_token).transfer(owner(), IERC20(_token).balanceOf(address(this)));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IBasisAsset {
    function decimals() external view returns (uint8);

    function cap() external view returns (uint256);

    function mint(address, uint256) external;

    function burn(uint256) external;

    function burnFrom(address, uint256) external;

    function isOperator() external returns (bool);

    function operator() external view returns (address);

    function transferOperator(address newOperator_) external;

    function transferOwnership(address newOwner_) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface ICollateralReserve {
    function fundBalance(address _token) external view returns (uint256);

    function transferTo(address _token, address _receiver, uint256 _amount) external;

    function burnToken(address _token, uint256 _amount) external;

    function receiveCollaterals(uint256 _mainCollateralAmount, uint256 _secondCollateralAmount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IDollar {
    function poolBurnFrom(address _address, uint256 _amount) external;

    function poolMint(address _address, uint256 _amount) external;

    function mint(address _address, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IOracle {
    function nextEpochPoint() external view returns (uint256);

    function update() external;

    function epochConsult() external view returns (uint256);

    function consult() external view returns (uint256);

    function consultTrue() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IPool {
    function targetCollateralRatio() external view returns (uint256);

    function calcMintInput(uint256 _dollarAmount) external view returns (uint256 _mainCollateralAmount, uint256 _secondCollateralAmount, uint256 _shareAmount, uint256 _shareFee);

    function calcMintOutputFromMainCollateral(uint256 _mainCollateralAmount) external view returns (uint256 _dollarAmount, uint256 _secondCollateralAmount, uint256 _shareAmount, uint256 _shareFee);

    function calcMintOutputFromSecondCollateral(uint256 _secondCollateralAmount) external view returns (uint256 _dollarAmount, uint256 _mainCollateralAmount, uint256 _shareAmount, uint256 _shareFee);

    function calcMintOutputFromShare(uint256 _shareAmount) external view returns (uint256 _dollarAmount, uint256 _mainCollateralAmount, uint256 _secondCollateralAmount, uint256 _shareFee);

    function calcRedeemOutput(uint256 _dollarAmount) external view returns (uint256 _mainCollateralAmount, uint256 _secondCollateralAmount, uint256 _shareAmount, uint256 _shareFee);

    function getMainCollateralPrice() external view returns (uint256);

    function getSecondCollateralPrice() external view returns (uint256);

    function getDollarPrice() external view returns (uint256);

    function getSharePrice() external view returns (uint256);

    function getRedemptionOpenTime(address _account) external view returns (uint256);

    function unclaimed_pool_main_collateral() external view returns (uint256);

    function unclaimed_pool_second_collateral() external view returns (uint256);

    function unclaimed_pool_share() external view returns (uint256);

    function mintingLimitHourly() external view returns (uint256 _limit);

    function mintingLimitDaily() external view returns (uint256 _limit);

    function calcMintableDollarHourly() external view returns (uint256 _limit);

    function calcMintableDollarDaily() external view returns (uint256 _limit);

    function calcMintableDollar() external view returns (uint256 _dollarAmount);

    function calcRedeemableDollarHourly() external view returns (uint256 _limit);

    function calcRedeemableDollarDaily() external view returns (uint256 _limit);

    function calcRedeemableDollar() external view returns (uint256 _dollarAmount);

    function updateTargetCollateralRatio() external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface ITreasury {
    function hasPool(address _address) external view returns (bool);

    function minting_fee() external view returns (uint256);

    function redemption_fee() external view returns (uint256);

    function reserve_farming_percent() external view returns (uint256);

    function collateralReserve() external view returns (address);

    function globalMainCollateralBalance() external view returns (uint256);

    function globalMainCollateralValue() external view returns (uint256);

    function globalSecondCollateralBalance() external view returns (uint256);

    function globalSecondCollateralValue() external view returns (uint256);

    function globalCollateralTotalValue() external view returns (uint256);

    function getEffectiveCollateralRatio() external view returns (uint256);

    function requestTransfer(address token, address receiver, uint256 amount) external;

    function reserveReceiveCollaterals(uint256 _mainCollateralAmount, uint256 _secondCollateralAmount) external;

    function info()
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        );
}