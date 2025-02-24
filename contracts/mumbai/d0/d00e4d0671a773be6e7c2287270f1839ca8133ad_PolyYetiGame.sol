//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.7;
import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155ReceiverUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "./Interfaces/IYeti.sol";
import "./YetiSigner.sol";
import "./GaslessSigner.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
contract PolyYetiGame is OwnableUpgradeable, YetiSigner, ReentrancyGuardUpgradeable, GaslessSigner {

    iYeti public yeti;
    IERC20Upgradeable public frxst;

    struct Stake {
        uint8 activityId;
        uint16 tokenId;
        uint80 value;
        uint80 stakeTime;
        address owner;
    }

    struct InjuryStake {
        uint16 tokenId;
        uint80 value;
        address owner;
    }

    address public treasury;

    uint256 nonce;
    uint256 public totalYetiStakedGathering;
    uint256 public totalYetiStakedHunting;
    uint256 public totalYetiStakedFighting;
    uint256 public MINIMUM_TO_EXIT ;
    uint256 public INJURY_TIME;
    uint256 public GATHERING_TAX_RISK_PERCENTAGE;
    uint256 public HUNTING_INJURY_RISK_PERCENTAGE;
    uint256 public FIGHTING_STOLEN_RISK_PERCENTAGE;
    uint256 public GENERAL_FRXST_TAX_PERCENTAGE;
    uint256 public GATHERING_FRXST_TAX_PERCENTAGE;
    uint256 public rewardCalculationDuration;
    uint256 public HEALING_COST;
    uint256 public LEVEL_UP_COST_MULTIPLIER;
    uint256 public healingConstant;

    uint256[] public yetiMultiplier;
    uint256[] public levelCost;
    uint256[] public levelExp;
    uint256[][] public rates;
    uint256[][] public exprates;

    mapping (uint => uint) public levels;
    mapping (uint => uint) public exp;
    mapping (uint => bool) public onL2;
    mapping (uint => uint) public tokenRarity;
    mapping (address => uint[]) public stakedToken;
    mapping (uint => uint) public  tokenToPosition;
    mapping(uint => Stake) public palace;
    mapping(uint => Stake) public fighters;
    Stake[] public fighterArray;
    mapping (uint => uint) public fighterIndices;
    mapping (uint => InjuryStake) public hospital;
    mapping (uint => address) public ownerOfToken;
    mapping (address => mapping (uint => bool)) public usedNonce;
    mapping (uint => bool) public isMinted;


    //@dev Game Mechanics
    function startAll(
        address _yeti,
        address _frxst,
        address _treasury,
        string memory domainSigner,
        string memory versionSigner,
        string memory domainUserInteraction,
        string memory versionInteraction)
    public  initializer
    {
        __Ownable_init();
        __ReentrancyGuard_init();
        __YetiSigner_init(domainSigner,versionSigner);
        __rarity_init(domainUserInteraction,versionInteraction);
        if (_yeti != address(0)) {
            yeti = iYeti(_yeti);
        }
        if (_frxst != address(0)) {
            frxst = IERC20Upgradeable(_frxst);
        }
        if (_treasury != address(0)) {
            treasury = _treasury;
        }
        MINIMUM_TO_EXIT = 2 days;
        INJURY_TIME = 1 days;
        GATHERING_TAX_RISK_PERCENTAGE = 50;
        HUNTING_INJURY_RISK_PERCENTAGE = 500;
        FIGHTING_STOLEN_RISK_PERCENTAGE = 100;
        GENERAL_FRXST_TAX_PERCENTAGE = 10;
        GATHERING_FRXST_TAX_PERCENTAGE = 50;
        rewardCalculationDuration = 1 days;
        HEALING_COST = 500 * 1e18;
        LEVEL_UP_COST_MULTIPLIER = 100;
        healingConstant = 150;
        yetiMultiplier = [100, 120, 150];
        levelCost = [0, 48, 210, 512, 980, 2100, 3430, 4760, 6379, 8313];
        levelExp = [0, 50, 200, 450, 800, 1600, 2450, 3200, 4050, 5000];
        rates = [
        [50, 60, 4],
        [90, 135, 10],
        [130, 195, 26]
        ];
        exprates = [
        [80,100,120], //deviant [gather,hunt,duel]
        [96,120,144],
        [120,150,180]
        ];
    }

    //@dev Mints L2 yeti along with all the traits of the original Yeti on L1
    //@param A tuple consisting of userAddress, tokenId, level, exp, rarity, pass and signature.
    function MintTokens(Rarity memory yetis) external onlyOwner{
        require(!isMinted[yetis.tokenId], "TokenID is already minted");
        require (getSigner(yetis) == yetis.userAddress,'!User address');
        if(!onL2[yetis.tokenId]){
            yeti.mintNewTokens(yetis.tokenId, yetis.userAddress);
            levels[yetis.tokenId] = yetis.level;
            exp[yetis.tokenId] = yetis.exp;
            tokenRarity[yetis.tokenId] = yetis.rarity;
            onL2[yetis.tokenId] = true;
            isMinted[yetis.tokenId] = true;
            nonce++;
        }
        else{
            ReEnterMint(yetis);
        }
    }

    function burnToken (Rarity memory rarity) external onlyOwner {
        require(isMinted[rarity.tokenId],'TokenId not present');
        isMinted[rarity.tokenId] = false;
        yeti.burnToken(rarity.tokenId,rarity.userAddress);
    }


    //@dev Levels Up the Yeti
    //@param A tuple consisting of userAddress, nonce and signature, tokenIds of Yeti to be levelled in an array.
    function levelup(Signer memory rarity, uint[] memory tokenIds) external onlyOwner{
        address account = rarity._user;
        require(!usedNonce[account][rarity.nonce],'Nonce Used');
        require(getYetiSigner(rarity) == account, "Not Account");
        usedNonce[account][rarity.nonce] = true;
        for(uint i = 0; i < tokenIds.length; i++){
            require(fighters[tokenIds[i]].tokenId != tokenIds[i], "Can't level up while fighting");
            require(palace[tokenIds[i]].tokenId != tokenIds[i], "Can't level up while staked");
            require(hospital[tokenIds[i]].tokenId != tokenIds[i], "Can't level up while injured");
            require(levels[tokenIds[i]] > 0 && levels[tokenIds[i]] < 10, "Can exceed level ran");
            require(frxst.balanceOf(account) >= levelCost[levels[tokenIds[i]]], "Insufficient FRXST");
            frxst.transferFrom(account, address(this), levelCost[levels[tokenIds[i]]]* 1 ether);
            exp[tokenIds[i]] -= levelExp[levels[tokenIds[i]]];
            levels[tokenIds[i]] += 1;
        }
    }

    //@dev Adds Yeti to Palace and depending on the activity Id, it would send Yeti to Harvest, Hunt or Fight'
    //@param A tuple consisting of userAddress, nonce and signature, tokenIds of Yeti in an array, activity id 0, 1 or 2
    function addManyToPalace(Signer memory signer, uint[] memory tokenIds, uint8 activityId) external onlyOwner{
        require (activityId < 3, "Not valid activity id");
        address account = signer._user;
//        require(getYetiSigner(signer) == account, "Not Account");
        require(!usedNonce[account][signer.nonce],'Nonce Used');
        usedNonce[account][signer.nonce] = true;
        for (uint i = 0; i < tokenIds.length; i++) {
            require(fighters[tokenIds[i]].tokenId != tokenIds[i], "fighting yeti");
            require(palace[tokenIds[i]].tokenId != tokenIds[i], "staked yeti");
            require(hospital[tokenIds[i]].tokenId != tokenIds[i], "injured yeti");
        if (account != address(yeti)) {
                require(account == yeti.viewOwnerOfToken(tokenIds[i]), "Invalid Token Owners");
                yeti.safeTransferFrom(account, address(this), tokenIds[i],1,'');
                tokenToPosition[tokenIds[i]] = stakedToken[account].length;
                stakedToken[account].push(tokenIds[i]);
            }
            if (levels[tokenIds[i]] == 0) {
                levels[tokenIds[i]] = 1;
                exp[tokenIds[i]] = 0;
            }
            if (activityId == 2) {
                _addYetiToFighting(account, tokenIds[i], activityId);
            } else {
                _addYetiToPalace(account, tokenIds[i], activityId);
            }
        }
    }

    //@dev Bring backs Yeti from hospital to gaming arena
    //@param A tuple consisting of userAddress, nonce and signature, tokenId of Yeti to be de-hospitalised
    function ClaimSickYeti(Signer memory rarity, uint tokenId) public onlyOwner{
        address account = rarity._user;
        require(getYetiSigner(rarity) == account, "Not Account");
        require(!usedNonce[account][rarity.nonce],'Nonce Used');
        usedNonce[account][rarity.nonce] = true;
        _claimYetiFromHospital(account, tokenId, false);
    }

    //@dev Claims yeti from the activity they were sent to do.
    //@param A tuple consisting of userAddress, nonce and signature, tokenIds of Yeti in an array, and true if you want to unstake or false if you don't
    function claimMany(Rarity memory yetiSigner, uint16[] calldata tokenIds, bool unstake) external onlyOwner {
        address account = yetiSigner.userAddress;
        require(getSigner(yetiSigner) == account, "Not Account");
        uint owed;
        for (uint i = 0; i < tokenIds.length; i++) {
            require(fighters[tokenIds[i]].tokenId == tokenIds[i] || palace[tokenIds[i]].tokenId == tokenIds[i], "Yeti is not staked");
            owed += _claimYeti(yetiSigner, account, tokenIds[i], unstake);
        }
        require(owed > 0, "Claiming before 1 day");
        frxst.transfer(account, owed);
        nonce++;
    }

    //@dev Heals yeti quickly and transfers them from hospital to the activity arena
    //@param A tuple consisting of userAddress, nonce and signature, tokenId of Yeti to be healed
    function Heal(Signer memory rarity, uint tokenId) external onlyOwner{
        require(!usedNonce[rarity._user][rarity.nonce],'Nonce Used');
        usedNonce[rarity._user][rarity.nonce] = true;

        address account = rarity._user;
        require(getYetiSigner(rarity) == account, "Not Account");
        require(hospital[tokenId].value + INJURY_TIME > block.timestamp, "YOU ARE NOT INJURED");
        if (frxst.transferFrom(account, treasury, heal_cost(tokenId) * 1 ether)) {
            _claimYetiFromHospital(account, tokenId, true);
        }
    }

    //@dev Used to unstake Yetis if theres an emergency in game contract
    //@param TokenIds of Yetis and their Owners Addresses in respective arrays.
    function emergencyUnstake(uint[] memory _tokenIds, address[] memory _userAddresses) external onlyOwner{
        for(uint i = 0; i < _tokenIds.length; i++){
            yeti.safeTransferFrom(address(this), _userAddresses[i], _tokenIds[i], 1,  "");
        }
    }

    //@dev Setters:

    function setYetiMultiplier(uint[] memory _yetiMultiplier) external onlyOwner {
        yetiMultiplier = _yetiMultiplier;
    }

    function setLevelCost(uint[] memory _levelCost) external onlyOwner {
        levelCost = _levelCost;
    }

    function setLevelExp(uint[] memory _levelExp) external onlyOwner {
        levelExp = _levelExp;
    }

    function setRewardCalculationDuration(uint _amount) external onlyOwner {
        rewardCalculationDuration = _amount;
    }

    function SetFrxstRates(uint[][] memory _rates) public onlyOwner {
        rates = _rates;
    }

    function SetGeneralTaxPercentage(uint _tax) external onlyOwner {
        GENERAL_FRXST_TAX_PERCENTAGE = _tax;
    }

    function SetGatherTaxPercentage(uint _tax) external onlyOwner {
        GATHERING_FRXST_TAX_PERCENTAGE = _tax;
    }

    function SetLevelUpCostMultiplier(uint _multiplier) external onlyOwner {
        LEVEL_UP_COST_MULTIPLIER = _multiplier;
    }

    function SetExpRates(uint[][] memory _exprates) external onlyOwner {
        exprates = _exprates;
    }

    function gatheringFRXSTRisk(uint _new) external onlyOwner{
        GATHERING_TAX_RISK_PERCENTAGE = _new;
    }

    function huntingInjuryRisk(uint _new) external onlyOwner{
        HUNTING_INJURY_RISK_PERCENTAGE = _new;
    }

    function fightingStolenRisk(uint _new) external onlyOwner{
        FIGHTING_STOLEN_RISK_PERCENTAGE = _new;
    }

    function healCostSetter (uint cost) external onlyOwner {
        HEALING_COST = cost;
    }

    function setHealingConstant(uint _heal) external onlyOwner{
        healingConstant = _heal;
    }

    // In days
    function SetInjuryTime(uint _seconds) external onlyOwner {
        INJURY_TIME = _seconds;
    }
    // In days
    function SetMinimumClaimTime(uint _seconds) external onlyOwner {
        MINIMUM_TO_EXIT = _seconds;
    }

    // In ether
    function SetHealingCost(uint _healingCost) external onlyOwner {
        LEVEL_UP_COST_MULTIPLIER = _healingCost * 1e18;
    }

    function setTreasury(address _treasury) external onlyOwner {
        treasury = _treasury;
    }

    function setYetiAddress(address _yeti) external onlyOwner {
        yeti = iYeti(_yeti);
    }

    function setFrxstAddress(address _frxst) external onlyOwner {
        frxst = IERC20Upgradeable(_frxst);
    }

    //@dev Getters
    function GetTotalYetiStaked() public view returns (uint) {
        return totalYetiStakedGathering + totalYetiStakedHunting + totalYetiStakedFighting;
    }

    function getStakedTokens(address _user) external view returns(uint[] memory) {
        return stakedToken[_user];
    }

    //@dev Internal Functions

    //@dev This function is required so that when a player re-enters their token on L2, the stored data is queried from the mappings.
    function ReEnterMint(Rarity memory token) internal{
        yeti.mintNewTokens(token.tokenId, token.userAddress);
        nonce++;
    }

    function popToken(uint tokenId, address _user) internal {
        uint[] storage currentMap = stakedToken[_user];
        uint lastToken = currentMap[currentMap.length-1];
        tokenToPosition[lastToken] = tokenToPosition[tokenId];
        currentMap[tokenToPosition[lastToken]] = lastToken;
        stakedToken[_user].pop();
    }

    function _addYetiToFighting(address account, uint tokenId, uint8 activityId) internal  {

        fighterIndices[tokenId] = totalYetiStakedFighting;
        Stake memory fs = Stake({
        owner: account,
        tokenId: uint16(tokenId),
        activityId: activityId,
        value: uint80(block.timestamp),
        stakeTime: uint80(block.timestamp)
        });
        fighters[tokenId] = fs;
        fighterArray.push(fs);
        fighterIndices[tokenId] = fighterArray.length - 1;
        totalYetiStakedFighting += 1;
        // emit TokenStaked(account, tokenId, activityId, block.timestamp);
    }

    function _addYetiToPalace(address account, uint tokenId, uint8 activityId) internal  { //whenNotPaused

        palace[tokenId] = Stake({
        owner: account,
        tokenId: uint16(tokenId),
        activityId: activityId,
        value: uint80(block.timestamp),
        stakeTime: uint80(block.timestamp)
        });
        if (activityId == 0) {
            totalYetiStakedGathering += 1;
        } else if (activityId == 1) {
            totalYetiStakedHunting += 1;
        }
    }

    function _payYetiTax(uint amount) internal {
        frxst.transfer(treasury, amount);
    }

    function heal_cost(uint tokenId) internal view returns (uint) {
        return 2*healingConstant* yetiMultiplier[tokenRarity[tokenId]]/100;
    }

    function _claimYetiFromHospital(address account, uint tokenId, bool healed) internal {
        InjuryStake memory stake = hospital[tokenId];
        require(stake.owner == account, "SWIPER, NO SWIPING");
        require(healed || (block.timestamp - stake.value > INJURY_TIME), "Yeti not healed yet!");
        yeti.safeTransferFrom(address(this), account, tokenId, 1, "");
        popToken(tokenId, account);
        delete tokenToPosition[tokenId];
        delete hospital[tokenId];
    }

    function _claimYetiFromPalace(Rarity memory yetiSigner, address account, uint tokenId, bool unstake) internal returns (uint owedFrxst) {
        Stake memory stake = palace[tokenId];
        require(stake.owner == account, "SWIPER, NO SWIPING");
        require(!( unstake && block.timestamp - stake.value < MINIMUM_TO_EXIT ), "Need two days of Frxst before claiming");
        uint c = tokenRarity[tokenId];
        nonce++;
        uint hourly;
        if (stake.activityId == 1) {
            hourly = rates[c][stake.activityId] * 1 ether;
            hourly = hourly + hourly*(levels[tokenId]-1)/10;
        } else{
            hourly = rates[c][stake.activityId] *1 ether;
            hourly = hourly + hourly*(levels[tokenId]-1)/10;
        }
        if (unstake) {
            uint mod = (block.timestamp - stake.value) /rewardCalculationDuration;
            owedFrxst =  (hourly * mod);
            uint owedExp = ((block.timestamp - stake.stakeTime)/rewardCalculationDuration)* exprates[c][stake.activityId];
            if (stake.activityId == 0) {
                uint rand = uint(keccak256(abi.encodePacked(yetiSigner.pass + nonce)));
                if (rand % 100 < GATHERING_FRXST_TAX_PERCENTAGE)
                {
                        uint amountToPay = newGatheringTax(levels[tokenId]);
                    _payYetiTax(owedFrxst * amountToPay / 100);
                    owedFrxst = owedFrxst * (100 - amountToPay) / 100;
                }
                yeti.safeTransferFrom(address(this), account, tokenId,1, "");
                popToken(tokenId, account);
                delete tokenToPosition[tokenId];
                if (exp[tokenId] < levelExp[levels[tokenId]]) {
                    if(owedExp > levelExp[levels[tokenId]]) {
                        owedExp = levelExp[levels[tokenId]] - exp[tokenId];
                    }
                    exp[tokenId] += owedExp;
                }
            }
            // Check Injury
            else if (stake.activityId == 1) {
                uint rand = uint(keccak256(abi.encodePacked(yetiSigner.pass)));
                if (rand % 1000 < newHuntingInjuryRisk(levels[tokenId])) {
                    owedExp = owedExp/2;
                    if (exp[tokenId] < levelExp[levels[tokenId]]) {
                        if(owedExp > levelExp[levels[tokenId]]) {
                            owedExp = levelExp[levels[tokenId]] - exp[tokenId];
                        }
                        exp[tokenId] += owedExp;
                    }
                    hospital[tokenId] = InjuryStake({
                    owner: account,
                    tokenId: uint16(tokenId),
                    value: uint80(block.timestamp)
                    });
                } else {
                    yeti.safeTransferFrom(address(this), account, tokenId, 1, "");
                    popToken(tokenId, account);
                    delete tokenToPosition[tokenId];
                    if (exp[tokenId] < levelExp[levels[tokenId]]) {
                        if(owedExp > levelExp[levels[tokenId]]) {
                            owedExp = levelExp[levels[tokenId]] - exp[tokenId];
                        }
                        exp[tokenId] += owedExp;
                    }
                }
                totalYetiStakedHunting -= 1;
            }
            delete palace[tokenId];
        }
        else {
            uint mod = (block.timestamp - stake.value) / rewardCalculationDuration;
            owedFrxst =  (hourly * mod);
            _payYetiTax(owedFrxst * GENERAL_FRXST_TAX_PERCENTAGE / 100);
            owedFrxst = owedFrxst * (100 - GENERAL_FRXST_TAX_PERCENTAGE) / 100;

            palace[tokenId] = Stake({
            owner: account,
            tokenId: uint16(tokenId),
            activityId: stake.activityId,
            value: uint80(block.timestamp),
            stakeTime: stake.stakeTime
            });
        }
    }

    function _claimYetiFromFighting(Rarity memory yetiSigner, address account, uint tokenId, bool unstake) internal returns (uint owedFrxst) {
        Stake memory stake = fighters[tokenId];
        require(stake.owner == account, "SWIPER, NO SWIPING");
        require(!(unstake && block.timestamp - stake.value < MINIMUM_TO_EXIT), "GONNA BE COLD WITHOUT TWO DAY'S FROST");
        nonce++;
        uint hourly = rates[tokenRarity[tokenId]][stake.activityId] * levels[tokenId]*1 ether;
        hourly = hourly + hourly* (levels[tokenId]-1)/10;
        if (unstake) {
            uint mod = (block.timestamp - stake.value) / rewardCalculationDuration;
            owedFrxst =  (hourly * mod);
            uint owedExp = ((block.timestamp - stake.stakeTime)/rewardCalculationDuration)* exprates[tokenRarity[tokenId]][stake.activityId];
            uint rand = uint(keccak256(abi.encodePacked(yetiSigner.pass + nonce)));
            Stake memory lastStake = fighterArray[fighterArray.length - 1];
            if (exp[tokenId] < levelExp[levels[tokenId]]) {
                if(owedExp > levelExp[levels[tokenId]]) {
                    owedExp = levelExp[levels[tokenId]] - exp[tokenId];
                }
                exp[tokenId] += owedExp;
            }
            if (rand % 1000 < newFightingHonour(levels[tokenId])) {
                uint rand1 = uint(keccak256(abi.encodePacked(yetiSigner.pass + nonce)));
                address recipient = selectRecipient(account, uint(keccak256(abi.encodePacked(rand1,'constantValue'))));
                yeti.safeTransferFrom(address(this), recipient, tokenId,1, "");
                popToken(tokenId, account);
                delete tokenToPosition[tokenId];
                exp[tokenId] = 0;
                levels[tokenId] = 1;
                //   emit Stolen(tokenId);
            } else {
                yeti.safeTransferFrom(address(this), account, tokenId,1, "");
                popToken(tokenId, account);
                delete tokenToPosition[tokenId];
            }
            fighterArray[fighterIndices[tokenId]] = lastStake;
            fighterIndices[lastStake.tokenId] = fighterIndices[tokenId];
            fighterArray.pop();
            delete fighterIndices[tokenId];
            delete fighters[tokenId];
            totalYetiStakedFighting -= 1;
            delete fighters[tokenId];
        } else {
            uint mod = (block.timestamp - stake.value) / rewardCalculationDuration ;
            owedFrxst =  (hourly * mod);
            _payYetiTax(owedFrxst * GENERAL_FRXST_TAX_PERCENTAGE / 100);
            owedFrxst = owedFrxst * (100 - GENERAL_FRXST_TAX_PERCENTAGE) / 100;
            fighters[tokenId] = Stake({
            owner: account,
            tokenId: uint16(tokenId),
            activityId: stake.activityId,
            value: uint80(block.timestamp),
            stakeTime: stake.stakeTime
            });
        }
    }

    function _claimYeti(Rarity memory yetiSigner, address account, uint tokenId, bool unstake) internal returns (uint owedFrxst) {
        if (fighters[tokenId].tokenId != tokenId) {
            return _claimYetiFromPalace(yetiSigner, account, tokenId, unstake);
        } else {
            return _claimYetiFromFighting(yetiSigner, account, tokenId, unstake);
        }
    }

    function newGatheringTax(uint level) internal view returns(uint){
        uint temp = GATHERING_TAX_RISK_PERCENTAGE;
        temp-= 2*(level-1);
        return temp;
    }

    function newFightingHonour(uint level) internal view returns(uint){
        uint temp = FIGHTING_STOLEN_RISK_PERCENTAGE;
        temp -= 5*(level-1);
        return temp;
    }

    function newHuntingInjuryRisk(uint level) internal view returns(uint){
        uint temp = HUNTING_INJURY_RISK_PERCENTAGE;
        temp -= 25*(level-1);
        return temp;
    }

    function selectRecipient(address account, uint seed) internal view returns (address) {
        address thief = randomYetiFighter(seed); // 144 bits reserved for trait selection
        if (thief == address(0x0)) return account;
        return thief;
    }

    function randomYetiFighter(uint seed) internal view returns (address) {
        require(fighterArray.length>0, "Array Size 0"); //require statement added here
        if (totalYetiStakedFighting == 0) return address(0x0);
        return fighterArray[seed % fighterArray.length].owner;
    }

    //@dev Helpers
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) external pure returns (bytes4){
        return IERC1155ReceiverUpgradeable.onERC1155Received.selector;
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155ReceiverUpgradeable is IERC165Upgradeable {
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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;
import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";

interface iYeti is IERC1155Upgradeable{

    function mintNewTokens(uint _tokenId, address _to) external;

    function burnToken(uint _tokenId, address _from) external;

    function viewOwnerOfToken(uint _tokenId) external returns(address);

}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;
import "@openzeppelin/contracts-upgradeable/utils/cryptography/draft-EIP712Upgradeable.sol";

contract YetiSigner is EIP712Upgradeable{

    ///@dev SIGNING_DOMAIN = "Yeti-Migration" ; SIGNATURE_VERSION = "1"
    string private  SIGNING_DOMAIN;
    string private  SIGNATURE_VERSION;

    struct Rarity{
        address userAddress;
        uint tokenId;
        uint level;
        uint exp;
        uint rarity;
        uint pass;
        bytes signature;
    }

    function __YetiSigner_init(string memory domain, string memory version) internal initializer {
        SIGNING_DOMAIN = domain;
        SIGNATURE_VERSION = version;
        __EIP712_init(domain, version);
    }

    function getSigner(Rarity memory rarity) public view returns(address){
        return _verify(rarity);
    }

    function _hash(Rarity memory rarity) internal view returns (bytes32) {
        return _hashTypedDataV4(keccak256(abi.encode(
                keccak256("Rarity(address userAddress,uint256 tokenId,uint256 level,uint256 exp,uint256 rarity,uint256 pass)"),
                rarity.userAddress,
                rarity.tokenId,
                rarity.level,
                rarity.exp,
                rarity.rarity,
                rarity.pass
            )));
    }

    function _verify(Rarity memory rarity) internal view returns (address) {
        bytes32 digest = _hash(rarity);
        return ECDSAUpgradeable.recover(digest, rarity.signature);
    }

}

//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/cryptography/draft-EIP712Upgradeable.sol";

contract GaslessSigner is EIP712Upgradeable{

    string private SIGNING_DOMAIN; //= "Yeti";
    string private SIGNATURE_VERSION;// = "1";

    struct Signer{
        address _user;
        uint nonce;
        bytes signature;
    }

    function __rarity_init(string memory domain, string memory version) public initializer {
        SIGNING_DOMAIN = domain;
        SIGNATURE_VERSION = version;
        __EIP712_init(domain,version);
    }

    function getYetiSigner(Signer memory signer) public view returns(address){
        return _verify(signer);
    }

    /// @notice Returns a hash of the given rarity, prepared using EIP712 typed data hashing rules.

    function _hash(Signer memory signer) internal view returns (bytes32) {
        return _hashTypedDataV4(keccak256(abi.encode(
                keccak256("Signer(address _user,uint256 nonce)"),
                    signer._user,
                    signer.nonce
            )));
    }

    function _verify(Signer memory signer) internal view returns (address) {
        bytes32 digest = _hash(signer);
        return ECDSAUpgradeable.recover(digest, signer.signature);
    }

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
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

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
        bool isTopLevelCall = _setInitializedVersion(1);
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
        bool isTopLevelCall = _setInitializedVersion(version);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(version);
        }
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
        _setInitializedVersion(type(uint8).max);
    }

    function _setInitializedVersion(uint8 version) private returns (bool) {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, and for the lowest level
        // of initializers, because in other contexts the contract may have been reentered.
        if (_initializing) {
            require(
                version == 1 && !AddressUpgradeable.isContract(address(this)),
                "Initializable: contract is already initialized"
            );
            return false;
        } else {
            require(_initialized < version, "Initializable: contract is already initialized");
            _initialized = version;
            return true;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155Upgradeable is IERC165Upgradeable {
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
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/draft-EIP712.sol)

pragma solidity ^0.8.0;

import "./ECDSAUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 *
 * @custom:storage-size 52
 */
abstract contract EIP712Upgradeable is Initializable {
    /* solhint-disable var-name-mixedcase */
    bytes32 private _HASHED_NAME;
    bytes32 private _HASHED_VERSION;
    bytes32 private constant _TYPE_HASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    function __EIP712_init(string memory name, string memory version) internal onlyInitializing {
        __EIP712_init_unchained(name, version);
    }

    function __EIP712_init_unchained(string memory name, string memory version) internal onlyInitializing {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        return _buildDomainSeparator(_TYPE_HASH, _EIP712NameHash(), _EIP712VersionHash());
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSAUpgradeable.toTypedDataHash(_domainSeparatorV4(), structHash);
    }

    /**
     * @dev The hash of the name parameter for the EIP712 domain.
     *
     * NOTE: This function reads from storage by default, but can be redefined to return a constant value if gas costs
     * are a concern.
     */
    function _EIP712NameHash() internal virtual view returns (bytes32) {
        return _HASHED_NAME;
    }

    /**
     * @dev The hash of the version parameter for the EIP712 domain.
     *
     * NOTE: This function reads from storage by default, but can be redefined to return a constant value if gas costs
     * are a concern.
     */
    function _EIP712VersionHash() internal virtual view returns (bytes32) {
        return _HASHED_VERSION;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../StringsUpgradeable.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSAUpgradeable {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", StringsUpgradeable.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
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