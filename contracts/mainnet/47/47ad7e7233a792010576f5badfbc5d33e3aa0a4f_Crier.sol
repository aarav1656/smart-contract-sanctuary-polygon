/**
 *Submitted for verification at polygonscan.com on 2023-03-08
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IFxMessageProcessor {
    function processMessageFromRoot(uint256 stateId, address rootMessageSender, bytes calldata data) external;
}

contract Crier is IFxMessageProcessor {
    error InvalidChild();

    event Heard(uint256 stateId, address rootMessageSender, bytes data);

    /// @notice Address of Polygon's bridged message receiver
    address public fxChild;

    constructor(address _fxChild) {
        fxChild = _fxChild;
    }

    function processMessageFromRoot(uint256 stateId, address rootMessageSender, bytes calldata data) external {
        if (msg.sender != fxChild) revert InvalidChild();
        emit Heard(stateId, rootMessageSender, data);
    }
}