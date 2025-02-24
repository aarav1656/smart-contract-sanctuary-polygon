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
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
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
interface IERC20Permit {
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
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
        IERC20 token,
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
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
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
        IERC20Permit token,
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
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
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
pragma solidity >=0.8.0 <0.9.0;

import "./Utils.sol";

/**
 * @dev Interface of the Gateway Self External Calls.
 */
interface IGateway {
    struct RequestMetadata {
        uint256 destGasLimit;
        uint256 destGasPrice;
        uint256 ackGasLimit;
        uint256 ackGasPrice;
        uint256 relayerFees;
        uint8 ackType;
        bool isReadCall;
        bytes asmAddress;
    }

    function iSend(
        uint256 version,
        uint256 routeAmount,
        bytes memory routeRecipient,
        string memory destChainId,
        bytes memory requestMetadata,
        bytes memory requestPacket
    ) external payable returns (uint256);

    function setDappMetadata(string memory feePayerAddress) external payable returns (uint256);

    function crossChainRequestDefaultFee() external view returns (uint256 fees);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

library Utils {
    // This is used purely to avoid stack too deep errors
    // represents everything about a given validator set
    struct ValsetArgs {
        // the validators in this set, represented by an Ethereum address
        address[] validators;
        // the powers of the given validators in the same order as above
        uint64[] powers;
        // the nonce of this validator set
        uint256 valsetNonce;
    }

    struct RequestPayload {
        uint256 routeAmount;
        uint256 requestIdentifier;
        uint256 requestTimestamp;
        address routeRecipient;
        address asmAddress;
        string srcChainId;
        string destChainId;
        bytes requestSender;
        bytes requestPacket;
        bool isReadCall;
    }

    struct CrossChainAckPayload {
        uint256 requestIdentifier;
        string destChainId;
        bytes requestSender;
        bytes execData;
        bool execFlag;
    }

    // This represents a validator signature
    struct Signature {
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    enum AckType {
        NO_ACK,
        ACK_ON_SUCCESS,
        ACK_ON_ERROR,
        ACK_ON_BOTH
    }

    error IncorrectCheckpoint();
    error InvalidValsetNonce(uint256 newNonce, uint256 currentNonce);
    error MalformedNewValidatorSet();
    error MalformedCurrentValidatorSet();
    error InsufficientPower(uint64 cumulativePower, uint64 powerThreshold);
    error InvalidSignature();
    // constants
    string constant MSG_PREFIX = "\x19Ethereum Signed Message:\n32";
    // The number of 'votes' required to execute a valset
    // update or batch execution, set to 2/3 of 2^32
    uint64 constant constantPowerThreshold = 2791728742;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Interface for handler contracts that support deposits and deposit executions.
/// @author Router Protocol.
interface IDepositExecute {
    struct NonReserveSwapInfo {
        uint256 srcTokenAmount;
        uint256 srcStableTokenAmount;
        bytes32 destChainIdBytes;
        address depositor;
        address srcTokenAddress;
        address srcStableTokenAddress;
        bytes[] dataTx;
        address[] path;
        uint256[] flags;
    }

    struct ReserveOrLPSwapInfo {
        uint256 srcStableTokenAmount;
        address srcStableTokenAddress;
        address depositor;
        address srcTokenAddress;
        bytes32 destChainIdBytes;
    }

    struct ExecuteSwapInfo {
        uint256 destStableTokenAmount;
        bytes destStableTokenAddress;
        uint64 depositNonce;
        bool isDestNative;
        bytes destTokenAddress;
        bytes recipient;
        bytes[] dataTx;
        bytes[] path;
        uint256[] flags;
        uint256 destTokenAmount;
        uint256 widgetID;
    }

    struct DepositData {
        address sender;
        address srcStableTokenAddress;
        uint256 srcStableTokenAmount;
    }

    struct NativeTransferParams {
        uint256 routeAmount;
        bytes routeRecipient;
    }

    struct ArbitraryInstruction {
        bytes destContractAddress;
        bytes data;
        uint256 gasLimit;
        uint256 gasPrice;
    }

    // dest details for usdc deposits
    struct DestDetails {
        string chainId;
        uint32 usdcDomainId;
        address reserveHandlerAddress;
        address destCallerAddress;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IHandlerReserve {
    function fundERC20(address tokenAddress, address owner, uint256 amount) external;

    function lockERC20(address tokenAddress, address owner, address recipient, uint256 amount) external;

    function releaseERC20(address tokenAddress, address recipient, uint256 amount) external;

    function mintERC20(address tokenAddress, address recipient, uint256 amount) external;

    function burnERC20(address tokenAddress, address owner, uint256 amount) external;

    function safeTransferETH(address to, uint256 value) external;

    // function deductFee(
    //     address feeTokenAddress,
    //     address depositor,
    //     uint256 providedFee,
    //     // uint256 requiredFee,
    //     // address _ETH,
    //     // bool _isFeeEnabled,
    //     address _feeManager
    // ) external;

    function mintWrappedERC20(address tokenAddress, address recipient, uint256 amount) external;

    function stake(address depositor, address tokenAddress, uint256 amount) external;

    function stakeETH(address depositor, address tokenAddress, uint256 amount) external;

    function unstake(address unstaker, address tokenAddress, uint256 amount) external;

    function unstakeETH(address unstaker, address tokenAddress, uint256 amount, address WETH) external;

    function giveAllowance(address token, address spender, uint256 amount) external;

    function getStakedRecord(address account, address tokenAddress) external view returns (uint256);

    function withdrawWETH(address WETH, uint256 amount, address payable recipient) external;

    function _setLiquidityPoolOwner(
        address oldOwner,
        address newOwner,
        address tokenAddress,
        address lpAddress
    ) external;

    function _setLiquidityPool(address contractAddress, address lpAddress) external;

    // function _setLiquidityPool(
    //     string memory name,
    //     string memory symbol,
    //     uint8 decimals,
    //     address contractAddress,
    //     address lpAddress
    // ) external returns (address);

    function swapMulti(
        address oneSplitAddress,
        address[] memory tokens,
        uint256 amount,
        uint256 minReturn,
        uint256[] memory flags,
        bytes[] memory dataTx
    ) external returns (uint256 returnAmount);

    function swap(
        address oneSplitAddress,
        address fromToken,
        address destToken,
        uint256 amount,
        uint256 minReturn,
        uint256 flags,
        bytes memory dataTx
    ) external returns (uint256 returnAmount);

    // function feeManager() external returns (address);

    function _lpToContract(address token) external returns (address);

    function _contractToLP(address token) external returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITokenMessenger {
    function depositForBurnWithCaller(
        uint256 _amount,
        uint32 _destinationDomain,
        bytes32 _mintRecipient,
        address _burnToken,
        bytes32 _destinationCaller
    ) external returns (uint64);

    function replaceDepositForBurn(
        bytes memory originalMessage,
        bytes calldata originalAttestation,
        bytes32 _destCaller,
        bytes32 _mintRecipient
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IWETH {
    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);

    function withdraw(uint256) external;

    function transferFrom(address src, address dst, uint256 wad) external returns (bool);

    function approve(address guy, uint256 wad) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IDepositExecute.sol";
import "../interfaces/IHandlerReserve.sol";
import "../interfaces/ITokenMessenger.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

library Setter {
    using SafeERC20 for IERC20;

    // codeId:
    // 1 -> Only Gateway contract
    // 2 -> array length mismatch
    // 3 -> contract address cannot be zero address
    // 4 -> provided contract is not whitelisted
    // 5 -> Either reserve handler or dest caller address is zero address
    // 6 -> Insufficient native assets sent
    // 7 -> token not whitelisted
    // 8 -> min amount lower than required
    // 9 -> invalid data
    // 10 -> invalid token addresses
    // 11 -> data for reserve transfer
    // 12 -> data for LP transfer
    // 13 -> only Voyager middleware
    // 14 -> already reverted
    // 15 -> no deposit found
    // 16 -> dest chain not configured
    error VoyagerError(uint8 codeId);

    event DepositReverted(
        bytes32 indexed destChainIdBytes,
        uint64 indexed depositNonce,
        address indexed sender,
        address srcStableTokenAddress,
        uint256 srcStableTokenAmount
    );

    /// @notice Function to get chain ID bytes
    /// @param  chainId chain Id of the chain
    function getChainIdBytes(string memory chainId) public pure returns (bytes32) {
        return keccak256(abi.encode(chainId));
    }

    function setChainIdToDestDetails(
        mapping(bytes32 => IDepositExecute.DestDetails) storage chainIdToDestDetails,
        IDepositExecute.DestDetails[] memory destDetails
    ) public {
        for (uint256 i = 0; i < destDetails.length; i++) {
            bytes32 chainIdBytes = getChainIdBytes(destDetails[i].chainId);

            // require(destDetails[i].reserveHandlerAddress != address(0), "Reserve handler != address(0)");
            // require(destDetails[i].destCallerAddress != address(0), "Dest caller != address(0)");
            if (destDetails[i].reserveHandlerAddress == address(0) || destDetails[i].destCallerAddress == address(0)) {
                // Either reserve handler or dest caller address is zero address
                revert VoyagerError(5);
            }

            chainIdToDestDetails[chainIdBytes] = IDepositExecute.DestDetails(
                destDetails[i].chainId,
                destDetails[i].usdcDomainId,
                destDetails[i].reserveHandlerAddress,
                destDetails[i].destCallerAddress
            );
        }
    }

    function setResource(
        mapping(address => bool) storage _contractWhitelist,
        address contractAddress,
        bool isResource
    ) public {
        // require(contractAddress != address(0), "contract address can't be zero");
        if (contractAddress == address(0)) {
            // contract address can't be zero
            revert VoyagerError(3);
        }
        _contractWhitelist[contractAddress] = isResource;
    }

    /// @notice First verifies {contractAddress} is whitelisted, then sets {_burnList}[{contractAddress}]
    /// to true.
    /// @dev Can only be called by the bridge
    /// @param contractAddress Address of contract to be used when making or executing deposits.
    /// @param status Boolean flag to change burnable status.
    function setBurnable(
        mapping(address => bool) storage _burnList,
        bool isWhitelisted,
        address contractAddress,
        bool status
    ) public {
        // require(isWhitelisted, "provided contract is not whitelisted");
        if (!isWhitelisted) {
            // provided contract is not whitelisted
            revert VoyagerError(4);
        }
        _burnList[contractAddress] = status;
    }

    /// @notice Function to set min amount to transfer to another chain.
    /// @param  _tokens addresses of src stable token
    /// @param  _amounts min amounts to be transferred
    function setMinAmountToSwap(
        mapping(address => uint256) storage _minAmountToSwap,
        address[] memory _tokens,
        uint256[] memory _amounts
    ) public {
        // require(_tokens.length == _amounts.length, "array length mismatch");
        if (_tokens.length != _amounts.length) {
            // array length mismatch
            revert VoyagerError(2);
        }
        uint8 length = uint8(_tokens.length);
        for (uint8 i = 0; i < length; i++) {
            _minAmountToSwap[_tokens[i]] = _amounts[i];
        }
    }

    function setLiquidityPool(
        IHandlerReserve _reserve,
        mapping(address => bool) storage _contractWhitelist,
        mapping(address => bool) storage _burnList,
        address contractAddress,
        address lpAddress
    ) public {
        _reserve._setLiquidityPool(contractAddress, lpAddress);
        _contractWhitelist[lpAddress] = true;
        _burnList[lpAddress] = true;
    }

    /// @notice Set if USDC is burnable and mintable for a chain pair
    /// @notice Only RESOURCE_SETTER can call this function
    /// @param _destChainID array of dest chain ids
    /// @param _setTrue array of boolean suggesting whether it is burnable and mintable
    function setUsdcBurnableAndMintable(
        mapping(bytes32 => bool) storage _isUsdcBurnableMintable,
        string[] memory _destChainID,
        bool[] memory _setTrue
    ) public {
        // Array length mismatch
        if (_destChainID.length != _setTrue.length) {
            revert VoyagerError(2);
        }

        for (uint8 i = 0; i < _destChainID.length; i++) {
            bytes32 destChainIdBytes = getChainIdBytes(_destChainID[i]);
            // require(isChainWhitelisted[destChainIdBytes], "Chain Id != 0");
            _isUsdcBurnableMintable[destChainIdBytes] = _setTrue[i];
        }
    }

    /// @notice Function to handle the request for execution received from Router Chain
    /// @param requestSender Address of the sender of the transaction on the source chain.
    /// @param packet Payload coming from the router chain.
    function iReceive(
        mapping(bytes32 => mapping(uint64 => bool)) storage _executionRevertCompleted,
        mapping(address => bool) storage _burnList,
        IHandlerReserve _reserve,
        bytes memory routerBridge,
        bytes memory requestSender,
        bytes memory packet
    ) public {
        // require(
        //     keccak256(abi.encodePacked(sender)) == keccak256(abi.encodePacked(routerBridge)),
        //     "only Voyager middleware"
        // );

        if (keccak256(requestSender) != keccak256(routerBridge)) {
            // only Voyager middleware
            revert VoyagerError(13);
        }

        uint8 txType = abi.decode(packet, (uint8));

        /// Refunding user money in case of some issues on dest chain
        if (txType == 2) {
            (, bytes32 destChainIdBytes, uint64 _depositNonce, IDepositExecute.DepositData memory depositData) = abi
                .decode(packet, (uint8, bytes32, uint64, IDepositExecute.DepositData));

            // require(!_executionRevertCompleted[destChainIdBytes][_depositNonce], "already reverted");

            if (_executionRevertCompleted[destChainIdBytes][_depositNonce]) {
                // already reverted
                revert VoyagerError(14);
            }

            // IDepositExecute.DepositData memory depositData = _depositData[destChainIdBytes][_depositNonce];
            // require(depositData.srcStableTokenAddress != address(0), "no deposit found");

            if (depositData.srcStableTokenAddress == address(0)) {
                // no deposit found
                revert VoyagerError(15);
            }

            _executionRevertCompleted[destChainIdBytes][_depositNonce] = true;

            if (_burnList[depositData.srcStableTokenAddress]) {
                _reserve.mintERC20(
                    depositData.srcStableTokenAddress,
                    depositData.sender,
                    depositData.srcStableTokenAmount
                );
            } else {
                IERC20(depositData.srcStableTokenAddress).safeTransfer(
                    depositData.sender,
                    depositData.srcStableTokenAmount
                );
            }

            emit DepositReverted(
                destChainIdBytes,
                _depositNonce,
                depositData.sender,
                depositData.srcStableTokenAddress,
                depositData.srcStableTokenAmount
            );
        }
    }

    /// @notice Function to change the destCaller and mintRecipient for a USDC burn tx.
    /// @notice Only DEFAULT_ADMIN can call this function.
    /// @param  originalMessage Original message received when the USDC was burnt.
    /// @param  originalAttestation Original attestation received from the API.
    /// @param  newDestCaller Address of the new destination caller.
    /// @param  newMintRecipient Address of the new mint recipient.
    function changeDestCallerOrMintRecipient(
        ITokenMessenger tokenMessenger,
        bytes memory originalMessage,
        bytes calldata originalAttestation,
        address newDestCaller,
        address newMintRecipient
    ) public {
        bytes32 _destCaller = bytes32(uint256(uint160(newDestCaller)));
        bytes32 _mintRecipient = bytes32(uint256(uint160(newMintRecipient)));

        tokenMessenger.replaceDepositForBurn(originalMessage, originalAttestation, _destCaller, _mintRecipient);
    }

    // function decodeArbitraryData(
    //     bytes calldata arbitraryData
    // ) internal pure returns (IDepositExecute.ArbitraryInstruction memory arbitraryInstruction) {
    //     (
    //         arbitraryInstruction.destContractAddress,
    //         arbitraryInstruction.data,
    //         arbitraryInstruction.gasLimit,
    //         arbitraryInstruction.gasPrice
    //     ) = abi.decode(arbitraryData, (bytes, bytes, uint256, uint256));
    // }

    // function decodeReserveOrLpSwapData(
    //     bytes calldata swapData
    // ) internal pure returns (IDepositExecute.ReserveOrLPSwapInfo memory swapDetails) {
    //     (
    //         swapDetails.destChainIdBytes,
    //         swapDetails.srcStableTokenAmount,
    //         swapDetails.srcStableTokenAddress,
    //         swapDetails.srcTokenAddress
    //     ) = abi.decode(swapData, (bytes32, uint256, address, address));
    // }

    // function decodeExecuteData(
    //     bytes calldata executeData
    // ) internal pure returns (IDepositExecute.ExecuteSwapInfo memory executeDetails) {
    //     (executeDetails.destTokenAmount) = abi.decode(executeData, (uint256));

    //     (
    //         ,
    //         executeDetails.destTokenAddress,
    //         executeDetails.isDestNative,
    //         executeDetails.destStableTokenAddress,
    //         executeDetails.recipient,
    //         executeDetails.dataTx,
    //         executeDetails.path,
    //         executeDetails.flags,
    //         executeDetails.widgetID
    //     ) = abi.decode(executeData, (uint256, bytes, bool, bytes, bytes, bytes[], bytes[], uint256[], uint256));
    // }

    // function checks(
    //     address token,
    //     uint256 amount,
    //     mapping(address => uint256) storage _minAmountToSwap,
    //     mapping(address => bool) storage _contractWhitelist
    // ) internal view {
    //     if (amount < _minAmountToSwap[token]) {
    //         // min amount lower than required
    //         revert VoyagerError(8);
    //     }

    //     if (!_contractWhitelist[token]) {
    //         // token not whitelisted
    //         revert VoyagerError(7);
    //     }
    // }

    // /// @notice Function to transfer LP tokens from source chain to get any other token on dest chain.
    // /// @param swapData Swap data for LP token deposit
    // /// @param executeData Execute data for the execution of transaction on the destination chain.
    // function depositLPToken(
    //     bytes calldata swapData,
    //     bytes calldata executeData,
    //     mapping(address => uint256) storage _minAmountToSwap,
    //     mapping(address => bool) storage _contractWhitelist,
    //     mapping(bytes32 => uint64) storage depositNonce,
    //     IHandlerReserve reserve,
    //     address msgSender
    // ) external returns (bytes memory, address srcToken, uint256 amount) {
    //     IDepositExecute.ReserveOrLPSwapInfo memory swapDetails = decodeReserveOrLpSwapData(swapData);
    //     IDepositExecute.ExecuteSwapInfo memory executeDetails = decodeExecuteData(executeData);
    //     swapDetails.depositor = msgSender;

    //     executeDetails.depositNonce = _depositLPToken(
    //         swapDetails,
    //         _minAmountToSwap,
    //         _contractWhitelist,
    //         depositNonce,
    //         reserve
    //     );

    //     bytes memory packet = abi.encode(0, swapDetails, executeDetails);
    //     return (packet, swapDetails.srcTokenAddress, swapDetails.srcStableTokenAmount);
    // }

    // /// @notice Function to transfer LP tokens from source chain to get any other token on dest chain
    // /// and execute an arbitrary instruction on the destination chain after the fund transfer is completed.
    // /// @param swapData Swap data for LP token deposit
    // /// @param executeData Execute data for the execution of token transfer on the destination chain.
    // /// @param arbitraryData Arbitrary data for the execution of arbitrary instruction execution on the
    // /// destination chain.
    // function depositLPTokenAndExecute(
    //     bytes calldata swapData,
    //     bytes calldata executeData,
    //     bytes calldata arbitraryData,
    //     mapping(address => uint256) storage _minAmountToSwap,
    //     mapping(address => bool) storage _contractWhitelist,
    //     mapping(bytes32 => uint64) storage depositNonce,
    //     IHandlerReserve reserve,
    //     address depositor
    // ) external returns (bytes memory, address, uint256) {
    //     IDepositExecute.ReserveOrLPSwapInfo memory swapDetails = decodeReserveOrLpSwapData(swapData);
    //     IDepositExecute.ExecuteSwapInfo memory executeDetails = decodeExecuteData(executeData);
    //     swapDetails.depositor = depositor;

    //     IDepositExecute.ArbitraryInstruction memory arbitraryInstruction = decodeArbitraryData(arbitraryData);
    //     executeDetails.depositNonce = _depositLPToken(
    //         swapDetails,
    //         _minAmountToSwap,
    //         _contractWhitelist,
    //         depositNonce,
    //         reserve
    //     );

    //     bytes memory packet = abi.encode(2, msg.sender, swapDetails, executeDetails, arbitraryInstruction);
    //     return (packet, swapDetails.srcTokenAddress, swapDetails.srcStableTokenAmount);
    // }

    // function _depositLPToken(
    //     IDepositExecute.ReserveOrLPSwapInfo memory swapDetails,
    //     mapping(address => uint256) storage _minAmountToSwap,
    //     mapping(address => bool) storage _contractWhitelist,
    //     mapping(bytes32 => uint64) storage depositNonce,
    //     IHandlerReserve reserve
    // ) internal returns (uint64 nonce) {
    //     // require(_contractWhitelist[swapDetails.srcStableTokenAddress], "token not whitelisted");
    //     // if(!_contractWhitelist[swapDetails.srcStableTokenAddress]) {
    //     //     // token not whitelisted
    //     //     revert VoyagerError(7);
    //     // }

    //     // require(
    //     //     swapDetails.srcStableTokenAmount >= _minAmountToSwap[swapDetails.srcStableTokenAddress],
    //     //     "min amount lower than required"
    //     // );
    //     // if (swapDetails.srcStableTokenAmount < _minAmountToSwap[swapDetails.srcStableTokenAddress]) {
    //     //     // min amount lower than required
    //     //     revert VoyagerError(8);
    //     // }

    //     checks(
    //         swapDetails.srcStableTokenAddress,
    //         swapDetails.srcStableTokenAmount,
    //         _minAmountToSwap,
    //         _contractWhitelist
    //     );

    //     // require(
    //     //     _reserve._contractToLP(swapDetails.srcStableTokenAddress) == swapDetails.srcTokenAddress,
    //     //     "invalid token addresses"
    //     // );
    //     if (reserve._contractToLP(swapDetails.srcStableTokenAddress) != swapDetails.srcTokenAddress) {
    //         // invalid token addresses
    //         revert VoyagerError(10);
    //     }

    //     // require(isChainWhitelisted[swapDetails.destChainIdBytes], "dest chain not whitelisted");

    //     // depositNonce[swapDetails.destChainIdBytes] += 1;
    //     // _reserve.burnERC20(swapDetails.srcTokenAddress, swapDetails.depositor, swapDetails.srcStableTokenAmount);

    //     unchecked {
    //         nonce = ++depositNonce[swapDetails.destChainIdBytes];
    //     }
    // }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
// import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
// import "@openzeppelin/contracts/utils/math/SafeMath.sol";
// import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
// import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import "@routerprotocol/evm-gateway-contracts/contracts/IGateway.sol";
import "./interfaces/IDepositExecute.sol";
import "./interfaces/IWETH.sol";
import "./interfaces/IHandlerReserve.sol";
import "./interfaces/ITokenMessenger.sol";
import "./libraries/Setter.sol";

// import "hardhat/console.sol";

/// @title Handles ERC20 deposits and deposit executions.
/// @author Router Protocol.
/// @notice This contract is intended to be used with the Bridge contract.
// Initializable,
// UUPSUpgradeable,
// ContextUpgradeable,
contract VoyagerDepositHandler is AccessControl, ReentrancyGuard, Pausable {
    using Setter for mapping(bytes32 => IDepositExecute.DestDetails);
    using Setter for mapping(bytes32 => mapping(uint64 => bool));
    using Setter for mapping(bytes32 => bool);
    using Setter for mapping(address => bool);
    using Setter for mapping(address => uint256);

    // using SafeMath for uint256;
    using SafeERC20 for IERC20;

    bytes32 public constant RESOURCE_SETTER = keccak256("RESOURCE_SETTER");
    bytes32 public constant PAUSER = keccak256("PAUSER");

    // abi.encodePacked(
    //    uint64 destGasLimit: 1000000,
    //    uint64 destGasPrice: 0,
    //    uint64 ackGasLimit: 0,
    //    uint64 ackGasPrice: 0,
    //    uint256 relayerFees: 0 // take default
    //    uint8 ackType: 0 // NO ACK
    //    bool isReadCall: false
    //    bytes memory asmAddress: ""
    // );
    bytes public constant VOYAGER_REQUEST_METADATA =
        "0x00000000000f424000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000";

    string public constant ROUTER_CHAIN_ID = "router_9000-1";

    // address of WETH
    address public _WETH;
    // address of the oneSplitAddress
    address public _oneSplitAddress;
    // address of USDC
    address private _usdc;

    // Instance of the reserve handler contract
    IHandlerReserve public _reserve;
    // Instance of the gateway contract
    address public gatewayContract;
    // USDC token messenger
    ITokenMessenger public tokenMessenger;

    // address of the Router Bridge contract on Router chain
    bytes routerBridge;

    // keccak256(abi.encode(destChainId)) => DestDetails
    mapping(bytes32 => IDepositExecute.DestDetails) public chainIdToDestDetails;

    // keccak256(abi.encode(destChainId)) => nonce
    mapping(bytes32 => uint64) public depositNonce;

    // keccak256(abi.encode(destChainId)) => if USDC is burnable and mintable
    mapping(bytes32 => bool) public _isUsdcBurnableMintable;

    // keccak256(abi.encode(destChainId)) + depositNonce => Revert Executed?
    mapping(bytes32 => mapping(uint64 => bool)) private _executionRevertCompleted;

    // srcStableTokenAddress => min amount to transfer to the other chain
    mapping(address => uint256) private _minAmountToSwap;

    // token contract address => is reserve
    mapping(address => bool) private _contractWhitelist;

    // token contract address => is burnable
    mapping(address => bool) private _burnList;
    uint256 public eventNonce;

    // codeId:
    // 1 -> Only Gateway contract
    // 2 -> array length mismatch
    // 3 -> contract address cannot be zero address
    // 4 -> provided contract is not whitelisted
    // 5 -> Either reserve handler or dest caller address is zero address
    // 6 -> Insufficient native assets sent
    // 7 -> token not whitelisted
    // 8 -> min amount lower than required
    // 9 -> invalid data
    // 10 -> invalid token addresses
    // 11 -> data for reserve transfer
    // 12 -> data for LP transfer
    // 13 -> only Voyager middleware
    // 14 -> already reverted
    // 15 -> no deposit found
    // 16 -> dest chain not configured
    error VoyagerError(uint8 codeId);

    event SendEvent(uint8 typeOfDeposit, uint256 nonce, address srcTokenAddress, uint256 srcTokenAmount, bytes packet);

    event NewSendEvent(
        uint8 typeOfDeposit,
        uint32 timestamp,
        address srcTokenAddress,
        address depositor,
        bytes recipient,
        bytes32 destChainIdBytes,
        uint256 nonce,
        uint256 srcTokenAmount
    );

    modifier isGateway() {
        _isGateway();
        _;
    }

    function _isGateway() private view {
        // require(msg.sender == address(gatewayContract), "Only gateway");
        if (msg.sender != gatewayContract) {
            // Only gateway contracts
            revert VoyagerError(1);
        }
    }

    constructor(bytes memory depositArgs) {
        (_WETH, _usdc) = abi.decode(depositArgs, (address, address));

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(RESOURCE_SETTER, msg.sender);
        _setupRole(PAUSER, msg.sender);
    }

    // function _authorizeUpgrade(address newImplementation) internal override onlyRole(DEFAULT_ADMIN_ROLE) {}

    /// @notice Pauses deposits on the handler.
    /// @notice Only callable by an address that currently has the PAUSER role.
    function pause() external onlyRole(PAUSER) whenNotPaused {
        _pause();
    }

    /// @notice Unpauses deposits on the handler.
    /// @notice Only callable by an address that currently has the PAUSER role.
    function unpause() external onlyRole(PAUSER) whenPaused {
        _unpause();
    }

    /// @notice Function to set min amount to transfer to another chain.
    /// @param  _tokens addresses of src stable token
    /// @param  _amounts min amounts to be transferred
    function setMinAmountToSwap(
        address[] memory _tokens,
        uint256[] memory _amounts
    ) external onlyRole(RESOURCE_SETTER) {
        Setter.setMinAmountToSwap(_minAmountToSwap, _tokens, _amounts);
        // require(_tokens.length == _amounts.length, "array length mismatch");
        // uint8 length = uint8(_tokens.length);
        // for (uint8 i = 0; i < length; i++) {
        //     _minAmountToSwap[_tokens[i]] = _amounts[i];
        // }
    }

    /// @notice Function to set router bridge address
    /// @notice Only RESOURCE_SETTER can call this function
    /// @param  bridge address of bridge on router chain
    function setRouterBridge(string memory bridge) external onlyRole(RESOURCE_SETTER) {
        routerBridge = bytes(bridge);
    }

    /// @notice Function to set gateway contract address
    /// @notice Only RESOURCE_SETTER can call this function
    /// @param  gateway address of gateway contract
    function setGatewayContract(address gateway) external onlyRole(RESOURCE_SETTER) {
        gatewayContract = gateway;
    }

    function setDappMetadata(string memory feePayer) external onlyRole(RESOURCE_SETTER) {
        (bool success, ) = gatewayContract.call(abi.encodeWithSelector(0xef15cbda, feePayer));
        require(success);
        // gatewayContract.setDappMetadata(feePayer);
    }

    // /// @notice Set chain whitelist
    // /// @notice Only RESOURCE_SETTER can call this function
    // /// @param chainId Array of chain ids
    // /// @param shouldWhitelist Array of should whitelist boolean
    // function whitelistChains(
    //     string[] memory chainId,
    //     bool[] memory shouldWhitelist
    // ) external onlyRole(RESOURCE_SETTER) {
    //     require(
    //         chainId.length == shouldWhitelist.length,
    //         "array length mismatch"
    //     );

    //     for (uint16 i = 0; i < chainId.length; i++) {
    //         bytes32 destChainIdBytes = getChainIdBytes(chainId[i]);
    //         isChainWhitelisted[destChainIdBytes] = shouldWhitelist[i];
    //     }
    // }

    /// @notice Function to fetch if a token is whitelisted for swaps
    /// @param tokenAddress Address of token contract.
    /// @return isResource true if whitelisted
    function isContractWhitelisted(address tokenAddress) external view returns (bool isResource) {
        isResource = _contractWhitelist[tokenAddress];
    }

    /// @notice Function to fetch if a token is burnable
    /// @param tokenAddress Address of token contract.
    /// @return burnable true if burnable
    function isBurnable(address tokenAddress) external view returns (bool burnable) {
        burnable = _burnList[tokenAddress];
    }

    /// TODO: Can we remove this min amount to swap?
    /// @notice Function used to fetch min amount to transfer to the other chain
    /// @param  _token src stable token address
    /// @return minAmountToSwap amount of src stable tokens
    function getMinAmountToSwap(address _token) external view returns (uint256 minAmountToSwap) {
        minAmountToSwap = _minAmountToSwap[_token];
    }

    function getRouterBridge() external view returns (string memory) {
        return string(routerBridge);
    }

    function getUsdc() external view returns (address) {
        return _usdc;
    }

    // /// @notice Function to get chain ID bytes
    // /// @param  chainId chain Id of the chain
    // function getChainIdBytes(string memory chainId) public pure returns (bytes32) {
    //     return keccak256(abi.encode(chainId));
    // }

    /// @notice Function to whitelist a token for swaps
    /// @dev Can only be called by the RESOURCE_SETTER
    /// @param contractAddress Address of contract to be called when a deposit is made and a deposited is executed.
    function setResource(address contractAddress, bool isResource) public onlyRole(RESOURCE_SETTER) {
        Setter.setResource(_contractWhitelist, contractAddress, isResource);
        // _setResource(contractAddress, isResource);
    }

    /// @notice First verifies {contractAddress} is whitelisted, then sets {_burnList}[{contractAddress}]
    /// to true.
    /// @dev Can only be called by the bridge
    /// @param contractAddress Address of contract to be used when making or executing deposits.
    /// @param status Boolean flag to change burnable status.
    function setBurnable(address contractAddress, bool status) public onlyRole(RESOURCE_SETTER) {
        // require(_contractWhitelist[contractAddress], "provided contract is not whitelisted");
        Setter.setBurnable(_burnList, _contractWhitelist[contractAddress], contractAddress, status);
        // _setBurnable(contractAddress, status);
    }

    function setLiquidityPool(address contractAddress, address lpAddress) public onlyRole(RESOURCE_SETTER) {
        // _reserve._setLiquidityPool(contractAddress, lpAddress);
        // _contractWhitelist[lpAddress] = true;
        // _burnList[lpAddress] = true;
        Setter.setLiquidityPool(_reserve, _contractWhitelist, _burnList, contractAddress, lpAddress);
    }

    /// @notice Sets liquidity pool owner for an existing LP.
    /// @dev Can only be set by the bridge
    /// @param oldOwner Address of the old owner of LP
    /// @param newOwner Address of the new owner for LP
    /// @param tokenAddress Address of ERC20 token
    /// @param lpAddress Address of LP.
    function setLiquidityPoolOwner(
        address oldOwner,
        address newOwner,
        address tokenAddress,
        address lpAddress
    ) public onlyRole(RESOURCE_SETTER) {
        _reserve._setLiquidityPoolOwner(oldOwner, newOwner, tokenAddress, lpAddress);
    }

    // /// @notice Sets a resource.
    // /// @param contractAddress Address of ERC20 token
    // function _setResource(address contractAddress, bool isResource) internal {
    //     require(contractAddress != address(0), "contract address can't be zero");
    //     _contractWhitelist[contractAddress] = isResource;
    // }

    // /// @notice Sets a resource burnable.
    // /// @param contractAddress Address of ERC20 token
    // /// @param status true for burnable, false for not burnable
    // function _setBurnable(address contractAddress, bool status) internal {
    //     require(_contractWhitelist[contractAddress], "provided contract is not whitelisted");
    //     _burnList[contractAddress] = status;
    // }

    /// @notice Function used to set reserve handler
    /// @notice Only RESOURCE_SETTER can call this function
    /// @param reserve address of the reserve handler
    function setReserve(address reserve) external onlyRole(RESOURCE_SETTER) {
        // require(reserve != address(0), "address != 0");
        if (reserve == address(0)) {
            // contract address cannot be zero address
            revert VoyagerError(3);
        }
        _reserve = IHandlerReserve(reserve);
        // Setter.setReserve(_reserve, reserve);
    }

    /// @notice Sets OneSplit address.
    /// @param contractAddress Address of OneSplit contract
    function setOneSplitAddress(address contractAddress) external onlyRole(RESOURCE_SETTER) {
        // require(contractAddress != address(0), "address != 0");
        if (contractAddress == address(0)) {
            // contract address cannot be zero address
            revert VoyagerError(3);
        }
        _oneSplitAddress = address(contractAddress);
    }

    /// @notice Function used to set usdc address
    /// @notice Only RESOURCE_SETTER can call this function
    /// @param  usdc address
    function setUsdcAddress(address usdc) external onlyRole(RESOURCE_SETTER) {
        _usdc = usdc;
    }

    /// @notice Function used to set usdc token messenger address
    /// @notice Only RESOURCE_SETTER can call this function
    /// @param  _tokenMessenger address of token messenger
    function setTokenMessenger(address _tokenMessenger) external onlyRole(RESOURCE_SETTER) {
        tokenMessenger = ITokenMessenger(_tokenMessenger);
    }

    /// @notice Function used to set dest details for usdc
    /// @notice Only RESOURCE_SETTER can call this function
    /// @param  destDetails dest details
    function setDestDetails(IDepositExecute.DestDetails[] memory destDetails) external onlyRole(RESOURCE_SETTER) {
        Setter.setChainIdToDestDetails(chainIdToDestDetails, destDetails);
        // for (uint256 i = 0; i < destDetails.length; i++) {
        //     bytes32 chainIdBytes = getChainIdBytes(destDetails[i].chainId);

        //     require(destDetails[i].reserveHandlerAddress != address(0), "Reserve handler != address(0)");
        //     require(destDetails[i].destCallerAddress != address(0), "Dest caller != address(0)");

        //     chainIdToDestDetails[chainIdBytes] = IDepositExecute.DestDetails(
        //         destDetails[i].chainId,
        //         destDetails[i].usdcDomainId,
        //         destDetails[i].reserveHandlerAddress,
        //         destDetails[i].destCallerAddress
        //     );
        // }
    }

    /// @notice Set if USDC is burnable and mintable for a chain pair
    /// @notice Only RESOURCE_SETTER can call this function
    /// @param _destChainID array of dest chain ids
    /// @param _setTrue array of boolean suggesting whether it is burnable and mintable
    function setUsdcBurnableAndMintable(
        string[] memory _destChainID,
        bool[] memory _setTrue
    ) external onlyRole(RESOURCE_SETTER) {
        Setter.setUsdcBurnableAndMintable(_isUsdcBurnableMintable, _destChainID, _setTrue);
        // require(
        //     _destChainID.length == _setTrue.length,
        //     "Array length mismatch"
        // );
        // for (uint8 i = 0; i < _destChainID.length; i++) {
        //     bytes32 destChainIdBytes = getChainIdBytes(_destChainID[i]);
        //     // require(isChainWhitelisted[destChainIdBytes], "Chain Id != 0");
        //     _isUsdcBurnableMintable[destChainIdBytes] = _setTrue[i];
        // }
    }

    // function decodeArbitraryData(
    //     bytes calldata arbitraryData
    // ) internal pure returns (IDepositExecute.ArbitraryInstruction memory arbitraryInstruction) {
    //     (
    //         arbitraryInstruction.destContractAddress,
    //         arbitraryInstruction.data,
    //         arbitraryInstruction.gasLimit,
    //         arbitraryInstruction.gasPrice
    //     ) = abi.decode(arbitraryData, (bytes, bytes, uint256, uint256));
    // }

    // function decodeReserveOrLpSwapData(
    //     bytes calldata swapData
    // ) internal pure returns (IDepositExecute.ReserveOrLPSwapInfo memory swapDetails) {
    //     (
    //         swapDetails.destChainIdBytes,
    //         swapDetails.srcStableTokenAmount,
    //         swapDetails.srcStableTokenAddress,
    //         swapDetails.srcTokenAddress
    //     ) = abi.decode(swapData, (bytes32, uint256, address, address));
    // }

    // function decodeNonReserveSwapData(
    //     bytes calldata swapData
    // ) internal pure returns (IDepositExecute.NonReserveSwapInfo memory swapDetails) {
    //     (
    //         swapDetails.destChainIdBytes,
    //         swapDetails.srcTokenAmount,
    //         swapDetails.srcStableTokenAmount,
    //         swapDetails.srcTokenAddress,
    //         swapDetails.srcStableTokenAddress,
    //         swapDetails.dataTx,
    //         swapDetails.path,
    //         swapDetails.flags
    //     ) = abi.decode(swapData, (bytes32, uint256, uint256, address, address, bytes[], address[], uint256[]));
    // }

    function decodeExecuteData(
        bytes calldata executeData
    ) internal pure returns (IDepositExecute.ExecuteSwapInfo memory executeDetails) {
        (executeDetails.destTokenAmount) = abi.decode(executeData, (uint256));

        (
            ,
            executeDetails.destTokenAddress,
            executeDetails.isDestNative,
            executeDetails.destStableTokenAddress,
            executeDetails.recipient,
            executeDetails.dataTx,
            executeDetails.path,
            executeDetails.flags,
            executeDetails.widgetID
        ) = abi.decode(executeData, (uint256, bytes, bool, bytes, bytes, bytes[], bytes[], uint256[], uint256));
    }

    // /// @notice Function to convert native to Wrapped native token and send it back to user
    // /// @param amount amount of native tokens to be converted
    // function convertToWeth(uint256 amount) internal {
    //     IWETH(_WETH).deposit{ value: amount }();
    //     // require(IWETH(_WETH).transfer(tokenPayer, amount));
    // }

    // function iSend(bytes memory packet, uint256 value) internal {
    //     bytes memory requestPacket = abi.encode(routerBridge, packet);
    //     (bool success, ) = gatewayContract.call{ value: value }(
    //         abi.encodeWithSelector(0xa84cee01, 1, 0, "", ROUTER_CHAIN_ID, VOYAGER_REQUEST_METADATA, requestPacket)
    //     );
    //     require(success);
    //     // gatewayContract.iSend{ value: value }(
    //     //     1, // version
    //     //     0, // routeAmount
    //     //     "", // routeRecipient
    //     //     ROUTER_CHAIN_ID,
    //     //     VOYAGER_REQUEST_METADATA,
    //     //     requestPacket
    //     // );
    // }

    function checkBurnableAndLock(address token, address user, uint256 amount) internal {
        if (!_burnList[token]) {
            IERC20(token).safeTransferFrom(user, address(_reserve), amount);
        } else {
            _reserve.burnERC20(token, user, amount);
        }
    }

    function checks(address token, uint256 amount) internal view {
        if (amount < _minAmountToSwap[token]) {
            // min amount lower than required
            revert VoyagerError(8);
        }

        if (!_contractWhitelist[token]) {
            // token not whitelisted
            revert VoyagerError(7);
        }
    }

    // function transferNativeToken(
    //     // bytes32 destChainIdBytes,
    //     uint256 srcTokenAmount,
    //     // bytes memory recipient,
    //     bytes calldata packet
    // ) external payable {
    //     // uint256 gasLeft = gasleft();
    //     convertToWeth(srcTokenAmount);

    //     address weth = _WETH;
    //     IERC20(weth).safeTransfer(address(_reserve), srcTokenAmount);

    //     // checkBurnableAndLock(weth, msg.sender, srcTokenAmount);

    //     // ++depositNonce[destChainIdBytes];
    //     unchecked {
    //         ++eventNonce;
    //     }

    //     emit SendEvent(4, eventNonce, weth, srcTokenAmount, packet);
    //     // emit NewSendEvent(4, eventNonce, _WETH, srcTokenAmount, packet);

    //     // bytes memory packet = abi.encode(
    //     //     4,
    //     //     destChainIdBytes,
    //     //     weth,
    //     //     srcTokenAmount,
    //     //     msg.sender,
    //     //     recipient,
    //     //     depositNonce[destChainIdBytes],
    //     //     widgetId
    //     // );

    //     // iSend(packet, msg.value.sub(srcTokenAmount));
    //     // console.log("gas left native transfer: %s", gasLeft - gasleft());
    // }

    // function transferBurnableUsdc(
    //     bytes32 destChainIdBytes,
    //     uint256 srcTokenAmount,
    //     bytes memory recipient,
    //     uint256 widgetId
    // ) external payable {
    //     handleUsdcBurn(destChainIdBytes, srcTokenAmount);
    //     ++depositNonce[destChainIdBytes];

    //     bytes memory packet = abi.encode(
    //         4,
    //         destChainIdBytes,
    //         _usdc,
    //         srcTokenAmount,
    //         msg.sender,
    //         recipient,
    //         depositNonce[destChainIdBytes],
    //         widgetId
    //     );
    //     iSend(packet, msg.value);
    // }

    function transferToken(
        bytes32 destChainIdBytes,
        bytes calldata recipient,
        address srcTokenAddress,
        uint256 srcTokenAmount
    ) external payable nonReentrant {
        checkBurnableAndLock(srcTokenAddress, msg.sender, srcTokenAmount);

        unchecked {
            ++eventNonce;
        }

        emit NewSendEvent(
            4,
            uint32(block.timestamp),
            srcTokenAddress,
            msg.sender,
            recipient,
            destChainIdBytes,
            eventNonce,
            srcTokenAmount
        );
    }

    function transferReserveToken(
        // bytes32 destChainIdBytes,
        address srcTokenAddress,
        uint256 srcTokenAmount,
        // bytes memory recipient,
        // uint256 widgetId,
        // bytes calldata requestMetadata,
        bytes calldata packet
    ) external payable {
        // uint256 gasLeft = gasleft();
        // address srcTokenAddress = toAddress(bytes(packet[33:33 + 20]));
        // uint256 srcTokenAmount = uint256(bytes32(bytes(packet[53:53 + 32])));

        // if (!_contractWhitelist[srcTokenAddress]) {
        //     // token not whitelisted
        //     revert VoyagerError(7);
        // }

        // checkBurnableAndLock(srcTokenAddress, msg.sender, srcTokenAmount);
        IERC20(srcTokenAddress).safeTransferFrom(msg.sender, address(_reserve), srcTokenAmount);

        unchecked {
            ++eventNonce;
        }

        // bytes memory packet = abi.encode(
        //     uint8(4), // 1
        //     destChainIdBytes, // 32
        //     srcTokenAddress,
        //     srcTokenAmount,
        //     msg.sender,
        //     recipient,
        //     eventNonce,
        //     widgetId
        // );

        // bytes memory requestPacket = abi.encode(routerBridge, packet);
        // (bool success, ) = gatewayContract.call{ value: msg.value }(
        //     abi.encodeWithSelector(0xa84cee01, 1, 0, "", ROUTER_CHAIN_ID, VOYAGER_REQUEST_METADATA, requestPacket)
        // );
        // require(success);

        emit SendEvent(4, eventNonce, srcTokenAddress, srcTokenAmount, packet);
        // SendEvent(uint64 nonce, bytes metadata, bytes packet);
        // iSend(packet, msg.value);
        // console.log("gas left: %s", gasLeft - gasleft());
    }

    // function safeTransferNativeToken(
    //     bytes32 destChainIdBytes,
    //     address srcTokenAddress,
    //     uint256 srcTokenAmount,
    //     bytes memory recipient,
    //     uint256 widgetId,
    //     bytes calldata packet // bytes calldata requestMetadata, // bytes calldata packet
    // ) external payable {
    //     // uint256 gasLeft = gasleft();
    //     // address srcTokenAddress = toAddress(bytes(packet[33:33 + 20]));
    //     // uint256 srcTokenAmount = uint256(bytes32(bytes(packet[53:53 + 32])));

    //     if (!_contractWhitelist[srcTokenAddress]) {
    //         // token not whitelisted
    //         revert VoyagerError(7);
    //     }

    //     checkBurnableAndLock(srcTokenAddress, msg.sender, srcTokenAmount);

    //     unchecked {
    //         ++eventNonce;
    //     }

    //     // bytes memory packet = abi.encode(
    //     //     uint8(4), // 1
    //     //     destChainIdBytes, // 32
    //     //     srcTokenAddress,
    //     //     srcTokenAmount,
    //     //     msg.sender,
    //     //     recipient,
    //     //     eventNonce,
    //     //     widgetId
    //     // );

    //     // bytes memory requestPacket = abi.encode(routerBridge, packet);
    //     // (bool success, ) = gatewayContract.call{ value: msg.value }(
    //     //     abi.encodeWithSelector(0xa84cee01, 1, 0, "", ROUTER_CHAIN_ID, VOYAGER_REQUEST_METADATA, requestPacket)
    //     // );
    //     // require(success);

    //     // emit SendEvent(4, eventNonce, srcTokenAddress, srcTokenAmount, packet);
    //     emit NewSendEvent(
    //         4,
    //         eventNonce,
    //         destChainIdBytes,
    //         msg.sender,
    //         recipient,
    //         srcTokenAddress,
    //         srcTokenAmount,
    //         widgetId,
    //         packet
    //     );

    //     // iSend(packet, msg.value);
    //     // console.log("Safe transfer gas left: %s", gasLeft - gasleft());
    // }

    // function toAddress(bytes memory _bytes) internal pure returns (address contractAddress) {
    //     bytes20 srcTokenAddress;
    //     assembly {
    //         srcTokenAddress := mload(add(_bytes, 0x20))
    //     }
    //     contractAddress = address(srcTokenAddress);
    // }

    // /// @notice Function to transfer reserve tokens from source chain to get any other token on dest chain.
    // /// @param isSourceNative Is the source token native token for this chain?
    // /// @param swapData Swap data for reserve token deposit
    // /// @param executeData Execute data for the execution of transaction on the destination chain.
    // function depositReserveToken(
    //     bool isSourceNative,
    //     bytes calldata swapData,
    //     bytes calldata executeData
    // ) external payable nonReentrant whenNotPaused {
    //     IDepositExecute.ReserveOrLPSwapInfo memory swapDetails = decodeReserveOrLpSwapData(swapData);
    //     IDepositExecute.ExecuteSwapInfo memory executeDetails = decodeExecuteData(executeData);

    //     if (isSourceNative) {
    //         // require(msg.value >= swapDetails.srcStableTokenAmount, "No native assets sent");
    //         if (msg.value < swapDetails.srcStableTokenAmount) {
    //             // No native assets sent
    //             revert VoyagerError(6);
    //         }
    //         convertToWeth(swapDetails.srcStableTokenAmount);
    //     }

    //     swapDetails.depositor = msg.sender;

    //     executeDetails.depositNonce = _depositReserveToken(isSourceNative, swapDetails);

    //     bytes memory packet = abi.encode(0, swapDetails, executeDetails);

    //     iSend(packet, msg.value.sub(swapDetails.srcStableTokenAmount));
    // }

    // /// @notice Function to transfer reserve tokens from source chain to get any other token on dest chain
    // /// and execute an arbitrary instruction on the destination chain after the fund transfer is completed.
    // /// @param isSourceNative Is the source token native token for this chain?
    // /// @param isAppTokenPayer Is app going to pay the tokens for transfer? if false, tokens will be deducted
    // /// from the user
    // /// @param swapData Swap data for reserve token deposit
    // /// @param executeData Execute data for the execution of token transfer on the destination chain.
    // /// @param arbitraryData Arbitrary data for the execution of arbitrary instruction execution on the
    // /// destination chain.
    // function depositReserveTokenAndExecute(
    //     bool isSourceNative,
    //     bool isAppTokenPayer,
    //     bytes calldata swapData,
    //     bytes calldata executeData,
    //     bytes calldata arbitraryData
    // ) external payable nonReentrant whenNotPaused {
    //     IDepositExecute.ReserveOrLPSwapInfo memory swapDetails = decodeReserveOrLpSwapData(swapData);
    //     IDepositExecute.ExecuteSwapInfo memory executeDetails = decodeExecuteData(executeData);

    //     if (isAppTokenPayer) {
    //         swapDetails.depositor = msg.sender;
    //     } else {
    //         address txOrigin;
    //         assembly {
    //             txOrigin := origin()
    //         }
    //         swapDetails.depositor = txOrigin;
    //     }

    //     if (isSourceNative) {
    //         // require(msg.value >= swapDetails.srcStableTokenAmount, "No native assets sent");
    //         if (msg.value < swapDetails.srcStableTokenAmount) {
    //             // No native assets sent
    //             revert VoyagerError(6);
    //         }
    //         convertToWeth(swapDetails.srcStableTokenAmount);
    //     }

    //     IDepositExecute.ArbitraryInstruction memory arbitraryInstruction = decodeArbitraryData(arbitraryData);

    //     executeDetails.depositNonce = _depositReserveToken(isSourceNative, swapDetails);

    //     bytes memory packet = abi.encode(2, msg.sender, swapDetails, executeDetails, arbitraryInstruction);

    //     iSend(packet, msg.value.sub(swapDetails.srcStableTokenAmount));
    // }

    // function _depositReserveToken(
    //     bool isSourceNative,
    //     IDepositExecute.ReserveOrLPSwapInfo memory swapDetails
    // ) internal returns (uint64 nonce) {
    //     // require(_contractWhitelist[swapDetails.srcStableTokenAddress], "token not whitelisted");
    //     // if (!_contractWhitelist[swapDetails.srcStableTokenAddress]) {
    //     //     // token not whitelisted
    //     //     revert VoyagerError(7);
    //     // }

    //     // require(
    //     //     swapDetails.srcStableTokenAmount >= _minAmountToSwap[swapDetails.srcStableTokenAddress],
    //     //     "min amount lower than required"
    //     // );
    //     // if (swapDetails.srcStableTokenAmount < _minAmountToSwap[swapDetails.srcStableTokenAddress]) {
    //     //     // min amount lower than required
    //     //     revert VoyagerError(8);
    //     // }

    //     checks(swapDetails.srcStableTokenAddress, swapDetails.srcStableTokenAmount);

    //     // require(swapDetails.srcTokenAddress == swapDetails.srcStableTokenAddress, "invalid data");
    //     if (swapDetails.srcTokenAddress != swapDetails.srcStableTokenAddress) {
    //         // invalid data
    //         revert VoyagerError(9);
    //     }

    //     // uint64 depositNonce = depositNonce[swapDetails.destChainIdBytes];
    //     _handleDepositForReserveToken(isSourceNative, swapDetails);
    //     unchecked {
    //         nonce = ++depositNonce[swapDetails.destChainIdBytes];
    //     }
    // }

    // /// @notice Function to handle deposit for reserve tokens
    // /// @param  swapDetails swapInfo struct for the swap details
    // function _handleDepositForReserveToken(
    //     bool isSourceNative,
    //     IDepositExecute.ReserveOrLPSwapInfo memory swapDetails
    // ) internal {
    //     // if (_burnList[swapDetails.srcTokenAddress]) {
    //     //     // since in case of reserve tokens, srcTokenAmount = srcStableTokenAmount
    //     //     _reserve.burnERC20(swapDetails.srcTokenAddress, swapDetails.depositor, swapDetails.srcStableTokenAmount);
    //     // } else {
    //     //     _reserve.lockERC20(
    //     //         swapDetails.srcTokenAddress,
    //     //         swapDetails.depositor,
    //     //         address(_reserve),
    //     //         swapDetails.srcStableTokenAmount
    //     //     );
    //     // }

    //     if (!isSourceNative) {
    //         checkBurnableAndLock(swapDetails.srcTokenAddress, swapDetails.depositor, swapDetails.srcStableTokenAmount);
    //     } else {
    //         IERC20(_WETH).safeTransfer(address(_reserve), swapDetails.srcStableTokenAmount);
    //     }

    //     if (_isUsdcBurnableMintable[swapDetails.destChainIdBytes] && _usdc == swapDetails.srcTokenAddress) {
    //         // Burn USDC
    //         handleUsdcBurn(swapDetails.destChainIdBytes, swapDetails.srcStableTokenAmount);
    //     }
    // }

    // /// @notice Function to transfer LP tokens from source chain to get any other token on dest chain.
    // /// @param swapData Swap data for LP token deposit
    // /// @param executeData Execute data for the execution of transaction on the destination chain.
    // function depositLPToken(
    //     bytes calldata swapData,
    //     bytes calldata executeData
    // ) external payable nonReentrant whenNotPaused {
    //     IDepositExecute.ReserveOrLPSwapInfo memory swapDetails = decodeReserveOrLpSwapData(swapData);
    //     IDepositExecute.ExecuteSwapInfo memory executeDetails = decodeExecuteData(executeData);
    //     swapDetails.depositor = msg.sender;

    //     executeDetails.depositNonce = _depositLPToken(swapDetails);

    //     bytes memory packet = abi.encode(0, swapDetails, executeDetails);

    //     iSend(packet, msg.value);
    // }

    // /// @notice Function to transfer LP tokens from source chain to get any other token on dest chain
    // /// and execute an arbitrary instruction on the destination chain after the fund transfer is completed.
    // /// @param isAppTokenPayer Is app going to pay the tokens for transfer? if false, tokens will be deducted
    // /// from the user
    // /// @param swapData Swap data for LP token deposit
    // /// @param executeData Execute data for the execution of token transfer on the destination chain.
    // /// @param arbitraryData Arbitrary data for the execution of arbitrary instruction execution on the
    // /// destination chain.
    // function depositLPTokenAndExecute(
    //     bool isAppTokenPayer,
    //     bytes calldata swapData,
    //     bytes calldata executeData,
    //     bytes calldata arbitraryData
    // ) external payable nonReentrant whenNotPaused {
    //     IDepositExecute.ReserveOrLPSwapInfo memory swapDetails = decodeReserveOrLpSwapData(swapData);
    //     IDepositExecute.ExecuteSwapInfo memory executeDetails = decodeExecuteData(executeData);

    //     if (isAppTokenPayer) {
    //         swapDetails.depositor = msg.sender;
    //     } else {
    //         address txOrigin;
    //         assembly {
    //             txOrigin := origin()
    //         }
    //         swapDetails.depositor = txOrigin;
    //     }

    //     IDepositExecute.ArbitraryInstruction memory arbitraryInstruction = decodeArbitraryData(arbitraryData);

    //     executeDetails.depositNonce = _depositLPToken(swapDetails);

    //     bytes memory packet = abi.encode(2, msg.sender, swapDetails, executeDetails, arbitraryInstruction);
    //     iSend(packet, msg.value);
    // }

    // function _depositLPToken(IDepositExecute.ReserveOrLPSwapInfo memory swapDetails) internal returns (uint64 nonce) {
    //     checks(swapDetails.srcStableTokenAddress, swapDetails.srcStableTokenAmount);

    //     if (_reserve._contractToLP(swapDetails.srcStableTokenAddress) != swapDetails.srcTokenAddress) {
    //         // invalid token addresses
    //         revert VoyagerError(10);
    //     }

    //     _reserve.burnERC20(swapDetails.srcTokenAddress, swapDetails.depositor, swapDetails.srcStableTokenAmount);

    //     unchecked {
    //         nonce = ++depositNonce[swapDetails.destChainIdBytes];
    //     }
    // }

    // /// @notice Function to transfer non-reserve tokens from source chain to get any other token on dest chain.
    // /// @param isSourceNative Is the source token native token for this chain?
    // /// @param swapData Swap data for non-reserve token deposit
    // /// @param executeData Execute data for the execution of transaction on the destination chain.
    // function depositNonReserveToken(
    //     bool isSourceNative,
    //     bytes calldata swapData,
    //     bytes calldata executeData
    // ) external payable nonReentrant whenNotPaused {
    //     IDepositExecute.NonReserveSwapInfo memory swapDetails = decodeNonReserveSwapData(swapData);
    //     IDepositExecute.ExecuteSwapInfo memory executeDetails = decodeExecuteData(executeData);
    //     if (isSourceNative) {
    //         // require(msg.value >= swapDetails.srcTokenAmount, "No native assets sent");
    //         if (msg.value < swapDetails.srcTokenAmount) {
    //             // Insufficient native assets sent
    //             revert VoyagerError(6);
    //         }
    //         convertToWeth(swapDetails.srcTokenAmount);
    //     }

    //     swapDetails.depositor = msg.sender;

    //     executeDetails.depositNonce = _depositNonReserveToken(isSourceNative, swapDetails);

    //     bytes memory packet = abi.encode(1, swapDetails, executeDetails);

    //     iSend(packet, msg.value.sub(swapDetails.srcTokenAmount));
    // }

    // /// @notice Function to transfer non-reserve tokens from source chain to get any other token on dest chain
    // /// and execute an arbitrary instruction on the destination chain after the fund transfer is completed.
    // /// @param isSourceNative Is the source token native token for this chain?
    // /// @param isAppTokenPayer Is app going to pay the tokens for transfer? if false, tokens will be deducted
    // /// from the user
    // /// @param swapData Swap data for non-reserve token deposit
    // /// @param executeData Execute data for the execution of token transfer on the destination chain.
    // /// @param arbitraryData Arbitrary data for the execution of arbitrary instruction execution on the
    // /// destination chain.
    // function depositNonReserveTokenAndExecute(
    //     bool isSourceNative,
    //     bool isAppTokenPayer,
    //     bytes calldata swapData,
    //     bytes calldata executeData,
    //     bytes calldata arbitraryData
    // ) external payable nonReentrant whenNotPaused {
    //     IDepositExecute.NonReserveSwapInfo memory swapDetails = decodeNonReserveSwapData(swapData);
    //     IDepositExecute.ExecuteSwapInfo memory executeDetails = decodeExecuteData(executeData);

    //     if (isAppTokenPayer) {
    //         swapDetails.depositor = msg.sender;
    //     } else {
    //         address txOrigin;
    //         assembly {
    //             txOrigin := origin()
    //         }
    //         swapDetails.depositor = txOrigin;
    //     }

    //     if (isSourceNative) {
    //         // require(msg.value >= swapDetails.srcTokenAmount, "No native assets sent");
    //         if (msg.value < swapDetails.srcTokenAmount) {
    //             // Insufficient native assets sent
    //             revert VoyagerError(6);
    //         }
    //         convertToWeth(swapDetails.srcTokenAmount);
    //     }

    //     IDepositExecute.ArbitraryInstruction memory arbitraryInstruction = decodeArbitraryData(arbitraryData);

    //     executeDetails.depositNonce = _depositNonReserveToken(isSourceNative, swapDetails);

    //     bytes memory packet = abi.encode(3, msg.sender, swapDetails, executeDetails, arbitraryInstruction);

    //     iSend(packet, msg.value.sub(swapDetails.srcTokenAmount));
    // }

    // function _depositNonReserveToken(
    //     bool isSourceNative,
    //     IDepositExecute.NonReserveSwapInfo memory swapDetails
    // ) internal returns (uint64 nonce) {
    //     // require(_contractWhitelist[swapDetails.srcStableTokenAddress], "token not whitelisted");
    //     // if(!_contractWhitelist[swapDetails.srcStableTokenAddress]) {
    //     //     // token not whitelisted
    //     //     revert VoyagerError(7);
    //     // }
    //     // require(
    //     //     swapDetails.srcStableTokenAmount >= _minAmountToSwap[swapDetails.srcStableTokenAddress],
    //     //     "min amount lower than required"
    //     // );

    //     // if(swapDetails.srcStableTokenAmount < _minAmountToSwap[swapDetails.srcStableTokenAddress]) {
    //     //     // min amount lower than required
    //     //     revert VoyagerError(8);
    //     // }

    //     checks(swapDetails.srcStableTokenAddress, swapDetails.srcStableTokenAmount);

    //     // require(!(swapDetails.srcTokenAddress == swapDetails.srcStableTokenAddress), "data for reserve transfer");
    //     if (swapDetails.srcTokenAddress == swapDetails.srcStableTokenAddress) {
    //         // data for reserve transfer
    //         revert VoyagerError(11);
    //     }

    //     // require(
    //     //     !(_reserve._contractToLP(swapDetails.srcStableTokenAddress) == swapDetails.srcTokenAddress),
    //     //     "data for LP transfer"
    //     // );

    //     if (_reserve._contractToLP(swapDetails.srcStableTokenAddress) == swapDetails.srcTokenAddress) {
    //         // data for LP transfer
    //         revert VoyagerError(12);
    //     }

    //     if (!isSourceNative) {
    //         _reserve.lockERC20(
    //             swapDetails.srcTokenAddress,
    //             swapDetails.depositor,
    //             _oneSplitAddress,
    //             swapDetails.srcTokenAmount
    //         );
    //     } else {
    //         IERC20(_WETH).safeTransfer(address(_reserve), swapDetails.srcTokenAmount);
    //     }

    //     _handleDepositForNonReserveToken(swapDetails);

    //     if (_burnList[swapDetails.srcStableTokenAddress]) {
    //         _reserve.burnERC20(swapDetails.srcStableTokenAddress, address(_reserve), swapDetails.srcStableTokenAmount);
    //     } else if (
    //         swapDetails.srcStableTokenAddress == _usdc && _isUsdcBurnableMintable[swapDetails.destChainIdBytes]
    //     ) {
    //         handleUsdcBurn(swapDetails.destChainIdBytes, swapDetails.srcStableTokenAmount);
    //     }

    //     unchecked {
    //         nonce = ++depositNonce[swapDetails.destChainIdBytes];
    //     }
    // }

    // /// @notice Handles deposit for non-reserve tokens
    // /// @param swapDetails swapInfo struct for the swap details
    // function _handleDepositForNonReserveToken(IDepositExecute.NonReserveSwapInfo memory swapDetails) internal {
    //     uint256 pathLength = swapDetails.path.length;
    //     if (pathLength > 2) {
    //         //swapMulti
    //         require(swapDetails.path[pathLength - 1] == swapDetails.srcStableTokenAddress);
    //         swapDetails.srcStableTokenAmount = _reserve.swapMulti(
    //             _oneSplitAddress,
    //             swapDetails.path,
    //             swapDetails.srcTokenAmount,
    //             swapDetails.srcStableTokenAmount,
    //             swapDetails.flags,
    //             swapDetails.dataTx
    //         );
    //     } else {
    //         swapDetails.srcStableTokenAmount = _reserve.swap(
    //             _oneSplitAddress,
    //             swapDetails.srcTokenAddress,
    //             swapDetails.srcStableTokenAddress,
    //             swapDetails.srcTokenAmount,
    //             swapDetails.srcStableTokenAmount,
    //             swapDetails.flags[0],
    //             swapDetails.dataTx[0]
    //         );
    //     }
    // }

    // /// @notice Function to handle the request for execution received from Router Chain
    // /// @param requestSender Address of the sender of the transaction on the source chain.
    // /// @param packet Packet coming from the router chain.
    // function iReceive(
    //     bytes memory requestSender,
    //     bytes memory packet,
    //     string memory //srcChainId
    // ) external isGateway nonReentrant whenNotPaused {
    //     Setter.iReceive(_executionRevertCompleted, _burnList, _reserve, routerBridge, requestSender, packet);
    //     // require(
    //     //     keccak256(abi.encodePacked(sender)) == keccak256(abi.encodePacked(routerBridge)),
    //     //     "only Voyager middleware"
    //     // );
    //     // uint8 txType = abi.decode(packet, (uint8));

    //     // /// Refunding user money in case of some issues on dest chain
    //     // if (txType == 2) {
    //     //     (, bytes32 destChainIdBytes, uint64 _depositNonce, IDepositExecute.DepositData memory depositData) = abi
    //     //         .decode(packet, (uint8, bytes32, uint64, IDepositExecute.DepositData));

    //     //     require(!_executionRevertCompleted[destChainIdBytes][_depositNonce], "already reverted");

    //     //     // IDepositExecute.DepositData memory depositData = _depositData[destChainIdBytes][_depositNonce];
    //     //     require(depositData.srcStableTokenAddress != address(0), "no deposit found");

    //     //     _executionRevertCompleted[destChainIdBytes][_depositNonce] = true;

    //     //     if (isBurnable(depositData.srcStableTokenAddress)) {
    //     //         _reserve.mintERC20(
    //     //             depositData.srcStableTokenAddress,
    //     //             depositData.sender,
    //     //             depositData.srcStableTokenAmount
    //     //         );
    //     //     } else {
    //     //         IERC20(depositData.srcStableTokenAddress).safeTransfer(
    //     //             depositData.sender,
    //     //             depositData.srcStableTokenAmount
    //     //         );
    //     //     }

    //     //     emit DepositReverted(
    //     //         destChainIdBytes,
    //     //         _depositNonce,
    //     //         depositData.sender,
    //     //         depositData.srcStableTokenAddress,
    //     //         depositData.srcStableTokenAmount
    //     //     );
    //     // }
    // }

    // /// @notice Used to manually release ERC20 tokens from ERC20Safe
    // /// @param tokenAddress Address of token contract to release.
    // /// @param recipient Address to release tokens to.
    // /// @param amount The amount of ERC20 tokens to release.
    // function withdraw(address tokenAddress, address recipient, uint256 amount) external onlyRole(DEFAULT_ADMIN_ROLE) {
    //     _reserve.releaseERC20(tokenAddress, recipient, amount);
    // }

    // /// @notice Function to handle USDC burn and sets the details in the _usdcBurnData
    // /// @param  destChainIdBytes keccak256(abi.encode(destChainId))
    // /// @param  amount amount to be burnt
    // function handleUsdcBurn(bytes32 destChainIdBytes, uint256 amount) internal {
    //     _reserve.giveAllowance(_usdc, address(this), amount);

    //     IDepositExecute.DestDetails memory destDetails = chainIdToDestDetails[destChainIdBytes];
    //     // require(destDetails.reserveHandlerAddress != address(0), "dest chain not configured");
    //     if (destDetails.reserveHandlerAddress == address(0)) {
    //         // dest chain not configured
    //         revert VoyagerError(16);
    //     }
    //     address usdc = _usdc;

    //     IERC20(usdc).safeTransferFrom(address(_reserve), address(this), amount);
    //     IERC20(usdc).safeApprove(address(tokenMessenger), amount);

    //     bytes32 _destCaller = bytes32(uint256(uint160(destDetails.destCallerAddress)));
    //     bytes32 _mintRecipient = bytes32(uint256(uint160(destDetails.reserveHandlerAddress)));

    //     tokenMessenger.depositForBurnWithCaller(amount, destDetails.usdcDomainId, _mintRecipient, usdc, _destCaller);
    // }

    // /// @notice Function to change the destCaller and mintRecipient for a USDC burn tx.
    // /// @notice Only DEFAULT_ADMIN can call this function.
    // /// @param  originalMessage Original message received when the USDC was burnt.
    // /// @param  originalAttestation Original attestation received from the API.
    // /// @param  newDestCaller Address of the new destination caller.
    // /// @param  newMintRecipient Address of the new mint recipient.
    // function changeDestCallerOrMintRecipient(
    //     bytes memory originalMessage,
    //     bytes calldata originalAttestation,
    //     address newDestCaller,
    //     address newMintRecipient
    // ) external onlyRole(RESOURCE_SETTER) {
    //     Setter.changeDestCallerOrMintRecipient(
    //         tokenMessenger,
    //         originalMessage,
    //         originalAttestation,
    //         newDestCaller,
    //         newMintRecipient
    //     );
    //     // bytes32 _destCaller = bytes32(uint256(uint160(newDestCaller)));
    //     // bytes32 _mintRecipient = bytes32(uint256(uint160(newMintRecipient)));

    //     // tokenMessenger.replaceDepositForBurn(originalMessage, originalAttestation, _destCaller, _mintRecipient);
    // }

    // /// @notice Function to withdraw funds from this contract.
    // /// @notice Only DEFAULT_ADMIN can call this function.
    // /// @param  token Address of token to withdraw. If native token, send address 0.
    // /// @param  amount Amount of tokens to withdraw. If all tokens, send 0.
    // /// @param  recipient Address of recipient.
    // function withdrawFunds(
    //     address token,
    //     uint256 amount,
    //     address payable recipient
    // ) external onlyRole(DEFAULT_ADMIN_ROLE) {
    //     if (token == address(0)) {
    //         amount = amount != 0 ? amount : address(this).balance;
    //         recipient.transfer(amount);
    //     } else {
    //         IERC20 _token = IERC20(token);
    //         amount = amount != 0 ? amount : _token.balanceOf(address(this));
    //         _token.safeTransfer(recipient, amount);
    //     }
    // }
}