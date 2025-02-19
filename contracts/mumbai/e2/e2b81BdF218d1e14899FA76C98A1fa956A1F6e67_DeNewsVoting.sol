// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IDeNewsManager.sol";
import "../interfaces/IDeNewsMedia.sol";

contract DeNewsVoting is Ownable {
    IDeNewsManager DeNewsManager;
    IDeNewsMedia DeNewsMedia;

    uint256 public ballotID;
    uint256 public fakeHunterVoteAmount;
    uint256 public fakeHunterReward;
    uint256 public userVoteAmount;
    uint256 public voteTime; // in seconds
    uint256 public revealTime; // in seconds

    int256 public fakeHunterRatingDelta;

    mapping(string => bool) opportunityToVote; // Mapping to check if a vote was taken.
    mapping(uint256 => VotingBallot) public votingArchive;

    struct VotingBallot {
        address accusingFakeHunter;
        string newsMetadata;
        uint256 voteFor;
        uint256 voteAgainst;
        uint256 startTime;
        uint256 endVoteTime;
        uint256 endRevealTime;
        mapping(address => bool) alreadyVoted;
        mapping(address => bytes32) voteHash;
        mapping(address => bool) alreadyReveal;
        bool votingStatus; // voting status, true-open, false-close
    }

    function setDeNewsManagerContract(address _addressDeNewsManager)
        external
        onlyOwner
    {
        DeNewsManager = IDeNewsManager(_addressDeNewsManager);
    }

    function setDeNewsMediaContract(address _addressDeNewsMedia)
        external
        onlyOwner
    {
        DeNewsMedia = IDeNewsMedia(_addressDeNewsMedia);
    }

    function setFakeHunterVoteAmount(uint256 _amount) public onlyOwner {
        fakeHunterVoteAmount = _amount;
    }

    function setFakeHunterReward(uint256 _amount) public onlyOwner {
        fakeHunterReward = _amount;
    }

    function setFakeHunterRatingDelta(int256 _delta) public onlyOwner {
        fakeHunterRatingDelta = _delta;
    }

    function setUserVoteAmount(uint256 _amount) public onlyOwner {
        userVoteAmount = _amount;
    }

    function setVoteTime(uint256 _seconds) public onlyOwner {
        voteTime = _seconds;
    }

    function setRevealTime(uint256 _seconds) public onlyOwner {
        revealTime = _seconds;
    }

    function generateVoteHash(
        uint256 _ballotID,
        uint256 _amount,
        bool _vote,
        string memory password
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_ballotID, _amount, _vote, password));
    }

    function openVoting(string memory _cid, bytes32 _voteHash) external {
        (bool _fakeHunterAccreditation, ) = DeNewsManager.fakeHuntersInfo(
            msg.sender
        );
        uint256 _fakeHunterBalance = DeNewsManager.depositInfo(msg.sender);
        require(
            DeNewsManager.checkHumanVerify(msg.sender) == true,
            "You are no verified human!"
        );
        require(
            _fakeHunterAccreditation == true,
            "You are not an accredited fake hunter!"
        );
        require(
            _fakeHunterBalance >= fakeHunterVoteAmount,
            "You don't have enough funds to open voting!"
        );
        require(
            opportunityToVote[_cid] == false,
            "DeNewsVoting is in progress or already finished!"
        );
        opportunityToVote[_cid] = true;
        VotingBallot storage newVotingBallot = votingArchive[ballotID];
        newVotingBallot.accusingFakeHunter = msg.sender;
        newVotingBallot.newsMetadata = string.concat("ipfs://", _cid);
        newVotingBallot.voteFor = fakeHunterVoteAmount / 10**19;
        newVotingBallot.voteAgainst = 0;
        newVotingBallot.startTime = block.timestamp;
        newVotingBallot.endVoteTime = block.timestamp + voteTime;
        newVotingBallot.endRevealTime = block.timestamp + revealTime;
        newVotingBallot.alreadyVoted[msg.sender] = true;
        newVotingBallot.voteHash[msg.sender] = _voteHash;
        newVotingBallot.alreadyReveal[msg.sender] = true;
        newVotingBallot.votingStatus = true;
        uint256 _amount = fakeHunterVoteAmount;
        uint256 _reward = fakeHunterVoteAmount + fakeHunterReward;
        DeNewsManager.dataOfVote(
            msg.sender,
            ballotID,
            _amount,
            _reward,
            _voteHash
        );
        DeNewsMedia.safeMint(_cid, msg.sender);
        ballotID++;
    }

    function vote(
        uint256 _ballotID,
        uint256 _amount,
        bytes32 _voteHash
    ) external {
        uint256 _voterBalance = DeNewsManager.depositInfo(msg.sender);
        require(
            DeNewsManager.checkHumanVerify(msg.sender) == true,
            "You are no verified human!"
        );
        require(_amount >= userVoteAmount, "Need more tokens!");
        require(
            _amount <= _voterBalance,
            "You don't have enough money to vote!"
        );
        require(
            votingArchive[_ballotID].votingStatus == true,
            "DeNewsVoting is closed!"
        );
        require(
            votingArchive[_ballotID].alreadyVoted[msg.sender] == false,
            "You have already voted!"
        );
        require(
            votingArchive[_ballotID].endVoteTime > block.timestamp,
            "Time to vote is up!"
        );
        votingArchive[_ballotID].voteHash[msg.sender] = _voteHash;
        votingArchive[_ballotID].alreadyVoted[msg.sender] = true;
        uint256 _reward = _amount + (_amount * 5) / 100;
        DeNewsManager.dataOfVote(
            msg.sender,
            _ballotID,
            _amount,
            _reward,
            _voteHash
        );
    }

    function revealVote(
        uint256 _ballotID,
        bool _vote,
        string memory password
    ) public {
        require(
            votingArchive[_ballotID].endVoteTime <= block.timestamp,
            "Voting time is not over yet!"
        );
        require(
            votingArchive[_ballotID].endRevealTime > block.timestamp,
            "Time to reveal is up!"
        );
        require(
            votingArchive[_ballotID].alreadyReveal[msg.sender] == false,
            "You have already reveal!"
        );
        (uint256 _amount, , , ) = DeNewsManager.participationInVotingInfo(
            msg.sender,
            _ballotID
        );
        require(
            votingArchive[_ballotID].voteHash[msg.sender] ==
                generateVoteHash(_ballotID, _amount, _vote, password),
            "The entered data does not match!"
        );
        votingArchive[_ballotID].alreadyReveal[msg.sender] = true;
        uint256 _voteWeight = _amount / 10**19;
        if (_vote == true) {
            votingArchive[_ballotID].voteFor += _voteWeight;
        } else {
            votingArchive[_ballotID].voteAgainst += _voteWeight;
        }
    }

    function endOfVoting(uint256 _ballotID) public onlyOwner {
        require(
            votingArchive[_ballotID].endVoteTime <= block.timestamp,
            "Voting time is not over yet!"
        );
        require(
            votingArchive[_ballotID].endRevealTime <= block.timestamp,
            "Reveal time is not over yet!"
        );
        votingArchive[_ballotID].votingStatus = false;
        address _fakeHunter = votingArchive[_ballotID].accusingFakeHunter;
        if (
            votingArchive[_ballotID].voteFor >
            votingArchive[_ballotID].voteAgainst
        ) {
            DeNewsManager.changeRatingFakeHunter(
                _fakeHunter,
                fakeHunterRatingDelta
            );
        } else if (
            votingArchive[_ballotID].voteFor <=
            votingArchive[_ballotID].voteAgainst
        ) {
            DeNewsManager.changeRatingFakeHunter(
                _fakeHunter,
                -fakeHunterRatingDelta
            );
        }
    }

    function votingArchiveInfo(uint256 _ballotID)
        public
        view
        returns (
            address,
            uint256,
            uint256,
            uint256,
            uint256,
            bool
        )
    {
        return (
            votingArchive[_ballotID].accusingFakeHunter,
            votingArchive[_ballotID].voteFor,
            votingArchive[_ballotID].voteAgainst,
            votingArchive[_ballotID].endVoteTime,
            votingArchive[_ballotID].endRevealTime,
            votingArchive[_ballotID].votingStatus
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

interface IDeNewsManager {
    function fakeHuntersInfo(address _from)
        external
        view
        returns (bool, int256);

    function depositInfo(address _user) external view returns (uint256);

    function checkHumanVerify(address _user) external view returns (bool);

    function participationInVotingInfo(address _voter, uint256 _ballotID)
        external
        view
        returns (
            uint256,
            uint256,
            bytes32,
            bool
        );

    function changeRatingFakeHunter(address _address, int256 delta) external;

    function dataOfVote(
        address _voter,
        uint256 _ballotID,
        uint256 _lockedAmount,
        uint256 _lockedAmountWithReward,
        bytes32 _voteHash
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

interface IDeNewsMedia {
    function safeMint(string memory _cid, address _fakeHunter) external;
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