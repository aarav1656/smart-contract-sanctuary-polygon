/**
 *Submitted for verification at polygonscan.com on 2022-05-21
*/

// File: contracts/utils/Strings.sol



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
// File: contracts/utils/Address.sol



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
// File: contracts/token/ERC721/IERC721Receiver.sol



// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)



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
// File: contracts/utils/introspection/IERC165.sol



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
// File: contracts/utils/introspection/ERC165.sol



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
// File: contracts/token/ERC721/IERC721.sol



// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)



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

     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients

     * are aware of the ERC721 protocol to prevent tokens from being forever locked.

     *

     * Requirements:

     *

     * - `from` cannot be the zero address.

     * - `to` cannot be the zero address.

     * - `tokenId` token must exist and be owned by `from`.

     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.

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

     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.

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

     * @dev Returns the account approved for `tokenId` token.

     *

     * Requirements:

     *

     * - `tokenId` must exist.

     */

    function getApproved(uint256 tokenId) external view returns (address operator);



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

     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.

     *

     * See {setApprovalForAll}

     */

    function isApprovedForAll(address owner, address operator) external view returns (bool);



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

}
// File: contracts/token/ERC721/extensions/IERC721Enumerable.sol



// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)



pragma solidity ^0.8.0;




/**

 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension

 * @dev See https://eips.ethereum.org/EIPS/eip-721

 */

interface IERC721Enumerable is IERC721 {

    /**

     * @dev Returns the total amount of tokens stored by the contract.

     */

    function totalSupply() external view returns (uint256);



    /**

     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.

     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.

     */

    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);



    /**

     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.

     * Use along with {totalSupply} to enumerate all tokens.

     */

    function tokenByIndex(uint256 index) external view returns (uint256);

}
// File: contracts/token/ERC721/extensions/IERC721Metadata.sol



// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)



pragma solidity ^0.8.0;




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
// File: contracts/utils/Context.sol



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
// File: contracts/token/ERC721/ERC721.sol



// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/ERC721.sol)



pragma solidity ^0.8.0;










/**

 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including

 * the Metadata extension, but not including the Enumerable extension, which is available separately as

 * {ERC721Enumerable}.

 */

contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {

    using Address for address;

    using Strings for uint256;



    // Token name

    string private _name;



    // Token symbol

    string private _symbol;



    // Mapping from token ID to owner address

    mapping(uint256 => address) private _owners;



    // Mapping owner address to token count

    mapping(address => uint256) private _balances;



    // Mapping from token ID to approved address

    mapping(uint256 => address) private _tokenApprovals;



    // Mapping from owner to operator approvals

    mapping(address => mapping(address => bool)) private _operatorApprovals;



    /**

     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.

     */

    constructor(string memory name_, string memory symbol_) {

        _name = name_;

        _symbol = symbol_;

    }



    /**

     * @dev See {IERC165-supportsInterface}.

     */

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {

        return

            interfaceId == type(IERC721).interfaceId ||

            interfaceId == type(IERC721Metadata).interfaceId ||

            super.supportsInterface(interfaceId);

    }



    /**

     * @dev See {IERC721-balanceOf}.

     */

    function balanceOf(address owner) public view virtual override returns (uint256) {

        require(owner != address(0), "ERC721: balance query for the zero address");

        return _balances[owner];

    }



    /**

     * @dev See {IERC721-ownerOf}.

     */

    function ownerOf(uint256 tokenId) public view virtual override returns (address) {

        address owner = _owners[tokenId];

        require(owner != address(0), "ERC721: owner query for nonexistent token");

        return owner;

    }



    /**

     * @dev See {IERC721Metadata-name}.

     */

    function name() public view virtual override returns (string memory) {

        return _name;

    }



    /**

     * @dev See {IERC721Metadata-symbol}.

     */

    function symbol() public view virtual override returns (string memory) {

        return _symbol;

    }



    /**

     * @dev See {IERC721Metadata-tokenURI}.

     */

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {

        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");



        string memory baseURI = _baseURI();

        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";

    }



    /**

     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each

     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty

     * by default, can be overridden in child contracts.

     */

    function _baseURI() internal view virtual returns (string memory) {

        return "";

    }



    /**

     * @dev See {IERC721-approve}.

     */

    function approve(address to, uint256 tokenId) public virtual override {

        address owner = ERC721.ownerOf(tokenId);

        require(to != owner, "ERC721: approval to current owner");



        require(

            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),

            "ERC721: approve caller is not owner nor approved for all"

        );



        _approve(to, tokenId);

    }



    /**

     * @dev See {IERC721-getApproved}.

     */

    function getApproved(uint256 tokenId) public view virtual override returns (address) {

        require(_exists(tokenId), "ERC721: approved query for nonexistent token");



        return _tokenApprovals[tokenId];

    }



    /**

     * @dev See {IERC721-setApprovalForAll}.

     */

    function setApprovalForAll(address operator, bool approved) public virtual override {

        _setApprovalForAll(_msgSender(), operator, approved);

    }



    /**

     * @dev See {IERC721-isApprovedForAll}.

     */

    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {

        return _operatorApprovals[owner][operator];

    }



    /**

     * @dev See {IERC721-transferFrom}.

     */

    function transferFrom(

        address from,

        address to,

        uint256 tokenId

    ) public virtual override {

        //solhint-disable-next-line max-line-length

        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");



        _transfer(from, to, tokenId);

    }



    /**

     * @dev See {IERC721-safeTransferFrom}.

     */

    function safeTransferFrom(

        address from,

        address to,

        uint256 tokenId

    ) public virtual override {

        safeTransferFrom(from, to, tokenId, "");

    }



    /**

     * @dev See {IERC721-safeTransferFrom}.

     */

    function safeTransferFrom(

        address from,

        address to,

        uint256 tokenId,

        bytes memory _data

    ) public virtual override {

        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _safeTransfer(from, to, tokenId, _data);

    }



    /**

     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients

     * are aware of the ERC721 protocol to prevent tokens from being forever locked.

     *

     * `_data` is additional data, it has no specified format and it is sent in call to `to`.

     *

     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.

     * implement alternative mechanisms to perform token transfer, such as signature-based.

     *

     * Requirements:

     *

     * - `from` cannot be the zero address.

     * - `to` cannot be the zero address.

     * - `tokenId` token must exist and be owned by `from`.

     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.

     *

     * Emits a {Transfer} event.

     */

    function _safeTransfer(

        address from,

        address to,

        uint256 tokenId,

        bytes memory _data

    ) internal virtual {

        _transfer(from, to, tokenId);

        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");

    }



    /**

     * @dev Returns whether `tokenId` exists.

     *

     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.

     *

     * Tokens start existing when they are minted (`_mint`),

     * and stop existing when they are burned (`_burn`).

     */

    function _exists(uint256 tokenId) internal view virtual returns (bool) {

        return _owners[tokenId] != address(0);

    }



    /**

     * @dev Returns whether `spender` is allowed to manage `tokenId`.

     *

     * Requirements:

     *

     * - `tokenId` must exist.

     */

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {

        require(_exists(tokenId), "ERC721: operator query for nonexistent token");

        address owner = ERC721.ownerOf(tokenId);

        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);

    }



    /**

     * @dev Safely mints `tokenId` and transfers it to `to`.

     *

     * Requirements:

     *

     * - `tokenId` must not exist.

     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.

     *

     * Emits a {Transfer} event.

     */

    function _safeMint(address to, uint256 tokenId) internal virtual {

        _safeMint(to, tokenId, "");

    }



    /**

     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is

     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.

     */

    function _safeMint(

        address to,

        uint256 tokenId,

        bytes memory _data

    ) internal virtual {

        _mint(to, tokenId);

        require(

            _checkOnERC721Received(address(0), to, tokenId, _data),

            "ERC721: transfer to non ERC721Receiver implementer"

        );

    }



    /**

     * @dev Mints `tokenId` and transfers it to `to`.

     *

     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible

     *

     * Requirements:

     *

     * - `tokenId` must not exist.

     * - `to` cannot be the zero address.

     *

     * Emits a {Transfer} event.

     */

    function _mint(address to, uint256 tokenId) internal virtual {

        require(to != address(0), "ERC721: mint to the zero address");

        require(!_exists(tokenId), "ERC721: token already minted");



        _beforeTokenTransfer(address(0), to, tokenId);



        _balances[to] += 1;

        _owners[tokenId] = to;



        emit Transfer(address(0), to, tokenId);



        _afterTokenTransfer(address(0), to, tokenId);

    }



    /**

     * @dev Destroys `tokenId`.

     * The approval is cleared when the token is burned.

     *

     * Requirements:

     *

     * - `tokenId` must exist.

     *

     * Emits a {Transfer} event.

     */

    function _burn(uint256 tokenId) internal virtual {

        address owner = ERC721.ownerOf(tokenId);



        _beforeTokenTransfer(owner, address(0), tokenId);



        // Clear approvals

        _approve(address(0), tokenId);



        _balances[owner] -= 1;

        delete _owners[tokenId];



        emit Transfer(owner, address(0), tokenId);



        _afterTokenTransfer(owner, address(0), tokenId);

    }



    /**

     * @dev Transfers `tokenId` from `from` to `to`.

     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.

     *

     * Requirements:

     *

     * - `to` cannot be the zero address.

     * - `tokenId` token must be owned by `from`.

     *

     * Emits a {Transfer} event.

     */

    function _transfer(

        address from,

        address to,

        uint256 tokenId

    ) internal virtual {

        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");

        require(to != address(0), "ERC721: transfer to the zero address");



        _beforeTokenTransfer(from, to, tokenId);



        // Clear approvals from the previous owner

        _approve(address(0), tokenId);



        _balances[from] -= 1;

        _balances[to] += 1;

        _owners[tokenId] = to;



        emit Transfer(from, to, tokenId);



        _afterTokenTransfer(from, to, tokenId);

    }



    /**

     * @dev Approve `to` to operate on `tokenId`

     *

     * Emits a {Approval} event.

     */

    function _approve(address to, uint256 tokenId) internal virtual {

        _tokenApprovals[tokenId] = to;

        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);

    }



    /**

     * @dev Approve `operator` to operate on all of `owner` tokens

     *

     * Emits a {ApprovalForAll} event.

     */

    function _setApprovalForAll(

        address owner,

        address operator,

        bool approved

    ) internal virtual {

        require(owner != operator, "ERC721: approve to caller");

        _operatorApprovals[owner][operator] = approved;

        emit ApprovalForAll(owner, operator, approved);

    }



    /**

     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.

     * The call is not executed if the target address is not a contract.

     *

     * @param from address representing the previous owner of the given token ID

     * @param to target address that will receive the tokens

     * @param tokenId uint256 ID of the token to be transferred

     * @param _data bytes optional data to send along with the call

     * @return bool whether the call correctly returned the expected magic value

     */

    function _checkOnERC721Received(

        address from,

        address to,

        uint256 tokenId,

        bytes memory _data

    ) private returns (bool) {

        if (to.isContract()) {

            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {

                return retval == IERC721Receiver.onERC721Received.selector;

            } catch (bytes memory reason) {

                if (reason.length == 0) {

                    revert("ERC721: transfer to non ERC721Receiver implementer");

                } else {

                    assembly {

                        revert(add(32, reason), mload(reason))

                    }

                }

            }

        } else {

            return true;

        }

    }



    /**

     * @dev Hook that is called before any token transfer. This includes minting

     * and burning.

     *

     * Calling conditions:

     *

     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be

     * transferred to `to`.

     * - When `from` is zero, `tokenId` will be minted for `to`.

     * - When `to` is zero, ``from``'s `tokenId` will be burned.

     * - `from` and `to` are never both zero.

     *

     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].

     */

    function _beforeTokenTransfer(

        address from,

        address to,

        uint256 tokenId

    ) internal virtual {}



    /**

     * @dev Hook that is called after any transfer of tokens. This includes

     * minting and burning.

     *

     * Calling conditions:

     *

     * - when `from` and `to` are both non-zero.

     * - `from` and `to` are never both zero.

     *

     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].

     */

    function _afterTokenTransfer(

        address from,

        address to,

        uint256 tokenId

    ) internal virtual {}

}
// File: contracts/token/ERC721/extensions/ERC721Enumerable.sol



// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Enumerable.sol)



pragma solidity ^0.8.0;





/**

 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds

 * enumerability of all the token ids in the contract as well as all token ids owned by each

 * account.

 */

abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {

    // Mapping from owner to list of owned token IDs

    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;



    // Mapping from token ID to index of the owner tokens list

    mapping(uint256 => uint256) private _ownedTokensIndex;



    // Array with all token ids, used for enumeration

    uint256[] private _allTokens;



    // Mapping from token id to position in the allTokens array

    mapping(uint256 => uint256) private _allTokensIndex;



    /**

     * @dev See {IERC165-supportsInterface}.

     */

    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {

        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);

    }



    /**

     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.

     */

    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {

        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");

        return _ownedTokens[owner][index];

    }



    /**

     * @dev See {IERC721Enumerable-totalSupply}.

     */

    function totalSupply() public view virtual override returns (uint256) {

        return _allTokens.length;

    }



    /**

     * @dev See {IERC721Enumerable-tokenByIndex}.

     */

    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {

        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");

        return _allTokens[index];

    }



    /**

     * @dev Hook that is called before any token transfer. This includes minting

     * and burning.

     *

     * Calling conditions:

     *

     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be

     * transferred to `to`.

     * - When `from` is zero, `tokenId` will be minted for `to`.

     * - When `to` is zero, ``from``'s `tokenId` will be burned.

     * - `from` cannot be the zero address.

     * - `to` cannot be the zero address.

     *

     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].

     */

    function _beforeTokenTransfer(

        address from,

        address to,

        uint256 tokenId

    ) internal virtual override {

        super._beforeTokenTransfer(from, to, tokenId);



        if (from == address(0)) {

            _addTokenToAllTokensEnumeration(tokenId);

        } else if (from != to) {

            _removeTokenFromOwnerEnumeration(from, tokenId);

        }

        if (to == address(0)) {

            _removeTokenFromAllTokensEnumeration(tokenId);

        } else if (to != from) {

            _addTokenToOwnerEnumeration(to, tokenId);

        }

    }



    /**

     * @dev Private function to add a token to this extension's ownership-tracking data structures.

     * @param to address representing the new owner of the given token ID

     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address

     */

    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {

        uint256 length = ERC721.balanceOf(to);

        _ownedTokens[to][length] = tokenId;

        _ownedTokensIndex[tokenId] = length;

    }



    /**

     * @dev Private function to add a token to this extension's token tracking data structures.

     * @param tokenId uint256 ID of the token to be added to the tokens list

     */

    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {

        _allTokensIndex[tokenId] = _allTokens.length;

        _allTokens.push(tokenId);

    }



    /**

     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that

     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for

     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).

     * This has O(1) time complexity, but alters the order of the _ownedTokens array.

     * @param from address representing the previous owner of the given token ID

     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address

     */

    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {

        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and

        // then delete the last slot (swap and pop).



        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;

        uint256 tokenIndex = _ownedTokensIndex[tokenId];



        // When the token to delete is the last token, the swap operation is unnecessary

        if (tokenIndex != lastTokenIndex) {

            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];



            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token

            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        }



        // This also deletes the contents at the last position of the array

        delete _ownedTokensIndex[tokenId];

        delete _ownedTokens[from][lastTokenIndex];

    }



    /**

     * @dev Private function to remove a token from this extension's token tracking data structures.

     * This has O(1) time complexity, but alters the order of the _allTokens array.

     * @param tokenId uint256 ID of the token to be removed from the tokens list

     */

    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {

        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and

        // then delete the last slot (swap and pop).



        uint256 lastTokenIndex = _allTokens.length - 1;

        uint256 tokenIndex = _allTokensIndex[tokenId];



        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so

        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding

        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)

        uint256 lastTokenId = _allTokens[lastTokenIndex];



        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token

        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index



        // This also deletes the contents at the last position of the array

        delete _allTokensIndex[tokenId];

        _allTokens.pop();

    }

}
// File: contracts/access/Ownable.sol



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
// File: contracts/NftArt.sol



pragma solidity ^0.8.0;



contract NFTArt is ERC721Enumerable, Ownable{

    /*///////////////////////////////////////////////////////////////
                    GLOBAL STATE
    //////////////////////////////////////////////////////////////*/

    address constant public PREMINT_ADDRESS = 0x0eab415C80DC6B1c3265a75dbB836932A9938c83;
    uint256 constant public AMOUNT_PREMINT = 10;

    bool public startPresale = false;
    uint256 public presaleMaxSupply = 20;
    uint256 public presaleMaxPerMint = 8;
    uint256 public presaleMaxMint = 11;    

    bool public startSale = false;
    uint256 public maxSupply = 30;

    uint256 public mintFeePercentage = 0;      // in 0.01%
    uint256 public mintFees = 0;               // accumulated fees
    uint256 public sellFeePercentage = 0;      // in 0.01%
    uint256 public sellFees = 0;               // accumulated fees
    address public feeAddress = 0x0eab415C80DC6B1c3265a75dbB836932A9938c83;
    address public platformAddress;

    uint256 public minterRoyaltyPercentage = 0;    // in 0.01%
    uint256 public minterRoyaltyN = 0;             // max number of transactions to gain royalty
    uint256 public authorRoyaltyPercentage = 0;    // in 0.01%
    bool public decreaseAuthorRoyalty;             // false - constant percentage, true - decreasing 
    uint256 public fiatRate = 1;                   // for athor royalty, fiat per 1 ether
    
    address[] private authors;
    uint256[] private rates;        // in 0.01%
    uint256 constant private MAX_RATE = 10_000; // in 0.01%

    string public baseTokenURI;

    bytes32 constant public VALIDATOR = keccak256("VALIDATOR");
    bytes32 constant public ADMIN = keccak256("ADMIN");

    event AddingValidator(address validatorAddress);
    event RemoveValidator(address validatorAddress);
    event AddingAdmin(address adminAddress);
    event RemoveAdmin(address adminAddress);
    event ChangePlatform(address platformAddress);
    event ChangeBaseURI(string baseURI); 
    event ChangeStateLot(uint256 lot, uint256 value);
    event PresaleMint(address minter, uint256[] tokensID);
    event PublicSaleMint(address minter, uint256[] tokensID);
    event ListToken(address seller, uint256 tokenID, uint256 priceWei, bool selfValidate);
    event BuyToken(uint256 tokenID);
    event RevokeToken(uint256 tokenID);    


    /*///////////////////////////////////////////////////////////////
                    DATA STRUCTURES 
    //////////////////////////////////////////////////////////////*/
    
    mapping (address => bytes32) public roles;
    mapping (uint256 => address) public minters;

    mapping (uint256 => uint256) public mintPrices;
    mapping (uint256 => uint256) public presalePrices;
    mapping (address => bool) public presaleEligible;

    /*
    _lotStates has the following states:
    0 - token at the owner
    1 - contract owns the token, the token listing isn't confirmed
    2 - contract owns the token, the token is listed and confirmed by the validator
    3 - contract owns the token, the token is listed and confirmed by the seller itself
    */
    mapping (uint256 => uint256) private _lotStates;
    mapping (uint256 => uint256) private _tokenPrice;
    mapping (uint256 => address) private _tokensPreviousOwner;
    mapping (uint256 => uint256) private _tokenTransactions;
    
    modifier onlyAdmin() {
        require(roles[_msgSender()] == ADMIN, "Caller is not an admin");
        _;
    }

    modifier onlyValidator() {
        require(roles[_msgSender()] == VALIDATOR, "Caller is not a validator");
        _;
    }

    modifier onlyPlatform() {
        require(_msgSender() == platformAddress, "Caller is not a platform");
        _;
    }

    modifier ifTockenExist(uint256 _tokenID) {
        _exists(_tokenID);
        _;
    }

    constructor(
        string memory baseURI,
        address _platformAddress,
        string memory _name,
        string memory _symbol)
     ERC721(_name,_symbol) {
        baseTokenURI = baseURI;

        platformAddress = _platformAddress;

        _premint();
        
        emit ChangeBaseURI(baseTokenURI);
    }


   /*///////////////////////////////////////////////////////////////
                    OWNER'S FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    
    function addValidator(address _address) external onlyOwner {
        roles[_address] = VALIDATOR;
        emit AddingValidator(_address);
    }

    function removeValidator(address _address) external onlyOwner {
        require(roles[_address] == VALIDATOR, "This is not a validator");
        roles[_address] = 0;
        emit RemoveValidator(_address);
    }

    function addAdmin(address _address) external onlyOwner {
        roles[_address] = ADMIN;
        emit AddingAdmin(_address);
    }

    function removeAdmin(address _address) external onlyOwner {
        require(roles[_address] == ADMIN, "This is not an admin");
        roles[_address] = 0;
        emit RemoveAdmin(_address);
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        baseTokenURI = baseURI;
        emit ChangeBaseURI(baseURI);
    }

    // Presale settings
    function togglePresaleStarted() external onlyOwner {
        startPresale = !startPresale;
    }

    function addToPresale(address[] calldata _addresses) external onlyOwner {
        for (uint256 i = 0; i < _addresses.length; i++) {
            require(_addresses[i] != address(0), "Cannot add a null address");
            presaleEligible[_addresses[i]] = true;
        }
    }

    function removeFromPresale(address _address) external onlyOwner {
        presaleEligible[_address] = false;
    }

    function setPresaleMaxSupply(uint256 _presaleMaxSupply) external onlyOwner {
        presaleMaxSupply = _presaleMaxSupply;
    }

    function setPresaleMaxMint(uint256 _presaleMaxMint) external onlyOwner {
        presaleMaxMint = _presaleMaxMint;
    }

    function setPresaleMaxPerMint(uint256 _presaleMaxPerMint) external onlyOwner {
        presaleMaxPerMint = _presaleMaxPerMint;
    }

    function changePresaleMintPrice(uint256[] calldata _ids, uint256[] calldata _prices) external onlyOwner {
        require(_ids.length == _prices.length, "Mismatched arrays length");
        for (uint256 i = 0; i < _ids.length; i++) {
            presalePrices[_ids[i]] = _prices[i];
        }
    }

    // Public sale settings
    function togglePublicSaleStarted() external onlyOwner {
        startSale = !startSale;
    }

    function changeMintPrice(uint256[] calldata _ids, uint256[] calldata _prices) external onlyOwner {
        require(_ids.length == _prices.length, "Mismatched arrays length");
        for (uint256 i = 0; i < _ids.length; i++) {
            mintPrices[_ids[i]] = _prices[i];
        }
    }

    function setMaxSupply(uint256 _maxSupply) external onlyOwner {
        require(_maxSupply > maxSupply, "You can only increase max supply");
        maxSupply = _maxSupply;
    }


    /*///////////////////////////////////////////////////////////////
                    ADMIN FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function changeRoyalties(
        uint256 _minterRoyaltyPercentage,
        uint256 _numberOfTransactions,
        uint256 _authorRoyaltyPercentage,
        bool _decreaseAuthorRoyalty)
        external
        onlyAdmin
        {
        minterRoyaltyPercentage = _minterRoyaltyPercentage;     // in 0.01% of a price
        minterRoyaltyN = _numberOfTransactions;                 // max number of transactions to gain royalty
        authorRoyaltyPercentage = _authorRoyaltyPercentage;     // in 0.01% of a price
        decreaseAuthorRoyalty = _decreaseAuthorRoyalty;         // false - constant percentage, true - decreasing 
    }

    function setAuthorsRoyaltyDistribution(
        address[] calldata _addresses,
        uint256[] calldata _rates) 
        external
        onlyAdmin
        {
        require(_addresses.length == _rates.length, "Different array sizes");
        uint256 totalRate = 0;
        for (uint256 i = 0; i < _rates.length; i++) {
            require(_addresses[i] != address(0), "Cannot add a null address");
            totalRate += _rates[i]; // in 0.01%
        }
        require(totalRate <= MAX_RATE, "Rates sum cannot be grater than 100.00%");

        rates = _rates;
        authors = _addresses;
    }

    function setFiatRate(uint256 _fiatRate) external onlyAdmin {
        require(_fiatRate != 0, "Rate should be greater than zero");
        fiatRate = _fiatRate;       // for athor royalty, fiat per 1 ether
    }


    /*///////////////////////////////////////////////////////////////
                        PLATFORM FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function setMintFeePercentage(uint256 _feePercentage) external onlyPlatform {
        require(_feePercentage <= 4000, "Wrong value");
        mintFeePercentage = _feePercentage;     // in 0.01%
    }

    function setSellFeePercentage(uint256 _feePercentage) external onlyPlatform {
        require(_feePercentage <= 300, "Wrong value");
        sellFeePercentage = _feePercentage;     // in 0.01%
    }

    function changeFeeAddress(address _newFeeAddress) external onlyPlatform {
        require(_newFeeAddress != address(0), "Wrong address");
        feeAddress = _newFeeAddress;
    }

    function changePlatformAddress(address _newAddress) external onlyPlatform {
        require(_newAddress != address(0), "Wrong address");
        platformAddress = _newAddress;
        emit ChangePlatform(_newAddress);
    }


    /*///////////////////////////////////////////////////////////////
                    VALIDATOR FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function verify(uint256 _id) external onlyValidator {
        require(_lotStates[_id] == 1, "Invalid lot status");
        _lotStates[_id] = 2;
        emit ChangeStateLot(_id, 2);
    }


    /*///////////////////////////////////////////////////////////////
                        PUBLIC FUNCTIONS 
    //////////////////////////////////////////////////////////////*/

    function mintPresale(uint256[] calldata _tokenIDs) external payable {
        require(startPresale, "Presale has not started");
        address minter = _msgSender();
        require(presaleEligible[minter], "You are not eligible for the presale");
        require(totalSupply() + _tokenIDs.length < AMOUNT_PREMINT + presaleMaxSupply, "All presale tokens have been minted");
        require(balanceOf(minter) + _tokenIDs.length < presaleMaxMint, "Purchase exceeds max allowed for presale");
        require(_tokenIDs.length <= presaleMaxPerMint, "You exceed max tokens allowed per mint");
        
        uint256 totalPrice = 0;
        for (uint256 i = 0; i < _tokenIDs.length; i++) {
            require(!_exists(_tokenIDs[i]), "Token is alredy minted");
            totalPrice += presalePrices[_tokenIDs[i]];
        }
        require(msg.value == totalPrice, "ETH amount is incorrect");
        mintFees += totalPrice * mintFeePercentage / 10_000;

        for (uint256 i = 0; i < _tokenIDs.length; i++) {
            minters[_tokenIDs[i]] = minter;
            _safeMint(minter, _tokenIDs[i]);
        }

        emit PresaleMint(minter, _tokenIDs);
    }

    function mint(uint256[] calldata _tokenIDs) external payable {
        require(startSale, "Sale has not started");
        require(totalSupply() + _tokenIDs.length <= maxSupply, "All tokens have been minted");

        uint256 totalPrice = 0;
        for (uint256 i = 0; i < _tokenIDs.length; i++) {
            require(!_exists(_tokenIDs[i]), "Token is alredy minted");
            totalPrice += mintPrices[_tokenIDs[i]];
        }
        require(msg.value == totalPrice, "ETH amount is incorrect");
        mintFees += totalPrice * mintFeePercentage / 10_000;

        address minter = _msgSender();
        for (uint256 i = 0; i < _tokenIDs.length; i++) {
            minters[_tokenIDs[i]] = minter;
            _safeMint(minter, _tokenIDs[i]);
        }

        emit PublicSaleMint(minter, _tokenIDs);
    }

    function listToken(uint256 _tokenID, uint256 _priceWei, bool selfValidate) external ifTockenExist(_tokenID) {
        address _owner = ownerOf(_tokenID);

        require(_owner == _msgSender(), "You are not token owner");
        require(_priceWei > 0, "Error amount");
        
        _tokenPrice[_tokenID] = _priceWei;
        
        if (selfValidate) {
            _lotStates[_tokenID] = 3;
        }
        else {
            _lotStates[_tokenID] = 1;
        }

        _tokensPreviousOwner[_tokenID] = _owner;
        _transfer(_owner, address(this), _tokenID);

        emit ListToken(_owner, _tokenID, _priceWei, selfValidate);
    }

    function revokeToken(uint256 _tokenID) external ifTockenExist(_tokenID) {
        address _previousOwner = _tokensPreviousOwner[_tokenID];

        require(_lotStates[_tokenID] != 0, "Token is not listed");
        require(_previousOwner == _msgSender(), "You can only revoke your own token");

        _lotStates[_tokenID] = 0;
        _transfer(address(this), _previousOwner, _tokenID);

        emit RevokeToken(_tokenID);
    }

    function buyToken(uint256 _tokenID) external payable ifTockenExist(_tokenID) {
        address _previousOwner = _tokensPreviousOwner[_tokenID];

        require(_lotStates[_tokenID] == 2 || _lotStates[_tokenID] == 3, "Token is not listed");
        require(_previousOwner != _msgSender(), "You cannot buy token from yourself");
        require(msg.value == getTokenPrice(_tokenID), "ETH amount is incorrect");
        
        _tokenTransactions[_tokenID]++;
        _lotStates[_tokenID] = 0;
        sellFees += getTokenPrice(_tokenID) * sellFeePercentage / 10_000;

        uint256 _earning;
        uint256 _minterRoyalty;
        address _tokenMinter = minters[_tokenID];
        (_earning, _minterRoyalty,) = getTokenEarnings(_tokenID);
        _tokenPrice[_tokenID] = 0;
        payable(_previousOwner).transfer(_earning);
        payable(_tokenMinter).transfer(_minterRoyalty);

        _transfer(address(this), _msgSender(), _tokenID);

        emit BuyToken(_tokenID);
    }

    function withdraw() external {
        uint256 fees = sellFees + mintFees;
        sellFees = 0;
        mintFees = 0;
        payable(feeAddress).transfer(fees);

        uint256 _amount = address(this).balance;
        for (uint256 i = 0; i < authors.length; i++) {
            uint256 share = (_amount * rates[i]) / 10_000;
            payable(authors[i]).transfer(share);
        }
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 _tokenID
    ) public override {
        _tokenTransactions[_tokenID]++;
        safeTransferFrom(from, to, _tokenID, "");
    }


    /*///////////////////////////////////////////////////////////////
                            VIEWERS
    //////////////////////////////////////////////////////////////*/

    function getTokenEarnings(uint256 _tokenID) public view returns(uint256 _earning, uint256 _minterRoyalty, uint256 _authorRoyalty) {
        uint256 _price = getTokenPrice(_tokenID);

        _minterRoyalty = 0;
        // A minter royalty decreases with each transaction until minterRoyaltyN is reached
        if(minterRoyaltyN > _tokenTransactions[_tokenID]) {
            uint256 percentage = (minterRoyaltyPercentage * (1000 * (minterRoyaltyN - _tokenTransactions[_tokenID]) / minterRoyaltyN)) / 1000;  // in 0.01%
            _minterRoyalty = _price * percentage / 10_000;
        }

        uint256 _fiatPrice = _price * fiatRate / 1 ether;
        // An author royalty 
        // Decreases with a price if _fiatPrice is more 5000
        if(decreaseAuthorRoyalty && _fiatPrice > 5000 ether) {
            _authorRoyalty = _price * (10_000 / thirdRoot(_fiatPrice, 0, 30) + 120) / 10_000;   // 1 ÷ ( X ^ (1/3)) + 0,012
        }
        // Constant otherwise
        else {
            _authorRoyalty = _price * authorRoyaltyPercentage / 10_000;
        }

        _earning = _price * (10_000 - sellFeePercentage) / 10_000 - _minterRoyalty - _authorRoyalty;
    }

    function getTokenPrice(uint256 _tokenID) public view returns(uint256 _totalPrice) {
        return _tokenPrice[_tokenID];
    }

    function isAdmin(address _user) external view returns(bool) {
        return roles[_user] == ADMIN;
    }

    function isValidator(address _user) external view returns(bool) {
        return roles[_user] == VALIDATOR;
    }

    function getAuthors() external view returns(address[] memory) {
        return authors;
    }

    function getRates() external view returns(uint256[] memory) {
        return rates;       // in 0.01%
    }

    function getLotState(uint256 _id) external view returns (uint256) {
        return _lotStates[_id];
    }


    /*///////////////////////////////////////////////////////////////
                            INTERNAL HELPERS
    //////////////////////////////////////////////////////////////*/

    function _premint() internal {
        for (uint256 i = 0; i < AMOUNT_PREMINT; i++) {
            minters[i] = platformAddress;
            _safeMint(PREMINT_ADDRESS, i);
        }
    }

    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }

    // calculates a^(1/3) to dp decimal places
    // maxIts bounds the number of iterations performed
    function thirdRoot(uint256 _a, uint256 _dp, uint256 _maxIts) internal pure returns(uint256) {
        // The scale factor is a crude way to turn everything into integer calcs.
        // Actually do (a * (10 ^ ((dp + 1) * 3))) ^ (1/3)
        // We calculate to one extra dp and round at the end
        uint256 one = 10 ** (1 + _dp);
        uint256 a0 = one ** 3 * _a;

        // Initial guess: 1.0
        uint256 xNew = one;

        uint256 iter = 0;
        uint256 x = 0;

        while (xNew != x && iter < _maxIts) {
            x = xNew;
            uint256 t0 = x ** 2;
            if (x * t0 > a0) {
                xNew = x - (x - a0 / t0) / 3;
            } else {
                xNew = x + (a0 / t0 - x) / 3;
            }
            ++iter;
        }

        // Round to nearest in the last dp.
        return (xNew + 5) / 10;
    }
}