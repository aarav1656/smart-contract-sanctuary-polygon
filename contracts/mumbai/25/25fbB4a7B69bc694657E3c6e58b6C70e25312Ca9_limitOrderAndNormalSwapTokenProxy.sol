// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.12;

library EnumerableSet {
    struct Set {
        bytes32[] _values;
        mapping(bytes32 => uint256) _indexes;
    }

    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    function _remove(Set storage set, bytes32 value) private returns (bool) {
        uint256 valueIndex = set._indexes[value];
        if (valueIndex != 0) {
            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;
            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];
                set._values[toDeleteIndex] = lastValue;
                set._indexes[lastValue] = valueIndex;
            }
            set._values.pop();
            delete set._indexes[value];
            return true;
        } else {
            return false;
        }
    }

    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }


    struct Bytes32Set {
        Set _inner;
    }

    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    struct AddressSet {
        Set _inner;
    }

    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    struct UintSet {
        Set _inner;
    }

    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;
        assembly {
            result := store
        }
        return result;
    }
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "s1");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "s2");
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "s3");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "s4");
        uint256 c = a / b;
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "s5");
        return a % b;
    }
}

interface IOps {
    function createTask(
        address execAddress,
        bytes calldata execDataOrSelector,
        ModuleData calldata moduleData,
        address feeToken
    ) external returns (bytes32 taskId);

    function cancelTask(bytes32 taskId) external;

    function getFeeDetails() external view returns (uint256, address);

    function gelato() external view returns (address payable);

    function taskTreasury() external view returns (ITaskTreasuryUpgradable);
}

interface ITaskTreasuryUpgradable {
    function depositFunds(
        address receiver,
        address token,
        uint256 amount
    ) external payable;

    function withdrawFunds(
        address payable receiver,
        address token,
        uint256 amount
    ) external;
}

interface IOpsProxyFactory {
    function getProxyOf(address account) external view returns (address, bool);
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);

    function approve(address spender, uint value) external returns (bool);

    function allowance(address _owner, address spender) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success,) = recipient.call{value : amount}("");
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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value : value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
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

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(data, "e0");
        if (returndata.length > 0) {
            require(abi.decode(returndata, (bool)), "e1");
        }
    }
}

abstract contract OpsReady {
    IOps public immutable ops;
    address public immutable dedicatedMsgSender;
    address public immutable _gelato;
    address internal constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address private constant OPS_PROXY_FACTORY =
    0xC815dB16D4be6ddf2685C201937905aBf338F5D7;

    /**
     * @dev
     * Only tasks created by _taskCreator defined in constructor can call
     * the functions with this modifier.
     */
    modifier onlyDedicatedMsgSender() {
        require(msg.sender == dedicatedMsgSender, "Only dedicated msg.sender");
        _;
    }

    /**
     * @dev
     * _taskCreator is the address which will create tasks for this contract.
     */
    constructor(address _ops, address _taskCreator) {
        ops = IOps(_ops);
        _gelato = IOps(_ops).gelato();
        (dedicatedMsgSender,) = IOpsProxyFactory(OPS_PROXY_FACTORY).getProxyOf(
            _taskCreator
        );
    }

    /**
     * @dev
     * Transfers fee to gelato for synchronous fee payments.
     *
     * _fee & _feeToken should be queried from IOps.getFeeDetails()
     */
    function _transfer(uint256 _fee, address _feeToken) internal {
        if (_feeToken == ETH) {
            (bool success,) = _gelato.call{value : _fee}("");
            require(success, "_transfer: ETH transfer failed");
        } else {
            SafeERC20.safeTransfer(IERC20(_feeToken), _gelato, _fee);
        }
    }

    function _getFeeDetails()
    internal
    view
    returns (uint256 fee, address feeToken)
    {
        (fee, feeToken) = ops.getFeeDetails();
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor() {
        _setOwner(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(owner() == _msgSender(), "k002");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "k003");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IAocoRouter02 {
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
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

}

abstract contract OpsTaskCreator is OpsReady {
    using SafeERC20 for IERC20;

    address public immutable fundsOwner;
    ITaskTreasuryUpgradable public immutable taskTreasury;

    constructor(address _ops, address _fundsOwner)
    OpsReady(_ops, address(this))
    {
        fundsOwner = _fundsOwner;
        taskTreasury = ops.taskTreasury();
    }

    /**
     * @dev
     * Withdraw funds from this contract's Gelato balance to fundsOwner.
     */
    function withdrawFunds(uint256 _amount, address _token) external {
        require(
            msg.sender == fundsOwner,
            "Only funds owner can withdraw funds"
        );

        taskTreasury.withdrawFunds(payable(fundsOwner), _token, _amount);
    }

    function _depositFunds(uint256 _amount, address _token) internal {
        uint256 ethValue = _token == ETH ? _amount : 0;
        taskTreasury.depositFunds{value : ethValue}(
            address(this),
            _token,
            _amount
        );
    }

    function _createTask(
        address _execAddress,
        bytes memory _execDataOrSelector,
        ModuleData memory _moduleData,
        address _feeToken
    ) internal returns (bytes32) {
        return
        ops.createTask(
            _execAddress,
            _execDataOrSelector,
            _moduleData,
            _feeToken
        );
    }

    function _cancelTask(bytes32 _taskId) internal {
        ops.cancelTask(_taskId);
    }

    function _resolverModuleArg(
        address _resolverAddress,
        bytes memory _resolverData
    ) internal pure returns (bytes memory) {
        return abi.encode(_resolverAddress, _resolverData);
    }

    function _timeModuleArg(uint256 _startTime, uint256 _interval)
    internal
    pure
    returns (bytes memory)
    {
        return abi.encode(uint128(_startTime), uint128(_interval));
    }

    function _proxyModuleArg() internal pure returns (bytes memory) {
        return bytes("");
    }

    function _singleExecModuleArg() internal pure returns (bytes memory) {
        return bytes("");
    }
}

interface USDTPool {
    function userInfoList(address _user) external view returns (bool _canClaim, uint256 _maxAmount);

    function claimUSDT(address _user, uint256 _amount) external;

    function USDT() external view returns (IERC20);

    function swapRate() external view returns (uint256);

    function swapAllRate() external view returns (uint256);

    function getYearMonthDay(uint256 _timestamp) external view returns (uint256);
}

    enum Module {
        RESOLVER,
        TIME,
        PROXY,
        SINGLE_EXEC
    }

    enum orderType{USDTOrder, GasOrder, LimitOrder}

    struct ModuleData {
        Module[] modules;
        bytes[] args;
    }

    struct txItem {
        uint256 _totalTx;
        uint256 _totalSpendTokenAmount;
        uint256 _totalFee;
    }

    struct userInfoItem {
        uint256 ethDepositAmount;
        uint256 ethAmount;
        uint256 ethUsedAmount;
        uint256 ethWithdrawAmount;

        uint256 usdtDepositAmount;
        uint256 usdtAmount;
        uint256 usdtUsedAmount;
        uint256 usdtWithdrawAmount;

        uint256 devDepositAmount;
        uint256 devAmount;
        uint256 devUsedAmount;
        uint256 devWithdrawAmount;
    }

    struct limitItem {
        uint256 _swapInDecimals;
        uint256 _swapInAmount;
        uint256 _swapInAmountOld;

        uint256 _swapOutDecimals;
        uint256 _swapOutStandardAmount;
        uint256 _minswapOutAmount;
        uint256 _swapOutAmount;
    }

    struct tccItem {
        string _taskName; //任务名字 (刷单/限价单)
        IAocoRouter02 _routerAddress; //路由地址(刷单/限价单)
        address[] _swapRouter;  //usdt买代币(刷单/限价单)
        address[] _swapRouter2; //代币换USDT
        uint256 _interval; //触发频率,小于20每个区块都检测,大于20按指定的时间间隔检测条件
        uint256[] _start_end_Time; //开始和结束时间(刷单/限价单)
        uint256[] _timeList; //设置的交易时间段,两个一组(刷单)
        uint256[] _timeIntervalList; //交易的时间间隔列表(刷单)
        uint256[] _swapAmountList; //交易的USDT数量列表(刷单)
        uint256 _maxtxAmount; //每天的交易次数上限(刷单)
        uint256 _maxSpendTokenAmount; //每天刷单消耗USDT的总量上限(刷单)
        uint256 _maxFeePerTx; //每笔刷单消耗的GAS上限(刷单/限价单)
        limitItem _limitItem; //(限价单)
        orderType _type;
    }

    struct tcdItem {
        uint256 _index;
        address _owner;
        address _execAddress;
        bytes _execDataOrSelector;
        ModuleData _moduleData;
        address _feeToken;
        bool _status;
        uint256 _taskExTimes;
        bytes32 _md5;
        bytes32 _taskID;
    }

    struct taskConfig {
        tccItem tcc;
        tcdItem tcd;
    }

    struct balanceItem {
        uint256 balanceOfIn0;
        uint256 balanceOfOut0;
        uint256 balanceOfOut1;
        uint256 balanceOfIn1;
    }

    struct TokenItem {
        address swapInToken;
        address swapOutToken;
    }

    struct feeItem {
        uint256 poolFee;
        uint256 allFee;
    }

    struct feeItem2 {
        uint256 fee;
        address feeToken;
    }

    struct swapTokenItem {
        uint256 day;
        uint256 claimAmount;
        uint256 swapInAmount;
        uint256 spendSwapInToken;
        bytes32 taskID;
        TokenItem _TokenItem;
        balanceItem _balanceItem;
        feeItem _feeItem;
        feeItem2 _feeItem2;
    }

    struct swapEventItem {
        uint256 _swapInDecimals;
        uint256 _swapOutDecimals;
        uint256 _usdtAmount;
        uint256 _spendUsdtAmount;
        uint256 _poolFee;
        uint256 _swapInAmount;
        uint256 _minswapOutAmount;
        uint256 _swapOutAmount;
    }

interface limitOrderAndNormalSwapToken {
    function setDedicatedMsgSenderList(address _dedicatedMsgSender) external;

    function setDefaultSwapInfo(uint256 _approveAmount) external;

    function setDevTokenAndFee(IERC20 _devToken, uint256 _devFee) external;

    function setUSDTPoolAddress(USDTPool _USDTPoolAddress, address _WETH) external;

    function setSwapRates(uint256 _swapRate, uint256 _swapAllRate) external;

    function createLimitTask(tccItem[] calldata _tccList) external payable;

    function createNormalTask(tccItem[] calldata _tccList, uint256 _ethAmount, uint256 _usdtAmount) external payable;

    function createGasTask(tccItem[] calldata _tccList, uint256 _ethAmount) external payable;

    function editTaskSwapAmountList(bytes32 _taskID, uint256[] memory _swapAmountList) external;

    function editTaskStartEndTime(bytes32 _taskID, uint256[] memory _start_end_Time) external;

    function editTaskTimeList(bytes32 _taskID, uint256[] memory _timeList) external;

    function editTaskTimeIntervalList(bytes32 _taskID, uint256[] memory _timeIntervalList) external;

    function editTaskLimit(bytes32 _taskID, uint256 _maxtxAmount, uint256 _maxSpendTokenAmount, uint256 _maxFeePerTx) external;

    function editLimitOrder(bytes32 _taskID, uint256 _minswapOutAmount) external;

    function swapToken(address _user, bytes32 _md5) external;

    function limitOrder(address _user, bytes32 _md5) external;

    function swapGasToken(address _user, bytes32 _md5) external;

    function cancelTask(bytes32 _taskID) external;

    function restartTask(bytes32 _taskID) external;

    function deposit(uint256 _usdtAmount, uint256 _devAmount) external payable;

    function withdraw(uint256 _usdtAmount, uint256 _ethAmount, uint256 _devAmount) external;

    function claimToken(IERC20 _token, uint256 _amount) external;

    function claimEth(uint256 _amount) external;

    function withdrawAll() external;

    function getUserTaskList(address _user) external view returns (bytes32[] memory _taskList);

    function getUserTaskListByList(address _user, uint256[] memory _indexList) external view returns (bytes32[] memory taskIdList);
}

contract limitOrderAndNormalSwapTokenProxy is OpsTaskCreator, Ownable {
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.Bytes32Set;
    address public WETH;
    IERC20 public USDT;
    IERC20 public devToken;
    uint256 public devFee;
    uint256 public swapRate = 100;
    uint256 public swapAllRate = 1000;
    uint256 public approveAmount;
    uint256 public taskAmount;
    USDTPool public USDTPoolAddress;
    mapping(uint256 => bytes32) public taskList;
    mapping(bytes32 => bool) public taskIdStatusList;
    mapping(address => userInfoItem) public userInfoList;
    mapping(address => bytes32[]) public userTaskList;
    mapping(bytes32 => bool) public md5List;
    mapping(bytes32 => bytes32) public md5TaskList;
    mapping(bytes32 => taskConfig) public taskConfigList;
    mapping(bytes32 => uint256) public lastExecutedTimeList;
    mapping(bytes32 => uint256) public lastTimeIntervalIndexList;
    mapping(bytes32 => uint256) public lastSwapAmountIndexList;
    mapping(bytes32 => mapping(uint256 => txItem)) public txHistoryList;
    mapping(address => bool) public dedicatedMsgSenderList;
    mapping(string => bool) public taskNameList;
    mapping(address => EnumerableSet.Bytes32Set) private userAllLimitOrderList;
    mapping(address => EnumerableSet.Bytes32Set) private userActiveLimitOrderList;
    mapping(address => EnumerableSet.Bytes32Set) private userAllSwapOrderList;
    mapping(address => EnumerableSet.Bytes32Set) private userActiveSwapOrderList;


    event createTaskEvent(uint256 _blockNumber, uint256 _timestamp, address _user, uint256 _taskAmount, bytes32 _taskId, orderType _type, tccItem _tcc);
    event OrderEvent(uint256 _blockNumber, uint256 _timestamp, orderType _type, address _user, bytes32 _taskID, address _caller, uint256 _fee, swapEventItem _swapEventItem);

    address public USDTOrderAddress;
    address public GasOrderAddress;
    address public LimitOrderAddress;
    address public OrderAdminAddress;

    function setUSDTOrderAddress(address _USDTOrderAddress) external onlyOwner {
        USDTOrderAddress = _USDTOrderAddress;
    }

    function setGasOrderAddress(address _GasOrderAddress) external onlyOwner {
        GasOrderAddress = _GasOrderAddress;
    }

    function setLimitOrderAddress(address _LimitOrderAddress) external onlyOwner {
        LimitOrderAddress = _LimitOrderAddress;
    }

    function setOrderAdminAddress(address _OrderAdminAddress) external onlyOwner {
        OrderAdminAddress = _OrderAdminAddress;
    }

    constructor(
        uint256 _approveAmount,
        address payable _ops,
        address _fundsOwner,
        USDTPool _USDTPoolAddress,
        address _WETH
    ) OpsTaskCreator(_ops, _fundsOwner){
        approveAmount = _approveAmount;
        USDTPoolAddress = _USDTPoolAddress;
        WETH = _WETH;
        USDT = _USDTPoolAddress.USDT();
        dedicatedMsgSenderList[dedicatedMsgSender] = true;
    }

    function _getRevertMsg(bool success, bytes memory result) private pure {
        if (!success) {
            if (result.length < 68) revert();
            assembly {
                result := add(result, 0x04)
            }
            revert(abi.decode(result, (string)));
        }
    }

    function createNormalTask(tccItem[] calldata _tccList, uint256 _ethAmount, uint256 _usdtAmount) external payable {
        (bool success,bytes memory result) = USDTOrderAddress.delegatecall(abi.encodeWithSelector(limitOrderAndNormalSwapToken.createNormalTask.selector, _tccList, _ethAmount, _usdtAmount));
        _getRevertMsg(success, result);
    }

    function swapToken(address _user, bytes32 _md5) external {
        (bool success,bytes memory result) = USDTOrderAddress.delegatecall(abi.encodeWithSelector(limitOrderAndNormalSwapToken.swapToken.selector, _user, _md5));
        _getRevertMsg(success, result);
    }

    function createGasTask(tccItem[] calldata _tccList, uint256 _ethAmount) external payable {
        (bool success,bytes memory result) = GasOrderAddress.delegatecall(abi.encodeWithSelector(limitOrderAndNormalSwapToken.createGasTask.selector, _tccList, _ethAmount));
        _getRevertMsg(success, result);
    }

    function swapGasToken(address _user, bytes32 _md5) external {
        (bool success,bytes memory result) = GasOrderAddress.delegatecall(abi.encodeWithSelector(limitOrderAndNormalSwapToken.swapGasToken.selector, _user, _md5));
        _getRevertMsg(success, result);
    }

    function createLimitTask(tccItem[] calldata _tccList) external payable {
        (bool success,bytes memory result) = LimitOrderAddress.delegatecall(abi.encodeWithSelector(limitOrderAndNormalSwapToken.createLimitTask.selector, _tccList));
        _getRevertMsg(success, result);
    }

    function limitOrder(address _user, bytes32 _md5) external {
        (bool success,bytes memory result) = LimitOrderAddress.delegatecall(abi.encodeWithSelector(limitOrderAndNormalSwapToken.limitOrder.selector, _user, _md5));
        _getRevertMsg(success, result);
    }

    function cancelTask(bytes32 _taskID) external {
        (bool success,bytes memory result) = OrderAdminAddress.delegatecall(abi.encodeWithSelector(limitOrderAndNormalSwapToken.cancelTask.selector, _taskID));
        _getRevertMsg(success, result);
    }

    function restartTask(bytes32 _taskID) external {
        (bool success,bytes memory result) = OrderAdminAddress.delegatecall(abi.encodeWithSelector(limitOrderAndNormalSwapToken.restartTask.selector, _taskID));
        _getRevertMsg(success, result);
    }

    function setDedicatedMsgSenderList(address _dedicatedMsgSender) public onlyOwner {
        (bool success,bytes memory result) = OrderAdminAddress.delegatecall(abi.encodeWithSelector(limitOrderAndNormalSwapToken.setDedicatedMsgSenderList.selector, _dedicatedMsgSender));
        _getRevertMsg(success, result);
    }

    function setDevTokenAndFee(IERC20 _devToken, uint256 _devFee) public onlyOwner {
        (bool success,bytes memory result) = OrderAdminAddress.delegatecall(abi.encodeWithSelector(limitOrderAndNormalSwapToken.setDevTokenAndFee.selector, _devToken, _devFee));
        _getRevertMsg(success, result);
    }

    function setDefaultSwapInfo(uint256 _approveAmount) public onlyOwner {
        (bool success,bytes memory result) = OrderAdminAddress.delegatecall(abi.encodeWithSelector(limitOrderAndNormalSwapToken.setDefaultSwapInfo.selector, _approveAmount));
        _getRevertMsg(success, result);
    }

    function setUSDTPoolAddress(USDTPool _USDTPoolAddress, address _WETH) public onlyOwner {
        (bool success,bytes memory result) = OrderAdminAddress.delegatecall(abi.encodeWithSelector(limitOrderAndNormalSwapToken.setUSDTPoolAddress.selector, _USDTPoolAddress, _WETH));
        _getRevertMsg(success, result);
    }

    function editTaskSwapAmountList(bytes32 _taskID, uint256[] memory _swapAmountList) external {
        (bool success,bytes memory result) = OrderAdminAddress.delegatecall(abi.encodeWithSelector(limitOrderAndNormalSwapToken.editTaskSwapAmountList.selector, _taskID, _swapAmountList));
        _getRevertMsg(success, result);
    }

    function editTaskStartEndTime(bytes32 _taskID, uint256[] memory _start_end_Time) external {
        (bool success,bytes memory result) = OrderAdminAddress.delegatecall(abi.encodeWithSelector(limitOrderAndNormalSwapToken.editTaskStartEndTime.selector, _taskID, _start_end_Time));
        _getRevertMsg(success, result);
    }

    function editTaskTimeList(bytes32 _taskID, uint256[] memory _timeList) external {
        (bool success,bytes memory result) = OrderAdminAddress.delegatecall(abi.encodeWithSelector(limitOrderAndNormalSwapToken.editTaskTimeList.selector, _taskID, _timeList));
        _getRevertMsg(success, result);
    }

    function editTaskTimeIntervalList(bytes32 _taskID, uint256[] memory _timeIntervalList) external {
        (bool success,bytes memory result) = OrderAdminAddress.delegatecall(abi.encodeWithSelector(limitOrderAndNormalSwapToken.editTaskTimeIntervalList.selector, _taskID, _timeIntervalList));
        _getRevertMsg(success, result);
    }

    function editTaskLimit(bytes32 _taskID, uint256 _maxtxAmount, uint256 _maxSpendTokenAmount, uint256 _maxFeePerTx) external {
        (bool success,bytes memory result) = OrderAdminAddress.delegatecall(abi.encodeWithSelector(limitOrderAndNormalSwapToken.editTaskLimit.selector, _taskID, _maxtxAmount, _maxSpendTokenAmount, _maxFeePerTx));
        _getRevertMsg(success, result);
    }

    function editLimitOrder(bytes32 _taskID, uint256 _minswapOutAmount) external {
        (bool success,bytes memory result) = OrderAdminAddress.delegatecall(abi.encodeWithSelector(limitOrderAndNormalSwapToken.editLimitOrder.selector, _taskID, _minswapOutAmount));
        _getRevertMsg(success, result);
    }

    function setSwapRates(uint256 _swapRate, uint256 _swapAllRate) external onlyOwner {
        (bool success,bytes memory result) = OrderAdminAddress.delegatecall(abi.encodeWithSelector(limitOrderAndNormalSwapToken.setSwapRates.selector, _swapRate, _swapAllRate));
        _getRevertMsg(success, result);
    }

    function deposit(uint256 _usdtAmount, uint256 _devAmount) external payable {
        (bool success,bytes memory result) = OrderAdminAddress.delegatecall(abi.encodeWithSelector(limitOrderAndNormalSwapToken.deposit.selector, _usdtAmount, _devAmount));
        _getRevertMsg(success, result);
    }

    function withdraw(uint256 _usdtAmount, uint256 _ethAmount, uint256 _devAmount) external {
        (bool success,bytes memory result) = OrderAdminAddress.delegatecall(abi.encodeWithSelector(limitOrderAndNormalSwapToken.withdraw.selector, _usdtAmount, _ethAmount, _devAmount));
        _getRevertMsg(success, result);
    }

    function withdrawAll() external {
        (bool success,bytes memory result) = OrderAdminAddress.delegatecall(abi.encodeWithSelector(limitOrderAndNormalSwapToken.withdrawAll.selector));
        _getRevertMsg(success, result);
    }

    function claimToken(IERC20 _token, uint256 _amount) external onlyOwner {
        (bool success,bytes memory result) = OrderAdminAddress.delegatecall(abi.encodeWithSelector(limitOrderAndNormalSwapToken.claimToken.selector, _token, _amount));
        _getRevertMsg(success, result);
    }

    function claimEth(uint256 _amount) external onlyOwner {
        (bool success,bytes memory result) = OrderAdminAddress.delegatecall(abi.encodeWithSelector(limitOrderAndNormalSwapToken.claimEth.selector, _amount));
        _getRevertMsg(success, result);
    }

    function getUserTaskList(address _user) external view returns (bytes32[] memory _taskList) {
        _taskList = userTaskList[_user];
    }

    function getUserAllOrderList(address _user, orderType _type) external view returns (bytes32[] memory _taskList) {
        _taskList = _type == orderType.LimitOrder ? userAllLimitOrderList[_user].values() : userAllSwapOrderList[_user].values();
    }

    function getUserAllOrderListByList(address _user, orderType _type, uint256[] memory _indexList) external view returns (bytes32[] memory _taskList) {
        _taskList = new bytes32[](_indexList.length);
        for (uint256 i = 0; i < _indexList.length; i++) {
            _taskList[i] = _type == orderType.LimitOrder ? userAllLimitOrderList[_user].at(_indexList[i]) : userAllSwapOrderList[_user].at(_indexList[i]);
        }
    }

    function getUserActiveOrderList(address _user, orderType _type) external view returns (bytes32[] memory _taskList) {
        _taskList = _type == orderType.LimitOrder ? userActiveLimitOrderList[_user].values() : userActiveSwapOrderList[_user].values();
    }

    function getUserActiveOrderListByList(address _user, orderType _type, uint256[] memory _indexList) external view returns (bytes32[] memory _taskList) {
        _taskList = new bytes32[](_indexList.length);
        for (uint256 i = 0; i < _indexList.length; i++) {
            _taskList[i] = _type == orderType.LimitOrder ? userActiveLimitOrderList[_user].at(_indexList[i]) : userActiveSwapOrderList[_user].at(_indexList[i]);
        }
    }

    function getUserTaskListByList(address _user, uint256[] memory _indexList) external view returns (bytes32[] memory _taskList) {
        _taskList = new bytes32[](_indexList.length);
        for (uint256 i = 0; i < _indexList.length; i++) {
            _taskList[i] = userTaskList[_user][_indexList[i]];
        }
    }

    receive() external payable {}
}