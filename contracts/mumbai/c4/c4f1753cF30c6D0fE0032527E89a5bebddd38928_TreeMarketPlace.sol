// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {Counters} from "@openzeppelin/contracts/utils/Counters.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";
import {ITreeMarketPlace} from "./interface/ITreeMarketPlace.sol";

contract TreeMarketPlace is
    Ownable,
    ReentrancyGuard,
    Pausable,
    ITreeMarketPlace
{
    // TODO: List NFT Feature -- DONE
    // TODO: Unlist NFT Feature -- DONE
    // TODO: Buy NFT Feature -- DONE
    // GET MY NFTS
    // GET LISTED NFTS

    using Counters for Counters.Counter;

    Counters.Counter private s_artifactIds;
    Counters.Counter private s_artifactListed;

    address private s_treeTokenAddress;
    uint256 private s_listingPrice;

    constructor(address treeTokenAddress_, uint256 listingPrice_) {
        s_treeTokenAddress = treeTokenAddress_;
        s_listingPrice = listingPrice_;
    }

    struct Artifact {
        uint256 artifactId;
        uint256 tokenId;
        uint256 price;
        uint256 loyaltyPercentage;
        address payable seller;
        address payable owner;
    }

    mapping(uint256 => bool) private s_isListed;
    mapping(uint256 => Artifact) public s_idToArtifact;

    modifier whenArtifactIsNotListed(uint256 _tokenId) {
        require(
            s_isListed[_tokenId] == false,
            "TreeMarketPlace: Artifact Is Already Listed"
        );
        _;
    }

    modifier whenArtifactIsListed(uint256 _tokenId) {
        require(
            s_isListed[_tokenId] == true,
            "TreeMarketPlace: Artifact Is Not Listed"
        );
        _;
    }

    function listArtifact(
        uint256 _tokenId,
        uint256 _price,
        uint256 _loyaltyPercentage
    )
        external
        payable
        whenNotPaused
        whenArtifactIsNotListed(_tokenId)
        nonReentrant
    {
        s_artifactListed.increment();
        IERC721 treeToken = IERC721(s_treeTokenAddress);
        address treeTokenOwner = treeToken.ownerOf(_tokenId);

        require(_price > 0, "TreeMarketPlace: Price Must Be Greater Than 0");
        require(
            msg.value == s_listingPrice,
            "TreeMarketPlace: Not Enough Funds To Pay Listing Fees"
        );
        require(
            msg.sender == treeTokenOwner,
            "TreeMarketPlace: You Must Own This NFT To List"
        );

        s_artifactIds.increment();
        uint256 artifactId = s_artifactIds.current();

        s_idToArtifact[artifactId] = Artifact(
            artifactId,
            _tokenId,
            _price,
            _loyaltyPercentage,
            payable(msg.sender),
            payable(treeTokenOwner)
        );

        s_isListed[artifactId] = true;

        emit ArtifactListed(artifactId,_tokenId,_price,_loyaltyPercentage,msg.sender,treeTokenOwner);
    }

    function unListArtifact(uint256 _artifactId)
        external
        nonReentrant
        whenNotPaused
        whenArtifactIsListed(_artifactId)
    {
        Artifact memory currentArtifact = s_idToArtifact[_artifactId];
        IERC721 treeToken = IERC721(s_treeTokenAddress);
        address ownerOfToken = treeToken.ownerOf(currentArtifact.tokenId);

        require(
            msg.sender == ownerOfToken,
            "TreeMarketPlace: Only Owner Of This NFT Can Call This Function"
        );

        s_isListed[_artifactId] = false;
        s_artifactListed.decrement();

        emit ArtifactUnListed(_artifactId);
    }

    function purchaseArtifact(uint256 _artifactId) external payable nonReentrant whenNotPaused {
        require(s_isListed[_artifactId] == true, "TreeMarketPlace: Artifact Must Be Listed");

        Artifact memory currentArtifact = s_idToArtifact[_artifactId];

        uint256 price = currentArtifact.price;
        uint256 tokenId = currentArtifact.tokenId;
        uint256 artifactId = currentArtifact.artifactId;
        address seller = currentArtifact.seller;

        require(msg.value == price,"TreeMarketPlace: Not Enough Funds To Purchase Artifact");

        IERC721 treeToken = IERC721(s_treeTokenAddress);

        treeToken.transferFrom(seller,msg.sender,tokenId);

        s_isListed[artifactId] = false;
        s_artifactListed.decrement();


        emit ArtifactPurchased(tokenId,price,seller);

    }

    function updateListingPrice(uint256 _newListingPrice)
        external
        override
        onlyOwner
    {
        uint256 oldListingPrice = s_listingPrice;
        s_listingPrice = _newListingPrice;
        emit ListingPriceUpdated(oldListingPrice, s_listingPrice);
    }

    function updateTreeTokenAddress(address _treeTokenAddress) external onlyOwner {
        address oldTokenAddress = s_treeTokenAddress;
        s_treeTokenAddress = _treeTokenAddress;

        emit TreeTokenAddressUpdated(oldTokenAddress,_treeTokenAddress);
    }

    function pause() external whenPaused onlyOwner {
        _pause();
    }

    function unpause() external whenNotPaused onlyOwner {
        _unpause();
    }

    function getListingPrice() public view override returns (uint256) {
        return s_listingPrice;
    }

    function getTreeTokenAddress() public view override returns (address) {
        return s_treeTokenAddress;
    }

    function getTotalArtifactsIds() public view override returns (uint256) {
        return s_artifactIds.current();
    }

    function getIsListed(uint256 _tokenId) public view returns (bool) {
        return s_isListed[_tokenId];
    }

    function getArtifactsListed() public view returns(Artifact[] memory) {
        uint256 listedCount = s_artifactListed.current();
        uint256 currentIndex = 0;

        Artifact[] memory items = new Artifact[](listedCount);

        for (uint256 i = 0; i < items.length; i++) {
            if (s_isListed[i+1] == true) {
                uint256 currentId = i + 1;

                Artifact storage currentItem = s_idToArtifact[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }

        return items;
    }

    function getArtifactsListedByMe() public view returns(Artifact[] memory) {
        uint256 totalArtifactCount  = s_artifactIds.current();
        uint256 itemCount = 0;
        uint256 currentIndex = 0;


        for (uint256 i = 0; i < totalArtifactCount; i++) {
            if (s_idToArtifact[i + 1].owner == msg.sender) {
                itemCount += 1;
            }
        }

        Artifact[] memory items = new Artifact[](itemCount);
        for (uint256 i = 0; i < totalArtifactCount; i++) {
            if (s_idToArtifact[i + 1].owner == _msgSender()) {
                uint256 currentId = i + 1;
                Artifact storage currentItem = s_idToArtifact[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ITreeMarketPlace {
    event ListingPriceUpdated(uint256 oldListingPrice, uint256 newListingPrice);

    event ArtifactListed(uint256 artifactId, uint256 tokenId, uint256 price, uint256 loyaltyPercentage, address seller, address owner);

    event ArtifactUnListed(uint256 artifactId);

    event ArtifactPurchased(uint256 tokenId,uint256 price,address seller);

    event TreeTokenAddressUpdated(address oldTokenAddress,address newTokenAddress);

    function updateListingPrice(uint256 _newListingPrice) external;

    function getListingPrice() external view returns (uint256);

    function getTreeTokenAddress() external view returns (address);

    function getTotalArtifactsIds() external view returns (uint256);
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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
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