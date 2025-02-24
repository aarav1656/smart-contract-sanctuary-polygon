/**
 *Submitted for verification at polygonscan.com on 2022-10-12
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.11;


interface IForwarder {
  function approveAndDeposit(
    address, // ERC20
    uint8, // destinationDomainID
    bytes32, // resourceID
    bytes calldata, // depositData
    bytes calldata // feeData
  ) external;

  function deposit(
    uint8, // destinationDomainID
    bytes32, // resourceID
    bytes calldata, // depositData
    bytes calldata // feeData
  ) external;
}

contract Forwarder is IForwarder{
    function approveAndDeposit(
        address, // ERC20
        uint8, // destinationDomainID
        bytes32, // resourceID
        bytes calldata, // depositData
        bytes calldata // feeData
    ) external {

    }


    function deposit(
        uint8, // destinationDomainID
        bytes32, // resourceID
        bytes calldata, // depositData
        bytes calldata // feeData
    ) external {

    }
}