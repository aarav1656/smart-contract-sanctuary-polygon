// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract OfferingRegistry is Ownable {
    IERC721 public nftCollection;

    struct Offering {
        address offerer;
        address fulfiller;
        uint256 price;
        uint256 startTime;
        uint256 endTime;
        bool closed;
        bool cancelled;
    }
    mapping(uint256 => Offering[]) public offers; // token id => offer
    mapping(address => uint256) public idToOffer; // buyer => offer index

    event OfferPlaced(address offerer, address fulfiller, uint256 _tokenId, uint256 _amount, uint256 _remainingTime);
    event OfferAccepted(address offerer, address fulfiller, uint256 _tokenId, uint256 _amount, uint256 _acceptedTime);

    /**
        @dev initializes the contract addresses
        @notice only contract owner can access this 
     */
    function initialize(address _nftAddress) external onlyOwner {
        nftCollection = IERC721(_nftAddress);
    }

    /**
        @dev places an offer on a token with an amount that the user can afford
             user will be required to approve this cotnract to transfer their MATIC token
     */
    function placeOfferring(uint256 _tokenId, uint256 _amount, uint256 _endTime) payable external {
        require(msg.value == _amount, "Please deposit the exact amount.");
        require(block.timestamp < _endTime, "Time range is incorrect.");
        require(_amount > 0, "Please enter a Non-Negative number");
        
        Offering memory offer;
        offer.offerer = msg.sender;
        offer.fulfiller = nftCollection.ownerOf(_tokenId);
        offer.price = _amount;
        offer.startTime = block.timestamp;
        offer.endTime = _endTime;

        offers[_tokenId].push(offer);
        idToOffer[msg.sender] = offers[_tokenId].length - 1;

        uint256 id = idToOffer[msg.sender];

        uint256 timeLeft = _endTime - offers[_tokenId][id].startTime;

        emit OfferPlaced(msg.sender, offers[_tokenId][id].fulfiller, _tokenId, _amount, timeLeft);
    }

    /**
        @dev accepts offer on a token.
             seller will be required to approve this contract to transfer their token
        @notice only the owner of the token can accept the offer and the period should still be valid
     */
    function acceptOfferring(address _offerer, uint256 _tokenId) public {
        uint256 id = idToOffer[_offerer];

        require(!offers[_tokenId][id].cancelled, "This offer is no longer available.");
        require(offers[_tokenId][id].endTime >= block.timestamp, "You can not accept expired offers.");
        require(nftCollection.ownerOf(_tokenId) == msg.sender, "Only token owner can accept offers.");

        offers[_tokenId][id].closed = true;

        nftCollection.transferFrom(
            offers[_tokenId][id].fulfiller,
            offers[_tokenId][id].offerer,  
            _tokenId
        );

        payable(offers[_tokenId][id].fulfiller).transfer(offers[_tokenId][id].price);

        emit OfferAccepted(
            msg.sender,
            offers[_tokenId][id].fulfiller,
            offers[_tokenId][id].price,
            _tokenId,
            block.timestamp
        );
    }

    /**
        @dev cancels an offer placed on a token and transfers tokens locked back to the offerer
     */
    function cancelOfferring(uint256 _tokenId) public {
        uint256 id = idToOffer[msg.sender];

        require(!offers[_tokenId][id].closed, "This offer is already closed.");

        offers[_tokenId][id].cancelled = true;

        payable(offers[_tokenId][id].offerer).transfer(offers[_tokenId][id].price);
    }

    function fetchOfferId(address _offerer) public view returns (uint256) {
        return idToOffer[_offerer];
    }

    /**
        @dev returns the offers placed on a token
     */
    function fetchOfferrings(uint256 _id, uint256 _tokenId) public view returns (Offering[] memory) {
        uint256 amountOfOffers = offers[_tokenId].length;

        Offering[] memory offerings = new Offering[](amountOfOffers);

        for(uint256 i = 0; i < amountOfOffers; i++) {
            offerings[i] = offers[_tokenId][_id];
        }
        return offerings;
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