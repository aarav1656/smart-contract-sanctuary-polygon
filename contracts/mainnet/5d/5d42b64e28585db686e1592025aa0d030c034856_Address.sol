/**
 *Submitted for verification at polygonscan.com on 2023-02-09
*/

// File: gist-bec82ffe3214e1948b08e302d892894f/interfaces/IDex.sol

/*
```_____````````````_````_`````````````````_``````````````_````````````
``/`____|``````````|`|``|`|```````````````|`|````````````|`|```````````
`|`|`````___```___`|`|`_|`|__```___```___`|`|`__```````__|`|`_____```__
`|`|````/`_`\`/`_`\|`|/`/`'_`\`/`_`\`/`_`\|`|/`/``````/`_``|/`_`\`\`/`/
`|`|___|`(_)`|`(_)`|```<|`|_)`|`(_)`|`(_)`|```<```_``|`(_|`|``__/\`V`/`
``\_____\___/`\___/|_|\_\_.__/`\___/`\___/|_|\_\`(_)``\__,_|\___|`\_/``
```````````````````````````````````````````````````````````````````````
```````````````````````````````````````````````````````````````````````
*/

// -> Cookbook is a free smart contract marketplace. Find, deploy and contribute audited smart contracts.
// -> Follow Cookbook on Twitter: https://twitter.com/cookbook_dev
// -> Join Cookbook on Discord:https://discord.gg/WzsfPcfHrk

// -> Find this contract on Cookbook: https://www.cookbook.dev/contracts/dividend-paying-token-with-buy-sell-fee/?utm=code


pragma solidity ^0.8.10;

interface IPair {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function token0() external view returns (address);

}

interface IFactory{
        function createPair(address tokenA, address tokenB) external returns (address pair);
        function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface IRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline) external;
}
// File: gist-bec82ffe3214e1948b08e302d892894f/interfaces/Ownable.sol

/*
```_____````````````_````_`````````````````_``````````````_````````````
``/`____|``````````|`|``|`|```````````````|`|````````````|`|```````````
`|`|`````___```___`|`|`_|`|__```___```___`|`|`__```````__|`|`_____```__
`|`|````/`_`\`/`_`\|`|/`/`'_`\`/`_`\`/`_`\|`|/`/``````/`_``|/`_`\`\`/`/
`|`|___|`(_)`|`(_)`|```<|`|_)`|`(_)`|`(_)`|```<```_``|`(_|`|``__/\`V`/`
``\_____\___/`\___/|_|\_\_.__/`\___/`\___/|_|\_\`(_)``\__,_|\___|`\_/``
```````````````````````````````````````````````````````````````````````
```````````````````````````````````````````````````````````````````````
*/

// -> Cookbook is a free smart contract marketplace. Find, deploy and contribute audited smart contracts.
// -> Follow Cookbook on Twitter: https://twitter.com/cookbook_dev
// -> Join Cookbook on Discord:https://discord.gg/WzsfPcfHrk

// -> Find this contract on Cookbook: https://www.cookbook.dev/contracts/dividend-paying-token-with-buy-sell-fee/?utm=code



pragma solidity ^0.8.10;

// File: gist-bec82ffe3214e1948b08e302d892894f/interfaces/Context.sol

/*
```_____````````````_````_`````````````````_``````````````_````````````
``/`____|``````````|`|``|`|```````````````|`|````````````|`|```````````
`|`|`````___```___`|`|`_|`|__```___```___`|`|`__```````__|`|`_____```__
`|`|````/`_`\`/`_`\|`|/`/`'_`\`/`_`\`/`_`\|`|/`/``````/`_``|/`_`\`\`/`/
`|`|___|`(_)`|`(_)`|```<|`|_)`|`(_)`|`(_)`|```<```_``|`(_|`|``__/\`V`/`
``\_____\___/`\___/|_|\_\_.__/`\___/`\___/|_|\_\`(_)``\__,_|\___|`\_/``
```````````````````````````````````````````````````````````````````````
```````````````````````````````````````````````````````````````````````
*/

// -> Cookbook is a free smart contract marketplace. Find, deploy and contribute audited smart contracts.
// -> Follow Cookbook on Twitter: https://twitter.com/cookbook_dev
// -> Join Cookbook on Discord:https://discord.gg/WzsfPcfHrk

// -> Find this contract on Cookbook: https://www.cookbook.dev/contracts/dividend-paying-token-with-buy-sell-fee/?utm=code


pragma solidity ^0.8.10;

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}
// File: gist-bec82ffe3214e1948b08e302d892894f/interfaces/IERC20.sol


contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}
// File: gist-bec82ffe3214e1948b08e302d892894f/interfaces/DividendPayingTokenInterface.sol

/*
```_____````````````_````_`````````````````_``````````````_````````````
``/`____|``````````|`|``|`|```````````````|`|````````````|`|```````````
`|`|`````___```___`|`|`_|`|__```___```___`|`|`__```````__|`|`_____```__
`|`|````/`_`\`/`_`\|`|/`/`'_`\`/`_`\`/`_`\|`|/`/``````/`_``|/`_`\`\`/`/
`|`|___|`(_)`|`(_)`|```<|`|_)`|`(_)`|`(_)`|```<```_``|`(_|`|``__/\`V`/`
``\_____\___/`\___/|_|\_\_.__/`\___/`\___/|_|\_\`(_)``\__,_|\___|`\_/``
```````````````````````````````````````````````````````````````````````
```````````````````````````````````````````````````````````````````````
*/

// -> Cookbook is a free smart contract marketplace. Find, deploy and contribute audited smart contracts.
// -> Follow Cookbook on Twitter: https://twitter.com/cookbook_dev
// -> Join Cookbook on Discord:https://discord.gg/WzsfPcfHrk

// -> Find this contract on Cookbook: https://www.cookbook.dev/contracts/dividend-paying-token-with-buy-sell-fee/?utm=code


pragma solidity ^0.8.6;


/// @title Dividend-Paying Token Interface
/// @author Roger Wu (https://github.com/roger-wu)
/// @dev An interface for a dividend-paying token contract.
interface DividendPayingTokenInterface {
  /// @notice View the amount of dividend in wei that an address can withdraw.
  /// @param _owner The address of a token holder.
  /// @return The amount of dividend in wei that `_owner` can withdraw.
  function dividendOf(address _owner) external view returns(uint256);

  /// @notice Withdraws the ether distributed to the sender.
  /// @dev SHOULD transfer `dividendOf(msg.sender)` wei to `msg.sender`, and `dividendOf(msg.sender)` SHOULD be 0 after the transfer.
  ///  MUST emit a `DividendWithdrawn` event if the amount of ether transferred is greater than 0.
  function withdrawDividend() external;
  
  /// @notice View the amount of dividend in wei that an address can withdraw.
  /// @param _owner The address of a token holder.
  /// @return The amount of dividend in wei that `_owner` can withdraw.
  function withdrawableDividendOf(address _owner) external view returns(uint256);

  /// @notice View the amount of dividend in wei that an address has withdrawn.
  /// @param _owner The address of a token holder.
  /// @return The amount of dividend in wei that `_owner` has withdrawn.
  function withdrawnDividendOf(address _owner) external view returns(uint256);

  /// @notice View the amount of dividend in wei that an address has earned in total.
  /// @dev accumulativeDividendOf(_owner) = withdrawableDividendOf(_owner) + withdrawnDividendOf(_owner)
  /// @param _owner The address of a token holder.
  /// @return The amount of dividend in wei that `_owner` has earned in total.
  function accumulativeDividendOf(address _owner) external view returns(uint256);


  /// @dev This event MUST emit when ether is distributed to token holders.
  /// @param from The address which sends ether to this contract.
  /// @param weiAmount The amount of distributed ether in wei.
  event DividendsDistributed(
    address indexed from,
    uint256 weiAmount
  );

  /// @dev This event MUST emit when an address withdraws their dividend.
  /// @param to The address which withdraws ether from this contract.
  /// @param weiAmount The amount of withdrawn ether in wei.
  event DividendWithdrawn(
    address indexed to,
    uint256 weiAmount
  );
  
}

// File: gist-bec82ffe3214e1948b08e302d892894f/interfaces/SafeMath.sol

/*
```_____````````````_````_`````````````````_``````````````_````````````
``/`____|``````````|`|``|`|```````````````|`|````````````|`|```````````
`|`|`````___```___`|`|`_|`|__```___```___`|`|`__```````__|`|`_____```__
`|`|````/`_`\`/`_`\|`|/`/`'_`\`/`_`\`/`_`\|`|/`/``````/`_``|/`_`\`\`/`/
`|`|___|`(_)`|`(_)`|```<|`|_)`|`(_)`|`(_)`|```<```_``|`(_|`|``__/\`V`/`
``\_____\___/`\___/|_|\_\_.__/`\___/`\___/|_|\_\`(_)``\__,_|\___|`\_/``
```````````````````````````````````````````````````````````````````````
```````````````````````````````````````````````````````````````````````
*/

// -> Cookbook is a free smart contract marketplace. Find, deploy and contribute audited smart contracts.
// -> Follow Cookbook on Twitter: https://twitter.com/cookbook_dev
// -> Join Cookbook on Discord:https://discord.gg/WzsfPcfHrk

// -> Find this contract on Cookbook: https://www.cookbook.dev/contracts/dividend-paying-token-with-buy-sell-fee/?utm=code


pragma solidity ^0.8.6;

library SafeMath {
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
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
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

/**
 * @title SafeMathInt
 * @dev Math operations for int256 with overflow safety checks.
 */
library SafeMathInt {
    int256 private constant MIN_INT256 = int256(1) << 255;
    int256 private constant MAX_INT256 = ~(int256(1) << 255);

    /**
     * @dev Multiplies two int256 variables and fails on overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a * b;

        // Detect overflow when multiplying MIN_INT256 with -1
        require(c != MIN_INT256 || (a & MIN_INT256) != (b & MIN_INT256));
        require((b == 0) || (c / b == a));
        return c;
    }

    /**
     * @dev Division of two int256 variables and fails on overflow.
     */
    function div(int256 a, int256 b) internal pure returns (int256) {
        // Prevent overflow when dividing MIN_INT256 by -1
        require(b != -1 || a != MIN_INT256);

        // Solidity already throws when dividing by 0.
        return a / b;
    }

    /**
     * @dev Subtracts two int256 variables and fails on overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a));
        return c;
    }

    /**
     * @dev Adds two int256 variables and fails on overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));
        return c;
    }

    /**
     * @dev Converts to absolute value, and fails on overflow.
     */
    function abs(int256 a) internal pure returns (int256) {
        require(a != MIN_INT256);
        return a < 0 ? -a : a;
    }


    function toUint256Safe(int256 a) internal pure returns (uint256) {
        require(a >= 0);
        return uint256(a);
    }
}

/**
 * @title SafeMathUint
 * @dev Math operations with safety checks that revert on error
 */
library SafeMathUint {
  function toInt256Safe(uint256 a) internal pure returns (int256) {
    int256 b = int256(a);
    require(b >= 0);
    return b;
  }
}

/*
```_____````````````_````_`````````````````_``````````````_````````````
``/`____|``````````|`|``|`|```````````````|`|````````````|`|```````````
`|`|`````___```___`|`|`_|`|__```___```___`|`|`__```````__|`|`_____```__
`|`|````/`_`\`/`_`\|`|/`/`'_`\`/`_`\`/`_`\|`|/`/``````/`_``|/`_`\`\`/`/
`|`|___|`(_)`|`(_)`|```<|`|_)`|`(_)`|`(_)`|```<```_``|`(_|`|``__/\`V`/`
``\_____\___/`\___/|_|\_\_.__/`\___/`\___/|_|\_\`(_)``\__,_|\___|`\_/``
```````````````````````````````````````````````````````````````````````
```````````````````````````````````````````````````````````````````````
*/

// -> Cookbook is a free smart contract marketplace. Find, deploy and contribute audited smart contracts.
// -> Follow Cookbook on Twitter: https://twitter.com/cookbook_dev
// -> Join Cookbook on Discord:https://discord.gg/WzsfPcfHrk

// -> Find this contract on Cookbook: https://www.cookbook.dev/contracts/dividend-paying-token-with-buy-sell-fee/?utm=code


pragma solidity ^0.8.10;

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
// File: gist-bec82ffe3214e1948b08e302d892894f/interfaces/ERC20.sol

/*
```_____````````````_````_`````````````````_``````````````_````````````
``/`____|``````````|`|``|`|```````````````|`|````````````|`|```````````
`|`|`````___```___`|`|`_|`|__```___```___`|`|`__```````__|`|`_____```__
`|`|````/`_`\`/`_`\|`|/`/`'_`\`/`_`\`/`_`\|`|/`/``````/`_``|/`_`\`\`/`/
`|`|___|`(_)`|`(_)`|```<|`|_)`|`(_)`|`(_)`|```<```_``|`(_|`|``__/\`V`/`
``\_____\___/`\___/|_|\_\_.__/`\___/`\___/|_|\_\`(_)``\__,_|\___|`\_/``
```````````````````````````````````````````````````````````````````````
```````````````````````````````````````````````````````````````````````
*/

// -> Cookbook is a free smart contract marketplace. Find, deploy and contribute audited smart contracts.
// -> Follow Cookbook on Twitter: https://twitter.com/cookbook_dev
// -> Join Cookbook on Discord:https://discord.gg/WzsfPcfHrk

// -> Find this contract on Cookbook: https://www.cookbook.dev/contracts/dividend-paying-token-with-buy-sell-fee/?utm=code


pragma solidity ^0.8.10;




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
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
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
    using SafeMath for uint256;

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
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
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
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
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
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
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

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
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

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
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
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
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
}
// File: gist-bec82ffe3214e1948b08e302d892894f/interfaces/DividendPayingToken.sol

/*
```_____````````````_````_`````````````````_``````````````_````````````
``/`____|``````````|`|``|`|```````````````|`|````````````|`|```````````
`|`|`````___```___`|`|`_|`|__```___```___`|`|`__```````__|`|`_____```__
`|`|````/`_`\`/`_`\|`|/`/`'_`\`/`_`\`/`_`\|`|/`/``````/`_``|/`_`\`\`/`/
`|`|___|`(_)`|`(_)`|```<|`|_)`|`(_)`|`(_)`|```<```_``|`(_|`|``__/\`V`/`
``\_____\___/`\___/|_|\_\_.__/`\___/`\___/|_|\_\`(_)``\__,_|\___|`\_/``
```````````````````````````````````````````````````````````````````````
```````````````````````````````````````````````````````````````````````
*/

// -> Cookbook is a free smart contract marketplace. Find, deploy and contribute audited smart contracts.
// -> Follow Cookbook on Twitter: https://twitter.com/cookbook_dev
// -> Join Cookbook on Discord:https://discord.gg/WzsfPcfHrk

// -> Find this contract on Cookbook: https://www.cookbook.dev/contracts/dividend-paying-token-with-buy-sell-fee/?utm=code


pragma solidity ^0.8.10;







/*
        Credits to: Roger Wu (https://github.com/roger-wu)
        Reference: the source code of PoWH3D: https://etherscan.io/address/0xB3775fB83F7D12A36E0475aBdD1FCA35c091efBe#code
*/

contract DividendPayingToken is ERC20, DividendPayingTokenInterface, Ownable {
  using SafeMath for uint256;
  using SafeMathUint for uint256;
  using SafeMathInt for int256;

  address public LP_Token;


  // With `magnitude`, we can properly distribute dividends even if the amount of received ether is small.
  // For more discussion about choosing the value of `magnitude`,
  //  see https://github.com/ethereum/EIPs/issues/1726#issuecomment-472352728
  uint256 constant internal magnitude = 2**128;

  uint256 internal magnifiedDividendPerShare;

  // About dividendCorrection:
  // If the token balance of a `_user` is never changed, the dividend of `_user` can be computed with:
  //   `dividendOf(_user) = dividendPerShare * balanceOf(_user)`.
  // When `balanceOf(_user)` is changed (via minting/burning/transferring tokens),
  //   `dividendOf(_user)` should not be changed,
  //   but the computed value of `dividendPerShare * balanceOf(_user)` is changed.
  // To keep the `dividendOf(_user)` unchanged, we add a correction term:
  //   `dividendOf(_user) = dividendPerShare * balanceOf(_user) + dividendCorrectionOf(_user)`,
  //   where `dividendCorrectionOf(_user)` is updated whenever `balanceOf(_user)` is changed:
  //   `dividendCorrectionOf(_user) = dividendPerShare * (old balanceOf(_user)) - (new balanceOf(_user))`.
  // So now `dividendOf(_user)` returns the same value before and after `balanceOf(_user)` is changed.
  mapping(address => int256) internal magnifiedDividendCorrections;
  mapping(address => uint256) internal withdrawnDividends;

  uint256 public totalDividendsDistributed;
  uint256 public totalDividendsWithdrawn;

  constructor(string memory _name, string memory _symbol) ERC20(_name, _symbol) {}

  function distributeLPDividends(uint256 amount) public onlyOwner{
    require(totalSupply() > 0);

    if (amount > 0) {
      magnifiedDividendPerShare = magnifiedDividendPerShare.add(
        (amount).mul(magnitude) / totalSupply()
      );
      emit DividendsDistributed(msg.sender, amount);

      totalDividendsDistributed = totalDividendsDistributed.add(amount);
    }
  }

  /// @notice Withdraws the ether distributed to the sender.
  /// @dev It emits a `DividendWithdrawn` event if the amount of withdrawn ether is greater than 0.
  function withdrawDividend() public virtual override {
    _withdrawDividendOfUser(payable(msg.sender));
  }

  /// @notice Withdraws the ether distributed to the sender.
  /// @dev It emits a `DividendWithdrawn` event if the amount of withdrawn ether is greater than 0.
 function _withdrawDividendOfUser(address payable user) internal returns (uint256) {
    uint256 _withdrawableDividend = withdrawableDividendOf(user);
    if (_withdrawableDividend > 0) {
      withdrawnDividends[user] = withdrawnDividends[user].add(_withdrawableDividend);
      totalDividendsWithdrawn += _withdrawableDividend;
      emit DividendWithdrawn(user, _withdrawableDividend);
      bool success = IERC20(LP_Token).transfer(user, _withdrawableDividend);

      if(!success) {
        withdrawnDividends[user] = withdrawnDividends[user].sub(_withdrawableDividend);
        totalDividendsWithdrawn -= _withdrawableDividend;
        return 0;
      }

      return _withdrawableDividend;
    }

    return 0;
  }


  /// @notice View the amount of dividend in wei that an address can withdraw.
  /// @param _owner The address of a token holder.
  /// @return The amount of dividend in wei that `_owner` can withdraw.
  function dividendOf(address _owner) public view override returns(uint256) {
    return withdrawableDividendOf(_owner);
  }

  /// @notice View the amount of dividend in wei that an address can withdraw.
  /// @param _owner The address of a token holder.
  /// @return The amount of dividend in wei that `_owner` can withdraw.
  function withdrawableDividendOf(address _owner) public view override returns(uint256) {
    return accumulativeDividendOf(_owner).sub(withdrawnDividends[_owner]);
  }

  /// @notice View the amount of dividend in wei that an address has withdrawn.
  /// @param _owner The address of a token holder.
  /// @return The amount of dividend in wei that `_owner` has withdrawn.
  function withdrawnDividendOf(address _owner) public view override returns(uint256) {
    return withdrawnDividends[_owner];
  }


  /// @notice View the amount of dividend in wei that an address has earned in total.
  /// @dev accumulativeDividendOf(_owner) = withdrawableDividendOf(_owner) + withdrawnDividendOf(_owner)
  /// = (magnifiedDividendPerShare * balanceOf(_owner) + magnifiedDividendCorrections[_owner]) / magnitude
  /// @param _owner The address of a token holder.
  /// @return The amount of dividend in wei that `_owner` has earned in total.
  function accumulativeDividendOf(address _owner) public view override returns(uint256) {
    return magnifiedDividendPerShare.mul(balanceOf(_owner)).toInt256Safe()
      .add(magnifiedDividendCorrections[_owner]).toUint256Safe() / magnitude;
  }

  /// @dev Internal function that transfer tokens from one address to another.
  /// Update magnifiedDividendCorrections to keep dividends unchanged.
  /// @param from The address to transfer from.
  /// @param to The address to transfer to.
  /// @param value The amount to be transferred.
  function _transfer(address from, address to, uint256 value) internal virtual override {
    require(false);

    int256 _magCorrection = magnifiedDividendPerShare.mul(value).toInt256Safe();
    magnifiedDividendCorrections[from] = magnifiedDividendCorrections[from].add(_magCorrection);
    magnifiedDividendCorrections[to] = magnifiedDividendCorrections[to].sub(_magCorrection);
  }

  /// @dev Internal function that mints tokens to an account.
  /// Update magnifiedDividendCorrections to keep dividends unchanged.
  /// @param account The account that will receive the created tokens.
  /// @param value The amount that will be created.
  function _mint(address account, uint256 value) internal override {
    super._mint(account, value);

    magnifiedDividendCorrections[account] = magnifiedDividendCorrections[account]
      .sub( (magnifiedDividendPerShare.mul(value)).toInt256Safe() );
  }

  /// @dev Internal function that burns an amount of the token of a given account.
  /// Update magnifiedDividendCorrections to keep dividends unchanged.
  /// @param account The account whose tokens will be burnt.
  /// @param value The amount that will be burnt.
  function _burn(address account, uint256 value) internal override {
    super._burn(account, value);

    magnifiedDividendCorrections[account] = magnifiedDividendCorrections[account]
      .add( (magnifiedDividendPerShare.mul(value)).toInt256Safe() );
  }

  function _setBalance(address account, uint256 newBalance) internal {
    uint256 currentBalance = balanceOf(account);

    if(newBalance > currentBalance) {
      uint256 mintAmount = newBalance.sub(currentBalance);
      _mint(account, mintAmount);
    } else if(newBalance < currentBalance) {
      uint256 burnAmount = currentBalance.sub(newBalance);
      _burn(account, burnAmount);
    }
  }
}

// File: gist-bec82ffe3214e1948b08e302d892894f/VIRAL.sol

/*
```_____````````````_````_`````````````````_``````````````_````````````
``/`____|``````````|`|``|`|```````````````|`|````````````|`|```````````
`|`|`````___```___`|`|`_|`|__```___```___`|`|`__```````__|`|`_____```__
`|`|````/`_`\`/`_`\|`|/`/`'_`\`/`_`\`/`_`\|`|/`/``````/`_``|/`_`\`\`/`/
`|`|___|`(_)`|`(_)`|```<|`|_)`|`(_)`|`(_)`|```<```_``|`(_|`|``__/\`V`/`
``\_____\___/`\___/|_|\_\_.__/`\___/`\___/|_|\_\`(_)``\__,_|\___|`\_/``
```````````````````````````````````````````````````````````````````````
```````````````````````````````````````````````````````````````````````
*/

// -> Cookbook is a free smart contract marketplace. Find, deploy and contribute audited smart contracts.
// -> Follow Cookbook on Twitter: https://twitter.com/cookbook_dev
// -> Join Cookbook on Discord:https://discord.gg/WzsfPcfHrk

// -> Find this contract on Cookbook: https://www.cookbook.dev/contracts/dividend-paying-token-with-buy-sell-fee/?utm=code


/**

 TheViralCrypto presents: #VIRAL
   
 by @SatoshiViral

 Community: @TheViralCrypto
 Website: https://theviralcrypto.co/

 */

pragma solidity ^0.8.10;






library Address{
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}


contract VIRAL is ERC20, Ownable {
    using Address for address payable;

    IRouter public router;
    address public  pair;

    bool private swapping;
    bool public swapEnabled = true;
    bool public claimEnabled;
    bool public tradingEnabled;
    
    VIRALDividendTracker public dividendTracker;

    address public treasuryWallet = 0x73fA5dDF2aB78D92bB723D92Ab98aF7A0A4Fde8F;
    address public devWallet = 0x16023072c6a88555736B654629fC807d623617A5;

    uint256 public swapTokensAtAmount = 500_000 * 10**18;
    uint256 public maxBuyAmount = 1_000_000 * 10**18;
    uint256 public maxSellAmount = 1_000_000 * 10**18;

            ///////////////
           //   Fees    //
          ///////////////
    
    struct Taxes {
        uint256 rewards;
        uint256 treasury;
        uint256 liquidity;
        uint256 dev;
    }

    Taxes public buyTaxes = Taxes(0,0,0,2);
    Taxes public sellTaxes = Taxes(5,10,3,2);

    uint256 public totalBuyTax = 2;
    uint256 public totalSellTax = 20;

    mapping (address => bool) public _isBot;
      
    mapping (address => bool) private _isExcludedFromFees;
    mapping (address => bool) public automatedMarketMakerPairs;

        ///////////////
       //   Events  //
      ///////////////
      
    event ExcludeFromFees(address indexed account, bool isExcluded);
    event ExcludeMultipleAccountsFromFees(address[] accounts, bool isExcluded);
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
    event GasForProcessingUpdated(uint256 indexed newValue, uint256 indexed oldValue);
    event SendDividends(uint256 tokensSwapped,uint256 amount);
    event ProcessedDividendTracker(uint256 iterations,uint256 claims,uint256 lastProcessedIndex,bool indexed automatic,uint256 gas,address indexed processor);


    constructor() ERC20("VIRAL", "VIRAL") {

        dividendTracker = new VIRALDividendTracker();

        IRouter _router = IRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        address _pair = IFactory(_router.factory()).createPair(address(this), _router.WETH());

        router = _router;
        pair = _pair;

        _setAutomatedMarketMakerPair(_pair, true);

        dividendTracker.updateLP_Token(pair);

        // exclude from receiving dividends
        dividendTracker.excludeFromDividends(address(dividendTracker), true);
        dividendTracker.excludeFromDividends(address(this), true);
        dividendTracker.excludeFromDividends(owner(), true);
        dividendTracker.excludeFromDividends(address(0xdead), true);
        dividendTracker.excludeFromDividends(address(_router), true);

        // exclude from paying fees or having max transaction amount
        excludeFromFees(owner(), true);
        excludeFromFees(address(this), true);
        excludeFromFees(treasuryWallet, true);
        excludeFromFees(devWallet, true);

        /*
            _mint is an internal function in ERC20.sol that is only called here,
            and CANNOT be called ever again
        */
        _mint(owner(), 10e9* (10**18));
    }

    receive() external payable {}
    function updateDividendTracker(address newAddress) public onlyOwner {
        VIRALDividendTracker newDividendTracker = VIRALDividendTracker(payable(newAddress));

        newDividendTracker.excludeFromDividends(address(newDividendTracker), true);
        newDividendTracker.excludeFromDividends(address(this), true);
        newDividendTracker.excludeFromDividends(owner(), true);
        newDividendTracker.excludeFromDividends(address(router), true);
        dividendTracker = newDividendTracker;
    }

    
    /// @notice Manual claim the dividends
    function claim() external {
        require(claimEnabled, "Claim not enabled");
        dividendTracker.processAccount(payable(msg.sender));
    }
    
    /// @notice Withdraw tokens sent by mistake.
    /// @param tokenAddress The address of the token to withdraw
    function rescueETH20Tokens(address tokenAddress) external onlyOwner{
        IERC20(tokenAddress).transfer(owner(), IERC20(tokenAddress).balanceOf(address(this)));
    }
    
    /// @notice Send remaining ETH to treasuryWallet
    /// @dev It will send all ETH to treasuryWallet
    function forceSend() external {
        uint256 ETHbalance = address(this).balance;
        payable(treasuryWallet).sendValue(ETHbalance);
    }

    function trackerRescueETH20Tokens(address tokenAddress) external onlyOwner{
        dividendTracker.trackerRescueETH20Tokens(owner(), tokenAddress);
    }

    function trackerForceSend() external onlyOwner{
        dividendTracker.trackerForceSend(owner());
    }
    
    function updateRouter(address newRouter) external onlyOwner{
        router = IRouter(newRouter);
    }
    
     /////////////////////////////////
    // Exclude / Include functions //
   /////////////////////////////////

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        require(_isExcludedFromFees[account] != excluded, "VIRAL: Account is already the value of 'excluded'");
        _isExcludedFromFees[account] = excluded;

        emit ExcludeFromFees(account, excluded);
    }

    function excludeMultipleAccountsFromFees(address[] calldata accounts, bool excluded) public onlyOwner {
        for(uint256 i = 0; i < accounts.length; i++) {
            _isExcludedFromFees[accounts[i]] = excluded;
        }
        emit ExcludeMultipleAccountsFromFees(accounts, excluded);
    }

    /// @dev "true" to exlcude, "false" to include
    function excludeFromDividends(address account, bool value) external onlyOwner{
        dividendTracker.excludeFromDividends(account, value);
    }

     ///////////////////////
    //  Setter Functions //
   ///////////////////////

    function setTreasuryWallet(address newWallet) external onlyOwner{
        treasuryWallet = newWallet;
    }

    function setDevWallet(address newWallet) external onlyOwner{
        devWallet = newWallet;
    }

    /// @notice Update the threshold to swap tokens for liquidity,
    ///   treasury and dividends.
    function setSwapTokensAtAmount(uint256 amount) external onlyOwner{
        swapTokensAtAmount = amount * 10**18;
    }

    function setBuyTaxes(uint256 _rewards, uint256 _treasury, uint256 _liquidity, uint256 _dev) external onlyOwner{
        require(_rewards + _treasury + _liquidity + _dev <= 20, "Fee must be <= 20%");
        buyTaxes = Taxes(_rewards, _treasury, _liquidity, _dev);
        totalBuyTax = _rewards + _treasury + _liquidity + _dev;
    }

    function setSellTaxes(uint256 _rewards, uint256 _treasury, uint256 _liquidity,uint256 _dev) external onlyOwner{
        require(_rewards + _treasury + _liquidity + _dev <= 20, "Fee must be <= 20%");
        sellTaxes = Taxes(_rewards, _treasury, _liquidity, _dev);
        totalSellTax = _rewards + _treasury + _liquidity + _dev;
    }

    function setMaxBuyAndSell(uint256 maxBuy, uint256 maxSell) external onlyOwner{
        maxBuyAmount = maxBuy * 10**18;
        maxSellAmount = maxSell * 10**18;
    }

    /// @notice Enable or disable internal swaps
    /// @dev Set "true" to enable internal swaps for liquidity, treasury and dividends
    function setSwapEnabled(bool _enabled) external onlyOwner{
        swapEnabled = _enabled;
    }
    
    
    function activateTrading() external onlyOwner{
        require(!tradingEnabled, "Trading already enabled");
        tradingEnabled = true;
    }

    function setClaimEnabled(bool state) external onlyOwner{
        claimEnabled = state;
    }

    /// @param bot The bot address
    /// @param value "true" to blacklist, "false" to unblacklist
    function setBot(address bot, bool value) external onlyOwner{
        require(_isBot[bot] != value);
        _isBot[bot] = value;
    }
    
    function setBulkBot(address[] memory bots, bool value) external onlyOwner{
        for(uint256 i; i<bots.length; i++){
            _isBot[bots[i]] = value;
        }
    }

    function setLP_Token(address _lpToken) external onlyOwner{
        dividendTracker.updateLP_Token(_lpToken);
    }


    /// @dev Set new pairs created due to listing in new DEX
    function setAutomatedMarketMakerPair(address newPair, bool value) external onlyOwner {
        _setAutomatedMarketMakerPair(newPair, value);
    }
    
    
    function _setAutomatedMarketMakerPair(address newPair, bool value) private {
        require(automatedMarketMakerPairs[newPair] != value, "VIRAL: Automated market maker pair is already set to that value");
        automatedMarketMakerPairs[newPair] = value;

        if(value) {
            dividendTracker.excludeFromDividends(newPair, true);
        }

        emit SetAutomatedMarketMakerPair(newPair, value);
    }

     //////////////////////
    // Getter Functions //
   //////////////////////

    function getTotalDividendsDistributed() external view returns (uint256) {
        return dividendTracker.totalDividendsDistributed();
    }

    function isExcludedFromFees(address account) public view returns(bool) {
        return _isExcludedFromFees[account];
    }

    function withdrawableDividendOf(address account) public view returns(uint256) {
        return dividendTracker.withdrawableDividendOf(account);
    }

    function dividendTokenBalanceOf(address account) public view returns (uint256) {
        return dividendTracker.balanceOf(account);
    }

    function getAccountInfo(address account)
        external view returns (
             address,
            uint256,
            uint256,
            uint256,
            uint256){
        return dividendTracker.getAccount(account);
    }

     ////////////////////////
    // Transfer Functions //
   ////////////////////////
   
    // Airdrop tokens to users. This won't update the dividend balance in order to avoid a gas issue.
    // Users will get dividend balance updated as soon as their balance change.
    function airdropTokens(address[] memory accounts, uint256[] memory amounts) external onlyOwner{
        require(accounts.length == amounts.length, "Arrays must have same size");
        for(uint256 i; i< accounts.length; i++){
            super._transfer(msg.sender, accounts[i], amounts[i]);
        }
    }

    function _transfer(address from, address to, uint256 amount) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        

        if(!_isExcludedFromFees[from] && !_isExcludedFromFees[to] && !swapping){
            require(tradingEnabled, "Trading not active");
            require(!_isBot[from] && !_isBot[to], "Bye Bye Bot");
            if(automatedMarketMakerPairs[to]) require(amount <= maxSellAmount, "You are exceeding maxSellAmount");
            else if(automatedMarketMakerPairs[from]) require(amount <= maxBuyAmount, "You are exceeding maxBuyAmount");
        }

        if(amount == 0) {
            super._transfer(from, to, 0);
            return;
        }
        
        uint256 contractTokenBalance = balanceOf(address(this));
        bool canSwap = contractTokenBalance >= swapTokensAtAmount;

        if( canSwap && !swapping && swapEnabled && automatedMarketMakerPairs[to] && !_isExcludedFromFees[from] && !_isExcludedFromFees[to]) {
            swapping = true;

            if(totalSellTax> 0){
                swapAndLiquify(swapTokensAtAmount);
            }

            swapping = false;
        }

        bool takeFee = !swapping;

        // if any account belongs to _isExcludedFromFee account then remove the fee
        if(_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }

        if(!automatedMarketMakerPairs[to] && !automatedMarketMakerPairs[from]) takeFee = false;

        if(takeFee) {
            uint256 feeAmt;
            if(automatedMarketMakerPairs[to]) feeAmt = amount * totalSellTax / 100;
            else if(automatedMarketMakerPairs[from]) feeAmt = amount * totalBuyTax / 100;

            amount = amount - feeAmt;
            super._transfer(from, address(this), feeAmt);
        }
        super._transfer(from, to, amount);

        try dividendTracker.setBalance(from, balanceOf(from)) {} catch {}
        try dividendTracker.setBalance(to, balanceOf(to)) {} catch {}

    }

    function swapAndLiquify(uint256 tokens) private {
        // Split the contract balance into halves
        uint256 tokensToAddLiquidityWith = tokens / 2;
        uint256 toSwap = tokens - tokensToAddLiquidityWith;

        uint256 initialBalance = address(this).balance;

        swapTokensForETH(toSwap);

        uint256 ETHToAddLiquidityWith = address(this).balance - initialBalance;

        if(ETHToAddLiquidityWith > 0){
            // Add liquidity to pancake
            addLiquidity(tokensToAddLiquidityWith, ETHToAddLiquidityWith);
        }

        uint256 lpBalance = IERC20(pair).balanceOf(address(this));
        uint256 totalTax = (totalSellTax - sellTaxes.liquidity);

        // Send LP to treasuryWallet
        uint256 treasuryAmt = lpBalance * sellTaxes.treasury / totalTax;
        if(treasuryAmt > 0){
            IERC20(pair).transfer(treasuryWallet, treasuryAmt);
        }

        // Send LP to dev
        uint256 devAmt = lpBalance * sellTaxes.dev / totalTax;
        if(devAmt > 0){
            IERC20(pair).transfer(devWallet, devAmt);
        }

        //Send LP to dividends
        uint256 dividends = lpBalance * sellTaxes.rewards / totalTax;
        if(dividends > 0){
            bool success = IERC20(pair).transfer(address(dividendTracker), dividends);
            if (success) {
                dividendTracker.distributeLPDividends(dividends);
                emit SendDividends(tokens, dividends);
            }
        }
    }

    function swapTokensForETH(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        _approve(address(this), address(router), tokenAmount);

        // make the swap
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );

    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {

        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(router), tokenAmount);

        // add the liquidity
        router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(this),
            block.timestamp
        );

    }

}

contract VIRALDividendTracker is Ownable, DividendPayingToken {
    using Address for address payable;

    struct AccountInfo {
        address account;
        uint256 withdrawableDividends;
        uint256 totalDividends;
        uint256 lastClaimTime;
    }

    mapping (address => bool) public excludedFromDividends;

    mapping (address => uint256) public lastClaimTimes;

    event ExcludeFromDividends(address indexed account, bool value);
    event Claim(address indexed account, uint256 amount);

    constructor()  DividendPayingToken("VIRAL_Dividen_Tracker", "VIRAL_Dividend_Tracker") {}

    function trackerRescueETH20Tokens(address recipient, address tokenAddress) external onlyOwner{
        IERC20(tokenAddress).transfer(recipient, IERC20(tokenAddress).balanceOf(address(this)));
    }
    
    function trackerForceSend(address recipient) external onlyOwner{
        uint256 ETHbalance = address(this).balance;
        payable(recipient).sendValue(ETHbalance);
    }

    function updateLP_Token(address _lpToken) external onlyOwner{
        LP_Token = _lpToken;
    }

    function _transfer(address, address, uint256) internal pure override {
        require(false, "VIRAL_Dividend_Tracker: No transfers allowed");
    }
    

    function excludeFromDividends(address account, bool value) external onlyOwner {
        require(excludedFromDividends[account] != value);
        excludedFromDividends[account] = value;
      if(value == true){
        _setBalance(account, 0);
      }
      else{
        _setBalance(account, balanceOf(account));
      }
      emit ExcludeFromDividends(account, value);

    }

    function getAccount(address account) public view returns (address, uint256, uint256, uint256, uint256 ) {
        AccountInfo memory info;
        info.account = account;
        info.withdrawableDividends = withdrawableDividendOf(account);
        info.totalDividends = accumulativeDividendOf(account);
        info.lastClaimTime = lastClaimTimes[account];
        return (
            info.account,
            info.withdrawableDividends,
            info.totalDividends,
            info.lastClaimTime,
            totalDividendsWithdrawn
        );
        
    }

    function setBalance(address account, uint256 newBalance) external onlyOwner {
        if(excludedFromDividends[account]) {
            return;
        }
        _setBalance(account, newBalance);
    }

    function processAccount(address payable account) external onlyOwner returns (bool) {
        uint256 amount = _withdrawDividendOfUser(account);

        if(amount > 0) {
            lastClaimTimes[account] = block.timestamp;
            emit Claim(account, amount);
            return true;
        }
        return false;
    }
}