/**
 *Submitted for verification at polygonscan.com on 2022-11-07
*/

pragma solidity ^0.8.6;


/**
WARNING: INVEST ONLY IF YOU TRUST THE PROJECT OWNER/TEAM, AS YOUR FUNDS WILL LOCKED 
(and will be used by company to maximize the returns).
There is no gaurantee of fixed profit, you may loose funds.

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}
// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.17;

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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.17;


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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.17;

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


contract TestManager is Ownable, ReentrancyGuard{

    

 IERC20 token;
 IERC20 public  USDT = IERC20(0xd8b934580fcE35a11B58C6D73aDeE468a2833fa8);
 bool public open = false;
 address  private _wallet = address  (0x123);
 
 mapping(address => uint256) public payment;
 mapping(address => uint256) public depositTime;
 uint256 public mincap = 100 * 10**6; // 100 USDT
 uint256 public maxcap = 100000 * 10**6;  // 100000 USDT
 uint256 private saleUSDT = 0;
 uint256 private USDTClaimFund = 0;
 uint256 public lockupTime = 365 days;
 uint256 public hardcap = 5000000 * 10**6; // 5000000 USDT

                    
 uint256 public rate = 1000000000000;
 uint256 div = 1;
 
 constructor ( address _token) {
     token = IERC20(_token);
 }
 
 
 function openPortal() public onlyOwner {
     open = true;
 }

 function closePortal() public onlyOwner {
     open = false;
 }
 
 
 function invest(uint256 amount) public nonReentrant {
     require(saleUSDT <= hardcap, "Manager: Hardcap Reached");
     require(open == true, "Manager: Investment Portal is not Open yet");
     uint256 cnt = (amount * rate)/div;
     require(token.balanceOf(address(this)) >= cnt, "Contract has less than requested tokens");
     require(payment[msg.sender]+ amount >= mincap && payment[msg.sender]+amount <= maxcap, "Not in between minimum Capital and maximum Capital"); 
     sendShares(cnt, amount);
     depositTime[msg.sender] = block.timestamp;
 }
 

 
 function sendShares(uint256 cnt, uint256 _payment) internal returns (bool success){
    payment[msg.sender] += _payment;
    USDT.transferFrom(msg.sender, owner(), _payment);
    saleUSDT += _payment;
    token.transfer(msg.sender,cnt);
    return true;
 }

 function returnShares() external onlyOwner returns(bool success){
     token.transfer(owner(),token.balanceOf(address(this)));
     return true;
 }
 
 receive() payable external {
    
 }

 function claimInvestment () external nonReentrant {
     uint256 claimTime = block.timestamp - depositTime[msg.sender];
     uint256 PerShare = USDTClaimFund/saleUSDT;
     if (claimTime >= lockupTime){
         uint256 amount = payment[msg.sender];
         require (token.transferFrom(msg.sender, owner(), amount),"Not enough shares to claim investment");
         payment[msg.sender] = 0;
         USDT.transfer(msg.sender, amount*PerShare);
        
     }
    else {
        require (claimTime >= lockupTime, "Investment is in Lockup period");
    }

 }

 function setHardcap (uint256 newHardcap) external onlyOwner {
    hardcap = newHardcap * 10**6;
 }

 function setLockUpTime (uint256 _inDays) external onlyOwner {
     require (_inDays <= 365, " lockup period should be less than eqaul to 1 year");
     lockupTime = _inDays * 1 days;
 }
 //Function to inject Funds so Users can claim
 function injectFunds (uint256 amount) external onlyOwner {
     uint256 balance = amount * 10**6;
     USDT.transferFrom(msg.sender, address(this), balance);
     USDTClaimFund += balance;
 }

 function setUSDT (IERC20 usdt) external onlyOwner {
     USDT = usdt;
 }
 
}