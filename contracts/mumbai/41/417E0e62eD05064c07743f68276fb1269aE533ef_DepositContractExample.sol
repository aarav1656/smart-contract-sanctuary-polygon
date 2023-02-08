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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract DepositContractExample is Ownable {
    IERC20 public token;

    struct TradeData {
        address maker;
        address taker;
        uint balanceDelta;
        uint fee;
        uint instrumentID;
    }

    struct Deposit {
        address user;
        uint amount;
        uint txnID;
    }
    
    struct Withdrawal {
        address user;
        uint amount;
        uint txnID;
    }
    
    mapping(uint => TradeData) public trades;
    mapping(address => uint) public userBalance;
    mapping(uint => Deposit) public deposits;
    mapping(uint => Withdrawal) public withdrawals;

    event UserDeposited(address indexed _from, uint256 indexed _amount);
    event UserWithdraw(address indexed _from, uint256 indexed _amount);

    address public _USDC = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;

    constructor() {
        token = IERC20(_USDC);
    }

    function deposit(uint _amount, uint _txnID) public {
        //amount should be > 0
        require(_amount > 0);
        
        // transfer USDC to this contract
        token.transferFrom(msg.sender, address(this), _amount);

        // update staking balance
        userBalance[msg.sender] += _amount;

        // add Deposit record to deposits map
        deposits[_txnID] = Deposit({
            user: msg.sender,
            amount: _amount,
            txnID: _txnID
        });

        // emit UserDeposited event
        emit UserDeposited(msg.sender, _amount);
    }
    
    function withdraw(uint _amount, uint _txnID) public {
        //user can only withdraw up to the amount they have deposited
        uint balance = userBalance[msg.sender];

        // balance should be > 0
        require(_amount <= balance, "withdrawal amount must be less than or equal to user balance");

        // Transfer USDC tokens to the users wallet
        token.transfer(msg.sender, _amount);

        // reconciles user balance
        userBalance[msg.sender] -= _amount;

        // add Withdrawal record to deposits map
        withdrawals[_txnID] = Withdrawal({
            user: msg.sender,
            amount: _amount,
            txnID: _txnID
        });

        // emit UserWithdraw event
        emit UserWithdraw(msg.sender, _amount);
    }   

    function getAllowance() public view returns(uint) {
        return token.allowance(msg.sender, address(this));
    }

    function settleBalanceDeltas(
        address _maker, 
        address _taker, 
        uint _tradeID, 
        uint _balanceDelta, 
        uint _makerFee, 
        uint _takerFee, 
        uint _instrumentID) public onlyOwner {
        // trade object being tracked and stored on-chain by tradeID
        trades[_tradeID] = TradeData({
            maker: _maker,
            taker: _taker,
            balanceDelta: _balanceDelta,
            fee: (_makerFee + _takerFee),
            instrumentID: _instrumentID
        });
        // credit exchange with the fees from the trade
        userBalance[owner()] += (_makerFee + _takerFee);
        // increase balance delta of the maker
        userBalance[_maker] += (_balanceDelta - _makerFee);
        // decrease balance of the taker
        userBalance[_taker] -= (_balanceDelta + _takerFee);
    }

      // Function to receive Ether. msg.data must be empty
  receive() external payable {}

  // Fallback function is called when msg.data is not empty
  fallback() external payable {}
}