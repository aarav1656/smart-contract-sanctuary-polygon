// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

import "ERC20PresetMinterBurnableUpgradeable.sol";
import "Utils.sol";

/// @title ERC-20 token that pays for all actions within the project.
/// @dev there is a possibility of minting additional Coins
contract Coin is ERC20PresetMinterBurnableUpgradeable {
    using Utils for address;

    address public treasury;
    address public treasuryLP;
    uint256 constant public DENOMINATOR = 10000;
    uint256 constant public MAX_TAX_NUMERATOR = 500;  // 5%
    uint256 public purchaseDEXTaxNumerator;
    uint256 public saleDEXTaxNumerator;
    uint256 public purchaseDEXTaxForLPNumerator;
    uint256 public saleDEXTaxForLPNumerator;
    uint256 public transferTaxNumerator;
    mapping (address => bool) public isPool;
    mapping (address /*account*/ => bool) public isTaxWhitelisted;  // no transfer tax for outgoing transfers
    mapping (address /*account*/ => bool) public isTaxWhitelistedToReceive;  // no transfer tax for incoming transfers

    event TreasurySet(address indexed treasuryAddress);
    event TreasuryLPSet(address indexed treasuryLPAddress);
    event TransferTaxPaid(address indexed sender, address indexed treasury, uint256 taxAmount);
    event SaleDEXTaxPaid(address indexed pool, address indexed seller, address indexed treasury, uint256 taxAmount);
    event PurchaseDEXTaxPaid(address indexed pool, address indexed purchaser, address indexed treasury, uint256 taxAmount);
    event SaleDEXTaxForLPPaid(address indexed pool, address indexed seller, address indexed treasuryLP, uint256 taxAmount);
    event PurchaseDEXTaxForLPPaid(address indexed pool, address indexed purchaser, address indexed treasuryLP, uint256 taxAmount);
    event PoolAdded(address indexed addr);
    event PoolRemoved(address indexed addr);
    event TaxWhitelistAdded(address indexed addr);
    event TaxWhitelistRemoved(address indexed addr);
    event TaxWhitelistToReceiveAdded(address indexed addr);
    event TaxWhitelistToReceiveRemoved(address indexed addr);
    event TransferTaxNumeratorSet(uint256 indexed value);
    event PurchaseDEXTaxNumeratorSet(uint256 indexed value);
    event SaleDEXTaxNumeratorSet(uint256 indexed value);
    event PurchaseDEXTaxForLPNumeratorSet(uint256 indexed value);
    event SaleDEXTaxForLPNumeratorSet(uint256 indexed value);

    /// @notice Adds new DEX pool (only owner can call)
    /// @param pool pool address
    function addPool(address pool) external onlyOwner {
        isPool[pool] = true;
        emit PoolAdded(pool);
    }

    /// @notice Removes DEX pool (only owner can call)
    /// @param pool pool address
    function removePool(address pool) external onlyOwner {
        isPool[pool] = false;
        emit PoolRemoved(pool);
    }

    /// @notice Adds an address to whitelist to send (only owner can call)
    /// @param addr some address
    function addTaxWhitelist(address addr) external onlyOwner {
        isTaxWhitelisted[addr] = true;
        emit TaxWhitelistAdded(addr);
    }

    /// @notice Removes an address to whitelist to send (only owner can call)
    /// @param addr some address
    function removeTaxWhitelist(address addr) external onlyOwner {
        isTaxWhitelisted[addr] = false;
        emit TaxWhitelistRemoved(addr);
    }

    /// @notice Adds an address to whitelist to receive (only owner can call)
    /// @param addr some address
    function addTaxWhitelistToReceive(address addr) external onlyOwner {
        isTaxWhitelistedToReceive[addr] = true;
        emit TaxWhitelistToReceiveAdded(addr);
    }

    /// @notice Removes an address to whitelist to receive (only owner can call)
    /// @param addr some address
    function removeTaxWhitelistToReceive(address addr) external onlyOwner {
        isTaxWhitelistedToReceive[addr] = false;
        emit TaxWhitelistToReceiveRemoved(addr);
    }

    /// @notice Set new "treasury" setting value (only contract owner may call)
    /// @param treasuryAddress new setting value
    function setTreasury(address treasuryAddress) external onlyOwner {
        treasury = treasuryAddress.ensureNotZero();
        emit TreasurySet(treasuryAddress);
    }

    /// @notice Set new "treasuryLP" setting value (only contract owner may call)
    /// @param treasuryLPAddress new setting value
    function setTreasuryLP(address treasuryLPAddress) external onlyOwner {
        treasuryLP = treasuryLPAddress.ensureNotZero();
        emit TreasuryLPSet(treasuryLPAddress);
    }

    /// @notice Set new "transferTaxNumerator" setting value (only contract owner may call)
    /// @param value new setting value
    function setTransferTaxNumerator(uint256 value) external onlyOwner {
        require(value <= MAX_TAX_NUMERATOR, "TAX_IS_TOO_HIGH");
        transferTaxNumerator = value;
        emit TransferTaxNumeratorSet(value);
    }

    /// @notice Set new "purchaseDEXTaxNumerator" setting value (only contract owner may call)
    /// @param value new setting value
    function setPurchaseDEXTaxNumerator(uint256 value) external onlyOwner {
        require(value <= MAX_TAX_NUMERATOR, "TAX_IS_TOO_HIGH");
        purchaseDEXTaxNumerator = value;
        emit PurchaseDEXTaxNumeratorSet(value);
    }

    /// @notice Set new "saleDEXTaxNumerator" setting value (only contract owner may call)
    /// @param value new setting value
    function setSaleDEXTaxNumerator(uint256 value) external onlyOwner {
        require(value <= MAX_TAX_NUMERATOR, "TAX_IS_TOO_HIGH");
        saleDEXTaxNumerator = value;
        emit SaleDEXTaxNumeratorSet(value);
    }

    /// @notice Set new "purchaseDEXTaxForLPNumerator" setting value (only contract owner may call)
    /// @param value new setting value
    function setPurchaseDEXTaxForLPNumerator(uint256 value) external onlyOwner {
        require(value <= MAX_TAX_NUMERATOR, "TAX_IS_TOO_HIGH");
        purchaseDEXTaxForLPNumerator = value;
        emit PurchaseDEXTaxForLPNumeratorSet(value);
    }

    /// @notice Set new "saleDEXTaxForLPNumerator" setting value (only contract owner may call)
    /// @param value new setting value
    function setSaleDEXTaxForLPNumerator(uint256 value) external onlyOwner {
        require(value <= MAX_TAX_NUMERATOR, "TAX_IS_TOO_HIGH");
        saleDEXTaxForLPNumerator = value;
        emit SaleDEXTaxForLPNumeratorSet(value);
    }

    /// @notice initialize the contract
    /// @param nameValue name
    /// @param symbolValue symbol
    /// @param receiverValue receiver of the initial minting
    /// @param totalSupplyValue total supply of the token on the initial minting
    /// @param treasuryAddressValue treasury to receive fees
    /// @param treasuryLPAddressValue treasuryLP to receive LP fees
    /// @param ownerValue contract owner
    function initialize(
        string memory nameValue,
        string memory symbolValue,
        address receiverValue,
        uint256 totalSupplyValue,
        address treasuryAddressValue,
        address treasuryLPAddressValue,
        address ownerValue
    )
        external
        initializer
    {
        treasury = treasuryAddressValue.ensureNotZero();
        treasuryLP = treasuryLPAddressValue.ensureNotZero();
        __ERC20PresetMinterBurnable_init(nameValue, symbolValue, ownerValue);
        _mint(receiverValue, totalSupplyValue);
    }

    function _transfer(address from, address recipient, uint256 amount) internal virtual override {
        uint256 initialAmount = amount;
        if(isPool[recipient]) {
            if (isPool[from]) {  // isPool[from] && isPool[recipient]
                // swap through 2 pools e.g. path=[USDC, COIN, USDT]
                // no tax for cross pool liquidity moving
            } else {  // !isPool[from] && isPool[recipient]
                // sale
                if (!isTaxWhitelisted[from]) {
                    if (saleDEXTaxNumerator > 0){
                        uint256 tax = initialAmount * saleDEXTaxNumerator / DENOMINATOR;
                        super._transfer(from, treasury, tax);
                        amount -= tax;
                        emit SaleDEXTaxPaid({seller: from, pool: recipient, treasury: treasury, taxAmount: tax});
                    }
                    if(saleDEXTaxForLPNumerator > 0) {
                        uint256 tax = initialAmount * saleDEXTaxForLPNumerator / DENOMINATOR;
                        super._transfer(from, treasuryLP, tax);
                        amount -= tax;
                        emit SaleDEXTaxForLPPaid({seller: from, pool: recipient, treasuryLP: treasuryLP, taxAmount: tax});
                    }
                }
            }
        } else {  // !isPool[recipient]
            if (isPool[from]) {  // isPool[from] && !isPool[recipient]
                // purchase
                if ((!isTaxWhitelisted[recipient]) && (!isTaxWhitelistedToReceive[recipient])) {
                    if (purchaseDEXTaxNumerator > 0) {
                        uint256 tax = initialAmount * purchaseDEXTaxNumerator / DENOMINATOR;
                        super._transfer(from, treasury, tax);
                        amount -= tax;
                        emit PurchaseDEXTaxPaid({purchaser: recipient, pool: from, treasury: treasury, taxAmount: tax});
                    }
                    if (purchaseDEXTaxForLPNumerator > 0) {
                        uint256 tax = initialAmount * purchaseDEXTaxForLPNumerator / DENOMINATOR;
                        super._transfer(from, treasuryLP, tax);
                        amount -= tax;
                        emit PurchaseDEXTaxForLPPaid({purchaser: recipient, pool: from, treasuryLP: treasuryLP, taxAmount: tax});
                    }
                }
            } else {  // !isPool[from] && !isPool[recipient]
                // regular transfer (no dex)
                if (
                    (transferTaxNumerator > 0) &&
                    (!isTaxWhitelisted[from]) &&
                    (!isTaxWhitelistedToReceive[recipient])
                ) {
                    uint256 tax = initialAmount * transferTaxNumerator / DENOMINATOR;
                    super._transfer(from, treasury, tax);
                    amount -= tax;
                    emit TransferTaxPaid({sender: from, treasury: treasury, taxAmount: tax});
                }
            }
        }
        super._transfer(from, recipient, amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

import "ERC20BurnableUpgradeable.sol";
import "OwnableUpgradeable.sol";
import "ContextUpgradeable.sol";
import "Initializable.sol";

/**
 * @title ERC20PresetMinterBurnableUpgradeable
 * @dev erc20 token template
 */
abstract contract ERC20PresetMinterBurnableUpgradeable is
    Initializable,
    ContextUpgradeable,
    OwnableUpgradeable,
    ERC20BurnableUpgradeable
{
    function initialize(string memory nameValue, string memory symbolValue, address ownerValue) external virtual initializer {
        __ERC20PresetMinterBurnable_init(nameValue, symbolValue, ownerValue);
    }

    function __ERC20PresetMinterBurnable_init(string memory nameValue, string memory symbolValue, address ownerValue) internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
        __ERC20_init_unchained(nameValue, symbolValue);
        __ERC20Burnable_init_unchained();
        __ERC20PresetMinterBurnable_init_unchained(ownerValue);
    }

    function __ERC20PresetMinterBurnable_init_unchained(address ownerValue) internal initializer {
        transferOwnership(ownerValue);
    }

    /**
     * @dev Mints `amount` new tokens for `to`.
     * See {ERC20-_mint}.
     */
    function mint(address to, uint256 amount) public onlyOwner virtual {
        _mint(to, amount);
    }

    uint256[10] private __gap_ERC20PresetMinterBurnableUpgradeable;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "ERC20Upgradeable.sol";
import "ContextUpgradeable.sol";
import "Initializable.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20BurnableUpgradeable is Initializable, ContextUpgradeable, ERC20Upgradeable {
    function __ERC20Burnable_init() internal initializer {
        __Context_init_unchained();
        __ERC20Burnable_init_unchained();
    }

    function __ERC20Burnable_init_unchained() internal initializer {
    }
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
        uint256 currentAllowance = allowance(account, _msgSender());
        require(currentAllowance >= amount, "ERC20: burn amount exceeds allowance");
        unchecked {
            _approve(account, _msgSender(), currentAllowance - amount);
        }
        _burn(account, amount);
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "IERC20Upgradeable.sol";
import "IERC20MetadataUpgradeable.sol";
import "ContextUpgradeable.sol";
import "Initializable.sol";

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
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable {
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
    function __ERC20_init(string memory name_, string memory symbol_) internal initializer {
        __Context_init_unchained();
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal initializer {
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

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
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

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
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
    uint256[45] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
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

pragma solidity ^0.8.0;
import "Initializable.sol";

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
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "ContextUpgradeable.sol";
import "Initializable.sol";

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
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;


/// @title Utils
library Utils {
    function ensureNotZero(address addr) internal pure returns(address) {
        require(addr != address(0), "ZERO_ADDRESS");
        return addr;
    }

    modifier onlyNotZeroAddress(address addr) {
        require(addr != address(0), "ZERO_ADDRESS");
        _;
    }
}