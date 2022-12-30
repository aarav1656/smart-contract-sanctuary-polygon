// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../interfaces/IStanNFT.sol";
import "../interfaces/IListing.sol";
import "../interfaces/IOffer.sol";
import "../interfaces/IAuctionStorage.sol";
import "../interfaces/IStanFund.sol";
import "../library/AuctionLibrary.sol";
import "../library/AuctionStructure.sol";

contract AuctionPureV2 is Initializable {
    using AuctionLibrary for AuctionStructure.Offer;
    using AuctionLibrary for AuctionStructure.auctionStruct;
    using AuctionLibrary for AuctionStructure.Currency;

    IStanNFT public stanNFT;
    IListing public listing;
    IOffer public offer;
    IStanFund public stanFund;
    IAuctionStorage public auctionStorage;

    address private owner;
    address public auctionAddress;

    function initialize(
        address _stanNFT,
        address _listing,
        address _offer,
        address _auctionStorage,
        address _stanFund
    ) public initializer {
        owner = msg.sender;
        stanNFT = IStanNFT(_stanNFT);
        listing = IListing(_listing);
        offer = IOffer(_offer);
        stanFund = IStanFund(_stanFund);
        auctionStorage = IAuctionStorage(_auctionStorage);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "InvalidOwner");
        _;
    }

    modifier onlyAuction() {
        require(auctionAddress == msg.sender, "InvalidOwner");
        _;
    }

    modifier onlyOwnerNFTOrAuction(uint256 _tokenId) {
        require(
            msg.sender == stanNFT.ownerOf(_tokenId) ||
                msg.sender == auctionAddress,
            "InvalidOwnerNFT"
        );
        _;
    }

    modifier checkStateOfAution(bytes memory _auctionId) {
        AuctionStructure.infoAuction memory _auctionInstance = auctionStorage
            .getInforAuction(_auctionId);

        require(
            _auctionInstance.state == AuctionStructure.StateOfAution.ACTIVE,
            "InvalidState"
        );
        _;
    }

    function setAuction(address _auction) external onlyOwner {
        auctionAddress = _auction;
    }

    function setStanFund(address _stanFundAddress) external onlyOwner {
        stanFund = IStanFund(_stanFundAddress);
    }

    function listingNFTAuction(
        AuctionStructure.paramListing calldata _paramListing,
        bool _isWhiteList,
        AuctionStructure.feeStanFixed calldata _feeStanFixed
    ) external onlyOwnerNFTOrAuction(_paramListing.tokenId) {
        require(
            stanNFT.getIsApprovedForAll(_paramListing.maker, address(this)),
            "NotYetApproved"
        );

        AuctionStructure.stanFundParams memory paramStanFund = stanFund.get(
            _paramListing.maker
        );

        require(
            (paramStanFund.result &&
                paramStanFund.userStanFund >=
                _feeStanFixed.feeListingNFTAuction) || _isWhiteList,
            "InvalidBalance"
        );

        if (
            !_isWhiteList ||
            _paramListing.currency == AuctionStructure.Currency.CRYPTO
        )
            stanFund.set(
                _feeStanFixed.feeListingNFTAuction,
                AuctionStructure.Operator.MINUS,
                _paramListing.maker
            );

        address ownerOfListing = listing.listingNFTAuction(
            _paramListing,
            address(stanNFT)
        );

        stanNFT.updateOwnerNFTAndTransferNFT(
            _paramListing.maker,
            address(stanNFT),
            _paramListing.tokenId
        );
        auctionStorage.listingNFTAuction(
            _paramListing.indexId,
            _paramListing.tokenId,
            ownerOfListing,
            _paramListing.currency
        );
    }

    function cancelListingAuction(
        bytes memory _listingId,
        bool _isWhiteList,
        AuctionStructure.feeStanFixed calldata _feeStanFixed
    ) external onlyAuction returns (uint256) {
        AuctionStructure.Listing memory listingInstance = listing
            .getInforListing(_listingId);

        AuctionStructure.stanFundParams memory paramStanFund = stanFund.get(
            listingInstance.Owner
        );

        require(
            (paramStanFund.result &&
                paramStanFund.userStanFund >=
                _feeStanFixed.feeCancelListingAuction) || _isWhiteList,
            "InvalidBalance"
        );

        stanFund.handleBackFeeToUser(
            auctionStorage.backFeeToUserFund(listingInstance.AuctionId)
        );

        if (listingInstance.currency == AuctionStructure.Currency.CRYPTO)
            stanFund.set(
                _feeStanFixed.feeCancelListingAuction,
                AuctionStructure.Operator.MINUS,
                listingInstance.Owner
            );

        auctionStorage.changeStateOffers(listingInstance.AuctionId, address(0));
        listing.cancelListingAuction(_listingId);

        stanNFT.updateOwnerNFTAndTransferNFT(
            address(stanNFT),
            listingInstance.Owner,
            listingInstance.tokenId
        );

        return listingInstance.tokenId;
    }

    function _reOffer(AuctionStructure.paramReOffer memory params)
        private
        view
        returns (uint256)
    {
        AuctionStructure.infoOfferAuction memory infoInstance = auctionStorage
            .getInforOfferAuction(params.auctionId, params.subOfferId);

        if (
            infoInstance.owner == address(0) &&
            infoInstance.state == AuctionStructure.StateOfOffer.INACTIVE
        ) return params.amount;

        require(infoInstance.amount < params.amount, "ReOfferFailed");

        return params.amount - infoInstance.amount;
    }

    function placeBidAuction(
        bytes memory _subOfferId,
        bytes memory _auctionId,
        uint256 _amount,
        address _maker,
        bool _isWhiteList,
        AuctionStructure.feeStanFixed calldata _feeStanFixed,
        AuctionStructure.Currency _currency
    ) external checkStateOfAution(_auctionId) onlyAuction returns (uint256) {
        AuctionStructure.stanFundParams memory paramStanFund = stanFund.get(
            _maker
        );

        require(
            (paramStanFund.result &&
                paramStanFund.userStanFund >=
                (_amount + _feeStanFixed.feePlaceBidAuction)) || _isWhiteList,
            "InvalidBalance"
        );
        AuctionStructure.Listing memory listingInstance = listing
            .getInforListing(_auctionId);

        require(
            listingInstance.ExpirationTime >= block.timestamp,
            "InvalidTimestamp"
        );

        require(
            listingInstance.Amount <= _amount || _isWhiteList,
            "InvalidOffer"
        );

        AuctionStructure.paramReOffer memory paramsReOffer = AuctionStructure
            .paramReOffer(_subOfferId, _auctionId, _amount);

        if (!_isWhiteList)
            stanFund.set(
                (_reOffer(paramsReOffer) + _feeStanFixed.feePlaceBidAuction),
                AuctionStructure.Operator.MINUS,
                _maker
            );

        AuctionStructure.paramOffer memory params = AuctionStructure.paramOffer(
            _subOfferId,
            listingInstance.AuctionId,
            listingInstance.tokenId,
            listingInstance.Owner,
            _maker,
            listingInstance.ExpirationTime,
            _amount,
            listingInstance.isAuction,
            _currency
        );

        auctionStorage.placeBidAuction(params);

        return listingInstance.tokenId;
    }

    function acceptOfferAuction(
        bytes memory _auctionId,
        bytes memory _subOfferId,
        bytes memory _nftId,
        AuctionStructure.feeStanService calldata _feeStanService
    ) external onlyAuction returns (uint256) {
        AuctionStructure.infoOfferAuction memory infoInstance = auctionStorage
            .getInforOfferAuction(_auctionId, _subOfferId);

        AuctionStructure.Listing memory listingInstance = listing
            .getInforListing(_auctionId);

        address ownerOfNFT = stanNFT.ownerOf(infoInstance.tokenId);

        require(ownerOfNFT == address(stanNFT), "InvalidOwner");
        require(
            infoInstance.state == AuctionStructure.StateOfOffer.ACTIVE &&
                listingInstance.state == AuctionStructure.StateOfListing.ACTIVE,
            "InvalidState"
        );
        require(
            block.timestamp < listingInstance.ExpirationTime,
            "InvalidTimestamp"
        );

        auctionStorage.acceptOfferAuction(_auctionId, _subOfferId);

        AuctionStructure.puchasing memory params = AuctionStructure.puchasing(
            infoInstance.owner,
            infoInstance.maker,
            infoInstance.amount,
            _feeStanService.ratioAcceptOfferAuctionVal,
            _feeStanService.ratioAcceptOfferAuctionDenomination,
            infoInstance.tokenId,
            AuctionStructure.Method.AUCTION,
            listingInstance.currency.getPaymentMethod(infoInstance.currency)
        );

        stanFund.purchaseProcessing(params);

        stanNFT.updateOwnerNFTAndTransferNFT(
            ownerOfNFT,
            infoInstance.maker,
            infoInstance.tokenId
        );

        offer.updateOwnerOfNFT(_nftId, infoInstance.maker);

        return infoInstance.tokenId;
    }

    function cancelOfferAuction(
        bytes memory _auctionId,
        bytes calldata _subOfferId,
        bool _isWhiteList,
        address _sender
    ) external onlyAuction returns (uint256) {
        (
            address maker,
            uint256 tokenId,
            uint256 subOfferAmount,
            AuctionStructure.Currency currency
        ) = auctionStorage.getInforSubOffer(_auctionId, _subOfferId);

        require(_isWhiteList || _sender == maker, "InvalidOwner");

        if (currency == AuctionStructure.Currency.CRYPTO)
            stanFund.set(subOfferAmount, AuctionStructure.Operator.PLUS, maker);

        auctionStorage.cancelOfferAuction(_auctionId, _subOfferId);

        return tokenId;
    }

    function expiredOffer(
        bytes memory _indexId,
        bytes[] calldata _subOffersIdParam
    ) external onlyAuction returns (uint256) {
        AuctionStructure.Listing memory listingInstance = listing
            .getInforListing(_indexId);

        if (listingInstance.AuctionId.length != 0) {
            auctionStorage.expiredOffer(_indexId, _subOffersIdParam);
            stanFund.handleBackFeeToUser(
                auctionStorage.backFeeToUserFund(_indexId)
            );
        } else {
            offer.expiredOffer(_indexId, _subOffersIdParam);
        }

        return listingInstance.tokenId;
    }

    function expiredListing(bytes[] memory _listingIds, bool _isAuction)
        external
        onlyAuction
    {
        listing.expiredListing(_listingIds);
        for (uint256 i = 0; i < _listingIds.length; ) {
            AuctionStructure.Listing memory listingAuction = listing
                .getInforListing(_listingIds[i]);
            stanNFT.updateOwnerNFTAndTransferNFT(
                address(stanNFT),
                listingAuction.Owner,
                listingAuction.tokenId
            );
            unchecked {
                ++i;
            }
        }
        if (_isAuction) {
            auctionStorage.expiredListing(_listingIds);
        }
    }

    function _processFinishAuction(
        bytes memory _auctionId,
        bytes memory _winnerSubOfferId,
        AuctionStructure.Currency _currencyListing,
        AuctionStructure.feeStanService calldata _feeStanService
    ) private returns (uint256) {
        AuctionStructure.infoOfferAuction memory infoInstance = auctionStorage
            .getInforOfferAuction(_auctionId, _winnerSubOfferId);

        require(
            infoInstance.state == AuctionStructure.StateOfOffer.ACTIVE,
            "InvalidState"
        );

        address ownerNFT = stanNFT.ownerOf(infoInstance.tokenId);

        AuctionStructure.puchasing memory params = AuctionStructure.puchasing(
            infoInstance.owner,
            infoInstance.maker,
            infoInstance.amount,
            _feeStanService.ratioFinishAuctionVal,
            _feeStanService.ratioFinishAuctionDenomination,
            infoInstance.tokenId,
            AuctionStructure.Method.AUCTION,
            _currencyListing.getPaymentMethod(infoInstance.currency)
        );

        stanFund.purchaseProcessing(params);

        stanNFT.updateOwnerNFTAndTransferNFT(
            ownerNFT,
            infoInstance.maker,
            infoInstance.tokenId
        );
        return infoInstance.tokenId;
    }

    function finishAuction(
        bytes memory _auctionId,
        bytes memory _nftId,
        AuctionStructure.feeStanService calldata _feeStanService
    ) external onlyAuction checkStateOfAution(_auctionId) returns (uint256) {
        AuctionStructure.Listing memory listingInstance = listing
            .getInforListing(_auctionId);

        require(
            listingInstance.state == AuctionStructure.StateOfListing.ACTIVE,
            "InvalidState"
        );
        (address winner, bytes memory winnerSubOfferId) = auctionStorage
            .finishAuction(_auctionId);
        auctionStorage.changeStateOffers(_auctionId, winner);

        listing.updateListing(
            _auctionId,
            AuctionStructure.StateOfListing.INACTIVE
        );

        if (_nftId.length > 0) offer.updateOwnerOfNFT(_nftId, winner);
        stanFund.handleBackFeeToUser(
            auctionStorage.backFeeToUserFund(_auctionId)
        );

        uint256 tokenId = _processFinishAuction(
            _auctionId,
            winnerSubOfferId,
            listingInstance.currency,
            _feeStanService
        );

        return tokenId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/Initializable.sol)

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
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
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
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
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
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initialized`
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initializing`
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "../library/AuctionLibrary.sol";

interface IStanNFT {
    event STAN_EVENT(
        bytes requestId,
        string nameFunction,
        bool platForm,
        uint256 tokenId
    );

    event STAN_BATCH_TRANSFER(
        bytes requestId,
        AuctionLibrary.FunctionName nameFunction,
        bool platForm,
        uint256 indexed fromTokenId,
        uint256 toTokenId
    );

    function createNFT(
        bytes calldata _requestId,
        bytes calldata _collectionId,
        uint256 _quantity,
        bool _isWeb
    ) external;

    function createNFTByStan(
        bytes calldata _requestId,
        bytes calldata _collectionId,
        uint256 _quantity,
        address _to,
        bytes[] calldata _nftIds,
        bool _isWeb
    ) external;

    function updateTokenToListing(bytes calldata _listing, uint256 _tokenId)
        external;

    function getTokenToListing(uint256 _tokenId)
        external
        view
        returns (bytes memory);

    function deleteTokenToListing(uint256 _tokenId) external;

    function getListingResult(uint256 _tokenId) external view returns (bool);

    function setPriceNFT(uint256 _tokenId, uint256 _amount) external;

    function getPriceNFT(uint256 _tokenId) external view returns (uint256);

    function updateOwnerNFTAndTransferNFT(
        address _from,
        address _to,
        uint256 _tokenId
    ) external;

    function ownerOf(uint256 _tokenId) external view returns (address);

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external view returns (bytes4);

    function moveBatchNFTToCollection(
        bytes calldata _requestId,
        bytes calldata _oldIdCollection,
        bytes calldata _newIdCollection,
        address _creator,
        uint256 _quantity,
        uint256[] calldata _tokenIds,
        bool _isWeb
    ) external;

    function approveForAll(address _operator, bool _approved) external;

    function approveForAuction(
        address _owner,
        address _operator,
        bool _approved
    ) external;

    function getIsApprovedForAll(address _owner, address _operator)
        external
        view
        returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "../library/AuctionLibrary.sol";

interface IListing {
    function listingNFTAuction(
        AuctionStructure.paramListing calldata _paramListing,
        address _stanNFT
    ) external returns (address);

    function listingNFTFixedPrice(
        AuctionStructure.paramListing calldata paramListing,
        address _stanNFT
    ) external;

    function cancelListingFixedPrice(bytes calldata _listingId) external;

    function cancelListingAuction(bytes calldata _listingId) external;

    function getInforListing(bytes calldata _listing)
        external
        view
        returns (AuctionStructure.Listing memory);

    function expiredListing(bytes[] calldata listingIds) external;

    function updateListing(
        bytes calldata _listingId,
        AuctionStructure.StateOfListing state
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "../library/AuctionLibrary.sol";

interface IOffer {
    function makeOfferFixedPrice(
        AuctionStructure.paramOffer memory _paramOffer,
        AuctionStructure.Currency _currency
    ) external;

    function acceptOfferPvP(bytes calldata _nftId, bytes calldata _subOfferId)
        external
        returns (address);

    function cancelOfferPvP(
        bytes calldata _nftId,
        bytes calldata _subOfferId,
        address _sender,
        bool isWhiteList
    ) external returns (uint256);

    function getInforOffer(bytes calldata _indexId, bytes calldata _subOfferId)
        external
        view
        returns (AuctionStructure.infoOffer memory);

    function expiredOffer(
        bytes calldata _indexId,
        bytes[] calldata subOffersIdParam
    ) external;

    function updateOwnerOfNFT(bytes calldata _indexId, address _user) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "../library/AuctionLibrary.sol";
import "../library/AuctionStructure.sol";

interface IAuctionStorage {
    function getInforAuction(bytes calldata _auctionId)
        external
        view
        returns (AuctionStructure.infoAuction memory);

    function getInforSubOffer(
        bytes calldata _auctionId,
        bytes calldata _subOfferId
    )
        external
        view
        returns (
            address,
            uint256,
            uint256,
            AuctionStructure.Currency
        );

    function getInforOfferAuction(
        bytes memory _indexId,
        bytes memory _subOfferId
    ) external view returns (AuctionStructure.infoOfferAuction memory);

    function backFeeToUserFund(bytes memory _auctionId)
        external
        view
        returns (AuctionStructure.userFund[] memory);

    function changeStateOffers(bytes memory _auctionId, address _exceptionist)
        external;

    function listingNFTAuction(
        bytes memory _auctionId,
        uint256 _tokenId,
        address _ownerOfListing,
        AuctionStructure.Currency _currency
    ) external;

    function placeBidAuction(AuctionStructure.paramOffer memory _params)
        external;

    function acceptOfferAuction(
        bytes memory _auctionId,
        bytes memory _subOfferId
    ) external;

    function cancelOfferAuction(
        bytes memory _auctionId,
        bytes calldata _subOfferId
    ) external;

    function expiredOffer(
        bytes memory _indexId,
        bytes[] calldata subOffersIdParam
    ) external;

    function expiredListing(bytes[] memory listingIds) external;

    function finishAuction(bytes memory _auctionId)
        external
        returns (address, bytes memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "../library/AuctionLibrary.sol";
import "../library/AuctionStructure.sol";

interface IStanFund {
    function purchaseProcessing(AuctionStructure.puchasing memory params)
        external;

    function handleBackFeeToUser(AuctionStructure.userFund[] memory _users)
        external;

    function set(
        uint256 _amount,
        AuctionStructure.Operator _operator,
        address _user
    ) external;

    function get(address _user)
        external
        view
        returns (AuctionStructure.stanFundParams memory);

    function getInforStanFund()
        external
        returns (
            uint256 totalSupply,
            uint256 userSupply,
            uint256 val,
            uint256 valDenomination,
            uint256 stanFundToWithdraw
        );
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./AuctionStructure.sol";

library AuctionLibrary {
    enum FunctionName {
        LIST_FIXED_PRICE,
        LIST_AUCTION,
        BUY_NFT,
        CANCEL_LISTING_FIX_PRICE,
        CANCEL_LISTING_AUCTION,
        MAKE_OFFER_WITH_NFT,
        RE_OFFER,
        MAKE_OFFER_WITH_AUCTION,
        ACCEPT_OFFER_WITH_NFT,
        ACCEPT_OFFER_WITH_AUCTION,
        CANCEL_OFFER_WITH_NFT,
        CANCEL_OFFER_WITH_AUCTION,
        EXPIRED_FIX_PRICE,
        EXPIRED_LISTING,
        TRANSFER_NFT_PVP,
        DEPOSIT,
        WITHDRAW,
        WITHDRAW_BY_STAN,
        CLAIM_NFT,
        DEPOSIT_NFT,
        FINISH_AUCTION,
        CREATE_NFT_BY_STAN,
        CREATE_NFT,
        CREATE_COLLECTION,
        ADD_NFT_TO_COLLECTION,
        MOVE_BATCH_NFT
    }

    function saveOffer(
        AuctionStructure.Offer storage _offerInstance,
        AuctionStructure.paramOffer memory _params
    ) internal {
        _offerInstance.tokenId = _params.tokenId;
        if (_params.indexId.length != 0) {
            _offerInstance.nftID = _params.indexId;
        }
        _offerInstance.subOffers[_params.subOfferId].subOfferId = _params
            .subOfferId;
        _offerInstance.owner = _params.owner;
        _offerInstance.subOffers[_params.subOfferId].maker = _params.maker;
        _offerInstance.subOffers[_params.subOfferId].amount = _params.amount;
        _offerInstance.subOffers[_params.subOfferId].expirationTime = _params
            .expiTime;
        _offerInstance.subOffers[_params.subOfferId].state = AuctionStructure
            .StateOfOffer
            .ACTIVE;
        _offerInstance.subOffers[_params.subOfferId].currency = _params
            .currency;
    }

    function processCancel(
        AuctionStructure.Offer storage _offerInstance,
        bytes calldata _subOfferId
    ) internal {
        AuctionStructure.StateOfOffer stateOfOffer = _offerInstance
            .subOffers[_subOfferId]
            .state;

        require(
            stateOfOffer != AuctionStructure.StateOfOffer.CANCELLED &&
                stateOfOffer != AuctionStructure.StateOfOffer.INACTIVE,
            "AlreadyInActive"
        );
        _offerInstance.subOffers[_subOfferId].state = AuctionStructure
            .StateOfOffer
            .INACTIVE;
    }

    function findTheBestFitWinner(
        AuctionStructure.auctionStruct storage _auction
    ) internal view returns (uint256) {
        uint256 max = 0;
        uint256 winnerIndex = 0;

        for (uint256 i = 0; i < _auction.offerIds.length; ) {
            uint256 _amount = _auction
                .offers
                .subOffers[_auction.offerIds[i]]
                .amount;
            if (_amount > max) {
                max = _amount;
                winnerIndex = i;
            }
            unchecked {
                ++i;
            }
        }

        return winnerIndex;
    }

    function processChangeExpired(
        AuctionStructure.Offer storage _offerInstance,
        bytes[] calldata subOffersIdParam
    ) internal {
        for (uint256 i = 0; i < subOffersIdParam.length; ) {
            _offerInstance
                .subOffers[subOffersIdParam[i]]
                .state = AuctionStructure.StateOfOffer.CANCELLED;
            unchecked {
                ++i;
            }
        }
    }

    function getPaymentMethod(
        AuctionStructure.Currency _from,
        AuctionStructure.Currency _to
    ) internal pure returns (AuctionStructure.MethodToPayment) {
        if (
            _from == AuctionStructure.Currency.POINT &&
            _to == AuctionStructure.Currency.CRYPTO
        ) {
            return AuctionStructure.MethodToPayment.POINT_TO_CRYPTO;
        } else if (
            _from == AuctionStructure.Currency.CRYPTO &&
            _to == AuctionStructure.Currency.POINT
        ) {
            return AuctionStructure.MethodToPayment.CRYPTO_TO_POINT;
        } else if (
            _from == AuctionStructure.Currency.CRYPTO &&
            _to == AuctionStructure.Currency.CRYPTO
        ) {
            return AuctionStructure.MethodToPayment.CRYPTO_TO_CRYPTO;
        } else {
            return AuctionStructure.MethodToPayment.POINT_TO_POINT;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

library AuctionStructure {
    struct auctionStruct {
        bytes autionId;
        uint256 tokenId;
        StateOfAution state;
        address owner;
        address winner;
        bytes[] offerIds;
        Currency currency;
        Offer offers;
        mapping(bytes => uint256) offerIdToIndex;
        mapping(address => uint256) userToBidnumber;
    }

    struct Offer {
        uint256 tokenId;
        mapping(bytes => subOffer) subOffers;
        address owner;
        bytes nftID;
    }

    struct subOffer {
        bytes subOfferId;
        address maker;
        uint256 amount;
        uint256 expirationTime;
        StateOfOffer state;
        Currency currency;
    }

    struct Listing {
        bytes ListingID;
        address Owner;
        address ownerOfNFT;
        bool isAuction;
        uint256 ExpirationTime;
        uint256 Amount;
        uint256 tokenId;
        StateOfListing state;
        bytes AuctionId;
        bytes nftId;
        Currency currency;
    }

    struct stateCollection {
        bytes id;
        uint128 currentNumber;
        uint128 maxNumber;
        uint128 ratioCreatorVal;
        uint128 ratioCreatorDenomination;
        uint128 ratioStanVal;
        uint128 ratioStanDenomination;
        address owner;
        mapping(uint256 => uint256) NFT;
        mapping(address => address) currentOwnerNFT;
        mapping(uint256 => address) creator;
    }

    struct participant {
        address user;
        uint256 index;
    }

    struct paramOffer {
        bytes subOfferId;
        bytes indexId;
        uint256 tokenId;
        address owner;
        address maker;
        uint256 expiTime;
        uint256 amount;
        bool isAuction;
        Currency currency;
    }

    struct paramListing {
        bytes indexId;
        uint256 amount;
        uint256 tokenId;
        uint256 expirationTime;
        address maker;
        bytes nftId;
        Currency currency;
    }

    struct puchasing {
        address seller;
        address buyer;
        uint256 amount;
        uint256 feeStanVal;
        uint256 feeStanValDenomination;
        uint256 tokenId;
        Method method;
        MethodToPayment methodToPayment;
    }

    struct userFund {
        address maker;
        uint256 bidnumber;
    }

    struct infoOffer {
        uint256 tokenId;
        address owner;
        address maker;
        uint256 amount;
        uint256 expirationTime;
        bytes nftId;
        StateOfOffer state;
        Currency currency;
    }

    struct infoOfferAuction {
        uint256 tokenId;
        address owner;
        address maker;
        uint256 amount;
        uint256 expirationTime;
        StateOfOffer state;
        Currency currency;
    }

    struct infoAuction {
        bytes auctionId;
        uint256 tokenId;
        StateOfAution state;
        address owner;
        address winner;
        bytes[] offerIds;
        Currency currency;
    }

    struct infoCollection {
        uint256 ratioCreatorVal;
        uint256 ratioCreatorDenomination;
        uint256 ratioStanVal;
        uint256 ratioStanDenomination;
        address creator;
        address _owner;
        uint256 nft;
        address currentOwnerNFT;
    }

    struct paramReOffer {
        bytes subOfferId;
        bytes auctionId;
        uint256 amount;
    }

    struct stanFundParams {
        uint256 userStanFund;
        bool result;
    }

    struct feeStanSystem {
        uint128 ratioCreatorVal;
        uint128 ratioCreatorDenomination;
        uint128 ratioStanVal;
        uint128 ratioStanDenomination;
        uint128 ratioStanServiceFeeVal;
        uint128 ratioStanServiceFeeDenomination;
        uint256 stanFee;
        uint128 maxCollectionNumber;
    }

    struct abilityToWithdraw {
        uint256 val;
        uint256 valDenomination;
    }

    struct feeStanFixed {
        uint256 feeTransferNFTPvP;
        uint256 feeListingNFTAuction;
        uint256 feeCancelListingAuction;
        uint256 feePlaceBidAuction;
    }

    struct feeStanService {
        uint128 ratioBuyFixedPriceVal;
        uint128 ratioBuyFixedPriceDenomination;
        uint128 ratioAcceptOfferPvPVal;
        uint128 ratioAcceptOfferPvPDenomination;
        uint128 ratioAcceptOfferAuctionVal;
        uint128 ratioAcceptOfferAuctionDenomination;
        uint128 ratioFinishAuctionVal;
        uint128 ratioFinishAuctionDenomination;
        uint128 ratioCancelOfferPvPVal;
        uint128 ratioCancelOfferPvPDenomination;
    }

    enum StateOfListing {
        INACTIVE,
        ACTIVE,
        EXPIRED
    }

    enum Method {
        BUY,
        AUCTION,
        OTHER
    }

    enum Currency {
        POINT,
        CRYPTO
    }

    enum Operator {
        PLUS,
        MINUS
    }

    enum StateOfOffer {
        INACTIVE,
        ACTIVE,
        EXPIRED,
        DONE,
        CANCELLED
    }

    enum StateOfAution {
        ACTIVE,
        DONE,
        CANCEL,
        EXPIRED
    }

    enum MethodToPayment {
        POINT_TO_POINT,
        POINT_TO_CRYPTO,
        CRYPTO_TO_POINT,
        CRYPTO_TO_CRYPTO
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
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