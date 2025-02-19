/**
 *Submitted for verification at polygonscan.com on 2022-11-20
*/

/*

       ▄▄▄▄███▄▄▄▄    ▄█  ███▄▄▄▄       ███           ▄██████▄     ▄████████      ████████▄     ▄████████    ▄████████     ███      ▄█  ███▄▄▄▄   ▄██   ▄
     ▄██▀▀▀███▀▀▀██▄ ███  ███▀▀▀██▄ ▀█████████▄      ███    ███   ███    ███      ███   ▀███   ███    ███   ███    ███ ▀█████████▄ ███  ███▀▀▀██▄ ███   ██▄
     ███   ███   ███ ███▌ ███   ███    ▀███▀▀██      ███    ███   ███    █▀       ███    ███   ███    █▀    ███    █▀     ▀███▀▀██ ███▌ ███   ███ ███▄▄▄███
     ███   ███   ███ ███▌ ███   ███     ███   ▀      ███    ███  ▄███▄▄▄          ███    ███  ▄███▄▄▄       ███            ███   ▀ ███▌ ███   ███ ▀▀▀▀▀▀███
     ███   ███   ███ ███▌ ███   ███     ███          ███    ███ ▀▀███▀▀▀          ███    ███ ▀▀███▀▀▀     ▀███████████     ███     ███▌ ███   ███ ▄██   ███
     ███   ███   ███ ███  ███   ███     ███          ███    ███   ███             ███    ███   ███    █▄           ███     ███     ███  ███   ███ ███   ███
     ███   ███   ███ ███  ███   ███     ███          ███    ███   ███             ███   ▄███   ███    ███    ▄█    ███     ███     ███  ███   ███ ███   ███
      ▀█   ███   █▀  █▀    ▀█   █▀     ▄████▀         ▀██████▀    ███             ████████▀    ██████████  ▄████████▀     ▄████▀   █▀    ▀█   █▀   ▀█████▀


    v1
    @author NFTArca.de
    @title Unlock for chapt3r.xyz

*/

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

contract chapt3rSacrifice {

    struct Witness {
        uint16 id;
        bool vote;
    }

    uint16 minT = 17022;
    uint16 maxT = 17121;

    address starter;
    uint256 public bS = 0;

    uint256 public toSacrificeT;
    address public toSacrifice;

    address[] witnesses;
    uint16[] witnessesT;

    mapping (address => Witness) witness;

    bool _pause = true;

    bool public godzAppeased = false;

    // Admins
    mapping (address => bool) admins;
    mapping (address => bool) witnessCheck;

    constructor() {
        admins[msg.sender] = true;
    }

    modifier onlyAdmins() {
        require(admins[msg.sender], "Only admins can call this function.");
        _;
    }

    modifier witnessesOnly() {
        require(witnessCheck[msg.sender], "Only witnesses can call this function.");
        _;
    }

    modifier whenNotPaused() {
        require(_pause == false, "Someone must begin the sacrifice first.");
        _;
    }

    function addAdmin(address newAdmin) public onlyAdmins{
        admins[newAdmin] = true;
    }

    function removeAdmin(address oldAdmin) public onlyAdmins{
        admins[oldAdmin] = false;
    }

    function pause() public onlyAdmins {
        _pause = true;
    }

    function unpause() public onlyAdmins {
        _pause = false;
    }

    function uB() public onlyAdmins {
        bS = block.timestamp;
    }

    function addWitness(address newWitnessAddress, uint16 id) public onlyAdmins whenNotPaused {
        require(witnesses.length < 4, "Reached witness limit");
        bool isWitness = false;
        for (uint i=0; i < witnesses.length; i++) {
            if (witnesses[i] == newWitnessAddress){
                isWitness = true;
            }
        }
        require(isWitness == false, "Hero has already proved worthiness");

        require(id >= minT && id <= maxT, "Not a suffecient Witness");

        witnesses.push(newWitnessAddress);
        witnessesT.push(id);
        witnessCheck[newWitnessAddress] = true;

        Witness memory newWitness;
        newWitness.id = id;
        newWitness.vote = false;
        witness[newWitnessAddress] = newWitness;
    }

    function addSacrifice(address sac, uint256 id) public onlyAdmins whenNotPaused {

        require(witnesses.length == 4, "Not enough witnesses have come forward yet");

        require(id >= minT && id <= maxT, "Not a suffecient Sacrifice");

        bool isWitness = false;
        for (uint i=0; i < witnesses.length; i++) {
            if (witnesses[i] == sac){
                isWitness = true;
            }
        }
        require(isWitness == false, "Hero cannot be a witness and sacrifice");

        toSacrifice = sac;
        toSacrificeT = id;
    }

    function getWitnessesVotes() public view whenNotPaused returns (bool[] memory) {

        require(witnesses.length == 4, "Not enough witnesses have come forward to begin voting");

        bool[] memory votes = new bool[](4);
        for (uint i=0; i < witnesses.length; i++) {
            votes[i] = witness[witnesses[i]].vote;
        }

        return votes;
    }

    function vote(bool myVote) public whenNotPaused witnessesOnly {

        require(witnesses.length == 4, "Not enough witnesses have come forward to begin voting");

        require(block.timestamp > bS + 3 days, "You have failed to appease the godz. There shall be no reward for the cowardly!");

        witness[msg.sender].vote = myVote;

        uint16 voteCount = 0;
        for (uint i=0; i < witnesses.length; i++) {
            if (witness[witnesses[i]].vote == true){
                voteCount += 1;
            }
        }
        if (voteCount == 4){
            godzAppeased = true;
        }
    }

    function getWitnesses() public view whenNotPaused returns(address[] memory){
        return witnesses;
    }

    function getWitnessesT() public view whenNotPaused returns(uint16[] memory){
        return witnessesT;
    }

    function startSacrifice() public {
        // Fail to appease the godz in a timely mannor and the one who started it will have all their tokens burned
        require(bS == 0, "The sacrifice has already begun");
        _pause = false;
        starter = msg.sender;
        bS = block.timestamp;
    }

    function timeRemaining() public view returns(uint256) {
        require(bS != 0, "The sacrifical alter has yet to be awaken");
        return (bS + 3 days) - block.timestamp;
    }
}