// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface VRFCoordinatorV2Interface {
  /**
   * @notice Get configuration relevant for making requests
   * @return minimumRequestConfirmations global min for request confirmations
   * @return maxGasLimit global max for request gas limit
   * @return s_provingKeyHashes list of registered key hashes
   */
  function getRequestConfig()
    external
    view
    returns (
      uint16,
      uint32,
      bytes32[] memory
    );

  /**
   * @notice Request a set of random words.
   * @param keyHash - Corresponds to a particular oracle job which uses
   * that key for generating the VRF proof. Different keyHash's have different gas price
   * ceilings, so you can select a specific one to bound your maximum per request cost.
   * @param subId  - The ID of the VRF subscription. Must be funded
   * with the minimum subscription balance required for the selected keyHash.
   * @param minimumRequestConfirmations - How many blocks you'd like the
   * oracle to wait before responding to the request. See SECURITY CONSIDERATIONS
   * for why you may want to request more. The acceptable range is
   * [minimumRequestBlockConfirmations, 200].
   * @param callbackGasLimit - How much gas you'd like to receive in your
   * fulfillRandomWords callback. Note that gasleft() inside fulfillRandomWords
   * may be slightly less than this amount because of gas used calling the function
   * (argument decoding etc.), so you may need to request slightly more than you expect
   * to have inside fulfillRandomWords. The acceptable range is
   * [0, maxGasLimit]
   * @param numWords - The number of uint256 random values you'd like to receive
   * in your fulfillRandomWords callback. Note these numbers are expanded in a
   * secure way by the VRFCoordinator from a single random value supplied by the oracle.
   * @return requestId - A unique identifier of the request. Can be used to match
   * a request to a response in fulfillRandomWords.
   */
  function requestRandomWords(
    bytes32 keyHash,
    uint64 subId,
    uint16 minimumRequestConfirmations,
    uint32 callbackGasLimit,
    uint32 numWords
  ) external returns (uint256 requestId);

  /**
   * @notice Create a VRF subscription.
   * @return subId - A unique subscription id.
   * @dev You can manage the consumer set dynamically with addConsumer/removeConsumer.
   * @dev Note to fund the subscription, use transferAndCall. For example
   * @dev  LINKTOKEN.transferAndCall(
   * @dev    address(COORDINATOR),
   * @dev    amount,
   * @dev    abi.encode(subId));
   */
  function createSubscription() external returns (uint64 subId);

  /**
   * @notice Get a VRF subscription.
   * @param subId - ID of the subscription
   * @return balance - LINK balance of the subscription in juels.
   * @return reqCount - number of requests for this subscription, determines fee tier.
   * @return owner - owner of the subscription.
   * @return consumers - list of consumer address which are able to use this subscription.
   */
  function getSubscription(uint64 subId)
    external
    view
    returns (
      uint96 balance,
      uint64 reqCount,
      address owner,
      address[] memory consumers
    );

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @param newOwner - proposed new owner of the subscription
   */
  function requestSubscriptionOwnerTransfer(uint64 subId, address newOwner) external;

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @dev will revert if original owner of subId has
   * not requested that msg.sender become the new owner.
   */
  function acceptSubscriptionOwnerTransfer(uint64 subId) external;

  /**
   * @notice Add a consumer to a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - New consumer which can use the subscription
   */
  function addConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Remove a consumer from a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - Consumer to remove from the subscription
   */
  function removeConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Cancel a subscription
   * @param subId - ID of the subscription
   * @param to - Where to send the remaining LINK to
   */
  function cancelSubscription(uint64 subId, address to) external;

  /*
   * @notice Check to see if there exists a request commitment consumers
   * for all consumers and keyhashes for a given sub.
   * @param subId - ID of the subscription
   * @return true if there exists at least one unfulfilled request for the subscription, false
   * otherwise.
   */
  function pendingRequestExists(uint64 subId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/** ****************************************************************************
 * @notice Interface for contracts using VRF randomness
 * *****************************************************************************
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * @dev to Vera the verifier in such a way that Vera can be sure he's not
 * @dev making his output up to suit himself. Reggie provides Vera a public key
 * @dev to which he knows the secret key. Each time Vera provides a seed to
 * @dev Reggie, he gives back a value which is computed completely
 * @dev deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * @dev correctly computed once Reggie tells it to her, but without that proof,
 * @dev the output is indistinguishable to her from a uniform random sample
 * @dev from the output space.
 *
 * @dev The purpose of this contract is to make it easy for unrelated contracts
 * @dev to talk to Vera the verifier about the work Reggie is doing, to provide
 * @dev simple access to a verifiable source of randomness. It ensures 2 things:
 * @dev 1. The fulfillment came from the VRFCoordinator
 * @dev 2. The consumer contract implements fulfillRandomWords.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constructor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash). Create subscription, fund it
 * @dev and your consumer contract as a consumer of it (see VRFCoordinatorInterface
 * @dev subscription management functions).
 * @dev Call requestRandomWords(keyHash, subId, minimumRequestConfirmations,
 * @dev callbackGasLimit, numWords),
 * @dev see (VRFCoordinatorInterface for a description of the arguments).
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomWords method.
 *
 * @dev The randomness argument to fulfillRandomWords is a set of random words
 * @dev generated from your requestId and the blockHash of the request.
 *
 * @dev If your contract could have concurrent requests open, you can use the
 * @dev requestId returned from requestRandomWords to track which response is associated
 * @dev with which randomness request.
 * @dev See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ.
 *
 * *****************************************************************************
 * @dev SECURITY CONSIDERATIONS
 *
 * @dev A method with the ability to call your fulfillRandomness method directly
 * @dev could spoof a VRF response with any random value, so it's critical that
 * @dev it cannot be directly called by anything other than this base contract
 * @dev (specifically, by the VRFConsumerBase.rawFulfillRandomness method).
 *
 * @dev For your users to trust that your contract's random behavior is free
 * @dev from malicious interference, it's best if you can write it so that all
 * @dev behaviors implied by a VRF response are executed *during* your
 * @dev fulfillRandomness method. If your contract must store the response (or
 * @dev anything derived from it) and use it later, you must ensure that any
 * @dev user-significant behavior which depends on that stored value cannot be
 * @dev manipulated by a subsequent VRF request.
 *
 * @dev Similarly, both miners and the VRF oracle itself have some influence
 * @dev over the order in which VRF responses appear on the blockchain, so if
 * @dev your contract could have multiple VRF requests in flight simultaneously,
 * @dev you must ensure that the order in which the VRF responses arrive cannot
 * @dev be used to manipulate your contract's user-significant behavior.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request. It is for this reason that
 * @dev that you can signal to an oracle you'd like them to wait longer before
 * @dev responding to the request (however this is not enforced in the contract
 * @dev and so remains effective only in the case of unmodified oracle software).
 */
abstract contract VRFConsumerBaseV2 {
  error OnlyCoordinatorCanFulfill(address have, address want);
  address private immutable vrfCoordinator;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   */
  constructor(address _vrfCoordinator) {
    vrfCoordinator = _vrfCoordinator;
  }

  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBaseV2 expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomWords the VRF output expanded to the requested number of words
   */
  function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal virtual;

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomWords(uint256 requestId, uint256[] memory randomWords) external {
    if (msg.sender != vrfCoordinator) {
      revert OnlyCoordinatorCanFulfill(msg.sender, vrfCoordinator);
    }
    fulfillRandomWords(requestId, randomWords);
  }
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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import "hardhat/console.sol";

error MatchMaker__HostCannotPlay();
error MatchMaker__NotPaidGamer();
error MatchMaker__NoCurrentRolledToken();

contract MatchMaker is VRFConsumerBaseV2, ReentrancyGuard, Ownable {

    using Counters for Counters.Counter;

    Counters.Counter public tournamentCounter;
    Counters.Counter public matchCounter;
    Counters.Counter public playerCounter;

    struct TournamentStruct {
        uint256 tournamentId;
        TournamentState tournamentState;
        uint32 currentGamerCount;
        uint32 maxGamerCount;
        address hostAddress;
        address winnerAddress;
        address feeTokenAddress;
        uint256 feeAmount;
        uint256 hostFeePercentage;
    }

    struct MatchStruct {
        MatchState matchState;
        uint256 matchId;
        uint256 tournamentId;
        address gamerA;
        address gamerB;
        address winnerAddress;
        uint256 hostFeePercentage;
        bytes32 winType;
    }

    struct VrfRequest {
        uint256 requestId;
        uint256 num_words;
    }

    enum MatchState {
        Started,
        Finished
    }

    enum TournamentState {
        GatheringPlayers,
        Started,
        Finished
    }

    address public rootOwner;
    uint64 private subId;
    bool public shouldUseVRF = true;
    VRFCoordinatorV2Interface public vrfCoordinatorV2;

    mapping(uint256 => TournamentStruct) public matchToTournamentMap;
    mapping(uint256 => MatchStruct) public matchToMatchInfoMap;
    mapping(uint256 => TournamentStruct) public tournamentToTournamentInfoMap;
    mapping(uint256 => VrfRequest) private tournamentToRequest;
    mapping(uint256 => uint256) private requestToTournamentId;
    mapping(uint256 =>  mapping(uint256 => address)) public playerIdToPlayerAddress;
    mapping(uint256 => mapping(address => uint256)) public playerAddressToPlayerId;
    mapping(uint256 => mapping(uint256 => bool)) public tournamentToPlayerIdStatus;
    mapping(uint256 => mapping(uint256 => bool)) public tournamentToPlayerMatchStatus;
    mapping(uint256 => uint256[]) public tournamentToPlayers; // initial order by player arrival
    mapping(uint256 => uint256[]) public tournamentToPlayerMatches; // random sequence
    mapping(address => uint256[]) public paidTournamentIds;

    uint256[] public allTournaments;
    uint256[] public allMatches;
    uint256[] public lastRandomWords;

    bytes32 public gasLane;
    uint16 public MIN_CONFIRMATIONS;
    uint32 public GAS_LIMIT;

    //-------------------------------------------------------------------------
    // EVENTS
    //-------------------------------------------------------------------------
    event TournamentCreated(
        uint256 indexed tournamentId,
        address indexed tournamentHost,
        uint256 timestamp
    );

    event PlayerJoinedTournament(
        uint256 indexed tournamentId,
        address joiner
    );

    event TournamentMatched(
        uint256 indexed tournamentId
    );

    event WinnerPaid(
        uint256 indexed tournamentId,
        address winner
    );

    event HostPaid(
        uint256 indexed tournamentId,
        address host
    );

    //-------------------------------------------------------------------------
    // CONSTRUCTOR
    //-------------------------------------------------------------------------

    constructor(
        address _vrfCoordinatorV2,
        uint64 _subId,
        bytes32 _gaslane,
        uint16 _minConfirmations,
        uint32 gas_limit
    ) VRFConsumerBaseV2(_vrfCoordinatorV2) {
        rootOwner = owner();
        subId = _subId;
        gasLane = _gaslane;
        vrfCoordinatorV2 = VRFCoordinatorV2Interface(_vrfCoordinatorV2);
        MIN_CONFIRMATIONS = _minConfirmations;
        GAS_LIMIT = gas_limit;
    }

    // receive() external payable {
    //     emit Receive(msg.sender, msg.value);
    // }

    //-------------------------------------------------------------------------
    // EXTERNAL FUNCTIONS
    //-------------------------------------------------------------------------

    function createTournament(
        uint32 _maxGamerCount,
        address _feeToken,
        uint256 _feeAmount
    ) external nonReentrant {
        //get 500 random words from vrf
        require(_maxGamerCount > 0 && _feeAmount > 0 && _feeToken != address(0), "INVALID_TOURNAMENT_PARAMS");
        tournamentCounter.increment();
        uint256 tournamentId = tournamentCounter.current();
        tournamentToTournamentInfoMap[tournamentId] = TournamentStruct(
            tournamentId,
            TournamentState.GatheringPlayers,
            0,
            _maxGamerCount,
            msg.sender,
            address(0),
            _feeToken,
            _feeAmount,
            20
        );
        emit TournamentCreated(tournamentId, msg.sender, block.timestamp);
    }

    function startTournament(uint256 _tournamentId) external nonReentrant {
        TournamentStruct storage currentTournament = tournamentToTournamentInfoMap[_tournamentId];
        // check if host
        require(currentTournament.hostAddress == msg.sender, "ONLY_HOST");
        // check if tournament started already
        require(currentTournament.tournamentState == TournamentState.GatheringPlayers, "TOURNAMENT_STARTED_ALREADY");
        // check if players joined
        require(currentTournament.currentGamerCount >= 1, "PLAYERS_LESS_THAN_MIN");
        // match making
        if (currentTournament.currentGamerCount == 1) {
            currentTournament.winnerAddress =
             playerIdToPlayerAddress[_tournamentId][tournamentToPlayers[_tournamentId][0]];
            currentTournament.tournamentState = TournamentState.Finished;
        } else if (currentTournament.currentGamerCount == 2){
            tournamentToPlayerMatches[_tournamentId].push(tournamentToPlayers[_tournamentId][0]);
            tournamentToPlayerMatches[_tournamentId].push(tournamentToPlayers[_tournamentId][1]);
            currentTournament.tournamentState = TournamentState.Started;
            emit TournamentMatched(_tournamentId);
        } else {
            currentTournament.tournamentState = TournamentState.Started;
            requestRandomnessOracle(_tournamentId, currentTournament.currentGamerCount * 5);
        }
    }

    function joinTournament(uint256 _tournamentId) external nonReentrant {
        // check if tournament exists
        require(tournamentToTournamentInfoMap[_tournamentId].tournamentId != 0, "TOURNAMENT_NOT_EXIST");
        TournamentStruct storage currentTournament = tournamentToTournamentInfoMap[_tournamentId];
        // check if GatheringPlayers
        require(currentTournament.tournamentState == TournamentState.GatheringPlayers, "TOURNAMENT_CANNOT_JOINED");
        // host address cannot join
        require(currentTournament.hostAddress != msg.sender, "HOST_CANNOT_JOIN");
        // max participants check
        require(currentTournament.currentGamerCount < currentTournament.maxGamerCount, "MAX_PARTICIPANTS");
        // player is joining the game 1st time
        if (playerAddressToPlayerId[_tournamentId][msg.sender] == 0) {
            // check fee TODO: uncomment fee before production
            require(
                IERC20(currentTournament.feeTokenAddress).transferFrom(
                    msg.sender,
                    address(this),
                    currentTournament.feeAmount
                ) == true,
                "FEE_TOKEN_NOT_APPROVED"
            );
            uint256 playerId = tournamentToPlayers[_tournamentId].length + 1;
            playerAddressToPlayerId[_tournamentId][msg.sender] = playerId;
            playerIdToPlayerAddress[_tournamentId][playerId] = msg.sender;
            tournamentToPlayers[_tournamentId].push(playerId);
            tournamentToPlayerIdStatus[_tournamentId][playerId] = true;
            currentTournament.currentGamerCount = currentTournament.currentGamerCount + 1;
            emit PlayerJoinedTournament(_tournamentId, msg.sender);
        } else {
            uint256 _playerId = playerAddressToPlayerId[_tournamentId][msg.sender];
            // check if player is already in this tournament
            require(tournamentToPlayerIdStatus[_tournamentId][_playerId] == false, "PLAYER_CANNOT_REJOIN");
            // check fee TODO: uncomment fee before production
            require(
                IERC20(currentTournament.feeTokenAddress).transferFrom(
                    msg.sender,
                    address(this),
                    currentTournament.feeAmount
                ) == true,
                "FEE_TOKEN_NOT_APPROVED"
            );
            tournamentToPlayers[_tournamentId].push(_playerId);
            tournamentToPlayerIdStatus[_tournamentId][_playerId] = true;
            currentTournament.currentGamerCount = currentTournament.currentGamerCount + 1;
            emit PlayerJoinedTournament(_tournamentId, msg.sender);
        }
    }

    function decideTournamentFinalWinner(uint256 _tournamentId, address _winnerAddress) external nonReentrant {
        // check if host    
        require(tournamentToTournamentInfoMap[_tournamentId].hostAddress == msg.sender, "ONLY_HOST");
        TournamentStruct storage currentTournament = tournamentToTournamentInfoMap[_tournamentId];
        // check tournament started
        require(
            currentTournament.tournamentState == TournamentState.Started,
            "TOURNAMENT_CANNOT_END"
        );
        // check winner address
        require(playerAddressToPlayerId[_tournamentId][_winnerAddress] != 0, "INVALID_WINNER");

        currentTournament.winnerAddress = _winnerAddress;
        currentTournament.tournamentState = TournamentState.Finished;
        //payout final winner and others
        uint256 feeAfterRoot = currentTournament.feeAmount - (currentTournament.feeAmount / 10);
        uint256 hostReward = (feeAfterRoot * currentTournament.hostFeePercentage ) / 100;
        IERC20(currentTournament.feeTokenAddress).transfer(currentTournament.hostAddress, hostReward);
        paidTournamentIds[currentTournament.hostAddress].push(_tournamentId);
        emit HostPaid(_tournamentId, currentTournament.hostAddress);
        IERC20(currentTournament.feeTokenAddress).transfer(_winnerAddress, feeAfterRoot - hostReward);
        paidTournamentIds[_winnerAddress].push(_tournamentId);
        emit WinnerPaid(_tournamentId, _winnerAddress);
    }

    //-------------------------------------------------------------------------
    // INTERNAL FUNCTIONS
    //-------------------------------------------------------------------------

    function randomMatchMaking(
        uint256 rand1,
        uint256 rand2,
        uint256 rand3,
        uint256 price
    ) internal virtual returns (uint256, bytes32) {
        //use 500 random words % numberOfPeople
    }

    function requestRandomnessOracle(uint256 _tournamentId, uint32 num_Words) internal {
        if (shouldUseVRF) {
            uint256 requestId = vrfCoordinatorV2.requestRandomWords(
                gasLane,
                subId,
                MIN_CONFIRMATIONS,
                GAS_LIMIT,
                num_Words
            );
            tournamentToRequest[_tournamentId] = VrfRequest(requestId, num_Words);
            requestToTournamentId[requestId] = _tournamentId;
            // emit RequestRandomness(requestId);
        }
    }


    /**
     * @dev Callback function used by VRF Coordinator
     */
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        uint256 _tournamentId = requestToTournamentId[requestId];
       uint256 _totalPlayersInTournament = tournamentToPlayers[_tournamentId].length;
        for (uint256 i = 0; i < randomWords.length && tournamentToPlayerMatches[_tournamentId].length < _totalPlayersInTournament; i++) {
            uint256 rand = uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, randomWords[i])));
            unchecked {
                rand = (rand % _totalPlayersInTournament) + 1;
            }
            if (tournamentToPlayerMatchStatus[_tournamentId][rand] == false) {
                tournamentToPlayerMatches[_tournamentId].push(rand);
                tournamentToPlayerMatchStatus[_tournamentId][rand] = true;
            }
             else {
                unchecked {
                    rand = (rand % _totalPlayersInTournament) + 1;
                }
                while (rand <= _totalPlayersInTournament && tournamentToPlayerMatches[_tournamentId].length < _totalPlayersInTournament) {
                    if (tournamentToPlayerMatchStatus[_tournamentId][rand] == false) {
                        tournamentToPlayerMatches[_tournamentId].push(rand);
                        tournamentToPlayerMatchStatus[_tournamentId][rand] = true;
                        break;
                    }
                    rand = rand + 1;
                }
            }
        }
        emit TournamentMatched(_tournamentId);
    }

    function getTournamentMatches(uint256 _tournamentId) external view returns (uint256[] memory) {
       return tournamentToPlayerMatches[_tournamentId];
    }

    function getTournamentPlayers(uint256 _tournamentId) external view returns (uint256[] memory) {
       return tournamentToPlayers[_tournamentId];
    }

    function getEarnings(address _user) external view returns (TournamentStruct[] memory) {
       uint256[] memory _paidTournaments = paidTournamentIds[_user];
       TournamentStruct[] memory tournaments = new TournamentStruct[](_paidTournaments.length);
       if(_paidTournaments.length > 0){
        for (uint256 i = 0; i < _paidTournaments.length; i++) {
         tournaments[i] = tournamentToTournamentInfoMap[_paidTournaments[i]];
        }
       }
       return tournaments;
    }

    function toBytes(uint256 x) internal pure returns (bytes memory b) {
        b = new bytes(32);
        assembly {
            mstore(add(b, 32), x)
        }
    }

    function toggleShouldUseVRF(bool _shouldUseVRF) external onlyOwner {
        shouldUseVRF = _shouldUseVRF;
    }

        // function requestRandomnessNonOracle(
    //     RollState _rollState,
    //     uint256 _amount,
    //     address _token
    // ) internal {
    //     uint256[] memory rand = new uint256[](3);
    //     rand[0] = msg.value;
    //     rand[1] = msg.value + 10;
    //     rand[2] = msg.value + 20;

    //     uint256 requestId = nonVRFRequestIdCounter.current();
    //     vrfRequestsMap[requestId] = VRFRequest(_rollState, msg.sender, _token, requestId, _amount, 0, 0, 0, 0, "");
    //     requestToPlayersAddress[requestId] = msg.sender;

    //     emit RequestRandomness(requestId);
    //     fulfillRandomWords(requestId, rand);
    //     nonVRFRequestIdCounter.increment();
    // }

    // function randomGenInternal(uint256 _seed) internal virtual returns (uint256 randomNumber) {
    //     uint256 source = block.difficulty + block.timestamp + _seed;
    //     bytes memory source_b = toBytes(source);
    //     return (uint256(keccak256(source_b)) % 15) + 1;
    // }
    //-------------------------------------------------------------------------
    // ONLY OWNER FUNCTIONS
    //-------------------------------------------------------------------------

    // function cashout(uint256 _amount) external nonReentrant onlyOwner {
    //     rootOwner = owner();
    //     (bool sent, ) = rootOwner.call{value: _amount}("");
    //     if (!sent) {
    //         revert SlotMachine__TransferFailed();
    //     }
    // }

    // function setChainlinkSubID(uint64 _subscriptionId) external onlyOwner {
    //     subscriptionId = _subscriptionId;
    // }


    //      function fulfillRandomWordsTest(uint256 _tournamentId, uint256[] memory randomWords) internal {
    //     // uint256 _tournamentId = requestToTournamentId[requestId];
    //     uint256 _totalPlayersInTournament = tournamentToPlayers[_tournamentId].length;
    //     for (uint256 i = 0; i < randomWords.length && tournamentToPlayerMatches[_tournamentId].length < _totalPlayersInTournament; i++) {
    //         uint256 rand = uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, randomWords[i])));
    //         unchecked {
    //             rand = (rand % _totalPlayersInTournament) + 1;
    //         }
    //         if (tournamentToPlayerMatchStatus[_tournamentId][rand] == false) {
    //             tournamentToPlayerMatches[_tournamentId].push(rand);
    //             tournamentToPlayerMatchStatus[_tournamentId][rand] = true;
    //         }
    //          else {
    //             // rand = rand + 1;
    //             unchecked {
    //                 rand = (rand % _totalPlayersInTournament) + 1;
    //             }
    //             while (rand <= _totalPlayersInTournament && tournamentToPlayerMatches[_tournamentId].length < _totalPlayersInTournament) {
    //                 if (tournamentToPlayerMatchStatus[_tournamentId][rand] == false) {
    //                     tournamentToPlayerMatches[_tournamentId].push(rand);
    //                     tournamentToPlayerMatchStatus[_tournamentId][rand] = true;
    //                     break;
    //                 }
    //                 rand = rand + 1;
    //             }
    //         }
    //     }
    //     emit TournamentMatched(_tournamentId);
    // }

    // function startTournamentTest(uint256 _tournamentId, uint256[] memory randomWords) external nonReentrant {
    //     TournamentStruct storage currentTournament = tournamentToTournamentInfoMap[_tournamentId];
    //     // check if host
    //     require(currentTournament.hostAddress == msg.sender, "ONLY_HOST");
    //     // check if players joined
    //     require(currentTournament.currentGamerCount >= 1, "PLAYERS_LESS_THAN_MIN");
    //     // match making
    //     if (currentTournament.currentGamerCount == 1) {
    //         currentTournament.winnerAddress =
    //          playerIdToPlayerAddress[_tournamentId][tournamentToPlayers[_tournamentId][0]];
    //         currentTournament.tournamentState = TournamentState.Finished;
    //     } else if (currentTournament.currentGamerCount == 2){
    //         tournamentToPlayerMatches[_tournamentId].push(tournamentToPlayers[_tournamentId][0]);
    //         tournamentToPlayerMatches[_tournamentId].push(tournamentToPlayers[_tournamentId][1]);
    //         currentTournament.tournamentState = TournamentState.Started;
    //         emit TournamentMatched(_tournamentId);
    //     } else {
    //         currentTournament.tournamentState = TournamentState.Started;
    //         fulfillRandomWordsTest(_tournamentId, randomWords);
    //     }
    // }

}