// SPDX-License-Identifier: CovestFinance.V1.0.0

pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/IAdminRouter.sol";
import "./interfaces/INameRegistry.sol";
import "./interfaces/IPolicyManager.sol";
import "./interfaces/IPolicyDetails.sol";
import "./interfaces/ICapitalProvider.sol";

contract Cargo is
	Initializable,
	AccessControlUpgradeable,
	UUPSUpgradeable,
	ReentrancyGuardUpgradeable
{
	bytes32 public constant SUPER_MANAGER_ROLE =
		keccak256("SUPER_MANAGER_ROLE");
	bytes32 public constant PARTNER_ROLE = keccak256("PARTNER_ROLE");
	bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

	/* string(awbNumber) => CargoData */
	mapping(string => CargoData) internal _cargoData;

	/* string(awbNumber) => array(claimId) */
	mapping(string => uint256[]) internal _cargoClaimId;

	/* string(awbNumber) => uint256(redeemId) */
	mapping(string => uint256) internal _cargoRedeemId;

	/* string(policyId => awbNumber) */
	mapping(string => string) internal _cargoDataAWBNumberByPolicyId;

	/* string(awbNumber => policyId) */
	mapping(string => string) internal _cargoDataPolicyIdByAWBNumber;

	/* string(natureOfGoods of the product => count of that product are insured) */
	mapping(string => uint256) internal _cargoNatureOfGoodsCount;

	struct CargoData {
		string awbNumber; // including dash(-) //
		string departureAirport; // airport iataCode such as "HDY" //
		string arrivalAirport; // airport iataCode such as "CEI" //
		string designator; // iata designator code //
		string natureOfGoods;
		uint256 flightNumber; // only number of flightNumber //
		uint256 insuranceValue; // decimals 18 //
		uint256 declareValue; // decimals 18 //
		uint256 dateDeparture; // timestamp //
		uint256 dateArrival; // timestamp //
	}

	event PolicyCreated(string awbNumber, string policyId);
	event PolicyRedeemed(string awbNumber, string policyId);
	event PolicyClaimCanceled(string awbNumber, string policyId);
	event PolicyClaimRequested(string awbNumber, string policyId);

	INameRegistry public NR;
	IAdminRouter public AR;

	string public poolId;

	modifier hasDistributed() {
		require(AR.isPolicyDistributor(poolId, address(this)), "TINAPD");
		_;
	}

	function initialize(address _nameRegistry) public initializer {
		__ReentrancyGuard_init();
		__AccessControl_init();
		__UUPSUpgradeable_init();

		_grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
		_grantRole(SUPER_MANAGER_ROLE, msg.sender);
		_grantRole(MANAGER_ROLE, msg.sender);

		_setNameRegistry(_nameRegistry);
	}

	function setNameRegistry(address _nameRegistry)
		public
		onlyRole(SUPER_MANAGER_ROLE)
	{
		_setNameRegistry(_nameRegistry);
	}

	function _setNameRegistry(address _nameRegistry) internal {
		NR = INameRegistry(_nameRegistry);
		AR = IAdminRouter(NR.getContract("AR"));
		poolId = NR.poolId();
	}

	function _authorizeUpgrade(address newImplementation)
		internal
		override
		onlyRole(DEFAULT_ADMIN_ROLE)
	{}

	function existAirWaybill(string memory _awbNumber)
		public
		view
		returns (bool)
	{
		return (keccak256(bytes(_cargoData[_awbNumber].awbNumber)) ==
			keccak256(bytes(_awbNumber)));
	}

	function buyPolicy(
		CargoData memory _cargoParams,
		IPolicyManager.BuyPolicyParams memory _buyPolicyParams
	) public onlyRole(MANAGER_ROLE) hasDistributed {
		address _policyManager = NR.getContract("PM");
		IERC20 _IERC20 = IERC20(_buyPolicyParams.asset);
		IPolicyManager _IPolicyManager = IPolicyManager(_policyManager);

		IPolicyDetails _IPolicyDetails = IPolicyDetails(NR.getContract("PDS"));

		uint8 _convertDecimals = 18 - _IERC20.decimals();

		require(
			_IERC20.balanceOf(address(this)) >=
				_buyPolicyParams.buyValue / 10**_convertDecimals,
			"IB"
		);

		require(existAirWaybill(_cargoParams.awbNumber) == false, "AWBE");
		require(bytes(_cargoParams.awbNumber).length == 12, "ILAWBN");
		require(bytes(_cargoParams.departureAirport).length == 3, "IIAD");
		require(bytes(_cargoParams.arrivalAirport).length == 3, "IIAA");
		require(bytes(_cargoParams.designator).length == 2, "IID");
		require(
			_IPolicyDetails.existPolicyId(_buyPolicyParams.policyId) == false,
			"PIMBF"
		);

		if (
			_IERC20.allowance(address(this), _policyManager) <
			_buyPolicyParams.buyValue / 10**_convertDecimals
		) {
			_IERC20.approve(
				_policyManager,
				_buyPolicyParams.buyValue / 10**_convertDecimals
			);
		}

		_IPolicyManager.buyPolicy(_buyPolicyParams);

		require(
			_IPolicyDetails.existPolicyId(_buyPolicyParams.policyId) == true,
			"PIMBT"
		);

		_cargoData[_cargoParams.awbNumber] = _cargoParams;

		_cargoNatureOfGoodsCount[_cargoParams.natureOfGoods]++;

		_cargoDataAWBNumberByPolicyId[_buyPolicyParams.policyId] = _cargoParams
			.awbNumber;

		_cargoDataPolicyIdByAWBNumber[_cargoParams.awbNumber] = _buyPolicyParams
			.policyId;

		emit PolicyCreated(_cargoParams.awbNumber, _buyPolicyParams.policyId);
	}

	function claimPolicy(
		string memory _awbNumber,
		ICapitalProvider.ClaimPolicyParams memory _claimPolicyParams
	) public onlyRole(MANAGER_ROLE) hasDistributed returns (uint256 claimId) {
		require(existAirWaybill(_awbNumber) == true, "AWBNE");

		ICapitalProvider _ICapitalProvider = ICapitalProvider(
			NR.getContract("CP")
		);

		require(
			_ICapitalProvider.pendingClaimRequest(
				_cargoDataPolicyIdByAWBNumber[_awbNumber]
			) == 0,
			"PCRZ"
		);

		// _claimPolicyParams.value decimals 18 //

		// _cargoData[_awbNumber].insuranceValue decimals 18 //

		require(
			_cargoData[_awbNumber].insuranceValue <= _claimPolicyParams.value,
			"IV"
		);

		claimId = _ICapitalProvider.policyClaimRequest(_claimPolicyParams);

		_cargoClaimId[_awbNumber].push(claimId);

		emit PolicyClaimRequested(
			_awbNumber,
			_cargoDataPolicyIdByAWBNumber[_awbNumber]
		);
	}

	function cancelClaimPolicy(string memory _awbNumber)
		public
		onlyRole(MANAGER_ROLE)
		hasDistributed
	{
		require(existAirWaybill(_awbNumber) == true, "AWBNE");

		ICapitalProvider _ICapitalProvider = ICapitalProvider(
			NR.getContract("CP")
		);

		require(
			_ICapitalProvider.pendingClaimRequest(
				_cargoDataPolicyIdByAWBNumber[_awbNumber]
			) != 0,
			"PCRNZ"
		);

		require(
			_ICapitalProvider.canCancelClaim(
				_cargoClaimId[_awbNumber][_cargoClaimId[_awbNumber].length - 1]
			) == true,
			"CNCTCI"
		);

		_ICapitalProvider.cancelClaim(
			_cargoClaimId[_awbNumber][_cargoClaimId[_awbNumber].length - 1]
		);

		emit PolicyClaimCanceled(
			_awbNumber,
			_cargoDataPolicyIdByAWBNumber[_awbNumber]
		);
	}

	function redeemPolicy(
		string memory _awbNumber,
		IPolicyManager.RedeemPolicyParams memory _redeemPolicyParams
	) public onlyRole(MANAGER_ROLE) hasDistributed {
		require(existAirWaybill(_awbNumber) == true, "AWBNE");

		IPolicyManager _IPolicyManager = IPolicyManager(NR.getContract("PM"));

		ICapitalProvider _ICapitalProvider = ICapitalProvider(
			NR.getContract("CP")
		);

		require(
			keccak256(bytes(_cargoDataPolicyIdByAWBNumber[_awbNumber])) ==
				keccak256(bytes(_redeemPolicyParams.policyId)),
			"IAWBNBYPIPRPP"
		);

		require(
			_ICapitalProvider.pendingClaimRequest(
				_cargoDataPolicyIdByAWBNumber[_awbNumber]
			) == 0,
			"PCRZ"
		);

		uint256 _redeemId = _IPolicyManager.redeemPolicy(_redeemPolicyParams);

		_cargoRedeemId[_awbNumber] = _redeemId;

		emit PolicyRedeemed(
			_awbNumber,
			_cargoDataPolicyIdByAWBNumber[_awbNumber]
		);
	}

	/* string(awbNumber) => CargoData */
	// mapping(string => CargoData) internal _cargoData;

	function cargo(string memory _awbNumber)
		public
		view
		returns (CargoData memory)
	{
		return _cargoData[_awbNumber];
	}

	/* string(awbNumber) => array(claimId) */
	// mapping(string => uint256[]) internal _cargoClaimId;
	function getClaimIdByAWBNumber(string memory _awbNumber)
		public
		view
		returns (uint256[] memory)
	{
		return _cargoClaimId[_awbNumber];
	}

	/* string(awbNumber) => uint256(redeemId) */
	// mapping(string => uint256) internal _cargoRedeemId;
	function getRedeemIdByAWBNumber(string memory _awbNumber)
		public
		view
		returns (uint256)
	{
		return _cargoRedeemId[_awbNumber];
	}

	/* string(policyId => awbNumber) */
	// mapping(string => string) internal _cargoDataAWBNumberByPolicyId;
	function airWaybill(string memory _policyId)
		public
		view
		returns (string memory)
	{
		return _cargoDataAWBNumberByPolicyId[_policyId];
	}

	/* string(awbNumber => policyId) */
	// mapping(string => string) internal _cargoDataPolicyIdByAWBNumber;
	function policyId(string memory _awbNumber)
		public
		view
		returns (string memory)
	{
		return _cargoDataPolicyIdByAWBNumber[_awbNumber];
	}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

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
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../ERC1967/ERC1967UpgradeUpgradeable.sol";
import "./Initializable.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is Initializable, IERC1822ProxiableUpgradeable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal onlyInitializing {
    }

    function __UUPSUpgradeable_init_unchained() internal onlyInitializing {
    }
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        require(address(this) == __self, "UUPSUpgradeable: must not be called through delegatecall");
        _;
    }

    /**
     * @dev Implementation of the ERC1822 {proxiableUUID} function. This returns the storage slot used by the
     * implementation. It is used to validate that the this implementation remains valid after an upgrade.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy. This is guaranteed by the `notDelegated` modifier.
     */
    function proxiableUUID() external view virtual override notDelegated returns (bytes32) {
        return _IMPLEMENTATION_SLOT;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

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
        _checkRole(role);
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: CovestFinance.V1.0.0

pragma solidity 0.8.17;

interface IERC20 {
	function balanceOf(address owner) external view returns (uint256);

	function allowance(address owner, address spender)
		external
		view
		returns (uint256);

	function approve(address spender, uint256 value) external returns (bool);

	function transfer(address to, uint256 value) external returns (bool);

	function transferFrom(
		address from,
		address to,
		uint256 value
	) external returns (bool);

	function totalSupply() external view returns (uint256);

	function decimals() external view returns (uint8);

	function symbol() external view returns (string memory);

	function name() external view returns (string memory);
}

// SPDX-License-Identifier: CovestFinance.V1.0.0

pragma solidity 0.8.17;

interface IAdminRouter {
	function DEFAULT_ADMIN_ROLE() external view returns (bytes32);

	function MANAGER_ROLE() external view returns (bytes32);

	function SUPER_MANAGER_ROLE() external view returns (bytes32);

	function getAssetSupports(string memory _poolId)
		external
		view
		returns (address[] memory);

	function getAssetSupportsMI(string memory _poolId)
		external
		view
		returns (address);

	function getRoleAdmin(bytes32 role) external view returns (bytes32);

	function grantRole(bytes32 role, address account) external;

	function hasRole(bytes32 role, address account)
		external
		view
		returns (bool);

	function isNameRegistry(string memory _poolId, address _nameRegistry)
		external
		view
		returns (bool);

	function isPolicy(string memory _poolId, address _policy)
		external
		view
		returns (bool);

	function isPolicyDistributor(string memory _poolId, address _distributor)
		external
		view
		returns (bool);

	function isSupportAssets(string memory _poolId, address _currency)
		external
		view
		returns (bool);

	function isSupportAssetsMI(string memory _poolId, address _currency)
		external
		view
		returns (bool);

	function renounceRole(bytes32 role, address account) external;

	function revokeRole(bytes32 role, address account) external;

	function setAssestsMI(
		address _policyDetails,
		address _MI,
		bool _boolean
	) external;

	function setAssets(
		address _policyDetails,
		address[] memory _currency,
		bool[] memory _boolean
	) external;

	function setNameRegistry(address _nameRegistry, bool _boolean) external;

	function setPolicy(address _policy, bool _boolean) external;

	function setPolicyDistributor(
		address _policy,
		address _distributor,
		bool _boolean
	) external;

	function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: CovestFinance.V1.0.0

pragma solidity 0.8.17;

interface INameRegistry {
	struct InitStructerParams {
		address F;
		address RF;
		address UW;
		address CA;
		address PD;
		address CM;
		address PF;
		address RM;
		address S;
		address CP;
		address AR;
		address PM;
		address PDS;
		address SUB;
		address MI;
		address V;
		string poolName;
		string poolId;
	}

	function AR() external view returns (address);

	function MANAGER_ROLE() external view returns (bytes32);

	function PDS() external view returns (address);

	function SUPER_MANAGER_ROLE() external view returns (bytes32);

	function getContract(string memory _contractName)
		external
		view
		returns (address);

	function getContracts(string[] memory _contractsName)
		external
		view
		returns (address[] memory);

	function pause() external;

	function paused() external view returns (bool);

	function poolId() external view returns (string memory);

	function poolName() external view returns (string memory);

	function proxiableUUID() external view returns (bytes32);

	function setContract(string memory _contractName, address _addr) external;

	function setup(address[] memory _contract) external;

	function unpause() external;
}

// SPDX-License-Identifier: CovestFinance.V1.0.0

pragma solidity 0.8.17;

interface IPolicyManager {
	struct BuyPolicyParams {
		address referrer;
		address asset;
		string policyId;
		uint256 buyValue;
		uint256 maxCoverage;
		uint256 coveragePeriodHours;
		uint256 generatedAt;
		uint256 expiresAt;
		uint8 v;
		bytes32 r;
		bytes32 s;
	}

	struct RedeemPolicyParams {
		address asset;
		string policyId;
		uint256 redeemPercentage;
		uint256 generatedAt;
		uint256 expiresAt;
		uint8 v;
		bytes32 r;
		bytes32 s;
	}

	struct verifyBuyCoverParams {
		address user;
		address asset;
		string policyId;
		uint256 buyValue;
		uint256 maxCoverage;
		uint256 coveragePeriodHours;
		uint256 claimPeriodHours;
		uint256 generatedAt;
		uint256 expiresAt;
	}

	struct verifyRedeemCoverParams {
		address user;
		address asset;
		string policyId;
		uint256 redeemPercentage;
		uint256 generatedAt;
		uint256 expiresAt;
	}

	function AR() external view returns (address);

	function CP() external view returns (address);

	function MANAGER_ROLE() external view returns (bytes32);

	function NR() external view returns (address);

	function PDS() external view returns (address);

	function RM() external view returns (address);

	function SUB() external view returns (address);

	function SUPER_MANAGER_ROLE() external view returns (bytes32);

	function V() external view returns (address);

	function buyPolicy(BuyPolicyParams memory _buyPolicyParams) external;

	function decimals() external pure returns (uint8);

	function fundAllocationWeight() external view returns (uint256[] memory);

	function isBlacklistAssetsUser(address _user, address _asset)
		external
		view
		returns (bool);

	function isBlacklistUser(address _user) external view returns (bool);

	function nameRegistry() external view returns (address);

	function poolId() external view returns (string memory);

	function poolName() external view returns (string memory);

	function redeemPolicy(RedeemPolicyParams memory _redeemPolicyParams)
		external
		returns (uint256 redeemId);

	function verifyBuyCover(verifyBuyCoverParams memory _verifyBuyCoverParams)
		external
		view
		returns (bytes32);

	function verifyRedeemCover(
		verifyRedeemCoverParams memory _verifyRedeemCoverParams
	) external view returns (bytes32);
}

// SPDX-License-Identifier: CovestFinance.V1.0.0

pragma solidity 0.8.17;

interface IPolicyDetails {
	struct IssuePolicyParams {
		string policyId;
		address user;
		address asset;
		uint256 buyValue;
		uint256 maxCoverage;
		uint256 coveragePeriodHours;
		address referrer;
		uint256 valueSub;
		uint256 percentSub;
		string orgSub;
	}

	struct PolicyIdData {
		address user;
		address asset;
		address referrer;
		string policyId;
		string orgSubsidized;
		uint256 startDate;
		uint256 untilDate;
		uint256 claimExpires;
		uint256 buyValue;
		uint256 maxCoverage;
		uint256 valueSubsidized;
		uint256 percentSubsidized;
		uint256[] fundAllocationWeight;
		bool isRedeemed;
	}

	struct RedeemData {
		address user;
		uint256 id;
		bool approved;
		uint256 amountRequest;
		uint256[] weightOfThisRequest;
		address signature;
	}

	function AR() external view returns (address);

	function CP() external view returns (address);

	function MANAGER_ROLE() external view returns (bytes32);

	function NR() external view returns (address);

	function RM() external view returns (address);

	function SUB() external view returns (address);

	function SUPER_MANAGER_ROLE() external view returns (bytes32);

	function activePolicies() external view returns (uint256);

	function activePoliciesCoverageValue() external view returns (uint256);

	function activePoliciesUser(address _user) external view returns (uint256);

	function activePoliciesValue() external view returns (uint256);

	function amountRequest(uint256 _redeemId) external view returns (uint256);

	function blacklistAssetsUser(
		address[] memory _user,
		address[] memory _assets,
		bool[] memory _boolean
	) external;

	function decimals() external pure returns (uint8);

	function claimPeriodHours() external pure returns (uint256);

	function existPolicyId(string memory _policyId)
		external
		view
		returns (bool);

	function fundAllocationWeight() external view returns (uint256[] memory);

	function fundAllocationWeightPolicy(string memory _policyId)
		external
		view
		returns (uint256[] memory);

	function isBlacklistAssetsUser(address _user, address _asset)
		external
		view
		returns (bool);

	function isBlacklistUser(address _user) external view returns (bool);

	function isOnlyDistributor() external view returns (bool);

	function isPolicyActive(string memory _policyId)
		external
		view
		returns (bool isActive);

	function isPolicyRedeem(string memory _policyId)
		external
		view
		returns (bool);

	function issuePolicy(IssuePolicyParams memory _issuePolicyParams) external;

	function maxCoveragePolicy(string memory _policyId)
		external
		view
		returns (uint256);

	function policy() external view returns (string[] memory);

	function policyBuyValue(string memory _policyId)
		external
		view
		returns (uint256);

	function policyData(string memory _policyId)
		external
		view
		returns (
			PolicyIdData memory,
			bool isActive,
			bool isRedeem
		);

	function policyUser(address _user) external view returns (string[] memory);

	function poolId() external view returns (string memory);

	function poolName() external view returns (string memory);

	function redeemData(uint256 _redeemId)
		external
		view
		returns (RedeemData memory);

	function redeemIdLength() external view returns (uint256);

	function redeemIdPolicy(string memory _policyId)
		external
		view
		returns (uint256[] memory);

	function redeemIdUser(address _user)
		external
		view
		returns (uint256[] memory);

	function redeemPolicy(string memory _policyId, uint256 _redeemPercentage)
		external
		returns (
			bool,
			string memory,
			uint256
		);

	function setBlacklistUser(address[] memory _user, bool[] memory _boolean)
		external;

	function setFundAllocationWeight(uint256[] memory _fundAllocationWeight)
		external;

	function setOnlyDistributor(bool _boolean) external;

	function totalPolicies() external view returns (uint256);

	function totalPoliciesCoverageValue() external view returns (uint256);

	function totalPoliciesValue() external view returns (uint256);

	function weightRequest(uint256 _redeemId)
		external
		view
		returns (uint256[] memory);

	function whoIsRequest(uint256 _redeemId) external view returns (address);
}

// SPDX-License-Identifier: CovestFinance.V1.0.0

pragma solidity 0.8.17;

import "./IPolicyDetails.sol";

interface ICapitalProvider {
	struct ClaimIdRequestData {
		string proofData;
		string policyId;
		address user;
		address asset;
		uint256 timeout;
		uint256 requestAmount;
		uint256 approveAmount;
		address first;
		bool firstCheckerBool;
		uint256 caSnapshotValue;
		uint256 caSnapshotCount;
		uint256 caSnapshotVoteCount;
		uint256 votingPass;
		uint256 votingFailed;
	}

	struct HistoryOfPolicyIdData {
		address owner;
		address asset;
		uint256 claimPending;
		uint256 claimAmountPaid;
		uint256 claimIdLasted;
	}

	struct ClaimPolicyParams {
		address asset;
		string policyId;
		string ipfsHash;
		uint256 value;
		uint256 generatedAt;
		uint256 expiresAt;
		uint8 v;
		bytes32 r;
		bytes32 s;
	}

	struct VerifyClaimRequestParams {
		address user;
		address asset;
		string policyId;
		string ipfsHash;
		uint256 value;
		uint256 generatedAt;
		uint256 expiresAt;
	}

	function AR() external view returns (address);

	function CA() external view returns (address);

	function MANAGER_ROLE() external view returns (bytes32);

	function NR() external view returns (address);

	function PDS() external view returns (address);

	function S() external view returns (address);

	function SUPER_MANAGER_ROLE() external view returns (bytes32);

	function V() external view returns (address);

	function accessForClaimId(address _user, uint256 _claimId)
		external
		view
		returns (bool haveAccess, bool alreadyVote);

	function caProposalVoting(uint256 _claimId, bool _boolean) external;

	function claimAmountPaid(string memory _policyId)
		external
		view
		returns (uint256);

	function cancelClaim(uint256 _claimId) external;

	function canCancelClaim(uint256 _claimId) external view returns (bool);

	function claimIdData(uint256 _claimId)
		external
		view
		returns (ClaimIdRequestData memory);

	function claimIdLastedUserWithPolicyId(string memory _policyId)
		external
		view
		returns (uint256 claimId);

	function claimIdStatus(uint256 _claimId) external view returns (uint8);

	function claimPolicyDataId(string memory _policyId)
		external
		view
		returns (HistoryOfPolicyIdData memory);

	function countClaimForRequest() external view returns (uint256);

	function existsIpfs(string memory _ipfsHash) external view returns (bool);

	function finalize(uint256 _claimId) external;

	function firstCAVote(
		uint256 _claimId,
		bool _boolean,
		uint256 _valueApprove
	) external;

	function fundInFlow(
		address _caller,
		address _asset,
		string memory _policyId,
		uint256 _value
	) external;

	function fundOutFlow(
		address _caller,
		address _asset,
		string memory _policyId,
		uint256 _value
	) external;

	function getAllClaimStatus(uint8 _status)
		external
		view
		returns (ClaimIdRequestData[] memory, uint256[] memory);

	function pendingClaimRequest(string memory _policyId)
		external
		view
		returns (uint256);

	function percentageWillPassWhenRequestClaim()
		external
		view
		returns (uint256);

	function policyClaimId(string memory _policy)
		external
		view
		returns (uint256[] memory);

	function policyClaimRequest(ClaimPolicyParams memory _claimPolicyParams)
		external
		returns (uint256 claimId);

	function poolId() external view returns (string memory);

	function poolName() external view returns (string memory);

	function reInsuranceFeeAsset(
		address _to,
		address _asset,
		uint256 _value
	) external;

	function reInsuranceFeeNative(address _to, uint256 _value) external;

	function setPassPercentage(uint256 _percentageWillPassClaim) external;

	function totalClaimValuePaid() external view returns (uint256);

	function totalClaimValueReserve() external view returns (uint256);

	function userClaimId(address _user)
		external
		view
		returns (uint256[] memory);

	function verifyClaimRequest(
		VerifyClaimRequestParams memory _verifyClaimRequestParams
	) external view returns (bytes32);

	function withdraw(
		address _to,
		address _asset,
		uint256 _value
	) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822ProxiableUpgradeable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeaconUpgradeable.sol";
import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/StorageSlotUpgradeable.sol";
import "../utils/Initializable.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable {
    function __ERC1967Upgrade_init() internal onlyInitializing {
    }

    function __ERC1967Upgrade_init_unchained() internal onlyInitializing {
    }
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822ProxiableUpgradeable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlotUpgradeable {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }
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
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
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
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
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