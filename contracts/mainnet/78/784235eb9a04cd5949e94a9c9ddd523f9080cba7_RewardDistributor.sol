/**
 *Submitted for verification at polygonscan.com on 2022-03-22
*/

// Sources flattened with hardhat v2.6.8 https://hardhat.org

// File contracts/interfaces/IRewardDistributor.sol

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IRewardDistributor {
    function addRewardHolderShare(address rewardRecipient, uint256 amount) external;
}


// File contracts/interfaces/IUniswap.sol


interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}


// File @openzeppelin/contracts/utils/math/[email protected]

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}


// File @openzeppelin/contracts/utils/[email protected]

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}


// File contracts/interfaces/IBEP20.sol

/**
 * @dev Interface of the BEP20 standard as defined in the EIP.
 */
interface IBEP20 {
    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}


// File contracts/ReentrancyGuard.sol

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;
    constructor () {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}


// File contracts/RewardDistributor.sol

contract RewardDistributor is IRewardDistributor, ReentrancyGuard {
    using SafeMath for uint256;
    using Address for address;

    // Referral Rewards
    struct ReferralShare {
        uint256 amount;
        uint256 numberOfTimesClaimed;
    }

    mapping (address => ReferralShare) public referralShares;

    uint256 public totalReferralShares;
    
    // Token Address
    address public rewardToken;

    // Pancakeswap Router
    address public router;
    
    // Owner of contract
    address public tokenOwner;
    
    modifier onlyToken() {
        require(msg.sender == rewardToken, 'Invalid Token!'); _;
    }
    
    modifier onlyOwner() {
        require(msg.sender == tokenOwner, 'Invalid Token Owner'); _;
    }

    // EVENTS
    event SetRewardTokenAddress(address indexed rewardToken);
    event TransferedTokenOwnership(address indexed newOwner);
    event UpgradeDistributor(address indexed newDistributor);
    event AddRewardHolderShare(address indexed rewardRecipient, uint256 indexed amount);
    event RemoveRewardholder(address indexed rewardRecipient);
    event GiftReward(address indexed rewardRecipient, address indexed giftRecipient, uint256 indexed amount);
    event ClaimReward(address indexed rewardRecipient);
    event ClaimRewardInDesiredToken(address indexed rewardRecipient, address indexed desiredToken);
    event ClaimRewardToDesiredWallet(address indexed rewardRecipient, address indexed desiredWallet);
    event ClaimRewardInDesiredTokenToDesiredWallet(address indexed rewardRecipient, address indexed desiredWallet, address indexed desiredToken);
    event UpdateRouterAddress(address indexed router);

    constructor (address _router) {
        tokenOwner = msg.sender;
        router = _router;
    }

    receive() external payable {}

    function setRewardTokenAddress(address _rewardToken) external onlyOwner {
        require(rewardToken != _rewardToken && _rewardToken != address(0), 'Invalid Reward Token!');

        if (rewardToken != address(0)) {
            uint256 balance = IBEP20(rewardToken).balanceOf(address(this));
            if (balance > 0) {
                require(IBEP20(rewardToken).transfer(tokenOwner, balance), 'Transfer Failed!');
            }
        }
        
        rewardToken = _rewardToken;
        emit SetRewardTokenAddress(_rewardToken);
    }
    
    function transferTokenOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), 'Invalid New Owner');
        tokenOwner = newOwner;
        emit TransferedTokenOwnership(newOwner);
    }
    
    function upgradeDistributor(address newDistributor) external onlyOwner {
        require(newDistributor != address(this) && newDistributor != address(0), 'Invalid Distributor!');
        uint256 balance = IBEP20(rewardToken).balanceOf(address(this));
        if (balance > 0) require(IBEP20(rewardToken).transfer(newDistributor, balance), 'Transfer Failed!');
        emit UpgradeDistributor(newDistributor);
        selfdestruct(payable(tokenOwner));
    }

    function addRewardHolderShare(address rewardRecipient, uint256 amount) external override onlyToken {
        referralShares[rewardRecipient].amount = referralShares[rewardRecipient].amount.add(amount);
        totalReferralShares = totalReferralShares.add(amount);
        emit AddRewardHolderShare(rewardRecipient, amount);
    }

    function updateRouterAddress(address _router) external onlyOwner {
        require(_router != address(0), 'Router Address Invalid!');
        require(router != _router, 'Router Address already exists!');
        router = _router;
        emit UpdateRouterAddress(_router);
    }

    // Back-Up withdraw, in case BNB gets sent in here
    // NOTE: This function is to be called if and only if BNB gets sent into this contract. 
    // On no other occurence should this function be called. 
    function emergencyWithdrawEthInWei(address payable recipient, uint256 amount) external onlyOwner {
        require(recipient != address(0), 'Invalid Recipient!');
        require(amount > 0, 'Invalid Amount!');
        recipient.transfer(amount);
    }

    // Withdraw BEP20 tokens sent to this contract
    // NOTE: This function is to be called if and only if BEP20 tokens gets sent into this contract. 
    // On no other occurence should this function be called. 
    function emergencyWithdrawTokens(address token) external onlyOwner {
        require(token != address(0), 'Invalid Token!');

        uint256 balance = IBEP20(token).balanceOf(address(this));
        if (balance > 0) {
            require(IBEP20(token).transfer(tokenOwner, balance), 'Transfer Failed!');
        }
    }

    function giftReward(address giftRecipient, uint256 amount) external nonReentrant {
        _giftReward(msg.sender, giftRecipient, amount);
        emit GiftReward(msg.sender, giftRecipient, amount);
    }

    function claimReward() external nonReentrant {
        _claimRewardInBNB(msg.sender);
        emit ClaimReward(msg.sender);
    }

    function claimRewardInDesiredToken(address desiredToken) external nonReentrant {
        _claimRewardInDesiredToken(msg.sender, desiredToken);
        emit ClaimRewardInDesiredToken(msg.sender, desiredToken);
    }

    function claimRewardToDesiredWallet(address desiredWallet) external nonReentrant {
        _claimRewardInBNBToDesiredWallet(msg.sender, desiredWallet);
        emit ClaimRewardToDesiredWallet(msg.sender, desiredWallet);
    }

    function claimRewardInDesiredTokenToDesiredWallet(address desiredToken, address desiredWallet) external nonReentrant {
        require(desiredWallet != address(0), "Invalid Destination Wallet!");
        _claimRewardInDesiredTokenToDesiredWallet(msg.sender, desiredWallet, desiredToken);
        emit ClaimRewardInDesiredTokenToDesiredWallet(msg.sender, desiredWallet, desiredToken);
    }

    function _giftReward(address rewardRecipient, address giftRecipient, uint256 amount) private {
        require(rewardRecipient != address(0), 'Invalid Reward Recipient!');
        require(giftRecipient != address(0), 'Invalid Gift Recipient!');
        require(referralShares[rewardRecipient].amount > 0, 'Insufficient Balance!');
        require(amount > 0, 'Invalid Amount!');
        require(amount <= referralShares[rewardRecipient].amount, 'Insufficient Balance!');

        if (referralShares[rewardRecipient].amount <= IBEP20(rewardToken).balanceOf(address(this))) {
            require(IBEP20(rewardToken).transfer(giftRecipient, amount), 'Transfer Failed!');
            
            referralShares[rewardRecipient].amount = referralShares[rewardRecipient].amount.sub(amount);
        }
    }
    
    function _claimRewardInBNB(address rewardRecipient) private {
        require(rewardRecipient != address(0), 'Invalid Reward Recipient!');
        require(referralShares[rewardRecipient].amount > 0, 'Insufficient Balance!');

        if (referralShares[rewardRecipient].amount <= IBEP20(rewardToken).balanceOf(address(this))) {
            // Swap token and send to the reward recipient
            _swapAndSendBNB(rewardRecipient, referralShares[rewardRecipient].amount);

            // Set amount to 0, set number of times claimed
            referralShares[rewardRecipient].amount = 0;
            referralShares[rewardRecipient].numberOfTimesClaimed = referralShares[rewardRecipient].numberOfTimesClaimed.add(1);
        }
    }

    function _claimRewardInDesiredToken(address rewardRecipient, address desiredToken) private {
        require(rewardRecipient != address(0), 'Invalid Reward Recipient!');
        require(desiredToken != address(0), 'Invalid Desired Token!');
        require(referralShares[rewardRecipient].amount > 0, 'Insufficient Balance!');

        if (referralShares[rewardRecipient].amount <= IBEP20(rewardToken).balanceOf(address(this))) {
            // Swap token and send to the reward recipient
            _swapAndSendToken(rewardRecipient, referralShares[rewardRecipient].amount, desiredToken);

            // Set amount to 0, set number of times claimed
            referralShares[rewardRecipient].amount = 0;
            referralShares[rewardRecipient].numberOfTimesClaimed = referralShares[rewardRecipient].numberOfTimesClaimed.add(1);
        }
    }

    function _claimRewardInBNBToDesiredWallet(address rewardRecipient, address desiredWallet) private {
        require(rewardRecipient != address(0), 'Invalid Reward Recipient!');
        require(desiredWallet != address(0), 'Zero Address!');
        require(referralShares[rewardRecipient].amount > 0, 'Insufficient Balance!');

        if (referralShares[rewardRecipient].amount <= IBEP20(rewardToken).balanceOf(address(this))) {
            // Swap token and send to the reward recipient
            _swapAndSendBNB(desiredWallet, referralShares[rewardRecipient].amount);

            // Set amount to 0, set number of times claimed
            referralShares[rewardRecipient].amount = 0;
            referralShares[rewardRecipient].numberOfTimesClaimed = referralShares[rewardRecipient].numberOfTimesClaimed.add(1);
        }
    }

    function _claimRewardInDesiredTokenToDesiredWallet(address rewardRecipient, address desiredWallet, address desiredToken) private {
        require(rewardRecipient != address(0), 'Invalid Reward Recipient!');
        require(desiredWallet != address(0), 'Zero Address!');
        require(desiredToken != address(0), 'Invalid Desired Token!');
        require(referralShares[rewardRecipient].amount > 0, 'Insufficient Balance!');

        if (referralShares[rewardRecipient].amount <= IBEP20(rewardToken).balanceOf(address(this))) {
            // Swap token and send to the reward recipient
            _swapAndSendToken(desiredWallet, referralShares[rewardRecipient].amount, desiredToken);

            // Set amount to 0, set number of times claimed
            referralShares[rewardRecipient].amount = 0;
            referralShares[rewardRecipient].numberOfTimesClaimed = referralShares[rewardRecipient].numberOfTimesClaimed.add(1);
        }
    }

    function _swapAndSendBNB(address recipient, uint256 amount) private {
        IUniswapV2Router02 pcsV2Router = IUniswapV2Router02(router);

        address[] memory path = new address[](2);
        path[0] = rewardToken;
        path[1] = pcsV2Router.WETH();

        IBEP20(rewardToken).approve(address(pcsV2Router), amount);

        pcsV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amount,
            0,
            path,
            recipient,
            block.timestamp.add(30)
        );
    }

    function _swapAndSendToken(address recipient, uint256 amount, address token) private {
        IUniswapV2Router02 pcsV2Router = IUniswapV2Router02(router);

        address[] memory path = new address[](3);
        path[0] = rewardToken;
        path[1] = pcsV2Router.WETH();
        path[2] = token;

        IBEP20(rewardToken).approve(address(pcsV2Router), amount);

        pcsV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amount,
            0,
            path,
            recipient,
            block.timestamp.add(30)
        );
    }
}