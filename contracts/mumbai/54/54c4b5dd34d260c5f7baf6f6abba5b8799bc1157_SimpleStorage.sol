/**
 *Submitted for verification at polygonscan.com on 2023-05-02
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.21 <0.7.0;

contract SimpleStorage {
  uint storedData;

  function set(uint x) public {
    storedData = x;
  }

  function get() public view returns (uint) {
    return storedData;
  }
}