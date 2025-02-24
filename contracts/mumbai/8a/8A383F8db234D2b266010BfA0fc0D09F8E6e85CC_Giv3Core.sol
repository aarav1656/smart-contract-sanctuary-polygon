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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides a function for encoding some bytes in base64
library Base64 {
    string internal constant TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return "";

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
            for {

            } lt(dataPtr, endPtr) {

            } {
                dataPtr := add(dataPtr, 3)

                // read 3 bytes
                let input := mload(dataPtr)

                // write 4 characters
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(input, 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./Base64.sol";
import "./interface/IImageStorage.sol";
import "./interface/IGiv3Core.sol";

contract Giv3AvatarNFT is ERC721 {
    using Strings for uint256;

    struct CompoundImageData {
        uint256 layer_1_index;
        uint256 layer_2_index;
        uint256 layer_3_index;
        uint256 layer_4_index;
        uint256 layer_5_index;
    }

    address public storageContract;
    IGiv3Core public GIV3_CORE;
    string[] private z = [
        '<svg width="100%" height="100%" version="1.1" viewBox="0 0 32 32" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">',
        '"<image width="32" height="32" image-rendering="pixelated" preserveAspectRatio="xMidYMid" xlink:href="',
        '"/> <image width="32" height="32" image-rendering="pixelated" preserveAspectRatio="xMidYMid" xlink:href="',
        '"/> <image width="32" height="32" image-rendering="pixelated" preserveAspectRatio="xMidYMid" xlink:href="',
        '"/> <image width="32" height="32" image-rendering="pixelated" preserveAspectRatio="xMidYMid" xlink:href="',
        '"/> <image width="32" height="32" image-rendering="pixelated" preserveAspectRatio="xMidYMid" xlink:href="',
        '"/> </svg>'
    ];

    // The tokenId of the next token to be minted.
    uint128 internal _currentIndex;

    constructor(
        string memory name_,
        string memory symbol_,
        IGiv3Core _giv3Core
    ) ERC721(name_, symbol_) {
        GIV3_CORE = _giv3Core;
    }

    modifier onlyGiv3() {
        require(msg.sender == address(GIV3_CORE));
        _;
    }

    function mint(address _to) external onlyGiv3 {
        _safeMint(_to, _currentIndex);
        _currentIndex++;
    }

    /**
     * Get Total Supply of Tokens Minted
     * @return Current Total Supply
     */
    function totalSupply() public view returns (uint256) {
        return _currentIndex;
    }

    function genPNG(CompoundImageData memory data)
        internal
        view
        returns (string memory)
    {
        // Get Token Power levels
        uint256 power_1 = data.layer_1_index;
        uint256 power_2 = data.layer_2_index;
        uint256 power_3 = data.layer_3_index;
        uint256 power_4 = data.layer_4_index;
        uint256 power_5 = data.layer_5_index;

        // Get Image Levels
        string memory layer_1 = IImageStorage(storageContract).getLayer1(
            power_1
        );
        string memory layer_2 = IImageStorage(storageContract).getLayer2(
            power_2
        );
        string memory layer_3 = IImageStorage(storageContract).getLayer3(
            power_3
        );
        string memory layer_4 = IImageStorage(storageContract).getLayer4(
            power_4
        );
        string memory layer_5 = IImageStorage(storageContract).getLayer5(
            power_5
        );

        // Get Image Data
        string memory output = string(
            abi.encodePacked(z[0], z[1], layer_1, z[2])
        );
        output = string(abi.encodePacked(output, layer_2, z[3], layer_3, z[4]));
        output = string(abi.encodePacked(output, layer_4, z[5], layer_5, z[6]));

        return output;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(tokenId), "TokenID does not exist");

        CompoundImageData memory data = CompoundImageData(
            GIV3_CORE.getPowerLevels(1, tokenId), // Shoes
            GIV3_CORE.getPowerLevels(2, tokenId), // Clothes
            GIV3_CORE.getPowerLevels(3, tokenId), // Necklace
            GIV3_CORE.getPowerLevels(4, tokenId), // Specs
            GIV3_CORE.getPowerLevels(5, tokenId) // Hat
        );

        string memory json = string(
            abi.encodePacked(
                '{"name": "',
                name(),
                "# ",
                tokenId.toString(),
                '",'
            )
        );

        json = string(
            abi.encodePacked(
                json,
                '"description": "This is a NFT of the first initial of my name!",'
            )
        );
        // hat, specs , necklace, clothes, shoes
        json = string(
            abi.encodePacked(
                json,
                '"attributes": [{"trait_type": "Hat", "value": "',
                data.layer_5_index.toString(),
                '"},',
                '{"trait_type": "Specs", "value": "',
                data.layer_4_index.toString(),
                '"},',
                '{"trait_type": "Necklace", "value": "',
                data.layer_3_index.toString(),
                '"},',
                '{"trait_type": "Clothes", "value": "',
                data.layer_2_index.toString(),
                '"}',
                '{"trait_type": "Shoes", "value": "',
                data.layer_1_index.toString(),
                '"}],'
            )
        );

        json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        json,
                        '"image_data": "data:image/svg+xml;base64,',
                        Base64.encode(bytes(genPNG(data))),
                        '"}'
                    )
                )
            )
        );
        return string(abi.encodePacked("data:application/json;base64,", json));
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal pure override {
        // Prevent Future Transfer of token
        require(from == address(0), "ERC721: transfer from non-zero address");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./interface/IImageStorage.sol";
import "./interface/IGiv3Core.sol";
import "./Giv3NFTFactory.sol";
import "./Giv3TreasuryFactory.sol";
import "./Giv3AvatarNFT.sol";

contract Giv3Core is IGiv3Core {
    Giv3NFTFactory public GIV3_NFT_FACTORY;
    Giv3TreasuryFactory public GIV3_TREASURY_FACTORY;
    Giv3AvatarNFT public GIV3_AVATAR_NFT;

    struct DAO {
        address contractAddress;
        string description;
    }

    mapping(uint256 => DAO) public daoIds;
    mapping(uint256 => address) public treasuryIds;

    uint256 public daoCounter;

    event DAOCreated(string name, string symbol, address dao);
    event DAOJoined(address indexed member, uint256 indexed _id);

    constructor(
        IImageStorage staticImageStorage,
        IImageStorage dynamicImageStorage
    ) {
        GIV3_NFT_FACTORY = new Giv3NFTFactory(
            IGiv3Core(address(this)),
            staticImageStorage,
            dynamicImageStorage
        );

        GIV3_TREASURY_FACTORY = new Giv3TreasuryFactory(
            IGiv3Core(address(this))
        );

        GIV3_AVATAR_NFT = new Giv3AvatarNFT(
            "GIV3 Avatar",
            "GIV3NFT",
            IGiv3Core(address(this))
        );
    }

    /**
     * @notice Create a new DAO.
     * @param name The name of the DAO.
     * @param symbol The symbol of the DAO.
     * @param description Description of the DAO
     * @dev Include a offchain signer to verify if the structure of the datafile is correct
     */
    function createDAO(
        string memory name,
        string memory symbol,
        string memory description
    ) public {
        Giv3NFT giv3NFT = GIV3_NFT_FACTORY.createCollection(name, symbol);
        Giv3Treasury giv3Treasury = GIV3_TREASURY_FACTORY.createTreasury(name);

        // Mint GIV3Avatar NFT for user if not already exists
        if (GIV3_AVATAR_NFT.balanceOf(msg.sender) == 0) {
            GIV3_AVATAR_NFT.mint(msg.sender);
        }

        daoIds[daoCounter] = DAO(address(giv3NFT), description);
        treasuryIds[daoCounter] = address(giv3Treasury);
        daoCounter++;
        emit DAOCreated(name, symbol, address(giv3NFT));
    }

    function joinDAO(uint256 _id) public {
        require(
            GIV3_NFT_FACTORY.getCollection(_id).balanceOf(msg.sender) == 0,
            "User already minted"
        );
        GIV3_NFT_FACTORY.getCollection(_id).mint(msg.sender);

        emit DAOJoined(msg.sender, _id);
    }

    function getContract(uint256 _id) public view returns (address) {
        return daoIds[_id].contractAddress;
    }

    function setGiv3NFTFactory(address _giv3NFTFactory) public {
        GIV3_NFT_FACTORY = Giv3NFTFactory(_giv3NFTFactory);
    }

    function getPowerLevels(uint256 _id, uint256 _tokenId)
        public
        view
        returns (uint256)
    {
        return GIV3_NFT_FACTORY.getCollection(_id).getPowerLevel(_tokenId);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./Base64.sol";
import "./interface/IGiv3Core.sol";
import "./interface/IImageStorage.sol";

contract Giv3NFT is ERC721 {
    using Strings for uint256;

    // Store data about the contributions made by a user holding the token
    struct Contribution {
        string ipfsHash;
        uint256 upvotes;
        uint256 downvotes;
    }

    mapping(uint256 => Contribution[]) contributions;
    mapping(uint256 => uint256) donations;
    mapping(uint256 => uint256) experience;
    mapping(uint256 => uint256) energy;
    mapping(uint256 => uint256) mintedTime;

    IGiv3Core public GIV3_CORE;
    IImageStorage public IMAGE_STORAGE;
    string public baseURI;

    // The tokenId of the next token to be minted.
    uint128 internal _currentIndex;

    // Weight Multipliers for the different types of contributions
    uint256[3] public mul = [1, 1, 1];

    uint256 public collectionIndex;

    event DonationAdded(
        address indexed user,
        uint256 indexed tokenId,
        uint256 amount
    );

    event ExperienceAdded(
        address indexed user,
        uint256 indexed tokenId,
        uint256 amount
    );

    event EnergyAdded(
        address indexed user,
        uint256 indexed tokenId,
        uint256 amount
    );

    constructor(
        string memory name_,
        string memory symbol_,
        IGiv3Core _giv3Core,
        uint256 _collectionIndex,
        IImageStorage _imageStorageAddress // ImageStorageStatic Address
    ) ERC721(name_, symbol_) {
        GIV3_CORE = _giv3Core;
        IMAGE_STORAGE = _imageStorageAddress;
        collectionIndex = _collectionIndex;
    }

    modifier onlyGiv3() {
        require(msg.sender == address(GIV3_CORE));
        _;
    }

    function mint(address _to) external onlyGiv3 returns (uint256) {
        _safeMint(_to, _currentIndex);
        mintedTime[_currentIndex] = block.timestamp;
        _currentIndex++;
        return _currentIndex - 1;
    }

    /**
     * [email protected] Add Update Donation balance.
     */
    function addDonation(uint256 amount, uint256 tokenId) external onlyGiv3 {
        require(
            tx.origin == ownerOf(tokenId),
            "Only the owner can add a contribution"
        );

        donations[tokenId] += amount;
        emit DonationAdded(msg.sender, tokenId, amount);
    }

    /**
     * [email protected] Add Update Experience balance.
     */
    function addExperience(uint256 amount, uint256 tokenId) external onlyGiv3 {
        require(
            tx.origin == ownerOf(tokenId),
            "Only the owner can add a contribution"
        );

        experience[tokenId] += amount;
        emit ExperienceAdded(msg.sender, tokenId, amount);
    }

    /**
     * [email protected] Add Update Energy balance.
     */
    function addEnergy(uint256 amount, uint256 tokenId) external onlyGiv3 {
        require(
            tx.origin == ownerOf(tokenId),
            "Only the owner can add a contribution"
        );

        energy[tokenId] += amount;
        emit EnergyAdded(msg.sender, tokenId, amount);
    }

    /**
     * Get Total Supply of Tokens Minted
     * @return Current Total Supply
     */
    function totalSupply() public view returns (uint256) {
        return _currentIndex;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     * @dev gets baseURI from contract state variable
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        return buildMetadata(tokenId);
    }

    /// @notice Builds the metadata required in accordance ot Opensea requirements
    /// @param _tokenId Policy ID which will also be the NFT token ID
    /// @dev Can change public to internal
    function buildMetadata(uint256 _tokenId)
        public
        view
        returns (string memory)
    {
        uint256 _powerlevel = getPowerLevel(_tokenId);
        string memory image;
        // NFTS that level up based on the governance score of the token.
        // Get Image from Image Storage Contract
        image = IMAGE_STORAGE.getImageForCollection(
            collectionIndex,
            _powerlevel
        );
        bytes memory m1 = abi.encodePacked(
            '{"name":"',
            name(),
            " Membership",
            '", "description":"',
            name(),
            " Membership",
            '", "image": "',
            image,
            // adding policyHolder
            '", "attributes": [{"trait_type":"Power Level",',
            '"value":"',
            Strings.toString(_powerlevel),
            '"}]}'
        );

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(bytes.concat(m1))
                )
            );
    }

    function getUpvotes(uint256 tokenId, uint256 index)
        public
        view
        returns (uint256)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        return contributions[tokenId][index].upvotes;
    }

    function getDownvotes(uint256 tokenId, uint256 index)
        public
        view
        returns (uint256)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        return contributions[tokenId][index].downvotes;
    }

    function getTotalUpvotes(uint256 tokenId)
        public
        view
        returns (uint256 _totalUpvotes)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        for (uint256 i = 0; i < contributions[tokenId].length; i++) {
            _totalUpvotes += contributions[tokenId][i].upvotes;
        }
        return _totalUpvotes;
    }

    function getTotalDownvotes(uint256 tokenId)
        public
        view
        returns (uint256 _totalDownvotes)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        for (uint256 i = 0; i < contributions[tokenId].length; i++) {
            _totalDownvotes += contributions[tokenId][i].downvotes;
        }
        return _totalDownvotes;
    }

    function getContribution(uint256 tokenId, uint256 index)
        public
        view
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return
            string(
                abi.encodePacked(
                    "https://ipfs.io/ipfs/",
                    contributions[tokenId][index].ipfsHash
                )
            );
    }

    function getAllContributions(uint256 tokenId)
        public
        view
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        string memory contributionsString = "";
        for (uint256 i = 0; i < contributions[tokenId].length; i++) {
            if (i + 1 < contributions[tokenId].length) {
                string(
                    abi.encodePacked(
                        contributionsString,
                        "https://ipfs.io/ipfs/",
                        contributions[tokenId][i].ipfsHash,
                        ","
                    )
                );
            } else {
                string(
                    abi.encodePacked(
                        contributionsString,
                        "https://ipfs.io/ipfs/",
                        contributions[tokenId][i].ipfsHash
                    )
                );
            }
        }
        return contributionsString;
    }

    function getContributionCount(uint256 tokenId)
        public
        view
        returns (uint256 _contributionCount)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return contributions[tokenId].length;
    }

    function getTimeScore(uint256 tokenId) public view returns (uint256) {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return (block.timestamp - mintedTime[tokenId]) / 1 days;
    }

    function getDonationScore(uint256 tokenId) public view returns (uint256) {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return donations[tokenId];
    }

    function getExperienceScore(uint256 tokenId) public view returns (uint256) {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return experience[tokenId];
    }

    function getEnergyScore(uint256 tokenId) public view returns (uint256) {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return energy[tokenId];
    }

    function getPowerLevel(uint256 tokenId)
        public
        view
        returns (uint256 _powerLevel)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        uint256 _donationScore = getDonationScore(tokenId);
        uint256 _experienceScore = getExperienceScore(tokenId);
        uint256 _energyScore = getEnergyScore(tokenId);

        _powerLevel =
            mul[0] *
            _donationScore +
            mul[1] *
            _experienceScore +
            mul[2] *
            _energyScore;

        return _powerLevel;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal pure override {
        // Prevent Future Transfer of token
        require(from == address(0), "ERC721: transfer from non-zero address");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./Giv3NFT.sol";

contract Giv3NFTFactory {
    uint256 collectionsCounter = 0;

    // Map Id to collection
    mapping(uint256 => Giv3NFT) collections;

    IGiv3Core public GIV3_CORE;
    IImageStorage public STATIC_IMAGE_STORAGE;
    IImageStorage public DYNAMIC_IMAGE_STORAGE;

    event CollectionCreated(uint256 id, address collection);

    modifier onlyGiv3() {
        require(msg.sender == address(GIV3_CORE));
        _;
    }

    constructor(
        IGiv3Core _giv3Core,
        IImageStorage _staticImageStorage,
        IImageStorage _dynamicImageStorage
    ) {
        GIV3_CORE = _giv3Core;
        STATIC_IMAGE_STORAGE = _staticImageStorage;
        DYNAMIC_IMAGE_STORAGE = _dynamicImageStorage;
    }

    function createCollection(string memory name, string memory symbol)
        public
        onlyGiv3
        returns (Giv3NFT)
    {
        Giv3NFT giv3Address = new Giv3NFT(
            name,
            symbol,
            GIV3_CORE,
            collectionsCounter,
            STATIC_IMAGE_STORAGE
        );

        collections[collectionsCounter] = giv3Address;
        collectionsCounter++;

        return giv3Address;
        // emit CollectionCreated()
    }

    function getCollection(uint256 id) public view returns (Giv3NFT) {
        return collections[id];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

// import erc20
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./interface/IGiv3Core.sol";

contract Giv3Treasury {
    uint256 public ethBalance;
    IGiv3Core public GIV3_CORE;

    string public name;

    mapping(address => uint256) public tokenBalances;

    event ETHDeposited(uint256 amount);
    event ETHWithdrawn(uint256 amount, address to);
    event TokenDeposited(IERC20 tokenAddress, uint256 amount);
    event TokenWithdrawn(IERC20 tokenAddress, uint256 amount, address to);

    modifier onlyGiv3() {
        require(msg.sender == address(GIV3_CORE));
        _;
    }

    constructor(string memory _name, IGiv3Core _giv3Core) {
        name = _name;
        GIV3_CORE = _giv3Core;
    }

    function depositETH() public payable onlyGiv3 {
        ethBalance += msg.value;
        uint256 amount = msg.value;
        emit ETHDeposited(amount);
    }

    function withdrawETH(address to, uint256 amount) public payable onlyGiv3 {
        require(amount <= ethBalance, "Not enough ETH");
        ethBalance -= amount;
        to.call{value: amount}("");
        emit ETHWithdrawn(amount, to);
    }

    function depositToken(IERC20 tokenAddress, uint256 amount) public onlyGiv3 {
        require(amount > 0, "Amount must be greater than 0");
        tokenAddress.transfer(msg.sender, amount);
        emit TokenDeposited(tokenAddress, amount);
    }

    function withdrawToken(
        IERC20 tokenAddress,
        uint256 amount,
        address to
    ) public onlyGiv3 {
        require(amount > 0, "Amount must be greater than 0");
        require(
            tokenAddress.balanceOf(msg.sender) >= amount,
            "Not enough tokens"
        );
        tokenAddress.transfer(to, amount);
        emit TokenWithdrawn(tokenAddress, amount, to);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./Giv3Treasury.sol";

contract Giv3TreasuryFactory {
    uint256 collectionsCounter = 0;

    // Map Id to collection
    mapping(uint256 => Giv3Treasury) treasuries;

    IGiv3Core public GIV3_CORE;

    event TreasuryCreated(uint256 id, string name);

    modifier onlyGiv3() {
        require(msg.sender == address(GIV3_CORE));
        _;
    }

    constructor(IGiv3Core _giv3Core) {
        GIV3_CORE = _giv3Core;
    }

    function createTreasury(string memory name)
        public
        onlyGiv3
        returns (Giv3Treasury)
    {
        Giv3Treasury giv3Treasury = new Giv3Treasury(name, GIV3_CORE);

        treasuries[collectionsCounter] = giv3Treasury;
        collectionsCounter++;

        emit TreasuryCreated(collectionsCounter - 1, name);
        return giv3Treasury;
    }

    function getCollection(uint256 id) public view returns (Giv3Treasury) {
        return treasuries[id];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IGiv3Core {
    function createDAO(
        string memory name,
        string memory symbol,
        string memory metadataHash
    ) external;

    function joinDAO(uint256 _id) external;

    function getContract(uint256 _id) external view returns (address);

    function setGiv3NFTFactory(address _giv3NFTFactory) external;

    function getPowerLevels(uint256 _id, uint256 _tokenId)
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.10;

interface IImageStorage {
    function getBody() external view returns (string memory);

    function getLayer1(uint256 _index) external view returns (string memory);

    function getLayer2(uint256 _index) external view returns (string memory);

    function getLayer3(uint256 _index) external view returns (string memory);

    function getLayer4(uint256 _index) external view returns (string memory);

    function getLayer5(uint256 _index) external view returns (string memory);

    function getImageForCollection(uint256 collectionIndex, uint256 imageIndex)
        external
        view
        returns (string memory);
}