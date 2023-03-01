// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

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
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
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
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (security/ReentrancyGuard.sol)

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

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155ReceiverUpgradeable is IERC165Upgradeable {
    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;

import "./ERC1155ReceiverUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev _Available since v3.1._
 */
contract ERC1155HolderUpgradeable is Initializable, ERC1155ReceiverUpgradeable {
    function __ERC1155Holder_init() internal initializer {
        __ERC165_init_unchained();
        __ERC1155Receiver_init_unchained();
        __ERC1155Holder_init_unchained();
    }

    function __ERC1155Holder_init_unchained() internal initializer {
    }
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../IERC1155ReceiverUpgradeable.sol";
import "../../../utils/introspection/ERC165Upgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155ReceiverUpgradeable is Initializable, ERC165Upgradeable, IERC1155ReceiverUpgradeable {
    function __ERC1155Receiver_init() internal initializer {
        __ERC165_init_unchained();
        __ERC1155Receiver_init_unchained();
    }

    function __ERC1155Receiver_init_unchained() internal initializer {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return interfaceId == type(IERC1155ReceiverUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
// OpenZeppelin Contracts v4.4.0 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
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
// OpenZeppelin Contracts v4.4.0 (utils/Address.sol)

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal initializer {
        __ERC165_init_unchained();
    }

    function __ERC165_init_unchained() internal initializer {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/introspection/IERC165.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUpgradeable {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
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
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

/// @title Interface defining PIX Landmark Staking
interface IPIXLandStaking {
	  /**
     * @notice Event emitted when a landmark is staked
     * @param account The staker's address
     * @param tokenId The token which was staked
     * @param amount The amount of tokens that were staked
     */
	  event PIXLandStaked(address indexed account, uint256 tokenId, uint256 amount);
	  /**
     * @notice Event emitted when a landmark is unstaked
     * @param account The address of user that unstakes
     * @param tokenId The token which was unstaked
     * @param amount The amount of tokens that were unstaked
     */
    event PIXLandUnstaked(address indexed account, uint256 tokenId, uint256 amount);
   	/**
     * @notice Event emitted when a reward is claimed
     * @param account The user's address
     * @param reward The amount of tokens that were claimed
     */
    event RewardClaimed(address indexed account, uint256 reward);
    /**
     * @notice Event emitted when the reward is added to the contract
     * @param tokenId The token for which the reward was added
     * @param reward The amount of rewards that were added
     */
    event RewardAdded(uint256 tokenId, uint256 reward);

		/**
		 * @notice Used to store info for Landmark pools
		 * @param periodFinish The timestamp of epoch end
		 * @param rewardRate The reward rate payout
		 * @param lastUpdateTime Timestamp of last pool update
		 * @param rewardPerTokenStored Total reward accumulated
		 * @param tokensStaked The amount of tokens staked
		 * @param userRewardPerTokenPaid The rewards paid out
		 * @param rewards The rewards accumulated to be paid out
		 */
    struct RewardPool {
        uint256 periodFinish;
        uint256 rewardRate;
        uint256 lastUpdateTime;
        uint256 rewardPerTokenStored;
        uint256 tokensStaked;
        mapping(address => uint256) userRewardPerTokenPaid;
        mapping(address => uint256) rewards;
    }

	  /**
     * @notice Used to get the amount of token shares staked by address
     * @param _walletAddress The wallet address for which staked amounts are requested
     * @param _tokenId The token for which staked amounts are requested
     * @return Amount of shares of token staked by address
     */
    function getStakedAmounts(address _walletAddress, uint256 _tokenId) external view returns (uint256);

    /**
     * @notice Used to get the amount of token shares staked per pool
     * @param _tokenId The token for which tokens staked are requested
     * @return Amount of shares of token staked per pool
     */
    function getTokensStakedPerPool(uint256 _tokenId) external view returns (uint256);

		/**
     * @notice Used to get the reward rate of a pool
     * @param _tokenId The token for which reward rate is requested
     * @return Current reward rate for a staking pool
     */
		function getRewardRate(uint256 _tokenId) external view returns (uint256);

	  /**
     * @notice Used to get all tokens address staked
     * @param _walletAddress The token for which the reward was added
	   * @return A list of tokens staked by address
     */
    function getStakedIDs(address _walletAddress) external view returns (uint256[] memory);

		/**
	   * @notice Used to get earned rewards for a batch of tokens
	   * @param _walletAddress The owner of tokenIDs
	   * @param _tokenIds List of token ids to get rewards
	   * @return Rewards accumulated by address for a given list of token ids
	   */
		function earnedBatch(address _walletAddress, uint256[] calldata _tokenIds)
				external
				view
				returns (uint256[] memory);

		/**
		 * @notice Used to get rewards earned by a given wallet address
		 * @param _walletAddress Wallet address to get rewards
		 * @return reward Rewards accumulated by address
		 */
		function earnedByAccount(address _walletAddress) external
	         view
	         returns (uint256);

    /**
     * @notice Set Reward distributor
     * @param _distributor Reward distributor to be address
     */
    function setRewardDistributor(address _distributor) external;

    /**
     * @notice Stake Landmark shares to the pool
     * @param _tokenId Token id to be staked
     * @param _amount Token amount to be staked
     * @notice emit {PIXLandStaked} event
     */
    function stake(uint256 _tokenId, uint256 _amount) external;

    /**
     * @notice Unstake Landmark shares from the pool
     * @param _tokenId Token id to be unstaked
     * @param _amount Token amount to be unstaked
     * @notice emit {PIXLandUnstaked} event
     */
    function unstake(uint256 _tokenId, uint256 _amount) external;

    /**
     * @notice Claim rewards from all Landmark pools
     * @notice emit {RewardClaimed} event
     */
    function claim() external;

    /**
     * @notice Add rewards to Landmark pools
     * @param _tokenIds Token ids of pools to receive rewards
     * @param _poolRewards Reward token amounts to be distributed
     * @param _epochDuration Period in which reward token amounts will be distributed
     * @notice emit {RewardAdded} event
     */
		function initializePools(
			 uint256[] calldata _tokenIds,
			 uint256[] calldata _poolRewards,
			 uint256 _epochDuration
		) external;
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../interfaces/IPIXLandStaking.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/utils/ERC1155HolderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";

contract PIXLandStaking is
    IPIXLandStaking,
    OwnableUpgradeable,
    ERC1155HolderUpgradeable,
    ReentrancyGuardUpgradeable
{
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /* State Variables */
    address private s_pixLandmark;
    address private s_rewardDistributor;
    IERC20Upgradeable private s_rewardToken;

    mapping(uint256 => RewardPool) private s_rewardPools;
    mapping(address => uint256[]) private s_stakedIDs;
    mapping(address => mapping(uint256 => uint256)) private s_stakedAmounts;

    /* Modifiers */
    modifier onlyRewardDistributor() {
        require(msg.sender == s_rewardDistributor, "Staking: NON_DISTRIBUTOR");
        _;
    }

    /* Functions */
    /**
     * @notice Initializer for the PIXLandStaking contract
     * @param _pixt IXT contract
     * @param _pixLandmark Landmark contract
     */
    function initialize(address _pixt, address _pixLandmark) public initializer {
        require(_pixt != address(0), "LandStaking: INVALID_PIXT");
        require(_pixLandmark != address(0), "LandStaking: INVALID_PIX_LAND");

        __Ownable_init();
        __ERC1155Holder_init();
        __ReentrancyGuard_init();

        s_rewardToken = IERC20Upgradeable(_pixt);
        s_pixLandmark = _pixLandmark;
    }

    /**
     * @notice Get reward per token staked for Landmark share
     * @param _tokenId The Token to get reward
     * @param _untilTimestamp The timestamp by which the reward per token is requested
     */
    function rewardPerToken(uint256 _tokenId, uint256 _untilTimestamp) public view returns (uint256) {
        RewardPool storage rewardPool = s_rewardPools[_tokenId];
        if (rewardPool.tokensStaked == 0) {
            return rewardPool.rewardPerTokenStored;
        }
        return
            rewardPool.rewardPerTokenStored +
            ((lastTimeRewardApplicable(_tokenId, _untilTimestamp) - rewardPool.lastUpdateTime) * rewardPool.rewardRate ) / rewardPool.tokensStaked;
    }

    /**
     * @notice Used to get the latest time for which the reward is applicable
     * @param _tokenId The token for which the reward was added
     * @param _untilTimestamp The timestamp by which the last time reward is applicable
     */
    function lastTimeRewardApplicable(uint256 _tokenId, uint256 _untilTimestamp) public view returns (uint256) {
        RewardPool storage rewardPool = s_rewardPools[_tokenId];
        return MathUpgradeable.min(_untilTimestamp, rewardPool.periodFinish);
    }

    // @inheritdoc IPIXLandStaking
    function getStakedAmounts(address _walletAddress, uint256 _tokenId) external view override returns (uint256) {
        return s_stakedAmounts[_walletAddress][_tokenId];
    }

    // @inheritdoc IPIXLandStaking
    function getRewardRate(uint256 _tokenId) external view override returns (uint256) {
        RewardPool storage rewardPool = s_rewardPools[_tokenId];
        return rewardPool.rewardRate;
    }

    // @inheritdoc IPIXLandStaking
    function getTokensStakedPerPool(uint256 _tokenId) external view override returns (uint256) {
        RewardPool storage rewardPool = s_rewardPools[_tokenId];
        return rewardPool.tokensStaked;
    }

    // @inheritdoc IPIXLandStaking
    function getStakedIDs(address _walletAddress) external view override returns (uint256[] memory) {
        return s_stakedIDs[_walletAddress];
    }

    /**
     * @notice Used to get earned rewards for addess and token
     * @param _walletAddress The address to get earned rewards
     * @param _tokenId The token to be get earned rewards
     * @return Rewards accumulated by address for a given token
     */
    function earned(address _walletAddress, uint256 _tokenId) public view returns (uint256) {
        return earnedUntilTimestamp(_walletAddress, _tokenId, block.timestamp);
    }

    /**
     * @notice Used to get earned rewards for addess and token until timestamp
     * @param _walletAddress The address to get earned rewards
     * @param _tokenId The token to be get earned rewards
     * @param _untilTimestamp The timestamp by which the earned reward is requested
     * @return reward Rewards accumulated by address for a given token until timestamp
     */
    function earnedUntilTimestamp(address _walletAddress, uint256 _tokenId, uint256 _untilTimestamp) public view returns (uint256 reward) {
        RewardPool storage rewardPool = s_rewardPools[_tokenId];
        return
            (s_stakedAmounts[_walletAddress][_tokenId] * (rewardPerToken(_tokenId, _untilTimestamp) - rewardPool.userRewardPerTokenPaid[_walletAddress]))  +
            rewardPool.rewards[_walletAddress];
    }

    // @inheritdoc IPIXLandStaking
    function earnedBatch(address _walletAddress, uint256[] calldata _tokenIds)
        external
        view
        override
        returns (uint256[] memory)
    {
        uint256[] memory earneds = new uint256[](_tokenIds.length);
        for (uint256 i; i < _tokenIds.length; i += 1) {
            earneds[i] = earned(_walletAddress, _tokenIds[i]);
        }
        return earneds;
    }

    // @inheritdoc IPIXLandStaking
    function earnedByAccount(address _walletAddress) external
        view
        override
        returns (uint256)
    {
        return earnedByAccountUntilTimestamp(_walletAddress, block.timestamp);
    }

    /**
     * @notice Used to get rewards earned by a wallet address until timestamp
     * @param _walletAddress Wallet address to get rewards
     * @param _untilTimestamp The timestamp by which the account earned reward is requested
     * @return reward Rewards accumulated by address until timestamp
     */
    function earnedByAccountUntilTimestamp(address _walletAddress, uint256 _untilTimestamp) public view returns (uint256 reward) {
        for (uint256 i; i < s_stakedIDs[_walletAddress].length; i += 1) {
            if (s_stakedAmounts[_walletAddress][s_stakedIDs[_walletAddress][i]] == 0) continue;
            reward += earnedUntilTimestamp(_walletAddress, s_stakedIDs[_walletAddress][i], _untilTimestamp);
        }
    }

    // @inheritdoc IPIXLandStaking
    function setRewardDistributor(address _distributor) external override onlyOwner {
        require(_distributor != address(0), "Staking: INVALID_DISTRIBUTOR");
        s_rewardDistributor = _distributor;
    }

    // @inheritdoc IPIXLandStaking
    function stake(uint256 _tokenId, uint256 _amount) external override nonReentrant {
        IERC1155Upgradeable(s_pixLandmark).safeTransferFrom(
            msg.sender,
            address(this),
            _tokenId,
            _amount,
            ""
        );
        updateReward(_tokenId, msg.sender);

        bool isTokenIdStaked;
        for (uint256 i; i < s_stakedIDs[msg.sender].length; i += 1) {
            if (_tokenId == s_stakedIDs[msg.sender][i]) {
                isTokenIdStaked = true;
                break;
            }
        }
        if (!isTokenIdStaked) s_stakedIDs[msg.sender].push(_tokenId);

        RewardPool storage rewardPool = s_rewardPools[_tokenId];
        rewardPool.tokensStaked += _amount;
        s_stakedAmounts[msg.sender][_tokenId] += _amount;

        emit PIXLandStaked(msg.sender, _tokenId, _amount);
    }

    // @inheritdoc IPIXLandStaking
    function unstake(uint256 _tokenId, uint256 _amount) external override nonReentrant {
        require(_tokenId > 0, "LandStaking: INVALID_TOKEN_ID");
        require(s_stakedAmounts[msg.sender][_tokenId] >= _amount, "LandStaking: NOT_ENOUGH");

        updateReward(_tokenId, msg.sender);

        RewardPool storage rewardPool = s_rewardPools[_tokenId];
        rewardPool.tokensStaked -= _amount;
        s_stakedAmounts[msg.sender][_tokenId] -= _amount;

        if (s_stakedAmounts[msg.sender][_tokenId] == 0)
            _deleteFromStakedNFTs(msg.sender, _tokenId);

        uint256 reward = rewardPool.rewards[msg.sender];
        if (reward > 0) {
            rewardPool.rewards[msg.sender] = 0;
            s_rewardToken.safeTransfer(msg.sender, reward);
            emit RewardClaimed(msg.sender, reward);
        }

        IERC1155Upgradeable(s_pixLandmark).safeTransferFrom(
            address(this),
            msg.sender,
            _tokenId,
            _amount,
            ""
        );

        emit PIXLandUnstaked(msg.sender, _tokenId, _amount);
    }

    /**
     * @notice Claim rewards for multiple Landmarks
     * @notice emit {RewardClaimed} event
     */
    function claimBatch(uint256[] memory tokenIds) public {
        uint256 reward;
        for (uint256 i; i < tokenIds.length; i += 1) {
            RewardPool storage rewardPool = s_rewardPools[tokenIds[i]];
            updateReward(tokenIds[i], msg.sender);
            reward += rewardPool.rewards[msg.sender];
            rewardPool.rewards[msg.sender] = 0;
        }
        if (reward > 0) {
            s_rewardToken.safeTransfer(msg.sender, reward);
            emit RewardClaimed(msg.sender, reward);
        }
    }

    // @inheritdoc IPIXLandStaking
    function claim() external override {
        uint256 count;
        for (uint256 i; i < s_stakedIDs[msg.sender].length; i += 1) {
            if (s_stakedAmounts[msg.sender][s_stakedIDs[msg.sender][i]] == 0) continue;
            count++;
        }
        uint256 k;
        uint256[] memory tokenIds = new uint256[](count);
        for (uint256 i; i < s_stakedIDs[msg.sender].length; i += 1) {
            if (s_stakedAmounts[msg.sender][s_stakedIDs[msg.sender][i]] == 0) continue;
            tokenIds[k++] = s_stakedIDs[msg.sender][i];
        }
        claimBatch(tokenIds);
    }

    // @inheritdoc IPIXLandStaking
    function initializePools(
        uint256[] calldata _tokenIds,
        uint256[] calldata _poolRewards,
        uint256 _epochDuration
    ) external override onlyRewardDistributor
    {
        uint256 length = _tokenIds.length;
        require(length == _poolRewards.length, "Staking: INVALID_ARGUMENTS");
        uint256 totalRewards;
        for(uint256 i=0; i<length; i++) {
            updateReward(_tokenIds[i], address(0));
            RewardPool storage rewardPool = s_rewardPools[_tokenIds[i]];
            if (block.timestamp >= rewardPool.periodFinish) {
                rewardPool.rewardRate = _poolRewards[i] / _epochDuration;
            } else {
                uint256 remaining = rewardPool.periodFinish - block.timestamp;
                uint256 leftover = remaining * rewardPool.rewardRate;
                rewardPool.rewardRate = (_poolRewards[i] + leftover) / _epochDuration;
            }
            rewardPool.lastUpdateTime = block.timestamp;
            rewardPool.periodFinish = block.timestamp + _epochDuration;
            totalRewards += _poolRewards[i];
            emit RewardAdded(_tokenIds[i], _poolRewards[i]);
        }
        s_rewardToken.safeTransferFrom(msg.sender, address(this), totalRewards);
    }

    /**
     * @notice Internal function to delete address and tokenId from s_stakedIDs
     * @param _walletAddress The address to remove
     * @param _tokenId The tokenID to remove
     */
    function _deleteFromStakedNFTs(address _walletAddress, uint256 _tokenId) internal {
        for (uint256 i; i < s_stakedIDs[_walletAddress].length; i++) {
            if (s_stakedIDs[_walletAddress][i] == _tokenId) {
                s_stakedIDs[_walletAddress][i] = s_stakedIDs[_walletAddress][s_stakedIDs[_walletAddress].length - 1];
                s_stakedIDs[_walletAddress].pop();
            }
        }
    }

    /**
     * @notice internal function to update rewards before staking/unstaking and claiming rewards
     * @param _tokenId The token to update pool
     * @param _walletAddress The wallet address to update pool
     */
    function updateReward(uint256 _tokenId, address _walletAddress) internal {
        RewardPool storage rewardPool = s_rewardPools[_tokenId];
        rewardPool.rewardPerTokenStored = rewardPerToken(_tokenId, block.timestamp);
        rewardPool.lastUpdateTime = lastTimeRewardApplicable(_tokenId, block.timestamp);
        if (_walletAddress != address(0)) {
            rewardPool.rewards[_walletAddress] = earned(_walletAddress, _tokenId);
            rewardPool.userRewardPerTokenPaid[_walletAddress] = rewardPool.rewardPerTokenStored;
        }
    }
}