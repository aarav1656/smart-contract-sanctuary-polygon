/**
 *Submitted for verification at polygonscan.com on 2022-11-30
*/

// SPDX-License-Identifier: MIT
// Credits to OpenZeppelin
pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        //TODO: return address of the message sender
        return msg.sender; 
        // this is used to access msg.sender's address later instead of directly.
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

contract ERC20 is Context {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    // TODO: create a `Transfer` event
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 value
    ); // variables follow the requirements

    // TODO: create an `Approval` event
    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    constructor(string memory name_, string memory symbol_) {
        _name = name_; // used name from memory
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        //TODO: return token name set in the constructor
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        //TODO: return token symbol set in the constructor
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).

     */
    function decimals() public view virtual returns (uint8) {
        //TODO: return the value of decimals specified in README
        return 18; // as given by the coursework
    }

    /**
     * @dev Returns token total supply.
     */
    function totalSupply() public view virtual returns (uint256) {
        //TODO
        return _totalSupply;
    }

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) public view virtual returns (uint256) {
        //TODO
        return _balances[account];
    }

    /** TODO
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount)
        public
        virtual
        returns (bool)
    {
        // TODO use _transfer
        _transfer(_msgSender(), to, amount);
        // Actions, requirements, emissions are all in '_transfer' function.

        return true;
    }

    /** TODO
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     */
    function allowance(address owner, address spender)
        public
        view
        virtual
        returns (uint256)
    {
        //TODO
        return _allowances[owner][spender];
    }

    /** TODO
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount)
        public
        virtual
        returns (bool)
    {
        // TODO: use `_approve` defined later in the contract
        _approve(_msgSender(), spender, amount);
        // Actions, requirements, emissions are all in '_approve' function

        return true;
    }

    /** TODO
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
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
    ) public virtual returns (bool) {
        // TODO: use `_spendAllowance` and `_transfer` defined later in the contract
        _spendAllowance(from, _msgSender(), amount);
        _transfer(from, to, amount);

        // Actions, requirements, emissions are all done in '_transfer' and '_spendAllowance'

        return true;
    }

    /** TODO
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * Returns a boolean value indicating whether the operation succeded.
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        // TODO: use `_approve` defined later in the contract
        _approve(_msgSender(), spender, allowance(_msgSender(), spender) + addedValue);
        // Actions, requirements, emissions are all done in '_approve'

        return true;
    }

    /** TODO
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        // TODO: use `_approve` defined later in the contract
        // requirements:
        require(allowance(_msgSender(), spender) >= subtractedValue);

        // actions:
        _approve(_msgSender(), spender, allowance(_msgSender(), spender) - subtractedValue);

        return true;
    }

    /** TODO
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
        // TODO
        // requirements:
        require(from != address(0));
        require(to != address(0));
        require(_balances[from] >= amount);

        // actions:
        _balances[from] -= amount;
        _balances[to] += amount;

        // emission:
        emit Transfer(from, to, amount);
    }

    /** TODO
     @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        //TODO
        // requirement:
        require(account != address(0));

        // actions:
        _totalSupply += amount; // create tokens
        _balances[account] += amount; // assignment to 'account'

        // emissions:
        emit Transfer(address(0), account, amount);
    }

    /** TODO
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
        // TODO
        // requirements:
        require(account != address(0));
        require(_balances[account] >= amount);

        // actions:
        _totalSupply -= amount; // burn tokens
        _balances[account] -= amount; // remove from 'account'

        // emissions:
        emit Transfer(account, address(0), amount);
    }

    /** TODO
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens. (ok)
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event. (ok)
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address. (ok)
     * - `spender` cannot be the zero address. (ok)
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        // TODO
        // requirements:
        require(owner != address(0));
        require(spender != address(0));

        // action:
        _allowances[owner][spender] = amount; // under 'owner's control, 'spender's allowance to spend

        // emission:
        emit Approval(owner, spender, amount);
    }

    /** TODO
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`. (ok)
     *
     * Does not update the allowance amount in case of infinite allowance (ok)
     * (use `type(uint256).max` to approximate infinity).
     * Revert if not enough allowance is available. (ok)
     *
     * Might emit an {Approval} event. (ok. done in '_approve')
     */

    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(
                // TODO: must have enough currentAllowance to cover amount
                currentAllowance >= amount
            );
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }
}



/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
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

/**
 * @dev {ERC20} token, including:
 *
 *  - ability for holders to burn (destroy) their tokens
 *  - a minter role that allows for token minting (creation)
 *  - a pauser role that allows to stop all token transfers
 *
 */
contract LuckyToken is Context, ERC20Burnable {
    mapping(address => bool) _minters;

    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        _minters[_msgSender()] = true;
    }

    function hasMinterRole(address account) public view virtual returns (bool) {
        return _minters[account];
    }

    /**
     * @dev Creates `amount` new tokens for `to`.
     *
     * Requirements:
     *
     * - the caller must have the `MINTER_ROLE`.
     */
    function mint(address to, uint256 amount) public virtual {
        require(
            hasMinterRole(_msgSender()),
            "requester must have minter role to mint"
        );
        _mint(to, amount);
    }
}

contract LC0 is LuckyToken {
    // TODO: replace names
    constructor() LuckyToken("LuckyTokenXF", "LCXF") {}
}