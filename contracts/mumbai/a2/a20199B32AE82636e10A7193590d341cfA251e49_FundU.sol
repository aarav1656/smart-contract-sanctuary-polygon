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
pragma solidity ^0.8.0;

/*** CONTRACTS IMPORTED ***/
import "./wallet/UserWallet.sol";

/*** CONTRACT ***/
contract FundU is UserWallet {
    /*** STATE VARIABLES ***/
    uint256 private s_streamId;

    /*** MAPPINGS ***/

    // Streams
    mapping(uint256 => StreamData) private s_streamById; // Fund Id => Fund
    mapping(address => uint256[]) private s_beneficiaryStreamsIds; // address => [fund´s ids]
    mapping(address => uint256[]) private s_ownerStreamsIds; // address => [fund´s ids]

    /*** MODIFIERS ***/

    /**
     * @notice To check the stream´s owner by giving the id
     */
    modifier onlyStreamOwner(uint256 id) {
        StreamData memory stream = s_streamById[id];
        require(msg.sender == stream.owner, "Stream: Only stream owner allowed");
        _;
    }

    /**
     * @notice To check the stream´s beneficiary by giving the id
     */
    modifier onlyStreamBeneficiary(uint256 id) {
        StreamData memory stream = s_streamById[id];
        require(msg.sender == stream.beneficiary, "Stream: Only stream beneficiary allowed");
        _;
    }

    /*** CONSTRUCTOR ***/
    constructor(
        address _feeManager,
        address _CNET,
        address _USDC,
        address _USDT
    ) UserWallet(_CNET, _USDC, _USDT, _feeManager) {
        s_streamId = 0;
    }

    /*** MAIN FUNCTIONS ***/

    /*** INSTANT PAYMENTS RELATED ***/
    /**
     * @notice Unique and instant payments
     * @param beneficiary The one to receive the payment
     * @param amountToDeposit How much to deposit
     * @param tokenAddress Tokens address deposited
     */
    function instantPayments(
        address beneficiary,
        uint256 amountToDeposit,
        address tokenAddress
    ) external {
        uint256 time = block.timestamp;
        _newStream(beneficiary, amountToDeposit, time, time, tokenAddress);
    }

    /**
     * @notice Multiple instant payments
     * @param beneficiaries Array of the ones to receive the payments
     * @param amountToDeposit How much to deposit
     * @param tokenAddress Tokens address deposited
     */
    function multipleInstantPayments(
        address[] memory beneficiaries,
        uint256 amountToDeposit,
        address tokenAddress
    ) external {
        uint256 time = block.timestamp;
        for (uint i = 0; i < beneficiaries.length; i++) {
            address beneficiary = beneficiaries[i];
            _newStream(beneficiary, amountToDeposit, time, time, tokenAddress);
        }
    }

    /*** STREAMS RELATED ***/
    /**
     * @notice Create new streams
     * @param beneficiary The one to receive the stream
     * @param amountToDeposit How much to deposit
     * @param start When the stream starts
     * @param stop When the stream ends
     * @param tokenAddress Tokens address deposited
     */
    function newStream(
        address beneficiary,
        uint256 amountToDeposit,
        uint256 start,
        uint256 stop,
        address tokenAddress
    ) external {
        _newStream(beneficiary, amountToDeposit, start, stop, tokenAddress);
    }

    /**
     * @notice Create multiple new streams
     * @param beneficiaries The one to receive the stream
     * @param amountToDeposit How much to deposit
     * @param start When the stream starts
     * @param stop When the stream ends
     * @param tokenAddress Tokens address deposited
     */
    function multipleNewStream(
        address[] memory beneficiaries,
        uint256 amountToDeposit,
        uint256 start,
        uint256 stop,
        address tokenAddress
    ) external {
        for (uint i = 0; i < beneficiaries.length; i++) {
            address beneficiary = beneficiaries[i];
            _newStream(beneficiary, amountToDeposit, start, stop, tokenAddress);
        }
    }

    /**
     * @notice Pause an active stream
     * @param id Stream´s id
     * @dev It fails if the caller is not the owner
     * @dev It fails if the stream is not active
     */
    function pause(uint256 id) external onlyStreamOwner(id) {
        StreamData storage stream = s_streamById[id];

        require(stream.status == StreamStatus.Active, "Stream: Stream incorrect status");

        stream.status = StreamStatus.Paused;

        _withdrawPauseAndResume(id, stream.beneficiary);

        emit PauseStream(id, stream.owner, stream.beneficiary);
    }

    /**
     * @notice Resume a paused stream
     * @param id Stream´s id
     * @param paid True if it is a paid pause, false if not
     * @dev It fails if the caller is not the owner
     * @dev It fails if the stream is not active
     */
    function resumeStream(uint256 id, bool paid) public onlyStreamOwner(id) {
        StreamData storage stream = s_streamById[id];

        require(stream.status == StreamStatus.Paused, "Stream: Stream incorrect status");

        if (!paid) {
            _withdrawPauseAndResume(id, stream.owner);
        }

        if (stream.status != StreamStatus.Completed) {
            stream.status = StreamStatus.Active;

            emit ResumeStream(id, stream.owner, stream.beneficiary, paid);
        }
    }

    /**
     * @notice Cancel an existing stream
     * @param id Stream´s id
     * @dev If the beneficiary has some unclaimed balance, it will be transfer to him
     * The rest of the balance on the stream will be transfer to the owner
     * @dev It fails if the stream doesn´t exist
     * @dev It fails if the caller is not the owner
     * @dev It fails if the transfer fails
     */
    function cancelStream(uint256 id) external nonReentrant onlyStreamOwner(id) {
        StreamData storage stream = s_streamById[id];

        require(
            stream.status == StreamStatus.Active || stream.status == StreamStatus.Paused,
            "Stream: Stream incorrect status"
        );

        if (stream.status == StreamStatus.Paused) {
            resumeStream(id, false);
        }

        // Check the balances
        uint256 ownerRemainingBalance = balanceOfStreamOwner(id);
        uint256 beneficiaryRemainingBalance = balanceOfStreamBeneficiary(id);

        stream.status = StreamStatus.Canceled;
        stream.balanceLeft = 0;

        if (beneficiaryRemainingBalance > 0) {
            s_userBalanceByToken[stream.beneficiary][
                stream.tokenAddress
            ] += beneficiaryRemainingBalance;
        }
        if (ownerRemainingBalance > 0) {
            s_userBalanceByToken[stream.owner][stream.tokenAddress] += ownerRemainingBalance;
        }

        emit CancelStream(
            id,
            stream.owner,
            stream.beneficiary,
            ownerRemainingBalance,
            beneficiaryRemainingBalance
        );
    }

    /**
     * @notice Allow the beneficiary to withdraw the proceeds
     * @dev It fails if the stream doesn´t exist
     * @dev It fails if the caller is not the beneficiary
     * @dev It fails if the amount is bigger than the balance left
     * @dev It fails if the transfer fails
     */
    function withdrawAll() external nonReentrant {
        uint256[] memory beneficiaryIds = s_beneficiaryStreamsIds[msg.sender];
        for (uint i = 0; i < beneficiaryIds.length; i++) {
            uint256 id = beneficiaryIds[i];
            StreamData memory stream = s_streamById[id];

            if (stream.status == StreamStatus.Active) {
                _withdrawPauseAndResume(id, stream.beneficiary);
            }
        }
    }

    /**
     * @notice Allow the beneficiary to withdraw the proceeds
     * @param id Stream´s id
     * @dev It fails if the stream doesn´t exist
     * @dev It fails if the caller is not the beneficiary
     * @dev It fails if the amount is bigger than the balance left
     * @dev It fails if the transfer fails
     */
    function withdraw(uint256 id) public nonReentrant onlyStreamBeneficiary(id) {
        StreamData storage stream = s_streamById[id];

        require(stream.status == StreamStatus.Active, "Stream: Stream incorrect status");

        uint256 balance = 0;

        uint256 time = block.timestamp;

        if (stream.stopTime <= time) {
            balance = stream.balanceLeft;
            stream.balanceLeft = 0;
            stream.status = StreamStatus.Completed;

            emit Completed(id);
        } else {
            balance = balanceOfStreamBeneficiary(id);

            require(balance > 0, "Stream: No balance available");

            stream.balanceLeft = stream.balanceLeft - balance;
        }

        s_userBalanceByToken[stream.beneficiary][stream.tokenAddress] += balance;

        emit Withdraw(id, stream.owner, stream.beneficiary, stream.beneficiary, balance);
    }

    /**
     * @notice Create new streams
     * @param _beneficiary The one to receive the stream
     * @param _amountToDeposit How much to deposit
     * @param _start When the stream starts
     * @param _stop When the stream ends
     * @param _tokenAddress Tokens address deposited
     * @return The newly created stream´s id
     * @dev If start and stop are iqual it is an instant payment
     * @dev It fails if the beneficiary is the address zero
     * @dev It fails if the beneficiary is this contract
     * @dev It fails if the beneficiary is the owner
     * @dev It fails if there is no deposit
     * @dev It fails if the stopTime is less that the time when the function is called
     * @dev It fails if the transfer fails
     */
    function _newStream(
        address _beneficiary,
        uint256 _amountToDeposit,
        uint256 _start,
        uint256 _stop,
        address _tokenAddress
    ) internal nonReentrant returns (uint256) {
        require(
            _beneficiary != address(0x00) &&
                _beneficiary != address(this) &&
                _beneficiary != msg.sender,
            "Stream: Invalid beneficiary address"
        );
        require(_amountToDeposit != 0, "Stream: Zero amount");
        require(
            s_userBalanceByToken[msg.sender][_tokenAddress] >= _amountToDeposit,
            "Stream: Not enough balance"
        );
        uint256 _time = block.timestamp;
        uint256 _startTime;

        // If start is zero or less than the actual time the start time will be set to block.timestamp
        if (_start == 0 || _start < _time) {
            _startTime = _time;
        } else {
            _startTime = _start;
        }

        s_streamId++;

        StreamData storage stream = s_streamById[s_streamId];

        require(_stop >= _startTime, "Stream: Invalid stop time");

        uint256 _deposit;

        if (_tokenAddress == i_CNET) {
            _deposit = _amountToDeposit;
        } else {
            _deposit = feeManager.collectFee(_amountToDeposit, _tokenAddress);
        }

        if (_stop == _startTime) {
            // This will manage it like an instant payment
            stream.deposit = _deposit;
            stream.balanceLeft = 0;
            stream.startTime = _time;
            stream.stopTime = _time;
            stream.beneficiary = _beneficiary;
            stream.owner = msg.sender;
            stream.tokenAddress = _tokenAddress;
            stream.status = StreamStatus.Completed;

            // Transfer the balance directly to the beneficiary protocol´s wallet
            s_userBalanceByToken[_beneficiary][_tokenAddress] += _deposit;
        } else {
            // This will manage it like a stream
            uint256 _duration = _stop - _startTime;

            // This check is to ensure a rate per second, bigger than 0
            require(_amountToDeposit > _duration, "Stream: Deposit smaller than time left");

            stream.deposit = _deposit;
            stream.balanceLeft = _deposit;
            stream.startTime = _startTime;
            stream.stopTime = _stop;
            stream.beneficiary = _beneficiary;
            stream.owner = msg.sender;
            stream.tokenAddress = _tokenAddress;
            stream.status = StreamStatus.Active;
        }

        // The owner balance will be locked on streams and take away on instant payments
        s_userBalanceByToken[msg.sender][_tokenAddress] -= _amountToDeposit;

        s_beneficiaryStreamsIds[_beneficiary].push(s_streamId);
        s_ownerStreamsIds[msg.sender].push(s_streamId);

        emit NewStream(
            s_streamId,
            msg.sender,
            _beneficiary,
            _deposit,
            _tokenAddress,
            _startTime,
            _stop
        );

        return s_streamId;
    }

    /**
     * @notice An internal function to manage withdraws on the Pause and Resume functions
     * @param _id The stream´s id
     * @param _who The one who receive the transfer
     * @dev _who can be the stream´s beneficiary or the stream´s owner
     */
    function _withdrawPauseAndResume(uint256 _id, address _who) private {
        StreamData storage stream = s_streamById[_id];

        uint256 _balance = 0;
        uint256 _time = block.timestamp;

        if (stream.stopTime <= _time) {
            _balance = stream.balanceLeft;
            stream.balanceLeft = 0;
            stream.status = StreamStatus.Completed;

            emit Completed(_id);
        } else {
            _balance = balanceOfStreamBeneficiary(_id);
            stream.balanceLeft = stream.balanceLeft - _balance;
        }

        if (_balance > 0) {
            s_userBalanceByToken[_who][stream.tokenAddress] += _balance;

            emit Withdraw(_id, stream.owner, stream.beneficiary, _who, _balance);
        }
    }

    /*** VIEW / PURE FUNCTIONS ***/

    /*** STREAM´S INFO ***/
    /**
     * @notice Get the total number of streams
     */
    function getStreamsNumber() public view returns (uint256) {
        return s_streamId;
    }

    /**
     * @notice Get the Stream by giving the id
     * @return StreamData object
     */
    function getStreamById(uint256 id) public view returns (StreamData memory) {
        return s_streamById[id];
    }

    /*** STREAM BENEFICIARY´S INFO ***/
    /**
     * @notice Get all beneficiary streams
     * @return StreamData object
     */
    function getStreamByBeneficiary(address beneficiary) public view returns (uint256[] memory) {
        return s_beneficiaryStreamsIds[beneficiary];
    }

    /**
     * @notice Get a beneficiary´s total Streams
     * @return StreamData object
     */
    function getBeneficiaryStreamCount(address beneficiary) public view returns (uint256) {
        return s_beneficiaryStreamsIds[beneficiary].length;
    }

    /*** STREAM OWNER´S INFO ***/
    /**
     * @notice Get all owner streams
     * @return StreamData object
     */
    function getStreamByOwner(address owner) public view returns (uint256[] memory) {
        return s_ownerStreamsIds[owner];
    }

    /**
     * @notice Get a owner´s total Streams
     * @return StreamData object
     */
    function getOwnerStreamCount(address owner) public view returns (uint256) {
        return s_ownerStreamsIds[owner].length;
    }

    /*** AUXILIARS ***/
    /**
     * @notice Calculate the unclaimed balance of a stream´s beneficiary by giving the id
     * @return balance of beneficiary
     */
    function balanceOfStreamBeneficiary(uint256 id) public view returns (uint256 balance) {
        StreamData memory stream = s_streamById[id];

        uint256 time = timePassed(id);
        uint256 duration = stream.stopTime - stream.startTime;
        uint256 rate = stream.deposit / duration;
        uint256 beneficiaryBalance = time * rate;

        // If the deposit is bigger than balanceLeft there has been some withdraws
        if (stream.deposit > stream.balanceLeft) {
            // So check how much the beneficiary has withdraw and calculate the actual balance
            uint256 withdraws = stream.deposit - stream.balanceLeft;
            beneficiaryBalance = beneficiaryBalance - withdraws;
        }

        return beneficiaryBalance;
    }

    /**
     * @notice Calculate the balance of the stream´s owner by giving the id
     * @param id Stream´s id
     * @return balance of owner
     */
    function balanceOfStreamOwner(uint256 id) public view returns (uint256 balance) {
        StreamData memory stream = s_streamById[id];
        uint256 beneficiaryBalance = balanceOfStreamBeneficiary(id);

        uint256 ownerBalance = stream.balanceLeft - beneficiaryBalance;
        return ownerBalance;
    }

    /**
     * @notice Calculates the stram´s time passed by giving the id
     * @return time passed
     */
    function timePassed(uint256 id) public view returns (uint256 time) {
        StreamData memory stream = s_streamById[id];
        uint256 currentTime = block.timestamp;
        if (currentTime <= stream.startTime) return 0;
        if (currentTime < stream.stopTime) return currentTime - stream.startTime;
        return stream.stopTime - stream.startTime;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IFeeManager {
    event FeeCollected(uint256 feeCollected, address indexed token);

    function collectFee(uint256 depositAmount, address tokenAddress) external returns (uint256);

    function withdrawByToken(address tokenToWithdraw) external;

    function withdrawAllBalance() external;

    function setNewFeeManager(address _newManager) external;

    function setNewTransactionFee(uint256 _newTransactionFee) external;

    function getProtocolManager() external view returns (address);

    function getFeeManager() external view returns (address);

    function getTransactionFee() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*** CONTRACT ***/
contract FundUtils {
    /*** STATE VARIABLES ***/

    enum StreamStatus {
        Active,
        Paused,
        Canceled,
        Completed
    }

    /*
     * It refer to an instant payment when:
     * startTime === stopTime
     * balanceLeft === 0
     * StreamStatus === Completed
     */
    struct StreamData {
        uint256 deposit;
        uint256 balanceLeft; // If no withdraws must be equal to deposit
        uint256 startTime;
        uint256 stopTime;
        address beneficiary;
        address owner;
        address tokenAddress;
        StreamStatus status;
    }

    /*** EVENTS ***/
    event WalletDeposit(uint256 deposit, address indexed token, address indexed user);

    event WalletWithdraw(uint256 amount, address indexed token, address indexed user);

    event NewStream(
        uint256 indexed streamID,
        address indexed owner,
        address indexed beneficiary,
        uint256 depositedAmount,
        address token,
        uint256 startTime,
        uint256 stopTime
    );

    event PauseStream(uint256 indexed streamID, address indexed owner, address indexed beneficiary);

    event ResumeStream(
        uint256 indexed streamID,
        address indexed owner,
        address indexed beneficiary,
        bool paid
    );

    event CancelStream(
        uint256 indexed streamID,
        address indexed owner,
        address indexed beneficiary,
        uint256 ownerRemainingBalance,
        uint256 beneficiaryRemainingBalance
    );

    event Withdraw(
        uint256 indexed streamID,
        address indexed owner,
        address indexed beneficiary,
        address recipient,
        uint256 amount
    );

    event Completed(uint256 indexed streamID);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*** CONTRACTS IMPORTED ***/
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../utils/FundUtils.sol";

/*** INTERFACES IMPORTED ***/
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IFeeManager.sol";

/*** LIBRARIES IMPORTED ***/
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/*** CONTRACT ***/
contract UserWallet is ReentrancyGuard, FundUtils {
    /*** LIBRARIES USED ***/
    using SafeERC20 for IERC20;

    // Tokens allowed on protocol
    address public immutable i_CNET;
    address public immutable i_USDC;
    address public immutable i_USDT;
    IERC20 private immutable CNET;
    IERC20 private immutable USDC;
    IERC20 private immutable USDT;

    // Fee manager
    address private s_feeManager;
    IFeeManager public immutable feeManager;

    /*** MAPPINGS ***/

    // Funding wallet
    // user => (tokenAddress => balance)
    mapping(address => mapping(address => uint256)) public s_userBalanceByToken;

    /*** CONSTRUCTOR ***/
    constructor(address _CNET, address _USDC, address _USDT, address _feeManager) {
        i_CNET = _CNET;
        i_USDC = _USDC;
        i_USDT = _USDT;

        CNET = IERC20(i_CNET);
        USDC = IERC20(i_USDC);
        USDT = IERC20(i_USDT);

        s_feeManager = _feeManager;
        feeManager = IFeeManager(s_feeManager);

        // Infinite approvals
        CNET.safeApprove(address(feeManager), type(uint256).max);
        USDC.safeApprove(address(feeManager), type(uint256).max);
        USDT.safeApprove(address(feeManager), type(uint256).max);
    }

    /*** MAIN FUNCTIONS ***/
    /*** WALLET RELATED ***/
    /**
     * @notice A method to fund the wallet
     * @param deposit The amount to fund the wallet
     * @param tokenAddress The token to fund
     * @dev It fails if the token is not CNET, USDC or USDT
     * @dev It fails if the deposit is "0"
     */
    function depositOnWallet(uint256 deposit, address tokenAddress) external returns (uint256) {
        require(deposit != 0, "Wallet: Zero amount");
        /*
        require(
            tokenAddress == i_CNET || tokenAddress == i_USDC || tokenAddress == i_USDT,
            "Wallet: Only CNET, USDC and USDT"
        );
        */

        s_userBalanceByToken[msg.sender][tokenAddress] += deposit;

        IERC20 token = IERC20(tokenAddress);
        token.safeTransferFrom(msg.sender, address(this), deposit);

        emit WalletDeposit(deposit, tokenAddress, msg.sender);
        return deposit;
    }

    /**
     * @notice A method to withdraw from wallet
     * @param amount The amount to withdraw from wallet
     * @param tokenAddress The token to withdrw
     * @dev It fails if the token is not CNET, USDC or USDT
     * @dev It fails if the amount is "0"
     * @dev It fails if the user does not have enough balance
     */
    function withdrawFromWallet(
        uint amount,
        address tokenAddress
    ) external nonReentrant returns (uint256) {
        require(amount != 0, "Wallet: Zero amount");
        require(
            tokenAddress == i_CNET || tokenAddress == i_USDC || tokenAddress == i_USDT,
            "Wallet: Only CNET, USDC and USDT"
        );
        require(
            s_userBalanceByToken[msg.sender][tokenAddress] >= amount,
            "Wallet: Not enough balance"
        );

        s_userBalanceByToken[msg.sender][tokenAddress] -= amount;

        IERC20 token = IERC20(tokenAddress);
        token.safeTransfer(msg.sender, amount);

        emit WalletWithdraw(amount, tokenAddress, msg.sender);
        return amount;
    }

    /*** VIEW / PURE FUNCTIONS ***/

    /*** USER´S INFO ***/
    /**
     * @notice A method to know user´s balances
     * @param token The token to know user´s balance
     */
    function getWalletBalance(address token) public view returns (uint256) {
        return s_userBalanceByToken[msg.sender][token];
    }

    /*** TOKEN´S INFO ***/

    function getCnetAddress() public view returns (address) {
        return i_CNET;
    }

    function getUsdcAddress() public view returns (address) {
        return i_USDC;
    }

    function getUsdtAddress() public view returns (address) {
        return i_USDT;
    }
}