// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract MarketSentiment
{
    address public owner;
    string[] public tickersArray;

    constructor()
    {
        owner = msg.sender;
    }

    struct ticker
    {
        bool exists;
        uint256 up;
        uint256 down;
        mapping (address => bool) Voters;
    }

    event tickerupdated
    (
        uint256 up,
        uint256 down,
        address voter,
        string ticker
    );

    mapping (string => ticker) private Tickers;

    function addTicker (string memory _ticker) public
    {
        require(msg.sender == owner, "Tickets can be created by an owner only");
        ticker storage newTicker = Tickers[_ticker];
        newTicker.exists = true;
        tickersArray.push(_ticker);
    }

    function vote (string memory _ticker, bool _vote) public
    {
        require(Tickers[_ticker].exists, "Cannot vote for this cryptocurrency");
        require(!Tickers[_ticker].Voters[msg.sender], "You have voted for this coin already"); 

        ticker storage t = Tickers[_ticker];
        t.Voters[msg.sender] = true;

        if(_vote)
        {
            t.up++;
        }
        else
        {
            t.down++;
        }

        emit tickerupdated(t.up, t.down, msg.sender, _ticker);
    }

    function getVotes (string memory _ticker) public view returns
    (
        uint256 up,
        uint256 down
    )
    {
        require(Tickers[_ticker].exists, "No such ticker is defined");
        ticker storage t = Tickers[_ticker];
        return(t.up, t.down);
    }
}