/**
 *Submitted for verification at polygonscan.com on 2022-08-17
*/

//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;

contract Verify {
    string private greeting;
    constructor(){}

    function hello(bool sayHello) public pure returns (string memory){
        if(sayHello){
            return "hello";
        }
        return "";
    }
}