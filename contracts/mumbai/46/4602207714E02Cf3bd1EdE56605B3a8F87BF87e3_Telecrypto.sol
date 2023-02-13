/**
 *Submitted for verification at polygonscan.com on 2023-02-12
*/

// SPDX-License-Identifier: MIT
// File: @chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol


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

// File: @pancakeswap/pancake-swap-lib/contracts/token/BEP20/IBEP20.sol



pragma solidity >=0.4.0;

interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

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
    function allowance(address _owner, address spender) external view returns (uint256);

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

// File: @openzeppelin/contracts/utils/math/SafeMath.sol


// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

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
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
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


// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol



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





// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;




/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
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
        _approve(owner, spender, allowance(owner, spender) + addedValue);
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
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
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
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

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
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
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
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

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
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
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

// File: contracts/Telecrypto.sol



pragma solidity ^0.8.17;





contract TOKEN is ERC20 {
    constructor() ERC20("TOKEN", "TK") {
        _mint(msg.sender, 111 * 10**decimals());
    }
}

contract Telecrypto {
    using SafeMath for uint256;

    IBEP20 private BEP20;
    address private Owner;
    address private Admin;
    address private WalletDev;
    string private luckynumbers;
    uint256 private nrgame;
    uint256 private TokenPrice;
    uint256[] private uints;
    bool private maintenance;

    AggregatorV3Interface internal priceFeed;

    //GAME
    struct Game {
        address wallet;
        uint256 ticketprice;
        string gamestate;
        uint256 sold;
        uint256 poolbalance;
    }
    mapping(uint256 => Game) games;

    struct Raffle {
        address[] winners;
        uint256[] tickets;
        uint256[] luckynumbers;
    }
    mapping(uint256 => Raffle) raffles;

    //EVENTS
    event BuyTicket(
        address indexed from,
        uint256 indexed nrgame,
        string luckynumbers,
        uint256 amount
    );
    event UpdateGameState(
        uint256 indexed nrgame,
        uint256 ticketprice,
        string gamestate,
        address walletpool
    );
    event UpdateGameWinner(
        uint256 indexed nrgame,
        string gamestate,
        address walletpool,
        address[] winners,
        uint256[] tickets
    );
    event UpdateDevAddress(address indexed from, address wallet);
    event UpdateAdminAddress(address indexed from, address wallet);
    event UpdateIBEP20(address indexed from, IBEP20 tokenaddr);
    event Deposit(address indexed from, uint256 indexed amount);
    event Withdraw(address indexed from, uint256 indexed amount);
    event EventRaffle(uint256 indexed nrgame, uint256[] luckynumbers);
    event Payment(
        uint256 indexed nrgame,
        address[] winners,
        uint256 prize,
        uint256 poolbalance
    );

    constructor() {
        Owner = msg.sender;
        Admin = msg.sender;
        WalletDev = msg.sender;
        TokenPrice = 0;
        maintenance = false;

        // BUSD TESTNET = 0xeD24FC36d5Ee211Ea25A80239Fb8C4Cfd80f12Ee
        // BUSD MAINNET = 0xe9e7cea3dedca5984780bafc599bd69add087d56
                        
        // MOMBAY USDC = 0xE097d6B3100777DC31B34dC2c58fB524C2e76921

        BEP20 = IBEP20(0xE097d6B3100777DC31B34dC2c58fB524C2e76921);
        
        // Aggregator: BNB/USD
        // TestAddress: 0x2514895c72f50D8bd4B4F9b1110F0D6bD2c97526
        // MainAddress: 0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE
         
        priceFeed = AggregatorV3Interface(
            0x2514895c72f50D8bd4B4F9b1110F0D6bD2c97526
        );

        for (uint256 i = 1; i <= 36; i++) {
            uints.push(i);
        }
    }

    //1 ETH = 1000000000000000000;
    function buyTicket(
        uint256 _nrgame,
        string memory _luckynumbers,
        uint256 _tokenamount
    ) public payable {
        require(maintenance == false, "Contract is under maintenance");

        uint256 totalwei = _tokenamount * (10**18);
        require(totalwei >= games[_nrgame].ticketprice, "tokens too small");

        string memory gstate = games[_nrgame].gamestate;
        require(
            keccak256(bytes(gstate)) == keccak256(bytes("open")),
            "this game is not open"
        );

        uint256 ShareDev = totalwei.div(10).mul(3);
        uint256 SharePool = totalwei.div(10).mul(7);

        address WalletPool = games[_nrgame].wallet;

        BEP20.transferFrom(msg.sender, WalletDev, ShareDev);
        BEP20.transferFrom(msg.sender, WalletPool, SharePool);

        nrgame = _nrgame;
        luckynumbers = _luckynumbers;
        games[_nrgame].sold = games[_nrgame].sold + 1;

        emit BuyTicket(msg.sender, nrgame, luckynumbers, totalwei);
    }

    function createGame(
        uint256 _nrgame,
        address _wallet,
        uint256 _ticketprice
    ) public {
        require(msg.sender == Admin, "Only admin can create games!");
        require(games[_nrgame].ticketprice == 0, "this game existis");

        games[_nrgame].wallet = _wallet;
        games[_nrgame].ticketprice = _ticketprice;
        games[_nrgame].gamestate = "open";
        games[_nrgame].sold = 0;

        emit UpdateGameState(_nrgame, _ticketprice, "open", _wallet);
    }

    function updateGame(uint256 _nrgame, string memory _gamestate) public {
        require(msg.sender == Admin, "Only admin can update games!");

        games[_nrgame].gamestate = _gamestate;

        emit UpdateGameState(
            _nrgame,
            games[_nrgame].ticketprice,
            games[_nrgame].gamestate,
            games[_nrgame].wallet
        );
    }

    function setGameWinner(
        uint256 _nrgame,
        address[] memory _winners,
        uint256[] memory _tickets
    ) public {
        require(msg.sender == Admin, "Only admin can set winner!");

        string memory gstate = games[_nrgame].gamestate;
        require(
            keccak256(bytes(gstate)) == keccak256(bytes("raffle")),
            "this game is not raffle"
        );

        games[_nrgame].gamestate = "completed";
        raffles[_nrgame].winners = _winners;
        raffles[_nrgame].tickets = _tickets;

        emit UpdateGameWinner(
            _nrgame,
            games[_nrgame].gamestate,
            games[_nrgame].wallet,
            raffles[_nrgame].winners,
            raffles[_nrgame].tickets
        );
    }

    function updateAdminAddress(address _wallet) external {
        require(msg.sender == Owner, "Only Owner can update Admin!");
        Admin = _wallet;

        emit UpdateAdminAddress(msg.sender, _wallet);
    }

    function updateDevAddress(address _wallet) external {
        require(msg.sender == Owner, "Only Owner can update Address!");
        WalletDev = _wallet;

        emit UpdateDevAddress(msg.sender, _wallet);
    }

    function updateIBEP20(IBEP20 _tokenaddr) external {
        require(msg.sender == Owner, "Only Owner can update Address!");
        BEP20 = _tokenaddr;

        emit UpdateIBEP20(msg.sender, _tokenaddr);
    }

    function updateTokenPrice() public {
        require(msg.sender == Admin, "Only admin can update!");
        (
            ,
            /*uint80 roundID*/
            int256 price, /*uint startedAt*/ /*uint timeStamp*/ /*uint80 answeredInRound*/
            ,
            ,

        ) = priceFeed.latestRoundData();
        TokenPrice = uint256(price) / 100000;
    }

    function setMaintenance(bool _active) public {
        require(msg.sender == Owner, "Only Owner can set Manintenance!");
        maintenance = _active;
    }

    function getGame(uint256 _nrgame) public view returns (Game memory) {
        return games[_nrgame];
    }

    function getRaffle(uint256 _nrgame) public view returns (Raffle memory) {
        return raffles[_nrgame];
    }

    function getPoolBalance(uint256 _nrgame) public view returns (uint256) {
        return BEP20.balanceOf(address(games[_nrgame].wallet));
    }

    function getGamePrize(uint256 _nrgame) public view returns (uint256) {
        uint256 poolBalance = BEP20.balanceOf(address(games[_nrgame].wallet));
        uint256 prizePool = poolBalance.div(20).mul(19); //95% POOL BALANCE

        return prizePool;
    }

    function deposit(uint256 _tokenamount) public {
        uint256 totalwei = _tokenamount * (10**18);
        BEP20.transferFrom(msg.sender, address(this), totalwei);

        emit Deposit(msg.sender, _tokenamount);
    }

    function withdraw(address _tokenaddr, uint256 _amount) public {
        
        // This function withdraws funds only from the contract and not from games. 
        // It is only used for maintenance situations. 
        // The game prize is stored in the pool wallet. 
        // This contract does not store funds.           
        
        require(msg.sender == Owner, "Only Owner can withdraw!");
        IBEP20(_tokenaddr);
        BEP20.transfer(msg.sender, _amount);

        emit Withdraw(msg.sender, _amount);
    }
    
    function shuffle() private view returns (uint256[] memory) {

        // This shuffle function works by creating a keccak256 hash of the current block.timestamp + a counter
        // to produce a different hash every time we need one.
        // Then, we use each byte as our value to generate the index we are going to swap the ith element with
        // by using the modulo (%) operator.
        // A keccak256 hash only has 32 bytes, so, in case the array we are trying to shuffle is bigger than
        // 32 elements, then we create a different keccak256 hash with the counter, and start taking each
        // byte of this new hash one by one to derive the index to swap the ith element with..
        // This function asumes that the array to shuffle is no bigger than 255 elements. If so,
        // then we would need to read 2 bytes instead of one. Because 1 byte only provides us 256 (2^8) values
        // to use as index, but 2 bytes would provide us with 65536 (2^16) values to use as index, which
        // we then cut it down to the range of our array using the % operator.

        uint256[] memory uintsCopy = uints;

        uint256 counter = 0;
        uint256 j = 0;
        bytes32 b32 = keccak256(
            abi.encodePacked(
                block.timestamp + block.number + TokenPrice + counter
            )
        );
        uint256 length = uintsCopy.length;

        for (uint256 i = 0; i < uintsCopy.length; i++) {
            if (j > 31) {
                b32 = keccak256(
                    abi.encodePacked(
                        block.timestamp + block.number + TokenPrice + ++counter
                    )
                );
                j = 0;
            }

            uint8 value = uint8(b32[j++]);

            uint256 n = value % length;

            uint256 temp = uintsCopy[n];
            uintsCopy[n] = uintsCopy[i];
            uintsCopy[i] = temp;
        }

        return uintsCopy;
    }

    function raffle(uint256 _nrgame) public {
        require(maintenance == false, "Contract is under maintenance");
        require(msg.sender == Admin, "Only admin can raffle!");

        string memory gstate = games[_nrgame].gamestate;
        require(
            keccak256(bytes(gstate)) == keccak256(bytes("closed")),
            "this game is not closed"
        );

        games[_nrgame].gamestate = "raffle";
        raffles[_nrgame].luckynumbers = shuffle();

        emit EventRaffle(_nrgame, raffles[_nrgame].luckynumbers);
    }

    function payGame(uint256 _nrgame) public payable {
        string memory gstate = games[_nrgame].gamestate;
        require(
            keccak256(bytes(gstate)) == keccak256(bytes("completed")),
            "this game is not completed"
        );

        require(msg.sender == games[_nrgame].wallet, "Only pool can pay!");

        uint256 poolBalance = BEP20.balanceOf(address(games[_nrgame].wallet));
        uint256 prizePool = poolBalance.div(20).mul(19); //95% PRIZE POOL - 5% MAINTENANCE TAX
        uint256 winnerPrize = prizePool.div(raffles[_nrgame].winners.length);

        for (uint256 i = 0; i < raffles[_nrgame].winners.length; i++) {
            BEP20.transferFrom(
                msg.sender,
                raffles[_nrgame].winners[i],
                winnerPrize
            );
        }

        games[_nrgame].gamestate = "payed";
        games[_nrgame].poolbalance = poolBalance;

        emit Payment(
            _nrgame,
            raffles[_nrgame].winners,
            winnerPrize,
            poolBalance
        );
    }
}