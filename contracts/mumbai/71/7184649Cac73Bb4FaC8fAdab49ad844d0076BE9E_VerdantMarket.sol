// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
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
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "../IERC721ReceiverUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721HolderUpgradeable is Initializable, IERC721ReceiverUpgradeable {
    function __ERC721Holder_init() internal onlyInitializing {
    }

    function __ERC721Holder_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../StringsUpgradeable.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSAUpgradeable {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV // Deprecated in v4.8
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", StringsUpgradeable.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165Upgradeable {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUpgradeable {
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/MathUpgradeable.sol";

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = MathUpgradeable.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, MathUpgradeable.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
 * ====
 */
library EnumerableSetUpgradeable {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract Manager is Initializable, OwnableUpgradeable, PausableUpgradeable {
    using StringsUpgradeable for uint256;
    // FEE
    uint256 public xUser;
    uint256 public xBuyer;
    uint256 public xCreator;
    uint256 public zProfitToCreator;
    mapping(address => bool) public paymentMethod;
    mapping(address => bool) public isFarmingNFTs;
    mapping(address => bool) public isOperator;
    mapping(address => bool) public isRetailer;

    mapping(string => uint256) private commissionSellers;
    mapping(string => bool) public isCommissionSellerSets;

    mapping(string => uint256) private commissionBuyers;
    mapping(string => bool) public isCommissionBuyerSets;

    event SetCommissions(
        uint256[] _categoryIds,
        uint256[] _branchIds,
        uint256[] _collectionIds,
        address[] _minters,
        uint256[] _sellerCommissions,
        uint256[] _buyerCommissions
    );

    event SetSystemFee(
        uint256 xUser,
        uint256 xBuyer,
        uint256 yRefRate,
        uint256 zProfitToCreator
    );

    modifier onlyOperator() {
        require(isOperator[msg.sender], "Only-operator");
        _;
    }

    function __Manager_init() public onlyInitializing {
        OwnableUpgradeable.__Ownable_init();
        PausableUpgradeable.__Pausable_init();
        isOperator[msg.sender] = true;
        xUser = 250; // 2.5%
        xBuyer = 250; // 2.5%
        xCreator = 1500;
        zProfitToCreator = 5000; // 10% profit
    }

    function whiteListOperator(
        address _operator,
        bool _whitelist
    ) external onlyOwner {
        isOperator[_operator] = _whitelist;
    }

    function whiteListRetailer(
        address _retailer,
        bool _whitelist
    ) external onlyOwner {
        isRetailer[_retailer] = _whitelist;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unPause() public onlyOwner {
        _unpause();
    }

    function setSystemFee(
        uint256 _xUser,
        uint256 _xBuyer,
        uint256 _yRefRate,
        uint256 _zProfitToCreator
    ) external onlyOwner {
        _setSystemFee(_xUser, _xBuyer, _yRefRate, _zProfitToCreator);
        emit SetSystemFee(_xUser, _xBuyer, _yRefRate, _zProfitToCreator);
    }

    function _setSystemFee(
        uint256 _xUser,
        uint256 _xBuyer,
        uint256 _xCreator,
        uint256 _zProfitToCreator
    ) internal {
        xUser = _xUser;
        xBuyer = _xBuyer;
        xCreator = _xCreator;
        zProfitToCreator = _zProfitToCreator;
    }

    function setPaymentMethod(
        address _token,
        bool _status
    ) public onlyOwner returns (bool) {
        paymentMethod[_token] = _status;
        if (_token != address(0)) {
            IERC20Upgradeable(_token).approve(msg.sender, type(uint256).max);
            IERC20Upgradeable(_token).approve(address(this), type(uint256).max);
        }
        return true;
    }

    function setCommissions(
        uint256[] memory _categoryIds,
        uint256[] memory _branchIds,
        uint256[] memory _collectionIds,
        address[] memory _minters,
        uint256[] memory _sellerCommissions,
        uint256[] memory _buyerCommissions
    ) public onlyOwner {
        require(
            _categoryIds.length > 0 &&
                _categoryIds.length == _sellerCommissions.length &&
                _categoryIds.length == _buyerCommissions.length &&
                _categoryIds.length == _branchIds.length &&
                _categoryIds.length == _collectionIds.length &&
                _categoryIds.length == _minters.length,
            "Invalid-input"
        );
        for (uint256 i = 0; i < _categoryIds.length; i++) {
            _setCommission(
                _categoryIds[i],
                _branchIds[i],
                _collectionIds[i],
                _minters[i],
                _sellerCommissions[i],
                _buyerCommissions[i]
            );
        }

        emit SetCommissions(
            _categoryIds,
            _branchIds,
            _collectionIds,
            _minters,
            _sellerCommissions,
            _buyerCommissions
        );
    }

    function _setCommission(
        uint256 _categoryId,
        uint256 _branchId,
        uint256 _collecttionId,
        address _minter,
        uint256 _sellerCommission,
        uint256 _buyerCommission
    ) private onlyOwner {
        require(_categoryId > 0, "Invalid-categoryId");
        if (_minter != address(0)) {
            require(_collecttionId > 0, "Invalid-collecttionId");
        }

        if (_collecttionId > 0) {
            require(_branchId > 0, "Invalid-branchId");
        }

        string memory _config = mapConfigId(
            _categoryId,
            _branchId,
            _collecttionId,
            _minter
        );

        commissionSellers[_config] = _sellerCommission;
        isCommissionSellerSets[_config] = true;

        commissionBuyers[_config] = _buyerCommission;
        isCommissionBuyerSets[_config] = true;
    }

    function getCommissionSeller(
        uint256 _categoryId,
        uint256 _branchId,
        uint256 _collecttionId,
        address _minter
    ) public view returns (uint256) {
        string memory _config = mapConfigId(
            _categoryId,
            _branchId,
            _collecttionId,
            _minter
        );

        if (isCommissionSellerSets[_config]) {
            return commissionSellers[_config];
        }

        _config = mapConfigId(
            _categoryId,
            _branchId,
            _collecttionId,
            address(0)
        );
        if (isCommissionSellerSets[_config]) {
            return commissionSellers[_config];
        }

        _config = mapConfigId(_categoryId, _branchId, 0, address(0));
        if (isCommissionSellerSets[_config]) {
            return commissionSellers[_config];
        }

        _config = mapConfigId(_categoryId, 0, 0, address(0));
        if (isCommissionSellerSets[_config]) {
            return commissionSellers[_config];
        }

        return xUser;
    }

    function getCommissionBuyer(
        uint256 _categoryId,
        uint256 _branchId,
        uint256 _collecttionId,
        address _minter
    ) public view returns (uint256) {
        string memory _config = mapConfigId(
            _categoryId,
            _branchId,
            _collecttionId,
            _minter
        );

        if (isCommissionBuyerSets[_config]) {
            return commissionBuyers[_config];
        }

        _config = mapConfigId(
            _categoryId,
            _branchId,
            _collecttionId,
            address(0)
        );
        if (isCommissionBuyerSets[_config]) {
            return commissionBuyers[_config];
        }

        _config = mapConfigId(_categoryId, _branchId, 0, address(0));
        if (isCommissionBuyerSets[_config]) {
            return commissionBuyers[_config];
        }

        _config = mapConfigId(_categoryId, 0, 0, address(0));
        if (isCommissionBuyerSets[_config]) {
            return commissionBuyers[_config];
        }

        return xBuyer;
    }

    function mapConfigId(
        uint256 _categoryId,
        uint256 _branchId,
        uint256 _collecttionId,
        address _minter
    ) public pure returns (string memory) {
        uint256 _minterId = uint256(uint160(_minter));
        string memory _config = string(
            abi.encodePacked(
                "Ca",
                _categoryId.toString(),
                "Br",
                _branchId.toString(),
                "Co",
                _collecttionId.toString(),
                "M",
                StringsUpgradeable.toString(_minterId)
            )
        );
        if (_branchId == 0) {
            return string(abi.encodePacked("Ca", _categoryId.toString()));
        }

        if (_collecttionId == 0) {
            return
                string(
                    abi.encodePacked(
                        "Ca",
                        _categoryId.toString(),
                        "Br",
                        _branchId.toString()
                    )
                );
        }

        if (_minterId == 0) {
            return
                string(
                    abi.encodePacked(
                        "Ca",
                        _categoryId.toString(),
                        "Br",
                        _branchId.toString(),
                        "Co",
                        _collecttionId.toString()
                    )
                );
        }
        return _config;
    }

    /**
     * @notice withdrawFunds
     */
    function withdrawFunds(
        address payable _beneficiary,
        address _tokenAddress
    ) external onlyOwner whenPaused {
        uint256 _withdrawAmount;
        if (_tokenAddress == address(0)) {
            _beneficiary.transfer(address(this).balance);
            _withdrawAmount = address(this).balance;
        } else {
            _withdrawAmount = IERC20Upgradeable(_tokenAddress).balanceOf(
                address(this)
            );
            IERC20Upgradeable(_tokenAddress).transfer(
                _beneficiary,
                _withdrawAmount
            );
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import {ECDSAUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./Manager.sol";

contract VerdantMarket is
    Initializable,
    Manager,
    ERC721HolderUpgradeable,
    ReentrancyGuardUpgradeable
{
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using AddressUpgradeable for address payable;
    using ECDSAUpgradeable for bytes32;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    address public nFTAddress;

    address public verifier;
    address public feeTo;
    uint256 public constant ZOOM_USDT = 10 ** 6;
    uint256 public constant ZOOM_FEE = 10 ** 4;
    uint256 public totalOrders;
    uint256 public totalBids;
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;
    bytes4 private constant _INTERFACE_ID_ERC1155 = 0xd9b67a26;

    struct Order {
        address owner;
        address paymentToken;
        uint256 tokenId;
        uint256 price; // price of 1 NFT in paymentToken
        uint256 commissionFromBuyer;
        uint256 commissionToSeller;
        uint256 expTime;
        bool isFloatingPrice;
        address aggregatorV3;
        bool isOnsale; // true: on sale, false: cancel
    }

    struct Bid {
        address bidder;
        address paymentToken;
        uint256 tokenId;
        uint256 bidPrice;
        uint256 commissionFromBuyer;
        uint256 taxAmount;
        uint256 expTime;
        bool status; // 1: available | 2: done | 3: reject
    }

    struct BuyerCommissionInput {
        uint256 orderId;
        address paymentToken;
        uint256 tokenId;
        uint256 amount;
        address minter;
    }

    struct TaxPromoCodeInfo {
        bool isPercent;
        uint256 tax;
        uint256 promoCodeNft;
        uint256 promoCodeServiceFee;
    }

    struct BuyerCommissionOutput {
        uint256 amountToBuyer;
        uint256 commissionFromBuyer;
        uint256 promocodeAmount;
        uint256 taxAmount;
    }

    mapping(uint256 => Order) public orders;
    mapping(bytes32 => uint256) private orderID;
    mapping(uint256 => Bid) public bids;
    mapping(address => mapping(uint256 => uint256)) public amountFirstSale;
    mapping(address => mapping(bytes32 => uint256)) public farmingAmount;
    mapping(bytes32 => bool) public isBid;
    mapping(bytes32 => uint256) private userBidOfToken;

    EnumerableSetUpgradeable.AddressSet private aggregatorV3s;

    event OrderCreated(
        uint256 indexed _orderId,
        uint256 indexed _tokenId,
        uint256 _price,
        address _paymentToken,
        uint256 expTime,
        bool isFloatingPrice,
        address aggregatorV3
    );
    event Buy(
        uint256 _itemId,
        address _paymentToken,
        uint256 _paymentAmount,
        uint256 _promocodeAmount,
        uint256 _taxAmount
    );
    event OrderCancelled(uint256 indexed _orderId);
    event OrderUpdated(uint256 indexed _orderId);
    event BidCreated(
        uint256 indexed _bidId,
        uint256 indexed _tokenId,
        uint256 _price,
        address _paymentToken,
        uint256 expTime
    );
    event AcceptBid(uint256 indexed _bidId);
    event BidUpdated(uint256 indexed _bidId);
    event BidCancelled(uint256 indexed _bidId);
    event VerifierSet(address indexed _verifier);
    event NFTAddressSet(address indexed _nFTAddress);

    /******* GOVERNANCE FUNCTIONS *******/

    function initialize(
        address verifier_,
        address nFTAddress_,
        address feeto_
    ) public initializer {
        Manager.__Manager_init();
        ERC721HolderUpgradeable.__ERC721Holder_init();
        ReentrancyGuardUpgradeable.__ReentrancyGuard_init();
        verifier = verifier_;
        nFTAddress = nFTAddress_;
        feeTo = feeto_;
    }

    /**
     * @dev Function to set new verifier
     * @param _verifier new verifier address to set
     * Emit VerifierSet event
     */
    function setVerifier(address _verifier) external onlyOwner {
        require(_verifier != address(0), "Invalid-address");
        require(_verifier != verifier, "Verifier-already-set");
        verifier = _verifier;
        emit VerifierSet(_verifier);
    }

    /**
     * @dev Function to set new NFT address
     * @param _nFTAddress new verifier address to set
     * Emit NFTAddressSet event
     */
    function setNFTAddress(address _nFTAddress) external onlyOwner {
        require(_nFTAddress != address(0), "Invalid-address");
        require(_nFTAddress != nFTAddress, "NFT-address-already-set");
        bool isERC721 = IERC721Upgradeable(_nFTAddress).supportsInterface(
            _INTERFACE_ID_ERC721
        );
        require(isERC721, "Token-is-not-ERC721");
        nFTAddress = _nFTAddress;
        emit NFTAddressSet(_nFTAddress);
    }

    /**
     * @dev Function to add floating payment method
     * @param _aggregatorV3 address of aggregatorV3 of payment method
     */
    function addFloatingPaymentMethod(
        address _aggregatorV3
    ) external onlyOwner {
        require(_aggregatorV3 != address(0), "Invalid-address");
        require(
            !aggregatorV3s.contains(_aggregatorV3),
            "Payment-method-already-added"
        );
        aggregatorV3s.add(_aggregatorV3);
    }

    /**
     * @dev Function to remove floating payment method
     * @param _aggregatorV3 address of aggregatorV3 of payment method
     */
    function removeFloatingPaymentMethod(
        address _aggregatorV3
    ) external onlyOwner {
        require(_aggregatorV3 != address(0), "Invalid-address");
        require(
            aggregatorV3s.contains(_aggregatorV3),
            "Payment-method-not-exist"
        );
        aggregatorV3s.remove(_aggregatorV3);
    }

    /******* VIEW FUNCTIONS *******/

    function getAllFloatingPayment() public view returns (address[] memory) {
        return aggregatorV3s.values();
    }

    /******* INTERNAL FUNCTIONS *******/

    function _paid(address _token, address _to, uint256 _amount) private {
        require(_to != address(0), "Invalid-address");
        if (_token == address(0)) {
            payable(_to).sendValue(_amount);
        } else {
            IERC20Upgradeable(_token).safeTransfer(_to, _amount);
        }
    }

    /**
     * @dev Matching order mechanism
     * @param _buyer is address of buyer
     * @param _orderId is id of order
     * @param _paymentToken is payment method (USDT, BNB, ...)
     * @param _price is matched price
     */
    function _match(
        address _buyer,
        address _paymentToken,
        uint256 _orderId,
        uint256 _price,
        uint256 _commissionFromBuyer,
        uint256 _taxAmount
    ) private returns (bool) {
        Order memory order = orders[_orderId];
        (
            uint256 _categoryId,
            uint256 _branchId,
            uint256 _collectionId
        ) = callGetCategoryToken(order.tokenId);
        uint256 _commission = getCommissionSeller(
            _categoryId,
            _branchId,
            _collectionId,
            _buyer
        );
        order.commissionToSeller = (_price * _commission) / ZOOM_FEE;
        uint256 amountToSeller = _price - order.commissionToSeller;
        // send payment to seller
        _paid(_paymentToken, order.owner, amountToSeller);
        // send nft to buyer
        IERC721Upgradeable(nFTAddress).safeTransferFrom(
            address(this),
            _buyer,
            order.tokenId
        );
        // send payment to feeTo
        _paid(
            _paymentToken,
            feeTo,
            _commissionFromBuyer + order.commissionToSeller + _taxAmount
        );
        order.isOnsale = false;
        order.commissionFromBuyer = _commissionFromBuyer;
        orders[_orderId] = order;
        return true;
    }

    function callGetCategoryToken(
        uint256 _tokenId
    ) private returns (uint256, uint256, uint256) {
        (bool success, bytes memory data) = nFTAddress.call(
            abi.encodeWithSignature("getConfigToken(uint256)", _tokenId)
        );

        (
            uint256 _categoryId,
            uint256 _branchId,
            uint256 _collectionId
        ) = success ? abi.decode(data, (uint256, uint256, uint256)) : (0, 0, 0);
        return (_categoryId, _branchId, _collectionId);
    }

    function calBuyerCommission(
        BuyerCommissionInput memory _buyerCommission,
        uint256 _taxPercent
    ) private returns (BuyerCommissionOutput memory) {
        (
            uint256 _categoryId,
            uint256 _branchId,
            uint256 _collectionId
        ) = callGetCategoryToken(_buyerCommission.tokenId);
        uint256 _commission = getCommissionBuyer(
            _categoryId,
            _branchId,
            _collectionId,
            _buyerCommission.minter
        );

        BuyerCommissionOutput memory _buyerCommissionOutput;

        _buyerCommissionOutput.commissionFromBuyer =
            (_buyerCommission.amount * _commission) /
            ZOOM_FEE;
        _buyerCommissionOutput.amountToBuyer =
            _buyerCommission.amount +
            _buyerCommissionOutput.commissionFromBuyer;

        if (_taxPercent > 0) {
            _buyerCommissionOutput.taxAmount =
                (_buyerCommissionOutput.commissionFromBuyer * _taxPercent) /
                ZOOM_FEE;
            _buyerCommissionOutput.amountToBuyer += _buyerCommissionOutput
                .taxAmount;
        }

        return _buyerCommissionOutput;
    }

    function calBuyerCommissionHasSign(
        BuyerCommissionInput memory _buyerCommission,
        TaxPromoCodeInfo memory _taxPromoCodeInfo,
        bytes memory _signature
    ) private returns (BuyerCommissionOutput memory) {
        require(_taxPromoCodeInfo.tax <= ZOOM_FEE, "Invalid tax");
        if (_taxPromoCodeInfo.isPercent) {
            require(
                _taxPromoCodeInfo.promoCodeNft <= ZOOM_FEE,
                "Invalid promoCodeNft"
            );
            require(
                _taxPromoCodeInfo.promoCodeServiceFee <= ZOOM_FEE,
                "Invalid promoCodeServiceFee"
            );
        }

        (
            uint256 _categoryId,
            uint256 _branchId,
            uint256 _collectionId
        ) = callGetCategoryToken(_buyerCommission.tokenId);
        uint256 _commission = getCommissionBuyer(
            _categoryId,
            _branchId,
            _collectionId,
            _buyerCommission.minter
        );

        BuyerCommissionOutput memory _buyerCommissionOutput;

        require(
            verifyMessage(_buyerCommission, _signature),
            "Invalid signature"
        );
        if (_taxPromoCodeInfo.isPercent) {
            uint256 _commissionAmount = (_buyerCommission.amount *
                _commission) / ZOOM_FEE;
            uint256 _buyerAmount = (_buyerCommission.amount *
                (ZOOM_FEE - _taxPromoCodeInfo.promoCodeNft)) / ZOOM_FEE;
            _buyerCommissionOutput.commissionFromBuyer =
                (((_commissionAmount *
                    (ZOOM_FEE - _taxPromoCodeInfo.promoCodeNft)) / ZOOM_FEE) *
                    (ZOOM_FEE - _taxPromoCodeInfo.promoCodeServiceFee)) /
                ZOOM_FEE;

            _buyerCommissionOutput.amountToBuyer =
                _buyerAmount +
                _buyerCommissionOutput.commissionFromBuyer;
            _buyerCommissionOutput.promocodeAmount =
                _commissionAmount +
                _buyerCommission.amount -
                _buyerCommissionOutput.amountToBuyer;
        } else {
            uint256 _buyerAmount = _buyerCommission.amount >
                _taxPromoCodeInfo.promoCodeNft
                ? _buyerCommission.amount - _taxPromoCodeInfo.promoCodeNft
                : 0;
            uint256 _commissionAmount = (_buyerAmount * _commission) / ZOOM_FEE;
            _buyerCommissionOutput.commissionFromBuyer = _commissionAmount >
                _taxPromoCodeInfo.promoCodeServiceFee
                ? _commissionAmount - _taxPromoCodeInfo.promoCodeServiceFee
                : 0;

            _buyerCommissionOutput.amountToBuyer =
                _buyerAmount +
                _buyerCommissionOutput.commissionFromBuyer;
            _buyerCommissionOutput.promocodeAmount =
                _commissionAmount +
                _buyerCommission.amount -
                _buyerCommissionOutput.amountToBuyer;
        }

        if (_taxPromoCodeInfo.tax > 0) {
            _buyerCommissionOutput.taxAmount =
                (_buyerCommissionOutput.commissionFromBuyer *
                    _taxPromoCodeInfo.tax) /
                ZOOM_FEE;
            _buyerCommissionOutput.amountToBuyer += _buyerCommissionOutput
                .taxAmount;
        }

        return _buyerCommissionOutput;
    }

    /******* MUTATIVE FUNCTIONS *******/

    /**
     * @dev Allow user create order on market
     * @param _tokenId is id of NFTs
     * @param _price is price per item in payment method (example 50 USDT)
     * @param _paymentToken is payment method (USDT, BNB, ...)
     */
    function createOrder(
        address _paymentToken, // payment method
        uint256 _tokenId,
        uint256 _price, // price of 1 nft
        uint256 _expTime,
        address _aggregatorV3,
        bool _isFloatingPrice
    ) external whenNotPaused returns (uint256 _orderId) {
        require(
            paymentMethod[_paymentToken] &&
                (!_isFloatingPrice ||
                    (_isFloatingPrice &&
                        aggregatorV3s.contains(_aggregatorV3))),
            "Payment-method-does-not-support"
        );

        require(
            _expTime > block.timestamp || _expTime == 0,
            "Invalid-expired-time"
        );

        IERC721Upgradeable(nFTAddress).safeTransferFrom(
            msg.sender,
            address(this),
            _tokenId
        );

        Order memory newOrder;
        newOrder.isOnsale = true;
        newOrder.owner = msg.sender;
        newOrder.price = _price;
        newOrder.tokenId = _tokenId;
        newOrder.paymentToken = _paymentToken;
        newOrder.expTime = _expTime;
        newOrder.isFloatingPrice = _isFloatingPrice;
        newOrder.aggregatorV3 = _aggregatorV3;

        orders[totalOrders] = newOrder;
        _orderId = totalOrders;
        totalOrders++;
        bytes32 _id = keccak256(
            abi.encodePacked(nFTAddress, _tokenId, msg.sender)
        );
        orderID[_id] = _orderId;

        emit OrderCreated(
            _orderId,
            _tokenId,
            _price,
            _paymentToken,
            _expTime,
            _isFloatingPrice,
            _aggregatorV3
        );
        return _orderId;
    }

    function buy(
        uint256 _orderId,
        address _paymentToken,
        TaxPromoCodeInfo memory _taxPromoCodeInfo,
        bytes calldata _signature
    ) external payable whenNotPaused returns (bool) {
        Order memory order = orders[_orderId];
        require(order.owner != address(0), "Invalid-order-id");
        require(
            _paymentToken == order.paymentToken,
            "Payment-method-does-not-support"
        );
        require(order.isOnsale, "Not-available-to-buy");
        require(
            order.expTime > block.timestamp || order.expTime == 0,
            "Order-expired"
        );

        BuyerCommissionOutput
            memory _buyerCommissionOutput = calBuyerCommissionHasSign(
                BuyerCommissionInput(
                    _orderId,
                    _paymentToken,
                    order.tokenId,
                    order.price,
                    msg.sender
                ),
                _taxPromoCodeInfo,
                _signature
            );

        bytes32 _id = keccak256(
            abi.encodePacked(nFTAddress, order.tokenId, msg.sender)
        );

        bool isUserBid = isBid[_id];
        if (isUserBid) {
            uint256 bidId = userBidOfToken[_id];
            Bid memory bid = bids[bidId];
            if (bid.paymentToken == _paymentToken) {
                uint256 buyerPaidAmount = bid.bidPrice +
                    bid.taxAmount +
                    bid.commissionFromBuyer;
                if (buyerPaidAmount > _buyerCommissionOutput.amountToBuyer) {
                    _paid(
                        _paymentToken,
                        msg.sender,
                        buyerPaidAmount - _buyerCommissionOutput.amountToBuyer
                    );
                } else {
                    if (_paymentToken == address(0)) {
                        require(
                            msg.value >=
                                _buyerCommissionOutput.amountToBuyer -
                                    buyerPaidAmount,
                            "Not-enough-to-buy"
                        );
                    } else {
                        IERC20Upgradeable(_paymentToken).safeTransferFrom(
                            msg.sender,
                            address(this),
                            _buyerCommissionOutput.amountToBuyer -
                                buyerPaidAmount
                        );
                    }
                }
                bid.status = false;
                bids[bidId] = bid;
                isBid[_id] = false;
                emit BidCancelled(bidId);
            } else {
                isUserBid = false;
            }
        }

        if (!isUserBid) {
            if (_paymentToken == address(0)) {
                require(
                    msg.value >= _buyerCommissionOutput.amountToBuyer,
                    "Not-enough-to-buy"
                );
            } else {
                IERC20Upgradeable(_paymentToken).safeTransferFrom(
                    msg.sender,
                    address(this),
                    _buyerCommissionOutput.amountToBuyer
                );
            }
        }

        emit Buy(
            _orderId,
            _paymentToken,
            _buyerCommissionOutput.amountToBuyer,
            _buyerCommissionOutput.promocodeAmount,
            _buyerCommissionOutput.taxAmount
        );
        uint256 _amountToSeller = _buyerCommissionOutput.amountToBuyer <
            order.price
            ? _buyerCommissionOutput.amountToBuyer
            : order.price;
        return
            _match(
                msg.sender,
                _paymentToken,
                _orderId,
                _amountToSeller,
                _buyerCommissionOutput.commissionFromBuyer,
                _buyerCommissionOutput.taxAmount
            );
    }

    function createBid(
        address _paymentToken, // payment method
        uint256 _tokenId,
        uint256 _price, // price of 1 nft
        uint256 _taxPercent,
        uint256 _expTime,
        bytes calldata signature
    ) external payable whenNotPaused returns (uint256 _bidId) {
        bytes32 _id = keccak256(
            abi.encodePacked(nFTAddress, _tokenId, msg.sender)
        );
        require(!isBid[_id], "User-has-bid");
        require(
            paymentMethod[_paymentToken],
            "Payment-method-does-not-support"
        );
        require(
            _expTime > block.timestamp || _expTime == 0,
            "Invalid-expired-time"
        );

        require(
            verifyBidMessage(
                msg.sender,
                _paymentToken,
                _tokenId,
                _price,
                _taxPercent,
                signature
            ),
            "Invalid signature"
        );

        Bid memory newBid;
        newBid.bidder = msg.sender;
        newBid.bidPrice = _price;
        newBid.tokenId = _tokenId;

        BuyerCommissionOutput
            memory _buyerCommissionOutput = calBuyerCommission(
                BuyerCommissionInput(
                    0,
                    _paymentToken,
                    _tokenId,
                    _price,
                    msg.sender
                ),
                _taxPercent
            );

        if (msg.value > 0) {
            require(
                msg.value >= _buyerCommissionOutput.amountToBuyer,
                "Invalid-amount"
            );
            newBid.paymentToken = address(0);
        } else {
            newBid.paymentToken = _paymentToken;
            IERC20Upgradeable(newBid.paymentToken).safeTransferFrom(
                msg.sender,
                address(this),
                _buyerCommissionOutput.amountToBuyer
            );
        }

        newBid.taxAmount = _buyerCommissionOutput.taxAmount;
        newBid.commissionFromBuyer = _buyerCommissionOutput.commissionFromBuyer;
        newBid.status = true;
        newBid.expTime = _expTime;
        bids[totalBids] = newBid;
        _bidId = totalBids;
        totalBids++;

        isBid[_id] = true;
        userBidOfToken[_id] = _bidId;
        emit BidCreated(
            _bidId,
            _tokenId,
            _buyerCommissionOutput.amountToBuyer,
            newBid.paymentToken,
            _expTime
        );
        return _bidId;
    }

    function acceptBid(uint256 _bidId) external whenNotPaused returns (bool) {
        Bid memory bid = bids[_bidId];
        require(bid.status, "Invalid-quantity-or-bid-cancelled");
        require(
            bid.expTime > block.timestamp || bid.expTime == 0,
            "Bid-expired"
        );

        bytes32 _id = keccak256(
            abi.encodePacked(nFTAddress, bid.tokenId, msg.sender)
        );
        uint256 _orderId = orderID[_id];
        Order memory order = orders[_orderId];
        require(
            order.owner == msg.sender && order.isOnsale,
            "Oops!Wrong-order-owner-or-cancelled"
        );
        require(
            order.expTime > block.timestamp || order.expTime == 0,
            "Order-expired"
        );

        emit AcceptBid(_bidId);
        bid.status = false;
        bids[_bidId] = bid;

        isBid[_id] = false;

        return
            _match(
                bid.bidder,
                bid.paymentToken,
                _orderId,
                bid.bidPrice,
                bid.commissionFromBuyer,
                bid.taxAmount
            );
    }

    function cancelOrder(uint256 _orderId) external whenNotPaused {
        Order memory order = orders[_orderId];
        require(
            (order.owner == msg.sender || isOperator[msg.sender]) &&
                order.isOnsale,
            "Oops!Wrong-order-owner-or-cancelled"
        );
        IERC721Upgradeable(nFTAddress).safeTransferFrom(
            address(this),
            order.owner,
            order.tokenId
        );

        order.isOnsale = false;
        orders[_orderId] = order;
        emit OrderCancelled(_orderId);
    }

    function cancelBid(uint256 _bidId) external whenNotPaused nonReentrant {
        Bid memory bid = bids[_bidId];
        require(
            bid.bidder == msg.sender || isOperator[msg.sender],
            "Only bidder or operator"
        );
        require(bid.status, "Bid-cancelled-or-accepted");
        bytes32 _id = keccak256(
            abi.encodePacked(nFTAddress, bid.tokenId, bid.bidder)
        );
        uint256 payBackAmount = bid.bidPrice +
            bid.commissionFromBuyer +
            bid.taxAmount;
        if (payBackAmount > 0) {
            if (bid.paymentToken != address(0)) {
                IERC20Upgradeable(bid.paymentToken).safeTransfer(
                    bid.bidder,
                    payBackAmount
                );
            } else {
                payable(bid.bidder).sendValue(payBackAmount);
            }
        }
        bid.status = false;
        bids[_bidId] = bid;

        isBid[_id] = false;

        emit BidCancelled(_bidId);
    }

    function updateOrder(
        uint256 _orderId,
        uint256 _price,
        uint256 _expTime
    ) external whenNotPaused {
        Order memory order = orders[_orderId];
        require(
            order.owner == msg.sender && order.isOnsale,
            "Oops!Wrong-order-owner-or-cancelled"
        );
        require(
            order.expTime > block.timestamp || order.expTime == 0,
            "Order-expired"
        );
        require(
            order.price != _price || order.expTime != _expTime,
            "Invalid-update-info"
        );

        if (order.expTime != _expTime) {
            require(
                _expTime > block.timestamp || _expTime == 0,
                "Invalid-expired-time"
            );
            order.expTime = _expTime;
        }

        if (order.price != _price) {
            order.price = _price;
        }

        orders[_orderId] = order;
        emit OrderUpdated(_orderId);
    }

    function updateBid(
        uint256 _bidId,
        uint256 _bidPrice,
        uint256 _taxPercent,
        uint256 _expTime,
        bytes calldata signature
    ) external payable whenNotPaused nonReentrant {
        Bid memory bid = bids[_bidId];
        require(bid.bidder == msg.sender, "Invalid-bidder");
        require(bid.status, "Bid-cancelled-or-accepted");
        require(
            bid.expTime > block.timestamp || bid.expTime == 0,
            "Bid-expired"
        );
        require(
            bid.bidPrice != _bidPrice || bid.expTime != _expTime,
            "Invalid-update-info"
        );

        if (bid.expTime != _expTime) {
            require(
                _expTime > block.timestamp || _expTime == 0,
                "Invalid-expired-time"
            );
            bid.expTime = _expTime;
        }

        if (bid.bidPrice != _bidPrice) {
            require(
                verifyBidMessage(
                    msg.sender,
                    bid.paymentToken,
                    bid.tokenId,
                    _bidPrice,
                    _taxPercent,
                    signature
                ),
                "Invalid signature"
            );

            BuyerCommissionOutput
                memory _buyerCommissionOutput = calBuyerCommission(
                    BuyerCommissionInput(
                        0,
                        bid.paymentToken,
                        bid.tokenId,
                        _bidPrice,
                        msg.sender
                    ),
                    _taxPercent
                );
            uint256 _amountToBuyerOld = bid.bidPrice +
                bid.commissionFromBuyer +
                bid.taxAmount;

            bool isExcess = _amountToBuyerOld >
                _buyerCommissionOutput.amountToBuyer;
            uint256 amount = isExcess
                ? _amountToBuyerOld - _buyerCommissionOutput.amountToBuyer
                : _buyerCommissionOutput.amountToBuyer - _amountToBuyerOld;

            if (bid.paymentToken != address(0)) {
                if (isExcess) {
                    IERC20Upgradeable(bid.paymentToken).safeTransfer(
                        bid.bidder,
                        amount
                    );
                } else {
                    IERC20Upgradeable(bid.paymentToken).safeTransferFrom(
                        bid.bidder,
                        address(this),
                        amount
                    );
                }
            } else {
                if (isExcess) {
                    payable(msg.sender).sendValue(amount);
                } else {
                    require(msg.value >= amount, "Invalid-amount");
                }
            }

            bid.bidPrice = _bidPrice;
            bid.commissionFromBuyer = _buyerCommissionOutput
                .commissionFromBuyer;
            bid.taxAmount = _buyerCommissionOutput.taxAmount;
        }

        bids[_bidId] = bid;
        emit BidUpdated(_bidId);
    }

    /******* SIGNATURE FUNCTIONS *******/

    function verifyMessage(
        BuyerCommissionInput memory _buyerCommission,
        bytes memory signature
    ) public view returns (bool) {
        if (signature.length == 0) return false;
        bytes32 dataHash = encodeData(
            _buyerCommission.orderId,
            nFTAddress,
            _buyerCommission.paymentToken,
            _buyerCommission.tokenId
        );
        bytes32 signHash = ECDSAUpgradeable.toEthSignedMessageHash(dataHash);
        address recovered = ECDSAUpgradeable.recover(signHash, signature);
        return recovered == verifier;
    }

    function encodeData(
        uint256 _orderId,
        address _token,
        address _paymentToken,
        uint256 _tokenId
    ) public view returns (bytes32) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return
            keccak256(
                abi.encode(id, _orderId, _token, _paymentToken, _tokenId)
            );
    }

    function verifyBidMessage(
        address _sender,
        address _paymentToken,
        uint256 _tokenId,
        uint256 _price,
        uint256 _taxPercent,
        bytes memory signature
    ) public view returns (bool) {
        if (signature.length == 0) return false;
        bytes32 dataHash = encodeBidData(
            _sender,
            nFTAddress,
            _paymentToken,
            _tokenId,
            _price,
            _taxPercent
        );
        bytes32 signHash = ECDSAUpgradeable.toEthSignedMessageHash(dataHash);
        address recovered = ECDSAUpgradeable.recover(signHash, signature);
        return recovered == verifier;
    }

    function encodeBidData(
        address _sender,
        address _token,
        address _paymentToken,
        uint256 _tokenId,
        uint256 _price,
        uint256 _taxPercent
    ) public view returns (bytes32) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return
            keccak256(
                abi.encode(
                    id,
                    _sender,
                    _token,
                    _paymentToken,
                    _tokenId,
                    _price,
                    _taxPercent
                )
            );
    }

    function setApproveForAll(
        address _token,
        address _spender
    ) external onlyOwner {
        IERC721Upgradeable(_token).setApprovalForAll(_spender, true);
    }
}