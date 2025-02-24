// deployscript 30851d78a4d6674b372ab0cf48987ce16d753dfa
// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.19;

import "Clones.sol";

import "BaseOwnable.sol";

contract CoboFactory is BaseOwnable {
    bytes32 public constant NAME = "CoboFactory";
    uint256 public constant VERSION = 1;

    mapping(bytes32 => address) public latestImplementations;
    mapping(bytes32 => address[]) public allImplementations;

    event ProxyCreated(address indexed deployer, bytes32 indexed name, address indexed impl, address proxy);
    event ImplementationAdded(bytes32 indexed name, address indexed impl);

    mapping(address => mapping(bytes32 => address[])) public records;

    constructor(address _owner) BaseOwnable(_owner) {}

    /// View functions.
    function getLatestImplementation(bytes32 name) public view returns (address impl) {
        impl = latestImplementations[name];
        require(impl != address(0), "No implementation");
    }

    function getLastRecord(address deployer, bytes32 name) external view returns (address proxy) {
        address[] storage record = records[deployer][name];
        require(record.length > 0, "No record");
        proxy = record[record.length - 1];
    }

    function getRecordSize(address deployer, bytes32 name) external view returns (uint256 size) {
        address[] storage record = records[deployer][name];
        size = record.length;
    }

    function getAllRecord(address deployer, bytes32 name) external view returns (address[] memory proxies) {
        return records[deployer][name];
    }

    function getRecords(
        address deployer,
        bytes32 name,
        uint256 start,
        uint256 end
    ) external view returns (address[] memory proxies) {
        address[] storage record = records[deployer][name];
        uint256 size = record.length;
        if (end > size) end = size;
        require(end > start, "end >= start");
        proxies = new address[](end - start);
        for (uint i = start; i < end; ++i) {
            proxies[i - start] = record[i];
        }
    }

    function getCreate2Address(bytes32 name, bytes32 salt) external view returns (address instance) {
        address implementation = getLatestImplementation(name);
        return Clones.predictDeterministicAddress(implementation, salt);
    }

    /// External functions.
    /// @dev Create EIP 1167 proxy and call (often initialize) function.
    function create(bytes32 name) public returns (address instance) {
        address implementation = getLatestImplementation(name);
        instance = Clones.clone(implementation);
        emit ProxyCreated(msg.sender, name, implementation, instance);
    }

    /// @dev Create with create2
    function create2(bytes32 name, bytes32 salt) public returns (address instance) {
        address implementation = getLatestImplementation(name);
        instance = Clones.cloneDeterministic(implementation, salt);
        emit ProxyCreated(msg.sender, name, implementation, instance);
    }

    function createAndRecord(bytes32 name) external returns (address instance) {
        instance = create(name);
        records[msg.sender][name].push(instance);
    }

    function create2AndRecord(bytes32 name, bytes32 salt) public returns (address instance) {
        instance = create2(name, salt);
        records[msg.sender][name].push(instance);
    }

    function addImplementation(address impl) external onlyOwner {
        bytes32 name = IVersion(impl).NAME();
        latestImplementations[name] = impl;
        allImplementations[name].push(impl);
        emit ImplementationAdded(name, impl);
    }
}

// deployscript 30851d78a4d6674b372ab0cf48987ce16d753dfa
// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create(0, 0x09, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create2(0, 0x09, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(add(ptr, 0x38), deployer)
            mstore(add(ptr, 0x24), 0x5af43d82803e903d91602b57fd5bf3ff)
            mstore(add(ptr, 0x14), implementation)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73)
            mstore(add(ptr, 0x58), salt)
            mstore(add(ptr, 0x78), keccak256(add(ptr, 0x0c), 0x37))
            predicted := keccak256(add(ptr, 0x43), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// deployscript 30851d78a4d6674b372ab0cf48987ce16d753dfa
// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.19;

import "Errors.sol";
import "BaseVersion.sol";

/// @dev Our version of OpenZeppelin OwnableUpgradeable can be used by proxy and non-proxy.
abstract contract BaseOwnable is BaseVersion {
    address public owner;
    address public pendingOwner;
    bool private initialized = false;

    event PendingOwnerSet(address to);
    event NewOwnerSet(address owner);

    /// @dev `owner` is set by argument, thus the owner can any address.
    constructor(address _owner) {
        initialize(_owner);
    }

    /// @dev If the contract is a proxy, `initialize` can be called to claim the ownership.
    ///      This function can be called only once.
    function initialize(address _owner) public {
        require(!initialized, Errors.ALREADY_INITIALIZED);
        _setOwner(_owner);
        initialized = true;
    }

    modifier onlyOwner() {
        require(owner == msg.sender, Errors.CALLER_IS_NOT_OWNER);
        _;
    }

    function setPendingOwner(address to) external onlyOwner {
        pendingOwner = to;
        emit PendingOwnerSet(pendingOwner);
    }

    function renounceOwnership() external onlyOwner {
        _setOwner(address(0));
    }

    /// @notice User should ensure the corrent owner address set, or the
    /// ownership may be transferred to blackhole. It is recommended to
    /// take a safer way with setPendingOwner() + acceptOwner().
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "New Owner is zero");
        _setOwner(newOwner);
    }

    function acceptOwner() external {
        require(msg.sender == pendingOwner);
        _setOwner(pendingOwner);
    }

    /// @dev Clear pendingOwner to prevent it from reclaiming the owner.
    function _setOwner(address _owner) internal {
        owner = _owner;
        pendingOwner = address(0);
        emit NewOwnerSet(owner);
    }
}

// deployscript 30851d78a4d6674b372ab0cf48987ce16d753dfa
// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.19;

library Errors {
    // Not View Variant.
    string constant NOT_VIEW_VAR = "E1";

    // Call/Static-call failed.
    string constant CALL_FAILED = "E2";

    // Argument's type not supported in View Variant.
    string constant INVALID_VIEW_ARG_SOL_TYPE = "E3";

    // Invalid length for variant raw data.
    string constant INVALID_VARIANT_RAW_DATA = "E4";

    // Invalid path in Dynamic Variant.
    string constant INVALID_DYN_VAR_PATH = "E5";

    // Invalid variant type.
    string constant INVALID_VAR_TYPE = "E6";

    // Rule not exists
    string constant RULE_NOT_EXISTS = "E7";

    // Variant name not found.
    string constant VAR_NAME_NOT_FOUND = "E8";

    // Rule: v1/v2 solType mismatch
    string constant SOL_TYPE_MISMATCH = "E9";

    // Rule AND/OR: no rules
    string constant NO_RULES = "E10";

    // Invalid rule OP.
    string constant INVALID_RULE_OP = "E11";

    // Invalid vm OP.
    string constant INVALID_VM_OP = "E12";

    // VM: v1/v2 solType mismatch
    string constant VM_SOL_TYPE_MISMATCH = "E13";

    // VM: In NOT op, v1 must be bool
    string constant VAR_NOT_BOOL = "E14";

    // VM: op not handled
    string constant OP_NOT_HANDLED = "E15";

    // parseDynamicCallData: Invalid path
    string constant INVALID_DYN_PATH = "E16";

    // parseDynamicCallData: Dynamic data elementIndex OOB
    string constant INDEX_OOB = "E17";

    // parseDynamicCallData: Dynamic data elementOffset OOB
    string constant ELEMENT_OFFSET_OOB = "E18";

    // parseDynamicCallData: Dynamic data targetOffset OOB
    string constant TARGET_OFFSET_OOB = "E19";

    // parseDynamicCallData: Dynamic data targetSize OOB
    string constant TARGET_SIZE_OOB = "E20";

    // checkCmpOp: OP not support
    string constant CMP_OP_NOT_SUPPORT = "E21";

    // checkBySolType: Invalid op for bool
    string constant INVALID_BOOL_OP = "E22";

    // checkBySolType: Invalid op
    string constant CHECK_INVALID_OP = "E23";

    // Invalid solidity type.
    string constant INVALID_SOL_TYPE = "E24";

    // computeBySolType: invalid vm op
    string constant INVALID_VM_BOOL_OP = "E25";

    // computeBySolType: invalid vm arith op
    string constant INVALID_VM_ARITH_OP = "E26";

    // onlyCaller: Invalid caller
    string constant INVALID_CALLER = "E27";

    // _preExecCheck: Re-entrance found.
    string constant REENTRY_FOUND = "E28";

    // Side-effect is not allowed here.
    string constant SIDE_EFFECT_NOT_ALLOWED = "E29";

    // Invalid variant count for the rule op.
    string constant INVALID_VAR_COUNT = "E30";

    // extractCallData: Invalid op.
    string constant INVALID_EXTRACTOR_OP = "E31";

    // extractCallData: Invalid array index.
    string constant INVALID_ARRAY_INDEX = "E32";

    // extractCallData: No extract op.
    string constant NO_EXTRACT_OP = "E33";

    // extractCallData: No extract path.
    string constant NO_EXTRACT_PATH = "E34";

    // BaseOwnable: caller is not owner
    string constant CALLER_IS_NOT_OWNER = "E35";

    // BaseOwnable: Already initialized
    string constant ALREADY_INITIALIZED = "E36";

    // BaseConfigManager: Invalid contract.
    string constant INVALID_CONTRACT = "E37";

    // BaseAuthorizer: caller is not wallet.
    string constant CALLER_IS_NOT_WALLET = "E38";

    // BaseACL: ACL check method should not return anything.
    string constant ACL_FUNC_RETURNS_NON_EMPTY = "E39";

    // BaseAuthorizer: wallet not set.
    string constant WALLET_NOT_SET = "E40";

    // BaseAccount: Invalid delegate.
    string constant INVALID_DELEGATE = "E41";

    // RootAuthorizer: delegateCallAuthorizer not set
    string constant DELEGATE_CALL_AUTH_NOT_SET = "E42";

    // RootAuthorizer: callAuthorizer not set.
    string constant CALL_AUTH_NOT_SET = "E43";

    // BaseAccount: Authorizer not set.
    string constant AUTHORIZER_NOT_SET = "E44";

    // No authorizers allow
    string constant ALL_AUTH_FAIL = "E45";

    // BaseAuthorizer: Authorizer paused.
    string constant AUTHORIZER_PAUSED = "E46";

    // Authorizer set: Invalid hint.
    string constant INVALID_HINT = "E47";

    // Authorizer set: All auth deny.
    string constant ALL_AUTH_FAILED = "E48";

    // BaseACL: Method not allow.
    string constant METHOD_NOT_ALLOW = "E49";

    // AuthorizerUnionSet: Invalid hint collected.
    string constant INVALID_HINT_COLLECTED = "E50";

    // AuthorizerSet: Empty auth set
    string constant EMPTY_AUTH_SET = "E51";

    // AuthorizerSet: hint not implement.
    string constant HINT_NOT_IMPLEMENT = "E52";

    // RoleAuthorizer: Empty role set
    string constant EMPTY_ROLE_SET = "E53";

    // RoleAuthorizer: No auth for the role
    string constant NO_AUTH_FOR_THE_ROLE = "E54";
}

// deployscript 30851d78a4d6674b372ab0cf48987ce16d753dfa
// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.19;

import "IVersion.sol";

abstract contract BaseVersion is IVersion {
    function _NAME() external view virtual returns (string memory) {
        return string(abi.encodePacked(this.NAME()));
    }
}

// deployscript 30851d78a4d6674b372ab0cf48987ce16d753dfa
// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.19;

interface IVersion {
    function NAME() external view returns (bytes32 name);

    function VERSION() external view returns (uint256 version);
}