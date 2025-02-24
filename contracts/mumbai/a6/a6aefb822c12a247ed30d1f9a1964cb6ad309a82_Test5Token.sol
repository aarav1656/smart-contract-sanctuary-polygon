/**
 *Submitted for verification at polygonscan.com on 2022-12-22
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

contract Test5Token {

    uint public price = 1300000000000000000;
    address public owner;
    mapping (address => uint) public tokenBalances;
    string public name;
    string public symbol;
    string public decimals;
    event Bought(address indexed buyer, uint amount);

    constructor () {
        owner = msg.sender;
        tokenBalances[address(this)] = 10000;
        name = "Test5";
        symbol = "TEST5";
        decimals = "0";
    }

    function refill(uint amount) public {
        require(msg.sender == owner);
        tokenBalances[address(this)] += amount;
    }

    function buy(uint amount) public payable {
        require(msg.value >= amount * 1300000000000000000);
        require(tokenBalances[address(this)] >= amount);
        tokenBalances[address(this)] -= amount;
        tokenBalances[msg.sender] += amount;

        emit Bought(msg.sender, msg.value);
    }

    function withdrawAll() public {
        require(msg.sender == owner);
        address payable _to = payable(owner);
        address _thisContract = address(this);
        _to.transfer(_thisContract.balance);
    }
}