// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "../token/IERC20.sol";
import "./Address.sol";

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

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) - value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

library SafeMath {

    uint256 constant UMAX = 2 ** 255 - 1;
    int256  constant IMIN = -2 ** 255;

    function utoi(uint256 a) internal pure returns (int256) {
        require(a <= UMAX, 'SafeMath.utoi: overflow');
        return int256(a);
    }

    function itou(int256 a) internal pure returns (uint256) {
        require(a >= 0, 'SafeMath.itou: underflow');
        return uint256(a);
    }

    function abs(int256 a) internal pure returns (int256) {
        require(a != IMIN, 'SafeMath.abs: overflow');
        return a >= 0 ? a : -a;
    }

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function max(int256 a, int256 b) internal pure returns (int256) {
        return a >= b ? a : b;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a <= b ? a : b;
    }

    function min(int256 a, int256 b) internal pure returns (int256) {
        return a <= b ? a : b;
    }

     // rescale a uint256 from base 10**decimals1 to 10**decimals2
    function rescale(uint256 a, uint256 decimals1, uint256 decimals2) internal pure returns (uint256) {
        return decimals1 == decimals2 ? a : a * 10**decimals2 / 10**decimals1;
    }

    // rescale towards zero
    // b: rescaled value in decimals2
    // c: the remainder
    function rescaleDown(uint256 a, uint256 decimals1, uint256 decimals2) internal pure returns (uint256 b, uint256 c) {
        b = rescale(a, decimals1, decimals2);
        c = a - rescale(b, decimals2, decimals1);
    }

    // rescale towards infinity
    // b: rescaled value in decimals2
    // c: the excessive
    function rescaleUp(uint256 a, uint256 decimals1, uint256 decimals2) internal pure returns (uint256 b, uint256 c) {
        b = rescale(a, decimals1, decimals2);
        uint256 d = rescale(b, decimals2, decimals1);
        if (d != a) {
            b += 1;
            c = rescale(b, decimals2, decimals1) - a;
        }
    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;
import '../utils/Admin.sol';
import '../library/SafeMath.sol';
import '../library/SafeERC20.sol';
import '../pool/IPool.sol';
import '../token/IWETH.sol';
import "hardhat/console.sol";

contract Router is Admin {
    
    bool internal _mutex;
    modifier _reentryLock_() {
        require(!_mutex, 'Router: reentry');
        _mutex = true;
        _;
        _mutex = false;
    }

    using SafeMath for uint256;
    using SafeMath for int256;
    using SafeERC20 for IERC20;


    address public weth;
    address public pool;
    address public alp;

    constructor(address _pool, address _weth, address _alp) public {
        pool = _pool;
        weth = _weth;
        alp = _alp;
    }


    function addLiquidity(address token, uint256 amount, uint256 minLp, IPool.OracleSignature[] memory oracleSignatures) external payable _reentryLock_ {
        require(amount > 0, "Router.addLiquidity: invalid amount");
        address underlying;
        uint256 addAmount;
        if(token != address(0)) {
            underlying = token;
            IERC20(underlying).safeTransferFrom(msg.sender, address(this), amount);
        } else {
            underlying = weth;
            IWETH(underlying).deposit{value: msg.value}();
            require(amount == msg.value, "Router.addLiquidity: msg.value");
        }

        IERC20(underlying).approve(pool, amount);
            //address underlying, uint256 amount, uint256 minLp, address to, OracleSignature[] memory oracleSignatures
       uint256 amountOut = IPool(pool).addLiquidity(underlying, amount, oracleSignatures);
       require(amountOut >= minLp, "Router.addLiquidity: invalid amount out");
       IERC20(alp).safeTransfer(msg.sender, amountOut);
    }

    function removeLiquidity(address token, uint256 amount, uint256 minOut, IPool.OracleSignature[] memory oracleSignatures) external _reentryLock_{
        require(amount > 0, "RewardRouter: invalid _alpAmount");

        address account = msg.sender;
        IERC20(alp).safeTransferFrom(account, address(this), amount);
        IERC20(alp).approve(pool, amount);
        if(token != address(0)) {
            uint256 amountOut = IPool(pool).removeLiquidity(token, amount, oracleSignatures);
            require(amountOut >= minOut, "Router.removeLiquidity: invalid amount out");
            IERC20(token).safeTransfer(account, amountOut);
        } else {
            uint256 amountOut = IPool(pool).removeLiquidity(weth, amount, oracleSignatures);
            require(amountOut >= minOut, "Router.removeLiquidity: invalid amount out");
            IWETH(weth).withdraw(amountOut);
            (bool success, ) = payable(account).call{value: amountOut}('');
            require(success, 'PoolImplementation.transfer: send ETH fail');
        }
    }
    // function addMargin(address account, address underlying, string memory symbolName, uint256 amount, OracleSignature[] memory oracleSignatures) external  _reentryLock_
    function addMargin(address token, uint256 amount, string memory symbolName, IPool.OracleSignature[] memory oracleSignatures) external payable _reentryLock_ {
        require(amount > 0, "Router.addLiquidity: invalid amount");
        address underlying;
        uint256 addAmount;
        if(token != address(0)) {
            underlying = token;
            IERC20(underlying).safeTransferFrom(msg.sender, address(this), amount);
        } else {
            underlying = weth;
            IWETH(underlying).deposit{value: msg.value}();
            require(amount == msg.value, "Router.addLiquidity: msg.value");
        }

        IERC20(underlying).approve(pool, amount);
            //address underlying, uint256 amount, uint256 minLp, address to, OracleSignature[] memory oracleSignatures
        IPool(pool).addMargin(msg.sender, underlying, symbolName, amount, oracleSignatures);
    }

    function removeMargin(address token, uint256 amount, string memory symbolName, IPool.OracleSignature[] memory oracleSignatures) external _reentryLock_{
        require(amount > 0, "RewardRouter: invalid _alpAmount");


        address account = msg.sender;
        if(token != address(0)) {
            IPool(pool).removeMargin(account, token, symbolName, amount, oracleSignatures);
            IERC20(token).safeTransfer(account, amount);
        } else {
            IPool(pool).removeMargin(account, weth, symbolName, amount, oracleSignatures);
            IWETH(weth).withdraw(amount);
            (bool success, ) = payable(account).call{value: amount}('');
            require(success, 'PoolImplementation.transfer: send ETH fail');
        }
    }

    function transfer(address token, uint256 amount, string memory fromSymbolName, string memory toSymbolName, IPool.OracleSignature[] memory oracleSignatures) external payable _reentryLock_{
        require(amount > 0, "Router.transfer: invalid amount");
        address account = msg.sender;
        if(token != address(0)) {
            IPool(pool).removeMargin(account, token, fromSymbolName, amount, oracleSignatures);
            IERC20(token).safeTransfer(account, amount);

            IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
            IERC20(token).approve(pool, amount);
            IPool(pool).addMargin(msg.sender, token, toSymbolName, amount, oracleSignatures);
        } else {
            IPool(pool).removeMargin(account, weth, fromSymbolName, amount, oracleSignatures);
            IWETH(weth).withdraw(amount);
            (bool success, ) = payable(account).call{value: amount}('');
            require(success, 'PoolImplementation.transfer: send ETH fail');

            IWETH(weth).deposit{value: msg.value}();
            require(amount == msg.value, "Router.transfer: msg.value");
            IERC20(weth).approve(pool, amount);
            IPool(pool).addMargin(msg.sender, weth, toSymbolName, amount, oracleSignatures);
        }
    }

    receive() external payable {
        require(msg.sender == weth, "Router: invalid sender");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import '../utils/INameVersion.sol';
import '../utils/IAdmin.sol';

interface IOracleManager is INameVersion, IAdmin {

    event NewOracle(bytes32 indexed symbolId, address indexed oracle);

    event NewTokenOracle(address indexed token, address indexed oracle);

    // function getOracle(bytes32 symbolId) external view returns (address);

    function getOracle(string memory symbol) external view returns (address);

    function setOracle(address oracleAddress) external;

    function delOracle(bytes32 symbolId) external;

    function delOracle(string memory symbol) external;

    function value(bytes32 symbolId) external view returns (uint256);

    function getValue(bytes32 symbolId) external view returns (uint256);

    function updateValue(
        bytes32 symbolId,
        uint256 timestamp_,
        uint256 value_,
        uint8   v_,
        bytes32 r_,
        bytes32 s_
    ) external returns (bool);

    function getTokenPrice(address token) external view returns (uint256);
    function setTokenOracle(address token, address oracleAddress) external;
    function delTokenOracle(address token) external;

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "../library/SafeMath.sol";
import "../token/IERC20.sol";
import "../library/SafeERC20.sol";
import "../symbol/ISymbolManager.sol";
import "../symbol/ISymbol.sol";
import "../pool/IPool.sol";

// import "../libraries/utils/ReentrancyGuard.sol";

// import "./interfaces/IRouter.sol";
// import "./interfaces/IVault.sol";
// import "./interfaces/IOrderBook.sol";

contract OrderBook {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    // using Address for address payable;

    bool internal _mutex;

    modifier _reentryLock_() {
        require(!_mutex, 'Pool: reentry');
        _mutex = true;
        _;
        _mutex = false;
    }

    uint256 public constant PRICE_PRECISION = 1e18;
    uint256 public constant USDA_PRECISION = 1e18;

    //string memory symbolName,
    // int256 tradeVolume,
    // uint256 _triggerPrice,
    // bool _triggerAboveThreshold
    struct TradeOrder {
        address account;
        string symbolName;
        int256 tradeVolume;
        uint256 triggerPrice;
        bool triggerAboveThreshold;
        uint256 executionFee;
    }

    event CreateTradeOrder(
        address indexed account,
        uint256 orderIndex,
        string symbolName,
        int256 tradeVolume,
        uint256 triggerPrice,
        bool triggerAboveThreshold,
        uint256 executionFee
    );

    event UpdateTradeOrder(
        address indexed account,
        uint256 orderIndex,
        string symbolName,
        int256 tradeVolume,
        uint256 triggerPrice,
        bool triggerAboveThreshold
    );

    event CancelTradeOrder(
        address indexed account,
        uint256 orderIndex,
        string symbolName,
        int256 tradeVolume,
        uint256 triggerPrice,
        bool triggerAboveThreshold,
        uint256 executionFee
    );

    event ExecuteTradeOrder(
        address indexed account,
        uint256 orderIndex,
        string symbolName,
        int256 tradeVolume,
        uint256 triggerPrice,
        bool triggerAboveThreshold,
        uint256 executionFee,
        uint256 curentPrice
    );




    mapping (address => mapping(uint256 => TradeOrder)) public tradeOrders;
    mapping (address => uint256) public tradeOrdersIndex;

    address public gov;
    address public pool;
    address public symbolManager;
    uint256 public minExecutionFee;


    event UpdateMinExecutionFee(uint256 minExecutionFee);
    event UpdateGov(address gov);

    modifier onlyGov() {
        require(msg.sender == gov, "OrderBook: forbidden");
        _;
    }

    constructor(
        address _pool,
        address _symbolManager,
        uint256 _minExecutionFee
    ) {
        gov = msg.sender;
        minExecutionFee = _minExecutionFee;
        symbolManager = _symbolManager;
        pool = _pool;
    }

    // receive() external payable {
    //     require(msg.sender == weth, "OrderBook: invalid sender");
    // }
    

    function setMinExecutionFee(uint256 _minExecutionFee) external onlyGov {
        minExecutionFee = _minExecutionFee;

        emit UpdateMinExecutionFee(_minExecutionFee);
    }

    function setGov(address _gov) external onlyGov {
        gov = _gov;

        emit UpdateGov(_gov);
    }

    function cancelMultiple(
        uint256[] memory _tradeOrderIndexes
    ) external {
        for (uint256 i = 0; i < _tradeOrderIndexes.length; i++) {
            cancelTradeOrder(_tradeOrderIndexes[i]);
        }
    }
    
    function validatePositionOrderPrice(
        string memory symbol,
        int256 tradeVolume,
        uint256 _triggerPrice,
        bool _triggerAboveThreshold,
        bool _raise
    ) public view returns (uint256, bool) {
        uint256 UMAX = 2 ** 255 - 1;
        if(_triggerAboveThreshold) {
            return (0, true);
        }
        return (UMAX, true);
        
        // uint256 currentPrice = IVault(vault).getMarketPrice(_indexToken, _sizeDelta, _maximizePrice);
        // bool isPriceValid = _triggerAboveThreshold ? currentPrice > _triggerPrice : currentPrice < _triggerPrice;
        // if (_raise) {
        //     require(isPriceValid, "OrderBook: invalid price for execution");
        // }
        // return (currentPrice, isPriceValid);
    }

    function createTradeOrder(
        string memory _symbolName,
        int256 _tradeVolume,
        uint256 _triggerPrice,
        bool _triggerAboveThreshold
    ) external payable _reentryLock_ {
        // always need this call because of mandatory executionFee user has to transfer in ETH
        // msg.value is execution fee
        require(msg.value >= minExecutionFee, "OrderBook: insufficient execution fee");
        bytes32 symbolId = keccak256(abi.encodePacked(_symbolName));
        address symbol = ISymbolManager(symbolManager).symbols(symbolId);
        require(symbol != address(0), 'OrderBook.createTradeOrder: invalid trade symbol');
        int256 minTradeVolume = ISymbol(symbol).minTradeVolume();
        require(
            _tradeVolume != 0 && _tradeVolume % minTradeVolume == 0,
            'OrderBook.createTradeOrder: invalid tradeVolume'
        );

        _createTradeOrder(
            msg.sender,
            _symbolName,
            _tradeVolume,
            _triggerPrice,
            _triggerAboveThreshold,
            msg.value
        );
    }

    function _createTradeOrder(
        address _account,
        string memory _symbolName,
        int256 _tradeVolume,
        uint256 _triggerPrice,
        bool _triggerAboveThreshold,
        uint256 _executionFee
    ) private {
        uint256 _orderIndex = tradeOrdersIndex[_account];
        TradeOrder memory order = TradeOrder(
            _account,
            _symbolName,
            _tradeVolume,
            _triggerPrice,
            _triggerAboveThreshold,
            _executionFee
        );
        tradeOrdersIndex[_account] = _orderIndex + 1;
        tradeOrders[_account][_orderIndex] = order;

        emit CreateTradeOrder(
            _account,
            _orderIndex,
            _symbolName,
            _tradeVolume,
            _triggerPrice,
            _triggerAboveThreshold,
            _executionFee
        );
    }

    function getTradeOrder(address _account, uint256 _orderIndex) public view returns (
        string memory symbolName,
        int256 tradeVolume,
        uint256 triggerPrice,
        bool triggerAboveThreshold,
        uint256 executionFee
    ) {
        TradeOrder memory order = tradeOrders[_account][_orderIndex];
        return (
            order.symbolName,
            order.tradeVolume,
            order.triggerPrice,
            order.triggerAboveThreshold,
            order.executionFee
        );
    }

    function updateTradeOrder(uint256 _orderIndex, int256 _tradeVolume, uint256 _triggerPrice, bool _triggerAboveThreshold) external  {
        TradeOrder storage order = tradeOrders[msg.sender][_orderIndex];
        require(order.account != address(0), "OrderBook: non-existent order");

        order.triggerPrice = _triggerPrice;
        order.triggerAboveThreshold = _triggerAboveThreshold;
        order.tradeVolume = _tradeVolume;

        emit UpdateTradeOrder(
            msg.sender,
            _orderIndex,
            order.symbolName,
            _tradeVolume,
            _triggerPrice,
            _triggerAboveThreshold
        );
    }


    function cancelTradeOrder(uint256 _orderIndex) public _reentryLock_ {
        TradeOrder memory order = tradeOrders[msg.sender][_orderIndex];
        require(order.account != address(0), "OrderBook: non-existent order");

        delete tradeOrders[msg.sender][_orderIndex];

        // if (order.purchaseToken == weth) {
        //     _transferOutETH(order.executionFee.add(order.purchaseTokenAmount), msg.sender);
        // } else {
            // IERC20(order.purchaseToken).safeTransfer(msg.sender, order.purchaseTokenAmount);
            // _transferOutETH(order.executionFee, msg.sender);
        // }

        _transferOutETH(order.executionFee, payable(msg.sender));

        emit CancelTradeOrder(
            order.account,
            _orderIndex,
            order.symbolName,
            order.tradeVolume,
            order.triggerPrice,
            order.triggerAboveThreshold,
            order.executionFee
        );
    }


    function executeTradeOrder(address _address, uint256 _orderIndex, address payable _feeReceiver) external _reentryLock_ {
        TradeOrder memory order = tradeOrders[_address][_orderIndex];
        require(order.account != address(0), "OrderBook: non-existent order");

        // increase long should use max price
        // increase short should use min price
        (uint256 currentPrice, ) = validatePositionOrderPrice(
            order.symbolName,
            order.tradeVolume,
            order.triggerPrice,
            order.triggerAboveThreshold,
            true
        );

        delete tradeOrders[_address][_orderIndex];
        IPool.OracleSignature[] memory oracleSignatures;
        IPool(pool).trade(order.account, order.symbolName, order.tradeVolume, currentPrice.utoi(), oracleSignatures);

        // IERC20(order.purchaseToken).safeTransfer(vault, order.purchaseTokenAmount);

        // if (order.purchaseToken != order.collateralToken) {
        //     address[] memory path = new address[](2);
        //     path[0] = order.purchaseToken;
        //     path[1] = order.collateralToken;

        //     uint256 amountOut = _swap(path, 0, address(this));
        //     IERC20(order.collateralToken).safeTransfer(vault, amountOut);
        // }

        // IRouter(router).pluginIncreasePosition(order.account, order.collateralToken, order.indexToken, order.sizeDelta, order.isLong);

        // pay executor
        _transferOutETH(order.executionFee, _feeReceiver);

        emit ExecuteTradeOrder(
            order.account,
            _orderIndex,
            order.symbolName,
            order.tradeVolume,
            order.triggerPrice,
            order.triggerAboveThreshold,
            order.executionFee,
            currentPrice
        );
    }

    // function _transferInETH() private {
    //     if (msg.value != 0) {
    //         IWETH(weth).deposit{value: msg.value}();
    //     }
    // }

    function _transferOutETH(uint256 _amountOut, address payable _receiver) private {
        // IWETH(weth).withdraw(_amountOut);

        (bool success, ) = _receiver.call{value: _amountOut}('');
        require(success, 'OrderBook.transfer: send ETH fail');
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import '../utils/INameVersion.sol';
import '../utils/IAdmin.sol';

interface IPool is INameVersion, IAdmin {

    function implementation() external view returns (address);

    function protocolFeeCollector() external view returns (address);

    function liquidity() external view returns (int256);

    function lpsPnl() external view returns (int256);

    function cumulativePnlPerLiquidity() external view returns (int256);

    function protocolFeeAccrued() external view returns (int256);

    function setImplementation(address newImplementation) external;

    function addMarket(address token, address market) external;

    function getMarket(address token) external view returns (address);

    function approveSwapper(address underlying) external;

    function collectProtocolFee() external;

    function claimVenusLp(address account) external;

    function claimVenusTrader(address account) external;

    struct OracleSignature {
        bytes32 oracleSymbolId;
        uint256 timestamp;
        uint256 value;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    function addLiquidity(address underlying, uint256 amount, OracleSignature[] memory oracleSignatures) external returns (uint256);

    function removeLiquidity(address underlying, uint256 amount, OracleSignature[] memory oracleSignatures) external returns (uint256);

    function addMargin(address account, address underlying, string memory symbolName, uint256 amount, OracleSignature[] memory oracleSignatures) external;

    function removeMargin(address account, address underlying, string memory symbolName, uint256 amount, OracleSignature[] memory oracleSignatures) external;

    function trade(address account, string memory symbolName, int256 tradeVolume, int256 priceLimit, OracleSignature[] memory oracleSignatures) external;

    function liquidate(uint256 pTokenId, OracleSignature[] memory oracleSignatures) external;

    function transfer(address account, address underlying, string memory fromSymbolName, string memory toSymbolName, uint256 amount, OracleSignature[] memory oracleSignatures) external;

    function addWhitelistedTokens(address _token) external;
    function removeWhitelistedTokens(address _token) external;
    function allWhitelistedTokens(uint256 index) external view returns (address);
    function allWhitelistedTokensLength() external view returns (uint256);
    function whitelistedTokens(address) external view returns (bool);
    function tokenPriceId(address) external view returns (bytes32);

    function getLiquidity() external view returns (uint256);

    function getTokenPrice(address token) external view returns (uint256);

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import './IPool.sol';
import './PoolStorage.sol';

contract Pool is PoolStorage {

    function setImplementation(address newImplementation) external _onlyAdmin_ {
        require(
            IPool(newImplementation).nameId() == keccak256(abi.encodePacked('PoolImplementation')),
            'Pool.setImplementation: not pool implementations'
        );
        implementation = newImplementation;
        emit NewImplementation(newImplementation);
    }

    function setProtocolFeeCollector(address newProtocolFeeCollector) external _onlyAdmin_ {
        protocolFeeCollector = newProtocolFeeCollector;
        emit NewProtocolFeeCollector(newProtocolFeeCollector);
    }

    fallback() external payable {
        _delegate();
    }

    receive() external payable {

    }

    function _delegate() internal {
        address imp = implementation;
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), imp, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import '../token/IERC20.sol';
import '../token/IDToken.sol';
import '../vault/IVToken.sol';
import '../vault/IVault.sol';
import '../oracle/IOracleManager.sol';
import '../swapper/ISwapper.sol';
import '../symbol/ISymbolManager.sol';
import './PoolStorage.sol';
import '../utils/NameVersion.sol';
import '../library/SafeMath.sol';
import '../library/SafeERC20.sol';
import '../token/IMintableToken.sol';
import '../token/IWETH.sol';

contract PoolImplementation is PoolStorage, NameVersion {

    event CollectProtocolFee(address indexed collector, uint256 amount);

    event AddMarket(address indexed market);

    // event AddLiquidity(
    //     uint256 indexed lTokenId,
    //     address indexed underlying,
    //     uint256 amount,
    //     int256 newLiquidity
    // );

    event AddLiquidity(
        address token,
        uint256 amount,
        int256 liquidity,
        uint256 lpSupply,
        uint256 usdAmount,
        uint256 mintAmount
    );

    event RemoveLiquidity(
        address token,
        uint256 lpAmount,
        int256 liquidity,
        uint256 lpSupply,
        uint256 usdAmount,
        uint256 amountOut
    );

    // event RemoveLiquidity(
    //     uint256 indexed lTokenId,
    //     address indexed underlying,
    //     uint256 amount,
    //     int256 newLiquidity
    // );

    event AddMargin(
        address indexed account,
        string sumbol,
        address indexed underlying,
        uint256 amount,
        int256 newMargin
    );

    event RemoveMargin(
        address indexed account,
        string sumbol,
        address indexed underlying,
        uint256 amount,
        int256 newMargin
    );

    using SafeMath for uint256;
    using SafeMath for int256;
    using SafeERC20 for IERC20;

    int256 constant ONE = 1e18;
    uint256 constant UONE = 1e18;
    uint256 constant UMAX = type(uint256).max / UONE;

    address public immutable vaultTemplate;

    address public immutable vaultImplementation;

    address public immutable tokenB0;

    address public immutable tokenWETH;

    // address public immutable vTokenB0;

    // address public immutable vTokenETH;

    // IDToken public immutable lToken;

    // IDToken public immutable pToken;

    IOracleManager public immutable oracleManager;

    ISwapper public immutable swapper;

    ISymbolManager public immutable symbolManager;

    uint256 public immutable reserveRatioB0;

    int256 public immutable minRatioB0;

    int256 public immutable poolInitialMarginMultiplier;

    int256 public immutable protocolFeeCollectRatio;

    int256 public immutable minLiquidationReward;

    int256 public immutable maxLiquidationReward;

    int256 public immutable liquidationRewardCutRatio;

    address[] public allWhitelistedTokens;
    mapping (address => bool) public whitelistedTokens;
    mapping (address => bytes32) public tokenPriceId;
    mapping (address => bool) public isPoolManager;

    uint256 public constant mintFeeBasisPoints = 30; // 0.2%
    uint256 public constant burnFeeBasisPoints = 30; // 0.3%
    uint256 public constant BASIS_POINTS_DIVISOR = 10000;

    address public immutable lpTokenAddress;
    address public lpVault;

    modifier onlyManager() {
        require(isPoolManager[msg.sender] , 'Pool: reentry');
        _;
    }

    constructor (
        address[8] memory addresses_,
        uint256[7] memory parameters_
    ) NameVersion('PoolImplementation', '3.0.2')
    {
        vaultTemplate = addresses_[0];
        vaultImplementation = addresses_[1];
        tokenB0 = addresses_[2];
        tokenWETH = addresses_[3];
        // vTokenB0 = addresses_[4];
        // vTokenETH = addresses_[5];
        // lToken = IDToken(addresses_[6]);
        // pToken = IDToken(addresses_[7]);
        oracleManager = IOracleManager(addresses_[4]);
        swapper = ISwapper(addresses_[5]);
        symbolManager = ISymbolManager(addresses_[6]);
        
        lpTokenAddress = addresses_[7];

        reserveRatioB0 = parameters_[0];
        minRatioB0 = parameters_[1].utoi();
        poolInitialMarginMultiplier = parameters_[2].utoi();
        protocolFeeCollectRatio = parameters_[3].utoi();
        minLiquidationReward = parameters_[4].utoi();
        maxLiquidationReward = parameters_[5].utoi();
        liquidationRewardCutRatio = parameters_[6].utoi();

        lpVault = _clone(vaultTemplate);

        require(
            IERC20(tokenB0).decimals() == 18 && IERC20(tokenWETH).decimals() == 18,
            'PoolImplementation.constant: only token of decimals 18'
        );
    }

    function setLpVault(address _lpVault) external _onlyAdmin_ {
        lpVault = _clone(_lpVault);
    }

    function getMarket(address token) external view returns(address) {
        return markets[token];
    }

    function getUserVault(address account, string memory symbolName) external view returns(address) {
        bytes32 vaultId = keccak256(abi.encodePacked(account, symbolName));
        return userVault[vaultId];
    }

    function addMarket(address token, address market) external _onlyAdmin_ {
        // underlying is the underlying token of Venus market
        // address underlying = IVToken(market).underlying();
        require(
            IERC20(token).decimals() == 18,
            'PoolImplementation.addMarket: only token of decimals 18'
        );
        // require(
        //     IVToken(market).isVToken(),
        //     'PoolImplementation.addMarket: invalid vToken'
        // );
        // require(
        //     IVToken(market).comptroller() == IVault(vaultImplementation).comptroller(),
        //     'PoolImplementation.addMarket: wrong comptroller'
        // );
        // require(
        //     swapper.isSupportedToken(underlying),
        //     'PoolImplementation.addMarket: no swapper support'
        // );
        require(
            markets[token] == address(0),
            'PoolImplementation.addMarket: replace not allowed'
        );
        markets[token] = market;
        approveSwapper(token);

        emit AddMarket(market);
    }

    function addWhitelistedTokens(address token, string memory priceSumbolId) external _onlyAdmin_ {
        require(
            !whitelistedTokens[token], 
            "PoolImplementation.addWhitelistedTokens: already in whitelisted"
        );
        allWhitelistedTokens.push(token);
        whitelistedTokens[token] = true;
        tokenPriceId[token] = keccak256(abi.encodePacked(priceSumbolId));
        getTokenPrice(token);
    }

    function removeWhitelistedTokens(address token) external _onlyAdmin_ {
        require(
            whitelistedTokens[token], 
            "PoolImplementation.addWhitelistedTokens: token is not in whitelisted"
        );
        uint256 length = allWhitelistedTokens.length;

        for(uint256 i=0; i < length ; i++) {
            if(allWhitelistedTokens[i] == token) {
                allWhitelistedTokens[i] = allWhitelistedTokens[length-1];
                allWhitelistedTokens.pop();
                whitelistedTokens[token] = false;
                break;
            }
        }
        tokenPriceId[token] = 0;
    }

    function allWhitelistedTokensLength() external view  returns (uint256) {
        return allWhitelistedTokens.length;
    }

    function getTokenPrice(address token) public view returns (uint256) {
        bytes32 priceId = tokenPriceId[token];
        require(priceId !=0, "PoolImplementation.getTokenPrice: invalid price id");
        return oracleManager.getValue(priceId);
    }

    function approvePoolManager(address manager) public _onlyAdmin_ {
        uint256 length = allWhitelistedTokens.length;
        for(uint256 i=0; i < length; i++) {
            address token = allWhitelistedTokens[i];

            require( token != address(0) , "PoolImplementation.approvePoolManager: token is not in whitelisted");
            require( whitelistedTokens[token] , "PoolImplementation.approvePoolManager: token is not in whitelisted");
            uint256 allowance = IERC20(token).allowance(address(this), address(manager));
            if (allowance != type(uint256).max) {
                if (allowance != 0) {
                    IERC20(token).safeApprove(address(manager), 0);
                }
                IERC20(token).safeApprove(address(manager), type(uint256).max);
            }   
        }
        isPoolManager[manager] = true;
    }

    function approveSwapper(address underlying) public _onlyAdmin_ {
        uint256 allowance = IERC20(underlying).allowance(address(this), address(swapper));
        if (allowance != type(uint256).max) {
            if (allowance != 0) {
                IERC20(underlying).safeApprove(address(swapper), 0);
            }
            IERC20(underlying).safeApprove(address(swapper), type(uint256).max);
        }
    }
    

    function collectProtocolFee() external _onlyAdmin_ {
        require(protocolFeeCollector != address(0), 'PoolImplementation.collectProtocolFee: collector not set');
        uint256 amount = protocolFeeAccrued.itou();
        protocolFeeAccrued = 0;
        IERC20(tokenB0).safeTransfer(protocolFeeCollector, amount);
        emit CollectProtocolFee(protocolFeeCollector, amount);
    }

    // function claimVenusLp(address account) external {
    //     uint256 lTokenId = lToken.getTokenIdOf(account);
    //     if (lTokenId != 0) {
    //         IVault(lpInfos[lTokenId].vault).claimVenus(account);
    //     }
    // }

    // function claimVenusTrader(address account) external {
    //     uint256 pTokenId = pToken.getTokenIdOf(account);
    //     if (pTokenId != 0) {
    //         // IVault(tdInfos[pTokenId].vault).claimVenus(account);
    //     }
    // }

    //================================================================================

    // function addLiquidity(address underlying, uint256 amount, OracleSignature[] memory oracleSignatures) external payable _reentryLock_
    // {
    //     _updateOracles(oracleSignatures);

    //     if (underlying == address(0)) amount = msg.value;

    //     Data memory data = _initializeData(underlying);
    //     _getLpInfo(data, true);

    //     ISymbolManager.SettlementOnAddLiquidity memory s =
    //     symbolManager.settleSymbolsOnAddLiquidity(data.liquidity + data.lpsPnl);

    //     int256 undistributedPnl = s.funding - s.deltaTradersPnl;
    //     if (undistributedPnl != 0) {
    //         data.lpsPnl += undistributedPnl;
    //         data.cumulativePnlPerLiquidity += undistributedPnl * ONE / data.liquidity;
    //     }

    //     // _settleLp(data);
    //     _transferIn(data, amount);

    //     int256 newLiquidity = IVault(data.vault).getVaultLiquidity().utoi() + data.amountB0;
    //     data.liquidity += newLiquidity - data.lpLiquidity;
    //     data.lpLiquidity = newLiquidity;

    //     require(
    //         IERC20(tokenB0).balanceOf(address(this)).utoi() * ONE >= data.liquidity * minRatioB0,
    //         'PoolImplementation.addLiquidity: insufficient B0'
    //     );

    //     liquidity = data.liquidity;
    //     lpsPnl = data.lpsPnl;
    //     cumulativePnlPerLiquidity = data.cumulativePnlPerLiquidity;

    //     LpInfo storage info = lpInfos[data.tokenId];
    //     info.vault = data.vault;
    //     info.amountB0 = data.amountB0;
    //     info.liquidity = data.lpLiquidity;
    //     info.cumulativePnlPerLiquidity = data.lpCumulativePnlPerLiquidity;

    //     emit AddLiquidity(data.tokenId, underlying, amount, newLiquidity);
    // }

    function getTokenToUsd(address token, uint256 amount) public view returns (uint256) {
        uint256 price = getTokenPrice(token);
        uint256 deccimals = IERC20(token).decimals();
        return  amount * price / 10**deccimals;
    }

    function getUsdToToken(address token, uint256 amountUsd) public view returns (uint256) {
        uint256 price = getTokenPrice(token);
        uint256 deccimals = IERC20(token).decimals();
        return  amountUsd * 10 ** deccimals / price ;
    }

    function addLiquidity(address underlying, uint256 amount, OracleSignature[] memory oracleSignatures) external _reentryLock_ returns (uint256)
    {
        _updateOracles(oracleSignatures);
        require(whitelistedTokens[underlying], "PoolImplementation: token not in whitelisted");
        Data memory data = _initializeData(msg.sender);
        // _getLpInfo(data, true);

        ISymbolManager.SettlementOnAddLiquidity memory s =
        symbolManager.settleSymbolsOnAddLiquidity(data.liquidity + data.lpsPnl);
        // {
        //     int256 undistributedPnl = s.funding - s.deltaTradersPnl;
        //     if (undistributedPnl != 0) {
        //         data.lpsPnl += undistributedPnl;
        //         // data.cumulativePnlPerLiquidity += undistributedPnl * ONE / data.liquidity;
        //     }
        // }

        data.lpsPnl += s.funding - s.deltaTradersPnl;
        

        uint256 feeAmount = amount * mintFeeBasisPoints / BASIS_POINTS_DIVISOR;

        uint256 amountUsd = getTokenToUsd(underlying, amount-feeAmount);

        int256 availableLiquidity = data.liquidity + data.lpsPnl; 
        uint256 lpSupply = IERC20(lpTokenAddress).totalSupply();
        uint256 mintAmount = availableLiquidity == 0 ? amountUsd : amountUsd * lpSupply / availableLiquidity.itou();
        IMintableToken(lpTokenAddress).mint(msg.sender, mintAmount);

        // uint256 amountOut = _mintLiquidity(data, msg.sender, amountUsd);
        IERC20(underlying).safeTransferFrom(msg.sender, address(this), amount);
        IERC20(underlying).safeTransfer(lpVault, amount-feeAmount);
        // IVault(lpVault).supply(underlying, amount-feeAmount);
        IERC20(underlying).safeTransfer(protocolFeeCollector, feeAmount);
        // require(mintAmount >= minLp, "PoolImplementation.addLiquidity: invalid amount out");
        lpsPnl = data.lpsPnl;
        // emit AddLiquidity(data.tokenId, underlying, amount, newLiquidity);
        emit AddLiquidity(underlying, amount, availableLiquidity, lpSupply, amountUsd, mintAmount);
        return mintAmount;
    }

    // function addLiquidityV2(address token, uint256 amount, uint256 minLp) external payable _reentryLock_ {

    //     if(token == address(0)) {
    //         IWETH(tokenWETH).deposit{value: msg.value}();
    //         token = tokenWETH;
    //         amount = msg.value;
    //     }
    //     require(whitelistedTokens[token], "PoolImplementation: token not in whitelisted");
    //     uint256 price = getTokenPrice(token);
       
    //     uint256 deccimals = IERC20(token).decimals();

    //     uint256 feeAmount = amount * mintFeeBasisPoints / BASIS_POINTS_DIVISOR;

    //     uint256 amountUsd = (amount-feeAmount) * price / 10**deccimals;
    //     uint256 amountOut = _mintLiquidity(data, msg.sender, amountUsd);
    //     IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
    //     _transfer(token, protocolFeeCollector, feeAmount);
    //     require(amountOut >= minLp, "PoolImplementation.addLiquidity: invalid amount out");
    // }

    // function removeLiquidityV2(address tokenOut, uint256 lpAmount, uint256 minAmountOut) external _reentryLock_ { 

    //     require(whitelistedTokens[tokenOut], "PoolImplementation: token not in whitelisted");
    //     // IERC20(lpTokenAddress).safeTransferFrom(msg.sender, address(this), lpAmount);
    //     uint256 amountOutUsd = _burnLiquidity(msg.sender, lpAmount);
    //     uint256 price = getTokenPrice(tokenOut);
    //     uint256 deccimals = IERC20(tokenOut).decimals();

    //     uint256 tokenOutAmount = amountOutUsd * 10 ** deccimals / price ;
    //     uint256 feeAmount = tokenOutAmount * burnFeeBasisPoints / BASIS_POINTS_DIVISOR;
    //     require(tokenOutAmount-feeAmount > minAmountOut, "PoolImplementation.removeLiquidity: invalid amount out");
    //     require(tokenOutAmount-feeAmount > 0, "PoolImplementation.removeLiquidity: invalid amount out2");
    //     _transfer(tokenOut, msg.sender, tokenOutAmount-feeAmount);
    //     _transfer(tokenOut, protocolFeeCollector, feeAmount);

    // }

    function removeLiquidity(address underlying, uint256 lpAmount, OracleSignature[] memory oracleSignatures) external _reentryLock_ returns (uint256)
    {
        _updateOracles(oracleSignatures);

        Data memory data = _initializeData(msg.sender);

        require(whitelistedTokens[underlying], "PoolImplementation: token not in whitelisted");
        
        int256 availableLiquidity = data.liquidity + data.lpsPnl;
        uint256 lpSupply = IERC20(lpTokenAddress).totalSupply();
        IMintableToken(lpTokenAddress).burn(msg.sender, lpAmount);
        uint256 amountOutUsd = lpAmount *  availableLiquidity.itou() / lpSupply;
        ISymbolManager.SettlementOnRemoveLiquidity memory s =
        symbolManager.settleSymbolsOnRemoveLiquidity(data.liquidity + data.lpsPnl, amountOutUsd.utoi());

        int256 undistributedPnl = s.funding - s.deltaTradersPnl + s.removeLiquidityPenalty;
        data.lpsPnl += undistributedPnl;

        uint256 tokenOutAmount = getUsdToToken(underlying, amountOutUsd) ;
        uint256 feeAmount = tokenOutAmount * burnFeeBasisPoints / BASIS_POINTS_DIVISOR;
        // require(tokenOutAmount-feeAmount > minAmountOut, "PoolImplementation.removeLiquidity: invalid amount out");
        require(tokenOutAmount-feeAmount > 0, "PoolImplementation.removeLiquidity: invalid amount out2");
        require(
            data.liquidity * ONE >= s.initialMarginRequired * poolInitialMarginMultiplier,
            'PoolImplementation.removeLiquidity: pool insufficient liquidity'
        );

        IVault v = IVault(lpVault);
        // v.withdraw(underlying, tokenOutAmount);
        v.transfer(underlying,  msg.sender, tokenOutAmount-feeAmount);
        v.transfer(underlying, protocolFeeCollector, feeAmount);
        // _transfer(underlying, protocolFeeCollector, feeAmount);

        lpsPnl = data.lpsPnl;
        

        // emit RemoveLiquidity(data.tokenId, underlying, lpAmount, newLiquidity);
        emit RemoveLiquidity(underlying, lpAmount, availableLiquidity, lpSupply, amountOutUsd, tokenOutAmount-feeAmount);
        return tokenOutAmount-feeAmount;
    }

    // function _mintLiquidity(Data memory data, address to, uint256 amountUsd) private returns (uint256) {
    //     int256 availableLiquidity = (data.liquidity + data.lpsPnl); 
    //     uint256 lpSupply = IERC20(lpTokenAddress).totalSupply();
    //     uint256 mintAmount = availableLiquidity == 0 ? amountUsd : amountUsd * lpSupply / availableLiquidity.itou();
    //     IMintableToken(lpTokenAddress).mint(to, mintAmount);
    //     return mintAmount;
    // }

    // function _burnLiquidity(address from, uint256 lpAmount) private returns (uint256) {
    //     uint256 aum = IVault(lpVault).getVaultLiquidity();
    //     uint256 lpSupply = IERC20(lpTokenAddress).totalSupply();
    //     IMintableToken(lpTokenAddress).burn(from, lpAmount);
    //     return lpAmount *  aum / lpSupply;
    // }

    // function _collectMintFee(address token, uint256 amount) private {
        

    // }

    function getLiquidity() public view returns (uint256) {
        return IVault(lpVault).getVaultLiquidity();
    }



    // function removeLiquidity(address underlying, uint256 amount, OracleSignature[] memory oracleSignatures) external _reentryLock_
    // {
    //     _updateOracles(oracleSignatures);

    //     Data memory data = _initializeData(underlying);
    //     _getLpInfo(data, false);

    //     int256 removedLiquidity;
    //     (uint256 vTokenBalance, uint256 underlyingBalance) = IVault(data.vault).getBalances(data.market);
    //     if (underlying == tokenB0) {
    //         int256 available = underlyingBalance.utoi() + data.amountB0;
    //         if (available > 0) {
    //             removedLiquidity = amount >= available.itou() ? available : amount.utoi();
    //         }
    //     } else if (underlyingBalance > 0) {
    //         uint256 redeemAmount = amount >= underlyingBalance ?
    //                                vTokenBalance :
    //                                vTokenBalance * amount / underlyingBalance;
    //         uint256 bl1 = IVault(data.vault).getVaultLiquidity();
    //         uint256 bl2 = IVault(data.vault).getHypotheticalVaultLiquidity(data.market, redeemAmount);
    //         removedLiquidity = (bl1 - bl2).utoi();
    //     }

    //     ISymbolManager.SettlementOnRemoveLiquidity memory s =
    //     symbolManager.settleSymbolsOnRemoveLiquidity(data.liquidity + data.lpsPnl, removedLiquidity);

    //     int256 undistributedPnl = s.funding - s.deltaTradersPnl + s.removeLiquidityPenalty;
    //     data.lpsPnl += undistributedPnl;
    //     data.cumulativePnlPerLiquidity += undistributedPnl * ONE / data.liquidity;
    //     data.amountB0 -= s.removeLiquidityPenalty;

    //     _settleLp(data);
    //     uint256 newVaultLiquidity = _transferOut(data, amount, vTokenBalance, underlyingBalance);

    //     int256 newLiquidity = newVaultLiquidity.utoi() + data.amountB0;
    //     data.liquidity += newLiquidity - data.lpLiquidity;
    //     data.lpLiquidity = newLiquidity;

    //     require(
    //         data.liquidity * ONE >= s.initialMarginRequired * poolInitialMarginMultiplier,
    //         'PoolImplementation.removeLiquidity: pool insufficient liquidity'
    //     );

    //     liquidity = data.liquidity;
    //     lpsPnl = data.lpsPnl;
    //     cumulativePnlPerLiquidity = data.cumulativePnlPerLiquidity;

    //     LpInfo storage info = lpInfos[data.tokenId];
    //     info.amountB0 = data.amountB0;
    //     info.liquidity = data.lpLiquidity;
    //     info.cumulativePnlPerLiquidity = data.lpCumulativePnlPerLiquidity;

    //     emit RemoveLiquidity(data.tokenId, underlying, amount, newLiquidity);
    // }

    function addMargin(address account, address underlying, string memory symbolName, uint256 amount, OracleSignature[] memory oracleSignatures) external  _reentryLock_
    {
        _updateOracles(oracleSignatures);

        require(msg.sender == account || isPoolManager[msg.sender],  "PoolImplementation: only manager");

        Data memory data;
        data.underlying = underlying;
        // data.market = _getMarket(underlying);
        data.account = account;
        // bytes32 symbolId = keccak256(abi.encodePacked(symbolName));
        _getTdInfo(data, symbolName, true);
        _transferIn(data, amount);

        int256 newMargin = IVault(data.vault).getVaultLiquidity().utoi() + data.amountB0;

        // TdInfo storage info = tdInfos[data.tokenId];
        // info.vault = data.vault;
        // info.amountB0 = data.amountB0;
        emit AddMargin(data.account, symbolName, underlying, amount, newMargin);
    }

    function removeMargin(address account, address underlying, string memory symbolName, uint256 amount, OracleSignature[] memory oracleSignatures) external _reentryLock_
    {
        _updateOracles(oracleSignatures);
        // if user not call the contract directly, he/she must call it by pool manager/router
        require(msg.sender == account || isPoolManager[msg.sender],  "PoolImplementation: only manager");
        Data memory data = _initializeData(underlying, account);
        bytes32 symbolId = keccak256(abi.encodePacked(symbolName));
        _getTdInfo(data, symbolName, false);
        ISymbolManager.SettlementOnRemoveMargin memory s =
        symbolManager.settleSymbolsOnRemoveMargin(data.account, symbolId, data.liquidity + data.lpsPnl);

        int256 undistributedPnl = s.funding - s.deltaTradersPnl;
        data.lpsPnl += undistributedPnl;
        // data.cumulativePnlPerLiquidity += undistributedPnl * ONE / data.liquidity;

        data.amountB0 -= s.traderFunding;

        // (uint256 vTokenBalance, uint256 underlyingBalance) = IVault(data.vault).getBalances(data.market);
        // IVault(data.vault).withdraw(data.underlying, amount);
        IVault(data.vault).transfer(data.underlying, msg.sender, amount);
        uint256 newVaultLiquidity = IVault(data.vault).getVaultLiquidity();
        require(
            newVaultLiquidity.utoi() + data.amountB0 + s.traderPnl >= s.traderInitialMarginRequired,
            'PoolImplementation.removeMargin: insufficient margin'
        );

        lpsPnl = data.lpsPnl;
        // cumulativePnlPerLiquidity = data.cumulativePnlPerLiquidity;

        // tdInfos[data.tokenId].amountB0 = data.amountB0;

        emit RemoveMargin(data.account, symbolName, underlying, amount, newVaultLiquidity.utoi() + data.amountB0);
    }

    function trade(address account, string memory symbolName, int256 tradeVolume, int256 priceLimit, OracleSignature[] memory oracleSignatures) external _reentryLock_
    {
        
        _updateOracles(oracleSignatures);

        bytes32 symbolId = keccak256(abi.encodePacked(symbolName));

        Data memory data = _initializeData(account);
        _getTdInfo(data, symbolName, false);

        ISymbolManager.SettlementOnTrade memory s =
        symbolManager.settleSymbolsOnTrade(data.account, symbolId, tradeVolume, data.liquidity + data.lpsPnl, priceLimit);

        int256 collect = s.tradeFee * protocolFeeCollectRatio / ONE;
        int256 undistributedPnl = s.funding - s.deltaTradersPnl + s.tradeFee - collect + s.tradeRealizedCost;
        data.lpsPnl += undistributedPnl;
        // data.cumulativePnlPerLiquidity += undistributedPnl * ONE / data.liquidity;

        data.amountB0 -= s.traderFunding + s.tradeFee + s.tradeRealizedCost;
        int256 margin = IVault(data.vault).getVaultLiquidity().utoi() + data.amountB0;

        require(
            (data.liquidity + data.lpsPnl) * ONE >= s.initialMarginRequired * poolInitialMarginMultiplier,
            'PoolImplementation.trade: pool insufficient liquidity'
        );
        require(
            margin + s.traderPnl >= s.traderInitialMarginRequired,
            'PoolImplementation.trade: insufficient margin'
        );

        lpsPnl = data.lpsPnl;
        // cumulativePnlPerLiquidity = data.cumulativePnlPerLiquidity;
        protocolFeeAccrued += collect;

        // tdInfos[data.tokenId].amountB0 = data.amountB0;
    }

    function liquidate(address account, string memory symbolName, OracleSignature[] memory oracleSignatures) external _reentryLock_
    {
        _updateOracles(oracleSignatures);

        // require(
        //     pToken.exists(pTokenId),
        //     'PoolImplementation.liquidate: nonexistent pTokenId'
        // );

        Data memory data = _initializeData(msg.sender);
        
        // data.vault = tdInfos[pTokenId].vault;
        // data.amountB0 = tdInfos[pTokenId].amountB0;
        bytes32 symbolId = keccak256(abi.encodePacked(symbolName));
        bytes32 vaultId = keccak256(abi.encodePacked(data.account, symbolName));
        data.vault = userVault[vaultId];

        ISymbolManager.SettlementOnLiquidate memory s =
        symbolManager.settleSymbolsOnLiquidate(account, symbolId, data.liquidity + data.lpsPnl);

        int256 undistributedPnl = s.funding - s.deltaTradersPnl + s.traderRealizedCost;

        data.amountB0 -= s.traderFunding;
        int256 margin = IVault(data.vault).getVaultLiquidity().utoi() + data.amountB0;

        require(
            s.traderMaintenanceMarginRequired > 0,
            'PoolImplementation.liquidate: no position'
        );
        require(
            margin + s.traderPnl < s.traderMaintenanceMarginRequired,
            'PoolImplementation.liquidate: cannot liquidate'
        );

        data.amountB0 -= s.traderRealizedCost;

        IVault v = IVault(data.vault);
        // address[] memory inMarkets = v.getMarketsIn();
        uint256 length = allWhitelistedTokens.length;

        for (uint256 i = 0; i < length; i++) {
            // address market = inMarkets[i];
            // uint256 balance = IVToken(market).balanceOf(data.vault);
            address token = allWhitelistedTokens[i];
            uint256 balance = IERC20(token).balanceOf(data.vault);
            
            if (balance > 0) {
                // address underlying = _getUnderlying(market);
                // v.redeem(market, balance);
                balance = v.transferAll(token, address(this));
                if (token == address(0)) {
                    (uint256 resultB0, ) = swapper.swapExactETHForB0{value: balance}();
                    data.amountB0 += resultB0.utoi();
                } else if (token == tokenB0) {
                    data.amountB0 += balance.utoi();
                } else {
                    (uint256 resultB0, ) = swapper.swapExactBXForB0(token, balance);
                    data.amountB0 += resultB0.utoi();
                }
            }
        }

        int256 reward;
        if (data.amountB0 <= minLiquidationReward) {
            reward = minLiquidationReward;
        } else {
            reward = (data.amountB0 - minLiquidationReward) * liquidationRewardCutRatio / ONE + minLiquidationReward;
            reward = reward.min(maxLiquidationReward);
        }

        undistributedPnl += data.amountB0 - reward;
        data.lpsPnl += undistributedPnl;
        // data.cumulativePnlPerLiquidity += undistributedPnl * ONE / data.liquidity;

        _transfer(tokenB0, msg.sender, reward.itou());

        lpsPnl = data.lpsPnl;
        // cumulativePnlPerLiquidity = data.cumulativePnlPerLiquidity;

        // tdInfos[pTokenId].amountB0 = 0;
    }

    function transfer(address account, address underlying, string memory fromSymbolName, string memory toSymbolName, uint256 amount, OracleSignature[] memory oracleSignatures) external _reentryLock_
    {
        _updateOracles(oracleSignatures);
        // if user not call the contract directly, he/she must call it by pool manager/router
        require(msg.sender == account || isPoolManager[msg.sender],  "PoolImplementation: only manager");

        Data memory data = _initializeData(underlying, account);
        bytes32 symbolId = keccak256(abi.encodePacked(fromSymbolName));
        _getTdInfo(data, fromSymbolName, false);
        ISymbolManager.SettlementOnRemoveMargin memory s =
        symbolManager.settleSymbolsOnRemoveMargin(data.account, symbolId, data.liquidity + data.lpsPnl);

        int256 undistributedPnl = s.funding - s.deltaTradersPnl;
        data.lpsPnl += undistributedPnl;
        data.amountB0 -= s.traderFunding;

        IVault(data.vault).transfer(data.underlying, msg.sender, amount);
        uint256 newVaultLiquidity = IVault(data.vault).getVaultLiquidity();
        require(
            newVaultLiquidity.utoi() + data.amountB0 + s.traderPnl >= s.traderInitialMarginRequired,
            'PoolImplementation.transfer: insufficient margin'
        );

        lpsPnl = data.lpsPnl;
        emit RemoveMargin(data.account, fromSymbolName, underlying, amount, newVaultLiquidity.utoi() + data.amountB0);

        Data memory _data;
        _data.underlying = underlying;
        _data.account = account;
        _getTdInfo(_data, toSymbolName, true);
        _transferIn(_data, amount);
        int256 newMargin = IVault(_data.vault).getVaultLiquidity().utoi() + _data.amountB0;

        emit AddMargin(data.account, toSymbolName, underlying, amount, newMargin);
    }

    //================================================================================

    struct OracleSignature {
        bytes32 oracleSymbolId;
        uint256 timestamp;
        uint256 value;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    function _updateOracles(OracleSignature[] memory oracleSignatures) internal {
        for (uint256 i = 0; i < oracleSignatures.length; i++) {
            OracleSignature memory signature = oracleSignatures[i];
            oracleManager.updateValue(
                signature.oracleSymbolId,
                signature.timestamp,
                signature.value,
                signature.v,
                signature.r,
                signature.s
            );
        }
    }

    struct Data {
        int256 liquidity;
        int256 lpsPnl;
        int256 cumulativePnlPerLiquidity;

        address underlying;
        address market;

        address account;
        uint256 tokenId;
        address vault;
        int256 amountB0;
        int256 lpLiquidity;
        int256 lpCumulativePnlPerLiquidity;
    }

    function _initializeData(address account) internal view returns (Data memory data) {
        data.liquidity = IVault(lpVault).getVaultLiquidity().utoi();
        data.lpsPnl = lpsPnl;
        // data.cumulativePnlPerLiquidity = cumulativePnlPerLiquidity;
        data.account = account;
    }

    function _initializeData(address underlying, address account) internal view returns (Data memory data) {
        data = _initializeData(account);
        data.underlying = underlying;
        // data.market = _getMarket(underlying);
    }

    // function _getMarket(address underlying) internal view returns (address market) {
    //     if (underlying == address(0)) {
    //         market = vTokenETH;
    //     } else if (underlying == tokenB0) {
    //         market = vTokenB0;
    //     } else {
    //         market = markets[underlying];
    //         require(
    //             market != address(0),
    //             'PoolImplementation.getMarket: unsupported market'
    //         );
    //     }
    // }

    // function _getUnderlying(address market) internal view returns (address underlying) {
    //     if (market == vTokenB0) {
    //         underlying = tokenB0;
    //     } else if (market == vTokenETH) {
    //         underlying = address(0);
    //     } else {
    //         underlying = IVToken(market).underlying();
    //     }
    // }

    // function _getLpInfo(Data memory data, bool createOnDemand) internal {
    //     data.tokenId = lToken.getTokenIdOf(data.account);
    //     if (data.tokenId == 0) {
    //         require(createOnDemand, 'PoolImplementation.getLpInfo: not LP');
    //         data.tokenId = lToken.mint(data.account);
    //         data.vault = _clone(vaultTemplate);
    //     } else {
    //         LpInfo storage info = lpInfos[data.tokenId];
    //         data.vault = info.vault;
    //         data.amountB0 = info.amountB0;
    //         data.lpLiquidity = info.liquidity;
    //         // data.lpCumulativePnlPerLiquidity = info.cumulativePnlPerLiquidity;
    //     }
    // }

    function _getTdInfo(Data memory data, string memory symbolName, bool createOnDemand) internal {
        // data.tokenId = pToken.getTokenIdOf(data.account);
        bytes32 vaultId = keccak256(abi.encodePacked(data.account, symbolName));
        address uVault = userVault[vaultId];
        if (uVault == address(0)) {
            require(createOnDemand, 'PoolImplementation.getTdInfo: not trader');
            // data.tokenId = pToken.mint(data.account);
            data.vault = _clone(vaultTemplate);
            userVault[vaultId] = data.vault;
        } else {
            // TdInfo storage info = tdInfos[data.tokenId];
            data.vault = uVault;
            // data.amountB0 = info.amountB0;
        }
    }

    function _clone(address source) internal returns (address target) {
        bytes20 sourceBytes = bytes20(source);
        assembly {
            let c := mload(0x40)
            mstore(c, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(c, 0x14), sourceBytes)
            mstore(add(c, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            target := create(0, c, 0x37)
        }
    }

    function _settleLp(Data memory data) internal pure {
        int256 diff;
        unchecked { diff = data.cumulativePnlPerLiquidity - data.lpCumulativePnlPerLiquidity; }
        int256 pnl = diff * data.lpLiquidity / ONE;

        data.amountB0 += pnl;
        data.lpsPnl -= pnl;
        data.lpCumulativePnlPerLiquidity = data.cumulativePnlPerLiquidity;
    }

    function _transfer(address underlying, address to, uint256 amount) internal {
        if (underlying == address(0)) {
            (bool success, ) = payable(to).call{value: amount}('');
            require(success, 'PoolImplementation.transfer: send ETH fail');
        } else {
            IERC20(underlying).safeTransfer(to, amount);
        }
    }

    function _transferIn(Data memory data, uint256 amount) internal {
        IVault v = IVault(data.vault);

        // if (!v.isInMarket(data.market)) {
        //     v.enterMarket(data.market);
        // }

        // if (data.underlying == address(0)) { // ETH
        //     v.mint{value: amount}();
        // }
        // else if (data.underlying == tokenB0) {
        //     uint256 reserve = amount * reserveRatioB0 / UONE;
        //     uint256 deposit = amount - reserve;

        //     IERC20(data.underlying).safeTransferFrom(data.account, address(this), amount);
        //     IERC20(data.underlying).safeTransfer(data.vault, deposit);

        //     v.mint(data.market, deposit);
        //     data.amountB0 += reserve.utoi();
        // }
        // else {
        IERC20(data.underlying).safeTransferFrom(data.account, address(this), amount);
        IERC20(data.underlying).safeTransfer(data.vault, amount);
        // v.supply(data.underlying, amount);
        // }
    }

    // function _transferOut(Data memory data, uint256 amount, uint256 vTokenBalance, uint256 underlyingBalance)
    // internal returns (uint256 newVaultLiquidity)
    // {
    //     IVault v = IVault(data.vault);

    //     if (underlyingBalance > 0) {
    //         if (amount >= underlyingBalance) {
    //             v.redeem(data.market, vTokenBalance);
    //         } else {
    //             v.redeemUnderlying(data.market, amount);
    //         }

    //         underlyingBalance = data.underlying == address(0) ?
    //                             data.vault.balance :
    //                             IERC20(data.underlying).balanceOf(data.vault);

    //         if (data.amountB0 < 0) {
    //             uint256 owe = (-data.amountB0).itou();
    //             v.transfer(data.underlying, address(this), underlyingBalance);

    //             if (data.underlying == address(0)) {
    //                 (uint256 resultB0, uint256 resultBX) = swapper.swapETHForExactB0{value: underlyingBalance}(owe);
    //                 data.amountB0 += resultB0.utoi();
    //                 underlyingBalance -= resultBX;
    //             }
    //             else if (data.underlying == tokenB0) {
    //                 if (underlyingBalance >= owe) {
    //                     data.amountB0 = 0;
    //                     underlyingBalance -= owe;
    //                 } else {
    //                     data.amountB0 += underlyingBalance.utoi();
    //                     underlyingBalance = 0;
    //                 }
    //             }
    //             else {
    //                 (uint256 resultB0, uint256 resultBX) = swapper.swapBXForExactB0(
    //                     data.underlying, owe, underlyingBalance
    //                 );
    //                 data.amountB0 += resultB0.utoi();
    //                 underlyingBalance -= resultBX;
    //             }

    //             if (underlyingBalance > 0) {
    //                 _transfer(data.underlying, data.account, underlyingBalance);
    //             }
    //         }
    //         else {
    //             v.transfer(data.underlying, data.account, underlyingBalance);
    //         }
    //     }

    //     newVaultLiquidity = v.getVaultLiquidity();

    //     if (newVaultLiquidity == 0 && amount >= UMAX && data.amountB0 > 0) {
    //         uint256 own = data.amountB0.itou();
    //         uint256 resultBX;

    //         if (data.underlying == address(0)) {
    //             (, resultBX) = swapper.swapExactB0ForETH(own);
    //         } else if (data.underlying == tokenB0) {
    //             resultBX = own;
    //         } else {
    //             (, resultBX) = swapper.swapExactB0ForBX(data.underlying, own);
    //         }

    //         _transfer(data.underlying, data.account, resultBX);
    //         data.amountB0 = 0;
    //     }

    //     if (data.underlying == tokenB0 && data.amountB0 > 0 && amount > underlyingBalance) {
    //         uint256 own = data.amountB0.itou();
    //         uint256 resultBX = own.min(amount - underlyingBalance);
    //         _transfer(tokenB0, data.account, resultBX);
    //         data.amountB0 -= resultBX.utoi();
    //     }
    // }

}

import '../token/IERC20.sol';
import '../library/SafeMath.sol';
import '../library/SafeERC20.sol';
import './IPool.sol';
import '../swapper/IUniswapV2Factory.sol';
import '../swapper/IUniswapV2Router02.sol';
import '../utils/Admin.sol';
import '../oracle/IOracleManager.sol';

pragma solidity >=0.8.0 <0.9.0;

contract PoolManager is Admin  {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    uint256 constant ONE = 1e18;
    uint256 constant BASIS_POINTS_DIVISOR = 1e6;


    IUniswapV2Factory public immutable factory;

    IUniswapV2Router02 public immutable router;

    IOracleManager public immutable oracleManager;
    
    address public immutable pool;

    // address public immutable tokenB0;

    address public immutable weth;

    uint256 public immutable maxSlippageRatio;

    // fromToken => toToken => path
    mapping (address => mapping (address => address[])) public paths;

    // tokenBX => oracle symbolId
    mapping (address => bytes32) public oracleSymbolIds;

    constructor (
        address pool_,
        address factory_,
        address router_,
        address oracleManager_,
        uint256 maxSlippageRatio_,
        address weth_
    ) {
        factory = IUniswapV2Factory(factory_);
        router = IUniswapV2Router02(router_);
        oracleManager = IOracleManager(oracleManager_);
        pool = pool_;
        maxSlippageRatio = maxSlippageRatio_;
        weth = weth_;
    }

    function setTokenConfig(address token, address[] calldata pathToETH, string memory symbol) external _onlyAdmin_ {
        uint256 length = pathToETH.length;

        require(length >= 2, 'Swapper.setPath: invalid path length');
        require(pathToETH[0] == token, 'Swapper.setPath: path should begin with token');
        require(pathToETH[length-1] == weth, 'Swapper.setPath: path should begin with WETH');
        for (uint256 i = 1; i < length; i++) {
            require(factory.getPair(pathToETH[i-1], pathToETH[i]) != address(0), 'Swapper.setPath: path broken');
        }

        address[] memory revertedPath = new address[](length);
        for (uint256 i = 0; i < length; i++) {
            revertedPath[length-i-1] = pathToETH[i];
        }

        paths[weth][token] = pathToETH;
        paths[token][weth] = revertedPath;

        IERC20(token).safeApprove(address(router), type(uint256).max);

        bytes32 symbolId = keccak256(abi.encodePacked(symbol));
        require(oracleManager.value(symbolId) != 0, 'Swapper: no oralce price');
        oracleSymbolIds[token] = symbolId;
    }

    function adjustTokensRatio(uint256[] calldata ratios) external _onlyAdmin_ {
        uint256 length = IPool(pool).allWhitelistedTokensLength();
        require(length ==  ratios.length, "PoolManager: Invalid ratios length");

        uint256 ratiosSum = 0;
        for(uint256 i=0 ; i < length; i++) {
            ratiosSum += ratios[i];
        }
        require(ratiosSum == BASIS_POINTS_DIVISOR, "PoolManager: Invalid ratios sum");
        uint256 wethPrice = getTokenPrice(weth);
        for(uint256 i=0 ; i < length; i++) {
            address token = IPool(pool).allWhitelistedTokens(i);
            if(token == weth) { continue;}
            uint256 amount = IERC20(token).balanceOf(pool);

            uint256 tokenPrice = getTokenPrice(token);
            uint256 minAmount = amount * tokenPrice / wethPrice * (BASIS_POINTS_DIVISOR - maxSlippageRatio) / BASIS_POINTS_DIVISOR;

            IERC20(token).safeTransferFrom(pool, address(this), amount);
            router.swapExactTokensForTokens(
                amount,
                minAmount,
                paths[token][weth],
                address(this),
                block.timestamp + 3600
            );
        }
        uint256 totalWeth = IERC20(weth).balanceOf(pool);
        for(uint256 i=0 ; i < length; i++) {
            address token = IPool(pool).allWhitelistedTokens(i);
            if(token == weth) { continue;}
            uint256 amount = totalWeth * ratios[i] / BASIS_POINTS_DIVISOR;

            uint256 tokenPrice = getTokenPrice(token);
            uint256 minAmount = amount * wethPrice / tokenPrice * (BASIS_POINTS_DIVISOR - maxSlippageRatio) / BASIS_POINTS_DIVISOR;

            router.swapExactTokensForTokens(
                amount,
                minAmount,
                paths[weth][token],
                pool,
                block.timestamp + 3600
            );
        }
    }

    function _calAmountOutMin(address token,uint256 amount, uint256 wethPrice) internal {
        

        
    }

    function getTokenPrice(address token) public view returns (uint256) {
        return oracleManager.value(oracleSymbolIds[token]);
    }


    function _swapExactTokensForTokens(address token1, address token2, uint256 amount1, uint256 amount2)
    internal returns (uint256 result1, uint256 result2)
    {
        if (amount1 == 0) return (0, 0);

        uint256[] memory res;
        IERC20(token1).safeTransferFrom(msg.sender, address(this), amount1);
        router.swapExactTokensForTokens(
            amount1,
            amount2,
            paths[token1][token2],
            msg.sender,
            block.timestamp + 3600
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import '../utils/Admin.sol';

abstract contract PoolStorage is Admin {

    // admin will be truned in to Timelock after deployment

    event NewImplementation(address newImplementation);

    event NewProtocolFeeCollector(address newProtocolFeeCollector);

    bool internal _mutex;

    modifier _reentryLock_() {
        require(!_mutex, 'Pool: reentry');
        _mutex = true;
        _;
        _mutex = false;
    }

    address public implementation;

    address public protocolFeeCollector;

    // underlying => vToken, supported markets
    mapping (address => address) public markets;

    struct LpInfo {
        address vault;
        int256 amountB0;
        int256 liquidity;
        int256 cumulativePnlPerLiquidity;
    }


    
    
    // lTokenId => LpInfo
    mapping (uint256 => LpInfo) public lpInfos;

    struct TdInfo {
        address vault;
        int256 amountB0;
    }

    // pTokenId => TdInfo
    // mapping (uint256 => TdInfo) public tdInfos;
    mapping (bytes32 => address) public userVault;

    int256 public liquidity;

    int256 public lpsPnl;

    int256 public cumulativePnlPerLiquidity;

    int256 public protocolFeeAccrued;
    
    
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import '../utils/IAdmin.sol';
import '../utils/INameVersion.sol';
import './IUniswapV2Factory.sol';
import './IUniswapV2Router02.sol';
import '../oracle/IOracleManager.sol';

interface ISwapper is IAdmin, INameVersion {

    function factory() external view returns (IUniswapV2Factory);

    function router() external view returns (IUniswapV2Router02);

    function oracleManager() external view returns (IOracleManager);

    function tokenB0() external view returns (address);

    function tokenWETH() external view returns (address);

    function maxSlippageRatio() external view returns (uint256);

    function oracleSymbolIds(address tokenBX) external view returns (bytes32);

    function setPath(string memory priceSymbol, address[] calldata path) external;

    function getPath(address tokenBX) external view returns (address[] memory);

    function isSupportedToken(address tokenBX) external view returns (bool);

    function getTokenPrice(address tokenBX) external view returns (uint256);

    function swapExactB0ForBX(address tokenBX, uint256 amountB0)
    external returns (uint256 resultB0, uint256 resultBX);

    function swapExactBXForB0(address tokenBX, uint256 amountBX)
    external returns (uint256 resultB0, uint256 resultBX);

    function swapB0ForExactBX(address tokenBX, uint256 maxAmountB0, uint256 amountBX)
    external returns (uint256 resultB0, uint256 resultBX);

    function swapBXForExactB0(address tokenBX, uint256 amountB0, uint256 maxAmountBX)
    external returns (uint256 resultB0, uint256 resultBX);

    function swapExactB0ForETH(uint256 amountB0)
    external returns (uint256 resultB0, uint256 resultBX);

    function swapExactETHForB0()
    external payable returns (uint256 resultB0, uint256 resultBX);

    function swapB0ForExactETH(uint256 maxAmountB0, uint256 amountBX)
    external returns (uint256 resultB0, uint256 resultBX);

    function swapETHForExactB0(uint256 amountB0)
    external payable returns (uint256 resultB0, uint256 resultBX);

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

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

pragma solidity >=0.8.0 <0.9.0;

interface ISymbol {

    struct SettlementOnAddLiquidity {
        bool settled;
        int256 funding;
        int256 deltaTradersPnl;
        int256 deltaInitialMarginRequired;
    }

    struct SettlementOnRemoveLiquidity {
        bool settled;
        int256 funding;
        int256 deltaTradersPnl;
        int256 deltaInitialMarginRequired;
        int256 removeLiquidityPenalty;
    }

    struct SettlementOnTraderWithPosition {
        int256 funding;
        int256 deltaTradersPnl;
        int256 deltaInitialMarginRequired;
        int256 traderFunding;
        int256 traderPnl;
        int256 traderInitialMarginRequired;
    }

    struct SettlementOnTrade {
        int256 funding;
        int256 deltaTradersPnl;
        int256 deltaInitialMarginRequired;
        int256 indexPrice;
        int256 traderFunding;
        int256 traderPnl;
        int256 traderInitialMarginRequired;
        int256 tradeCost;
        int256 tradeFee;
        int256 tradeRealizedCost;
        int256 positionChangeStatus; // 1: new open (enter), -1: total close (exit), 0: others (not change)
    }

    struct SettlementOnLiquidate {
        int256 funding;
        int256 deltaTradersPnl;
        int256 deltaInitialMarginRequired;
        int256 indexPrice;
        int256 traderFunding;
        int256 traderPnl;
        int256 traderMaintenanceMarginRequired;
        int256 tradeVolume;
        int256 tradeCost;
        int256 tradeRealizedCost;
    }

    struct Position {
        int256 volume;
        int256 cost;
        int256 cumulativeFundingPerVolume;
    }

    function implementation() external view returns (address);

    function symbol() external view returns (string memory);

    function netVolume() external view returns (int256);

    function netCost() external view returns (int256);

    function indexPrice() external view returns (int256);

    function fundingTimestamp() external view returns (uint256);

    function cumulativeFundingPerVolume() external view returns (int256);

    function tradersPnl() external view returns (int256);

    function initialMarginRequired() external view returns (int256);

    function nPositionHolders() external view returns (uint256);

    function positions(uint256 pTokenId) external view returns (Position memory);

    function setImplementation(address newImplementation) external;

    function manager() external view returns (address);

    function oracleManager() external view returns (address);

    function symbolId() external view returns (bytes32);

    function feeRatio() external view returns (int256);             // futures only

    function alpha() external view returns (int256);

    function fundingPeriod() external view returns (int256);

    function minTradeVolume() external view returns (int256);

    function initialMarginRatio() external view returns (int256);

    function maintenanceMarginRatio() external view returns (int256);

    function pricePercentThreshold() external view returns (int256);

    function timeThreshold() external view returns (uint256);

    function isCloseOnly() external view returns (bool);

    function priceId() external view returns (bytes32);              // option only

    function volatilityId() external view returns (bytes32);         // option only

    function feeRatioITM() external view returns (int256);           // option only

    function feeRatioOTM() external view returns (int256);           // option only

    function strikePrice() external view returns (int256);           // option only

    function minInitialMarginRatio() external view returns (int256); // option only

    function isCall() external view returns (bool);                  // option only

    function hasPosition(address pTokenId) external view returns (bool);

    function settleOnAddLiquidity(int256 liquidity)
    external returns (ISymbol.SettlementOnAddLiquidity memory s);

    function settleOnRemoveLiquidity(int256 liquidity, int256 removedLiquidity)
    external returns (ISymbol.SettlementOnRemoveLiquidity memory s);

    function settleOnTraderWithPosition(address pTokenId, int256 liquidity)
    external returns (ISymbol.SettlementOnTraderWithPosition memory s);

    function settleOnTrade(address pTokenId, int256 tradeVolume, int256 liquidity, int256 priceLimit)
    external returns (ISymbol.SettlementOnTrade memory s);

    function settleOnLiquidate(address pTokenId, int256 liquidity)
    external returns (ISymbol.SettlementOnLiquidate memory s);

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

interface ISymbolManager {

    struct SettlementOnAddLiquidity {
        int256 funding;
        int256 deltaTradersPnl;
    }

    struct SettlementOnRemoveLiquidity {
        int256 funding;
        int256 deltaTradersPnl;
        int256 initialMarginRequired;
        int256 removeLiquidityPenalty;
    }

    struct SettlementOnRemoveMargin {
        int256 funding;
        int256 deltaTradersPnl;
        int256 traderFunding;
        int256 traderPnl;
        int256 traderInitialMarginRequired;
    }

    struct SettlementOnTrade {
        int256 funding;
        int256 deltaTradersPnl;
        int256 initialMarginRequired;
        int256 traderFunding;
        int256 traderPnl;
        int256 traderInitialMarginRequired;
        int256 tradeFee;
        int256 tradeRealizedCost;
    }

    struct SettlementOnLiquidate {
        int256 funding;
        int256 deltaTradersPnl;
        int256 traderFunding;
        int256 traderPnl;
        int256 traderMaintenanceMarginRequired;
        int256 traderRealizedCost;
    }

    function implementation() external view returns (address);

    function initialMarginRequired() external view returns (int256);

    function pool() external view returns (address);

    function getActiveSymbols(address pTokenId) external view returns (address[] memory);

    function getSymbolsLength() external view returns (uint256);

    function addSymbol(address symbol) external;

    function removeSymbol(bytes32 symbolId) external;

    function symbols(bytes32 symbolId) external view returns (address);

    function settleSymbolsOnAddLiquidity(int256 liquidity)
    external returns (SettlementOnAddLiquidity memory ss);

    function settleSymbolsOnRemoveLiquidity(int256 liquidity, int256 removedLiquidity)
    external returns (SettlementOnRemoveLiquidity memory ss);

    function settleSymbolsOnRemoveMargin(address pTokenId, bytes32 symbolId, int256 liquidity)
    external returns (SettlementOnRemoveMargin memory ss);

    function settleSymbolsOnTrade(address pTokenId, bytes32 symbolId, int256 tradeVolume, int256 liquidity, int256 priceLimit)
    external returns (SettlementOnTrade memory ss);

    function settleSymbolsOnLiquidate(address pTokenId, bytes32 symbolId, int256 liquidity)
    external returns (SettlementOnLiquidate memory ss);

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;
interface IKeep {
    function supply(address asset, uint256 amount, address onBehalfOf) external;
    function withdraw(address asset, uint256, address to) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import './IERC721.sol';
import '../utils/INameVersion.sol';

interface IDToken is IERC721, INameVersion {

    function pool() external view returns (address);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function totalMinted() external view returns (uint256);

    function exists(address owner) external view returns (bool);

    function exists(uint256 tokenId) external view returns (bool);

    function getOwnerOf(uint256 tokenId) external view returns (address);

    function getTokenIdOf(address owner) external view returns (uint256);

    function mint(address owner) external returns (uint256);

    function burn(uint256 tokenId) external;

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

interface IERC165 {

    function supportsInterface(bytes4 interfaceId) external view returns (bool);

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

interface IERC20 {

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    event Transfer(address indexed from, address indexed to, uint256 amount);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transfer(address to, uint256 amount) external returns (bool);

    function transferFrom(address from, address to, uint256 amount) external returns (bool);

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "./IERC165.sol";

interface IERC721 is IERC165 {

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    event Approval(address indexed owner, address indexed operator, uint256 indexed tokenId);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns (uint256);

    function ownerOf(uint256 tokenId) external view returns (address);

    function getApproved(uint256 tokenId) external view returns (address);

    function isApprovedForAll(address owner, address operator) external view returns (bool);

    function approve(address operator, uint256 tokenId) external;

    function setApprovalForAll(address operator, bool approved) external;

    function transferFrom(address from, address to, uint256 tokenId) external;

    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

interface IMintableToken {
    function isMinter(address _account) external returns (bool);
    function setMinter(address _minter, bool _isActive) external;
    function mint(address _account, uint256 _amount) external;
    function burn(address _account, uint256 _amount) external;
}

pragma solidity ^0.8.0;
interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import './IAdmin.sol';

abstract contract Admin is IAdmin {

    address public admin;

    modifier _onlyAdmin_() {
        require(msg.sender == admin, 'Admin: only admin');
        _;
    }

    constructor () {
        admin = msg.sender;
        emit NewAdmin(admin);
    }

    function setAdmin(address newAdmin) external _onlyAdmin_ {
        admin = newAdmin;
        emit NewAdmin(newAdmin);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

interface IAdmin {

    event NewAdmin(address indexed newAdmin);

    function admin() external view returns (address);

    function setAdmin(address newAdmin) external;

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

interface INameVersion {

    function nameId() external view returns (bytes32);

    function versionId() external view returns (bytes32);

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "./INameVersion.sol";

/**
 * @dev Convenience contract for name and version information
 */
abstract contract NameVersion is INameVersion {

    bytes32 public immutable nameId;
    bytes32 public immutable versionId;

    constructor (string memory name, string memory version) {
        nameId = keccak256(abi.encodePacked(name));
        versionId = keccak256(abi.encodePacked(version));
    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

interface IComptroller {

    function isComptroller() external view returns (bool);

    function checkMembership(address account, address vToken) external view returns (bool);

    function getAssetsIn(address account) external view returns (address[] memory);

    function getAccountLiquidity(address account) external view returns (uint256 error, uint256 liquidity, uint256 shortfall);

    function getHypotheticalAccountLiquidity(address account, address vTokenModify, uint256 redeemTokens, uint256 borrowAmount)
    external view returns (uint256 error, uint256 liquidity, uint256 shortfall);

    function enterMarkets(address[] memory vTokens) external returns (uint256[] memory errors);

    function exitMarket(address vToken) external returns (uint256 error);

    function getXVSAddress() external view returns (address);

    function claimVenus(address account) external;

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import '../utils/INameVersion.sol';

interface IVault is INameVersion {

    function pool() external view returns (address);

    // function comptroller() external view returns (address);

    // function vTokenETH() external view returns (address);

    // function tokenXVS() external view returns (address);

    function vaultLiquidityMultiplier() external view returns (uint256);

    function getVaultLiquidity() external view  returns (uint256);

    // function getHypotheticalVaultLiquidity(address vTokenModify, uint256 redeemVTokens) external view returns (uint256);

    // function isInMarket(address vToken) external view returns (bool);

    // function getMarketsIn() external view returns (address[] memory);

    // function getBalances(address vToken) external view returns (uint256 vTokenBalance, uint256 underlyingBalance);

    // function enterMarket(address vToken) external;

    // function exitMarket(address vToken) external;

    // function mint() external payable;

    // function mint(address vToken, uint256 amount) external;

    // function redeem(address vToken, uint256 amount) external;

    // function redeemAll(address vToken) external;

    // function redeemUnderlying(address vToken, uint256 amount) external;

    function transfer(address underlying, address to, uint256 amount) external;

    function transferAll(address underlying, address to) external returns (uint256);

    // function claimVenus(address account) external;

    // function supply(address token, uint256 amount) external;
    // function withdraw(address token, uint256 amount) external;

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

interface IVToken {

    function isVToken() external view returns (bool);

    function symbol() external view returns (string memory);

    function balanceOf(address account) external view returns (uint256);

    function decimals() external view returns (uint256);

    function comptroller() external view returns (address);

    function underlying() external view returns (address);

    function exchangeRateStored() external view returns (uint256);

    function mint() external payable;

    function mint(uint256 amount) external returns (uint256 error);

    function redeem(uint256 amount) external returns (uint256 error);

    function redeemUnderlying(uint256 amount) external returns (uint256 error);

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import './IVToken.sol';
import './IComptroller.sol';
import '../token/IERC20.sol';
import '../library/SafeERC20.sol';
import '../utils/NameVersion.sol';
import '../test/keep/IKeep.sol';
import '../pool/IPool.sol';
contract VaultImplementation is NameVersion {

    using SafeERC20 for IERC20;

    uint256 constant ONE = 1e18;

    address public immutable pool;

    // address public immutable comptroller;

    // address public immutable vTokenETH;

    // address public immutable tokenXVS;

    uint256 public immutable vaultLiquidityMultiplier;

    // address public immutable lending;

    modifier _onlyPool_() {
        require(msg.sender == pool, 'VaultImplementation: only pool');
        _;
    }

    constructor (
        address pool_,
        // address comptroller_,
        // address vTokenETH_,
        uint256 vaultLiquidityMultiplier_
        // address lending_
    ) NameVersion('VaultImplementation', '3.0.1') {
        pool = pool_;
        // comptroller = comptroller_;
        // vTokenETH = vTokenETH_;
        vaultLiquidityMultiplier = vaultLiquidityMultiplier_;
        // tokenXVS = IComptroller(comptroller_).getXVSAddress();
        // lending = lending_;

        // require(
        //     IComptroller(comptroller_).isComptroller(),
        //     'VaultImplementation.constructor: not comptroller'
        // );
        // require(
        //     IVToken(vTokenETH_).isVToken(),
        //     'VaultImplementation.constructor: not vToken'
        // );
        // require(
        //     keccak256(abi.encodePacked(IVToken(vTokenETH_).symbol())) == keccak256(abi.encodePacked('vBNB')),
        //     'VaultImplementation.constructor: not vBNB'
        // );
    }

    function getVaultLiquidity() external view returns (uint256) {

        // (uint256 err, uint256 liquidity, uint256 shortfall) = IComptroller(comptroller).getAccountLiquidity(address(this));
        // require(err == 0 && shortfall == 0, 'VaultImplementation.getVaultLiquidity: error');
        // return liquidity * vaultLiquidityMultiplier / ONE;
        IPool poolContract = IPool(pool);
        uint256 length = poolContract.allWhitelistedTokensLength();
        uint256 liquidity = 0;

        for (uint256 i = 0; i < length; i++) {
            address token = poolContract.allWhitelistedTokens(i);
            bool isWhitelisted = poolContract.whitelistedTokens(token);
            if (!isWhitelisted) {
                continue;
            }

            uint256 price = poolContract.getTokenPrice(token);
            // address market = poolContract.getMarket(token);
            uint256 amount = IERC20(token).balanceOf(address(this));
            uint256 decimals = IERC20(token).decimals();
            liquidity += amount * price / 10 ** decimals;
        }
        return liquidity;

    }

    // function getVaultLiquidity() external view returns (uint256) {

    // }

    // function getHypotheticalVaultLiquidity(address vTokenModify, uint256 redeemVTokens)
    // external view returns (uint256)
    // {
    //     (uint256 err, uint256 liquidity, uint256 shortfall) =
    //     IComptroller(comptroller).getHypotheticalAccountLiquidity(address(this), vTokenModify, redeemVTokens, 0);
    //     require(err == 0 && shortfall == 0, 'VaultImplementation.getHypotheticalVaultLiquidity: error');
    //     return liquidity * vaultLiquidityMultiplier / ONE;
    // }

    // function isInMarket(address vToken) public view returns (bool) {
    //     return IComptroller(comptroller).checkMembership(address(this), vToken);
    // }

    // function getMarketsIn() external view returns (address[] memory) {
    //     return IComptroller(comptroller).getAssetsIn(address(this));
    // }

    // function getBalances(address vToken) external view returns (uint256 vTokenBalance, uint256 underlyingBalance) {
    //     vTokenBalance = IVToken(vToken).balanceOf(address(this));
    //     if (vTokenBalance != 0) {
    //         uint256 exchangeRate = IVToken(vToken).exchangeRateStored();
    //         underlyingBalance = vTokenBalance * exchangeRate / ONE;
    //     }
    // }

    // function enterMarket(address vToken) external _onlyPool_ {
    //     if (vToken != vTokenETH) {
    //         IERC20 underlying = IERC20(IVToken(vToken).underlying());
    //         uint256 allowance = underlying.allowance(address(this), vToken);
    //         if (allowance != type(uint256).max) {
    //             if (allowance != 0) {
    //                 underlying.safeApprove(vToken, 0);
    //             }
    //             underlying.safeApprove(vToken, type(uint256).max);
    //         }
    //     }
    //     address[] memory markets = new address[](1);
    //     markets[0] = vToken;
    //     uint256[] memory res = IComptroller(comptroller).enterMarkets(markets);
    //     require(res[0] == 0, 'VaultImplementation.enterMarket: error');
    // }

    // function exitMarket(address vToken) external _onlyPool_ {
    //     if (vToken != vTokenETH) {
    //         IERC20 underlying = IERC20(IVToken(vToken).underlying());
    //         uint256 allowance = underlying.allowance(address(this), vToken);
    //         if (allowance != 0) {
    //             underlying.safeApprove(vToken, 0);
    //         }
    //     }
    //     require(
    //         IComptroller(comptroller).exitMarket(vToken) == 0,
    //         'VaultImplementation.exitMarket: error'
    //     );
    // }

    // function mint() external payable _onlyPool_ {
    //     IVToken(vTokenETH).mint{value: msg.value}();
    // }

    // function mint(address vToken, uint256 amount) external _onlyPool_ {
    //     require(IVToken(vToken).mint(amount) == 0, 'VaultImplementation.mint: error');
    // }

    // function supply(address token, uint256 amount) external _onlyPool_ {
    //     IERC20(token).safeApprove(lending, amount);
    //     IKeep(lending).supply(token, amount, address(this));
    // }

    // function withdraw(address token, uint256 amount) external _onlyPool_ {
    //     IKeep(lending).withdraw(token, amount, address(this));
    // }

    // function redeem(address vToken, uint256 amount) public _onlyPool_ {
    //     require(IVToken(vToken).redeem(amount) == 0, 'VaultImplementation.redeem: error');
    // }

    // function redeemAll(address vToken) external _onlyPool_ {
    //     uint256 balance = IVToken(vToken).balanceOf(address(this));
    //     if (balance != 0) {
    //         redeem(vToken, balance);
    //     }
    // }

    // function redeemUnderlying(address vToken, uint256 amount) external _onlyPool_ {
    //     require(
    //         IVToken(vToken).redeemUnderlying(amount) == 0,
    //         'VaultImplementation.redeemUnderlying: error'
    //     );
    // }

    function transfer(address underlying, address to, uint256 amount) public _onlyPool_ {
        if (underlying == address(0)) {
            (bool success, ) = payable(to).call{value: amount}('');
            require(success, 'VaultImplementation.transfer: send ETH fail');
        } else {
            IERC20(underlying).safeTransfer(to, amount);
        }
    }

    function transferAll(address underlying, address to) external _onlyPool_ returns (uint256) {
        uint256 amount = underlying == address(0) ?
                         address(this).balance :
                         IERC20(underlying).balanceOf(address(this));
        transfer(underlying, to, amount);
        return amount;
    }

    // function claimVenus(address account) external _onlyPool_ {
    //     IComptroller(comptroller).claimVenus(address(this));
    //     uint256 balance = IERC20(tokenXVS).balanceOf(address(this));
    //     if (balance != 0) {
    //         IERC20(tokenXVS).safeTransfer(account, balance);
    //     }
    // }

}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.4.22 <0.9.0;

library console {
	address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

	function _sendLogPayload(bytes memory payload) private view {
		uint256 payloadLength = payload.length;
		address consoleAddress = CONSOLE_ADDRESS;
		assembly {
			let payloadStart := add(payload, 32)
			let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
		}
	}

	function log() internal view {
		_sendLogPayload(abi.encodeWithSignature("log()"));
	}

	function logInt(int256 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(int256)", p0));
	}

	function logUint(uint256 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256)", p0));
	}

	function logString(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function logBool(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function logAddress(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function logBytes(bytes memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
	}

	function logBytes1(bytes1 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
	}

	function logBytes2(bytes2 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
	}

	function logBytes3(bytes3 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
	}

	function logBytes4(bytes4 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
	}

	function logBytes5(bytes5 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
	}

	function logBytes6(bytes6 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
	}

	function logBytes7(bytes7 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
	}

	function logBytes8(bytes8 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
	}

	function logBytes9(bytes9 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
	}

	function logBytes10(bytes10 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
	}

	function logBytes11(bytes11 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
	}

	function logBytes12(bytes12 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
	}

	function logBytes13(bytes13 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
	}

	function logBytes14(bytes14 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
	}

	function logBytes15(bytes15 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
	}

	function logBytes16(bytes16 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
	}

	function logBytes17(bytes17 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
	}

	function logBytes18(bytes18 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
	}

	function logBytes19(bytes19 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
	}

	function logBytes20(bytes20 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
	}

	function logBytes21(bytes21 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
	}

	function logBytes22(bytes22 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
	}

	function logBytes23(bytes23 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
	}

	function logBytes24(bytes24 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
	}

	function logBytes25(bytes25 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
	}

	function logBytes26(bytes26 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
	}

	function logBytes27(bytes27 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
	}

	function logBytes28(bytes28 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
	}

	function logBytes29(bytes29 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
	}

	function logBytes30(bytes30 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
	}

	function logBytes31(bytes31 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
	}

	function logBytes32(bytes32 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
	}

	function log(uint256 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256)", p0));
	}

	function log(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function log(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function log(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function log(uint256 p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256)", p0, p1));
	}

	function log(uint256 p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string)", p0, p1));
	}

	function log(uint256 p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool)", p0, p1));
	}

	function log(uint256 p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address)", p0, p1));
	}

	function log(string memory p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256)", p0, p1));
	}

	function log(string memory p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
	}

	function log(string memory p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
	}

	function log(string memory p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
	}

	function log(bool p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256)", p0, p1));
	}

	function log(bool p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
	}

	function log(bool p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
	}

	function log(bool p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
	}

	function log(address p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256)", p0, p1));
	}

	function log(address p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
	}

	function log(address p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
	}

	function log(address p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
	}

	function log(uint256 p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
	}

	function log(string memory p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256)", p0, p1, p2));
	}

	function log(string memory p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
	}

	function log(string memory p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
	}

	function log(string memory p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
	}

	function log(bool p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256)", p0, p1, p2));
	}

	function log(bool p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
	}

	function log(bool p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
	}

	function log(bool p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
	}

	function log(bool p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256)", p0, p1, p2));
	}

	function log(bool p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
	}

	function log(bool p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
	}

	function log(bool p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address)", p0, p1, p2));
	}

	function log(address p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256)", p0, p1, p2));
	}

	function log(address p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
	}

	function log(address p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
	}

	function log(address p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
	}

	function log(address p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256)", p0, p1, p2));
	}

	function log(address p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
	}

	function log(address p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
	}

	function log(address p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
	}

	function log(address p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256)", p0, p1, p2));
	}

	function log(address p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
	}

	function log(address p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
	}

	function log(address p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
	}

}