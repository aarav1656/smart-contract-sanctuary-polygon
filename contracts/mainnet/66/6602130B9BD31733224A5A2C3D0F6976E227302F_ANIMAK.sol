/**
 *Submitted for verification at polygonscan.com on 2021-12-28
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.7 <0.9.0;

//import "../../utils/Context.sol";
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}


//import "@openzeppelin/contracts/access/Ownable.sol";
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


//import "./IERC721Receiver.sol";
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}


//import "../../utils/Address.sol";
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


//import "../../utils/Strings.sol";
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


//import "./IERC165.sol";
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


//import "../../utils/introspection/ERC165.sol";
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}


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


//import "./extensions/IERC721Metadata.sol";
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


//import "../ERC721.sol";
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
     * by default, can be overriden in child contracts.
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
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
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
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
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
}


//import "./IERC721Enumerable.sol";
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
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}


//import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
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


//import "./Common/IANIMAK.sol";
interface IANIMAK {
    //--------------------------------------
    // イベント
    //--------------------------------------
    event TokenCreated( uint256 indexed tokenId, uint256 rarity, address indexed owner );

    event NameUpdated( uint256 indexed tokenId, string name );
    event DescriptionUpdated( uint256 indexed tokenId, string description );
    event FolderUpdated( uint256 indexed tokenId, string folder );
    event AvatarUpdated( uint256 indexed tokenId, string avatar );
    event ImageUpdated( uint256 indexed tokenId, string image );
    event HtmlUpdated( uint256 indexed tokenId, string html );
    event AttributeAdded( uint256 indexed tokenId, string attribute );
    event AtttributeRemoved( uint256 indexed tokenId, string attribute );

    //--------------------------------------
    // MINT
    //--------------------------------------
    function createToken( uint256 tokenId, uint256 rarity, string[] calldata attributes, address holder ) external;

    //--------------------------------------
    // 情報の設定
    //--------------------------------------
    function setNmae( uint256 tokenId, string calldata name ) external;
    function setDescription( uint256 tokenId, string calldata description ) external;
    function setFolder( uint256 tokenId, string calldata folder ) external;
    function setAvatar( uint256 tokenId, string calldata avatar ) external;
    function setImage( uint256 tokenId, string calldata image ) external;
    function setHtml( uint256 tokenId, string calldata html ) external;
    function addAttribute( uint256 tokenId, string calldata attribute ) external;
    function removeAttribute( uint256 tokenId, string calldata attribute ) external;

    //--------------------------------------
    // 情報の取得
    //--------------------------------------
    function getRarity( uint256 tokenId ) external returns (uint256);
}


//import "./Common/IManager.sol";
interface IManager {
    //--------------------------------------
    // event
    //--------------------------------------
    event CoinCreated( uint256 indexed coinId, address indexed coinAddress );
    event Donated( uint256 indexed tokenId, uint256 indexed amount, uint256 indexed total );

    //--------------------------------------
    // 参照
    //--------------------------------------
    function getConfigAddress() external view returns (address);
    function getTotalDonated( uint256 coinId ) external view returns (uint256);

    //--------------------------------------    
    // NFTの発行
    //--------------------------------------
    function mintIdol( uint256 tokenId, uint256 rarity, string[] calldata attributes, address holder ) external;

    //--------------------------------------
    // NFTの操作
    //--------------------------------------
    function setIdolNmae( uint256 tokenId, string calldata name ) external;
    function setIdolDescription( uint256 tokenId, string calldata description ) external;
    function setIdolFolder( uint256 tokenId, string calldata folder ) external;
    function setIdolAvatar( uint256 tokenId, string calldata avatar ) external;
    function setIdolImage( uint256 tokenId, string calldata image ) external;
    function setIdolHtml( uint256 tokenId, string calldata html ) external;
    function addIdolAttribute( uint256 tokenId, string calldata attribute ) external;
    function removeIdolAttribute( uint256 tokenId, string calldata attribute ) external;

    //--------------------------------------
    // コインの発行
    //--------------------------------------
    function donate( uint256 tokenId, address from, uint256 amount ) external;

    //--------------------------------------
    // コインの操作
    //--------------------------------------
    function mintCoin( uint256 coinId, address to, uint256 amount ) external;
    function transferCoin( uint256 coinId, address from, address to, uint256 amount ) external;
    function burnCoin( uint256 coinId, address from, uint256 amount ) external;
}


//import "./Common/IConfig.sol";
interface IConfig {
    //--------------------------------------
    // 情報の取得
    //--------------------------------------
    function externalUrl() external view returns (string memory);
    function defaultName() external view returns (string memory);
    function defaultDescription() external view returns (string memory);
    function defaultFolder() external view returns (string memory);
    function maxAttributes() external view returns (uint256);

    function rarityLabel( uint256 at ) external view returns (string memory);
    function rarityRate( uint256 at ) external view returns (uint256);

    function coinRate() external view returns (uint256);
    
    function coinName() external view returns (string memory);
    function coinSymbol() external view returns (string memory);
}


//import "./Common/LibB64.sol";
library LibB64 {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (bytes memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
        }

        return result;
    }
}


//import "./Common/LibStr.sol";
library LibStr {
    //---------------------------
    // 同じ文字列か？
    //---------------------------
    function compare( string memory str0, string memory str1 ) internal pure returns( bool ) {
        bytes memory buf0 = bytes(str0);
        bytes memory buf1 = bytes(str1);

        if( buf0.length != buf1.length ){
            return( false );
        }

        for( uint256 i=0; i<buf0.length; i++ ){
            if( buf0[i] != buf1[i] ){
                return( false );
            }
        }

        return( true );
    }

    //---------------------------
    // URLエンコードして返す
    //---------------------------
    function urlEncode( string memory str0 ) internal pure returns( string memory ) {
        bytes memory buf0 = bytes(str0);

        uint256 bufSize = buf0.length;
        for( uint256 i=0; i<buf0.length; i++ ){
            if( (buf0[i] >= 0x20 && buf0[i] <= 0x2C) || buf0[i] == 0x2F ){ bufSize += 2; }
            else if( buf0[i] >= 0x3A && buf0[i] <= 0x3F ){ bufSize += 2; }
            else if( buf0[i] == 0x40 ){ bufSize += 2; }
            else if( buf0[i] == 0x5B || (buf0[i] >= 0x5D && buf0[i] <= 0x5E) ){ bufSize += 2; }
            else if( buf0[i] == 0x60 ){ bufSize += 2; }
            else if( buf0[i] >= 0x7B && buf0[i] <= 0x7E ){ bufSize += 2; }
        }

        // バッファ確保
        bytes memory buf = new bytes(bufSize);

        // バッファへ出力
        uint256 at = 0;
        for( uint256 i=0; i<buf0.length; i++ ){
            if( (buf0[i] >= 0x20 && buf0[i] <= 0x2C) || buf0[i] == 0x2F ){
                buf[at++] = 0x25;    // %
                buf[at++] = 0x32;    // 2
                if( buf0[i] < 0x2A ){
                    buf[at++] = bytes1(0x30 + (uint8(buf0[i])-0x20));
                }else{
                    buf[at++] = bytes1(0x41 + (uint8(buf0[i])-0x2A));
                }
            }else if( buf0[i] >= 0x3A && buf0[i] <= 0x3F ){
                buf[at++] = 0x25;    // %
                buf[at++] = 0x33;    // 3
                buf[at++] = bytes1(0x41 + (uint8(buf0[i])-0x3A));
            }else if( buf0[i] == 0x40 ){
                buf[at++] = 0x25;    // %
                buf[at++] = 0x34;    // 4
                buf[at++] = 0x30;    // 0
            }else if( buf0[i] == 0x5B || (buf0[i] >= 0x5D && buf0[i] <= 0x5E) ){
                buf[at++] = 0x25;    // %
                buf[at++] = 0x35;    // 5
                buf[at++] = bytes1(0x42 + (uint8(buf0[i])-0x5B));
            }else if( buf0[i] == 0x60 ){
                buf[at++] = 0x25;    // %
                buf[at++] = 0x36;    // 6
                buf[at++] = 0x30;    // 0
            }else if( buf0[i] >= 0x7B && buf0[i] <= 0x7E ){
                buf[at++] = 0x25;    // %
                buf[at++] = 0x37;    // 7
                buf[at++] = bytes1(0x42 + (uint8(buf0[i])-0x7B));

            }else{
                buf[at++] = buf0[i];
            }
        }

        return( string(buf) );
    }

    //---------------------------
    // 数値を１０進数文字列にして返す
    //---------------------------
    function numToStr(uint256 val, uint256 zeroFill) internal pure returns (string memory) {
        // 数字の桁
        uint256 len = 1;
        uint256 temp = val;
        while (temp >= 10) {
            temp = temp / 10;
            len++;
        }

        // ゼロ埋め桁数
        uint256 padding = 0;
        if (zeroFill > len) {
            padding = zeroFill - len;
        }

        // バッファ確保
        bytes memory buf = new bytes(padding + len);

        // ０埋め
        for (uint256 i = 0; i < padding; i++) {
            buf[i] = bytes1(uint8(48));
        }

        // 数字の出力
        temp = val;
        for (uint256 i = 0; i < len; i++) {
            uint256 c = 48 + (temp % 10); // ascii: '0' 〜 '9'
            buf[padding + len - (i + 1)] = bytes1(uint8(c));
            temp /= 10;
        }

        return (string(buf));
    }

    //----------------------------
    // 数値を１６進数文字列にして返す
    //----------------------------
    function numToStrHex(uint256 val, uint256 zeroFill) internal pure returns (string memory) {
        // 数字の桁
        uint256 len = 1;
        uint256 temp = val;
        while (temp >= 16) {
            temp = temp / 16;
            len++;
        }

        // ゼロ埋め桁数
        uint256 padding = 0;
        if (zeroFill > len) {
            padding = zeroFill - len;
        }

        // バッファ確保
        bytes memory buf = new bytes(padding + len);

        // ０埋め
        for (uint256 i = 0; i < padding; i++) {
            buf[i] = bytes1(uint8(48));
        }

        // 数字の出力
        temp = val;
        for (uint256 i = 0; i < len; i++) {
            uint256 c = 48 + (temp % 16); // ascii: '0' 〜 '15'
            if (c >= 58) {
                c += 7; // ascii: 'A' 〜 'F' へ調整
            }
            buf[padding + len - (i + 1)] = bytes1(uint8(c));
            temp /= 16;
        }

        return (string(buf));
    }

}


//-----------------------------------
// ANIMAK(ERC721)
//-----------------------------------
contract ANIMAK is Ownable, ERC721Enumerable, IANIMAK {
    //--------------------------------------
    // 定数
    //--------------------------------------
    string constant private TOKEN_NAME = "Animak Token";
    string constant private TOKEN_SYMBOL = "ANIM";

    //--------------------------------------
    // 管理データ
    //--------------------------------------
    address private _manager;

    //--------------------------------------
    // ストレージ
    //--------------------------------------
    // tokenId → dataId(事前に_existsによりtokenIdの存在を確認すること)
    mapping( uint256 => uint256 ) private _mapDataIdFromTokenId;

    // 下記はdataIdで参照する
    uint256[] private _arrRarity;
    string[] private _arrName;
    string[] private _arrDescription;
    string[] private _arrFolder;
    string[] private _arrAvatar;
    string[] private _arrImage;
    string[] private _arrHtml;
    string[][] private _arrAttributes;

    //--------------------------------------
    // [modifier] マネージャからしか呼べない
    //--------------------------------------
    modifier onlyManager() {
        require( manager() == msg.sender, "caller is not the manager" );
        _;
    }

    //--------------------------------------
    // コンストラクタ
    //--------------------------------------
    constructor() Ownable() ERC721( TOKEN_NAME, TOKEN_SYMBOL ) {
    }

    //--------------------------------------
    // [public] マネージャの取得
    //--------------------------------------
    function manager() public view returns (address) {
        return( _manager );
    }

    //--------------------------------------
    // [external/onlyOwner] マネージャの設定
    //--------------------------------------
    function setManager( address __manager ) external onlyOwner {
        _manager = __manager;
    }

    //-------------------------------------------------------------------
    // [external/onlyManager] トークンの作成
    //-------------------------------------------------------------------
    function createToken( uint256 tokenId, uint256 rarity, string[] calldata attributes, address holder ) external override onlyManager {
        require( ! _exists( tokenId ), "existent token" );
        uint256 dataId = _arrRarity.length;
        _mapDataIdFromTokenId[tokenId] = dataId;

        IConfig iConfig = IConfig( IManager( _manager ).getConfigAddress() );
        bytes memory bytesTokenId = bytes( LibStr.numToStr( tokenId, 0 ) );
        bytes memory bytetFolder = abi.encodePacked( iConfig.defaultFolder(), bytesTokenId, "/" );

        // データ登録
        _arrRarity.push( rarity );
        _arrName.push( "" );
        _arrDescription.push( iConfig.defaultDescription() );
        _arrFolder.push( string( bytetFolder ) );
        _arrAvatar.push( string( abi.encodePacked( bytetFolder, bytesTokenId, ".vrm" ) ) );
        _arrImage.push( string( abi.encodePacked( bytetFolder, bytesTokenId, ".gif" ) ) );
        _arrHtml.push( string( abi.encodePacked( bytetFolder, "index.html" ) ) );

        string[] memory arrTemp = new string[](attributes.length);
        for( uint256 i=0; i<attributes.length; i++ ){
            arrTemp[i] = attributes[i];
        }
        _arrAttributes.push( arrTemp );

        // event
        emit TokenCreated( tokenId, rarity, holder );
        emit NameUpdated( tokenId, _arrName[dataId] );
        emit DescriptionUpdated( tokenId, _arrDescription[dataId] );
        emit FolderUpdated( tokenId, _arrFolder[dataId] );
        emit AvatarUpdated( tokenId, _arrAvatar[dataId] );
        emit ImageUpdated( tokenId, _arrImage[dataId] );
        emit HtmlUpdated( tokenId, _arrHtml[dataId] );
        for( uint256 i=0; i<_arrAttributes[dataId].length; i++ ){
            emit AttributeAdded( tokenId, _arrAttributes[dataId][i] );
        }

        // トークンの発行
        _safeMint( holder, tokenId );
    }

    //-----------------------------------------
    // [public] トークンURI
    //-----------------------------------------
    function tokenURI( uint256 tokenId ) public view override returns (string memory) {
        require( _exists(tokenId), "nonexistent token" );
        uint256 dataId = _mapDataIdFromTokenId[tokenId];

        IConfig iConfig = IConfig( IManager( _manager ).getConfigAddress() );

        bytes memory bytesName = abi.encodePacked( '"name":"', iConfig.defaultName(), " #", LibStr.numToStr( tokenId, 0 ), ' ', _arrName[dataId], '",' );
        bytes memory bytesDescription = abi.encodePacked( '"description":"', _arrDescription[dataId], '",' );
        bytes memory bytesExternalUrl = abi.encodePacked( '"external_url":"', iConfig.externalUrl(), '",' );
        bytes memory bytesImage = abi.encodePacked( '"image":"', _arrImage[dataId], '",' );
        bytes memory bytesFolder = abi.encodePacked( '"folder":"', _arrFolder[dataId], '",' );
        bytes memory bytesAvatar = abi.encodePacked( '"avatar_default":"', _arrAvatar[dataId], '",' );
        bytes memory bytesAnimationUrl = abi.encodePacked( '"animation_url":"', _arrHtml[dataId], '?avatar=', LibStr.urlEncode(_arrAvatar[dataId]), '",' );
        bytes memory bytesAttributes = _createAttributes( dataId, iConfig );
        bytes memory bytesMeta = abi.encodePacked( '{', bytesName, bytesDescription, bytesExternalUrl, bytesImage, bytesFolder, bytesAvatar, bytesAnimationUrl, bytesAttributes, '}' );
        return( string( abi.encodePacked( 'data:application/json;base64,', LibB64.encode( bytesMeta ) ) ) );
    }

    //--------------------------------------
    // [internal] attributesの作成
    //--------------------------------------
    function _createAttributes( uint256 dataId, IConfig iConfig ) internal view returns (bytes memory) {
        bytes memory bytesAttributes = "";
        string[] memory attributes = _arrAttributes[dataId];

        for( uint256 i=0; i<attributes.length; i++ ){
            bytesAttributes = abi.encodePacked( bytesAttributes, '{ "trait_type":"characteristics", "value":"', attributes[i] ,'" },' );
        }

        bytesAttributes = abi.encodePacked( '"attributes":[', bytesAttributes,'{ "trait_type":"rarity", "value":"', iConfig.rarityLabel( _arrRarity[dataId] ) ,'"}]' );
        return( bytesAttributes );        
    }

    //--------------------------------------
    // [external/onlyManager] 情報の設定
    //--------------------------------------
    // name
    function setNmae( uint256 tokenId, string calldata name ) external override onlyManager {
        require( _exists(tokenId), "nonexistent token" );
        uint256 dataId = _mapDataIdFromTokenId[tokenId];

        _arrName[dataId] = name;
        emit NameUpdated( tokenId, _arrName[dataId] );
    }

    // description
    function setDescription( uint256 tokenId, string calldata description ) external override onlyManager {
        require( _exists(tokenId), "nonexistent token" );
        uint256 dataId = _mapDataIdFromTokenId[tokenId];

        _arrDescription[dataId] = description;
        emit DescriptionUpdated( tokenId, _arrDescription[dataId] );
    }

    // folder
    function setFolder( uint256 tokenId, string calldata folder ) external override onlyManager {
        require( _exists(tokenId), "nonexistent token" );
        uint256 dataId = _mapDataIdFromTokenId[tokenId];

        _arrFolder[dataId] = folder;
        emit FolderUpdated( tokenId, _arrFolder[dataId] );
    }

    // avatar
    function setAvatar( uint256 tokenId, string calldata avatar ) external override onlyManager {
        require( _exists(tokenId), "nonexistent token" );
        uint256 dataId = _mapDataIdFromTokenId[tokenId];

        _arrAvatar[dataId] = avatar;
        emit AvatarUpdated( tokenId, _arrAvatar[dataId] );
    }

    // image
    function setImage( uint256 tokenId, string calldata image ) external override onlyManager {
        require( _exists(tokenId), "nonexistent token" );
        uint256 dataId = _mapDataIdFromTokenId[tokenId];

        _arrImage[dataId] = image;
        emit ImageUpdated( tokenId, _arrImage[dataId] );
    }

    // html
    function setHtml( uint256 tokenId, string calldata html ) external override onlyManager {
        require( _exists(tokenId), "nonexistent token" );
        uint256 dataId = _mapDataIdFromTokenId[tokenId];

        _arrHtml[dataId] = html;
        emit HtmlUpdated( tokenId, _arrHtml[dataId] );
    }

    // attribute(add)
    function addAttribute( uint256 tokenId, string calldata attribute ) external override onlyManager {
        require( _exists(tokenId), "nonexistent token" );
        uint256 dataId = _mapDataIdFromTokenId[tokenId];

        IConfig iConfig = IConfig( IManager( _manager ).getConfigAddress() );
        require( _arrAttributes[dataId].length < iConfig.maxAttributes(), "upper limit of atttribute" );

        for( uint256 i=0; i<_arrAttributes[dataId].length; i++ ){
            if( LibStr.compare( attribute, _arrAttributes[dataId][i] ) ){
                require( false, "duplicated attribute" );
            }
        }
        _arrAttributes[dataId].push( attribute );
        emit AttributeAdded( tokenId, attribute );
    }

    // attribute(remove)
    function removeAttribute( uint256 tokenId, string calldata attribute ) external override onlyManager {
        require( _exists(tokenId), "nonexistent token" );
        uint256 dataId = _mapDataIdFromTokenId[tokenId];

        for( uint256 i=0; i<_arrAttributes[dataId].length; i++ ){
            if( LibStr.compare( attribute, _arrAttributes[dataId][i] ) ){
                for( uint256 j=i; j<_arrAttributes[dataId].length-1; j++ ){
                    _arrAttributes[dataId][j] = _arrAttributes[dataId][j+1];                   
                }
                _arrAttributes[dataId].pop();
                emit AtttributeRemoved( tokenId, attribute );
                return;
            }
        }

        // ここまできたら何か変
        require( false, "nonexistent attribute" );        
    }

    //-------------------------------
    // [external] レアリティの取得
    //-------------------------------
    function getRarity( uint256 tokenId ) external view override returns (uint256) {
        require( _exists(tokenId), "nonexistent token" );
        uint256 dataId = _mapDataIdFromTokenId[tokenId];

        return( _arrRarity[dataId] );
    }

    //-------------------------------
    // [external] トークンが存在するか？
    //-------------------------------
    function isTokenExisting( uint256 tokenId ) external view returns (bool) {
        return( _exists( tokenId ) );
    }

    //-------------------------------
    // [external] 保有トークンIDのリスト
    //-------------------------------
    function getHolderTokenIds( address holder, uint256 pageSize, uint256 pageOfs ) external view returns (uint256[] memory) {
        uint max = balanceOf( holder );
        uint ofs = pageSize * pageOfs;
        uint num = 0;
        if( ofs < max ){
            num = max - ofs;
            if( num > pageSize ){
                num = pageSize;
            }
        }

        uint256[] memory ids = new uint256[](num);
        for( uint i=0; i<num; i++ ){
            ids[i] = tokenOfOwnerByIndex( holder, ofs+i );
        }

        return( ids );
    }

}