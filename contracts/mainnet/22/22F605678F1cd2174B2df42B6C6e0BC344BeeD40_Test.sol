// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract Test {
    uint256 public constant interval = 1 hours;
    uint256 public lastExecuted;

    event LogUpKeep(address _sender, uint256 _timestamp);

    function performUpkeep(bytes calldata) external {
        require(block.timestamp >= lastExecuted + interval, "slow");

        lastExecuted = block.timestamp;

        emit LogUpKeep(msg.sender, block.timestamp);
    }

    function checkUpkeep(bytes calldata)
        external
        view
        returns (bool, bytes memory)
    {
        if (block.timestamp >= lastExecuted + interval) {
            return (
                true,
                abi.encodeWithSelector(this.performUpkeep.selector, bytes(""))
            );
        }

        return (false, bytes("wait"));
    }
}