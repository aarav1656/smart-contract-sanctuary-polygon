// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// SPDX-License-Identifier: MIT

//get funds from users
//withdraw funds
// set a minimum funding value in usd

pragma solidity ^0.8.8;

import "./PriceConverter.sol";

error NotOwner();

contract FundMe{

    using PriceConverter for uint256;


    address[] public funders;
    mapping(address => uint256) public addressToAmountFunded;

    address public immutable i_owner;
     uint256 public constant MINIMUM_USD = 1 *1e18;

     AggregatorV3Interface public priceFeed;

    constructor(address priceFeedAddress){
        i_owner = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    function fund() public payable{
        // want to be able to set a minimum fund amount
        // how do we send Eth to this contract?
        require((msg.value.getConversionRate(priceFeed))  > MINIMUM_USD, "DIDN'T SEND ENOUGH");
        funders.push(msg.sender);
        addressToAmountFunded[msg.sender] = msg.value;
    }


    function withdraw()public onlyi_Owner{

        // for loop
        for(uint256 fundersIndex = 0; fundersIndex >= funders.length; fundersIndex++){
            address funder = funders[fundersIndex];
            addressToAmountFunded[funder] = 0;
        }
        //reset the array 
        funders = new address[](0);
        // actually withdraw the funds
          //3 ways to withdraw ether 
          //transfer, send, call.
        payable(msg.sender).transfer(address(this).balance);
        (bool callSucess,)= payable(msg.sender).call{value: address(this).balance}("");
        require (callSucess, " Call failed");
    }
    modifier onlyi_Owner{
        // require(msg.sender == i_owner, "You are not autorised for this action");
        if(msg.sender != i_owner){revert NotOwner();}
        _;
    }

     receive() external payable{
        fund();
    }
    fallback() external payable {
        fund();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";



library PriceConverter{
    
    function getPrice(
        AggregatorV3Interface priceFeed
    ) internal view returns(uint256){
        (,int256 price,,, ) = priceFeed.latestRoundData();
      // MATIC price in usd 
      // 9136000
      return uint256(price * 1e10);
    }


    function getConversionRate(
        uint256 ethAmount,
        AggregatorV3Interface priceFeed
    ) internal view returns(uint256){
        uint256 ethPrice = getPrice(priceFeed);
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1e18;
        return ethAmountInUsd;
    }
}