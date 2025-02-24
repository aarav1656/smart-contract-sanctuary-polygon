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

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0;

import '@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol';
import '@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol';

contract Coinflip is VRFConsumerBaseV2 {

    // =============================================================
    //                            STORAGE
    // =============================================================

    uint256 public minValue = 0.001 ether;
    uint256 public sumPlayersMoney = 0;
    address public owner;
    address public pool;
    bool public pause;
    
    struct RequestStatus {
        bool fulfilled; // whether the request has been successfully fulfilled
        bool exists; // whether a requestId exists
        uint256[] randomWords;
    }

    struct GameStart {
        address player;
        uint256 deposit;
        uint256 numOfIterations;
        bool choice;
    }

    struct GameRes {
        uint256 result;
        uint256 randNumber;
    }

    mapping(address => uint256) public totalWinsOfPlayer;
    mapping(uint256 => GameStart) public gamesStart;
    mapping(address => GameRes[]) public gamesResult;
    mapping(uint256 => RequestStatus) public s_requests; /* requestId --> requestStatus */
    VRFCoordinatorV2Interface COORDINATOR;

    uint256[] public requestIds;
    uint256 public lastRequestId;
    uint64 public s_subscriptionId;
    address vrfCoordinator;

    uint32 public callbackGasLimit;
    uint16 requestConfirmations = 3;
    uint32 numWords =  1;
    bytes32 public keyHash;

    event RequestSent(uint256 requestId, uint32 numWords);
    event RequestFulfilled(uint256 requestId, uint256[] randomWords);

    // =============================================================
    //                            Modifiers
    // =============================================================
    
    modifier onlyOwner() {
        require (msg.sender == owner, 'only owner');
        _;
    }

    modifier isVRFCoordinator {
        require(vrfCoordinator == msg.sender, "You are not allowed");
        _;
    }

    // =============================================================
    //                               Events
    // =============================================================

    event GameStartEvent(
        address indexed userAddress,
        uint256 indexed volumeOfGame,
        uint256 indexed numOfGames,
        bool choise
    );

    event GameResEvent(
        uint256 indexed winAmount,
        address indexed userAddress,
        uint256 result,
        uint256 gameNumber
    );

    // =============================================================
    //                            Admin functions
    // =============================================================

    function setCallbackGasLimit(uint32 newCallbackGasLimit) public onlyOwner {
        callbackGasLimit = newCallbackGasLimit;
    }

    function setRequestConfirmations(uint16 newRequestConfirmations) public onlyOwner {
        requestConfirmations = newRequestConfirmations;
    }

    function setPoolAddress(address newPool) public onlyOwner {
        pool = newPool;
    }

    function setPause(bool pauseState) public onlyOwner {
        pause = pauseState;
    }

    function changeMinValue(uint256 newMinValue) external onlyOwner {
        minValue = newMinValue;
    }

    // =============================================================
    //                            View functions
    // =============================================================

    function getMyBalance() external view returns (uint256) {
        return totalWinsOfPlayer[msg.sender];
    }

    function getLastPlayerGame(address player)
        external
        view
        returns (
            uint256,
            uint256
        )
    {
        uint256 length = gamesResult[player].length - 1;
        return (
            gamesResult[player][length].result,
            gamesResult[player][length].randNumber
        );
    }

    function getLastNPlayerGames(address player, uint8 n)
        external
        view
        returns (
            GameRes[] memory
        )
    {
        require(gamesResult[player].length >= n, "Out of limits");

        GameRes[] memory result = new GameRes[](n);
        uint8 counter = 0;

        for (uint256 i = (gamesResult[player].length - n); i <= (gamesResult[player].length - 1); i++){
            result[counter] = gamesResult[player][i];
            counter++;
        }

        return (result);
    }

    function getRequestStatus(uint256 _requestId) external view returns (bool fulfilled, uint256[] memory randomWords) {
        require(s_requests[_requestId].exists, 'request not found');
        RequestStatus memory request = s_requests[_requestId];
        return (request.fulfilled, request.randomWords);
    }

    // =============================================================
    //                     First roll functions
    // =============================================================

    function startRoll(uint256 iter, bool _choice) external payable returns (uint256 requestId) {
        requestId = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );

        require(iter == 1 || iter == 2 || iter == 5 || iter == 10, "iter out of limit");
        require(!pause, "contract is paused");
        require(msg.value > minValue, "deposit is too low");
        require(msg.value < (address(pool).balance / 100 * 5), "deposit is too high");

        s_requests[requestId] = RequestStatus({randomWords: new uint256[](0), exists: true, fulfilled: false});
        requestIds.push(requestId);
        lastRequestId = requestId;

        (bool success, ) = pool.call{value: msg.value}("");
        require(success);

        emit RequestSent(requestId, numWords);

        gamesStart[requestId] = GameStart(msg.sender, msg.value, iter, _choice);

        emit GameStartEvent(msg.sender, msg.value, iter, _choice);
        return requestId;
    }

    // =============================================================
    //                      Second roll functions
    // =============================================================

    function fulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) internal override isVRFCoordinator {
        require(s_requests[_requestId].exists, 'request not found');
        s_requests[_requestId].fulfilled = true;
        s_requests[_requestId].randomWords = _randomWords;
        emit RequestFulfilled(_requestId, _randomWords);

        uint256 reward = 0;
        for (uint i = 0; i<(gamesStart[_requestId].numOfIterations); i++) {
            reward += endRoll(
                _requestId,
                (_randomWords[0] % 10)
            );
            _randomWords[0] = _randomWords[0]/10;
        }

        if (reward > 0) {
            (bool success, ) = pool.call(abi.encodeWithSignature("send(address,uint256,bool)", gamesStart[_requestId].player, reward, true));
            require(success);
        } else {
            (bool _success, ) = pool.call(abi.encodeWithSignature("isHaveReferal(address)", msg.sender));
            // отчисление в 0.5% человеку, который привел реферала (работает только в случае поражения)
            if (_success){
                (bool success, ) = pool.call(abi.encodeWithSignature("send(address,uint256,bool)", gamesStart[_requestId].player, (reward*5/1000), false));
                require(success);
            }
        }
    }

    function endRoll(uint256 _requestId, uint256 num) private returns(uint256) {

        uint256 result = calculatePrize(gamesStart[_requestId].choice, num, (gamesStart[_requestId].deposit/(gamesStart[_requestId].numOfIterations)));
        if (result != 0) {
            totalWinsOfPlayer[gamesStart[_requestId].player] += result;
        }
        gamesResult[gamesStart[_requestId].player].push(
            GameRes(result, num)
        );
        
        emit GameResEvent(result, gamesStart[_requestId].player, num, gamesResult[gamesStart[_requestId].player].length);
        return(result);
    }

    function calculatePrize(
        bool choice,
        uint256 num,
        uint256 deposit
    ) private view returns (uint256) {
        if ((num>4) == choice) {
            return deposit * 2;
        } else {
            return 0;
        }
    }

    // =============================================================
    //                            Constructor
    // =============================================================
    
    constructor(uint64 subscriptionId, address vfrCoordinator_, uint32 callBackGaslimit_, bytes32 keyHash_, address pool_) VRFConsumerBaseV2(vfrCoordinator_){
        owner = msg.sender;
        keyHash = keyHash_;
        callbackGasLimit = callBackGaslimit_;
        COORDINATOR = VRFCoordinatorV2Interface(vfrCoordinator_);
        s_subscriptionId = subscriptionId;
        vrfCoordinator = vfrCoordinator_;
        pool = pool_;
    }
}