// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "../character/ICharacter.sol";
import "../tavern/IRhum.sol";
import "../thesea/ITheTreasureSea.sol";
import "../tavern/IFlagStaking.sol";
import "../character/ICharacterMinter.sol";
import "../renting/IRenting.sol";
import "../quest/IQuest.sol";
import "./IBrothel.sol";

contract BrothelJob is VRFConsumerBaseV2, ReentrancyGuard, AccessControl {
    using SafeERC20 for IERC20;

    bytes32 public constant HUNTER_ROLE = keccak256("HUNTER_ROLE");
    VRFCoordinatorV2Interface COORDINATOR;
    uint64 s_subscriptionId;
    address vrfCoordinator = 0x7a1BaC17Ccc5b313516C5E16fb24f7659aA5ebed;
    bytes32 keyHash =
        0x4b09e658ed251bcafeebbc69400383d49f344ace09b9576fe248bb02c003fe9f;
    uint32 callbackGasLimit = 2500000;
    uint16 requestConfirmations = 3;
    uint32 numWords = 1;
    mapping(uint256 => uint256[]) internal s_requestIdToRandomWords;
    mapping(address => mapping(uint256 => uint256))
        internal requestIdToSenderAndCharacter;
    mapping(uint256 => bool) internal requestIdToReadyToHook;
    uint256 public constant jobPoints = 100;
    uint256 internal difficulty = 10;

    mapping(uint256 => address) internal requestIdToBrothelOwner;

    uint256 internal CommonPrice = 1 * 10**18;
    uint256 internal RarePrice = 2 * 10**18;
    uint256 internal MinLvlRareBrothel = 20;
    uint256 internal LegPrice = 3 * 10**18;
    uint256 internal MinLvlLegBrothel = 30;
    uint256 internal constant COMMON = 0;
    uint256 internal constant RARE = 1;
    uint256 internal constant LEGENDARY = 2;

    uint256 internal bossLevel = 10;

    IRhum internal rhum;
    IFlagStaking internal royalty;
    ICharacterMinter internal CharacterMinter;
    ICharacter internal characters;
    IRenting internal renting;
    IQuest internal quest;
    ITheTreasureSea internal theSea;
    IBrothel internal brothel;

    uint256 internal constant firstLevelCostMatic = 10 * 10**18;
    uint256 internal constant percentReduce = 12500 * 10**18;
    uint256 internal constant nextCostLevelup = 1000;
    uint256 internal MaxStakedReduce = 10000 * 10**18;
    uint256 internal constant BIG_NUM = 10**18;
    uint256 internal constant Percent = 10000;
    uint256 internal constant tenPercent = 1000;
    uint256 internal constant two = 2;
    uint256 internal constant one = 1;
    uint256 internal constant ten = 10;
    uint256 internal constant zero = 0;
    uint256 internal constant cent = 100;

    uint256 internal boostBossExp = 300;

    mapping(uint256 => CharacterInfos) internal characterinfos;
    struct CharacterInfos {
        uint256 testosterone;
        uint256 amountBonus;
        uint256 amountToHunt;
        bool gonorrhoea;
        uint256 currentHunt;
    }

    mapping(uint256 => BrothelInfos) internal brothelinfos;
    struct BrothelInfos {
        bool hasBoss;
        uint256 bossId;
        uint256 reserveRhum;
        uint256 BossExp;
        uint256 BrothelLevel;
        uint256 costNextLevelMatic;
    }

    mapping(uint256 => Pass) internal requestIdToPass;
    struct Pass {
        uint256 brothelId;
        uint256 characterId;
        address ownerOfBrothel;
        bool hasgonorrhoea;
        uint256 rarity;
        uint256 max;
        uint256 mid;
        uint256 price;
    }

    constructor(
        uint64 subscriptionId,
        address _characters,
        ITheTreasureSea _theSea,
        IFlagStaking _royalty,
        ICharacterMinter _CharacterMinter,
        IRhum _rhum,
        IRenting _renting,
        address _brothel
    ) VRFConsumerBaseV2(vrfCoordinator) {
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        s_subscriptionId = subscriptionId;
        characters = ICharacter(_characters);
        theSea = _theSea;
        rhum = _rhum;
        royalty = _royalty;
        CharacterMinter = _CharacterMinter;
        renting = _renting;
        brothel = IBrothel(_brothel);
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /////////////
    // External//
    /////////////

    function launchCommon(uint256 characterId, uint256 brothelId)
        external
        payable
        nonReentrant
    {
        require(
            msg.value >= CommonPrice * brothelinfos[brothelId].BrothelLevel,
            "Gas value too low!"
        );
        require(
            characterinfos[characterId].amountToHunt == 0,
            "Libido too low!"
        );
        require(
            characters.ownerOf(characterId) == msg.sender,
            "Not your character!"
        );
        require(
            brothelinfos[brothelId].hasBoss == true,
            "Brothel without Boss!"
        );
        require(
            brothelinfos[brothelId].reserveRhum >= 100,
            "Brothel rhum reserve empty!"
        );

        _launchCommon(characterId, brothelId, msg.sender);
    }

    function launchRare(uint256 characterId, uint256 brothelId)
        external
        payable
        nonReentrant
    {
        require(
            msg.value >= RarePrice * brothelinfos[brothelId].BrothelLevel,
            "Gas value too low!"
        );
        require(
            brothelinfos[brothelId].BrothelLevel >= MinLvlRareBrothel &&
                sqrt(brothelinfos[brothelId].BossExp) >= MinLvlRareBrothel,
            "Brothel or Boss level too low!"
        );
        require(
            sqrt(characterinfos[characterId].testosterone) < MinLvlRareBrothel,
            "Testosterone too High for this service!"
        );
        require(
            characterinfos[characterId].amountToHunt == 0,
            "Libido too low!"
        );
        require(
            characters.ownerOf(characterId) == msg.sender,
            "Not your character!"
        );
        require(
            brothelinfos[brothelId].hasBoss == true,
            "Brothel without Boss!"
        );
        require(
            brothelinfos[brothelId].reserveRhum >= 100,
            "Brothel rhum reserve empty!"
        );
        _launchRare(characterId, brothelId, msg.sender);
    }

    function launchLegendary(uint256 characterId, uint256 brothelId)
        external
        payable
        nonReentrant
    {
        require(
            msg.value >= LegPrice * brothelinfos[brothelId].BrothelLevel,
            "Gas value too low!"
        );
        require(
            brothelinfos[brothelId].BrothelLevel >= MinLvlRareBrothel &&
                sqrt(brothelinfos[brothelId].BossExp) >= MinLvlRareBrothel,
            "Brothel or Boss level too low!"
        );
        require(
            sqrt(characterinfos[characterId].testosterone) < MinLvlLegBrothel,
            "Testosterone too High for this service!"
        );
        require(
            characterinfos[characterId].amountToHunt == 0,
            "Libido too low!"
        );
        require(
            characters.ownerOf(characterId) == msg.sender,
            "Not your character!"
        );
        require(
            brothelinfos[brothelId].hasBoss == true,
            "Brothel without Boss!"
        );
        require(
            brothelinfos[brothelId].reserveRhum >= 100,
            "Brothel rhum reserve empty!"
        );

        _launchLegendary(characterId, brothelId, msg.sender);
    }

    function loadRhum(uint256 brothelId, uint256 amount) external nonReentrant {
        rhum.burnFrom(msg.sender, amount);
        brothelinfos[brothelId].reserveRhum += amount / BIG_NUM;
    }

    function updateCharacter(uint256 characterId)
        external
        nonReentrant
        onlyRole(HUNTER_ROLE)
    {
        characterinfos[characterId].amountBonus -= 1;
    }

    function addBoss(uint256 bossId, uint256 brothelId) external nonReentrant {
        ICharacter.Character memory characterInfos = characters
            .getCharacterInfos(bossId);
        require(
            characters.ownerOf(bossId) == msg.sender,
            "Not your Character!"
        );
        require(brothel.ownerOf(brothelId) == msg.sender, "Not your brothel!");
        BrothelInfos storage _brothel = brothelinfos[brothelId];

        require(_brothel.hasBoss == false, "Already with a boss!");
        require(
            sqrt(characterInfos.experience) >= bossLevel,
            "Character level too low!"
        );

        _brothel.bossId = bossId;
        _brothel.hasBoss = true;
        characters.safeTransferFrom(msg.sender, address(this), bossId);
    }

    function removeboss(uint256 brothelId) external nonReentrant {
        require(brothel.ownerOf(brothelId) == msg.sender, "Not your brothel!");
        require(
            brothelinfos[brothelId].hasBoss == true,
            "Brothel without boss!"
        );
        BrothelInfos storage _brothel = brothelinfos[brothelId];
        _brothel.hasBoss = false;

        characters.safeTransferFrom(address(this), msg.sender, _brothel.bossId);
    }

    /////////////
    // Internal//
    /////////////

    function _launchCommon(
        uint256 characterId,
        uint256 brothelId,
        address user
    ) internal {
        uint256 requestId = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
        requestIdToSenderAndCharacter[user][characterId] = requestId;
        Pass storage pass = requestIdToPass[requestId];
        pass.brothelId = brothelId;
        pass.ownerOfBrothel = brothel.ownerOf(brothelId);
        pass.characterId = characterId;
        pass.max =
            (sqrt(characterinfos[characterId].testosterone)) +
            (sqrt(brothelinfos[brothelId].BossExp)) +
            cent;
        pass.mid = two;
        pass.rarity = COMMON;
    }

    function _launchRare(
        uint256 characterId,
        uint256 brothelId,
        address user
    ) internal {
        uint256 requestId = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
        requestIdToSenderAndCharacter[user][characterId] = requestId;
        Pass storage pass = requestIdToPass[requestId];
        pass.brothelId = brothelId;
        pass.ownerOfBrothel = brothel.ownerOf(brothelId);
        pass.characterId = characterId;
        pass.max = ((sqrt(characterinfos[characterId].testosterone) * 100) +
            (sqrt(brothelinfos[brothelId].BossExp) * 100));
        pass.mid = (pass.max / cent);
        pass.rarity = RARE;
    }

    function _launchLegendary(
        uint256 characterId,
        uint256 brothelId,
        address user
    ) internal {
        uint256 requestId = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
        requestIdToSenderAndCharacter[user][characterId] = requestId;
        Pass storage pass = requestIdToPass[requestId];
        pass.brothelId = brothelId;
        pass.ownerOfBrothel = brothel.ownerOf(brothelId);
        pass.characterId = characterId;
        pass.max = ((sqrt(characterinfos[characterId].testosterone) * 100) +
            (sqrt(brothelinfos[brothelId].BossExp) * 100));
        pass.mid = (pass.max / cent);
        pass.rarity = LEGENDARY;
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords)
        internal
        override
    {
        s_requestIdToRandomWords[requestId] = randomWords;
        requestIdToReadyToHook[requestId] = true;
    }

    function _claim(uint256 characterId) internal {
        uint256 requestId = requestIdToSenderAndCharacter[msg.sender][
            characterId
        ];
        Pass storage pass = requestIdToPass[requestId];
        uint256[] memory randomWords = s_requestIdToRandomWords[requestId];
        pass.price = (randomWords[0] % pass.max);
        if (pass.price <= pass.mid) {
            pass.hasgonorrhoea = true;
        }
        if (pass.price > pass.mid) {
            pass.hasgonorrhoea = false;
        }
        characterinfos[pass.characterId].amountToHunt = 5;
        characterinfos[pass.characterId].gonorrhoea = pass.hasgonorrhoea;
        characterinfos[pass.characterId].amountBonus =
            (sqrt(brothelinfos[pass.brothelId].BossExp)) +
            boostBossExp;
        characterinfos[pass.characterId].testosterone += 1;
        characterinfos[pass.characterId].currentHunt = pass.rarity;
        brothelinfos[pass.brothelId].BossExp += 1;
        brothelinfos[pass.brothelId].reserveRhum -= 100;
    }

    function _levelupBrothel(uint256 brothelId) internal {
        if (brothelinfos[brothelId].BrothelLevel >= one) {
            require(
                msg.value >= brothelinfos[brothelId].costNextLevelMatic,
                "Value too low!"
            );
            brothelinfos[brothelId].costNextLevelMatic += (((
                brothelinfos[brothelId].costNextLevelMatic
            ) * (nextCostLevelup)) / Percent);
            brothelinfos[brothelId].BrothelLevel += one;
        } else {
            require(msg.value >= firstLevelCostMatic, "Value too low!");
            brothelinfos[brothelId].BrothelLevel = two;
            brothelinfos[brothelId].costNextLevelMatic =
                firstLevelCostMatic +
                ((firstLevelCostMatic * (nextCostLevelup)) / (Percent));
        }
    }

    function calculFeeReduction(uint256 price, address user)
        internal
        view
        returns (uint256)
    {
        uint256 userStake = royalty.addressStakedBalance(user);
        if (userStake > MaxStakedReduce) {
            userStake = MaxStakedReduce;
        }
        return (price -
            ((((userStake * BIG_NUM) / percentReduce) * price) / BIG_NUM));
    }

    function sqrt(uint256 x) internal pure returns (uint256 y) {
        uint256 z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }

    //////////
    // View //
    //////////

    function getLevelUpPrice(uint256 brothelId)
        external
        view
        returns (uint256)
    {
        uint256 price = firstLevelCostMatic;
        if (brothelinfos[brothelId].BrothelLevel >= one) {
            price = brothelinfos[brothelId].costNextLevelMatic;
        }
        return price;
    }

    function getCharacterInfos(uint256 characterId)
        external
        view
        returns (CharacterInfos memory character)
    {
        return characterinfos[characterId];
    }

    function getBrothelInfos(uint256 brothelId)
        external
        view
        returns (BrothelInfos memory brothel_)
    {
        return brothelinfos[brothelId];
    }

    function getCommonPrice() external view returns (uint256) {
        return CommonPrice;
    }

    function getRarePrice() external view returns (uint256) {
        return RarePrice;
    }

    function getLegPrice() external view returns (uint256) {
        return LegPrice;
    }

    function getMinLvlRareBrothel() external view returns (uint256) {
        return MinLvlRareBrothel;
    }

    function getMinLvlLegBrothel() external view returns (uint256) {
        return MinLvlLegBrothel;
    }

    function getbossLevel() external view returns (uint256) {
        return bossLevel;
    }

    ///////////
    // Owner //
    ///////////
    function setRarePrice(uint256 newAmount)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        RarePrice = newAmount;
    }

    function setLegendaryPrice(uint256 newAmount)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        LegPrice = newAmount;
    }

    function setMinLvlLegBrothel(uint256 newAmount)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        MinLvlLegBrothel = newAmount;
    }

    function setCommonPrice(uint256 newAmount)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        CommonPrice = newAmount;
    }

    function setbossLevel(uint256 newAmount)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        bossLevel = newAmount;
    }

    function setCharacterAddress(address _newAddress)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        characters = ICharacter(_newAddress);
    }

    function setCharacterMinter(address _CharacterMinter)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        CharacterMinter = ICharacterMinter(_CharacterMinter);
    }

    function setRenting(address _newRenting)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        renting = IRenting(_newRenting);
    }

    function setTheSea(address _newTreasureSea)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        theSea = ITheTreasureSea(_newTreasureSea);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface VRFCoordinatorV2Interface {
  /**
   * @notice Get configuration relevant for making requests
   * @return minimumRequestConfirmations global min for request confirmations
   * @return maxGasLimit global max for request gas limit
   * @return s_provingKeyHashes list of registered key hashes
   */
  function getRequestConfig()
    external
    view
    returns (
      uint16,
      uint32,
      bytes32[] memory
    );

  /**
   * @notice Request a set of random words.
   * @param keyHash - Corresponds to a particular oracle job which uses
   * that key for generating the VRF proof. Different keyHash's have different gas price
   * ceilings, so you can select a specific one to bound your maximum per request cost.
   * @param subId  - The ID of the VRF subscription. Must be funded
   * with the minimum subscription balance required for the selected keyHash.
   * @param minimumRequestConfirmations - How many blocks you'd like the
   * oracle to wait before responding to the request. See SECURITY CONSIDERATIONS
   * for why you may want to request more. The acceptable range is
   * [minimumRequestBlockConfirmations, 200].
   * @param callbackGasLimit - How much gas you'd like to receive in your
   * fulfillRandomWords callback. Note that gasleft() inside fulfillRandomWords
   * may be slightly less than this amount because of gas used calling the function
   * (argument decoding etc.), so you may need to request slightly more than you expect
   * to have inside fulfillRandomWords. The acceptable range is
   * [0, maxGasLimit]
   * @param numWords - The number of uint256 random values you'd like to receive
   * in your fulfillRandomWords callback. Note these numbers are expanded in a
   * secure way by the VRFCoordinator from a single random value supplied by the oracle.
   * @return requestId - A unique identifier of the request. Can be used to match
   * a request to a response in fulfillRandomWords.
   */
  function requestRandomWords(
    bytes32 keyHash,
    uint64 subId,
    uint16 minimumRequestConfirmations,
    uint32 callbackGasLimit,
    uint32 numWords
  ) external returns (uint256 requestId);

  /**
   * @notice Create a VRF subscription.
   * @return subId - A unique subscription id.
   * @dev You can manage the consumer set dynamically with addConsumer/removeConsumer.
   * @dev Note to fund the subscription, use transferAndCall. For example
   * @dev  LINKTOKEN.transferAndCall(
   * @dev    address(COORDINATOR),
   * @dev    amount,
   * @dev    abi.encode(subId));
   */
  function createSubscription() external returns (uint64 subId);

  /**
   * @notice Get a VRF subscription.
   * @param subId - ID of the subscription
   * @return balance - LINK balance of the subscription in juels.
   * @return reqCount - number of requests for this subscription, determines fee tier.
   * @return owner - owner of the subscription.
   * @return consumers - list of consumer address which are able to use this subscription.
   */
  function getSubscription(uint64 subId)
    external
    view
    returns (
      uint96 balance,
      uint64 reqCount,
      address owner,
      address[] memory consumers
    );

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @param newOwner - proposed new owner of the subscription
   */
  function requestSubscriptionOwnerTransfer(uint64 subId, address newOwner) external;

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @dev will revert if original owner of subId has
   * not requested that msg.sender become the new owner.
   */
  function acceptSubscriptionOwnerTransfer(uint64 subId) external;

  /**
   * @notice Add a consumer to a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - New consumer which can use the subscription
   */
  function addConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Remove a consumer from a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - Consumer to remove from the subscription
   */
  function removeConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Cancel a subscription
   * @param subId - ID of the subscription
   * @param to - Where to send the remaining LINK to
   */
  function cancelSubscription(uint64 subId, address to) external;
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
pragma solidity ^0.8.0;

/** ****************************************************************************
 * @notice Interface for contracts using VRF randomness
 * *****************************************************************************
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * @dev to Vera the verifier in such a way that Vera can be sure he's not
 * @dev making his output up to suit himself. Reggie provides Vera a public key
 * @dev to which he knows the secret key. Each time Vera provides a seed to
 * @dev Reggie, he gives back a value which is computed completely
 * @dev deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * @dev correctly computed once Reggie tells it to her, but without that proof,
 * @dev the output is indistinguishable to her from a uniform random sample
 * @dev from the output space.
 *
 * @dev The purpose of this contract is to make it easy for unrelated contracts
 * @dev to talk to Vera the verifier about the work Reggie is doing, to provide
 * @dev simple access to a verifiable source of randomness. It ensures 2 things:
 * @dev 1. The fulfillment came from the VRFCoordinator
 * @dev 2. The consumer contract implements fulfillRandomWords.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constructor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash). Create subscription, fund it
 * @dev and your consumer contract as a consumer of it (see VRFCoordinatorInterface
 * @dev subscription management functions).
 * @dev Call requestRandomWords(keyHash, subId, minimumRequestConfirmations,
 * @dev callbackGasLimit, numWords),
 * @dev see (VRFCoordinatorInterface for a description of the arguments).
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomWords method.
 *
 * @dev The randomness argument to fulfillRandomWords is a set of random words
 * @dev generated from your requestId and the blockHash of the request.
 *
 * @dev If your contract could have concurrent requests open, you can use the
 * @dev requestId returned from requestRandomWords to track which response is associated
 * @dev with which randomness request.
 * @dev See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ.
 *
 * *****************************************************************************
 * @dev SECURITY CONSIDERATIONS
 *
 * @dev A method with the ability to call your fulfillRandomness method directly
 * @dev could spoof a VRF response with any random value, so it's critical that
 * @dev it cannot be directly called by anything other than this base contract
 * @dev (specifically, by the VRFConsumerBase.rawFulfillRandomness method).
 *
 * @dev For your users to trust that your contract's random behavior is free
 * @dev from malicious interference, it's best if you can write it so that all
 * @dev behaviors implied by a VRF response are executed *during* your
 * @dev fulfillRandomness method. If your contract must store the response (or
 * @dev anything derived from it) and use it later, you must ensure that any
 * @dev user-significant behavior which depends on that stored value cannot be
 * @dev manipulated by a subsequent VRF request.
 *
 * @dev Similarly, both miners and the VRF oracle itself have some influence
 * @dev over the order in which VRF responses appear on the blockchain, so if
 * @dev your contract could have multiple VRF requests in flight simultaneously,
 * @dev you must ensure that the order in which the VRF responses arrive cannot
 * @dev be used to manipulate your contract's user-significant behavior.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request. It is for this reason that
 * @dev that you can signal to an oracle you'd like them to wait longer before
 * @dev responding to the request (however this is not enforced in the contract
 * @dev and so remains effective only in the case of unmodified oracle software).
 */
abstract contract VRFConsumerBaseV2 {
  error OnlyCoordinatorCanFulfill(address have, address want);
  address private immutable vrfCoordinator;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   */
  constructor(address _vrfCoordinator) {
    vrfCoordinator = _vrfCoordinator;
  }

  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBaseV2 expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomWords the VRF output expanded to the requested number of words
   */
  function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal virtual;

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomWords(uint256 requestId, uint256[] memory randomWords) external {
    if (msg.sender != vrfCoordinator) {
      revert OnlyCoordinatorCanFulfill(msg.sender, vrfCoordinator);
    }
    fulfillRandomWords(requestId, randomWords);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
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
        IERC20 token,
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
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
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
        IERC20Permit token,
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
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
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
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

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
abstract contract AccessControl is Context, IAccessControl, ERC165 {
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
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
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
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
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
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface ICharacter {
    struct Character {
        uint32 boarding;
        uint32 sailing;
        uint32 charisma;
        uint64 experience;
        uint64 specialisation;
        uint32 thirst;
        uint256 tokenId;
    }

    //View functions
    function addTreasuryHuntResult(
        uint256 tokenId,
        uint32 amountHunt,
        uint64 exp
    ) external;

    function generateCharacter(
        uint256 class,
        address user,
        uint32 numberOfmints
    ) external;

    function getCharacterInfos(uint256 tokenId)
        external
        view
        returns (Character memory characterInfos);

    function getLevelMax() external view returns (uint256);

    function getNumberOfCharacters() external view returns (uint256);

    function getCharacterTotalStats(uint256 tokenId)
        external
        view
        returns (
            uint32 boarding,
            uint32 sailing,
            uint32 charisma
        );

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function balanceOf(address owner) external view returns (uint256 balance);

    function tokenOfOwnerByIndex(address owner, uint256 index)
        external
        view
        returns (uint256);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);

    function setApprovalForAll(address operator, bool _approved) external;

    function burn(uint256 tokenId) external;
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

interface IRhum {
    function mint(address to, uint amount) external;

    function burnFrom(address account, uint amount) external;

    function burn(uint amount) external;

    function fetchHalving() external view returns (uint256);
    
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
    function transfer(address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.7;

interface ITheTreasureSea {
    function mintTreasureMap(
        address user,
        uint256 amount,
        uint256 rarity
    ) external;

    function burn(
        address from,
        uint256 id,
        uint256 value
    ) external;

    function setApprovalForAll(address operator, bool approved) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IFlagStaking {
    // --------- UTILITY FUNCTIONS ------------
    function isStaker(address _address) external view returns (bool);

    // ----------- STAKING ACTIONS ------------
    function createStake(uint _amount) external;

    function removeStake(uint _amount) external;

    // Backup function in case something happens with the update rewards functions
    function emergencyUnstake(uint _amount) external;

    // ------------ REWARD ACTIONS ---------------
    function getRewards() external;

    function updateAddressRewardsBalance(address _address)
        external
        returns (uint);

    function updateBigRewardsPerToken() external;

    function userPendingRewards(address _address) external view returns (uint);

    // ------------ ADMIN ACTIONS ---------------
    function withdrawRewards(uint _amount) external;

    function depositRewards(uint _amount) external;

    function setDailyEmissions(uint _amount) external;

    function pause() external;

    function unpause() external;

    // ------------ VIEW FUNCTIONS ---------------
    function timeSinceLastReward() external view returns (uint);

    function rewardsBalance() external view returns (uint);

    function addressStakedBalance(address _address)
        external
        view
        returns (uint);

    function showStakingToken() external view returns (address);

    function showRewardToken() external view returns (address);

    function showBigRewardsPerToken() external view returns (uint);

    function showBigUserRewardsCollected() external view returns (uint);

    function showLockTimeRemaining(address _address)
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface ICharacterMinter {
    function mintTicket(address user, uint256 specialisation) external;
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.7;

interface IRenting {
    struct Rent {
        address owner;
        address renter;
        bool isRenting;
        uint256 percentToRenter;
        uint256 amountRhumOwner;
        uint256 amountRhumRenter;
    }

    function calculRewardToShare(uint256 amount, uint256 share)
        external
        pure
        returns (uint256);

    function getRentData(uint256 tokenId)
        external
        view
        returns (Rent memory rent);
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.7;

interface IQuest {
    function addQuest(
        uint256 rarity,
        uint256 characterId,
        address user
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IBrothel {
    //View functions

    function ownerOf(uint256 tokenId) external view returns (address owner);
    function balanceOf(address owner) external view returns (uint256 balance);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);

    function setApprovalForAll(address operator, bool _approved) external;

    function burn(uint256 tokenId) external;
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
interface IERC20Permit {
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
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
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