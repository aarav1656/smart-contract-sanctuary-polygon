pragma solidity ^0.8.0;
pragma abicoder v2;

import "@hyperlane-xyz/core/contracts/interfaces/IMailbox.sol";
import "@hyperlane-xyz/core/contracts/interfaces/IInterchainGasPaymaster.sol";

contract Counter {
    // application state
    uint256 public counter;

    IMailbox public mailbox;
    IInterchainGasPaymaster public igp;

    constructor(address _mailbox, address _igp) {
        mailbox = IMailbox(_mailbox);
        igp = IInterchainGasPaymaster(_igp);
    }

    function addressToBytes32(address _addr) public returns (bytes32) {
        return bytes32(uint256(uint160(_addr)));
    }

    // application ops
    bytes32 public constant OP_ADD = keccak256("OP_ADD");
    bytes32 public constant OP_SUB = keccak256("OP_SUB");

    function remoteAddOperation(
        uint32 destinationDomain,
        address destinationAddress,
        uint256 amount
    ) external payable {
        bytes memory payload = abi.encode(OP_ADD, amount);
        _outbound(destinationDomain, destinationAddress, payload);
    }

    function remoteSubOperation(
        uint32 destinationDomain,
        address destinationAddress,
        uint256 amount
    ) external payable {
        bytes memory payload = abi.encode(OP_SUB, amount);
        _outbound(destinationDomain, destinationAddress, payload);
    }

    function _outbound(
        uint32 destinationDomain,
        address destinationAddress,
        bytes memory payload
    ) private {
         bytes32 messageId = mailbox.dispatch(
            destinationDomain,
            addressToBytes32(destinationAddress),
            payload
        );
       
        igp.payForGas{value: msg.value}(
            messageId, // The ID of the message that was just dispatched
            destinationDomain, // The destination domain of the message
            250000, // 100k gas to use in the recipient's handle function
            msg.sender // refunds go to msg.sender, who paid the msg.value
        );
    }

    function handle(
        uint32 _origin,
        bytes32 _sender,
        bytes calldata payload
    ) external {
      (bytes32 operationType, uint256 amount) = abi.decode(
            payload,
            (bytes32, uint256)
        );
        
        if (operationType == OP_ADD) {
            _addOperation(amount);
        } else if (operationType == OP_SUB) {
            _subOperation(amount);
        } else {
            revert("Counter: Invalid Operation");
        }
    }

    //
    // base ops
    //
    function _addOperation(uint256 amount_) private {
        counter += amount_;
    }

    function _subOperation(uint256 amount_) private {
        require(counter > amount_, "Counter: Subtraction Overflow");
        counter -= amount_;
    }
   
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.6.11;

interface IInterchainSecurityModule {
    enum Types {
        UNUSED_0,
        ROUTING,
        AGGREGATION,
        LEGACY_MULTISIG,
        MULTISIG
    }

    /**
     * @notice Returns an enum that represents the type of security model
     * encoded by this ISM.
     * @dev Relayers infer how to fetch and format metadata.
     */
    function moduleType() external view returns (uint8);

    /**
     * @notice Defines a security model responsible for verifying interchain
     * messages based on the provided metadata.
     * @param _metadata Off-chain metadata provided by a relayer, specific to
     * the security model encoded by the module (e.g. validator signatures)
     * @param _message Hyperlane encoded interchain message
     * @return True if the message was verified
     */
    function verify(bytes calldata _metadata, bytes calldata _message)
        external
        returns (bool);
}

interface ISpecifiesInterchainSecurityModule {
    function interchainSecurityModule()
        external
        view
        returns (IInterchainSecurityModule);
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.8.0;

import {IInterchainSecurityModule} from "./IInterchainSecurityModule.sol";

interface IMailbox {
    // ============ Events ============
    /**
     * @notice Emitted when a new message is dispatched via Hyperlane
     * @param sender The address that dispatched the message
     * @param destination The destination domain of the message
     * @param recipient The message recipient address on `destination`
     * @param message Raw bytes of message
     */
    event Dispatch(
        address indexed sender,
        uint32 indexed destination,
        bytes32 indexed recipient,
        bytes message
    );

    /**
     * @notice Emitted when a new message is dispatched via Hyperlane
     * @param messageId The unique message identifier
     */
    event DispatchId(bytes32 indexed messageId);

    /**
     * @notice Emitted when a Hyperlane message is processed
     * @param messageId The unique message identifier
     */
    event ProcessId(bytes32 indexed messageId);

    /**
     * @notice Emitted when a Hyperlane message is delivered
     * @param origin The origin domain of the message
     * @param sender The message sender address on `origin`
     * @param recipient The address that handled the message
     */
    event Process(
        uint32 indexed origin,
        bytes32 indexed sender,
        address indexed recipient
    );

    function localDomain() external view returns (uint32);

    function delivered(bytes32 messageId) external view returns (bool);

    function defaultIsm() external view returns (IInterchainSecurityModule);

    function dispatch(
        uint32 _destinationDomain,
        bytes32 _recipientAddress,
        bytes calldata _messageBody
    ) external returns (bytes32);

    function process(bytes calldata _metadata, bytes calldata _message)
        external;

    function count() external view returns (uint32);

    function root() external view returns (bytes32);

    function latestCheckpoint() external view returns (bytes32, uint32);

    function recipientIsm(address _recipient)
        external
        view
        returns (IInterchainSecurityModule);
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.6.11;

/**
 * @title IInterchainGasPaymaster
 * @notice Manages payments on a source chain to cover gas costs of relaying
 * messages to destination chains.
 */
interface IInterchainGasPaymaster {
    /**
     * @notice Emitted when a payment is made for a message's gas costs.
     * @param messageId The ID of the message to pay for.
     * @param gasAmount The amount of destination gas paid for.
     * @param payment The amount of native tokens paid.
     */
    event GasPayment(
        bytes32 indexed messageId,
        uint256 gasAmount,
        uint256 payment
    );

    function payForGas(
        bytes32 _messageId,
        uint32 _destinationDomain,
        uint256 _gasAmount,
        address _refundAddress
    ) external payable;

    function quoteGasPayment(uint32 _destinationDomain, uint256 _gasAmount)
        external
        view
        returns (uint256);
}