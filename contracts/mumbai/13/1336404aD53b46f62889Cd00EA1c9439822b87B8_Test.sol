// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract Test {

    address a;
    address b;
    uint256 c;
    bytes32 d;

    constructor(address vrfCoordinator, address linkToken,
    bytes32 vrfKeyHash, uint256 vrfFee) {
        a = vrfCoordinator;
        b = linkToken;
        c = vrfFee;
        d = vrfKeyHash;
        
    }

    function test1() public pure returns (uint256) {
        return 1;
    }
    function test2() public pure returns (uint256) {
        return 1;
    }
    uint256 public fee;
    // ID of public key against which randomness is generated
    bytes32 public keyHash;


}