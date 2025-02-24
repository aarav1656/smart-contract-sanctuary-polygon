// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract TKNStakingT24 is Ownable {

    struct Deposit {
        uint256 tokenAmount;
        uint256 weight;
        uint256 lockedUntil;
        uint256 entryTime;
        uint256 rewardDebt;
        uint256 claimedSoFar;
        uint256 lockMode;
    }

    struct UserInfo {
        uint256 tokenAmount;
        uint256 totalWeight;
        uint256 totalRewardsClaimed;
        Deposit[] deposits;
    }

    uint256 public constant ONE_DAY = 3 minutes;
    uint256 public constant MULTIPLIER = 1e14; //

    uint256 public lastRewardBlock; // Last block number that TKNs distribution occurs.
    uint256 public accTokenPerUnitWeight; // Accumulated TKNs per weight, times MULTIPLIER.

    // total locked amount across all users
    uint256 public usersLockingAmount;
    // total locked weight across all users
    uint256 public usersLockingWeight;

    // the bonus weight multiplier based on lock duration
    uint256[4] public rewardBonusWeight;
    // possible lock durations (in days)
    uint256[4] public lockDurations;

    // The staking and reward token
    IERC20 public immutable token;
    // TKN tokens rewarded per block.
    uint256 public rewardPerBlock;
    // The accounting of unclaimed TKN rewards
    uint256 public unclaimedTokenRewards;

    // Toggle new entry staking in case of maintenance
    bool public stakeDisabled = false;

    // All staking users info
    UserInfo[] private allUsersInfo;
    bool getUsersAllowed = true;

    // The REMN reward vault for stakers to claim from
    address public rewardVault;

    // Info of each user that stakes LP tokens.
    mapping(address => UserInfo) public userInfo;

    event Staked(address indexed user, uint256 amount, uint256 stakeType);
    event Unstaked(address indexed user, uint256 amount, uint256 stakeType);
    event Claimed(address indexed user, uint256 amount, uint256 stakeType);

    constructor(address _token, uint256 _rewardPerBlock, uint256 _startBlock) {
        require(_startBlock > block.number, "TKNStakingT1: _startBlock must be in the future");
        token = IERC20(_token);
        rewardPerBlock = _rewardPerBlock;
        lastRewardBlock = _startBlock;
        rewardBonusWeight[0] = 100; // 14 day lock 100% rewards
        rewardBonusWeight[1] = 110; // 30 day lock 110% rewards
        rewardBonusWeight[2] = 125; // 90 day lock 125% rewards
        rewardBonusWeight[3] = 160; // 180 day lock 160% rewards
        lockDurations[0] = 14;
        lockDurations[1] = 30;
        lockDurations[2] = 90;
        lockDurations[3] = 180;
        rewardVault = address(this);
    }

    // Returns total staked token balance for the given address
    function balanceOf(address _user) external view returns (uint256) {
        return userInfo[_user].tokenAmount;
    }

    // Returns total staked token weight for the given address
    function weightOf(address _user) external view returns (uint256) {
        return userInfo[_user].totalWeight;
    }

    // Returns information on the given deposit for the given address
    function getDeposit(address _user, uint256 _depositId) external view returns (Deposit memory) {
        return userInfo[_user].deposits[_depositId];
    }

    // Returns number of deposits for the given address. Allows iteration over deposits.
    function getDepositsLength(address _user) external view returns (uint256) {
        return userInfo[_user].deposits.length;
    }

    // Returns all users (this function is very costly)
    function getAllUsers() external view returns (UserInfo[] memory) {
        require(getUsersAllowed, "Get users not allowed");
        return allUsersInfo;
    }

    // Returns indexed user
    function getUserByIndex(uint256 _index) external view returns (UserInfo memory) {
        require(getUsersAllowed, "Get users not allowed");
        return allUsersInfo[_index];
    }

    // Returns users indexed from lower and upper bounds specified
    function getUsersInRange(uint256 _lower, uint256 _upper) external view returns (UserInfo[] memory) {
        require(getUsersAllowed, "Get users not allowed");
        require(_lower < _upper && _lower >= 0);
        UserInfo[] memory users;
        for (uint256 i = _lower; i < _upper; i++) {
            UserInfo memory user = allUsersInfo[i];
            users[i] = user;
        }
        return users;
    }

    // Get total user stake count
    function getTotalStakers() external view returns (uint256) {
        require(getUsersAllowed, "Get users not allowed");
        return allUsersInfo.length;
    }

    function getPendingRewardOf(address _staker, uint256 _depositId) external view returns(uint256) {
        UserInfo storage user = userInfo[_staker];
        Deposit storage stakeDeposit = user.deposits[_depositId];

        uint256 _amount = stakeDeposit.tokenAmount;
        uint256 _weight = stakeDeposit.weight;
        uint256 _rewardDebt = stakeDeposit.rewardDebt;

        require(_amount > 0, "TKNStakingT1: Deposit amount is 0");

        // calculate reward upto current block
        uint256 tokenReward = (block.number - lastRewardBlock) * rewardPerBlock;
        uint256 _accTokenPerUnitWeight = accTokenPerUnitWeight + (tokenReward * MULTIPLIER) / usersLockingWeight;
        uint256 _rewardAmount = ((_weight * _accTokenPerUnitWeight) / MULTIPLIER) - _rewardDebt;

        return _rewardAmount;
    }

    function getUnlockSpecs(uint256 _amount, uint256 _lockMode) public view returns(uint256 lockUntil, uint256 weight) {
        require(_lockMode < 4, "TKNStakingT1: Invalid lock mode");

        if(_lockMode == 0) {
            // 0 : 14-day lock
            return (now256() + lockDurations[0] * ONE_DAY, _amount + (_amount*rewardBonusWeight[0])/100);
        }
        else if(_lockMode == 1) {
            // 1 : 30-day lock
            return (now256() + lockDurations[1] * ONE_DAY, _amount + (_amount*rewardBonusWeight[1])/100);
        }
        else if(_lockMode == 2) {
            // 2 : 90-day lock
            return (now256() + lockDurations[2] * ONE_DAY, _amount + (_amount*rewardBonusWeight[2])/100);
        }

        // 3 : 180-day lock
        return (now256() + lockDurations[3] * ONE_DAY, _amount + (_amount*rewardBonusWeight[3])/100);
    }

    function setRewardVaultAddress(address _addr) external onlyOwner {
        rewardVault = _addr;
    }

    function changeRewardBonusPercent(uint256 _new1, uint256 _new2, uint256 _new3, uint256 _new4) external onlyOwner {
        require(_new4 > _new3 && _new3 > _new2 && _new2 > _new1 && _new1 >= 0 && _new4 <= 300, "Invalid reward bonus percentages");
        rewardBonusWeight[0] = _new1; // 14 day lock
        rewardBonusWeight[1] = _new2; // 30 day lock
        rewardBonusWeight[2] = _new3; // 90 day lock
        rewardBonusWeight[3] = _new4; // 180 day lock
    }

    function changeLockDurations(uint256 _new1, uint256 _new2, uint256 _new3, uint256 _new4) external onlyOwner {
        require(_new4 > _new3 && _new3 > _new2 && _new2 > _new1 && _new1 >= 0 && _new4 <= 720, "Invalid lock durations");
        lockDurations[0] = _new1; // xx day lock
        lockDurations[1] = _new2; // xx day lock
        lockDurations[2] = _new3; // xx day lock
        lockDurations[3] = _new4; // xx day lock
    }

    function now256() public view returns (uint256) {
        // return current block timestamp
        return block.timestamp;
    }

    function blockNumber() public view returns (uint256) {
        // return current block number
        return block.number;
    }

    function updateRewardPerBlock(uint256 _newRewardPerBlock) external onlyOwner {
        _sync();
        rewardPerBlock = _newRewardPerBlock;
    }

    // Added to support recovering lost tokens that find their way to this contract
    function recoverERC20(address _tokenAddress, uint256 _tokenAmount) external onlyOwner {
        require(_tokenAddress != address(token), "TKNStakingT1: Cannot withdraw the staking token");
        IERC20(_tokenAddress).transfer(msg.sender, _tokenAmount);
    }

    // Update reward variables
    function sync() external {
        _sync();
    }

    // Stake tokens
    function stake(uint256 _amount, uint256 _lockMode) external {
        _stake(msg.sender, _amount, _lockMode);
    }

    // Unstake tokens and claim rewards
    function unstakeRemn(uint256 _depositId) external {
        _unstake(msg.sender, _depositId, true);
    }

    // Claim rewards
    function claimRemnRewards(uint256 _depositId) external {
        _claimRewards(msg.sender, _depositId);
    }

    // Claim all rewards (if user has multiple stakes)
    function claimAllRemnRewards() external {
        for (uint256 i = 0; i < userInfo[msg.sender].deposits.length; i++) {
            _claimRewards(msg.sender, i);
        }
    }

    // Unstake tokens withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _depositId) external {
        _unstake(msg.sender, _depositId, false);
    }

    function _sync() internal {
        if (block.number <= lastRewardBlock) {
            return;
        }
        uint256 _weightLocked = usersLockingWeight;
        if (_weightLocked == 0) {
            lastRewardBlock = block.number;
            return;
        }
        uint256 tokenReward = (block.number - lastRewardBlock) * rewardPerBlock;

        uint256 surplusToken = token.balanceOf(rewardVault) - usersLockingAmount - unclaimedTokenRewards;
        require(surplusToken >= tokenReward, "TKNStakingT1: Insufficient TKN tokens for rewards");
        unclaimedTokenRewards += tokenReward;
        accTokenPerUnitWeight += (tokenReward * MULTIPLIER) / _weightLocked;
        lastRewardBlock = block.number;
    }

    function _stake(address _staker, uint256 _amount, uint256 _lockMode) internal {
        require(_amount > 0, "TKNStakingT1: Deposit amount is 0");
        _sync();

        UserInfo storage user = userInfo[_staker];

        _transferTokenFrom(address(_staker), address(this), _amount);

        (uint256 lockUntil, uint256 stakeWeight) = getUnlockSpecs(_amount, _lockMode);

        // create and save the deposit (append it to deposits array)
        Deposit memory deposit =
            Deposit({
                tokenAmount: _amount,
                weight: stakeWeight,
                lockedUntil: lockUntil,
                entryTime: now256(),
                rewardDebt: (stakeWeight*accTokenPerUnitWeight) / MULTIPLIER,
                claimedSoFar: 0,
                lockMode: _lockMode
            });
        // deposit ID is an index of the deposit in `deposits` array
        user.deposits.push(deposit);

        allUsersInfo.push(user); // Add to all users array for tracking all stakers

        user.tokenAmount += _amount;
        user.totalWeight += stakeWeight;

        // update global variable
        usersLockingWeight += stakeWeight;
        usersLockingAmount += _amount;

        emit Staked(_staker, _amount, _lockMode);
    }

    function _unstake(address _staker, uint256 _depositId, bool _sendRewards) internal {
        UserInfo storage user = userInfo[_staker];
        Deposit storage stakeDeposit = user.deposits[_depositId];

        uint256 _amount = stakeDeposit.tokenAmount;
        uint256 _weight = stakeDeposit.weight;
        uint256 _rewardDebt = stakeDeposit.rewardDebt;

        require(_amount > 0, "TKNStakingT1: Deposit amount is 0");
        require(now256() > stakeDeposit.lockedUntil, "TKNStakingT1: Deposit not unlocked yet");

        if(_sendRewards) {
            _sync();
        }

        uint256 _rewardAmount = ((_weight * accTokenPerUnitWeight) / MULTIPLIER) - _rewardDebt;

        // update user record
        user.tokenAmount -= _amount;
        user.totalWeight = user.totalWeight - _weight;
        user.totalRewardsClaimed += _rewardAmount;

        // update global variable
        usersLockingWeight -= _weight;
        usersLockingAmount -= _amount;
        unclaimedTokenRewards -= _rewardAmount;

        uint256 tokenToSend = _amount;
        if(_sendRewards) {
            // add rewards
            tokenToSend += _rewardAmount;
            emit Claimed(_staker, _rewardAmount, stakeDeposit.lockMode);
        }

        delete user.deposits[_depositId];

        // return tokens back to holder
        _safeTokenTransfer(_staker, tokenToSend);
        emit Unstaked(_staker, _amount, stakeDeposit.lockMode);
    }

    function _claimRewards(address _staker, uint256 _depositId) internal {
        UserInfo storage user = userInfo[_staker];
        Deposit storage stakeDeposit = user.deposits[_depositId];

        uint256 _amount = stakeDeposit.tokenAmount;
        uint256 _weight = stakeDeposit.weight;
        uint256 _rewardDebt = stakeDeposit.rewardDebt;

        require(_amount > 0, "TKNStakingT1: Deposit amount is 0");
        _sync();

        uint256 _rewardAmount = ((_weight * accTokenPerUnitWeight) / MULTIPLIER) - _rewardDebt;

        // update stakeDeposit record
        stakeDeposit.rewardDebt += _rewardAmount;

        // update info on amount claimed so far
        stakeDeposit.claimedSoFar += _rewardAmount;

        // update user record
        user.totalRewardsClaimed += _rewardAmount;

        // update global variable
        unclaimedTokenRewards -= _rewardAmount;

        // return tokens back to holder
        _safeTokenTransfer(_staker, _rewardAmount);
        emit Claimed(_staker, _rewardAmount, stakeDeposit.lockMode);
    }

    function _transferTokenFrom(address _from, address _to, uint256 _value) internal {
        IERC20(token).transferFrom(_from, _to, _value);
    }

    // Safe token transfer function, just in case if rounding error causes contract to not have enough TKN.
    function _safeTokenTransfer(address _to, uint256 _amount) internal {
        uint256 tokenBal = token.balanceOf(rewardVault);
        if (_amount > tokenBal) {
            IERC20(token).transferFrom(rewardVault, _to, tokenBal);
        } else {
            IERC20(token).transferFrom(rewardVault, _to, _amount);
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