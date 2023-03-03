/**
 *Submitted for verification at polygonscan.com on 2023-03-03
*/

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol

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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol

 
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
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

// File: @openzeppelin/contracts/token/ERC1155/IERC1155.sol

 
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

 
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

// File: @openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol

 
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

// File: @openzeppelin/contracts/utils/Address.sol

 
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

// File: @openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol

 
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;



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

// File: @openzeppelin/contracts/utils/Context.sol

 
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

// File: @openzeppelin/contracts/access/Ownable.sol

 
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

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

// File: @openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol

 
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

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

// File: @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol

 
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
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

// File: contracts/HyperPlayNFTLaunchpad.sol

pragma solidity ^0.8.4;







contract HyperPlayNFTLaunchpad is Ownable, IERC1155Receiver, IERC721Receiver {
    using SafeERC20 for IERC20;

    enum TokenType {ERC721, ERC1155}

    struct Token {
        TokenType tokenType;
        uint256 tokenId;
        address tokenAddress;
        uint8 round;
        uint256 amount; // only for ERC1155
        uint256 price; // in wei
        bool isWhitelisted;
        uint256 maxPurchase; // only for ERC1155
        uint256 purchased;
        uint256 startTime;
        uint256 endTime;
    }

    Token[] public tokens;

    struct Purchase {
        bool hasPurchased;
        uint256 quantity;
    }

    mapping(address => mapping(uint8 => mapping(address => Purchase))) public whitelist;

    function getWhitelist(address _contractAddress, uint8 _round, address _walletAddress) external view returns (bool, uint256) {
        Purchase memory purchase = whitelist[_contractAddress][_round][_walletAddress];
        return (purchase.hasPurchased, purchase.hasPurchased ? purchase.quantity : 0);
    }

    function addWhitelist(address _contractAddress, uint8 _round, address _walletAddress, uint256 _quantity) external onlyOwner {
        whitelist[_contractAddress][_round][_walletAddress] = Purchase(true, _quantity);
    }

    function addWhitelistAll(address _contractAddress, uint8[] memory _rounds, address[] memory _walletAddresses, uint256 _quantity) external onlyOwner {
        for (uint i = 0; i < _rounds.length; i++) {
            for (uint j = 0; j < _walletAddresses.length; j++) {
                whitelist[_contractAddress][_rounds[i]][_walletAddresses[j]] = Purchase(true, _quantity);
            }
        }
    }

    function canPurchase(address _contractAddress, uint8 _round, address _walletAddress, uint256 _quantity) internal view returns (bool) {
        return whitelist[_contractAddress][_round][_walletAddress].hasPurchased == false || whitelist[_contractAddress][_round][_walletAddress].quantity >= _quantity;
    }

    event TokenAdded(
        uint256 indexed tokenId,
        address indexed tokenAddress,
        TokenType tokenType,
        uint256 price,
        bool isWhitelisted,
        uint256 maxPurchase,
        uint256 startTime,
        uint256 endTime
    );

    event TokenRemoved(
        uint256 indexed tokenId,
        address indexed tokenAddress,
        TokenType tokenType
    );

    event TokenPurchased(
        uint256 indexed tokenId,
        address indexed tokenAddress,
        TokenType tokenType,
        address buyer,
        uint256 amount,
        uint256 price
    );

    function getBlockTimestamp() public view returns (uint256) {
        return block.timestamp;
    }

    function addTokenERC721(uint256 tokenId, address tokenAddress, uint8 round, uint256 price, bool isWhitelisted, uint256 maxPurchase, uint256 startTime, uint256 endTime) external onlyOwner {
        require(IERC721(tokenAddress).ownerOf(tokenId) == address(this), "Token must be owned by the contract");
        require(!isTokenIndex(tokenAddress, tokenId), "Token already registered.");
        tokens.push(Token({
        tokenType : TokenType.ERC721,
        tokenId : tokenId,
        tokenAddress : tokenAddress,
        round : round,
        amount : 0,
        price : price,
        isWhitelisted : isWhitelisted,
        maxPurchase : maxPurchase,
        purchased : 0,
        startTime : startTime,
        endTime : endTime
        }));
        emit TokenAdded(tokenId, tokenAddress, TokenType.ERC1155, price, isWhitelisted, maxPurchase, startTime, endTime);
    }

    function addTokensERC721(uint256[] memory tokenIds, address tokenAddress, uint8 round, uint256 price, bool isWhitelisted, uint256 maxPurchase, uint256 startTime, uint256 endTime) external onlyOwner {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(IERC721(tokenAddress).ownerOf(tokenIds[i]) == address(this), "Token must be owned by the contract");
            require(!isTokenIndex(tokenAddress, tokenIds[i]), "Token already registered.");
            tokens.push(Token({
            tokenType : TokenType.ERC721,
            tokenId : tokenIds[i],
            tokenAddress : tokenAddress,
            amount : 0,
            price : price,
            isWhitelisted : isWhitelisted,
            maxPurchase : maxPurchase,
            purchased : 0,
            startTime : startTime,
            endTime : endTime,
            round : round
            }));
            emit TokenAdded(tokenIds[i], tokenAddress, TokenType.ERC721, price, isWhitelisted, maxPurchase, startTime, endTime);
        }
    }

    function updateTokenERC721(uint256 index, uint8 round, uint256 price, bool isWhitelisted, uint256 maxPurchase, uint256 startTime, uint256 endTime) external onlyOwner {
        require(index < tokens.length, "Index out of range");
        Token storage token = tokens[index];
        require(token.tokenType == TokenType.ERC721, "Token must be of type ERC721");
        token.price = price;
        token.isWhitelisted = isWhitelisted;
        token.maxPurchase = maxPurchase;
        token.startTime = startTime;
        token.endTime = endTime;
        token.round = round;

        emit TokenAdded(token.tokenId, token.tokenAddress, TokenType.ERC721, price, isWhitelisted, maxPurchase, startTime, endTime);
    }

    function addTokenERC1155(uint256 tokenId, address tokenAddress, uint8 round, uint256 amount, uint256 price, bool isWhitelisted, uint256 maxPurchase, uint256 startTime, uint256 endTime) external onlyOwner {
        require(IERC1155(tokenAddress).balanceOf(address(this), tokenId) >= amount, "Token must be deposited to the contract");
        require(!isTokenIndex(tokenAddress, tokenId), "Token already registered.");
        tokens.push(Token({
        tokenType : TokenType.ERC1155,
        tokenId : tokenId,
        tokenAddress : tokenAddress,
        amount : amount,
        price : price,
        isWhitelisted : isWhitelisted,
        maxPurchase : maxPurchase,
        purchased : 0,
        startTime : startTime,
        endTime : endTime,
        round : round
        }));
        emit TokenAdded(tokenId, tokenAddress, TokenType.ERC1155, price, isWhitelisted, maxPurchase, startTime, endTime);
    }

    function addTokensERC1155(uint256[] memory tokenIds, address tokenAddress, uint8 round, uint256 amount, uint256 price, bool isWhitelisted, uint256 maxPurchase, uint256 startTime, uint256 endTime) external onlyOwner {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(IERC1155(tokenAddress).balanceOf(address(this), tokenIds[i]) >= amount, "Token must be deposited to the contract");
            require(!isTokenIndex(tokenAddress, tokenIds[i]), "Token already registered.");
            tokens.push(Token({
            tokenType : TokenType.ERC1155,
            tokenId : tokenIds[i],
            tokenAddress : tokenAddress,
            amount : amount,
            price : price,
            isWhitelisted : isWhitelisted,
            maxPurchase : maxPurchase,
            purchased : 0,
            startTime : startTime,
            endTime : endTime,
            round : round
            }));
            emit TokenAdded(tokenIds[i], tokenAddress, TokenType.ERC1155, price, isWhitelisted, maxPurchase, startTime, endTime);
        }
    }

    function updateTokenERC1155(uint256 index, uint8 round, uint256 price, bool isWhitelisted, uint256 maxPurchase, uint256 startTime, uint256 endTime) external onlyOwner {
        require(index < tokens.length, "Index out of range");
        Token storage token = tokens[index];
        require(token.tokenType == TokenType.ERC1155, "Token must be of type ERC1155");
        token.price = price;
        token.isWhitelisted = isWhitelisted;
        token.maxPurchase = maxPurchase;
        token.startTime = startTime;
        token.endTime = endTime;
        token.round = round;

        emit TokenAdded(token.tokenId, token.tokenAddress, TokenType.ERC1155, price, isWhitelisted, maxPurchase, startTime, endTime);
    }

    function getTokenInfo(address tokenAddress, uint256 tokenId, uint8 round) external view returns (uint256, TokenType, uint256, uint256, uint256, bool, uint256, uint256, uint256, bool) {
        uint256 index = getTokenIndex(tokenAddress, tokenId, round);
        Token storage token = tokens[index];
        if (token.tokenType == TokenType.ERC721) {
            return (index, TokenType.ERC721, token.price, token.purchased, token.maxPurchase, token.isWhitelisted, token.startTime, token.endTime, 0, token.purchased > 0);
        }
        if (token.tokenType == TokenType.ERC1155) {
            return (index, TokenType.ERC1155, token.price, token.purchased, token.maxPurchase, token.isWhitelisted, token.startTime, token.endTime, token.amount, token.purchased > 0);
        }
        revert("Token not found");
    }

    function isTokenIndex(address tokenAddress, uint256 tokenId) public view returns (bool) {
        for (uint i = 0; i < tokens.length; i++) {
            Token storage token = tokens[i];
            if (token.tokenAddress == tokenAddress && token.tokenId == tokenId) {
                return true;
            }
        }
        return false;
    }

    function getTokenIndex(address tokenAddress, uint256 tokenId, uint8 round) internal view returns (uint256) {
        for (uint256 i = 0; i < tokens.length; i++) {
            Token storage token = tokens[i];
            if (token.tokenAddress == tokenAddress && token.tokenId == tokenId && token.round == round) {
                return i;
            }
        }
        revert("Token not found");
    }

    function getTokenIndex(address tokenAddress, uint256 tokenId) internal view returns (uint256) {
        for (uint256 i = 0; i < tokens.length; i++) {
            Token storage token = tokens[i];
            if (token.tokenAddress == tokenAddress && token.tokenId == tokenId) {
                return i;
            }
        }
        revert("Token not found");
    }

    function getTokenIds(address tokenAddress, uint8 round) external view returns (uint256[] memory, bool[] memory) {
        uint256 count;
        for (uint256 i = 0; i < tokens.length; i++) {
            Token storage token = tokens[i];
            if (token.tokenAddress == tokenAddress && token.round == round) {
                count++;
            }
        }
        uint256[] memory tokenIds = new uint256[](count);
        bool[] memory purchased = new bool[](count);
        uint256 index;
        for (uint256 i = 0; i < tokens.length; i++) {
            Token storage token = tokens[i];
            if (token.tokenAddress == tokenAddress && token.round == round) {
                tokenIds[index] = token.tokenId;
                purchased[index] = (token.purchased > 0);
                index++;
            }
        }
        return (tokenIds, purchased);
    }

    function removeToken(uint256 index) external onlyOwner {
        require(index < tokens.length, "Index out of range");
        Token storage token = tokens[index];
        require(token.purchased == 0, "Token has been purchased");
        if (token.tokenType == TokenType.ERC721) {
            IERC721(token.tokenAddress).transferFrom(address(this), owner(), token.tokenId);
        } else {
            IERC1155(token.tokenAddress).safeTransferFrom(address(this), owner(), token.tokenId, token.amount, "");
        }

        emit TokenRemoved(token.tokenId, token.tokenAddress, token.tokenType);

        // Remove token from array by swapping with the last token and then reducing the length
        tokens[index] = tokens[tokens.length - 1];
        tokens.pop();
    }

    function buyToken(uint256 index, uint256 amount) external payable {
        require(index < tokens.length, "Index out of range");
        Token storage token = tokens[index];
        require(token.tokenType == TokenType.ERC1155 || amount == 1, "Can only purchase one token for ERC721");

        if (token.isWhitelisted) {
            require(canPurchase(token.tokenAddress, token.round, msg.sender, amount), "Cannot purchase");
        }

        require(token.purchased + amount <= token.maxPurchase, "Exceeds maximum purchase amount");
        require(block.timestamp >= token.startTime, "Sale has not started yet");
        require(block.timestamp < token.endTime, "Sale has ended");
        require(msg.value == token.price * amount, "Incorrect value sent");

        token.purchased += amount;

        if (token.tokenType == TokenType.ERC721) {
            IERC721(token.tokenAddress).transferFrom(address(this), msg.sender, token.tokenId);
        } else {
            IERC1155(token.tokenAddress).safeTransferFrom(address(this), msg.sender, token.tokenId, amount, "");
        }

        if (token.isWhitelisted) {
            Purchase storage purchase = whitelist[token.tokenAddress][token.round][msg.sender];
            require(purchase.quantity >= amount, "Cannot purchase more than the allowed quantity");
            purchase.hasPurchased = true;
            purchase.quantity -= amount;
        }

        emit TokenPurchased(token.tokenId, token.tokenAddress, token.tokenType, msg.sender, amount, token.price);
    }

    function buyToken(address tokenAddress, uint256 tokenId, uint256 amount) external payable {
        uint256 index = getTokenIndex(tokenAddress, tokenId);
        Token storage token = tokens[index];
        require(token.tokenType == TokenType.ERC1155 || amount == 1, "Can only purchase one token for ERC721");

        if (token.isWhitelisted) {
            require(canPurchase(token.tokenAddress, token.round, msg.sender, amount), "Cannot purchase");
        }

        require(token.purchased + amount <= token.maxPurchase, "Exceeds maximum purchase amount");
        require(block.timestamp >= token.startTime, "Sale has not started yet");
        require(block.timestamp < token.endTime, "Sale has ended");
        require(msg.value == token.price * amount, "Incorrect value sent");

        token.purchased += amount;

        if (token.tokenType == TokenType.ERC721) {
            IERC721(token.tokenAddress).transferFrom(address(this), msg.sender, token.tokenId);
        } else {
            IERC1155(token.tokenAddress).safeTransferFrom(address(this), msg.sender, token.tokenId, amount, "");
        }

        if (token.isWhitelisted) {
            Purchase storage purchase = whitelist[token.tokenAddress][token.round][msg.sender];
            require(purchase.quantity >= amount, "Cannot purchase more than the allowed quantity");
            purchase.hasPurchased = true;
            purchase.quantity -= amount;
        }

        emit TokenPurchased(token.tokenId, token.tokenAddress, token.tokenType, msg.sender, amount, token.price);
    }

    function buyTokens(address tokenAddress, uint256[] memory tokenIds, uint256[] memory amounts) external payable {
        uint256 totalPrice;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 index = getTokenIndex(tokenAddress, tokenIds[i]);
            Token storage token = tokens[index];
            require(token.tokenType == TokenType.ERC1155 || amounts[i] == 1, "Can only purchase one token for ERC721");

            if (token.isWhitelisted) {
                require(canPurchase(token.tokenAddress, token.round, msg.sender, amounts[i]), "Cannot purchase");
            }

            require(token.purchased + amounts[i] <= token.maxPurchase, "Exceeds maximum purchase amount");
            require(block.timestamp >= token.startTime, "Sale has not started yet");
            require(block.timestamp < token.endTime, "Sale has ended");

            totalPrice += token.price * amounts[i];
            token.purchased += amounts[i];

            if (token.tokenType == TokenType.ERC721) {
                IERC721(token.tokenAddress).transferFrom(address(this), msg.sender, token.tokenId);
            } else {
                IERC1155(token.tokenAddress).safeTransferFrom(address(this), msg.sender, token.tokenId, amounts[i], "");
            }

            if (token.isWhitelisted) {
                Purchase storage purchase = whitelist[token.tokenAddress][token.round][msg.sender];
                require(purchase.quantity >= amounts[i], "Cannot purchase more than the allowed quantity");
                purchase.hasPurchased = true;
                purchase.quantity -= amounts[i];
            }

            emit TokenPurchased(token.tokenId, token.tokenAddress, token.tokenType, msg.sender, amounts[i], token.price);
        }
        require(msg.value == totalPrice, "Incorrect value sent");
    }

    function getRandomTokenId(address tokenAddress, uint8 round) public view returns (uint256) {
        uint256[] memory availableTokenIds = new uint256[](tokens.length);
        uint256 numAvailableTokens = 0;
        for (uint256 i = 0; i < tokens.length; i++) {
            Token storage token = tokens[i];
            if (token.tokenAddress == tokenAddress && token.round == round && token.purchased == 0) {
                availableTokenIds[numAvailableTokens] = token.tokenId;
                numAvailableTokens++;
            }
        }
        require(numAvailableTokens > 0, "No available tokens to purchase");
        uint256 randomIndex = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender))) % numAvailableTokens;
        return availableTokenIds[randomIndex];
    }

    function buyRandomTokens(address tokenAddress, uint8 round, uint8 qty, uint256[] memory amounts) external payable {
        uint256 totalPrice;
        for (uint256 i = 0; i < qty; i++) {
            uint256 index = getTokenIndex(tokenAddress, getRandomTokenId(tokenAddress, round));
            Token storage token = tokens[index];
            require(token.tokenType == TokenType.ERC1155 || amounts[i] == 1, "Can only purchase one token for ERC721");

            if (token.isWhitelisted) {
                require(canPurchase(token.tokenAddress, token.round, msg.sender, amounts[i]), "Cannot purchase");
            }

            require(token.purchased + amounts[i] <= token.maxPurchase, "Exceeds maximum purchase amount");
            require(block.timestamp >= token.startTime, "Sale has not started yet");
            require(block.timestamp < token.endTime, "Sale has ended");

            totalPrice += token.price * amounts[i];
            token.purchased += amounts[i];

            if (token.tokenType == TokenType.ERC721) {
                IERC721(token.tokenAddress).transferFrom(address(this), msg.sender, token.tokenId);
            } else {
                IERC1155(token.tokenAddress).safeTransferFrom(address(this), msg.sender, token.tokenId, amounts[i], "");
            }

            if (token.isWhitelisted) {
                Purchase storage purchase = whitelist[token.tokenAddress][token.round][msg.sender];
                require(purchase.quantity >= amounts[i], "Cannot purchase more than the allowed quantity");
                purchase.hasPurchased = true;
                purchase.quantity -= amounts[i];
            }

            emit TokenPurchased(token.tokenId, token.tokenAddress, token.tokenType, msg.sender, amounts[i], token.price);
        }
        require(msg.value >= totalPrice, "Incorrect value sent");
    }

    function transferToken(address tokenAddress, uint256[] memory tokenIds, uint256[] memory amounts, address to) external onlyOwner {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 index = getTokenIndex(tokenAddress, tokenIds[i]);
            Token storage token = tokens[index];
            require(token.purchased == 0, "Token has been purchased");
            if (token.tokenType == TokenType.ERC721) {
                IERC721(token.tokenAddress).transferFrom(address(this), to, token.tokenId);
            } else {
                IERC1155(token.tokenAddress).safeTransferFrom(address(this), to, token.tokenId, token.amount, "");
            }

            emit TokenRemoved(token.tokenId, token.tokenAddress, token.tokenType);

            // Remove token from array by swapping with the last token and then reducing the length
            tokens[index] = tokens[tokens.length - 1];
            tokens.pop();
        }
    }

    function withdrawFunds() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function getTokenCount() external view returns (uint256) {
        return tokens.length;
    }

    function getTotalTokenCount(address tokenAddress) external view returns (uint256) {
        uint256 count;
        for (uint256 i = 0; i < tokens.length; i++) {
            Token storage token = tokens[i];
            if (token.tokenAddress == tokenAddress) {
                count++;
            }
        }
        return count;
    }

    function onERC1155Received(
        address, // operator
        address, // from
        uint256, // id
        uint256, // value
        bytes calldata // data
    ) external pure override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address, // operator
        address, // from
        uint256[] calldata, // ids
        uint256[] calldata, // values
        bytes calldata // data
    ) external pure override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function supportsInterface(bytes4 interfaceId) external view override returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || interfaceId == type(IERC721Receiver).interfaceId;
    }
}