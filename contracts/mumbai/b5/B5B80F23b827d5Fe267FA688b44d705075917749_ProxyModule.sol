// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/structs/EnumerableSet.sol)

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
 */
library EnumerableSet {
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
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
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

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;
import {
    EnumerableSet
} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {LibDataTypes} from "./libraries/LibDataTypes.sol";

/**
 * @notice Storage layout of Ops smart contract.
 */
// solhint-disable max-states-count
abstract contract OpsStorage {
    mapping(bytes32 => address) public taskCreator; ///@dev Deprecated
    mapping(bytes32 => address) public execAddresses; ///@dev Deprecated
    mapping(address => EnumerableSet.Bytes32Set) internal _createdTasks;

    uint256 public fee;
    address public feeToken;

    ///@dev Appended State
    mapping(bytes32 => LibDataTypes.Time) public timedTask;
    mapping(LibDataTypes.Module => address) public taskModuleAddresses;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import {GelatoBytes} from "../vendor/gelato/GelatoBytes.sol";

// solhint-disable private-vars-leading-underscore
// solhint-disable func-visibility

function _call(
    address _add,
    bytes memory _data,
    uint256 _value,
    bool _revertOnFailure,
    string memory _tracingInfo
) returns (bool success, bytes memory returnData) {
    (success, returnData) = _add.call{value: _value}(_data);

    if (!success && _revertOnFailure)
        GelatoBytes.revertWithError(returnData, _tracingInfo);
}

function _delegateCall(
    address _add,
    bytes memory _data,
    string memory _tracingInfo
) returns (bool success, bytes memory returnData) {
    (success, returnData) = _add.delegatecall(_data);

    if (!success) GelatoBytes.revertWithError(returnData, _tracingInfo);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

interface IOpsProxy {
    /**
     * @notice Emitted when proxy calls a contract successfully in `executeCall`
     *
     * @param target Address of contract that is called
     * @param data Data used in the call.
     * @param value Native token value used in the call.
     * @param returnData Data returned by the call.
     */
    event ExecuteCall(
        address indexed target,
        bytes data,
        uint256 value,
        bytes returnData
    );

    /**
     * @notice Multicall to different contracts with different datas.
     *
     * @param targets Addresses of contracts to be called.
     * @param datas Datas for each contract call.
     * @param values Native token value for each contract call.
     */
    function batchExecuteCall(
        address[] calldata targets,
        bytes[] calldata datas,
        uint256[] calldata values
    ) external payable;

    /**
     * @notice Call to a single contract.
     *
     * @param target Address of contracts to be called.
     * @param data Data for contract call.
     * @param value Native token value for contract call.
     */
    function executeCall(
        address target,
        bytes calldata data,
        uint256 value
    ) external payable;

    /**
     * @return address Ops smart contract address
     */
    function ops() external view returns (address);

    /**
     * @return address Owner of the proxy
     */
    function owner() external view returns (address);

    /**
     * @return uint256 version of OpsProxy.
     */
    function version() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

interface IOpsProxyFactory {
    /**
     * @notice Emitted when an OpsProxy is deployed.
     *
     * @param deployer Address which initiated the deployment
     * @param owner The address which the proxy is for.
     * @param seed Seed used for deployment.
     * @param salt Salt used for deployment.
     * @param proxy Address of deployed proxy.
     */
    event DeployProxy(
        address indexed deployer,
        address indexed owner,
        bytes32 seed,
        bytes32 salt,
        address proxy
    );

    /**
     * @notice Deploys OpsProxy for the msg.sender.
     *
     * @return proxy Address of deployed proxy.
     */
    function deploy() external returns (address payable proxy);

    /**
     * @notice Deploys OpsProxy for another address.
     *
     * @param owner Address to deploy the proxy for.
     *
     * @return proxy Address of deployed proxy.
     */
    function deployFor(address owner) external returns (address payable proxy);

    /**
     * @notice Determines the OpsProxy address when it is not deployed.
     *
     * @param account Address to determine the proxy address for.
     */
    function determineProxyAddress(address account)
        external
        view
        returns (address);

    /**
     * @return bytes32 Next seed which will be used for deployment for an address.
     */
    function getNextSeed(address account) external view returns (bytes32);

    /**
     * @return address Proxy address owned by account.
     * @return bool Whether if proxy is deployed
     */
    function getProxyOf(address account) external view returns (address, bool);

    /**
     * @return address Owner of deployed proxy.
     */
    function getOwnerOf(address proxy) external view returns (address);

    /**
     * @return bool Whether if a contract is an OpsProxy.
     */
    function isProxy(address proxy) external view returns (bool);

    /**
     * @return uint256 version of OpsProxyFactory.
     */
    function version() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

// solhint-disable max-line-length
interface ITaskModule {
    /**
     * @notice Called before generating taskId.
     * @dev Modules can override execAddress or taskCreator. {See ProxyModule-preCreateTask}
     *
     * @param taskCreator The address which created the task.
     * @param execAddress Address of contract that should be called.
     *
     * @return address Overriden or original taskCreator.
     * @return address Overriden or original execAddress.
     */
    function preCreateTask(address taskCreator, address execAddress)
        external
        returns (address, address);

    /**
     * @notice Initiates task module whenever `createTask` is being called.
     *
     * @param taskId Unique hash of the task created.
     * @param taskCreator The address which created the task.
     * @param execAddress Address of contract that should be called.
     * @param execData Execution data to be called with / function selector if execution data is yet to be determined.
     * @param initModuleArg Encoded arguments for module if any.
     */
    function onCreateTask(
        bytes32 taskId,
        address taskCreator,
        address execAddress,
        bytes calldata execData,
        bytes calldata initModuleArg
    ) external;

    /**
     * @notice Called before taskId is removed from _createdTasks[].
     * @dev Modules can override taskCreator.
     *
     * @param taskId Unique hash of the task created.
     * @param taskCreator The address which created the task.
     *
     * @return address Overriden or original taskCreator.
     */
    function preCancelTask(bytes32 taskId, address taskCreator)
        external
        returns (address);

    /**
     * @notice Called during `exec` and before execAddress is called.
     *
     * @param taskId Unique hash of the task created.
     * @param taskCreator The address which created the task.
     * @param execAddress Address of contract that should be called.
     * @param execData Execution data to be called with / function selector if execution data is yet to be determined.
     *
     * @return address Overriden or original execution address.
     * @return bytes Overriden or original execution data.
     */
    function preExecCall(
        bytes32 taskId,
        address taskCreator,
        address execAddress,
        bytes calldata execData
    ) external returns (address, bytes memory);

    /**
     * @notice Called during `exec` and after execAddress is called.
     *
     * @param taskId Unique hash of the task created.
     * @param taskCreator The address which created the task.
     * @param execAddress Address of contract that should be called.
     * @param execData Execution data to be called with / function selector if execution data is yet to be determined.
     */
    function postExecCall(
        bytes32 taskId,
        address taskCreator,
        address execAddress,
        bytes calldata execData
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

// solhint-disable max-line-length
library LibDataTypes {
    /**
     * @notice Whitelisted modules that are available for users to customise conditions and specifications of their tasks.
     *
     * @param RESOLVER Use dynamic condition & input data for execution. {See ResolverModule.sol}
     * @param TIME Repeated execution of task at a specified timing and interval. {See TimeModule.sol}
     * @param PROXY Creates a dedicated caller (msg.sender) to be used when executing the task. {See ProxyModule.sol}
     * @param SINGLE_EXEC Task is cancelled after one execution. {See SingleExecModule.sol}
     */
    enum Module {
        RESOLVER,
        TIME,
        PROXY,
        SINGLE_EXEC
    }

    /**
     * @notice Struct to contain modules and their relative arguments that are used for task creation.
     *
     * @param modules List of selected modules.
     * @param args Arguments of modules if any. Pass "0x" for modules which does not require args {See encodeModuleArg}
     */
    struct ModuleData {
        Module[] modules;
        bytes[] args;
    }

    /**
     * @notice Struct for time module.
     *
     * @param nextExec Time when the next execution should occur.
     * @param interval Time interval between each execution.
     */
    struct Time {
        uint128 nextExec;
        uint128 interval;
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.12;

import {GelatoBytes} from "../vendor/gelato/GelatoBytes.sol";
import {TaskModuleBase} from "./TaskModuleBase.sol";
import {LibDataTypes} from "../libraries/LibDataTypes.sol";
import {IOpsProxy} from "../interfaces/IOpsProxy.sol";
import {IOpsProxyFactory} from "../interfaces/IOpsProxyFactory.sol";

contract ProxyModule is TaskModuleBase {
    using GelatoBytes for bytes;

    IOpsProxyFactory public immutable opsProxyFactory;

    constructor(IOpsProxyFactory _opsProxyFactory) {
        opsProxyFactory = _opsProxyFactory;
    }

    /**
     * @inheritdoc TaskModuleBase
     */
    function onCreateTask(
        bytes32,
        address _taskCreator,
        address,
        bytes calldata,
        bytes calldata
    ) external override {
        _deployIfNoProxy(_taskCreator);
    }

    /**
     * @inheritdoc TaskModuleBase
     * @dev _taskCreator cannot create task to other user's proxy
     */
    function preCreateTask(address _taskCreator, address _execAddress)
        external
        view
        override
        returns (address, address)
    {
        bool isExecAddressProxy = opsProxyFactory.isProxy(_execAddress);

        if (isExecAddressProxy) {
            address ownerOfExecAddress = opsProxyFactory.getOwnerOf(
                _execAddress
            );
            require(
                _taskCreator == ownerOfExecAddress ||
                    _taskCreator == _execAddress,
                "ProxyModule: Only owner of proxy"
            );

            return (ownerOfExecAddress, _execAddress);
        } else {
            bool isTaskCreatorProxy = opsProxyFactory.isProxy(_taskCreator);

            if (isTaskCreatorProxy) {
                address ownerOfTaskCreator = opsProxyFactory.getOwnerOf(
                    _taskCreator
                );

                return (ownerOfTaskCreator, _execAddress);
            }

            return (_taskCreator, _execAddress);
        }
    }

    function preCancelTask(bytes32, address _taskCreator)
        external
        view
        override
        returns (address)
    {
        bool isTaskCreatorProxy = opsProxyFactory.isProxy(_taskCreator);

        if (isTaskCreatorProxy) {
            address ownerOfTaskCreator = opsProxyFactory.getOwnerOf(
                _taskCreator
            );

            return ownerOfTaskCreator;
        }

        return _taskCreator;
    }

    /**
     * @inheritdoc TaskModuleBase
     * @dev _execData is encoded with proxy's `executeCall` function
     * unless _execAddress is OpsProxy which assumes that _execData is encoded
     * with `executeCall` or `batchExecuteCall`.
     */
    function preExecCall(
        bytes32,
        address _taskCreator,
        address _execAddress,
        bytes calldata _execData
    ) external view override returns (address, bytes memory execData) {
        (address proxy, ) = opsProxyFactory.getProxyOf(_taskCreator);

        execData = _execAddress == proxy
            ? _execData
            : _encodeWithOpsProxy(_execAddress, _execData);

        _execAddress = proxy;

        return (_execAddress, execData);
    }

    function _deployIfNoProxy(address _taskCreator) private {
        bool isTaskCreatorProxy = opsProxyFactory.isProxy(_taskCreator);

        if (!isTaskCreatorProxy) {
            (, bool deployed) = opsProxyFactory.getProxyOf(_taskCreator);
            if (!deployed) opsProxyFactory.deployFor(_taskCreator);
        }
    }

    function _encodeWithOpsProxy(address _execAddress, bytes calldata _execData)
        private
        pure
        returns (bytes memory)
    {
        return
            abi.encodeWithSelector(
                IOpsProxy.executeCall.selector,
                _execAddress,
                _execData,
                0
            );
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.12;

import {OpsStorage} from "../OpsStorage.sol";
import {_call} from "../functions/FExec.sol";
import {ITaskModule} from "../interfaces/ITaskModule.sol";

// solhint-disable no-empty-blocks
abstract contract TaskModuleBase is OpsStorage, ITaskModule {
    ///@inheritdoc ITaskModule
    function preCreateTask(address, address)
        external
        virtual
        override
        returns (address, address)
    {}

    ///@inheritdoc ITaskModule
    function onCreateTask(
        bytes32,
        address,
        address,
        bytes calldata,
        bytes calldata
    ) external virtual override {}

    ///@inheritdoc ITaskModule
    function preCancelTask(bytes32, address)
        external
        virtual
        override
        returns (address)
    {}

    ///@inheritdoc ITaskModule
    function preExecCall(
        bytes32,
        address,
        address _execAddress,
        bytes calldata _execData
    ) external virtual override returns (address, bytes memory) {
        return (_execAddress, _execData);
    }

    ///@inheritdoc ITaskModule
    function postExecCall(
        bytes32 taskId,
        address taskCreator,
        address execAddress,
        bytes calldata execData
    ) external virtual override {}
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

library GelatoBytes {
    function calldataSliceSelector(bytes calldata _bytes)
        internal
        pure
        returns (bytes4 selector)
    {
        selector =
            _bytes[0] |
            (bytes4(_bytes[1]) >> 8) |
            (bytes4(_bytes[2]) >> 16) |
            (bytes4(_bytes[3]) >> 24);
    }

    function memorySliceSelector(bytes memory _bytes)
        internal
        pure
        returns (bytes4 selector)
    {
        selector =
            _bytes[0] |
            (bytes4(_bytes[1]) >> 8) |
            (bytes4(_bytes[2]) >> 16) |
            (bytes4(_bytes[3]) >> 24);
    }

    function revertWithError(bytes memory _bytes, string memory _tracingInfo)
        internal
        pure
    {
        // 68: 32-location, 32-length, 4-ErrorSelector, UTF-8 err
        if (_bytes.length % 32 == 4) {
            bytes4 selector;
            assembly {
                selector := mload(add(0x20, _bytes))
            }
            if (selector == 0x08c379a0) {
                // Function selector for Error(string)
                assembly {
                    _bytes := add(_bytes, 68)
                }
                revert(string(abi.encodePacked(_tracingInfo, string(_bytes))));
            } else {
                revert(
                    string(abi.encodePacked(_tracingInfo, "NoErrorSelector"))
                );
            }
        } else {
            revert(
                string(abi.encodePacked(_tracingInfo, "UnexpectedReturndata"))
            );
        }
    }

    function returnError(bytes memory _bytes, string memory _tracingInfo)
        internal
        pure
        returns (string memory)
    {
        // 68: 32-location, 32-length, 4-ErrorSelector, UTF-8 err
        if (_bytes.length % 32 == 4) {
            bytes4 selector;
            assembly {
                selector := mload(add(0x20, _bytes))
            }
            if (selector == 0x08c379a0) {
                // Function selector for Error(string)
                assembly {
                    _bytes := add(_bytes, 68)
                }
                return string(abi.encodePacked(_tracingInfo, string(_bytes)));
            } else {
                return
                    string(abi.encodePacked(_tracingInfo, "NoErrorSelector"));
            }
        } else {
            return
                string(abi.encodePacked(_tracingInfo, "UnexpectedReturndata"));
        }
    }
}