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
// OpenZeppelin Contracts v4.4.1 (access/AccessControl.sol)

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
        __Context_init_unchained();
        __ERC165_init_unchained();
        __AccessControl_init_unchained();
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
        _checkRole(role, _msgSender());
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
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
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
// OpenZeppelin Contracts v4.4.1 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

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
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
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
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

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

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

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
        assembly {
            size := extcodesize(account)
        }
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
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal onlyInitializing {
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
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
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
        __ERC165_init_unchained();
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }
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

//SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "@openzeppelin/contracts-0.8/access/Ownable.sol";
import "../common/BaseWithStorage/ERC2771Handler.sol";
import "../common/interfaces/IAssetMinter.sol";
import "../catalyst/GemsCatalystsRegistry.sol";
import "../common/interfaces/IPolygonAssetERC1155.sol";

/// @notice Allow to mint Asset with Catalyst, Gems and Sand, giving the assets attributes through AssetAttributeRegistry
contract AssetMinter is ERC2771Handler, IAssetMinter, Ownable {
    uint32 public numberOfGemsBurnPerAsset = 1;
    uint32 public numberOfCatalystBurnPerAsset = 1;

    IAssetAttributesRegistry internal immutable _registry;
    IPolygonAssetERC1155 internal immutable _assetERC1155;
    GemsCatalystsRegistry internal immutable _gemsCatalystsRegistry;

    mapping(uint16 => uint256) public quantitiesByCatalystId;
    mapping(uint16 => uint256) public quantitiesByAssetTypeId; // quantities for asset that don't use catalyst to burn (art, prop...)
    mapping(address => bool) public customMinterAllowance;

    event CustomMintingAllowanceChanged(address indexed addressModified, bool indexed isAddressCustomMintingAllowed);
    event TrustedForwarderChanged(address indexed newTrustedForwarderAddress);
    event QuantitiesByCatalystIdChanged(uint256 indexed id, uint256 indexed newValue);
    event QuantitiesByAssetTypeIdChanged(uint256 indexed index, uint256 indexed newValue);
    event NumberOfGemsBurnPerAssetChanged(uint256 indexed newValue);
    event NumberOfCatalystBurnPerAssetChanged(uint256 indexed newValue);

    /// @notice AssetMinter depends on
    /// @param registry: AssetAttributesRegistry for recording catalyst and gems used
    /// @param assetERC1155: Asset ERC1155 Token Contract
    /// @param gemsCatalystsRegistry: that track the canonical catalyst and gems and provide batch burning facility
    /// @param trustedForwarder: address of the trusted forwarder (used for metaTX)
    constructor(
        IAssetAttributesRegistry registry,
        IPolygonAssetERC1155 assetERC1155,
        GemsCatalystsRegistry gemsCatalystsRegistry,
        address admin,
        address trustedForwarder,
        uint256[] memory quantitiesByCatalystId_,
        uint256[] memory quantitiesByAssetTypeId_
    ) {
        require(address(registry) != address(0), "AssetMinter: registry can't be zero");
        require(address(assetERC1155) != address(0), "AssetMinter: assetERC1155 can't be zero");
        require(address(gemsCatalystsRegistry) != address(0), "AssetMinter: gemsCatalystsRegistry can't be zero");
        _registry = registry;
        _assetERC1155 = assetERC1155;
        _gemsCatalystsRegistry = gemsCatalystsRegistry;
        transferOwnership(admin);
        __ERC2771Handler_initialize(trustedForwarder);

        require(quantitiesByCatalystId_.length > 0, "AssetMinter: quantitiesByCatalystID length cannot be 0");
        require(quantitiesByAssetTypeId_.length > 0, "AssetMinter: quantitiesByAssetTypeId length cannot be 0");

        for (uint16 i = 0; i < quantitiesByCatalystId_.length; i++) {
            quantitiesByCatalystId[i + 1] = quantitiesByCatalystId_[i];
        }

        for (uint16 i = 0; i < quantitiesByAssetTypeId_.length; i++) {
            quantitiesByAssetTypeId[i + 1] = quantitiesByAssetTypeId_[i];
        }
    }

    function addOrReplaceQuantityByCatalystId(uint16 catalystId, uint256 newQuantity) external override onlyOwner {
        quantitiesByCatalystId[catalystId] = newQuantity;
        emit QuantitiesByCatalystIdChanged(catalystId, newQuantity);
    }

    function addOrReplaceAssetTypeQuantity(uint16 index1Based, uint256 newQuantity) external override onlyOwner {
        quantitiesByAssetTypeId[index1Based] = newQuantity;
        emit QuantitiesByAssetTypeIdChanged(index1Based, newQuantity);
    }

    function setNumberOfGemsBurnPerAsset(uint32 newQuantity) external override onlyOwner {
        numberOfGemsBurnPerAsset = newQuantity;
        emit NumberOfGemsBurnPerAssetChanged(newQuantity);
    }

    function setNumberOfCatalystsBurnPerAsset(uint32 newQuantity) external override onlyOwner {
        numberOfCatalystBurnPerAsset = newQuantity;
        emit NumberOfCatalystBurnPerAssetChanged(newQuantity);
    }

    function setCustomMintingAllowance(address addressToModify, bool isAddressAllowed) external override onlyOwner {
        customMinterAllowance[addressToModify] = isAddressAllowed;

        emit CustomMintingAllowanceChanged(addressToModify, isAddressAllowed);
    }

    /// @notice mint "quantity" number of Asset token using one catalyst.
    /// @param mintData (-from address creating the Asset, need to be the tx sender or meta tx signer.
    ///  -packId unused packId that will let you predict the resulting tokenId.
    /// - metadataHash cidv1 ipfs hash of the folder where 0.json file contains the metadata.
    /// - to destination address receiving the minted tokens.
    /// - data extra data)
    /// @param catalystId Id of the Catalyst ERC20 token to burn (1, 2, 3 or 4).
    /// @param gemIds list of gem ids to burn in the catalyst.
    /// @param quantity number of token to mint
    /// @return assetId The new token Id.
    function mintCustomNumberWithCatalyst(
        MintData calldata mintData,
        uint16 catalystId,
        uint16[] calldata gemIds,
        uint256 quantity,
        uint256 _numberOfCatalystBurnPerAsset,
        uint256 _numberOfGemsBurnPerAsset
    ) external override returns (uint256 assetId) {
        require(
            customMinterAllowance[_msgSender()] == true || _msgSender() == owner(),
            "AssetMinter: custom minting unauthorized"
        );
        require(
            _numberOfCatalystBurnPerAsset == numberOfCatalystBurnPerAsset,
            "AssetMinter: invalid numberOfCatalystBurnPerAsset value "
        );
        require(
            _numberOfGemsBurnPerAsset == numberOfGemsBurnPerAsset,
            "AssetMinter: invalid numberOfGemsBurnPerAsset value"
        );
        assetId = _burnAndMint(mintData, catalystId, gemIds, quantity);
    }

    /// @notice mint "quantity" number of Asset token without using a catalyst.
    /// @param mintData (-from address creating the Asset, need to be the tx sender or meta tx signer.
    ///  -packId unused packId that will let you predict the resulting tokenId.
    /// - metadataHash cidv1 ipfs hash of the folder where 0.json file contains the metadata.
    /// - to destination address receiving the minted tokens.
    /// - data extra data)
    /// @param quantity number of token to mint
    /// @return assetId The new token Id.
    function mintCustomNumberWithoutCatalyst(MintData calldata mintData, uint256 quantity)
        external
        override
        returns (uint256 assetId)
    {
        require(
            customMinterAllowance[_msgSender()] == true || _msgSender() == owner(),
            "AssetMinter: custom minting unauthorized"
        );
        _mintRequirements(mintData.from, quantity, mintData.to);
        assetId = _assetERC1155.mint(
            mintData.from,
            mintData.packId,
            mintData.metadataHash,
            quantity,
            mintData.to,
            mintData.data
        );
    }

    /// @notice mint one Asset token with no catalyst.
    /// @param mintData : (-from address creating the Asset, need to be the tx sender or meta tx signer.
    ///  -packId unused packId that will let you predict the resulting tokenId.
    /// - metadataHash cidv1 ipfs hash of the folder where 0.json file contains the metadata.
    /// - to destination address receiving the minted tokens.
    /// - data extra data)
    /// @param typeAsset1Based (art, prop...) decide how many asset will be minted (start at 1)
    /// @return assetId The new token Id.
    function mintWithoutCatalyst(
        MintData calldata mintData,
        uint16 typeAsset1Based,
        uint256 quantity
    ) external override returns (uint256 assetId) {
        require(
            quantity == quantitiesByAssetTypeId[typeAsset1Based],
            "AssetMinter: Invalid quantitiesByAssetType value"
        );

        _mintRequirements(mintData.from, quantity, mintData.to);
        assetId = _assetERC1155.mint(
            mintData.from,
            mintData.packId,
            mintData.metadataHash,
            quantity,
            mintData.to,
            mintData.data
        );
    }

    /// @notice mint multiple Asset tokens using one catalyst.
    /// @param mintData : (-from address creating the Asset, need to be the tx sender or meta tx signer.
    ///  -packId unused packId that will let you predict the resulting tokenId.
    /// - metadataHash cidv1 ipfs hash of the folder where 0.json file contains the metadata.
    /// - to destination address receiving the minted tokens.
    /// - data extra data)
    /// @param catalystId Id of the Catalyst ERC20 token to burn (1, 2, 3 or 4).
    /// @param gemIds list of gem ids to burn in the catalyst.
    /// @return assetId The new token Id.
    function mintWithCatalyst(
        MintData calldata mintData,
        uint16 catalystId,
        uint16[] calldata gemIds,
        uint256 quantity,
        uint256 _numberOfCatalystBurnPerAsset,
        uint256 _numberOfGemsBurnPerAsset
    ) external override returns (uint256 assetId) {
        require(quantity == quantitiesByCatalystId[catalystId], "AssetMinter : Invalid quantitiesByCatalyst value");
        require(
            _numberOfCatalystBurnPerAsset == numberOfCatalystBurnPerAsset,
            "AssetMinter: invalid numberOfCatalystBurnPerAsset value"
        );
        require(
            _numberOfGemsBurnPerAsset == numberOfGemsBurnPerAsset,
            "AssetMinter: invalid numberOfGemsBurnPerAsset value "
        );

        assetId = _burnAndMint(mintData, catalystId, gemIds, quantity);
    }

    /// @notice mint multiple Asset tokens.
    /// @param mintData contains (-from address creating the Asset, need to be the tx sender or meta tx signer
    /// -packId unused packId that will let you predict the resulting tokenId
    /// -metadataHash cidv1 ipfs hash of the folder where 0.json file contains the metadata)
    /// @param assets data (gems and catalyst data)
    function mintMultipleWithCatalyst(
        MintData calldata mintData,
        AssetData[] memory assets,
        uint256[] memory supplies,
        uint256 _numberOfCatalystBurnPerAsset,
        uint256 _numberOfGemsBurnPerAsset
    ) external override returns (uint256[] memory assetIds) {
        uint256 assetsLength = assets.length;
        require(assetsLength != 0, "INVALID_0_ASSETS");
        require(assetsLength == supplies.length, "AssetMinter: supplies and assets length mismatch");
        require(mintData.to != address(0), "INVALID_TO_ZERO_ADDRESS");
        require(
            _numberOfCatalystBurnPerAsset == numberOfCatalystBurnPerAsset,
            "AssetMinter: invalid numberOfCatalystBurnPerAsset value"
        );
        require(
            _numberOfGemsBurnPerAsset == numberOfGemsBurnPerAsset,
            "AssetMinter: invalid numberOfGemsBurnPerAsset value"
        );
        require(_msgSender() == mintData.from, "AUTH_ACCESS_DENIED");

        _handleMultipleAssetRequirements(mintData.from, assets, supplies);
        assetIds = _assetERC1155.mintMultiple(
            mintData.from,
            mintData.packId,
            mintData.metadataHash,
            supplies,
            "",
            mintData.to,
            mintData.data
        );
        for (uint256 i = 0; i < assetIds.length; i++) {
            require(assets[i].catalystId != 0, "AssetMinter: catalystID can't be 0");
            _registry.setCatalyst(assetIds[i], assets[i].catalystId, assets[i].gemIds);
        }
        return assetIds;
    }

    function mintMultipleWithoutCatalyst(
        MintData calldata mintData,
        uint256[] calldata supplies,
        uint16[] calldata assetTypesIds
    ) external override returns (uint256[] memory assetIds) {
        uint256 suppliesLength = supplies.length;
        require(suppliesLength != 0, "INVALID_0_ASSETS");
        require(suppliesLength == assetTypesIds.length, "AssetMinter: supplies and assets length mismatch");
        require(mintData.to != address(0), "INVALID_TO_ZERO_ADDRESS");
        require(_msgSender() == mintData.from, "AUTH_ACCESS_DENIED");
        for (uint256 i = 0; i < suppliesLength; i++) {
            require(
                supplies[i] == quantitiesByAssetTypeId[assetTypesIds[i]],
                "AssetMinter: Invalid quantitiesByAssetType value"
            );
        }
        assetIds = _assetERC1155.mintMultiple(
            mintData.from,
            mintData.packId,
            mintData.metadataHash,
            supplies,
            "",
            mintData.to,
            mintData.data
        );
        return assetIds;
    }

    /// @dev Change the address of the trusted forwarder for meta-TX
    /// @param trustedForwarder The new trustedForwarder
    function setTrustedForwarder(address trustedForwarder) external onlyOwner {
        _trustedForwarder = trustedForwarder;

        emit TrustedForwarderChanged(trustedForwarder);
    }

    /// @dev Handler for dealing with assets when minting multiple at once.
    /// @param from The original address that signed the transaction.
    /// @param assets An array of AssetData structs to define how the total gems and catalysts are to be allocated.
    function _handleMultipleAssetRequirements(
        address from,
        AssetData[] memory assets,
        uint256[] memory supplies
    ) internal {
        uint256[] memory catalystsToBurn = new uint256[](_gemsCatalystsRegistry.getNumberOfCatalystContracts());
        uint256[] memory gemsToBurn = new uint256[](_gemsCatalystsRegistry.getNumberOfGemContracts());

        for (uint256 i = 0; i < assets.length; i++) {
            require(
                assets[i].catalystId > 0 && assets[i].catalystId <= catalystsToBurn.length,
                "AssetMinter: catalystID out of bound"
            );
            catalystsToBurn[assets[i].catalystId - 1]++;
            for (uint256 j = 0; j < assets[i].gemIds.length; j++) {
                require(
                    assets[i].gemIds[j] > 0 && assets[i].gemIds[j] <= gemsToBurn.length,
                    "AssetMinter: gemId out of bound"
                );
                gemsToBurn[assets[i].gemIds[j] - 1]++;
            }

            uint16 maxGems = _gemsCatalystsRegistry.getMaxGems(assets[i].catalystId);
            require(assets[i].gemIds.length <= maxGems, "AssetMinter: too many gems");
            require(
                supplies[i] == quantitiesByCatalystId[assets[i].catalystId],
                "AssetMinter: Invalid quantitiesByAssetType value"
            );
        }
        _batchBurnCatalysts(from, catalystsToBurn);
        _batchBurnGems(from, gemsToBurn);
    }

    /// @dev Burn a batch of catalysts in one tx.
    /// @param from The original address that signed the tx.
    /// @param catalystsQuantities An array of quantities for each type of catalyst to burn.
    function _batchBurnCatalysts(address from, uint256[] memory catalystsQuantities) internal {
        uint16[] memory ids = new uint16[](catalystsQuantities.length);
        for (uint16 i = 0; i < ids.length; i++) {
            ids[i] = i + 1;
        }
        _gemsCatalystsRegistry.batchBurnCatalysts(from, ids, _scaleCatalystQuantities(catalystsQuantities));
    }

    /// @dev Burn a batch of gems in one tx.
    /// @param from The original address that signed the tx.
    /// @param gemsQuantities An array of quantities for each type of gems to burn.
    function _batchBurnGems(address from, uint256[] memory gemsQuantities) internal {
        uint16[] memory ids = new uint16[](gemsQuantities.length);
        for (uint16 i = 0; i < ids.length; i++) {
            ids[i] = i + 1;
        }
        _gemsCatalystsRegistry.batchBurnGems(from, ids, _scaleGemQuantities(gemsQuantities));
    }

    /// @dev Burn an array of gems.
    /// @param from The original signer of the tx.
    /// @param gemIds The array of gems to burn.
    /// @param numTimes Amount of gems to burn.
    function _burnGems(
        address from,
        uint16[] memory gemIds,
        uint32 numTimes
    ) internal {
        uint256[] memory gemFactors = new uint256[](gemIds.length);
        for (uint256 i = 0; i < gemIds.length; i++) {
            gemFactors[i] = 10**(_gemsCatalystsRegistry.getGemDecimals(gemIds[i])) * numTimes;
        }
        _gemsCatalystsRegistry.batchBurnGems(from, gemIds, gemFactors);
    }

    /// @dev Burn a single type of catalyst.
    /// @param from The original signer of the tx.
    /// @param catalystId The type of catalyst to burn.
    /// @param numTimes Amount of catalysts of this type to burn.
    function _burnCatalyst(
        address from,
        uint16 catalystId,
        uint32 numTimes
    ) internal {
        _gemsCatalystsRegistry.burnCatalyst(
            from,
            catalystId,
            numTimes * 10**(_gemsCatalystsRegistry.getCatalystDecimals(catalystId))
        );
    }

    /// @dev Scale up each number in an array of quantities by a factor of gemsUnits.
    /// @param quantities The array of numbers to scale.
    /// @return scaledQuantities The scaled-up values.
    function _scaleGemQuantities(uint256[] memory quantities)
        internal
        view
        returns (uint256[] memory scaledQuantities)
    {
        scaledQuantities = new uint256[](quantities.length);
        for (uint256 i = 0; i < quantities.length; i++) {
            uint256 gemFactor = 10**_gemsCatalystsRegistry.getGemDecimals(uint16(i + 1));
            scaledQuantities[i] = quantities[i] * gemFactor * numberOfGemsBurnPerAsset;
        }
    }

    /// @dev Scale up each number in an array of quantities by a factor of gemsUnits.
    /// @param quantities The array of numbers to scale.
    /// @return scaledQuantities The scaled-up values.
    function _scaleCatalystQuantities(uint256[] memory quantities)
        internal
        view
        returns (uint256[] memory scaledQuantities)
    {
        scaledQuantities = new uint256[](quantities.length);
        for (uint256 i = 0; i < quantities.length; i++) {
            uint256 catalystFactor = 10**_gemsCatalystsRegistry.getCatalystDecimals(uint16(i + 1));
            scaledQuantities[i] = quantities[i] * catalystFactor * numberOfCatalystBurnPerAsset;
        }
    }

    function _msgSender() internal view override(Context, ERC2771Handler) returns (address sender) {
        return ERC2771Handler._msgSender();
    }

    function _msgData() internal view override(Context, ERC2771Handler) returns (bytes calldata) {
        return ERC2771Handler._msgData();
    }

    function _mintRequirements(
        address from,
        uint256 quantity,
        address to
    ) internal view {
        require(to != address(0), "INVALID_TO_ZERO_ADDRESS");
        require(_msgSender() == from, "AUTH_ACCESS_DENIED");
        require(quantity != 0, "AssetMinter: quantity cannot be 0");
    }

    function _burnAndMint(
        MintData calldata mintData,
        uint16 catalystId,
        uint16[] calldata gemIds,
        uint256 quantity
    ) internal returns (uint256 assetId) {
        _mintRequirements(mintData.from, quantity, mintData.to);

        _burnCatalyst(mintData.from, catalystId, numberOfCatalystBurnPerAsset);
        _burnGems(mintData.from, gemIds, numberOfGemsBurnPerAsset);

        assetId = _assetERC1155.mint(
            mintData.from,
            mintData.packId,
            mintData.metadataHash,
            quantity,
            mintData.to,
            mintData.data
        );
        _registry.setCatalyst(assetId, catalystId, gemIds);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import {IGem} from "./interfaces/IGem.sol";
import {ICatalyst, IAssetAttributesRegistry} from "./interfaces/ICatalyst.sol";
import {IERC20Extended, IERC20} from "../common/interfaces/IERC20Extended.sol";
import {IGemsCatalystsRegistry} from "./interfaces/IGemsCatalystsRegistry.sol";
import {ERC2771HandlerUpgradeable} from "../common/BaseWithStorage/ERC2771/ERC2771HandlerUpgradeable.sol";
import {
    AccessControlUpgradeable,
    ContextUpgradeable
} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

/// @notice Contract managing the Gems and Catalysts
/// @notice The following privileged roles are used in this contract: DEFAULT_ADMIN_ROLE, SUPER_OPERATOR_ROLE
/// @dev Each Gems and Catalyst must be registered here.
/// @dev Each new Gem get assigned a new id (starting at 1)
/// @dev Each new Catalyst get assigned a new id (starting at 1)
/// @dev DEFAULT_ADMIN_ROLE is intended for contract setup / emergency, SUPER_OPERATOR_ROLE is provided for business purposes
contract GemsCatalystsRegistry is ERC2771HandlerUpgradeable, IGemsCatalystsRegistry, AccessControlUpgradeable {
    uint256 private constant MAX_GEMS_AND_CATALYSTS = 256;
    uint256 internal constant MAX_UINT256 = type(uint256).max;
    bytes32 public constant SUPER_OPERATOR_ROLE = keccak256("SUPER_OPERATOR_ROLE");

    IGem[] internal _gems;
    ICatalyst[] internal _catalysts;

    event TrustedForwarderChanged(address indexed newTrustedForwarderAddress);
    event AddGemsAndCatalysts(IGem[] gems, ICatalyst[] catalysts);
    event SetGemsAndCatalystsAllowance(address owner, uint256 allowanceValue);

    // solhint-disable-next-line no-empty-blocks
    constructor() initializer {}

    function initV1(address trustedForwarder, address admin) external initializer {
        require(trustedForwarder != address(0), "TRUSTED_FORWARDER_ZERO_ADDRESS");
        require(admin != address(0), "ADMIN_ZERO_ADDRESS");
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        __ERC2771Handler_initialize(trustedForwarder);
        __AccessControl_init();
    }

    /// @notice Returns the values for each gem included in a given asset.
    /// @param catalystId The catalyst identifier.
    /// @param assetId The asset tokenId.
    /// @param events An array of GemEvents. Be aware that only gemEvents from the last CatalystApplied event onwards should be used to populate a query. If gemEvents from multiple CatalystApplied events are included the output values will be incorrect.
    /// @return values An array of values for each gem present in the asset.
    function getAttributes(
        uint16 catalystId,
        uint256 assetId,
        IAssetAttributesRegistry.GemEvent[] calldata events
    ) external view override returns (uint32[] memory values) {
        ICatalyst catalyst = getCatalyst(catalystId);
        require(catalyst != ICatalyst(address(0)), "CATALYST_DOES_NOT_EXIST");
        return catalyst.getAttributes(assetId, events);
    }

    /// @notice Returns the maximum number of gems for a given catalyst
    /// @param catalystId catalyst identifier
    function getMaxGems(uint16 catalystId) external view override returns (uint8) {
        ICatalyst catalyst = getCatalyst(catalystId);
        require(catalyst != ICatalyst(address(0)), "CATALYST_DOES_NOT_EXIST");
        return catalyst.getMaxGems();
    }

    /// @notice Returns the decimals for a given catalyst
    /// @param catalystId catalyst identifier
    function getCatalystDecimals(uint16 catalystId) external view override returns (uint8) {
        ICatalyst catalyst = getCatalyst(catalystId);
        require(catalyst != ICatalyst(address(0)), "CATALYST_DOES_NOT_EXIST");
        return catalyst.getDecimals();
    }

    /// @notice Returns the decimals for a given gem
    /// @param gemId gem identifier
    function getGemDecimals(uint16 gemId) external view override returns (uint8) {
        IGem gem = getGem(gemId);
        require(gem != IGem(address(0)), "GEM_DOES_NOT_EXIST");
        return gem.getDecimals();
    }

    /// @notice Burns few gem units from each gem id on behalf of a beneficiary
    /// @param from address of the beneficiary to burn on behalf of
    /// @param gemIds list of gems to burn gem units from each
    /// @param amounts list of amounts of units to burn
    function batchBurnGems(
        address from,
        uint16[] calldata gemIds,
        uint256[] calldata amounts
    ) external override {
        uint256 gemIdsLength = gemIds.length;
        require(gemIdsLength == amounts.length, "GemsCatalystsRegistry: gemsIds and amounts length mismatch");
        for (uint256 i = 0; i < gemIdsLength; i++) {
            if (gemIds[i] != 0 && amounts[i] != 0) {
                burnGem(from, gemIds[i], amounts[i]);
            }
        }
    }

    /// @notice Burns few catalyst units from each catalyst id on behalf of a beneficiary
    /// @param from address of the beneficiary to burn on behalf of
    /// @param catalystIds list of catalysts to burn catalyst units from each
    /// @param amounts list of amounts of units to burn
    function batchBurnCatalysts(
        address from,
        uint16[] calldata catalystIds,
        uint256[] calldata amounts
    ) external override {
        uint256 catalystIdsLength = catalystIds.length;
        require(catalystIdsLength == amounts.length, "GemsCatalystsRegistry: catalystIds and amounts length mismatch");
        for (uint256 i = 0; i < catalystIdsLength; i++) {
            if (catalystIds[i] != 0 && amounts[i] != 0) {
                burnCatalyst(from, catalystIds[i], amounts[i]);
            }
        }
    }

    /// @notice Adds both arrays of gems and catalysts to registry
    /// @param gems array of gems to be added
    /// @param catalysts array of catalysts to be added
    function addGemsAndCatalysts(IGem[] calldata gems, ICatalyst[] calldata catalysts)
        external
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(
            uint256(_gems.length + _catalysts.length + gems.length + catalysts.length) < MAX_GEMS_AND_CATALYSTS,
            "GemsCatalystsRegistry: Too many gem and catalyst contracts"
        );

        for (uint256 i = 0; i < gems.length; i++) {
            IGem gem = gems[i];
            require(address(gem) != address(0), "GEM_ZERO_ADDRESS");
            uint16 gemId = gem.gemId();
            require(gemId == _gems.length + 1, "GEM_ID_NOT_IN_ORDER");
            _gems.push(gem);
        }

        for (uint256 i = 0; i < catalysts.length; i++) {
            ICatalyst catalyst = catalysts[i];
            require(address(catalyst) != address(0), "CATALYST_ZERO_ADDRESS");
            uint16 catalystId = catalyst.catalystId();
            require(catalystId == _catalysts.length + 1, "CATALYST_ID_NOT_IN_ORDER");
            _catalysts.push(catalyst);
        }
        emit AddGemsAndCatalysts(gems, catalysts);
    }

    /// @notice Set a new trusted forwarder address, limited to DEFAULT_ADMIN_ROLE only
    /// @dev Change the address of the trusted forwarder for meta-TX
    /// @param trustedForwarder The new trustedForwarder
    function setTrustedForwarder(address trustedForwarder) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(trustedForwarder != address(0), "ZERO_ADDRESS");
        _trustedForwarder = trustedForwarder;
        emit TrustedForwarderChanged(trustedForwarder);
    }

    /// @notice Query whether a given gem exists.
    /// @param gemId The gem being queried.
    /// @return Whether the gem exists.
    function doesGemExist(uint16 gemId) external view override returns (bool) {
        return getGem(gemId) != IGem(address(0));
    }

    /// @notice Query whether a giving catalyst exists.
    /// @param catalystId The catalyst being queried.
    /// @return Whether the catalyst exists.
    function doesCatalystExist(uint16 catalystId) external view returns (bool) {
        return getCatalyst(catalystId) != ICatalyst(address(0));
    }

    /// @notice Burn a catalyst.
    /// @param from The signing address for the tx.
    /// @param catalystId The id of the catalyst to burn.
    /// @param amount The number of catalyst tokens to burn.
    function burnCatalyst(
        address from,
        uint16 catalystId,
        uint256 amount
    ) public override checkAuthorization(from) {
        ICatalyst catalyst = getCatalyst(catalystId);
        require(catalyst != ICatalyst(address(0)), "CATALYST_DOES_NOT_EXIST");
        catalyst.burnFor(from, amount);
    }

    /// @notice Burn a gem.
    /// @param from The signing address for the tx.
    /// @param gemId The id of the gem to burn.
    /// @param amount The number of gem tokens to burn.
    function burnGem(
        address from,
        uint16 gemId,
        uint256 amount
    ) public override checkAuthorization(from) {
        IGem gem = getGem(gemId);
        require(gem != IGem(address(0)), "GEM_DOES_NOT_EXIST");
        gem.burnFor(from, amount);
    }

    function getNumberOfCatalystContracts() external view returns (uint256 number) {
        number = _catalysts.length;
    }

    function getNumberOfGemContracts() external view returns (uint256 number) {
        number = _gems.length;
    }

    /// @dev Only the owner, SUPER_OPERATOR_ROLE or APPROVER_ROLE may set the allowance
    function revokeGemsandCatalystsMaxAllowance() external {
        _setGemsAndCatalystsAllowance(0);
    }

    /// @dev Only the owner, SUPER_OPERATOR_ROLE or APPROVER_ROLE may set the allowance
    function setGemsAndCatalystsMaxAllowance() external {
        _setGemsAndCatalystsAllowance(MAX_UINT256);
    }

    /// @dev Get the catalyst contract corresponding to the id.
    /// @param catalystId The catalyst id to use to retrieve the contract.
    /// @return The requested Catalyst contract.
    function getCatalyst(uint16 catalystId) public view returns (ICatalyst) {
        if (catalystId > 0 && catalystId <= _catalysts.length) {
            return _catalysts[catalystId - 1];
        } else {
            return ICatalyst(address(0));
        }
    }

    /// @dev Get the gem contract corresponding to the id.
    /// @param gemId The gem id to use to retrieve the contract.
    /// @return The requested Gem contract.
    function getGem(uint16 gemId) public view returns (IGem) {
        if (gemId > 0 && gemId <= _gems.length) {
            return _gems[gemId - 1];
        } else {
            return IGem(address(0));
        }
    }

    /// @dev verify that the caller is authorized for this function call.
    /// @param from The original signer of the transaction.
    modifier checkAuthorization(address from) {
        require(_msgSender() == from || hasRole(SUPER_OPERATOR_ROLE, _msgSender()), "AUTH_ACCESS_DENIED");
        _;
    }

    function _setGemsAndCatalystsAllowance(uint256 allowanceValue) internal {
        for (uint256 i = 0; i < _gems.length; i++) {
            require(_gems[i].approveFor(_msgSender(), address(this), allowanceValue), "GEM_ALLOWANCE_NOT_APPROVED");
        }

        for (uint256 i = 0; i < _catalysts.length; i++) {
            require(
                _catalysts[i].approveFor(_msgSender(), address(this), allowanceValue),
                "CATALYST_ALLOWANCE_NOT_APPROVED"
            );
        }
        emit SetGemsAndCatalystsAllowance(_msgSender(), allowanceValue);
    }

    function _msgSender()
        internal
        view
        override(ContextUpgradeable, ERC2771HandlerUpgradeable)
        returns (address sender)
    {
        return ERC2771HandlerUpgradeable._msgSender();
    }

    function _msgData() internal view override(ContextUpgradeable, ERC2771HandlerUpgradeable) returns (bytes calldata) {
        return ERC2771HandlerUpgradeable._msgData();
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "../../common/interfaces/IAssetAttributesRegistry.sol";
import "../../common/interfaces/IAttributes.sol";
import "../../common/interfaces/IERC20Extended.sol";

interface ICatalyst is IERC20Extended, IAttributes {
    function catalystId() external returns (uint16);

    function changeAttributes(IAttributes attributes) external;

    function getMaxGems() external view returns (uint8);

    function approveFor(
        address owner,
        address spender,
        uint256 amount
    ) external override returns (bool success);

    function getAttributes(uint256 assetId, IAssetAttributesRegistry.GemEvent[] calldata events)
        external
        view
        override
        returns (uint32[] memory values);

    function getDecimals() external pure returns (uint8);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "../../common/interfaces/IERC20Extended.sol";

interface IGem is IERC20Extended {
    function gemId() external returns (uint16);

    function approveFor(
        address owner,
        address spender,
        uint256 amount
    ) external override returns (bool success);

    function getDecimals() external pure returns (uint8);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "../../common/interfaces/IAssetAttributesRegistry.sol";
import "./IGem.sol";
import "./ICatalyst.sol";

interface IGemsCatalystsRegistry {
    function getAttributes(
        uint16 catalystId,
        uint256 assetId,
        IAssetAttributesRegistry.GemEvent[] calldata events
    ) external view returns (uint32[] memory values);

    function getMaxGems(uint16 catalystId) external view returns (uint8);

    function batchBurnGems(
        address from,
        uint16[] calldata gemIds,
        uint256[] calldata amounts
    ) external;

    function batchBurnCatalysts(
        address from,
        uint16[] calldata catalystIds,
        uint256[] calldata amounts
    ) external;

    function addGemsAndCatalysts(IGem[] calldata gems, ICatalyst[] calldata catalysts) external;

    function doesGemExist(uint16 gemId) external view returns (bool);

    function burnCatalyst(
        address from,
        uint16 catalystId,
        uint256 amount
    ) external;

    function burnGem(
        address from,
        uint16 gemId,
        uint256 amount
    ) external;

    function getCatalystDecimals(uint16 catalystId) external view returns (uint8);

    function getGemDecimals(uint16 gemId) external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// solhint-disable-next-line compiler-version
pragma solidity 0.8.2;

/// @dev minimal ERC2771 handler to keep bytecode-size down
/// based on: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.6.0/contracts/metatx/ERC2771Context.sol
/// with an initializer for proxies and a mutable forwarder
/// @dev same as ERC2771Handler.sol but with gap

contract ERC2771HandlerUpgradeable {
    address internal _trustedForwarder;
    uint256[49] private __gap;

    function __ERC2771Handler_initialize(address forwarder) internal {
        _trustedForwarder = forwarder;
    }

    function isTrustedForwarder(address forwarder) public view returns (bool) {
        return forwarder == _trustedForwarder;
    }

    function getTrustedForwarder() external view returns (address trustedForwarder) {
        return _trustedForwarder;
    }

    function _msgSender() internal view virtual returns (address sender) {
        if (isTrustedForwarder(msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            // solhint-disable-next-line no-inline-assembly
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return msg.sender;
        }
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        if (isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length - 20];
        } else {
            return msg.data;
        }
    }
}

// SPDX-License-Identifier: MIT
// solhint-disable-next-line compiler-version
pragma solidity 0.8.2;

/// @dev minimal ERC2771 handler to keep bytecode-size down
/// based on: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.6.0/contracts/metatx/ERC2771Context.sol
/// with an initializer for proxies and a mutable forwarder

abstract contract ERC2771Handler {
    address internal _trustedForwarder;

    function __ERC2771Handler_initialize(address forwarder) internal {
        _trustedForwarder = forwarder;
    }

    function isTrustedForwarder(address forwarder) public view returns (bool) {
        return forwarder == _trustedForwarder;
    }

    function getTrustedForwarder() external view returns (address trustedForwarder) {
        return _trustedForwarder;
    }

    function _msgSender() internal view virtual returns (address sender) {
        if (isTrustedForwarder(msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            // solhint-disable-next-line no-inline-assembly
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return msg.sender;
        }
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        if (isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length - 20];
        } else {
            return msg.data;
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.2;
pragma experimental ABIEncoderV2;

interface IAssetAttributesRegistry {
    struct GemEvent {
        uint16[] gemIds;
        bytes32 blockHash;
    }

    struct AssetGemsCatalystData {
        uint256 assetId;
        uint16 catalystContractId;
        uint16[] gemContractIds;
    }

    function getRecord(uint256 assetId)
        external
        view
        returns (
            bool exists,
            uint16 catalystId,
            uint16[] memory gemIds
        );

    function getAttributes(uint256 assetId, GemEvent[] calldata events) external view returns (uint32[] memory values);

    function setCatalyst(
        uint256 assetId,
        uint16 catalystId,
        uint16[] calldata gemIds
    ) external;

    function setCatalystWhenDepositOnOtherLayer(
        uint256 assetId,
        uint16 catalystId,
        uint16[] calldata gemIds
    ) external;

    function setCatalystWithBlockNumber(
        uint256 assetId,
        uint16 catalystId,
        uint16[] calldata gemIds,
        uint64 blockNumber
    ) external;

    function addGems(uint256 assetId, uint16[] calldata gemIds) external;

    function setMigrationContract(address _migrationContract) external;

    function getCatalystRegistry() external view returns (address);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import {IERC721Base} from "./IERC721Base.sol";

interface IAssetERC721 is IERC721Base {
    function setTokenURI(uint256 id, string memory uri) external;

    function tokenURI(uint256 id) external view returns (string memory);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.2;
pragma experimental ABIEncoderV2;

interface IAssetMinter {
    struct AssetData {
        uint16[] gemIds;
        uint16 catalystId;
    }

    // use only to fix stack too deep
    struct MintData {
        address from;
        address to;
        uint40 packId;
        bytes32 metadataHash;
        bytes data;
    }

    function mintWithoutCatalyst(
        MintData calldata mintData,
        uint16 typeAsset1Based,
        uint256 quantity
    ) external returns (uint256 assetId);

    function mintWithCatalyst(
        MintData calldata mintData,
        uint16 catalystId,
        uint16[] calldata gemIds,
        uint256 quantity,
        uint256 _numberOfCatalystBurnPerAsset,
        uint256 _numberOfGemsBurnPerAsset
    ) external returns (uint256 assetId);

    function mintMultipleWithCatalyst(
        MintData calldata mintData,
        AssetData[] memory assets,
        uint256[] memory supplies,
        uint256 _numberOfCatalystBurnPerAsset,
        uint256 _numberOfGemsBurnPerAsset
    ) external returns (uint256[] memory assetIds);

    function mintMultipleWithoutCatalyst(
        MintData calldata mintData,
        uint256[] calldata supplies,
        uint16[] calldata assetTypesIds
    ) external returns (uint256[] memory assetIds);

    function mintCustomNumberWithCatalyst(
        MintData calldata mintData,
        uint16 catalystId,
        uint16[] calldata gemIds,
        uint256 quantity,
        uint256 _numberOfCatalystBurnPerAsset,
        uint256 _numberOfGemsBurnPerAsset
    ) external returns (uint256 assetId);

    function mintCustomNumberWithoutCatalyst(MintData calldata mintData, uint256 quantity)
        external
        returns (uint256 assetId);

    function addOrReplaceQuantityByCatalystId(uint16 catalystId, uint256 newQuantity) external;

    function addOrReplaceAssetTypeQuantity(uint16 index1Based, uint256 newQuantity) external;

    function setNumberOfGemsBurnPerAsset(uint32 newQuantity) external;

    function setNumberOfCatalystsBurnPerAsset(uint32 newQuantity) external;

    function setCustomMintingAllowance(address addressToModify, bool isAddressAllowed) external;
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.2;
pragma experimental ABIEncoderV2;

import "../interfaces/IAssetAttributesRegistry.sol";

interface IAttributes {
    function getAttributes(uint256 assetId, IAssetAttributesRegistry.GemEvent[] calldata events)
        external
        view
        returns (uint32[] memory values);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.2;

/// @dev see https://eips.ethereum.org/EIPS/eip-20
interface IERC20 {
    /// @notice emitted when tokens are transfered from one address to another.
    /// @param from address from which the token are transfered from (zero means tokens are minted).
    /// @param to destination address which the token are transfered to (zero means tokens are burnt).
    /// @param value amount of tokens transferred.
    event Transfer(address indexed from, address indexed to, uint256 value);

    /// @notice emitted when owner grant transfer rights to another address
    /// @param owner address allowing its token to be transferred.
    /// @param spender address allowed to spend on behalf of `owner`
    /// @param value amount of tokens allowed.
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /// @notice return the current total amount of tokens owned by all holders.
    /// @return supply total number of tokens held.
    function totalSupply() external view returns (uint256 supply);

    /// @notice return the number of tokens held by a particular address.
    /// @param who address being queried.
    /// @return balance number of token held by that address.
    function balanceOf(address who) external view returns (uint256 balance);

    /// @notice transfer tokens to a specific address.
    /// @param to destination address receiving the tokens.
    /// @param value number of tokens to transfer.
    /// @return success whether the transfer succeeded.
    function transfer(address to, uint256 value) external returns (bool success);

    /// @notice transfer tokens from one address to another.
    /// @param from address tokens will be sent from.
    /// @param to destination address receiving the tokens.
    /// @param value number of tokens to transfer.
    /// @return success whether the transfer succeeded.
    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool success);

    /// @notice approve an address to spend on your behalf.
    /// @param spender address entitled to transfer on your behalf.
    /// @param value amount allowed to be transfered.
    /// @param success whether the approval succeeded.
    function approve(address spender, uint256 value) external returns (bool success);

    /// @notice return the current allowance for a particular owner/spender pair.
    /// @param owner address allowing spender.
    /// @param spender address allowed to spend.
    /// @return amount number of tokens `spender` can spend on behalf of `owner`.
    function allowance(address owner, address spender) external view returns (uint256 amount);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.2;

import "./IERC20.sol";

interface IERC20Extended is IERC20 {
    function burnFor(address from, uint256 amount) external;

    function burn(uint256 amount) external;

    function approveFor(
        address owner,
        address spender,
        uint256 amount
    ) external returns (bool success);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import {IERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import {IERC721ExtendedToken} from "./IERC721ExtendedToken.sol";

interface IERC721Base is IERC721Upgradeable {
    function mint(address to, uint256 id) external;

    function mint(
        address to,
        uint256 id,
        bytes calldata metaData
    ) external;

    function approveFor(
        address from,
        address operator,
        uint256 id
    ) external;

    function setApprovalForAllFor(
        address from,
        address operator,
        bool approved
    ) external;

    function burnFrom(address from, uint256 id) external;

    function burn(uint256 id) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external override;

    function batchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids
    ) external;

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        bytes calldata data
    ) external;

    function exists(uint256 tokenId) external view returns (bool);

    function supportsInterface(bytes4 id) external view override returns (bool);

    function setTrustedForwarder(address trustedForwarder) external;

    function isTrustedForwarder(address forwarder) external returns (bool);

    function getTrustedForwarder() external returns (address trustedForwarder);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

interface IERC721ExtendedToken {
    function approveFor(
        address sender,
        address operator,
        uint256 id
    ) external;

    function batchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids
    ) external;

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        bytes calldata data
    ) external;

    function setApprovalForAllFor(
        address sender,
        address operator,
        bool approved
    ) external;

    function burn(uint256 id) external;

    function burnFrom(address from, uint256 id) external;
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import {IAssetERC721} from "./IAssetERC721.sol";

interface IPolygonAssetERC1155 {
    function changeBouncerAdmin(address newBouncerAdmin) external;

    function setBouncer(address bouncer, bool enabled) external;

    function setPredicate(address predicate) external;

    function mint(
        address creator,
        uint40 packId,
        bytes32 hash,
        uint256 supply,
        address owner,
        bytes calldata data
    ) external returns (uint256 id);

    function mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    function mintDeficit(
        address account,
        uint256 id,
        uint256 amount
    ) external;

    function mintMultiple(
        address creator,
        uint40 packId,
        bytes32 hash,
        uint256[] calldata supplies,
        bytes calldata rarityPack,
        address owner,
        bytes calldata data
    ) external returns (uint256[] memory ids);

    // fails on non-NFT or nft who do not have collection (was a mistake)
    function collectionOf(uint256 id) external view returns (uint256);

    function balanceOf(address owner, uint256 id) external view returns (uint256);

    // return true for Non-NFT ERC1155 tokens which exists
    function isCollection(uint256 id) external view returns (bool);

    function collectionIndexOf(uint256 id) external view returns (uint256);

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external;

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external;

    function burnFrom(
        address from,
        uint256 id,
        uint256 amount
    ) external;

    function getBouncerAdmin() external view returns (address);

    function extractERC721From(
        address sender,
        uint256 id,
        address to
    ) external returns (uint256 newId);

    function isBouncer(address who) external view returns (bool);

    function creatorOf(uint256 id) external view returns (address);

    function doesHashExist(uint256 id) external view returns (bool);

    function isSuperOperator(address who) external view returns (bool);

    function isApprovedForAll(address owner, address operator) external view returns (bool isOperator);

    function setApprovalForAllFor(
        address sender,
        address operator,
        bool approved
    ) external;

    function setApprovalForAll(address operator, bool approved) external;

    function balanceOfBatch(address[] calldata owners, uint256[] calldata ids) external returns (uint256[] memory);

    function name() external returns (string memory _name);

    function symbol() external returns (string memory _symbol);

    function supportsInterface(bytes4 id) external returns (bool);

    function uri(uint256 id) external returns (string memory);

    function setAssetERC721(IAssetERC721 assetERC721) external;

    function exists(uint256 tokenId) external view returns (bool);

    function setTrustedForwarder(address trustedForwarder) external;

    function isTrustedForwarder(address forwarder) external returns (bool);

    function getTrustedForwarder() external returns (address);

    function metadataHash(uint256 id) external returns (bytes32);
}