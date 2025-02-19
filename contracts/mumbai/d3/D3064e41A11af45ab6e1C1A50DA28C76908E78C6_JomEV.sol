pragma solidity ^0.8.4;

import {Counters} from "@openzeppelin/contracts/utils/Counters.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
struct Station {
    uint256 pricePerHour;
    string location;
    address owner;
    bytes3[8] availability;
    bool isActive;
}

contract JomEV is Ownable{

    using Counters for Counters.Counter; 
    using SafeMath for uint256;

    event UserJoined(address userAddr);
    event ProviderJoined(address providerAddr);
    event BookingSubmited( uint256 chargingPointIndex,uint256 connectorIndex, uint256 fee, uint256 day, bytes3 bookingSlot);
    event StationAdded(uint256 chargingPointId, uint256 connectorIndex, uint256 index, string cid, uint256 price);
    event ChargingPointAdded(uint256 index, string cid, uint256 price, uint256 amountStaked);
    event ConnectorDesactivated(uint256 charginPointIndex, uint256 connectorIndex);

    mapping(address => bool) public isMember;
    mapping(address => bool) public isProvider;
    mapping(uint256 => Station) public stationsMap;
    mapping(uint256 => uint256) public station_time_lower_bound;
    mapping(address => mapping (address => uint256)) public stakes;
    mapping (address => bool) public isAcceptedPayment;
    mapping(uint256 => mapping(uint256 => uint256)) public ChargingPointToStation;
    mapping(uint256 => uint256) public StationCounterInChargingPoint;

    uint256 private TIMESTAMP_PER_DAY = 86400;
    uint256 internal contract_time_lower_bound;
    Counters.Counter public stationIDs;
    Counters.Counter public bookingIDs;
    Counters.Counter public ChargingPointIDs;
    constructor () {
        contract_time_lower_bound = block.timestamp;
    }
    modifier onlyUser() {
        require(isMember[msg.sender], "This Feature is only for users");
        _;
    }
    modifier onlyProvider() {
        require(isProvider[msg.sender], "To become a provider you need to be a user of JomEV");
        _;
    }

    //dummy function for now, we will use worldcoin to upgrade this
    function joinAsUser() external {
        //worldcoin verification
        isMember[msg.sender] = true;
        emit UserJoined(msg.sender);
    } 
    function joinAsProvider() external onlyUser {
        isProvider[msg.sender] = true;
        emit ProviderJoined(msg.sender);
    }
    function addChargingPoint ( uint256 _pricePerHour, string calldata cid, address tokenAddr, uint256 nConnectors) external onlyProvider {
        require(isAcceptedPayment[tokenAddr],"this token is not allowed");
        uint256 amountToTransfer = _pricePerHour.mul(24).mul(7).mul(nConnectors);
        IERC20(tokenAddr).transferFrom(msg.sender, address(this),amountToTransfer);
        stakes[tokenAddr][msg.sender] += amountToTransfer;

        ChargingPointIDs.increment();
        uint256 currChargingPointCount = ChargingPointIDs.current();
        for(uint256 i=0; i<nConnectors ; i++){
            _addStation(_pricePerHour, cid, currChargingPointCount);
        }
        emit ChargingPointAdded(stationIDs.current(), cid, _pricePerHour, amountToTransfer);
    }
    /**
    ** @dev 
    ** @note  
        pricePerHour : price x hour of current station
        location : must be passed in coordinates or other relevant way
        tokenAddr : token which is used to perform the transaction , must be an approved token
    **/
    function _addStation(uint256 _pricePerHour, string calldata location, uint256 chargingPointId) internal  {
        stationIDs.increment();
        Station memory newStation = Station(_pricePerHour, location, msg.sender, [
            bytes3(0),bytes3(0),bytes3(0),bytes3(0),bytes3(0),bytes3(0),bytes3(0),bytes3(0)
        ],true);
        station_time_lower_bound[stationIDs.current()] = contract_time_lower_bound;
        stationsMap[stationIDs.current()] = newStation;
        StationCounterInChargingPoint[chargingPointId]++;
        ChargingPointToStation[chargingPointId][StationCounterInChargingPoint[chargingPointId]] = stationIDs.current();
        emit StationAdded(chargingPointId, StationCounterInChargingPoint[chargingPointId], stationIDs.current(), location, _pricePerHour);
    }
    /**
    ** @dev 
    ** @note  
        index : index of the station ( starts from 1
        day : index of day starting from today. if today is 15 and we want for 16 we must write 1, 0 is not allowed
        time : pass in bytes 24 slots ( hrs )
                i.e: 0010 0001 0000 0000 => we book for hours 3 and 8
                parse into hex : 0x2100 => this is the input
        tokenAddr : token which is used to perform the transaction , must be an approved token

    **/
    function bookStation(uint256 chargingPointId, uint256 connectorIndex, uint256 day, bytes3 time, address tokenAddr) external  onlyUser{

        bookingIDs.increment();
        uint256 index = ChargingPointToStation[chargingPointId][connectorIndex];
        require (index <= stationIDs.current() && index > 0,"index for booking not allowed");
        require (time != bytes3(0) , "new schedule cannot be empty");
        Station memory selectedStation = stationsMap[index];
        require(selectedStation.isActive,"Current Station is not active");

        //perform payment
        uint256 amountRequired = selectedStation.pricePerHour;
        require(isAcceptedPayment[tokenAddr],"this token is not accepted");
        IERC20(tokenAddr).transferFrom(msg.sender, address(this) , amountRequired);

        uint256 startPointer = day;
        uint256 diff = block.timestamp - station_time_lower_bound[index];
        if( diff > TIMESTAMP_PER_DAY){
            uint256 quotient = (diff).div(TIMESTAMP_PER_DAY);
            uint256 n = quotient;
            if(quotient>=7){
                n = 7;
                station_time_lower_bound[index]+=(TIMESTAMP_PER_DAY*(quotient.div(7)));
            }
            for ( uint8 i = 1 ; i <= n ; i++){
                startPointer+=1;
                selectedStation.availability[i] = bytes3(0);
            }
        }
        startPointer = startPointer % 7;
        bytes3 checkOverlap = time & selectedStation.availability[startPointer];
        require(checkOverlap == bytes3(0) , "new schedule overlaps");
        selectedStation.availability[startPointer] = time | selectedStation.availability[startPointer];
        stationsMap[index] = selectedStation;

        emit BookingSubmited(chargingPointId,connectorIndex,amountRequired, startPointer, time);
    }

    function desactivateConnector(uint256 chargingPointIndex, uint256 connectorIndex) external onlyProvider {
        require(stationsMap[ChargingPointToStation[chargingPointIndex][connectorIndex]].owner == msg.sender , "Caller is not the owner of the station");
        stationsMap[ChargingPointToStation[chargingPointIndex][connectorIndex]].isActive = false;
        
        emit ConnectorDesactivated(chargingPointIndex, connectorIndex);
    }
    function addAcceptedPayment(address tokenAddr) external onlyOwner {
        isAcceptedPayment[tokenAddr]= true;
    }
    //readers
    function getStation(uint256 index) external view returns(Station memory station){
        return (stationsMap[index]);
    }

    function getConnector(uint256 chargingPointID , uint256 connectorID) external view returns (Station memory station){
        return (stationsMap[ChargingPointToStation[chargingPointID][connectorID]]);
    }

    /** 
    **  @dev dummy call for usage in the testing
    **/
    function getBlockTimestamp() external view returns(uint256) {
        return(block.timestamp);
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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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