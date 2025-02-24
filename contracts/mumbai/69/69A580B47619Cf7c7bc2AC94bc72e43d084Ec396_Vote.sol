// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

contract Vote {
    address public owner;
    string[] public tickerArray;

    constructor() {
        owner = msg.sender;
    }

    struct ticker {
        bool exists;
        uint256 up;
        uint256 down;
        mapping(address => bool) Voters;
    }

    event tickerupdated (
        uint256 up,
        uint256 down,
        address voter,
        string ticker
    );

    mapping(string => ticker) private Tickers;

    function addTicker(string memory _ticker) public {
        require(msg.sender == owner, "Only the owner can create tickers");
        ticker storage newTicker = Tickers[_ticker];
        newTicker.exists = true;
        tickerArray.push(_ticker);
    }

    function vote(string memory _ticker, bool _vote) payable public {
        require(Tickers[_ticker].exists, "Can't vote on this coin");
        require(!Tickers[_ticker].Voters[msg.sender], "You have already voted for this coin");
        

        ticker storage t = Tickers[_ticker];
        t.Voters[msg.sender] = true;

        if(_vote){
            t.up += msg.value;
        } else {
            t.down += msg.value;
        }

        emit tickerupdated(t.up, t.down, msg.sender, _ticker);
    }

    function getVotes(string memory _ticker) public view returns(
        uint256 up,
        uint256 down
    ) {
        require(Tickers[_ticker].exists, "No such Ticker defined");
        ticker storage t = Tickers[_ticker];
        return(t.up, t.down);
    }
}