// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./PRBMathSD59x18.sol";

import "./core/MonksTypes.sol";
import "./interfaces/IMonksPublication.sol";
import "./interfaces/IMonksMarket.sol";
import "@opengsn/contracts/src/ERC2771Recipient.sol";

error MarketAlreadyInitialised();
error MarketUnauthorized();
error MarketHasNoBets();
error MarketIsNotFunded();


contract MonksMarket is IMonksMarket, ERC2771Recipient {
    using PRBMathSD59x18 for int256;

    // Constants assigned during the initialise
    // ***************************************************************************************
    uint public funding;  // total funding for this post (Protocol + Writers + Predictors/Markets + Moderators)
    MonksTypes.PayoutSplitBps private _payoutSplitBps; // we have a getter for this
    uint public expiryDate;
    int public alpha;
    MonksTypes.ResultBounds public bounds;
    
    bytes20 private _postId;
    MonksTypes.Post public post;
    IERC20 private _monksToken;
    IMonksPublication private _publication;

    // Constants assigns after publication:
    uint public tweetId;
    uint public publishTime;
    uint public totalTokensCollected;

    // State variables
    // ***************************************************************************************
    // q[0] amount of X shares sold, q[1] amount of 1-X shares sold.
    // each X share will return normalisedResult tokens
    // each 1-X share will return 1-normalisedResult tokens
    int[2] public q;
    int[2] private _initialQ;
    mapping(address => int[2]) public sharesOf;
    mapping(address => uint) public tokensOf;

    Status private _status;
    // MonksMarket are positive-sum, meaning that the market always loses money to the participants.
    // This is how we incentivise monks to participate in the markets.
    // The market will always lose "funding*payoutSplitBps.editors/10000" tokens.
    // Some of the market losses, are due to its initial bet - but if the market doesn't lose enough due to its bet
    // we will distribute the "exceeding" amongst all market participants according to the amount of tokens they bet.
    uint public exceeding;

    // The normalised result is the ground truth by a ChainLink oracle but normalised. 
    // normalisedResult = clip((result - minResult)/(maxResult - minResult), 0, 1)
    int public normalisedResult;

    bool private _isInitialised;

    function init(bytes20 postId_, MonksTypes.Post memory post_) public {
        if (_isInitialised == true) {
            revert MarketAlreadyInitialised();
        }
        _postId = postId_;
        _setTrustedForwarder(ERC2771Recipient(msg.sender).getTrustedForwarder());
        _publication = IMonksPublication(msg.sender);
        _monksToken = _publication.monksERC20();
        uint8 postType = post_.postType;
        funding = _publication.issuancePerPostType(postType);
        (uint128 minResult, uint128 maxResult) = _publication.bounds();
        bounds = MonksTypes.ResultBounds(minResult, maxResult);

        (uint16 coreTeam, uint16 writer, uint16 editors, uint16 moderators) = _publication.payoutSplitBps();
        _payoutSplitBps = MonksTypes.PayoutSplitBps(coreTeam, writer, editors, moderators);
        alpha = _publication.alpha();
        expiryDate = block.timestamp + _publication.postExpirationPeriod();

        int[2] memory _q = [_publication.initialQs(postType, 0), _publication.initialQs(postType, 1)];
        _initialQ = _q;
        q = _q;

        _status = Status.Active;
        post = post_;

        _isInitialised = true;
    }

    // Modifiers
    // ***************************************************************************************
    modifier onlyModerator() {
        if (!_publication.hasRole(MonksTypes.MODERATOR_ROLE, _msgSender())) {
            revert MarketUnauthorized();
        }
        _;
    }

    modifier onlyPublication() {
        if (address(_publication) != msg.sender) {
            revert MarketUnauthorized();
        }
        _;
    }

    modifier onlyStatus(Status status_) {
        if (status() != status_) {
            revert InvalidMarketStatusForAction();
        }
        _;
    }

    // Public Market Functions
    // ***************************************************************************************
    function buy(int sharesToBuy_, bool isYes_, uint maximumCost_) public onlyStatus(Status.Active) {
        require(sharesToBuy_ > 0);
        uint amountToPay = deltaPrice(sharesToBuy_, isYes_);
        if(amountToPay > maximumCost_) {
            revert MarketExceededMaxCost();
        }
        _monksToken.transferFrom(_msgSender(), address(this), amountToPay);
        _buy(sharesToBuy_, isYes_, amountToPay, _msgSender()); 
        _publication.emitOnSharesBought(_postId, _msgSender(), uint(sharesToBuy_), amountToPay, isYes_);
    }

    function redeemAll() public {
        // No need to check status() here, checking _status is a bit cheaper.
        if (_status != Status.Resolved) { 
            revert InvalidMarketStatusForAction();
        }
        int[2] memory shares = sharesOf[_msgSender()];
        require(shares[0] > 0 || shares[1] > 0);
        sharesOf[_msgSender()][0] = 0;
        sharesOf[_msgSender()][1] = 0;
        uint amount;
        if (shares[0] > 0) {
            amount += uint(normalisedResult.mul(shares[0]));
        }
        if (shares[1] > 0) {
            amount += uint((1E18 - normalisedResult).mul(shares[1]));
        }
        if (exceeding > 0) {
            amount += exceeding * tokensOf[_msgSender()] / totalTokensCollected;
        }
        _monksToken.transfer(_msgSender(), amount);
        _publication.emitOnTokensRedeemed(_postId, _msgSender(), amount, tokensOf[_msgSender()]);
    }

    function getRefund() public {
        Status s = status();
        require(s == Status.Expired || s == Status.Flagged);
        uint amount = tokensOf[_msgSender()];
        require(amount > 0);
        tokensOf[_msgSender()] = 0;
        _monksToken.transfer(_msgSender(), amount);
        _publication.emitOnRefundTaken(_postId, _msgSender(), amount);
    }

    // Market Getters
    // ***************************************************************************************
    function postTypeAndAuthor() public view returns (uint8, address) {
        MonksTypes.Post memory _post = post;
        return (_post.postType, _post.author);
    }

    function payoutSplitBps() external view returns (MonksTypes.PayoutSplitBps memory) {
        return _payoutSplitBps;
    }

    function status() public view returns (Status) {
        if (_status == Status.Active && block.timestamp > expiryDate) {
            return Status.Expired;
        }
        return _status;
    }

    function deltaPrice(int shares_, bool isYes_) public view returns (uint) {
        int[2] memory _q = q;
        int[2] memory qz = [_q[0], _q[1]];
        if (shares_ > 0) {
            qz[isYes_ ? 0 : 1] += shares_;
        }
        int price = _cost(qz) - _cost(_q);
        return uint(price);
    }

    // Internal Functions
    // ***************************************************************************************

    function _buy(int sharesToBuy_, bool isYes_, uint amountToPay_, address buyer_) internal {
        uint8 outcomeIndex = isYes_ ? 0 : 1;
        q[outcomeIndex] += sharesToBuy_;
        sharesOf[buyer_][outcomeIndex] += sharesToBuy_;
        tokensOf[buyer_] += amountToPay_;
    }

    function _getB(int[2] memory q_) internal view returns (int) {
        return alpha.mul(q_[0]+ q_[1]);
    }

    function _cost(int[2] memory q_) internal view returns (int){
        int b = _getB(q_);
        return b.mul((q_[0].div(b).exp() + q_[1].div(b).exp()).ln());
    }

    /**
     * @dev Normalize the result to be a number between 0 and 1E18 which correspond to minResult and maxResult.
     */
    function _normaliseResult(uint result) internal view returns (uint) {
        if (result < bounds.minResult) {
            return 0;
        } else if (result > bounds.maxResult) {
            return 1E18;
        } else {
            return ((result - bounds.minResult)*1E18) / (bounds.maxResult - bounds.minResult);
        }
    }

    // Publication Only Functions
    // ***************************************************************************************
    function publish() public onlyPublication onlyStatus(Status.Active) {
        uint tokensCollected = _monksToken.balanceOf(address(this));
        if (tokensCollected <= 0) {
            revert MarketHasNoBets();
        }

        totalTokensCollected = tokensCollected;
        _status = Status.Published;
    }

    function buy(int sharesToBuy_, bool isYes_, uint maximumCost_, address buyer_) public onlyPublication {
        _buy(sharesToBuy_, isYes_, maximumCost_, buyer_);
    }

    function setPublishTimeAndTweetId(uint createdAt_, uint tweetId_) public onlyPublication onlyStatus(Status.Published) {
        require(publishTime == 0); // Publish time && TweetId is only set once.
        publishTime = createdAt_;
        tweetId = tweetId_;
    }

    /** @notice anyone can call resolve on the ´publication´ contract as long as block.timestamp > publishTime + accumulationTime
     *  this check is done on the publication.
     */
    function resolve(uint result_) public onlyPublication onlyStatus(Status.Published) {
        int _normalisedResult = int(_normaliseResult(result_));
        // The publication should have transfered the marketFunding to this contract before calling resolve.
        uint balance = _monksToken.balanceOf(address(this));
        if (balance - totalTokensCollected != funding * _payoutSplitBps.editors / 10000) {
            revert MarketIsNotFunded();
        }
        uint dept = uint(((q[0] - _initialQ[0]).mul(_normalisedResult) + (q[1] - _initialQ[1]).mul(1E18 - _normalisedResult)));
        assert(balance >= dept);
            
        if (balance > dept) {
            // If the market proceeds are more than enough to pay the editors, then we have ´exceeding´ which will be distributed amonsgt all market participants
            // according to the tokens spent. The distribution is made when ´redeemAll()´ is called.
            exceeding = balance - dept;
        }
        normalisedResult = _normalisedResult;
        _status = Status.Resolved;
    }

    // Moderator Only Functions
    // ***************************************************************************************
    function flag(bytes32 flagReasonHash_) public onlyModerator onlyStatus(Status.Active) {
        _status = Status.Flagged;
        _publication.emitOnPostFlagged(_postId, _msgSender(), flagReasonHash_);
    }


    // Author Only Functions
    // ***************************************************************************************
    function deletePost() public onlyStatus(Status.Active) {
        if (_msgSender() != post.author) {
            revert MarketUnauthorized();
        }
        require(_monksToken.balanceOf(address(this)) == 0);
        _status = Status.Deleted;
        _publication.emitOnPostDeleted(_postId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.4;

import "./PRBMath.sol";

/// @title PRBMathSD59x18
/// @author Paul Razvan Berg
/// @notice Smart contract library for advanced fixed-point math that works with int256 numbers considered to have 18
/// trailing decimals. We call this number representation signed 59.18-decimal fixed-point, since the numbers can have
/// a sign and there can be up to 59 digits in the integer part and up to 18 decimals in the fractional part. The numbers
/// are bound by the minimum and the maximum values permitted by the Solidity type int256.
library PRBMathSD59x18 {
    /// @dev log2(e) as a signed 59.18-decimal fixed-point number.
    int256 internal constant LOG2_E = 1_442695040888963407;

    /// @dev Half the SCALE number.
    int256 internal constant HALF_SCALE = 5e17;

    /// @dev The maximum value a signed 59.18-decimal fixed-point number can have.
    int256 internal constant MAX_SD59x18 =
    57896044618658097711785492504343953926634992332820282019728_792003956564819967;

    /// @dev The maximum whole value a signed 59.18-decimal fixed-point number can have.
    int256 internal constant MAX_WHOLE_SD59x18 =
    57896044618658097711785492504343953926634992332820282019728_000000000000000000;

    /// @dev The minimum value a signed 59.18-decimal fixed-point number can have.
    int256 internal constant MIN_SD59x18 =
    -57896044618658097711785492504343953926634992332820282019728_792003956564819968;

    /// @dev The minimum whole value a signed 59.18-decimal fixed-point number can have.
    int256 internal constant MIN_WHOLE_SD59x18 =
    -57896044618658097711785492504343953926634992332820282019728_000000000000000000;

    /// @dev How many trailing decimals can be represented.
    int256 internal constant SCALE = 1e18;

    /// INTERNAL FUNCTIONS ///

    /// @notice Calculate the absolute value of x.
    ///
    /// @dev Requirements:
    /// - x must be greater than MIN_SD59x18.
    ///
    /// @param x The number to calculate the absolute value for.
    /// @param result The absolute value of x.
    function abs(int256 x) internal pure returns (int256 result) {
    unchecked {
        if (x == MIN_SD59x18) {
            revert PRBMathSD59x18__AbsInputTooSmall();
        }
        result = x < 0 ? -x : x;
    }
    }

    /// @notice Calculates the arithmetic average of x and y, rounding down.
    /// @param x The first operand as a signed 59.18-decimal fixed-point number.
    /// @param y The second operand as a signed 59.18-decimal fixed-point number.
    /// @return result The arithmetic average as a signed 59.18-decimal fixed-point number.
    function avg(int256 x, int256 y) internal pure returns (int256 result) {
        // The operations can never overflow.
    unchecked {
        int256 sum = (x >> 1) + (y >> 1);
        if (sum < 0) {
            // If at least one of x and y is odd, we add 1 to the result. This is because shifting negative numbers to the
            // right rounds down to infinity.
            assembly {
                result := add(sum, and(or(x, y), 1))
            }
        } else {
            // If both x and y are odd, we add 1 to the result. This is because if both numbers are odd, the 0.5
            // remainder gets truncated twice.
            result = sum + (x & y & 1);
        }
    }
    }

    /// @notice Yields the least greatest signed 59.18 decimal fixed-point number greater than or equal to x.
    ///
    /// @dev Optimized for fractional value inputs, because for every whole value there are (1e18 - 1) fractional counterparts.
    /// See https://en.wikipedia.org/wiki/Floor_and_ceiling_functions.
    ///
    /// Requirements:
    /// - x must be less than or equal to MAX_WHOLE_SD59x18.
    ///
    /// @param x The signed 59.18-decimal fixed-point number to ceil.
    /// @param result The least integer greater than or equal to x, as a signed 58.18-decimal fixed-point number.
    function ceil(int256 x) internal pure returns (int256 result) {
        if (x > MAX_WHOLE_SD59x18) {
            revert PRBMathSD59x18__CeilOverflow(x);
        }
    unchecked {
        int256 remainder = x % SCALE;
        if (remainder == 0) {
            result = x;
        } else {
            // Solidity uses C fmod style, which returns a modulus with the same sign as x.
            result = x - remainder;
            if (x > 0) {
                result += SCALE;
            }
        }
    }
    }

    /// @notice Divides two signed 59.18-decimal fixed-point numbers, returning a new signed 59.18-decimal fixed-point number.
    ///
    /// @dev Variant of "mulDiv" that works with signed numbers. Works by computing the signs and the absolute values separately.
    ///
    /// Requirements:
    /// - All from "PRBMath.mulDiv".
    /// - None of the inputs can be MIN_SD59x18.
    /// - The denominator cannot be zero.
    /// - The result must fit within int256.
    ///
    /// Caveats:
    /// - All from "PRBMath.mulDiv".
    ///
    /// @param x The numerator as a signed 59.18-decimal fixed-point number.
    /// @param y The denominator as a signed 59.18-decimal fixed-point number.
    /// @param result The quotient as a signed 59.18-decimal fixed-point number.
    function div(int256 x, int256 y) internal pure returns (int256 result) {
        if (x == MIN_SD59x18 || y == MIN_SD59x18) {
            revert PRBMathSD59x18__DivInputTooSmall();
        }

        // Get hold of the absolute values of x and y.
        uint256 ax;
        uint256 ay;
    unchecked {
        ax = x < 0 ? uint256(-x) : uint256(x);
        ay = y < 0 ? uint256(-y) : uint256(y);
    }

        // Compute the absolute value of (x*SCALE)÷y. The result must fit within int256.
        uint256 rAbs = PRBMath.mulDiv(ax, uint256(SCALE), ay);
        if (rAbs > uint256(MAX_SD59x18)) {
            revert PRBMathSD59x18__DivOverflow(rAbs);
        }

        // Get the signs of x and y.
        uint256 sx;
        uint256 sy;
        assembly {
            sx := sgt(x, sub(0, 1))
            sy := sgt(y, sub(0, 1))
        }

        // XOR over sx and sy. This is basically checking whether the inputs have the same sign. If yes, the result
        // should be positive. Otherwise, it should be negative.
        result = sx ^ sy == 1 ? -int256(rAbs) : int256(rAbs);
    }

    /// @notice Returns Euler's number as a signed 59.18-decimal fixed-point number.
    /// @dev See https://en.wikipedia.org/wiki/E_(mathematical_constant).
    function e() internal pure returns (int256 result) {
        result = 2_718281828459045235;
    }

    /// @notice Calculates the natural exponent of x.
    ///
    /// @dev Based on the insight that e^x = 2^(x * log2(e)).
    ///
    /// Requirements:
    /// - All from "log2".
    /// - x must be less than 133.084258667509499441.
    ///
    /// Caveats:
    /// - All from "exp2".
    /// - For any x less than -41.446531673892822322, the result is zero.
    ///
    /// @param x The exponent as a signed 59.18-decimal fixed-point number.
    /// @return result The result as a signed 59.18-decimal fixed-point number.
    function exp(int256 x) internal pure returns (int256 result) {
        // Without this check, the value passed to "exp2" would be less than -59.794705707972522261.
        if (x < -41_446531673892822322) {
            return 0;
        }

        // Without this check, the value passed to "exp2" would be greater than 192.
        if (x >= 133_084258667509499441) {
            revert PRBMathSD59x18__ExpInputTooBig(x);
        }

        // Do the fixed-point multiplication inline to save gas.
    unchecked {
        int256 doubleScaleProduct = x * LOG2_E;
        result = exp2((doubleScaleProduct + HALF_SCALE) / SCALE);
    }
    }

    /// @notice Calculates the binary exponent of x using the binary fraction method.
    ///
    /// @dev See https://ethereum.stackexchange.com/q/79903/24693.
    ///
    /// Requirements:
    /// - x must be 192 or less.
    /// - The result must fit within MAX_SD59x18.
    ///
    /// Caveats:
    /// - For any x less than -59.794705707972522261, the result is zero.
    ///
    /// @param x The exponent as a signed 59.18-decimal fixed-point number.
    /// @return result The result as a signed 59.18-decimal fixed-point number.
    function exp2(int256 x) internal pure returns (int256 result) {
        // This works because 2^(-x) = 1/2^x.
        if (x < 0) {
            // 2^59.794705707972522262 is the maximum number whose inverse does not truncate down to zero.
            if (x < -59_794705707972522261) {
                return 0;
            }

            // Do the fixed-point inversion inline to save gas. The numerator is SCALE * SCALE.
        unchecked {
            result = 1e36 / exp2(-x);
        }
        } else {
            // 2^192 doesn't fit within the 192.64-bit format used internally in this function.
            if (x >= 192e18) {
                revert PRBMathSD59x18__Exp2InputTooBig(x);
            }

        unchecked {
            // Convert x to the 192.64-bit fixed-point format.
            uint256 x192x64 = (uint256(x) << 64) / uint256(SCALE);

            // Safe to convert the result to int256 directly because the maximum input allowed is 192.
            result = int256(PRBMath.exp2(x192x64));
        }
        }
    }

    /// @notice Yields the greatest signed 59.18 decimal fixed-point number less than or equal to x.
    ///
    /// @dev Optimized for fractional value inputs, because for every whole value there are (1e18 - 1) fractional counterparts.
    /// See https://en.wikipedia.org/wiki/Floor_and_ceiling_functions.
    ///
    /// Requirements:
    /// - x must be greater than or equal to MIN_WHOLE_SD59x18.
    ///
    /// @param x The signed 59.18-decimal fixed-point number to floor.
    /// @param result The greatest integer less than or equal to x, as a signed 58.18-decimal fixed-point number.
    function floor(int256 x) internal pure returns (int256 result) {
        if (x < MIN_WHOLE_SD59x18) {
            revert PRBMathSD59x18__FloorUnderflow(x);
        }
    unchecked {
        int256 remainder = x % SCALE;
        if (remainder == 0) {
            result = x;
        } else {
            // Solidity uses C fmod style, which returns a modulus with the same sign as x.
            result = x - remainder;
            if (x < 0) {
                result -= SCALE;
            }
        }
    }
    }

    /// @notice Yields the excess beyond the floor of x for positive numbers and the part of the number to the right
    /// of the radix point for negative numbers.
    /// @dev Based on the odd function definition. https://en.wikipedia.org/wiki/Fractional_part
    /// @param x The signed 59.18-decimal fixed-point number to get the fractional part of.
    /// @param result The fractional part of x as a signed 59.18-decimal fixed-point number.
    function frac(int256 x) internal pure returns (int256 result) {
    unchecked {
        result = x % SCALE;
    }
    }

    /// @notice Converts a number from basic integer form to signed 59.18-decimal fixed-point representation.
    ///
    /// @dev Requirements:
    /// - x must be greater than or equal to MIN_SD59x18 divided by SCALE.
    /// - x must be less than or equal to MAX_SD59x18 divided by SCALE.
    ///
    /// @param x The basic integer to convert.
    /// @param result The same number in signed 59.18-decimal fixed-point representation.
    function fromInt(int256 x) internal pure returns (int256 result) {
    unchecked {
        if (x < MIN_SD59x18 / SCALE) {
            revert PRBMathSD59x18__FromIntUnderflow(x);
        }
        if (x > MAX_SD59x18 / SCALE) {
            revert PRBMathSD59x18__FromIntOverflow(x);
        }
        result = x * SCALE;
    }
    }

    /// @notice Calculates geometric mean of x and y, i.e. sqrt(x * y), rounding down.
    ///
    /// @dev Requirements:
    /// - x * y must fit within MAX_SD59x18, lest it overflows.
    /// - x * y cannot be negative.
    ///
    /// @param x The first operand as a signed 59.18-decimal fixed-point number.
    /// @param y The second operand as a signed 59.18-decimal fixed-point number.
    /// @return result The result as a signed 59.18-decimal fixed-point number.
    function gm(int256 x, int256 y) internal pure returns (int256 result) {
        if (x == 0) {
            return 0;
        }

    unchecked {
        // Checking for overflow this way is faster than letting Solidity do it.
        int256 xy = x * y;
        if (xy / x != y) {
            revert PRBMathSD59x18__GmOverflow(x, y);
        }

        // The product cannot be negative.
        if (xy < 0) {
            revert PRBMathSD59x18__GmNegativeProduct(x, y);
        }

        // We don't need to multiply by the SCALE here because the x*y product had already picked up a factor of SCALE
        // during multiplication. See the comments within the "sqrt" function.
        result = int256(PRBMath.sqrt(uint256(xy)));
    }
    }

    /// @notice Calculates 1 / x, rounding toward zero.
    ///
    /// @dev Requirements:
    /// - x cannot be zero.
    ///
    /// @param x The signed 59.18-decimal fixed-point number for which to calculate the inverse.
    /// @return result The inverse as a signed 59.18-decimal fixed-point number.
    function inv(int256 x) internal pure returns (int256 result) {
    unchecked {
        // 1e36 is SCALE * SCALE.
        result = 1e36 / x;
    }
    }

    /// @notice Calculates the natural logarithm of x.
    ///
    /// @dev Based on the insight that ln(x) = log2(x) / log2(e).
    ///
    /// Requirements:
    /// - All from "log2".
    ///
    /// Caveats:
    /// - All from "log2".
    /// - This doesn't return exactly 1 for 2718281828459045235, for that we would need more fine-grained precision.
    ///
    /// @param x The signed 59.18-decimal fixed-point number for which to calculate the natural logarithm.
    /// @return result The natural logarithm as a signed 59.18-decimal fixed-point number.
    function ln(int256 x) internal pure returns (int256 result) {
        // Do the fixed-point multiplication inline to save gas. This is overflow-safe because the maximum value that log2(x)
        // can return is 195205294292027477728.
    unchecked {
        result = (log2(x) * SCALE) / LOG2_E;
    }
    }

    /// @notice Calculates the common logarithm of x.
    ///
    /// @dev First checks if x is an exact power of ten and it stops if yes. If it's not, calculates the common
    /// logarithm based on the insight that log10(x) = log2(x) / log2(10).
    ///
    /// Requirements:
    /// - All from "log2".
    ///
    /// Caveats:
    /// - All from "log2".
    ///
    /// @param x The signed 59.18-decimal fixed-point number for which to calculate the common logarithm.
    /// @return result The common logarithm as a signed 59.18-decimal fixed-point number.
    function log10(int256 x) internal pure returns (int256 result) {
        if (x <= 0) {
            revert PRBMathSD59x18__LogInputTooSmall(x);
        }

        // Note that the "mul" in this block is the assembly mul operation, not the "mul" function defined in this contract.
        // prettier-ignore
        assembly {
            switch x
            case 1 { result := mul(SCALE, sub(0, 18)) }
            case 10 { result := mul(SCALE, sub(1, 18)) }
            case 100 { result := mul(SCALE, sub(2, 18)) }
            case 1000 { result := mul(SCALE, sub(3, 18)) }
            case 10000 { result := mul(SCALE, sub(4, 18)) }
            case 100000 { result := mul(SCALE, sub(5, 18)) }
            case 1000000 { result := mul(SCALE, sub(6, 18)) }
            case 10000000 { result := mul(SCALE, sub(7, 18)) }
            case 100000000 { result := mul(SCALE, sub(8, 18)) }
            case 1000000000 { result := mul(SCALE, sub(9, 18)) }
            case 10000000000 { result := mul(SCALE, sub(10, 18)) }
            case 100000000000 { result := mul(SCALE, sub(11, 18)) }
            case 1000000000000 { result := mul(SCALE, sub(12, 18)) }
            case 10000000000000 { result := mul(SCALE, sub(13, 18)) }
            case 100000000000000 { result := mul(SCALE, sub(14, 18)) }
            case 1000000000000000 { result := mul(SCALE, sub(15, 18)) }
            case 10000000000000000 { result := mul(SCALE, sub(16, 18)) }
            case 100000000000000000 { result := mul(SCALE, sub(17, 18)) }
            case 1000000000000000000 { result := 0 }
            case 10000000000000000000 { result := SCALE }
            case 100000000000000000000 { result := mul(SCALE, 2) }
            case 1000000000000000000000 { result := mul(SCALE, 3) }
            case 10000000000000000000000 { result := mul(SCALE, 4) }
            case 100000000000000000000000 { result := mul(SCALE, 5) }
            case 1000000000000000000000000 { result := mul(SCALE, 6) }
            case 10000000000000000000000000 { result := mul(SCALE, 7) }
            case 100000000000000000000000000 { result := mul(SCALE, 8) }
            case 1000000000000000000000000000 { result := mul(SCALE, 9) }
            case 10000000000000000000000000000 { result := mul(SCALE, 10) }
            case 100000000000000000000000000000 { result := mul(SCALE, 11) }
            case 1000000000000000000000000000000 { result := mul(SCALE, 12) }
            case 10000000000000000000000000000000 { result := mul(SCALE, 13) }
            case 100000000000000000000000000000000 { result := mul(SCALE, 14) }
            case 1000000000000000000000000000000000 { result := mul(SCALE, 15) }
            case 10000000000000000000000000000000000 { result := mul(SCALE, 16) }
            case 100000000000000000000000000000000000 { result := mul(SCALE, 17) }
            case 1000000000000000000000000000000000000 { result := mul(SCALE, 18) }
            case 10000000000000000000000000000000000000 { result := mul(SCALE, 19) }
            case 100000000000000000000000000000000000000 { result := mul(SCALE, 20) }
            case 1000000000000000000000000000000000000000 { result := mul(SCALE, 21) }
            case 10000000000000000000000000000000000000000 { result := mul(SCALE, 22) }
            case 100000000000000000000000000000000000000000 { result := mul(SCALE, 23) }
            case 1000000000000000000000000000000000000000000 { result := mul(SCALE, 24) }
            case 10000000000000000000000000000000000000000000 { result := mul(SCALE, 25) }
            case 100000000000000000000000000000000000000000000 { result := mul(SCALE, 26) }
            case 1000000000000000000000000000000000000000000000 { result := mul(SCALE, 27) }
            case 10000000000000000000000000000000000000000000000 { result := mul(SCALE, 28) }
            case 100000000000000000000000000000000000000000000000 { result := mul(SCALE, 29) }
            case 1000000000000000000000000000000000000000000000000 { result := mul(SCALE, 30) }
            case 10000000000000000000000000000000000000000000000000 { result := mul(SCALE, 31) }
            case 100000000000000000000000000000000000000000000000000 { result := mul(SCALE, 32) }
            case 1000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 33) }
            case 10000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 34) }
            case 100000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 35) }
            case 1000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 36) }
            case 10000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 37) }
            case 100000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 38) }
            case 1000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 39) }
            case 10000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 40) }
            case 100000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 41) }
            case 1000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 42) }
            case 10000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 43) }
            case 100000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 44) }
            case 1000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 45) }
            case 10000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 46) }
            case 100000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 47) }
            case 1000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 48) }
            case 10000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 49) }
            case 100000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 50) }
            case 1000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 51) }
            case 10000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 52) }
            case 100000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 53) }
            case 1000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 54) }
            case 10000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 55) }
            case 100000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 56) }
            case 1000000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 57) }
            case 10000000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 58) }
            default {
                result := MAX_SD59x18
            }
        }

        if (result == MAX_SD59x18) {
            // Do the fixed-point division inline to save gas. The denominator is log2(10).
        unchecked {
            result = (log2(x) * SCALE) / 3_321928094887362347;
        }
        }
    }

    /// @notice Calculates the binary logarithm of x.
    ///
    /// @dev Based on the iterative approximation algorithm.
    /// https://en.wikipedia.org/wiki/Binary_logarithm#Iterative_approximation
    ///
    /// Requirements:
    /// - x must be greater than zero.
    ///
    /// Caveats:
    /// - The results are not perfectly accurate to the last decimal, due to the lossy precision of the iterative approximation.
    ///
    /// @param x The signed 59.18-decimal fixed-point number for which to calculate the binary logarithm.
    /// @return result The binary logarithm as a signed 59.18-decimal fixed-point number.
    function log2(int256 x) internal pure returns (int256 result) {
        if (x <= 0) {
            revert PRBMathSD59x18__LogInputTooSmall(x);
        }
    unchecked {
        // This works because log2(x) = -log2(1/x).
        int256 sign;
        if (x >= SCALE) {
            sign = 1;
        } else {
            sign = -1;
            // Do the fixed-point inversion inline to save gas. The numerator is SCALE * SCALE.
            assembly {
                x := div(1000000000000000000000000000000000000, x)
            }
        }

        // Calculate the integer part of the logarithm and add it to the result and finally calculate y = x * 2^(-n).
        uint256 n = PRBMath.mostSignificantBit(uint256(x / SCALE));

        // The integer part of the logarithm as a signed 59.18-decimal fixed-point number. The operation can't overflow
        // because n is maximum 255, SCALE is 1e18 and sign is either 1 or -1.
        result = int256(n) * SCALE;

        // This is y = x * 2^(-n).
        int256 y = x >> n;

        // If y = 1, the fractional part is zero.
        if (y == SCALE) {
            return result * sign;
        }

        // Calculate the fractional part via the iterative approximation.
        // The "delta >>= 1" part is equivalent to "delta /= 2", but shifting bits is faster.
        for (int256 delta = int256(HALF_SCALE); delta > 0; delta >>= 1) {
            y = (y * y) / SCALE;

            // Is y^2 > 2 and so in the range [2,4)?
            if (y >= 2 * SCALE) {
                // Add the 2^(-m) factor to the logarithm.
                result += delta;

                // Corresponds to z/2 on Wikipedia.
                y >>= 1;
            }
        }
        result *= sign;
    }
    }

    /// @notice Multiplies two signed 59.18-decimal fixed-point numbers together, returning a new signed 59.18-decimal
    /// fixed-point number.
    ///
    /// @dev Variant of "mulDiv" that works with signed numbers and employs constant folding, i.e. the denominator is
    /// always 1e18.
    ///
    /// Requirements:
    /// - All from "PRBMath.mulDivFixedPoint".
    /// - None of the inputs can be MIN_SD59x18
    /// - The result must fit within MAX_SD59x18.
    ///
    /// Caveats:
    /// - The body is purposely left uncommented; see the NatSpec comments in "PRBMath.mulDiv" to understand how this works.
    ///
    /// @param x The multiplicand as a signed 59.18-decimal fixed-point number.
    /// @param y The multiplier as a signed 59.18-decimal fixed-point number.
    /// @return result The product as a signed 59.18-decimal fixed-point number.
    function mul(int256 x, int256 y) internal pure returns (int256 result) {
        if (x == MIN_SD59x18 || y == MIN_SD59x18) {
            revert PRBMathSD59x18__MulInputTooSmall();
        }

    unchecked {
        uint256 ax;
        uint256 ay;
        ax = x < 0 ? uint256(-x) : uint256(x);
        ay = y < 0 ? uint256(-y) : uint256(y);

        uint256 rAbs = PRBMath.mulDivFixedPoint(ax, ay);
        if (rAbs > uint256(MAX_SD59x18)) {
            revert PRBMathSD59x18__MulOverflow(rAbs);
        }

        uint256 sx;
        uint256 sy;
        assembly {
            sx := sgt(x, sub(0, 1))
            sy := sgt(y, sub(0, 1))
        }
        result = sx ^ sy == 1 ? -int256(rAbs) : int256(rAbs);
    }
    }

    /// @notice Returns PI as a signed 59.18-decimal fixed-point number.
    function pi() internal pure returns (int256 result) {
        result = 3_141592653589793238;
    }

    /// @notice Raises x to the power of y.
    ///
    /// @dev Based on the insight that x^y = 2^(log2(x) * y).
    ///
    /// Requirements:
    /// - All from "exp2", "log2" and "mul".
    /// - z cannot be zero.
    ///
    /// Caveats:
    /// - All from "exp2", "log2" and "mul".
    /// - Assumes 0^0 is 1.
    ///
    /// @param x Number to raise to given power y, as a signed 59.18-decimal fixed-point number.
    /// @param y Exponent to raise x to, as a signed 59.18-decimal fixed-point number.
    /// @return result x raised to power y, as a signed 59.18-decimal fixed-point number.
    function pow(int256 x, int256 y) internal pure returns (int256 result) {
        if (x == 0) {
            result = y == 0 ? SCALE : int256(0);
        } else {
            result = exp2(mul(log2(x), y));
        }
    }

    /// @notice Raises x (signed 59.18-decimal fixed-point number) to the power of y (basic unsigned integer) using the
    /// famous algorithm "exponentiation by squaring".
    ///
    /// @dev See https://en.wikipedia.org/wiki/Exponentiation_by_squaring
    ///
    /// Requirements:
    /// - All from "abs" and "PRBMath.mulDivFixedPoint".
    /// - The result must fit within MAX_SD59x18.
    ///
    /// Caveats:
    /// - All from "PRBMath.mulDivFixedPoint".
    /// - Assumes 0^0 is 1.
    ///
    /// @param x The base as a signed 59.18-decimal fixed-point number.
    /// @param y The exponent as an uint256.
    /// @return result The result as a signed 59.18-decimal fixed-point number.
    function powu(int256 x, uint256 y) internal pure returns (int256 result) {
        uint256 xAbs = uint256(abs(x));

        // Calculate the first iteration of the loop in advance.
        uint256 rAbs = y & 1 > 0 ? xAbs : uint256(SCALE);

        // Equivalent to "for(y /= 2; y > 0; y /= 2)" but faster.
        uint256 yAux = y;
        for (yAux >>= 1; yAux > 0; yAux >>= 1) {
            xAbs = PRBMath.mulDivFixedPoint(xAbs, xAbs);

            // Equivalent to "y % 2 == 1" but faster.
            if (yAux & 1 > 0) {
                rAbs = PRBMath.mulDivFixedPoint(rAbs, xAbs);
            }
        }

        // The result must fit within the 59.18-decimal fixed-point representation.
        if (rAbs > uint256(MAX_SD59x18)) {
            revert PRBMathSD59x18__PowuOverflow(rAbs);
        }

        // Is the base negative and the exponent an odd number?
        bool isNegative = x < 0 && y & 1 == 1;
        result = isNegative ? -int256(rAbs) : int256(rAbs);
    }

    /// @notice Returns 1 as a signed 59.18-decimal fixed-point number.
    function scale() internal pure returns (int256 result) {
        result = SCALE;
    }

    /// @notice Calculates the square root of x, rounding down.
    /// @dev Uses the Babylonian method https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method.
    ///
    /// Requirements:
    /// - x cannot be negative.
    /// - x must be less than MAX_SD59x18 / SCALE.
    ///
    /// @param x The signed 59.18-decimal fixed-point number for which to calculate the square root.
    /// @return result The result as a signed 59.18-decimal fixed-point .
    function sqrt(int256 x) internal pure returns (int256 result) {
    unchecked {
        if (x < 0) {
            revert PRBMathSD59x18__SqrtNegativeInput(x);
        }
        if (x > MAX_SD59x18 / SCALE) {
            revert PRBMathSD59x18__SqrtOverflow(x);
        }
        // Multiply x by the SCALE to account for the factor of SCALE that is picked up when multiplying two signed
        // 59.18-decimal fixed-point numbers together (in this case, those two numbers are both the square root).
        result = int256(PRBMath.sqrt(uint256(x * SCALE)));
    }
    }

    /// @notice Converts a signed 59.18-decimal fixed-point number to basic integer form, rounding down in the process.
    /// @param x The signed 59.18-decimal fixed-point number to convert.
    /// @return result The same number in basic integer form.
    function toInt(int256 x) internal pure returns (int256 result) {
    unchecked {
        result = x / SCALE;
    }
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.17;

library MonksTypes {
    bytes32 constant MODERATOR_ROLE = keccak256('MODERATOR');

    struct Post {
        uint8 postType;
        address author;
        uint timestamp;
    }

    struct ResultBounds {
        uint128 minResult;
        uint128 maxResult;
    }

    struct PayoutSplitBps {
        uint16 coreTeam;
        uint16 writer;
        uint16 editors;
        uint16 moderators;
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.17;

import "../core/MonksTypes.sol";
import "./IMonksERC20.sol";
import "@openzeppelin/contracts/access/IAccessControl.sol";


interface IMonksPublication is IAccessControl {
    // Predictive Markets will use this info when initialise
    function postExpirationPeriod() external view returns(uint);
    function issuancePerPostType(uint postType) external view returns(uint128);
    function payoutSplitBps() external view returns(uint16 coreTeam, uint16 writer, uint16 editors, uint16 moderators);
    function monksERC20() external view returns(IMonksERC20);
    function alpha() external view returns(int);
    function bounds() external view returns(uint128 minResult, uint128 maxResult);
    function initialQs(uint postType, uint isYes) external view returns(int);
    function scores(address monk, uint index) external view returns(uint);
    function totalScore(address monk) external view returns(uint);
    

    function init(uint64 publicationId_, uint postExpirationPeriod_, address marketTemplate_,
                  address token_, MonksTypes.PayoutSplitBps memory payoutSplitBps_, address publicationAdmin_,
                  address coreTeam_, address moderationTeam_, address postSigner_, address twitterRelayer_, MonksTypes.ResultBounds memory bounds_) external;


    // market functions that trigger events
    function emitOnPostFlagged(bytes20 postId_, address flaggedBy_, bytes32 flagReason_) external;
    function emitOnPostDeleted(bytes20 postId_) external;
    function emitOnSharesBought(bytes20 postId_, address buyer_, uint sharesBought_, uint cost_, bool isYes_) external;
    function emitOnTokensRedeemed(bytes20 postId_, address redeemer_, uint tokensReceived_, uint tokensBetted_) external;
    function emitOnRefundTaken(bytes20 postId_, address to_, uint value_) external;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.17;

import "../core/MonksTypes.sol";
import "./IMonksPublication.sol";

error MarketExceededMaxCost();
error InvalidMarketStatusForAction();

interface IMonksMarket {
    enum Status {Active, Expired, Flagged, Deleted, Published, Resolved}

    function init(bytes20 postId_, MonksTypes.Post memory post_) external;
    function postTypeAndAuthor() external view returns (uint8, address);
    function publish() external;
    function setPublishTimeAndTweetId(uint createdAt_, uint tweetId_) external;
    function status() external view returns (Status);

    function resolve(uint result_) external;
    function tweetId() external returns (uint);
    function publishTime() external returns (uint);
    function funding() external returns (uint);
    function payoutSplitBps() external returns (MonksTypes.PayoutSplitBps memory);

    function buy(int sharesToBuy_, bool isYes_, uint amountToPay_, address buyer_) external;
    function deltaPrice(int shares, bool isYes) external view returns (uint);
}

// SPDX-License-Identifier: MIT
// solhint-disable no-inline-assembly
pragma solidity >=0.6.9;

import "./interfaces/IERC2771Recipient.sol";

/**
 * @title The ERC-2771 Recipient Base Abstract Class - Implementation
 *
 * @notice Note that this contract was called `BaseRelayRecipient` in the previous revision of the GSN.
 *
 * @notice A base contract to be inherited by any contract that want to receive relayed transactions.
 *
 * @notice A subclass must use `_msgSender()` instead of `msg.sender`.
 */
abstract contract ERC2771Recipient is IERC2771Recipient {

    /*
     * Forwarder singleton we accept calls from
     */
    address private _trustedForwarder;

    /**
     * :warning: **Warning** :warning: The Forwarder can have a full control over your Recipient. Only trust verified Forwarder.
     * @notice Method is not a required method to allow Recipients to trust multiple Forwarders. Not recommended yet.
     * @return forwarder The address of the Forwarder contract that is being used.
     */
    function getTrustedForwarder() public virtual view returns (address forwarder){
        return _trustedForwarder;
    }

    function _setTrustedForwarder(address _forwarder) internal {
        _trustedForwarder = _forwarder;
    }

    /// @inheritdoc IERC2771Recipient
    function isTrustedForwarder(address forwarder) public virtual override view returns(bool) {
        return forwarder == _trustedForwarder;
    }

    /// @inheritdoc IERC2771Recipient
    function _msgSender() internal override virtual view returns (address ret) {
        if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
            // At this point we know that the sender is a trusted forwarder,
            // so we trust that the last bytes of msg.data are the verified sender address.
            // extract sender address from the end of msg.data
            assembly {
                ret := shr(96,calldataload(sub(calldatasize(),20)))
            }
        } else {
            ret = msg.sender;
        }
    }

    /// @inheritdoc IERC2771Recipient
    function _msgData() internal override virtual view returns (bytes calldata ret) {
        if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
            return msg.data[0:msg.data.length-20];
        } else {
            return msg.data;
        }
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.4;

/// @notice Emitted when the result overflows uint256.
    error PRBMath__MulDivFixedPointOverflow(uint256 prod1);

/// @notice Emitted when the result overflows uint256.
    error PRBMath__MulDivOverflow(uint256 prod1, uint256 denominator);

/// @notice Emitted when one of the inputs is type(int256).min.
    error PRBMath__MulDivSignedInputTooSmall();

/// @notice Emitted when the intermediary absolute result overflows int256.
    error PRBMath__MulDivSignedOverflow(uint256 rAbs);

/// @notice Emitted when the input is MIN_SD59x18.
    error PRBMathSD59x18__AbsInputTooSmall();

/// @notice Emitted when ceiling a number overflows SD59x18.
    error PRBMathSD59x18__CeilOverflow(int256 x);

/// @notice Emitted when one of the inputs is MIN_SD59x18.
    error PRBMathSD59x18__DivInputTooSmall();

/// @notice Emitted when one of the intermediary unsigned results overflows SD59x18.
    error PRBMathSD59x18__DivOverflow(uint256 rAbs);

/// @notice Emitted when the input is greater than 133.084258667509499441.
    error PRBMathSD59x18__ExpInputTooBig(int256 x);

/// @notice Emitted when the input is greater than 192.
    error PRBMathSD59x18__Exp2InputTooBig(int256 x);

/// @notice Emitted when flooring a number underflows SD59x18.
    error PRBMathSD59x18__FloorUnderflow(int256 x);

/// @notice Emitted when converting a basic integer to the fixed-point format overflows SD59x18.
    error PRBMathSD59x18__FromIntOverflow(int256 x);

/// @notice Emitted when converting a basic integer to the fixed-point format underflows SD59x18.
    error PRBMathSD59x18__FromIntUnderflow(int256 x);

/// @notice Emitted when the product of the inputs is negative.
    error PRBMathSD59x18__GmNegativeProduct(int256 x, int256 y);

/// @notice Emitted when multiplying the inputs overflows SD59x18.
    error PRBMathSD59x18__GmOverflow(int256 x, int256 y);

/// @notice Emitted when the input is less than or equal to zero.
    error PRBMathSD59x18__LogInputTooSmall(int256 x);

/// @notice Emitted when one of the inputs is MIN_SD59x18.
    error PRBMathSD59x18__MulInputTooSmall();

/// @notice Emitted when the intermediary absolute result overflows SD59x18.
    error PRBMathSD59x18__MulOverflow(uint256 rAbs);

/// @notice Emitted when the intermediary absolute result overflows SD59x18.
    error PRBMathSD59x18__PowuOverflow(uint256 rAbs);

/// @notice Emitted when the input is negative.
    error PRBMathSD59x18__SqrtNegativeInput(int256 x);

/// @notice Emitted when the calculating the square root overflows SD59x18.
    error PRBMathSD59x18__SqrtOverflow(int256 x);

/// @notice Emitted when addition overflows UD60x18.
    error PRBMathUD60x18__AddOverflow(uint256 x, uint256 y);

/// @notice Emitted when ceiling a number overflows UD60x18.
    error PRBMathUD60x18__CeilOverflow(uint256 x);

/// @notice Emitted when the input is greater than 133.084258667509499441.
    error PRBMathUD60x18__ExpInputTooBig(uint256 x);

/// @notice Emitted when the input is greater than 192.
    error PRBMathUD60x18__Exp2InputTooBig(uint256 x);

/// @notice Emitted when converting a basic integer to the fixed-point format format overflows UD60x18.
    error PRBMathUD60x18__FromUintOverflow(uint256 x);

/// @notice Emitted when multiplying the inputs overflows UD60x18.
    error PRBMathUD60x18__GmOverflow(uint256 x, uint256 y);

/// @notice Emitted when the input is less than 1.
    error PRBMathUD60x18__LogInputTooSmall(uint256 x);

/// @notice Emitted when the calculating the square root overflows UD60x18.
    error PRBMathUD60x18__SqrtOverflow(uint256 x);

/// @notice Emitted when subtraction underflows UD60x18.
    error PRBMathUD60x18__SubUnderflow(uint256 x, uint256 y);

/// @dev Common mathematical functions used in both PRBMathSD59x18 and PRBMathUD60x18. Note that this shared library
/// does not always assume the signed 59.18-decimal fixed-point or the unsigned 60.18-decimal fixed-point
/// representation. When it does not, it is explicitly mentioned in the NatSpec documentation.
library PRBMath {
    /// STRUCTS ///

    struct SD59x18 {
        int256 value;
    }

    struct UD60x18 {
        uint256 value;
    }

    /// STORAGE ///

    /// @dev How many trailing decimals can be represented.
    uint256 internal constant SCALE = 1e18;

    /// @dev Largest power of two divisor of SCALE.
    uint256 internal constant SCALE_LPOTD = 262144;

    /// @dev SCALE inverted mod 2^256.
    uint256 internal constant SCALE_INVERSE =
    78156646155174841979727994598816262306175212592076161876661_508869554232690281;

    /// FUNCTIONS ///

    /// @notice Calculates the binary exponent of x using the binary fraction method.
    /// @dev Has to use 192.64-bit fixed-point numbers.
    /// See https://ethereum.stackexchange.com/a/96594/24693.
    /// @param x The exponent as an unsigned 192.64-bit fixed-point number.
    /// @return result The result as an unsigned 60.18-decimal fixed-point number.
    function exp2(uint256 x) internal pure returns (uint256 result) {
    unchecked {
        // Start from 0.5 in the 192.64-bit fixed-point format.
        result = 0x800000000000000000000000000000000000000000000000;

        // Multiply the result by root(2, 2^-i) when the bit at position i is 1. None of the intermediary results overflows
        // because the initial result is 2^191 and all magic factors are less than 2^65.
        if (x & 0x8000000000000000 > 0) {
            result = (result * 0x16A09E667F3BCC909) >> 64;
        }
        if (x & 0x4000000000000000 > 0) {
            result = (result * 0x1306FE0A31B7152DF) >> 64;
        }
        if (x & 0x2000000000000000 > 0) {
            result = (result * 0x1172B83C7D517ADCE) >> 64;
        }
        if (x & 0x1000000000000000 > 0) {
            result = (result * 0x10B5586CF9890F62A) >> 64;
        }
        if (x & 0x800000000000000 > 0) {
            result = (result * 0x1059B0D31585743AE) >> 64;
        }
        if (x & 0x400000000000000 > 0) {
            result = (result * 0x102C9A3E778060EE7) >> 64;
        }
        if (x & 0x200000000000000 > 0) {
            result = (result * 0x10163DA9FB33356D8) >> 64;
        }
        if (x & 0x100000000000000 > 0) {
            result = (result * 0x100B1AFA5ABCBED61) >> 64;
        }
        if (x & 0x80000000000000 > 0) {
            result = (result * 0x10058C86DA1C09EA2) >> 64;
        }
        if (x & 0x40000000000000 > 0) {
            result = (result * 0x1002C605E2E8CEC50) >> 64;
        }
        if (x & 0x20000000000000 > 0) {
            result = (result * 0x100162F3904051FA1) >> 64;
        }
        if (x & 0x10000000000000 > 0) {
            result = (result * 0x1000B175EFFDC76BA) >> 64;
        }
        if (x & 0x8000000000000 > 0) {
            result = (result * 0x100058BA01FB9F96D) >> 64;
        }
        if (x & 0x4000000000000 > 0) {
            result = (result * 0x10002C5CC37DA9492) >> 64;
        }
        if (x & 0x2000000000000 > 0) {
            result = (result * 0x1000162E525EE0547) >> 64;
        }
        if (x & 0x1000000000000 > 0) {
            result = (result * 0x10000B17255775C04) >> 64;
        }
        if (x & 0x800000000000 > 0) {
            result = (result * 0x1000058B91B5BC9AE) >> 64;
        }
        if (x & 0x400000000000 > 0) {
            result = (result * 0x100002C5C89D5EC6D) >> 64;
        }
        if (x & 0x200000000000 > 0) {
            result = (result * 0x10000162E43F4F831) >> 64;
        }
        if (x & 0x100000000000 > 0) {
            result = (result * 0x100000B1721BCFC9A) >> 64;
        }
        if (x & 0x80000000000 > 0) {
            result = (result * 0x10000058B90CF1E6E) >> 64;
        }
        if (x & 0x40000000000 > 0) {
            result = (result * 0x1000002C5C863B73F) >> 64;
        }
        if (x & 0x20000000000 > 0) {
            result = (result * 0x100000162E430E5A2) >> 64;
        }
        if (x & 0x10000000000 > 0) {
            result = (result * 0x1000000B172183551) >> 64;
        }
        if (x & 0x8000000000 > 0) {
            result = (result * 0x100000058B90C0B49) >> 64;
        }
        if (x & 0x4000000000 > 0) {
            result = (result * 0x10000002C5C8601CC) >> 64;
        }
        if (x & 0x2000000000 > 0) {
            result = (result * 0x1000000162E42FFF0) >> 64;
        }
        if (x & 0x1000000000 > 0) {
            result = (result * 0x10000000B17217FBB) >> 64;
        }
        if (x & 0x800000000 > 0) {
            result = (result * 0x1000000058B90BFCE) >> 64;
        }
        if (x & 0x400000000 > 0) {
            result = (result * 0x100000002C5C85FE3) >> 64;
        }
        if (x & 0x200000000 > 0) {
            result = (result * 0x10000000162E42FF1) >> 64;
        }
        if (x & 0x100000000 > 0) {
            result = (result * 0x100000000B17217F8) >> 64;
        }
        if (x & 0x80000000 > 0) {
            result = (result * 0x10000000058B90BFC) >> 64;
        }
        if (x & 0x40000000 > 0) {
            result = (result * 0x1000000002C5C85FE) >> 64;
        }
        if (x & 0x20000000 > 0) {
            result = (result * 0x100000000162E42FF) >> 64;
        }
        if (x & 0x10000000 > 0) {
            result = (result * 0x1000000000B17217F) >> 64;
        }
        if (x & 0x8000000 > 0) {
            result = (result * 0x100000000058B90C0) >> 64;
        }
        if (x & 0x4000000 > 0) {
            result = (result * 0x10000000002C5C860) >> 64;
        }
        if (x & 0x2000000 > 0) {
            result = (result * 0x1000000000162E430) >> 64;
        }
        if (x & 0x1000000 > 0) {
            result = (result * 0x10000000000B17218) >> 64;
        }
        if (x & 0x800000 > 0) {
            result = (result * 0x1000000000058B90C) >> 64;
        }
        if (x & 0x400000 > 0) {
            result = (result * 0x100000000002C5C86) >> 64;
        }
        if (x & 0x200000 > 0) {
            result = (result * 0x10000000000162E43) >> 64;
        }
        if (x & 0x100000 > 0) {
            result = (result * 0x100000000000B1721) >> 64;
        }
        if (x & 0x80000 > 0) {
            result = (result * 0x10000000000058B91) >> 64;
        }
        if (x & 0x40000 > 0) {
            result = (result * 0x1000000000002C5C8) >> 64;
        }
        if (x & 0x20000 > 0) {
            result = (result * 0x100000000000162E4) >> 64;
        }
        if (x & 0x10000 > 0) {
            result = (result * 0x1000000000000B172) >> 64;
        }
        if (x & 0x8000 > 0) {
            result = (result * 0x100000000000058B9) >> 64;
        }
        if (x & 0x4000 > 0) {
            result = (result * 0x10000000000002C5D) >> 64;
        }
        if (x & 0x2000 > 0) {
            result = (result * 0x1000000000000162E) >> 64;
        }
        if (x & 0x1000 > 0) {
            result = (result * 0x10000000000000B17) >> 64;
        }
        if (x & 0x800 > 0) {
            result = (result * 0x1000000000000058C) >> 64;
        }
        if (x & 0x400 > 0) {
            result = (result * 0x100000000000002C6) >> 64;
        }
        if (x & 0x200 > 0) {
            result = (result * 0x10000000000000163) >> 64;
        }
        if (x & 0x100 > 0) {
            result = (result * 0x100000000000000B1) >> 64;
        }
        if (x & 0x80 > 0) {
            result = (result * 0x10000000000000059) >> 64;
        }
        if (x & 0x40 > 0) {
            result = (result * 0x1000000000000002C) >> 64;
        }
        if (x & 0x20 > 0) {
            result = (result * 0x10000000000000016) >> 64;
        }
        if (x & 0x10 > 0) {
            result = (result * 0x1000000000000000B) >> 64;
        }
        if (x & 0x8 > 0) {
            result = (result * 0x10000000000000006) >> 64;
        }
        if (x & 0x4 > 0) {
            result = (result * 0x10000000000000003) >> 64;
        }
        if (x & 0x2 > 0) {
            result = (result * 0x10000000000000001) >> 64;
        }
        if (x & 0x1 > 0) {
            result = (result * 0x10000000000000001) >> 64;
        }

        // We're doing two things at the same time:
        //
        //   1. Multiply the result by 2^n + 1, where "2^n" is the integer part and the one is added to account for
        //      the fact that we initially set the result to 0.5. This is accomplished by subtracting from 191
        //      rather than 192.
        //   2. Convert the result to the unsigned 60.18-decimal fixed-point format.
        //
        // This works because 2^(191-ip) = 2^ip / 2^191, where "ip" is the integer part "2^n".
        result *= SCALE;
        result >>= (191 - (x >> 64));
    }
    }

    /// @notice Finds the zero-based index of the first one in the binary representation of x.
    /// @dev See the note on msb in the "Find First Set" Wikipedia article https://en.wikipedia.org/wiki/Find_first_set
    /// @param x The uint256 number for which to find the index of the most significant bit.
    /// @return msb The index of the most significant bit as an uint256.
    function mostSignificantBit(uint256 x) internal pure returns (uint256 msb) {
        if (x >= 2**128) {
            x >>= 128;
            msb += 128;
        }
        if (x >= 2**64) {
            x >>= 64;
            msb += 64;
        }
        if (x >= 2**32) {
            x >>= 32;
            msb += 32;
        }
        if (x >= 2**16) {
            x >>= 16;
            msb += 16;
        }
        if (x >= 2**8) {
            x >>= 8;
            msb += 8;
        }
        if (x >= 2**4) {
            x >>= 4;
            msb += 4;
        }
        if (x >= 2**2) {
            x >>= 2;
            msb += 2;
        }
        if (x >= 2**1) {
            // No need to shift x any more.
            msb += 1;
        }
    }

    /// @notice Calculates floor(x*y÷denominator) with full precision.
    ///
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv.
    ///
    /// Requirements:
    /// - The denominator cannot be zero.
    /// - The result must fit within uint256.
    ///
    /// Caveats:
    /// - This function does not work with fixed-point numbers.
    ///
    /// @param x The multiplicand as an uint256.
    /// @param y The multiplier as an uint256.
    /// @param denominator The divisor as an uint256.
    /// @return result The result as an uint256.
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
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
        unchecked {
            result = prod0 / denominator;
        }
            return result;
        }

        // Make sure the result is less than 2^256. Also prevents denominator == 0.
        if (prod1 >= denominator) {
            revert PRBMath__MulDivOverflow(prod1, denominator);
        }

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
    unchecked {
        // Does not overflow because the denominator cannot be zero at this stage in the function.
        uint256 lpotdod = denominator & (~denominator + 1);
        assembly {
        // Divide denominator by lpotdod.
            denominator := div(denominator, lpotdod)

        // Divide [prod1 prod0] by lpotdod.
            prod0 := div(prod0, lpotdod)

        // Flip lpotdod such that it is 2^256 / lpotdod. If lpotdod is zero, then it becomes one.
            lpotdod := add(div(sub(0, lpotdod), lpotdod), 1)
        }

        // Shift in bits from prod1 into prod0.
        prod0 |= prod1 * lpotdod;

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

    /// @notice Calculates floor(x*y÷1e18) with full precision.
    ///
    /// @dev Variant of "mulDiv" with constant folding, i.e. in which the denominator is always 1e18. Before returning the
    /// final result, we add 1 if (x * y) % SCALE >= HALF_SCALE. Without this, 6.6e-19 would be truncated to 0 instead of
    /// being rounded to 1e-18.  See "Listing 6" and text above it at https://accu.org/index.php/journals/1717.
    ///
    /// Requirements:
    /// - The result must fit within uint256.
    ///
    /// Caveats:
    /// - The body is purposely left uncommented; see the NatSpec comments in "PRBMath.mulDiv" to understand how this works.
    /// - It is assumed that the result can never be type(uint256).max when x and y solve the following two equations:
    ///     1. x * y = type(uint256).max * SCALE
    ///     2. (x * y) % SCALE >= SCALE / 2
    ///
    /// @param x The multiplicand as an unsigned 60.18-decimal fixed-point number.
    /// @param y The multiplier as an unsigned 60.18-decimal fixed-point number.
    /// @return result The result as an unsigned 60.18-decimal fixed-point number.
    function mulDivFixedPoint(uint256 x, uint256 y) internal pure returns (uint256 result) {
        uint256 prod0;
        uint256 prod1;
        assembly {
            let mm := mulmod(x, y, not(0))
            prod0 := mul(x, y)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        if (prod1 >= SCALE) {
            revert PRBMath__MulDivFixedPointOverflow(prod1);
        }

        uint256 remainder;
        uint256 roundUpUnit;
        assembly {
            remainder := mulmod(x, y, SCALE)
            roundUpUnit := gt(remainder, 499999999999999999)
        }

        if (prod1 == 0) {
        unchecked {
            result = (prod0 / SCALE) + roundUpUnit;
            return result;
        }
        }

        assembly {
            result := add(
            mul(
            or(
            div(sub(prod0, remainder), SCALE_LPOTD),
            mul(sub(prod1, gt(remainder, prod0)), add(div(sub(0, SCALE_LPOTD), SCALE_LPOTD), 1))
            ),
            SCALE_INVERSE
            ),
            roundUpUnit
            )
        }
    }

    /// @notice Calculates floor(x*y÷denominator) with full precision.
    ///
    /// @dev An extension of "mulDiv" for signed numbers. Works by computing the signs and the absolute values separately.
    ///
    /// Requirements:
    /// - None of the inputs can be type(int256).min.
    /// - The result must fit within int256.
    ///
    /// @param x The multiplicand as an int256.
    /// @param y The multiplier as an int256.
    /// @param denominator The divisor as an int256.
    /// @return result The result as an int256.
    function mulDivSigned(
        int256 x,
        int256 y,
        int256 denominator
    ) internal pure returns (int256 result) {
        if (x == type(int256).min || y == type(int256).min || denominator == type(int256).min) {
            revert PRBMath__MulDivSignedInputTooSmall();
        }

        // Get hold of the absolute values of x, y and the denominator.
        uint256 ax;
        uint256 ay;
        uint256 ad;
    unchecked {
        ax = x < 0 ? uint256(-x) : uint256(x);
        ay = y < 0 ? uint256(-y) : uint256(y);
        ad = denominator < 0 ? uint256(-denominator) : uint256(denominator);
    }

        // Compute the absolute value of (x*y)÷denominator. The result must fit within int256.
        uint256 rAbs = mulDiv(ax, ay, ad);
        if (rAbs > uint256(type(int256).max)) {
            revert PRBMath__MulDivSignedOverflow(rAbs);
        }

        // Get the signs of x, y and the denominator.
        uint256 sx;
        uint256 sy;
        uint256 sd;
        assembly {
            sx := sgt(x, sub(0, 1))
            sy := sgt(y, sub(0, 1))
            sd := sgt(denominator, sub(0, 1))
        }

        // XOR over sx, sy and sd. This is checking whether there are one or three negative signs in the inputs.
        // If yes, the result should be negative.
        result = sx ^ sy ^ sd == 0 ? -int256(rAbs) : int256(rAbs);
    }

    /// @notice Calculates the square root of x, rounding down.
    /// @dev Uses the Babylonian method https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method.
    ///
    /// Caveats:
    /// - This function does not work with fixed-point numbers.
    ///
    /// @param x The uint256 number for which to calculate the square root.
    /// @return result The result as an uint256.
    function sqrt(uint256 x) internal pure returns (uint256 result) {
        if (x == 0) {
            return 0;
        }

        // Set the initial guess to the least power of two that is greater than or equal to sqrt(x).
        uint256 xAux = uint256(x);
        result = 1;
        if (xAux >= 0x100000000000000000000000000000000) {
            xAux >>= 128;
            result <<= 64;
        }
        if (xAux >= 0x10000000000000000) {
            xAux >>= 64;
            result <<= 32;
        }
        if (xAux >= 0x100000000) {
            xAux >>= 32;
            result <<= 16;
        }
        if (xAux >= 0x10000) {
            xAux >>= 16;
            result <<= 8;
        }
        if (xAux >= 0x100) {
            xAux >>= 8;
            result <<= 4;
        }
        if (xAux >= 0x10) {
            xAux >>= 4;
            result <<= 2;
        }
        if (xAux >= 0x8) {
            result <<= 1;
        }

        // The operations can never overflow because the result is max 2^127 when it enters this block.
    unchecked {
        result = (result + x / result) >> 1;
        result = (result + x / result) >> 1;
        result = (result + x / result) >> 1;
        result = (result + x / result) >> 1;
        result = (result + x / result) >> 1;
        result = (result + x / result) >> 1;
        result = (result + x / result) >> 1; // Seven iterations should be enough
        uint256 roundedDownResult = x / result;
        return result >= roundedDownResult ? roundedDownResult : result;
    }
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IMonksERC20 is IERC20 {
    function maxIssuancePerPost() external returns (uint);
    function getPublicationFunding(uint issuance_) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

/**
 * @title The ERC-2771 Recipient Base Abstract Class - Declarations
 *
 * @notice A contract must implement this interface in order to support relayed transaction.
 *
 * @notice It is recommended that your contract inherits from the ERC2771Recipient contract.
 */
abstract contract IERC2771Recipient {

    /**
     * :warning: **Warning** :warning: The Forwarder can have a full control over your Recipient. Only trust verified Forwarder.
     * @param forwarder The address of the Forwarder contract that is being used.
     * @return isTrustedForwarder `true` if the Forwarder is trusted to forward relayed transactions by this Recipient.
     */
    function isTrustedForwarder(address forwarder) public virtual view returns(bool);

    /**
     * @notice Use this method the contract anywhere instead of msg.sender to support relayed transactions.
     * @return sender The real sender of this call.
     * For a call that came through the Forwarder the real sender is extracted from the last 20 bytes of the `msg.data`.
     * Otherwise simply returns `msg.sender`.
     */
    function _msgSender() internal virtual view returns (address);

    /**
     * @notice Use this method in the contract instead of `msg.data` when difference matters (hashing, signature, etc.)
     * @return data The real `msg.data` of this call.
     * For a call that came through the Forwarder, the real sender address was appended as the last 20 bytes
     * of the `msg.data` - so this method will strip those 20 bytes off.
     * Otherwise (if the call was made directly and not through the forwarder) simply returns `msg.data`.
     */
    function _msgData() internal virtual view returns (bytes calldata);
}