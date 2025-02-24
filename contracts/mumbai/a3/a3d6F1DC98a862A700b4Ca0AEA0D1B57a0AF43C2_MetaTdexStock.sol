// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0 <0.9.0;

import "./TokenConfig.sol";

abstract contract ERC20 {

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     */
    function decimals() public view virtual returns (uint8) {
        return _decimals;
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
    function transferFrom(
        address sender,
        address recipient,
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

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a >= b) return a;
        return b;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        require(a >=0 && b>=0, "SafeMath: Cannot have negative numbers");
        if (a <= b) return a;
        return b;
    }
}

library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value : value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

struct Dish {
    uint256 price;
    uint256 number;
}

enum OrderType { Buy, Sell }
enum OrderStatus { None, Waiting, Finished, Cancelled }

struct Order {
    uint256 orderId;
    uint256 price;
    uint256 tokenTotal;
    uint256 tokenDone;
    uint256 usdtDone;
    uint256 tokenFee;
    uint256 usdtFee;
    uint256 tokenSurplus;
    uint256 usdtSurplus;
    uint256 createnTime;
    uint256 endTime;
    OrderType orderType;
    OrderStatus status;
    address sender;
}

struct Match {
    uint256 matchId;
    uint256 buyOrderId;
    uint256 sellOrderId;
    uint256 price;
    uint256 tokenDeal;
    uint256 usdtDeal;
    uint256 tokenFee;
    uint256 usdtFee;
}

interface OrderInterface {

    function getOrder(address _tokenContract, uint256 _orderId) external view returns (Order memory);

    function getPrice(address _tokenContract) external view returns (uint256 price);

    function getLastOrderId(address _tokenContract) external view returns (uint256 orderId);

    function getBuyOrderPriceListLength(address _tokenContract) external view returns (uint);

    function getBuyOrderPriceList(address _tokenContract, uint256 start, uint256 end) external view returns (uint256[] memory);

    function getBuyOrderPriceOrderIdList(address _tokenContract, uint256 _price) external view returns (uint256[] memory);

    function getSellOrderPriceListLength(address _tokenContract) external view returns (uint);

    function getSellOrderPriceList(address _tokenContract, uint256 start, uint256 end) external view returns (uint256[] memory);

    function getSellOrderPriceOrderIdList(address _tokenContract, uint256 _price) external view returns (uint256[] memory);

    function getOrderUnmatchedListLength(address _tokenContract, address _sender) external view returns (uint);

    function getOrderFinishedListLength(address _tokenContract, address _sender) external view returns (uint);

    function getOrderUnmatchedList(address _tokenContract, address _sender, uint256 start, uint256 end) external view returns (uint256[] memory);

    function getOrderFinishedList(address _tokenContract, address _sender, uint256 start, uint256 end) external view returns (uint256[] memory);
}

interface DexInterface {

    function createOrder(address _tokenContract, address _sender, uint256 _price, uint256 _token, uint256 _usdt, uint8 _type) external returns (uint256);

    function removeOrder(address _tokenContract, uint256 _orderId, address _sender) external returns (bool);

    function orderManager() external view returns (address);

    function books() external view returns (address);
}

interface TokenInterface {

    function getToken(address _tokenContract) external view returns (Token memory token);

    function getTokenMapLength() external view returns (uint length);

    function getTokenAddressList(uint256 start, uint256 end) external view returns (address[] memory list);
}

interface __tdexDelegate {

    function __buy(address __tokenContract, address __sender) external;

    function __sell(address __tokenContract, address __sender) external;

    function __cancel(address __tokenContract, address __sender) external;
}


contract MetaTdexStock {

    address private _owner;

    address private _dexInterface = address(0);

    address private _tokenManager = address(0);

    address private _delegate = address(0);

    Token private USDT;

    Token private ETH;

    event Create(address indexed tokenContract, address indexed sender, uint256 indexed orderId, OrderType orderType, uint256 price, uint256 tokenTotal, uint256 tokenDone, uint256 usdtDone, uint256 tokenFee, uint256 usdtFee, uint256 tokenSurplus, uint256 usdtSurplus, uint256 createnTime, uint256 endTime, OrderStatus status);

    event Update(address indexed tokenContract, address indexed sender, uint256 indexed orderId, OrderType orderType, uint256 price, uint256 tokenTotal, uint256 tokenDone, uint256 usdtDone, uint256 tokenFee, uint256 usdtFee, uint256 tokenSurplus, uint256 usdtSurplus, uint256 createnTime, uint256 endTime, OrderStatus status);

    event Matching(address indexed tokenContract, uint256 indexed matchId, uint256 buyOrderId, uint256 sellOrderId, uint256 price, uint256 tokenDeal, uint256 tokenFee, uint256 usdtDeal, uint256 usdtFee);

    constructor () {
        _owner = msg.sender;
        USDT = T.USDT();
        ETH = T.ETH();
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    modifier onlyDexInterface() {
        require(_dexInterface == msg.sender, "Dex: caller has no permissions");
        _;
    }

    function init(address __dexInterface) external onlyOwner
    {
        require(_dexInterface == address(0), "Can only be assigned once");
        _dexInterface = __dexInterface;
    }

    function setTokenManager(address ___tokenManager) external onlyOwner
    {
        _tokenManager = ___tokenManager;
    }

    function setDelegate(address __delegate) external onlyOwner
    {
        _delegate = __delegate;
    }

    function getToken(address _tokenContract) external view returns (
        address tokenContract,
        string memory symbol,
        string memory name,
        uint decimals)
    {
        Token memory token = TokenInterface(_tokenManager).getToken(_tokenContract);

        tokenContract = token.tokenContract;
        symbol = token.symbol;
        name = token.name;
        decimals = token.decimals;
    }

    function getTokenAddressListLength() external view returns (uint length)
    {
        return TokenInterface(_tokenManager).getTokenMapLength();
    }

    function getTokenAddressList(uint256 start, uint256 end) external view returns (address[] memory list)
    {
        return TokenInterface(_tokenManager).getTokenAddressList(start, end);
    }

    /**********************************************************/

    function _buy(address _tokenContract, uint256 _price, uint256 _token_amount, address _sender) internal returns (uint256)
    {
        if (_delegate != address(0)) __tdexDelegate(_delegate).__buy(_tokenContract, _sender);

        require(_token_amount > 0, "The quantity cannot be 0");

        Token memory token = TokenInterface(_tokenManager).getToken(_tokenContract);
        require(token.tokenContract != address(0), "This contract address is not supported");
        require(_price > 0, "No, no price");

        uint256 _usdt_amount = SafeMath.div(SafeMath.mul(_token_amount, _price), PDEC);

        require(_usdt_amount <= 1e6 * 10 ** USDT.decimals, "Maximum single transaction amount 1000000 USDT");

        TransferHelper.safeTransferFrom(USDT.tokenContract, _sender, _dexInterface, _usdt_amount);

        return DexInterface(_dexInterface).createOrder(_tokenContract, _sender, _price, _token_amount, _usdt_amount, 0);
    }

    function Buy(address _tokenContract, uint256 _price, uint256 _token_amount) external returns (uint256 orderId)
    {
        require(_tokenContract != ETH.tokenContract, "Does not support ETH");
        return _buy(_tokenContract, _price, _token_amount, msg.sender);
    }

    function _sell(address _tokenContract, uint256 _price, uint256 _token_amount, address _sender) internal returns (uint256)
    {
        if (_delegate != address(0)) __tdexDelegate(_delegate).__sell(_tokenContract, _sender);

        require(_token_amount > 0, "The quantity cannot be 0");

        Token memory token = TokenInterface(_tokenManager).getToken(_tokenContract);
        require(token.tokenContract != address(0), "This contract address is not supported");
        require(_price > 0, "No, no price");

        uint256 _usdt_amount = SafeMath.div(SafeMath.mul(_token_amount, _price), PDEC);
        require(_usdt_amount <= 1e6 * 10 ** USDT.decimals, "Maximum single transaction amount 1000000 USDT");

        if (_tokenContract == ETH.tokenContract)
        {
            TransferHelper.safeTransferETH(_dexInterface, _token_amount);
        }
        else
        {
            TransferHelper.safeTransferFrom(_tokenContract, _sender, _dexInterface, _token_amount);
        }

        return DexInterface(_dexInterface).createOrder(_tokenContract, _sender, _price, _token_amount, _usdt_amount, 1);
    }

    function Sell(address _tokenContract, uint256 _price, uint256 _token_amount) external returns (uint256 orderId)
    {
        require(_tokenContract != ETH.tokenContract, "Does not support ETH");
        return _sell(_tokenContract, _price, _token_amount, msg.sender);
    }

    function Cancel(address _tokenContract, uint256 _orderId) external returns (bool)
    {
        Token memory token = TokenInterface(_tokenManager).getToken(_tokenContract);
        require(token.tokenContract != address(0), "This contract address is not supported");

        return DexInterface(_dexInterface).removeOrder(_tokenContract, _orderId, msg.sender);
    }

    function CancelRoot(address _tokenContract, uint256 _orderId, address _sender) external onlyOwner returns (bool)
    {
        Token memory token = TokenInterface(_tokenManager).getToken(_tokenContract);
        require(token.tokenContract != address(0), "This contract address is not supported");

        return DexInterface(_dexInterface).removeOrder(_tokenContract, _orderId, _sender);
    }

    function __create(address tokenContract, Order memory order) external onlyDexInterface
    {
        emit Create(tokenContract, order.sender, order.orderId, order.orderType, order.price, order.tokenTotal, order.tokenDone, order.usdtDone, order.tokenFee, order.usdtFee, order.tokenSurplus, order.usdtSurplus, order.createnTime, order.endTime, order.status);
    }

    function __update(address tokenContract, Order memory order) external onlyDexInterface
    {
        emit Update(tokenContract, order.sender, order.orderId, order.orderType, order.price, order.tokenTotal, order.tokenDone, order.usdtDone, order.tokenFee, order.usdtFee, order.tokenSurplus, order.usdtSurplus, order.createnTime, order.endTime, order.status);
    }

    function __matching(address tokenContract, Match memory newMatch) external onlyDexInterface
    {
        emit Matching(tokenContract, newMatch.matchId, newMatch.buyOrderId, newMatch.sellOrderId, newMatch.price, newMatch.tokenDeal, newMatch.tokenFee, newMatch.usdtDeal, newMatch.usdtFee);
    }

    /**********************************************************/

    function balanceOf(address _tokenContract, address _sender) external view returns (uint256)
    {
        uint256 balance;
        if (_tokenContract == ETH.tokenContract)
        {
            balance = _sender.balance;
        }
        else
        {
            balance = IERC20(_tokenContract).balanceOf(_sender);
        }
        return balance;
    }

    function getOrderManager() internal view returns (OrderInterface)
    {
        return OrderInterface(DexInterface(_dexInterface).orderManager());
    }

    function getPrice(address _tokenContract) external view returns (uint256 price)
    {
        return getOrderManager().getPrice(_tokenContract);
    }

    function getLastOrderId(address _tokenContract) external view returns (uint256 orderId)
    {
        return getOrderManager().getLastOrderId(_tokenContract);
    }

    function getOrder(address _tokenContract, uint256 _orderId) external view returns (Order memory)
    {
        return getOrderManager().getOrder(_tokenContract, _orderId);
    }

    function getBuyOrderPriceListLength(address _tokenContract) external view returns (uint length)
    {
        return getOrderManager().getBuyOrderPriceListLength(_tokenContract);
    }

    function getBuyOrderPriceList(address _tokenContract, uint256 start, uint256 end) external view returns (uint256[] memory list)
    {
        return getOrderManager().getBuyOrderPriceList(_tokenContract, start, end);
    }

    function getBuyOrderPriceOrderIdList(address _tokenContract, uint256 _price) external view returns (uint256[] memory list)
    {
        return getOrderManager().getBuyOrderPriceOrderIdList(_tokenContract, _price);
    }

    function getSellOrderPriceListLength(address _tokenContract) external view returns (uint length)
    {
        return getOrderManager().getSellOrderPriceListLength(_tokenContract);
    }

    function getSellOrderPriceList(address _tokenContract, uint256 start, uint256 end) external view returns (uint256[] memory list)
    {
        return getOrderManager().getSellOrderPriceList(_tokenContract, start, end);
    }

    function getSellOrderPriceOrderIdList(address _tokenContract, uint256 _price) external view returns (uint256[] memory list)
    {
        return getOrderManager().getSellOrderPriceOrderIdList(_tokenContract, _price);
    }

    function getOrderUnmatchedListLength(address _tokenContract, address _sender) external view returns (uint length)
    {
        return getOrderManager().getOrderUnmatchedListLength(_tokenContract, _sender);
    }

    function getOrderFinishedListLength(address _tokenContract, address _sender) external view returns (uint length)
    {
        return getOrderManager().getOrderFinishedListLength(_tokenContract, _sender);
    }

    function getOrderUnmatchedList(address _tokenContract, address _sender, uint256 start, uint256 end) external view returns (uint256[] memory list)
    {
        return getOrderManager().getOrderUnmatchedList(_tokenContract, _sender, start, end);
    }

    function getOrderFinishedList(address _tokenContract, address _sender, uint256 start, uint256 end) external view returns (uint256[] memory list)
    {
        return getOrderManager().getOrderFinishedList(_tokenContract, _sender, start, end);
    }
}