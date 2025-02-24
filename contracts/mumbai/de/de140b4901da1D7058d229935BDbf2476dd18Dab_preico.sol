//SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "./Extras/Interface/IERC20.sol";
import "./Extras/access/Ownable.sol";
import "./Extras/Library/Safemath.sol";
import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";

contract preico is Ownable{
    using SafeMath for uint256;
    //start time, end time, open to all, fixed supply, available on fixed rate, soft cap, hard cap
    //no minimum buying cap,


    ///@dev For 1 wei you will be getting 2*1e12/decimalOfToken = 2*1e12/1e18 = c tokens
    //uint private rate1=4*1e12;

    ///@dev For 1 wei you will be getting 2*1e12/decimalOfToken = 2*1e12/1e18 = 0.000002 tokens
    //uint private rate2=2*1e12;

    ///@dev For 1 wei you will be getting 2*1e12/decimalOfToken = 2*1e12/1e18 = 0.000001 tokens
    // //uint private rate3=1*1e12;

    // /@dev Total 20 Million tokens are to be sold at ICO in 3 stages which  are divided into 
    // /        4 mil, 6 mil, 10 mil supply respectively


    IERC20 private token;
    //AggregatorV3Interface internal priceFeedAvax;
    //AggregatorV3Interface internal priceFeedEth;
    AggregatorV3Interface internal priceFeed;


    // uint public tokenPrice=7642621707402130 ;//USD
    // uint public currentPriceEth=130845152133;

    address payable private immutable wallet;

    struct ICOdata{
        uint rate;
        uint supply;
        uint start;
        uint end;
        uint sold;
    }

    ICOdata private ICOdatas;


    constructor (IERC20 _token, address payable _wallet) public
    {
        token = IERC20(_token);
        wallet = _wallet;
        ICOdatas=ICOdata(10,900000000000000000000000000,0,0,0);
        //priceFeedAvax = AggregatorV3Interface(0x5498BB86BC934c8D34FDA08E81D444153d0D06aD);
        //priceFeedEth=AggregatorV3Interface(0x86d67c3D38D2bCeE722E601025C25a575021c6EA);
        priceFeed = AggregatorV3Interface(0xd0D5e3DB44DE05E9F294BB0a3bEEaF030DE24Ada);

        
    }


    function startSale() public onlyOwner{
        uint oneyear = 31536000;
            ICOdatas.start=block.timestamp;
            ICOdatas.end = ICOdatas.start +oneyear;
    }
    function _endSale() private {
        if(address(this).balance>=6250 ether){
            ICOdatas.end=block.timestamp;
        }
    }
    function endSale() public onlyOwner {
        ICOdatas.end=block.timestamp;

    }
    function LatestPriceMatic() public view returns(uint256){
        (
            /*uint80 roundID*/,
            int price_,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = priceFeed.latestRoundData();
         return  uint(price_);
      
    }
    
    // function getLatestPriceAvax() public view returns (uint) {
    //     (
    //         /*uint80 roundID*/,
    //         int price_,
    //         /*uint startedAt*/,
    //         /*uint timeStamp*/,
    //         /*uint80 answeredInRound*/
    //     ) = priceFeedAvax.latestRoundData();
    //     return uint(price_);
    // }
    // function getLatestPriceEth() public view returns (uint) {
    //     (
    //         /*uint80 roundID*/,
    //         int price_,
    //         /*uint startedAt*/,
    //         /*uint timeStamp*/,
    //         /*uint80 answeredInRound*/
    //     ) = priceFeedEth.latestRoundData();
    //     return uint(price_);
    // }
 

    function TokenPrice() public view returns(uint256){
        uint256 x =10**27;
       uint256 tokenPrice = x/LatestPriceMatic();
       return tokenPrice;
    }
    // function getTokenPriceAvax() public view returns(uint){
    //     uint currentPriceAvax=getLatestPriceAvax();
    //     uint currentPrice=(price.mul(10**8)).div(currentPriceAvax);
    //     return currentPrice;

    // }
    // function getTokenPriceEth() public view returns(uint){
    //     uint currentPriceEth=getLatestPriceEth();
    //     uint currentPrice=(price.mul(10**8)).div(currentPriceEth);
    //     return currentPrice;

    // }

    function allowance() public view onlyOwner returns(uint){
        return token.allowance(msg.sender, address(this));
    }

    //make sure you approve tokens to this contract address
        function buy(uint256 amount) public payable{
        require(_saleIsActive(),'Sale not active');
        uint value = _calculate(amount);
        uint _amount= amount*10**18;
        require(msg.value>=value,"Not enough Eth");
        require(ICOdatas.sold + amount<=ICOdatas.supply,'Not enough tokens, try buying lesser amount');
        token.transferFrom(wallet, msg.sender, _amount);
        ICOdatas.sold+=_amount;
        _endSale();
        
    }
    // function buyInAvax(uint256 amount) public payable{
    //     require(_saleIsActive(),'Sale not active');
    //     uint value = _calculateAvax(amount);
    //     require(msg.value==value,"Not enough avax");
    //     require(ICOdatas.sold + amount<=ICOdatas.supply,'Not enough tokens, try buying lesser amount');
    //     token.transferFrom(wallet, msg.sender, amount);
    //     ICOdatas.sold+=amount;
    //     _endSale();
        
    // }
    // function buyInEth(uint256 amount) public payable{
    //     require(_saleIsActive(),'Sale not active');
    //     uint value = _calculateEth(amount);
    //     require(msg.value==value,"Not enough Eth");
    //     require(ICOdatas.sold + amount<=ICOdatas.supply,'Not enough tokens, try buying lesser amount');
    //     token.transferFrom(wallet, msg.sender, amount);
    //     ICOdatas.sold+=amount;
    //     _endSale();
        
    // }

    function _saleIsActive() private view returns(bool){
        if(block.timestamp>=ICOdatas.end )
        {
            return false;
        }
        else if( tokensLeft()==0){return false;}
        else{return true;}
    }
    function isSaleActive() public view returns(bool){
        return _saleIsActive();
    }

 function _calculate(uint value) public view returns(uint){
        return value.mul(TokenPrice());
    }
    // function _calculateAvax(uint value) public view returns(uint){
    //     return value.mul(getLatestPriceAvax());
    // }
    
    // function _calculateEth(uint value) public view returns(uint){
    //     return value.mul(getLatestPriceEth());
    // }

    function tokensLeft() public view returns(uint){
        return ICOdatas.supply-ICOdatas.sold;
    }


    function weiRaised() public view returns(uint) {
        return address(this).balance;
    }

    function claimWei() public onlyOwner {
        wallet.transfer(address(this).balance);
    }

    // function isSuccess() public view onlyOwner returns(bool){
    //     require(!_saleIsActive(),'Sale need to end first');
    //     if(weiRaisedAmount>=softCapWei){
    //         return true;
    //     }else{return false;}
    // }

}

// 1 wei = 0.000002 tokens
// 1 ether = 1e12 tokens
// number of tokens in 'y' amount of wei => y*0.000002 tokens in real life => y*0.000002*1e18 tokens where 1e18 is the decimal of token
// example: 100 wei will get me => 0.0002 tokens => 100*2*1e18/1e6 = 2*1e14 tokens in solidity

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
       function mint(address _to, uint256 _value) external returns (bool success);
          function burn(uint256 _value) external returns (bool success);

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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "../utils/context.sol";
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
    constructor () public {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT


pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  function getRoundData(
    uint80 _roundId
  )
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity >=0.6.0 <0.9.0;

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

    function _msgData() internal pure virtual returns (bytes calldata) {
        return msg.data;
    }
}