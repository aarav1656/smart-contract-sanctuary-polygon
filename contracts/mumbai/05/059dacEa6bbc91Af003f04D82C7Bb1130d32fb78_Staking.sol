/**
 *Submitted for verification at polygonscan.com on 2022-09-30
*/

pragma solidity >=0.7.0 <0.9.0;
// SPDX-License-Identifier: MIT

/**
 * Contract Type : Staking
 * Staking of : Coin Coin_Testtoken
 * Coin Address : 0xA0Ec9Be4b42EB17a9FEF44127765080eC72017E3
 * Number of schemes : 1
 * Scheme 1 functions : stake, unstake
 * Referral Scheme : 1, 0.5
*/

interface ERC20{
	function transfer(address recipient, uint256 amount) external returns (bool);
	function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract Staking {

	address owner;
	struct record { uint256 stakeTime; uint256 stakeAmt; uint256 lastUpdateTime; uint256 accumulatedInterestToUpdateTime; }
	mapping(address => record) public addressMap;
	mapping(uint256 => address) public addressStore;
	uint256 public numberOfAddressesCurrentlyStaked = uint256(0);
	uint256 public dailyInterestRate = uint256(10000);
	uint256 public dailyInterestRate_1 = uint256(10000);
	uint256 public totalWithdrawals = uint256(0);
	struct referralRecord { bool hasDeposited; address referringAddress; uint256 unclaimedRewards; }
	mapping(address => referralRecord) public referralRecordMap;
	event Staked (address indexed account);
	event Unstaked (address indexed account);

	constructor() {
		owner = msg.sender;
	}

	//This function allows the owner to specify an address that will take over ownership rights instead. Please double check the address provided as once the function is executed, only the new owner will be able to change the address back.
	function changeOwner(address _newOwner) public onlyOwner {
		owner = _newOwner;
	}

	modifier onlyOwner() {
		require(msg.sender == owner);
		_;
	}

/**
 * Function withdrawReferral
 * The function takes in 1 variable, zero or a positive integer _amt. It can be called by functions both inside and outside of this contract. It does the following :
 * checks that (referralRecordMap with element the address that called this function with element unclaimedRewards) is greater than or equals to _amt
 * calls ERC20's transfer function  with variable recipient as the address that called this function, variable amount as _amt
 * updates referralRecordMap (Element the address that called this function) (Entity unclaimedRewards) as (referralRecordMap with element the address that called this function with element unclaimedRewards) - (_amt)
*/
	function withdrawReferral(uint256 _amt) public {
		require((referralRecordMap[msg.sender].unclaimedRewards >= _amt), "Insufficient referral rewards to withdraw");
		ERC20(0xA0Ec9Be4b42EB17a9FEF44127765080eC72017E3).transfer(msg.sender, _amt);
		referralRecordMap[msg.sender].unclaimedRewards  = (referralRecordMap[msg.sender].unclaimedRewards - _amt);
	}

/**
 * Function addReferral
 * The function takes in 1 variable, zero or a positive integer _amt. It can only be called by other functions in this contract. It does the following :
 * creates an internal variable referringAddress with initial value referralRecordMap with element the address that called this function with element referringAddress
 * if not referralRecordMap with element the address that called this function with element hasDeposited then (updates referralRecordMap (Element the address that called this function) (Entity hasDeposited) as true)
 * if referringAddress is equals to Address 0 then ()
 * updates referralRecordMap (Element referringAddress) (Entity unclaimedRewards) as (referralRecordMap with element referringAddress with element unclaimedRewards) + (_amt)
 * updates referringAddress as referralRecordMap with element referringAddress with element referringAddress
 * if referringAddress is equals to Address 0 then ()
 * updates referralRecordMap (Element referringAddress) (Entity unclaimedRewards) as (referralRecordMap with element referringAddress with element unclaimedRewards) + (((5) * (_amt)) / (10))
 * updates referringAddress as referralRecordMap with element referringAddress with element referringAddress
*/
	function addReferral(uint256 _amt) internal {
		address referringAddress = referralRecordMap[msg.sender].referringAddress;
		if (!(referralRecordMap[msg.sender].hasDeposited)){
			referralRecordMap[msg.sender].hasDeposited  = true;
		}
		if ((referringAddress == address(0))){
			return;
		}
		referralRecordMap[referringAddress].unclaimedRewards  = (referralRecordMap[referringAddress].unclaimedRewards + _amt);
		referringAddress  = referralRecordMap[referringAddress].referringAddress;
		if ((referringAddress == address(0))){
			return;
		}
		referralRecordMap[referringAddress].unclaimedRewards  = (referralRecordMap[referringAddress].unclaimedRewards + ((uint256(5) * _amt) / uint256(10)));
		referringAddress  = referralRecordMap[referringAddress].referringAddress;
	}

/**
 * Function addReferralAddress
 * The function takes in 1 variable, an address _referringAddress. It can only be called by functions outside of this contract. It does the following :
 * checks that referralRecordMap with element _referringAddress with element hasDeposited
 * checks that not _referringAddress is equals to (the address that called this function)
 * checks that (referralRecordMap with element the address that called this function with element referringAddress) is equals to Address 0
 * updates referralRecordMap (Element the address that called this function) (Entity referringAddress) as _referringAddress
*/
	function addReferralAddress(address _referringAddress) external {
		require(referralRecordMap[_referringAddress].hasDeposited, "Referring Address has not made a deposit");
		require(!((_referringAddress == msg.sender)), "Self-referrals are not allowed");
		require((referralRecordMap[msg.sender].referringAddress == address(0)), "User has previously indicated a referral address");
		referralRecordMap[msg.sender].referringAddress  = _referringAddress;
	}

/**
 * Function stake
 * Daily Interest Rate : Variable dailyInterestRate
 * This interest rate is modified under certain circumstances, as articulated in the consolidatedInterestRate function
 * Address Map : addressMap
 * ERC20 Transfer : 0xA0Ec9Be4b42EB17a9FEF44127765080eC72017E3, _stakeAmt
 * The function takes in 1 variable, zero or a positive integer _stakeAmt. It can be called by functions both inside and outside of this contract. It does the following :
 * checks that _stakeAmt is strictly greater than 0
 * creates an internal variable thisRecord with initial value addressMap with element the address that called this function
 * if (thisRecord with element stakeAmt) is equals to 0 then (updates addressMap (Element the address that called this function) as Struct comprising current time, _stakeAmt, current time, 0; then updates addressStore (Element numberOfAddressesCurrentlyStaked) as the address that called this function; and then updates numberOfAddressesCurrentlyStaked as (numberOfAddressesCurrentlyStaked) + (1)) otherwise (updates addressMap (Element the address that called this function) as Struct comprising current time, ((thisRecord with element stakeAmt) + (_stakeAmt)), current time, ((thisRecord with element accumulatedInterestToUpdateTime) + (((thisRecord with element stakeAmt) * ((current time) - (thisRecord with element lastUpdateTime)) * (consolidatedInterestRate with variable _stakedAmt as thisRecord with element stakeAmt)) / (86400000000))))
 * calls ERC20's transferFrom function  with variable sender as the address that called this function, variable recipient as the address of this contract, variable amount as _stakeAmt
 * calls addReferral with variable _amt as _stakeAmt
 * emits event Staked with inputs the address that called this function
*/
	function stake(uint256 _stakeAmt) public {
		require((_stakeAmt > uint256(0)), "Staked amount needs to be greater than 0");
		record memory thisRecord = addressMap[msg.sender];
		if ((thisRecord.stakeAmt == uint256(0))){
			addressMap[msg.sender]  = record (block.timestamp, _stakeAmt, block.timestamp, uint256(0));
			addressStore[numberOfAddressesCurrentlyStaked]  = msg.sender;
			numberOfAddressesCurrentlyStaked  = (numberOfAddressesCurrentlyStaked + uint256(1));
		}else{
			addressMap[msg.sender]  = record (block.timestamp, (thisRecord.stakeAmt + _stakeAmt), block.timestamp, (thisRecord.accumulatedInterestToUpdateTime + ((thisRecord.stakeAmt * (block.timestamp - thisRecord.lastUpdateTime) * consolidatedInterestRate(thisRecord.stakeAmt)) / uint256(86400000000))));
		}
		ERC20(0xA0Ec9Be4b42EB17a9FEF44127765080eC72017E3).transferFrom(msg.sender, address(this), _stakeAmt);
		addReferral(_stakeAmt);
		emit Staked(msg.sender);
	}

/**
 * Function unstake
 * The function takes in 1 variable, zero or a positive integer _unstakeAmt. It can be called by functions both inside and outside of this contract. It does the following :
 * creates an internal variable thisRecord with initial value addressMap with element the address that called this function
 * checks that _unstakeAmt is less than or equals to (thisRecord with element stakeAmt)
 * creates an internal variable newAccum with initial value (thisRecord with element accumulatedInterestToUpdateTime) + (((thisRecord with element stakeAmt) * ((current time) - (thisRecord with element lastUpdateTime)) * (consolidatedInterestRate with variable _stakedAmt as thisRecord with element stakeAmt)) / (86400000000))
 * creates an internal variable interestToRemove with initial value ((newAccum) * (_unstakeAmt)) / (thisRecord with element stakeAmt)
 * calls ERC20's transfer function  with variable recipient as the address that called this function, variable amount as (_unstakeAmt) + (interestToRemove)
 * updates totalWithdrawals as (totalWithdrawals) + (interestToRemove)
 * if _unstakeAmt is equals to (thisRecord with element stakeAmt) then (repeat numberOfAddressesCurrentlyStaked times with loop variable i0 :  (if (addressStore with element Loop Variable i0) is equals to (the address that called this function) then (updates addressStore (Element Loop Variable i0) as addressStore with element (numberOfAddressesCurrentlyStaked) - (1); then updates numberOfAddressesCurrentlyStaked as (numberOfAddressesCurrentlyStaked) - (1); and then terminates the for-next loop)))
 * updates addressMap (Element the address that called this function) as Struct comprising (thisRecord with element stakeTime), ((thisRecord with element stakeAmt) - (_unstakeAmt)), (thisRecord with element lastUpdateTime), ((newAccum) - (interestToRemove))
 * emits event Unstaked with inputs the address that called this function
*/
	function unstake(uint256 _unstakeAmt) public {
		record memory thisRecord = addressMap[msg.sender];
		require((_unstakeAmt <= thisRecord.stakeAmt), "Withdrawing more than staked amount");
		uint256 newAccum = (thisRecord.accumulatedInterestToUpdateTime + ((thisRecord.stakeAmt * (block.timestamp - thisRecord.lastUpdateTime) * consolidatedInterestRate(thisRecord.stakeAmt)) / uint256(86400000000)));
		uint256 interestToRemove = ((newAccum * _unstakeAmt) / thisRecord.stakeAmt);
		ERC20(0xA0Ec9Be4b42EB17a9FEF44127765080eC72017E3).transfer(msg.sender, (_unstakeAmt + interestToRemove));
		totalWithdrawals  = (totalWithdrawals + interestToRemove);
		if ((_unstakeAmt == thisRecord.stakeAmt)){
			for (uint i0 = 0; i0 < numberOfAddressesCurrentlyStaked; i0++){
				if ((addressStore[i0] == msg.sender)){
					addressStore[i0]  = addressStore[(numberOfAddressesCurrentlyStaked - uint256(1))];
					numberOfAddressesCurrentlyStaked  = (numberOfAddressesCurrentlyStaked - uint256(1));
					break;
				}
			}
		}
		addressMap[msg.sender]  = record (thisRecord.stakeTime, (thisRecord.stakeAmt - _unstakeAmt), thisRecord.lastUpdateTime, (newAccum - interestToRemove));
		emit Unstaked(msg.sender);
	}

/**
 * Function updateRecordsWithLatestInterestRates
 * The function takes in 0 variables. It can only be called by other functions in this contract. It does the following :
 * repeat numberOfAddressesCurrentlyStaked times with loop variable i0 :  (creates an internal variable thisRecord with initial value addressMap with element addressStore with element Loop Variable i0; and then updates addressMap (Element addressStore with element Loop Variable i0) as Struct comprising (thisRecord with element stakeTime), (thisRecord with element stakeAmt), current time, ((thisRecord with element accumulatedInterestToUpdateTime) + (((thisRecord with element stakeAmt) * ((current time) - (thisRecord with element lastUpdateTime)) * (consolidatedInterestRate with variable _stakedAmt as Loop Variable i0)) / (86400000000))))
*/
	function updateRecordsWithLatestInterestRates() internal {
		for (uint i0 = 0; i0 < numberOfAddressesCurrentlyStaked; i0++){
			record memory thisRecord = addressMap[addressStore[i0]];
			addressMap[addressStore[i0]]  = record (thisRecord.stakeTime, thisRecord.stakeAmt, block.timestamp, (thisRecord.accumulatedInterestToUpdateTime + ((thisRecord.stakeAmt * (block.timestamp - thisRecord.lastUpdateTime) * consolidatedInterestRate(i0)) / uint256(86400000000))));
		}
	}

/**
 * Function interestEarnedUpToNowBeforeTaxesAndNotYetWithdrawn
 * The function takes in 1 variable, an address _address. It can be called by functions both inside and outside of this contract. It does the following :
 * creates an internal variable thisRecord with initial value addressMap with element _address
 * returns (thisRecord with element accumulatedInterestToUpdateTime) + (((thisRecord with element stakeAmt) * ((current time) - (thisRecord with element lastUpdateTime)) * (consolidatedInterestRate with variable _stakedAmt as thisRecord with element stakeAmt)) / (86400000000)) as output
*/
	function interestEarnedUpToNowBeforeTaxesAndNotYetWithdrawn(address _address) public view returns (uint256) {
		record memory thisRecord = addressMap[_address];
		return (thisRecord.accumulatedInterestToUpdateTime + ((thisRecord.stakeAmt * (block.timestamp - thisRecord.lastUpdateTime) * consolidatedInterestRate(thisRecord.stakeAmt)) / uint256(86400000000)));
	}

/**
 * Function consolidatedInterestRate
 * The function takes in 1 variable, zero or a positive integer _stakedAmt. It can be called by functions both inside and outside of this contract. It does the following :
 * if _stakedAmt is greater than or equals to 100000000000000000000 then (returns dailyInterestRate_1 as output)
 * returns dailyInterestRate as output
*/
	function consolidatedInterestRate(uint256 _stakedAmt) public view returns (uint256) {
		if ((_stakedAmt >= uint256(100000000000000000000))){
			return dailyInterestRate_1;
		}
		return dailyInterestRate;
	}

/**
 * Function modifyDailyInterestRate
 * Notes for _dailyInterestRate : 10000 is one percent
 * The function takes in 1 variable, zero or a positive integer _dailyInterestRate. It can be called by functions both inside and outside of this contract. It does the following :
 * checks that the function is called by the owner of the contract
 * calls updateRecordsWithLatestInterestRates
 * updates dailyInterestRate as _dailyInterestRate
*/
	function modifyDailyInterestRate(uint256 _dailyInterestRate) public onlyOwner {
		updateRecordsWithLatestInterestRates();
		dailyInterestRate  = _dailyInterestRate;
	}

/**
 * Function modifyDailyInterestRate_1
 * Notes for _dailyInterestRate : 10000 is one percent
 * The function takes in 1 variable, zero or a positive integer _dailyInterestRate. It can be called by functions both inside and outside of this contract. It does the following :
 * checks that the function is called by the owner of the contract
 * calls updateRecordsWithLatestInterestRates
 * updates dailyInterestRate_1 as _dailyInterestRate
*/
	function modifyDailyInterestRate_1(uint256 _dailyInterestRate) public onlyOwner {
		updateRecordsWithLatestInterestRates();
		dailyInterestRate_1  = _dailyInterestRate;
	}

/**
 * Function withdrawToken
 * The function takes in 1 variable, zero or a positive integer _amt. It can be called by functions both inside and outside of this contract. It does the following :
 * checks that the function is called by the owner of the contract
 * calls ERC20's transfer function  with variable recipient as the address that called this function, variable amount as _amt
*/
	function withdrawToken(uint256 _amt) public onlyOwner {
		ERC20(0xA0Ec9Be4b42EB17a9FEF44127765080eC72017E3).transfer(msg.sender, _amt);
	}
}