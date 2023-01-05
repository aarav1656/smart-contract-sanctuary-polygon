// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

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
     *
     * May emit a {RoleGranted} event.
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
     *
     * May emit a {RoleRevoked} event.
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
     *
     * May emit a {RoleRevoked} event.
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
     * May emit a {RoleGranted} event.
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
     *
     * May emit a {RoleGranted} event.
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
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/extensions/ERC20Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC20.sol";
import "../../../utils/Context.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
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
pragma solidity 0.8.11;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./interfaces/IStaking.sol";
import "./interfaces/ISquads.sol";
import "./interfaces/IReferralManager.sol";

contract Squads is ISquads, AccessControl {
    uint256 public SUBSCRIPTION_PERIOD_DAYS = 365;

    SquadPlan[] public plans;
    mapping(uint256 => mapping(address => Squad)) private userSubscriptions;
    mapping(uint256 => mapping(address => address[])) private squadMembers;

    ERC20Burnable public subscriptionToken;
    IReferralManager public referralManager;
    IStaking public stakingContract;

    event Subscribed(
        address indexed subscriber,
        uint256 indexed planId,
        uint256 indexed timestamp
    );
    event SquadFilled(
        address indexed user,
        uint256 indexed planId,
        uint256 indexed squadCount
    );
    event MemberAdded(
        address indexed user,
        uint256 indexed planId,
        address member,
        uint256 squadMembers
    );
    event SquadPlanCreated(
        uint256 indexed planId,
        uint256 subscriptionCost,
        uint256 reward,
        uint256 stakingThreshold,
        uint256 squadSize,
        uint256 stakingPlanId
    );
    event SquadActivityChanged(uint256 indexed planId, bool isActive);

    constructor(
        address subscriptionToken_,
        address referralManager_,
        address stakingContract_
    ) {
        require(subscriptionToken_ != address(0));
        require(referralManager_ != address(0));
        require(stakingContract_ != address(0));

        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());

        subscriptionToken = ERC20Burnable(subscriptionToken_);
        referralManager = IReferralManager(referralManager_);
        stakingContract = IStaking(stakingContract_);
    }

    function subscribe(uint256 planId) public {
        require(planId < plans.length, "Incorrect plan id");

        address subscriber = _msgSender();
        SquadPlan storage plan = plans[planId];

        require(plan.isActive, "Plan is not active");

        subscriptionToken.burnFrom(subscriber, plan.subscriptionCost);

        squadMembers[planId][subscriber] = new address[](0);

        uint256 startDate = userSubscriptions[planId][subscriber].subscription <
            getTimestamp()
            ? getTimestamp()
            : userSubscriptions[planId][subscriber].subscription;
        userSubscriptions[planId][subscriber].subscription =
            startDate +
            SUBSCRIPTION_PERIOD_DAYS *
            1 days;

        emit Subscribed(subscriber, planId, startDate);
    }

    function tryToAddMember(
        uint256 stakingPlanId,
        address referrer,
        address member,
        uint256 amount
    ) public returns (bool) {
        if (referrer == address(0) || member == address(0)) return false;

        int256 _planId = getSufficientPlanIdByStakingAmount(
            stakingPlanId,
            amount
        );

        if (_planId < 0) return false;

        uint256 planId = uint256(_planId);

        if (plans[planId].stakingPlanId != stakingPlanId) return false;

        if (
            _isSenderAuthorized(_msgSender()) &&
            userHasPlanSubscription(referrer, planId) &&
            userHasSufficientStaking(referrer, planId) &&
            !_isMemberInSquad(referrer, planId, member)
        ) {
            squadMembers[planId][referrer].push(member);
            uint256 membersAmount = squadMembers[planId][referrer].length;

            if (membersAmount >= plans[planId].squadSize) {
                Squad storage partner = userSubscriptions[planId][referrer];

                partner.squadsFilled += 1;
                partner.subscription = 0;

                referralManager.addUserDividends(
                    IReferralManager.AddDividendsParams(
                        referrer,
                        plans[planId].reward,
                        address(this),
                        1,
                        plans[planId].stakingThreshold,
                        stakingPlanId,
                        4
                    )
                );

                emit SquadFilled(referrer, planId, partner.squadsFilled);
            } else {
                emit MemberAdded(referrer, planId, member, membersAmount);
            }

            return true;
        }

        return false;
    }

    // --------- Helper functions ---------
    function getUserSubscription(address user, uint256 planId)
        public
        view
        returns (Squad memory)
    {
        return userSubscriptions[planId][user];
    }

    function getUserSquadMembers(address user, uint256 planId)
        public
        view
        returns (address[] memory)
    {
        return squadMembers[planId][user];
    }

    function getPlan(uint256 planId) public view returns (SquadPlan memory) {
        return plans[planId];
    }

    function getPlans() public view returns (SquadPlan[] memory) {
        return plans;
    }

    function getActivePlans() public view returns (SquadPlan[] memory) {
        uint256 totalActivePlans = 0;
        bool[] memory activePlansFlags = new bool[](plans.length);
        for (uint256 i = 0; i < plans.length; i++) {
            if (plans[i].isActive) {
                activePlansFlags[i] = true;
                totalActivePlans += 1;
            }
        }

        SquadPlan[] memory activePlans = new SquadPlan[](totalActivePlans);
        for (uint256 i = plans.length; i > 0; i--) {
            if (activePlansFlags[i - 1]) {
                totalActivePlans -= 1;
                activePlans[totalActivePlans] = plans[i - 1];
                if (totalActivePlans == 0) break;
            }
        }

        return activePlans;
    }

    function userHasSufficientStaking(address user, uint256 planId)
        public
        view
        returns (bool)
    {
        IStaking.Stake[] memory stakes = stakingContract.getUserStakes(
            plans[planId].stakingPlanId,
            user
        );

        for (uint256 i = stakes.length; i > 0; i--) {
            // stake is: active + in SAV token + sufficient amount
            if (
                stakes[i - 1].timeEnd > block.timestamp &&
                !stakes[i - 1].isToken2 &&
                getSufficientPlanIdByStakingAmount(
                    plans[planId].stakingPlanId,
                    stakes[i - 1].amount
                ) ==
                int256(planId)
            ) return true;
        }

        return false;
    }

    function userHasPlanSubscription(address user, uint256 planId)
        public
        view
        returns (bool)
    {
        return userSubscriptions[planId][user].subscription > block.timestamp;
    }

    function hasAnySubscription(address user) public view returns (bool) {
        for (uint256 i = 0; i < plans.length; i++) {
            if (userHasPlanSubscription(user, i)) {
                return true;
            }
        }
        return false;
    }

    function getSufficientPlanIdByStakingAmount(
        uint256 stakingPlanId,
        uint256 amount
    ) public view returns (int256) {
        int256 planId = -1;
        for (uint256 i = 0; i < plans.length; i++) {
            if (
                plans[i].isActive &&
                plans[i].stakingPlanId == stakingPlanId &&
                amount >= plans[i].stakingThreshold
            ) planId = int256(i);
        }

        return planId;
    }

    function _isMemberInSquad(
        address user,
        uint256 planId,
        address member
    ) internal view returns (bool) {
        address[] memory squad = squadMembers[planId][user];

        for (uint256 i = 0; i < squad.length; i++) {
            if (squad[i] == member) return true;
        }

        return false;
    }

    function getTimestamp() public view returns (uint256) {
        return block.timestamp;
    }

    function _isSenderAuthorized(address contractAddress)
        internal
        view
        returns (bool)
    {
        return address(stakingContract) == contractAddress;
    }

    // --------- Administrative functions ---------
    function addPlan(
        uint256 subscriptionCost_,
        uint256 reward_,
        uint256 stakingThreshold_,
        uint256 squadSize_,
        uint256 stakingPlanId_
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        SquadPlan memory plan = SquadPlan(
            plans.length,
            subscriptionCost_,
            reward_,
            stakingThreshold_,
            squadSize_,
            stakingPlanId_,
            true
        );

        plans.push(plan);

        emit SquadPlanCreated(
            plans.length - 1,
            subscriptionCost_,
            reward_,
            stakingThreshold_,
            squadSize_,
            stakingPlanId_
        );
    }

    function updatePlanSubscriptionCost(
        uint256 planId,
        uint256 subscriptionCost
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        plans[planId].subscriptionCost = subscriptionCost;
    }

    function updatePlanReward(uint256 planId, uint256 reward)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        plans[planId].reward = reward;
    }

    function updatePlanStakingThreshold(uint256 planId, uint256 threshold)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        plans[planId].stakingThreshold = threshold;
    }

    function updatePlanSquadSize(uint256 planId, uint256 size)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        plans[planId].squadSize = size;
    }

    function updatePlanStakingId(uint256 planId, uint256 stakingPlanId)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        plans[planId].stakingPlanId = stakingPlanId;
    }

    function updatePlanActivity(uint256 planId, bool isActive)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        plans[planId].isActive = isActive;
        emit SquadActivityChanged(planId, isActive);
    }

    function updateSubscriptionPeriod(uint256 numDays)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        SUBSCRIPTION_PERIOD_DAYS = numDays;
    }

    function updateSubscriptionToken(address token)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        subscriptionToken = ERC20Burnable(token);
    }

    function updateSubscriptionReferralManager(address referralManager_)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        referralManager = IReferralManager(referralManager_);
    }

    function updateStakingContract(address stakingContract_)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        stakingContract = IStaking(stakingContract_);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface IReferralManager {
    struct Referral {
        address referralAddress;
        uint256 level;
        uint256 activationDate;
        bool isReferralSubscriptionActive;
    }

    struct AddDividendsParams {
        address user;
        uint256 reward;
        address referral;
        uint256 level;
        uint256 depositAmount;
        uint256 stakingPlanId;
        // REASONS:
        // 0 - full reward
        // 1 - no ref subscription
        // 2 - no user stake
        // 3 - trancated by user stake
        // 4 - team
        uint256 reason;
    }

    function getReferralLevels() external pure returns (uint256);

    function addUserDividends(AddDividendsParams memory params) external;

    function getUserReferrer(address user) external view returns (address);

    function setUserReferrer(address user, address referrer) external;

    function userHasSubscription(address user, uint256 level)
        external
        view
        returns (bool);

    function calculateRefReward(uint256 amount, uint256 level)
        external
        view
        returns (uint256);

    function getUserReferralsByLevel(address userAddress, uint256 level)
        external
        view
        returns (Referral[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface ISquads {
    struct Squad {
        uint256 subscription; // when subscription expire
        uint256 squadsFilled; // how much squads user filled
    }

    struct SquadPlan {
        uint256 index;
        uint256 subscriptionCost;
        uint256 reward; // reward for filling full squad
        uint256 stakingThreshold; // min staking amount that member should do
        uint256 squadSize; // amount of squad members
        uint256 stakingPlanId;
        bool isActive;
    }

    function subscribe(uint256 planId) external;

    function tryToAddMember(
        uint256 stakingPlanId,
        address user,
        address member,
        uint256 amount
    ) external returns (bool);

    function getUserSquadMembers(address user, uint256 planId)
        external
        view
        returns (address[] memory);

    function userHasSufficientStaking(address user, uint256 planId)
        external
        view
        returns (bool);

    function getUserSubscription(address user, uint256 planId)
        external
        view
        returns (Squad memory);

    function hasAnySubscription(address user) external view returns (bool);

    function userHasPlanSubscription(address user, uint256 planId)
        external
        view
        returns (bool);

    function getSufficientPlanIdByStakingAmount(
        uint256 stakingPlanId,
        uint256 amount
    ) external view returns (int256);

    function getPlan(uint256 planId) external view returns (SquadPlan memory);

    function getPlans() external view returns (SquadPlan[] memory);

    function getActivePlans() external view returns (SquadPlan[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface IStaking {
    struct StakingPlan {
        bool isActive;
        uint256 subscriptionCost;
        uint256 subscriptionDuration;
        uint256 stakingDuration;
        uint256 apr;
        uint256 totalStakesToken1No;
        uint256 totalStakesToken2No;
        uint256 totalStakedToken1;
        uint256 totalStakedToken2;
        uint256 currentToken1Locked;
        uint256 currentToken2Locked;
        uint256 totalClaimed;
    }

    struct Stake {
        uint256 amount;
        uint256 timeStart;
        uint256 timeEnd;
        uint256 apr;
        uint256 profit;
        bool isClaimed;
        bool isToken2;
    }

    struct Staker {
        Stake[] stakes;
        uint256 subscription;
        uint256 totalClaimed;
        uint256 currentToken1Staked;
        uint256 currentToken2Staked;
    }

    struct UserStakingInfo {
        uint256 totalClaimed;
        uint256 currentToken1Staked;
        uint256 currentToken2Staked;
        bool isSubscribed;
        uint256 subscribedTill;
    }

    struct StakeWithRewardsInfo {
        Stake stake;
        uint256 reward;
    }

    function deposit(
        uint256 planId,
        uint256 depositAmount,
        bool isToken2,
        address referrer
    ) external;

    function withdraw(uint256 planId, uint256 stakeId) external;

    function subscribe(uint256 planId) external;

    // --------- Helper functions ---------
    function getUserPlanInfo(uint256 planId, address userAddress)
        external
        view
        returns (UserStakingInfo memory);

    function getUserStakes(uint256 planId, address userAddress)
        external
        view
        returns (Stake[] memory stakes);

    function getAvailableStakeReward(
        uint256 planId,
        address userAddress,
        uint256 stakeId
    ) external view returns (uint256);

    function hasSubscription(uint256 planId, address user)
        external
        view
        returns (bool);

    function hasAnySubscription(address user) external view returns (bool);
}