// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
//import "hardhat/console.sol";
import "./TefNFTFactory.sol";
import "./TefNFT.sol";


/// Custom Errors
error PriceNotMet(uint256 tokenId, uint256 price);
error ItemNotForSale(uint256 tokenId);
error FeesOutOfRange();
error NotOwner();
error NotApprovedForMarketplace();
error PriceMustBeAboveZero();
error CollectionNotExist();
error InvalidData();
error ItemNotFound();


/**
 * @title Telefónica NFT Marketplace with ERC-2981 support
 * @notice Defines a marketplace to buy and sell NFTs.
 *         Sends royalties to rightsholder on each sale if applicable.
 */
contract Marketplace is ReentrancyGuard, Ownable {
    /// Marketplace version constant
    string private constant VERSION = "0.4.1";

    using Counters for Counters.Counter;
    /// Number of NFTs listed in the marketplace
    Counters.Counter private _itemCounter;
    /// Number of NFTs items sold until now
    Counters.Counter private _itemSoldCounter;
    /// Number of creators in marketplace (whitelisted)
    Counters.Counter private _creatorsCounter;
    /// Number of collections in the marketplace
    Counters.Counter private _collectionsCounter;
    /// Market Owner address (Telefonica operational address)
    address private _marketOwner;
    /// Payable Telefonica address (Telefonica payable address)
    address payable private _payableAddress;
    /// Address reference to the TefNFTFactory for creating collections
    address private _contractFactory;
    /// Fee percentage for Telefonica * 100 (eg 2.5% is 250)
    uint256 private _listingFees = 250;
    /// Max percentage fees * 10
    uint256 constant MAXIMUM_FEES = 9500;
    /// Constant fees factor 10000
    uint256 constant FACTOR_FEES = uint256(1e4);
    /// NFT Status, useful for selling, hidden objects and so on
    enum NFTStatus {
        LISTED,
        DELISTED,
        SOLD,
        UNKNOWN
    }
    
    /// NFT Struct, contains all the relevant info for the marketplace
    struct MarketItem {
        TefNFT collection;
        uint256 collectionId;
        uint256 tokenId;
        address payable owner;
        address payable buyer;
        uint256 price;
        NFTStatus status;
    }
    /// Whitelist addresses for creators
    mapping(address => bool) private _whitelistedAddresses;
    /// Mapping storing all market items
    mapping(uint256 => mapping(uint256 => MarketItem)) private _marketItems;
    /// Mapping all collections created in the marketplace
    mapping(uint256 => TefNFT) private _collections;

    // Events
    event CollectionCreated(
        string name,
        uint256 uuid,
        uint256 collectionId,
        address collectionAddress,
        address owner
    );
    event NFTMinted(
        address recipient,
        uint256 tokenId,
        uint96 authorFee,
        uint256 uuid,
        address collectionAddress
	);
    event NFTListed(
        uint256 itemId,
        address owner,
        uint256 price,
        address collectionAddress
    );
    event NFTUpdated(
        uint256 itemId,
        address owner,
        uint256 price,
        address collectionAddress,
        string uri
    );
    event NFTDelisted(
        uint256 tokenId,
        address owner,
        address collectionAddress
    );
    event NFTSold(
        uint256 tokenId,
        address owner,
        address buyer,
        uint256 price,
        address collectionAddress
    );
    event NFTRemoved(
        address collectionAddress,
        uint256 tokenId,
        address owner
    );
    event MarketFeesChanged(
        uint256 newFees
    );

    // Modifiers
    /// Check if the caller is in the creators whitelist
    modifier onlyWhitelist() {
        if (!_whitelistedAddresses[msg.sender]) {
            revert NotApprovedForMarketplace();
        }
        _;
    }

    /// Check if the caller is owner of the market item
    modifier isOwner(uint256 idCollection ,uint256 tokenId) {
        if (msg.sender != _marketItems[idCollection][tokenId].owner) {
            revert NotOwner();
        }
        _;
    }

    /// Check if the collection with `collectionId` exists in the marketplace
    modifier collectionExist(uint256 collectionId) {
        if (address(_collections[collectionId]) == address(0x0)) {
            revert CollectionNotExist();
        }
        _;
    }

    // Owner functions

    /// @notice Marketplace constructor
    /// @param payableFees The address where by default all the Market fees where sending
    /// @param contractFactory The factory address for the creating collections Smart Contract
    constructor(address payableFees, address contractFactory) {
        if (payableFees == address(0x0) || contractFactory == address(0x0)) {
            revert AddressZeroOrNull();
        }
        _marketOwner = msg.sender;
        _contractFactory = contractFactory;
        _payableAddress = payable(payableFees);
    }

    /// @notice Returns the version of the Smart Contract
    function getVersionNumber() public view onlyOwner returns (string memory) {
        return VERSION;
    }

    /// @notice Returns the fees in basic points of the Marketplace
    function getListingFees() public view onlyOwner returns (uint256) {
        return _listingFees;
    }

    /// @notice Set new fees in basic points for the Marketplace
    /// @param newFees The new fee to apply, in basic points (x100)
    function setListingFees(uint newFees) public payable onlyOwner {
        if (newFees >= MAXIMUM_FEES) {
            revert FeesOutOfRange();
        }
        _listingFees = newFees;

        emit MarketFeesChanged(newFees);
    }

    /// @notice Get all the NFTs in the marketplace, listed, unlisted, sold, whatever state
    /// @dev Onlyowner method
    /// @return Array list of all of the listed items in the market
    function fetchAllMarketItems() public view onlyOwner returns (MarketItem[] memory) {
        uint256 _totalItems = _itemCounter.current();
        uint256 _totalCollections = _collectionsCounter.current();
        uint256 index = 0;
        MarketItem[] memory items = new MarketItem[](_totalItems);
        for (uint256 i = 1; i <= _totalCollections; i++) {
            for (uint256 j = 1; j <= _totalItems; j++) {
                if (_marketItems[i][j].tokenId > 0) {
                    items[index] = _marketItems[i][j];
                    index++;
                } else {
                    break;
                }
            }
        }
        return items;
    }

    /// @notice Adds the argument address in the whitelist of the Market and identifies as creator
    /// @param creatorAddress the address for adding to SC whitelist with Creator profile
    function addCreator(address creatorAddress) public onlyOwner {
        if (address(creatorAddress) == address(0x0)) {
            revert AddressZeroOrNull();
        }

        if (!_whitelistedAddresses[creatorAddress]) {
            _creatorsCounter.increment();
            _whitelistedAddresses[creatorAddress] = true;
        }
    }

    /// @notice Removes the argument address for the creators' whitelist of the Market
    /// @param creatorAddress the address for removing to SC whitelist with Creator profile
    function removeCreator(address creatorAddress) public onlyOwner {
        if (address(creatorAddress) == address(0)) {
            revert AddressZeroOrNull();
        }
        
        if (_whitelistedAddresses[creatorAddress]) {
            _creatorsCounter.decrement();
            _whitelistedAddresses[creatorAddress] = false;
        }
    }

    /// @notice Set a new marketplace address for all the TefNFT collection tokens
    /// @param newAddress the address of the new market
    function setMarketCollection(address newAddress) public onlyOwner nonReentrant {
        for (uint256 i = 1; i <= _collectionsCounter.current(); i++) {
             _collections[i].setMarketAddress(newAddress);
         }
    }

    /// @notice Returns the number of creators in whitelist of the Market
    /// @return number the actual number of creators accepted in the Marketplace
    function getNumberOfCreators() public view onlyOwner returns (uint256) {
        return _creatorsCounter.current();
    }

    /// @notice Set the TefNFT collections passed as arguments as the market collections
    /// @dev Onlyowner method
    /// @param collections the collection address array to set in the marketplace
    function setCollections(address[] memory collections) public onlyOwner {
        for (uint256 i = 0; i < collections.length; i++) {
            _collectionsCounter.increment();
            TefNFT tefNFT = TefNFT(collections[i]);
            _collections[_collectionsCounter.current()] = tefNFT;
        }
    }

    /// @notice Set the market items passed as arguments
    /// @dev Onlyowner method
    /// @param collectionIds the collection Ids array to set in the marketplace
    /// @param tokenIds the tokenIds array to set in the marketplace
    /// @param owners the owner array of the items to set in the marketplace
    /// @param buyers the buyer array of the items to set in the marketplace
    /// @param prices the prices array to set in the marketplace
    /// @param statuses the statuses array to set in the marketplace
    function setMarketItems(
        uint256[] memory collectionIds,
        uint256[] memory tokenIds, 
        address[] memory owners,
        address[] memory buyers,
        uint256[] memory prices,
        uint[] memory statuses)
        public onlyOwner
    {
        for (uint256 i = 0; i < collectionIds.length; i++) {
            _marketItems[collectionIds[i]][tokenIds[i]] = MarketItem(
                _collections[collectionIds[i]],
                collectionIds[i],
                tokenIds[i],
                payable(owners[i]),
                payable(buyers[i]),
                prices[i],
                NFTStatus(statuses[i])
            );
            _itemCounter.increment();
        }
    }

    // ONLY CREATORS methods (whitelisted)

    /// @notice Create collection of NFTs
    /// @param name Collection name
    /// @param symbol Collection symbol
    /// @param initialRoyaltiesReceiver author addresss
    /// @param uuid UUID to track events in the backend
    /// @return token identifier of the NFT in the collection
    function createCollection(
        string memory name, 
        string memory symbol, 
        address initialRoyaltiesReceiver, 
        uint256 uuid) 
        public onlyWhitelist returns (uint256)
    {
        TefNFTFactory factory = TefNFTFactory(_contractFactory);
        TefNFT collection = factory.createCollectionSC(name, symbol, initialRoyaltiesReceiver, msg.sender);
        _collectionsCounter.increment();
        uint countCollections = _collectionsCounter.current();
        _collections[countCollections] = collection;

        emit CollectionCreated(name, uuid, countCollections, address(_collections[countCollections]), collection.owner());
        return countCollections;
    }
    
    /// @notice Create collection of nfts with mint in batch mode
    /// @param name Collection name
    /// @param symbol Collection symbol
    /// @param initialRoyaltiesReceiver address where the author royalties are received
    /// @param metadataNFT String array metadataURI for each NFT
    /// @param authorFeeNFT Array of fee percentage for each NFT
    /// @param price Price array for each NFT
    /// @param uuidNFT UUID array (uint256) for tracking each NFT
    /// @param uuidCollection UUID array (uint256) for tracking each NFT
    /// @return collectionId for the new collection created in the Marketplace
    function createCollectionBatch(
        string memory name,
        string memory symbol,
        address initialRoyaltiesReceiver,
        string[] memory metadataNFT,
        uint96[] memory authorFeeNFT,
        uint256[] memory price,
        uint256[] memory uuidNFT,
        uint256 uuidCollection)
        public onlyWhitelist returns (uint256)
    {
        // Same length in all data arrays
        if (!(metadataNFT.length == authorFeeNFT.length && metadataNFT.length == price.length && metadataNFT.length == uuidNFT.length)) {
            revert InvalidData();
        }

        TefNFTFactory factory = TefNFTFactory(_contractFactory);
        TefNFT collection = factory.createCollectionSC(name, symbol, initialRoyaltiesReceiver, msg.sender);
        _collectionsCounter.increment();
        uint collectionId = _collectionsCounter.current();
        _collections[collectionId] = collection;
        for (uint256 i = 0; i < metadataNFT.length; ++i) {
            mintAndListItem(collectionId, metadataNFT[i], price[i], authorFeeNFT[i], uuidNFT[i]);
        }

        emit CollectionCreated(name, uuidCollection, collectionId, address(collection), collection.owner());
        return collectionId;
    }

    /// @notice Obtain collection reference from the Marketplace
    /// @param collectionId the Id of the collection to read the address
    /// @return the address of the collectionId passed as argument
    function getCollection(
        uint256 collectionId) 
        public view onlyWhitelist collectionExist(collectionId) returns (TefNFT)
    {
        return _collections[collectionId];
    }
    
    /// @notice Mint NFTs from specific collection
    /// @param collectionId the Id of the collection to mint the NFTs
    /// @param metadataURI the IPFS hash of the NFT metadata
    /// @param authorFee author fee percentage for the NFT in basis points (*100)
    /// @return the token identifier of the NFT in the collection
    function mint(
        uint256 collectionId, 
        string memory metadataURI, 
        uint96 authorFee,
        uint256 uuid)
        public onlyWhitelist collectionExist(collectionId) returns (uint256)
    {   
        TefNFT collection = _collections[collectionId];
        /// Only the owner of the collection can mint items
        if (collection.owner() != msg.sender) {
            revert NotOwner();
        }
        uint256 tokenId = collection.mint(msg.sender, metadataURI, authorFee);

        emit NFTMinted(collection.owner(), tokenId, authorFee, uuid, address(collection));
        return tokenId;
    }
    
    /// @notice List item (NFT) from specific collection with a specific price
    /// @param collectionId the Id of the collection to mint the NFTs
    /// @param tokenId the Id of the token (NFT) in the specified collection
    /// @param price price to be listed in the market in MATICS in basis points (*100)
    /// @return the tokenId of the item in the market
    function listItem(
        uint256 collectionId, 
        uint256 tokenId, 
        uint256 price)
        public onlyWhitelist collectionExist(collectionId) returns (uint256)
    {
        /// Only the owner of the collection can list items
        TefNFT collection = _collections[collectionId];
        if (collection.owner() != msg.sender) {
            revert NotOwner();
        }
        if (price <= 0) { 
            revert PriceMustBeAboveZero();
        }
        if (!collection.existsToken(tokenId)) {
            revert ItemNotFound();
        }
        if (IERC721(collection).getApproved(tokenId) != address(this)) {
            revert NotApprovedForMarketplace();
        }
        
        _itemCounter.increment();
        _marketItems[collectionId][tokenId] = MarketItem(
            collection,
            collectionId,
            tokenId,
            payable(msg.sender),
            payable(address(0)),
            price,
            NFTStatus.LISTED
        );
        IERC721(collection).transferFrom(msg.sender, address(this), tokenId);

        emit NFTListed(tokenId, msg.sender, price, address(collection));
        return tokenId;
    }

    /// @notice Wrapped method for Mint & List one item (NFT) from a collection
    /// @param collectionId the Id of the collection to mint the NFTs
    /// @param metadataURI the IPFS hash of the NFT metadata
    /// @param price price to be listed in the market in MATICS in basis points (*100)
    /// @param authorFee author fee percentage for the NFT in basis points (*100)
    /// @return identifier of the item in the collectionId minted and listed
    function mintAndListItem(
        uint256 collectionId,
        string memory metadataURI, 
        uint256 price,
        uint96 authorFee,
        uint256 uuid) public onlyWhitelist collectionExist(collectionId) nonReentrant returns (uint256)
    {
        uint256 tokenId = mint(collectionId, metadataURI, authorFee, uuid);
        listItem(collectionId, tokenId, price);
        return tokenId;
    }

    /// @notice Change the price for the argument tokenId in the Marketplace (if exists)
    /// @param collectionId the token's collectionId
    /// @param tokenId the Id of then token in the collection
    /// @param newPrice the new price for the tokenId in the Marketplace
    /// @param newURI the new uri for the marketplace
    /// @param authorFee the new author fee for the token
    function updateNFT(
        uint256 collectionId,
        uint256 tokenId, 
        uint256 newPrice,
        string memory newURI,
        uint96 authorFee) 
        public onlyWhitelist collectionExist(collectionId) isOwner(collectionId, tokenId) nonReentrant 
    {
        if (_marketItems[collectionId][tokenId].status != NFTStatus.LISTED) {
            revert ItemNotForSale(tokenId);
        }

        MarketItem storage nft = _marketItems[collectionId][tokenId];
        nft.price = newPrice;
        TefNFT collection = _collections[collectionId];
        collection.setTokenRoyalty(tokenId, authorFee);
        collection.revealNFT(tokenId, newURI);
        
        emit NFTUpdated(tokenId, msg.sender, nft.price, address(nft.collection), newURI);
    }

    /// @notice Hides/show from Market listings for the selected token
    /// @dev Internally, market as NFTStatus.DELISTED or NFTStatus.LISTED
    /// @param collectionId the token's collectionId  to list/delist from Market
    /// @param tokenId the Id of then token in the collection to list/delist from Market
    /// @param listing true if the token must be listed, false if the token must be delisted
    function changeListItem(
        uint256 collectionId,
        uint256 tokenId, 
        bool listing) 
        public onlyWhitelist isOwner(collectionId, tokenId) nonReentrant
    {
        if (_marketItems[collectionId][tokenId].status != NFTStatus.LISTED && _marketItems[collectionId][tokenId].status != NFTStatus.DELISTED) {
            revert ItemNotForSale(tokenId);
        }

        MarketItem storage nft = _marketItems[collectionId][tokenId];
        nft.status = listing ? NFTStatus.LISTED : NFTStatus.DELISTED;

        if (listing) {
            emit NFTListed(tokenId, msg.sender, nft.price, address(nft.collection));
        } else {
            emit NFTDelisted(tokenId, nft.owner, address(nft.collection));
        }
    }

    /// @notice Remove from Market listings the selected token item and revert the NFT to the owner
    /// @dev Internally, removed entry from _marketItems
    /// @param collectionId the token's collectionId to remove from Market
    /// @param tokenId the collection tokenId to remove from Market
    function removeListItem(
        uint256 collectionId,
        uint256 tokenId)
        public onlyWhitelist isOwner(collectionId, tokenId) nonReentrant
    {
        if (_marketItems[collectionId][tokenId].status != NFTStatus.LISTED && _marketItems[collectionId][tokenId].status != NFTStatus.DELISTED) {
            revert ItemNotForSale(tokenId);
        }

        // Remove from market and revert the NFT to the owner
        MarketItem memory nft = _marketItems[collectionId][tokenId];
        delete _marketItems[collectionId][tokenId];
        IERC721(nft.collection).transferFrom(address(this), nft.owner, tokenId);
        _itemCounter.decrement();
        
        emit NFTRemoved(address(nft.collection), tokenId, nft.owner);
    }

    // Public methods

    /// @notice Buy a listed Item in the Marketplace.
    /// @dev This is a public method, could be called by everyone.
    ///      The items must be on sale, and the payable value must be fill the
    ///      item price, the market fees and the author fees
    /// @param collectionId the Id of the collection for the token to buy
    /// @param tokenId the Id of the token in the collection to buy
    function buyMarketItem(uint256 collectionId, uint256 tokenId) public payable nonReentrant {
        /// Legal require: creators can't buy on the Market
        if (_whitelistedAddresses[msg.sender]) {
            revert NotApprovedForMarketplace();
        }
        if (_marketItems[collectionId][tokenId].tokenId == 0 || _marketItems[collectionId][tokenId].status != NFTStatus.LISTED) {
            revert ItemNotForSale(tokenId);
        }
        MarketItem storage item = _marketItems[collectionId][tokenId];
        TefNFT collection = item.collection;
        if (msg.value < item.price) {
            revert PriceNotMet(tokenId, item.price);
        }

        // First update item in Market for protect from reentrancy attacks
        address payable buyer = payable(msg.sender);
        item.buyer = buyer;
        item.status = NFTStatus.SOLD;

        // Pay fees to author
        (address _royaltiesAddr, uint256 _royaltiesNFT) = collection.royaltyInfo(item.tokenId, item.price);
        payable(_royaltiesAddr).transfer(_royaltiesNFT);
        uint256 actualMoney = item.price - _royaltiesNFT;

        // Pay fees to Market
        uint256 mktFee = item.price * _listingFees / FACTOR_FEES;
        _payableAddress.transfer(mktFee);
        actualMoney -= mktFee;

        // Pay to seller the difference
        payable(item.owner).transfer(actualMoney);

        // Send NFT to buyer
		collection.transferFrom(address(this), buyer, tokenId);

        _itemSoldCounter.increment();

        emit NFTSold(item.tokenId, item.owner, buyer, msg.value, address(collection));
    }

    /// Query Functions

    /// Enum operations for fetching methods
    enum FetchOperator {
        LISTED,
        PURCHASED,
        CREATED,
        SOLD
    }

    /// @notice Returns list of all listed items in the Marketplace (only LISTED, not SOLD)
    /// @dev This is a public method, could be called by everyone
    /// @return the MarketItem list of listed items right now
    function fetchListedItems() public view returns (MarketItem[] memory) {
        return fetchHelper(FetchOperator.LISTED);
    }

    /// @notice Returns list of all purchased items in the Marketplace (SOLD items, and purchased by me)
    /// @dev This is a public method, could be called by everyone
    /// @return the MarketItem list of purchased items by me
    function fetchMyPurchasedItems() public view returns (MarketItem[] memory) {
        return fetchHelper(FetchOperator.PURCHASED);
    }
   
    /// @notice Returns list of all created items in the Marketplace by the sender
    /// @dev This is a public method, could be called by everyone
    /// @return the MarketItem list of created items by me
    function fetchMyCreatedItems() public view returns (MarketItem[] memory) {
        return fetchHelper(FetchOperator.CREATED);
    }

    /// @notice Returns list of all sold items in the Marketplace (SOLD items, and purchased by others)
    /// @dev This is a public method, could be called by everyone
    /// @return the MarketItem list of sold items by me
    function fetchMySoldItems() public view returns (MarketItem[] memory) {
        return fetchHelper(FetchOperator.SOLD);
    }

    /// @notice Returns all the collections address created in the Marketplace
    /// @dev This is a public method, could be called by everyone
    /// @return the list with all the collection's address already created in the Marketplace
    function fetchAllCollections() public view returns (address[] memory) {
        uint256 total = _collectionsCounter.current();
        address[] memory collections = new address[](total);
        uint256 index = 0;
        for (uint256 i = 1; i <= total; i++) {
            collections[index] = address(_collections[i]);
            index++;
        }
        return collections;
    }

    /// @notice Helper method for creating the filtering array to response all the fetchXXX methods
    /// @param operator One of the FetchOperator values (LISTED, PURCHASED, CREATED, SOLD, ...)
    /// @return the MarketItem array filtered with the operator argument
    function fetchHelper(FetchOperator operator) private view returns (MarketItem[] memory) {
        uint256 _total = _itemCounter.current();
        uint256 _totalCollections = _collectionsCounter.current();
        uint256 itemCount = 0;
        
        for (uint256 i = 1; i <= _totalCollections; i++) {
            for (uint256 j = 1; j <= _total; j++) {
                if (_marketItems[i][j].tokenId > 0) {
                    if (isCondition(_marketItems[i][j], operator)) {
                        itemCount++;
                    }
                } else {
                    break;
                }
            }
        }

        uint256 index = 0;
        MarketItem[] memory items = new MarketItem[](itemCount);
        for (uint256 i = 1; i <= _totalCollections; i++) {
            for (uint256 j = 1; j <= _total; j++) {
                if (_marketItems[i][j].owner > address(0)) {
                    if (isCondition(_marketItems[i][j], operator)) {
                        items[index] = _marketItems[i][j];
                        index++;
                    }
                } else {
                    break;
                }
            }
        }
        return items;
    }
    
    /// @notice Helper method for creating the filtering array to response all the fetchXXX methods
    /// @param item The Market item to check the operation if compliance
    /// @param operator The operation (based on FetchOperator) to check
    /// @return true if the condicion is checked in the item, false in other case
    function isCondition(MarketItem memory item, FetchOperator operator) private view returns (bool) {
        if (operator == FetchOperator.CREATED) {
            return (item.owner == msg.sender) ? true : false;
        } else if (operator == FetchOperator.SOLD) {
            return (item.owner == msg.sender && item.status == NFTStatus.SOLD) ? true : false;
        } else if (operator == FetchOperator.PURCHASED) {
            return (item.buyer == msg.sender && item.status == NFTStatus.SOLD) ? true : false;
        } else if (operator == FetchOperator.LISTED) {
            return (item.buyer == address(0) && item.status == NFTStatus.LISTED) ? true : false;
        } else {
            return false;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./TefNFT.sol";

error NotApprovedForFactory();


/// @title contract TefNFTFactory is Ownable 
/// @notice TefNFTFactory
contract TefNFTFactory is Ownable {

    /// @notice The Marketplace address from where the NFTFactory is permitted to create collections
    address private _marketAddress;

    constructor() {   
    }

    /// @notice Set the market address to restrict de access, onlyOwner call this method
    /// @param marketAddress The address of the Marketplace
    function setMarketAddress(address marketAddress) public onlyOwner {
        if (marketAddress == address(0x0)) {
            revert AddressZeroOrNull();
        }

        _marketAddress = marketAddress;
    }

    /// @notice Factory pattern that return the new collection object
    /// @param name Name collections
    /// @param symbol Symbol collections
    /// @param initialRoyaltiesReceiver Address for receive royalties
    /// @param creator Address of creator
    function createCollectionSC(string memory name, string memory symbol, address initialRoyaltiesReceiver, address creator) public returns (TefNFT) {
        if (msg.sender != _marketAddress) {
            revert NotApprovedForFactory();
        }

        TefNFT tefnft = new TefNFT(name, symbol, initialRoyaltiesReceiver, msg.sender, creator);
        return tefnft;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
//import "hardhat/console.sol";

// Custom errors

/// @notice The metadata URI is empty
error MetadataURIEmpty();
/// @notice Two items can't be with the same medata URI hash
error DuplicatedMetadataURI();
/// @notice Only the Marketplace address can mint tokens from TefNFT
error OnlyMarketCanMint();
/// @notice Error thrown when some address are 0x0, and is required
error AddressZeroOrNull();


/// @title TefNFT
/// @notice TefNFT token, represent a Telefonica Marketplace collection
/// @dev Extends ERC-721 NFT contract and implements ERC-2981 (author fees)
contract TefNFT is Ownable, ERC721Enumerable, ERC721URIStorage, ERC721Royalty {

    // Keep a mapping of token ids and corresponding IPFS hashes
    mapping(string => uint8) private hashes;
    // Address of the royalties recipient
    address private _royaltiesReceiver;
    // Address of the Marketplace Smart Contract
    address private _marketAddress;

    // Constructor
    
    constructor(
        string memory name, 
        string memory symbol, 
        address initialRoyaltiesReceiver, 
        address market, 
        address owner) 
        ERC721(name, symbol) 
    {
        if (initialRoyaltiesReceiver == address(0x0) || market == address(0x0)) {
            revert AddressZeroOrNull();
        }

        _royaltiesReceiver = initialRoyaltiesReceiver;
        _marketAddress = market;
        setApprovalForAll(owner, true);
        transferOwnership(owner);
    }

    // Public methods

    /// @notice Mints tokens
    /// @param recipient the address to which the token will be transfered
    /// @param uri the IPFS hash of the token's resource
    /// @param authorFee the author fee in basic points.
    /// @return tokenId the id of the token
    function mint(address recipient, string memory uri, uint96 authorFee) external returns (uint256 tokenId) {
        if (msg.sender != _marketAddress && msg.sender != owner()) {
            revert OnlyMarketCanMint();
        }
        // The metadata uri can't be empty
        if (bytes(uri).length == 0) {
            revert MetadataURIEmpty();
        }
        // Metadata uri can't be duplicated
        if (hashes[uri] == 1) {
            revert DuplicatedMetadataURI();
        }

        hashes[uri] = 1;
        uint256 newItemId = totalSupply() + 1;
        _safeMint(recipient, newItemId);
        _setTokenURI(newItemId, uri);
        _setTokenRoyalty(newItemId, _royaltiesReceiver, authorFee);
        _approve(_marketAddress, newItemId);
        
        return newItemId;
    }

    /// @notice Reveal NFT: change the metadata URI of the token
    /// @param tokenId tokenId of the NFT to be revelead
    /// @param newURI the newUri for the NFT
    function revealNFT(uint256 tokenId, string memory newURI) external {
        require(_isApprovedOrOwner(msg.sender, tokenId));
        _setTokenURI(tokenId, newURI);
    }

    /// @notice Getter function for _royaltiesReceiver
    /// @return address of the royalties recipient
    function royaltiesReceiver() external view returns(address) {
        return _royaltiesReceiver;
    }

    /// @notice Changes the royalties' recipient address
    /// @param tokenId Id of the token to change the fees
    /// @param authorFee New author fee (x100) for the token
    function setTokenRoyalty(uint256 tokenId, uint96 authorFee) external {
        require(_isApprovedOrOwner(msg.sender, tokenId));
        _setTokenRoyalty(tokenId, _royaltiesReceiver, authorFee);
    }

    /// @notice Set new market address
    /// @param newMarket Address new market
    function setMarketAddress(address newMarket) external {
        if (msg.sender != _marketAddress) {
            revert OnlyMarketCanMint();
        }
        _marketAddress = newMarket;
    }

    /// @notice Changes the royalties' for token
    /// @param newRoyaltiesReceiver address of the new royalties recipient
    function setRoyaltiesReceiver(address newRoyaltiesReceiver) external onlyOwner {
        require(newRoyaltiesReceiver != _royaltiesReceiver);
        _royaltiesReceiver = newRoyaltiesReceiver;
    }

    // @notice Changes the royalties' recipient address
    /// @param tokenId address of the new royalties recipient
    function existsToken(uint256 tokenId) view external  returns (bool) {
       return _exists(tokenId);
    }

    // Private methods

    // Override methods

    /// @notice Returns a token's URI
    /// @dev See {IERC721Metadata-tokenURI}.
    /// @param tokenId the id of the token whose URI to return
    /// @return a string containing an URI pointing to the token's ressource
    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    /// @notice Informs callers that this contract supports ERC2981
    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable, ERC721Royalty) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId ||
        super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, amount);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage, ERC721Royalty) {
        super._burn(tokenId);
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/ERC721Royalty.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "../../common/ERC2981.sol";
import "../../../utils/introspection/ERC165.sol";

/**
 * @dev Extension of ERC721 with the ERC2981 NFT Royalty Standard, a standardized way to retrieve royalty payment
 * information.
 *
 * Royalty information can be specified globally for all token ids via {_setDefaultRoyalty}, and/or individually for
 * specific token ids via {_setTokenRoyalty}. The latter takes precedence over the first.
 *
 * IMPORTANT: ERC-2981 only specifies a way to signal royalty information and does not enforce its payment. See
 * https://eips.ethereum.org/EIPS/eip-2981#optional-royalty-payments[Rationale] in the EIP. Marketplaces are expected to
 * voluntarily pay royalties together with sales, but note that this standard is not yet widely supported.
 *
 * _Available since v4.5._
 */
abstract contract ERC721Royalty is ERC2981, ERC721 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {ERC721-_burn}. This override additionally clears the royalty information for the token.
     */
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);
        _resetTokenRoyalty(tokenId);
    }
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
// OpenZeppelin Contracts (last updated v4.6.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "./IERC721Enumerable.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/extensions/ERC721URIStorage.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";

/**
 * @dev ERC721 token with storage based token URI management.
 */
abstract contract ERC721URIStorage is ERC721 {
    using Strings for uint256;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return super.tokenURI(tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev See {ERC721-_burn}. This override additionally checks to see if a
     * token-specific URI was set for the token, and if so, it deletes the token URI from
     * the storage mapping.
     */
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/common/ERC2981.sol)

pragma solidity ^0.8.0;

import "../../interfaces/IERC2981.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of the NFT Royalty Standard, a standardized way to retrieve royalty payment information.
 *
 * Royalty information can be specified globally for all token ids via {_setDefaultRoyalty}, and/or individually for
 * specific token ids via {_setTokenRoyalty}. The latter takes precedence over the first.
 *
 * Royalty is specified as a fraction of sale price. {_feeDenominator} is overridable but defaults to 10000, meaning the
 * fee is specified in basis points by default.
 *
 * IMPORTANT: ERC-2981 only specifies a way to signal royalty information and does not enforce its payment. See
 * https://eips.ethereum.org/EIPS/eip-2981#optional-royalty-payments[Rationale] in the EIP. Marketplaces are expected to
 * voluntarily pay royalties together with sales, but note that this standard is not yet widely supported.
 *
 * _Available since v4.5._
 */
abstract contract ERC2981 is IERC2981, ERC165 {
    struct RoyaltyInfo {
        address receiver;
        uint96 royaltyFraction;
    }

    RoyaltyInfo private _defaultRoyaltyInfo;
    mapping(uint256 => RoyaltyInfo) private _tokenRoyaltyInfo;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC165) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @inheritdoc IERC2981
     */
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) public view virtual override returns (address, uint256) {
        RoyaltyInfo memory royalty = _tokenRoyaltyInfo[_tokenId];

        if (royalty.receiver == address(0)) {
            royalty = _defaultRoyaltyInfo;
        }

        uint256 royaltyAmount = (_salePrice * royalty.royaltyFraction) / _feeDenominator();

        return (royalty.receiver, royaltyAmount);
    }

    /**
     * @dev The denominator with which to interpret the fee set in {_setTokenRoyalty} and {_setDefaultRoyalty} as a
     * fraction of the sale price. Defaults to 10000 so fees are expressed in basis points, but may be customized by an
     * override.
     */
    function _feeDenominator() internal pure virtual returns (uint96) {
        return 10000;
    }

    /**
     * @dev Sets the royalty information that all ids in this contract will default to.
     *
     * Requirements:
     *
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function _setDefaultRoyalty(address receiver, uint96 feeNumerator) internal virtual {
        require(feeNumerator <= _feeDenominator(), "ERC2981: royalty fee will exceed salePrice");
        require(receiver != address(0), "ERC2981: invalid receiver");

        _defaultRoyaltyInfo = RoyaltyInfo(receiver, feeNumerator);
    }

    /**
     * @dev Removes default royalty information.
     */
    function _deleteDefaultRoyalty() internal virtual {
        delete _defaultRoyaltyInfo;
    }

    /**
     * @dev Sets the royalty information for a specific token id, overriding the global default.
     *
     * Requirements:
     *
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function _setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) internal virtual {
        require(feeNumerator <= _feeDenominator(), "ERC2981: royalty fee will exceed salePrice");
        require(receiver != address(0), "ERC2981: Invalid parameters");

        _tokenRoyaltyInfo[tokenId] = RoyaltyInfo(receiver, feeNumerator);
    }

    /**
     * @dev Resets royalty information for the token id back to the global default.
     */
    function _resetTokenRoyalty(uint256 tokenId) internal virtual {
        delete _tokenRoyaltyInfo[tokenId];
    }
}