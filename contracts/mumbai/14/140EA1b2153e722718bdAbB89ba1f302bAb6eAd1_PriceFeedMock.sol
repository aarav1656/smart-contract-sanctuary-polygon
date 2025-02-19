// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract PriceFeedMock is AggregatorV3Interface {
  uint8 private _decimals;
  int256 private _price;

  constructor(uint8 decimals_, int256 price_) {
    _decimals = decimals_;
    _price = price_;
  }

  function decimals() external view override returns (uint8) {
    return _decimals;
  }

  function description() external pure override returns (string memory) {
    return "";
  }

  function version() external pure override returns (uint256) {
    return 1;
  }

  function getRoundData(uint80)
    external
    view
    override
    returns (
      uint80,
      int256 answer,
      uint256,
      uint256,
      uint80
    )
  {
    return (0, _price, 0, 0, 0);
  }

  function latestRoundData()
    external
    view
    override
    returns (
      uint80,
      int256 answer,
      uint256,
      uint256,
      uint80
    )
  {
    return (0, _price, 0, 0, 0);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
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