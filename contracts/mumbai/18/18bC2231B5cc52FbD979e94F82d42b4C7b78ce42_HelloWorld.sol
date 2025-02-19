/**
 *Submitted for verification at polygonscan.com on 2022-11-20
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity >= 0.8.9;

contract HelloWorld {
    event UpdatedMessages(string oldStr, string newString);

    string public message;

    constructor(string memory initMessage) {
        message = initMessage;
    }

    function update(string memory newMessage) public {
        string memory oldMsg = message;
        message = newMessage;
        emit UpdatedMessages(oldMsg, newMessage);
    }
}