pragma solidity 0.8.15;


contract MockPriceFeed  {
    function latestAnswer() external pure returns (int256) {
        return 0;
    }
    function decimals() external pure returns (uint8) {
        return 18;
    }
}