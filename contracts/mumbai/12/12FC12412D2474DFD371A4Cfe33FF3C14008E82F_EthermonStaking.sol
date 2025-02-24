/**
 *Submitted for verification at polygonscan.com on 2022-08-17
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
    mapping(address => bool) public moderators;
    bool public isMaintaining = false;

    constructor() public {
        owner = msgSender();
    }

    modifier onlyOwner() {
        require(msgSender() == owner);
        _;
    }

    modifier onlyModerators() {
        require(msgSender() == owner || moderators[msgSender()] == true);
        _;
    }

    modifier isActive() {
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
        uint64 lockId;
        uint16 level;
        uint8 validTeam;
        uint256 teamPower;
        uint16 badge;
        uint256 balance;
        Duration duration;
    }

    enum Duration {
        Days_30,
        Days_60,
        Days_90,
        Days_120,
        Days_180,
        Days_365
    }

    uint256 public decimal = 18;

    function setDecimal(uint256 _decimal) external onlyModerators {
        decimal = _decimal;
    }

    event Withdraw(address _from, address _to, uint256 _amount);
    event Deposite(address _from, address _to, uint256 _amount);
}

// File: contracts/EthermonStaking.sol

pragma solidity 0.6.6;
pragma experimental ABIEncoderV2;



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
        uint256 _lockId,
        uint8 _validTeam
    ) external;
}

interface EthermonWeightInterface {
    function getClassWeight(uint32 _classId)
        external
        view
        returns (uint256 weight);
}

contract EthermonStaking is EthermonStakingBasic {
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

    uint16[] daysToStake = [1, 30, 60, 90, 120, 180, 365];
    uint16[] daysAdvantage = [10, 11, 12, 13, 17, 25];
    uint16[] pfpRaritiesArr = [10, 12, 3, 4, 5, 6];
    uint16[] badgeAdvantageValues = [15, 13, 12];

    uint256 maxDepositeValue = 100000 * 10**decimal;
    uint256 minDepositeValue = 1000 * 10**decimal;
    uint8 public emonPerPeriod = 1;
    uint8 private rewardsCap = 100;
    bytes32 public appHash;

    address public stakingDataContract;
    address public ethermonWeightContract;

    IERC20 emon;

    constructor(
        address _stakingDataContract,
        address _ethermonWeightContract,
        address _emon
    ) public {
        stakingDataContract = _stakingDataContract;
        ethermonWeightContract = _ethermonWeightContract;
        emon = IERC20(_emon);
    }

    function setAppHash(bytes32 _appSecret) public onlyModerators {
        appHash = keccak256(abi.encodePacked(_appSecret));
    }

    function setContracts(
        address _stakingDataContract,
        address _ethermonWeightContract,
        address _emon
    ) public onlyModerators {
        stakingDataContract = _stakingDataContract;
        ethermonWeightContract = _ethermonWeightContract;
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

    function changeRewardCap(uint8 _rewardCap) external onlyModerators {
        require(_rewardCap > 0, "Invlaid reward cap value");
        rewardsCap = _rewardCap;
    }

    function depositeTokens(
        Duration _day,
        uint256 _amount,
        uint64 _monId,
        uint32 _classId,
        uint64 _lockId,
        uint16 _level,
        uint16 _createdIndex,
        bytes32 _appSecret
    ) external {
        require(
            keccak256(abi.encodePacked(_appSecret)) == appHash,
            "Application hash doesn't match"
        );

        EthermonStakingInterface stakingData = EthermonStakingInterface(
            stakingDataContract
        );

        address owner = msgSender();
        uint256 balance = emon.balanceOf(owner);
        require(
            balance >= minDepositeValue &&
                _amount >= minDepositeValue &&
                _amount <= maxDepositeValue,
            "Balance is not valid."
        );

        uint16 badgeAdvantage = (_createdIndex > 2)
            ? 10
            : badgeAdvantageValues[_createdIndex];

        uint256 currentTime = now;
        uint256 dayTime = currentTime + (daysToStake[uint8(_day)] * 1 minutes);

        TokenData memory data = stakingData.getTokenData(_lockId);
        require(data.monId == 0, "Token already exists");

        EthermonWeightInterface weight = EthermonWeightInterface(
            ethermonWeightContract
        );

        data.owner = owner;
        data.duration = _day;
        data.emons = _amount;
        data.lastCalled = currentTime;
        data.monId = _monId;
        data.endTime = dayTime;
        data.lockId = _lockId;
        data.badge = _createdIndex;
        data.level = _level;
        uint256 rarity = weight.getClassWeight(_classId);
        data.validTeam = 1;

        uint256 emonsInDecimal = data.emons / 10**decimal;
        data.teamPower =
            emonsInDecimal *
            data.level *
            rarity *
            daysAdvantage[uint8(data.duration)] *
            badgeAdvantage;

        uint256 teamPower = data.teamPower * 10**decimal;

        uint256 sumTeamPower = stakingData.SumTeamPower();
        uint256 hourlyEmon = (((teamPower / sumTeamPower) *
            emonPerPeriod *
            (currentTime - data.lastCalled)) / (1 minutes)) * data.validTeam;
        data.balance += hourlyEmon;
        bytes memory output = abi.encode(data);
        stakingData.addTokenData(output);

        emon.safeTransferFrom(msgSender(), address(this), data.emons);
        emit Deposite(owner, address(this), data.emons);
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

    function updateTokens(
        uint256 _lockId,
        uint16 _level,
        uint32 _classId,
        uint256 _badge,
        uint8 validTeam
    ) external onlyModerators {
        EthermonStakingInterface stakingData = EthermonStakingInterface(
            stakingDataContract
        );
        EthermonWeightInterface weightData = EthermonWeightInterface(
            ethermonWeightContract
        );
        uint256 currentTime = now;

        TokenData memory data = stakingData.getTokenData(_lockId);
        require(data.monId > 0 && _level > 0, "Data is not valid");

        uint256 timeElapsed = (currentTime - data.lastCalled) / (1 minutes);
        data.lastCalled = currentTime;

        uint256 teamPower = data.teamPower * 10**decimal;
        data.validTeam = validTeam;
        data.level = _level;
        uint256 rarity = weightData.getClassWeight(_classId);

        if (timeElapsed > 0 && currentTime > data.endTime) {
            require(rewardsCap > 0, "Reward cap reached max capacity");
            rewardsCap--;

            timeElapsed =
                timeElapsed -
                ((currentTime - data.endTime) / 1 minutes);

            data.balance +=
                (teamPower / stakingData.SumTeamPower()) *
                emonPerPeriod *
                timeElapsed *
                _level *
                rarity *
                data.validTeam *
                badgeAdvantageValues[_badge];

            data.emons += data.balance;

            if (emon.balanceOf(address(this)) >= data.emons) {
                emon.safeTransfer(data.owner, data.emons);
                //1000Emons
                stakingData.removeTokenData(_lockId);
                emit Withdraw(address(this), data.owner, data.emons);
            }
            return;
        }

        uint256 hourlyEmon = (teamPower / stakingData.SumTeamPower()) *
            emonPerPeriod *
            timeElapsed *
            _level *
            rarity *
            data.validTeam *
            badgeAdvantageValues[_badge];

        data.balance += hourlyEmon;
        uint256 lockId = _lockId;
        stakingData.updateTokenData(
            data.balance,
            data.lastCalled,
            lockId,
            data.validTeam
        );
        emit Deposite(data.owner, address(this), data.balance);
    }

    function withDrawRewards(uint256 _lockId) external {
        EthermonStakingInterface stakingData = EthermonStakingInterface(
            stakingDataContract
        );
        uint256 currentTime = now;

        TokenData memory data = stakingData.getTokenData(_lockId);
        require(data.monId != 0, "Data is not present");

        uint256 timeElapsed = (currentTime - data.lastCalled) / (1 minutes);
        data.lastCalled = currentTime;

        uint256 teamPower = data.teamPower * 10**decimal;

        if (timeElapsed > 0 && currentTime > data.endTime) {
            timeElapsed =
                timeElapsed -
                ((currentTime - data.endTime) / 1 minutes);

            data.balance +=
                (teamPower / stakingData.SumTeamPower()) *
                emonPerPeriod *
                timeElapsed *
                data.validTeam;

            data.emons += data.balance;

            emon.safeTransfer(data.owner, data.emons);

            stakingData.removeTokenData(_lockId);

            emit Withdraw(address(this), data.owner, data.emons);
        }
    }

    function updateStakingData(
        uint64 _lockId,
        uint64 _monId,
        uint16 _level,
        uint16 _createdIndex,
        bytes32 _appSecret
    ) external {
        require(
            keccak256(abi.encodePacked(_appSecret)) == appHash,
            "Application hash doesn't match"
        );

        EthermonStakingInterface stakingData = EthermonStakingInterface(
            stakingDataContract
        );

        TokenData memory data = stakingData.getTokenData(_lockId);
        require(data.owner == msgSender(), "PFP do not belongs to you.");
        require(data.monId > 0, "Staking data does not exists");

        data.monId = _monId;
        data.level = _level;
        data.badge = _createdIndex;

        bytes memory output = abi.encode(data);
        stakingData.addTokenData(output);
    }

    function depositeEmons(uint256 _amount) external {
        require(
            _amount > 0 && _amount <= emon.balanceOf(msgSender()),
            "Invalid amount"
        );
        emon.safeTransferFrom(msgSender(), address(this), _amount);
    }

    function withdrawEmon(address _sendTo) external onlyModerators {
        uint256 balance = emon.balanceOf(address(this));
        emon.safeTransfer(_sendTo, balance);
    }
}