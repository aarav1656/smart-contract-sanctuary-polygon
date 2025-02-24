//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

import "./PermissionManagerStorage.sol";

/**
 * @title PermissionManager
 * @author Swarm
 * @dev Provide tier based permissions assignments and revoking functions.
 */
contract PermissionManagerV2 is Initializable, AccessControlUpgradeable, PermissionManagerStorage {
    struct UserProxy {
        address user;
        address proxy;
    }

    /// @notice mapping of Security Tokens, entered by token Address
    mapping(address => uint256) public securityTokens;
    uint256 public lastSecurityTokenId;

    uint256 public constant POOL_CREATOR = 5;
    uint256 public constant SOF_TOKEN_ITEM_ID = 10;

    /**
     * @dev Emitted when `permissionItems` address is set.
     */
    event PermissionItemsSet(IPermissionItems indexed newPermissions);

    /**
     * @dev Emitted when new security token id is generated
     */
    event NewSecurityTokenIdGenerated(uint256 indexed newId, address indexed tokenContract);

    /**
     * @dev Emitted when lastSecurityTokenId was edited
     */
    event LastSecurityTokenIdEdited(uint256 indexed oldId, uint256 indexed newId, address indexed caller);

    /**
     * @dev Throws if passed zero address.
     */
    modifier zeroAddressCheck(address account) {
        require(account != address(0), "PMV2: Passed zero address.");
        _;
    }

    /**
     * @dev Throws if called by some address without DEFAULT_ADMIN_ROLE.
     */
    modifier onlyDefaultAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "PMV2: Account must have DEFAULT_ADMIN_ROLE.");
        _;
    }

    /**
     * @dev Throws if called by some address without PERMISSIONS_ADMIN_ROLE.
     */
    modifier onlyPermissionsAdmin() {
        require(hasRole(PERMISSIONS_ADMIN_ROLE, _msgSender()), "PMV2: Account must have PERMISSIONS_ADMIN_ROLE.");
        _;
    }

    /**
     * @dev Grants PERMISSIONS_ADMIN_ROLE to `_permissionsAdmin`.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     * - `_permissionsAdmin` should not be the zero address.
     */
    function setPermissionsAdmin(
        address _permissionsAdmin
    ) external zeroAddressCheck(_permissionsAdmin) onlyDefaultAdmin {
        grantRole(PERMISSIONS_ADMIN_ROLE, _permissionsAdmin);
    }

    /**
     * @dev Sets `_permissionItems` as the new permissionItems module.
     *
     * Requirements:
     *
     * - the caller must be the owner.
     * - `_permissionItems` should not be the zero address.
     *
     * @param _permissionItems The address of the new Pemissions module.
     */
    function setPermissionItems(
        IPermissionItems _permissionItems
    ) external zeroAddressCheck(address(_permissionItems)) onlyDefaultAdmin returns (bool) {
        emit PermissionItemsSet(_permissionItems);
        permissionItems = _permissionItems;
        return true;
    }

    /**
     * @dev Assigns Tier1 permission to the `_account`.
     *
     * Requirements:
     *
     * - the caller must be the owner.
     * - `_account` address should not have Tier1 already assigned.
     * - `_account` address should not be zero address.
     *
     * @param _account The address to assign Tier1.
     */
    function assignTier1(address _account) public zeroAddressCheck(_account) onlyPermissionsAdmin {
        require(!hasTier1(_account), "PMV2: Address already has Tier 1 assigned");
        permissionItems.mint(_account, TIER_1_ID, 1, "");
    }

    /**
     * @dev Assigns Tier1 permission to the list `_accounts`.
     *
     * Requirements:
     *
     * - the caller must be the owner.
     * - each address in `_accounts` should not have Tier1 already assigned.
     * - `_accounts` addresses should not be zero addresses.
     *
     * @param _accounts The addresses to assign Tier1.
     */
    function assignTiers1(address[] calldata _accounts) external {
        for (uint256 i = 0; i < _accounts.length; i++) {
            assignTier1(_accounts[i]);
        }
    }

    /**
     * @dev Removes Tier1 permission from the `_account`.
     *
     * Requirements:
     *
     * - the caller must be the owner.
     * - `_account` should have Tier1 assigned.
     * - `_account` should not be a zero address.
     *
     * @param _account The address to revoke Tier1.
     */
    function revokeTier1(address _account) public onlyPermissionsAdmin {
        require(hasTier1(_account), "PMV2: Address doesn't has Tier 1 assigned");
        permissionItems.burn(_account, TIER_1_ID, 1);
    }

    /**
     * @dev Removes Tier1 permission from the list `_accounts`.
     *
     * Requirements:
     *
     * - the caller must be the owner.
     * - each address in `_accounts` should have Tier1 assigned.
     * - each address in `_accounts` should not be a zero address.
     *
     * @param _accounts The addresses to revoke Tier1.
     */
    function revokeTiers1(address[] calldata _accounts) external {
        for (uint256 i = 0; i < _accounts.length; i++) {
            revokeTier1(_accounts[i]);
        }
    }

    /**
     * @dev Assigns Tier2 permission to users and proxies.
     *
     * Requirements:
     *
     * - the caller must be the owner.
     * - Address in `_userProxy.user` should not have Tier2 already assigned.
     * - Address in `_userProxy.proxy` should not have Tier2 already assigned.
     * - Address in `_userProxy.user` should not be zero address.
     *
     * @param _userProxy The address of user and proxy.
     */
    function assignTier2(UserProxy calldata _userProxy) public zeroAddressCheck(_userProxy.user) onlyPermissionsAdmin {
        require(!hasTier2(_userProxy.user), "PMV2: Address already has Tier 2 assigned");
        require(!hasTier2(_userProxy.proxy), "PMV2: Proxy already has Tier 2 assigned");

        permissionItems.mint(_userProxy.user, TIER_2_ID, 1, "");
        permissionItems.mint(_userProxy.proxy, TIER_2_ID, 1, "");
    }

    /**
     * @dev Assigns Tier2 permission to a list of users and proxies.
     *
     * Requirements:
     *
     * - the caller must be the owner.
     * - All user addresses in `_usersProxies` should not have Tier2 already assigned.
     * - All proxy addresses in `_usersProxies` should not have Tier2 already assigned.
     * - All `_userProxy.user` addresses should not be zero address.
     *
     * @param _usersProxies The addresses of the users and proxies.
     *                      An array of the struct UserProxy where user and proxy are bout required.
     */
    function assignTiers2(UserProxy[] calldata _usersProxies) external {
        for (uint256 i = 0; i < _usersProxies.length; i++) {
            assignTier2(_usersProxies[i]);
        }
    }

    /**
     * @dev Removes Tier2 permission from user and proxy.
     *
     * Requirements:
     *
     * - the caller must be the owner.
     * - `_userProxy.user` should have Tier2 assigned.
     * - `_userProxy.proxy` should have Tier2 assigned.
     *
     * @param _userProxy The address of user and proxy.
     */
    function revokeTier2(UserProxy calldata _userProxy) public onlyPermissionsAdmin {
        require(hasTier2(_userProxy.user), "PMV2: Address doesn't has Tier 2 assigned");
        require(hasTier2(_userProxy.proxy), "PMV2: Proxy doesn't has Tier 2 assigned");

        permissionItems.burn(_userProxy.user, TIER_2_ID, 1);
        permissionItems.burn(_userProxy.proxy, TIER_2_ID, 1);
    }

    /**
     * @dev Removes Tier2 permission from a list of users and proxies.
     *
     * Requirements:
     *
     * - the caller must be the owner.
     * - All user addresses in `_usersProxies` should have Tier2 assigned.
     * - All proxy addresses in should have Tier2 assigned.
     *
     * @param _usersProxies The addresses of the users and proxies.
     *                      An array of the struct UserProxy where user and proxy are bout required.
     */
    function revokeTiers2(UserProxy[] calldata _usersProxies) external {
        for (uint256 i = 0; i < _usersProxies.length; i++) {
            revokeTier2(_usersProxies[i]);
        }
    }

    /**
     * @dev Assigns SoF token permission to the `_account`.
     *
     * Requirements:
     *
     * - the caller must be the owner.
     * - `_account` address should not have SoF token already assigned.
     * - `_account` address should not be zero address.
     *
     * @param _account The address to assign SoF token.
     */
    function assignSoFToken(address _account) public zeroAddressCheck(_account) onlyPermissionsAdmin {
        require(!hasSoFToken(_account), "PMV2: Address already has SoF token assigned");
        permissionItems.mint(_account, SOF_TOKEN_ITEM_ID, 1, "");
    }

    /**
     * @dev Assigns SoF tokens permission to the list `_accounts`.
     *
     * Requirements:
     *
     * - the caller must be the owner.
     * - each address in `_accounts` should not have SoF token already assigned.
     * - `_accounts` addresses should not be zero addresses.
     *
     * @param _accounts The addresses to assign SoF tokens.
     */
    function assignSoFTokens(address[] calldata _accounts) external {
        for (uint256 i = 0; i < _accounts.length; i++) {
            assignSoFToken(_accounts[i]);
        }
    }

    /**
     * @dev Removes SoF token permission from the `_account`.
     *
     * Requirements:
     *
     * - the caller must be the owner.
     * - `_account` should have SoF token assigned.
     * - `_account` should not be a zero address.
     *
     * @param _account The address to revoke SoF token.
     */
    function revokeSoFToken(address _account) public onlyPermissionsAdmin {
        require(hasSoFToken(_account), "PMV2: Address has no SoF token assigned");
        permissionItems.burn(_account, SOF_TOKEN_ITEM_ID, 1);
    }

    /**
     * @dev Removes SoF tokens permission from the list `_accounts`.
     *
     * Requirements:
     *
     * - the caller must be the owner.
     * - each address in `_accounts` should have SoF token assigned.
     * - each address in `_accounts` should not be a zero address.
     *
     * @param _accounts The addresses to revoke SoF tokens.
     */
    function revokeSoFTokens(address[] calldata _accounts) external {
        for (uint256 i = 0; i < _accounts.length; i++) {
            revokeSoFToken(_accounts[i]);
        }
    }

    /**
     * @dev Suspends permissions effects to user and proxy.
     *
     * Requirements:
     *
     * - the caller must be the owner.
     * - Address in `_userProxy.user` should not be already suspended.
     * - Address in `_userProxy.proxy` should not be already suspended.
     * - Address in `_userProxy.user` should not be zero address.
     *
     * @param _userProxy The address of user and proxy.
     */
    function suspendUser(UserProxy calldata _userProxy) public zeroAddressCheck(_userProxy.user) onlyPermissionsAdmin {
        require(!isSuspended(_userProxy.user), "PMV2: Address is already suspended");
        permissionItems.mint(_userProxy.user, SUSPENDED_ID, 1, "");

        if (_userProxy.proxy != address(0)) {
            require(!isSuspended(_userProxy.proxy), "PMV2: Proxy is already suspended");
            permissionItems.mint(_userProxy.proxy, SUSPENDED_ID, 1, "");
        }
    }

    /**
     * @dev Suspends permissions effects to a list of users and proxies.
     *
     * Requirements:
     *
     * - the caller must be the owner.
     * - All user addresses in `_usersProxies` should not be already suspended.
     * - All proxy addresses in `_usersProxies` should not be already suspended.
     * - All user addresses in `_usersProxies` should not be a zero address.
     *
     * @param _usersProxies The addresses of the users and proxies.
     *                      An array of the struct UserProxy where is required
     *                      but proxy can be optional if it is set to zero address.
     */
    function suspendUsers(UserProxy[] calldata _usersProxies) external {
        for (uint256 i = 0; i < _usersProxies.length; i++) {
            suspendUser(_usersProxies[i]);
        }
    }

    /**
     * @dev Re-activates pemissions effects for user and proxy.
     *
     * Requirements:
     *
     * - the caller must be the owner.
     * - `_userProxy.user` should be suspended.
     * - `_userProxy.proxy` should be suspended.
     *
     * @param _userProxy The address of user and proxy.
     */
    function unsuspendUser(UserProxy calldata _userProxy) public onlyPermissionsAdmin {
        require(isSuspended(_userProxy.user), "PMV2: Address is not currently suspended");
        permissionItems.burn(_userProxy.user, SUSPENDED_ID, 1);

        if (_userProxy.proxy != address(0)) {
            require(isSuspended(_userProxy.proxy), "PMV2: Proxy is not currently suspended");
            permissionItems.burn(_userProxy.proxy, SUSPENDED_ID, 1);
        }
    }

    /**
     * @dev Re-activates pemissions effects on a list of users and proxies.
     *
     * Requirements:
     *
     * - the caller must be the owner.
     * - All user addresses in `_usersProxies` should be suspended.
     * - All proxy addresses in `_usersProxies` should be suspended.
     *
     * @param _usersProxies The addresses of the users and proxies.
     *                      An array of the struct UserProxy where is required
     *                      but proxy can be optional if it is set to zero address.
     */
    function unsuspendUsers(UserProxy[] calldata _usersProxies) external onlyPermissionsAdmin {
        for (uint256 i = 0; i < _usersProxies.length; i++) {
            unsuspendUser(_usersProxies[i]);
        }
    }

    /**
     * @dev Assigns Reject permission to user and proxy.
     *
     * Requirements:
     *
     * - the caller must be the owner.
     * - Address in `_userProxy.user` should not be already rejected.
     * - Address in `_userProxy.proxy` should not be already rejected.
     * - Address in `_userProxy.user` should not be zero address.
     *
     *
     * @param _userProxy The address of user and proxy.
     */
    function rejectUser(UserProxy calldata _userProxy) public zeroAddressCheck(_userProxy.user) onlyPermissionsAdmin {
        require(!isRejected(_userProxy.user), "PMV2: Address is already rejected");
        permissionItems.mint(_userProxy.user, REJECTED_ID, 1, "");

        if (_userProxy.proxy != address(0)) {
            require(!isRejected(_userProxy.proxy), "PMV2: Proxy is already rejected");

            permissionItems.mint(_userProxy.proxy, REJECTED_ID, 1, "");
        }
    }

    /**
     * @dev Assigns Reject permission to a list of users and proxies.
     *
     * Requirements:
     *
     * - the caller must be the owner.
     * - All user addresses in `_usersProxies` should not be already rejected.
     * - All proxy addresses in `_usersProxies` should not be already rejected.
     * - All user addresses in `_usersProxies` should not be a zero address.
     *
     *
     * @param _usersProxies The addresses of the users and proxies.
     *                      An array of the struct UserProxy where is required
     *                      but proxy can be optional if it is set to zero address.
     */
    function rejectUsers(UserProxy[] calldata _usersProxies) external {
        for (uint256 i = 0; i < _usersProxies.length; i++) {
            rejectUser(_usersProxies[i]);
        }
    }

    /**
     * @dev Removes Reject permission from user and proxy.
     *
     * Requirements:
     *
     * - the caller must be the owner.
     * - `_userProxy.user` should be rejected.
     * - `_userProxy.proxy` should be rejected.
     *
     *
     * @param _userProxy The address of user and proxy.
     */
    function unrejectUser(UserProxy calldata _userProxy) public onlyPermissionsAdmin {
        require(isRejected(_userProxy.user), "PMV2: Address is not currently rejected");
        permissionItems.burn(_userProxy.user, REJECTED_ID, 1);

        if (_userProxy.proxy != address(0)) {
            require(isRejected(_userProxy.proxy), "PMV2: Proxy is not currently rejected");
            permissionItems.burn(_userProxy.proxy, REJECTED_ID, 1);
        }
    }

    /**
     * @dev Removes Reject permission from a list of users and proxies.
     *
     * Requirements:
     *
     * - the caller must be the owner.
     * - All user addresses in `_usersProxies` should be rejected.
     * - All proxy addresses in `_usersProxies` should be rejected.
     *
     *
     * @param _usersProxies The addresses of the users and proxies.
     *                      An array of the struct UserProxy where is required
     *                      but proxy can be optional if it is set to zero address.
     */
    function unrejectUsers(UserProxy[] calldata _usersProxies) external {
        for (uint256 i = 0; i < _usersProxies.length; i++) {
            unrejectUser(_usersProxies[i]);
        }
    }

    /**
     * @dev Assigns specific item `_itemId` to the `_account`.
     *
     * Requirements:
     *
     * - the caller must be the owner.
     * - `_account` should not have `_itemId` already assigned.
     * - `_account` should not be address zero.
     *
     * @param _itemId Item to be assigned.
     * @param _account The address to assign Tier1.
     */
    function assignSingleItem(
        uint256 _itemId,
        address _account
    ) public zeroAddressCheck(_account) onlyPermissionsAdmin {
        require(!_hasItem(_account, _itemId), "PMV2: Account is assigned with item");
        permissionItems.mint(_account, _itemId, 1, "");
    }

    /**
     * @dev Assigns specific item `_itemId` to the list `_accounts`.
     *
     * Requirements:
     *
     * - the caller must be the owner.
     * - each address in `_accounts` should not have `_itemId` already assigned.
     * - each address in `_accounts` should not be zero address.
     *
     * @param _itemId Item to be assigned.
     * @param _accounts The addresses to assign Tier1.
     */
    function assignItem(uint256 _itemId, address[] calldata _accounts) external {
        for (uint256 i = 0; i < _accounts.length; i++) {
            assignSingleItem(_itemId, _accounts[i]);
        }
    }

    /**
     * @dev Removes specific item `_itemId` from `_account`.
     *
     * Requirements:
     *
     * - the caller must be the owner.
     * - `_accounts` should have `_itemId` already assigned.
     *
     * @param _itemId Item to be removed
     * @param _account The address to assign Tier1.
     */
    function removeSingleItem(uint256 _itemId, address _account) public onlyPermissionsAdmin {
        require(_hasItem(_account, _itemId), "PermissionManager: Account is not assigned with item");

        permissionItems.burn(_account, _itemId, 1);
    }

    /**
     * @dev Removes specific item `_itemId` to the list `_accounts`.
     *
     * Requirements:
     *
     * - the caller must be the owner.
     * - each address in `_accounts` should have `_itemId` already assigned.
     *
     * @param _itemId Item to be removed
     * @param _accounts The addresses to assign Tier1.
     */
    function removeItem(uint256 _itemId, address[] calldata _accounts) external {
        for (uint256 i = 0; i < _accounts.length; i++) {
            removeSingleItem(_itemId, _accounts[i]);
        }
    }

    /**
     * @dev Returns `true` if `_account` has been assigned Tier1 permission.
     *
     * @param _account The address of the user.
     */
    function hasTier1(address _account) public view returns (bool) {
        return _hasItem(_account, TIER_1_ID);
    }

    /**
     * @dev Returns `true` if `_account` has been assigned Tier2 permission.
     *
     * @param _account The address of the user.
     */
    function hasTier2(address _account) public view returns (bool) {
        return _hasItem(_account, TIER_2_ID);
    }

    /**
     * @dev Returns `true` if `_account` has been assigned SoF token permission.
     *
     * @param _account The address of the user.
     */
    function hasSoFToken(address _account) public view returns (bool) {
        return _hasItem(_account, SOF_TOKEN_ITEM_ID);
    }

    /**
     * @dev Returns `true` if `_account` has been Suspended.
     *
     * @param _account The address of the user.
     */
    function isSuspended(address _account) public view returns (bool) {
        return _hasItem(_account, SUSPENDED_ID);
    }

    /**
     * @dev Returns `true` if `_account` has been Rejected.
     *
     * @param _account The address of the user.
     */
    function isRejected(address _account) public view returns (bool) {
        return _hasItem(_account, REJECTED_ID);
    }

    /**
     * @dev Sets the counter for the new 1155 ID
     *
     * @param _newId The new 1155 ID to start from
     */
    function editLastSecurityTokenId(uint256 _newId) external onlyPermissionsAdmin {
        require(_newId > 99, "PMV2: security id needs to be larger than 99");
        emit LastSecurityTokenIdEdited(lastSecurityTokenId, _newId, _msgSender());
        lastSecurityTokenId = _newId;
    }

    /**
     * @dev Get the 1155 ID from the token address
     *
     * @param _tokenContract The address of the token to get the 1155 ID from
     */
    function getSecurityTokenId(address _tokenContract) external view returns (uint256) {
        return securityTokens[_tokenContract];
    }

    /**
     * @dev Generates the new 1155 ID for the token contract
     *
     * @param _tokenContract The address of the token to generate the 1155 ID
     */
    function generateSecurityTokenId(address _tokenContract) external onlyPermissionsAdmin returns (uint256) {
        require(_tokenContract != address(0), "PMV2: Invalid token address");
        require(securityTokens[_tokenContract] == 0, "PMV2: Id already generated for this token");

        // this is to start from 99 to let empty places for other tiers in swarm
        if (lastSecurityTokenId == 0) {
            lastSecurityTokenId = 99;
        }
        lastSecurityTokenId = lastSecurityTokenId + 1;
        emit NewSecurityTokenIdGenerated(lastSecurityTokenId, _tokenContract);
        securityTokens[_tokenContract] = lastSecurityTokenId;
        return lastSecurityTokenId;
    }

    /**
     * @dev Check if the account has 1155 ID
     *
     * @param _user The account to check
     * @param _itemId The ID of the 1155 token
     * @return bool true if the account has such ID
     */
    function hasSecurityToken(address _user, uint256 _itemId) external view returns (bool) {
        require(_itemId > 99, "PMV2: itemId is not correct for security token");
        return _hasItem(_user, _itemId);
    }

    /**
     * @dev Check if the account has 1155 token(item)
     *
     * @param _user The account to check
     * @param _itemId The ID of the 1155 token
     * @return bool true if the account has such ID
     */
    function hasItem(address _user, uint256 _itemId) public view returns (bool) {
        return _hasItem(_user, _itemId);
    }

    function _hasItem(address _user, uint256 _itemId) private view returns (bool) {
        return permissionItems.balanceOf(_user, _itemId) > 0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/Initializable.sol";
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "../utils/EnumerableSetUpgradeable.sol";
import "../utils/AddressUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../proxy/Initializable.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms.
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
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable {
    function __AccessControl_init() internal initializer {
        __Context_init_unchained();
        __AccessControl_init_unchained();
    }

    function __AccessControl_init_unchained() internal initializer {
    }
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    using AddressUpgradeable for address;

    struct RoleData {
        EnumerableSetUpgradeable.AddressSet members;
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
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role].members.contains(account);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view returns (uint256) {
        return _roles[role].members.length();
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
    function getRoleMember(bytes32 role, uint256 index) public view returns (address) {
        return _roles[role].members.at(index);
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view returns (bytes32) {
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
    function grantRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to grant");

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
    function revokeRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to revoke");

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
    function renounceRole(bytes32 role, address account) public virtual {
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
        emit RoleAdminChanged(role, _roles[role].adminRole, adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (_roles[role].members.add(account)) {
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (_roles[role].members.remove(account)) {
            emit RoleRevoked(role, account, _msgSender());
        }
    }
    uint256[49] private __gap;
}

//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.7.0;

import "../interfaces/IPermissionItems.sol";

/**
 * @title PemissionManagerStorage
 * @author Swarm
 * @dev Storage structure used by PermissionManager contract.
 *
 * All storage must be declared here
 * New storage must be appended to the end
 * Never remove items from this list
 */
abstract contract PermissionManagerStorage {
    bytes32 public constant PERMISSIONS_ADMIN_ROLE = keccak256("PERMISSIONS_ADMIN_ROLE");

    IPermissionItems public permissionItems;

    // Constants for Permissions ID
    uint256 public constant SUSPENDED_ID = 0;
    uint256 public constant TIER_1_ID = 1;
    uint256 public constant TIER_2_ID = 2;
    uint256 public constant REJECTED_ID = 3;
    uint256 public constant PROTOCOL_CONTRACT = 4;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
import "../proxy/Initializable.sol";

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
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
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

import "../utils/AddressUpgradeable.sol";

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
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

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

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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

pragma solidity ^0.7.0;

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

//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.7.0;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

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
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external view returns (uint256);

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
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

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

/**
 * @title Interface for PermissionItems
 * @author Swarm
 * @dev Interface for contract module which provides a permissioning mechanism through the asisgnation of ERC1155 tokens.
 * It inherits from standard EIP1155 and extends functionality for
 * role based access control and makes tokens non-transferable.
 */
interface IPermissionItems is IERC1155, IAccessControl {
    // Constants for roles assignments
    function MINTER_ROLE() external returns (bytes32);

    function BURNER_ROLE() external returns (bytes32);

    /**
     * @dev See {PermissionItems-setAdmin}.
     */
    function setAdmin(address account) external;

    /**
     * @dev Revokes TRANSFER role to `account`.
     *
     * Revokes MINTER role to `account`.
     * Revokes BURNER role to `account`.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeAdmin(address account) external;

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `account`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - the caller must have MINTER role.
     * - `account` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] variant of {mint}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) external;

    /**
     * @dev Destroys `amount` tokens of token type `id` from `account`
     *
     * Requirements:
     *
     * - the caller must have BURNER role.
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens of token type `id`.
     */
    function burn(
        address account,
        uint256 id,
        uint256 value
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {burn}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory values
    ) external;

    /**
     * @dev Disabled setApprovalForAll function.
     *
     */
    function setApprovalForAll(address, bool) external pure override;

    /**
     * @dev Disabled safeTransferFrom function.
     *
     */
    function safeTransferFrom(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) external pure override;

    /**
     * @dev Disabled safeBatchTransferFrom function.
     *
     */
    function safeBatchTransferFrom(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) external pure override;

    /**
     * See {IERC165-supportsInterface}
     */
    function supportsInterface(bytes4 interfaceId) external view override returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "../../introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values);

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids) external view returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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