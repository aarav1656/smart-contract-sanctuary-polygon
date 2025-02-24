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
// solhint-disable no-inline-assembly
pragma solidity >=0.6.9;

import "./interfaces/IERC2771Recipient.sol";

/**
 * @title The ERC-2771 Recipient Base Abstract Class - Implementation
 *
 * @notice Note that this contract was called `BaseRelayRecipient` in the previous revision of the GSN.
 *
 * @notice A base contract to be inherited by any contract that want to receive relayed transactions.
 *
 * @notice A subclass must use `_msgSender()` instead of `msg.sender`.
 */
abstract contract ERC2771Recipient is IERC2771Recipient {

    /*
     * Forwarder singleton we accept calls from
     */
    address private _trustedForwarder;

    /**
     * :warning: **Warning** :warning: The Forwarder can have a full control over your Recipient. Only trust verified Forwarder.
     * @notice Method is not a required method to allow Recipients to trust multiple Forwarders. Not recommended yet.
     * @return forwarder The address of the Forwarder contract that is being used.
     */
    function getTrustedForwarder() public virtual view returns (address forwarder){
        return _trustedForwarder;
    }

    function _setTrustedForwarder(address _forwarder) internal {
        _trustedForwarder = _forwarder;
    }

    /// @inheritdoc IERC2771Recipient
    function isTrustedForwarder(address forwarder) public virtual override view returns(bool) {
        return forwarder == _trustedForwarder;
    }

    /// @inheritdoc IERC2771Recipient
    function _msgSender() internal override virtual view returns (address ret) {
        if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
            // At this point we know that the sender is a trusted forwarder,
            // so we trust that the last bytes of msg.data are the verified sender address.
            // extract sender address from the end of msg.data
            assembly {
                ret := shr(96,calldataload(sub(calldatasize(),20)))
            }
        } else {
            ret = msg.sender;
        }
    }

    /// @inheritdoc IERC2771Recipient
    function _msgData() internal override virtual view returns (bytes calldata ret) {
        if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
            return msg.data[0:msg.data.length-20];
        } else {
            return msg.data;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

/**
 * @title The ERC-2771 Recipient Base Abstract Class - Declarations
 *
 * @notice A contract must implement this interface in order to support relayed transaction.
 *
 * @notice It is recommended that your contract inherits from the ERC2771Recipient contract.
 */
abstract contract IERC2771Recipient {

    /**
     * :warning: **Warning** :warning: The Forwarder can have a full control over your Recipient. Only trust verified Forwarder.
     * @param forwarder The address of the Forwarder contract that is being used.
     * @return isTrustedForwarder `true` if the Forwarder is trusted to forward relayed transactions by this Recipient.
     */
    function isTrustedForwarder(address forwarder) public virtual view returns(bool);

    /**
     * @notice Use this method the contract anywhere instead of msg.sender to support relayed transactions.
     * @return sender The real sender of this call.
     * For a call that came through the Forwarder the real sender is extracted from the last 20 bytes of the `msg.data`.
     * Otherwise simply returns `msg.sender`.
     */
    function _msgSender() internal virtual view returns (address);

    /**
     * @notice Use this method in the contract instead of `msg.data` when difference matters (hashing, signature, etc.)
     * @return data The real `msg.data` of this call.
     * For a call that came through the Forwarder, the real sender address was appended as the last 20 bytes
     * of the `msg.data` - so this method will strip those 20 bytes off.
     * Otherwise (if the call was made directly and not through the forwarder) simply returns `msg.data`.
     */
    function _msgData() internal virtual view returns (bytes calldata);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@gsn/ERC2771Recipient.sol";
import "./common/IERC20MetaTxn.sol";
import "./IDaterLP.sol";

/**
 * @dev Dater Liquidity Pool (LP)
 * Provides $DC => USDT and vice versa swaps functionality
 * See functions annotations for more details
 * Allows for gasless transactions through EIP-2771 compliant recipient functionality
*/

contract DaterLP is Ownable, ERC2771Recipient, IDaterLP {

    using SafeERC20 for IERC20MetaTxn;
    using Address for address;

    uint256 private constant USD_TO_DC_MAX_RATIO = 100;
    uint256 private constant ONE_HUNDRED_PERCENT_TWO_DECIMALS = 10_000;

    uint256 public commission;

    IERC20MetaTxn[2] public tokens;
    uint256[2] public tokenReserves;    

    address private keeper;
    bool private withdrawalsAllowed;

    constructor(address _stableAddress, address _dcAddress, uint256 _commissionInHundredthsOfPercent, address _keeper) {
        tokens[uint(TokensNames.STABLECOIN)] = IERC20MetaTxn(_stableAddress);
        tokens[uint(TokensNames.DATERCOIN)] = IERC20MetaTxn(_dcAddress);
        commission = _commissionInHundredthsOfPercent;
        keeper = _keeper;
    }

    /** 
        @dev Swaps exact amount of tokens for other tokens.
        @param amountOutMin Minimal amount for a user to receive from pool. Introduced to deal with slippage.
        @param direction Swapping direction. From stablecoins to Datercoins or vice versa.
        @return amountOut Amount out.
    */

    function swapExactAmountOfTokensForOtherTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        IDaterLP.SwapDirections direction, 
        bytes32 sigR, bytes32 sigS, uint8 sigV
    ) external returns (uint256 amountOut) {

        if(amountIn == 0 || amountOutMin == 0) 
            revert WrongAmounts(amountIn, amountOutMin);
    
        uint256 amountInAfterCommission = amountIn * (ONE_HUNDRED_PERCENT_TWO_DECIMALS - commission) / (ONE_HUNDRED_PERCENT_TWO_DECIMALS);

        uint256 reservesIn = tokenReserves[uint(direction)];
        uint256 reservesOut = tokenReserves[1-uint(direction)];
        
        amountOut = (amountInAfterCommission * reservesOut) / (amountInAfterCommission + reservesIn);

        if (amountOut < amountOutMin)
            revert InsufficientOutputAmount(amountOutMin, amountOut);
        
        if (amountOut >= reservesOut)
            revert InsufficientReserve(amountOut, reservesOut, uint(direction));
        
        bytes memory functionSignature = abi.encodeWithSignature("approve(address,uint256)", address(this), amountIn);

        _swap(amountIn, amountOut, direction, functionSignature, sigR, sigS, sigV);
    }

    function swapExactAmountOfTokensForOtherTokensPreapproved(
        uint256 amountIn,
        uint256 amountOutMin,
        IDaterLP.SwapDirections direction
    ) external returns (uint256 amountOut) {

        if(amountIn == 0 || amountOutMin == 0) 
            revert WrongAmounts(amountIn, amountOutMin);
    
        uint256 amountInAfterCommission = amountIn * (ONE_HUNDRED_PERCENT_TWO_DECIMALS - commission) / (ONE_HUNDRED_PERCENT_TWO_DECIMALS);

        uint256 reservesIn = tokenReserves[uint(direction)];
        uint256 reservesOut = tokenReserves[1-uint(direction)];
        
        amountOut = (amountInAfterCommission * reservesOut) / (amountInAfterCommission + reservesIn);

        if (amountOut < amountOutMin)
            revert InsufficientOutputAmount(amountOutMin, amountOut);
        
        if (amountOut >= reservesOut)
            revert InsufficientReserve(amountOut, reservesOut, uint(direction));

        _swapPreapproved(amountIn, amountOut, direction);
    }

    /** 
     *  @dev Swaps tokens for the exact amount of other tokens.
     *  @param amountInMax Maximum tokens user willing to pay to pool to get `amountOut` 
     *  of other tokens from pool. Introduced to deal with slippage.
     *  @param direction Swapping direction. From stablecoins to Datercoins or vice versa.
     *  @return amountIn The amount of tokens sent to pool to get AmountOut of tokens from pool.
    */

    function swapTokensForExactAmountOfOtherTokens(
        uint256 amountOut,
        uint256 amountInMax,
        IDaterLP.SwapDirections direction,
        bytes32 sigR, bytes32 sigS, uint8 sigV
    ) external returns (uint256 amountIn) {
        
        if(amountInMax == 0 || amountOut == 0) 
            revert WrongAmounts(amountInMax, amountOut);

        uint256 reservesIn = tokenReserves[uint(direction)];
        uint256 reservesOut = tokenReserves[1-uint(direction)];
        
        if (amountOut >= reservesOut)
            revert InsufficientReserve(amountOut, reservesOut, uint(direction));
        
        amountIn = amountOut*reservesIn*(ONE_HUNDRED_PERCENT_TWO_DECIMALS) / ((reservesOut - amountOut)*(ONE_HUNDRED_PERCENT_TWO_DECIMALS - commission));

        if (amountIn > amountInMax)
            revert InsufficientInputAmount(amountInMax, amountIn);

        bytes memory functionSignature = abi.encodeWithSignature("approve(address,uint256)", address(this), amountInMax);

        _swap(amountIn, amountOut, direction, functionSignature, sigR, sigS, sigV);
    }

    function swapTokensForExactAmountOfOtherTokensPreapproved(
        uint256 amountOut,
        uint256 amountInMax,
        IDaterLP.SwapDirections direction
    ) external returns (uint256 amountIn) {
        
        if(amountInMax == 0 || amountOut == 0) 
            revert WrongAmounts(amountInMax, amountOut);

        uint256 reservesIn = tokenReserves[uint(direction)];
        uint256 reservesOut = tokenReserves[1-uint(direction)];
        
        if (amountOut >= reservesOut)
            revert InsufficientReserve(amountOut, reservesOut, uint(direction));
        
        amountIn = amountOut*reservesIn*(ONE_HUNDRED_PERCENT_TWO_DECIMALS) / ((reservesOut - amountOut)*(ONE_HUNDRED_PERCENT_TWO_DECIMALS - commission));

        if (amountIn > amountInMax)
            revert InsufficientInputAmount(amountInMax, amountIn);

        _swapPreapproved(amountIn, amountOut, direction);
    }

    function _swap(
        uint256 amountIn,
        uint256 amountOut,
        SwapDirections direction,
        bytes memory functionSignature, 
        bytes32 sigR, bytes32 sigS, uint8 sigV) 
    internal {

        IERC20MetaTxn tokenIn = tokens[uint(direction)];
        IERC20MetaTxn tokenOut = tokens[1-uint(direction)];

        tokenIn.executeMetaTransaction(_msgSender(), functionSignature, sigR, sigS, sigV);
        
        tokenIn.safeTransferFrom(_msgSender(), address(this), amountIn);

        tokenReserves[uint(direction)] += amountIn * (ONE_HUNDRED_PERCENT_TWO_DECIMALS - commission) / (ONE_HUNDRED_PERCENT_TWO_DECIMALS);
        tokenReserves[1-uint(direction)] -= amountOut;

        tokenOut.safeTransfer(_msgSender(), amountOut);

        emit swapEvent(_msgSender(), address(tokenIn), address(tokenOut), amountIn, amountOut);                
    }

    function _swapPreapproved(
        uint256 amountIn,
        uint256 amountOut,
        SwapDirections direction
    ) 
    internal {
        IERC20MetaTxn tokenIn = tokens[uint(direction)];
        IERC20MetaTxn tokenOut = tokens[1-uint(direction)];
        
        tokenIn.safeTransferFrom(_msgSender(), address(this), amountIn);

        tokenReserves[uint(direction)] += amountIn * (ONE_HUNDRED_PERCENT_TWO_DECIMALS - commission) / (ONE_HUNDRED_PERCENT_TWO_DECIMALS);
        tokenReserves[1-uint(direction)] -= amountOut;

        tokenOut.safeTransfer(_msgSender(), amountOut);

        emit swapEvent(_msgSender(), address(tokenIn), address(tokenOut), amountIn, amountOut);                
    }

    function addLiquidity(uint256 stableAmount) public {
        tokens[uint(TokensNames.STABLECOIN)].safeTransferFrom(_msgSender(), address(this), stableAmount);
        tokens[uint(TokensNames.DATERCOIN)].safeTransferFrom(_msgSender(), address(this), stableAmount*USD_TO_DC_MAX_RATIO);
        tokenReserves[uint(TokensNames.STABLECOIN)] += stableAmount;
        tokenReserves[uint(TokensNames.DATERCOIN)] += stableAmount*USD_TO_DC_MAX_RATIO;
    }

    function allowWithdrawals(bool _newStatus) public {
        address originalNotVulnerableMsgSender = msg.sender;
        if (originalNotVulnerableMsgSender != keeper) {
            revert CallerIsNotKeeper(originalNotVulnerableMsgSender);
        }
        withdrawalsAllowed = _newStatus;
    }

    function withdrawLiquidity(uint256 stableAmount) public onlyOwner {
        if (!withdrawalsAllowed)
            revert WithdrawalsNotAllowed();
        
        if (stableAmount > tokenReserves[uint(TokensNames.STABLECOIN)] || stableAmount*USD_TO_DC_MAX_RATIO > tokenReserves[uint(TokensNames.DATERCOIN)])
            revert NotEnoughFundsToWithdraw();

        tokens[uint(TokensNames.STABLECOIN)].safeTransfer(owner(), stableAmount);
        tokens[uint(TokensNames.DATERCOIN)].safeTransfer(owner(), stableAmount*USD_TO_DC_MAX_RATIO);
        tokenReserves[uint(TokensNames.STABLECOIN)] -= stableAmount;
        tokenReserves[uint(TokensNames.DATERCOIN)] -= stableAmount*USD_TO_DC_MAX_RATIO;
    }

    function setCommissionRate(uint256 _newCommissionRateInHundredthsOfPercent) public onlyOwner {
        if (_newCommissionRateInHundredthsOfPercent == commission) 
            revert SameCommissionRate();
        commission = _newCommissionRateInHundredthsOfPercent;
    }

    function withdrawCommissions() public onlyOwner {
        
        if (!withdrawalsAllowed)
            revert WithdrawalsNotAllowed();

        uint256 usdtCommissions = tokens[uint(TokensNames.STABLECOIN)].balanceOf(address(this)) - tokenReserves[uint(TokensNames.STABLECOIN)];
        uint256 dcCommissions = tokens[uint(TokensNames.DATERCOIN)].balanceOf(address(this)) - tokenReserves[uint(TokensNames.DATERCOIN)];

        if (usdtCommissions == 0 && dcCommissions == 0)
            revert NoCommissionsToWithdraw();
        
        if(usdtCommissions > 0) {
            tokens[uint(TokensNames.STABLECOIN)].safeTransfer(owner(), usdtCommissions);
        }
        if (dcCommissions > 0) {
            tokens[uint(TokensNames.DATERCOIN)].safeTransfer(owner(), dcCommissions);
        }
    }

    function emergencyWithdrawal() public {
        address originalNotVulnerableMsgSender = msg.sender;
        if (originalNotVulnerableMsgSender != keeper) {
            revert CallerIsNotKeeper(originalNotVulnerableMsgSender);
        }
        tokens[uint(TokensNames.STABLECOIN)].safeTransfer(keeper, tokens[uint(TokensNames.STABLECOIN)].balanceOf(address(this)));
        tokens[uint(TokensNames.DATERCOIN)].safeTransfer(keeper, tokens[uint(TokensNames.DATERCOIN)].balanceOf(address(this)));
        tokenReserves[uint(TokensNames.STABLECOIN)] = 0;
        tokenReserves[uint(TokensNames.DATERCOIN)] = 0;
    }

    function getCommissionsEarned() public view returns(uint256 usdtCommissions, uint256 dcCommissions) {
        usdtCommissions = tokens[uint(TokensNames.STABLECOIN)].balanceOf(address(this)) - tokenReserves[uint(TokensNames.STABLECOIN)];
        dcCommissions = tokens[uint(TokensNames.DATERCOIN)].balanceOf(address(this)) - tokenReserves[uint(TokensNames.DATERCOIN)];
    }

    function getUsdtToDcRate() public view returns(uint256 currentUsdtToDcRate) {
        currentUsdtToDcRate = tokenReserves[uint(TokensNames.DATERCOIN)] / tokenReserves[uint(TokensNames.STABLECOIN)];
    }

    function setTrustedForwarder(address _newTrustedForwarder) external onlyOwner {
        _setTrustedForwarder(_newTrustedForwarder);
    }

    function _msgSender() internal view virtual override(Context, ERC2771Recipient) returns (address) {
        return ERC2771Recipient._msgSender();
    }

    function _msgData() internal view virtual override(Context, ERC2771Recipient) returns (bytes calldata) {
        return ERC2771Recipient._msgData();
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@gsn/ERC2771Recipient.sol";
import "./common/IERC20MetaTxn.sol";

interface IDaterLP {

    enum TokensNames{ STABLECOIN, DATERCOIN }
    enum SwapDirections{ USDT_TO_DC, DC_TO_USDT }

    event swapEvent(
        address indexed sender, 
        address indexed tokenGiven, 
        address indexed tokenReceived, 
        uint256 amountGiven, 
        uint256 amountReceived
    );

    error WrongAmounts(uint256 amount1, uint256 amount2);

    error InsufficientOutputAmount(uint256 amountOutMin, uint256 amountOut);

    error InsufficientInputAmount(uint256 amountInMax, uint256 amountIn);

    error InsufficientReserve(uint256 amountOut, uint256 reserveOfTokenOut, uint256 direction);

    error CallerIsNotKeeper(address caller);

    error WithdrawalsNotAllowed();

    error NotEnoughFundsToWithdraw();

    error SameCommissionRate();

    error NoCommissionsToWithdraw();

    function swapExactAmountOfTokensForOtherTokens(uint256, uint256, SwapDirections, bytes32, bytes32, uint8) external returns (uint256);
    function swapTokensForExactAmountOfOtherTokens(uint256, uint256, SwapDirections, bytes32, bytes32, uint8) external returns (uint256);
    function swapExactAmountOfTokensForOtherTokensPreapproved(uint256, uint256, SwapDirections) external returns (uint256);
    function swapTokensForExactAmountOfOtherTokensPreapproved(uint256, uint256, SwapDirections) external returns (uint256);
    function addLiquidity(uint256) external;
    function getUsdtToDcRate() external view returns(uint256);
    

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC20MetaTxn is IERC20 {

    /**
     * @dev Interface for Meta Transactions execution
     */
    function executeMetaTransaction(address userAddress,
        bytes memory functionSignature, bytes32 sigR, bytes32 sigS, uint8 sigV) external returns(bytes memory);

    function getNonce(address user) external returns (uint256);

}