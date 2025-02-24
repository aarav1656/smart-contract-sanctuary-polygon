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

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./Errors.sol";

//Interface needed to interact with mint function of token
interface IToken {
    function mint(address to, uint256 amount) external;
}

contract BADS_TEST is Ownable {
    using SafeMath for uint256;

    event userCreated(uint256 id, address userAddress);
    event dataCollectionStarted(uint256 id, address userAddress);
    event dataCollectionStopped(uint256 id, address userAddress);
    event dataDeleted(uint256 id, address userAddress);
    event rewardClaimed(uint256 id, address userAddress, uint256 amount);


    string public website = "www.blockchain-ads.com";
    string public contactEmail = "[email protected]";

    bool public dataCollectionOpen;
    bool public signUpOpen;
    bool public rewardsClaimable;

    address Cookie;

    struct User{
        uint256 id;
        address userAddress;
    }

    User[] public users;

    mapping(address => bool) isUser;
    mapping(uint256 => uint256) collectionStarted;
    mapping(uint256 => uint256) collectionTotal;

    modifier dataCollectionInitiated(){
        require(dataCollectionOpen == true, "Data Collection is not initiated.");
        _;
    }

    modifier userSignUpInitiated(){
        require(signUpOpen == true, "Sign Up is still not available.");
        _;
    }

    modifier rewardsClaimingInitiated(){
        require(rewardsClaimable == true, "Rewards are not yet claimable.");
        _;
    }

    modifier userExists(uint256 userId){
        require(_userExists(userId) == true, "User is not existant");
        _;
    }

    modifier isAccOwner(uint256 userId){
        require(_isOwner(userId) == true);
        _;
    }
    
    //INTERNAL METHODS

    function _getNumUsers() internal view returns(uint256){
        return users.length;
    }

    function _createUser() internal {
        if (isUser[msg.sender] == true){
            revert addressAlreadyUser();
        }
        users.push(User(_getNumUsers(), msg.sender));
        isUser[msg.sender] = true;
        emit userCreated(SafeMath.sub(_getNumUsers(), 1), msg.sender);
    }

    function _userExists(uint256 userId) internal view returns(bool){
        if (userId > _getNumUsers()){
            return false;
        }
        return true;
    }

    function _isOwner(uint256 userId) internal view returns(bool){
        if (users[userId].userAddress == msg.sender){
            return true;
        }

        return false;

    }

    function _getCurrentBlock() internal view returns(uint256){
        return block.timestamp;
    }

    function _getEarnings(uint256 userId) public view returns(uint256){
        uint256 dataCollPeriod;
        uint256 earned;
        (,,dataCollPeriod) = _collectionPeriod(userId);
        earned += dataCollPeriod;
        return earned;
    }


    function signUp() external userSignUpInitiated {
        _createUser();
    }

    function setTokenAddress(address tokenAddress) external onlyOwner{
        Cookie = tokenAddress;
    }

    function toggleRewards() external onlyOwner{
        rewardsClaimable = !rewardsClaimable;
    }

    function toggleDataCollection() external onlyOwner{
        dataCollectionOpen = !dataCollectionOpen;
    }

    function toggleSignUp() external onlyOwner{
        signUpOpen = !signUpOpen;
    }

    function claimRewards(uint256 userId) external rewardsClaimingInitiated isAccOwner(userId){
        uint256 earned = _getEarnings(userId);
        if (earned > 0){
            IToken(Cookie).mint(msg.sender, earned);
            emit rewardClaimed(userId, msg.sender, earned);
            collectionStarted[userId] = 0;
            collectionTotal[userId] = 0;
        }
    }

    function _collectionPeriod(uint256 userId) 
        public 
        view
        returns (  
            bool collectingData, 
            uint256 current, 
            uint256 total
            )
    {
        uint256 start = collectionStarted[userId];
        if (start != 0){
            collectingData = true;
            current = _getCurrentBlock() - start;

        }
        total = SafeMath.add(current,collectionTotal[userId]);
    }


    function initDataCollection(uint256 userId) external dataCollectionInitiated userExists(userId) isAccOwner(userId) {
        uint256 start = collectionStarted[userId];
        if (start == 0){
            collectionStarted[userId] = _getCurrentBlock();
            emit dataCollectionStarted(userId, msg.sender);
        } else {
            collectionTotal[userId] += SafeMath.sub(_getCurrentBlock(),start);
            collectionStarted[userId] = 0;
            emit dataCollectionStopped(userId, msg.sender);
        }
    }


    function deleteData(uint256 userId) external userExists(userId) isAccOwner(userId) {
        collectionStarted[userId] = 0;
        collectionTotal[userId] = 0;
        emit dataDeleted(userId, msg.sender);
    }
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

error userNotRegistered();
error notAuthorized();
error notCollectingData();
error userCreationNotStarted();
error addressAlreadyUser();
error notAccountOwner();