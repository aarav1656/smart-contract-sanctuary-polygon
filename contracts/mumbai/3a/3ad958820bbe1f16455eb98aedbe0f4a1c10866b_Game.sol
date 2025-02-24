/**
 *Submitted for verification at polygonscan.com on 2022-11-20
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Game {

    uint score;

    struct Hero { // only to define the structure; not to define any values to elements;
        string name;
        uint health;
        uint strength;
        uint agility;
        uint wisdom;
    }

    struct Spawn {
        uint health;
        uint strength;
        uint agility;
        uint wisdom;
    }

    struct Round {
        uint round;
    }

    Hero[] players;
    Spawn[] spawns;
    Round [] rounds;

    function addHero(string memory _name, uint _health, uint _strength, uint _agility, uint _wisdom) private {
        Hero memory newHero = Hero(_name, _health, _strength, _agility, _wisdom); // Create an `instance` of `Hero`
        players.push(newHero);
    } 

    function addSpawn() private {
        Spawn memory newSpawn = Spawn(100, 6, 5, 4);
        spawns.push(newSpawn);
    } 

    function addRound(uint _round) private {
        Round memory newRound = Round(_round);
        rounds.push(newRound);
    } 

    // TODO: generate pseudo-random nos for attributes

    // function getStrength(uint256 tokenId) public view returns (string memory) {
    //     return pluck(tokenId, "STRENGTH", strength);
    // }
    
    // function getAgility(uint256 tokenId) public view returns (string memory) {
    //     return pluck(tokenId, "AGILITY", agility);
    // }
    
    // function getWisdom(uint256 tokenId) public view returns (string memory) {
    //     return pluck(tokenId, "WISDOM", wisdom);
    // }

    // function pluck(uint256 tokenId, string memory keyPrefix, string[] memory sourceArray) internal pure returns (string memory) {
    //     uint256 rand = random(string(abi.encodePacked(keyPrefix, toString(tokenId))));
    //     string memory output = sourceArray[rand % sourceArray.length];
    //     return output;
    // }

    function mapPlayer(string memory _name, uint _str, uint _agi, uint _wis) public returns (uint) {
        addHero(_name, 100, _str, _agi, _wis); // addHero("Hero", 100, 10, 9, 8);
        return players.length-1; // return index of newly mapped player
    }

    function getHero(uint _index) public view returns (string memory, uint, uint, uint, uint) {
        Hero memory heroToReturn = players[_index];
        return (heroToReturn.name, heroToReturn.health, heroToReturn.strength, heroToReturn.agility, heroToReturn.wisdom);
    }

    function getSpawn(uint _index) public view returns (uint, uint, uint, uint) {
        Spawn memory spawnToReturn = spawns[_index];
        return (spawnToReturn.health, spawnToReturn.strength, spawnToReturn.agility, spawnToReturn.wisdom);
    }

    function getScore() public view returns(uint){
        return score;
    }
    
    function battle(uint _index) public returns (string memory) {
        // uint[] memory thisSpawn = addSpawn(); // doesn't work
        // thisSpawn[_index]; // hp
        // thisSpawn[_index]; // str
        // thisSpawn[_index]; // agi
        // thisSpawn[_index]; // wis

        addSpawn();
        addRound(_index);
        // players[_index].health;
        // players[_index].strength;
        // players[_index].agility;
        // players[_index].wisdom;
        // spawns[_index].health;
        // spawns[_index].strength;
        // spawns[_index].agility;
        // spawns[_index].wisdom;
        // rounds[_index].round;

        // start game
        while (players[_index].health > 0 && spawns[_index].health > 0){
            players[_index].health -= spawns[_index].strength;
            spawns[_index].health -= players[_index].strength;
        }

        // check winner
        if (players[_index].health < 0 && spawns[_index].health < 0){
            return "tie";
        } else if (players[_index].health > 0 && spawns[_index].health <= 0){
            score++;
            return "win";
        } else if (players[_index].health <= 0 && spawns[_index].health > 0){
            return "lose";
        }

        // end game, reset stats
        // players[_index].health = 100;
        
        return "game end";
    }
}