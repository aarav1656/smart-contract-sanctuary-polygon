/**
 *Submitted for verification at polygonscan.com on 2022-09-23
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract V1 {
    uint public number;

    function initialValue(uint _num) external {
        number=_num;
    }

    function increase() external {
        number += 1;
    }
}