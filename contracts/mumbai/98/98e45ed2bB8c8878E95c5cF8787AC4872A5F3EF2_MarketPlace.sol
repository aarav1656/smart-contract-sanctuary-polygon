// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Interfaces.sol";

// contract for sell NFTs or make offer to NFTs owner
// UPDATE AUDIT : change block by timestamp
// + store end of offer timestamp, not the creating timestamp of offer
contract MarketPlace is Ownable {
    IERC20 immutable BZAI;

    struct OfferDatas {
        address nftOwner;
        address offeredBy;
        address nftAddress;
        uint256 nftId;
        uint256 price;
        uint256 bidValue;
        uint256 offerEndAt;
    }

    uint256 public offerDuration; // in day

    uint256 public offersCount;
    mapping(uint256 => OfferDatas) _offers;
    // UPDATE AUDIT : link NFT to offerId
    mapping(address => mapping(uint256 => uint256)) _nftOfferId;

    IAddresses public gameAddresses;

    event GameAddressesSetted(address gameAddresses);
    event NftSold(
        address indexed nftAddress,
        uint256 offerId,
        uint256 indexed nftId,
        uint256 price,
        address pastOwner,
        address newOwner
    );
    event NftBid(
        address indexed nftAddress,
        address indexed owner,
        address indexed bider,
        uint256 offerId,
        uint256 nftId,
        uint256 price
    );
    event NftInSale(
        address indexed nftAddress,
        address indexed owner,
        uint256 offerId,
        uint256 indexed nftId,
        uint256 price
    );
    event NftOfferRefused(
        address indexed owner,
        address indexed bider,
        address nftAddress,
        uint256 offerId,
        uint256 indexed nftId,
        uint256 price
    );

    event OfferDurationUpdated(uint256 oldDuration, uint256 newDuration);

    constructor(IERC20 _bzai) {
        BZAI = _bzai;
        offerDuration = 3;
    }

    function setGameAddresses(address _address) external onlyOwner {
        require(
            address(gameAddresses) == address(0x0),
            "game addresses already setted"
        );
        gameAddresses = IAddresses(_address);
        emit GameAddressesSetted(_address);
    }

    function updateOfferDuration(uint256 _offerDuration) external onlyOwner {
        uint256 oldDuration = offerDuration;
        offerDuration = _offerDuration;
        emit OfferDurationUpdated(oldDuration, _offerDuration);
    }

    function getOffer(uint256 _offerId)
        external
        view
        returns (OfferDatas memory)
    {
        return _offers[_offerId];
    }

    function sellNft(
        address _nftAddress,
        uint256 _nftId,
        uint256 _askedPrice
    ) external {
        IERC721 I = IERC721(_nftAddress);
        require(I.ownerOf(_nftId) == msg.sender, "Not your NFT");
        require(
            I.getApproved(_nftId) == address(this),
            "Need to approve the NFT"
        );
        // UPDATE AUDIT : Not possible to create multiple sale offer for the same NFT
        require(
            _nftOfferId[_nftAddress][_nftId] == 0 ||
                block.timestamp >=
                _offers[_nftOfferId[_nftAddress][_nftId]].offerEndAt,
            "There already is a selling offer for this NFT"
        );
        ++offersCount;
        // UPDATE AUDIT : store Id of offer to NFT
        _nftOfferId[_nftAddress][_nftId] = offersCount;

        OfferDatas storage offer = _offers[offersCount];
        offer.nftAddress = _nftAddress;
        offer.nftId = _nftId;
        offer.nftOwner = msg.sender;
        offer.offerEndAt = block.timestamp + (offerDuration * 1 days);
        offer.price = _askedPrice;

        emit NftInSale(
            _nftAddress,
            msg.sender,
            offersCount,
            _nftId,
            _askedPrice
        );
    }

    function cancelMySell(uint256 _offerId) external {
        require(_offers[_offerId].nftOwner == msg.sender, "Not your sale");
        delete _offers[_offerId];
    }

    function bidForNft(
        address _nftAddress,
        uint256 _nftId,
        uint256 _bidPrice
    ) external {
        require(
            IERC721(_nftAddress).ownerOf(_nftId) != msg.sender,
            "You can't bid on your own NFT"
        );
        address payment = gameAddresses.getAddressOf(
            AddressesInit.Addresses.PAYMENTS
        );
        uint256 _balance = IPayments(payment).getMyReward(msg.sender) +
            IPayments(payment).getMyCentersRevenues(msg.sender);
        if (_balance < _bidPrice) {
            require(
                BZAI.allowance(msg.sender, payment) >= _bidPrice - _balance,
                "You need to approve contract"
            );
            require(
                BZAI.balanceOf(msg.sender) >= _bidPrice - _balance,
                "You don't have enough BZAI"
            );
        }

        ++offersCount;
        OfferDatas storage offer = _offers[offersCount];
        offer.nftAddress = _nftAddress;
        offer.offeredBy = msg.sender;
        offer.nftId = _nftId;
        offer.nftOwner = IERC721(_nftAddress).ownerOf(_nftId);
        offer.offerEndAt = block.timestamp + (offerDuration * 1 days);
        offer.bidValue = _bidPrice;

        emit NftBid(
            _nftAddress,
            offer.nftOwner,
            msg.sender,
            offersCount,
            _nftId,
            _bidPrice
        );
    }

    function refuseOffer(uint256 _offerId) external {
        OfferDatas memory offer = _offers[_offerId];
        require(offer.nftOwner == msg.sender, "not your NFT");

        delete _offers[_offerId];

        emit NftOfferRefused(
            offer.nftOwner,
            offer.offeredBy,
            offer.nftAddress,
            _offerId,
            offer.nftId,
            offer.price
        );
    }

    function cancelMyBid(uint256 _offerId) external {
        require(_offers[_offerId].offeredBy == msg.sender, "Not your offer");
        delete _offers[_offerId];
    }

    function acceptBid(uint256 _offerId) external {
        OfferDatas memory offer = _offers[_offerId];
        require(offer.nftOwner == msg.sender, "not your NFT");
        address payments = gameAddresses.getAddressOf(
            AddressesInit.Addresses.PAYMENTS
        );
        IPayments IPay = IPayments(payments);

        require(
            block.timestamp <= offer.offerEndAt,
            string(
                abi.encodePacked("Offers only avalaible", offerDuration, "days")
            )
        );

        delete _offers[_offerId];

        require(
            IPay.payWithRewardOrWallet(offer.offeredBy, offer.bidValue),
            "bidder hasn't enough founds"
        );
        IPay.payNFTOwner(msg.sender, offer.bidValue);

        IERC721(offer.nftAddress).transferFrom(
            msg.sender,
            offer.offeredBy,
            offer.nftId
        );

        emit NftSold(
            offer.nftAddress,
            _offerId,
            offer.nftId,
            offer.bidValue,
            msg.sender,
            offer.offeredBy
        );
    }

    function buyNft(uint256 _offerId) external {
        OfferDatas memory offer = _offers[_offerId];
        require(
            offer.nftOwner == IERC721(offer.nftAddress).ownerOf(offer.nftId),
            "owner change offer not available"
        );
        require(
            block.timestamp <= offer.offerEndAt,
            string(
                abi.encodePacked("Offers only avalaible", offerDuration, "days")
            )
        );

        IPayments IPay = IPayments(
            gameAddresses.getAddressOf(AddressesInit.Addresses.PAYMENTS)
        );
        require(IPay.payWithRewardOrWallet(msg.sender, offer.price));

        IPay.payNFTOwner(offer.nftOwner, offer.price);

        address _from = offer.nftOwner;
        uint256 _tokenId = offer.nftId;
        delete _offers[_offerId];

        // UPDATE AUDIT : Authorize new owner to create a sale offer for this NFT
        _nftOfferId[offer.nftAddress][offer.nftId] = 0;

        IERC721(offer.nftAddress).transferFrom(_from, msg.sender, _tokenId);

        emit NftSold(
            offer.nftAddress,
            _offerId,
            offer.nftId,
            offer.price,
            offer.nftOwner,
            msg.sender
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

library ZaiStruct {
    // Zai powers
    struct Powers {
        uint8 water;
        uint8 fire;
        uint8 metal;
        uint8 air;
        uint8 stone;
    }

    // A zai can work in a center , training or coaching. He can't fight if he isn't free
    //string[4] _status = ["Free","Training","Coaching","Working"];
    // UPDATE AUDIT : add spotId
    struct Activity {
        uint8 statusId;
        uint8 onSpotId;
        uint16 onCenter;
    }

    struct ZaiMetaData {
        uint8 state; // _states index
        uint8 seasonOf;
        uint32 ipfsPathId;
        bool isGod;
    }

    struct Zai {
        uint8 level;
        uint8 creditForUpgrade; // credit to use to raise powers
        uint16 manaMax;
        uint16 mana;
        uint32 xp;
        Powers powers;
        Activity activity;
        ZaiMetaData metadata;
        string name;
    }

    struct ZaiMinDatasForFight {
        uint8 level;
        uint8 state;
        uint8 statusId;
        uint8 water;
        uint8 fire;
        uint8 metal;
        uint8 air;
        uint8 stone;
    }

    struct EggsPrices {
        uint256 bronzePrice;
        uint256 silverPrice;
        uint256 goldPrice;
        uint256 platinumPrice;
    }

    struct MintedData {
        uint256 bronzeMinted;
        uint256 silverMinted;
        uint256 goldMinted;
        uint256 platinumMinted;
    }

    struct WorkInstance {
        uint256 zaiId;
        uint256 beginingAt;
    }

    struct DelegateData {
        address scholarAddress;
        address ownerAddress;
        uint8 percentageForScholar;
        uint16 contractDuration;
        uint32 contractEnd;
        uint32 lastScholarPlayed;
        bool renewable;
    }

    struct GuildeDatas {
        address renterOf;
        address masterOf;
        address platformAddress;
        uint8 percentageForScholar;
        uint8 percentageForGuilde;
        uint8 percentagePlatformFees;
    }

    struct ScholarDatas {
        GuildeDatas guildeDatas;
        DelegateData delegateDatas;
    }
}

library PotionStruct {
    struct Powers {
        uint8 water;
        uint8 fire;
        uint8 metal;
        uint8 air;
        uint8 stone;
        uint8 rest;
        uint8 xp;
        uint8 mana;
    }

    struct Potion {
        address seller;
        uint256 listingPrice;
        uint256 fromLab;
        uint256 potionId;
        uint256 saleTimestamp;
        uint8 potionType; // 0: water ; 1: fire ; 2:metal ; 3:air ; 4:stone  ; 5:rest ; 6:xp ; 7:multiple ; 99 : empty
        Powers powers;
    }
}

library LaboStruct {
    struct WorkInstance {
        uint256 zaiId;
        uint256 beginingAt;
    }

    struct LabDetails {
        uint256 revenues;
        uint256 employees;
        uint256 potionsCredits;
        uint256 numberOfSpots;
        WorkInstance[10] workingSpot;
    }
}

library AddressesInit {
    enum Addresses {
        ALCHEMY,
        BZAI_TOKEN,
        CHICKEN,
        CLAIM_NFTS,
        DELEGATE,
        EGGS_NFT,
        FIGHT,
        FIGHT_PVP,
        IPFS_STORAGE,
        LABO_MANAGEMENT,
        LABO_NFT,
        LEVEL_STORAGE,
        LOOT,
        MARKET_PLACE,
        MARKET_DUTCH_AUCTION_ZAI,
        NURSERY_MANAGEMENT,
        NURSERY_NFT,
        OPEN_AND_CLOSE,
        ORACLE,
        PAYMENTS,
        POTIONS_NFT,
        PVP_GAME,
        RANKING,
        RENT_MY_NFT,
        REWARDS_PVP,
        REWARDS_WINNING_PVE,
        REWARDS_RANKING,
        TRAINING_MANAGEMENT,
        TRAINING_NFT,
        ZAI_META,
        ZAI_NFT
    }

    //     ALCHEMY, 0
    //     BZAI_TOKEN, 1
    //     CHICKEN, 2
    //     CLAIM_NFTS, 3
    //     DELEGATE, 4
    //     EGGS_NFT, 5
    //     FIGHT, 6
    //     FIGHT_PVP, 7
    //     IPFS_STORAGE, 8
    //     LABO_MANAGEMENT, 9
    //     LABO_NFT, 10
    //     LEVEL_STORAGE, 11
    //     LOOT, 12
    //     MARKET_PLACE, 13
    //     MARKET_DUTCH_AUCTION_ZAI, 14
    //     NURSERY_MANAGEMENT, 15
    //     NURSERY_NFT, 16
    //     OPEN_AND_CLOSE, 17
    //     ORACLE, 18
    //     PAYMENTS, 19
    //     POTIONS_NFT, 20
    //     PVP_GAME, 21
    //     RANKING, 22
    //     RENT_MY_NFT, 23
    //     REWARDS_PVP, 24
    //     REWARDS_WINNING_PVE, 25
    //     REWARDS_RANKING, 26
    //     TRAINING_MANAGEMENT, 27
    //     TRAINING_NFT, 28
    //     ZAI_META, 29
    //     ZAI_NFT, 30
}

interface IAddresses {
    function isAuthToManagedNFTs(address _address) external view returns (bool);

    function isAuthToManagedPayments(address _address)
        external
        view
        returns (bool);

    function getAddressOf(AddressesInit.Addresses _contract)
        external
        view
        returns (address);
}

interface IBZAI is IERC20 {
    function burn(uint256 _amount) external returns (bool);
}

interface IChicken is IERC721 {
    function mintChicken(address _to) external returns (uint256);
}

interface IDelegate {
    function gotDelegationForZai(uint256 _zaiId)
        external
        view
        returns (ZaiStruct.ScholarDatas memory scholarDatas);

    function canUseZai(uint256 _zaiId, address _user)
        external
        view
        returns (bool);

    function getDelegateDatasByZai(uint256 _zaiId)
        external
        view
        returns (ZaiStruct.DelegateData memory);

    function isZaiDelegated(uint256 _zaiId) external view returns (bool);

    function updateLastScholarPlayed(uint256 _zaiId) external returns (bool);

    function updateInterfaces() external;
}

interface IEggs is IERC721 {
    function mintEgg(
        address _to,
        uint256 _state,
        uint256 _maturityDuration
    ) external returns (uint256);
}

interface IFighting {
    function updateInterfaces() external;
}

interface IFightingLibrary {
    function updateFightingProgress(
        uint256[30] memory _toReturn,
        uint256[9] calldata _elements,
        uint256[9] calldata _powers
    ) external pure returns (uint256[30] memory);

    function getUsedPowersByElement(
        uint256[9] calldata _elements,
        uint256[9] calldata _powers
    ) external pure returns (uint256[5] memory);

    function isPowersUsedCorrect(
        uint8[5] calldata _got,
        uint256[5] calldata _used
    ) external pure returns (bool);

    function getNewPattern(
        uint256 _random,
        ZaiStruct.ZaiMinDatasForFight memory c,
        uint256[30] memory _toReturn
    ) external pure returns (uint256[30] memory result);
}

interface IGuildeDelegation {
    function getRentingDatas(address _nftAddress, uint256 _tokenId)
        external
        view
        returns (ZaiStruct.GuildeDatas memory);
}

interface IipfsIdStorage {
    function getTokenURI(
        uint256 _season,
        uint256 _state,
        uint256 _id
    ) external view returns (string memory);

    function getNextIpfsId(uint256 _state, uint256 _nftId)
        external
        returns (uint256);

    function getCurrentSeason() external view returns (uint8);

    function updateInterfaces() external;
}

interface ILaboratory is IERC721 {
    function mintLaboratory(address _to) external returns (uint256);

    function burn(uint256 _tokenId) external;

    function getCreditLastUpdate(uint256 _tokenId)
        external
        view
        returns (uint256);

    function updateCreditLastUpdate(uint256 _tokenId) external returns (bool);

    function numberOfWorkingSpots(uint256 _tokenId)
        external
        view
        returns (uint256);

    function updateNumberOfWorkingSpots(uint256 _tokenId, uint256 _quantity)
        external
        returns (bool);

    function getPreMintNumber() external view returns (uint256);

    function updateInterfaces() external;
}

interface ILabManagement {
    function initSpotsNumber(uint256 _tokenId) external returns (bool);

    function cleanSlotsBeforeClosing(uint256 _laboId) external returns (bool);

    function updateInterfaces() external;
}

interface ILevelStorage {
    function addFighter(uint256 _level, uint256 _zaiId) external returns (bool);

    function removeFighter(uint256 _level, uint256 _zaiId)
        external
        returns (bool);

    function getLevelLength(uint256 _level) external view returns (uint256);

    function getRandomZaiFromLevel(
        uint256 _level,
        uint256 _idForbiden,
        uint256 _random
    ) external view returns (uint256);

    function updateInterfaces() external;
}

interface ILootProgress {
    // UPDATE AUDIT : update interface
    function updateUserProgress(address _user)
        external
        returns (uint256 beginingDay);

    function updateInterfaces() external;
}

interface IMarket {
    function updateInterfaces() external;
}

interface INurseryNFT is IERC721 {
    function getPreMintNumber() external view returns (uint256);
}

interface INurseryManagement {
    function getEggsPrices(uint256 _nursId)
        external
        view
        returns (ZaiStruct.EggsPrices memory);

    function updateInterfaces() external;
}

interface IOpenAndClose {
    function getLaboCreatingTime(uint256 _tokenId)
        external
        view
        returns (uint256);

    function canLaboSell(uint256 _tokenId) external view returns (bool);

    function canTrain(uint256 _tokenId) external view returns (bool);

    function updateInterfaces() external;
}

interface IOracle {
    function getRandom() external returns (uint256);
}

interface IPayments {
    function payOwner(address _owner, uint256 _value) external returns (bool);

    function getMyReward(address _user) external view returns (uint256);

    function distributeFees(uint256 _amount) external returns (bool);

    function rewardPlayer(
        address _user,
        uint256 _amount,
        uint256 _zaiId,
        uint256 _state
    ) external returns (bool);

    function getMyCentersRevenues(address _user)
        external
        view
        returns (uint256);

    function burnRevenuesForEggs(address _owner, uint256 _amount)
        external
        returns (bool);

    function payNFTOwner(address _owner, uint256 _amount)
        external
        returns (bool);

    function payWithRewardOrWallet(address _user, uint256 _amount)
        external
        returns (bool);
}

interface IPotions is IERC721 {
    function mintPotionForSale(
        uint256 _laboId,
        uint256 _price,
        uint256 _type,
        uint256 _power,
        uint256 _quantity
    ) external returns (uint256[] memory);

    function offerPotion(
        uint256 _type,
        uint256 _power,
        address _to
    ) external returns (uint256);

    function burnPotion(uint256 _tokenId) external returns (bool);

    function emptyingPotion(uint256 _tokenId) external returns (bool);

    function mintMultiplePotion(uint256[7] memory _powers, address _owner)
        external
        returns (uint256);

    function changePotionPrice(
        uint256 _tokenId,
        uint256 _laboId,
        uint256 _price
    ) external returns (bool);

    function updatePotionSaleTimestamp(uint256 _tokenId)
        external
        returns (bool);

    function getFullPotion(uint256 _tokenId)
        external
        view
        returns (PotionStruct.Potion memory);

    function getPotionPowers(uint256 _tokenId)
        external
        view
        returns (PotionStruct.Powers memory);

    function updateInterfaces() external;
}

interface IRanking {
    function updatePlayerRankings(address _user, uint256 _xpWin)
        external
        returns (bool);

    function getDayBegining() external view returns (uint256);

    function getDayAndWeekRankingCounter()
        external
        view
        returns (uint256 dayNumber, uint256 weekNumber);

    function updateInterfaces() external;
}

interface IReserveForChalengeRewards {
    function updateRewards() external returns (bool, uint256);
}

interface IReserveForWinRewards {
    function updateRewards() external returns (bool, uint256);
}

interface IRewardsPvP {
    function updateInterfaces() external;
}

interface IRewardsRankingFound {
    function getDailyRewards(address _rewardStoringAddress)
        external
        returns (uint256);

    function getWeeklyRewards(address _rewardStoringAddress)
        external
        returns (uint256);

    function updateInterfaces() external;
}

interface IRewardsWinningFound {
    function getWinningRewards(uint256 level, bool bonus)
        external
        returns (uint256);

    function updateInterfaces() external;
}

interface ITraining is IERC721 {
    function mintTrainingCenter(address _to) external returns (uint256);

    function burn(uint256 _tokenId) external;

    function numberOfTrainingSpots(uint256 _tokenId)
        external
        view
        returns (uint256);

    function addTrainingSpots(uint256 _tokenId, uint256 _amount)
        external
        returns (bool);

    function getPreMintNumber() external view returns (uint256);

    function updateInterfaces() external;
}

interface ITrainingManagement {
    function initSpotsNumber(uint256 _tokenId) external returns (bool);

    function cleanSlotsBeforeClosing(uint256 _laboId) external returns (bool);

    function updateInterfaces() external;
}

interface IZaiNFT is IERC721 {
    function mintZai(
        address _to,
        string memory _name,
        uint256 _state
    ) external returns (uint256);

    function createNewChallenger() external returns (uint256);

    function burnZai(uint256 _tokenId) external returns (bool);
}

interface IZaiMeta {
    function getZaiURI(uint256 tokenId) external view returns (string memory);

    function createZaiDatas(
        uint256 _newItemId,
        string memory _name,
        uint256 _state,
        uint256 _level
    ) external;

    function getZai(uint256 _tokenId)
        external
        view
        returns (ZaiStruct.Zai memory);

    function getZaiMinDatasForFight(uint256 _tokenId)
        external
        view
        returns (ZaiStruct.ZaiMinDatasForFight memory zaiMinDatas);

    function isFree(uint256 _tokenId) external view returns (bool);

    function updateStatus(
        uint256 _tokenId,
        uint256 _newStatusID,
        uint256 _center,
        uint256 _spotId
    ) external;

    function updateXp(uint256 _id, uint256 _xp)
        external
        returns (uint256 level);

    function updateMana(
        uint256 _tokenId,
        uint256 _manaUp,
        uint256 _manaDown,
        uint256 _maxUp
    ) external returns (bool);

    function getNextLevelUpPoints(uint256 _level)
        external
        view
        returns (uint256);

    function updateInterfaces() external;
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

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
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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