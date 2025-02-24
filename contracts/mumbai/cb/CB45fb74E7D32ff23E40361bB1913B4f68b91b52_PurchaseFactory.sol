/**
 *Submitted for verification at polygonscan.com on 2022-08-15
*/

// Sources flattened with hardhat v2.8.0 https://hardhat.org

// File contracts/common/ContextMixin.sol


pragma solidity ^0.8.0;

abstract
contract ContextMixin
{
    function msgSender() internal view returns (address sender) {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
                // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender := and(
                    mload(add(array, index)),
                    0xffffffffffffffffffffffffffffffffffffffff
                )
            }
        } else {
            sender = msg.sender;
        }
        return sender;
    }
}


// File @openzeppelin/contracts-upgradeable/proxy/beacon/[email protected]

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


// File @openzeppelin/contracts-upgradeable/utils/[email protected]


// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

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


// File @openzeppelin/contracts-upgradeable/utils/[email protected]


// OpenZeppelin Contracts v4.4.1 (utils/StorageSlot.sol)

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
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
        }
    }
}


// File @openzeppelin/contracts-upgradeable/proxy/utils/[email protected]


// OpenZeppelin Contracts v4.4.1 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
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
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
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
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

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

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}


// File @openzeppelin/contracts-upgradeable/proxy/ERC1967/[email protected]


// OpenZeppelin Contracts v4.4.1 (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;




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
        __ERC1967Upgrade_init_unchained();
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
    function _upgradeToAndCallSecure(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        address oldImplementation = _getImplementation();

        // Initial upgrade and setup call
        _setImplementation(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }

        // Perform rollback test if not already in progress
        StorageSlotUpgradeable.BooleanSlot storage rollbackTesting = StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT);
        if (!rollbackTesting.value) {
            // Trigger rollback using upgradeTo from the new implementation
            rollbackTesting.value = true;
            _functionDelegateCall(
                newImplementation,
                abi.encodeWithSignature("upgradeTo(address)", oldImplementation)
            );
            rollbackTesting.value = false;
            // Check rollback was effective
            require(oldImplementation == _getImplementation(), "ERC1967Upgrade: upgrade breaks further upgrades");
            // Finally reset to the new implementation and log the upgrade
            _upgradeTo(newImplementation);
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
    uint256[50] private __gap;
}


// File @openzeppelin/contracts-upgradeable/proxy/utils/[email protected]


// OpenZeppelin Contracts v4.4.1 (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;


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
abstract contract UUPSUpgradeable is Initializable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal onlyInitializing {
        __ERC1967Upgrade_init_unchained();
        __UUPSUpgradeable_init_unchained();
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
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallSecure(newImplementation, new bytes(0), false);
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
        _upgradeToAndCallSecure(newImplementation, data, true);
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
    uint256[50] private __gap;
}


// File contracts/purchase-factory/IPurchaseFactory.sol


pragma solidity ^0.8.4;

interface IPurchaseFactory {

    struct SeatSelection {
        string section;
        string row;
        string seatno;
    }

    struct SeatBook {
        address assetAddress;
        address seller;
        SeatSelection[] seatNos;
        uint256 subtotal;
        uint256 tax;
        uint256 ccfee;
    }

    struct BulkOrderFinal {
        uint8 tokenSymbol;
        uint256 paidAmount;
        string clOrdId;
        address buyer;
        SeatBook[] bulkOrders;
    }

    struct StandardPurchaseBulkOrder {
        uint8 tokenSymbol;
        uint256 paidAmount;
        string clOrdId;
        address buyer;
        address seller;
        address assetAddress;
        uint256 numberOfTokens;
        uint256 subtotal;
        uint256 tax;
        uint256 ccfee;
    }

    event VirtualTokenAddrUpdated(address indexed msgSender, address indexed prevAddress, address indexed newAddress); 

    event OrderProcessed(address indexed msgSender, address indexed buyer, uint8 tokenSymbol, uint256 yhSettlement, 
                        uint256 sellerSettlement, string clOrdId);

    function updateAccessControlContract(address accessControlContract_) external ;

    function setVtokenContract(uint8 tokenSymbol, address vtokenContract) external;

    function virtualTokenContract(uint8 tokenSymbol) external view returns (address);

    function accessControlContract() external view returns(address);

    function seatedBulkOrder(BulkOrderFinal memory bulkOrderFinal,bytes32 r, bytes32 s, uint8 v) external;

    function standardBulkOrder(StandardPurchaseBulkOrder memory standardPurchaseBulkOrder,bytes32 r, bytes32 s, uint8 v) external;
}


// File @openzeppelin/contracts-upgradeable/utils/math/[email protected]


// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMathUpgradeable {
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}


// File @openzeppelin/contracts/token/ERC20/[email protected]


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


// File @openzeppelin/contracts/access/[email protected]


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


// File @openzeppelin/contracts/utils/[email protected]


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


// File contracts/common/ErrorCodes.sol


pragma solidity ^0.8.0; 
/**
 * @dev this library consists of error codes applicable for ERC721 contracts.
 */
library ErrorCodes {

    string internal constant ALREADY_UPGRADED = "ALREADY_UPGRADED";
    string internal constant INVALID_CONTRACT = "INVALID_CONTRACT";

    //error codes for ChildMintableERC721
    string internal constant INVALID_ACCESS_CONTRACT = "CHME:INV_ACCESS_CONTRACT"; //invalid access control(Access MANAGEMENT) contract
    string internal constant INVALID_OWNER = "CHME:INV_OWNER"; //Ownable: caller is not the owner
    string internal constant INVALID_OWNER_OR_ADMIN = "CHME:INV_OWNER/ADMIN"; //Ownable: caller is not the owner or admin
    string internal constant NEW_OWNER_ZERO_ADDRESS = "CHME:OWNER_ZERO_ADDR"; //Ownable: new owner is the zero address
    string internal constant INSUFFICIENT_PERMISSIONS = "CHME:INSUFFICIENT_PERMISSIONS";

    string internal constant WITHDRAWAL_NOT_SUPPORTED = "CHME:WD_NOT_SPTD"; //ChildMintableERC721 : token withdrawal isn't supported
    string internal constant INVALID_TOKEN_OWNER = "CHME:INV_TOKEN_OWNER";//ChildMintableERC721: INVALID_TOKEN_OWNER
    string internal constant BATCH_WITHDRAWAL_NOT_SUPPORTED = "CHME:BATCH_WD_NOT_SPTD"; //ChildMintableERC721 : token batch withdrawal isn't supported

    string internal constant WD_BATCH_LIMIT_EXCEEDED = "CHME:BATCH_WD_LMT_EXCEEDS"; //ChildMintableERC721: EXCEEDS_BATCH_LIMIT
    string internal constant WD_METADATA_NOT_SUPPORTED = "CHME:WD_METADATA_NOT_SPTD"; //ChildMintableERC721 : token withdrawal with metadata isn't supported
    string internal constant TOKEN_NOT_EXIST_IN_WD_LIST = "CHME:TOKEN_NOT_EXIST_WD_LIST"; //ChildMintableERC721: tokenId does not exist in the withdrawnTokens
    string internal constant TOKEN_IN_ROOT_CHAIN = "CHME:TOKEN_IN_ROOT_CHAIN"; //ChildMintableERC721: TOKEN_EXISTS_ON_ROOT_CHAIN
    //Error codes for BasicEditionERC721
    string internal constant INSUFFICIENT_SUPPLY = "BASE:INSUF_SPLY"; //BasicEditionERC721: Insufficient supply to mint
    string internal constant EDITION_CLOSED = "BASE:EDITION_CLOSED"; //BasicEditionERC721: Edition is closed
    string internal constant BASE_BATCH_LIMIT_EXCEEDS = "BASE:BATCH_LMT_EXCEEDS"; //BasicEditionERC721: EXCEEDS_BATCH_LIMIT
    string internal constant TOTAL_SPLY_GRT_SPLY_LMT = "BASE:TOTAL_SPLY_GRT_SPLY_LIMIT"; //BasicEditionERC721: Can not update supply limit below the current total supply
    string internal constant BLOCK_TS_GRT_GIVEN_TS = "BASE:BLOCK_TS_GRT_GIVEN_TS"; //BasicEditionERC721: Cannot set new timestamp earlier than the current block time
    string internal constant MINTABLE_BATCH_SIZE = "BASE:MINT_SZ_EXCEEDS";//BasicEditionERC721: can not mint more than 100 accounts at a given method call
    string internal constant SUPLY_LMT_NOT_SET = "BASE:SUPLY_LMT_NOT_SET";//supply limit is not set
    string internal constant PAYEE_NULL_ADDR = "BASE:PAYEE_ADDR_NULL";//asset payee address is null
    string internal constant ASSET_PAYEE_NULL_ADDR = "BASE:ASSET_PAYEE_ADDR_NULL";//asset payee address is null
    string internal constant TAX_PAYEE_NULL_ADDR = "BASE:TAX_PAYEE_ADDR_NULL";//tax payee address is null
    string internal constant CCFEE_PAYEE_NULL_ADDR = "BASE:CCFEE_PAYEE_ADDR_NULL";//ccfee payee address is null
    string internal constant INV_FEE_TYPE_SPEC = "BASE:INV_FEE_TYPE_SPEC";//asset payee address is null
    
    //Error codes for RedeemableERC721
    string internal constant RDME_INV_TOKEN_OWNER = "RDME:INV_TOKEN_OWNER"; //token is not owned by redeeming account
    string internal constant RDME_TOKEN_ALREADY_REDEEMED = "RDME:TOKEN_ALREADY_REDEEMED";//token has already been redeemed
    string internal constant UNSUPPORTED_REDEEM = "RDME:UN_SPTD_REDEEM";//un-supported redeem mode
    string internal constant EXCEEDS_MAX_SEAT_TOKEN_BATCH_SIZE = "RDME:EXCEEDS_MAX_SEAT_MAP_SIZE";
    string internal constant ASSET_IS_NOT_SEATED_TICKET = "RDME:ASSET_IS_NOT_SEATED_TICKET";
    string internal constant UNSUPPORTED_TOKEN_STATUS = "RDME:UNSPTD_TKN_STATUS";//un-supported status 
    string internal constant TOKEN_CANCELLED_OR_VOIDED = "RDME:TOKEN_CANCLD_VOIDED";//token already cancelled or voided
    string internal constant NO_SEAT_TOKEN_MAPPING_AVAIL = "RDME:NO_TKN_ID_ASSOC_WITH_SEAT";//No token id associated with the given seat
    string internal constant TOKEN_ID_CAN_NOT_BE_ZERO = "RDME:INV_TOKEN_ID";//token id can not be zero
    string internal constant UNSUPPORTED_TOKEN_ACTION = "RDME:UNSPTD_TKN_ACTION";//un-supported status
    string internal constant TOKEN_IS_NOT_IN_ACTIONABLE_STATE = "RDME:TOKEN_IS_NOT_ACTIONABLE";//un-supported status
    string internal constant BULK_MINT_NOT_PERMITTED = "RDME:BULK_MINT_NOT_PERM";//un-supported status
    string internal constant TOKEN_EXIST = "RDME:TOKEN_EXIST";//token does not exist
    string internal constant INV_SEAT_NO = "RDME:INV_SEAT_NO";//invalid seat no
    string internal constant TOKEN_ID_MAP_TO_DIFF_SEAT = "RDME:TOKEN_MAP_TO_DIFF_SEAT";//token id already mapped to diff seat no

    //Error Codes for BasicTicketERC721
    string internal constant INV_RESALE_LMT = "BATE:INV_RESALE_LMT"; //Invalid resale limit
    string internal constant INV_TRNS_LMT = "BATE:INV_TRNS_LMT"; //Invalid transfer limit
    string internal constant TXN_NOT_ALWD = "BATE:TXN_NOT_ALWD"; //token transfer not allowed
    string internal constant INV_TXN_TYPE = "BATE:INV_TXN_TYPE"; //invalid transaction type
    string internal constant TRANSFER_LMT_EXCEEDS = "BATE:TRANS_LMT_EXCEEDED"; //token transfer not allowed
    string internal constant RESALE_LMT_EXCEEDS = "BATE:RESALE_LMT_EXCEEDED"; //invalid transaction type

    //Error codes for LivingERC721
    string internal constant LVNFT_INV_DAO_ADDRESS = "LVNFT:NULL_DAO_ADDR";//null oracle address.
    string internal constant LVNFT_INV_ORACLE_ADDRESS = "LVNFT:NULL_ORACLE_ADDR";//null oracle address.
    string internal constant LVNFT_INV_LINK_TOKEN_ADDRESS = "LVNFT:NULL_LINK_TOKEN_ADDR";//null link token address
    string internal constant LVNFT_NON_EXIST_TOKEN = "LVNFT:NON_EXISTENT_TOKEN";//non existent token
    string internal constant LVNFT_INV_CARBON_LEVEL = "LVNFT:INV_CARBON_LEVEL";//invalid carbon level
    string internal constant LVNFT_INV_JOB_ID = "LVNFT:INV_JOB_ID";//invalid job id
    string internal constant LVNFT_DEPOSIT_FAILED = "LVNFT:DEPOSIT_FAILED";//LINK deposit failed
    string internal constant LVNFT_WITHDRAWAL_FAILED = "LVNFT:WITHDRAWAL_FAILED";//Link withdrawal failed

    //Error codes for RootAssetPayment( L1 payment) 
    string internal constant RSP_ASSET_ADDR_NULL = "RSP:ASSET_ADDR_NULL";
    string internal constant RSP_INV_FEE_RATE = "RSP:INV_FEE_RATE";
    string internal constant RSP_PAYEE_ADDR_NULL = "RSP:PAYEE_ADDR_NULL";
    string internal constant RSP_SYS_ACC_ADDR_NULL = "RSP:SYS_ACC_ADDR_NULL";
    string internal constant RSP_USER_ADDR_NULL = "RSP:USER_ADDR_NULL";
    string internal constant RSP_PAYMENT_GT_ZERO = "RSP:PAYMENT_GT_ZERO";
    string internal constant RSP_INV_USER_SUBMIT_TXN = "RSP:INV_USER_SUBMIT_TXN";
    string internal constant RSP_INV_CLORDERID = "RSP:INV_CLORDERID";
    string internal constant RSP_AMT_PLUS_FEE_NT_MATCH_PAYMENT = "RSP:AMT_PLUS_FEE_NT_MATCH_PAYMENT";
    string internal constant RSP_PAYMENT_TOK_ADDR_NULL = "RSP:PAYMENT_TOK_ADDR_NULL";
    string internal constant RSP_INV_TOK_SYML = "RSP:INV_TOK_SYML";
    string internal constant RSP_INV_PAYER_SUMT = "RSP:INV_PAYER_SUMT";
    string internal constant RSP_PAYMENT_RECV_ADDR_NULL = "RSP:PAYMENT_RECV_ADDR_NULL"; 
    string internal constant RSP_PAYER_ADDR_NULL = "RSP:PAYER_ADDR_NULL"; 
    string internal constant RSP_PAYEE_IS_NOT_MATCHED_SYSTEM_ACC = "RSP:PAYEE_IS_NOT_MATCHED_SYSTEM_ACC"; 
    string internal constant RSP_SYS_ACC_INSUFF_BAL = "RSP:SYS_ACC_INSUFF_BAL";
    string internal constant RSP_INSUFF_ALLOWANCE = "RSP:INSUFF_ALLOWANCE";
    string internal constant RSP_CLORDERID_ALREADY_REFUNDED = "RSP:CLORDER_ID_PREV_REFUNDED";
    string internal constant RSP_SELF_REFUND_NOT_ALLWD = "RSP:SELF_REFUND_NT_ALLWD";
    string internal constant RSP_INV_CLAIM_ID = "RSP:INV_CLAIM_ID";
    string internal constant RSP_SELF_CLAIM_NOT_ALLWD = "RSP:SELF_CLAIM_NT_ALLWD";
    string internal constant RSP_CLAIMID_ALRD_PROCESSED = "RSP:CLAIMID_ALREADY_PROCESSED";
    string internal constant RSP_FAILED_TO_SEND_ETHER = "RSP:FAILED_TO_SEND_ETHER";
    string internal constant RSP_CONTRACT_INSUFF_BAL = "RSP:INSUFF_BAL_IN_CONTRACT";
    string internal constant RSP_FUND_AMT_NOT_MATCHED = "RSP:AMT_IS_NT_MATCHED_FUNDING_VAL";
    string internal constant RSP_FUNDER_ADDR_NULL = "RSP:FUNDER_ADDR_NULL";
    string internal constant RSP_BAL_IS_ZERO = "RSP:BAL_IS_ZERO";
    string internal constant RSP_AMT_GT_ZERO = "RSP:AMT_SHOULD_BE_GT_ZERO";
    string internal constant RSP_FUNDER_INSUFF_BAL = "RSP:FUNDER_INSUFF_BAL";
    string internal constant RSP_DEFUNDER_ADDR_NULL = "RSP:DEFUNDER_ADDR_NULL";
    string internal constant RSP_CALLER_ADDR_NULL = "RSP:CALLER_ADDR_NULL";
    string internal constant RSP_PAYEE_IS_NOT_MATCHED_CONTRACT = "RSP:PAYEE_IS_NOT_MATCHED_CONTRACT_ADDR";
    string internal constant RSP_CLAIM_SIGNER_ADDR_NULL = "RSP:CLAIM_SIGNER_ADDR_NUL"; 
    string internal constant RSP_INV_CLAIM_SIGNATURE = "RSP:INV_CLAIM_SIGNATURE";
    string internal constant RSP_INV_PAYMENT_SIGNATURE = "RSP:INV_PAYMENT_SIGNATURE";
    string internal constant RSP_WITHDRAWAL_HASH_ALREADY_PROCESSED = "RSP:WD_HASH_ALRDY_PROCESSED";

    //Error codes for purchase factory
    string internal constant PF_SIGNER_ADDR_NULL = "PF:SIGNER_ADDR_NULL";
    string internal constant PF_INV_SIGNATURE = "PF:INV_SIGNATURE";
    string internal constant PF_ACCESS_CONTRACT_NULL = "PF:ACCESS_CONTRACT_ADDR_NULL";
    string internal constant PF_INV_VTOKEN_SYBL = "PF:INV_VTOKEN_SYBL";
    string internal constant PF_VTOKEN_ADDR_NULL = "PF:VTOKEN_ADDR_NULL";
    string internal constant PF_INV_VTOKEN_ADDR = "PF:INV_VTOKEN_ADDR";
    string internal constant PF_INV_CLORDID = "PF:INV_CLORDID";
    string internal constant PF_INV_PAID_AMOUNT = "PF:INV_PAID_AMOUNT";
    string internal constant PF_VTOKEN_NOT_CONFIGURED = "PF:VTOKEN_NOT_CONF_FOR_GIV_TKN_SYBL";
    string internal constant PF_PAYMENT_RECV_ADDR_NULL = "PF:PAYMENT_RECV_ADDR_NULL";
    string internal constant PF_CLORDID_PROCSD = "PF:CLORDID_PROCSD";
    string internal constant PF_SIGNER_CAN_NOT_SUBMIT_TXN = "PF:SIGNER_CAN_NOT_SUBMIT_TXN";
    string internal constant PF_INV_FEE_RATE = "PF:INV_FEE_RATE";
    string internal constant PF_SYSACC_ADDR_NULL = "PF:SYS_ACC_ADDR_NULL";
    string internal constant PF_SYS_ACC_NOT_CONFIGURED = "PF:SYS_ACC_NOT_CONFIG";
    string internal constant PF_NO_PURCHASE_ENTRIES_FOUND = "PF:NO_PURCHASE_ENTRIES_FOUND";
    string internal constant PF_BUYER_ADDR_NULL = "PF:BUYER_ADDR_NULL";
    string internal constant PF_SELLER_ADDR_NULL = "PF:SELLER_ADDR_NULL";
    string internal constant PF_SELLER_ADDR_NOT_MATCHED_WITH_ASSET_PAYEE = "PF:SELLER_ADDR_NOT_MATCH_WITH_ASSET_PAYEE";
}


// File contracts/common/lib/EIP712.sol


pragma solidity ^0.8.0; 

library EIP712 {
    // keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)")
    bytes32 public constant EIP712_DOMAIN_TYPEHASH = 0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f;

    function makeDomainSeparator(string memory name, string memory version)
        internal
        view
        returns (bytes32)
    {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }

        return
            keccak256(
                abi.encode(
                    EIP712_DOMAIN_TYPEHASH,
                    keccak256(bytes(name)),
                    keccak256(bytes(version)),
                    chainId,
                    address(this)
                )
            );
    }

    function recover(
        bytes32 domainSeparator,
        uint8 v,
        bytes32 r,
        bytes32 s,
        bytes memory typeHashAndData
    ) internal pure returns (address) {
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                domainSeparator,
                keccak256(typeHashAndData)
            )
        );
        address recovered = ecrecover(digest, v, r, s);
        require(recovered != address(0), "EIP712: invalid signature");
        return recovered;
    }
}


// File contracts/common/ERC721Constants.sol


pragma solidity ^0.8.0; 
/**
 * @dev this library consists of error codes applicable for ERC721 contracts.
 */
library ERC721Constants {

    // limit batching of tokens due to gas limit restrictions
    uint256 internal constant BATCH_LIMIT = 20;
    uint256 internal constant MIN_NFT_TOKEN_COUNT = 1;

    //Roles in NFT contracts
    bytes32 internal constant DEFAULT_ADMIN_ROLE = 0x00;
    bytes32 internal constant DEPOSITOR_ROLE = keccak256("DEPOSITOR_ROLE");
    bytes32 internal constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 internal constant REDEEMER_ROLE = keccak256("REDEEMER_ROLE");

    //custom ticket related constant
    bytes32 internal constant TICKET_TRANSFER_ROLE = keccak256("TICKET_TRANSFER_ROLE");

    //limit for number of minting accounts in an array
    uint256 internal constant MINT_ACC_SIZE = 50;

    //ticket status
    uint8 internal constant PHYSICAL_REDEEM = 1;
    uint8 internal constant ONLINE_REDEEM = 2;
    uint8 internal constant CANCELLED = 3;
    uint8 internal constant VOIDED = 4;
    //specifiy role to perform cancellation of events. 
    bytes32 internal constant EVENT_MANAGER_ROLE = keccak256("EVENT_MANAGER_ROLE"); 
    //this role will be granted for purchase factory contract.
    bytes32 internal constant PURCHASE_FACTORY_ROLE = keccak256("PURCHASE_FACTORY_ROLE"); 
    uint8 internal constant MAX_SEAT_TOKEN_MAP_SIZE = 100;
    string internal constant PLATFORM = 'YH';

    //fee types,
    uint8 internal constant SELLER_FEE = 1;
    uint8 internal constant TAX_FEE = 2;
    uint8 internal constant CC_FEE = 3;
    uint8 internal constant FOREX_CONVERSION_FEE = 4;

    function isValidRedeem(uint8 currStatus) internal pure returns(bool){
        return (currStatus == PHYSICAL_REDEEM || currStatus == ONLINE_REDEEM ) ? true : false;
    }

    function isValidUpdateAction(uint8 currStatus) internal pure returns(bool){
        return (currStatus == CANCELLED || currStatus == VOIDED) ? true : false;
    }

    function isTokenInActionableState(uint8 currStatus) internal pure returns(bool) {
        return (currStatus != PHYSICAL_REDEEM && currStatus != ONLINE_REDEEM && 
                currStatus != CANCELLED && currStatus != VOIDED ) ? true : false;
    }
}


// File contracts/asset-payment/PaymentConstants.sol


pragma solidity ^0.8.0; 
/**
 * @dev this library consists of error codes applicable for PaymentContracts
 */
library PaymentConstants { 

    //payment currency symbols
    uint8 public constant USD = 0;
    uint8 public constant ETH = 1;
    uint8 public constant BTC = 2;
    uint8 public constant USDC = 3;
    uint8 public constant USDT = 4;
    uint8 public constant HEART = 5;
    uint8 public constant MATIC = 6;
    uint8 public constant DOT = 7;
    //contract ids
    string internal constant ROOT_ASSET_CONTRACT_ID = "RootAssetPayment";
    string internal constant VERSION = "1";
    //status
    string internal constant PAYMENT_SUCCESS = "payment success";
    //roles
    bytes32 internal constant ROOT_MANAGER_ROLE = keccak256("ROOT_MANAGER_ROLE");
    bytes32 internal constant PAYMENT_REFUNDER_ROLE = keccak256("PAYMENT_REFUNDER_ROLE");
    bytes32 internal constant FUNDER_ROLE = keccak256("FUNDER_ROLE");

}


// File contracts/common/IAssetPurchase.sol


pragma solidity ^0.8.4;

interface IAssetPurchase {

    function issueTokens(address to, string[] memory seatNumbers) external;

    function getFeeRate() external view returns(uint256) ; 

    function bulkMint(address to, uint256 numTokens) external;

    function getFeePayee(uint8 feeType) external view returns(address);

}


// File @openzeppelin/contracts/token/ERC20/utils/[email protected]


// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;


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


// File contracts/purchase-factory/PurchaseFactory.sol


pragma solidity ^0.8.4;
pragma experimental ABIEncoderV2;
/**
 * @dev This contract primarily contains two functionalities
 * 1. handles the bulk asset purchases, which means buyng from multiple assets. 
 *    Hence it requires NFTs are to be minted in multiple contracts. 
 * 2. Also does the settlement to the seller in appropriate vtoken.
 */
contract PurchaseFactory is ContextMixin, 
                             UUPSUpgradeable, 
                             IPurchaseFactory { 
                            
    using SafeMathUpgradeable for uint256;

    bytes32 public constant SEAT_SELECTION_TYPE_HASH = keccak256("SeatSelection(string section,string row,string seatno)");
    bytes32 public constant SEAT_BOOK_TYPE_HASH = keccak256("SeatBook(address assetAddress,address seller,SeatSelection[] seatNos,uint256 subtotal,uint256 tax,uint256 ccfee)SeatSelection(string section,string row,string seatno)");
    bytes32 public constant BULK_ORDER_TYPE_HASH = keccak256("BulkOrder(uint8 tokenSymbol,uint256 paidAmount,string clOrdId,address buyer,SeatBook[] bulkOrders)SeatBook(address assetAddress,address seller,SeatSelection[] seatNos,uint256 subtotal,uint256 tax,uint256 ccfee)SeatSelection(string section,string row,string seatno)");
    bytes32 public constant STANDARD_PURCHASE_TYPE_HASH = keccak256("StandardPurchaseBulkOrder(uint8 tokenSymbol,uint256 paidAmount,string clOrdId,address buyer,address seller,address assetAddress,uint256 numberOfTokens,uint256 subtotal,uint256 tax,uint256 ccfee)");

    address private _accessControlContract;
    mapping(uint8 => address) private _vtokenContractMap;
    string private _name; 
    string private _version;
    bytes32 private _domainSeparator;
    address private _owner;
    IAccessControl private _accessControl;
    address private _signer;
    mapping(string => bool) private _processedOrderIds;
    uint256 private _feeRate = 0;
    address private _systemAccount;
    
    function initialize(string memory name_, string memory version_, address accessContractContract_,
                        address signer_, address systemAccount) public virtual initializer {
        require(signer_ != address(0), ErrorCodes.PF_SIGNER_ADDR_NULL);
        require(Address.isContract(accessContractContract_), ErrorCodes.INVALID_CONTRACT); 
        require(systemAccount != address(0), ErrorCodes.PF_SYSACC_ADDR_NULL);
        _name = name_;
        _version = version_;
        _accessControlContract = accessContractContract_;
        _accessControl = IAccessControl(_accessControlContract);
        _domainSeparator = EIP712.makeDomainSeparator(name_, version_); 
        _owner = _msgSender();
        _signer = signer_;
        _systemAccount = systemAccount;
    }

    function _msgSender() internal view returns (address) {
        return ContextMixin.msgSender();
    }

    /**
     * @dev See {UUPSUpgradeable-_authorizeUpgrade}.
     */
    function _authorizeUpgrade(address) internal virtual override onlyOwnerOrAdmin {
        this;
    }

    function getImplementation() public view returns (address) {
        return _getImplementation(); 
    }

    function name() public view returns(string memory){
        return _name;
    }

    function version() public view returns(string memory){
        return _version;
    }

    modifier onlyOwnerOrAdmin() {
        require(_owner == _msgSender() || _accessControl.hasRole(ERC721Constants.DEFAULT_ADMIN_ROLE, _msgSender()), 
                ErrorCodes.INVALID_OWNER_OR_ADMIN);
        _;
    }

    modifier only(bytes32 role){
        require(_accessControl.hasRole(role, _msgSender()), ErrorCodes.INSUFFICIENT_PERMISSIONS);
        _;
    }

    function updateAccessControlContract(address accessControlContract_) public override onlyOwnerOrAdmin{
        require(accessControlContract_ != address(0), ErrorCodes.PF_ACCESS_CONTRACT_NULL);
        require(Address.isContract(accessControlContract_), ErrorCodes.INVALID_CONTRACT);
        _updateAccessControlContract(accessControlContract_);
    }

    function _updateAccessControlContract(address accessControlContract_) internal {
        _accessControlContract = accessControlContract_;
        _accessControl = IAccessControl(accessControlContract_);
    }

    function accessControlContract() public override view returns(address){
        return _accessControlContract;
    }

    function setVtokenContract(uint8 tokenSymbol, address vtokenContract) public override onlyOwnerOrAdmin {
        require(tokenSymbol == PaymentConstants.ETH 
               || tokenSymbol == PaymentConstants.USDC 
               || tokenSymbol == PaymentConstants.HEART, ErrorCodes.PF_INV_VTOKEN_SYBL);
        require(vtokenContract != address(0), ErrorCodes.PF_VTOKEN_ADDR_NULL);
        require(Address.isContract(vtokenContract), ErrorCodes.PF_INV_VTOKEN_ADDR);
        _setVtokenContract(tokenSymbol, vtokenContract);
    }

    function _setVtokenContract(uint8 tokenSymbol, address vtokenContract) internal {
        address prevAddr = _vtokenContractMap[tokenSymbol];
        _vtokenContractMap[tokenSymbol] = vtokenContract;
        emit VirtualTokenAddrUpdated(_msgSender(), prevAddr, vtokenContract);
    }

    function virtualTokenContract(uint8 tokenSymbol) public view override returns (address){
        require(_vtokenContractMap[tokenSymbol] != address(0), ErrorCodes.PF_VTOKEN_ADDR_NULL);
        return _vtokenContractMap[tokenSymbol];  
    }

    /**
     * @dev sets the signing account address for claim approvals.
     */
    function setSigner(address signer_) public onlyOwnerOrAdmin {
        _setSigner(signer_);
    }

    function _setSigner(address signer_) internal {
        require(signer_ != address(0), ErrorCodes.PF_SIGNER_ADDR_NULL);
        _signer = signer_;
    }

    function signer() public view returns (address) {
        return _signer;
    }

    /**
     * @dev this function executes the seated bulk purchase along with signature.
     */
    function seatedBulkOrder(BulkOrderFinal memory bulkOrderFinal, bytes32 r, bytes32 s, uint8 v) public override {
        _validateSeatedPurchases(bulkOrderFinal);
        _verifySignature(bulkOrderFinal, r, s, v);
        //flag the clOrdId as processed
        _processedOrderIds[bulkOrderFinal.clOrdId] =  true;
        IERC20 vtoken = IERC20(virtualTokenContract(bulkOrderFinal.tokenSymbol));
        _seatedPayment(bulkOrderFinal, vtoken);
    }

    /**
     * @dev this function verifies the signature for seated bulk purchases.
     */
    function _verifySignature(BulkOrderFinal memory bulkOrderFinal, bytes32 r, bytes32 s, uint8 v) internal view {
        //compute the signed data from the received parameters and type-hash
        bytes memory data = abi.encode(
            BULK_ORDER_TYPE_HASH,
            bulkOrderFinal.tokenSymbol,
            bulkOrderFinal.paidAmount,
            keccak256(bytes(bulkOrderFinal.clOrdId)),
            bulkOrderFinal.buyer,
            hashSeatBook(bulkOrderFinal.bulkOrders)
        );
        //verify the signer.
        require(EIP712.recover(_domainSeparator, v, r, s, data) == _signer, ErrorCodes.PF_INV_SIGNATURE);
    }

    function hashSeatBook(SeatBook[] memory bulkOrders) private pure returns (bytes32) {
        bytes32[] memory _array = new bytes32[](bulkOrders.length);
        for (uint256 i = 0; i < bulkOrders.length; ++i) {
            _array[i] = keccak256(abi.encode(
                            SEAT_BOOK_TYPE_HASH,
                            bulkOrders[i].assetAddress,
                            bulkOrders[i].seller,
                            hashSeatSelection(bulkOrders[i].seatNos),
                            bulkOrders[i].subtotal,
                            bulkOrders[i].tax,
                            bulkOrders[i].ccfee
                        ));
        }
        return keccak256(abi.encodePacked(_array));
    }

    function hashSeatSelection(SeatSelection[] memory seatSelection) private pure returns (bytes32) {
        bytes32[] memory _array_selection = new bytes32[](seatSelection.length);
        for (uint256 i = 0; i < seatSelection.length; ++i) {
            _array_selection[i] = keccak256(abi.encode(
                            SEAT_SELECTION_TYPE_HASH,
                            keccak256(bytes(seatSelection[i].section)),
                            keccak256(bytes(seatSelection[i].row)),
                            keccak256(bytes(seatSelection[i].seatno))
                        ));
        }
        return keccak256(abi.encodePacked(_array_selection));
    }
    /**
     * @dev internal function validates the seated ticketing request object
     */
    function _validateSeatedPurchases(BulkOrderFinal memory bulkOrderFinal) internal view {
        require(bytes(bulkOrderFinal.clOrdId).length > 0, ErrorCodes.PF_INV_CLORDID);
        require(bulkOrderFinal.tokenSymbol == PaymentConstants.ETH 
               || bulkOrderFinal.tokenSymbol == PaymentConstants.USDC 
               || bulkOrderFinal.tokenSymbol == PaymentConstants.HEART, ErrorCodes.PF_INV_VTOKEN_SYBL);
        require(_vtokenContractMap[bulkOrderFinal.tokenSymbol] != address(0), ErrorCodes.PF_VTOKEN_NOT_CONFIGURED);
        require(bulkOrderFinal.buyer != address(0), ErrorCodes.PF_BUYER_ADDR_NULL);
        require(_processedOrderIds[bulkOrderFinal.clOrdId] == false, ErrorCodes.PF_CLORDID_PROCSD);
        require(_msgSender() != _signer, ErrorCodes.PF_SIGNER_CAN_NOT_SUBMIT_TXN);
        require(bulkOrderFinal.bulkOrders.length > 0, ErrorCodes.PF_NO_PURCHASE_ENTRIES_FOUND);
    }
    /**
     * @dev internal function executes the payment for seated ticketing purchase
     */
    function _seatedPayment (BulkOrderFinal memory bulkOrderFinal, IERC20 vtoken) internal {
        uint256 sellerSettlement;
        uint256 yhSettlement;
        
        for(uint256 i = 0; i < bulkOrderFinal.bulkOrders.length; i++){
            require(bulkOrderFinal.bulkOrders[i].seller != address(0), ErrorCodes.PF_SELLER_ADDR_NULL);
            //initialize the asset contract & issue NFTs.
            IAssetPurchase assetPurchase = IAssetPurchase(bulkOrderFinal.bulkOrders[i].assetAddress);
            require(assetPurchase.getFeePayee(ERC721Constants.SELLER_FEE) == bulkOrderFinal.bulkOrders[i].seller, 
                    ErrorCodes.PF_SELLER_ADDR_NOT_MATCHED_WITH_ASSET_PAYEE);
            //calculate the fee
            uint256 yhfee = _calculateFee(assetPurchase.getFeeRate(), bulkOrderFinal.bulkOrders[i].subtotal);
            yhSettlement += yhfee;
            uint256 sellerPayment = (bulkOrderFinal.bulkOrders[i].subtotal).sub(yhfee);
            sellerSettlement += sellerPayment;
           
            uint256 total = bulkOrderFinal.bulkOrders[i].subtotal
                                .add(bulkOrderFinal.bulkOrders[i].tax)
                                .add(bulkOrderFinal.bulkOrders[i].ccfee);  
            if(total > 0){
                SafeERC20.safeTransferFrom(vtoken, bulkOrderFinal.buyer, address(this), total);
                //transfer seller's amount
                SafeERC20.safeTransferFrom(vtoken, address(this), bulkOrderFinal.bulkOrders[i].seller, sellerPayment);
                //transfer yh fee.
                if(yhfee > 0)
                    SafeERC20.safeTransferFrom(vtoken, address(this), _systemAccount, yhfee);
                if(bulkOrderFinal.bulkOrders[i].tax > 0){
                    SafeERC20.safeTransferFrom(vtoken, address(this), 
                        assetPurchase.getFeePayee(ERC721Constants.TAX_FEE) != address(0) ? 
                        assetPurchase.getFeePayee(ERC721Constants.TAX_FEE) : _systemAccount, bulkOrderFinal.bulkOrders[i].tax);
                }
                if(bulkOrderFinal.bulkOrders[i].ccfee > 0)
                    SafeERC20.safeTransferFrom(vtoken, address(this), 
                        assetPurchase.getFeePayee(ERC721Constants.CC_FEE) != address(0) ? 
                        assetPurchase.getFeePayee(ERC721Constants.CC_FEE) : _systemAccount, bulkOrderFinal.bulkOrders[i].ccfee);
            }
            
            //mints NFTs.
            string[] memory computedSeatNosToMint = new string[](bulkOrderFinal.bulkOrders[i].seatNos.length);
            for(uint256 k = 0; k < bulkOrderFinal.bulkOrders[i].seatNos.length; k++){
                computedSeatNosToMint[k] = string(bytes.concat(bytes(bulkOrderFinal.bulkOrders[i].seatNos[k].section), 
                                                "-", bytes(bulkOrderFinal.bulkOrders[i].seatNos[k].row),"-",
                                                bytes(bulkOrderFinal.bulkOrders[i].seatNos[k].seatno)));
            }
            assetPurchase.issueTokens(bulkOrderFinal.buyer, computedSeatNosToMint); 
        }
        emit OrderProcessed(_msgSender(),bulkOrderFinal.buyer,bulkOrderFinal.tokenSymbol, 
                            yhSettlement, sellerSettlement, bulkOrderFinal.clOrdId);
    }

    /**
     * @dev this function executes the seated bulk purchase permitted to admin or contract owner.
     */
    function seatedPurchaseWithOwnerOrAdmin(BulkOrderFinal memory bulkOrderFinal) public onlyOwnerOrAdmin {
        _validateSeatedPurchases(bulkOrderFinal);
        //flag the clOrdId as processed
        _processedOrderIds[bulkOrderFinal.clOrdId] =  true;
        IERC20 vtoken = IERC20(virtualTokenContract(bulkOrderFinal.tokenSymbol));
        _seatedPayment(bulkOrderFinal, vtoken);
    }

    function _calculateFee(uint256 feerate, uint256 amount) internal pure returns(uint256){
        return amount.mul(feerate).div(10000);
    }

    function updateSystemAccount(address systemAcc) public onlyOwnerOrAdmin {
        require(systemAcc != address(0), ErrorCodes.PF_SYSACC_ADDR_NULL);
        _systemAccount = systemAcc;
    }

    function getSystemAccount() public view returns(address){
        return _systemAccount;
    }

    /**
     * @dev this function executes the standard bulk purchase along with signature.
     */
    function standardBulkOrder(StandardPurchaseBulkOrder memory standardPurchaseBulkOrder,bytes32 r, bytes32 s, uint8 v) public override {
        _validateStandardPurchases(standardPurchaseBulkOrder);
        //initialize the asset contract & issue NFTs.
        IAssetPurchase assetPurchase = IAssetPurchase(standardPurchaseBulkOrder.assetAddress);
        require(assetPurchase.getFeePayee(ERC721Constants.SELLER_FEE) == standardPurchaseBulkOrder.seller, 
                ErrorCodes.PF_SELLER_ADDR_NOT_MATCHED_WITH_ASSET_PAYEE);
        _verifySignatureForStandardPurchase(standardPurchaseBulkOrder, r, s, v); 
        //flag the clOrdId as processed
        _processedOrderIds[standardPurchaseBulkOrder.clOrdId] =  true;
        IERC20 vtoken = IERC20(virtualTokenContract(standardPurchaseBulkOrder.tokenSymbol));
        _standardPayment(assetPurchase, vtoken, standardPurchaseBulkOrder);
    }

    /**
     * @dev this function verifies the signature for the standard bulk purchases.
     */
    function _verifySignatureForStandardPurchase(StandardPurchaseBulkOrder memory standardPurchaseBulkOrder, 
                bytes32 r, bytes32 s, uint8 v) internal view {
        //compute the signed data from the received parameters and type-hash
        bytes memory data = abi.encode(
            STANDARD_PURCHASE_TYPE_HASH,
            standardPurchaseBulkOrder.tokenSymbol,
            standardPurchaseBulkOrder.paidAmount,
            keccak256(bytes(standardPurchaseBulkOrder.clOrdId)),
            standardPurchaseBulkOrder.buyer,
            standardPurchaseBulkOrder.seller,
            standardPurchaseBulkOrder.assetAddress,
            standardPurchaseBulkOrder.numberOfTokens,
            standardPurchaseBulkOrder.subtotal,
            standardPurchaseBulkOrder.tax,
            standardPurchaseBulkOrder.ccfee
        );
        //verify the signer.
        require(EIP712.recover(_domainSeparator, v, r, s, data) == _signer, ErrorCodes.PF_INV_SIGNATURE);
    }

    /**
     * @dev this function validates the standard bulk purchase payload.
     */
    function _validateStandardPurchases(StandardPurchaseBulkOrder memory standardPurchaseBulkOrder) internal view{
        require(bytes(standardPurchaseBulkOrder.clOrdId).length > 0, ErrorCodes.PF_INV_CLORDID);
        uint256 total = standardPurchaseBulkOrder.subtotal.add(standardPurchaseBulkOrder.tax).add(standardPurchaseBulkOrder.ccfee);
        require(standardPurchaseBulkOrder.paidAmount == total, ErrorCodes.PF_INV_PAID_AMOUNT);
        require(standardPurchaseBulkOrder.tokenSymbol == PaymentConstants.ETH 
               || standardPurchaseBulkOrder.tokenSymbol == PaymentConstants.USDC 
               || standardPurchaseBulkOrder.tokenSymbol == PaymentConstants.HEART, ErrorCodes.PF_INV_VTOKEN_SYBL);
        require(_vtokenContractMap[standardPurchaseBulkOrder.tokenSymbol] != address(0), ErrorCodes.PF_VTOKEN_NOT_CONFIGURED);
        require(standardPurchaseBulkOrder.buyer != address(0), ErrorCodes.PF_BUYER_ADDR_NULL);
        require(standardPurchaseBulkOrder.seller != address(0), ErrorCodes.PF_SELLER_ADDR_NULL);
        require(_processedOrderIds[standardPurchaseBulkOrder.clOrdId] == false, ErrorCodes.PF_CLORDID_PROCSD);
        require(_msgSender() != _signer, ErrorCodes.PF_SIGNER_CAN_NOT_SUBMIT_TXN);
    }

    /**
     * @dev this function executes the payment for the standard bulk purchases. 
     */
    function _standardPayment(IAssetPurchase assetPurchase, IERC20 vtoken, 
        StandardPurchaseBulkOrder memory standardPurchaseBulkOrder) internal {
        //calculate the fee
        uint256 yhSettlement = _calculateFee(assetPurchase.getFeeRate(), standardPurchaseBulkOrder.subtotal);
        uint256 sellerSettlement = (standardPurchaseBulkOrder.subtotal).sub(yhSettlement);
        if(standardPurchaseBulkOrder.paidAmount > 0){
            SafeERC20.safeTransferFrom(vtoken, standardPurchaseBulkOrder.buyer, address(this), standardPurchaseBulkOrder.paidAmount);
            //transfer seller's amount
            SafeERC20.safeTransferFrom(vtoken, address(this), standardPurchaseBulkOrder.seller, sellerSettlement);
            //transfer yh fee.
            if(yhSettlement > 0)
                SafeERC20.safeTransferFrom(vtoken, address(this), _systemAccount, yhSettlement);
            address taxPayee = assetPurchase.getFeePayee(ERC721Constants.TAX_FEE);
            address ccPayee = assetPurchase.getFeePayee(ERC721Constants.CC_FEE);
            if(standardPurchaseBulkOrder.tax > 0)
                SafeERC20.safeTransferFrom(vtoken, address(this), 
                        taxPayee != address(0) ? 
                        taxPayee : _systemAccount, standardPurchaseBulkOrder.tax);
            if(standardPurchaseBulkOrder.ccfee > 0)
                SafeERC20.safeTransferFrom(vtoken, address(this), 
                        ccPayee != address(0) ? 
                        ccPayee : _systemAccount, standardPurchaseBulkOrder.ccfee);
        }
        //mints NFTs.
        assetPurchase.bulkMint(standardPurchaseBulkOrder.buyer, standardPurchaseBulkOrder.numberOfTokens); 
        emit OrderProcessed(_msgSender(),standardPurchaseBulkOrder.buyer,standardPurchaseBulkOrder.tokenSymbol, 
                            yhSettlement, sellerSettlement, standardPurchaseBulkOrder.clOrdId);
    }

    /**
     * @dev this function executes the standard bulk purchase permitted to admin or contract owner
     */
    function standardPurchaseWithOwnerOrAdmin(StandardPurchaseBulkOrder memory standardPurchaseBulkOrder) public onlyOwnerOrAdmin {
        _validateStandardPurchases(standardPurchaseBulkOrder);
        //initialize the asset contract & issue NFTs.
        IAssetPurchase assetPurchase = IAssetPurchase(standardPurchaseBulkOrder.assetAddress);
        require(assetPurchase.getFeePayee(ERC721Constants.SELLER_FEE) == standardPurchaseBulkOrder.seller, 
                ErrorCodes.PF_SELLER_ADDR_NOT_MATCHED_WITH_ASSET_PAYEE);
        //flag the clOrdId as processed
        _processedOrderIds[standardPurchaseBulkOrder.clOrdId] =  true;
        IERC20 vtoken = IERC20(virtualTokenContract(standardPurchaseBulkOrder.tokenSymbol));
        _standardPayment(assetPurchase, vtoken, standardPurchaseBulkOrder);
    }

    uint256[39] private __gap;
}