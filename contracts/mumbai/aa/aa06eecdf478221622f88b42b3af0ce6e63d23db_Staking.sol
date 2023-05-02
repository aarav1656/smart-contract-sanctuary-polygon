/**
 *Submitted for verification at polygonscan.com on 2023-05-01
*/

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


// File: @openzeppelin/contracts/utils/Address.sol

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// File: @openzeppelin/contracts/utils/Context.sol


/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin/contracts/utils/Strings.sol

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant alphabet = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = alphabet[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() {
    owner = msg.sender;
  }


  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

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

contract Staking is Ownable{

    using SafeMath for uint;

    event RewardsTransferred(address holder, uint amount);

    // token contract address
    address private tokenAddress;

    //percentage rate will be (percentage * 100)
    // reward rate 72.00% per year
    uint private rewardRate;
    uint private rewardInterval;

    // staking fee 1.50 percent
    uint private stakingFeeRate;

    // unstaking fee 0.50 percent
    uint private unstakingFeeRate;

    // unstaking possible after cliffTime value in seconds
    uint private cliffTime;

    uint public totalClaimedRewards = 0;
    
    uint public totalStakedToken = 0;

    //  array of holders;
    address[] public holders;
        
    mapping (address => uint) public depositedTokens;
    mapping (address => uint) public stakingTime;
    mapping (address => uint) public lastClaimedTime;
    mapping (address => uint) public totalEarnedTokens;
    
    constructor(address _tokenAddress, uint _rewardRate, uint _rewardInterval, uint _stakingFeeRate, uint _unstakingFeeRate, uint _cliffTime) {
        tokenAddress = _tokenAddress;
        rewardRate = _rewardRate;
        rewardInterval = _rewardInterval;
        stakingFeeRate = _stakingFeeRate;
        unstakingFeeRate = _unstakingFeeRate;
        cliffTime = _cliffTime;
    }
    
    
    // All constant value view function 
    
    /**
     * @notice Reward rate
     * @return rewardRate of staking
     */
    function getRewardRate() public view returns(uint){
        return rewardRate;
    }
    
    /**
     * @notice Reward interval
     * @return rewardInterval of staking
     */
    function getRewardInterval() public view returns(uint){
        return rewardInterval;
    }
    
    /**
     * @notice Staking Fee Rate
     * @return stakingFeeRate will be send to owner at staking time
     */
    function getStakingFeeRate() public view returns(uint){
        return stakingFeeRate;
    }
    
    /**
     * @notice Staking Fee Rate
     * @return unstakingFeeRate will be send to owner at unstaking time
     */
    function getUnstakingFeeRate() public view returns(uint){
        return unstakingFeeRate;
    }
    
    /**
     * @notice Cliff time
     * @return cliffTime after which time user can wwithdraw their stake
     */
    function getCliffTime() public view returns(uint){
        return cliffTime;
    }
    
    /**
     * @notice Token address
     * @return tokenAddress of erc20 token address which is stake in this contract
     */
    function getTokenAddress() public view returns(address){
        return tokenAddress;
    }

    /**
     * @notice Change Reward rate
     */
    function setRewardRate(uint _rewardRate) public onlyOwner{
        rewardRate = _rewardRate;
    }
    
    /**
     * @notice Change staking fee rate
     */
    function setStakingFeeRate(uint _rate) public onlyOwner{
        stakingFeeRate = _rate;
    }
    
    /**
     * @notice Change Unstaking fee rate
     */
    function setUnstakingFeeRate(uint _rate) public onlyOwner{
        unstakingFeeRate = _rate;
    }

    /**
     * @notice Change Cliff Time
     */
    function setCliffTime(uint _cliffTime) public onlyOwner{
        cliffTime = _cliffTime;
    }
    
    /**
     * @notice Number of staked token withou NFT
     * @return number of tokens staked by user without NFT
     */
    function getDepositedTokensOfUser() public view returns(uint){
        return depositedTokens[msg.sender];
    }
     
    /**
     * @notice Only Holder - check holder is exists in our contract or not
     * @return bool value
     */
    function onlyHolder() public view returns(bool){
        bool condition = false;
        for(uint i= 0; i< holders.length; i++){
            if(holders[i] == msg.sender){
                condition = true;
                return true;
            }
        }
        return false;
    }

    /**
     * @notice Update Account
     * @param account account address of the user
     */
    function updateAccount(address account) private {
        uint pendingDivs = getPendingDivs(account);
        if (pendingDivs > 0) {
            require(IERC20(tokenAddress).transfer(account, pendingDivs), "Could not transfer tokens.");
            totalEarnedTokens[account] = totalEarnedTokens[account].add(pendingDivs);
            totalClaimedRewards = totalClaimedRewards.add(pendingDivs);
            emit RewardsTransferred(account, pendingDivs);
        }
        lastClaimedTime[account] = block.timestamp;
    }

    /**
     * @notice Get Pending divs
     * @param _holder account address of the user
     * @return pendingDivs;
     */
    function getPendingDivs(address _holder) public view returns (uint) {

        uint timeDiff = block.timestamp.sub(lastClaimedTime[_holder]);
        uint stakedAmount = depositedTokens[_holder];

        uint pendingDivs = stakedAmount
                            .mul(rewardRate)
                            .mul(timeDiff)
                            .div(rewardInterval)
                            .div(1e4);

        return uint(pendingDivs);
    }

    /**
     * @notice Get number of holders
     * @notice will return length of holders array
     * @return holders;
     */
    function getNumberOfHolders() public view returns (uint) {
        return holders.length;
    }

    /**
     * @notice Deposit
     * @notice A transfer is used to bring tokens into the staking contract so pre-approval is required
     * @param amountToStake amount of total tokens user staking and get NFT basis on that 
     */
    function deposit(uint amountToStake) public {
        require(amountToStake > 0, "Cannot deposit 0 Tokens");
        require(IERC20(tokenAddress).transferFrom(msg.sender, address(this), amountToStake), "Insufficient Token Allowance");

        updateAccount(msg.sender);
        
        uint fee = amountToStake.mul(stakingFeeRate).div(1e4);
        require(IERC20(tokenAddress).transfer(owner, fee), "Could not transfer deposit fee.");
        depositedTokens[msg.sender] += amountToStake;

        if(!onlyHolder()){
            holders.push(msg.sender);
            stakingTime[msg.sender] = block.timestamp;
        }
    }
    
    /**
     * @notice withdraw
     * @dev Must be called directly by the user 
     * @param amountToWithdraw amount of total tokens user user wants to unstake
     */
    function withdraw(uint amountToWithdraw) public {
        require(depositedTokens[msg.sender] >= amountToWithdraw, "Invalid amount to withdraw");

        require(block.timestamp.sub(stakingTime[msg.sender]) > cliffTime, "You recently staked, please wait before withdrawing.");

        updateAccount(msg.sender);

        uint fee = amountToWithdraw.mul(unstakingFeeRate).div(1e4);
        uint amountAfterFee = amountToWithdraw.sub(fee);

        require(IERC20(tokenAddress).transfer(owner, fee), "Could not transfer withdraw fee.");
        require(IERC20(tokenAddress).transfer(msg.sender, amountAfterFee), "Could not transfer tokens.");

        depositedTokens[msg.sender] = depositedTokens[msg.sender].sub(amountToWithdraw);

        if(onlyHolder() && depositedTokens[msg.sender] == 0){
            for(uint i= 0; i< holders.length; i++){
            if(holders[i] == msg.sender){
                delete holders[i];
            }
        }
        }
    }
    
    /**
     * @notice Claim reward tokens call by directly from user
     */
    function claimDivs() public {
        updateAccount(msg.sender);
    }

    /**
     * @notice Get stakers list
     * @param startIndex index of array from point
     * @param endIndex index of array end point
     * @return stakers
     * @return stakingTimestamps
     * @return lastClaimedTimeStamps
     * @return stakedTokens
     */
    function getStakersList(uint startIndex, uint endIndex)
        public
        view
        returns (address[] memory stakers,
            uint[] memory stakingTimestamps,
            uint[] memory lastClaimedTimeStamps,
            uint[] memory stakedTokens) {
        require (startIndex < endIndex);

        uint length = endIndex.sub(startIndex);
        address[] memory _stakers = new address[](length);
        uint[] memory _stakingTimestamps = new uint[](length);
        uint[] memory _lastClaimedTimeStamps = new uint[](length);
        uint[] memory _stakedTokens = new uint[](length);

        for (uint i = startIndex; i < endIndex; i = i.add(1)) {
            // address staker = holders.at(i);
            address staker = holders[i];
            uint listIndex = i.sub(startIndex);
            _stakers[listIndex] = staker;
            _stakingTimestamps[listIndex] = stakingTime[staker];
            _lastClaimedTimeStamps[listIndex] = lastClaimedTime[staker];
            _stakedTokens[listIndex] = depositedTokens[staker];
        }

        return (_stakers, _stakingTimestamps, _lastClaimedTimeStamps, _stakedTokens);
    }

    // function to allow admin to claim *other* ERC20 tokens sent to this contract (by mistake)
    // Admin cannot transfer out Staking Token from this smart contract
    function transferAnyERC20Tokens(address _tokenAddr, address _to, uint _amount) public onlyOwner {
        require (_tokenAddr != tokenAddress, "Cannot Transfer Out Staking Token!");
        IERC20(_tokenAddr).transfer(_to, _amount);
    }
    
}