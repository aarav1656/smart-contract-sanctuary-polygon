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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

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
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

import "../interfaces/IAdapter.sol";
import "../libraries/Transfers.sol";
import "../libraries/Errors.sol";

abstract contract AdapterBase is IAdapter {
    /// @notice Target contract for this adapter
    address public immutable target;

    /// @notice Adapter constructor
    /// @param target_ Target contract for this adapter
    constructor(address target_) {
        require(target_ != address(0), Errors.ZERO_ADDRESS);
        target = target_;
    }

    /// @notice Approves incoming token to target and executes call
    /// @param tokenIn Incoming token
    /// @param amountIn Incoming amount
    /// @param args Encoded additional arguments for current adapter
    function call(
        address tokenIn,
        uint256 amountIn,
        bytes memory args
    ) external payable virtual override {
        Transfers.approve(tokenIn, target, amountIn);
        _executeCall(tokenIn, amountIn, args);
    }

    /// @notice Executes target call with given params
    /// @param tokenIn Incoming token
    /// @param amountIn Incoming amount
    /// @param args Encoded additional arguments for current adapter
    function _executeCall(
        address tokenIn,
        uint256 amountIn,
        bytes memory args
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./AdapterBase.sol";
import "../interfaces/external/ILiFi.sol";
import "../libraries/Errors.sol";

// https://transferto.xyz/swap?fromChain=pol

// via WebSite  Polygon USDC -> BSC USDC
// approve - https://polygonscan.com/tx/0x9bc4b9fd7b8e1f7a3724597df4f19a240f0bc36de630e460f6ca1b372de8bd94
// swap - https://polygonscan.com/tx/0x47abd33ac3fff33786294e11615fe928cbb88373d12477aaa560be7608ec00cc
// recv - https://bscscan.com/tx/0xfdc156af95e4528f21df9b89c203f87620b6c0893148fa33cc579234a672d5bd

// via WebSite BSC USDC -> Polygon USDT
//   1 step - swap USDC -> WETH with ParaSwap
//             approve https://bscscan.com/tx/0xa5dfe2007795bd5c804dc7465b673214a4834cbb0507c0da166c048a5866517b
//             call https://bscscan.com/tx/0x9871beae2801c1d1417192c1e4512dbd631843fe9b64decfb52570a525a210d8
//   2 step - bridge WETH bsc->polygon via Hyphen
//             approve https://bscscan.com/tx/0x9bfacc4ac555db45be5f29fdc1c42e539fabb75120c574123c2e8ccb06227d20
//             call https://bscscan.com/tx/0xf214f1731d30fb4899a9dfec2e51445deda8cc60deed08bc923cfcf54aa5fdaf
//             recv https://polygonscan.com/tx/0xfd7100804af59f60533685b0237dab5dcf340dd7419629a2045bd355f655e416
//   3 step - swap WETH -> USDT via OpenOcean
//             approve https://polygonscan.com/tx/0xc3ee677bc1d6397a5df38324abe2922c013a5ac4669f08abc683c8043c5032b2
//             SWAP - FAILED

// via WebSite BSC USDC -> Polygon USDT in 1 tx
// approve - https://bscscan.com/tx/0xd7e10ac056edff24e836aab7d21869f2efe09d97b7e6f6bbe6e07853489b8cd1
// swap - https://bscscan.com/tx/0xda75628ef0b4a65413c3c440a130957f558079caccedacc1db6ce6e8b29c774c
// recv - https://polygonscan.com/tx/0xb67a7a3d71983ca61f67f7497d98eacbd49783f67a0c4704c20f924101fb4033

contract LiFiAdapter is AdapterBase {
    using Address for address;

    constructor(address target_) AdapterBase(target_) {}

    function _executeCall(
        address tokenIn,
        uint256 amountIn,
        bytes memory args // raw lifiTxData
    ) internal override {
        (
            _ILiFi.LiFiData memory argsLiFiData,
            ITransactionManager.PrepareArgs memory argsPrepareArgs
        ) = abi.decode(
                args,
                (_ILiFi.LiFiData, ITransactionManager.PrepareArgs)
            );

        require(
            argsLiFiData.sendingAssetId == tokenIn,
            Errors.INVALID_INCOMING_TOKEN
        );
        require(
            argsLiFiData.amount >= amountIn,
            Errors.INVALID_INCOMING_AMOUNT
        );
        argsPrepareArgs.amount = amountIn; // change amount to actual inside calldata

        ILiFi(target).startBridgeTokensViaNXTP({
            _lifiData: argsLiFiData,
            _nxtpData: argsPrepareArgs
        });
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

interface IAdapter {
    /// @notice Executes call with given params
    /// @param tokenIn Incoming token
    /// @param amountIn Incoming amount
    /// @param args Encoded additional arguments for current adapter
    function call(
        address tokenIn,
        uint256 amountIn,
        bytes memory args
    ) external payable;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// from https://github.com/lifinance/contracts/tree/master/src/Interfaces

interface _ILiFi {
    struct LiFiData {
        bytes32 transactionId;
        string integrator;
        address referrer;
        address sendingAssetId;
        address receivingAssetId;
        address receiver;
        uint256 destinationChainId;
        uint256 amount;
    }
}


interface ITransactionManager {
    // Structs

    // Holds all data that is constant between sending and
    // receiving chains. The hash of this is what gets signed
    // to ensure the signature can be used on both chains.
    struct InvariantTransactionData {
        address receivingChainTxManagerAddress;
        address user;
        address router;
        address initiator; // msg.sender of sending side
        address sendingAssetId;
        address receivingAssetId;
        address sendingChainFallback; // funds sent here on cancel
        address receivingAddress;
        address callTo;
        uint256 sendingChainId;
        uint256 receivingChainId;
        bytes32 callDataHash; // hashed to prevent free option
        bytes32 transactionId;
    }

    // Holds all data that varies between sending and receiving
    // chains. The hash of this is stored onchain to ensure the
    // information passed in is valid.
    struct VariantTransactionData {
        uint256 amount;
        uint256 expiry;
        uint256 preparedBlockNumber;
    }

    // All Transaction data, constant and variable
    struct TransactionData {
        address receivingChainTxManagerAddress;
        address user;
        address router;
        address initiator; // msg.sender of sending side
        address sendingAssetId;
        address receivingAssetId;
        address sendingChainFallback;
        address receivingAddress;
        address callTo;
        bytes32 callDataHash;
        bytes32 transactionId;
        uint256 sendingChainId;
        uint256 receivingChainId;
        uint256 amount;
        uint256 expiry;
        uint256 preparedBlockNumber; // Needed for removal of active blocks on fulfill/cancel
    }

    // The structure of the signed data for fulfill
    struct SignedFulfillData {
        bytes32 transactionId;
        uint256 relayerFee;
        string functionIdentifier; // "fulfill" or "cancel"
        uint256 receivingChainId; // For domain separation
        address receivingChainTxManagerAddress; // For domain separation
    }

    // The structure of the signed data for cancellation
    struct SignedCancelData {
        bytes32 transactionId;
        string functionIdentifier;
        uint256 receivingChainId;
        address receivingChainTxManagerAddress; // For domain separation
    }

    /**
     * Arguments for calling prepare()
     * @param invariantData The data for a crosschain transaction that will
     *                      not change between sending and receiving chains.
     *                      The hash of this data is used as the key to store
     *                      the inforamtion that does change between chains
     *                      (amount,expiry,preparedBlock) for verification
     * @param amount The amount of the transaction on this chain
     * @param expiry The block.timestamp when the transaction will no longer be
     *               fulfillable and is freely cancellable on this chain
     * @param encryptedCallData The calldata to be executed when the tx is
     *                          fulfilled. Used in the function to allow the user
     *                          to reconstruct the tx from events. Hash is stored
     *                          onchain to prevent shenanigans.
     * @param encodedBid The encoded bid that was accepted by the user for this
     *                   crosschain transfer. It is supplied as a param to the
     *                   function but is only used in event emission
     * @param bidSignature The signature of the bidder on the encoded bid for
     *                     this transaction. Only used within the function for
     *                     event emission. The validity of the bid and
     *                     bidSignature are enforced offchain
     * @param encodedMeta The meta for the function
     */
    struct PrepareArgs {
        InvariantTransactionData invariantData;
        uint256 amount;
        uint256 expiry;
        bytes encryptedCallData;
        bytes encodedBid;
        bytes bidSignature;
        bytes encodedMeta;
    }

    /**
     * @param txData All of the data (invariant and variant) for a crosschain
     *               transaction. The variant data provided is checked against
     *               what was stored when the `prepare` function was called.
     * @param relayerFee The fee that should go to the relayer when they are
     *                   calling the function on the receiving chain for the user
     * @param signature The users signature on the transaction id + fee that
     *                  can be used by the router to unlock the transaction on
     *                  the sending chain
     * @param callData The calldata to be sent to and executed by the
     *                 `FulfillHelper`
     * @param encodedMeta The meta for the function
     */
    struct FulfillArgs {
        TransactionData txData;
        uint256 relayerFee;
        bytes signature;
        bytes callData;
        bytes encodedMeta;
    }

    /**
     * Arguments for calling cancel()
     * @param txData All of the data (invariant and variant) for a crosschain
     *               transaction. The variant data provided is checked against
     *               what was stored when the `prepare` function was called.
     * @param signature The user's signature that allows a transaction to be
     *                  cancelled by a relayer
     * @param encodedMeta The meta for the function
     */
    struct CancelArgs {
        TransactionData txData;
        bytes signature;
        bytes encodedMeta;
    }

    // Adding/removing asset events
    event RouterAdded(address indexed addedRouter, address indexed caller);

    event RouterRemoved(address indexed removedRouter, address indexed caller);

    // Adding/removing router events
    event AssetAdded(address indexed addedAssetId, address indexed caller);

    event AssetRemoved(address indexed removedAssetId, address indexed caller);

    // Liquidity events
    event LiquidityAdded(address indexed router, address indexed assetId, uint256 amount, address caller);

    event LiquidityRemoved(address indexed router, address indexed assetId, uint256 amount, address recipient);

    // Transaction events
    event TransactionPrepared(
        address indexed user,
        address indexed router,
        bytes32 indexed transactionId,
        TransactionData txData,
        address caller,
        PrepareArgs args
    );

    event TransactionFulfilled(
        address indexed user,
        address indexed router,
        bytes32 indexed transactionId,
        FulfillArgs args,
        bool success,
        bool isContract,
        bytes returnData,
        address caller
    );

    event TransactionCancelled(
        address indexed user,
        address indexed router,
        bytes32 indexed transactionId,
        CancelArgs args,
        address caller
    );

    // Getters
    function getChainId() external view returns (uint256);

    function getStoredChainId() external view returns (uint256);

    // Owner only methods
    function addRouter(address router) external;

    function removeRouter(address router) external;

    function addAssetId(address assetId) external;

    function removeAssetId(address assetId) external;

    // Router only methods
    function addLiquidityFor(
        uint256 amount,
        address assetId,
        address router
    ) external payable;

    function addLiquidity(uint256 amount, address assetId) external payable;

    function removeLiquidity(
        uint256 amount,
        address assetId,
        address payable recipient
    ) external;

    // Methods for crosschain transfers
    // called in the following order (in happy case)
    // 1. prepare by user on sending chain
    // 2. prepare by router on receiving chain
    // 3. fulfill by user on receiving chain
    // 4. fulfill by router on sending chain
    function prepare(PrepareArgs calldata args) external payable returns (TransactionData memory);

    function fulfill(FulfillArgs calldata args) external returns (TransactionData memory);

    function cancel(CancelArgs calldata args) external returns (TransactionData memory);
}


interface ILiFi is _ILiFi {
    /// @notice This function starts a cross-chain transaction using the NXTP protocol
    /// @param _lifiData data used purely for tracking and analytics
    /// @param _nxtpData data needed to complete an NXTP cross-chain transaction
    function startBridgeTokensViaNXTP(
        LiFiData calldata _lifiData,
        ITransactionManager.PrepareArgs calldata _nxtpData
    ) external payable;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

library Errors {
    // ViaRouter

    string internal constant INSUFFICIENT_COLLECTED_FEES = "ICF";

    string internal constant EMPTY_CALLS = "EC";

    string internal constant DEADLINE_HAS_PASSED = "DHP";

    string internal constant DOUBLE_EXECUTION = "DE";

    string internal constant NONCONITNUOUS_SWAP_PATH = "NSP";

    string internal constant NOT_AN_ADAPTER = "NAA";

    string internal constant SHOULD_SPECIFY_RECEIVER = "SSR";

    string internal constant NOT_SIGNED_BY_VALIDATOR = "NSV";

    string internal constant NOT_AN_OPERATOR = "NAO";

    // Transfers

    string internal constant INVALID_MESSAGE_VALUE = "IMV";

    string internal constant INVALID_RECEIVED_AMOUNT = "IRA";

    // Adapters

    string internal constant INVALID_INCOMING_TOKEN = "IIT";

    string internal constant INVALID_INCOMING_AMOUNT = "IIA";

    // Generic

    string internal constant ZERO_ADDRESS = "ZA";
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./Errors.sol";

library Transfers {
    using SafeERC20 for IERC20;
    using Address for address payable;

    /// @notice Structure describing multi-chain token, consists of address and chain id
    struct Token {
        address token;
        uint96 chainId;
    }

    /// @notice Checks if to token structures are equal
    /// @param a First token
    /// @param b Second token
    /// @return _ True if equal, false otherwise
    function equals(Token memory a, Token memory b)
        internal
        pure
        returns (bool)
    {
        return a.token == b.token && a.chainId == b.chainId;
    }

    /// @notice Transfers (or checks sent value) given token from given address to running contract
    /// @param token Token to transfer (address(0) to check native sent value)
    /// @param from Address to transfer from
    /// @param amount Amount to transfer
    function transferIn(
        address token,
        address from,
        uint256 amount
    ) internal {
        if (token == address(0)) {
            require(msg.value == amount, Errors.INVALID_MESSAGE_VALUE);
        } else {
            require(msg.value == 0, Errors.INVALID_MESSAGE_VALUE);
            uint256 balanceBefore = IERC20(token).balanceOf(address(this));
            IERC20(token).safeTransferFrom(from, address(this), amount);
            require(
                IERC20(token).balanceOf(address(this)) - balanceBefore ==
                    amount,
                Errors.INVALID_RECEIVED_AMOUNT
            );
        }
    }

    /// @notice Transfers given token from running contract to given address
    /// @param token Token to transfer (address(0) to transfer native token)
    /// @param to Address to transfer to
    /// @param amount Amount to transfer
    function transferOut(
        address token,
        address to,
        uint256 amount
    ) internal {
        if (token == address(0)) {
            payable(to).sendValue(amount);
        } else {
            IERC20(token).safeTransfer(to, amount);
        }
    }

    /// @notice Approves given token to given spender (with checks for address(0) as native)
    /// @param token Token to approve
    /// @param spender Spender address
    /// @param amount Amount to approve
    function approve(
        address token,
        address spender,
        uint256 amount
    ) internal {
        if (token == address(0)) {
            return;
        }

        uint256 allowance = IERC20(token).allowance(address(this), spender);
        if (allowance > 0) {
            // https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
            IERC20(token).safeApprove(spender, 0);
        }
        IERC20(token).safeIncreaseAllowance(spender, amount);
    }

    /// @notice Gets balance of given token
    /// @param token Token to get balance of (address(0) for native token)
    function getBalance(address token) internal view returns (uint256) {
        if (address(token) == address(0)) {
            return address(this).balance;
        } else {
            return IERC20(token).balanceOf(address(this));
        }
    }

    /// @notice Gets balance of given token (by multi-chain structure)
    /// @param token Token to get balance of (address(0) for native token)
    function getBalance(Token memory token) internal view returns (uint256) {
        if (token.chainId == block.chainid) {
            return getBalance(token.token);
        } else {
            return 0;
        }
    }
}