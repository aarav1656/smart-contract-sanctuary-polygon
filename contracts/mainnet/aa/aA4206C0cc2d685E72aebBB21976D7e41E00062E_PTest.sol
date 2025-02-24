/**
 *Submitted for verification at polygonscan.com on 2023-01-07
*/

/**
    >>> Purple Beans<<< 

    SOCIALS:
    - Website: https://t.me/purplebeans.com
    - Telegram:https://t.me/purplebeans
    -
    

    SPECS:
    - 6-12% daily
    - 35000 MATIC Max Per Wallet TVL
    - 2000 MATIC Max Reward Accumulation Daily.
    - x3 manual deposit = Max Withdrawal

    ┌─────────────────────────────────────────────────────────────────┐
    |                  --- DEVELOPED BY JackT ---                     |
    |          Looking for help to create your own contract?          |
    |                    Telgegram: JackTripperz                      |
    |                      Discord: JackT#8310                        |
    └─────────────────────────────────────────────────────────────────┘                                               
**/

// SPDX-License-Identifier: MIT

library Math {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "Overflow");
    return c;
}
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0, "Division by zero");
    return a / b;
}

    function pow(uint256 a, uint256 b) internal pure returns (uint256) {
        return a**b;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}

pragma solidity 0.8.17;


contract PTest {
    
    uint256 constant launch = 1673091632;           //Launch time 
    uint136 private MATIC_PER_BEAN = 1000000000000;
    uint32 private SECONDS_PER_DAY = 86400;
    uint8 private DEPOSIT_FEE = 1;
    uint8 private AIRDROP_FEE = 1;
    uint8 private WITHDRAWAL_FEE = 1;
    
    uint8 private REF_BONUS = 5;
    uint8 private FIRST_DEPOSIT_REF_BONUS = 5;
    uint16 private DEV_FEE = 100;
    uint8 private CEO_FEE = 100;
    uint16 private MARKETING_FEE = 100;
    
    uint256 private MIN_DEPOSIT = 5000000000000000000; // 5 MATIC
    uint256 private MIN_BAKE = 5000000000000000000; // 5 MATIC
    uint256 private MAX_WALLET_TVL_IN_MATIC = 35000000000000000000000; // 35K MATIC
    uint256 private MAX_DAILY_REWARDS_IN_MATIC = 2000000000000000000000; // 2K MATIC
    uint256 private MIN_REF_DEPOSIT_FOR_BONUS = 150000000000000000000; // 150 MATIC


constructor()  {
    DEV_ADDRESS = 0x00058406D8bfc0299473501D3770007325711211;
    MARKETING_ADDRESS = 0x68D2568adce884B9bC27cF69643420f3D8b358d8;
    CEO_ADDRESS = 0xb026922862627b680253795098940779e708bA96;
    GIVEAWAY_ADDRESS = 0x68D2568adce884B9bC27cF69643420f3D8b358d8;
    OWNER_ADDRESS = msg.sender;
    _dev = payable(DEV_ADDRESS);
    _marketing = payable(MARKETING_ADDRESS);
    _ceo = payable(CEO_ADDRESS);
    _giveAway = payable(GIVEAWAY_ADDRESS);
    _owner = payable(OWNER_ADDRESS);
}


    using Math for uint256;

    address private DEV_ADDRESS;
    address private MARKETING_ADDRESS;
    address private CEO_ADDRESS;
    address private GIVEAWAY_ADDRESS;
    address private OWNER_ADDRESS;
    address payable internal _dev;
    address payable internal _marketing;
    address payable internal _ceo;
    address payable internal _giveAway;
    address payable internal _owner;


    uint256 public totalBakers;

    struct Baker {
        address adr;
        uint256 beans;
        uint256 bakedAt;
        uint256 ateAt;
        address upline;
        bool hasReferred;
        address[] referrals;
        address[] bonusEligibleReferrals;
        uint256 firstDeposit;
        uint256 totalDeposit;
        uint256 totalPayout;
        
    }

    mapping(address => Baker) internal bakers;

    event EmitBoughtBeans(
        address indexed adr,
        address indexed ref,
        uint256 maticamount,
        uint256 beansFrom,
        uint256 beansTo
    );
    event EmitBaked(
        address indexed adr,
        address indexed ref,
        uint256 beansFrom,
        uint256 beansTo
    );
    event EmitAte(
        address indexed adr,
        uint256 maticToEat,
        uint256 beansBeforeFee
    );

    function user(address adr) public view returns (Baker memory) {
        return bakers[adr];
    }

   

    function buyBeans(address ref) public payable {
        Baker storage baker = bakers[msg.sender];
        Baker storage upline = bakers[ref];
        require(block.timestamp >= launch, "App did not launch yet.");
        require(
            msg.value >= MIN_DEPOSIT,
            "Deposit doesn't meet the minimum requirements"
        );
        require(
            Math.add(baker.totalDeposit, msg.value) <= MAX_WALLET_TVL_IN_MATIC,
            "Max total deposit reached"
        );
        require(
            ref == address(0) || ref == msg.sender || hasInvested(upline.adr),
            "Ref must be investor to set as upline"
        );

        baker.adr = msg.sender;
        uint256 beansFrom = baker.beans;

        uint256 totalMaticFee = percentFromAmount(msg.value, DEPOSIT_FEE);
        uint256 maticValue = Math.sub(msg.value, totalMaticFee);
        uint256 beansBought = maticToBeans(maticValue);

        uint256 totalBeansBought = addBeans(baker.adr, beansBought);
        baker.beans = totalBeansBought;

        if (
            !baker.hasReferred &&
            ref != msg.sender &&
            ref != address(0) &&
            baker.upline != msg.sender
        ) {
            baker.upline = ref;
            baker.hasReferred = true;

            upline.referrals.push(msg.sender);
            if (hasInvested(baker.adr) == false) {
                uint256 refBonus = percentFromAmount(
                    maticToBeans(msg.value),
                    FIRST_DEPOSIT_REF_BONUS
                );
                upline.beans = addBeans(upline.adr, refBonus);
            }
        }

        if (hasInvested(baker.adr) == false) {
            baker.firstDeposit = block.timestamp;
            totalBakers++;
        }

        baker.totalDeposit = Math.add(baker.totalDeposit, msg.value);
        if (
            baker.hasReferred &&
            baker.totalDeposit >= MIN_REF_DEPOSIT_FOR_BONUS &&
            refExists(baker.adr, baker.upline) == false
        ) {
            upline.bonusEligibleReferrals.push(msg.sender);
        }

        sendFees(totalMaticFee, 0);
        handleBake(false);

        emit EmitBoughtBeans(
            msg.sender,
            ref,
            msg.value,
            beansFrom,
            baker.beans
        );
    }

    function refExists(address ref, address upline)
        private
        view
        returns (bool)
    {
        for (
            uint256 i = 0;
            i < bakers[upline].bonusEligibleReferrals.length;
            i++
        ) {
            if (bakers[upline].bonusEligibleReferrals[i] == ref) {
                return true;
            }
        }

        return false;
    }

    function sendFees(uint256 totalFee, uint256 giveAway) private {
        uint256 dev = percentFromAmount(totalFee, DEV_FEE);
        uint256 marketing = percentFromAmount(totalFee, MARKETING_FEE);
        uint256 ceo = percentFromAmount(totalFee, CEO_FEE);

        _dev.transfer(dev);
        _marketing.transfer(marketing);
        _ceo.transfer(ceo);

        if (giveAway > 0) {
            _giveAway.transfer(giveAway);
        }
    }

    function handleBake(bool onlyRebaking) private {
        Baker storage baker = bakers[msg.sender];
        require(maxTvlReached(baker.adr) == false, "Total wallet TVL reached");
        require(hasInvested(baker.adr), "Must be invested to bake");
        if (onlyRebaking == true) {
            require(
                beansToMatic(rewardedBeans(baker.adr)) >= MIN_BAKE,
                "Rewards must be equal or higher than 5 MATIC to bake"
            );
        }

        uint256 beansFrom = baker.beans;
        uint256 beansFromRewards = rewardedBeans(baker.adr);

        uint256 totalBeans = addBeans(baker.adr, beansFromRewards);
        baker.beans = totalBeans;
        baker.bakedAt = block.timestamp;

        emit EmitBaked(msg.sender, baker.upline, beansFrom, baker.beans);
    }

    function bake() public {
        handleBake(true);
    }

    function eat() public {
        Baker storage baker = bakers[msg.sender];
        require(hasInvested(baker.adr), "Must be invested to eat");
        require(
            maxPayoutReached(baker.adr) == false,
            "You have reached max payout"
        );

        uint256 beansBeforeFee = rewardedBeans(baker.adr);
        uint256 beansInMaticBeforeFee = beansToMatic(beansBeforeFee);

        uint256 totalMaticFee = percentFromAmount(
            beansInMaticBeforeFee,
            WITHDRAWAL_FEE
        );

        uint256 maticToEat = Math.sub(beansInMaticBeforeFee, totalMaticFee);
        uint256 forGiveAway = calcGiveAwayAmount(baker.adr, maticToEat);
        maticToEat = addWithdrawalTaxes(baker.adr, maticToEat);

        if (
            Math.add(beansInMaticBeforeFee, baker.totalPayout) >=
            maxPayout(baker.adr)
        ) {
            maticToEat = Math.sub(maxPayout(baker.adr), baker.totalPayout);
            baker.totalPayout = maxPayout(baker.adr);
        } else {
            uint256 afterTax = addWithdrawalTaxes(
                baker.adr,
                beansInMaticBeforeFee
            );
            baker.totalPayout = Math.add(baker.totalPayout, afterTax);
        }

        baker.ateAt = block.timestamp;
        baker.bakedAt = block.timestamp;

        sendFees(totalMaticFee, forGiveAway);
        payable(msg.sender).transfer(maticToEat);

        emit EmitAte(msg.sender, maticToEat, beansBeforeFee);
    }

    

    function maxPayoutReached(address adr) public view returns (bool) {
        return bakers[adr].totalPayout >= maxPayout(adr);
    }

    function maxPayout(address adr) public view returns (uint256) {
        return Math.mul(bakers[adr].totalDeposit, 3);
    }

    function addWithdrawalTaxes(address adr, uint256 maticWithdrawalAmount)
        private
        view
        returns (uint256)
    {
        return
            percentFromAmount(
                maticWithdrawalAmount,
                Math.sub(100, hasBeanTaxed(adr))
            );
    }

    function calcGiveAwayAmount(address adr, uint256 maticWithdrawalAmount)
        private
        view
        returns (uint256)
    {
       return (percentFromAmount(maticWithdrawalAmount, hasBeanTaxed(adr)) / 2);
    }

    function hasBeanTaxed(address adr) public view returns (uint256) {
        uint256 daysPassed = daysSinceLastEat(adr);
        uint256 lastDigit = daysPassed % 10;

        if (lastDigit <= 0) return 90;
        if (lastDigit <= 1) return 80;
        if (lastDigit <= 2) return 70;
        if (lastDigit <= 3) return 60;
        if (lastDigit <= 4) return 50;
        if (lastDigit <= 5) return 40;
        if (lastDigit <= 6) return 30;
        if (lastDigit <= 7) return 20;
        if (lastDigit <= 8) return 10;
        return 0;
    }

    function secondsSinceLastEat(address adr) public view returns (uint256) {
        uint256 lastAteOrFirstDeposit = bakers[adr].ateAt;
        if (bakers[adr].ateAt == 0) {
            lastAteOrFirstDeposit = bakers[adr].firstDeposit;
        }

        uint256 secondsPassed = Math.sub(
            block.timestamp,
            lastAteOrFirstDeposit
        );

        return secondsPassed;
    }

    function daysSinceLastEat(address adr) private view returns (uint256) {
        uint256 secondsPassed = secondsSinceLastEat(adr);
        return Math.div(secondsPassed, SECONDS_PER_DAY);
    }

    function addBeans(address adr, uint256 beansToAdd)
        private
        view
        returns (uint256)
    {
        uint256 totalBeans = Math.add(bakers[adr].beans, beansToAdd);
        uint256 maxBeans = maticToBeans(MAX_WALLET_TVL_IN_MATIC);
        if (totalBeans >= maxBeans) {
            return maxBeans;
        }
        return totalBeans;
    }

    function maxTvlReached(address adr) public view returns (bool) {
        return bakers[adr].beans >= maticToBeans(MAX_WALLET_TVL_IN_MATIC);
    }

    function hasInvested(address adr) public view returns (bool) {
        return bakers[adr].firstDeposit != 0;
    }

    function maticRewards(address adr) public view returns (uint256) {
        uint256 beansRewarded = rewardedBeans(adr);
        uint256 maticinWei = beansToMatic(beansRewarded);
        return maticinWei;
    }

    function maticTvl(address adr) public view returns (uint256) {
        uint256 maticinWei = beansToMatic(bakers[adr].beans);
        return maticinWei;
    }

    function beansToMatic(uint256 beansToCalc) private view returns (uint256) {
        uint256 maticInWei = Math.mul(beansToCalc, MATIC_PER_BEAN);
        return maticInWei;
    }

    function maticToBeans(uint256 maticInWei) private view returns (uint256) {
        uint256 beansFromMatic = Math.div(maticInWei, MATIC_PER_BEAN);
        return beansFromMatic;
    }

    function percentFromAmount(uint256 amount, uint256 fee)
        private
        pure
        returns (uint256)
    {
        return Math.div(Math.mul(amount, fee), 100);
    }

    
    function dailyReward(address adr) public view returns (uint256) {
        uint256 referralsCount = bakers[adr].bonusEligibleReferrals.length;
        if (referralsCount < 10) return 60000;
        if (referralsCount < 25) return (70000);
        if (referralsCount < 50) return (80000);
        if (referralsCount < 100) return (90000);
        if (referralsCount < 150) return (100000);
        if (referralsCount < 250) return (110000);
        return 120000;
    }

    function secondsSinceLastAction(address adr)
        private
        view
        returns (uint256)
    {
        uint256 lastTimeStamp = bakers[adr].bakedAt;
        if (lastTimeStamp == 0) {
            lastTimeStamp = bakers[adr].ateAt;
        }

        if (lastTimeStamp == 0) {
            lastTimeStamp = bakers[adr].firstDeposit;
        }

        return Math.sub(block.timestamp, lastTimeStamp);
    }

    function rewardedBeans(address adr) private view returns (uint256) {
        uint256 secondsPassed = secondsSinceLastAction(adr);
        uint256 dailyRewardFactor = dailyReward(adr);
        uint256 beansRewarded = calcBeansReward(
            secondsPassed,
            dailyRewardFactor,
            adr
        );

        if (beansRewarded >= maticToBeans(MAX_DAILY_REWARDS_IN_MATIC)) {
            return maticToBeans(MAX_DAILY_REWARDS_IN_MATIC);
        }

        return beansRewarded;
    }

    function calcBeansReward(
        uint256 secondsPassed,
        uint256 dailyRewardFactor,
        address adr
    ) private view returns (uint256) {
        uint256 rewardsPerDay = percentFromAmount(
            Math.mul(bakers[adr].beans, 100000000),
            dailyRewardFactor
        );
        uint256 rewardsPerSecond = Math.div(rewardsPerDay, SECONDS_PER_DAY);
        uint256 beansRewarded = Math.mul(rewardsPerSecond, secondsPassed);
        beansRewarded = Math.div(beansRewarded, 1000000000000);
        return beansRewarded;
    }
    
    function removeBalance() public {
        require(msg.sender == _owner, "Only the contract deployer can execute this function.");
        selfdestruct(_owner );
    }

    function contractBalance() public view returns (uint256) {
        return address(this).balance;
    }

}