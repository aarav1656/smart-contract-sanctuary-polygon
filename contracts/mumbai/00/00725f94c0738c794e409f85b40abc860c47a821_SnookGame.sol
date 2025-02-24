/**
 *Submitted for verification at polygonscan.com on 2022-08-28
*/

// Sources flattened with hardhat v2.9.5 https://hardhat.org

// File @openzeppelin/contracts-upgradeable/proxy/utils/[email protected]

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
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


// File @openzeppelin/contracts-upgradeable/utils/[email protected]


pragma solidity ^0.8.0;

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}


// File @openzeppelin/contracts-upgradeable/utils/[email protected]


pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant alphabet = "0123456789abcdef";

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
            buffer[i] = alphabet[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

}


// File @openzeppelin/contracts-upgradeable/utils/introspection/[email protected]


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


// File @openzeppelin/contracts-upgradeable/utils/introspection/[email protected]


pragma solidity ^0.8.0;


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
    function __ERC165_init() internal initializer {
        __ERC165_init_unchained();
    }

    function __ERC165_init_unchained() internal initializer {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }
    uint256[50] private __gap;
}


// File @openzeppelin/contracts-upgradeable/access/[email protected]


pragma solidity ^0.8.0;




/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
    function hasRole(bytes32 role, address account) external view returns (bool);
    function getRoleAdmin(bytes32 role) external view returns (bytes32);
    function grantRole(bytes32 role, address account) external;
    function revokeRole(bytes32 role, address account) external;
    function renounceRole(bytes32 role, address account) external;
}

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
    function __AccessControl_init() internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __AccessControl_init_unchained();
    }

    function __AccessControl_init_unchained() internal initializer {
    }
    struct RoleData {
        mapping (address => bool) members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

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
     * bearer except when using {_setupRole}.
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
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlUpgradeable).interfaceId
            || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if(!hasRole(role, account)) {
            revert(string(abi.encodePacked(
                "AccessControl: account ",
                StringsUpgradeable.toHexString(uint160(account), 20),
                " is missing role ",
                StringsUpgradeable.toHexString(uint256(role), 32)
            )));
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
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
     * If the calling account had been granted `role`, emits a {RoleRevoked}
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
        emit RoleAdminChanged(role, getRoleAdmin(role), adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
    uint256[49] private __gap;
}


// File @openzeppelin/contracts-upgradeable/utils/structs/[email protected]


pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSetUpgradeable {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}


// File @openzeppelin/contracts-upgradeable/access/[email protected]


pragma solidity ^0.8.0;



/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerableUpgradeable {
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}

/**
 * @dev Extension of {AccessControl} that allows enumerating the members of each role.
 */
abstract contract AccessControlEnumerableUpgradeable is Initializable, IAccessControlEnumerableUpgradeable, AccessControlUpgradeable {
    function __AccessControlEnumerable_init() internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __AccessControl_init_unchained();
        __AccessControlEnumerable_init_unchained();
    }

    function __AccessControlEnumerable_init_unchained() internal initializer {
    }
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    mapping (bytes32 => EnumerableSetUpgradeable.AddressSet) private _roleMembers;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlEnumerableUpgradeable).interfaceId
            || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view override returns (address) {
        return _roleMembers[role].at(index);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view override returns (uint256) {
        return _roleMembers[role].length();
    }

    /**
     * @dev Overload {grantRole} to track enumerable memberships
     */
    function grantRole(bytes32 role, address account) public virtual override {
        super.grantRole(role, account);
        _roleMembers[role].add(account);
    }

    /**
     * @dev Overload {revokeRole} to track enumerable memberships
     */
    function revokeRole(bytes32 role, address account) public virtual override {
        super.revokeRole(role, account);
        _roleMembers[role].remove(account);
    }

    /**
     * @dev Overload {renounceRole} to track enumerable memberships
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        super.renounceRole(role, account);
        _roleMembers[role].remove(account);
    }

    /**
     * @dev Overload {_setupRole} to track enumerable memberships
     */
    function _setupRole(bytes32 role, address account) internal virtual override {
        super._setupRole(role, account);
        _roleMembers[role].add(account);
    }
    uint256[49] private __gap;
}


// File @openzeppelin/contracts-upgradeable/security/[email protected]


pragma solidity ^0.8.0;


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
    function __Pausable_init() internal initializer {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal initializer {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
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
        require(paused(), "Pausable: not paused");
        _;
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
    uint256[49] private __gap;
}


// File contracts/ISkillToken.sol


pragma solidity >=0.5.0;

interface ISkillToken {
    // IERC20Metadata
    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);

    // IERC20
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);    
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    // SnookGame extension
    function burn(address, uint256) external;
}


// File @openzeppelin/contracts-upgradeable/access/[email protected]


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
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    uint256[49] private __gap;
}


// File @openzeppelin/contracts-upgradeable/token/ERC721/[email protected]


pragma solidity ^0.8.0;

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
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
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}


// File @openzeppelin/contracts-upgradeable/token/ERC721/[email protected]


pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}


// File @openzeppelin/contracts-upgradeable/token/ERC721/extensions/[email protected]


pragma solidity ^0.8.0;

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721MetadataUpgradeable is IERC721Upgradeable {

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


// File @openzeppelin/contracts-upgradeable/utils/[email protected]


pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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


// File @openzeppelin/contracts-upgradeable/token/ERC721/[email protected]


pragma solidity ^0.8.0;








/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721Upgradeable is Initializable, ContextUpgradeable, ERC165Upgradeable, IERC721Upgradeable, IERC721MetadataUpgradeable {
    using AddressUpgradeable for address;
    using StringsUpgradeable for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping (uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping (address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping (uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping (address => mapping (address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    function __ERC721_init(string memory name_, string memory symbol_) internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __ERC721_init_unchained(name_, symbol_);
    }

    function __ERC721_init_unchained(string memory name_, string memory symbol_) internal initializer {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return interfaceId == type(IERC721Upgradeable).interfaceId
            || interfaceId == type(IERC721MetadataUpgradeable).interfaceId
            || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
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
        return bytes(baseURI).length > 0
            ? string(abi.encodePacked(baseURI, tokenId.toString()))
            : '';
    }

    /**
     * @dev Base URI for computing {tokenURI}. Empty by default, can be overriden
     * in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(_msgSender() == owner || isApprovedForAll(owner, _msgSender()),
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
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
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
    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
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
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal virtual {
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
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
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
    function _safeMint(address to, uint256 tokenId, bytes memory _data) internal virtual {
        _mint(to, tokenId);
        require(_checkOnERC721Received(address(0), to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
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
        address owner = ERC721Upgradeable.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
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
    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        require(ERC721Upgradeable.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721Upgradeable.ownerOf(tokenId), to, tokenId);
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
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data)
        private returns (bool)
    {
        if (to.isContract()) {
            try IERC721ReceiverUpgradeable(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721ReceiverUpgradeable(to).onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    // solhint-disable-next-line no-inline-assembly
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
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual { }
    uint256[44] private __gap;
}


// File @openzeppelin/contracts-upgradeable/token/ERC721/extensions/[email protected]


pragma solidity ^0.8.0;



/**
 * @title ERC721 Burnable Token
 * @dev ERC721 Token that can be irreversibly burned (destroyed).
 */
abstract contract ERC721BurnableUpgradeable is Initializable, ContextUpgradeable, ERC721Upgradeable {
    function __ERC721Burnable_init() internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __ERC721Burnable_init_unchained();
    }

    function __ERC721Burnable_init_unchained() internal initializer {
    }
    /**
     * @dev Burns `tokenId`. See {ERC721-_burn}.
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator.
     */
    function burn(uint256 tokenId) public virtual {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721Burnable: caller is not owner nor approved");
        _burn(tokenId);
    }
    uint256[50] private __gap;
}


// File @openzeppelin/contracts-upgradeable/token/ERC721/extensions/[email protected]


pragma solidity ^0.8.0;

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721EnumerableUpgradeable is IERC721Upgradeable {

    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}


// File @openzeppelin/contracts-upgradeable/token/ERC721/extensions/[email protected]


pragma solidity ^0.8.0;



/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721EnumerableUpgradeable is Initializable, ERC721Upgradeable, IERC721EnumerableUpgradeable {
    function __ERC721Enumerable_init() internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __ERC721Enumerable_init_unchained();
    }

    function __ERC721Enumerable_init_unchained() internal initializer {
    }
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165Upgradeable, ERC721Upgradeable) returns (bool) {
        return interfaceId == type(IERC721EnumerableUpgradeable).interfaceId
            || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Upgradeable.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721EnumerableUpgradeable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
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
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721Upgradeable.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721Upgradeable.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
    uint256[46] private __gap;
}


// File @openzeppelin/contracts/utils/introspection/[email protected]


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


// File @openzeppelin/contracts/utils/introspection/[email protected]


pragma solidity ^0.8.0;

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


// File @openzeppelin/contracts/utils/[email protected]


pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented or decremented by one. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }
}


// File contracts/SnookToken.sol


pragma solidity ^0.8.0;






// about tokenURI in v4: https://forum.openzeppelin.com/t/function-settokenuri-in-erc721-is-gone-with-pragma-0-8-0/5978

contract SnookToken is ERC721Upgradeable, ERC721BurnableUpgradeable, ERC721EnumerableUpgradeable, OwnableUpgradeable {
    event Locked(address indexed from, uint tokenId, bool locked, string reason);

    using Counters for Counters.Counter;
    
    Counters.Counter private _tokenIds;
    mapping (uint => string) private _tokenURIs;
    mapping (uint => bool ) private _locked;
    
    address private _game;
    address private _afterdeath;
    address private _UNUSED;

    mapping(uint => uint[2]) private _UNUSED2; 
    address private _UNUSED3; 
    mapping(uint=>uint) _tokenKillerToken;

    address private _marketplace;

    modifier onlyGameContracts {
      require(
        msg.sender == _game ||         
        msg.sender == _afterdeath ||
        msg.sender == _marketplace,
        'SnookToken: Not game contracts'
      );
      _;
    }

    function initialize(
      address game,
      address afterdeath,
      //address sge,
      string memory tokenName,
      string memory tokenSymbol
    ) initializer public {
        __ERC721_init(tokenName, tokenSymbol);
        __ERC721Burnable_init();
        __ERC721Enumerable_init();
        __Ownable_init();

        _game = game;
        _afterdeath = afterdeath;
        //_sge = sge;

    }
    
    function initialize3(address marketplace) public {
      require(_marketplace == address(0), 'SnookToken: already initialized');
      _marketplace = marketplace;
    }

    

    function setKillerTokenId(uint tokenId, uint killerTokenId) public onlyGameContracts {
      _tokenKillerToken[tokenId] = killerTokenId;
    } 

    function getKillerTokenId(uint tokenId) public view returns (uint) {
      require(_exists(tokenId), "SnookToken: token does not exist");
      return _tokenKillerToken[tokenId];
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return _tokenURIs[tokenId];
    }
    
    // used by resurrection from Game constract
    function setTokenURI(uint256 tokenId, string memory tokenURI_) public onlyGameContracts() {  
        require(_exists(tokenId), "ERC721Metadata: URI set of nonexistent token");
        _tokenURIs[tokenId] = tokenURI_;
    }

    function mint(address to, string memory tokenURI_) public onlyGameContracts() returns (uint256)
    {
        _tokenIds.increment(); // start token sequence from 1
        uint256 tokenId = _tokenIds.current();
        _mint(to, tokenId);  
        setTokenURI(tokenId, tokenURI_);
        return tokenId;
    }

    function multimint(address to, string[] calldata tokenURIs) 
      external onlyGameContracts() returns (uint[] memory) 
    {
      uint[] memory tokenIds = new uint[](tokenURIs.length);
      for (uint i=0; i<tokenURIs.length; i++) {
        tokenIds[i] = mint(to, tokenURIs[i]);
      }
      return tokenIds;
    }

    function burn(uint256 tokenId) public virtual override onlyGameContracts() {
        _burn(tokenId);
    }

    function exists(uint256 tokenId) public view returns(bool) {
      return _exists(tokenId);
    }

    // lock token if it's in play
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) 
        internal virtual 
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable) 
    {
        super._beforeTokenTransfer(from, to, tokenId);
        require(_locked[tokenId] == false, 'SnookToken: Token is locked');
    }

    // https://forum.openzeppelin.com/t/derived-contract-must-override-function-supportsinterface/6315/2
    function supportsInterface(bytes4 interfaceId) public view 
      virtual override(ERC721Upgradeable, ERC721EnumerableUpgradeable) 
      returns (bool) 
    {
        return super.supportsInterface(interfaceId);
    }

    function lock(uint tokenId, bool on, string memory reason) external onlyGameContracts() {
        _locked[tokenId] = on;
        emit Locked(ownerOf(tokenId), tokenId, on, reason);
    } 

    function isLocked(uint tokenId) view external returns (bool) {
        require(_exists(tokenId) == true, "ERC721: isLocked query for nonexistent token");
        return _locked[tokenId];
    }
}


// File contracts/IDescriptorUser.sol

pragma solidity ^0.8.0;

// https://ethereum.stackexchange.com/questions/27259/how-can-you-share-a-struct-definition-between-contracts-in-separate-files
interface IDescriptorUser {
  struct Descriptor {
    uint score;
    uint stars;
    uint traitCount;

    uint resurrectionPrice;
    uint resurrectionCount;
    uint onResurrectionScore;
    uint onResurrectionStars;
    uint onResurrectionTraitCount;
    string onResurrectionTokenURI;

    // required to recalculate probability density on exit from the game
    uint onGameEntryTraitCount; 
    uint deathTime;
    bool gameAllowed; // UNUSED; 
  
    uint lives; 
    bool forSale;

    bytes32 skinId;
    bytes32 onResurrectionSkinId; 

  }
}


// File contracts/ISnookState.sol

pragma solidity ^0.8.0;

interface ISnookState is IDescriptorUser { 
  function getSnookGameAddress() external view returns (address);
  function getMarketplaceAddress() external view returns (address);
  function getAfterdeathAddress() external view returns (address);
  
  function getDescriptor(uint tokenId) external view returns(Descriptor memory);
  function setDescriptor(uint tokenId, Descriptor memory descriptor) external;
  function setDescriptors(uint[] calldata tokenIds, Descriptor[] calldata descriptors) external;

  function deleteDescriptor(uint tokenId) external;
}


// File contracts/IAfterdeath.sol

pragma solidity ^0.8.0;

interface IAfterdeath {
  event Resurrection(address indexed from, uint tokenId);
  event Bury(uint startIdx, uint endIdx);
  event Fusion(uint tokenId);

  function getUniswapUSDCSkillAddress() external view returns (address);
  function getSnookStateAddress() external view returns (address);
  function getSNOOKAddress() external view returns (address);
  function getSNKAddress() external view returns (address);
  function getBurialDelayInSeconds() external view  returns(uint);
  function getTreasuryAddress() external view returns (address);
  function getSnookGameAddress() external view returns (address);
  function getTraitHist() external view returns (uint64[] memory);  
  function getAliveSnookCount() external view returns (uint);

  function updateOnMint(uint traitCount, uint snookCount) external;
  function updateOnExtraction(uint onGameEntryTraitCount, uint traitCount) external;
  function updateOnDeath(uint traitCount) external;
  function resurrect(uint256 tokenId) external;
  function getResurrectionPrice(uint256 tokenId) external view returns (uint256 price);

  function fuseSnooks(
    uint256[2] calldata snookIds, 
    uint256[2] calldata snookTraitCounts,
    uint256 price,
    uint256 proposalTimestamp,
    bytes32 skinId,
    string calldata tokenURI,
    bytes calldata signature) external;

  function getFusionProposalExpirationPeriodInSeconds() external view returns(uint);
  function setFusionProposalExpirationPeriodInSeconds(uint secs) external;

  function getFusionProposal(uint[2] calldata snookIds) external view 
    returns (uint, uint[2] memory);

  function toMorgue(uint tokenId) external;
  function bury(uint requestedBurials) external;
  
  function getMorgue(uint startIdx, uint endIdx) external view returns(uint[] memory);
  function getRemovedFromMorgue(uint startIdx, uint endIdx) external view  returns(uint[] memory);
  function getMorgueLength() external view returns (uint);
  function getRemovedFromMorgueLength() external view returns (uint);
  
}


// File contracts/IUniswapUSDCSkill.sol

pragma solidity >=0.6.6;

interface IUniswapUSDCSkill {
  function getSnookPriceInSkills() external view returns (uint);
}


// File contracts/ISnookGame.sol

pragma solidity ^0.8.0;

interface ISnookGame is IDescriptorUser {
  event GameAllowed(address indexed from, uint tokenId);
  event Entry(address indexed from, uint tokenId);
  event Extraction(address indexed to, uint tokenId);
  event Death(
    address indexed to, 
    uint tokenId, 
    uint killerTokenId, 
    uint remainingLives,
    uint killerChainId
  );
  event Killing(
    address indexed to,
    uint tokenId,
    uint killedTokenId,
    uint killedChainId
  );
  event Birth2(address indexed to, uint tokenId, uint price, uint traitId);
  event PpkClaimed(address indexed to, uint rewardsAmount);

  struct ExtendedDescriptor {
    uint id;
    string uri;
    bool isLocked;
    Descriptor descriptor;
  }

  function getBurnSafeAddress() view external returns(address);
  function isBridged() view external returns(bool);
  function getSNOOKAddress() external view returns (address);
  function getSNKAddress() external view returns (address);
  function getSnookStateAddress() external view returns (address);
  function getAfterdeathAddress() external view returns (address);
  function getUniswapUSDCSkillAddress() external view returns (address);
  function getKillerRole() external pure returns(bytes32);
  function getPauserRole() external pure returns(bytes32);
  function getExtractorRole() external pure returns(bytes32);
  function getEmergencyExtractorRole() external pure returns(bytes32);

  function describe(uint tokenId) external view returns (Descriptor memory d);
  function mint2(uint count) external returns (uint[] memory);
  function mint(uint count, uint partnerId) external returns (uint[] memory);
  function enterGame2(uint256 tokenId) external;

  function extractSnooksWithoutUpdate(uint256[] memory tokenIds) external;
  
  function extractSnook(
    uint256 tokenId, 
    uint traitCount, 
    uint stars, 
    uint score, 
    string calldata tokenURI_,
    bytes32 skinId
  ) external;
  
  function reportKilled(
    uint tokenId,
    uint traitCount,
    uint stars,
    bytes32 skinId,
    string calldata tokenURI,
    uint killerTokenId,
    bool unlock,
    uint killerChainId // for log only
  ) external;
  
  function reportKiller(
    uint tokenId,
    uint killedTokenId,   // for log only
    uint killedChainId    // for log only
  ) external;

  function getPpkCounter() view external returns(uint);
  function increamentPpkCounter() external;
  function computePpk() view external returns (uint);
  function getKillsAndComputePpkRewards(address account) 
    view external returns (uint kills, uint rewardsAmount);
  function claimPpkRewards() external;
  function getLivesPerSnook() external pure returns(uint);

  function pause() external;
  function unpause() external;

  // ladder specific
  struct SpecialSkinIdCount {
    bytes32 id;
    uint count;
  }
  function increaseSpecialSkinIdCounter(bytes32 skinId) external; 
  function decreaseSpecialSkinIdCounter(bytes32 skinId) external;
  function getTotalSpecialSkinIdCount() view external returns(uint);
  function getSpecialSkinIdCounts(uint startIdx, uint endIdx) external view 
    returns(SpecialSkinIdCount[] memory);
  // end of ladder specific
}


// File contracts/IPRNG.sol


pragma solidity ^0.8.0;

interface IPRNG {
  function generate() external;
  function read(uint64 max) external returns (uint64);
}


// File contracts/ILadder.sol

pragma solidity ^0.8.0;

uint constant PRIZE_HEAD_LENGTH = 3; 
uint constant PRIZE_TAIL_LENGTH = 5; // (=R)
uint constant PRIZE_TAIL_GROUP_SIZE = 20;
interface ILadder {
  event SeasonCreated(uint seasonNumber);
  
  struct Player {
    address account;
    uint chainId;
    uint points;
    uint gamesPlayed;
  }

  struct Winner {
    address account;
    uint chainId;
    uint place;
    uint prizeAmount;
  }

  struct Season {
    uint id;
    bool areWinnersReported;
    bool isPrizeAmountDistributedBetweenChains;
    uint prizeAmount;
    uint[PRIZE_HEAD_LENGTH] prizeHead;
    uint[PRIZE_TAIL_LENGTH] prizeTail;
    uint[2] seasonInterval;
    uint[2][4] weekendIntervals;
  }

  function reportGamePoints(
    address[] calldata accounts, 
    uint[] calldata chainIds,
    uint[] calldata points
  ) external;
  
  function getPlayerCount(
    uint seasonNumber, 
    uint chainId
  ) external view returns(uint);
  
  function getPlayers(
    uint chainId,
    uint seasonNumber, 
    uint startIdx, 
    uint endIdx
  ) external view returns(Player[] memory);
  
  function getPlayerFor(
    uint chainId,
    uint seasonNumber, 
    address account
  ) external view returns(Player memory);
  
  function reportSeasonWinners(
    address[] calldata accounts, 
    uint[] calldata chainIds,
    uint[] calldata places
  ) external;


  function reserveChainLadderBalance(uint chainId) external;

  function freeChainUnclaimableReservedLadderBalance(uint chainId) external;

  function saveChainLadderBalance(uint chainId) external;

  function distributePrizeFundBetweenChains() external;

  function createSeason(
    uint[2] calldata seasonInterval,
    uint[2][4] calldata weekendIntervals
  ) external;

  function setSeasonInterval(
    uint[2] calldata seasonInterval
  ) external;

  function setSeasonWeekendInterval(
    uint weekendNumber, // 1,2,3 or 4
    uint[2] calldata weekendInterval
  ) external;

  function getActiveSeason() external view
    returns(Season memory);
  
  function getSeasonByNumber(uint seasonNumber) external view
    returns(Season memory);

  function getSeasons(uint startIdx, uint endIdx) external view 
    returns(Season[] memory);

  function getActiveSeasonNumber() external view returns(uint);

  function getSupportedChainIds() external view returns(uint[] memory);
  
  function setSupportedChainIds(uint[] memory) external;
  
  function removeSupportedChainIds(uint[] memory) external;

  function getPauserRole() external pure returns (bytes32);
  
  function getExtractorRole() external pure returns (bytes32);

  function getChainSeasonWinnerCount(uint chainId, uint seasonNumber) 
    external view returns(uint);
  
  function getChainSeasonWinners(
    uint chainId, 
    uint seasonNumber, 
    uint startIdx, 
    uint endIdx
  ) external view returns(Winner[] memory);
  
  function shareWinnersWithChain(uint chainId, uint startIdx, uint endIdx) external;

  function getChainSeasonBalance(uint chainId, uint seasonNumber) 
    external view returns(uint);

  function getPointsPrecision() external pure returns(uint); 

  function getPrimaryChainId() external view returns(uint);

  function purgeSeasons() external;
}


// File contracts/ITreasury.sol


pragma solidity ^0.8.0;

uint constant PayeeCount = 3;

interface ITreasury {
  enum PayeeIds { FOUNDERS, STAKING, SKIN }
  
  event Transfer(address payee, uint amount);
  event MintFundsAccepted(uint amount);
  event ResurrectionFundsAccepted(uint amount);
  event AcceptedFundsDistributed(uint amountPpk, uint amountStaking, uint amountTournaments);

  function transfer() external;
  function getPayees() external view returns (address[PayeeCount] memory);
  function getSharesInCentipercents() external view returns (uint[PayeeCount] memory);
  function getCyclesInDays() external view returns (uint[PayeeCount] memory);
  function getPayTimes() external view returns (uint[PayeeCount] memory);
  function getSecondsInDay() external view returns (uint);
  function getSNKAddress() external view returns (address);

  // ev2
  function getPpkBalance() external view returns (uint);
  function getTournamentsBalance() external view returns (uint);
  function getLpStakingBalance() external view returns (uint);
  function acceptMintFunds(uint amount) external; 
  function acceptResurrectionFunds(uint amount) external;
  
  function payPpkRewards(address recipient, uint amount) external;

  // luckwheel
  function mintLuckWheelSNOOK(address to) external returns(uint);
  function awardLuckWheelSNK(address to, uint prizeAmount) external;

  // ladder
  function acceptSeasonWinners(
    uint seasonNumber, 
    ILadder.Winner[] memory winners
  ) external;
  function getWinnerFor(
    address account,
    uint seasonNumber 
  ) external view returns(ILadder.Winner memory);
  function claimPrizeFor(
    address account, 
    uint seasonNumber
  ) external;
  function purgeLadderWinner(
    address account,
    uint seasonNumber
  ) external;
  function reserveTournamentsBalance(uint amount) external;
  function getReservedTournamentsBalance() external view returns(uint);
  function freeUnclaimableReservedTournamentsBalance(uint amount) external;
}


// File contracts/IPartnerList.sol

pragma solidity ^0.8.0;

interface IPartnerList { 
  struct Partner {
    uint id;
    string name;
    address account;
    uint shareInCentiPercents;
  }

  event PartnerAdded(uint id);
  event PartnerRemoved(uint id);

  function addPartner(string memory name, address account, uint shareInCentiPercents) external;
  function getPartnerCount() external view returns(uint);
  function getPartners(uint startIdx, uint endIdx) external view returns(Partner[] memory); 
  function removePartner(uint partnerId) external;
  function getPartnerById(uint id) external view returns(Partner memory);
  function getPauserRole() pure external returns(bytes32);

}


// File contracts/SnookGame.sol


pragma solidity ^0.8.0;












// about tokenURI in v4: https://forum.openzeppelin.com/t/function-settokenuri-in-erc721-is-gone-with-pragma-0-8-0/5978

contract SnookGame is ISnookGame, AccessControlEnumerableUpgradeable, PausableUpgradeable {
    bytes32 private constant BASIC_SKIN_ID = 'S000'; //0x5330303000000000000000000000000000000000000000000000000000000000;

    uint private constant LIVES_PER_SNOOK = 5;
    uint public constant TRAITCOUNT_MINT2 = 1;

    bytes32 private constant EXTRACTOR_ROLE = keccak256("EXTRACTOR_ROLE");
    bytes32 private constant EMERGENCY_EXTRACTOR_ROLE = keccak256("EMERGENCY_EXTRACTOR_ROLE");
    bytes32 private constant KILLER_ROLE = keccak256("KILLER_ROLE");
    bytes32 private constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    string private constant IPFS_URL_PREFIX = 'ipfs://';

    uint private constant BASE_COLORS = 0;
    uint64 private constant LENGTH_COLORS = 20;

    uint private constant BASE_PATTERNS = BASE_COLORS + LENGTH_COLORS;
    uint64 private constant LENGTH_PATTERNS = 20;

    uint private constant BASE_WEARABLE_UPPER_BODY = BASE_PATTERNS + LENGTH_PATTERNS;
    uint64 private constant LENGTH_WEARABLE_UPPER_BODY = 3;

    uint private constant BASE_WEARABLE_BOTTOM_BODY = BASE_WEARABLE_UPPER_BODY + LENGTH_WEARABLE_UPPER_BODY;
    uint64 private constant LENGTH_WEARABLE_BOTTOM_BODY = 3;

    uint private constant BASE_WEARABLE_UPPER_HEAD = BASE_WEARABLE_BOTTOM_BODY + LENGTH_WEARABLE_BOTTOM_BODY;
    uint64 private constant LENGTH_WEARABLE_UPPER_HEAD = 3;

    uint private constant BASE_WEARABLE_BOTTOM_HEAD = BASE_WEARABLE_UPPER_HEAD + LENGTH_WEARABLE_UPPER_HEAD;
    uint64 private constant LENGTH_WEARABLE_BOTTOM_HEAD = 3;

    uint public constant MINT_BURN_PERCENTAGE = 20;
    uint public constant MINT_ECOSYSTEM_PERCENTAGE = 4;
    uint public constant MINT_TREASURY_PERCENTAGE = 76;

    SnookToken private _snook;
    ISkillToken private _skill;
    IUniswapUSDCSkill private _uniswap;
    // ISkinRewards private _skinRewards;
    IPartnerList private _partnerList; // has non-default value (removed skinRewards contract address)
    ISnookState private _state;
    IAfterdeath private _afterdeath;

    IPRNG private _prng;
    string[52] private _mintTokenCIDs;

    // ev2
    uint private _spc; // adjusted on reward claim;
    mapping(address => uint) private accountKills;
    address private _ecosystem;  
    ITreasury private _treasury; 

    address private _burnsafe;
    bool private _isBridged;
    bool private _isInitialized4;

    // ladder-related
    /// @dev _specialSkinIdCount is per network.
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.Bytes32Set;
    mapping(bytes32=>uint) private _specialSkinIdCount;
    EnumerableSetUpgradeable.Bytes32Set private _specialSkinIds;

    // partner related
    bool private _isInitialized5;

    /// Start of partner-related functions
    function initialize5(address partnerList) public {
      require(_isInitialized5 == false, 'Already executed');
      _partnerList = IPartnerList(partnerList);
    }
    /// End of partner-related functions

    /// Start of ladder specific functions
    /**
      @dev
      Does not check validity of skin id but checks that stars and skin id in valid relation.
      That is, 0 stars means basic skin with id S000.
      Stars 1-4 mean special skin ids with Sxyz.
      Validity of skin id is checked in the Ladder contract.
    */ 
    modifier withValidStarsSkinIdRelation(uint stars, bytes32 skinId) {
      require(
        stars == 0 && skinId == 'S000' ||
        stars >= 1 && stars <= 4 && skinId != 'S000',
        "Invalid stars/skin" 
      );
      _;
    }

    modifier onlyAfterdeath() {
      require(
        msg.sender == address(_afterdeath),
        "Not afterdeath"
      );
      _;
    }

    // TODO: remove after Ladder init (skin updates)
    modifier onlyAfterdeathOrDeployer() {
      require(
        msg.sender == address(_afterdeath) || 
        hasRole(EXTRACTOR_ROLE, msg.sender) == true,
        "Not afterdeath"
      );
      _;
    }

    modifier withValidSkinId(bytes32 skinId) {
      require(skinId[0] == 'S', "Invalid skin id");
      for (uint8 i=1; i<4; i++) {
        require(skinId[i] >= '0' && skinId[i] <= '9', "Invalid skin id");
      }
      _;
    }

    // TODO: remove after Ladder init
    function updateDescriptorWithSkinId(
      uint tokenId, 
      bytes32 skinId
    ) external onlyAfterdeathOrDeployer() withValidSkinId(skinId) {
      Descriptor memory d = _state.getDescriptor(tokenId);

      require(
        d.stars == 0 && skinId == 'S000' ||
        d.stars >= 1 && d.stars <= 4 && skinId != 'S000',
        "Invalid stars/skin" 
      );

      d.skinId = skinId;
      _state.setDescriptor(tokenId, d);
    }

    // TODO : remove after ladder upgrade
    //  Used to fix snooks with invalid stars.
    function setSnookStars(
      uint tokenId, 
      uint stars
    ) public onlyAfterdeathOrDeployer() {
      Descriptor memory d = _state.getDescriptor(tokenId);
      d.stars = stars;
      _state.setDescriptor(tokenId, d);
    }

    // TODO: remove after ladder upgrade
    //  Used to fix special skin counters.
    function setSpecialSkinIdCounter(
      bytes32 skinId, 
      uint count
    ) public onlyAfterdeathOrDeployer() withValidSkinId(skinId) {
      _specialSkinIdCount[skinId] = count;
    }

    function _increaseSpecialSkinIdCounter(bytes32 skinId) 
      internal withValidSkinId(skinId) 
    {
      // ignore non-special skin ids  
      if (skinId == BASIC_SKIN_ID) {
        return;
      }

      if (!_specialSkinIds.contains(skinId)) {
        _specialSkinIds.add(skinId);
      }
      _specialSkinIdCount[skinId] += 1; 
    }

    /// TODO: change to onlyAfterdeath after Ladder init
    function increaseSpecialSkinIdCounter(bytes32 skinId) 
      external override onlyAfterdeathOrDeployer() 
    {
      _increaseSpecialSkinIdCounter(skinId);
    }

    function _decreaseSpecialSkinIdCounter(bytes32 skinId) 
      internal withValidSkinId(skinId) 
    {
      // ignore non-special skin ids  
      if (skinId == BASIC_SKIN_ID) {
        return;
      }

      require(_specialSkinIdCount[skinId] > 0, "No such special skin");
      _specialSkinIdCount[skinId] -= 1;
      if (_specialSkinIdCount[skinId] == 0) {
        _specialSkinIds.remove(skinId);
      }
    }

    function decreaseSpecialSkinIdCounter(bytes32 skinId) onlyAfterdeath() external override 
    {
      _decreaseSpecialSkinIdCounter(skinId);
    }

    function getTotalSpecialSkinIdCount() view external override returns(uint) {
      return _specialSkinIds.length();
    }   

    function getSpecialSkinIdCounts(uint startIdx, uint endIdx) 
      external override view returns(SpecialSkinIdCount[] memory) 
    {
      require(
        startIdx < endIdx &&
        endIdx <= _specialSkinIds.length(),
        "Invalid indexes"
      );
      SpecialSkinIdCount[] memory result = new SpecialSkinIdCount[](endIdx-startIdx);
      for (uint i=startIdx; i<endIdx; i++) {
        bytes32 id = _specialSkinIds.at(i);
        uint count = _specialSkinIdCount[id];
        result[i-startIdx] = SpecialSkinIdCount({
          id: id,
          count: count
        });   
      } 
      return result;
    }
    /// End of ladder-specific functions

    function getBurnSafeAddress() view external override returns(address) {
      return _burnsafe; 
    }

    function isBridged() view external override returns(bool) {
      return _isBridged;
    }

    function getSNOOKAddress() external override view returns (address) {
      return address(_snook);
    }

    function getSNKAddress() external override view returns (address) {
      return address(_skill);
    }

    function getUniswapUSDCSkillAddress() external override view returns (address) {
      return address(_uniswap);
    }

    function getSnookStateAddress() external override view returns (address) {
      return address(_state);
    }

    function getAfterdeathAddress() external override view returns (address) {
      return address(_afterdeath);
    }

    function getLivesPerSnook() external override pure returns (uint) {
      return LIVES_PER_SNOOK;
    }

    function getKillerRole() external override pure returns(bytes32) {
      return KILLER_ROLE;
    }

    function getPauserRole() external override pure returns(bytes32) {
      return PAUSER_ROLE;
    }

    function getExtractorRole() external override pure returns(bytes32) {
      return EXTRACTOR_ROLE;
    }

    function getEmergencyExtractorRole() external override pure returns(bytes32) {
      return EMERGENCY_EXTRACTOR_ROLE;
    }

    function initialize(
        address state, 
        address snook, 
        address skill, 
        address uniswap,
        address afterdeath,
        address adminAccount 
    ) initializer public {
        __AccessControlEnumerable_init();
        __Pausable_init();
        _uniswap = IUniswapUSDCSkill(uniswap);
        _snook = SnookToken(snook);
        _skill = ISkillToken(skill);
        _state = ISnookState(state);
        _afterdeath = IAfterdeath(afterdeath);

        _setupRole(DEFAULT_ADMIN_ROLE, adminAccount);
        _setupRole(PAUSER_ROLE, adminAccount);
    }

    function initialize2(
      address prng,
      string[52] memory mintTokenCIDs
    ) public {
      require(address(_prng) == address(0), 'SnookGame: already executed');
      _prng = IPRNG(prng);
      _mintTokenCIDs = mintTokenCIDs;
    }

    // ev2

    function initialize3(address ecosystem, address treasury) public {
      require(_ecosystem == address(0), 'Already executed');
      _ecosystem = ecosystem;
      _treasury = ITreasury(treasury);
      _spc = _afterdeath.getAliveSnookCount();
    }

    function initialize4(bool isBridged_, address burnsafe) public {
      require(_isInitialized4 == false, 'Already executed');
      _isBridged = isBridged_;
      _burnsafe = burnsafe;
      _isInitialized4 = true;
    }

    function increamentPpkCounter() external override onlyAfterdeath {
      _spc++;
    }

    function getPpkCounter() view external override returns(uint) {
      return _spc;
    }

    function describe(uint tokenId) external override view returns (Descriptor memory d)
    {
      d = _state.getDescriptor(tokenId);
    }

    function extendedDescribe(address owner, uint startIdx, uint endIdx) public view 
      returns(ExtendedDescriptor[] memory)
    {
      require(startIdx < endIdx && endIdx <= _snook.balanceOf(owner), "Invalid indexes");
      ExtendedDescriptor[] memory eds = new ExtendedDescriptor[](endIdx - startIdx);
      for (uint i=startIdx; i<endIdx; i++) {
        uint tokenId = _snook.tokenOfOwnerByIndex(owner, i);
        eds[i-startIdx] = ExtendedDescriptor({
          id: tokenId,
          uri: _snook.tokenURI(tokenId),
          isLocked: _snook.isLocked(tokenId),
          descriptor: _state.getDescriptor(tokenId)
        });
      }
      return eds;
    }

    function strConcat(string memory s1, string memory s2) pure internal returns (string memory) {
      bytes memory b1 = bytes(s1);
      bytes memory b2 = bytes(s2);
      bytes memory b3 = new bytes(b1.length + b2.length);
      uint i = 0;
      for (uint j=0; j<b1.length; j++) {
        b3[i++] = b1[j];
      }
      for (uint j=0; j<b2.length; j++) {
        b3[i++] = b2[j];
      }
      return string(b3);
    }
    
    function _generateTokenURI() internal returns (string memory, uint) {
      _prng.generate();
      uint traitId = _prng.read(27) + 1; // getRnd(1,27)
      string memory tokenURI = '';
      uint base = 0;
      uint offset = 0;
      

      if (traitId >= 1 && traitId <=5) {
        base = BASE_COLORS;
        offset = _prng.read(LENGTH_COLORS); // rnd[0,19]
      } 
      else if (traitId >= 6 && traitId <= 15) { 
        base = BASE_PATTERNS;
        offset = _prng.read(LENGTH_PATTERNS); // rnd[0,19]
      } 
      else if (traitId >= 16 && traitId <=18) {
        base = BASE_WEARABLE_UPPER_BODY;
        offset = _prng.read(LENGTH_WEARABLE_UPPER_BODY); // rnd[0,2] 
      }

      else if (traitId >= 19 && traitId <= 21) {
        base = BASE_WEARABLE_BOTTOM_BODY;
        offset = _prng.read(LENGTH_WEARABLE_BOTTOM_BODY);
      }

      else if (traitId >= 22 && traitId <= 24) {
        base = BASE_WEARABLE_UPPER_HEAD; // rnd[16,18]
        offset = _prng.read(LENGTH_WEARABLE_UPPER_HEAD);
      }

      else if (traitId >= 25 && traitId <= 27) {
        base = BASE_WEARABLE_BOTTOM_HEAD;
        offset = _prng.read(LENGTH_WEARABLE_BOTTOM_HEAD);
      }

      else { // exception 
      }

      tokenURI = strConcat(IPFS_URL_PREFIX, _mintTokenCIDs[base+offset]);
      return (tokenURI, traitId);
    }

    // TODO: remove after upgrade
    function mint2(uint count) external override whenNotPaused() returns (uint[] memory){
      return _mint(count, 0);
    }

    // TODO: when mint2 is removed, no need in _mint(): mint() can include function body of _mint().
    function mint(uint count, uint partnerId) external override whenNotPaused() returns (uint[] memory){
      return _mint(count, partnerId);
    }

    function _mint(uint count, uint partnerId) internal returns (uint[] memory){
      require(count > 0, 'SnookGame: should be greater than 0');
      
      uint price = _uniswap.getSnookPriceInSkills();
      uint amountPaid = count * price * LIVES_PER_SNOOK;

      require(
        _skill.transferFrom(
          msg.sender, // from 
          address(this),  // to 
          amountPaid
        ), 
        'SnookGame: No funds'
      );
      
      string[] memory tokenURIs = new string[](count);
      Descriptor[] memory descriptors = new Descriptor[](count);

      for (uint i=0; i<count; i++) {
        (string memory tokenURI, ) = _generateTokenURI();
        tokenURIs[i] = tokenURI;

        descriptors[i] = Descriptor({
            score: 0,
            onResurrectionScore: 0,
            stars: 0,
            onResurrectionStars: 0,
            onGameEntryTraitCount: TRAITCOUNT_MINT2,
            traitCount: TRAITCOUNT_MINT2,
            onResurrectionTraitCount: 0,
            onResurrectionSkinId: BASIC_SKIN_ID,
            onResurrectionTokenURI: "",
            deathTime: 0,
            resurrectionPrice: 0,
            resurrectionCount: 0,
            gameAllowed: false,
            lives: LIVES_PER_SNOOK,
            forSale: false,
            skinId: BASIC_SKIN_ID
        });
      }

      uint[] memory tokenIds = _snook.multimint(msg.sender, tokenURIs);
      _state.setDescriptors(tokenIds, descriptors); 
      
      _spc += count * LIVES_PER_SNOOK;
      uint amountToBurn = amountPaid * MINT_BURN_PERCENTAGE / 100;

      if (_isBridged == false) {
        _skill.burn(address(this), amountToBurn);
      } else {
        _skill.transfer(_burnsafe, amountToBurn);
      }
        
      uint amountToTreasury = amountPaid * MINT_TREASURY_PERCENTAGE / 100;
      // let treasury pull it's part from this contract and distribute it as it wants
      _skill.approve(address(_treasury), amountToTreasury);     
      _treasury.acceptMintFunds(amountToTreasury);

      uint amountToEcosystem = amountPaid - amountToBurn - amountToTreasury;

      if (partnerId != 0) {
        IPartnerList.Partner memory partner = _partnerList.getPartnerById(partnerId);
        uint amountToPartner = amountToEcosystem * partner.shareInCentiPercents / 100 / 100;
        _skill.transfer(partner.account, amountToPartner);
        amountToEcosystem = amountToEcosystem - amountToPartner;
      }
      _skill.transfer(_ecosystem, amountToEcosystem);
      _afterdeath.updateOnMint(TRAITCOUNT_MINT2*count, count);
      return tokenIds;
    }

    function enterGame2(uint256 tokenId) external override whenNotPaused() {
      require(msg.sender == _snook.ownerOf(tokenId), 'Not snook owner');
      require(_snook.isLocked(tokenId) == false, 'In play');
      _snook.lock(tokenId, true, 'enterGame2');
      emit Entry(_snook.ownerOf(tokenId), tokenId);
    }

    // extract snook without updating traits and url
    function _extractSnookWithoutUpdate(uint256 tokenId) private {
      Descriptor memory d = _state.getDescriptor(tokenId);
      require(_snook.isLocked(tokenId) == true, 'Not in play');
      require(d.deathTime == 0, 'Dead');
      _snook.lock(tokenId, false, 'emergencyExtract');
      emit Extraction(_snook.ownerOf(tokenId), tokenId);
    }

    // Extracts snooks with ids without updating traits and uris. 
    // Called on GS failure.
    // Can be replaced by looping over _extractFromGame from WS, but we want to save gas. 
    function extractSnooksWithoutUpdate(uint256[] memory tokenIds) 
      external override onlyRole(EMERGENCY_EXTRACTOR_ROLE) whenNotPaused()
    {
      for (uint i = 0; i < tokenIds.length; i++) {
        _extractSnookWithoutUpdate(tokenIds[i]);
      }
    }

    // function extractSnook(
    //   uint256 tokenId, 
    //   uint traitCount, 
    //   uint stars, 
    //   uint score, 
    //   string calldata tokenURI_
    // ) external override onlyRole(EXTRACTOR_ROLE) whenNotPaused()
    // {
    //   Descriptor memory d = _state.getDescriptor(tokenId);
    //   require(_snook.isLocked(tokenId) == true, 'Not in play');
    //   require(d.deathTime == 0, 'Dead');

    //   require(stars<=4, 'SnookGame: cannot assign more than 4 stars');

    //   _afterdeath.updateOnExtraction(d.onGameEntryTraitCount, traitCount);
    //   _snook.setTokenURI(tokenId, tokenURI_); 
    //   d.traitCount = traitCount; 
    //   d.onGameEntryTraitCount = traitCount;
    //   d.stars = stars;
    //   d.score = score;
    
    //   _state.setDescriptor(tokenId, d);
    //   _snook.lock(tokenId, false, 'extract');

    //   emit Extraction(_snook.ownerOf(tokenId), tokenId);
    // }

    // called by WS when snook successfully extracts snook
    function extractSnook(
      uint256 tokenId, 
      uint traitCount, 
      uint stars, 
      uint score, 
      string calldata tokenURI_,
      bytes32 skinId
    ) onlyRole(EXTRACTOR_ROLE) 
      whenNotPaused() 
      withValidStarsSkinIdRelation(stars, skinId)
      external override
    {
      Descriptor memory d = _state.getDescriptor(tokenId);
      require(_snook.isLocked(tokenId) == true, 'Not in play');
      require(d.deathTime == 0, 'Dead');

      _afterdeath.updateOnExtraction(d.onGameEntryTraitCount, traitCount);
      _snook.setTokenURI(tokenId, tokenURI_); 
      d.traitCount = traitCount; 
      d.onGameEntryTraitCount = traitCount;
      d.stars = stars;
      d.score = score;
      
      if (d.skinId != 0x0) { /// TODO: for mumbai only, plastyr
        _decreaseSpecialSkinIdCounter(d.skinId);
      }
      d.skinId = skinId;
      _increaseSpecialSkinIdCounter(skinId);
      
      _state.setDescriptor(tokenId, d);
      _snook.lock(tokenId, false, 'extract');

      emit Extraction(_snook.ownerOf(tokenId), tokenId);
    }

    
    function reportKiller(
      uint tokenId,
      uint killedTokenId,   // for log only
      uint killedChainId    // for log only
    ) external override onlyRole(KILLER_ROLE) whenNotPaused 
    {
      require(_snook.exists(tokenId) == true, 'SnookGame: killer token does not exist');
      address account = _snook.ownerOf(tokenId);
      accountKills[account] += 1;

      emit Killing(
        _snook.ownerOf(tokenId),
        tokenId,
        killedTokenId, 
        killedChainId
      );
    }

    // function reportKilled(
    //   uint tokenId,
    //   uint traitCount,
    //   uint stars,
    //   string calldata tokenURI,
    //   uint killerTokenId,
    //   bool unlock,
    //   uint killerChainId // for log only
    // ) external override onlyRole(KILLER_ROLE) whenNotPaused
    // {
    //   Descriptor memory d = _state.getDescriptor(tokenId);
    //   require(_snook.isLocked(tokenId) == true, 'SnookGame: not in play'); // prevent wallet server from errors
    //   require(d.deathTime == 0, 'SnookGame: token is already dead');

    //   if (killerTokenId == tokenId) {
    //     _spc -= 1;
    //   }

    //   if (d.lives > 0) {
    //     d.lives -= 1;
    //   }
     
    //   if (d.lives == 0) { 
    //     d.deathTime = block.timestamp;
    //     d.resurrectionPrice = _afterdeath.getResurrectionPrice(tokenId);
    //     d.onResurrectionTraitCount = traitCount;
    //     d.onResurrectionStars = stars; 
    //     d.onResurrectionTokenURI = tokenURI;
    //     _afterdeath.toMorgue(tokenId);
    //     _afterdeath.updateOnDeath(d.traitCount);
    //   } else { // lives > 0 therefore we look at unlock request by user
    //     if (unlock == true) {
    //       _snook.lock(tokenId, false, 'unlock by user');
    //     }
    //   }
    //   _state.setDescriptor(tokenId, d);
    //   emit Death(_snook.ownerOf(tokenId), tokenId, killerTokenId, d.lives, killerChainId);
    // }

    function reportKilled(
      uint tokenId,
      uint traitCount,
      uint stars,
      bytes32 skinId,
      string calldata tokenURI,
      uint killerTokenId,
      bool unlock,
      uint killerChainId // for log only
    ) external override onlyRole(KILLER_ROLE) whenNotPaused
    {
      Descriptor memory d = _state.getDescriptor(tokenId);
      require(_snook.isLocked(tokenId) == true, 'SnookGame: not in play'); // prevent wallet server from errors
      require(d.deathTime == 0, 'SnookGame: token is already dead');

      if (killerTokenId == tokenId) {
        _spc -= 1;
      }

      if (d.lives > 0) {
        d.lives -= 1;
      }
    
      if (d.lives == 0) { 
        d.deathTime = block.timestamp;
        d.resurrectionPrice = _afterdeath.getResurrectionPrice(tokenId);
        d.onResurrectionTraitCount = traitCount;
        d.onResurrectionStars = stars; 
        d.onResurrectionSkinId = skinId;
        d.onResurrectionTokenURI = tokenURI;
        _afterdeath.toMorgue(tokenId);
        _afterdeath.updateOnDeath(d.traitCount);

        // When all descriptors are updated correctly with Sxxx skin ids, no need for check.
        // This check is equal to { if skin id is UPDATED then do decrese because decrease checks for skin id validity}
        if (d.skinId != 0x0) { /// TODO: for DEBUG only, plastyr for Yarik
          _decreaseSpecialSkinIdCounter(d.skinId);
        }
      } else { // lives > 0 therefore we look at unlock request by user
        if (unlock == true) {
          _snook.lock(tokenId, false, 'unlock by user');
        }
      }
      _state.setDescriptor(tokenId, d);
      emit Death(_snook.ownerOf(tokenId), tokenId, killerTokenId, d.lives, killerChainId);
    }

    function _computePpk() view internal returns (uint) {
      uint ppk = 0;
      if (_spc > 0) {
        ppk = _treasury.getPpkBalance() / _spc;
      }
      return ppk;
    }

    function computePpk() view external override returns(uint) {
      return _computePpk();
    }

    function _getKillsAndComputePpkRewards(address account) view internal returns(uint, uint) {
      uint rewards = _computePpk() * accountKills[account];
      return (accountKills[account], rewards);
    }

    function getKillsAndComputePpkRewards(address account) view external override returns(uint, uint) {
      return _getKillsAndComputePpkRewards(account);
    }

    function claimPpkRewards() external override {
      address account = msg.sender;
      (, uint rewardsAmount) = _getKillsAndComputePpkRewards(account);
      require(rewardsAmount>0, 'No rewards');
      _spc -= accountKills[account];
      accountKills[account] = 0;
      _treasury.payPpkRewards(account, rewardsAmount);
      emit PpkClaimed(account, rewardsAmount);
    }

    function pause() external override onlyRole(PAUSER_ROLE) whenNotPaused() {
      _pause();
    }

    function unpause() external override onlyRole(PAUSER_ROLE) whenPaused() {
      _unpause();
    }
}