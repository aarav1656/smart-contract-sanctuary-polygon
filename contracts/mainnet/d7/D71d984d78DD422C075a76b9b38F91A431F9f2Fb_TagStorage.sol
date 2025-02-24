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
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
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

pragma solidity ^0.8;

library CoreConsts {

    bytes32 public constant MANAGER_ROLE = keccak256('MANAGER_ROLE');

    string  public constant ROLE_MANAGER_MODULE_NAME = "ROLE_MANAGER";
    bytes32 public constant ROLE_MANAGER_MODULE_ID = keccak256(abi.encodePacked(ROLE_MANAGER_MODULE_NAME));

    string  public constant MANAGER_MODULE_NAME = "MODULE_MANAGER";
    bytes32 public constant MANAGER_MODULE_ID = keccak256(abi.encodePacked(MANAGER_MODULE_NAME));

    string  public constant TAG_STORAGE_MODULE_NAME = "TAG_STORAGE";
    bytes32 public constant TAG_STORAGE_MODULE_ID = keccak256(abi.encodePacked(TAG_STORAGE_MODULE_NAME));

}

pragma solidity ^0.8;

interface IModuleListener {

    event ModuleUpdated(address oldInstance, address _manager);

    event ModuleAdded(address _manager);

    event ModuleReplaced(address contractInstance);

    event ModuleRemoved();

    event ModuleOwnershipUpdate(address newOwner);

    event ModuleManagerSwitch(address newManager);

    function getName() view external returns(string memory);

    function getId() view external returns(bytes32);

    function getVersion() view external returns(bytes32);

    function onUpdate(address oldInstance, address _manager) external;

    function onAdd(address _manager) external;

    function onReplaced(address newInstance) external;

    function onRemoved() external;

    function updateOwnership(address newOwner) external;

    function switchManager(address newManager) external;

    function onListenAdded(bytes32 hname, address contractInstance, bool isNew) external;

    function onListenRemoved(bytes32 hname) external;

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

abstract contract ContentMixin {
    function msgSender()
        internal
        view
        returns (address payable sender)
    {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
                // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender := and(
                    mload(add(array, index)),
                    0xffffffffffffffffffffffffffffffffffffffff
                )
            }
        } else {
            sender = payable(msg.sender);
        }
        return sender;
    }
}

pragma solidity ^0.8;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts/access/IAccessControl.sol";

import "./meta-transactions/ContentMixin.sol";

import "../common/IModuleManager.sol";

import "./IModuleListener.sol";
import {CoreConsts} from "./CoreConsts.sol";

abstract contract ModuleUpgradeable is AccessControlUpgradeable, OwnableUpgradeable, ContentMixin, IModuleListener {

    IModuleManager public manager;
    IAccessControl public authManager;

    event LinkRoleManager(address addr);


    modifier onlyManager {
	require(hasRole(CoreConsts.MANAGER_ROLE, msg.sender),"CrossContractManListener: the caller must have MANAGER_ROLE");
	_;
    }

    function getManagerRole() public pure returns(bytes32){return CoreConsts.MANAGER_ROLE;}

    function __Module_init() internal onlyInitializing {
	AccessControlUpgradeable.__AccessControl_init();
	OwnableUpgradeable.__Ownable_init();

	__Module_init_unchained();
    }

    function __Module_init_unchained() internal onlyInitializing {
	_grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function onListenAdded(bytes32 hname, address contractInstance, bool isNew) override virtual public onlyManager {
	_onListenAdded(hname, contractInstance, isNew);
    }

    function _onListenAdded(bytes32 hname, address contractInstance, bool isNew) internal virtual {
	if(address(this) == contractInstance)return;
	if(hname == CoreConsts.ROLE_MANAGER_MODULE_ID){
	    _linkRoleManager(contractInstance);
	}
    }

    function onListenRemoved(bytes32 hname) override virtual public onlyManager {
	_onListenRemoved(hname);
    }

    function _onListenRemoved(bytes32 hname) internal virtual {
	if(hname == CoreConsts.ROLE_MANAGER_MODULE_ID){
    	    authManager = IAccessControl(address(0));
	}
    }

    function onUpdate(address oldInstance, address _manager) external virtual override {
	_onUpdate(oldInstance,_manager);
    }

    function _onUpdate(address oldInstance, address _manager) internal virtual onlyManager {
	manager = IModuleManager(_manager);

	require(IModuleListener(oldInstance).getVersion() != this.getVersion(), "The version of the updated contract must differ from the previous one");

	emit ModuleUpdated(oldInstance, _manager);
    }

    function onAdd(address _manager) external virtual override {
	_onAdd(_manager);
    }

    function _onAdd(address _manager) internal virtual onlyManager {
	manager = IModuleManager(_manager);

	emit ModuleAdded(_manager);
    }

    function onReplaced(address newInstance) external virtual override {
	_onReplaced(newInstance);
    }

    function _onReplaced(address newInstance) internal virtual onlyManager {
	emit ModuleReplaced(newInstance);
    }

    function onRemoved() external virtual override {
	_onRemoved();
    }

    function _onRemoved() internal virtual onlyManager {
	manager = IModuleManager(address(0));

	emit ModuleRemoved();
    }

    function updateOwnership(address newOwner) external virtual override {
	_updateOwnership(newOwner);
    }

    function _updateOwnership(address newOwner) internal virtual onlyManager {
	transferOwnership(newOwner);

	emit ModuleOwnershipUpdate(newOwner);
    }

    function switchManager(address newManager) external virtual override {
	_switchManager(newManager);
    }

    function _switchManager(address newManager) internal virtual onlyManager {
	manager = IModuleManager(newManager);
	grantRole(CoreConsts.MANAGER_ROLE, newManager);
	revokeRole(CoreConsts.MANAGER_ROLE, msg.sender);

	emit ModuleManagerSwitch(newManager);
    }

    function linkRoleManager(address addr) public virtual onlyOwner {
	_linkRoleManager(addr);
    }

    function _linkRoleManager(address addr) internal virtual {
	authManager = IAccessControl(addr);

	emit LinkRoleManager(addr);
    }

    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
	if(!super.hasRole(role, account)){
    	    if(address(authManager) != address(0)){
		return authManager.hasRole(role, account);
    	    }
    	    else return false;
	}else return true;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
	{
    	    return 
    		interfaceId == type(IModuleListener).interfaceId ||
    		super.supportsInterface(interfaceId);
	}

    /**
     * This is used instead of msg.sender as transactions won't be sent by the original token owner, but by OpenSea.
     */
    function _msgSender()
        internal
        override
        virtual
        view
        returns (address sender)
    {
        return ContentMixin.msgSender();
    }

}

pragma solidity ^0.8;

interface IModuleManager {

    event Man_ModuleReplaced(bytes32 h_name, address module_addr);

    event Man_ModuleAdded(bytes32 h_name, address module_addr);

    event ManagerUpdatedFrom(address oldManager);

    event ManagerUpdatedTo(address newManager);

    function onSwitchManager(address oldManager) external;

    function addModule(address module_addr) external;

    function addModule(string calldata name, address module_addr) external;

    function removeModule(string calldata name) external;

    function isListener(address instance) external view returns (bool);

    function upgradeManager(address newManager) external;

    function getModule(string calldata name) external view returns (address);

    function getModule(bytes32 id) external view returns (address);

    function getModuleId(address addr) external view returns (bytes32);

    function getModuleIdAt(uint256 idx) external view returns (bytes32);

    function getModulesCount() external view returns (uint256);

    function getManagerRoleCode() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
/**
 * @title Key-value (Tag) generic storage
 * @notice Stores tags (key-value) pairs of byte32, string, uint256 and boolean types.
 * The storage is agnostic to what contract (editor) and what data are being stored. Tags are formed by
 * the editor contracts. The storage provides authentication for adding/modifying tags.
 *
 * Each tag is assigned an editors' group. An editor (contract or user) can be added to one or more groups.
 * An editor can add/modify only those tags that are assigned to a group which the editor belongs to.
 */

pragma solidity ^0.8.0;

import "../base/ModuleUpgradeable.sol";

contract TagStorage is ModuleUpgradeable {
    bytes32 public constant ADDER_ROLE = keccak256("ADDER_ROLE");

    mapping(bytes32 => bytes32) tagGroup;
    mapping(bytes32 => bytes32) tagByte32Value;
    mapping(bytes32 => string) tagStringValue;
    mapping(bytes32 => uint256) tagIntValue;
    mapping(bytes32 => bool) tagBooleanValue;
    mapping(bytes32 => StatType) tagType;
    //    mapping (bytes32 => StatType) tagType;
    //    mapping (bytes32 => bool) groupMember;

    enum StatType{ None, Integer, String, ByteArray, Boolean, Address }

    struct Stat{
	string name;
	StatType statType;
	bool is_mutable;
    }

    struct StatValue{
	StatType statType;
	uint256  int_val;
	string   str_val;
	bytes32  bta_val;
	bool     bool_val;
	address	 addr_val;
    }

    uint256[256] __gap;

    modifier onlyAdder() {
        require(
            hasRole(ADDER_ROLE, msg.sender),
            "TagStorage: The caller must have adder's priviledges"
        );
        _;
    }

    modifier onlyAdmin() {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "TagStorage: The caller must have admin's priviledges"
        );
        _;
    }

    modifier authorizeEdit(bytes32 groupID, bytes32 key) {
        require(
            hasRole(groupID, msg.sender),
            "TagStorage: Caller needs to be group member of groupID"
        );
        if (tagGroup[key] != bytes32(0)) {
            require(
                hasRole(tagGroup[key], msg.sender),
                "TagStorage: Caller needs to be tag's group member"
            );
            //	    bytes32 groupMemberKey = keccak256(abi.encode(msg.sender,tagGroup[key]));
            //	    require(groupMember[groupMemberKey],"TagStorage: Need to be tag's group member");
        }
        tagGroup[key] = groupID;
        _;
    }

    modifier byte32Tag(bytes32 key) {
        require(
            (tagType[key] == StatType.ByteArray),
            "TagStorage: The tag must be a byte array"
        );
        _;
    }

    modifier stringTag(bytes32 key) {
        require(
            (tagType[key] == StatType.String),
            "TagStorage: The tag must be a string"
        );
        _;
    }

    modifier intTag(bytes32 key) {
        require(
            (tagType[key] == StatType.Integer),
            "TagStorage: The tag must be an integer"
        );
        _;
    }

    modifier booleanTag(bytes32 key) {
        require(
            (tagType[key] == StatType.Boolean),
            "TagStorage: The tag must be a boolean"
        );
        _;
    }

    function initialize() public initializer {
	ModuleUpgradeable.__Module_init();
    }


    function getId() public view override returns (bytes32) {
        return CoreConsts.TAG_STORAGE_MODULE_ID;
    }

    function getName() public view override returns (string memory) {
        return CoreConsts.TAG_STORAGE_MODULE_NAME;
    }

    function getVersion() external view virtual override returns (bytes32) {
        return keccak256(abi.encodePacked("v1.0")); // First release
    }

    function grantAdminRole(address entity) external virtual onlyOwner {
        super._setupRole(DEFAULT_ADMIN_ROLE, entity);
    }

    function revokeAdminRole(address entity) external virtual onlyOwner {
        super.revokeRole(DEFAULT_ADMIN_ROLE, entity);
    }

    function grantAdderRole(address entity) external virtual onlyAdmin {
        super._setupRole(ADDER_ROLE, entity);
    }

    function revokeAdderRole(address entity) external virtual onlyAdmin {
        super.revokeRole(ADDER_ROLE, entity);
    }

    function isAdmin(address entity) external view returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, entity);
    }

    function isAdder(address entity) external view returns (bool) {
        return hasRole(ADDER_ROLE, entity);
    }

    function isGroupMember(address entity, bytes32 groupID)
        external
        view
        returns (bool)
    {
        return hasRole(groupID, entity);
        //	bytes32 groupMemberKey = keccak256(abi.encode(entity,groupID));
        //	return groupMember[groupMemberKey];
    }

    /**
     * @notice Add editor to a group
     *
     * @param entity  Editor's address. It can be contract or user
     * @param groupID The id of the group where to add the entity
     **/
    function addEditor2Group(address entity, bytes32 groupID)
        public
        virtual
        onlyAdmin
    {
        grantRole(groupID, entity);
        //	bytes32 groupMemberKey = keccak256(abi.encode(entity,groupID));
        //	groupMember[groupMemberKey] = true;
    }

    /**
     * @notice Remove editor from the group
     *
     * @param entity  Editor's address. It can be contract or user
     * @param groupID The id of the group from where to remove the entity
     **/
    function removeEditorFromGroup(address entity, bytes32 groupID)
        public
        virtual
        onlyAdmin
    {
        revokeRole(groupID, entity);
        //	bytes32 groupMemberKey = keccak256(abi.encode(entity,groupID));
        //	groupMember[groupMemberKey] = false;
    }

    /**
     * @notice Set a byte array tag. The caller must have an adder role.
     * The caller with the adder role can create new tag and assign it to any group id.
     * The caller may modify existing tag and assign it to a new group id if the caller belongs to the group currently associated to the tag.
     *
     * @param groupID The ID of the group for the tag
     * @param key     The key of the tag
     * @param value   The value (type byte32) of the tag
     **/
    function setTag(
        bytes32 groupID,
        bytes32 key,
        bytes32 value
    ) public virtual onlyAdder authorizeEdit(groupID, key) {
        tagType[key] = StatType.ByteArray;
        tagByte32Value[key] = value;
    }

    /**
     * @notice Set a string tag. The caller must have an adder role.
     * The caller with the adder role can create new tag and assign it to any group id.
     * The caller may modify existing tag and assign it to a new group id if the caller belongs to the group currently associated to the tag.
     *
     * @param groupID The ID of the group for the tag
     * @param key     The key of the tag
     * @param value   The value (type string) of the tag
     **/
    function setTag(
        bytes32 groupID,
        bytes32 key,
        string calldata value
    ) public virtual onlyAdder authorizeEdit(groupID, key) {
        tagType[key] = StatType.String;
        tagStringValue[key] = value;
    }

    /**
     * @notice Set an integer tag. The caller must have an adder role.
     * The caller with the adder role can create new tag and assign it to any group id.
     * The caller may modify existing tag and assign it to a new group id if the caller belongs to the group currently associated to the tag.
     *
     * @param groupID The ID of the group for the tag
     * @param key     The key of the tag
     * @param value   The value (type uint256) of the tag
     **/
    function setTag(
        bytes32 groupID,
        bytes32 key,
        uint256 value
    ) public virtual onlyAdder authorizeEdit(groupID, key) {
        tagType[key] = StatType.Integer;
        tagIntValue[key] = value;
    }

    /**
     * @notice Set a boolean tag. The caller must have an adder role.
     * The caller with the adder role can create new tag and assign it to any group id.
     * The caller may modify existing tag and assign it to a new group id if the caller belongs to the group currently associated to the tag.
     *
     * @param groupID The ID of the group for the tag
     * @param key     The key of the tag
     * @param value   The value (type boolean) of the tag
     **/
    function setTag(
        bytes32 groupID,
        bytes32 key,
        bool value
    ) public virtual onlyAdder authorizeEdit(groupID, key) {
        tagType[key] = StatType.Boolean;
        tagBooleanValue[key] = value;
    }

    /**
     * @notice Gets data type of the tag.
     *
     * @param  key The tag's key
     * @return The tag's value data type
     **/
    function getTagType(bytes32 key) public view returns (StatType) {
        return tagType[key];
    }

    /**
     * @notice Gets tag's value of byte array type.
     *
     * @param key The tag's key
     * @return The tag's value of type bytes32
     **/
    function getByte32Value(bytes32 key)
        public
        view
        byte32Tag(key)
        returns (bytes32)
    {
        return tagByte32Value[key];
    }

    /**
     * @notice Gets tag's value of string type.
     *
     * @param key The tag's key
     * @return The tag's value of type string
     **/
    function getStringValue(bytes32 key)
        public
        view
        stringTag(key)
        returns (string memory)
    {
        return tagStringValue[key];
    }

    /**
     * @notice Gets tag's value of integer type.
     *
     * @param key The tag's key
     * @return The tag's value of type uint256
     **/
    function getIntValue(bytes32 key)
        public
        view
        intTag(key)
        returns (uint256)
    {
        return tagIntValue[key];
    }

    /**
     * @notice Gets tag's value of boolean type.
     *
     * @param key The tag's key
     * @return The tag's value of type boolean
     **/
    function getBooleanValue(bytes32 key)
        public
        view
        booleanTag(key)
        returns (bool)
    {
        return tagBooleanValue[key];
    }

    /**
     * @notice Gets tag's associated group
     *
     * @param key The tag's key
     * @return Id of the groupt to which the tag is currently associated
     **/
    function getTagGroup(bytes32 key) public view returns (bytes32) {
        return tagGroup[key];
    }

}