/**
 *Submitted for verification at polygonscan.com on 2022-10-09
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.15;

// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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

interface IPreCommitManager {
    struct Project {
        address receiver;
        address asset;
    }
    struct Commit {
        uint256 commitId;
        uint256 projectId;
        address commiter;
        address erc20Token;
        uint256 amount;
        uint256 expiry;
    }

    function lastProjectId() external view returns (uint256);
    function lastCommitId() external view returns (uint256);
    function getProject(uint256) external view returns (Project memory);
    function getCommit(uint256) external view returns (Commit memory);

    function createProject(address projectAcceptedAsset) external;
    function redeem(uint256 projectId, uint256[] memory commitIds) external;
    function commit(
        uint256 projectId,
        uint256 amount,
        uint256 deadline
    ) external;
    function withdrawCommit(uint256 commitId) external;
}

contract CheckExpiring is Ownable {
    IPreCommitManager public preCommitManager;
    uint256 public minimumInterval;
    uint256 public warningTime;

    uint256 internal _lastCheckTime;

    event CommitExpiringWarning(uint256 commitId);

    constructor(IPreCommitManager preCommitManager_) {
        preCommitManager = preCommitManager_;
    }

    function checkAtMinInterval() external {
        if (_lastCheckTime != 0) {
            uint256 _nextCheckTime = _lastCheckTime + minimumInterval;
            require(
                block.timestamp >= _nextCheckTime,
                "CheckExpiring: minimum interval between checks has not elapsed"
            );
            _lastCheckTime = _nextCheckTime;
        } else {
            // execute the first time
            _lastCheckTime = block.timestamp;
        }
    }

    function checkExpiration() public {
        for (
            uint256 commitId = 0;
            commitId < preCommitManager.lastCommitId() + 1;
            commitId++
        ) {
            _checkExpiration(commitId);
        }
    }

    function _checkExpiration(uint256 commitId) internal {
        uint256 expiry = preCommitManager.getCommit(commitId).expiry;
        if (expiry == 0) {
            // commit already withdrawn
        } else if (
            expiry < block.timestamp + warningTime && expiry > block.timestamp
        ) {
            // expiring in less than 1 hour
            emit CommitExpiringWarning(commitId);
        }
    }

    function setPreCommitManager(IPreCommitManager preCommitManager_)
        external
        onlyOwner
    {
        preCommitManager = preCommitManager_;
    }

    function setMinimumInterval(uint256 minimumInterval_) external onlyOwner {
        minimumInterval = minimumInterval_;
    }

    function setWarningTime(uint256 warningTime_) external onlyOwner {
        warningTime = warningTime_;
    }
}