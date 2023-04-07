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
// OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)

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
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
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
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
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
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/UUPSUpgradeable.sol)

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
     * implementation. It is used to validate the implementation's compatibility when performing an upgrade.
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
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

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
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
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
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
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
     * @dev Returns the number of values in the set. O(1).
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

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

library Constants {
    // gNFT constants
    uint8 internal constant VOTE_WEIGHT_TOPAZ = 1;
    uint8 internal constant VOTE_WEIGHT_EMERALD = 2;
    uint8 internal constant VOTE_WEIGHT_DIAMOND = 3;

    uint8 internal constant REWARD_WEIGHT_TOPAZ = 1;
    uint8 internal constant REWARD_WEIGHT_EMERALD = 11;
    uint8 internal constant REWARD_WEIGHT_DIAMOND = 120;

    uint8 internal constant LIQUIDITY_FOR_MINTING_TOPAZ = 1; // mul by EXP_1E20
    uint8 internal constant LIQUIDITY_FOR_MINTING_EMERALD = 1; // mul by EXP_1E20
    uint8 internal constant LIQUIDITY_FOR_MINTING_DIAMOND = 1; // mul by EXP_1E20

    uint8 internal constant ACTIVATION_TOPAZ_NOMINATOR = 1;
    uint8 internal constant ACTIVATION_EMERALD_NOMINATOR = 10;
    uint8 internal constant ACTIVATION_DIAMOND_NOMINATOR = 100;

    uint8 internal constant LIQUIDITY_FOR_REWARDS_TOPAZ = 1; // mul by EXP_1E20
    uint8 internal constant LIQUIDITY_FOR_REWARDS_EMERALD = 0; // mul by EXP_1E20
    uint8 internal constant LIQUIDITY_FOR_REWARDS_DIAMOND = 0; // mul by EXP_1E20

    uint8 internal constant REQUIRE_TOPAZES_FOR_TOPAZ = 0;
    uint8 internal constant REQUIRE_TOPAZES_FOR_EMERALD = 10;
    uint8 internal constant REQUIRE_TOPAZES_FOR_DIAMOND = 10;

    uint8 internal constant REQUIRE_EMERALDS_FOR_TOPAZ = 0;
    uint8 internal constant REQUIRE_EMERALDS_FOR_EMERALD = 0;
    uint8 internal constant REQUIRE_EMERALDS_FOR_DIAMOND = 1;

    uint8 internal constant REQUIRE_DIAMONDS_FOR_TOPAZ = 0;
    uint8 internal constant REQUIRE_DIAMONDS_FOR_EMERALD = 0;
    uint8 internal constant REQUIRE_DIAMONDS_FOR_DIAMOND = 0;

    uint8 internal constant SEGMENTS_NUMBER = 12;
    uint256 internal constant REWARD_ACCUMULATING_PERIOD = 365 days;
    uint256 internal constant ACTIVATION_MIN_PRICE = 1000e18;
    uint256 internal constant ACTIVATION_MAX_PRICE = 5000e18;
    uint256 internal constant ACTIVATION_DENOMINATOR = 1;
    uint256 internal constant AIRDROP_DISCOUNT_NOMINATOR = 0;
    uint256 internal constant AIRDROP_DISCOUNT_DENOMINATOR = 1e6;
    uint256 internal constant EXP_ORACLE = 1e18;
    uint256 internal constant EXP_LIQUIDITY = 1e20;
    string internal constant BASE_URI = "https://tonpound.com/api/token-data/metadata/";

    //@notice uint8 parameters packed into bytes constant
    bytes internal constant M = hex"010203010b78010101010a64010000000a0a000001000000";

    // Treasury constants
    uint256 internal constant EXP_REWARD_PER_SHARE = 1e12;
    uint256 internal constant REWARD_PER_SHARE_MULTIPLIER = 1e12;
    uint256 internal constant MAX_RESERVE_BPS = 5e3;
    uint256 internal constant DENOM_BPS = 1e4;

    // Common constants
    uint256 internal constant DEFAULT_DECIMALS = 18;
    bytes32 internal constant DEFAULT_ADMIN_ROLE = 0x00;
    address internal constant DEAD_ADDRESS = 0x000000000000000000000000000000000000dEaD;

    function TYPE_PARAMETERS(uint256 col, uint256 row) internal pure returns (uint8) {
        unchecked {
            return uint8(M[row * 3 + col]);
        }
    }

    enum ParameterType {
        VoteWeight,
        RewardWeight,
        MintingLiquidity,
        ActivationNominator,
        RewardsLiquidity,
        RequiredTopazes,
        RequiredEmeralds,
        RequiredDiamonds
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

/// @title  Interface for Auth contract, which is a part of gNFT token
/// @notice Authorization model is based on AccessControl and Pausable contracts from OpenZeppelin:
///         (https://docs.openzeppelin.com/contracts/4.x/api/access#AccessControl) and
///         (https://docs.openzeppelin.com/contracts/4.x/api/security#Pausable)
///         Blacklisting implemented with BLACKLISTED_ROLE, managed by MANAGER_ROLE
interface IAuth {
    /// @notice Revert reason for unwanted input zero addresses
    error ZeroAddress();

    /// @notice Revert reason for protected functions being called by blacklisted address
    error BlacklistedUser(address account);

    /// @notice             Check for admin role
    /// @param user         User to check for role bearing
    /// @return             True if user has the DEFAULT_ADMIN_ROLE role
    function isAdmin(address user) external view returns (bool);

    /// @notice             Check for not being in blacklist
    /// @param user         User to check for
    /// @return             True if user is not blacklisted
    function isValidUser(address user) external view returns (bool);

    /// @notice             Control function of OpenZeppelin's Pausable contract
    ///                     Restricted to PAUSER_ROLE bearers only
    /// @param newState     New boolean status for affected whenPaused/whenNotPaused functions
    function setPause(bool newState) external;
}

// SPDX-License-Identifier: UNLICENSED

import "./ICToken.sol";

pragma solidity ^0.8.4;

/// @title  Partial interface for Tonpound Comptroller contract
/// @notice Based on Comptroller from Compound Finance with different governance model
///         (https://docs.compound.finance/v2/comptroller/)
///         Modified Comptroller stores gNFT and Treasury addresses
///         Unmodified descriptions are copied from Compound Finance GitHub repo:
///         (https://github.com/compound-finance/compound-protocol/blob/v2.8.1/contracts/Comptroller.sol)
interface IComptroller {
    /// @notice         Returns whether the given account is entered in the given asset
    /// @param account  The address of the account to check
    /// @param market   The market(cToken) to check
    /// @return         True if the account is in the asset, otherwise false
    function checkMembership(address account, address market) external view returns (bool);

    /// @notice         Claim all rewards accrued by the holders
    /// @param holders  The addresses to claim for
    /// @param markets  The list of markets to claim in
    /// @param bor      Whether or not to claim rewards earned by borrowing
    /// @param sup      Whether or not to claim rewards earned by supplying
    function claimComp(
        address[] memory holders,
        address[] memory markets,
        bool bor,
        bool sup
    ) external;

    /// @notice         Returns rewards accrued but not yet transferred to the user
    /// @param account  User address to get accrued rewards for
    /// @return         Value stored in compAccrued[account] mapping
    function compAccrued(address account) external view returns (uint256);

    /// @notice         Add assets to be included in account liquidity calculation
    /// @param markets  The list of addresses of the markets to be enabled
    /// @return         Success indicator for whether each corresponding market was entered
    function enterMarkets(address[] memory markets) external returns (uint256[] memory);

    /// @notice             Determine the current account liquidity wrt collateral requirements
    /// @return err         (possible error code (semi-opaque)
    ///         liquidity   account liquidity in excess of collateral requirements
    ///         shortfall   account shortfall below collateral requirements)
    function getAccountLiquidity(
        address account
    ) external view returns (uint256 err, uint256 liquidity, uint256 shortfall);

    /// @notice Return all of the markets
    /// @dev    The automatic getter may be used to access an individual market.
    /// @return The list of market addresses
    function getAllMarkets() external view returns (address[] memory);

    /// @notice         Returns the assets an account has entered
    /// @param  account The address of the account to pull assets for
    /// @return         A dynamic list with the assets the account has entered
    function getAssetsIn(address account) external view returns (address[] memory);

    /// @notice Return the address of the TPI token
    /// @return The address of TPI
    function getCompAddress() external view returns (address);

    /// @notice Return the address of the governance gNFT token
    /// @return The address of gNFT
    function gNFT() external view returns (address);

    /// @notice View function to read 'markets' mapping separately
    /// @return Market structure without nested 'accountMembership'
    function markets(address market) external view returns (Market calldata);

    /// @notice Return the address of the system Oracle
    /// @return The address of Oracle
    function oracle() external view returns (address);

    /// @notice Return the address of the Treasury
    /// @return The address of Treasury
    function treasury() external view returns (address);

    struct Market {
        bool isListed;
        uint256 collateralFactorMantissa;
        bool isComped;
    }
}

// SPDX-License-Identifier: UNLICENSED

import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";

pragma solidity ^0.8.4;

/// @title  Partial interface for Tonpound cToken market
/// @notice Extension of IERC20 standard interface from OpenZeppelin
///         (https://docs.openzeppelin.com/contracts/4.x/api/token/erc20#IERC20)
interface ICToken is IERC20MetadataUpgradeable {
    /**
     * @notice Accrues interest and reduces reserves by transferring to admin
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function _reduceReserves() external returns (uint256);

    /**
     * @notice Block number that interest was last accrued at
     */
    function accrualBlockNumber() external view returns(uint256);

    /**
     * @notice Get the underlying balance of the `owner`
     * @dev This also accrues interest in a transaction
     * @param owner The address of the account to query
     * @return The amount of underlying owned by `owner`
     */
    function balanceOfUnderlying(address owner) external returns (uint256);

    /**
     * @notice Contract which oversees inter-cToken operations
     */
    function comptroller() external returns (address);

    /**
     * @notice Accrue interest then return the up-to-date exchange rate
     * @return Calculated exchange rate scaled by 1e18
     */
    function exchangeRateCurrent() external returns (uint256);

    /**
     * @notice Calculates the exchange rate from the underlying to the CToken
     * @dev This function does not accrue interest before calculating the exchange rate
     * @return Calculated exchange rate scaled by 1e18
     */
    function exchangeRateStored() external view returns (uint256);

    /**
     * @notice Get cash balance of this cToken in the underlying asset
     * @return The quantity of underlying asset owned by this contract
     */
    function getCash() external view returns (uint256);

    /**
     * @notice Model which tells what the current interest rate should be
     */
    function interestRateModel() external view returns (address);

    /**
     * @notice Fraction of interest currently set aside for reserves
     */
    function reserveFactorMantissa() external view returns (uint256);

    /**
     * @notice Total amount of outstanding borrows of the underlying in this market
     */
    function totalBorrows() external view returns (uint256);

    /**
     * @notice Total amount of reserves of the underlying held in this market
     */
    function totalReserves() external view returns (uint256);

    /**
     * @notice Underlying asset for this CToken
     */
    function underlying() external view returns (address);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

import "./ISegmentManagement.sol";

/// @title  gNFT governance token for Tonpound protocol
/// @notice Built on ERC721Votes extension from OpenZeppelin Upgradeable library
///         (https://docs.openzeppelin.com/contracts/4.x/api/token/erc721#ERC721Votes)
///         Supports Permit approvals (see IERC721Permit.sol) and Multicall
///         (https://docs.openzeppelin.com/contracts/4.x/api/utils#Multicall)
interface IgNFT {
    /// @notice Revert reason for unauthorized access to protected functions
    error Auth();

    /// @notice Revert reason for protected functions being called by blacklisted address
    error BlacklistedUser(address account);

    /// @notice Revert reason for accessing protected functions during pause
    error Paused();

    /// @notice Revert reason for unwanted input zero addresses
    error ZeroAddress();

    /// @notice              Emitted during minting
    /// @param tokenId       tokenId of minted token
    /// @param data          Metadata of minted token
    event MintData(uint256 tokenId, TokenData data);

    /// @notice              Emitted during slot0 of metadata updating
    /// @param tokenId       tokenId of updated token
    /// @param data          New Slot0 of metadata of updated token
    event UpdatedTokenDataSlot0(uint256 tokenId, Slot0 data);

    /// @notice              Emitted during slot1 of metadata updating
    /// @param tokenId       tokenId of updated token
    /// @param data          New Slot1 of metadata of updated token
    event UpdatedTokenDataSlot1(uint256 tokenId, Slot1 data);

    /// @notice              View method to read SegmentManagement contract address
    /// @return              Address of SegmentManagement contract
    function SEGMENT_MANAGEMENT() external view returns (ISegmentManagement);

    /// @notice               View method to get total vote weight of minted tokens,
    ///                       only gNFTs with fully activated segments participates in the voting
    /// @return               Value of Votes._getTotalSupply(), i.e. latest total checkpoints
    function getTotalVotePower() external view returns (uint256);

    /// @notice               View method to read 'tokenDataById' mapping of extended token metadata
    /// @param tokenId        tokenId to read mapping for
    /// @return               Stored value of 'tokenDataById[tokenId]' of IgNFT.TokenData type
    function getTokenData(uint256 tokenId) external view returns (TokenData memory);

    /// @notice               View method to read first slot of extended token metadata
    /// @param tokenId        tokenId to read mapping for
    /// @return               Stored value of 'tokenDataById[tokenId].slot0' of IgNFT.Slot0 type
    function getTokenSlot0(uint256 tokenId) external view returns (Slot0 memory);

    /// @notice               View method to read second slot of extended token metadata
    /// @param tokenId        tokenId to read mapping for
    /// @return               Stored value of 'tokenDataById[tokenId].slot1' of IgNFT.Slot1 type
    function getTokenSlot1(uint256 tokenId) external view returns (Slot1 memory);

    /// @notice               Minting new gNFT token
    ///                       Restricted only to SEGMENT_MANAGEMENT contract
    /// @param to             Address of recipient
    /// @param data           Parameters of new token to be minted
    function mint(address to, TokenData memory data) external;

    /// @notice               Update IgNFT.Slot0 parameters of IgNFT.TokenData of a token
    ///                       Restricted only to SEGMENT_MANAGEMENT contract
    /// @param tokenId        Token to be updated
    /// @param data           Slot0 structure to update existed
    function updateTokenDataSlot0(uint256 tokenId, Slot0 memory data) external;

    /// @notice               Update IgNFT.Slot1 parameters of IgNFT.TokenData of a token
    ///                       Restricted only to SEGMENT_MANAGEMENT contract
    /// @param tokenId        Token to be updated
    /// @param data           Slot1 structure to update existed
    function updateTokenDataSlot1(uint256 tokenId, Slot1 memory data) external;

    struct TokenData {
        Slot0 slot0;
        Slot1 slot1;
    }

    struct Slot0 {
        TokenType tokenType;
        uint8 activeSegment;
        uint8 voteWeight;
        uint8 rewardWeight;
        bool usedForMint;
        uint48 completionTimestamp;
        address lockedMarket;
    }

    struct Slot1 {
        uint256 lockedVaultShares;
    }

    enum TokenType {
        Topaz,
        Emerald,
        Diamond
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

/// @title  Partial interface for Oracle contract
/// @notice Based on PriceOracle from Compound Finance
///         (https://github.com/compound-finance/compound-protocol/blob/v2.8.1/contracts/PriceOracle.sol)
interface IOracle {
    /// @notice         Get the underlying price of a market(cToken) asset
    /// @param market   The market to get the underlying price of
    /// @return         The underlying asset price mantissa (scaled by 1e18).
    ///                 Zero means the price is unavailable.
    function getUnderlyingPrice(address market) external view returns (uint256);

    /// @notice         Evaluates input amount according to stored price, accrues interest
    /// @param cToken   Market to evaluate
    /// @param amount   Amount of tokens to evaluate according to 'reverse' order
    /// @param reverse  Order of evaluation
    /// @return         Depending on 'reverse' order:
    ///                     false - return USD amount equal to 'amount' of 'cToken'
    ///                     true - return cTokens equal to 'amount' of USD
    function getEvaluation(address cToken, uint256 amount, bool reverse) external returns (uint256);

    /// @notice         Evaluates input amount according to stored price, doesn't accrue interest
    /// @param cToken   Market to evaluate
    /// @param amount   Amount of tokens to evaluate according to 'reverse' order
    /// @param reverse  Order of evaluation
    /// @return         Depending on 'reverse' order:
    ///                     false - return USD amount equal to 'amount' of 'cToken'
    ///                     true - return cTokens equal to 'amount' of USD
    function getEvaluationStored(
        address cToken,
        uint256 amount,
        bool reverse
    ) external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

import "./IgNFT.sol";
import "./IComptroller.sol";
import "./ITPIToken.sol";
import "./ITreasury.sol";
import "./IOracle.sol";

/// @title  Segment management contract for gNFT governance token for Tonpound protocol
interface ISegmentManagement {
    /// @notice Revert reason for activating segments for a fully activated token
    error AlreadyFullyActivated();

    /// @notice Revert reason for repeating discount activation
    error DiscountUsed();

    /// @notice Revert reason for minting over the max segment number
    error ExceedingMaxSegments();

    /// @notice Revert reason for minting without liquidity in Tonpound protocol
    error FailedLiquidityCheck();

    /// @notice Revert reason for minting token with a market without membership
    error InvalidMarket();

    /// @notice Revert reason for activating segment with invalid Merkle proof for given account
    error InvalidProof();

    /// @notice Revert reason for activating more segments than available
    error InvalidSegmentsNumber();

    /// @notice Revert reason for operating tokens without ownership
    error InvalidTokenOwnership(uint256 tokenId);

    /// @notice Revert reason for activating last segment without specified liquidity for lock
    error MarketForLockNotSpecified();

    /// @notice Revert reason for minting high tier gNFT without providing proof of ownership
    error MintingRequirementsNotMet();

    /// @notice Revert reason for zero returned price from Oracle contract
    error OracleFailed();

    /// @notice Revert reason for trying to lock already locked token
    error TokenAlreadyLocked();

    /// @notice              Emitted during NFT segments activation
    /// @param tokenId       tokenId of activated token
    /// @param segment       New active segment after performed activation
    event ActivatedSegments(uint256 indexed tokenId, uint8 segment);

    /// @notice              Emitted after the last segment of gNFT token is activated
    /// @param tokenId       tokenId of completed token
    /// @param user          Address of the user who completed the token
    event TokenCompleted(uint256 indexed tokenId, address indexed user);

    /// @notice              Emitted when whitelisted users activate their segments with discount
    /// @param leaf          Leaf of Merkle tree being used in activation
    /// @param root          Root of Merkle tree being used in activation
    event Discounted(bytes32 leaf, bytes32 root);

    /// @notice             Emitted to notify about airdrop Merkle root change
    /// @param oldRoot      Old root
    /// @param newRoot      New updated root to be used after this tx
    event AirdropMerkleRootChanged(bytes32 oldRoot, bytes32 newRoot);

    /// @notice              View method to read Tonpound Comptroller address
    /// @return              Address of Tonpound Comptroller contract
    function TONPOUND_COMPTROLLER() external view returns (IComptroller);

    /// @notice View method to read gNFT
    /// @return Address of gNFT contract
    function gNFT() external view returns (IgNFT);

    /// @notice View method to read Tonpound TPI token
    /// @return Address of TPI token contract
    function TPI() external view returns (ITPIToken);

    /// @notice               View method to get price in TPI tokens to activate segments of gNFT token
    /// @param tokenId        tokenId of the token to activate segments of
    /// @param segmentsToOpen Number of segments to activate, fails if this number exceeds available segments
    /// @param discounted     Whether the user is eligible for activation discount
    /// @return               Price in TPI tokens to be burned from caller to activate specified number of segments
    function getActivationPrice(
        uint256 tokenId,
        uint8 segmentsToOpen,
        bool discounted
    ) external view returns (uint256);

    /// @notice              View method to get amount of liquidity to be provided for lock in order to
    ///                      complete last segment and make gNFT eligible for reward distribution in Treasury
    /// @param market        Tonpound Comptroller market (cToken) to be locked
    /// @param tokenType     Type of token to quote lock for
    /// @return              Amount of specified market tokens to be provided for lock
    function quoteLiquidityForLock(
        address market,
        IgNFT.TokenType tokenType
    ) external view returns (uint256);

    /// @notice              Minting new gNFT token with zero active segments and no voting power
    ///                      Minter must have total assets in Tonpound protocol over the threshold nominated in USD
    /// @param markets       User provided markets of Tonpound Comptroller to be checked for liquidity
    function mint(address[] memory markets) external;

    /// @notice              Minting new gNFT token of given type with zero active segments and no voting power
    ///                      Minter must have assets in given markets of Tonpound protocol over the threshold in USD
    ///                      Minter must own number of fully activated lower tier gNFTs to mint Emerald or Diamond
    /// @param markets       User provided markets of Tonpound Comptroller to be checked for liquidity
    /// @param tokenType     Token type to mint: Topaz, Emerald, or Diamond
    /// @param proofIds      List of tokenIds to be checked for ownership, activation, and type
    function mint(
        address[] memory markets,
        IgNFT.TokenType tokenType,
        uint256[] calldata proofIds
    ) external;

    /// @notice              Activating number of segments of given gNFT token
    ///                      Caller must be the owner, token may be completed with this function if
    ///                      caller provides enough liquidity for lock in specified Tonpound 'market'
    /// @param tokenId       tokenId to be activated for number of segments
    /// @param segments      Number of segments to be activated, must not exceed available segments of tokenId
    /// @param market        Optional address of Tonpound market to lock liquidity in order to complete gNFT
    function activateSegments(uint256 tokenId, uint8 segments, address market) external;

    /// @notice              Activating 1 segment of given gNFT token
    ///                      Caller must provide valid Merkle proof, token may be completed with this function if
    ///                      'account' provides enough liquidity for lock in specified Tonpound 'market'
    /// @param tokenId       tokenId to be activated for a single segment
    /// @param account       Address of whitelisted account, which is included in leaf of Merkle tree
    /// @param nonce         Nonce parameter included in leaf of Merkle tree
    /// @param proof         bytes32[] array of Merkle tree proof for whitelisted account
    /// @param market        Optional address of Tonpound market to lock liquidity in order to complete gNFT
    function activateSegmentWithProof(
        uint256 tokenId,
        address account,
        uint256 nonce,
        bytes32[] memory proof,
        address market
    ) external;

    /// @notice              Unlocking liquidity of a fully activated gNFT
    ///                      Caller must be the owner. If function is called before start of reward claiming,
    ///                      the given tokenId is de-registered in Treasury contract and stops acquiring rewards
    ///                      Any rewards acquired before unlocking will be available once claiming starts
    /// @param tokenId       tokenId to unlock liquidity for
    function unlockLiquidity(uint256 tokenId) external;

    /// @notice              Locking liquidity of a fully activated gNFT (reverting result of unlockLiquidity())
    ///                      Caller must be the owner. If function is called before start of reward claiming,
    ///                      the given tokenId is registered in Treasury contract and starts acquiring rewards
    ///                      Any rewards acquired before remains accounted and will be available once claiming starts
    /// @param tokenId       tokenId to lock liquidity for
    /// @param market        Address of Tonpound market to lock liquidity in
    function lockLiquidity(uint256 tokenId, address market) external;

    /// @notice             Updating Merkle root for whitelisting airdropped accounts
    ///                     Restricted to MANAGER_ROLE bearers only
    /// @param root         New root of Merkle tree of whitelisted addresses
    function setMerkleRoot(bytes32 root) external;
}

// SPDX-License-Identifier: UNLICENSED

import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";

pragma solidity ^0.8.4;

/// @title  Partial interface for Tonpound TPI token
/// @notice Extension of IERC20 standard interface from OpenZeppelin
///         (https://docs.openzeppelin.com/contracts/4.x/api/token/erc20#IERC20)
interface ITPIToken is IERC20Upgradeable {
    /// @notice View function to get current active circulating supply,
    ///         used to calculate price of gNFT segment activation
    /// @return Total supply without specific TPI storing address, e.g. vesting
    function getCirculatingSupply() external view returns (uint256);

    /// @notice         Function to be used for gNFT segment activation
    /// @param account  Address, whose token to be burned
    /// @param amount   Amount to be burned
    function burnFrom(address account, uint256 amount) external;
}

// SPDX-License-Identifier: UNLICENSED

import "./IComptroller.sol";
import "./IgNFT.sol";
import "./IAuth.sol";

pragma solidity ^0.8.4;

/// @title  Interface for Tonpound Treasury contract, which is a part of Tonpound gNFT token
interface ITreasury {
    /// @notice Revert reason for unauthorized access to protected functions
    error Auth();

    /// @notice Revert reason claiming rewards before start of claiming period
    error ClaimingNotStarted();

    /// @notice Revert reason claiming unregistered reward token
    error InvalidRewardToken();

    /// @notice Revert reason for distributing rewards in unsupported reward token
    error InvalidMarket();

    /// @notice Revert reason for setting too high parameter value
    error InvalidParameter();

    /// @notice Revert reason for claiming reward for not-owned gNFT token
    error InvalidTokenOwnership();

    /// @notice Revert reason for accessing protected functions during pause
    error Paused();

    /// @notice Revert reason for unwanted input zero addresses
    error ZeroAddress();

    /// @notice Emitted in governance function when reserveBPS variable is updated
    event ReserveFactorUpdated(uint256 oldValue, uint256 newValue);

    /// @notice Emitted in governance function when reserveFund variable is updated
    event ReserveFundUpdated(address oldValue, address newValue);

    /// @notice             View method to read 'fixedRewardPayments' mapping of
    ///                     solid reward payments for tokenId
    /// @param rewardToken  Address of reward token to read mapping for
    /// @param tokenId      gNFT tokenId to read mapping for
    /// @return             Stored bool value of 'fixedRewardPayments[rewardToken][tokenId], 
    ///                     that can be claimed regardless of tokenId registration status
    function fixedRewardPayments(address rewardToken, uint256 tokenId) external view returns (uint256);

    /// @notice             View method to read all supported reward tokens
    /// @return             Array of addresses of registered reward tokens
    function getRewardTokens() external view returns (address[] memory);

    /// @notice             View method to read number of supported reward tokens
    /// @return             Number of registered reward tokens
    function getRewardTokensLength() external view returns (uint256);

    /// @notice             View method to read a single reward token address
    /// @param index        Index of reward token in array to return
    /// @return             Address of reward token at given index in array
    function getRewardTokensAtIndex(uint256 index) external view returns (address);

    /// @notice             View method to read 'lastClaimForTokenId' mapping
    ///                     storing 'rewardPerShare' parameter for 'tokenId'
    ///                     from time of registration or last claiming event
    /// @param rewardToken  Address of reward token to read mapping for
    /// @param tokenId      gNFT tokenId to read mapping for
    /// @return             Stored value of 'lastClaimForTokenId[rewardToken][tokenId]',
    ///                     last claim value of reward per share multiplied by REWARD_PER_SHARE_MULTIPLIER = 1e12
    function lastClaimForTokenId(
        address rewardToken,
        uint256 tokenId
    ) external view returns (uint256);

    /// @notice             View method to get pending rewards for given
    ///                     reward token and gNFT token, contains fixed part for
    ///                     de-registered tokens and calculated part of distributed rewards
    /// @param rewardToken  Address of reward token to calculate pending rewards
    /// @param tokenId      gNFT tokenId to calculate pending rewards for
    /// @return             Value of rewards in rewardToken that would be claimed if claim is available
    function pendingReward(address rewardToken, uint256 tokenId) external view returns (uint256);

    /// @notice             View method to read 'registeredTokenIds' mapping of
    ///                     tracked registered gNFT tokens
    /// @param tokenId      tokenId of gNFT token to read
    /// @return             Stored bool value of 'registeredTokenIds[tokenId]', true if registered
    function registeredTokenIds(uint256 tokenId) external view returns (bool);

    /// @notice             View method to read reserve factor
    /// @return             Fraction (in bps) of rewards going to reserves, can be set to 0
    function reserveBPS() external view returns (uint256);

    /// @notice             View method to read address of reserve fund
    /// @return             Address to collect reserved part of rewards, can be set to 0
    function reserveFund() external view returns (address);

    /// @notice             View method to read 'rewardPerShare' mapping of
    ///                     tracked balances of Treasury contract to properly distribute rewards
    /// @param rewardToken  Address of reward token to read mapping for
    /// @return             Stored value of 'rewardPerShare[rewardToken]',
    ///                     reward per share multiplied by REWARD_PER_SHARE_MULTIPLIER = 1e12
    function rewardPerShare(address rewardToken) external view returns (uint256);

    /// @notice             View method to read 'rewardBalance' mapping of distributed rewards
    ///                     in specified rewardToken stored to properly account fresh rewards
    /// @param rewardToken  Address of reward token to read mapping for
    /// @return             Stored value of 'rewardBalance[rewardToken]'
    function rewardBalance(address rewardToken) external view returns (uint256);

    /// @notice             View method to get the remaining time until start of claiming period
    /// @return             Seconds until claiming is available, zero if claiming has started
    function rewardsClaimRemaining() external view returns (uint256);

    /// @notice             View method to read Tonpound Comptroller address
    /// @return             Address of Tonpound Comptroller contract
    function TONPOUND_COMPTROLLER() external view returns (IComptroller);

    /// @notice             View method to read total weight of registered gNFT tokens,
    ///                     eligible for rewards distribution
    /// @return             Stored value of 'totalRegisteredWeight'
    function totalRegisteredWeight() external view returns (uint256);

    /// @notice             Register and distribute incoming rewards in form of all tokens
    ///                     supported by the Tonpound Comptroller contract
    ///                     Rewards must be re-distributed if there's no users to receive at the moment
    function distributeRewards() external;

    /// @notice             Register and distribute incoming rewards in form of underlying of 'market'
    ///                     Market address must be listed in the Tonpound Comptroller
    ///                     Rewards must be re-distributed if there's no users to receive at the moment
    /// @param market       Address of market cToken to try to distribute
    function distributeReward(address market) external;

    /// @notice             Claim all supported pending rewards for given gNFT token
    ///                     Claimable only after rewardsClaimRemaining() == 0 and
    ///                     only by the owner of given tokenId
    /// @param tokenId      gNFT tokenId to claim rewards for
    function claimRewards(uint256 tokenId) external;

    /// @notice             Claim pending rewards for given gNFT token in form of single 'rewardToken'
    ///                     Claimable only after rewardsClaimRemaining() == 0 and
    ///                     only by the owner of given tokenId
    /// @param tokenId      gNFT tokenId to claim rewards for
    /// @param rewardToken  Address of reward token to claim rewards in
    function claimReward(uint256 tokenId, address rewardToken) external;

    /// @notice             Register or de-register tokenId for rewards distribution
    ///                     De-registering saves acquired rewards in fixed part for claiming when available
    ///                     Restricted for gNFT contract only
    /// @param tokenId      gNFT tokenId to update registration status for
    /// @param state        New boolean registration status
    function registerTokenId(uint256 tokenId, bool state) external;

    /// @notice             Updating reserveBPS factor for reserve fund part of rewards
    /// @param newFactor    New value to be less than 5000
    function setReserveFactor(uint256 newFactor) external;

    /// @notice             Updating reserve fund address
    /// @param newFund      New address to receive future reserve rewards
    function setReserveFund(address newFund) external;

    struct RewardInfo {
        address market;
        uint256 amount;
    }
}

// SPDX-License-Identifier: UNLICENSED

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "./Constants.sol";
import "./interfaces/ITreasury.sol";
import "./interfaces/ICToken.sol";

pragma solidity 0.8.17;

contract Treasury is UUPSUpgradeable, ReentrancyGuardUpgradeable, ITreasury {
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    IComptroller public TONPOUND_COMPTROLLER;
    uint64 internal _REWARD_CLAIM_START;
    address public reserveFund;
    uint256 public reserveBPS;
    uint256 public totalRegisteredWeight;

    mapping(address => mapping(uint256 => uint256)) public fixedRewardPayments;
    mapping(address => mapping(uint256 => uint256)) public lastClaimForTokenId;
    mapping(address => uint256) public rewardPerShare;
    mapping(address => uint256) public rewardBalance;
    mapping(uint256 => bool) public registeredTokenIds;

    EnumerableSetUpgradeable.AddressSet internal rewardTokens;

    function initialize(address comptroller_) external initializer {
        if (comptroller_ == address(0)) revert ZeroAddress();
        __UUPSUpgradeable_init();

        TONPOUND_COMPTROLLER = IComptroller(comptroller_);
        _REWARD_CLAIM_START = uint64(block.timestamp + Constants.REWARD_ACCUMULATING_PERIOD);
    }

    function distributeRewards() external {
        address[] memory tokens = TONPOUND_COMPTROLLER.getAllMarkets();
        _distributeInternal(tokens);
    }

    function distributeReward(address market) external {
        if (!TONPOUND_COMPTROLLER.markets(market).isListed) revert InvalidMarket();
        address[] memory tokens = new address[](1);
        tokens[0] = market;
        _distributeInternal(tokens);
    }

    function _distributeInternal(address[] memory tokens) internal {
        uint256 latestSupply = totalRegisteredWeight;
        address resAddress = reserveFund;
        uint256 resFactorBPS = reserveBPS;
        uint256 updRewardBalance;
        uint256 amount;
        uint256 reserveAmount;
        address underlyingToken;
        bool takeReserve = (resAddress != address(0) && resFactorBPS > 0);
        for (uint256 i; i < tokens.length; ) {
            ICToken(tokens[i])._reduceReserves();
            underlyingToken = ICToken(tokens[i]).underlying();
            updRewardBalance = IERC20Upgradeable(underlyingToken).balanceOf(address(this));
            amount = updRewardBalance - rewardBalance[tokens[i]];
            if (takeReserve) {
                reserveAmount = (amount * resFactorBPS) / Constants.DENOM_BPS;
                IERC20Upgradeable(underlyingToken).safeTransfer(resAddress, reserveAmount);
            }
            unchecked {
                if (_updateRewards(underlyingToken, amount - reserveAmount, latestSupply)) {
                    rewardBalance[underlyingToken] = updRewardBalance - reserveAmount;
                }
                i++;
            }
        }
    }

    function _updateRewards(
        address rewardToken,
        uint256 amount,
        uint256 supply
    ) internal returns (bool) {
        uint256 curRewardPerShare = rewardPerShare[rewardToken];
        if (curRewardPerShare == 0) {
            rewardTokens.add(rewardToken);
        }
        if (supply == 0) {
            return false;
        }
        rewardPerShare[rewardToken] =
            curRewardPerShare +
            (amount * Constants.EXP_REWARD_PER_SHARE) /
            supply;
        return true;
    }

    function registerTokenId(uint256 tokenId, bool state) external nonReentrant {
        IgNFT gNft = _getgNFTAddress();
        if (msg.sender != address(gNft.SEGMENT_MANAGEMENT())) revert Auth();
        if (state == registeredTokenIds[tokenId]) return;

        uint256 deltaWeight = gNft.getTokenSlot0(tokenId).rewardWeight;
        uint256 updRegisteredWeight = state
            ? totalRegisteredWeight + deltaWeight
            : totalRegisteredWeight - deltaWeight;
        totalRegisteredWeight = updRegisteredWeight;
        uint256 length = rewardTokens.length();
        for (uint256 i; i < length; ) {
            address rewardToken = rewardTokens.at(i);
            if (!state) {
                fixedRewardPayments[rewardToken][tokenId] = _pendingReward(
                    tokenId,
                    rewardToken,
                    gNft
                );
            }
            lastClaimForTokenId[rewardToken][tokenId] = state ? rewardPerShare[rewardToken] : 0;
            unchecked {
                i++;
            }
        }
        registeredTokenIds[tokenId] = state;
    }

    function pendingReward(address rewardToken, uint256 tokenId) external view returns (uint256) {
        IgNFT gNft = _getgNFTAddress();
        return _pendingReward(tokenId, rewardToken, gNft);
    }

    function _pendingReward(
        uint256 tokenId,
        address rewardToken,
        IgNFT gNft
    ) internal view returns (uint256) {
        uint8 weight = gNft.getTokenSlot0(tokenId).rewardWeight;
        uint256 curRewardPerShare = rewardPerShare[rewardToken];
        uint256 pendingPart = registeredTokenIds[tokenId]
            ? (weight * (curRewardPerShare - lastClaimForTokenId[rewardToken][tokenId])) /
                Constants.EXP_REWARD_PER_SHARE
            : 0;
        return fixedRewardPayments[rewardToken][tokenId] + pendingPart;
    }

    function claimRewards(uint256 tokenId) external whenNotPaused nonReentrant {
        IgNFT gNft = _getgNFTAddress();
        _validateClaiming(tokenId, address(gNft));
        uint256 length = rewardTokens.length();
        for (uint256 i; i < length; ) {
            _claimRewardInternal(tokenId, rewardTokens.at(i), gNft);
            unchecked {
                i++;
            }
        }
    }

    function claimReward(uint256 tokenId, address rewardToken) external whenNotPaused nonReentrant {
        IgNFT gNft = _getgNFTAddress();
        _validateClaiming(tokenId, address(gNft));
        if (!rewardTokens.contains(rewardToken)) revert InvalidRewardToken();
        _claimRewardInternal(tokenId, rewardToken, gNft);
    }

    function _claimRewardInternal(uint256 tokenId, address rewardToken, IgNFT gNft) internal {
        uint256 reward;
        uint256 pendingPart;
        if (registeredTokenIds[tokenId]) {
            uint8 weight = gNft.getTokenSlot0(tokenId).rewardWeight;
            uint256 curRewardPerShare = rewardPerShare[rewardToken];
            pendingPart =
                (weight * (curRewardPerShare - lastClaimForTokenId[rewardToken][tokenId])) /
                Constants.REWARD_PER_SHARE_MULTIPLIER;
            lastClaimForTokenId[rewardToken][tokenId] = curRewardPerShare;
        }
        reward = fixedRewardPayments[rewardToken][tokenId] + pendingPart;
        fixedRewardPayments[rewardToken][tokenId] = 0;
        rewardBalance[rewardToken] -= reward;
        IERC20Upgradeable(rewardToken).safeTransfer(msg.sender, reward);
    }

    function _validateClaiming(uint256 tokenId, address gNft) internal view {
        if (rewardsClaimRemaining() > 0) revert ClaimingNotStarted();
        if (msg.sender != IERC721Upgradeable(gNft).ownerOf(tokenId)) revert InvalidTokenOwnership();
    }

    function rewardsClaimRemaining() public view returns (uint256) {
        uint256 claimTimestamp = uint256(_REWARD_CLAIM_START);
        if (block.timestamp > claimTimestamp) {
            return 0;
        }
        unchecked {
            return claimTimestamp - block.timestamp;
        }
    }

    function getRewardTokens() external view returns (address[] memory) {
        return rewardTokens.values();
    }

    function getRewardTokensLength() external view returns (uint256) {
        return rewardTokens.length();
    }

    function getRewardTokensAtIndex(uint256 index) external view returns (address) {
        return rewardTokens.at(index);
    }

    function _getgNFTAddress() internal view returns (IgNFT) {
        return IgNFT(TONPOUND_COMPTROLLER.gNFT());
    }

    function setReserveFactor(uint256 newReserveBPS) external onlyAdmin {
        if (newReserveBPS > Constants.MAX_RESERVE_BPS) {
            revert InvalidParameter();
        }
        emit ReserveFactorUpdated(reserveBPS, newReserveBPS);
        reserveBPS = newReserveBPS;
    }

    function setReserveFund(address newReserveFund) external onlyAdmin {
        if (newReserveFund == address(0)) {
            revert ZeroAddress();
        }
        emit ReserveFundUpdated(reserveFund, newReserveFund);
        reserveFund = newReserveFund;
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyAdmin {}

    modifier whenNotPaused() {
        if (PausableUpgradeable(address(_getgNFTAddress().SEGMENT_MANAGEMENT())).paused()) {
            revert Paused();
        }
        _;
    }

    modifier onlyAdmin() {
        if (!IAuth(address(_getgNFTAddress().SEGMENT_MANAGEMENT())).isAdmin(msg.sender)) {
            revert Auth();
        }
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }
}