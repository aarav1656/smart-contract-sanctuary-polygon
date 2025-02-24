// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract Test {
    mapping(address => bool) wl;
    uint256 public interval;
    uint256 public lastExecuted;

    modifier onlyWhitelist() {
        require(wl[msg.sender], "Test: wl");
        _;
    }

    event LogUpKeep(address _sender, uint256 _timestamp);

    constructor() {
        interval = 5 minutes;
    }

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

    function setInterval(uint256 _interval) external onlyWhitelist {
        interval = _interval;
    }
}