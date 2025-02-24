/**
 *Submitted for verification at polygonscan.com on 2023-04-25
*/

/** 
 *  SourceUnit: /home/dos/dev/clients/cointinum/vaultContract/contracts/Vault.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [////IMPORTANT]
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
     * ////IMPORTANT: because control is transferred to `recipient`, care must be
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




/** 
 *  SourceUnit: /home/dos/dev/clients/cointinum/vaultContract/contracts/Vault.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
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
     * ////IMPORTANT: The same issues {IERC20-approve} has related to transaction
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




/** 
 *  SourceUnit: /home/dos/dev/clients/cointinum/vaultContract/contracts/Vault.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
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
     * ////IMPORTANT: Beware that changing an allowance with this method brings the risk
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




/** 
 *  SourceUnit: /home/dos/dev/clients/cointinum/vaultContract/contracts/Vault.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

////import "../IERC20.sol";
////import "../extensions/draft-IERC20Permit.sol";
////import "../../../utils/Address.sol";

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




/** 
 *  SourceUnit: /home/dos/dev/clients/cointinum/vaultContract/contracts/Vault.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
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


/** 
 *  SourceUnit: /home/dos/dev/clients/cointinum/vaultContract/contracts/Vault.sol
*/

////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: GPL-3.0
pragma solidity ^0.8.17;

/// @dev - Inherited contracts for security and token compliancy
////import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
////import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
////import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract Vault is ReentrancyGuard {
    using SafeERC20 for IERC20;
/// @dev Custom Errors
    error NoTokensDepositError();

/// @notice ERC20 token for interest payments
    IERC20 public CTM;
    IERC20 public USDC;

/// @notice Global variables to keep track of the accounts and the deposits they make
    mapping(address => uint256) public ctmTokenBalance;

/// @notice Mappings for the USDC token
    mapping(address => uint256) public usdcTokenBalance;

/// @notice Deployer of the contract gains permission to supply interest as collateral
    address payable owner;
/// @notice Admin address for the contract
    address adminAddress;

/// @notice Wallet address for unrefundable portion of payments
    address fundsAddress;

/// @notice The address of the contract the handles the ICO functions
    address swapAddress;

/// @notice Set the basis points penalty for early widthdrawal 
    uint256 public penalty; // bps

/// @notice Total amount of CTM in the contract
    uint256 public ctmTotal;
/// @notice Total amount of USDC in the contract
    uint256 public usdcTotal;

/// @dev Events for proper vault functionality and transaction execution 
    event Minted(address indexed minter, uint256 amount);
    event CTM_Supplied(address indexed depositer, uint256 amount, uint256 timestamp);
    event CTM_Removed(address indexed depositer, uint256 amount, uint256 timestamp);
    event CtmPurchased(address indexed purchaser, uint256 usdcAmount, uint256 cmtAllotedAmount);
    event TokenWithdraw(address indexed user, bytes32 token, uint256 payment);
    event RemovedPaymentTokens(address indexed owner, uint256 amount);
    event AddedPaymentTokens(address indexed owner, uint256 amount);
    event Refund(address indexed _buyer, uint256 _amount);
    event SetPenalty(uint256 _penalty);
    event SetSwapAddress(address _swapAddress);
    event SetFundsAddress(address _fundsAddress);

/// @param _fundsAddress Wallet address to recieve unrefundable portion of payments
    constructor (address token, address _fundsAddress) {
        require((_fundsAddress!=address(0)), "fundsAddress invalid");
        owner = payable(msg.sender);
        adminAddress = (msg.sender);
        CTM = IERC20(token);
        fundsAddress = _fundsAddress;
    }

/// @notice Admin address can be changed by owner
    function setAdminAddress(address _address) public onlyOwner {
        adminAddress = _address;
    }

/// @param _fundsAddress Address for penalties to get routed to upon CTM purchase
    function setFundsAddress(address _fundsAddress) public onlyOwner {
        require(_fundsAddress!=address(0), "fundsAddress cannot be zero");
        fundsAddress = _fundsAddress;
        emit SetFundsAddress(_fundsAddress);
    }

/// @param _swapAddress Address for the swap contract
    function setSwapAddress(address _swapAddress) public onlyAdmin {
        require(_swapAddress!=address(0), "swapAddress cannot be zero");
        swapAddress = _swapAddress;
        emit SetSwapAddress(_swapAddress);
    }

/// @notice Sets the token that will be used for payments (USDC)
    function setPaymentToken(address token) public onlyAdmin {
        USDC = IERC20(token);
    }

/// @notice Can withdraw entire payment token supply held inside of the Vault
/// @param _amount The amount of USDC to be removed from the vault
    function removePaymentTokens(uint256 _amount) public onlyOwner {
        require(_amount > 0, "The amount must be greater than zero");
        require(usdcTotal >= _amount, "There are not enough USDC tokens in the vault");
        usdcTotal -= _amount;
        emit RemovedPaymentTokens(tx.origin, usdcTotal);
        USDC.safeTransfer(tx.origin, _amount);        
    }

/// @param _amount The amount of USDC to add to the vault
    function addPaymentTokens(uint256 _amount) public onlyOwner {
        require(_amount > 0, "No tokens where added");
        usdcTotal += _amount;
        emit AddedPaymentTokens(tx.origin, _amount);
        USDC.safeTransferFrom(tx.origin, address(this), _amount);
    }

/// @param _amount The amount of CTM to add to the Vault
    function supplyCTM (uint256 _amount) public onlyOwner {
        require(_amount > 0, "You need to deposit some tokens");

        ctmTotal += _amount;        
        emit CTM_Supplied(
            tx.origin,
            _amount,
            block.timestamp
        );
        CTM.safeTransferFrom(tx.origin, address(this), _amount);
    }

/// @param _amount This is the amount of CTM to be removed by contract owner
    function removeCTM (uint256 _amount) public onlyOwner {
        require(_amount > 0, "The amount must be greater than zero");
        require(ctmTotal >= _amount, "There are not enough CTM tokens in the vault");
        ctmTotal -= _amount;
        emit CTM_Removed(
            msg.sender,
            ctmTotal,
            block.timestamp
        );
        CTM.safeTransfer(msg.sender, _amount);
    }

/// @notice Checks the balance of CTM
    function balanceOfCTM() public view returns(uint256) {
        return ctmTotal;
    }

/// @notice Checks the balance of USDC in the contract
    function balanceOfUSDC() public view returns(uint256) {
        return usdcTotal;
    }

/// @param _amount Amount of basis points to set penalty
    function setPenaltyAmount(uint256 _amount) public onlyAdmin {
        penalty = _amount * 100;
        emit SetPenalty(penalty);
    }

/// @return Returns the penalty amount that was set
    function getPenaltyAmount() public view returns(uint256) {
        return penalty;
    }
/// @return Returns the fundsAddress
    function getFundsAddress() public view returns (address) {
        return fundsAddress;
    }
/// @return Returns the swapAddress
    function getSwapAddress() public view returns (address) {
        return swapAddress;
    }

/// @notice Returns the adminAddress
    function getAdminAddress() public view returns (address) {
        return adminAddress;
    }

/// @notice Admin functions accessible only by admin address
    modifier onlyAdmin() {
        require(msg.sender == adminAddress, "Only admin can call this function.");
        _;
    }

/// @dev Allows only the deployer / supplier to use the function
    modifier onlyOwner() {
        require(tx.origin == owner);
        _;
    }

/// @dev Allows only the swap contract to use this function
    modifier onlySwap() {
        require(msg.sender == swapAddress);
        _;
    }

/**
    @param _user Address purchasing CTM
    @param _usdcAmount Amount of USDC being swapped for CTM
    @param _ctmAmount Requested amount of CTM being purchased
*/
    
    function buyCTM(address _user, uint256 _usdcAmount, uint256 _ctmAmount) public onlySwap nonReentrant {
        require (_user != address(0), "Invalid address");
        if (_usdcAmount <= 0) { revert NoTokensDepositError(); }
        /// @notice Penalty amount for CTM purchase 
        uint256 unrefundableAmount = _usdcAmount * penalty / 10000;
        uint256 storedAmount = _usdcAmount - unrefundableAmount;
        /// @dev USDC and CTM token balances for each user who interact with the Vault
        usdcTokenBalance[_user] += storedAmount;
        ctmTokenBalance[_user] += _ctmAmount;
        /// @dev USDC Total amount being stored inside of the Vault
        usdcTotal += storedAmount;

        /// @dev _user can only be sent from the swap contract so not aritrary (slither)
        /// @dev Penalty portion of payment sent to fundsAddress upon CTM purchase
        USDC.safeTransferFrom(_user, fundsAddress, unrefundableAmount);
        /// @dev Maximum refundable portion of payment sent to vault
        USDC.safeTransferFrom(_user, address(this), storedAmount);
        /// @dev CtmPurchased event 
        emit CtmPurchased(_user, _usdcAmount, _ctmAmount);
    }

/// @notice Allows an account to withdraw the CTM that was purchased
/// @param _user The buyers address
/// @param _amount The amount of CTM to send to the buyer
    function withdraw(address _user, uint256 _amount, uint256 _usdcAdjustment) public onlySwap {
        require(_amount <= ctmTokenBalance[_user], "The amount is greater than your balance");
        require(_amount > 0, "The amount must be greater than zero");
        require(_amount <= ctmTotal, "Please contact support"); 
        
        /// @dev Adjusts the balances of the users account
        ctmTokenBalance[_user] -= _amount;
        usdcTokenBalance[_user] -= _usdcAdjustment;
        /// @dev Removes the CTM that was sent from the total amount in the contract
        ctmTotal -= _amount;
        /// @dev Allows a CTM token withdraw event from the verified sender
        emit TokenWithdraw(
            msg.sender,
            'CTM',
            _amount
        );
        /// @dev Sends the CTM to the buyer who requested a withdraw
        CTM.safeTransfer(_user, _amount);
    }

/** 
    @notice Refunds USDC to buyer
    @param _buyer The buyer's address
    @param _amount The amount to be refunded
    @param _ctmAdjustment The amount of CTM to be removed from the buyers account
*/

    function refund(address _buyer, uint256 _amount, uint256 _ctmAdjustment) public onlySwap {
        require(_amount <= usdcTokenBalance[_buyer], "The amount is greater than the buyer's balance");
        require(_amount > 0, "The amount must be greater than zero");
        require(_amount <= usdcTotal, "Please contact support");

        /// @dev Adjust the balances of the users account
        usdcTokenBalance[_buyer] -= _amount;
        ctmTokenBalance[_buyer] -= _ctmAdjustment;
        /// @dev Removes the USDC that was sent from the total amount in the Vault
        usdcTotal -= _amount;
        emit Refund(_buyer, _amount);
        /// @dev Sends the refund to the buyer
        USDC.safeTransfer(_buyer, _amount);
    }
}