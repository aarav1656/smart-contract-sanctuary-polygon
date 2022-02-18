// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import {Decimal} from "../lib/Decimal.sol";
import {ISapphireOracle} from "../oracle/ISapphireOracle.sol";

contract MockSapphireOracle is ISapphireOracle {

    // Priced at $10.00 (18 d.p)
    uint256 public currentPrice = 10 ** 19;

    uint256 public mockTimestamp = 0;
    bool public reportRealTimestamp = false;

    function fetchCurrentPrice()
        external
        override
        view
        returns (uint256 price, uint256 timestamp)
    {
        price = currentPrice;

        if (reportRealTimestamp) {
            timestamp = block.timestamp;
        } else {
            timestamp = mockTimestamp;
        }
    }

    function setPrice(
        uint256 _price
    )
        external
    {
        currentPrice = _price;
    }

    function setTimestamp(
        uint256 timestamp
    )
        external
    {
        mockTimestamp = timestamp;
    }

    function setReportRealTimestamp(
        bool _reportRealTimestamp
    )
        external
    {
        reportRealTimestamp = _reportRealTimestamp;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import {SafeMath} from "../lib/SafeMath.sol";
import {Math} from "./Math.sol";

/**
 * @title Decimal
 *
 * Library that defines a fixed-point number with 18 decimal places.
 */
library Decimal {
    using SafeMath for uint256;

    // ============ Constants ============

    uint256 public constant BASE = 10**18;

    // ============ Structs ============

    struct D256 {
        uint256 value;
    }

    // ============ Functions ============

    function one()
        internal
        pure
        returns (D256 memory)
    {
        return D256({ value: BASE });
    }

    function onePlus(
        D256 memory d
    )
        internal
        pure
        returns (D256 memory)
    {
        return D256({ value: d.value.add(BASE) });
    }

    function mul(
        uint256 target,
        D256 memory d
    )
        internal
        pure
        returns (uint256)
    {
        return Math.getPartial(target, d.value, BASE);
    }

    function mul(
        D256 memory d1,
        D256 memory d2
    )
        internal
        pure
        returns (D256 memory)
    {
        return Decimal.D256({ value: Math.getPartial(d1.value, d2.value, BASE) });
    }

    function div(
        uint256 target,
        D256 memory d
    )
        internal
        pure
        returns (uint256)
    {
        return Math.getPartial(target, BASE, d.value);
    }

    function add(
        D256 memory d,
        uint256 amount
    )
        internal
        pure
        returns (D256 memory)
    {
        return D256({ value: d.value.add(amount) });
    }

    function sub(
        D256 memory d,
        uint256 amount
    )
        internal
        pure
        returns (D256 memory)
    {
        return D256({ value: d.value.sub(amount) });
    }

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

interface ISapphireOracle {

    /**
     * @notice Fetches the current price of the asset
     *
     * @return price The price in 18 decimals
     * @return timestamp The timestamp when price is updated and the decimals of the asset
     */
    function fetchCurrentPrice()
        external
        view
        returns (uint256 price, uint256 timestamp);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {

        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;


/**
 * @title Math
 *
 * Library for non-standard Math functions
 */
library Math {
    uint256 public constant BASE = 10**18;

    // ============ Library Functions ============

    /*
     * Return target * (numerator / denominator).
     */
    function getPartial(
        uint256 target,
        uint256 numerator,
        uint256 denominator
    )
        internal
        pure
        returns (uint256)
    {
        return target * numerator / denominator;
    }

    function to128(
        uint256 number
    )
        internal
        pure
        returns (uint128)
    {
        uint128 result = uint128(number);
        require(
            result == number,
            "Math: Unsafe cast to uint128"
        );
        return result;
    }

    function min(
        uint256 a,
        uint256 b
    )
        internal
        pure
        returns (uint256)
    {
        return a < b ? a : b;
    }

    function max(
        uint256 a,
        uint256 b
    )
        internal
        pure
        returns (uint256)
    {
        return a > b ? a : b;
    }

    /**
     * @dev Performs a / b, but rounds up instead
     */
    function roundUpDiv(
        uint256 a,
        uint256 b
    )
        internal
        pure
        returns (uint256)
    {
        return (a * BASE + b - 1) / b;
    }

    /**
     * @dev Performs a * b / BASE, but rounds up instead
     */
    function roundUpMul(
        uint256 a,
        uint256 b
    )
        internal
        pure
        returns (uint256)
    {
        return (a * b + BASE - 1) / BASE;
    }
}