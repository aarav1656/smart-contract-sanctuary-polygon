// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
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
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
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
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
interface IERC20PermitUpgradeable {
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../extensions/draft-IERC20PermitUpgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
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
        IERC20PermitUpgradeable token,
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
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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

pragma solidity ^0.8.13;

import "../layerZero/interfaces/ILayerZeroEndpoint.sol";

interface ICrossChainManager {    
	function finalizeRemote(bytes calldata, bytes calldata, uint256) external;
	function lzEndpoint() external returns(ILayerZeroEndpoint);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface IKommunitasStaking{
    function getUserStakedTokens(address _of) external view returns (uint256);
    function communityStaked() external view returns(uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface IKommunitasStakingV2{
    function getUserStakedTokensBeforeDate(address _of, uint256 _before) external view returns (uint256);
    function staked(uint256) external view returns (uint256,uint256,uint256);
    function lockPeriod(uint256) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface IPublicGovFactory{
    event ProjectCreated(address indexed project, uint index);
    
    function crossChainManager() external  view returns (address);
    function savior() external  view returns (address);
    function keeper() external  view returns (address);
    function saleImplementation() external  view returns (address);
    function operational() external  view returns (address);
    function marketing() external  view returns (address);
    function treasury() external  view returns (address);

    function operationalPercentage_d2() external  view returns (uint64);
    function marketingPercentage_d2() external  view returns (uint64);
    function treasuryPercentage_d2() external  view returns (uint128);
    function gasForDestinationLzReceive() external view returns (uint256);
    
    function allProjectsLength() external view returns(uint);
    function allPaymentsLength() external view returns(uint);
    function allProjects(uint) external view returns(address);
    function allPayments(uint) external view returns(address);
    function getPaymentIndex(address) external view returns(uint);
    function isKnown(address) external view returns(bool);

    function createProject(uint128, uint128, uint128, uint128, uint128, uint128[4] calldata, address, address) external returns (address);
    
    function setPayment(address) external;
    function setSaleImplementation(address) external;
    function setGasForDestinationLzReceive(uint256) external;
    function removePayment(address) external;
    function config(address, address, address, address, address, address) external;
    function setPercentage_d2(uint64, uint64, uint128) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

import "./ILayerZeroUserApplicationConfig.sol";

interface ILayerZeroEndpoint is ILayerZeroUserApplicationConfig {
    // @notice send a LayerZero message to the specified address at a LayerZero endpoint.
    // @param _dstChainId - the destination chain identifier
    // @param _destination - the address on destination chain (in bytes). address length/format may vary by chains
    // @param _payload - a custom bytes payload to send to the destination contract
    // @param _refundAddress - if the source transaction is cheaper than the amount of value passed, refund the additional amount to this address
    // @param _zroPaymentAddress - the address of the ZRO token holder who would pay for the transaction
    // @param _adapterParams - parameters for custom functionality. e.g. receive airdropped native gas from the relayer on destination
    function send(uint16 _dstChainId, bytes calldata _destination, bytes calldata _payload, address payable _refundAddress, address _zroPaymentAddress, bytes calldata _adapterParams) external payable;

    // @notice used by the messaging library to publish verified payload
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source contract (as bytes) at the source chain
    // @param _dstAddress - the address on destination chain
    // @param _nonce - the unbound message ordering nonce
    // @param _gasLimit - the gas limit for external contract execution
    // @param _payload - verified payload to send to the destination contract
    function receivePayload(uint16 _srcChainId, bytes calldata _srcAddress, address _dstAddress, uint64 _nonce, uint _gasLimit, bytes calldata _payload) external;

    // @notice get the inboundNonce of a lzApp from a source chain which could be EVM or non-EVM chain
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source chain contract address
    function getInboundNonce(uint16 _srcChainId, bytes calldata _srcAddress) external view returns (uint64);

    // @notice get the outboundNonce from this source chain which, consequently, is always an EVM
    // @param _srcAddress - the source chain contract address
    function getOutboundNonce(uint16 _dstChainId, address _srcAddress) external view returns (uint64);

    // @notice gets a quote in source native gas, for the amount that send() requires to pay for message delivery
    // @param _dstChainId - the destination chain identifier
    // @param _userApplication - the user app address on this EVM chain
    // @param _payload - the custom message to send over LayerZero
    // @param _payInZRO - if false, user app pays the protocol fee in native token
    // @param _adapterParam - parameters for the adapter service, e.g. send some dust native token to dstChain
    function estimateFees(uint16 _dstChainId, address _userApplication, bytes calldata _payload, bool _payInZRO, bytes calldata _adapterParam) external view returns (uint nativeFee, uint zroFee);

    // @notice get this Endpoint's immutable source identifier
    function getChainId() external view returns (uint16);

    // @notice the interface to retry failed message on this Endpoint destination
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source chain contract address
    // @param _payload - the payload to be retried
    function retryPayload(uint16 _srcChainId, bytes calldata _srcAddress, bytes calldata _payload) external;

    // @notice query if any STORED payload (message blocking) at the endpoint.
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source chain contract address
    function hasStoredPayload(uint16 _srcChainId, bytes calldata _srcAddress) external view returns (bool);

    // @notice query if the _libraryAddress is valid for sending msgs.
    // @param _userApplication - the user app address on this EVM chain
    function getSendLibraryAddress(address _userApplication) external view returns (address);

    // @notice query if the _libraryAddress is valid for receiving msgs.
    // @param _userApplication - the user app address on this EVM chain
    function getReceiveLibraryAddress(address _userApplication) external view returns (address);

    // @notice query if the non-reentrancy guard for send() is on
    // @return true if the guard is on. false otherwise
    function isSendingPayload() external view returns (bool);

    // @notice query if the non-reentrancy guard for receive() is on
    // @return true if the guard is on. false otherwise
    function isReceivingPayload() external view returns (bool);

    // @notice get the configuration of the LayerZero messaging library of the specified version
    // @param _version - messaging library version
    // @param _chainId - the chainId for the pending config change
    // @param _userApplication - the contract address of the user application
    // @param _configType - type of configuration. every messaging library has its own convention.
    function getConfig(uint16 _version, uint16 _chainId, address _userApplication, uint _configType) external view returns (bytes memory);

    // @notice get the send() LayerZero messaging library version
    // @param _userApplication - the contract address of the user application
    function getSendVersion(address _userApplication) external view returns (uint16);

    // @notice get the lzReceive() LayerZero messaging library version
    // @param _userApplication - the contract address of the user application
    function getReceiveVersion(address _userApplication) external view returns (uint16);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

interface ILayerZeroUserApplicationConfig {
    // @notice set the configuration of the LayerZero messaging library of the specified version
    // @param _version - messaging library version
    // @param _chainId - the chainId for the pending config change
    // @param _configType - type of configuration. every messaging library has its own convention.
    // @param _config - configuration in the bytes. can encode arbitrary content.
    function setConfig(uint16 _version, uint16 _chainId, uint _configType, bytes calldata _config) external;

    // @notice set the send() LayerZero messaging library version to _version
    // @param _version - new messaging library version
    function setSendVersion(uint16 _version) external;

    // @notice set the lzReceive() LayerZero messaging library version to _version
    // @param _version - new messaging library version
    function setReceiveVersion(uint16 _version) external;

    // @notice Only when the UA needs to resume the message flow in blocking mode and clear the stored payload
    // @param _srcChainId - the chainId of the source chain
    // @param _srcAddress - the contract address of the source contract at the source chain
    function forceResumeReceive(uint16 _srcChainId, bytes calldata _srcAddress) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "../layerZero/interfaces/ILayerZeroEndpoint.sol";
import "../interfaces/IPublicGovFactory.sol";
import "../interfaces/ICrossChainManager.sol";
import "../utils/AdminProxyManager.sol";
import "../utils/PublicSaleLibrary.sol";
import "../utils/StakingLibrary.sol";

contract PublicGovSale is Initializable, UUPSUpgradeable, PausableUpgradeable, OwnableUpgradeable, AdminProxyManager {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using PublicSaleLibrary for uint128;

    uint16 public immutable dstChainId = 10002; // bsc_testnet
    IPublicGovFactory public factory;

    uint128 public calculation;
    uint128 public feeMoved;
    
    uint128 public price; // in payment decimal
    uint128 public refund_d2; // refund in percent 2 decimal
    
    uint128 public raised; // sale amount get
    uint128 public revenue; // fee amount get

    uint128 public sale;
    uint128 public totalStaked;

    uint128 public minFCFSBuy;
    uint128 public maxFCFSBuy;

    uint128 public minComBuy;
    uint128 public maxComBuy;

    uint128 public whitelistTotalAlloc;
    uint128 public candidateTotalStaked;

    address[] public buyers;
    address[] public whitelists;
    address[] public candidates;

    address public gov;
    IERC20Upgradeable public payment;

    struct Round{
        uint128 start;
        uint128 end;
        uint128 tokenAchieved;
        uint128 fee_d2; // in percent 2 decimal
    }
    
    struct Invoice{
        uint32 buyersIndex;
        uint32 boosterId;
        uint64 boughtAt;
        uint128 received;
        uint128 bought;
        uint128 charged;
    }
    
    mapping(uint32 => Round) public booster;
    mapping(address => Invoice[]) public invoices;
    mapping(address => string) public recipient;
    mapping(address => uint128) public whitelist;
    mapping(address => mapping(uint32 => uint128)) public purchasePerRound;
    mapping(address => bool) public refunded;
    
    mapping(address => uint128) internal userStaked;
    mapping(address => mapping(uint32 => uint128)) internal userAllocation;
    
    event TokenBought(
        uint32 indexed booster,
        address indexed buyer,
        uint128 tokenReceived,
        uint128 buyAmount,
        uint128 feeCharged
    );
    
    /**
     * @dev Initialize project for raise fund
     * @param _calculation Epoch date to start buy allocation calculation
     * @param _start Epoch date to start round 1
     * @param _duration Duration per booster (in seconds)
     * @param _sale Amount token project to sell (based on token decimals of project)
     * @param _price Token project price in payment decimal
     * @param _fee_d2 Fee project percent in each rounds in 2 decimal
     * @param _payment Tokens to raise
     * @param _gov Governance address
     */
    function init(
        uint128 _calculation,
        uint128 _start,
        uint128 _duration,
        uint128 _sale,
        uint128 _price,
        uint128[4] calldata _fee_d2,
        address _payment,
        address _gov
    ) external initializer proxied {
        factory = IPublicGovFactory(_msgSender());

        __UUPSUpgradeable_init();
        __Pausable_init();
        __Ownable_init();
        __AdminProxyManager_init(tx.origin);

        calculation = _calculation;
        sale = _sale;
        price = _price;
        payment = IERC20Upgradeable(_payment);
        gov = _gov;
        gasForDestinationLzReceive = factory.gasForDestinationLzReceive();
        endpoint = ICrossChainManager(factory.crossChainManager()).lzEndpoint();

        uint32 i = 1;
        do {
            if(i==1){
                booster[i].start = _start;
            }else{
                booster[i].start = booster[i-1].end + 1;
            }
            if(i < 4) booster[i].end = booster[i].start + _duration;
            booster[i].fee_d2 = _fee_d2[i-1];

            ++i;
        } while(i <= 4);

        transferOwnership(tx.origin);
    }
    
    function _authorizeUpgrade(address newImplementation) internal virtual override proxied {}

    // **** VIEW AREA ****
    
    /**
     * @dev Get all whitelists length
     */
    function getWhitelistLength() external view returns(uint) {
        return whitelists.length;
    }
    
    /**
     * @dev Get all buyers/participants length
     */
    function getBuyersLength() external view returns(uint) {
        return buyers.length;
    }

    /**
     * @dev Get all candidates length
     */
    function getCandidatesLength() external view returns(uint) {
        return candidates.length;
    }
    
    /**
     * @dev Get total number transactions of buyer
     */
    function getBuyerHistoryLength(address _buyer) external view returns(uint) {
        return invoices[_buyer].length;
    }

    /**
     * @dev Get User Total Staked Kom
     * @param _user User address
     */
    function getUserTotalStaked(address _user) public view returns(uint128){
        return StakingLibrary.getUserTotalStaked(_user, calculation);
    }

    /**
     * @dev Get User Total Staked Allocation
     * @param _user User address
     * @param _boosterRunning Booster progress
     */
    function getUserAllocation(
        address _user,
        uint32 _boosterRunning
    ) public view returns(uint128 userAlloc){
        uint128 saleAmount = sale;
        uint128 userStakedToken = _boosterRunning == 1 ? userStaked[_user] : getUserTotalStaked(_user);

        if(_boosterRunning == 1){
            if(userStakedToken > 0){
                userAlloc = userStakedToken.calcAllocFromKom(
                    candidateTotalStaked,
                    saleAmount - whitelistTotalAlloc
                );
            }

            uint128 whitelistAmount = whitelist[_user];

            if(whitelistAmount > 0) userAlloc += whitelistAmount;
        } else if(_boosterRunning == 2){
            if(uint128(block.timestamp) >= booster[2].start) {
                userAlloc = userStakedToken.calcAllocFromKom(
                    totalStaked,
                    saleAmount - booster[1].tokenAchieved
                );
            }
        } else if(_boosterRunning == 3){
            if(userStakedToken > 0) userAlloc = maxFCFSBuy;
        } else if(_boosterRunning == 4){
            userAlloc = maxComBuy;
        }
    }
    
    /**
     * @dev Get total purchase of a user
     * @param _user User address
     */
    function getTotalPurchase(address _user) public view returns(uint128 total) {
        for(uint32 i=1; i<=4; ++i){
            total += purchasePerRound[_user][i];
        }
    }
    
    /**
     * @dev Get booster running now, 0 = no booster running
     */
    function boosterProgress() public view returns (uint32 running) {
        for(uint32 i=1; i<=4; ++i){
            if( (uint128(block.timestamp) >= booster[i].start && uint128(block.timestamp) <= booster[i].end) ||
                (i == 4 && uint128(block.timestamp) >= booster[i].start)
            ){
                running = i;
                break;
            }
        }
    }
    
    /**
     * @dev Get total sold tokens
     */
    function sold() public view returns(uint128 total) {
        for(uint32 i=1; i<=4; ++i){
            total += booster[i].tokenAchieved;
        }
    }
    
    /**
     * @dev Calculate amount in
     * @param _tokenReceived Token received amount
     * @param _user User address
     * @param _running Booster running
     * @param _boosterPrice Booster running price
     */
    function amountInCalc(
        uint128 _tokenReceived,
        address _user,
        uint32 _running,
        uint128 _boosterPrice
    ) internal view returns(
        uint128 amountInFinal,
        uint128 tokenReceivedFinal
    ) {
        uint128 left = sale - sold();

        if(_tokenReceived > left) _tokenReceived = left;

        amountInFinal = _tokenReceived.calcAmountIn(_boosterPrice);
        
        uint128 alloc;
        if(_running < 3){
            alloc = userAllocation[_user][_running];
        } else if(_running == 3){
            require(minFCFSBuy > 0 && maxFCFSBuy > 0 && _tokenReceived >= minFCFSBuy, "<min");
            alloc = maxFCFSBuy;
        } else if(_running == 4){
            require(minComBuy > 0 && maxComBuy > 0 && _tokenReceived >= minComBuy, "<min");
            alloc = maxComBuy;
        }

        uint128 purchaseThisRound = purchasePerRound[_user][_running];

        if(purchaseThisRound + _tokenReceived > alloc) amountInFinal = (alloc - purchaseThisRound).calcAmountIn(_boosterPrice);

        require(purchaseThisRound < alloc && amountInFinal > 0, "nope");

        tokenReceivedFinal = amountInFinal.calcTokenReceived(_boosterPrice);
    }
    
    // **** MAIN AREA ****

    function isEligible() internal view {
        require((_msgSender() == factory.savior() || _msgSender() == factory.keeper() || _msgSender() == owner()), "??");
    }

    function isSufficient(uint256 _amount) internal view {
        require(payment.balanceOf(address(this)) >= _amount, "less");
    }
    
    function isNotStarted() internal view {
        require(uint128(block.timestamp) < booster[1].start, "started");
    }

    function isCalculated() internal view {
        require(uint128(block.timestamp) >= calculation, "nope");
    }

    function releaseToken(
        address _target,
        uint256 _amount
    ) internal {
        payment.safeTransfer(_target, _amount);
    }


    /**
     * @dev Move raised fund to devAddr/project owner
     */
    function moveFund(
        uint16 _percent_d2,
        bool _devAddr,
        address _target
    ) external {
        isEligible();

        uint amount = raised.calcPercent2Decimal(_percent_d2);

        isSufficient(amount);
        require(refund_d2 == 0, "bad");

        if(_devAddr){
            releaseToken(factory.operational(), amount);
        } else{
            releaseToken(_target, amount);
        }
    }

    /**
     * @dev Move fee to devAddr
     */
    function moveFee() external {
        isEligible();
        
        uint128 amount = revenue;
        uint128 left = amount - feeMoved;

        isSufficient(left);

        require(left > 0, "bad");
        
        feeMoved = amount;
        
        releaseToken(factory.operational(), left.calcPercent2Decimal(factory.operationalPercentage_d2()));
        releaseToken(factory.marketing(), left.calcPercent2Decimal(factory.marketingPercentage_d2()));
        releaseToken(factory.treasury(), left.calcPercent2Decimal(factory.treasuryPercentage_d2()));
    }

    /**
     * @dev Buy token project using token raise
     * @param _amountIn Buy amount
     */
    function buyToken(uint128 _amountIn) external whenNotPaused {
        uint128 amountDebt = _buyToken(_amountIn, _msgSender());
        payment.safeTransferFrom(_msgSender(), address(this), amountDebt);
    }

    function _buyToken(
        uint128 _amountIn,
        address _buyer
    ) public whenNotPaused returns(uint128 amountDebt) {
        uint32 running = boosterProgress();
        require(
            (_msgSender() == address(this) || _msgSender() == factory.crossChainManager()) &&
            running > 0 &&
            targetSale != address(0)
        , "!booster");
        
        if(running == 1){
            require(_setUserAllocation(_buyer, running), "bad");
            require(candidateTotalStaked > 0 && (userStaked[_buyer] > 0 || whitelist[_buyer] > 0), "!eligible");
        } else if(running == 2 || running == 3){
            require(setAllocation(_buyer, running), "bad");
            require(totalStaked > 0 && userStaked[_buyer] > 0, "!eligible");
        }

        uint128 boosterPrice = price;

        (uint128 amountInFinal, uint128 tokenReceivedFinal) = amountInCalc(_amountIn.calcTokenReceived(boosterPrice), _buyer, running, boosterPrice);
        
        uint128 feeCharged = amountInFinal.calcPercent2Decimal(booster[running].fee_d2);

        invoices[_buyer].push(Invoice(setBuyer(_buyer), running, uint64(block.timestamp), tokenReceivedFinal, amountInFinal, feeCharged));
        
        raised += amountInFinal;
        revenue += feeCharged;
        purchasePerRound[_buyer][running] += tokenReceivedFinal;
        booster[running].tokenAchieved += tokenReceivedFinal;

        amountDebt = amountInFinal + feeCharged;

        if(_msgSender() == factory.crossChainManager()){
            remoteRaised += amountInFinal;
            remoteRevenue += feeCharged;
            if(remoteUsers.length == 0 || (remoteUsers.length > 0 && remoteUsersIndex[_buyer] == 0)){
                remoteUsers.push(_buyer);
                remoteUsersAmount.push(amountInFinal);
                remoteUsersFee.push(feeCharged);
                remoteUsersIndex[_buyer] = uint128(remoteUsers.length - 1);
            } else {
                uint128 index = remoteUsersIndex[_buyer];
                remoteUsersAmount[index] += amountInFinal;
                remoteUsersFee[index] += feeCharged;
            }

        }

        emit TokenBought(running, _buyer, tokenReceivedFinal, amountInFinal, feeCharged);
    }

    address public targetSale;
    uint256 internal gasForDestinationLzReceive;
    ILayerZeroEndpoint internal endpoint;

    uint128 internal remoteRaised;
    uint128 internal remoteRevenue;
    address[] internal remoteUsers;
    uint128[] internal remoteUsersAmount;
    uint128[] internal remoteUsersFee;
    mapping(address => uint128) internal remoteUsersIndex;

    function getPayload() internal view returns(bytes memory payload){
        payload = abi.encode(targetSale, remoteRaised, remoteRevenue, remoteUsers, remoteUsersAmount, remoteUsersFee);
    }

    function getAdapterParams() internal view returns(bytes memory adapterParams){
        uint16 version = 1;
        adapterParams = abi.encodePacked(version, gasForDestinationLzReceive);
    }

    /**
     * @dev Estimate cross chain fees
     */
    function estimateFees() public view returns(uint256 fees){
        (fees,) = endpoint.estimateFees(dstChainId, factory.crossChainManager(), getPayload(), false, getAdapterParams());
    }

    function finalizeRemote() external whenPaused {
        ICrossChainManager(factory.crossChainManager()).finalizeRemote(getPayload(), getAdapterParams(), estimateFees());
    }

    /**
     * @dev KOM Team buy some left tokens
     * @param _tokenAmount Token amount to buy
     */
    function teamBuy(uint128 _tokenAmount) external whenNotPaused {
        isEligible();

        uint32 running = boosterProgress();

        require(running > 2, "bad");

        uint32 buyerId = setBuyer(_msgSender());

        uint128 left = sale - sold();
        if(_tokenAmount > left) _tokenAmount = left;

        invoices[_msgSender()].push(Invoice(buyerId, running, uint64(block.timestamp), _tokenAmount, 0, 0));
        
        purchasePerRound[_msgSender()][running] += _tokenAmount;
        booster[running].tokenAchieved += _tokenAmount;
        
        emit TokenBought(running, _msgSender(), _tokenAmount, 0, 0);
    }

    /**
     * @dev Refund payment
     */
    function refund() external {
        _refund(_msgSender(), _msgSender());
    }

    function _refund(
        address _from,
        address _to
    ) internal {
        uint128 _refund_d2 = refund_d2;
        uint256 amount = (uint256(getTotalPurchase(_from)) * uint256(price) * uint256(_refund_d2)) / 1e22; // 1e18 (token decimal) + 1e4 (percent 2 decimal)

        isSufficient(amount);

        require(
            refund_d2 > 0 &&
            amount > 0 &&
            !refunded[_from]
        , "bad");
        
        refunded[_from] = true;

        releaseToken(_to, amount);
    }

    /**
     * @dev Set buyer allocation
     * @param _user User address
     * @param _running Booster running
     */
    function setAllocation(
        address _user,
        uint32 _running
    ) internal returns(bool) {
        require(_setUserTotalStaked(_user), "bad#1");
        require(_setUserAllocation(_user, _running), "bad#2");

        return true;
    }

    /**
     * @dev Set user total KOM staked
     * @param _user User address
     */
    function _setUserTotalStaked(address _user) internal returns(bool) {
        if(userStaked[_user] == 0) userStaked[_user] = getUserTotalStaked(_user);

        return true;
    }

    /**
     * @dev Set user allocation token to buy
     * @param _user User address
     * @param _running Booster running
     */
    function _setUserAllocation(
        address _user,
        uint32 _running
    ) internal returns(bool) {
        if(userAllocation[_user][_running] == 0 && _running < 3) userAllocation[_user][_running] = getUserAllocation(_user, _running);
        
        return true;
    }

    /**
     * @dev Set buyer id
     * @param _user User address
     */
    function setBuyer(address _user) internal returns(uint32 buyerId) {
        if(invoices[_user].length == 0){
            buyers.push(_user);
            buyerId = uint32(buyers.length - 1);
        }else{
            buyerId = invoices[_user][0].buyersIndex;
        }
    }
    
    /**
     * @dev Set recipient address
     * @param _recipient Recipient address
     */
    function setRecipient(string calldata _recipient) external whenNotPaused  {
        require(((sale - sold()).calcAmountIn(price) > 0) && bytes(_recipient).length != 0, "bad");

        recipient[_msgSender()] = _recipient;
    }
    
    /**
     * @dev Set total KOM staked
     */
    function setTotalStaked() external {
        isCalculated();
        require(totalStaked == 0, "bad");

        totalStaked = StakingLibrary.getTotalStaked();
    }

    /**
     * @dev Migrate candidates from gov contract
     * @param _candidates Candidate address
     */
    function migrateCandidates(address[] calldata _candidates) external returns (bool) {
        isNotStarted();
        isCalculated();
        require(_msgSender() == gov, "bad");

        uint128 candidateStaked = candidateTotalStaked;
        for(uint16 i=0; i<_candidates.length; ++i){
            if(userStaked[_candidates[i]] > 0) continue;

            _setUserTotalStaked(_candidates[i]);
            candidateStaked += userStaked[_candidates[i]];
        }

        candidateTotalStaked = candidateStaked;

        candidates = _candidates;

        return true;
    }
    
    // **** ADMIN AREA ****

    function refundAirdrop(
        address _from,
        address _to
    ) external onlyOwner {
        _refund(_from, _to);
    }

    /**
     * @dev Set whitelist allocation token in 6 decimal
     * @param _user User address
     * @param _allocation Token allocation in 6 decimal
     */
    function setWhitelist_d6(
        address[] calldata _user,
        uint128[] calldata _allocation
    ) external onlyOwner {
        require(uint128(block.timestamp) < calculation && _user.length == _allocation.length, "bad");
        
        uint128 whitelistTotal = whitelistTotalAlloc;
        for(uint16 i=0; i<_user.length; ++i){
            if(whitelist[_user[i]] > 0) continue;

            whitelists.push(_user[i]);
            whitelist[_user[i]] = _allocation[i].calcWhitelist6Decimal();
            whitelistTotal += whitelist[_user[i]];
        }

        whitelistTotalAlloc = whitelistTotal;
    }

    /**
     * @dev Update whitelist allocation token in 6 decimal
     * @param _user User address
     * @param _allocation Token allocation in 6 decimal
     */
    function updateWhitelist_d6(
        address[] calldata _user,
        uint128[] calldata _allocation
    ) external onlyOwner {
        isNotStarted();
        require(_user.length == _allocation.length, "bad");

        uint128 whitelistTotal = whitelistTotalAlloc;
        for(uint16 i=0; i<_user.length; ++i){
            if(whitelist[_user[i]] == 0) continue;

            uint128 oldAlloc = whitelist[_user[i]];
            whitelist[_user[i]] = _allocation[i].calcWhitelist6Decimal();
            whitelistTotal = whitelistTotal - oldAlloc + whitelist[_user[i]];
        }

        whitelistTotalAlloc = whitelistTotal;
    }

    /**
     * @dev Set Min & Max in FCFS
     * @param _minMaxFCFSBuy Min and max token to buy
     */
    function setMinMaxFCFS(uint128[2] calldata _minMaxFCFSBuy) external onlyOwner {
        if(boosterProgress() < 3) minFCFSBuy = _minMaxFCFSBuy[0];
        maxFCFSBuy = _minMaxFCFSBuy[1];
    }

    /**
     * @dev Set Min & Max in Community Round
     * @param _minMaxComBuy Min and max token to buy
     */
    function setMinMaxCom(uint128[2] calldata _minMaxComBuy) external onlyOwner {
        if(boosterProgress() < 4) minComBuy = _minMaxComBuy[0];
        maxComBuy = _minMaxComBuy[1];
    }

    /**
     * @dev Set Calculation
     * @param _calculation Epoch date to start buy allocation calculation
     */
    function setCalculation(uint128 _calculation) external onlyOwner {
        require(uint128(block.timestamp) < calculation, "bad");

        calculation = _calculation;
    }

    /**
     * @dev Config sale data
     * @param _payment Tokens to raise
     * @param _start Epoch date to start round 1
     * @param _duration Duration per booster (in seconds)
     * @param _sale Amount token project to sell (based on token decimals of project)
     * @param _price Token project price in payment decimal
     * @param _fee_d2 Fee project percent in each rounds in 2 decimal
     * @param _gov Governance address
     */
    function config(
        address _payment,
        uint128 _start,
        uint128 _duration,
        uint128 _sale,
        uint128 _price,
        uint128[4] calldata _fee_d2,
        address _gov,
        address _targetSale
    ) external onlyOwner {
        isNotStarted();

        payment = IERC20Upgradeable(_payment);
        sale = _sale;
        price = _price;
        gov = _gov;
        targetSale = _targetSale;

        uint32 i = 1;
        do {
            if(i==1){
                booster[i].start = _start;
            }else{
                booster[i].start = booster[i-1].end + 1;
            }
            if(i < 4) booster[i].end = booster[i].start + _duration;
            booster[i].fee_d2 = _fee_d2[i-1];

            ++i;
        } while(i <= 4);
    }

    function setTargetSale(address _targetSale) external onlyOwner {
        targetSale = _targetSale;
    }

    /**
     * @dev Set refund
     * @param _refund_d2 Refund percent in 2 decimal
     */
    function setRefund(uint128 _refund_d2) external onlyOwner {
        refund_d2 = _refund_d2;
    }
    
    /**
     * @dev Toggle buyToken pause
     */
    function togglePause() external onlyOwner {
        if(paused()) {
            _unpause();
        } else {
            _pause();
        }
    }

}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "hardhat-deploy/solc_0.8/proxy/Proxied.sol";

contract AdminProxyManager is Initializable, Proxied {
  function __AdminProxyManager_init(address _sender) internal onlyInitializing {
    __AdminProxyManager_init_unchained(_sender);
  }

  function __AdminProxyManager_init_unchained(address _sender) internal onlyInitializing {
    assembly {
      sstore(0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103, _sender)
    }
  }

  function proxyAdmin() external view virtual returns(address) {
    return _proxyAdmin();
  }

  function transferProxyAdmin(address _newProxyAdmin) external virtual proxied {
    require(_newProxyAdmin != address(0) && _newProxyAdmin != _proxyAdmin(), "bad");

    assembly {
      sstore(0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103, _newProxyAdmin)
    }

  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

library PublicSaleLibrary {
    function calcPercent2Decimal(uint128 _a, uint128 _b) internal pure returns(uint128) {
        return (_a * _b) / 10000;
    }

    function calcAllocFromKom(uint128 _staked, uint128 _totalStaked, uint128 _sale) internal pure returns(uint128){
        return (((_staked * 10**8) / _totalStaked) * _sale) / 10**8;
    }

    function calcTokenReceived(uint128 _amountIn, uint128 _price) internal pure returns(uint128){
        return (_amountIn * 10**18) / _price;
    }

    function calcAmountIn(uint128 _received, uint128 _price) internal pure returns(uint128){
        return (_received * _price) / 10**18;
    }

    function calcWhitelist6Decimal(uint128 _allocation) internal pure returns(uint128){
        return (_allocation * 10**18) / 10**6;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "../interfaces/IKommunitasStaking.sol";
import "../interfaces/IKommunitasStakingV2.sol";

library StakingLibrary {
	IKommunitasStaking public constant stakingV1 = IKommunitasStaking(0x233BA8ab987d1e66702cdbEC914812fBC31D7D47);
	IKommunitasStakingV2 public constant stakingV2 = IKommunitasStakingV2(0xEFB19A429947Bb5D1Ac340C31146d325b4CE90a5);

    /**
     * @dev Get V1 + V2 Staked
     */
    function getTotalStaked() internal view returns(uint128 total){
        uint256 v2;
        for(uint8 i=0; i<3; ++i){
            uint lock = stakingV2.lockPeriod(i);
            (,,uint fetch) = stakingV2.staked(lock);
            v2 += fetch;
        }

        total = uint128(stakingV1.communityStaked()) + uint128(v2);
    }

	/**
     * @dev Get User Total Staked Kom
     * @param _user User address
     */
    function getUserTotalStaked(address _user, uint128 _calculation) internal view returns(uint128){
        uint128 userV1Staked = uint128(stakingV1.getUserStakedTokens(_user));
        uint128 userV2Staked = uint128(stakingV2.getUserStakedTokensBeforeDate(_user, _calculation));
        return userV1Staked + userV2Staked;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract Proxied {
    /// @notice to be used by initialisation / postUpgrade function so that only the proxy's admin can execute them
    /// It also allows these functions to be called inside a contructor
    /// even if the contract is meant to be used without proxy
    modifier proxied() {
        address proxyAdminAddress = _proxyAdmin();
        // With hardhat-deploy proxies
        // the proxyAdminAddress is zero only for the implementation contract
        // if the implementation contract want to be used as a standalone/immutable contract
        // it simply has to execute the `proxied` function
        // This ensure the proxyAdminAddress is never zero post deployment
        // And allow you to keep the same code for both proxied contract and immutable contract
        if (proxyAdminAddress == address(0)) {
            // ensure can not be called twice when used outside of proxy : no admin
            // solhint-disable-next-line security/no-inline-assembly
            assembly {
                sstore(
                    0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103,
                    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
                )
            }
        } else {
            require(msg.sender == proxyAdminAddress);
        }
        _;
    }

    modifier onlyProxyAdmin() {
        require(msg.sender == _proxyAdmin(), "NOT_AUTHORIZED");
        _;
    }

    function _proxyAdmin() internal view returns (address ownerAddress) {
        // solhint-disable-next-line security/no-inline-assembly
        assembly {
            ownerAddress := sload(0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103)
        }
    }
}