// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

contract Counter {
    address public AMB;
    address public sendingCounter;
    address public receivingCounter;
    uint256 public counter;

    constructor(address _AMB) {
        AMB = _AMB;
        sendingCounter = address(this);
    }

    function setReceivingCounter(address _receivingCounter) public {
        receivingCounter = _receivingCounter;
    }

    function send() public returns (bytes memory) {
        require(receivingCounter != address(0), "Receiving counter not set");
        (bool success, bytes memory data) = AMB.call(
            abi.encode(
                "send(address,bytes)",
                receivingCounter,
                abi.encode("increment()")
            )
        );
        require(success, "Call to AMB failed");
        return data;
        // IAMB.send(...) // TODO: figure out data to send
    }

    function increment() public {
        // ... // TODO: validation of message call
        counter++;
    }
}