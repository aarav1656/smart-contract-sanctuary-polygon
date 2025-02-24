/**
 *Submitted for verification at polygonscan.com on 2022-11-29
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;


interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size; assembly {
            size := extcodesize(account)
        } return size > 0;
    }
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }
    function functionCall(address target,bytes memory data,string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }
    function functionCallWithValue(address target,bytes memory data,uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }
    function functionCallWithValue(address target,bytes memory data,uint256 value,string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }
    function functionStaticCall(address target,bytes memory data,string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }
    function functionDelegateCall(address target,bytes memory data,string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }
    function verifyCallResult(bool success,bytes memory returndata,string memory errorMessage) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}
library SafeERC20 {
    using Address for address;
    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }
    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }
    function safeIncreaseAllowance(IERC20 token,address spender,uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }
    function safeDecreaseAllowance(IERC20 token,address spender,uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }
    function _callOptionalReturn(IERC20 token, bytes memory data) private {   
        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;
        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        return c;
    }
}
//libraries
struct User {
    uint256 startDate;
    uint256 divs;
    uint256 refBonus;
    uint256 totalInits;
    uint256 totalWiths;
    uint256 totalAccrued;
    uint256 lastWith;
    uint256 timesCmpd;
    uint256 keyCounter;
    Depo [] depoList;
}
struct Depo {
    uint256 key;
    uint256 depoTime;
    uint256 amt;
    address reffy;
    bool initialWithdrawn;
}

struct TrackTransaction {
    address user_addr;
    uint256 key;
    uint256 depoTime;
    uint256 amt;
    bool initialWithdrawn;

}
struct Main {
    uint256 ovrTotalDeps;
    uint256 ovrTotalWiths;
    uint256 users;
    uint256 compounds;
}
struct DivPercs{
    uint256 daysInSeconds; // updated to be in seconds
    uint256 divsPercentage;
}
struct FeesPercs{
    uint256 daysInSeconds;
    uint256 feePercentage;
}

struct lending {
    address user_addr;
    uint256 amount;
    uint256 earned_amount;
}

struct lendingUsers {
    uint256 user_id;
    address user_addr;
}

struct lendingWithdrawn {
    address user_addr;
    uint256 amount;
    
}

contract IgniteBusd {
    using SafeMath for uint256;
  	uint256 constant hardDays = 86400;
    uint256 constant percentdiv = 1000;
    uint256 refPercentage = 60;
    uint256 devPercentage = 70;
    uint256 lenderPercentage = 30;
    uint256 min_invest = 300000000000000000000;
    uint256 public Collection_lending = 0;
    uint256 public lendingUsersCount = 0;
    bool ToTheMoon = false;
    mapping (address => mapping(uint256 => Depo)) public DeposMap;
    mapping (address => mapping(uint256 => TrackTransaction)) public queryDeposit;
    mapping(uint256 => lendingUsers) public queryLendingUsers;
    mapping(address => lendingWithdrawn) public queryWithdrawn;
    mapping (address => User) public UsersKey;
    mapping (uint256 => DivPercs) public PercsKey;
    mapping (uint256 => FeesPercs) public FeesKey;
    mapping (uint256 => Main) public MainKey;
    mapping(address => lending) public queryLending;
    using SafeERC20 for IERC20;
    IERC20 public BUSD;
    address public owner;

    constructor() {
            owner = msg.sender;
            PercsKey[10] = DivPercs(864000, 20);
            PercsKey[20] = DivPercs(1728000, 30);
            PercsKey[30] = DivPercs(2592000, 40);
            PercsKey[40] = DivPercs(3456000, 50);
            PercsKey[50] = DivPercs(4320000, 60);
            FeesKey[10] = FeesPercs(864000, 80);
            FeesKey[20] = FeesPercs(1728000, 60);
            FeesKey[30] = FeesPercs(2592000, 30);
            FeesKey[40] = FeesPercs(3456000, 20);
            FeesKey[50] = FeesPercs(4320000, 10);

            BUSD = IERC20(0x6c11E96fE8E0e78995a5E901eFAf24BE72051EDE); 


    }
    function stakeStablecoins(uint256 amtx, address ref) public {
        require(ToTheMoon, "App did not launch yet.");
        require(ref != msg.sender, "You cannot refer yourself!");
        BUSD.safeTransferFrom(msg.sender, address(this), amtx);
        User storage user = UsersKey[msg.sender];
        User storage user2 = UsersKey[ref];
        Main storage main = MainKey[1];
        if (user.lastWith == 0){
            user.lastWith = block.timestamp;
            user.startDate = block.timestamp;
        }
        uint256 userStakePercentAdjustment = 1000 - devPercentage;
        uint256 adjustedAmt = amtx.mul(userStakePercentAdjustment).div(percentdiv); 
        uint256 stakeFee = amtx.mul(devPercentage).div(percentdiv); 
        
        user.totalInits += adjustedAmt; 
        uint256 refAmtx = adjustedAmt.mul(refPercentage).div(percentdiv);
        if (ref == 0x000000000000000000000000000000000000dEaD){
            user2.refBonus += 0;
            user.refBonus += 0;
        } else {
            user2.refBonus += refAmtx;
            user.refBonus += refAmtx;
        }

       uint256 depoList = UsersKey[msg.sender].keyCounter;

       if(depoList == 0) {
           uint256 amtNow = SafeMath.sub(amtx,stakeFee);
           queryDeposit[msg.sender][depoList] = TrackTransaction(msg.sender,0,block.timestamp,amtNow,false);
       }
       else {
           uint256 amtNow = SafeMath.sub(amtx,stakeFee);
           queryDeposit[msg.sender][depoList] = TrackTransaction(msg.sender,depoList + 1,block.timestamp,amtNow,false);
       }
        
        user.depoList.push(Depo({
            key: user.depoList.length,
            depoTime: block.timestamp,
            amt: adjustedAmt,
            reffy: ref,
            initialWithdrawn: false
        }));



        user.keyCounter += 1;
        main.ovrTotalDeps += 1;
        main.users += 1;

       
        uint256 xlendingFee = SafeMath.div(amtx,percentdiv);
        uint256 lendingFee = SafeMath.mul(xlendingFee,lenderPercentage);
        Collection_lending = SafeMath.add(Collection_lending,lendingFee);
       
        BUSD.safeTransfer(owner, stakeFee);
    }

    function lendBusd(uint256 amtx) public {
        require(min_invest==amtx, "You cannot deposit less than 300 BUSD");
        require(ToTheMoon,"Not Launched Yet");
        require(queryLending[msg.sender].user_addr == address(0));
        uint256 devFee = SafeMath.div(amtx,100);
        uint256 devFeeNow = SafeMath.mul(devFee,3);
        uint256 _previous = queryLending[owner].earned_amount;
        uint256 totalDiv = SafeMath.add(_previous,devFeeNow);
        queryLending[owner].earned_amount = totalDiv;
       
        BUSD.safeTransferFrom(msg.sender,address(this),amtx);

        uint256 previousLending = queryLending[msg.sender].amount;
        uint256 totalNow = SafeMath.add(amtx,previousLending);

        queryLending[msg.sender] = lending(msg.sender,totalNow,0);
        lendingUsersCount = lendingUsersCount + 1;
        queryLendingUsers[lendingUsersCount] = lendingUsers(lendingUsersCount,msg.sender);


    }

    function lendingReward() public {
        uint256 xAmount = queryLending[msg.sender].earned_amount;
        BUSD.safeTransfer(msg.sender,xAmount);
        uint256 previous = queryWithdrawn[msg.sender].amount;
        uint256 totalWithdrawn = SafeMath.add(xAmount,previous);
        queryWithdrawn[msg.sender] = lendingWithdrawn(msg.sender,totalWithdrawn);
        queryLending[msg.sender].earned_amount = 0;
    }

    function lendDistribute() public {
        require(msg.sender == owner);
        uint256 i = 1;
        uint256 toPayLend = SafeMath.div(Collection_lending,lendingUsersCount);

        for(i;i<=lendingUsersCount;i++) {
            address _user = queryLendingUsers[i].user_addr;
            uint256 _previous = queryLending[_user].earned_amount;
            uint256 PayOut = SafeMath.add(_previous,toPayLend);
            queryLending[_user].earned_amount = PayOut;

        }
        Collection_lending = 0;
    }


    function userInfo() view external returns (Depo [] memory depoList){
        User storage user = UsersKey[msg.sender];
        return(
            user.depoList
        );
    }

    function withdrawDivs() public returns (uint256 withdrawAmount){
        User storage user = UsersKey[msg.sender];
        Main storage main = MainKey[1];
        uint256 x = calcdiv(msg.sender);
      
      	for (uint i = 0; i < user.depoList.length; i++){
          if (user.depoList[i].initialWithdrawn == false) {
            user.depoList[i].depoTime = block.timestamp;
          }
        }

        main.ovrTotalWiths += x;
        user.lastWith = block.timestamp;
        BUSD.safeTransfer(msg.sender, x);
        return x;
    }

    function withdrawInitial(uint256 keyy) public {
      	  
      	User storage user = UsersKey[msg.sender];
				
      	require(user.depoList[keyy].initialWithdrawn == false, "This has already been withdrawn.");
      
        uint256 initialAmt = user.depoList[keyy].amt; 
        uint256 currDays1 = user.depoList[keyy].depoTime;
        uint256 currTime = block.timestamp;
        uint256 currDays = currTime - currDays1;
        uint256 transferAmt;
      	
        if (currDays < FeesKey[10].daysInSeconds){ // LESS THAN 10 DAYS STAKED
            uint256 minusAmt = initialAmt.mul(FeesKey[10].feePercentage).div(percentdiv); //10% fee
           	
          	uint256 dailyReturn = initialAmt.mul(PercsKey[10].divsPercentage).div(percentdiv);
            uint256 currentReturn = dailyReturn.mul(currDays).div(hardDays);
          	
          	transferAmt = initialAmt + currentReturn - minusAmt;
          
            user.depoList[keyy].amt = 0;
            user.depoList[keyy].initialWithdrawn = true;
            user.depoList[keyy].depoTime = block.timestamp;
            queryDeposit[msg.sender][keyy].initialWithdrawn = true;

            BUSD.safeTransfer(msg.sender, transferAmt);


        } else if (currDays >= FeesKey[10].daysInSeconds && currDays < FeesKey[20].daysInSeconds){ // BETWEEN 20 and 30 DAYS
            uint256 minusAmt = initialAmt.mul(FeesKey[20].feePercentage).div(percentdiv); //8% fee
						
          	uint256 dailyReturn = initialAmt.mul(PercsKey[10].divsPercentage).div(percentdiv);
            uint256 currentReturn = dailyReturn.mul(currDays).div(hardDays);
						transferAmt = initialAmt + currentReturn - minusAmt;

            user.depoList[keyy].amt = 0;
            user.depoList[keyy].initialWithdrawn = true;
            user.depoList[keyy].depoTime = block.timestamp;
            queryDeposit[msg.sender][keyy].initialWithdrawn = true;

            BUSD.safeTransfer(msg.sender, transferAmt);


        } else if (currDays >= FeesKey[20].daysInSeconds && currDays < FeesKey[30].daysInSeconds){ // BETWEEN 30 and 40 DAYS
            uint256 minusAmt = initialAmt.mul(FeesKey[30].feePercentage).div(percentdiv); //5% fee
            
          	uint256 dailyReturn = initialAmt.mul(PercsKey[20].divsPercentage).div(percentdiv);
            uint256 currentReturn = dailyReturn.mul(currDays).div(hardDays);
						transferAmt = initialAmt + currentReturn - minusAmt;

            user.depoList[keyy].amt = 0;
            user.depoList[keyy].initialWithdrawn = true;
            user.depoList[keyy].depoTime = block.timestamp;
            queryDeposit[msg.sender][keyy].initialWithdrawn = true;

            BUSD.safeTransfer(msg.sender, transferAmt);

        } else if (currDays >= FeesKey[30].daysInSeconds && currDays < FeesKey[40].daysInSeconds){ // BETWEEN 30 and 40 DAYS
            uint256 minusAmt = initialAmt.mul(FeesKey[40].feePercentage).div(percentdiv); //5% fee
            
          	uint256 dailyReturn = initialAmt.mul(PercsKey[30].divsPercentage).div(percentdiv);
            uint256 currentReturn = dailyReturn.mul(currDays).div(hardDays);
						transferAmt = initialAmt + currentReturn - minusAmt;

            user.depoList[keyy].amt = 0;
            user.depoList[keyy].initialWithdrawn = true;
            user.depoList[keyy].depoTime = block.timestamp;
            queryDeposit[msg.sender][keyy].initialWithdrawn = true;

            BUSD.safeTransfer(msg.sender, transferAmt);

          
        } else if (currDays >= FeesKey[40].daysInSeconds && currDays < FeesKey[50].daysInSeconds){ // BETWEEN 30 and 40 DAYS
            uint256 minusAmt = initialAmt.mul(FeesKey[40].feePercentage).div(percentdiv); //2% fee
            
          	uint256 dailyReturn = initialAmt.mul(PercsKey[40].divsPercentage).div(percentdiv);
            uint256 currentReturn = dailyReturn.mul(currDays).div(hardDays);
						transferAmt = initialAmt + currentReturn - minusAmt;

            user.depoList[keyy].amt = 0;
            user.depoList[keyy].initialWithdrawn = true;
            user.depoList[keyy].depoTime = block.timestamp;
            queryDeposit[msg.sender][keyy].initialWithdrawn = true;

            BUSD.safeTransfer(msg.sender, transferAmt);


        } else if (currDays >= FeesKey[50].daysInSeconds){ // 40+ DAYS
            uint256 minusAmt = initialAmt.mul(FeesKey[40].feePercentage).div(percentdiv); //2% fee
            
          	uint256 dailyReturn = initialAmt.mul(PercsKey[50].divsPercentage).div(percentdiv);
            uint256 currentReturn = dailyReturn.mul(currDays).div(hardDays);
						transferAmt = initialAmt + currentReturn - minusAmt;

            user.depoList[keyy].amt = 0;
            user.depoList[keyy].initialWithdrawn = true;
            user.depoList[keyy].depoTime = block.timestamp;

            queryDeposit[msg.sender][keyy].initialWithdrawn = true;
            
            BUSD.safeTransfer(msg.sender, transferAmt);


        } else {
            revert("Could not calculate the # of days youv've been staked.");
        }
        
    }
    function withdrawRefBonus() public {
        User storage user = UsersKey[msg.sender];
        uint256 amtz = user.refBonus;
        user.refBonus = 0;

        BUSD.safeTransfer(msg.sender, amtz);
    }

    function stakeRefBonus() public { 
        User storage user = UsersKey[msg.sender];
        Main storage main = MainKey[1];
        require(user.refBonus > 10);
      	uint256 refferalAmount = user.refBonus;
        user.refBonus = 0;
        address ref = 0x000000000000000000000000000000000000dEaD; //DEAD ADDRESS
				
        user.depoList.push(Depo({
            key: user.keyCounter,
            depoTime: block.timestamp,
            amt: refferalAmount,
            reffy: ref, 
            initialWithdrawn: false
        }));

        user.keyCounter += 1;
        main.ovrTotalDeps += 1;
    }

    function calcdiv(address dy) public view returns (uint256 totalWithdrawable){
        User storage user = UsersKey[dy];	

        uint256 with;
        
        for (uint256 i = 0; i < user.depoList.length; i++){	
            uint256 elapsedTime = block.timestamp.sub(user.depoList[i].depoTime);

            uint256 amount = user.depoList[i].amt;
            if (user.depoList[i].initialWithdrawn == false){
                if (elapsedTime <= PercsKey[20].daysInSeconds){ 
                    uint256 dailyReturn = amount.mul(PercsKey[10].divsPercentage).div(percentdiv);
                    uint256 currentReturn = dailyReturn.mul(elapsedTime).div(PercsKey[10].daysInSeconds / 10);
                    with += currentReturn;
                }
                if (elapsedTime > PercsKey[20].daysInSeconds && elapsedTime <= PercsKey[30].daysInSeconds){
                    uint256 dailyReturn = amount.mul(PercsKey[20].divsPercentage).div(percentdiv);
                    uint256 currentReturn = dailyReturn.mul(elapsedTime).div(PercsKey[10].daysInSeconds / 10);
                    with += currentReturn;
                }
                if (elapsedTime > PercsKey[30].daysInSeconds && elapsedTime <= PercsKey[40].daysInSeconds){
                    uint256 dailyReturn = amount.mul(PercsKey[30].divsPercentage).div(percentdiv);
                    uint256 currentReturn = dailyReturn.mul(elapsedTime).div(PercsKey[10].daysInSeconds / 10);
                    with += currentReturn;
                }
                if (elapsedTime > PercsKey[40].daysInSeconds && elapsedTime <= PercsKey[50].daysInSeconds){
                    uint256 dailyReturn = amount.mul(PercsKey[40].divsPercentage).div(percentdiv);
                    uint256 currentReturn = dailyReturn.mul(elapsedTime).div(PercsKey[10].daysInSeconds / 10);
                    with += currentReturn;
                }
                if (elapsedTime > PercsKey[50].daysInSeconds){
                    uint256 dailyReturn = amount.mul(PercsKey[50].divsPercentage).div(percentdiv);
                    uint256 currentReturn = dailyReturn.mul(elapsedTime).div(PercsKey[10].daysInSeconds / 10);
                    with += currentReturn;
                }
                
            } 
        }
        return with;
    }
  		function compound() public {
        User storage user = UsersKey[msg.sender];
        Main storage main = MainKey[1];

        uint256 y = calcdiv(msg.sender);

        for (uint i = 0; i < user.depoList.length; i++){
          if (user.depoList[i].initialWithdrawn == false) {
            user.depoList[i].depoTime = block.timestamp;
          }
        }

        user.depoList.push(Depo({
              key: user.keyCounter,
              depoTime: block.timestamp,
              amt: y,
              reffy: 0x000000000000000000000000000000000000dEaD, 
              initialWithdrawn: false
          }));

        user.keyCounter += 1;
        main.ovrTotalDeps += 1;
        main.compounds += 1;
        user.lastWith = block.timestamp;  
      }

      function Launch() public {
          require(msg.sender == owner);
          ToTheMoon = true;
            queryLending[msg.sender] = lending(msg.sender,0,0);
          lendingUsersCount = lendingUsersCount + 1;

        queryLendingUsers[lendingUsersCount] = lendingUsers(lendingUsersCount,msg.sender);
      }

      function TvlBalance() public view returns(uint256) {
          return BUSD.balanceOf(address(this));
      }
}