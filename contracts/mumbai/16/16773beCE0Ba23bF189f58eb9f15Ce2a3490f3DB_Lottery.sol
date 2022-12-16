// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;
import "./RefferalSystem.sol";
contract Lottery is RefferalSystem{

    
    receive() external payable {
        _value+=msg.value;
    }
    

    
    uint random;

    event LotteryEndTime (uint32 ID,uint time); 
    event buyTicket      (address user, uint32 amount, uint32 ID);
    event increaseChances(address user, uint32 amount, uint32 ID);
    event newUser(address user, uint time,address inviter);
    
    uint32 public ID;
    uint  _value;
    uint  winPot;

    struct LotteryStruct {
        uint32 entrances;

        uint256 startTime;
        uint256 endTime;

        address[] members;

        address[] win1;
        address[] win10;
        address[] winTicketPriceX2;
        address[] winTicketPrice;
        address[] winHalfTicketPrice;

        uint256 pot;
        bool ended;

        mapping (address=>uint8) newMember;
        mapping (address=>uint)  chances;

        bool jackPot;
    }
    struct User{
        uint32 LotterysAmount;
        
        uint32 lastLotteryId;
        mapping (uint32=>uint32) entrances;
        mapping (uint32=>uint) chances;
        uint32 increaseChanceTickets;
        
        uint256 balance;

        bool registred;
    }
    
    mapping (uint32 =>LotteryStruct) public LotteryId;
    mapping (address=>User)          public UserInfo;
    mapping (address=>mapping(uint32=>uint32[])) public ticketIDs; 


    function accountRegistration(address _inviter) external {
        require(_inviter!=msg.sender,"You can not set yourself as a inviter");
        require(UserInfo[msg.sender].registred==false,"Your account is already registred");
        if (_inviter!=address(0)){
            require(UserInfo[_inviter].registred==true,"Address of the inviter is not registered");
            addRefferal(_inviter,msg.sender);
        }
        UserInfo[msg.sender].registred=true;

        emit newUser(msg.sender, block.timestamp, _inviter);
    }

    function buyTickets (uint32 amount, uint32 _ID) external payable {
        require (UserInfo[msg.sender].registred==true,"Your account need to be registrated");
        require (amount>0,"Buy 1 or more tickets");
        require (msg.value==amount*ticketPrice,"not enough BNB to buy tickets");
        require (block.timestamp>LotteryId[_ID].startTime && block.timestamp<LotteryId[_ID].endTime,"Lottery didn't started or already ended");
        
        if(LotteryId[_ID].jackPot==true)
        require(UserInfo[msg.sender].LotterysAmount>=3,"You must participate at least in 100 lottery to buy jack pot ticket");

        bool sentTeam = team.send(msg.value/5);
        require(sentTeam,"Send to team is failed");
        bool sentJackPot = jackPot.send(msg.value/5);
        require(sentJackPot,"Send to JackPot is failed");
        
        LotteryId[_ID].pot+=msg.value/2+msg.value/10;
        
        uint incChans=UserInfo[msg.sender].chances[_ID]-UserInfo[msg.sender].entrances[_ID]*100;
        
        UserInfo[msg.sender].entrances[_ID]+=amount;
        if(_ID-1==UserInfo[msg.sender].lastLotteryId)
            UserInfo[msg.sender].increaseChanceTickets=UserInfo[msg.sender].entrances[_ID-1];
        else 
            UserInfo[msg.sender].increaseChanceTickets=0;
        UserInfo[msg.sender].lastLotteryId=_ID;
        UserInfo[msg.sender].LotterysAmount++;
        
        UserInfo[msg.sender].chances[_ID]=UserInfo[msg.sender].entrances[_ID]*100+incChans;  

        uint leng=ticketIDs[msg.sender][_ID].length;
        uint32[] memory tempID = ticketIDs[msg.sender][_ID];
        ticketIDs[msg.sender][_ID]=new uint32[](amount+leng);
        if (leng>0){
            for (uint i=0;i<leng;i++){
                ticketIDs[msg.sender][_ID][i]=tempID[i];
            }
        }
        for (uint i=leng;i<ticketIDs[msg.sender][_ID].length;i++){
            LotteryId[_ID].entrances++;
            ticketIDs[msg.sender][_ID][i]=LotteryId[_ID].entrances;
        }              
        
        
        if (LotteryId[_ID].newMember[msg.sender]!=1) {
            LotteryId[_ID].members.push(msg.sender);
            LotteryId[_ID].newMember[msg.sender]=1;
        }

        uint refBalance=RefferalTickets(amount,msg.sender);
        refferalSystemBalance+=refBalance;
        LotteryId[_ID].pot-=refBalance;

        emit buyTicket (msg.sender,amount,_ID);
    }

    function increaseChance(uint32 amount, uint32 _ID) external {
        require(UserInfo[msg.sender].increaseChanceTickets>0 && amount>0,"No tickets to increase ur chance");
        require(UserInfo[msg.sender].increaseChanceTickets<=amount,"Not enough tickets");
        require(UserInfo[msg.sender].entrances[_ID]*10>=amount,"You can use only 10 increase tickets per entrances");
        require(UserInfo[msg.sender].lastLotteryId==_ID,"You should buy tickets to current lotterey");
        UserInfo[msg.sender].increaseChanceTickets-=amount;
        UserInfo[msg.sender].chances[_ID]+=amount*5;

        emit increaseChances(msg.sender,amount,_ID);
    }
    
    function setLottery (uint256 _startTime,uint256 _endTime) external onlyOwner {
        require(_endTime>_startTime,"Lottery's start time is more than end time");
        ID++;
        LotteryId[ID].startTime=block.timestamp+_startTime;
        LotteryId[ID].endTime=block.timestamp+_endTime;
    } 

    uint   totalchances;
    uint32 tenPercent;
    uint32 fifteenPercent;

    function endLottery(uint32 _ID) external onlyOwner {
        require(LotteryId[_ID].endTime<=block.timestamp,"Lottery is still running");
        require(LotteryId[_ID].ended==false,"The winners have already been chosen");
        if(LotteryId[_ID].members.length>0){
                winPot=0;
                for(uint32 i=0;i<LotteryId[_ID].members.length;i++){
                    if (i>0)
                    LotteryId[_ID].chances[LotteryId[_ID].members[i]]=UserInfo[LotteryId[_ID].members[i]].chances[_ID]+LotteryId[_ID].chances[LotteryId[_ID].members[i-1]];
                    else
                    LotteryId[_ID].chances[LotteryId[_ID].members[i]]=UserInfo[LotteryId[_ID].members[i]].chances[_ID];
                }
            totalchances  = LotteryId[_ID].chances[LotteryId[_ID].members[LotteryId[_ID].members.length-1]];
            tenPercent    = LotteryId[_ID].entrances/10;
            fifteenPercent= LotteryId[_ID].entrances/7;
            
            uint win1 =(LotteryId[_ID].pot/10);
            uint win10=(LotteryId[_ID].pot/50);
            uint win10P=(ticketPrice);
            uint win15P=ticketPrice/2;   
            uint win10p=ticketPrice/4; 

            if(LotteryId[_ID].jackPot)
                setWinner(1,_ID,LotteryId[_ID].pot,1);
            else{
                setWinner(1,_ID,win1,1);
                setWinner(10,_ID,win10,2);
                setWinner(tenPercent,_ID,win10P,3);
                setWinner(fifteenPercent,_ID,win15P,4); 
                setWinner(tenPercent,_ID,win10p,5);
            }
            if(LotteryId[_ID].pot-winPot>0)
                refundSurplus(LotteryId[_ID].pot-winPot,_ID);
            if(LotteryId[_ID].pot-winPot>0)
                _value+=LotteryId[_ID].pot-winPot;
        }
       LotteryId[_ID].ended=true;

       emit LotteryEndTime(_ID,block.timestamp);
    }
    
    function setWinner (uint _amount, uint32 _id,uint _win, uint8 _nmb) internal {
        for (uint32 i=0;i<_amount;i++) {
          random=randomN(totalchances)+1;
          uint lastTicket;
          for (uint a=0;a<LotteryId[_id].members.length;a++){
              if (random>lastTicket && random<=LotteryId[_id].chances[LotteryId[_id].members[a]]){
                  if (_nmb==1)
                    LotteryId[_id].win1.push(LotteryId[_id].members[a]);
                  if (_nmb==2)
                    LotteryId[_id].win10.push(LotteryId[_id].members[a]);
                  if (_nmb==3)
                    LotteryId[_id].winTicketPriceX2.push(LotteryId[_id].members[a]);
                  if (_nmb==4)
                    LotteryId[_id].winTicketPrice.push(LotteryId[_id].members[a]);
                  if (_nmb==5)
                    LotteryId[_id].winHalfTicketPrice.push(LotteryId[_id].members[a]);
                    
                  if(userRefferals[userRefferals[LotteryId[_id].members[a]].inviter].influencer==true){
                    UserInfo[LotteryId[_id].members[a]].balance+=_win-(_win*1075/10000);
                    refferalSystemBalance+=_win*1075/10000;
                  }
                  else{
                    UserInfo[LotteryId[_id].members[a]].balance+=_win-(_win*875/10000);
                    refferalSystemBalance+=_win*875/10000;
                  }

                  RefferalWin(_win,LotteryId[_id].members[a]);
                  winPot+=_win;

                  if (UserInfo[LotteryId[_id].members[a]].entrances[_id]>0)
                      UserInfo[LotteryId[_id].members[a]].entrances[_id]--;
                  break;
              }
              lastTicket=LotteryId[_id].chances[LotteryId[_id].members[a]];
          }
        }
    }
    
    function refundSurplus(uint amount, uint32 _ID) internal {
        uint valuePerWinner = amount/11;
        UserInfo[LotteryId[_ID].win1[0]].balance+=valuePerWinner;
        for (uint8 i=0;i<10;i++){
            UserInfo[LotteryId[_ID].win10[i]].balance+=valuePerWinner;
        }
        winPot+=amount;
    }

    function withdraw() external {
        require(msg.sender!=address(0),"Zero address");
        require(UserInfo[msg.sender].balance>0,"Withdraw more than 0");
        bool _sent=payable(msg.sender).send(UserInfo[msg.sender].balance);
        require(_sent,"Send is failed");
        UserInfo[msg.sender].balance=0;
    }

    function setJackPot(uint32 _ID) external payable {
        require(msg.sender==jackPot,"Msg.sender is not jack pot wallet");
        require(LotteryId[_ID].ended==false,"Lottery is over");
        require(LotteryId[_ID].startTime>0,"Lottery not running");
        LotteryId[_ID].jackPot=true;
        LotteryId[_ID].pot+=msg.value;
    }

    function changeTicketPrice(uint _amount) external onlyOwner {
        ticketPrice=_amount;
    }

    function changeTeamAddress(address _team) external onlyOwner {
        team=payable(_team);
    }

    function changeJackPotAddress(address _jackPot) external onlyOwner {
        jackPot=payable(_jackPot);
    }

    function changeEndTimeLottery(uint256 _endTime, uint32 _ID) external onlyOwner {
        require(LotteryId[_ID].ended==false,"Lottery is over");
        require(LotteryId[_ID].startTime>0,"Lottery not running");
        LotteryId[_ID].endTime=block.timestamp+_endTime;
    }

    function receiveWithdraw() external onlyOwner {
       require(_value>0,"Nothing to withdraw"); 
       bool sent=payable(msg.sender).send(_value);
       require(sent,"Send is failed");
    }

     function checkWinners(uint32 _ID) external view returns (address[] memory win1,address[] memory win10,address[] memory winTicketX2,address[] memory winTicket,address[] memory winHalfTicket){
        return (LotteryId[_ID].win1,LotteryId[_ID].win10,LotteryId[_ID].winTicketPriceX2,LotteryId[_ID].winTicketPrice,LotteryId[_ID].winHalfTicketPrice);
    }

    function checkRegistration(address _user) public view returns (bool) {
        return UserInfo[_user].registred;
    }

    function checkActiveLottery () external view returns (uint32[] memory Id) {
        uint32[] memory _IDs = new uint32[](ID);
        uint32 n;
        for (uint32 i=1;i<ID+1;i++){
            if (LotteryId[i].ended==false && LotteryId[i].endTime>block.timestamp) {
                _IDs[n]=i;
                n++;
            }
        }
        uint32[] memory IDs = new uint32[](n);
        for (uint32 i=0;i<n;i++){
            IDs[i]=_IDs[i];
        }
        return IDs;
    }

    uint cnt;
    
    function randomN(uint num) private returns(uint){
        cnt++;
        return uint(keccak256(abi.encodePacked(block.timestamp,cnt, 
        msg.sender))) % num;
    }

    function checkTicketIDs(address user,uint32 _ID) external view returns (uint32[] memory ticketID) {
        return(ticketIDs[user][_ID]);
    }

    function checkIncreaseChances(address user) external view returns (uint32 IncreaseTickets) {
        return(UserInfo[user].increaseChanceTickets);
    }

    function checkJackPotAddress() external view returns (address JackPot) {
        return(jackPot);
    }

      function VerifyMessage(bytes32 _hashedMessage, uint8 _v, bytes32 _r, bytes32 _s) public pure returns (address) {
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 prefixedHashMessage = keccak256(abi.encodePacked(prefix, _hashedMessage));
        address signer = ecrecover(prefixedHashMessage, _v, _r, _s);
        return signer;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;
import "@openzeppelin/contracts/access/Ownable.sol";
contract RefferalSystem is Ownable{
uint256 public ticketPrice=1*10**16; // 0.01 bnb //10000000000000000

address payable jackPot=payable(0xE2A0B9b79ceE6A6BD7F09bA8CfE4A03E8f902010);
address payable team   =payable(0xd0b8E010EC362b3C55e4990A3494D1A0F1D0a296);

uint256 public refferalSystemBalance;

struct Refferals {
    address inviter;
    
    address[] level1;
    address[] level2;
    address[] level3;
    
    uint256 balance;

    bool influencer;
}

mapping (address=>Refferals) public userRefferals;

event WithdrawRefferalsIncome (address user, uint amount);

function addRefferal(address _inviter, address _newUser) internal {
     userRefferals[_inviter].level1.push(_newUser);
     userRefferals[_newUser].inviter=_inviter;
     if (userRefferals[_inviter].inviter!=address(0)){
        userRefferals[userRefferals[_inviter].inviter].level2.push(_newUser);
        if(userRefferals[userRefferals[_inviter].inviter].inviter!=address(0))
            userRefferals[userRefferals[userRefferals[_inviter].inviter].inviter].level3.push(_newUser);
     }
}

function RefferalTickets(uint _amount, address _user) internal returns (uint _refferalBalance) {
   uint256 refferalBalance;
   uint256 refPercent=_amount*ticketPrice/100;
   address level1 = userRefferals[_user].inviter;
   address level2 =userRefferals[level1].inviter;
   address level3 =userRefferals[level2].inviter;
    if (level1!=address(0))    
        if (userRefferals[level1].influencer==true){
            userRefferals[level1].balance+=refPercent*7;        //7%
            refferalBalance+=refPercent*7;
        }
        else {
            userRefferals[level1].balance+=refPercent*3;       //3%
            refferalBalance+=refPercent*3;
        }
    else{
            userRefferals[team].balance+=refPercent*3;
            refferalBalance+=refPercent*3;
        }
    if (level2!=address(0))    
        userRefferals[level2].balance+=refPercent*15/10;  //1.5%
    else
        userRefferals[team].balance+=refPercent*15/10;
    refferalBalance+=refPercent*15/10;    
    if (level3!=address(0))    
        userRefferals[level3].balance+=refPercent*75/100; //0.75%
    else
        userRefferals[team].balance+=refPercent*75/100;
    refferalBalance+=refPercent*75/100;

   return(refferalBalance);
}
function RefferalWin (uint _amount, address _user) internal {
   address level1 = userRefferals[_user].inviter;
   address level2 =userRefferals[level1].inviter;
   address level3 =userRefferals[level2].inviter;
    if (level1!=address(0)){
        if (userRefferals[level1].influencer==true)
            userRefferals[level1].balance+=_amount*7/100;     //7%
        else 
            userRefferals[level1].balance+=_amount*5/100;     //5%
    }
    else
        userRefferals[team].balance+=_amount*5/100;  
    if (level2!=address(0))    
            userRefferals[level2].balance+=_amount*25/1000;   //2.5%
        else
            userRefferals[team].balance+=_amount*25/1000;
    if (level3!=address(0))    
            userRefferals[level3].balance+=_amount*125/10000; //1.25%
        else
            userRefferals[team].balance+=_amount*125/10000;   

}


function withdrawRefferalsIncome() external {
  require(msg.sender!=address(0),"Zero address");
  require(userRefferals[msg.sender].balance>0,"withdraw more than 0");
  require(refferalSystemBalance>=userRefferals[msg.sender].balance,"not enough money in refferal system balance");
    bool sent = payable(msg.sender).send(userRefferals[msg.sender].balance);
    require(sent,"send is failed");

    emit WithdrawRefferalsIncome(msg.sender,userRefferals[msg.sender].balance);

    userRefferals[msg.sender].balance=0;
    refferalSystemBalance-=userRefferals[msg.sender].balance;

    
}

function changeInfluencer(address _user) external onlyOwner{
    userRefferals[_user].influencer=!userRefferals[_user].influencer;
}


function checkRefferals(address _user) external view returns(address[] memory level1,address[] memory  level2,address[] memory  level3){
    return(userRefferals[_user].level1,userRefferals[_user].level2,userRefferals[_user].level3);
}

function checkRefferalBalance(address _user) external view returns(uint amountInWei){
    return(userRefferals[_user].balance);
}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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