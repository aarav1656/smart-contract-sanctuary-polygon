// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/AutomationCompatible.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./VRFV2Consumer.sol";

contract Lottery is
    Ownable,
    ReentrancyGuard,
    VRFV2Consumer,
    AutomationCompatibleInterface
{
    using Counters for Counters.Counter;

    struct User {
        bool hasTicket;
        bool claimed;
        uint256[] tickets;
    }

    struct LotteryStruct {
        string name;
        uint256 ticketPrice;
        Counters.Counter ticketsCount;
        uint256 balance;
        bool finalized;
        uint256 indexChainLink;
        address winner;
        bool claimed;
        uint32 minTicket;
        bool finishTrigger;
        uint256 timeToFinish;
        uint256 timeToClaim;
    }

    mapping(uint256 => mapping(address => User)) ticketOwners;
    mapping(uint256 => mapping(uint256 => address)) tickets;
    mapping(uint256 => LotteryStruct) lottery;

    Counters.Counter public lotteryId;
    uint256 public fee;
    uint256 public configFinishTime;
    uint256 public configTimeToClaim;
    uint32 public minTicket;
    uint256 public ticketPrice;
    string public lotteryName;

    event TicketBought(
        address indexed buyer,
        uint256 price,
        uint256 ticketNumber
    );
    event MinTicketsReached(
        uint256 ticketNumber,
        uint32 minTickets,
        uint256 balance,
        uint256 finishTime
    );
    event LotteryFinalized(
        address owner,
        uint256 totalValue,
        uint256 ticketAmount
    );
    event ClaimedPrize(
        address indexed winner,
        uint256 lotteryIndex,
        uint256 totalPrize,
        uint256 fee
    );
    event ClaimedExpiredPrize(
        address indexed winner,
        address owner,
        uint256 lotteryIndex,
        uint256 totalPrize
    );
    event ChangedProperties(
        address indexed owner,
        string name,
        uint256 ticketPrize,
        uint256 fee,
        uint32 minTicket,
        uint256 configFinishTime,
        uint256 configTimeToClaim
    );

    constructor(
        uint64 _subscriptionId,
        address _cordinatorAddress,
        bytes32 _keyHash,
        string memory _name,
        uint256 _ticketPrice,
        uint32 _minTicket,
        uint256 _fee
    ) VRFV2Consumer(_subscriptionId, _cordinatorAddress, _keyHash) {
        uint256 currentLottery = lotteryId.current();

        lottery[currentLottery].name = _name;
        lottery[currentLottery].ticketPrice = _ticketPrice;
        lottery[currentLottery].minTicket = _minTicket;

        fee = _fee;
        lotteryName = _name;
        configFinishTime = 10 minutes;
        configTimeToClaim = 7 days;
        ticketPrice = _ticketPrice;
        minTicket = _minTicket;
    }

    function buyTicket() external payable nonReentrant {
        uint256 currentLottery = lotteryId.current();
        require(
            !lottery[currentLottery].finalized,
            "This lottery has already finalized, wait for results!"
        );
        require(
            lottery[currentLottery].ticketPrice == msg.value,
            "You need to pay the exactly ticket price."
        );

        uint256 currentLotteryPosition = lottery[currentLottery]
            .ticketsCount
            .current();
        lottery[currentLottery].ticketsCount.increment();

        ticketOwners[currentLottery][msg.sender].hasTicket = true;
        ticketOwners[currentLottery][msg.sender].claimed = false;
        ticketOwners[currentLottery][msg.sender].tickets.push(
            currentLotteryPosition
        );

        tickets[currentLottery][currentLotteryPosition] = msg.sender;
        lottery[currentLottery].balance += msg.value;

        uint256 nextLotteryPosition = lottery[currentLottery]
            .ticketsCount
            .current();

        if (
            !lottery[currentLottery].finishTrigger &&
            nextLotteryPosition >= lottery[currentLottery].minTicket
        ) {
            lottery[currentLottery].finishTrigger = true;
            lottery[currentLottery].timeToFinish =
                block.timestamp +
                configFinishTime;

            emit MinTicketsReached(
                nextLotteryPosition,
                lottery[currentLottery].minTicket,
                lottery[currentLottery].balance,
                lottery[currentLottery].timeToFinish
            );
        }

        emit TicketBought(msg.sender, msg.value, currentLottery);
    }

    function finalizeLottery() private {
        uint256 currentLottery = lotteryId.current();
        uint256 currentLotteryPosition = lottery[currentLottery]
            .ticketsCount
            .current();

        require(
            lottery[currentLottery].minTicket < currentLotteryPosition,
            "It Didnt reach min tickets yet."
        );

        require(
            !lottery[currentLottery].finalized,
            "Lottery already finalized."
        );

        lottery[currentLottery].finalized = true;
        lottery[currentLottery].indexChainLink = requestRandomWords(1);
        emit LotteryFinalized(
            msg.sender,
            lottery[currentLottery].balance,
            lottery[currentLottery].ticketsCount.current()
        );
    }

    function fulfillRandomWords(
        uint256 _requestId,
        uint256[] memory _randomWords
    ) internal override {
        super.fulfillRandomWords(_requestId, _randomWords);
        uint256 currentLottery = lotteryId.current();
        uint256 currentLotteryPosition = lottery[currentLottery]
            .ticketsCount
            .current();
        if (_requestId == lottery[currentLottery].indexChainLink) {
            lottery[currentLottery].winner = tickets[currentLottery][
                _randomWords[0] % currentLotteryPosition
            ];
            lottery[currentLottery].timeToClaim =
                block.timestamp +
                configFinishTime;
            require(resetLottery(), "Lottery needs to be reseted");
        }
    }

    function claim(uint256 lotteryIndex) external nonReentrant {
        require(
            !lottery[lotteryIndex].claimed,
            "The winner already claimed its prize."
        );
        require(
            lottery[lotteryIndex].finalized,
            "This lottery isn't finalized yet."
        );
        require(
            lottery[lotteryIndex].winner != address(0),
            "This lottery didn't get a winner yet."
        );
        require(
            lottery[lotteryIndex].winner == msg.sender,
            "You're not the winner."
        );
        require(
            ticketOwners[lotteryIndex][msg.sender].hasTicket,
            "You dont have any ticket to claim here."
        );
        require(
            !ticketOwners[lotteryIndex][msg.sender].claimed,
            "You have alread claimed your prize."
        );
        lottery[lotteryIndex].claimed = true;
        ticketOwners[lotteryIndex][msg.sender].hasTicket = false;
        ticketOwners[lotteryIndex][msg.sender].claimed = true;

        uint256 _feeAmount = _calcFee(lottery[lotteryIndex].balance);
        uint256 prize = lottery[lotteryIndex].balance - _feeAmount;

        payable(owner()).transfer(_feeAmount);
        payable(msg.sender).transfer(prize);
        emit ClaimedPrize(msg.sender, lotteryIndex, prize, _feeAmount);
    }

    function claimExpiredLottery(uint256 lotteryIndex) external onlyOwner {
        require(
            !lottery[lotteryIndex].claimed,
            "The winner already claimed its prize."
        );
        require(
            lottery[lotteryIndex].finalized,
            "This lottery isn't finalized yet."
        );
        require(
            lottery[lotteryIndex].winner != address(0),
            "This lottery didn't get a winner yet."
        );
        require(
            lottery[lotteryIndex].timeToClaim < block.timestamp,
            "You can't claim before timeToClaim get expired."
        );

        lottery[lotteryIndex].claimed = true;

        payable(owner()).transfer(lottery[lotteryIndex].balance);
        emit ClaimedExpiredPrize(lottery[lotteryIndex].winner, msg.sender, lotteryIndex, lottery[lotteryIndex].balance);
    }

    function resetLottery() private returns (bool) {
        lotteryId.increment();
        uint256 nextLottery = lotteryId.current();

        lottery[nextLottery].name = lotteryName;
        lottery[nextLottery].ticketPrice = ticketPrice;
        lottery[nextLottery].minTicket = minTicket;

        return true;
    }

    function _calcFee(uint256 amount) private view returns (uint256) {
        return (amount * fee) / 100;
    }

    function setProperties(
        string memory _name,
        uint256 _ticketPrice,
        uint32 _minTicket,
        uint256 _configFinishTime,
        uint256 _configTimeToClaim,
        uint256 _fee
    ) external onlyOwner {
        require(_fee <= 30, "Fee can't be better than 30%");

        fee = _fee;
        configFinishTime = _configFinishTime;
        configTimeToClaim = _configTimeToClaim;
        ticketPrice = _ticketPrice;
        minTicket = _minTicket;
        emit ChangedProperties(
            msg.sender,
            _name,
            _ticketPrice,
            _fee,
            _minTicket,
            _configFinishTime,
            _configTimeToClaim
        );
    }

    function getLotteryStatus(
        uint256 _lotteryId
    ) public view returns (LotteryStruct memory _lottery) {
        return lottery[_lotteryId];
    }

    function getUserStatus(
        uint256 _lotteryId,
        address _user
    ) public view returns (User memory _returnedUser) {
        return ticketOwners[_lotteryId][_user];
    }

    // Only if we have some problem to use this
    function getAllBalance() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function checkUpkeep(
        bytes calldata /* checkData */
    )
        external
        view
        override
        returns (bool upkeepNeeded, bytes memory /* performData */)
    {
        uint256 currentLottery = lotteryId.current();
        upkeepNeeded = (lottery[currentLottery].finishTrigger &&
            block.timestamp > lottery[currentLottery].timeToFinish);
    }

    function performUpkeep(bytes calldata /* performData */) external override {
        uint256 currentLottery = lotteryId.current();

        require(
            (lottery[currentLottery].finishTrigger &&
                block.timestamp > lottery[currentLottery].timeToFinish),
            "Not read yet"
        );
        finalizeLottery();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import '@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol';
import '@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol';

import "@openzeppelin/contracts/access/Ownable.sol";

contract VRFV2Consumer is VRFConsumerBaseV2, Ownable {
    event RequestSent(uint256 requestId, uint32 numWords);
    event RequestFulfilled(uint256 requestId, uint256[] randomWords);

    struct RequestStatus {
        bool fulfilled;
        bool exists;
        uint256[] randomWords;
    }

    mapping(uint256 => RequestStatus) public s_requests; /* requestId --> requestStatus */
    VRFCoordinatorV2Interface COORDINATOR;

    // Your subscription ID.
    uint64 s_subscriptionId;

    // past requests Id.
    uint256[] public requestIds;
    uint256 public lastRequestId;

    // The gas lane to use, which specifies the maximum gas price to bump to.
    // For a list of available gas lanes on each network,
    // see https://docs.chain.link/docs/vrf/v2/subscription/supported-networks/#configurations
    bytes32 keyHash;

    // Depends on the number of requested values that you want sent to the
    // fulfillRandomWords() function. Storing each word costs about 20,000 gas,
    // so 100,000 is a safe default for this example contract. Test and adjust
    // this limit based on the network that you select, the size of the request,
    // and the processing of the callback request in the fulfillRandomWords()
    // function.
    uint32 callbackGasLimit;

    // The default is 3, but you can set this higher.
    uint16 requestConfirmations;

    constructor(uint64 subscriptionId, address cordinatorAddress, bytes32 _keyHash)
        VRFConsumerBaseV2(cordinatorAddress)
    {
        COORDINATOR = VRFCoordinatorV2Interface(cordinatorAddress);
        s_subscriptionId = subscriptionId;
        keyHash = _keyHash;
        callbackGasLimit = 500000;
        requestConfirmations = 3;
    }

    // Assumes the subscription is funded sufficiently.
    function requestRandomWords(uint32 _numWords) internal returns (uint256 requestId) {
        // Will revert if subscription is not set and funded.
        requestId = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            _numWords
        );
        s_requests[requestId] = RequestStatus({randomWords: new uint256[](0), exists: true, fulfilled: false});
        requestIds.push(requestId);
        lastRequestId = requestId;
        emit RequestSent(requestId, _numWords);
        return requestId;
    }

    function fulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) internal virtual override {
        require(s_requests[_requestId].exists, 'request not found');
        s_requests[_requestId].fulfilled = true;
        s_requests[_requestId].randomWords = _randomWords;
        emit RequestFulfilled(_requestId, _randomWords);
    }

    function getRequestStatus(uint256 _requestId) external view returns (bool fulfilled, uint256[] memory randomWords) {
        require(s_requests[_requestId].exists, 'request not found');
        RequestStatus memory request = s_requests[_requestId];
        return (request.fulfilled, request.randomWords);
    }

    function setKeyHashValue(bytes32 _keyHash) external onlyOwner {
        keyHash = _keyHash;
    }

    function setCallBackGasLimit(uint32 _callBackGasLimit) external onlyOwner {
        callbackGasLimit = _callBackGasLimit;
    }

    function setRequestConfirmations(uint16 _requestConfirmations) external onlyOwner {
        requestConfirmations = _requestConfirmations;
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
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
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
pragma solidity ^0.8.0;

interface AutomationCompatibleInterface {
  /**
   * @notice method that is simulated by the keepers to see if any work actually
   * needs to be performed. This method does does not actually need to be
   * executable, and since it is only ever simulated it can consume lots of gas.
   * @dev To ensure that it is never called, you may want to add the
   * cannotExecute modifier from KeeperBase to your implementation of this
   * method.
   * @param checkData specified in the upkeep registration so it is always the
   * same for a registered upkeep. This can easily be broken down into specific
   * arguments using `abi.decode`, so multiple upkeeps can be registered on the
   * same contract and easily differentiated by the contract.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with, if
   * upkeep is needed. If you would like to encode data to decode later, try
   * `abi.encode`.
   */
  function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);

  /**
   * @notice method that is actually executed by the keepers, via the registry.
   * The data returned by the checkUpkeep simulation will be passed into
   * this method to actually be executed.
   * @dev The input to this method should not be trusted, and the caller of the
   * method should not even be restricted to any single registry. Anyone should
   * be able call it, and the input should be validated, there is no guarantee
   * that the data passed in is the performData returned from checkUpkeep. This
   * could happen due to malicious keepers, racing keepers, or simply a state
   * change while the performUpkeep transaction is waiting for confirmation.
   * Always validate the data passed in.
   * @param performData is the data which was passed back from the checkData
   * simulation. If it is encoded, it can easily be decoded into other types by
   * calling `abi.decode`. This data should not be trusted, and should be
   * validated against the contract's current state.
   */
  function performUpkeep(bytes calldata performData) external;
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
pragma solidity ^0.8.0;

import "./AutomationBase.sol";
import "./interfaces/AutomationCompatibleInterface.sol";

abstract contract AutomationCompatible is AutomationBase, AutomationCompatibleInterface {}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AutomationBase {
  error OnlySimulatedBackend();

  /**
   * @notice method that allows it to be simulated via eth_call by checking that
   * the sender is the zero address.
   */
  function preventExecution() internal view {
    if (tx.origin != address(0)) {
      revert OnlySimulatedBackend();
    }
  }

  /**
   * @notice modifier that allows it to be simulated via eth_call by checking
   * that the sender is the zero address.
   */
  modifier cannotExecute() {
    preventExecution();
    _;
  }
}