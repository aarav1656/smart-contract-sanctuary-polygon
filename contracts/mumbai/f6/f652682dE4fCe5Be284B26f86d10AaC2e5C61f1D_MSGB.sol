// SPDX-License-Identifier: GPLv3

pragma solidity ^0.8.18;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MSGB {
    using SafeMath for uint256; 
    uint256 private constant baseDivider = 10000;
    uint256 private constant incomeFeePercents = 700;
    uint256 private constant minDepositable = 50e6;
    uint256 private constant maxDepositable = 3000e6;
    uint256 private constant baseDeposit = 500e6;
    // 进场控制
    uint256 private constant initDayNewbies = 5; // 初始每天进场人数
    uint256 private constant incInterval = 2; // 增加进场人数间隔
    uint256 private constant incNumber = 1; // 每次增加人数
    uint256 private constant unlimitDay = 365; // 接触限制日期

    // 首单赠送比例
    uint256 private constant firstOrderBonusPercents = 500;
    
    // 拆分分配比例
    uint256 private constant splitPercents = 3000;

    uint256 private constant transferFeePercents = 1000;

    uint256 private constant timeStep = 10 minutes;
    uint256 private constant dayPerCycle = 100 minutes; 
    uint256 private constant dayRewardPercents = 150;
    uint256 private constant maxAddFreeze = 300 minutes;
    uint256[20] private invitePercents = [500, 100, 200, 300, 200, 100, 100, 100, 50, 50, 50, 50, 30, 30, 30, 30, 30, 30, 30, 30];

    uint256[5] private levelDeposit = [50e6, 500e6, 1000e6, 2000e6, 3000e6];
    uint256[5] private levelInvite = [0, 0, 0, 10000e6, 20000e6];
    uint256[5] private levelTeam = [0, 0, 0, 5, 20];

    // 余额控制
    uint256[5] private balReached = [50e9, 100e9, 200e9, 500e9, 1000e9];
    uint256[5] private balFreeze = [35e9, 70e9, 100e9, 300e9, 500e9];
    uint256[5] private balUnfreeze = [50e9, 150e9, 200e9, 500e9, 1000e9];
    mapping(uint256=>bool) private balStatus;
    mapping(address=>mapping(uint256=>bool)) private isUnfreezedReward; // user=>free times=>status

    // 是否冻结中
    bool private isFreezing;
    // 冻结次数
    uint256 private freezedTimes;
    // 冻结时间
    mapping(uint256=>uint256) private freezeTime;
    // 解冻时间
    mapping(uint256=>uint256) private unfreezeTime;

    // 未回本账户增加存款倍数
    uint256 private depositMultipleWithoutIncomePercents = 15000;
    // 回本账号增加存款倍数
    uint256 private depositMultipleWithIncomePercents = 20000;

    // 竞猜参数
    uint256[20] private predictWinnerPercents = [3000, 2000, 1000, 500, 500, 200, 200, 200, 200, 200, 200, 200, 200, 200, 200, 200, 200, 200, 200, 200];
    uint256 private constant predictDuration = 5 minutes;
    uint256 private constant predictFee = 1e6;
    // 每个用户每天最高竞猜次数
    uint256 private constant dayPredictLimit = 10;
    uint256 private constant searchStep = 10e6;
    uint256 private constant predictPoolPercents = 300;
    uint256 private constant maxSearchDepth = 3000;
    uint256 private predictPool;
    uint256 private totalPredictPool;
    uint256 private totalWinners;
    mapping(uint256=>uint256) private dayPredictReward;
    mapping(uint256=>uint256) private dayDeposits;
    mapping(uint256=>mapping(address=>PredictInfo[])) private userPredicts;// day=>user=>predicts
    mapping(uint256=>mapping(uint256=>address[])) private dayPredictors; // day=>amount=>users

    IERC20 private usdt;
    address private feeReceiver;
    address private defaultRefer;
    uint256 private startTime;
    uint256 private lastDistribute;
    uint256 private totalUsers;
    mapping(uint256=>address[]) private dayNewbies;
    
    address[] private depositors;

    struct UserInfo {
        address referrer;
        uint256 level;
        uint256 maxDeposit;
        uint256 maxDepositable;
        uint256 teamNum;
        uint256 teamTotalDeposit;
        uint256 totalFreezed;
        uint256 totalRevenue;
        uint256 unfreezeIndex;
        uint256 startTime;
        bool isMaxFreezing;
    }

    struct RewardInfo{
        uint256 capitals;
        uint256 statics;
        uint256 invited;
        uint256 bonus;
        uint256 l5Freezed;
        uint256 l5Released;
        uint256 predictWin;
        uint256 split;
        uint256 lastWithdaw;
    }

    struct OrderInfo {
        uint256 amount;
        uint256 start;
        uint256 unfreeze; 
        bool isUnfreezed;
    }

    struct PredictInfo {
        uint256 time;
        uint256 number;
    }

    mapping(address=>UserInfo) private userInfo;
    mapping(address=>RewardInfo) private rewardInfo;
    mapping(address=>OrderInfo[]) private orderInfos;
    mapping(address=>mapping(uint256=>uint256)) private userCycleMax;
    mapping(address=>mapping(uint256=>address[])) private teamUsers;

    event Register(address user, address referral);
    event Deposit(address user, uint256 amount);
    event DepositBySplit(address user, uint256 amount);
    event Redeposit(address user, uint256 amount);
    event TransferBySplit(address user, uint256 subBal, address receiver, uint256 amount);
    event Withdraw(address user, uint256 withdrawable);
    event Predict(uint256 time, address user, uint256 number);
    event DistributePredictPool(uint256 day, uint256 reward, uint256 time);

    constructor(address _usdtAddr, address _defaultRefer, address _feeReceiver, uint256 _startTime) {
        usdt = IERC20(_usdtAddr);
        defaultRefer = _defaultRefer;
        feeReceiver = _feeReceiver;
        startTime = _startTime;
        lastDistribute = _startTime;
    }

    function register(address _referral) external {
        require(userInfo[_referral].maxDeposit > 0 || _referral == defaultRefer, "invalid refer");
        require(userInfo[msg.sender].referrer == address(0), "referrer bonded");
        userInfo[msg.sender].referrer = _referral;
        emit Register(msg.sender, _referral);
    }

    function deposit(uint256 _amount) external {
        _deposit(msg.sender, _amount, 0);
        emit Deposit(msg.sender, _amount);
    }

    function depositBySplit(uint256 _amount) public {
        _deposit(msg.sender, _amount, 1);
        emit DepositBySplit(msg.sender, _amount);

    }

    function redeposit() public {
        _deposit(msg.sender, 0, 2);
        emit Redeposit(msg.sender, 0);
    }

    // types: 0: 正常投资， 1: 拆分投资, 2: 续存
    function _deposit(address _userAddr, uint256 _amount, uint256 _types) private {
        require(block.timestamp >= startTime, "not start");
        UserInfo storage user = userInfo[_userAddr];
        RewardInfo storage userRewards = rewardInfo[_userAddr];
        // 条件判断
        require(user.referrer != address(0), "not register");

        if(_types == 0){
            usdt.transferFrom(_userAddr, address(this), _amount);
        }else if(_types == 1){
            require(user.level == 0, "actived");
            require(userRewards.split >= _amount, "insufficient split");
            userRewards.split = userRewards.split.sub(_amount);
        }else{
            require(orderInfos[_userAddr].length > 0, "no order");
            if(isFreezing) require(isUnfreezedReward[_userAddr][freezedTimes], "unfreeze first");
            OrderInfo storage order = orderInfos[_userAddr][user.unfreezeIndex];
            _amount = order.amount;
        }
        
        // 获取当前可投信息
        uint256 curCycle = getCurCycle();
        (uint256 userCurMin, uint256 userCurMax) = getUserCycleDepositable(_userAddr, curCycle);
        require(_amount >= userCurMin && _amount <= userCurMax && _amount.mod(minDepositable) == 0, "amount err");

        // 更新系统信息
        uint256 curDay = getCurDay();
        dayDeposits[curDay] = dayDeposits[curDay].add(_amount);
        depositors.push(_userAddr);

        if(user.level == 0){
            if(curDay < unlimitDay) require(dayNewbies[curDay].length < getMaxDayNewbies(curDay), "reach max day newbies");
            dayNewbies[curDay].push(_userAddr);
            totalUsers = totalUsers + 1;
            user.startTime = block.timestamp;
            userRewards.bonus = _amount.mul(firstOrderBonusPercents).div(baseDivider);
        }

        // 更新上级奖励
        _updateUplineReward(_userAddr, _amount);
        // 解冻订单或奖励
        _unfreezeCapitalOrReward(_userAddr, _amount, _types);
        // 生成新订单
        bool isMaxFreezing = _addNewOrder(_userAddr, _amount, _types, user.startTime, user.isMaxFreezing);
        user.isMaxFreezing = isMaxFreezing;
        // 更新最大可投
        _updateUserMax(_userAddr, _amount, userCurMax, curCycle);
        // 个人升级
    }

    function _updateUplineReward(address _userAddr, uint256 _amount) private {
        address upline = userInfo[_userAddr].referrer;
        for(uint256 i = 0; i < invitePercents.length; i++){
            if(upline != address(0)){
                if(!isFreezing || isUnfreezedReward[_userAddr][freezedTimes]){
                    OrderInfo[] storage upOrders = orderInfos[upline];
                    if(upOrders.length > 0){
                        uint256 latestUnFreezeTime = getOrderUnfreezeTime(upline, upOrders.length - 1);
                        uint256 maxFreezing = latestUnFreezeTime > block.timestamp ? upOrders[upOrders.length - 1].amount : 0;
                        uint256 newAmount = maxFreezing < _amount ? maxFreezing : _amount;
                        if(newAmount > 0){
                            RewardInfo storage upRewards = rewardInfo[upline];
                            uint256 reward = newAmount.mul(invitePercents[i]).div(baseDivider);
                            if(i == 0 || (i < 4 && userInfo[upline].level >= 4)){
                                upRewards.invited = upRewards.invited.add(reward);
                                userInfo[upline].totalRevenue = userInfo[upline].totalRevenue.add(reward);
                            }else if(userInfo[upline].level == 5){
                                upRewards.l5Freezed = upRewards.l5Freezed.add(reward);
                            }
                        }
                    }
                }
                if(upline == defaultRefer) break;
                upline = userInfo[upline].referrer;
            }else{
                break;
            }
        }
    }

    function _unfreezeCapitalOrReward(address _userAddr, uint256 _amount, uint256 _types) private {
        (uint256 unfreezed, uint256 rewards) = _unfreezeOrder(_userAddr, _amount);
        if(_types >= 2){
            require(unfreezed == _amount, "unfreeze err");
        }else{
            _updateFreezeAndTeamDeposit(_userAddr, _amount, unfreezed);
        }

        UserInfo storage user = userInfo[_userAddr];
        RewardInfo storage userRewards = rewardInfo[_userAddr];
        if(unfreezed > 0){// 更新静态奖
            user.unfreezeIndex = user.unfreezeIndex + 1;
            if(rewards > 0){
                // 首单奖
                if(userRewards.bonus > 0){
                    rewards = rewards.add(userRewards.bonus);
                    userRewards.bonus = 0;
                }
                userRewards.statics = userRewards.statics.add(rewards);
                if(_types < 2){
                    userRewards.capitals = userRewards.capitals.add(unfreezed);
                }
            }
        }else{// 解冻动态奖
            uint256 l5Freezed = userRewards.l5Freezed;
            if(l5Freezed > 0){
                rewards = _amount <= l5Freezed ? _amount : l5Freezed;
                userRewards.l5Freezed = l5Freezed.sub(rewards);
                userRewards.l5Released = userRewards.l5Released.add(rewards);
            }
        }

        user.totalRevenue = user.totalRevenue.add(rewards);
    }

    function _unfreezeOrder(address _userAddr, uint256 _amount) private returns(uint256 unfreezed, uint256 rewards){
        if(orderInfos[_userAddr].length > 0){
            UserInfo storage user = userInfo[_userAddr];
            OrderInfo storage order = orderInfos[_userAddr][user.unfreezeIndex];
            uint256 orderUnfreezeTime = getOrderUnfreezeTime(_userAddr, user.unfreezeIndex);
            if(order.isUnfreezed == false && block.timestamp >= orderUnfreezeTime && _amount >= order.amount){
                order.isUnfreezed = true;
                unfreezed = order.amount;
                rewards = order.amount.mul(dayRewardPercents).mul(dayPerCycle).div(timeStep).div(baseDivider);
                if(isFreezing){
                    if(isUnfreezedReward[_userAddr][freezedTimes] && user.totalFreezed > user.totalRevenue){
                        uint256 leftCapital = user.totalFreezed.sub(user.totalRevenue);
                        if(rewards > leftCapital){
                            rewards = leftCapital;
                        }
                    }else{
                        rewards = 0;
                    }
                }
            }
        }
    }

    function _updateFreezeAndTeamDeposit(address _userAddr, uint256 _amount, uint256 _unfreezed) private {
        UserInfo storage user = userInfo[_userAddr];
        if(_amount > _unfreezed){
            uint256 incAmount = _amount.sub(_unfreezed);
            user.totalFreezed = user.totalFreezed.add(incAmount);
            address upline = user.referrer;
            for(uint256 i = 0; i < invitePercents.length; i++){
                if(upline != address(0)){
                    // newbie
                    UserInfo storage upUser = userInfo[upline];
                    if(user.level == 0 && _userAddr != upline){
                        upUser.teamNum = upUser.teamNum + 1;
                        teamUsers[upline][i].push(_userAddr);
                    }
                    upUser.teamTotalDeposit = upUser.teamTotalDeposit.add(incAmount);
                    if(upline == defaultRefer) break;
                    upline = upUser.referrer;
                }else{
                    break;
                }
            }
        }
    }

        // 生成新订单
    function _addNewOrder(address _userAddr, uint256 _amount, uint256 _types, uint256 _startTime, bool _isMaxFreezing) private returns(bool isMaxFreezing){
        uint256 addFreeze;
        OrderInfo[] storage orders = orderInfos[_userAddr];
        if(_isMaxFreezing){
            isMaxFreezing = true;
        }else{
            if((isFreezing && _types == 1) || (!isFreezing && _startTime < freezeTime[freezedTimes])){
                isMaxFreezing = true;
            }else{
                addFreeze = (orders.length).mul(timeStep);
                if(addFreeze > maxAddFreeze) isMaxFreezing = true;
            }
        }
        uint256 unfreeze = isMaxFreezing ? block.timestamp.add(dayPerCycle).add(maxAddFreeze) : block.timestamp.add(dayPerCycle).add(addFreeze);
        orders.push(OrderInfo(_amount, block.timestamp, unfreeze, false));
    }

    function _updateUserMax(address _userAddr, uint256 _amount, uint256 _userCurMax, uint256 _curCycle) internal {
        UserInfo storage user = userInfo[_userAddr];
        // 更新最高投资额
        if(_amount > user.maxDeposit) user.maxDeposit = _amount;

        // 更新当前轮最大可投
        userCycleMax[_userAddr][_curCycle] = _userCurMax;
        // 更新下轮最大可投
        uint256 nextMaxDepositable;
        if(_amount == _userCurMax){
            uint256 curMaxDepositable = getCurlMaxDepositable();
            nextMaxDepositable = _userCurMax >= curMaxDepositable ? curMaxDepositable : _userCurMax.add(baseDeposit);
        }else{
            nextMaxDepositable = _userCurMax;
        }
        userCycleMax[_userAddr][_curCycle + 1] = nextMaxDepositable;
        user.maxDepositable = nextMaxDepositable;
    }

    function predict(uint256 _amount) external {
        require(userInfo[msg.sender].referrer != address(0), "not register");
        require(_amount.mod(searchStep) == 0, "amount err");
        uint256 curDay = getCurDay();
        require(userPredicts[curDay][msg.sender].length < dayPredictLimit, "reached day limit");
        uint256 predictEnd = startTime.add(curDay.mul(timeStep)).add(predictDuration);
        require(block.timestamp < predictEnd, "today is over");
        usdt.transferFrom(msg.sender, address(this), predictFee);
        dayPredictors[curDay][_amount].push(msg.sender);
        userPredicts[curDay][msg.sender].push(PredictInfo(block.timestamp, _amount));
        emit Predict(block.timestamp, msg.sender, _amount);
    }

    function getOrderUnfreezeTime(address _userAddr, uint256 _index) public view returns(uint256 orderUnfreezeTime) {
        if(_index < orderInfos[_userAddr].length){
            OrderInfo storage order = orderInfos[_userAddr][_index];
            orderUnfreezeTime = order.unfreeze;
            // 老用户的老订单增加锁定时间
            if(!isFreezing && userInfo[_userAddr].startTime < freezeTime[freezedTimes]){
                if(order.unfreeze < unfreezeTime[freezedTimes]){
                    orderUnfreezeTime = unfreezeTime[freezedTimes].add(dayPerCycle).add(maxAddFreeze);
                }else{
                    if(order.start <= unfreezeTime[freezedTimes]) orderUnfreezeTime = orderUnfreezeTime.add(maxAddFreeze);
                }
            }
        }
    }

    function getUserCycleDepositable(address _userAddr, uint256 _cycle) public view returns(uint256 cycleMin, uint256 cycleMax) {
        UserInfo storage user = userInfo[_userAddr];
        if(user.maxDeposit > 0){
            cycleMin = user.maxDeposit;
            cycleMax = userCycleMax[_userAddr][_cycle];
            if(cycleMax == 0) cycleMax = user.maxDepositable;
            // 冻结中，解冻后的老用户处理
            if(isFreezing){
                if(user.startTime < freezeTime[freezedTimes] && !isUnfreezedReward[_userAddr][freezedTimes]){
                    // 未回本
                    cycleMin = user.totalFreezed > user.totalRevenue ? cycleMin.mul(depositMultipleWithoutIncomePercents).div(baseDivider) : cycleMin.mul(depositMultipleWithIncomePercents).div(baseDivider);
                    cycleMax = getCurlMaxDepositable();
                }
            }else{
                if(user.startTime < freezeTime[freezedTimes]) cycleMax = getCurlMaxDepositable();
            }
        }else{
            cycleMin = minDepositable;
            cycleMax = baseDeposit;
        }
    }

    function getTeamDeposit(address _userAddr) public view returns(uint256 maxTeam, uint256 otherTeam, uint256 totalTeam){
        address[] memory directTeamUsers = teamUsers[_userAddr][0];
        for(uint256 i = 0; i < directTeamUsers.length; i++){
            UserInfo storage user = userInfo[directTeamUsers[i]];
            uint256 userTotalTeam = user.teamTotalDeposit.add(user.totalFreezed);
            totalTeam = totalTeam.add(userTotalTeam);
            if(userTotalTeam > maxTeam) maxTeam = userTotalTeam;
            if(i >= maxSearchDepth) break;
        }
        otherTeam = totalTeam.sub(maxTeam);
    }

    function getCurDay() public view returns(uint256) {
        return (block.timestamp.sub(startTime)).div(timeStep);
    }

    function getCurCycle() public view returns(uint256) {
        return (block.timestamp.sub(startTime)).div(dayPerCycle);
    }

    function getCurlMaxDepositable() public view returns(uint256) {
        return maxDepositable.mul(freezedTimes + 1);
    }

    function getMaxDayNewbies(uint256 _day) public pure returns(uint256) {
        return initDayNewbies + _day.mul(incNumber).div(incInterval);
    }

    function getOrderLength(address _userAddr) public view returns(uint256) {
        return orderInfos[_userAddr].length;
    }

    function getLatestDepositors(uint256 _length) public view returns(address[] memory latestDepositors) {
        uint256 totalCount = depositors.length;
        if(_length > totalCount) _length = totalCount;
        latestDepositors = new address[](_length);
        for(uint256 i = totalCount; i > totalCount - _length; i--){
            latestDepositors[totalCount - i] = depositors[i - 1];
        }
    }

    function getTeamUsers(address _userAddr, uint256 _layer) public view returns(address[] memory) {
        return teamUsers[_userAddr][_layer];
    }

    function getUserDayPredicts(address _userAddr, uint256 _day) public view returns(PredictInfo[] memory) {
        return userPredicts[_day][_userAddr];
    }

    function getDayPredictors(uint256 _day, uint256 _number) external view returns(address[] memory) {
        return dayPredictors[_day][_number];
    }

    function getDayInfos(uint256 _day) external view returns(address[] memory, uint256, uint256){
        return (dayNewbies[_day], dayDeposits[_day], dayPredictReward[_day]);
    }

    function getUserInfos(address _userAddr) external view returns(UserInfo memory user, RewardInfo memory reward, OrderInfo[] memory orders, bool unfreeze) {
        user = userInfo[_userAddr];
        reward = rewardInfo[_userAddr];
        orders = orderInfos[_userAddr];
        unfreeze = isUnfreezedReward[_userAddr][freezedTimes];
    }

    function getBalStatus(uint256 _bal) external view returns(bool) {
        return balStatus[_bal];
    }

    function getUserCycleMax(address _userAddr, uint256 _cycle) external view returns(uint256){
        return userCycleMax[_userAddr][_cycle];
    }

    function getContractInfos() external view returns(address[3] memory infos0, uint256[9] memory infos1, bool freezing) {
        infos0[0] = address(usdt);
        infos0[1] = feeReceiver;
        infos0[2] = defaultRefer;

        infos1[0] = startTime;
        infos1[1] = lastDistribute;
        infos1[2] = totalUsers;
        infos1[3] = predictPool;
        infos1[4] = totalPredictPool;
        infos1[5] = totalWinners;
        infos1[6] = freezedTimes;
        infos1[7] = freezeTime[freezedTimes];
        infos1[8] = unfreezeTime[freezedTimes];
        freezing = isFreezing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
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