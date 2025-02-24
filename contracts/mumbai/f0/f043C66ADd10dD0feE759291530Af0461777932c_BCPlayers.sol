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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

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
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: invalid token ID");
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
        _requireMinted(tokenId);

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
            "ERC721: approve caller is not token owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

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
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");

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
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
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
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
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
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
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
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
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
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import "./BCTypes.sol";

// Stores information for events that happen in a specific room or from a card
// TODO: Consider splitting this by event type
// TODO: CRITICAL -> Unit tests for event and effect validity
contract BCEvents is Ownable {

    enum EnemyPlacement { NONE, IN_ROOM, LAST_ROOM, ALL_ADJACENT }
    enum MovePlayer { NONE, HOME, LAST_ROOM, RANDOM, PORTAL, REACTOR }
    enum EnemyType { NONE, TURRET, ROBOT, SCAV, BUG }
    // ENEMY Types: 0 - turret, 1 - robot, 2 - scav, 3 - bug

    enum EffectTypes {
        empty,

        permanant,
        fullHealth,
        instantDeath,
        placeHazard,
        grantEgg,

        healAmt,
        healArmorAmt,
        hazardDamage,
        physicalDamage,

        numEnemyToPlace,
        enemyType,
        whereToPlace,

        grantData,
        grantNumItems,
        takeNumItems,
        dropNumItems, // drop items in the room in unknown state

        moveType,
        trapPlayerEscapeRoll,
        grantAbility,

        loseTurn,

        lockDoorStrength,

        traitModifiersID
    }

    // Effects are mapped by the effect type to an int:
    // CRITICAL:  1 == true, not present is false
    // Numbers are cast to enum as above
    // Uint effects are as normal

    struct Effect {
        EffectTypes effect;
        uint value;
    }

    struct BCEvent {
        // TODO: Only a one-time cost to put this here, probably leave for ease
        // TODO: Except there is probably a cost to read it from the chain, remove
        // TODO: and replace name and text with a unique ID
        // string name;
        // string text;
        uint id; // TODO: Eval system, for now X000NN is for cards and 2000NN is for tiles
        // TODO: Change below to a number to serve as turns allowed?
        bool permanent; // Draw card before use allowed.  As an action - both can be derived from this
                        // TODO: Permanent events conflict with and prevent card events in a room, this upsets balance!
        uint8 rollForLow;  // On or below (unused if zero)
        uint8 rollForHigh; // On or above (unused if zero)
                           // If both roll items are zero, player can choose any non
        Effect[] defaultEffect;  // TODO: Eval doing it this way vs. using index and storing in array
        Effect[] lowEffect;
        Effect[] highEffect;
    }

    Effect[][] public effectsList; // Used to support creating empty Effects // TODO: Is this the best pattern?

    BCEvent[] public bcRoomEvents;

    BCEvent[] public bcBugCardEvents;
    BCEvent[] public bcMysteryCardEvents;
    BCEvent[] public bcScavCardEvents;
    BCEvent[] public bcShipCardEvents;

    constructor() {
        effectsList.push(); // Push empty effect into [0], but this is probably unnecessary
        _initializeDefaultRoomEvents();
        _initializeDefaultRoomEvents_2();
        _initializeDefaultBugCardEvents();
        _initializeDefaultMysteryCardEvents();
        _initializeDefaultScavCardEvents();
        _initializeDefaultShipCardEvents();
    }

    function extGetRoomEvent(uint _id) public view returns (BCEvent memory) {
        return bcRoomEvents[_id];
    }

    function extGetCardEvent(uint _id, BCTypes.BCEventType _type) public view returns (BCEvent memory) {
        if(_type == BCTypes.BCEventType.BUG) {
            return bcBugCardEvents[_id];
        } else if (_type == BCTypes.BCEventType.MYSTERY) {
            return bcMysteryCardEvents[_id];
        } else if (_type == BCTypes.BCEventType.SCAVENGER) {
            return bcScavCardEvents[_id];
        } else if (_type == BCTypes.BCEventType.SHIP_SECURITY) {
            return bcShipCardEvents[_id];
        } else if (_type == BCTypes.BCEventType.NONE) {
            // Return an empty event
            // TODO: check for side effects of type
            return bcBugCardEvents[0];
        } else {
            console.log("Bad Event of type:", uint(_type));
            revert("Bad event type");
        }
    }

    function extGetEffects(BCTypes.BCEventType _eventType, uint _id) public view returns (Effect[][] memory) {
        // TODO: Hardcoded length??
        Effect[][] memory currentEffects = new Effect[][](3);
        BCEvent storage currentEvent;
        if(_eventType == BCTypes.BCEventType.ROOM) {
            currentEvent = bcRoomEvents[_id];
        } else {
            if(_eventType == BCTypes.BCEventType.BUG) {
                currentEvent = bcBugCardEvents[_id];
            } else if (_eventType == BCTypes.BCEventType.MYSTERY) {
                currentEvent = bcMysteryCardEvents[_id];
            } else if (_eventType == BCTypes.BCEventType.SCAVENGER) {
                currentEvent = bcScavCardEvents[_id];
            } else if (_eventType == BCTypes.BCEventType.SHIP_SECURITY) {
                currentEvent = bcShipCardEvents[_id];
            } else {
                revert("Bad event type");
            }
        }

        currentEffects[0] = currentEvent.defaultEffect;
        // TODO: This is ineffecient if most effects don't have all three
        currentEffects[1] = currentEvent.lowEffect;
        currentEffects[2] = currentEvent.highEffect;

        return currentEffects;
    }

    // TODO: REFACTOR WHEN TRAIT MOD SYSTEM IMPLEMENTED!!!
    // For _effect 0 -> default, 1 -> low, 2-> high
    // function extGetTraitModForEffect(bool _roomEvent, uint _id, uint _effect) public view returns (BCTypes.Traits memory) {
    //     BCEvent storage currentEvent;
    //     if(_roomEvent) {
    //         currentEvent = bcRoomEvents[_id];
    //     } else {
    //         currentEvent = bcCardEvents[_id];
    //     }

    //     if(_effect == 0) {
    //         return currentEvent.defaultEffect.traitModifiers;
    //     } else if (_effect == 1) {
    //         return currentEvent.lowEffect.traitModifiers;
    //     } else if (_effect == 2) {
    //         return currentEvent.highEffect.traitModifiers;
    //     } else {
    //         revert ("Effect must be 0, 1, or 2");
    //     }
    // }

    function _initializeDefaultBugCardEvents() internal {
        // Effect[] storage emptyEffect = effectsList[0];

        // TODO: Should this be some kind of script that instead makes these after deployment
        // 0 No effect
        BCEvent storage noEvent = bcBugCardEvents.push();
        noEvent.id = 0;
        // noEvent.permanent = false;
        // noEvent.rollForLow = 0;
        // noEvent.rollForHigh = 0;

        // noEvent.defaultEffect = emptyEffect;
        // noEvent.lowEffect = emptyEffect;
        // noEvent.highEffect = emptyEffect;

        // 1 There's Something in the Walls
        // TODO
        Effect[] storage somethingInWallsDefault = effectsList.push();
        somethingInWallsDefault.push(Effect(EffectTypes.numEnemyToPlace, 1));
        somethingInWallsDefault.push(Effect(EffectTypes.enemyType, uint(EnemyType.BUG)));
        somethingInWallsDefault.push(Effect(EffectTypes.enemyType, uint(EnemyPlacement.IN_ROOM)));

        BCEvent storage somethingInWalls = bcBugCardEvents.push();
        somethingInWalls.id = 300001; // Bug events start with 3
        somethingInWalls.permanent = false;
        // somethingInWalls.rollForLow = 0;
        // somethingInWalls.rollForHigh = 0; //TODO: Can save gas/space not doing this, but less explicit

        somethingInWalls.defaultEffect = somethingInWallsDefault;
        // somethingInWalls.lowEffect = emptyEffect;
        // somethingInWalls.highEffect = emptyEffect;

        // 2 Something Bit Me // TODO: Appears not to hurt player
        Effect[] storage somethingBitMeDefault = effectsList.push();
        somethingBitMeDefault.push(Effect(EffectTypes.physicalDamage, 1));

        BCEvent storage somethingBitMe = bcBugCardEvents.push();
        somethingBitMe.id = 300002;
        somethingBitMe.permanent = false;
        // somethingBitMe.rollForLow = 0;
        // somethingBitMe.rollForHigh = 0;

        somethingBitMe.defaultEffect = somethingBitMeDefault;
        // somethingBitMe.lowEffect = emptyEffect;
        // somethingBitMe.highEffect = emptyEffect;

        // 3 Game Over Man, Game Over!
        // TODO
        Effect[] storage gameOverDefault = effectsList.push();
        gameOverDefault.push(Effect(EffectTypes.loseTurn, 1));

        BCEvent storage gameOver = bcBugCardEvents.push();
        gameOver.id = 300003;
        gameOver.permanent = false;
        // gameOver.rollForLow = 0;
        // gameOver.rollForHigh = 0;

        gameOver.defaultEffect = gameOverDefault;
        // gameOver.lowEffect = emptyEffect;
        // gameOver.highEffect = emptyEffect;

        // 4 Packrat
        Effect[] storage packratDefault = effectsList.push();
        packratDefault.push(Effect(EffectTypes.takeNumItems, 1));

        BCEvent storage packrat = bcBugCardEvents.push();
        packrat.id = 300004;
        packrat.permanent = false;
        // packrat.rollForLow = 0;
        // packrat.rollForHigh = 0;

        packrat.defaultEffect = packratDefault;
        // packrat.lowEffect = emptyEffect;
        // packrat.highEffect = emptyEffect;

        // 5 What is this stuff?
        // TODO
        Effect[] storage whatIsThisDefault = effectsList.push();
        whatIsThisDefault.push(Effect(EffectTypes.grantAbility, 0)); // TODO: Ignored by bugs
        whatIsThisDefault.push(Effect(EffectTypes.grantAbility, 0)); // TODO: -1 to all rolls

        BCEvent storage whatIsThis = bcBugCardEvents.push();
        whatIsThis.id = 300005;
        whatIsThis.permanent = false;
        // whatIsThis.rollForLow = 0;
        // whatIsThis.rollForHigh = 0;

        whatIsThis.defaultEffect = whatIsThisDefault;

        // 6 Packrat Nest
        // TODO
        Effect[] storage packratNestDefault = effectsList.push();
        packratNestDefault.push(Effect(EffectTypes.grantNumItems, 2));

        BCEvent storage packratNest = bcBugCardEvents.push();
        packratNest.id = 300006;
        packratNest.permanent = false;

        packratNest.defaultEffect = packratNestDefault;

        // 7 Clever Girls
        // TODO
        Effect[] storage cleverGirlsDefault = effectsList.push();
        cleverGirlsDefault.push(Effect(EffectTypes.numEnemyToPlace, 2));
        cleverGirlsDefault.push(Effect(EffectTypes.enemyType, uint(EnemyType.BUG)));
        cleverGirlsDefault.push(Effect(EffectTypes.whereToPlace, uint(EnemyPlacement.LAST_ROOM)));

        BCEvent storage cleverGirls = bcBugCardEvents.push();
        cleverGirls.id = 300007;

        cleverGirls.defaultEffect = cleverGirlsDefault;

        // 8 Warrior
        // TODO
        Effect[] storage warriorDefault = effectsList.push();
        warriorDefault.push(Effect(EffectTypes.numEnemyToPlace, 1));
        warriorDefault.push(Effect(EffectTypes.enemyType, uint(EnemyType.BUG)));
        warriorDefault.push(Effect(EffectTypes.whereToPlace, uint(EnemyPlacement.IN_ROOM)));

        BCEvent storage warrior = bcBugCardEvents.push();
        warrior.id = 300008;

        warrior.defaultEffect = warriorDefault;

        // 9 Good Girl
        // TODO
        Effect[] storage goodGirlDefault = effectsList.push();
        goodGirlDefault.push(Effect(EffectTypes.grantNumItems, 1));

        BCEvent storage goodGirl = bcBugCardEvents.push();
        goodGirl.id = 300009;

        goodGirl.defaultEffect = goodGirlDefault;

        // 10 What's that Smell?
        Effect[] storage whatsThatSmellDefault = effectsList.push();
        whatsThatSmellDefault.push(Effect(EffectTypes.hazardDamage, 1));
        whatsThatSmellDefault.push(Effect(EffectTypes.placeHazard, 1));

        BCEvent storage whatsThatSmell = bcBugCardEvents.push();
        whatsThatSmell.id = 300010;

        whatsThatSmell.defaultEffect = whatsThatSmellDefault;

        // 11 Spider's Web
        // TODO
        Effect[] storage spidersWebDefault = effectsList.push();
        spidersWebDefault.push(Effect(EffectTypes.grantNumItems, 1));
        spidersWebDefault.push(Effect(EffectTypes.numEnemyToPlace, 1));
        spidersWebDefault.push(Effect(EffectTypes.enemyType, uint(EnemyType.BUG)));
        spidersWebDefault.push(Effect(EffectTypes.whereToPlace, uint(EnemyPlacement.IN_ROOM)));

        Effect[] storage spidersWebLow = effectsList.push();
        spidersWebLow.push(Effect(EffectTypes.numEnemyToPlace, 1));
        spidersWebLow.push(Effect(EffectTypes.enemyType, uint(EnemyType.BUG)));
        spidersWebLow.push(Effect(EffectTypes.whereToPlace, uint(EnemyPlacement.IN_ROOM)));

        Effect[] storage spidersWebHigh = effectsList.push();
        spidersWebHigh.push(Effect(EffectTypes.grantNumItems, 1));

        BCEvent storage spidersWeb = bcBugCardEvents.push();
        spidersWeb.id = 300011;
        spidersWeb.rollForLow = 1;
        spidersWeb.rollForHigh = 6;

        spidersWeb.defaultEffect = spidersWebDefault;
        spidersWeb.lowEffect = spidersWebLow;
        spidersWeb.highEffect = spidersWebHigh;

        // 12 Something is following me...
        // TODO
        Effect[] storage followingMeDefault = effectsList.push();
        followingMeDefault.push(Effect(EffectTypes.numEnemyToPlace, 1));
        followingMeDefault.push(Effect(EffectTypes.enemyType, uint(EnemyType.BUG)));
        followingMeDefault.push(Effect(EffectTypes.whereToPlace, uint(EnemyPlacement.LAST_ROOM)));

        BCEvent storage followingMe = bcBugCardEvents.push();
        followingMe.id = 300012;

        followingMe.defaultEffect = followingMeDefault;

        // 13 Sneak Attack
        Effect[] storage sneakAttackDefault = effectsList.push();
        sneakAttackDefault.push(Effect(EffectTypes.numEnemyToPlace, 1));
        sneakAttackDefault.push(Effect(EffectTypes.enemyType, uint(EnemyType.BUG)));
        sneakAttackDefault.push(Effect(EffectTypes.whereToPlace, uint(EnemyPlacement.IN_ROOM)));

        BCEvent storage sneakAttack = bcBugCardEvents.push();
        sneakAttack.id = 300013;

        sneakAttack.defaultEffect = sneakAttackDefault;

        // 14 Feeding Time
        // TODO
        Effect[] storage feedingTimeDefault = effectsList.push();
        feedingTimeDefault.push(Effect(EffectTypes.dropNumItems, 1));
        feedingTimeDefault.push(Effect(EffectTypes.numEnemyToPlace, 1));
        feedingTimeDefault.push(Effect(EffectTypes.enemyType, uint(EnemyType.BUG)));
        feedingTimeDefault.push(Effect(EffectTypes.whereToPlace, uint(EnemyPlacement.IN_ROOM)));

        BCEvent storage feedingTime = bcBugCardEvents.push();
        feedingTime.id = 300014;

        feedingTime.defaultEffect = feedingTimeDefault;

        // 15 Pardon m---aaaaah!
        Effect[] storage pardonMeDefault = effectsList.push();
        pardonMeDefault.push(Effect(EffectTypes.moveType, uint(MovePlayer.LAST_ROOM)));
        pardonMeDefault.push(Effect(EffectTypes.numEnemyToPlace, 1));
        pardonMeDefault.push(Effect(EffectTypes.enemyType, uint(EnemyType.BUG)));
        pardonMeDefault.push(Effect(EffectTypes.whereToPlace, uint(EnemyPlacement.IN_ROOM)));

        BCEvent storage pardonMe = bcBugCardEvents.push();
        pardonMe.id = 300015;

        pardonMe.defaultEffect = pardonMeDefault;
    }

    function _initializeDefaultMysteryCardEvents() internal {
        BCEvent storage noEvent = bcMysteryCardEvents.push();
        noEvent.id = 0;

        // 1 Mesmer
        Effect[] storage mesmerDefault = effectsList.push();
        mesmerDefault.push(Effect(EffectTypes.loseTurn, 1));

        BCEvent storage mesmer = bcMysteryCardEvents.push();
        mesmer.id = 400001;

        mesmer.defaultEffect = mesmerDefault;

        // 2 Portal
        // TODO
        Effect[] storage portalDefault = effectsList.push();
        portalDefault.push(Effect(EffectTypes.moveType, uint(MovePlayer.PORTAL)));

        BCEvent storage portal = bcMysteryCardEvents.push();
        portal.id = 400002;

        portal.defaultEffect = portalDefault;

        // 3 The Kirk Method
        // TODO
        Effect[] storage kirkMethodDefault = effectsList.push();
        kirkMethodDefault.push(Effect(EffectTypes.loseTurn, 1)); // TODO: This should be a two dice event
        kirkMethodDefault.push(Effect(EffectTypes.fullHealth, 0));

        Effect[] storage kirkMethodLow = effectsList.push();
        kirkMethodLow.push(Effect(EffectTypes.loseTurn, 1)); // TODO: This should be a two dice event
        // TODO: Add ability -1 to all rolls

        Effect[] storage kirkMethodHigh = effectsList.push();
        kirkMethodHigh.push(Effect(EffectTypes.loseTurn, 1)); // TODO: This should be a two dice event
        kirkMethodHigh.push(Effect(EffectTypes.fullHealth, 1));

        BCEvent storage kirkMethod = bcMysteryCardEvents.push();
        kirkMethod.id = 400003;

        kirkMethod.defaultEffect = kirkMethodDefault;
        kirkMethod.lowEffect = kirkMethodLow;
        kirkMethod.highEffect = kirkMethodHigh;

        // 4 Brownie
        // TODO: This is a choice event, choices are not implemented
        Effect[] storage brownieDefault = effectsList.push();

        BCEvent storage brownie = bcMysteryCardEvents.push();
        brownie.id = 400004;

        brownie.defaultEffect = brownieDefault;

        // 5 I gotta get out of here!
        // TODO
        Effect[] storage getOutDefault = effectsList.push();
        getOutDefault.push(Effect(EffectTypes.physicalDamage, 1));
        // getOutDefault.push(Effect()) // TODO: Move player to nearest window or reeval.  This would be expensive to bfs.

        BCEvent storage getOut = bcMysteryCardEvents.push();
        getOut.id = 400005;

        getOut.defaultEffect = getOutDefault;

        // 6 Incident Boundry
        // TODO
        Effect[] storage incidentBoundryDefault = effectsList.push();
        incidentBoundryDefault.push(Effect(EffectTypes.physicalDamage, 1)); // TODO: Should armor prevent this?

        BCEvent storage incidentBoundry = bcMysteryCardEvents.push();
        incidentBoundry.id = 400006;

        incidentBoundry.defaultEffect = incidentBoundryDefault;

        // 7 Fugue State
        // TODO: May need to replace this one, very complicated to implement, meaningless single player
        Effect[] storage fugueStateDefault = effectsList.push();

        BCEvent storage fugueState = bcMysteryCardEvents.push();
        fugueState.id = 400007;

        fugueState.defaultEffect = fugueStateDefault;

        // 8 Horror
        // TODO: Another challenging event to implement, would need BFS and custom code to break doors, and move player there
        Effect[] storage horrorDefault = effectsList.push();

        BCEvent storage horror = bcMysteryCardEvents.push();
        horror.id = 400008;

        horror.defaultEffect = horrorDefault;

        // 9 Voices
        // TODO
        Effect[] storage voicesDefault = effectsList.push();

        BCEvent storage voices = bcMysteryCardEvents.push();
        voices.id = 400009;

        voices.defaultEffect = voicesDefault;

        // 10 The Lottery
        Effect[] storage lotteryDefault = effectsList.push();

        Effect[] storage lotteryLow = effectsList.push();
        lotteryLow.push(Effect(EffectTypes.instantDeath, 1));

        BCEvent storage lottery = bcMysteryCardEvents.push();
        lottery.id = 400010;
        lottery.rollForLow = 1;

        lottery.defaultEffect = lotteryDefault;
        lottery.lowEffect = lotteryLow;

        // 11 Missing Numbers
        // TODO
        Effect[] storage missingNumbersDefault = effectsList.push();

        Effect[] storage missingNumbersLow = effectsList.push();

        Effect[] storage missingNumbersHigh = effectsList.push();

        BCEvent storage missingNumbers = bcMysteryCardEvents.push();
        missingNumbers.id = 400011;
        missingNumbers.rollForLow = 1;
        missingNumbers.rollForHigh = 6;

        missingNumbers.defaultEffect = missingNumbersDefault;
        missingNumbers.lowEffect = missingNumbersLow;
        missingNumbers.highEffect = missingNumbersHigh;

        // 12 Tesseract
        // TODO
        Effect[] storage tesseractDefault = effectsList.push();
        tesseractDefault.push(Effect(EffectTypes.trapPlayerEscapeRoll, 4));

        BCEvent storage tesseract = bcMysteryCardEvents.push();
        tesseract.id = 400012;

        tesseract.defaultEffect = tesseractDefault;

        // 13 Glitch In the Spaceship
        // TODO
        Effect[] storage glitchDefault = effectsList.push();

        BCEvent storage glitch = bcMysteryCardEvents.push();
        glitch.id = 400013;

        glitch.defaultEffect = glitchDefault;

        // 14 Ephemeral Form
        // TODO
        Effect[] storage ephemeralFormDefault = effectsList.push();

        BCEvent storage ephemeralForm = bcMysteryCardEvents.push();
        ephemeralForm.id = 400014;

        ephemeralForm.defaultEffect = ephemeralFormDefault;

        // 15 TISATAAFL
        // TODO
        Effect[] storage tisataaflDefault = effectsList.push();
        tisataaflDefault.push(Effect(EffectTypes.grantNumItems, 1));
        tisataaflDefault.push(Effect(EffectTypes.fullHealth, 0));

        BCEvent storage tisataafl = bcMysteryCardEvents.push();
        tisataafl.id = 400015;

        tisataafl.defaultEffect = tisataaflDefault;
    }

    function _initializeDefaultScavCardEvents() internal {
        // 1 Crazed Prophet
        // TODO
        Effect[] storage crazedProphetDefault = effectsList.push();
        crazedProphetDefault.push(Effect(EffectTypes.grantNumItems, 1));

        BCEvent storage crazedProphet = bcScavCardEvents.push();
        crazedProphet.id = 500001;

        crazedProphet.defaultEffect = crazedProphetDefault;

        // 2 Blackjack
        Effect[] storage blackjackDefault = effectsList.push();
        blackjackDefault.push(Effect(EffectTypes.physicalDamage, 1));
        blackjackDefault.push(Effect(EffectTypes.takeNumItems, 1));

        BCEvent storage blackjack = bcScavCardEvents.push();
        blackjack.id = 500002;

        blackjack.defaultEffect = blackjackDefault;

        // 3 Toll
        // TODO
        Effect[] storage tollDefault = effectsList.push();

        BCEvent storage toll = bcScavCardEvents.push();
        toll.id = 500003;

        toll.defaultEffect = tollDefault;

        // 4 Bear Trap
        // TODO: 2 dice, place enemy if free self failed
        Effect[] storage bearTrapDefault = effectsList.push();
        bearTrapDefault.push(Effect(EffectTypes.trapPlayerEscapeRoll, 4));

        BCEvent storage bearTrap = bcScavCardEvents.push();
        bearTrap.id = 500004;

        bearTrap.defaultEffect = bearTrapDefault;

        // 5 Cooking Badly
        Effect[] storage cookingBadlyDefault = effectsList.push();
        cookingBadlyDefault.push(Effect(EffectTypes.placeHazard, 1));

        BCEvent storage cookingBadly = bcScavCardEvents.push();
        cookingBadly.id = 500005;

        cookingBadly.defaultEffect = cookingBadlyDefault;

        // 6 Garbage Collection
        // TODO:
        Effect[] storage garbageCollectionDefault = effectsList.push();
        garbageCollectionDefault.push(Effect(EffectTypes.grantNumItems, 2));

        BCEvent storage garbageCollection = bcScavCardEvents.push();
        garbageCollection.id = 500006;

        garbageCollection.defaultEffect = garbageCollectionDefault;

        // 7 You scratch my back... // TODO: Need variant for single player
                                    // Or just make it discard a card and draw a card
        // TODO:
        Effect[] storage scratchDefault = effectsList.push();
        scratchDefault.push(Effect(EffectTypes.takeNumItems, 1)); // TODO: Also need to implement picking an item to discard
        scratchDefault.push(Effect(EffectTypes.grantNumItems, 1));

        BCEvent storage scratch = bcScavCardEvents.push();
        scratch.id = 500007;

        scratch.defaultEffect = scratchDefault;

        // 8 Bully
        // TODO: Choice
        Effect[] storage bullyDefault = effectsList.push();

        BCEvent storage bully = bcScavCardEvents.push();
        bully.id = 500008;

        bully.defaultEffect = bullyDefault;

        // 9 Arm Rassling
        // TODO: Choice
        Effect[] storage armRasslingDefault = effectsList.push();

        BCEvent storage armRassling = bcScavCardEvents.push();
        armRassling.id = 500009;

        armRassling.defaultEffect = armRasslingDefault;

        // 10 Hitman
        // TODO: Solo player variant, pick player to kill, pick discard
        Effect[] storage hitmanDefault = effectsList.push();

        BCEvent storage hitman = bcScavCardEvents.push();
        hitman.id = 500010;

        hitman.defaultEffect = hitmanDefault;

        // 11 Mad Mel
        // TODO
        Effect[] storage madMelDefault = effectsList.push();
        madMelDefault.push(Effect(EffectTypes.physicalDamage, 1));
        madMelDefault.push(Effect(EffectTypes.enemyType, uint(EnemyType.SCAV)));
        madMelDefault.push(Effect(EffectTypes.numEnemyToPlace, 1));
        madMelDefault.push(Effect(EffectTypes.whereToPlace, uint(EnemyPlacement.IN_ROOM)));

        BCEvent storage madMel = bcScavCardEvents.push();
        madMel.id = 500011;

        madMel.defaultEffect = madMelDefault;

        // 12 Scavangus Interruptus
        // TODO
        Effect[] storage scavangusInterruptusDefault = effectsList.push();
        scavangusInterruptusDefault.push(Effect(EffectTypes.enemyType, uint(EnemyType.SCAV)));
        scavangusInterruptusDefault.push(Effect(EffectTypes.numEnemyToPlace, 2));
        scavangusInterruptusDefault.push(Effect(EffectTypes.whereToPlace, (uint(EnemyPlacement.IN_ROOM))));

        BCEvent storage scavangusInterruptus = bcScavCardEvents.push();
        scavangusInterruptus.id = 500012;

        scavangusInterruptus.defaultEffect = scavangusInterruptusDefault;

        // 13 I'm sleeping here!
        // TODO
        Effect[] storage imSleepingDefault = effectsList.push();
        imSleepingDefault.push(Effect(EffectTypes.enemyType, uint(EnemyType.SCAV)));
        imSleepingDefault.push(Effect(EffectTypes.numEnemyToPlace, 1));
        imSleepingDefault.push(Effect(EffectTypes.whereToPlace, (uint(EnemyPlacement.IN_ROOM))));

        BCEvent storage imSleeping = bcScavCardEvents.push();
        imSleeping.id = 500013;

        imSleeping.defaultEffect = imSleepingDefault;

        // 14 I'm not following you!
        Effect[] storage notFollowingDefault = effectsList.push();
        notFollowingDefault.push(Effect(EffectTypes.enemyType, uint(EnemyType.SCAV)));
        notFollowingDefault.push(Effect(EffectTypes.numEnemyToPlace, 1));
        notFollowingDefault.push(Effect(EffectTypes.whereToPlace, (uint(EnemyPlacement.LAST_ROOM))));

        BCEvent storage notFollowing = bcScavCardEvents.push();
        notFollowing.id = 500014;

        notFollowing.defaultEffect = notFollowingDefault;

        // 15 You Are Not Alone
        Effect[] storage notAloneDefault = effectsList.push();
        notAloneDefault.push(Effect(EffectTypes.enemyType, uint(EnemyType.SCAV)));
        notAloneDefault.push(Effect(EffectTypes.numEnemyToPlace, 1));
        notAloneDefault.push(Effect(EffectTypes.whereToPlace, (uint(EnemyPlacement.ALL_ADJACENT))));

        BCEvent storage notAlone = bcScavCardEvents.push();
        notAlone.id = 500015;

        notAlone.defaultEffect = notAloneDefault;
    }

    function _initializeDefaultShipCardEvents() internal {
        // TODO: Only 1 event spawns a sentry robot.  Evaluate.
        // Though saving murder bots for crisises is interesting too

        BCEvent storage noEvent = bcShipCardEvents.push();
        noEvent.id = 600000;

        // 1 Snitch
        // TODO: Need target player mechanism and place in that room
        Effect[] storage snitchDefault = effectsList.push();

        BCEvent storage snitch = bcShipCardEvents.push();
        snitch.id = 600001;

        snitch.defaultEffect = snitchDefault;

        // 2 Alarm
        Effect[] storage alarmDefault = effectsList.push();
        alarmDefault.push(Effect(EffectTypes.enemyType, uint(EnemyType.TURRET)));
        alarmDefault.push(Effect(EffectTypes.numEnemyToPlace, 1));
        alarmDefault.push(Effect(EffectTypes.whereToPlace, uint(EnemyPlacement.IN_ROOM)));

        BCEvent storage alarm = bcShipCardEvents.push();
        alarm.id = 600002;

        alarm.defaultEffect = alarmDefault;

        // 3 Lockdown
        // TODO: Need to permanantly lock the walls
        // For now, just locking the doors at strength 5
        Effect[] storage lockdownDefault = effectsList.push();
        lockdownDefault.push(Effect(EffectTypes.lockDoorStrength, 5));

        BCEvent storage lockdown = bcShipCardEvents.push();
        lockdown.id = 600003;

        lockdown.defaultEffect = lockdownDefault;

        // 4 Vent the Ship
        Effect[] storage ventDefault = effectsList.push();
        ventDefault.push(Effect(EffectTypes.hazardDamage, 1));
        ventDefault.push(Effect(EffectTypes.placeHazard, 1));

        BCEvent storage vent = bcShipCardEvents.push();
        vent.id = 600004;

        vent.defaultEffect = ventDefault;

        // 5 Maintenance Hatch
        // TODO: Impelement hatch
        Effect[] storage hatchDefault = effectsList.push();

        BCEvent storage hatch = bcShipCardEvents.push();
        hatch.id = 600005;

        hatch.defaultEffect = hatchDefault;

        // 6 Replicator
        // TODO: Need to track discarded/destroyed items
        // TODO: Allowing item duplicates or reviving dead items has major implications for UiF.  However, it would be super cool properly controlled!
        Effect[] storage replicatorDefault = effectsList.push();
        // TODO: For now, just granting an item
        replicatorDefault.push(Effect(EffectTypes.grantNumItems, 1));

        BCEvent storage replicator = bcShipCardEvents.push();
        replicator.id = 600006;

        replicator.defaultEffect = replicatorDefault;

        // 7 First Aid Station
        Effect[] storage firstAidDefault = effectsList.push();
        firstAidDefault.push(Effect(EffectTypes.fullHealth, 1));

        BCEvent storage firstAid = bcShipCardEvents.push();
        firstAid.id = 600007;

        firstAid.defaultEffect = firstAidDefault;

        // 8 ATM
        // TODO: Two Dice
        // TODO: Choice to walk away
        Effect[] storage atmDefault = effectsList.push();

        Effect[] storage atmLow = effectsList.push();
        atmLow.push(Effect(EffectTypes.enemyType, uint(EnemyType.TURRET)));
        atmLow.push(Effect(EffectTypes.numEnemyToPlace, 1));
        atmLow.push(Effect(EffectTypes.whereToPlace, uint(EnemyPlacement.IN_ROOM)));

        // TODO: Add second high?
        Effect[] storage atmHigh = effectsList.push();
        atmHigh.push(Effect(EffectTypes.grantData, 2)); // Avg of 1 and 3

        BCEvent storage atm = bcShipCardEvents.push();
        atm.id = 60008;

        atm.defaultEffect = atmDefault;
        atm.lowEffect = atmLow;
        atm.highEffect = atmHigh;

        // 9 Blooper Reel
        Effect[] storage blooperDefault = effectsList.push();
        blooperDefault.push(Effect(EffectTypes.hazardDamage, 1));

        BCEvent storage blooper = bcShipCardEvents.push();
        blooper.id = 600009;

        blooper.defaultEffect = blooperDefault;

        // 10 Locker
        // TODO
        Effect[] storage lockerDefault = effectsList.push();
        lockerDefault.push(Effect(EffectTypes.grantNumItems, 1));

        BCEvent storage locker = bcShipCardEvents.push();
        locker.id = 600010;

        locker.defaultEffect = lockerDefault;

        // 11 Contraband
        // TODO: CHOICE
        Effect[] storage contrabandDefault = effectsList.push();

        BCEvent storage contraband = bcShipCardEvents.push();
        contraband.id = 600011;

        contraband.defaultEffect = contrabandDefault;

        // 12 Fire // TODO: This is identical to Vent the Ship!
        Effect[] storage fireDefault = effectsList.push();
        fireDefault.push(Effect(EffectTypes.hazardDamage, 1));
        fireDefault.push(Effect(EffectTypes.placeHazard, 1));

        BCEvent storage fire = bcShipCardEvents.push();
        fire.id = 600012;

        fire.defaultEffect = fireDefault;

        // 13 Janitorial Misconduct
        // TODO: Need ability to force dropping an item at a location
        Effect[] storage janitorialMisconductDefault = effectsList.push();

        BCEvent storage janitorialMisconduct = bcShipCardEvents.push();
        janitorialMisconduct.id = 600013;

        janitorialMisconduct.defaultEffect = janitorialMisconductDefault;

        // 14 Target Acquired
        // TODO
        Effect[] storage targetAcquiredDefault = effectsList.push();
        targetAcquiredDefault.push(Effect(EffectTypes.enemyType, uint(EnemyType.TURRET)));
        targetAcquiredDefault.push(Effect(EffectTypes.numEnemyToPlace, 1));
        targetAcquiredDefault.push(Effect(EffectTypes.whereToPlace, uint(EnemyPlacement.IN_ROOM)));

        BCEvent storage targetAcquired = bcShipCardEvents.push();
        targetAcquired.id = 600014;

        targetAcquired.defaultEffect = targetAcquiredDefault;

        // 15 Security!
        // TODO
        Effect[] storage securityDefault = effectsList.push();
        securityDefault.push(Effect(EffectTypes.enemyType, uint(EnemyType.TURRET)));
        securityDefault.push(Effect(EffectTypes.numEnemyToPlace, 1));
        securityDefault.push(Effect(EffectTypes.whereToPlace, uint(EnemyPlacement.IN_ROOM)));

        BCEvent storage security = bcShipCardEvents.push();
        security.id = 600015;

        security.defaultEffect = securityDefault;
    }

    function _initializeDefaultRoomEvents() internal {
        Effect[] storage emptyEffect = effectsList[0];
        // TODO: Should this be some kind of script that instead makes these after deployment
        // 0 No effect
        BCEvent storage noEvent = bcRoomEvents.push();
        noEvent.id = 0;
        noEvent.permanent = false;
        noEvent.rollForLow = 0;
        noEvent.rollForHigh = 0;

        noEvent.defaultEffect = emptyEffect;
        noEvent.lowEffect = emptyEffect;
        noEvent.highEffect = emptyEffect;

        // 1 Breached Reactor
        // Done
        Effect[] storage breachedReactorDefault = effectsList.push();
        breachedReactorDefault.push(Effect(EffectTypes.placeHazard, 1)); // TRUE
        breachedReactorDefault.push(Effect(EffectTypes.hazardDamage, 1));
        BCEvent storage breachedReactor = bcRoomEvents.push();
        breachedReactor.id = 200001;
        breachedReactor.permanent = false;
        breachedReactor.rollForLow = 0;
        breachedReactor.rollForHigh = 0;

        breachedReactor.defaultEffect = breachedReactorDefault;
        breachedReactor.lowEffect = emptyEffect;
        breachedReactor.highEffect = emptyEffect;
    //     bcRoomEvents.push(BCEvent(
    //         // "Breached Reactor",
    //         // "As you enter the room, the reactor explodes!  Take 1 hazard damage.",
    //         200001,
    //         false,
    //         0,
    //         0, // TODO:  Explore adding choices to these ones
    //         breachedReactorDefault,
    //         emptyEffect,
    //         emptyEffect
    //     ));

        // 2 Bug Nest
        // TODO
        Effect[] storage bugNestLow = effectsList.push();
        bugNestLow.push(Effect(EffectTypes.numEnemyToPlace, 1));
        bugNestLow.push(Effect(EffectTypes.enemyType, uint(EnemyType.BUG)));
        bugNestLow.push(Effect(EffectTypes.whereToPlace, uint(EnemyPlacement.IN_ROOM)));

        Effect[] storage bugNestHigh = effectsList.push();
        bugNestHigh.push(Effect(EffectTypes.grantEgg, 1)); // TRUE

        BCEvent storage bugNest = bcRoomEvents.push();
        bugNest.id = 200002;
        bugNest.permanent = true; // TODO: THIS IS SCARY!!! CHAD WITH A LUCKY MAP COULD GET UNLIMITED!!!
        bugNest.rollForLow = 2;
        bugNest.rollForHigh = 6;

        bugNest.defaultEffect = emptyEffect;
        bugNest.lowEffect = bugNestLow;
        bugNest.highEffect = bugNestHigh;

    //     bcRoomEvents.push(BCEvent(
    //         // "Bug Nest",
    //         // "As an action, attempt to harvest an egg.  Roll a die.  On a 6, take an egg token.  On a 1 or 2, take 1 physical damage and place a bug alien in the room.",
    //         200002,
    //         true,  // TODO: THIS IS SCARY!!! CHAD WITH A LUCKY MAP COULD GET UNLIMITED!!!
    //         2,
    //         6,
    //         emptyEffect,
    //         bugNestLow,
    //         bugNestHigh
    //     ));

        // 3 Crossroads
        // TODO
        Effect[] storage crossroadsDefault = effectsList.push();
        crossroadsDefault.push(Effect(EffectTypes.numEnemyToPlace, 3));
        crossroadsDefault.push(Effect(EffectTypes.enemyType, uint(EnemyType.SCAV)));
        crossroadsDefault.push(Effect(EffectTypes.whereToPlace, uint(EnemyPlacement.IN_ROOM)));

        BCEvent storage crossroads = bcRoomEvents.push();
        crossroads.id = 200003;
        crossroads.permanent = false;
        crossroads.rollForLow = 0;
        crossroads.rollForHigh = 0;

        crossroads.defaultEffect = crossroadsDefault;
        crossroads.lowEffect = emptyEffect;
        crossroads.highEffect = emptyEffect;

    //     bcRoomEvents.push(BCEvent(
    //         // "Crossroads",
    //         // "You've crashed a party!  Place 3 scavengers in this room.",
    //         200003,
    //         false,
    //         0,
    //         0,

    //         crossroadsDefault,
    //         emptyEffect,
    //         emptyEffect
    //     ));

        // 4 Engineering Catwalk
        Effect[] storage catwalkDefault = effectsList.push();
        catwalkDefault.push(Effect(EffectTypes.moveType, uint(MovePlayer.REACTOR)));

        BCEvent storage catwalk = bcRoomEvents.push();
        catwalk.id = 200004;
        catwalk.permanent = true;
        catwalk.rollForLow = 0;
        catwalk.rollForHigh = 0;

        catwalk.defaultEffect = catwalkDefault;
        catwalk.lowEffect = emptyEffect;
        catwalk.highEffect = emptyEffect;

    //     bcRoomEvents.push(BCEvent(
    //         // "Engineering Catwalk",
    //         // "As an action, jump down to the Reactor Room, exploring if unexplored.",
    //         200004,
    //         true,
    //         0,
    //         0,
    //         catwalkDefault,
    //         emptyEffect,
    //         emptyEffect
    //     ));

        // 5 Hull Breach
        // Done
        Effect[] storage hullBreachDefault = effectsList.push();
        hullBreachDefault.push(Effect(EffectTypes.placeHazard, 1)); // TRUE

        Effect[] storage hullBreachLow = effectsList.push();
        hullBreachLow.push(Effect(EffectTypes.placeHazard, 1)); // TRUE
        hullBreachLow.push(Effect(EffectTypes.instantDeath, 1)); // TRUE

        BCEvent storage hullBreach = bcRoomEvents.push();
        hullBreach.id = 200005;
        hullBreach.permanent = false;
        hullBreach.rollForLow = 1;
        hullBreach.rollForHigh = 0;

        hullBreach.defaultEffect = hullBreachDefault;
        hullBreach.lowEffect = hullBreachLow;
        hullBreach.highEffect = emptyEffect;

    //     bcRoomEvents.push(BCEvent(
    //         // "Hull Breach",
    //         // "As you enter the room, a wall buckles and explodes into space!",
    //         200005,
    //         false,
    //         1,
    //         0,

    //         hullBreachDefault,
    //         hullBreachLow,
    //         emptyEffect
    //     ));

        // 6 Medbay
        // TODO: No hostiles in room
        // HACK:  Full health + heal amount 1 indicates heal to full health +1
        Effect[] storage medbayDefault = effectsList.push();
        medbayDefault.push(Effect(EffectTypes.fullHealth, 1)); // TRUE

        BCEvent storage medbay = bcRoomEvents.push();
        medbay.id = 200006;
        medbay.permanent = true;
        medbay.rollForLow = 0;
        medbay.rollForHigh = 0;

        medbay.defaultEffect = medbayDefault;
        medbay.lowEffect = emptyEffect;
        medbay.highEffect = emptyEffect;

    //     bcRoomEvents.push(BCEvent(
    //         // "Medbay",
    //         // "If there are no hostiles in this room, as an action, return to full health +1",
    //         200006,
    //         true,
    //         0,
    //         0,

    //         medbayDefault,
    //         emptyEffect,
    //         emptyEffect
    //     ));
    }

    function _initializeDefaultRoomEvents_2() internal {
        Effect[] storage emptyEffect = effectsList[0];
        // 7 Showers
        // Done
        Effect[] storage showersDefault = effectsList.push();
        showersDefault.push(Effect(EffectTypes.hazardDamage, 1));

        BCEvent storage showers = bcRoomEvents.push();
        showers.id = 200007;
        showers.permanent = false;
        showers.rollForLow = 0;
        showers.rollForHigh = 0;

        showers.defaultEffect = showersDefault;
        showers.lowEffect = emptyEffect;
        showers.highEffect = emptyEffect;

        //     bcRoomEvents.push(BCEvent(
        //     // "Showers",
        //     // "As you explore this room, a horde of small bugs emerge from the drains.  They get inside your suit, biiting and stinging.  Take 1 hazard damage.",
        //     200007,
        //     false,
        //     0,
        //     0,

        //     showersDefault,
        //     emptyEffect,
        //     emptyEffect
        // ));

        // 8 Trash Compactor
        // TODO - Locking doors is done, crushing players and items is not
        Effect[] storage trashCompactorDefault = effectsList.push();
        trashCompactorDefault.push(Effect(EffectTypes.lockDoorStrength, 4));

        BCEvent storage trashCompactor = bcRoomEvents.push();
        trashCompactor.id = 200008;
        trashCompactor.permanent = false;
        trashCompactor.rollForLow = 0;
        trashCompactor.rollForHigh = 0;

        trashCompactor.defaultEffect = trashCompactorDefault;
        trashCompactor.lowEffect = emptyEffect;
        trashCompactor.highEffect = emptyEffect;

        // bcRoomEvents.push(BCEvent(
        //     // "Trash Compactor",
        //     // "As you enter, the doors slam shut and the trash compactor comes to life!  In three turns, everything in the room will be destroyed!",
        //     200008,
        //     false,
        //     0,
        //     0,

        //     trashCompactorDefault,
        //     emptyEffect,
        //     emptyEffect
        // ));

        // 9 Ship Services
        // TODO: Let player select which services to use.
        // TODO
        Effect[] storage shipServicesDefault = effectsList.push();
        shipServicesDefault.push(Effect(EffectTypes.fullHealth, 1)); // TODO: Prevent this from stripping extra health
        // TODO: Sell items to company
        // TODO: Buy items from company (only multiplayer?)

        BCEvent storage shipServices = bcRoomEvents.push();
        shipServices.id = 200009;
        shipServices.permanent = true;

        shipServices.defaultEffect = shipServicesDefault;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "hardhat/console.sol";
// import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./BCTypes.sol";
import "./BCEvents.sol";
// import "./BCMaps.sol";

interface EventsInterface {
    function extGetRoomEvent(uint _id) external view returns (BCEvents.BCEvent memory);
    function extGetCardEvent(uint _id, BCTypes.BCEventType _type) external view returns (BCEvents.BCEvent memory);
    function extGetEffects(BCTypes.BCEventType _eventType, uint _id) external view returns (BCEvents.Effect[][] memory);
    function extGetTraitModForEffect(bool _roomEvent, uint _id, uint _effect) external view returns (BCTypes.Traits memory);
}

interface CharInterface {
    function characters(uint _id) external view returns(BCTypes.Character memory);
    function incrementCloneNumber(uint _charId) external;
    function extGetChar(uint _charId) external view returns(BCTypes.Character memory);
}

interface UtilsInterface {
    function smallIntBetweenVals(uint8 _min, uint8 _max) external returns (uint8);
    function roll(uint _gameId) external returns (uint);
}

interface MapInterface {
    function createMap() external returns (uint);
    function debugBuildMapOneRoom(uint _roomId) external returns(uint);
    // function extGetBoard(uint _mapId) external view returns (BCTypes.GameTile[][] memory);
    function extGetGameTile(uint _mapId, uint _row, uint _col) external view returns (BCTypes.GameTile memory);
    function getDoor(uint _mapId, uint _row, uint _col, uint _direction) external view returns (BCTypes.Door memory);
    function setDoorFromPos(uint _mapId, uint _row, uint _col, uint _direction, BCTypes.DoorStatus _status, uint _strength) external;
    function resetOpenDoors(uint _mapId) external;
    function extGetRoom(uint _mapId, uint _row, uint _col) external view returns(BCTypes.RoomTile memory);
    function extGetRoomById(uint _mapId, uint _roomId) external view returns (BCTypes.RoomTile memory);
    function extSetHazardStatus(uint _mapId, uint _row, uint _col, bool _hasHazard) external;
    function extSpreadHazards(uint _mapId, uint _distance) external;
    function lockDownRoom(uint _mapId, uint _row, uint _col, uint _strength) external;
    function extGetMainReactorCoords(uint _mapId) external view returns (uint, uint);
}

interface ItemsInterface {
    function getItemIDsByPlayer(uint _playerID) external view returns (uint[] memory);
    function destroyItem(uint _itemId) external;
}

interface GamesInterface {
    // function endPlayerRound(uint _gameId, uint _mapId) external;
    function extMovePlayer(uint _gameId, BCTypes.Position memory _position, uint _playerId) external;
}

contract BCPlayers is Ownable {
    CharInterface public chars;
    UtilsInterface public utils;
    MapInterface public maps;
    EventsInterface public bcEvents;
    ItemsInterface public items;
    GamesInterface public games;

    address public lobbiesAddress;
    address public charsAddress;
    address public actionsAddress;

    // BCChars bcChars;
    // Maps bcMaps;

    function setContractAddresses(
        address _charAddress,
        address _utilsAddress,
        address _mapsAddress,
        address _lobbiesAddress,
        address _actionsAddress,
        address _eventsAddress,
        address _itemsAddress,
        address _gamesAddress)
        public onlyOwner {
        chars = CharInterface(_charAddress);
        // bcChars = BCChars(_charAddress);
        utils = UtilsInterface(_utilsAddress);
        maps = MapInterface(_mapsAddress);
        // bcMaps = Maps(_mapsAddress);
        lobbiesAddress = _lobbiesAddress;
        actionsAddress = _actionsAddress;
        bcEvents = EventsInterface(_eventsAddress);
        items = ItemsInterface(_itemsAddress);
        games = GamesInterface(_gamesAddress);
    }

    uint constant DEFAULT_ACTIONS_NUM = 3;

    uint8 constant SPACE_ROOM = 0;

    BCTypes.Position public StartLocation = BCTypes.Position(10, 6); // TODO: duped on maps

    BCTypes.Player[] public players;

    event EventResolvedEvent(uint gameId, uint playerId, BCEvents.BCEvent bcEvent, BCEvents.Effect[] bcEffects);

    constructor() {
        // TODO: CRITICAL!!! BURN PLAYER 0
    }

    function addPlayer(address _charContractAddress, uint _charId, address _owner) external returns (uint) {
        // TODO: CRITICAL -> Add tests to confirm require works
        // TODO: Decide on allowing more than one valid contract for chars (etc.)
        require(msg.sender == lobbiesAddress, "Not lobby contract");

        BCTypes.Player storage newPlayer = players.push();
        newPlayer.charContractAddress = _charContractAddress;
        newPlayer.owner = _owner;
        newPlayer.characterId = _charId;
        return uint(players.length-1);
    }

    function grantDataToPlayer(uint _playerId, uint8 _amount) public {
        require(msg.sender == actionsAddress, "Not actions contract");
        players[_playerId].dataTokens += _amount;


        // TODO: Event
    }

    function extHurtPlayer(uint _playerId, uint _amount, bool _hazard) public {
        require(msg.sender == address(games), "Not games contract");
        _hurtPlayer(_playerId, _amount, _hazard);
    }

    function _hurtPlayer(uint _playerId, uint _amount, bool _hazard) internal {
        BCTypes.Player storage currentPlayer = players[_playerId];
        // TODO: The below worked in games, but not here!?!?!?!
        // Or maybe it does?
        BCTypes.Character memory currentChar = chars.characters(currentPlayer.characterId);
        // BCTypes.Character memory currentChar = chars.extGetChar(currentPlayer.characterId);
        // TODO: Handle hazard immunity
        // TODO: Handle armor
        currentPlayer.healthDmgTaken += int8(uint8(_amount));
        if(currentPlayer.healthDmgTaken >= int8(uint8(currentChar.traits.health))) {
            _respawnPlayer(_playerId);
        }
    }

    function _respawnPlayer(uint _playerId) internal {
        BCTypes.Player storage currentPlayer = players[_playerId];
        // players[_playerId].dead = false;
        // TODO: Eval making this cost an action.  If so, need to handle 4/3 actions used
        // TODO: Drop or destroy items
        // TODO: CHARGE FOR THIS!
        currentPlayer.healthDmgTaken = 0;
        chars.incrementCloneNumber(players[_playerId].characterId);
        // TODO: Confirm I don't need any game stuff for moving player because a room won't be
        players[_playerId].position = StartLocation;
    }

    // TODO: Currently this is only used for using a room, consider renaming
    function extApplyEffect(uint _playerId, uint _gameId, uint _mapId, BCTypes.Position memory _position, uint _eventId, uint _effectNum) public {
        require(msg.sender == actionsAddress, "Not actions contract");
        // TODO: Assumes this will always use the default effect
        BCEvents.Effect[] memory effect = bcEvents.extGetEffects(BCTypes.BCEventType.ROOM, _eventId)[_effectNum];
        _applyEffect(_playerId, _gameId, _mapId, _position, effect);
    }

    function _applyEffect(uint _playerId, uint _gameId, uint _mapId, BCTypes.Position memory _position, BCEvents.Effect[] memory _effects) internal {
        for(uint i = 0; i < _effects.length; i++) {

            BCTypes.Player storage currentPlayer = players[_playerId];

            if(_effects[i].effect == BCEvents.EffectTypes.permanant) {
                // TODO
            }

            if(_effects[i].effect == BCEvents.EffectTypes.fullHealth) {
                currentPlayer.healthDmgTaken = 0 - int8(uint8(_effects[i].value));
            }

            if(_effects[i].effect == BCEvents.EffectTypes.instantDeath) {
                _respawnPlayer(_playerId);
            }

            if(_effects[i].effect == BCEvents.EffectTypes.placeHazard) {
                maps.extSetHazardStatus(_mapId, _position.row, _position.col, true);
            }

            if(_effects[i].effect == BCEvents.EffectTypes.grantEgg) {
                // TODO
            }

            if(_effects[i].effect == BCEvents.EffectTypes.healAmt) {
                currentPlayer.healthDmgTaken -= int8(uint8(_effects[i].value));
                if(currentPlayer.healthDmgTaken < 0) {
                    currentPlayer.healthDmgTaken = 0;
                }
            }

            if(_effects[i].effect == BCEvents.EffectTypes.healArmorAmt) {
                // TODO
            }

            if(_effects[i].effect == BCEvents.EffectTypes.hazardDamage) {
                _hurtPlayer(_playerId, _effects[i].value, true);
            }

            if(_effects[i].effect == BCEvents.EffectTypes.physicalDamage) {
                _hurtPlayer(_playerId, _effects[i].value, false);
            }

            if(_effects[i].effect == BCEvents.EffectTypes.enemyType) {
                // TODO
            }

            if(_effects[i].effect == BCEvents.EffectTypes.grantData) {
                grantDataToPlayer(_playerId, uint8(_effects[i].value));
            }

            if(_effects[i].effect == BCEvents.EffectTypes.grantNumItems) {
                // TODO:  This is complicated and will probably need to be two steps
                // We won't know when the effect is drawn if the player will get items
                // Therefore, we don't know whether or not to require them to pay for items
            }

            if(_effects[i].effect == BCEvents.EffectTypes.takeNumItems) {
                // TODO: CRITICAL -> Ensure complete test coverage
                uint remainingToTake = _effects[i].value;
                uint[] memory itemIds = items.getItemIDsByPlayer(_playerId);
                if(itemIds.length > 0) {
                    // Fischer-yates for random order to take
                    for (uint j = itemIds.length-1; j > 0; j--) {
                        uint8 k = utils.smallIntBetweenVals(0, uint8(j));

                        (itemIds[j], itemIds[k]) = (itemIds[k], itemIds[j]);
                    }

                    for(uint j = 0; i < itemIds.length; j++) {
                        items.destroyItem(itemIds[j]);

                        remainingToTake--;
                        if(remainingToTake == 0){
                            break;
                        }
                    }
                }
            }

            // TODO: Other move types
            if(_effects[i].effect == BCEvents.EffectTypes.moveType) {
                if (_effects[i].value == uint(BCEvents.MovePlayer.REACTOR)) {
                    (uint row, uint col) = maps.extGetMainReactorCoords(_mapId);
                    // This is roundabout, but have the games contract move the player to discover the room
                    games.extMovePlayer(_gameId, BCTypes.Position(uint8(row), uint8(col)), _playerId);
                }
            }

            if(_effects[i].effect == BCEvents.EffectTypes.trapPlayerEscapeRoll) {
                // TODO
            }

            if(_effects[i].effect == BCEvents.EffectTypes.grantAbility) {
                // TODO
            }

            if(_effects[i].effect == BCEvents.EffectTypes.lockDoorStrength) {
                // maps.lockDownRoom(_mapId, _position.row, _position.col, _effect.lockDoorStrength);
                // Function above removed because of contract size.  Can refactor after removing debug mapgen
                for(uint k = 0; k < 4; k++) {
                    BCTypes.Door memory currentDoor = maps.getDoor(_mapId, _position.row, _position.col, k);
                    if (currentDoor.status == BCTypes.DoorStatus.CLOSED ||
                        currentDoor.status == BCTypes.DoorStatus.OPEN ||
                        currentDoor.status == BCTypes.DoorStatus.BREACHED) {
                            maps.setDoorFromPos(_mapId, _position.row, _position.col, k, BCTypes.DoorStatus.CLOSED, _effects[i].value);
                    }
                }
            }

            if(_effects[i].effect == BCEvents.EffectTypes.loseTurn) {
                // TODO
            }

            // TODO: Handle trait modifiers
        }
    }

    // Choose which effect to apply then apply it to resolve the event
    function extChooseEffect(uint _choice, uint _eventPlayerId, uint _gameId, uint _mapId, BCTypes.Position memory _position, uint _eventNumber, BCTypes.BCEventType _eventType) public {
        require(msg.sender == address(games), "Not games contract");
        BCEvents.BCEvent memory currentEvent;
        BCEvents.Effect[] memory currentEffect;
        if(_eventType == BCTypes.BCEventType.ROOM) {
            currentEvent = bcEvents.extGetRoomEvent(_eventNumber);
        } else {
            currentEvent = bcEvents.extGetCardEvent(_eventNumber, _eventType);
        }
        // TODO: Revisit this, should probably be picking an effect then fetching just that one
        BCEvents.Effect[][] memory currentEffects = bcEvents.extGetEffects(_eventType, _eventNumber);
        // TODO: Could always roll and skip this first level of if
        if(currentEvent.rollForLow == 0 && currentEvent.rollForHigh == 0) {
            // No rolls means defaultEffect happens automatically
            _applyEffect(_eventPlayerId, _gameId, _mapId, _position, currentEffects[0]);
        } else {
            uint roll = utils.roll(_gameId);
            if(currentEvent.rollForLow != 0 && roll <= currentEvent.rollForLow) {
                // Rolled for lowEffect
                _applyEffect(_eventPlayerId, _gameId, _mapId, _position, currentEffects[1]);
            } else if (currentEvent.rollForHigh != 0 && roll >= currentEvent.rollForHigh){
                // Rolled for highEffect
                _applyEffect(_eventPlayerId, _gameId, _mapId, _position, currentEffects[2]);
            } else {
                // Do the default anyway
                _applyEffect(_eventPlayerId, _gameId, _mapId, _position, currentEffects[0]);
            }
        }

        emit EventResolvedEvent(_gameId, _eventPlayerId, currentEvent, currentEffect);
    }

    function extMovePlayer(BCTypes.Position memory _position, uint _playerId, uint _mapId) public returns (bool) {
        require(msg.sender == address(games), "Not games contract");
        // TODO: Require move to ship tile?
        players[_playerId].position = _position;

        // Kill the player if they are in space
        if(maps.extGetGameTile(_mapId, _position.row, _position.col).roomId == SPACE_ROOM) {
            _respawnPlayer(_playerId);
            return true;
        }

        return false;
    }

    function resetPlayerActions(uint _playerId) public {
        require(msg.sender == address(games));
        players[_playerId].actionsTaken = 0;
    }

    function incrementPlayerActions(uint _playerId) public {
        require(msg.sender == address(games));
        players[_playerId].actionsTaken++;
    }

    function applyHazardDamage(uint _mapId, uint[] memory _players) public {
        require(msg.sender == address(games), "Not games contract");

        for(uint i = 0; i <= _players.length-1; i++) {
            BCTypes.Player storage currentPlayer = players[_players[i]];
            BCTypes.GameTile memory currentGameTile = maps.extGetGameTile(_mapId, currentPlayer.position.row, currentPlayer.position.col);

            if(currentGameTile.hasHazard) {
                _hurtPlayer(_players[i], 1, true); // TODO: Hardcoded
            }
        }
    }

    // TODO: Why do I need this here, but I can get chars from the automatic getter?
    function extGetPlayer(uint _id) public view returns(BCTypes.Player memory) {
        return players[_id];
    }

    function extGetPlayerOwner(uint _id) public view returns (address) {
        return players[_id].owner;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "hardhat/console.sol";

contract BCTypes {

    // From BCGames.sol
    enum DoorStatus { NO_DOOR, CLOSED, OPEN, BREACHED, WINDOW }
    enum Action { HACK, BREACH, MOVE, PASS, LOOT, USE_ROOM, USE_ITEM } // TODO: Add rest
    enum Followthrough { NONE, MOVE }
    enum BCEventType {NONE, BUG, MYSTERY, SCAVENGER, SHIP_SECURITY, ROOM}

    struct Player {
        address owner;
        address charContractAddress;
        uint256 characterId;

        Position position;
        // 20,000 to write a word vs. 3 to add numbers, will not store updated characteristics
        int8 healthDmgTaken;  // TODO: eval cons of this being int, using to give bonus health
        uint8 armorDmgTaken;
        uint8 actionsTaken;

        uint8 dataTokens;
        uint8[] currentEffects; // Use mapping and mark true if effect is present
        uint8[] inventoryIDs; // WARNING: THIS IS NOT USED CURRENTLY!!! // TODO: figure out how to manage inventory

        // Flags
        bool canHarmOthers;
        bool dead; // TODO: Probably don't need
        bool hasEgg;  // TODO: Eval only allowing one egg at a time
    }

    struct WorldItem {
        address itemContract;
        uint id;

        Position position;
        bool destroyed; // TODO: Discarded vs. destroyed (probably remove destroyed)
    }

    struct EventTracker {
        uint8 bugEvents;
        uint8 mysteryEvents;
        uint8 scavEvents;
        uint8 shipEvents;
    }

    struct Position {
        uint8 row;
        uint8 col;
    }

    struct GameTile {
        // Position pos;
        // uint8 timesUsed;  // Used to turn off egg room, etc.
        uint8 roomId;
        uint8 parentId;

        uint[4] doors; // n, s, e, w

        bool explored;
        bool looted;
        bool hasVent;
        bool hasHazard;
    }

    struct Door {
        uint8 vsBreach;
        uint8 vsHack;
        DoorStatus status;
    }

    struct Map {
        // TODO:  Either add all events, effects, and traits here, or remove roomList
        // mapping (uint => RoomTile) roomList;
        // uint8 numRooms;
        uint[] unusedNormalRooms;
        // mapping (uint => bool) usedRooms;


        // Row, Col => GameTile
        mapping (uint => mapping (uint => GameTile)) board;
        mapping (uint => Door) doors;
        uint8 numDoors;

        Position startPosition;
        uint mainReactorRow;
        uint mainReactorCol;
    }

    struct Game {
        // TODO: Consider adding contract addresses to games to handle versioning
        bool active;

        uint[] playerIndexes;
        uint currentPlayerTurnIndex; // TODO: Default of player zero
        uint numPlayers;
        // uint256[] itemIDs; // Items in (owned by) the game

        uint turnsTaken; // TODO: Can this be smaller?

        EventTracker eventTracker;

        address mapContract; // TODO: Handle if game contract changes!!!!
        uint mapId;

        uint eventPlayerId;
        uint eventNumber;
        BCEventType eventType;
        Position eventPosition;

        uint[] unusedBugEvents;
        uint[] unusedMysteryEvents;
        uint[] unusedScavEvents;
        uint[] unusedShipEvents;
    }

    struct Lobby {
        bool gameStarted;
        uint8 numberOfPlayers;
        uint[] playerIndexes;

        // uint expireTime; TODO: Lobbys should possibly expire, or maybe set a timer to allow starting with three
    }

    // From RoomTiles.sol
    struct RoomTile {
        // uint roomTileId // TODO: Critical
        BCEventType eventType;
        uint256 eventNum; // 0 if no event in room

        uint8 numItems;
        uint8 numData;

        // bool hasHazard; // TODO:  Should hazards be handled by events only?
        bool sigDetected; // TODO:  Doesn't work with current map generation
                            // TODO: Split map list into those with and without sigs
    }

    // From BCChars.sol // TODO: Change to int8
    struct Traits {
        int8 health;
        int8 carry;
        int8 defense;
        int8 hack;
        int8 breach;
        int8 shoot;
        int8 melee;
    }

    struct Character {
        bytes32 genHash; // TODO: Eval storing these properties
        uint id; // Id in the characters array
        uint uifID; // ID in UIF
        Traits traits;
        uint8 cloneNumber;  // High but possibly reachable limit
        uint8 maxClones; // Eventually exit them from the economy??
        uint8 ability;
        uint8 flaw;
        bool inGame; // TODO: I think uint8 would be cheaper because packing
    }

    // From/for BCItems.sol
    enum ItemCategory { COMPANY, ARTIFACT, SCAVENGER }
    enum ItemType { MELEE, GUN, ARMOR, TODO_ITEM } // TODO: Finalize

    struct Item {
        bytes32 genHash; // TODO: Eval storing this here
        uint id; // Id in chars array
        uint uifID;
        uint holdingPlayerId; // TODO: Eval if this is needed

        uint weight;

        uint traitModID;

        ItemCategory itemCategory;

        uint8 grantsAbility; // TODO: Align with char abilities
        uint8 grantsFlaw;

        ItemType itemType; // 0 for not a weapon, 1 for melee, 2 gun, 3 grenade
        uint8 power;  // damage, armor level, etc... // TODO: Define this
        // uint8 level;
        // bool asAnAction; // TODO: Derive from itemType
        // bool consumable; // TODO: Derive from UIF and/or itemType

        bool inGame;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.4.22 <0.9.0;

library console {
	address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

	function _sendLogPayload(bytes memory payload) private view {
		uint256 payloadLength = payload.length;
		address consoleAddress = CONSOLE_ADDRESS;
		assembly {
			let payloadStart := add(payload, 32)
			let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
		}
	}

	function log() internal view {
		_sendLogPayload(abi.encodeWithSignature("log()"));
	}

	function logInt(int p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(int)", p0));
	}

	function logUint(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function logString(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function logBool(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function logAddress(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function logBytes(bytes memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
	}

	function logBytes1(bytes1 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
	}

	function logBytes2(bytes2 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
	}

	function logBytes3(bytes3 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
	}

	function logBytes4(bytes4 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
	}

	function logBytes5(bytes5 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
	}

	function logBytes6(bytes6 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
	}

	function logBytes7(bytes7 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
	}

	function logBytes8(bytes8 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
	}

	function logBytes9(bytes9 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
	}

	function logBytes10(bytes10 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
	}

	function logBytes11(bytes11 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
	}

	function logBytes12(bytes12 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
	}

	function logBytes13(bytes13 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
	}

	function logBytes14(bytes14 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
	}

	function logBytes15(bytes15 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
	}

	function logBytes16(bytes16 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
	}

	function logBytes17(bytes17 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
	}

	function logBytes18(bytes18 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
	}

	function logBytes19(bytes19 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
	}

	function logBytes20(bytes20 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
	}

	function logBytes21(bytes21 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
	}

	function logBytes22(bytes22 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
	}

	function logBytes23(bytes23 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
	}

	function logBytes24(bytes24 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
	}

	function logBytes25(bytes25 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
	}

	function logBytes26(bytes26 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
	}

	function logBytes27(bytes27 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
	}

	function logBytes28(bytes28 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
	}

	function logBytes29(bytes29 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
	}

	function logBytes30(bytes30 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
	}

	function logBytes31(bytes31 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
	}

	function logBytes32(bytes32 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
	}

	function log(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function log(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function log(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function log(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function log(uint p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint)", p0, p1));
	}

	function log(uint p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string)", p0, p1));
	}

	function log(uint p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool)", p0, p1));
	}

	function log(uint p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address)", p0, p1));
	}

	function log(string memory p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint)", p0, p1));
	}

	function log(string memory p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
	}

	function log(string memory p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
	}

	function log(string memory p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
	}

	function log(bool p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint)", p0, p1));
	}

	function log(bool p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
	}

	function log(bool p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
	}

	function log(bool p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
	}

	function log(address p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint)", p0, p1));
	}

	function log(address p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
	}

	function log(address p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
	}

	function log(address p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
	}

	function log(uint p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint)", p0, p1, p2));
	}

	function log(uint p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string)", p0, p1, p2));
	}

	function log(uint p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool)", p0, p1, p2));
	}

	function log(uint p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address)", p0, p1, p2));
	}

	function log(uint p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint)", p0, p1, p2));
	}

	function log(uint p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string)", p0, p1, p2));
	}

	function log(uint p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool)", p0, p1, p2));
	}

	function log(uint p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address)", p0, p1, p2));
	}

	function log(uint p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint)", p0, p1, p2));
	}

	function log(uint p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string)", p0, p1, p2));
	}

	function log(uint p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool)", p0, p1, p2));
	}

	function log(uint p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
	}

	function log(string memory p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint)", p0, p1, p2));
	}

	function log(string memory p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
	}

	function log(string memory p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
	}

	function log(string memory p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
	}

	function log(bool p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint)", p0, p1, p2));
	}

	function log(bool p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string)", p0, p1, p2));
	}

	function log(bool p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool)", p0, p1, p2));
	}

	function log(bool p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
	}

	function log(bool p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint)", p0, p1, p2));
	}

	function log(bool p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
	}

	function log(bool p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
	}

	function log(bool p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
	}

	function log(bool p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint)", p0, p1, p2));
	}

	function log(bool p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
	}

	function log(bool p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
	}

	function log(bool p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
	}

	function log(address p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint)", p0, p1, p2));
	}

	function log(address p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string)", p0, p1, p2));
	}

	function log(address p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool)", p0, p1, p2));
	}

	function log(address p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address)", p0, p1, p2));
	}

	function log(address p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint)", p0, p1, p2));
	}

	function log(address p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
	}

	function log(address p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
	}

	function log(address p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
	}

	function log(address p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint)", p0, p1, p2));
	}

	function log(address p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
	}

	function log(address p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
	}

	function log(address p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
	}

	function log(address p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint)", p0, p1, p2));
	}

	function log(address p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
	}

	function log(address p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
	}

	function log(address p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
	}

	function log(uint p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
	}

}