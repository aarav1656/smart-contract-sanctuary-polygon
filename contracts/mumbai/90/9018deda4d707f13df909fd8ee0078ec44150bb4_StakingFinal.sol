/**
 *Submitted for verification at polygonscan.com on 2023-04-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

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

// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

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


error TransferFailed();
error NeedsMoreThanZero();

contract StakingFinal is ReentrancyGuard, Ownable {
    IERC20 public s_rewardsToken;
    IERC20 public s_stakingToken;

    // This is the reward token per second
    // Which will be multiplied by the tokens the user staked divided by the total
    // This is a steady reward rate of the platform
    // That means that the more users stake, the less the reward is for everyone who is staking.
    uint256 public constant REWARD_RATE = 50000000000000000;
    uint256 public s_lastUpdateTime;
    uint256 public s_rewardPerTokenStored;
    address[] public addresses;
    // Minimal staking period in seconds
    uint256 public minStakePeriod = 120; //2 mins

    uint256 private s_totalSupply;

    mapping(address => uint256) public s_userRewardPerTokenPaid;
    mapping(address => uint256) public s_rewards;
    mapping(address => uint256) public s_stakes;
    mapping(address => uint256) public s_lastTimeOfRewardsClaimed;

    event Staked(address indexed user, uint256 indexed amount);
    event WithdrewStake(address indexed user, uint256 indexed amount);
    event RewardsClaimed(address indexed user, uint256 indexed amount);

    constructor(address stakingToken, address rewardsToken) {
        s_stakingToken = IERC20(stakingToken);
        s_rewardsToken = IERC20(rewardsToken);
    }

    /**
     * @notice How much reward a token gets based on how long it's been in and during which "snapshots"
     */
    function rewardPerToken() public view returns (uint256) {
        if (s_totalSupply == 0) {
            return s_rewardPerTokenStored;
        }
        return
            s_rewardPerTokenStored +
            (((block.timestamp - s_lastUpdateTime) * REWARD_RATE * 1e18) / s_totalSupply);
    }

    /**
     * @notice How much reward a user has earned
     */
    function earned(address account) public view returns (uint256) {
        return
            ((s_stakes[account] * (rewardPerToken() - s_userRewardPerTokenPaid[account])) / 1e18) + s_rewards[account];
    }

    /**
     * @notice Deposit tokens into this contract
     * @param amount | How much to stake
     */
    function stake(uint256 amount)
        external
        updateReward(msg.sender)
        nonReentrant
        moreThanZero(amount)
    {
        if(!(s_stakes[msg.sender] > 0)){
            addresses.push(msg.sender);
        }
        s_totalSupply += amount;
        s_stakes[msg.sender] += amount;
        emit Staked(msg.sender, amount);
        bool success = s_stakingToken.transferFrom(msg.sender, address(this), amount);
        if (!success) {
            revert TransferFailed();
        }
    }

    /**
     * @notice Withdraw tokens from this contract
     * @param amount | How much to withdraw
     */
    function withdraw(uint256 amount) external updateReward(msg.sender) nonReentrant {
        s_totalSupply -= amount;
        s_stakes[msg.sender] -= amount;
        emit WithdrewStake(msg.sender, amount);
        bool success = s_stakingToken.transfer(msg.sender, amount);
        if (!success) {
            revert TransferFailed();
        }
    }

    /**
     * @notice User claims their tokens
     */
    function claimReward() external updateReward(msg.sender) nonReentrant {
      require(
            claimRewardsTimer(msg.sender) == 0,
            "Tried to claim rewards too soon"
        );
        s_lastTimeOfRewardsClaimed[msg.sender] = block.timestamp;
        uint256 reward = s_rewards[msg.sender];
        s_rewards[msg.sender] = 0;
        emit RewardsClaimed(msg.sender, reward);
        bool success = s_rewardsToken.transfer(msg.sender, reward);
        if (!success) {
            revert TransferFailed();
        }
    }

    // Utility function that returns the timer for claiming rewards
    function claimRewardsTimer(address _user)
        public
        view
        returns (uint256 _timer)
    {
        if (s_lastTimeOfRewardsClaimed[_user] + minStakePeriod <= block.timestamp) {
            return 0;
        } else {
            return
                (s_lastTimeOfRewardsClaimed[_user] + minStakePeriod) -
                block.timestamp;
        }
    }

    /********************/
    /* Modifiers Functions */
    /********************/
    modifier updateReward(address account) {
        s_rewardPerTokenStored = rewardPerToken();
        s_lastUpdateTime = block.timestamp;
        s_rewards[account] = earned(account);
        s_userRewardPerTokenPaid[account] = s_rewardPerTokenStored;
        _;
    }

    modifier moreThanZero(uint256 amount) {
        if (amount == 0) {
            revert NeedsMoreThanZero();
        }
        _;
    }

    /********************/
    /* Getter Functions */
    /********************/
    function getStaked(address _stakeholder) public view returns (uint256) {
        return s_stakes[_stakeholder];
    }

    function getStakableTokensBalance(address account) public view returns (uint256) {
      return s_stakingToken.balanceOf(account);
    }

    function getRewardsTokensBalance(address account) public view returns (uint256) {
      return s_rewardsToken.balanceOf(account);
    }

    function getTotalRewardTokensSupply() public view returns (uint256) {
      return s_rewardsToken.totalSupply();
    }

    function getTotalStakingTokensSupply() public view returns (uint256) {
      return s_stakingToken.totalSupply();
    }

    function getTotalStakes() public view returns (uint256) {
      return s_totalSupply;
    }

    function getRewardPerTokenStored() public view returns (uint256) {
      return s_rewardPerTokenStored;
    }

    function getSender() public view returns (address) {
      return msg.sender;
    }

    function getOwner() public view returns (address) {
      return owner();
    }

    function isOwner(address account) public view returns (bool) {
      return owner() == account;
    }

    function getUsersStaked(address account) public view returns (address[] memory, uint[] memory) {
      require(owner() == account, "You are not the owner");
      address[] memory mAddresses = new address[](addresses.length);
      uint[] memory mStakes = new uint[](addresses.length);

      for(uint i=0; i<addresses.length; i++) {
        mAddresses[i] = addresses[i];
        mStakes[i] = s_stakes[addresses[i]];
      }

      return (mAddresses, mStakes);
    }

    function getUsersRewards(address account) public view returns (address[] memory, uint[] memory) {
      require(owner() == account, "You are not the owner");
      address[] memory mAddresses = new address[](addresses.length);
      uint[] memory mRewards = new uint[](addresses.length);

      for(uint i=0; i<addresses.length; i++) {
        mAddresses[i] = addresses[i];
        mRewards[i] = s_rewardsToken.balanceOf(addresses[i]);
      }

      return (mAddresses, mRewards);
    }
    
}