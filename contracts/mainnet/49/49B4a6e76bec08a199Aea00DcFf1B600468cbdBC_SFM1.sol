/**
 *Submitted for verification at polygonscan.com on 2022-04-26
*/

// SPDX-License-Identifier: Unlicensed

pragma solidity >=0.6.2;

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

// File: @uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol

pragma solidity >=0.6.2;


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

// File: @uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol

pragma solidity >=0.5.0;

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

// File: @uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol

pragma solidity >=0.5.0;

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

// File: @openzeppelin/contracts/utils/Address.sol


// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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

// File: @openzeppelin/contracts/utils/math/SafeMath.sol


// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
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

// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: @openzeppelin/contracts/security/Pausable.sol


// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

// File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;


/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;




/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = _allowances[owner][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Spend `amount` form the allowance of `owner` toward `spender`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// File: @openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/extensions/ERC20Burnable.sol)

pragma solidity ^0.8.0;



/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }
}

 

 

contract SFM1 is Context, IERC20, Ownable {

    using SafeMath for uint256;

    using Address for address;

 

    mapping (address => uint256) private _rOwned;

    mapping (address => uint256) private _tOwned;

    mapping (address => mapping (address => uint256)) private _allowances;

 

    mapping (address => bool) private _isExcludedFromFee;

 

    mapping (address => bool) private _isExcluded;

    address[] private _excluded;

   

    uint256 private constant MAX = ~uint256(0);

    uint256 private _tTotal = 1000 * 10**18;

    uint256 private _rTotal = (MAX - (MAX % _tTotal));

    uint256 private _tFeeTotal;

 

    string private _name = "SFM1";

    string private _symbol = "SFM1";

    uint8 private _decimals = 18;

    

    uint256 public _taxFee = 10;

    uint256 private _previousTaxFee = _taxFee;

    

    uint256 public _liquidityFee = 30;

    uint256 private _previousLiquidityFee = _liquidityFee;

 

    IUniswapV2Router02 public immutable uniswapV2Router;

    address public immutable uniswapV2Pair;

    

    bool inSwapAndLiquify;

    bool public swapAndLiquifyEnabled = false;

    

    uint256 public _maxTxAmount = 10 * 10**18;

    uint256 private numTokensSellToAddToLiquidity = 10 * 10**18;

    

    event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);

    event SwapAndLiquifyEnabledUpdated(bool enabled);

    event SwapAndLiquify(

        uint256 tokensSwapped,

        uint256 ethReceived,

        uint256 tokensIntoLiqudity

    );

    

    modifier lockTheSwap {

        inSwapAndLiquify = true;

        _;

        inSwapAndLiquify = false;

    }

    // DEBUG TESTING
    address immutable public zdebugUniswapFactory;
    address immutable public zdebugUniswapRouter;
    
    address public zdebugWETHaddress;
    address public zdebugUniswapPair;

    constructor () {
        zdebugUniswapFactory = 0x5757371414417b8C6CAad45bAeF941aBc7d3Ab32;
        zdebugUniswapRouter = 0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff;
        zdebugWETHaddress = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;
        _rOwned[address(this)] = _rTotal;


        _approve(address(this), address(zdebugUniswapFactory), type(uint256).max);
        _approve(address(this), address(zdebugUniswapRouter), type(uint256).max);
        _approve(address(owner()), address(zdebugUniswapFactory), type(uint256).max);
        _approve(address(owner()), address(zdebugUniswapRouter), type(uint256).max);


        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(zdebugUniswapRouter);
        uniswapV2Router = _uniswapV2Router;

        address WETHaddress = IUniswapV2Router02(zdebugUniswapRouter).WETH();
        zdebugWETHaddress = WETHaddress;

         // Create a uniswap pair for this new token
        uniswapV2Pair = IUniswapV2Factory(zdebugUniswapFactory).createPair(address(this), zdebugWETHaddress);
        zdebugUniswapPair = uniswapV2Pair;

        // set the rest of the contract variables
        

        //exclude owner and this contract from fee

        _isExcludedFromFee[owner()] = true;

        _isExcludedFromFee[address(this)] = true;

        

        emit Transfer(address(0), address(this), _tTotal);

    }








    function zaddDEXLiquidityFirstTime(uint256 tokenAmount, uint256 ethAmount) public {
        // Adds liquidity to an ERC-20 ⇄ WrappedToken pool with.
        // WrappedToken is the native token, of the blockchain this contract is deployed on, wrapped as ERC20 e.g: WETH, WBNB, WMATIC, etc..
        // IF a pool for the passed token and WrappedToken does not exists, one is created automatically, and exactly amountTokenDesired/msg.value tokens are added.
        IUniswapV2Router02(address(zdebugUniswapRouter)).addLiquidityETH{value: ethAmount}(address(this), tokenAmount, tokenAmount, ethAmount, address(this), block.timestamp);
        //IUniswapV2Router02(address(zdebugUniswapRouter)).addLiquidityETH{value: msg.value}(address(this), msg.value, 0, 0, address(this), block.timestamp);
    }
    


    function zaddDEXLiquidityNative2(uint256 ethAmount) public {
        // Adds liquidity to an ERC-20 ⇄ WrappedToken pool with.
        // WrappedToken is the native token, of the blockchain this contract is deployed on, wrapped as ERC20 e.g: WETH, WBNB, WMATIC, etc..
        // IF a pool for the passed token and WrappedToken does not exists, one is created automatically, and exactly amountTokenDesired/msg.value tokens are added.
        //IUniswapV2Router02(address(zdebugUniswapRouter)).addLiquidityETH{value: ethAmount}(address(this), tokenAmount, tokenAmount, ethAmount, address(this), block.timestamp);
        IUniswapV2Router02(address(zdebugUniswapRouter)).addLiquidityETH{value: ethAmount}(address(this), balanceOf(address(this)), 0, 0, address(this), block.timestamp);
    }



    function zremoveDEXLiquidityNative(uint256 percentage) public {
        // Approve token
        IERC20(zdebugUniswapPair).approve(zdebugUniswapRouter, type(uint256).max);

        // Remove liquidity
        uint256 LPTokens = IERC20(zdebugUniswapPair).balanceOf(address(this)) / 100 * percentage;
        IUniswapV2Router02(address(zdebugUniswapRouter)).removeLiquidityETHSupportingFeeOnTransferTokens(address(this), LPTokens, 0, 0, address(this), block.timestamp);
    }
 


    function zwithdrawNativeFromContract() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }













    function name() public view returns (string memory) {

        return _name;

    }

 

    function symbol() public view returns (string memory) {

        return _symbol;

    }

 

    function decimals() public view returns (uint8) {

        return _decimals;

    }

 

    function totalSupply() public view override returns (uint256) {

        return _tTotal;

    }

 

    function balanceOf(address account) public view override returns (uint256) {

        if (_isExcluded[account]) return _tOwned[account];

        return tokenFromReflection(_rOwned[account]);

    }

 

    function transfer(address recipient, uint256 amount) public override returns (bool) {

        _transfer(_msgSender(), recipient, amount);

        return true;

    }

 

    function allowance(address owner, address spender) public view override returns (uint256) {

        return _allowances[owner][spender];

    }

 

    function approve(address spender, uint256 amount) public override returns (bool) {

        _approve(_msgSender(), spender, amount);

        return true;

    }

 

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {

        _transfer(sender, recipient, amount);

        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));

        return true;

    }

 

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {

        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));

        return true;

    }

 

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {

        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));

        return true;

    }

 

    function isExcludedFromReward(address account) public view returns (bool) {

        return _isExcluded[account];

    }

 

    function totalFees() public view returns (uint256) {

        return _tFeeTotal;

    }

 

    function deliver(uint256 tAmount) public {

        address sender = _msgSender();

        require(!_isExcluded[sender], "Excluded addresses cannot call this function");

        (uint256 rAmount,,,,,) = _getValues(tAmount);

        _rOwned[sender] = _rOwned[sender].sub(rAmount);

        _rTotal = _rTotal.sub(rAmount);

        _tFeeTotal = _tFeeTotal.add(tAmount);

    }

 

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns(uint256) {

        require(tAmount <= _tTotal, "Amount must be less than supply");

        if (!deductTransferFee) {

            (uint256 rAmount,,,,,) = _getValues(tAmount);

            return rAmount;

        } else {

            (,uint256 rTransferAmount,,,,) = _getValues(tAmount);

            return rTransferAmount;

        }

    }

 

    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {

        require(rAmount <= _rTotal, "Amount must be less than total reflections");

        uint256 currentRate =  _getRate();

        return rAmount.div(currentRate);

    }

 

    function excludeFromReward(address account) public onlyOwner() {

        // require(account != 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D, 'We can not exclude Uniswap router.');

        require(!_isExcluded[account], "Account is already excluded");

        if(_rOwned[account] > 0) {

            _tOwned[account] = tokenFromReflection(_rOwned[account]);

        }

        _isExcluded[account] = true;

        _excluded.push(account);

    }

 

    function includeInReward(address account) external onlyOwner() {

        require(_isExcluded[account], "Account is already excluded");

        for (uint256 i = 0; i < _excluded.length; i++) {

            if (_excluded[i] == account) {

                _excluded[i] = _excluded[_excluded.length - 1];

                _tOwned[account] = 0;

                _isExcluded[account] = false;

                _excluded.pop();

                break;

            }

        }

    }

        function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {

        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);

        _tOwned[sender] = _tOwned[sender].sub(tAmount);

        _rOwned[sender] = _rOwned[sender].sub(rAmount);

        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);

        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);        

        _takeLiquidity(tLiquidity);

        _reflectFee(rFee, tFee);

        emit Transfer(sender, recipient, tTransferAmount);

    }

    

        function excludeFromFee(address account) public onlyOwner {

        _isExcludedFromFee[account] = true;

    }

    

    function includeInFee(address account) public onlyOwner {

        _isExcludedFromFee[account] = false;

    }

    

    function setTaxFeePercent(uint256 taxFee) external onlyOwner() {

        _taxFee = taxFee;

    }

    

    function setLiquidityFeePercent(uint256 liquidityFee) external onlyOwner() {

        _liquidityFee = liquidityFee;

    }

   

    function setMaxTxPercent(uint256 maxTxPercent) external onlyOwner() {

        _maxTxAmount = _tTotal.mul(maxTxPercent).div(

            10**2

        );

    }

 

    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {

        swapAndLiquifyEnabled = _enabled;

        emit SwapAndLiquifyEnabledUpdated(_enabled);

    }

    

     //to recieve ETH from uniswapV2Router when swaping

    receive() external payable {}

 

    function _reflectFee(uint256 rFee, uint256 tFee) private {

        _rTotal = _rTotal.sub(rFee);

        _tFeeTotal = _tFeeTotal.add(tFee);

    }

 

    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256) {

        (uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getTValues(tAmount);

        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tLiquidity, _getRate());

        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tLiquidity);

    }

 

    function _getTValues(uint256 tAmount) private view returns (uint256, uint256, uint256) {

        uint256 tFee = calculateTaxFee(tAmount);

        uint256 tLiquidity = calculateLiquidityFee(tAmount);

        uint256 tTransferAmount = tAmount.sub(tFee).sub(tLiquidity);

        return (tTransferAmount, tFee, tLiquidity);

    }

 

    function _getRValues(uint256 tAmount, uint256 tFee, uint256 tLiquidity, uint256 currentRate) private pure returns (uint256, uint256, uint256) {

        uint256 rAmount = tAmount.mul(currentRate);

        uint256 rFee = tFee.mul(currentRate);

        uint256 rLiquidity = tLiquidity.mul(currentRate);

        uint256 rTransferAmount = rAmount.sub(rFee).sub(rLiquidity);

        return (rAmount, rTransferAmount, rFee);

    }

 

    function _getRate() private view returns(uint256) {

        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();

        return rSupply.div(tSupply);

    }

 

    function _getCurrentSupply() private view returns(uint256, uint256) {

        uint256 rSupply = _rTotal;

        uint256 tSupply = _tTotal;      

        for (uint256 i = 0; i < _excluded.length; i++) {

            if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return (_rTotal, _tTotal);

            rSupply = rSupply.sub(_rOwned[_excluded[i]]);

            tSupply = tSupply.sub(_tOwned[_excluded[i]]);

        }

        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);

        return (rSupply, tSupply);

    }

    

    function _takeLiquidity(uint256 tLiquidity) private {

        uint256 currentRate =  _getRate();

        uint256 rLiquidity = tLiquidity.mul(currentRate);

        _rOwned[address(this)] = _rOwned[address(this)].add(rLiquidity);

        if(_isExcluded[address(this)])

            _tOwned[address(this)] = _tOwned[address(this)].add(tLiquidity);

    }

    

    function calculateTaxFee(uint256 _amount) private view returns (uint256) {

        return _amount.mul(_taxFee).div(

            10**2

        );

    }

 

    function calculateLiquidityFee(uint256 _amount) private view returns (uint256) {

        return _amount.mul(_liquidityFee).div(

            10**2

        );

    }

    

    function removeAllFee() private {

        if(_taxFee == 0 && _liquidityFee == 0) return;

        

        _previousTaxFee = _taxFee;

        _previousLiquidityFee = _liquidityFee;

        

        _taxFee = 0;

        _liquidityFee = 0;

    }

    

    function restoreAllFee() private {

        _taxFee = _previousTaxFee;

        _liquidityFee = _previousLiquidityFee;

    }

    

    function isExcludedFromFee(address account) public view returns(bool) {

        return _isExcludedFromFee[account];

    }

 

    function _approve(address owner, address spender, uint256 amount) private {

        require(owner != address(0), "ERC20: approve from the zero address");

        require(spender != address(0), "ERC20: approve to the zero address");

 

        _allowances[owner][spender] = amount;

        emit Approval(owner, spender, amount);

    }

 

    function _transfer(

        address from,

        address to,

        uint256 amount

    ) private {

        require(from != address(0), "ERC20: transfer from the zero address");

        require(to != address(0), "ERC20: transfer to the zero address");

        require(amount > 0, "Transfer amount must be greater than zero");

        if(from != owner() && to != owner())

            require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");

 

        // is the token balance of this contract address over the min number of

        // tokens that we need to initiate a swap + liquidity lock?

        // also, don't get caught in a circular liquidity event.

        // also, don't swap & liquify if sender is uniswap pair.

        uint256 contractTokenBalance = balanceOf(address(this));

        

        if(contractTokenBalance >= _maxTxAmount)

        {

            contractTokenBalance = _maxTxAmount;

        }

        

        bool overMinTokenBalance = contractTokenBalance >= numTokensSellToAddToLiquidity;

        if (

            overMinTokenBalance &&

            !inSwapAndLiquify &&

            from != uniswapV2Pair &&

            swapAndLiquifyEnabled

        ) {

            contractTokenBalance = numTokensSellToAddToLiquidity;

            //add liquidity

            swapAndLiquify(contractTokenBalance);

        }

        

        //indicates if fee should be deducted from transfer

        bool takeFee = true;

        

        //if any account belongs to _isExcludedFromFee account then remove the fee

        if(_isExcludedFromFee[from] || _isExcludedFromFee[to]){

            takeFee = false;

        }

        

        //transfer amount, it will take tax, burn, liquidity fee

        _tokenTransfer(from,to,amount,takeFee);

    }

 

    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {

        // split the contract balance into halves

        uint256 half = contractTokenBalance.div(2);

        uint256 otherHalf = contractTokenBalance.sub(half);

 

        // capture the contract's current ETH balance.

        // this is so that we can capture exactly the amount of ETH that the

        // swap creates, and not make the liquidity event include any ETH that

        // has been manually sent to the contract

        uint256 initialBalance = address(this).balance;

 

        // swap tokens for ETH

        swapTokensForEth(half); // <- this breaks the ETH -> HATE swap when swap+liquify is triggered

 

        // how much ETH did we just swap into?

        uint256 newBalance = address(this).balance.sub(initialBalance);

 

        // add liquidity to uniswap

        addLiquidity(otherHalf, newBalance);

        

        emit SwapAndLiquify(half, newBalance, otherHalf);

    }

 

    function swapTokensForEth(uint256 tokenAmount) private {

        // generate the uniswap pair path of token -> weth

        address[] memory path = new address[](2);

        path[0] = address(this);

        path[1] = uniswapV2Router.WETH();

 

        _approve(address(this), address(uniswapV2Router), tokenAmount);

 

        // make the swap

        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(

            tokenAmount,

            0, // accept any amount of ETH

            path,

            address(this),

            block.timestamp

        );

    }

 

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {

        // approve token transfer to cover all possible scenarios

        _approve(address(this), address(uniswapV2Router), tokenAmount);

 

        // add the liquidity

        uniswapV2Router.addLiquidityETH{value: ethAmount}(

            address(this),

            tokenAmount,

            0, // slippage is unavoidable

            0, // slippage is unavoidable

            address(this),

            block.timestamp

        );

    }

 

    //this method is responsible for taking all fee, if takeFee is true

    function _tokenTransfer(address sender, address recipient, uint256 amount,bool takeFee) private {

        if(!takeFee)

            removeAllFee();

        

        if (_isExcluded[sender] && !_isExcluded[recipient]) {

            _transferFromExcluded(sender, recipient, amount);

        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {

            _transferToExcluded(sender, recipient, amount);

        } else if (!_isExcluded[sender] && !_isExcluded[recipient]) {

            _transferStandard(sender, recipient, amount);

        } else if (_isExcluded[sender] && _isExcluded[recipient]) {

            _transferBothExcluded(sender, recipient, amount);

        } else {

            _transferStandard(sender, recipient, amount);

        }

        

        if(!takeFee)

            restoreAllFee();

    }

 

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {

        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);

        _rOwned[sender] = _rOwned[sender].sub(rAmount);

        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);

        _takeLiquidity(tLiquidity);

        _reflectFee(rFee, tFee);

        emit Transfer(sender, recipient, tTransferAmount);

    }

 

    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {

        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);

        _rOwned[sender] = _rOwned[sender].sub(rAmount);

        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);

        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);           

        _takeLiquidity(tLiquidity);

        _reflectFee(rFee, tFee);

        emit Transfer(sender, recipient, tTransferAmount);

    }

 

    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {

        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);

        _tOwned[sender] = _tOwned[sender].sub(tAmount);

        _rOwned[sender] = _rOwned[sender].sub(rAmount);

        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);   

        _takeLiquidity(tLiquidity);

        _reflectFee(rFee, tFee);

        emit Transfer(sender, recipient, tTransferAmount);

    }
    
}