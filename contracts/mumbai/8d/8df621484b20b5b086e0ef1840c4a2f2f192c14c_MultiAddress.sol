/**
 *Submitted for verification at polygonscan.com on 2023-03-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MultiAddress {
    address public mainAddress;
    mapping(uint256 => address) public receivingAddresses;
    uint256 public totalReceivingAddresses;

    constructor() {
        mainAddress = msg.sender;
        totalReceivingAddresses = 0;
    }

    function addReceivingAddress() public {
        require(msg.sender == mainAddress, "Only the main address can add receiving addresses");
        address newAddress = address(new ReceivingAddress(msg.sender));
        receivingAddresses[totalReceivingAddresses] = newAddress;
        totalReceivingAddresses++;
    }

    receive() external payable {}
}

contract ReceivingAddress {
    address public owner;

    constructor(address _owner) {
        owner = _owner;
    }

    receive() external payable {}
    
    function withdraw() public {
        require(msg.sender == owner, "Only the owner can withdraw from this address");
        payable(msg.sender).transfer(address(this).balance);
    }
}