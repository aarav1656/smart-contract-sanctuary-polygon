/**
 *Submitted for verification at polygonscan.com on 2023-01-02
*/

// File: @openzeppelin/contracts/utils/Context.sol

// SPDX-License-Identifier: MIT

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

// File: @openzeppelin/contracts/access/Ownable.sol


pragma solidity ^0.8.0;

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: contracts/UpVsDownGameV1.sol


pragma solidity >=0.4.22 <0.9.0;

contract UpVsDownGameV1 is Ownable {

  struct BetGroup {
    uint256[] bets;
    address[] addresses;
    uint256 total;
    uint256 distributedCount;
  }

  struct Round {
    bool created;
    int32 startPrice;
    int32 endPrice;
    uint256 minBetAmount;
    uint256 maxBetAmount;
    uint256 poolBetsLimit;
    BetGroup upBetGroup;
    BetGroup downBetGroup;
  }

  address public gameController;
  mapping(bytes => Round) public pools;
  uint8 public feePercentage = 5;
  address public feeAddress = msg.sender;
  bool public isRunning;
  bytes public notRunningReason;
  //string avatarUrl = "https://i.seadn.io/gae/7l3PwKASoZABNFrgDLXOGPeQsTFnr6KIVuleu-Cywq3JigZpcH7soLaXk3AEL-NFJWFUXUf03iResPjHQc7BiAAUips6BK-4-1ekVGE?auto=format&w=100";

  // Errors

  error PendingDistributions();

  // Events

  event RoundStarted(bytes poolId, int64 timestamp, int32 price, uint256 minBetAmount, uint256 maxBetAmount, uint256 poolBetsLimit, bytes indexed indexedPoolId);
  event RoundEnded(bytes poolId, int64 timestamp, int32 startPrice, int32 endPrice, bytes indexed indexedPoolId);
  event BetPlaced(bytes poolId, address sender, uint256 amount, bool prediction, uint256 newTotal, bytes indexed indexedPoolId, string avatarUrl, address indexed indexedSender);
  event BetReturned(bytes poolId, address sender, uint256 amount);
  event GameStopped(bytes reason);
  event GameStarted();
  event RoundDistributed(bytes poolId, uint totalWinners, uint from, uint to);
  event BetWinningsSent(bytes poolId, address sender, uint256 betAmount, uint256 winningsAmount, address indexed indexedSender);

  // Modifiers

  modifier onlyGameController () {
    require(msg.sender == gameController, 'Only game controller can do this');
    _;
  }

  modifier onlyOpenPool (bytes calldata poolId) {
    require(isPoolOpen(poolId), 'This pool has a round in progress');
    _;
  }

  modifier onlyGameRunning () {
    require(isRunning, 'The game is not running');
    _;
  }

  modifier onlyPoolExists (bytes calldata poolId) {
    require(pools[poolId].created == true, 'Pool does not exist');
    _;
  }

  constructor(address newGameController) {
    gameController = newGameController;
  }

  // Methods

  function changeGameControllerAddress(address newGameController) public onlyOwner {
    gameController = newGameController;
  }

  function changeGameFeePercentage(uint8 newFeePercentage) public onlyOwner {
    feePercentage = newFeePercentage;
  }

  function changeGameFeeAddress(address newFeeAddress) public onlyOwner {
    feeAddress = newFeeAddress;
  }

  function stopGame(bytes calldata reason) public onlyOwner {
    isRunning = false;
    notRunningReason = reason;
    emit GameStopped(reason);
  }

  function startGame() public onlyOwner {
    isRunning = true;
    notRunningReason = '';
    emit GameStarted();
  }

  function createPool(bytes calldata poolId, uint256 minBetAmount , uint256 maxBetAmount, uint256 poolBetsLimit) public onlyGameController {
    pools[poolId].created = true;
    pools[poolId].minBetAmount = minBetAmount;
    pools[poolId].maxBetAmount = maxBetAmount;
    pools[poolId].poolBetsLimit = poolBetsLimit;
  }

  function trigger(
    bytes calldata poolId,
    int64 timeMS,
    int32 price,
    uint32 batchSize
  ) public onlyGameController onlyPoolExists(poolId) {
    Round storage currentRound = pools[poolId];

    if(isPoolOpen(poolId)) {
      require(isRunning, 'The game is not running, rounds can only be ended at this point');
      currentRound.startPrice = price;
    
      emit RoundStarted(poolId, timeMS, currentRound.startPrice, currentRound.minBetAmount, currentRound.maxBetAmount, currentRound.poolBetsLimit, poolId);
    } else if (currentRound.endPrice == 0) {
      currentRound.endPrice = price;

      emit RoundEnded(poolId, timeMS, currentRound.startPrice, currentRound.endPrice, poolId);

      distribute(poolId, batchSize);
    } else {
      revert PendingDistributions();
    }
  }

  function returnBets (
    bytes calldata poolId,
    BetGroup storage group,
    uint32 batchSize
  ) private {
    uint256 pending = group.bets.length - group.distributedCount;
    uint256 limit = pending > batchSize ? batchSize : pending;
    uint256 to = group.distributedCount + limit;

    for (uint i = group.distributedCount; i < to; i ++) {
      sendEther(group.addresses[i], group.bets[i]);
      emit BetReturned(poolId, group.addresses[i], group.bets[i]);
    }

    group.distributedCount = to;
  }

  function distribute (
    bytes calldata poolId,
    uint32 batchSize
  ) public onlyGameController onlyPoolExists(poolId) {
    Round storage round = pools[poolId];

    BetGroup storage winners = round.downBetGroup;
    BetGroup storage losers = round.upBetGroup;

    if (round.startPrice < round.endPrice) {
      winners = round.upBetGroup;
      losers = round.downBetGroup;
    }

    if (winners.bets.length == 0) {
      //uint fromReturn = losers.distributedCount;
      returnBets(poolId, losers, batchSize);
      emit RoundDistributed(poolId, losers.bets.length, losers.distributedCount, losers.distributedCount);

      if (losers.distributedCount == losers.bets.length) {
        clearPool(poolId);
      }
      return;
    }

    //uint256 fee = feePercentage * losers.total / 100;
    uint256 totalMinusFee = losers.total - (feePercentage * losers.total / 100);
    uint256 pending = winners.bets.length - winners.distributedCount;
    uint256 limit = pending > batchSize ? batchSize : pending;
    uint256 to = winners.distributedCount + limit;

    if (winners.distributedCount == 0) {
      sendEther(feeAddress, (feePercentage * losers.total / 100));
    }

    for (uint i = winners.distributedCount; i < to; i++) {
      uint256 winnings = ((winners.bets[i] * 100 / winners.total) * totalMinusFee / 100);
      sendEther(winners.addresses[i], winnings + winners.bets[i]);
      emit BetWinningsSent(poolId, winners.addresses[i], winners.bets[i], winnings, winners.addresses[i]);
    }

    emit RoundDistributed(poolId, winners.bets.length, winners.distributedCount, to);

    winners.distributedCount = to;
    if (winners.distributedCount == winners.bets.length) {
      clearPool(poolId);
    }
  }

  function clearPool (
    bytes calldata poolId
  ) private {
    delete pools[poolId].upBetGroup;
    delete pools[poolId].downBetGroup;
    delete pools[poolId].startPrice;
    delete pools[poolId].endPrice;
  }

  function hasPendingDistributions(
    bytes calldata poolId
  ) public view returns (bool) {
    return (pools[poolId].upBetGroup.bets.length + pools[poolId].downBetGroup.bets.length) > 0;
  }

  function isPoolOpen(
    bytes calldata poolId
  ) public view returns (bool) {
    return pools[poolId].startPrice == 0;
  }

  function addBet (
    BetGroup storage betGroup,
    uint256 amount
  ) private returns (uint256) {
    betGroup.bets.push(amount);
    betGroup.addresses.push(msg.sender);
    betGroup.total += amount;
    return betGroup.total;
  }

  function makeBet(
    bytes calldata poolId,
    bool upOrDown,
    string calldata avatarUrl
  ) public payable onlyOpenPool(poolId) onlyGameRunning onlyPoolExists(poolId) {
    require(msg.value > 0, "Needs to send ether to bet");
    require(msg.value >= pools[poolId].minBetAmount, "Bet amount should be higher than the minimum");
    require(msg.value <= pools[poolId].maxBetAmount, "Bet amount should be lower than the maximum");
    uint256 newTotal;
    //Round storage currentPool = pools[poolId];

    if (upOrDown) {
      require(pools[poolId].upBetGroup.bets.length <= pools[poolId].poolBetsLimit-1,"Pool is full, wait for next round");
      newTotal = addBet(pools[poolId].upBetGroup, msg.value);
    } else {
      require(pools[poolId].downBetGroup.bets.length <= pools[poolId].poolBetsLimit-1,"Pool is full, wait for next round");
      newTotal = addBet(pools[poolId].downBetGroup, msg.value);
    }

    emit BetPlaced(poolId, msg.sender, msg.value, upOrDown, newTotal, poolId, avatarUrl, msg.sender);
  }

  function sendEther (
    address to, 
    uint256 amount
  ) private {
    (bool sent, bytes memory data) = payable(to).call{gas: 0, value: amount}("");
    require(sent, "Couldn't send ether");
  } 

  function etherToWei(
    uint valueEther
  ) public returns (uint) {
       return valueEther*(10**18);
  }
}