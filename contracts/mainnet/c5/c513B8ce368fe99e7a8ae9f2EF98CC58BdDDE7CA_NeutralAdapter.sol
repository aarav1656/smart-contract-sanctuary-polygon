// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

import '../../interfaces/IAdapter.sol';
import '../CustodianStorage.sol';
import './extensions/IAaveLendingPool.sol';

/**
 * @title AaveV2V3Adapter
 * @author Atlendis Labs
 */
contract AaveV2V3Adapter is CustodianStorage, IAdapter {

    /**
     * @inheritdoc IAdapter
     */
    function supportsToken(address yieldProvider) external view returns(bool) {
        return IAaveLendingPool(yieldProvider).getReserveNormalizedIncome(address(token)) >= RAY;
    }

    /**
     * @inheritdoc IAdapter
     */
    function deposit(uint256 amount) external {

        yieldProviderBalance += (amount * RAY) / lastYieldFactor;

        IAaveLendingPool(yieldProvider).deposit(address(token), amount, address(this), 0);
    }

    /**
     * @inheritdoc IAdapter
     */
    function withdraw(uint256 amount) external {

        yieldProviderBalance -= (amount * RAY) / lastYieldFactor;

        IAaveLendingPool(yieldProvider).withdraw(address(token), amount, address(this));
    }

    /**
     * @inheritdoc IAdapter
     */
    function empty() external {

        uint256 toWithdraw = yieldProviderBalance * lastYieldFactor / RAY;
        yieldProviderBalance = 0;

        IAaveLendingPool(yieldProvider).withdraw(address(token), toWithdraw, address(this));
    }

    /**
     * @inheritdoc IAdapter
     */
    function collectRewards() public returns (uint256 collectedAmount) {
        uint256 newYieldFactor = IAaveLendingPool(yieldProvider).getReserveNormalizedIncome(address(token));

        collectedAmount = (yieldProviderBalance * (newYieldFactor - lastYieldFactor)) / RAY;

        lastYieldFactor = newYieldFactor;
    }

    /**
     * @inheritdoc IERC165
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAdapter).interfaceId;
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

import 'lib/openzeppelin-contracts/contracts/utils/introspection/IERC165.sol';

/**
 * @notice IAdapter
 * @author Atlendis Labs
 * @notice Interface Adapter contract
 *         An Adapter is associated to a yield provider.
 *         It implement the logic necessary to deposit, withdraw and compute rewards
 *         the custodian will get when managing its holdings
 */
interface IAdapter is IERC165 {

    /**
     * @notice Verifies that the yield provider associated with
     * the adapter supports the custodian token
     **/
    function supportsToken(address yieldProvider) external returns(bool);

    /**
     * @notice Deposit tokens to the yield provider
     * @param amount Amount to deposit
     **/
    function deposit(uint256 amount) external;

    /**
     * @notice Withdraw tokens from the yield provider
     * @param amount Amount to deposit
     **/
    function withdraw(uint256 amount) external;

    /**
     * @notice Empty
     **/
    function empty() external;

    /**
     * @notice Updates the pending rewards accrued by the deposits
     **/
    function collectRewards() external returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

import 'lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol';

/**
 * @title CustodianStorage
 * @author Atlendis Labs
 */
contract CustodianStorage {
    // constants
    uint256 public constant WAD = 1e18;
    uint256 public constant RAY = 1e27;

    // addresses
    ERC20 public token; // Custodian token
    address public adapter; // Current adapter
    address public yieldProvider; // Current yield provider

    // balances
    uint256 public depositedBalance; // Original token balance deposited to custodian
    uint256 public pendingRewards; // Yield provider rewards to be withdrawn

    // below variable usage are yield provider specific
    uint256 public yieldProviderBalance; // Yield provider specific balance
    uint256 public lastYieldFactor; // Yield provider specific ratio to be used to compute rewards
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

interface IAaveLendingPool {
    /**
     * @dev Deposits an `amount` of underlying asset into the reserve, receiving in return overlying aTokens.
     * - E.g. User deposits 100 USDC and gets in return 100 aUSDC
     * @param asset The address of the underlying asset to deposit
     * @param amount The amount to be deposited
     * @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
     *   wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
     *   is a different wallet
     * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     **/
    function deposit(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external;

    /**
     * @dev Withdraws an `amount` of underlying asset from the reserve, burning the equivalent aTokens owned
     * E.g. User has 100 aUSDC, calls withdraw() and receives 100 USDC, burning the 100 aUSDC
     * @param asset The address of the underlying asset to withdraw
     * @param amount The underlying amount to be withdrawn
     *   - Send the value type(uint256).max in order to withdraw the whole aToken balance
     * @param to Address that will receive the underlying, same as msg.sender if the user
     *   wants to receive it on his own wallet, or a different address if the beneficiary is a
     *   different wallet
     * @return The final amount withdrawn
     **/
    function withdraw(
        address asset,
        uint256 amount,
        address to
    ) external returns (uint256);

    /**
     * @dev Returns the normalized income normalized income of the reserve
     * @param asset The address of the underlying asset of the reserve
     * @return The reserve's normalized income
     */
    function getReserveNormalizedIncome(address asset) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/ERC20.sol)

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
pragma solidity 0.8.13;

import 'lib/openzeppelin-contracts/contracts/access/AccessControl.sol';
import 'lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol';

import '../interfaces/IAdapter.sol';
import '../interfaces/IPoolCustodian.sol';
import './CustodianStorage.sol';

/**
 * @title PoolCustodian
 * @author Atlendis Labs
 */
contract PoolCustodian is CustodianStorage, AccessControl, IPoolCustodian {

    // CONSTANTS

    bytes32 public constant POOL_ROLE = keccak256('POOL_ROLE');
    bytes32 public constant REWARDS_ROLE = keccak256('REWARDS_ROLE');

    constructor(
        ERC20 _token,
        address _adapter,
        address _yieldProvider,
        address governance
    ) {
        require(_adapter != address(0) && _yieldProvider != address(0));

        token = _token;
        adapter = _adapter;
        yieldProvider = _yieldProvider;

        _setupRole(DEFAULT_ADMIN_ROLE, governance);
    }

    // VIEW METHODS

    /**
     * @inheritdoc IPoolCustodian
     */
    function getAssetDecimals() external view returns (uint256) {
        return token.decimals();
    }

    /**
     * @inheritdoc IPoolCustodian
     */
    function getRewards() external view returns (uint256) {
        return pendingRewards;
    }

    // DEPOSIT MANAGEMENT

    /**
     * @inheritdoc IPoolCustodian
     */
    function deposit(uint256 amount) public onlyRole(POOL_ROLE) {
        collectRewards();

        depositedBalance += amount;

        token.transferFrom(msg.sender, address(this), amount);
        (bool success, ) = adapter.delegatecall(abi.encodeWithSignature('deposit(uint256)', amount));
        require(success);

        emit Deposit(amount, adapter, yieldProvider);
    }

    /**
     * @inheritdoc IPoolCustodian
     */
    function withdraw(uint256 amount) public onlyRole(POOL_ROLE) {
        collectRewards();

        if (amount == type(uint256).max) amount = depositedBalance;
        depositedBalance -= amount;
        
        (bool success, ) = adapter.delegatecall(abi.encodeWithSignature('withdraw(uint256)', amount));
        require(success);
        token.transfer(msg.sender, amount);

        emit Withdraw(amount, adapter, yieldProvider);
    }

    // REWARDS MANAGEMENT

    /**
     * @inheritdoc IPoolCustodian
     */
    function collectRewards() public returns (uint256) {
        (bool success, bytes memory returndata) = adapter.delegatecall(
            abi.encodeWithSignature('collectRewards()', yieldProvider)
        );
        uint256 collectedAmount = abi.decode(returndata, (uint256));
        require(success);

        pendingRewards += collectedAmount;

        emit CollectRewards(collectedAmount);

        return pendingRewards;
    }

    /**
     * @inheritdoc IPoolCustodian
     */
    function withdrawRewards(uint256 amount, address to) external onlyRole(REWARDS_ROLE) {
        collectRewards();

        if (amount == type(uint256).max) amount = pendingRewards;
        pendingRewards -= amount;

        (bool success, ) = adapter.delegatecall(abi.encodeWithSignature('withdraw(uint256)', amount));
        require(success);

        token.transfer(to, amount);

        emit WithdrawRewards(amount);
    }

    // YIELD PROVIDER MANAGEMENT

    /**
     * @inheritdoc IPoolCustodian
     */
    function switchYieldProvider(address newAdapter, address newYieldProvider) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(IAdapter(adapter).supportsInterface(type(IAdapter).interfaceId));
        require(newYieldProvider != address(0));

        collectRewards();
        uint256 balanceToSwitch = depositedBalance;
        (bool success, ) = adapter.delegatecall(abi.encodeWithSignature('empty()'));
        require(success);

        adapter = newAdapter;
        yieldProvider = newYieldProvider;

        collectRewards();
        token.approve(newYieldProvider, balanceToSwitch);
        (success, ) = adapter.delegatecall(abi.encodeWithSignature('deposit(uint256)', balanceToSwitch));
        require(success);

        emit SwitchYieldProvider(adapter, yieldProvider);
    }

    /**
     * @inheritdoc IERC165
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, AccessControl) returns (bool) {
        return interfaceId == type(IPoolCustodian).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

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
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

import 'lib/openzeppelin-contracts/contracts/utils/introspection/IERC165.sol';

/**
 * @notice IPoolCustodian
 * @author Atlendis Labs
 * @notice Interface of the Custodian contract
 *         A custodian contract is associated to a product contract.
 *         It receives funds by the associated product contract.
 *         A yield strategy is chosen in order to generate rewards based on the deposited funds.
 */
interface IPoolCustodian is IERC165 {

    // EVENTS

    /**
     * @notice Deposit tokens to the custodian using current adapter and yield provider
     **/
    event Deposit(uint256 amount, address adapter, address yieldProvider);

    /**
     * @notice Withdraw tokens to the custodian using current adapter and yield provider
     **/
    event Withdraw(uint256 amount, address adapter, address yieldProvider);

    /**
     * @notice Move funds from old yield provider to new yield provider
     **/
    event SwitchYieldProvider(address adapter, address yieldProvider);

    /**
     * @notice Update pending rewards
     **/
    event CollectRewards(uint256 amount);

    /**
     * @notice Withdraw pending rewards
     **/
    event WithdrawRewards(uint256 amount);

    // VIEW METHODS

    /**
     * @notice Retrieve the current stored amount of rewards generated by the custodian
     * @return rewards Amount of rewards
     */
    function getRewards() external view returns (uint256 rewards);

    /**
     * @notice Retrieve the decimals of the underlying asset
     & @return decimals Decimals of the underlying asset
     */
    function getAssetDecimals() external view returns (uint256 decimals);

    // DEPOSIT MANAGEMENT

    /**
     * @notice Deposit tokens to the yield provider
     * Collects pending rewards before depositing
     * @param amount Amount to deposit
     **/
    function deposit(uint256 amount) external;

    /**
     * @notice Withdraw tokens from the yield provider
     * Collects pending rewards before withdrawing
     * @param amount Amount to deposit
     **/
    function withdraw(uint256 amount) external;

    // REWARDS MANAGEMENT

    /**
     * @notice Withdraw an amount of rewards
     * @param amount The amount of rewards to be withdrawn
     * @param to Address that will receive the rewards
     **/
    function withdrawRewards(uint256 amount, address to) external;

    /**
     * @notice Updates the pending rewards accrued by the deposits
     **/
    function collectRewards() external returns (uint256);

    // YIELD PROVIDER MANAGEMENT

    /**
     * @notice Changes the yield provider used by the custodian
     * @param newAdapter New adapter used to manage yield provider interaction
     * @param newYieldProvider New yield provider address
     **/
    function switchYieldProvider(address newAdapter, address newYieldProvider) external;
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
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

import 'lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol';

/**
 * @title IRewardsManager
 * @author Atlendis Labs
 * @notice Interface of the Rewards Manager contract
 *         It allows users to stake their positions and earn rewards associated to it.
 *         When a position is staked, a NFT associated to the staked position is minted to the owner.
 *         The staked position NFT can be burn in order to unlock the original position.
 */
interface IRewardsManager is IERC721 {
    /**
     * @notice Thrown when the minimum value position is zero
     * @param value Given minimum value position
     */
    error INVALID_ZERO_MIN_POSITION_VALUE(uint256 value);

    /**
     * @notice Thrown when the sender is not the expected one
     * @param actualAddress Address of the sender
     * @param expectedAddress Expected address
     */
    error UNAUTHORIZED(address actualAddress, address expectedAddress);

    /**
     * @notice Thrown when the position value is below the minimum
     * @param value Value of the position
     * @param minimumValue Minimum value required for the position
     */
    error POSITION_VALUE_TOO_LOW(uint256 value, uint256 minimumValue);

    /**
     * @notice Emitted when a position has been staked
     * @param positionId ID of the position
     * @param owner Address of the owner of the position
     * @param rate Rate of the position
     * @param positionValue Value of the position at staking time
     */
    event PositionStaked(uint256 indexed positionId, address indexed owner, uint256 rate, uint256 positionValue);

    /**
     * @notice Emitted when a position has been unstaked
     * @param positionId ID of the position
     * @param owner Address of the owner of the position
     */
    event PositionUnstaked(uint256 indexed positionId, address indexed owner);

    /**
     * @notice Emitted when rewards of a staked position has been claimed
     * @param positionId ID of the position
     * @param owner Address of the owner of the position
     */
    event RewardsClaimed(uint256 indexed positionId, address indexed owner);

    /**
     * @notice Stake a position in the contract
     *         An associated staked position NFT is created for the owner
     * @param positionId ID of the position
     *
     * Emits a {PositionStaked} event
     */
    function stake(uint256 positionId) external;

    /**
     * @notice Unstake a position in the contract
     *         The assiocated staked position NFT is burned
     *         The position is transferred to the owner of the staked position NFT
     * @param positionId ID of the position
     *
     * Emits a {PositionUnstaked} event
     */
    function unstake(uint256 positionId) external;

    /**
     * @notice Claim the rewards earned for a staked position without burning it
     * @param positionId ID of the position
     *
     * Emits a {RewardsClaimed} event
     */
    function claimRewards(uint256 positionId) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

import 'lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol';
import 'lib/openzeppelin-contracts/contracts/access/Ownable.sol';
import '../interfaces/IPositionManager.sol';
import './interfaces/IRewardsManager.sol';
import './modules/interfaces/IRewardsModule.sol';

/**
 * @title Rewards Manager
 * @author Atlendis Labs
 * @notice Implementation of the IRewardsManager
 */
contract RewardsManager is IRewardsManager, ERC721, Ownable {
    /*//////////////////////////////////////////////////////////////
                               STORAGE
    //////////////////////////////////////////////////////////////*/
    IPositionManager public immutable POSITION_MANAGER;
    uint256 public immutable MIN_POSITION_VALUE;

    IRewardsModule[] public modules;

    /*//////////////////////////////////////////////////////////////
                             CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Constructor
     * @param governance Address of the governance
     * @param positionManager Address of the position manager contract
     * @param minPositionValue Minimum position required value
     * @param name ERC721 name of the staked position NFT
     * @param symbol ERC721 symbol of the staked position NFT
     */
    constructor(
        address governance,
        address positionManager,
        uint256 minPositionValue,
        string memory name,
        string memory symbol
    ) ERC721(name, symbol) {
        if (minPositionValue == 0) revert INVALID_ZERO_MIN_POSITION_VALUE(minPositionValue);
        MIN_POSITION_VALUE = minPositionValue;

        POSITION_MANAGER = IPositionManager(positionManager);

        _transferOwnership(governance);
    }

    /*//////////////////////////////////////////////////////////////
                              GOVERNANCE
    //////////////////////////////////////////////////////////////*/

    /**
     * Note: temporary method, will be removed or updated with #196
     */
    function addRewardsModule(address module) public onlyOwner {
        modules.push(IRewardsModule(module));
    }

    /*//////////////////////////////////////////////////////////////
                            PUBLIC METHODS
    //////////////////////////////////////////////////////////////*/

    /**
     * @inheritdoc IRewardsManager
     */
    function stake(uint256 positionId) public {
        (address owner, uint256 rate, uint256 positionValue) = POSITION_MANAGER.getPosition(positionId);
        if (msg.sender != owner) revert UNAUTHORIZED(msg.sender, owner);
        if (positionValue < MIN_POSITION_VALUE) revert POSITION_VALUE_TOO_LOW(positionValue, MIN_POSITION_VALUE);

        POSITION_MANAGER.transferFrom(owner, address(this), positionId);

        for (uint256 i = 0; i < modules.length; i++) {
            modules[i].stake(positionId, owner, rate, positionValue);
        }

        _mint(owner, positionId);

        emit PositionStaked(positionId, owner, rate, positionValue);
    }

    /**
     * @inheritdoc IRewardsManager
     */
    function unstake(uint256 positionId) public {
        address owner = ownerOf(positionId);
        if (msg.sender != owner) revert UNAUTHORIZED(msg.sender, owner);

        _burn(positionId);

        for (uint256 i = 0; i < modules.length; i++) {
            modules[i].unstake(positionId, owner);
        }

        POSITION_MANAGER.transferFrom(address(this), owner, positionId);

        emit PositionUnstaked(positionId, owner);
    }

    /**
     * @inheritdoc IRewardsManager
     */
    function claimRewards(uint256 positionId) public {
        address owner = ownerOf(positionId);
        if (msg.sender != owner) revert UNAUTHORIZED(msg.sender, owner);

        for (uint256 i = 0; i < modules.length; i++) {
            modules[i].claimRewards(positionId, owner);
        }

        emit RewardsClaimed(positionId, owner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

import 'lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol';

/**
 * @title IPositionManager
 * @author Atlendis Labs
 * @notice Interface of a Position Manager
 */
interface IPositionManager is IERC721 {
    /**
     * @notice Retrieve a position
     * @param positionId ID of the position
     * @return owner Address of the position owner
     * @return rate Value of the position rate
     * @return value Value of the position
     */
    function getPosition(uint256 positionId)
        external
        returns (
            address owner,
            uint256 rate,
            uint256 value
        );

    /**
     * @notice Retrieve the address of the underlying ERC20 token
     * @return token The address of the token contract
     */
    function UNDERLYING_TOKEN() external returns (address token);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

/**
 * @title IRewardsModule
 * @author Atlendis Labs
 * @notice Interface of a Rewards module contract
 *         A module implementing this interface is meant to be controlled by a rewards manager.
 *         It allows to retrieve rewards and distribute them to staked positions.
 *         The way to retrieve the rewards is specific for each module type.
 */
interface IRewardsModule {
    /**
     * @notice Thrown when the sender is not the expected one
     * @param actualAddress Address of the sender
     * @param expectedAddress Expected address
     */
    error UNAUTHORIZED(address actualAddress, address expectedAddress);

    /**
     * @notice Forward the staking of a position at the module level
     *         Only the Rewards Manager is able to trigger this method
     * @param positionId ID of the staked position
     * @param owner Owner of the staked position
     * @param rate Rate of the underlying position
     * @param positionValue Value of the underlying position
     *
     * Emits a {PositionStaked} event. The params of the event varies according to the module type.
     */
    function stake(
        uint256 positionId,
        address owner,
        uint256 rate,
        uint256 positionValue
    ) external;

    /**
     * @notice Forward the unstaking of a position at the module level
     *         Only the Rewards Manager is able to trigger this method
     * @param positionId ID of the position
     * @param owner Owner of the staked position
     *
     * Emits a {PositionUnstaked} event. The params of the event varies according to the module type.
     */
    function unstake(uint256 positionId, address owner) external;

    /**
     * @notice Forward the rewards claim associated to a staked position at the module level
     *         Only the Rewards Manager is able to trigger this method
     * @param positionId ID of the position
     * @param owner Owner of the staked position
     *
     * Emits a {RewardsClaimed} event. The params of the event varies according to the module type.
     */
    function claimRewards(uint256 positionId, address owner) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

import './IRewardsModule.sol';

/**
 * @title ILiquidStakingRewards
 * @author Atlendis Labs
 * @notice Interface of the Liquid Staking Rewards module contract
 *         This module is controlled by a rewards manager.
 *         It allows to generate rewards of ERC20 tokens based on a configured rate and distribute the rewards to staked positions.
 */
interface ILiquidStakingRewards is IRewardsModule {
    /**
     * @notice Thrown when a value of zero has been given for the rate
     */
    error INVALID_ZERO_RATE();

    /**
     * @notice Emitted when a position has been staked
     * @param positionId ID of the position
     * @param owner Address of the owner of the position
     * @param rate Rate of the position
     * @param positionValue Value of the position at staking time
     */
    event PositionStaked(uint256 indexed positionId, address indexed owner, uint256 rate, uint256 positionValue);

    /**
     * @notice Emitted when a position has been unstaked
     * @param positionId ID of the position
     * @param owner Address of the owner of the position
     * @param positionRewards Value of the position rewards
     */
    event PositionUnstaked(uint256 indexed positionId, address indexed owner, uint256 positionRewards);

    /**
     * @notice Emitted when rewards of a staked position has been claimed
     * @param positionId ID of the position
     * @param owner Address of the owner of the position
     * @param positionRewards Value of the position rewards
     */
    event RewardsClaimed(uint256 indexed positionId, address indexed owner, uint256 positionRewards);

    /**
     * @notice Emitted when rewards are colleted
     * @param pendingRewards Amount of rewards to be collected
     * @param earningsPerDeposit Value of the computed earning per deposit ratio
     */
    event RewardsCollected(uint256 pendingRewards, uint256 earningsPerDeposit);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

import 'lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol';
import 'lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol';
import './interfaces/ILiquidStakingRewards.sol';
import '../../libraries/FixedPointMathLib.sol';

/**
 * @title LiquidStakingRewards
 * @author Atlendis Labs
 * @notice Implementation of the ILiquidStakingRewards
 */
contract LiquidStakingRewards is ILiquidStakingRewards {
    /*//////////////////////////////////////////////////////////////
                              LIBRARIES
    //////////////////////////////////////////////////////////////*/
    using SafeERC20 for ERC20;
    using FixedPointMathLib for uint256;

    /*//////////////////////////////////////////////////////////////
                               STRUCTS
    //////////////////////////////////////////////////////////////*/
    struct StakedPosition {
        uint256 initialValue;
        uint256 startEarningsPerDeposit;
    }

    /*//////////////////////////////////////////////////////////////
                               STORAGE
    //////////////////////////////////////////////////////////////*/

    address public immutable REWARDS_MANAGER;
    ERC20 public immutable TOKEN;

    uint256 public immutable DISTRIBUTION_RATE;

    uint256 public deposits;

    uint256 public pendingRewards;
    uint256 public earningsPerDeposit;
    uint256 public lastUpdateTimestamp;

    uint256 constant RAY = 1e27;

    // position ID -> staked position liquid staking
    mapping(uint256 => StakedPosition) public stakedPositions;

    /*//////////////////////////////////////////////////////////////
                              MODIFIERS
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Restrict sender to Rewards Manager contract
     */
    modifier onlyRewardsManager() {
        if (msg.sender != REWARDS_MANAGER) revert UNAUTHORIZED(msg.sender, REWARDS_MANAGER);
        _;
    }

    /**
     * @dev Trigger the collection of rewards
     */
    modifier rewardsCollector() {
        collectRewards();
        _;
    }

    /*//////////////////////////////////////////////////////////////
                             CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev constructor
     * @param rewardsManager Address of the rewards manager contract
     * @param token Address of the ERC20 token contract
     * @param distributionRate Value of the rate of rewards distribution
     */
    constructor(
        address rewardsManager,
        address token,
        uint256 distributionRate
    ) {
        if (distributionRate == 0) revert INVALID_ZERO_RATE();
        DISTRIBUTION_RATE = distributionRate;
        REWARDS_MANAGER = rewardsManager;
        TOKEN = ERC20(token);
    }

    /*//////////////////////////////////////////////////////////////
                            PUBLIC METHODS
    //////////////////////////////////////////////////////////////*/

    /**
     * @inheritdoc IRewardsModule
     */
    function stake(
        uint256 positionId,
        address owner,
        uint256 rate,
        uint256 positionValue
    ) public onlyRewardsManager rewardsCollector {
        deposits += positionValue;
        stakedPositions[positionId] = StakedPosition({
            initialValue: positionValue,
            startEarningsPerDeposit: earningsPerDeposit
        });

        emit PositionStaked(positionId, owner, rate, positionValue);
    }

    /**
     * @inheritdoc IRewardsModule
     */
    function unstake(uint256 positionId, address owner) public onlyRewardsManager rewardsCollector {
        StakedPosition memory stakedPosition = stakedPositions[positionId];

        uint256 positionRewards = stakedPosition.initialValue.mul(
            earningsPerDeposit - stakedPosition.startEarningsPerDeposit,
            RAY
        );

        deposits -= stakedPosition.initialValue;
        pendingRewards -= positionRewards;

        delete stakedPositions[positionId];

        TOKEN.safeTransfer(owner, positionRewards);

        emit PositionUnstaked(positionId, owner, positionRewards);
    }

    /**
     * @inheritdoc IRewardsModule
     */
    function claimRewards(uint256 positionId, address owner) public onlyRewardsManager rewardsCollector {
        StakedPosition storage stakedPosition = stakedPositions[positionId];

        uint256 positionRewards = stakedPosition.initialValue.mul(
            earningsPerDeposit - stakedPosition.startEarningsPerDeposit,
            RAY
        );

        pendingRewards -= positionRewards;
        stakedPosition.startEarningsPerDeposit = earningsPerDeposit;

        TOKEN.safeTransfer(owner, positionRewards);

        emit RewardsClaimed(positionId, owner, positionRewards);
    }

    /*//////////////////////////////////////////////////////////////
                           PRIVATE METHODS
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Collect the rewards since last update and distribute them to staked positions
     */
    function collectRewards() private {
        if (deposits == 0) {
            lastUpdateTimestamp = block.timestamp;
            return;
        }
        uint256 maximumRewardsSinceLastUpdate = DISTRIBUTION_RATE * (block.timestamp - lastUpdateTimestamp);

        uint256 contractBalance = TOKEN.balanceOf(address(this));
        uint256 rewardsSinceLastUpdate = pendingRewards + maximumRewardsSinceLastUpdate <= contractBalance
            ? maximumRewardsSinceLastUpdate
            : contractBalance - pendingRewards;

        earningsPerDeposit += rewardsSinceLastUpdate.div(deposits, RAY);
        pendingRewards += rewardsSinceLastUpdate;
        lastUpdateTimestamp = block.timestamp;

        emit RewardsCollected(pendingRewards, earningsPerDeposit);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

import {FixedPointMathLib as SolmateFixedPointMathLib} from 'lib/solmate/src/utils/FixedPointMathLib.sol';

/**
 * @title FixedPointMathLib library
 * @author Atlendis Labs
 * @dev Overlay over Solmate FixedPointMathLib
 *      Results of multiplications and divisions are always rounded down
 */
library FixedPointMathLib {
    using SolmateFixedPointMathLib for uint256;

    function mul(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256) {
        return x.mulDivDown(y, denominator);
    }

    function div(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256) {
        return x.mulDivDown(denominator, y);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Arithmetic library with operations for fixed-point numbers.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/FixedPointMathLib.sol)
/// @author Inspired by USM (https://github.com/usmfum/USM/blob/master/contracts/WadMath.sol)
library FixedPointMathLib {
    /*//////////////////////////////////////////////////////////////
                    SIMPLIFIED FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    uint256 internal constant WAD = 1e18; // The scalar of ETH and most ERC20s.

    function mulWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, y, WAD); // Equivalent to (x * y) / WAD rounded down.
    }

    function mulWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, y, WAD); // Equivalent to (x * y) / WAD rounded up.
    }

    function divWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, WAD, y); // Equivalent to (x * WAD) / y rounded down.
    }

    function divWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, WAD, y); // Equivalent to (x * WAD) / y rounded up.
    }

    /*//////////////////////////////////////////////////////////////
                    LOW LEVEL FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function mulDivDown(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        assembly {
            // Store x * y in z for now.
            z := mul(x, y)

            // Equivalent to require(denominator != 0 && (x == 0 || (x * y) / x == y))
            if iszero(and(iszero(iszero(denominator)), or(iszero(x), eq(div(z, x), y)))) {
                revert(0, 0)
            }

            // Divide z by the denominator.
            z := div(z, denominator)
        }
    }

    function mulDivUp(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        assembly {
            // Store x * y in z for now.
            z := mul(x, y)

            // Equivalent to require(denominator != 0 && (x == 0 || (x * y) / x == y))
            if iszero(and(iszero(iszero(denominator)), or(iszero(x), eq(div(z, x), y)))) {
                revert(0, 0)
            }

            // First, divide z - 1 by the denominator and add 1.
            // We allow z - 1 to underflow if z is 0, because we multiply the
            // end result by 0 if z is zero, ensuring we return 0 if z is zero.
            z := mul(iszero(iszero(z)), add(div(sub(z, 1), denominator), 1))
        }
    }

    function rpow(
        uint256 x,
        uint256 n,
        uint256 scalar
    ) internal pure returns (uint256 z) {
        assembly {
            switch x
            case 0 {
                switch n
                case 0 {
                    // 0 ** 0 = 1
                    z := scalar
                }
                default {
                    // 0 ** n = 0
                    z := 0
                }
            }
            default {
                switch mod(n, 2)
                case 0 {
                    // If n is even, store scalar in z for now.
                    z := scalar
                }
                default {
                    // If n is odd, store x in z for now.
                    z := x
                }

                // Shifting right by 1 is like dividing by 2.
                let half := shr(1, scalar)

                for {
                    // Shift n right by 1 before looping to halve it.
                    n := shr(1, n)
                } n {
                    // Shift n right by 1 each iteration to halve it.
                    n := shr(1, n)
                } {
                    // Revert immediately if x ** 2 would overflow.
                    // Equivalent to iszero(eq(div(xx, x), x)) here.
                    if shr(128, x) {
                        revert(0, 0)
                    }

                    // Store x squared.
                    let xx := mul(x, x)

                    // Round to the nearest number.
                    let xxRound := add(xx, half)

                    // Revert if xx + half overflowed.
                    if lt(xxRound, xx) {
                        revert(0, 0)
                    }

                    // Set x to scaled xxRound.
                    x := div(xxRound, scalar)

                    // If n is even:
                    if mod(n, 2) {
                        // Compute z * x.
                        let zx := mul(z, x)

                        // If z * x overflowed:
                        if iszero(eq(div(zx, x), z)) {
                            // Revert if x is non-zero.
                            if iszero(iszero(x)) {
                                revert(0, 0)
                            }
                        }

                        // Round to the nearest number.
                        let zxRound := add(zx, half)

                        // Revert if zx + half overflowed.
                        if lt(zxRound, zx) {
                            revert(0, 0)
                        }

                        // Return properly scaled zxRound.
                        z := div(zxRound, scalar)
                    }
                }
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                        GENERAL NUMBER UTILITIES
    //////////////////////////////////////////////////////////////*/

    function sqrt(uint256 x) internal pure returns (uint256 z) {
        assembly {
            let y := x // We start y at x, which will help us make our initial estimate.

            z := 181 // The "correct" value is 1, but this saves a multiplication later.

            // This segment is to get a reasonable initial estimate for the Babylonian method. With a bad
            // start, the correct # of bits increases ~linearly each iteration instead of ~quadratically.

            // We check y >= 2^(k + 8) but shift right by k bits
            // each branch to ensure that if x >= 256, then y >= 256.
            if iszero(lt(y, 0x10000000000000000000000000000000000)) {
                y := shr(128, y)
                z := shl(64, z)
            }
            if iszero(lt(y, 0x1000000000000000000)) {
                y := shr(64, y)
                z := shl(32, z)
            }
            if iszero(lt(y, 0x10000000000)) {
                y := shr(32, y)
                z := shl(16, z)
            }
            if iszero(lt(y, 0x1000000)) {
                y := shr(16, y)
                z := shl(8, z)
            }

            // Goal was to get z*z*y within a small factor of x. More iterations could
            // get y in a tighter range. Currently, we will have y in [256, 256*2^16).
            // We ensured y >= 256 so that the relative difference between y and y+1 is small.
            // That's not possible if x < 256 but we can just verify those cases exhaustively.

            // Now, z*z*y <= x < z*z*(y+1), and y <= 2^(16+8), and either y >= 256, or x < 256.
            // Correctness can be checked exhaustively for x < 256, so we assume y >= 256.
            // Then z*sqrt(y) is within sqrt(257)/sqrt(256) of sqrt(x), or about 20bps.

            // For s in the range [1/256, 256], the estimate f(s) = (181/1024) * (s+1) is in the range
            // (1/2.84 * sqrt(s), 2.84 * sqrt(s)), with largest error when s = 1 and when s = 256 or 1/256.

            // Since y is in [256, 256*2^16), let a = y/65536, so that a is in [1/256, 256). Then we can estimate
            // sqrt(y) using sqrt(65536) * 181/1024 * (a + 1) = 181/4 * (y + 65536)/65536 = 181 * (y + 65536)/2^18.

            // There is no overflow risk here since y < 2^136 after the first branch above.
            z := shr(18, mul(z, add(y, 65536))) // A mul() is saved from starting z at 181.

            // Given the worst case multiplicative error of 2.84 above, 7 iterations should be enough.
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))

            // If x+1 is a perfect square, the Babylonian method cycles between
            // floor(sqrt(x)) and ceil(sqrt(x)). This statement ensures we return floor.
            // See: https://en.wikipedia.org/wiki/Integer_square_root#Using_only_integer_division
            // Since the ceil is rare, we save gas on the assignment and repeat division in the rare case.
            // If you don't care whether the floor or ceil square root is returned, you can remove this statement.
            z := sub(z, lt(div(x, z), z))
        }
    }

    function unsafeMod(uint256 x, uint256 y) internal pure returns (uint256 z) {
        assembly {
            // Mod x by y. Note this will return
            // 0 instead of reverting if y is zero.
            z := mod(x, y)
        }
    }

    function unsafeDiv(uint256 x, uint256 y) internal pure returns (uint256 r) {
        assembly {
            // Divide x by y. Note this will return
            // 0 instead of reverting if y is zero.
            r := div(x, y)
        }
    }

    function unsafeDivUp(uint256 x, uint256 y) internal pure returns (uint256 z) {
        assembly {
            // Add 1 to x * y if x % y > 0. Note this will
            // return 0 instead of reverting if y is zero.
            z := add(gt(mod(x, y), 0), div(x, y))
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

import '../../interfaces/ICustodian.sol';
import '../../libraries/FixedPointMathLib.sol';
import './interfaces/ICustodianRewards.sol';

/**
 * @title CustodianRewards
 * @author Atlendis Labs
 * @notice Implementation of the ICustodianRewards
 */
contract CustodianRewards is ICustodianRewards {
    /*//////////////////////////////////////////////////////////////
                               STRUCTS
    //////////////////////////////////////////////////////////////*/
    struct StakedPosition {
        uint256 initialValue;
        uint256 adjustedAmount;
    }

    /*//////////////////////////////////////////////////////////////
                              LIBRARIES
    //////////////////////////////////////////////////////////////*/

    using FixedPointMathLib for uint256;

    /*//////////////////////////////////////////////////////////////
                               STORAGE
    //////////////////////////////////////////////////////////////*/

    address public immutable REWARDS_MANAGER;
    ICustodian public immutable CUSTODIAN;

    uint256 public rewards;
    uint256 public liquidityRatio;
    uint256 public unallocatedRewards;
    uint256 public totalStakedAdjustedAmount;

    uint256 constant RAY = 1e27;

    // position ID -> staked position custodian
    mapping(uint256 => StakedPosition) public stakedPositions;

    /*//////////////////////////////////////////////////////////////
                              MODIFIERS
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Restrict sender to Rewards Manager contract
     */
    modifier onlyRewardsManager() {
        if (msg.sender != REWARDS_MANAGER) revert UNAUTHORIZED(msg.sender, REWARDS_MANAGER);
        _;
    }

    /**
     * @dev Trigger the collection of rewards
     */
    modifier rewardsCollector() {
        collectRewards();
        _;
    }

    /*//////////////////////////////////////////////////////////////
                             CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Constructor
     * @param rewardsManager Address of the rewards manager contract
     * @param custodian Address of the custodian contract
     */
    constructor(address rewardsManager, address custodian) {
        REWARDS_MANAGER = rewardsManager;
        CUSTODIAN = ICustodian(custodian);
        liquidityRatio = RAY;
    }

    /*//////////////////////////////////////////////////////////////
                           PUBLIC METHODS
    //////////////////////////////////////////////////////////////*/

    /**
     * @inheritdoc IRewardsModule
     */
    function stake(
        uint256 positionId,
        address owner,
        uint256 rate,
        uint256 positionValue
    ) public onlyRewardsManager rewardsCollector {
        uint256 adjustedAmount = positionValue.div(liquidityRatio, RAY);
        totalStakedAdjustedAmount += adjustedAmount;
        stakedPositions[positionId] = StakedPosition({initialValue: positionValue, adjustedAmount: adjustedAmount});
        emit PositionStaked(positionId, owner, rate, positionValue, adjustedAmount);
    }

    /**
     * @inheritdoc IRewardsModule
     */
    function unstake(uint256 positionId, address owner) public onlyRewardsManager rewardsCollector {
        StakedPosition memory stakedPosition = stakedPositions[positionId];

        uint256 positionRewards = stakedPosition.adjustedAmount.mul(liquidityRatio, RAY) - stakedPosition.initialValue;

        totalStakedAdjustedAmount -= stakedPosition.adjustedAmount;
        delete stakedPositions[positionId];

        CUSTODIAN.withdrawRewards(positionRewards, owner);

        emit PositionUnstaked(positionId, owner, positionRewards);
    }

    /**
     * @inheritdoc IRewardsModule
     */
    function claimRewards(uint256 positionId, address owner) public onlyRewardsManager rewardsCollector {
        StakedPosition storage stakedPosition = stakedPositions[positionId];

        uint256 positionRewards = stakedPosition.adjustedAmount.mul(liquidityRatio, RAY) - stakedPosition.initialValue;
        uint256 adjustedAmountDecrease = stakedPosition.adjustedAmount -
            stakedPosition.initialValue.div(liquidityRatio, RAY);
        totalStakedAdjustedAmount -= adjustedAmountDecrease;
        stakedPosition.adjustedAmount -= adjustedAmountDecrease;

        CUSTODIAN.withdrawRewards(positionRewards, owner);

        emit RewardsClaimed(positionId, owner, positionRewards, adjustedAmountDecrease);
    }

    /*//////////////////////////////////////////////////////////////
                           PRIVATE METHODS
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Collect the rewards since last update and distribute them to staked positions
     */
    function collectRewards() private {
        CUSTODIAN.collectRewards();
        uint256 currentRewards = CUSTODIAN.getRewards();
        uint256 rewardsSinceLastUpdate = currentRewards - rewards;

        if (totalStakedAdjustedAmount > 0) {
            liquidityRatio += rewardsSinceLastUpdate.div(totalStakedAdjustedAmount, RAY);
        } else {
            unallocatedRewards += rewardsSinceLastUpdate;
        }
        rewards = currentRewards;

        emit RewardsCollected(rewards, liquidityRatio, unallocatedRewards);
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

/**
 * @notice ICustodian
 * @author Atlendis Labs
 * @notice Interface of the Custodian contract
 *         A custodian contract is associated to a product contract.
 *         It receives funds by the associated product contract.
 *         A yield strategy is chosen in order to generate rewards based on the deposited funds.
 */
interface ICustodian {
    /**
     * @notice Withdraw an amount of rewards
     * @param amount The amount of rewards to be withdrawn
     * @param to Address that will receive the rewards
     **/
    function withdrawRewards(uint256 amount, address to) external;

    /**
     * @notice Retrieve the rewards generated by the custodian
     * @return rewards Amount of rewards
     */
    function getRewards() external view returns (uint256 rewards);

    /**
     * @notice Collect the rewards on the custodian
     */
    function collectRewards() external;

    /**
     * @notice Retrieve the decimals of the underlying asset
     & @return decimals Decimals of the underlying asset
     */
    function getAssetDecimals() external view returns (uint256 decimals);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

import './IRewardsModule.sol';

/**
 * @title ICustodianRewards
 * @author Atlendis Labs
 * @notice Interface of the Custodian Rewards module contract
 *         This module is controlled by a rewards manager.
 *         It allows to retrieve the generated rewards by a custodian contract and distribute them to staked positions.
 */
interface ICustodianRewards is IRewardsModule {
    /**
     * @notice Emitted when a position has been staked
     * @param positionId ID of the position
     * @param owner Address of the owner of the position
     * @param rate Rate of the position
     * @param positionValue Value of the position at staking time
     * @param adjustedAmount Value of the computed adjusted amount
     */
    event PositionStaked(
        uint256 indexed positionId,
        address indexed owner,
        uint256 rate,
        uint256 positionValue,
        uint256 adjustedAmount
    );

    /**
     * @notice Emitted when a position has been unstaked
     * @param positionId ID of the position
     * @param owner Address of the owner of the position
     * @param positionRewards Value of the position rewards
     */
    event PositionUnstaked(uint256 indexed positionId, address indexed owner, uint256 positionRewards);

    /**
     * @notice Emitted when rewards of a staked position has been claimed
     * @param positionId ID of the position
     * @param owner Address of the owner of the position
     * @param positionRewards Value of the position rewards
     * @param adjustedAmountDecrease Value of the computed decrease in adjusted amount
     */
    event RewardsClaimed(
        uint256 indexed positionId,
        address indexed owner,
        uint256 positionRewards,
        uint256 adjustedAmountDecrease
    );

    /**
     * @notice Emitted when rewards are colleted
     * @param rewards Total amount of collected rewards
     * @param liquidityRatio Value of the computed liquidity ratio
     * @param unallocatedRewards Amount of unallocated rewards
     */
    event RewardsCollected(uint256 rewards, uint256 liquidityRatio, uint256 unallocatedRewards);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

import 'lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol';

import '../../../libraries/FixedPointMathLib.sol';
import './../libraries/PoolDataTypes.sol';
import './../libraries/PositionDataTypes.sol';
import './../libraries/SingleBondIssuanceLogic.sol';
import './interfaces/ISBIBorrowers.sol';
import './SBIPool.sol';

/**
 * @title SBIBorrowers
 * @author Atlendis Labs
 * @notice Implementation of the ISBIBorrowers
 */
abstract contract SBIBorrowers is ISBIBorrowers, SBIPool {
    /*//////////////////////////////////////////////////////////////
                                LIBRARIES
    //////////////////////////////////////////////////////////////*/

    using FixedPointMathLib for uint256;

    /*//////////////////////////////////////////////////////////////
                                STORAGE
    //////////////////////////////////////////////////////////////*/
    uint256 public borrowTimestamp;
    uint256 public atlendisRevenue;
    uint256 public theoreticalPoolNotional;

    /*//////////////////////////////////////////////////////////////
                                MODIFIERS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Restrict the sender of the message to the borrowe, i.e. default admin
     */
    modifier onlyBorrower() {
        require(permissionedBorrowers[msg.sender], 'Only permissioned borrower allowed');
        _;
    }

    /*//////////////////////////////////////////////////////////////
                        EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function borrow(address to) external onlyBorrower onlyInPhase(PoolDataTypes.PoolPhase.ISSUANCE) {
        if (block.timestamp > ISSUANCE_PHASE_START_TIMESTAMP + ISSUANCE_PERIOD_DURATION) {
            revert SingleBondIssuanceErrors.SBI_ISSUANCE_PHASE_EXPIRED();
        }
        uint256 borrowedAmount = deposits < TARGET_ISSUANCE_AMOUNT ? deposits : TARGET_ISSUANCE_AMOUNT;
        if (borrowedAmount == 0) {
            revert SingleBondIssuanceErrors.SBI_ZERO_BORROW_AMOUNT_NOT_ALLOWED();
        }
        poolPhase = PoolDataTypes.PoolPhase.ISSUED;
        uint256 issuanceFee = ISSUANCE_FEE_PC.mul(borrowedAmount, TOKEN_DENOMINATOR);
        atlendisRevenue += issuanceFee;
        bool borrowComplete = false;
        uint256 currentInterestRate = MIN_RATE;
        uint256 deltaTheoreticalPoolNotional;
        uint256 remainingAmount = borrowedAmount;
        while (remainingAmount > 0 && currentInterestRate <= MAX_RATE && !borrowComplete) {
            if (ticks[currentInterestRate].depositedAmount > 0) {
                (borrowComplete, remainingAmount, deltaTheoreticalPoolNotional) = SingleBondIssuanceLogic
                    .borrowFromTick(
                        remainingAmount,
                        ticks[currentInterestRate],
                        currentInterestRate,
                        LOAN_DURATION,
                        TOKEN_DENOMINATOR
                    );
                theoreticalPoolNotional += deltaTheoreticalPoolNotional;
            }
            currentInterestRate += RATE_SPACING;
        }
        if (remainingAmount > 0) {
            revert SingleBondIssuanceErrors.SBI_NOT_ENOUGH_FUNDS_AVAILABLE();
        }

        borrowTimestamp = block.timestamp;
        SingleBondIssuanceLogic.transferERC20(
            to,
            UNDERLYING_TOKEN,
            borrowedAmount - issuanceFee + cancellationFeeEscrow
        );

        emit Borrowed(msg.sender, address(this), borrowedAmount, issuanceFee, cancellationFeeEscrow);
    }

    function repay() external onlyBorrower onlyInPhase(PoolDataTypes.PoolPhase.ISSUED) {
        if (block.timestamp < borrowTimestamp + LOAN_DURATION) {
            revert SingleBondIssuanceErrors.SBI_EARLY_REPAY_NOT_ALLOWED();
        }
        uint256 lateRepaymentThreshold = borrowTimestamp + LOAN_DURATION + REPAYMENT_PERIOD_DURATION;
        uint256 timeDeltaIntoLateRepay = (block.timestamp > lateRepaymentThreshold)
            ? block.timestamp - lateRepaymentThreshold
            : 0;
        uint256 currentInterestRate = MIN_RATE;
        uint256 repaidAmount;
        uint256 interestToRepay;
        while (currentInterestRate <= MAX_RATE) {
            PoolDataTypes.Tick storage tick = ticks[currentInterestRate];
            if (tick.borrowedAmount > 0) {
                (uint256 amountToRepayForTick, uint256 interestRepayedForTick) = SingleBondIssuanceLogic.repayForTick(
                    tick,
                    currentInterestRate,
                    borrowTimestamp,
                    timeDeltaIntoLateRepay,
                    LOAN_DURATION + REPAYMENT_PERIOD_DURATION,
                    LATE_REPAYMENT_FEE_RATE,
                    TOKEN_DENOMINATOR
                );
                interestToRepay += interestRepayedForTick;
                repaidAmount += amountToRepayForTick;
            }
            currentInterestRate += RATE_SPACING;
        }
        uint256 atlendisFee = interestToRepay.mul(REPAYMENT_FEE_PC, TOKEN_DENOMINATOR);
        atlendisRevenue += atlendisFee;
        poolPhase = PoolDataTypes.PoolPhase.REPAID;
        SingleBondIssuanceLogic.transferERC20From(
            msg.sender,
            address(this),
            UNDERLYING_TOKEN,
            repaidAmount + atlendisFee
        );
        emit Repaid(msg.sender, address(this), repaidAmount, atlendisFee);
    }

    function partialRepay(uint256 amount) external onlyBorrower onlyInPhase(PoolDataTypes.PoolPhase.ISSUED) {
        if (block.timestamp < borrowTimestamp + LOAN_DURATION) {
            revert SingleBondIssuanceErrors.SBI_EARLY_PARTIAL_REPAY_NOT_ALLOWED();
        }
        uint256 currentInterestRate = MIN_RATE;
        while (currentInterestRate <= MAX_RATE) {
            PoolDataTypes.Tick storage tick = ticks[currentInterestRate];
            if (tick.borrowedAmount > 0) {
                SingleBondIssuanceLogic.partialRepayForTick(
                    tick,
                    currentInterestRate,
                    borrowTimestamp,
                    amount,
                    theoreticalPoolNotional,
                    TOKEN_DENOMINATOR
                );
            }
            currentInterestRate += RATE_SPACING;
        }
        poolPhase = PoolDataTypes.PoolPhase.PARTIAL_DEFAULT;
        SingleBondIssuanceLogic.transferERC20From(msg.sender, address(this), UNDERLYING_TOKEN, amount);

        emit PartiallyRepaid(msg.sender, address(this), amount);
    }

    function enableBookBuildingPhase() external onlyBorrower onlyInPhase(PoolDataTypes.PoolPhase.INACTIVE) {
        cancellationFeeEscrow = CANCELLATION_FEE_PC.mul(TARGET_ISSUANCE_AMOUNT, TOKEN_DENOMINATOR);
        SingleBondIssuanceLogic.transferERC20From(msg.sender, address(this), UNDERLYING_TOKEN, cancellationFeeEscrow);
        poolPhase = PoolDataTypes.PoolPhase.BOOK_BUILDING;
        emit BookBuildingPhaseEnabled(address(this), cancellationFeeEscrow);
    }

    function withdrawRemainingEscrow(address to) external onlyBorrower onlyInPhase(PoolDataTypes.PoolPhase.CANCELLED) {
        SingleBondIssuanceLogic.transferERC20(to, UNDERLYING_TOKEN, cancellationFeeEscrow);
        emit EscrowWithdrawn(address(this), cancellationFeeEscrow);
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

/**
 * @title PoolDataTypes library
 * @dev Defines the structs and enums related to the pool
 */
library PoolDataTypes {
    struct Tick {
        uint256 depositedAmount;
        uint256 borrowedAmount;
        uint256 repaidAmount;
    }

    enum PoolPhase {
        INACTIVE,
        BOOK_BUILDING,
        ISSUANCE,
        ISSUED,
        REPAID,
        PARTIAL_DEFAULT,
        DEFAULT,
        CANCELLED
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

/**
 * @title PoolDataTypes library
 * @dev Defines the structs related to the positions
 */
library PositionDataTypes {
    struct PositionDetails {
        uint256 depositedAmount;
        uint256 rate;
        uint256 depositBlockNumber;
        bool hasWithdrawPartially;
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

import 'lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol';
import 'lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol';
import '../../../libraries/FixedPointMathLib.sol';

import '../../../libraries/TimeValue.sol';
import './PoolDataTypes.sol';
import './SingleBondIssuanceErrors.sol';

/**
 * @title SingleBondIssuanceLogic library
 * @dev Collection of methods used in the SingleBondIssuance contract
 */
library SingleBondIssuanceLogic {
    using SafeERC20 for ERC20;
    using FixedPointMathLib for uint256;

    /**
     * @dev Wrapper over ERC20 safeTransfer
     * @param from Address for which the balance will decrease
     * @param to Address to which the balance will increase
     * @param underlyingToken Address of the ERC20 contract
     * @param amount Amount to be transferred
     */
    function transferERC20From(
        address from,
        address to,
        address underlyingToken,
        uint256 amount
    ) internal {
        ERC20(underlyingToken).safeTransferFrom(from, to, amount);
    }

    /**
     * @dev Wrapper over ERC20 safeTransfer, `from` is forced as the caller
     * @param to Address to which the balance will increase
     * @param underlyingToken Address of the ERC20 contract
     * @param amount Amount to be transferred
     */
    function transferERC20(
        address to,
        address underlyingToken,
        uint256 amount
    ) internal {
        ERC20(underlyingToken).safeTransfer(to, amount);
    }

    /**
     * @dev Deposit amount of ERC20 token to tick
     * @param tick The tick
     * @param amount The amount
     * @param underlyingToken The address of the ERC20 token
     */
    function depositToTick(
        PoolDataTypes.Tick storage tick,
        uint256 amount,
        address underlyingToken
    ) external {
        tick.depositedAmount += amount;
        transferERC20From(msg.sender, address(this), underlyingToken, amount);
    }

    /**
     * @dev Transfer an amount from one tick to another
     * @param currentTick Tick for which the deposited amount will decrease
     * @param newTick Tick for which the deposited amount will increase
     * @param amount The transferred amount
     */
    function updateTicksDeposit(
        PoolDataTypes.Tick storage currentTick,
        PoolDataTypes.Tick storage newTick,
        uint256 amount
    ) external {
        currentTick.depositedAmount -= amount;
        newTick.depositedAmount += amount;
    }

    /**
     * @dev Derive the allowed amount to be withdrawn
     *      The sequence of conditional branches is relevant for correct logic
     *      Decrease tick deposited amount if the contract is in the Book Building phase
     * @param tick The tick
     * @param issuancePhase The current issuance phase
     * @param depositedAmount The original deposited amount in the position
     * @param didPartiallyWithdraw True if the position has already been partially withdrawn
     * @param denominator The denominator value
     * @return amountToWithdraw The allowed amount to be withdrawn
     * @return partialWithdrawPartialFilledTick True if it is a partial withdraw
     */
    function withdrawFromTick(
        PoolDataTypes.Tick storage tick,
        PoolDataTypes.PoolPhase issuancePhase,
        uint256 depositedAmount,
        bool didPartiallyWithdraw,
        uint256 denominator
    ) external returns (uint256 amountToWithdraw, bool partialWithdrawPartialFilledTick) {
        /// @dev The order of conditional statements in this function is relevant to the correctness of the logic
        if (issuancePhase == PoolDataTypes.PoolPhase.BOOK_BUILDING) {
            amountToWithdraw = depositedAmount;
            tick.depositedAmount -= amountToWithdraw;
            return (amountToWithdraw, false);
        }

        // partial withdraw during borrow before repay
        if (
            !didPartiallyWithdraw &&
            tick.borrowedAmount > 0 &&
            tick.borrowedAmount < tick.depositedAmount &&
            (issuancePhase == PoolDataTypes.PoolPhase.ISSUED || issuancePhase == PoolDataTypes.PoolPhase.DEFAULT)
        ) {
            amountToWithdraw = depositedAmount.mul(tick.depositedAmount - tick.borrowedAmount, denominator).div(
                tick.depositedAmount,
                denominator
            );
            return (amountToWithdraw, true);
        }

        // if tick was not matched
        if (tick.borrowedAmount == 0 && issuancePhase != PoolDataTypes.PoolPhase.CANCELLED) {
            return (depositedAmount, false);
        }

        // If bond has been paid in full, partially or issuance was cancelled
        if (
            (tick.depositedAmount == tick.borrowedAmount && tick.repaidAmount > 0) ||
            issuancePhase == PoolDataTypes.PoolPhase.CANCELLED
        ) {
            amountToWithdraw = depositedAmount.mul(tick.repaidAmount, denominator).div(
                tick.depositedAmount,
                denominator
            );
            return (amountToWithdraw, false);
        }

        // If bond has been paid back partially or fully and the tick was partially filled
        if (tick.depositedAmount > tick.borrowedAmount && tick.repaidAmount != 0) {
            uint256 noneBorrowedAmountToWithdraw = didPartiallyWithdraw
                ? 0
                : depositedAmount.mul(tick.depositedAmount - tick.borrowedAmount, denominator).div(
                    tick.depositedAmount,
                    denominator
                );
            amountToWithdraw =
                depositedAmount.mul(tick.repaidAmount, denominator).div(tick.depositedAmount, denominator) +
                noneBorrowedAmountToWithdraw;
            return (amountToWithdraw, false);
        }

        revert SingleBondIssuanceErrors.SBI_WITHDRAWAL_NOT_ALLOWED(issuancePhase);
    }

    /**
     * @dev Register borrowed amount in tick and compute the value of emitted bonds at maturity
     * @param amountToBorrow The amount to borrow
     * @param tick The tick
     * @param rate The rate of the tick
     * @param maturity The maturity of the loan
     * @param denominator The denominator value
     * @return borrowComplete True if the deposited amount of the tick is larger than the amount to borrow
     * @return remainingAmount Remaining amount to borrow
     * @return deltaTheoreticalPoolNotional The value of emitted bonds at maturity
     */
    function borrowFromTick(
        uint256 amountToBorrow,
        PoolDataTypes.Tick storage tick,
        uint256 rate,
        uint256 maturity,
        uint256 denominator
    )
        external
        returns (
            bool borrowComplete,
            uint256 remainingAmount,
            uint256 deltaTheoreticalPoolNotional
        )
    {
        if (tick.depositedAmount == 0) return (false, amountToBorrow, 0);

        if (tick.depositedAmount < amountToBorrow) {
            amountToBorrow -= tick.depositedAmount;
            tick.borrowedAmount += tick.depositedAmount;
            deltaTheoreticalPoolNotional = tick.depositedAmount.div(
                TimeValue.getDiscountFactor(rate, maturity, denominator),
                denominator
            );
            return (false, amountToBorrow, deltaTheoreticalPoolNotional);
        }

        if (tick.depositedAmount >= amountToBorrow) {
            tick.borrowedAmount += amountToBorrow;
            deltaTheoreticalPoolNotional = amountToBorrow.div(
                TimeValue.getDiscountFactor(rate, maturity, denominator),
                denominator
            );
            return (true, 0, deltaTheoreticalPoolNotional);
        }
    }

    /**
     * @dev Register repaid amount in tick
     * @param tick The tick
     * @param rate The rate of the tick
     * @param borrowTimeStamp The borrow timestamp
     * @param timeDeltaIntoLateRepay Time since late repay threshold
     * @param timeDeltaStandardAccruals Time during which standard accrual is applied
     * @param lateRepaymentRate Late repayment rate
     * @param denominator The denominator value
     * @return amountToRepayForTick Amount to be repaid
     * @return yieldPayed Payed yield
     */
    function repayForTick(
        PoolDataTypes.Tick storage tick,
        uint256 rate,
        uint256 borrowTimeStamp,
        uint256 timeDeltaIntoLateRepay,
        uint256 timeDeltaStandardAccruals,
        uint256 lateRepaymentRate,
        uint256 denominator
    ) external returns (uint256 amountToRepayForTick, uint256 yieldPayed) {
        if (timeDeltaIntoLateRepay > 0) {
            amountToRepayForTick = tick
                .borrowedAmount
                .div(TimeValue.getDiscountFactor(rate, timeDeltaStandardAccruals, denominator), denominator)
                .div(TimeValue.getDiscountFactor(lateRepaymentRate, timeDeltaIntoLateRepay, denominator), denominator);
        } else {
            amountToRepayForTick = tick.borrowedAmount.div(
                TimeValue.getDiscountFactor(rate, block.timestamp - borrowTimeStamp, denominator),
                denominator
            );
        }

        yieldPayed = amountToRepayForTick - tick.borrowedAmount;
        tick.repaidAmount = amountToRepayForTick;
    }

    /**
     * @dev Register repaid amount in tick in the case of a partial repay
     * @param tick The tick
     * @param rate The rate of the tick
     * @param borrowTimeStamp The borrow timestamp
     * @param totalRepaidAmount Amount to be repaid
     * @param poolNotional The value of emitted bonds at maturity
     * @param denominator The denominator value
     */
    function partialRepayForTick(
        PoolDataTypes.Tick storage tick,
        uint256 rate,
        uint256 borrowTimeStamp,
        uint256 totalRepaidAmount,
        uint256 poolNotional,
        uint256 denominator
    ) external {
        uint256 amountToRepayForTick = tick.borrowedAmount.div(
            TimeValue.getDiscountFactor(rate, block.timestamp - borrowTimeStamp, denominator),
            denominator
        );
        tick.repaidAmount = amountToRepayForTick.div(poolNotional, denominator).mul(totalRepaidAmount, denominator);
    }

    /**
     * @dev Distributes escrowed cancellation fee to tick
     * @param tick The tick
     * @param cancellationFeeRate The cancelation fee rate
     * @param remainingEscrow The remaining amount in escrow
     * @param denominator The denominator value
     */
    function repayCancelFeeForTick(
        PoolDataTypes.Tick storage tick,
        uint256 cancellationFeeRate,
        uint256 remainingEscrow,
        uint256 denominator
    ) external returns (uint256 cancelFeeForTick) {
        if (cancellationFeeRate.mul(tick.depositedAmount, denominator) > remainingEscrow) {
            cancelFeeForTick = remainingEscrow;
        } else {
            cancelFeeForTick = cancellationFeeRate.mul(tick.depositedAmount, denominator);
        }
        tick.repaidAmount = tick.depositedAmount + cancelFeeForTick;
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

/**
 * @title ISBIBorrowers
 * @author Atlendis Labs
 * @notice Interface of the Single Bond Issuance Borrowers module contract
 *         It exposes the available methods for permissioned borrowers.
 */
interface ISBIBorrowers {
    /**
     * @notice Emitted when a borrow has been made
     *         The transferred amount is given by borrowedAmount + cancellationFeeEscrow - issuanceFee
     * @param borrower Address of the borrower
     * @param contractAddress Address of the contract
     * @param borrowedAmount Borrowed amount
     * @param issuanceFee Issuance fee
     * @param cancellationFeeEscrow Cancelation fee at borrow time
     */
    event Borrowed(
        address indexed borrower,
        address contractAddress,
        uint256 borrowedAmount,
        uint256 issuanceFee,
        uint256 cancellationFeeEscrow
    );

    /**
     * @notice Emitted when a loan has been partially repaid
     * @param borrower Address of the borrower
     * @param contractAddress Address of the contract
     * @param repaidAmount Repaid amount
     */
    event PartiallyRepaid(address indexed borrower, address contractAddress, uint256 repaidAmount);

    /**
     * @notice Emitted when a loan has been repaid
     *         Total paid amount by borrower is given by repaidAmount + atlendisFee
     * @param borrower Address of the borrower
     * @param contractAddress Address of the contract
     * @param repaidAmount Repaid amount
     * @param atlendisFee Repayment fee
     */
    event Repaid(address indexed borrower, address contractAddress, uint256 repaidAmount, uint256 atlendisFee);

    /**
     * @notice Emitted when the remaining cancellation fee has been withdrawn
     * @param contractAddress Address of the contract
     * @param amount Withdrawn remaining cancellation fee amount
     */
    event EscrowWithdrawn(address indexed contractAddress, uint256 amount);

    /**
     * Borrow up to a maximum of the parametrised target issuance amount
     * @param to Address to which the borrowed amount is transferred
     *
     * Emits a {Borrowed} event
     */
    function borrow(address to) external;

    /**
     * @notice Repay a loan
     *
     * Emits a {Repaid} event
     */
    function repay() external;

    /**
     * @notice Partially repay a loan
     * @param amount The repaid amount
     *
     * Emits a {PartiallyRepaid} event
     */
    function partialRepay(uint256 amount) external;

    /**
     * @notice Enable the book building phase by depositing in escrow the cancellation fee amount of tokens
     *
     * Emits a {BookBuildingPhaseEnabled} event
     */
    function enableBookBuildingPhase() external;

    /**
     * @notice Withdraw the remaining escrow
     * @param to Address to which the remaining escrow amount is transferred
     *
     * Emits a {EscrowWithdrawn} event
     */
    function withdrawRemainingEscrow(address to) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

import './../libraries/PoolDataTypes.sol';
import './../libraries/SingleBondIssuanceErrors.sol';
import './interfaces/ISBIPool.sol';
import 'lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol';

/**
 * @title SBIPool
 * @author Atlendis Labs
 * @notice Implementation of the ISBIPool
 *         Contains the core storage of the pool and shared methods accross the modules
 */
abstract contract SBIPool is ISBIPool {
    /*//////////////////////////////////////////////////////////////
                                STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public immutable CREATION_TIMESTAMP;
    uint256 public ISSUANCE_PHASE_START_TIMESTAMP;

    address public immutable UNDERLYING_TOKEN;
    uint256 public immutable TOKEN_DENOMINATOR;
    uint256 public immutable MIN_RATE;
    uint256 public immutable MAX_RATE;
    uint256 public immutable RATE_SPACING;
    uint256 public immutable LOAN_DURATION;
    uint256 public immutable TARGET_ISSUANCE_AMOUNT;
    uint256 public immutable BOOK_BUILDING_PERIOD_DURATION;
    uint256 public immutable ISSUANCE_PERIOD_DURATION;
    uint256 public immutable REPAYMENT_PERIOD_DURATION;
    uint256 public immutable ISSUANCE_FEE_PC; // value for the percentage of the borrowed amount which is taken as a fee at borrow time
    uint256 public immutable REPAYMENT_FEE_PC; // value for the percentage of the interests amount which is taken as a fee at repay time
    uint256 public immutable LATE_REPAYMENT_FEE_RATE;
    uint256 public immutable CANCELLATION_FEE_PC; // value for the percentage of the target issuance amount which is needed in escrow in order to enable the book building phase

    PoolDataTypes.PoolPhase public poolPhase;
    mapping(uint256 => PoolDataTypes.Tick) public ticks;

    mapping(address => bool) public permissionedBorrowers;

    uint256 public deposits;

    uint256 public cancellationFeeEscrow;

    /*//////////////////////////////////////////////////////////////
                                CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(bytes memory feeConfigs, bytes memory parametersConfig) {
        (LATE_REPAYMENT_FEE_RATE, ISSUANCE_FEE_PC, REPAYMENT_FEE_PC, CANCELLATION_FEE_PC) = abi.decode(
            feeConfigs,
            (uint256, uint256, uint256, uint256)
        );

        (
            UNDERLYING_TOKEN,
            MIN_RATE,
            MAX_RATE,
            RATE_SPACING,
            LOAN_DURATION,
            REPAYMENT_PERIOD_DURATION,
            ISSUANCE_PERIOD_DURATION,
            BOOK_BUILDING_PERIOD_DURATION,
            TARGET_ISSUANCE_AMOUNT
        ) = abi.decode(
            parametersConfig,
            (address, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256)
        );

        TOKEN_DENOMINATOR = 10**ERC20(UNDERLYING_TOKEN).decimals();
        if (MIN_RATE >= MAX_RATE) revert SingleBondIssuanceErrors.SBI_INVALID_RATE_BOUNDARIES();
        if (RATE_SPACING == 0) revert SingleBondIssuanceErrors.SBI_INVALID_ZERO_RATE_SPACING();
        if ((MAX_RATE - MIN_RATE) % RATE_SPACING != 0) revert SingleBondIssuanceErrors.SBI_INVALID_RATE_PARAMETERS();
        if (
            ISSUANCE_FEE_PC >= TOKEN_DENOMINATOR ||
            REPAYMENT_FEE_PC >= TOKEN_DENOMINATOR ||
            CANCELLATION_FEE_PC >= TOKEN_DENOMINATOR
        ) revert SingleBondIssuanceErrors.SBI_INVALID_PERCENTAGE_VALUE();

        if (CANCELLATION_FEE_PC > 0) {
            poolPhase = PoolDataTypes.PoolPhase.INACTIVE;
        } else {
            poolPhase = PoolDataTypes.PoolPhase.BOOK_BUILDING;
            emit BookBuildingPhaseEnabled(address(this), 0);
        }
        CREATION_TIMESTAMP = block.timestamp;
    }

    /*//////////////////////////////////////////////////////////////
                                MODIFIERS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Allow only if the pool phase is the expected one
     * @param expectedPhase Expected phase
     */
    modifier onlyInPhase(PoolDataTypes.PoolPhase expectedPhase) {
        if (poolPhase != expectedPhase) revert SingleBondIssuanceErrors.SBI_INVALID_PHASE(expectedPhase, poolPhase);
        _;
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

import './FixedPointMathLib.sol';

/**
 * @title TimeValue library
 * @author Atlendis Labs
 * @dev Contains the utilitaries methods associated to time computation in the Atlendis Protocol
 */
library TimeValue {
    using FixedPointMathLib for uint256;
    uint256 internal constant SECONDS_PER_YEAR = 365 days;

    /**
     * @dev Compute the discount factor given a rate and a time delta with respect to the time at which the bonds have been emitted
     *      Exact computation is defined as 1 / (1 + rate)^deltaTime
     *      The approximation uses up to the first order of the Taylor series, i.e. 1 / (1 + deltaTime * rate)
     * @param rate Rate
     * @param timeDelta Time difference since the the time at which the bonds have been emitted
     * @param denominator The denominator value
     * @return discountFactor The discount factor
     */
    function getDiscountFactor(
        uint256 rate,
        uint256 timeDelta,
        uint256 denominator
    ) internal pure returns (uint256 discountFactor) {
        uint256 timeInYears = (timeDelta * denominator).div(SECONDS_PER_YEAR * denominator, denominator);
        /// TODO: #92 Higher order Taylor series
        return
            denominator.div(
                denominator + rate.mul(timeInYears, denominator), //+
                // (rate.mul(rate, denominator).mul(timeInYears.mul(timeInYears - 1, denominator), denominator)) /
                // 2 +
                // (rate.mul(rate, denominator).mul(rate, denominator)).mul(
                //     timeInYears.mul(timeInYears - 1, denominator).mul(timeInYears - 2, denominator),
                //     denominator
                // ) /
                // 6,
                denominator
            );
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

import './PoolDataTypes.sol';

/**
 * @title SingleBondIssuanceErrors library
 * @dev Defines the errors used in the Single Bond Issuance product
 */
library SingleBondIssuanceErrors {
    error SBI_INVALID_RATE_BOUNDARIES(); // "Invalid rate boundaries parameters"
    error SBI_INVALID_ZERO_RATE_SPACING(); // "Can not have rate spacing to zero"
    error SBI_INVALID_RATE_PARAMETERS(); // "Invalid rate parameters"
    error SBI_INVALID_PERCENTAGE_VALUE(); // "Invalid percentage value"

    error SBI_OUT_OF_BOUND_MIN_RATE(); // "Input rate is below min rate"
    error SBI_OUT_OF_BOUND_MAX_RATE(); // "Input rate is above max rate"
    error SBI_INVALID_RATE_SPACING(); // "Input rate is invalid with respect to rate spacing"

    error SBI_INVALID_PHASE(PoolDataTypes.PoolPhase expectedPhase, PoolDataTypes.PoolPhase actualPhase); // "Phase is invalid for this operation"
    error SBI_ZERO_AMOUNT(); // "Cannot deposit zero amount";
    error SBI_MGMT_ONLY_OWNER(); // "Only the owner of the position token can manage it (update rate, withdraw)";
    error SBI_TIMELOCK(); // "Cannot withdraw or update rate in the same block as deposit";
    error SBI_BOOK_BUILDING_TIME_NOT_OVER(); // "Book building time window is not over";
    error SBI_ALLOWED_ONLY_BOOK_BUILDING_PHASE(); // "Action only allowed during the book building phase";
    error SBI_EARLY_REPAY_NOT_ALLOWED(); // "Bond is not callable";
    error SBI_EARLY_PARTIAL_REPAY_NOT_ALLOWED(); // "Partial repays are not allowed before maturity or during not allowed phases";
    error SBI_NOT_ENOUGH_FUNDS_AVAILABLE(); // "Not enough funds available in pool"
    error SBI_NO_WITHDRAWALS_ISSUANCE_PHASE(); // "No withdrawals during issuance phase"
    error SBI_WITHDRAW_AMOUNT_TOO_LARGE(); // "Partial withdraws are allowed for withdrawals of less hten 100% of a position"
    error SBI_PARTIAL_WITHDRAW_NOT_ALLOWED(); // "Partial withdraws are allowed during the book building phase"
    error SBI_WITHDRAWAL_NOT_ALLOWED(PoolDataTypes.PoolPhase poolPhase); // "Withdrawal not possible"
    error SBI_ZERO_BORROW_AMOUNT_NOT_ALLOWED(); // "Borrowing from an empty pool is not allowed"
    error SBI_ISSUANCE_PHASE_EXPIRED(); // "Issuance phase has expired"
    error SBI_ISSUANCE_PERIOD_STILL_ACTIVE(); // "Issuance period not expired yet"
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

/**
 * @title ISBIPool
 * @author Atlendis Labs
 * @notice Interface of the Single Bond Issuance core Pool module contract
 *         It exposes the available methods for all the modules
 */
interface ISBIPool {
    /**
     * @notice Emitted when the book building phase has started
     * @param contractAddress Address of the contract
     */
    event BookBuildingPhaseEnabled(address contractAddress, uint256 cancellationFeeEscrow);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

import 'lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol';

import './libraries/PoolDataTypes.sol';
import './libraries/PositionDataTypes.sol';
import './interfaces/ISingleBondIssuance.sol';
import './modules/SBIGovernance.sol';
import './modules/SBIPool.sol';
import './modules/SBILenders.sol';
import './modules/SBIBorrowers.sol';

/**
 * @title SingleBondIssuance
 * @author Atlendis Labs
 * @notice Implementation of the ISingleBondIssuance
 */
contract SingleBondIssuance is SBIPool, SBIGovernance, SBIBorrowers, SBILenders {
    /*//////////////////////////////////////////////////////////////
                                LIBRARIES
    //////////////////////////////////////////////////////////////*/

    using FixedPointMathLib for uint256;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Constructor - pass parameters to modules
     * @param governance Address of the governance
     * @param feeConfigs Configurations around fees
     * @param parametersConfig Other Configurations
     * @param name ERC721 name of the positions
     * @param symbol ERC721 symbol of the positions
     */
    constructor(
        address governance,
        bytes memory feeConfigs,
        bytes memory parametersConfig,
        string memory name,
        string memory symbol
    ) SBILenders(name, symbol) SBIGovernance(governance) SBIPool(feeConfigs, parametersConfig) {}

    /*//////////////////////////////////////////////////////////////
                            VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function getPositionComposition(uint256 positionId)
        public
        view
        returns (
            uint256 depositedAmount,
            uint256 borrowedAmount,
            uint256 theoreticalBondValue,
            uint256 noneBorrowedAvailableAmount
        )
    {
        PositionDataTypes.PositionDetails memory position = positions[positionId];
        PoolDataTypes.Tick storage tick = ticks[position.rate];

        if (tick.borrowedAmount == 0) {
            return (position.depositedAmount, 0, 0, position.depositedAmount);
        }

        if (tick.depositedAmount == tick.borrowedAmount) {
            return (
                position.depositedAmount,
                position.depositedAmount,
                position.depositedAmount.mul(
                    TimeValue.getDiscountFactor(position.rate, LOAN_DURATION, TOKEN_DENOMINATOR),
                    TOKEN_DENOMINATOR
                ),
                0
            );
        }

        if (tick.depositedAmount > tick.borrowedAmount) {
            uint256 noneFilledDeposit = position.depositedAmount.div(tick.depositedAmount, TOKEN_DENOMINATOR).mul(
                tick.depositedAmount - tick.borrowedAmount,
                TOKEN_DENOMINATOR
            );
            return (
                position.depositedAmount,
                position.depositedAmount - noneFilledDeposit,
                position.depositedAmount.div(tick.depositedAmount, TOKEN_DENOMINATOR).mul(
                    tick.borrowedAmount.div(
                        TimeValue.getDiscountFactor(position.rate, LOAN_DURATION, TOKEN_DENOMINATOR),
                        TOKEN_DENOMINATOR
                    ),
                    TOKEN_DENOMINATOR
                ),
                position.hasWithdrawPartially ? 0 : noneFilledDeposit
            );
        }
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        return interfaceId == type(ISingleBondIssuance).interfaceId || super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

import './../modules/interfaces/ISBIPool.sol';
import './../modules/interfaces/ISBIGovernance.sol';
import './../modules/interfaces/ISBIBorrowers.sol';
import './../modules/interfaces/ISBILenders.sol';

/**
 * @title ISingleBondIssuance
 * @author Atlendis Labs
 * @notice Interface of the Single Bond Issuance product
 *         The product allows permissionless deposit of tokens at a chosen rate in a pool.
 *         These funds can then be borrowed at the specified rate.
 *         The loan can be repaid by repaying the borrowed amound and the interests.
 *         A lender can withdraw its funds when it has not been borrowed or when repaid.
 *         This product allows for a single loan to be made.
 *         If the loan never happens, a cancellation fee if parametrized, is applied.
 *         The interface is defined as a union of its modules
 */
interface ISingleBondIssuance is ISBIPool, ISBIGovernance, ISBIBorrowers, ISBILenders {

}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

import './../libraries/PoolDataTypes.sol';
import './../libraries/SingleBondIssuanceErrors.sol';
import './../libraries/SingleBondIssuanceLogic.sol';
import './interfaces/ISBIGovernance.sol';
import './SBIPool.sol';
import 'lib/openzeppelin-contracts/contracts/access/Ownable.sol';

/**
 * @title SBIGovernance
 * @author Atlendis Labs
 * @notice Implementation of the ISBIGovernance
 *         Governance module of the SBI product
 */
abstract contract SBIGovernance is ISBIGovernance, SBIPool, Ownable {
    /**
     * @notice Constructor - register creation timestamp and grant the default admin role to the governance address
     * @param governance Address of the governance
     */
    constructor(address governance) {
        _transferOwnership(governance);
    }

    /*//////////////////////////////////////////////////////////////
                        EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function enableIssuancePhase() external onlyOwner onlyInPhase(PoolDataTypes.PoolPhase.BOOK_BUILDING) {
        if (block.timestamp <= CREATION_TIMESTAMP + BOOK_BUILDING_PERIOD_DURATION) {
            revert SingleBondIssuanceErrors.SBI_BOOK_BUILDING_TIME_NOT_OVER();
        }
        poolPhase = PoolDataTypes.PoolPhase.ISSUANCE;
        ISSUANCE_PHASE_START_TIMESTAMP = block.timestamp;
        emit IssuancePhaseEnabled(address(this));
    }

    function markPoolAsDefaulted() external onlyOwner onlyInPhase(PoolDataTypes.PoolPhase.ISSUED) {
        poolPhase = PoolDataTypes.PoolPhase.DEFAULT;
        emit Default(address(this));
    }

    function allowBorrower(address borrower) external onlyOwner {
        permissionedBorrowers[borrower] = true;
    }

    function cancelBondIssuance() external onlyOwner onlyInPhase(PoolDataTypes.PoolPhase.ISSUANCE) {
        if (block.timestamp < ISSUANCE_PHASE_START_TIMESTAMP + ISSUANCE_PERIOD_DURATION) {
            revert SingleBondIssuanceErrors.SBI_ISSUANCE_PERIOD_STILL_ACTIVE();
        }
        uint256 remainingEscrow = cancellationFeeEscrow;
        for (
            uint256 currentInterestRate = MIN_RATE;
            currentInterestRate <= MAX_RATE;
            currentInterestRate += RATE_SPACING
        ) {
            PoolDataTypes.Tick storage tick = ticks[currentInterestRate];
            uint256 cancelFeeForTick = SingleBondIssuanceLogic.repayCancelFeeForTick(
                tick,
                CANCELLATION_FEE_PC,
                remainingEscrow,
                TOKEN_DENOMINATOR
            );
            remainingEscrow -= cancelFeeForTick;
        }
        cancellationFeeEscrow = remainingEscrow;
        poolPhase = PoolDataTypes.PoolPhase.CANCELLED;

        emit BondIssuanceCanceled(address(this), remainingEscrow);
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

import 'lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol';
import './../libraries/PoolDataTypes.sol';
import './../libraries/PositionDataTypes.sol';
import './../libraries/SingleBondIssuanceLogic.sol';
import './interfaces/ISBILenders.sol';
import './SBIPool.sol';

/**
 * @title SBILenders
 * @author Atlendis Labs
 * @notice Implementation of the ISBILenders
 *         Lenders module of the SBI product
 *         Positions are created according to associated ERC721 token
 */
abstract contract SBILenders is ISBILenders, SBIPool, ERC721 {
    /*//////////////////////////////////////////////////////////////
                                STORAGE
    //////////////////////////////////////////////////////////////*/
    mapping(uint256 => PositionDataTypes.PositionDetails) public positions;
    uint256 public nextPositionId;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Constructor - Initialize storage, transit to `book building` phase if no cancellation fee are needed
     * @param name ERC721 name of the positions
     * @param symbol ERC721 symbol of the positions
     */
    constructor(string memory name, string memory symbol) ERC721(name, symbol) {}

    /*//////////////////////////////////////////////////////////////
                        INTERNAL FUNCTIONS LENDER
    //////////////////////////////////////////////////////////////*/

    function validateRate(uint256 newRate) internal view {
        if (newRate < MIN_RATE) {
            revert SingleBondIssuanceErrors.SBI_OUT_OF_BOUND_MIN_RATE();
        }
        if (newRate > MAX_RATE) {
            revert SingleBondIssuanceErrors.SBI_OUT_OF_BOUND_MAX_RATE();
        }
        if ((newRate - MIN_RATE) % RATE_SPACING != 0) {
            revert SingleBondIssuanceErrors.SBI_INVALID_RATE_SPACING();
        }
    }

    /*//////////////////////////////////////////////////////////////
                        EXTERNAL FUNCTIONS LENDER
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Deposit amount of tokens at a chosen rate
     * @param rate Chosen rate at which the funds can be borrowed
     * @param amount Deposited amount of tokens
     * @param to Recipient address for the position associated to the deposit
     * @return positionId ID of the position
     */
    function deposit(
        uint256 rate,
        uint256 amount,
        address to
    ) external returns (uint256 positionId) {
        if (
            poolPhase != PoolDataTypes.PoolPhase.BOOK_BUILDING ||
            block.timestamp > CREATION_TIMESTAMP + BOOK_BUILDING_PERIOD_DURATION
        ) {
            revert SingleBondIssuanceErrors.SBI_ALLOWED_ONLY_BOOK_BUILDING_PHASE();
        }

        if (amount == 0) revert SingleBondIssuanceErrors.SBI_ZERO_AMOUNT();

        validateRate(rate);

        SingleBondIssuanceLogic.depositToTick(ticks[rate], amount, UNDERLYING_TOKEN);
        positionId = nextPositionId++;
        deposits += amount;
        _safeMint(to, positionId);
        positions[positionId] = PositionDataTypes.PositionDetails({
            depositedAmount: amount,
            rate: rate,
            depositBlockNumber: block.number,
            hasWithdrawPartially: false
        });
        emit Deposited(positionId, to, address(this), rate, amount);
    }

    /**
     * @notice Update a position rate
     * @param positionId The ID of the position
     * @param newRate The new rate of the position
     */
    function updateRate(uint256 positionId, uint256 newRate) external {
        if (
            poolPhase != PoolDataTypes.PoolPhase.BOOK_BUILDING ||
            block.timestamp > CREATION_TIMESTAMP + BOOK_BUILDING_PERIOD_DURATION
        ) {
            revert SingleBondIssuanceErrors.SBI_ALLOWED_ONLY_BOOK_BUILDING_PHASE();
        }

        if (ownerOf(positionId) != msg.sender) {
            revert SingleBondIssuanceErrors.SBI_MGMT_ONLY_OWNER();
        }

        validateRate(newRate);

        uint256 oldRate = positions[positionId].rate;

        SingleBondIssuanceLogic.updateTicksDeposit(
            ticks[oldRate],
            ticks[newRate],
            positions[positionId].depositedAmount
        );
        positions[positionId].rate = newRate;
        emit RateUpdated(positionId, msg.sender, address(this), oldRate, newRate);
    }

    function withdraw(uint256 positionId) external {
        if (ownerOf(positionId) != msg.sender) {
            revert SingleBondIssuanceErrors.SBI_MGMT_ONLY_OWNER();
        }

        if (positions[positionId].depositBlockNumber == block.number) {
            revert SingleBondIssuanceErrors.SBI_TIMELOCK();
        }

        if (poolPhase == PoolDataTypes.PoolPhase.ISSUANCE) {
            revert SingleBondIssuanceErrors.SBI_NO_WITHDRAWALS_ISSUANCE_PHASE();
        }

        (uint256 withdrawnAmount, bool partialWithdrawPartialFilledTick) = SingleBondIssuanceLogic.withdrawFromTick(
            ticks[positions[positionId].rate],
            poolPhase,
            positions[positionId].depositedAmount,
            positions[positionId].hasWithdrawPartially,
            TOKEN_DENOMINATOR
        );

        if (poolPhase == PoolDataTypes.PoolPhase.BOOK_BUILDING) {
            deposits -= withdrawnAmount;
        }

        if (partialWithdrawPartialFilledTick) {
            positions[positionId].hasWithdrawPartially = true;
        } else {
            _burn(positionId);
            delete positions[positionId];
        }
        SingleBondIssuanceLogic.transferERC20(msg.sender, UNDERLYING_TOKEN, withdrawnAmount);

        emit Withdrawn(positionId, msg.sender, address(this), withdrawnAmount);
    }

    function withdraw(uint256 positionId, uint256 amount) external {
        if (ownerOf(positionId) != msg.sender) {
            revert SingleBondIssuanceErrors.SBI_MGMT_ONLY_OWNER();
        }

        if (positions[positionId].depositBlockNumber == block.number) {
            revert SingleBondIssuanceErrors.SBI_TIMELOCK();
        }

        if (poolPhase != PoolDataTypes.PoolPhase.BOOK_BUILDING) {
            revert SingleBondIssuanceErrors.SBI_PARTIAL_WITHDRAW_NOT_ALLOWED();
        }

        if (amount > positions[positionId].depositedAmount) {
            revert SingleBondIssuanceErrors.SBI_WITHDRAW_AMOUNT_TOO_LARGE();
        }
        ticks[positions[positionId].rate].depositedAmount -= amount;
        if (positions[positionId].depositedAmount == amount) {
            _burn(positionId);
            delete positions[positionId];
        } else {
            positions[positionId].depositedAmount -= amount;
        }
        deposits -= amount;
        SingleBondIssuanceLogic.transferERC20(msg.sender, UNDERLYING_TOKEN, amount);

        emit PartiallyWithdrawn(positionId, msg.sender, address(this), amount);
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

/**
 * @title ISBIGovernance
 * @author Atlendis Labs
 * @notice Interface of the Single Bond Issuance Governance module contract
 *         It is in charge of the governance part of the contract
 *         In details:
 *           - manage borrowers,
 *           - enable issuance phase,
 *           - able to cancel bond issuance or default.
 *          Extended by the SingleBondIssuance product contract
 */
interface ISBIGovernance {
    /**
     * @notice Emitted when the issuance phase has started
     * @param contractAddress Address of the contract
     */
    event IssuancePhaseEnabled(address contractAddress);

    /**
     * @notice Cancel the bond issuance and consume the escrow in fees
     * @param contractAddress Address of the contract
     * @param remainingEscrow Remaining amount in escrow after fees distribution
     */
    event BondIssuanceCanceled(address contractAddress, uint256 remainingEscrow);

    /**
     * @notice Emitted when the ç
     * @param contractAddress Address of the contractpool has been marked as default
     */
    event Default(address contractAddress);

    /**
     * @notice Enable the issuance phase
     *
     * Emits a {IssuancePhaseEnabled} event
     */
    function enableIssuancePhase() external;

    /**
     * @notice Cancel the bond issuance
     *
     * Emits a {BondIssuanceCanceled} event
     */
    function cancelBondIssuance() external;

    /**
     * @notice Set the pool as defaulted
     *
     * Emits a {Default} event
     */
    function markPoolAsDefaulted() external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

/**
 * @title ISBILenders
 * @author Atlendis Labs
 * @notice Interface of the Single Bond Issuance Lenders module contract
 *         It exposes the available methods for the lenders
 */
interface ISBILenders {
    /**
     * @notice Emitted when a deposit has been made
     * @param positionId ID of the position associated to the deposit
     * @param owner Address of the position owner
     * @param contractAddress Address of the contract
     * @param rate Chosen rate at which the funds can be borrowed
     * @param amount Deposited amount
     */
    event Deposited(
        uint256 indexed positionId,
        address indexed owner,
        address contractAddress,
        uint256 rate,
        uint256 amount
    );

    /**
     * @notice Emitted when a rate has been updated
     * @param positionId ID of the position
     * @param owner Address of the position owner
     * @param contractAddress Address of the contract
     * @param oldRate Previous rate
     * @param newRate Updated rate
     */
    event RateUpdated(
        uint256 indexed positionId,
        address indexed owner,
        address contractAddress,
        uint256 oldRate,
        uint256 newRate
    );

    /**
     * @notice Emitted when a withdraw has been made
     * @param positionId ID of the position
     * @param owner Address of the position owner
     * @param contractAddress Address of the contract
     * @param amount Withdrawn amount
     */
    event Withdrawn(uint256 indexed positionId, address indexed owner, address contractAddress, uint256 amount);

    /**
     * @notice Emitted when a partial withdraw has been made
     * @param positionId ID of the position
     * @param owner Address of the position owner
     * @param contractAddress Address of the contract
     * @param amount Withdrawn amount
     */
    event PartiallyWithdrawn(
        uint256 indexed positionId,
        address indexed owner,
        address contractAddress,
        uint256 amount
    );

    /**
     * @notice Deposit amount of tokens at a chosen rate
     * @param rate Chosen rate at which the funds can be borrowed
     * @param amount Deposited amount of tokens
     * @param to Recipient address for the position associated to the deposit
     * @return positionId ID of the position
     *
     * Emits a {Deposited} event
     */
    function deposit(
        uint256 rate,
        uint256 amount,
        address to
    ) external returns (uint256 positionId);

    /**
     * @notice Update a position rate
     * @param positionId The ID of the position
     * @param newRate The new rate of the position
     *
     * Emits a {RateUpdated} event
     */
    function updateRate(uint256 positionId, uint256 newRate) external;

    /**
     * @notice Withdraw the maximum amount from a position
     * @param positionId ID of the position
     *
     * Emits a {Withdrawn} event
     */
    function withdraw(uint256 positionId) external;

    /**
     * @notice Withdraw any amount up to the full position deposited amount
     * @param positionId ID of the position
     * @param amount Amount to withdraw
     *
     * Emits a {PartiallyWithdrawn} event
     */
    function withdraw(uint256 positionId, uint256 amount) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

import './../libraries/DataTypes.sol';
import './../libraries/Errors.sol';
import './interfaces/IRCLOrderBook.sol';
import 'lib/openzeppelin-contracts/contracts/access/Ownable.sol';
import 'lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol';

/**
 * @title OrderBook
 * @author Atlendis Labs
 * @notice Implementation of the IOrderBook
 *         Contains the core storage of the pool and shared methods accross the modules
 */
abstract contract RCLOrderBook is IRCLOrderBook, Ownable {
    /*//////////////////////////////////////////////////////////////
                                STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => DataTypes.Tick) public ticks;
    mapping(address => bool) public permissionedBorrowers;
    mapping(uint256 => uint256) public loanRepayTimeDeltas;
    uint256 immutable TOKEN_DENOMINATOR;
    uint256 immutable ONE;
    uint256 public currentLoanId;
    uint256 public totalBorrowed;
    uint256 public currentMaturity;
    uint256 public atlendisRevenue;
    uint256 immutable MAX_BORROWABLE_AMOUNT;
    address immutable UNDERLYING_TOKEN;
    uint256 immutable MIN_RATE;
    uint256 immutable MAX_RATE;
    uint256 immutable RATE_SPACING;
    uint256 immutable REPAYMENT_PERIOD;
    bool immutable IS_CALLABLE;
    uint256 immutable ISSUANCE_FEE_RATE;
    uint256 immutable REPAYMENT_FEE_RATE;
    uint256 immutable LATE_REPAYMENT_FEE_RATE;
    uint256 immutable LOAN_DURATION; // in seconds
    DataTypes.OrderBookPhase public orderBookPhase;

    /*//////////////////////////////////////////////////////////////
                                CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Constructor - Initialize parametrization
     */
    constructor(bytes memory feeConfig, bytes memory parametersConfig) {
        orderBookPhase = DataTypes.OrderBookPhase.OPEN;

        (ISSUANCE_FEE_RATE, REPAYMENT_FEE_RATE, LATE_REPAYMENT_FEE_RATE) = abi.decode(
            feeConfig,
            (uint256, uint256, uint256)
        );
        (
            MAX_BORROWABLE_AMOUNT,
            UNDERLYING_TOKEN,
            MIN_RATE,
            MAX_RATE,
            RATE_SPACING,
            REPAYMENT_PERIOD,
            IS_CALLABLE,
            LOAN_DURATION
        ) = abi.decode(parametersConfig, (uint256, address, uint256, uint256, uint256, uint256, bool, uint256));

        TOKEN_DENOMINATOR = 10**ERC20(UNDERLYING_TOKEN).decimals();
        ONE = TOKEN_DENOMINATOR;

        uint256 currentInterestRate = MIN_RATE;
        while (currentInterestRate <= MAX_RATE) {
            ticks[currentInterestRate].yieldFactor = ONE;
            /// @dev the first loan gets an ID of one.
            /// Hence the endOfPriorLoanYieldFactor for genesis deposits is never set but is theoertically ONE
            ticks[currentInterestRate].endOfLoanYieldFactors[0] = ONE;
            currentInterestRate += RATE_SPACING;
        }
    }

    /*//////////////////////////////////////////////////////////////
                                GETTERS
    //////////////////////////////////////////////////////////////*/

    function getEpoch(uint256 rate, uint256 epochId)
        public
        view
        returns (
            uint256 deposited,
            uint256 borrowed,
            uint256 endOfLoanAccruedYield,
            uint256 loanId,
            bool isBaseEpoch
        )
    {
        DataTypes.Tick storage tick = ticks[rate];
        borrowed = tick.epochs[epochId].borrowed;
        endOfLoanAccruedYield = tick.epochs[epochId].endOfLoanAccruedYield;
        deposited = tick.epochs[epochId].deposited;
        loanId = tick.epochs[epochId].loanId;
        isBaseEpoch = tick.epochs[epochId].isBaseEpoch;
    }

    function getNewEpochsAmounts(uint256 rate)
        public
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        DataTypes.Tick storage tick = ticks[rate];

        return (
            tick.newEpochsAmounts.borrowedLoanNewEpochs,
            tick.newEpochsAmounts.availableToBorrowNew,
            tick.newEpochsAmounts.toExitNewEpochsYield,
            tick.newEpochsAmounts.toExitNewEpochs
        );
    }

    function getTickAmounts(uint256 rate)
        public
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        DataTypes.Tick storage tick = ticks[rate];

        return (
            tick.adjustedDeposits,
            tick.toBeAdjusted,
            tick.borrowedLoanBaseEpoch,
            tick.availableToBorrowBase,
            tick.amountToPayBack
        );
    }

    function getTickRemaining(uint256 rate)
        public
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        // copy the data into memory
        DataTypes.Tick storage tick = ticks[rate];

        return (tick.yieldFactor, tick.loanStartEpochId, tick.currentEpochId, tick.lastBorrowTimeStamp);
    }

    /*//////////////////////////////////////////////////////////////
                                MODIFIERS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Allow only if the pool phase is the expected one
     * @param expectedPhase Expected phase
     */
    modifier onlyInPhase(DataTypes.OrderBookPhase expectedPhase) {
        if (orderBookPhase != expectedPhase)
            revert RevolvingCreditLineErrors.RCL_INVALID_PHASE(expectedPhase, orderBookPhase);
        _;
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

/**
 * @title DataTypes library
 * @dev Defines the structs and enums used by the resolving credit line
 */
library DataTypes {
    struct NewEpochsAmounts {
        uint256 borrowedLoanNewEpochs;
        uint256 toExitNewEpochs;
        uint256 toExitNewEpochsYield;
        uint256 availableToBorrowNew;
    }

    struct Tick {
        uint256 yieldFactor;
        uint256 adjustedDeposits;
        uint256 toBeAdjusted;
        uint256 borrowedLoanBaseEpoch;
        uint256 availableToBorrowBase;
        uint256 loanStartEpochId;
        uint256 currentEpochId;
        uint256 lastBorrowTimeStamp;
        uint256 amountToPayBack;
        uint256 toExitBaseAdjusted;
        NewEpochsAmounts newEpochsAmounts;
        mapping(uint256 => Epoch) epochs;
        mapping(uint256 => uint256) endOfLoanYieldFactors;
    }
    struct Epoch {
        uint256 borrowed;
        uint256 deposited;
        uint256 endOfLoanAccruedYield;
        uint256 loanId;
        bool isBaseEpoch;
        uint256 toExit;
    }

    enum OrderBookPhase {
        INACTIVE,
        OPEN,
        CLOSED,
        PARTIAL_DEFAULT,
        DEFAULT
    }

    struct Position {
        uint256 baseDeposit;
        uint256 rate;
        uint256 epochId;
        uint256 creationTimestamp;
        uint256 exitLoanId;
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

import './DataTypes.sol';

/**
 * @title Errors library
 * @dev Defines the errors used in the Resolving credit line product
 */
library RevolvingCreditLineErrors {
    error RCL_OUT_OF_BOUND_MIN_RATE(); // "Input rate is below min rate"
    error RCL_OUT_OF_BOUND_MAX_RATE(); // "Input rate is above max rate"
    error RCL_INVALID_RATE_SPACING(); // "Input rate is invalid with respect to rate spacing"

    error RCL_INVALID_PHASE(DataTypes.OrderBookPhase expectedPhase, DataTypes.OrderBookPhase actualPhase); // "Phase is invalid for this operation"
    error RCL_ZERO_AMOUNT(); // "Cannot deposit zero amount"
    error RCL_ZERO_AMOUNT_NOT_ALLOWED(); // "Zero amount not allowed"
    error RCL_NO_LIQUIDITY(); // "No liquidity available for the amount of bonds to sell"
    error RCL_LOAN_RUNNING(); // "Loan has not reached maturity"
    error RCL_AMOUNT_EXCEEDS_MAX(); // "Amount exceeds maximum allowed"
    error RCL_FURTHER_BORROW_DISABLED(); // OrderBook does not allow further borrows
    error RCL_NO_LOAN_RUNNING(); // No loan currently running
    error RCL_ONLY_OWNER(); // Has to be position owner
    error RCL_TIMELOCK(); // ActionNot possible within this block
    error RCL_CANNOT_EXIT(); // Cannot signal exit during first loan cycle
    error RCL_POSITION_NOT_BORROWED(); // The positions is currently not under a borrow
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

/**
 * @title IOrderBook
 * @author Atlendis Labs
 */
interface IRCLOrderBook {

}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

import 'lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol';
import './interfaces/IRevolvingCreditLine.sol';
import './modules/RCLGovernance.sol';
import './modules/RCLOrderBook.sol';
import './modules/RCLLenders.sol';
import './modules/RCLBorrowers.sol';
import './libraries/DataTypes.sol';

/**
 * @title RevolvingCreditLines
 * @author Atlendis Labs
 * @notice Implementation of the IRevolvingCreditLines
 */
contract RevolvingCreditLine is IRevolvingCreditLine, RCLOrderBook, RCLGovernance, RCLBorrowers, RCLLenders {
    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Constructor - pass parameters to modules
     * @param governance Address of the governance
     * @param feeConfig Fee parameters
     * @param parametersConfig Othern parmaeters
     * @param name ERC721 name of the positions
     * @param symbol ERC721 symbol of the positions
     */
    constructor(
        address governance,
        bytes memory feeConfig,
        bytes memory parametersConfig,
        string memory name,
        string memory symbol
    ) RCLLenders(name, symbol) RCLGovernance(governance) RCLOrderBook(feeConfig, parametersConfig) {}
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

import './../modules/interfaces/IRCLOrderBook.sol';
import './../modules/interfaces/IRCLGovernance.sol';
import './../modules/interfaces/IRCLBorrowers.sol';
import './../modules/interfaces/IRCLLenders.sol';

/**
 * @title IRevolvingCreditLine
 * @author Atlendis Labs
 */
interface IRevolvingCreditLine {

}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

import './interfaces/IRCLGovernance.sol';
import './RCLOrderBook.sol';

/**
 * @title Governance
 * @author Atlendis Labs
 * @notice Implementation of the IRCLGovernance
 *         Governance module of the RCL product
 */
abstract contract RCLGovernance is IRCLGovernance, RCLOrderBook {
    /**
     * @notice Constructor - register creation timestamp and grant the owner rights to the governance address
     * @param governance Address of the governance
     */
    constructor(address governance) {
        _transferOwnership(governance);
    }

    /*//////////////////////////////////////////////////////////////
                        EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function allowBorrower(address borrower) external onlyOwner {
        permissionedBorrowers[borrower] = true;
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

import 'lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol';
import 'lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol';
import '../../../libraries/FixedPointMathLib.sol';

import '../libraries/DataTypes.sol';
import '../libraries/Errors.sol';
import './interfaces/IRCLLenders.sol';
import './RCLOrderBook.sol';

/**
 * @title Lenders
 * @author Atlendis Labs
 * @notice Implementation of the IRCLenders
 *         Lenders module of the RCL product
 *         Positions are created according to associated ERC721 token
 */
abstract contract RCLLenders is IRCLLenders, RCLOrderBook, ERC721 {
    /*//////////////////////////////////////////////////////////////
                                Events
    //////////////////////////////////////////////////////////////*/

    event Withdraw(uint256 indexed positionId, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                                LIBRARIES
    //////////////////////////////////////////////////////////////*/

    using FixedPointMathLib for uint256;

    using SafeERC20 for ERC20;

    /*//////////////////////////////////////////////////////////////
                                STORAGE
    //////////////////////////////////////////////////////////////*/
    mapping(uint256 => DataTypes.Position) public positions;
    uint256 public currentPositionId;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(string memory name, string memory symbol) ERC721(name, symbol) {}

    /*//////////////////////////////////////////////////////////////
                        INTERNAL FUNCTIONS LENDER
    //////////////////////////////////////////////////////////////*/

    function validateRate(uint256 newRate) internal view {
        if (newRate < MIN_RATE) {
            revert RevolvingCreditLineErrors.RCL_OUT_OF_BOUND_MIN_RATE();
        }
        if (newRate > MAX_RATE) {
            revert RevolvingCreditLineErrors.RCL_OUT_OF_BOUND_MAX_RATE();
        }
        if ((newRate - MIN_RATE) % RATE_SPACING != 0) {
            revert RevolvingCreditLineErrors.RCL_INVALID_RATE_SPACING();
        }
    }

    /*//////////////////////////////////////////////////////////////
                            EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function deposit(
        uint256 rate,
        uint256 amount,
        address to
    ) external onlyInPhase(DataTypes.OrderBookPhase.OPEN) returns (uint256 positionId) {
        if (amount == 0) revert RevolvingCreditLineErrors.RCL_ZERO_AMOUNT();

        validateRate(rate);
        DataTypes.Tick storage tick = ticks[rate];
        if (tick.borrowedLoanBaseEpoch > 0) {
            tick.toBeAdjusted += amount;
            tick.newEpochsAmounts.availableToBorrowNew += amount;
            tick.epochs[ticks[rate].currentEpochId].deposited += amount;
        } else {
            tick.availableToBorrowBase += amount;
            tick.adjustedDeposits += amount.div(tick.yieldFactor, TOKEN_DENOMINATOR);
        }
        positions[currentPositionId] = DataTypes.Position({
            baseDeposit: amount,
            rate: rate,
            epochId: ticks[rate].currentEpochId,
            creationTimestamp: block.timestamp,
            exitLoanId: 0
        });
        _safeMint(to, currentPositionId++);
        ERC20(UNDERLYING_TOKEN).safeTransferFrom(msg.sender, address(this), amount);
        positionId = currentPositionId - 1;
    }

    function withdraw(uint256 positionId) external onlyInPhase(DataTypes.OrderBookPhase.OPEN) {
        if (ownerOf(positionId) != _msgSender()) {
            revert RevolvingCreditLineErrors.RCL_ONLY_OWNER();
        }
        DataTypes.Position storage position = positions[positionId];
        if (position.creationTimestamp == block.timestamp) {
            revert RevolvingCreditLineErrors.RCL_TIMELOCK();
        }

        DataTypes.Tick storage tick = ticks[position.rate];
        uint256 withdrawableAmount;
        if (tick.currentEpochId == position.epochId) {
            withdrawableAmount = position.baseDeposit;
            if (tick.borrowedLoanBaseEpoch > 0) {
                tick.toBeAdjusted -= withdrawableAmount;
                tick.newEpochsAmounts.availableToBorrowNew -= withdrawableAmount;
                tick.epochs[ticks[position.rate].currentEpochId].deposited -= withdrawableAmount;
            } else {
                tick.availableToBorrowBase -= withdrawableAmount;
                tick.adjustedDeposits -= withdrawableAmount.div(tick.yieldFactor, TOKEN_DENOMINATOR);
            }
        } else {
            if (tick.borrowedLoanBaseEpoch > 0) {
                revert RevolvingCreditLineErrors.RCL_LOAN_RUNNING();
            }

            DataTypes.Epoch storage epoch = ticks[position.rate].epochs[position.epochId];
            withdrawableAmount = computePositionValue(epoch, tick, position);
            tick.availableToBorrowBase -= withdrawableAmount;
            tick.adjustedDeposits -= withdrawableAmount.div(tick.yieldFactor, TOKEN_DENOMINATOR);
        }

        _burn(positionId);
        delete positions[positionId];

        ERC20(UNDERLYING_TOKEN).safeTransfer(_msgSender(), withdrawableAmount);
        emit Withdraw(positionId, withdrawableAmount);
    }

    function signalExit(uint256 positionId) external onlyInPhase(DataTypes.OrderBookPhase.OPEN) {
        if (ownerOf(positionId) != _msgSender()) {
            revert RevolvingCreditLineErrors.RCL_ONLY_OWNER();
        }
        if (currentMaturity == 0) {
            revert RevolvingCreditLineErrors.RCL_NO_LOAN_RUNNING();
        }
        DataTypes.Position storage position = positions[positionId];
        DataTypes.Tick storage tick = ticks[position.rate];
        if (tick.borrowedLoanBaseEpoch == 0) {
            revert RevolvingCreditLineErrors.RCL_NO_LOAN_RUNNING();
        }

        DataTypes.Epoch storage epoch = ticks[position.rate].epochs[position.epochId];
        if (epoch.borrowed == 0 && !epoch.isBaseEpoch) {
            revert RevolvingCreditLineErrors.RCL_POSITION_NOT_BORROWED();
        }
        if (position.epochId <= tick.loanStartEpochId) {
            tick.toExitBaseAdjusted += position.baseDeposit.div(
                getEquivalentRatio(epoch, tick, position.rate),
                TOKEN_DENOMINATOR
            );
        } else {
            tick.newEpochsAmounts.toExitNewEpochs += position.baseDeposit;
            epoch.toExit += position.baseDeposit;
            tick.newEpochsAmounts.toExitNewEpochsYield += position
                .baseDeposit
                .div(epoch.deposited, TOKEN_DENOMINATOR)
                .mul(epoch.endOfLoanAccruedYield, TOKEN_DENOMINATOR);
        }
        position.exitLoanId = currentLoanId;
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function computePositionValue(
        DataTypes.Epoch storage epoch,
        DataTypes.Tick storage tick,
        DataTypes.Position storage position
    ) internal returns (uint256 positionValue) {
        positionValue = position.baseDeposit.mul(tick.yieldFactor, TOKEN_DENOMINATOR).div(
            getEquivalentRatio(epoch, tick, position.rate),
            TOKEN_DENOMINATOR
        );
    }

    function getEquivalentRatio(
        DataTypes.Epoch storage epoch,
        DataTypes.Tick storage tick,
        uint256 rate
    ) internal returns (uint256 equivalentRatio) {
        if (epoch.isBaseEpoch) {
            equivalentRatio = tick.endOfLoanYieldFactors[epoch.loanId - 1];
        } else {
            uint256 deltaToMaturityAccruals = epoch
                .borrowed
                .mul(loanRepayTimeDeltas[epoch.loanId], TOKEN_DENOMINATOR)
                .mul(rate, TOKEN_DENOMINATOR);
            equivalentRatio = tick.endOfLoanYieldFactors[epoch.loanId].mul(epoch.deposited, TOKEN_DENOMINATOR).div(
                epoch.endOfLoanAccruedYield + epoch.deposited + deltaToMaturityAccruals,
                TOKEN_DENOMINATOR
            );
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

import '../../../libraries/TimeValue.sol';
import '../libraries/BorrowingLogic.sol';
import './interfaces/IRCLBorrowers.sol';
import './RCLOrderBook.sol';
import 'lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol';
import '../../../libraries/FixedPointMathLib.sol';

/**
 * @title Borrowers
 * @author Atlendis Labs
 * @notice Implementation of IBorrowers
 */
abstract contract RCLBorrowers is IRCLBorrowers, RCLOrderBook {
    /*//////////////////////////////////////////////////////////////
                                LIBRARIES
    //////////////////////////////////////////////////////////////*/

    using SafeERC20 for ERC20;
    using FixedPointMathLib for uint256;

    /*//////////////////////////////////////////////////////////////
                                MODIFIERS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Restrict the sender of the message to the borrowe, i.e. default admin
     */
    modifier onlyBorrower() {
        require(permissionedBorrowers[msg.sender], 'Only permissioned borrower allowed');
        _;
    }

    /*//////////////////////////////////////////////////////////////
                        EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function borrow(address to, uint256 amount) external onlyBorrower onlyInPhase(DataTypes.OrderBookPhase.OPEN) {
        if (amount + totalBorrowed > MAX_BORROWABLE_AMOUNT) {
            revert RevolvingCreditLineErrors.RCL_AMOUNT_EXCEEDS_MAX();
        }
        if (amount == 0) {
            revert RevolvingCreditLineErrors.RCL_ZERO_AMOUNT_NOT_ALLOWED();
        }

        uint256 issuanceFee = amendGlobalsOnBorrow(amount);

        uint256 currentInterestRate = MIN_RATE;
        uint256 remainingAmount = amount;
        while (remainingAmount > 0 && currentInterestRate <= MAX_RATE) {
            DataTypes.Tick storage tick = ticks[currentInterestRate];
            DataTypes.Epoch storage currentEpoch = tick.epochs[tick.currentEpochId];

            if (tick.availableToBorrowBase + tick.newEpochsAmounts.availableToBorrowNew > 0) {
                if (tick.borrowedLoanBaseEpoch > 0) {
                    accrueYieldFactor(tick, currentInterestRate);
                    incrementPaybackWithInterestDue(tick, currentInterestRate);
                    adjustForNewEpochsYield(tick, currentInterestRate);
                }

                bool firstLoanBorrow;
                if (tick.availableToBorrowBase > 0) {
                    DataTypes.Epoch storage epoch;
                    if (tick.borrowedLoanBaseEpoch > 0) {
                        epoch = tick.epochs[tick.currentEpochId - 1];
                    } else {
                        epoch = tick.epochs[tick.currentEpochId];
                        firstLoanBorrow = true;
                    }
                    remainingAmount = BorrowingLogic.borrowFromBase({
                        tick: tick,
                        epoch: epoch,
                        toBeBorrowed: remainingAmount,
                        currentLoanId: currentLoanId
                    });
                } else {
                    DataTypes.Epoch storage lastEpoch = tick.epochs[tick.currentEpochId - 1];
                    if (
                        !lastEpoch.isBaseEpoch && lastEpoch.deposited - lastEpoch.borrowed > 0 && lastEpoch.borrowed > 0
                    ) {
                        remainingAmount = BorrowingLogic.borrowFromNew({
                            tick: tick,
                            epoch: lastEpoch,
                            toBeBorrowed: remainingAmount,
                            rate: currentInterestRate,
                            currentLoanId: currentLoanId,
                            tokenDenominator: TOKEN_DENOMINATOR,
                            currentMaturity: currentMaturity
                        });
                    }
                }

                if (remainingAmount > 0 && !firstLoanBorrow) {
                    remainingAmount = BorrowingLogic.borrowFromNew({
                        tick: tick,
                        epoch: currentEpoch,
                        toBeBorrowed: remainingAmount,
                        rate: currentInterestRate,
                        currentLoanId: currentLoanId,
                        tokenDenominator: TOKEN_DENOMINATOR,
                        currentMaturity: currentMaturity
                    });
                }
                tick.lastBorrowTimeStamp = block.timestamp;
            }
            currentInterestRate += RATE_SPACING;
        }
        if (remainingAmount > 0) {
            revert RevolvingCreditLineErrors.RCL_NO_LIQUIDITY();
        }
        ERC20(UNDERLYING_TOKEN).safeTransfer(to, amount - issuanceFee);
    }

    function repay() external onlyBorrower onlyInPhase(DataTypes.OrderBookPhase.OPEN) {
        if (currentMaturity == 0) {
            revert RevolvingCreditLineErrors.RCL_NO_LOAN_RUNNING();
        }
        if (block.timestamp < currentMaturity) {
            revert RevolvingCreditLineErrors.RCL_LOAN_RUNNING();
        }

        uint256 amountToPayBack;
        uint256 currentInterestRate = MIN_RATE;
        while (currentInterestRate <= MAX_RATE) {
            DataTypes.Tick storage tick = ticks[currentInterestRate];
            if (tick.borrowedLoanBaseEpoch > 0) {
                DataTypes.Epoch storage lastBorrowedEpoch = tick.epochs[tick.currentEpochId - 1];

                if (lastBorrowedEpoch.deposited > lastBorrowedEpoch.borrowed) {
                    tick.newEpochsAmounts.toExitNewEpochsYield += lastBorrowedEpoch
                        .toExit
                        .div(lastBorrowedEpoch.deposited, TOKEN_DENOMINATOR)
                        .mul(lastBorrowedEpoch.endOfLoanAccruedYield, TOKEN_DENOMINATOR);
                }
                incrementPaybackWithInterestDue(tick, currentInterestRate);
                accrueYieldFactor(tick, currentInterestRate);
                adjustForNewEpochsYield(tick, currentInterestRate);
                adjustForExits(tick, currentInterestRate);
                amountToPayBack += tick.amountToPayBack;
                BorrowingLogic.prepareTickForNextLoan(tick, TOKEN_DENOMINATOR, currentLoanId);
            }
            currentInterestRate += RATE_SPACING;
        }
        amendGlobalsOnRepay();
        ERC20(UNDERLYING_TOKEN).safeTransferFrom(msg.sender, address(this), amountToPayBack);
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function accrueYieldFactor(DataTypes.Tick storage tick, uint256 rate) internal {
        tick.yieldFactor += tick
            .borrowedLoanBaseEpoch
            .mul(block.timestamp - tick.lastBorrowTimeStamp, TOKEN_DENOMINATOR)
            .mul(rate, TOKEN_DENOMINATOR)
            .div(tick.adjustedDeposits, TOKEN_DENOMINATOR);
    }

    function incrementPaybackWithInterestDue(DataTypes.Tick storage tick, uint256 rate) internal {
        tick.amountToPayBack += (tick.borrowedLoanBaseEpoch + tick.newEpochsAmounts.borrowedLoanNewEpochs)
            .mul(block.timestamp - tick.lastBorrowTimeStamp, TOKEN_DENOMINATOR)
            .mul(rate, TOKEN_DENOMINATOR);
    }

    function amendGlobalsOnRepay() internal {
        loanRepayTimeDeltas[currentLoanId] = block.timestamp - currentMaturity;
        currentMaturity = 0;
        totalBorrowed = 0;
    }

    function adjustForNewEpochsYield(DataTypes.Tick storage tick, uint256 rate) internal {
        tick.toBeAdjusted =
            tick.toBeAdjusted +
            tick
                .newEpochsAmounts
                .borrowedLoanNewEpochs
                .mul(block.timestamp - tick.lastBorrowTimeStamp, TOKEN_DENOMINATOR)
                .mul(rate, TOKEN_DENOMINATOR);
    }

    function adjustForExits(DataTypes.Tick storage tick, uint256 rate) internal {
        uint256 toExitAdjustment;

        uint256 deltaToMaturityAdjustment = tick
            .epochs[tick.currentEpochId - 1]
            .borrowed
            .mul(block.timestamp - currentMaturity, TOKEN_DENOMINATOR)
            .mul(rate, TOKEN_DENOMINATOR);

        toExitAdjustment =
            tick.newEpochsAmounts.toExitNewEpochsYield +
            deltaToMaturityAdjustment +
            tick.newEpochsAmounts.toExitNewEpochs;

        tick.toBeAdjusted -= toExitAdjustment;
    }

    function amendGlobalsOnBorrow(uint256 amount) internal returns (uint256 issuanceFee) {
        if (currentMaturity == 0) {
            currentMaturity = block.timestamp + LOAN_DURATION;
            currentLoanId += 1;
        }
        totalBorrowed += amount;
        issuanceFee = ISSUANCE_FEE_RATE.mul(amount, TOKEN_DENOMINATOR);
        atlendisRevenue += issuanceFee;
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

/**
 * @title IGovernance
 * @author Atlendis Labs
 */
interface IRCLGovernance {

}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

/**
 * @title IBorrowers
 * @author Atlendis Labs
 */
interface IRCLBorrowers {

}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

/**
 * @title ILenders
 * @author Atlendis Labs
 */
interface IRCLLenders {

}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

import './DataTypes.sol';
import '../../../libraries/FixedPointMathLib.sol';

library BorrowingLogic {
    using FixedPointMathLib for uint256;

    function borrowFromBase(
        DataTypes.Tick storage tick,
        DataTypes.Epoch storage epoch,
        uint256 toBeBorrowed,
        uint256 currentLoanId
    ) external returns (uint256) {
        if (tick.borrowedLoanBaseEpoch == 0) {
            epoch.isBaseEpoch = true;
            tick.loanStartEpochId = tick.currentEpochId;
            epoch.loanId = currentLoanId;
            tick.currentEpochId += 1;
        }
        uint256 amountToBorrow;
        if (toBeBorrowed >= tick.availableToBorrowBase) {
            amountToBorrow = tick.availableToBorrowBase;
        } else {
            amountToBorrow = toBeBorrowed;
        }
        tick.borrowedLoanBaseEpoch += amountToBorrow;
        tick.availableToBorrowBase -= amountToBorrow;
        toBeBorrowed -= amountToBorrow;
        return toBeBorrowed;
    }

    function borrowFromNew(
        DataTypes.Tick storage tick,
        DataTypes.Epoch storage epoch,
        uint256 toBeBorrowed,
        uint256 rate,
        uint256 currentLoanId,
        uint256 tokenDenominator,
        uint256 currentMaturity
    ) external returns (uint256) {
        if (epoch.borrowed == 0) {
            epoch.loanId = currentLoanId;
            tick.currentEpochId += 1;
        }
        uint256 amountToBorrow;
        if (toBeBorrowed >= epoch.deposited - epoch.borrowed) {
            amountToBorrow = epoch.deposited - epoch.borrowed;
        } else {
            amountToBorrow = toBeBorrowed;
        }

        epoch.borrowed += amountToBorrow;
        tick.newEpochsAmounts.borrowedLoanNewEpochs += amountToBorrow;
        epoch.endOfLoanAccruedYield += amountToBorrow.mul(currentMaturity - block.timestamp, tokenDenominator).mul(
            rate,
            tokenDenominator
        );

        tick.newEpochsAmounts.availableToBorrowNew -= amountToBorrow;
        toBeBorrowed -= amountToBorrow;

        // compute yield that exits once new epoch is filled
        if (toBeBorrowed == 0) {
            tick.newEpochsAmounts.toExitNewEpochsYield += epoch.toExit.div(epoch.deposited, tokenDenominator).mul(
                epoch.endOfLoanAccruedYield,
                tokenDenominator
            );
        }
        return toBeBorrowed;
    }

    function prepareTickForNextLoan(
        DataTypes.Tick storage tick,
        uint256 tokenDenominator,
        uint256 currentLoanId
    ) external {
        tick.availableToBorrowBase +=
            tick.amountToPayBack +
            tick.borrowedLoanBaseEpoch +
            tick.newEpochsAmounts.availableToBorrowNew -
            tick.newEpochsAmounts.toExitNewEpochs -
            tick.newEpochsAmounts.toExitNewEpochsYield +
            tick.newEpochsAmounts.borrowedLoanNewEpochs -
            tick.toExitBaseAdjusted.mul(tick.yieldFactor, tokenDenominator);

        delete tick.newEpochsAmounts;
        tick.borrowedLoanBaseEpoch = 0;
        tick.amountToPayBack = 0;
        tick.adjustedDeposits =
            tick.adjustedDeposits +
            tick.toBeAdjusted.div(tick.yieldFactor, tokenDenominator) -
            tick.toExitBaseAdjusted;
        tick.toBeAdjusted = 0;
        tick.toExitBaseAdjusted = 0;
        tick.endOfLoanYieldFactors[currentLoanId] = tick.yieldFactor;
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

import 'lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol';
import 'lib/openzeppelin-contracts/contracts/utils/introspection/ERC165.sol';

import '../../interfaces/IProductFactory.sol';
import './RevolvingCreditLine.sol';

/**
 * @title Factory
 * @author Atlendis Labs
 * @notice Implementation of the IProductFactory for the Revolving Credit Line product
 */
contract RCLFactory is IProductFactory, ERC165 {
    /*//////////////////////////////////////////////////////////////
                                STORAGE
    //////////////////////////////////////////////////////////////*/

    address public immutable FACTORY_REGISTRY;
    bytes32 public constant PRUDUCT_ID = keccak256('RCL');

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address factoryRegistry) {
        FACTORY_REGISTRY = factoryRegistry;
    }

    /*//////////////////////////////////////////////////////////////
                        EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function deploy(
        address governance,
        bytes memory feeConfig,
        bytes memory parametersConfig,
        string memory name,
        string memory symbol
    ) external returns (address instance) {
        if (msg.sender != FACTORY_REGISTRY) revert UNAUTHORIZED();
        if (feeConfig.length != 96) revert INVALID_PRODUCT_PARAMS();
        if (parametersConfig.length != 256) revert INVALID_PRODUCT_PARAMS();

        instance = address(new RevolvingCreditLine(governance, feeConfig, parametersConfig, name, symbol));
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

/**
 * @title IProductFactory
 * @author Atlendis Labs
 * @notice Interface of the factory contract in charge of deploying instance of one dedicated product
 *         One Product Factory is deployed per product
 *         Used by the Factory Router contract in order to deploy instances of any products
 */
interface IProductFactory {
    /**
     * @notice Thrown when constructor data is invalid
     */
    error INVALID_PRODUCT_PARAMS();

    /**
     * @notice Thrown when sender is not authorized
     */
    error UNAUTHORIZED();

    /**
     * @notice Deploy an instance of the product
     * @param governance Address of the governance of the product instance
     * @param feeConfigs Configurations specific to fees, encoded as bytes
     * @param parametersConfig Configurations specific to all other params, encoded as bytes
     * @param name Name of the ERC721 token associated to the product instance
     * @param symbol Symbol of the ERC721 token associated to the product instance
     * @return instance The address of the deployed product instance
     *
     * Emits a {InstanceDeployed} event
     */
    function deploy(
        address governance,
        bytes memory feeConfigs,
        bytes memory parametersConfig,
        string memory name,
        string memory symbol
    ) external returns (address instance);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

import '../../interfaces/IProductFactory.sol';
import './SingleBondIssuance.sol';

/**
 * @title SBIFactory
 * @author Atlendis Labs
 * @notice Implementation of the IProductFactory for the Single Bond Issuance product
 */
contract SBIFactory is IProductFactory {
    /*//////////////////////////////////////////////////////////////
                                STORAGE
    //////////////////////////////////////////////////////////////*/

    address public immutable FACTORY_REGISTRY;
    bytes32 public constant PRUDUCT_ID = keccak256('SBI');

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address factoryRegistry) {
        FACTORY_REGISTRY = factoryRegistry;
    }

    /*//////////////////////////////////////////////////////////////
                        EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function deploy(
        address governance,
        bytes memory feeConfigs,
        bytes memory parametersConfig,
        string memory name,
        string memory symbol
    ) external returns (address instance) {
        if (msg.sender != FACTORY_REGISTRY) revert UNAUTHORIZED();

        if (feeConfigs.length != 128) revert INVALID_PRODUCT_PARAMS();
        if (parametersConfig.length != 288) revert INVALID_PRODUCT_PARAMS();

        instance = address(new SingleBondIssuance(governance, feeConfigs, parametersConfig, name, symbol));
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

import './IProductFactory.sol';

/**
 * @title IFactoryRegistry
 * @author Atlendis Labs
 * @notice Interface of the Factory Registry, its responsibilities are twofold
 *           - manage the product factories,
 *           - use the product factories in order to deploy product instance and register them
 */
interface IFactoryRegistry {
    /**
     * @notice Thrown when the product factory already exists
     */
    error PRODUCT_FACTORY_ALREADY_EXISTING();

    /**
     * @notice Thrown when the candidate product factory does not implement the required interface
     */
    error INVALID_PRODUCT_FACTORY_CANDIDATE();

    /**
     * @notice Thrown when the product factory has not been found
     */
    error PRODUCT_FACTORY_NOT_FOUND();

    /**
     * @notice Thrown when the product instance already exists
     */
    error PRODUCT_INSTANCE_ALREADY_EXISTING();

    /**
     * @notice Emitted when a new product factory has been registered
     * @param productId The ID of the new product
     * @param factory The address of the factory of the new product
     */
    event ProductFactoryRegistered(bytes32 indexed productId, address factory);

    /**
     * @notice Emitted when a product factory has been unregistered
     * @param productId The ID of the new product
     */
    event ProductFactoryUnregistered(bytes32 indexed productId);

    /**
     * @notice Emitted when a new instance of a product has been deployed
     * @param productId The ID of the registered product
     * @param governance Address of the governance of the product instance
     * @param instanceId The string ID of the deployed instance of the product
     * @param instance Address of the deployed instance
     * @param feeConfigs Configurations specific to fees, encoded as bytes
     * @param parametersConfig Configurations specific to all other params, encoded as bytes
     * @param name Name of the ERC721 token associated to the product instance
     * @param symbol Symbol of the ERC721 token associated to the product instance
     */
    event ProductInstanceDeployed(
        bytes32 indexed productId,
        address indexed governance,
        string instanceId,
        address instance,
        bytes feeConfigs,
        bytes parametersConfig,
        string name,
        string symbol
    );

    /**
     * @notice Register a new product factory
     * @param productId The ID of the new product
     * @param factory The address of the factory of the new product
     *
     * Emits a {ProductFactoryRegistered} event
     */
    function registerProductFactory(bytes32 productId, IProductFactory factory) external;

    /**
     * @notice Unregister an existing product factory
     * @param productId The ID of the product
     *
     * Emits a {ProductFactoryUnregistered} event
     */
    function unregisterProductFactory(bytes32 productId) external;

    /**
     * @notice Deploy a new instance of a product and register the address using an ID
     * @param productId The  ID of the registered product
     * @param instanceId The string ID of the deployed instance of the product
     * @param feeConfigs Configurations specific to fees, encoded as bytes
     * @param parametersConfig Configurations specific to all other params, encoded as bytes
     * @param name Name of the ERC721 token associated to the product instance
     * @param symbol Symbol of the ERC721 token associated to the product instance
     *
     * Emits a {ProductInstanceDeployed} event
     */
    function deployProductInstance(
        bytes32 productId,
        string memory instanceId,
        bytes memory feeConfigs,
        bytes memory parametersConfig,
        string memory name,
        string memory symbol
    ) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

import 'lib/openzeppelin-contracts/contracts/access/Ownable.sol';
import 'lib/openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol';
import 'lib/openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol';
import 'lib/openzeppelin-contracts-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol';
import './interfaces/IProductFactory.sol';
import './interfaces/IFactoryRegistry.sol';

/**
 * @title FactoryRegistry
 * @author Atlendis Labs
 * @notice Implementation of the IFactoryRegistry
 *         The product factory management and the right to deploy product instances are restricted to an owner
 */
contract FactoryRegistry is IFactoryRegistry, Initializable, OwnableUpgradeable, UUPSUpgradeable {
    /*//////////////////////////////////////////////////////////////
                                STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public version;
    mapping(bytes32 => IProductFactory) public productFactories;
    mapping(string => address) public productInstances;

    /*//////////////////////////////////////////////////////////////
                             INITIALIZER
    //////////////////////////////////////////////////////////////*/

    function initialize(address governance) public initializer {
        __Ownable_init();
        transferOwnership(governance);
        version++;
    }

    /*//////////////////////////////////////////////////////////////
                            UPGRADABILITY
    //////////////////////////////////////////////////////////////*/

    function _authorizeUpgrade(address) internal override onlyOwner {}

    /*//////////////////////////////////////////////////////////////
                        EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function registerProductFactory(bytes32 productId, IProductFactory factory) external onlyOwner {
        if (address(productFactories[productId]) != address(0)) revert PRODUCT_FACTORY_ALREADY_EXISTING();

        productFactories[productId] = factory;

        emit ProductFactoryRegistered(productId, address(factory));
    }

    function unregisterProductFactory(bytes32 productId) external onlyOwner {
        if (address(productFactories[productId]) == address(0)) revert PRODUCT_FACTORY_NOT_FOUND();

        productFactories[productId] = IProductFactory(address(0));

        emit ProductFactoryUnregistered(productId);
    }

    function deployProductInstance(
        bytes32 productId,
        string memory instanceId,
        bytes memory feeConfigs,
        bytes memory parametersConfig,
        string memory name,
        string memory symbol
    ) external onlyOwner {
        if (productInstances[instanceId] != address(0)) revert PRODUCT_INSTANCE_ALREADY_EXISTING();

        IProductFactory factory = productFactories[productId];
        if (address(factory) == address(0)) revert PRODUCT_FACTORY_NOT_FOUND();

        address instance = factory.deploy(msg.sender, feeConfigs, parametersConfig, name, symbol);
        productInstances[instanceId] = instance;

        emit ProductInstanceDeployed(
            productId,
            msg.sender,
            instanceId,
            instance,
            feeConfigs,
            parametersConfig,
            name,
            symbol
        );
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = _setInitializedVersion(1);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        bool isTopLevelCall = _setInitializedVersion(version);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(version);
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        _setInitializedVersion(type(uint8).max);
    }

    function _setInitializedVersion(uint8 version) private returns (bool) {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, and for the lowest level
        // of initializers, because in other contexts the contract may have been reentered.
        if (_initializing) {
            require(
                version == 1 && !AddressUpgradeable.isContract(address(this)),
                "Initializable: contract is already initialized"
            );
            return false;
        } else {
            require(_initialized < version, "Initializable: contract is already initialized");
            _initialized = version;
            return true;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../ERC1967/ERC1967UpgradeUpgradeable.sol";
import "./Initializable.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is Initializable, IERC1822ProxiableUpgradeable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal onlyInitializing {
    }

    function __UUPSUpgradeable_init_unchained() internal onlyInitializing {
    }
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        require(address(this) == __self, "UUPSUpgradeable: must not be called through delegatecall");
        _;
    }

    /**
     * @dev Implementation of the ERC1822 {proxiableUUID} function. This returns the storage slot used by the
     * implementation. It is used to validate that the this implementation remains valid after an upgrade.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy. This is guaranteed by the `notDelegated` modifier.
     */
    function proxiableUUID() external view virtual override notDelegated returns (bytes32) {
        return _IMPLEMENTATION_SLOT;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822ProxiableUpgradeable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeaconUpgradeable.sol";
import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/StorageSlotUpgradeable.sol";
import "../utils/Initializable.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable {
    function __ERC1967Upgrade_init() internal onlyInitializing {
    }

    function __ERC1967Upgrade_init_unchained() internal onlyInitializing {
    }
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822ProxiableUpgradeable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/StorageSlot.sol)

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
library StorageSlotUpgradeable {
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
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

import 'lib/openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol';
import 'lib/openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol';
import 'lib/openzeppelin-contracts-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol';
import '../FactoryRegistry.sol';

contract FactoryRegistryV2 is FactoryRegistry {
    function upgradeVersion() external onlyOwner {
        version++;
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

import '../../interfaces/IAdapter.sol';
import '../CustodianStorage.sol';

/**
 * @title NeutralAdapter
 * @author Atlendis Labs
 */
contract NeutralAdapter is CustodianStorage, IAdapter {

    /**
     * @inheritdoc IAdapter
     */
    function supportsToken(address) external pure returns(bool) {
        return true;
    }

    /**
     * @inheritdoc IAdapter
     */
    function deposit(uint256) external {}

    /**
     * @inheritdoc IAdapter
     */
    function withdraw(uint256) external {}

    /**
     * @inheritdoc IAdapter
     */
    function empty() external {}

    /**
     * @inheritdoc IAdapter
     */
    function collectRewards() external pure returns (uint256) {
        return 0;
    }

    /**
     * @inheritdoc IERC165
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAdapter).interfaceId;
    }
}