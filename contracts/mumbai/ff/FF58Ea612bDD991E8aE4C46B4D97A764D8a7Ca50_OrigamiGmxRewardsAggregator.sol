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
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
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

pragma solidity ^0.8.4;
// SPDX-License-Identifier: AGPL-3.0-or-later
// Origami (common/CommonEventsAndErrors.sol)

/// @notice A collection of common errors thrown within the Origami contracts
library CommonEventsAndErrors {
    error InsufficientBalance(address token, uint256 required, uint256 balance);
    error InvalidToken(address token);
    error InvalidParam();
    error InvalidAddress(address addr);
    error InvalidAmount(address token, uint256 amount);
    error ExpectedNonZero();
    error Slippage(uint256 minAmountExpected, uint256 acutalAmount);

    event TokenRecovered(address indexed to, address indexed token, uint256 amount);
}

pragma solidity ^0.8.4;
// SPDX-License-Identifier: AGPL-3.0-or-later
// Origami (common/FractionalAmount.sol)

import "./CommonEventsAndErrors.sol";

/// @notice Utilities to operate on fractional amounts of an input
/// - eg to calculate the split of rewards for fees.
library FractionalAmount {

    struct Data {
        uint128 numerator;
        uint128 denominator;
    }

    uint256 public constant BASIS_POINTS_DIVISOR = 10000;

    /// @notice Return the fractional amount as basis points (ie fractional amount at precision of 10k)
    function asBasisPoints(Data storage self) internal view returns (uint256) {
        return (self.numerator * BASIS_POINTS_DIVISOR) / self.denominator;
    }

    /// @notice Helper to set the storage value with safety checks.
    function set(Data storage self, uint128 _numerator, uint128 _denominator) internal {
        if (_denominator == 0 || _numerator > _denominator) revert CommonEventsAndErrors.InvalidParam();
        self.numerator = _numerator;
        self.denominator = _denominator;
    }

    /// @notice Split an amount into two parts based on a fractional ratio
    /// eg: 333/1000 (33.3%) can be used to split an input amount of 600 into: (199, 401).
    /// @dev The numerator amount is truncated if necessary
    function split(Data storage self, uint256 inputAmount) internal view returns (uint256 numeratorAmount, uint256 denominatorAmount) {
        if (self.numerator == 0) {
            return (0, inputAmount);
        }
        unchecked {
            numeratorAmount = (inputAmount * self.numerator) / self.denominator;
            denominatorAmount = inputAmount - numeratorAmount;
        }
    }

    /// @notice Split an amount into two parts based on a fractional ratio
    /// eg: 333/1000 (33.3%) can be used to split an input amount of 600 into: (199, 401).
    /// @dev Overloaded version of the above, using calldata/pure to avoid a copy from storage in some scenarios
    function split(Data calldata self, uint256 inputAmount) internal pure returns (uint256 numeratorAmount, uint256 denominatorAmount) {
        if (self.numerator == 0) {
            return (0, inputAmount);
        }
        unchecked {
            numeratorAmount = (inputAmount * self.numerator) / self.denominator;
            denominatorAmount = inputAmount - numeratorAmount;
        }
    }
}

pragma solidity ^0.8.4;
// SPDX-License-Identifier: AGPL-3.0-or-later
// Origami (interfaces/investments/gmx/IOrigamiGmxEarnAccount.sol)

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../../common/FractionalAmount.sol";

interface IOrigamiGmxEarnAccount {
    // Input parameters required when claiming/compounding rewards from GMX.io
    struct HandleGmxRewardParams {
        bool shouldClaimGmx;
        bool shouldStakeGmx;
        bool shouldClaimEsGmx;
        bool shouldStakeEsGmx;
        bool shouldStakeMultiplierPoints;
        bool shouldClaimWeth;
        bool shouldConvertWethToEth;
    }

    // Rewards that Origami claimed from GMX.io
    struct ClaimedRewards {
        uint256 wrappedNativeFromGmx;
        uint256 wrappedNativeFromGlp;
        uint256 esGmxFromGmx;
        uint256 esGmxFromGlp;
        uint256 vestedGmx;
    }

    function rewardRates(bool forStakedGlpRewards) external view returns (uint256 wrappedNativeTokensPerSec, uint256 esGmxTokensPerSec);
    function harvestableRewards(bool forStakedGlpRewards) external view returns (
        uint256 wrappedNativeAmount, 
        uint256 esGmxAmount
    );
    function harvestRewards(FractionalAmount.Data calldata _esGmxVestingRate) external returns (ClaimedRewards memory claimedRewards);
    function handleRewards(HandleGmxRewardParams calldata params) external returns (ClaimedRewards memory claimedRewards);
    function stakeGmx(uint256 _amount) external;
    function unstakeGmx(uint256 _maxAmount) external;
    function mintAndStakeGlp(
        uint256 fromAmount,
        address fromToken,
        uint256 minUsdg,
        uint256 minGlp,
        uint256 slippageBps
    ) external returns (uint256);
    function unstakeAndRedeemGlp(
        uint256 glpAmount, 
        address toToken, 
        uint256 minOut, 
        uint256 slippageBps,
        address receiver
    ) external returns (uint256);
    function transferStakedGlp(uint256 glpAmount, address receiver) external;
    function stakedGlp() external view returns (IERC20);
}

pragma solidity ^0.8.4;
// SPDX-License-Identifier: AGPL-3.0-or-later
// Origami (interfaces/investments/gmx/IOrigamiGmxManager.sol)

import "./IOrigamiGmxEarnAccount.sol";

interface IOrigamiGmxManager {
    function harvestableRewards(bool forStakedGlpRewards) external view returns (uint256[] memory amounts);
    function projectedRewardRates(bool forStakedGlpRewards) external view returns (uint256[] memory amounts);
    function harvestRewards() external;
    function harvestSecondaryRewards() external;
    function rewardTokensList() external view returns (address[] memory tokens);
    function wrappedNativeToken() external view returns (address);
    function primaryEarnAccount() external view returns (IOrigamiGmxEarnAccount);
    function secondaryEarnAccount() external view returns (IOrigamiGmxEarnAccount);
    function sellOGmxQuote(uint256 _oGmxAmount) external view returns (uint256 origamiFeeBasisPoints, uint256 gmxAmountOut);
    function sellOGmx(
        uint256 _sellAmount,
        address _recipient
    ) external returns (uint256 amountOut);
    function acceptedGlpTokens(address[] calldata extraTokens) external view returns (address[] memory);
    function buyOGlpQuote(uint256 _amount, address _token) external view returns (
        uint256 oGlpAmountOut, uint256[] memory investFeeBps, uint256 expectedUsdg
    );
    function sellOGlpQuote(uint256 _oGlpAmount, address _toToken) external view returns (
        uint256 toTokenAmount, uint256[] memory exitFeeBps
    );
    function sellOGlp(
        uint256 _sellAmount,
        address _toToken,
        uint256 _minAmountOut,
        uint256 _slippageBps,
        address _recipient
    ) external returns (uint256 amountOut);
    function sellOGlpToStakedGlp(
        uint256 _sellAmount,
        address _recipient
    ) external returns (uint256 amountOut);
}

pragma solidity ^0.8.4;
// SPDX-License-Identifier: AGPL-3.0-or-later
// Origami (interfaces/staking/IOrigamiInvestmentManager.sol)

interface IOrigamiInvestmentManager {
    function rewardTokensList() external view returns (address[] memory tokens);
    function harvestRewards() external returns (uint256[] memory amounts);
    function harvestableRewards() external view returns (uint256[] memory amounts);
    function projectedRewardRates() external view returns (uint256[] memory amounts);
    function performanceFeeRates(uint256 rewardTokenIndex) external view returns (
        uint128 numerator,
        uint128 denominator
    );
}

pragma solidity ^0.8.4;
// SPDX-License-Identifier: AGPL-3.0-or-later
// Origami (investments/gmx/OrigamiGmxRewardsAggregator.sol)

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

import "../../interfaces/investments/IOrigamiInvestmentManager.sol";
import "../../interfaces/investments/gmx/IOrigamiGmxManager.sol";
import "../../common/CommonEventsAndErrors.sol";
import "../../common/FractionalAmount.sol";

/// @title Origami GMX/GLP Rewards Aggregator
/// @notice Manages the collation and selection of GMX.io rewards sources to the correct Origami investment vault.
/// ie the Origami GMX vault and the Origami GLP vault
/// @dev This implements the IOrigamiInvestmentManager interface -- the Origami GMX/GLP Rewards Distributor 
/// calls to harvest aggregated rewards.
contract OrigamiGmxRewardsAggregator is IOrigamiInvestmentManager, Ownable, Pausable {
    using SafeERC20 for IERC20;
    using FractionalAmount for FractionalAmount.Data;

    /// @notice The Origami contract managing the holdings of staked GMX derived rewards
    /// @dev The GMX Vault needs to pick staked GMX/esGMX/mult point rewards from both GMX Manager and also GLP Manager 
    IOrigamiGmxManager public gmxManager;

    /// @notice The Origami contract managing the holdings of staked GLP derived rewards
    /// @dev The GLP Vault picks staked GLP rewards from the GLP manager. 
    /// The GMX vault picks staked GMX/esGMX/mult points from the GLP Manager
    IOrigamiGmxManager public glpManager;

    /// @notice The set of reward tokens that the GMX manager yields to users.
    /// [ ETH/AVAX, oGMX ]
    address[] public rewardTokens;

    /// @notice The contract/EOA responsible for harvesting rewards and distributing to the staking contract.
    address public rewardsDistributor;

    /// @notice Performance fee for each rewardToken which Origami takes on the rewards
    mapping(uint256 => FractionalAmount.Data) public override performanceFeeRates;
    
    event OrigamiGmxManagersSet(address indexed gmxManager, address indexed glpManager);
    event RewardsDistributorSet(address indexed rewardsDistributor);
    event PerformanceFeesSet(FractionalAmount.Data[] performanceFeeRates);
    error OnlyRewardsDistributor(address caller);

    constructor(address _gmxManager, address _glpManager, FractionalAmount.Data[] memory _performanceFeeRates) {
        gmxManager = IOrigamiGmxManager(_gmxManager);
        glpManager = IOrigamiGmxManager(_glpManager);
        rewardTokens = _gmxManager == address(0)
            ? glpManager.rewardTokensList() 
            : gmxManager.rewardTokensList();
        for (uint256 i; i < rewardTokens.length; ++i) {
            performanceFeeRates[i] = _performanceFeeRates[i];
        }
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    /// @notice Set the Origami GMX Manager contract used to apply GMX to earn rewards.
    function setOrigamiGmxManagers(address _gmxManager, address _glpManager) external onlyOwner {
        gmxManager = IOrigamiGmxManager(_gmxManager);
        glpManager = IOrigamiGmxManager(_glpManager);
        emit OrigamiGmxManagersSet(_gmxManager, _glpManager);
    }

    /// @notice Set the Origami staking and rewards distributor contracts.
    function setRewardsDistributor(address _rewardsDistributor) external onlyOwner {
        if (_rewardsDistributor == address(0)) revert CommonEventsAndErrors.InvalidAddress(address(0));
        rewardsDistributor = _rewardsDistributor;
        emit RewardsDistributorSet(_rewardsDistributor);
    }

    /// @notice Set the Origami performance fees per token
    function setPerformanceFees(
        FractionalAmount.Data[] calldata _performanceFeeRates
    ) external onlyOwner {
        if (_performanceFeeRates.length != rewardTokens.length) revert CommonEventsAndErrors.InvalidParam();
        for (uint256 i; i < rewardTokens.length; ++i) {
            performanceFeeRates[i] = _performanceFeeRates[i];
        }
        emit PerformanceFeesSet(_performanceFeeRates);
    }

    /// @notice The set of reward tokens we give to the staking contract.
    /// @dev Part of the IOrigamiInvestmentManager interface
    function rewardTokensList() external view override returns (address[] memory tokens) {
        return rewardTokens;
    }

    /// @notice The amount of rewards up to this block that Origami is due to distribute to users.
    /// ie the net amount after Origami has deducted it's fees.
    /// @dev Part of the IOrigamiInvestmentManager interface.
    function harvestableRewards() external view override returns (uint256[] memory amounts) {
        // Pull the GLP manager rewards - may be from GLP only or GMX/esGMX/mult points, 
        // depending on the vault.
        bool forStakedGlpRewards = address(gmxManager) == address(0);
        amounts = glpManager.harvestableRewards(forStakedGlpRewards);

        // And the GMX manager only rewards
        uint256 i;
        if (address(gmxManager) != address(0)) {
            // Never any GLP rewards from the GMX manager.
            uint256[] memory _gmxAmounts = gmxManager.harvestableRewards(false);
            for (; i < amounts.length; ++i) {
                amounts[i] += _gmxAmounts[i];
            }
        }

        // Add any balances which have already been harvested (ie if gmxManager.harvestRewards() was called directly),
        // and sitting in this aggregator
        for (i=0; i < rewardTokens.length; ++i) {
            amounts[i] += IERC20(rewardTokens[i]).balanceOf(address(this));
        }
    }

    /// @notice The current native token and oGMX reward rates per second
    /// @dev Based on the current total Origami rewards, minus any portion of fees which we will take
    function projectedRewardRates() external view override returns (uint256[] memory amounts) {
        // Pull the GLP manager rewards - may be from GLP only or GMX/esGMX/mult points, 
        // depending on the vault.
        bool forStakedGlpRewards = address(gmxManager) == address(0);
        amounts = glpManager.projectedRewardRates(forStakedGlpRewards);

        // And the GMX manager only rewards
        if (address(gmxManager) != address(0)) {
            // Never any GLP rewards from the GMX manager.
            uint256[] memory _gmxAmounts = gmxManager.projectedRewardRates(false);
            for (uint256 i; i < amounts.length; i++) {
                amounts[i] += _gmxAmounts[i];
            }
        }

        // Finally take off any performance fees that Origami is due
        for (uint256 i; i < amounts.length; i++) {
            (, amounts[i]) = performanceFeeRates[i].split(amounts[i]);
        }
    }

    /**
     * @notice Harvest any Origami claimable rewards distributable to users from the glpManager and gmxManager.
     * Performance fees are not collected here, they are collected after the rewards have been converted into the
     * Origami Investment token.
     */
    function harvestRewards() external override whenNotPaused returns (uint256[] memory amounts) {
        if (msg.sender != rewardsDistributor) revert OnlyRewardsDistributor(msg.sender);

        // Both the GMX Vault and the GLP Vault harvests rewards from the GLP Manager.
        glpManager.harvestRewards();

        // Only the GMX Vault harvests from the GMX Manager, and the GMX Vault leaves gmxManager=address(0)
        if (address(gmxManager) != address(0)) {
            gmxManager.harvestRewards();
        }

        // gmx/glpManager contracts are aggregated here. 
        // Transfer any accrued balance of each reward token to the rewardsDistributor
        IERC20 rewardToken;
        uint256 amount;
        amounts = new uint256[](rewardTokens.length);
        for (uint256 i; i < rewardTokens.length; ++i) {
            rewardToken = IERC20(rewardTokens[i]);
            amount = rewardToken.balanceOf(address(this));
            amounts[i] = amount;
            if (amount > 0) {
                rewardToken.safeTransfer(rewardsDistributor, amount);
            }
        }
    }

    /// @notice Owner can recover tokens
    function recoverToken(
        address _token,
        address _to,
        uint256 _amount
    ) external onlyOwner {
        IERC20(_token).safeTransfer(_to, _amount);
        emit CommonEventsAndErrors.TokenRecovered(_to, _token, _amount);
    }
}