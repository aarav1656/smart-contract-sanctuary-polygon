/**
 *Submitted for verification at polygonscan.com on 2022-09-08
*/

// File: @openzeppelin/contracts/utils/Counters.sol


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


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


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

// File: @openzeppelin/contracts/token/ERC1155/utils/ERC1155Receiver.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;



/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}

// File: @openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;


/**
 * Simple implementation of `ERC1155Receiver` that will allow a contract to hold ERC1155 tokens.
 *
 * IMPORTANT: When inheriting this contract, you must include a way to use the received tokens, otherwise they will be
 * stuck.
 *
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
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

// File: contracts/ERC1155MarketPlace.sol


pragma solidity ^0.8.4;






contract NFT1155Marketplace is Ownable, ERC1155Holder, ReentrancyGuard {
    uint256 public _marketplaceCommissionFee = 250;

    uint256 public _promotionEarnings = 0;

    using Counters for Counters.Counter;
    Counters.Counter private _listingIdCounter;

    enum TokenStatus {
        InSale,
        Sold
    }

     struct Token {
        address contractAddress;
        uint256 tokenId;
        address payable creator;
        address payable owner;
        uint256 copies;
        uint256 unsold_copies;
        uint256 price;
        uint256 royaltyFee;
        uint256 createdAt;
        uint256 expiredAt;
        TokenStatus status;
        bool exists;
    }

    struct Listing {
        uint256 listingId;
        address contractAddress;
        uint256 tokenId;
        address payable owner;
        uint256 price;
        uint256 copies;
        uint256 expiredAt;
        TokenStatus status;
        bool exists;
    }

     // tokens
    mapping(address => mapping(uint256 => Token)) private _tokenMapping;

    // listings
    mapping(uint256 => Listing) private _listingMapping;

    // events
    event MintedListingId(uint256 listingId);

    constructor() {}

    modifier isValidtoSell(address _contractAddress,uint256 _tokenId,uint256 _price,uint256 _amount,uint256 _royaltyFee,uint256 _duration) {
       require(msg.sender != address(0),"Invalid Address");
       require(msg.sender != owner(), "Marketplace Owner can't sell the nft");
       require(!_tokenMapping[_contractAddress][_tokenId].exists,"Token Already Exists");
       require(_price >= 1000000000000 ,"Minimum price is required");
       require(_amount > 0,"Amount is required");
       require(_duration > 0,"Duration is required"); 
        _;
    }

    modifier isValidtoBuy(uint256 _listingId, uint256 _amount) {

        require(_listingMapping[_listingId].exists,"Listing does not exists");

        uint256 _tokenPrice = _listingMapping[_listingId].price;
        uint256 _tokenExpiredAt = _listingMapping[_listingId].expiredAt;
        TokenStatus _tokenStatus = _listingMapping[_listingId].status;

        require(msg.sender != address(0),"Invalid Address");
        require(msg.sender != owner(), "Marketplace Owner can't buy the nft");
        require(msg.value != 0 ,"Paid amount is 0");
        require(msg.value >=_tokenPrice,"Paid amount is less than price");
        require(_tokenExpiredAt > block.timestamp,"Time up! Sale ended");
        require(_tokenStatus == TokenStatus.InSale,"NFT is not in sale");
        
        _;
    }

    modifier isValidtoReSell(address _contractAddress,uint256 _tokenId,uint256 _listingId, uint256 _price,uint256 _amount,uint256 _duration) {
       require(msg.sender != address(0),"Invalid Address");
       require(msg.sender != owner(), "Marketplace Owner can't sell the nft");
       require(_tokenMapping[_contractAddress][_tokenId].exists,"Token does not exists");
       require(_listingMapping[_listingId].owner == msg.sender,"Only owner can resell the item");
       require(_price >= 1000000000000 ,"Minimum price is required");
       require(_amount > 0,"Amount is required");
       require(_duration > 0,"Duration is required"); 
        _;
    }

    modifier isTokenExists(uint256 _listingId) {
        require(_listingMapping[_listingId].exists,"NFT does not exists");
        _;
    }

    modifier isTokenActive(uint256 _listingId) {
        TokenStatus _tokenStatus = _listingMapping[_listingId].status;
        require(_tokenStatus == TokenStatus.InSale,"NFT is not in sale");
        _;
    }

    // List NFT to Marketplace
    function sellNFT(
        address _contractAddress,
        uint256 _tokenId,
        uint256 _price,
        uint256 _amount,
        uint256 _royaltyFee,
        uint256 _duration
    ) isValidtoSell(_contractAddress,_tokenId,_price,_amount,_royaltyFee,_duration) public {

        _tokenMapping[_contractAddress][_tokenId] = Token(
            _contractAddress,
            _tokenId,
            payable(msg.sender),
            payable(msg.sender),
            _amount,
            _amount,
            _price,
            _royaltyFee * 100,
            block.timestamp,
            block.timestamp + _duration,
            TokenStatus.InSale,
            true
        );

        _listingIdCounter.increment();
         uint256 _listingId = _listingIdCounter.current();

        _listingMapping[_listingId] = Listing(
            _listingId,
            _contractAddress,
            _tokenId,
            payable(msg.sender),
            _price,
            _amount,
            block.timestamp + _duration,
            TokenStatus.InSale,
            true
        );

        IERC1155(_contractAddress).safeTransferFrom(msg.sender,address(this),_tokenId,_amount,"");

        emit MintedListingId(_listingId);
    }

    // Buy NFT from Marketplace
    function buyNFT(
        uint256 _listingId,
        uint256 _amount
    ) isValidtoBuy(_listingId,_amount) public payable {
        
        uint256 _tokenId = _listingMapping[_listingId].tokenId;
        address _tokenContract = _listingMapping[_listingId].contractAddress;
        address _tokenOwner = _listingMapping[_listingId].owner;
        address _tokenCreator = _tokenMapping[_tokenContract][_tokenId].creator;
        uint256 _tokenRoyalty = _tokenMapping[_tokenContract][_tokenId].royaltyFee;

        // transfer royalty to creator
        uint256 _tokenCopies = _amount;
        uint256 _tokenListingId = _listingId;
        uint256 _ownerEarnings = 0;
        uint256 _creatorEarnings = 0;
        uint256 _marketplaceEarnings = 0;

        require(msg.sender != _tokenOwner, "Current NFT Owner can't buy the nft");

        // transfer royalty
        if (_tokenCreator != msg.sender) {
            _creatorEarnings =(msg.value * _tokenRoyalty) / 10000;    
            payable(_tokenCreator).transfer(_creatorEarnings);
        }

        // transfer commission
        _marketplaceEarnings = (msg.value * _marketplaceCommissionFee) / 10000;
        payable(owner()).transfer(_marketplaceEarnings);

        // transfer seller earnings
        _ownerEarnings = (msg.value - _marketplaceEarnings) - _creatorEarnings;
        payable(_tokenOwner).transfer(_ownerEarnings);

        _listingIdCounter.increment();
        uint256 listingNewId = _listingIdCounter.current();
        _listingMapping[listingNewId] = Listing(
            listingNewId,
            _tokenContract,
            _tokenId,
            payable(msg.sender),
             0,
            _tokenCopies,
            block.timestamp,
            TokenStatus.Sold,
            true
        );

        _tokenMapping[_tokenContract][_tokenId].unsold_copies -= _tokenCopies;
        _listingMapping[_tokenListingId].copies -= _tokenCopies;

        if(_tokenMapping[_tokenContract][_tokenId].unsold_copies == 0) {
            _tokenMapping[_tokenContract][_tokenId].status = TokenStatus.Sold;   
        }

        if(_listingMapping[_tokenListingId].copies == 0) {
            _listingMapping[_tokenListingId].status = TokenStatus.Sold; 
        }

        IERC1155(_tokenContract).safeTransferFrom(
            address(this),
            msg.sender,
            _tokenId,
            _tokenCopies,
            ""
        );

        emit MintedListingId(listingNewId);
    }

    function resellNFT(
        address _contractAddress,
        uint256 _tokenId,
        uint256 _listingId,
        uint256 _price,
        uint256 _amount,
        uint256 _duration
    ) isValidtoReSell(_contractAddress,_tokenId,_listingId,_price,_amount,_duration)public {
        _tokenMapping[_contractAddress][_tokenId].owner = payable(msg.sender);
        _tokenMapping[_contractAddress][_tokenId].price = _price;
        _tokenMapping[_contractAddress][_tokenId].expiredAt = block.timestamp +_duration;
        _tokenMapping[_contractAddress][_tokenId].status = TokenStatus.InSale;

        _listingIdCounter.increment();
        uint256 listingNewId = _listingIdCounter.current();
        _listingMapping[listingNewId] = Listing(
            listingNewId,
            _contractAddress,
            _tokenId,
            payable(msg.sender),
            _price,
            _amount,
            block.timestamp + _duration,
            TokenStatus.InSale,
            true
        );
      
        _tokenMapping[_contractAddress][_tokenId].unsold_copies += _amount;
        _tokenMapping[_contractAddress][_tokenId].status = TokenStatus.InSale;
        IERC1155(_contractAddress).safeTransferFrom(
            msg.sender,
            address(this),
            _tokenId,
            _amount,
            ""
        );

        emit MintedListingId(listingNewId);
    }

    function listingDetails(uint256 _listingId) public view returns (Listing memory)
    {
        return _listingMapping[_listingId];
    }

     // Cancel NFT from sale
    function cancelNFT(uint256 _listingId) public isTokenExists(_listingId) isTokenActive(_listingId) {
        require(msg.sender ==  _listingMapping[_listingId].owner, "Only owner can cancel the nft");
        _listingMapping[_listingId].status = TokenStatus.Sold;
        _listingMapping[_listingId].owner = payable(msg.sender);
        address _tokenContract = _listingMapping[_listingId].contractAddress;
        uint256 _tokenId = _listingMapping[_listingId].tokenId;
        uint256 _tokenCopies = _listingMapping[_listingId].copies;
        IERC1155(_tokenContract).safeTransferFrom(address(this),msg.sender,_tokenId,_tokenCopies,"");
    }

    function promoteNFT(address _contractAddress,uint256 _tokenId) public payable{
        require(msg.sender != address(0),"Invalid Address");
        require(msg.sender != owner(), "Marketplace Owner can't promote the nft");
        require(_tokenMapping[_contractAddress][_tokenId].exists,"Token Does Not Exists");
        require(_tokenMapping[_contractAddress][_tokenId].status == TokenStatus.InSale,"NFT is not in sale");
        require(_tokenMapping[_contractAddress][_tokenId].expiredAt > block.timestamp,"Time up! Sale ended");
        require(msg.value >= 10000000000000 ,"Minimum price is required");
        _promotionEarnings+=msg.value;
        payable(owner()).transfer(msg.value);
    }

    function promotionEarnings() public view returns(uint256 earnings){
        return _promotionEarnings;
    }
}