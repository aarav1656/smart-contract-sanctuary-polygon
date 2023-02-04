// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";

import {FxBaseChildTunnel} from "../tunnel/FxBaseChildTunnel.sol";
import "../pools/IChildPool.sol";

/**
 * @title FxStateChildTunnel
 */
contract FxStateChildTunnel is FxBaseChildTunnel, Ownable {
    uint256 public latestStateId;
    address public latestRootMessageSender;
    bytes public latestData;
    address public pool;

    constructor(address _fxChild) FxBaseChildTunnel(_fxChild) {}

    function _processMessageFromRoot(
        uint256 stateId,
        address sender,
        bytes memory data
    ) internal override validateSender(sender) {
        latestStateId = stateId;
        latestRootMessageSender = sender;
        latestData = data;
    }

    function sendMessageToRoot(bytes memory message) public {
        require(msg.sender == pool, "!pool");

        _sendMessageToRoot(message);
    }

    function readData() external view returns (uint256, uint256, ShuttleProcessingStatus) {
      (uint256 shuttleNumber, uint256 amount, ShuttleProcessingStatus shuttleProcessingStatus) = abi.decode(
            latestData,
            (uint256, uint256, ShuttleProcessingStatus)
        );

        return (shuttleNumber, amount, shuttleProcessingStatus);
    }

    function setPool(address _pool) external onlyOwner {
        pool = _pool;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

// IFxMessageProcessor represents interface to process message
interface IFxMessageProcessor {
    function processMessageFromRoot(
        uint256 stateId,
        address rootMessageSender,
        bytes calldata data
    ) external;
}

/**
 * @notice Mock child tunnel contract to receive and send message from L2
 */
abstract contract FxBaseChildTunnel is IFxMessageProcessor {
    // MessageTunnel on L1 will get data from this event
    event MessageSent(bytes message);

    // fx child
    address public fxChild;

    // fx root tunnel
    address public fxRootTunnel;

    constructor(address _fxChild) {
        fxChild = _fxChild;
    }

    // Sender must be fxRootTunnel in case of ERC20 tunnel
    modifier validateSender(address sender) {
        require(sender == fxRootTunnel, "FxBaseChildTunnel: INVALID_SENDER_FROM_ROOT");
        _;
    }

    // set fxRootTunnel if not set already
    function setFxRootTunnel(address _fxRootTunnel) external virtual {
        require(fxRootTunnel == address(0x0), "FxBaseChildTunnel: ROOT_TUNNEL_ALREADY_SET");
        fxRootTunnel = _fxRootTunnel;
    }

    function processMessageFromRoot(
        uint256 stateId,
        address rootMessageSender,
        bytes calldata data
    ) external override {
        require(msg.sender == fxChild, "FxBaseChildTunnel: INVALID_SENDER");
        _processMessageFromRoot(stateId, rootMessageSender, data);
    }

    /**
     * @notice Emit message that can be received on Root Tunnel
     * @dev Call the internal function when need to emit message
     * @param message bytes message that will be sent to Root Tunnel
     * some message examples -
     *   abi.encode(tokenId);
     *   abi.encode(tokenId, tokenMetadata);
     *   abi.encode(messageType, messageData);
     */
    function _sendMessageToRoot(bytes memory message) internal {
        emit MessageSent(message);
    }

    /**
     * @notice Process message received from Root Tunnel
     * @dev function needs to be implemented to handle message as per requirement
     * This is called by onStateReceive function.
     * Since it is called via a system call, any event will not be emitted during its execution.
     * @param stateId unique state id
     * @param sender root message sender
     * @param message bytes message that was sent from Root Tunnel
     */
    function _processMessageFromRoot(
        uint256 stateId,
        address sender,
        bytes memory message
    ) internal virtual;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.7;

contract IChildPool {
    enum ShuttleStatus {
        UNAVAILABLE,
        AVAILABLE,
        ENROUTE,
        ARRIVED,
        EXPIRED,
        CANCELLED
    }

    struct Shuttle {
        uint256 totalAmount;
        ShuttleStatus status;
        uint256 recievedToken;
        uint256 expiry;
    }

    event ShuttleCreated(uint256 _shuttleNumber);
    event Deposit(uint256 _shuttlesNumber, address _sender, uint256 _amount);
    event ShuttleEnrouted(uint256 _shuttleNumber, uint256 _amount);
    event ShuttleArrived(
        uint256 _shuttleNumber,
        uint256 _amount,
        ShuttleStatus _status,
        uint256 _shuttleFee
    );
    event TokenClaimed(
        uint256 _shuttleNumber,
        address _token,
        address _beneficiary,
        uint256 _claimedAmount
    );

    event ShuttleExpired(uint256 _shuttleNumber);
    event ShuttleCancelled(uint256 _shuttleNumber);
    event FeeChanged(uint256 _fee);
    event ShuttleExpiryChanged(uint256 _shuttleExpiry);

    event CampaignChanged(address _campaignAddress);

    error ZeroAddress();
}

enum ShuttleProcessingStatus {
    PROCESSED,
    CANCELLED
}

interface IFxStateChildTunnel {
    function sendMessageToRoot(bytes memory message) external;

    function readData()
        external
        returns (
            uint256,
            uint256,
            ShuttleProcessingStatus
        );
}

interface IMaticToken {
    function withdraw(uint256) external payable;
}

interface IFundCollector {
    function withdrawFunds(uint256 _amount) external;
}

interface ICampaign {
    function claimRewards(
        uint256 _shuttleNumber,
        uint256 _campaignNumber,
        uint256 _userAmount,
        uint256 _totalAmount,
        address payable _sender
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}