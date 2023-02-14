// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../IMoaCore.sol";

/**
 * @notice once-off contract for Batch minting for Gen 1 Moa.
 */
contract Gen1BatchMinter is Ownable {
    address public nftAddress;

    uint256[] public genZeroTokens;

    uint256 public quota;

    constructor(address _nftAddress, uint256 _quota) {
        require(_nftAddress != address(0));
        require(_quota > 0);
        nftAddress = _nftAddress;
        quota = _quota;
    }

    function setGenZeroTokens(uint256[] calldata _genZeroTokens)
        public
        onlyOwner
    {
        genZeroTokens = _genZeroTokens;
    }

    function setNftAddress(address _nftAddress) public onlyOwner {
        require(_nftAddress != address(0));
        nftAddress = _nftAddress;
    }

    /**
     * @notice batch mint Gen 1 Moa to target address
     * @dev Required BOSS_ROLE of MoaCore contract
     * @param to owner address of newly minted Moa
     * @param count number of Gen1 Moa to be minted
     */
    function batchMintGen1(address to, uint256 count) public onlyOwner {
        // check
        require(count <= quota);
        require(genZeroTokens.length >= 4); // require the genZeroTokens to be correctly setup
        require(genZeroTokens.length % 2 == 0); // require the genZeroTokens to be correctly setup
        // effects
        quota = quota - count;
        // interactions
        for (uint256 i = 0; i < count; i++) {
            _draw(to, i);
        }
    }

    /**
      @notice draw an MoA Gen1
      @dev assume that the contract have BOSS_ROLE to call mintGen1()
      @param to owner of the new Gen1 MoA
      @return tokenId the newly birth MoA tokenId
     */
    function _draw(address to, uint256 count)
        internal
        returns (uint256 tokenId)
    {
        IERC721Enumerable erc721 = IERC721Enumerable(nftAddress);
        IMoaCore moaCore = IMoaCore(nftAddress);

        uint256 randomN = _pseudoRandom(
            count,
            erc721.balanceOf(to), // it should be costly to manipulate how much MoA owned
            erc721.totalSupply() // it should be hard to manipulate the totalSupply of MoA
        );

        // 1) we put the result of 1st random token at [0]
        /// @dev assumption, M+F of the same species is adjacent. swap the pair [0,1] with the 1st randomed pair
        uint256[] memory tmpArray = genZeroTokens;
        uint256 index1 = _sliceNumber(randomN, 16, 0) % tmpArray.length;
        uint256 index1o = (index1 % 2) == 0 ? index1 + 1 : index1 - 1;
        uint256 tokenId1 = tmpArray[index1];
        tmpArray[index1] = tmpArray[0];
        // tmpArray[0] = tokenId1; // we do not use [0] again, so do not actually need the full swap
        tmpArray[index1o] = tmpArray[1];
        // tmpArray[0] = tokenId1; // we do not use [1] again, so do not actually need the full swap

        // we need to random 2 elements from genZeroTokens:
        // 2) random another index from 2 to array.length-1
        uint256 index2 = 2 +
            (_sliceNumber(randomN, 16, 16) % (tmpArray.length - 2));

        // Interactions:
        tokenId = moaCore.mintGen1(tokenId1, tmpArray[index2], to);
    }

    function _sliceNumber(
        uint256 _n,
        uint256 _nbits,
        uint256 _offset
    ) private pure returns (uint256) {
        // mask is made by shifting left an offset number of times
        uint256 shiftBits = 256 - _nbits - _offset;
        uint256 mask = uint256((2**_nbits) - 1);
        return uint256((_n >> shiftBits) & mask);
    }

    function _pseudoRandom(
        uint256 seed1,
        uint256 seed2,
        uint256 seed3
    ) internal view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        blockhash(block.number - 1),
                        nftAddress,
                        seed1,
                        seed2,
                        seed3
                    )
                )
            );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

///@dev MoaCore provide methods to update contract information
interface IMoaCore {
    /// @dev pause the Contract
    function pause() external;

    /// @dev unpause the Contract
    function unpause() external;

    /// @dev update the GeneScience contract adress
    function setGeneScienceAddress(address _address) external;

    /// @dev mint a Gen0 MoA to the msg.sender.
    function mintGen0(uint256 _genes) external returns (uint256);

    /// @dev mint a Gen1 MoA to the "to" address.
    function mintGen1(uint256 _coreId, uint256 _supportId, address _to) external returns (uint256);

    /// @dev Retrieve a Moa struct by given tokenId
    function getMoa(uint256 _moaId)
        external
        view
        returns (
            bool isCultivating,
            bool isReadyToComplete,
            bool isReadyToCultivate,
            uint256 restingCooldownIndex,
            uint256 birthCooldownIndex,
            uint256 cultivatingWithId,
            uint256 birthTime,
            uint256 coreId,
            uint256 supportId,
            uint256 generation,
            uint256 genes,
            uint256 autoBirthFee
        );

    /// @dev update Royalty Info
    /// @param _receiver MoA's artist address
    /// @param _royaltyFeesInBips precentage of the royalty fee
    function setRoyaltyInfo( address _receiver, uint96 _royaltyFeesInBips) external;

    /// @dev add/remove prefined operator permission
    function setPredefinedOperators(address operator, bool approved) external;
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

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