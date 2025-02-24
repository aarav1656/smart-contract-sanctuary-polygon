// contracts/Box.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

//import "@openzeppelin/contracts/access/Ownable.sol";

contract BoxV2 {
    uint256 private _value;

    // Emitted when the stored value changes
    event ValueChanged(uint256 value);

    // Stores a new value in the contract
    function store(uint256 value) public {
        _value = value;
        emit ValueChanged(value);
    }
    
    function increment() public {
        _value = _value + 1;
        emit ValueChanged(_value);
    }

    // Reads the last stored value
    function retrieve() public view returns (uint256) {
        return _value;
    }
}