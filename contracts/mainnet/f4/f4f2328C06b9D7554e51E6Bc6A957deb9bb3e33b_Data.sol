/**
 *Submitted for verification at polygonscan.com on 2023-01-24
*/

// SPDX-License-Identifier: MIT
// File: contracts/Base64.sol


pragma solidity ^0.8.0;

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides a function for encoding some bytes in base64
library Base64 {
    string internal constant TABLE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';
        
        // load the table into memory
        string memory table = TABLE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)
            
            // prepare the lookup table
            let tablePtr := add(table, 1)
            
            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))
            
            // result ptr, jump over length
            let resultPtr := add(result, 32)
            
            // run over the input, 3 bytes at a time
            for {} lt(dataPtr, endPtr) {}
            {
               dataPtr := add(dataPtr, 3)
               
               // read 3 bytes
               let input := mload(dataPtr)
               
               // write 4 characters
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr( 6, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(        input,  0x3F)))))
               resultPtr := add(resultPtr, 1)
            }
            
            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }
        
        return result;
    }
}
// File: @openzeppelin/contracts/utils/Strings.sol


// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
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


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
}

// File: @openzeppelin/contracts/utils/Address.sol


// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
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

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


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

// File: @openzeppelin/contracts/utils/introspection/ERC165.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/token/ERC1155/extensions/IERC1155MetadataURI.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;


/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// File: @openzeppelin/contracts/token/ERC1155/ERC1155.sol


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/ERC1155.sol)

pragma solidity ^0.8.0;







/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
    using Address for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    constructor(string memory uri_) {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: address zero is not a valid owner");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not token owner nor approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not token owner nor approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `ids` and `amounts` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    /**
     * @dev Hook that is called after any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
}

// File: @openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/extensions/ERC1155Burnable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Extension of {ERC1155} that allows token holders to destroy both their
 * own tokens and those that they have been approved to use.
 *
 * _Available since v3.1._
 */
abstract contract ERC1155Burnable is ERC1155 {
    function burn(
        address account,
        uint256 id,
        uint256 value
    ) public virtual {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "ERC1155: caller is not token owner nor approved"
        );

        _burn(account, id, value);
    }

    function burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory values
    ) public virtual {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "ERC1155: caller is not token owner nor approved"
        );

        _burnBatch(account, ids, values);
    }
}

// File: @openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC1155/extensions/ERC1155Supply.sol)

pragma solidity ^0.8.0;


/**
 * @dev Extension of ERC1155 that adds tracking of total supply per id.
 *
 * Useful for scenarios where Fungible and Non-fungible tokens have to be
 * clearly identified. Note: While a totalSupply of 1 might mean the
 * corresponding is an NFT, there is no guarantees that no other token with the
 * same id are not going to be minted.
 */
abstract contract ERC1155Supply is ERC1155 {
    mapping(uint256 => uint256) private _totalSupply;

    /**
     * @dev Total amount of tokens in with a given id.
     */
    function totalSupply(uint256 id) public view virtual returns (uint256) {
        return _totalSupply[id];
    }

    /**
     * @dev Indicates whether any token exist with a given id, or not.
     */
    function exists(uint256 id) public view virtual returns (bool) {
        return ERC1155Supply.totalSupply(id) > 0;
    }

    /**
     * @dev See {ERC1155-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        if (from == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                _totalSupply[ids[i]] += amounts[i];
            }
        }

        if (to == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                uint256 id = ids[i];
                uint256 amount = amounts[i];
                uint256 supply = _totalSupply[id];
                require(supply >= amount, "ERC1155: burn amount exceeds totalSupply");
                unchecked {
                    _totalSupply[id] = supply - amount;
                }
            }
        }
    }
}

// File: contracts/Collection3 Media.sol


pragma solidity >=0.8.0 <0.9.0;







contract Collection is Ownable {
  using Strings for uint256;
  string public name = "Media";
  uint public collectionID = 3;
  uint256 public cost=0 ether;
  address public BpaperContractAddr = 0x3C2309aCB65dE5BEca0aec437147f514C1cAB651;
  Bpaper BpaperContract= Bpaper(BpaperContractAddr);
  address public BcardContractAddr = BpaperContract.BcardContractAddr();
  address public designAddr = 0x52b095E79004648CE9dd8cb08dda658396593962;
  address public CheckQuaAddr = 0x1c256eCD8149C0e20E29aB1db4A69dAA4fAE39b6;
  address public dataAddr = 0xf4f2328C06b9D7554e51E6Bc6A957deb9bb3e33b;
  address public AdAddr;

  // public
  function mintNewAnimat(string memory _Title,string[] memory _tagName, string[] memory _tagValue, string memory _content, string memory _imageLink, 
    string memory _animaLink, uint _Amount, address cardholder) public payable {  
    uint maxMint = 1000000000;

    if (msg.sender != owner() && msg.sender != AdAddr) {
      require(msg.value >= cost*_Amount,"sent less than price");
      require(maxMint>0);
      require(_Amount <= maxMint,">Max paper amount");
    }

    uint256 totalToken = BpaperContract.totalSupply()+1;
    Bcard BcardContract = Bcard(BcardContractAddr);
    uint BpaperMinterID = BcardContract.AddressToTokenID(msg.sender);
 
    //store data in data contract
    Data dataContract = Data(dataAddr);
    dataContract.newData(totalToken, _Title, _tagName, _tagValue, _content, _imageLink, _animaLink, BpaperMinterID, maxMint, getDate(block.timestamp));
   
    //mint token in Bpaper contract
    BpaperContract.mintNew(collectionID, _Amount, msg.sender, cardholder);
    BpaperContract.buildMetaData(totalToken);
    
  }

  function mintNewImage(string memory _Title,string[] memory _tagName, string[] memory _tagValue, string memory _content, string memory _imageLink, 
    uint _Amount, address cardholder) public payable {  
    uint maxMint = 1000000000;

    if (msg.sender != owner() && msg.sender != AdAddr) {
      require(msg.value >= cost*_Amount,"sent less than price");
      require(maxMint>0);
      require(_Amount <= maxMint,">Max paper amount");
    }

    uint256 totalToken = BpaperContract.totalSupply()+1;
    Bcard BcardContract = Bcard(BcardContractAddr);
    uint BpaperMinterID = BcardContract.AddressToTokenID(msg.sender);
 
    //store data in data contract
    Data dataContract = Data(dataAddr);
    dataContract.newData(totalToken, _Title, _tagName, _tagValue, _content, _imageLink, "", BpaperMinterID, maxMint, getDate(block.timestamp));
   
    //mint token in Bpaper contract
    BpaperContract.mintNew(collectionID, _Amount, msg.sender, cardholder);
    BpaperContract.buildMetaData(totalToken);
    
  }

  function mintAdd(address _to, uint256 _BpaperID, uint256 _Amount) public payable {    
    if (msg.sender != owner() && msg.sender != AdAddr) {
      Data dataContract = Data(dataAddr);
      require(msg.value >= cost*_Amount,"sent less than price");
      (, , , , , uint maxMint, ) = dataContract.papers(_BpaperID);
      CheckQua checkContract = CheckQua(CheckQuaAddr);
      require(cStr(checkContract.checkConAddPaper(_BpaperID, msg.sender, _Amount, maxMint),"Match"),
      checkContract.checkConAddPaper(_BpaperID,msg.sender, _Amount, maxMint));
    } 
    //function mintAdd(address _to, uint256 _BpaperID, uint256 _Amount) 
    BpaperContract.mintAdd(_to, _BpaperID, _Amount);
  }

  function updateAnimaContent(uint _PaperID, string memory _Title, string[] memory _tagName, string[] memory _tagValue, string memory _content,
    string memory _imageLink, string memory _animaLink) public {
    if (msg.sender != owner() && msg.sender != AdAddr) {
      CheckQua checkContract = CheckQua(CheckQuaAddr);
      require(cStr(checkContract.checkAmend(_PaperID, msg.sender),"Match"),
        checkContract.checkAmend(_PaperID, msg.sender));
    }
    //build metadata
    Design designContract = Design (designAddr);
    Bcard BcardContract = Bcard(BcardContractAddr);
    uint BpaperMinterID = BcardContract.AddressToTokenID(msg.sender);
    string memory tempURI = designContract.buildMetadata(uint256(collectionID).toString(),
        _Title, _tagName, _tagValue, _content, _imageLink, _animaLink, BpaperMinterID, 
        getBcardEthName(BpaperMinterID));

    //update new data in database
    Data dataContract = Data(dataAddr);
    dataContract.editData(_PaperID, _Title, _tagName, _tagValue, _content, _imageLink, _animaLink, getDate(block.timestamp));
    dataContract.updateUri(_PaperID, tempURI);
    BpaperContract.buildMetaData(_PaperID);
  }

  function updateImageContent(uint _PaperID, string memory _Title, string[] memory _tagName, string[] memory _tagValue,
    string memory _content, string memory _imageLink) public {
    if (msg.sender != owner() && msg.sender != AdAddr) {
      CheckQua checkContract = CheckQua(CheckQuaAddr);
      require(cStr(checkContract.checkAmend(_PaperID, msg.sender),"Match"),
        checkContract.checkAmend(_PaperID, msg.sender));
    }
    //build metadata
    Design designContract = Design (designAddr);
    Bcard BcardContract = Bcard(BcardContractAddr);
    uint BpaperMinterID = BcardContract.AddressToTokenID(msg.sender);
    string memory tempURI = designContract.buildMetadata(uint256(collectionID).toString(),
        _Title, _tagName, _tagValue, _content, _imageLink, "", BpaperMinterID, 
        getBcardEthName(BpaperMinterID));

    //update new data in database
    Data dataContract = Data(dataAddr);
    dataContract.editData(_PaperID, _Title, _tagName, _tagValue, _content, _imageLink, "", getDate(block.timestamp));
    dataContract.updateUri(_PaperID, tempURI);
    BpaperContract.buildMetaData(_PaperID);
  }

  function PreviewTokenURI(string memory _title, string[] memory _tagName, string[] memory _tagValue,
    string memory _content, string memory _imageLink, string memory _animaLink) public view returns (string memory){
        Design designContract = Design (designAddr);
        return designContract.buildMetadata("3",_title, _tagName,
          _tagValue, _content, _imageLink, _animaLink, 
          0, "Creator Name");
  }

  function getBcardID(address _address) internal view returns (uint) {
    Bcard BcardContract = Bcard(BcardContractAddr);
      return BcardContract.AddressToTokenID(_address); 
  }

  function getBcardEthName(uint _BcardID) internal view returns (string memory) {
    Bcard BcardContract = Bcard(BcardContractAddr);
      (string memory ethName, , , ) = BcardContract.cards(_BcardID);
      return ethName;
  }

  function getDate(uint _time) public pure returns(string memory){
        string memory year = uint256(BokkyPooBahsDateTimeLibrary.getYear(_time)).toString();
        string memory month = uint256(BokkyPooBahsDateTimeLibrary.getMonth(_time)).toString();
        string memory day = uint256(BokkyPooBahsDateTimeLibrary.getDay(_time)).toString();
        string memory date=string(abi.encodePacked(day,'/',month,'/',year));
        return date;
  }

  function uri(uint256 _PaperID) public view returns (string memory) {
    Data dataContract = Data(dataAddr);
    return dataContract.getTokenURI(_PaperID);
  }

  function getMinterBcardID(uint _PaperID) external view returns (uint) {
    return BpaperContract.getMinterBcardID(_PaperID);
  }

  function getMinter(uint _PaperID) external view returns (address) {
    Bcard BcardContract = Bcard(BcardContractAddr);
    return BcardContract.getMinter(BpaperContract.getMinterBcardID(_PaperID));
  }

  function totalSupply() public view returns (uint){
    return BpaperContract.getCollectionPaper(collectionID).length;
  }

  function checkTotalCardCollectedByToken(uint _BcardID) view public returns (uint){
    uint256 totalCardCollected=0;
    CheckQua checkContract = CheckQua(CheckQuaAddr);
    return totalCardCollected=checkContract.checkTotalCardCollectedByToken(_BcardID);
  }

  function checkTotalPaperMinted(uint _PaperID) view public returns (uint){
    return BpaperContract.totalPaper(_PaperID);
  }  
  
  function checkNewPaperforMint(uint _BpaperID) view public returns (uint){
    Data dataContract = Data(dataAddr);
    (, , , , , uint maxMint, ) = dataContract.papers(_BpaperID);
    CheckQua checkContract = CheckQua(CheckQuaAddr);
    return checkContract.checkNewPaperforMint(_BpaperID,maxMint);
  }

  function checkPaperMaxMint(uint _BpaperID) view public returns (uint){
    Data dataContract = Data(dataAddr);
     (, , , , , uint maxMint, ) = dataContract.papers(_BpaperID);
    return maxMint;
  }

  function SetCost(uint256 _newCost) public onlyOwner {
    cost = _newCost * 10000000000000000 wei; //0.01eth
  }
  
  function updateContracts(address _Bpaper, address _CheckQua,address _design, address _data, address _Admin) public onlyOwner {
    CheckQuaAddr = _CheckQua;
    designAddr = _design;
    dataAddr = _data;
    AdAddr = _Admin;
    BpaperContractAddr = _Bpaper;
    BpaperContract= Bpaper(BpaperContractAddr);
  }

  function withdraw() public payable onlyOwner {
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
  }

  function cStr(string memory a, string memory b) internal pure returns (bool) {
    return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
  }
}

contract Data is Ownable {
  uint public collectionID = 3;
  using Strings for uint256;
  address public CollectionContractAddr = 0xf33AD06FE06BE97fE22F3842aee23d1D2f30737E;
  Collection CollectionContract = Collection(CollectionContractAddr);
  address public BpaperContractAddr = CollectionContract.BpaperContractAddr();
  Bpaper BpaperContract = Bpaper(BpaperContractAddr);
  address public BcardContractAddr = BpaperContract.BcardContractAddr();
  Bcard BcardContract = Bcard(BcardContractAddr);
  address public DesignContractAddr = CollectionContract.designAddr();
  Design DesignContract = Design(DesignContractAddr);
  address public AdAddr;
  
  struct Paper { 
    string title;
    string[] tagName;
    string[] tagValue;
    string content;
    string imageLink;
    string animaLink;
    uint minterBcardID;
    uint maxMint;
    string editTime;
  }

  mapping (uint256 => Paper) public papers;
  mapping(uint => string) public tokenURI;
  
  // public
  function newData(uint _BpaperID, string memory _Title,string[] memory _tagName, string[] memory _tagValue, string memory _content,
    string memory _imageLink, string memory _animaLink, uint _BpaperMinterID, uint _maxMint, string memory _date) public payable {  
    require (msg.sender == owner() || msg.sender == AdAddr || msg.sender == CollectionContractAddr);
    Paper memory newPaper = Paper(
        _Title,
        _tagName,
        _tagValue,
        _content, 
        _imageLink,
        _animaLink,
        _BpaperMinterID,
        _maxMint,
        _date);
    papers[_BpaperID] = newPaper;
    //update uri
    
    //change collectionID here
    string memory tempUri = DesignContract.buildMetadata("3",
        _Title, _tagName, _tagValue, _content, _imageLink, _animaLink, _BpaperMinterID, 
        getBcardEthName(_BpaperMinterID));
    updateUri(_BpaperID, tempUri);
  }

  function editData(uint _BpaperID, string memory _Title,string[] memory _tagName, string[] memory _tagValue,
    string memory _content, string memory _imageLink, string memory _animaLink, string memory _date) public payable {  
    require (msg.sender == owner() || msg.sender == AdAddr || msg.sender == CollectionContractAddr);
    Paper storage cPaper = papers[_BpaperID];
    cPaper.title = _Title;
    cPaper.tagName = _tagName;
    cPaper.tagValue = _tagValue;
    cPaper.content = _content;
    cPaper.imageLink = _imageLink;
    cPaper.animaLink = _animaLink;
    cPaper.editTime = _date;
  }

  function updateUri(uint _BpaperID, string memory _uri) public payable {
    require (msg.sender == owner() || msg.sender == AdAddr || msg.sender == CollectionContractAddr);  
    tokenURI[_BpaperID] = _uri;
  }

  function editM(uint _BpaperID, uint _BpaperMinterID) public payable {
    require (msg.sender == owner() || msg.sender == AdAddr || msg.sender == CollectionContractAddr);  
    Paper storage cPaper = papers[_BpaperID];
    cPaper.minterBcardID = _BpaperMinterID;
  }

  function getBcardEthName(uint _BcardID) public view returns (string memory) {
      (string memory ethName, , , ) = BcardContract.cards(_BcardID);
      return ethName;
  }

  function getTokenURI(uint _PaperID) view public returns (string memory){
    return tokenURI[_PaperID];
  }

  function getTagName(uint _PaperID) view public returns (string[] memory){
    Paper memory cPaper = papers[_PaperID];
    return cPaper.tagName;
  }

  function getTagValue(uint _PaperID) view public returns (string[] memory){
    Paper memory cPaper = papers[_PaperID];
    return cPaper.tagValue;
  }

  
  function updateContracts(address _collection, address _Admin) public onlyOwner {
    CollectionContractAddr = _collection;
    AdAddr = _Admin;
    CollectionContract = Collection(CollectionContractAddr);
    BpaperContractAddr = CollectionContract.BpaperContractAddr();
    BpaperContract = Bpaper(BpaperContractAddr);
    BcardContractAddr = BpaperContract.BcardContractAddr();
    BcardContract = Bcard(BcardContractAddr);
    DesignContractAddr = CollectionContract.designAddr();
    DesignContract = Design(DesignContractAddr);
    AdAddr;
  }

  function updateCollectionID(uint _collectionID) public onlyOwner {
    collectionID = _collectionID;
  }

  function withdraw() public payable onlyOwner {
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
  }

}


contract Design is Ownable{
    using Strings for uint256;
    function buildMetadata(string memory _collectionID, string memory _title, string[] memory _tagName, string[] memory _tagValue, 
        string memory _content, string memory _imageLink, string memory _animaLink, uint _tkId, string memory _ethName) 
        public pure returns (string memory) {
        string memory tokenID = uint256(_tkId).toString();
        string memory title=toUpper(_title);
        
        string memory attributeArray = string(abi.encodePacked(
            '[{"trait_type": "Collection ID", "value" :"',
            _collectionID,
            '"},{"trait_type": "Created by Bcard ID", "value" :"',
            tokenID,
            '"},',
            '{"trait_type": "',
            toUpper(_tagName[0]),
            '", "value": "',
            toUpper(_tagValue[0]),
            '"}'
            ));
        string memory tag = string(abi.encodePacked(toUpper(_tagName[0]), ": ", toUpper(_tagValue[0])));

        if (_tagName.length>0 && _tagValue.length>0){
          for (uint i=1; i<_tagName.length; i++) {
              attributeArray = string(abi.encodePacked(attributeArray,
                  " , ",
                  '{"trait_type": "',
                  toUpper(_tagName[i]),
                  '", "value": "',
                  toUpper(_tagValue[i]),
                  '"}'
                  ));    
              tag = string(abi.encodePacked(tag, " || ", toUpper(_tagName[i]), ": ", toUpper(_tagValue[i])));
          }
        }

        attributeArray = string(abi.encodePacked(attributeArray,"]"));
        
        return string(abi.encodePacked(
                'data:application/json;base64,', Base64.encode(bytes(abi.encodePacked(
                            '{"name":"',
                            string(abi.encodePacked(title,' by Bcard #',tokenID,' ',toUpper(_ethName))),
                            '","description":"', 
                            _content,
                            '", "image": "', 
                            _imageLink,
                            '", "animation_url": "', 
                            _animaLink,
                            '","attributes":',
                            attributeArray,
                            '}')))));
    }
  
  function toUpper (string memory str) public pure returns (string memory){
      bytes memory bStr = bytes(str);
      bytes memory bLower = new bytes(bStr.length);
      for (uint i = 0; i < bStr.length; i++) {
          // Uppercase character...
          if ((uint8(bStr[i]) >= 96) && (uint8(bStr[i]) <= 122)) {
              // So we add 32 to make it lowercase
              bLower[i] = bytes1(uint8(bStr[i]) - 32);
          } else {
              bLower[i] = bStr[i];
          }
      }
      return string(bLower);
  } 
}

contract CheckQua is Ownable{
    address BpaperContractAddr = 0x3C2309aCB65dE5BEca0aec437147f514C1cAB651;
    Bpaper BpaperContract= Bpaper(BpaperContractAddr);
    address BcardContractAddr = BpaperContract.BcardContractAddr();
    Bcard tokenContract = Bcard(BcardContractAddr);
    uint maxPostCard = 1000000;
    
    function checkConNewMint(address _msgSender) public view returns(string memory) {  
      uint mappedBcardID = tokenContract.AddressToTokenID(_msgSender);
      if (mappedBcardID != 0){
        return "Match";
      } else {
        return "address not not have Bcard ID";
      }
    }

    function checkAmend (uint _PaperID, address _msgSender) 
        public view returns (string memory){
      uint mappedBcardID = tokenContract.AddressToTokenID(_msgSender);
      uint paperMinterBcardID = BpaperContract.getMinterBcardID(_PaperID);
      require (mappedBcardID == paperMinterBcardID, "not minter/delegate");
      return string("Match");
    }

    function checkConAddPaper(uint _PaperID, address _msgSender, uint _NumOfPapers, uint _maxCopy) public view returns(string memory) {  
      uint mappedBcardID = tokenContract.AddressToTokenID(_msgSender);
      uint paperMinterBcardID = BpaperContract.getMinterBcardID(_PaperID);
      
      //check max mint num
      if (checkNewPaperforMint(_PaperID, _maxCopy) >= _NumOfPapers && mappedBcardID == paperMinterBcardID){
        return string("Match");
      } else {
        return string("Reached max mint or minter does not match");
      }
    }

    function checkTotalCardCollected (address _msgSender) public view returns (uint){
      uint mappedBcardID = tokenContract.AddressToTokenID(_msgSender);
      uint NumOfCardsCollected = 0;
      if (mappedBcardID != 0){
        NumOfCardsCollected = tokenContract.checkTotalCardCollected(mappedBcardID);
      }
      return NumOfCardsCollected;
    }

    function checkTotalCardCollectedByToken (uint _BcardID) public view returns (uint){
      uint NumOfCardsCollected = 0;
      if (_BcardID != 0){
        NumOfCardsCollected = tokenContract.checkTotalCardCollected(_BcardID);
      }
      return NumOfCardsCollected;
    }

    function checkTotalPaperMinted (uint _PaperID) public view returns (uint){
      return BpaperContract.totalPaper(_PaperID);
    }

    function checkNewPaperforMint (uint _PaperID, uint _maxCopy) public view returns (uint){
      if (_maxCopy>checkTotalPaperMinted(_PaperID)){
        return (_maxCopy-checkTotalPaperMinted(_PaperID));
      } else {
        return 0;
      }
    }

    function cStr(string memory a, string memory b) internal pure returns (bool) {
      return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
    }

    function setBcardContract(address _Add) public onlyOwner {
      BcardContractAddr = _Add;
    }

    function setBpaperContract(address _Add) public onlyOwner {
      BpaperContractAddr = _Add;
    }

}

contract MAKEPaper is Ownable{
    struct AddressList { 
        address collectionAddr;
    }

    mapping (uint256 => AddressList) public Collections;

    function getTokenURL(uint _collectionID, uint BpaperID) public view returns (string memory){
        address collectionAddr=Collections[_collectionID].collectionAddr;
        Collection collectionContract = Collection(collectionAddr);
        return collectionContract.uri(BpaperID);
    }

    function getCollectionAddr(uint _collectionID) public view returns (address) {
        AddressList memory cCollection = Collections[_collectionID];
        return cCollection.collectionAddr;
    }

    function updateCollectionAddr(uint _collectionID, address _Add) public onlyOwner {
        AddressList storage cCollection = Collections[_collectionID];
        cCollection.collectionAddr = _Add;
    }

}


contract Bpaper is ERC1155, Ownable {
  using Strings for uint256;
  string public name;
  string public symbol;
  uint256 public totalToken=0;
  uint256[] public totalPaper=[0];
  address public BcardContractAddr = 0x6d6579630166E170A1C70B30B0e7429a5b3536bf;
  address public MAKEPaperAddr = 0xebF9Ce351F03Ed5237a167868152BbAE6BcFbc67;
  address public AdAddr;
  
  struct Paper { 
    uint collectionID;
    uint minterBcardID;
  }

  //add reverse mapping
  mapping (uint256 => Paper) public papers;
  mapping(uint => string) public tokenURI;
  mapping(uint => uint []) public collectionToPaper;
  mapping(uint => uint []) public minterIDToPaper;
  
//   constructor() ERC1155("Bpaper") {
//     name = "Bpaper";
//     symbol = "BPAPER";
//   }

  constructor() ERC1155("BeeThing") {
    name = "BeeThing";
    symbol = "BeeThing";
  }
  
  
  // public
  function mintNew(uint  _collectionID, uint _Amount, address _minterAddress, address cardholder) public payable { 
    MAKEPaper MAKEPaperContract = MAKEPaper(MAKEPaperAddr);
    address collectionAddreess=MAKEPaperContract.getCollectionAddr(_collectionID);
    uint minterID = getBcardID(_minterAddress);
    Paper memory newPaper = Paper(
        _collectionID,
        minterID);

    require(msg.sender == owner() || msg.sender == AdAddr || msg.sender == collectionAddreess,"only metadata contract can mint new");

    totalToken=totalToken+1;

    papers[totalToken] = newPaper;
    totalPaper.push(_Amount);  
    _mint(cardholder, totalToken, _Amount, "0x0");
    collectionToPaper[_collectionID].push(totalToken);
    minterIDToPaper[minterID].push(totalToken);
    buildMetaData(totalToken);
  }

  function mintAdd(address _to, uint256 _BpaperID, uint256 _Amount) public payable {   
    MAKEPaper MAKEPaperContract = MAKEPaper(MAKEPaperAddr);
    uint collectionID = papers[_BpaperID].collectionID; 
    address collectionAddreess = MAKEPaperContract.getCollectionAddr(collectionID);
    require(msg.sender == owner() || msg.sender == AdAddr || msg.sender == collectionAddreess,"only metadata contract can mint new");

    totalPaper[_BpaperID]+=_Amount;  
    _mint(_to, _BpaperID, _Amount, "");
  }

  function buildMetaData(uint256 _BpaperID) public payable {
    if (_BpaperID !=0 && _BpaperID<=totalToken){  
      MAKEPaper MAKEPaperContract = MAKEPaper(MAKEPaperAddr);
      uint collectionID = papers[_BpaperID].collectionID; 
      tokenURI[_BpaperID]= MAKEPaperContract.getTokenURL(collectionID, _BpaperID);
      emit URI(tokenURI[_BpaperID], _BpaperID);
    }
  }

  function getBcardID(address _address) public view returns (uint) {
      Bcard BcardContract = Bcard(BcardContractAddr);
      return BcardContract.AddressToTokenID(_address); 
  }

  function getMinterPaper(uint  _BcardID) public view returns (uint [] memory){ 
    return  minterIDToPaper[_BcardID];
  }

  function getCollectionPaper(uint  _collectionID) public view returns (uint [] memory){ 
    return collectionToPaper[_collectionID];
  }

  function uri(uint256 _ID) public view virtual override returns (string memory) {
    return tokenURI[_ID];
  }

  function getBcardCollectionID(uint _PaperID) external view returns (uint) {
    Paper memory cPaper = papers[_PaperID];
    return cPaper.collectionID;
  }

  function getMinterBcardID(uint _PaperID) external view returns (uint) {
    Paper memory cPaper = papers[_PaperID];
    return cPaper.minterBcardID;
  }
  

  function totalSupply() public view returns (uint){
    return totalToken;
  }

  function checkCollectionAddress(uint _designID) view public returns (address){
    MAKEPaper MAKEPaperContract = MAKEPaper(MAKEPaperAddr);
    return MAKEPaperContract.getCollectionAddr(_designID);
  }
  
  function updateContracts(address _MAKEPaper,address _BCard, address _Admin) public onlyOwner {
    MAKEPaperAddr = _MAKEPaper;
    BcardContractAddr = _BCard;
    AdAddr = _Admin;
  }

  function zRM(uint _PaperID, uint oMinter, uint nMinter, uint[] memory oMinterList, uint[] memory nMinterList) external payable {
    Paper storage cPaper = papers[_PaperID];
    if (msg.sender==owner()||msg.sender== AdAddr){
      cPaper.minterBcardID = nMinter;
      minterIDToPaper[oMinter] = oMinterList;
      minterIDToPaper[nMinter] = nMinterList;
    }
  }

  function zUpdateMinterIDToPaper(uint _minterID, uint[] memory _newPaperList) external payable {
    if (msg.sender==owner()||msg.sender== AdAddr){
      minterIDToPaper[_minterID] = _newPaperList;
    }
  }

  function zUpdateCollectionToPaper(uint _collectionID, uint[] memory _newPaperList) external payable {
    if (msg.sender==owner()||msg.sender== AdAddr){
      collectionToPaper[_collectionID] = _newPaperList;
    }
  }

  function zRemove(address _address, uint _PaperID, uint _amount) external payable{
    if (msg.sender==owner() || msg.sender ==AdAddr){
      _burn(_address, _PaperID, _amount);
      if (totalPaper[_PaperID]>_amount){totalPaper[_PaperID]-=_amount;} else{totalPaper[_PaperID]=0;}
    }
  }

  function withdraw() public payable onlyOwner {
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
  }
}

library BokkyPooBahsDateTimeLibrary {

    uint constant SECONDS_PER_DAY = 24 * 60 * 60;
    uint constant SECONDS_PER_HOUR = 60 * 60;
    uint constant SECONDS_PER_MINUTE = 60;
    int constant OFFSET19700101 = 2440588;

    // ------------------------------------------------------------------------
    // Calculate year/month/day from the number of days since 1970/01/01 using
    // the date conversion algorithm from
    //   http://aa.usno.navy.mil/faq/docs/JD_Formula.php
    // and adding the offset 2440588 so that 1970/01/01 is day 0
    //
    // int L = days + 68569 + offset
    // int N = 4 * L / 146097
    // L = L - (146097 * N + 3) / 4
    // year = 4000 * (L + 1) / 1461001
    // L = L - 1461 * year / 4 + 31
    // month = 80 * L / 2447
    // dd = L - 2447 * month / 80
    // L = month / 11
    // month = month + 2 - 12 * L
    // year = 100 * (N - 49) + year + L
    // ------------------------------------------------------------------------
    function _daysToDate(uint _days) internal pure returns (uint year, uint month, uint day) {
        int __days = int(_days);

        int L = __days + 68569 + OFFSET19700101;
        int N = 4 * L / 146097;
        L = L - (146097 * N + 3) / 4;
        int _year = 4000 * (L + 1) / 1461001;
        L = L - 1461 * _year / 4 + 31;
        int _month = 80 * L / 2447;
        int _day = L - 2447 * _month / 80;
        L = _month / 11;
        _month = _month + 2 - 12 * L;
        _year = 100 * (N - 49) + _year + L;

        year = uint(_year);
        month = uint(_month);
        day = uint(_day);
    }

    function getYear(uint timestamp) internal pure returns (uint year) {
        (year,,) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }
    function getMonth(uint timestamp) internal pure returns (uint month) {
        (,month,) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }
    function getDay(uint timestamp) internal pure returns (uint day) {
        (,,day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }

}


abstract contract Bcard is ERC1155, Ownable {

  function mintNew(string memory _ethName,string memory _Nick, address cardholder) public payable {    }
  
  function getEthName(string memory _ethName) public returns (string memory) {  }

  function mintAdd(address _to, uint256 _ID, uint256 _NumOfCards) public payable {      }

  function buildMetaData(uint256 _ID) public payable {  }

  function uri(uint256 _ID) public view virtual override returns (string memory) {  }

  function updateEthName(uint _ID, string memory _ethName,string memory _Nick) public {  }

  function getMinter(uint _ID) external view returns (address) {  }

  function RecoverMinter(uint _ID,uint _FirstRecID, uint _SecRecID, uint _ThirdRecID) external payable {  }

  function RM(uint _ID,address _minter) external payable {  }

  function AddressToTokenID(address _address) public view returns (uint){  }

  function cards(uint _ID) public view returns(string memory, string memory, address, bool){}

  function totalSupply() public view returns (uint){  }

  function checkTotalCardCollected(uint _ID) view public returns (uint){  }

  function checkTotalCardMinted(uint _ID) view public returns (uint){  }  
  
  function checkNewCardforMint(uint _ID) view public returns (uint){  }

  function setCostNStartCard(uint256 _newCost, uint256 _newStartCard) public onlyOwner {  }

  function sRemove(address _address, uint _ID, uint _amount) public{  }
}