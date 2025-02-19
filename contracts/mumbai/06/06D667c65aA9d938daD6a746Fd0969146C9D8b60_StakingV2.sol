// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./utils/IStakingFactory.sol";

/**
 * @dev This contract is designed to work as fixed reward staking pool which reward could be claimed daily.
 * Has function to add reward to staking pool.
 * Has functions to stake token and withdraw token.
 * Has functions to get user unclaim reward amount.
 * Has functions to get user stake amount and claim amount.
 */
contract StakingV2 is AccessControl, Ownable, Pausable, ReentrancyGuard {
    bytes32 public constant STAKINGOWNER = keccak256("STAKINGOWNER");

    struct UserInfo {
        uint256 stakeAmount;
        uint256 claimedAmount;
        uint256 withdrawnAmount;
    }

    IStakingFactory public stakingFactory;
    mapping(address => UserInfo) public userInfo;
    address public tokenAddress;
    uint256 public startStakeTime;
    uint256 public endStakeTime;
    uint256 public duration;
    uint256 public userStakeLimit;
    uint256 public poolStakeLimit;
    uint256 public poolStakeTotal;
    uint256 public poolReward;
    uint256 public distributedReward;
    uint256 public percentage;
    address public stakingOwner;

    event PoolRewardAdded(uint256 tokenAmount);
    event PoolRewardReduced(uint256 tokenAmount);
    event TokenStaked(address indexed userAddress, uint256 tokenAmount);
    event TokenWithdrawn(address indexed userAddress, uint256 tokenAmount);
    event RewardClaimed(address indexed userAddress, uint256 tokenAmount);
    event StakeRefunded(address indexed userAddress, uint256 refundAmount);
    event StakingOwnerChanged(address stakingOwner);

    constructor(
        address _tokenAddress,
        uint256 _startStakeTime,
        uint256 _endStakeTime,
        uint256 _userStakeLimit,
        uint256 _poolStakeLimit,
        uint256 _percentage,
        address _stakingOwner
    ) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        stakingFactory = IStakingFactory(msg.sender);

        tokenAddress = _tokenAddress;
        startStakeTime = _startStakeTime;
        endStakeTime = _endStakeTime;
        userStakeLimit = _userStakeLimit;
        poolStakeLimit = _poolStakeLimit;
        percentage = _percentage;
        stakingOwner = _stakingOwner;
        grantRole(STAKINGOWNER, stakingOwner);

        uint256 startDay = (startStakeTime - (startStakeTime % 86400)) / 86400;
        uint256 endDay = (endStakeTime - (endStakeTime % 86400)) / 86400;
        duration = endDay - startDay;
    }

    /**
     * @dev Modifier to only allow the function to be executed before staking period started
     */
    modifier beforeStakeStarted() {
        require(
            block.timestamp < startStakeTime,
            "[StakingV2.beforeStakeStarted] Staking period started"
        );
        _;
    }

    /**
     * @dev Modifier to only allow the function to be executed after staking period started
     */
    modifier afterStakeStarted() {
        require(
            block.timestamp >= startStakeTime,
            "[StakingV2.afterStakeStarted] Staking period not yet started"
        );
        _;
    }

    /**
     * @dev Modifier to only allow the function to be executed after staking period end
     */
    modifier afterStakeEnded() {
        require(
            block.timestamp >= endStakeTime,
            "[StakingV2.afterStakeEnded] Staking period not yet ended"
        );
        _;
    }

    /**
     * @dev Revert receive and fallback functions.
     */
    receive() external payable {
        revert("[StakingV2] Revert receive function.");
    }

    fallback() external payable {
        revert("[StakingV2] Revert fallback function.");
    }

    function increaseTime(uint256 _time) external {
        startStakeTime -= _time;
        endStakeTime -= _time;
    }

    /**
     * @dev Function for increase staking pool reward.
     * Owner can use to increase pool reward in contract.
     * Amount of reward will be maximum possible reward of this pool.
     */
    function addPoolReward()
        external
        beforeStakeStarted
        onlyRole(STAKINGOWNER)
    {
        uint256 maxPoolReward = calculatePoolRewardAmount(poolStakeLimit);
        stakingFactory.vaultPayWithToken(msg.sender, tokenAddress, maxPoolReward);
        poolReward += maxPoolReward;

        emit PoolRewardAdded(maxPoolReward);
    }

    /**
     * @dev Function for withdraw exceed staking pool reward.
     * Owner can use to withdraw and decrease pool reward in contract.
     */
    function withdrawExceedPoolReward()
        external
        nonReentrant
        onlyRole(STAKINGOWNER)
        afterStakeStarted
    {
        uint256 actualRewardAmount = calculatePoolRewardAmount(poolStakeTotal);
        require(
            poolReward >= actualRewardAmount,
            "[StakingV2.withdrawExceedPoolReward] Pool reward not exceed actual reward amount"
        );
        uint256 exceedAmount = poolReward - actualRewardAmount;
        poolReward -= exceedAmount;
        stakingFactory.vaultTransferTokenToAddress(msg.sender, tokenAddress, exceedAmount);

        emit PoolRewardReduced(exceedAmount);
    }

    /**
     * @dev Function for stake token.
     * Use to increase user stake amount and pool stake total before staking period start.
     * @param _tokenAmount - Amount of token to be staked.
     */
    function stakeToken(uint256 _tokenAmount)
        external
        whenNotPaused
        beforeStakeStarted
    {
        require(
            _tokenAmount + userInfo[msg.sender].stakeAmount <= userStakeLimit,
            "[StakingV2.stakeToken] total stake amount should be less than user limit"
        );
        require(
            _tokenAmount + poolStakeTotal <= poolStakeLimit,
            "[StakingV2.stakeToken] total stake amount should be less than pool limit"
        );
        stakingFactory.vaultPayWithToken(msg.sender, tokenAddress, _tokenAmount);
        userInfo[msg.sender].stakeAmount += _tokenAmount;
        poolStakeTotal += _tokenAmount;

        emit TokenStaked(msg.sender, _tokenAmount);
    }

    /**
     * @dev Function for withdraw staked token.
     * Use to withdraw user all remaining staked token and delete user info after user claim all reward and staking period end.
     */
    function withdrawToken() external nonReentrant afterStakeEnded {
        require(
            userInfo[msg.sender].withdrawnAmount == 0,
            "[StakingV2.withdrawToken] user already withdrawn"
        );
        require(
            getUserUnclaimAmount(msg.sender) == 0,
            "[StakingV2.withdrawToken] unclaim amount should be zero before user can withdraw"
        );
        uint256 userStakeAmount = userInfo[msg.sender].stakeAmount;
        userInfo[msg.sender].withdrawnAmount += userStakeAmount;
        stakingFactory.vaultTransferTokenToAddress(msg.sender, tokenAddress, userStakeAmount);
        
        emit TokenWithdrawn(msg.sender, userStakeAmount);
    }

    /**
     * @dev Function for claim staking reward.
     * Use to transfer reward to user wallet and increase user claim amount limit by user unclaim amount.
     */
    function claimReward() external nonReentrant afterStakeStarted {
        if (poolReward == 0) {
            uint256 refundAmount = userInfo[msg.sender].stakeAmount;
            userInfo[msg.sender].stakeAmount -= refundAmount;
            stakingFactory.vaultTransferTokenToAddress(msg.sender, tokenAddress, refundAmount);

            emit StakeRefunded(msg.sender, refundAmount);
        } else {
            uint256 unclaimAmount = getUserUnclaimAmount(msg.sender);
            require(
                unclaimAmount > 0,
                "[StakingV2.claimReward] Claimable reward = 0"
            );
            userInfo[msg.sender].claimedAmount += unclaimAmount;
            distributedReward += unclaimAmount;
            stakingFactory.vaultTransferTokenToAddress(msg.sender, tokenAddress, unclaimAmount);

            emit RewardClaimed(msg.sender, unclaimAmount);
        }
    }

    /**
     * @dev Function for retrieve user stake amount.
     * Use to retrieve specify user stake amount.
     * @param _userAddress - user address to be retrieve.
     */
    function getUserStakeAmount(address _userAddress)
        external
        view
        returns (uint256)
    {
        return userInfo[_userAddress].stakeAmount;
    }

    /**
     * @dev Function for retrieve user claimed amount.
     * Use to retrieve specify user claimed amount.
     * @param _userAddress - user address to be retrieve.
     */
    function getUserClaimedAmount(address _userAddress)
        external
        view
        returns (uint256)
    {
        return userInfo[_userAddress].claimedAmount;
    }

    /**
     * @dev Function for retrieve user withdrawn amount.
     * Use to retrieve specify user withdrawn amount.
     * @param _userAddress - user address to be retrieve.
     */
    function getUserWithdrawnAmount(address _userAddress)
        external
        view
        returns (uint256)
    {
        return userInfo[_userAddress].withdrawnAmount;
    }

    /**
     * @dev Function for retrieve user unclaim amount.
     * Use to retrieve specify user unclaim amount.
     * Calculated by claimedAmount - (poolReward * dayPassed * stakeAmount) / duration / poolStakeTotal.
     * @param _userAddress - user address to be retrieve.
     */
    function getUserUnclaimAmount(address _userAddress)
        public
        view
        returns (uint256)
    {
        UserInfo memory user = userInfo[_userAddress];
        uint256 currentDay = (block.timestamp - (block.timestamp % 86400)) /
            86400;
        uint256 startDay = (startStakeTime - (startStakeTime % 86400)) / 86400;
        uint256 dayPassed = (currentDay - startDay) > duration
            ? duration
            : (currentDay - startDay);

        uint256 totalRewardUntilToday = (user.stakeAmount *
            percentage *
            dayPassed) /
            100 /
            365;
        return totalRewardUntilToday - user.claimedAmount;
    }

    /**
     * @dev Function for calculate pool reward amount from pool stake amount.
     * @param _poolStakeAmount - pool stake amount.
     */
    function calculatePoolRewardAmount(uint256 _poolStakeAmount) public view returns (uint256) {
        return (_poolStakeAmount * percentage * duration) / 100 / 365;
    }

    /**
     * @dev Function for admin to change staking owner from contract factory
     * in case of emergency.
     */
    function changeStakingOwner(address _stakingOwner) external onlyOwner {
        revokeRole(STAKINGOWNER, stakingOwner);

        stakingOwner = _stakingOwner;
        grantRole(STAKINGOWNER, stakingOwner);

        emit StakingOwnerChanged(stakingOwner);
    }

    /**
     * @dev Set staking in to pause state (only withdraw and claim reward function is allowed).
     */
    function pauseStaking() external onlyRole(STAKINGOWNER) {
        _pause();
    }

    /**
     * @dev Set staking in to pause state (only withdraw and claim reward function is allowed).
     */
    function unpauseStaking() external onlyRole(STAKINGOWNER) {
        _unpause();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControl.sol)

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
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
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
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

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
pragma solidity ^0.8.7;

interface IStakingFactory{
    function vaultPayWithToken(address _userAddress, address _tokenAddress, uint256 _tokenAmount) external;
    function vaultTransferTokenToAddress(address _userAddress, address _tokenAddress, uint256 _tokenAmount) external;
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