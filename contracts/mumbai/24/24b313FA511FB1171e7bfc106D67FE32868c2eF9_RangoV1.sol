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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
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
interface IERC20PermitUpgradeable {
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../extensions/draft-IERC20PermitUpgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
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
        IERC20PermitUpgradeable token,
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
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMathUpgradeable {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "../../interfaces/IWETH.sol";
import "../../interfaces/IThorchainRouter.sol";
import "../../interfaces/IRangoMessageReceiver.sol";

/// @title The base contract that RangoV1 and all its parents inherit to support refund, on-chain swap, and DEX whitelisting
/// @author Uchiha Sasuke
/// @notice It contains storage for whitelisted contracts, refund ERC20 and native tokens and on-chain swap
contract BaseProxyContract is PausableUpgradeable, OwnableUpgradeable, ReentrancyGuardUpgradeable {
    address payable constant ETH = payable(0x0000000000000000000000000000000000000000);

    /// @notice The maximum possible percent of fee that Rango will receive from user times 10,000, so 300 = 3%
    /// @dev The real fee is calculated by smart routing off-chain, this field only limits the value to prevent mis-calculations
    uint constant MAX_FEE_PERCENT_x_10000 = 300;

    /// @notice The maximum possible percent of fee that third-party dApp will receive from user times 10,000, so 300 = 3%
    /// @dev The real fee is calculated by smart routing off-chain, this field only limits the value to prevent mis-calculations
    uint constant MAX_AFFILIATE_PERCENT_x_10000 = 300;

    using SafeMathUpgradeable for uint;

    /// @dev keccak256("exchange.rango.baseproxycontract")
    bytes32 internal constant BASE_PROXY_CONTRACT_NAMESPACE = hex"c23df90b6466cfd0cbf4f6a578f167d2f60ed56371b4746a3c5973c8543f4fd9";

    struct BaseProxyStorage {
        address payable feeContractAddress;
        address WETH;
        mapping (address => bool) whitelistContracts;
    }

    /// @notice Rango received a fee reward
    /// @param token The address of received token, ZERO address for native
    /// @param wallet The address of receiver wallet
    /// @param amount The amount received as fee
    event FeeReward(address token, address wallet, uint amount);

    /// @notice Some money is sent to dApp wallet as affiliate reward
    /// @param token The address of received token, ZERO address for native
    /// @param wallet The address of receiver wallet
    /// @param amount The amount received as fee
    event AffiliateReward(address token, address wallet, uint amount);

    /// @notice A call to another dex or contract done and here is the result
    /// @param target The address of dex or contract that is called
    /// @param success A boolean indicating that the call was success or not
    /// @param returnData The response of function call
    event CallResult(address target, bool success, bytes returnData);

    /// @notice Output amount of a dex calls is logged
    /// @param _token The address of output token, ZERO address for native
    /// @param amount The amount of output
    event DexOutput(address _token, uint amount);

    /// @notice The output money (ERC20/Native) is sent to a wallet
    /// @param _token The token that is sent to a wallet, ZERO address for native
    /// @param _amount The sent amount
    /// @param _receiver The receiver wallet address
    event SendToken(address _token, uint256 _amount, address _receiver);

    /// @notice Notifies that a new contract is whitelisted
    /// @param _factory The address of the contract
    event ContractWhitelisted(address _factory);

    /// @notice Notifies that a new contract is blacklisted
    /// @param _factory The address of the contract
    event ContractBlacklisted(address _factory);

    /// @notice Notifies that Rango's fee receiver address updated
    /// @param _oldAddress The previous fee wallet address
    /// @param _newAddress The new fee wallet address
    event FeeContractAddressUpdated(address _oldAddress, address _newAddress);

    /// @notice Notifies that admin manually refunded some money
    /// @param _token The address of refunded token, 0x000..00 address for native token
    /// @param _amount The amount that is refunded
    event Refunded(address _token, uint _amount);

    /// @notice The requested call data which is computed off-chain and passed to the contract
    /// @param target The dex contract address that should be called
    /// @param callData The required data field that should be give to the dex contract to perform swap
    struct Call { address spender; address payable target; bytes callData; }

    /// @notice General swap request which is given to us in all relevant functions
    /// @param fromToken The source token that is going to be swapped (in case of simple swap or swap + bridge) or the briding token (in case of solo bridge)
    /// @param toToken The output token of swapping. This is the output of DEX step and is also input of bridging step
    /// @param amountIn The amount of input token to be swapped
    /// @param feeIn The amount of fee charged by Rango
    /// @param affiliateIn The amount of fee charged by affiliator dApp
    /// @param affiliatorAddress The wallet address that the affiliator fee should be sent to
    struct SwapRequest {
        address fromToken;
        address toToken;
        uint amountIn;
        uint feeIn;
        uint affiliateIn;
        address payable affiliatorAddress;
    }

    /// @notice Adds a contract to the whitelisted DEXes that can be called
    /// @param _factory The address of the DEX
    function addWhitelist(address _factory) public onlyOwner {
        BaseProxyStorage storage baseStorage = getBaseProxyContractStorage();
        baseStorage.whitelistContracts[_factory] = true;

        emit ContractWhitelisted(_factory);
    }

    /// @notice Adds a list of contracts to the whitelisted DEXes that can be called
    /// @param _factories The addresses of the DEXes
    function addWhitelists(address[] calldata _factories) external onlyOwner {
        for (uint i = 0; i < _factories.length; i++)
            addWhitelist(_factories[i]);
    }

    /// @notice Removes a contract from the whitelisted DEXes
    /// @param _factory The address of the DEX or dApp
    function removeWhitelist(address _factory) external onlyOwner {
        BaseProxyStorage storage baseStorage = getBaseProxyContractStorage();

        require(baseStorage.whitelistContracts[_factory], 'Factory not found');
        delete baseStorage.whitelistContracts[_factory];

        emit ContractBlacklisted(_factory);
    }

    /// @notice Sets the wallet that receives Rango's fees from now on
    /// @param _address The receiver wallet address
    function updateFeeContractAddress(address payable _address) external onlyOwner {
        BaseProxyStorage storage baseProxyStorage = getBaseProxyContractStorage();

        address oldAddress = baseProxyStorage.feeContractAddress;
        baseProxyStorage.feeContractAddress = _address;

        emit FeeContractAddressUpdated(oldAddress, _address);
    }

    /// @notice Transfers an ERC20 token from this contract to msg.sender
    /// @dev This endpoint is to return money to a user if we didn't handle failure correctly and the money is still in the contract
    /// @dev Currently the money goes to admin and they should manually transfer it to a wallet later
    /// @param _tokenAddress The address of ERC20 token to be transferred
    /// @param _amount The amount of money that should be transfered
    function refund(address _tokenAddress, uint256 _amount) external onlyOwner {
        IERC20Upgradeable ercToken = IERC20Upgradeable(_tokenAddress);
        uint balance = ercToken.balanceOf(address(this));
        require(balance >= _amount, "Insufficient balance");

        SafeERC20Upgradeable.safeTransfer(ercToken, msg.sender, _amount);

        emit Refunded(_tokenAddress, _amount);
    }

    /// @notice Transfers the native token from this contract to msg.sender
    /// @dev This endpoint is to return money to a user if we didn't handle failure correctly and the money is still in the contract
    /// @dev Currently the money goes to admin and they should manually transfer it to a wallet later
    /// @param _amount The amount of native token that should be transfered
    function refundNative(uint256 _amount) external onlyOwner {
        uint balance = address(this).balance;
        require(balance >= _amount, "Insufficient balance");

        _sendToken(ETH, _amount, msg.sender, true, false);

        emit Refunded(ETH, _amount);
    }

    function onChainSwapsPreBridge(
        address _bridgeProxy,
        SwapRequest memory request,
        Call[] calldata calls,
        uint extraFee
    ) internal returns (uint out, uint value) {
        require(_bridgeProxy != ETH, 'Bridge proxy address in Rango contract not set');

        bool isNative = request.fromToken == ETH;
        uint minimumRequiredValue = (isNative ? request.feeIn + request.affiliateIn + request.amountIn : 0) + extraFee;
        require(msg.value >= minimumRequiredValue, 'Send more ETH to cover input amount + fee');

        (, out) = onChainSwapsInternal(request, calls);
        if (request.toToken != ETH)
            approve(request.toToken, _bridgeProxy, out);

        value = (request.toToken == ETH ? (out > 0 ? out : request.amountIn) : 0) + extraFee;
        return (out, value);
    }

    /// @notice Internal function to compute output amount of DEXes
    /// @param request The general swap request containing from/to token and fee/affiliate rewards
    /// @param calls The list of DEX calls
    /// @return The response of all DEX calls and the output amount of the whole process
    function onChainSwapsInternal(SwapRequest memory request, Call[] calldata calls) internal returns (bytes[] memory, uint) {

        uint toBalanceBefore = getBalanceOf(request.toToken);
        uint fromBalanceBefore = getBalanceOf(request.fromToken);

        bytes[] memory result = callSwapsAndFees(request, calls);

        uint toBalanceAfter = getBalanceOf(request.toToken);
        uint fromBalanceAfter = getBalanceOf(request.fromToken);

        if (request.fromToken != ETH)
            require(fromBalanceAfter >= fromBalanceBefore, 'Source token balance on contract must not decrease after swap');
        else
            require(fromBalanceAfter >= fromBalanceBefore - msg.value, 'Source token balance on contract must not decrease after swap');

        uint secondaryBalance;
        if (calls.length > 0) {
            require(toBalanceAfter - toBalanceBefore > 0, "No balance found after swaps");

            secondaryBalance = toBalanceAfter - toBalanceBefore;
            emit DexOutput(request.toToken, secondaryBalance);
        } else {
            secondaryBalance = toBalanceAfter > toBalanceBefore ? toBalanceAfter - toBalanceBefore : request.amountIn;
        }

        return (result, secondaryBalance);
    }

    /// @notice Private function to handle fetching money from wallet to contract, reduce fee/affiliate, perform DEX calls
    /// @param request The general swap request containing from/to token and fee/affiliate rewards
    /// @param calls The list of DEX calls
    /// @dev It checks the whitelisting of all DEX addresses + having enough msg.value as input
    /// @dev It checks the max threshold for fee/affiliate
    /// @return The bytes of all DEX calls response
    function callSwapsAndFees(SwapRequest memory request, Call[] calldata calls) private returns (bytes[] memory) {
        bool isSourceNative = request.fromToken == ETH;
        BaseProxyStorage storage baseProxyStorage = getBaseProxyContractStorage();
        
        // validate
        require(baseProxyStorage.feeContractAddress != ETH, "Fee contract address not set");

        for(uint256 i = 0; i < calls.length; i++) {
            require(baseProxyStorage.whitelistContracts[calls[i].spender], "Contract spender not whitelisted");
            require(baseProxyStorage.whitelistContracts[calls[i].target], "Contract target not whitelisted");
        }

        // Get all the money from user
        uint totalInputAmount = request.feeIn + request.affiliateIn + request.amountIn;
        if (isSourceNative)
            require(msg.value >= totalInputAmount, "Not enough ETH provided to contract");

        // Check max fee/affiliate is respected
        uint maxFee = totalInputAmount * MAX_FEE_PERCENT_x_10000 / 10000;
        uint maxAffiliate = totalInputAmount * MAX_AFFILIATE_PERCENT_x_10000 / 10000;
        require(request.feeIn <= maxFee, 'Requested fee exceeded max threshold');
        require(request.affiliateIn <= maxAffiliate, 'Requested affiliate reward exceeded max threshold');

        // Transfer from wallet to contract
        if (!isSourceNative) {
            for(uint256 i = 0; i < calls.length; i++) {
                approve(request.fromToken, calls[i].spender, totalInputAmount);
            }

            uint balanceBefore = getBalanceOf(request.fromToken);
            SafeERC20Upgradeable.safeTransferFrom(IERC20Upgradeable(request.fromToken), msg.sender, address(this), totalInputAmount);
            uint balanceAfter = getBalanceOf(request.fromToken);

            if(balanceAfter > balanceBefore && balanceAfter - balanceBefore < totalInputAmount)
                revert("Deflationary tokens are not supported by Rango contract");
        }

        // Get Platform fee
        if (request.feeIn > 0) {
            _sendToken(request.fromToken, request.feeIn, baseProxyStorage.feeContractAddress, isSourceNative, false);
            emit FeeReward(request.fromToken, baseProxyStorage.feeContractAddress, request.feeIn);
        }

        // Get affiliator fee
        if (request.affiliateIn > 0) {
            require(request.affiliatorAddress != ETH, "Invalid affiliatorAddress");
            _sendToken(request.fromToken, request.affiliateIn, request.affiliatorAddress, isSourceNative, false);
            emit AffiliateReward(request.fromToken, request.affiliatorAddress, request.affiliateIn);
        }

        bytes[] memory returnData = new bytes[](calls.length);
        for (uint256 i = 0; i < calls.length; i++) {
            (bool success, bytes memory ret) = isSourceNative
                ? calls[i].target.call{value: request.amountIn}(calls[i].callData)
                : calls[i].target.call(calls[i].callData);

            emit CallResult(calls[i].target, success, ret);
            if (!success)
                revert(_getRevertMsg(ret));
            returnData[i] = ret;
        }

        return returnData;
    }

    /// @notice Approves an ERC20 token to a contract to transfer from the current contract
    /// @param token The address of an ERC20 token
    /// @param to The contract address that should be approved
    /// @param value The amount that should be approved
    function approve(address token, address to, uint value) internal {
        SafeERC20Upgradeable.safeApprove(IERC20Upgradeable(token), to, 0);
        SafeERC20Upgradeable.safeIncreaseAllowance(IERC20Upgradeable(token), to, value);
    }

    /// @notice An internal function to send a token from the current contract to another contract or wallet
    /// @dev This function also can convert WETH to ETH before sending if _withdraw flat is set to true
    /// @dev To send native token _nativeOut param should be set to true, otherwise we assume it's an ERC20 transfer
    /// @param _token The token that is going to be sent to a wallet, ZERO address for native
    /// @param _amount The sent amount
    /// @param _receiver The receiver wallet address or contract
    /// @param _nativeOut means the output is native token
    /// @param _withdraw If true, indicates that we should swap WETH to ETH before sending the money and _nativeOut must also be true
    function _sendToken(
        address _token,
        uint256 _amount,
        address _receiver,
        bool _nativeOut,
        bool _withdraw
    ) internal {
        BaseProxyStorage storage baseStorage = getBaseProxyContractStorage();
        emit SendToken(_token, _amount, _receiver);

        if (_nativeOut) {
            if (_withdraw) {
                require(_token == baseStorage.WETH, "token mismatch");
                IWETH(baseStorage.WETH).withdraw(_amount);
            }
            _sendNative(_receiver, _amount);
        } else {
            SafeERC20Upgradeable.safeTransfer(IERC20Upgradeable(_token), _receiver, _amount);
        }
    }

    /// @notice An internal function to send native token to a contract or wallet
    /// @param _receiver The address that will receive the native token
    /// @param _amount The amount of the native token that should be sent
    function _sendNative(address _receiver, uint _amount) internal {
        (bool sent, ) = _receiver.call{value: _amount}("");
        require(sent, "failed to send native");
    }


    /// @notice A utility function to fetch storage from a predefined random slot using assembly
    /// @return s The storage object
    function getBaseProxyContractStorage() internal pure returns (BaseProxyStorage storage s) {
        bytes32 namespace = BASE_PROXY_CONTRACT_NAMESPACE;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            s.slot := namespace
        }
    }

    /// @notice To extract revert message from a DEX/contract call to represent to the end-user in the blockchain
    /// @param _returnData The resulting bytes of a failed call to a DEX or contract
    /// @return A string that describes what was the error
    function _getRevertMsg(bytes memory _returnData) internal pure returns (string memory) {
        // If the _res length is less than 68, then the transaction failed silently (without a revert message)
        if (_returnData.length < 68) return 'Transaction reverted silently';

        assembly {
            // Slice the sighash.
            _returnData := add(_returnData, 0x04)
        }
        return abi.decode(_returnData, (string)); // All that remains is the revert string
    }

    function getBalanceOf(address token) internal view returns (uint) {
        IERC20Upgradeable ercToken = IERC20Upgradeable(token);
        return token == ETH ? address(this).balance : ercToken.balanceOf(address(this));
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "../base/BaseProxyContract.sol";
import "../../interfaces/IRangoAcross.sol";
import "../../interfaces/Interchain.sol";
import "../../interfaces/IRangoHop.sol";
import "../../interfaces/IRangoHyphen.sol";
import "../../interfaces/IRangoThorchain.sol";
import "../../interfaces/IRangoMultichain.sol";
import "../../interfaces/IRangoSynapse.sol";
import "../../interfaces/IRangoStargate.sol";
import "../../interfaces/IRangoCBridge.sol";
import "../../interfaces/IRangoSymbiosis.sol";
import "../../interfaces/IRangoSatellite.sol";
import "../../interfaces/IRangoVoyager.sol";

/// TODO:
// Arbitrum Bridge
// Avalanche Bridge
// Optimism Bridge
// Polygon Bridge
// Rainbow Bridge
// Satellite
// Sifchain
// Wormhole
// allbridge
// symbiosis
// router protocol
// Poly network

/// @title The main contract that users interact with in the source chain
/// @author Uchiha Sasuke
/// @notice It contains all the required functions to swap on-chain or swap + bridge or swap + bridge + swap initiation in a single step
/// @dev To support a new bridge, it inherits from a proxy with the name of that bridge which adds extra function for that specific bridge
/// @dev There are some extra refund functions for admin to get the money back in case of any unwanted problem
/// @dev This contract is being seen via a transparent proxy from openzeppelin
contract RangoV1 is BaseProxyContract {

    /// @notice Initializes the state of all sub bridges contracts that RangoV1 inherited from
    /// @param _weth Address of wrapped token (WETH, WBNB, etc.) on the current chain
    /// @param _feeContractAddress Address of wallet that receives Rango fees
    /// @dev It is the initializer function of proxy pattern, and is equivalent to constructor for normal contracts
    function initialize(
        address _weth,
        address payable _feeContractAddress
    ) public initializer {
        BaseProxyStorage storage baseProxyStorage = getBaseProxyContractStorage();
        
        baseProxyStorage.WETH = _weth;
        baseProxyStorage.feeContractAddress = _feeContractAddress;

        __Ownable_init();
        __Pausable_init();
        __ReentrancyGuard_init();
    }

    /// @notice Enables the contract to receive native ETH token from other contracts including WETH contract
    receive() external payable { }

    struct BridgesProxyStorage {
        address across;
        address cBridge;
        address hop;
        address hyphen;
        address multichain;
        address stargate;
        address synapse;
        address thorchain;
        address symbiosis;
        address satellite;
        address voyager;

    }

    enum BridgeType { Across, CBridge, Hop, Hyphen, Multichain, Stargate, Synapse, Thorchain, Symbiosis, Satellite, Voyager }

    /// @notice Notifies that a bridge contract address is updated
    /// @param _oldAddress The previous deployed address
    /// @param _newAddress The new deployed address
    /// @param _bridgeType The type of updated bridge
    event BridgeAddressUpdated(address _oldAddress, address _newAddress, BridgeType _bridgeType);

    /// @notice Updates the address of deployed bridge contract
    /// @param _address The address
    function updateBridgeProxyAddress(address _address, BridgeType _bridgeType) external onlyOwner {
        address oldAddress = getProxyAddress(_bridgeType);
        setProxyAddress(_bridgeType, _address);

        emit BridgeAddressUpdated(oldAddress, _address, _bridgeType);
    }

    /// @notice Returns the list of valid Rango contracts that can call other contracts for the security purpose
    /// @dev This contains the contracts that can call others via messaging protocols, and excludes DEX-only contracts such as Thorchain
    /// @return List of addresses of Rango contracts that can call other contracts
    function getValidRangoContracts() external view returns (address[] memory) {
        BridgesProxyStorage memory s = getBridgesStorage();

        address[] memory whitelist = new address[](12);
        whitelist[0] = address(this);
        whitelist[1] = s.across;
        whitelist[2] = s.cBridge;
        whitelist[3] = s.hop;
        whitelist[4] = s.hyphen;
        whitelist[5] = s.multichain;
        whitelist[6] = s.stargate;
        whitelist[7] = s.synapse;
        whitelist[8] = s.thorchain;
        whitelist[9] = s.symbiosis;
        whitelist[10] = s.satellite;
        whitelist[11] = s.voyager;

        return whitelist;
    }

    function getProxyAddress(BridgeType bridgeType) public pure returns(address) {
        BridgesProxyStorage memory s = getBridgesStorage();
        if (bridgeType == BridgeType.Across) return s.across;
        if (bridgeType == BridgeType.CBridge) return s.cBridge;
        if (bridgeType == BridgeType.Hop) return s.hop;
        if (bridgeType == BridgeType.Hyphen) return s.hyphen;
        if (bridgeType == BridgeType.Multichain) return s.multichain;
        if (bridgeType == BridgeType.Stargate) return s.stargate;
        if (bridgeType == BridgeType.Synapse) return s.synapse;
        if (bridgeType == BridgeType.Thorchain) return s.thorchain;
        if (bridgeType == BridgeType.Symbiosis) return s.symbiosis;
        if (bridgeType == BridgeType.Satellite) return s.satellite;
        if (bridgeType == BridgeType.Voyager) return s.voyager;

        revert("Unsupported bridge type");
    }

    function setProxyAddress(BridgeType bridgeType, address _newAddress) internal {
        BridgesProxyStorage storage s = getBridgesStorage();
        if (bridgeType == BridgeType.Across) s.across = _newAddress;
        if (bridgeType == BridgeType.CBridge) s.cBridge = _newAddress;
        if (bridgeType == BridgeType.Hop) s.hop = _newAddress;
        if (bridgeType == BridgeType.Hyphen) s.hyphen = _newAddress;
        if (bridgeType == BridgeType.Multichain) s.multichain = _newAddress;
        if (bridgeType == BridgeType.Stargate) s.stargate = _newAddress;
        if (bridgeType == BridgeType.Synapse) s.synapse = _newAddress;
        if (bridgeType == BridgeType.Thorchain) s.thorchain = _newAddress;
        if (bridgeType == BridgeType.Symbiosis) s.symbiosis =_newAddress;
        if (bridgeType == BridgeType.Satellite) s.satellite = _newAddress;
        if (bridgeType == BridgeType.Voyager) s.voyager = _newAddress;
    }

    /// @notice A utility function to fetch storage from a predefined random slot using assembly
    /// @return s The storage object
    /// @dev hex is keccak256("exchange.rango.bridges.proxy")
    function getBridgesStorage() internal pure returns (BridgesProxyStorage storage s) {
        bytes32 namespace = hex"1ed014b447bfe01bc8cf4e9aa355dee866801d51ab06e08144ccd58f6177a3ad";
        // solhint-disable-next-line no-inline-assembly
        assembly {
            s.slot := namespace
        }
    }

    /// @notice Does a simple on-chain swap
    /// @param request The general swap request containing from/to token and fee/affiliate rewards
    /// @param calls The list of DEX calls
    /// @param nativeOut indicates that the output of swaps must be a native token
    /// @return The byte array result of all DEX calls
    function onChainSwaps(
        SwapRequest memory request,
        Call[] calldata calls,
        bool nativeOut
    ) external payable whenNotPaused nonReentrant returns (bytes[] memory) {
        (bytes[] memory result, uint outputAmount) = onChainSwapsInternal(request, calls);

        _sendToken(request.toToken, outputAmount, msg.sender, nativeOut, false);
        return result;
    }

    /// @notice Does a simple on-chain swap
    /// @param request The general swap request containing from/to token and fee/affiliate rewards
    /// @param calls The list of DEX calls
    /// @param nativeOut indicates that the output of swaps must be a native token
    /// @return The byte array result of all DEX calls
    function onChainSwapsWithReceiver(
        SwapRequest memory request,
        Call[] calldata calls,
        bool nativeOut,
        address receiver
    ) external payable whenNotPaused nonReentrant returns (bytes[] memory) {
        (bytes[] memory result, uint outputAmount) = onChainSwapsInternal(request, calls);

        _sendToken(request.toToken, outputAmount, receiver, nativeOut, false);
        return result;
    }

    /// @notice Executes a DEX (arbitrary) call + a Across bridge call
    /// @dev The bridge part is handled in the RangoAcross.sol contract
    /// @param request The general swap request containing from/to token and fee/affiliate rewards
    /// @param calls The list of DEX calls, if this list is empty, it means that there is no DEX call and we are only bridging
    /// @param bridgeRequest required data for the bridging step, including the destination chain and recipient wallet address
    function acrossBridge(
        SwapRequest memory request,
        Call[] calldata calls,
        IRangoAcross.AcrossBridgeRequest memory bridgeRequest
    ) external payable whenNotPaused nonReentrant {
        address a = getProxyAddress(BridgeType.Across);
        (uint out, uint value) = onChainSwapsPreBridge(a, request, calls, 0);
        IRangoAcross(a).acrossBridge{value: value}(request.toToken, out, bridgeRequest);
    }

    /// @notice Executes a DEX (arbitrary) call + a cBridge send function
    /// @param request The general swap request containing from/to token and fee/affiliate rewards
    /// @param calls The list of DEX calls, if this list is empty, it means that there is no DEX call and we are only bridging
    /// @param _receiver The receiver address in the destination chain
    /// @param _dstChainId The network id of destination chain, ex: 10 for optimism
    /// @param _nonce A nonce mechanism used by cBridge that is generated off-chain, it normally is the time.now()
    /// @param _maxSlippage The maximum tolerable slippage by user on cBridge side (The bridge is not 1-1 and may have slippage in big swaps)
    /// @dev The cbridge part is handled in the RangoCBridge.sol contract
    /// @dev If this function is success, user will automatically receive the fund in the destination in his/her wallet (_receiver)
    /// @dev If bridge is out of liquidity somehow after submiting this transaction and success, user must sign a refund transaction which is not currently present here, will be supported soon
    function cBridgeSend(
        SwapRequest memory request,
        Call[] calldata calls,

        // cbridge params
        address _receiver,
        uint64 _dstChainId,
        uint64 _nonce,
        uint32 _maxSlippage
    ) external payable whenNotPaused nonReentrant {
        address a = getProxyAddress(BridgeType.CBridge);
        (uint out, ) = onChainSwapsPreBridge(a, request, calls, 0);
        IRangoCBridge(a).send(_receiver, request.toToken, out, _dstChainId, _nonce, _maxSlippage);
    }

    /// @notice Executes a DEX (arbitrary) call + a cBridge IM function
    /// @dev The cbridge part is handled in the RangoCBridge.sol contract
    /// @param request The general swap request containing from/to token and fee/affiliate rewards
    /// @param calls The list of DEX calls, if this list is empty, it means that there is no DEX call and we are only bridging
    /// @param _receiverContract Our RangoCbridge.sol contract in the destination chain that will handle the destination logic
    /// @param _dstChainId The network id of destination chain, ex: 10 for optimism
    /// @param _nonce A nonce mechanism used by cBridge that is generated off-chain, it normally is the time.now()
    /// @param _maxSlippage The maximum tolerable slippage by user on cBridge side (The bridge is not 1-1 and may have slippage in big swaps)
    /// @param _sgnFee The fee amount (in native token) that cBridge IM charges for delivering the message
    /// @param imMessage Our custom interchain message that contains all the required info for the RangoCBridge.sol on the destination
    /// @dev The msg.value should at least be _sgnFee + (input + fee + affiliate) if input is native token
    /**
     * @dev Here is the overall flow for a cross-chain dApp that integrates Rango + cBridgeIM:
     * Example case: RangoSea is an imaginary cross-chain OpenSea that users can lock their NFT on BSC to get 100 BNB
     * and convert it to FTM to buy another NFT there, all in one TX.
     * RangoSea contract = RS
     * Rango contract = R
     *
     * 1. RangoSea server asks Rango for a quote of 100 BSC.BNB to Fantom.FTM and embeds the message (imMessage.dAppMessage) that should be received by RS on destination
     * 2. User signs sellNFTandBuyCrosschain on RS
     * 3. RS executes their own logic and locks the NFT, gets 100 BNB and calls R with the hex from step 1 (which is cBridgeIM function call)
     * 4. R on source chain does the required swap/bridge
     * 5. R on destination receives the message via Celer network (by calling RangoCBridge.executeMessageWithTransfer on dest) and does other Rango internal stuff on destination to have the final FTM
     * 6. R on dest sends fund to RS on dest and calls their handler function for message handling and passes imMessage.dAppMessage to it
     * 7. RS on destination has the money and the message it needs to buy the NFT on destination and if it is still available it will be purchased
     *
     * Failure scenarios:
     * If cBridge does not have enough liquidity later:
     * 1. Celer network will call (RangoCBridge on source chain).executeMessageWithTransferRefund function
     * 2. RangoCbridge will refund money to the RS contract on source and ask it to handle refund to their own users
     *
     * If something on the destination fails:
     * 1. Celer network will call (RangoCBridge on dest chain).executeMessageWithTransferFallback function
     * 2. R on dest sends fund to RS on dest with refund reason, again RS should send it to your user if you like
     *
     * Hint: The dAppMessage part is arbitrary, if it's not set. The scenario is the same as above but without RS being in. In this case Rango will refund to the end-user.
     * Here is the celer IM docs: https://im-docs.celer.network/
     */
    function cBridgeIM(
        SwapRequest memory request,
        Call[] calldata calls,

        address _receiverContract, // The receiver app contract address, not recipient
        uint64 _dstChainId,
        uint64 _nonce,
        uint32 _maxSlippage,
        uint _sgnFee,

        Interchain.RangoInterChainMessage memory imMessage
    ) external payable whenNotPaused nonReentrant {
        address a = getProxyAddress(BridgeType.CBridge);
        (uint out, uint value) = onChainSwapsPreBridge(a, request, calls, _sgnFee);

        IRangoCBridge(a).cBridgeIM{value: value}(
            request.toToken,
            out,
            _receiverContract,
            _dstChainId,
            _nonce,
            _maxSlippage,
            _sgnFee,
            imMessage
        );
    }


    /// @notice Executes a DEX (arbitrary) call + a Hop bridge call
    /// @dev The bridge part is handled in the RangoHop.sol contract
    /// @param request The general swap request containing from/to token and fee/affiliate rewards
    /// @param calls The list of DEX calls, if this list is empty, it means that there is no DEX call and we are only bridging
    /// @param bridgeRequest required data for the bridging step, including the destination chain and recipient wallet address
    function hopBridge(
        SwapRequest memory request,
        Call[] calldata calls,
        IRangoHop.HopRequest memory bridgeRequest
    ) external payable whenNotPaused nonReentrant {
        address a = getProxyAddress(BridgeType.Hop);
        (uint out, uint value) = onChainSwapsPreBridge(a, request, calls, 0);

        IRangoHop(a).hopBridge{value: value}(bridgeRequest, request.toToken, out);
    }

    /// @notice Executes a DEX (arbitrary) call + a hyphen bridge function
    /// @param request The general swap request containing from/to token and fee/affiliate rewards
    /// @param calls The list of DEX calls, if this list is empty, it means that there is no DEX call and we are only bridging
    /// @param bridgeRequest data related to hyphen bridge
    /// @dev The hyphen bridge part is handled in the RangoHyphen.sol contract
    /// @dev If this function is a success, user will automatically receive the fund in the destination in their wallet (_receiver)
    function hyphenBridge(
        SwapRequest memory request,
        Call[] calldata calls,
        IRangoHyphen.HyphenBridgeRequest memory bridgeRequest
    ) external payable whenNotPaused nonReentrant {
        address a = getProxyAddress(BridgeType.Hyphen);
        (uint out, uint value) = onChainSwapsPreBridge(a, request, calls, 0);

        IRangoHyphen(a).hyphenBridge{value: value}(bridgeRequest, request.toToken, out);
    }

    /// @notice Executes a DEX (arbitrary) call + a MultichainOrg bridge call
    /// @dev The cbridge part is handled in the RangoMultichain.sol contract
    /// @param request The general swap request containing from/to token and fee/affiliate rewards
    /// @param calls The list of DEX calls, if this list is empty, it means that there is no DEX call and we are only bridging
    /// @param bridgeRequest required data for the bridging step, including the destination chain and recipient wallet address
    function multichainBridge(
        SwapRequest memory request,
        Call[] calldata calls,
        IRangoMultichain.MultichainBridgeRequest memory bridgeRequest
    ) external payable whenNotPaused nonReentrant {
        address a = getProxyAddress(BridgeType.Multichain);
        (uint out, uint value) = onChainSwapsPreBridge(a, request, calls, 0);
        IRangoMultichain(a).multichainBridge{value: value}(request.toToken, out, bridgeRequest);
    }

    function stargateSwap(
        SwapRequest memory request,
        Call[] calldata calls,
        IRangoStargate.StargateRequest memory stargateRequest
    ) external payable whenNotPaused nonReentrant {
        address a = getProxyAddress(BridgeType.Stargate);
        (uint out, uint value) = onChainSwapsPreBridge(a, request, calls, stargateRequest._stgFee);
        IRangoStargate(a).stargateSwap{value: value}(request.toToken, out, stargateRequest);
    }

    /// @notice Executes a DEX (arbitrary) call + a Synapse bridge call
    /// @dev The Synapse part is handled in the RangoSynapse.sol contract
    /// @param request The general swap request containing from/to token and fee/affiliate rewards
    /// @param calls The list of DEX calls, if this list is empty, it means that there is no DEX call and we are only bridging
    /// @param bridgeRequest required data for the bridging step, including the destination chain and recipient wallet address
    function synapseBridge(
        SwapRequest memory request,
        Call[] calldata calls,
        IRangoSynapse.SynapseBridgeRequest memory bridgeRequest
    ) external payable whenNotPaused nonReentrant {
        address a = getProxyAddress(BridgeType.Synapse);
        (uint out, uint value) = onChainSwapsPreBridge(a, request, calls, 0);
        IRangoSynapse(a).synapseBridge{value : value}(request.toToken, out, bridgeRequest);
    }

    /// @notice Swap tokens if necessary, then pass it to RangoThorchain
    /// @dev Swap tokens if necessary, then pass it to RangoThorchain. If no swap is required (calls.length==0) the provided token is passed to RangoThorchain without change.
    /// @param request The swap information used to check input and output token addresses and balances, as well as the fees if any. Together with calls param, determines the swap logic before passing to Thorchain.
    /// @param calls The contract call data that is used to swap (can be empty if no swap is needed). Together with request param, determines the swap logic before passing to Thorchain.
    /// @param tcRouter The router contract address of Thorchain. This cannot be hardcoded because Thorchain can upgrade its router and the address might change.
    /// @param tcVault The vault address of Thorchain. This cannot be hardcoded because Thorchain rotates vaults.
    /// @param thorchainMemo The transaction memo used by Thorchain which contains the thorchain swap data. More info: https://dev.thorchain.org/thorchain-dev/memos
    /// @param expiration The expiration block number. If the tx is included after this block, it will be reverted.
    function swapInToThorchain(
        SwapRequest memory request,
        Call[] calldata calls,

        address tcRouter,
        address tcVault,
        string calldata thorchainMemo,
        uint expiration
    ) external payable whenNotPaused nonReentrant {
        address a = getProxyAddress(BridgeType.Thorchain);
        (uint out, uint value) = onChainSwapsPreBridge(a, request, calls, 0);

        IRangoThorchain(a).swapInToThorchain{value : value}(
            request.toToken,
            out,
            tcRouter,
            tcVault,
            thorchainMemo,
            expiration
        );
    }

    /// @notice Executes a DEX call + a Symbiosis bridge call + a Dex call
    /// @dev The Symbiosis part is handled in the RangoSymbiosis.sol contract
    /// @param request The general swap request containing from/to token and fee/affiliate rewards
    /// @param calls The list of DEX calls, if this list is empty, it means that there is no DEX call and we are only bridging
    /// @param bridgeRequest required data for the bridging step, including the destination chain and recipient wallet address
    function symbiosisBridge(
        SwapRequest memory request,
        Call[] calldata calls,
        IRangoSymbiosis.SymbiosisBridgeRequest memory bridgeRequest
    ) external payable whenNotPaused nonReentrant {
        address a = getProxyAddress(BridgeType.Symbiosis);
        (uint out, uint value) = onChainSwapsPreBridge(a, request, calls, 0);
        IRangoSymbiosis(a).symbiosisBridge{value : value}(
            request.toToken, out, bridgeRequest
        );
    }

    /// @notice Executes a DEX (arbitrary) call + a Satellite bridge call
    /// @dev The Satellite part is handled in the RangoSatellite.sol contract
    /// @param request The general swap request containing from/to token and fee/affiliate rewards
    /// @param calls The list of DEX calls, if this list is empty, it means that there is no DEX call and we are only bridging
    /// @param bridgeRequest required data for the bridging step, including the destination chain and recipient wallet address
    function satelliteBridge(
        SwapRequest memory request,
        Call[] calldata calls,
        IRangoSatellite.SatelliteBridgeRequest memory bridgeRequest
    ) external payable whenNotPaused nonReentrant {
        address a = getProxyAddress(BridgeType.Satellite);
        (uint out, uint value) = onChainSwapsPreBridge(a, request, calls, 0);
        IRangoSatellite(a).satelliteBridge{value : value}(request.toToken, out, bridgeRequest);
    } 
    
    function voyagerBridge(
        SwapRequest memory request,
        Call[] calldata calls,
        IRangoVoyager.VoyagerBridgeRequest memory bridgeRequest
    ) external payable whenNotPaused nonReentrant {

        BaseProxyStorage storage baseProxyStorage = getBaseProxyContractStorage();
        require(bridgeRequest.feeTokenAddress == baseProxyStorage.WETH,
            "Fee is only acceptable in native token"
        );

        address a = getProxyAddress(BridgeType.Voyager);
        (uint out, uint value) = onChainSwapsPreBridge(a, request, calls, bridgeRequest.feeAmount);

        IRangoVoyager(a).voyagerBridge{value : value}(request.toToken, out, bridgeRequest);
    }

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

/// @title An interface to RangoAcross.sol contract to improve type hinting
/// @author Uchiha Sasuke
interface IRangoAcross {
    /// @notice The request object for Across bridge call
    /// @param spokePoolAddress The address of Across spoke pool that deposit should be done to
    /// @param recipient Address to receive funds at on destination chain.
    /// @param originToken Token to lock into this contract to initiate deposit.
    /// @param destinationChainId Denotes network where user will receive funds from SpokePool by a relayer.
    /// @param relayerFeePct % of deposit amount taken out to incentivize a fast relayer.
    /// @param quoteTimestamp Timestamp used by relayers to compute this deposit's realizedLPFeePct which is paid to LP pool on HubPool.
    struct AcrossBridgeRequest {
        address spokePoolAddress;
        address recipient;
        address originToken;
        uint256 destinationChainId;
        uint64 relayerFeePct;
        uint32 quoteTimestamp;
    }

    /// @notice Executes an Across bridge call
    /// @param fromToken The erc20 address of the input token, 0x000...00 for native token
    /// @param amount Amount of tokens to deposit. Will be amount of tokens to receive less fees.
    /// @param request The other required fields for across bridge contract
    function acrossBridge(address fromToken, uint256 amount, AcrossBridgeRequest memory request) external payable;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "./Interchain.sol";

/// @title An interface to RangoCBridge.sol contract to improve type hinting
/// @author Uchiha Sasuke
interface IRangoCBridge {
    /// @notice Executes a cBridgeIM call
    /// @param _fromToken The address of source token to bridge
    /// @param _inputAmount The amount of input to be bridged
    /// @param _receiverContract Our RangoCbridge.sol contract in the destination chain that will handle the destination logic
    /// @param _dstChainId The network id of destination chain, ex: 10 for optimism
    /// @param _nonce A nonce mechanism used by cBridge that is generated off-chain, it normally is the time.now()
    /// @param _maxSlippage The maximum tolerable slippage by user on cBridge side (The bridge is not 1-1 and may have slippage in big swaps)
    /// @param _sgnFee The fee amount (in native token) that cBridge IM charges for delivering the message
    /// @param imMessage Our custom interchain message that contains all the required info for the RangoCBridge.sol on the destination
    function cBridgeIM(
        address _fromToken,
        uint _inputAmount,
        address _receiverContract, // The receiver app contract address, not recipient
        uint64 _dstChainId,
        uint64 _nonce,
        uint32 _maxSlippage,
        uint _sgnFee,

        Interchain.RangoInterChainMessage memory imMessage
    ) external payable;

    /// @notice Executes a bridging via cBridge
    /// @param _receiver The receiver address in the destination chain
    /// @param _token The token address to be bridged
    /// @param _amount The amount of the token to be bridged
    /// @param _dstChainId The network id of destination chain, ex: 10 for optimism
    /// @param _nonce A nonce mechanism used by cBridge that is generated off-chain, it normally is the time.now()
    /// @param _maxSlippage The maximum tolerable slippage by user on cBridge side (The bridge is not 1-1 and may have slippage in big swaps)
    function send(
        address _receiver,
        address _token,
        uint256 _amount,
        uint64 _dstChainId,
        uint64 _nonce,
        uint32 _maxSlippage
    ) external;

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

/// @title An interface to RangoHop.sol contract to improve type hinting
/// @author Uchiha Sasuke
interface IRangoHop {
    enum HopActionType { SWAP_AND_SEND, SEND_TO_L2 }

    struct HopRequest {
        HopActionType actionType;
        address bridgeAddress;
        uint256 chainId;
        address recipient;
        uint256 bonderFee;
        uint256 amountOutMin;
        uint256 deadline;
        uint256 destinationAmountOutMin;
        uint256 destinationDeadline;
        address relayer;
        uint256 relayerFee;
    }

    /// @notice Executes a Hop bridge call
    /// @param _request The request object containing required field by hop bridge
    /// @param _amount The amount to be bridged
    function hopBridge(
        HopRequest memory _request,
        address fromToken,
        uint _amount
    ) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

/// @title An interface to RangoHyphen.sol contract to improve type hinting
/// @author Hellboy
interface IRangoHyphen {

    /// @param receiver The receiver address in the destination chain
    /// @param toChainId The network id of destination chain, ex: 56 for BSC
    struct HyphenBridgeRequest {
        address receiver;
        uint256 toChainId;
    }

    /// @notice Executes a bridging via hyphen
    /// @param _request The extra fields required by the hyphen bridge
    /// @param _token The requested token to bridge
    /// @param _amount The requested amount to bridge
    function hyphenBridge(HyphenBridgeRequest memory _request, address _token, uint256 _amount) external payable;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

interface IRangoMessageReceiver {
    enum ProcessStatus { SUCCESS, REFUND_IN_SOURCE, REFUND_IN_DESTINATION }

    function handleRangoMessage(
        address _token,
        uint _amount,
        ProcessStatus _status,
        bytes memory _message
    ) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "./Interchain.sol";

/// @title An interface to RangoMultichain.sol contract to improve type hinting
/// @author Uchiha Sasuke
interface IRangoMultichain {
    enum MultichainBridgeType { OUT, OUT_UNDERLYING, OUT_NATIVE, OUT_AND_CALL }

    /// @notice The request object for MultichainOrg bridge call
    /// @param _actionType The type of bridge action which indicates the name of the function of MultichainOrg contract to be called
    /// @param _underlyingToken For _actionType = OUT_UNDERLYING, it's the address of the underlying token
    /// @param _multichainRouter Address of MultichainOrg contract on the current chain
    /// @param _receiverAddress The address of end-user on the destination
    /// @param _receiverChainID The network id of destination chain
    struct MultichainBridgeRequest {
        IRangoMultichain.MultichainBridgeType _actionType;
        address _underlyingToken;
        address _multichainRouter;
        address _receiverAddress;
        uint _receiverChainID;
        address _receiverContract;

        Interchain.RangoInterChainMessage _payload;
    }

    /// @notice Executes a MultichainOrg bridge call
    /// @param _fromToken The address of bridging token
    /// @param _inputAmount The amount of the token to be bridged
    /// @param _request The other required field by MultichainOrg bridge
    function multichainBridge(
        address _fromToken, 
        uint _inputAmount, 
        MultichainBridgeRequest memory _request
    ) external payable;

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./Interchain.sol";

/// @title An interface to RangoSatellite.sol contract to improve type hinting
/// @author Hellboy
interface IRangoSatellite {

    enum SatelliteBridgeType { TRANSFER, TRANSFER_WITH_MESSAGE }

    /// @param receiver The receiver address in the destination chain
    /// @param toChainId The network id of destination chain, ex: 56 for BSC
    struct SatelliteBridgeRequest {
        SatelliteBridgeType _bridgeType;

        address receiver;
        uint256 toChainId;
        string toChain;
        string symbol;

        Interchain.RangoInterChainMessage imMessage;
    }

    /// @notice Executes a bridging via satellite
    /// @param _request The extra fields required by the satellite bridge
    /// @param _token The requested token to bridge
    /// @param _amount The requested amount to bridge
    function satelliteBridge(address _token, uint256 _amount, SatelliteBridgeRequest memory _request) external payable;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "./IStargateRouter.sol";
import "./Interchain.sol";

/// @title An interface to RangoStargate.sol contract to improve type hinting
/// @author Uchiha Sasuke
interface IRangoStargate {
    enum StargateBridgeType { TRANSFER, TRANSFER_WITH_MESSAGE }

    struct StargateRequest {
        StargateBridgeType _bridgeType;
        uint16 _dstChainId;
        uint256 _srcPoolId;
        uint256 _dstPoolId;
        address payable _refundAddress;
        uint256 _minAmountLD;

        uint256 _dstGasForCall;
        uint256 _dstNativeAmount;
        bytes _dstNativeAddr;

        bytes _to;
        uint _stgFee;
        
        Interchain.RangoInterChainMessage _payload;
    }

    /// @notice Executes a Stargate call
    /// @param _fromToken The address of source token to bridge
    /// @param _inputAmount The amount of input to be bridged
    /// @param _stargateRequest Required bridge params + interchain message that contains all the required info for the RangoStargate.sol on the destination
    function stargateSwap(
        address _fromToken,
        uint _inputAmount,
        StargateRequest memory _stargateRequest
    ) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./Interchain.sol";

interface IRangoSymbiosis {

    struct SymbiosisBridgeRequest {
        SymbiosisBridgeType bridgeType;
        bool hasFinalCall;
        MetaRouteTransaction metaRouteTransaction;
        SwapData swapData;
        BridgeData bridgeData;
        UserData userData;
        OtherSideData otherSideData;
        Interchain.RangoInterChainMessage imMessage;
    }

    enum SymbiosisBridgeType {META_BURN, META_SYNTHESIZE}

    struct MetaRouteTransaction {
        bytes firstSwapCalldata;
        bytes secondSwapCalldata;
        address[] approvedTokens;
        address firstDexRouter;
        address secondDexRouter;
        uint256 amount;
        bool nativeIn;
        address relayRecipient;
        bytes otherSideCalldata;
    }

    struct SwapData {
        bytes poolData;
        address poolAddress;
    }

    struct BridgeData {
        address oppositeBridge;
        uint256 chainID;
        bytes32 clientID;
    }

    struct UserData {
        address receiveSide;
        address revertableAddress;
        address token;
        address syntCaller;
    }

    struct OtherSideData {
        uint256 stableBridgingFee;
        uint256 amount;
        address chain2address;
        address[] swapTokens;
        address finalReceiveSide;
        address finalToken;
        uint256 finalAmount;
    }

    struct MetaBurnTransaction {
        uint256 stableBridgingFee;
        uint256 amount;
        address syntCaller;
        address finalReceiveSide;
        address sToken;
        bytes finalCallData;
        uint256 finalOffset;
        address chain2address;
        address receiveSide;
        address oppositeBridge;
        address revertableAddress;
        uint256 chainID;
        bytes32 clientID;
    }

    struct MetaSynthesizeTransaction {
        uint256 stableBridgingFee;
        uint256 amount;
        address rToken;
        address chain2address;
        address receiveSide;
        address oppositeBridge;
        address syntCaller;
        uint256 chainID;
        address[] swapTokens;
        address secondDexRouter;
        bytes secondSwapCalldata;
        address finalReceiveSide;
        bytes finalCalldata;
        uint256 finalOffset;
        address revertableAddress;
        bytes32 clientID;
    }

    /// @notice Executes a bridging via symbiosis
    /// @param _token The requested token to bridge
    /// @param _amount The requested amount to bridge
    /// @param _request The extra fields required by the symbiosis bridge
    function symbiosisBridge(
        address _token,
        uint256 _amount,
        SymbiosisBridgeRequest memory _request
    ) external payable;

    /// @notice Complete bridge in destination chain
    /// @param _amount The requested amount to bridge
    /// @param _token The received token after bridge
    /// @param _receivedMessage imMessage to send in destination chain
    function messageReceive(
        uint256 _amount,
        address _token,
        Interchain.RangoInterChainMessage memory _receivedMessage
    ) external payable;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;


/// @title An interface to RangoSynapse.sol contract to improve type hinting
/// @author Rango DeXter
interface IRangoSynapse {

    enum SynapseBridgeType {
        SWAP_AND_REDEEM,
        SWAP_ETH_AND_REDEEM,
        SWAP_AND_REDEEM_AND_SWAP,
        SWAP_AND_REDEEM_AND_REMOVE,
        REDEEM,
        REDEEM_AND_SWAP,
        REDEEM_AND_REMOVE,
        DEPOSIT,
        DEPOSIT_ETH,
        DEPOSIT_AND_SWAP,
        DEPOSIT_ETH_AND_SWAP,
        ZAP_AND_DEPOSIT,
        ZAP_AND_DEPOSIT_AND_SWAP
    }

    /// @notice The request object for Synapse bridge call
    struct SynapseBridgeRequest {
        SynapseBridgeType bridgeType;
        address router;
        address to;
        uint256 chainId;
        address token;
        uint8 tokenIndexFrom;
        uint8 tokenIndexTo;
        uint256 minDy;
        uint256 deadline;
        uint8 swapTokenIndexFrom;
        uint8 swapTokenIndexTo;
        uint256 swapMinDy;
        uint256 swapDeadline;
        uint256[] liquidityAmounts;
    }

    event SynapseBridgeEvent(
        address inputToken,
        uint inputAmount,
        SynapseBridgeType bridgeType,
        address to,
        uint256 chainId,
        address token
    );

    event SynapseBridgeDetailEvent(
        uint8 tokenIndexFrom,
        uint8 tokenIndexTo,
        uint256 minDy,
        uint256 deadline,
        uint8 swapTokenIndexFrom,
        uint8 swapTokenIndexTo,
        uint256 swapMinDy,
        uint256 swapDeadline
    );

    /// @notice Executes a Synapse bridge call
    /// @param inputToken The address of bridging token
    /// @param inputAmount The amount of the token to be bridged
    /// @param request required data for bridge
    function synapseBridge(
        address inputToken,
        uint inputAmount,
        SynapseBridgeRequest memory request
    ) external payable;

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

/// @title Interface to interact with RangoThorchain contract.
/// @author Thinking Particle
interface IRangoThorchain {
    /// @notice Defines parameters used for swapIn functionality on thorchain router.
    /// @param token The token contract address (if token is native, should be 0x0000000000000000000000000000000000000000)
    /// @param amount The amount of token to be swapped. It should be positive and if token is native, msg.value should be bigger than amount.
    /// @param tcRouter The router contract address of Thorchain. This cannot be hardcoded because Thorchain can upgrade its router and the address might change.
    /// @param tcVault The vault address of Thorchain. This cannot be hardcoded because Thorchain rotates vaults.
    /// @param thorchainMemo The transaction memo used by Thorchain which contains the thorchain swap data. More info: https://dev.thorchain.org/thorchain-dev/memos
    /// @param expiration The expiration block number. If the tx is included after this block, it will be reverted.
    function swapInToThorchain(
        address token,
        uint amount,
        address tcRouter,
        address tcVault,
        string calldata thorchainMemo,
        uint expiration
    ) external payable;

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "./Interchain.sol";

/// @title An interface to RangoVoyager.sol contract to improve type hinting
/// @author Uchiha Sasuke
interface IRangoVoyager {
    /// @notice The request object for Voyager bridge call
    struct VoyagerBridgeRequest {
        uint8 voyagerDestinationChainId;
        bytes32 resourceID;
        address feeTokenAddress;
        address reserveContract;
        uint256 dstTokenAmount;
        uint256 feeAmount;
        bytes data;
    }

    /// @notice Executes an Voyager bridge call
    /// @param fromToken The erc20 address of the input token, 0x000...00 for native token
    /// @param amount Amount of tokens to deposit. Will be amount of tokens to receive less fees.
    /// @param request The other required fields for Voyager bridge contract
    function voyagerBridge(address fromToken, uint256 amount, VoyagerBridgeRequest memory request) external payable;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.13;

interface IStargateRouter {
    struct lzTxObj {
        uint256 dstGasForCall;
        uint256 dstNativeAmount;
        bytes dstNativeAddr;
    }

    function swap(
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address payable _refundAddress,
        uint256 _amountLD,
        uint256 _minAmountLD,
        lzTxObj memory _lzTxParams,
        bytes calldata _to,
        bytes calldata _payload
    ) external payable;

    function swapETH(
        uint16 _dstChainId,
        address payable _refundAddress,
        bytes calldata _toAddress,
        uint256 _amountLD,
        uint256 _minAmountLD
    ) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

/// @dev based on thorchain router https://gitlab.com/thorchain/ethereum/eth-router/-/blob/29b59c2d6c6fc7a65d6bbc0f80d90694ac4122f8/contracts/THORChain_Aggregator.sol#L12
interface IThorchainRouter {
    /// @param vault The vault address of Thorchain. This cannot be hardcoded because Thorchain rotates vaults.
    /// @param asset The token contract address (if token is native, should be 0x0000000000000000000000000000000000000000)
    /// @param amount The amount of token to be swapped. It should be positive and if token is native, msg.value should be bigger than amount.
    /// @param memo The transaction memo used by Thorchain which contains the thorchain swap data. More info: https://dev.thorchain.org/thorchain-dev/memos
    /// @param expiration The expiration block number. If the tx is included after this block, it will be reverted.
    function depositWithExpiry(
        address payable vault,
        address asset,
        uint amount,
        string calldata memo,
        uint expiration
    ) external payable;
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.13;

interface IWETH {
    function deposit() external payable;

    function withdraw(uint256) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

/// @title An interface to interchain message types
/// @author Uchiha Sasuke
interface Interchain {
    enum ActionType { NO_ACTION, UNI_V2, UNI_V3, CALL }
    enum CallSubActionType { WRAP, UNWRAP, NO_ACTION }

    struct RangoInterChainMessage {
        uint64 dstChainId;
        address bridgeRealOutput;
        address toToken;
        address originalSender;
        address recipient;
        ActionType actionType;
        bytes action;
        CallSubActionType postAction;

        // Extra message
        bytes dAppMessage;
        address dAppSourceContract;
        address dAppDestContract;
    }

    struct UniswapV2Action {
        address dexAddress;
        uint amountOutMin;
        address[] path;
        uint deadline;
    }

    struct UniswapV3ActionExactInputSingleParams {
        address dexAddress;
        address tokenIn;
        address tokenOut;
        uint24 fee;
        uint256 deadline;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice The requested call data which is computed off-chain and passed to the contract
    /// @param target The dex contract address that should be called
    /// @param callData The required data field that should be give to the dex contract to perform swap
    struct CallAction { 
        address tokenIn;
        address spender; 
        CallSubActionType preAction;
        address payable target;
        bytes callData;
    }
}