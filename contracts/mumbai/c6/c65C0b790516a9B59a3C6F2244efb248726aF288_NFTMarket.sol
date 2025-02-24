// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./NFTMarketReserveAuction.sol";
import "./NFTMarketDutchAuction.sol";
import "./NFTMarketFees.sol";
import "./NFTMarketOffer.sol";
import "./NFTMarketListing.sol";

/**
 * @title A market for NFTs.
 * @dev This top level file holds no data directly to ease future upgrades.
 *
 * Upgrading: upgrading and adding new parent contracts works as long as there are no
 * state variables in the main contract (this one). New parent contracts must be appended
 * to the END of the current inherited contracts.
 *
 */
contract NFTMarket is
    NFTMarketFees,
    NFTMarketReserveAuction,
    NFTMarketOffer,
    NFTMarketListing,
    NFTMarketDutchAuction
{
    /**
     * @notice Called once to configure the contract after the initial deployment.
     * @dev This farms the initialize call out to inherited contracts as needed.
     */

    function initialize(
        address admin,
        IERC20Upgradeable darToken,
        address primarySalesWallet,
        address secondarySalesWallet,
        uint8 listingLimit,
        uint minPercentIncrementInBasisPoints,
        uint secondaryMarketCreatorFeeInBasisPoints,
        IMoDApproveProxy _IMoDApproveProxy
    ) external initializer {
        AccessControlUpgradeable.__AccessControl_init();
        _setupRole(DEFAULT_ADMIN_ROLE, admin);

        NFTMarketReserveAuction._initializeNFTMarketReserveAuction();
        NFTMarketOffer._initializeNFTMarketOffer();
        NFTMarketListing._initializeNFTMarketListing();
        NFTMarketDutchAuction._initializeNFTMarketDutchAuction();
        NFTMarketFees._initializeNFTMarketFees(
            listingLimit,
            primarySalesWallet,
            secondarySalesWallet,
            secondaryMarketCreatorFeeInBasisPoints,
            _IMoDApproveProxy,
            darToken
        );
    }

    /**
     * @dev Returns the seller that put a given NFT into escrow. Covers Auctions, Listings and Dutch Auctions.
     */
    function getSellerFor(
        address nftContract,
        uint tokenId
    ) public view returns (address) {
        // Check if auction
        address seller = auctionIdToAuction[
            nftContractToTokenIdToAuctionId[nftContract][tokenId]
        ].seller;
        if (seller != address(0)) {
            return seller;
        }
        // Check if listing
        seller = listingIdToListing[
            nftContractToTokenIdToListingId[nftContract][tokenId]
        ].seller;
        if (seller != address(0)) {
            return seller;
        }
        // Check if dutch auction
        seller = dutchAuctionIdToDutchAuction[
            nftContractToTokenIdToDutchAuctionId[nftContract][tokenId]
        ].seller;
        if (seller != address(0)) {
            return seller;
        }
        return address(0);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./NFTMarketFees.sol";

/**
 * @notice Manages a reserve price auction for NFTs.
 */
abstract contract NFTMarketReserveAuction is NFTMarketFees {
    using AddressUpgradeable for address;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    mapping(address => mapping(uint => uint))
        public nftContractToTokenIdToAuctionId;
    mapping(uint => ReserveAuction) public auctionIdToAuction;

    uint private _minPercentIncrementInBasisPoints; // The minimum percent increment a bid must be from last bid

    /// @custom:oz-renamed-from _defaultDuration
    uint public _maxAuctionDuration; // If a duration is not supplied when creating an auction it will simply default to this duration

    /// @custom:oz-renamed-from _minDuration
    uint public _minAuctionDuration; // Minimum duration an auction can be held
    uint private _extensionDuration; // The duration which each bid extends the auction

    uint private nextAuctionId;
    struct ReserveAuction {
        address nftContract;
        uint tokenId;
        address seller;
        uint duration;
        uint extensionDuration;
        uint endTime;
        address bidder;
        uint amount;
    }

    // EVENTS -----------------

    event MinPercentIncrementUpdated(uint minPercentIncrementInBasisPoints);
    event ListingLimitUpdated(uint8 listingLimit);
    event MinAuctionDurationUpdated(uint minAuctionDuration);
    event MaxAuctionDurationUpdated(uint maxAuctionDuration);
    event ExtensionDurationUpdated(uint extensionDuration);

    event ReserveAuctionCreated(
        address indexed seller,
        address indexed nftContract,
        uint indexed tokenId,
        uint duration,
        uint extensionDuration,
        uint reservePrice,
        uint auctionId
    );
    event ReserveAuctionUpdated(uint indexed auctionId, uint reservePrice);
    event ReserveAuctionCanceled(uint indexed auctionId);
    event ReserveAuctionBidPlaced(
        uint indexed auctionId,
        address indexed bidder,
        uint amount,
        uint endTime,
        uint timestamp
    );
    event ReserveAuctionFinalized(
        uint indexed auctionId,
        address indexed seller,
        address indexed bidder,
        uint royaltyFee,
        uint creatorSecondaryMarketFee,
        uint ownerRew
    );

    // Reserve Auction -----------------

    /*
     * Seller puts an NFT on auction with a determined reserve price - a minimum bid - for a determined duration. Multiple
     * users can bid on the NFT until the duration is over, which is when the auction can be finalized.
     * */

    function _initializeNFTMarketReserveAuction() internal onlyInitializing {
        _maxAuctionDuration = 30 days;
    }

    modifier onlyValidMinPercentIncrement(
        uint minPercentIncrementInBasisPoints
    ) {
        require(
            minPercentIncrementInBasisPoints <= BASIS_POINTS,
            "Market: Min increment percent must be <= 100%"
        );
        _;
    }

    function _getNextAndIncrementAuctionId() internal returns (uint) {
        return nextAuctionId++;
    }

    /**
     * @notice Returns the current configuration for reserve auctions.
     */
    function getReserveAuctionConfig()
        public
        view
        returns (uint minPercentIncrementInBasisPoints, uint8 listingLimit)
    {
        minPercentIncrementInBasisPoints = _minPercentIncrementInBasisPoints;
        listingLimit = _listingLimit;
    }

    /**
     * @notice Updates a minimum percent increment for all auctions
     */
    function updateMinPercentIncrement(
        uint minPercentIncrementInBasisPoints
    )
        public
        onlyAdmin
        onlyValidMinPercentIncrement(minPercentIncrementInBasisPoints)
    {
        _minPercentIncrementInBasisPoints = minPercentIncrementInBasisPoints;

        emit MinPercentIncrementUpdated(minPercentIncrementInBasisPoints);
    }

    /**
     * @notice Updates a listing limit that is used in time of auctions creation in batch.
     */
    function updateListingLimit(uint8 listingLimit) public onlyAdmin {
        _listingLimit = listingLimit;

        emit ListingLimitUpdated(listingLimit);
    }

    /**
     * @notice Updates a listing limit that is used in time of auctions creation in batch.
     */
    function updateExtensionDuration(uint extensionDuration) public onlyAdmin {
        _extensionDuration = extensionDuration;

        emit ExtensionDurationUpdated(extensionDuration);
    }

    /**
     * @notice Updates minimum duration that a reserve auction can span.
     */
    function updateMinAuctionDuration(
        uint minAuctionDuration
    ) public onlyAdmin {
        require(
            minAuctionDuration >= 1 minutes,
            "Market: can not be less than 1 minute"
        );
        _minAuctionDuration = minAuctionDuration;

        emit MinAuctionDurationUpdated(minAuctionDuration);
    }

    /**
     * @notice Updates maximum duration that a reserve auction can span.
     */
    function updateMaxAuctionDuration(
        uint maxAuctionDuration
    ) public onlyAdmin {
        require(
            maxAuctionDuration <= 1000 days,
            "Market: must be less than 1000 days"
        );
        _maxAuctionDuration = maxAuctionDuration;

        emit MaxAuctionDurationUpdated(maxAuctionDuration);
    }

    /**
     * @dev Creates one reserve auction for the given NFT and token ID with custom duration.
     */
    function createReserveAuction(
        address nftContract,
        uint tokenId,
        uint reservePrice,
        uint duration
    ) public onlyAllowedContract(nftContract) {
        _createReserveAuction(nftContract, tokenId, reservePrice, duration);
    }

    function _createReserveAuction(
        address nftContract,
        uint tokenId,
        uint reservePrice,
        uint duration
    ) internal onlyValidPrice(reservePrice) {
        require(
            duration >= _minAuctionDuration,
            "Market: Too short auction duration"
        );
        require(
            duration <= _maxAuctionDuration,
            "Market: Too long auction duration"
        );

        uint auctionId = _getNextAndIncrementAuctionId();

        nftContractToTokenIdToAuctionId[nftContract][tokenId] = auctionId;
        auctionIdToAuction[auctionId] = ReserveAuction(
            nftContract,
            tokenId,
            msg.sender,
            duration,
            _extensionDuration,
            0,
            address(0),
            reservePrice
        );

        IERC721Upgradeable(nftContract).transferFrom(
            msg.sender,
            address(this),
            tokenId
        );

        emit ReserveAuctionCreated(
            msg.sender,
            nftContract,
            tokenId,
            duration,
            _extensionDuration,
            reservePrice,
            auctionId
        );
    }

    /**
     * @notice Creates an auctions for the given NFT contract and token IDs.
     * The NFTs are held in escrow until the auctions are finalized or canceled.
     * Uses a custom duration supplied by the user.
     */

    function createReserveAuctionBatch(
        address nftContract,
        uint[] calldata tokenIds,
        uint[] calldata reservePrices,
        uint duration
    ) public onlyAllowedContract(nftContract) {
        require(
            tokenIds.length == reservePrices.length,
            "Market: Token IDs and reserve prices length mismatch"
        );
        require(
            tokenIds.length <= _listingLimit,
            "Market: Too many tokens to list in reserve auctions per one transaction"
        );

        for (uint i = 0; i < tokenIds.length; i++) {
            _createReserveAuction(
                nftContract,
                tokenIds[i],
                reservePrices[i],
                duration
            );
        }
    }

    /**
     * @notice If an auction has been created but has not yet received bids, the configuration
     * such as the reservePrice may be changed by the seller.
     */
    function updateReserveAuction(
        uint auctionId,
        uint reservePrice
    ) public onlyValidPrice(reservePrice) {
        ReserveAuction storage auction = auctionIdToAuction[auctionId];

        require(auction.seller == msg.sender, "Market: Not your auction");
        require(auction.endTime == 0, "Market: Auction in progress");

        auction.amount = reservePrice;

        emit ReserveAuctionUpdated(auctionId, reservePrice);
    }

    function updateReserveAuctionBatch(
        uint[] calldata auctionIds,
        uint[] calldata reservePrices
    ) external {
        require(
            auctionIds.length <= _listingLimit,
            "Market: Too many auctions to update in one transaction"
        );
        require(
            auctionIds.length == reservePrices.length,
            "Market: Token IDs and reserve prices length mismatch"
        );
        for (uint i = 0; i < auctionIds.length; i++) {
            updateReserveAuction(auctionIds[i], reservePrices[i]);
        }
    }

    /**
     * @notice If an auction has been created but has not yet received bids, it may be canceled by the seller.
     * The NFT is returned to the seller from escrow.
     */
    function cancelReserveAuction(uint auctionId) public {
        ReserveAuction memory auction = auctionIdToAuction[auctionId];

        require(auction.seller == msg.sender, "Market: Not your auction");
        require(auction.endTime == 0, "Market: Auction in progress");

        delete nftContractToTokenIdToAuctionId[auction.nftContract][
            auction.tokenId
        ];
        delete auctionIdToAuction[auctionId];

        IERC721Upgradeable(auction.nftContract).transferFrom(
            address(this),
            auction.seller,
            auction.tokenId
        );

        emit ReserveAuctionCanceled(auctionId);
    }

    function cancelReserveAuctionBatch(uint[] calldata auctionIds) external {
        require(
            auctionIds.length <= _listingLimit,
            "Market: Too many auctions to cancel in one transaction"
        );
        for (uint i = 0; i < auctionIds.length; i++) {
            cancelReserveAuction(auctionIds[i]);
        }
    }

    /**
     * @notice A bidder may place a bid which is at least the value defined by `getMinBidAmount`.
     * If this is the first bid on the auction, the countdown will begin.
     * If there is already an outstanding bid, the previous bidder will be refunded at this time
     * and if the bid is placed in the final moments of the auction, the countdown may be extended.
     */
    function placeBid(uint auctionId, uint bid) public {
        ReserveAuction storage auction = auctionIdToAuction[auctionId];

        require(auction.amount != 0, "Market: Auction not found");

        if (auction.endTime == 0) {
            // If this is the first bid, ensure it's >= the reserve price
            require(
                bid >= auction.amount,
                "Market: Bid must be at least the reserve price"
            );
        } else {
            // If this bid outbids another, confirm that the bid is at least x% greater than the last
            require(
                auction.endTime >= block.timestamp,
                "Market: Auction is over"
            );

            require(
                bid >= _getMinBidAmount(auction.amount),
                "Market: Bid amount too low"
            );
        }

        IMODA.DAR_transferFrom(msg.sender, address(this), bid);

        if (auction.endTime == 0) {
            auction.amount = bid;
            auction.bidder = msg.sender;
            // On the first bid, the endTime is now + duration
            auction.endTime = block.timestamp + auction.duration;
        } else {
            // Cache and update bidder state before a possible reentrancy (via the value transfer)
            uint originalAmount = auction.amount;
            address originalBidder = auction.bidder;

            auction.amount = bid;
            auction.bidder = msg.sender;

            // When a bid outbids another, check to see if a time extension should apply.
            if (auction.endTime - block.timestamp < auction.extensionDuration) {
                auction.endTime = block.timestamp + auction.extensionDuration;
            }

            // Refund the previous bidder
            darToken.transfer(originalBidder, originalAmount);
        }

        emit ReserveAuctionBidPlaced(
            auctionId,
            msg.sender,
            bid,
            auction.endTime,
            block.timestamp
        );
    }

    /**
     * @notice Once the countdown has expired for an auction, anyone can settle the auction.
     * This will send the NFT to the highest bidder and distribute funds.
     */
    function finalizeReserveAuction(uint auctionId) public {
        ReserveAuction memory auction = auctionIdToAuction[auctionId];

        require(
            auction.endTime > 0,
            "Auction does not have bids or does not exist"
        );
        require(
            auction.endTime < block.timestamp,
            "Market: Auction still in progress"
        );

        delete nftContractToTokenIdToAuctionId[auction.nftContract][
            auction.tokenId
        ];

        delete auctionIdToAuction[auctionId];

        IERC721Upgradeable(auction.nftContract).transferFrom(
            address(this),
            auction.bidder,
            auction.tokenId
        );

        (
            uint royaltyFee,
            uint creatorSecondaryMarketFee,
            uint ownerRew
        ) = _distributeFunds(
                auction.nftContract,
                auction.tokenId,
                auction.seller,
                auction.amount
            );

        emit ReserveAuctionFinalized(
            auctionId,
            auction.seller,
            auction.bidder,
            royaltyFee,
            creatorSecondaryMarketFee,
            ownerRew
        );
    }

    /**
     * @dev Determines the minimum bid amount when outbidding another user.
     */
    function _getMinBidAmount(
        uint currentBidAmount
    ) private view returns (uint) {
        uint minIncrement = (currentBidAmount *
            _minPercentIncrementInBasisPoints) / BASIS_POINTS;

        if (minIncrement == 0) {
            // The next bid must be at least 1 wei greater than the current.
            return currentBidAmount + 1;
        }

        return currentBidAmount + minIncrement;
    }

    /**
     * @notice Returns the minimum amount a bidder must spend to participate in an auction.
     */
    function getMinBidAmount(uint auctionId) public view returns (uint) {
        ReserveAuction storage auction = auctionIdToAuction[auctionId];

        if (auction.endTime == 0) {
            return auction.amount;
        }

        return _getMinBidAmount(auction.amount);
    }

    uint[1000] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./NFTMarketFees.sol";

abstract contract NFTMarketOffer is NFTMarketFees {
    using AddressUpgradeable for address;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    mapping(uint => Offer) public offerIdToOffer;

    /// @custom:oz-renamed-from _minOfferTime
    uint public _minOfferDuration; // The minimum time a offer can be active

    uint private nextOfferId;

    uint public _maxOfferDuration;

    struct Offer {
        address nftContract;
        uint tokenId;
        uint endTime;
        address buyer;
        uint price;
    }

    // EVENTS -----------------

    event OfferCreated(
        address indexed nftContract,
        uint indexed tokenId,
        address indexed buyer,
        uint endTime,
        uint price,
        uint offerId
    );
    event OfferCanceled(uint offerId);

    event OfferFinalized(
        uint indexed offerId,
        address indexed seller,
        address indexed buyer,
        uint royaltyFee,
        uint creatorSecondaryMarketFee,
        uint ownerRew
    );
    event MinOfferDurationUpdated(uint minOfferDuration);
    event MaxOfferDurationUpdated(uint maxOfferDuration);

    // OFFER -----------------

    /*
     * An offer is made from the buyers party to the sellers party. The seller has no obligations.
     * The NFT in question does not need to be listed in any way either.
     * */

    function _initializeNFTMarketOffer() internal onlyInitializing {
        _maxOfferDuration = 30 days;
    }

    function _getNextAndIncrementOfferId() internal returns (uint) {
        return nextOfferId++;
    }

    function createOffer(
        address nftContract,
        uint tokenId,
        uint price,
        uint endTime
    ) external onlyAllowedContract(nftContract) onlyValidPrice(price) {
        uint offerId = _getNextAndIncrementOfferId();
        uint timeNow = block.timestamp;

        require(
            endTime >= timeNow + _minOfferDuration,
            "Market: Too short offer duration"
        );
        require(
            endTime <= timeNow + _maxOfferDuration,
            "Market: Too long offer duration"
        );

        require(
            IERC721Upgradeable(nftContract).ownerOf(tokenId) != address(0),
            "Market: NFT does not exist."
        );

        offerIdToOffer[offerId] = Offer(
            nftContract,
            tokenId,
            endTime,
            msg.sender,
            price
        );

        IMODA.DAR_transferFrom(msg.sender, address(this), price);

        emit OfferCreated(
            nftContract,
            tokenId,
            msg.sender,
            endTime,
            price,
            offerId
        );
    }

    function cancelOffer(uint offerId) external {
        Offer memory offer = offerIdToOffer[offerId];
        require(msg.sender == offer.buyer, "Market: Not your offer");

        delete offerIdToOffer[offerId];

        darToken.transfer(msg.sender, offer.price);

        emit OfferCanceled(offerId);
    }

    function finalizeOffer(uint offerId) external {
        Offer memory offer = offerIdToOffer[offerId];

        require(
            offer.endTime > block.timestamp,
            "Market: Offer has expired or does not exist"
        );

        delete offerIdToOffer[offerId];

        IERC721Upgradeable(offer.nftContract).transferFrom(
            msg.sender,
            offer.buyer,
            offer.tokenId
        );

        (
            uint royaltyFee,
            uint creatorSecondaryMarketFee,
            uint ownerRew
        ) = _distributeFunds(
                offer.nftContract,
                offer.tokenId,
                msg.sender,
                offer.price
            );

        emit OfferFinalized(
            offerId,
            msg.sender,
            offer.buyer,
            royaltyFee,
            creatorSecondaryMarketFee,
            ownerRew
        );
    }

    function updateMinOfferDuration(uint minOfferDuration) external onlyAdmin {
        require(
            minOfferDuration >= 1 minutes,
            "Market: can not be less than 1 minute"
        );
        _minOfferDuration = minOfferDuration;
        emit MinOfferDurationUpdated(minOfferDuration);
    }

    function updateMaxOfferDuration(uint maxOfferDuration) external onlyAdmin {
        require(
            maxOfferDuration <= 1000 days,
            "Market: must be less than 1000 days"
        );
        _maxOfferDuration = maxOfferDuration;
        emit MaxOfferDurationUpdated(maxOfferDuration);
    }

    uint[999] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./NFTMarketFees.sol";

/**
 * @notice Manages a reserve price auction for NFTs.
 */
abstract contract NFTMarketDutchAuction is NFTMarketFees {
    using AddressUpgradeable for address;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    mapping(address => mapping(uint => uint))
        public nftContractToTokenIdToDutchAuctionId;
    mapping(uint => DutchAuction) public dutchAuctionIdToDutchAuction;

    uint public _minDutchAuctionDuration; // Minimum duration an auction can be held
    uint public _maxDutchAuctionDuration; // Maximum duration an auction can be held

    uint private nextDutchAuctionId;

    struct DutchAuction {
        address nftContract;
        uint tokenId;
        address seller;
        uint endTime;
        uint duration;
        uint maxPrice;
        uint minPrice;
    }

    // EVENTS -----------------

    event DutchAuctionCreated(
        address indexed nftContract,
        uint indexed tokenId,
        address indexed seller,
        uint endTime,
        uint duration,
        uint maxPrice,
        uint minPrice,
        uint dutchAuctionId
    );
    event DutchAuctionCanceled(uint dutchAuctionId);

    event DutchAuctionFinalized(
        uint indexed dutchAuctionId,
        address indexed seller,
        address indexed buyer,
        uint royaltyFee,
        uint creatorSecondaryMarketFee,
        uint ownerRew
    );

    event MinDutchAuctionDurationUpdated(uint minDutchAuctionTime);
    event MaxDutchAuctionDurationUpdated(uint maxDutchAuctionTime);

    // Reserve Auction -----------------

    /*
     * Seller puts an NFT on auction with a determined reserve price - a minimum bid - for a determined duration. Multiple
     * users can bid on the NFT until the duration is over, which is when the auction can be finalized.
     * */

    function _initializeNFTMarketDutchAuction() internal onlyInitializing {
        _minDutchAuctionDuration = 12 hours;
        _maxDutchAuctionDuration = 30 days;
    }

    function _getNextAndIncrementDutchAuctionId() internal returns (uint) {
        return nextDutchAuctionId++;
    }

    /**
     * @dev Creates one reserve auction for the given NFT and token ID with custom duration.
     */
    function createDutchAuction(
        address nftContract,
        uint tokenId,
        uint endTime,
        uint maxPrice,
        uint minPrice
    ) public onlyAllowedContract(nftContract) {
        _createDutchAuction(nftContract, tokenId, endTime, maxPrice, minPrice);
    }

    function _createDutchAuction(
        address nftContract,
        uint tokenId,
        uint endTime,
        uint maxPrice,
        uint minPrice
    ) internal onlyValidPrice(minPrice) {
        uint timeNow = block.timestamp;
        require(
            endTime >= _minDutchAuctionDuration + timeNow,
            "Market: too short dutch auction duration"
        );
        require(
            endTime <= _maxDutchAuctionDuration + timeNow,
            "Market: too long dutch auction duration"
        );
        require(
            maxPrice > minPrice,
            "Market: MaxPrice must be greater than MinPrice"
        );

        uint dutchAuctionId = _getNextAndIncrementDutchAuctionId();

        nftContractToTokenIdToDutchAuctionId[nftContract][
            tokenId
        ] = dutchAuctionId;
        dutchAuctionIdToDutchAuction[dutchAuctionId] = DutchAuction(
            nftContract,
            tokenId,
            msg.sender,
            endTime,
            endTime - timeNow,
            maxPrice,
            minPrice
        );

        IERC721Upgradeable(nftContract).transferFrom(
            msg.sender,
            address(this),
            tokenId
        );
        emit DutchAuctionCreated(
            nftContract,
            tokenId,
            msg.sender,
            endTime,
            endTime - timeNow,
            maxPrice,
            minPrice,
            dutchAuctionId
        );
    }

    /**
     * @notice Creates an auctions for the given NFT contract and token IDs.
     * The NFTs are held in escrow until the auctions are finalized or canceled.
     * Uses a custom duration supplied by the user.
     */

    function createDutchAuctionBatch(
        address nftContract,
        uint[] calldata tokenIds,
        uint[] calldata maxPrices,
        uint[] calldata minPrices,
        uint endTime
    ) public onlyAllowedContract(nftContract) {
        require(
            tokenIds.length == maxPrices.length,
            "Market: Token IDs and max prices length mismatch"
        );
        require(
            tokenIds.length == minPrices.length,
            "Market: Token IDs and min prices length mismatch"
        );
        require(
            tokenIds.length <= _listingLimit,
            "Market: Too many tokens to list in one transaction"
        );

        for (uint i = 0; i < tokenIds.length; i++) {
            _createDutchAuction(
                nftContract,
                tokenIds[i],
                endTime,
                maxPrices[i],
                minPrices[i]
            );
        }
    }

    /**
     * @notice If an auction has been created but has not yet received bids, it may be canceled by the seller.
     * The NFT is returned to the seller from escrow.
     */
    function cancelDutchAuction(uint dutchAuctionId) public {
        DutchAuction memory dutchAuction = dutchAuctionIdToDutchAuction[
            dutchAuctionId
        ];

        require(dutchAuction.seller == msg.sender, "Market: Not your auction");

        delete nftContractToTokenIdToDutchAuctionId[dutchAuction.nftContract][
            dutchAuction.tokenId
        ];
        delete dutchAuctionIdToDutchAuction[dutchAuctionId];

        IERC721Upgradeable(dutchAuction.nftContract).transferFrom(
            address(this),
            dutchAuction.seller,
            dutchAuction.tokenId
        );

        emit DutchAuctionCanceled(dutchAuctionId);
    }

    function cancelDutchAuctionBatch(uint[] calldata auctionIds) external {
        require(
            auctionIds.length <= _listingLimit,
            "Market: Too many auctions to cancel in one transaction"
        );
        for (uint i = 0; i < auctionIds.length; i++) {
            cancelDutchAuction(auctionIds[i]);
        }
    }

    /**
     * @notice A bidder may place a bid which is at least the value defined by `getMinBidAmount`.
     * If this is the first bid on the auction, the countdown will begin.
     * If there is already an outstanding bid, the previous bidder will be refunded at this time
     * and if the bid is placed in the final moments of the auction, the countdown may be extended.
     */
    function buyDutchAuction(uint dutchAuctionId) public {
        DutchAuction memory dutchAuction = dutchAuctionIdToDutchAuction[
            dutchAuctionId
        ];

        require(
            dutchAuction.endTime >= block.timestamp,
            "Market: Auction is over"
        );
        uint price = getDutchAuctionPrice(dutchAuctionId);

        delete nftContractToTokenIdToDutchAuctionId[dutchAuction.nftContract][
            dutchAuction.tokenId
        ];
        delete dutchAuctionIdToDutchAuction[dutchAuctionId];

        IMODA.DAR_transferFrom(msg.sender, address(this), price);

        (
            uint royaltyFee,
            uint creatorSecondaryMarketFee,
            uint ownerRew
        ) = _distributeFunds(
                dutchAuction.nftContract,
                dutchAuction.tokenId,
                dutchAuction.seller,
                price
            );

        IERC721Upgradeable(dutchAuction.nftContract).transferFrom(
            address(this),
            msg.sender,
            dutchAuction.tokenId
        );

        emit DutchAuctionFinalized(
            dutchAuctionId,
            dutchAuction.seller,
            msg.sender,
            royaltyFee,
            creatorSecondaryMarketFee,
            ownerRew
        );
    }

    function getDutchAuctionPrice(uint dutchAuctionId)
        public
        view
        returns (uint)
    {
        DutchAuction memory dutchAuction = dutchAuctionIdToDutchAuction[
            dutchAuctionId
        ];

        if (dutchAuction.endTime > block.timestamp) {
            uint timeLeft = dutchAuction.endTime - block.timestamp;
            uint priceDelta = dutchAuction.maxPrice - dutchAuction.minPrice;

            uint price = dutchAuction.minPrice +
                (priceDelta * timeLeft) /
                dutchAuction.duration;

            return price;
        } else {
            return dutchAuction.minPrice;
        }
    }

    function updateMinDutchAuctionDuration(uint minDutchAuctionDuration)
        external
        onlyAdmin
    {
        require(
            minDutchAuctionDuration >= 1 minutes,
            "Market: can not be less than 1 minute"
        );
        _minDutchAuctionDuration = minDutchAuctionDuration;
        emit MinDutchAuctionDurationUpdated(minDutchAuctionDuration);
    }

    function updateMaxDutchAuctionDuration(uint maxDutchAuctionDuration)
        external
        onlyAdmin
    {
        require(
            maxDutchAuctionDuration <= 1000 days,
            "Market: can not be more than 1000 days"
        );
        _maxDutchAuctionDuration = maxDutchAuctionDuration;
        emit MaxDutchAuctionDurationUpdated(maxDutchAuctionDuration);
    }

    uint[1000] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts-upgradeable/token/common/ERC2981Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

import "../interfaces/IMoDApproveProxy.sol";

/**
 * @notice A mixin to distribute funds when an NFT is sold.
 */
abstract contract NFTMarketFees is Initializable, AccessControlUpgradeable {
    using AddressUpgradeable for address;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;
    uint internal constant BASIS_POINTS = 10000;

    mapping(address => bool) public nftContractAllowed;
    uint public _secondaryMarketCreatorFeeInBasisPoints;
    address public _primarySalesWallet;
    address public _secondarySalesWallet;
    uint8 internal _listingLimit;
    uint internal _minPrice;

    IMoDApproveProxy public IMODA;
    IERC20Upgradeable internal darToken;

    event SecondaryMarketCreatorFeeUpdated(
        uint secondaryMarketCreatorFeeInBasisPoints
    );

    event AdminAllowContract(address nftcontract, bool allowed);

    modifier onlyValidWallet(address wallet) {
        require(wallet != address(0), "Market: zero address");
        _;
    }

    modifier onlyAdmin() {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "AdminRole: caller does not have the Admin role"
        );
        _;
    }

    modifier onlyValidSecondaryMarketCreatorFee(
        uint secondaryMarketCreatorFeeInBasisPoints
    ) {
        require(
            secondaryMarketCreatorFeeInBasisPoints < BASIS_POINTS,
            "Market: Fee >= 100%"
        );
        _;
    }

    modifier onlyAllowedContract(address nftContract) {
        require(
            nftContractAllowed[nftContract],
            "Market: NFT Contract not allowed"
        );
        _;
    }

    modifier onlyValidPrice(uint price) {
        require(
            price >= _minPrice,
            "Market: Price must be greater than minimum price"
        );
        _;
    }

    function _initializeNFTMarketFees(
        uint8 listingLimit,
        address primarySalesWallet,
        address secondarySalesWallet,
        uint secondaryMarketCreatorFeeInBasisPoints,
        IMoDApproveProxy _IMODA,
        IERC20Upgradeable _darToken
    )
        internal
        onlyValidWallet(primarySalesWallet)
        onlyValidWallet(secondarySalesWallet)
        onlyValidSecondaryMarketCreatorFee(
            secondaryMarketCreatorFeeInBasisPoints
        )
        onlyInitializing
    {
        _listingLimit = listingLimit;
        _primarySalesWallet = primarySalesWallet;
        _secondarySalesWallet = secondarySalesWallet;
        _secondaryMarketCreatorFeeInBasisPoints = secondaryMarketCreatorFeeInBasisPoints;
        IMODA = _IMODA;
        darToken = _darToken;
    }

    /**
     * @notice Returns how funds will be distributed for a sale at the given price point.
     * @dev This could be used to present exact fee distributing on listing or before a bid is placed.
     */
    function getFees(
        address nftContract,
        uint tokenId,
        uint price
    )
        public
        view
        returns (
            uint royaltyFee,
            uint creatorSecondaryMarketFee,
            uint ownerRew
        )
    {
        (, royaltyFee, , creatorSecondaryMarketFee, , ownerRew) = _getFees(
            nftContract,
            tokenId,
            IERC721Upgradeable(nftContract).ownerOf(tokenId),
            price
        );
    }

    /**
     * @dev Calculates how funds should be distributed for the given sale details.
     * If this is a primary sale, the creator revenue will appear as `ownerRew`.
     */
    function _getFees(
        address nftContract,
        uint tokenId,
        address seller,
        uint price
    )
        public
        view
        returns (
            address royaltyFeeTo,
            uint royalty,
            address creatorSecondaryMarketFeeTo,
            uint creatorSecondaryMarketFee,
            address ownerRewTo,
            uint ownerRew
        )
    {
        bool isPrimary = hasRole(DEFAULT_ADMIN_ROLE, seller);

        if (!isPrimary && checkRoyalties(nftContract)) {
            (royaltyFeeTo, royalty) = ERC2981Upgradeable(nftContract)
                .royaltyInfo(tokenId, price);
        } else {
            royalty = 0;
        }

        // Prevent malicious contract from claiming a higher fee than the sales price
        if (royalty >= price) {
            royalty = 0;
        }

        price = price - royalty;

        if (isPrimary) {
            ownerRewTo = _primarySalesWallet;
        } else {
            creatorSecondaryMarketFee =
                (price * _secondaryMarketCreatorFeeInBasisPoints) /
                BASIS_POINTS;
            creatorSecondaryMarketFeeTo = _secondarySalesWallet;
            ownerRewTo = seller;
        }

        ownerRew = price - creatorSecondaryMarketFee;
    }

    /**
     * @dev Check if NFT Contract supports the EIP-2981 standard for royalties.
     */
    function checkRoyalties(address _contract) internal view returns (bool) {
        bool success = ERC165(_contract).supportsInterface(
            _INTERFACE_ID_ERC2981
        );
        return success;
    }

    /**
     * @dev Distributes funds to creator and NFT owner after a sale.
     */
    function _distributeFunds(
        address nftContract,
        uint tokenId,
        address seller,
        uint price
    )
        internal
        returns (
            uint royaltyFee,
            uint creatorSecondaryMarketFee,
            uint ownerRew
        )
    {
        address royaltyTo;
        address creatorSecondaryMarketFeeTo;
        address ownerRewTo;
        (
            royaltyTo,
            royaltyFee,
            creatorSecondaryMarketFeeTo,
            creatorSecondaryMarketFee,
            ownerRewTo,
            ownerRew
        ) = _getFees(nftContract, tokenId, seller, price);

        if (royaltyFee > 0 && royaltyTo != address(0)) {
            darToken.transfer(royaltyTo, royaltyFee);
        }

        if (creatorSecondaryMarketFee > 0) {
            darToken.transfer(
                creatorSecondaryMarketFeeTo,
                creatorSecondaryMarketFee
            );
        }

        darToken.transfer(ownerRewTo, ownerRew);
    }

    /**
     * @notice Allows an admin to change the secondary market creator fee.
     */
    function updateSecondaryMarketCreatorFee(
        uint secondaryMarketCreatorFeeInBasisPoints
    )
        public
        onlyAdmin
        onlyValidSecondaryMarketCreatorFee(
            secondaryMarketCreatorFeeInBasisPoints
        )
    {
        _secondaryMarketCreatorFeeInBasisPoints = secondaryMarketCreatorFeeInBasisPoints;

        emit SecondaryMarketCreatorFeeUpdated(
            secondaryMarketCreatorFeeInBasisPoints
        );
    }

    // Changes the min price a auction, listing or offer can have.
    function setMinPrice(uint minPrice) public onlyAdmin {
        _minPrice = minPrice;
    }

    function setNftContractAllowed(address nftContract, bool allowed)
        public
        onlyAdmin
    {
        nftContractAllowed[nftContract] = allowed;
        emit AdminAllowContract(nftContract, allowed);
    }

    function setPrimarySalesWallet(address newPrimarySalesWallet)
        public
        onlyValidWallet(newPrimarySalesWallet)
        onlyAdmin
    {
        _primarySalesWallet = newPrimarySalesWallet;
    }

    function setSecondarySalesWallet(address newSecondarySalesWallet)
        public
        onlyValidWallet(newSecondarySalesWallet)
        onlyAdmin
    {
        _secondarySalesWallet = newSecondarySalesWallet;
    }

    uint[1000] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./NFTMarketFees.sol";

abstract contract NFTMarketListing is NFTMarketFees {
    using AddressUpgradeable for address;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    mapping(uint => Listing) public listingIdToListing;
    mapping(address => mapping(uint => uint))
        public nftContractToTokenIdToListingId;

    /// @custom:oz-renamed-from _minListingTime
    uint public _minListingDuration; // The minimum time a listing can be up for

    uint private nextListingId;

    uint public _maxListingDuration;

    struct Listing {
        address nftContract;
        uint tokenId;
        uint endTime;
        address seller;
        uint price;
    }

    // EVENTS -----------------

    event ListingCreated(
        address indexed nftContract,
        uint indexed tokenId,
        address indexed seller,
        uint endTime,
        uint price,
        uint listingId
    );
    event ListingCanceled(uint listingId);

    event ListingFinalized(
        uint indexed listingId,
        address indexed seller,
        address indexed buyer,
        uint royaltyFee,
        uint creatorSecondaryMarketFee,
        uint ownerRew
    );

    event MinListingDurationUpdated(uint minListingDuration);
    event MaxListingDurationUpdated(uint maxListingDuration);

    // LISTING -----------------

    /*
     * Listings are sales that can be instantaneously bought. This means that there is no auction,
     * only a price and a sale if a user buys the listing. In some cases this proves to be more convenient than an auction.
     */

    function _initializeNFTMarketListing() internal onlyInitializing {
        _maxListingDuration = 30 days;
    }

    function _getNextAndIncrementListingId() internal returns (uint) {
        return nextListingId++;
    }

    function createListing(
        address nftContract,
        uint tokenId,
        uint price,
        uint endTime
    ) public onlyAllowedContract(nftContract) {
        _createListing(nftContract, tokenId, price, endTime);
    }

    function _createListing(
        address nftContract,
        uint tokenId,
        uint price,
        uint endTime
    ) internal onlyValidPrice(price) {
        uint listingId = _getNextAndIncrementListingId();
        uint timeNow = block.timestamp;

        require(
            endTime >= timeNow + _minListingDuration,
            "Market: Too short listing duration"
        );
        require(
            endTime <= timeNow + _maxListingDuration,
            "Market: Too long listing duration"
        );

        listingIdToListing[listingId] = Listing(
            nftContract,
            tokenId,
            endTime,
            msg.sender,
            price
        );

        nftContractToTokenIdToListingId[nftContract][tokenId] = listingId;

        IERC721Upgradeable(nftContract).transferFrom(
            msg.sender,
            address(this),
            tokenId
        );

        emit ListingCreated(
            nftContract,
            tokenId,
            msg.sender,
            endTime,
            price,
            listingId
        );
    }

    function createListingBatch(
        address nftContract,
        uint[] calldata tokenIds,
        uint[] calldata prices,
        uint endTime
    ) public onlyAllowedContract(nftContract) {
        require(
            tokenIds.length == prices.length,
            "Market: Token IDs and prices length mismatch"
        );
        require(
            tokenIds.length <= _listingLimit,
            "Market: Too many tokens to list in one transaction"
        );

        for (uint i = 0; i < tokenIds.length; i++) {
            _createListing(nftContract, tokenIds[i], prices[i], endTime);
        }
    }

    /**
     * @dev Returns the seller that put a given NFT into escrow.
     */
    function getListingSellerFor(
        address nftContract,
        uint tokenId
    ) public view returns (address) {
        address seller = listingIdToListing[
            nftContractToTokenIdToListingId[nftContract][tokenId]
        ].seller;

        return seller;
    }

    function cancelListing(uint listingId) public {
        Listing memory listing = listingIdToListing[listingId];
        require(msg.sender == listing.seller, "Market: Not your listing");

        delete nftContractToTokenIdToListingId[listing.nftContract][
            listing.tokenId
        ];
        delete listingIdToListing[listingId];

        IERC721Upgradeable(listing.nftContract).transferFrom(
            address(this),
            listing.seller,
            listing.tokenId
        );

        emit ListingCanceled(listingId);
    }

    function cancelListingBatch(uint[] calldata listingIds) external {
        require(
            listingIds.length <= _listingLimit,
            "Market: Too many listings to cancel in one transaction"
        );
        for (uint i = 0; i < listingIds.length; i++) {
            cancelListing(listingIds[i]);
        }
    }

    function buyListing(uint listingId) public {
        Listing memory listing = listingIdToListing[listingId];

        require(
            listing.endTime > block.timestamp,
            "Market: Listing has expired or does not exist"
        );

        delete nftContractToTokenIdToListingId[listing.nftContract][
            listing.tokenId
        ];
        delete listingIdToListing[listingId];

        IMODA.DAR_transferFrom(msg.sender, address(this), listing.price);

        (
            uint royaltyFee,
            uint creatorSecondaryMarketFee,
            uint ownerRew
        ) = _distributeFunds(
                listing.nftContract,
                listing.tokenId,
                listing.seller,
                listing.price
            );

        IERC721Upgradeable(listing.nftContract).transferFrom(
            address(this),
            msg.sender,
            listing.tokenId
        );

        emit ListingFinalized(
            listingId,
            listing.seller,
            msg.sender,
            royaltyFee,
            creatorSecondaryMarketFee,
            ownerRew
        );
    }

    function updateMinListingDuration(
        uint minListingDuration
    ) external onlyAdmin {
        require(
            minListingDuration >= 1 minutes,
            "Market: can not be less than 1 minute"
        );
        _minListingDuration = minListingDuration;
        emit MinListingDurationUpdated(minListingDuration);
    }

    function updateMaxListingDuration(
        uint maxListingDuration
    ) external onlyAdmin {
        require(
            maxListingDuration <= 1000 days,
            "Market: must be less than 1000 days"
        );
        _maxListingDuration = maxListingDuration;
        emit MaxListingDurationUpdated(maxListingDuration);
    }

    uint[999] private __gap;
}

// krippilippa
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IMoDApproveProxy {
    function DAR_transferFrom(address _sender, address _recipient, uint256 _amount) external;
    function item_safeTransferFrom(address _from, address _to, uint _tokenId, bytes memory _data) external;
    function resources_safeTransferFrom(address _from, address _to, uint _id, uint _amount, bytes memory _data) external;
    function resources_safeBatchTransferFrom(address _from, address _to, uint[] calldata _ids, uint[] calldata _amounts, bytes memory _data) external;
    function planetPlot_safeTransferFrom(address _from, address _to, uint _tokenId, bytes memory _data) external;
    function item_burn(address _from, uint256[] memory _burnItemIds) external returns (bool);
    function item_mint(address _to, uint256[] memory _mintTypes) external returns (bool);
    function item_burnAndMint(address _fromTo, uint256[] memory _mintTypes, uint256[] memory _burnItemIds) external returns (bool);
    function resources_burnBatch(address _from, uint256[] memory _ids, uint256[] memory _amounts) external returns (bool);
    function resources_mintBatch(address _to, uint256[] memory _ids, uint256[] memory _amounts) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/common/ERC2981.sol)

pragma solidity ^0.8.0;

import "../../interfaces/IERC2981Upgradeable.sol";
import "../../utils/introspection/ERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
abstract contract ERC2981Upgradeable is Initializable, IERC2981Upgradeable, ERC165Upgradeable {
    function __ERC2981_init() internal onlyInitializing {
    }

    function __ERC2981_init_unchained() internal onlyInitializing {
    }
    struct RoyaltyInfo {
        address receiver;
        uint96 royaltyFraction;
    }

    RoyaltyInfo private _defaultRoyaltyInfo;
    mapping(uint256 => RoyaltyInfo) private _tokenRoyaltyInfo;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165Upgradeable, ERC165Upgradeable) returns (bool) {
        return interfaceId == type(IERC2981Upgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @inheritdoc IERC2981Upgradeable
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[48] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../extensions/draft-IERC20PermitUpgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20PermitUpgradeable token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal onlyInitializing {
    }

    function __AccessControl_init_unchained() internal onlyInitializing {
    }
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        StringsUpgradeable.toHexString(uint160(account), 20),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.6.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981Upgradeable is IERC165Upgradeable {
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
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
interface IERC165Upgradeable {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20PermitUpgradeable {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
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