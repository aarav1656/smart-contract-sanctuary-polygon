pragma solidity ^0.5.0;

import "./SafeMath.sol";

contract Ownable {
  address public owner;
  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  constructor() public {
   owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
  _;
  }

  function transferOwnership(address newOwner) public onlyOwner {
  require(newOwner != address(0));
  emit OwnershipTransferred(owner, newOwner);
  owner = newOwner;
  }
}

contract ERC20 {
  function transfer(address recipient, uint256 amount) external returns (bool ok);
  function transferFrom(address from, address to, uint256 value) external returns (bool ok);
  function getUplines() external view returns (address[] memory);
}

contract BlockChainMLM is Ownable{

  using SafeMath for uint256;

  uint[] public rates = [10,9,8,7,6,5,4,3,2,1];
  address[] public uplines = [msg.sender];
  uint256 public balance = 0;
  uint public level = 0;

  function getUplines() public view returns(address[] memory) {
    return uplines;
  }

  function reg(ERC20 token, ERC20 uplineContract, uint256 amount) public {
   
    balance = balance.add(amount);
    token.transferFrom(msg.sender, address(this), amount);
    
    address[] memory lastUplines = uplineContract.getUplines();
    level = lastUplines.length;
    uint counter = 0;
    for (uint i = level; i > 0; i--) {
      counter++;
      if(rates.length >= counter){
        token.transfer(lastUplines[i-1], amount.div(10));
      }
    }
    lastUplines[level] = msg.sender;
    uplines = lastUplines;
  }
}