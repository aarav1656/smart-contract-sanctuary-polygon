/**
 *Submitted for verification at polygonscan.com on 2022-11-07
*/

// File: @openzeppelin/contracts/utils/Address.sol


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

// File: @openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol


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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: @openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;




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

// File: @chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol


pragma solidity ^0.8.4;

/** ****************************************************************************
 * @notice Interface for contracts using VRF randomness
 * *****************************************************************************
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * @dev to Vera the verifier in such a way that Vera can be sure he's not
 * @dev making his output up to suit himself. Reggie provides Vera a public key
 * @dev to which he knows the secret key. Each time Vera provides a seed to
 * @dev Reggie, he gives back a value which is computed completely
 * @dev deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * @dev correctly computed once Reggie tells it to her, but without that proof,
 * @dev the output is indistinguishable to her from a uniform random sample
 * @dev from the output space.
 *
 * @dev The purpose of this contract is to make it easy for unrelated contracts
 * @dev to talk to Vera the verifier about the work Reggie is doing, to provide
 * @dev simple access to a verifiable source of randomness. It ensures 2 things:
 * @dev 1. The fulfillment came from the VRFCoordinator
 * @dev 2. The consumer contract implements fulfillRandomWords.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constructor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash). Create subscription, fund it
 * @dev and your consumer contract as a consumer of it (see VRFCoordinatorInterface
 * @dev subscription management functions).
 * @dev Call requestRandomWords(keyHash, subId, minimumRequestConfirmations,
 * @dev callbackGasLimit, numWords),
 * @dev see (VRFCoordinatorInterface for a description of the arguments).
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomWords method.
 *
 * @dev The randomness argument to fulfillRandomWords is a set of random words
 * @dev generated from your requestId and the blockHash of the request.
 *
 * @dev If your contract could have concurrent requests open, you can use the
 * @dev requestId returned from requestRandomWords to track which response is associated
 * @dev with which randomness request.
 * @dev See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ.
 *
 * *****************************************************************************
 * @dev SECURITY CONSIDERATIONS
 *
 * @dev A method with the ability to call your fulfillRandomness method directly
 * @dev could spoof a VRF response with any random value, so it's critical that
 * @dev it cannot be directly called by anything other than this base contract
 * @dev (specifically, by the VRFConsumerBase.rawFulfillRandomness method).
 *
 * @dev For your users to trust that your contract's random behavior is free
 * @dev from malicious interference, it's best if you can write it so that all
 * @dev behaviors implied by a VRF response are executed *during* your
 * @dev fulfillRandomness method. If your contract must store the response (or
 * @dev anything derived from it) and use it later, you must ensure that any
 * @dev user-significant behavior which depends on that stored value cannot be
 * @dev manipulated by a subsequent VRF request.
 *
 * @dev Similarly, both miners and the VRF oracle itself have some influence
 * @dev over the order in which VRF responses appear on the blockchain, so if
 * @dev your contract could have multiple VRF requests in flight simultaneously,
 * @dev you must ensure that the order in which the VRF responses arrive cannot
 * @dev be used to manipulate your contract's user-significant behavior.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request. It is for this reason that
 * @dev that you can signal to an oracle you'd like them to wait longer before
 * @dev responding to the request (however this is not enforced in the contract
 * @dev and so remains effective only in the case of unmodified oracle software).
 */
abstract contract VRFConsumerBaseV2 {
  error OnlyCoordinatorCanFulfill(address have, address want);
  address private immutable vrfCoordinator;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   */
  constructor(address _vrfCoordinator) {
    vrfCoordinator = _vrfCoordinator;
  }

  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBaseV2 expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomWords the VRF output expanded to the requested number of words
   */
  function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal virtual;

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomWords(uint256 requestId, uint256[] memory randomWords) external {
    if (msg.sender != vrfCoordinator) {
      revert OnlyCoordinatorCanFulfill(msg.sender, vrfCoordinator);
    }
    fulfillRandomWords(requestId, randomWords);
  }
}

// File: @chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol


pragma solidity ^0.8.0;

interface VRFCoordinatorV2Interface {
  /**
   * @notice Get configuration relevant for making requests
   * @return minimumRequestConfirmations global min for request confirmations
   * @return maxGasLimit global max for request gas limit
   * @return s_provingKeyHashes list of registered key hashes
   */
  function getRequestConfig()
    external
    view
    returns (
      uint16,
      uint32,
      bytes32[] memory
    );

  /**
   * @notice Request a set of random words.
   * @param keyHash - Corresponds to a particular oracle job which uses
   * that key for generating the VRF proof. Different keyHash's have different gas price
   * ceilings, so you can select a specific one to bound your maximum per request cost.
   * @param subId  - The ID of the VRF subscription. Must be funded
   * with the minimum subscription balance required for the selected keyHash.
   * @param minimumRequestConfirmations - How many blocks you'd like the
   * oracle to wait before responding to the request. See SECURITY CONSIDERATIONS
   * for why you may want to request more. The acceptable range is
   * [minimumRequestBlockConfirmations, 200].
   * @param callbackGasLimit - How much gas you'd like to receive in your
   * fulfillRandomWords callback. Note that gasleft() inside fulfillRandomWords
   * may be slightly less than this amount because of gas used calling the function
   * (argument decoding etc.), so you may need to request slightly more than you expect
   * to have inside fulfillRandomWords. The acceptable range is
   * [0, maxGasLimit]
   * @param numWords - The number of uint256 random values you'd like to receive
   * in your fulfillRandomWords callback. Note these numbers are expanded in a
   * secure way by the VRFCoordinator from a single random value supplied by the oracle.
   * @return requestId - A unique identifier of the request. Can be used to match
   * a request to a response in fulfillRandomWords.
   */
  function requestRandomWords(
    bytes32 keyHash,
    uint64 subId,
    uint16 minimumRequestConfirmations,
    uint32 callbackGasLimit,
    uint32 numWords
  ) external returns (uint256 requestId);

  /**
   * @notice Create a VRF subscription.
   * @return subId - A unique subscription id.
   * @dev You can manage the consumer set dynamically with addConsumer/removeConsumer.
   * @dev Note to fund the subscription, use transferAndCall. For example
   * @dev  LINKTOKEN.transferAndCall(
   * @dev    address(COORDINATOR),
   * @dev    amount,
   * @dev    abi.encode(subId));
   */
  function createSubscription() external returns (uint64 subId);

  /**
   * @notice Get a VRF subscription.
   * @param subId - ID of the subscription
   * @return balance - LINK balance of the subscription in juels.
   * @return reqCount - number of requests for this subscription, determines fee tier.
   * @return owner - owner of the subscription.
   * @return consumers - list of consumer address which are able to use this subscription.
   */
  function getSubscription(uint64 subId)
    external
    view
    returns (
      uint96 balance,
      uint64 reqCount,
      address owner,
      address[] memory consumers
    );

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @param newOwner - proposed new owner of the subscription
   */
  function requestSubscriptionOwnerTransfer(uint64 subId, address newOwner) external;

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @dev will revert if original owner of subId has
   * not requested that msg.sender become the new owner.
   */
  function acceptSubscriptionOwnerTransfer(uint64 subId) external;

  /**
   * @notice Add a consumer to a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - New consumer which can use the subscription
   */
  function addConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Remove a consumer from a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - Consumer to remove from the subscription
   */
  function removeConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Cancel a subscription
   * @param subId - ID of the subscription
   * @param to - Where to send the remaining LINK to
   */
  function cancelSubscription(uint64 subId, address to) external;
}

// File: contracts/SwertRafHosted.sol


pragma solidity ^0.8.7;





contract JuanFourRafCon is VRFConsumerBaseV2 {
    VRFCoordinatorV2Interface COORDINATOR;

    // Your subscription ID.
    uint64 s_subscriptionId;

    // Goerli coordinator. For other networks,
    // see https://docs.chain.link/docs/vrf-contracts/#configurations
    address vrfCoordinator = 0x7a1BaC17Ccc5b313516C5E16fb24f7659aA5ebed; //mumbai testnet
    // address vrfCoordinator = 0xAE975071Be8F8eE67addBC1A82488F1C24858067;
    // The gas lane to use, which specifies the maximum gas price to bump to.
    // For a list of available gas lanes on each network,
    // see https://docs.chain.link/docs/vrf-contracts/#configurations
    bytes32 keyHash = 0x4b09e658ed251bcafeebbc69400383d49f344ace09b9576fe248bb02c003fe9f; //mumbai testnet
    // bytes32 keyHash = 0xcc294a196eeeb44da2888d17c0625cc88d70d9760a69d58d853ba6581a9ab0cd;

    // Depends on the number of requested values that you want sent to the
    // fulfillRandomWords() function. Storing each word costs about 20,000 gas,
    // so 100,000 is a safe default for this example contract. Test and adjust
    // this limit based on the network that you select, the size of the request,
    // and the processing of the callback request in the fulfillRandomWords()
    // function.
    uint32 callbackGasLimit = 200000;

    // The default is 3, but you can set this higher.
    uint16 requestConfirmations = 3;

    // For this example, retrieve 2 random values in one request.
    // Cannot exceed VRFCoordinatorV2.MAX_NUM_WORDS.
    uint32 numWords =  3;

    uint256[] public s_randomWords;
    uint256 public s_requestId;
    address payable public s_owner;
    uint public balance = 0;
    bool public isActive = true;
    IERC20 token_address;
    uint lastCreatedRoom;
    struct Room{
        bool active;
        address lessee;
        uint l_rake;
        uint l_rakeCollected;
        uint lease_duration; //2592000;
        uint lessee_updatedAt;
        uint entryfee;
        uint rentFee;
        uint pot;
        uint burn_rate;
        uint limit;
        address[] s_players;
        mapping(uint256 => uint256) prizes;
        mapping(address => uint256) s_player_wallets;
        mapping(uint256=>address) winning_places;
    }

    mapping(uint256=>Room) public raffle_room;

    mapping(uint=>bool) prizeSelection;

    uint[] public readyRooms;

    event TransferReceived(uint room_number,address _from, uint _amount, uint playersLength);
    event WinnerPicked(uint room_number,uint place, address player,uint amount, uint groupid); 
    event RakeTransfer(uint room_number,uint amount, address rakeCollector); 
    event ContractReset(uint room_number,uint timestamp); 
    event ChangeContractState(string state); 
    event ChangeContractStateByRoom(uint room_number,string state); 
    event PlayerWithdraw(uint room_number,address player,uint playersLength); 
    event LeaseExpired(uint room_number,uint time);
    event NewRaffle(uint room_number, uint rentFee, uint lease_duration, bool active);
    event NewLease(uint room_number,address lessee,uint newEntryfee,uint pot,uint limit,bool active,uint grandPrize);
    event OpenRaffleLease(uint room_number);

    constructor(uint64 subscriptionId,IERC20 tok_address) VRFConsumerBaseV2(vrfCoordinator) {
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        s_owner = payable(msg.sender);
        s_subscriptionId = subscriptionId;
        token_address = tok_address;
        prizeSelection[50] = true;
        prizeSelection[75] = true;
        prizeSelection[100] = true;
    }

    //B: Admin functions
    function createRaffle(uint room_number, uint256 _rentFee,uint _lease_duration) public onlyOwner{
      require(raffle_room[room_number].active == false,"This room is taken");
        Room storage newRaffle = raffle_room[room_number];
        newRaffle.active = false;
        newRaffle.lease_duration = _lease_duration;
        newRaffle.lessee_updatedAt = block.timestamp;
        newRaffle.entryfee = 1; 
        newRaffle.lessee = msg.sender;
        newRaffle.rentFee = _rentFee;
        lastCreatedRoom = room_number;
        emit NewRaffle(room_number,_rentFee,_lease_duration,false);
    }

    //General controle --- WARNING - this will pause all contracts
    function pauseContract() public onlyOwner{
        isActive = false;
        emit ChangeContractState("INACTIVE");
    }

    function reactiveContract() public onlyOwner{
        isActive = true;
        emit ChangeContractState("ACTIVE");
    }

    //
    function pauseContractByRoom(uint room_number) public onlyOwner{
        raffle_room[room_number].active = false;
        emit ChangeContractStateByRoom(room_number,"INACTIVE");
    }

    function reactiveContractByRoom(uint room_number) public onlyOwner{
        raffle_room[room_number].active = true;
        emit ChangeContractStateByRoom(room_number,"ACTIVE");
    }
    //E: Admin functions


    //B: Oracle
    // Assumes the subscription is funded sufficiently.
    function _requestRandomWords() internal {
        // Will revert if subscription is not set and funded.
        s_requestId = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
    }


    function fulfillRandomWords(
        uint256, /* requestId */
        uint256[] memory randomWords
    ) internal override {
        s_randomWords = randomWords;
        for(uint x = 0; x < readyRooms.length; x++){
            uint room = readyRooms[x];
            uint groupid = room + block.timestamp;
            for(uint i = 0; i < numWords; i++) {
                uint place_index = randomWords[i] % raffle_room[room].s_players.length;
                address winner = raffle_room[room].s_players[place_index];
                emit WinnerPicked(room,i, winner, raffle_room[room].prizes[i],groupid); 
                raffle_room[room].s_player_wallets[winner] = raffle_room[room].s_player_wallets[winner] + raffle_room[room].prizes[i];
                remove(room,place_index);
            }
            // rakeCollection(room);
            resetContract(room);
            removeRoom(x);
        }
    }
    //E: Oracle

    
    //B: General Functions
    modifier onlyOwner() {
        require(msg.sender == s_owner);
        _;
    }

    function rakeCollection(uint room_number) private{
        raffle_room[room_number].l_rakeCollected = raffle_room[room_number].l_rakeCollected + raffle_room[room_number].l_rake;
        emit RakeTransfer(room_number,raffle_room[room_number].l_rakeCollected,raffle_room[room_number].lessee);   
    }

    function gettimestamp() public view returns(uint){
        return block.timestamp;
    }
    //prevents duplication of winner
    function remove(uint room_number,uint index)  private {
        if (index >= raffle_room[room_number].s_players.length) return;
        for (uint i = index; i < raffle_room[room_number].s_players.length-1; i++){
            raffle_room[room_number].s_players[i] = raffle_room[room_number].s_players[i+1];
        }
        raffle_room[room_number].s_players.pop();
    }

    function removeRoom(uint index) private{
        if (index >= readyRooms.length) return;
        for (uint i = index; i < readyRooms.length-1; i++){
            readyRooms[i] = readyRooms[i+1];
        }
        readyRooms.pop();
    }

    function resetContract(uint room_number) private {
        delete raffle_room[room_number].s_players;
        emit ContractReset(room_number,block.timestamp);
    }

    function getPlayersByRoom(uint room_number,uint order) public view returns(address){
        return raffle_room[room_number].s_players[order];
    }

    function checkPlayerBalance(uint room_number, address player) public view returns(uint){
        return raffle_room[room_number].s_player_wallets[player];
    }
    //E: General Functions

    //B: Player functions
    function join(uint _amount, uint room_number) public {
        require(raffle_room[room_number].active == true, "This room is paused at the moment.");
        require(_amount >= raffle_room[room_number].entryfee, "Please enter enough amount");
        require(raffle_room[room_number].s_players.length < raffle_room[room_number].limit, "This room is full");
        uint256 allowance = token_address.allowance(msg.sender,address(this));
        require(allowance >= _amount, "You don't have enough allowance to join.");
        token_address.transferFrom(msg.sender, address(this), _amount);
        raffle_room[room_number].s_players.push(msg.sender);
        raffle_room[room_number].s_player_wallets[msg.sender] = 0;
        emit TransferReceived(room_number,msg.sender, _amount, raffle_room[room_number].s_players.length);
        balance = balance + _amount;

        if(raffle_room[room_number].s_players.length == raffle_room[room_number].limit){
            readyRooms.push(room_number);
            _requestRandomWords();
            // _test_requestRW();
        }
    }

    function playerCollect(uint room_number) public{
        //check amount from player mapping
        //transfer to sender
        require(raffle_room[room_number].s_player_wallets[msg.sender] > 0,"This account is not allowed to withdraw.");
        token_address.transfer(msg.sender, raffle_room[room_number].s_player_wallets[msg.sender]);
        raffle_room[room_number].s_player_wallets[msg.sender] = 0;
    }

    function playerWithdraw(uint room_number) public {
        for (uint i = 0; i <= raffle_room[room_number].s_players.length; i++) {
           if(raffle_room[room_number].s_players[i] == msg.sender){
                token_address.transfer(msg.sender, raffle_room[room_number].entryfee);
                remove(room_number,i);
                emit PlayerWithdraw(room_number,msg.sender,raffle_room[room_number].s_players.length);
                return;
           }
        }
    }
    //E: Player functions
    
    //B: Lessee Functions
    function hostARaffle(uint _amount, uint newEntryfee, uint room_number, uint grandPrize,uint limit) public {
        require(isActive == true, "This room is paused at the moment.");
        require(s_owner == raffle_room[room_number].lessee,"Someone is still renting this raffle.");
        uint256 allowance = token_address.allowance(msg.sender,address(this));
        require(allowance >= raffle_room[room_number].rentFee, "You don't have enough allowance to host.");
        require(_amount >= raffle_room[room_number].rentFee, "Please enter enough amount");
        require(limit >= 3, "Limit should be 3 or higher");
        require(prizeSelection[grandPrize] == true, "Invalid grand prize");

        token_address.transferFrom(msg.sender, address(this), _amount);
        raffle_room[room_number].active = true;
        raffle_room[room_number].lessee = msg.sender;
        raffle_room[room_number].entryfee = newEntryfee;
        raffle_room[room_number].limit = limit;
        raffle_room[room_number].pot = newEntryfee * limit;
        raffle_room[room_number].l_rake = raffle_room[room_number].pot * 2 / 100;
        raffle_room[room_number].burn_rate = raffle_room[room_number].pot * 1 / 100; //1% of of the whole balance is burned... as there is no way to withdraw.
        raffle_room[room_number].lessee_updatedAt = block.timestamp;
        
        uint fullrake = raffle_room[room_number].burn_rate + raffle_room[room_number].l_rake;

        if(grandPrize == 50){
            computePrizes(room_number,50,25,25,fullrake);
        }
        if(grandPrize == 75){
            computePrizes(room_number,75,15,10,fullrake);

        }
        if(grandPrize == 100){
            computePrizes(room_number,100,0,0,fullrake);
        }
        
        // lessee_list[msg.sender] = room_number;
        emit NewLease(room_number,msg.sender,newEntryfee,raffle_room[room_number].pot,limit,true,raffle_room[room_number].prizes[0]);

        resetContract(room_number);
    }

    function computePrizes(uint room_number, uint grand, uint first, uint second, uint fullrake) private{
        raffle_room[room_number].prizes[0] =  raffle_room[room_number].pot * grand / 100;
        raffle_room[room_number].prizes[1] =  raffle_room[room_number].pot * first / 100;
        raffle_room[room_number].prizes[2] =  raffle_room[room_number].pot * second / 100;
        raffle_room[room_number].prizes[0] = raffle_room[room_number].prizes[0] - fullrake;
    }

    function getPrizeByRoom(uint room_number, uint order) public view returns(uint){
        return raffle_room[room_number].prizes[order];
    }   

    function withdrawRakeLessee(uint amount, uint room_number) public{
        require(msg.sender == raffle_room[room_number].lessee,"This account is not allowed to withdraw. Please rent this contract");
        token_address.transfer(msg.sender, amount);
        raffle_room[room_number].l_rakeCollected = raffle_room[room_number].l_rakeCollected - amount;
    }

    function getAllowance() public view returns(uint){
        return token_address.allowance(msg.sender,address(this));
    }


    //TODO: Remove on productions
    function _test_requestRW() private{
        s_randomWords = [1234687631,3247869663,789986534];
        for(uint x = 0; x < readyRooms.length; x++){
            uint room = readyRooms[x];
            for(uint i = 0; i <= 2; i++) {
                uint place_index = s_randomWords[i] % raffle_room[room].s_players.length;
                address winner = raffle_room[room].s_players[place_index];
                uint prize = raffle_room[room].prizes[i];
                raffle_room[readyRooms[x]].s_player_wallets[winner] = raffle_room[readyRooms[x]].s_player_wallets[winner] + prize;
                raffle_room[readyRooms[x]].winning_places[i] = winner;
                remove(readyRooms[x],place_index);
            }
            removeRoom(x);
            rakeCollection(room);
        }
    }

    function transferOwnership(address newOwner) public onlyOwner{
        s_owner = payable(newOwner);
    }

    //note: players can withdraw, but the rake will be transfered to the s_owner
    function breakLease(uint room_number) public{
        require(msg.sender == raffle_room[room_number].lessee,"This account is not allowed to break this contract.");
        require(raffle_room[room_number].s_players.length > 0,"This raffle has participants, please wait until room is full.");

        uint lessee_time = raffle_room[room_number].lessee_updatedAt + raffle_room[room_number].lease_duration;
        if(lessee_time <= block.timestamp){
            token_address.transfer(msg.sender, raffle_room[room_number].rentFee);
        }else{
            uint profit = raffle_room[room_number].rentFee + raffle_room[room_number].l_rakeCollected;
            token_address.transfer(msg.sender, profit);
        }

        raffle_room[room_number].l_rakeCollected = 0;
        raffle_room[room_number].active = false;
        raffle_room[room_number].lessee = s_owner;
        emit OpenRaffleLease(room_number);
    }
    //E: Lessee Functions

}