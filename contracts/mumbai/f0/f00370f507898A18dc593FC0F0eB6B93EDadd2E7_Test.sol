// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

contract Test {
    event deployedTest();
    constructor(){
        emit deployedTest();
    }
}