// SPDX-License-Identifier: MIT
pragma solidity 0.8.8;
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "./Tournament.sol";

interface ITournament {
    function initialize(
        uint256 _tournamentId,
        address[] calldata _tokens,
        address _registrationToken,
        uint256 _registrationStartTime,
        uint256 _registrationEndTime,
        uint256 _registrationFeeAmount,
        uint256 _pFeeRate,
        uint256 _tFeeRate,
        uint256 _pPenaltyFeeRate,
        uint256 _tPenaltyFeeRate,
        address _eventEmitter
    ) external;
}

interface IDESPortsToken {
    function applyWhiteList(address _whitelist) external;
}

contract TournamentFactory is Pausable, Initializable, AccessControl {
    //Array of created Tournaments Address
    address[] public allTournaments;

    // Platform wallet
    address public pWallet;

    // Platform fee Rate
    uint256 private pFeeRate;

    // Tournament fee Rate
    uint256 private tFeeRate;

    // Platform penalty Rate
    uint256 private pPenaltyFeeRate;

    // Tournament penalty Rate
    uint256 private tPenaltyFeeRate;

    //address of owner;
    address private signer;

    // is end using fake token
    bool public isReady;

    //address of DEST
    address public destAddress;

    //event emitter address
    address public eventEmitter;

    //claim time duration
    uint256 public claimTimeDuration;

    //--------EVENT-----------
    event CreateTournamentEvent(
        address indexed from,
        address[] tokens,
        address newTournamentAddress,
        address registrationToken,
        uint256 registationStartTime,
        uint256 registrartionEndTime,
        uint256 registrationFeeAmount,
        uint256 pFeeRate,
        uint256 tFeeRate,
        uint256 pPenaltyFeeRate,
        uint256 tPenaltyFeeRate
    );

    //--------END EVENT-----------

    function initialize(
        address _signer,
        address _pWallet,
        address _destAddress,
        address _eventEmitter
    ) external initializer {
        //Setup Role
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        signer = _signer;

        pWallet = _pWallet;

        destAddress = _destAddress;

        pFeeRate = 5; //5%

        tFeeRate = 5; //5%

        pPenaltyFeeRate = 0; //0%

        tPenaltyFeeRate = 0; //0%

        claimTimeDuration = 1 days; // can claim after 1 day

        isReady = false;

        eventEmitter = _eventEmitter;
    }

    // grant admin role to other
    function setAdminRole(address _adminAddress) external {
        grantRole(DEFAULT_ADMIN_ROLE, _adminAddress);
    }

    // get platform Walelt
    function getpWallet() external view returns (address) {
        return pWallet;
    }

    // set platformWallet
    function setpWallet(address _pWallet)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        pWallet = _pWallet;
    }

    // get claim time duration
    function getClaimTimeDuration() external view returns (uint256) {
        return claimTimeDuration;
    }

    //set claim time duration
    function setClaimTimeDuration(uint256 _claimTimeDuration)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        claimTimeDuration = _claimTimeDuration;
    }

    // get signer
    function getSigner() external view returns (address) {
        return signer;
    }

    // set platform fee rate
    function setPlatformFeeRate(uint256 _pFeeRate)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        pFeeRate = _pFeeRate;
    }

    // set tournament fee rate
    function setTournamentFeeRate(uint256 _tFeeRate)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        tFeeRate = _tFeeRate;
    }

        // set platform fee rate
    function setPlatformPenaltyFeeRate(uint256 _pPenaltyFeeRate)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        pPenaltyFeeRate = _pPenaltyFeeRate;
    }

    // set tournament fee rate
    function setTournamentPenaltyFeeRate(uint256 _tPenaltyFeeRate)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        tPenaltyFeeRate = _tPenaltyFeeRate;
    }

    function changeStatus(bool _isReady) external onlyRole(DEFAULT_ADMIN_ROLE) {
        isReady = _isReady;
    }

    function setEventEmitter(address _eventEmitter)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        eventEmitter = _eventEmitter;
    }

    //Create a tournament
    function createTournament(
        uint256 _tournamentId,
        address[] calldata _tokens,
        address _registrationToken,
        uint256 _registrationStartTime,
        uint256 _registrationEndTime,
        uint256 _registrationFeeAmount,
        bytes memory _signature
    ) external whenNotPaused returns (address tournament) {
        require(
            _verifyCreateTournament(
                _tournamentId,
                _tokens,
                _registrationToken,
                _registrationStartTime,
                _registrationEndTime,
                _registrationFeeAmount,
                _signature
            ),
            "TOURNAMENTFACTORY:INVALID_SIGNATURE"
        );

        bytes memory bytecode = type(Tournament).creationCode;

        bytes32 salt = keccak256(
            abi.encodePacked(
                msg.sender,
                pFeeRate,
                tFeeRate,
                _tournamentId,
                _tokens,
                _registrationToken,
                _registrationStartTime,
                _registrationEndTime,
                _registrationFeeAmount,
                block.timestamp,
                allTournaments.length
            )
        );
        assembly {
            tournament := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }

        ITournament(tournament).initialize(
            _tournamentId,
            _tokens,
            _registrationToken,
            _registrationStartTime,
            _registrationEndTime,
            _registrationFeeAmount,
            pFeeRate,
            tFeeRate,
            pPenaltyFeeRate,
            tPenaltyFeeRate,
            eventEmitter
        );

        if (!isReady) {
            IDESPortsToken(destAddress).applyWhiteList(tournament);
        }

        IEventEmitter(eventEmitter).applyWhiteList(tournament);

        allTournaments.push(tournament);
        emit CreateTournamentEvent(
            msg.sender,
            _tokens,
            tournament,
            _registrationToken,
            _registrationStartTime,
            _registrationEndTime,
            _registrationFeeAmount,
            pFeeRate,
            tFeeRate,
            pPenaltyFeeRate,
            tPenaltyFeeRate
        );
    }

    function _verifyCreateTournament(
        uint256 _tournamentId,
        address[] calldata _tokens,
        address _registrationToken,
        uint256 _registrationStartTime,
        uint256 _registrationEndTime,
        uint256 _registrationAmount,
        bytes memory _signature
    ) private view returns (bool) {
        return
            verify(
                signer,
                _tournamentId,
                _tokens,
                _registrationToken,
                _registrationStartTime,
                _registrationEndTime,
                _registrationAmount,
                _signature
            );
    }

    // Using Openzeppelin ECDSA cryptography library
    function getMessageHash(
        uint256 _tournamentId,
        address[] calldata _tokens,
        address _registrationToken,
        uint256 _registrationStartTime,
        uint256 _registrationEndTime,
        uint256 _registrationFeeAmount
    ) public pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    _tournamentId,
                    _tokens,
                    _registrationToken,
                    _registrationStartTime,
                    _registrationEndTime,
                    _registrationFeeAmount
                )
            );
    }

    // Verify signature function
    function verify(
        address _signer,
        uint256 _tournamentId,
        address[] calldata _tokens,
        address _registrationToken,
        uint256 _registrationStartTime,
        uint256 _registrationEndTime,
        uint256 _registrationFeeAmount,
        bytes memory signature
    ) public pure returns (bool) {
        bytes32 messageHash = getMessageHash(
            _tournamentId,
            _tokens,
            _registrationToken,
            _registrationStartTime,
            _registrationEndTime,
            _registrationFeeAmount
        );
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);
        return getSignerAddress(ethSignedMessageHash, signature) == _signer;
    }

    function getSignerAddress(bytes32 _messageHash, bytes memory _signature)
        public
        pure
        returns (address)
    {
        return ECDSA.recover(_messageHash, _signature);
    }

    function getEthSignedMessageHash(bytes32 _messageHash)
        public
        pure
        returns (bytes32)
    {
        return ECDSA.toEthSignedMessageHash(_messageHash);
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
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/Address.sol";

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
            (isTopLevelCall && _initialized < 1) || (!Address.isContract(address(this)) && _initialized == 1),
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

//SPDX-License-Identifier: MIT
pragma solidity 0.8.8;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

interface ITournamentFactory {
    function getpWallet() external view returns (address);

    function getSigner() external view returns (address);

    function getClaimTimeDuration() external view returns (uint256);
}

interface IEventEmitter {
    function applyWhiteList(address addedAddress) external;

    function emitRegisterEvent(
        address tournamentAddress,
        address registeredUser,
        uint256 amount
    ) external;

    function emitRefundMultipleEvent(
        address tournamentAddress,
        address organizerUser,
        address[] calldata refundToUsers,
        uint256 amount
    ) external;

    function emitWithDrawEvent(
        address tournamentAddress,
        address withDrawUser
    ) external;

    function emitClaimWithDrawEvent(
        address tournamentAddress,
        address claimedUser,
        uint256 amount
    ) external;

    function emitAddPrizePoolEvent(
        address tournamentAddress,
        address organizer,
        address tokenAddress,
        uint256 amount
    ) external;

    function emitRemovedSponsoredEvent(
        address tournamentAddress,
        address organizer,
        address tokenAddress,
        uint256 amount
    ) external;

    function emitSetClaimTimeEvent(
        address tournamentAddress,
        address adminAddress,
        uint256 claimTime
    ) external;

    function emitDistributeRewardEvent(
        address tournamentAddress,
        address organizer,
        address[] calldata userAddresses,
        address[] calldata tokenRewards,
        uint256[] calldata amounts,
        uint256 remain,
        uint256 claimTime
    ) external;

    function emitClaimRefundEvent(
        address tournamentAddress,
        address userClaimed,
        address token,
        uint256 amount
    ) external;

    function emitClaimedEvent(
        address tournamentAddress,
        address user,
        address[] calldata tokens,
        uint256[] calldata amounts
    ) external;

    function emitDonatedEvent(
        address tournamentAddress,
        address donatedUser,
        address tokenDonated,
        uint256 amount
    ) external;
}

contract Tournament is AccessControl {
    using SafeERC20 for IERC20;

    constructor() {
        factory = msg.sender;
    }

    uint256 private tournamentId;

    // Tokens will be used in tournament
    address[] private tokens;

    // Tokens will be used for register
    address public registrationToken;

    // Register Fee
    uint256 public registrationFeeAmount;

    //Registered Addresses
    mapping(address => bool) public registeredAddresses;

    // The address of factory Contract
    address private factory;

    //The address of event manager contact
    address private eventEmitter;

    // The address of organizer
    address public organizer;

    // The address of Black List
    mapping(address => bool) public blackListAddresses;

    // The platform fee rate
    uint256 private pfeeRate;


    uint256 private pPenaltyFeeRate;

    // The tournament fee rate
    uint256 private tfeeRate;

    uint256 private tPenaltyFeeRate;

    //Total PrizePools
    mapping(address => uint256) public totalPrizePool;


    //Current PoolPrize
    mapping(address => uint256) public currPrizePool;

    //Total Sponsor
    mapping(address => uint256) public totalTokenSponsored;

    //Total donate
    mapping(address => uint256) public totalTokenDonated;

    //Claim Time
    uint256 public claimTime;

    //Registration Start Time
    uint256 public registrationStartTime;

    //Registration End Time
    uint256 public registrationEndTime;

    //
    mapping(address => mapping(address => uint256)) public userDonated;

    // user address => token address => amount
    mapping(address => mapping(address => uint256)) public teamTokenRewards;

    //user address => status
    mapping(address => bool) public teamTokenRefund;

    //user address => amount
    mapping(address => uint256) public teamTokenWithDraw;

    // true: refunded, false otherwise
    bool private isRefunded;

    // ORGANIZER ROLE
    bytes32 public constant ORGANIZER_ROLE = keccak256("ORGANIZER");

    /*
     * function initialize
     * _tokens : Address of token will be used in tournament
     * _startTime : When tournament start
     * _endTime : When tournament end
     * _wallet : Address where collected fee will be forwarded to
     */
    function initialize(
        uint256 _tournamentId,
        address[] calldata _tokens,
        address _registrationToken,
        uint256 _registrationStartTime,
        uint256 _registrationEndTime,
        uint256 _registrationFeeAmount,
        uint256 _pfeeRate,
        uint256 _tfeeRate,
        uint256 _pPenaltyFeeRate,
        uint256 _tPenaltyFeeRate,
        address _eventEmitter
    ) external {
        require(msg.sender == factory, "UNAUTHORIZED");
        require(
            _registrationStartTime > block.timestamp,
            "REGISTRATION START < NOW"
        );
        require(
            _registrationStartTime < _registrationEndTime,
            "REGISTRATION END < START TIME"
        );

        //Setup Role
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(
            DEFAULT_ADMIN_ROLE,
            ITournamentFactory(factory).getpWallet()
        );
        _setupRole(ORGANIZER_ROLE, tx.origin);
        organizer = tx.origin;
        registrationToken = _registrationToken;
        registrationStartTime = _registrationStartTime;
        registrationEndTime = _registrationEndTime;
        registrationFeeAmount = _registrationFeeAmount;
        pfeeRate = _pfeeRate;
        tfeeRate = _tfeeRate;
        pPenaltyFeeRate = _pPenaltyFeeRate;
        tPenaltyFeeRate = _tPenaltyFeeRate;
        tournamentId = _tournamentId;
        tokens = _tokens;
        eventEmitter = _eventEmitter;
    }

    function setEventEmitter(address _eventEmitter)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        eventEmitter = _eventEmitter;
    }

    function setOrganizer(address _newOG) external onlyRole(DEFAULT_ADMIN_ROLE){
        //remove old OG
        revokeRole(ORGANIZER_ROLE, organizer);
        
        //set new OG
        organizer = _newOG;
        
        //grant OG Role to new OG
        grantRole(ORGANIZER_ROLE, _newOG);
        
    }

    //------------------------------------------------------------------------
    //FUNCTION SET TOKENS WILL BE USED IN THIS TOURNAMENT
    //------------------------------------------------------------------------
    function setTokens(address[] calldata _tokens) external {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender) ||
                hasRole(ORGANIZER_ROLE, msg.sender),
            "NO_PERMISSION"
        );
        require(
            _tokens.length > 0,
            "ATLEAST ONE TOKEN MUST BE ADDED"
        );
        require(
            block.timestamp < registrationStartTime ||
                registrationStartTime == 0,
            "UNABLE TO SET TOKENS THIS TIME"
        );
        _validateRemovedTokens(_tokens);
        tokens = _tokens;
    }

    function _validateRemovedTokens(address[] calldata _tokensNew)
        private
        view
    {
        for (uint256 i = 0; i < tokens.length; i++) {
            bool isRemove = true;
            for (uint256 j = 0; j < _tokensNew.length; j++) {
                if (tokens[i] == _tokensNew[j]) {
                    isRemove = false;
                    continue;
                }
            }
            if (isRemove) {
                require(
                    totalTokenSponsored[tokens[i]] <= 0,
                    "UNABLE TO REMOVE TOKEN. THERE IS STILL EXISTING BALANCE."
                );
            }
        }
    }

    //------------------------------------------------------------------------
    //FUNCTION SET REGISTRATION FEE AND REGISTRATION TOKEN
    //------------------------------------------------------------------------
    function setRegistrationFee(
        address _registrationToken,
        uint256 _registrationFeeAmount,
        uint256 _registrationStartTime,
        uint256 _registrationEndTime
    ) external {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender) ||
                hasRole(ORGANIZER_ROLE, msg.sender),
            "NO_PERMISSION"
        );
        require(
            _registrationStartTime > 0,
            "REGISTRATION START MUST BE SET"
        );
        require(
            _registrationStartTime < _registrationEndTime,
            "REGISTRATION START > END"
        );
        if (_registrationToken == address(0) && _registrationFeeAmount == 0) {
            require(
                _validToken(_registrationToken),
                "TOKEN NOT ALLOWED"
            );
        }
        require(
            block.timestamp < registrationStartTime ||
                registrationStartTime == 0,
            "CANNOT SET REGISTRATION FEE THIS TIME"
        );
        registrationToken = _registrationToken;
        registrationFeeAmount = _registrationFeeAmount;
        registrationStartTime = _registrationStartTime;
        registrationEndTime = _registrationEndTime;
    }

    //------------------------
    //FUNCTION REGISTER
    //------------------------
    function register() external payable {
        //add to list registered
        require(
            !registeredAddresses[msg.sender],
            "ALREADY REGISTERED"
        );
        
        registeredAddresses[msg.sender] = true;

        if (registrationFeeAmount == 0) {
            IEventEmitter(eventEmitter).emitRegisterEvent(
                address(this),
                msg.sender,
                registrationFeeAmount
            );
            return;
        }

        //ADD TO TOTAL PRIZE POOL
        totalPrizePool[registrationToken] += registrationFeeAmount;

        //UPDATE CURRENT PRIZE POOL
        currPrizePool[registrationToken] += registrationFeeAmount;

        if (registrationToken == address(0)) {
            require(
                msg.value == registrationFeeAmount,
                "NOT ENOUGH FEE"
            );
        } else {
                IERC20(registrationToken).safeTransferFrom(
                msg.sender,
                address(this),
                registrationFeeAmount
            );
        }

        IEventEmitter(eventEmitter).emitRegisterEvent(
            address(this),
            msg.sender,
            registrationFeeAmount
        );
    }

    //------------------------
    //FUNCTION REFUND
    //------------------------
    function refundMultiple(
        address[] calldata _userAddresses
    ) external {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "NO_PERMISSION"
        );

        require(!isRefunded, "REFUNDED");
        
        isRefunded = true;

        if(registrationFeeAmount > 0)
        {
            for (uint256 i = 0; i < _userAddresses.length; i++) {
                require(
                    registeredAddresses[_userAddresses[i]],
                    "USER_NOT_REGISTERED"
                );
                registeredAddresses[_userAddresses[i]] = false;

                teamTokenRefund[_userAddresses[i]] = true;

                totalPrizePool[registrationToken] -= registrationFeeAmount;
            }
        }
        IEventEmitter(eventEmitter).emitRefundMultipleEvent(
            address(this),
            msg.sender,
            _userAddresses,
            registrationFeeAmount
        );
    }

    //------------------------
    //FUNCTION WITHDRAWTOURNAMENT
    //------------------------
    function withDrawTournament() external {
        require(
            registeredAddresses[msg.sender],
            "USER_NOT_REGISTERED"
        );
        require(
            block.timestamp < registrationEndTime,
            "INVALID_TIME"
        );

        registeredAddresses[msg.sender] = false;

        totalPrizePool[registrationToken] -= registrationFeeAmount;

        teamTokenWithDraw[msg.sender] += registrationFeeAmount;

        IEventEmitter(eventEmitter).emitWithDrawEvent(
            address(this),
            msg.sender
        );
    }

    function claimAfterWithDrawTournament() external {
       require(
            msg.sender == tx.origin,
            "CANNOT_CALL_FROM_CONTRACT"
        );
        require(
            !blackListAddresses[msg.sender],
            "YOU ARE IN BLACK LIST"
        );

        require(
            teamTokenWithDraw[msg.sender] > 0,
            "NO TOKEN TO CLAIM"
        );


        uint256 tokenWithdrawAmount = teamTokenWithDraw[msg.sender];

        uint256 calculatedPlatformFee = (tokenWithdrawAmount * pPenaltyFeeRate) /
            100;
        uint256 calculatedTournamentFee = (tokenWithdrawAmount * pPenaltyFeeRate) /
            100;
        uint256 claimAmount = tokenWithdrawAmount -
            calculatedPlatformFee -
            calculatedTournamentFee;

        if(tokenWithdrawAmount > 0) {
            currPrizePool[registrationToken] -= tokenWithdrawAmount;

            if (registrationToken == address(0)) {
                //Transfer Fee to Platform Wallet
                payable(ITournamentFactory(factory).getpWallet()).transfer(
                    calculatedPlatformFee
                );

                //Transfer Fee to Organizer
                payable(organizer).transfer(calculatedTournamentFee);

                //Transfer to user wallet
                payable(msg.sender).transfer(claimAmount);
            } else {
                // Transfer fee to Fee Wallet
                IERC20(registrationToken).safeTransfer(
                    ITournamentFactory(factory).getpWallet(),
                    calculatedTournamentFee
                );

                // Transfer fee to Organizer
                IERC20(registrationToken).safeTransfer(
                    organizer,
                    calculatedTournamentFee
                );

                //Transfer reward to team captain
                IERC20(registrationToken).safeTransfer(
                    msg.sender,
                    claimAmount
                );
            }
        }

        IEventEmitter(eventEmitter).emitClaimWithDrawEvent(
            address(this),
            msg.sender,
            claimAmount
        );
    }

    //------------------------
    // FUNCTION CLAIM REFUND
    //------------------------
    function claimRefund() external {
        require(
            msg.sender == tx.origin,
            "CANNOT_CALL_FROM_CONTRACT"
        );
        require(
            !blackListAddresses[msg.sender],
            "YOU ARE IN BLACK LIST"
        );
        require(
            teamTokenRefund[msg.sender],
            "NO TOKEN TO CLAIM"
        );

        teamTokenRefund[msg.sender] = false;

        currPrizePool[registrationToken] -= registrationFeeAmount;

        if (registrationToken == address(0)) {
            payable(msg.sender).transfer(registrationFeeAmount);
        } else {
            //Transfer reward to team captain
            IERC20(registrationToken).safeTransfer(msg.sender, registrationFeeAmount);
        }

        IEventEmitter(eventEmitter).emitClaimRefundEvent(
            address(this),
            msg.sender,
            registrationToken,
            registrationFeeAmount
        );
    }

    //------------------------------------------------
    // FUNCTION ADD LIST ADDRESS TO BLACK LIST
    //------------------------------------------------
    function addToBlackListMultiple(address[] calldata _addresses) external {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender) ||
                hasRole(ORGANIZER_ROLE, msg.sender),
            "NO_PERMISSION"
        );
        for (uint256 i = 0; i < _addresses.length; i++) {
            blackListAddresses[_addresses[i]] = true;
        }
    }

    //------------------------------------------------
    // FUNCTION REMOVE USER FROM BLACKLIST
    //------------------------------------------------
    function removeFromBlackList(address _address) external {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender) ||
                hasRole(ORGANIZER_ROLE, msg.sender),
            "NO_PERMISSION"
        );
        blackListAddresses[_address] = false;
    }

    //------------------------------
    // FUNCTION ADD PRIZEPOOL
    //------------------------------
    function addSponsorToPrizePool(address _token, uint256 _amount)
        external
        payable
    {
        require(_amount > 0, "MIN_AMOUNT_UNREACHED");
        require(_validToken(_token), "TOKEN NOT ALLOWED");

        //ADD TO TOTAL PRIZEPOOL
        totalPrizePool[_token] += _amount;
        currPrizePool[_token] += _amount;

        //ADD TO SPONSORED
        totalTokenSponsored[_token] += _amount;

        if (_token == address(0)) {
            require(msg.value == _amount, "NOT ENOUGH AMOUNT");
        } else {
            IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
        }

        IEventEmitter(eventEmitter).emitAddPrizePoolEvent(
            address(this),
            msg.sender,
            _token,
            _amount
        );
    }

    //------------------------------
    // FUNCTION REMOVE FROM PRIZEPOOL
    //------------------------------
    function removeSponsorFromPrizePool(address _token) external {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender) ||
                hasRole(ORGANIZER_ROLE, msg.sender),
            "NO_PERMISSION"
        );
        require(
            msg.sender == tx.origin,
            "CANNOT_CALL_FROM_CONTRACT"
        );

        require(_validToken(_token), "TOKEN NOT ALLOWED");

        require(block.timestamp < registrationStartTime,"UNABLE TO REMOVE SPONSOR THIS TIME");

        uint256 removedAmount = totalTokenSponsored[_token];

        //ADD TO SPONSORED
        totalTokenSponsored[_token] = 0;
        totalPrizePool[_token] -= removedAmount;
        currPrizePool[_token] -= removedAmount;
        if (removedAmount == 0) {
            return;
        }

        if (_token == address(0)) {
            payable(msg.sender).transfer(removedAmount);
        } else {
            IERC20(_token).safeTransfer(msg.sender, removedAmount);
        }

        IEventEmitter(eventEmitter).emitRemovedSponsoredEvent(
            address(this),
            msg.sender,
            _token,
            removedAmount
        );
    }

    //------------------------------
    // FUNCTION DONATE
    //------------------------------
    function donate(address _token, uint256 _amount) external payable {
        require(_amount > 0, "MIN_AMOUNT_UNREACHED");
        require(_validToken(_token), "TOKEN NOT ALLOWED");

        userDonated[msg.sender][_token] += _amount;
        totalTokenDonated[_token] += _amount;
        totalPrizePool[_token] += _amount;
        currPrizePool[_token] += _amount;

        if (_token == address(0)) {
            require(msg.value == _amount, "NOT ENOUGH AMOUNT");
        } else {
            IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
        }

        IEventEmitter(eventEmitter).emitDonatedEvent(
            address(this),
            msg.sender,
            _token,
            _amount
        );
    }

    //---------------------------------------------
    // function withDrawEmergency
    //---------------------------------------------
    function withDrawEmergency() external payable {
        require(
            msg.sender == ITournamentFactory(factory).getpWallet(),
            "NO_PERMISSION"
        );

        for (uint256 i = 0; i < tokens.length; i++) {
            if (currPrizePool[tokens[i]] == 0) {
                continue;
            }
            if (tokens[i] == address(0)) {
                payable(msg.sender).transfer(currPrizePool[tokens[i]]);
                currPrizePool[tokens[i]] = 0;
            } else {
                IERC20(tokens[i]).safeTransfer(
                    msg.sender,
                    currPrizePool[tokens[i]]
                );
                currPrizePool[tokens[i]] = 0;
            }
        }
    }

    //------------------------------
    // function valid Token
    // return true if user can action with tournament
    //------------------------------
    function _validToken(address _token) internal view returns (bool) {
        for (uint256 i = 0; i < tokens.length; i++) {
            if (tokens[i] == _token) return true;
        }
        return false;
    }

    //------------------------------
    // FUNCTION MULTIPLE DISTRIBUTE
    //------------------------------
    function distributeTokensReward(
        address[] calldata _userAddresses,
        address[] calldata _tokenRewards,
        uint256[] calldata _percentages,
        uint256 _remainPercentages,
        bool _needToRefund
    ) external onlyRole(DEFAULT_ADMIN_ROLE){

        require(
            ITournamentFactory(factory).getpWallet() != address(0),
            "PLATFORM WALLET HAS NOT BEEN SETUP"
        );

        if(_needToRefund){
            require(isRefunded || registrationFeeAmount == 0, "NEED_REFUND_BEFORE_DISTRIBUTE");
        }

        require(
            _userAddresses.length == _tokenRewards.length &&
                _userAddresses.length == _percentages.length,
            "ADDRESSES,TOKENS AND AMOUNTs MUST BE SAME LENGTH"
        );

        //set Claim Time
        claimTime =
            block.timestamp +
            ITournamentFactory(factory).getClaimTimeDuration();

        // Distribute to User
        for (uint256 i = 0; i < _userAddresses.length; i++) {

            if (totalPrizePool[_tokenRewards[i]] <= 0) {
                continue;
            } else {
                uint256 rewardAmount = (totalPrizePool[_tokenRewards[i]] *
                    _percentages[i]) / (1e18);

                teamTokenRewards[_userAddresses[i]][
                    _tokenRewards[i]
                ] += rewardAmount;
            }
        }

        if(_remainPercentages > 0) {
            for (uint256 i = 0; i < tokens.length; i++) {
                if (totalPrizePool[tokens[i]] <= 0) {
                    continue;
                } else {
                    uint remainAmount = (totalPrizePool[tokens[i]] * _remainPercentages)/(1e18);
                    uint256 calculatedPlatformFee = (remainAmount * pfeeRate) / 100;

                    uint256 transferAmount = remainAmount -
                    calculatedPlatformFee;

                    //
                    currPrizePool[tokens[i]] -= remainAmount;

                    //clear total Prize pool
                    totalPrizePool[tokens[i]] = 0;
                    if (tokens[i] == address(0)) {
                    // Transfer fee to Fee Wallet
                    payable(ITournamentFactory(factory).getpWallet()).transfer(
                        calculatedPlatformFee
                    );

                    // Transfer fee to Organizer
                    payable(organizer).transfer(transferAmount);

                    } else {
                        // Transfer fee to Fee Wallet
                        IERC20(tokens[i]).safeTransfer(
                            ITournamentFactory(factory).getpWallet(),
                            calculatedPlatformFee
                        );

                        // Transfer fee to Organizer
                        IERC20(tokens[i]).safeTransfer(
                            organizer,
                            transferAmount
                        );
                    }
                }
            }
        }
        
        IEventEmitter(eventEmitter).emitDistributeRewardEvent(
            address(this),
            msg.sender,
            _userAddresses,
            _tokenRewards,
            _percentages,
            _remainPercentages,
            claimTime
        );
    }

    function setClaimTime(uint256 _claimTime)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        claimTime = _claimTime;

        IEventEmitter(eventEmitter).emitSetClaimTimeEvent(
            address(this),
            msg.sender,
            _claimTime
        );
    }

    function claimTokensReward() external {
        require(
            msg.sender == tx.origin,
            "CANNOT_CALL_FROM_CONTRACT"
        );
        require(
            !blackListAddresses[msg.sender],
            "YOU ARE IN BLACK LIST"
        );
        require(
            block.timestamp > claimTime,
            "NOT ALLOWED TO CLAIM THIS TIME"
        );
        require(
            ITournamentFactory(factory).getpWallet() != address(0),
            "PLATFORM WALLET HAS NOT BEEN SETUP"
        );

        uint256[] memory rewardsAmount = new uint256[](tokens.length);
        for (uint256 i = 0; i < tokens.length; i++) {
            uint256 totalAmount = teamTokenRewards[msg.sender][tokens[i]];
            if (totalAmount == 0) {
                continue;
            }
            currPrizePool[tokens[i]] -= totalAmount;

            teamTokenRewards[msg.sender][tokens[i]] = 0;

            uint256 calculatedPlatformFee = (totalAmount * pfeeRate) / 100;

            uint256 calculatedTournamentFee = (totalAmount * tfeeRate) / 100;

            uint256 claimAmount = totalAmount -
                calculatedPlatformFee -
                calculatedTournamentFee;

            rewardsAmount[i] = claimAmount;

            if (tokens[i] == address(0)) {
                // Transfer fee to Fee Wallet
                payable(ITournamentFactory(factory).getpWallet()).transfer(
                    calculatedPlatformFee
                );

                // Transfer fee to Organizer
                payable(organizer).transfer(calculatedTournamentFee);

                // Transfer reward to team captain
                payable(msg.sender).transfer(claimAmount);
            } else {
                // Transfer fee to Fee Wallet
                IERC20(tokens[i]).safeTransfer(
                    ITournamentFactory(factory).getpWallet(),
                    calculatedPlatformFee
                );

                // Transfer fee to Organizer
                IERC20(tokens[i]).safeTransfer(
                    organizer,
                    calculatedTournamentFee
                );

                //Transfer reward to team captain
                IERC20(tokens[i]).safeTransfer(msg.sender, claimAmount);
            }
        }

        IEventEmitter(eventEmitter).emitClaimedEvent(
            address(this),
            msg.sender,
            tokens,
            rewardsAmount
        );
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/cryptography/ECDSA.sol)

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
        InvalidSignatureV
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
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
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
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
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
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
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
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
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