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
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

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
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
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

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';

/**
 * @dev Contract implementing stacking with personal interest for users.
 * @author RY
 */
contract GameStaking is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    uint256 public constant SECONDS_IN_A_DAY = 86400;
    uint256 public constant ONE_HUNDRED_PERCENT = 1e6; // 100%

    // @dev Admin's address
    address private admin;

    // @dev Token in which rewards will be paid
    IERC20 private rewardToken;

    // @dev The price for entering the staking
    uint256 private ticketPrice;

    // @dev Minimum quantity for deposit
    uint256 private minimalDepositAmount;

    // @dev Maximum quantity for deposit
    uint256 private maximumDepositAmount;

    // @dev The percentage of awards is standard for all users. Reward percents per 1 day.
    uint256 private startingRate;

    // @dev Token blocking time in stacking
    uint256 private lockTime;

    // @dev Stacking shutdown time
    uint256 private endTime;

    // @dev Total players
    uint256 private totalPlayers;

    // @dev Total staked
    uint256 private totalStaked;

    // @dev Total staked
    uint256 private totalClaimed;

    // @dev Initialization indicator
    bool private initialized;

    // @dev List of all players
    mapping(address => Player) private players;

    /**
     * @dev Player is the player info structure contains all the data needed for manage player stacking.
     **/
    struct Player {
        uint256 deposit; // the amount of the user's deposit
        uint256 balance; // the amount of awards earned
        uint256 claimDate; // the time of the last withdrawal of awards
        uint256 activateTime; // stacking start time
        uint256 rate; // percentage of reward increase
    }

    /**
     * @dev Function used to get the admin address.
     **/
    function getAdmin() external view returns (address) {
        return admin;
    }

    /**
     * @dev Function used to get the end time of the stacking.
     **/
    function getEndTime() external view returns (uint256) {
        return endTime;
    }

    /**
     * @dev Function used to get the initialization indicator of the staking.
     **/
    function getInitialized() external view returns (bool) {
        return initialized;
    }

    /**
     * @dev Function used to get the lockTime of the staking.
     **/
    function getLockTime() external view returns (uint256) {
        return lockTime;
    }

    /**
     * @dev Function used to get the minimal deposit amount of the staking.
     **/
    function getMinimalDepositAmount() external view returns (uint256) {
        return minimalDepositAmount;
    }

    /**
     * @dev Function used to get the maximum deposit amount of the staking.
     **/
    function getMaximumDepositAmount() external view returns (uint256) {
        return maximumDepositAmount;
    }

    /**
     * @dev Function used to get the reward token of the staking.
     **/
    function getRewardToken() external view returns (address) {
        return address(rewardToken);
    }

    /**
     * @dev Function used to get the balance of reward tokens on the stacking contrast.
     **/
    function getRewardTokenBalance() external view returns (uint256) {
        return rewardToken.balanceOf(address(this));
    }

    /**
     * @dev Function used to get the starting rate of all users.
     **/
    function getStartingRate() external view returns (uint256) {
        return startingRate;
    }

    /**
     * @dev Function used to get total amount of staked tokens.
     **/
    function getTotalStaked() external view returns (uint256) {
        return totalStaked;
    }

    /**
     * @dev Function used to get total amount of claimed tokens.
     **/
    function getTotalClaimed() external view returns (uint256) {
        return totalClaimed;
    }

    /**
     * @dev Function used to get total amount of stakers.
     **/
    function getTotalPlayers() external view returns (uint256) {
        return totalPlayers;
    }

    /**
     * @dev Function used to get the price for entering the staking.
     **/
    function getTicketPrice() external view returns (uint256) {
        return ticketPrice;
    }

    /**
     * @dev Function used to get the information about user.
     * @param playerAddress is the address of the user that you need to get information about.
     **/
    function getPlayerInfo(address playerAddress) external view returns (Player memory) {
        return players[playerAddress];
    }

    /**
     * @dev Function used to get the amount of user reward.
     * @param playerAddress is the address of the user that you need to get amount of rewards.
     **/
    function getUserBalance(address playerAddress) public view returns (uint256) {
        return players[playerAddress].balance + calculateRewards(playerAddress);
    }

    /**
     * @dev Event informs about setting of new admin address.
     * @param newAdmin is address of new admin.
     **/
    event AdminSet(address indexed newAdmin);

    /**
     * @dev Event informs about the withdrawal of the deposit by the user
     * @param playerAddress is the address of the user that you need to get amount of rewards.
     * @param deposit is the amount of withdrawed tokens.
     **/
    event DepositWithdrawed(address indexed playerAddress, uint256 deposit);

    /**
     * @dev Event informs about setting of new end time of the staking.
     * @param newEndTime is the new timestamp of staking end.
     **/
    event EndTimeSet(uint256 newEndTime);

    /**
     * @dev Event informs about staking initializing.
     * @param operator is address of function caller.
     **/
    event Initialized(address operator);

    /**
     * @dev Event informs about setting of new lock time for users deposits.
     * @param newLockTime is new amount in seconds for token lock.
     **/
    event LockTimeSet(uint256 newLockTime);

    /**
     * @dev Event informs about setting of new minimal deposit amount for users.
     * @param newMinimalDepositAmount is new amount for minimal user deposit.
     **/
    event MinimalDepositAmountSet(uint256 newMinimalDepositAmount);

    /**
     * @dev Event informs about setting of new maximum deposit amount for users deposits.
     * @param newMaximumDepositAmount is new amount for maximum user deposit.
     **/
    event MaximumDepositAmountSet(uint256 newMaximumDepositAmount);

    /**
     * @dev Event informs about setting of new maximum deposit amount for users deposits.
     * @param playerAddress is new amount for maximum user deposit.
     * @param reward is new amount for maximum user deposit.
     **/
    event RewardClaimed(address indexed playerAddress, uint256 reward);

    /**
     * @dev Event informs about setting of new reward token.
     * @param newRewardToken is new  address of reward token.
     **/
    event RewardTokenSet(address newRewardToken);

    /**
     * @dev Event informs about removing of rewards tokens from contract.
     * @param operator is address of function caller.
     * @param amount is amount of tokens.
     **/
    event RewardTokenRemoved(address operator, uint256 amount);

    /**
     * @dev Event informs about new deposit from the user.
     * @param playerAddress is address of user that deposit tokens.
     * @param playerDeposit is amount of tokens.
     **/
    event Staked(address indexed playerAddress, uint256 playerDeposit);

    /**
     * @dev Event informs about setting of new starting rate for all users.
     * @param newStartingRate is new starting rate in percent.
     **/
    event StartingRateSet(uint256 newStartingRate);

    /**
     * @dev Event informs about setting of new ticket price for all users.
     * @param newTicketPrice is new ticket price.
     **/
    event TicketPriceSet(uint256 newTicketPrice);

    /**
     * @dev When creating a contract, the presented parameters will be filled in with the transmitted data.
     * @param _rewardToken is address of reward token.
     * @param _ticketPrice is ticket price.
     * @param _lockTime is lock time.
     * @param _minimalDepositAmount is amount of minimal deposit for users.
     * @param _maximumDepositAmount is amount of maximum deposit for users.
     * @param _startingRate is standard rate for all users.
     * @param _endTime is end time of staking.
     *
     * @notice *WARNING* After the contract is deployed, some functions will not be available.
     * Therefore, as soon as you are ready to launch the contract, you need to initialize it using the init function.
     **/
    constructor(
        IERC20 _rewardToken,
        uint256 _ticketPrice,
        uint256 _lockTime,
        uint256 _minimalDepositAmount,
        uint256 _maximumDepositAmount,
        uint256 _startingRate,
        uint256 _endTime,
        address _admin
    ) {
        require(address(_rewardToken) != address(0), 'GameStaking: zero-check');
        setAdmin(_admin);
        startingRate = _startingRate; // 15000 --- 1.5% per day
        minimalDepositAmount = _minimalDepositAmount;
        maximumDepositAmount = _maximumDepositAmount;
        lockTime = _lockTime;
        rewardToken = _rewardToken;
        ticketPrice = _ticketPrice;
        endTime = _endTime;
    }

    /**
     * @dev The function is used to get rewards by users.
     *
     * @notice The user will be able to collect rewards only after the end of the block
     **/
    function claimReward() external nonReentrant {
        Player storage player = players[msg.sender];
        uint256 balance = getUserBalance(msg.sender);
        require(rewardToken.balanceOf(address(this)) >= balance, 'GameStaking: not enough tokens');
        require(balance > 0, 'GameStaking: zero balance');
        player.balance = 0;
        player.claimDate = block.timestamp;
        totalClaimed += balance;
        emit RewardClaimed(msg.sender, balance);
        rewardToken.safeTransfer(msg.sender, balance);
    }

    /**
     * @dev Function is used to initialize contract.
     *
     * @notice *WARNING* After the contract is deployed, some functions will not be available.
     * Therefore, as soon as you are ready to launch the contract, you need to initialize it using this function.
     **/
    function init() external onlyOwner {
        initialized = true;
        emit Initialized(msg.sender);
    }

    /**
     * @dev Functions used for stake token by users.
     **/
    function stake() external payable nonReentrant {
        require(initialized, 'GameStaking: is not active');
        require(block.timestamp < endTime, 'GameStaking: is ended');
        Player storage player = players[msg.sender];
        if (player.deposit > 0) {
            updateBalance(msg.sender);
        }
        if (minimalDepositAmount != 0) {
            require(msg.value >= minimalDepositAmount, 'GameStaking: minimum amount error');
        }
        if (maximumDepositAmount != 0) {
            require(player.deposit + msg.value <= maximumDepositAmount, 'GameStaking: limit amount error');
        }
        totalStaked += msg.value;
        player.deposit += msg.value;
        player.claimDate = block.timestamp;
        if (player.activateTime == 0) {
            totalPlayers += 1;
            player.activateTime = block.timestamp;
        }
        emit Staked(msg.sender, player.deposit);
        if (ticketPrice > 0) rewardToken.safeTransferFrom(msg.sender, address(this), ticketPrice);
    }

    /**
     * @dev Function is used to withdraw deposits by users.
     *
     * @notice users can withdraw a deposit only after the lock time.
     **/
    function withdrawDeposit() external nonReentrant {
        Player storage player = players[msg.sender];
        require(player.activateTime + lockTime <= block.timestamp, 'GameStaking: lock time error');
        updateBalance(msg.sender);
        uint256 deposit = player.deposit;
        require(deposit > 0, 'GameStaking: zero deposit error');
        player.deposit = 0;
        totalPlayers -= 1;
        totalStaked -= deposit;
        emit DepositWithdrawed(msg.sender, deposit);
        sendEth(payable(msg.sender), deposit);
    }

    /**
     * @dev Function is used to setting new admin for contract.
     *
     * @param newAdmin is address of new admin.
     **/
    function setAdmin(address newAdmin) public onlyOwner returns (bool) {
        require(newAdmin != address(0), 'GameStaking: zero-check');
        admin = newAdmin;
        emit AdminSet(newAdmin);
        return true;
    }

    /**
     * @dev Function is used to setting new end time for staking.
     *
     * @param newEndTime is new end time of staking.
     **/
    function setEndTime(uint256 newEndTime) external onlyOwner returns (bool) {
        endTime = newEndTime;
        emit EndTimeSet(newEndTime);
        return true;
    }

    /**
     * @dev Function is used to setting new lock time for staking.
     *
     * @param newLockTime is new lock time for users deposits.
     **/
    function setLockTime(uint256 newLockTime) external onlyOwner returns (bool) {
        lockTime = newLockTime;
        emit LockTimeSet(newLockTime);
        return true;
    }

    /**
     * @dev Function is used to setting new minimal deposit amount for staking.
     *
     * @param newMinimalDepositAmount is new minimal deposit amount for users deposits.
     **/
    function setMinimalDepositAmount(uint256 newMinimalDepositAmount) external onlyOwner returns (bool) {
        minimalDepositAmount = newMinimalDepositAmount;
        emit MinimalDepositAmountSet(newMinimalDepositAmount);
        return true;
    }

    /**
     * @dev Function is used to setting new  maximum deposit amount for staking.
     *
     * @param newMaximumDepositAmount is new  maximum deposit amount for users deposits.
     **/
    function setMaximumDepositAmount(uint256 newMaximumDepositAmount) external onlyOwner returns (bool) {
        maximumDepositAmount = newMaximumDepositAmount;
        emit MaximumDepositAmountSet(newMaximumDepositAmount);
        return true;
    }

    /**
     * @dev Function is used to setting new reward token for staking.
     *
     * @param newRewardToken is address of new reward token.
     **/
    function setRewardToken(IERC20 newRewardToken) external onlyOwner returns (bool) {
        require(address(newRewardToken) != address(0), 'GameStaking: zero-check');
        rewardToken = newRewardToken;
        emit RewardTokenSet(address(newRewardToken));
        return true;
    }

    /**
     * @dev Function is used to setting new starting rate for staking.
     *
     * @param newStartingRate is new standard rate for all users.
     **/
    function setStartingRate(uint256 newStartingRate) external onlyOwner returns (bool) {
        startingRate = newStartingRate;
        emit StartingRateSet(newStartingRate);
        return true;
    }

    /**
     * @dev Function is used to setting new ticket price for staking.
     *
     * @param newTicketPrice is new price of entrance for all users.
     **/
    function setTicketPrice(uint256 newTicketPrice) external onlyOwner returns (bool) {
        ticketPrice = newTicketPrice;
        emit TicketPriceSet(newTicketPrice);
        return true;
    }

    /**
     * @dev Function is used remove rewards token from contract.
     *
     * @param amount of rewards tokens.
     **/
    function removeRewardToken(uint256 amount) external onlyOwner returns (bool) {
        emit RewardTokenRemoved(msg.sender, amount);
        rewardToken.safeTransfer(msg.sender, amount);
        return true;
    }

    /**
     * @dev Function is used remove rewards token from contract.
     *
     * @param playersAddresses array of players addresses for updating rate.
     * @param newRates array of new rates for player.
     *
     * @notice the user's address from the array should be under the corresponding index with the new rate.
     *
     * WARNING - The length of arrays should be equal !
     **/
    function updatePlayersRates(
        address[] memory playersAddresses,
        uint256[] memory newRates
    ) external onlyAdmin returns (bool) {
        require(playersAddresses.length == newRates.length, 'GameStaking: wrong params');
        for (uint256 i = 0; i < playersAddresses.length; i++) {
            updateBalance(playersAddresses[i]);
            players[playersAddresses[i]].rate = newRates[i];
        }
        return true;
    }

    /**
     * @dev Function is used to calculate rewards for users.
     *
     * @param playerAddress is address of player.
     **/
    function calculateRewards(address playerAddress) internal view returns (uint256 rewards) {
        Player memory player = players[playerAddress];
        if (player.deposit == 0) {
            return 0;
        }
        uint256 rate = startingRate + player.rate;
        uint256 lastTimestamp = block.timestamp > endTime ? endTime : block.timestamp;
        uint256 claimTimestamp = player.claimDate > endTime ? endTime : player.claimDate;
        rewards = ((((player.deposit * rate) / ONE_HUNDRED_PERCENT) * (lastTimestamp - claimTimestamp)) /
            SECONDS_IN_A_DAY);
    }

    /**
     * @dev Function is used to transfer native tokens from contract.
     *
     * @param to is address of recipient.
     * @param value of native tokens to transfer.
     **/
    function sendEth(address payable to, uint256 value) private {
        (bool sent, ) = to.call{value: value}('');
        require(sent, 'GameStaking: failed to send Tokens');
    }

    /**
     * @dev Function is used to update user information for calculating user rewards.
     *
     * @param playerAddress is address of user.
     *
     * @notice  update rewards and claimDate EVERY TIME when change user rate.
     **/
    function updateBalance(address playerAddress) private {
        Player storage player = players[playerAddress];
        player.balance = player.balance + calculateRewards(playerAddress);
        player.claimDate = block.timestamp;
    }

    /**
     * @dev Modifier is used to check that caller is admin.
     **/
    modifier onlyAdmin() {
        require(msg.sender == admin, 'Gambling: caller is not the admin');
        _;
    }
}