// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.2 <0.9.0;

contract Verify {
    string private greeting;

    constructor() {

    }

    function hello(bool sayHello) public pure returns(string memory) {
        if (sayHello) {
            return "Hello";
        }
        return "";
    }
}