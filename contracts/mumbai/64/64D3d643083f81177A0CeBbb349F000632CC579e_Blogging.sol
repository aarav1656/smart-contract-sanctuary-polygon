// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./utils/IBalanceVault.sol";

/**
 * @dev Use to distribute blogging reward and donation.
 * Has a function to approve blog creation.
 * Has a function to register blog owner.
 * Has functions to create/update/delete event.
 * Has a function for recieving/claiming blog donation.
 * Has functions to event reward.
 * Has functions for retriving blog, blog owner and event information.
 * @notice Is pausable to prevent malicious behavior.
 * @notice Utilize balance vault to minimize gas cost in token transfer.
 */
contract Blogging is Ownable, AccessControl, Pausable {
    using SafeERC20 for IERC20;

    struct Blog {
        string blogId;
        address blogOwner;
        uint256 blogDonation;
        mapping(string => Event) blogEventByEventId;
        uint256 blogTotalDonation;
        uint256 blogTotalEventReward;
    }
    struct BlogOwner {
        address blogOwner;
        mapping(string => Event) blogOwnerEventByEventId;
        uint256 blogOwnerTotalEventReward;
    }
    struct Event {
        string eventId;
        uint256 eventReward;
    }

    bytes32 public constant WORKER = keccak256("WORKER");

    IERC20 public token;
    IBalanceVault public balanceVault;
    address public adminAddress;

    uint256 public eventRewardBalance;
    mapping(string => Event) public eventByEventId;
    mapping(string => Blog) public blogByBlogId;
    mapping(address => BlogOwner) public blogOwnerByAddress;

    event EventCreated(string indexed eventId, uint256 eventReward);
    event EventUpdated(string indexed eventId, uint256 eventReward);
    event EventDeleted(string indexed eventId);
    event BlogCreated(string indexed blogId, address indexed blogOwner);
    event BlogDonated(string indexed blockId, uint256 donateAmount);
    event BlogEventRewardClaimed(string indexed blogId, string indexed eventId, uint256 eventReward);
    event BlogDonationClaimed(string indexed blogId, uint256 claimAmount, uint256 fees);
    event BlogOwnerRegistered(address indexed blogOwner);
    event BlogOwnerEventRewardClaimed(address indexed blogOwner, string indexed eventId, uint256 eventReward);
    event EventRewardDeposited(uint256 depositAmount);

    error InvalidEvent(uint256 eventIdx, string reason);

    /**
     * @dev Setup role for deployer.
     * Setup token interface.
     * @param _tokenAddress - Token address.
     */
    constructor(
        address _tokenAddress,
        address _balanceVaultAddress,
        address _adminAddress
    ) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        grantRole(WORKER, msg.sender);

        token = IERC20(_tokenAddress);
        balanceVault = IBalanceVault(_balanceVaultAddress);
        adminAddress = _adminAddress;
    }

    /**
     * @dev Revert receive and fallback functions.
     */
    receive() external payable {
        revert("[Blogging] Revert receive function.");
    }
    fallback() external payable {
        revert("[Blogging] Revert fallback function.");
    }

    /**
     * @dev Allow for created blog.
     */
    modifier blogCreated(string memory _blogId) {
        require(
            bytes(blogByBlogId[_blogId].blogId).length > 0,
            "[Blogging.blogCreated] Blog not created yet"
        );
        _;
    }
    /**
     * @dev Allow for created event.
     */
    modifier eventCreated(string memory _eventId) {
        require(
            bytes(eventByEventId[_eventId].eventId).length > 0,
            "[Blogging.eventCreated] Event not created yet"
        );
        _;
    }
    /**
     * @dev Allow for registered blog owner.
     */
    modifier blogOwnerRegistered(address _blogOwner) {
        require(
            blogOwnerByAddress[_blogOwner].blogOwner != address(0),
            "[Blogging.blogOwnerRegistered] Blog owner not registered yet"
        );
        _;
    }
    
    /**
     * @dev Set new owner for block.
     * @param _blogId - Blog id.
     * @param _blogOwner - New blog owner address.
     * @notice Incase of emergency.
     */
    function setBlogOwner(string memory _blogId, address _blogOwner) external onlyOwner {
        blogByBlogId[_blogId].blogOwner = _blogOwner;
    }
    /**
     * @dev Set new address for balance vault interface.
     * @param _balanceVaultAddress - New balance vault address.
     */
    function setBalanceVaultAddress(address _balanceVaultAddress) external onlyOwner {
        balanceVault = IBalanceVault(_balanceVaultAddress);
    }
    /**
     * @dev Set new address for admin.
     * @param _adminAddress - New admin address.
     */
    function setAdminAddress(address _adminAddress) external onlyOwner {
        adminAddress = _adminAddress;
    }
    /**
     * @dev Set contract into pause state (only claim function allowed).
     */
    function pauseBlogging() external onlyOwner {
        _pause();
    }
    /**
     * @dev Set contract back to normal state.
     */
    function unpauseBlogging() external onlyOwner {
        _unpause();
    }

    /**
     * @dev Create blog, setup variables and register blog owner.
     * @param _blogId - Blog id.
     * @param _blogOwner - Blog owner address.
     */
    function approveBlogCreate(string memory _blogId, address _blogOwner) external whenNotPaused onlyRole(WORKER) {
        Blog storage blog = blogByBlogId[_blogId];
        require(
            bytes(blog.blogId).length == 0,
            "[Blogging.approveBlogCreate] Blog already created"
        );
        blog.blogId = _blogId;
        blog.blogOwner = _blogOwner;
        registerBlogOwner(_blogOwner);

        emit BlogCreated(_blogId, _blogOwner);
    }

    /**
     * @dev Transfer token from sender, update donation amount.
     * @param _blogId - Blog id.
     * @param _donateAmount - Donation amount.
     */
    function donateToBlogOwner(string memory _blogId, uint256 _donateAmount) external whenNotPaused blogCreated(_blogId) {
        Blog storage blog = blogByBlogId[_blogId];

        require(
            token.allowance(msg.sender, address(this)) >= _donateAmount,
            "[Blogging.donateToBlogOwner] Insufficient donation allowance"
        );
        token.safeTransferFrom(msg.sender, address(this), _donateAmount);
        token.approve(address(balanceVault), _donateAmount);
        balanceVault.depositUpo(_donateAmount);
        blog.blogDonation += _donateAmount;
        blog.blogTotalDonation += _donateAmount;

        emit BlogDonated(_blogId, _donateAmount);
    }

    /**
     * @dev Create event(s).
     * @param _eventList - Event struct array.
     */
    function batchCreateEvent(Event[] memory _eventList) external whenNotPaused onlyRole(WORKER) {
        require(
            _eventList.length > 0,
            "[Blogging.batchCreateEvent] Invalid tournament event list length"
        );

        for (uint256 i = 0; i < _eventList.length; i++) {
            Event storage _event = eventByEventId[_eventList[i].eventId];

            if(bytes(_event.eventId).length != 0)
                revert InvalidEvent(i, "Event already created");
            _event.eventId = _eventList[i].eventId;
            _event.eventReward = _eventList[i].eventReward;

            emit EventCreated(_event.eventId, _event.eventReward);
        }
    }   

    /**
     * @dev Update event.
     * @param _eventId - Event id.
     * @param _eventReward - Event reward.
     */
    function updateEvent(string memory _eventId, uint256 _eventReward) external whenNotPaused onlyRole(WORKER) eventCreated(_eventId) {
        Event storage _event = eventByEventId[_eventId];
        _event.eventReward = _eventReward;

        emit EventUpdated(_eventId, _eventReward);
    }

    /**
     * @dev Delete event.
     * @param _eventId - Event id.
     */
    function deleteEvent(string memory _eventId) external whenNotPaused onlyRole(WORKER) eventCreated(_eventId) {
        delete eventByEventId[_eventId];
        
        emit EventDeleted(_eventId);
    }

    /**
     * @dev Update blog event(s) reward data, transfer token to blog owner.
     * @param _blogId - Blog id.
     * @param _eventIdList - Array of event id.
     */
    function batchClaimBlogEventReward(
        string memory _blogId,
        string[] memory _eventIdList
    ) external onlyRole(WORKER) blogCreated(_blogId) {
        require(
            _eventIdList.length > 0,
            "[Blogging.batchClaimBlogEventReward] Invalid tournament event list length"
        );

        Blog storage blog = blogByBlogId[_blogId];
        for (uint256 i = 0; i < _eventIdList.length; i++) {
            Event storage blogEvent = blog.blogEventByEventId[_eventIdList[i]];
            Event memory _event = eventByEventId[_eventIdList[i]];

            if(bytes(_event.eventId).length == 0)
                revert InvalidEvent(i, "Invalid event");
            if(bytes(blogEvent.eventId).length != 0)
                revert InvalidEvent(i, "Blog event reward already claimed");
            if(eventRewardBalance < _event.eventReward)
                revert InvalidEvent(i, "Insufficient event reward balance for blog event");

            eventRewardBalance -= _event.eventReward;
            blog.blogTotalEventReward += _event.eventReward;
            blogEvent.eventId = _event.eventId;
            blogEvent.eventReward = _event.eventReward;
            balanceVault.increaseBalance(blog.blogOwner, _event.eventReward);
            balanceVault.decreaseBalance(address(this), _event.eventReward);

            emit BlogEventRewardClaimed(_blogId, _event.eventId, _event.eventReward);
        }
    }

    /**
     * @dev Update blog owner event(s) reward data, transfer token to blog owner.
     * @param _blogOwner - Blog owner address.
     * @param _eventIdList - Array of event id.
     */
    function batchClaimBlogOwnerEventReward(
        address _blogOwner,
        string[] memory _eventIdList
    ) external onlyRole(WORKER) blogOwnerRegistered(_blogOwner) {
        require(
            _eventIdList.length > 0,
            "[Blogging.batchClaimBlogOwnerEventReward] Invalid tournament event list length"
        );

        BlogOwner storage blogOwner = blogOwnerByAddress[_blogOwner];
        for (uint256 i = 0; i < _eventIdList.length; i++) {
            Event storage blogOwnerEvent = blogOwner.blogOwnerEventByEventId[_eventIdList[i]];
            Event memory _event = eventByEventId[_eventIdList[i]];

            if(bytes(_event.eventId).length == 0)
                revert InvalidEvent(i, "Invalid event");
            if(bytes(blogOwnerEvent.eventId).length != 0)
                revert InvalidEvent(i, "Blog owner event reward already claimed");
            if(eventRewardBalance < _event.eventReward)
                revert InvalidEvent(i, "Insufficient event reward balance for blog owner event");

            eventRewardBalance -= _event.eventReward;
            blogOwner.blogOwnerTotalEventReward += _event.eventReward;
            blogOwnerEvent.eventId = _event.eventId;
            blogOwnerEvent.eventReward = _event.eventReward;
            balanceVault.increaseBalance(_blogOwner, _event.eventReward);
            balanceVault.decreaseBalance(address(this), _event.eventReward);

            emit BlogOwnerEventRewardClaimed(_blogOwner, _event.eventId, _event.eventReward);
        }
    }

    /**
     * @dev Update donation data, deduct fees, transfer token to blog owner.
     * @param _blogId - Blog id.
     * @param _claimAmount - Donation claim amount.
     * @param _fees - Fees for donation claimed.
     */
    function claimBlogDonation(
        string memory _blogId,
        uint256 _claimAmount,
        uint256 _fees
    ) external onlyRole(WORKER) blogCreated(_blogId) {
        Blog storage blog = blogByBlogId[_blogId];

        uint256 claimAmtIncFees = _claimAmount + _fees;
        require(
            blog.blogDonation >= claimAmtIncFees,
            "[Blogging.claimBlogDonation] Insufficient blog donation"
        );
        blog.blogDonation -= claimAmtIncFees;
        balanceVault.increaseBalance(adminAddress, _fees);
        balanceVault.increaseBalance(blog.blogOwner, _claimAmount);
        balanceVault.decreaseBalance(address(this), claimAmtIncFees);

        emit BlogDonationClaimed(_blogId, _claimAmount, _fees);
    }

    /**
     * @dev Deposit event reward to contract.
     * @param _depositAmount - Event reward deposit amount.
     */
    function depositEventReward(uint256 _depositAmount) external whenNotPaused onlyRole(WORKER) {
        token.safeTransferFrom(msg.sender, address(this), _depositAmount);
        token.approve(address(balanceVault), _depositAmount);
        balanceVault.depositUpo(_depositAmount);
        eventRewardBalance += _depositAmount;

        emit EventRewardDeposited(_depositAmount);
    }

    /** 
    * @dev Retrieve blog info.
    * @param _blogId - Existing blog id.
    */
    function getBlogInfo(string memory _blogId)
        external
        view    
        returns (
            string memory blogId,
            address blogOwner,
            uint256 blogDonation,
            uint256 blogTotalDonation,
            uint256 blogTotalEventReward
        ) 
    {
        Blog storage blog = blogByBlogId[_blogId];

        blogId = blog.blogId;
        blogOwner = blog.blogOwner;
        blogDonation = blog.blogDonation;
        blogTotalDonation = blog.blogTotalDonation;
        blogTotalEventReward = blog.blogTotalEventReward;
    }

    /** 
    * @dev Retrieve blog owner info.
    * @param _blogOwner - Existing blog owner address.
    */
    function getBlogOwnerInfo(address _blogOwner)
        external
        view    
        returns (
            address blogOwner,
            uint256 blogOwnerTotalEventReward
        ) 
    {
        BlogOwner storage __blogOwner = blogOwnerByAddress[_blogOwner];

        blogOwner = __blogOwner.blogOwner;
        blogOwnerTotalEventReward = __blogOwner.blogOwnerTotalEventReward;
    }

    /** 
    * @dev Retrieve event info.
    * @param _eventId - Existing event id.
    */
    function getEventInfo(string memory _eventId)
        external
        view    
        returns (
            string memory eventId,
            uint256 eventReward
        ) 
    {
        Event storage _event = eventByEventId[_eventId];

        eventId = _event.eventId;
        eventReward = _event.eventReward;
    }

    /** 
    * @dev Retrieve blog event info.
    * @param _blogId - Existing blog id.
    * @param _eventId - Event id.
    */
    function getBlogEventInfo(string memory _blogId, string memory _eventId)
        external
        view
        returns (
            string memory eventId,
            uint256 eventReward
        )
    {
        Event storage _event = blogByBlogId[_blogId].blogEventByEventId[_eventId];
        
        eventId = _event.eventId;
        eventReward = _event.eventReward;
    }

    /** 
    * @dev Retrieve blogOwner event info.
    * @param _blogOwner - BlogOwner address.
    * @param _eventId - Event id.
    */
    function getBlogOwnerEventInfo(address _blogOwner, string memory _eventId)
        external
        view
        returns (
            string memory eventId,
            uint256 eventReward
        )
    {
        Event storage _event = blogOwnerByAddress[_blogOwner].blogOwnerEventByEventId[_eventId];
        
        eventId = _event.eventId;
        eventReward = _event.eventReward;
    }

    /** 
    * @dev Retrieve blog event specify in event id list.
    * @param _blogId - Existing blog id.
    * @param _eventIdList - Array of event id.
    */
    function getBlogEventList(string memory _blogId, string[] memory _eventIdList)
        external
        view
        returns (
            Event[] memory eventList
        )
    {
        Blog storage blog = blogByBlogId[_blogId];

        eventList = new Event[](_eventIdList.length);
        for (uint256 i = 0; i < _eventIdList.length; i++) {
            eventList[i] = blog.blogEventByEventId[_eventIdList[i]];
        }
    }

    /** 
    * @dev Retrieve blogOwner event specify in event id list.
    * @param _blogOwner - BlogOwner address.
    * @param _eventIdList - Array of event id.
    */
    function getBlogOwnerEventList(address _blogOwner, string[] memory _eventIdList)
        external
        view
        returns (
            Event[] memory eventList
        )
    {
        BlogOwner storage blogOwner = blogOwnerByAddress[_blogOwner];

        eventList = new Event[](_eventIdList.length);
        for (uint256 i = 0; i < _eventIdList.length; i++) {
            eventList[i] = blogOwner.blogOwnerEventByEventId[_eventIdList[i]];
        }
    }

    /**
     * @dev Register blog owner if not exist.
     * @param _blogOwner - Blog owner address.
     */
    function registerBlogOwner(address _blogOwner) public whenNotPaused onlyRole(WORKER) {
        BlogOwner storage blogOwner = blogOwnerByAddress[_blogOwner];
        if(blogOwner.blogOwner == address(0)) {
            blogOwner.blogOwner = _blogOwner;

            emit BlogOwnerRegistered(_blogOwner);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

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
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

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
pragma solidity ^0.8.7;

interface IBalanceVault{
    function depositUpo(uint256 _upoAmount) external;
    function withdrawUpo(uint256 _upoAmount) external;
    function increaseBalance(address _userAddress, uint256 _upoAmount) external;
    function decreaseBalance(address _userAddress, uint256 _upoAmount) external;
    function increaseReward(uint256 _upoAmount) external;
    function decreaseReward(uint256 _upoAmount) external;
    function getBalance(address _userAddress) external view returns (uint256);
    function getReward() external view returns (uint256);
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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