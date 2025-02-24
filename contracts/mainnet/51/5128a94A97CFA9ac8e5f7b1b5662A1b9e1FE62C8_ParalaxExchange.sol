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
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

abstract contract EIP712 {
    using ECDSA for bytes32;
    bytes32 public DOMAIN_SEPARATOR;

    function _init(string memory name, string memory version) internal {
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes(name)),
                keccak256(bytes(version)),
                block.chainid,
                address(this)
            )
        );
    }

    function _hashTypedDataV4(bytes32 hashStruct)
        internal
        view
        returns (bytes32 digest)
    {
        digest = keccak256(
            abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, hashStruct)
        );
    }

    function _verify(
        address owner,
        bytes calldata signature,
        bytes32 hashStruct
    ) internal view returns (bool) {
        bytes32 digest = _hashTypedDataV4(hashStruct);
        address recoveredAddress = digest.recover(signature);
        return (recoveredAddress == owner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

abstract contract ExtensionPercent {
    uint256 internal constant PRECISION = 1e6;

    function calcPercent(
        uint256 amount,
        uint256 percent
    ) internal pure returns (uint256 share) {
        return ((amount * percent) / (PRECISION * 100));
    }

    function subtractPercentage(
        uint256 amount,
        uint256 percent
    ) internal pure returns (uint256 remains, uint256 share) {
        share = calcPercent(amount, percent);
        return (amount - share, share);
    }

    function addPercentage(
        uint256 amount,
        uint256 percent
    ) internal pure returns (uint256 remains, uint256 share) {
        share = calcPercent(amount, percent);
        return (amount + share, share);
    }
}

pragma solidity ^0.8.10;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

pragma solidity ^0.8.10;

interface IWETH {
    function deposit() external payable;

    function withdraw(uint wad) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Storage.sol";
import "./interfaces/IWETH.sol";

contract ParalaxExchange is Storage, ReentrancyGuard {
    using SafeERC20 for IERC20;

    event LimitOrderDEX(
        bytes sign,
        address account,
        uint256 amountIn,
        uint256 amountOutMin,
        address[] path
    );
    event LimitOrderP2P(
        bytes sign1,
        bytes sign2,
        address addrOne,
        address addrTwo,
        uint256 amountInOne,
        uint256 amountInTwo
    );
    event SwapDex(
        address account,
        uint256 amountIn,
        uint256 amountOut,
        address[] path
    );

    event TimeMultiplierDCA(
        bytes sign,
        TimeMultiplier tm,
        uint256 amountIn,
        address account
    );

    event LevelOrderDCA(bytes sign, OrderDCA order, uint256 amountIn);

    receive() external payable {}

    /**
     * @notice Swaps an exact amount of input tokens for as many output tokens as possible,
     * along the route determined by the path. The first element of path is the input token,
     * the last is the output token, and any intermediate elements represent intermediate pairs to trade through
     * (if, for example, a direct pair does not exist).
     */

    function swapDex(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path
    ) external {
        (uint256 newAmountIn, uint256 tax) = subtractPercentage(
            amountIn,
            feeDEX
        );

        _transferTax(path[0], msg.sender, tax);
        IERC20(path[0]).safeTransferFrom(
            msg.sender,
            address(this),
            newAmountIn
        );

        uint256[] memory amounts = _swapDex(
            newAmountIn,
            amountOutMin,
            path,
            msg.sender
        );

        emit SwapDex(
            msg.sender,
            newAmountIn,
            amounts[amounts.length - 1],
            path
        );
    }

    /**
     * @notice Swaps an exact amount of ETH for as many output tokens as possible,
     * along the route determined by the path.
     * The first element of path must be WETH, the last is the output token,
     * and any intermediate elements represent intermediate pairs to trade through
     * (if, for example, a direct pair does not exist).
     */
    function swapDexETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path
    ) external payable {
        address wETH = IUniswapV2Router02(_adapter).WETH();
        require(path[0] == wETH || path[path.length - 1] == wETH, "Bad path");
        uint256 newAmountIn;
        uint256 tax;
        uint256[] memory amounts;
        if (path[0] == wETH) {
            require(msg.value == amountIn, "ETH amount error");
            (newAmountIn, tax) = subtractPercentage(msg.value, feeDEX);

            amounts = IUniswapV2Router02(_adapter).swapExactETHForTokens{
                value: newAmountIn
            }(amountOutMin, path, msg.sender, block.timestamp);
            _transferTaxETH(tax);
        } else {
            (newAmountIn, tax) = subtractPercentage(amountIn, feeDEX);
            IERC20(path[0]).safeTransferFrom(
                msg.sender,
                address(this),
                newAmountIn
            );
            _approve(path[0]);

            _transferTax(path[0], msg.sender, tax);

            amounts = IUniswapV2Router02(_adapter).swapExactTokensForETH(
                newAmountIn,
                amountOutMin,
                path,
                msg.sender,
                block.timestamp
            );
        }

        emit SwapDex(
            msg.sender,
            newAmountIn,
            amounts[amounts.length - 1],
            path
        );
    }

    /**

    * @notice p2p trading. Exchanges tokens between two users.
    * Users sign "SignerData", then these data are compared with each other.
    * Opposite orders exchange tokens.
    */
    function limitOrderP2P(
        bytes calldata sign1,
        bytes calldata sign2,
        SignerData memory signerData1,
        SignerData memory signerData2
    ) external nonReentrant {
        _validateData(sign1, sign2, signerData1, signerData2);

        //if the first call of this order
        if (_signerDatas[sign1].account != address(0))
            signerData1 = _signerDatas[sign1];

        // if the first call of this order
        if (_signerDatas[sign2].account != address(0))
            signerData2 = _signerDatas[sign2];

        //we get the amount to transfer
        (
            uint256 amountTransferFromSignerOne,
            uint256 amountTransferFromSignerTwo
        ) = _swapLimitOrderP2P(signerData1, signerData2);

        // update data
        _signerDatas[sign1] = signerData1;
        _signerDatas[sign2] = signerData2;

        // subtract fee
        (
            uint256 newAmountFromSignerOne,
            uint256 taxFromSignerOne
        ) = subtractPercentage(amountTransferFromSignerOne, feeLMP2P);
        (
            uint256 newAmountFromSignerTwo,
            uint256 taxFromSignerTwo
        ) = subtractPercentage(amountTransferFromSignerTwo, feeLMP2P);

        // transfering taxes to the treasure
        _transferTax(
            signerData1.baseCurrency,
            signerData1.account,
            taxFromSignerOne
        );
        _transferTax(
            signerData2.baseCurrency,
            signerData2.account,
            taxFromSignerTwo
        );
        //transferring funds from user 1 to user 2
        if (signerData1.baseCurrency != _wETH) {
            IERC20(signerData1.baseCurrency).safeTransferFrom(
                signerData1.account,
                signerData2.account,
                newAmountFromSignerOne
            );
        } else {
            // we debit WETH from the user and convert them into ETH
            // and we send them to the user
            IERC20(signerData1.baseCurrency).safeTransferFrom(
                signerData1.account,
                address(this),
                newAmountFromSignerOne
            );

            _transferETH(newAmountFromSignerOne, signerData2.account);
        }
        // transferring funds from user 2 to user 1
        if (signerData2.baseCurrency != _wETH) {
            IERC20(signerData2.baseCurrency).safeTransferFrom(
                signerData2.account,
                signerData1.account,
                newAmountFromSignerTwo
            );
        } else {
            // we debit WETH from the user and convert them into ETH
            // and we send them to the user
            IERC20(signerData2.baseCurrency).safeTransferFrom(
                signerData2.account,
                address(this),
                newAmountFromSignerTwo
            );

            _transferETH(newAmountFromSignerTwo, signerData1.account);
        }

        emit LimitOrderP2P(
            sign1,
            sign2,
            signerData1.account,
            signerData2.account,
            newAmountFromSignerOne,
            newAmountFromSignerTwo
        );
    }

    /**
     * @notice Сalling a pre-signed order to exchange for DEX.
     * @param sign signature generated by "signerData"
     * @param signerData order data
     * @param path the path to exchange to uniswap V2
     */
    function limitOrderDEX(
        bytes calldata sign,
        SignerData memory signerData,
        address[] calldata path
    ) external {
        require(_verifySignerData(sign, signerData), "Sign Error");

        if (_signerDatas[sign].account != address(0)) {
            signerData = _signerDatas[sign];
        }

        require(
            signerData.deadline >= block.timestamp || signerData.deadline == 0,
            "Deadline expired"
        );
        require(signerData.amount != 0, "Already executed");

        uint256 amountIn = signerData.amount;

        // subtract fee
        (uint256 newAmountIn, uint256 tax) = subtractPercentage(
            amountIn,
            feeLMDEX
        );

        // transfering taxes to the treasure
        _transferTax(path[0], signerData.account, tax);
        IERC20(path[0]).safeTransferFrom(
            signerData.account,
            address(this),
            newAmountIn
        );

        //we get the minimum amount that the user should receive according to the signed data
        uint8 decimalsQuote = IERC20Metadata(signerData.quoteCurrency)
            .decimals();
        uint256 amountOutMin = _calcQuoteAmount(
            newAmountIn,
            decimalsQuote,
            signerData.price
        );
        // exchange for DEX
        uint256[] memory amounts;
        if (signerData.quoteCurrency != _wETH) {
            // exchange ERC20
            amounts = _swapDex(
                newAmountIn,
                amountOutMin,
                path,
                signerData.account
            );
        } else {
            // exchange ETH
            amounts = _swapDex(newAmountIn, amountOutMin, path, address(this));
            uint transferAmount = amounts[amounts.length - 1];

            _transferETH(transferAmount, signerData.account);
        }

        signerData.amount = 0;
        // update signerData
        _signerDatas[sign] = signerData;

        emit LimitOrderDEX(
            sign,
            signerData.account,
            newAmountIn,
            amounts[amounts.length - 1],
            path
        );
    }

    function orderDCATM(
        bytes calldata sign,
        Order memory order,
        address[] calldata path
    ) public {
        require(_verifyOrder(order, sign), "Sign Error");
        OrderDCA memory orderDca = _ordersDCA[sign];
        // checking for the first entry
        if (_isEmptyDCA(orderDca)) {
            // first entry
            require(_verificationDCA(order.dca), "Verification DCA");
            if (_emptyTM(order.tm)) {
                // first entry without TM
                _levelDCA(sign, order.dca, path);
            } else {
                //first entry with TM

                uint8 decimalsBase = IERC20Metadata(order.dca.baseCurrency)
                    .decimals();
                uint8 decimalsQuote = IERC20Metadata(order.dca.quoteCurrency)
                    .decimals();

                uint256 convertedPrice = _convertPrice(
                    decimalsBase,
                    decimalsQuote,
                    order.dca.price
                );

                order.tm.amount =
                    (order.tm.amount * (10 ** decimalsBase)) /
                    convertedPrice;
                _levelTM(sign, order.dca, order.tm, path);
            }
            _ordersDCA[sign] = order.dca;
            _timeMultipliers[sign] = order.tm;
        } else {
            // subsequent entry
            if (_emptyTM(order.tm)) {
                // entry without TM
                _levelDCA(sign, order.dca, path);
            } else {
                // entry with TM
                _dcaTM(sign, path);
            }
        }
    }

    function _verificationDCA(
        OrderDCA memory orderDca
    ) internal pure returns (bool) {
        return (orderDca.volume != 0 &&
            orderDca.baseCurrency != address(0) &&
            orderDca.quoteCurrency != address(0) &&
            orderDca.account != address(0));
    }

    function _isEmptyDCA(
        OrderDCA memory orderDca
    ) internal pure returns (bool) {
        return (orderDca.volume == 0 ||
            orderDca.baseCurrency == address(0) ||
            orderDca.quoteCurrency == address(0) ||
            orderDca.account == address(0));
    }

    /**
     * @notice execution of a DCA order with TimeMultiplier
     * @param sign signature generated by "Order"
     * @param path the path to exchange to uniswap V2
     */
    function _dcaTM(bytes calldata sign, address[] calldata path) internal {
        TimeMultiplier memory tm = _timeMultipliers[sign];
        ProcessingDCA memory procDCA = _processingDCA[sign];
        OrderDCA memory order = _ordersDCA[sign];

        if (procDCA.doneTM == tm.amount && tm.amount != 0) {
            // completing levels in DCA after completing "Time multiplier"
            require(order.volume != 0, "Init Error");

            require(_validatePriceDCA(order, path), "Price Error");

            _levelDCA(sign, order, path);
        } else {
            // completing levels in "Time multiplier"
            require(order.volume != 0, "Init Error");

            require(procDCA.done < order.volume, "Order Error");

            require(procDCA.doneTM < tm.amount, "TM: Order Error");

            require(_validatePriceDCA(order, path), "Price Error");

            require(tm.amount != 0, "TM: Init Error");

            _levelTM(sign, order, tm, path);
        }
        require(
            procDCA.done + procDCA.doneTM <= order.volume,
            "The order has already been made"
        );
    }

    /**
     * @notice exchange of tokens for "uniswap"
     */
    function _swapDex(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] memory path,
        address account
    ) internal returns (uint256[] memory amounts) {
        _approve(path[0]);

        amounts = _exchangeDex(amountIn, amountOutMin, path, account);
    }

    /**
     * @notice comparison of two prices. The difference should not exceed a delta
     */
    function _validateDelta(
        uint256 price,
        uint256 convertedPrice
    ) internal view {
        int256 signedDelta = int256(100 * PRECISION) -
            int256((price * 100 * PRECISION) / convertedPrice);

        uint256 actualDelta = (signedDelta < 0)
            ? uint256(signedDelta * -1)
            : uint256(signedDelta);

        require(actualDelta <= _delta, "Prices Error");
    }

    /**
     * @dev Validate main properties of the DCA order
     */
    function _validateOrderDCA(
        OrderDCA memory order
    ) internal pure returns (bool) {
        return
            order.volume != 0 &&
            // order.price != 0 &&
            order.levels != 0 &&
            order.period != 0;
    }

    /**
     * @dev Validate trigger price for the DCA order
     */
    function _validatePriceDCA(
        OrderDCA memory order,
        address[] calldata path
    ) internal view returns (bool) {
        if (order.price == 0) return true;

        (uint256 amountOutMin, uint256 actualAmountOut) = _getQuotePrice(
            order,
            0,
            path
        );

        return actualAmountOut >= amountOutMin;
    }

    /**
     * @dev Validate state of the DCA order
     */
    function _validateInitDCA(bytes memory sign) internal view returns (bool) {
        return
            _ordersDCA[sign].volume == 0 && _timeMultipliers[sign].amount == 0;
    }

    /**
     * @dev Validate time multiplier struct
     */
    function _validateTMDCA(Order memory order) internal pure returns (bool) {
        return
            order.tm.amount != 0 &&
            order.tm.interval != 0 &&
            order.tm.amount <= order.dca.volume;
    }

    /**
     * @dev Validate TM struct, should be empty.
     */
    function _emptyTM(TimeMultiplier memory tm) internal pure returns (bool) {
        return tm.amount == 0 && tm.interval == 0;
    }

    /**
     * @dev Get a quote asset price for the DCA order
     */
    function _getQuotePrice(
        OrderDCA memory order,
        uint256 amountIn,
        address[] calldata path
    ) internal view returns (uint256, uint256) {
        require(
            path[0] == order.baseCurrency &&
                path[path.length - 1] == order.quoteCurrency,
            "BAD PATH"
        );
        if (order.price == 0) return (0, 0);
        if (amountIn == 0) {
            amountIn = order.volume / order.levels;
        }

        (uint256 newAmountIn, ) = subtractPercentage(amountIn, feeDCA);

        uint8 decimalsBase = IERC20Metadata(order.baseCurrency).decimals();
        uint8 decimalsQuote = IERC20Metadata(order.quoteCurrency).decimals();

        (uint256 slippedPrice, ) = addPercentage(order.price, order.slippage);

        uint256 convertedPrice = _convertPrice(
            decimalsBase,
            decimalsQuote,
            slippedPrice
        );

        uint256 amountOutMin = (newAmountIn * convertedPrice) /
            10 ** decimalsBase;

        uint256[] memory amounts = _getAmountsOut(path, newAmountIn);

        return (amountOutMin, amounts[amounts.length - 1]);
    }

    /**
     * @notice execution of DCA level logic
     */
    function _levelDCA(
        bytes memory sign,
        OrderDCA memory order,
        address[] calldata path
    ) internal {
        ProcessingDCA memory procDCA = _processingDCA[sign];
        require(
            block.timestamp >= procDCA.lastLevel + order.period,
            "Period Error"
        );
        uint256 scaleAmount = _getScaleAmount(order, procDCA);

        procDCA.scaleAmount = scaleAmount;
        procDCA.lastLevel = block.timestamp;
        procDCA.done += scaleAmount;
        _processingDCA[sign] = procDCA;

        _proceedLevel(order, scaleAmount, path);

        emit LevelOrderDCA(sign, order, scaleAmount);
    }

    /**
     * @notice Getting the amount to exchange at the current level
     */
    function _getScaleAmount(
        OrderDCA memory order,
        ProcessingDCA memory procDCA
    ) internal pure returns (uint256 scaleAmount) {
        if (procDCA.done == 0 || (procDCA.done != 0 && order.scale == 0)) {
            scaleAmount = (order.volume - procDCA.doneTM) / order.levels;
        } else {
            uint256 scalingValue = procDCA.scaleAmount;
            (scaleAmount, ) = addPercentage(scalingValue, order.scale);
        }
        uint256 totalDone = procDCA.done + procDCA.doneTM;
        scaleAmount = (order.volume - totalDone < scaleAmount)
            ? order.volume - totalDone
            : scaleAmount;
    }

    function _levelTM(
        bytes memory sign,
        OrderDCA memory order,
        TimeMultiplier memory tm,
        address[] calldata path
    ) internal returns (uint256 amountIn) {
        ProcessingDCA memory procDCA = _processingDCA[sign];
        require(
            block.timestamp >= procDCA.lastLevel + tm.interval,
            "Interval Error"
        );

        uint256 scaleAmount;
        if (procDCA.doneTM == 0 || (procDCA.doneTM != 0 && order.scale == 0)) {
            scaleAmount = tm.amount / order.levels;
        } else {
            (scaleAmount, ) = addPercentage(procDCA.scaleAmount, order.scale);
        }

        if (tm.amount - procDCA.doneTM <= scaleAmount) {
            amountIn = tm.amount - procDCA.doneTM;

            procDCA.scaleAmount = 0;
            // procDCA.lastLevel = 0;
        } else {
            amountIn = scaleAmount;

            procDCA.scaleAmount = amountIn;
            procDCA.lastLevel = block.timestamp;
        }
        procDCA.doneTM += amountIn;
        _processingDCA[sign] = procDCA;

        _proceedLevel(order, amountIn, path);

        emit TimeMultiplierDCA(sign, tm, amountIn, order.account);
    }

    function _proceedLevel(
        OrderDCA memory order,
        uint256 amountIn,
        address[] calldata path
    ) internal {
        (uint256 newAmountIn, uint256 tax) = subtractPercentage(
            amountIn,
            feeDCA
        );

        _transferTax(order.baseCurrency, order.account, tax);
        IERC20(order.baseCurrency).safeTransferFrom(
            order.account,
            address(this),
            newAmountIn
        );

        (uint256 amountOutMin, ) = _getQuotePrice(order, amountIn, path);
        if (order.quoteCurrency != _wETH) {
            _swapDex(newAmountIn, amountOutMin, path, order.account);
        } else {
            uint256[] memory amounts = _swapDex(
                newAmountIn,
                amountOutMin,
                path,
                address(this)
            );

            _transferETH(amounts[amounts.length - 1], order.account);
        }
    }

    /**
     * @notice Checking the data of two orders
     */
    function _validateData(
        bytes calldata sign1,
        bytes calldata sign2,
        SignerData memory signerData1,
        SignerData memory signerData2
    ) internal view {
        require(_verifySignerData(sign1, signerData1), "Sign1 Error");
        require(_verifySignerData(sign2, signerData2), "Sign2 Error");
        require(
            signerData1.baseCurrency == signerData2.quoteCurrency &&
                signerData1.quoteCurrency == signerData2.baseCurrency,
            "SignData error"
        );
        require(
            (signerData1.deadline >= block.timestamp) ||
                (signerData1.deadline == 0),
            "Deadline expired signer1"
        );
        require(
            (signerData2.deadline >= block.timestamp) ||
                (signerData1.deadline == 0),
            "Deadline expired signer2"
        );
    }

    /**
     * @notice calculation of the amount to be exchanged between orders
     * @return signerOneQuoteAmount - the amount of toxins that must be written off
     *  from the second user and transferred to the first
     * @return signerTwoQuoteAmount - the amount of toxins that must be written off
     *  from the second user and transferred to the first
     */
    function _calcCostQuote(
        SignerData memory signerData1,
        SignerData memory signerData2
    )
        internal
        view
        returns (uint256 signerOneQuoteAmount, uint256 signerTwoQuoteAmount)
    {
        uint8 decimalsBase = IERC20Metadata(signerData1.baseCurrency)
            .decimals();
        uint8 decimalsQuote = IERC20Metadata(signerData1.quoteCurrency)
            .decimals();

        uint256 convertedPrice = _convertPrice(
            decimalsBase,
            decimalsQuote,
            signerData1.price
        );

        _validateDelta(signerData2.price, convertedPrice);

        signerOneQuoteAmount = _calcQuoteAmount(
            signerData1.amount,
            decimalsQuote,
            signerData1.price
        );

        signerTwoQuoteAmount = _calcQuoteAmount(
            signerData2.amount,
            decimalsBase,
            signerData2.price
        );
    }

    /**
     * @notice price conversion from base currency to quote
     */
    function _convertPrice(
        uint256 decimalsBase,
        uint256 decimalsQuote,
        uint256 price
    ) internal pure returns (uint256 convertedPrice) {
        convertedPrice = (10 ** decimalsBase * 10 ** decimalsQuote) / price;
    }

    /**
     * @notice calculation of the amount in the quote currency
     */
    function _calcQuoteAmount(
        uint256 amount,
        uint256 decimals,
        uint256 price
    ) internal pure returns (uint256 quoteAmount) {
        quoteAmount = (amount * 10 ** decimals) / price;
    }

    /**
     * @notice calculation of the amount to be exchanged between two orders
     * @param signerData1 order for comparison
     * @param signerData2 order for comparison
     * @return amountTransferFromSignerOne - the amount of toxins that must be written off
     *  from the first user and transferred to the second
     * @return amountTransferFromSignerTwo - the amount of toxins that must be written off
     *  from the second user and transferred to the first
     */
    function _swapLimitOrderP2P(
        SignerData memory signerData1,
        SignerData memory signerData2
    )
        internal
        view
        returns (
            uint256 amountTransferFromSignerOne,
            uint256 amountTransferFromSignerTwo
        )
    {
        (
            uint256 signerOneQuoteAmount,
            uint256 signerTwoQuoteAmount
        ) = _calcCostQuote(signerData1, signerData2);

        if (signerData1.amount >= signerTwoQuoteAmount) {
            amountTransferFromSignerOne = signerTwoQuoteAmount;
            amountTransferFromSignerTwo = signerData2.amount;

            signerData1.amount -= signerTwoQuoteAmount;
            signerData2.amount = 0;
        } else {
            amountTransferFromSignerOne = signerData1.amount;
            amountTransferFromSignerTwo = signerOneQuoteAmount;
            signerData1.amount = 0;
            signerData2.amount -= signerOneQuoteAmount;
        }
    }

    /**
     * @notice calls the "approve" function to the router address
     */
    function _approve(address token) internal {
        if (IERC20(token).allowance(address(this), _adapter) == 0) {
            IERC20(token).approve(_adapter, type(uint256).max);
        }
    }

    function _exchangeDex(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] memory path,
        address account
    ) internal returns (uint256[] memory amounts) {
        uint256 deadline = block.timestamp + 2 minutes;
        amounts = IUniswapV2Router02(_adapter).swapExactTokensForTokens(
            amountIn,
            amountOutMin,
            path,
            account,
            deadline
        );
    }

    /**
     * @dev Transfer tax to the treasure
     */
    function _transferTaxETH(uint256 tax) internal {
        (bool success, ) = payable(_treasure).call{value: tax}("");
        require(success, "ETH transfer error");
    }

    /**
     * @dev Transfer tax to the treasure
     */
    function _transferTax(
        address asset,
        address from,
        uint256 amount
    ) internal {
        IERC20(asset).safeTransferFrom(from, _treasure, amount);
    }

    /**
     * @notice exchanges WETH for ETH. Sends them to the address
     */
    function _transferETH(uint amount, address account) internal {
        IWETH(_wETH).withdraw(amount);
        (bool success, ) = account.call{value: amount}("");
        require(success, "ETH transfer error");
    }

    /**
     * @notice checks the address that signed the hashed message (`hash`) with  `signature`.
     * @param signature signature received from the user
     * @param  signerData the "SignerData" data structure is required for signature verification
     */
    function _verifySignerData(
        bytes calldata signature,
        SignerData memory signerData
    ) private view returns (bool status) {
        bytes32 hashStruct = _hashStructSignerData(signerData);
        status = EIP712._verify(signerData.account, signature, hashStruct);
    }

    /**
     * @notice checks the address that signed the hashed message (`hash`) with  `signature`.
     * @param signature signature received from the user
     * @param order the "Order" data structure is required for signature verification
     */
    function _verifyOrder(
        Order memory order,
        bytes calldata signature
    ) private view returns (bool status) {
        bytes32 hashOrder = _hashOrderDCA(order);
        status = EIP712._verify(order.dca.account, signature, hashOrder);
    }

    /**
     * @notice hashing struct "signerData"
     */
    function _hashStructSignerData(
        SignerData memory signerData
    ) private pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    SIGNER_DATA,
                    signerData.account,
                    signerData.baseCurrency,
                    signerData.deadline,
                    signerData.quoteCurrency,
                    signerData.price,
                    signerData.amount,
                    signerData.nonce
                )
            );
    }

    /**
     * @notice hashing struct "OrderDCA"
     */
    function _hashStructOrderDCA(
        OrderDCA memory orderDCA
    ) private pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    ORDER_DCA,
                    orderDCA.price,
                    orderDCA.volume,
                    orderDCA.levels,
                    orderDCA.period,
                    orderDCA.slippage,
                    orderDCA.baseCurrency,
                    orderDCA.scale,
                    orderDCA.quoteCurrency,
                    orderDCA.account,
                    orderDCA.nonce
                )
            );
    }

    /**
     * @notice hashing struct "TimeMultiplier"
     */
    function _hashStructTM(
        TimeMultiplier memory tm
    ) private pure returns (bytes32) {
        return keccak256(abi.encode(TIME_MULTIPLIER, tm.amount, tm.interval));
    }

    /**
     * @notice hashing struct "Order"
     */
    function _hashOrderDCA(Order memory order) private pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    ORDER,
                    _hashStructOrderDCA(order.dca),
                    _hashStructTM(order.tm)
                )
            );
    }

    /**
     * @dev UniswapV2Router02 getAmountsOut function
     */
    function _getAmountsOut(
        address[] memory path,
        uint256 amount
    ) internal view returns (uint256[] memory amountsOut) {
        amountsOut = IUniswapV2Router02(_adapter).getAmountsOut(amount, path);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {IUniswapV2Router02} from "./interfaces/IUniswapV2Router02.sol";
import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

import "./EIP712.sol";
import {ExtensionPercent} from "./ExtensionPercent.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

abstract contract Storage is ExtensionPercent, EIP712, AccessControl {
    using SafeERC20 for IERC20;
    struct SignerData {
        address account;
        address baseCurrency;
        uint96 deadline;
        address quoteCurrency;
        uint96 price;
        uint256 amount;
        uint256 nonce;
    }
    struct OrderDCA {
        uint256 price;
        uint128 volume;
        uint64 levels;
        uint64 period;
        uint96 slippage;
        address baseCurrency;
        uint96 scale;
        address quoteCurrency;
        address account;
        uint256 nonce;
    }
    struct TimeMultiplier {
        uint256 amount;
        uint256 interval;
    }
    struct Order {
        OrderDCA dca;
        TimeMultiplier tm;
    }
    struct ProcessingDCA {
        uint256 lastLevel;
        uint256 scaleAmount;
        uint256 done;
        uint256 doneTM;
    }

    enum TypeFee {
        FeeDEX,
        FeeLMDEX,
        FeeLMP2P,
        FeeDCA
    }

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant SIGNER_DATA =
        keccak256(
            "SignerData(address account,address baseCurrency,uint96 deadline,address quoteCurrency,uint96 price,uint256 amount,uint256 nonce)"
        );
    bytes32 public constant ORDER_DCA =
        keccak256(
            "OrderDCA(uint256 price,uint128 volume,uint64 levels,uint64 period,uint96 slippage,address baseCurrency,uint96 scale,address quoteCurrency,address account,uint256 nonce)"
        );
    bytes32 public constant TIME_MULTIPLIER =
        keccak256("TimeMultiplier(uint256 amount,uint256 interval)");
    bytes32 public constant ORDER =
        keccak256(
            "Order(OrderDCA dca,TimeMultiplier tm)OrderDCA(uint256 price,uint128 volume,uint64 levels,uint64 period,uint96 slippage,address baseCurrency,uint96 scale,address quoteCurrency,address account,uint256 nonce)TimeMultiplier(uint256 amount,uint256 interval)"
        );

    address internal _adapter;
    address internal _treasure;
    uint256 internal _delta;
    address internal _wETH;

    address public _implementation;
    uint256 public feeDEX;
    uint256 public feeLMDEX;
    uint256 public feeLMP2P;
    uint256 public feeDCA;

    mapping(bytes => SignerData) internal _signerDatas;
    mapping(bytes => OrderDCA) internal _ordersDCA;
    mapping(bytes => TimeMultiplier) internal _timeMultipliers;
    // mapping(bytes => bool) internal _limitOrdersDEX;
    mapping(bytes => ProcessingDCA) internal _processingDCA;
}