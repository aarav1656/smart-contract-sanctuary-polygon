// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface ISLPFP {
    /*
     *  Minting
     */
    function mint(address _to, uint256 _amount) external;

    function mintBatch(
        address[] calldata _accounts,
        uint256[] calldata _amounts
    ) external;

    /*
     *  Base
     */
    function setBaseTokenURI(string calldata _baseTokenURI) external;

    function getBaseTokenURI() external view returns (string memory);

    function getMaxSupply() external pure returns (uint256);

    function getPublicSupply() external pure returns (uint256);

    function getMintedSupply() external view returns (uint256);

    function getBurnedSupply() external view returns (uint256);

    function ownerOfBatch(
        uint256[] calldata _tokenIds
    ) external view returns (address[] memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

abstract contract BaseStorage {
    /*
     *  Enum
     */
    enum AccountType {
        Provider,
        Operator,
        Associator,
        Creator,
        DAO
    }

    enum TokenType {
        ERC721,
        ERC1155
    }

    enum RankType {
        E,
        D,
        C,
        B,
        A,
        S
    }

    enum StoneType {
        E,
        D,
        C,
        B,
        A,
        S,
        Strange
    }

    /*
     *  Event
     */
    event Create(string target, uint64 targetId, uint256 timestamp);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import {ContextUpgradeable} from "../utils/ContextUpgradeable.sol";

import {BaseStorage} from "./BaseStorage.sol";

abstract contract SLBaseUpgradeable is ContextUpgradeable, BaseStorage {
    function emitCreate(string memory _target, uint64 _targetId) internal {
        emit Create(_target, _targetId, block.timestamp);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import {ContextUpgradeable} from "../utils/ContextUpgradeable.sol";
import {Initializable} from "../utils/Initializable.sol";

import {BaseStorage} from "./BaseStorage.sol";
import {RoleAccessError} from "../errors/RoleAccessError.sol";
import {ISLProject} from "../project/ISLProject.sol";

abstract contract SLControllerUpgradeable is
    Initializable,
    ContextUpgradeable,
    RoleAccessError
{
    ISLProject internal projectContract;

    function __SLCotroller_init(
        ISLProject _projectContract
    ) internal onlyInitializing {
        projectContract = _projectContract;
    }

    modifier onlyProviderMaster() {
        _onlyProviderMaster(_msgSender());
        _;
    }

    modifier onlyProvider() {
        _onlyProvider(_msgSender());
        _;
    }

    modifier onlyOperator() {
        _onlyOperator(_msgSender());
        _;
    }

    function _onlyProviderMaster(address _account) private view {
        if (!projectContract.isProviderMaster(_account))
            revert OnlyProviderMaster();
    }

    function _onlyProvider(address _account) private view {
        if (!projectContract.isProvider(_account)) revert OnlyProvider();
    }

    function _onlyOperator(address _account) private view {
        if (!projectContract.isOperator(_account)) revert OnlyOperator();
    }

    function setProjectContract(
        ISLProject _projectContract
    ) external onlyProvider {
        projectContract = _projectContract;
    }

    function getProjectContract() external view returns (address) {
        return address(projectContract);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface PFPOfferingError {
    //////////////
    // Offering //
    //////////////

    error ExceedSupply();
    error InvalidTimestamp();
    error InvalidSupply();
    error InvalidOfferingId();
    error AlreadyStartOffering();

    //////////
    // Mint //
    //////////

    error InvalidArgument();
    error InvalidAddress();
    error InvalidPrice();
    error ExceedMaxAmountPerMint();
    error ExceedAccountMaxSupply();
    error WhitelistSignatureVerifyFailed();
    error DoesNotExistTokenId();

    //////////
    // Base //
    //////////

    error InvalidCollectionId();
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import {RoleAccessError} from "./RoleAccessError.sol";

interface ProjectError is RoleAccessError {
    //////////
    // Role //
    //////////

    error InvalidProvider();
    error InvalidOperator();
    error InvalidDAO();

    //////////////
    // Universe //
    //////////////

    error InvalidUniverseId();

    ////////////////
    // Collection //
    ////////////////

    error InvalidCollectionId();
    error AlreadyExistTokenContract();
    error InvalidTokenContract();
    error InvalidArgument();

    /////////////
    // Royalty //
    /////////////

    error ExceedDenominator();

    /////////////
    // Account //
    /////////////

    error InvalidAccountType();
    error InvalidMintingType();
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface RoleAccessError {
    error OnlyProviderMaster();
    error OnlyProvider();
    error OnlyOperator();
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
    function __ERC1967Upgrade_init() internal onlyInitializing {}

    function __ERC1967Upgrade_init_unchained() internal onlyInitializing {}

    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT =
        0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT =
        0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return
            StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(
            AddressUpgradeable.isContract(newImplementation),
            "ERC1967: new implementation is not a contract"
        );
        StorageSlotUpgradeable
            .getAddressSlot(_IMPLEMENTATION_SLOT)
            .value = newImplementation;
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
            try
                IERC1822ProxiableUpgradeable(newImplementation).proxiableUUID()
            returns (bytes32 slot) {
                require(
                    slot == _IMPLEMENTATION_SLOT,
                    "ERC1967Upgrade: unsupported proxiableUUID"
                );
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
    bytes32 internal constant _ADMIN_SLOT =
        0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

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
        require(
            newAdmin != address(0),
            "ERC1967: new admin is the zero address"
        );
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
    bytes32 internal constant _BEACON_SLOT =
        0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

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
        require(
            AddressUpgradeable.isContract(newBeacon),
            "ERC1967: new beacon is not a contract"
        );
        require(
            AddressUpgradeable.isContract(
                IBeaconUpgradeable(newBeacon).implementation()
            ),
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
            _functionDelegateCall(
                IBeaconUpgradeable(newBeacon).implementation(),
                data
            );
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data)
        private
        returns (bytes memory)
    {
        require(
            AddressUpgradeable.isContract(target),
            "Address: delegate call to non-contract"
        );

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return
            AddressUpgradeable.verifyCallResult(
                success,
                returndata,
                "Address: low-level delegate call failed"
            );
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
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
            (isTopLevelCall && _initialized < 1) ||
                (!AddressUpgradeable.isContract(address(this)) &&
                    _initialized == 1),
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
        require(
            !_initializing && _initialized < version,
            "Initializable: contract is already initialized"
        );
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
abstract contract UUPSUpgradeable is
    Initializable,
    IERC1822ProxiableUpgradeable,
    ERC1967UpgradeUpgradeable
{
    function __UUPSUpgradeable_init() internal onlyInitializing {}

    function __UUPSUpgradeable_init_unchained() internal onlyInitializing {}

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
        require(
            address(this) != __self,
            "Function must be called through delegatecall"
        );
        require(
            _getImplementation() == __self,
            "Function must be called through active proxy"
        );
        _;
    }

    /**
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        require(
            address(this) == __self,
            "UUPSUpgradeable: must not be called through delegatecall"
        );
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
    function proxiableUUID()
        external
        view
        virtual
        override
        notDelegated
        returns (bytes32)
    {
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
    function upgradeToAndCall(address newImplementation, bytes memory data)
        external
        payable
        virtual
        onlyProxy
    {
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
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library CountersUpgradeable {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../StringsUpgradeable.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSAUpgradeable {
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
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", StringsUpgradeable.toString(s.length), s));
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/SafeCast.sol)

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCastUpgradeable {
    /**
     * @dev Returns the downcasted uint248 from uint256, reverting on
     * overflow (when the input is greater than largest uint248).
     *
     * Counterpart to Solidity's `uint248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toUint248(uint256 value) internal pure returns (uint248) {
        require(value <= type(uint248).max, "SafeCast: value doesn't fit in 248 bits");
        return uint248(value);
    }

    /**
     * @dev Returns the downcasted uint240 from uint256, reverting on
     * overflow (when the input is greater than largest uint240).
     *
     * Counterpart to Solidity's `uint240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toUint240(uint256 value) internal pure returns (uint240) {
        require(value <= type(uint240).max, "SafeCast: value doesn't fit in 240 bits");
        return uint240(value);
    }

    /**
     * @dev Returns the downcasted uint232 from uint256, reverting on
     * overflow (when the input is greater than largest uint232).
     *
     * Counterpart to Solidity's `uint232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toUint232(uint256 value) internal pure returns (uint232) {
        require(value <= type(uint232).max, "SafeCast: value doesn't fit in 232 bits");
        return uint232(value);
    }

    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.2._
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint216 from uint256, reverting on
     * overflow (when the input is greater than largest uint216).
     *
     * Counterpart to Solidity's `uint216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toUint216(uint256 value) internal pure returns (uint216) {
        require(value <= type(uint216).max, "SafeCast: value doesn't fit in 216 bits");
        return uint216(value);
    }

    /**
     * @dev Returns the downcasted uint208 from uint256, reverting on
     * overflow (when the input is greater than largest uint208).
     *
     * Counterpart to Solidity's `uint208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toUint208(uint256 value) internal pure returns (uint208) {
        require(value <= type(uint208).max, "SafeCast: value doesn't fit in 208 bits");
        return uint208(value);
    }

    /**
     * @dev Returns the downcasted uint200 from uint256, reverting on
     * overflow (when the input is greater than largest uint200).
     *
     * Counterpart to Solidity's `uint200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toUint200(uint256 value) internal pure returns (uint200) {
        require(value <= type(uint200).max, "SafeCast: value doesn't fit in 200 bits");
        return uint200(value);
    }

    /**
     * @dev Returns the downcasted uint192 from uint256, reverting on
     * overflow (when the input is greater than largest uint192).
     *
     * Counterpart to Solidity's `uint192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toUint192(uint256 value) internal pure returns (uint192) {
        require(value <= type(uint192).max, "SafeCast: value doesn't fit in 192 bits");
        return uint192(value);
    }

    /**
     * @dev Returns the downcasted uint184 from uint256, reverting on
     * overflow (when the input is greater than largest uint184).
     *
     * Counterpart to Solidity's `uint184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toUint184(uint256 value) internal pure returns (uint184) {
        require(value <= type(uint184).max, "SafeCast: value doesn't fit in 184 bits");
        return uint184(value);
    }

    /**
     * @dev Returns the downcasted uint176 from uint256, reverting on
     * overflow (when the input is greater than largest uint176).
     *
     * Counterpart to Solidity's `uint176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toUint176(uint256 value) internal pure returns (uint176) {
        require(value <= type(uint176).max, "SafeCast: value doesn't fit in 176 bits");
        return uint176(value);
    }

    /**
     * @dev Returns the downcasted uint168 from uint256, reverting on
     * overflow (when the input is greater than largest uint168).
     *
     * Counterpart to Solidity's `uint168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toUint168(uint256 value) internal pure returns (uint168) {
        require(value <= type(uint168).max, "SafeCast: value doesn't fit in 168 bits");
        return uint168(value);
    }

    /**
     * @dev Returns the downcasted uint160 from uint256, reverting on
     * overflow (when the input is greater than largest uint160).
     *
     * Counterpart to Solidity's `uint160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toUint160(uint256 value) internal pure returns (uint160) {
        require(value <= type(uint160).max, "SafeCast: value doesn't fit in 160 bits");
        return uint160(value);
    }

    /**
     * @dev Returns the downcasted uint152 from uint256, reverting on
     * overflow (when the input is greater than largest uint152).
     *
     * Counterpart to Solidity's `uint152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toUint152(uint256 value) internal pure returns (uint152) {
        require(value <= type(uint152).max, "SafeCast: value doesn't fit in 152 bits");
        return uint152(value);
    }

    /**
     * @dev Returns the downcasted uint144 from uint256, reverting on
     * overflow (when the input is greater than largest uint144).
     *
     * Counterpart to Solidity's `uint144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toUint144(uint256 value) internal pure returns (uint144) {
        require(value <= type(uint144).max, "SafeCast: value doesn't fit in 144 bits");
        return uint144(value);
    }

    /**
     * @dev Returns the downcasted uint136 from uint256, reverting on
     * overflow (when the input is greater than largest uint136).
     *
     * Counterpart to Solidity's `uint136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toUint136(uint256 value) internal pure returns (uint136) {
        require(value <= type(uint136).max, "SafeCast: value doesn't fit in 136 bits");
        return uint136(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v2.5._
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint120 from uint256, reverting on
     * overflow (when the input is greater than largest uint120).
     *
     * Counterpart to Solidity's `uint120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toUint120(uint256 value) internal pure returns (uint120) {
        require(value <= type(uint120).max, "SafeCast: value doesn't fit in 120 bits");
        return uint120(value);
    }

    /**
     * @dev Returns the downcasted uint112 from uint256, reverting on
     * overflow (when the input is greater than largest uint112).
     *
     * Counterpart to Solidity's `uint112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toUint112(uint256 value) internal pure returns (uint112) {
        require(value <= type(uint112).max, "SafeCast: value doesn't fit in 112 bits");
        return uint112(value);
    }

    /**
     * @dev Returns the downcasted uint104 from uint256, reverting on
     * overflow (when the input is greater than largest uint104).
     *
     * Counterpart to Solidity's `uint104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toUint104(uint256 value) internal pure returns (uint104) {
        require(value <= type(uint104).max, "SafeCast: value doesn't fit in 104 bits");
        return uint104(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.2._
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint88 from uint256, reverting on
     * overflow (when the input is greater than largest uint88).
     *
     * Counterpart to Solidity's `uint88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toUint88(uint256 value) internal pure returns (uint88) {
        require(value <= type(uint88).max, "SafeCast: value doesn't fit in 88 bits");
        return uint88(value);
    }

    /**
     * @dev Returns the downcasted uint80 from uint256, reverting on
     * overflow (when the input is greater than largest uint80).
     *
     * Counterpart to Solidity's `uint80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toUint80(uint256 value) internal pure returns (uint80) {
        require(value <= type(uint80).max, "SafeCast: value doesn't fit in 80 bits");
        return uint80(value);
    }

    /**
     * @dev Returns the downcasted uint72 from uint256, reverting on
     * overflow (when the input is greater than largest uint72).
     *
     * Counterpart to Solidity's `uint72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toUint72(uint256 value) internal pure returns (uint72) {
        require(value <= type(uint72).max, "SafeCast: value doesn't fit in 72 bits");
        return uint72(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v2.5._
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint56 from uint256, reverting on
     * overflow (when the input is greater than largest uint56).
     *
     * Counterpart to Solidity's `uint56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toUint56(uint256 value) internal pure returns (uint56) {
        require(value <= type(uint56).max, "SafeCast: value doesn't fit in 56 bits");
        return uint56(value);
    }

    /**
     * @dev Returns the downcasted uint48 from uint256, reverting on
     * overflow (when the input is greater than largest uint48).
     *
     * Counterpart to Solidity's `uint48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toUint48(uint256 value) internal pure returns (uint48) {
        require(value <= type(uint48).max, "SafeCast: value doesn't fit in 48 bits");
        return uint48(value);
    }

    /**
     * @dev Returns the downcasted uint40 from uint256, reverting on
     * overflow (when the input is greater than largest uint40).
     *
     * Counterpart to Solidity's `uint40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toUint40(uint256 value) internal pure returns (uint40) {
        require(value <= type(uint40).max, "SafeCast: value doesn't fit in 40 bits");
        return uint40(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v2.5._
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint24 from uint256, reverting on
     * overflow (when the input is greater than largest uint24).
     *
     * Counterpart to Solidity's `uint24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toUint24(uint256 value) internal pure returns (uint24) {
        require(value <= type(uint24).max, "SafeCast: value doesn't fit in 24 bits");
        return uint24(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v2.5._
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     *
     * _Available since v2.5._
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     *
     * _Available since v3.0._
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int248 from int256, reverting on
     * overflow (when the input is less than smallest int248 or
     * greater than largest int248).
     *
     * Counterpart to Solidity's `int248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toInt248(int256 value) internal pure returns (int248) {
        require(value >= type(int248).min && value <= type(int248).max, "SafeCast: value doesn't fit in 248 bits");
        return int248(value);
    }

    /**
     * @dev Returns the downcasted int240 from int256, reverting on
     * overflow (when the input is less than smallest int240 or
     * greater than largest int240).
     *
     * Counterpart to Solidity's `int240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toInt240(int256 value) internal pure returns (int240) {
        require(value >= type(int240).min && value <= type(int240).max, "SafeCast: value doesn't fit in 240 bits");
        return int240(value);
    }

    /**
     * @dev Returns the downcasted int232 from int256, reverting on
     * overflow (when the input is less than smallest int232 or
     * greater than largest int232).
     *
     * Counterpart to Solidity's `int232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toInt232(int256 value) internal pure returns (int232) {
        require(value >= type(int232).min && value <= type(int232).max, "SafeCast: value doesn't fit in 232 bits");
        return int232(value);
    }

    /**
     * @dev Returns the downcasted int224 from int256, reverting on
     * overflow (when the input is less than smallest int224 or
     * greater than largest int224).
     *
     * Counterpart to Solidity's `int224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.7._
     */
    function toInt224(int256 value) internal pure returns (int224) {
        require(value >= type(int224).min && value <= type(int224).max, "SafeCast: value doesn't fit in 224 bits");
        return int224(value);
    }

    /**
     * @dev Returns the downcasted int216 from int256, reverting on
     * overflow (when the input is less than smallest int216 or
     * greater than largest int216).
     *
     * Counterpart to Solidity's `int216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toInt216(int256 value) internal pure returns (int216) {
        require(value >= type(int216).min && value <= type(int216).max, "SafeCast: value doesn't fit in 216 bits");
        return int216(value);
    }

    /**
     * @dev Returns the downcasted int208 from int256, reverting on
     * overflow (when the input is less than smallest int208 or
     * greater than largest int208).
     *
     * Counterpart to Solidity's `int208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toInt208(int256 value) internal pure returns (int208) {
        require(value >= type(int208).min && value <= type(int208).max, "SafeCast: value doesn't fit in 208 bits");
        return int208(value);
    }

    /**
     * @dev Returns the downcasted int200 from int256, reverting on
     * overflow (when the input is less than smallest int200 or
     * greater than largest int200).
     *
     * Counterpart to Solidity's `int200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toInt200(int256 value) internal pure returns (int200) {
        require(value >= type(int200).min && value <= type(int200).max, "SafeCast: value doesn't fit in 200 bits");
        return int200(value);
    }

    /**
     * @dev Returns the downcasted int192 from int256, reverting on
     * overflow (when the input is less than smallest int192 or
     * greater than largest int192).
     *
     * Counterpart to Solidity's `int192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toInt192(int256 value) internal pure returns (int192) {
        require(value >= type(int192).min && value <= type(int192).max, "SafeCast: value doesn't fit in 192 bits");
        return int192(value);
    }

    /**
     * @dev Returns the downcasted int184 from int256, reverting on
     * overflow (when the input is less than smallest int184 or
     * greater than largest int184).
     *
     * Counterpart to Solidity's `int184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toInt184(int256 value) internal pure returns (int184) {
        require(value >= type(int184).min && value <= type(int184).max, "SafeCast: value doesn't fit in 184 bits");
        return int184(value);
    }

    /**
     * @dev Returns the downcasted int176 from int256, reverting on
     * overflow (when the input is less than smallest int176 or
     * greater than largest int176).
     *
     * Counterpart to Solidity's `int176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toInt176(int256 value) internal pure returns (int176) {
        require(value >= type(int176).min && value <= type(int176).max, "SafeCast: value doesn't fit in 176 bits");
        return int176(value);
    }

    /**
     * @dev Returns the downcasted int168 from int256, reverting on
     * overflow (when the input is less than smallest int168 or
     * greater than largest int168).
     *
     * Counterpart to Solidity's `int168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toInt168(int256 value) internal pure returns (int168) {
        require(value >= type(int168).min && value <= type(int168).max, "SafeCast: value doesn't fit in 168 bits");
        return int168(value);
    }

    /**
     * @dev Returns the downcasted int160 from int256, reverting on
     * overflow (when the input is less than smallest int160 or
     * greater than largest int160).
     *
     * Counterpart to Solidity's `int160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toInt160(int256 value) internal pure returns (int160) {
        require(value >= type(int160).min && value <= type(int160).max, "SafeCast: value doesn't fit in 160 bits");
        return int160(value);
    }

    /**
     * @dev Returns the downcasted int152 from int256, reverting on
     * overflow (when the input is less than smallest int152 or
     * greater than largest int152).
     *
     * Counterpart to Solidity's `int152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toInt152(int256 value) internal pure returns (int152) {
        require(value >= type(int152).min && value <= type(int152).max, "SafeCast: value doesn't fit in 152 bits");
        return int152(value);
    }

    /**
     * @dev Returns the downcasted int144 from int256, reverting on
     * overflow (when the input is less than smallest int144 or
     * greater than largest int144).
     *
     * Counterpart to Solidity's `int144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toInt144(int256 value) internal pure returns (int144) {
        require(value >= type(int144).min && value <= type(int144).max, "SafeCast: value doesn't fit in 144 bits");
        return int144(value);
    }

    /**
     * @dev Returns the downcasted int136 from int256, reverting on
     * overflow (when the input is less than smallest int136 or
     * greater than largest int136).
     *
     * Counterpart to Solidity's `int136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toInt136(int256 value) internal pure returns (int136) {
        require(value >= type(int136).min && value <= type(int136).max, "SafeCast: value doesn't fit in 136 bits");
        return int136(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= type(int128).min && value <= type(int128).max, "SafeCast: value doesn't fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int120 from int256, reverting on
     * overflow (when the input is less than smallest int120 or
     * greater than largest int120).
     *
     * Counterpart to Solidity's `int120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toInt120(int256 value) internal pure returns (int120) {
        require(value >= type(int120).min && value <= type(int120).max, "SafeCast: value doesn't fit in 120 bits");
        return int120(value);
    }

    /**
     * @dev Returns the downcasted int112 from int256, reverting on
     * overflow (when the input is less than smallest int112 or
     * greater than largest int112).
     *
     * Counterpart to Solidity's `int112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toInt112(int256 value) internal pure returns (int112) {
        require(value >= type(int112).min && value <= type(int112).max, "SafeCast: value doesn't fit in 112 bits");
        return int112(value);
    }

    /**
     * @dev Returns the downcasted int104 from int256, reverting on
     * overflow (when the input is less than smallest int104 or
     * greater than largest int104).
     *
     * Counterpart to Solidity's `int104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toInt104(int256 value) internal pure returns (int104) {
        require(value >= type(int104).min && value <= type(int104).max, "SafeCast: value doesn't fit in 104 bits");
        return int104(value);
    }

    /**
     * @dev Returns the downcasted int96 from int256, reverting on
     * overflow (when the input is less than smallest int96 or
     * greater than largest int96).
     *
     * Counterpart to Solidity's `int96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.7._
     */
    function toInt96(int256 value) internal pure returns (int96) {
        require(value >= type(int96).min && value <= type(int96).max, "SafeCast: value doesn't fit in 96 bits");
        return int96(value);
    }

    /**
     * @dev Returns the downcasted int88 from int256, reverting on
     * overflow (when the input is less than smallest int88 or
     * greater than largest int88).
     *
     * Counterpart to Solidity's `int88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toInt88(int256 value) internal pure returns (int88) {
        require(value >= type(int88).min && value <= type(int88).max, "SafeCast: value doesn't fit in 88 bits");
        return int88(value);
    }

    /**
     * @dev Returns the downcasted int80 from int256, reverting on
     * overflow (when the input is less than smallest int80 or
     * greater than largest int80).
     *
     * Counterpart to Solidity's `int80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toInt80(int256 value) internal pure returns (int80) {
        require(value >= type(int80).min && value <= type(int80).max, "SafeCast: value doesn't fit in 80 bits");
        return int80(value);
    }

    /**
     * @dev Returns the downcasted int72 from int256, reverting on
     * overflow (when the input is less than smallest int72 or
     * greater than largest int72).
     *
     * Counterpart to Solidity's `int72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toInt72(int256 value) internal pure returns (int72) {
        require(value >= type(int72).min && value <= type(int72).max, "SafeCast: value doesn't fit in 72 bits");
        return int72(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= type(int64).min && value <= type(int64).max, "SafeCast: value doesn't fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int56 from int256, reverting on
     * overflow (when the input is less than smallest int56 or
     * greater than largest int56).
     *
     * Counterpart to Solidity's `int56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toInt56(int256 value) internal pure returns (int56) {
        require(value >= type(int56).min && value <= type(int56).max, "SafeCast: value doesn't fit in 56 bits");
        return int56(value);
    }

    /**
     * @dev Returns the downcasted int48 from int256, reverting on
     * overflow (when the input is less than smallest int48 or
     * greater than largest int48).
     *
     * Counterpart to Solidity's `int48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toInt48(int256 value) internal pure returns (int48) {
        require(value >= type(int48).min && value <= type(int48).max, "SafeCast: value doesn't fit in 48 bits");
        return int48(value);
    }

    /**
     * @dev Returns the downcasted int40 from int256, reverting on
     * overflow (when the input is less than smallest int40 or
     * greater than largest int40).
     *
     * Counterpart to Solidity's `int40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toInt40(int256 value) internal pure returns (int40) {
        require(value >= type(int40).min && value <= type(int40).max, "SafeCast: value doesn't fit in 40 bits");
        return int40(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= type(int32).min && value <= type(int32).max, "SafeCast: value doesn't fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int24 from int256, reverting on
     * overflow (when the input is less than smallest int24 or
     * greater than largest int24).
     *
     * Counterpart to Solidity's `int24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toInt24(int256 value) internal pure returns (int24) {
        require(value >= type(int24).min && value <= type(int24).max, "SafeCast: value doesn't fit in 24 bits");
        return int24(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= type(int16).min && value <= type(int16).max, "SafeCast: value doesn't fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= type(int8).min && value <= type(int8).max, "SafeCast: value doesn't fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     *
     * _Available since v3.0._
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableSet.sol)

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
 *
 * [WARNING]
 * ====
 *  Trying to delete such a structure from storage will likely result in data corruption, rendering the structure unusable.
 *  See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 *  In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an array of EnumerableSet.
 * ====
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
        mapping(bytes32 => uint256) _indexes;
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

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

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
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
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

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
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

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
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

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import {PFPOfferingBase} from "./PFPOfferingBase.sol";
import {ISLPFP} from "../collections/PFP/ISLPFP.sol";

interface ISLPFPOffering {
    /*
     *  Public Offering
     */
    function addPublicOffering(
        uint256 _supplyToWhitelist,
        uint256 _supplyToPublic,
        uint256 _accountMaxSupply,
        uint256 _startTimestamp,
        uint256 _whitelistExpirationTimestamp,
        uint256 _endTimestamp,
        uint256 _price
    ) external;

    function setPublicOfferingSupply(
        uint256 _offeringId,
        uint256 _supplyToWhitelist,
        uint256 _supplyToPublic,
        uint256 _accountMaxSupply
    ) external;

    function setPublicOfferingTimestamp(
        uint256 _offeringId,
        uint256 _startTimestamp,
        uint256 _whitelistExpirationTimestamp,
        uint256 _endTimestamp
    ) external;

    /*
     *  Private Offering
     */
    function addPrivateOffering(
        uint256 _supply,
        uint256 _accountMaxSupply,
        uint256 _startTimestamp,
        uint256 _endTimestamp,
        uint256 _price
    ) external;

    function setPrivateOfferingSupply(
        uint256 _offeringId,
        uint256 _supply,
        uint256 _accountMaxSupply
    ) external;

    function setPrivateOfferingTimestamp(
        uint256 _offeringId,
        uint256 _startTimestamp,
        uint256 _endTimestamp
    ) external;

    /*
     *  Offering Common
     */
    function removeOffering(
        PFPOfferingBase.OfferingType _offeringType,
        uint256 _offeringId
    ) external;

    function setOfferingPrice(
        PFPOfferingBase.OfferingType _offeringType,
        uint256 _offeringId,
        uint256 _price
    ) external;

    /*
     *  View
     */
    function isExistOfferingById(
        PFPOfferingBase.OfferingType _offeringType,
        uint256 _offeringId
    ) external view returns (bool);

    function getPublicOfferingById(
        uint256 _offeringId
    ) external view returns (PFPOfferingBase.PublicOffering memory);

    function getPrivateOfferingById(
        uint256 _offeringId
    ) external view returns (PFPOfferingBase.PrivateOffering memory);

    function getPublicOfferingMinted(
        uint256 _offeringId
    )
        external
        view
        returns (uint256 _mintedByWhitelist, uint256 _mintedByPublic);

    function getPrivateOfferingMinted(
        uint256 _offeringId
    ) external view returns (uint256);

    function getCurrentOfferingId(
        PFPOfferingBase.OfferingType _offeringType
    ) external view returns (uint256);

    /*
     *  Airdrop Minting
     */
    function mintOfAirdrop(address _to, uint256 _amount) external;

    function mintOfAirdropBatch(
        address[] calldata _accounts,
        uint256[] calldata _amounts
    ) external;

    /*
     *  Offering Minting
     */
    function mintOfOffering(
        PFPOfferingBase.OfferingType _offeringType,
        uint256 _offeringId,
        bytes calldata _signature
    ) external payable;

    /*
     *  Base
     */
    function setPFPCollectionId(uint256 _PFPCollectionId) external;

    function setMaxAmountPerMint(uint256 _maxAmountPerMint) external;

    function getPFPCollectionId() external view returns (uint256);

    function getMaxAmountPerMint() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import {Unsafe} from "../../utils/Unsafe.sol";
import {CountersUpgradeable} from "../../utils/CountersUpgradeable.sol";
import {EnumerableSetUpgradeable} from "../../utils/EnumerableSetUpgradeable.sol";
import {SafeCastUpgradeable} from "../../utils/SafeCastUpgradeable.sol";
import {ECDSAUpgradeable} from "../../utils/ECDSAUpgradeable.sol";

import {R_R} from "./R_R.sol";
import {ISLPFP} from "../../collections/PFP/ISLPFP.sol";

abstract contract Minting is R_R {
    using Unsafe for uint256;
    using CountersUpgradeable for CountersUpgradeable.Counter;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;
    using SafeCastUpgradeable for uint256;
    using ECDSAUpgradeable for bytes32;

    /*
     *  Airdrop Minting
     */
    function mintOfAirdrop(address _to, uint256 _amount) public onlyOperator {
        ISLPFP PFPContract = ISLPFP(
            projectContract.getTokenContractByCollectionId(PFPCollectionId)
        );

        if (reservedSupply + _amount > PFPContract.getPublicSupply())
            revert ExceedSupply();

        if (_amount > maxAmountPerMint) revert ExceedMaxAmountPerMint();

        uint256 startTokenId = PFPContract.getMintedSupply() + 1;
        PFPContract.mint(_to, _amount);
        emit Minted({
            to: _to,
            startTokenId: startTokenId,
            amount: _amount,
            timestamp: block.timestamp
        });
    }

    function mintOfAirdropBatch(
        address[] calldata _accounts,
        uint256[] calldata _amounts
    ) external onlyOperator {
        if (_accounts.length != _amounts.length) revert InvalidArgument();

        ISLPFP PFPContract = ISLPFP(
            projectContract.getTokenContractByCollectionId(PFPCollectionId)
        );

        uint256 totalAmount;

        uint256 startTokenId = PFPContract.getMintedSupply() + 1;
        for (uint256 i = 0; i < _accounts.length; i = i.increment()) {
            address to = _accounts[i];
            uint256 amount = _amounts[i];

            totalAmount += amount;
            startTokenId += amount;

            emit Minted({
                to: to,
                startTokenId: startTokenId,
                amount: amount,
                timestamp: block.timestamp
            });
        }

        if (reservedSupply + totalAmount > PFPContract.getPublicSupply())
            revert ExceedSupply();

        if (totalAmount > maxAmountPerMint) revert ExceedMaxAmountPerMint();

        PFPContract.mintBatch(_accounts, _amounts);
    }

    /*
     *  Offering Minting
     */
    function mintOfOffering(
        OfferingType _offeringType,
        uint256 _offeringId,
        bytes calldata _signature
    ) external payable {
        address buyer = _msgSender();

        if (buyer == address(0) || buyer == address(this))
            revert InvalidAddress();

        if (!isExistOfferingById(_offeringType, _offeringId))
            revert InvalidOfferingId();

        ISLPFP PFPContract = ISLPFP(
            projectContract.getTokenContractByCollectionId(PFPCollectionId)
        );

        uint16 amount;
        uint256 startTokenId = PFPContract.getMintedSupply() + 1;

        if (_offeringType == OfferingType.Public) {
            PublicOffering memory offering = publicOfferings[_offeringId];

            amount = _checkOfferingAndGetAmount(
                uint256(msg.value),
                offering.price,
                offering.accountMaxSupply,
                accountMintedOfPublicOffering[_offeringId][buyer],
                offering.startTimestamp,
                offering.endTimestamp
            );

            accountMintedOfPublicOffering[_offeringId][buyer] += amount;

            _mintOfPublicOffering(
                PFPContract,
                _offeringId,
                buyer,
                amount,
                _signature
            );
        } else {
            PrivateOffering memory offering = privateOfferings[_offeringId];

            amount = _checkOfferingAndGetAmount(
                uint256(msg.value),
                offering.price,
                offering.accountMaxSupply,
                accountMintedOfPrivateOffering[_offeringId][buyer],
                offering.startTimestamp,
                offering.endTimestamp
            );

            accountMintedOfPrivateOffering[_offeringId][buyer] += amount;

            _mintOfPrivateOffering(
                PFPContract,
                _offeringId,
                buyer,
                amount,
                _signature
            );
        }

        emit Minted({
            to: buyer,
            startTokenId: startTokenId,
            amount: amount,
            timestamp: block.timestamp
        });
    }

    function _checkOfferingAndGetAmount(
        uint256 _buyerPrice,
        uint256 _offeringPrice,
        uint16 _accountMaxSupply,
        uint256 _accountMinted,
        uint32 _startTimestamp,
        uint32 _endTimestamp
    ) private view returns (uint16) {
        uint16 amount;

        // check price
        if (_offeringPrice == 0) {
            if (_buyerPrice != 0) revert InvalidPrice();

            amount = _accountMaxSupply;
        } else {
            if (_buyerPrice % _offeringPrice != 0) revert InvalidPrice();

            amount = (_buyerPrice / _offeringPrice).toUint16();

            if (amount == 0) revert InvalidPrice();
        }

        // check amount
        if (amount > maxAmountPerMint) revert ExceedMaxAmountPerMint();

        // check timestamp
        if (
            block.timestamp < _startTimestamp || _endTimestamp < block.timestamp
        ) revert InvalidTimestamp();

        if (_accountMaxSupply < _accountMinted + amount)
            revert ExceedAccountMaxSupply();

        return amount;
    }

    function _mintOfPublicOffering(
        ISLPFP _PFPContract,
        uint256 _offeringId,
        address _buyer,
        uint16 _amount,
        bytes calldata _signature
    ) private {
        PublicOffering storage offering = publicOfferings[_offeringId];

        bool isWhitelist;
        if (_signature.length > 0) {
            if (
                !_verifyWhitelistSignature(
                    OfferingType.Public,
                    _offeringId,
                    _buyer,
                    _signature
                )
            ) revert WhitelistSignatureVerifyFailed();

            isWhitelist = true;
        }

        // buyer is whitelist and not ended whitelist time
        if (
            isWhitelist &&
            block.timestamp <= offering.whitelistExpirationTimestamp
        ) {
            if (
                offering.supplyToWhitelist <
                offering.mintedByWhitelist + _amount
            ) revert ExceedSupply();

            offering.mintedByWhitelist += _amount;

            // buyer is public and not ended whitelist time
        } else if (block.timestamp <= offering.whitelistExpirationTimestamp) {
            if (offering.supplyToPublic < offering.mintedByPublic + _amount)
                revert ExceedSupply();

            offering.mintedByPublic += _amount;

            // buyer is public and ended whitelist time
        } else {
            uint256 supplyToPublic = offering.supplyToPublic +
                (offering.supplyToWhitelist - offering.mintedByWhitelist);

            if (supplyToPublic < offering.mintedByPublic + _amount)
                revert ExceedSupply();

            offering.mintedByPublic += _amount;
        }

        _PFPContract.mint(_buyer, _amount);
    }

    function _mintOfPrivateOffering(
        ISLPFP _PFPContract,
        uint256 _offeringId,
        address _buyer,
        uint16 _amount,
        bytes calldata _signature
    ) private {
        PrivateOffering storage offering = privateOfferings[_offeringId];

        if (
            !_verifyWhitelistSignature(
                OfferingType.Private,
                _offeringId,
                _buyer,
                _signature
            )
        ) revert WhitelistSignatureVerifyFailed();

        if (offering.supply < offering.minted) revert ExceedSupply();

        offering.minted += _amount;

        _PFPContract.mint(_buyer, _amount);
    }

    function _verifyWhitelistSignature(
        OfferingType _offeringType,
        uint256 _offeringId,
        address _buyer,
        bytes calldata _signature
    ) private view returns (bool) {
        bytes32 data = keccak256(
            abi.encodePacked(_offeringType, _offeringId, _buyer)
        );

        bytes32 signedHash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", data)
        );
        address signer = signedHash.recover(_signature);

        return projectContract.isOperator(signer);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import {CountersUpgradeable} from "../../utils/CountersUpgradeable.sol";
import {SafeCastUpgradeable} from "../../utils/SafeCastUpgradeable.sol";

import {ISLPFPOffering} from "../ISLPFPOffering.sol";
import {PFPOfferingBase} from "../PFPOfferingBase.sol";
import {ISLPFP} from "../../collections/PFP/ISLPFP.sol";

abstract contract Offering is ISLPFPOffering, PFPOfferingBase {
    using CountersUpgradeable for CountersUpgradeable.Counter;
    using SafeCastUpgradeable for uint256;

    /*
     *  Public Offering
     */
    function addPublicOffering(
        uint256 _supplyToWhitelist,
        uint256 _supplyToPublic,
        uint256 _accountMaxSupply,
        uint256 _startTimestamp,
        uint256 _whitelistExpirationTimestamp,
        uint256 _endTimestamp,
        uint256 _price
    ) external onlyOperator {
        uint256 totalSupply = _supplyToWhitelist + _supplyToPublic;

        ISLPFP PFPContract = ISLPFP(
            projectContract.getTokenContractByCollectionId(PFPCollectionId)
        );

        if (reservedSupply + totalSupply > PFPContract.getPublicSupply())
            revert ExceedSupply();

        reservedSupply += totalSupply;

        if (
            !_isValidPublicOfferingTimestamp(
                0,
                _startTimestamp,
                _whitelistExpirationTimestamp,
                _endTimestamp
            )
        ) revert InvalidTimestamp();

        publicOfferingIds.increment();
        uint64 offeringId = publicOfferingIds.current().toUint64();

        publicOfferings[offeringId] = PublicOffering({
            id: offeringId,
            supplyToWhitelist: _supplyToWhitelist.toUint16(),
            supplyToPublic: _supplyToPublic.toUint16(),
            accountMaxSupply: _accountMaxSupply.toUint16(),
            startTimestamp: _startTimestamp.toUint32(),
            whitelistExpirationTimestamp: _whitelistExpirationTimestamp
                .toUint32(),
            endTimestamp: _endTimestamp.toUint32(),
            mintedByWhitelist: 0,
            mintedByPublic: 0,
            price: _price
        });

        emitCreate("PublicOffering", offeringId);
    }

    function setPublicOfferingSupply(
        uint256 _offeringId,
        uint256 _supplyToWhitelist,
        uint256 _supplyToPublic,
        uint256 _accountMaxSupply
    ) external onlyOperator {
        if (!isExistOfferingById(OfferingType.Public, _offeringId))
            revert InvalidOfferingId();

        if (!_isNotStartedOffering(OfferingType.Public, _offeringId))
            revert AlreadyStartOffering();

        PublicOffering storage offering = publicOfferings[_offeringId];

        uint256 beforeTotalSupply = offering.supplyToWhitelist +
            offering.supplyToPublic;
        uint256 totalSupply = _supplyToWhitelist + _supplyToPublic;

        ISLPFP PFPContract = ISLPFP(
            projectContract.getTokenContractByCollectionId(PFPCollectionId)
        );

        if (
            reservedSupply - beforeTotalSupply + totalSupply >
            PFPContract.getPublicSupply()
        ) revert InvalidSupply();

        offering.supplyToWhitelist = _supplyToWhitelist.toUint16();
        offering.supplyToPublic = _supplyToPublic.toUint16();
        offering.accountMaxSupply = _accountMaxSupply.toUint16();
    }

    function setPublicOfferingTimestamp(
        uint256 _offeringId,
        uint256 _startTimestamp,
        uint256 _whitelistExpirationTimestamp,
        uint256 _endTimestamp
    ) external onlyOperator {
        if (!isExistOfferingById(OfferingType.Public, _offeringId))
            revert InvalidOfferingId();

        if (
            !_isValidPublicOfferingTimestamp(
                _offeringId,
                _startTimestamp,
                _whitelistExpirationTimestamp,
                _endTimestamp
            )
        ) revert InvalidTimestamp();

        PublicOffering storage offering = publicOfferings[_offeringId];

        offering.startTimestamp = _startTimestamp.toUint32();
        offering.whitelistExpirationTimestamp = _whitelistExpirationTimestamp
            .toUint32();
        offering.endTimestamp = _endTimestamp.toUint32();
    }

    function _isValidPublicOfferingTimestamp(
        uint256 _offeringId,
        uint256 _startTimestamp,
        uint256 _whitelistExpirationTimestamp,
        uint256 _endTimestamp
    ) private view returns (bool) {
        if (
            _endTimestamp <= _startTimestamp ||
            _endTimestamp < _whitelistExpirationTimestamp ||
            _startTimestamp <= block.timestamp
        ) {
            return false;
        }

        uint256 beforeOfferingId;
        uint256 afterOfferingId;

        if (_offeringId == 0) {
            beforeOfferingId = publicOfferingIds.current();
        } else {
            beforeOfferingId = _offeringId - 1;
            afterOfferingId = _offeringId + 1;
        }

        if (publicOfferings[beforeOfferingId].endTimestamp >= _startTimestamp)
            return false;

        if (
            afterOfferingId != 0 &&
            afterOfferingId <= publicOfferingIds.current()
        ) {
            if (
                publicOfferings[afterOfferingId].startTimestamp <= _endTimestamp
            ) return false;
        }

        return true;
    }

    /*
     *  Private Offering
     */
    function addPrivateOffering(
        uint256 _supply,
        uint256 _accountMaxSupply,
        uint256 _startTimestamp,
        uint256 _endTimestamp,
        uint256 _price
    ) external onlyOperator {
        ISLPFP PFPContract = ISLPFP(
            projectContract.getTokenContractByCollectionId(PFPCollectionId)
        );

        if (reservedSupply + _supply > PFPContract.getPublicSupply())
            revert ExceedSupply();
        reservedSupply += _supply;

        if (_supply % _accountMaxSupply != 0) revert InvalidSupply();

        uint256 whitelistAmount = _supply / _accountMaxSupply;

        if (whitelistAmount == 0) revert InvalidSupply();

        if (
            _endTimestamp <= _startTimestamp ||
            _startTimestamp <= block.timestamp
        ) revert InvalidTimestamp();

        privateOfferingIds.increment();
        uint64 offeringId = privateOfferingIds.current().toUint64();

        privateOfferings[offeringId] = PrivateOffering({
            id: offeringId,
            supply: _supply.toUint16(),
            accountMaxSupply: _accountMaxSupply.toUint16(),
            startTimestamp: _startTimestamp.toUint32(),
            endTimestamp: _endTimestamp.toUint32(),
            minted: 0,
            price: _price
        });

        emitCreate("PrivateOffering", offeringId);
    }

    function setPrivateOfferingSupply(
        uint256 _offeringId,
        uint256 _supply,
        uint256 _accountMaxSupply
    ) external onlyOperator {
        if (!isExistOfferingById(OfferingType.Private, _offeringId))
            revert InvalidOfferingId();

        if (!_isNotStartedOffering(OfferingType.Private, _offeringId))
            revert AlreadyStartOffering();

        PrivateOffering storage offering = privateOfferings[_offeringId];

        uint256 beforeSupply = offering.supply;

        ISLPFP PFPContract = ISLPFP(
            projectContract.getTokenContractByCollectionId(PFPCollectionId)
        );

        if (
            reservedSupply - beforeSupply + _supply >
            PFPContract.getPublicSupply()
        ) revert InvalidSupply();

        if (_supply % _accountMaxSupply != 0) revert InvalidSupply();

        uint256 whitelistAmount = _supply / _accountMaxSupply;

        if (whitelistAmount == 0) revert InvalidSupply();

        offering.supply = _supply.toUint16();
        offering.accountMaxSupply = _accountMaxSupply.toUint16();
    }

    function setPrivateOfferingTimestamp(
        uint256 _offeringId,
        uint256 _startTimestamp,
        uint256 _endTimestamp
    ) external onlyOperator {
        if (!isExistOfferingById(OfferingType.Private, _offeringId))
            revert InvalidOfferingId();

        if (
            _endTimestamp <= _startTimestamp ||
            _startTimestamp <= block.timestamp
        ) revert InvalidTimestamp();

        PrivateOffering storage offering = privateOfferings[_offeringId];

        offering.startTimestamp = _startTimestamp.toUint32();
        offering.endTimestamp = _endTimestamp.toUint32();
    }

    /*
     *  Offering Common
     */
    function removeOffering(
        OfferingType _offeringType,
        uint256 _offeringId
    ) external onlyOperator {
        if (!isExistOfferingById(_offeringType, _offeringId))
            revert InvalidOfferingId();

        if (!_isNotStartedOffering(_offeringType, _offeringId))
            revert AlreadyStartOffering();

        uint256 supply;

        if (_offeringType == OfferingType.Public) {
            PublicOffering storage offering = publicOfferings[_offeringId];

            supply = offering.mintedByWhitelist + offering.mintedByPublic;

            offering.id = 0;
        } else {
            PrivateOffering storage offering = privateOfferings[_offeringId];

            supply = offering.supply;

            offering.id = 0;
        }

        reservedSupply -= supply;
    }

    function setOfferingPrice(
        OfferingType _offeringType,
        uint256 _offeringId,
        uint256 _price
    ) external onlyOperator {
        if (!isExistOfferingById(_offeringType, _offeringId))
            revert InvalidOfferingId();

        if (!_isNotStartedOffering(_offeringType, _offeringId))
            revert AlreadyStartOffering();

        if (_offeringType == OfferingType.Public) {
            publicOfferings[_offeringId].price = _price;
        } else {
            privateOfferings[_offeringId].price = _price;
        }
    }

    function _isNotStartedOffering(
        OfferingType _offeringType,
        uint256 _offeringId
    ) internal view returns (bool) {
        if (_offeringType == OfferingType.Public) {
            PublicOffering memory offering = publicOfferings[_offeringId];

            if (
                block.timestamp < offering.startTimestamp &&
                offering.mintedByWhitelist + offering.mintedByPublic == 0
            ) return true;
        } else {
            PrivateOffering memory offering = privateOfferings[_offeringId];

            if (
                block.timestamp < offering.startTimestamp &&
                offering.supply == 0
            ) return true;
        }

        return false;
    }

    /*
     *  View
     */
    function isExistOfferingById(
        OfferingType _offeringType,
        uint256 _offeringId
    ) public view returns (bool) {
        if (_offeringType == OfferingType.Public) {
            return
                _offeringId != 0 &&
                _offeringId <= publicOfferingIds.current() &&
                publicOfferings[_offeringId].id != 0;
        } else {
            return
                _offeringId != 0 &&
                _offeringId <= privateOfferingIds.current() &&
                privateOfferings[_offeringId].id != 0;
        }
    }

    function getPublicOfferingById(
        uint256 _offeringId
    ) external view returns (PublicOffering memory) {
        if (!isExistOfferingById(OfferingType.Public, _offeringId))
            revert InvalidOfferingId();

        return publicOfferings[_offeringId];
    }

    function getPrivateOfferingById(
        uint256 _offeringId
    ) external view returns (PrivateOffering memory) {
        if (!isExistOfferingById(OfferingType.Private, _offeringId))
            revert InvalidOfferingId();

        return privateOfferings[_offeringId];
    }

    function getPublicOfferingMinted(
        uint256 _offeringId
    )
        external
        view
        returns (uint256 _mintedByWhitelist, uint256 _mintedByPublic)
    {
        if (!isExistOfferingById(OfferingType.Public, _offeringId))
            revert InvalidOfferingId();

        PublicOffering memory offering = publicOfferings[_offeringId];

        _mintedByWhitelist = offering.mintedByWhitelist;
        _mintedByPublic = offering.mintedByPublic;
    }

    function getPrivateOfferingMinted(
        uint256 _offeringId
    ) external view returns (uint256) {
        if (!isExistOfferingById(OfferingType.Private, _offeringId))
            revert InvalidOfferingId();

        return privateOfferings[_offeringId].minted;
    }

    function getCurrentOfferingId(
        OfferingType _offeringType
    ) external view returns (uint256) {
        return
            _offeringType == OfferingType.Public
                ? publicOfferingIds.current()
                : privateOfferingIds.current();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import {Unsafe} from "../../utils/Unsafe.sol";

import {Offering} from "./Offering.sol";

abstract contract R_R is Offering {
    using Unsafe for uint256;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import {CountersUpgradeable} from "../utils/CountersUpgradeable.sol";
import {EnumerableSetUpgradeable} from "../utils/EnumerableSetUpgradeable.sol";

import {SLBaseUpgradeable} from "../core/SLBaseUpgradeable.sol";
import {SLControllerUpgradeable} from "../core/SLControllerUpgradeable.sol";
import {PFPOfferingError} from "../errors/PFPOfferingError.sol";

/// @notice Core storage and event for PFP Offering contract
abstract contract PFPOfferingBase is
    SLBaseUpgradeable,
    SLControllerUpgradeable,
    PFPOfferingError
{
    CountersUpgradeable.Counter internal publicOfferingIds;
    CountersUpgradeable.Counter internal privateOfferingIds;

    // collectionId
    uint256 internal PFPCollectionId;

    uint256 internal reservedSupply;
    uint256 internal maxAmountPerMint;

    /*
     *  Struct
     */
    struct PublicOffering {
        uint64 id;
        uint16 supplyToWhitelist;
        uint16 supplyToPublic;
        uint16 accountMaxSupply;
        uint32 startTimestamp;
        uint32 whitelistExpirationTimestamp;
        uint32 endTimestamp;
        uint16 mintedByWhitelist;
        uint16 mintedByPublic; // 256
        uint256 price;
    }

    // 1등 - 10 개 ->
    struct PrivateOffering {
        uint64 id;
        uint16 supply; // 100
        uint16 accountMaxSupply; // 10 - 10
        uint32 startTimestamp;
        uint32 endTimestamp;
        uint16 minted;
        uint256 price;
    }

    // 랭킹 보상은 에어드랍

    /*
     *  Mapping
     */
    /// @notice publicOfferingId to PublicOffering
    mapping(uint256 => PublicOffering) internal publicOfferings;

    /// @notice privateOfferingId to PrviateOffering
    mapping(uint256 => PrivateOffering) internal privateOfferings;

    /// @notice publicOfferingId to account to minted count
    mapping(uint256 => mapping(address => uint256))
        internal accountMintedOfPublicOffering;

    /// @notice privateOfferingId to account to minted count
    mapping(uint256 => mapping(address => uint256))
        internal accountMintedOfPrivateOffering;

    /*
     *  Enum
     */
    enum OfferingType {
        Public,
        Private
    }

    /*
     *  Event
     */
    event Minted(
        address indexed to,
        uint256 startTokenId,
        uint256 amount,
        uint256 timestamp
    );
}

// PFP 발행량 10,000

// R&R 물량 2000개  - 20%
// provider 1000개 - 10%, creator 500개 - 5%, operator 300개 - 3%, associator 200개 - 2%

// 1년 동안 민팅 없음 - startBlockTimestamp - 6개월마다 500개씩 4번 민팅
// provider 250개, creator 125개, 75개, 50개 // 클레임 & 에어드랍

// 나머지 8000개
// operator 오퍼링 생성 - 시즌 랭커 화이트리스트로 등록 -
// 랭킹 차등 줄 것인지?

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import {UUPSUpgradeable} from "../utils/UUPSUpgradeable.sol";

import {Minting} from "./parts/Minting.sol";
import {ISLProject} from "../project/ISLProject.sol";

contract SLPFPOffering is Minting, UUPSUpgradeable {
    function initialize(
        ISLProject _projectContract,
        uint256 _PFPCollectionId
    ) public initializer {
        __SLCotroller_init(_projectContract);

        PFPCollectionId = _PFPCollectionId;

        maxAmountPerMint = 5000;
    }

    function _authorizeUpgrade(address) internal override onlyProvider {}

    /*
     *  Base
     */
    function setPFPCollectionId(
        uint256 _PFPCollectionId
    ) external onlyOperator {
        if (!projectContract.isActiveCollection(_PFPCollectionId))
            revert InvalidCollectionId();

        TokenType tokenType = projectContract.getCollectionTypeByCollectionId(
            _PFPCollectionId
        );

        if (tokenType != TokenType.ERC721) revert InvalidCollectionId();

        PFPCollectionId = _PFPCollectionId;
    }

    function setMaxAmountPerMint(
        uint256 _maxAmountPerMint
    ) external onlyOperator {
        maxAmountPerMint = _maxAmountPerMint;
    }

    function getPFPCollectionId() external view returns (uint256) {
        return PFPCollectionId;
    }

    function getMaxAmountPerMint() external view returns (uint256) {
        return maxAmountPerMint;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import {BaseStorage} from "../core/BaseStorage.sol";
import {ProjectBase} from "./ProjectBase.sol";
import {ISLRoleWallet} from "../wallet/ISLRoleWallet.sol";
import {IDAOFundWallet} from "../wallet/DAO/IDAOFundWallet.sol";

interface ISLProject {
    /*
     *  Authorization
     */
    function isProviderMaster(address _account) external view returns (bool);

    function isProvider(address _account) external view returns (bool);

    function isOperator(address _account) external view returns (bool);

    /*
     *  Role
     */
    function setProvider(ISLRoleWallet _provider) external;

    // DAO governance
    function setOperator(ISLRoleWallet _operator) external;

    // DAO governance
    function setNextOperator(
        ISLRoleWallet _operator,
        uint32 _expirationTimestamp
    ) external;

    function setDAO(IDAOFundWallet _DAO) external;

    function setAssociator(address _associator) external;

    function getProvider() external view returns (address);

    function getOperator() external view returns (address);

    function getDAO() external view returns (address);

    function getAssociator() external view returns (address);

    /*
     *  Royalty
     */
    function setRoyalty(
        uint32 _providerRate,
        uint32 _operatorRate,
        uint32 _associatorRate,
        uint32 _creatorRate,
        uint32 _DAORate
    ) external;

    function getRoyalty() external view returns (ProjectBase.Royalty memory);

    function getTotalRoyalty() external view returns (uint256);

    /*
     *  Universe
     */
    function addUniverse() external;

    function setUniverseActive(uint256 _universeId, bool _isActive) external;

    function getUniverseId() external view returns (uint256);

    function isExistUniverseById(
        uint256 _universeId
    ) external view returns (bool);

    function isActiveUniverse(uint256 _universeId) external view returns (bool);

    function getUniverseById(
        uint256 _universeId
    ) external view returns (ProjectBase.Universe memory, uint256[] memory);

    function addCollectionOfUniverse(
        uint256 _universeId,
        uint256 _collectionId
    ) external;

    function removeCollectionOfUniverse(
        uint256 _universeId,
        uint256 _collectionId
    ) external;

    /*
     *  Collection
     */
    function addCollection(address _tokenContract, address _creator) external;

    function setCollectionTokenContract(
        uint256 _collectionId,
        address _tokenContract
    ) external;

    function setCollectionCreator(
        uint256 _collectionId,
        address _creator
    ) external;

    function setCollectionActive(
        uint256 _collectionId,
        bool _isActive
    ) external;

    function getCollectionId() external view returns (uint256);

    function isExistCollectionById(
        uint256 _collectionId
    ) external view returns (bool);

    function isExistTokenContract(
        address _tokenContract
    ) external view returns (bool);

    function isActiveCollection(
        uint256 _collectionId
    ) external view returns (bool);

    function getCollectionById(
        uint256 _collectionId
    ) external view returns (ProjectBase.Collection memory);

    function getCollectionIdByToken(
        address _tokenContract
    ) external view returns (uint256);

    function isContainCollectionOfUniverse(
        uint256 _universeId,
        uint256 _collectionId
    ) external view returns (bool);

    function getCollectionIdOfUniverse(
        uint256 _universeId,
        bool _activeFilter
    ) external view returns (uint256[] memory);

    function getCollectionByToken(
        address _tokenContract
    ) external view returns (ProjectBase.Collection memory);

    function getTokenContractByCollectionId(
        uint256 _collectionId
    ) external view returns (address);

    function getCollectionTypeByCollectionId(
        uint256 _collectionId
    ) external view returns (BaseStorage.TokenType);

    /*
     *  Account
     */
    function getAccountsByCollectionId(
        uint256 _collectionId
    ) external view returns (address[5] memory);

    function getAccountByAccountType(
        uint256 _collectionId,
        ProjectBase.AccountType _type
    ) external view returns (address);

    /*
     *  Base
     */
    function getDenominator() external pure returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import {CountersUpgradeable} from "../utils/CountersUpgradeable.sol";
import {EnumerableSetUpgradeable} from "../utils/EnumerableSetUpgradeable.sol";

import {SLBaseUpgradeable} from "../core/SLBaseUpgradeable.sol";
import {ProjectError} from "../errors/ProjectError.sol";
import {ISLRoleWallet} from "../wallet/ISLRoleWallet.sol";
import {IDAOFundWallet} from "../wallet/DAO/IDAOFundWallet.sol";

/// @notice Core storage and event for project contract
abstract contract ProjectBase is SLBaseUpgradeable, ProjectError {
    CountersUpgradeable.Counter internal universeIds;
    CountersUpgradeable.Counter internal collectionIds;

    /// @notice precision 100.00000%
    uint256 internal constant denominator = 100_00000;

    /// @notice operator term of office
    uint32 internal operatorExpirationTimestamp;
    uint32 internal operatorSequence;

    /*
     *  R&R Account
     */
    ISLRoleWallet provider;
    ISLRoleWallet operator;
    IDAOFundWallet DAO;
    address internal associator;

    Royalty internal royalty;

    /*
     *  Struct
     */
    struct Royalty {
        uint32 providerRate;
        uint32 operatorRate;
        uint32 associatorRate;
        uint32 creatorRate;
        uint32 DAORate;
    }

    struct Universe {
        uint64 id;
        uint32 createdTimestamp;
        bool isActive;
    }

    struct Collection {
        uint64 id;
        uint32 createdTimestamp;
        bool isActive;
        address tokenContract;
        address creator;
        TokenType tokenType;
    }

    /*
     *  Mapping
     */
    /// @notice universeId to Universe
    mapping(uint256 => Universe) internal universes;

    /// @notice collectionId to Collection
    mapping(uint256 => Collection) internal collections;

    /// @notice universeId to collectionIds
    mapping(uint256 => EnumerableSetUpgradeable.UintSet)
        internal collectionOfUniverse;

    /// @notice tokenContract to collectionId
    mapping(address => uint256) internal collectionByTokenContract;

    /*
     *  Event
     */
    event SetRoyalty(
        uint256 providerRate,
        uint256 operatorRate,
        uint256 associatorRate,
        uint256 creatorRate,
        uint256 DAORate,
        uint256 timestmap
    );
    event SetProvider(address provider, uint256 timestamp);
    event SetOperator(address operator, uint256 timestamp);
    event SetNextOperator(
        address operator,
        uint256 expirationTimestamp,
        uint256 sequence,
        uint256 timestamp
    );
    event SetAssociator(address associator, uint256 timestamp);
    event SetDAO(address DAO, uint256 timestamp);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "../openzeppelin/upgradeable/utils/ContextUpgradeable.sol";

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "../openzeppelin/upgradeable/utils/CountersUpgradeable.sol";

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "../openzeppelin/upgradeable/utils/cryptography/ECDSAUpgradeable.sol";

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "../openzeppelin/upgradeable/utils/structs/EnumerableSetUpgradeable.sol";

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "../openzeppelin/upgradeable/proxy/utils/Initializable.sol";

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "../openzeppelin/upgradeable/utils/math/SafeCastUpgradeable.sol";

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

library Unsafe {
    function increment(uint256 x) internal pure returns (uint256) {
        unchecked {
            return x + 1;
        }
    }

    function decrement(uint256 x) internal pure returns (uint256) {
        unchecked {
            return x - 1;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "../openzeppelin/upgradeable/proxy/utils/UUPSUpgradeable.sol";

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface IDAOFundWallet {
    /*
     *  Event
     */
    event Deposit(address indexed sender, uint256 amount, uint256 balance);
    event ExecuteTransaction(
        address indexed operator,
        address indexed to,
        uint256 value,
        bytes data
    );

    /*
     *  Error
     */
    error TransactionFailed();
    error OnlyOperator();

    function executeTransaction(
        address _to,
        uint256 _value,
        bytes calldata _data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface ISLRoleWallet {
    /*
     *  Event
     */
    event Deposit(address indexed sender, uint256 amount, uint256 balance);
    event ExecuteTransaction(
        address indexed from,
        address indexed to,
        uint256 value,
        bytes data
    );
    event MasterAdded(address indexed master, uint256 timestamp);
    event MasterRemoved(address indexed master, uint256 timestamp);
    event ManagerAdded(address indexed manager, uint256 timestamp);
    event ManagerRemoved(address indexed manager, uint256 timestamp);

    /*
     *  Error
     */
    error RequiredMaster();
    error TransactionFailed();
    error OnlyMaster();
    error OnlyManager();
    error AlreadyExistAccount();
    error DoesNotExistAccount();

    function executeTransaction(
        address _to,
        uint256 _value,
        bytes calldata _data
    ) external;

    function hasRole(address _account) external view returns (bool);

    /*
     *  Master
     */
    function addMaster(address _master) external;

    function renounceMaster() external;

    function isMaster(address _master) external view returns (bool);

    function getMaster(uint256 _index) external view returns (address);

    function getMasters() external view returns (address[] memory);

    function getMasterCount() external view returns (uint256);

    /*
     *  Manager
     */

    function addManager(address _manager) external;

    function removeManager(address _manager) external;

    function renounceManager() external;

    function isManager(address _manager) external view returns (bool);

    function getManager(uint256 _index) external view returns (address);

    function getManagers() external view returns (address[] memory);

    function getManagerCount() external view returns (uint256);
}