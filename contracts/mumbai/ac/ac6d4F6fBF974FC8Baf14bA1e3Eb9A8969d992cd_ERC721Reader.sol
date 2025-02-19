/**
 *Submitted for verification at polygonscan.com on 2022-10-18
*/

// SPDX-License-Identifier: AGPL-3.0-or-later

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

pragma solidity =0.8.9;
pragma abicoder v2;

contract ERC721Reader {
    struct CollectionSupply {
        address tokenAddress;
        uint256 supply;
    }

    struct OwnerTokenCount {
        address tokenAddress;
        uint256 count;
    }

    struct TokenOwnerInput {
        address tokenAddress;
        uint256 tokenId;
    }

    struct TokenOwner {
        address tokenAddress;
        uint256 tokenId;
        address owner;
        bool exists;
    }

    struct TokenId {
        uint256 tokenId;
        bool exists;
    }

    function collectionSupplys(address[] calldata tokenAddresses)
        external
        view
        returns (CollectionSupply[] memory supplys)
    {
        supplys = new CollectionSupply[](tokenAddresses.length);

        for (uint256 i = 0; i < tokenAddresses.length; i++) {
            address tokenAddress = tokenAddresses[i];
            uint256 supply = IERC721Enumerable(tokenAddress).totalSupply();

            supplys[i] = CollectionSupply(tokenAddress, supply);
        }
    }

    function ownerTokenCounts(address[] calldata tokenAddresses, address owner)
        external
        view
        returns (OwnerTokenCount[] memory tokenCounts)
    {
        tokenCounts = new OwnerTokenCount[](tokenAddresses.length);

        for (uint256 i = 0; i < tokenAddresses.length; i++) {
            address tokenAddress = tokenAddresses[i];
            uint256 count = IERC721(tokenAddress).balanceOf(owner);

            tokenCounts[i] = OwnerTokenCount(tokenAddress, count);
        }
    }

    function _tokenOfOwnerByIndex(
        address tokenAddress,
        address owner,
        uint256 index
    ) internal view returns (TokenId memory) {
        try
            IERC721Enumerable(tokenAddress).tokenOfOwnerByIndex(owner, index)
        returns (uint256 tokenId) {
            return TokenId(tokenId, true);
        } catch {
            return TokenId(0, false);
        }
    }

    function ownerTokenIds(
        address tokenAddress,
        address owner,
        uint256 fromIndex,
        uint256 size
    ) external view returns (TokenId[] memory tokenIds) {
        uint256 count = IERC721(tokenAddress).balanceOf(owner);
        uint256 length = size;

        if (length > (count - fromIndex)) {
            length = count - fromIndex;
        }

        tokenIds = new TokenId[](length);

        for (uint256 i = 0; i < length; i++) {
            tokenIds[i] = _tokenOfOwnerByIndex(
                tokenAddress,
                owner,
                fromIndex + i
            );
        }
    }

    function _tokenByIndex(address tokenAddress, uint256 index)
        internal
        view
        returns (TokenId memory)
    {
        try IERC721Enumerable(tokenAddress).tokenByIndex(index) returns (
            uint256 tokenId
        ) {
            return TokenId(tokenId, true);
        } catch {
            return TokenId(0, false);
        }
    }

    function collectionTokenIds(
        address tokenAddress,
        uint256 fromIndex,
        uint256 size
    ) external view returns (TokenId[] memory tokenIds) {
        uint256 count = IERC721Enumerable(tokenAddress).totalSupply();
        uint256 length = size;

        if (length > (count - fromIndex)) {
            length = count - fromIndex;
        }

        tokenIds = new TokenId[](length);

        for (uint256 i = 0; i < length; i++) {
            tokenIds[i] = _tokenByIndex(tokenAddress, fromIndex + i);
        }
    }

    function _tokenOwner(address tokenAddress, uint256 tokenId)
        internal
        view
        returns (TokenOwner memory)
    {
        try IERC721(tokenAddress).ownerOf(tokenId) returns (address owner) {
            return TokenOwner(tokenAddress, tokenId, owner, true);
        } catch {
            return TokenOwner(tokenAddress, tokenId, address(0), false);
        }
    }

    function tokenOwners(TokenOwnerInput[] calldata tokenOwnerInput)
        external
        view
        returns (TokenOwner[] memory owners)
    {
        owners = new TokenOwner[](tokenOwnerInput.length);

        for (uint256 i = 0; i < tokenOwnerInput.length; i++) {
            address tokenAddress = tokenOwnerInput[i].tokenAddress;
            uint256 tokenId = tokenOwnerInput[i].tokenId;
            owners[i] = _tokenOwner(tokenAddress, tokenId);
        }
    }
}