// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// a simple set and get function for mood defined:

contract MoodDiary {
    string mood;

    function setMood(string memory _mood) public {
        mood = _mood;
    }

    function getMood() public view returns (string memory) {
        return mood;
    }
}