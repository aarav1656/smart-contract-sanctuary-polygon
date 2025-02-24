/**
 *Submitted for verification at polygonscan.com on 2022-10-18
*/

pragma solidity >=0.7.0 <0.9.0;
// SPDX-License-Identifier: MIT

/**
 * Contract Type : Staking
 * Staking of : Coin Coin_Dt3
 * Coin Address : 0x46dbcD4B7016EBb0a4046e1aEcAd6be8Db9426a9
 * Number of schemes : 1
 * Scheme 1 functions : stake, unstake
 * Referral Scheme : 2
*/

interface ERC20{
	function balanceOf(address account) external view returns (uint256);
	function transfer(address recipient, uint256 amount) external returns (bool);
	function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract Staking {

	address owner;
	uint256 public taxInterestBank0 = uint256(0);
	uint256 public taxPrincipalBank0 = uint256(0);
	struct record { uint256 stakeTime; uint256 stakeAmt; uint256 lastUpdateTime; uint256 accumulatedInterestToUpdateTime; }
	mapping(address => record) public addressMap;
	mapping(uint256 => address) public addressStore;
	uint256 public numberOfAddressesCurrentlyStaked = uint256(0);
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
 * checks that (ERC20's balanceOf function  with variable recipient as the address of this contract) is greater than or equals to _amt
 * calls ERC20's transfer function  with variable recipient as the address that called this function, variable amount as _amt
 * updates referralRecordMap (Element the address that called this function) (Entity unclaimedRewards) as (referralRecordMap with element the address that called this function with element unclaimedRewards) - (_amt)
*/
	function withdrawReferral(uint256 _amt) public {
		require((referralRecordMap[msg.sender].unclaimedRewards >= _amt), "Insufficient referral rewards to withdraw");
		require((ERC20(0x46dbcD4B7016EBb0a4046e1aEcAd6be8Db9426a9).balanceOf(address(this)) >= _amt), "Insufficient amount of the token in this contract to transfer out. Please contact the contract owner to top up the token.");
		ERC20(0x46dbcD4B7016EBb0a4046e1aEcAd6be8Db9426a9).transfer(msg.sender, _amt);
		referralRecordMap[msg.sender].unclaimedRewards  = (referralRecordMap[msg.sender].unclaimedRewards - _amt);
	}

/**
 * Function addReferral
 * The function takes in 1 variable, zero or a positive integer _amt. It can only be called by other functions in this contract. It does the following :
 * creates an internal variable referringAddress with initial value referralRecordMap with element the address that called this function with element referringAddress
 * if not referralRecordMap with element the address that called this function with element hasDeposited then (updates referralRecordMap (Element the address that called this function) (Entity hasDeposited) as true)
 * if referringAddress is equals to Address 0 then ()
 * updates referralRecordMap (Element referringAddress) (Entity unclaimedRewards) as (referralRecordMap with element referringAddress with element unclaimedRewards) + ((2) * (_amt))
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
		referralRecordMap[referringAddress].unclaimedRewards  = (referralRecordMap[referringAddress].unclaimedRewards + (uint256(2) * _amt));
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
 * Daily Interest Rate : .5
 * Address Map : addressMap
 * ERC20 Transfer : 0x46dbcD4B7016EBb0a4046e1aEcAd6be8Db9426a9, _stakeAmt
 * The function takes in 1 variable, zero or a positive integer _stakeAmt. It can be called by functions both inside and outside of this contract. It does the following :
 * checks that _stakeAmt is strictly greater than 0
 * creates an internal variable thisRecord with initial value addressMap with element the address that called this function
 * if (thisRecord with element stakeAmt) is equals to 0 then (updates addressMap (Element the address that called this function) as Struct comprising current time, (((_stakeAmt) * ((1000000) - (50000))) / (1000000)), current time, 0; then updates addressStore (Element numberOfAddressesCurrentlyStaked) as the address that called this function; and then updates numberOfAddressesCurrentlyStaked as (numberOfAddressesCurrentlyStaked) + (1)) otherwise (updates addressMap (Element the address that called this function) as Struct comprising current time, ((thisRecord with element stakeAmt) + (((_stakeAmt) * ((1000000) - (50000))) / (1000000))), current time, ((thisRecord with element accumulatedInterestToUpdateTime) + (((thisRecord with element stakeAmt) * ((current time) - (thisRecord with element lastUpdateTime)) * (5000)) / (86400000000))))
 * calls ERC20's transferFrom function  with variable sender as the address that called this function, variable recipient as the address of this contract, variable amount as _stakeAmt
 * calls addReferral with variable _amt as _stakeAmt
 * updates taxPrincipalBank0 as (taxPrincipalBank0) + (((_stakeAmt) * (100) * (50000)) / ((1000000) * (100)))
 * emits event Staked with inputs the address that called this function
*/
	function stake(uint256 _stakeAmt) public {
		require((_stakeAmt > uint256(0)), "Staked amount needs to be greater than 0");
		record memory thisRecord = addressMap[msg.sender];
		if ((thisRecord.stakeAmt == uint256(0))){
			addressMap[msg.sender]  = record (block.timestamp, ((_stakeAmt * (uint256(1000000) - uint256(50000))) / uint256(1000000)), block.timestamp, uint256(0));
			addressStore[numberOfAddressesCurrentlyStaked]  = msg.sender;
			numberOfAddressesCurrentlyStaked  = (numberOfAddressesCurrentlyStaked + uint256(1));
		}else{
			addressMap[msg.sender]  = record (block.timestamp, (thisRecord.stakeAmt + ((_stakeAmt * (uint256(1000000) - uint256(50000))) / uint256(1000000))), block.timestamp, (thisRecord.accumulatedInterestToUpdateTime + ((thisRecord.stakeAmt * (block.timestamp - thisRecord.lastUpdateTime) * uint256(5000)) / uint256(86400000000))));
		}
		ERC20(0x46dbcD4B7016EBb0a4046e1aEcAd6be8Db9426a9).transferFrom(msg.sender, address(this), _stakeAmt);
		addReferral(_stakeAmt);
		taxPrincipalBank0  = (taxPrincipalBank0 + ((_stakeAmt * uint256(100) * uint256(50000)) / (uint256(1000000) * uint256(100))));
		emit Staked(msg.sender);
	}

/**
 * Function unstake
 * The function takes in 1 variable, zero or a positive integer _unstakeAmt. It can be called by functions both inside and outside of this contract. It does the following :
 * creates an internal variable thisRecord with initial value addressMap with element the address that called this function
 * checks that _unstakeAmt is less than or equals to (thisRecord with element stakeAmt)
 * creates an internal variable newAccum with initial value (thisRecord with element accumulatedInterestToUpdateTime) + (((thisRecord with element stakeAmt) * ((current time) - (thisRecord with element lastUpdateTime)) * (5000)) / (86400000000))
 * creates an internal variable interestToRemove with initial value ((newAccum) * (_unstakeAmt)) / (thisRecord with element stakeAmt)
 * checks that (ERC20's balanceOf function  with variable recipient as the address of this contract) is greater than or equals to ((((_unstakeAmt) * ((1000000) - (50000))) / (1000000)) + (((interestToRemove) * ((1000000) - (50000))) / (1000000)))
 * calls ERC20's transfer function  with variable recipient as the address that called this function, variable amount as (((_unstakeAmt) * ((1000000) - (50000))) / (1000000)) + (((interestToRemove) * ((1000000) - (50000))) / (1000000))
 * updates totalWithdrawals as (totalWithdrawals) + (((interestToRemove) * ((1000000) - (50000))) / (1000000))
 * updates taxPrincipalBank0 as (taxPrincipalBank0) + (((thisRecord with element stakeAmt) * (100) * (50000)) / ((1000000) * (100)))
 * updates taxInterestBank0 as (taxInterestBank0) + (((interestToRemove) * (100) * (50000)) / ((1000000) * (100)))
 * if _unstakeAmt is equals to (thisRecord with element stakeAmt) then (repeat numberOfAddressesCurrentlyStaked times with loop variable i0 :  (if (addressStore with element Loop Variable i0) is equals to (the address that called this function) then (updates addressStore (Element Loop Variable i0) as addressStore with element (numberOfAddressesCurrentlyStaked) - (1); then updates numberOfAddressesCurrentlyStaked as (numberOfAddressesCurrentlyStaked) - (1); and then terminates the for-next loop)))
 * updates addressMap (Element the address that called this function) as Struct comprising (thisRecord with element stakeTime), ((thisRecord with element stakeAmt) - (_unstakeAmt)), (thisRecord with element lastUpdateTime), ((newAccum) - (interestToRemove))
 * emits event Unstaked with inputs the address that called this function
*/
	function unstake(uint256 _unstakeAmt) public {
		record memory thisRecord = addressMap[msg.sender];
		require((_unstakeAmt <= thisRecord.stakeAmt), "Withdrawing more than staked amount");
		uint256 newAccum = (thisRecord.accumulatedInterestToUpdateTime + ((thisRecord.stakeAmt * (block.timestamp - thisRecord.lastUpdateTime) * uint256(5000)) / uint256(86400000000)));
		uint256 interestToRemove = ((newAccum * _unstakeAmt) / thisRecord.stakeAmt);
		require((ERC20(0x46dbcD4B7016EBb0a4046e1aEcAd6be8Db9426a9).balanceOf(address(this)) >= (((_unstakeAmt * (uint256(1000000) - uint256(50000))) / uint256(1000000)) + ((interestToRemove * (uint256(1000000) - uint256(50000))) / uint256(1000000)))), "Insufficient amount of the token in this contract to transfer out. Please contact the contract owner to top up the token.");
		ERC20(0x46dbcD4B7016EBb0a4046e1aEcAd6be8Db9426a9).transfer(msg.sender, (((_unstakeAmt * (uint256(1000000) - uint256(50000))) / uint256(1000000)) + ((interestToRemove * (uint256(1000000) - uint256(50000))) / uint256(1000000))));
		totalWithdrawals  = (totalWithdrawals + ((interestToRemove * (uint256(1000000) - uint256(50000))) / uint256(1000000)));
		taxPrincipalBank0  = (taxPrincipalBank0 + ((thisRecord.stakeAmt * uint256(100) * uint256(50000)) / (uint256(1000000) * uint256(100))));
		taxInterestBank0  = (taxInterestBank0 + ((interestToRemove * uint256(100) * uint256(50000)) / (uint256(1000000) * uint256(100))));
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
 * Function interestEarnedUpToNowBeforeTaxesAndNotYetWithdrawn
 * The function takes in 1 variable, an address _address. It can be called by functions both inside and outside of this contract. It does the following :
 * creates an internal variable thisRecord with initial value addressMap with element _address
 * returns (thisRecord with element accumulatedInterestToUpdateTime) + (((thisRecord with element stakeAmt) * ((current time) - (thisRecord with element lastUpdateTime)) * (5000)) / (86400000000)) as output
*/
	function interestEarnedUpToNowBeforeTaxesAndNotYetWithdrawn(address _address) public view returns (uint256) {
		record memory thisRecord = addressMap[_address];
		return (thisRecord.accumulatedInterestToUpdateTime + ((thisRecord.stakeAmt * (block.timestamp - thisRecord.lastUpdateTime) * uint256(5000)) / uint256(86400000000)));
	}

/**
 * Function totalStakedAmount
 * The function takes in 0 variables. It can be called by functions both inside and outside of this contract. It does the following :
 * creates an internal variable total with initial value 0
 * repeat numberOfAddressesCurrentlyStaked times with loop variable i0 :  (creates an internal variable thisRecord with initial value addressMap with element addressStore with element Loop Variable i0; and then updates total as (total) + (thisRecord with element stakeAmt))
 * returns total as output
*/
	function totalStakedAmount() public view returns (uint256) {
		uint256 total = uint256(0);
		for (uint i0 = 0; i0 < numberOfAddressesCurrentlyStaked; i0++){
			record memory thisRecord = addressMap[addressStore[i0]];
			total  = (total + thisRecord.stakeAmt);
		}
		return total;
	}

/**
 * Function totalAccumulatedInterest
 * The function takes in 0 variables. It can be called by functions both inside and outside of this contract. It does the following :
 * creates an internal variable total with initial value 0
 * repeat numberOfAddressesCurrentlyStaked times with loop variable i0 :  (updates total as (total) + (interestEarnedUpToNowBeforeTaxesAndNotYetWithdrawn with variable _address as addressStore with element Loop Variable i0))
 * returns total as output
*/
	function totalAccumulatedInterest() public view returns (uint256) {
		uint256 total = uint256(0);
		for (uint i0 = 0; i0 < numberOfAddressesCurrentlyStaked; i0++){
			total  = (total + interestEarnedUpToNowBeforeTaxesAndNotYetWithdrawn(addressStore[i0]));
		}
		return total;
	}

/**
 * Function withdrawPrincipalTax0
 * The function takes in 0 variables. It can be called by functions both inside and outside of this contract. It does the following :
 * checks that (the address that called this function) is equals to Address 0xcb2A7dAF65bd94e74E1a0393912aD0fcc4a50c7f
 * checks that (ERC20's balanceOf function  with variable recipient as the address of this contract) is greater than or equals to taxPrincipalBank0
 * calls ERC20's transfer function  with variable recipient as the address that called this function, variable amount as taxPrincipalBank0
 * updates taxPrincipalBank0 as 0
*/
	function withdrawPrincipalTax0() public {
		require((msg.sender == address(0xcb2A7dAF65bd94e74E1a0393912aD0fcc4a50c7f)), "Not the withdrawal address");
		require((ERC20(0x46dbcD4B7016EBb0a4046e1aEcAd6be8Db9426a9).balanceOf(address(this)) >= taxPrincipalBank0), "Insufficient amount of the token in this contract to transfer out. Please contact the contract owner to top up the token.");
		ERC20(0x46dbcD4B7016EBb0a4046e1aEcAd6be8Db9426a9).transfer(msg.sender, taxPrincipalBank0);
		taxPrincipalBank0  = uint256(0);
	}

/**
 * Function withdrawInterestTax0
 * The function takes in 0 variables. It can be called by functions both inside and outside of this contract. It does the following :
 * checks that (the address that called this function) is equals to Address 0xcb2A7dAF65bd94e74E1a0393912aD0fcc4a50c7f
 * checks that (ERC20's balanceOf function  with variable recipient as the address of this contract) is greater than or equals to taxInterestBank0
 * calls ERC20's transfer function  with variable recipient as the address that called this function, variable amount as taxInterestBank0
 * updates taxInterestBank0 as 0
*/
	function withdrawInterestTax0() public {
		require((msg.sender == address(0xcb2A7dAF65bd94e74E1a0393912aD0fcc4a50c7f)), "Not the withdrawal address");
		require((ERC20(0x46dbcD4B7016EBb0a4046e1aEcAd6be8Db9426a9).balanceOf(address(this)) >= taxInterestBank0), "Insufficient amount of the token in this contract to transfer out. Please contact the contract owner to top up the token.");
		ERC20(0x46dbcD4B7016EBb0a4046e1aEcAd6be8Db9426a9).transfer(msg.sender, taxInterestBank0);
		taxInterestBank0  = uint256(0);
	}

/**
 * Function withdrawToken
 * The function takes in 1 variable, zero or a positive integer _amt. It can be called by functions both inside and outside of this contract. It does the following :
 * checks that the function is called by the owner of the contract
 * checks that (ERC20's balanceOf function  with variable recipient as the address of this contract) is greater than or equals to _amt
 * calls ERC20's transfer function  with variable recipient as the address that called this function, variable amount as _amt
*/
	function withdrawToken(uint256 _amt) public onlyOwner {
		require((ERC20(0x46dbcD4B7016EBb0a4046e1aEcAd6be8Db9426a9).balanceOf(address(this)) >= _amt), "Insufficient amount of the token in this contract to transfer out. Please contact the contract owner to top up the token.");
		ERC20(0x46dbcD4B7016EBb0a4046e1aEcAd6be8Db9426a9).transfer(msg.sender, _amt);
	}
}