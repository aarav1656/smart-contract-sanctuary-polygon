// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./Interfaces.sol";
import "./PhatRollupReceiver.sol";

contract TestOracle is PhatRollupReceiver, Ownable {
    event PriceReceived(uint reqId, string pair, uint256 price);
    event FeedReceived(uint feedId, string pair,  uint256 price);
    event ErrorReceived(uint reqId, string pair,  uint256 errno);

    uint constant TYPE_RESPONSE = 0;
    uint constant TYPE_FEED = 1;
    uint constant TYPE_ERROR = 2;

    address anchor = address(0);
    mapping (uint => string) feeds;
    mapping (uint => string) requests;
    uint nextRequest = 1;

    function setAnchor(address anchor_) public onlyOwner() {
        anchor = anchor_;
    }

    function request(string calldata tradingPair) public {
        require(anchor != address(0), "anchor not configured");
        // assemble the request
        uint id = nextRequest;
        requests[id] = tradingPair;
        IPhatRollupAnchor(anchor).pushMessage(abi.encode(id, tradingPair));
        nextRequest += 1;
    }

    function registerFeed(uint id, string calldata name) public onlyOwner() {
        feeds[id] = name;
    }

    function onPhatRollupReceived(address /*_from*/, bytes calldata action)
        public override returns(bytes4)
    {
        // Always check the sender. Otherwise you can get fooled.
        require(msg.sender == anchor, "bad caller");

        require(action.length == 32 * 3, "cannot parse action");
        (uint respType, uint id, uint256 data) = abi.decode(action, (uint, uint, uint256));
        if (respType == TYPE_RESPONSE) {
            emit PriceReceived(id, requests[id], data);
            delete requests[id];
        } else if (respType == TYPE_FEED) {
            emit FeedReceived(id, feeds[id], data);
        } else if (respType == TYPE_ERROR) {
            emit ErrorReceived(id, requests[id], data);
            delete requests[id];
        }
        return ROLLUP_RECEIVED;
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.9;

interface IPhatRollupAnchor {
    function pushMessage(bytes memory data) external returns (uint32);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.9;

abstract contract PhatRollupReceiver {
    // bytes4(keccak256("onPhatRollupReceived(address,bytes)"))
    bytes4 constant ROLLUP_RECEIVED = 0x43a53d89;
    function onPhatRollupReceived(address _from, bytes calldata _action)
        public virtual returns(bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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