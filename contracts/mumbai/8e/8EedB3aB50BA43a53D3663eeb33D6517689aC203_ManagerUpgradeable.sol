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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

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

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

//SPDX-License-Identifier: MIT
pragma solidity =0.8.16;

import {IOfficerUpgradeable} from './interfaces/IOfficerUpgradeable.sol';
import {IReceiverUpgradeable} from './interfaces/IReceiverUpgradeable.sol';
import {IERC20} from '@openzeppelin/contracts/interfaces/IERC20.sol';
import {IManagerUpgradeable} from './interfaces/IManagerUpgradeable.sol';
import {IUniswapV2Router02} from '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';
import {IUniswapV2Factory} from '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';

import {AccessControlUpgradeable} from '@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol';
import {Initializable} from '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import {VaultType} from './utils/Structures.sol';
import {Roles} from './utils/Roles.sol';
import {OraclePermission} from './utils/OraclePermission.sol';

/**
 * @title ManagerUpgradeable
 * @author gotbit
 * @notice Main contract of the bot profile.
 * @dev ManagerUpgradeable is responsible for providing addresses of the other
 * contracts of the profile, pausing the entire profile at once, profile level
 * roles, managing receivers, and providing access to the Officer contract
 * managing the entire DEX Bot system.
 * It's supposed to be deployed using the beacon proxy pattern.
 */

contract ManagerUpgradeable is
    Initializable,
    AccessControlUpgradeable,
    IManagerUpgradeable
{
    bytes32 public constant EXECUTOR_VOLUME_ROLE = keccak256('EXECUTOR_VOLUME');
    bytes32 public constant EXECUTOR_LIMIT_ROLE = keccak256('EXECUTOR_LIMIT');
    bytes32 public constant WITHDRAWER_ROLE = keccak256('WITHDRAWER');
    bytes32 public constant DEPLOYER_ROLE = keccak256('DEPLOYER');
    bytes32 internal constant ADMIN_ROLE = keccak256('ADMIN');
    bytes32 internal constant SUPERADMIN_ROLE = 0x00;

    address public DEPLOYER;
    address public OFFICER;
    address public BASE;
    address public QUOTE;
    uint256 public DEX_ID;
    uint256 public DEX_TYPE;
    address public RECEIVER_BEACON;
    address public MAIN_VAULT;
    address public VOLUME_VAULT;
    address public LIMIT_VAULT;

    bool public profilePaused;
    bool public momotPaused;
    address public momot;
    address[] public receivers;
    address public prevReceiver;
    VaultType public prevVault;

    mapping(address => uint256) public nonces;

    function hasPermission(
        address user,
        address contract_,
        uint256 expiresAt,
        uint256 nonce,
        bytes calldata data,
        bytes calldata signature
    ) external returns (bool has) {
        if (block.timestamp > expiresAt) return false;
        if (data.length == 0) return false;
        if (signature.length == 0) return false;
        if (nonce != nonces[user]) return false;

        has = IOfficerUpgradeable(OFFICER).hasPermission(
            DEPLOYER,
            user,
            contract_,
            expiresAt,
            nonce,
            data,
            signature
        );

        if (has) nonces[user] = nonce + 1;
    }

    function requestReceiver(VaultType vault) external returns (address) {
        require(receivers.length > 0, 'no receivers');
        require(getVaultAddress(vault) != address(0), 'bad vault');
        require(
            msg.sender == getVaultAddress(vault),
            'only vaults can request receivers'
        );
        require(msg.sender != momot, 'momot cant request receivers');

        if (prevReceiver != address(0))
            _transferTokens(prevReceiver, getVaultAddress(prevVault));

        uint256 randomId;

        // pseudo-random seed
        randomId = uint256(
            keccak256(
                abi.encodePacked(
                    address(this),
                    blockhash(block.number - 1),
                    block.timestamp
                )
            )
        );

        randomId = randomId % receivers.length;

        address newReceiver = receivers[randomId];
        prevReceiver = newReceiver;
        prevVault = vault;
        return newReceiver;
    }

    function _transferTokens(address from, address to) internal {
        if (IERC20(BASE).balanceOf(from) > 0)
            IReceiverUpgradeable(from).withdraw(BASE, to, IERC20(BASE).balanceOf(from));
        if (IERC20(QUOTE).balanceOf(from) > 0)
            IReceiverUpgradeable(from).withdraw(QUOTE, to, IERC20(QUOTE).balanceOf(from));

        address factoryDex = IUniswapV2Router02(getDexAddress()).factory();
        address lpToken = IUniswapV2Factory(factoryDex).getPair(BASE, QUOTE);
        if (IERC20(lpToken).balanceOf(from) > 0)
            IReceiverUpgradeable(from).withdraw(
                lpToken,
                to,
                IERC20(lpToken).balanceOf(from)
            );
    }

    function getVaultAddress(VaultType vault) public view returns (address) {
        return
            vault == VaultType.MOMOT ? momot : vault == VaultType.VOLUME
                ? VOLUME_VAULT
                : vault == VaultType.LIMIT
                ? LIMIT_VAULT
                : vault == VaultType.MAIN
                ? MAIN_VAULT
                : address(0);
    }

    function getDexAddress() public view returns (address) {
        return IOfficerUpgradeable(OFFICER).getDexAddress(DEX_ID);
    }

    function batchGrantRoles(
        bytes32[] calldata roles,
        address[] calldata accounts
    ) external {
        require(roles.length == accounts.length, 'bad length');

        for (uint256 i = 0; i < roles.length; ) {
            grantRole(roles[i], accounts[i]);
            unchecked {
                ++i;
            }
        }
    }

    function batchRevokeRoles(
        bytes32[] calldata roles,
        address[] calldata accounts
    ) external {
        require(roles.length == accounts.length, 'bad length');

        for (uint256 i = 0; i < roles.length; ) {
            revokeRole(roles[i], accounts[i]);
            unchecked {
                ++i;
            }
        }
    }

    function revokeWithdrawer(address[] calldata accounts) external {
        require(IOfficerUpgradeable(OFFICER).hasRole(0x00, msg.sender), 'not superadmin');

        for (uint256 i = 0; i < accounts.length; ) {
            _revokeRole(WITHDRAWER_ROLE, accounts[i]);
            unchecked {
                ++i;
            }
        }
    }

    function hasRoles(
        bytes32[] memory roles,
        address account
    ) external view returns (bool) {
        require(roles.length != 0, 'empty roles');

        for (uint256 i = 0; i < roles.length; ) {
            if (hasRole(roles[i], account)) return true;
            unchecked {
                ++i;
            }
        }
        return false;
    }

    function getReceivers() external view returns (address[] memory) {
        return receivers;
    }

    function setProfilePaused(bool paused) external {
        bytes32[] memory roles = new bytes32[](2);
        roles[0] = ADMIN_ROLE;
        roles[1] = SUPERADMIN_ROLE;

        require(IOfficerUpgradeable(OFFICER).hasRoles(roles, msg.sender), 'no access');

        profilePaused = paused;
    }

    function setMomotPaused(bool paused) external {
        bytes32[] memory roles = new bytes32[](2);
        roles[0] = ADMIN_ROLE;
        roles[1] = SUPERADMIN_ROLE;

        require(IOfficerUpgradeable(OFFICER).hasRoles(roles, msg.sender), 'no access');

        momotPaused = paused;
    }

    function setMomot(address momot_) external {
        bytes32[] memory roles = new bytes32[](2);
        roles[0] = ADMIN_ROLE;
        roles[1] = SUPERADMIN_ROLE;

        require(
            hasRole(WITHDRAWER_ROLE, msg.sender) ||
                IOfficerUpgradeable(OFFICER).hasRoles(roles, msg.sender),
            'no access'
        );
        momot = momot_;
    }

    function init(InitParams calldata params) external initializer {
        _grantRole(DEPLOYER_ROLE, params.deployer);
        _setRoleAdmin(EXECUTOR_VOLUME_ROLE, DEPLOYER_ROLE);
        _setRoleAdmin(EXECUTOR_LIMIT_ROLE, DEPLOYER_ROLE);

        DEPLOYER = params.deployer;
        OFFICER = params.officer;
        BASE = params.base;
        QUOTE = params.quote;
        DEX_TYPE = params.dexType;
        DEX_ID = params.dexId;
        RECEIVER_BEACON = params.receiverBeacon;
        MAIN_VAULT = params.mainVault;
        VOLUME_VAULT = params.mmVault;
        LIMIT_VAULT = params.limitVault;
        momot = params.momot;
        receivers = params.receivers;

        for (uint256 i = 0; i < params.executorsVolume.length; i++) {
            _grantRole(EXECUTOR_VOLUME_ROLE, params.executorsVolume[i]);
        }
        for (uint256 i = 0; i < params.executorsLimit.length; i++) {
            _grantRole(EXECUTOR_LIMIT_ROLE, params.executorsLimit[i]);
        }
        for (uint256 i = 0; i < params.withdrawers.length; i++) {
            _grantRole(WITHDRAWER_ROLE, params.withdrawers[i]);
        }
    }

    function manager() external view returns (address) {
        return address(this);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IAccessControlUpgradeable} from '@openzeppelin/contracts-upgradeable/access/IAccessControlUpgradeable.sol';
import {VaultType} from '../utils/Structures.sol';
import {OraclePermission} from '../utils/OraclePermission.sol';

/**
 * @title IManagerUpgradeable
 * @author gotbit
 * @notice Interface for the ManagerUpgradeable contract.
 * @dev The ManagerUpgradeable contract is the main contract of the profile.
 * It's responsible for providing addresses of the other contracts of the profile,
 * pausing the entire profile at once, profile level roles, managing receivers,
 * and providing access to the Officer contract managing the entire DEX Bot system.
 */

interface IManagerUpgradeable is IAccessControlUpgradeable {
    /// @notice Returns the ID of the EXECUTOR_VOLUME role.
    function EXECUTOR_VOLUME_ROLE() external pure returns (bytes32);

    /// @notice Returns the ID of the EXECUTOR_LIMIT role.
    function EXECUTOR_LIMIT_ROLE() external pure returns (bytes32);

    /// @notice Returns the ID of the WITHDRAWER role.
    function WITHDRAWER_ROLE() external pure returns (bytes32);

    /// @notice Returns the ID of the DEPLOYER role.
    function DEPLOYER_ROLE() external pure returns (bytes32);

    /// @notice Returns the address that deployed the profile.
    function DEPLOYER() external view returns (address);

    /// @notice Returns the address of the OfficerUpgradeable contract managing the profile.
    function OFFICER() external view returns (address);

    /// @notice Returns the address of the 'base' token.
    function BASE() external view returns (address);

    /// @notice Returns the address of the 'quote' token.
    function QUOTE() external view returns (address);

    /// @notice Returns the address of the DEX used corresponding to the DEX_ID.
    /// @dev Returns the DEX router address.
    function getDexAddress() external view returns (address);

    /// @notice Returns the DEX type. (1: Uniswap V2-like, 2: TraderJoe-like etc.)
    function DEX_TYPE() external view returns (uint256);

    /// @notice Returns the ID of the DEX used.
    function DEX_ID() external view returns (uint256);

    /// @notice Returns the address of the Beacon contract used to deploy receivers.
    /// @dev The beacon contract contains a pointer to the implementation contract.
    function RECEIVER_BEACON() external view returns (address);

    /// @notice Returns the address of the VaultMainUpgradeable contract of the profile.
    function MAIN_VAULT() external view returns (address);

    /// @notice Returns the address of the VaultVolumeUpgradeable contract of the profile.
    function VOLUME_VAULT() external view returns (address);

    /// @notice Returns the address of the VaultLimitUpgradeable contract of the profile.
    function LIMIT_VAULT() external view returns (address);

    /// @notice Returns whether the profile is paused. Pausing a profile is equivalent to pausing all vaults.
    function profilePaused() external view returns (bool);

    /// @notice Returns whether the momot wallet is paused. This restricts transfers from other vaults to the momot wallet.
    function momotPaused() external view returns (bool);

    /// @notice Returns the address of the Momot wallet.
    /// @dev Privileged users can send funds from the profile to this wallet.
    function momot() external view returns (address);

    /// @notice Returns the address of the receiver contract corresponding to the ID.
    function receivers(uint256 id) external view returns (address);

    /// @notice Returns the address of the last used receiver contract.
    function prevReceiver() external view returns (address);

    /// @notice Returns the type of the last used vault.
    function prevVault() external view returns (VaultType);

    /// @notice Returns the address of the receiver contract to be used for the swap.
    /// @dev This is called by the vaults on each swap that uses receivers.
    function requestReceiver(VaultType vault) external returns (address);

    /// @notice Returns the address of the vault.
    function getVaultAddress(VaultType vault) external view returns (address);

    /// @notice Returns all the receiver contracts.
    function getReceivers() external view returns (address[] memory);

    /// @notice Returns the amount of oracle permissions used by `address`.
    function nonces(address) external view returns (uint256);

    /// @notice Returns whether a permission is valid and matches the parameters provided.
    /// @dev This calls OfficerUpgradeable.hasPermission().
    /// @param user The address of the user.
    /// @param contract_ The address of the contract interacted with.
    /// @param expiresAt The timestamp at which the permission expires.
    /// @param nonce The nonce of the permission.
    /// @param data Function call data.
    /// @param signature The permission itself (the signature).
    /// @return has Whether the permission is valid.
    function hasPermission(
        address user,
        address contract_,
        uint256 expiresAt,
        uint256 nonce,
        bytes calldata data,
        bytes calldata signature
    ) external returns (bool has);

    /// @notice Returns whether the account has any of the profile level roles provided.
    /// @param roles The profile level roles to check.
    /// @param account The address of the account.
    function hasRoles(
        bytes32[] memory roles,
        address account
    ) external view returns (bool);

    /// @notice Marks the entire profile as paused. Pausing a profile is equivalent to pausing all vaults.
    function setProfilePaused(bool paused) external;

    /// @notice Marks the momot wallet as paused. This prevents transferring funds from other vaults to the momot wallet.
    function setMomotPaused(bool paused) external;

    /// @notice Sets the address of the Momot wallet.
    function setMomot(address momot_) external;

    struct InitParams {
        address deployer;
        address officer;
        address base;
        address quote;
        uint256 dexType;
        uint256 dexId;
        address receiverBeacon;
        address mainVault;
        address mmVault;
        address limitVault;
        address momot;
        address[] receivers;
        address[] executorsVolume;
        address[] executorsLimit;
        address[] withdrawers;
    }

    /// @notice Initializes the contract.
    function init(InitParams calldata params) external;

    /// @notice Grants roles to accounts.
    /// @dev The caller is subject to access control checks of the `grantRole` function.
    function batchGrantRoles(
        bytes32[] calldata roles,
        address[] calldata accounts
    ) external;

    /// @notice Revokes roles from accounts.
    /// @dev The caller is subject to access control checks of the `revokeRole` function.
    function batchRevokeRoles(
        bytes32[] calldata roles,
        address[] calldata accounts
    ) external;

    /// @notice Revokes WITHDRAWER_ROLE from `accounts`. Can only be called by the superadmin.
    function revokeWithdrawer(address[] calldata accounts) external;

    /// @notice Returns the address of the Manager contract managing the profile.
    function manager() external view returns (address);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ProfileTokens, Order} from '../utils/Structures.sol';
import {IAccessControlUpgradeable} from '@openzeppelin/contracts-upgradeable/access/IAccessControlUpgradeable.sol';

/**
 * @title IOfficerUpgradeable
 * @author gotbit
 * @notice Interface for the OfficerUpgradeable contract.
 * @dev The OfficerUpgradeable contract is the main contract of the system.
 * It's responsible for global roles, checking oracle permissions and managing DEXes.
 * Note that it is not responsible for managing and deploying profiles.
 * Profile contracts read from the Officer contract but don't write,
 * eliminating the need for access control for profiles.
 */

interface IOfficerUpgradeable is IAccessControlUpgradeable {
    // read

    /// @notice Returns the unique identifier for the superadmin role.
    function SUPERADMIN_ROLE() external view returns (bytes32);

    /// @notice Returns the unique identifier for the admin role.
    function ADMIN_ROLE() external view returns (bytes32);

    /// @notice Returns the address of the superadmin.
    function superAdmin() external view returns (address);

    /// @notice Returns the timestamp at which the user can withdraw funds.
    /// @dev Used only in adminWithdraw() available to ADMIN_ROLE.
    function withdrawCooldown(address user) external view returns (uint256);

    /// @notice Returns whether `account` has any of the global roles provided.
    /// @param roles The global level roles to check.
    /// @param account The address to check.
    function hasRoles(
        bytes32[] memory roles,
        address account
    ) external view returns (bool);

    /// @dev Returns whether a permission is valid and matches the parameters provided.
    /// @param permissionOracle The signer of the permission.
    /// @param user The address of the user.
    /// @param contract_ The address of the contract interacted with.
    /// @param expiresAt The timestamp at which the permission expires.
    /// @param nonce The nonce of the permission.
    /// @param data Function call data.
    /// @param signature The permission itself (the signature).
    /// @return Whether the permission is valid.
    function hasPermission(
        address permissionOracle,
        address user,
        address contract_,
        uint256 expiresAt,
        uint256 nonce,
        bytes calldata data,
        bytes calldata signature
    ) external view returns (bool);

    /// @notice Returns the DEX address associated with a DEX ID.
    /// @param dexId The ID of the DEX.
    /// @return The address of the DEX.
    function getDexAddress(uint256 dexId) external view returns (address);

    // write

    /// @notice Sets the superadmin address.
    /// @dev The old superadmin loses his role.
    /// @param superAdmin_ The new superadmin.
    function setSuperAdmin(address superAdmin_) external;

    /// @notice Grants roles to accounts.
    /// @dev The caller is subject to access control checks of the `grantRole` function.
    function batchGrantRoles(
        bytes32[] calldata roles,
        address[] calldata accounts
    ) external;

    /// @notice Revokes roles from accounts.
    /// @dev The caller is subject to access control checks of the `revokeRole` function.
    function batchRevokeRoles(
        bytes32[] calldata roles,
        address[] calldata accounts
    ) external;

    /// @notice Allows the admin to withdraw funds with a 6 hour cooldown.
    /// @param vault The vault to withdraw from.
    /// @param token The token to withdraw.
    /// @param to The address to send the funds to.
    /// @param amount The amount of tokens to withdraw.
    function adminWithdraw(
        address vault,
        address token,
        address to,
        uint256 amount
    ) external;

    /// @notice Initializes the contract.
    /// @param superAdmin_ The address of the superadmin.
    /// @param dexAddresses The addresses of the DEXes. Index is the DEX ID.
    function init(address superAdmin_, address[] calldata dexAddresses) external;

    /// @notice Sets the DEX addresses associated with the specified DEX IDs.
    /// @param dexIds The IDs of the DEXes.
    /// @param dexAddresses The addresses of the DEXes.
    function batchSetDexAddress(
        uint256[] calldata dexIds,
        address[] calldata dexAddresses
    ) external;

    // function checkWithdrawCooldown(address user) external;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title IReceiverUpgradeable
 * @author gotbit
 * @notice Interface for the ReceiverUpgradeable contract.
 * @dev Receivers are responsible for receiving tokens from swaps
 * to make our bots slightly less noticeable.
 */

interface IReceiverUpgradeable {
    /// @dev Returns the manager address.
    /// @return The manager address.
    function manager() external view returns (address);

    /// @notice Returns the ID of the receiver.
    function receiverId() external view returns (uint256);

    /// @notice Initializes the contract.
    /// @param manager_ The address of the profile manager.
    /// @param receiverId_ The ID of the receiver to be returned by receiverId().
    function init(address manager_, uint256 receiverId_) external;

    /// @notice Withdraws tokens from the receiver.
    /// @dev Is supposed to be called by the profile manager to return the funds from the swap.
    /// @param token The address of the token to be withdrawn.
    /// @param to The address to which the tokens will be sent.
    /// @param amount The amount of tokens to be withdrawn.
    function withdraw(address token, address to, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {IManagerUpgradeable} from '../interfaces/IManagerUpgradeable.sol';

library OraclePermission {
    struct Data {
        uint256 permExpiresAt;
        uint256 nonce;
        bytes signature;
    }

    function has(address manager, Data calldata data) internal returns (bool) {
        return
            IManagerUpgradeable(manager).hasPermission(
                msg.sender,
                address(this),
                data.permExpiresAt,
                data.nonce,
                msg.data[0:(msg.data.length - 256)],
                data.signature
            );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

abstract contract Roles {
    bytes32 internal constant DEPLOYER_ROLE = keccak256('DEPLOYER');
    bytes32 internal constant WITHDRAWER_ROLE = keccak256('WITHDRAWER');
    bytes32 internal constant EXECUTOR_VOLUME_ROLE = keccak256('EXECUTOR_VOLUME');
    bytes32 internal constant EXECUTOR_LIMIT_ROLE = keccak256('EXECUTOR_LIMIT');
    bytes32 internal constant ADMIN_ROLE = keccak256('ADMIN');
    bytes32 internal constant SUPERADMIN_ROLE = 0x00;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

enum ProfileTokens {
    BASE,
    QUOTE,
    LIQUIDITY
}

enum Direction {
    BUY,
    SELL
}

enum VaultType {
    MAIN,
    VOLUME,
    LIMIT,
    MOMOT
}

struct Order {
    uint256 price_min;
    uint256 price_max;
    uint256 volume;
    Direction dir;
}

struct VaultSwapParams {
    Direction direction;
    bool useReceiver;
    uint256 amountIn; // quote
    uint256 amountOut; // base
    uint256 deadline;
}