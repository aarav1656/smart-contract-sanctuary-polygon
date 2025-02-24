// SPDX-License-Identifier: GPLv3

pragma solidity >=0.8.0;

import "./SafeMath.sol";
import "./IERC20.sol";

contract PolygonBSG {
    using SafeMath for uint256;
    IERC20 public usdt;
    uint256 private constant baseDivider = 10000;
    uint256 private constant limitProfit = 20000;
    uint256 private constant boosterLimitProfit = 30000;
    uint256 private constant feePercents = 200; 
    uint256 private constant minDeposit = 100e6; 
    uint256 private constant maxDeposit = 2500e6; 
    uint256 private constant freezeIncomePercents = 3000;
    uint256 private constant LuckDeposit = 1000e6; 
    uint256 private constant timeStep = 1 minutes; 
    uint256 private constant dayPerCycle = 15 minutes;
    uint256 private constant maxAddFreeze = 25 minutes; 
    uint256 private constant normalcycleRewardPercents = 1500;
    uint256 private constant boostercycleRewardPercents = 2000;
    uint256 private constant referDepth = 12;

    uint256 private constant directPercents = 500;
    uint256[] private percent4Levels = [500,100,200,100,200,100,100,100,100,100,50,50]; 

    uint256 private constant infiniteRewardPercents = 400; 
    uint256 private constant boosterPoolPercents = 50; 
    uint256 private constant insurancePoolPercents = 100; 
    uint256 private constant more1kIncomePoolPercents = 50; 

    uint256[5] private balDown = [6000, 8000, 11000];
    mapping(uint256=>bool) public balStatus; 

    address[2] public feeReceivers; 
    address public insuranceAccount;

    address public defaultRefer; 
    uint256 public startTime;
    uint256 public lastDistribute; //daliy distribution pool reward
    uint256 public totalUser;
    uint256 public insurancePool;
    uint256 public more1kIncomePool;
    uint256 public boosterPool;

    uint256 public AllTimeHigh;
    uint256 private constant ATHSTOPLOSS30 = 3000;
    uint256 private constant ATHSTOPLOSS50 = 5000;

    mapping(uint256=>address[]) public dayMore1kUsers;
    uint256 dayMore1KLastDistributed;

    address[] public diamondUsers;
    address[] public blueDiamondUsers;
    address[] public crownDiamondUsers;
    address[] public boosterUsers;

    struct OrderInfo {
        uint256 amount;
        uint256 start;
        uint256 unfreeze;
        bool isClaimed;
    }

    mapping(address => OrderInfo[]) public orderInfos;

    address[] public depositors;

    struct UserInfo {
        address referrer;
        uint256 start; //cycle start time
        uint256 level;
        uint256 maxDeposit;
        uint256 maxDirectDeposit;
        uint256 totalDeposit;
        uint256 teamNum;
        uint256 teamTotalDeposit;
        uint256 directTeamTotalVolume;
        bool isbooster;
        uint256 totalFreezed;
        uint256 totalRevenue;
        uint256 depositDistributed;
    }

    mapping(address => UserInfo) public userInfo;
    mapping(address => mapping(uint256 => address[])) public teamUsers;
    mapping(address => address[]) public myTeamUsers;

    struct RewardInfo {
        uint256 capitals;
        uint256 statics;
        uint256 directs;
        uint256 levelReleased;
        uint256 levelFreezed;
        uint256 infinityBonusReleased;
        uint256 infinityFreezed;
        uint256 blueDiamondReceived;
        uint256 crownDiamondReceived;
        uint256 infinityL1toL5Received;
        uint256 more1k;
        uint256 booster;
        uint256 lockusdt;
        uint256 lockusdtDebt; // locked amount got from other lock amount
    }

    mapping(address => RewardInfo) public rewardInfo;

    bool public isFreezeReward = false;
    bool public isStopLoss30ofATH = false;
    bool public isStopLoss50ofATH = false;
    uint256 private constant maxBlueDiamondFreeze = 200e6;
    uint256 private constant maxCrownDiamondFreeze = 100e6;
    uint256 private constant maxInfinityL1toL5 = 200e6;

    event Register(address user, address referral);
    event Deposit(address user, uint256 amount);
    event DepositBylockusdt(address user, uint256 amount);
    event TransferBylockusdt(address user, address receiver, uint256 amount);
    event Withdraw(address user, uint256 withdrawable);

    constructor(
        address _usdtAddr,
        address _defaultRefer,
        address _insurance,
        address[2] memory _feeReceivers
    ) {
        usdt = IERC20(_usdtAddr);
        defaultRefer = _defaultRefer;
        insuranceAccount = _insurance;
        feeReceivers = _feeReceivers;
        startTime = block.timestamp;
        lastDistribute = block.timestamp;
    }

    function register(address _referral) external {
        require(userInfo[_referral].totalDeposit > 0 || _referral == defaultRefer,"invalid refer");
        UserInfo storage user = userInfo[msg.sender];
        require(user.referrer == address(0), "referrer bonded");
        user.referrer = _referral;
        totalUser = totalUser.add(1);
        emit Register(msg.sender, _referral);
    }
    
    function _updateTeamNum(address _user) private {
        UserInfo storage user = userInfo[_user];
        address upline = user.referrer;
        for (uint256 i = 0; i < referDepth; i++) {
            if (upline != address(0)) {
                userInfo[upline].teamNum = userInfo[upline].teamNum.add(1);
                teamUsers[upline][i].push(_user);
                _updateLevel(upline);
                if (upline == defaultRefer) break;
                upline = userInfo[upline].referrer;
            } else {
                break;
            }
        }
    }

    function _updateLevel(address _user) private {
        UserInfo storage user = userInfo[_user];
        user.level = _calLevelNow(_user);
    }

    function _calLevelNow(address _user) private view returns (uint256) {
        UserInfo storage user = userInfo[_user];
        uint256 level;
        uint256 directTeam = getActiveTeam(_user);
        (uint256 maxTeam, uint256 otherTeam, ) = getTeamDeposit(_user);
        uint256 totalTeam = getActiveTeambyDepth(_user);
        if(user.maxDeposit >= 800e6 && directTeam >=2 && user.maxDirectDeposit >= 300e6 && totalTeam >= 3 && maxTeam >= 400e6 && otherTeam >= 200e6){
            level = 4;
        }else if(user.maxDeposit >= 500e6 && directTeam >=1 && user.maxDirectDeposit >= 200e6 && totalTeam >= 2 && maxTeam >= 300e6 && otherTeam >= 100e6){
            level = 3;
        }else if(user.maxDeposit >= 300e6 && directTeam >=1 && user.maxDirectDeposit >= 100e6 && totalTeam >= 1 && maxTeam >= 200e6 && otherTeam >= 0){
            level = 2;
        } else if(user.maxDeposit >= minDeposit) {
            level = 1;
        }
        return level;
    }

    function _updatemaxdirectdepositInfo(address _user, uint256 _amount, uint256 _prevMax) private {
        UserInfo storage user = userInfo[_user];
        address upline = user.referrer;

        if (upline != address(0)) {
            userInfo[upline].maxDirectDeposit = userInfo[upline]
                .maxDirectDeposit
                .add(_amount);
            userInfo[upline].maxDirectDeposit = userInfo[upline]
                .maxDirectDeposit
                .sub(_prevMax);

            userInfo[upline].directTeamTotalVolume = userInfo[upline].directTeamTotalVolume.add(_amount);
        }
    }

    function deposit(uint256 _amount) external {
        require(_amount.mod(minDeposit) == 0,"amount should be multiple of 100");
        usdt.transferFrom(msg.sender, address(this), _amount);
        _deposit(msg.sender, _amount);
        emit Deposit(msg.sender, _amount);
    }

    function _deposit(address _user, uint256 _amount) private {
        UserInfo storage user = userInfo[_user];
        uint256 prevMax = user.maxDeposit;
        require(user.referrer != address(0),"register first with referral address");
        require(_amount >= minDeposit, "should be more than 100");
        require(_amount <= maxDeposit, "should be less than 2500");
        require(user.maxDeposit == 0 || _amount >= user.maxDeposit,"next deposit should be equal or more than previous");

        if (user.maxDeposit == 0) {
            user.maxDeposit = _amount;
            myTeamUsers[user.referrer].push(_user);
            _updateTeamNum(_user);
        } else if (user.maxDeposit < _amount) {
            user.maxDeposit = _amount;
        }

        _distributeDeposit(_amount);

        if(user.totalDeposit == 0 && _amount >= LuckDeposit){
            uint256 dayNow = dayMore1KLastDistributed;
            _updateDayMore1kUsers(_user, dayNow);
        }

        _updateDepositors(_user);

        user.totalDeposit = user.totalDeposit.add(_amount);
        user.totalFreezed = user.totalFreezed.add(_amount);

        uint256 addFreeze = (orderInfos[_user].length).mul(timeStep);
        if (addFreeze > maxAddFreeze) {
            addFreeze = maxAddFreeze;
        }

        uint256 unfreezeTime = block.timestamp.add(dayPerCycle).add(addFreeze);
        orderInfos[_user].push(OrderInfo(_amount, block.timestamp, unfreezeTime, false));

        _updatemaxdirectdepositInfo(_user, _amount, prevMax);
        
        _isBooster(_user);

        _unfreezeFundAndUpdateReward(_user); //calculate main static reward

        distributePoolRewards(); //give more1k users reward

        _updateReferInfo(_user, _amount); //update totalDep and totalVol

        _updateReward(_user, _amount, prevMax); //calculate directs and level reward

        _updateInfinity(_user, _amount);

        _updateLevel(_user);

        uint256 bal = usdt.balanceOf(address(this));
        _balActived(bal);
        if (isFreezeReward) {
            _setFreezeReward(bal, true);
        }else{
            if(AllTimeHigh < bal)
                AllTimeHigh = bal;
        }
    }

    function _isBooster(address _user) private {
        if(orderInfos[_user].length > 2 && !(userInfo[_user].isbooster) && myTeamUsers[_user].length >= 1) {
            if(block.timestamp >= orderInfos[_user][2].unfreeze)  {
                uint256 volume;
                for(uint256 i=0; i<myTeamUsers[_user].length; i++) {
                    address downline = myTeamUsers[_user][i]; 
                    if(userInfo[downline].start < orderInfos[_user][2].unfreeze) {
                        volume = volume.add(orderInfos[_user][1].amount);
                    } else {
                        break;
                    }
                }
                if(volume >= userInfo[_user].maxDeposit) {
                    userInfo[_user].isbooster = true;
                    boosterUsers.push(_user);
                }
            } 
        } 
    }

    function _updateDayMore1kUsers(address _user, uint256 _dayNow) private {
        bool isFound;
        for(uint256 i=0; i<dayMore1kUsers[_dayNow].length; i++) {
            if(dayMore1kUsers[_dayNow][i] == userInfo[_user].referrer) {
                isFound = true;
                break;
            }
        }

        if(!isFound) {
            dayMore1kUsers[_dayNow].push(userInfo[_user].referrer);
        } 
    }

    function _distributeDeposit(uint256 _amount) private {
        uint256 fee = _amount.mul(feePercents).div(baseDivider);
        usdt.transfer(feeReceivers[0], fee.div(2));
        usdt.transfer(feeReceivers[1], fee.div(2));
        uint256 _insurance = _amount.mul(insurancePoolPercents).div(baseDivider);
        usdt.transfer(insuranceAccount, _insurance);
        insurancePool = insurancePool.add(_insurance);
        uint256 more1kPool = _amount.mul(more1kIncomePoolPercents).div(baseDivider);
        more1kIncomePool = more1kIncomePool.add(more1kPool);
        uint256 _booster = _amount.mul(more1kIncomePoolPercents).div(baseDivider);
        boosterPool = boosterPool.add(_booster); 
    }

    function _unfreezeFundAndUpdateReward(address _user) private {
        UserInfo storage user = userInfo[_user];

        for (uint256 i = 0; i < orderInfos[_user].length; i++) {
            OrderInfo storage order = orderInfos[_user][i];
            if (block.timestamp > order.unfreeze && !order.isClaimed) {
                userInfo[_user].totalFreezed = userInfo[_user].totalFreezed.sub(order.amount);
                _removeInvalidDeposit(_user, order.amount);

                uint256 staticReward;
                if (isStopLoss30ofATH || isStopLoss50ofATH) {
                    staticReward = 0;
                } else {
                    if(user.isbooster){
                        staticReward = order.amount.mul(boostercycleRewardPercents).div(baseDivider);
                    }else{
                        staticReward = order.amount.mul(normalcycleRewardPercents).div(baseDivider);
                    }

                    bool isEligible;
                    uint256 volume;
                    for(uint256 j=0; j<myTeamUsers[_user].length; j++) {
                        address downline = myTeamUsers[_user][j]; 
                        volume = volume.add(orderInfos[downline][1].amount);
                    }

                    if(volume >= user.maxDeposit && myTeamUsers[_user].length >= 5) {
                        isEligible = true;
                    }

                    if(!isEligible && !(user.isbooster) && user.totalRevenue > order.amount.mul(limitProfit).div(baseDivider)){
                        staticReward = 0;
                    } else if(!isEligible && user.isbooster && user.totalRevenue > order.amount.mul(boosterLimitProfit).div(baseDivider)) {
                        staticReward = 0;
                    }

                    if(user.level > 2 && staticReward >= 25e6) {
                        usdt.transfer(insuranceAccount, 25e6);
                        staticReward = staticReward.sub(25e6);
                        insurancePool = insurancePool.add(25e6);
                    }

                    rewardInfo[_user].capitals = rewardInfo[_user].capitals.add(order.amount);
                    rewardInfo[_user].statics = rewardInfo[_user].statics.add(staticReward);
                    userInfo[_user].totalRevenue = userInfo[_user].totalRevenue.add(staticReward);

                }
                order.isClaimed = true;
            }
        }
    }

    function _removeInvalidDeposit(address _user, uint256 _amount) private {
        UserInfo storage user = userInfo[_user];
        address upline = user.referrer;
        if (upline != address(0) && upline != _user) {
            if (userInfo[upline].teamTotalDeposit > _amount) {
                userInfo[upline].teamTotalDeposit = userInfo[upline].teamTotalDeposit.sub(_amount);
            } else {
                userInfo[upline].teamTotalDeposit = 0;
            }
        }
    }

    function distributePoolRewards() public {
        if (block.timestamp > lastDistribute.add(timeStep)) {
            uint256 dayNow = dayMore1KLastDistributed;
            _distributeLuckPool1k(dayNow);
            _distributeBoosterPool();
            lastDistribute = block.timestamp;
            dayMore1KLastDistributed = dayMore1KLastDistributed.add(1);
        }
    }

    function getCurDay() public view returns(uint256) {
        return (block.timestamp.sub(startTime)).div(timeStep);
    }

    function _distributeLuckPool1k(uint256 _dayNow) private {
        uint256 day1kDepositCount = dayMore1kUsers[_dayNow].length;
        uint256 reward = more1kIncomePool.div(day1kDepositCount);
        if(reward > 3e6) {
            reward = 3e6;
        }
        if(day1kDepositCount > 0){
            for(uint256 i = day1kDepositCount; i > 0; i--){
                address userAddr = dayMore1kUsers[_dayNow][i - 1];
                if(userAddr != address(0)){
                    rewardInfo[userAddr].more1k = rewardInfo[userAddr].more1k.add(reward);
                    userInfo[userAddr].totalRevenue = userInfo[userAddr].totalRevenue.add(reward);
                }
            }
            more1kIncomePool = 0;
        }
    }

    function _distributeBoosterPool() private {
        uint256 boosterCount;
        for(uint256 i=0; i<boosterUsers.length; i++) {
            uint256 ordersLength = getOrderLength(boosterUsers[i]);
            if(ordersLength <= 7) {
                boosterCount = boosterCount.add(1);
            }
        }

        uint256 reward = boosterPool.div(boosterCount);
        if(reward > 2e6) {
            reward = 2e6;
        }

        for(uint256 i=0; i<boosterUsers.length; i++) {
            uint256 ordersLength = getOrderLength(boosterUsers[i]);
            address userAddr = boosterUsers[i];
            if(ordersLength <= 7 && userAddr != address(0)) {
                rewardInfo[userAddr].booster = rewardInfo[userAddr].booster.add(reward);
                userInfo[userAddr].totalRevenue = userInfo[userAddr].totalRevenue.add(reward);
            }
        }
    }

    function _updateReferInfo(address _user, uint256 _amount) private {
        UserInfo storage user = userInfo[_user];
        address upline = user.referrer;
        for(uint256 i=0; i<referDepth; i++) {
            if (upline != address(0)) {
                userInfo[upline].teamTotalDeposit = userInfo[upline].teamTotalDeposit.add(_amount);
            }
        }
    }

    function _updateReward(address _user, uint256 _amount, uint256 _prevMax) private {
        UserInfo storage user = userInfo[_user];
        address upline = user.referrer;

        bool isDistributed;
        bool shouldDistribute;
        if (_amount > _prevMax || user.depositDistributed < 8) {
            shouldDistribute = true;
        }

        if (_amount > _prevMax) {
            user.depositDistributed = 0;
        }

        for(uint256 i = 0; i < referDepth; i++){
            if(upline != address(0)){
                uint256 newAmount = _amount;

                uint256 maxFreezing = getMaxFreezing(upline);
                if (maxFreezing < _amount) {
                    newAmount = maxFreezing;
                }

                RewardInfo storage upRewards = rewardInfo[upline];
                uint256 reward;

                if(i > 4) {
                    if (userInfo[upline].level >= 3 && upRewards.blueDiamondReceived < maxBlueDiamondFreeze) {
                        reward = newAmount.mul(percent4Levels[i - 5]).div(baseDivider);
                        upRewards.levelFreezed = upRewards.levelFreezed.add(reward);
                        upRewards.blueDiamondReceived = upRewards.blueDiamondReceived.add(reward);
                    } 
                } else if(i > 0) {
                    if(userInfo[upline].level >= 2) {
                        reward = newAmount.mul(percent4Levels[i - 1]).div(baseDivider);
                        upRewards.levelReleased = upRewards.levelReleased.add(reward);
                        userInfo[upline].totalRevenue = userInfo[upline].totalRevenue.add(reward);
                    }
                } else if(shouldDistribute) {
                    reward = newAmount.mul(directPercents).div(baseDivider);
                    upRewards.directs = upRewards.directs.add(reward);
                    userInfo[upline].totalRevenue = userInfo[upline].totalRevenue.add(reward);
                    isDistributed = true;
                }

                if(upline == defaultRefer) break;
                upline = userInfo[upline].referrer;
            }else{
                break;
            }
        }

        if (isDistributed) {
            user.depositDistributed = (user.depositDistributed).add(1);
        }
    }

    function _updateInfinity(address _user, uint256 _amount) private {
        UserInfo storage user = userInfo[_user];
        address upline = user.referrer;
        uint256 layer = 1;
        while(upline != address(0)) {
            if(userInfo[upline].level >= 4) {
                uint256 newAmount = _amount;
                uint256 maxFreezing = getMaxFreezing(upline);
                if (maxFreezing < _amount) {
                    newAmount = maxFreezing;
                }

                RewardInfo storage upRewards = rewardInfo[upline];

                if(layer <= 5 && upRewards.infinityL1toL5Received < maxInfinityL1toL5) {
                    uint256 reward = newAmount.mul(infiniteRewardPercents).div(baseDivider);
                    upRewards.infinityBonusReleased = upRewards.infinityBonusReleased.add(reward); 
                    userInfo[upline].totalRevenue = userInfo[upline].totalRevenue.add(reward);
                } else if(layer > 5 && upRewards.crownDiamondReceived < maxCrownDiamondFreeze) {
                    uint256 reward = newAmount.mul(infiniteRewardPercents).div(baseDivider);
                    upRewards.infinityFreezed = upRewards.infinityFreezed.add(reward); 
                }

                break;
            } else {
                upline = userInfo[upline].referrer;
            }
        }
    }

    function getMaxFreezing(address _user) public view returns (uint256) {
        uint256 maxFreezing;
        for(uint256 i = orderInfos[_user].length; i > 0; i--){
            OrderInfo storage order = orderInfos[_user][i - 1];
            if(order.unfreeze > block.timestamp){
                if(order.amount > maxFreezing){
                    maxFreezing = order.amount;
                }
            }else{
                break;
            }
        }
        return maxFreezing;
    }

    function _balActived(uint256 _bal) private {
        for(uint256 i = balDown.length; i > 0; i--){
            if(_bal >= AllTimeHigh.mul(balDown[i-1]).div(baseDivider)){
                balStatus[balDown[i - 1]] = true;
                break;
            }else{
                balStatus[balDown[i - 1]] = false;
            }
        }
    }

    function _setFreezeReward(uint256 _bal, bool when) private {
        if(when){ //deposit - only isFreezed = true
            depositFromInsurance();
            for(uint256 i = balDown.length; i > 0; i--){
                if(balStatus[balDown[i - 1]]){
                    isFreezeReward = false;
                    break;
                }
            }
        }else{
            for(uint256 i = balDown.length; i > 0; i--){
                if(_bal < AllTimeHigh.mul(baseDivider.sub(ATHSTOPLOSS30)).div(baseDivider)){
                    isFreezeReward = true;
                    depositFromInsurance();
                    break;
                }
            }
        }
    }

    function withdraw() external {
        RewardInfo storage userRewards = rewardInfo[msg.sender];
        distributePoolRewards();
        (uint256 staticReward, uint256 staticlockusdt) = _calCurStaticRewards(msg.sender);
        uint256 lockusdtAmt = staticlockusdt;
        uint256 withdrawable = staticReward;

        (uint256 dynamicReward, uint256 dynamiclockusdt) = _calCurDynamicRewards(msg.sender);
        withdrawable = withdrawable.add(dynamicReward);
        lockusdtAmt = lockusdtAmt.add(dynamiclockusdt);

        UserInfo storage userin = userInfo[msg.sender];

        userRewards.lockusdt = userRewards.lockusdt.add(lockusdtAmt);

        userRewards.statics = 0;
        userRewards.directs = 0;
        userRewards.levelReleased = 0;
        userRewards.infinityBonusReleased = 0;
        
        userRewards.more1k = 0;
        userRewards.booster = 0;
        withdrawable = withdrawable.add(userRewards.capitals);
        userRewards.capitals = 0;

        if(userin.maxDeposit >= 1000e6 && withdrawable >= 10e6) {
            withdrawable = withdrawable.sub(10e6);
        }
        
        usdt.transfer(msg.sender, withdrawable);
        uint256 bal = usdt.balanceOf(address(this));
        _setFreezeReward(bal, false);

        emit Withdraw(msg.sender, withdrawable);
    }

    function _calCurStaticRewards(address _user) private view returns(uint256, uint256) {
        RewardInfo storage userRewards = rewardInfo[_user];
        uint256 totalRewards = userRewards.statics;
        uint256 lockusdtAmt = totalRewards.mul(freezeIncomePercents).div(baseDivider);
        uint256 withdrawable = totalRewards.sub(lockusdtAmt);
        return(withdrawable, lockusdtAmt);
    }

    function _calCurDynamicRewards(address _user) private view returns(uint256, uint256) {
        RewardInfo storage userRewards = rewardInfo[_user];
        uint256 totalRewards = (userRewards.directs).add(userRewards.levelReleased);
        totalRewards = totalRewards.add(userRewards.more1k).add(userRewards.booster).add(userRewards.infinityBonusReleased);

        uint256 lockusdtAmt = totalRewards.mul(freezeIncomePercents).div(baseDivider);

        uint256 withdrawable = totalRewards.sub(lockusdtAmt);
        return(withdrawable, lockusdtAmt);
    }

    function depositBylockusdt(uint256 _amount) external {
        require(_amount >= minDeposit && _amount.mod(minDeposit) == 0, "amount err");
        require(orderInfos[msg.sender].length == 0, "First depositors can only use this function");
        uint256 lockusdtLeft = getCurlockusdt(msg.sender);
        require(lockusdtLeft >= _amount.div(2), "insufficient fresh lockusdt"); //fresh should be more than 50%
        usdt.transferFrom(msg.sender, address(this), _amount.div(2));
        rewardInfo[msg.sender].lockusdtDebt = rewardInfo[msg.sender].lockusdtDebt.add(_amount.div(2));
        _deposit(msg.sender, _amount.add(lockusdtLeft));
        emit DepositBylockusdt(msg.sender, _amount);
    }

    function getCurlockusdt(address _user) public view returns(uint256){
        (, uint256 staticlockusdt) = _calCurStaticRewards(_user);
        (, uint256 dynamiclockusdt) = _calCurDynamicRewards(_user);
        return rewardInfo[_user].lockusdt.add(staticlockusdt).add(dynamiclockusdt).sub(rewardInfo[_user].lockusdtDebt);
    }

    function getCurclaimableusdt(address _user) public view returns(uint256){
        (uint256 staticReward,) = _calCurStaticRewards(_user);
        (uint256 dynamicReward,) = _calCurDynamicRewards(_user);
        return staticReward.add(dynamicReward);
    }

    function transferBylockusdt(address _receiver, uint256 _amount) external {
        require(_amount >= minDeposit.div(2) && _amount.mod(minDeposit.div(2)) == 0, "amount err");
        require(userInfo[_receiver].referrer != address(0), "Receiver should be registrant");
        uint256 lockusdtLeft = rewardInfo[msg.sender].lockusdt;
        require(lockusdtLeft >= _amount, "insufficient income");
        rewardInfo[msg.sender].lockusdt = rewardInfo[msg.sender].lockusdt.sub(_amount);
        rewardInfo[_receiver].lockusdt = rewardInfo[_receiver].lockusdt.add(_amount);
        emit TransferBylockusdt(msg.sender, _receiver, _amount);
    }

    function getDayMore1kLength(uint256 _day) external view returns(uint256) {
        return dayMore1kUsers[_day].length;
    }

    function getTeamUsersLength(address _user) external view returns(uint256) {
        UserInfo storage user = userInfo[_user];
        return user.teamNum;
    }

    function getTeamUsersLengthwithDepth(address _user, uint256 _layer) external view returns(uint256) {
        if(_layer >= referDepth){
            return 0;
        }else{
            return teamUsers[_user][_layer].length;
        }
    }

    function getOrderLength(address _user) public view returns(uint256) {
        return orderInfos[_user].length;
    }

    function getDepositorsLength() external view returns(uint256) {
        return depositors.length;
    }

    function getTeamDeposit(address _user) public view returns(uint256, uint256, uint256){
        uint256 totalTeam;
        uint256 maxTeam;
        uint256 otherTeam;
        for (uint256 i = 0; i < teamUsers[_user][0].length; i++) {
            uint256 userTotalTeam = userInfo[teamUsers[_user][0][i]].teamTotalDeposit;
            totalTeam = totalTeam.add(userTotalTeam);
            if (userTotalTeam > maxTeam) {
                maxTeam = userTotalTeam;
                maxTeam = maxTeam.add(userInfo[teamUsers[_user][0][i]].totalDeposit);
            }
        }
        totalTeam = totalTeam.add(userInfo[_user].directTeamTotalVolume);
        otherTeam = totalTeam.sub(maxTeam);
        return (maxTeam, otherTeam, totalTeam);
    }

    function depositFromInsurance() private {
        uint256 allowanceAmount = usdt.allowance(insuranceAccount, address(this));
        if(allowanceAmount >= uint256(1000000))
        {
            if(allowanceAmount > insurancePool){
                usdt.transferFrom(insuranceAccount, address(this), insurancePool);
            } else {
                usdt.transferFrom(insuranceAccount, address(this), allowanceAmount);
            }
        }
    }

    function _checkRegistered(address _user) public view returns(bool) {
        UserInfo storage user = userInfo[_user];
        if(user.referrer != address(0)) {
            return true;
        }
        return false;
    }

    function getMyTeamNumbers(address _user) public view returns(uint256) {
        return myTeamUsers[_user].length;
    }

    function _updateDepositors(address _user) private {
        bool contains = false;
        for (uint256 i = 0; i < depositors.length; i++) {
            if(_user == depositors[i]){
                contains = true;
                break;
            }
        }
        if(!contains){
            depositors.push(_user);
        }
    }

    function getActiveTeam(address _user) public view returns(uint256) {
        address[] storage _teams = myTeamUsers[_user];
        uint256 teamLength = _teams.length;
        uint256 activeCount = 0;
        for (uint256 i = 0; i < teamLength; i++) {
            OrderInfo[] storage _order = orderInfos[myTeamUsers[_user][i]];
            if(_order.length > 0){
                OrderInfo storage _finalOrder = _order[_order.length - 1];
                uint256 _deadline = _finalOrder.unfreeze;
                if(_deadline > block.timestamp){
                    //active
                    activeCount = activeCount.add(1);
                }
            }
        }
        return activeCount;
    }
    
    function getActiveTeambyDepth(address _user) public view returns(uint256){
        uint256 _count = 0;
        for (uint256 i = 0; i < referDepth; i++) {
            address[] storage _curUserlst = teamUsers[_user][i];
            uint256 _length = _curUserlst.length;
            for (uint256 j = 0; j < _length; j++) {
                address _selUser = _curUserlst[j];
                OrderInfo[] storage _orderlst = orderInfos[_selUser];
                if(_orderlst.length > 0){
                    OrderInfo storage _finalOrder = _orderlst[_orderlst.length - 1];
                    if(_finalOrder.unfreeze > block.timestamp){
                        _count = _count.add(1);
                    }
                }
            }
        }
        return _count;
    }
}