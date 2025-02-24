/**
 *Submitted for verification at polygonscan.com on 2022-07-05
*/

// File: openzeppelin-solidity/contracts/token/ERC20/IERC20.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
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

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: openzeppelin-solidity/contracts/utils/Address.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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

// File: openzeppelin-solidity/contracts/token/ERC20/SafeERC20.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;



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
    using SafeMath for uint256;
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
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
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

// File: contracts/Context.sol

pragma solidity 0.6.6;


contract Context {
    function msgSender()
        internal
        view
        returns (address payable sender)
    {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
                // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender := and(
                    mload(add(array, index)),
                    0xffffffffffffffffffffffffffffffffffffffff
                )
            }
        } else {
            sender = msg.sender;
        }
        return sender;
    }
}

// File: contracts/BasicAccessControl.sol

pragma solidity 0.6.6;

contract BasicAccessControl is Context {
    address payable public owner;
    // address[] public moderators;
    uint16 public totalModerators = 0;
    mapping (address => bool) public moderators;
    bool public isMaintaining = false;

    constructor() public {
        owner = msgSender();
    }

    modifier onlyOwner {
    require(msgSender() == owner);
        _;
    }

    modifier onlyModerators() {
        require(msgSender() == owner || moderators[msgSender()] == true);
        _;
    }

    modifier isActive {
        require(!isMaintaining);
        _;
    }

    function ChangeOwner(address payable _newOwner) public onlyOwner {
        if (_newOwner != address(0)) {
            owner = _newOwner;
        }
    }


    function AddModerator(address _newModerator) public onlyOwner {
        if (moderators[_newModerator] == false) {
            moderators[_newModerator] = true;
            totalModerators += 1;
        }
    }

    function Kill() public onlyOwner {
        selfdestruct(owner);
    }
}

// File: contracts/EthermonStakingBasic.sol

pragma solidity 0.6.6;

contract EthermonStakingBasic is BasicAccessControl {
    struct TokenData {
        address owner;
        uint64 monId;
        uint256 emons;
        uint256 endTime;
        uint256 lastCalled;
        uint16 level;
        uint8 validTeam;
        uint256 teamPower;
        uint256 rarity;
        uint256 balance;
        Duration duration;
    }

    enum Duration {
        Days_30,
        Days_60,
        Days_90,
        Days_120,
        Days_180,
        Days_360
    }

    uint256 public decimal = 18;

    function setDecimal(uint256 _decimal) external onlyModerators {
        decimal = _decimal;
    }

    event Withdraw(address _from, address _to, uint256 _amount);
    event Deposite(address _from, address _to, uint256 _amount);
}

// File: contracts/EthermonEnum.sol

pragma solidity 0.6.6;

contract EthermonEnum {
    enum ResultCode {
        SUCCESS,
        ERROR_CLASS_NOT_FOUND,
        ERROR_LOW_BALANCE,
        ERROR_SEND_FAIL,
        ERROR_NOT_TRAINER,
        ERROR_NOT_ENOUGH_MONEY,
        ERROR_INVALID_AMOUNT
    }

    enum ArrayType {
        CLASS_TYPE,
        STAT_STEP,
        STAT_START,
        STAT_BASE,
        OBJ_SKILL
    }

    enum BattleResult {
        CASTLE_WIN,
        CASTLE_LOSE,
        CASTLE_DESTROYED
    }

    enum PropertyType {
        ANCESTOR,
        XFACTOR
    }
}

// File: contracts/EthermonDataBase.sol

pragma solidity 0.6.6;

interface EtheremonDataBase {

    // write
    function withdrawEther(address _sendTo, uint _amount) external returns(EthermonEnum.ResultCode);
    function addElementToArrayType(EthermonEnum.ArrayType _type, uint64 _id, uint8 _value) external returns(uint);
    function updateIndexOfArrayType(EthermonEnum.ArrayType _type, uint64 _id, uint _index, uint8 _value) external returns(uint);
    function setMonsterClass(uint32 _classId, uint256 _price, uint256 _returnPrice, bool _catchable) external returns(uint32);
    function addMonsterObj(uint32 _classId, address _trainer, string calldata _name) external returns(uint64);
    function setMonsterObj(uint64 _objId, string calldata _name, uint32 _exp, uint32 _createIndex, uint32 _lastClaimIndex) external;
    function increaseMonsterExp(uint64 _objId, uint32 amount) external;
    function decreaseMonsterExp(uint64 _objId, uint32 amount) external;
    function removeMonsterIdMapping(address _trainer, uint64 _monsterId) external;
    function addMonsterIdMapping(address _trainer, uint64 _monsterId) external;
    function clearMonsterReturnBalance(uint64 _monsterId) external returns(uint256 amount);
    function collectAllReturnBalance(address _trainer) external returns(uint256 amount);
    function transferMonster(address _from, address _to, uint64 _monsterId) external returns(EthermonEnum.ResultCode);
    function addExtraBalance(address _trainer, uint256 _amount) external returns(uint256);
    function deductExtraBalance(address _trainer, uint256 _amount) external returns(uint256);
    function setExtraBalance(address _trainer, uint256 _amount) external;
    
    // read
    function totalMonster() external view returns(uint256);
    function totalClass() external view returns(uint32);
    function getSizeArrayType(EthermonEnum.ArrayType _type, uint64 _id) external view returns(uint);
    function getElementInArrayType(EthermonEnum.ArrayType _type, uint64 _id, uint _index) external view returns(uint8);
    function getMonsterClass(uint32 _classId) external view returns(uint32 classId, uint256 price, uint256 returnPrice, uint32 total, bool catchable);
    function getMonsterObj(uint64 _objId) external view returns(uint64 objId, uint32 classId, address trainer, uint32 exp, uint32 createIndex, uint32 lastClaimIndex, uint createTime);
    function getMonsterName(uint64 _objId) external view returns(string memory name);
    function getExtraBalance(address _trainer) external view returns(uint256);
    function getMonsterDexSize(address _trainer) external view returns(uint);
    function getMonsterObjId(address _trainer, uint index) external view returns(uint64);
    function getExpectedBalance(address _trainer) external view returns(uint256);
    function getMonsterReturn(uint64 _objId) external view returns(uint256 current, uint256 total);
}

// File: contracts/EthermonTradeData.sol

pragma solidity >=0.6.0 <0.8.0;






contract EthermonTradeData is BasicAccessControl {
    using SafeMath for uint256;

    struct BorrowItem {
        uint256 index;
        address owner;
        address borrower;
        uint256 price;
        bool lent;
        uint256 releaseTime;
        uint256 createTime;
    }

    struct SellingItem {
        uint256 index;
        uint256 price;
        uint256 createTime;
    }

    mapping(uint64 => SellingItem) public sellingDict; // monster id => item
    uint64[] public sellingList; // monster id

    mapping(uint64 => BorrowItem) public borrowingDict;
    uint64[] public borrowingList;

    mapping(address => uint64[]) public lendingList;

    address[] public whiteListUsers;

    function removeSellingItem(uint64 _itemId) external onlyModerators {
        SellingItem storage item = sellingDict[_itemId];
        if (item.index == 0) return;

        if (item.index <= sellingList.length) {
            // Move an existing element into the vacated key slot.
            sellingDict[sellingList[sellingList.length - 1]].index = item.index;
            sellingList[item.index - 1] = sellingList[sellingList.length - 1];
            sellingList.pop();
            //sellingList.length -= 1;
            delete sellingDict[_itemId];
        }
    }

    function addWhiteListUsers(address _owner) external onlyModerators {
        require(_owner != address(0));

        whiteListUsers.push(_owner);
    }

    function removeWhiteListUsers(address _owner) external onlyModerators {
        require(_owner != address(0));

        uint256 foundIndex = 0;
        for (; foundIndex < whiteListUsers.length; foundIndex++) {
            if (whiteListUsers[foundIndex] == _owner) {
                break;
            }
        }
        if (foundIndex < whiteListUsers.length) {
            whiteListUsers[foundIndex] = whiteListUsers[
                whiteListUsers.length - 1
            ];
            whiteListUsers.pop();
        }
    }

    function isUserWhiteListed(address _owner)
        public
        view
        onlyModerators
        returns (bool)
    {
        for (
            uint256 foundIndex;
            foundIndex < whiteListUsers.length;
            foundIndex++
        ) {
            if (whiteListUsers[foundIndex] == _owner) return true;
        }
        return false;
    }

    function addSellingItem(
        uint64 _itemId,
        uint256 _price,
        uint256 _createTime
    ) external onlyModerators {
        SellingItem storage item = sellingDict[_itemId];
        item.price = _price;
        item.createTime = _createTime;

        if (item.index == 0) {
            sellingList.push(_itemId);
            item.index = sellingList.length;
            //item.index = ++sellingList.length;
            //sellingList[item.index - 1] = _itemId;
        }
    }

    function removeBorrowingItem(uint64 _itemId) external onlyModerators {
        BorrowItem storage item = borrowingDict[_itemId];
        if (item.index == 0) return;

        if (item.index <= borrowingList.length) {
            // Move an existing element into the vacated key slot.
            borrowingDict[borrowingList[borrowingList.length - 1]].index = item
                .index;
            borrowingList[item.index - 1] = borrowingList[
                borrowingList.length - 1
            ];
            borrowingList.pop();
            // borrowingList.length -= 1;
            delete borrowingDict[_itemId];
        }
    }

    function addBorrowingItem(
        address _owner,
        uint64 _itemId,
        uint256 _price,
        address _borrower,
        bool _lent,
        uint256 _releaseTime,
        uint256 _createTime
    ) external onlyModerators {
        BorrowItem storage item = borrowingDict[_itemId];
        item.owner = _owner;
        item.borrower = _borrower;
        item.price = _price;
        item.lent = _lent;
        item.releaseTime = _releaseTime;
        item.createTime = _createTime;

        if (item.index == 0) {
            borrowingList.push(_itemId);
            item.index = borrowingList.length;
            // item.index = ++borrowingList.length;
            // borrowingList[item.index - 1] = _itemId;
        }
    }

    function addItemLendingList(address _trainer, uint64 _objId)
        external
        onlyModerators
    {
        lendingList[_trainer].push(_objId);
    }

    function removeItemLendingList(address _trainer, uint64 _objId)
        external
        onlyModerators
    {
        uint256 foundIndex = 0;
        uint64[] storage objList = lendingList[_trainer];
        for (; foundIndex < objList.length; foundIndex++) {
            if (objList[foundIndex] == _objId) {
                break;
            }
        }
        if (foundIndex < objList.length) {
            objList[foundIndex] = objList[objList.length - 1];
            objList.pop();
            // delete objList[objList.length - 1];
            // objList.length--;
        }
    }

    // read access
    function isOnBorrow(uint64 _objId) external view returns (bool) {
        return (borrowingDict[_objId].index > 0);
    }

    function isOnSell(uint64 _objId) external view returns (bool) {
        return (sellingDict[_objId].index > 0);
    }

    function isOnLent(uint64 _objId) external view returns (bool) {
        return borrowingDict[_objId].lent;
    }

    function getSellPrice(uint64 _objId) external view returns (uint256) {
        return sellingDict[_objId].price;
    }

    function isOnTrading(uint64 _objId) external view returns (bool) {
        return ((borrowingDict[_objId].index > 0) ||
            (sellingDict[_objId].index > 0));
    }

    function getBorrowBasicInfo(uint64 _objId)
        external
        view
        returns (address owner, bool lent)
    {
        BorrowItem storage borrowItem = borrowingDict[_objId];
        return (borrowItem.owner, borrowItem.lent);
    }

    function getBorrowInfo(uint64 _objId)
        external
        view
        returns (
            uint256 index,
            address owner,
            address borrower,
            uint256 price,
            bool lent,
            uint256 createTime,
            uint256 releaseTime
        )
    {
        BorrowItem storage borrowItem = borrowingDict[_objId];
        return (
            borrowItem.index,
            borrowItem.owner,
            borrowItem.borrower,
            borrowItem.price,
            borrowItem.lent,
            borrowItem.createTime,
            borrowItem.releaseTime
        );
    }

    function getSellInfo(uint64 _objId)
        external
        view
        returns (
            uint256 index,
            uint256 price,
            uint256 createTime
        )
    {
        SellingItem storage item = sellingDict[_objId];
        return (item.index, item.price, item.createTime);
    }

    function getTotalSellingItem() external view returns (uint256) {
        return sellingList.length;
    }

    function getTotalBorrowingItem() external view returns (uint256) {
        return borrowingList.length;
    }

    function getTotalLendingItem(address _trainer)
        external
        view
        returns (uint256)
    {
        return lendingList[_trainer].length;
    }

    function getSellingInfoByIndex(uint256 _index)
        external
        view
        returns (
            uint64 objId,
            uint256 price,
            uint256 createTime
        )
    {
        objId = sellingList[_index];
        SellingItem storage item = sellingDict[objId];
        price = item.price;
        createTime = item.createTime;
    }

    function getBorrowInfoByIndex(uint256 _index)
        external
        view
        returns (
            uint64 objId,
            address owner,
            address borrower,
            uint256 price,
            bool lent,
            uint256 createTime,
            uint256 releaseTime
        )
    {
        objId = borrowingList[_index];
        BorrowItem storage borrowItem = borrowingDict[objId];
        return (
            objId,
            borrowItem.owner,
            borrowItem.borrower,
            borrowItem.price,
            borrowItem.lent,
            borrowItem.createTime,
            borrowItem.releaseTime
        );
    }

    function getLendingObjId(address _trainer, uint256 _index)
        external
        view
        returns (uint64)
    {
        return lendingList[_trainer][_index];
    }

    function getLendingInfo(address _trainer, uint256 _index)
        external
        view
        returns (
            uint64 objId,
            address owner,
            address borrower,
            uint256 price,
            bool lent,
            uint256 createTime,
            uint256 releaseTime
        )
    {
        objId = lendingList[_trainer][_index];
        BorrowItem storage borrowItem = borrowingDict[objId];
        return (
            objId,
            borrowItem.owner,
            borrowItem.borrower,
            borrowItem.price,
            borrowItem.lent,
            borrowItem.createTime,
            borrowItem.releaseTime
        );
    }

    function getTradingInfo(uint64 _objId)
        external
        view
        returns (
            uint256 sellingPrice,
            uint256 lendingPrice,
            bool lent,
            uint256 releaseTime,
            address owner,
            address borrower
        )
    {
        SellingItem storage item = sellingDict[_objId];
        sellingPrice = item.price;
        BorrowItem storage borrowItem = borrowingDict[_objId];
        lendingPrice = borrowItem.price;
        lent = borrowItem.lent;
        releaseTime = borrowItem.releaseTime;
        owner = borrowItem.owner;
        borrower = borrower;
    }
}

// File: contracts/EIP712Base.sol

pragma solidity 0.6.6;


contract EIP712Base {
    struct EIP712Domain {
        string name;
        string version;
        address verifyingContract;
        bytes32 salt;
    }

    string constant public ERC712_VERSION = "1";

    bytes32 internal constant EIP712_DOMAIN_TYPEHASH = keccak256(
        bytes(
            "EIP712Domain(string name,string version,address verifyingContract,bytes32 salt)"
        )
    );
    bytes32 internal domainSeperator;

    constructor(string memory name) public {
        _setDomainSeperator(name);
    }
    
    function _setDomainSeperator(string memory name) internal {
        domainSeperator = keccak256(
            abi.encode(
                EIP712_DOMAIN_TYPEHASH,
                keccak256(bytes(name)),
                keccak256(bytes(ERC712_VERSION)),
                address(this),
                bytes32(getChainId())
            )
        );
    }

    function getDomainSeperator() public view returns (bytes32) {
        return domainSeperator;
    }

    function getChainId() public pure returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }

    /**
     * Accept message hash and returns hash message in EIP712 compatible form
     * So that it can be used to recover signer from signature signed using EIP712 formatted data
     * https://eips.ethereum.org/EIPS/eip-712
     * "\\x19" makes the encoding deterministic
     * "\\x01" is the version byte to make it compatible to EIP-191
     */
    function toTypedMessageHash(bytes32 messageHash)
        internal
        view
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked("\x19\x01", getDomainSeperator(), messageHash)
            );
    }
}

// File: contracts/NativeMetaTransaction.sol

pragma solidity 0.6.6;


contract NativeMetaTransaction is EIP712Base {
    using SafeMath for uint256;
    bytes32 private constant META_TRANSACTION_TYPEHASH = keccak256(
        bytes(
            "MetaTransaction(uint256 nonce,address from,bytes functionSignature)"
        )
    );
    event MetaTransactionExecuted(
        address userAddress,
        address payable relayerAddress,
        bytes functionSignature
    );
    mapping(address => uint256) nonces;

    /*
     * Meta transaction structure.
     * No point of including value field here as if user is doing value transfer then he has the funds to pay for gas
     * He should call the desired function directly in that case.
     */
    struct MetaTransaction {
        uint256 nonce;
        address from;
        bytes functionSignature;
    }

    constructor(string memory name) public EIP712Base(name){
    }

    function executeMetaTransaction(
        address userAddress,
        bytes memory functionSignature,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) public payable returns (bytes memory) {
        MetaTransaction memory metaTx = MetaTransaction({
            nonce: nonces[userAddress],
            from: userAddress,
            functionSignature: functionSignature
        });

        require(
            verify(userAddress, metaTx, sigR, sigS, sigV),
            "Signer and signature do not match"
        );

        // increase nonce for user (to avoid re-use)
        nonces[userAddress] = nonces[userAddress].add(1);

        emit MetaTransactionExecuted(
            userAddress,
            msg.sender,
            functionSignature
        );

        // Append userAddress and relayer address at the end to extract it from calling context
        (bool success, bytes memory returnData) = address(this).call(
            abi.encodePacked(functionSignature, userAddress)
        );
        require(success, "Function call not successful");

        return returnData;
    }

    function hashMetaTransaction(MetaTransaction memory metaTx)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    META_TRANSACTION_TYPEHASH,
                    metaTx.nonce,
                    metaTx.from,
                    keccak256(metaTx.functionSignature)
                )
            );
    }

    function getNonce(address user) public view returns (uint256 nonce) {
        nonce = nonces[user];
    }

    function verify(
        address signer,
        MetaTransaction memory metaTx,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) internal view returns (bool) {
        require(signer != address(0), "NativeMetaTransaction: INVALID_SIGNER");
        return
            signer ==
            ecrecover(
                toTypedMessageHash(hashMetaTransaction(metaTx)),
                sigV,
                sigR,
                sigS
            );
    }
}

// File: contracts/EtheremonData.sol

pragma solidity 0.6.6;

// copyright [email protected]







contract SafeMathEthermon {
    function safeAdd(uint256 x, uint256 y) internal pure returns (uint256) {
        uint256 z = x + y;
        assert((z >= x) && (z >= y));
        return z;
    }

    function safeSubtract(uint256 x, uint256 y)
        internal
        pure
        returns (uint256)
    {
        assert(x >= y);
        uint256 z = x - y;
        return z;
    }

    function safeMult(uint256 x, uint256 y) internal pure returns (uint256) {
        uint256 z = x * y;
        assert((x == 0) || (z / x == y));
        return z;
    }
}

contract EtheremonData is
    EtheremonDataBase,
    NativeMetaTransaction,
    EthermonEnum,
    BasicAccessControl,
    SafeMathEthermon
{
    using SafeERC20 for IERC20;

    struct MonsterClass {
        uint32 classId;
        uint8[] types;
        uint8[] statSteps;
        uint8[] statStarts;
        uint256 price;
        uint256 returnPrice;
        uint32 total;
        bool catchable;
    }

    struct MonsterObj {
        uint64 monsterId;
        uint32 classId;
        address trainer;
        string name;
        uint32 exp;
        uint8[] statBases;
        uint8[] skills;
        uint32 createIndex;
        uint32 lastClaimIndex;
        uint256 createTime;
    }

    mapping(uint32 => MonsterClass) public monsterClass;
    mapping(uint64 => MonsterObj) public monsterWorld;
    mapping(address => uint64[]) public trainerDex;
    mapping(address => uint256) public trainerExtraBalance;

    uint32 public override totalClass;
    uint256 public override totalMonster;
    //wrapped ether on matic
    IERC20 public weth;

    constructor(string memory name, address _weth)
        public
        NativeMetaTransaction(name)
    {
        weth = IERC20(_weth);
    }

    // write access
    function withdrawEther(address _sendTo, uint256 _amount)
        public
        override
        onlyOwner
        returns (ResultCode)
    {
        uint256 balance = weth.balanceOf(address(this));

        if (_amount > balance) {
            return ResultCode.ERROR_INVALID_AMOUNT;
        }

        weth.safeTransfer(_sendTo, _amount);
        return ResultCode.SUCCESS;
    }

    function addElementToArrayType(
        ArrayType _type,
        uint64 _id,
        uint8 _value
    ) public override onlyModerators returns (uint256) {
        uint8[] storage array = monsterWorld[_id].statBases;
        if (_type == ArrayType.CLASS_TYPE) {
            array = monsterClass[uint32(_id)].types;
        } else if (_type == ArrayType.STAT_STEP) {
            array = monsterClass[uint32(_id)].statSteps;
        } else if (_type == ArrayType.STAT_START) {
            array = monsterClass[uint32(_id)].statStarts;
        } else if (_type == ArrayType.OBJ_SKILL) {
            array = monsterWorld[_id].skills;
        }
        array.push(_value);
        return array.length;
    }

    function updateIndexOfArrayType(
        ArrayType _type,
        uint64 _id,
        uint256 _index,
        uint8 _value
    ) public override onlyModerators returns (uint256) {
        uint8[] storage array = monsterWorld[_id].statBases;
        if (_type == ArrayType.CLASS_TYPE) {
            array = monsterClass[uint32(_id)].types;
        } else if (_type == ArrayType.STAT_STEP) {
            array = monsterClass[uint32(_id)].statSteps;
        } else if (_type == ArrayType.STAT_START) {
            array = monsterClass[uint32(_id)].statStarts;
        } else if (_type == ArrayType.OBJ_SKILL) {
            array = monsterWorld[_id].skills;
        }
        if (_index < array.length) {
            if (_value == 255) {
                // consider as delete
                for (uint256 i = _index; i < array.length - 1; i++) {
                    array[i] = array[i + 1];
                }
                array.pop();
            } else {
                array[_index] = _value;
            }
        }
    }

    function setMonsterClass(
        uint32 _classId,
        uint256 _price,
        uint256 _returnPrice,
        bool _catchable
    ) public override onlyModerators returns (uint32) {
        MonsterClass storage class = monsterClass[_classId];
        if (class.classId == 0) {
            totalClass += 1;
        }
        class.classId = _classId;
        class.price = _price;
        class.returnPrice = _returnPrice;
        class.catchable = _catchable;
        return totalClass;
    }

    function addMonsterObj(
        uint32 _classId,
        address _trainer,
        string memory _name
    ) public override onlyModerators returns (uint64) {
        MonsterClass storage class = monsterClass[_classId];
        if (class.classId == 0) return 0;

        // construct new monster
        totalMonster += 1;
        class.total += 1;

        MonsterObj storage obj = monsterWorld[uint64(totalMonster)];
        obj.monsterId = uint64(totalMonster);
        obj.classId = _classId;
        obj.trainer = _trainer;
        obj.name = _name;
        obj.exp = 1;
        obj.createIndex = class.total;
        obj.lastClaimIndex = class.total;
        obj.createTime = now;

        // add to monsterdex
        addMonsterIdMapping(_trainer, obj.monsterId);
        return obj.monsterId;
    }

    function setMonsterObj(
        uint64 _objId,
        string memory _name,
        uint32 _exp,
        uint32 _createIndex,
        uint32 _lastClaimIndex
    ) public override onlyModerators {
        MonsterObj storage obj = monsterWorld[_objId];
        if (obj.monsterId == _objId) {
            obj.name = _name;
            obj.exp = _exp;
            obj.createIndex = _createIndex;
            obj.lastClaimIndex = _lastClaimIndex;
        }
    }

    function increaseMonsterExp(uint64 _objId, uint32 amount)
        public
        override
        onlyModerators
    {
        MonsterObj storage obj = monsterWorld[_objId];
        if (obj.monsterId == _objId) {
            obj.exp = uint32(safeAdd(obj.exp, amount));
        }
    }

    function decreaseMonsterExp(uint64 _objId, uint32 amount)
        public
        override
        onlyModerators
    {
        MonsterObj storage obj = monsterWorld[_objId];
        if (obj.monsterId == _objId) {
            obj.exp = uint32(safeSubtract(obj.exp, amount));
        }
    }

    function removeMonsterIdMapping(address _trainer, uint64 _monsterId)
        public
        override
        onlyModerators
    {
        uint256 foundIndex = 0;
        uint64[] storage objIdList = trainerDex[_trainer];
        for (; foundIndex < objIdList.length; foundIndex++) {
            if (objIdList[foundIndex] == _monsterId) {
                break;
            }
        }
        if (foundIndex < objIdList.length) {
            //Passing last index to the index found and then delete to last index to avoid duplication.
            objIdList[foundIndex] = objIdList[objIdList.length - 1];
            objIdList.pop();
            MonsterObj storage monster = monsterWorld[_monsterId];
            monster.trainer = address(0);
        }
    }

    function addMonsterIdMapping(address _trainer, uint64 _monsterId)
        public
        override
        onlyModerators
    {
        if (_trainer != address(0) && _monsterId > 0) {
            uint64[] storage objIdList = trainerDex[_trainer];
            for (uint256 i = 0; i < objIdList.length; i++) {
                if (objIdList[i] == _monsterId) {
                    return;
                }
            }
            objIdList.push(_monsterId);
            MonsterObj storage monster = monsterWorld[_monsterId];
            monster.trainer = _trainer;
        }
    }

    function clearMonsterReturnBalance(uint64 _monsterId)
        public
        override
        onlyModerators
        returns (uint256)
    {
        MonsterObj storage monster = monsterWorld[_monsterId];
        MonsterClass storage class = monsterClass[monster.classId];
        if (monster.monsterId == 0 || class.classId == 0) return 0;
        uint256 amount = 0;
        uint32 gap = uint32(safeSubtract(class.total, monster.lastClaimIndex));
        if (gap > 0) {
            monster.lastClaimIndex = class.total;
            amount = safeMult(gap, class.returnPrice);
            trainerExtraBalance[monster.trainer] = safeAdd(
                trainerExtraBalance[monster.trainer],
                amount
            );
        }
        return amount;
    }

    function collectAllReturnBalance(address _trainer)
        public
        override
        onlyModerators
        returns (uint256 amount)
    {
        uint64[] storage objIdList = trainerDex[_trainer];
        for (uint256 i = 0; i < objIdList.length; i++) {
            clearMonsterReturnBalance(objIdList[i]);
        }
        return trainerExtraBalance[_trainer];
    }

    function transferMonster(
        address _from,
        address _to,
        uint64 _monsterId
    ) public override onlyModerators returns (ResultCode) {
        MonsterObj storage monster = monsterWorld[_monsterId];
        if (monster.trainer != _from) {
            return ResultCode.ERROR_NOT_TRAINER;
        }

        clearMonsterReturnBalance(_monsterId);

        removeMonsterIdMapping(_from, _monsterId);
        addMonsterIdMapping(_to, _monsterId);
        return ResultCode.SUCCESS;
    }

    function addExtraBalance(address _trainer, uint256 _amount)
        public
        override
        onlyModerators
        returns (uint256)
    {
        trainerExtraBalance[_trainer] = safeAdd(
            trainerExtraBalance[_trainer],
            _amount
        );
        return trainerExtraBalance[_trainer];
    }

    function deductExtraBalance(address _trainer, uint256 _amount)
        public
        override
        onlyModerators
        returns (uint256)
    {
        trainerExtraBalance[_trainer] = safeSubtract(
            trainerExtraBalance[_trainer],
            _amount
        );
        return trainerExtraBalance[_trainer];
    }

    function setExtraBalance(address _trainer, uint256 _amount)
        public
        override
        onlyModerators
    {
        trainerExtraBalance[_trainer] = _amount;
    }

    //Replacement for ETH fallback method on Matic
    function depositEth(uint256 amount) public {
        //user will have to approve this contract first
        weth.safeTransferFrom(msgSender(), address(this), amount);
        addExtraBalance(msgSender(), amount);
    }

    // public
    /**receive () external {
        addExtraBalance(msgSender(), msg.value);
    }*/

    // read access
    function getSizeArrayType(ArrayType _type, uint64 _id)
        public
        view
        override
        returns (uint256)
    {
        uint8[] storage array = monsterWorld[_id].statBases;
        if (_type == ArrayType.CLASS_TYPE) {
            array = monsterClass[uint32(_id)].types;
        } else if (_type == ArrayType.STAT_STEP) {
            array = monsterClass[uint32(_id)].statSteps;
        } else if (_type == ArrayType.STAT_START) {
            array = monsterClass[uint32(_id)].statStarts;
        } else if (_type == ArrayType.OBJ_SKILL) {
            array = monsterWorld[_id].skills;
        }
        return array.length;
    }

    function getElementInArrayType(
        ArrayType _type,
        uint64 _id,
        uint256 _index
    ) public view override returns (uint8) {
        uint8[] storage array = monsterWorld[_id].statBases;
        if (_type == ArrayType.CLASS_TYPE) {
            array = monsterClass[uint32(_id)].types;
        } else if (_type == ArrayType.STAT_STEP) {
            array = monsterClass[uint32(_id)].statSteps;
        } else if (_type == ArrayType.STAT_START) {
            array = monsterClass[uint32(_id)].statStarts;
        } else if (_type == ArrayType.OBJ_SKILL) {
            array = monsterWorld[_id].skills;
        }
        if (_index >= array.length) return 0;
        return array[_index];
    }

    function getMonsterClass(uint32 _classId)
        public
        view
        override
        returns (
            uint32 classId,
            uint256 price,
            uint256 returnPrice,
            uint32 total,
            bool catchable
        )
    {
        MonsterClass storage class = monsterClass[_classId];
        classId = class.classId;
        price = class.price;
        returnPrice = class.returnPrice;
        total = class.total;
        catchable = class.catchable;
    }

    function getMonsterObj(uint64 _objId)
        public
        view
        override
        returns (
            uint64 objId,
            uint32 classId,
            address trainer,
            uint32 exp,
            uint32 createIndex,
            uint32 lastClaimIndex,
            uint256 createTime
        )
    {
        MonsterObj storage monster = monsterWorld[_objId];
        objId = monster.monsterId;
        classId = monster.classId;
        trainer = monster.trainer;
        exp = monster.exp;
        createIndex = monster.createIndex;
        lastClaimIndex = monster.lastClaimIndex;
        createTime = monster.createTime;
    }

    function getMonsterName(uint64 _objId)
        public
        view
        override
        returns (string memory name)
    {
        return monsterWorld[_objId].name;
    }

    function getExtraBalance(address _trainer)
        public
        view
        override
        returns (uint256)
    {
        return trainerExtraBalance[_trainer];
    }

    function getMonsterDexSize(address _trainer)
        public
        view
        override
        returns (uint256)
    {
        return trainerDex[_trainer].length;
    }

    function getMonsterObjId(address _trainer, uint256 index)
        public
        view
        override
        returns (uint64)
    {
        if (index >= trainerDex[_trainer].length) return 0;
        return trainerDex[_trainer][index];
    }

    function getExpectedBalance(address _trainer)
        public
        view
        override
        returns (uint256)
    {
        uint64[] storage objIdList = trainerDex[_trainer];
        uint256 monsterBalance = 0;
        for (uint256 i = 0; i < objIdList.length; i++) {
            MonsterObj memory monster = monsterWorld[objIdList[i]];
            MonsterClass storage class = monsterClass[monster.classId];
            uint32 gap = uint32(
                safeSubtract(class.total, monster.lastClaimIndex)
            );
            monsterBalance += safeMult(gap, class.returnPrice);
        }
        return monsterBalance;
    }

    function getMonsterReturn(uint64 _objId)
        public
        view
        override
        returns (uint256 current, uint256 total)
    {
        MonsterObj memory monster = monsterWorld[_objId];
        MonsterClass storage class = monsterClass[monster.classId];
        uint32 totalGap = uint32(
            safeSubtract(class.total, monster.createIndex)
        );
        uint32 currentGap = uint32(
            safeSubtract(class.total, monster.lastClaimIndex)
        );
        return (
            safeMult(currentGap, class.returnPrice),
            safeMult(totalGap, class.returnPrice)
        );
    }
}

// File: contracts/EthermonStaking.sol

pragma solidity 0.6.6;
pragma experimental ABIEncoderV2; //Need to remove this from flattened file.






// Insert Data contract and trading contract here

interface EthermonDataInterface {
    function getMonsterObj(uint64 _objId)
        external
        view
        returns (
            uint64 objId,
            uint32 classId,
            address trainer,
            uint32 exp,
            uint32 createIndex,
            uint32 lastClaimIndex,
            uint256 createTime
        );

    function getElementInArrayType(
        EthermonEnum.ArrayType _type,
        uint64 _id,
        uint256 _index
    ) external view returns (uint8);
}

interface EthermonStakingInterface {
    function SumTeamPower() external returns (uint256);

    function addTokenData(bytes calldata _data) external;

    function getTokenData(uint256 _pfpTokenId)
        external
        returns (EthermonStakingBasic.TokenData memory);

    function removeTokenData(uint256 _lockId) external;

    function updateTokenData(
        uint256 _balance,
        uint256 _lastCalled,
        uint8 _validTeam,
        uint256 _lockId
    ) external;
}

interface EthermonTradeDataInterface {
    function addBorrowingItem(
        address _owner,
        uint64 _itemId,
        uint256 _price,
        address _borrower,
        bool _lent,
        uint256 _releaseTime,
        uint256 _createTime
    ) external;

    function removeBorrowingItem(uint64 _itemId) external;

    function isOnBorrow(uint64 _objId) external view returns (bool);
}

contract EthermonStaking is EthermonStakingBasic, EthermonEnum {
    using SafeERC20 for IERC20;
    struct MonsterObjAcc {
        uint64 monsterId;
        uint32 classId;
        address trainer;
        uint32 exp;
        uint32 createIndex;
        uint32 lastClaimIndex;
        uint256 createTime;
    }

    mapping(uint16 => uint256) public LEVEL_REQUIREMENT;
    uint16 constant MAX_LEVEL = 100;
    uint8 constant STAT_COUNT = 6;
    // These are multiple of 10 will change it to more if required
    uint16[] daysToStake = [1, 30, 60, 90, 120, 180, 360];
    uint16[] daysAdvantage = [10, 11, 12, 13, 17, 25];
    uint16[] badgeAdvantageValues = [15, 13, 12];
    uint16[] pfpRaritiesArr = [10, 12, 3, 4, 5, 6];

    uint256 minDepositeValue = 1000 * 10**decimal;
    uint256 maxDepositeValue = 100000 * 10**decimal;
    uint8 public emonPerPeriod = emonPerPeriod;

    address public stakingDataContract;
    //address public tradeDataContract;
    address public ethermonDataContract;

    IERC20 emon;

    constructor(
        address _stakingDataContract,
        //address _tradeDataContract,
        address _ethermonDataContract,
        address _emon
    ) public {
        stakingDataContract = _stakingDataContract;
        //tradeDataContract = _tradeDataContract;
        ethermonDataContract = _ethermonDataContract;
        emon = IERC20(_emon);
        genLevelExp();
    }

    function setContracts(address _stakingDataContract, address _emon)
        public
        onlyModerators
    {
        stakingDataContract = _stakingDataContract;
        emon = IERC20(_emon);
    }

    function setEmonPerPeriod(uint8 _emonPerPeriod) external onlyModerators {
        emonPerPeriod = _emonPerPeriod;
    }

    function setDepositeValues(
        uint256 _minDepositeValue,
        uint256 _maxDepositeValue
    ) public onlyModerators {
        minDepositeValue = _minDepositeValue;
        maxDepositeValue = _maxDepositeValue;
    }

    function depositeTokens(
        Duration _day,
        uint256 _amount,
        uint64 _monId
    ) external {
        EthermonStakingInterface stakingData = EthermonStakingInterface(
            stakingDataContract
        );

        EthermonDataInterface ethermonData = EthermonDataInterface(
            ethermonDataContract
        );

        MonsterObjAcc memory obj;
        (
            obj.monsterId,
            obj.classId,
            obj.trainer,
            obj.exp,
            obj.createIndex,
            obj.lastClaimIndex,
            obj.createTime
        ) = ethermonData.getMonsterObj(_monId);

        // EthermonTradeDataInterface ethermonTadeData = EthermonTradeDataInterface(
        //         tradeDataContract
        //     );
        // require(
        //     !ethermonTadeData.isOnBorrow(_monId) && obj.trainer == _owner,
        //     "Either you mon is already on stake or borrowed by someone else."
        // );
        address owner = msgSender();
        uint256 balance = emon.balanceOf(owner);

        require(
            balance >= minDepositeValue &&
                _amount >= minDepositeValue &&
                _amount <= maxDepositeValue,
            "Balance is not valid."
        );
        uint16 badgeAdvantage = (obj.createIndex > 2)
            ? 10
            : badgeAdvantageValues[obj.createIndex];

        uint256[6] memory baseStats;
        for (uint256 i = 0; i < STAT_COUNT; i += 1) {
            baseStats[i] = ethermonData.getElementInArrayType(
                EthermonEnum.ArrayType.STAT_BASE,
                obj.monsterId,
                i
            );
        }

        uint256[6] memory startStats;
        for (uint256 i = 0; i < STAT_COUNT; i += 1) {
            startStats[i] = ethermonData.getElementInArrayType(
                EthermonEnum.ArrayType.STAT_START,
                obj.monsterId,
                i
            );
        }
        uint256 currentTime = now;
        uint256 dayTime = currentTime + (daysToStake[uint8(_day)] * 1 minutes);

        TokenData memory data;
        data.owner = owner;
        data.duration = _day;
        data.emons = _amount;
        data.lastCalled = currentTime;
        data.monId = obj.monsterId;
        data.endTime = dayTime;
        data.level = getLevel(obj.exp);
        data.rarity = getBP(baseStats, startStats, data.level); //This would be mon rarity instead of PFP rarity.
        data.validTeam = 1; //When person stakes is checked from backend if team is already valid or not so we can throw exception there.

        uint256 emonsInDecimal = data.emons / 10**decimal;
        data.teamPower =
            emonsInDecimal *
            data.level *
            data.rarity *
            daysAdvantage[uint8(data.duration)] *
            badgeAdvantage;

        uint256 teamPower = data.teamPower * 10**decimal;

        uint256 sumTeamPower = stakingData.SumTeamPower();
        uint256 hourlyEmon = (((teamPower / sumTeamPower) *
            emonPerPeriod *
            (currentTime - data.lastCalled)) / (1 minutes)) * data.validTeam;
        data.balance += hourlyEmon; //This would be 0 as timeElapsed is 0

        // ethermonTadeData.addBorrowingItem(
        //     obj.trainer,
        //     obj.monsterId,
        //     0,
        //     owner,
        //     true,
        //     dayTime,
        //     currentTime
        // );
        emon.safeTransfer(address(this), data.emons);
        emit Deposite(owner, address(this), data.emons);

        bytes memory output = abi.encode(data);

        stakingData.addTokenData(output);
    }

    function genLevelExp() private {
        uint16 level = 1;
        uint16 requirement = 100;
        uint256 sum = requirement;
        while (level <= MAX_LEVEL) {
            LEVEL_REQUIREMENT[level] = sum;
            level += 1;
            requirement = (requirement * 11) / 10 + 5;
            sum += requirement;
        }
    }

    function getLevel(uint32 exp) private returns (uint16) {
        if (LEVEL_REQUIREMENT[1] == 0) genLevelExp();

        uint16 minIndex = 1;
        uint16 maxIndex = 100;
        uint16 currentIndex = 0;

        while (minIndex < maxIndex) {
            currentIndex = (minIndex + maxIndex) / 2;
            if (exp < LEVEL_REQUIREMENT[currentIndex]) maxIndex = currentIndex;
            else minIndex = currentIndex + 1;
        }
        return minIndex;
    }

    function getBP(
        uint256[6] memory _baseStats,
        uint256[6] memory _startStats,
        uint256 _level
    ) private pure returns (uint256) {
        uint256 bp = 0;
        for (uint256 index = 0; index < _baseStats.length; index++) {
            bp += _baseStats[index] + _level * _startStats[index] * 3;
        }
        bp /= 6;
        return bp;
    }

    function updateTokens(uint256 _lockId, uint8 validTeam)
        external
        onlyModerators
    {
        EthermonStakingInterface stakingData = EthermonStakingInterface(
            stakingDataContract
        );
        uint256 currentTime = now;

        TokenData memory data = stakingData.getTokenData(_lockId);
        require(data.monId != 0, "Data is not present");

        EthermonDataInterface ethermonData = EthermonDataInterface(
            ethermonDataContract
        );

        // EthermonTradeDataInterface ethermonTadeData = EthermonTradeDataInterface(
        //         tradeDataContract
        //     );

        MonsterObjAcc memory obj;
        (
            obj.monsterId,
            obj.classId,
            obj.trainer,
            obj.exp,
            obj.createIndex,
            obj.lastClaimIndex,
            obj.createTime
        ) = ethermonData.getMonsterObj(data.monId);

        uint256 timeElapsed = (currentTime - data.lastCalled) / (1 minutes);
        data.lastCalled = currentTime;

        // When time is passed transfer rewards will have to see if need to do it manually
        uint256 teamPower = data.teamPower * 10**decimal;
        data.validTeam = validTeam;

        if (timeElapsed > 0 && currentTime > data.endTime) {
            //7                         // 32 - 28 = 5
            timeElapsed =
                timeElapsed -
                ((currentTime - data.endTime) / 1 minutes);

            data.balance +=
                (teamPower / stakingData.SumTeamPower()) *
                emonPerPeriod * //emonPerPeriod would be changeable by mod
                timeElapsed *
                data.validTeam;

            data.emons += data.balance;

            //PFP-TOKEN: 101
            //PFP - 102 // jamie
            //PFP - 102 // Mohib

            // Get doesn't eat gas
            //
            // EMONA + PFP => onlyMod
            // EMON => public

            //CAN_DO: We can ask user to add token into the contract first and that emon have token_id to it and this will only store value doesn't
            //transfer it to this contract.Then in order to start staking user have to do another call which will transfer emons from user account
            //to this contract and this call will also accepts EMONA and PFP and we will provide record according to it.

            //For checking cross chain we can do PFP off chain as it the only on that may cause issue with verifing

            emon.safeTransferFrom(address(this), data.owner, data.emons);
            //1000Emons
            //ethermonTadeData.removeBorrowingItem(data.monId);
            stakingData.removeTokenData(_lockId);

            emit Withdraw(address(this), data.owner, data.emons);

            return;
        }

        uint256 hourlyEmon = (teamPower / stakingData.SumTeamPower()) *
            emonPerPeriod *
            timeElapsed *
            data.validTeam;
        data.balance += hourlyEmon;

        //emonsOnly = 1 || 0 * emons * data.level * data.rarity * data.lastCalled * data.badgeAdvantage
        //if(G15=1,0,F15*I15*J15*H15*K15)

        //bytes memory output = abi.encode(data);
        stakingData.updateTokenData(
            data.balance,
            data.lastCalled,
            data.validTeam,
            _lockId
        );
        emit Deposite(data.owner, address(this), data.balance);
    }

    //TOOD: Seprate function to withdraw for users.
    function withDrawRewards(uint256 _lockId) external {
        EthermonStakingInterface stakingData = EthermonStakingInterface(
            stakingDataContract
        );
        uint256 currentTime = now;

        TokenData memory data = stakingData.getTokenData(_lockId);
        require(data.monId != 0, "Data is not present");

        EthermonDataInterface ethermonData = EthermonDataInterface(
            ethermonDataContract
        );

        MonsterObjAcc memory obj;
        (
            obj.monsterId,
            obj.classId,
            obj.trainer,
            obj.exp,
            obj.createIndex,
            obj.lastClaimIndex,
            obj.createTime
        ) = ethermonData.getMonsterObj(data.monId);

        uint256 timeElapsed = (currentTime - data.lastCalled) / (1 minutes);
        data.lastCalled = currentTime;

        // When time is passed transfer rewards will have to see if need to do it manually
        uint256 teamPower = data.teamPower * 10**decimal;

        if (timeElapsed > 0 && currentTime > data.endTime) {
            //7                         // 32 - 28 = 5
            timeElapsed =
                timeElapsed -
                ((currentTime - data.endTime) / 1 minutes);

            data.balance +=
                (teamPower / stakingData.SumTeamPower()) *
                emonPerPeriod * //emonPerPeriod would be changeable by mod
                timeElapsed *
                data.validTeam;

            data.emons += data.balance;

            emon.safeTransferFrom(address(this), data.owner, data.emons);

            stakingData.removeTokenData(_lockId);

            emit Withdraw(address(this), data.owner, data.emons);
        }
    }

    function depositeEmons(uint256 _amount) external {
        require(
            _amount > 0 && _amount <= emon.balanceOf(msgSender()),
            "Invalid amount"
        );
        emon.safeTransfer(address(this), _amount);
    }
}