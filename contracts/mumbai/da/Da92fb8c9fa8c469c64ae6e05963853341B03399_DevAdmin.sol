//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "../interfaces/INFT.sol";
import "../libraries/MapperStorage.sol";
import "../libraries/NodesStorage.sol";
import "../libraries/nodes/VehicleStorage.sol";
import "../libraries/nodes/AftermarketDeviceStorage.sol";

import {DEFAULT_ADMIN_ROLE} from "../shared/Roles.sol";

import "@solidstate/contracts/access/access_control/AccessControlInternal.sol";

/// @dev Admin module for development and testing
contract DevAdmin is AccessControlInternal {
    event AftermarketDeviceUnclaimed(uint256 indexed aftermarketDeviceNode);
    event AftermarketDeviceTransferred(
        uint256 indexed aftermarketDeviceNode,
        address indexed oldOwner,
        address indexed newOwner
    );
    event AftermarketDeviceUnpaired(
        uint256 indexed aftermarketDeviceNode,
        uint256 indexed vehicleNode,
        address indexed owner
    );

    /// @dev Transfers the ownership of an afermarket device
    /// @dev Caller must have the admin role
    /// @param aftermarketDeviceNode Aftermarket device node id
    /// @param newOwner The address of the new owner
    function transferAftermarketDeviceOwnership(
        uint256 aftermarketDeviceNode,
        address newOwner
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        // TODO check not tyep ?
        // require(
        //     NodesStorage.getStorage().nodes[aftermarketDeviceNode].nodeType ==
        //         AftermarketDeviceStorage.getStorage().nodeType,
        //     "Invalid AD node"
        // );
        INFT adNftProxy = INFT(
            AftermarketDeviceStorage.getStorage().nftProxyAddress
        );
        address oldOwner = adNftProxy.ownerOf(aftermarketDeviceNode);

        adNftProxy.safeTransferFrom(oldOwner, newOwner, aftermarketDeviceNode);

        emit AftermarketDeviceTransferred(
            aftermarketDeviceNode,
            oldOwner,
            newOwner
        );
    }

    /// @dev Sets deviceClaimed to false for each aftermarket device
    /// @dev Caller must have the admin role
    /// @param aftermarketDeviceNodes Array of aftermarket device node ids
    function unclaimAftermarketDeviceNode(
        uint256[] calldata aftermarketDeviceNodes
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        AftermarketDeviceStorage.Storage storage ads = AftermarketDeviceStorage
            .getStorage();

        uint256 _adNode;
        for (uint256 i = 0; i < aftermarketDeviceNodes.length; i++) {
            _adNode = aftermarketDeviceNodes[i];

            ads.deviceClaimed[_adNode] = false;

            emit AftermarketDeviceUnclaimed(_adNode);
        }
    }

    /// @dev Unpairs a list of aftermarket device from their respective vehicles by the device node
    /// @dev Caller must have the admin role
    /// @param aftermarketDeviceNodes Array of aftermarket device node ids
    function unpairAftermarketDeviceByDeviceNode(
        uint256[] calldata aftermarketDeviceNodes
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        // NodesStorage.Storage storage ns = NodesStorage.getStorage();
        MapperStorage.Storage storage ms = MapperStorage.getStorage();
        address vehicleNftProxyAddress = VehicleStorage
            .getStorage()
            .nftProxyAddress;
        address adNftProxyAddress = AftermarketDeviceStorage
            .getStorage()
            .nftProxyAddress;

        uint256 _adNode;
        uint256 _vehicleNode;
        for (uint256 i = 0; i < aftermarketDeviceNodes.length; i++) {
            _adNode = aftermarketDeviceNodes[i];

            // TODO check node type ?
            // require(
            //     ns.nodes[_adNode].nodeType ==
            //         AftermarketDeviceStorage.getStorage().nodeType,
            //     "Invalid AD node"
            // );

            _vehicleNode = ms.links[adNftProxyAddress][_adNode];

            ms.links[vehicleNftProxyAddress][_vehicleNode] = 0;
            ms.links[adNftProxyAddress][_adNode] = 0;

            emit AftermarketDeviceUnpaired(
                _adNode,
                _vehicleNode,
                INFT(adNftProxyAddress).ownerOf(_adNode)
            );
        }
    }

    /// @dev Unpairs a list of aftermarket devices from their respective vehicles by the vehicle node ids
    /// @dev Caller must have the admin role
    /// @param vehicleNodes Array of vehicle node id
    function unpairAftermarketDeviceByVehicleNode(
        uint256[] calldata vehicleNodes
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        // NodesStorage.Storage storage ns = NodesStorage.getStorage();
        MapperStorage.Storage storage ms = MapperStorage.getStorage();
        address vehicleNftProxyAddress = VehicleStorage
            .getStorage()
            .nftProxyAddress;
        address adNftProxyAddress = AftermarketDeviceStorage
            .getStorage()
            .nftProxyAddress;

        uint256 _adNode;
        uint256 _vehicleNode;
        for (uint256 i = 0; i < vehicleNodes.length; i++) {
            _vehicleNode = vehicleNodes[i];

            // TODO check node type ?
            // require(
            //     ns.nodes[_vehicleNode].nodeType ==
            //         VehicleStorage.getStorage().nodeType,
            //     "Invalid vehicle node"
            // );

            _adNode = ms.links[vehicleNftProxyAddress][_vehicleNode];

            ms.links[vehicleNftProxyAddress][_vehicleNode] = 0;
            ms.links[adNftProxyAddress][_adNode] = 0;

            emit AftermarketDeviceUnpaired(
                _adNode,
                _vehicleNode,
                INFT(vehicleNftProxyAddress).ownerOf(_vehicleNode)
            );
        }
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

// TODO Documentation
interface INFT {
    function safeMint(address to) external returns (uint256);

    function safeTransferByRegistry(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function setApprovalForAll(address operator, bool _approved) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

library MapperStorage {
    bytes32 internal constant MAPPER_STORAGE_SLOT =
        keccak256("DIMORegistry.mapper.storage");

    struct Storage {
        mapping(address => mapping(uint256 => uint256)) links;
    }

    /* solhint-disable no-inline-assembly */
    function getStorage() internal pure returns (Storage storage s) {
        bytes32 slot = MAPPER_STORAGE_SLOT;
        assembly {
            s.slot := slot
        }
    }
    /* solhint-enable no-inline-assembly */
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

library NodesStorage {
    bytes32 internal constant NODES_STORAGE_SLOT =
        keccak256("DIMORegistry.nodes.storage");

    struct Node {
        // TODO add info to the parent node type
        address nftProxyAddress; // TODO Redundant ?
        uint256 parentNode;
        mapping(string => string) info;
    }

    struct Storage {
        mapping(address => mapping(uint256 => Node)) nodes;
    }

    /* solhint-disable no-inline-assembly */
    function getStorage() internal pure returns (Storage storage s) {
        bytes32 slot = NODES_STORAGE_SLOT;
        assembly {
            s.slot := slot
        }
    }
    /* solhint-enable no-inline-assembly */
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "../AttributeSet.sol";

library VehicleStorage {
    using AttributeSet for AttributeSet.Set;

    bytes32 private constant VEHICLE_STORAGE_SLOT =
        keccak256("DIMORegistry.vehicle.storage");

    struct Storage {
        address nftProxyAddress;
        // Allowed node attribute
        AttributeSet.Set whitelistedAttributes;
    }

    /* solhint-disable no-inline-assembly */
    function getStorage() internal pure returns (Storage storage s) {
        bytes32 slot = VEHICLE_STORAGE_SLOT;
        assembly {
            s.slot := slot
        }
    }
    /* solhint-enable no-inline-assembly */
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "../AttributeSet.sol";

library AftermarketDeviceStorage {
    using AttributeSet for AttributeSet.Set;

    bytes32 private constant AFTERMARKET_DEVICE_STORAGE_SLOT =
        keccak256("DIMORegistry.aftermarketDevice.storage");

    struct Storage {
        address nftProxyAddress;
        // Allowed node attribute
        AttributeSet.Set whitelistedAttributes;
        // AD Id => already claimed or not
        mapping(uint256 => bool) deviceClaimed;
        // AD address => AD Id
        mapping(address => uint256) deviceAddressToNodeId;
        // AD Id => AD address
        mapping(uint256 => address) nodeIdToDeviceAddress;
    }

    /* solhint-disable no-inline-assembly */
    function getStorage() internal pure returns (Storage storage s) {
        bytes32 slot = AFTERMARKET_DEVICE_STORAGE_SLOT;
        assembly {
            s.slot := slot
        }
    }
    /* solhint-enable no-inline-assembly */
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

bytes32 constant DEFAULT_ADMIN_ROLE = 0x00;
bytes32 constant MINTER_ROLE = keccak256("Minter");
bytes32 constant MANUFACTURER_ROLE = keccak256("Manufacturer");

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { EnumerableSet } from '../../data/EnumerableSet.sol';
import { AddressUtils } from '../../utils/AddressUtils.sol';
import { UintUtils } from '../../utils/UintUtils.sol';
import { IAccessControlInternal } from './IAccessControlInternal.sol';
import { AccessControlStorage } from './AccessControlStorage.sol';

/**
 * @title Role-based access control system
 * @dev derived from https://github.com/OpenZeppelin/openzeppelin-contracts (MIT license)
 */
abstract contract AccessControlInternal is IAccessControlInternal {
    using AddressUtils for address;
    using EnumerableSet for EnumerableSet.AddressSet;
    using UintUtils for uint256;

    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /*
     * @notice query whether role is assigned to account
     * @param role role to query
     * @param account account to query
     * @return whether role is assigned to account
     */
    function _hasRole(bytes32 role, address account)
        internal
        view
        virtual
        returns (bool)
    {
        return
            AccessControlStorage.layout().roles[role].members.contains(account);
    }

    /**
     * @notice revert if sender does not have given role
     * @param role role to query
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, msg.sender);
    }

    /**
     * @notice revert if given account does not have given role
     * @param role role to query
     * @param account to query
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!_hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        'AccessControl: account ',
                        account.toString(),
                        ' is missing role ',
                        uint256(role).toHexString(32)
                    )
                )
            );
        }
    }

    /*
     * @notice query admin role for given role
     * @param role role to query
     * @return admin role
     */
    function _getRoleAdmin(bytes32 role)
        internal
        view
        virtual
        returns (bytes32)
    {
        return AccessControlStorage.layout().roles[role].adminRole;
    }

    /**
     * @notice set role as admin role
     * @param role role to set
     * @param adminRole admin role to set
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = _getRoleAdmin(role);
        AccessControlStorage.layout().roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /*
     * @notice assign role to given account
     * @param role role to assign
     * @param account recipient of role assignment
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        AccessControlStorage.layout().roles[role].members.add(account);
        emit RoleGranted(role, account, msg.sender);
    }

    /*
     * @notice unassign role from given account
     * @param role role to unassign
     * @parm account
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        AccessControlStorage.layout().roles[role].members.remove(account);
        emit RoleRevoked(role, account, msg.sender);
    }

    /**
     * @notice relinquish role
     * @param role role to relinquish
     */
    function _renounceRole(bytes32 role) internal virtual {
        _revokeRole(role, msg.sender);
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

/// @dev derived from https://github.com/OpenZeppelin/openzeppelin-contracts (MIT license)

library AttributeSet {
    struct Set {
        string[] _values;
        mapping(string => uint256) _indexes;
    }

    function add(Set storage set, string calldata key) internal returns (bool) {
        if (!exists(set, key)) {
            set._values.push(key);
            set._indexes[key] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    function remove(Set storage set, string calldata key)
        internal
        returns (bool)
    {
        uint256 valueIndex = set._indexes[key];

        if (valueIndex != 0) {
            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                string memory lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[key];

            return true;
        } else {
            return false;
        }
    }

    function count(Set storage set) internal view returns (uint256) {
        return (set._values.length);
    }

    function exists(Set storage set, string calldata key)
        internal
        view
        returns (bool)
    {
        return set._indexes[key] != 0;
    }

    function getIndex(Set storage set, string calldata key)
        internal
        returns (uint256)
    {
        return set._indexes[key];
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/**
 * @title Set implementation with enumeration functions
 * @dev derived from https://github.com/OpenZeppelin/openzeppelin-contracts (MIT license)
 */
library EnumerableSet {
    error EnumerableSet__IndexOutOfBounds();

    struct Set {
        bytes32[] _values;
        // 1-indexed to allow 0 to signify nonexistence
        mapping(bytes32 => uint256) _indexes;
    }

    struct Bytes32Set {
        Set _inner;
    }

    struct AddressSet {
        Set _inner;
    }

    struct UintSet {
        Set _inner;
    }

    function at(Bytes32Set storage set, uint256 index)
        internal
        view
        returns (bytes32)
    {
        return _at(set._inner, index);
    }

    function at(AddressSet storage set, uint256 index)
        internal
        view
        returns (address)
    {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    function at(UintSet storage set, uint256 index)
        internal
        view
        returns (uint256)
    {
        return uint256(_at(set._inner, index));
    }

    function contains(Bytes32Set storage set, bytes32 value)
        internal
        view
        returns (bool)
    {
        return _contains(set._inner, value);
    }

    function contains(AddressSet storage set, address value)
        internal
        view
        returns (bool)
    {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    function contains(UintSet storage set, uint256 value)
        internal
        view
        returns (bool)
    {
        return _contains(set._inner, bytes32(value));
    }

    function indexOf(Bytes32Set storage set, bytes32 value)
        internal
        view
        returns (uint256)
    {
        return _indexOf(set._inner, value);
    }

    function indexOf(AddressSet storage set, address value)
        internal
        view
        returns (uint256)
    {
        return _indexOf(set._inner, bytes32(uint256(uint160(value))));
    }

    function indexOf(UintSet storage set, uint256 value)
        internal
        view
        returns (uint256)
    {
        return _indexOf(set._inner, bytes32(value));
    }

    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function add(Bytes32Set storage set, bytes32 value)
        internal
        returns (bool)
    {
        return _add(set._inner, value);
    }

    function add(AddressSet storage set, address value)
        internal
        returns (bool)
    {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    function remove(Bytes32Set storage set, bytes32 value)
        internal
        returns (bool)
    {
        return _remove(set._inner, value);
    }

    function remove(AddressSet storage set, address value)
        internal
        returns (bool)
    {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    function remove(UintSet storage set, uint256 value)
        internal
        returns (bool)
    {
        return _remove(set._inner, bytes32(value));
    }

    function toArray(Bytes32Set storage set)
        internal
        view
        returns (bytes32[] memory)
    {
        uint256 len = _length(set._inner);
        bytes32[] memory arr = new bytes32[](len);

        unchecked {
            for (uint256 index; index < len; ++index) {
                arr[index] = at(set, index);
            }
        }

        return arr;
    }

    function toArray(AddressSet storage set)
        internal
        view
        returns (address[] memory)
    {
        uint256 len = _length(set._inner);
        address[] memory arr = new address[](len);

        unchecked {
            for (uint256 index; index < len; ++index) {
                arr[index] = at(set, index);
            }
        }

        return arr;
    }

    function toArray(UintSet storage set)
        internal
        view
        returns (uint256[] memory)
    {
        uint256 len = _length(set._inner);
        uint256[] memory arr = new uint256[](len);

        unchecked {
            for (uint256 index; index < len; ++index) {
                arr[index] = at(set, index);
            }
        }

        return arr;
    }

    function _at(Set storage set, uint256 index)
        private
        view
        returns (bytes32)
    {
        if (index >= set._values.length)
            revert EnumerableSet__IndexOutOfBounds();
        return set._values[index];
    }

    function _contains(Set storage set, bytes32 value)
        private
        view
        returns (bool)
    {
        return set._indexes[value] != 0;
    }

    function _indexOf(Set storage set, bytes32 value)
        private
        view
        returns (uint256)
    {
        unchecked {
            return set._indexes[value] - 1;
        }
    }

    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    function _remove(Set storage set, bytes32 value) private returns (bool) {
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            unchecked {
                bytes32 last = set._values[set._values.length - 1];

                // move last value to now-vacant index

                set._values[valueIndex - 1] = last;
                set._indexes[last] = valueIndex;
            }
            // clear last index

            set._values.pop();
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { UintUtils } from './UintUtils.sol';

library AddressUtils {
    using UintUtils for uint256;

    error AddressUtils__InsufficientBalance();
    error AddressUtils__NotContract();
    error AddressUtils__SendValueFailed();

    function toString(address account) internal pure returns (string memory) {
        return uint256(uint160(account)).toHexString(20);
    }

    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function sendValue(address payable account, uint256 amount) internal {
        (bool success, ) = account.call{ value: amount }('');
        if (!success) revert AddressUtils__SendValueFailed();
    }

    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionCall(target, data, 'AddressUtils: failed low-level call');
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory error
    ) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, error);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                'AddressUtils: failed low-level call with value'
            );
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory error
    ) internal returns (bytes memory) {
        if (value > address(this).balance)
            revert AddressUtils__InsufficientBalance();
        return _functionCallWithValue(target, data, value, error);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory error
    ) private returns (bytes memory) {
        if (!isContract(target)) revert AddressUtils__NotContract();

        (bool success, bytes memory returnData) = target.call{ value: value }(
            data
        );

        if (success) {
            return returnData;
        } else if (returnData.length > 0) {
            assembly {
                let returnData_size := mload(returnData)
                revert(add(32, returnData), returnData_size)
            }
        } else {
            revert(error);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/**
 * @title utility functions for uint256 operations
 * @dev derived from https://github.com/OpenZeppelin/openzeppelin-contracts/ (MIT license)
 */
library UintUtils {
    error UintUtils__InsufficientHexLength();

    bytes16 private constant HEX_SYMBOLS = '0123456789abcdef';

    function add(uint256 a, int256 b) internal pure returns (uint256) {
        return b < 0 ? sub(a, -b) : a + uint256(b);
    }

    function sub(uint256 a, int256 b) internal pure returns (uint256) {
        return b < 0 ? add(a, -b) : a - uint256(b);
    }

    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return '0';
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

    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return '0x00';
        }

        uint256 length = 0;

        for (uint256 temp = value; temp != 0; temp >>= 8) {
            unchecked {
                length++;
            }
        }

        return toHexString(value, length);
    }

    function toHexString(uint256 value, uint256 length)
        internal
        pure
        returns (string memory)
    {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = '0';
        buffer[1] = 'x';

        unchecked {
            for (uint256 i = 2 * length + 1; i > 1; --i) {
                buffer[i] = HEX_SYMBOLS[value & 0xf];
                value >>= 4;
            }
        }

        if (value != 0) revert UintUtils__InsufficientHexLength();

        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Partial AccessControl interface needed by internal functions
 */
interface IAccessControlInternal {
    event RoleAdminChanged(
        bytes32 indexed role,
        bytes32 indexed previousAdminRole,
        bytes32 indexed newAdminRole
    );

    event RoleGranted(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );

    event RoleRevoked(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { EnumerableSet } from '../../data/EnumerableSet.sol';

library AccessControlStorage {
    struct RoleData {
        EnumerableSet.AddressSet members;
        bytes32 adminRole;
    }

    struct Layout {
        mapping(bytes32 => RoleData) roles;
    }

    bytes32 internal constant DEFAULT_ADMIN_ROLE = 0x00;

    bytes32 internal constant STORAGE_SLOT =
        keccak256('solidstate.contracts.storage.AccessControl');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}