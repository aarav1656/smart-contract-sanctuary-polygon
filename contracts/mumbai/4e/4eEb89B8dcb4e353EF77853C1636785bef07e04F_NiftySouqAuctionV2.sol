// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal onlyInitializing {
    }

    function __AccessControl_init_unchained() internal onlyInitializing {
    }
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
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
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
                        StringsUpgradeable.toHexString(uint160(account), 20),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
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
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

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
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
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
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
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
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
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
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
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
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20PermitUpgradeable {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../extensions/draft-IERC20PermitUpgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
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

    function safePermit(
        IERC20PermitUpgradeable token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
                /// @solidity memory-safe-assembly
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
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

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
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
interface IERC165Upgradeable {
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
pragma solidity ^0.8.4;

import "./interface/NiftySouq-IMarketplaceManager.sol";
import "./interface/NiftySouq-IMarketplace.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

struct Bid {
    address bidder;
    uint256 price;
    uint256 bidAt;
    bool canceled;
}

struct Auction {
    uint256 tokenId;
    address tokenContract;
    uint256 startTime;
    uint256 endTime;
    address seller;
    uint256 startBidPrice;
    uint256 reservePrice;
    uint256 highestBidIdx;
    uint256 selectedBid;
    Bid[] bids;
}

struct CreateAuction {
    uint256 offerId;
    uint256 tokenId;
    address tokenContract;
    uint256 startTime;
    uint256 duration;
    address seller;
    uint256 startBidPrice;
    uint256 reservePrice;
}

struct CreateAuctionData {
    uint256 tokenId;
    address tokenContract;
    uint256 duration;
    uint256 startBidPrice;
    uint256 reservePrice;
}

struct MintAndCreateAuctionData {
    address tokenAddress;
    string uri;
    address[] creators;
    uint256[] royalties;
    address[] investors;
    uint256[] revenues;
    uint256 duration;
    uint256 startBidPrice;
    uint256 reservePrice;
}

struct Payout {
    address currency;
    address[] refundAddresses;
    uint256[] refundAmounts;
}

/**
 *@title  Auction contract.
 *@dev Auction  is an implementation contract of initializable contract.
 */
contract NiftySouqAuctionV2 is Initializable,
    AccessControlUpgradeable,
    PausableUpgradeable {
    error GeneralError(string errorCode);

    //*********************** Attaching libraries ***********************//
    using SafeMath for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    //*********************** Declarations ***********************//
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    uint256 private constant PERCENT_UNIT = 1e4;
    uint256 private _bidIncreasePercentage;
    NiftySouqIMarketplace private _marketplace;
    NiftySouqIMarketplaceManager private _marketplaceManager;
    mapping(uint256 => Auction) private _auction;
    uint256 private _extendAuctionPeriod;
    address private _admin;
    string private _defaultCurrency;
    mapping(address => bool) public blockList;

    //*********************** Events ***********************//
    event BlockListUpdated(address indexed client, bool value);
    event eCreateAuction(
        uint256 offerId,
        uint256 tokenId,
        address contractAddress,
        address owner,
        uint256 startTime,
        uint256 duration,
        uint256 startBidPrice,
        uint256 reservePrice
    );
    event eCancelAuction(uint256 offerId);
    event eEndAuction(
        uint256 offerId,
        uint256 BidIdx,
        address buyer,
        address currency,
        uint256 price
    );
    event ePlaceBid(
        uint256 offerId,
        uint256 BidIdx,
        address bidder,
        uint256 bidAmount
    );
    event ePlaceHigherBid(
        uint256 offerId,
        uint256 BidIdx,
        address bidder,
        uint256 bidAmount
    );
    event eCancelBid(uint256 offerId, uint256 bidIdx);
    event ePayoutTransfer(
        address indexed withdrawer,
        uint256 indexed amount,
        address indexed currency
    );

    //*********************** Modifiers ***********************//
    modifier isAdmin() {
        if (msg.sender != _admin) revert GeneralError("NS:101");
        _;
    }

    //*********************** Admin Functions ***********************//
    /**
     *@notice Initializes the contract by setting address of marketplace,marketplace manager contract and bidIncreasePercentage.
     *@dev used instead of constructor.
     *@param marketplace_ address of marketplace contract.
     *@param marketplaceManager_ address of marketplaceManager contract.
     */
    function initialize(
        address marketplace_,
        address marketplaceManager_,
        uint8 version_
    ) external reinitializer(version_) {
        __AccessControl_init();
        __Pausable_init();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(PAUSER_ROLE, msg.sender);
        _marketplace = NiftySouqIMarketplace(marketplace_);
        _marketplaceManager = NiftySouqIMarketplaceManager(marketplaceManager_);
        _admin = msg.sender;
    }

    function auctionConfiguration(
        uint256 bidIncreasePercentage_,
        uint256 extendAuctionPeriod_,
        string calldata defaultCurrency_
    ) external isAdmin {
        _bidIncreasePercentage = bidIncreasePercentage_;
        _extendAuctionPeriod = extendAuctionPeriod_;
        _defaultCurrency = defaultCurrency_;
    }

    /**
     * @notice Pausing/stopping
     * @dev Only by pauser role
     */
    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    /**
     * @notice Unpausing
     * @dev Only by pauser role
     */
    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    /**
     * @notice Update list of blocked users
     * @dev Only by defaul admin role
     * @param _address user's address
     * @param _value block(true) or unblock(false) the user
     */
    function blockListUpdate(address _address, bool _value) public {
        require(
            hasRole(PAUSER_ROLE, msg.sender),
            "You should have a pauser role"
        );

        blockList[_address] = _value;
        emit BlockListUpdated(_address, _value);
    }

    //*********************** Getter Functions ***********************//
    /**
     *@notice gets auction details.
     *@param offerId_ offerId of NFT
     *@return auction_  contains tokenId,address token Contract,start and end time of auction,started bid price,reserved price,seller address,highest bid price,selected bid.
     */
    function getAuctionDetails(uint256 offerId_)
        public
        view
        returns (Auction memory auction_)
    {
        auction_ = _auction[offerId_];
    }

    function getConfiguration()
        external
        view
        returns (
            uint256 bidIncreasePercentage_,
            uint256 extendAuctionPeriod_,
            string memory defaultCurrency_
        )
    {
        bidIncreasePercentage_ = _bidIncreasePercentage;
        extendAuctionPeriod_ = _extendAuctionPeriod;
        defaultCurrency_ = _defaultCurrency;
    }

    //*********************** Setter Functions ***********************//
    /**
     *@notice Creates Auction for NFT.
     *@dev only owner of nft can create auction also it should be erc1155 contract.
     *@param createAuctionData_ contains offerId,tokenId,address of token contract,start time and duration of auction,seller address, strat bid price and reserve price.
     *@return offerId_ offerId of NFT.
     */

    function createAuction(CreateAuctionData memory createAuctionData_)
        public
        whenNotPaused
        returns (uint256 offerId_)
    {
        (
            ContractType contractType,
            bool isERC1155,
            bool isOwner,

        ) = _marketplaceManager.isOwnerOfNFT(
                msg.sender,
                createAuctionData_.tokenId,
                createAuctionData_.tokenContract
            );
        if (blockList[msg.sender]) revert GeneralError("NS:126");
        if (!isOwner) revert GeneralError("NS:104");
        if (isERC1155) revert GeneralError("NS:403");
        if (createAuctionData_.duration <= 0) revert GeneralError("NS:404");
        if (createAuctionData_.startBidPrice <= 0)
            revert GeneralError("NS:405");
        if (createAuctionData_.reservePrice <= 0) revert GeneralError("NS:406");
        if (createAuctionData_.reservePrice <= createAuctionData_.startBidPrice)
            revert GeneralError("NS:407");

        offerId_ = _marketplace.createSale(
            createAuctionData_.tokenId,
            NiftySouqIMarketplace.ContractType(uint256(contractType)),
            NiftySouqIMarketplace.OfferType.AUCTION
        );

        CreateAuction memory auctionData = CreateAuction(
            offerId_,
            createAuctionData_.tokenId,
            createAuctionData_.tokenContract,
            block.timestamp,
            createAuctionData_.duration,
            msg.sender,
            createAuctionData_.startBidPrice,
            createAuctionData_.reservePrice
        );
        _createAuction(auctionData);
        emit eCreateAuction(
            offerId_,
            createAuctionData_.tokenId,
            createAuctionData_.tokenContract,
            msg.sender,
            block.timestamp,
            createAuctionData_.duration,
            createAuctionData_.startBidPrice,
            createAuctionData_.reservePrice
        );
    }

    /**
     *@notice Mints and create Auction
     *@param mintNCreateAuction_ contains token address,uri,creators address,investors address ,royalties percentage,revenue percentage, duration of auction, start bid price of auction,reserved price of nft.
     *@return offerId_ offerId of NFT.
     *@return tokenId_ token Id of NFT.
     */
    function mintCreateAuctionNft(
        MintAndCreateAuctionData calldata mintNCreateAuction_
    ) external whenNotPaused returns (uint256 offerId_, uint256 tokenId_) {
        if (blockList[msg.sender]) revert GeneralError("NS:126");
        uint256 tokenId = _marketplace.mintNft(
            NiftySouqIMarketplace.MintData(
                msg.sender,
                mintNCreateAuction_.tokenAddress,
                mintNCreateAuction_.uri,
                mintNCreateAuction_.creators,
                mintNCreateAuction_.royalties,
                mintNCreateAuction_.investors,
                mintNCreateAuction_.revenues,
                1
            )
        );

        offerId_ = createAuction(
            CreateAuctionData(
                tokenId,
                mintNCreateAuction_.tokenAddress,
                mintNCreateAuction_.duration,
                mintNCreateAuction_.startBidPrice,
                mintNCreateAuction_.reservePrice
            )
        );
        tokenId_ = tokenId;
    }

    /**
     *@notice Cancel Auction of NFT.
     *@param offerId_ offerId of NFT.
     */
    function cancelAuction(uint256 offerId_) external {
        NiftySouqIMarketplace.Offer memory offer = _marketplace.getOfferStatus(
            offerId_
        );
        if (
            (msg.sender != _auction[offerId_].seller) &&
            (!_marketplaceManager.isAdmin(msg.sender))
        ) revert GeneralError("NS:108");
        if (offer.offerType != NiftySouqIMarketplace.OfferType.AUCTION)
            revert GeneralError("NS:121");
        if (offer.status != NiftySouqIMarketplace.OfferState.OPEN)
            revert GeneralError("NS:402");
        (
            address[] memory refundAddresses,
            uint256[] memory refundAmount
        ) = _cancelAuction(offerId_);
        CryptoTokens memory currencyDetails = _marketplaceManager
            .getTokenDetail(_defaultCurrency);

        _payout(
            Payout(currencyDetails.tokenAddress, refundAddresses, refundAmount)
        );

        _marketplace.endSale(
            offerId_,
            NiftySouqIMarketplace.OfferState.CANCELLED
        );
        emit eCancelAuction(offerId_);
    }

    /**
     *@notice Ends Auction with highest bid.
     *@param offerId_ offerId of NFT.
     */
    //End Auction with highest bid
    function endAuction(uint256 offerId_) external {
        {
            NiftySouqIMarketplace.Offer memory offer = _marketplace
                .getOfferStatus(offerId_);
            if (offer.offerType != NiftySouqIMarketplace.OfferType.AUCTION)
                revert GeneralError("NS:121");
            if (offer.status != NiftySouqIMarketplace.OfferState.OPEN)
                revert GeneralError("NS:402");
        }

        {
            if (
                (msg.sender != _auction[offerId_].seller) &&
                (!_marketplaceManager.isAdmin(msg.sender))
            ) revert GeneralError("NS:108");
            if (
                _auction[offerId_]
                    .bids[_auction[offerId_].highestBidIdx]
                    .canceled
            ) revert GeneralError("NS:411");
            if (_auction[offerId_].endTime > block.timestamp)
                revert GeneralError("NS:412");
            if (
                _auction[offerId_].highestBidIdx == 0 &&
                _auction[offerId_].bids[0].canceled == false
            ) return;
        }
        uint256 offerId = offerId_;
        uint256 j = 0;
        (
            address[] memory recipientAddresses,
            uint256[] memory paymentAmount,
            bool isTransferable,
            bool isOwner
        ) = _marketplaceManager.calculatePayout(
                CalculatePayout(
                    _auction[offerId_].tokenId,
                    _auction[offerId_].tokenContract,
                    _auction[offerId_].seller,
                    _auction[offerId]
                        .bids[_auction[offerId_].highestBidIdx]
                        .price,
                    1
                )
            );
        if (!isTransferable) revert GeneralError("NS:123");
        if (!isOwner) revert GeneralError("NS:104");

        address[] memory recipientAddresses_ = new address[](
            (_auction[offerId].bids.length).add(recipientAddresses.length)
        );
        uint256[] memory paymentAmount_ = new uint256[](
            (_auction[offerId].bids.length).add(paymentAmount.length)
        );

        for (uint256 i = 0; i < recipientAddresses.length; i++) {
            recipientAddresses_[j] = recipientAddresses[i];
            if (i == recipientAddresses.length.sub(1))
                paymentAmount_[j] = paymentAmount[i].sub(
                    paymentAmount[i.sub(1)]
                );
            else paymentAmount_[j] = paymentAmount[i];
            j = j.add(1);
        }

        // refund
        {
            for (uint256 i = 0; i < _auction[offerId].bids.length; i++) {
                Bid storage bid = _auction[offerId].bids[i];
                if (i != _auction[offerId_].highestBidIdx && !bid.canceled) {
                    recipientAddresses_[j] = bid.bidder;
                    paymentAmount_[j] = bid.price;
                    j = j.add(1);
                    _auction[offerId].bids[i].canceled = true;
                }
            }
        }
        if (recipientAddresses_.length > 0) {
            {
                Auction memory auctionDetails = getAuctionDetails(offerId_);
                _marketplace.transferNFT(
                    auctionDetails.seller,
                    auctionDetails
                        .bids[_auction[offerId_].highestBidIdx]
                        .bidder,
                    auctionDetails.tokenId,
                    auctionDetails.tokenContract,
                    1
                );
            }
            CryptoTokens memory currencyDetails = _marketplaceManager
                .getTokenDetail(_defaultCurrency);

            _payout(
                Payout(
                    currencyDetails.tokenAddress,
                    recipientAddresses_,
                    paymentAmount_
                )
            );
        }
        _marketplace.endSale(offerId, NiftySouqIMarketplace.OfferState.ENDED);
        emit eEndAuction(
            offerId,
            _auction[offerId].highestBidIdx,
            msg.sender,
            address(0),
            _auction[offerId].bids[_auction[offerId].highestBidIdx].price
        );
    }

    /**
     *@notice extend  duration of Auction
     *@param offerId_ offerId
     *@param duration_ duration of auction period.
     */
    function extendAuction(uint256 offerId_, uint256 duration_) external {
        NiftySouqIMarketplace.Offer memory offer = _marketplace.getOfferStatus(
            offerId_
        );
        if (offer.offerType != NiftySouqIMarketplace.OfferType.AUCTION)
            revert GeneralError("NS:121");
        if (offer.status != NiftySouqIMarketplace.OfferState.OPEN)
            revert GeneralError("NS:402");

        if (_auction[offerId_].endTime < block.timestamp)
            revert GeneralError("NS:401");

        if (
            _auction[offerId_].endTime.sub(_extendAuctionPeriod) >
            block.timestamp
        ) revert GeneralError("NS:408");

        if (
            _auction[offerId_].reservePrice <
            _auction[offerId_].bids[_auction[offerId_].highestBidIdx].price
        ) revert GeneralError("NS:409");
        _auction[offerId_].endTime = _auction[offerId_].endTime.add(duration_);
    }

    /**
     *@notice place bid function for lazy mint token.
     *@param lazyMintAuctionData_ contains seller address,token address,uri,creators address,investors address ,royalties percentage,revenue percentage.
     *@param bidPrice_ bid price for auction.
     *@return offerId_ offerId
     *@return tokenId_ tokenId
     *@return bidIdx_  identifies the bid using index in the auction.
     */

    function lazyMintAuctionNPlaceBid(
        LazyMintAuctionData calldata lazyMintAuctionData_,
        uint256 bidPrice_
    )
        external
        whenNotPaused
        returns (
            uint256 offerId_,
            uint256 tokenId_,
            uint256 bidIdx_
        )
    {
        address signer = _marketplaceManager.verifyAuctionLazyMint(
            lazyMintAuctionData_
        );
        if (blockList[msg.sender]) revert GeneralError("NS:126");
        if (lazyMintAuctionData_.seller != signer)
            revert GeneralError("NS:410");
        (ContractType contractType_, bool isERC1155_) = _marketplaceManager
            .getContractDetails(lazyMintAuctionData_.tokenAddress);

        if (isERC1155_) revert GeneralError("NS:403");
        if (
            (contractType_ != ContractType.NIFTY_V2 &&
                contractType_ != ContractType.COLLECTOR)
        ) revert GeneralError("NS:122");
        //mint nft

        uint256 tokenId = _marketplace.mintNft(
            NiftySouqIMarketplace.MintData(
                lazyMintAuctionData_.seller,
                lazyMintAuctionData_.tokenAddress,
                lazyMintAuctionData_.uri,
                lazyMintAuctionData_.creators,
                lazyMintAuctionData_.royalties,
                lazyMintAuctionData_.investors,
                lazyMintAuctionData_.revenues,
                1
            )
        );
        tokenId_ = tokenId;
        //create auction
        offerId_ = _marketplace.createSale(
            tokenId_,
            NiftySouqIMarketplace.ContractType(uint256(contractType_)),
            NiftySouqIMarketplace.OfferType.AUCTION
        );

        CreateAuction memory auctionData = CreateAuction(
            offerId_,
            tokenId_,
            lazyMintAuctionData_.tokenAddress,
            lazyMintAuctionData_.startTime,
            lazyMintAuctionData_.duration,
            lazyMintAuctionData_.seller,
            lazyMintAuctionData_.startBidPrice,
            lazyMintAuctionData_.reservePrice
        );
        _createAuction(auctionData);

        //place bid
        bidIdx_ = placeBid(offerId_, bidPrice_);
    }

    /**
     *@notice enables to Place Bid
     *@param offerId_ offer Id
     *@param bidPrice_  bid price for auction .
     *@return bidIdx_ identifies the bid using index in the auction.
     */
    function placeBid(uint256 offerId_, uint256 bidPrice_)
        public
        whenNotPaused
        returns (uint256 bidIdx_)
    {
        NiftySouqIMarketplace.Offer memory offer = _marketplace.getOfferStatus(
            offerId_
        );
        if (blockList[msg.sender]) revert GeneralError("NS:126");
        if (offer.offerType != NiftySouqIMarketplace.OfferType.AUCTION)
            revert GeneralError("NS:121");
        if (offer.status != NiftySouqIMarketplace.OfferState.OPEN)
            revert GeneralError("NS:402");
        CryptoTokens memory currencyDetails = _marketplaceManager
            .getTokenDetail(_defaultCurrency);

        IERC20Upgradeable(currencyDetails.tokenAddress).safeTransferFrom(
            msg.sender,
            address(this),
            bidPrice_
        );

        bidIdx_ = _placeBid(offerId_, msg.sender, bidPrice_);
        emit ePlaceBid(offerId_, bidIdx_, msg.sender, bidPrice_);
    }

    /**
     *@notice Place Higher Bid for auction
     *@param offerId_ offer id
     *@param bidIdx_ identifies the bid using index in the auction.
     *@param bidPrice_ bid price
     */
    function placeHigherBid(
        uint256 offerId_,
        uint256 bidIdx_,
        uint256 bidPrice_
    ) external whenNotPaused {
        NiftySouqIMarketplace.Offer memory offer = _marketplace.getOfferStatus(
            offerId_
        );
        if (blockList[msg.sender]) revert GeneralError("NS:126");
        if (offer.offerType != NiftySouqIMarketplace.OfferType.AUCTION)
            revert GeneralError("NS:121");
        if (offer.status != NiftySouqIMarketplace.OfferState.OPEN)
            revert GeneralError("NS:402");
        CryptoTokens memory currencyDetails = _marketplaceManager
            .getTokenDetail(_defaultCurrency);

        IERC20Upgradeable(currencyDetails.tokenAddress).safeTransferFrom(
            msg.sender,
            address(this),
            bidPrice_
        );

        uint256 currentBidAmount = _placeHigherBid(
            offerId_,
            msg.sender,
            bidIdx_,
            bidPrice_
        );
        emit ePlaceHigherBid(offerId_, bidIdx_, msg.sender, currentBidAmount);
    }

    /**
     *@notice Cancel Bid
     *@param offerId_ offerId
     *@param bidIdx_ bid
     */
    function cancelBid(uint256 offerId_, uint256 bidIdx_) external {
        NiftySouqIMarketplace.Offer memory offer = _marketplace.getOfferStatus(
            offerId_
        );
        if (offer.offerType != NiftySouqIMarketplace.OfferType.AUCTION)
            revert GeneralError("NS:121");
        if (offer.status != NiftySouqIMarketplace.OfferState.OPEN)
            revert GeneralError("NS:402");
        (
            address[] memory refundAddresses,
            uint256[] memory refundAmount
        ) = _cancelBid(offerId_, msg.sender, bidIdx_);
        CryptoTokens memory currencyDetails = _marketplaceManager
            .getTokenDetail(_defaultCurrency);

        _payout(
            Payout(currencyDetails.tokenAddress, refundAddresses, refundAmount)
        );
        emit eCancelBid(offerId_, bidIdx_);
    }

    //*********************** Internal Functions ***********************//

    function _createAuction(CreateAuction memory createAuctionData_) internal {
        _auction[createAuctionData_.offerId].tokenId = createAuctionData_
            .tokenId;
        _auction[createAuctionData_.offerId].tokenContract = createAuctionData_
            .tokenContract;
        _auction[createAuctionData_.offerId].startTime = createAuctionData_
            .startTime;
        _auction[createAuctionData_.offerId].endTime = createAuctionData_
            .startTime
            .add(createAuctionData_.duration);
        _auction[createAuctionData_.offerId].seller = createAuctionData_.seller;
        _auction[createAuctionData_.offerId].startBidPrice = createAuctionData_
            .startBidPrice;
        _auction[createAuctionData_.offerId].reservePrice = createAuctionData_
            .reservePrice;
    }

    function _cancelAuction(uint256 offerId_)
        internal
        returns (
            address[] memory refundAddresses_,
            uint256[] memory refundAmount_
        )
    {
        refundAddresses_ = new address[](_auction[offerId_].bids.length);
        refundAmount_ = new uint256[](_auction[offerId_].bids.length);
        uint256 j = 0;
        for (uint256 i = 0; i < _auction[offerId_].bids.length; i++) {
            Bid storage bid = _auction[offerId_].bids[i];
            if (!bid.canceled) {
                refundAddresses_[j] = bid.bidder;
                refundAmount_[j] = bid.price;
                j = j.add(1);
                _auction[offerId_].bids[i].canceled = true;
            }
        }
    }

    function _placeBid(
        uint256 offerId_,
        address bidder_,
        uint256 bidPrice_
    ) internal returns (uint256 bidIdx_) {
        if (_auction[offerId_].seller == bidder_) revert GeneralError("NS:413");
        if (_auction[offerId_].endTime < block.timestamp)
            revert GeneralError("NS:401");
        uint256 highestBidPrice = _auction[offerId_].startBidPrice;

        if (_auction[offerId_].bids.length > 0) {
            Bid storage highestBid = _auction[offerId_].bids[
                _auction[offerId_].highestBidIdx
            ];
            if (highestBid.bidder == bidder_) revert GeneralError("NS:414");

            highestBidPrice = _percent(
                highestBid.price,
                (PERCENT_UNIT + _bidIncreasePercentage)
            );
        }

        if (bidPrice_ < highestBidPrice) revert GeneralError("NS:415");

        _auction[offerId_].bids.push(
            Bid({
                bidder: bidder_,
                price: bidPrice_,
                bidAt: block.timestamp,
                canceled: false
            })
        );

        _auction[offerId_].highestBidIdx = _auction[offerId_].bids.length - 1;
        bidIdx_ = _auction[offerId_].highestBidIdx;
    }

    function _placeHigherBid(
        uint256 offerId_,
        address bidder_,
        uint256 bidIdx_,
        uint256 bidPrice_
    ) internal returns (uint256 currentBidPrice_) {
        if (bidIdx_ > _auction[offerId_].bids.length)
            revert GeneralError("NS:416");
        if (bidder_ != _auction[offerId_].bids[bidIdx_].bidder)
            revert GeneralError("NS:417");
        if (_auction[offerId_].endTime < block.timestamp)
            revert GeneralError("NS:401");

        Bid storage bid = _auction[offerId_].bids[bidIdx_];
        Bid storage highestBid = _auction[offerId_].bids[
            _auction[offerId_].highestBidIdx
        ];

        uint256 requiredMinBidPrice = _percent(
            highestBid.price,
            (PERCENT_UNIT + _bidIncreasePercentage)
        );

        if (bidPrice_.add(bid.price) < requiredMinBidPrice)
            revert GeneralError("NS:415");

        _auction[offerId_].bids[bidIdx_].price = bidPrice_.add(bid.price);

        _auction[offerId_].highestBidIdx = bidIdx_;
        currentBidPrice_ = _auction[offerId_].bids[bidIdx_].price;
    }

    function _cancelBid(
        uint256 offerId_,
        address bidder_,
        uint256 bidIdx_
    )
        internal
        returns (
            address[] memory refundAddresses_,
            uint256[] memory refundAmount_
        )
    {
        if (bidIdx_ > _auction[offerId_].bids.length)
            revert GeneralError("NS:416");
        if (bidder_ != _auction[offerId_].bids[bidIdx_].bidder)
            revert GeneralError("NS:417");
        refundAddresses_ = new address[](1);
        refundAmount_ = new uint256[](1);
        _auction[offerId_].bids[bidIdx_].canceled = true;
        refundAddresses_[0] = _auction[offerId_].bids[bidIdx_].bidder;
        refundAmount_[0] = _auction[offerId_].bids[bidIdx_].price;

        // update highest bidder
        if (_auction[offerId_].highestBidIdx == bidIdx_) {
            uint256 idx = 0;
            for (uint256 i = 0; i < _auction[offerId_].bids.length; i++) {
                if (
                    !_auction[offerId_].bids[i].canceled &&
                    _auction[offerId_].bids[i].price >
                    _auction[offerId_].bids[uint256(idx)].price
                ) {
                    idx = i;
                }
            }
            _auction[offerId_].highestBidIdx = idx;
        }
    }

    function _calculatePayout(
        uint256 price_,
        uint256 serviceFeePercent_,
        uint256[] memory payouts_
    )
        internal
        view
        virtual
        returns (
            uint256 serviceFee_,
            uint256[] memory payoutFees_,
            uint256 netFee_
        )
    {
        payoutFees_ = new uint256[](payouts_.length);
        uint256 payoutSum = 0;
        serviceFee_ = _percent(price_, serviceFeePercent_);

        for (uint256 i = 0; i < payouts_.length; i++) {
            uint256 royalFee = _percent(price_, payouts_[i]);
            payoutFees_[i] = royalFee;
            payoutSum = payoutSum.add(royalFee);
        }

        netFee_ = price_.sub(serviceFee_).sub(payoutSum);
    }

    function _percent(uint256 value_, uint256 percentage_)
        internal
        pure
        returns (uint256)
    {
        uint256 result = value_.mul(percentage_).div(PERCENT_UNIT);
        return (result);
    }

    function _payout(Payout memory payoutData_) private {
        for (uint256 i = 0; i < payoutData_.refundAddresses.length; i++) {
            if (payoutData_.refundAddresses[i] != address(0)) {
                if (address(0) == payoutData_.currency) {
                    payable(payoutData_.refundAddresses[i]).transfer(
                        payoutData_.refundAmounts[i]
                    );
                } else {
                    IERC20Upgradeable(payoutData_.currency).safeTransfer(
                        payoutData_.refundAddresses[i],
                        payoutData_.refundAmounts[i]
                    );
                }
                emit ePayoutTransfer(
                    payoutData_.refundAddresses[i],
                    payoutData_.refundAmounts[i],
                    payoutData_.currency
                );
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface NiftySouqIMarketplace {
    enum ContractType {
        NIFTY_V1,
        NIFTY_V2,
        COLLECTOR,
        EXTERNAL,
        UNSUPPORTED
    }

    enum OfferState {
        OPEN,
        CANCELLED,
        ENDED
    }

    enum OfferType {
        SALE,
        AUCTION
    }

    struct Offer {
        uint256 tokenId;
        OfferType offerType;
        OfferState status;
        ContractType contractType;
    }

    struct MintData {
        address minter;
        address tokenAddress;
        string uri;
        address[] creators;
        uint256[] royalties;
        address[] investors;
        uint256[] revenues;
        uint256 quantity;
    }

    struct Payout {
        address currency;
        address[] refundAddresses;
        uint256[] refundAmounts;
    }

    function mintNft(MintData memory mintData_)
        external
        returns (uint256 tokenId_);

    function createSale(
        uint256 tokenId_,
        ContractType contractType_,
        OfferType offerType_
    ) external returns (uint256 offerId_);

    function endSale(uint256 offerId_, OfferState offerState_) external;

    function transferNFT(
        address from_,
        address to_,
        uint256 tokenId_,
        address tokenAddress_,
        uint256 quantity_
    ) external;

    function getOfferStatus(uint256 offerId_)
        external
        view
        returns (Offer memory offerDetails_);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

enum ContractType {
    NIFTY_V1,
    NIFTY_V2,
    COLLECTOR,
    EXTERNAL,
    UNSUPPORTED
}
struct CalculatePayout {
    uint256 tokenId;
    address contractAddress;
    address seller;
    uint256 price;
    uint256 quantity;
}

struct LazyMintSellData {
    address tokenAddress;
    string uri;
    address seller;
    address[] creators;
    uint256[] royalties;
    address[] investors;
    uint256[] revenues;
    uint256 minPrice;
    uint256 quantity;
    bytes signature;
    string currency;
}

struct LazyMintAuctionData {
    address tokenAddress;
    string uri;
    address seller;
    address[] creators;
    uint256[] royalties;
    address[] investors;
    uint256[] revenues;
    uint256 startTime;
    uint256 duration;
    uint256 startBidPrice;
    uint256 reservePrice;
    bytes signature;
}

struct CryptoTokens {
    address tokenAddress;
    uint256 tokenValue;
    bool isEnabled;
}

interface NiftySouqIMarketplaceManager {
    function isAdmin(address caller_) external view returns (bool);

    function isPauser(address caller_) external view returns (bool);

    function serviceFeeWallet() external view returns (address);

    function serviceFeePercent() external view returns (uint256);

    function getTokenDetail(string memory tokenName_)
        external
        view
        returns (CryptoTokens memory cryptoToken_);

    function tokenExist(string memory tokenName_)
        external
        view
        returns (bool tokenExist_);

    function verifyFixedPriceLazyMintV1(LazyMintSellData calldata lazyData_)
        external
        returns (address);

    function verifyFixedPriceLazyMintV2(LazyMintSellData calldata lazyData_)
        external
        returns (address);

    function verifyAuctionLazyMint(LazyMintAuctionData calldata lazyData_)
        external
        returns (address);

    function getContractDetails(address contractAddress_)
        external
        returns (ContractType contractType_, bool isERC1155_);

    function isOwnerOfNFT(
        address address_,
        uint256 tokenId_,
        address contractAddress_
    )
        external
        returns (
            ContractType contractType_,
            bool isERC1155_,
            bool isOwner_,
            uint256 quantity_
        );

    function calculatePayout(CalculatePayout memory calculatePayout_)
        external
        returns (
            address[] memory recepientAddresses_,
            uint256[] memory paymentAmount_,
            bool isTokenTransferable_,
            bool isOwner_
        );
}