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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title Staking $TKI
/// @author TokenIdle
/// @notice Allows you to stake your $TKI
contract TkiStaking is Ownable {

    IERC20 public immutable tkiToken;

    uint256 public rewardsPerSecPerTokenNumerator;
    uint256 public rewardsPerSecPerTokenDenominator;

    uint256 public totalStaked;

    mapping(address => uint256) public balanceOf;
    
    mapping(address => uint256) public stakeTime;
 
    constructor(address _tkiToken) {
        tkiToken = IERC20(_tkiToken);
    }

    /// @notice Calculate the staking rewards
    /// @param _account The address associated to the rewards
    /// @return staking rewards
    function getRewards(address _account) public view returns (uint256) {
        uint256 rewardsAmount = (balanceOf[_account] * (block.timestamp - stakeTime[_account]) * rewardsPerSecPerTokenNumerator) / rewardsPerSecPerTokenDenominator;
        return rewardsAmount;
    }

    /// @notice Stake the current available staking rewards
    function reinvestRewards() external {
        uint256 rewards = getRewards(msg.sender);
        stakeTime[msg.sender] = block.timestamp;
        balanceOf[msg.sender] += rewards;
        totalStaked += rewards;
    }

    /// @notice Stake the specified amount (be sure to approve the amount before calling this function)
    /// @param _amount The amount to stake
    function stake(uint256 _amount) external {
        tkiToken.transferFrom(msg.sender, address(this), _amount);

        uint256 rewards = getRewards(msg.sender);
        stakeTime[msg.sender] = block.timestamp;
        uint256 totalToAdd = _amount+rewards;

        balanceOf[msg.sender] += totalToAdd;
        totalStaked += totalToAdd;
    }

    /// @notice Withdraw the specified amount and reinvest the staking rewards
    /// @param _amount The amount to withdraw
    function withdraw(uint256 _amount) external {
        uint256 rewards = getRewards(msg.sender);
        uint256 balance = balanceOf[msg.sender] + rewards;

        require(balance >= _amount, "amount exceed balance");
        require(tkiToken.balanceOf(address(this)) >= _amount, "contract balance too low");

        balanceOf[msg.sender] = balance - _amount;
        stakeTime[msg.sender] = block.timestamp;

        totalStaked = (totalStaked + rewards) - _amount;
        tkiToken.transfer(msg.sender, _amount);

    }

    /// @notice Withdraw the balance and the staking rewards
    function withdrawBalance() external {
        uint256 balance = balanceOf[msg.sender];
        uint256 withdrawAmount = balance + getRewards(msg.sender);

        require(tkiToken.balanceOf(address(this)) >= withdrawAmount, "contract balance too low");

        balanceOf[msg.sender] = 0;
        totalStaked -= balance;

        tkiToken.transfer(msg.sender, withdrawAmount);
    }

    /// @notice Set the staking rewards rate
    function setRewardsPerSecPerToken(uint256 _rewardsPerSecPerTokenNumerator, uint256 _rewardsPerSecPerTokenDenominator) external onlyOwner {
        require(_rewardsPerSecPerTokenDenominator > 0, "rewardsPerSecPerTokenDenominator must be > 0");
        rewardsPerSecPerTokenNumerator = _rewardsPerSecPerTokenNumerator;
        rewardsPerSecPerTokenDenominator = _rewardsPerSecPerTokenDenominator;
    }

    /// @notice Admin withdraw $TKI
    /// @param _amount The amount to withdraw
    /// @param _recipient The recipient of the $TKI
    function adminWithdraw(uint256 _amount, address _recipient) external onlyOwner{
        tkiToken.transfer(_recipient, _amount);
    }

}