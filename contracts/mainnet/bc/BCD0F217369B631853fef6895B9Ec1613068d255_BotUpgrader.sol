//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// Interfaces
import "./Modifiers/IModifier.sol";
import "./IBot.sol";
import "./IBotMetadata.sol";
import "./IERC20Burnable.sol";
import "./ITokenPaymentSplitter.sol";
import "./IBotUpgradeCalculator.sol";
import "./IRewardsSpender.sol";

// Dependencies
import "./Managable.sol";
import "./LibBot.sol";

contract BotUpgrader is Managable, Pausable, ReentrancyGuard {
    address public botAddress;
    address public botMetadataAddress;
    address public treasuryAddress;
    address public oilAddress;
    address public calculatorAddress;
    address public modifierAddress;
    address public rewardsSpenderAddress;
    uint public modifierId;

    uint16[] public upPrices;
    address[] public items;
    mapping(uint => uint32[]) public maxTier; // Producer Number -> Detail Max Tier
    mapping(address => uint32[]) public tokenPrices;
    mapping(address => uint256) public tokenDecimals;
    address public constant ZERO_ADDRESS = 0x0000000000000000000000000000000000000000;
    address public immutable BITS_ADDRESS;

    // events
    event ChangedBotAddress(address _addr);
    event ChangedBotMetadataAddress(address _addr);
    event ChangedTreasuryAddress(address _addr);
    event ChangedCalculatorAddress(address _addr);
    event ChangedOilAddress(address _addr);
    event ChangedModifierAddress(address _addr);
    event ChangedRewardsSpenderAddress(address _addr);
    event ChangedModifierId(uint _id);
    event ChangedUpPrices(uint16[] _prices);
    event ChangedMaxTier(uint _producer, uint32[] _maxTier);
    event AddedItemsAddress(address _addr);
    event RemovedItemsAddress(address _addr);
    event AddedPaymentToken(address _addr, uint256 _decimals);
    event RemovedPaymentToken(address _addr);
    event BotUpgraded(uint _botToUpgradeId, uint _upgradedDetail, uint _newDetailTier, uint _oilPrice, uint _maticPrice, uint _bitsPrice);
    event EarlyClaimUpgradeAmounts (uint256 indexed _earlyClaimId, uint256 indexed _botToUpgradeId, uint256 _oilClaim, uint256 _bitsClaim);

    constructor(
        address _botAddress,
        address _botMetadataAddress,
        address _treasuryAddress,
        address _oilAddress,
        address _bitAddress,
        address _botUpgradeCalculatorAddress,
        address _rewardsSpenderAddress,        
        address _modifierAddress,
        uint _modifierId
    ) {
        _setBotAddress(_botAddress);
        _setBotMetadataAddress(_botMetadataAddress);
        _setTreasuryAddress(_treasuryAddress);
        _setOilAddress(_oilAddress);
        BITS_ADDRESS = _bitAddress;
        _setCalculatorAddress(_botUpgradeCalculatorAddress);
        _setRewardsSpenderAddress(_rewardsSpenderAddress);
        _setModifierAddress(_modifierAddress);
        _setModifierId(_modifierId);
        _addManager(msg.sender);
    }

    /// @param _detailToUpgrade is Ears = 1; Mask = 2; Eyes = 3; Body = 4; Legs = 5; Arms = 6; Aerial = 7
    function upgradeWithMATIC(
        uint256 _botToUpgradeId,
        uint256[] calldata _botsToBurn,
        uint256 _detailToUpgrade,
        bool modifierExists
    ) external payable whenNotPaused nonReentrant{
        (uint _bitsPrice, uint _maticPrice, uint _oilPrice) = _upgrade(_botToUpgradeId, _botsToBurn, _detailToUpgrade, modifierExists);
        if (_bitsPrice > 0) {
            _transferPayments(BITS_ADDRESS, _bitsPrice);
        }
        if (_maticPrice > 0){
            require(msg.value == _maticPrice, "not enough native token");
            (bool success,) = treasuryAddress.call{value: msg.value}(
                abi.encodeWithSignature("split(address,address,uint256)", ZERO_ADDRESS, msg.sender, _maticPrice)
            );
            require(success, "Splitter call fail");
        }
        // Burning tokens
        IERC20Burnable(oilAddress).burnFrom(msg.sender, _oilPrice);
    }

    /// @param _detailToUpgrade is Ears = 1; Mask = 2; Eyes = 3; Body = 4; Legs = 5; Arms = 6; Aerial = 7
    function upgradeWithEarlyClaim(
        uint256 _botToUpgradeId,
        uint256[] calldata _botsToBurn,
        uint256 _detailToUpgrade,
        bool modifierExists,
        IRewardsSpender.EarlyClaim calldata _earlyClaim,
        bytes calldata _signature
    ) external payable whenNotPaused nonReentrant {
        require(_earlyClaim.addr == msg.sender, "not claim owner");
        require(address(this) == _earlyClaim.contractAddr, "not allowed");
        require(_earlyClaim.parts.length == 1 || _earlyClaim.parts.length == 2, "wrong token number");

        (uint _bitsPrice, uint _maticPrice, uint _oilPrice) = _upgrade(_botToUpgradeId, _botsToBurn, _detailToUpgrade, modifierExists);

        if (_maticPrice > 0){
            require(msg.value == _maticPrice, "not enough native token");
            (bool success,) = treasuryAddress.call{value: msg.value}(
                abi.encodeWithSignature("split(address,address,uint256)", ZERO_ADDRESS, msg.sender, _maticPrice)
            );
            require(success, "Splitter call fail");
        }

        IRewardsSpender.Rewarder memory _rewarder1 = IRewardsSpender(rewardsSpenderAddress).rewarders(_earlyClaim.parts[0].name);
        require(_rewarder1.addr == BITS_ADDRESS || _rewarder1.addr == oilAddress, "wrong token");
        if(_rewarder1.addr == BITS_ADDRESS){
            require(_bitsPrice > 0, "incorrect prices");
        }

        _checkToken(
            _rewarder1.addr,
            _bitsPrice,
            _oilPrice,
            _earlyClaim.parts[0].amountUserWallet,
            _earlyClaim.parts[0].amountClaim,
            BITS_ADDRESS
        );

        if(_earlyClaim.parts.length == 2){
            IRewardsSpender.Rewarder memory _rewarder2 = IRewardsSpender(rewardsSpenderAddress).rewarders(_earlyClaim.parts[1].name);
            require(_rewarder2.addr == BITS_ADDRESS || _rewarder2.addr == oilAddress, "wrong token");
            require(_rewarder1.addr != _rewarder2.addr, "same token");
            require(_bitsPrice > 0, "incorrect prices");


            _checkToken(
                _rewarder2.addr,
                _bitsPrice,
                _oilPrice,
                _earlyClaim.parts[1].amountUserWallet,
                _earlyClaim.parts[1].amountClaim,
                BITS_ADDRESS
            );
        }
        {
            try IRewardsSpender(rewardsSpenderAddress).earlyClaim(_earlyClaim, _signature) returns (bool result) {
                require(result, "EarlyClaim fail");
            } catch Error (string memory _reason) {
                revert(_reason);
            } catch {
                revert();
            }
        }
        if(_bitsPrice > 0){
            _transferPayments(BITS_ADDRESS, _bitsPrice);
        }

        // Burning tokens
        IERC20Burnable(oilAddress).burnFrom(msg.sender, _oilPrice);

        if (_rewarder1.addr == BITS_ADDRESS){
            if(_earlyClaim.parts.length == 1){
                emit EarlyClaimUpgradeAmounts(_earlyClaim.id, _botToUpgradeId, 0, _earlyClaim.parts[0].amountClaim);
            } else {
                emit EarlyClaimUpgradeAmounts(_earlyClaim.id, _botToUpgradeId, _earlyClaim.parts[1].amountClaim, _earlyClaim.parts[0].amountClaim);
            }
        } else {
            if(_earlyClaim.parts.length == 1){
                emit EarlyClaimUpgradeAmounts(_earlyClaim.id, _botToUpgradeId, _earlyClaim.parts[0].amountClaim, 0);
            } else {
                emit EarlyClaimUpgradeAmounts(_earlyClaim.id, _botToUpgradeId, _earlyClaim.parts[0].amountClaim, _earlyClaim.parts[1].amountClaim);                
            }
        }

    }

    function _checkToken(address _rewardedToken, uint _tokenPrice, uint _oilPrice, uint _amountUserWallet, uint _amountClaim, address _token) internal pure {
        if(_rewardedToken == _token){
            require(( _amountUserWallet + _amountClaim) == _tokenPrice, "wrong ac");
        } else {
            require(( _amountUserWallet + _amountClaim) == _oilPrice, "wrong ac");
        }
    }

    function _transferPayments(address _token, uint _tokenPrice) internal {
        // Transferring payments
        require(IERC20(_token).transferFrom(msg.sender, address(this), _tokenPrice));
        IERC20(_token).approve(treasuryAddress, _tokenPrice);
        ITokenPaymentSplitter(treasuryAddress).split(_token, msg.sender, _tokenPrice);        
    }    

    /// @param _detailToUpgrade is Ears = 1; Mask = 2; Eyes = 3; Body = 4; Legs = 5; Arms = 6; Aerial = 7
    function _upgrade(
        uint256 _botToUpgradeId,
        uint256[] calldata _botsToBurn,
        uint256 _detailToUpgrade,
        bool modifierExists
    ) internal returns (uint _bitsPrice, uint _maticPrice, uint _oilPrice){
        address _sender = msg.sender;
        require(_botsToBurn.length >= 1, "no bots");
        require(_botsToBurn.length <= 100, "too much bots");
        require(_botOwnerAndNotSameUpgradeBurnBot(_botToUpgradeId, _botsToBurn, _sender), "bots:not owner or same burn upgrade bot");

        (uint _botDetailTier, uint _botProducer) = _getBotDetailTier(_botToUpgradeId, _detailToUpgrade);
        uint _upPoints;
        bool _allGenesExist;
        (_upPoints, _allGenesExist) = _getUpPoints(_botsToBurn, _botProducer, modifierExists);
        require(_allGenesExist == true, "Bot to burn does not exist");

        require(_upPoints >=  uint(upPrices[_botDetailTier-1]), "Bots to burn are not enough");

        uint _botNextTier = _getNextTier(_detailToUpgrade, _botDetailTier, _botProducer, _upPoints);
        (_bitsPrice, _maticPrice, _oilPrice) = getUpgradePrices(_botDetailTier, _botNextTier);

        //Burning modifier
        if(modifierExists){
            IModifier(modifierAddress).burn(_sender, modifierId, 1);
        }
    
        //Burn bots
        _burnBots(_botsToBurn);

        _upgradeDetail(_botToUpgradeId, _detailToUpgrade, _botNextTier);
        emit BotUpgraded(_botToUpgradeId, _detailToUpgrade, _botNextTier, _oilPrice, _maticPrice, _bitsPrice);

        return (_bitsPrice, _maticPrice, _oilPrice);
    }
    
    function getUpgradeResults(
        uint256 _botToUpgradeId,
        uint256[] calldata _botsToBurn,
        uint256 _detailToUpgrade,
        address _owner,
        bool modifierExists
    ) external view returns(bool _canUpgrade, uint _detailNextTier) {
        if(_botsToBurn.length < 1){return (false, 0);}
        if(_botsToBurn.length > 100){return (false, 0);}
        if(_botOwnerAndNotSameUpgradeBurnBot(_botToUpgradeId, _botsToBurn, _owner) == false){ return (false, 0);}

        (uint _botDetailTier, uint _botProducer, bool _upgradability) = _getTierAndUpgradability(_botToUpgradeId, _detailToUpgrade);
        if(_upgradability == false){return (false, 0);}
        (uint _upPoints, bool _allGenesExist) = _getUpPoints(_botsToBurn,_botProducer, modifierExists);
        if (_allGenesExist == false){return (false, 0);}
        if(_upPoints <  uint(upPrices[_botDetailTier-1])){return (false, 0);}
        uint _nextTier = _getNextTier(_detailToUpgrade, _botDetailTier, _botProducer, _upPoints);
        return (true, _nextTier);
    }

    /// @param _botDetailTier - current Tier of bot detail
    function getUpgradePrices(
        uint256 _botDetailTier,
        uint256 _botNextTier
    ) public view returns(uint256 _bitsPrice, uint256 _maticPrice, uint256 _oilPrice) {
        address _oilAddress = oilAddress;
        // Calculating Bits price
        uint256 _bitsDecimals = tokenDecimals[BITS_ADDRESS];
        if (_bitsDecimals > 0){
            require((_botDetailTier) <= tokenPrices[BITS_ADDRESS].length, "not allowed bits");
            for(uint i = 0; _botDetailTier + i < _botNextTier; i++){
                _bitsPrice += uint(tokenPrices[BITS_ADDRESS][_botDetailTier-1 + i]);
            }
            _bitsPrice *= _bitsDecimals;
        }

        // Calculating MATIC price
        uint256 _maticDecimals = tokenDecimals[ZERO_ADDRESS];
        if (_maticDecimals > 0){
            require((_botDetailTier) <= tokenPrices[ZERO_ADDRESS].length, "not allowed matic");
            for(uint i = 0; _botDetailTier + i < _botNextTier; i++){
                _maticPrice += uint(tokenPrices[ZERO_ADDRESS][_botDetailTier-1 + i]);
            }
            _maticPrice *= _maticDecimals;
        }

        require(_bitsPrice > 0 || _maticPrice > 0, "payment calculation error");

        //Calculating oil price
        uint256 _oilDecimals = tokenDecimals[_oilAddress];
        require((_botDetailTier) <= tokenPrices[_oilAddress].length && _oilDecimals > 0, "not allowed oil");
        for(uint i = 0; _botDetailTier + i < _botNextTier; i++){
            _oilPrice += uint(tokenPrices[_oilAddress][_botDetailTier-1 + i]);
        }
        _oilPrice *= _oilDecimals;

        return (_bitsPrice, _maticPrice, _oilPrice);
    }

    function togglePause() external onlyManager {
        if(paused()) {
            _unpause();
        } else {
            _pause();
        }
    }

    function setBotAddress(address _addr) external onlyManager {
        _setBotAddress(_addr);
    }

    function setBotMetadataAddress(address _addr) external onlyManager {
        _setBotMetadataAddress(_addr);
    }    

    function setCalculatorAddress(address _addr) external onlyManager {
        _setCalculatorAddress(_addr);
    }  

    function setTreasuryAddress(address _addr) external onlyManager {
        _setTreasuryAddress(_addr);
    }  

    function setOilAddress(address _addr) external onlyManager {
        _setOilAddress(_addr);
    }

    function setRewardsSpenderAddress(address _addr) external onlyManager {
        _setRewardsSpenderAddress(_addr);
    }           

    function setModifierAddress(address _addr) external onlyManager {
        _setModifierAddress(_addr);
    }      

    function setModifierId(uint _id) external onlyManager {
        _setModifierId(_id);
    }

    function addItemsAddress(address _addr) external onlyManager {
        for (uint i = 0; i < items.length; i++){
            require(items[i] != _addr, "already added");
        }
        items.push(_addr);
        emit AddedItemsAddress(_addr);
    }      

    function removeItemsAddress(address _addr) external onlyManager {
        uint _length = items.length;
        bool _found = false;
        if(_length == 1){
            require(items[0] == _addr, "no such address");
            items.pop();
            _found = true;
        } else{
            for (uint i = 0; i < _length; i++){
                if(items[i] == _addr){
                    _found = true;
                    items[i] = items[_length - 1];
                    items.pop();
                    break;
                }
            }
        }
        require(_found == true, "no such address");
        emit RemovedItemsAddress(_addr);
    }      

    //To add native crypto - ETH, MATIC, use ZERO ADDRESS
    ///@notice @param _prices from 0 to its length represents price for upgrade from 1 to 2 and up to maxtier-1 to maxtier  
    function addPayToken(address _addr, uint32[] calldata _prices, uint256 _decimals) external onlyManager {
        for (uint i = 0; i < _prices.length; i++){
            tokenPrices[_addr].push(_prices[i]);
        }
        tokenDecimals[_addr] = _decimals;
        emit AddedPaymentToken(_addr, _decimals);
    }

    function removePayToken(address _addr) external onlyManager {
        uint length = tokenPrices[_addr].length;
        for (uint i = 0; i < length; i++){
            tokenPrices[_addr].pop();
        }
        tokenDecimals[_addr] = 0;
        emit RemovedPaymentToken(_addr);
    }

    function setUpPrices (uint16[] calldata _prices) external onlyManager {
        uint _length = upPrices.length;
        if (_length != 0){
            for (uint i = 0; i < _length; i++){
                upPrices.pop();
            }
        }
        for (uint i = 0; i < _prices.length; i++){
            upPrices.push(_prices[i]);
        }
        emit ChangedUpPrices(_prices);
    }

    ///@notice @param _maxTier from 0 to its length represents maxTier for bot producers as represented in BotBreeder, 
    ///                         _maxTier[0] for producer = 1, _maxTier[1] for producer = 2, etc.    
    function setMaxTier (uint _producer, uint32[] calldata _maxTier) external onlyManager {
        uint _length = maxTier[_producer].length;
        if (_length != 0){
            for (uint i = 0; i < _length; i++){
                maxTier[_producer].pop();
            }
        }
        for (uint i = 0; i < _maxTier.length; i++){
            maxTier[_producer].push(_maxTier[i]);
        }
        emit ChangedMaxTier(_producer, _maxTier);
    }
    
    function getMaxTier (uint _producer) public view returns(uint32[] memory _maxTier){
        return maxTier[_producer];
    }    

    function getTokenPrices (address _token) public view returns(uint32[] memory _tokenPrices){
        return tokenPrices[_token];
    }    

    function getItemsAddresses() external view returns (address[] memory _itemAddresses) {
        return items;
    }      

   function getUpPrices() external view returns (uint16[] memory _upPrices) {
        return upPrices;
    }      

    function _bot() private view returns(IBot) {
        return IBot(botAddress);
    }

    function _botMetadata() private view returns(IBotMetadata) {
        return IBotMetadata(botMetadataAddress);
    }

    function _botOwnerAndNotSameUpgradeBurnBot(uint256 _botToUpgradeId, uint256[] memory _botIds, address _owner) private view returns(bool) {
        for (uint i = 0; i < _botIds.length; i++){
                if(_botIds[i] == _botToUpgradeId){
                    return false;
                }
                if(_bot().ownerOf(_botIds[i]) != _owner){
                    return false;
                }    
        }
        if(_bot().ownerOf(_botToUpgradeId) != _owner){
            return false;
        }    
        return true;
    }    

    function _getBotDetailTier(uint _botToUpgradeId, uint _detailToUpgrade) private view returns(uint _tier, uint _producer){
        uint _botToUpgradeGene = _botMetadata().getBot(_botToUpgradeId).genes;
        require(_botToUpgradeGene != 0, "Bot does not exist");
        (bool _detailExists, uint _botProducer, uint _botDetailTier) = IBotUpgradeCalculator(calculatorAddress).getBotTierAndProducer(_botToUpgradeGene, _detailToUpgrade);
        require(_detailExists, "Bot detail does not exist");
        require(_botDetailTier < maxTier[_botProducer][_detailToUpgrade-1], "Bot already max Tier");
        return (_botDetailTier, _botProducer);
    }

    function _getTierAndUpgradability(uint _botToUpgradeId, uint _detailToUpgrade) private view returns(uint _tier, uint _producer, bool _upgradability){
        uint _botToUpgradeGene = _botMetadata().getBot(_botToUpgradeId).genes;
        if(_botToUpgradeGene == 0){return (0, 0, false);}
        (bool _detailExists, uint _botProducer, uint _botDetailTier) = IBotUpgradeCalculator(calculatorAddress).getBotTierAndProducer(_botToUpgradeGene, _detailToUpgrade);
        if(_detailExists == false){return (0, 0, false);}
        if(_botDetailTier >= maxTier[_botProducer][_detailToUpgrade-1]){return (0, 0, false);}
        return (_botDetailTier, _botProducer, true);
    }
    
    function _getUpPoints(
        uint256[] calldata _botsToBurn,
        uint _botToUpgradeProducer,
        bool modifierExists
    ) private view returns(uint _upPoints, bool _allGenesExist){
        _allGenesExist = true;
        if(modifierExists){
            for (uint i = 0; i < _botsToBurn.length; i++){
                uint gene = _botMetadata().getBot(_botsToBurn[i]).genes;
                if(gene == 0){_allGenesExist = false;}
                uint _points = IBotUpgradeCalculator(calculatorAddress).getModifiedUpPoints(gene, _botToUpgradeProducer);
                _upPoints += _points;
            }
        } else {
            for (uint i = 0; i < _botsToBurn.length; i++){
                uint gene = _botMetadata().getBot(_botsToBurn[i]).genes;
                if(gene == 0){_allGenesExist = false;}
                uint _points = IBotUpgradeCalculator(calculatorAddress).getUpPoints(gene);
                _upPoints += _points;
            }
        }
        return (_upPoints, _allGenesExist);   
    }

    function _getNextTier(uint _detailToUpgrade, uint _botDetailTier, uint _botProducer, uint _upPoints) private view returns(uint){
        uint i = 0;
        while(_upPoints > 0){
            if(_upPoints >= upPrices[_botDetailTier-1 + i]){
                _upPoints -= upPrices[_botDetailTier-1 + i];
                i++;            
            } else {
                break;
            }
            if(_botDetailTier + i == maxTier[_botProducer][_detailToUpgrade-1]){
                break;
            }
        }
        uint _botNextTier = _botDetailTier + i;
        return _botNextTier;
    }

    function _burnBots(uint256[] memory _botIds) private {
        for (uint i = 0; i < _botIds.length; i++){
            _bot().burn(_botIds[i]);
        }
    }

    function _upgradeDetail(uint _botToUpgradeId, uint _detailToUpgrade, uint _botNextTier) private {
        LibBot.Bot memory _botMeta = _botMetadata().getBot(_botToUpgradeId);
        uint _botToUpgradeGene = _botMeta.genes;
        uint _upgradedGene = IBotUpgradeCalculator(calculatorAddress).getUpgradedGene(_botToUpgradeGene, _detailToUpgrade, _botNextTier);
        _botMeta.genes = _upgradedGene;
        _botMetadata().setBot(_botToUpgradeId, _botMeta);
    }    

    function _setBotAddress(address _addr) internal {
        botAddress = _addr;
        emit ChangedBotAddress(_addr);
    }

    function _setBotMetadataAddress(address _addr) internal {
        botMetadataAddress = _addr;
        emit ChangedBotMetadataAddress(_addr);
    }    

    function _setTreasuryAddress(address _addr) internal {
        treasuryAddress = _addr;
        emit ChangedTreasuryAddress(_addr);
    }   

    function _setCalculatorAddress(address _addr) internal {
        calculatorAddress = _addr;
        emit ChangedCalculatorAddress(_addr);
    }   

    function _setOilAddress(address _addr) internal {
        oilAddress = _addr;
        emit ChangedOilAddress(_addr);
    }

    function _setModifierAddress(address _addr) internal {
        modifierAddress = _addr;
        emit ChangedModifierAddress(_addr);
    }

    function _setModifierId(uint _id) internal {
        modifierId = _id;
        emit ChangedModifierId(_id);
    }

    function _setRewardsSpenderAddress(address _addr) internal {
        rewardsSpenderAddress = _addr;
        emit ChangedRewardsSpenderAddress(_addr);
    }
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
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
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
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
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
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
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

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IModifier {
    function burn(address account, uint256 id, uint256 value) external ;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IBot is IERC721 {
    function mint(address _to) external returns(uint256);
    function mintTokenId(address _to, uint256 _tokenId) external;
    function burn(uint256 tokenId) external;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./LibBot.sol";

interface IBotMetadata {
    function setBot(uint256 _tokenId, LibBot.Bot calldata _bot) external;
    function getBot(uint256 _tokenId) external view returns(LibBot.Bot memory);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC20Burnable is IERC20 {
    function burn(uint256 amount) external;
    function burnFrom(address account, uint256 amount) external;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface ITokenPaymentSplitter {
    function split(address _token, address _sender, uint256 _amount) external payable ;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IBotUpgradeCalculator {
    function getBotTierAndProducer(uint _genes, uint _detailToUpgrade) external pure returns (bool _detailExists, uint _producer, uint _tier) ;

    function getUpPoints(uint _genes) external pure returns (uint _upPoints) ;

    function getModifiedUpPoints(uint _genes, uint _botToUpgradeProducer) external pure returns (uint _upPoints);

    function getUpgradedGene(uint _genes, uint _detailToUpgrade, uint _botNextTier) external pure returns (uint);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IRewardsSpender {

    struct EarlyClaim {
        uint256 id;
        address addr;
        address contractAddr;
        uint256 deadline;
        EarlyPart[] parts;
    }

    struct EarlyPart {
        string name;
        uint256 id;
        uint256 amountUserWallet;
        uint256 amountClaim;
    }

    struct Rewarder {
        address addr;
        RewardType typ;
    }

    enum RewardType{ERC20, ERC1155}

    function earlyClaim(EarlyClaim calldata _earlyClaim, bytes calldata _signature) external returns (bool);

    function rewarders(string calldata _name) external view returns (Rewarder calldata);
        
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Managable {
    mapping(address => bool) private managers;
    address[] private managersAddresses;

    event AddedManager(address _address);
    event RemovedManager(address _address);

    modifier onlyManager() {
        require(managers[msg.sender], "caller is not manager");
        _;
    }

    function getManagers() public view returns (address[] memory) {
        return managersAddresses;
    }

    function transferManager(address _manager) external onlyManager {
        _removeManager(msg.sender);
        _addManager(_manager);
    }

    function addManager(address _manager) external onlyManager {
        _addManager(_manager);
    }

    function removeManager(address _manager) external onlyManager {
        uint index;
        for(uint i = 0; i < managersAddresses.length; i++) {
            if(managersAddresses[i] == _manager) {
                index = i;
                break;
            }
        }

        managersAddresses[index] = managersAddresses[managersAddresses.length - 1];
        managersAddresses.pop();

        _removeManager(_manager);
    }

    function _addManager(address _manager) internal {
        managers[_manager] = true;
        managersAddresses.push(_manager);
        emit AddedManager(_manager);
    }

    function _removeManager(address _manager) internal {
        managers[_manager] = false;
        emit RemovedManager(_manager);
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

library LibBot {
    struct Bot {
        uint256 id;
        uint256 genes;
        uint256 birthTime;
        uint64 matronId;
        uint64 sireId;
        uint8 generation;
        uint8 breedCount;
        uint256 lastBreed;
        uint256 revealCooldown;
    }

    function from(Bot calldata bot) public pure returns (uint256[] memory) {
        uint256[] memory _data = new uint256[](9);
        _data[0] = bot.id;
        _data[1] = bot.genes;
        _data[2] = bot.birthTime;
        _data[3] = uint256(bot.matronId);
        _data[4] = uint256(bot.sireId);
        _data[5] = uint256(bot.generation);
        _data[6] = uint256(bot.breedCount);
        _data[7] = bot.lastBreed;
        _data[8] = bot.revealCooldown;

        return _data;
    }

    function into(uint256[] calldata data) public pure returns (Bot memory) {
        Bot memory bot = Bot({
            id: data[0],
            genes: data[1],
            birthTime: data[2],
            matronId: uint64(data[3]),
            sireId: uint64(data[4]),
            generation: uint8(data[5]),
            breedCount: uint8(data[6]),
            lastBreed: data[7],
            revealCooldown: data[8]      
        });

        return bot;
    }    
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