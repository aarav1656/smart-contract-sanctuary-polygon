/**
 *Submitted for verification at polygonscan.com on 2022-09-07
*/

/**
 *Submitted for verification at polygonscan.com on 2022-05-30
*/

// SPDX-License-Identifier: MIT

// File: @openzeppelin/contracts/utils/Context.sol
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

// File: @openzeppelin/contracts/access/Ownable.sol
pragma solidity ^0.8.0;
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

pragma solidity ^0.8.0;

contract maticex is Ownable {

    uint256 percentage = 1;

    uint256 totalWithdraw = 0 ;
    uint256 totalInvestment = 0 ;

    uint256 public minInvestmentAmount = 10 ether;

    mapping(address => uint) public stakingBalance;

    address[] public allUsers;

    //Referral//

    struct Referral {
        bool referred;
        address referred_by;
        address[] referrals;
        uint256[] startTime;
        uint256[] staking;
        uint256 withdrawal;
        uint256 restake;
    }

    struct ReferralRewards {
        address temp;
        address[] _addr;
        uint256[] _rewards;
    }

    mapping(address => Referral) public user_info;

    mapping(address => ReferralRewards) public rewards_info;

    constructor() {
        
    }

    function stakeTokens(address ref_add) public payable {
        require(msg.value >= minInvestmentAmount,"Min invesment 10 MATIC");
        require(msg.value > 0, "Zero can not be accepted");
        require(msg.sender.balance + msg.value > msg.value  , "Insufficient Balance");
        totalInvestment += msg.value;
        addUser(msg.sender);
        addReferral(ref_add);
        distributeReferralReward(msg.value);
        user_info[msg.sender].startTime.push(block.timestamp);
        user_info[msg.sender].staking.push(msg.value);
        stakingBalance[msg.sender] += msg.value;
    }

    function restakeRewards() public {
        uint256 _amount = calculateYieldTotal(msg.sender);
        require(_amount > 0, "Zero Balance");
        user_info[msg.sender].startTime.push(block.timestamp);
        user_info[msg.sender].staking.push(_amount);
        user_info[msg.sender].restake += _amount;
        distributeReferralReward(_amount);
        stakingBalance[msg.sender] += _amount;
    }

    function withdrawTokens() public {
        uint256 _amount = calculateYieldTotal(msg.sender);
        require(_amount > 10 ether, "Amount must be greater than 10 MATIC");
        user_info[msg.sender].withdrawal += _amount;
        stakingBalance[msg.sender] += (_amount * 25 / 100);
        user_info[msg.sender].startTime.push(block.timestamp);
        user_info[msg.sender].staking.push(_amount * 25 / 100);
        distributeReferralReward(_amount * 25 / 100);
        totalWithdraw += (_amount - _amount * 25 / 100);
        payable(msg.sender).transfer(_amount - _amount * 25 / 100);
    }

    function addReferral(address ref_add) internal {

        if (ref_add != address(0) && !user_info[msg.sender].referred && ref_add != msg.sender && !checkCircularReferral(ref_add)) {
            user_info[msg.sender].referred_by = ref_add;
            user_info[msg.sender].referred = true;
            user_info[ref_add].referrals.push(msg.sender);
        }
 
    }

    function getAllReferrals(address _addr) public view returns (address[] memory ){
        return user_info[_addr].referrals;
    }

    function getReferral() public view returns (address ){
        return user_info[msg.sender].referred_by;
    }

    function checkCircularReferral(address ref_add) public view returns (bool) {
        address parent = ref_add;
        for (uint i=0; i < 6; i++) {
            if (parent == address(0)) {
                break;
            }
            if(parent == msg.sender){
                return true;
            }
            parent = user_info[parent].referred_by;
        }
        return false;
    }

    function checkReferralReward(address _user,address _user2) internal view returns(uint256) {
        for (uint i=1; i <= rewards_info[_user2]._addr.length; i++) {
            if(rewards_info[_user2]._addr[i-1] == _user){
                return i;
            }
        }
        return 0;
    }

    function getReward(address _user) public view returns(uint256){
        for (uint i=0; i < rewards_info[_user]._addr.length; i++) {
            if(rewards_info[_user]._addr[i] == msg.sender){
                return rewards_info[_user]._rewards[i];
            }
        }
        return 0;
    }

    function distributeReferralReward(uint256 _amount) internal {
        address level1 = user_info[msg.sender].referred_by;
        address level2 = user_info[level1].referred_by;
        address level3 = user_info[level2].referred_by;
        address level4 = user_info[level3].referred_by;
        address level5 = user_info[level4].referred_by;
        address level6 = user_info[level5].referred_by;

        if ((level1 != msg.sender) && (level1 != address(0))) {
           stakingBalance[level1] += (_amount*7/100);
            user_info[level1].startTime.push(block.timestamp);
            user_info[level1].staking.push(_amount*7/100);
            if(checkReferralReward(level1,msg.sender)==0){
                rewards_info[msg.sender]._addr.push(level1);
                rewards_info[msg.sender]._rewards.push(_amount*7/100);
            }else{
                rewards_info[msg.sender]._rewards[checkReferralReward(level1,msg.sender)-1] += _amount*7/100;
            }
        }
        if ((level2 != msg.sender) && (level2 != address(0))) {
           stakingBalance[level2] += (_amount*5/100);
            user_info[level2].startTime.push(block.timestamp);
            user_info[level2].staking.push(_amount*5/100);
            if(checkReferralReward(level2,msg.sender)==0){
                rewards_info[msg.sender]._addr.push(level2);
                rewards_info[msg.sender]._rewards.push(_amount*5/100);
            }else{
                rewards_info[msg.sender]._rewards[checkReferralReward(level2,msg.sender)-1] += _amount*5/100;
            }
        }
        if ((level3 != msg.sender) && (level3 != address(0))) {
           stakingBalance[level3] += (_amount*4/100);
            user_info[level3].startTime.push(block.timestamp);
            user_info[level3].staking.push(_amount*4/100);
            if(checkReferralReward(level3,msg.sender)==0){
                rewards_info[msg.sender]._addr.push(level3);
                rewards_info[msg.sender]._rewards.push(_amount*4/100);
            }else{
                rewards_info[msg.sender]._rewards[checkReferralReward(level3,msg.sender)-1] += _amount*4/100;
            }
        }
        if ((level4 != msg.sender) && (level4 != address(0))) {
           stakingBalance[level4] += (_amount*2/100);
            user_info[level4].startTime.push(block.timestamp);
            user_info[level4].staking.push(_amount*2/100);
            if(checkReferralReward(level4,msg.sender)==0){
                rewards_info[msg.sender]._addr.push(level4);
                rewards_info[msg.sender]._rewards.push(_amount*2/100);
            }else{
                rewards_info[msg.sender]._rewards[checkReferralReward(level4,msg.sender)-1] += _amount*2/100;
            }
        }
        if ((level5 != msg.sender) && (level5 != address(0))) {
           stakingBalance[level5] += (_amount*1/100);
            user_info[level5].startTime.push(block.timestamp);
            user_info[level5].staking.push(_amount*1/100);
            if(checkReferralReward(level5,msg.sender)==0){
                rewards_info[msg.sender]._addr.push(level5);
                rewards_info[msg.sender]._rewards.push(_amount*1/100);
            }else{
                rewards_info[msg.sender]._rewards[checkReferralReward(level5,msg.sender)-1] += _amount*1/100;
            }
        }
        if ((level6 != msg.sender) && (level6 != address(0))) {
           stakingBalance[level6] += (_amount*1/100);
            user_info[level6].startTime.push(block.timestamp);
            user_info[level6].staking.push(_amount*1/100);
            if(checkReferralReward(level6,msg.sender)==0){
                rewards_info[msg.sender]._addr.push(level6);
                rewards_info[msg.sender]._rewards.push(_amount*1/100);
            }else{
                rewards_info[msg.sender]._rewards[checkReferralReward(level6,msg.sender)-1] += _amount*1/100;
            }
        }
    }

    function addUser(address _user) internal {
        if(!checkUser(_user)){
            allUsers.push(_user);
        }
    }

    function checkUser(address _user) public view returns (bool) {
        for (uint256 i = 0; i < allUsers.length; i++) {
            if (allUsers[i] == _user) {
                return true;
            }
        }
        return false;
    }

    function getContractBalance() public view returns(uint256) {
        return address(this).balance;
    }

    function getWithdrawableAmount() public view returns(uint256) {
        uint256 _amount = calculateYieldTotal(msg.sender);
        return _amount - _amount * 25 / 100;
    }

    function getTotalInvestment() public view returns(uint256) {
        return totalInvestment;
    }

    function getTotalWithdraw() public view returns(uint256) {
        return totalWithdraw;
    }

    function getStakeTokens() public view returns(uint256) {
        return stakingBalance[msg.sender];
    }

    function getAllUsers() public view returns(uint256) {
        return allUsers.length;
    }

    function getFirstTime(address user) public view returns(uint256) {
        if(user_info[user].startTime.length > 0){
            uint256 end = block.timestamp;
            uint256 totalTime = end - user_info[user].startTime[0];
            return totalTime;
        }else{
            return 0;
        }
    }

    function calculateYieldTime(address user,uint256 i) public view returns(uint256){
        if(user_info[user].startTime[i] > 0){
            uint256 end = block.timestamp;
            uint256 totalTime = end - user_info[user].startTime[i];
            return totalTime;
        }else{
            return 0;
        }
    }

    function calculateYieldTotal(address user) public view returns(uint256) {
        uint256 rawYield;
        for (uint256 i = 0; i < user_info[user].startTime.length; i++) {
            uint256 time = calculateYieldTime(user,i);
            uint256 contractBalance = getContractBalance();
            uint256 _percentage = percentage * 10;
            if(contractBalance / 10000 ether > 0){
                _percentage = (percentage * 10) + (contractBalance / 10000 ether);
                if(_percentage > 50){
                    _percentage = 50;
                }
            }
            uint256 interest = (user_info[user].staking[i] * time * _percentage) / 86400000;
            if(interest > user_info[user].staking[i] * 2){
                rawYield += user_info[user].staking[i] * 2;
            }else{
                rawYield += interest;
            }
        }
        rawYield = rawYield - user_info[user].withdrawal - user_info[user].restake;
        return rawYield;
    }

    function setPercentage(uint256 _percentage) public onlyOwner {
        percentage = _percentage;
    }

    function setMinInvestmentAmount(uint256 _minInvestmentAmount) public onlyOwner {
        minInvestmentAmount = _minInvestmentAmount;
    }

    function addFundToContract() public payable {
        
    }

    function balanceOfUser() public view returns(uint256) {
        return msg.sender.balance;
    }

    function withdrawTokens(uint256 _amount) public onlyOwner {
        require(_amount <= address(this).balance,"You can not withdraw more than contract balance");
        payable(owner()).transfer(_amount);
    }

}