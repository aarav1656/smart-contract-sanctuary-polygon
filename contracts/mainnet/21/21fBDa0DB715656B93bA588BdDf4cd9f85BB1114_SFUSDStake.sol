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
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SFUSDStake is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    address public constant SFUSDaddress = 0x93FEe753b548b4Cf93C41AdA062F80DE12710dB8; // SFUSD Address
    address public constant multiSigWallet = 0x210d477d9ef8cB94EE42De9f20d4555f87b70A02; //Multi sig wallet
    address public devAddress;

    uint256 public currentDepositID;

    uint256 public constant DAILY_ROI = 1; // 1%
    uint256 public constant DEPOSIT_LIMIT = 100;

    uint256 public constant COOLDOWN_PERIOD = 7 days;
    uint256 public constant LOCKED_PERIOD = 63 days;
    uint256 public constant DEPOSIT_FEE = 2; // 2%
    uint256 public constant TOTAL_PERCENTAGE = 100; // 100%

    uint256 public startDate;
    uint256 public capitalLockedPool;
    uint256 public rewardPool;

    bool public contractClosed;

    struct DepositStruct {
        address investor;
        uint256 depositAmount;
        uint256 depositAt;
        uint256 pocketInvestment;
        uint256 compoundedInvestment;
        bool state;
        bool migratedInvestment;
    }

    struct InvestorStruct {
        address investor;
        uint256 startTime;
        uint256 claimedAmount;
        uint256 lastCalculationDate;
        uint256 nextClaimDate;
        uint256 totalRewardAmount;
        uint256 pocketInvestment;
    }

    event NewInvestor(address investor, uint256 amount, uint256 time);

    event NewInvestment(address investor, uint256 amount, uint256 time);

    event ClaimedReward(address investor, uint256 amount, uint256 time);

    event CapitalWithdrawn(
        address investor,
        uint256 amount,
        uint256 id,
        uint256 time
    );

    mapping(uint256 => DepositStruct) public depositState;
    mapping(address => uint256[]) public ownedDeposits;
    mapping(address => uint256) public depositsLength;
    mapping(address => bool) public isAdmin;

    mapping(address => InvestorStruct) public investors;

    uint256 public totalInvestors = 0;
    uint256 public totalReward = 0;
    uint256 public totalInvested = 0;
    uint256 public capitalWithdrawn = 0;

    bool public isPause = false;

    modifier onlyAdmin() {
        require(isAdmin[msg.sender], "Only admin can do this transaction");
        _;
    }

    constructor(
        address _devAddress,
        uint256 _startDate
    ) {
        require(_devAddress != address(0), "Invalid dev wallet address");
        require(_startDate > block.timestamp, "Invalid start time");
        devAddress = _devAddress;
        startDate = _startDate;

        transferOwnership(multiSigWallet); //Multisig wallet
    }

    function setContractClosed(bool _contractClosed) external onlyOwner {
        require(contractClosed != _contractClosed, "Invalid value");
        contractClosed = _contractClosed;
    }

    // change dev address
    function setDevAddress(address _devAddress) external onlyOwner {
        require(_devAddress != address(0), "Invalid dev address");
        devAddress = _devAddress;
    }

    // Make/remove any address as admin
    function setIsAdmin(
        address _walletAddress,
        bool adminStatus
    ) external onlyOwner {
        require(_walletAddress != address(0),"Invalid wallet address");
        require(isAdmin[_walletAddress] != adminStatus, "Invalid value");
        isAdmin[_walletAddress] = adminStatus;
    }

    // use to pause/unpause the contract
    function setPause(bool _isPause) external onlyOwner {
        require(isPause != _isPause, "Invalid value");
        isPause = _isPause;
    }

    // get next deposit id at the time of deposit
    function _getNextDepositID() private view returns (uint256) {
        return currentDepositID + 1;
    }

    // increment deposit id counter at the time of deposit
    function _incrementDepositID() private {
        currentDepositID = currentDepositID + 1;
    }

    // to make investment in the contract
    function deposit(uint256 _amount) external nonReentrant {
        require(
            depositsLength[msg.sender] < DEPOSIT_LIMIT,
            "Cannot make more than 100 deposits from a single wallet"
        );
        require(block.timestamp >= startDate, "Cannot deposit at this moment");
        require(_amount > 0, "Amount must be greater than 0");
        require(
            IERC20(SFUSDaddress).allowance(msg.sender, address(this)) >=
                _amount,
            "Insufficient allowance"
        );
        require(!isPause, "Cannot deposit at the moment");

        uint256 _id = _getNextDepositID();
        _incrementDepositID();

        uint256 depositFee = (_amount * DEPOSIT_FEE) / TOTAL_PERCENTAGE;

        uint256 amountToDeposit = _amount - depositFee;
        depositState[_id].investor = msg.sender;
        depositState[_id].depositAmount = amountToDeposit;
        depositState[_id].depositAt = block.timestamp;
        depositState[_id].state = true;
        depositState[_id].migratedInvestment = false;

        ownedDeposits[msg.sender].push(_id);
        depositsLength[msg.sender] = depositsLength[msg.sender] + 1;

        if (investors[msg.sender].investor == address(0)) {
            totalInvestors = totalInvestors + 1;

            investors[msg.sender].investor = msg.sender;
            investors[msg.sender].startTime = block.timestamp;
            investors[msg.sender].lastCalculationDate = block.timestamp;

            emit NewInvestor(msg.sender, _amount, block.timestamp);
        }

        if (investors[msg.sender].totalRewardAmount >= _amount) {
            rewardPool = rewardPool + amountToDeposit;
            investors[msg.sender].totalRewardAmount =
                investors[msg.sender].totalRewardAmount -
                _amount;
            depositState[_id].compoundedInvestment = amountToDeposit;
        } else {
            if (amountToDeposit >= investors[msg.sender].totalRewardAmount) {
                capitalLockedPool =
                    capitalLockedPool +
                    (amountToDeposit - investors[msg.sender].totalRewardAmount);
                depositState[_id].pocketInvestment =
                    amountToDeposit -
                    investors[msg.sender].totalRewardAmount;
                rewardPool =
                    rewardPool +
                    investors[msg.sender].totalRewardAmount;

                depositState[_id].compoundedInvestment = investors[msg.sender]
                    .totalRewardAmount;

                investors[msg.sender].pocketInvestment =
                    investors[msg.sender].pocketInvestment +
                    (amountToDeposit - investors[msg.sender].totalRewardAmount);
                investors[msg.sender].totalRewardAmount = 0;
            } else {
                depositState[_id].compoundedInvestment = amountToDeposit;
                rewardPool = rewardPool + amountToDeposit;
                investors[msg.sender].totalRewardAmount =
                    investors[msg.sender].totalRewardAmount -
                    amountToDeposit;
            }
        }

        investors[msg.sender].nextClaimDate = block.timestamp + COOLDOWN_PERIOD;

        totalInvested = totalInvested + _amount;

        emit NewInvestment(msg.sender, _amount, block.timestamp);

        IERC20(SFUSDaddress).safeTransferFrom(
            msg.sender,
            address(this),
            _amount
        );
        IERC20(SFUSDaddress).safeTransfer(devAddress, depositFee);
    }

    // to claim rewards
    function claimRewards() external nonReentrant {
        require(depositsLength[msg.sender] > 0, "you need to deposit first");
        require(
            investors[msg.sender].nextClaimDate <= block.timestamp,
            "Cannot claim before 7 days"
        );
        require(!isPause, "Cannot claim at the moment");

        uint256 claimableAmount = getAllClaimableReward(msg.sender);

        require(claimableAmount > 0, "No claimable reward yet");

        investors[msg.sender].claimedAmount =
            investors[msg.sender].claimedAmount +
            claimableAmount;
        investors[msg.sender].nextClaimDate = block.timestamp + COOLDOWN_PERIOD;
        investors[msg.sender].lastCalculationDate = block.timestamp;
        investors[msg.sender].totalRewardAmount =
            investors[msg.sender].totalRewardAmount +
            claimableAmount;

        require(
            claimableAmount <= rewardPool,
            "Not enough SFUSD in reward pool"
        );

        totalReward = totalReward + claimableAmount;

        rewardPool = rewardPool - claimableAmount;

        emit ClaimedReward(msg.sender, claimableAmount, block.timestamp);

        IERC20(SFUSDaddress).safeTransfer(msg.sender, claimableAmount);
    }

    // to withdraw initial investment from the contract after 63 days
    function withdrawCapital(uint256 id) external nonReentrant {
        require(
            depositState[id].investor == msg.sender,
            "only investor of this id can withdraw capital"
        );

        require(
            block.timestamp - depositState[id].depositAt > LOCKED_PERIOD,
            "withdraw lock time is not finished yet"
        );
        require(depositState[id].state, "you have already withdrawn capital");
        require(!isPause, "Cannot withdraw at the moment");

        uint256 claimableReward = getClaimableReward(id);

        if (claimableReward > rewardPool) {
            claimableReward = rewardPool;
        }

        require(
            depositState[id].depositAmount + claimableReward <=
                IERC20(SFUSDaddress).balanceOf(address(this)),
            "no enough SFUSD in pool"
        );

        // transfer capital to the user
        IERC20(SFUSDaddress).safeTransfer(
            msg.sender,
            depositState[id].depositAmount + claimableReward
        );

        capitalLockedPool =
            capitalLockedPool -
            depositState[id].pocketInvestment;
        rewardPool = rewardPool - claimableReward;

        investors[msg.sender].pocketInvestment =
            investors[msg.sender].pocketInvestment -
            depositState[id].pocketInvestment;
        investors[depositState[id].investor].claimedAmount =
            investors[depositState[id].investor].claimedAmount +
            claimableReward;
        investors[msg.sender].totalRewardAmount =
            investors[msg.sender].totalRewardAmount +
            claimableReward;

        totalReward = totalReward + claimableReward;

        capitalWithdrawn = capitalWithdrawn + depositState[id].depositAmount;
        depositState[id].state = false;

        emit CapitalWithdrawn(
            msg.sender,
            claimableReward + depositState[id].depositAmount,
            id,
            block.timestamp
        );
    }

    // to withdraw pocket investment from the contract
    function withdrawPocketInvestment() external nonReentrant {
        require(contractClosed, "Contract is not closed yet");
        require(isPause, "Cannot withdraw at the moment");
        uint256 refundAmount = investors[msg.sender].pocketInvestment;

        require(
            IERC20(SFUSDaddress).balanceOf(address(this)) >= refundAmount,
            "Not enough SFUSD"
        );

        removeInvestorOnWithdraw(msg.sender);
        IERC20(SFUSDaddress).safeTransfer(msg.sender, refundAmount);
    }

    function getAllClaimableReward(
        address _investorAddress
    ) public view returns (uint256 allClaimableAmount) {
        allClaimableAmount = 0;
        uint256 length = depositsLength[_investorAddress];
        for (uint256 i = 0; i < length; i++) {
            allClaimableAmount += getClaimableReward(
                ownedDeposits[_investorAddress][i]
            );
        }
    }

    function getClaimableReward(
        uint256 _id
    ) public view returns (uint256 reward) {
        require(_id > 0, "Deposit ID must be greater than 0");
        if (!depositState[_id].state) return 0;
        address investor = depositState[_id].investor;

        uint256 lastROIDate = investors[investor].lastCalculationDate;
        uint256 profit = 0;
        uint256 currentTime = (depositState[_id].depositAt + LOCKED_PERIOD) >
            block.timestamp
            ? block.timestamp
            : (depositState[_id].depositAt + LOCKED_PERIOD);
        
        if(lastROIDate>=currentTime){
            return 0;
        }

        if (
            lastROIDate >= depositState[_id].depositAt &&
            lastROIDate < currentTime
        ) {
            profit =
                ((depositState[_id].depositAmount * (DAILY_ROI * 7)) *
                    (currentTime - lastROIDate)) /
                (TOTAL_PERCENTAGE * COOLDOWN_PERIOD);
        } else {
            
            profit =
                ((depositState[_id].depositAmount * (DAILY_ROI * 7)) *
                    (currentTime - depositState[_id].depositAt)) /
                (TOTAL_PERCENTAGE * COOLDOWN_PERIOD);
        }

        reward = profit;
    }

    // get investor data
    function getInvestor(
        address _investorAddress
    )
        public
        view
        returns (
            address investor,
            uint256 startTime,
            uint256 lastCalculationDate,
            uint256 nextClaimDate,
            uint256 claimableAmount,
            uint256 claimedAmount,
            uint256 totalRewardAmount,
            uint256 pocketInvestment
        )
    {
        investor = _investorAddress;
        startTime = investors[_investorAddress].startTime;
        lastCalculationDate = investors[_investorAddress].lastCalculationDate;
        nextClaimDate = investors[_investorAddress].nextClaimDate;
        claimableAmount = getAllClaimableReward(_investorAddress);
        claimedAmount = investors[_investorAddress].claimedAmount;
        totalRewardAmount = investors[_investorAddress].totalRewardAmount;
        pocketInvestment = investors[_investorAddress].pocketInvestment;
    }

    // get deposit data by id
    function getDepositState(
        uint256 _id
    )
        public
        view
        returns (
            address investor,
            uint256 depositAmount,
            uint256 depositAt,
            uint256 claimedAmount,
            bool state,
            uint256 pocketInvestment,
            uint256 compoundedInvestment
        )
    {
        require(_id > 0, "Deposit ID must be greater than 0");
        investor = depositState[_id].investor;
        depositAmount = depositState[_id].depositAmount;
        depositAt = depositState[_id].depositAt;
        state = depositState[_id].state;
        pocketInvestment = depositState[_id].pocketInvestment;
        compoundedInvestment = depositState[_id].compoundedInvestment;
        claimedAmount = getClaimableReward(_id);
    }

    // get owned deposits
    function getOwnedDeposits(
        address investor
    ) public view returns (uint256[] memory) {
        return ownedDeposits[investor];
    }

    // used by owner of the contract to deposit SFUSD in the reward pool
    function depositInRewardPool(uint256 _amount) external onlyOwner {
        require(_amount > 0, "Amount must be greater than 0");
        rewardPool = rewardPool + _amount;
        IERC20(SFUSDaddress).safeTransferFrom(
            msg.sender,
            address(this),
            _amount
        );
    }

    // used by admin to migrate StableFund V1 investors to V2
    function migrateInvestorToV2(
        address _investor,
        uint256 _amount,
        uint256 _depositAt
    ) external onlyAdmin nonReentrant {
        require(_amount > 0, "Amount must be greater than 0");
        require(_investor != address(0), "Invalid investor address");
        require(
            depositsLength[_investor] < DEPOSIT_LIMIT,
            "Cannot make more than 100 deposits from a single wallet"
        );
        if (_depositAt == 0) {
            _depositAt = startDate;
        }

        uint256 _id = _getNextDepositID();
        _incrementDepositID();
        depositState[_id].investor = _investor;
        depositState[_id].depositAmount = _amount;
        depositState[_id].depositAt = _depositAt;
        depositState[_id].state = true;
        depositState[_id].migratedInvestment = true;

        ownedDeposits[_investor].push(_id);

        if (investors[_investor].investor == address(0)) {
            totalInvestors = totalInvestors + 1;

            investors[_investor].investor = _investor;
            investors[_investor].startTime = _depositAt;

            investors[_investor].lastCalculationDate = _depositAt;

            emit NewInvestor(_investor, _amount, _depositAt);
        }

        if (investors[_investor].totalRewardAmount >= _amount) {
            rewardPool = rewardPool + _amount;
            investors[_investor].totalRewardAmount =
                investors[_investor].totalRewardAmount -
                _amount;

            depositState[_id].compoundedInvestment = _amount;
        } else {
            uint256 _pocketAmount = _amount -
                investors[_investor].totalRewardAmount;

            capitalLockedPool = capitalLockedPool + _pocketAmount;
            depositState[_id].pocketInvestment = _pocketAmount;

            rewardPool = rewardPool + investors[_investor].totalRewardAmount;
            depositState[_id].compoundedInvestment = investors[_investor]
                .totalRewardAmount;

            investors[_investor].pocketInvestment =
                investors[_investor].pocketInvestment +
                _pocketAmount;
            investors[_investor].totalRewardAmount = 0;
        }

        depositsLength[_investor] = depositsLength[_investor] + 1;
        investors[_investor].nextClaimDate = _depositAt + COOLDOWN_PERIOD;
        totalInvested = totalInvested + _amount;

        emit NewInvestment(_investor, _amount, _depositAt);

        IERC20(SFUSDaddress).safeTransferFrom(
            msg.sender,
            address(this),
            _amount
        );
    }

    function removeInvestorOnWithdraw(address _investor) private {
        require(_investor != address(0), "Invalid investor address");
        require(
            investors[_investor].investor != address(0),
            "This address has no investment in the contract"
        );

        uint256[] memory currentInvestorDeposits = getOwnedDeposits(_investor);
        uint256 length = currentInvestorDeposits.length;

        uint256 totalAmountLocked = 0;
        for (uint256 i = 0; i < length; i++) {
            if (depositState[currentInvestorDeposits[i]].state) {
                if(!depositState[currentInvestorDeposits[i]].migratedInvestment){
                    totalAmountLocked =
                        totalAmountLocked + ((depositState[currentInvestorDeposits[i]].depositAmount * TOTAL_PERCENTAGE)/(TOTAL_PERCENTAGE - DEPOSIT_FEE));
                }else{
                    totalAmountLocked =
                        totalAmountLocked +
                        depositState[currentInvestorDeposits[i]].depositAmount;
                }
            }

            depositState[currentInvestorDeposits[i]] = DepositStruct({
                investor: address(0),
                depositAmount: 0,
                depositAt: 0,
                pocketInvestment: 0,
                compoundedInvestment: 0,
                state: false,
                migratedInvestment: false
            });
        }

        capitalLockedPool =
            capitalLockedPool -
            investors[_investor].pocketInvestment;
        totalInvestors = totalInvestors - 1;
        totalInvested =
            totalInvested - totalAmountLocked;

        investors[_investor] = InvestorStruct({
            investor: address(0),
            startTime: 0,
            claimedAmount: 0,
            lastCalculationDate: 0,
            nextClaimDate: 0,
            totalRewardAmount: 0,
            pocketInvestment: 0
        });

        ownedDeposits[_investor] = new uint256[](0);
        depositsLength[_investor] = 0;
    }

    // used by admin to remove investor
    function removeInvestor(address _investor) public onlyAdmin nonReentrant {
        require(_investor != address(0), "Invalid investor address");
        require(
            investors[_investor].investor != address(0),
            "This address has no investment in the contract"
        );

        uint256[] memory currentInvestorDeposits = getOwnedDeposits(_investor);
        uint256 length = currentInvestorDeposits.length;

        uint256 totalAmountLocked = 0;
        for (uint256 i = 0; i < length; i++) {
            if (depositState[currentInvestorDeposits[i]].state) {
                if(!depositState[currentInvestorDeposits[i]].migratedInvestment){
                    totalAmountLocked =
                        totalAmountLocked + ((depositState[currentInvestorDeposits[i]].depositAmount * TOTAL_PERCENTAGE)/(TOTAL_PERCENTAGE - DEPOSIT_FEE));
                }else{
                    totalAmountLocked =
                        totalAmountLocked +
                        depositState[currentInvestorDeposits[i]].depositAmount;
                }
            }

            depositState[currentInvestorDeposits[i]] = DepositStruct({
                investor: address(0),
                depositAmount: 0,
                depositAt: 0,
                pocketInvestment: 0,
                compoundedInvestment: 0,
                state: false,
                migratedInvestment:false
            });
        }

        capitalLockedPool =
            capitalLockedPool -
            investors[_investor].pocketInvestment;
        totalInvestors = totalInvestors - 1;
        totalInvested =
            totalInvested - totalAmountLocked;

        investors[_investor] = InvestorStruct({
            investor: address(0),
            startTime: 0,
            claimedAmount: 0,
            lastCalculationDate: 0,
            nextClaimDate: 0,
            totalRewardAmount: 0,
            pocketInvestment: 0
        });

        ownedDeposits[_investor] = new uint256[](0);
        depositsLength[_investor] = 0;

        IERC20(SFUSDaddress).safeTransfer(msg.sender, totalAmountLocked);
    }
}