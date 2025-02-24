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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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

// SPDX-License-Identifier: MIT
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Base64.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides a set of functions to operate with Base64 strings.
 *
 * _Available since v4.5._
 */
library Base64 {
    /**
     * @dev Base64 Encoding/Decoding Table
     */
    string internal constant _TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /**
     * @dev Converts a `bytes` to its Bytes64 `string` representation.
     */
    function encode(bytes memory data) internal pure returns (string memory) {
        /**
         * Inspired by Brecht Devos (Brechtpd) implementation - MIT licence
         * https://github.com/Brechtpd/base64/blob/e78d9fd951e7b0977ddca77d92dc85183770daf4/base64.sol
         */
        if (data.length == 0) return "";

        // Loads the table into memory
        string memory table = _TABLE;

        // Encoding takes 3 bytes chunks of binary data from `bytes` data parameter
        // and split into 4 numbers of 6 bits.
        // The final Base64 length should be `bytes` data length multiplied by 4/3 rounded up
        // - `data.length + 2`  -> Round up
        // - `/ 3`              -> Number of 3-bytes chunks
        // - `4 *`              -> 4 characters for each chunk
        string memory result = new string(4 * ((data.length + 2) / 3));

        /// @solidity memory-safe-assembly
        assembly {
            // Prepare the lookup table (skip the first "length" byte)
            let tablePtr := add(table, 1)

            // Prepare result pointer, jump over length
            let resultPtr := add(result, 32)

            // Run over the input, 3 bytes at a time
            for {
                let dataPtr := data
                let endPtr := add(data, mload(data))
            } lt(dataPtr, endPtr) {

            } {
                // Advance 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // To write each character, shift the 3 bytes (18 bits) chunk
                // 4 times in blocks of 6 bits for each character (18, 12, 6, 0)
                // and apply logical AND with 0x3F which is the number of
                // the previous character in the ASCII table prior to the Base64 Table
                // The result is then added to the table to get the character to write,
                // and finally write it in the result pointer but with a left shift
                // of 256 (1 byte) - 8 (1 ASCII char) = 248 bits

                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance
            }

            // When data `bytes` is not exactly 3 bytes long
            // it is padded with `=` characters at the end
            switch mod(mload(data), 3)
            case 1 {
                mstore8(sub(resultPtr, 1), 0x3d)
                mstore8(sub(resultPtr, 2), 0x3d)
            }
            case 2 {
                mstore8(sub(resultPtr, 1), 0x3d)
            }
        }

        return result;
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
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
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
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
            return toHexString(value, Math.log256(value) + 1);
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
pragma solidity ^0.8.17;
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "./EIP712Allowlisting.sol";
import "./Phaseable.sol";
import "./FlexibleMetadata.sol";
import "./Nameable.sol";
import "./LockableTransferrable.sol";
import { Phase, PhaseNotActiveYet, PhaseExhausted, WalletMintsFilled } from "./SetPhaseable.sol";

abstract contract Allowable is EIP712Allowlisting, DefaultOperatorFilterer {  
    address constant defaultPayable = 0x5aE09f46967A92f3cF976e98f82B6FDd00784815;
    address payable internal TREASURY = payable(defaultPayable);
    uint256 PRIVATE = 0;
    uint256 ALLOWED = 1;
    uint256 OPEN = 2; 
    
    constructor(string memory name, string memory symbol) FlexibleMetadata(name,symbol) {
        setSigningAddress(msg.sender);
        setDomainSeparator(name, symbol);
        initializePhases();
    }

    function initializePhases() internal virtual;

    function canMint(uint256 phase, uint256 quantity) internal override virtual returns(bool) {
        uint256 activePhase = activePhase();
        if (phase > activePhase) {
            revert PhaseNotActiveYet();
        }
        uint256 requestedSupply = minted()+quantity;
        Phase memory requestedPhase = findPhase(phase);
        if (requestedSupply > requestedPhase.highestSupply) {
            revert PhaseExhausted();
        }
        uint16[4] memory aux = retrieveMintQuantities(msg.sender);
        uint256 requestedMints = quantity + aux[phase];

        if (requestedMints > requestedPhase.maxPerWallet) {
            revert WalletMintsFilled(requestedMints);
        }
        return true;
    }

    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        LockableTransferrable.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public override onlyAllowedOperatorApproval(operator) {
        LockableTransferrable.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        LockableTransferrable.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        LockableTransferrable.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override
        onlyAllowedOperator(from)
    {
        LockableTransferrable.safeTransferFrom(from, to, tokenId, data);
    }    
}

/**
 * Ordo Signum Machina - 2023
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./Ownable.sol";
import "./Nameable.sol";
import { TokenNonOwner } from "./SetOwnerEnumerable.sol";
import { OwnerEnumerable } from "./OwnerEnumerable.sol";
import { SetApprovable, ApprovableData, TokenNonExistent } from "./SetApprovable.sol";

abstract contract Approvable is OwnerEnumerable {  
    using SetApprovable for ApprovableData; 
    ApprovableData approvable;
    uint256 tokenCount;

    function _checkTokenOwner(uint256 tokenId) internal view virtual {
        if (ownerOf(tokenId) != msg.sender) {
            revert TokenNonOwner(msg.sender, tokenId);
        }
    }    
 
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return approvable.isApprovedForAll(owner,operator);
    }  

    function approve(address to, uint256 tokenId) public virtual override {  
        _checkTokenOwner(tokenId);      
        approvable.approveForToken(to, tokenId);
        emit Approval(ownerOf(tokenId), to, tokenId);        
    }  

    function setApprovalForAll(address operator, bool approved) public virtual override {   
        approved ? approvable.approveForContract(operator): approvable.revokeApprovalForContract(operator, msg.sender);
    }       

    function validateApprovedOrOwner(address spender, uint256 tokenId) internal view {        
        if (!(spender == ownerOf(tokenId) || isApprovedForAll(ownerOf(tokenId), spender) || approvable.getApproved(tokenId) == spender)) {
            revert TokenNonOwner(spender, tokenId);
        }
    }  

    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        requireMinted(tokenId);
        return approvable.tokens[tokenId].approval;
    }       

    function revokeTokenApproval(uint256 tokenId) internal {
        approvable.revokeTokenApproval(tokenId);
    }

    function revokeApprovals(address holder) internal {
        approvable.revokeApprovals(holder,tokensOwnedBy(holder));                    
    }

    function requireMinted(uint256 tokenId) internal view virtual {
        if (tokenId <= tokenCount) {
            revert TokenNonExistent(tokenId);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import { SetAssignable, AssignableData, NotTokenOwner, NotAssigned } from "./SetAssignable.sol";
import { OwnerEnumerable } from "./OwnerEnumerable.sol";
import "./Phaseable.sol";


abstract contract Assignable is Phaseable {  
    using SetAssignable for AssignableData;
    AssignableData assignables;
    
    function assignColdStorage(uint256 tokenId) public {        
        if (msg.sender != ownerOf(tokenId)) {
            revert NotTokenOwner();
        }
        assignables.addAssignment(msg.sender,tokenId);
    }
    
    function revokeColdStorage(uint256 tokenId) public {        
        if (assignables.findAssignment(msg.sender) != tokenId) {
            revert NotAssigned(msg.sender);
        }
        assignables.removeAssignment(msg.sender);
    }   
    
    function revokeAssignments(uint256 tokenId) public {        
        if (msg.sender != ownerOf(tokenId)) {
            revert NotTokenOwner();
        }
        assignables.revokeAll(tokenId);
    }    
    
    function findAssignments(uint256 tokenId) public view returns (address[] memory){        
        return assignables.findAssignees(tokenId);
    }        

    function balanceOf(address seekingContract, address owner) external view returns (uint256) {        
        uint256 guardianBalance = balanceOf(owner);
        if (guardianBalance > 0) {
            uint256[] memory guardians = tokensOwnedBy(owner);
            return assignables.iterateGuardiansBalance(guardians, seekingContract, 0);
        }
        return 0;
    }     
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./EIP712Listable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

bytes32 constant ALLOW_MINT_TYPE =
    keccak256("Minter(address wallet)");

bytes32 constant BAG_MINT_TYPE =
    keccak256("Minter(string genesisBagAddress)");

bytes32 constant FREE_MINT_TYPE =
    keccak256("Minter(string genesisStakedAddress)");    


abstract contract EIP712Allowlisting is EIP712Listable {
    using ECDSA for bytes32;
    using Strings for uint256;
    using Strings for uint160;
    using Strings for address;

    struct recovered { 
        address receipient;
        bytes signature;
        address recovered;
        address signingKey;
    }

    uint256[] empty;

    function recoverAllowAddress(bytes calldata sig, address recip) public view returns (recovered memory) {
        // bytes32 digest = keccak256(
        //     abi.encodePacked(
        //         "\x19\x01",
        //         DOM_SEP,
        //         keccak256(abi.encode(ALLOW_MINT_TYPE, recip))
        //     )
        // );      
        bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(ALLOW_MINT_TYPE, recip)));          
        address recoveredAddress = digest.recover(sig);
        
        return recovered(recip, sig, recoveredAddress, sigKey);
    }
    modifier requiresAllowSig(bytes calldata sig, address recip) {
        require(sigKey != address(0), "allowlist not enabled");
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOM_SEP,
                keccak256(abi.encode(ALLOW_MINT_TYPE, recip))
            )
        );
        address recovery = digest.recover(sig);
        require(recovery == sigKey, "invalid signature");
        require(msg.sender == recip, "invalid signature");
        _;
    }
    struct recoveredBag { 
        address receipient;
        bytes signature;
        address recovered;
        address signingKey;
        string bagging;
        uint256 total;
    }    
    
    function recoverClaimSig(bytes calldata sig, address recip, uint256[] memory bag) public view returns (recoveredBag memory) {        
        return recoverClaimSig(sig, recip, bag, empty);            
    }

    function recoverClaimSig(bytes calldata sig, address recip, uint256[] memory bag, uint256[] memory staked) public view returns (recoveredBag memory) {
        require(sigKey != address(0), "allowlist not enabled");
        uint total = uint(uint160(recip));
        for (uint i; i < bag.length; i++) {
            total += bag[i];
        }
        for (uint i; i < staked.length; i++) {
            total += staked[i];
        }        
        string memory bagged = total.toString();
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOM_SEP,
                keccak256(abi.encode(FREE_MINT_TYPE,keccak256(abi.encodePacked(bagged))))
            )
        );
        address recovery = digest.recover(sig);
        return recoveredBag(recip, sig, recovery, sigKey, bagged, total);               
    }
    modifier requiresBagSig(bytes calldata sig, address recip, uint256[] memory bag) {
        require(sigKey != address(0), "allowlist not enabled");
        uint total = uint(uint160(recip));
        for (uint i; i < bag.length; i++) {
            total += bag[i];
        }
        string memory bagged = total.toString();
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOM_SEP,
                keccak256(abi.encode(FREE_MINT_TYPE,keccak256(abi.encodePacked(bagged))))
            )
        );
        address recovery = digest.recover(sig);
        require(recovery == sigKey, "invalid signature");
        require(msg.sender == recip, "invalid signature");
        _;
    }        
    modifier requiresClaimSig(bytes calldata sig, address recip, uint256[] memory bag, uint256[] memory staked) {
        require(sigKey != address(0), "allowlist not enabled");
        uint total = uint(uint160(recip));
        for (uint i; i < bag.length; i++) {
            total += bag[i];
        }
        for (uint i; i < staked.length; i++) {
            total += staked[i];
        }        
        string memory bagged = total.toString();
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOM_SEP,
                keccak256(abi.encode(FREE_MINT_TYPE,keccak256(abi.encodePacked(bagged))))
            )
        );
        address recovery = digest.recover(sig);
        require(recovery == sigKey, "invalid signature");
        require(msg.sender == recip, "invalid signature");
        _;
    }    
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "./Assignable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

abstract contract EIP712Listable is Assignable {
    using ECDSA for bytes32;

    address internal sigKey = address(0);

    bytes32 internal DOM_SEP;    

    uint256 chainid = 420;

    function setDomainSeparator(string memory _name, string memory _version) internal {
        DOM_SEP = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes(_name)),
                keccak256(bytes(_version)),
                chainid,
                address(this)
            )
        );
    }

    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSA.toTypedDataHash(DOM_SEP, structHash);
    }    

    function getSigningAddress() public view returns (address) {
        return sigKey;
    }

    function setSigningAddress(address _sigKey) public onlyOwner {
        sigKey = _sigKey;
    }

    function isOwner() public view returns (bool) {
        return msg.sender == owner();
    }
  
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "./Ownable.sol";
import "./Nameable.sol";
import { DEFAULT, FLAG, PRE, Supplement, SetFlexibleMetadata, FlexibleMetadataData } from "./SetFlexibleMetadata.sol";

abstract contract FlexibleMetadata is Ownable, Context, ERC165, IERC721, Nameable {  
    using SetFlexibleMetadata for FlexibleMetadataData;
    FlexibleMetadataData flexible;   

    constructor(string memory _name, string memory _symbol) Nameable(_name,_symbol) {
    }   
    
    function setContractUri(string memory uri) external onlyOwner {
        flexible.setContractMetadataURI(uri);
    }

    function reveal(bool _reveal) external onlyOwner {
        flexible.reveal(_reveal);
    }

    function setTokenUri(string memory uri, uint256 tokenType) public onlyOwner {
        tokenType == FLAG ?
            flexible.setFlaggedTokenMetadataURI(uri):
            (tokenType == PRE) ?
                flexible.setPrerevealTokenMetadataURI(uri):
                    flexible.setDefaultTokenMetadataURI(uri);
    }

    function setSupplementalTokenUri(string memory key, string memory uri) external onlyOwner {
        flexible.setSupplementalTokenMetadataURI(key,uri);
    }

    function flagToken(uint256 tokenId, bool isFlagged) external onlyOwner {
        flexible.flagToken(tokenId,isFlagged);
    }

    function setSupplemental(uint256 tokenId, bool isSupplemental, string memory key) internal {
        if (isSupplemental) {
            flexible.supplemental[tokenId] = Supplement(key,true);
        } else {
            delete flexible.supplemental[tokenId];
        }
    }    

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165,IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }   

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {        
        return flexible.getTokenMetadata(tokenId);
    }          
    function contractURI() external view virtual returns (string memory) {
        return flexible.getContractMetadata();
    }    
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "./Approvable.sol";
import { SetLockable, LockableStatus,  LockableData, WalletLockedByOwner } from "./SetLockable.sol";

abstract contract Lockable is Approvable {    
    using SetLockable for LockableData; 
    LockableData lockable;

    bool soulBound = false;

    function custodianOf(uint256 id)
        public
        view
        returns (address)
    {             
        return lockable.findCustodian(ownerOf(id));
    }     

    function lockWallet(uint256 id) public {           
        revokeApprovals(ownerOf(id));
        lockable.lockWallet(ownerOf(id));
    }

    function unlockWallet(uint256 id) public {              
        lockable.unlockWallet(ownerOf(id));
    }    

    function _forceUnlock(uint256 id) internal {  
        lockable.forceUnlock(ownerOf(id));
    }    

    function setCustodian(uint256 id, address custodianAddress) public {       
        lockable.setCustodian(custodianAddress,ownerOf(id));
    }


    function isLocked(uint256 id) public view returns (bool) {  
        if (enumerationExists(id)) {
            return lockable.lockableStatus[ownerOf(id)].isLocked || soulBound;
        }
        return soulBound;
    } 

    function lockedSince(uint256 id) public view returns (uint256) {     
        return lockable.lockableStatus[ownerOf(id)].lockedAt;
    }     

    function validateLock(uint256 tokenId) internal view {
        if (isLocked(tokenId)) {
            revert WalletLockedByOwner();
        }
    }

    function soulBind() internal {
        soulBound = true;
    }
    
    function releaseSoul() internal {
        soulBound = false;
    }    
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./Lockable.sol";
import { LockableStatus,InvalidTransferRecipient,TokenIsSoulBound,ContractIsNot721Receiver } from "./SetLockable.sol";

abstract contract LockableTransferrable is Lockable {  
    using Address for address;

    function approve(address to, uint256 tokenId) public virtual override {  
        validateLock(tokenId);
        super.approve(to,tokenId);      
    }  

    function setApprovalForAll(address operator, bool approved) public virtual override {
        if (tokensOwnedBy(msg.sender).length > 0) {
            validateLock(tokensOwnedBy(msg.sender)[0]);
        } else if (soulBound) {
            revert TokenIsSoulBound();
        }
        super.setApprovalForAll(operator,approved);     
    }        

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {        
        validateApprovedOrOwner(msg.sender, tokenId);
        // if (soulBound) revert TokenIsSoulBound();
        validateLock(tokenId);
        _transfer(from,to,tokenId);
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal {
                
        if(to == address(0)) {
            revert InvalidTransferRecipient();
        }

        revokeTokenApproval(tokenId);   

        if (enumerationExists(tokenId)) {
            swapOwner(from,to,tokenId);
        }
        
        packedTransferFrom(from, to, tokenId);

        completeTransfer(from,to,tokenId);    
    }   

    function completeTransfer(
        address from,
        address to,
        uint256 tokenId) internal {

        emit Transfer(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }    

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        validateApprovedOrOwner(msg.sender, tokenId);
        validateLock(tokenId);
        _safeTransfer(from, to, tokenId, data);
    }     

    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        if (!_checkOnERC721Received(from, to, tokenId, data)) {
            revert ContractIsNot721Receiver();
        }        
        _transfer(from, to, tokenId);
    }

    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert InvalidTransferRecipient();
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }    

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "./LockableTransferrable.sol";
import { SetMintable, MintableData } from "./SetMintable.sol";
import { TokenOwnership } from "./SetOwnerEnumerable.sol";
error InvalidRecipient(address zero);
error TokenAlreadyMinted(uint256 tokenId);
error InvalidToken(uint256 tokenId);
error MintIsNotLive();

abstract contract Mintable is LockableTransferrable {  
    using SetMintable for MintableData;
    MintableData mintables;  

    mapping(address => mapping(uint256 => bool)) claimed; 

    bool isLive;

    function setMintLive(bool _isLive) public onlyOwner {
        isLive = _isLive;
    }

    function hasBeenClaimed(uint256 tokenId, address addressed) public view returns (bool) {
        return claimed[addressed][tokenId];
    }

    function claim(uint256 tokenId, address addressed) internal {
        claimed[addressed][tokenId] = true;
    }

    function getSenderMints() internal view returns (uint256) {
        return numberMinted(msg.sender);
    }

    function _mint(address to, uint256 quantity, bool enumerate) internal virtual returns (uint256) {
        if (!isLive) {
            revert MintIsNotLive();
        }
        if (to == address(0)) {
            revert InvalidRecipient(to);
        }
        
        return enumerate ? enumerateMint(to, quantity) : packedMint(to, quantity);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import { SetNameable, NameableData } from "./SetNameable.sol";

abstract contract Nameable is IERC721Metadata {   
    using SetNameable for NameableData;      
    NameableData nameable;

    constructor(string memory _name, string memory _symbol) {
        nameable.setNamed(_name, _symbol);
    }

    function name() public virtual override view returns (string memory) {
        return nameable.getName();
    }  

    function symbol() public virtual override view returns (string memory) {
        return nameable.getSymbol();
    }          
      
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

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
abstract contract Ownable {
    address private _owner;

    error CallerIsNotOwner(address caller);
    error OwnerCannotBeZeroAddress();

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(msg.sender);
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
        if (owner() != msg.sender) {
            revert CallerIsNotOwner(msg.sender);
        }
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
        if(newOwner == address(0)) {
            revert OwnerCannotBeZeroAddress();
        }
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
pragma solidity ^0.8.17;
import { SetOwnerEnumerable, OwnerEnumerableData, TokenNonOwner, InvalidOwner, TokenOwnership } from "./SetOwnerEnumerable.sol";
import { PackableOwnership } from "./PackableOwnership.sol";


abstract contract OwnerEnumerable is PackableOwnership {  
    using SetOwnerEnumerable for OwnerEnumerableData;
    OwnerEnumerableData enumerable;      



    function tokensOwnedBy(address holder) public view returns (uint256[] memory) {
        uint256[] memory empty;        
        if (enumerable.isOwnerEnumerated(holder)) {
            return enumerable.findTokensOwned(holder);
        } 
        return empty;
    }

    function enumeratedBalanceOf(address owner) public view virtual returns (uint256) {
        validateNonZeroAddress(owner);
        return enumerable.ownedTokens[owner].length;
    }   

    function validateNonZeroAddress(address owner) internal pure {
        if(owner == address(0)) {
            revert InvalidOwner();
        }
    }
    
    function enumerateToken(address to, uint256 tokenId) internal {
        enumerable.addTokenToEnumeration(to, tokenId);
    }

    function enumerateMint(address to, uint256 quantity) internal returns (uint256) {
        uint256 start = minted()+1;
        uint256 end = packedMint(to,quantity);
        for (uint256 i = start; i <= end; i++) {
            enumerateToken(to, i);
        }
        return end;
    }

    function enumerateBurn(address from, uint256 tokenId) internal {
        enumerable.addBurnToEnumeration(from, tokenId);
        enumerable.removeTokenFromEnumeration(from, tokenId);
    }

    function swapOwner(address from, address to, uint256 tokenId) internal {
        enumerable.removeTokenFromEnumeration(from, tokenId);
        enumerable.addTokenToEnumeration(to, tokenId);
    }
    
    function enumerationExists(uint256 tokenId) internal view virtual returns (bool) {
        return enumerable.tokens[tokenId].exists;
    }    

    function selfDestruct(uint256 tokenId) internal {
        delete enumerable.tokens[tokenId];
    }    
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import { FlexibleMetadata } from "./FlexibleMetadata.sol";
import { PackableData, SetPackable } from "./SetPackable.sol";


struct TokenApproval {
    address approval;
    bool exists;
}

abstract contract PackableOwnership is FlexibleMetadata {
    using SetPackable for PackableData;
    PackableData packable;

    constructor() {
        packable._currentIndex = packable._startTokenId();     
    } 
     


    function numberMinted(address minter) public view returns (uint256) {
        return packable._numberMinted(minter);
    }

    function ownerOf(uint256 tokenId) public view returns (address) {
        return packable.ownerOf(tokenId);
    }

    function balanceOf(address owner) public view virtual override returns (uint256) {
        return packable.balanceOf(owner);
    }         
       
    function totalSupply() public view virtual returns (uint256) {
        return packable.totalSupply();
    }    
       
    function minted() internal view virtual returns (uint256) {
        return packable._currentIndex;
    }
    function exists(uint256 tokenId) internal view returns (bool) {
        return packable._exists(tokenId);
    }
    function packedTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) internal {
        packable.transferFrom(from,to,tokenId);
    }
    function packedMint(address to, uint256 quantity) internal returns (uint256) {
        return packable._mint(to,quantity);
    }
    function packedBurn(uint256 tokenId) internal  {
        packable._burn(tokenId);
    }
    /**
     * Returns the auxiliary data for `owner`. (e.g. number of whitelist mint slots used).
     * returned as a uint16[4] allowing 4 distinct counts per wallet
     */
    function retrieveMintQuantities(address owner) internal view returns (uint16[4] memory) {
        return packable.getAux16(owner);
    }  
    /**
     * Stores a uint16[4] as a single aux value
     * returned as a uint16[4] allowing 4 distinct counts per wallet
     */
    function setAux32(address owner, uint16[4] memory aux) internal {
        packable._setAux(owner,packable.pack64(packable.pack32(aux[0],aux[1]),packable.pack32(aux[2],aux[3])));
    }  

    function recordMintQuantity(uint256 phase, uint256 quantity) internal {
      uint16[4] memory aux = retrieveMintQuantities(msg.sender);
      aux[phase] = uint16(quantity)+aux[phase];
      setAux32(msg.sender,aux);
    }     
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import { SetPhaseable, PhaseableData, MintIsNotAllowedRightNow, ExceedsMaxSupply, Phase } from "./SetPhaseable.sol";
import { OwnerEnumerable } from "./OwnerEnumerable.sol";
import "./Mintable.sol";


abstract contract Phaseable is Mintable {  
    using SetPhaseable for PhaseableData;
    PhaseableData phaseables;    
    
    function canMint(uint256 phase, uint256 quantity) internal virtual returns(bool);

    function initialize(Phase[] storage phases, uint256 maxSupply) internal {
        phaseables.initialize(phases,maxSupply);
    }

    function phasedMint(uint256 phase, uint256 quantity, bool enumerate) internal returns (uint256) {
        if (!canMint(phase, quantity)) {
            revert MintIsNotAllowedRightNow();
        }        
        if (minted()+quantity > phaseables.getMaxSupply()) {
            revert ExceedsMaxSupply();
        }        
        recordMintQuantity(phase, quantity);
        return _mint(msg.sender,quantity,enumerate);        
    }

    function airdrop(address recipient, uint256 quantity, bool enumerate) public virtual onlyOwner {        
        if (minted()+quantity > phaseables.getMaxSupply()) {
            revert ExceedsMaxSupply();
        }
        _mint(recipient,quantity, enumerate);
    }

    function activePhase() internal view returns (uint256) {
        return phaseables.getActivePhase();
    }

    function nextPhase() public onlyOwner {
        phaseables.startNextPhase();
    }

    function previousPhase() public onlyOwner {
        phaseables.revertPhase();
    }    

    function getPhases() internal view returns (Phase[] storage) {
        return phaseables.getPhases();
    }

    function findPhase(uint256 phaseId) internal view returns (Phase memory) {
        return phaseables.findPhase(phaseId);
    }

    function mintedInPhase(uint256 phaseId, address minter) external view returns (uint16) {
        return retrieveMintQuantities(minter)[phaseId];
    }

    function updatePhase(uint256 phaseId, Phase memory phase) internal {
        Phase[] storage existing = phaseables.getPhases();
        existing[phaseId] = phase;
    }    

    function getMaxSupply() internal view returns (uint256) {
        return phaseables.getMaxSupply();
    }  

    function setMaxSupply(uint256 newMax) internal {
        phaseables.setMaxSupply(newMax);
    }    

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
/**
                    .......................................................                         
                   .............................................................                    
                .......................''''''..'''''''...''.........................                
              ...................''''''''''''''',,,''''''''''''''.....................              
           ................'''''''''''',,,,;;,,,,,,,,,,,,,,,,,,'''''.......................         
          .............'''''''',,,,,,,,,;;;;;;;;;;;;;;;;;;;;;,,,,,,,'''''''''''............         
    ...............'''''''',,,,,,;;;;;;;;:::::::::::::::::::;;;;;,,,,;,,,,,''''''............       
 ...................''''',,,,,;;;;::::::::c::cccc::cccccccc:::::::;;;;;;;,,,,,''''.............     
...................''',,,,;;;;;;::cccccccc;'........,clllccccccccc:::::;;;,,,,,,''................  
................'''',,,;;;;;::c::ccllllll:..         .cllllllllllccc:::;;;;,,,,,,''.................
...............''',,,;;;;;:::cccclllool:'..           .;looloolllllccc:::::;;;,,,'''................
.............''',,,,;;:::::ccccllooool:'.....           .:odoooooolllccccc:::;;;,,,,'''.............
...........''',,;;;;;::cccccclllooodl:,'.......          .;odddddooolllllcccc::;;;,,,,'''...........
........'''',,,;;;::::cccllllooooddo:;,'......    .....   .:xxxddddoooloollccc::;;;;,,,,'''.........
.....''''''',,;;:::::cllloooooddddxl;,,,'.',,,,,,;::::;'.  ,dkxxxddddooooolllcc:::::;;;,,,''........
....'',,,,,,,;;::ccccclooooodddxxxxo:,;;',;:cccccccccc::;..;dkxxxxxddddoooollccccc::::;;;,,'''......
..''',,,;;;;;;::ccccclloodddddxxkxxd:,::,,;;:ccc::::;;;;;'.,cldkkxxxxxdddoolllllcccccc::;;;,,'''....
'',,;;;;;;:::::ccclllooodddxxxxkkdoo:,cl:,,,;col:;;,,',,,..'::lkkkkxxxxdddoooooollllccc:::;;,,,,,'''
cc::::::::cccccclllloodddxxxxkkkkdll:,cdolccccooc:;;:::;'..,;:okOOkkkxxxddddddoooolllccccc:::;;;;;::
XXK0OkxdoollllllloooodddxxxkkkkkOxooc,';oxdollooc;;;;cc,. .';cxOOOOOkkxxxxxxddddddooolllllloodxkO0KX
WWWWWWWNXXK0OkkxdddddoodxxxkkkOkOkddl,'cxkOOOkddolccccc:'..,lkOO0OOOOkkkxxkxdoodddxxxkkO0KXNNWWWWWWW
NNWWWWWWWWWWWWWNXXKK0OdoddxkkOOOOxc;:;;okkOOOkxdolccclcc:..,x00000OOOOkkkxxdodO0KKXNNWWWWWWWWWWWWWNN
lodxkOO00KXXNNNWWWWWWWNX0xdxxxkOOxl:;;;dkkkkkxdlccccclll:...oO0000OOOkxxxdx0XNWWWWWWWNNXXKK00Okkxdol
,;::ccllloddxk0KXNNNWNNWNOlloodxkdoc;,,:oxkkxxolcccclll:'...:k0000kxxdolllkNNNNNNNNXK0kxdoollcc:::;;
,;::ccllooddxkO0KXXNNNNNNXklc:cloodl,,:,,:ldxxdollcc:,..;,..,dOkkxollccclkXNNNNNNXXK0Oxddoollcc:::;,
OO0000KKKKKXXXXXXXNNNNWNWWNXK0kdccoc,:c,.',,,;,,''.....;l:..'ldolc::ok0KXNWWWWNNNNNXXXXXXKKKK0000OOO
oxkOO00KKKXXXXNNNNNNNWWWWWWWWWWNKko;,:c,..,,''.........:c,..':c::cxKNWWWWWWWWWWWWNNNNXXXXKKK000OOkdo
',,;::ccllooddxxkkOOKXNNNNNXXXXNXOdodo;'.':c;'.... ...,,........;ok0KXXXXNNNNNXKOkkkxxddoolcc::;;,,'
.'',;;:::clloooddxOKXNNNNNNNNWWWXkxkkx:........    ... ...........';cxKNNNNNNNNXKOkdddollcc::;;,,''.
.'',,;;;:clodxkO0KXNNWWWWWWWWNKkl;,'..........         ... ........;lkXWWWWWWWNNNXK00Oxdolc:;;,,''..
..'',:ldxO0XXNNWWNNNNXXXXKKXXKkc,.............         ..........,ldxOXXKKXXXXXXNNNNWWNXK0Okdc;,''..
..'',;:clodxxkkkkxxxxxxxkOKXXKK0x:....'''......          .;c;. .,oddxkKXX0Okkkxxxxkkkkkkxxdol:;''...
...''',,,;::ccllloooooddkO0Okk0KXKd,..,'.......           ,c:' .cdddxxkOO0Okxddoooolllccc::;;,'.....
.....'''',;;;:ccclllllodddxk0XXKXXKO:......               .;lc..cdddxk00kxxddoolllccc:::;;,,''......
........'',,,;;::cccllodxOKNWWXXKKKKk,.....              . .cl,.:ddddkKWNKOxdollcc:::;;,,,'''.......
..........'',,,;;:cccox0XNNXK0KXKKKXk,..,c:.               .,c,.:ooddxOKNNNX0xocc::;;,,'''..........
..........'''',,,;::coxkkxxdokKKKKK0x;..cOo.               .,:,.;looddxxdxkkkxl:;;;,,''''...........
...........''''',,;;:ccccclco0XKKKOxo:..,oo,               .;c'':loooddddlc:::;;;,,'''''............
  ...........'''',,;;;:::::cxKXKOxdol;..'okl.              .:c'':loooooddl:;;;;,,,,'''..............
   .............''',,,,;;;:d00Okxddoc,..'d0d.        .     .lo,':loooooodo:;;;,,,''''...............
   ................''',,,;dO0OOOOOko:'...lkd, ...,,,,,;'.  .''.':looooooooc,,''''''................ 
   ..................'',,cOKKKKK0Oxl,....:dx:.'oxdooool;.    ..';loollllool,''''''................  
    ..................'''l0KKKK00kd:'....:ddl;okc,,,,,,,,,,,,''.;lllllloooo:..................      
     ...................,dKKKK0Okdo;.....:ddkOkxdollllllccc:;,'.;clllllllodc'..............         
           .............;kK0OOkxxdl,...:xOOkOxldkdl:,,,';lllcc,',:llcccllool,............           
            ............c0KOkkkkkd:.':d0KKKK0c'dKxl'    .';cllc,',cllloooodl,.........              
              .........'dK0OOkOkxc',oOKKKKK0kllO0o;.       :ollc,.;llllloodo;......                 
                .......,kK0OOOkxo;;d0KKKKKK0dlx0Ol,.       ;oollc;';loooddddc....                   
                   ....:OK0OOxdoc;oOKKKKK0KOooxOOkxdll:;;,':ooollc,'cxxxdxddl'..                    
                     ..cKK0kddol:cx00KKKK0KOxdddxxxddxOOkxddooollc:.,dkxxxxdl.                      
 */
import "./Allowable.sol";
import "./PackableOwnership.sol";
import { SetContractMetadataRenderable, RenderableData } from "./SetContractMetadataRenderable.sol";
import { DEFAULT, FLAG, PRE } from "./SetFlexibleMetadata.sol";
error ApienAlreadyClaimed(uint256 id);
error BagAlreadyClaimed(uint256 id);
error InvalidPayment(uint256 cost, uint256 amount);
error Unphased();
error NotInTreasury(uint256 tokenId);
/// @title Apiens Generation 2: Female Apiens
/// @author @OsmOnomous https://osm.tools
contract QueenApiens is Allowable {    
    using SetContractMetadataRenderable for RenderableData;
    RenderableData renderings;
    // minting phases
    uint256 ALLOW_PHASE = 0;
    uint256 ALLOW_BAG_PHASE = 1;
    uint256 CLAIM_PHASE = 2;
    uint256 PUBLIC_PHASE = 3;
    
    // claim tracking addresses
    address GENESIS_BAG = 0xD2C83498882AfF028E18aF5FB46120342c5129bD;
    address APIENS = 0xcf8896D28B905cEfd5fFbDDD5Dbfa0eEfF8d938B;
    address GENESIS_BAG_ALLOW = address(0x0);

    // supply and allowances
    uint256 MAX_SUPPLY = 8888;

    // allowed phase
    uint256 ALLOW_PER = 5;
    uint256 ALLOW_SUPPLY = 8600;
    uint256 ALLOW_PRICE = .03 ether;
    
    // free claim phase
    uint256 FREE_PER = 3000;
    uint256 FREE_SUPPLY = 3000;
    uint256 FREE_PRICE = 0 ether;   
    
    // public phase
    uint256 PUBLIC_PER = 5;
    uint256 PUBLIC_PRICE = 0.049 ether;    

    // contract metadata
    bytes prerevealUri = "ipfs://QmTkQej4rqQrKEQd7fQrHQwYH2fRDHAo8xJPinUuJv4Lx1";
    bytes contractProfileURI = "ipfs://bafybeifrzbmi4icjrwdsypqqxlxkb27oyzlqf2372eq55t3kn7nidnmagq";
    uint256 royaltyBasis = 500;
    address feeRecipient = 0xb9d8a142F6fC69dD1B38a33eD123C895870A42e8;

    mapping(address=>bool) freeClaimed;

    /**
     * Initialization
     */
        
    /// @notice contract is initialized as soul bound, no transfers or approvals allowed
    /// @dev sales can be enabled by contract owner calling enableSecondarySales()
    /// @param name string name of contract
    /// @param symbol string symbol for contract 
    constructor(string memory name, string memory symbol) Allowable(name,symbol) {
        soulBind();
        initializePhases();        
    }    

    /// @notice initialization of minting phases
    function initializePhases() internal virtual override {
        Phase[] storage phases = getPhases();

        // Phase struct
        // name, maxPerWallet (0 indicates no limit), maxMint, price
        phases.push(Phase("allowed", ALLOW_PER, ALLOW_SUPPLY, ALLOW_PRICE));
        phases.push(Phase("allowedBags", FREE_PER, ALLOW_SUPPLY, ALLOW_PRICE));
        phases.push(Phase("claim", FREE_PER, FREE_SUPPLY, FREE_PRICE));
        phases.push(Phase("public", PUBLIC_PER, MAX_SUPPLY, PUBLIC_PRICE));
        
        initialize(phases,MAX_SUPPLY);        
    }
    
    /**
     * Metadata
     */
    function contractURI() external view virtual override returns (string memory) {   
        return renderings.encodedContractURI(contractProfileURI, royaltyBasis, feeRecipient);
    }   

    /**
     * Minting & Burning
     */    

    /// @notice minting CLAIM_PHASE, requires trusted signature, staked Apien and Genesis Bag
    /// @param stakedApiens uint256[] ids of staked Apien
    /// @param genesisBags uint256[] ids of Genesis Bag
    /// @param signature bytes trusted signature 
    function freeClaimMint(uint256[] memory stakedApiens, uint256[] memory genesisBags, bytes calldata signature) 
    external requiresClaimSig(signature,msg.sender,genesisBags,stakedApiens) {    
        if (freeClaimed[msg.sender]) revert ApienAlreadyClaimed(0);
        for (uint i = 0; i < genesisBags.length; i++) {
            if (hasBeenClaimed(genesisBags[i], GENESIS_BAG)) {
                revert BagAlreadyClaimed(genesisBags[i]);
            }
            
            claim(genesisBags[i], GENESIS_BAG);
        }
        for (uint i; i < stakedApiens.length; i++) {
            if (hasBeenClaimed(stakedApiens[i], APIENS)) {
                revert ApienAlreadyClaimed(stakedApiens[i]);
            }
            
            claim(stakedApiens[i], APIENS);
        }
        phasedMint(CLAIM_PHASE, stakedApiens.length, false);        
    } 

    /// @notice minting ALLOW_PHASE, requires trusted signature and GenesisBag
    /// @param genesisBags uint256[] ids of Genesis Bags
    /// @param signature bytes trusted signature 
    function bagAllowMint(uint256[] memory genesisBags, bytes calldata signature) 
    external payable requiresBagSig(signature,msg.sender,genesisBags) { 
        for (uint i = 0; i < genesisBags.length; i++) {
            if (hasBeenClaimed(genesisBags[i], GENESIS_BAG)) {
                revert BagAlreadyClaimed(genesisBags[i]);
            }
            
            claim(genesisBags[i], GENESIS_BAG);
        }
        Phase memory phased = findPhase(ALLOW_BAG_PHASE);     
        isValidPayment(phased.cost, genesisBags.length);

        phasedMint(ALLOW_BAG_PHASE, genesisBags.length, false);        
        
        // we do not want to track bag claims as consuming an allowlist spot
        // setAux(msg.sender, getAux(msg.sender)+uint64(genesisBags.length));
    }     

    /// @notice minting ALLOW_PHASE, requires trusted signature, maximum quantity 5 per wallet
    /// @param quantity uint64 number to mint
    /// @param signature bytes trusted signature 
    function allowlistMint(uint64 quantity, bytes calldata signature) 
    external payable requiresAllowSig(signature,msg.sender) {  
        
        Phase memory phased = findPhase(ALLOW_PHASE); 

        isValidPayment(phased.cost, quantity);

        phasedMint(ALLOW_PHASE, quantity, false);       
    }

    /// @notice minting PUBLIC_PHASE, maximum quantity 5 per wallet
    /// @param quantity uint64 number to mint
    function publicMint(uint64 quantity) 
    external payable {  
        
        Phase memory phased = findPhase(PUBLIC_PHASE); 

        isValidPayment(phased.cost, quantity);

        phasedMint(PUBLIC_PHASE, quantity, false);       
    }

    /// @notice empower function
    /// @param tokenId uint256 token id to empower
    function empower(uint256 tokenId) external {
        validateApprovedOrOwner(msg.sender, tokenId);

        if (!enumerationExists(tokenId)) {
            enumerateToken(msg.sender, tokenId);
        }
    }    

    /// @notice burn function
    /// @param tokenId uint256 token id to burn
    function burn(uint256 tokenId) external {

        validateApprovedOrOwner(msg.sender, tokenId);
        
        validateLock(tokenId);   

        if (enumerationExists(tokenId)) {
            enumerateBurn(msg.sender,tokenId);
            selfDestruct(tokenId);
        }

        packedBurn(tokenId);
    }    

    /**
     * Owner Utility and Managment of TREASURY 
     */     

    /**
     * setRoyaltyBasis
     * @notice sets the royalty rate 
     * @param royalty_basis uint256 0 - 1000 (1000 = 10%)
     */
    function setRoyaltyBasis(uint256 royalty_basis) external onlyOwner {
        royaltyBasis = royalty_basis;
    }    

    /**
     * setContractRoyaltyRecipient
     * @notice sets the royalty payment recipient
     * @param recipient address to recieve royalties
     */
    function setContractRoyaltyRecipient(address recipient) external onlyOwner {
        feeRecipient = recipient;
    }   

    /**
     * setContractProfileImage
     * @notice sets the contract profile image
     * @param imageUri uri to use for profile image
     */
    function setContractProfileImage(bytes calldata imageUri) external onlyOwner {
        contractProfileURI = imageUri;
    }                

    /// @notice withdraw funds to treasury
    function withdrawFunds() external onlyOwner {
        TREASURY.transfer(address(this).balance);
    } 

    /// @notice set treasury wallet address
    function assignFundRecipient(address treasury) external onlyOwner {
        TREASURY = payable(treasury);
    }      

    /// @notice disables soul bound state allowing transfers and approvals
    function enableSecondarySales() external onlyOwner {
        releaseSoul();
    }    

    /// @notice establishes the cost of a mint for the specified phase
    /// @param phase uint256 the phase to set the mint price for
    /// @param price uint256 price of mint during phase
    function setMintPrice(uint256 phase, uint256 price) external onlyOwner {
        Phase memory existing = findPhase(phase);
        existing.cost = price;
        updatePhase(phase, existing);
    }

    /// @notice determines the price for a minting phase
    /// @param phase uint256 the phase to get the mint price for
    function getMintPrice(uint256 phase) external view returns (uint256) {
        Phase memory existing = findPhase(phase);
        return existing.cost;
    }    

    /// @notice mints quantity of tokens to TREASURY without enumeration
    /// @param quantity uint256 quantity to mint to TREASURY
    function airdropToTreasury(uint256 quantity) public onlyOwner {        
        if (minted()+quantity > getMaxSupply()) {
            revert ExceedsMaxSupply();
        }
        _mint(TREASURY, quantity, false);
    }  

    /// @notice airdrops tokenId from TREASURY to recipient
    /// @param tokenId uint256 tokenId to airdrop
    /// @param recipient address address to airdrop token to
    function airdropFromTreasury(uint256 tokenId, address recipient) public onlyOwner {        
        if (ownerOf(tokenId) != TREASURY) {
            revert NotInTreasury(tokenId);
        }
        if (!enumerationExists(tokenId)) {
            enumerateToken(TREASURY, tokenId);
        }
        transferFrom(TREASURY, recipient, tokenId);

    }        

    /**
     * @notice 
     * @param recipient address recipient of airdrop
     * @param quantity quantity to airdrop
     */
    function bulkAirdrop(address recipient, uint256 quantity) public virtual onlyOwner {        
        super.airdrop(recipient,quantity,false);
        freeClaimed[msg.sender] = true;
    }    

    /// @notice max supply of tokens allowed
    function maxSupply() external view returns (uint256) {
        return getMaxSupply();
    }       

    /// @notice validate payment for minting phase
    /// @param cost uint256 cost required by requested phase
    /// @param quantity uint256 number of tokens requested
    function isValidPayment(uint256 cost, uint256 quantity) internal view {        
        if (msg.value != (cost*quantity)) {
            revert InvalidPayment(cost*quantity, msg.value);
        }
    } 
}

/**
 * Ordo Signum Machina - 2023
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

struct ApprovableData { 

    mapping(address => uint256) contractApprovals;
    mapping(address => address[]) approvedForAll;
    mapping(address => mapping(address => uint256)) approvedForAllIndex;

    mapping(uint256 => uint256) tokenApprovals;
    mapping(uint256 => TokenApproval[]) approvedForToken;
    mapping(uint256 => mapping(address => uint256)) approvedForTokenIndex;

    mapping(uint256 => TokenApproval) tokens;

    bool exists;
}    

struct TokenApproval {
    address approval;
    bool exists;
}

error AlreadyApproved(address operator, uint256 tokenId);
error AlreadyApprovedContract(address operator);
error AlreadyRevoked(address operator, uint256 tokenId);
error AlreadyRevokedContract(address operator);
error TokenNonExistent(uint256 tokenId);


library SetApprovable {     

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);    

    function isApprovedForAll(ApprovableData storage self, address owner, address operator) public view returns (bool) {        
        return self.approvedForAll[owner].length > self.approvedForAllIndex[owner][operator] ? 
            (self.approvedForAll[owner][self.approvedForAllIndex[owner][operator]] != address(0)) :
            false;
    }   

    function revokeApprovals(ApprovableData storage self, address owner, uint256[] memory ownedTokens) public {            
        
        for (uint256 i = 0; i < ownedTokens.length; i++) {
            revokeTokenApproval(self,ownedTokens[i]);
        }
        
        address[] memory contractApprovals = self.approvedForAll[owner];
        for (uint256 i = 0; i < contractApprovals.length; i++) {
            address approved = contractApprovals[i];    
            revokeApprovalForContract(self, approved, owner);             
        }
    }   

    function revokeTokenApproval(ApprovableData storage self, uint256 token) public {            
        TokenApproval[] memory approvals = self.approvedForToken[token];
        for (uint256 j = 0; j < approvals.length; j++) {
            revokeApprovalForToken(self, approvals[j].approval, token);
        }         
    }       

    function getApproved(ApprovableData storage self, uint256 tokenId) public view returns (address) {
        return self.approvedForToken[tokenId].length > 0 ? self.approvedForToken[tokenId][0].approval : address(0);
    }     

    function approveForToken(ApprovableData storage self, address operator, uint256 tokenId) public {
        uint256 index = self.approvedForTokenIndex[tokenId][operator];
        if (index < self.approvedForToken[tokenId].length) {
            if (self.approvedForToken[tokenId][index].exists) {
                revert AlreadyApproved(operator, tokenId);
            }            
        }
   
        self.approvedForToken[tokenId].push(TokenApproval(operator,true));
        self.approvedForTokenIndex[tokenId][operator] = self.approvedForToken[tokenId].length-1;
        self.tokenApprovals[tokenId]++;
        
        emit Approval(msg.sender, operator, tokenId); 
    } 

    function revokeApprovalForToken(ApprovableData storage self, address revoked, uint256 tokenId) public {
        uint256 index = self.approvedForTokenIndex[tokenId][revoked];
        if (!self.approvedForToken[tokenId][index].exists) {
            revert AlreadyRevoked(revoked,tokenId);
        }
        
        // When the token to delete is not the last token, the swap operation is unnecessary
        if (index != self.approvedForToken[tokenId].length - 1) {
            TokenApproval storage tmp = self.approvedForToken[tokenId][self.approvedForToken[tokenId].length - 1];
            self.approvedForToken[tokenId][self.approvedForToken[tokenId].length - 1] = self.approvedForToken[tokenId][index];
            self.approvedForToken[tokenId][index] = tmp;
            self.approvedForTokenIndex[tokenId][tmp.approval] = index;            
        }

        // This also deletes the contents at the last position of the array
        delete self.approvedForTokenIndex[tokenId][revoked];
        self.approvedForToken[tokenId].pop();

        self.tokenApprovals[tokenId]--;
    }

    function approveForContract(ApprovableData storage self, address operator) public {
        uint256 index = self.approvedForAllIndex[msg.sender][operator];
        if (self.approvedForAll[msg.sender].length > index) {
            if (self.approvedForAll[msg.sender][index] != address(0)) {
                revert AlreadyApprovedContract(self.approvedForAll[msg.sender][index]);
            }
        }
   
        self.approvedForAll[msg.sender].push(operator);
        self.approvedForAllIndex[msg.sender][operator] = self.approvedForAll[msg.sender].length-1;
        self.contractApprovals[msg.sender]++;

        emit ApprovalForAll(msg.sender, operator, true); 
    } 

    function revokeApprovalForContract(ApprovableData storage self, address revoked, address owner) public {
        uint256 index = self.approvedForAllIndex[owner][revoked];
        address revokee = self.approvedForAll[owner][index];
        if (revokee != revoked) {
            revert AlreadyRevokedContract(revoked);
        }
        
        // When the token to delete is not the last token, the swap operation is unnecessary
        if (index != self.approvedForAll[owner].length - 1) {
            address tmp = self.approvedForAll[owner][self.approvedForAll[owner].length - 1];
            self.approvedForAll[owner][self.approvedForAll[owner].length - 1] = self.approvedForAll[owner][index];
            self.approvedForAll[owner][index] = tmp;
            self.approvedForAllIndex[owner][tmp] = index;            
        }
        // This also deletes the contents at the last position of the array
        delete self.approvedForAllIndex[owner][revoked];
        self.approvedForAll[owner].pop();

        self.contractApprovals[owner]--;

        emit ApprovalForAll(owner, revoked, false); 
    }    

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

struct AssignableData { 
    mapping(uint256 => address[]) assignments;

    mapping(address => mapping(uint256 => uint256)) assignmentIndex; 

    mapping(address => uint256) assigned;
}    

error AlreadyAssigned(uint256 tokenId);
error NotAssigned(address to);
error NotTokenOwner();

interface Supportable {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
    function balanceOf(address owner) external view returns (uint256);
    function ownerOf(uint256 tokenId) external view returns (address);
    function balanceOf(address owner, uint256 tokenId) external view returns (uint256);
}

library SetAssignable {

    function findAssignees(AssignableData storage self, uint256 tokenId) public view returns (address[] memory) {
        return self.assignments[tokenId];
    }

    function revokeAll(AssignableData storage self, uint256 tokenId) public {        
        for (uint256 iterator = 0; iterator < self.assignments[tokenId].length; iterator++) {
            address target = self.assignments[tokenId][iterator];
            delete self.assignmentIndex[target][tokenId];
            delete self.assigned[target];
        }
        while ( self.assignments[tokenId].length > 0) {
            self.assignments[tokenId].pop();
        }        
    }

    function iterateGuardiansBalance(AssignableData storage self, uint256[] memory guardians, address seeking, uint256 tokenId) public view returns (uint256)  {
        uint256 balance = 0;
        for (uint256 iterator = 0; iterator < guardians.length; iterator++) {
            uint256 guardian = guardians[iterator];
            balance += iterateAssignmentsBalance(self,guardian,seeking,tokenId);
        }
        return balance;
    }

    function iterateAssignmentsBalance(AssignableData storage self, uint256 guardian, address seeking, uint256 tokenId) public view returns (uint256)  {
        uint256 balance = 0;
        for (uint256 iterator = 0; iterator < self.assignments[guardian].length; iterator++) {
            address assignment =self.assignments[guardian][iterator];
            Supportable supporting = Supportable(seeking);
            if (supporting.supportsInterface(type(IERC721).interfaceId)) {
                balance += supporting.balanceOf(assignment); 
            }            
            if (supporting.supportsInterface(type(IERC1155).interfaceId)) {
                balance += supporting.balanceOf(assignment, tokenId); 
            }               
        }       
        return balance; 
    } 

    function addAssignment(AssignableData storage self, address to, uint256 tokenId) public {
        uint256 assigned = findAssignment(self, to);
        if (assigned > 0) {
            revert AlreadyAssigned(assigned);
        }
        
        self.assignments[tokenId].push(to);     
        uint256 length = self.assignments[tokenId].length;
        self.assignmentIndex[to][tokenId] = length-1;
        self.assigned[to] = tokenId;
    }    

    function removeAssignment(AssignableData storage self, address to) public {
        uint256 assigned = findAssignment(self, to);
        if (assigned > 0) {
            uint256 existingAddressIndex = self.assignmentIndex[to][assigned];
            uint256 lastAssignmentIndex = self.assignments[assigned].length-1;
            
            if (existingAddressIndex != lastAssignmentIndex) {
                address lastAssignment = self.assignments[assigned][lastAssignmentIndex];
                self.assignments[assigned][existingAddressIndex] = lastAssignment; 
                self.assignmentIndex[lastAssignment][assigned] = existingAddressIndex;
            }
            delete self.assignmentIndex[to][assigned];
            self.assignments[assigned].pop();
        } else {
            revert NotAssigned(to);
        }
    }

    function findAssignment(AssignableData storage self, address to) public view returns (uint256) {
        return self.assigned[to];
    }     
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
bytes constant description = abi.encodePacked(unicode"Female Apiens, born from the heart of the Apiens community, carry a powerful mission: to uplift and empower women. By giving them wings to build businesses centered around their unique strengths, these cherished collections not only unlock exciting possibilities but also offer incredible opportunities for female Apiens to soar.");
struct RenderableData { 
    uint256 num;
}   
library SetContractMetadataRenderable {
    using Strings for uint256;

    function encodedContractURI(RenderableData storage, bytes memory imageUri, uint256 royalty_basis, address recipient) public pure returns (string memory) { 
        bytes memory dataURI = abi.encodePacked(
            '{',
                '"name": "Queen Apiens"',
                ',"description": "',string(description),'"', 
                ',"image":"',string(imageUri),'"',
                ',"external_link":"https://theapiens.com/"',
                ',"seller_fee_basis_points":', royalty_basis.toString(), 
                ',"fee_recipient":"', Strings.toHexString(uint160(recipient), 20),'"'
            '}'
        );

        return string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(dataURI)
            )
        );
    }    
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

struct FlexibleMetadataData { 
    string defaultTokenMetadata;
    string prerevealTokenMetadata;
    string flaggedTokenMetadata;
    mapping(string => string) supplementalTokenMetadata;
    string contractMetadata;
    mapping(uint256 => bool) tokenFlag;
    mapping(uint256 => Supplement) supplemental;
    bool tokenReveal; 
}    
struct Supplement {
    string key;
    bool exists;
}
bytes16 constant _SYMBOLS = "0123456789abcdef";
uint256 constant DEFAULT = 1;
uint256 constant FLAG = 2;
uint256 constant PRE = 3;
library SetFlexibleMetadata {
    function setDefaultTokenMetadataURI(FlexibleMetadataData storage self, string memory uri) public {
        self.defaultTokenMetadata = uri;
    }  
    function setPrerevealTokenMetadataURI(FlexibleMetadataData storage self, string memory uri) public {
        self.prerevealTokenMetadata = uri;
    }  
    function setFlaggedTokenMetadataURI(FlexibleMetadataData storage self, string memory uri) public {
        self.flaggedTokenMetadata = uri;
    }  
    function setSupplementalTokenMetadataURI(FlexibleMetadataData storage self, string memory key, string memory uri) public {
        self.supplementalTokenMetadata[key] = uri;
    }      
    function setContractMetadataURI(FlexibleMetadataData storage self, string memory uri) public {
        self.contractMetadata = uri;
    }  
    function reveal(FlexibleMetadataData storage self, bool revealed) public {
        self.tokenReveal = revealed;
    }

    function flagToken(FlexibleMetadataData storage self, uint256 tokenId, bool flagged) public {
        self.tokenFlag[tokenId] = flagged;
    }

    function getTokenMetadata(FlexibleMetadataData storage self, uint256 tokenId) public view returns (string memory) {
        if (self.tokenFlag[tokenId]) {
            return encodeURI(self.flaggedTokenMetadata,tokenId);
        } 
        if (!self.tokenReveal) {
            return encodeURI(self.prerevealTokenMetadata,tokenId);
        }
        if (self.supplemental[tokenId].exists) {
            return encodeURI(self.supplementalTokenMetadata[self.supplemental[tokenId].key],tokenId);
        }
        return encodeURI(self.defaultTokenMetadata,tokenId);
    }

    function getContractMetadata(FlexibleMetadataData storage self) public view returns (string memory) { 
        return self.contractMetadata;
    }    

    function encodeURI(string storage uri, uint256 tokenId) public pure returns (string memory) {
        return string(abi.encodePacked(uri, "/", toString(tokenId)));
    }

    function toString(uint256 value) public pure returns (string memory) {
        unchecked {
            uint256 length = log10(value) + 1;
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

    function log10(uint256 value) public pure returns (uint256) {
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
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { InvalidOwner } from "./SetOwnerEnumerable.sol";
struct LockableData { 

    mapping(address => uint256) lockableStatusIndex; 

    mapping(address => LockableStatus) lockableStatus;  
} 


struct LockableStatus {
    bool isLocked;
    uint256 lockedAt;
    address custodian;
    uint256 balance;
    address[] approvedAll;
    bool exists;
}

uint64 constant MAX_INT = 2**64 - 1;

error OnlyCustodianCanLock();

error OnlyOwnerCanSetCustodian();

error InvalidTransferRecipient();

error ContractIsNot721Receiver();

error WalletLockedByOwner();

error TokenIsSoulBound();


library SetLockable {           

    function lockWallet(LockableData storage self, address holder) public {
        LockableStatus storage status = self.lockableStatus[holder];    
        if (msg.sender != status.custodian) {
            revert OnlyCustodianCanLock();
        }       
        status.isLocked = true;
        status.lockedAt = block.timestamp;
    }

    function unlockWallet(LockableData storage self, address holder) public {        
        LockableStatus storage status = self.lockableStatus[holder];
        if (msg.sender != status.custodian) {
            revert OnlyCustodianCanLock();
        }                   
        
        status.isLocked = false;
        status.lockedAt = MAX_INT;
    }

    function setCustodian(LockableData storage self, address custodianAddress,  address holder) public {
        if (msg.sender != holder) {
            revert OnlyOwnerCanSetCustodian();
        }    
        LockableStatus storage status = self.lockableStatus[holder];
        status.custodian = custodianAddress;
    }

    function findCustodian(LockableData storage self, address wallet) public view returns (address) {
        return self.lockableStatus[wallet].custodian;
    }

    function forceUnlock(LockableData storage self, address owner) public {        
        LockableStatus storage status = self.lockableStatus[owner];
        status.isLocked = false;
        status.lockedAt = MAX_INT;
    }
            
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
struct MintableData {
    mapping(address => mapping(uint256 => bool)) claimed;    
}

error OnlyOwnerCanClaim();
library SetMintable {
    function isClaimed(MintableData storage self, address addressed, uint256 tokenId) public view returns (bool) {
        return self.claimed[addressed][tokenId];
    }
    function claim(MintableData storage self, address addressed, uint256 tokenId) public {
        self.claimed[addressed][tokenId] = true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
struct NameableData {
    string name;
    string symbol;
}
library SetNameable {
    function getName(NameableData storage self) public view returns (string memory) {
        return self.name;
    }
    function getSymbol(NameableData storage self) public view returns (string memory) {
        return self.symbol;
    }    
    function setName(NameableData storage self, string calldata named) public {
        self.name = named;
    }
    function setSymbol(NameableData storage self, string calldata symbol) public {
        self.symbol = symbol;
    }    
    function setNamed(NameableData storage self, string memory named, string memory symbol) public {
        self.name = named;
        self.symbol = symbol;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

struct OwnerEnumerableData { 
    mapping(uint256 => TokenOwnership) tokens;

    mapping(address => bool) ownerEnumerated;
    
    mapping(address => uint256[]) ownedTokens;

    mapping(address => mapping(uint256 => uint256)) ownedTokensIndex; 

    mapping(address => uint256[]) burnedTokens;

    mapping(address => mapping(uint256 => uint256)) burnedTokensIndex; 
} 



struct TokenOwnership {
    address ownedBy;
    bool exists;
}

error TokenNonOwner(address requester, uint256 tokenId); 
error InvalidOwner();

library SetOwnerEnumerable {
    function addTokenToEnumeration(OwnerEnumerableData storage self, address to, uint256 tokenId) public {       
        self.ownedTokens[to].push(tokenId);        
        uint256 length = self.ownedTokens[to].length;
        self.ownedTokensIndex[to][tokenId] = length-1;
        self.tokens[tokenId] = TokenOwnership(to,true);
        self.ownerEnumerated[to] = true;
    }

    function addBurnToEnumeration(OwnerEnumerableData storage self, address to, uint256 tokenId) public {       
        self.burnedTokens[to].push(tokenId);        
        uint256 length = self.burnedTokens[to].length;
        self.burnedTokensIndex[to][tokenId] = length-1;        
    }    

    function removeTokenFromEnumeration(OwnerEnumerableData storage self, address to, uint256 tokenId) public {

        uint256 length = self.ownedTokens[to].length;
        if (self.ownedTokensIndex[to][tokenId] > 0) {
            if (self.ownedTokensIndex[to][tokenId] != length - 1) {
                uint256 lastTokenId = self.ownedTokens[to][length - 1];
                self.ownedTokens[to][self.ownedTokensIndex[to][tokenId]] = lastTokenId; 
                self.ownedTokensIndex[to][lastTokenId] = self.ownedTokensIndex[to][tokenId];
            }
        }

        delete self.ownedTokensIndex[to][tokenId];
        if (self.ownedTokens[to].length > 0) {
            self.ownedTokens[to].pop();
        }
    }    

    function isOwnerEnumerated(OwnerEnumerableData storage self, address wallet) public view returns (bool) {        
        return self.ownerEnumerated[wallet];
    }  
    
    function findTokensOwned(OwnerEnumerableData storage self, address wallet) public view returns (uint256[] storage) {        
        return self.ownedTokens[wallet];
    }  

    function tokenIndex(OwnerEnumerableData storage self, address wallet, uint256 index) public view returns (uint256) {
        return self.ownedTokens[wallet][index];
    }    

    function ownerOf(OwnerEnumerableData storage self, uint256 tokenId) public view returns (address) {
        address owner = self.tokens[tokenId].ownedBy;
        if (owner == address(0)) {
            revert TokenNonOwner(owner,tokenId);
        }
        return owner;
    }      
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;


/**
    * The caller must own the token or be an approved operator.
    */
error ApprovalCallerNotOwnerNorApproved();

/**
    * The token does not exist.
    */
error ApprovalQueryForNonexistentToken();

/**
    * Cannot query the balance for the zero address.
    */
error BalanceQueryForZeroAddress();

/**
    * Cannot mint to the zero address.
    */
error MintToZeroAddress();

/**
    * The quantity of tokens minted must be more than zero.
    */
error MintZeroQuantity();

/**
    * The token does not exist.
    */
error OwnerQueryForNonexistentToken();

/**
    * The caller must own the token or be an approved operator.
    */
error TransferCallerNotOwnerNorApproved();

/**
    * The token must be owned by `from`.
    */
error TransferFromIncorrectOwner();

/**
    * Cannot safely transfer to a contract that does not implement the
    * ERC721Receiver interface.
    */
error TransferToNonERC721ReceiverImplementer();

/**
    * Cannot transfer to the zero address.
    */
error TransferToZeroAddress();

/**
    * The token does not exist.
    */
error URIQueryForNonexistentToken();

/**
    * The `quantity` minted with ERC2309 exceeds the safety limit.
    */
error MintERC2309QuantityExceedsLimit();

/**
    * The `extraData` cannot be set on an unintialized ownership slot.
    */
error OwnershipNotInitializedForExtraData();

// =============================================================
//                            STRUCTS
// =============================================================

struct TokenOwnership {
    // The address of the owner.
    address addr;
    // Stores the start time of ownership with minimal overhead for tokenomics.
    uint64 startTimestamp;
    // Whether the token has been burned.
    bool burned;
    // Arbitrary data similar to `startTimestamp` that can be set via {_extraData}.
    uint24 extraData;
}    


struct DualAuxData {
    uint32 data1;
    uint32 data2;
}

struct QuadAuxData {
    uint16 data1;
    uint16 data2;
    uint16 data3;
    uint16 data4;
}
struct OctAuxData {
    uint8 data1;
    uint8 data2;
    uint8 data3;
    uint8 data4;
    uint8 data5;
    uint8 data6;
    uint8 data7;
    uint8 data8;
}

// Mapping from token ID to ownership details
// An empty struct value does not necessarily mean the token is unowned.
// See {_packedOwnershipOf} implementation for details.
//
// Bits Layout:
// - [0..159]   `addr`
// - [160..223] `startTimestamp`
// - [224]      `burned`
// - [225]      `nextInitialized`
// - [232..255] `extraData`

// Mapping owner address to address data.
//
// Bits Layout:
// - [0..63]    `balance`
// - [64..127]  `numberMinted`
// - [128..191] `numberBurned`
// - [192..255] `aux`
struct PackableData {
    mapping(uint256 => uint256) _packedOwnerships;
    mapping(address => uint256) _packedAddressData;
    uint256 _currentIndex;
    uint256 _burnCounter;
}

library SetPackable {

    

    // =============================================================
    //                           CONSTANTS
    // =============================================================

    // Mask of an entry in packed address data.
    uint256 private constant _BITMASK_ADDRESS_DATA_ENTRY = (1 << 64) - 1;

    // The bit position of `numberMinted` in packed address data.
    uint256 private constant _BITPOS_NUMBER_MINTED = 64;

    // The bit position of `numberBurned` in packed address data.
    uint256 private constant _BITPOS_NUMBER_BURNED = 128;

    // The bit position of `aux` in packed address data.
    uint256 private constant _BITPOS_AUX = 192;

    // Mask of all 256 bits in packed address data except the 64 bits for `aux`.
    uint256 private constant _BITMASK_AUX_COMPLEMENT = (1 << 192) - 1;

    // The bit position of `startTimestamp` in packed ownership.
    uint256 private constant _BITPOS_START_TIMESTAMP = 160;

    // The bit mask of the `burned` bit in packed ownership.
    uint256 private constant _BITMASK_BURNED = 1 << 224;

    // The bit position of the `nextInitialized` bit in packed ownership.
    uint256 private constant _BITPOS_NEXT_INITIALIZED = 225;

    // The bit mask of the `nextInitialized` bit in packed ownership.
    uint256 private constant _BITMASK_NEXT_INITIALIZED = 1 << 225;

    // The bit position of `extraData` in packed ownership.
    uint256 private constant _BITPOS_EXTRA_DATA = 232;

    // Mask of all 256 bits in a packed ownership except the 24 bits for `extraData`.
    uint256 private constant _BITMASK_EXTRA_DATA_COMPLEMENT = (1 << 232) - 1;

    // The mask of the lower 160 bits for addresses.
    uint256 private constant _BITMASK_ADDRESS = (1 << 160) - 1;

    // The maximum `quantity` that can be minted with {_mintERC2309}.
    // This limit is to prevent overflows on the address data entries.
    // For a limit of 5000, a total of 3.689e15 calls to {_mintERC2309}
    // is required to cause an overflow, which is unrealistic.
    uint256 private constant _MAX_MINT_ERC2309_QUANTITY_LIMIT = 5000;

    // The `Transfer` event signature is given by:
    // `keccak256(bytes("Transfer(address,address,uint256)"))`.
    bytes32 private constant _TRANSFER_EVENT_SIGNATURE =
        0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef;


    // =============================================================
    //                    ADDRESS DATA OPERATIONS
    // =============================================================

    /**
     * @dev Returns the number of tokens in `owner`'s account.
     */
    function balanceOf(PackableData storage self, address owner) public view returns (uint256) {
        if (owner == address(0)) revert BalanceQueryForZeroAddress();
        return self._packedAddressData[owner] & _BITMASK_ADDRESS_DATA_ENTRY;
    }

    /**
     * Returns the number of tokens minted by `owner`.
     */
    function _numberMinted(PackableData storage self,address owner) public view returns (uint256) {
        return (self._packedAddressData[owner] >> _BITPOS_NUMBER_MINTED) & _BITMASK_ADDRESS_DATA_ENTRY;
    }

    /**
     * Returns the number of tokens burned by or on behalf of `owner`.
     */
    function _numberBurned(PackableData storage self,address owner) public view returns (uint256) {
        return (self._packedAddressData[owner] >> _BITPOS_NUMBER_BURNED) & _BITMASK_ADDRESS_DATA_ENTRY;
    }

    /**
     * Returns the auxiliary data for `owner`. (e.g. number of whitelist mint slots used).
     */
    function _getAux(PackableData storage self,address owner) public view returns (uint64 aux) {
        return uint64(self._packedAddressData[owner] >> _BITPOS_AUX);
    }

    /**
     * Sets the auxiliary data for `owner`. (e.g. number of whitelist mint slots used).
     * If there are multiple variables, please pack them into a uint64.
     */
    function _setAux(PackableData storage self, address owner, uint64 aux) public {
        uint256 packed = self._packedAddressData[owner];
        uint256 auxCasted;
        // Cast `aux` with assembly to avoid redundant masking.
        assembly {
            auxCasted := aux
        }
        packed = (packed & _BITMASK_AUX_COMPLEMENT) | (auxCasted << _BITPOS_AUX);
        self._packedAddressData[owner] = packed;
    }

    function getAux16(PackableData storage self, address owner) public view returns (uint16[4] memory) {
        
        uint32[2] memory packed32 = unpack64(self,_getAux(self,owner));
        uint16[2] memory pack16a = unpack32(self,packed32[0]);
        uint16[2] memory pack16b = unpack32(self,packed32[1]);
        
        return [pack16a[0],pack16a[1],pack16b[0],pack16b[1]];
    }   

    function pack16(PackableData storage, uint8 pack1, uint8 pack2) public pure returns (uint16) {
        return (uint16(pack2) << 8) | pack1;
    }

    function pack32(PackableData storage, uint16 pack1, uint16 pack2) public pure returns (uint32) {
        return (uint32(pack2) << 16) | pack1;
    }    

    function pack64(PackableData storage, uint32 pack1, uint32 pack2) public pure returns (uint64) {
        return (uint64(pack2) << 32) | pack1;
    }        

    function unpack64(PackableData storage, uint64 packed) public pure returns (uint32[2] memory unpacked){
        uint32 pack2 = uint32(packed >> 32); 
        uint32 pack1 = uint32(packed);       
        return [pack1, pack2];
    }       

    function unpack32(PackableData storage, uint32 packed) public pure returns (uint16[2] memory unpacked){
        uint16 pack2 = uint16(packed >> 16); 
        uint16 pack1 = uint16(packed);       
        return [pack1, pack2];
    }        

    function unpack16(PackableData storage, uint16 packed) public pure returns (uint8[2] memory unpacked){
        uint8 pack2 = uint8(packed >> 8); 
        uint8 pack1 = uint8(packed);       
        return [pack1, pack2];
    }    

    // =============================================================
    //                     OWNERSHIPS OPERATIONS
    // =============================================================

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(PackableData storage self, uint256 tokenId) public view returns (address) {
        return address(uint160(_packedOwnershipOf(self,tokenId)));
    }

    /**
     * @dev Gas spent here starts off proportional to the maximum mint batch size.
     * It gradually moves to O(1) as tokens get transferred around over time.
     */
    function _ownershipOf(PackableData storage self, uint256 tokenId) internal view returns (TokenOwnership memory) {
        return _unpackedOwnership(_packedOwnershipOf(self,tokenId));
    }

    /**
     * @dev Returns the unpacked `TokenOwnership` struct at `index`.
     */
    function _ownershipAt(PackableData storage self, uint256 index) internal view returns (TokenOwnership memory) {
        return _unpackedOwnership(self._packedOwnerships[index]);
    }

    /**
     * @dev Initializes the ownership slot minted at `index` for efficiency purposes.
     */
    function _initializeOwnershipAt(PackableData storage self, uint256 index) internal {
        if (self._packedOwnerships[index] == 0) {
            self._packedOwnerships[index] = _packedOwnershipOf(self,index);
        }
    }

    /**
     * Returns the packed ownership data of `tokenId`.
     */
    function _packedOwnershipOf(PackableData storage self, uint256 tokenId) private view returns (uint256) {
        uint256 curr = tokenId;

        unchecked {
            if (_startTokenId(self) <= curr)
                if (curr < self._currentIndex) {
                    uint256 packed = self._packedOwnerships[curr];
                    // If not burned.
                    if (packed & _BITMASK_BURNED == 0) {
                        // Invariant:
                        // There will always be an initialized ownership slot
                        // (i.e. `ownership.addr != address(0) && ownership.burned == false`)
                        // before an unintialized ownership slot
                        // (i.e. `ownership.addr == address(0) && ownership.burned == false`)
                        // Hence, `curr` will not underflow.
                        //
                        // We can directly compare the packed value.
                        // If the address is zero, packed will be zero.
                        while (packed == 0) {
                            packed = self._packedOwnerships[--curr];
                        }
                        return packed;
                    }
                }
        }
        revert OwnerQueryForNonexistentToken();
    }

    /**
     * @dev Returns the unpacked `TokenOwnership` struct from `packed`.
     */
    function _unpackedOwnership(uint256 packed) private pure returns (TokenOwnership memory ownership) {
        ownership.addr = address(uint160(packed));
        ownership.startTimestamp = uint64(packed >> _BITPOS_START_TIMESTAMP);
        ownership.burned = packed & _BITMASK_BURNED != 0;
        ownership.extraData = uint24(packed >> _BITPOS_EXTRA_DATA);
    }

    /**
     * @dev Packs ownership data into a single uint256.
     */
    function _packOwnershipData(address owner, uint256 flags) private view returns (uint256 result) {
        assembly {
            // Mask `owner` to the lower 160 bits, in case the upper bits somehow aren't clean.
            owner := and(owner, _BITMASK_ADDRESS)
            // `owner | (block.timestamp << _BITPOS_START_TIMESTAMP) | flags`.
            result := or(owner, or(shl(_BITPOS_START_TIMESTAMP, timestamp()), flags))
        }
    }



    /**
     * @dev Returns the `nextInitialized` flag set if `quantity` equals 1.
     */
    function _nextInitializedFlag(uint256 quantity) private pure returns (uint256 result) {
        // For branchless setting of the `nextInitialized` flag.
        assembly {
            // `(quantity == 1) << _BITPOS_NEXT_INITIALIZED`.
            result := shl(_BITPOS_NEXT_INITIALIZED, eq(quantity, 1))
        }
    }    

    /**
     * @dev Returns the starting token ID.
     * To change the starting token ID, please override this function.
     */
    function _startTokenId(PackableData storage) internal pure returns (uint256) {
        return 0;
    }  

/**
     * @dev Returns the next token ID to be minted.
     */
    function _nextTokenId(PackableData storage self) public view returns (uint256) {
        return self._currentIndex;
    }

    /**
     * @dev Returns the total number of tokens in existence.
     * Burned tokens will reduce the count.
     * To get the total number of tokens minted, please see {_totalMinted}.
     */
    function totalSupply(PackableData storage self) public view returns (uint256) {
        // Counter underflow is impossible as _burnCounter cannot be incremented
        // more than `_currentIndex - _startTokenId()` times.
        unchecked {
            return self._currentIndex - self._burnCounter;
        }
    }

    /**
     * @dev Returns the total amount of tokens minted in the contract.
     */
    function _totalMinted(PackableData storage self) public view returns (uint256) {
        // Counter underflow is impossible as `_currentIndex` does not decrement,
        // and it is initialized to `_startTokenId()`.
        unchecked {
            return self._currentIndex;
        }
    }

    /**
     * @dev Returns the total number of tokens burned.
     */
    function _totalBurned(PackableData storage self) public view returns (uint256) {
        return self._burnCounter;
    }      

/**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted. See {_mint}.
     */
    function _exists(PackableData storage self, uint256 tokenId) public view returns (bool) {
        return
            _startTokenId(self) <= tokenId &&
            tokenId < self._currentIndex && // If within bounds,
            self._packedOwnerships[tokenId] & _BITMASK_BURNED == 0; // and not burned.
    }

    // =============================================================
    //                      TRANSFER OPERATIONS
    // =============================================================

    function transferFrom(
        PackableData storage self,
        address from,
        address to,
        uint256 tokenId
    ) public {
        uint256 prevOwnershipPacked = _packedOwnershipOf(self,tokenId);

        if (address(uint160(prevOwnershipPacked)) != from) revert TransferFromIncorrectOwner();        

        if (to == address(0)) revert TransferToZeroAddress();

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as `tokenId` would have to be 2**256.
        unchecked {
            // We can directly increment and decrement the balances.
            --self._packedAddressData[from]; // Updates: `balance -= 1`.
            ++self._packedAddressData[to]; // Updates: `balance += 1`.

            // Updates:
            // - `address` to the next owner.
            // - `startTimestamp` to the timestamp of transfering.
            // - `burned` to `false`.
            // - `nextInitialized` to `true`.
            self._packedOwnerships[tokenId] = _packOwnershipData(
                to,
                _BITMASK_NEXT_INITIALIZED | _nextExtraData(from, to, prevOwnershipPacked)
            );

            // If the next slot may not have been initialized (i.e. `nextInitialized == false`) .
            if (prevOwnershipPacked & _BITMASK_NEXT_INITIALIZED == 0) {
                uint256 nextTokenId = tokenId + 1;
                // If the next slot's address is zero and not burned (i.e. packed value is zero).
                if (self._packedOwnerships[nextTokenId] == 0) {
                    // If the next slot is within bounds.
                    if (nextTokenId != self._currentIndex) {
                        // Initialize the next slot to maintain correctness for `ownerOf(tokenId + 1)`.
                        self._packedOwnerships[nextTokenId] = prevOwnershipPacked;
                    }
                }
            }
        }
    }

    

    // =============================================================
    //                        MINT OPERATIONS
    // =============================================================

    /**
     * @dev Mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `quantity` must be greater than 0.
     *
     * Emits a {Transfer} event for each mint.
     */
    function _mint(PackableData storage self, address to, uint256 quantity) public returns (uint256) {
        uint256 startTokenId = self._currentIndex;
        if (quantity == 0) revert MintZeroQuantity();        

        // Overflows are incredibly unrealistic.
        // `balance` and `numberMinted` have a maximum limit of 2**64.
        // `tokenId` has a maximum limit of 2**256.
        unchecked {
            // Updates:
            // - `balance += quantity`.
            // - `numberMinted += quantity`.
            //
            // We can directly add to the `balance` and `numberMinted`.
            self._packedAddressData[to] += quantity * ((1 << _BITPOS_NUMBER_MINTED) | 1);

            // Updates:
            // - `address` to the owner.
            // - `startTimestamp` to the timestamp of minting.
            // - `burned` to `false`.
            // - `nextInitialized` to `quantity == 1`.
            self._packedOwnerships[startTokenId] = _packOwnershipData(
                to,
                _nextInitializedFlag(quantity) | _nextExtraData(address(0), to, 0)
            );

            uint256 toMasked;
            uint256 end = startTokenId + quantity;

            // Use assembly to loop and emit the `Transfer` event for gas savings.
            // The duplicated `log4` removes an extra check and reduces stack juggling.
            // The assembly, together with the surrounding Solidity code, have been
            // delicately arranged to nudge the compiler into producing optimized opcodes.
            assembly {
                // Mask `to` to the lower 160 bits, in case the upper bits somehow aren't clean.
                toMasked := and(to, _BITMASK_ADDRESS)
                // Emit the `Transfer` event.
                log4(
                    0, // Start of data (0, since no data).
                    0, // End of data (0, since no data).
                    _TRANSFER_EVENT_SIGNATURE, // Signature.
                    0, // `address(0)`.
                    toMasked, // `to`.
                    startTokenId // `tokenId`.
                )

                // The `iszero(eq(,))` check ensures that large values of `quantity`
                // that overflows uint256 will make the loop run out of gas.
                // The compiler will optimize the `iszero` away for performance.
                for {
                    let tokenId := add(startTokenId, 1)
                } iszero(eq(tokenId, end)) {
                    tokenId := add(tokenId, 1)
                } {
                    // Emit the `Transfer` event. Similar to above.
                    log4(0, 0, _TRANSFER_EVENT_SIGNATURE, 0, toMasked, tokenId)
                }
            }
            if (toMasked == 0) revert MintToZeroAddress();

            self._currentIndex = end;
        }     
        return self._currentIndex;
    }

    

    // =============================================================
    //                        BURN OPERATIONS
    // =============================================================

    function _burn(PackableData storage self, uint256 tokenId) public {
        uint256 prevOwnershipPacked = _packedOwnershipOf(self,tokenId);

        address from = address(uint160(prevOwnershipPacked));

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as `tokenId` would have to be 2**256.
        unchecked {
            // Updates:
            // - `balance -= 1`.
            // - `numberBurned += 1`.
            //
            // We can directly decrement the balance, and increment the number burned.
            // This is equivalent to `packed -= 1; packed += 1 << _BITPOS_NUMBER_BURNED;`.
            self._packedAddressData[from] += (1 << _BITPOS_NUMBER_BURNED) - 1;

            // Updates:
            // - `address` to the last owner.
            // - `startTimestamp` to the timestamp of burning.
            // - `burned` to `true`.
            // - `nextInitialized` to `true`.
            self._packedOwnerships[tokenId] = _packOwnershipData(
                from,
                (_BITMASK_BURNED | _BITMASK_NEXT_INITIALIZED) | _nextExtraData(from, address(0), prevOwnershipPacked)
            );

            // If the next slot may not have been initialized (i.e. `nextInitialized == false`) .
            if (prevOwnershipPacked & _BITMASK_NEXT_INITIALIZED == 0) {
                uint256 nextTokenId = tokenId + 1;
                // If the next slot's address is zero and not burned (i.e. packed value is zero).
                if (self._packedOwnerships[nextTokenId] == 0) {
                    // If the next slot is within bounds.
                    if (nextTokenId != self._currentIndex) {
                        // Initialize the next slot to maintain correctness for `ownerOf(tokenId + 1)`.
                        self._packedOwnerships[nextTokenId] = prevOwnershipPacked;
                    }
                }
            }
        }

        // Overflow not possible, as _burnCounter cannot be exceed _currentIndex times.
        unchecked {
            self._burnCounter++;
        }
    }

    // =============================================================
    //                     EXTRA DATA OPERATIONS
    // =============================================================

    /**
     * @dev Directly sets the extra data for the ownership data `index`.
     */
    function _setExtraDataAt(PackableData storage self, uint256 index, uint24 extraData) public {
        uint256 packed = self._packedOwnerships[index];
        if (packed == 0) revert OwnershipNotInitializedForExtraData();
        uint256 extraDataCasted;
        // Cast `extraData` with assembly to avoid redundant masking.
        assembly {
            extraDataCasted := extraData
        }
        packed = (packed & _BITMASK_EXTRA_DATA_COMPLEMENT) | (extraDataCasted << _BITPOS_EXTRA_DATA);
        self._packedOwnerships[index] = packed;
    }

    /**
     * @dev Called during each token transfer to set the 24bit `extraData` field.
     * Intended to be overridden by the cosumer contract.
     *
     * `previousExtraData` - the value of `extraData` before transfer.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, `tokenId` will be burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _extraData(
        address from,
        address to,
        uint24 previousExtraData
    ) public view returns (uint24) {}

    /**
     * @dev Returns the next extra data for the packed ownership data.
     * The returned result is shifted into position.
     */
    function _nextExtraData(
        address from,
        address to,
        uint256 prevOwnershipPacked
    ) private view returns (uint256) {
        uint24 extraData = uint24(prevOwnershipPacked >> _BITPOS_EXTRA_DATA);
        return uint256(_extraData(from, to, extraData)) << _BITPOS_EXTRA_DATA;
    }

    // =============================================================
    //                       OTHER OPERATIONS
    // =============================================================

    /**
     * @dev Converts a uint256 to its ASCII string decimal representation.
     */
    function _toString(uint256 value) public pure returns (string memory str) {
        assembly {
            // The maximum value of a uint256 contains 78 digits (1 byte per digit), but
            // we allocate 0xa0 bytes to keep the free memory pointer 32-byte word aligned.
            // We will need 1 word for the trailing zeros padding, 1 word for the length,
            // and 3 words for a maximum of 78 digits. Total: 5 * 0x20 = 0xa0.
            let m := add(mload(0x40), 0xa0)
            // Update the free memory pointer to allocate.
            mstore(0x40, m)
            // Assign the `str` to the end.
            str := sub(m, 0x20)
            // Zeroize the slot after the string.
            mstore(str, 0)

            // Cache the end of the memory to calculate the length later.
            let end := str

            // We write the string from rightmost digit to leftmost digit.
            // The following is essentially a do-while loop that also handles the zero case.
            // prettier-ignore
            for { let temp := value } 1 {} {
                str := sub(str, 1)
                // Write the character to the pointer.
                // The ASCII index of the '0' character is 48.
                mstore8(str, add(48, mod(temp, 10)))
                // Keep dividing `temp` until zero.
                temp := div(temp, 10)
                // prettier-ignore
                if iszero(temp) { break }
            }

            let length := sub(end, str)
            // Move the pointer 32 bytes leftwards to make room for the length.
            str := sub(str, 0x20)
            // Store the length.
            mstore(str, length)
        }
    }    

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

struct PhaseableData { 
    Phase[] phases;
    uint256 activePhase;
    uint256 maxSupply;
}    

struct Phase {
    string name;
    uint256 maxPerWallet;
    uint256 highestSupply;
    uint256 cost;
}

error MintIsNotAllowedRightNow();
error ExceedsMaxSupply();
error PhaseNotActiveYet();
error PhaseExhausted();
error WalletMintsFilled(uint256 requested);

library SetPhaseable {
    function initialize(PhaseableData storage self, Phase[] storage phases, uint256 maxSupply) public {
        self.phases = phases;
        self.activePhase = 0;
        self.maxSupply = maxSupply;
    }
    function getMaxSupply(PhaseableData storage self) public view returns (uint256) {
        return self.maxSupply;
    }
    function setMaxSupply(PhaseableData storage self, uint256 newMax) public {
        self.maxSupply = newMax;
    }
    function getPhases(PhaseableData storage self) public view returns (Phase[] storage) {
        return self.phases;
    }
    function getActivePhase(PhaseableData storage self) public view returns (uint256) {
        return self.activePhase;
    }
    function findPhase(PhaseableData storage self, uint256 phaseId) public view returns (Phase memory) {
        return self.phases[phaseId];
    }
    function startNextPhase(PhaseableData storage self) public {
        self.activePhase += 1;
    }
    function revertPhase(PhaseableData storage self) public {
        self.activePhase -= 1;
    }
    function addPhase(PhaseableData storage self,Phase calldata nextPhase) public {
        self.phases.push(nextPhase);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {OperatorFilterer} from "./OperatorFilterer.sol";
import {CANONICAL_CORI_SUBSCRIPTION} from "./lib/Constants.sol";
/**
 * @title  DefaultOperatorFilterer
 * @notice Inherits from OperatorFilterer and automatically subscribes to the default OpenSea subscription.
 * @dev    Please note that if your token contract does not provide an owner with EIP-173, it must provide
 *         administration methods on the contract itself to interact with the registry otherwise the subscription
 *         will be locked to the options set during construction.
 */

abstract contract DefaultOperatorFilterer is OperatorFilterer {
    /// @dev The constructor that is called when the contract is being deployed.
    constructor() OperatorFilterer(CANONICAL_CORI_SUBSCRIPTION, true) {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IOperatorFilterRegistry {
    /**
     * @notice Returns true if operator is not filtered for a given token, either by address or codeHash. Also returns
     *         true if supplied registrant address is not registered.
     */
    function isOperatorAllowed(address registrant, address operator) external view returns (bool);

    /**
     * @notice Registers an address with the registry. May be called by address itself or by EIP-173 owner.
     */
    function register(address registrant) external;

    /**
     * @notice Registers an address with the registry and "subscribes" to another address's filtered operators and codeHashes.
     */
    function registerAndSubscribe(address registrant, address subscription) external;

    /**
     * @notice Registers an address with the registry and copies the filtered operators and codeHashes from another
     *         address without subscribing.
     */
    function registerAndCopyEntries(address registrant, address registrantToCopy) external;

    /**
     * @notice Unregisters an address with the registry and removes its subscription. May be called by address itself or by EIP-173 owner.
     *         Note that this does not remove any filtered addresses or codeHashes.
     *         Also note that any subscriptions to this registrant will still be active and follow the existing filtered addresses and codehashes.
     */
    function unregister(address addr) external;

    /**
     * @notice Update an operator address for a registered address - when filtered is true, the operator is filtered.
     */
    function updateOperator(address registrant, address operator, bool filtered) external;

    /**
     * @notice Update multiple operators for a registered address - when filtered is true, the operators will be filtered. Reverts on duplicates.
     */
    function updateOperators(address registrant, address[] calldata operators, bool filtered) external;

    /**
     * @notice Update a codeHash for a registered address - when filtered is true, the codeHash is filtered.
     */
    function updateCodeHash(address registrant, bytes32 codehash, bool filtered) external;

    /**
     * @notice Update multiple codeHashes for a registered address - when filtered is true, the codeHashes will be filtered. Reverts on duplicates.
     */
    function updateCodeHashes(address registrant, bytes32[] calldata codeHashes, bool filtered) external;

    /**
     * @notice Subscribe an address to another registrant's filtered operators and codeHashes. Will remove previous
     *         subscription if present.
     *         Note that accounts with subscriptions may go on to subscribe to other accounts - in this case,
     *         subscriptions will not be forwarded. Instead the former subscription's existing entries will still be
     *         used.
     */
    function subscribe(address registrant, address registrantToSubscribe) external;

    /**
     * @notice Unsubscribe an address from its current subscribed registrant, and optionally copy its filtered operators and codeHashes.
     */
    function unsubscribe(address registrant, bool copyExistingEntries) external;

    /**
     * @notice Get the subscription address of a given registrant, if any.
     */
    function subscriptionOf(address addr) external returns (address registrant);

    /**
     * @notice Get the set of addresses subscribed to a given registrant.
     *         Note that order is not guaranteed as updates are made.
     */
    function subscribers(address registrant) external returns (address[] memory);

    /**
     * @notice Get the subscriber at a given index in the set of addresses subscribed to a given registrant.
     *         Note that order is not guaranteed as updates are made.
     */
    function subscriberAt(address registrant, uint256 index) external returns (address);

    /**
     * @notice Copy filtered operators and codeHashes from a different registrantToCopy to addr.
     */
    function copyEntriesOf(address registrant, address registrantToCopy) external;

    /**
     * @notice Returns true if operator is filtered by a given address or its subscription.
     */
    function isOperatorFiltered(address registrant, address operator) external returns (bool);

    /**
     * @notice Returns true if the hash of an address's code is filtered by a given address or its subscription.
     */
    function isCodeHashOfFiltered(address registrant, address operatorWithCode) external returns (bool);

    /**
     * @notice Returns true if a codeHash is filtered by a given address or its subscription.
     */
    function isCodeHashFiltered(address registrant, bytes32 codeHash) external returns (bool);

    /**
     * @notice Returns a list of filtered operators for a given address or its subscription.
     */
    function filteredOperators(address addr) external returns (address[] memory);

    /**
     * @notice Returns the set of filtered codeHashes for a given address or its subscription.
     *         Note that order is not guaranteed as updates are made.
     */
    function filteredCodeHashes(address addr) external returns (bytes32[] memory);

    /**
     * @notice Returns the filtered operator at the given index of the set of filtered operators for a given address or
     *         its subscription.
     *         Note that order is not guaranteed as updates are made.
     */
    function filteredOperatorAt(address registrant, uint256 index) external returns (address);

    /**
     * @notice Returns the filtered codeHash at the given index of the list of filtered codeHashes for a given address or
     *         its subscription.
     *         Note that order is not guaranteed as updates are made.
     */
    function filteredCodeHashAt(address registrant, uint256 index) external returns (bytes32);

    /**
     * @notice Returns true if an address has registered
     */
    function isRegistered(address addr) external returns (bool);

    /**
     * @dev Convenience method to compute the code hash of an arbitrary contract
     */
    function codeHashOf(address addr) external returns (bytes32);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

address constant CANONICAL_OPERATOR_FILTER_REGISTRY_ADDRESS = 0x000000000000AAeB6D7670E522A718067333cd4E;
address constant CANONICAL_CORI_SUBSCRIPTION = 0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6;

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {IOperatorFilterRegistry} from "./IOperatorFilterRegistry.sol";
import {CANONICAL_OPERATOR_FILTER_REGISTRY_ADDRESS} from "./lib/Constants.sol";
/**
 * @title  OperatorFilterer
 * @notice Abstract contract whose constructor automatically registers and optionally subscribes to or copies another
 *         registrant's entries in the OperatorFilterRegistry.
 * @dev    This smart contract is meant to be inherited by token contracts so they can use the following:
 *         - `onlyAllowedOperator` modifier for `transferFrom` and `safeTransferFrom` methods.
 *         - `onlyAllowedOperatorApproval` modifier for `approve` and `setApprovalForAll` methods.
 *         Please note that if your token contract does not provide an owner with EIP-173, it must provide
 *         administration methods on the contract itself to interact with the registry otherwise the subscription
 *         will be locked to the options set during construction.
 */

abstract contract OperatorFilterer {
    /// @dev Emitted when an operator is not allowed.
    error OperatorNotAllowed(address operator);

    IOperatorFilterRegistry public constant OPERATOR_FILTER_REGISTRY =
        IOperatorFilterRegistry(CANONICAL_OPERATOR_FILTER_REGISTRY_ADDRESS);

    /// @dev The constructor that is called when the contract is being deployed.
    constructor(address subscriptionOrRegistrantToCopy, bool subscribe) {
        // If an inheriting token contract is deployed to a network without the registry deployed, the modifier
        // will not revert, but the contract will need to be registered with the registry once it is deployed in
        // order for the modifier to filter addresses.
        if (address(OPERATOR_FILTER_REGISTRY).code.length > 0) {
            if (subscribe) {
                OPERATOR_FILTER_REGISTRY.registerAndSubscribe(address(this), subscriptionOrRegistrantToCopy);
            } else {
                if (subscriptionOrRegistrantToCopy != address(0)) {
                    OPERATOR_FILTER_REGISTRY.registerAndCopyEntries(address(this), subscriptionOrRegistrantToCopy);
                } else {
                    OPERATOR_FILTER_REGISTRY.register(address(this));
                }
            }
        }
    }

    /**
     * @dev A helper function to check if an operator is allowed.
     */
    modifier onlyAllowedOperator(address from) virtual {
        // Allow spending tokens from addresses with balance
        // Note that this still allows listings and marketplaces with escrow to transfer tokens if transferred
        // from an EOA.
        if (from != msg.sender) {
            _checkFilterOperator(msg.sender);
        }
        _;
    }

    /**
     * @dev A helper function to check if an operator approval is allowed.
     */
    modifier onlyAllowedOperatorApproval(address operator) virtual {
        _checkFilterOperator(operator);
        _;
    }

    /**
     * @dev A helper function to check if an operator is allowed.
     */
    function _checkFilterOperator(address operator) internal view virtual {
        // Check registry code length to facilitate testing in environments without a deployed registry.
        if (address(OPERATOR_FILTER_REGISTRY).code.length > 0) {
            // under normal circumstances, this function will revert rather than return false, but inheriting contracts
            // may specify their own OperatorFilterRegistry implementations, which may behave differently
            if (!OPERATOR_FILTER_REGISTRY.isOperatorAllowed(address(this), operator)) {
                revert OperatorNotAllowed(operator);
            }
        }
    }
}