/**
 *Submitted for verification at polygonscan.com on 2022-09-28
*/

// SPDX-License-Identifier: PUCRS

pragma solidity >= 0.8.9;

contract StationManager {
    struct Station{
        uint index;
        string cod_station;
        bool is_online;
        string address_details;
        string address_active_contract;
        bool is_deprecated;
        uint lastUpdate;
    }
 
    event stationEvent(uint indexed _stationIndex);

    uint stationCount;

    constructor() {
        stationCount = 0;
    }
    
    Station[] station_enrolled;
    
    mapping(uint => Station) stations;
    
    function compareStrings(string memory _a, string memory _b) private pure returns (bool) {
        return keccak256(abi.encodePacked(_a)) == keccak256(abi.encodePacked(_b));
    }

    function getStationInfo(string memory _cod_station) public view returns (Station[] memory) {
        //Station[] memory index = new Station[](stationCount);
        Station[] memory index = new Station[](1);
        /*for (uint i = 0; i < stationCount; i++){
            Station storage station = stations[i];
            if (compareStrings(station.cod_station, _cod_station) == true) {
                index[i] = station; 
            }
            index[i] = station;   
        }*/
        uint indexValue = stationExists(_cod_station);
        if (indexValue <= stationCount) {
            Station storage station = stations[indexValue];
            index[0]=station;
        } 
        return index;        
    }

    function getAllStationInfo() public view returns (Station[] memory) {
        Station[] memory index = new Station[](stationCount);
        for (uint i = 0; i < stationCount; i++){
            Station storage station = stations[i];
            index[i] = station;   
        }
        return index;
    }

    function stationExists(string memory _cod_station) private view returns (uint) {
        for (uint i = 0; i < stationCount; i++){
            Station storage station = stations[i];
            if (compareStrings(station.cod_station, _cod_station) == true) {
                return i; 
            } 
        }
        return stationCount+1;
    }

    function addStation(string memory _cod_station, string memory _address_details) public returns (bool){
        if (stationExists(_cod_station) > stationCount)  {
            stations[stationCount] = Station(
                stationCount,
                _cod_station,
                true,
                _address_details,
                "null",
                false,
                block.timestamp
            );
            stationCount++;
            return (true);
        } else {return(false);}
    }

    function setActiveAddressContract(string memory _cod_station, string memory _address_active_contract) 
    public returns (bool) {
        uint index = stationExists(_cod_station);
        if ( index <= stationCount)  { 
            //Station memory station = stations[index];
            /*stations[index] = Station(
                station[index].index,
                station[index].cod_station,
                station[index].is_online,
                station[index].address_details,
                _address_active_contract,
                station[index].is_deprecated,
                block.timestamp
            );*/
            stations[index].address_active_contract = _address_active_contract;
            //Station[0].address_active_contract = _address_active_contract;
            return true;
        } else return false;
    }
    function getNumStations() public view returns (uint) {
        return stationCount;
    }
}