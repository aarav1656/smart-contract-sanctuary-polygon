//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// Interfaces
import "./IBot.sol";
import "./IBotMetadata.sol";
import "./IERC20Burnable.sol";
import "./ITokenPaymentSplitter.sol";
import "./IRewardsSpender.sol";

// Dependencies
import "./Managable.sol";
import "./LibBot.sol";

contract BotMinter is Managable, Pausable, ReentrancyGuard {
    address public botAddress;
    address public botMetadataAddress;
    address public treasuryAddress;
    address public oilAddress;
    address public rewardsSpenderAddress;

    uint32[] public cooldowns = [
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0
    ];
    mapping(address => uint32) public tokenPrices;
    mapping(address => uint256) public tokenDecimals;

    uint32[] public oilPrices = [
        165,
        170,
        180,
        190,
        200,
        210,
        225,
        235,
        250,
        265,
        265,
        265
    ];
    uint256 oilDecimals = 10 ** 18;
    uint32 public revealCooldown = uint32(5 days);
    DoubleToken public doubleTokenPrices;
    address public constant ZERO_ADDRESS = 0x0000000000000000000000000000000000000000;
    address public immutable BITS_ADDRESS;

    struct DoubleToken {
        uint128 matic;
        uint128 bits;
    }

    // events
    event ChangedBotAddress(address _addr);
    event ChangedBotMetadataAddress(address _addr);
    event ChangedTreasuryAddress(address _addr);
    event ChangedOilAddress(address _addr);
    event ChangedRewardsSpenderAddress(address _addr);
    event ChangedRevealCooldown(uint32 _cooldown);
    event ChangedCooldowns(uint32[] _cooldowns);
    event ChangedOilPrices(uint32[] _prices, uint256 _decimals);
    event AddedPaymentToken(address _addr, uint32 _price, uint256 _decimals);
    event RemovedPaymentToken(address _addr);
    event DoubleTokenPricesSet (uint128 _matic, uint128 _bits);
    event BotBreed(uint256 indexed _tokenId, uint256 indexed _matronId, uint256 indexed _sireId, uint256 _oilPrice, uint256 _maticPrice, uint256 _bitsPrice);
    event EarlyClaimBreedAmounts (uint256 indexed _earlyClaimId, uint256 indexed _tokenId, uint256 _oilClaim, uint256 _bitsClaim);

    constructor(
        address _botAddress,
        address _botMetadataAddress,
        address _treasuryAddress,
        address _oilAddress,
        address _bitAddress,
        address _rewardsSpenderAddress
    ) {
        _setBotAddress(_botAddress);
        _setBotMetadataAddress(_botMetadataAddress);
        _setTreasuryAddress(_treasuryAddress);
        _setOilAddress(_oilAddress);
        BITS_ADDRESS = _bitAddress;
        _setRewardsSpenderAddress(_rewardsSpenderAddress);

        _addManager(msg.sender);
    }

    function togglePause() external onlyManager {
        if(paused()) {
            _unpause();
        } else {
            _pause();
        }
    }

    function setCooldowns(uint32[] calldata _cooldowns) external onlyManager {
        cooldowns = _cooldowns;
        emit ChangedCooldowns(_cooldowns);
    }

    function setOilPrices(uint32[] calldata _prices, uint256 _decimals) external onlyManager {
        oilPrices = _prices;
        oilDecimals = _decimals;
        emit ChangedOilPrices(_prices, _decimals);
    }             

    function setBotAddress(address _addr) external onlyManager {
        _setBotAddress(_addr);
    }

    function setBotMetadataAddress(address _addr) external onlyManager {
        _setBotMetadataAddress(_addr);
    }    

    function setTreasuryAddress(address _addr) external onlyManager {
        _setTreasuryAddress(_addr);
    }  

    function setOilAddress(address _addr) external onlyManager {
        _setOilAddress(_addr);
    }      

    function setRevealCooldown(uint32 _cooldown) external onlyManager {
        revealCooldown = _cooldown;
        emit ChangedRevealCooldown(_cooldown);
    }

    function setRewardsSpenderAddress(address _addr) external onlyManager {
        _setRewardsSpenderAddress(_addr);
    }

    //To add native crypto - ETH, MATIC, use ZERO ADDRESS
    function addPayToken(address _addr, uint32 _price, uint256 _decimals) external onlyManager {
        tokenPrices[_addr] = _price;
        tokenDecimals[_addr] = _decimals;
        emit AddedPaymentToken(_addr, _price, _decimals);
    }

    function removePayToken(address _addr) external onlyManager {
        tokenPrices[_addr] = 0;
        tokenDecimals[_addr] = 0;
        emit RemovedPaymentToken(_addr);
    }

    function setDoubleTokenPrices (uint128 _matic, uint128 _bits) external onlyManager {
        doubleTokenPrices = DoubleToken(_matic,_bits);
        emit DoubleTokenPricesSet(_matic,_bits);
    }

    function breedWithMATIC(uint256 _matronId, uint256 _sireId) external whenNotPaused nonReentrant payable returns(uint256) {

        (uint _tokenId, uint _oilPrice ) = _breed(_matronId, _sireId);
        DoubleToken memory _doubleTokenPrices = doubleTokenPrices;
        require(_doubleTokenPrices.matic > 0 || _doubleTokenPrices.bits > 0, "incorrect prices");

        if(_doubleTokenPrices.matic > 0){
            require(msg.value == _doubleTokenPrices.matic, "not enough native token");
            (bool success,) = treasuryAddress.call{value: msg.value}(
                abi.encodeWithSignature("split(address,address,uint256)", ZERO_ADDRESS, msg.sender, _doubleTokenPrices.matic)
            );
            require(success, "Splitter call fail");
        }
        if(_doubleTokenPrices.bits > 0){
            require(IERC20(BITS_ADDRESS).transferFrom(msg.sender, address(this), _doubleTokenPrices.bits));
            IERC20(BITS_ADDRESS).approve(treasuryAddress, _doubleTokenPrices.bits);
            ITokenPaymentSplitter(treasuryAddress).split(BITS_ADDRESS, msg.sender, _doubleTokenPrices.bits);
        }
        
        // Burning tokens
        IERC20Burnable(oilAddress).burnFrom(msg.sender, _oilPrice);

        return _tokenId;
    }
    
    function breedWithEarlyClaimAndMATIC(
        uint256 _matronId,
        uint256 _sireId,
        IRewardsSpender.EarlyClaim calldata _earlyClaim,
        bytes calldata _signature
    ) external whenNotPaused nonReentrant payable returns(uint256) {
        require(_earlyClaim.addr == msg.sender, "not claim owner");
        require(address(this) == _earlyClaim.contractAddr, "not allowed");
        require(_earlyClaim.parts.length == 1 || _earlyClaim.parts.length == 2, "wrong token number");

        (uint _tokenId, uint _oilPrice ) = _breed(_matronId, _sireId);
        DoubleToken memory _doubleTokenPrices = doubleTokenPrices;
        require(_doubleTokenPrices.matic > 0 || _doubleTokenPrices.bits > 0, "incorrect prices");

        if(_doubleTokenPrices.matic > 0){
            require(msg.value == _doubleTokenPrices.matic, "not enough native token");
            (bool success,) = treasuryAddress.call{value: msg.value}(
                abi.encodeWithSignature("split(address,address,uint256)", ZERO_ADDRESS, msg.sender, _doubleTokenPrices.matic)
            );
            require(success, "Splitter call fail");
        }

        IRewardsSpender.Rewarder memory _rewarder1 = IRewardsSpender(rewardsSpenderAddress).rewarders(_earlyClaim.parts[0].name);
        require(_rewarder1.addr == BITS_ADDRESS || _rewarder1.addr == oilAddress, "wrong token");
        if(_rewarder1.addr == BITS_ADDRESS){
            require(_doubleTokenPrices.bits > 0, "incorrect prices");
        }
        _checkToken(
            _rewarder1.addr,
            _doubleTokenPrices.bits,
            _oilPrice,
            _earlyClaim.parts[0].amountUserWallet,
            _earlyClaim.parts[0].amountClaim,
            BITS_ADDRESS
        );

        if(_earlyClaim.parts.length == 2){
            IRewardsSpender.Rewarder memory _rewarder2 = IRewardsSpender(rewardsSpenderAddress).rewarders(_earlyClaim.parts[1].name);
            require(_rewarder2.addr == BITS_ADDRESS || _rewarder2.addr == oilAddress, "wrong token");
            require(_rewarder1.addr != _rewarder2.addr, "same token");
            require(_doubleTokenPrices.bits > 0, "incorrect prices");
            _checkToken(
                _rewarder2.addr,
                _doubleTokenPrices.bits,
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

        if(_doubleTokenPrices.bits > 0){
            require(IERC20(BITS_ADDRESS).transferFrom(msg.sender, address(this), _doubleTokenPrices.bits));
            IERC20(BITS_ADDRESS).approve(treasuryAddress, _doubleTokenPrices.bits);
            ITokenPaymentSplitter(treasuryAddress).split(BITS_ADDRESS, msg.sender, _doubleTokenPrices.bits);
        }

       // Burning tokens
        IERC20Burnable(oilAddress).burnFrom(msg.sender, _oilPrice);

        if (_rewarder1.addr == BITS_ADDRESS){
            if(_earlyClaim.parts.length == 1){
                emit EarlyClaimBreedAmounts(_earlyClaim.id, _tokenId, 0, _earlyClaim.parts[0].amountClaim);
            } else {
                emit EarlyClaimBreedAmounts(_earlyClaim.id, _tokenId, _earlyClaim.parts[1].amountClaim, _earlyClaim.parts[0].amountClaim);
            }
        } else {
            if(_earlyClaim.parts.length == 1){
                emit EarlyClaimBreedAmounts(_earlyClaim.id, _tokenId, _earlyClaim.parts[0].amountClaim, 0);
            } else {
                emit EarlyClaimBreedAmounts(_earlyClaim.id, _tokenId, _earlyClaim.parts[0].amountClaim, _earlyClaim.parts[1].amountClaim);                
            }
        }

        return _tokenId;
    }

    function _transferPayments(address _token, uint _tokenPrice, uint _oilPrice) internal {
        // Transfering payments
        require(IERC20(_token).transferFrom(msg.sender, address(this), _tokenPrice));
        IERC20(_token).approve(treasuryAddress, _tokenPrice);
        ITokenPaymentSplitter(treasuryAddress).split(_token, msg.sender, _tokenPrice);
        
        // Burning tokens
        IERC20Burnable(oilAddress).burnFrom(msg.sender, _oilPrice);
    }

    function _checkToken(address _rewardedToken, uint _tokenPrice, uint _oilPrice, uint _amountUserWallet, uint _amountClaim, address _token) internal pure {
        if(_rewardedToken == _token){
            require(( _amountUserWallet + _amountClaim) == _tokenPrice, "wrong ac");
        } else {
            require(( _amountUserWallet + _amountClaim) == _oilPrice, "wrong ac");
        }
    }

    function _breed(uint256 _matronId, uint256 _sireId) internal returns(uint256, uint256) {
        require(_matronId != _sireId, "matron,sire:same");
        require(_bot().ownerOf(_matronId) == msg.sender, "not owner");
        require(_bot().ownerOf(_sireId) == msg.sender, "not owner");    

        LibBot.Bot memory matron = _botMetadata().getBot(_matronId);
        LibBot.Bot memory sire = _botMetadata().getBot(_sireId);

        require(_canBreed(matron), "matron:lim");
        require(_canBreed(sire), "sire:lim");
        require(_notCooldown(matron), "matron:cd");
        require(_notCooldown(sire), "sire:cd");
        require(_notRelatives(matron, sire), "relatives");      

        (
            uint256 _matronPrice, 
            uint256 _sirePrice
        ) = _breedPrices(matron, sire);

        // Calculating reveal cooldown
        uint32 _rCooldown = revealCooldown;
        if (matron.generation == 0 && sire.generation == 0) {
            _rCooldown = _rCooldown / 2;
        }

        // Creating a new bot
        uint256 tokenId = _bot().mint(msg.sender);
        {
            LibBot.Bot memory bot;
            bot.id = tokenId;
            bot.generation = 1;
            bot.matronId = uint64(_matronId);
            bot.sireId = uint64(_sireId);
            bot.revealCooldown = block.timestamp + _rCooldown;
            _botMetadata().setBot(tokenId, bot);
        }
        // Increasing breed amount for matron
        matron.breedCount += 1;
        matron.lastBreed = block.timestamp;
        _botMetadata().setBot(_matronId, matron);

        // Increasing breed amount for sire
        sire.breedCount += 1;
        sire.lastBreed = block.timestamp;
        _botMetadata().setBot(_sireId, sire);

        DoubleToken memory _doubleTokenPrices = doubleTokenPrices;
        emit BotBreed(
            tokenId, 
            _matronId,
            _sireId,
            _matronPrice + _sirePrice, 
            uint(_doubleTokenPrices.matic),
            uint(_doubleTokenPrices.bits)
        );

        return (tokenId, (_matronPrice + _sirePrice));
    }

    function breedDoublePrices(
        uint256 _matronId, 
        uint256 _sireId 
    ) public view returns(uint256 _maticPrice, uint256 _bitsPrice, uint256 _oilPrice) {
        LibBot.Bot memory matron = _botMetadata().getBot(_matronId);
        LibBot.Bot memory sire = _botMetadata().getBot(_sireId);        

        (uint256 _matronOilPrice, uint256 _sireOilPrice) = _breedPrices(matron, sire);
        _oilPrice = _matronOilPrice + _sireOilPrice;
        _maticPrice = doubleTokenPrices.matic;
        _bitsPrice = doubleTokenPrices.bits;
        return (_maticPrice, _bitsPrice, _oilPrice);
    }    
    
    function _breedPrices(LibBot.Bot memory matron, LibBot.Bot memory sire) internal view returns(uint256, uint256) {
        // Calculating oilPrices
        uint256 matronPrice = oilPrices[matron.breedCount] * oilDecimals;
        uint256 sirePrice = oilPrices[sire.breedCount] * oilDecimals;
        require(matronPrice > 0 && sirePrice > 0, "incorrect prices");

        return (matronPrice, sirePrice);
    }

    function canBreed(uint256 _matronId, uint256 _sireId) public view returns(bool) {
        if (_matronId == _sireId) {
            return false;
        }

        LibBot.Bot memory matron = _botMetadata().getBot(_matronId);
        LibBot.Bot memory sire = _botMetadata().getBot(_sireId);

        return _canBreed(matron) && _canBreed(sire) && _notCooldown(matron) && _notCooldown(sire) && _notRelatives(matron, sire);
    }

    function canBreedMultiple(uint256 _matronId, uint256[] calldata _siresIds) public view returns(bool[] memory) {
        bool[] memory _canBreedWith = new bool[](_siresIds.length);
        for(uint256 i = 0; i < _siresIds.length; i++) {
            _canBreedWith[i] = canBreed(_matronId, _siresIds[i]);
        }

        return _canBreedWith;
    }

    function _bot() private view returns(IBot) {
        return IBot(botAddress);
    }

    function _botMetadata() private view returns(IBotMetadata) {
        return IBotMetadata(botMetadataAddress);
    }

    function _notCooldown(LibBot.Bot memory _b) private view returns(bool) {
        if (_b.breedCount == 0) {
            return true;
        }

        uint32 _cooldown = cooldowns[_b.breedCount];
        if (_cooldown == 0) {
            return true;
        }

        return _b.lastBreed + _cooldown < block.timestamp;
    }

    function _canBreed(LibBot.Bot memory _b) private pure returns(bool) {
        if (_b.generation == 0 && _b.breedCount < 12) {
            return true;
        }

        return _b.breedCount < 7;
    }

    function _notRelatives(LibBot.Bot memory _matron, LibBot.Bot memory _sire) private pure returns(bool) {        
        if (_matron.generation == 0 && _sire.generation == 0) {
            return true;
        }
        
        // If they have same partens it's can't be done
        if (
            (_matron.matronId == _sire.matronId && _matron.sireId == _sire.sireId) || 
            (_matron.sireId == _sire.matronId && _matron.matronId == _sire.sireId)
        ) {
            return false;
        }

        // You can't breed with you kids
        if (_matron.id == _sire.matronId || _matron.id == _sire.sireId) {
            return false;
        }

        if (_sire.id == _matron.matronId || _sire.id == _matron.sireId) {
            return false;
        }

        return true;
    }

    //
    // Private functions
    //

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

    function _setOilAddress(address _addr) internal {
        oilAddress = _addr;
        emit ChangedOilAddress(_addr);
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