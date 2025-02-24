/*
 *  Oblivion :: NFT Market Contract
 *
 *  This is the primary contract for the Oblivion NFT market and handles all listings and collections.
 *
 *  SPDX-License-Identifier: MIT
 */

pragma solidity ^0.8.4;

import "../includes/access/Ownable.sol";
import "../includes/libraries/Percentages.sol";
import "../includes/utils/ReentrancyGuard.sol";
import "./NftMarketInterfaces.sol";
import "../includes/interfaces/IPriceConsumerV3.sol";

contract NftMarketV2NoZmbe is Ownable, ReentrancyGuard {
    using Percentages for uint;

    enum PaymentMethod { BNB, BEP20 }           // Payment methods that can be used
    enum SaleType { DIRECT, OFFER, BOTH }       // Types of sales that are supported
    enum SaleState { OPEN, CLOSED }             // States that sales can be in

    // This struct holds the details of an offer on a listing
    struct Offer {
        address offeror;                // Address of the user making the offer
        uint amount;                    // The amount being offered
        uint discount;                  // The discount that should be applied to the tax
        bool claimed;                   // Flag for if this offer has been claimed
        uint createBlock;               // The block the offer was made
        uint endBlock;                  // The block the offer was accepted/cancelled
    }

    // This struct holds the details of a listed NFT
    struct Listing {
        address owner;                  // The address of the person who owns the listing
        address paymentToken;           // The address of the base payment token for the listing
        address nft;                    // The address of the NFT being listed
        uint targetPrice;               // The buy out price
        uint minimumPrice;              // The minimum price that can be offered
        uint tokenId;                   // The ID of the NFT being listed
        uint saleEnd;                   // The last timestamp that an offer can be made or the listing can be purchased
        uint graceEnd;                  // The timestamp where the grace period ends afterwhich an auction that has a bid cannot be cancelled
        uint createBlock;               // The block that the listing was created
        uint closedBlock;               // The block that the listing closed
        PaymentMethod paymentMethod;    // The payment method for this listing
        SaleType saleType;              // The type of listing this is
        SaleState saleState;            // The state the listing is in
    }

    // This struct is used to store information about offers made by each user for easier front end referencing
    struct OfferInfo {
        uint listingId;                 // The ID of the listing the offer is against
        uint offerId;                   // The ID of the offer within the listing's offer list
        address paymentToken;           // The payment token the offer was made in
    }

    // This struct is used to store information about the discount that gets applied on the taxes
    struct DiscountInfo {
        uint percentage;                // The percentage that is applied for this discount
        bool enabled;                   // Flag tracking if the discount is enabled
    }

    // This struct is used to store information about BEP20 tokens that have been enabled to be used as payment methods
    struct Bep20Info {
        uint marketTax;                 // The tax rate for this BEP20 token
        bool enabled;                   // Flag tracking if this token is enabled as a payment method
    }

    address payable                                 public  treasury;               // The treasury address
    uint                                            public  marketTaxBnb = 100;     // Base tax rate for open market sales
    uint                                            public  minTax = 25;            // Minimum tax of any sale
    uint                                            public  maxTax = 250;           // Maximum marketTax value
    uint                                            public  gracePeriod = 3600;     // Time after an auction listing is made that it can be cancelled with bids on it    
    uint                                            public  listingFee;             // The listing fee in USD
    ICollection                                     public  collection;             // The collection manager
    IPriceConsumerV3                                public  priceConsumer;          // The price consumer
    Listing[]                                       public  listings;               // The NFT listings

    mapping(uint => mapping(address => Offer[]))    public  offers;                 // Mapping to store all the offers based on the listing ID and the payment token being offered
    mapping(address => OfferInfo[])                 public  userOffers;             // Mapping to store all the offers made by a user
    mapping(address => uint[])                      public  userListings;           // Mapping to store references to a user's listings
    mapping(address => DiscountInfo)                public  discountInfo;           // Mapping to store details on each discount
    mapping(address => Bep20Info)                   public  bep20Info;              // Mapping to store details on BEP20 tokens used as payments
    mapping(address => uint)                        public  trades;                 // Mapping to store count of users trades
    mapping(address => bool)                        public  feeWhitelist;           // Mapping to store addresses that are exempt from listing fee

    /*
     *  Constructor for initializing the base contract values on deployment
     */

    constructor(address _treasury, address _collectionManager, address _priceConsumer, uint _listingFee) {
        treasury = payable(_treasury);
        collection = ICollection(_collectionManager);
        priceConsumer = IPriceConsumerV3(_priceConsumer);
        listingFee = _listingFee;
    }
    
    /*
     *  Events used to send notifications when certain things occur within the contract for off chain tracking
     */

    event CreateListing(uint indexed id, address indexed owner, address indexed nft, uint tokenId, uint targetPrice, SaleType _saleType, uint _targetPrice, uint _saleEnd);
    event CancelListing(uint indexed id, address indexed owner);
    event TransferNft(uint id, address recipient);    
    event TransferTax(uint indexed listingId, address indexed paymentToken, uint amount, address treasury);
    event TransferPayment(uint indexed listingId, address indexed paymentToken, uint amount, address indexed recipient);
    event CreateOffer(uint indexed listingId, uint indexed offerId, address indexed offeror, uint amount, uint discount);
    event WithdrawOffer(uint indexed listingId, uint offerId, address indexed paymentToken, address indexed offeror);
    event AcceptOffer(uint indexed listingId, uint offerId, address indexed paymentToken, address indexed offeror, uint amount);
    event DirectBuy(uint indexed listingId, address indexed buyer, address indexed paymentToken, uint amount);
    event UpdateDiscount(address discountAddress, uint percentage, bool enabled);
    event UpdateBEP20Info(address token, uint tax, bool enabled);
    event UpdateMarketTax(uint rebate);
    event UpdateFeeWhitelist(address wallet, bool whitelisted);
    event UpdateListingFee(uint fee);

    /*
     *  Contract data read functions
     */

    function totalListings() public view returns (uint) { return listings.length; }
    function totalOffers(uint _listing, address _paymentToken) public view returns (uint) { return offers[_listing][_paymentToken].length; }
    function totalUserListings(address _user) public view returns (uint) { return userListings[_user].length; }
    function totalUserOffers(address _user) public view returns (uint) { return userOffers[_user].length; }    
    function feeInBnb() public view returns (uint) { return priceConsumer.usdToBnb(listingFee); }
    
    function calculateDiscount(address user, address[] memory discountAddresses) public view returns (uint) {
        uint _discount = 0;
        for (uint x = 0; x < discountAddresses.length; x++) 
            if (discountInfo[discountAddresses[x]].enabled && IDiscount(discountAddresses[x]).isApplicable(user)) 
                _discount += discountInfo[discountAddresses[x]].percentage;
        return _discount;
    }

    function isAuction(uint _listing) public view returns(bool) {
        return (listings[_listing].saleType == SaleType.OFFER || listings[_listing].saleType == SaleType.BOTH) && listings[_listing].saleEnd != 0;
    }

    function minimumOfferAmount(uint _listing, address _paymentToken) public view returns (uint) {
        Offer[] storage _offers = offers[_listing][_paymentToken];
        if (_offers.length == 0) return 0;
        for(uint i = _offers.length; i > 0; i--)
            if(!_offers[i - 1].claimed) return _offers[i - 1].amount;
        return 0;
    }

    /*
     *  Marketplace management functions (onlyOwner)
     */

    // Function for setting the treasury address
    function setTreasury(address _treasury) public onlyOwner() { treasury = payable(_treasury); }

    // Function for setting the price consumer
    function setPriceConsumer(address _priceConsumer) public onlyOwner() { priceConsumer = IPriceConsumerV3(_priceConsumer); }

    // Function for setting the listing fee
    function setListingFee(uint _fee) public onlyOwner() { 
        listingFee = _fee; 
        emit UpdateListingFee(_fee);
    }

    // Function to change the fee whitelist state for an address
    function setFeeWhitelist(address _wallet, bool _whitelisted) public onlyOwner() { 
        feeWhitelist[_wallet] = _whitelisted; 
        emit UpdateFeeWhitelist(_wallet, _whitelisted);
    }

    // Function for setting the BNB tax rate
    function setMarketTaxBnb(uint _marketTaxBnb) public onlyOwner() {
        require(_marketTaxBnb <= maxTax, 'tax must be <= maxTax.');
        marketTaxBnb = _marketTaxBnb;
        emit UpdateMarketTax(_marketTaxBnb);
    }

    // Function for setting the discount details for a given discount manager contract address
    function updateDiscount(address _addr, uint _percentage, bool _enabled) public onlyOwner() {
        DiscountInfo storage info = discountInfo[_addr];
        info.percentage = _percentage;
        info.enabled = _enabled;
        emit UpdateDiscount(_addr, _percentage, _enabled);
    }

    // Function for setting the details of a BEP20 token that is used as a payment method
    function setBep20(address _addr, uint _marketTax, bool _enabled) public onlyOwner() {
        require(_marketTax <= maxTax, 'must be <= maxTax');
        Bep20Info storage info = bep20Info[_addr];
        info.marketTax = _marketTax;
        info.enabled = _enabled;
        emit UpdateBEP20Info(_addr, _marketTax, _enabled);
    }

    /*
     *  Buyer functions
     */

    // Function to buy a listing with BNB
    function directBuyBnb(uint _listing, address[] memory _discountAddresses) public payable nonReentrant() {
        _validListing(_listing);
        Listing storage listing = listings[_listing];
        require(listing.saleType == SaleType.DIRECT || listing.saleType == SaleType.BOTH, 'incorrect sale type');
        require(listing.paymentMethod == PaymentMethod.BNB, 'incorrect sale type');
        require(listing.targetPrice == msg.value, 'incorrect amount');
        _payBnb(listing.targetPrice, _listing, calculateDiscount(msg.sender, _discountAddresses));
        _sendNft(_listing, msg.sender);
        emit DirectBuy(_listing, msg.sender, address(0), listing.targetPrice);
    }

    // Function to buy a listing with a BEP20 token
    function directBuyBep20(uint _listing, address[] memory _discountAddresses) public nonReentrant() {
        _validListing(_listing);
        Listing storage listing = listings[_listing];
        require(listing.saleType == SaleType.DIRECT || listing.saleType == SaleType.BOTH, 'incorrect sale type');
        require(listing.paymentMethod == PaymentMethod.BEP20, 'incorrect sale type');
        _payBep20(listing.targetPrice, msg.sender, _listing, calculateDiscount(msg.sender, _discountAddresses));
        _sendNft(_listing, msg.sender);
        emit DirectBuy(_listing, msg.sender, listing.paymentToken, listing.targetPrice);
    }

    // Function to create an offer on a listing
    function createOffer(uint _listing, uint _amount, address _paymentToken, address[] memory _discountAddresses) public payable {
        _validListing(_listing);
        Listing storage listing = listings[_listing];
        require(listing.saleType == SaleType.OFFER || listing.saleType == SaleType.BOTH, 'incorrect sale type');
        require(listing.owner != msg.sender, 'cannot offer on your own listing');
        Offer[] storage _offers = offers[_listing][_paymentToken];
        require(_amount > minimumOfferAmount(_listing, _paymentToken), 'must be > last offer');

        if(listing.saleType == SaleType.BOTH && listing.paymentToken == _paymentToken)
            require(_amount < listing.targetPrice, 'must be < direct sale price');

        if(listing.saleEnd != 0) {
            require(listing.paymentToken == _paymentToken, 'requires using the sellers chosen token');
            require(_amount >= listing.minimumPrice, 'offer is below minimum price');
        }

        uint _discount = calculateDiscount(msg.sender, _discountAddresses);
        _offers.push(Offer({offeror: msg.sender, amount: _amount, discount: _discount, claimed: false, createBlock: block.number, endBlock: 0}));

        if(_paymentToken != address(0)) {
            require(msg.value == 0, 'offer does not require BNB');
            require(bep20Info[_paymentToken].enabled, 'token not enabled');

            uint initialBalance = IToken(_paymentToken).balanceOf(address(this));
            IToken(_paymentToken).transferFrom(msg.sender, address(this), _amount);
            require(IToken(_paymentToken).balanceOf(address(this)) == initialBalance + _amount, 'token not enabled');
        } else {
            require(msg.value == _amount, 'incorrect amount');
            require(_amount >= 10000, 'incorrect amount');
        }

        userOffers[msg.sender].push(OfferInfo({listingId: _listing, offerId: _offers.length - 1, paymentToken: _paymentToken}));
        emit CreateOffer(_listing, _offers.length - 1, msg.sender, _amount, _discount);
    }

    // Function to withdraw an offer
    function withdrawOffer(uint _listing, uint _offer, address _paymentToken) public nonReentrant() {
        require(_listing < totalListings(), 'invalid listing ID');
        require(_paymentToken == address(0) || bep20Info[_paymentToken].enabled, 'token not enabled');
        require(_offer < totalOffers(_listing, _paymentToken), 'does not exist');
        Offer storage offer = offers[_listing][_paymentToken][_offer];
        require(!offer.claimed, 'already claimed');
        require(msg.sender == offer.offeror, 'must be owner');

        if(_offer == totalOffers(_listing, _paymentToken) - 1)
            require(!isAuction(_listing) || listings[_listing].saleState == SaleState.CLOSED, 'highest bid is final');

        if(_paymentToken == address(0)) _safeTransfer(offer.offeror, offer.amount);
        else IToken(_paymentToken).transfer(offer.offeror, offer.amount);

        offer.claimed = true;
        offer.endBlock = block.number;
        emit WithdrawOffer(_listing, _offer, _paymentToken, msg.sender);
    }

    // Function for a buyer to claim an auction after it has ended
    function claimAuction(uint _listing, uint _offer, address _paymentToken) public nonReentrant() {
        require(_listing < totalListings(), 'invalid listing ID');
        require(isAuction(_listing), 'incorrect sale type');
        Listing storage listing = listings[_listing];
        require(listing.saleState == SaleState.OPEN, 'not open');
        require(block.timestamp > listing.saleEnd, 'has not ended');
        require(_offer < totalOffers(_listing, _paymentToken), 'does not exist');
        Offer storage offer = offers[_listing][_paymentToken][_offer];

        require(_offer == totalOffers(_listing, _paymentToken) - 1, 'must be the winning bid');

        if(_paymentToken == address(0)) _payBnb(offer.amount, _listing, offer.discount);
        else _payBep20(offer.amount, address(this), _listing, offer.discount);

        offer.claimed = true;
        offer.endBlock = block.number;
        _sendNft(_listing, offer.offeror);
        emit AcceptOffer(_listing, _offer, _paymentToken, offer.offeror, offer.amount);
    }

    /*
     *  Seller functions
     */

    // Function to list an NFT for sale
    function listNft(address _nft, uint _tokenId, PaymentMethod _paymentMethod, address _paymentToken, SaleType _saleType, uint _targetPrice, uint _minimumPrice, uint _saleEnd) public payable nonReentrant() {
        INft(_nft).transferFrom(msg.sender, address(this), _tokenId);
        require(INft(_nft).ownerOf(_tokenId) == address(this), 'transfer failed');

        if(_paymentMethod == PaymentMethod.BNB) {
            require(_paymentToken == address(0), 'must be zero address for BNB listings');
            require(_targetPrice >= 10000 || _targetPrice == 0, 'incorrect amount');
            require(_minimumPrice >= 10000 || _minimumPrice == 0, 'incorrect amount');
        }
        else require(bep20Info[_paymentToken].enabled, 'token not enabled');

        listings.push(Listing({
            owner: msg.sender,
            paymentMethod: _paymentMethod,
            paymentToken: _paymentToken,
            saleType: _saleType,
            saleState: SaleState.OPEN,
            targetPrice: _targetPrice,
            minimumPrice: _minimumPrice,
            nft: _nft,
            tokenId: _tokenId,
            saleEnd: _saleEnd,
            graceEnd: block.timestamp + gracePeriod,
            createBlock: block.number,
            closedBlock: 0
        }));

        uint256 id = listings.length - 1;

        if (!feeWhitelist[msg.sender]) {
            require(msg.value == feeInBnb(), 'insufficient BNB for fee');
            _safeTransfer(treasury, msg.value);
        }

        userListings[msg.sender].push(id);
        emit CreateListing(id, msg.sender, _nft, _tokenId, _targetPrice, _saleType, _targetPrice, _saleEnd);
    }

    // Function to accept an offer on a listing
    function acceptOffer(uint _listing, uint _offer, address _paymentToken) public nonReentrant() {
        require(_listing < totalListings(), 'invalid listing ID');
        Listing storage listing = listings[_listing];
        require(listing.owner == msg.sender, 'must be owner');
        require(listing.saleState == SaleState.OPEN, 'not open');
        require(_paymentToken == address(0) || bep20Info[_paymentToken].enabled, 'token not enabled');
        require(_offer < totalOffers(_listing, _paymentToken), 'does not exist');
        Offer storage offer = offers[_listing][_paymentToken][_offer];

        if(isAuction(_listing)) {
            require(block.timestamp > listing.saleEnd, 'has not ended');
            require(_offer == totalOffers(_listing, _paymentToken) - 1, 'must accept the final bid');
        }

        if(_paymentToken == address(0)) _payBnb(offer.amount, _listing, offer.discount);
        else {
            listing.paymentToken = _paymentToken;
            _payBep20(offer.amount, address(this), _listing, offer.discount);
        }

        offer.claimed = true;
        offer.endBlock = block.number;
        _sendNft(_listing, offer.offeror);
        emit AcceptOffer(_listing, _offer, _paymentToken, offer.offeror, offer.amount);
    }

    // Function to cancel a listing
    function cancel(uint _listing) public {
        require(_listing < totalListings(), 'invalid listing ID');
        Listing storage listing = listings[_listing];
        require(listing.saleState == SaleState.OPEN, 'not open');
        require(listing.owner == msg.sender, 'must be owner');

        if (isAuction(_listing) && block.timestamp > listing.graceEnd)
            require(offers[_listing][listing.paymentToken].length == 0, 'cannot cancel auction with bidders');

        INft nft = INft(listing.nft);
        nft.transferFrom(address(this), msg.sender, listings[_listing].tokenId);
        require(nft.ownerOf(listing.tokenId) == msg.sender, 'transfer failed');
        listing.saleState = SaleState.CLOSED;
        listing.closedBlock = block.number;
        emit CancelListing(_listing, msg.sender);
    }

    /*
     *  Private helpers
    */

    // Function to complete a payment in a BEP20 token
    function _payBep20(uint _amount, address _tokenLocation, uint _listing, uint _discount) private {
        Listing storage listing = listings[_listing];
        Bep20Info storage paymentInfo = bep20Info[listing.paymentToken];

        if (_tokenLocation == address(this)) IToken(listing.paymentToken).approve(address(this), _amount);

        // cap _discount to prevent subtraction underflow error
        if(_discount > paymentInfo.marketTax) _discount = paymentInfo.marketTax;

        uint taxBP = paymentInfo.marketTax - _discount;
        if (taxBP < minTax) taxBP = minTax;

        uint tax = _amount.calcPortionFromBasisPoints(taxBP);
        uint remaining = _amount - tax;

        NftCollectionInfo memory _nftCollectionInfo = collection.nftInfo(listing.nft);
        if(_nftCollectionInfo.inCollection) {
            Collection memory info = collection.getCollection(_nftCollectionInfo.collectionId);
            if (info.royalties > 0) {
                uint royalties = _amount.calcPortionFromBasisPoints(info.royalties);
                IToken(listing.paymentToken).transferFrom(_tokenLocation, info.treasury, royalties);
                remaining -= royalties;
            }
        }

        IToken(listing.paymentToken).transferFrom(_tokenLocation, treasury, tax);
        emit TransferTax(_listing, listing.paymentToken, tax, treasury);

        IToken(listing.paymentToken).transferFrom(_tokenLocation, listing.owner, remaining);
        emit TransferPayment(_listing, listing.paymentToken, remaining, listing.owner);
    }

    // Function to complete a payment in a BNB
    function _payBnb(uint _amount, uint _listing, uint _discount) private {
        uint taxBP = marketTaxBnb - _discount;

        require(taxBP >= minTax, 'taxBP < minTax');

        uint tax = _amount.calcPortionFromBasisPoints(taxBP);
        uint remaining = _amount - tax;

        require(_amount.calcBasisPoints(tax) >= minTax || _amount == 0, 'minTax: Discount Error occurred');
        require(_amount.calcBasisPoints(tax) <= maxTax, 'maxTax: Discount Error occurred');

        NftCollectionInfo memory _nftCollectionInfo = collection.nftInfo(listings[_listing].nft);
        if(_nftCollectionInfo.inCollection) {
            Collection memory info = collection.getCollection(_nftCollectionInfo.collectionId);
            if (info.royalties > 0) {
                uint royalties = _amount.calcPortionFromBasisPoints(info.royalties);
                _safeTransfer(info.treasury, royalties);
                remaining -= royalties;
            }            
        }

        _safeTransfer(treasury, tax);
        emit TransferTax(_listing, address(0), tax, treasury);

        _safeTransfer(listings[_listing].owner, remaining);
        emit TransferPayment(_listing, address(0), remaining, listings[_listing].owner);
    }

    // Function to send the NFT at the end of a sale
    function _sendNft(uint _listing, address _recipient) private {
        INft nft = INft(listings[_listing].nft);
        nft.transferFrom(address(this), _recipient, listings[_listing].tokenId);
        require(nft.ownerOf(listings[_listing].tokenId) == _recipient, 'transfer failed');
        Listing storage listing = listings[_listing];
        listing.saleState = SaleState.CLOSED;
        listing.closedBlock = block.number;
        trades[listing.owner]++;
        trades[_recipient]++;
        emit TransferNft(_listing, _recipient);
    }

    // Function to safely transfer BNB to an address
    function _safeTransfer(address _recipient, uint _amount) private {
        (bool _success,) = _recipient.call{value : _amount}("");
        require(_success, "transfer failed");
    }

    // Function for ensuring a listing is valid
    function _validListing(uint _listing) private view {
        require(_listing < totalListings(), 'invalid listing ID');
        Listing storage listing = listings[_listing];
        require(listing.saleState == SaleState.OPEN, 'not open');
        require(listing.saleEnd == 0 || block.timestamp <= listing.saleEnd, 'sale ended');
    }
}

/*
 *  Oblivion :: NFT Market Objects
 *
 *  This file contains objects that are used between multiple market contracts.
 *
 *  SPDX-License-Identifier: MIT
 */

pragma solidity ^0.8.4;

// This struct holds the details of a NFT collection
struct Collection {
    address[] nfts;                 // Array of addressed for the NFTs that belong to this collection
    address owner;                  // The address of the owner of the collection
    address treasury;               // The address that the royalty payments should be sent to
    uint royalties;                 // The percentage of royalties that should be collected
    uint createBlock;               // The block that the collection was created
}

// This struct is used to reference an NFT address to the collection it belongs to
struct NftCollectionInfo {
    uint collectionId;              // The ID of the collection this NFT belongs to
    uint index;                     // The index of the collection array where this NFT is
    bool inCollection;              // Flag tracking if this NFT is part of a collection
}

/*
 *  Oblivion :: NFT Market Interfaces
 *
 *  This contract defines the interfaces that the NFT market contract uses to interface with other contracts.
 *  Some of these are abridged versions of standard interfaces in order to save contract size.
 *
 *  SPDX-License-Identifier: MIT
 */

pragma solidity ^0.8.4;

import "./NftMarketObjects.sol";

/*
 *  Interface for interacting with an ERC721 NFT
 */
interface INft {
    function transferFrom(address from, address to, uint256 tokenId) external;
    function ownerOf(uint256 tokenId) external view returns (address);
    function owner() external view returns (address);
}

/*
 *  Interface for interacting with an ERC1155 NFT
 */
interface INft1155 {
    function balanceOf(address account, uint256 id) external view returns (uint256);
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;
    function ownerOf(uint256 tokenId) external view returns (address);
    function owner() external view returns (address);
    function transferOwnership(address newOwner) external;
    function mint(address _to, uint256 _id, uint256 _amount, bytes memory _data) external;
}

/*
 *  Interface for interacting with a BEP20 token
 */
interface IToken {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

/*
 *  Interface for interacting with a PCS compatible DEX router
 */
interface IDexRouter {
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline) external payable returns (uint[] memory amounts);
    function WETH() external pure returns (address);
}

/*
 *  Interface for interacting with the rebates contract
 */
interface IRebates {
    function addUserRebate(address _user, uint _amount) external;
}

/*
 *  Interface for interacting with the discounts contract
 */
interface IDiscount {
    function isApplicable(address _user) external view returns (bool);
}

/*
 *  Interface for interacting with the collection contract
 */
interface ICollection {
    function nftInfo(address _nft) external view returns (NftCollectionInfo memory);
    function getCollection(uint _id) external view returns (Collection memory);    
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

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
     * by making the `nonReentrant` function external, and make it call a
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

pragma solidity ^0.8.4;

/*
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

    function _msgData() internal view virtual returns ( bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

library Percentages {
    // Get value of a percent of a number
    function calcPortionFromBasisPoints(uint _amount, uint _basisPoints) public pure returns(uint) {
        if(_basisPoints == 0 || _amount == 0) {
            return 0;
        } else {
            uint _portion = _amount * _basisPoints / 10000;
            return _portion;
        }
    }

    // Get basis points (percentage) of _portion relative to _amount
    function calcBasisPoints(uint _amount, uint  _portion) public pure returns(uint) {
        if(_portion == 0 || _amount == 0) {
            return 0;
        } else {
            uint _basisPoints = (_portion * 10000) / _amount;
            return _basisPoints;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IPriceConsumerV3 {
    function getLatestPrice() external view returns (uint);
    function unlockFeeInBnb(uint) external view returns (uint);
    function usdToBnb(uint) external view returns (uint);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

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
    constructor()  {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}