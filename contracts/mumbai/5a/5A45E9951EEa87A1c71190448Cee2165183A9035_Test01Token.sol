// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/extensions/ERC20Snapshot.sol)

pragma solidity ^0.8.0;

import "../ERC20.sol";
import "../../../utils/Arrays.sol";
import "../../../utils/Counters.sol";

/**
 * @dev This contract extends an ERC20 token with a snapshot mechanism. When a snapshot is created, the balances and
 * total supply at the time are recorded for later access.
 *
 * This can be used to safely create mechanisms based on token balances such as trustless dividends or weighted voting.
 * In naive implementations it's possible to perform a "double spend" attack by reusing the same balance from different
 * accounts. By using snapshots to calculate dividends or voting power, those attacks no longer apply. It can also be
 * used to create an efficient ERC20 forking mechanism.
 *
 * Snapshots are created by the internal {_snapshot} function, which will emit the {Snapshot} event and return a
 * snapshot id. To get the total supply at the time of a snapshot, call the function {totalSupplyAt} with the snapshot
 * id. To get the balance of an account at the time of a snapshot, call the {balanceOfAt} function with the snapshot id
 * and the account address.
 *
 * NOTE: Snapshot policy can be customized by overriding the {_getCurrentSnapshotId} method. For example, having it
 * return `block.number` will trigger the creation of snapshot at the beginning of each new block. When overriding this
 * function, be careful about the monotonicity of its result. Non-monotonic snapshot ids will break the contract.
 *
 * Implementing snapshots for every block using this method will incur significant gas costs. For a gas-efficient
 * alternative consider {ERC20Votes}.
 *
 * ==== Gas Costs
 *
 * Snapshots are efficient. Snapshot creation is _O(1)_. Retrieval of balances or total supply from a snapshot is _O(log
 * n)_ in the number of snapshots that have been created, although _n_ for a specific account will generally be much
 * smaller since identical balances in subsequent snapshots are stored as a single entry.
 *
 * There is a constant overhead for normal ERC20 transfers due to the additional snapshot bookkeeping. This overhead is
 * only significant for the first transfer that immediately follows a snapshot for a particular account. Subsequent
 * transfers will have normal cost until the next snapshot, and so on.
 */

abstract contract ERC20Snapshot is ERC20 {
    // Inspired by Jordi Baylina's MiniMeToken to record historical balances:
    // https://github.com/Giveth/minime/blob/ea04d950eea153a04c51fa510b068b9dded390cb/contracts/MiniMeToken.sol

    using Arrays for uint256[];
    using Counters for Counters.Counter;

    // Snapshotted values have arrays of ids and the value corresponding to that id. These could be an array of a
    // Snapshot struct, but that would impede usage of functions that work on an array.
    struct Snapshots {
        uint256[] ids;
        uint256[] values;
    }

    mapping(address => Snapshots) private _accountBalanceSnapshots;
    Snapshots private _totalSupplySnapshots;

    // Snapshot ids increase monotonically, with the first value being 1. An id of 0 is invalid.
    Counters.Counter private _currentSnapshotId;

    /**
     * @dev Emitted by {_snapshot} when a snapshot identified by `id` is created.
     */
    event Snapshot(uint256 id);

    /**
     * @dev Creates a new snapshot and returns its snapshot id.
     *
     * Emits a {Snapshot} event that contains the same id.
     *
     * {_snapshot} is `internal` and you have to decide how to expose it externally. Its usage may be restricted to a
     * set of accounts, for example using {AccessControl}, or it may be open to the public.
     *
     * [WARNING]
     * ====
     * While an open way of calling {_snapshot} is required for certain trust minimization mechanisms such as forking,
     * you must consider that it can potentially be used by attackers in two ways.
     *
     * First, it can be used to increase the cost of retrieval of values from snapshots, although it will grow
     * logarithmically thus rendering this attack ineffective in the long term. Second, it can be used to target
     * specific accounts and increase the cost of ERC20 transfers for them, in the ways specified in the Gas Costs
     * section above.
     *
     * We haven't measured the actual numbers; if this is something you're interested in please reach out to us.
     * ====
     */
    function _snapshot() internal virtual returns (uint256) {
        _currentSnapshotId.increment();

        uint256 currentId = _getCurrentSnapshotId();
        emit Snapshot(currentId);
        return currentId;
    }

    /**
     * @dev Get the current snapshotId
     */
    function _getCurrentSnapshotId() internal view virtual returns (uint256) {
        return _currentSnapshotId.current();
    }

    /**
     * @dev Retrieves the balance of `account` at the time `snapshotId` was created.
     */
    function balanceOfAt(address account, uint256 snapshotId) public view virtual returns (uint256) {
        (bool snapshotted, uint256 value) = _valueAt(snapshotId, _accountBalanceSnapshots[account]);

        return snapshotted ? value : balanceOf(account);
    }

    /**
     * @dev Retrieves the total supply at the time `snapshotId` was created.
     */
    function totalSupplyAt(uint256 snapshotId) public view virtual returns (uint256) {
        (bool snapshotted, uint256 value) = _valueAt(snapshotId, _totalSupplySnapshots);

        return snapshotted ? value : totalSupply();
    }

    // Update balance and/or total supply snapshots before the values are modified. This is implemented
    // in the _beforeTokenTransfer hook, which is executed for _mint, _burn, and _transfer operations.
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);

        if (from == address(0)) {
            // mint
            _updateAccountSnapshot(to);
            _updateTotalSupplySnapshot();
        } else if (to == address(0)) {
            // burn
            _updateAccountSnapshot(from);
            _updateTotalSupplySnapshot();
        } else {
            // transfer
            _updateAccountSnapshot(from);
            _updateAccountSnapshot(to);
        }
    }

    function _valueAt(uint256 snapshotId, Snapshots storage snapshots) private view returns (bool, uint256) {
        require(snapshotId > 0, "ERC20Snapshot: id is 0");
        require(snapshotId <= _getCurrentSnapshotId(), "ERC20Snapshot: nonexistent id");

        // When a valid snapshot is queried, there are three possibilities:
        //  a) The queried value was not modified after the snapshot was taken. Therefore, a snapshot entry was never
        //  created for this id, and all stored snapshot ids are smaller than the requested one. The value that corresponds
        //  to this id is the current one.
        //  b) The queried value was modified after the snapshot was taken. Therefore, there will be an entry with the
        //  requested id, and its value is the one to return.
        //  c) More snapshots were created after the requested one, and the queried value was later modified. There will be
        //  no entry for the requested id: the value that corresponds to it is that of the smallest snapshot id that is
        //  larger than the requested one.
        //
        // In summary, we need to find an element in an array, returning the index of the smallest value that is larger if
        // it is not found, unless said value doesn't exist (e.g. when all values are smaller). Arrays.findUpperBound does
        // exactly this.

        uint256 index = snapshots.ids.findUpperBound(snapshotId);

        if (index == snapshots.ids.length) {
            return (false, 0);
        } else {
            return (true, snapshots.values[index]);
        }
    }

    function _updateAccountSnapshot(address account) private {
        _updateSnapshot(_accountBalanceSnapshots[account], balanceOf(account));
    }

    function _updateTotalSupplySnapshot() private {
        _updateSnapshot(_totalSupplySnapshots, totalSupply());
    }

    function _updateSnapshot(Snapshots storage snapshots, uint256 currentValue) private {
        uint256 currentId = _getCurrentSnapshotId();
        if (_lastSnapshotId(snapshots.ids) < currentId) {
            snapshots.ids.push(currentId);
            snapshots.values.push(currentValue);
        }
    }

    function _lastSnapshotId(uint256[] storage ids) private view returns (uint256) {
        if (ids.length == 0) {
            return 0;
        } else {
            return ids[ids.length - 1];
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Arrays.sol)

pragma solidity ^0.8.0;

import "./StorageSlot.sol";
import "./math/Math.sol";

/**
 * @dev Collection of functions related to array types.
 */
library Arrays {
    using StorageSlot for bytes32;

    /**
     * @dev Searches a sorted `array` and returns the first index that contains
     * a value greater or equal to `element`. If no such index exists (i.e. all
     * values in the array are strictly less than `element`), the array length is
     * returned. Time complexity O(log n).
     *
     * `array` is expected to be sorted in ascending order, and to contain no
     * repeated elements.
     */
    function findUpperBound(uint256[] storage array, uint256 element) internal view returns (uint256) {
        if (array.length == 0) {
            return 0;
        }

        uint256 low = 0;
        uint256 high = array.length;

        while (low < high) {
            uint256 mid = Math.average(low, high);

            // Note that mid will always be strictly less than high (i.e. it will be a valid array index)
            // because Math.average rounds down (it does integer division with truncation).
            if (unsafeAccess(array, mid).value > element) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }

        // At this point `low` is the exclusive upper bound. We will return the inclusive upper bound.
        if (low > 0 && unsafeAccess(array, low - 1).value == element) {
            return low - 1;
        } else {
            return low;
        }
    }

    /**
     * @dev Access an array in an "unsafe" way. Skips solidity "index-out-of-range" check.
     *
     * WARNING: Only use if you are certain `pos` is lower than the array length.
     */
    function unsafeAccess(address[] storage arr, uint256 pos) internal pure returns (StorageSlot.AddressSlot storage) {
        bytes32 slot;
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0, arr.slot)
            slot := add(keccak256(0, 0x20), pos)
        }
        return slot.getAddressSlot();
    }

    /**
     * @dev Access an array in an "unsafe" way. Skips solidity "index-out-of-range" check.
     *
     * WARNING: Only use if you are certain `pos` is lower than the array length.
     */
    function unsafeAccess(bytes32[] storage arr, uint256 pos) internal pure returns (StorageSlot.Bytes32Slot storage) {
        bytes32 slot;
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0, arr.slot)
            slot := add(keccak256(0, 0x20), pos)
        }
        return slot.getBytes32Slot();
    }

    /**
     * @dev Access an array in an "unsafe" way. Skips solidity "index-out-of-range" check.
     *
     * WARNING: Only use if you are certain `pos` is lower than the array length.
     */
    function unsafeAccess(uint256[] storage arr, uint256 pos) internal pure returns (StorageSlot.Uint256Slot storage) {
        bytes32 slot;
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0, arr.slot)
            slot := add(keccak256(0, 0x20), pos)
        }
        return slot.getUint256Slot();
    }
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }
}

/* SPDX-License-Identifier: UNLICENSED */
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Snapshot.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "../../libraries/BokkyPooBahsDateTimeLibrary.sol";
import "../../libraries/MathLibrary.sol";
import "../../interfaces/IOffer.sol";

contract Test01Token is ERC20Snapshot, Ownable {
    string public constant TEXT__FIELD = "EMPRESA TESTE";
    string public constant TEXT__FIELD__1 = "CNPJ:00.000.000/0000-00";
    uint256 public constant TOTAL_TOKENS = 14538.8 * 1 ether; //Quantidade de tokens a serem vendidos
    string public constant DOCUMENT = "";
    uint256 public constant DAILY_DISCOUNT_RATE = 0.04306335382293636 * 1 ether;
    uint256 public constant TOKEN_BASE_RATE = 2500; //R$ 25,00 por token
    uint256 public constant DATE_INTEREST_START = 1663729200;
    uint256[] private PERIOD_VALUES = [36914748 * 1 ether];
    uint256[] private PERIOD_DATES = [1666843200];
    address public constant OWNER = 0xdF3e9705F59e544aaa16d9407B2F58A6D808229c;
    // Name of the token
    string public constant TOKEN_NAME = "Test01Token";
    // Symbol of the token
    string public constant TOKEN_SYMBOL = "T01";

    using SafeMath for uint256;
    // Index of the last token snapshot
    uint256 private nCurrentSnapshotId;
    // Reference to the token the dividends are paid in
    IERC20 private dividendsToken;
    // A flag marking if the payment was completed
    bool private bCompletedPayment;
    // Total amount of input tokens paid to holders
    uint256 private nTotalDividendsPaid;
    // Map of investor to last payment snapshot index
    mapping(address => uint256) private mapLastPaymentSnapshot;
    // Map of snapshot index to dividend date
    mapping(uint256 => uint256) private mapPaymentDate;
    uint256 private nStatus;
    // Total amount of interest
    uint256 private nTotalInterest;
    uint256 private nTotalTokens;
    uint256 private nTotalValue;
    uint256 private nTotalDiscountedValue;
    // State of contract initialization
    bool private bInitialized;
    uint256[] private arrInterests;
    uint256[] private arrDiscountedValue;
    using Counters for Counters.Counter;
    // A map of the offer index to the start date
    mapping(uint256 => uint256) internal mapOfferStartDate;
    // A map of the offer index to the offer object
    mapping(uint256 => IOffer) internal mapOffers;
    // A map of the investor to the last cashout he did
    mapping(address => uint256) internal mapLastCashout;
    // An internal counter to keep track of the offers
    Counters.Counter internal counterTotalOffers;
    // Address of the issuer
    address internal aIssuer;
    // A fuse to disable the exchangeBalance function
    bool internal bDisabledExchangeBalance;

    constructor(
        address _issuer, //Emissor
        address _dividendsToken //Token de dividendos
    ) public ERC20(TOKEN_NAME, TOKEN_SYMBOL) {
        require(_dividendsToken != address(0), "Dividends token cant be zero");

        require(
            PERIOD_VALUES.length == PERIOD_DATES.length,
            "Values and dates must have the same size"
        );

        dividendsToken = IERC20(_dividendsToken);

        uint256 nBalance = dividendsToken.balanceOf(address(this));

        require(nBalance == 0, "Contract must have no balance");

        require(_issuer != address(0));

        aIssuer = _issuer;
    }

    /**
    * Returns true if the provided timestamp is the last day in February
    */
    function isFebLastDay(uint256 _timestamp) public pure returns (bool) {
        (uint256 nTimeYear, uint256 nTimeMonth, uint256 nTimeDay) = BokkyPooBahsDateTimeLibrary.timestampToDate(_timestamp);
        if (nTimeMonth == 2) {
            uint256 nFebDays = BokkyPooBahsDateTimeLibrary._getDaysInMonth(
                nTimeYear,
                nTimeMonth
            );

            return nTimeDay == nFebDays;
        }

        return false;
    }

    /**
    * Returns how many days there are between _startDate and _endDate, considering that a year has 360 days.
    */
    function days360(uint256 _startDate, uint256 _endDate, bool _method) public pure returns (uint256) {
        (uint256 nStartYear, uint256 nStartMonth, uint256 nStartDay) = BokkyPooBahsDateTimeLibrary.timestampToDate(_startDate);
        (uint256 nEndYear, uint256 nEndMonth, uint256 nEndDay) = BokkyPooBahsDateTimeLibrary.timestampToDate(_endDate);
        if (_method) {
            nStartDay = Math.min(nStartDay, 30);
            nEndDay = Math.min(nEndDay, 30);
        } else {
            // If both date A and B fall on the last day of February, then date B will be changed to
            // the 30th (unless preserving Excel compatibility)
            bool bIsStartLast = isFebLastDay(nStartDay);
            if (bIsStartLast && isFebLastDay(nEndDay)) {
                nEndDay = 30;
            }
            // If date A falls on the 31st of a month or last day of February, then date A will be changed
            // to the 30th.
            if (bIsStartLast || nStartDay == 31) {
                nStartDay = 30;
            }
            // If date A falls on the 30th of a month after applying (2) above and date B falls on the
            // 31st of a month, then date B will be changed to the 30th.
            if (nStartDay == 30 && nEndDay == 31) {
                nEndDay = 30;
            }
        }
        return
        ((nEndYear - nStartYear) * 360) +
        ((nEndMonth - nStartMonth) * 30) +
        (nEndDay - nStartDay);
    }

    /**
    * Executada até o contrato ser inicializado,
    * faz a emissão dos tokens de acordo com as constantes definidas no contrato e
    * calcula os dados a serem utilizados por funcões de referência
    */
    function initialize() public {
        require(!bInitialized, "Contract is already initialized");
        uint256 PAGE_DIVISION = 20;
        uint256 nPages = Math.max(1, PERIOD_VALUES.length / PAGE_DIVISION);
        // convert the discount rate from 0-1 to 0-100
        uint256 nDailyDiscount = DAILY_DISCOUNT_RATE + 100 ether;
        uint256 nStartIndex = PAGE_DIVISION * nStatus;
        uint256 nFinalIndex = Math.min(
            nStartIndex + PAGE_DIVISION,
            PERIOD_VALUES.length
        );

        if (nStatus < nPages + 1) {
            for (uint256 i = nStartIndex; i < nFinalIndex; i++) {
                uint256 nPeriodValue = PERIOD_VALUES[i];
                uint256 nPeriodDate = PERIOD_DATES[i];
                uint256 nDays = days360(
                    DATE_INTEREST_START,
                    nPeriodDate,
                    false
                );
                // total discount = daily discount ^ number of days
                uint256 nDiscountRate = nDailyDiscount;
                for (uint256 j = 1; j < nDays; j++) {
                    nDiscountRate = nDiscountRate * nDailyDiscount;
                    nDiscountRate = nDiscountRate / 100 ether;
                }
                uint256 nDiscountedValue = nPeriodValue * 1 ether;
                nDiscountedValue = (nDiscountedValue / nDiscountRate) * 100;
                arrDiscountedValue.push(nDiscountedValue);
                nTotalValue = nTotalValue.add(nPeriodValue);
                nTotalDiscountedValue = nTotalDiscountedValue.add(
                    nDiscountedValue
                );
                // divide the discount value by the token value to get the amount of tokens this period is worth
                nTotalTokens = nTotalTokens.add(
                    nDiscountedValue.div(TOKEN_BASE_RATE)
                );
            }
            nStatus = nStatus.add(1);
        } else {
            _mint(aIssuer, nTotalTokens);
            uint256 nTotalInterestValue = nTotalValue.sub(
                nTotalDiscountedValue
            );
            uint256 nTotalInterestPC = Math.mulDiv(
                nTotalValue,
                100 ether,
                nTotalDiscountedValue
            );
            nTotalInterestPC = nTotalInterestPC.sub(100 ether);
            for (uint8 i = 0; i < PERIOD_VALUES.length; i++) {
                uint256 nPeriodValue = PERIOD_VALUES[i];
                uint256 nDiscountedValue = arrDiscountedValue[i];
                uint256 nPeriodInterestValue = nPeriodValue.sub(
                    nDiscountedValue
                );
                uint256 nPeriodInterestTotalPC = Math.mulDiv(
                    nPeriodInterestValue,
                    100 ether,
                    nTotalInterestValue
                );
                uint256 nPeriodInterestPC = Math.mulDiv(
                    nPeriodInterestTotalPC,
                    nTotalInterestPC,
                    100 ether
                );
                arrInterests.push(nPeriodInterestPC);
                nTotalInterest = nTotalInterest.add(nPeriodInterestPC);
            }
            bInitialized = true;
        }
    }

    /**
    * Returns the discount rate for a 30-day period
    */
    function getMonthlyDiscountRate() public pure returns (uint256) {
        uint256 nDailyDiscount = DAILY_DISCOUNT_RATE + 100 ether;
        uint256 nDiscountRate = nDailyDiscount;
        for (uint8 j = 1; j < 30; j++) {
            nDiscountRate = nDiscountRate * nDailyDiscount;
            nDiscountRate = nDiscountRate.div(100 ether);
        }
        return nDiscountRate.sub(100 ether);
    }

    /**
    * Chamado para pagar dividendos para os token holders.
    * Antes de ser chamado, é necessário chamar increaseAllowance() com no minimo o valor da próxima parcela
    */
    function payDividends() public onlyOwner {
        require(bInitialized, "Contract isn't initialized");
        require(!bCompletedPayment, "Dividends payment is already completed");
        // grab our current allowance
        uint256 nAllowance = dividendsToken.allowance(
            _msgSender(),
            address(this)
        );
        // get the amount needed to pay
        uint256 nPaymentValue = PERIOD_VALUES[nCurrentSnapshotId];
        // make sure we are allowed to transfer the total payment value
        require(
            nPaymentValue <= nAllowance,
            "Not enough allowance to pay dividends"
        );
        // increase the total amount paid
        nTotalDividendsPaid = nTotalDividendsPaid.add(nPaymentValue);
        // transfer the tokens from the sender to the contract
        dividendsToken.transferFrom(_msgSender(), address(this), nPaymentValue);
        // snapshot the tokens at the moment the ether enters
        nCurrentSnapshotId = _snapshot();
        // check if we have paid everything
        if (nCurrentSnapshotId == PERIOD_VALUES.length) {
            bCompletedPayment = true;
        }
        // save the date
        mapPaymentDate[nCurrentSnapshotId] = block.timestamp;
    }

    function payDividendsMultiple(uint256 _count) public onlyOwner {
        for (uint256 i = 0; i < _count; i++) {
            payDividends();
        }
    }

    /**
    * Withdraws dividends up to 16 times for the calling user
    */
    function withdrawDividends() public {
        address aSender = _msgSender();
        require(_withdrawDividends(aSender), "No new withdrawal");
        for (uint256 i = 0; i < 15; i++) {
            if (!_withdrawDividends(aSender)) {
                return;
            }
        }
    }

    /**
    * Withdraws only 1 dividend for the calling user
    */
    function withdrawDividend() public {
        address aSender = _msgSender();
        require(_withdrawDividends(aSender), "No new withdrawal");
    }

    /**
    * Withdraws dividends up to 16 times for the specified user
    */
    function withdrawDividendsAny(address _investor) public {
        require(_withdrawDividends(_investor), "No new withdrawal");
        for (uint256 i = 0; i < 15; i++) {
            if (!_withdrawDividends(_investor)) {
                return;
            }
        }
    }

    /**
    * @dev Withdraws only 1 dividend for the specified user
    */
    function withdrawDividendAny(address _investor) public {
        require(_withdrawDividends(_investor), "No new withdrawal");
    }

    /**
    * @dev Returns the value of the next payment
    */
    function getNextPaymentValue() public view returns (uint256) {
        if (bCompletedPayment) {
            return 0;
        }
        return PERIOD_VALUES[nCurrentSnapshotId];
    }

    function getDividends(address _aInvestor, uint256 _nPaymentIndex) public view returns (uint256) {
        // get the balance of the user at this snapshot
        uint256 nTokenBalance = balanceOfAt(_aInvestor, _nPaymentIndex);
        // get the date the payment entered the system
        uint256 nPaymentDate = mapPaymentDate[_nPaymentIndex];
        // get the total amount of balance this user has in offers
        uint256 nTotalOffers = getTotalInOffers(nPaymentDate, _aInvestor);
        // add the total amount the user has in offers
        nTokenBalance = nTokenBalance.add(nTotalOffers);
        if (nTokenBalance == 0) {
            return 0;
        } else {
            // get the total supply at this snapshot
            uint256 nTokenSuppy = totalSupplyAt(_nPaymentIndex);
            // get value from index
            uint256 nPaymentValue = PERIOD_VALUES[_nPaymentIndex - 1];
            // calculate how much he'll receive from this lot,
            // based on the amount of tokens he was holding
            uint256 nToReceive = Math.mulDiv(
                nTokenBalance,
                nPaymentValue,
                nTokenSuppy
            );
            return nToReceive;
        }
    }

    /**
    * Gets the total amount of dividends for an investor
    */
    function getTotalDividends(address _investor) public view returns (uint256) {
        // start total balance 0
        uint256 nBalance = 0;
        // get the last payment index for the investor
        uint256 nLastPayment = mapLastPaymentSnapshot[_investor];
        // add 16 as the limit
        uint256 nEndPayment = Math.min(
            nLastPayment.add(16),
            nCurrentSnapshotId.add(1)
        );
        // loop
        for (uint256 i = nLastPayment.add(1); i < nEndPayment; i++) {
            // add the balance that would be withdrawn if called for this index
            nBalance = nBalance.add(getDividends(_investor, i));
        }
        return nBalance;
    }

    /**
    * Based on how many tokens the user had at the snapshot,
    * pay dividends of the erc20 token
    * (also pays for tokens inside offer)
    */
    function _withdrawDividends(address _sender) private returns (bool) {
        require(bInitialized, "Contract isn't initialized");
        // read the last payment
        uint256 nLastUserPayment = mapLastPaymentSnapshot[_sender];
        // make sure we have a next payment
        if (nLastUserPayment >= nCurrentSnapshotId) {
            return false;
        }
        // add 1 to get the next payment
        uint256 nNextUserPayment = nLastUserPayment.add(1);
        // save back that we have paid this user
        mapLastPaymentSnapshot[_sender] = nNextUserPayment;
        // get the balance of the user at this snapshot
        uint256 nTokenBalance = balanceOfAt(_sender, nNextUserPayment);
        // get the date the payment entered the system
        uint256 nPaymentDate = mapPaymentDate[nNextUserPayment];
        // get the total amount of balance this user has in offers
        uint256 nBalanceInOffers = getTotalInOffers(nPaymentDate, _sender);
        // add the total amount the user has in offers
        nTokenBalance = nTokenBalance.add(nBalanceInOffers);
        if (nTokenBalance != 0) {
            // get the total supply at this snapshot
            uint256 nTokenSupply = totalSupplyAt(nNextUserPayment);
            // get value from index
            uint256 nPaymentValue = PERIOD_VALUES[nLastUserPayment];
            // calculate how much he'll receive from this lot,
            // based on the amount of tokens he was holding
            uint256 nToReceive = Math.mulDiv(
                nTokenBalance,
                nPaymentValue,
                nTokenSupply
            );
            // send the ERC20 value to the user
            dividendsToken.transfer(_sender, nToReceive);
        }
        return true;
    }

    /**
    * Retorna o valor que será pago ao contrato
    */
    function getTotalValue() public view returns (uint256) {
        return nTotalValue;
    }

    /**
    * Retorna o valor descontado
    */
    function getTotalDiscountedValue() public view returns (uint256) {
        return nTotalDiscountedValue;
    }

    /**
    * Retorna o valor total menos o descontado
    */
    function getTotalInterestValue() public view returns (uint256) {
        return nTotalValue.sub(nTotalDiscountedValue);
    }

    /**
    * Retorna true se a função initialize foi executada todas as vezes necessárias
    */
    function getInitialized() public view returns (bool) {
        return bInitialized;
    }

    /**
    * Retorna o endereço do token de dividendos - Smart Token BRL
    */
    function getDividendsToken() public view returns (address) {
        return address(dividendsToken);
    }

    /**
    * Retorna a quantidade total de pagamentos efetuados até agora
    */
    function getTotalDividendPayments() public view returns (uint256) {
        return nCurrentSnapshotId;
    }

    /**
    * Retorna a quantidade total de tokens pagos a esse contrato
    */
    function getTotalDividendsPaid() public view returns (uint256) {
        return nTotalDividendsPaid;
    }

    /**
    * Retorna true se o pagamento de todas as parcelas tiverem sido efetuados
    */
    function getCompletedPayment() public view returns (bool) {
        return bCompletedPayment;
    }

    /**
    * Retorna a data de pagamento da parcela especificada
    */
    function getPaymentDate(uint256 _nIndex) public view returns (uint256) {
        return mapPaymentDate[_nIndex];
    }

    /**
    * Retorna a valor de pagamento da parcela especificada
    */
    function getPaymentValue(uint256 _nIndex) public view returns (uint256) {
        return PERIOD_VALUES[_nIndex];
    }

    /**
    * Retorna a data do período
    */
    function getPeriodDate(uint256 _nIndex) public view returns (uint256) {
        return PERIOD_DATES[_nIndex];
    }

    /**
    * Retorna o último pagamento feito ao investidor especificado
    */
    function getLastPayment(address _aInvestor) public view returns (uint256) {
        return mapLastPaymentSnapshot[_aInvestor];
    }

    /**
    * Retorna a quantidade de parcelas
    */
    function getPaymentCount() public view returns (uint256) {
        return PERIOD_VALUES.length;
    }

    /**
    * Retorna a porcentagem de interesse de todos os pagamentos
    */
    function getTotalInterest() public view returns (uint256) {
        return nTotalInterest;
    }

    /**
    * Retorna a porcentagem de interesse gerada até agora
    */
    function getCurrentLinearInterest() public view returns (uint256) {
        return getLinearInterest(block.timestamp);
    }

    /**
    * Gets current percent based in period
    * Retorna a porcentagem de interesse gerada até a data especificada
    */
    function getLinearInterest(uint256 _nPaymentDate) public view returns (uint256) {
        if (_nPaymentDate < DATE_INTEREST_START) {
            return 0;
        }
        uint256 nInterest = 0;
        // loop all dates
        for (uint8 i = 0; i < PERIOD_DATES.length; i++) {
            uint256 nPeriodInterest = arrInterests[i];
            uint256 nPeriodDate = PERIOD_DATES[i];
            if (_nPaymentDate >= nPeriodDate) {
                // if after the payment date, all interest is already generated
                nInterest += nPeriodInterest;
            } else {
                // calculate the day difference
                uint256 nTotalDays = nPeriodDate.sub(DATE_INTEREST_START);
                uint256 nCurrentDays = nTotalDays.sub(
                    nPeriodDate.sub(_nPaymentDate)
                );
                uint256 nDifInterest = Math.mulDiv(
                    nCurrentDays.mul(1 ether),
                    nPeriodInterest.mul(1 ether),
                    nTotalDays.mul(1 ether)
                );
                nInterest += nDifInterest.div(1 ether);
            }
        }
        return nInterest;
    }

    /**
    * Gets the total amount of interest paid so far
    * Retorna a porcentagem de interesse paga até agora
    */
    function getPaidInterest() public view returns (uint256) {
        if (bCompletedPayment) {
            return nTotalInterest;
        }
        return getInterest(nCurrentSnapshotId);
    }

    /**
    * Gets the total amount of interest up to the specified index
    * Retorna a porcentagem de interesse paga até o índice especificado
    */
    function getInterest(uint256 _nPaymentIndex) public view returns (uint256) {
        uint256 nInterest = 0;
        // loop all dates
        uint256 nLast = Math.min(_nPaymentIndex, PERIOD_VALUES.length);
        for (uint8 i = 0; i < nLast; i++) {
            uint256 nPeriodInterest = arrInterests[i];
            nInterest = nInterest.add(nPeriodInterest);
        }
        return nInterest;
    }

    /**
    * Gets the amount of interest the specified period pays
    * Retorna a porcentagem de interesse que o periodo especificado paga
    */
    function getPeriodInterest(uint256 _nPeriod) public view returns (uint256) {
        if (_nPeriod >= arrInterests.length) {
            return 0;
        }
        return arrInterests[_nPeriod];
    }

    /**
    * Returns the current token value
    * Retorna o valor do token linear até agora
    */
    function getCurrentLinearTokenValue() public view returns (uint256) {
        return getLinearTokenValue(block.timestamp);
    }

    /**
    * Gets current token value based in period
    * Retorna o valor do token linear até a data especificada
    */
    function getLinearTokenValue(uint256 _nPaymentDate) public view returns (uint256) {
        if (_nPaymentDate <= DATE_INTEREST_START) {
            return TOKEN_BASE_RATE;
        }
        uint256 nTokenValue = 0;
        // loop all dates
        for (uint8 i = 0; i < PERIOD_DATES.length; i++) {
            uint256 nPeriodInterest = arrInterests[i];
            uint256 nPeriodDate = PERIOD_DATES[i];
            uint256 nInterest = 0;
            if (_nPaymentDate >= nPeriodDate) {
                // if after the payment date, all interest is already generated
                nInterest = nPeriodInterest;
            } else {
                // calculate the day difference
                uint256 nTotalDays = nPeriodDate.sub(DATE_INTEREST_START);
                uint256 nCurrentDays = nTotalDays.sub(
                    nPeriodDate.sub(_nPaymentDate)
                );
                uint256 nDifInterest = Math.mulDiv(
                    nCurrentDays.mul(1 ether),
                    nPeriodInterest.mul(1 ether),
                    nTotalDays.mul(1 ether)
                );
                nInterest = nDifInterest.div(1 ether);
            }
            uint256 nPeriodInterestTotalPC = Math.mulDiv(
                nInterest,
                100 ether,
                nTotalInterest
            );
            uint256 nTokenLinear = Math.mulDiv(
                TOKEN_BASE_RATE,
                nPeriodInterestTotalPC,
                100 ether
            );
            nTokenValue = nTokenValue.add(nTokenLinear);
        }
        return TOKEN_BASE_RATE.sub(nTokenValue);
    }

    /**
    * Gets the value of the token up to the current payment index
    * Retorna o valor do token até o ultimo pagamento efetuado pelo emissor
    */
    function getCurrentTokenValue() public view returns (uint256) {
        return getTokenValue(nCurrentSnapshotId);
    }

    /**
    * Gets the value of the token up to the specified payment index
    * Retorna o valor do token até o pagamento especificado
    */
    function getTokenValue(uint256 _nPaymentIndex) public view returns (uint256) {
        if (_nPaymentIndex == 0) {
            return TOKEN_BASE_RATE;
        } else if (_nPaymentIndex >= PERIOD_VALUES.length) {
            return 0;
        }
        uint256 nTokenValue = 0;
        for (uint8 i = 0; i < _nPaymentIndex; i++) {
            uint256 nInterest = arrInterests[i];
            uint256 nPeriodInterestTotalPC = Math.mulDiv(
                nInterest,
                100 ether,
                nTotalInterest
            );
            uint256 nTokenLinear = Math.mulDiv(
                TOKEN_BASE_RATE,
                nPeriodInterestTotalPC,
                100 ether
            );
            nTokenValue = nTokenValue.add(nTokenLinear);
        }
        return TOKEN_BASE_RATE.sub(nTokenValue);
    }

    /**
    * Registers a offer on the token
    * Método para iniciar uma oferta de venda de token Smart Token (parte do sistema interno de deployment)
    */
    function startOffer(address _aTokenOffer) public onlyOwner returns (uint256) {
        // make sure the address isn't empty
        require(_aTokenOffer != address(0), "Offer cant be empty");
        // convert the offer to a interface
        IOffer objOffer = IOffer(_aTokenOffer);
        // make sure the offer is intiialized
        require(!objOffer.getInitialized(), "Offer should not be initialized");
        // gets the index of the last offer, if it exists
        uint256 nLastId = counterTotalOffers.current();
        // check if its the first offer
        if (nLastId != 0) {
            // get a reference to the last offer
            IOffer objLastOFfer = IOffer(mapOffers[nLastId]);
            // make sure the last offer is finished
            require(objLastOFfer.getFinished(), "Offer should be finished");
        }
        // increment the total of offers
        counterTotalOffers.increment();
        // gets the current offer index
        uint256 nCurrentId = counterTotalOffers.current();
        // save the address of the offer
        mapOffers[nCurrentId] = objOffer;
        // save the date the offer should be considered for dividends
        mapOfferStartDate[nCurrentId] = block.timestamp;
        // initialize the offer
        objOffer.initialize();
        return nCurrentId;
    }

    /**
    * Try to cashout up to 5 times
    * Faz o cashout de até 6 compras de tokens na(s) oferta(s), para a carteira especificada
    */
    function cashoutFrozenMultipleAny(address aSender) public {
        bool bHasCashout = cashoutFrozenAny(aSender);
        require(bHasCashout, "No cashouts available");
        for (uint256 i = 0; i < 5; i++) {
            if (!cashoutFrozenAny(aSender)) {
                return;
            }
        }
    }

    /**
    * Main cashout function, cashouts up to 16 times
    * Faz o cashout de até 6 compras de tokens na(s) oferta(s), para a carteira que chama essa função
    */
    function cashoutFrozen() public {
        // cache the sender
        address aSender = _msgSender();
        // try to do 10 cashouts
        cashoutFrozenMultipleAny(aSender);
    }

    /**
    * Faz o cashout de apenas 1 compra para o endereço especificado.
    * Retorna true se mudar o estado do contrato.
    */
    function cashoutFrozenAny(address _account) public virtual returns (bool) {
        // get the latest token sale that was cashed out
        uint256 nCurSnapshotId = counterTotalOffers.current();
        // get the last token sale that this user cashed out
        uint256 nLastCashout = mapLastCashout[_account];
        // return if its the latest offer
        if (nCurSnapshotId <= nLastCashout) {
            return false;
        }
        // add 1 to get the next payment index
        uint256 nNextCashoutIndex = nLastCashout.add(1);
        // get the address of the offer this user is cashing out
        IOffer offer = mapOffers[nNextCashoutIndex];
        // cashout the tokens, if the offer allows
        bool bOfferCashout = offer.cashoutTokens(_account);
        // check if the sale is finished
        if (offer.getFinished()) {
            // save that it was cashed out, if the offer is over
            mapLastCashout[_account] = nNextCashoutIndex;
            return true;
        }
        return bOfferCashout;
    }

    /**
    * Returns the total amount of tokens the caller has in offers, up to _nPaymentDate
    * Calcula quantos tokens o endereço tem dentro de ofertas com sucesso (possíveis de saque) até a data de pagamento especificada
    */
    function getTotalInOffers(uint256 _nPaymentDate, address _aInvestor) public view returns (uint256) {
        // start the final balance as 0
        uint256 nBalance = 0;
        // get the latest offer index
        uint256 nCurrent = counterTotalOffers.current();
        for (uint256 i = 1; i <= nCurrent; i++) {
            // get offer start date
            uint256 nOfferDate = getOfferDate(i);
            // break if the offer started after the payment date
            if (nOfferDate >= _nPaymentDate) {
                break;
            }
            // grab the offer from the map
            IOffer objOffer = mapOffers[i];
            // only get if offer is finished
            if (!objOffer.getFinished()) {
                break;
            }
            if (!objOffer.getSuccess()) {
                continue;
            }
            // get the total amount the user bought at the offer
            uint256 nAddBalance = objOffer.getTotalBoughtDate(
                _aInvestor,
                _nPaymentDate
            );
            // get the total amount the user cashed out at the offer
            uint256 nRmvBalance = objOffer.getTotalCashedOutDate(
                _aInvestor,
                _nPaymentDate
            );
            // add the bought and remove the cashed out
            nBalance = nBalance.add(nAddBalance).sub(nRmvBalance);
        }
        return nBalance;
    }

    /**
    * Get the date the offer of the _index started
    * Retorna a data de inicio da oferta especificada
    */
    function getOfferDate(uint256 _index) public view returns (uint256) {
        return mapOfferStartDate[_index];
    }

    /**
    * Get the address of the _index offer
    * Retorna o endereço da oferta especificada
    */
    function getOfferAddress(uint256 _index) public view returns (address) {
        return address(mapOffers[_index]);
    }

    /**
    * Get the index of the last cashout for the _account
    * Retorna o índice da ultima oferta que o endereço especificado fez o cashout
    */
    function getLastCashout(address _account) public view returns (uint256) {
        return mapLastCashout[_account];
    }

    /**
    * Get the total amount of offers registered
    * Retorna o total de ofertas que foram linkadas a esse token
    */
    function getTotalOffers() public view returns (uint256) {
        return counterTotalOffers.current();
    }

    /**
    * Gets the address of the issuer
    * Retorna o endereço da carteira do emissor
    */
    function getIssuer() public view returns (address) {
        return aIssuer;
    }

    /**
    * Disables the exchangeBalance function
    */
    function disableExchangeBalance() public onlyOwner {
        require(
            !bDisabledExchangeBalance,
            "Exchange balance is already disabled"
        );
        bDisabledExchangeBalance = true;
    }

    /**
    * Exchanges the funds of one address to another
    */
    function exchangeBalance(address _from, address _to) public onlyOwner {
        // check if the function is disabled
        require(
            !bDisabledExchangeBalance,
            "Exchange balance has been disabled"
        );
        // simple checks for empty addresses
        require(_from != address(0), "Transaction from 0x");
        require(_to != address(0), "Transaction to 0x");
        // get current balance of _from address
        uint256 amount = balanceOf(_from);
        // check if there's balance to transfer
        require(amount != 0, "Balance is 0");
        // transfer balance to new address
        _transfer(_from, _to, amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        require(to != address(this), "Sending to contract address");
        super._beforeTokenTransfer(from, to, amount);
    }
}

/* SPDX-License-Identifier: UNLICENSED */
pragma solidity 0.8.17;

interface IOffer {
    /**
     * Returns true if the sale is initialized and ready for operation
     */
    function getInitialized() external view returns (bool);

    /**
     * Returns true if the sale has finished operations and can no longer sell
     */
    function getFinished() external view returns (bool);

    /**
     * Returns true if the sale has reached a successful state (should be irreversible)
     */
    function getSuccess() external view returns (bool);

    /**
     * Returns the total amount of tokens bought by the specified _investor
     */
    function getTotalBought(address _investor) external view returns (uint256);

    /**
     * Returns the total amount of tokens cashed out by the specified _investor
     */
    function getTotalCashedOut(address _investor) external view returns (uint256);

    /**
     * Returns the total amount of tokens bought by the specified _investor
     */
    function getTotalBoughtDate(address _investor, uint256 _date) external view returns (uint256);

    /**
     * Returns the total amount of tokens the specified investor
     * has cashed out from this contract, up to the specified date
     */
    function getTotalCashedOutDate(address _investor, uint256 _date) external view returns (uint256);

    /**
     * If the sale is finished, returns the date it finished at
     */
    function getFinishDate() external view returns (uint256);

    /**
     * Prepares the sale for operation
     */
    function initialize() external;

    /**
     * If possible, cash-outs tokens for the specified _investor
     */
    function cashoutTokens(address _investor) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

// ----------------------------------------------------------------------------
// BokkyPooBah's DateTime Library v1.01
//
// A gas-efficient Solidity date and time library
//
// https://github.com/bokkypoobah/BokkyPooBahsDateTimeLibrary
//
// Tested date range 1970/01/01 to 2345/12/31
//
// Conventions:
// Unit      | Range         | Notes
// :-------- |:-------------:|:-----
// timestamp | >= 0          | Unix timestamp, number of seconds since 1970/01/01 00:00:00 UTC
// year      | 1970 ... 2345 |
// month     | 1 ... 12      |
// day       | 1 ... 31      |
// hour      | 0 ... 23      |
// minute    | 0 ... 59      |
// second    | 0 ... 59      |
// dayOfWeek | 1 ... 7       | 1 = Monday, ..., 7 = Sunday
//
//
// Enjoy. (c) BokkyPooBah / Bok Consulting Pty Ltd 2018-2019. The MIT Licence.
// ----------------------------------------------------------------------------

library BokkyPooBahsDateTimeLibrary {

    uint constant SECONDS_PER_DAY = 24 * 60 * 60;
    uint constant SECONDS_PER_HOUR = 60 * 60;
    uint constant SECONDS_PER_MINUTE = 60;
    int constant OFFSET19700101 = 2440588;

    uint constant DOW_MON = 1;
    uint constant DOW_TUE = 2;
    uint constant DOW_WED = 3;
    uint constant DOW_THU = 4;
    uint constant DOW_FRI = 5;
    uint constant DOW_SAT = 6;
    uint constant DOW_SUN = 7;

    // ------------------------------------------------------------------------
    // Calculate the number of days from 1970/01/01 to year/month/day using
    // the date conversion algorithm from
    //   https://aa.usno.navy.mil/faq/JD_formula.html
    // and subtracting the offset 2440588 so that 1970/01/01 is day 0
    //
    // days = day
    //      - 32075
    //      + 1461 * (year + 4800 + (month - 14) / 12) / 4
    //      + 367 * (month - 2 - (month - 14) / 12 * 12) / 12
    //      - 3 * ((year + 4900 + (month - 14) / 12) / 100) / 4
    //      - offset
    // ------------------------------------------------------------------------
    function _daysFromDate(uint year, uint month, uint day) internal pure returns (uint _days) {
        require(year >= 1970);
        int _year = int(year);
        int _month = int(month);
        int _day = int(day);

        int __days = _day
        - 32075
        + 1461 * (_year + 4800 + (_month - 14) / 12) / 4
        + 367 * (_month - 2 - (_month - 14) / 12 * 12) / 12
        - 3 * ((_year + 4900 + (_month - 14) / 12) / 100) / 4
        - OFFSET19700101;

        _days = uint(__days);
    }

    // ------------------------------------------------------------------------
    // Calculate year/month/day from the number of days since 1970/01/01 using
    // the date conversion algorithm from
    //   http://aa.usno.navy.mil/faq/docs/JD_Formula.php
    // and adding the offset 2440588 so that 1970/01/01 is day 0
    //
    // int L = days + 68569 + offset
    // int N = 4 * L / 146097
    // L = L - (146097 * N + 3) / 4
    // year = 4000 * (L + 1) / 1461001
    // L = L - 1461 * year / 4 + 31
    // month = 80 * L / 2447
    // dd = L - 2447 * month / 80
    // L = month / 11
    // month = month + 2 - 12 * L
    // year = 100 * (N - 49) + year + L
    // ------------------------------------------------------------------------
    function _daysToDate(uint _days) internal pure returns (uint year, uint month, uint day) {
        int __days = int(_days);

        int L = __days + 68569 + OFFSET19700101;
        int N = 4 * L / 146097;
        L = L - (146097 * N + 3) / 4;
        int _year = 4000 * (L + 1) / 1461001;
        L = L - 1461 * _year / 4 + 31;
        int _month = 80 * L / 2447;
        int _day = L - 2447 * _month / 80;
        L = _month / 11;
        _month = _month + 2 - 12 * L;
        _year = 100 * (N - 49) + _year + L;

        year = uint(_year);
        month = uint(_month);
        day = uint(_day);
    }

    function timestampFromDate(uint year, uint month, uint day) internal pure returns (uint timestamp) {
        timestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY;
    }
    function timestampFromDateTime(uint year, uint month, uint day, uint hour, uint minute, uint second) internal pure returns (uint timestamp) {
        timestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + hour * SECONDS_PER_HOUR + minute * SECONDS_PER_MINUTE + second;
    }
    function timestampToDate(uint timestamp) internal pure returns (uint year, uint month, uint day) {
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }
    function timestampToDateTime(uint timestamp) internal pure returns (uint year, uint month, uint day, uint hour, uint minute, uint second) {
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        uint secs = timestamp % SECONDS_PER_DAY;
        hour = secs / SECONDS_PER_HOUR;
        secs = secs % SECONDS_PER_HOUR;
        minute = secs / SECONDS_PER_MINUTE;
        second = secs % SECONDS_PER_MINUTE;
    }

    function isValidDate(uint year, uint month, uint day) internal pure returns (bool valid) {
        if (year >= 1970 && month > 0 && month <= 12) {
            uint daysInMonth = _getDaysInMonth(year, month);
            if (day > 0 && day <= daysInMonth) {
                valid = true;
            }
        }
    }
    function isValidDateTime(uint year, uint month, uint day, uint hour, uint minute, uint second) internal pure returns (bool valid) {
        if (isValidDate(year, month, day)) {
            if (hour < 24 && minute < 60 && second < 60) {
                valid = true;
            }
        }
    }
    function isLeapYear(uint timestamp) internal pure returns (bool leapYear) {
        (uint year,,) = _daysToDate(timestamp / SECONDS_PER_DAY);
        leapYear = _isLeapYear(year);
    }
    function _isLeapYear(uint year) internal pure returns (bool leapYear) {
        leapYear = ((year % 4 == 0) && (year % 100 != 0)) || (year % 400 == 0);
    }
    function isWeekDay(uint timestamp) internal pure returns (bool weekDay) {
        weekDay = getDayOfWeek(timestamp) <= DOW_FRI;
    }
    function isWeekEnd(uint timestamp) internal pure returns (bool weekEnd) {
        weekEnd = getDayOfWeek(timestamp) >= DOW_SAT;
    }
    function getDaysInMonth(uint timestamp) internal pure returns (uint daysInMonth) {
        (uint year, uint month,) = _daysToDate(timestamp / SECONDS_PER_DAY);
        daysInMonth = _getDaysInMonth(year, month);
    }
    function _getDaysInMonth(uint year, uint month) internal pure returns (uint daysInMonth) {
        if (month == 1 || month == 3 || month == 5 || month == 7 || month == 8 || month == 10 || month == 12) {
            daysInMonth = 31;
        } else if (month != 2) {
            daysInMonth = 30;
        } else {
            daysInMonth = _isLeapYear(year) ? 29 : 28;
        }
    }
    // 1 = Monday, 7 = Sunday
    function getDayOfWeek(uint timestamp) internal pure returns (uint dayOfWeek) {
        uint _days = timestamp / SECONDS_PER_DAY;
        dayOfWeek = (_days + 3) % 7 + 1;
    }

    function getYear(uint timestamp) internal pure returns (uint year) {
        (year,,) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }
    function getMonth(uint timestamp) internal pure returns (uint month) {
        (,month,) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }
    function getDay(uint timestamp) internal pure returns (uint day) {
        (,,day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }
    function getHour(uint timestamp) internal pure returns (uint hour) {
        uint secs = timestamp % SECONDS_PER_DAY;
        hour = secs / SECONDS_PER_HOUR;
    }
    function getMinute(uint timestamp) internal pure returns (uint minute) {
        uint secs = timestamp % SECONDS_PER_HOUR;
        minute = secs / SECONDS_PER_MINUTE;
    }
    function getSecond(uint timestamp) internal pure returns (uint second) {
        second = timestamp % SECONDS_PER_MINUTE;
    }

    function addYears(uint timestamp, uint _years) internal pure returns (uint newTimestamp) {
        (uint year, uint month, uint day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        year += _years;
        uint daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;
        require(newTimestamp >= timestamp);
    }
    function addMonths(uint timestamp, uint _months) internal pure returns (uint newTimestamp) {
        (uint year, uint month, uint day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        month += _months;
        year += (month - 1) / 12;
        month = (month - 1) % 12 + 1;
        uint daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;
        require(newTimestamp >= timestamp);
    }
    function addDays(uint timestamp, uint _days) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _days * SECONDS_PER_DAY;
        require(newTimestamp >= timestamp);
    }
    function addHours(uint timestamp, uint _hours) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _hours * SECONDS_PER_HOUR;
        require(newTimestamp >= timestamp);
    }
    function addMinutes(uint timestamp, uint _minutes) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _minutes * SECONDS_PER_MINUTE;
        require(newTimestamp >= timestamp);
    }
    function addSeconds(uint timestamp, uint _seconds) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _seconds;
        require(newTimestamp >= timestamp);
    }

    function subYears(uint timestamp, uint _years) internal pure returns (uint newTimestamp) {
        (uint year, uint month, uint day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        year -= _years;
        uint daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;
        require(newTimestamp <= timestamp);
    }
    function subMonths(uint timestamp, uint _months) internal pure returns (uint newTimestamp) {
        (uint year, uint month, uint day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        uint yearMonth = year * 12 + (month - 1) - _months;
        year = yearMonth / 12;
        month = yearMonth % 12 + 1;
        uint daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;
        require(newTimestamp <= timestamp);
    }
    function subDays(uint timestamp, uint _days) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp - _days * SECONDS_PER_DAY;
        require(newTimestamp <= timestamp);
    }
    function subHours(uint timestamp, uint _hours) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp - _hours * SECONDS_PER_HOUR;
        require(newTimestamp <= timestamp);
    }
    function subMinutes(uint timestamp, uint _minutes) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp - _minutes * SECONDS_PER_MINUTE;
        require(newTimestamp <= timestamp);
    }
    function subSeconds(uint timestamp, uint _seconds) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp - _seconds;
        require(newTimestamp <= timestamp);
    }

    function diffYears(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _years) {
        require(fromTimestamp <= toTimestamp);
        (uint fromYear,,) = _daysToDate(fromTimestamp / SECONDS_PER_DAY);
        (uint toYear,,) = _daysToDate(toTimestamp / SECONDS_PER_DAY);
        _years = toYear - fromYear;
    }
    function diffMonths(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _months) {
        require(fromTimestamp <= toTimestamp);
        (uint fromYear, uint fromMonth,) = _daysToDate(fromTimestamp / SECONDS_PER_DAY);
        (uint toYear, uint toMonth,) = _daysToDate(toTimestamp / SECONDS_PER_DAY);
        _months = toYear * 12 + toMonth - fromYear * 12 - fromMonth;
    }
    function diffDays(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _days) {
        require(fromTimestamp <= toTimestamp);
        _days = (toTimestamp - fromTimestamp) / SECONDS_PER_DAY;
    }
    function diffHours(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _hours) {
        require(fromTimestamp <= toTimestamp);
        _hours = (toTimestamp - fromTimestamp) / SECONDS_PER_HOUR;
    }
    function diffMinutes(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _minutes) {
        require(fromTimestamp <= toTimestamp);
        _minutes = (toTimestamp - fromTimestamp) / SECONDS_PER_MINUTE;
    }
    function diffSeconds(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _seconds) {
        require(fromTimestamp <= toTimestamp);
        _seconds = toTimestamp - fromTimestamp;
    }
}

/* SPDX-License-Identifier: UNLICENSED */
pragma solidity 0.8.17;

library MathLibrary {

    function fullMul(uint256 x, uint256 y) internal pure returns (uint256 l, uint256 h) {
        uint256 xl = uint128(x);
        uint256 xh = x >> 128;
        uint256 yl = uint128(y);
        uint256 yh = y >> 128;
        uint256 xlyl = xl * yl;
        uint256 xlyh = xl * yh;
        uint256 xhyl = xh * yl;
        uint256 xhyh = xh * yh;

        uint256 ll = uint128(xlyl);
        uint256 lh = (xlyl >> 128) + uint128(xlyh) + uint128(xhyl);
        uint256 hl = uint128(xhyh) + (xlyh >> 128) + (xhyl >> 128);
        uint256 hh = (xhyh >> 128);
        l = ll + (lh << 128);
        h = (lh >> 128) + hl + (hh << 128);
    }

}