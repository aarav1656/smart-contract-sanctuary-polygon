/**
 *Submitted for verification at polygonscan.com on 2022-08-08
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

contract Verify {

    constructor() {

    }

    function hello(bool sayHello) public pure returns(string memory){
        if (sayHello) {
            return "Hello";
        }
        return "";
    } 
}