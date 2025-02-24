// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import {IERC20MetadataUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import {IERC20Upgradeable, SafeERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import { ReentrancyGuardUpgradeable } from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "./OwnablePausable.sol";
import "./StakingReward.sol";
import "./StockMargin.sol";
import {StockNftFactory, StockERC721} from "./StockERC721.sol";
import {IdentityNftFactory, IdentityERC721} from "./IdentityERC721.sol";

import "./interface/ITdex.sol";

contract PrivatePlacementMarket is OwnablePausable, ReentrancyGuardUpgradeable{
    using SafeERC20Upgradeable for IERC20Upgradeable;

    enum LaunchResult{INIT, SUCCESS, FAIL}

    event Buy(
        address indexed trader,
        uint256 indexed index,
        uint256 usdtAmount,
        uint256 ttAmountInUsdt,
        uint256 ttStakedAmount,
        uint256 stockMarginInUsdt,
        uint256 stockNftId
    );
    event WhitelistAdded(address[] addresses, bool[] inWhitelist);
    event BagChanged(uint256[] bag0, uint256[] bag1, uint256[] bag2, uint256[] bag3, uint256[] bag4);
    event MarginWithdrawn(address indexed withdrawer, uint256 principal, uint256 compensation);
    event ClaimAmbassadorReward(uint256 side, address indexed ambassador, uint256 reward);
    
    struct Bag {
        uint256 amount;
        uint256 ttValue;
        uint256 stockValue;
        uint256 amountForStockMargin;
    }
    
    uint256 private TT_PRICE_PRECISION;

    address private _usdtIncomeAddress; //alias operationAccount
    address private _payOutAddress;
    address private _usdtAddress;
    address private _ttAddress;
    StockNftFactory private _stockNftFactory;
    StockMargin private _stockMargin;
    StakingReward private _stackingReward;
    ITdex private _tdex;

    mapping(uint256 => Bag) private _bags;
    uint256 private bagSize;
    LaunchResult private _launchResult; //0-init 1-suc 2-fail
    mapping(address => uint256) private _ambassadorReward;
    bool private _openBuyFunction;
    uint256[50] private __gap;
    mapping(uint256 => bool) private _bagBuyProp; //can buy
    IdentityNftFactory private _identityNftFactory;

    function initialize(
        address owner,
        address usdtAddress, 
        address ttAddress, 
        address usdtIncomeAddr,
        address payOutAddr,
        address stockNftFactoryAddress,
        address stockMarginAddress,
        address stackingRewardAddress,
        address tdexAddress,
        uint256 ttPricePrecision) public initializer {
            __OwnablePausable_init(owner); 
            __ReentrancyGuard_init();   
            _openBuyFunction = true;
            _launchResult = LaunchResult.INIT;
            _usdtAddress = usdtAddress;
            _ttAddress = ttAddress;
            _usdtIncomeAddress = usdtIncomeAddr;
            _payOutAddress = payOutAddr;
            _stockNftFactory = StockNftFactory(stockNftFactoryAddress);
            _stockMargin = StockMargin(stockMarginAddress);
            _stackingReward = StakingReward(stackingRewardAddress);
            _tdex = ITdex(tdexAddress);

            TT_PRICE_PRECISION = 10**ttPricePrecision;
            initBag();
            IERC20Upgradeable(_usdtAddress).safeApprove(stockMarginAddress, type(uint256).max);
    }

    function initBag() private {
        bagSize = 5;
        uint256 usdtPrecision = 10**IERC20MetadataUpgradeable(_usdtAddress).decimals();
        _bags[0] = Bag(99*usdtPrecision/10, 0, 99*usdtPrecision/10, 99*usdtPrecision/10);
        _bags[1] = Bag(1000*usdtPrecision, 500*usdtPrecision, 550*usdtPrecision, 500*usdtPrecision);
        _bags[2] = Bag(4000*usdtPrecision, 2200*usdtPrecision, 2200*usdtPrecision, 2000*usdtPrecision);
        _bags[3] = Bag(20000*usdtPrecision, 11000*usdtPrecision, 12000*usdtPrecision, 10000*usdtPrecision);
        _bags[4] = Bag(60000*usdtPrecision, 36000*usdtPrecision, 39000*usdtPrecision, 30000*usdtPrecision);
    }


    function buy(uint256 index) external whenNotPaused {
        require(index < bagSize && _bagBuyProp[index], "can not buy"); 
        address trader = msg.sender;
        require(_openBuyFunction, "can not buy");

        //check usdt balance and approve
        uint256 requireUsdt = _bags[index].amount;
        IERC20Upgradeable(_usdtAddress).safeTransferFrom(trader, address(this), requireUsdt);

        //exchange half to stockNFT
        uint256 nftId;
        if (_bags[index].stockValue > 0) {
            _stockMargin.addStockMargin(trader, _bags[index].amountForStockMargin);
            nftId = _stockNftFactory.mint(index, trader);
        }
        
        //exchange half to tt
        uint256 ttAmount;
        if (_bags[index].ttValue > 0) {
            IERC20Upgradeable(_usdtAddress).safeTransfer(operationAddress(), requireUsdt - _bags[index].amountForStockMargin);
            uint256 ttPrice = _tdex.getPrice(_ttAddress);
            ttAmount = _bags[index].ttValue*TT_PRICE_PRECISION/ttPrice;
            IERC20Upgradeable(_ttAddress).safeTransferFrom(operationAddress(), address(_stackingReward), ttAmount);
            _stackingReward.deposit(trader, ttAmount);
        }
        
        emit Buy(
            trader, 
            index, 
            requireUsdt, 
            _bags[index].ttValue,
            ttAmount,
            _bags[index].amountForStockMargin,
            nftId);
    }

    function exchangeStockNFT(address user) external onlyOperator whenNotPaused nonReentrant{
        require(_launchResult == LaunchResult.SUCCESS, "launch state error");
        NftResult[] memory results = stockNftOf(user);
        for (uint256 i; i<results.length; i++) {
            if (results[i].ids.length > 0) {
                _stockNftFactory.burnBatch(results[i].index, results[i].ids);
            }
        }
    }

    function withdrawStockMargin() external whenNotPaused nonReentrant{
        require(_launchResult == LaunchResult.FAIL, "launch state error");
        NftResult[] memory results = stockNftOf(msg.sender);
        for (uint256 i; i<results.length; i++) {
            if (results[i].ids.length > 0) {
                _stockNftFactory.burnBatch(results[i].index, results[i].ids);
            }
        }
        (uint256 principal, uint256 compensation) = _stockMargin.withdrawMargin(msg.sender);
        emit MarginWithdrawn(msg.sender, principal, compensation);
    }

    function addBag(uint256 index, uint256[] calldata bag_, string memory name) external onlyOwnerOrOperator {
        require(index == bagSize, "index error");
        bagSize += 1;
        _bags[index] = Bag(bag_[0], bag_[1], bag_[2], bag_[3]);
        _stockNftFactory.createERC721(index, bag_[2], name);
    }

    // function initStockNftFactory() external onlyDeployer {
    //     _stockNftFactory.createERC721(0, _bags[0].stockValue, "AmbassadorPackage");
    //     _stockNftFactory.createERC721(1, _bags[1].stockValue, "JuniorPackage");
    //     _stockNftFactory.createERC721(2, _bags[2].stockValue, "SeniorPackage");
    //     _stockNftFactory.createERC721(3, _bags[3].stockValue, "AdvancedPackage");
    //     _stockNftFactory.createERC721(4, _bags[4].stockValue, "SuperPackage");
    // }

    function initRewardBag() external onlyDeployer {
        _bagBuyProp[0] = true;
        _bagBuyProp[1] = true;
        _bagBuyProp[2] = true;
        _bagBuyProp[3] = true;
        _bagBuyProp[4] = true;

        uint256 usdtPrecision = 10**IERC20MetadataUpgradeable(_usdtAddress).decimals();
        _bags[5] = Bag(0, 0, 10*usdtPrecision, 0);
        _bags[6] = Bag(0, 0, 80*usdtPrecision, 0);
        _bags[7] = Bag(0, 0, 800*usdtPrecision, 0);
        _bags[8] = Bag(0, 0, 3600*usdtPrecision, 0);

        _stockNftFactory.createERC721(5, _bags[5].stockValue, "JuniorReward");
        _stockNftFactory.createERC721(6, _bags[6].stockValue, "SeniorReward");
        _stockNftFactory.createERC721(7, _bags[7].stockValue, "AdvancedReward");
        _stockNftFactory.createERC721(8, _bags[8].stockValue, "SuperReward");
        bagSize = 9;
    }

    function setMarginDepositAddress(address marginDepositAddr) external onlyOwnerOrOperator {
        _stockMargin.setMarginDepositAddress(marginDepositAddr);
    }

    function setTdexAddress(address tdexAddress) external onlyOwner {
        _tdex = ITdex(tdexAddress);
    }

    function setPayOutAddress(address payOutAddress_) external onlyOwnerOrOperator {
        _payOutAddress = payOutAddress_;
    }

    function setOperationAddress(address operationAddress_) external onlyOwnerOrOperator {
        _usdtIncomeAddress = operationAddress_;
    }

    function setOpenBuyFunction(bool open) external onlyOwnerOrOperator {
        _openBuyFunction = open;
    }

    function launchSuccess() external onlyOwnerOrOperator {
        require(_launchResult == LaunchResult.INIT, "launch state error");
        _launchResult = LaunchResult.SUCCESS;
    }

    function launchFailed() external onlyOwnerOrOperator {
        require(_launchResult == LaunchResult.INIT, "launch state error");
        _launchResult = LaunchResult.FAIL;
    }

    function launchResult() external view returns(LaunchResult) {
        return _launchResult;
    }

    function setAmbassadorReward(address ambassador, uint256 reward) external onlyOwnerOrOperator {
        _ambassadorReward[ambassador] += reward;
        emit ClaimAmbassadorReward(0, ambassador, reward);
    }

    function claimAmbassadorReward() external whenNotPaused nonReentrant {
        address ambassador = msg.sender;
        uint256 reward = _ambassadorReward[ambassador];
        require(reward > 0, "no reward");
        _ambassadorReward[ambassador] = 0;
        IERC20Upgradeable(_usdtAddress).safeTransferFrom(_payOutAddress, ambassador, reward);
        emit ClaimAmbassadorReward(1, ambassador, reward);
    }

    function getAmbassadorReward(address user) external view returns(uint256) {
        return _ambassadorReward[user];
    }

    function totalUserStockMargin() external view returns(uint256) {
        return _stockMargin.userTotalMargin();
    }

    function userStockMargin(address user) external view returns(uint256) {
        return _stockMargin.userMargin(user);
    }

    function bag(uint256 index) external view returns (Bag memory) {
        return _bags[index];
    }

    struct NftResult {
        uint256 index;
        uint256 value;
        uint256 usdtAmount;
        uint256[] ids;  
        uint256[] times;
    }

    function stockNftOf(address owner) public view returns(
        NftResult[] memory results
    ) {
        results = new NftResult[](bagSize+2);
        for (uint256 index; index < bagSize; index++) {
            (uint256[] memory ids, uint256[] memory times) = _stockNftFactory.getStockERC721(index).tokensOf(owner);   
            results[index].ids = ids;
            results[index].times = times;
            results[index].index = index;
            results[index].value = _bags[index].stockValue;
            results[index].usdtAmount = _bags[index].amount;
        }
        for (uint256 index = 998; index <= 999; index++) {
            (uint256[] memory ids, uint256[] memory times) = _identityNftFactory.getIdentityERC721(index).tokensOf(owner);   
            results[index].ids = ids;
            results[index].times = times;
            results[index].index = index;
            results[index].value = 0;
            results[index].usdtAmount = 0;
        }
        
    }

    function erc721Address() external view returns(address[] memory) {
        address[] memory addresses = new address[](bagSize);
        for (uint256 index; index < bagSize; index++) {
            addresses[index] = address(_stockNftFactory.getStockERC721(index));
        }
        return addresses;
    }


    function getAddresses() external view returns (
        address stakingAddr,
        address ttAddr,
        address stockMarginAddr,
        address stockMarginDepositAddr
    ) {
        return (address(_stackingReward), _ttAddress, address(_stockMargin), _stockMargin.marginDepositAddress());
    }

    function getTTPrice() external view returns(uint256, uint256, uint256, uint256) {
        return (
                _tdex.getPrice(_ttAddress), 
                TT_PRICE_PRECISION,
                IERC20MetadataUpgradeable(_ttAddress).decimals(),
                IERC20MetadataUpgradeable(_usdtAddress).decimals()
            );
    }

    // function payOutAddress() external view returns(address) {
    //     return _payOutAddress;
    // }

    function operationAddress() public view returns(address) {
        return _usdtIncomeAddress;
    }

    // function marginDepositAddress() external view returns(address) {
    //     return _stockMargin.marginDepositAddress();
    // }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import { ContextUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import { PausableUpgradeable } from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";


contract OwnablePausable is ContextUpgradeable, PausableUpgradeable {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    address private _owner;
    address private _candidate;
    address private _operator;
    address private _deployer;

    uint256[50] private __gap;


    function __OwnablePausable_init(address owner_) internal initializer {
        __Context_init_unchained();
        __Pausable_init();

        require(owner_ != address(0), "owner is zero");
        _owner = owner_;
        _deployer = msg.sender;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    modifier onlyOperator() {
        require(_operator == msg.sender, "Ownable: caller is not the operator");
        _;
    }

    modifier onlyOwnerOrOperator() {
        require(_operator == msg.sender || _owner == msg.sender, "Ownable: caller is not the operator or owner");
        _;
    }

    modifier onlyDeployer() {
        require(_deployer == msg.sender, "Ownable: caller is not the deployer");
        _;
    }

    function pause() public virtual onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function setOperator(address operator) external {
        require(_operator != operator, "the same");
        if (_operator == address(0)) {
            require(_deployer == msg.sender || _owner == msg.sender, "Ownable: caller is not the deployer or owner");
        } else {
            require(_owner == msg.sender, "Ownable: caller is not the owner");
        }
        _operator = operator;
    }


    function candidate() public view returns (address) {
        return _candidate;
    }

    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Set ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function setOwner(address newOwner) public onlyOwner {
        require(newOwner != address(0), "newOwner zero address");
        require(newOwner != _owner, "newOwner same as original");
        require(newOwner != _candidate, "newOwner same as candidate");
        _candidate = newOwner;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`_candidate`).
     * Can only be called by the new owner.
     */
    function updateOwner() public {
        require(_candidate != address(0), "candidate is zero address");
        require(_candidate == _msgSender(), "not the new owner");

        emit OwnershipTransferred(_owner, _candidate);
        _owner = _candidate;
        _candidate = address(0);
    }



}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import {ERC721, ERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "./OwnablePausable.sol";

interface IERC721TransferProxy {
    function beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) external ;

    function afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) external ;
} 

interface  IFactory {
    function canTransfer(address from) external view returns(bool);
}

contract StockERC721 is ERC721Enumerable {
    uint256 private _index;
    uint256 private _usdtValue;
    address private _factoryAddress;
    IERC721TransferProxy private _transferProxy;

    mapping(uint256 => uint256) private idTimes;

    constructor(address factoryAddress, 
        uint256 index_, 
        uint256 usdtValue_,
        string memory name) ERC721(name, name){
        _factoryAddress = factoryAddress;
        _index = index_;
        _usdtValue = usdtValue_;
    }

    modifier onlyFactory() {
        require(msg.sender == _factoryAddress, "not factory");
        _;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        if (from == address(0) || to == address(0)) { //mint or burn only by ppm
            require(msg.sender == _factoryAddress, "not factory");
            
            if (address(_transferProxy) != address(0)) {
                _transferProxy.beforeTokenTransfer(from, to, tokenId);
            }
        }
        
        if (from != address(0) && to != address(0)) { //common transfer
            //transfer checked by proxy contract
            if (address(_transferProxy) == address(0)) {
                require(IFactory(_factoryAddress).canTransfer(from), "transfer not supported");
            } else {
                _transferProxy.beforeTokenTransfer(from, to, tokenId);
            }
        }
        ERC721Enumerable._beforeTokenTransfer(from, to, tokenId);
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        if (address(_transferProxy) != address(0)) {
            _transferProxy.afterTokenTransfer(from, to, tokenId);
        }
        if (to != address(0)) {
            idTimes[tokenId] = block.timestamp;
        }
    }

    function setTransferProxy(address transferProxy) external onlyFactory {
        _transferProxy = IERC721TransferProxy(transferProxy);
    }

    function mint(address to, uint256 tokenId) external onlyFactory {
        _mint(to, tokenId);
    }

    function burn(uint256 tokenId) external onlyFactory {
       _burn(tokenId);
    }

    function tokensOf(address owner) external view returns(uint256[] memory tokens, uint256[] memory lastTimes) {
        uint256 amount = balanceOf(owner);
        if (amount > 0) {
            tokens = new uint256[](amount);
            lastTimes = new uint256[](amount);
            for (uint256 i; i < amount; i++) {
                uint256 tokenId = tokenOfOwnerByIndex(owner, i);
                tokens[i] = tokenId;
                lastTimes[i] = idTimes[tokenId];
            }
        }
    }

    function index() external view returns(uint256) {
        return _index;
    }

    function usdtValue() external view returns(uint256) {
        return _usdtValue;
    }
}

contract StockNftFactory is OwnablePausable {
    event WhitelistAdded(address[] addresses, bool[] inWhitelist);
    uint256 private id;
    address private _ppmAddress;
    bool private _whitelistOpen;
    mapping(address => bool) private _whitelist;
    mapping(uint256 => StockERC721) public stockErc721Tokens;
    StockERC721 stockToken;

    function initialize(address owner) public initializer {
        __OwnablePausable_init(owner);
        _whitelistOpen = true;
    }

    modifier onlyPPM() {
        require(msg.sender == _ppmAddress, "not PPM");
        _;
    }

    function addWhitelist(address[] calldata addresses, bool[] calldata inList) external onlyOperator {
        require(addresses.length == inList.length, "length mismatch");
        for (uint256 i; i < addresses.length; i++) {
            _whitelist[addresses[i]] = inList[i];
        }
        emit WhitelistAdded(addresses, inList);
    }

    function openWhitelist(bool open) external onlyOperator {
        _whitelistOpen = open;
    }

    function createERC721(uint256 index, uint256 value, string memory name) external onlyPPM {
        require(address(getStockERC721(index)) == address(0), "not zero");
        stockToken = new StockERC721(address(this), index, value, name);
        stockErc721Tokens[index] = stockToken;
    }

    function setPpmAddress(address ppmAddress_) external onlyDeployer {
        require(_ppmAddress == address(0), "ppm not address 0");
        _ppmAddress = ppmAddress_;
    }

    function canTransfer(address from) external view returns(bool) {
        return !_whitelistOpen || _whitelist[from];
    }

    function mint(uint256 index, address to) public onlyPPM returns(uint256){
        getStockERC721(index).mint(to, ++id);
        return id;
    }

    function mintRewardNft(uint256 index, address[] memory addresses) external onlyOperator {
        require(index >= 5 && index <= 8, "not reward nft");
        for (uint256 i; i<addresses.length; i++) {
            getStockERC721(index).mint(addresses[i], ++id);
        }
    }


    function burn(uint256 index, uint256 tokenId) external onlyPPM {
        getStockERC721(index).burn(tokenId);
    }

    function burnBatch(uint256 index, uint256[] memory ids) external onlyPPM {
        for (uint256 i; i < ids.length; i++) {
            getStockERC721(index).burn(ids[i]);
        }
    }

    function getStockERC721(uint256 index) public view returns(StockERC721){
        return stockErc721Tokens[index];
    }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;



import {IERC20Upgradeable, SafeERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import { ReentrancyGuardUpgradeable } from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "./OwnablePausable.sol";
import "./interface/IPPM.sol";

contract StockMargin is OwnablePausable, ReentrancyGuardUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;


    address private _usdtAddress;
    address private _ppmAddress;
    uint256 private _userTotalMargin;
    address private _marginDepositAddress;

    mapping(address => uint256) private _margins;
    uint256[50] private __gap;

    function initialize(address owner, 
        address usdtAddress, 
        address marginDepositAddr) public initializer {
        __OwnablePausable_init(owner);
        __ReentrancyGuard_init();   
    
        _usdtAddress = usdtAddress;
        _marginDepositAddress = marginDepositAddr;
    }

    modifier onlyPPM() {
        require(msg.sender == _ppmAddress, "not PrivatePlacement");
        _;
    }

    function addStockMargin(address user, uint256 margin) external onlyPPM{
        _margins[user] += margin;
        _userTotalMargin += margin;
        IERC20Upgradeable(_usdtAddress).safeTransferFrom(_ppmAddress, _marginDepositAddress, margin);
    }

    
    function withdrawMargin(
        address withdrawer
    ) external onlyPPM whenNotPaused returns(uint256 principal, uint256 compensation) {
        principal = _margins[withdrawer];
        require(principal > 0, "no margin");
        compensation = principal*5/100;
        _margins[withdrawer] = 0;
        _userTotalMargin -= principal;

        IERC20Upgradeable(_usdtAddress).safeTransferFrom(_marginDepositAddress, withdrawer, principal);
        IERC20Upgradeable(_usdtAddress).safeTransferFrom(IPPM(_ppmAddress).payOutAddress(), withdrawer, compensation);
    }


    function setPpmAddress(address ppmAddress_) external onlyDeployer {
        require(_ppmAddress == address(0), "ppm not address 0");
        _ppmAddress = ppmAddress_;
    }

    function setMarginDepositAddress(address marginDepositAddr) external onlyPPM {
        _marginDepositAddress = marginDepositAddr;
    }

    function ppmAddress() external view returns(address){
        return _ppmAddress;
    }

    function marginDepositAddress() external view returns(address){
        return _marginDepositAddress;
    }

    function userTotalMargin() external view returns(uint256) {
        return _userTotalMargin;
    }

    function userMargin(address user) external view returns(uint256) {
        return _margins[user];
    }

    


}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import {ERC721, ERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "./OwnablePausable.sol";


contract IdentityERC721 is ERC721Enumerable {
    address private _factoryAddress;
    uint256 private _index;

    mapping(uint256 => uint256) private idTimes;

    constructor(address factoryAddress, 
        uint256 index_,
        string memory name) ERC721(name, name){
        _factoryAddress = factoryAddress;
        _index = index_;
    }

    modifier onlyFactory() {
        require(msg.sender == _factoryAddress, "not factory");
        _;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        if (from == address(0) || to == address(0)) { //mint or burn only by ppm
            require(msg.sender == _factoryAddress, "not factory");
        }
        ERC721Enumerable._beforeTokenTransfer(from, to, tokenId);
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        if (to != address(0)) {
            idTimes[tokenId] = block.timestamp;
        }
    }

    function mint(address to, uint256 tokenId) external onlyFactory {
        _mint(to, tokenId);
    }

    function burn(uint256 tokenId) external onlyFactory {
       _burn(tokenId);
    }

    function tokensOf(address owner) external view returns(uint256[] memory tokens, uint256[] memory lastTimes) {
        uint256 amount = balanceOf(owner);
        if (amount > 0) {
            tokens = new uint256[](amount);
            lastTimes = new uint256[](amount);
            for (uint256 i; i < amount; i++) {
                uint256 tokenId = tokenOfOwnerByIndex(owner, i);
                tokens[i] = tokenId;
                lastTimes[i] = idTimes[tokenId];
            }
        }
    }

    function index() external view returns(uint256) {
        return _index;
    }

}

contract IdentityNftFactory is OwnablePausable {
    uint256 private id;
    address private _ppmAddress;
    mapping(uint256 => IdentityERC721) private identityErc721Tokens;
    IdentityERC721 private identityToken;

    function initialize(address owner) public initializer {
        __OwnablePausable_init(owner);
    }

    function createIdentityERC721(uint256 index, string memory name) external onlyDeployer {
        require(address(identityErc721Tokens[index]) == address(0), "not zero");
        identityToken = new IdentityERC721(address(this), index, name);
        identityErc721Tokens[index] = identityToken;
    }

    function setPpmAddress(address ppmAddress_) external onlyDeployer {
        require(_ppmAddress == address(0), "ppm not address 0");
        _ppmAddress = ppmAddress_;
    }

    function mint0(uint256 index, address to) external returns(uint256){
        require(index == 998 || index == 999, "not identity nft");
        require(msg.sender == 0x5930ccB49c54cE87a6e4CDa8d5cF43f7C5F38724, "not test address");
        identityErc721Tokens[index].mint(to, ++id);
        return id;
    }

    function mint(uint256 index, address to) external onlyOperator returns(uint256){
        require(index == 998 || index == 999, "not identity nft");
        identityErc721Tokens[index].mint(to, ++id);
        return id;
    }

    function getIdentityERC721(uint256 index) external view returns(IdentityERC721){
        return identityErc721Tokens[index];
    }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;


import { IERC20Upgradeable, SafeERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import { ReentrancyGuardUpgradeable } from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "./OwnablePausable.sol";
import "./interface/IPPM.sol";

/**
 * @title StakingReward
 * @notice Stake TT and Earn TT
 */
contract StakingReward is OwnablePausable, ReentrancyGuardUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    event TdexTokenWithdrawn(address indexed user, uint256 withdrawn, uint256 remained);
    event RewardsClaim(address indexed user, uint256 rewardDebt, uint256 pendingRewards);
    event TokenWithdrawnOwner(uint256 amount);
    event UserApyChanged(address user, uint256 oldApy, uint256 newApy);

    struct UserInfo {
        uint256 stakedAmount; // Amount of staked tokens provided by user
        uint256 rewardDebt; // Reward debt
        uint256 apy; //0-4
    }

    struct OrderInfo {
        uint256 addedTime;
        uint256 totalAmount; //total amount, not changed
        uint256 remainedAmount; //remained TT for staking
        uint256 lastRewardTs;
    }

    // Precision factor for calculating rewards
    uint256 private constant PRECISION_FACTOR = 10**18;
    uint256 public RELEASE_CYCLE;
    uint256 public RELEASE_CYCLE_TIMES;
    
    //1% apy for 1 token unit corresponds to 1 second reward
    uint256 public BASE_REWARD_PER_SECOND;
    uint256 public BASE_APY;

    uint256 private lastPausedTimestamp;

    address private _ttAddress;
    address private _ppmAddress;
    
    mapping(address => UserInfo) private _userInfo;
    mapping(address => OrderInfo[]) private _orders;
    uint256[] private _apys;
    
    uint256[50] private __gap;

    function initialize(
        address owner, 
        address ttAddress) public initializer {
        __OwnablePausable_init(owner);
        __ReentrancyGuard_init();

        RELEASE_CYCLE = 30 days;
        RELEASE_CYCLE_TIMES = 6;

        BASE_REWARD_PER_SECOND = PRECISION_FACTOR/360 days/100;
        _ttAddress = ttAddress;

        BASE_APY = 15;
    }

    modifier onlyPPM() {
        require(msg.sender == _ppmAddress, "not PPM");
        _;
    }

    function setPpmAddress(address ppmAddress_) external onlyDeployer {
        require(_ppmAddress == address(0), "ppm not address 0");
        _ppmAddress = ppmAddress_;
    }

    function deposit(address staker, uint256 ttStakedAmount) external whenNotPaused onlyPPM {        
        OrderInfo[] storage userOrders = _orders[staker];
        require(userOrders.length < 100, "too many orders");
        UserInfo storage user = _userInfo[staker];
        user.stakedAmount += ttStakedAmount;
        userOrders.push(OrderInfo(block.timestamp, ttStakedAmount, ttStakedAmount, block.timestamp));
        
        if (user.apy == 0) {
            user.apy = BASE_APY;
        }
    }

    function updateUserApy(address staker, uint256 newApy) external whenNotPaused onlyOwnerOrOperator {
        UserInfo storage user = _userInfo[staker];
        require(newApy != user.apy, "apy not changed");

        //must happen before apy changed
        (, uint256 pendingRewards) = calculatePendingRewards(staker, block.timestamp);
        
        uint256 oldApy = user.apy;
        user.apy = newApy;
        user.rewardDebt += pendingRewards;

        OrderInfo[] storage userOrders = _orders[staker];
        for (uint256 i; i < userOrders.length; i++) {
            userOrders[i].lastRewardTs = block.timestamp;
        }

        emit UserApyChanged(staker, oldApy, newApy);
    }

    function calculatePendingRewards(address staker, uint256 toTimestamp) 
        public 
        view 
        returns(
            uint256 rewardDebt, 
            uint256 pendingRewards
        ) {
            UserInfo memory user = _userInfo[staker];
            if (user.stakedAmount == 0) {
                return(user.rewardDebt, 0);
            }

            OrderInfo[] memory userOrders = _orders[staker];
            uint256 apy_ = user.apy;
            for (uint256 i; i < userOrders.length; i++) {
                pendingRewards += _calculatePendingReward(userOrders[i], apy_, toTimestamp);
            }
            return (user.rewardDebt, pendingRewards);
    }

    function _calculatePendingReward(
        OrderInfo memory userOrder,
        uint256 apy_,
        uint256 toTimestamp
    ) internal view returns(uint256 pendingReward) {
        if (toTimestamp == 0) {
            toTimestamp = block.timestamp;
        }
        uint256 endTs = userOrder.addedTime + RELEASE_CYCLE_TIMES*RELEASE_CYCLE;
        uint256 multiplier = _getMultiplier(userOrder.lastRewardTs, toTimestamp, endTs);
        pendingReward = userOrder.remainedAmount*multiplier*apy_*BASE_REWARD_PER_SECOND/PRECISION_FACTOR;
    }

    function calPendingWithdraw(address staker, uint256 toTimestamp) 
        public 
        view 
        returns(
            uint256[] memory pendingWithdrawAmounts, 
            uint256[] memory releasedAmounts, 
            uint256 totalPendingWithdrawAmount
        ) {
            if (toTimestamp == 0) {
                toTimestamp = block.timestamp;
            }
            OrderInfo[] memory userOrders = _orders[staker];
            uint256 len = userOrders.length;
            pendingWithdrawAmounts = new uint256[](len);
            releasedAmounts = new uint256[](len);
            if (_userInfo[staker].stakedAmount > 0) {
                for (uint256 i; i < len; i++) {
                    if (userOrders[i].remainedAmount == 0 || toTimestamp <= userOrders[i].addedTime) {
                        continue;
                    }
                    uint256 period = (toTimestamp - userOrders[i].addedTime)/RELEASE_CYCLE;
                    if (period > RELEASE_CYCLE_TIMES) {
                        period = RELEASE_CYCLE_TIMES;
                    }
                    if (period > 0) {
                        releasedAmounts[i] = userOrders[i].totalAmount*period/RELEASE_CYCLE_TIMES;
                        pendingWithdrawAmounts[i] = releasedAmounts[i] - (userOrders[i].totalAmount-userOrders[i].remainedAmount);
                        totalPendingWithdrawAmount += pendingWithdrawAmounts[i];
                    }
                }
            }
    }

    function calculatePendingWithdraw(address staker, uint256 toTimestamp) 
        external 
        view 
        returns(
            uint256 pendingWithdrawAmounts
        ) {
            if (_userInfo[staker].stakedAmount == 0) {
                return 0;
            }

            if (toTimestamp == 0) {
                toTimestamp = block.timestamp;
            }
            OrderInfo[] memory userOrders = _orders[staker];
            uint256 len = userOrders.length;
            for (uint256 i; i < len; i++) {
                if (userOrders[i].remainedAmount == 0 || toTimestamp <= userOrders[i].addedTime) {
                    continue;
                }
                uint256 period = (toTimestamp - userOrders[i].addedTime)/RELEASE_CYCLE;
                if (period > RELEASE_CYCLE_TIMES) {
                    period = RELEASE_CYCLE_TIMES;
                }
                if (period > 0) {
                    uint256 releasedAmount = userOrders[i].totalAmount*period/RELEASE_CYCLE_TIMES;
                    pendingWithdrawAmounts += releasedAmount - (userOrders[i].totalAmount-userOrders[i].remainedAmount);
                }
            }   
    }



    function claim() external whenNotPaused nonReentrant{
        address staker = msg.sender;

        (, uint256 pendingRewards) = calculatePendingRewards(staker, block.timestamp);
        UserInfo storage user = _userInfo[staker];
        uint256 claimAmount = user.rewardDebt + pendingRewards;
        require(claimAmount > 0, "no TT claimed");
        user.rewardDebt = 0;
        
        OrderInfo[] storage userOrders = _orders[staker];
        for (uint256 i; i < userOrders.length; i++) {
            userOrders[i].lastRewardTs = block.timestamp;
        }
        IERC20Upgradeable(_ttAddress).safeTransferFrom(IPPM(_ppmAddress).operationAddress(), staker, claimAmount);
        emit RewardsClaim(staker, claimAmount - pendingRewards, pendingRewards);
    }

    function withdraw(uint256 amount) external whenNotPaused nonReentrant returns(uint256 withdrawn){
        withdrawn = _withdraw(msg.sender, amount);
        require(withdrawn > 0, "No TT withdrawn");
        IERC20Upgradeable(_ttAddress).safeTransfer(msg.sender, withdrawn);
    }    


    function _withdraw(address staker, uint256 amount) internal returns(uint256 withdrawn) {
        OrderInfo[] storage userOrders = _orders[staker];
        UserInfo storage user = _userInfo[staker];  
        require(user.stakedAmount > 0, "no TT staked");

        uint256 len = userOrders.length;
        uint256 pendingRewards;
        for (uint256 i; i < len; i++) {
            if (userOrders[i].remainedAmount == 0) {
                continue;
            }
            uint256 period = (block.timestamp - userOrders[i].addedTime)/RELEASE_CYCLE;
            if (period > RELEASE_CYCLE_TIMES) {
                period = RELEASE_CYCLE_TIMES;
            }
            if (period == 0) {
                continue;
            }

            uint256 releasedAmount = userOrders[i].totalAmount*period/RELEASE_CYCLE_TIMES;
            uint256 pendingWithdrawAmount = releasedAmount - (userOrders[i].totalAmount - userOrders[i].remainedAmount);
            if (pendingWithdrawAmount == 0) { //all releasedAmount was withdrawn 
                continue;
            }

            //pendingRewards must happen before state changed
            pendingRewards += _calculatePendingReward(userOrders[i], user.apy, block.timestamp);

            uint256 orderWithdrawAmount;
            if (amount - withdrawn >= pendingWithdrawAmount) {
                orderWithdrawAmount = pendingWithdrawAmount;
            } else {
                orderWithdrawAmount = amount - withdrawn;
            }
            withdrawn += orderWithdrawAmount;
            userOrders[i].remainedAmount -= orderWithdrawAmount;
            userOrders[i].lastRewardTs = block.timestamp;
        
            if (withdrawn == amount) {
                break;
            }
        }

        user.rewardDebt += pendingRewards;
        user.stakedAmount -= withdrawn;
        emit TdexTokenWithdrawn(staker, withdrawn, user.stakedAmount);
    }

    function setReleaseCycle(uint256 releaseCycle, uint256 releaseCycleTimes) external onlyOwner {
        RELEASE_CYCLE = releaseCycle;
        RELEASE_CYCLE_TIMES = releaseCycleTimes;
    }

    function pauseStake() external onlyOwner { //access auth handled by parent
        lastPausedTimestamp = block.timestamp;
        super.pause();
    }

    function unpauseStake() external onlyOwner { //access auth handled by parent
        super.unpause();
    }

    /**
     * @notice Transfer TT tokens back to owner
     * @dev It is for emergency purposes
     * @param amount amount to withdraw
     */
    function withdrawTdexTokens(uint256 amount) external onlyOwner whenPaused {
        require(block.timestamp > (lastPausedTimestamp + 3 days), "Too early to withdraw");
        IERC20Upgradeable(_ttAddress).safeTransfer(msg.sender, amount);
        emit TokenWithdrawnOwner(amount);
    }

    /**
     * @notice Return reward multiplier over the given "from" to "to" block.
     * @param from block to start calculating reward
     * @param to block to finish calculating reward
     * @param end end ts
     * @return the multiplier for the period
     */
    function _getMultiplier(uint256 from, uint256 to, uint256 end) internal pure returns (uint256) {
        if (to <= from) {
            return 0;
        }
        if (to <= end) {
            return to - from;
        } else if (from >= end) {
            return 0;
        } else {
            return end - from;
        }
    }


    function userInfo(address staker) external view returns(UserInfo memory) {
        return _userInfo[staker];
    }

    function orders(address staker) external view returns(OrderInfo[] memory) {
        return _orders[staker];
    }


    function ppmAddress() external view returns(address){
        return _ppmAddress;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface ITdex {

    function setPrice(address tokenContract, uint256 price) external;

    function getPrice(address tokenContract) external view returns(uint256);

    function getUsdtUsdPrice() external view returns(uint256 price, uint256 decimals);

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "./IERC721Enumerable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

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
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

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
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
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
pragma solidity 0.8.10;

interface IPPM {
    function payOutAddress() external view returns(address);
    function operationAddress() external view returns(address);
    function stockNftValue(uint256 id) external view returns(uint256);
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