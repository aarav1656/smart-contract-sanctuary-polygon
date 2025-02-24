// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Roulette is Ownable {
  uint256 public currentMultiBetId;
  uint256 public BetId;
  uint32 private deadlineOfGame = 6000000;
  uint256 private maxBet = 500 * 10 ** 18;
  uint8[] payouts = [2,3,3,2,2,36];
  uint8[] numberRange = [1,2,2,1,1,36];

    enum BetTypes {
        colour,
        column,
        dozen,
        eighteen,
        modulus,
        number
    }


  struct SinglePlayerBet {
    address bettorAddress;
    BetTypes[] betType;
    uint8[] number;
    uint256[] betAmount;
    uint256 winningAmount; 
    uint256 randomNumber;  
  }

    struct UserBet {
        address bettorAddress;
        BetTypes[] betType;
        uint8[] number;
        uint256[] betAmount;
        uint256 winningAmount;
        address tokenAddress;
        bool isMatic;
  }

  struct MultiPlayerBet {
        uint256 time;
        uint256 randomNumber;
        uint256 requestId;
        bool wheelSpun;
        bool fulfilled;
        bool betCompleted;
  }

    event BetPlacedInMatic(
    uint256 _betId,
    address _playerAddress,
    uint256[] _betAmount,
    BetTypes[] _betType,
    uint8[] _number
  );

    event BetPlacedInToken(
    uint256 _betId,
    address _playerAddress,
    address _tokenAddress,
    uint256[] _betAmount,
    BetTypes[] _betType,
    uint8[] _number
  );

  event RouletteStarted(uint256 betId, uint time);
  event wheelSpun(uint256 betId, uint256 requestId, uint256 randomValue);
  event WinAmount(uint256 _betId, uint256 _winningAmount);
  event Received(address _sender, uint256 indexed _message);

  mapping(address => bool) public whitelistedTokens;
  mapping(uint256 => SinglePlayerBet) public uniBetId;
  mapping(uint256 => uint256) public requestIdToBetId;
  mapping(address => uint256[]) public userBets;
  mapping(uint256 => address[]) public participants;
  mapping (address => uint256) public winningsInMatic;
  mapping(address => mapping(address => uint256)) public winningsInToken;
  mapping(uint256 => mapping(address => bool)) public participated;

  modifier maxBetAllowed() {
    require(msg.value <= maxBet, "Maximum allowed bet is 500");
    _;
  }


    /*
  Roulette game to be started by the owner. 
  Users are allowed to bet after the game is started until the deadline.
  */
  function startGame() external onlyOwner {
       ++currentMultiBetId;
       ++BetId; 
       emit RouletteStarted(currentMultiBetId, block.timestamp);
    }

    function singlePlayerBet(BetTypes[] memory _betType, uint8[] memory number, bool _isMatic, address ERC20Address, uint256[] memory amount) public maxBetAllowed payable {
    require(_betType.length == number.length && number.length == amount.length); 
      ++BetId; 
      uint betValue ;  
      for(uint i = 0; i < _betType.length; i++) {
        uint8 temp = uint8(_betType[i]);
        require(number[i] >= 0 && number[i] <= numberRange[temp], "Number should be within range");
        require(amount[i] > 0, 'Bet Value should be greater than 0');
        betValue += amount[i];
      }
        SinglePlayerBet storage u = uniBetId[BetId];
        u.bettorAddress = msg.sender;
        u.betType = _betType;
        u.number = number;
        u.betAmount = amount;

      if(_isMatic == false){ 
        require(whitelistedTokens[ERC20Address] == true, 'Token not allowed for placing bet');
        IERC20(ERC20Address).transferFrom(msg.sender, address(this), betValue);

        emit BetPlacedInToken(BetId, msg.sender, ERC20Address, amount, _betType, number );
        }
    else {       
        require(msg.value == betValue, 'Bet value should be same as the sum of bet amounts');      
        emit BetPlacedInMatic(BetId, msg.sender, amount, _betType, number );
        }
        userBets[msg.sender].push(BetId); 
        spinWheel( BetId, _isMatic, ERC20Address);     
    }

    function spinWheel(uint256 _betId, bool isMatic, address ERC20Address) internal  {
    SinglePlayerBet storage u = uniBetId[_betId];
    uint256 inc = ++_betId;
    uint256 num = uint(keccak256(abi.encodePacked(block.timestamp,block.difficulty,msg.sender, inc))) % 36; 
    u.randomNumber = num; 
    for(uint i = 0; i < u.betType.length; i++){
    bool won = false;
       if (num == 0) {
        won = (u.betType[i] == BetTypes.number && u.number[i] == 0);                   /* bet on 0 */
      } else {
        if (u.betType[i] == BetTypes.number) { 
          won = (u.number[i] == num);                              /* bet on number */
        } else if (u.betType[i] == BetTypes.modulus) {
          if (u.number[i] == 0) won = (num % 2 == 0);              /* bet on even */
          if (u.number[i] == 1) won = (num % 2 == 1);              /* bet on odd */
        } else if (u.betType[i] == BetTypes.eighteen) {            
          if (u.number[i] == 0) won = (num <= 18);                 /* bet on low 18s */
          if (u.number[i] == 1) won = (num >= 19);                 /* bet on high 18s */
        } else if (u.betType[i] == BetTypes.dozen) {                               
          if (u.number[i] == 0) won = (num <= 12);                 /* bet on 1st dozen */
          if (u.number[i] == 1) won = (num > 12 && num <= 24);     /* bet on 2nd dozen */
          if (u.number[i] == 2) won = (num > 24);                  /* bet on 3rd dozen */
        } else if (u.betType[i] == BetTypes.column) {               
          if (u.number[i] == 0) won = (num % 3 == 1);              /* bet on left column */
          if (u.number[i] == 1) won = (num % 3 == 2);              /* bet on middle column */
          if (u.number[i] == 2) won = (num % 3 == 0);              /* bet on right column */
        } else if (u.betType[i] == BetTypes.colour) {
          if (u.number[i] == 0) {                                     /* bet on black */
            if (num <= 10 || (num >= 20 && num <= 28)) {
              won = (num % 2 == 0);
            } else {
              won = (num % 2 == 1);
            }
          } else {                                                 /* bet on red */
            if (num <= 10 || (num >= 20 && num <= 28)) {
              won = (num % 2 == 1);
            } else {
              won = (num % 2 == 0);
            }
          }
        }
      }
      uint256 typeOfBet = uint256(u.betType[i]);
      /* if winning bet, add to player winnings balance */
      if (won && isMatic) {
        winningsInMatic[u.bettorAddress] += u.betAmount[i] * payouts[typeOfBet];
        u.winningAmount += u.betAmount[i] * payouts[typeOfBet];
      }
      else if (won == true && isMatic == false) {
        winningsInToken[u.bettorAddress][ERC20Address] += u.betAmount[i] * payouts[typeOfBet];
        u.winningAmount += u.betAmount[i] * payouts[typeOfBet];
      }
    } 
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