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
pragma solidity 0.8.17;

import "./PriceConverter.sol";

error NotOwner();
error NotEnoughAmount();

contract FundMe {
    using PriceConvertor for uint256;

    uint256 public constant MINIMUM_USD = 50 * 1e18;
    
    address[] public funders;
    mapping(address => uint256) public addressToAmountFunded;
    
    address public immutable i_owner;

    AggregatorV3Interface public priceFeed;

    modifier onlyOwner {
        if(msg.sender != i_owner) revert NotOwner();
        _;
    }

    constructor(address priceFeedAddress) {
        i_owner = msg.sender;    
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }
    
    function fund() public payable {
        if(msg.value.getConversion(priceFeed) < MINIMUM_USD) revert NotEnoughAmount();
        funders.push(msg.sender);
        addressToAmountFunded[msg.sender] = msg.value;
     }

    function widthdraw() public onlyOwner {

        for (uint256 funderIndex = 0; funderIndex < funders.length; funderIndex++) {
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }
        funders = new address[](0);

        (bool callSuccess,) = payable(msg.sender).call{value: address(this).balance}("");
        require (callSuccess, "Call failed"); 
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConvertor {
     function getPrice(AggregatorV3Interface priceFeed) internal view returns(uint256) {
     (,int price,,,) = priceFeed.latestRoundData();

     return uint256(price * 1e18);
     }

     function getConversion(uint256 ethAmount, AggregatorV3Interface priceFeed) internal view returns (uint256) {
         uint256 ethPrice = getPrice(priceFeed);
         uint256 ethAmountInUSD = (ethPrice * ethAmount) / 1e18;
         return ethAmountInUSD;
     }
}