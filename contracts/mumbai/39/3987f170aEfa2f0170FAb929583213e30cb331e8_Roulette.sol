// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol';
import '@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Roulette is VRFConsumerBaseV2, Ownable {

  VRFCoordinatorV2Interface COORDINATOR;

  uint32 private constant CALL_BACK_GAS_LIMIT = 1000000000;
  bytes32 private keyHash;
  uint16 private requestConfirmations = 3;
  uint32 private numWords = 1;
  uint64 private vrfSubscriptionId;
  uint256 public requestId;
  uint256 public currentBetId;
  uint256[] payouts;
  uint256[] numberRange;

    /*
    BetTypes are as follow:
      0: color
      1: column
      2: dozen
      3: eighteen
      4: modulus
      5: number
      
    Depending on the BetType, number will be:
      color: 0 for black, 1 for red
      column: 0 for left, 1 for middle, 2 for right
      dozen: 0 for first, 1 for second, 2 for third
      eighteen: 0 for low, 1 for high
      modulus: 0 for even, 1 for odd
      number: number
  */

   struct UserBet {
    address bettorAddress;
    uint256 betType;
    uint256 number;
    uint256 betAmount;
    uint256 winningAmount;
    bool isMatic;
    address tokenAddress;
  }

  struct Bet {
    uint256 time;
    uint256 randomNumber;
    bool wheelSpun;
  }

  event BetPlacedInMatic(
    uint256 _betId,
    address _playerAddress,
    uint256 _betAmount,
    uint256 _betType,
    uint256 _number,
    bool _isMatic
  );

  event BetPlacedInToken(
    uint256 _betId,
    address _playerAddress,
    address _tokenAddress,
    uint256 _betAmount,
    uint256 _betType,
    uint256 _number,
    bool _isMatic
  );

  event RouletteStarted(uint256 betId, uint time);
  event wheelSpun(uint256 betId, uint256 requestId, uint256 randomValue);
  event WinAmount(uint256 _betId, uint256 _winningAmount);
  event Received(address _sender, uint256 indexed _message);

  address private WETH = 0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619;
  address private WBTC = 0x1BFD67037B42Cf73acF2047067bd4F2C47D9BfD6;

  mapping(address => bool) public whitelistedTokens;
  mapping(uint256 => Bet) public betIdToBets;
  mapping(uint256 => uint256) public requestIdToBetId;
  mapping(uint256 => UserBet[]) public players;
  mapping (address => uint256) public winningsInMatic;
  mapping(address => mapping(address => uint256)) public winningsInToken;


    /**
   * @notice Constructor inherits VRFConsumerBaseV2
   * @param _vrfCoordinator {address} - coordinator, check https://docs.chain.link/docs/vrf-contracts/#configurations
   * @param _keyHash {bytes32} - the gas lane to use, which specifies the maximum gas price to bump to
   */
  constructor(
    address _vrfCoordinator,
    bytes32 _keyHash,
    uint64 _vrfSubscriptionId
  ) VRFConsumerBaseV2(_vrfCoordinator) {
    COORDINATOR = VRFCoordinatorV2Interface(_vrfCoordinator);
    vrfSubscriptionId = _vrfSubscriptionId;
    keyHash = _keyHash;
    whitelistedTokens[WETH] = true;
    whitelistedTokens[WBTC] = true;
    payouts = [2,3,3,2,2,36];
    numberRange = [1,2,2,1,1,36];
  }

  /*
  Roulette game to be started by the owner. 
  Users are allowed to bet after the game is started until the deadline.
  */
  function startGame() external onlyOwner {
       currentBetId = _inc(currentBetId);
       Bet storage b = betIdToBets[currentBetId];
       b.time = block.timestamp;

       emit RouletteStarted(currentBetId, block.timestamp);
    }

    /** 
   * @dev For placing the bet.
   * @param betType to choose the bet type. 
   * @param number based on the bet type, a number should be chosen.
   * Check the comments above for the available betTypes.
   * @param _isMatic to check whether is selected network is Matic or ERC20 token.
   * @param ERC20Address to know which token is chosen if the the network connected is not matic.
   * Only whitelisted tokens are allowed for payments.
   * @param amount amount of token user wants to bet. Should approve the contract to use it first.
   */
  function bet(uint256 betType, uint256 number, bool _isMatic, address ERC20Address, uint256 amount) external payable {
    require(block.timestamp < betIdToBets[currentBetId].time + 6000000, 'deadline for this bet is passed');
    require(betType >= 0 && betType <= 5, "Bet type should be within range");                         
    require(number >= 0 && number <= numberRange[betType], "Number should be within range"); 
    Bet memory b = betIdToBets[currentBetId];
    require(b.wheelSpun == false, "Spinning of wheel is completed"); 

    if(_isMatic == false){
      require(whitelistedTokens[ERC20Address] == true, 'Token not allowed for placing bet');
      require(amount > 0, 'Bet Value should be greater than 0');

      IERC20(ERC20Address).transferFrom(msg.sender, address(this), amount);

      players[currentBetId].push(UserBet({
        bettorAddress: msg.sender,
        betType: betType,
        number: number,
        betAmount: amount,
        winningAmount: 0,
        isMatic: false,
        tokenAddress: ERC20Address
      }));

    emit BetPlacedInToken(currentBetId, msg.sender, ERC20Address, amount, betType, number, false );  

    }
    else {
        require(msg.value > 0, 'Bet Value should be greater than 0');
        
      players[currentBetId].push(UserBet({
        bettorAddress: msg.sender,
        betType: betType,
        number: number,
        betAmount: msg.value,
        winningAmount: 0,
        isMatic: true,
        tokenAddress: address(0)
      }));

      emit BetPlacedInMatic(currentBetId, msg.sender, msg.value, betType, number, true ); 

      }
    }

  /*
  After the deadline is passed, owner will spin the wheel.
  Reverts if no player has joined the bet or if the spin wheel is already happened.
  Calls requestRandomWords function.
  */
  function spinWheel() external onlyOwner {
      require(players[currentBetId].length > 0, 'No player has joined');
      Bet storage b = betIdToBets[currentBetId];
      require(b.wheelSpun == false, "Spinning of wheel is already completed.");

      requestId = COORDINATOR.requestRandomWords(
      keyHash,
      vrfSubscriptionId,
      requestConfirmations,
      CALL_BACK_GAS_LIMIT,
      numWords
      );
    b.wheelSpun = true;
    requestIdToBetId[requestId] = currentBetId;
    }

  //Internal function called by VRFCoordinator when it receives a random number from valid VRFproof.
  function fulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords)
    internal
    override
  {
    uint256 _betId = requestIdToBetId[_requestId];
    uint256 randomValueBtwRange = (_randomWords[0] % 36);
    betIdToBets[_betId].randomNumber = randomValueBtwRange;

    checkWinner(randomValueBtwRange, _requestId);

    emit wheelSpun(_betId, _requestId, randomValueBtwRange);

  }

  /*
  Checks if the player has won the bet.
  Calculate the payouts for the winners of all bet types.
  Adds the winning amount to the user winnings.
  */
  function checkWinner(uint number, uint _requestId) internal {
    uint256 betId = requestIdToBetId[_requestId];
      for (uint i = 0; i < players[betId].length; i++) {
        bool won = false;
        UserBet storage b = players[betId][i];
      if (number == 0) {
        won = (b.betType == 5 && b.number == 0);                   /* bet on 0 */
      } else {
        if (b.betType == 5) { 
          won = (b.number == number);                              /* bet on number */
        } else if (b.betType == 4) {
          if (b.number == 0) won = (number % 2 == 0);              /* bet on even */
          if (b.number == 1) won = (number % 2 == 1);              /* bet on odd */
        } else if (b.betType == 3) {            
          if (b.number == 0) won = (number <= 18);                 /* bet on low 18s */
          if (b.number == 1) won = (number >= 19);                 /* bet on high 18s */
        } else if (b.betType == 2) {                               
          if (b.number == 0) won = (number <= 12);                 /* bet on 1st dozen */
          if (b.number == 1) won = (number > 12 && number <= 24);  /* bet on 2nd dozen */
          if (b.number == 2) won = (number > 24);                  /* bet on 3rd dozen */
        } else if (b.betType == 1) {               
          if (b.number == 0) won = (number % 3 == 1);              /* bet on left column */
          if (b.number == 1) won = (number % 3 == 2);              /* bet on middle column */
          if (b.number == 2) won = (number % 3 == 0);              /* bet on right column */
        } else if (b.betType == 0) {
          if (b.number == 0) {                                     /* bet on black */
            if (number <= 10 || (number >= 20 && number <= 28)) {
              won = (number % 2 == 0);
            } else {
              won = (number % 2 == 1);
            }
          } else {                                                 /* bet on red */
            if (number <= 10 || (number >= 20 && number <= 28)) {
              won = (number % 2 == 1);
            } else {
              won = (number % 2 == 0);
            }
          }
        }
      }
      /* if winning bet, add to player winnings balance */
      if (won && b.isMatic) {
        winningsInMatic[b.bettorAddress] += b.betAmount * payouts[b.betType];
        b.winningAmount = b.betAmount * payouts[b.betType];
      }
      else if (won == true && b.isMatic == false) {
        winningsInToken[b.bettorAddress][b.tokenAddress] += b.betAmount * payouts[b.betType];
        b.winningAmount = b.betAmount * payouts[b.betType];
      }
      emit WinAmount(betId, b.winningAmount);
    }
  }

    /*
  This function is used while adding allowed assets for placing bet on roll dice.
  Reverts if the token is already whitelisted.
  Can only be called by the owner.
  */ 
  function addWhitelistTokens(address ERC20Address) external onlyOwner {
    require(whitelistedTokens[ERC20Address] == false, 'Token already whitelisted');
    whitelistedTokens[ERC20Address] = true;
  }

   /*
  This function is used while removing allowed assets for placing bet on roll dice.
  Reverts if the token is not whitelisted.
  Can only be called by the owner.
  */ 
  function removeWhitelistTokens(address ERC20Address) external onlyOwner {
    require(whitelistedTokens[ERC20Address] == true, 'Token is not whitelisted');
    whitelistedTokens[ERC20Address] = false;
  }

  //Allows users to withdraw their Matic winnings.
  function userWithdrawMatic(uint256 amount) external {
    require(winningsInMatic[msg.sender] >= amount, "You do not have requested winning amount to withdraw");
    require(ReserveInMatic() >= amount,'Sorry, Contract does not have enough reserve');
    winningsInMatic[msg.sender] -= amount;
    payable(msg.sender).transfer(amount);
  }

  //Allows users to withdraw their ERC20 token winnings
  function userWithdrawToken(address ERC20Address, uint256 amount) external {
    require(winningsInToken[msg.sender][ERC20Address] >= amount, "You do not have requested winning amount to withdraw");
    require(ReserveInToken(ERC20Address) >= amount,'Sorry, Contract does not have enough reserve');
    winningsInToken[msg.sender][ERC20Address] -= amount;
    IERC20(ERC20Address).transfer(msg.sender, amount);
  }

  //Checks Matic balance of the contract
  function ReserveInMatic() public view returns (uint256) {
    return address(this).balance;
  }

  //Checks ERC20 Token balance.
  function ReserveInToken(address ERC20Address) public view returns(uint) {
    return IERC20(ERC20Address).balanceOf(address(this));
  }

  //Owner is allowed to withdraw the contract's matic balance.
  function MaticWithdraw(address _receiver, uint256 _amount) external onlyOwner {
    require(ReserveInMatic() >= _amount,'Sorry, Contract does not have enough balance');
    payable(_receiver).transfer(_amount);
  }

  //Owner is allowed to withdraw the contract's token balance.
  function TokenWithdraw(address ERC20Address, address _receiver, uint256 _amount) external onlyOwner {
    require(ReserveInToken(ERC20Address) >= _amount, 'Sorry, Contract does not have enough token balance');
    IERC20(ERC20Address).transfer(_receiver, _amount);
  }

  function _inc(uint256 index) private pure returns (uint256) {
    unchecked {
      return index + 1;
    }
  }

  receive() external payable {
    emit Received(msg.sender, msg.value);
  }

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