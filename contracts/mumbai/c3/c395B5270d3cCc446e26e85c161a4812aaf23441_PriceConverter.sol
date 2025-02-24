// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

/**
 * (MATIC/USD) / (EUR/USD) = MATIC/EUR
 * Base: MATIC/USD
 * Base Address: 0xAB594600376Ec9fD91F8e885dADF0CE036862dE0
 * Quote: EUR/USD
 * Quote Address: 0x73366Fe0AA0Ded304479862808e02506FE556a98
 * Decimals: 8
 */
contract PriceConverter {
    address public priceFeedEurUsd;
    address public priceFeedMaticUsd;

    constructor(address _priceFeedEurUsd, address _priceFeedMaticUsd) {
        priceFeedEurUsd = _priceFeedEurUsd;
        priceFeedMaticUsd = _priceFeedMaticUsd;
    }

    function getMaticInWeiFromEurCents(uint256 eurCentsAmount) public view returns (uint256) {
        require(eurCentsAmount >= 1, "Amount in cents need to be at least 1");
        uint256 maticPriceInEuroWei = (uint256) (getDerivedPrice(priceFeedEurUsd, priceFeedMaticUsd, 18));
        uint256 eurAmountInMaticWei = maticPriceInEuroWei * eurCentsAmount / 100;
        return eurAmountInMaticWei;
    }

    function getDerivedPrice(address _base, address _quote, uint8 _decimals) public view returns (int256) {
        require(_decimals > uint8(0) && _decimals <= uint8(18), "Invalid _decimals");
        int256 decimals = int256(10 ** uint256(_decimals));
        (, int256 basePrice, , ,) = AggregatorV3Interface(_base).latestRoundData();
        uint8 baseDecimals = AggregatorV3Interface(_base).decimals();
        basePrice = scalePrice(basePrice, baseDecimals, _decimals);

        (, int256 quotePrice, , ,) = AggregatorV3Interface(_quote).latestRoundData();
        uint8 quoteDecimals = AggregatorV3Interface(_quote).decimals();
        quotePrice = scalePrice(quotePrice, quoteDecimals, _decimals);

        return basePrice * decimals / quotePrice;
    }

    function scalePrice(int256 _price, uint8 _priceDecimals, uint8 _decimals) internal pure returns (int256) {
        if (_priceDecimals < _decimals) {
            return _price * int256(10 ** uint256(_decimals - _priceDecimals));
        } else if (_priceDecimals > _decimals) {
            return _price / int256(10 ** uint256(_priceDecimals - _decimals));
        }
        return _price;
    }
}

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