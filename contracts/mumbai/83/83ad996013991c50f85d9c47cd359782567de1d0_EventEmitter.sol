/**
 *Submitted for verification at polygonscan.com on 2022-08-27
*/

pragma solidity >=0.7.0 <0.9.0;

contract EventEmitter {
    event EmitMsg(address addr, string message);

    mapping(address => string[]) myAddressList;

    function doEmit(address callerAddr, string calldata message) public returns (bool) { 
        myAddressList[callerAddr].push(message);
        emit EmitMsg(callerAddr, message);
        return true;
    }

    function getMyString(address myAddr) public view returns (string[] memory) {
        return myAddressList[myAddr];
    }
}

contract EventEmitterCaller {

    address eventEmitterAddr;

    constructor(address _eventEmitterAddr) {
        eventEmitterAddr = _eventEmitterAddr;
    }

    event TestEvent(string message);

    function callDoEmit(string calldata message) public returns (bool){
        EventEmitter emitter = EventEmitter(eventEmitterAddr);
        return emitter.doEmit(msg.sender, message);
    }
}