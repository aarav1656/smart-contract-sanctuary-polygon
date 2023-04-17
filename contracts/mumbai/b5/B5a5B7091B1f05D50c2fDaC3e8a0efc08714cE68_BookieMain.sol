// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (access/AccessControl.sol)

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
                        Strings.toHexString(account),
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
// OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/Address.sol";

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
            (isTopLevelCall && _initialized < 1) || (!Address.isContract(address(this)) && _initialized == 1),
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
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
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
    constructor() {
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
        (bool success, bytes memory returndata) = target.delegatecall(data);
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV // Deprecated in v4.8
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
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
            return toHexString(value, Math.log256(value) + 1);
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
pragma solidity 0.8.17;

import "./interfaces/IBookieMain.sol";
import "./utils/AccessHandler.sol";
import "./libs/LibString.sol";
import "./libs/BetData.sol";
import "./libs/TokenAmountValidator.sol";
// For debugging only


/**
 * @title Bookie Main contract
 * @author Deepp Dev Team
 * @notice This is the main contract for the app: BookieMain.
 * @notice Multi contract app taking bets and locking tokens until bets settle.
 * @notice Token bets are matched from a liquidity pool (LP) of same token type.
 * @notice The LP holds tokens of a certain type, and issues LP tokens as
 *         proof of deposit.
 * @notice It has a simple node.js react app for easy interfacing.
 * @notice Accesshandler is Initializable.
 */
contract BookieMain is IBookieMain, AccessHandler {

    using TokenAmountValidator for address;
    using LibString for string;

    IBetHelper private lp;
    IBetHistory private betHistory;
    IMarketHistory private marketHistory;
    IDaoBonusDistribution private bonusHandler;
    ITokenTransferProxy private tokenTransferProxy; // Just used as an address

    /**
     * @notice Event that fires when a bet is accepted.
     * @param better is the address that made the bet.
     * @param betHash is calculated hash of the bet data.
     * @param amount is the betters amount wagered.
     * @param token is the token contract address.
     * @param decimalOdds is the odds of the bet in decimal format.
     * @param marketHash is the hash of the market betted.
     */
/*   * @param betPot is the potsize of the bet (better + house).
     * @param expiry is an epoch formatted expiry time in secs.
 */
    event BetWagered(
        address indexed better,
        bytes32 indexed betHash,
        uint256 amount,
        address token,
        uint256 decimalOdds,
        bytes32 marketHash
    );

    /**
     * @notice Event that fires when a bet is decided/settled.
     * @param better is the address that won the bet.
     * @param token is the token contract address
     * @param paid is the prize paid out (0 if its a loss).
     * @param betHash is calculated hash of the bet data.
     */
    event BetSettled(
        address indexed better,
        address indexed token, // TODO: Is this necessary if we only accept 1 token type?
        uint256 paid,
        bytes32 betHash
    );

    /**
     * @notice Event that fires when a bet is canceled.
     *         Can be due to a canceled market or an admin action.
     * @param better is the address made the bet.
     * @param token is the token contract address
     * @param paid is the amount paid back.
     * @param betHash is calculated hash of the bet data.
     */
    event BetCanceled(
        address indexed better,
        bytes32 indexed betHash,
        address token, // Is this necessary if we only accept 1 token type?
        uint256 paid
    );

    /**
     * @notice Event fires there is no bet to settle
     * @param better is the owner of the bet
     * @param token is the token contract address
     */
    event BetNothingToSettle(
        address indexed better,
        address indexed token
    );

    /**
     * @notice Event fires there is no bet to cancel
     * @param better is the owner of the bet
     * @param token is the token contract address
     */
    event BetNothingToCancel(
        address indexed better,
        address indexed token
    );

    /**
     * @notice Error for Insufficient user balance for betting.
     *         Needed `required` but only `available` available.
     * @param available balance available.
     * @param required requested amount to bet.
     */
    error InsufficientBalance(uint256 available, uint256 required);

    /**
     * @notice Error for Insufficient allowance for betting.
     *         Needed `required` but only `available` available.
     * @param available allowance available.
     * @param required requested amount to bet.
     */
    error InsufficientAllowance(uint256 available, uint256 required);

    /**
     * @notice Error for Insufficient liquidity to match a bet.
     * Needed `required` but only `available` available.
     * @param available balance available.
     * @param required requested amount to transfer.
     */
    error InsufficientLiquidityBalance(uint256 available, uint256 required);

    /**
     * @notice Error for Invaid bet.
     * @param reason is the reason of the error.
     * @param bet is the bet details.
     */
    error InvalidBet(string reason, BetData.Bet bet);

    /**
     * @notice Error for a non matching signature.
     * @param betHash is the calculated hash of the bet details.
     */
    error InvalidSignature(bytes32 betHash);

    constructor() AccessHandler() {}

    /**
     * @notice Initializes this contract with reference to other contracts.
     * @param inLP The Liquidity Pool contract address, for matching bets.
     * @param inBetHistory The bet history contract address for storing bets.
     * @param inMarketHistory The market history contract address.
     * @param inTokenTransferProxy The TokenTransferProxy contract address.
     */
    function init(
        IBetHelper inLP,
        IBetHistory inBetHistory,
        IMarketHistory inMarketHistory,
        IDaoBonusDistribution inDaoBonusDistribution,
        ITokenTransferProxy inTokenTransferProxy
    )
        external
        notInitialized
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        lp = inLP;
        betHistory = inBetHistory;
        marketHistory = inMarketHistory;
        bonusHandler = inDaoBonusDistribution;
        tokenTransferProxy = inTokenTransferProxy;
        BaseInitializer.initialize();
    }

    /**
     * @notice Setter to change the referenced LiquidityPool contract.
     * @param inLP The Liquidity Pool contract, to match bets.
     */
    function setLiquidityPool(IBetHelper inLP)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        lp = inLP;
    }

    /**
     * @notice Setter to change the referenced BetHistory contract.
     * @param inBetHistory The bet history contract for storing bets.
     */
    function setBetHistory(IBetHistory inBetHistory)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        betHistory = inBetHistory;
    }

    /**
     * @notice Setter to change the referenced MarketHistory contract.
     * @param inMarketHistory The market history contract address.
     */
    function setMarketHistory(IMarketHistory inMarketHistory)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        marketHistory = inMarketHistory;
    }

    /**
     * @notice Setter to change the referenced DaoBonusDistribution contract.
     * @param inDaoBonusDistribution The bonus handler contract address.
     */
    function setDaoBonusDistribution(IDaoBonusDistribution inDaoBonusDistribution)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        bonusHandler = inDaoBonusDistribution;
    }

    /**
     * @notice Setter to change the referenced TokenTransferProxy contract.
     * @param inTokenTransferProxy The TokenTransferProxy contract address.
     */
    function setTokenTransferProxy(ITokenTransferProxy inTokenTransferProxy)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        tokenTransferProxy = inTokenTransferProxy;
    }

    /**
     * @notice Check bet data and signature against a supplied signer account.
     *         Create the bet if it validates. This is temp func only.
     * @param token The token type to bet.
     * @param amount The amount to bet.
     * @param odds The odds of the bet in decimal notation.
     * @param expiry The epoch representation of expiry time of the request.
     * @param marketHash Is the market hash to identy the market.
     * @param signature The signature to compare to the signer.
     * @param signer The signer to compare to the signature.
     *        "signer" will be removed and replace by an admin set address.
     */
    function makeBetWithSigner(
        address token,
        uint256 amount,
        uint256 odds,
        uint256 expiry,
        bytes32 marketHash,
        bytes calldata signature,
        address signer
    )
        external
        override
        isInitialized
        whenNotPaused
    {
        address better = msg.sender;
        BetData.Bet memory bet = BetData.Bet({
            marketHash: marketHash,
            token: token,
            amount: amount,
            decimalOdds: odds,
            expiry: expiry,
            owner: better
        });

        // TODO: remove conditional "verify Bet signature"
        bool verified = (signature.length != 0) ? BetData.checkSignature(bet, signature, signer) : true;
        if (!verified) {
            revert InvalidSignature({betHash: BetData.getBetHash(bet)});
        }

        createBet(bet);
    }

    /**
     * @notice Check bet data and signature against a stored signer account.
     *         Create the bet if it validates.
     * @param token The token type to bet.
     * @param amount The amount to bet.
     * @param odds The odds of the bet in decimal notation.
     * @param expiry The epoch representation of expiry time of the request.
     * @param marketHash Is the market hash to identify the market.
     * @param signature The signature to compare to the signer.
     */
    function makeBet(
        address token,     // TODO: Check for valid Token (TokenValidator)?
        uint256 amount,    //       Sub calls to LP (matchBet()) and
        uint256 odds,      //       LockBox (lockAmount()) already checks token.
        uint256 expiry,    // TODO: Test that expiry actually works
        bytes32 marketHash,
        bytes calldata signature
    )
        external
        override
        isInitialized
        whenNotPaused
    {
        address better = msg.sender;
        BetData.Bet memory bet = BetData.Bet({
            marketHash: marketHash,
            token: token,
            amount: amount,
            decimalOdds: odds,
            expiry: expiry,
            owner: better
        });

        // TODO: remove conditional "verify Bet signature"
        bool verified = (signature.length == 0);
        if (!verified) {
            bytes32 betHash = BetData.getBetHash(bet);
            verified = hasRole(SIGNER_ROLE, ECDSA.recover(betHash, signature));
            if (!verified) {
                revert InvalidSignature({betHash: betHash});
            }
        }

        createBet(bet);
    }

    /**
     * @notice Creates the bet and locks the betters and the LPs tokens.
     * @param bet is a struct that holds all the bet details
     */
    function createBet(BetData.Bet memory bet) private {
        string memory validity = BetData.getParamValidity(bet);
        if (!validity.equals("OK"))
            revert InvalidBet({reason: validity, bet: bet});
        bytes32 betHash = BetData.getBetHash(bet);
        if (betHistory.getBetExists(betHash))
            revert InvalidBet({reason: "BET_ALREADY_EXISTS", bet: bet});

        // Check that its a valid market
        marketHistory.assertMarketIsActive(bet.marketHash);

        // Check balances
        (
            TokenAvailability res,
            uint256 available
        ) = bet.owner.checkAllowanceAndBalance(
            bet.amount,
            bet.token,
            address(tokenTransferProxy)
        );
        if (res == TokenAvailability.InsufficientBalance) {
            revert InsufficientBalance({
                available: available,
                required: bet.amount
            });
        } else if (res == TokenAvailability.InsufficientAllowance) {
            revert InsufficientAllowance({
                available: available,
                required: bet.amount
            });
        }

        uint256 liquidityBetBalance = lp.getLiquidityAvailableForBet(bet.token);
        uint256 matchedAmount = (bet.amount * bet.decimalOdds / BetData.ODDS_PRECISION) - bet.amount;

        if (liquidityBetBalance < matchedAmount) {
            revert InsufficientLiquidityBalance({
                available: liquidityBetBalance,
                required: matchedAmount
            });
        }

        //Now match, persist, transfer and token-lock the bet
        betHistory.createBet(bet);
        // Report the bet to the bonus handler
        if (address(bonusHandler) != address(0))
            bonusHandler.updateProgress(bet.owner, bet.amount);

        emit BetWagered(
            bet.owner,
            betHash,
            bet.amount,
            bet.token,
            bet.decimalOdds,
            bet.marketHash);
    }


    /**
     * @notice Settle a bet and pay the pot to the winner or to our LP
     * @param betHash The key/hash of the bet settle.
     */
    function settleBet(bytes32 betHash) external override whenNotPaused {
        BetData.BetSettleResult memory res = betHistory.settleBet(betHash);

        if (res.paidToBetter == 0 && res.paidToLP == 0) {
            emit BetNothingToSettle(res.better, res.tokenAdd);
            return;
        }




        emit BetSettled(res.better, res.tokenAdd, res.paidToBetter, betHash);
    }

   /**
     * @notice Let the admin of this contract cancel an active bet
     * @param betHash The key/hash of the bet cancel.
     */
    function cancelBetAsAdmin(bytes32 betHash)
        external
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        BetData.BetSettleResult memory res = betHistory.cancelBet(betHash);

        if (res.paidToBetter == 0 && res.paidToLP == 0) {
            emit BetNothingToCancel(res.better, res.tokenAdd);
            return;
        }
        emit BetCanceled(
            res.better,
            betHash,
            res.tokenAdd,
            res.paidToBetter
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./ILockBox.sol";
import "./IRewardHandler.sol";
import "./IMarketHistory.sol";
import "./utils/IBetHelper.sol";
import "./utils/ITokenTransferProxy.sol";
import "../libs/BetData.sol";

interface IBetHistory {
    function setLiquidityPool(IBetHelper) external;
    function setBetLockBox(ILockBox) external;
    function setMarketHistory(IMarketHistory) external;
    function setTokenTransferProxy(ITokenTransferProxy) external;
    function setFeeHandler1(IRewardHandler) external;
    function setFeeHandler2(IRewardHandler) external;
    function setFees(uint8, uint8, uint8) external;
    function createBet(BetData.Bet calldata) external;
    function settleBet(bytes32)
        external
        returns (BetData.BetSettleResult memory);
    function cancelBet(bytes32)
        external
        returns (BetData.BetSettleResult memory);
    function getBetExists(bytes32) external view returns(bool);
    function allBets(bytes32)
        external
        view
        returns (bytes32, address, uint256, uint256, uint256, address);
    function unsettledPots(bytes32) external view returns (uint256);
    function marketBetted(bytes32, address) external view returns (uint256);
    function marketMatched(bytes32, address) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./utils/IBetHelper.sol";
import "./IBetHistory.sol";
import "./IMarketHistory.sol";
import "./IDaoBonusDistribution.sol";
import "./utils/ITokenTransferProxy.sol";

interface IBookieMain {
    function setLiquidityPool(IBetHelper) external;
    function setBetHistory(IBetHistory) external;
    function setMarketHistory(IMarketHistory) external;
    function setDaoBonusDistribution(IDaoBonusDistribution) external;
    function setTokenTransferProxy(ITokenTransferProxy) external;
    function makeBetWithSigner(
        address,
        uint256,
        uint256,
        uint256,
        bytes32,
        bytes calldata,
        address
    ) external;
    function makeBet(
        address,
        uint256,
        uint256,
        uint256,
        bytes32,
        bytes calldata
    ) external;
    function settleBet(bytes32) external;
    function cancelBetAsAdmin(bytes32) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./utils/ITokenTransferProxy.sol";

interface IDaoBonusDistribution {
    enum BonusState { Undefined, Pending, Active, Completed, Released } // Enum

    struct BonusPortion {
        uint8 id;
        BonusState state;
        address tokenAdd;
        uint256 amount;
        uint256 released;
        uint256 progress;
        uint256 progressTarget;
    }

    function addPortion(uint8 id, address tokenAdd, uint256 amount, uint256 target) external;
    function claimBonus(address tokenAdd) external;
    function updateProgress(address inAccount, uint256 inNewProgress) external;
    function releaseBonus(address[] calldata inRecipients) external;
    function setPortionState(uint8 inId, BonusState inState) external;
    function getPortion(uint8 id) external view returns (BonusPortion memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface ILockBox {
    function lockAmount(address, address, uint256) external;
    function unlockAmount(address, address, uint256) external;
    function unlockAmountTo(address, address, address, uint256) external;
    function getLockedAmount(address, address)
        external
        view
        returns (uint256);
    function hasLockedAmount(address, address, uint256)
        external
        view
        returns(bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IMarketHistory {
    // State is all possible, only Completed has a defined outcome.
    enum MarketState { Undefined, Active, Playing, Completed } // Enum
    // Outcomes are defined as seen for better.
    enum MarketOutcome { Undefined, Win, HalfWin, Void, HalfLoss, Loss, Cancel } // Enum

    function createMarket() external;
    function addMarket(bytes32 hash) external;
//    function activateMarket(bytes32) external;
    function setMarketPlaying(bytes32) external;
    function settleMarket(bytes32, MarketOutcome) external;
    function assertMarketIsActive(bytes32) external view;
//    function assertMarketIsPlaying(bytes32) external view;
    function assertMarketIsCompleted(bytes32) external view;
    function getMarketState(bytes32)
        external
        view
        returns (MarketState);
    function isMarketOutcome(bytes32, MarketOutcome)
        external
        view
        returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./ILockBox.sol";

interface IRewardHandler is ILockBox {
    function addRewards(address, address, uint256) external;
    function updateRewards(address, address) external;
    function transferNondistributableRewardsTo(address, address) external;
    function claimRewardsOfAccount(address, address) external;
    function claimRewards(address) external;
    function getAvailableRewards(address, address)
        external
        view
        returns(uint256);
    function getDistToken(address) external view returns(address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IAccessHandler {
    function changeAdmin(address) external;
    function pause() external;
    function unpause() external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IBetHelper {
    function matchBet(address, uint256) external;
    function setLpBetPercent(uint8) external;
    function getLiquidityAvailableForBet(address)
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface ITokenTransferProxy {
    function transferFrom(address, address, address, uint256)
        external
        returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
// For debugging only



/**
 * @title BetData
 * @author Deepp Dev Team
 * @notice Central definition for what a bet is with utilities to make/check etc.
 */
library BetData {

    uint256 internal constant ODDS_PRECISION = 1e10;
    uint256 private constant MAX_ODDS = 1e3;

    struct Bet {
        bytes32 marketHash;
        address token;
        uint256 amount;
        uint256 decimalOdds;
        uint256 expiry;
        address owner;
    }

    struct BetSettleResult {
            address better;
            address tokenAdd;
            uint256 paidToBetter;
            uint256 paidToLP;
            uint256 paidToFee;
    }

    /**
     * @notice Checks the parameters of a bet to see if they are valid.
     * @param bet The bet to check.
     * @return string A status string in UPPER_SNAKE_CASE.
     *         It will return "OK" if everything checks out.
     */
    function getParamValidity(Bet memory bet)
        internal
        view
        returns (string memory)
    {
        if (bet.amount == 0) {return "BET_AMOUNT_ZERO";}
        if (bet.decimalOdds <= 1 || bet.decimalOdds > ODDS_PRECISION * MAX_ODDS) {
            return "INVALID_DECIMAL_ODDS";
        }
        if (bet.expiry < block.timestamp) {return "BET_EXPIRED";}
        if (bet.token == address(0)) {return "INVALID_TOKEN";}
        return "OK";
    }

    /**
     * @notice Checks the signature of a bet to see if it was signed by
     *         a given signer.
     * @param bet The bet to check.
     * @param signature The signature to compare to the signer.
     * @param signer The signer to compare to the signature.
     * @return bool True if the signature matches, false otherwise.
     */
    function checkSignature(
        Bet memory bet,
        bytes calldata signature,
        address signer
    )
        internal
        pure
        returns (bool)
    {
        return checkHashSignature(getBetHash(bet), signature, signer);
    }

    /**
     * @notice Checks the signature of a data hash to see if it was signed by
     *         a given signer.
     * @param dataHash The data to check.
     * @param signature The signature to compare to the signer.
     * @param signer The signer to compare to the signature.
     * @return bool True if the signature matches, false otherwise.
     */
    function checkHashSignature(
        bytes32 dataHash,
        bytes calldata signature,
        address signer
    )
        internal
        pure
        returns (bool)
    {
        //bytes32 signedMsgHash = ECDSA.toEthSignedMessageHash(dataHash);
        return ECDSA.recover(dataHash, signature) == signer;
    }

    /**
     * @notice Computes the hash of a bet. Packs the arguments in order
     *         of the Bet struct.
     * @param bet The Bet to compute the hash of.
     * @return bytes32 The calculated hash of of the bet.
     */
    function getBetHash(Bet memory bet) internal pure returns (bytes32) {
        return keccak256(
            abi.encode(
                bet.marketHash,
                bet.token,
                bet.amount,
                bet.decimalOdds,
                bet.expiry,
                bet.owner
            )
        );
    }

    /**
     * @notice Logs the content of a bet to the Hardhat console log.
     * @param bet The Bet to log the content of.
     */
    function logBet(Bet storage bet) internal view {







    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;


/**
 * @title LibString
 * @author Deepp Dev Team
 * @notice Utility to efficiently compare strings when necessary.
 */
library LibString {

    /**
     * @notice Compares two strings by taking their hash.
     * @param a The first string.
     * @param b The second string.
     * @return bool true or false depending on the strings compared.
     */
    function equals(string memory a, string memory b)
        internal
        pure
        returns (bool)
    {
        return keccak256(abi.encode(a)) == keccak256(abi.encode(b));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

enum TokenAvailability { InsufficientBalance, InsufficientAllowance, OK }

/**
 * @title TokenAmountValidator
 * @author Deepp Dev Team
 * @notice Lib to help with checking token balances, allowance etc.
 */
library TokenAmountValidator {

    /** @notice Checks an address balance and allowance for a given amount.
     *  @param owner The owner of the token balance and allowance.
     *  @param amount Is amount to check for.
     *  @param tokenAddress The token to check the availability for.
     *  @param receiver The address to check allowance for.
     *  @return TokenAvailability enum value and balance available.
     */
    function checkAllowanceAndBalance(
        address owner,
        uint256 amount,
        address tokenAddress,
        address receiver
    )
        internal
        view
        returns (TokenAvailability, uint256)
    {
        IERC20 token = IERC20(tokenAddress);
        uint256 balance = token.allowance(owner, address(receiver));
        if ( balance < amount) {
            return (TokenAvailability.InsufficientAllowance, balance);
        }
        balance = token.balanceOf(owner);
        if (balance < amount) {
            return (TokenAvailability.InsufficientBalance, balance);
        }
        return (TokenAvailability.OK, balance);
    }

    /** @notice Checks an address allowance for a given amount.
     *  @param owner The owner of the token allowance.
     *  @param amount Is amount to check for.
     *  @param tokenAddress The token to check the availability for.
     *  @param receiver The address to check allowance for.
     *  @return TokenAvailability enum value and allowance available.
     */
    function checkAllowance(
        address owner,
        uint256 amount,
        address tokenAddress,
        address receiver
    )
        internal
        view
        returns (TokenAvailability, uint256)
    {
        IERC20 token = IERC20(tokenAddress);
        uint256 balance = token.allowance(owner, address(receiver));
        if (balance < amount) {
            return (TokenAvailability.InsufficientAllowance, balance);
        }
        return (TokenAvailability.OK, balance);
    }

    /** @notice Checks an address balance for a given amount.
     *  @param owner The owner of the token balance.
     *  @param amount Is amount to check for.
     *  @param tokenAddress The token to check the availability for.
     *  @return TokenAvailability enum value.
     */
    function checkBalance(
        address owner,
        uint256 amount,
        address tokenAddress
    )
        internal
        view
        returns (TokenAvailability, uint256)
    {
        IERC20 token = IERC20(tokenAddress);
        uint256 balance = token.balanceOf(owner);
        if (balance < amount) {
            return (TokenAvailability.InsufficientBalance, balance);
        }
        return (TokenAvailability.OK, balance);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../interfaces/utils/IAccessHandler.sol";
import "./BaseInitializer.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

/**
 * @title Access Handler
 * @author Deepp Dev Team
 * @notice An access control contract. It restricts access to otherwise public
 *         methods, by checking for assigned roles. its meant to be extended
 *         and holds all the predefined role type for the derrived contracts.
 * @notice This is a util contract for the BookieMain app.
 */
abstract contract AccessHandler
    is IAccessHandler,
    BaseInitializer,
    AccessControl,
    Pausable
{
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    bytes32 public constant TRANSFER_ROLE = keccak256("TRANSFER_ROLE");
    bytes32 public constant BETTER_ROLE = keccak256("BETTER_ROLE");
    bytes32 public constant LOCKBOX_ROLE = keccak256("LOCKBOX_ROLE");
    bytes32 public constant REPORTER_ROLE = keccak256("REPORTER_ROLE");
    bytes32 public constant REWARDER_ROLE = keccak256("REWARDER_ROLE");
    bytes32 public constant SIGNER_ROLE = keccak256("SIGNER_ROLE");
    bytes32 public constant TOKEN_ROLE = keccak256("TOKEN_ROLE");
    bytes32 public constant BONUS_REPORTER_ROLE = keccak256("BONUS_REPORTER_ROLE");
    bytes32 public constant BONUS_CONTROLLER_ROLE = keccak256("BONUS_CONTROLLER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    // TODO: Consider replacing OZ modifiers, cannot be overrriden.
    //       OZ implementation uses revert string instead of custom error.
    //       We could override the internal _ logic, but it feels invasive.

    /**
     * @notice Simple constructor, just sets the admin.
     * Allows for AccessHandler to be inherited by non-upgradeable contracts
     * that are normally deployed, with a contructor call.
     */
    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
    }

    /**
     * @notice Changes the admin and revokes the roles of the current admin.
     * @param newAdmin is the addresse of the new admin.
     */
    function changeAdmin(address newAdmin)
        external
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _grantRole(DEFAULT_ADMIN_ROLE, newAdmin);
        // We only want 1 admin
        _revokeRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /**
     * @notice Puts the contract in pause state, for emergency control.
     */
    function pause() external override onlyRole(PAUSER_ROLE) {
        _pause();
    }

    /**
     * @notice Puts the contract in operational state, after being paused.
     */
    function unpause() external override onlyRole(PAUSER_ROLE) {
        _unpause();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

abstract contract BaseInitializer is Initializable {

    /**
     * Error for call to a contract that is not yet initialized.
     */
    error NotInitialized();

    /**
     * Error for call to a contract that is already initialized.
     */
    error AlreadyInitialized();

    /**
     * @notice Throws if this contract has not been initialized.
     */
    modifier isInitialized() {
        if (!getInitialized()) {
            revert NotInitialized();
        }
        _;
    }

    /**
     * @notice Throws if this contract has already been initialized.
     */
    modifier notInitialized() {
        if (getInitialized()) {
            revert AlreadyInitialized();
        }
        _;
    }

    /**
     * @notice Initialize and remember this state to avoid repeating.
     */
    function initialize() internal virtual initializer {}

    /**
     * @notice Get the state of initialization.
     * @return bool true if initialized.
     */
    function getInitialized() internal view returns (bool) {
        return _getInitializedVersion() != 0 && !_isInitializing();
    }

    /**
     * @notice Get the state of initialization.
     * @return bool true if initialized.
     */
    function getInitializedVersion() external view returns (uint8) {
        return _getInitializedVersion();
    }
}