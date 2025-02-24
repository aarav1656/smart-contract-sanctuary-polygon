// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./OwnerPausable.sol";
import "./StockERC1155.sol";
import "./StakingReward.sol";
import "./StockMargin.sol";

interface ITdex {
    function getPrice(address tokenContract) external pure returns(uint256);
}

contract PrivatePlacementMarket is OwnerPausable {
    using SafeERC20 for IERC20;
    event Buy(
        address indexed trader,
        uint256 index,
        uint256 usdtAmount,
        uint256 ttAmountInUsdt,
        uint256 ttStakedAmount,
        uint256 stockMargin,
        uint256 stockAmountInUsdt
    );
    event WhitelistAdded(address[] addresses, bool[] inWhitelist);

    struct Bag {
        uint256 amountInUsdt;
        uint256 ttAmountInUsdt;
        uint256 stockAmountInUsdt;
    }

    uint256 private immutable TT_PRICE_PRECISION;

    address private _usdtIncomeAddress;
    address private _ttPayOutAddress;
    address immutable _usdtAddress;
    address immutable _ttAddress;
    uint8 immutable _usdtDecimals;
    uint8 immutable _ttDecimals;
    StockERC1155 immutable _stockERC1155;
    StockMargin immutable _stockMargin;
    StakingReward immutable _stackingReward;
    ITdex immutable _tdex;
    mapping(uint256 => Bag) private _bags;

    mapping(address => bool) private _whitelist;

    uint256 private _launchResult; //0-init 1-suc 2-fail
    

    constructor(
        address owner,
        address usdtAddress, 
        address ttAddress, 
        address usdtIncomeAddress,
        address ttPayOutAddress,
        address stockERC1155Address,
        address stockMarginAddress,
        address stackingRewardAddress,
        address tdex) OwnerPausable(owner) {
        
        _usdtAddress = usdtAddress;
        _ttAddress = ttAddress;
        _usdtIncomeAddress = usdtIncomeAddress;
        _ttPayOutAddress = ttPayOutAddress;
        _stockERC1155 = StockERC1155(stockERC1155Address);
        _stockMargin = StockMargin(stockMarginAddress);
        _stackingReward = StakingReward(stackingRewardAddress);
        _tdex = ITdex(tdex);
        _usdtDecimals = IERC20Metadata(usdtAddress).decimals();
        _ttDecimals = IERC20Metadata(ttAddress).decimals();

        TT_PRICE_PRECISION = 10**(18 + _ttDecimals -_usdtDecimals);

        _bags[0] = Bag(200, 100, 100);
        _bags[1] = Bag(4000, 2200, 2200);
        _bags[2] = Bag(20000, 11000, 12000);
        _bags[3] = Bag(60000, 36000, 39000);

        IERC20(_usdtAddress).safeApprove(stockMarginAddress, type(uint256).max);
    }

    function addWhitelist(address[] memory addresses, bool[] memory inList) external onlyOwnerOrOperator {
        require(addresses.length == inList.length, "size error");
        for (uint256 i; i < addresses.length; i++) {
            _whitelist[addresses[i]] = inList[i];
        }
        emit WhitelistAdded(addresses, inList);
    }

    function buy(uint256 index) public whenNotPaused {
        address trader = msg.sender;
        //require(_whitelist[trader], "can not buy");
        //check usdt balance and approve
        uint256 requireUsdt = _bags[index].amountInUsdt * 10**_usdtDecimals;
        require(requireUsdt <= IERC20(_usdtAddress).balanceOf(trader), "USDT not enough");
        require(IERC20(_usdtAddress).allowance(trader, address(this)) > requireUsdt, "not approved");
        IERC20(_usdtAddress).safeTransferFrom(trader, address(this), requireUsdt);

        //exchange half to stockNFT
        _stockMargin.addStockMargin(trader, requireUsdt/2);
        _stockERC1155.mint(trader, _bags[index].stockAmountInUsdt, 1);

        //exchange half to tt
        IERC20(_usdtAddress).safeTransfer(_usdtIncomeAddress, requireUsdt/2);
        uint256 ttPrice = _tdex.getPrice(_ttAddress);
        uint256 ttAmount = _bags[index].ttAmountInUsdt*10**_ttDecimals*TT_PRICE_PRECISION/ttPrice;
        IERC20(_ttAddress).safeTransferFrom(_ttPayOutAddress, address(_stackingReward), ttAmount);
        _stackingReward.deposit(trader, ttAmount);

        emit Buy(
            trader, 
            index, 
            requireUsdt, 
            _bags[index].ttAmountInUsdt * 10**_usdtDecimals,
            ttAmount,
            requireUsdt/2,
            _bags[index].stockAmountInUsdt * 10**_usdtDecimals);
    }

    function exchangeStockNFT(uint256[] memory ids, uint256[] memory amounts) external whenNotPaused {
        require(_launchResult == 1, "launch state error");
        _stockERC1155.burnBatch(msg.sender, ids, amounts);
    }

    function withdrawStockMargin() external whenNotPaused {
        require(_launchResult == 2, "launch state error");
        for(uint256 i; i<4; i++) {
            uint256 id = _bags[i].stockAmountInUsdt;
            uint256 amount = _stockERC1155.balanceOf(msg.sender, id);
            if (amount > 0) {
                _stockERC1155.burn(msg.sender, id, amount);
            }
        }
        _stockMargin.withdrawMargin(msg.sender);
    }

    function setBag(
        uint256[] memory bag0, 
        uint256[] memory bag1, 
        uint256[] memory bag2, 
        uint256[] memory bag3) 
        external onlyOwnerOrOperator {
        
    }

    function setMarginDepositAddress(address marginDepositAddress) external onlyOwnerOrOperator {
        _stockMargin.setMarginDepositAddress(marginDepositAddress);
    }

    function setMarginWithdrawAddress(address marginWithdrawAddress) external onlyOwnerOrOperator {
        _stockMargin.setMarginWithdrawAddress(marginWithdrawAddress);
    }


    function setTTPayOutAddress(address ttPayOutAddress) external onlyOwnerOrOperator {
        _ttPayOutAddress = ttPayOutAddress;
    }

    function setUsdtIncomeAddress(address usdtIncomeAddress) external onlyOwnerOrOperator {
        _usdtIncomeAddress = usdtIncomeAddress;
    }

    function launchSuccess() external onlyOwnerOrOperator {
        require(_launchResult == 0, "launch state error");
        _launchResult = 1;
    }

    function launchFailed() external onlyOwnerOrOperator {
        require(_launchResult == 0, "launch state error");
        _launchResult = 2;
    }

    function launchResult() external view returns(uint256) {
        return _launchResult;
    }


    function totalStockMargin() external view returns(uint256) {
        return _stockMargin.totalMargin();
    }

    function userStockMargin(address user) external view returns(uint256) {
        return _stockMargin.userMargin(user);
    }

    function bag(uint256 index) external view returns (Bag memory) {
        return _bags[index];
    }

    function inWhitelist(address addr) external view returns(bool) {
        return _whitelist[addr];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./OwnerPausable.sol";


interface ITransferProxy {
    function beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) external;

    function afterTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) external;
} 

contract StockERC1155 is ERC1155Supply, OwnerPausable {
    
    event WhitelistAdded(address[] addresses, bool[] inWhitelist);

    address private _ppmAddress;
    ITransferProxy private _transferProxy;
    bool private _whitelistOpen;
    mapping(address => bool) private _whitelist;


    constructor(address owner) OwnerPausable(owner) ERC1155("https://ipfs/stocknft/{id}.json") {
        _whitelistOpen = true;
    }

    modifier onlyPPM() {
        require(msg.sender == _ppmAddress, "not PPM");
        _;
    }

    function addWhitelist(address[] memory addresses, bool[] memory inList) external onlyOperator {
        require(addresses.length == inList.length, "size error");
        for (uint256 i; i < addresses.length; i++) {
            _whitelist[addresses[i]] = inList[i];
        }
        emit WhitelistAdded(addresses, inList);
    }

    

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override {
        if (from == address(0) || to == address(0)) { //mint or burn only by ppm
            require(msg.sender == _ppmAddress, "not PPM");
             if (address(_transferProxy) != address(0)) {
                _transferProxy.beforeTokenTransfer(operator, from, to, ids, amounts, data);
            }
        }
        
        if (from != address(0) && to != address(0)) { //common transfer
            //transfer checked by proxy contract
            if (address(_transferProxy) == address(0)) {
                require(_whitelistOpen && _whitelist[from], "transfer not supported");
            } else {
                _transferProxy.beforeTokenTransfer(operator, from, to, ids, amounts, data);
            }
        }

        ERC1155Supply._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function _afterTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override {
        if (address(_transferProxy) != address(0)) {
            _transferProxy.afterTokenTransfer(operator, from, to, ids, amounts, data);
        }
    }

    function setTransferProxy(address transferProxy) external onlyOwnerOrOperator {
        _transferProxy = ITransferProxy(transferProxy);
    }

    function setPpmAddress(address ppmAddress_) external onlyDeployer {
        _ppmAddress = ppmAddress_;
    }

    function mint(
        address to,
        uint256 id,
        uint256 amount
    ) external onlyPPM {
        _mint(to, id, amount, bytes(''));
    }

    function burn(
        address from,
        uint256 id,
        uint256 amount
    ) external onlyPPM {
        _burn(from, id, amount);
    }

    function burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) external onlyPPM {
        _burnBatch(from, ids, amounts);
    }

    function ppmAddress() external view returns(address){
        return _ppmAddress;
    }

    function inWhitelist(address addr) external view returns(bool) {
        return _whitelist[addr];
    }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts/security/Pausable.sol";

contract OwnerPausable is Pausable {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    address private _owner;
    address private _candidate;
    address private _operator;
    address private _deployer;

    
    constructor(address owner_) {
        require(owner_ != address(0), "owner is zero");
        _owner = owner_;
        _deployer = msg.sender;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    modifier onlyOperator() {
        require(_owner == msg.sender, "Ownable: caller is not the operator");
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

    function pause() public virtual onlyOwnerOrOperator {
        _pause();
    }

    function unpause() public onlyOwnerOrOperator {
        _unpause();
    }

    function setOperator(address operator) external onlyOwner {
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

import "./OwnerPausable.sol";
import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title StakingReward
 * @notice Stake TT and Earn TT
 */
contract StakingReward is OwnerPausable {
    using SafeERC20 for IERC20;

    event TdexTokenWithdrawn(address indexed user, uint256 withdrawn, uint256 remained);
    event RewardsClaim(address indexed user, uint256 rewardDebt, uint256 pendingRewards);
    event TokenWithdrawnOwner(uint256 amount);
    event UserLevelChanged(address user, uint256 oldLevel, uint256 newLevel);
    event ApyAdded(uint256[] level, uint256[] apy);

    struct UserInfo {
        uint256 stakedAmount; // Amount of staked tokens provided by user
        uint256 rewardDebt; // Reward debt
        uint256 level; //0-18%
    }

    struct OrderInfo {
        uint256 addedBlock;
        uint256 totalAmount; //total amount, not changed
        uint256 remainedAmount;
        uint256 releasedAmount;
        uint256 lastRewardBlock;
    }

    struct ApyLevel {
        uint256 startBlock;
        uint256 apy;
    }
    // Precision factor for calculating rewards
    uint256 private constant PRECISION_FACTOR = 10**18;
    uint256 public RELEASE_CYCLE = 3 minutes;
    uint256 public RELEASE_CYCLE_TIMES = 6;

    uint256 private lastPausedTimestamp;

    address private immutable _ttAddress;
    address private _ttPayOutAddress;
    address private _ppmAddress;
    uint256 private immutable SECONDS_PER_BLOCK;

    //1% apy for 1 token unit corresponds to 1 block reward
    uint256 public immutable BASE_REWARD_PER_BLOCK; //1个代币单位 1%的apy 对应1个区块的奖励
    
    mapping(address => UserInfo) private _userInfo;
    mapping(address => OrderInfo[]) private _orders;
    
    //index => apy
    mapping(uint256 => ApyLevel[]) private _apys;
    
    constructor(address owner, uint256 secondsPerBlock, address ttAddress, address ttPayOutAddress) OwnerPausable(owner) {
        SECONDS_PER_BLOCK = secondsPerBlock;
        BASE_REWARD_PER_BLOCK = secondsPerBlock*PRECISION_FACTOR/365 days/100;
        _ttAddress = ttAddress;
        _ttPayOutAddress = ttPayOutAddress;

        uint256 number = block.number;
        _apys[0].push(ApyLevel(number, 18));
        _apys[1].push(ApyLevel(number, 20));
        _apys[2].push(ApyLevel(number, 28));
        _apys[3].push(ApyLevel(number, 30));
        _apys[4].push(ApyLevel(number, 32));
    }

    modifier onlyPPM() {
        require(msg.sender == _ppmAddress, "not PPM");
        _;
    }

    function setPpmAddress(address ppmAddress_) external onlyDeployer {
        _ppmAddress = ppmAddress_;
    }

    function deposit(address staker, uint256 ttStakedAmount) external whenNotPaused onlyPPM {        
        OrderInfo[] storage userOrders = _orders[staker];
        require(userOrders.length <= 200, "too many orders");
        UserInfo storage user = _userInfo[staker];
        user.stakedAmount += ttStakedAmount;
        userOrders.push(OrderInfo(block.number, ttStakedAmount, ttStakedAmount, 0, block.number));
    }

    function updateUserLevel(address staker, uint256 level) external whenNotPaused onlyOperator {
        require(level>0 && level < 5, "level error");
        (, uint256 pendingRewards) = calculatePendingRewards(staker);
        UserInfo storage user = _userInfo[staker];
        uint256 oldLevel = user.level;
        user.rewardDebt += pendingRewards;
        user.level = level;
        
        OrderInfo[] storage userOrders = _orders[staker];
        for (uint256 i; i < userOrders.length; i++) {
            userOrders[i].lastRewardBlock = block.number;
        }
        emit UserLevelChanged(staker, oldLevel, level);
    }

    function addApy(uint256[] memory levels, uint256[] memory apys_) external whenNotPaused onlyOwnerOrOperator{
        require(levels.length == apys_.length, "size error");
        for (uint i; i<levels.length; i++) {
            _apys[levels[i]].push(ApyLevel(block.number, apys_[i]));
        }
        emit ApyAdded(levels, apys_);
    }

    function depositMock(uint256 amount, uint256 loopCounter) external {
        address staker = msg.sender;
        UserInfo storage user = _userInfo[staker];
        OrderInfo[] storage userOrders = _orders[staker]; 
        user.stakedAmount += loopCounter*amount;
        for (uint256 i; i<loopCounter; i++) {
            userOrders.push(OrderInfo(block.number, amount, amount, 0, block.number));
        }
    }

    /**
     *               init block
     *          block |300        |1000                      |2000               |2500
     *          apy   |18         |20                        |22                 |24
     * 
     * case1: staked at block 3000                                                            3000 
     *                                                                                        [3000, block.number) apy=24
     * 
     * case1: staked at block 3000      1500
     *                                  [1500,2000) apy=20
     *                                                        [2000,2500) apy=22   
     *                                                                            [2500,block.number) apy=24 
     *                                                                
     */
    function calculatePendingRewards(address staker) public view returns(uint256 rewardDebt, uint256 pendingRewards) {
        UserInfo memory user = _userInfo[staker];
        OrderInfo[] memory userOrders = _orders[staker];
        //uint256 pendingRewards;
        if (_userInfo[staker].stakedAmount == 0) {
            return(0, 0);
        }

        for (uint256 i; i < userOrders.length; i++) {
            uint256 lastRewardBlock = userOrders[i].lastRewardBlock;
            uint256 endBlock = userOrders[i].addedBlock + RELEASE_CYCLE_TIMES*RELEASE_CYCLE/SECONDS_PER_BLOCK;
            ApyLevel[] memory apyLevels = _apys[user.level];
            uint256 apySize = apyLevels.length;
            if (lastRewardBlock >= apyLevels[apySize-1].startBlock) {
                uint256 multiplier = _getMultiplier(lastRewardBlock, block.number, endBlock);
                pendingRewards += userOrders[i].remainedAmount*multiplier*apyLevels[apySize-1].apy*BASE_REWARD_PER_BLOCK/PRECISION_FACTOR;
            } else {
                uint256 matches; //0-没有重合，1-第一次重合 2-第1次重合之后的区间
                for (uint256 j; j<apySize-1; j++) {
                    if (matches == 0 && apyLevels[j].startBlock <= lastRewardBlock && lastRewardBlock < apyLevels[j+1].startBlock) {
                        matches = 1;
                    }

                    if (matches >= 1) {
                        uint256 multiplier = _getMultiplier(matches == 1 ? lastRewardBlock : apyLevels[j].startBlock, apyLevels[j+1].startBlock, endBlock);
                        pendingRewards += userOrders[i].remainedAmount*multiplier*apyLevels[j].apy*BASE_REWARD_PER_BLOCK/PRECISION_FACTOR;
                        matches = 2;
                    }
                }
                uint256 multiplier_ = _getMultiplier(apyLevels[apySize-1].startBlock, block.number, endBlock);
                pendingRewards += userOrders[i].remainedAmount*multiplier_*apyLevels[apySize-1].apy*BASE_REWARD_PER_BLOCK/PRECISION_FACTOR;
            }
        }
        return (user.rewardDebt, pendingRewards);
    }

    function calculatePendingWithdraw(address staker) 
        public 
        view 
        returns(
            uint256[] memory pendingWithdrawAmounts, 
            uint256[] memory releasedAmounts, 
            uint256 totalPendingWithdrawAmount
        ) {
            OrderInfo[] memory userOrders = _orders[staker];
            pendingWithdrawAmounts = new uint256[](userOrders.length);
            releasedAmounts = new uint256[](userOrders.length);
            totalPendingWithdrawAmount;
            if (_userInfo[staker].stakedAmount > 0) {
                for (uint256 i; i < userOrders.length; i++) {
                    if (userOrders[i].remainedAmount == 0) {
                        continue;
                    }
                    uint256 period = (block.number - userOrders[i].addedBlock)/(RELEASE_CYCLE/SECONDS_PER_BLOCK);
                    if (period > RELEASE_CYCLE_TIMES) {
                        period = RELEASE_CYCLE_TIMES;
                    }
                    if (period > 0) {
                        uint256 totalRelease = userOrders[i].totalAmount*period/RELEASE_CYCLE_TIMES;
                        if (totalRelease > userOrders[i].releasedAmount) {
                            pendingWithdrawAmounts[i] = totalRelease - (userOrders[i].totalAmount-userOrders[i].remainedAmount);
                            totalPendingWithdrawAmount += pendingWithdrawAmounts[i];
                            releasedAmounts[i] = totalRelease;
                        } else {
                            releasedAmounts[i] = userOrders[i].releasedAmount;
                        }
                    }
                }
            }
    }


    function claim() external whenNotPaused {
        address staker = msg.sender;

        (, uint256 pendingRewards) = calculatePendingRewards(staker);
        UserInfo storage user = _userInfo[staker];
        uint256 claimAmount = user.rewardDebt + pendingRewards;
        require(claimAmount > 0, "no claimed TT");
        user.rewardDebt = 0;
        
        OrderInfo[] storage userOrders = _orders[staker];
        for (uint256 i; i < userOrders.length; i++) {
            userOrders[i].lastRewardBlock = block.number;
        }
        IERC20(_ttAddress).safeTransferFrom(_ttPayOutAddress, staker, claimAmount);
        emit RewardsClaim(staker, user.rewardDebt, pendingRewards);
    }

    function withdraw(uint256 amount) external whenNotPaused {
        uint256 staker = _withdraw(msg.sender, amount);
        IERC20(_ttAddress).safeTransfer(msg.sender, staker);
    }    

    function withdrawMock(uint256 amount) external {
        uint256 withdrawn = _withdraw(msg.sender, amount);
        IERC20(_ttAddress).safeTransferFrom(_ttPayOutAddress, msg.sender, withdrawn);
    }

    function _withdraw(address staker, uint256 amount) internal returns(uint256 withdrawn){
        (uint256[] memory pendingAmounts,uint256[] memory releasedAmounts, uint256 totalPendingAmount) = calculatePendingWithdraw(staker);
        require(totalPendingAmount >= amount, "withdraw too much");

        //first caculate the reward and then modify the order state(remainedAmount&lastRewardBlock)
        (, uint256 pendingRewards) = calculatePendingRewards(staker);
        UserInfo storage user = _userInfo[staker];
        user.rewardDebt += pendingRewards;

        OrderInfo[] storage userOrders = _orders[staker];
        for (uint256 i; i < pendingAmounts.length; i++) {
            if (pendingAmounts[i] == 0) {
                continue;
            }
            uint256 orderWithdrawAmount;
            if (amount - withdrawn >= pendingAmounts[i]) {
                orderWithdrawAmount = pendingAmounts[i];
            } else {
                orderWithdrawAmount = amount - withdrawn;
            }
            userOrders[i].remainedAmount = userOrders[i].remainedAmount - orderWithdrawAmount;
            withdrawn += orderWithdrawAmount;
            if (withdrawn == amount) {
                break;
            }
        }

        for (uint256 i; i < pendingAmounts.length; i++) {
            userOrders[i].lastRewardBlock = block.number;
            if (userOrders[i].releasedAmount != releasedAmounts[i]) {
                userOrders[i].releasedAmount = releasedAmounts[i];
            }
        }
        user.stakedAmount -= withdrawn;

        emit TdexTokenWithdrawn(staker, withdrawn, user.stakedAmount);
    }

    function setReleaseCycle(uint256 releaseCycle) external onlyOperator {
        RELEASE_CYCLE = releaseCycle;
    }


    function setReleaseCycleTimes(uint256 releaseCycleTimes) external onlyOperator {
        RELEASE_CYCLE_TIMES = releaseCycleTimes;
    }


    function pauseStake() external { //access auth handled by parent
        lastPausedTimestamp = block.timestamp;
        super.pause();
    }

    function unpauseStake() external { //access auth handled by parent
        super.unpause();
    }

    /**
     * @notice Transfer TT tokens back to owner
     * @dev It is for emergency purposes
     * @param amount amount to withdraw
     */
    function withdrawTdexTokens(uint256 amount) external onlyOwner whenPaused {
        require(block.timestamp > (lastPausedTimestamp + 3 days), "Too early to withdraw");
        IERC20(_ttAddress).safeTransfer(msg.sender, amount);
        emit TokenWithdrawnOwner(amount);
    }

    /**
     * @notice Return reward multiplier over the given "from" to "to" block.
     * @param from block to start calculating reward
     * @param to block to finish calculating reward
     * @return the multiplier for the period
     */
    function _getMultiplier(uint256 from, uint256 to, uint256 endBlock) internal pure returns (uint256) {
        if (to <= endBlock) {
            return to - from;
        } else if (from >= endBlock) {
            return 0;
        } else {
            return endBlock - from;
        }
    }


    function userInfo(address staker) external view returns(UserInfo memory) {
        return _userInfo[staker];
    }

    function orders(address staker) external view returns(OrderInfo[] memory) {
        return _orders[staker];
    }

    function apy(uint256 index) external view returns(ApyLevel[] memory) {
        return _apys[index];
    }

    function ppmAddress() external view returns(address){
        return _ppmAddress;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;


import "./OwnerPausable.sol";
import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";


contract StockMargin is OwnerPausable {
    using SafeERC20 for IERC20;

    event MarginWithdrawn(address indexed withdrawer, uint256 principal, uint256 amount);

    address immutable _usdtAddress;
    address private _ppmAddress;

    
    uint256 private _totalMargin;
    address private _marginDepositAddress;
    address private _marginWithdrawAddress;

    mapping(address => uint256) private _margins;

    constructor(address owner, 
        address usdtAddress, 
        address marginDepositAddress) OwnerPausable(owner) {
        _usdtAddress = usdtAddress;
        _marginDepositAddress = marginDepositAddress;
    }

    modifier onlyPPM() {
        require(msg.sender == _ppmAddress, "not PrivatePlacement");
        _;
    }

    function addStockMargin(address user, uint256 margin) external onlyPPM{
        _margins[user] += margin;
        _totalMargin += margin;
        IERC20(_usdtAddress).safeTransferFrom(_ppmAddress, _marginDepositAddress, margin);
    }

    
    function withdrawMargin(address withdrawer) external onlyPPM whenNotPaused {
        uint256 principal = _margins[withdrawer];
        require(principal > 0, "no margin");
        uint256 amount = principal*105/100;
        require(_marginWithdrawAddress != address(0), "margin out address is 0");
        _margins[withdrawer] = 0;
        if (_marginWithdrawAddress == address(this)) {
            IERC20(_usdtAddress).safeTransfer(withdrawer, amount);
        } else {
            IERC20(_usdtAddress).safeTransferFrom(_marginWithdrawAddress, withdrawer, amount);
        }
        _totalMargin -= principal;
        emit MarginWithdrawn(withdrawer, principal, amount);
    }


    function setPpmAddress(address ppmAddress_) external onlyDeployer {
        _ppmAddress = ppmAddress_;
    }

    function setMarginDepositAddress(address marginDepositAddress) external onlyPPM {
        _marginDepositAddress = marginDepositAddress;
    }

    function setMarginWithdrawAddress(address marginWithdrawAddress) external onlyPPM {
        _marginWithdrawAddress = marginWithdrawAddress;
    }

    function ppmAddress() external view returns(address){
        return _ppmAddress;
    }

    function totalMargin() external view returns(uint256) {
        return _totalMargin;
    }

    function userMargin(address user) external view returns(uint256) {
        return _margins[user];
    }

    


}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/ERC1155.sol)

pragma solidity ^0.8.0;

import "./IERC1155.sol";
import "./IERC1155Receiver.sol";
import "./extensions/IERC1155MetadataURI.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
    using Address for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    constructor(string memory uri_) {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: address zero is not a valid owner");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not token owner nor approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not token owner nor approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
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
        require(owner != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `ids` and `amounts` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    /**
     * @dev Hook that is called after any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Tree proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 *
 * WARNING: You should avoid using leaf values that are 64 bytes long prior to
 * hashing, or use a hash function other than keccak256 for hashing leaves.
 * This is because the concatenation of a sorted pair of internal nodes in
 * the merkle tree could be reinterpreted as a leaf value.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Calldata version of {verify}
     *
     * _Available since v4.7._
     */
    function verifyCalldata(
        bytes32[] calldata proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProofCalldata(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merkle tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Calldata version of {processProof}
     *
     * _Available since v4.7._
     */
    function processProofCalldata(bytes32[] calldata proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Returns true if the `leaves` can be proved to be a part of a Merkle tree defined by
     * `root`, according to `proof` and `proofFlags` as described in {processMultiProof}.
     *
     * _Available since v4.7._
     */
    function multiProofVerify(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProof(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Calldata version of {multiProofVerify}
     *
     * _Available since v4.7._
     */
    function multiProofVerifyCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProofCalldata(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Returns the root of a tree reconstructed from `leaves` and the sibling nodes in `proof`,
     * consuming from one or the other at each step according to the instructions given by
     * `proofFlags`.
     *
     * _Available since v4.7._
     */
    function processMultiProof(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    /**
     * @dev Calldata version of {processMultiProof}
     *
     * _Available since v4.7._
     */
    function processMultiProofCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    function _hashPair(bytes32 a, bytes32 b) private pure returns (bytes32) {
        return a < b ? _efficientHash(a, b) : _efficientHash(b, a);
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC1155/extensions/ERC1155Supply.sol)

pragma solidity ^0.8.0;

import "../ERC1155.sol";

/**
 * @dev Extension of ERC1155 that adds tracking of total supply per id.
 *
 * Useful for scenarios where Fungible and Non-fungible tokens have to be
 * clearly identified. Note: While a totalSupply of 1 might mean the
 * corresponding is an NFT, there is no guarantees that no other token with the
 * same id are not going to be minted.
 */
abstract contract ERC1155Supply is ERC1155 {
    mapping(uint256 => uint256) private _totalSupply;

    /**
     * @dev Total amount of tokens in with a given id.
     */
    function totalSupply(uint256 id) public view virtual returns (uint256) {
        return _totalSupply[id];
    }

    /**
     * @dev Indicates whether any token exist with a given id, or not.
     */
    function exists(uint256 id) public view virtual returns (bool) {
        return ERC1155Supply.totalSupply(id) > 0;
    }

    /**
     * @dev See {ERC1155-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        if (from == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                _totalSupply[ids[i]] += amounts[i];
            }
        }

        if (to == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                uint256 id = ids[i];
                uint256 amount = amounts[i];
                uint256 supply = _totalSupply[id];
                require(supply >= amount, "ERC1155: burn amount exceeds totalSupply");
                unchecked {
                    _totalSupply[id] = supply - amount;
                }
            }
        }
    }
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

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
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import "../IERC1155.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
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