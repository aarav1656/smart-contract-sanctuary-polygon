/**
 *Submitted for verification at polygonscan.com on 2022-08-18
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0.0;

// File: @openzeppelin\contracts\token\ERC20\IERC20.sol
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)
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
// File: @openzeppelin\contracts\utils\Address.sol
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)
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
// File: @openzeppelin\contracts\token\ERC20\utils\SafeERC20.sol
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)
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
// File: @openzeppelin\contracts\utils\Context.sol
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)
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
// File: @openzeppelin\contracts\access\Ownable.sol
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)
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
// File: contracts\vesting\Interfaces\IVestingFlex.sol
interface IVestingFlex  {
    event VestingCreated(address indexed who, uint256 indexed which, Vesting vesting);
    event VestingReduced(address indexed who, uint256 indexed which, uint256 amountBefore, uint256 amountAfter);
    event Retrieved(address indexed who, uint256 amount);
    event OwnerRevokeDisabled(address indexed who, uint256 indexed which);
    event OwnerRevokeDisabledGlobally(uint256 indexed time);
    struct Vesting {
        uint128 vestedTotal;
        uint128 claimedTotal;
        uint48 start;
        uint48 duration;
        uint48 cliff;          // % of tokens to be released ahead of startTime: 1_000_000_000 => 100%
        uint48 cliffDelay;     // the cliff can be retrieved this many seconds before StartTime of the schedule
        uint48 exp;        // exponent, form of the release, 0 => instant, when timeestmp == `end`; 1 => linear; 2 => quadratice etc.
        bool revokable;
    }
    // beneficiary retrieve
    function retrieve(uint256 which) external returns(uint256);
    // OWNER
    function createVestings(address from, address[] calldata recipients, Vesting[] calldata vestings) external;
    function reduceVesting(address who, uint256 which, uint128 amountToReduceTo, bool revokeComplete, address tokenReceiver) external;
    function disableOwnerRevokeGlobally() external;
    function disableOwnerRevoke(address who, uint256 which) external;
    // external view
    function getReleasedAt(address who, uint256 which, uint256 timestamp) external view returns(uint256);
    function getReleased(address who, uint256 which) external view returns(uint256);
    function getClaimed(address who, uint256 which) external view returns(uint256);
    function getClaimableAtTimestamp(address who, uint256 which, uint256 when) external view returns(uint256);
    function getClaimableNow(address who, uint256 which) external view returns(uint256);
    function getNumberOfVestings(address who) external view returns(uint256);
    function getVesting(address who, uint256 which) external view returns(Vesting memory);
    function canAdminRevoke(address who, uint256 which) external view returns(bool);
    function token() external view returns(address);
}
// File: contracts\vesting\MGH_VESTING_INITIATORS.sol
pragma solidity ^0.8.0.0;
/// @notice DO NOT SEND TOKENS TO THIS CONTRACT
contract MGH_VESTING_INITIATORS is Ownable {
    using SafeERC20 for IERC20;
    struct Vesting {
        uint128 vested;
        uint128 claimed;
        uint256 lastRewardClaimed;
    }
    struct Staking {
        uint128 reward;
        uint128 claimed;
        mapping(address => bool) claimedByRecipient;
    }
    uint256 public immutable START;
    uint256 public immutable DURATION;
    uint256 public immutable CLIFF;          // % of tokens to be released ahead of startTime: 1_000_000_000 => 100%
    uint256 public immutable CLIFF_DELAY;     // the cliff can be retrieved this many seconds before StartTime of the schedule
    uint256 public immutable EXP;        // exponent, form of the release, 0 => instant, when timeestmp == `end`; 1 => linear; 2 => quadratice etc.
    bool public adminCanRevokeGlobal = true;
    string constant private ZERO_VALUE = "param is zero, when it should not";
    uint256 constant private PRECISISION = 1_000_000_000;
    address public immutable token;
    mapping(address => Vesting) private _vestingByUser;
    mapping(uint256 => Staking) private _stakingRewards;
    uint128 vestedTotal;
    uint128 claimedTotal;
    uint256 stakingDelay = 1 days;
    address private _revenueSplitter;
    constructor(
        address _token,
        address _owner,
        uint256 _start,
        uint256 _duration,
        uint256 _cliff,
        uint256 _cliffDelay,
        uint256 _exp
    ) {
        token = _token;
        START = _start;
        DURATION = _duration;
        CLIFF = _cliff;
        CLIFF_DELAY = _cliffDelay;
        EXP = _exp;
        _transferOwnership(_owner);
    }
    //// USER ////
    /// @notice sends all vested tokens to the vesting who
    /// @notice call `getClaimableNow()` to see the amount of available tokens
    function retrieve() external {
        _retrieve(msg.sender);
    }
    function retrieveStakingRewards(address recipient, uint256[] calldata timestamps) external {
        uint256 userVestedAmount = _vestingByUser[recipient].vested;
        uint256 totalVestedAmount = vestedTotal;
        uint256 totalPayment;
        for (uint256 i = 0; i < timestamps.length; i++) {
            Staking storage stk  = _stakingRewards[timestamps[i]];
            uint256 reward = stk.reward;
            uint256 claimed = stk.claimed;
            require(block.timestamp > timestamps[i] + stakingDelay, "too early");
            require(! stk.claimedByRecipient[recipient], "already claimed");
            stk.claimedByRecipient[recipient] = true;
            if(reward <= claimed) continue;
            uint256 rewardForUser = reward * userVestedAmount / totalVestedAmount;
            rewardForUser = (rewardForUser + claimed) > reward ? reward - claimed : rewardForUser;
            totalPayment += rewardForUser;
            stk.claimed = uint128(claimed + rewardForUser);
        }
        _processPayment(address(this), recipient, totalPayment);
    }
    //// OWNER ////
    /// @notice create multiple vestings at once for different beneficiaries
    /// @param patron the one paying for the Vestings 
    /// @param beneficiaries the recipients of `vestings` in the same order
    /// @param vestings the vesting schedules in order for recipients
    function createVestings(address patron, address[] calldata beneficiaries, Vesting[] calldata vestings) external onlyOwner {
        require(beneficiaries.length == vestings.length, "length mismatch");
        uint256 totalAmount;
        for(uint256 i = 0; i < vestings.length; i++) {
            address who = beneficiaries[i];
            Vesting calldata vesting = vestings[i];
            totalAmount += vesting.vested;
            _setVesting(who, vesting);
        }
        _processPayment(patron, address(this), totalAmount);
        vestedTotal += uint128(totalAmount);
    }
    /// @notice reduces the vested amount and sends the difference in tokens to `tokenReceiver`
    /// @param who address that the tokens are vested for
    /// @param amountToReduceTo new total amount for the vesting
    /// @param tokenReceiver address receiving the tokens that are not needed for vesting anymore
    function reduceVesting(
        address who, 
        uint128 amountToReduceTo, 
        address tokenReceiver
    ) external onlyOwner {
        require(adminCanRevokeGlobal, "admin not allowed anymore");
        Vesting storage vesting = _vestingByUser[who];
        uint128 amountBefore = vesting.vested;
        // we give what was already released to `who`
        _retrieve(who);
        require(amountToReduceTo >= vesting.claimed, "cannot reduce, already claimed");
        require(amountBefore > amountToReduceTo, "must reduce");
        vesting.vested = amountToReduceTo;
        vestedTotal = vestedTotal - amountBefore + amountToReduceTo;
        _processPayment(address(this), tokenReceiver, amountBefore - amountToReduceTo);
        emit VestingReduced(who, amountBefore, amountToReduceTo);
    }
    /// @notice when this function is called once, the owner of this
    ///         contract cannot revoke vestings, once they are created
    function disableOwnerRevokeGlobally() external onlyOwner {
        require(adminCanRevokeGlobal);
        adminCanRevokeGlobal = false;
        emit OwnerRevokeDisabledGlobally(block.timestamp);
    }
    function recoverWrongToken(address _token) external onlyOwner {
        require(_token != token || claimedTotal == vestedTotal, "cannot retrieve vested token");
        if(_token == address(0)) {
            msg.sender.call{ value: address(this).balance }("");
        } else {
            _processPayment(address(this), msg.sender, IERC20(_token).balanceOf(address(this)));
        }
    }
    function setRevenueSplitter(address revenueSplitter) external onlyOwner {
        _revenueSplitter = revenueSplitter;
    }
    function setStakingDelay(uint256 delay) external onlyOwner {
        stakingDelay = delay;
    }
    //// INTERNAL ////
    /// @dev sends all claimable token in the vesting to `who` and updates vesting
    function _retrieve(address who) internal {
        _enforceVestingExists(who);
        Vesting storage vesting = _vestingByUser[who];
        uint256 totalReleased = _releasedAt(vesting, block.timestamp);
        uint256 claimedBefore = vesting.claimed;
        // check this to not block `reduceVesting()`
        if(totalReleased < claimedBefore) {
            if(msg.sender == owner()) return;
            revert("already claimed");
        }
        uint256 claimable = totalReleased - claimedBefore;
        vesting.claimed = uint128(totalReleased);
        claimedTotal    += uint128(claimable);
        _processPayment(address(this), who, claimable);
        emit Retrieved(who, claimable);
    }
    /// @dev sets the vesting for recipient, can only be done once
    function _setVesting(address recipient, Vesting calldata vesting) internal {
        require(_vestingByUser[recipient].vested == 0, "already has a vesting");
        _enforceVestingParams(recipient, vesting);
        _vestingByUser[recipient] = vesting;
        emit VestingCreated(recipient, vesting);
    }
    function _processPayment(address from, address to, uint256 amount) internal {
        if(amount == 0) return;
        if(from == address(this)) {
            IERC20(token).safeTransfer(to, amount);
        } else {
            IERC20(token).safeTransferFrom(from, to, amount);
        }
    }
    /// @dev throws if vesting parameters are 'nonsensical'
    function _enforceVestingParams(address recipient, Vesting calldata vesting) internal view {
        require(recipient != address(0), ZERO_VALUE);
        require(recipient != address(this), "cannot vest for self");
        require(vesting.vested != 0, ZERO_VALUE);
        require(vesting.claimed == 0, "claimed == 0");
    }
    /// @dev throws if the vesting does not exist
    function _enforceVestingExists(address who) internal view {
        require(_vestingByUser[who].vested > 0, "vesting doesnt exist");
    }
    /// @dev calculates the fraction of the total amount that can be retrieved at a given timestamp. 
    ///      Based on `PRECISION`
    function _releasedFractionAt(uint256 timestamp, uint256 exponent) internal view returns(uint256) {
        if(timestamp + CLIFF_DELAY < START) {
            return 0;
        }
        if(timestamp < START) {
            return CLIFF;
        }
        uint256 fraction = (PRECISISION * (timestamp - START) ** exponent) / (uint256(DURATION) ** exponent) + CLIFF;
        if (fraction < PRECISISION) {
            return fraction;
        }
        return PRECISISION;
    }
    ///@dev calculates the amount of tokens that can be retrieved at a given timestamp. 
    function _releasedAt(Vesting storage vesting, uint256 timestamp) internal view returns(uint256) {
        return _releasedFractionAt(timestamp, EXP) * uint256(vesting.vested) / PRECISISION;
    }
    //// EXTERNAL VIEW ////
    /// @return amount number of tokens that are released in the vesting at a given timestamp
    function getReleasedAt(address who, uint256 timestamp) external view returns(uint256) {
        _enforceVestingExists(who);
        return _releasedAt(_vestingByUser[who], timestamp);
    }
    /// @return amount number of tokens that are released in the vesting at the moment
    function getReleased(address who) external view returns(uint256) {
        _enforceVestingExists(who);
        return _releasedAt(_vestingByUser[who], block.timestamp);
    }
    /// @return amount number of tokens that were already retrieved in the vesting
    function getClaimed(address who) external view returns(uint256) {
        _enforceVestingExists(who);
        return _vestingByUser[who].claimed;
    }
    function getClaimableAt(address who, uint256 when) public view returns(uint256) {
        _enforceVestingExists(who);
        uint256 released =  _releasedAt(_vestingByUser[who], when);
        uint256 claimed  = _vestingByUser[who].claimed;
        return claimed >= released ? 0 : released - claimed;
    }
    /// @return amount number of tokens that can be retrieved in the vesting at the moment
    function getClaimableNow(address who) external view returns(uint256) {
        return getClaimableAt(who, block.timestamp);
    }
    /// @param who beneficiary of the vesting
    /// @notice check `getNumberOfVestings(who)` for the smallest out-of-bound `which`
    function getVesting(address who) external view returns(Vesting memory) {
        _enforceVestingExists(who);
        return _vestingByUser[who];
    }
    function balanceOf(address who) external view returns(uint256 sum) {
        Vesting storage vesting = _vestingByUser[who];
        uint256 vested = vesting.vested;
        uint256 claimed = vesting.claimed;
        return vested > claimed ? vested - claimed : 0;
    }
    function stakeableBalance() external view returns(uint256) {
        uint256 linearReleased = _releasedFractionAt(block.timestamp, 1);
        uint256 actualReleased = _releasedFractionAt(block.timestamp, EXP);
        if(linearReleased == 0) return 0;
        if(actualReleased >= linearReleased) return 0;
        return (linearReleased - actualReleased) * uint256(vestedTotal) / PRECISISION;
    }
    function notifyShareholder(address _token, uint256 amount) external {
        require(msg.sender == _revenueSplitter);
        require(token == _token, "wrong token received");
        _stakingRewards[block.timestamp].reward += uint128(amount);
        emit StakingRewardsDistributed(amount, block.timestamp);
    }
    event VestingCreated(address indexed who, Vesting vesting);
    event VestingReduced(address indexed who, uint256 amountBefore, uint256 amountAfter);
    event Retrieved(address indexed who, uint256 amount);
    event OwnerRevokeDisabledGlobally(uint256 indexed time);
    event StakingRewardsDistributed(uint256 amount, uint256 timestamp);
}