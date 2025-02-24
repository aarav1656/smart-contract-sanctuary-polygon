// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;
pragma experimental ABIEncoderV2;
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract EightsGame is Ownable {
    uint256 public feePercentage = 10;

    enum GameType { 
        Connect4,
        TicTacToe
    }
    enum GameStatus {
        Created,
        InProgress,
        Complete
    }
    enum GameResult {
        Undefined,
        CreatorWon,
        CreatorLost,
        Draw
    }
    struct Room {
        string roomId;
        string roomName;
        address roomOwner;
        address opponent;
        uint256 wagerAmount;
        GameType gameType;
        GameStatus gameStatus;
    }
    string[] public rooms;
    mapping(string => Room) public roomMap;
    mapping(address => string) public userToRoomId;

    // constructor to initialize the contract
    constructor() {
        // initialize the contract
    }

    event RoomCreated(string gameId, address creator, uint256 wagerAmount);
    event RoomJoined(string gameId, address joiner, uint256 wagerAmount);
    event GameCompleted(string gameId, address winner, uint256 wagerAmount);
    event RoomCountUpdate(uint256 count);

    function createRoom(
        string memory _roomId,
        string memory _roomName,
        uint256 _wagerAmount,
        GameType _gameType
    ) public payable {

        
        Room memory room = Room({
            roomId: _roomId,
            roomName: _roomName,
            roomOwner: msg.sender,
            opponent: address(0),
            wagerAmount: msg.value,
            gameType: _gameType,
            gameStatus: GameStatus.Created
        });
        rooms.push(_roomId);
        // push the players to the players array in storage

        roomMap[_roomId] = room;
        userToRoomId[msg.sender] = _roomId;

        // add room owner to list of players in the room    
        // rooms[rooms.length - 1].players.push(_roomOwner);
        // roomMap[_roomId].players.push(msg.sender);
        emit RoomCreated(_roomId, msg.sender, _wagerAmount);
        emit RoomCountUpdate(rooms.length);
    }
    // make a deposit to the contract
    function depositWager(uint256 _wagerAmount) public payable {
        // add the deposit to the contract
        payable(address(this)).transfer(_wagerAmount);

    }


    function joinRoom(string memory _roomId) public payable {
        Room storage room = roomMap[_roomId];
        require(room.gameStatus == GameStatus.Created, "Game is already in progress");
        require(room.opponent == address(0), "Game is already in progress");
        require(room.wagerAmount == msg.value, "Wager amount does not match");
        room.opponent = msg.sender;
        room.gameStatus = GameStatus.InProgress;
        userToRoomId[msg.sender] = _roomId;
        emit RoomJoined(_roomId, msg.sender, room.wagerAmount);
    }

    
    function completeGame(string memory _roomId, address _winner) public {
        Room storage room = roomMap[_roomId];
        room.gameStatus = GameStatus.Complete;
        uint wagerAmount = room.wagerAmount;
        if(wagerAmount > 0) {

            wagerAmount = SafeMath.mul(wagerAmount, 2);
            uint256 fee = SafeMath.div(SafeMath.mul(wagerAmount, feePercentage), 100);
            wagerAmount = SafeMath.sub(wagerAmount, fee);
            payable(_winner).transfer(wagerAmount);

        }

        // remove the room from the rooms array
        for (uint i = 0; i < rooms.length; i++) {
            if (keccak256(abi.encodePacked(rooms[i])) == keccak256(abi.encodePacked(_roomId))) {
                rooms[i] = rooms[rooms.length - 1];
                rooms.pop();
                break;
            }
        }

        emit GameCompleted(_roomId, _winner, room.wagerAmount);
        emit RoomCountUpdate(rooms.length);
    }

    function getRoom(string memory _roomId) public view returns (Room memory) {
        return roomMap[_roomId];
    }

    function getRoomId(address _user) public view returns (string memory) {
        return userToRoomId[_user];
    }

    function getRooms() public view returns (string[] memory) {
        return rooms;
    }

    function getRoomCount() public view returns (uint256) {
        return rooms.length;
    }


    // only the owner of the contract can change the fee
    function setFeePercentage(uint256 _feePercentage) public onlyOwner {
        require(_feePercentage > 0, "Fee must be greater than 0");
        require(_feePercentage < 100, "Fee must be less than 100");
        require(_feePercentage != feePercentage, "Fee must be different than the current fee");
        feePercentage = _feePercentage;
    }

    function getFeePercentage() public view returns (uint256) {
        return feePercentage;
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
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
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