// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

/// Imports
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';
import "./VRFv2Consumer.sol";

uint constant MAX_BPS = 10_000;

/// @title Bidtree project contract
contract Bidtree is Ownable {

    using SafeERC20 for IERC20;
    using Counters for Counters.Counter;

    // Events
    event Contributed(
        address user,
        address refadr,
        uint refBidNum,
        uint amount,
        uint refund,
        uint links,
        uint referral,
        uint lottery,
        uint fund,
        uint128 btcRate
    );
    event Offset(address user, uint number, uint amount, uint price);
    event Lottery(uint num, address user, uint bank);

    /// Variables
    Counters.Counter _countContributions; // Bids number counter
    Counters.Counter _countOffsetBids; // Refunded bids number counter
    bool private locker; // To prevent reentrancy attacks
    bool _final = false; // End game indicator
    uint _share; // The share of the bank per user after (determined after the completing of the game)
    uint public timer; // Timer, set after the completing of the game (so that users can collect their compensation)
    uint private _waitingTime; // The number of days set for the timer
    uint private _depositAmount; // Bid amount
    address private _wallet; // Wallet address for the current contract
    address private _usd; // Currency token address
    address private _bitcoin; // Reserved token address
    address private _router = 0x59CCfF117C37E0aabb5b50a4E64418358279525A;// DEX router address
    address private _vrf = 0x6339Cbaf53108a0F936304c4790a49745C0E6ebc; // Randomizer generator contract address
    uint private _percentageOwner; // Owner's share (в BP, 1% = 100bp)
    uint private _percentageMarketing; // Marketing share (в BP, 1% = 100bp)
    uint private _percentageLottery;  // Lottery share (в BP, 1% = 100bp)
    uint private _percentageReferral;  // Referal share (в BP, 1% = 100bp)
    uint private _percentageFund; // Fund share (в BP, 1% = 100bp)
    uint private _bankLottery; // Lottery bank
    uint private _bankOwner; // Owner's bank
    uint private _bankMarketing;  // Marketing bank
    uint private _bankFund; // Fund's bank
    uint private _randomNum; // The random number received from another contract
    uint private _startLotteryNum; // The bet number from which a round of the lottery starts
    uint private _numSales; // Number of discounts
    mapping(uint => address) private _payments; // Mapping bid number with contributor address
    mapping(uint => uint) private _multi;  // Mapping bid number with multiplier
    mapping(address => Contribution) private _contributions; // Mapping contributor address with the contribution structure


    /// Structurs
    struct Bid {
        uint128 _price; // Bid price
        uint128 _share_found; // BTC amount sent to fund
        uint128 _res_price; // BTC rate when the bid was contributed
        uint128 _referrals; // Referrals left
        uint128 _referrals_closed; // Referrals closed
        bool _gifted; // Is bid gifted
    }

    struct Contribution {
        mapping(uint => Bid) _bids; // Mapping user's contribution number with the bid structure
        Counters.Counter _countBids; // User's bids counter
    }

    /// Constructor
    constructor(address usd, address bitcoin, uint waitingTime, uint depositAmount,
        uint percentageOwner, uint percentageMarketing, uint percentageLottery, uint percentageReferral, uint percentageFund, uint numSales) {
        _usd = usd;
        _bitcoin = bitcoin;
        _waitingTime = waitingTime;
        _depositAmount = depositAmount;
        _percentageOwner = percentageOwner;
        _percentageMarketing = percentageMarketing;
        _percentageLottery = percentageLottery;
        _percentageReferral = percentageReferral;
        _percentageFund = percentageFund;
        _numSales = numSales;
        _wallet = address(this);
    }

    /// @notice Getting game status
    function getFinalizeStatus() external view returns (bool){
        return _final;
    }
    /// @notice Getting Amount of contributions
    function getDepositAmount() external view returns (uint){
        return _depositAmount;
    }
    /// @notice Setting Amount of contributions
    /// @param depositAmount - amount of contributions
    function setDepositAmount(uint depositAmount) external onlyOwner {
        _depositAmount = depositAmount;
    }
    /// @notice Getting Percentage of contributions to the owner
    function getPercentageOwner() external view returns (uint){
        return _percentageOwner;
    }
    /// @notice Setting Percentage of contributions to the owner
    /// @param percentageOwner - amount percentage of contributions to the owner
    function setPercentageOwner(uint percentageOwner) external onlyOwner {
        _percentageOwner = percentageOwner;
    }
    /// @notice Getting Percentage of contributions to the Fund
    function getPercentageFund() external view returns (uint){
        return _percentageFund;
    }
    /// @notice Setting Percentage of contributions to the Fund
    /// @param percentageFund - amount percentage of contributions to the Fund
    function setPercentageFund(uint percentageFund) external onlyOwner {
        _percentageFund = percentageFund;
    }
    /// @notice Getting Percentage of contributions to the marketing
    function getPercentageMarketing() external view returns (uint){
        return _percentageMarketing;
    }
    /// @notice Setting Percentage of contributions to the Marketing
    /// @param percentageMarketing - amount percentage of contributions to the Marketing
    function setPercentageMarketing(uint percentageMarketing) external onlyOwner {
        _percentageMarketing = percentageMarketing;
    }
    /// @notice Getting Percentage of contributions to the Lottery
    function getPercentageLottery() external view returns (uint){
        return _percentageLottery;
    }
    /// @notice Setting Percentage of contributions to the Lottery
    /// @param percentageLottery - amount percentage of contributions to the Lottery
    function setPercentageLottery(uint percentageLottery) external onlyOwner {
        _percentageLottery = percentageLottery;
    }
    /// @notice Getting Percentage of contributions to the Referral
    function getPercentageReferral() external view returns (uint){
        return _percentageReferral;
    }
    /// @notice Setting Percentage of contributions to the Referral
    /// @param percentageReferral - amount percentage of contributions to the Referral
    function setPercentageReferral(uint percentageReferral) external onlyOwner {
        _percentageReferral = percentageReferral;
    }
    /// @notice Getting Waiting Time
    function getWaitingTime() external view returns (uint){
        return _waitingTime;
    }
    /// @notice Setting Waiting Time
    /// @param waitingTime - in days
    function setWaitingTime(uint waitingTime) external onlyOwner {
        _waitingTime = waitingTime;
    }
    /// @notice Getting count all contribution
    /// @return (uint)
    function getCount() external view onlyOwner returns (uint){
        return _countContributions.current();
    }
    /// @notice Getting sum Bank of Lottery
    /// @return (uint)
    function getAmountLottery() external view returns (uint){
        return _bankLottery;
    }
    /// @notice Getting sum Bank of Owner
    /// @return (uint)
    function getAmountOwner() external view onlyOwner returns (uint){
        return _bankOwner;
    }
    /// @notice Getting sum Bank of Marketing
    /// @return (uint)
    function getAmountMarketing() external view onlyOwner returns (uint){
        return _bankMarketing;
    }
    /// @notice Getting sum Bank of Fund
    /// @return (uint)
    function getAmountFund() external view onlyOwner returns (uint){
        return _bankFund;
    }

    /// @notice Getting sum Bank of Fund
    /// @return (uint)
    function getActiveReferrals(address account, uint bid) external view onlyOwner returns (uint){
        return _contributions[account]._bids[bid]._referrals;
    }


    /// @notice Getting count of account bids
    /// @return (uint)
    function getCountBid(address account) external view returns (uint){
        return _contributions[account]._countBids.current();
    }
    /// @notice Getting account bid by number
    /// @return (uint)
    function getBid(address account, uint num) external view returns (Bid memory){
        return _contributions[account]._bids[num];
    }
    /// @notice Get lottery random number
    function getRandomNum() public view returns (uint){
        return _randomNum;
    }
    /// @notice Update lottery random number (После утверждения транзакции нужно подождать 2-3 минуту для обновления значения Оракулом)
    function updateRandomNum() external onlyOwner {
        VRFv2Consumer(_vrf).requestRandomWords();
    }
    /// @notice Get amount of discounts
    function getNumSales() external view returns (uint){
        return _numSales;
    }
    /// @notice Get share contribute
    /// @param multi - Referrals amount - 1
    function getShare(uint multi) internal view returns (uint, uint, uint, uint, uint, uint, uint){
        if (multi == 1) {
            uint _shareFond = _depositAmount * _percentageFund / MAX_BPS;
            uint _shareReferral = _depositAmount * _percentageReferral / MAX_BPS;
            uint _shareLottery = _depositAmount * _percentageLottery / MAX_BPS;
            uint _shareMarketing = _depositAmount * _percentageMarketing / MAX_BPS;
            uint _shareOwner = _depositAmount * _percentageOwner / MAX_BPS;
            uint _refund;
            return (_depositAmount, _shareFond, _shareReferral, _shareLottery, _shareMarketing, _shareOwner, _refund);
        } else {
            uint _amountGen = multi * _depositAmount;
            uint _shareFond = _amountGen * _percentageFund / MAX_BPS;
            uint _shareReferral = _depositAmount * _percentageReferral / MAX_BPS;
            uint _shareLottery = _amountGen * _percentageLottery / MAX_BPS;
            uint _shareMarketing = _amountGen * _percentageMarketing / MAX_BPS;
            uint _shareOwner = _amountGen * _percentageOwner / MAX_BPS;
            uint _refund = (_amountGen * _percentageReferral / MAX_BPS) - _shareReferral;
            return (_amountGen, _shareFond, _shareReferral, _shareLottery, _shareMarketing, _shareOwner, _refund);
        }
    }

    /// @notice Contribute
    /// @param multi - Referrals amount - 1
    /// @param base - Root bid or referral
    /// @param referral - Referral address
    /// @param bid - Referral bid number
    function contribute(uint multi, bool base, address referral, uint bid) external {
        require(_final == false, "Game finalized");
        Bid storage b_referral = _contributions[referral]._bids[bid];
        if (base == false) {
            require(b_referral._referrals > 0);
        }
        require(!locker);
        locker = true;

        (uint _deposit, uint _fond, uint _referral, uint _lottery, uint _marketing, uint _toOwner, uint _refund) = getShare(multi);
        if (_numSales > 0 && base == true) {
            _deposit -= _depositAmount / 2;
            _referral -= _depositAmount / 2;
        }
        address[] memory path = new address[](2);
        path[0] = _usd;
        path[1] = _bitcoin;
        _bankLottery += _lottery;
        _bankMarketing += _marketing;
        _bankOwner += _toOwner;
        _payments[_countContributions.current()] = msg.sender;
        _multi[_countContributions.current()] = multi + 1;
        _countContributions.increment();

        Contribution storage c_sender = _contributions[msg.sender];
        Bid storage b_sender = _contributions[msg.sender]._bids[c_sender._countBids.current()];

        b_sender._referrals = uint128(multi + 1);
        b_sender._referrals_closed = uint128(0);
        b_sender._gifted = false;

        if (base == true) {
            _fond += _referral;
            _referral = 0;
            IERC20(_usd).safeTransferFrom(msg.sender, _wallet, _deposit - _refund);
            b_sender._price = uint128(_deposit - _refund);
        } else {
            IERC20(_usd).safeTransferFrom(msg.sender, referral, _referral);
            IERC20(_usd).safeTransferFrom(msg.sender, _wallet, (_deposit - _referral - _refund));
            b_referral._referrals --;
            b_referral._referrals_closed ++;
            b_sender._price = uint128(_deposit - _referral - _refund);
        }

        b_sender._share_found = uint128(_fond);

        IERC20(_usd).approve(_router, _fond);
        uint _fromSwap = IUniswapV2Router02(_router).swapExactTokensForTokens(_fond, 0, path, address(this), block.timestamp)[1];
        _bankFund += _fromSwap;
        require(_fromSwap > 0, "from DEX comes 0 token");
        require(_fond / _fromSwap > 0, "the price is 0");

        b_sender._res_price = uint128(_fond / _fromSwap);
        c_sender._countBids.increment();
        if (_numSales > 0 && base == true) {
            _numSales --;
        }
        locker = false;
        emit Contributed(
            msg.sender,
            referral,
            bid,
            _deposit,
            _refund,
            b_sender._referrals,
            _referral,
            _lottery,
            b_sender._share_found,
            b_sender._res_price
        );
    }

    /// @notice Referral contribute
    /// @param number - user's refundable bet number
    function offsetContribution(uint number) external {
        Contribution storage c_sender = _contributions[msg.sender];
        require(c_sender._bids[number]._gifted == false, 'This bid was gifted');

        uint _unclose = c_sender._bids[number]._referrals;
        uint _closed = c_sender._bids[number]._referrals_closed;
        require(_unclose > 0, 'The bet has already been refunded');
        require(!locker);
        locker = true;


        uint _amount = c_sender._bids[number]._price - _closed * (_depositAmount * _percentageReferral / MAX_BPS);
        require(_amount > 0, 'Bid was already covered by referrals');
        address[] memory path = new address[](2);
        path[0] = _bitcoin;
        path[1] = _usd;
        uint _toSwap;
        uint _price = IUniswapV2Router02(_router).getAmountsOut(_amount, path)[1] / _amount;

        uint _new_share = (c_sender._bids[number]._share_found / c_sender._bids[number]._res_price) * _price;

        if (_final == false) {
            require(_new_share >= _amount, 'The deposit of the rate in the reserve has not yet increased enough');
        }
        if (_new_share < _amount) {
            uint _count = _new_share / _price;
            IERC20(_bitcoin).approve(_router, _count);
            _toSwap = IUniswapV2Router02(_router).swapTokensForExactTokens(_new_share, _count, path, msg.sender, block.timestamp)[0];
            _bankFund -= _toSwap;
            _countOffsetBids.increment();
            c_sender._bids[number]._referrals = 0;
            emit Offset(msg.sender, number, _new_share, _price);
        } else {
            uint _count = _amount / _price;
            IERC20(_bitcoin).approve(_router, _count);
            _toSwap = IUniswapV2Router02(_router).swapTokensForExactTokens(_amount, _count, path, msg.sender, block.timestamp)[0];
            _bankFund -= _toSwap;
            _countOffsetBids.increment();
            c_sender._bids[number]._referrals = 0;
            emit Offset(msg.sender, number, _amount, _price);
        }
        locker = false;
    }

    /// @notice Run lottery
    function startLottery() external onlyOwner {
        require(_final == false, "Game finalized");
        uint number = VRFv2Consumer(_vrf).randomNums(0);
        require(_randomNum != number, 'Random number not yet received from oracle');
        _randomNum = number;
        uint count;
        for (uint i = _startLotteryNum + 1; i <= _countContributions.current(); i++) {
            count += _multi[i];
        }
        uint _num = getRandomNum() % count;
        address _winner;
        for (uint i = _startLotteryNum + 1; i <= _countContributions.current(); i++) {
            if (_num <= _multi[i]) {
                _winner = _payments[i];
                break;
            }
        }

        IERC20(_usd).safeTransfer(_winner, _bankLottery);

        emit Lottery(_num, _winner, _bankLottery);
        _bankLottery = 0;
        _startLotteryNum = _countContributions.current();
    }

    /// @notice Contribute
    /// @param multi - Referrals amount - 1
    /// @param recipient - Address of gift recipient
    function giftContribute(uint multi, address recipient) external onlyOwner {
        require(_final == false, "Game finalized");
        require(!locker);
        locker = true;

        _payments[_countContributions.current()] = recipient;
        _multi[_countContributions.current()] = multi + 1;
        _countContributions.increment();

        Contribution storage c_sender = _contributions[recipient];
        Bid storage b_sender = _contributions[recipient]._bids[c_sender._countBids.current()];

        b_sender._referrals = uint128(multi + 1);
        b_sender._referrals_closed = uint128(0);
        b_sender._price = uint128(0);
        b_sender._share_found = uint128(0);
        b_sender._res_price = uint128(0);
        b_sender._gifted = true;

        c_sender._countBids.increment();
        locker = false;

        emit Contributed(
            recipient,
            address(0x0000000000000000000000000000000000000000),
            uint128(0),
            uint128(0),
            uint128(0),
            b_sender._referrals,
            uint128(0),
            uint128(0),
            uint128(0),
            uint128(0)
        );
    }

    /// @notice Finalize project
    function finalize() external onlyOwner {
        require(_final == false, "Already finalized");
        timer = block.timestamp + (_waitingTime * 1 minutes);
        _final = true;
    }
    /// @notice Withdraw balance
    function withdrawAll() external onlyOwner {
        require(_final == true, "Game not yet finalized");
        require(timer < block.timestamp, "Time to withdraw users' funds has not yet expired");
        uint _balanceUsd = IERC20(_usd).balanceOf(address(this));
        IERC20(_usd).safeTransfer(msg.sender, _balanceUsd);
        uint _balanceBtc = IERC20(_bitcoin).balanceOf(address(this));
        IERC20(_bitcoin).safeTransfer(msg.sender, _balanceBtc);
    }
    /// @notice Withdraw Marketing
    function withdrawMarketing() external onlyOwner {
        require(_bankMarketing > 0, "bank empty");
        IERC20(_usd).safeTransfer(msg.sender, _bankMarketing);
        _bankMarketing = 0;
    }
    /// @notice Withdraw Owner
    function withdrawOwner() external onlyOwner {
        require(_bankOwner > 0, "bank empty");
        IERC20(_usd).safeTransfer(msg.sender, _bankOwner);
        _bankOwner = 0;
    }
    /// @notice Withdraw Lottery
    function withdrawLottery() external onlyOwner {
        require(_final == true, "Game finalized");
        require(_bankLottery > 0, "bank empty");
        IERC20(_usd).safeTransfer(msg.sender, _bankLottery);
        _bankLottery = 0;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

/// Imports
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

/// @title Contract for generating random numbers
contract VRFv2Consumer is VRFConsumerBaseV2 {

    /// Variables
    VRFCoordinatorV2Interface COORDINATOR;

    uint64 _s_subscriptionId;       // Your subscription ID (issued on the chanlink website, and you need to approve the address of this contract on the site).
    address _vrfCoordinator;        // see https://docs.chain.link/docs/vrf-contracts/#configurations
    bytes32 _keyHash;               // see https://docs.chain.link/docs/vrf-contracts/#configurations
    uint32 _callbackGasLimit;       // Storing each word costs about 20,000 gas, so 100,000 is a safe default for this example contract
    uint16 _requestConfirmations;   // The default is 3, but you can set this higher.
    uint32 _numWords;               // Count random values in one request.
    uint256[] public randomNums;    // Array to store generated numbers
    uint256 public s_requestId;     // requestId - Variable for internal work
    address _owner;                 // Variable to store owner address

    /// Constructor
    constructor(uint64 subscriptionId, address vrfCoordinator, bytes32 keyHash, uint32 callbackGasLimit, uint16 requestConfirmations, uint32 numWords) VRFConsumerBaseV2(vrfCoordinator) {
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        _owner = msg.sender;
        _s_subscriptionId = subscriptionId;
        _vrfCoordinator = vrfCoordinator;
        _keyHash = keyHash;
        _callbackGasLimit = callbackGasLimit;
        _requestConfirmations = requestConfirmations;
        _numWords = numWords;
    }

    /// @notice Getting owner address
    function getOwner() external view returns(address){
        return _owner;
    }
    /// @notice Chainge owner address
    /// @param owner - new owner address
    function setOwner(address owner) external onlyOwner{
        _owner = owner;
    }

    /// @notice Request for getting new random numbers
    /// to update the data, you need to wait about 2-3 minutes after the completion of the transaction
    function requestRandomWords() external onlyOwner {
        // Will revert if subscription is not set and funded.
        s_requestId = COORDINATOR.requestRandomWords(
            _keyHash,
            _s_subscriptionId,
            _requestConfirmations,
            _callbackGasLimit,
            _numWords
        );
    }

    /// Function for internal work
    function fulfillRandomWords(
        uint256, /* requestId */
        uint256[] memory randomWords
    ) internal override {
        randomNums = randomWords;
    }

    /// Modifier to prohibit the launch of functions for everyone except the owner
    modifier onlyOwner() {
        require(msg.sender == _owner);
        _;
    }
}

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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface VRFCoordinatorV2Interface {
  /**
   * @notice Get configuration relevant for making requests
   * @return minimumRequestConfirmations global min for request confirmations
   * @return maxGasLimit global max for request gas limit
   * @return s_provingKeyHashes list of registered key hashes
   */
  function getRequestConfig()
    external
    view
    returns (
      uint16,
      uint32,
      bytes32[] memory
    );

  /**
   * @notice Request a set of random words.
   * @param keyHash - Corresponds to a particular oracle job which uses
   * that key for generating the VRF proof. Different keyHash's have different gas price
   * ceilings, so you can select a specific one to bound your maximum per request cost.
   * @param subId  - The ID of the VRF subscription. Must be funded
   * with the minimum subscription balance required for the selected keyHash.
   * @param minimumRequestConfirmations - How many blocks you'd like the
   * oracle to wait before responding to the request. See SECURITY CONSIDERATIONS
   * for why you may want to request more. The acceptable range is
   * [minimumRequestBlockConfirmations, 200].
   * @param callbackGasLimit - How much gas you'd like to receive in your
   * fulfillRandomWords callback. Note that gasleft() inside fulfillRandomWords
   * may be slightly less than this amount because of gas used calling the function
   * (argument decoding etc.), so you may need to request slightly more than you expect
   * to have inside fulfillRandomWords. The acceptable range is
   * [0, maxGasLimit]
   * @param numWords - The number of uint256 random values you'd like to receive
   * in your fulfillRandomWords callback. Note these numbers are expanded in a
   * secure way by the VRFCoordinator from a single random value supplied by the oracle.
   * @return requestId - A unique identifier of the request. Can be used to match
   * a request to a response in fulfillRandomWords.
   */
  function requestRandomWords(
    bytes32 keyHash,
    uint64 subId,
    uint16 minimumRequestConfirmations,
    uint32 callbackGasLimit,
    uint32 numWords
  ) external returns (uint256 requestId);

  /**
   * @notice Create a VRF subscription.
   * @return subId - A unique subscription id.
   * @dev You can manage the consumer set dynamically with addConsumer/removeConsumer.
   * @dev Note to fund the subscription, use transferAndCall. For example
   * @dev  LINKTOKEN.transferAndCall(
   * @dev    address(COORDINATOR),
   * @dev    amount,
   * @dev    abi.encode(subId));
   */
  function createSubscription() external returns (uint64 subId);

  /**
   * @notice Get a VRF subscription.
   * @param subId - ID of the subscription
   * @return balance - LINK balance of the subscription in juels.
   * @return reqCount - number of requests for this subscription, determines fee tier.
   * @return owner - owner of the subscription.
   * @return consumers - list of consumer address which are able to use this subscription.
   */
  function getSubscription(uint64 subId)
    external
    view
    returns (
      uint96 balance,
      uint64 reqCount,
      address owner,
      address[] memory consumers
    );

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @param newOwner - proposed new owner of the subscription
   */
  function requestSubscriptionOwnerTransfer(uint64 subId, address newOwner) external;

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @dev will revert if original owner of subId has
   * not requested that msg.sender become the new owner.
   */
  function acceptSubscriptionOwnerTransfer(uint64 subId) external;

  /**
   * @notice Add a consumer to a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - New consumer which can use the subscription
   */
  function addConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Remove a consumer from a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - Consumer to remove from the subscription
   */
  function removeConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Cancel a subscription
   * @param subId - ID of the subscription
   * @param to - Where to send the remaining LINK to
   */
  function cancelSubscription(uint64 subId, address to) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/** ****************************************************************************
 * @notice Interface for contracts using VRF randomness
 * *****************************************************************************
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * @dev to Vera the verifier in such a way that Vera can be sure he's not
 * @dev making his output up to suit himself. Reggie provides Vera a public key
 * @dev to which he knows the secret key. Each time Vera provides a seed to
 * @dev Reggie, he gives back a value which is computed completely
 * @dev deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * @dev correctly computed once Reggie tells it to her, but without that proof,
 * @dev the output is indistinguishable to her from a uniform random sample
 * @dev from the output space.
 *
 * @dev The purpose of this contract is to make it easy for unrelated contracts
 * @dev to talk to Vera the verifier about the work Reggie is doing, to provide
 * @dev simple access to a verifiable source of randomness. It ensures 2 things:
 * @dev 1. The fulfillment came from the VRFCoordinator
 * @dev 2. The consumer contract implements fulfillRandomWords.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constructor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash). Create subscription, fund it
 * @dev and your consumer contract as a consumer of it (see VRFCoordinatorInterface
 * @dev subscription management functions).
 * @dev Call requestRandomWords(keyHash, subId, minimumRequestConfirmations,
 * @dev callbackGasLimit, numWords),
 * @dev see (VRFCoordinatorInterface for a description of the arguments).
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomWords method.
 *
 * @dev The randomness argument to fulfillRandomWords is a set of random words
 * @dev generated from your requestId and the blockHash of the request.
 *
 * @dev If your contract could have concurrent requests open, you can use the
 * @dev requestId returned from requestRandomWords to track which response is associated
 * @dev with which randomness request.
 * @dev See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ.
 *
 * *****************************************************************************
 * @dev SECURITY CONSIDERATIONS
 *
 * @dev A method with the ability to call your fulfillRandomness method directly
 * @dev could spoof a VRF response with any random value, so it's critical that
 * @dev it cannot be directly called by anything other than this base contract
 * @dev (specifically, by the VRFConsumerBase.rawFulfillRandomness method).
 *
 * @dev For your users to trust that your contract's random behavior is free
 * @dev from malicious interference, it's best if you can write it so that all
 * @dev behaviors implied by a VRF response are executed *during* your
 * @dev fulfillRandomness method. If your contract must store the response (or
 * @dev anything derived from it) and use it later, you must ensure that any
 * @dev user-significant behavior which depends on that stored value cannot be
 * @dev manipulated by a subsequent VRF request.
 *
 * @dev Similarly, both miners and the VRF oracle itself have some influence
 * @dev over the order in which VRF responses appear on the blockchain, so if
 * @dev your contract could have multiple VRF requests in flight simultaneously,
 * @dev you must ensure that the order in which the VRF responses arrive cannot
 * @dev be used to manipulate your contract's user-significant behavior.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request. It is for this reason that
 * @dev that you can signal to an oracle you'd like them to wait longer before
 * @dev responding to the request (however this is not enforced in the contract
 * @dev and so remains effective only in the case of unmodified oracle software).
 */
abstract contract VRFConsumerBaseV2 {
  error OnlyCoordinatorCanFulfill(address have, address want);
  address private immutable vrfCoordinator;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   */
  constructor(address _vrfCoordinator) {
    vrfCoordinator = _vrfCoordinator;
  }

  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBaseV2 expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomWords the VRF output expanded to the requested number of words
   */
  function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal virtual;

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomWords(uint256 requestId, uint256[] memory randomWords) external {
    if (msg.sender != vrfCoordinator) {
      revert OnlyCoordinatorCanFulfill(msg.sender, vrfCoordinator);
    }
    fulfillRandomWords(requestId, randomWords);
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}