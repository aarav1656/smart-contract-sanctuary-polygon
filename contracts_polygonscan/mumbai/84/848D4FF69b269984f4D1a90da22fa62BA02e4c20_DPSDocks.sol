//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./../interfaces/IERC20MintableBurnable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "./interfaces/DPSStructs.sol";
import "./interfaces/DPSInterfaces.sol";

contract DPSDocks is ERC721Holder, ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;

    DPSVoyageI public voyage;
    DPSRandomI public causality;
    IERC721 public dps;
    DPSPirateFeaturesI public dpsFeatures;
    DPSFlagshipI public flagship;
    DPSSupportShipI public supportShip;
    IERC721 public artifact;
    DPSCartographerI public cartographer;
    DPSGameSettingsI public gameSettings;
    DPSChestsI public chest;

    /**
     * @notice list of voyages started by wallet
     */
    mapping(address => mapping(uint256 => LockedVoyage)) private lockedVoyages;

    /**
     * @notice list of voyages finished by wallet
     */
    mapping(address => mapping(uint256 => LockedVoyage)) private finishedVoyages;

    /**
     * @notice list of voyages ids started by wallet
     */
    mapping(address => uint256[]) private lockedVoyagesIds;

    /**
     * @notice list of voyages ids finished by wallet
     */
    mapping(address => uint256[]) private finishedVoyagesIds;

    /**
     * @notice finished voyages results voyageId=>results
     */
    mapping(uint256 => VoyageResult) private voyageResults;

    /**
     * @notice list of locked voyages and their owners id => wallet
     */
    mapping(uint256 => address) private ownerOfLockedVoyages;

    event LockVoyage(
        uint256 indexed _voyageId,
        uint256 indexed _dpsId,
        uint256 indexed _flagshipId,
        uint256[] _supportShipIds,
        uint256 _artifactId
    );

    event ClaimVoyageRewards(
        uint256 indexed _voyageId,
        uint16 _noOfChests,
        uint16 _destroyedSupportships,
        uint16 _healthDamage,
        uint16[] _interactionRNGs,
        uint8[] _interactionResults
    );
    event SetContract(string indexed _target, address _contract);
    event TokenRecovered(address indexed _token, address _destination, uint256 _amount);

    constructor() {}

    /**
     * @notice Locking a voyage
     * @param _lockedVoyage object that contains:
     * - voyageId
     * - dpsId (Pirate)
     * - flagshipId
     * - supportShipIds - list of support ships ids
     * - artifactId
     * the rest of the params are ignored
     */
    function lockVoyageItems(LockedVoyage memory _lockedVoyage) external nonReentrant {
        require(gameSettings.isPaused(1) == 0, "Paused");
        require(_lockedVoyage.voyageId > 0, "Invalid Voyage");
        require(voyage.ownerOf(_lockedVoyage.voyageId) == msg.sender, "You don't owe this voyage");
        require(dps.ownerOf(_lockedVoyage.dpsId) == msg.sender, "You don't owe this dps");

        require(flagship.ownerOf(_lockedVoyage.flagshipId) == msg.sender, "You don't owe this flagship");
        require(flagship.getPartsLevel(_lockedVoyage.flagshipId)[uint256(FLAGSHIP_PART.HEALTH)] == 100, "Flagship damaged");

        require(lockedVoyages[msg.sender][_lockedVoyage.voyageId].voyageId == 0, "This Voyage is already started");
        require(finishedVoyages[msg.sender][_lockedVoyage.voyageId].voyageId == 0, "This Voyage is finished");
        if (_lockedVoyage.supportShipIds.length > 0) {
            for (uint256 i; i < _lockedVoyage.supportShipIds.length; i++) {
                require(supportShip.ownerOf(_lockedVoyage.supportShipIds[i]) == msg.sender, "Support ship not owned by you");
            }
        }
        VoyageConfig memory voyageConfig = voyage.getVoyageConfig(_lockedVoyage.voyageId);
        require(
            block.number > voyageConfig.boughtAt + voyageConfig.noOfBlockJumps * voyageConfig.noOfInteractions + 2,
            "Voyage generation not done"
        );

        _lockedVoyage.lockedBlock = block.number;
        _lockedVoyage.lockedTimestamp = block.timestamp;
        _lockedVoyage.claimedTime = 0;
        _lockedVoyage.claimedTime = 0;
        _lockedVoyage.navigation = 0;
        _lockedVoyage.luck = 0;
        _lockedVoyage.strength = 0;
        lockedVoyages[msg.sender][_lockedVoyage.voyageId] = _lockedVoyage;
        lockedVoyagesIds[msg.sender].push(_lockedVoyage.voyageId);
        ownerOfLockedVoyages[_lockedVoyage.voyageId] = msg.sender;

        dps.safeTransferFrom(msg.sender, address(this), _lockedVoyage.dpsId);
        flagship.safeTransferFrom(msg.sender, address(this), _lockedVoyage.flagshipId);

        for (uint256 i; i < _lockedVoyage.supportShipIds.length; i++) {
            supportShip.safeTransferFrom(msg.sender, address(this), _lockedVoyage.supportShipIds[i]);
        }

        voyage.safeTransferFrom(msg.sender, address(this), _lockedVoyage.voyageId);
        emit LockVoyage(
            _lockedVoyage.voyageId,
            _lockedVoyage.dpsId,
            _lockedVoyage.flagshipId,
            _lockedVoyage.supportShipIds,
            _lockedVoyage.artifactId
        );
    }

    /**
     * @notice Claiming rewards with params retrieved from the random future blocks
     * @param _voyageId - id of the voyage
     * @param _causalityParams - list of parameters used to generated random outcomes
     */
    function claimRewards(uint256 _voyageId, CausalityParams memory _causalityParams) external nonReentrant {
        _causalityParams.userAddress = getLockedVoyageOwner(_voyageId);
        require(_causalityParams.userAddress != address(0), "Voyage does not exists");

        LockedVoyage storage lockedVoyage = lockedVoyages[_causalityParams.userAddress][_voyageId];
        require(voyage.ownerOf(_voyageId) == address(this) && lockedVoyage.voyageId != 0, "Voyage not started");

        VoyageConfig memory voyageConfig = cartographer.viewVoyageConfiguration(_causalityParams, _voyageId);

        require(
            lockedVoyage.lockedTimestamp + voyageConfig.noOfInteractions * voyageConfig.gapBetweenInteractions <=
                block.timestamp,
            "Voyage not finished"
        );

        require(
            block.number > lockedVoyage.lockedBlock + voyageConfig.noOfInteractions * voyageConfig.noOfBlockJumps,
            "Voyage can't be finished, needs more blocks"
        );

        require(
            _causalityParams.blockNumber.length > 0 &&
                _causalityParams.blockNumber.length == _causalityParams.signature.length,
            "Causality params are incorrect"
        );
        checkCausalityParams(_causalityParams, voyageConfig, lockedVoyage);

        VoyageResult memory voyageResult = computeVoyageState(lockedVoyage, voyageConfig, _causalityParams);
        lockedVoyage.claimedTime = block.timestamp;
        finishedVoyages[_causalityParams.userAddress][lockedVoyage.voyageId] = lockedVoyage;
        finishedVoyagesIds[_causalityParams.userAddress].push(lockedVoyage.voyageId);
        voyageResults[_voyageId] = voyageResult;
        awardRewards(voyageResult, voyageConfig.typeOfVoyage, lockedVoyage, _causalityParams.userAddress);
        cleanLockedVoyage(lockedVoyage.voyageId, _causalityParams.userAddress);

        emit ClaimVoyageRewards(
            _voyageId,
            voyageResult.awardedChests,
            voyageResult.destroyedSupportShips,
            voyageResult.healthDamage,
            voyageResult.interactionRNGs,
            voyageResult.interactionResults
        );
    }

    /**
     * @notice checking voyage state between start start and finish sail, it uses causality parameters to determine the outcome of interactions
     * @param _voyageId - id of the voyage
     * @param _causalityParams - list of parameters used to generated random outcomes, it can be an incomplete list, meaning that you can check mid-sail to determine outcomes
     */
    function checkVoyageState(uint256 _voyageId, CausalityParams memory _causalityParams)
        external
        view
        returns (VoyageResult memory voyageResult)
    {
        _causalityParams.userAddress = getLockedVoyageOwner(_voyageId);
        LockedVoyage storage lockedVoyage = lockedVoyages[_causalityParams.userAddress][_voyageId];

        require(voyage.ownerOf(_voyageId) == address(this) && lockedVoyage.voyageId != 0, "Voyage not started");

        VoyageConfig memory voyageConfig = cartographer.viewVoyageConfiguration(_causalityParams, _voyageId);
        require(
            (block.timestamp - lockedVoyage.lockedTimestamp) > voyageConfig.gapBetweenInteractions,
            "Voyage did not start"
        );

        uint256 interactions = (block.timestamp - lockedVoyage.lockedTimestamp) / voyageConfig.gapBetweenInteractions;
        if (interactions > voyageConfig.sequence.length) interactions = voyageConfig.sequence.length;
        uint256 length = voyageConfig.sequence.length;
        for (uint256 i; i < length - interactions; i++) {
            voyageConfig.sequence[length - i - 1] = 0;
        }
        return computeVoyageState(lockedVoyage, voyageConfig, _causalityParams);
    }

    /**
     * @notice computing voyage state based on the locked voyage skills and config and causality params
     * @param _lockedVoyage - locked voyage items
     * @param _voyageConfig - voyage config object
     * @param _causalityParams - list of parameters used to generated random outcomes, it can be an incomplete list, meaning that you can check mid-sail to determine outcomes
     * @return VoyageResult - containing the results of a voyage based on interactions
     */
    function computeVoyageState(
        LockedVoyage storage _lockedVoyage,
        VoyageConfig memory _voyageConfig,
        CausalityParams memory _causalityParams
    ) internal view returns (VoyageResult memory) {
        VoyageStatusCache memory claimingRewardsCache;
        claimingRewardsCache.randomCheckIndex = _voyageConfig.noOfInteractions + 2 - 1;
        (, uint16[3] memory features) = dpsFeatures.getTraitsAndSkills(uint16(_lockedVoyage.dpsId));

        require(features[0] > 0 && features[1] > 0 && features[2] > 0, "Traits not found");

        claimingRewardsCache.luck += features[0];
        claimingRewardsCache.navigation += features[1];
        claimingRewardsCache.strength += features[2];
        claimingRewardsCache = computeFlagShipSkills(_lockedVoyage.flagshipId, claimingRewardsCache);
        claimingRewardsCache = computeSupportShipSkills(_lockedVoyage.supportShipIds, claimingRewardsCache);
        VoyageResult memory voyageResult;
        uint256 maxRollCap = gameSettings.getMaxRollCap();
        voyageResult.interactionResults = new uint8[](_voyageConfig.sequence.length);
        voyageResult.interactionRNGs = new uint16[](_voyageConfig.sequence.length);
        for (uint256 i; i < _voyageConfig.sequence.length; i++) {
            INTERACTION interaction = INTERACTION(_voyageConfig.sequence[i]);
            if (interaction == INTERACTION.NONE || voyageResult.healthDamage == 100) {
                voyageResult.skippedInteractions++;
                continue;
            }

            claimingRewardsCache.randomCheckIndex++;

            uint256 result;
            if (_causalityParams.signature.length > 0) {
                result = causality.getRandom(
                    _causalityParams.userAddress,
                    _causalityParams.blockNumber[claimingRewardsCache.randomCheckIndex],
                    _causalityParams.hash1[claimingRewardsCache.randomCheckIndex],
                    _causalityParams.hash2[claimingRewardsCache.randomCheckIndex],
                    _causalityParams.timestamp[claimingRewardsCache.randomCheckIndex],
                    _causalityParams.signature[claimingRewardsCache.randomCheckIndex],
                    string(abi.encodePacked("INTERACTION_RESULT", claimingRewardsCache.randomCheckIndex)),
                    0,
                    maxRollCap
                );
            } else {
                result = causality.getRandomUnverified(
                    _causalityParams.userAddress,
                    _causalityParams.blockNumber[claimingRewardsCache.randomCheckIndex],
                    _causalityParams.hash1[claimingRewardsCache.randomCheckIndex],
                    _causalityParams.hash2[claimingRewardsCache.randomCheckIndex],
                    _causalityParams.timestamp[claimingRewardsCache.randomCheckIndex],
                    string(abi.encodePacked("INTERACTION_RESULT", claimingRewardsCache.randomCheckIndex)),
                    0,
                    maxRollCap
                );
            }
            (voyageResult, claimingRewardsCache) = interpretResults(
                result,
                voyageResult,
                _lockedVoyage,
                claimingRewardsCache,
                interaction,
                i
            );
            voyageResult.interactionRNGs[i] = uint16(result);
        }
        return voyageResult;
    }

    /**
     * @notice interprets a randomness result, meaning that based on the skill points accumulated from base pirate skills,
     *         flagship + support ships, we do a comparition between the result of the randomness and the skill points.
     *         if random > skill points than this interaction fails. Things to notice: if STORM or ENEMY fails then we
     *         destroy a support ship (if exists) or do health damage of 100% which will result in skipping all the upcoming
     *         interactions
     * @param _result - random number generated
     * @param _voyageResult - the result object that is cached and sent along for later on saving into storage
     * @param _lockedVoyage - locked voyage that contains the support ship objects that will get modified (sent as storage) if interaction failed
     * @param _claimingRewardsCache - cache object sent along for points updates
     * @param _interaction - interaction that we compute the outcome for
     * @param _index - current index of interaction, used to update the outcome
     * @return updated voyage results and claimingRewardsCache (this updates in case of a support ship getting destroyed)
     */
    function interpretResults(
        uint256 _result,
        VoyageResult memory _voyageResult,
        LockedVoyage storage _lockedVoyage,
        VoyageStatusCache memory _claimingRewardsCache,
        INTERACTION _interaction,
        uint256 _index
    ) internal view returns (VoyageResult memory, VoyageStatusCache memory) {
        if (_interaction == INTERACTION.CHEST && _result <= _claimingRewardsCache.luck) {
            _voyageResult.awardedChests++;
            _voyageResult.interactionResults[_index] = 1;
        } else if (
            (_interaction == INTERACTION.STORM && _result > _claimingRewardsCache.navigation) ||
            (_interaction == INTERACTION.ENEMY && _result > _claimingRewardsCache.strength)
        ) {
            if (_lockedVoyage.supportShipIds.length - _voyageResult.destroyedSupportShips > 0) {
                _voyageResult.destroyedSupportShips++;
                (uint256 points, SUPPORT_SHIP_TYPE supportShipType) = supportShip.getSkillBoostPerTokenId(
                    _lockedVoyage.supportShipIds[_voyageResult.destroyedSupportShips - 1]
                );
                if (
                    supportShipType == SUPPORT_SHIP_TYPE.SLOOP_STRENGTH ||
                    supportShipType == SUPPORT_SHIP_TYPE.CARAVEL_STRENGTH ||
                    supportShipType == SUPPORT_SHIP_TYPE.GALLEON_STRENGTH
                ) _claimingRewardsCache.strength -= points;
                if (
                    supportShipType == SUPPORT_SHIP_TYPE.SLOOP_LUCK ||
                    supportShipType == SUPPORT_SHIP_TYPE.CARAVEL_LUCK ||
                    supportShipType == SUPPORT_SHIP_TYPE.GALLEON_LUCK
                ) _claimingRewardsCache.luck -= points;
                if (
                    supportShipType == SUPPORT_SHIP_TYPE.SLOOP_NAVIGATION ||
                    supportShipType == SUPPORT_SHIP_TYPE.CARAVEL_NAVIGATION ||
                    supportShipType == SUPPORT_SHIP_TYPE.GALLEON_NAVIGATION
                ) _claimingRewardsCache.navigation -= points;
            } else {
                _voyageResult.healthDamage = 100;
            }
        } else if (_interaction != INTERACTION.CHEST) {
            _voyageResult.interactionResults[_index] = 1;
        }
        return (_voyageResult, _claimingRewardsCache);
    }

    /**
     * @notice awards the voyage (if any) and transfers back the assets that were locked into the voyage
     *         to the owners, also if support ship destroyed, it burns them, if healh damage taken then apply effect on flagship
     * @param _voyageResult - the result of the voyage that is used to award and apply effects
     * @param _typeOfVoyage - used to mint the chests types accordingly with the voyage type
     * @param _lockedVoyage - locked voyage object used to get the locked items that needs to be transferred back
     * @param _owner - the owner of the voyage that will receive rewards + items back
     *
     */
    function awardRewards(
        VoyageResult memory _voyageResult,
        VOYAGE_TYPE _typeOfVoyage,
        LockedVoyage memory _lockedVoyage,
        address _owner
    ) internal {
        chest.mint(_owner, _typeOfVoyage, _voyageResult.awardedChests);
        dps.safeTransferFrom(address(this), _owner, _lockedVoyage.dpsId);

        if (_voyageResult.healthDamage > 0)
            flagship.upgradePart(FLAGSHIP_PART.HEALTH, _lockedVoyage.flagshipId, 100 - _voyageResult.healthDamage);
        flagship.safeTransferFrom(address(this), _owner, _lockedVoyage.flagshipId);

        for (uint256 i; i < _lockedVoyage.supportShipIds.length; i++) {
            if (i < _voyageResult.destroyedSupportShips) supportShip.burn(_lockedVoyage.supportShipIds[i]);
            else supportShip.safeTransferFrom(address(this), _owner, _lockedVoyage.supportShipIds[i]);
        }
        voyage.burn(_lockedVoyage.voyageId);
    }

    /**
     * @notice computes skills for the support ships as there are multiple types that apply skills to different skill type: navigation, luck, strength
     * @param _supportShips the array of support ships
     * @param _claimingRewardsCache the cache object that contains the skill points per skill type
     * @return cached object with the skill points updated
     */
    function computeSupportShipSkills(uint256[] memory _supportShips, VoyageStatusCache memory _claimingRewardsCache)
        internal
        view
        returns (VoyageStatusCache memory)
    {
        for (uint256 i; i < _supportShips.length; i++) {
            (uint256 skill, SUPPORT_SHIP_TYPE supportShipType) = supportShip.getSkillBoostPerTokenId(_supportShips[i]);
            if (
                supportShipType == SUPPORT_SHIP_TYPE.SLOOP_STRENGTH ||
                supportShipType == SUPPORT_SHIP_TYPE.CARAVEL_STRENGTH ||
                supportShipType == SUPPORT_SHIP_TYPE.GALLEON_STRENGTH
            ) _claimingRewardsCache.strength += skill;

            if (
                supportShipType == SUPPORT_SHIP_TYPE.SLOOP_LUCK ||
                supportShipType == SUPPORT_SHIP_TYPE.CARAVEL_LUCK ||
                supportShipType == SUPPORT_SHIP_TYPE.GALLEON_LUCK
            ) _claimingRewardsCache.luck += skill;

            if (
                supportShipType == SUPPORT_SHIP_TYPE.SLOOP_NAVIGATION ||
                supportShipType == SUPPORT_SHIP_TYPE.CARAVEL_NAVIGATION ||
                supportShipType == SUPPORT_SHIP_TYPE.GALLEON_NAVIGATION
            ) _claimingRewardsCache.navigation += skill;
        }
        return _claimingRewardsCache;
    }

    /**
     * @notice computes skills for the flagship based on the level of the part of the flagship + base skills of the flagship
     * @param _flagshipId flagship id
     * @param _claimingRewardsCache the cache object that contains the skill points per skill type
     * @return cached object with the skill points updated
     */
    function computeFlagShipSkills(uint256 _flagshipId, VoyageStatusCache memory _claimingRewardsCache)
        internal
        view
        returns (VoyageStatusCache memory)
    {
        uint8[7] memory levels = flagship.getPartsLevel(_flagshipId);
        uint16[7] memory skillsPerPart = gameSettings.getSkillsPerFlagshipParts();
        uint8[7] memory skillTypes = gameSettings.getSkillTypeOfEachFlagshipPart();
        uint256 flagShipBaseSkills = gameSettings.getFlagshipBaseSkills();
        _claimingRewardsCache.luck += flagShipBaseSkills;
        _claimingRewardsCache.navigation += flagShipBaseSkills;
        _claimingRewardsCache.strength += flagShipBaseSkills;
        for (uint256 i; i < 7; i++) {
            if (skillTypes[i] == uint8(SKILL_TYPE.LUCK)) _claimingRewardsCache.luck += skillsPerPart[i] * levels[i];
            if (skillTypes[i] == uint8(SKILL_TYPE.NAVIGATION))
                _claimingRewardsCache.navigation += skillsPerPart[i] * levels[i];
            if (skillTypes[i] == uint8(SKILL_TYPE.STRENGTH)) _claimingRewardsCache.strength += skillsPerPart[i] * levels[i];
        }
        return _claimingRewardsCache;
    }

    /**
     * @notice Checks if causality params are correct in terms of blocks generated based on
     * block of buying and locked
     * @param _causalityParams params that needs to be checked
     * @param _voyageConfig config of the voyage
     * @param _lockedVoyage locked voyage params
     */
    function checkCausalityParams(
        CausalityParams memory _causalityParams,
        VoyageConfig memory _voyageConfig,
        LockedVoyage memory _lockedVoyage
    ) internal pure {
        for (uint256 i = 0; i < _voyageConfig.noOfInteractions + 2; i++) {
            if (!((i + 1) * _voyageConfig.noOfBlockJumps + _voyageConfig.boughtAt == _causalityParams.blockNumber[i])) {}
            require(
                (i + 1) * _voyageConfig.noOfBlockJumps + _voyageConfig.boughtAt == _causalityParams.blockNumber[i],
                "Causality params of bought blocks are wrong"
            );
        }
        uint256 j = 1;
        for (uint256 i = _voyageConfig.noOfInteractions + 2; i < _voyageConfig.noOfInteractions * 2 + 2; i++) {
            require(
                (j) * _voyageConfig.noOfBlockJumps + _lockedVoyage.lockedBlock == _causalityParams.blockNumber[i],
                "Causality params of locked blocks are wrong"
            );
            j++;
        }
    }

    /**
     * @notice cleans a locked voyage, usually once it's finished
     * @param _voyageId - voyage id
     * @param _owner  - owner of the voyage
     */
    function cleanLockedVoyage(uint256 _voyageId, address _owner) internal {
        uint256[] storage voyagesForOwner = lockedVoyagesIds[_owner];
        for (uint256 i; i < voyagesForOwner.length; i++) {
            if (voyagesForOwner[i] == _voyageId) {
                voyagesForOwner[i] = voyagesForOwner[voyagesForOwner.length - 1];
                voyagesForOwner.pop();
            }
        }
        delete ownerOfLockedVoyages[_voyageId];
        delete lockedVoyages[_owner][_voyageId];
    }

    function onERC721Received(
        address _operator,
        address,
        uint256,
        bytes calldata
    ) public view override returns (bytes4) {
        require(_operator == address(this), "Accepting only from Docks");
        return this.onERC721Received.selector;
    }

    /**
     * @notice Recover NFT sent by mistake to the contract
     * @param _nft the NFT address
     * @param _destination where to send the NFT
     * @param _tokenId the token to want to recover
     */
    function recoverNFT(
        address _nft,
        address _destination,
        uint256 _tokenId
    ) external onlyOwner {
        require(_destination != address(0), "Destination can not be address 0");
        IERC721(_nft).safeTransferFrom(address(this), _destination, _tokenId);
        emit TokenRecovered(_nft, _destination, _tokenId);
    }

    /**
     * @notice Recover NFT sent by mistake to the contract
     * @param _nft the 1155 NFT address
     * @param _destination where to send the NFT
     * @param _tokenId the token to want to recover
     * @param _amount amount of this token to want to recover
     */
    function recover1155NFT(
        address _nft,
        address _destination,
        uint256 _tokenId,
        uint256 _amount
    ) external onlyOwner {
        require(_destination != address(0), "Destination can not be address 0");
        IERC1155(_nft).safeTransferFrom(address(this), _destination, _tokenId, _amount, "");
        emit TokenRecovered(_nft, _destination, _tokenId);
    }

    /**
     * @notice Recover TOKENS sent by mistake to the contract
     * @param _token the TOKEN address
     * @param _destination where to send the NFT
     */
    function recoverERC20(address _token, address _destination) external onlyOwner {
        require(_destination != address(0), "Destination can not be address 0");
        uint256 amount = IERC20(_token).balanceOf(address(this));
        IERC20(_token).safeTransferFrom(address(this), _destination, amount);
        emit TokenRecovered(_token, _destination, amount);
    }

    function cleanVoyageResults(uint256 _voyageId) external onlyOwner {
        delete voyageResults[_voyageId];
    }

    /**
     * SETTERS & GETTERS
     */
    function setVoyageContract(address _contract) external onlyOwner {
        require(_contract != address(0), "Can not be address 0");
        voyage = DPSVoyageI(_contract);
        emit SetContract("Voyage", _contract);
    }

    function setCausalityContract(address _contract) external onlyOwner {
        require(_contract != address(0), "Can not be address 0");
        causality = DPSRandomI(_contract);
        emit SetContract("Causality", _contract);
    }

    function setDpsContract(address _contract) external onlyOwner {
        require(_contract != address(0), "Can not be address 0");
        dps = IERC721(_contract);
        emit SetContract("DPS", _contract);
    }

    function setFlagshipContract(address _contract) external onlyOwner {
        require(_contract != address(0), "Can not be address 0");
        flagship = DPSFlagshipI(_contract);
        emit SetContract("Flagship", _contract);
    }

    function setSupportShipContract(address _contract) external onlyOwner {
        require(_contract != address(0), "Can not be address 0");
        supportShip = DPSSupportShipI(_contract);
        emit SetContract("SupportShip", _contract);
    }

    function setArtifactContract(address _contract) external onlyOwner {
        require(_contract != address(0), "Can not be address 0");
        artifact = IERC721(_contract);
        emit SetContract("Artifact", _contract);
    }

    function setGameSettingsContract(address _contract) external onlyOwner {
        require(_contract != address(0), "Can not be address 0");
        gameSettings = DPSGameSettingsI(_contract);
        emit SetContract("GameSettings", _contract);
    }

    function setDpsPirateFeaturesContract(address _contract) external onlyOwner {
        require(_contract != address(0), "Can not be address 0");
        dpsFeatures = DPSPirateFeaturesI(_contract);
        emit SetContract("DPSFeatures", _contract);
    }

    function setCartographerContract(address _contract) external onlyOwner {
        require(_contract != address(0), "Can not be address 0");
        cartographer = DPSCartographerI(_contract);
        emit SetContract("Cartographer", _contract);
    }

    function setChestsContract(address _contract) external onlyOwner {
        require(_contract != address(0), "Can not be address 0");
        chest = DPSChestsI(_contract);
        emit SetContract("Chest", _contract);
    }

    function getLockedVoyagesForOwner(address _owner) external view returns (LockedVoyage[] memory locked) {
        locked = new LockedVoyage[](lockedVoyagesIds[_owner].length);
        for (uint256 i; i < lockedVoyagesIds[_owner].length; i++) {
            locked[i] = lockedVoyages[_owner][lockedVoyagesIds[_owner][i]];
        }
    }

    function getLockedVoyageByOwnerAndId(address _owner, uint256 _voyageId)
        external
        view
        returns (LockedVoyage memory locked)
    {
        for (uint256 i; i < lockedVoyagesIds[_owner].length; i++) {
            uint256 tempId = lockedVoyagesIds[_owner][i];
            if (tempId == _voyageId) return lockedVoyages[_owner][tempId];
        }
    }

    function getFinishedVoyagesForOwner(address _owner) external view returns (LockedVoyage[] memory finished) {
        finished = new LockedVoyage[](finishedVoyagesIds[_owner].length);
        for (uint256 i; i < finishedVoyagesIds[_owner].length; i++) {
            finished[i] = finishedVoyages[_owner][finishedVoyagesIds[_owner][i]];
        }
    }

    function getFinishedVoyageByOwnerAndId(address _owner, uint256 _voyageId)
        external
        view
        returns (LockedVoyage memory finished)
    {
        for (uint256 i; i < finishedVoyagesIds[_owner].length; i++) {
            uint256 tempId = finishedVoyagesIds[_owner][i];
            if (tempId == _voyageId) return finishedVoyages[_owner][tempId];
        }
    }

    function getLockedVoyageOwner(uint256 _voyageId) public view returns (address) {
        return ownerOfLockedVoyages[_voyageId];
    }

    function getLastComputedState(uint256 _voyageId) external view returns (VoyageResult memory) {
        return voyageResults[_voyageId];
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (security/ReentrancyGuard.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20Mintable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @dev Interface of the ERC20 expanded to include mint and burn functionality
 * @dev
 */
interface IERC20MintableBurnable is IERC20Mintable, IERC20 {
    /**
     * @dev burns `amount` from `receiver`
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits an {BURN} event.
     */
    function burn(address _from, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
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
// OpenZeppelin Contracts v4.4.0 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "../IERC721Receiver.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

enum VOYAGE_TYPE {
    EASY,
    MEDIUM,
    HARD,
    LEGENDARY
}

enum SUPPORT_SHIP_TYPE {
    SLOOP_STRENGTH,
    SLOOP_LUCK,
    SLOOP_NAVIGATION,
    CARAVEL_STRENGTH,
    CARAVEL_LUCK,
    CARAVEL_NAVIGATION,
    GALLEON_STRENGTH,
    GALLEON_LUCK,
    GALLEON_NAVIGATION
}

enum INTERACTION {
    NONE,
    CHEST,
    STORM,
    ENEMY
}

enum FLAGSHIP_PART {
    HEALTH,
    CANNON,
    HULL,
    SAILS,
    HELM,
    FLAG,
    FIGUREHEAD
}

enum SKILL_TYPE {
    LUCK,
    STRENGTH,
    NAVIGATION
}

struct VoyageConfig {
    VOYAGE_TYPE typeOfVoyage;
    uint8 noOfInteractions;
    uint16 noOfBlockJumps;
    // 1 - Chest 2 - Storm 3 - Enemy
    uint8[] sequence;
    uint256 boughtAt;
    uint256 gapBetweenInteractions;
}

struct CartographerConfig {
    uint8 minNoOfChests;
    uint8 maxNoOfChests;
    uint8 minNoOfStorms;
    uint8 maxNoOfStorms;
    uint8 minNoOfEnemies;
    uint8 maxNoOfEnemies;
    uint8 totalInteractions;
    uint256 gapBetweenInteractions;
}

struct RandomInteractions {
    uint256 randomNoOfChests;
    uint256 randomNoOfStorms;
    uint256 randomNoOfEnemies;
    uint8 generatedChests;
    uint8 generatedStorms;
    uint8 generatedEnemies;
    uint256[] positionsForGeneratingInteractions;
}

struct CausalityParams {
    address userAddress;
    uint256[] blockNumber;
    bytes32[] hash1;
    bytes32[] hash2;
    uint256[] timestamp;
    bytes[] signature;
}

struct LockedVoyage {
    uint256 voyageId;
    uint256 dpsId;
    uint256 flagshipId;
    uint256[] supportShipIds;
    uint256 artifactId;
    uint256 lockedBlock;
    uint256 lockedTimestamp;
    uint256 claimedTime;
    uint16 navigation;
    uint16 luck;
    uint16 strength;
}

struct VoyageResult {
    uint16 awardedChests;
    uint16 destroyedSupportShips;
    uint8 healthDamage;
    uint16 skippedInteractions;
    uint16[] interactionRNGs;
    uint8[] interactionResults;
}

struct VoyageStatusCache {
    uint256 strength;
    uint256 luck;
    uint256 navigation;
    uint256 randomCheckIndex;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "./DPSStructs.sol";

interface DPSVoyageI is IERC721Enumerable {
    function mint(
        address _owner,
        uint256 _tokenId,
        VoyageConfig calldata config
    ) external;

    function burn(uint256 _tokenId) external;

    function getVoyageConfig(uint256 _voyageId) external view returns (VoyageConfig memory config);

    function tokensOfOwner(address _owner) external view returns (uint256[] memory);

    function exists(uint256 _tokenId) external view returns (bool);
}

interface DPSRandomI {
    function getRandomBatch(
        address _address,
        uint256[] memory _blockNumber,
        bytes32[] memory _hash1,
        bytes32[] memory _hash2,
        uint256[] memory _timestamp,
        bytes[] memory _signature,
        string[] memory _entropy,
        uint256 _min,
        uint256 _max
    ) external view returns (uint256[] memory randoms);

    function getRandomUnverifiedBatch(
        address _address,
        uint256[] memory _blockNumber,
        bytes32[] memory _hash1,
        bytes32[] memory _hash2,
        uint256[] memory _timestamp,
        string[] memory _entropy,
        uint256 _min,
        uint256 _max
    ) external pure returns (uint256[] memory randoms);

    function getRandom(
        address _address,
        uint256 _blockNumber,
        bytes32 _hash1,
        bytes32 _hash2,
        uint256 _timestamp,
        bytes memory _signature,
        string memory _entropy,
        uint256 _min,
        uint256 _max
    ) external view returns (uint256 randoms);

    function getRandomUnverified(
        address _address,
        uint256 _blockNumber,
        bytes32 _hash1,
        bytes32 _hash2,
        uint256 _timestamp,
        string memory _entropy,
        uint256 _min,
        uint256 _max
    ) external pure returns (uint256 randoms);
}

interface DPSGameSettingsI {
    function getVoyageConfig(VOYAGE_TYPE _type) external view returns (CartographerConfig memory);

    function getMaxSkillsCap() external view returns (uint16);

    function getMaxRollCap() external view returns (uint16);

    function getFlagshipBaseSkills() external view returns (uint16);

    function getSkillsPerFlagshipParts() external view returns (uint16[7] memory skills);

    function getSkillTypeOfEachFlagshipPart() external view returns (uint8[7] memory skillTypes);

    function getTMAPPerVoyageType(VOYAGE_TYPE _type) external view returns (uint256);

    function getBlockJumps() external view returns (uint16);

    function getGapBetweenVoyagesCreation() external view returns (uint256);

    function getDoubloonsRewardsPerChest(VOYAGE_TYPE _type) external view returns (uint256[] memory);

    function isPaused(uint8 _component) external view returns (uint8);

    function getTmapPerDoubloon() external view returns (uint256);
}

interface DPSPirateFeaturesI {
    function getTraitsAndSkills(uint16 _dpsId) external view returns (string[8] memory, uint16[3] memory);
}

interface DPSSupportShipI is IERC721 {
    function getSkillBoostPerTokenId(uint256 _tokenId) external view returns (uint256, SUPPORT_SHIP_TYPE);

    function burn(uint256 _id) external;

    function exists(uint256 _tokenId) external view returns (bool);
}

interface DPSFlagshipI is IERC721 {
    function mint(address _owner, uint256 _id) external;

    function burn(uint256 _id) external;

    function upgradePart(
        FLAGSHIP_PART _trait,
        uint256 _tokenId,
        uint8 _level
    ) external;

    function getPartsLevel(uint256 _flagshipId) external view returns (uint8[7] memory);

    function tokensOfOwner(address _owner) external view returns (uint256[] memory);

    function exists(uint256 _tokenId) external view returns (bool);
}

interface DPSChestsI is IERC1155 {
    function mint(
        address _to,
        VOYAGE_TYPE _voyageType,
        uint256 _amount
    ) external;

    function burn(
        address _from,
        VOYAGE_TYPE _voyageType,
        uint256 _amount
    ) external;
}

interface DPSCartographerI {
    function viewVoyageConfiguration(CausalityParams memory causalityParams, uint256 _voyageId)
        external
        view
        returns (VoyageConfig memory voyageConfig);
}

interface MintableBurnableIERC1155 is IERC1155 {
    function mint(
        address _to,
        VOYAGE_TYPE _voyageType,
        uint256 _amount
    ) external;

    function burn(
        address _from,
        VOYAGE_TYPE _voyageType,
        uint256 _amount
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 expanded to include mint functionality
 * @dev
 */
interface IERC20Mintable {
    /**
     * @dev mints `amount` to `receiver`
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits an {Minted} event.
     */
    function mint(address receiver, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Address.sol)

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721Receiver.sol)

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
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/extensions/IERC721Enumerable.sol)

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
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721.sol)

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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/introspection/IERC165.sol)

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