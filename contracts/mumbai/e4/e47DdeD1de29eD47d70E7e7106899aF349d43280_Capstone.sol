/**
 *Submitted for verification at polygonscan.com on 2022-11-22
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract Capstone {

    address public owner;

    struct LAND {
        uint256 id;
        string uri;
        uint256 price;
        mapping(address => uint256) holders;
        address max_holder;
        uint256 max_amount;
        uint256 remain;

        bool listed_rent;
        bool rented;
        address renter;
        uint256 rent_price;
        uint256 rent_start_date;
        uint256 rent_end_date;
    }
    
    mapping(uint256 => LAND) public lands;
    uint256 private land_count;

    uint256[] private landList;
    uint256[] private rentList;

    address public dead = 0x000000000000000000000000000000000000dEaD;

    constructor() {
        owner = msg.sender;
        land_count = 0;
    }

    modifier onlyOwner {
        require(owner == msg.sender, "This function can be called by only owner");
        _;
    }

    function addLand ( string memory uri_, uint256 price_ ) onlyOwner public {
        lands[land_count].id = land_count;
        lands[land_count].uri = uri_;
        lands[land_count].price = price_;
        lands[land_count].max_holder = dead;
        lands[land_count].max_amount = 0;
        lands[land_count].remain = price_;
        lands[land_count].rented = false;
        lands[land_count].renter = dead;

        landList.push(land_count);
        land_count ++;
    }

    function buyLand ( uint256 id ) public payable {
        require(lands[id].remain >= msg.value, "This land is not enough.");
        uint256 land_price = lands[id].holders[msg.sender];
        if(lands[id].max_amount < land_price + msg.value) {
            lands[id].max_amount = land_price + msg.value;
            lands[id].max_holder = msg.sender;
        }
        lands[id].remain = lands[id].remain - msg.value;
        lands[id].holders[msg.sender] += msg.value;
        if(lands[id].remain == 0) {
            for(uint256 i = 0 ; i < landList.length ; i ++) {
                if(landList[i] == id) {
                    delete landList[i];
                    break;
                }
            }
        }
    }

    function listRent ( uint256 id, uint256 price ) public {
        require(lands[id].max_holder == msg.sender, "You are not allowed to rent");
        require(lands[id].listed_rent == false, "This land is already listed");
        rentList.push(id);
        lands[id].listed_rent = true;
        lands[id].rent_price = price;
    }

    function stopRent ( uint256 id ) public {
        require(lands[id].max_holder == msg.sender, "You are not allowed to do this action");
        for(uint256 i = 0 ; i < landList.length ; i ++) {
            if(rentList[i] == id) {
                lands[id].listed_rent = false;
                lands[id].rent_price = 0;
                delete rentList[i];
                break;
            }
        }
    }

    function rentLand ( uint256 id, uint256 start_date, uint256 end_date ) public payable {
        require(lands[id].listed_rent == true, "This land is not allowed to rent");
        require(lands[id].rented == false, "This land is already rented");
        uint256 period = (end_date - start_date) / 60 / 60 / 24;
        require(lands[id].rent_price * period / 30 <= msg.value, "Insufficient money");
        lands[id].renter = msg.sender;
        lands[id].rented = true;
        lands[id].rent_start_date = start_date;
        lands[id].rent_end_date = end_date;
    }

    function delayRent (uint256 id, uint256 to_date) public payable {
        require(lands[id].renter == msg.sender, "You can not delay to rent for this land.");
        uint256 period = (to_date - lands[id].rent_end_date) / 60 / 60 / 24;
        require(lands[id].rent_price * period / 30 <= msg.value, "Insufficient money");
        lands[id].rent_end_date = to_date;
    }

    function getLandList () public view returns (uint256[] memory) {
        return landList;
    }

    function getRentList () public view returns (uint256[] memory) {
        return rentList;
    }

    function getLandInfo (uint256 id) public view returns (string memory , uint256, uint256) {
        LAND storage current = lands[id];
        return (current.uri, current.price, current.remain);
    }

    function getRentInfo (uint256 id) public view returns (address, uint256, uint256, uint256) {
        LAND storage current = lands[id];
        return (current.renter, current.rent_price, current.rent_start_date, current.rent_end_date);
    }
}