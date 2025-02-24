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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

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
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
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
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

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
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
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
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

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
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {INewDefinaCard} from "./WorldCupPoolInterface.sol";

contract WorldCupPool is
    Initializable,
    OwnableUpgradeable,
    ERC721HolderUpgradeable
{
    using AddressUpgradeable for address;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    bool public claimableActive;

    INewDefinaCard public definaCard;

    //prize pool currency address
    address public prizePoolTokenAddress;

    //credits payment currency
    address public creditPaymentCurrency;

    //Each Hero's owner
    mapping(uint256 => address) public nftOwnedBy;


    // Bet for group stage

    // Total number of Games
    uint256 public constant totalMatches = 64;

    // Initial credits for each address
    uint256 public constant initCredit = 500;

    // consume 100 credits for each bet
    uint256 public constant consumeCreditEachBet = 100;

    // the cost of buying credits
    uint256 public constant creditCost = 10**18; // 1 credit = 1 fina

    // All group match and final match betting addresses
    address[] public allMatchBettingAddresses;

    // Top 3 addresses
    address[3] public leaderboardUsers;

    // Is in leaderboard
    mapping(address => bool) public isInLeaderboard;

    // Total credit - top 3 addresses credit
    uint256 public totalWinCredits;

    // group match prize pool
    uint256 public prizePool;

    struct MatchInfo{
        uint256 countryHomeId; // countryHome
        uint256 countryAwayId; // countryAway
        uint256 betEndTime; // Bet end time
        uint256 result; // result (0,1,2,3)
    }
    mapping(uint256 => MatchInfo) public allMatches;

    struct MatchCountryInfo{
        string countryName;
        uint256[] heroId;
        uint256[] heroRarity;
    }
    mapping(uint256 => MatchCountryInfo) public allMatchCountries;

    struct UserBetInfo{
        uint256 credits; // general credits
        uint256 winCredits; // reward credits
        uint256[] tokenIdList;
        uint256[] tokenIdListFinal;
        mapping(uint256 => uint256[4]) bets;
        mapping(uint256 => uint256) betsClaimed;
        bool activated;
    }
    mapping(address => UserBetInfo) public userMatchBets; // user => BetInfo
    mapping(uint256 => uint256) public tokenClaimedCredits;


    //Each Hero reward ratio based on FIFA ranking
    mapping(uint256 => uint256) public heroRewardRatio; // heroId => rewardRatio

    //Each Hero reward ratio based on it's rarity (SS-X)
    mapping(uint256 => uint256) public heroRarityRewardRatio;

    //Ending time of final betting
    uint256 public finalRankingBetEndTime;

    //Each hero id represented country id
    mapping(uint256 => uint256) public finalMatchHeroToCountry; // heroId => countryId

    constructor() {}

    function initialize() external virtual initializer {
        __WorldCupPool_init();
    }

    function __WorldCupPool_init() internal {
        __Ownable_init();
        finalRankingBetEndTime = 1667833200;
    }

    modifier whenClaimableActive() {
        require(claimableActive, "Claimable state is not active");
        _;
    }

    modifier onlyEOA() {
        require(_msgSender() == tx.origin, "WorldCupPool: not eoa");
        _;
    }

    function setFinalMatchHeroToCountry(uint256[] calldata _heroId, uint256[] calldata _countryId) external onlyOwner {
        for (uint256 i = 0; i < _heroId.length; ++i) {
            finalMatchHeroToCountry[_heroId[i]] = _countryId[i];
        }
    }

//    function setFinalMatchCountryInfo(uint256[] calldata _countryId, string[] calldata _representCountryName) external onlyOwner {
//        // 2 countries will be repeated
//        for (uint256 i = 0; i < _countryId.length; ++i) {
//            finalMatchCountries[_countryId[i]] = _representCountryName[i];
//        }
//    }

    // this function is to set ranking results for top 16 teams
    function setRewardRatio(
        uint256[] calldata _worldCupRankingByHeroId,
        uint256[] calldata _rewardRatioTier,
        uint256[] calldata _heroRarityRewardRatio
    ) external onlyOwner {
        // set this to true allows user to claim their reward
        // and they can no longer stake any nft
        for(uint256 i = 0; i < _worldCupRankingByHeroId.length; ++i) {
            uint256 heroId = _worldCupRankingByHeroId[i];
            uint256 rewardRatio = _rewardRatioTier[i];
            heroRewardRatio[heroId] = rewardRatio;
        }
        // set hero rarity ratio
        for(uint256 i = 0; i < _heroRarityRewardRatio.length; ++i){
            heroRarityRewardRatio[i+5]=_heroRarityRewardRatio[i];
        }
    }

    function betFinalMatch(uint256[] calldata _tokenIds) external onlyEOA {
        require(block.timestamp < finalRankingBetEndTime , "World cup final ranking betting has ended");

        UserBetInfo storage userBet = userMatchBets[_msgSender()];
        if(!userBet.activated){
            userBet.credits = initCredit;
            userBet.activated = true;
            allMatchBettingAddresses.push(_msgSender());
        }
        uint256 consumeCredits = consumeCreditEachBet * _tokenIds.length;
        require(
            userBet.credits + userBet.winCredits >= consumeCredits,
            "Insufficient user credits"
        );

        for (uint256 i = 0; i < _tokenIds.length; ++i) {
            uint256 heroId = definaCard.heroIdMap(_tokenIds[i]);
            uint256 rarity = definaCard.rarityMap(_tokenIds[i]);
            require(
                (finalMatchHeroToCountry[heroId]!=0)&&(rarity>=5),
                "This hero cannot be used for final match bet"
            );
            definaCard.safeTransferFrom(_msgSender(), address(this), _tokenIds[i]);
            nftOwnedBy[_tokenIds[i]] = _msgSender();
            userBet.tokenIdListFinal.push(_tokenIds[i]);
        }

        // deduct credits (100 per bet)
        if(userBet.credits < consumeCredits){
            totalWinCredits -= (consumeCredits - userBet.credits);
            userBet.winCredits -= (consumeCredits - userBet.credits);
            userBet.credits = 0;
        }else{
            userBet.credits -= consumeCredits;
        }
    }

    function setInitContract(
        address definaCardAddress,
        address _creditPaymentCurrency,
        address prizePoolTokenAddress_
    ) external onlyOwner {
        definaCard = INewDefinaCard(definaCardAddress);
        creditPaymentCurrency = _creditPaymentCurrency;
        prizePoolTokenAddress = prizePoolTokenAddress_;
    }

    function setMatchInfo(
        uint256[] calldata _matchId,
        uint256[] calldata _countryHomeId,
        uint256[] calldata _countryAwayId,
        uint256[] calldata _betEndTime
    ) external onlyOwner {
        for (uint256 i = 0; i < _matchId.length; ++i) {
            MatchInfo storage allMatch = allMatches[_matchId[i]];
            allMatch.countryHomeId = _countryHomeId[i];
            allMatch.countryAwayId = _countryAwayId[i];
            allMatch.betEndTime = _betEndTime[i];
            allMatch.result = 0;
        }
    }

    function setMatchResult(
        uint256[] calldata _matchId,
        uint256[] calldata _result
    ) external onlyOwner {
        for (uint256 i = 0; i < _matchId.length; ++i) {
            MatchInfo storage allMatch = allMatches[_matchId[i]];
            require(block.timestamp > allMatch.betEndTime + 90 * 60, "Match is not ended");
            allMatch.result = _result[i];
        }
    }

    function setMatchCountryInfo(
        uint256[] calldata _countryId,
        string[] calldata _representCountryName,
        uint256[] calldata _heroId,
        uint256[] calldata _heroRarity
    ) external onlyOwner {
        // 6 countries will be repeated
        require(_heroId.length == 38, "Country list length should be equal to 38!");
        for (uint256 i = 0; i < _heroId.length; ++i) {
            MatchCountryInfo storage matchCountry = allMatchCountries[_countryId[i]];
            matchCountry.countryName = _representCountryName[i];
            matchCountry.heroId.push(_heroId[i]);
            matchCountry.heroRarity.push(_heroRarity[i]);
        }
    }

    function setFinalRankingBetEndTime(uint256 _finalRankingBetEndTime) external onlyOwner{
        finalRankingBetEndTime = _finalRankingBetEndTime;
    }

    function resetMatchCountries() external onlyOwner {
        for (uint256 i = 1; i <= 38; ++i) {
            MatchCountryInfo storage matchCountry = allMatchCountries[i];
            delete matchCountry.countryName;
            delete matchCountry.heroId;
            delete matchCountry.heroRarity;
        }
    }

    function getCountryHeroes(uint256 _countryId) public view returns(uint256[] memory, uint256[] memory){
        MatchCountryInfo storage matchCountry = allMatchCountries[_countryId];
        uint256[] storage heroIdList = matchCountry.heroId;
        uint256[] storage heroRarityList = matchCountry.heroRarity;
        return (heroIdList, heroRarityList);
    }

    function getAllMatchResults() public view returns(uint256[64] memory){
        uint256[64] memory allMatchResults;
        for (uint256 i = 0; i < 64; ++i) {
            MatchInfo storage matchInfo = allMatches[i+1];
            allMatchResults[i] = matchInfo.result;
        }
        return allMatchResults;
    }
    function getUserBetTokenList(address user, bool isFinal) public view returns(uint256[] memory){
        UserBetInfo storage userBet = userMatchBets[user];
        if(isFinal) return userBet.tokenIdListFinal;
        return userBet.tokenIdList;
    }
    function getUserBetsByMatchId(address user, uint256 matchId) public view returns(uint256[4] memory){
        UserBetInfo storage userBet = userMatchBets[user];
        uint256[4] memory bets = userBet.bets[matchId];
        return bets;
    }
    function getUserBetsAll(address user) public view returns(uint256[4][64] memory){
        uint256[4][64] memory allBets;
        uint256[4] memory bets;
        for(uint256 _matchId=1; _matchId<=64; ++_matchId){
            UserBetInfo storage userBet = userMatchBets[user];
            bets = userBet.bets[_matchId];
            allBets[_matchId-1] = bets;
        }
        return allBets;
    }
    function getUserBetsAllClaimed(address user) public view returns(uint256[64] memory){
        uint256[64] memory betsClaimed;
        for(uint256 _matchId=1; _matchId<=64; ++_matchId){
            UserBetInfo storage userBet = userMatchBets[user];
            betsClaimed[_matchId-1] = userBet.betsClaimed[_matchId];
        }
        return betsClaimed;
    }

    function betByMatchId(
        uint256[] calldata _tokenIds,
        uint256[] calldata _matchIds,
        uint256[] calldata _isDraw)
    external onlyEOA {
        UserBetInfo storage userBet = userMatchBets[_msgSender()];
        if(!userBet.activated){
            userBet.credits = initCredit;
            userBet.activated = true;
            allMatchBettingAddresses.push(_msgSender());
        }
        uint256 consumeCredits = consumeCreditEachBet * _tokenIds.length;
        require(userBet.credits + userBet.winCredits >= consumeCredits, "Insufficient user credits");
        for (uint256 i = 0; i < _tokenIds.length; ++i) {

            bool betHomeCountry = _betByMatchId(_tokenIds[i], _matchIds[i]);
            // Home vs Away
            // betResults: 0=> none; 1=>HomeWin, 2=>AwayWin, 3=>Draw
            uint256[4] storage bet = userBet.bets[_matchIds[i]];
            if(_matchIds[i]>48){
                require(_isDraw[i]==0, "Final match cannot be draw");
            }
            if(_isDraw[i]==1){
                ++bet[3];
            }else if(betHomeCountry){
                ++bet[1];
            }else{
                ++bet[2];
            }
            nftOwnedBy[_tokenIds[i]] = _msgSender();

            // transfer card to contract address
            definaCard.safeTransferFrom(_msgSender(), address(this), _tokenIds[i]);
            userBet.tokenIdList.push(_tokenIds[i]);
        }

        // deduct credits (100 per bet)
        if(userBet.credits < consumeCredits){
            totalWinCredits -= (consumeCredits - userBet.credits);
            userBet.winCredits -= (consumeCredits - userBet.credits);
            userBet.credits = 0;
        }else{
            userBet.credits -= consumeCredits;
        }
    }

    function _betByMatchId(uint256 _tokenId, uint256 _matchId) private view returns (bool){
        uint256 heroId = definaCard.heroIdMap(_tokenId); // 下注的 heroId
        uint256 rarity = definaCard.rarityMap(_tokenId); // 下注的 rarity

        MatchInfo storage matchInfo = allMatches[_matchId];
        require(block.timestamp < matchInfo.betEndTime, "This Match bet is ended");
        MatchCountryInfo storage country1 = allMatchCountries[matchInfo.countryHomeId];
        uint256[] storage matchHeroId1 = country1.heroId;
        uint256[] storage matchHeroRarity1 = country1.heroRarity; // 获得本场比赛的HomeCountry 的 heroId 和 rarity

        MatchCountryInfo storage country2 = allMatchCountries[matchInfo.countryAwayId];
        uint256[] storage matchHeroId2 = country2.heroId;
        uint256[] storage matchHeroRarity2 = country2.heroRarity; // 获得本场比赛的AwayCountry 的 heroId 和 rarity

        bool betHomeCountry;
        bool betAwayCountry;
        if(matchHeroId1.length == 1){
            betHomeCountry = (heroId==matchHeroId1[0] && rarity==matchHeroRarity1[0]);
        }else{
            betHomeCountry = (heroId==matchHeroId1[0] && rarity==matchHeroRarity1[0]) || (heroId==matchHeroId1[1] && rarity==matchHeroRarity1[1]);
        }
        if(matchHeroId2.length == 1){
            betAwayCountry = (heroId==matchHeroId2[0] && rarity==matchHeroRarity2[0]);
        }else{
            betAwayCountry = (heroId==matchHeroId2[0] && rarity==matchHeroRarity2[0]) || (heroId==matchHeroId2[1] && rarity==matchHeroRarity2[1]);
        }

        require(betHomeCountry || betAwayCountry, "The betting hero is not in the match");
        return betHomeCountry;
    }

    // backend calculation
    function getMatchBettingAddresses() public view returns(address[] memory){
        return allMatchBettingAddresses;
    }

    function setLeaderboard(
        address[3] calldata _leaderboard,
        uint256 _prizePool) external onlyOwner{

        for(uint i=0; i<3; ++i){
            isInLeaderboard[_leaderboard[i]] = true;
        }
        leaderboardUsers = _leaderboard;
//        totalWinCredits -= _leaderboardTotalCredits;
        prizePool = _prizePool;
    }

    function getUserUnclaimedCredits(address user) public view returns(uint256){
        uint256 unClaimedCredits;
        UserBetInfo storage userBet = userMatchBets[user];
        for(uint256 _matchId=1; _matchId<=totalMatches; ++_matchId) {
            MatchInfo storage allMatch = allMatches[_matchId];
            if(userBet.betsClaimed[_matchId] == 0){
                unClaimedCredits += userBet.bets[_matchId][allMatch.result] * consumeCreditEachBet * 2;
            }
        }
        if(heroRarityRewardRatio[9] != 0){
            uint256[] memory _tokenIds = userBet.tokenIdListFinal;
            for (uint256 i = 0; i < _tokenIds.length; ++i) {
                if(tokenClaimedCredits[_tokenIds[i]] == 0){
                    uint256 rarity = definaCard.rarityMap(_tokenIds[i]);
                    uint256 heroId = definaCard.heroIdMap(_tokenIds[i]);
                    unClaimedCredits += consumeCreditEachBet * heroRewardRatio[heroId] * heroRarityRewardRatio[rarity];
                }
            }
        }
        return unClaimedCredits;
    }

    function claimMatchBetCreditsAll() public onlyEOA {
        for(uint _matchId=1; _matchId<=totalMatches; ++_matchId) {
            claimBetCreditsByMatchId(_matchId);
        }
        if(heroRarityRewardRatio[9] != 0){
            claimFinalMatchBetCredits();
        }
    }

    function claimBetCreditsByMatchId(uint256 _matchId) public onlyEOA {
        require(!claimableActive, "Credits not claimable");
//        require(allMatches[_matchId].result != 0, "Match Result is not revealed");
        if(allMatches[_matchId].result != 0){
            UserBetInfo storage userBet = userMatchBets[_msgSender()];
            if(userBet.betsClaimed[_matchId] == 0){
                uint256 credits = userBet.bets[_matchId][allMatches[_matchId].result] * consumeCreditEachBet * 2;
                userBet.winCredits += credits;
                totalWinCredits += credits;
                userBet.betsClaimed[_matchId] = credits;
            }
        }
    }

    function claimFinalMatchBetCredits() public onlyEOA {
        UserBetInfo storage userBet = userMatchBets[_msgSender()];
        uint256[] memory _tokenIds = userBet.tokenIdListFinal;
        claimFinalMatchBetCreditsByTokenIds(_tokenIds);
    }

    function claimFinalMatchBetCreditsByTokenIds(uint256[] memory _tokenIds) public onlyEOA {
        require(!claimableActive, "Credits not claimable");
        UserBetInfo storage userBet = userMatchBets[_msgSender()];
        for (uint256 i = 0; i < _tokenIds.length; ++i) {
            require(nftOwnedBy[_tokenIds[i]]==_msgSender(), "NFT is not owned by sender");
            if(tokenClaimedCredits[_tokenIds[i]] == 0){
                uint256 rarity = definaCard.rarityMap(_tokenIds[i]);
                uint256 heroId = definaCard.heroIdMap(_tokenIds[i]);
                uint256 credits = consumeCreditEachBet * heroRewardRatio[heroId] * heroRarityRewardRatio[rarity];
                userBet.winCredits += credits;
                totalWinCredits += credits;
                tokenClaimedCredits[_tokenIds[i]] = credits;
            }
        }
    }

    function getFinalMatchBetCreditsByTokenIds(uint256[] memory _tokenIds) public view returns(uint256) {
        uint256 credits;
        for (uint256 i = 0; i < _tokenIds.length; ++i) {
            if(tokenClaimedCredits[_tokenIds[i]] == 0){
                uint256 rarity = definaCard.rarityMap(_tokenIds[i]);
                uint256 heroId = definaCard.heroIdMap(_tokenIds[i]);
                credits += consumeCreditEachBet * heroRewardRatio[heroId] * heroRarityRewardRatio[rarity];
            }
        }
        return credits;
    }

    function claimMatchBetReward() external whenClaimableActive onlyEOA {
//        claimMatchBetCreditsAll();
        UserBetInfo storage userBet = userMatchBets[_msgSender()];

        for (uint256 i = 0; i < userBet.tokenIdList.length; ++i) {
            uint tokenId = userBet.tokenIdList[i];
            require(_msgSender() == nftOwnedBy[tokenId], "_msgSender() is not the owner");
            // transfer hero back to user
            definaCard.safeTransferFrom(address(this), _msgSender(), tokenId);
        }
        for (uint256 i = 0; i < userBet.tokenIdListFinal.length; ++i) {
            uint tokenId = userBet.tokenIdListFinal[i];
            require(_msgSender() == nftOwnedBy[tokenId], "_msgSender() is not the owner");
            // transfer hero back to user
            definaCard.safeTransferFrom(address(this), _msgSender(), tokenId);
        }
        uint256 userPrize;
        if(isInLeaderboard[_msgSender()]){
            if(_msgSender()==leaderboardUsers[0]){
                userPrize = prizePool * 12 / 100;
            }else if(_msgSender()==leaderboardUsers[1]){
                userPrize = prizePool * 5 / 100;
            }else{
                userPrize = prizePool * 3 / 100;
            }
        }
        userPrize += prizePool / 2 * userBet.winCredits / totalWinCredits;

        if (prizePoolTokenAddress == address(0)) {
            payable(_msgSender()).transfer(userPrize);
        } else {
            IERC20 token = IERC20(prizePoolTokenAddress);
            token.transfer(_msgSender(), userPrize);
        }
    }

    function setClaimableActive(bool isActive) external onlyOwner{
        claimableActive = isActive;
    }

    function buyCredits(uint256 amount) external onlyEOA {
        IERC20Upgradeable token = IERC20Upgradeable(creditPaymentCurrency);
        token.safeTransferFrom(_msgSender(), address(this), amount * creditCost);
        UserBetInfo storage userBet = userMatchBets[_msgSender()];
        if(!userBet.activated){
            userBet.credits = initCredit;
            userBet.activated = true;
            allMatchBettingAddresses.push(_msgSender());
        }
        userBet.credits += amount;
    }

    function pullFunds(address tokenAddress_) external onlyOwner {
        if (tokenAddress_ == address(0)) {
            payable(_msgSender()).transfer(address(this).balance);
        } else {
            IERC20 token = IERC20(tokenAddress_);
            token.transfer(_msgSender(), token.balanceOf(address(this)));
        }
    }

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2;
interface INewDefinaCard {
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    function heroIdMap(uint tokenId_) external view returns (uint);

    function rarityMap(uint tokenId_) external view returns (uint);
}