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
library ClonesUpgradeable {
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
pragma solidity 0.8.17;

import "./ProxyUtils.sol";

/// @title Proxy
/// @notice Proxy-side code for a minimal version of [OpenZeppelin's `ERC1967Proxy`](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/proxy/ERC1967/ERC1967Proxy.sol).
contract Proxy is ProxyUtils {
    /// @dev Initializes the upgradeable proxy with an initial implementation specified by `_logic`.
    /// If `_data` is nonempty, it's used as data in a delegate call to `_logic`. This will typically be an encoded
    /// function call, and allows initializing the storage of the proxy like a Solidity constructor.
    constructor(address _logic) {
        _upgradeTo(_logic);
    }

    /// @dev Delegates the current call to the address returned by `_implementation()`.
    /// This function does not return to its internal call site, it will return directly to the external caller.
    function _fallback() internal {
        _delegate(_implementation());
    }

    /// @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
    /// function in the contract matches the call data.
    fallback() external payable {
        _fallback();
    }

    /// @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
    /// is empty.
    receive() external payable {
        _fallback();
    }

    /// @dev Delegates the current call to `implementation`.
    /// This function does not return to its internal call site, it will return directly to the external caller.
    function _delegate(address implementation) internal {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "lib/openzeppelin-contracts-upgradeable/contracts/utils/AddressUpgradeable.sol";
import "lib/openzeppelin-contracts-upgradeable/contracts/utils/StorageSlotUpgradeable.sol";

/// @title ProxyUtils
/// @notice Common code for `Proxy` and underlying implementation contracts.
contract ProxyUtils {
    /// @dev Storage slot with the address of the current implementation.
    /// This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
    /// validated in the constructor.
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /// @dev Emitted when the implementation is upgraded.
    event Upgraded(address indexed implementation);

    /// @dev Returns the current implementation address.
    function _implementation() internal view returns (address impl) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /// @dev Perform implementation upgrade
    /// Emits an {Upgraded} event.
    function _upgradeTo(address newImplementation) internal {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
        emit Upgraded(newImplementation);
    }

    /// @dev Perform implementation upgrade with additional setup call.
    /// Emits an {Upgraded} event.
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

    /// @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
    /// but performing a delegate call.
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "./WalletFactory.sol";
import "./ProxyUtils.sol";

/// @title Wallet
/// @notice Basic multisig smart contract wallet with a relay guardian.
contract Wallet is ProxyUtils {
    using AddressUpgradeable for address;

    /// @notice The creating `WalletFactory`.
    WalletFactory public walletFactory;

    /// @dev Struct for a signer.
    struct SignerConfig {
        uint8 votes;
        uint256 signingTimelock;
    }

    /// @notice Configs per signer.
    mapping(address => SignerConfig) public signerConfigs;

    /// @dev Event emitted when a signer config is changed.
    event SignerConfigChanged(address indexed signer, SignerConfig config);

    /// @notice Threshold of signer votes required to sign transactions.
    uint8 public threshold;

    /// @notice Timelock after which the contract can be upgraded and/or the relayer whitelist can be disabled.
    uint256 public relayerWhitelistTimelock;

    /// @dev Struct for a signature.
    struct Signature {
        bytes32 r;
        bytes32 s;
        uint8 v;
    }

    /// @notice Last timestamp disabling the relayer whitelist was queued/requested.
    uint256 public disableRelayerWhitelistQueueTimestamp;

    /// @notice Maps pending (queued) signature hashes to queue timestamps.
    mapping(bytes32 => uint256) public pendingSignatures;

    /// @notice Current transaction nonce (prevents replays).
    uint256 public nonce;

    /// @dev Initializes the contract.
    /// See `WalletFactory` for details.
    function initialize(
        address[] calldata signers,
        SignerConfig[] calldata _signerConfigs,
        uint8 _threshold,
        uint256 _relayerWhitelistTimelock,
        bool _subscriptionPaymentsEnabled
    ) external {
        // Input validation
        require(signers.length > 0, "Must have at least one signer.");
        require(signers.length == _signerConfigs.length, "Lengths of signer and signer config arrays must match.");
        require(_threshold > 0, "Vote threshold must be greater than 0.");

        // Set variables
        for (uint256 i = 0; i < _signerConfigs.length; i++) {
            signerConfigs[signers[i]] = _signerConfigs[i];
            emit SignerConfigChanged(signers[i], _signerConfigs[i]);
        }

        threshold = _threshold;
        relayerWhitelistTimelock = _relayerWhitelistTimelock;
        subscriptionPaymentsEnabled = _subscriptionPaymentsEnabled;

        // Set WalletFactory
        walletFactory = WalletFactory(msg.sender);

        // Set lastSubscriptionPaymentTimestamp
        if (_subscriptionPaymentsEnabled) lastSubscriptionPaymentTimestamp = block.timestamp - SUBSCRIPTION_PAYMENT_INTERVAL_SECONDS;
    }

    /// @dev Access control for the contract itself.
    /// Make sure to call functions marked with this modifier via `Wallet.functionCall`.
    modifier onlySelf() {
        require(msg.sender == address(this), "Sender is not self.");
        _;
    }

    /// @dev Internal function to verify `signatures` on `signedData`.
    function _validateSignatures(Signature[] calldata signatures, bytes32 signedDataHash, bool requireRelayGuardian) internal view {
        // Input validation
        require(signatures.length > 0, "No signatures supplied.");
        
        // Loop through signers to tally votes (keeping track of signers checked to look for duplicates)
        uint256 _votes = 0;
        address[] memory signers = new address[](signatures.length);

        for (uint256 i = 0; i < signatures.length; i++) {
            // Get signer
            Signature calldata sig = signatures[i];
            address signer = ecrecover(signedDataHash, sig.v, sig.r, sig.s);

            // Check for duplicate & keep track of signer to check for duplicates in the future
            for (uint256 j = 0; j < signers.length; j++) require(signer != signers[j], "Duplicate signer in signatures array.");
            signers[i] = signer;

            // Get signer config
            SignerConfig memory config = signerConfigs[signer];
            require(config.votes > 0, "Unrecognized signer.");

            // Check signing timelock
            if (config.signingTimelock > 0) {
                uint256 timestamp = pendingSignatures[keccak256(abi.encode(sig))];
                require(timestamp > 0, "Signature not queued.");
                require(timestamp + config.signingTimelock <= block.timestamp, "Timelock not satisfied.");
            }

            // Tally votes
            _votes += config.votes;
        }

        // Check tally of votes against threshold
        require(_votes >= threshold, "Votes not greater than or equal to threshold.");

        // Relayer validation (if enabled)
        if (relayerWhitelistTimelock > 0 && requireRelayGuardian) walletFactory.checkRelayGuardian(msg.sender);
    }

    /// @notice Event emitted when a function call reverts.
    event FunctionCallReversion(uint256 indexed _nonce, uint256 indexA, uint256 indexB, bytes error);

    /// @notice Call any function on any contract given sufficient authentication.
    /// If the call reverts, the transaction will not revert but will emit a `FunctionCallReversion` event.
    /// @dev NOTICE: Does not validate that ETH balance is great enough for value + gas refund to paymaster + paymaster incentive. Handle this on the UI + relayer sides.
    /// UI + relayer should check to make sure the function calls will not revert using the `debug` flag.
    /// @param feeData Array of `[gasLimit, maxFeePerGas, maxPriorityFeePerGas, paymasterIncentive]`.
    /// @param debug Set to false to relay normally and set to true to revert on external call reversion.
    function functionCall(
        Signature[] calldata signatures,
        address target,
        bytes calldata data,
        uint256 value,
        uint256[4] calldata feeData,
        bool debug
    ) external {
        // Get initial gas
        uint256 initialGas = gasleft();

        // Get message hash (include chain ID, wallet contract address, and nonce) and validate signatures
        bytes32 dataHash = sha256(abi.encode(block.chainid, address(this), ++nonce, this.functionCall.selector, target, data, value, feeData));
        _validateSignatures(signatures, dataHash, true);

        // Gas validation
        require(initialGas <= feeData[0], "Gas limit not satified.");
        require(tx.gasprice <= feeData[1], "maxFeePerGas not satisfied.");
        require(tx.gasprice - block.basefee <= feeData[2], "maxPriorityFeePerGas not satisfied.");

        // Call contract
        (bool success, bytes memory ret) = target.call{ value: value, gas: gasleft() - 30000 }(data);
        if (!success) {
            emit FunctionCallReversion(nonce, 0, 0, ret);
            if (debug) revert(string(abi.encodeWithSelector(EXTERNAL_CALL_REVERTED_SELECTOR, 0, 0, ret)));
        }

        // Send relayer the gas back
        msg.sender.call{value: ((initialGas - gasleft()) * tx.gasprice) + feeData[3] }("");
    }

    /// @dev You know a `functionCall` has reverted internally if the revert data begins with this selector and decodes the `uint256`s and `bytes` correctly.
    bytes4 public constant EXTERNAL_CALL_REVERTED_SELECTOR = bytes4(keccak256("externalCallReverted(uint256,uint256,bytes)"));

    /// @notice Call multiple functions on any contract(s) given sufficient authentication.
    /// If the call reverts, the transaction will not revert but will emit a `FunctionCallReversion` event.
    /// @dev NOTICE: Does not validate that ETH balance is great enough for value + gas refund to paymaster + paymaster incentive. Handle this on the UI + relayer sides.
    /// UI + relayer should check to make sure the function calls will not revert using the `debug` flag.
    /// @param feeData Array of `[gasLimit, maxFeePerGas, maxPriorityFeePerGas, paymasterIncentive]`.
    /// @param debug Set to 0 to relay normally, set to 1 to stop execution on external call reversion, and set to 2 to revert on external call reversion.
    function functionCallMulti(
        Signature[] calldata signatures,
        address[] calldata targets,
        bytes[] calldata data,
        uint256[] calldata values,
        uint256[4] calldata feeData,
        uint8 debug
    ) external {
        // Get initial gas
        uint256 initialGas = gasleft();

        // Get message hash (include chain ID, wallet contract address, and nonce) and validate signatures
        bytes32 dataHash = sha256(abi.encode(block.chainid, address(this), ++nonce, this.functionCallMulti.selector, targets, data, values, feeData));
        _validateSignatures(signatures, dataHash, true);

        // Gas validation
        require(initialGas <= feeData[0], "Gas limit not satified.");
        require(tx.gasprice <= feeData[1], "maxFeePerGas not satisfied.");
        require(tx.gasprice - block.basefee <= feeData[2], "maxPriorityFeePerGas not satisfied.");

        // Input validation
        require(targets.length == data.length && targets.length == values.length, "Input array lengths must be equal.");

        // Call contracts
        for (uint256 i = 0; i < targets.length; i++) {
            uint256 gasl = gasleft();
            if (gasl <= 30000) {
                emit FunctionCallReversion(nonce, 0, i, "Wallet: function call ran out of gas.");
                break;
            }
            (bool success, bytes memory ret) = targets[i].call{ value: values[i], gas: gasl - 30000 }(data[i]);
            if (!success) {
                emit FunctionCallReversion(nonce, 0, i, ret);
                if (debug == 1) break;
                if (debug > 1) revert(string(abi.encodeWithSelector(EXTERNAL_CALL_REVERTED_SELECTOR, 0, i, ret)));
            }
        }

        // Send relayer the gas back
        msg.sender.call{value: ((initialGas - gasleft()) * tx.gasprice) + feeData[3] }("");
    }

    /// @notice Allows sending a combination of `functionCall`s and `functionCallMulti`s.
    /// Only useful for multi-party wallets--if using a single-party wallet, just re-sign all pending transactions and use `functionCallMulti` to save gas.
    /// If the call reverts, the transaction will not revert but will emit a `FunctionCallReversion` event.
    /// @dev NOTICE: Does not validate that ETH balance is great enough for value + gas refund to paymaster + paymaster incentive. Handle this on the UI + relayer sides.
    /// UI + relayer should check to make sure the function calls will not revert using the `debug` flag.
    /// @param debug Set to 0 to relay normally, set to 1 to stop execution on external call reversion, and set to 2 to revert on external call reversion.
    function functionCallBatch(
        bool[] calldata multi,
        Signature[][] calldata signatures,
        bytes[] calldata signedData,
        uint8 debug
    ) external {
        // Get initial gas
        uint256 initialGas = gasleft();

        // Input validation
        require(multi.length == signatures.length && multi.length == signedData.length, "Input array lengths must be equal.");

        // Loop through batch
        uint256 totalPaymasterIncentive = 0;

        for (uint256 i = 0; i < multi.length; i++) {
            uint256 minEndingGas = gasleft();
            _validateSignatures(signatures[i], sha256(signedData[i]), true);

            if (multi[i]) {
                // Decode data and check relayer
                address[] memory targets;
                bytes[] memory data;
                uint256[] memory values;
                {
                    uint256 chainid;
                    address wallet;
                    uint256 _nonce;
                    bytes4 selector;
                    uint256[4] memory feeData;
                    (chainid, wallet, _nonce, selector, targets, data, values, feeData) =
                        abi.decode(signedData[i], (uint256, address, uint256, bytes4, address[], bytes[], uint256[], uint256[4]));
                    require(chainid == block.chainid && wallet == address(this) && _nonce == ++nonce && selector == this.functionCallMulti.selector, "Invalid functionCallMulti signature.");
                    totalPaymasterIncentive += feeData[3];

                    // Gas validation
                    minEndingGas -= feeData[0];
                    require(tx.gasprice <= feeData[1], "maxFeePerGas not satisfied.");
                    require(tx.gasprice - block.basefee <= feeData[2], "maxPriorityFeePerGas not satisfied.");
                }

                // Input validation
                require(targets.length == data.length && targets.length == values.length, "Input array lengths must be equal.");

                // Call contracts
                for (uint256 j = 0; j < targets.length; j++) {
                    bytes memory ret;
                    {
                        uint256 gasl = gasleft();
                        if (gasl <= 30000) {
                            emit FunctionCallReversion(nonce, i, j, "Wallet: function call ran out of gas.");
                            break;
                        }
                        bool success;
                        (success, ret) = targets[i].call{ value: values[i], gas: gasl - 30000 }(data[i]);
                        if (success) continue;
                    }

                    // If call reverted:
                    emit FunctionCallReversion(nonce, i, j, ret);
                    if (debug == 1) {
                        i = multi.length;
                        break;
                    }
                    if (debug > 1) revert(string(abi.encodeWithSelector(EXTERNAL_CALL_REVERTED_SELECTOR, i, j, ret)));
                }

                require(minEndingGas <= gasleft(), "Gas limit not satified.");
            } else {
                // Decode data and check relayer
                address target;
                bytes memory data;
                uint256 value;
                {
                    uint256 chainid;
                    address wallet;
                    uint256 _nonce;
                    bytes4 selector;
                    uint256[4] memory feeData;
                    (chainid, wallet, _nonce, selector, target, data, value, feeData) =
                        abi.decode(signedData[i], (uint256, address, uint256, bytes4, address, bytes, uint256, uint256[4]));
                    require(chainid == block.chainid && wallet == address(this) && _nonce == ++nonce && selector == this.functionCall.selector, "Invalid functionCall signature.");
                    totalPaymasterIncentive += feeData[3];

                    // Gas validation
                    minEndingGas -= feeData[0];
                    require(tx.gasprice <= feeData[1], "maxFeePerGas not satisfied.");
                    require(tx.gasprice - block.basefee <= feeData[2], "maxPriorityFeePerGas not satisfied.");
                }

                // Call contract
                (bool success, bytes memory ret) = target.call{ value: value, gas: gasleft() - 30000 }(data);
                if (!success) {
                    emit FunctionCallReversion(nonce, i, 0, ret);
                    if (debug == 1) {
                        i = multi.length;
                        break;
                    }
                    if (debug > 1) revert(string(abi.encodeWithSelector(EXTERNAL_CALL_REVERTED_SELECTOR, i, 0, ret)));
                }

                require(minEndingGas <= gasleft(), "Gas limit not satified.");
            }
        }

        // Send relayer the gas back
        msg.sender.call{value: ((initialGas - gasleft()) * tx.gasprice) + totalPaymasterIncentive }("");
    }

    /// @notice Modifies the signers on the wallet.
    /// WARNING: Does not validate that all signers have >= threshold votes.
    function modifySigners(address[] calldata signers, SignerConfig[] calldata _signerConfigs, uint8 _threshold) external onlySelf {
        // Input validation
        require(signers.length == _signerConfigs.length, "Lengths of signer and config arrays must match.");
        require(_threshold > 0, "Vote threshold must be greater than 0.");

        // Set variables
        for (uint256 i = 0; i < signers.length; i++) {
            signerConfigs[signers[i]] = _signerConfigs[i];
            emit SignerConfigChanged(signers[i], _signerConfigs[i]);
        }

        threshold = _threshold;
    }

    /// @notice Change the relayer whitelist timelock.
    /// Timelock can be enabled at any time.
    /// Off chain relay guardian logic: if changing the timelock from a non-zero value, requires that the user waits for the old timelock to pass (after calling `queueAction`).
    function setRelayerWhitelistTimelock(uint256 _relayerWhitelistTimelock) external onlySelf {
        relayerWhitelistTimelock = _relayerWhitelistTimelock;
        disableRelayerWhitelistQueueTimestamp = 0;
    }

    /// @notice Disable the relayer whitelist by setting the timelock to 0.
    /// Requires that the user waits for the old timelock to pass (after calling `queueAction`).
    function disableRelayerWhitelist(Signature[] calldata signatures) external {
        // Validate signatures
        bytes32 dataHash = sha256(abi.encode(block.chainid, address(this), ++nonce, this.disableRelayerWhitelist.selector));
        if (msg.sender != address(this)) _validateSignatures(signatures, dataHash, false);

        // Check timelock
        if (relayerWhitelistTimelock > 0) {
            uint256 timestamp = disableRelayerWhitelistQueueTimestamp;
            require(timestamp > 0, "Action not queued.");
            require(timestamp + relayerWhitelistTimelock <= block.timestamp, "Timelock not satisfied.");
        }

        // Disable it
        require(relayerWhitelistTimelock > 0, "Relay whitelist already disabled.");
        relayerWhitelistTimelock = 0;
    }

    /// @notice Queues a timelocked action.
    /// @param signatures Only necessary if calling this function directly (i.e., not through `functionCall`).
    function queueDisableRelayerWhitelist(Signature[] calldata signatures) external {
        // Validate signatures
        bytes32 dataHash = sha256(abi.encode(block.chainid, address(this), ++nonce, this.queueDisableRelayerWhitelist.selector));
        if (msg.sender != address(this)) _validateSignatures(signatures, dataHash, false);

        // Mark down queue timestamp
        disableRelayerWhitelistQueueTimestamp = block.timestamp;
    }

    /// @notice Unqueues a timelocked action.
    /// @param signatures Only necessary if calling this function directly (i.e., not through `functionCall`).
    function unqueueDisableRelayerWhitelist(Signature[] calldata signatures) external {
        // Validate signatures
        bytes32 dataHash = sha256(abi.encode(block.chainid, address(this), ++nonce, this.unqueueDisableRelayerWhitelist.selector));
        if (msg.sender != address(this)) _validateSignatures(signatures, dataHash, false);

        // Reset queue timestamp
        disableRelayerWhitelistQueueTimestamp = 0;
    }

    /// @notice Queues a timelocked signature.
    /// No unqueue function because transaction nonces can be overwritten and signers can be removed.
    /// No access control because it's unnecessary and wastes gas.
    function queueSignature(bytes32 signatureHash) external {
        pendingSignatures[signatureHash] = block.timestamp;
    }

    /// @dev Receive ETH.
    receive() external payable { }

    /// @notice Returns the current `Wallet` implementation/logic contract.
    function implementation() external view returns (address) {
        return _implementation();
    }

    /// @notice Perform implementation upgrade.
    /// Emits an {Upgraded} event.
    function upgradeTo(address newImplementation) external onlySelf {
        _upgradeTo(newImplementation);
    }

    /// @notice Perform implementation upgrade with additional setup call.
    /// Emits an {Upgraded} event.
    function upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) external onlySelf {
        _upgradeToAndCall(newImplementation, data, forceCall);
    }

    /// @dev Payment amount enabled/diabled.
    bool public subscriptionPaymentsEnabled;

    /// @dev Payment amount per cycle.
    uint256 public constant SUBSCRIPTION_PAYMENT_AMOUNT = 0.164e18; // Approximately 2 ETH per year

    /// @dev Payment amount cycle interval (in seconds).
    uint256 public constant SUBSCRIPTION_PAYMENT_INTERVAL_SECONDS = 86400 * 30; // 30 days

    /// @dev Last recurring payment timestamp.
    uint256 public lastSubscriptionPaymentTimestamp;

    /// @dev Recurring payments transfer function.
    function subscriptionPayments() external {
        require(subscriptionPaymentsEnabled, "Subscription payments not enabled.");
        uint256 cycles = (block.timestamp - lastSubscriptionPaymentTimestamp) / SUBSCRIPTION_PAYMENT_INTERVAL_SECONDS;
        require(cycles > 0, "No cycles have passed.");
        uint256 amount = SUBSCRIPTION_PAYMENT_AMOUNT * cycles;
        require(address(this).balance > 0, "No ETH to transfer.");
        if (amount > address(this).balance) amount = address(this).balance;
        (bool success, ) = walletFactory.relayGuardianManager().call{value: amount}("");
        require(success, "Failed to transfer ETH.");
        lastSubscriptionPaymentTimestamp = block.timestamp;
    }

    /// @dev Enable/disable recurring payments.
    /// Relay guardian has permission to enable or disable at any time depending on if credit card payments are going through.
    function setSubscriptionPaymentsEnabled(bool enabled) external {
        require(subscriptionPaymentsEnabled != enabled, "Status already set to desired status.");
        if (!(msg.sender == address(this) && enabled)) walletFactory.checkRelayGuardian(msg.sender);
        subscriptionPaymentsEnabled = enabled;
        if (enabled) lastSubscriptionPaymentTimestamp = block.timestamp - SUBSCRIPTION_PAYMENT_INTERVAL_SECONDS;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "./Wallet.sol";
import "./Proxy.sol";

import "lib/openzeppelin-contracts-upgradeable/contracts/proxy/ClonesUpgradeable.sol";

/// @title WalletFactory
/// @notice Creates new `Wallet`s.
contract WalletFactory {
    using AddressUpgradeable for address;

    /// @notice The relay guardian.
    /// WARNING: If this variable is set to the zero address, the relay guardian whitelist will NOT be validated on wallets--so do NOT set this variable to the zero address unless you are sure you want to allow anyone to relay transactions.
    /// The relay guardian relays all transactions for a `Wallet`, unless the relay guardian whitelist is deactivated on a `Wallet` or if the relay guardian is set to the zero address here, in which case any address can relay transactions.
    /// The relay guardian can act as off-chain transaction policy node(s) permitting realtime/AI-based fraud detection, symmetric/access-token-based authentication mechanisms, and/or instant onboarding to the Waymont chain.
    /// The relay guardian whitelist can be disabled/enabled via a user-specified timelock on the `Wallet`.
    address public relayGuardian;

    /// @notice The secondary relay guardian.
    /// WARNING: Even if the secondary guardian is set, if the primary guardian is not set, the `Wallet` contract does not validate that the relayer is a whitelisted guardian.
    /// The secondary relay guardian is used as a fallback guardian.
    /// However, it can also double as an authenticated multicall contract to save gas while relaying transactions across multiple wallets in the same blocks.
    /// If using a secondary relay guardian, ideally, it is the less-used of the two guardians to conserve some gas.
    address public secondaryRelayGuardian;

    /// @notice The relay guardian manager.
    address public relayGuardianManager;

    /// @dev `Wallet` implementation/logic contract address.
    address public immutable walletImplementation;

    /// @notice Event emitted when the relay guardian is changed.
    event RelayGuardianChanged(address _relayGuardian);

    /// @notice Event emitted when the secondary relay guardian is changed.
    event SecondaryRelayGuardianChanged(address _relayGuardian);

    /// @notice Event emitted when the relay guardian manager is changed.
    event RelayGuardianManagerChanged(address _relayGuardianManager);

    /// @dev Constructor to initialize the factory by setting the relay guardian manager and creating and setting a new `Wallet` implementation.
    constructor(address _relayGuardianManager) {
        relayGuardianManager = _relayGuardianManager;
        emit RelayGuardianManagerChanged(_relayGuardianManager);
        walletImplementation = address(new Wallet());
    }

    /// @notice Deploys an upgradeable (or non-upgradeable) proxy over `Wallet`.
    /// WARNING: Does not validate that signers have >= threshold votes.
    /// Only callable by the relay guardian so nonces used on other chains can be kept unused on this chain until the same user deploys to this chain.
    /// @param signers Signers can be password-derived keys generated using bcrypt.
    /// @param signerConfigs Controls votes per signer as well as signing timelocks.
    /// @param threshold Threshold of votes required to sign transactions.
    /// @param relayerWhitelistTimelock Applies to disabling the relayer whitelist. If set to zero, the relayer whitelist is disabled.
    /// @param upgradeable Whether or not the contract is upgradeable (costs less gas to deploy and use if not).
    function createWallet(
        uint256 nonce,
        address[] calldata signers,
        Wallet.SignerConfig[] calldata signerConfigs,
        uint8 threshold,
        uint256 relayerWhitelistTimelock,
        bool subscriptionPaymentsEnabled,
        bool upgradeable
    ) external returns (Wallet) {
        require(msg.sender == relayGuardian, "Sender is not the relay guardian.");
        Wallet instance = Wallet(upgradeable ? payable(new Proxy{salt: bytes32(nonce)}(walletImplementation)) : payable(ClonesUpgradeable.cloneDeterministic(walletImplementation, bytes32(nonce))));
        address(instance).functionCall(abi.encode(signers, signerConfigs, threshold, relayerWhitelistTimelock, subscriptionPaymentsEnabled), "Failed to initialize Wallet.");
        return instance;
    }

    /// @dev Access control for the relay guardian manager.
    modifier onlyRelayGuardianManager() {
        require(msg.sender == relayGuardianManager, "Sender is not the relay guardian manager.");
        _;
    }

    /// @notice Sets the relay guardian.
    /// WARNING: If this variable is set to the zero address, the relay guardian whitelist will NOT be validated on wallets--so do NOT set this variable to the zero address unless you are sure you want to allow anyone to relay transactions.
    function setRelayGuardian(address _relayGuardian) external onlyRelayGuardianManager {
        relayGuardian = _relayGuardian;
        emit RelayGuardianChanged(_relayGuardian);
    }

    /// @notice Sets the secondary relay guardian.
    /// WARNING: Even if the secondary guardian is set, if the primary guardian is not set, the `Wallet` contract does not validate that the relayer is a whitelisted guardian.
    function setSecondaryRelayGuardian(address _relayGuardian) external onlyRelayGuardianManager {
        secondaryRelayGuardian = _relayGuardian;
        emit SecondaryRelayGuardianChanged(_relayGuardian);
    }

    /// @notice Sets the relay guardian manager.
    function setRelayGuardianManager(address _relayGuardianManager) external onlyRelayGuardianManager {
        relayGuardianManager = _relayGuardianManager;
        emit RelayGuardianManagerChanged(_relayGuardianManager);
    }

    /// @dev Validates that `sender` is a valid relay guardian.
    function checkRelayGuardian(address sender) external view {
        address _relayGuardian = relayGuardian;
        require(sender == _relayGuardian || sender == secondaryRelayGuardian || _relayGuardian == address(0), "Sender is not relay guardian.");
    }
}