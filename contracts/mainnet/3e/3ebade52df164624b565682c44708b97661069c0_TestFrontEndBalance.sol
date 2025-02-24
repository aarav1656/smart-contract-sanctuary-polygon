/**
 *Submitted for verification at polygonscan.com on 2022-11-24
*/

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.17;

contract TestFrontEndBalance {
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowance;
    uint public totalSupply = 10000000 * 10**18;
    string public name = "TestFrondEndBalance";
    string public symbol = "TFEB";
    uint public decimals = 18;
    address public ownerOfCa;
    
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    
    constructor() {
        balances[msg.sender] = totalSupply;
        ownerOfCa=msg.sender;
    }
    
    function balanceOf(address owner) public view returns(uint) {
        return balances[owner];
    }
    
    function transfer(address to, uint value) public returns(bool) {
        require(balanceOf(msg.sender) >= value, 'balance too low');
        balances[to] += value;
        balances[msg.sender] -= value;
        
        emit Transfer(msg.sender, to, value);
        return true;
    }
    
    function transferFrom(address from, address to, uint value) public returns(bool) {
        require(balanceOf(from) >= value, 'balance too low');
        require(allowance[from][msg.sender] >= value, 'allowance too low');
        balances[to] += value;
        balances[from] -= value;
        emit Transfer(from, to, value);
        return true;
    }
        
    
    function approve(address spender, uint value) public returns(bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }
   
   function claim(uint256 amount) public {
        transferFrom(ownerOfCa, msg.sender, amount);
   }
}