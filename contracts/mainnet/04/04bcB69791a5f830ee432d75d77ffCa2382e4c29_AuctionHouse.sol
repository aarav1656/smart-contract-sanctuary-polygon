// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (metatx/ERC2771Context.sol)

pragma solidity ^0.8.9;

import "../utils/Context.sol";

/**
 * @dev Context variant with ERC2771 support.
 */
abstract contract ERC2771Context is Context {
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    address private immutable _trustedForwarder;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address trustedForwarder) {
        _trustedForwarder = trustedForwarder;
    }

    function isTrustedForwarder(address forwarder) public view virtual returns (bool) {
        return forwarder == _trustedForwarder;
    }

    function _msgSender() internal view virtual override returns (address sender) {
        if (isTrustedForwarder(msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            /// @solidity memory-safe-assembly
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return super._msgSender();
        }
    }

    function _msgData() internal view virtual override returns (bytes calldata) {
        if (isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length - 20];
        } else {
            return super._msgData();
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
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
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../IERC1155Receiver.sol";
import "../../../utils/introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

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
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
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
interface IERC165 {
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

// SPDX-License-Identifier: BUSL-1.1
// Reality NFT Contracts
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Receiver.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/metatx/ERC2771Context.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @title NFT auctioning system
/// @author Imapp
/// @notice This contract holds forward auctions of ERC1155 tokens. The seller pays in tokens and starts the auction.
/// The bidding is done in the selected ERC20 tokens that act as auction currency. The highest bidder 
/// pays in the full amount and the previous bidder has their amount returned. At the end of the auction,
/// the highest bidder receives NFT tokens and the seller receives currency. This is reversed if the reserve price
/// has not been met. 
/// @dev The main currency is a specific token, transfers return true or revert, no need for safeTransfer.
contract AuctionHouse is ERC1155Receiver, ERC2771Context, Ownable {
  using SafeERC20 for IERC20;

  struct Auction {
    address seller;
    uint40 endDate;
    uint40 expiryDate;
    uint256 tokenId;
    uint256 tokenAmount;
    uint256 reservePrice;
    uint256 stableExchangeRate;
    uint256 highestBidCurrencyAmount;
    CurrencyType highestBidCurrencyType;
    address highestBidder;
    uint40 timeIncrement;
    uint256 priceIncrement;
  }

  struct EmergencyNftRelease {
    address holder;
    uint40 holderTimelock;
    uint256 tokenId;
    uint256 tokenAmount;
  }

  enum CurrencyType {
    Main,
    Stable
  }

  /// @notice returns version of open-gsn used
  // solhint-disable-next-line const-name-snakecase
  string constant public versionRecipient = "2.2.6";

  /// @notice All auction have to have reasonable timeframe
  uint40 public constant MAXIMUM_AUCTION_DURATION = 30 days;

  /// @dev Id of the last auction
  uint256 private _auctionCount = 0;

  /// @dev Auctions mapped to auction id
  mapping(uint256 => Auction) private _auctions;

  /// @dev Stores point in time when the emergency release can be executed
  mapping(uint256 => uint256) private _emergencyReleaseTimelock;

  /// @dev This is a specific token, safeTransfer used a per ERC1155 spec
  IERC1155 private immutable _auctionableNft;
  
  /// @notice Reality currency of choice for auction transactions
  /// @dev This is a specific token, transfers return true or revert, no need for safeTransfer
  IERC20 public immutable mainCurrency;

  /// @notice Alternative stable-coin currency for auction transactions
  IERC20 public immutable stableCurrency;

  /// @dev Holds the total value of currency paid in as current bidding
  uint256 private _activeBiddingMainTotal = 0;
  uint256 private _activeBiddingStableTotal = 0;

  /// @dev Holds information on NFTs that could not be transfered and were placed in the locker
  mapping(uint256 => EmergencyNftRelease) internal _emergencyLocker;

  bytes4 internal constant SAFETRANSFERFROM_SIGNATURE = bytes4(keccak256("safeTransferFrom(address,address,uint256,uint256,bytes)"));

  /// @dev 
  uint256 internal constant EXCHANGERATE_PRECISION = 10 ** 18;

  /// @notice Emitted when new auction is created by the owner of the contract.
  event AuctionCreated(uint256 indexed auctionId, address indexed seller, uint256 indexed tokenId, uint256 tokenAmount, uint256 reservePrice , uint256 endDate, uint40 expiryDate, uint256 priceIncrement, uint40 timeIncrement, uint256 stableExchangeRate);

  /// @notice Emitted when auction assets were bid.
  event AuctionBid(uint256 indexed auctionId, address indexed buyer, uint256 price, uint256 newEndDate, CurrencyType currencyType, uint256 currencyAmount);

  /// @notice Emitted when auction is settled.
  event AuctionSettled(uint256 indexed auctionId, uint256 price);

  /// @notice Emitted when auction was cancelled and assets were returned to the seller.
  event AuctionCancelled(uint256 indexed auctionId);

  /// @notice Emitted when the emergency release is initiated and indicates when it can be executed
  event EmergencyReleaseInitiated(uint256 indexed auctionId, uint256 timelock);

  /// @notice 
  event EmergencyReleaseComplete(uint256 indexed auctionId);

  /// @param auctionableNft The address of NFT ERC1155 token that is subject to the auction
  /// @param currency_ The address of ERC20 token that is used as auction currency
  /// @param stableCurrency_ The address of ERC20 token that is used as auction alternative, stable-coin currency
  /// @param trustedForwarder open-gsn forwarder address
  constructor(IERC1155 auctionableNft, IERC20 currency_, IERC20 stableCurrency_, address trustedForwarder) ERC2771Context(trustedForwarder) {
    require(address(auctionableNft) != address(0), "AuctionHouse: NFT token cannot be null");
    require(address(currency_) != address(0), "AuctionHouse: Token cannot be null");
    require(trustedForwarder != address(0), "AuctionHouse: Trusted Forwarder address cannot be null");

    _auctionableNft = auctionableNft;
    mainCurrency = currency_;
    stableCurrency = stableCurrency_;
  }

  function _msgSender() internal view override(ERC2771Context, Context)
      returns (address sender) {
      sender = ERC2771Context._msgSender();
  }

  function _msgData() internal view override(ERC2771Context, Context)
      returns (bytes calldata) {
      return ERC2771Context._msgData();
  }

  /// @notice Start the auction by the seller. The seller has to approve spending before calling this function
  /// @param tokenId Id of the ERC1155 token at auctionableNft address
  /// @param tokenAmount Number of tokens subject to auction
  /// @param endDate Initial end date, subject to sliding time window
  /// @param expiryDate Ultimate end date, after which the auction must be settled
  /// @param reservePrice A required minimal sale price set by the seller
  /// @param priceIncrement Optional minimal margin from the previous bid
  /// @param timeIncrement Optional time in seconds that extend the end date
  /// @dev No `data` is sent to safeTransferFrom()
  function createAuction(
    uint256 tokenId,
    uint256 tokenAmount,
    uint40 endDate,
    uint40 expiryDate,
    uint256 reservePrice,
    uint256 priceIncrement,
    uint40 timeIncrement,
    uint256 stableExchangeRate
  ) external returns (uint256) {
    require(tokenAmount > 0, "AuctionHouse: empty auction");
    require(endDate > block.timestamp, "AuctionHouse: wrong end date");
    require(expiryDate >= endDate, "AuctionHouse: wrong expiry date");
    require(block.timestamp + MAXIMUM_AUCTION_DURATION > endDate && block.timestamp + MAXIMUM_AUCTION_DURATION > expiryDate, "AuctionHouse: auction too long");
    require(priceIncrement > 0, "AuctionHouse: Price increment missing");
    require(reservePrice > 0, "AuctionHouse: Reserve Price is missing. Please enter a valid reservePrice");

    if (address(stableCurrency) != address(0)) {
      require(stableExchangeRate > 0, "AuctionHouse: Currency to stabele exchange");
    }

    address sender = _msgSender();
    uint256 auctionId = ++_auctionCount;

    _auctions[auctionId] = Auction(
      sender,
      endDate,
      expiryDate,
      tokenId,
      tokenAmount,
      reservePrice,
      stableExchangeRate,
      0,
      CurrencyType.Main,
      address(0),
      timeIncrement,
      priceIncrement
    );

    emit AuctionCreated(auctionId, sender, tokenId, tokenAmount, reservePrice,  endDate, expiryDate , priceIncrement, timeIncrement, stableExchangeRate);

    // transfering to AuctionHouse contract, deemed as safe
    _auctionableNft.safeTransferFrom(sender, address(this), tokenId, tokenAmount, "");

    return auctionId;
  }

  /// @notice The bidder must provide spending allowance for the bidding price in main currency
  /// @param auctionId Auction id
  /// @param amount The bid amount that must be equal or greater than: current highest bid price + price increment
  function bid(uint256 auctionId, uint256 amount) external {
    // Storage pointer makes the execution cheaper by ~7k gas
    Auction storage auction = _auctions[auctionId];

    uint256 currentPrice = _highestBidPrice(auction);

    require(isActive(auctionId), "AuctionHouse: auction not active");
    require(auction.endDate >= block.timestamp, "AuctionHouse: auction ended");
    require(amount >= currentPrice + auction.priceIncrement, "AuctionHouse: insufficient price");

    CurrencyType previousBidCurrencyType = auction.highestBidCurrencyType;
    uint256 previousBidCurrencyAmount = auction.highestBidCurrencyAmount;
    address previousBidder = auction.highestBidder;
    address sender = _msgSender();

    auction.highestBidder = sender;
    auction.highestBidCurrencyType = CurrencyType.Main;
    auction.highestBidCurrencyAmount = amount;

    // move end date when bidding near the end, but do not exceed expiry date    
    if (block.timestamp + auction.timeIncrement > auction.endDate) {
      if (block.timestamp + auction.timeIncrement > auction.expiryDate) {
        auction.endDate = auction.expiryDate;
      } else {
        auction.endDate = uint40(block.timestamp) + auction.timeIncrement;
      }
    }

    _updateBiddingTotals(previousBidCurrencyType, previousBidCurrencyAmount, CurrencyType.Main, amount);

    emit AuctionBid(auctionId, sender, amount, auction.endDate, CurrencyType.Main, amount);

    // get funds from bidder
    mainCurrency.transferFrom(sender, address(this), amount);

    // return funds to the previous bidder
    if (previousBidder != address(0)) {
      _transferCurrency(previousBidder, previousBidCurrencyType, previousBidCurrencyAmount);
    }
  }

  /// @notice The bidder must provide spending allowance for the bidding price in stable currency
  /// @param auctionId Auction id
  /// @param stableAmount The bid price that must be equal or greater than: current highest bid price + price increment
  function bidStable(uint256 auctionId, uint256 stableAmount) external {
    require(address(stableCurrency) != address(0), "AuctionHouse: stable currency not set");

    // Storage pointer makes the execution cheaper by ~7k gas
    Auction storage auction = _auctions[auctionId];

    uint256 mainAmount = _fromStableCurrency(stableAmount, auction.stableExchangeRate);

    uint256 currentPrice = _highestBidPrice(auction);

    require(isActive(auctionId), "AuctionHouse: auction not active");
    require(auction.endDate >= block.timestamp, "AuctionHouse: auction ended");
    require(mainAmount >= currentPrice + auction.priceIncrement, "AuctionHouse: insufficient price");

    CurrencyType previousBidCurrencyType = auction.highestBidCurrencyType;
    uint256 previousBidCurrencyPrice = auction.highestBidCurrencyAmount;
    address previousBidder = auction.highestBidder;
    address sender = _msgSender();

    auction.highestBidder = sender;
    auction.highestBidCurrencyType = CurrencyType.Stable;
    auction.highestBidCurrencyAmount = stableAmount;

    // move end date when bidding near the end, but do not exceed expiry date    
    if (block.timestamp + auction.timeIncrement > auction.endDate) {
      if (block.timestamp + auction.timeIncrement > auction.expiryDate) {
        auction.endDate = auction.expiryDate;
      } else {
        auction.endDate = uint40(block.timestamp) + auction.timeIncrement;
      }
    }

    _updateBiddingTotals(previousBidCurrencyType, previousBidCurrencyPrice, CurrencyType.Stable, stableAmount);

    ///todo: event to contain stable + main price?
    emit AuctionBid(auctionId, sender, mainAmount, auction.endDate, CurrencyType.Stable, stableAmount);

    // get funds from bidder
    stableCurrency.safeTransferFrom(sender, address(this), stableAmount);

    // return funds to the previous bidder
    if (previousBidder != address(0)) {
      _transferCurrency(previousBidder, previousBidCurrencyType, previousBidCurrencyPrice);
    }
  }

  /// @notice Auction can be settled after the end date. This can be called by anyone.
  /// If the reserve price was met then the transaction is finalized. Otherwise the transaction is cancelled.
  function settle(uint256 auctionId) external {
    Auction memory auction = _auctions[auctionId];

    require(auction.endDate < block.timestamp, "AuctionHouse: auction not ended");
    require(isActive(auctionId), "AuctionHouse: auction not active");

    uint256 currentHighestPrice = _highestBidPrice(_auctions[auctionId]);

    delete _auctions[auctionId];
    _updateBiddingTotals(auction.highestBidCurrencyType, auction.highestBidCurrencyAmount, CurrencyType.Main, 0);

    if (currentHighestPrice > 0 && currentHighestPrice >= auction.reservePrice) {
      emit AuctionSettled(auctionId, currentHighestPrice);
      _transferCurrency(auction.seller, auction.highestBidCurrencyType, auction.highestBidCurrencyAmount);
      safeNftTransfer(auctionId, address(this), auction.highestBidder, auction.tokenId, auction.tokenAmount);
    } else {
      emit AuctionCancelled(auctionId);
      _transferCurrency(auction.highestBidder, auction.highestBidCurrencyType, auction.highestBidCurrencyAmount);
      safeNftTransfer(auctionId, address(this), auction.seller, auction.tokenId, auction.tokenAmount);
    }
  }

  /// @notice Auction can be cancelled by the seller at any time
  /// @dev No `data` is sent to safeTransferFrom()
  function cancel(uint auctionId) external {
    Auction memory auction = _auctions[auctionId];

    require(isActive(auctionId), "AuctionHouse: auction not active");
    require(_msgSender() == auction.seller, "AuctionHouse: only seller can cancel");
    require(auction.endDate >= block.timestamp, "AuctionHouse: already ended");

    delete _auctions[auctionId];
    _updateBiddingTotals(auction.highestBidCurrencyType, auction.highestBidCurrencyAmount, CurrencyType.Main, 0);

    emit AuctionCancelled(auctionId);

    _transferCurrency(auction.highestBidder, auction.highestBidCurrencyType, auction.highestBidCurrencyAmount);
    safeNftTransfer(auctionId, address(this), auction.seller, auction.tokenId, auction.tokenAmount);
  }

  /// @notice Returns auction details
  function getAuction(uint256 auctionId) external view returns (Auction memory) {
    return _auctions[auctionId];
  }

  /// @notice Checks whether the given auction has its reserve price met and therefore can be settled
  function isReserveMet (uint256 auctionId) external view returns (bool) {
    uint256 currentHighestPrice = _highestBidPrice(_auctions[auctionId]);
    return currentHighestPrice >= _auctions[auctionId].reservePrice;
  }

  function isActive (uint256 auctionId) public view returns (bool) {
    return _auctions[auctionId].seller != address(0);
  }

  /// @notice Only accepts tokens from AuctionHouse.createAuction()
  function onERC1155Received(address operator, address, uint256, uint256, bytes memory) external virtual returns (bytes4) {
    require(operator == address(this), "AuctionHouse: Direct NFT transfers not allowed");
    return this.onERC1155Received.selector;
  }

  /// @notice Batch transfers not allowed
  function onERC1155BatchReceived(address, address, uint256[] memory, uint256[] memory, bytes memory) external virtual returns (bytes4) {
    revert("AuctionHouse: Batch operations not allowed");
  }

  /// @notice When settling or cancelling a bid, 
  /// NFT transfers can fail due to receiver contract error or a malicious player.
  /// In that case funds are kept in a locker that can be released to the address
  /// provided by the rightful holder. If not released in time, then the funds
  /// can be released by the contract owner
  function emergencyNftRecovery(uint256 auctionId, address to) external {
    EmergencyNftRelease memory emergencyLock = _emergencyLocker[auctionId];
    require(emergencyLock.holder != address(0), "AuctionHouse: No emergency release");
    require(to != address(0), "AuctionHouse: No destination address");

    if (emergencyLock.holderTimelock > block.timestamp) {
      require(_msgSender() == emergencyLock.holder, "AuctionHouse: Only holder can release now");
    } else {
      require(_msgSender() == emergencyLock.holder ||  _msgSender() == owner(), "AuctionHouse: Only holder or owner can release");
    }

    delete _emergencyLocker[auctionId];

    _auctionableNft.safeTransferFrom(address(this), to, emergencyLock.tokenId, emergencyLock.tokenAmount, "");
  }

  /// @notice This pays out any ERC20 tokens that were incorrectly sent to the auction contract
  function emergencyMainExcessHandout(address to) external onlyOwner {
    require(to != address(0), "AuctionHouse: No destination address");
    require(mainCurrency.balanceOf(address(this)) > _activeBiddingMainTotal, "AuctionHouse: no excess");
    mainCurrency.transfer(to, mainCurrency.balanceOf(address(this)) - _activeBiddingMainTotal);
  }

  /// @notice This pays out any ERC20 tokens that were incorrectly sent to the auction contract
  function emergencyStableExcessHandout(address to) external onlyOwner {
    require(to != address(0), "AuctionHouse: No destination address");
    require(stableCurrency.balanceOf(address(this)) > _activeBiddingStableTotal, "AuctionHouse: no excess");
    stableCurrency.safeTransfer(to, stableCurrency.balanceOf(address(this)) - _activeBiddingStableTotal);
  }

  /// @dev Attempts to transfer the NFTs to the given address. If the transfer fails, then
  /// the tokens are kept in the locker. The transfer can fail due to: receiver contract error,
  /// multi-sig, malicious actor.
  function safeNftTransfer(uint256 auctionId, address from, address to, uint256 tokenId, uint256 tokenAmount) internal {
    bytes memory callData = abi.encodeWithSelector(
      SAFETRANSFERFROM_SIGNATURE,
      from,
      to,
      tokenId,
      tokenAmount, 
      ""
    );

    // if the transfer fails, it creates an emergency locker and let the program continue
    // 66746 is the gas required to add an entry to _emergencyLocker
    // solhint-disable-next-line avoid-low-level-calls
    (bool callSuccess, ) = address(_auctionableNft).call{gas: gasleft() - 66746}(callData);
    if (!callSuccess) {
      _emergencyLocker[auctionId] = EmergencyNftRelease (
        to,
        uint40(block.timestamp) + MAXIMUM_AUCTION_DURATION,
        tokenId,
        tokenAmount
      );
    }
  }

  /// @notice Calculates exchange rate used for converting stable currency to the main currency
  /// @param mainCurrencyAmount any amount expressed in the main currency
  /// @param stableCurrencyAmount equal value expressed in the stable currency
  function calculateExchangeRate(uint256 mainCurrencyAmount, uint256 stableCurrencyAmount) external pure returns (uint256) {
    return mainCurrencyAmount * EXCHANGERATE_PRECISION / stableCurrencyAmount;
  }

  /// @dev Calculates exchange rate used for converting stable currency to the main currency
  /// @param stableCurrencyAmount any amount expressed in the main currency
  /// @param stableExchangeRate equal value expressed in the stable currency
  function _fromStableCurrency(uint256 stableCurrencyAmount, uint256 stableExchangeRate) internal pure returns (uint256) {
    return stableCurrencyAmount * stableExchangeRate / EXCHANGERATE_PRECISION;
  }

  function _highestBidPrice(Auction storage auction) internal view returns (uint256) {
    if (auction.highestBidCurrencyType == CurrencyType.Main) {
      return auction.highestBidCurrencyAmount;
    } else {
      return _fromStableCurrency(auction.highestBidCurrencyAmount, auction.stableExchangeRate);
    }
  }

  function _transferCurrency(address to, CurrencyType currencyType, uint256 amount) internal {
    if (to != address(0)) {
      if (currencyType == CurrencyType.Main) {
        mainCurrency.transfer(to, amount);
      } else if (currencyType == CurrencyType.Stable) {
        stableCurrency.safeTransfer(to, amount);
      }
    }
  }

  function _updateBiddingTotals(CurrencyType previousType, uint256 previousAmount, CurrencyType newType, uint256 newAmount) internal {
    if (previousType == CurrencyType.Main) {
      _activeBiddingMainTotal -= previousAmount;
    } else if (previousType == CurrencyType.Stable) {
      _activeBiddingStableTotal -= previousAmount;
    }

    if (newType == CurrencyType.Main) {
      _activeBiddingMainTotal += newAmount;
    } else if (newType == CurrencyType.Stable) {
      _activeBiddingStableTotal += newAmount;
    }
  }
}