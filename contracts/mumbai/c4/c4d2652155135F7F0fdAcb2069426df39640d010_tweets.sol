/**
 *Submitted for verification at polygonscan.com on 2022-08-23
*/

// File: contracts/Tweets.sol


pragma solidity ^0.8.7;

contract tweets {
    address public owner;
    uint256 private counter;

    constructor() {
        counter = 0;
        owner = msg.sender;
    }

    struct tweet {
        address tweeter;
        uint256 id;
        string tweetTxt;
        string tweetImg;
    }

    event tweetCreated(
        address tweeter,
        uint256 id,
        string tweetTxt,
        string tweetImg
    );

    //To store in solidity we use mapping
    mapping(uint256 => tweet) Tweets;

    //Function to add tweets to the Blochcahin
    function addTweet(string memory tweetTxt, string memory tweetImg)
        public
        payable
    {
        require(msg.value == (1 ether), "Please submit 1 Matic");
        tweet storage newTweet = Tweets[counter];
        newTweet.tweetTxt = tweetTxt;
        newTweet.tweetImg = tweetImg;
        newTweet.tweeter = msg.sender;
        newTweet.id = counter;

        emit tweetCreated(msg.sender, counter, tweetTxt, tweetImg);

        counter++;
        payable(owner).transfer(msg.value);
    }

    //Function to recover a tweet with an id
    function getTweet(uint256 id)
        public
        view
        returns (
            string memory,
            string memory,
            address
        )
    {
        require(id < counter, "No such Tweet");
        tweet storage t = Tweets[id];
        return (t.tweetTxt, t.tweetImg, t.tweeter);
    }
}