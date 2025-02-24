/**
 *Submitted for verification at polygonscan.com on 2023-04-24
*/

// File: ERC20/Context.sol


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

// File: ERC20/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
contract OwnableContract is Context {
    address private _owner;
    mapping (address => bool) private _whitelistedAdmin;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event AdminAdded(address indexed addedBy, address indexed newAdmin);
    event AdminRemoved(address indexed removedBy, address indexed admin);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
        _whitelistedAdmin[_msgSender()] = true;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner(address _address) {
        require(owner() == _address, "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Throws if called by any account other than the whitelistedAdmin.
     */
    modifier onlyWhitelistedAdmin(address _address){
        require(_whitelistedAdmin[_address], "Ownable: caller is not the whitelisted admin");
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Add new Admin to _whitelistedAdmin mapping.
     * Can only be called by the current owner and existing admin.
     */
    function addWhitelistedAdmin(address _whitelistAdmin)external onlyWhitelistedAdmin(msg.sender) returns(bool){
        require(!_whitelistedAdmin[_whitelistAdmin], "Ownable: already a whitelisted admin");
        _whitelistedAdmin[_whitelistAdmin] = true;
        emit AdminAdded(msg.sender, _whitelistAdmin);
        return true;
    }

    /**
     * @dev Remove existing Admin from _whitelistedAdmin mapping.
     * Can only be called by the current owner and existing admin.
     * Existing admin will not able to remove him/her self form _whitelistedAdmin mapping.
     */
    function removeWhitelistedAdmin(address _whitelistAdmin)external onlyWhitelistedAdmin(msg.sender) returns(bool){
        require(_whitelistedAdmin[_whitelistAdmin], "Ownable: not a whitelisted admin");
        require(_whitelistAdmin != msg.sender, "Ownable: self-remove not allowed");
        _whitelistedAdmin[_whitelistAdmin] = false;
        emit AdminRemoved(msg.sender, _whitelistAdmin);
        return true;
    }


    /**
     * @dev Return `true` if the sender is the whitelistedAdmin else `revert`.
     * 
     * Requirements:
     *
     * - `_address` that you need to check whether it is a whitelistedAdmin or not.
     */
    function checkAdmin(address _address) external view onlyWhitelistedAdmin(_address) returns(bool){
        return true;
    }

    /**
     * @dev Return `true` if the sender is the owner else `revert`.
     * 
     * Requirements:
     *
     * - `_address` that you need to check whether it is a owner or not.
     */
    function checkOwner(address _address) external view onlyOwner(_address) returns(bool){
        return true;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner(msg.sender) {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner(msg.sender) {
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
// File: ERC20/IERC20.sol


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

// File: ERC20/ERC20.sol


// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

// import "./extensions/IERC20Metadata.sol";


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
contract ERC20 is Context, IERC20{
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
    function name() public view virtual  returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual  returns (string memory) {
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
    function decimals() public view virtual  returns (uint8) {
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

// File: EUSD.sol


pragma solidity ^0.8.17;



contract EUSDContract is ERC20 {
    event Minted(
        address indexed _owner,
        address indexed _to,
        uint256 indexed _amount
    );
    event EGOLDAddressSet(address indexed _setBy, address indexed _EGOLDAdd);
    event TransferEUSDtoEGOLD(
        address indexed _from,
        address _to,
        uint256 _amount
    );
    event OwnableAddressSet(address indexed _setBy, address indexed _OwnableAddress);

    OwnableContract public ownable;
    address public EGOLD;

    constructor() ERC20("EUSD", "EUSD") {}

    modifier onlyEGOLD() {
        require(msg.sender == EGOLD, "EUSD: only EGOLD contract");
        _;
    }

    function setOwnable(address _ownable) external returns (bool) {
        require(_ownable != address(0), "EUSD: new _ownalbe is the zero address");
        if (address(ownable) == address(0)) {
            ownable = OwnableContract(_ownable);
        emit OwnableAddressSet(msg.sender, _ownable);
            return true;
        }
        require(ownable.checkOwner(msg.sender));
        ownable = OwnableContract(_ownable);
        emit OwnableAddressSet(msg.sender, _ownable);
        return true;
    }

    function mint(address _account, uint256 _amount) public {
        require(
            address(ownable) != address(0) && ownable.checkOwner(msg.sender),
            "EUSD: Ownable address not set"
        );

        _mint(_account, _amount);
        emit Minted(msg.sender, _account, _amount);
    }

    function setEGOLD(address _Egold) public {
        require(
            address(ownable) != address(0) && ownable.checkOwner(msg.sender),
            "EUSD: Ownable address not set"
        );

        EGOLD = _Egold;
        emit EGOLDAddressSet(msg.sender, _Egold);
    }

    function transferBal(address _from, uint256 _amount) external onlyEGOLD {
        _transfer(_from, EGOLD, _amount);
        emit TransferEUSDtoEGOLD(_from, EGOLD, _amount);
    }
}

// File: EINR.sol


pragma solidity ^0.8.17;



contract EINRContract is ERC20 {
    event Minted(
        address indexed _owner,
        address indexed _to,
        uint256 indexed _amount
    );
    event EGOLDAddressSet(address indexed _setBy, address indexed _EGOLDAdd);
    event TransferEINRtoEGOLD(
        address indexed _from,
        address _to,
        uint256 _amount
    );
    event OwnableAddressSet(address indexed _setBy, address indexed _OwnableAddress);

    OwnableContract public ownable;
    address public EGOLD;

    constructor() ERC20("EINR", "EINR") {}

    modifier onlyEGOLD() {
        require(msg.sender == EGOLD, "EINR: only EGOLD contract");
        _;
    }

    function setOwnable(address _ownable) external returns (bool) {
        require(_ownable != address(0), "EINR: new _ownalbe is the zero address");
        if (address(ownable) == address(0)) {
            ownable = OwnableContract(_ownable);
            emit OwnableAddressSet(msg.sender, _ownable);
            return true;
        }
        require(ownable.checkOwner(msg.sender));
        ownable = OwnableContract(_ownable);
            emit OwnableAddressSet(msg.sender, _ownable);
        return true;
    }

    function mint(address _account, uint256 _amount) public {
        require(
            address(ownable) != address(0) && ownable.checkOwner(msg.sender),
            "EINR: Ownable address not set"
        );
        _mint(_account, _amount);
        emit Minted(msg.sender, _account, _amount);
    }

    function setEGOLD(address _Egold) public {
        require(
            address(ownable) != address(0) && ownable.checkOwner(msg.sender),
            "EINR: Ownable address not set"
        );
        EGOLD = _Egold;
        emit EGOLDAddressSet(msg.sender, _Egold);
    }

    function transferBal(address _from, uint256 _amount) external onlyEGOLD {
        _transfer(_from, EGOLD, _amount);
        emit TransferEINRtoEGOLD(_from, EGOLD, _amount);
    }
}

// File: EGOLD.sol

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;





contract EGOLDContract is ERC20 {
    event Minted(address indexed _to, uint256 _amount);
    event Burned(address indexed _to, uint256 _amount);
    event InventoryAddressSet(
        address indexed _setBy,
        address indexed _InventoryAdd
    );
    event EINRAddressSet(address indexed _setBy, address indexed _EINRAdd);
    event EUSDAddressSet(address indexed _setBy, address indexed _EUSDAdd);
    event OwnableAddressSet(
        address indexed _setBy,
        address indexed _OwnableAddress
    );
    event EGOLD_INR_PriceSet(address indexed _setBy, uint256 _EGOLDPriceINR);
    event EGOLD_USD_PriceSet(address indexed _setBy, uint256 _EGOLDPriceUSD);
    event EGOLD_EINR_Transfer(
        address _from,
        address indexed _to,
        uint256 _EGoldAmount,
        uint256 _EINRAmount
    );
    event EGOLD_INR_Transfer(
        address _from,
        address indexed _to,
        bytes32 indexed _receipt,
        uint256 _EGoldmount,
        uint256 _INRAmount
    );
    event EGOLD_EUSD_Transfer(
        address _from,
        address indexed _to,
        uint256 _EGoldAmount,
        uint256 _EUSDAmount
    );
    event EGOLD_USD_Transfer(
        address _from,
        address indexed _to,
        bytes32 indexed _receipt,
        uint256 _EGoldmount,
        uint256 _USDAmount
    );

    OwnableContract public ownable;
    EINRContract public _EINR;
    EUSDContract public _EUSD;
    uint256 public EGoldPriceINR;
    uint256 public EGoldPriceUSD;
    uint256 public availableSupply;
    address public inventoryHandler;

    modifier onlyInventoryHandler() {
        require(
            msg.sender == inventoryHandler,
            "EGOLD: Only Inventory Handler Contract allowed."
        );
        _;
    }

    constructor() ERC20("EGOLD", "EGOLD") {}

    function setOwnable(address _ownable) external returns (bool) {
        require(
            _ownable != address(0),
            "EGOLD: new _ownalbe is the zero address"
        );
        if (address(ownable) == address(0)) {
            ownable = OwnableContract(_ownable);
            emit OwnableAddressSet(msg.sender, _ownable);
            return true;
        }
        require(ownable.checkOwner(msg.sender));
        ownable = OwnableContract(_ownable);
        emit OwnableAddressSet(msg.sender, _ownable);
        return true;
    }

    function setInventoryHandler(address _address) public {
        require(
            address(ownable) != address(0) && ownable.checkOwner(msg.sender),
            "EGOLD: Ownable address not set"
        );
        require(
            inventoryHandler == address(0),
            "EGOLD: nventory Handler already set."
        );
        inventoryHandler = _address;
        emit InventoryAddressSet(msg.sender, inventoryHandler);
    }

    function mint(uint256 _amount) public onlyInventoryHandler {
        _mint(address(this), _amount);
        availableSupply = balanceOf(address(this));
        emit Minted(address(this), _amount);
    }

    function burn(uint256 _amount) public onlyInventoryHandler {
        require(
            balanceOf(address(this)) >= _amount,
            "EGOLD: Insufficient EGOLD in Contract."
        );
        _burn(address(this), _amount);
        availableSupply = balanceOf(address(this));
        emit Burned(address(this), _amount);
    }

    function setEINR(address _Einr) public {
        require(
            address(ownable) != address(0) && ownable.checkOwner(msg.sender),
            "EGOLD: Ownable address not set"
        );
        _EINR = EINRContract(_Einr);
        emit EINRAddressSet(msg.sender, _Einr);
    }

    function setEUSD(address _Eusd) public {
        require(
            address(ownable) != address(0) && ownable.checkOwner(msg.sender),
            "EGOLD: Ownable address not set"
        );
        _EUSD = EUSDContract(_Eusd);
        emit EUSDAddressSet(msg.sender, _Eusd);
    }

    function setEGoldPriceINR(uint256 _price) public {
        require(
            address(ownable) != address(0) && ownable.checkOwner(msg.sender),
            "EGOLD: Ownable address not set"
        );
        EGoldPriceINR = _price;
        emit EGOLD_INR_PriceSet(msg.sender, EGoldPriceINR);
    }

    function setEGoldPriceUSD(uint256 _price) public {
        require(
            address(ownable) != address(0) && ownable.checkOwner(msg.sender),
            "EGOLD: Ownable address not set"
        );
        EGoldPriceUSD = _price;
        emit EGOLD_USD_PriceSet(msg.sender, EGoldPriceUSD);
    }

    function buyEGoldEINR(uint256 _EGoldAmount) public {
        require(
            balanceOf(address(this)) >= _EGoldAmount,
            "EGOLD: Insufficient EGOLD in Contract."
        );
        require(EGoldPriceINR > 0, "EGOLD: EGOLD Price not set");
        uint256 totalEINR = EGoldPriceINR * (_EGoldAmount / 10 ** 18);
        require(
            _EINR.balanceOf(msg.sender) >= totalEINR,
            "EGOLD: Insuffcient EINR Balance"
        );
        _EINR.transferBal(msg.sender, totalEINR);
        _transfer(address(this), msg.sender, _EGoldAmount);
        availableSupply -= _EGoldAmount;
        emit EGOLD_EINR_Transfer(
            address(this),
            msg.sender,
            _EGoldAmount,
            totalEINR
        );
    }

    function buyEGoldINR(
        uint256 _EGoldAmount,
        address _to,
        bytes32 _receipt
    ) public {
        require(
            address(ownable) != address(0) && ownable.checkOwner(msg.sender),
            "EGOLD: Ownable address not set"
        );
        require(
            balanceOf(address(this)) >= _EGoldAmount,
            "EGOLD: Insufficient EGOLD in Contract."
        );
        require(EGoldPriceINR > 0, "EGOLD: EGOLD Price not set");
        uint256 totalINR = (EGoldPriceINR / 10 ** 18) *
            (_EGoldAmount / 10 ** 18);
        _transfer(address(this), _to, _EGoldAmount);
        availableSupply -= _EGoldAmount;
        emit EGOLD_INR_Transfer(
            address(this),
            _to,
            _receipt,
            _EGoldAmount,
            totalINR
        );
    }

    function buyEGoldEUSD(uint256 _EGoldAmount) public {
        require(
            balanceOf(address(this)) >= _EGoldAmount,
            "EGOLD: Insufficient EGOLD in Contract."
        );
        require(EGoldPriceUSD > 0, "EGOLD: EGOLD Price not set");
        uint256 totalEUSD = EGoldPriceUSD * (_EGoldAmount / 10 ** 18);
        require(
            _EUSD.balanceOf(msg.sender) >= totalEUSD,
            "EGOLD: Insuffcient EUSD Balance"
        );
        _EUSD.transferBal(msg.sender, totalEUSD);
        _transfer(address(this), msg.sender, _EGoldAmount);
        availableSupply -= _EGoldAmount;
        emit EGOLD_EUSD_Transfer(
            address(this),
            msg.sender,
            _EGoldAmount,
            totalEUSD
        );
    }

    function buyEGoldUSD(
        uint256 _EGoldAmount,
        address _to,
        bytes32 _receipt
    ) public {
        require(
            address(ownable) != address(0) && ownable.checkOwner(msg.sender),
            "EGOLD: Ownable address not set"
        );
        require(
            balanceOf(address(this)) >= _EGoldAmount,
            "EGOLD: Insufficient EGOLD in Contract."
        );
        require(EGoldPriceUSD > 0, "EGOLD: EGOLD Price not set");
        uint256 totalUSD = (EGoldPriceUSD / 10 ** 18) *
            (_EGoldAmount / 10 ** 18);
        _transfer(address(this), _to, _EGoldAmount);
        availableSupply -= _EGoldAmount;
        emit EGOLD_USD_Transfer(
            address(this),
            _to,
            _receipt,
            _EGoldAmount,
            totalUSD
        );
    }

    function BalEINR()
        public
        view
        returns (uint256 _BalEINR, uint256 _BalEUSD)
    {
        _BalEINR = _EINR.balanceOf(address(this));
        _BalEINR = _EUSD.balanceOf(address(this));
        return (_BalEINR, _BalEUSD);
    }
}