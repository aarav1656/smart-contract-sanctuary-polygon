// SPDX-License-Identifier: MIT
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
// OpenZeppelin Contracts (last updated v4.8.0) (interfaces/IERC4626.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";
import "../token/ERC20/extensions/IERC20Metadata.sol";

/**
 * @dev Interface of the ERC4626 "Tokenized Vault Standard", as defined in
 * https://eips.ethereum.org/EIPS/eip-4626[ERC-4626].
 *
 * _Available since v4.7._
 */
interface IERC4626 is IERC20, IERC20Metadata {
    event Deposit(address indexed sender, address indexed owner, uint256 assets, uint256 shares);

    event Withdraw(
        address indexed sender,
        address indexed receiver,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );

    /**
     * @dev Returns the address of the underlying token used for the Vault for accounting, depositing, and withdrawing.
     *
     * - MUST be an ERC-20 token contract.
     * - MUST NOT revert.
     */
    function asset() external view returns (address assetTokenAddress);

    /**
     * @dev Returns the total amount of the underlying asset that is “managed” by Vault.
     *
     * - SHOULD include any compounding that occurs from yield.
     * - MUST be inclusive of any fees that are charged against assets in the Vault.
     * - MUST NOT revert.
     */
    function totalAssets() external view returns (uint256 totalManagedAssets);

    /**
     * @dev Returns the amount of shares that the Vault would exchange for the amount of assets provided, in an ideal
     * scenario where all the conditions are met.
     *
     * - MUST NOT be inclusive of any fees that are charged against assets in the Vault.
     * - MUST NOT show any variations depending on the caller.
     * - MUST NOT reflect slippage or other on-chain conditions, when performing the actual exchange.
     * - MUST NOT revert.
     *
     * NOTE: This calculation MAY NOT reflect the “per-user” price-per-share, and instead should reflect the
     * “average-user’s” price-per-share, meaning what the average user should expect to see when exchanging to and
     * from.
     */
    function convertToShares(uint256 assets) external view returns (uint256 shares);

    /**
     * @dev Returns the amount of assets that the Vault would exchange for the amount of shares provided, in an ideal
     * scenario where all the conditions are met.
     *
     * - MUST NOT be inclusive of any fees that are charged against assets in the Vault.
     * - MUST NOT show any variations depending on the caller.
     * - MUST NOT reflect slippage or other on-chain conditions, when performing the actual exchange.
     * - MUST NOT revert.
     *
     * NOTE: This calculation MAY NOT reflect the “per-user” price-per-share, and instead should reflect the
     * “average-user’s” price-per-share, meaning what the average user should expect to see when exchanging to and
     * from.
     */
    function convertToAssets(uint256 shares) external view returns (uint256 assets);

    /**
     * @dev Returns the maximum amount of the underlying asset that can be deposited into the Vault for the receiver,
     * through a deposit call.
     *
     * - MUST return a limited value if receiver is subject to some deposit limit.
     * - MUST return 2 ** 256 - 1 if there is no limit on the maximum amount of assets that may be deposited.
     * - MUST NOT revert.
     */
    function maxDeposit(address receiver) external view returns (uint256 maxAssets);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their deposit at the current block, given
     * current on-chain conditions.
     *
     * - MUST return as close to and no more than the exact amount of Vault shares that would be minted in a deposit
     *   call in the same transaction. I.e. deposit should return the same or more shares as previewDeposit if called
     *   in the same transaction.
     * - MUST NOT account for deposit limits like those returned from maxDeposit and should always act as though the
     *   deposit would be accepted, regardless if the user has enough tokens approved, etc.
     * - MUST be inclusive of deposit fees. Integrators should be aware of the existence of deposit fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToShares and previewDeposit SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by depositing.
     */
    function previewDeposit(uint256 assets) external view returns (uint256 shares);

    /**
     * @dev Mints shares Vault shares to receiver by depositing exactly amount of underlying tokens.
     *
     * - MUST emit the Deposit event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
     *   deposit execution, and are accounted for during deposit.
     * - MUST revert if all of assets cannot be deposited (due to deposit limit being reached, slippage, the user not
     *   approving enough underlying tokens to the Vault contract, etc).
     *
     * NOTE: most implementations will require pre-approval of the Vault with the Vault’s underlying asset token.
     */
    function deposit(uint256 assets, address receiver) external returns (uint256 shares);

    /**
     * @dev Returns the maximum amount of the Vault shares that can be minted for the receiver, through a mint call.
     * - MUST return a limited value if receiver is subject to some mint limit.
     * - MUST return 2 ** 256 - 1 if there is no limit on the maximum amount of shares that may be minted.
     * - MUST NOT revert.
     */
    function maxMint(address receiver) external view returns (uint256 maxShares);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their mint at the current block, given
     * current on-chain conditions.
     *
     * - MUST return as close to and no fewer than the exact amount of assets that would be deposited in a mint call
     *   in the same transaction. I.e. mint should return the same or fewer assets as previewMint if called in the
     *   same transaction.
     * - MUST NOT account for mint limits like those returned from maxMint and should always act as though the mint
     *   would be accepted, regardless if the user has enough tokens approved, etc.
     * - MUST be inclusive of deposit fees. Integrators should be aware of the existence of deposit fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToAssets and previewMint SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by minting.
     */
    function previewMint(uint256 shares) external view returns (uint256 assets);

    /**
     * @dev Mints exactly shares Vault shares to receiver by depositing amount of underlying tokens.
     *
     * - MUST emit the Deposit event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the mint
     *   execution, and are accounted for during mint.
     * - MUST revert if all of shares cannot be minted (due to deposit limit being reached, slippage, the user not
     *   approving enough underlying tokens to the Vault contract, etc).
     *
     * NOTE: most implementations will require pre-approval of the Vault with the Vault’s underlying asset token.
     */
    function mint(uint256 shares, address receiver) external returns (uint256 assets);

    /**
     * @dev Returns the maximum amount of the underlying asset that can be withdrawn from the owner balance in the
     * Vault, through a withdraw call.
     *
     * - MUST return a limited value if owner is subject to some withdrawal limit or timelock.
     * - MUST NOT revert.
     */
    function maxWithdraw(address owner) external view returns (uint256 maxAssets);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their withdrawal at the current block,
     * given current on-chain conditions.
     *
     * - MUST return as close to and no fewer than the exact amount of Vault shares that would be burned in a withdraw
     *   call in the same transaction. I.e. withdraw should return the same or fewer shares as previewWithdraw if
     *   called
     *   in the same transaction.
     * - MUST NOT account for withdrawal limits like those returned from maxWithdraw and should always act as though
     *   the withdrawal would be accepted, regardless if the user has enough shares, etc.
     * - MUST be inclusive of withdrawal fees. Integrators should be aware of the existence of withdrawal fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToShares and previewWithdraw SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by depositing.
     */
    function previewWithdraw(uint256 assets) external view returns (uint256 shares);

    /**
     * @dev Burns shares from owner and sends exactly assets of underlying tokens to receiver.
     *
     * - MUST emit the Withdraw event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
     *   withdraw execution, and are accounted for during withdraw.
     * - MUST revert if all of assets cannot be withdrawn (due to withdrawal limit being reached, slippage, the owner
     *   not having enough shares, etc).
     *
     * Note that some implementations will require pre-requesting to the Vault before a withdrawal may be performed.
     * Those methods should be performed separately.
     */
    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) external returns (uint256 shares);

    /**
     * @dev Returns the maximum amount of Vault shares that can be redeemed from the owner balance in the Vault,
     * through a redeem call.
     *
     * - MUST return a limited value if owner is subject to some withdrawal limit or timelock.
     * - MUST return balanceOf(owner) if owner is not subject to any withdrawal limit or timelock.
     * - MUST NOT revert.
     */
    function maxRedeem(address owner) external view returns (uint256 maxShares);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their redeemption at the current block,
     * given current on-chain conditions.
     *
     * - MUST return as close to and no more than the exact amount of assets that would be withdrawn in a redeem call
     *   in the same transaction. I.e. redeem should return the same or more assets as previewRedeem if called in the
     *   same transaction.
     * - MUST NOT account for redemption limits like those returned from maxRedeem and should always act as though the
     *   redemption would be accepted, regardless if the user has enough shares, etc.
     * - MUST be inclusive of withdrawal fees. Integrators should be aware of the existence of withdrawal fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToAssets and previewRedeem SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by redeeming.
     */
    function previewRedeem(uint256 shares) external view returns (uint256 assets);

    /**
     * @dev Burns exactly shares from owner and sends assets of underlying tokens to receiver.
     *
     * - MUST emit the Withdraw event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
     *   redeem execution, and are accounted for during redeem.
     * - MUST revert if all of shares cannot be redeemed (due to withdrawal limit being reached, slippage, the owner
     *   not having enough shares, etc).
     *
     * NOTE: some implementations will require pre-requesting to the Vault before a withdrawal may be performed.
     * Those methods should be performed separately.
     */
    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) external returns (uint256 assets);
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

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.0 <0.9.0;

interface IPool {
    function supply(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) external;

    function withdraw(address asset, uint256 amount, address to) external returns (uint256);

    function borrow(
        address asset,
        uint256 amount,
        uint256 interestRateMode,
        uint16 referralCode,
        address onBehalfOf
    ) external;

    function repay(
        address asset,
        uint256 amount,
        uint256 interestRateMode,
        address onBehalfOf
    ) external returns (uint256);

    function getUserAccountData(
        address user
    )
        external
        view
        returns (
            uint256 totalCollateralBase,
            uint256 totalDebtBase,
            uint256 availableBorrowsBase,
            uint256 currentLiquidationThreshold,
            uint256 ltv,
            uint256 healthFactor
        );
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.0 <0.9.0;

interface IRewardsController {
    function claimAllRewards(
        address[] calldata assets,
        address to
    ) external returns (address[] memory rewardsList, uint256[] memory claimedAmounts);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.7.0 <0.9.0;

interface IAsset {}

interface IVault {
    enum SwapKind {
        GIVEN_IN,
        GIVEN_OUT
    }

    function swap(
        SingleSwap memory singleSwap,
        FundManagement memory funds,
        uint256 limit,
        uint256 deadline
    ) external payable returns (uint256);

    struct SingleSwap {
        bytes32 poolId;
        SwapKind kind;
        IAsset assetIn;
        IAsset assetOut;
        uint256 amount;
        bytes userData;
    }

    struct FundManagement {
        address sender;
        bool fromInternalBalance;
        address payable recipient;
        bool toInternalBalance;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

interface IChildPool {
    function swapMaticForMaticXViaInstantPool() external payable;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.0 <0.9.0;

interface WMATIC {
    function deposit() external payable;

    function withdraw(uint wad) external;

    function approve(address guy, uint wad) external returns (bool);

    function transfer(address dst, uint wad) external returns (bool);

    function transferFrom(address src, address dst, uint wad) external returns (bool);

    function balanceOf(address guy) external returns (uint256);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/interfaces/IERC4626.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

import "./customInterfaces/stader/IChildPool.sol";
import "./customInterfaces/aave/IPool.sol";
import "./customInterfaces/aave/IRewardsController.sol";
import "./customInterfaces/balancer/IVault.sol";
import "./customInterfaces/wmatic/WMATIC.sol";

contract LSD is ERC20, IERC4626, Ownable {
    event LeverageStakingYieldToggle(bool toggleStatus);
    event BorrowPercentageChange(uint8 updatedPercentage);

    IChildPool immutable stader;
    AggregatorV3Interface immutable priceFeedMatic;
    AggregatorV3Interface immutable priceFeedMaticX;

    address immutable aave;
    address immutable aaveRewards;
    address immutable balancer;
    address immutable aPolMATICX;
    address immutable wMatic;
    address immutable maticX;
    bytes32 immutable balancerPool;

    bool public leverageStakingYieldToggle;
    uint8 public borrowPercentage;
    uint256 public totalInvested;
    uint256 public deployTime;

    constructor(
        string memory _name,
        string memory _symbol,
        bool _leverageStakingYieldToggle,
        uint8 _borrowPercentage,
        address _stader,
        address _aave,
        address _aaveRewards,
        address _balancer,
        address _priceFeedMatic,
        address _priceFeedMaticX,
        address _wMatic,
        address _maticX,
        address _aPolMATICX,
        bytes32 _balancerPool
    ) payable ERC20(_name, _symbol) {
        require(msg.value == 1 ether, "Send exactly 1 matic during deployement!");

        leverageStakingYieldToggle = _leverageStakingYieldToggle;
        borrowPercentage = _borrowPercentage;

        stader = IChildPool(_stader);
        priceFeedMatic = AggregatorV3Interface(_priceFeedMatic);
        priceFeedMaticX = AggregatorV3Interface(_priceFeedMaticX);

        aave = _aave;
        aaveRewards = _aaveRewards;
        balancer = _balancer;
        aPolMATICX = _aPolMATICX;
        wMatic = _wMatic;
        maticX = _maticX;
        balancerPool = _balancerPool;
        deployTime = block.timestamp * (10 ** 18);

        IERC20(_maticX).approve(_aave, type(uint256).max);
        IERC20(_maticX).approve(_balancer, type(uint256).max);
        WMATIC(_wMatic).approve(_aave, type(uint256).max);
        IERC20(_aPolMATICX).approve(_aave, type(uint256).max);

        uint256 _assets = 10 ** 18;
        _wrap(_assets);
        uint256 _shares = _convertToShares(_assets);
        _deposit(_assets);
        _mintLSD(_shares, _assets, msg.sender);
        emit Deposit(msg.sender, msg.sender, _assets, _shares);
    }

    // ERC4626 FUNCTIONS

    function asset() external view returns (address assetTokenAddress) {
        return wMatic;
    }

    function totalAssets() public view returns (uint256 totalManagedAssets) {
        (uint256 _supplied, uint256 _borrowed, , , , ) = getAaveUserAccountData();
        (, int256 _priceWMatic, , , ) = getPriceFeedWMatic();
        uint256 totalAssetsUSD = _supplied - _borrowed;
        return (totalAssetsUSD * (10 ** 18)) / uint256(_priceWMatic);
    }

    function convertToShares(uint256 _assets) external view returns (uint256 shares) {
        return _convertToShares(_assets);
    }

    function convertToAssets(uint256 _shares) external view returns (uint256 assets) {
        return _convertToAssets(_shares);
    }

    function maxDeposit(address _receiver) external view returns (uint256 maxAssets) {
        return type(uint256).max;
    }

    function previewDeposit(uint256 _assets) external view returns (uint256 shares) {
        return _convertToShares(_assets);
    }

    function deposit(uint256 _assets, address _receiver) external returns (uint256 shares) {
        WMATIC(wMatic).transferFrom(msg.sender, address(this), _assets);
        uint256 _shares = _convertToShares(_assets);
        _deposit(_assets);
        _mintLSD(_shares, _assets, _receiver);
        emit Deposit(msg.sender, _receiver, _assets, _shares);
        return _shares;
    }

    function maxMint(address _receiver) external view returns (uint256 maxShares) {
        return type(uint256).max;
    }

    function previewMint(uint256 _shares) external view returns (uint256 assets) {
        return _convertToAssets(_shares);
    }

    function mint(uint256 _shares, address _receiver) external returns (uint256 assets) {
        uint256 _assets = _convertToAssets(_shares);
        WMATIC(wMatic).transferFrom(msg.sender, address(this), _assets);
        _deposit(_assets);
        _mintLSD(_shares, _assets, _receiver);
        emit Deposit(msg.sender, _receiver, _assets, _shares);
        return _assets;
    }

    function maxWithdraw(address _owner) external view returns (uint256 maxAssets) {
        return _convertToAssets(balanceOf(_owner));
    }

    function previewWithdraw(uint256 _assets) external view returns (uint256 shares) {
        return _convertToAssets(_assets);
    }

    function withdraw(uint256 _assets, address _receiver, address _owner) external returns (uint256 shares) {
        uint256 _shares = _convertToShares(_assets);

        require(balanceOf(_owner) >= _shares, "Not enough shares!");
        if (msg.sender != _owner) {
            require(allowance(_owner, msg.sender) >= _shares, "Not enough allowance!");
            _spendAllowance(_owner, msg.sender, _shares);
        }

        (uint256 _supplied, , , , , ) = getAaveUserAccountData();
        uint256 _withdrawAssetsUSD = (_shares * _supplied) / totalSupply();
        _withdraw(_withdrawAssetsUSD);

        uint256 _investedAssets = (_shares * totalInvested) / totalSupply();
        _burnLSD(_shares, _investedAssets, _owner);

        _assets = WMATIC(wMatic).balanceOf(address(this));
        WMATIC(wMatic).transfer(_receiver, _assets);

        emit Withdraw(msg.sender, _receiver, _owner, _assets, _shares);

        return _shares;
    }

    function maxRedeem(address _owner) external view returns (uint256 maxShares) {
        return balanceOf(_owner);
    }

    function previewRedeem(uint256 _shares) external view returns (uint256 assets) {
        return _convertToAssets(_shares);
    }

    function redeem(uint256 _shares, address _receiver, address _owner) external returns (uint256 assets) {
        require(balanceOf(_owner) >= _shares, "Not enough shares!");
        if (msg.sender != _owner) {
            require(allowance(_owner, msg.sender) >= _shares, "Not enough allowance!");
            _spendAllowance(_owner, msg.sender, _shares);
        }

        (uint256 _supplied, , , , , ) = getAaveUserAccountData();
        uint256 _withdrawAssetsUSD = (_shares * _supplied) / totalSupply();
        _withdraw(_withdrawAssetsUSD);

        uint256 _investedAssets = (_shares * totalInvested) / totalSupply();
        _burnLSD(_shares, _investedAssets, _owner);

        uint256 _assets = WMATIC(wMatic).balanceOf(address(this));
        WMATIC(wMatic).transfer(_receiver, _assets);

        emit Withdraw(msg.sender, _receiver, _owner, _assets, _shares);

        return _assets;
    }

    // EXTRA FUNCTIONALITIES / STATS

    function resetApprovals() public {
        IERC20(maticX).approve(aave, type(uint256).max);
        IERC20(maticX).approve(balancer, type(uint256).max);
        WMATIC(wMatic).approve(aave, type(uint256).max);
        IERC20(aPolMATICX).approve(aave, type(uint256).max);
    }

    function _wrap(uint256 _assets) internal {
        WMATIC(wMatic).deposit{value: _assets}();
    }

    function _unWrap(uint256 _assets) internal {
        WMATIC(wMatic).withdraw(_assets);
    }

    receive() external payable {
        require(msg.sender == wMatic, "Transfer denied!");
    }

    function getPriceFeedWMatic()
        public
        view
        returns (uint80 roundID, int256 price, uint256 startedAt, uint256 timeStamp, uint80 answeredInRound)
    {
        (
            uint80 _roundID,
            int256 _price,
            uint256 _startedAt,
            uint256 _timeStamp,
            uint80 _answeredInRound
        ) = priceFeedMatic.latestRoundData();
        return (_roundID, _price, _startedAt, _timeStamp, _answeredInRound);
    }

    function getPriceFeedMaticX()
        public
        view
        returns (uint80 roundID, int256 price, uint256 startedAt, uint256 timeStamp, uint80 answeredInRound)
    {
        (
            uint80 _roundID,
            int256 _price,
            uint256 _startedAt,
            uint256 _timeStamp,
            uint80 _answeredInRound
        ) = priceFeedMaticX.latestRoundData();
        return (_roundID, _price, _startedAt, _timeStamp, _answeredInRound);
    }

    function getAaveUserAccountData()
        public
        view
        returns (
            uint256 totalCollateralBase,
            uint256 totalDebtBase,
            uint256 availableBorrowsBase,
            uint256 currentLiquidationThreshold,
            uint256 ltv,
            uint256 healthFactor
        )
    {
        (
            uint256 _totalCollateralBase,
            uint256 _totalDebtBase,
            uint256 _availableBorrowsBase,
            uint256 _currentLiquidationThreshold,
            uint256 _ltv,
            uint256 _healthFactor
        ) = IPool(aave).getUserAccountData(address(this));
        return (
            _totalCollateralBase,
            _totalDebtBase,
            _availableBorrowsBase,
            _currentLiquidationThreshold,
            _ltv,
            _healthFactor
        );
    }

    function enableLeverageStakingYield() public onlyOwner {
        require(leverageStakingYieldToggle == false, "Leverage staking is already enabled!");
        leverageStakingYieldToggle = true;

        // Leverage Staking
        (uint256 _supplied, uint256 _borrowed, , , , ) = getAaveUserAccountData();
        uint256 _toBeBorrowedUSD = (_supplied * borrowPercentage) / 100;
        if (_toBeBorrowedUSD > _borrowed) {
            _toBeBorrowedUSD -= _borrowed;
            (, int256 _priceWMatic, , , ) = getPriceFeedWMatic();
            uint256 _toBeBorrowed = (_toBeBorrowedUSD * (10 ** 18)) / uint256(_priceWMatic);
            IPool(aave).borrow(wMatic, _toBeBorrowed, 2, 0, address(this));
            _unWrap(_toBeBorrowed);
            stader.swapMaticForMaticXViaInstantPool{value: _toBeBorrowed}();
            IPool(aave).supply(maticX, IERC20(maticX).balanceOf(address(this)), address(this), 0);
        }

        emit LeverageStakingYieldToggle(true);
    }

    function disbaleLeverageStakingYield() public onlyOwner {
        require(leverageStakingYieldToggle == true, "Leverage staking is already disabled!");
        leverageStakingYieldToggle = false;

        // Settling Leverage Staking
        (, int256 _priceWMatic, , , ) = getPriceFeedWMatic();
        (, int256 _priceMaticX, , , ) = getPriceFeedMaticX();
        (, uint256 _borrowed, , , , ) = getAaveUserAccountData();

        uint256 _repayPercentageSlippageUSD = _borrowed + ((_borrowed * 2) / 100);
        uint256 _initialWithdrawMaticX = (_repayPercentageSlippageUSD * (10 ** 18)) / uint256(_priceMaticX);
        uint256 _initialWithdrawnMaticX = IPool(aave).withdraw(maticX, _initialWithdrawMaticX, address(this));
        uint256 _initialLimit = (_initialWithdrawnMaticX * 995) / 1000;
        IVault(balancer).swap(
            IVault.SingleSwap(
                balancerPool,
                IVault.SwapKind(0),
                IAsset(maticX),
                IAsset(wMatic),
                _initialWithdrawnMaticX,
                bytes("0")
            ),
            IVault.FundManagement(address(this), false, payable(address(this)), false),
            _initialLimit,
            block.timestamp + 4000
        );

        uint256 _repayWMatic = (_borrowed * (10 ** 18)) / uint256(_priceWMatic);
        IPool(aave).repay(wMatic, _repayWMatic, 2, address(this));

        // Liquid Staking the extra withdrawn maticx
        uint256 _extraWMatic = WMATIC(wMatic).balanceOf(address(this));
        _unWrap(_extraWMatic);
        stader.swapMaticForMaticXViaInstantPool{value: _extraWMatic}();
        IPool(aave).supply(maticX, IERC20(maticX).balanceOf(address(this)), address(this), 0);

        emit LeverageStakingYieldToggle(false);
    }

    function setBorrowPercentage(uint8 _borrowPercentage) external onlyOwner {
        if (leverageStakingYieldToggle) {
            disbaleLeverageStakingYield();
            borrowPercentage = _borrowPercentage;
            enableLeverageStakingYield();
        } else {
            borrowPercentage = _borrowPercentage;
        }

        emit BorrowPercentageChange(_borrowPercentage);
    }

    function claimAaveRewards(address[] calldata _assets, address _to) external onlyOwner {
        IRewardsController(aaveRewards).claimAllRewards(_assets, _to);
    }

    // INTERNAL FUNCTIONS

    function _convertToShares(uint256 _assets) internal view returns (uint256 shares) {
        if (totalSupply() == 0) {
            return _assets;
        }
        return (_assets * totalSupply()) / totalAssets();
    }

    function _convertToAssets(uint256 _shares) internal view returns (uint256 assets) {
        if (totalSupply() == 0) {
            return _shares;
        }
        return (_shares * totalAssets()) / totalSupply();
    }

    function _deposit(uint256 _assets) internal {
        // Liquid Staking
        _unWrap(_assets);
        stader.swapMaticForMaticXViaInstantPool{value: _assets}();
        IPool(aave).supply(maticX, IERC20(maticX).balanceOf(address(this)), address(this), 0);

        // Leverage Staking
        if (leverageStakingYieldToggle) {
            (uint256 _supplied, uint256 _borrowed, , , , ) = getAaveUserAccountData();
            uint256 _toBeBorrowedUSD = (_supplied * borrowPercentage) / 100;
            if (_toBeBorrowedUSD > _borrowed) {
                _toBeBorrowedUSD -= _borrowed;
                (, int256 _priceWMatic, , , ) = getPriceFeedWMatic();
                uint256 _toBeBorrowed = (_toBeBorrowedUSD * (10 ** 18)) / uint256(_priceWMatic);
                IPool(aave).borrow(wMatic, _toBeBorrowed, 2, 0, address(this));
                _unWrap(_toBeBorrowed);
                stader.swapMaticForMaticXViaInstantPool{value: _toBeBorrowed}();
                IPool(aave).supply(maticX, IERC20(maticX).balanceOf(address(this)), address(this), 0);
            }
        }
    }

    function _mintLSD(uint256 _shares, uint256 _assets, address _receiver) internal {
        _mint(_receiver, _shares);
        totalInvested += _assets;
    }

    function _withdraw(uint256 _assetsUSD) internal {
        (, int256 _priceWMatic, , , ) = getPriceFeedWMatic();
        (, int256 _priceMaticX, , , ) = getPriceFeedMaticX();

        uint256 _finalWithdrawMaticX;

        if (leverageStakingYieldToggle) {
            // Settling Leverage Staking
            (uint256 _supplied, uint256 _borrowed, , , , ) = getAaveUserAccountData();
            uint256 _repayPercentageUSD = (_assetsUSD * _borrowed) / _supplied;

            uint256 _repayPercentageSlippageUSD = _repayPercentageUSD + ((_repayPercentageUSD * 2) / 100);
            uint256 _initialWithdrawMaticX = (_repayPercentageSlippageUSD * (10 ** 18)) / uint256(_priceMaticX);
            uint256 _initialWithdrawnMaticX = IPool(aave).withdraw(maticX, _initialWithdrawMaticX, address(this));
            uint256 _initialLimit = (_initialWithdrawnMaticX * 995) / 1000;
            IVault(balancer).swap(
                IVault.SingleSwap(
                    balancerPool,
                    IVault.SwapKind(0),
                    IAsset(maticX),
                    IAsset(wMatic),
                    _initialWithdrawnMaticX,
                    bytes("0")
                ),
                IVault.FundManagement(address(this), false, payable(address(this)), false),
                _initialLimit,
                block.timestamp + 4000
            );

            uint256 _repayWMatic = (_repayPercentageUSD * (10 ** 18)) / uint256(_priceWMatic);
            IPool(aave).repay(wMatic, _repayWMatic, 2, address(this));

            _finalWithdrawMaticX = ((_assetsUSD - _repayPercentageSlippageUSD) * (10 ** 18)) / uint256(_priceMaticX);
        } else {
            _finalWithdrawMaticX = (_assetsUSD * (10 ** 18)) / uint256(_priceMaticX);
        }

        // Settling Liquid Staking
        uint256 _finalWithdrawnMaticX = IPool(aave).withdraw(maticX, _finalWithdrawMaticX, address(this));
        uint256 _finalLimit = (_finalWithdrawnMaticX * 995) / 1000;
        IVault(balancer).swap(
            IVault.SingleSwap(
                balancerPool,
                IVault.SwapKind(0),
                IAsset(maticX),
                IAsset(wMatic),
                _finalWithdrawnMaticX,
                bytes("0")
            ),
            IVault.FundManagement(address(this), false, payable(address(this)), false),
            _finalLimit,
            block.timestamp + 4000
        );
    }

    function _burnLSD(uint256 _shares, uint256 _assets, address _owner) internal {
        _burn(_owner, _shares);
        totalInvested -= _assets;
    }
}