// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
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
abstract contract AccessControl is Context, IAccessControl, ERC165 {
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
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId
            || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
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
    function grantRole(bytes32 role, address account) public virtual override {
        require(hasRole(getRoleAdmin(role), _msgSender()), "AccessControl: sender must be an admin to grant");

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
    function revokeRole(bytes32 role, address account) public virtual override {
        require(hasRole(getRoleAdmin(role), _msgSender()), "AccessControl: sender must be an admin to revoke");

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
}

// SPDX-License-Identifier: MIT

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
    constructor () {
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
}

// SPDX-License-Identifier: MIT

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

    constructor () {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./math/Math.sol";

/**
 * @dev Collection of functions related to array types.
 */
library Arrays {
   /**
     * @dev Searches a sorted `array` and returns the first index that contains
     * a value greater or equal to `element`. If no such index exists (i.e. all
     * values in the array are strictly less than `element`), the array length is
     * returned. Time complexity O(log n).
     *
     * `array` is expected to be sorted in ascending order, and to contain no
     * repeated elements.
     */
    function findUpperBound(uint256[] storage array, uint256 element) internal view returns (uint256) {
        if (array.length == 0) {
            return 0;
        }

        uint256 low = 0;
        uint256 high = array.length;

        while (low < high) {
            uint256 mid = Math.average(low, high);

            // Note that mid will always be strictly less than high (i.e. it will be a valid array index)
            // because Math.average rounds down (it does integer division with truncation).
            if (array[mid] > element) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }

        // At this point `low` is the exclusive upper bound. We will return the inclusive upper bound.
        if (low > 0 && array[low - 1] == element) {
            return low - 1;
        } else {
            return low;
        }
    }
}

// SPDX-License-Identifier: MIT

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

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

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
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
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
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
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

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
library EnumerableSet {
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
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

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

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.4.0;

// computes square roots using the babylonian method
// https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method
library Babylonian {
    // credit for this implementation goes to
    // https://github.com/abdk-consulting/abdk-libraries-solidity/blob/master/ABDKMath64x64.sol#L687
    function sqrt(uint256 x) internal pure returns (uint256) {
        if (x == 0) return 0;
        // this block is equivalent to r = uint256(1) << (BitMath.mostSignificantBit(x) / 2);
        // however that code costs significantly more gas
        uint256 xx = x;
        uint256 r = 1;
        if (xx >= 0x100000000000000000000000000000000) {
            xx >>= 128;
            r <<= 64;
        }
        if (xx >= 0x10000000000000000) {
            xx >>= 64;
            r <<= 32;
        }
        if (xx >= 0x100000000) {
            xx >>= 32;
            r <<= 16;
        }
        if (xx >= 0x10000) {
            xx >>= 16;
            r <<= 8;
        }
        if (xx >= 0x100) {
            xx >>= 8;
            r <<= 4;
        }
        if (xx >= 0x10) {
            xx >>= 4;
            r <<= 2;
        }
        if (xx >= 0x8) {
            r <<= 1;
        }
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1; // Seven iterations should be enough
        uint256 r1 = x / r;
        return (r < r1 ? r : r1);
    }
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

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
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

/**SPDX-License-Identifier: AGPL-3.0

          ▄▄█████████▄                                                                  
       ╓██▀└ ,╓▄▄▄, '▀██▄                                                               
      ██▀ ▄██▀▀╙╙▀▀██▄ └██µ           ,,       ,,      ,     ,,,            ,,,         
     ██ ,██¬ ▄████▄  ▀█▄ ╙█▄      ▄███▀▀███▄   ███▄    ██  ███▀▀▀███▄    ▄███▀▀███,     
    ██  ██ ╒█▀'   ╙█▌ ╙█▌ ██     ▐██      ███  █████,  ██  ██▌    └██▌  ██▌     └██▌    
    ██ ▐█▌ ██      ╟█  █▌ ╟█     ██▌      ▐██  ██ └███ ██  ██▌     ╟██ j██       ╟██    
    ╟█  ██ ╙██    ▄█▀ ▐█▌ ██     ╙██      ██▌  ██   ╙████  ██▌    ▄██▀  ██▌     ,██▀    
     ██ "██, ╙▀▀███████████⌐      ╙████████▀   ██     ╙██  ███████▀▀     ╙███████▀`     
      ██▄ ╙▀██▄▄▄▄▄,,,                ¬─                                    '─¬         
       ╙▀██▄ '╙╙╙▀▀▀▀▀▀▀▀                                                               
          ╙▀▀██████R⌐                                                                   

 */
pragma solidity >=0.8.3;

import "@openzeppelin/contracts/utils/Address.sol";
import "./interfaces/IMulticall.sol";
import "./OndoRegistryClient.sol";

/// @title Multicall
/// @notice Enables calling multiple methods in a single call to the contract
abstract contract Multicall is IMulticall, OndoRegistryClient {
  using Address for address;

  /// @inheritdoc IMulticall
  function multiexcall(ExCallData[] calldata exCallData)
    external
    payable
    override
    isAuthorized(OLib.GUARDIAN_ROLE)
    returns (bytes[] memory results)
  {
    results = new bytes[](exCallData.length);
    for (uint256 i = 0; i < exCallData.length; i++) {
      results[i] = exCallData[i].target.functionCallWithValue(
        exCallData[i].data,
        exCallData[i].value,
        "Multicall: multiexcall failed"
      );
    }
  }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.3;

import "contracts/OndoRegistryClientInitializable.sol";

abstract contract OndoRegistryClient is OndoRegistryClientInitializable {
  constructor(address _registry) {
    __OndoRegistryClient__initialize(_registry);
  }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.3;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "contracts/interfaces/IRegistry.sol";
import "contracts/libraries/OndoLibrary.sol";

abstract contract OndoRegistryClientInitializable is
  Initializable,
  ReentrancyGuard,
  Pausable
{
  using SafeERC20 for IERC20;

  IRegistry public registry;
  uint256 public denominator;

  // solhint-disable-next-line func-name-mixedcase
  function __OndoRegistryClient__initialize(address _registry)
    internal
    initializer
  {
    require(_registry != address(0), "Invalid registry address");
    registry = IRegistry(_registry);
    denominator = registry.denominator();
  }

  /**
   * @notice General ACL checker
   * @param _role Role as defined in OndoLibrary
   */
  modifier isAuthorized(bytes32 _role) {
    require(registry.authorized(_role, msg.sender), "Unauthorized");
    _;
  }

  /*
   * @notice Helper to expose a Pausable interface to tools
   */
  function paused() public view virtual override returns (bool) {
    return registry.paused() || super.paused();
  }

  function pause() external virtual isAuthorized(OLib.PANIC_ROLE) {
    super._pause();
  }

  function unpause() external virtual isAuthorized(OLib.GUARDIAN_ROLE) {
    super._unpause();
  }

  /**
   * @notice Grab tokens and send to caller
   * @dev If the _amount[i] is 0, then transfer all the tokens
   * @param _tokens List of tokens
   * @param _amounts Amount of each token to send
   */
  function _rescueTokens(address[] calldata _tokens, uint256[] memory _amounts)
    internal
    virtual
  {
    for (uint256 i = 0; i < _tokens.length; i++) {
      uint256 amount = _amounts[i];
      if (amount == 0) {
        amount = IERC20(_tokens[i]).balanceOf(address(this));
      }
      IERC20(_tokens[i]).safeTransfer(msg.sender, amount);
    }
  }

  function rescueTokens(address[] calldata _tokens, uint256[] memory _amounts)
    public
    whenPaused
    isAuthorized(OLib.GUARDIAN_ROLE)
  {
    require(_tokens.length == _amounts.length, "Invalid array sizes");
    _rescueTokens(_tokens, _amounts);
  }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.3;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "contracts/interfaces/ITrancheToken.sol";
import "contracts/interfaces/IRegistry.sol";
import "contracts/libraries/OndoLibrary.sol";
import "contracts/interfaces/IWETH.sol";

/**
 * @title Global values used by many contracts
 * @notice This is mostly used for access control
 */
contract Registry is IRegistry, AccessControl {
  using EnumerableSet for EnumerableSet.AddressSet;
  bool private _paused;
  mapping(bytes32 => bool) private featureFlags;

  uint256 public constant override denominator = 10000;

  IWETH public immutable override weth;

  address payable public fallbackRecipient;

  mapping(address => string) public strategistNames;

  modifier onlyRole(bytes32 _role) {
    require(hasRole(_role, msg.sender), "Unauthorized: Invalid role");
    _;
  }

  constructor(
    address _governance,
    address payable _fallbackRecipient,
    address _weth
  ) {
    require(
      _fallbackRecipient != address(0) && _fallbackRecipient != address(this),
      "Invalid address"
    );
    require(_governance != address(0), "Invalid governance address");
    require(_weth != address(0), "Invalid weth address");
    _setupRole(DEFAULT_ADMIN_ROLE, _governance);
    _setupRole(OLib.GOVERNANCE_ROLE, _governance);
    _setRoleAdmin(OLib.VAULT_ROLE, OLib.DEPLOYER_ROLE);
    _setRoleAdmin(OLib.ROLLOVER_ROLE, OLib.DEPLOYER_ROLE);
    _setRoleAdmin(OLib.STRATEGY_ROLE, OLib.DEPLOYER_ROLE);
    fallbackRecipient = _fallbackRecipient;
    weth = IWETH(_weth);
  }

  /**
   * @notice General ACL check
   * @param _role One of the predefined roles
   * @param _account Address to check
   * @return Access/Denied
   */
  function authorized(bytes32 _role, address _account)
    public
    view
    override
    returns (bool)
  {
    return hasRole(_role, _account);
  }

  /**
   * @dev Emitted when a feature flag is enabled or disabled.
   */
  event FeatureFlagUpdated(bytes32 indexed featureFlag, bool enabled);

  /**
   * Enables a feature flag.
   */
  function enableFeatureFlag(bytes32 _featureFlag)
    external
    override
    onlyRole(OLib.GOVERNANCE_ROLE)
  {
    featureFlags[_featureFlag] = true;
    emit FeatureFlagUpdated(_featureFlag, true);
  }

  /**
   * Disables a feature flag.
   */
  function disableFeatureFlag(bytes32 _featureFlag)
    external
    override
    onlyRole(OLib.GOVERNANCE_ROLE)
  {
    featureFlags[_featureFlag] = false;
    emit FeatureFlagUpdated(_featureFlag, false);
  }

  /**
   * Returns a feature flag value.
   */
  function getFeatureFlag(bytes32 _featureFlag)
    external
    view
    override
    returns (bool)
  {
    return featureFlags[_featureFlag];
  }

  /**
   * @dev Emitted when the pause is triggered by `account`.
   */
  event Paused(address account);

  /**
   * @dev Emitted when the pause is lifted by `account`.
   */
  event Unpaused(address account);

  /*
   * @notice Helper to expose a Pausable interface to tools
   */
  function paused() public view override returns (bool) {
    return _paused;
  }

  /**
   * @notice Turn on paused variable. Everything stops!
   */
  function pause() external override onlyRole(OLib.PANIC_ROLE) {
    _paused = true;
    emit Paused(msg.sender);
  }

  /**
   * @notice Turn off paused variable. Everything resumes.
   */
  function unpause() external override onlyRole(OLib.GUARDIAN_ROLE) {
    _paused = false;
    emit Unpaused(msg.sender);
  }

  /**
   * @notice Who will get any random eth from dead tranchetokens
   * @param _target Receipient of ETH
   */
  function setFallbackRecipient(address payable _target)
    external
    onlyRole(OLib.GOVERNANCE_ROLE)
  {
    fallbackRecipient = _target;
  }
}

/**SPDX-License-Identifier: AGPL-3.0

          ▄▄█████████▄                                                                  
       ╓██▀└ ,╓▄▄▄, '▀██▄                                                               
      ██▀ ▄██▀▀╙╙▀▀██▄ └██µ           ,,       ,,      ,     ,,,            ,,,         
     ██ ,██¬ ▄████▄  ▀█▄ ╙█▄      ▄███▀▀███▄   ███▄    ██  ███▀▀▀███▄    ▄███▀▀███,     
    ██  ██ ╒█▀'   ╙█▌ ╙█▌ ██     ▐██      ███  █████,  ██  ██▌    └██▌  ██▌     └██▌    
    ██ ▐█▌ ██      ╟█  █▌ ╟█     ██▌      ▐██  ██ └███ ██  ██▌     ╟██ j██       ╟██    
    ╟█  ██ ╙██    ▄█▀ ▐█▌ ██     ╙██      ██▌  ██   ╙████  ██▌    ▄██▀  ██▌     ,██▀    
     ██ "██, ╙▀▀███████████⌐      ╙████████▀   ██     ╙██  ███████▀▀     ╙███████▀`     
      ██▄ ╙▀██▄▄▄▄▄,,,                ¬─                                    '─¬         
       ╙▀██▄ '╙╙╙▀▀▀▀▀▀▀▀                                                               
          ╙▀▀██████R⌐                                                                   

 */
pragma solidity >=0.8.3;

/// @title Multicall interface
/// @notice Enables calling multiple methods in a single call to the contract
interface IMulticall {
  /// @notice External call data structure
  struct ExCallData {
    address target; // The target contract called from the current contract
    bytes data; // The encoded function data
    uint256 value; // The ether to be transfered to the target contract
  }

  /// @notice Call multiple functions in the target contract and return the data from all of them if they all succeed
  /// @dev The `msg.sender` is always the current contract in any method callable from multicall.
  /// @param exdata The external call data for each of the calls to make to this contract
  /// @return results The results from each of the calls passed in via data
  function multiexcall(ExCallData[] calldata exdata)
    external
    payable
    returns (bytes[] memory results);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.3;

/**
 * @notice Interface of contracts that have names.
 */
interface INamable {
  /**
   * @dev Any derived contracts must define a public state variable `name`,
   * or override this function.
   */
  function name() external view returns (string memory);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.3;

import "contracts/libraries/OndoLibrary.sol";
import "contracts/interfaces/ITrancheToken.sol";
import "contracts/interfaces/IStrategy.sol";

interface IPairVault {
  // Container to return Vault info to caller
  struct VaultView {
    uint256 id;
    Asset[] assets;
    IStrategy strategy; // Shared contract that interacts with AMMs
    address creator; // Account that calls createVault
    address strategist; // Has the right to call invest() and redeem(), and harvest() if strategy supports it
    address rollover;
    uint256 hurdleRate; // Return offered to senior tranche
    OLib.State state; // Current state of Vault
    uint256 startAt; // Time when the Vault is unpaused to begin accepting deposits
    uint256 investAt; // Time when investors can't move funds, strategist can invest
    uint256 redeemAt; // Time when strategist can redeem LP tokens, investors can withdraw
  }

  // Track the asset type and amount in different stages
  struct Asset {
    IERC20 token;
    ITrancheToken trancheToken;
    uint256 trancheCap;
    uint256 userCap;
    uint256 deposited;
    uint256 originalInvested;
    uint256 totalInvested; // not literal 1:1, originalInvested + proportional lp from mid-term
    uint256 received;
    uint256 rolloverDeposited;
  }

  function getState(uint256 _vaultId) external view returns (OLib.State);

  function createVault(OLib.VaultParams calldata _params)
    external
    returns (uint256 vaultId);

  function deposit(
    uint256 _vaultId,
    OLib.Tranche _tranche,
    uint256 _amount
  ) external;

  function depositETH(uint256 _vaultId, OLib.Tranche _tranche) external payable;

  function depositLp(uint256 _vaultId, uint256 _amount)
    external
    returns (uint256 seniorTokensOwed, uint256 juniorTokensOwed);

  function invest(
    uint256 _vaultId,
    uint256 _seniorMinOut,
    uint256 _juniorMinOut
  ) external returns (uint256, uint256);

  function redeem(
    uint256 _vaultId,
    uint256 _seniorMinOut,
    uint256 _juniorMinOut
  ) external returns (uint256, uint256);

  function withdraw(uint256 _vaultId, OLib.Tranche _tranche)
    external
    returns (uint256);

  function withdrawETH(uint256 _vaultId, OLib.Tranche _tranche)
    external
    returns (uint256);

  function withdrawLp(uint256 _vaultId, uint256 _amount)
    external
    returns (uint256, uint256);

  function claim(uint256 _vaultId, OLib.Tranche _tranche)
    external
    returns (uint256, uint256);

  function claimETH(uint256 _vaultId, OLib.Tranche _tranche)
    external
    returns (uint256, uint256);

  function depositFromRollover(
    uint256 _vaultId,
    uint256 _rolloverId,
    uint256 _seniorAmount,
    uint256 _juniorAmount
  ) external;

  function rolloverClaim(uint256 _vaultId, uint256 _rolloverId)
    external
    returns (uint256, uint256);

  function setRollover(
    uint256 _vaultId,
    address _rollover,
    uint256 _rolloverId
  ) external;

  function canDeposit(uint256 _vaultId) external view returns (bool);

  function getVaultById(uint256 _vaultId)
    external
    view
    returns (VaultView memory);

  function vaultInvestor(uint256 _vaultId, OLib.Tranche _tranche)
    external
    view
    returns (
      uint256 position,
      uint256 claimableBalance,
      uint256 withdrawableExcess,
      uint256 withdrawableBalance
    );

  function seniorExpected(uint256 _vaultId) external view returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.3;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "contracts/interfaces/IWETH.sol";

/**
 * @title Global values used by many contracts
 * @notice This is mostly used for access control
 */
interface IRegistry is IAccessControl {
  function paused() external view returns (bool);

  function pause() external;

  function unpause() external;

  function enableFeatureFlag(bytes32 _featureFlag) external;

  function disableFeatureFlag(bytes32 _featureFlag) external;

  function getFeatureFlag(bytes32 _featureFlag) external view returns (bool);

  function denominator() external view returns (uint256);

  function weth() external view returns (IWETH);

  function authorized(bytes32 _role, address _account)
    external
    view
    returns (bool);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.3;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "contracts/libraries/OndoLibrary.sol";
import "contracts/interfaces/IPairVault.sol";
import "contracts/interfaces/INamable.sol";

interface IStrategy is INamable {
  // Additional info stored for each Vault
  struct Vault {
    IPairVault origin; // who created this Vault
    IERC20 pool; // the DEX pool
    IERC20 senior; // senior asset in pool
    IERC20 junior; // junior asset in pool
    uint256 shares; // number of shares for ETF-style mid-duration entry/exit
    uint256 seniorExcess; // unused senior deposits
    uint256 juniorExcess; // unused junior deposits
  }

  function vaults(uint256 vaultId)
    external
    view
    returns (
      IPairVault origin,
      IERC20 pool,
      IERC20 senior,
      IERC20 junior,
      uint256 shares,
      uint256 seniorExcess,
      uint256 juniorExcess
    );

  function addVault(
    uint256 _vaultId,
    IERC20 _senior,
    IERC20 _junior
  ) external;

  function addLp(uint256 _vaultId, uint256 _lpTokens) external;

  function removeLp(
    uint256 _vaultId,
    uint256 _shares,
    address to
  ) external;

  function getVaultInfo(uint256 _vaultId)
    external
    view
    returns (IERC20, uint256);

  function invest(
    uint256 _vaultId,
    uint256 _totalSenior,
    uint256 _totalJunior,
    uint256 _extraSenior,
    uint256 _extraJunior,
    uint256 _seniorMinOut,
    uint256 _juniorMinOut
  ) external returns (uint256 seniorInvested, uint256 juniorInvested);

  function sharesFromLp(uint256 vaultId, uint256 lpTokens)
    external
    view
    returns (
      uint256 shares,
      uint256 vaultShares,
      IERC20 pool
    );

  function lpFromShares(uint256 vaultId, uint256 shares)
    external
    view
    returns (uint256 lpTokens, uint256 vaultShares);

  function redeem(
    uint256 _vaultId,
    uint256 _seniorExpected,
    uint256 _seniorMinOut,
    uint256 _juniorMinOut
  ) external returns (uint256, uint256);

  function withdrawExcess(
    uint256 _vaultId,
    OLib.Tranche tranche,
    address to,
    uint256 amount
  ) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.3;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface ITrancheToken is IERC20Upgradeable {
  function mint(address _account, uint256 _amount) external;

  function burn(address _account, uint256 _amount) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.3;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IWETH is IERC20 {
  function deposit() external payable;

  function withdraw(uint256 wad) external;
}

/**SPDX-License-Identifier: AGPL-3.0

          ▄▄█████████▄                                                                  
       ╓██▀└ ,╓▄▄▄, '▀██▄                                                               
      ██▀ ▄██▀▀╙╙▀▀██▄ └██µ           ,,       ,,      ,     ,,,            ,,,         
     ██ ,██¬ ▄████▄  ▀█▄ ╙█▄      ▄███▀▀███▄   ███▄    ██  ███▀▀▀███▄    ▄███▀▀███,     
    ██  ██ ╒█▀'   ╙█▌ ╙█▌ ██     ▐██      ███  █████,  ██  ██▌    └██▌  ██▌     └██▌    
    ██ ▐█▌ ██      ╟█  █▌ ╟█     ██▌      ▐██  ██ └███ ██  ██▌     ╟██ j██       ╟██    
    ╟█  ██ ╙██    ▄█▀ ▐█▌ ██     ╙██      ██▌  ██   ╙████  ██▌    ▄██▀  ██▌     ,██▀    
     ██ "██, ╙▀▀███████████⌐      ╙████████▀   ██     ╙██  ███████▀▀     ╙███████▀`     
      ██▄ ╙▀██▄▄▄▄▄,,,                ¬─                                    '─¬         
       ╙▀██▄ '╙╙╙▀▀▀▀▀▀▀▀                                                               
          ╙▀▀██████R⌐                                                                   

 */
pragma solidity >=0.8.3;

import "@openzeppelin/contracts/utils/Arrays.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title Helper functions
 */
library OLib {
  using Arrays for uint256[];

  // State transition per Vault. Just linear transitions.
  enum State {
    Inactive,
    Deposit,
    Live,
    Withdraw
  }

  // Only supports 2 tranches for now
  enum Tranche {
    Senior,
    Junior
  }

  struct VaultParams {
    address seniorAsset;
    address juniorAsset;
    address strategist;
    address strategy;
    uint256 hurdleRate;
    uint256 startTime;
    uint256 enrollment;
    uint256 duration;
    string seniorName;
    string seniorSym;
    string juniorName;
    string juniorSym;
    uint256 seniorTrancheCap;
    uint256 seniorUserCap;
    uint256 juniorTrancheCap;
    uint256 juniorUserCap;
  }

  struct RolloverParams {
    address strategist;
    string seniorName;
    string seniorSym;
    string juniorName;
    string juniorSym;
  }

  bytes32 public constant GOVERNANCE_ROLE = keccak256("GOVERNANCE_ROLE");
  bytes32 public constant PANIC_ROLE = keccak256("PANIC_ROLE");
  bytes32 public constant GUARDIAN_ROLE = keccak256("GUARDIAN_ROLE");
  bytes32 public constant DEPLOYER_ROLE = keccak256("DEPLOYER_ROLE");
  bytes32 public constant CREATOR_ROLE = keccak256("CREATOR_ROLE");
  bytes32 public constant STRATEGIST_ROLE = keccak256("STRATEGIST_ROLE");
  bytes32 public constant VAULT_ROLE = keccak256("VAULT_ROLE");
  bytes32 public constant ROLLOVER_ROLE = keccak256("ROLLOVER_ROLE");
  bytes32 public constant STRATEGY_ROLE = keccak256("STRATEGY_ROLE");
  bytes32 public constant SINGLE_ASSET_WHITELIST_ROLE =
    keccak256("SINGLE_ASSET_WHITELIST_ROLE");
  bytes32 public constant LAAS_WHITELIST_ROLE =
    keccak256("LAAS_WHITELIST_ROLE");

  // Both sums are running sums. If a user deposits [$1, $5, $3], then
  // userSums would be [$1, $6, $9]. You can figure out the deposit
  // amount be subtracting userSums[i]-userSum[i-1].

  // prefixSums is the total deposited for all investors + this
  // investors deposit at the time this deposit is made. So at
  // prefixSum[0], it would be $1 + totalDeposits, where totalDeposits
  // could be $1000 because other investors have put in money.
  struct Investor {
    uint256[] userSums;
    uint256[] prefixSums;
    bool claimed;
    bool withdrawn;
  }

  /**
   * @dev Given the total amount invested by the Vault, we want to find
   *   out how many of this investor's deposits were actually
   *   used. Use findUpperBound on the prefixSum to find the point
   *   where total deposits were accepted. For example, if $2000 was
   *   deposited by all investors and $1000 was invested, then some
   *   position in the prefixSum splits the array into deposits that
   *   got in, and deposits that didn't get in. That same position
   *   maps to userSums. This is the user's deposits that got
   *   in. Since we are keeping track of the sums, we know at that
   *   position the total deposits for a user was $15, even if it was
   *   15 $1 deposits. And we know the amount that didn't get in is
   *   the last value in userSum - the amount that got it.

   * @param investor A specific investor
   * @param invested The total amount invested by this Vault
   */
  function getInvestedAndExcess(Investor storage investor, uint256 invested)
    internal
    view
    returns (uint256 userInvested, uint256 excess)
  {
    uint256[] storage prefixSums_ = investor.prefixSums;
    uint256 length = prefixSums_.length;
    if (length == 0) {
      // There were no deposits. Return 0, 0.
      return (userInvested, excess);
    }
    uint256 leastUpperBound = prefixSums_.findUpperBound(invested);
    if (length == leastUpperBound) {
      // All deposits got in, no excess. Return total deposits, 0
      userInvested = investor.userSums[length - 1];
      return (userInvested, excess);
    }
    uint256 prefixSum = prefixSums_[leastUpperBound];
    if (prefixSum == invested) {
      // Not all deposits got in, but there are no partial deposits
      userInvested = investor.userSums[leastUpperBound];
      excess = investor.userSums[length - 1] - userInvested;
    } else {
      // Let's say some of my deposits got in. The last deposit,
      // however, was $100 and only $30 got in. Need to split that
      // deposit so $30 got in, $70 is excess.
      userInvested = leastUpperBound > 0
        ? investor.userSums[leastUpperBound - 1]
        : 0;
      uint256 depositAmount = investor.userSums[leastUpperBound] - userInvested;
      if (prefixSum - depositAmount < invested) {
        userInvested += (depositAmount + invested - prefixSum);
        excess = investor.userSums[length - 1] - userInvested;
      } else {
        excess = investor.userSums[length - 1] - userInvested;
      }
    }
  }

  /*
   Used to avoid phantom overflow issues that can arise during this calculation:
   @notice Calculates floor(x*y÷denominator) with full precision.
   @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv.
   @dec Credit to prb-math for refactoring for solidity ^0.8 https://github.com/paulrberg/prb-math/blob/main/contracts/PRBMath.sol
  */
  function safeMulDiv(
    uint256 x,
    uint256 y,
    uint256 denominator
  ) internal pure returns (uint256 result) {
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
      unchecked {
        result = prod0 / denominator;
      }
      return result;
    }
    // Make sure the result is less than 2^256. Also prevents denominator == 0.
    if (prod1 >= denominator) {
      revert("OLib__MulDivOverflow(prod1, denominator)");
    }
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
    unchecked {
      // Does not overflow because the denominator cannot be zero at this stage in the function.
      uint256 lpotdod = denominator & (~denominator + 1);
      assembly {
        // Divide denominator by lpotdod.
        denominator := div(denominator, lpotdod)
        // Divide [prod1 prod0] by lpotdod.
        prod0 := div(prod0, lpotdod)
        // Flip lpotdod such that it is 2^256 / lpotdod. If lpotdod is zero, then it becomes one.
        lpotdod := add(div(sub(0, lpotdod), lpotdod), 1)
      }
      // Shift in bits from prod1 into prod0.
      prod0 |= prod1 * lpotdod;
      // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
      // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
      // four bits. That is, denominator * inv = 1 mod 2^4.
      uint256 inverse = (3 * denominator) ^ 2;
      // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel’s lifting lemma, this also works
      // in modular arithmetic, doubling the correct bits in each step.
      inverse *= 2 - denominator * inverse; // inverse mod 2^8
      inverse *= 2 - denominator * inverse; // inverse mod 2^16
      inverse *= 2 - denominator * inverse; // inverse mod 2^32
      inverse *= 2 - denominator * inverse; // inverse mod 2^64
      inverse *= 2 - denominator * inverse; // inverse mod 2^128
      inverse *= 2 - denominator * inverse; // inverse mod 2^256
      // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
      // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
      // less than 2^256, this is the final result. We don’t need to compute the high bits of the result and prod1
      // is no longer required.
      result = prod0 * inverse;
      return result;
    }
  }
}

/**
 * @title Subset of SafeERC20 from openZeppelin
 *
 * @dev Some non-standard ERC20 contracts (e.g. Tether) break
 * `approve` by forcing it to behave like `safeApprove`. This means
 * `safeIncreaseAllowance` will fail when it tries to adjust the
 * allowance. The code below simply adds an extra call to
 * `approve(spender, 0)`.
 */
library OndoSaferERC20 {
  using SafeERC20 for IERC20;

  function ondoSafeIncreaseAllowance(
    IERC20 token,
    address spender,
    uint256 value
  ) internal {
    uint256 newAllowance = token.allowance(address(this), spender) + value;
    token.safeApprove(spender, 0);
    token.safeApprove(spender, newAllowance);
  }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.3;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "contracts/interfaces/IStrategy.sol";
import "contracts/Registry.sol";
import "contracts/libraries/OndoLibrary.sol";
import "contracts/OndoRegistryClient.sol";
import "contracts/interfaces/IPairVault.sol";

/**
 * @title  Basic LP strategy
 * @notice All LP strategies should inherit from this
 */
abstract contract BasePairLPStrategy is OndoRegistryClient, IStrategy {
  using SafeERC20 for IERC20;

  modifier onlyOrigin(uint256 _vaultId) {
    require(
      msg.sender == address(vaults[_vaultId].origin),
      "Unauthorized: Only Vault contract"
    );
    _;
  }

  event Invest(uint256 indexed vault, uint256 lpTokens);
  event Redeem(uint256 indexed vault);
  event Harvest(address indexed pool, uint256 lpTokens);

  mapping(uint256 => Vault) public override vaults;

  constructor(address _registry) OndoRegistryClient(_registry) {}

  /**
   * @notice Deposit more LP tokens while Vault is invested
   */
  function addLp(uint256 _vaultId, uint256 _amount)
    external
    virtual
    override
    whenNotPaused
    onlyOrigin(_vaultId)
  {
    Vault storage vault_ = vaults[_vaultId];
    vault_.shares += _amount;
  }

  /**
   * @notice Remove LP tokens while Vault is invested
   */
  function removeLp(
    uint256 _vaultId,
    uint256 _amount,
    address to
  ) external virtual override whenNotPaused onlyOrigin(_vaultId) {
    Vault storage vault_ = vaults[_vaultId];
    vault_.shares -= _amount;
    IERC20(vault_.pool).safeTransfer(to, _amount);
  }

  /**
   * @notice Return the DEX pool and the amount of LP tokens
   */
  function getVaultInfo(uint256 _vaultId)
    external
    view
    override
    returns (IERC20, uint256)
  {
    Vault storage c = vaults[_vaultId];
    return (c.pool, c.shares);
  }

  /**
   * @notice Send excess tokens to investor
   */
  function withdrawExcess(
    uint256 _vaultId,
    OLib.Tranche tranche,
    address to,
    uint256 amount
  ) external override onlyOrigin(_vaultId) {
    Vault storage _vault = vaults[_vaultId];
    if (tranche == OLib.Tranche.Senior) {
      uint256 excess = _vault.seniorExcess;
      require(amount <= excess, "Withdrawing too much");
      _vault.seniorExcess -= amount;
      _vault.senior.safeTransfer(to, amount);
    } else {
      uint256 excess = _vault.juniorExcess;
      require(amount <= excess, "Withdrawing too much");
      _vault.juniorExcess -= amount;
      _vault.junior.safeTransfer(to, amount);
    }
  }
}

/**SPDX-License-Identifier: AGPL-3.0

          ▄▄█████████▄                                                                  
       ╓██▀└ ,╓▄▄▄, '▀██▄                                                               
      ██▀ ▄██▀▀╙╙▀▀██▄ └██µ           ,,       ,,      ,     ,,,            ,,,         
     ██ ,██¬ ▄████▄  ▀█▄ ╙█▄      ▄███▀▀███▄   ███▄    ██  ███▀▀▀███▄    ▄███▀▀███,     
    ██  ██ ╒█▀'   ╙█▌ ╙█▌ ██     ▐██      ███  █████,  ██  ██▌    └██▌  ██▌     └██▌    
    ██ ▐█▌ ██      ╟█  █▌ ╟█     ██▌      ▐██  ██ └███ ██  ██▌     ╟██ j██       ╟██    
    ╟█  ██ ╙██    ▄█▀ ▐█▌ ██     ╙██      ██▌  ██   ╙████  ██▌    ▄██▀  ██▌     ,██▀    
     ██ "██, ╙▀▀███████████⌐      ╙████████▀   ██     ╙██  ███████▀▀     ╙███████▀`     
      ██▄ ╙▀██▄▄▄▄▄,,,                ¬─                                    '─¬         
       ╙▀██▄ '╙╙╙▀▀▀▀▀▀▀▀                                                               
          ╙▀▀██████R⌐                                                                   

*/
pragma solidity >=0.8.3;

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/lib/contracts/libraries/Babylonian.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "contracts/strategies/BasePairLPStrategy.sol";
import "contracts/Multicall.sol";
import "contracts/libraries/OndoLibrary.sol";
import "contracts/vendor/uniswap/UniswapV2Library.sol";
import "contracts/vendor/quickswap/IStakingDualRewards.sol";

/**
 * @title Access QuickSwap for dual rewards
 * @notice Add and remove liquidity to QuickSwap
 * @dev Strategy in brief: original assets -> LP -> stake and get rewards, convert them to LP and stake it too -> LP -> original assets.
 */
contract QuickSwapStrategyV2 is BasePairLPStrategy, Multicall {
  using SafeERC20 for IERC20;
  using OndoSaferERC20 for IERC20;

  string public constant override name = "Ondo QuickSwap V2 Strategy";

  IUniswapV2Router02 public immutable quickswapRouter;
  address public immutable quickswapFactory;

  struct PoolData {
    uint256 pid;
    address[][2] pathsFromRewards;
    uint256 totalShares;
    uint256 totalLp;
    uint256 accRewardTokenA;
    uint256 accRewardTokenB;
    IStakingDualRewards extraRewardHandler;
    bool _isSet; // can't use pid because pid 0 is usdt/eth
  }

  mapping(address => PoolData) public pools;

  event NewPair(address indexed pool, uint256 pid);

  uint256 public constant sharesToLpRatio = 10e15;

  /**
   * @dev
   * @param _registry Ondo global registry
   * @param _router Router
   * @param _factory Factory
   */
  constructor(
    address _registry,
    address _router,
    address _factory
  ) BasePairLPStrategy(_registry) {
    require(_router != address(0), "Invalid address");
    require(_factory != address(0), "Invalid address");
    quickswapRouter = IUniswapV2Router02(_router);
    quickswapFactory = _factory;
  }

  /**
   * @notice Conversion of LP tokens to shares
   * @param _vaultId Vault
   * @param _lpTokens Amount of LP tokens
   * @return Number of shares for LP tokens
   * @return Total shares for this Vault
   * @return Sushiswap pool
   */
  function sharesFromLp(uint256 _vaultId, uint256 _lpTokens)
    public
    view
    override
    returns (
      uint256,
      uint256,
      IERC20
    )
  {
    Vault storage vault_ = vaults[_vaultId];
    PoolData storage poolData = pools[address(vault_.pool)];
    return (
      (_lpTokens * poolData.totalShares) / poolData.totalLp,
      vault_.shares,
      vault_.pool
    );
  }

  /**
   * @notice Conversion of shares to LP tokens
   * @param _vaultId Vault
   * @param _shares Amount of shares
   * @return Number LP tokens
   * @return Total shares for this Vault
   */
  function lpFromShares(uint256 _vaultId, uint256 _shares)
    public
    view
    override
    returns (uint256, uint256)
  {
    Vault storage vault_ = vaults[_vaultId];
    PoolData storage poolData = pools[address(vault_.pool)];
    return ((_shares * poolData.totalLp) / poolData.totalShares, vault_.shares);
  }

  /**
   * @notice Add LP tokens while Vault is live
   * @dev Maintain the amount of lp deposited directly
   * @param _vaultId Vault
   * @param _lpTokens Amount of LP tokens
   */
  function addLp(uint256 _vaultId, uint256 _lpTokens)
    external
    virtual
    override
    nonReentrant
    whenNotPaused
    onlyOrigin(_vaultId)
  {
    _depositIntoStaking(_vaultId, _lpTokens);
  }

  /**
   * @notice Remove LP tokens while Vault is live
   * @dev
   * @param _vaultId Vault
   * @param _shares Number of shares
   * @param _to Send LP tokens here
   */
  function removeLp(
    uint256 _vaultId,
    uint256 _shares,
    address _to
  ) external override whenNotPaused nonReentrant onlyOrigin(_vaultId) {
    require(_to != address(0), "No zero address");
    Vault storage vault_ = vaults[_vaultId];
    PoolData storage poolData = pools[address(vault_.pool)];
    (uint256 userLp, ) = lpFromShares(_vaultId, _shares);
    poolData.extraRewardHandler.withdraw(userLp);
    vault_.shares -= _shares;
    poolData.totalShares -= _shares;
    poolData.totalLp -= userLp;
    IERC20(vault_.pool).safeTransfer(_to, userLp);
  }

  /**
   * @notice Add info about pool
   * @dev
   * @param _pool QuickSwap V2 pool (dual-rewards pools)
   * @param _pid Pool ID
   * @param _pathsFromRewards Paths
   * @param _extraRewardHandler StakingDualRewards contract
   */
  function addPool(
    address _pool,
    uint256 _pid,
    address[][2] memory _pathsFromRewards,
    address _extraRewardHandler
  ) external whenNotPaused isAuthorized(OLib.STRATEGIST_ROLE) {
    require(!pools[_pool]._isSet, "Pool ID already registered");
    require(_pool != address(0), "Cannot be zero address");

    address token0 = IUniswapV2Pair(_pool).token0();
    address token1 = IUniswapV2Pair(_pool).token1();
    address rewardToken;
    address endToken;
    for (uint8 i = 0; i < 2; i++) {
      rewardToken = _pathsFromRewards[i][0];
      endToken = _pathsFromRewards[i][_pathsFromRewards[i].length - 1];
      require(endToken == token0 || endToken == token1, "Invalid path");
    }
    pools[_pool].pathsFromRewards = _pathsFromRewards;

    pools[_pool].pid = _pid;
    pools[_pool]._isSet = true;
    pools[_pool].extraRewardHandler = IStakingDualRewards(_extraRewardHandler);

    emit NewPair(_pool, _pid);
  }

  function updateRewardPath(
    address _pool,
    uint8 _rewardTokenIndex,
    address[] calldata _pathFromReward
  )
    external
    whenNotPaused
    isAuthorized(OLib.STRATEGIST_ROLE)
    returns (bool success)
  {
    PoolData storage poolData = pools[_pool];
    require(poolData._isSet, "Pool ID not yet registered");
    address token0 = IUniswapV2Pair(_pool).token0();
    address token1 = IUniswapV2Pair(_pool).token1();
    address rewardToken = _pathFromReward[0];
    require(rewardToken != token0 || rewardToken != token1, "Invalid path");
    address endToken = _pathFromReward[_pathFromReward.length - 1];
    require(endToken == token0 || endToken == token1, "Invalid path");
    if (rewardToken == poolData.pathsFromRewards[_rewardTokenIndex][0]) {
      poolData.pathsFromRewards[_rewardTokenIndex] = _pathFromReward;
      success = true;
    } else {
      success = false;
    }
  }

  /**
   * @notice Reinvest rewards into LP tokens and stake them
   * @param _pool QuickSwap pool
   * @param _poolData Info about current state of pool investments
   */
  function _compound(IERC20 _pool, PoolData storage _poolData)
    internal
    returns (uint256 lpAmount)
  {
    // since some pools may include the dual reward token in the pair, resulting
    // in the strategy holding withdrawable balances of those tokens for expired vaults,
    // we initialize the contract's balance and then take the diff after harvesting
    IERC20 rewardTokenA = IERC20(_poolData.pathsFromRewards[0][0]);
    IERC20 rewardTokenB = IERC20(_poolData.pathsFromRewards[1][0]);
    uint256 rewardTokenAAmount = rewardTokenA.balanceOf(address(this));
    uint256 rewardTokenBAmount = rewardTokenB.balanceOf(address(this));

    _poolData.extraRewardHandler.getReward();

    rewardTokenAAmount =
      rewardTokenA.balanceOf(address(this)) +
      _poolData.accRewardTokenA -
      rewardTokenAAmount;
    rewardTokenBAmount =
      rewardTokenB.balanceOf(address(this)) +
      _poolData.accRewardTokenB -
      rewardTokenBAmount;

    if (rewardTokenAAmount > 10000 && rewardTokenBAmount > 10000) {
      _poolData.accRewardTokenA = 0;
      _poolData.accRewardTokenB = 0;

      IUniswapV2Pair pool = IUniswapV2Pair(address(_pool));
      uint256[] memory tokenAmountsArray = new uint256[](2);
      tokenAmountsArray[0] = rewardTokenAAmount;
      tokenAmountsArray[1] = rewardTokenBAmount;
      if (rewardTokenA == rewardTokenB) {
        tokenAmountsArray[0] = _swapExactIn(
          tokenAmountsArray[0],
          0,
          _poolData.pathsFromRewards[0]
        );
        tokenAmountsArray[1] = 0;
      } else {
        for (uint8 i = 0; i < 2; i++) {
          // the first element in the swap path is the reward token itself, so an array length of 1 indicates that the token
          // is also one of the LP assets and thus does not need to be swapped
          if (_poolData.pathsFromRewards[i].length > 1) {
            // if the reward token does need to be swapped into one of the LP assets, that harvestAmount is updated in place with
            // the amount of LP asset received, now representing a token amount that can be passed into _addLiquidity()
            tokenAmountsArray[i] = _swapExactIn(
              tokenAmountsArray[i],
              // internal swap calls do not set a minimum amount received, which is constrained only after compounding, on LP received
              0,
              _poolData.pathsFromRewards[i]
            );
          }
        }
      }

      address tokenA = _poolData.pathsFromRewards[0][
        _poolData.pathsFromRewards[0].length - 1
      ];
      // tokenB is the other asset in the LP
      address tokenB = IUniswapV2Pair(address(pool)).token0();
      if (tokenB == tokenA) tokenB = IUniswapV2Pair(address(pool)).token1();

      // there are two cases: either both rewards have now been converted to amounts of the same LP asset, or to
      // amounts of each LP asset
      if (
        tokenA ==
        _poolData.pathsFromRewards[1][_poolData.pathsFromRewards[1].length - 1]
      ) {
        // this is the case in which we are starting with two amounts of the same LP asset. we update the first harvestAmount in place
        // to contain the total amount of this asset
        tokenAmountsArray[0] = tokenAmountsArray[0] + tokenAmountsArray[1];
        // we use Zapper's Babylonian method to calculate how much of this total needs to be swapped into the other LP asset in order to
        // addLiquidity without remainder. this is removed from the first harvestAmount, which now represents the final amount of tokenA
        // to be added to the LP, and written into the second harvestAmount, now the amount of tokenA that will be converted to tokenB
        (uint256 reserveA, ) = UniswapV2Library.getReserves(
          quickswapFactory,
          tokenA,
          tokenB
        );
        tokenAmountsArray[1] = _calculateSwapInAmount(
          reserveA,
          tokenAmountsArray[0]
        );
        tokenAmountsArray[0] -= tokenAmountsArray[1];
        // we update the second harvestAmount (amount of tokenA to be swapped) with the amount of tokenB received. tokenAmountsArray now
        // represents balanced LP assets that can be passed into addLiquidity without remainder, resulting in lpAmount = the final
        // compounding result
        tokenAmountsArray[1] = _swapExactIn(
          tokenAmountsArray[1],
          0,
          _getPath(tokenA, tokenB)
        );
        (, , lpAmount) = _addLiquidity(
          tokenA,
          tokenB,
          tokenAmountsArray[0],
          tokenAmountsArray[1],
          0,
          0
        );
      } else {
        // in this branch, we have amounts of both LP assets and may need to swap in order to balance them. the zap-in method alone doesn't
        // suffice for this, so to avoid some very tricky and opaque math, we simply:
        // (1) addLiquidity, leaving remainder in at most one LP asset
        // (2) check for a remainder
        // (3) if it exists, zap this amount into balanced amounts of each LP asset
        // (4) addLiquidity again, leaving no remainder
        uint256 amountInA;
        uint256 amountInB;
        (amountInA, amountInB, lpAmount) = _addLiquidity(
          tokenA,
          tokenB,
          tokenAmountsArray[0],
          tokenAmountsArray[1],
          0,
          0
        );
        // tokenAmountsArray are updated in place to represent the remaining LP assets after adding liquidity. at least one element is 0,
        // and except in the extremely rare case that the amounts were already perfectly balanced, the other element is > 0. the semantics
        // of which element holds a balance of which token remains fixed:
        // [0] is tokenA, which is or was swapped from SUSHI, and [1] is tokenB,
        // which is or was swapped from the dual reward token, and they comprise both of the LP assets.
        tokenAmountsArray[0] -= amountInA;
        tokenAmountsArray[1] -= amountInB;
        require(
          tokenAmountsArray[0] == 0 || tokenAmountsArray[1] == 0,
          "Insufficient liquidity added on one side of first call"
        );
        (uint256 reserveA, uint256 reserveB) = UniswapV2Library.getReserves(
          quickswapFactory,
          tokenA,
          tokenB
        );
        // in the first branch, the entire original amount of tokenA was added to the LP and is now 0, and there is a nonzero remainder
        // of tokenB. we initialize the swap amount outside the conditional so that at the end we know whether we performed any swaps
        // and therefore need to addLiquidity a second time
        uint256 amountToSwap = 0;
        if (tokenAmountsArray[0] < tokenAmountsArray[1]) {
          // we perform the zap in, swapping tokenB for a balanced amount of tokenA. once again, the harvestAmount swapped from is
          // decremented in place by the swap amount, now available outside the conditional scope, and the amount received from the
          // swap is stored in the other harvestAmount
          amountToSwap = _calculateSwapInAmount(reserveB, tokenAmountsArray[1]);
          tokenAmountsArray[1] -= amountToSwap;
          tokenAmountsArray[0] += _swapExactIn(
            amountToSwap,
            0,
            _getPath(tokenB, tokenA)
          );
        } else if (tokenAmountsArray[0] > 0) {
          // in this branch, there is a nonzero remainder of tokenA, and none of tokenB, recalling that at most one of these
          // balances can be nonzero. the same zap-in procedure is applied, swapping tokenA for tokenB and updating amountToSwap and
          // both tokenAmountsArray. we structure this as an else-if with no further branch because if both amounts are 0,
          // the original amounts were perfectly balanced so we don't need to swap and addLiquidity again.
          amountToSwap = _calculateSwapInAmount(reserveA, tokenAmountsArray[0]);
          tokenAmountsArray[0] -= amountToSwap;
          tokenAmountsArray[1] += _swapExactIn(
            amountToSwap,
            0,
            _getPath(tokenA, tokenB)
          );
        }
        if (amountToSwap > 0) {
          // if amountToSwap was updated in one of the branches above, we have balanced nonzero amounts of both LP assets
          // and need to addLiquidity again
          (, , uint256 moreLp) = _addLiquidity(
            tokenA,
            tokenB,
            tokenAmountsArray[0],
            tokenAmountsArray[1],
            0,
            0
          );
          // recall that lpAmount was previously set by the first addLiquidity. if we've just received more, we add it to
          // get the final compounding result, which we include as a named return so that harvest() can constrain it with a
          // minimum that protects against flash price anomalies, whether adversarial or coincidental
          lpAmount += moreLp;
        }
      }

      _poolData.totalLp += lpAmount;
      _pool.ondoSafeIncreaseAllowance(
        address(_poolData.extraRewardHandler),
        lpAmount
      );
      _poolData.extraRewardHandler.stake(lpAmount);
    } else {
      // Save rewards to be processed next time
      _poolData.accRewardTokenA = rewardTokenAAmount;
      _poolData.accRewardTokenB = rewardTokenBAmount;
    }
  }

  /**
   * @param _vaultId Vault ID
   * @param _lpTokens Amount of LP tokens to be deposited into staking
   */
  function _depositIntoStaking(uint256 _vaultId, uint256 _lpTokens) internal {
    Vault storage vault = vaults[_vaultId];
    IERC20 pool = vault.pool;
    PoolData storage poolData = pools[address(pool)];
    _compound(pool, poolData);
    if (poolData.totalLp == 0 || poolData.totalShares == 0) {
      poolData.totalShares = _lpTokens * sharesToLpRatio;
      poolData.totalLp = _lpTokens;
      vault.shares = _lpTokens * sharesToLpRatio;

      // Need to stake the balance.
      pool.ondoSafeIncreaseAllowance(
        address(poolData.extraRewardHandler),
        _lpTokens
      );
      poolData.extraRewardHandler.stake(_lpTokens);
    } else {
      uint256 shares = (_lpTokens * poolData.totalShares) / poolData.totalLp;
      poolData.totalShares += shares;
      vault.shares += shares;
      poolData.totalLp += _lpTokens;

      // Need to stake the lp Balance
      pool.ondoSafeIncreaseAllowance(
        address(poolData.extraRewardHandler),
        _lpTokens
      );

      poolData.extraRewardHandler.stake(_lpTokens);
    }
  }

  /**
   * @param _vaultId Id of the vault to be withdrawn
   */
  function _withdrawFromStaking(uint256 _vaultId)
    internal
    returns (uint256 lpTokens)
  {
    Vault storage vault = vaults[_vaultId];
    IERC20 pool = vault.pool;
    PoolData storage poolData = pools[address(pool)];
    lpTokens = vault.shares == poolData.totalShares
      ? poolData.totalLp
      : (poolData.totalLp * vault.shares) / poolData.totalShares;
    poolData.totalLp -= lpTokens;
    poolData.totalShares -= vault.shares;
    vault.shares = 0;
    poolData.extraRewardHandler.withdraw(lpTokens);
    return lpTokens;
  }

  /**
   * @notice Periodically reinvest rewards into LP tokens
   * @param _pool Quickswap pool to reinvest
   */
  function harvest(address _pool, uint256 _minLp)
    external
    isAuthorized(OLib.STRATEGIST_ROLE)
    whenNotPaused
    returns (uint256 newLPs)
  {
    PoolData storage poolData = pools[_pool];
    newLPs = _compound(IERC20(_pool), poolData);
    require(newLPs >= _minLp, "Exceeds maximum slippage");
    emit Harvest(_pool, newLPs);
    return newLPs;
  }

  /**
   * @notice AllPairsVault registers Vault here
   * @param _vaultId Reference to Vault
   * @param _senior Asset used for senior tranche
   * @param _junior Asset used for junior tranche
   */
  function addVault(
    uint256 _vaultId,
    IERC20 _senior,
    IERC20 _junior
  ) external override nonReentrant isAuthorized(OLib.VAULT_ROLE) {
    require(
      address(vaults[_vaultId].origin) == address(0),
      "Vault id already registered"
    );
    address pool = IUniswapV2Factory(quickswapFactory).getPair(
      address(_senior),
      address(_junior)
    );
    require(pool != address(0), "Pool doesn't exist");
    Vault storage vault_ = vaults[_vaultId];
    vault_.origin = IPairVault(msg.sender);
    vault_.pool = IERC20(pool);
    vault_.senior = IERC20(_senior);
    vault_.junior = IERC20(_junior);
  }

  /**
   * @dev Given the total available amounts of senior and junior asset
   *      tokens, invest as much as possible and record any excess uninvested
   *      assets.
   * @param _vaultId Reference to specific Vault
   * @param _totalSenior Total amount available to invest into senior assets
   * @param _totalJunior Total amount available to invest into junior assets
   * @param _extraSenior Extra funds due to cap on tranche, must be returned
   * @param _extraJunior Extra funds due to cap on tranche, must be returned
   * @param _seniorMinIn Min amount expected for asset
   * @param _seniorMinIn Min amount expected for asset
   * @return seniorInvested Actual amout invested into LP tokens
   * @return juniorInvested Actual amout invested into LP tokens
   */
  function invest(
    uint256 _vaultId,
    uint256 _totalSenior,
    uint256 _totalJunior,
    uint256 _extraSenior,
    uint256 _extraJunior,
    uint256 _seniorMinIn,
    uint256 _juniorMinIn
  )
    external
    override
    nonReentrant
    whenNotPaused
    onlyOrigin(_vaultId)
    returns (uint256 seniorInvested, uint256 juniorInvested)
  {
    uint256 lpTokens;
    Vault storage vault_ = vaults[_vaultId];
    (seniorInvested, juniorInvested, lpTokens) = _addLiquidity(
      address(vault_.senior),
      address(vault_.junior),
      _totalSenior,
      _totalJunior,
      _seniorMinIn,
      _juniorMinIn
    );
    vault_.seniorExcess = _totalSenior - seniorInvested + _extraSenior;
    vault_.juniorExcess = _totalJunior - juniorInvested + _extraJunior;
    _depositIntoStaking(_vaultId, lpTokens);
    emit Invest(_vaultId, lpTokens);
  }

  /**
   * @dev Convert all LP tokens back into the pair of underlying
   *      assets. Also convert any rewards equally into both tranches.
   *      The senior tranche is expecting to get paid some hurdle
   *      rate above where they started. Here are the possible outcomes:
   * - If the senior tranche doesn't have enough, then sell some or
   *         all junior tokens to get the senior to the expected
   *         returns. In the worst case, the senior tranche could suffer
   *         a loss and the junior tranche will be wiped out.
   * - If the senior tranche has more than enough, reduce this tranche
   *    to the expected payoff. The excess senior tokens should be
   *    converted to junior tokens.
   * @param _vaultId Reference to a specific Vault
   * @param _seniorExpected Amount the senior tranche is expecting
   * @param _seniorMinReceived Compute the expected seniorReceived factoring in any slippage
   * @param _juniorMinReceived Same, for juniorReceived
   * @return seniorReceived Final amount for senior tranche
   * @return juniorReceived Final amount for junior tranche
   */
  function redeem(
    uint256 _vaultId,
    uint256 _seniorExpected,
    uint256 _seniorMinReceived,
    uint256 _juniorMinReceived
  )
    external
    override
    nonReentrant
    whenNotPaused
    onlyOrigin(_vaultId)
    returns (uint256 seniorReceived, uint256 juniorReceived)
  {
    Vault storage vault_ = vaults[_vaultId];
    {
      uint256 lpTokens = _withdrawFromStaking(_vaultId);
      vault_.pool.ondoSafeIncreaseAllowance(address(quickswapRouter), lpTokens);
      (seniorReceived, juniorReceived) = quickswapRouter.removeLiquidity(
        address(vault_.senior),
        address(vault_.junior),
        lpTokens,
        0,
        0,
        address(this),
        block.timestamp
      );
    }
    if (seniorReceived < _seniorExpected) {
      (seniorReceived, juniorReceived) = _swapForSr(
        address(vault_.senior),
        address(vault_.junior),
        _seniorExpected,
        seniorReceived,
        juniorReceived
      );
    } else {
      if (seniorReceived > _seniorExpected) {
        juniorReceived += _swapExactIn(
          seniorReceived - _seniorExpected,
          0,
          _getPath(address(vault_.senior), address(vault_.junior))
        );
      }
      seniorReceived = _seniorExpected;
    }
    require(
      _seniorMinReceived <= seniorReceived &&
        _juniorMinReceived <= juniorReceived,
      "Exceeds maximum slippage"
    );
    vault_.senior.ondoSafeIncreaseAllowance(
      msg.sender,
      seniorReceived + vault_.seniorExcess
    );
    vault_.junior.ondoSafeIncreaseAllowance(
      msg.sender,
      juniorReceived + vault_.juniorExcess
    );
    emit Redeem(_vaultId);
    return (seniorReceived, juniorReceived);
  }

  function _getPath(address _token0, address _token1)
    internal
    pure
    returns (address[] memory path)
  {
    path = new address[](2);
    path[0] = _token0;
    path[1] = _token1;
  }

  function _swapForSr(
    address _senior,
    address _junior,
    uint256 _seniorExpected,
    uint256 seniorReceived,
    uint256 juniorReceived
  ) internal returns (uint256, uint256) {
    uint256 seniorNeeded = _seniorExpected - seniorReceived;
    address[] memory jr2Sr = _getPath(_junior, _senior);
    if (seniorNeeded > _getAmountsOut(juniorReceived, jr2Sr)[1]) {
      seniorReceived += _swapExactIn(juniorReceived, 0, jr2Sr);
      return (seniorReceived, 0);
    } else {
      juniorReceived -= _swapExactOut(seniorNeeded, juniorReceived, jr2Sr);
      return (_seniorExpected, juniorReceived);
    }
  }

  /**
   * @dev Simple wrapper around uniswap
   * @param amtIn Amount in
   * @param minOut Minimumum out
   * @param path Router path
   */
  function _swapExactIn(
    uint256 amtIn,
    uint256 minOut,
    address[] memory path
  ) internal returns (uint256) {
    IERC20(path[0]).ondoSafeIncreaseAllowance(address(quickswapRouter), amtIn);
    return
      quickswapRouter.swapExactTokensForTokens(
        amtIn,
        minOut,
        path,
        address(this),
        block.timestamp
      )[path.length - 1];
  }

  function _swapExactOut(
    uint256 amtOut,
    uint256 maxIn,
    address[] memory path
  ) internal returns (uint256) {
    IERC20(path[0]).ondoSafeIncreaseAllowance(address(quickswapRouter), maxIn);
    return
      quickswapRouter.swapTokensForExactTokens(
        amtOut,
        maxIn,
        path,
        address(this),
        block.timestamp
      )[0];
  }

  function _getAmountsOut(uint256 juniorReceived, address[] memory jr2Sr)
    internal
    view
    virtual
    returns (uint256[] memory)
  {
    return
      UniswapV2Library.getAmountsOut(quickswapFactory, juniorReceived, jr2Sr);
  }

  function _addLiquidity(
    address token0,
    address token1,
    uint256 amt0,
    uint256 amt1,
    uint256 minOut0,
    uint256 minOut1
  )
    internal
    returns (
      uint256 out0,
      uint256 out1,
      uint256 lp
    )
  {
    IERC20(token0).ondoSafeIncreaseAllowance(address(quickswapRouter), amt0);
    IERC20(token1).ondoSafeIncreaseAllowance(address(quickswapRouter), amt1);
    (out0, out1, lp) = quickswapRouter.addLiquidity(
      token0,
      token1,
      amt0,
      amt1,
      minOut0,
      minOut1,
      address(this),
      block.timestamp
    );
  }

  /**
   * @notice Exactly how much of userIn to swap to get perfectly balanced ratio for LP tokens
   * @dev This code is cloned from L1242-1253 of UniswapV2_ZapIn_General_V4 at
   * https://etherscan.io/address/0x5ACedBA6C402e2682D312a7b4982eda0Ccf2d2E3#code#L1242
   * @param reserveIn Amount of reserves for asset 0
   * @param userIn Availabe amount of asset 0 to swap
   * @return Amount of userIn to swap for asset 1
   */
  function _calculateSwapInAmount(uint256 reserveIn, uint256 userIn)
    internal
    pure
    returns (uint256)
  {
    return
      (Babylonian.sqrt(reserveIn * (userIn * 3988000 + reserveIn * 3988009)) -
        reserveIn *
        1997) / 1994;
  }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.3;

interface IStakingDualRewards {
  function balanceOf(address account) external view returns (uint256);

  function stake(uint256 amount) external;

  function withdraw(uint256 amount) external;

  function getReward() external;

  function exit() external;

  function periodFinish() external view returns (uint256);

  function earnedA(address account) external view returns (uint256);

  function earnedB(address account) external view returns (uint256);

  function rewardsTokenA() external view returns (address);

  function rewardsTokenB() external view returns (address);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.3;

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

library UniswapV2Library {
  using SafeMath for uint256;

  // returns sorted token addresses, used to handle return values from pairs sorted in this order
  function sortTokens(address tokenA, address tokenB)
    internal
    pure
    returns (address token0, address token1)
  {
    require(tokenA != tokenB, "UniswapV2Library: IDENTICAL_ADDRESSES");
    (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
    require(token0 != address(0), "UniswapV2Library: ZERO_ADDRESS");
  }

  // fetches and sorts the reserves for a pair
  function getReserves(
    address factory,
    address tokenA,
    address tokenB
  ) internal view returns (uint256 reserveA, uint256 reserveB) {
    (address token0, ) = sortTokens(tokenA, tokenB);
    (uint256 reserve0, uint256 reserve1, ) = IUniswapV2Pair(
      IUniswapV2Factory(factory).getPair(tokenA, tokenB)
    ).getReserves();
    (reserveA, reserveB) = tokenA == token0
      ? (reserve0, reserve1)
      : (reserve1, reserve0);
  }

  // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
  function quote(
    uint256 amountA,
    uint256 reserveA,
    uint256 reserveB
  ) internal pure returns (uint256 amountB) {
    require(amountA > 0, "UniswapV2Library: INSUFFICIENT_AMOUNT");
    require(
      reserveA > 0 && reserveB > 0,
      "UniswapV2Library: INSUFFICIENT_LIQUIDITY"
    );
    amountB = amountA.mul(reserveB) / reserveA;
  }

  // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
  function getAmountOut(
    uint256 amountIn,
    uint256 reserveIn,
    uint256 reserveOut
  ) internal pure returns (uint256 amountOut) {
    require(amountIn > 0, "UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT");
    require(
      reserveIn > 0 && reserveOut > 0,
      "UniswapV2Library: INSUFFICIENT_LIQUIDITY"
    );
    uint256 amountInWithFee = amountIn.mul(997);
    uint256 numerator = amountInWithFee.mul(reserveOut);
    uint256 denominator = reserveIn.mul(1000).add(amountInWithFee);
    amountOut = numerator / denominator;
  }

  // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
  function getAmountIn(
    uint256 amountOut,
    uint256 reserveIn,
    uint256 reserveOut
  ) internal pure returns (uint256 amountIn) {
    require(amountOut > 0, "UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT");
    require(
      reserveIn > 0 && reserveOut > 0,
      "UniswapV2Library: INSUFFICIENT_LIQUIDITY"
    );
    uint256 numerator = reserveIn.mul(amountOut).mul(1000);
    uint256 denominator = reserveOut.sub(amountOut).mul(997);
    amountIn = (numerator / denominator).add(1);
  }

  // performs chained getAmountOut calculations on any number of pairs
  function getAmountsOut(
    address factory,
    uint256 amountIn,
    address[] memory path
  ) internal view returns (uint256[] memory amounts) {
    require(path.length >= 2, "UniswapV2Library: INVALID_PATH");
    amounts = new uint256[](path.length);
    amounts[0] = amountIn;
    for (uint256 i; i < path.length - 1; i++) {
      (uint256 reserveIn, uint256 reserveOut) = getReserves(
        factory,
        path[i],
        path[i + 1]
      );
      amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
    }
  }

  // performs chained getAmountIn calculations on any number of pairs
  function getAmountsIn(
    address factory,
    uint256 amountOut,
    address[] memory path
  ) internal view returns (uint256[] memory amounts) {
    require(path.length >= 2, "UniswapV2Library: INVALID_PATH");
    amounts = new uint256[](path.length);
    amounts[amounts.length - 1] = amountOut;
    for (uint256 i = path.length - 1; i > 0; i--) {
      (uint256 reserveIn, uint256 reserveOut) = getReserves(
        factory,
        path[i - 1],
        path[i]
      );
      amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
    }
  }
}