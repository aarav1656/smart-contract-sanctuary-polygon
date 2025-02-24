// SPDX-License-Identifier: MIT

/*
 ______     __                            __           __                      __
|_   _ \   [  |                          |  ]         [  |                    |  ]
  | |_) |   | |    .--.     .--.     .--.| |   .--.    | |--.    .---.    .--.| |
  |  __'.   | |  / .'`\ \ / .'`\ \ / /'`\' |  ( (`\]   | .-. |  / /__\\ / /'`\' |
 _| |__) |  | |  | \__. | | \__. | | \__/  |   `'.'.   | | | |  | \__., | \__/  |
|_______/  [___]  '.__.'   '.__.'   '.__.;__] [\__) ) [___]|__]  '.__.'  '.__.;__]
                      ________
                      ___  __ )_____ ______ _________________
                      __  __  |_  _ \_  __ `/__  ___/__  ___/
                      _  /_/ / /  __// /_/ / _  /    _(__  )
                      /_____/  \___/ \__,_/  /_/     /____/
*/

pragma solidity ^0.8.10;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "../shared/chainlink/VRFConsumerBaseUpgradeable.sol";
import "../storage/interface/IBSBStorage.sol";
import "../storage/interface/IBSBTypes.sol";
import "../storage/interface/IBSBMintPassBuff.sol";
import "../../collections/child/interface/IBSBBloodToken.sol";
import "../../collections/child/interface/IERC721Child.sol";
import "../../collections/child/interface/IBSBBloodShard.sol";
import "./BSBBaseUpgradeable.sol";

contract BSBFactoryUpgradeable is Initializable, OwnableUpgradeable, IBSBTypes, BSBBaseUpgradeable, VRFConsumerBaseUpgradeable {

    struct ImpactType {
        uint reRollSuccessBoostPercentage;
    }

    uint[] public levelMilestones;
    mapping(uint => ImpactType) public levelImpacts;

    // VRF
    uint private vrfFee;
    bytes32 private vrfKeyHash;
    uint private seed;

    IBSBStorage BSBStorageCaller;
    IBSBBloodShard BSBBloodShardCaller;
    IBSBBloodToken BSBBloodTokenCaller;

    mapping(string => address) public contracts;

    uint public baseWinChance;
    uint public reRollChanceIncreasePerBurn;
    uint public gen1ReRollStartingPrice;
    uint public reRollWinPercentageCap;
    uint public reRollLevelIncreasePercentage;
    uint public perTokenTaxIncrement;
    uint public gen1ElitesPercentageCap;
    uint public bloodShardTokenId;

    mapping(uint => uint) public treeHouseLevelBloodTokenCostsMapping;
    mapping(uint => uint) public treeHouseLevelBloodShardCostsMapping;

    mapping(uint => uint) public gen1BonusPercentages;
    mapping(uint => uint) public gen1ReRollAdditionalTax;

    uint public perTokenLevelTaxIncrement;

    event SeedFulfilled();
    event HouseMerge(uint[] houseIds_, uint resultingId_, uint resultingLevel_);
    event ReRoll(uint[] tokenIds_, uint resultingTokenId_, uint amount_, bool isSuccessful);

    function __BSBFactory_init(
        address vrfCoordinatorAddr_,
        address linkTokenAddr_,
        bytes32 vrfKeyHash_,
        uint vrfFee_
    ) public initializer {
        __BSBBase_init();
        __VRFConsumerBase_init(vrfCoordinatorAddr_, linkTokenAddr_);
        vrfKeyHash = vrfKeyHash_;
        vrfFee = vrfFee_;

        baseWinChance = 3;
        reRollChanceIncreasePerBurn = 2;
        bloodShardTokenId = 0;
        gen1ReRollStartingPrice = 20000;
        reRollWinPercentageCap = 50;
        reRollLevelIncreasePercentage = 50;
        perTokenTaxIncrement = 10000;
        gen1ElitesPercentageCap = 10;
    }

    function mergeTreeHouses(uint[] calldata housesIds_) external whenNotPaused {
        IERC721Child ERC721Caller =  IERC721Child(contracts["treeHouse"]);

        require(housesIds_.length == 2, "FAC:1");
        require(ERC721Caller.ownerOf(housesIds_[0]) == _msgSender(), "FAC:2");
        require(ERC721Caller.ownerOf(housesIds_[1]) == _msgSender(), "FAC:3");

        TreeHouseStats[] memory treeHousesStats_ = BSBStorageCaller.getTreeHousesStats(housesIds_);

        uint treeHouseToBeUpgradedIndex_ = treeHousesStats_[0].size.value > treeHousesStats_[1].size.value ? 0 : 1;
        uint resultingSize_ = treeHousesStats_[treeHouseToBeUpgradedIndex_].size.value + 1;
        require(resultingSize_ <= treeHousesStats_[treeHouseToBeUpgradedIndex_].size.max, "FAC:4");
        treeHousesStats_[treeHouseToBeUpgradedIndex_].size.value = resultingSize_;

        _spendTreeHouseMergingCosts(resultingSize_);

        BSBStorageCaller.setTreeHouseStats(
            housesIds_[treeHouseToBeUpgradedIndex_],
            treeHousesStats_[treeHouseToBeUpgradedIndex_]
        );

        _burnTreeHouse(housesIds_[1 - treeHouseToBeUpgradedIndex_]);

        emit HouseMerge(
            housesIds_,
            housesIds_[treeHouseToBeUpgradedIndex_],
            treeHousesStats_[treeHouseToBeUpgradedIndex_].size.value
        );

        delete resultingSize_;
        delete treeHouseToBeUpgradedIndex_;
    }

    function reRoll(uint toBeUpgradedTokenId_, uint[] calldata gen1Tokens_) external whenNotPaused {
        address gen1Address_ = contracts["gen1"];

        require(IERC721Child(gen1Address_).ownerOf(toBeUpgradedTokenId_) == _msgSender(), "FAC:5");

        for (uint i = 0; i < gen1Tokens_.length; ++i) {
            require(IERC721Child(gen1Address_).ownerOf(gen1Tokens_[i]) == _msgSender(), "FAC:6");
        }

        _runReRoll(toBeUpgradedTokenId_, gen1Tokens_);

        delete gen1Address_;
    }

    function getTreeHouseStats(uint[] calldata housesIds_) external view returns (uint, uint, uint) {
        require(housesIds_.length == 2, "FAC:12");
        TreeHouseStats[] memory treeHousesStats_ = BSBStorageCaller.getTreeHousesStats(housesIds_);
        uint treeHouseToBeUpgradedIndex_ = treeHousesStats_[0].size.value > treeHousesStats_[1].size.value ? 0 : 1;
        uint resultingSize_ = treeHousesStats_[treeHouseToBeUpgradedIndex_].size.value + 1;
        return (
            housesIds_[treeHouseToBeUpgradedIndex_],
            treeHouseLevelBloodTokenCostsMapping[resultingSize_],
            treeHouseLevelBloodShardCostsMapping[resultingSize_]
        );
    }

    function getReRollStats(uint toBeUpgradedTokenId_, uint[] calldata gen1Tokens_) view external returns (uint, uint) {
        BearStats memory bearStats_ = BSBStorageCaller.getBearStats(contracts["gen1"], toBeUpgradedTokenId_);
        (
        uint levelSum,
        uint currentAdditionalSuccessPercentage_,
        uint currentAdditionalTax_,
        uint totalSuccessPercentage_,
        uint reRollPrice_
        ) = _calculateReRollStats(
            toBeUpgradedTokenId_,
            bearStats_.level.value,
            gen1Tokens_
        );

        delete levelSum;
        delete currentAdditionalSuccessPercentage_;
        delete currentAdditionalTax_;
        delete bearStats_;

        return (totalSuccessPercentage_, reRollPrice_);
    }

    function setBSBStorageCaller(address address_) external onlyOwner {
        BSBStorageCaller = IBSBStorage(address_);
    }

    function setBSBBloodTokenCaller(address address_) external onlyOwner {
        BSBBloodTokenCaller = IBSBBloodToken(address_);
    }

    function setBSBBloodShardCaller(address address_) external onlyOwner {
        BSBBloodShardCaller = IBSBBloodShard(address_);
    }

    function setContractAddresses(string[] calldata aliases_, address[] calldata addresses_) external onlyOwner {
        for (uint i = 0; i < aliases_.length; ++i) {
            contracts[aliases_[i]] = addresses_[i];
        }
    }

    function setBaseWinChance(uint amount_) external onlyOwner {
        baseWinChance = amount_;
    }

    function setReRollChanceIncreasePerBurn(uint amount_) external onlyOwner {
        reRollChanceIncreasePerBurn = amount_;
    }

    function setBloodShardTokenId(uint id_) external onlyOwner {
        bloodShardTokenId = id_;
    }

    function setTreeHouseLevelCosts(
        uint[] calldata levels_,
        uint[] calldata bloodTokenCosts_,
        uint[] calldata bloodShardCosts_
    ) external onlyOwner {
        require(levels_.length == bloodTokenCosts_.length && levels_.length == bloodShardCosts_.length, "FAC:7");

        for (uint i = 0; i < levels_.length; ++i) {
            treeHouseLevelBloodTokenCostsMapping[levels_[i]] = bloodTokenCosts_[i];
            treeHouseLevelBloodShardCostsMapping[levels_[i]] = bloodShardCosts_[i];
        }
    }

    function setGen1ReRollStartingPrice(uint amount_) external onlyOwner {
        gen1ReRollStartingPrice = amount_;
    }

    function setReRollWinPercentageCap(uint amount_) external onlyOwner {
        reRollWinPercentageCap = amount_;
    }

    function setReRollLevelIncreasePercentage(uint amount_) external onlyOwner {
        reRollLevelIncreasePercentage = amount_;
    }

    function setPerTokenTaxIncrement(uint amount_) external onlyOwner {
        perTokenTaxIncrement = amount_;
    }

    function setPerTokenLevelTaxIncrement(uint amount_) external onlyOwner {
        perTokenLevelTaxIncrement = amount_;
    }

    function setGen1ElitesPercentageCap(uint amount_) external onlyOwner {
        gen1ElitesPercentageCap = amount_;
    }

    function setLevelImpacts(uint[] memory milestones_, ImpactType[] calldata impacts_) external onlyOwner {

        require(milestones_.length == impacts_.length, "FAC:8");

        levelMilestones = milestones_;

        for (uint i = 0; i < milestones_.length; i++) {
            ImpactType storage levelImpact = levelImpacts[milestones_[i]];
            levelImpact.reRollSuccessBoostPercentage = impacts_[i].reRollSuccessBoostPercentage;
        }
    }

    function initSeedGeneration() public onlyOwner returns (bytes32 requestId) {
        require(LINK.balanceOf(address(this)) >= vrfFee, "FAC:9");
        return requestRandomness(vrfKeyHash, vrfFee);
    }

    function _runReRoll(
        uint toBeUpgradedTokenId_,
        uint[] memory gen1Tokens_
    ) internal {
        require(gen1Tokens_.length >= 1, "FAC:10");

        address gen1Address_ = contracts["gen1"];
        BearStats memory toBeUpgradedBearStats_ = BSBStorageCaller.getBearStats(gen1Address_, toBeUpgradedTokenId_);
        require(!toBeUpgradedBearStats_.isElite, "FAC:11");

        (
            uint levelSum,
            uint currentAdditionalSuccessPercentage_,
            uint currentAdditionalTax_,
            uint totalSuccessPercentage_,
            uint reRollPrice_
        ) = _calculateReRollStats(
            toBeUpgradedTokenId_,
            toBeUpgradedBearStats_.level.value,
            gen1Tokens_
        );

        bool isReRollSuccessful = _isReRollSuccessful(totalSuccessPercentage_, toBeUpgradedTokenId_, currentAdditionalSuccessPercentage_);
        if (isReRollSuccessful) {
            toBeUpgradedBearStats_.isElite = true;
        } else {
            gen1BonusPercentages[toBeUpgradedTokenId_] += currentAdditionalSuccessPercentage_;
            gen1ReRollAdditionalTax[toBeUpgradedTokenId_] += currentAdditionalTax_;

            uint resultingLevel_ = toBeUpgradedBearStats_.level.value + levelSum * reRollLevelIncreasePercentage / 100;
            toBeUpgradedBearStats_.level.value = resultingLevel_ <= toBeUpgradedBearStats_.level.max ?
            resultingLevel_ : toBeUpgradedBearStats_.level.max;
            delete resultingLevel_;
        }

        BSBStorageCaller.setBearStats(gen1Address_, toBeUpgradedTokenId_, toBeUpgradedBearStats_);
        BSBBloodTokenCaller.spend(reRollPrice_ * ETHER, _msgSender());
        _burnGen1Tokens(gen1Tokens_);

        emit ReRoll(gen1Tokens_, toBeUpgradedTokenId_, reRollPrice_, isReRollSuccessful);

        delete levelSum;
        delete currentAdditionalSuccessPercentage_;
        delete currentAdditionalTax_;
        delete totalSuccessPercentage_;
        delete reRollPrice_;
        delete toBeUpgradedBearStats_;
        delete gen1Address_;
    }

    function _calculateReRollStats(
        uint toBeUpgradedTokenId_,
        uint toBeUpgradedTokenLevel_,
        uint[] memory gen1Tokens_
    ) internal view returns (uint, uint, uint, uint, uint) {
        BearStats[] memory bearStats_ = BSBStorageCaller.getBearsStats(contracts["gen1"], gen1Tokens_);
        uint levelSum;
        for (uint i = 0; i < bearStats_.length; ++i) {
            levelSum += bearStats_[i].level.value;
        }
        uint currentAdditionalSuccessPercentage_ = _getLevelImpact(levelSum).reRollSuccessBoostPercentage + (gen1Tokens_.length - 1) * reRollChanceIncreasePerBurn;
        uint totalSuccessPercentage_ = _calculateTotalReRollSuccessPercentage(toBeUpgradedTokenId_, currentAdditionalSuccessPercentage_);
        uint currentAdditionalTax_ = _calculateAdditionalTax(gen1Tokens_);
        uint totalPrice_ = _calculatePrice(toBeUpgradedTokenId_, toBeUpgradedTokenLevel_, currentAdditionalTax_);

        return (levelSum, currentAdditionalSuccessPercentage_, currentAdditionalTax_,  totalSuccessPercentage_, totalPrice_);
    }

    function _spendTreeHouseMergingCosts(uint houseLevel_) internal {
        if(treeHouseLevelBloodTokenCostsMapping[houseLevel_] > 0) {
            BSBBloodTokenCaller.spend(treeHouseLevelBloodTokenCostsMapping[houseLevel_] * ETHER, _msgSender());
        }
        if(treeHouseLevelBloodShardCostsMapping[houseLevel_] > 0) {
            BSBBloodShardCaller.burn(bloodShardTokenId, treeHouseLevelBloodShardCostsMapping[houseLevel_], _msgSender());
        }
    }

    function _burnTreeHouse(uint id_) internal {
        uint[] memory idsToBurn = new uint[](1);
        idsToBurn[0] = id_;
        IERC721Child(contracts["treeHouse"]).burn(idsToBurn, _msgSender());
        delete idsToBurn;
    }

    function _calculateTotalReRollSuccessPercentage(uint tokenId_, uint winChance_) internal view returns(uint) {
        if(_getGen1ElitePercentage() >= gen1ElitesPercentageCap) {
            return 0;
        }

        uint totalWinChance_ = winChance_ + gen1BonusPercentages[tokenId_] + baseWinChance;

        totalWinChance_ = totalWinChance_ > reRollWinPercentageCap ? reRollWinPercentageCap : totalWinChance_;

        return totalWinChance_;
    }

    function _getGen1ElitePercentage() internal view returns (uint) {
        address gen1Address_ = contracts["gen1"];
        uint gen1Supply = IERC721Child(gen1Address_).totalSupply();
        uint gen1Elites = BSBStorageCaller.elitesCount(gen1Address_);
        return gen1Elites / gen1Supply;
    }

    function _calculatePrice(uint tokenId_, uint tokenLevel_, uint additionalTax_) internal view returns(uint) {
        return gen1ReRollStartingPrice + gen1ReRollAdditionalTax[tokenId_] + additionalTax_ + tokenLevel_ * perTokenLevelTaxIncrement;
    }

    function _calculateAdditionalTax(uint[] memory tokenIds_) internal view returns(uint) {
        return perTokenTaxIncrement * tokenIds_.length;
    }

    function _isReRollSuccessful(uint portion_, uint tokenId_, uint amount_) internal view returns(bool) {
        return uint(
            keccak256(
                abi.encodePacked(
                    seed,
                    tokenId_,
                    amount_,
                    tx.origin,
                    blockhash(block.number - 1),
                    block.timestamp)
            )
        ) % 100 < portion_;
    }

    function _burnGen1Tokens(uint[] memory genTokens_) internal {
        IERC721Child(contracts["gen1"]).burn(genTokens_, _msgSender());
    }

    function _getLevelImpact(uint level_) internal view returns (ImpactType memory) {
        for (uint i = 0; i < levelMilestones.length; ++i) {
            if (level_ >= levelMilestones[levelMilestones.length - 1 - i]) {
                return levelImpacts[levelMilestones[levelMilestones.length - 1 - i]];
            }
        }

        return levelImpacts[0];
    }

    function fulfillRandomness(bytes32, uint randomness) internal override {
        seed = randomness;
        emit SeedFulfilled();
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
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
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./VRFRequestIDBase.sol";
import "./LinkTokenInterface.sol";

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
 * @dev simple access to a verifiable source of randomness.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constructor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator, _link) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash), and have told you the minimum LINK
 * @dev price for VRF service. Make sure your contract has sufficient LINK, and
 * @dev call requestRandomness(keyHash, fee, seed), where seed is the input you
 * @dev want to generate randomness from.
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomness method.
 *
 * @dev The randomness argument to fulfillRandomness is the actual random value
 * @dev generated from your seed.
 *
 * @dev The requestId argument is generated from the keyHash and the seed by
 * @dev makeRequestId(keyHash, seed). If your contract could have concurrent
 * @dev requests open, you can use the requestId to track which seed is
 * @dev associated with which randomness. See VRFRequestIDBase.sol for more
 * @dev details. (See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.)
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ. (Which is critical to making unpredictable randomness! See the
 * @dev next section.)
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
 * @dev Since the ultimate input to the VRF is mixed with the block hash of the
 * @dev block in which the request is made, user-provided seeds have no impact
 * @dev on its economic security properties. They are only included for API
 * @dev compatability with previous versions of this contract.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request.
 */
abstract contract VRFConsumerBaseUpgradeable is Initializable, VRFRequestIDBase {
    /**
     * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBase expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomness the VRF output
   */
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal virtual;

    /**
     * @dev In order to keep backwards compatibility we have kept the user
   * seed field around. We remove the use of it because given that the blockhash
   * enters later, it overrides whatever randomness the used seed provides.
   * Given that it adds no security, and can easily lead to misunderstandings,
   * we have removed it from usage and can now provide a simpler API.
   */
    uint256 private constant USER_SEED_PLACEHOLDER = 0;

    /**
     * @notice requestRandomness initiates a request for VRF output given _seed
   *
   * @dev The fulfillRandomness method receives the output, once it's provided
   * @dev by the Oracle, and verified by the vrfCoordinator.
   *
   * @dev The _keyHash must already be registered with the VRFCoordinator, and
   * @dev the _fee must exceed the fee specified during registration of the
   * @dev _keyHash.
   *
   * @dev The _seed parameter is vestigial, and is kept only for API
   * @dev compatibility with older versions. It can't *hurt* to mix in some of
   * @dev your own randomness, here, but it's not necessary because the VRF
   * @dev oracle will mix the hash of the block containing your request into the
   * @dev VRF seed it ultimately uses.
   *
   * @param _keyHash ID of public key against which randomness is generated
   * @param _fee The amount of LINK to send with the request
   *
   * @return requestId unique ID for this request
   *
   * @dev The returned requestId can be used to distinguish responses to
   * @dev concurrent requests. It is passed as the first argument to
   * @dev fulfillRandomness.
   */
    function requestRandomness(bytes32 _keyHash, uint256 _fee) internal returns (bytes32 requestId) {
        LINK.transferAndCall(vrfCoordinator, _fee, abi.encode(_keyHash, USER_SEED_PLACEHOLDER));
        // This is the seed passed to VRFCoordinator. The oracle will mix this with
        // the hash of the block containing this request to obtain the seed/input
        // which is finally passed to the VRF cryptographic machinery.
        uint256 vRFSeed = makeVRFInputSeed(_keyHash, USER_SEED_PLACEHOLDER, address(this), nonces[_keyHash]);
        // nonces[_keyHash] must stay in sync with
        // VRFCoordinator.nonces[_keyHash][this], which was incremented by the above
        // successful LINK.transferAndCall (in VRFCoordinator.randomnessRequest).
        // This provides protection against the user repeating their input seed,
        // which would result in a predictable/duplicate output, if multiple such
        // requests appeared in the same block.
        nonces[_keyHash] = nonces[_keyHash] + 1;
        return makeRequestId(_keyHash, vRFSeed);
    }

    LinkTokenInterface internal LINK;
    address private vrfCoordinator;

    // Nonces for each VRF key from which randomness has been requested.
    //
    // Must stay in sync with VRFCoordinator[_keyHash][this]
    mapping(bytes32 => uint256) /* keyHash */ /* nonce */
    private nonces;

    /**
     * @param _vrfCoordinator address of VRFCoordinator contract
   * @param _link address of LINK token contract
   *
   * @dev https://docs.chain.link/docs/link-token-contracts
   */

    function __VRFConsumerBase_init(address _vrfCoordinator, address _link) internal onlyInitializing {
        vrfCoordinator = _vrfCoordinator;
        LINK = LinkTokenInterface(_link);
    }


    // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
    // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
    // the origin of the call
    function rawFulfillRandomness(bytes32 requestId, uint256 randomness) external {
        require(msg.sender == vrfCoordinator, "Only VRFCoordinator can fulfill");
        fulfillRandomness(requestId, randomness);
    }
}

// SPDX-License-Identifier: MIT

/*
 ______     __                            __           __                      __
|_   _ \   [  |                          |  ]         [  |                    |  ]
  | |_) |   | |    .--.     .--.     .--.| |   .--.    | |--.    .---.    .--.| |
  |  __'.   | |  / .'`\ \ / .'`\ \ / /'`\' |  ( (`\]   | .-. |  / /__\\ / /'`\' |
 _| |__) |  | |  | \__. | | \__. | | \__/  |   `'.'.   | | | |  | \__., | \__/  |
|_______/  [___]  '.__.'   '.__.'   '.__.;__] [\__) ) [___]|__]  '.__.'  '.__.;__]
                      ________
                      ___  __ )_____ ______ _________________
                      __  __  |_  _ \_  __ `/__  ___/__  ___/
                      _  /_/ / /  __// /_/ / _  /    _(__  )
                      /_____/  \___/ \__,_/  /_/     /____/
*/

pragma solidity ^0.8.0;

import "./IBSBTypes.sol";

interface IBSBStorage is IBSBTypes {

    // BEARS

    // GETTERS
    function getBearsStats(address, uint[] calldata) external view returns(BearStats[] memory);

    function getBearStats(address, uint) external view returns(BearStats memory);

    // SETTERS

    function setBearStats(address, uint, BearStats calldata) external;

    function setBearsStats(address, uint[] calldata, BearStats[] calldata) external;

    // TREEHOUSE

    function setTreeHouseStats(uint, TreeHouseStats calldata) external;

    function getTreeHouseStats(uint) external view returns(TreeHouseStats memory);

    function setTreeHousesStats(uint[] calldata, TreeHouseStats[] calldata) external;

    function getTreeHousesStats(uint[] calldata) external view returns(TreeHouseStats[] memory);


    function stakeAssets(CollectionItems[] calldata, address) external;

    function unStakeAssets(CollectionItems[] calldata, address) external;

    function elitesCount(address) external view returns(uint);

    function isAssetStakedInMode(address, address, uint) external view returns(bool);

    function getOwnerOfERC721Token(address, uint) external view returns (address);

}

// SPDX-License-Identifier: MIT

/*
 ______     __                            __           __                      __
|_   _ \   [  |                          |  ]         [  |                    |  ]
  | |_) |   | |    .--.     .--.     .--.| |   .--.    | |--.    .---.    .--.| |
  |  __'.   | |  / .'`\ \ / .'`\ \ / /'`\' |  ( (`\]   | .-. |  / /__\\ / /'`\' |
 _| |__) |  | |  | \__. | | \__. | | \__/  |   `'.'.   | | | |  | \__., | \__/  |
|_______/  [___]  '.__.'   '.__.'   '.__.;__] [\__) ) [___]|__]  '.__.'  '.__.;__]
                      ________
                      ___  __ )_____ ______ _________________
                      __  __  |_  _ \_  __ `/__  ___/__  ___/
                      _  /_/ / /  __// /_/ / _  /    _(__  )
                      /_____/  \___/ \__,_/  /_/     /____/
*/

pragma solidity ^0.8.10;

interface IBSBTypes {

    struct Stat {
        uint256 min;
        uint256 max;
        uint256 value;
    }

    struct BearStats {
        bool isLegendary;
        bool isElite;
        uint256 faction;
        Stat stamina;
        Stat offense;
        Stat defense;
        Stat level;
        Stat leadership;
    }

    struct TreeHouseStats {
        Stat size;
        Stat defense;
    }

    struct CollectionItems {
        address collection;
        uint256[] assets;
    }
}

// SPDX-License-Identifier: MIT

/*
 ______     __                            __           __                      __
|_   _ \   [  |                          |  ]         [  |                    |  ]
  | |_) |   | |    .--.     .--.     .--.| |   .--.    | |--.    .---.    .--.| |
  |  __'.   | |  / .'`\ \ / .'`\ \ / /'`\' |  ( (`\]   | .-. |  / /__\\ / /'`\' |
 _| |__) |  | |  | \__. | | \__. | | \__/  |   `'.'.   | | | |  | \__., | \__/  |
|_______/  [___]  '.__.'   '.__.'   '.__.;__] [\__) ) [___]|__]  '.__.'  '.__.;__]
                      ________
                      ___  __ )_____ ______ _________________
                      __  __  |_  _ \_  __ `/__  ___/__  ___/
                      _  /_/ / /  __// /_/ / _  /    _(__  )
                      /_____/  \___/ \__,_/  /_/     /____/
*/

pragma solidity ^0.8.10;

interface IBSBMintPassBuff {
    function getBuffBalance(address) external view returns(uint256);
}

// SPDX-License-Identifier: MIT

/*
 ______     __                            __           __                      __
|_   _ \   [  |                          |  ]         [  |                    |  ]
  | |_) |   | |    .--.     .--.     .--.| |   .--.    | |--.    .---.    .--.| |
  |  __'.   | |  / .'`\ \ / .'`\ \ / /'`\' |  ( (`\]   | .-. |  / /__\\ / /'`\' |
 _| |__) |  | |  | \__. | | \__. | | \__/  |   `'.'.   | | | |  | \__., | \__/  |
|_______/  [___]  '.__.'   '.__.'   '.__.;__] [\__) ) [___]|__]  '.__.'  '.__.;__]
                      ________
                      ___  __ )_____ ______ _________________
                      __  __  |_  _ \_  __ `/__  ___/__  ___/
                      _  /_/ / /  __// /_/ / _  /    _(__  )
                      /_____/  \___/ \__,_/  /_/     /____/
*/

pragma solidity ^0.8.10;

interface IBSBBloodToken {
    function spend(
        uint256 amount,
        address sender
    ) external;

    function spend(
        uint256 amount,
        address sender,
        address recipient,
        address redirectAddress,
        uint256 redirectPercentage,
        uint256 burnPercentage
    ) external;

    function mint(address user, uint256 amount) external;
}

// SPDX-License-Identifier: MIT

/*
 ______     __                            __           __                      __
|_   _ \   [  |                          |  ]         [  |                    |  ]
  | |_) |   | |    .--.     .--.     .--.| |   .--.    | |--.    .---.    .--.| |
  |  __'.   | |  / .'`\ \ / .'`\ \ / /'`\' |  ( (`\]   | .-. |  / /__\\ / /'`\' |
 _| |__) |  | |  | \__. | | \__. | | \__/  |   `'.'.   | | | |  | \__., | \__/  |
|_______/  [___]  '.__.'   '.__.'   '.__.;__] [\__) ) [___]|__]  '.__.'  '.__.;__]
                      ________
                      ___  __ )_____ ______ _________________
                      __  __  |_  _ \_  __ `/__  ___/__  ___/
                      _  /_/ / /  __// /_/ / _  /    _(__  )
                      /_____/  \___/ \__,_/  /_/     /____/
*/

pragma solidity ^0.8.10;

import './IERC721.sol';

interface IERC721Child is IERC721 {
    function burn(uint256[] calldata tokenIds_, address wallet) external;

    function tokensOfOwner(address owner) external view returns (uint256[] memory);

    function totalSupply() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

interface IBSBBloodShard {
    function mint(
        address account,
        uint256 amount,
        bytes calldata data
    ) external;

    function burn(uint256 id, uint256 amount, address wallet) external;
}

// SPDX-License-Identifier: MIT

/*
 ______     __                            __           __                      __
|_   _ \   [  |                          |  ]         [  |                    |  ]
  | |_) |   | |    .--.     .--.     .--.| |   .--.    | |--.    .---.    .--.| |
  |  __'.   | |  / .'`\ \ / .'`\ \ / /'`\' |  ( (`\]   | .-. |  / /__\\ / /'`\' |
 _| |__) |  | |  | \__. | | \__. | | \__/  |   `'.'.   | | | |  | \__., | \__/  |
|_______/  [___]  '.__.'   '.__.'   '.__.;__] [\__) ) [___]|__]  '.__.'  '.__.;__]
                      ________
                      ___  __ )_____ ______ _________________
                      __  __  |_  _ \_  __ `/__  ___/__  ___/
                      _  /_/ / /  __// /_/ / _  /    _(__  )
                      /_____/  \___/ \__,_/  /_/     /____/
*/

pragma solidity ^0.8.10;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

contract BSBBaseUpgradeable is Initializable, OwnableUpgradeable, PausableUpgradeable {
    
    modifier onlyAuthorised {
        require(owner() == _msgSender() || authorizedContracts[_msgSender()], "BASE:1");
        _;
    }

    uint256 constant public DAYS = 1 days;
    uint256 constant public ETHER = 1 ether;

    mapping(address => bool) public authorizedContracts;

    function __BSBBase_init() internal initializer {
        __Ownable_init();
        __Pausable_init();
    }

    function setContractsStatuses(
        address[] calldata addresses_, 
        bool[] calldata statuses_
    ) external onlyOwner {
        for (uint256 i = 0; i < addresses_.length; ++i) {
            authorizedContracts[addresses_[i]] = statuses_[i];
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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
pragma solidity ^0.8.0;

contract VRFRequestIDBase {
    /**
     * @notice returns the seed which is actually input to the VRF coordinator
   *
   * @dev To prevent repetition of VRF output due to repetition of the
   * @dev user-supplied seed, that seed is combined in a hash with the
   * @dev user-specific nonce, and the address of the consuming contract. The
   * @dev risk of repetition is mostly mitigated by inclusion of a blockhash in
   * @dev the final seed, but the nonce does protect against repetition in
   * @dev requests which are included in a single block.
   *
   * @param _userSeed VRF seed input provided by user
   * @param _requester Address of the requesting contract
   * @param _nonce User-specific nonce at the time of the request
   */
    function makeVRFInputSeed(
        bytes32 _keyHash,
        uint256 _userSeed,
        address _requester,
        uint256 _nonce
    ) internal pure returns (uint256) {
        return uint256(keccak256(abi.encode(_keyHash, _userSeed, _requester, _nonce)));
    }

    /**
     * @notice Returns the id for this request
   * @param _keyHash The serviceAgreement ID to be used for this request
   * @param _vRFInputSeed The seed to be passed directly to the VRF
   * @return The id for this request
   *
   * @dev Note that _vRFInputSeed is not the seed passed by the consuming
   * @dev contract, but the one generated by makeVRFInputSeed
   */
    function makeRequestId(bytes32 _keyHash, uint256 _vRFInputSeed) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_keyHash, _vRFInputSeed));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface LinkTokenInterface {
    function allowance(address owner, address spender) external view returns (uint256 remaining);

    function approve(address spender, uint256 value) external returns (bool success);

    function balanceOf(address owner) external view returns (uint256 balance);

    function decimals() external view returns (uint8 decimalPlaces);

    function decreaseApproval(address spender, uint256 addedValue) external returns (bool success);

    function increaseApproval(address spender, uint256 subtractedValue) external;

    function name() external view returns (string memory tokenName);

    function symbol() external view returns (string memory tokenSymbol);

    function totalSupply() external view returns (uint256 totalTokensIssued);

    function transfer(address to, uint256 value) external returns (bool success);

    function transferAndCall(
        address to,
        uint256 value,
        bytes calldata data
    ) external returns (bool success);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool success);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

interface IERC721 {
    /**
     * @dev Emitted when `tokenId` token is transfered from `from` to `to`.
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
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
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
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
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
        require(paused(), "Pausable: not paused");
        _;
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}