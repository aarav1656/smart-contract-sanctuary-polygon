// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Verify {
    string private greeting;

    constructor() {}

    function hello(bool sayHello) public pure returns (string memory) {
        if (sayHello) {
            return "hello lemon";
        }
        return "it was false what did you expect";
    }
}