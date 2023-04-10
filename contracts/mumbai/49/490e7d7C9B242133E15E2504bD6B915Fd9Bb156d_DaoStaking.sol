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

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

error InvalidToken();

contract DaoStaking is Ownable, ReentrancyGuard {
    IERC20 public immutable stakingAdsToken;
    IERC20 public immutable stakingMeToken;
    IERC20 public immutable rewardsAdsToken;
    IERC20 public immutable rewardsMeToken;

    struct RewardType {
        address stakeToken;
        address rewardToken;
        uint256 rewardDuration;
        uint256 rewardAmount;
        uint256 stakeAmount;
    }
    RewardType[] public rewardsTypes;

    struct StakerReward {
        uint256 id;
        address staker;
        uint256 stakeAmount;
        uint256 rewardType;
        uint256 stakeTime;
        uint256 claimRewardTime;
        uint256 rewardAmount;
        bool claimed;
    }
    StakerReward[] public stakerRewards;

    struct WithdrawFee {
        uint256 duration;
        uint256 withdrawFeeAmount;
    }
    WithdrawFee[] public withdawFees;

    struct Content {
        uint256 id;
        address creator;
        bool contentType; // true: Advertiser, false: Publisher
        uint256 createdAt;
        uint256 endAt;
        uint256 agreeVoteAmount;
        uint256 rejectVoteAmount;
        string siteUrl;
    }
    Content[] public contents;

    event StakeEvent(address staker, uint256 stakeAmount, uint256 rewardType);
    event WithdrawEvent(address withdrawer, uint256 withdrawAmount, uint256 id);
    event CreateContentEvent(address creator, uint256 id, uint256 createdAt, uint256 endAt, uint256 agreeVoteAmount, uint256 rejectVoteAmount, string siteUrl);

    constructor(address _stakingAdsToken, address _stakingMeToken, address _rewardsAdsToken, address _rewardsMeToken) {
        stakingAdsToken = IERC20(_stakingAdsToken);
        stakingMeToken = IERC20(_stakingMeToken);
        rewardsAdsToken = IERC20(_rewardsAdsToken);
        rewardsMeToken = IERC20(_rewardsMeToken);
    }

    modifier checkTokenAddress(address _stakeToken, address _rewardToken) {
        require(_stakeToken == address(stakingAdsToken) || _stakeToken == address(stakingMeToken), "Invalid Staking Token Address");
        require(_rewardToken == address(rewardsAdsToken) || _rewardToken == address(rewardsMeToken), "Invalid Reward Token Address");
        _;
    }

    modifier checkZeroAddress() {
        require(msg.sender != address(0), "Invalid Wallet Address");
        _;
    }

    function addRewardType(address _stakeToken, address _rewardToken, uint256 _rewardDuration, uint256 _rewardAmount, uint256 _stakeAmount) external onlyOwner checkTokenAddress(_stakeToken, _rewardToken){
        RewardType memory rewardType;
        rewardType.stakeToken = _stakeToken;
        rewardType.rewardToken = _rewardToken;
        rewardType.rewardDuration = _rewardDuration;
        rewardType.rewardAmount = _rewardAmount;
        rewardType.stakeAmount = _stakeAmount;
        rewardsTypes.push(rewardType);
    }

    function updateRewardType(uint256 _id, uint256 _rewardAmount, uint256 _rewardDuration, uint256 _stakeAmount) external onlyOwner {
        RewardType storage rewardType = rewardsTypes[_id];
        rewardType.rewardAmount = _rewardAmount;
        rewardType.rewardDuration = _rewardDuration;
        rewardType.stakeAmount = _stakeAmount;
    }

    function addWithdrawFee(uint256 _duration, uint256 _feeAmount) external onlyOwner {
        WithdrawFee memory withdrawFee;
        withdrawFee.duration = _duration;
        withdrawFee.withdrawFeeAmount = _feeAmount;
        withdawFees.push(withdrawFee);
    }

    function updateWithdrawFee(uint256 _id, uint256 _duration, uint256 _feeAmount) external onlyOwner {
        WithdrawFee storage withdrawFee = withdawFees[_id];
        withdrawFee.duration = _duration;
        withdrawFee.withdrawFeeAmount = _feeAmount;
    }

    function stake(uint256 _stakeAmount, uint256 _rewardType) external checkZeroAddress nonReentrant{
        require(_stakeAmount > 0, "amount = 0");
        require(_rewardType < rewardsTypes.length , "Invalid RewardType ID");

        StakerReward memory stakeReward;
        stakeReward.id = stakerRewards.length;
        stakeReward.staker = msg.sender;
        stakeReward.stakeAmount = _stakeAmount;
        stakeReward.rewardType = _rewardType;
        stakeReward.stakeTime = block.timestamp;
        stakeReward.claimRewardTime = block.timestamp;
        stakeReward.claimed = false;
        stakeReward.rewardAmount = 0;

        RewardType storage reward = rewardsTypes[_rewardType];
        if(reward.stakeToken == address(stakingAdsToken))
            stakingAdsToken.transferFrom(msg.sender, address(this), _stakeAmount);
        else if(reward.stakeToken == address(stakingMeToken))
            stakingMeToken.transferFrom(msg.sender, address(this), _stakeAmount);
        else
            revert InvalidToken();
        stakerRewards.push(stakeReward);

        emit StakeEvent(msg.sender, _stakeAmount, _rewardType);
    }

    function withdraw(uint256 _id) external checkZeroAddress nonReentrant {
        StakerReward storage stakerReward = stakerRewards[_id];
        require(stakerReward.staker == msg.sender, "Invalid Staker");
        require(!stakerReward.claimed, "Already Claimed");
        uint256 curTime = block.timestamp;
        uint256 diffTime = curTime - stakerReward.stakeTime;
        RewardType storage rewardType = rewardsTypes[stakerReward.rewardType];
        require(diffTime >= rewardType.rewardDuration, "This stake is not unlocked yet");

        uint256 feeAmount = 0;
        for(uint256 i;i < withdawFees.length;i++) {
            if(withdawFees[i].duration == rewardType.rewardDuration) {
                feeAmount = withdawFees[i].withdrawFeeAmount;
            }
        }
        uint256 withdrawAmount = stakerReward.stakeAmount - stakerReward.stakeAmount * feeAmount / rewardType.stakeAmount;

        if(rewardType.stakeToken == address(stakingAdsToken))
            stakingAdsToken.transfer(msg.sender, withdrawAmount);
        else if(rewardType.stakeToken == address(stakingMeToken))
            stakingMeToken.transfer(msg.sender, withdrawAmount);
        else
            revert InvalidToken();

        uint256 timeDiff = curTime - stakerReward.claimRewardTime;
        uint256 reward = stakerReward.stakeAmount * rewardType.rewardAmount * timeDiff / rewardType.stakeAmount / rewardType.rewardDuration;
        stakerReward.rewardAmount += reward;
        stakerReward.claimRewardTime = curTime;
        stakerReward.claimed = true;

        emit WithdrawEvent(msg.sender, withdrawAmount, _id);
    }

    function claimADsGTReward() external nonReentrant{
        uint256 rewardAmount = 0;
        uint256 curTime = block.timestamp;
        for(uint256 i = 0;i < stakerRewards.length; i++) {
            if(stakerRewards[i].staker == msg.sender) {
                RewardType storage rewardType = rewardsTypes[stakerRewards[i].rewardType];
                if(rewardType.rewardToken == address(rewardsAdsToken)) {
                    if(!stakerRewards[i].claimed) {
                        uint256 timeDiff = curTime - stakerRewards[i].claimRewardTime;
                        uint256 reward = stakerRewards[i].stakeAmount * rewardType.rewardAmount * timeDiff / rewardType.stakeAmount / rewardType.rewardDuration;
                        rewardAmount += reward + stakerRewards[i].rewardAmount;
                        stakerRewards[i].claimRewardTime = curTime;
                    } else {
                        rewardAmount += stakerRewards[i].rewardAmount;
                        stakerRewards[i].rewardAmount = 0;
                    }
                }
            }
        }
        require(rewardAmount > 0, "No Reward");
        rewardsAdsToken.transfer(msg.sender, rewardAmount);
    }

    function claimMeGTReward() external nonReentrant{
        uint256 rewardAmount = 0;
        uint256 curTime = block.timestamp;
        for(uint256 i = 0;i < stakerRewards.length; i++) {
            if(stakerRewards[i].staker == msg.sender) {
                RewardType storage rewardType = rewardsTypes[stakerRewards[i].rewardType];
                if(rewardType.rewardToken == address(rewardsMeToken)) {
                    if(!stakerRewards[i].claimed) {
                        uint256 timeDiff = curTime - stakerRewards[i].claimRewardTime;
                        uint256 reward = stakerRewards[i].stakeAmount * rewardType.rewardAmount * timeDiff / rewardType.stakeAmount / rewardType.rewardDuration;
                        rewardAmount += reward + stakerRewards[i].rewardAmount;
                        stakerRewards[i].claimRewardTime = curTime;
                    } else {
                        rewardAmount += stakerRewards[i].rewardAmount;
                        stakerRewards[i].rewardAmount = 0;
                    }
                }
            }
        }
        require(rewardAmount > 0, "No Reward");
        rewardsMeToken.transfer(msg.sender, rewardAmount);
    }
    
    function emergencyWithdraw() external onlyOwner {
        rewardsAdsToken.transfer(msg.sender, rewardsAdsToken.balanceOf(address(this)));
        rewardsMeToken.transfer(msg.sender, rewardsMeToken.balanceOf(address(this)));
    }

    function createContent(bool _contentType, uint256 _endAt, string memory _siteUrl) external {
        require(_endAt > block.timestamp, "Invalid End Time");

        Content memory content;
        content.id = contents.length;
        content.creator = msg.sender;
        content.contentType = _contentType;
        content.createdAt = block.timestamp;
        content.endAt = _endAt;
        content.agreeVoteAmount = 0;
        content.rejectVoteAmount = 0;
        content.siteUrl = _siteUrl;

        contents.push(content);

        emit CreateContentEvent(msg.sender, content.id, content.createdAt, _endAt, 0,0, _siteUrl);
    }

    function vote(uint256 _id, bool voteType, uint256 _voteAmount) external {
        require(_voteAmount > 0, "Invalid Vote Amount");
        uint256 curTime = block.timestamp;
        Content storage content = contents[_id];
        require(curTime <= content.endAt, "Finished Vote");

        if(voteType) {
            content.agreeVoteAmount += _voteAmount;
        } else {
            content.rejectVoteAmount += _voteAmount;
        }

        uint256 rewardAmount = 0;
        uint256 rewardSpeed = 0;
        address tokenAddress;
        if(content.contentType) {
            tokenAddress = address(rewardsMeToken);
        } else {
            tokenAddress = address(rewardsAdsToken);
        }
        (rewardAmount, rewardSpeed) = getRewardTokenInfo(tokenAddress);
        require(_voteAmount <= rewardAmount, "Insufficient Reward");

        for(uint256 i = 0;i < stakerRewards.length; i++) {
            if(_voteAmount > 0 && stakerRewards[i].staker == msg.sender) {
                RewardType storage rewardType = rewardsTypes[stakerRewards[i].rewardType];
                if(rewardType.rewardToken == address(tokenAddress)) {
                    if(!stakerRewards[i].claimed) {
                        uint256 timeDiff = curTime - stakerRewards[i].claimRewardTime;
                        uint256 _rewardAmount = stakerRewards[i].rewardAmount + stakerRewards[i].stakeAmount * rewardType.rewardAmount * timeDiff / rewardType.stakeAmount / rewardType.rewardDuration;

                        if(_voteAmount <= _rewardAmount) {
                            stakerRewards[i].rewardAmount = _rewardAmount - _voteAmount;
                            _voteAmount = 0;
                        } else {
                            stakerRewards[i].rewardAmount = 0;
                            _voteAmount = _voteAmount - _rewardAmount;
                        }
                        
                        stakerRewards[i].claimRewardTime = curTime;
                    } else {
                        if(_voteAmount <= stakerRewards[i].rewardAmount) {
                            stakerRewards[i].rewardAmount -= _voteAmount;
                            _voteAmount = 0;
                        } else {
                            stakerRewards[i].rewardAmount = 0;
                            _voteAmount -= stakerRewards[i].rewardAmount;
                        }
                    }
                }
            }
        }

        emit CreateContentEvent(msg.sender, _id, content.createdAt, content.endAt, content.agreeVoteAmount, content.rejectVoteAmount, content.siteUrl);
    }

    function getContentsLength() public view returns (uint) {
        return contents.length;
    }

    function getRewardsTypesLength() public view returns (uint) {
        return rewardsTypes.length;
    }

    function getStakerRewardsLength() public view returns (uint) {
        return stakerRewards.length;
    }

    function getWithdrawFeesLength() public view returns (uint) {
        return withdawFees.length;
    }

    function getRewardTokenInfo(address _token) public view returns (uint, uint) {
        uint256 rewardAmount = 0;
        uint256 rewardSpeed = 0;
        uint256 curTime = block.timestamp;
        for(uint256 i = 0;i < stakerRewards.length; i++) {
            RewardType storage rewardType = rewardsTypes[stakerRewards[i].rewardType];
            if(rewardType.rewardToken == address(_token)) {
                if(stakerRewards[i].staker == msg.sender) {
                    if(!stakerRewards[i].claimed) {
                        uint256 timeDiff = curTime - stakerRewards[i].claimRewardTime;
                        uint256 reward = stakerRewards[i].stakeAmount * rewardType.rewardAmount * timeDiff / rewardType.stakeAmount / rewardType.rewardDuration;
                        rewardAmount = rewardAmount + reward + stakerRewards[i].rewardAmount;
                        uint256 speed = stakerRewards[i].stakeAmount * rewardType.rewardAmount / rewardType.stakeAmount / rewardType.rewardDuration;
                        rewardSpeed += speed;
                    } else {
                        rewardAmount += stakerRewards[i].rewardAmount;
                    }
                }
            }
        }
        return (rewardAmount, rewardSpeed);
    }
}