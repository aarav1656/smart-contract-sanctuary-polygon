// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (access/AccessControl.sol)

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
                        StringsUpgradeable.toHexString(account),
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
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/Initializable.sol)

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
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
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
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
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
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initialized`
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initializing`
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

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
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/MathUpgradeable.sol";

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = MathUpgradeable.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, MathUpgradeable.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUpgradeable {
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
pragma solidity 0.8.11;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "./interfaces/IAddressRegistry.sol";
import "./interfaces/IOparcade.sol";

/**
 * @title GameRegistry
 * @notice This contract stores all info related to the game and tournament creation
 * @author David Lee
 */
contract GameRegistry is AccessControlUpgradeable {
  using SafeERC20Upgradeable for IERC20Upgradeable;

  bytes32 public constant GAME_MANAGER_ROLE = keccak256("GAME_MANAGER_ROLE");
  bytes32 public constant TOURNAMENT_MANAGER_ROLE = keccak256("TOURNAMENT_MANAGER_ROLE");

  event GameAdded(
    address indexed by,
    uint256 indexed gid,
    string gameName,
    address indexed gameCreator,
    uint256 baseGameCreatorFee
  );
  event GameRemoved(
    address indexed by,
    uint256 indexed gid,
    string gameName,
    address indexed gameCreator,
    uint256 baseGameCreatorFee
  );
  event GameCreatorUpdated(
    address indexed by,
    uint256 indexed gid,
    address indexed oldGameCreator,
    address newGameCreator
  );
  event BaseGameCreatorFeeUpdated(
    address indexed by,
    uint256 indexed gid,
    uint256 indexed oldBaseGameCreatorFee,
    uint256 newBaseGameCreatorFee
  );
  event TournamentCreated(
    address indexed by,
    uint256 indexed gid,
    uint256 indexed tid,
    string tournamentName,
    uint256 appliedGameCreatorFee,
    uint256 tournamentCreatorFee
  );
  event DepositAmountUpdated(
    address indexed by,
    uint256 indexed gid,
    uint256 indexed tid,
    string tournamentName,
    address token,
    uint256 oldAmount,
    uint256 newAmount
  );
  event DistributableTokenAddressUpdated(
    address indexed by,
    uint256 indexed gid,
    address indexed token,
    bool oldStatus,
    bool newStatus
  );
  event PlatformFeeUpdated(
    address indexed by,
    address indexed oldFeeRecipient,
    uint256 oldPlatformFee,
    address indexed newFeeRecipient,
    uint256 newPlatformFee
  );
  event TournamentCreationFeeTokenUpdated(
    address indexed by,
    address indexed oldTournamentCreationFeeToken,
    address indexed newTournamentCreationFeeToken
  );
  event FreeTournamentCreationFeeAmountUpdated(
    address indexed by,
    uint256 oldFreeTournamentCreationFeeAmount,
    uint256 newFreeTournamentCreationFeeAmount
  );
  event PaidTournamentCreationFeeAmountUpdated(
    address indexed by,
    uint256 oldPaidTournamentCreationFeeAmount,
    uint256 newPaidTournamentCreationFeeAmount
  );

  struct Token {
    address tokenAddress;
    uint256 tokenAmount;
  }

  struct Tournament {
    string name;
    address creatorAddress;
    uint256 creatorFee;
    uint256 appliedGameCreatorFee;
    /// @dev Token address -> amount
    mapping(address => uint256) depositTokenAmount;
  }

  struct Game {
    string name;
    address creatorAddress;
    uint256 baseCreatorFee;
    bool isDeprecated;
    address[] distributableTokenList; // return all array
    address[] depositTokenList;
    mapping(uint256 => Tournament) tournaments;
    uint256 tournamentsCount;
    /// @dev Token address -> Bool
    mapping(address => bool) distributable;
  }

  /// @dev Game name array
  Game[] public games;

  /// @dev AddressRegistry
  IAddressRegistry public addressRegistry;

  /// @dev Platform fee recipient
  address public feeRecipient;

  /// @dev Platform fee
  uint256 public platformFee;

  /// @dev Tournament creation fee token address
  address public tournamentCreationFeeToken;

  /// @dev Free Tournament creation fee token amount
  uint256 public freeTournamentCreationFeeAmount;

  /// @dev Paid Tournament creation fee token amount
  uint256 public paidTournamentCreationFeeAmount;

  /// @dev Max fee constant in permillage (percentage * 10)
  uint256 private constant MAX_PERMILLAGE = 100_0;

  modifier onlyValidGID(uint256 _gid) {
    require(_gid < games.length, "Invalid game index");
    _;
  }

  modifier onlyActiveGame(uint256 _gid) {
    require(_gid < games.length && !games[_gid].isDeprecated, "Game not active");
    _;
  }

  modifier onlyValidTID(uint256 _gid, uint256 _tid) {
    require(_tid < games[_gid].tournamentsCount, "Invalid tournament index");
    _;
  }

  modifier onlyGameManager() {
    require(
      hasRole(GAME_MANAGER_ROLE, _msgSender()) || hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
      "Game manager role missing"
    );
    _;
  }

  modifier onlyTournamentManager() {
    require(
      hasRole(TOURNAMENT_MANAGER_ROLE, _msgSender()) || hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
      "Tournament manager role missing"
    );
    _;
  }

  modifier onlyAdmin() {
    require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Admin role missing");
    _;
  }

  function initialize(
    address _addressRegistry,
    address _feeRecipient,
    uint256 _platformFee,
    address _tournamentCreationFeeToken,
    uint256 _freeTournamentCreationFeeAmount,
    uint256 _paidTournamentCreationFeeAmount
  ) public initializer {
    __AccessControl_init();

    _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
    _grantRole(GAME_MANAGER_ROLE, _msgSender());
    _grantRole(TOURNAMENT_MANAGER_ROLE, _msgSender());

    require(_addressRegistry != address(0), "Zero address registry");
    require(_tournamentCreationFeeToken != address(0), "Zero tournament fee token");
    require(_feeRecipient != address(0) || _platformFee == 0, "Fee recipient not set");
    require(_platformFee <= MAX_PERMILLAGE, "Platform fee exceeded");

    // initialize AddressRegistery
    addressRegistry = IAddressRegistry(_addressRegistry);

    // initialize fee and recipient
    feeRecipient = _feeRecipient;
    platformFee = _platformFee;
    tournamentCreationFeeToken = _tournamentCreationFeeToken;
    freeTournamentCreationFeeAmount = _freeTournamentCreationFeeAmount;
    paidTournamentCreationFeeAmount = _paidTournamentCreationFeeAmount;
  }

  /**
   * @notice Returns a boolean indicating if a specific game is deprecated
   * @param _gid Game ID
   * @return (bool) Is deprecated
   */
  function isGameDeprecated(uint256 _gid) external view onlyValidGID(_gid) returns (bool) {
    return games[_gid].isDeprecated;
  }

  /**
   * @notice Returns the game name
   * @param _gid Game ID
   * @return (string) Game name
   */
  function getGameName(uint256 _gid) external view onlyValidGID(_gid) returns (string memory) {
    return games[_gid].name;
  }

  /**
   * @notice Returns the game creator address
   * @param _gid Game ID
   * @return (string) Game creator address
   */
  function getGameCreatorAddress(uint256 _gid) external view onlyValidGID(_gid) returns (address) {
    return games[_gid].creatorAddress;
  }

  /**
   * @notice Returns the game creator fee
   * @param _gid Game ID
   * @return (uint256) Game creator fee
   */
  function getGameBaseCreatorFee(uint256 _gid) external view onlyValidGID(_gid) returns (uint256) {
    return games[_gid].baseCreatorFee;
  }

  /**
   * @notice Returns true if the token of a specific game is distributable, false otherwise
   * @param _gid Game ID
   * @param _tokenAddress token address
   * @return (uint256) Is token distributable
   */
  function isDistributable(uint256 _gid, address _tokenAddress) external view onlyValidGID(_gid) returns (bool) {
    return games[_gid].distributable[_tokenAddress];
  }

  /**
   * @notice Returns the deposit token list of the game
   * @param _gid Game ID
   * @param (address[]) Deposit token list of the game
   */
  function getDepositTokenList(uint256 _gid) external view returns (address[] memory) {
    return games[_gid].depositTokenList;
  }

  /**
   * @notice Returns the distributable token list of the game
   * @param _gid Game ID
   * @param (address[]) Distributable token list of the game
   */
  function getDistributableTokenList(uint256 _gid) external view returns (address[] memory) {
    return games[_gid].distributableTokenList;
  }

  /**
   * @notice Returns the number of games created
   * @return (uint256) Amount of games created
   */
  function gameCount() external view returns (uint256) {
    return games.length;
  }

  /**
   * @notice Returns the number of the tournaments of the specific game
   * @param _gid Game ID
   * @return (uint256) Number of the tournament
   */
  function getTournamentCount(uint256 _gid) external view onlyValidGID(_gid) returns (uint256) {
    return games[_gid].tournamentsCount;
  }

  /**
   * @notice Returns the tournament name of the specific tournament
   * @param _gid Game ID
   * @param _tid Tournament ID
   * @return (string) Tournament name
   */
  function getTournamentName(
    uint256 _gid,
    uint256 _tid
  ) external view onlyValidGID(_gid) onlyValidTID(_gid, _tid) returns (string memory) {
    return games[_gid].tournaments[_tid].name;
  }

  /**
   * @notice Returns the tournament creator fee of the specific tournament
   * @param _gid Game ID
   * @param _tid Tournament ID
   * @return (uint256) Tournament creator fee
   */
  function getTournamentCreatorFee(
    uint256 _gid,
    uint256 _tid
  ) external view onlyValidGID(_gid) onlyValidTID(_gid, _tid) returns (uint256) {
    return games[_gid].tournaments[_tid].creatorFee;
  }

  /**
   * @notice Returns the applied game creator fee of the specific tournament
   * @param _gid Game ID
   * @param _tid Tournament ID
   * @return (string) Game applied game creator fee of a tournament
   */
  function getAppliedGameCreatorFee(
    uint256 _gid,
    uint256 _tid
  ) external view onlyValidGID(_gid) onlyValidTID(_gid, _tid) returns (uint256) {
    return games[_gid].tournaments[_tid].appliedGameCreatorFee;
  }

  /**
   * @notice Returns the deposit token amount of the specific tournament
   * @param _gid Game ID
   * @param _tid Tournament ID
   * @param _tokenAddress token address
   * @return (uint256) Tournament deposit token amount
   */
  function getDepositTokenAmount(
    uint256 _gid,
    uint256 _tid,
    address _tokenAddress
  ) external view onlyValidGID(_gid) onlyValidTID(_gid, _tid) returns (uint256) {
    return games[_gid].tournaments[_tid].depositTokenAmount[_tokenAddress];
  }

  /**
   * @notice Returns the tournament creator address of the specific tournament
   * @param _gid Game ID
   * @param _tid Tournament ID
   * @return (address) Tournament creator address
   */
  function getTournamentCreator(
    uint256 _gid,
    uint256 _tid
  ) external view onlyValidGID(_gid) onlyValidTID(_gid, _tid) returns (address) {
    return games[_gid].tournaments[_tid].creatorAddress;
  }

  /**
   * @notice Add the new game
   * @dev Base game creator fee is the minimum fee vaule that the game creator should be rewarded from the tournamnet of the game
   * @dev When creating the tournament of the game, the game creator fee can be proposed by the tournament creator
   * @dev but the proposed value can't be less than the base one
   * @dev If the proposed game creator fee is 0, the base game creator fee will be applied
   * @param _gameName Game name to add
   * @param _gameCreator Game creator address
   * @param _baseGameCreatorFee Base game creator fee
   */
  function addGame(
    string calldata _gameName,
    address _gameCreator,
    uint256 _baseGameCreatorFee
  ) external onlyGameManager returns (uint256 gid) {
    require(bytes(_gameName).length != 0, "Empty game name");
    require(_gameCreator != address(0), "Zero game creator address");
    require(platformFee + _baseGameCreatorFee <= MAX_PERMILLAGE, "Exceeded base game creator fee");

    // Create game and set properties
    gid = games.length;
    games.push();
    games[gid].name = _gameName;
    games[gid].creatorAddress = _gameCreator;
    games[gid].baseCreatorFee = _baseGameCreatorFee;

    emit GameAdded(msg.sender, gid, _gameName, _gameCreator, _baseGameCreatorFee);
  }

  /**
   * @notice Remove the exising game
   * @dev Game is not removed from the games array, just set it deprecated
   * @param _gid Game ID
   */
  function removeGame(uint256 _gid) external onlyGameManager onlyActiveGame(_gid) {
    // remove game
    games[_gid].isDeprecated = true;

    emit GameRemoved(msg.sender, _gid, games[_gid].name, games[_gid].creatorAddress, games[_gid].baseCreatorFee);
  }

  /**
   * @notice Update the game creator
   * @param _gid Game ID
   * @param _gameCreator Game creator address
   */
  function updateGameCreator(uint256 _gid, address _gameCreator) external onlyActiveGame(_gid) {
    require(msg.sender == games[_gid].creatorAddress, "Only game creator");
    require(_gameCreator != address(0), "Zero game creator address");

    emit GameCreatorUpdated(msg.sender, _gid, games[_gid].creatorAddress, _gameCreator);

    // update the game creator address
    games[_gid].creatorAddress = _gameCreator;
  }

  /**
   * @notice Update the base game creator fee
   * @dev Tournament creator fee is the royality that will be transferred to the tournament creator address
   * @dev Tournament creator can propose the game creator fee when creating the tournament
   * @dev but it can't be less than the base game creator fee
   * @param _gid Game ID
   * @param _baseGameCreatorFee Base game creator fee
   */
  function updateBaseGameCreatorFee(
    uint256 _gid,
    uint256 _baseGameCreatorFee
  ) external onlyGameManager onlyActiveGame(_gid) {
    require(platformFee + _baseGameCreatorFee <= MAX_PERMILLAGE, "Exceeded game creator fee");

    emit BaseGameCreatorFeeUpdated(msg.sender, _gid, games[_gid].baseCreatorFee, _baseGameCreatorFee);

    // update the game creator fee
    games[_gid].baseCreatorFee = _baseGameCreatorFee;
  }

  /**
   * @notice Create the tournament and set tokens
   * @dev Only owner
   * @dev If the proposed game creaetor fee is 0, the base game creator fee is applied
   * @dev The prize pool for the tournament that the owner created is initialized on Oparcade contract
   * @param _gid Game ID
   * @param _proposedGameCreatorFee Proposed game creator fee
   * @param _tournamentCreatorFee Tournament creator fee
   * @param _depositToken Token to allow/disallow the deposit
   * @param _distributionTokenAddress Distribution token address to be set to active
   * @return tid Tournament ID created
   */
  function createTournamentByDAOWithTokens(
    uint256 _gid,
    string memory _tournamentName,
    uint256 _proposedGameCreatorFee,
    uint256 _tournamentCreatorFee,
    Token calldata _depositToken,
    address _distributionTokenAddress
  ) external onlyTournamentManager onlyActiveGame(_gid) returns (uint256 tid) {
    // create the tournament
    tid = _createTournament(_gid, _tournamentName, _proposedGameCreatorFee, _tournamentCreatorFee);

    // set the deposit token address and amount
    _updateDepositTokenAmount(_gid, tid, _depositToken.tokenAddress, _depositToken.tokenAmount);

    // set the distributable token address
    if (!games[_gid].distributable[_distributionTokenAddress]) {
      _updateDistributableTokenAddress(_gid, _distributionTokenAddress, true);
    }

    return tid;
  }

  /**
   * @notice Create the tournament
   * @dev Only owner
   * @dev If the proposed game creaetor fee is 0, the base game creator fee is applied
   * @dev The prize pool for the tournament that the owner created is initialized on Oparcade contract
   * @param _gid Game ID
   * @param _proposedGameCreatorFee Proposed game creator fee
   * @param _tournamentCreatorFee Tournament creator fee
   * @return tid Tournament ID created
   */
  function createTournamentByDAO(
    uint256 _gid,
    string calldata _tournamentName,
    uint256 _proposedGameCreatorFee,
    uint256 _tournamentCreatorFee
  ) external onlyTournamentManager onlyActiveGame(_gid) returns (uint256 tid) {
    tid = _createTournament(_gid, _tournamentName, _proposedGameCreatorFee, _tournamentCreatorFee);
  }

  /**
   * @notice Create the tournament
   * @dev If the proposed game creaetor fee is 0, the base game creator fee is applied
   * @param _gid Game ID
   * @param _proposedGameCreatorFee Proposed game creator fee
   * @param _tournamentCreatorFee Tournament creator fee
   * @return tid Tournament ID created
   */
  function _createTournament(
    uint256 _gid,
    string memory _tournamentName,
    uint256 _proposedGameCreatorFee,
    uint256 _tournamentCreatorFee
  ) internal returns (uint256 tid) {
    // use baseCreatorFee if _proposedGameCreatorFee is zero
    uint256 appliedGameCreatorFee;
    if (_proposedGameCreatorFee == 0) {
      appliedGameCreatorFee = games[_gid].baseCreatorFee;
    } else {
      appliedGameCreatorFee = _proposedGameCreatorFee;
    }

    // check fees
    require(games[_gid].baseCreatorFee <= appliedGameCreatorFee, "Low game creator fee proposed");
    require(platformFee + appliedGameCreatorFee + _tournamentCreatorFee <= MAX_PERMILLAGE, "Exceeded fees");

    // get the new tournament ID
    tid = games[_gid].tournamentsCount;

    // add tournament
    games[_gid].tournamentsCount += 1;
    games[_gid].tournaments[tid].name = _tournamentName;
    games[_gid].tournaments[tid].creatorAddress = msg.sender;
    games[_gid].tournaments[tid].appliedGameCreatorFee = appliedGameCreatorFee;
    games[_gid].tournaments[tid].creatorFee = _tournamentCreatorFee;

    emit TournamentCreated(msg.sender, _gid, tid, _tournamentName, appliedGameCreatorFee, _tournamentCreatorFee);
  }

  /**
   * @notice Create the tournament
   * @dev Anyone can create the tournament and initialize the prize pool with tokens and NFTs
   * @dev Tournament creator should set all params necessary for the tournament in 1 tx and
   * @dev the params set is immutable. It will be prevent the fraud tournament is created
   * @dev Tournament creator should pay fees to create the tournament
   * @dev and the fee token address and fee token amount are set by the owner
   * @dev If the proposed game creaetor fee is 0, the base game creator fee is applied
   * @dev NFT type to initialize the prize pool should be either 721 or 1155
   * @param _gid Game ID
   * @param _proposedGameCreatorFee Proposed game creator fee
   * @param _tournamentCreatorFee Tournament creator fee
   * @param _depositToken Deposit token (address and amount) for playing the tournament
   * @param _tokenToAddPrizePool Token (address and amount) to initialize the prize pool
   * @param _nftAddressToAddPrizePool NFT address to initialize the prize pool
   * @param _nftTypeToAddPrizePool NFT type to initialize the prize pool
   * @param _tokenIdsToAddPrizePool NFT token Id list to initialize the prize pool
   * @param _amountsToAddPrizePool NFT token amount list to initialize the prize pool
   * @return tid Tournament ID created
   */
  function createTournamentByUser(
    uint256 _gid,
    string calldata _tournamentName,
    uint256 _proposedGameCreatorFee,
    uint256 _tournamentCreatorFee,
    Token calldata _depositToken,
    Token calldata _tokenToAddPrizePool,
    address _nftAddressToAddPrizePool,
    uint256 _nftTypeToAddPrizePool,
    uint256[] memory _tokenIdsToAddPrizePool,
    uint256[] memory _amountsToAddPrizePool
  ) external onlyActiveGame(_gid) returns (uint256 tid) {
    // pay the tournament creation fee
    IERC20Upgradeable(tournamentCreationFeeToken).safeTransferFrom(
      msg.sender,
      feeRecipient,
      _depositToken.tokenAmount == 0 ? freeTournamentCreationFeeAmount : paidTournamentCreationFeeAmount
    );

    // create new tournament
    tid = _createTournament(_gid, _tournamentName, _proposedGameCreatorFee, _tournamentCreatorFee);

    // set the deposit token amount
    _updateDepositTokenAmount(_gid, tid, _depositToken.tokenAddress, _depositToken.tokenAmount);

    // set the distributable token
    if (!games[_gid].distributable[_depositToken.tokenAddress]) {
      _updateDistributableTokenAddress(_gid, _depositToken.tokenAddress, true);
    }
    if (!games[_gid].distributable[_tokenToAddPrizePool.tokenAddress]) {
      _updateDistributableTokenAddress(_gid, _tokenToAddPrizePool.tokenAddress, true);
    }

    // initialize the prize pool with tokens
    if (_tokenToAddPrizePool.tokenAmount > 0) {
      IOparcade(addressRegistry.oparcade()).depositPrize(
        msg.sender,
        _gid,
        tid,
        _tokenToAddPrizePool.tokenAddress,
        _tokenToAddPrizePool.tokenAmount
      );
    }

    // initialize the prize pool with NFTs
    if (_nftTypeToAddPrizePool == 721 || _nftTypeToAddPrizePool == 1155) {
      // set the distributable token
      if (!games[_gid].distributable[_nftAddressToAddPrizePool] && _amountsToAddPrizePool.length > 0) {
        _updateDistributableTokenAddress(_gid, _nftAddressToAddPrizePool, true);
      }

      IOparcade(addressRegistry.oparcade()).depositNFTPrize(
        msg.sender,
        _gid,
        tid,
        _nftAddressToAddPrizePool,
        _nftTypeToAddPrizePool,
        _tokenIdsToAddPrizePool,
        _amountsToAddPrizePool
      );
    }
  }

  /**
   * @notice Update deposit token amount
   * @dev Only owner
   * @dev Only tokens with an amount greater than zero is valid for the deposit
   * @param _gid Game ID
   * @param _tid Tournament ID
   * @param _token Token address to allow/disallow the deposit
   * @param _amount Token amount
   */
  function updateDepositTokenAmount(
    uint256 _gid,
    uint256 _tid,
    address _token,
    uint256 _amount
  ) external onlyTournamentManager onlyActiveGame(_gid) onlyValidTID(_gid, _tid) {
    _updateDepositTokenAmount(_gid, _tid, _token, _amount);
  }

  /**
   * @notice Update deposit token amount
   * @dev Only tokens with an amount greater than zero is valid for the deposit
   * @param _gid Game ID
   * @param _tid Tournament ID
   * @param _token Token address to allow/disallow the deposit
   * @param _amount Token amount
   */
  function _updateDepositTokenAmount(uint256 _gid, uint256 _tid, address _token, uint256 _amount) internal {
    emit DepositAmountUpdated(
      msg.sender,
      _gid,
      _tid,
      games[_gid].tournaments[_tid].name,
      _token,
      games[_gid].tournaments[_tid].depositTokenAmount[_token],
      _amount
    );

    // update deposit token list
    if (_amount > 0) {
      if (games[_gid].tournaments[_tid].depositTokenAmount[_token] == 0) {
        // add the token into the list only if it's added newly
        games[_gid].depositTokenList.push(_token);
      }
    } else {
      for (uint256 i; i < games[_gid].depositTokenList.length; i++) {
        if (_token == games[_gid].depositTokenList[i]) {
          // remove the token from the list
          games[_gid].depositTokenList[i] = games[_gid].depositTokenList[games[_gid].depositTokenList.length - 1];
          games[_gid].depositTokenList.pop();
          break;
        }
      }
    }

    // update deposit token amount
    games[_gid].tournaments[_tid].depositTokenAmount[_token] = _amount;
  }

  /**
   * @notice Update distributable token address
   * @dev Only owner
   * @param _gid Game ID
   * @param _token Token address to allow/disallow the deposit
   * @param _isDistributable true: distributable false: not distributable
   */
  function updateDistributableTokenAddress(
    uint256 _gid,
    address _token,
    bool _isDistributable
  ) external onlyGameManager onlyActiveGame(_gid) {
    _updateDistributableTokenAddress(_gid, _token, _isDistributable);
  }

  /**
   * @notice Update distributable token address
   * @dev Only owner
   * @param _gid Game ID
   * @param _token Token address to allow/disallow the deposit
   * @param _isDistributable true: distributable false: not distributable
   */
  function _updateDistributableTokenAddress(uint256 _gid, address _token, bool _isDistributable) internal {
    emit DistributableTokenAddressUpdated(
      msg.sender,
      _gid,
      _token,
      games[_gid].distributable[_token],
      _isDistributable
    );

    // update distributable token list
    if (_isDistributable) {
      if (!games[_gid].distributable[_token]) {
        // add token to the list only if it's added newly
        games[_gid].distributableTokenList.push(_token);
      }
    } else {
      for (uint256 i; i < games[_gid].distributableTokenList.length; i++) {
        if (_token == games[_gid].distributableTokenList[i]) {
          games[_gid].distributableTokenList[i] = games[_gid].distributableTokenList[
            games[_gid].distributableTokenList.length - 1
          ];
          games[_gid].distributableTokenList.pop();
          break;
        }
      }
    }

    // update distributable token amount
    games[_gid].distributable[_token] = _isDistributable;
  }

  /**
   * @notice Update the platform fee
   * @dev Only owner
   * @dev Allow zero recipient address only of fee is also zero
   * @param _feeRecipient Platform fee recipient address
   * @param _platformFee platform fee
   */
  function updatePlatformFee(address _feeRecipient, uint256 _platformFee) external onlyAdmin {
    require(_feeRecipient != address(0) || _platformFee == 0, "Fee recipient not set");
    require(_platformFee <= MAX_PERMILLAGE, "Platform fee exceeded");

    emit PlatformFeeUpdated(msg.sender, feeRecipient, platformFee, _feeRecipient, _platformFee);

    feeRecipient = _feeRecipient;
    platformFee = _platformFee;
  }

  /**
   * @notice Update the tournament creation fee token
   * @dev Only owner
   * @dev Tournament creator should use this token to pay when creating the tournament
   * @param _tournamentCreationFeeToken Fee token address
   */
  function updateTournamentCreationFeeToken(address _tournamentCreationFeeToken) external onlyAdmin {
    require(_tournamentCreationFeeToken != address(0), "Zero tournament creation fee token");

    emit TournamentCreationFeeTokenUpdated(msg.sender, tournamentCreationFeeToken, _tournamentCreationFeeToken);

    tournamentCreationFeeToken = _tournamentCreationFeeToken;
  }

  /**
   * @notice Update the free tournament creation fee
   * @dev Only owner
   * @dev Tournament creator should pay this fee when creating the tournament
   * @param _freeTournamentCreationFeeAmount Fee token amount
   */
  function updateFreeTournamentCreationFeeAmount(uint256 _freeTournamentCreationFeeAmount) external onlyAdmin {
    emit FreeTournamentCreationFeeAmountUpdated(
      msg.sender,
      freeTournamentCreationFeeAmount,
      _freeTournamentCreationFeeAmount
    );

    freeTournamentCreationFeeAmount = _freeTournamentCreationFeeAmount;
  }

  /**
   * @notice Update the paid tournament creation fee
   * @dev Only owner
   * @dev Tournament creator should pay this fee when creating the tournament
   * @param _paidTournamentCreationFeeAmount Fee token amount
   */
  function updatePaidTournamentCreationFeeAmount(uint256 _paidTournamentCreationFeeAmount) external onlyAdmin {
    emit PaidTournamentCreationFeeAmountUpdated(
      msg.sender,
      paidTournamentCreationFeeAmount,
      _paidTournamentCreationFeeAmount
    );

    paidTournamentCreationFeeAmount = _paidTournamentCreationFeeAmount;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

/**
 * @title AddressRegistry Contract Interface
 * @notice Define the interface used to get addresses in Oparcade
 * @author David Lee
 */
interface IAddressRegistry {
  /**
   * @notice Provide the Oparcade contract address
   * @dev Can be zero in case of the Oparcade contract is not registered
   * @return address Oparcade contract address
   */
  function oparcade() external view returns (address);

  /**
   * @notice Provide the GameRegistry contract address
   * @dev Can be zero in case of the GameRegistry contract is not registered
   * @return address GameRegistry contract address
   */
  function gameRegistry() external view returns (address);

  /**
   * @notice Provide the maintainer address
   * @dev Can be zero in case of the maintainer address is not registered
   * @return address Maintainer contract address
   */
  function maintainer() external view returns (address);

  /**
   * @notice Provide the timelock contract address
   * @dev Can be zero in case of the timelock address is not registered
   * @return address Timelock contract address
   */
  function timelock() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

/**
 * @title Oparcade Contract Interface
 * @notice Define the interface used to get the token deposit and withdrawal info
 * @author David Lee
 */
interface IOparcade {
  /**
   * @notice Deposit ERC20 tokens from user
   * @dev Only tokens registered in GameRegistry with an amount greater than zero is valid for the deposit
   * @param _gid Game ID
   * @param _tid Tournament ID
   * @param _token Token address to deposit
   */
  function deposit(uint256 _gid, uint256 _tid, address _token) external;

  /**
   * @notice Deposit the prize tokens for the specific game/tournament
   * @dev Only tokens which are allowed as a distributable token can be deposited
   * @dev Prize is transferred from _depositor address to this contract
   * @param _depositor Depositor address
   * @param _gid Game ID
   * @param _tid Tournament ID
   * @param _token Prize token address
   * @param _amount Prize amount to deposit
   */
  function depositPrize(address _depositor, uint256 _gid, uint256 _tid, address _token, uint256 _amount) external;

  /**
   * @notice Deposit NFT prize for the specific game/tournament
   * @dev NFT type should be either 721 or 1155
   * @param _from NFT owner address
   * @param _gid Game ID
   * @param _tid Tournament ID
   * @param _nftAddress NFT address
   * @param _nftType NFT type (721/1155)
   * @param _tokenIds Token Id list
   * @param _amounts Token amount list
   */
  function depositNFTPrize(
    address _from,
    uint256 _gid,
    uint256 _tid,
    address _nftAddress,
    uint256 _nftType,
    uint256[] calldata _tokenIds,
    uint256[] calldata _amounts
  ) external;

  /**
   * @notice Distribute winners their prizes
   * @dev Only maintainer
   * @dev The maximum distributable prize amount is the sum of the users' deposit and the prize that the owner deposited
   * @param _gid Game ID
   * @param _tid Tournament ID
   * @param _winners Winners list
   * @param _token Prize token address
   * @param _amounts Prize list
   */
  function distributePrize(
    uint256 _gid,
    uint256 _tid,
    address[] calldata _winners,
    address _token,
    uint256[] calldata _amounts
  ) external;

  /**
   * @notice Distribute winners' NFT prizes
   * @dev Only maintainer
   * @dev NFT type should be either 721 or 1155
   * @param _gid Game ID
   * @param _tid Tournament ID
   * @param _winners Winners list
   * @param _nftAddress NFT address
   * @param _nftType NFT type (721/1155)
   * @param _tokenIds Token Id list
   * @param _amounts Token amount list
   */
  function distributeNFTPrize(
    uint256 _gid,
    uint256 _tid,
    address[] calldata _winners,
    address _nftAddress,
    uint256 _nftType,
    uint256[] calldata _tokenIds,
    uint256[] calldata _amounts
  ) external;

  /**
   * @notice Withdraw the prize tokens from the specific game/tournament
   * @dev Only owner
   * @param _to Beneficiary address
   * @param _gid Game ID
   * @param _tid Tournament ID
   * @param _token Prize token address
   * @param _amount Prize amount to withdraw
   */
  function withdrawPrize(address _to, uint256 _gid, uint256 _tid, address _token, uint256 _amount) external;

  /**
   * @notice Withdraw NFT prize for the specific game/tournament
   * @dev Only owner
   * @dev NFT type should be either 721 or 1155
   * @param _to NFT receiver address
   * @param _gid Game ID
   * @param _tid Tournament ID
   * @param _nftAddress NFT address
   * @param _nftType NFT type (721/1155)
   * @param _tokenIds Token Id list
   * @param _amounts Token amount list
   */
  function withdrawNFTPrize(
    address _to,
    uint256 _gid,
    uint256 _tid,
    address _nftAddress,
    uint256 _nftType,
    uint256[] calldata _tokenIds,
    uint256[] calldata _amounts
  ) external;

  /**
   * @notice Pause Oparcade
   * @dev Only owner
   */
  function pause() external;

  /**
   * @notice Resume Oparcade
   * @dev Only owner
   */
  function unpause() external;
}