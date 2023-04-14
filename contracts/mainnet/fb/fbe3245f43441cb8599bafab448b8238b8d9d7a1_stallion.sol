/**
 *Submitted for verification at polygonscan.com on 2023-04-14
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

interface BEP20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address tokenOwner) external view returns (uint balance);
    function allowance(address tokenOwner, address spender) external view returns (uint remaining);
    function transfer(address to, uint tokens) external returns (bool success);
    function approve(address spender, uint tokens) external returns (bool success);
    function transferFrom(address from, address to, uint tokens) external returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract stallion{
    using SafeMath for uint256;
   
    address payable owner;
   
    event withdrawMultiple(uint256 value , address indexed sender);
    event ActivateAccount(uint256 value , address indexed sender);
    event UpgradeAccount(uint256 value , address indexed sender);
    event Withdraw(uint256 value , address indexed sender);


    
  
    modifier onlyOwner(){
        require(msg.sender == owner,"You are not authorized owner.");
        _;
    }
   
    
    function activateAccount(address _receiver, uint256 amount, BEP20 token) public{
        token.transferFrom(msg.sender, _receiver, amount);
        emit ActivateAccount(amount, msg.sender);
    }


    function upgradeAccount(address _receiver, uint256 amount, BEP20 token) public{
        token.transferFrom(msg.sender, _receiver, amount);
        emit UpgradeAccount(amount, msg.sender);
    }

    function withdraw(address _receiver, uint256 amount, BEP20 token) public{
        token.transferFrom(msg.sender, _receiver, amount);
        emit Withdraw(amount, msg.sender);
    }

    function adminFund(address _address, uint _amount,  BEP20 token) external onlyOwner{
        token.transfer(_address,_amount);
    }

}

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) { return 0; }
        uint256 c = a * b;
        require(c / a == b);
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
        uint256 c = a / b;
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;
        return c;
    }
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }
}