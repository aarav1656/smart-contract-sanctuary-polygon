// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/AccessControl.sol)

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
        _checkRole(role, _msgSender());
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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
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

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
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
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

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
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
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
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

/// @title Plugins for the SandRewardPool that calculate the contributions must implement this interface
interface IContributionCalculator {
    /// @notice based on the user stake and address calculate the contribution
    /// @param account address of the user that is staking tokens
    /// @param amountStaked the amount of tokens stacked
    function computeContribution(address account, uint256 amountStaked) external returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

/// @title Plugins for Reward Pools that calculate the rewards must implement this interface
interface IRewardCalculator {
    /// @dev At any point in time this function must return the accumulated rewards from the last call to restartRewards
    function getRewards() external view returns (uint256);

    /// @dev The main contract has distributed the rewards (getRewards()) until this point, this must start
    /// @dev from scratch => getRewards() == 0
    function restartRewards() external;
}

//SPDX-License-Identifier: MIT

pragma solidity 0.8.2;

import "@openzeppelin/contracts-442/utils/Context.sol";
import "@openzeppelin/contracts-442/token/ERC20/utils/SafeERC20.sol";
import {Address} from "@openzeppelin/contracts-442/utils/Address.sol";

abstract contract StakeTokenWrapper is Context {
    using Address for address;
    using SafeERC20 for IERC20;
    IERC20 internal _stakeToken;

    uint256 internal _totalSupply;
    mapping(address => uint256) internal _balances;

    constructor(IERC20 stakeToken) {
        require(address(stakeToken).isContract(), "StakeTokenWrapper: is not a contract");
        _stakeToken = stakeToken;
    }

    function _stake(uint256 amount) internal virtual {
        require(amount > 0, "StakeTokenWrapper: amount > 0");
        _totalSupply = _totalSupply + amount;
        _balances[_msgSender()] = _balances[_msgSender()] + amount;
        _stakeToken.safeTransferFrom(_msgSender(), address(this), amount);
    }

    function _withdraw(uint256 amount) internal virtual {
        require(amount > 0, "StakeTokenWrapper: amount > 0");
        _totalSupply = _totalSupply - amount;
        _balances[_msgSender()] = _balances[_msgSender()] - amount;
        _stakeToken.safeTransfer(_msgSender(), amount);
    }

    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import {Context} from "@openzeppelin/contracts-442/utils/Context.sol";
import {SafeERC20} from "@openzeppelin/contracts-442/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts-442/token/ERC20/IERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts-442/security/ReentrancyGuard.sol";
import {Address} from "@openzeppelin/contracts-442/utils/Address.sol";
import {AccessControl} from "@openzeppelin/contracts-442/access/AccessControl.sol";
import {ERC2771Handler} from "./lib/ERC2771Handler.sol";
import {StakeTokenWrapper} from "./lib/StakeTokenWrapper.sol";
import {IContributionCalculator} from "./lib/IContributionCalculator.sol";
import {IRewardCalculator} from "./lib/IRewardCalculator.sol";

/// @title A pool that distributes rewards between users that stake sand (or any erc20 token)
/// @notice The contributions are updated passively, an external call to computeContribution from a backend is needed.
/// @notice After initialization the reward calculator must be set by the admin.
/// @dev The contract has two plugins that affect the behaviour: contributionCalculator and rewardCalculator
/// @dev contributionCalculator instead of using the stake directly the result of computeContribution is used
/// @dev this way some users can get an extra share of the rewards
/// @dev rewardCalculator is used to manage the rate at which the rewards are distributed.
/// @dev This way we can build different types of pools by mixing in the plugins we want with this contract.
/// @dev default behaviour (address(0)) for contributionCalculator is to use the stacked amount as contribution.
/// @dev default behaviour (address(0)) for rewardCalculator is that no rewards are giving
contract SandPool is StakeTokenWrapper, AccessControl, ReentrancyGuard, ERC2771Handler {
    using SafeERC20 for IERC20;
    using Address for address;

    event Staked(address indexed account, uint256 stakeAmount);
    event Withdrawn(address indexed account, uint256 stakeAmount);
    event Exit(address indexed account);
    event RewardPaid(address indexed account, uint256 rewardAmount);
    event ContributionUpdated(address indexed account, uint256 newContribution, uint256 oldContribution);

    // This value multiplied by the user contribution is the share of accumulated rewards (from the start of time
    // until the last call to restartRewards) for the user taking into account the value of totalContributions.
    uint256 public rewardPerTokenStored;

    // This value multiplied by the user contribution is the share of reward from the the last time
    // the user changed his contribution and called restartRewards
    mapping(address => uint256) public userRewardPerTokenPaid;

    // This value is the accumulated rewards won by the user when he called the contract.
    mapping(address => uint256) public rewards;

    IERC20 public rewardToken;
    IContributionCalculator public contributionCalculator;
    IRewardCalculator public rewardCalculator;

    uint256 internal _totalContributions;
    mapping(address => uint256) internal _contributions;

    struct AntiCompound {
        uint256 lockPeriodInSecs;
        mapping(address => uint256) lastClaim;
    }
    // This is used to implement a time buffer for reward retrieval, so the used cannot re-stake the rewards too fast.
    AntiCompound public antiCompound;

    constructor(
        IERC20 stakeToken_,
        IERC20 rewardToken_,
        address trustedForwarder
    ) StakeTokenWrapper(stakeToken_) {
        rewardToken = rewardToken_;
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        __ERC2771Handler_initialize(trustedForwarder);
    }

    modifier antiCompoundCheck(address account) {
        // We use lockPeriodInSecs == 0 to disable this check
        if (antiCompound.lockPeriodInSecs != 0) {
            require(
                block.timestamp > antiCompound.lastClaim[account] + antiCompound.lockPeriodInSecs,
                "SandRewardPool: must wait"
            );
        }
        antiCompound.lastClaim[account] = block.timestamp;
        _;
    }

    modifier isContractAndAdmin(address contractAddress) {
        require(contractAddress.isContract(), "SandRewardPool: not a contract");
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "SandRewardPool: not admin");
        _;
    }

    /// @notice set the lockPeriodInSecs for the anti-compound buffer
    /// @param lockPeriodInSecs amount of time the user must wait between reward withdrawal
    function setAntiCompoundLockPeriod(uint256 lockPeriodInSecs) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "SandRewardPool: not admin");
        antiCompound.lockPeriodInSecs = lockPeriodInSecs;
    }

    /// @notice set the contribution calculator
    /// @param contractAddress address of a plugin that calculates the contribution of the user based on his stake
    function setContributionCalculator(address contractAddress) external isContractAndAdmin(contractAddress) {
        contributionCalculator = IContributionCalculator(contractAddress);
    }

    /// @notice set the reward token
    /// @param contractAddress address token used to pay rewards
    function setRewardToken(address contractAddress) external isContractAndAdmin(contractAddress) {
        rewardToken = IERC20(contractAddress);
    }

    /// @notice set the stake token
    /// @param contractAddress address token used to stake funds
    function setStakeToken(address contractAddress) external isContractAndAdmin(contractAddress) {
        _stakeToken = IERC20(contractAddress);
    }

    /// @notice set the trusted forwarder
    /// @param trustedForwarder address of the contract that is enabled to send meta-tx on behalf of the user
    function setTrustedForwarder(address trustedForwarder) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "SandRewardPool: not admin");
        _trustedForwarder = trustedForwarder;
    }

    /// @notice set the reward calculator
    /// @param contractAddress address of a plugin that calculates absolute rewards at any point in time
    /// @param doRestartRewards if true the rewards from the previous calculator are accumulated before changing it
    function setRewardCalculator(address contractAddress, bool doRestartRewards)
        external
        isContractAndAdmin(contractAddress)
    {
        // We process the rewards of the current reward calculator before the switch.
        if (doRestartRewards) {
            _restartRewards();
        }
        rewardCalculator = IRewardCalculator(contractAddress);
    }

    /// @notice the admin recover is able to recover reward funds
    /// @param receiver address of the beneficiary of the recovered funds
    /// @dev this function must be called in an emergency situation only.
    /// @dev Calling it is risky specially when rewardToken == stakeToken
    function recoverFunds(address receiver) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "SandRewardPool: not admin");
        require(receiver != address(0), "SandRewardPool: invalid receiver");
        rewardToken.safeTransfer(receiver, rewardToken.balanceOf(address(this)));
    }

    /// @notice return the total supply of staked tokens
    /// @return the total supply of staked tokens
    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    /// @notice return the balance of staked tokens for a user
    /// @param account the address of the account
    /// @return balance of staked tokens
    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    /// @notice return the address of the stake token contract
    /// @return address of the stake token contract
    function stakeToken() external view returns (IERC20) {
        return _stakeToken;
    }

    /// @notice return the amount of rewards deposited in the contract that can be distributed by different campaigns
    /// @return the total amount of deposited rewards
    /// @dev this function can be called by a reward calculator to throw if a campaign doesn't have
    /// @dev enough rewards to start
    function getRewardsAvailable() external view returns (uint256) {
        if (address(rewardToken) != address(_stakeToken)) {
            return rewardToken.balanceOf(address(this));
        }
        return _stakeToken.balanceOf(address(this)) - _totalSupply;
    }

    /// @notice return the sum of the values returned by the contribution calculator
    /// @return total contributions of the users
    /// @dev this is the same than the totalSupply only if the contribution calculator
    /// @dev uses the staked amount as the contribution of the user which is the default behaviour
    function totalContributions() external view returns (uint256) {
        return _totalContributions;
    }

    /// @notice return the contribution of some user
    /// @param account the address of the account
    /// @return contribution of the users
    /// @dev this is the same than the balanceOf only if the contribution calculator
    /// @dev uses the staked amount as the contribution of the user which is the default behaviour
    function contributionOf(address account) external view returns (uint256) {
        return _contributions[account];
    }

    /// @notice accumulated rewards taking into account the totalContribution (see: rewardPerTokenStored)
    /// @return the accumulated total rewards
    /// @dev This value multiplied by the user contribution is the share of accumulated rewards for the user. Taking
    /// @dev into account the value of totalContributions.
    function rewardPerToken() external view returns (uint256) {
        return rewardPerTokenStored + _rewardPerToken();
    }

    /// @notice available earnings for some user
    /// @param account the address of the account
    /// @return the available earnings for the user
    function earned(address account) external view returns (uint256) {
        return rewards[account] + _earned(account, _rewardPerToken());
    }

    /// @notice accumulates the current rewards into rewardPerTokenStored and restart the reward calculator
    /// @dev calling this function make no difference. It is useful for testing and when the reward calculator
    /// @dev is changed.
    function restartRewards() external {
        _restartRewards();
    }

    /// @notice update the contribution for a user
    /// @param account the address of the account
    /// @dev if the user change his holdings (or any other parameter that affect the contribution calculation),
    /// @dev he can the reward distribution to his favor. This function must be called by an external agent ASAP to
    /// @dev update the contribution for the user. We understand the risk but the rewards are distributes slowly so
    /// @dev the user cannot affect the reward distribution heavily.
    function computeContribution(address account) external {
        require(account != address(0), "SandRewardPool: invalid address");
        // We decide to give the user the accumulated rewards even if he cheated a little bit.
        _processRewards(account);
        _updateContribution(account);
    }

    /// @notice update the contribution for a sef of users
    /// @param accounts the addresses of the accounts to update
    /// @dev see: computeContribution
    function computeContributionInBatch(address[] calldata accounts) external {
        _restartRewards();
        for (uint256 i = 0; i < accounts.length; i++) {
            address account = accounts[i];
            if (account == address(0)) {
                continue;
            }
            _processAccountRewards(account);
            _updateContribution(account);
        }
    }

    /// @notice stake some amount into the contract
    /// @param amount the amount of tokens to stake
    /// @dev the user must approve in the stack token before calling this function
    function stake(uint256 amount) external nonReentrant {
        require(amount > 0, "SandRewardPool: Cannot stake 0");

        // The first time a user stakes he cannot remove his rewards immediately.
        if (antiCompound.lastClaim[_msgSender()] == 0) {
            antiCompound.lastClaim[_msgSender()] = block.timestamp;
        }

        uint256 earlierRewards = 0;

        if (_totalContributions == 0 && rewardCalculator != IRewardCalculator(address(0))) {
            earlierRewards = rewardCalculator.getRewards();
        }

        _processRewards(_msgSender());
        super._stake(amount);
        _updateContribution(_msgSender());
        require(_contributions[_msgSender()] > 0, "SandRewardPool: not enough contributions");

        if (earlierRewards != 0) {
            rewards[_msgSender()] = rewards[_msgSender()] + earlierRewards;
        }
        emit Staked(_msgSender(), amount);
    }

    /// @notice withdraw the stake from the contract
    /// @param amount the amount of tokens to withdraw
    /// @dev the user can withdraw his stake independently from the rewards
    function withdraw(uint256 amount) external nonReentrant {
        _processRewards(_msgSender());
        _withdrawStake(_msgSender(), amount);
        _updateContribution(_msgSender());
    }

    /// @notice withdraw the stake and the rewards from the contract
    function exit() external nonReentrant {
        _processRewards(_msgSender());
        _withdrawStake(_msgSender(), _balances[_msgSender()]);
        _withdrawRewards(_msgSender());
        _updateContribution(_msgSender());
        emit Exit(_msgSender());
    }

    /// @notice withdraw the rewards from the contract
    /// @dev the user can withdraw his stake independently from the rewards
    function getReward() external nonReentrant {
        _processRewards(_msgSender());
        _withdrawRewards(_msgSender());
        _updateContribution(_msgSender());
    }

    function _withdrawStake(address account, uint256 amount) internal {
        require(amount > 0, "SandRewardPool: Cannot withdraw 0");
        super._withdraw(amount);
        emit Withdrawn(account, amount);
    }

    function _withdrawRewards(address account) internal antiCompoundCheck(account) {
        uint256 reward = rewards[account];
        if (reward > 0) {
            rewards[account] = 0;
            rewardToken.safeTransfer(account, reward);
            emit RewardPaid(account, reward);
        }
    }

    function _updateContribution(address account) internal {
        uint256 oldContribution = _contributions[account];
        _totalContributions = _totalContributions - oldContribution;
        uint256 contribution = _computeContribution(account);
        _totalContributions = _totalContributions + contribution;
        _contributions[account] = contribution;
        emit ContributionUpdated(account, contribution, oldContribution);
    }

    function _computeContribution(address account) internal returns (uint256) {
        if (contributionCalculator == IContributionCalculator(address(0))) {
            return _balances[account];
        } else {
            return contributionCalculator.computeContribution(account, _balances[account]);
        }
    }

    // Something changed (stake, withdraw, etc), we distribute current accumulated rewards and start from zero.
    // Called each time there is a change in contract state (stake, withdraw, etc).
    function _processRewards(address account) internal {
        _restartRewards();
        _processAccountRewards(account);
    }

    // Update the earnings for this specific user with what he earned until now
    function _processAccountRewards(address account) internal {
        // usually _earned takes _rewardPerToken() but in this method is zero because _restartRewards must be
        // called before _processAccountRewards
        rewards[account] = rewards[account] + _earned(account, 0);
        // restart rewards for this specific user, now earned(account) = 0
        userRewardPerTokenPaid[account] = rewardPerTokenStored;
    }

    function _restartRewards() internal {
        if (rewardCalculator != IRewardCalculator(address(0))) {
            // Distribute the accumulated rewards
            rewardPerTokenStored = rewardPerTokenStored + _rewardPerToken();
            // restart rewards so now the rewardCalculator return zero rewards
            rewardCalculator.restartRewards();
        }
    }

    function _earned(address account, uint256 mRewardPerToken) internal view returns (uint256) {
        // - userRewardPerTokenPaid[account] * _contributions[account]  / _totalContributions is the portion of
        //      rewards the last time the user changed his contribution and called _restartRewards
        //      (_totalContributions corresponds to previous value of that moment).
        // - rewardPerTokenStored * _contributions[account] is the share of the user from the
        //      accumulated rewards (from the start of time until the last call to _restartRewards) with the
        //      current value of _totalContributions
        // - _rewardPerToken() * _contributions[account]  / _totalContributions is the share of the user of the
        //      rewards from the last time anybody called _restartRewards until this moment
        //
        // The important thing to note is that at any moment in time _contributions[account] / _totalContributions is
        // the share of the user even if _totalContributions changes because of other users activity.
        return
            ((mRewardPerToken + rewardPerTokenStored - userRewardPerTokenPaid[account]) * _contributions[account]) /
            1e24;
    }

    // This function gives the proportion of the total contribution that corresponds to each user from
    // last restartRewards call.
    // _rewardsPerToken() * _contributions[account] is the amount of extra rewards gained from last restartRewards.
    function _rewardPerToken() internal view returns (uint256) {
        if (rewardCalculator == IRewardCalculator(address(0)) || _totalContributions == 0) {
            return 0;
        }
        return (rewardCalculator.getRewards() * 1e24) / _totalContributions;
    }

    function _msgSender() internal view override(Context, ERC2771Handler) returns (address sender) {
        return ERC2771Handler._msgSender();
    }

    function _msgData() internal view override(Context, ERC2771Handler) returns (bytes calldata) {
        return ERC2771Handler._msgData();
    }
}