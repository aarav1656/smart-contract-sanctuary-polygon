/**
 *Submitted for verification at polygonscan.com on 2022-08-01
*/

pragma solidity >=0.7.0 <0.9.0;
// SPDX-License-Identifier: MIT

/**
 * Contract Type : Staking
 * Staking of : Coin GuildFiToken
 * Coin Address : 0x7EFD8beC4A6E928747Fc9bB4c1DEF138F1C4Cfa4
 * Number of schemes : 1
 * Scheme 1 functions : stake, unstake
*/

interface ERC20{
	function transfer(address recipient, uint256 amount) external returns (bool);
	function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract Staking {

	address owner;
	struct record { uint256 stakeTime; uint256 stakeAmt; uint256 lastUpdateTime; uint256 accumulatedInterestToUpdateTime; }
	mapping(address => record) public addressMap;
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
 * Function stake
 * Daily Interest Rate : 2
 * Address Map : addressMap
 * ERC20 Transfer : 0x7EFD8beC4A6E928747Fc9bB4c1DEF138F1C4Cfa4, _stakeAmt
 * The function takes in 1 variable, zero or a positive integer _stakeAmt. It can be called by functions both inside and outside of this contract. It does the following :
 * checks that _stakeAmt is strictly greater than 0
 * creates an internal variable thisRecord with initial value addressMap with element the address that called this function
 * if (thisRecord with element stakeAmt) is equals to 0 then (updates addressMap (Element the address that called this function) as Struct comprising current time, _stakeAmt, current time, 0) otherwise (updates addressMap (Element the address that called this function) as Struct comprising current time, ((thisRecord with element stakeAmt) + (_stakeAmt)), current time, ((thisRecord with element accumulatedInterestToUpdateTime) + (((thisRecord with element stakeAmt) * ((current time) - (thisRecord with element lastUpdateTime)) * (20000)) / (86400000000))))
 * calls ERC20's transferFrom function  with variable sender as the address that called this function, variable recipient as the address of this contract, variable amount as _stakeAmt
 * emits event Staked with inputs the address that called this function
*/
	function stake(uint256 _stakeAmt) public {
		require((_stakeAmt > 0), "Staked amount needs to be greater than 0");
		record memory thisRecord = addressMap[msg.sender];
		if ((thisRecord.stakeAmt == 0)){
			addressMap[msg.sender]  = record (block.timestamp, _stakeAmt, block.timestamp, 0);
		}else{
			addressMap[msg.sender]  = record (block.timestamp, (thisRecord.stakeAmt + _stakeAmt), block.timestamp, (thisRecord.accumulatedInterestToUpdateTime + ((thisRecord.stakeAmt * (block.timestamp - thisRecord.lastUpdateTime) * 20000) / 86400000000)));
		}
		ERC20(0x7EFD8beC4A6E928747Fc9bB4c1DEF138F1C4Cfa4).transferFrom(msg.sender, address(this), _stakeAmt);
		emit Staked(msg.sender);
	}

/**
 * Function unstake
 * The function takes in 1 variable, zero or a positive integer _unstakeAmt. It can be called by functions both inside and outside of this contract. It does the following :
 * creates an internal variable thisRecord with initial value addressMap with element the address that called this function
 * checks that _unstakeAmt is less than or equals to (thisRecord with element stakeAmt)
 * creates an internal variable newAccum with initial value (thisRecord with element accumulatedInterestToUpdateTime) + (((thisRecord with element stakeAmt) * ((current time) - (thisRecord with element lastUpdateTime)) * (20000)) / (86400000000))
 * creates an internal variable interestToRemove with initial value ((newAccum) * (_unstakeAmt)) / (thisRecord with element stakeAmt)
 * transfers interestToRemove of the native currency to the address that called this function
 * calls ERC20's transfer function  with variable recipient as the address that called this function, variable amount as _unstakeAmt
 * updates addressMap (Element the address that called this function) as Struct comprising (thisRecord with element stakeTime), ((thisRecord with element stakeAmt) - (_unstakeAmt)), (thisRecord with element lastUpdateTime), ((newAccum) - (interestToRemove))
 * emits event Unstaked with inputs the address that called this function
*/
	function unstake(uint256 _unstakeAmt) public {
		record memory thisRecord = addressMap[msg.sender];
		require((_unstakeAmt <= thisRecord.stakeAmt), "Withdrawing more than staked amount");
		uint256 newAccum = (thisRecord.accumulatedInterestToUpdateTime + ((thisRecord.stakeAmt * (block.timestamp - thisRecord.lastUpdateTime) * 20000) / 86400000000));
		uint256 interestToRemove = ((newAccum * _unstakeAmt) / thisRecord.stakeAmt);
		payable(msg.sender).transfer(interestToRemove);
		ERC20(0x7EFD8beC4A6E928747Fc9bB4c1DEF138F1C4Cfa4).transfer(msg.sender, _unstakeAmt);
		addressMap[msg.sender]  = record (thisRecord.stakeTime, (thisRecord.stakeAmt - _unstakeAmt), thisRecord.lastUpdateTime, (newAccum - interestToRemove));
		emit Unstaked(msg.sender);
	}

/**
 * Function interestEarnedUpToNowBeforeTaxes
 * The function takes in 1 variable, an address _address. It can be called by functions both inside and outside of this contract. It does the following :
 * creates an internal variable thisRecord with initial value addressMap with element _address
 * returns (thisRecord with element accumulatedInterestToUpdateTime) + (((thisRecord with element stakeAmt) * ((current time) - (thisRecord with element lastUpdateTime)) * (20000)) / (86400000000)) as output
*/
	function interestEarnedUpToNowBeforeTaxes(address _address) public returns (uint256) {
		record memory thisRecord = addressMap[_address];
		return (thisRecord.accumulatedInterestToUpdateTime + ((thisRecord.stakeAmt * (block.timestamp - thisRecord.lastUpdateTime) * 20000) / 86400000000));
	}

/**
 * Function withdrawToken
 * The function takes in 1 variable, zero or a positive integer _amt. It can be called by functions both inside and outside of this contract. It does the following :
 * checks that the function is called by the owner of the contract
 * transfers _amt of the native currency to the address that called this function
*/
	function withdrawToken(uint256 _amt) public onlyOwner {
		payable(msg.sender).transfer(_amt);
	}

	function sendMeNativeCurrency() external payable {
	}
}