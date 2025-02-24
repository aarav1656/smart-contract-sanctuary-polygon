// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: GPL-3.0
import "@openzeppelin/contracts/utils/Strings.sol";

pragma solidity >=0.7.0 <0.9.0;

contract Lottery {
    uint256 public constant ticketPrice = 5 ether;
    uint256 public constant ticketCommission = 0.1 ether; // commition per ticket
    uint256 public constant duration = 30 days; // The duration set for the lottery


    address public lotteryOperator; // the crator of the lottery
    uint256 public operatorTotalCommission = 0; // the total commission balance

    uint256 public lotteryNumber = 0;
    uint256 public lotteryExtraPay = 0;
    uint256 public expiration; // Timeout in case That the lottery was not carried out.

    address public lastWinner; // the last winner of the lottery
    uint256 public lastWinnerAmount; // the last winner amount of the lottery
    uint256 public totalWinning; // Overall Winning

    uint256 public totalStaked; // total staked amount
    address[] public stakers;
    mapping(address => uint) indexOfStakers;
    mapping(address => bool) insertedStaker;

    address[] public tickets; //array of purchased Tickets

    struct Winning {
        uint256 lotteryNumber;
        address winner;
        uint256 amount;
        uint256 timestamp;
        uint256 totalTickets;
        uint256 winningTickets;
        uint256 operatorCommission;
    }

    Winning[] public winnings;

    struct StakedInterest {
        uint256 amount;
        uint256 timestamp;
        uint256 lotteryNumber;
    }

    struct User {
        bytes32 name;   // short name (up to 32 bytes)
        uint256 totalWinning;
        uint256 remainingWithdraw;
        uint256 totalTickets;
        uint256 lotteryNumber;
        uint256 lotteryTickets;
        uint256 staked;
        uint256 stakedExpiration;
        uint256 totalStakedInterest;
        StakedInterest[] stakedInterest;
    }

    mapping(address => User) users;

    struct OperatorCommision {
      bytes32 name; // [TICKET_COMMISON, PRE_WITHDRAWL_STAKE_COMMISION, LOTTERY_COMMISSION]
      uint256 amount;
      uint256 timestamp;
      uint256 user;
    }

    OperatorCommision[] public OpCommisions;
    
    // modifier to check if caller is the lottery operator
    modifier isOperator() {
        require(
            (msg.sender == lotteryOperator),
            "Caller is not the lottery operator"
        );
        _;
    }

    // modifier to check if caller is a winner
    modifier isWinner() {
        require(IsWinner(), "Caller is not a winner");
        _;
    }

    modifier isStaker() {
        require(IsStaker(), "Caller is not a staker");
        _;
    }

    constructor() {
        lotteryOperator = msg.sender;
        expiration = block.timestamp + duration;
    }


    // return all the tickets
    function getTickets() public view returns (address[] memory) {
        return tickets;
    }

    function getWinningsForAddress(address addr) public view returns (uint256) {
        return users[addr].remainingWithdraw;
    }

    function BuyTickets() public payable {
        require(
            msg.value % ticketPrice == 0,
            string.concat(
                "the value must be multiple of ",
                Strings.toString(ticketPrice),
                " Ether"
            )
        );
        uint256 numOfTicketsToBuy = msg.value / ticketPrice;
        for (uint256 i = 0; i < numOfTicketsToBuy; i++) {
            tickets.push(msg.sender);
        }
        User storage user = users[msg.sender];
        user.totalTickets += numOfTicketsToBuy;
        if(user.lotteryNumber != lotteryNumber) {
            user.lotteryTickets = 0;
            user.lotteryNumber = lotteryNumber;
        }
        user.lotteryTickets += numOfTicketsToBuy;
    }

    function StakeAsset(uint256 exp) public payable {
        require(
            msg.value % 1 == 0,
            string.concat(
                "the value must be multiple of ",      
                Strings.toString(1),
                " Ether"
            )
        );
        User storage user = users[msg.sender];
        if(user.stakedExpiration < exp) { user.stakedExpiration = exp; }
        user.staked += msg.value;
        totalStaked += msg.value;
        
        if(!insertedStaker[msg.sender]) {
            insertedStaker[msg.sender] = true;
            indexOfStakers[msg.sender] = stakers.length;
            stakers.push(msg.sender);
        }
    }

    function DrawWinnerTicket() public isOperator {
        require(tickets.length > 0, "No tickets were purchased");

        bytes32 blockHash = blockhash(block.number - tickets.length);
        uint256 randomNumber = uint256(
            keccak256(abi.encodePacked(block.timestamp, blockHash))
        );
        uint256 winningTicket = randomNumber % tickets.length;
        address winner = tickets[winningTicket];
        /* New Winning Logic */
        lastWinner = winner;
        uint256 totalAmount = (tickets.length * (ticketPrice - ticketCommission) + lotteryExtraPay);
        uint256 winnerAmount = totalAmount * 1 / 2; // 50% of winning
        uint256 stakedAmount = totalAmount * 2 / 5; // 40% of winning
        uint256 operatorAmount = totalAmount * 1 / 10; // 10% winning 

        lastWinnerAmount = winnerAmount;
        operatorTotalCommission += (tickets.length * ticketCommission) + operatorAmount;

        User storage winningUser = users[winner];
        winningUser.remainingWithdraw += winnerAmount;
        winningUser.totalWinning += winnerAmount;
        totalWinning += winnerAmount; // Overall Winning
        Winning memory newWinning;
        newWinning.amount = winnerAmount;
        newWinning.lotteryNumber = lotteryNumber;
        newWinning.operatorCommission = (tickets.length * ticketCommission);
        newWinning.timestamp = block.timestamp;
        newWinning.totalTickets = tickets.length; 
        newWinning.winner = winner;
        newWinning.winningTickets = winningUser.lotteryTickets;
        winnings.push(newWinning);

        // Add Operator Commission
        OperatorCommision memory comp1;
        comp1.name = "TICKET_COMMISON";
        comp1.amount = tickets.length * ticketCommission;
        comp1.timestamp =  block.timestamp;
        OpCommisions.push(comp1);
        OperatorCommision memory comp2;
        comp2.name = "LOTTERY_COMMISSION";
        comp2.amount = operatorAmount;
        comp2.timestamp =  block.timestamp;
        OpCommisions.push(comp2);

        // Add to staking
        for(uint i=0; i < stakers.length; i++) {
            User storage tmpUser = users[stakers[i]];
            uint interest = ( tmpUser.staked * stakedAmount ) / totalStaked;
            tmpUser.totalStakedInterest += interest;
            StakedInterest memory sk;
            sk.amount = interest;
            sk.timestamp = block.timestamp;
            sk.lotteryNumber = lotteryNumber;
            tmpUser.stakedInterest.push(sk);
        }
        /* End New Winning Logic */
        delete tickets;
        lotteryNumber = lotteryNumber + 1;
        expiration = block.timestamp + duration;
    }

    function restartDraw() public isOperator {
        require(tickets.length == 0, "Cannot Restart Draw as Draw is in play");

        delete tickets;
        expiration = block.timestamp + duration;
    }

    function checkWinningsAmount() public view returns (uint256) {
        address payable winner = payable(msg.sender);

        uint256 reward2Transfer = users[winner].remainingWithdraw;

        return reward2Transfer;
    }

    function WithdrawWinnings() public isWinner {
        address payable winner = payable(msg.sender);

        uint256 reward2Transfer = users[winner].remainingWithdraw;
        users[winner].remainingWithdraw = 0;

        winner.transfer(reward2Transfer);
    }

    function RefundAll() public {
        // require(block.timestamp >= expiration, "the lottery not expired yet");

        for (uint256 i = 0; i < tickets.length; i++) {
            address payable to = payable(tickets[i]);
            tickets[i] = address(0);
            to.transfer(ticketPrice);
        }
        delete tickets;
    }

    function WithdrawCommission() public isOperator {
        address payable operator = payable(msg.sender);

        uint256 commission2Transfer = operatorTotalCommission;
        operatorTotalCommission = 0;

        operator.transfer(commission2Transfer);
    }

    function IsWinner() public view returns (bool) {
        return users[msg.sender].remainingWithdraw > 0;
    }

    function IsStaker() public view returns (bool) {
        return users[msg.sender].staked > 0;
    }

    function IsOperator(address addr) public view returns (bool) {
        return addr == lotteryOperator;
    }

    function CurrentWinningReward() public view returns (uint256) {
        return tickets.length * ticketPrice + lotteryExtraPay;
    }

    function TotalTickets() public view returns (uint256) {
        return tickets.length;
    }

    function LotteryNumber() public view returns (uint256) {
        return lotteryNumber;
    }

    function getUser(address addr) public view returns (User memory) {
        return users[addr];
    }

    function getWinnings() public view returns (Winning[] memory) {
        return winnings;
    }

    function getOpComLogs() public view returns (OperatorCommision[] memory) {
        return OpCommisions;
    }

    function getStakers() public view returns (address[] memory) {
        return stakers;
    }

    function TotalStaked() public view returns (uint256) {
        return totalStaked;
    }

    function TotalStakers() public view returns (uint256) {
        return stakers.length;
    }

    function TotalWinning() public view returns (uint256) {
        return totalWinning;
    }

    function WithdrawStake() public isStaker {
        address payable operator = payable(msg.sender);
        uint256 stake2Transfer = users[msg.sender].staked + users[msg.sender].totalStakedInterest;

        // require(stake2Transfer == 0, "Staked amount is 0");
        // Check for stakedExpiration

        if(users[msg.sender].stakedExpiration > block.timestamp) {
            stake2Transfer /= 2;
            operatorTotalCommission += stake2Transfer / 2; // +25 %
            lotteryExtraPay += stake2Transfer / 2; // +25 %
            // Add Operator commission log
            OperatorCommision memory comp;
            comp.name = "PRE_WITHDRAWL_STAKE_COMMISION";
            comp.amount = stake2Transfer / 2;
            comp.timestamp =  block.timestamp;
            OpCommisions.push(comp);
        }

        totalStaked -= users[msg.sender].staked;
        users[msg.sender].staked = 0;
        users[msg.sender].stakedExpiration = 0;
        users[msg.sender].totalStakedInterest = 0;
        

        // new logic
        delete insertedStaker[msg.sender];

        uint index = indexOfStakers[msg.sender];
        uint lastIndex = stakers.length - 1;
        address lastStaker = stakers[lastIndex];

        indexOfStakers[lastStaker] = index;
        delete indexOfStakers[msg.sender];

        stakers[index] = lastStaker;
        stakers.pop();
        // end new logic 

        operator.transfer(stake2Transfer);
    }
}