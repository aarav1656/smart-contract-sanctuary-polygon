/**
 *Submitted for verification at polygonscan.com on 2023-02-13
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

//File: [ReentrancyGuard.sol]

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
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

//File: [IRouter.sol]

interface IUniRouterV1
{
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IUniRouterV2 is IUniRouterV1
{
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

//File: [IMoonAccessManager.sol]

interface IMoonAccessManager
{
    //========================
    // SECURITY FUNCTIONS
    //========================

    function requireAdmin(address _user) external view;
    function requireManager(address _user) external view;
    function requireSecurityAdmin(address _user) external view;
    function requireSecurityMod(address _user) external view;
    function requireDeployer(address _user) external view;    
}

//File: [IMigrationManager.sol]

interface IMigrationManager
{
    //========================
    // MIGRATION FUNCTIONS
    //========================

    function requestMigration(address _user, string memory _topic) external returns (uint256);
    function cancelMigration(address _user, uint256 _id) external;
    function executeMigration(address _user, uint256 _id) external returns (bool);
}

//File: [IToken.sol]

interface IToken
{
	//========================
    // EVENTS FUNCTIONS
    //========================

	event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

	//========================
    // INFO FUNCTIONS
    //========================
	
	function decimals() external view returns (uint8);	
	function symbol() external view returns (string memory);
	function name() external view returns (string memory);
	function totalSupply() external view returns (uint256);
	function allowance(address owner, address spender) external view returns (uint256);

	//========================
    // USER INFO FUNCTIONS
    //========================

    function balanceOf(address account) external view returns (uint256);

    //========================
    // TRANSFER / APPROVE FUNCTIONS
    //========================

    function transfer(address recipient, uint256 amount) external returns (bool);
	function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);    
    function approve(address spender, uint256 amount) external returns (bool);
}

//File: [IERC20.sol]

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
    function transferFrom(
        address sender,
        address recipient,
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

//File: [Address.sol]

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
        assembly {
            size := extcodesize(account)
        }
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
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

//File: [ML_TransferETH.sol]

contract ML_TransferETH
{
    //========================
    // ATTRIBUTES
    //======================== 

    uint256 public transferGas = 30000;

    //========================
    // CONFIG FUNCTIONS
    //======================== 

    function _setTransferGas(uint256 _gas) internal
    {
        require(_gas >= 30000, "Gas to low");
        require(_gas <= 250000, "Gas to high");
        transferGas = _gas;
    }

    //========================
    // TRANSFER FUNCTIONS
    //======================== 

    function transferETH(address _to, uint256 _amount) internal
    {
        (bool success, ) = payable(_to).call{ value: _amount, gas: transferGas }("");
        success; //prevent warning
    }
}

//File: [MoonAccessRequest.sol]

abstract contract MoonAccessRequest
{
    //========================
    // ATTRIBUTES
    //========================
    
    IMoonAccessManager public immutable accessManager;
    address public owner;

    //========================
    // CONSTRUCT
    //========================

    constructor(
        IMoonAccessManager _accessManager, 
        address _owner
    )
    {   
        accessManager = _accessManager;
        owner = _owner;
    }

    //========================
    // SECURITY FUNCTIONS
    //========================

    function isOwner() internal view returns (bool)
    {
        return (owner == msg.sender);
    }

    function requireOwner() internal view
    {
        require(
            isOwner(),
            "User is not Owner");
    }

    function requireAdmin() internal view
    {
        if (!isOwner())
        {
            accessManager.requireAdmin(msg.sender);
        }
    }

    function requireManager() internal view
    {
        if (!isOwner())
        {
            accessManager.requireManager(msg.sender);
        }
    }

    function requireDeployer() internal view
    {
        if (!isOwner())
        {
            accessManager.requireDeployer(msg.sender);
        }
    }

    function requireSecurityAdmin() internal view
    {
        if (!isOwner())
        {
            accessManager.requireSecurityAdmin(msg.sender);
        }
    }

    function requireSecurityMod() internal view
    {
        if (!isOwner())
        {
            accessManager.requireSecurityMod(msg.sender);
        }
    }
}

//File: [SafeERC20.sol]

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

//File: [IWrappedCoin.sol]

interface IWrappedCoin is IToken
{
	function deposit() external payable;
    function withdraw(uint256 _amount) external;
}

//File: [IBank.sol]

interface IBank
{  
    //========================
    // USER INFO FUNCTIONS
    //========================

    function balanceOf(IToken _token, address _user) external view returns (uint256);
    function allowance(IToken _token, address _user, address _spender) external view returns (uint256);
    
    //========================
    // DEPOSIT FUNCTIONS
    //========================

    function depositETHFor(address _user) external payable;
    function depositFor(IToken _token, address _user, uint256 _amount) external;

    //========================
    // TRANSFER FUNCTIONS
    //========================

    function transfer(IToken _token, address _from, address _to, uint256 _amount) external;
    function transferToAccount(IToken _token, address _from, address _to, uint256 _amount) external;

    //========================
    // ALLOWANCE FUNCTIONS
    //========================

    function approve(IToken _token, address _spender, uint256 _amount) external;
    function increaseAllowance(IToken _token, address _spender, uint256 _amount) external;
    function decreaseAllowance(IToken _token, address _spender, uint256 _amount) external;
}

//File: [ML_RecoverFunds.sol]

contract ML_RecoverFunds is ML_TransferETH
{
    //========================
    // LIBS
    //========================

    using SafeERC20 for IERC20;

    //========================
    // EMERGENCY FUNCTIONS
    //======================== 

    function _recoverETH(uint256 _amount, address _to) internal
    {
        transferETH(_to, _amount);
    }

    function _recoverToken(IToken _token, uint256 _amount, address _to) internal
    {
        IERC20(address(_token)).safeTransfer(_to, _amount);
    }  
}

//File: [IVaultConfig.sol]

interface IVaultConfig
{
    //========================
    // CONSTANTS
    //========================

    function PERCENT_FACTOR() external view returns (uint256);

    //========================
    // ATTRIBUTES
    //========================
    
    //fees
    function rewardFeeReceiver() external view returns (address);
    function compoundFee() external view returns (uint256);
    function rewardFee() external view returns (uint256);
    function withdrawFee() external view returns (uint256);
    function withdrawFeePeriod() external view returns (uint256);

    //contracts
    function migrationManager() external view returns (IMigrationManager);
    function bank() external view returns (IBank);
    function payoutManager() external view returns (address);

    //tokens
    function wrappedCoin() external view returns (IWrappedCoin);
    function stableCoin() external view returns (IToken);

    //deposit/withdraw logic
    function autoCompound() external view returns (bool);
}

//File: [IVault.sol]

interface IVault
{
    function config() external view returns (IVaultConfig);  

    function userRemainingWithdrawFeeTime(address _user) external view returns (uint256);
}

contract VaultConfig is
    IVaultConfig,
    MoonAccessRequest,
    ML_RecoverFunds,
    ReentrancyGuard
{
    //========================
    // CONSTANTS
    //========================
	
	string public constant VERSION = "1.0.0";	
	uint256 public constant override PERCENT_FACTOR = 1000000; //100%

    uint256 public constant MAX_REWARD_FEE = 50000; //5%
    uint256 public constant MAX_COMPOUND_FEE = 50000; //5%
    uint256 public constant MAX_TOTAL_FEE = 50000; //5%	
    uint256 public constant MAX_WITHDRAW_FEE = 10000; //1%
    uint256 public constant MAX_WITHDRAW_FEE_PERIOD = 30 days;    

    //========================
    // ATTRIBUTES
    //========================
    
    //fees
    address public override rewardFeeReceiver;
    uint256 public override compoundFee = 5000; //0.5%
    uint256 public override rewardFee = 40000; //4%
    uint256 public override withdrawFee = 2500; //0.25%
    uint256 public override withdrawFeePeriod = 3 days;

    //contracts
    IMigrationManager public override migrationManager;
    IBank public override bank;
    address public override payoutManager;

    //tokens
    IWrappedCoin public override immutable wrappedCoin;
    IToken public override stableCoin;

    //swap
    IUniRouterV2 public router_coinToStable;
    address[] public path_coinToStable;

    //vault registry
    mapping(IVault => uint256) public vaultIdMap;
    mapping(uint256 => IVault) public vaultMap;
    uint256[] public activeVaults;

    //pause actions in case of emergency
    bool public pauseCompound;
    bool public pauseDeposit;
    bool public pauseWithdraw;

    //deposit/withdraw logic
    bool public override autoCompound;

    //========================
    // EVENTS
    //========================

    event Pause(address indexed _user, bool _deposit, bool _withdraw, bool _compound);
    event Unpause(address indexed _user, bool _deposit, bool _withdraw, bool _compound);
    event ConfigChanged(string indexed _key, address indexed _sender, uint256 _value);

    //========================
    // CREATE
    //========================
    
    constructor(
        IMoonAccessManager _accessManager,
        IWrappedCoin _wrappedCoin,
        IToken _stableCoin
    )
    MoonAccessRequest(
        _accessManager,
        address(0)
    )
    {
        wrappedCoin = _wrappedCoin;
        stableCoin = _stableCoin;
    }
    
    //========================
    // CONFIG FUNCTIONS
    //========================

    function setRewardFeeReceiver(address _address) external
    {
        requireAdmin();
        rewardFeeReceiver = _address;
        emit ConfigChanged("NativeLiquidityAddress", msg.sender, uint256(uint160(_address)));
    }

    function setCompoundFee(uint256 _fee) external
    {
        //check
        requireAdmin();
        require(_fee <= MAX_REWARD_FEE, "value > compoundFee");
        require(_fee + rewardFee <= MAX_TOTAL_FEE, "value > totalFee");        

        compoundFee = _fee;
        emit ConfigChanged("CompoundFee", msg.sender, compoundFee);
    }

    function setRewardFee(uint256 _fee) external
    {
        //check
        requireAdmin();
        require(_fee <= MAX_REWARD_FEE, "value > rewardFee");
        require(_fee + compoundFee <= MAX_TOTAL_FEE, "value > totalFee");        

        rewardFee = _fee;
        emit ConfigChanged("RewardFee", msg.sender, rewardFee);
    }

    function setWithdrawFee(uint256 _fee) external
    {
        //check
        requireAdmin();
        require(_fee <= MAX_WITHDRAW_FEE, "value > withdrawFee");       

        withdrawFee = _fee;
        emit ConfigChanged("WithdrawFee", msg.sender, withdrawFee);
    }

    //========================
    // VAULT FUNCTIONS
    //========================

    function registerVault(IVault _vault) external
    {
        //check
        requireDeployer();

        _vault;
        this;
    }

    function unregisterVault(IVault _vault) external
    {
        //check
        requireDeployer();

        _vault;
        this;
    }

    function vaultLength() external view returns (uint256)
    {
        return activeVaults.length;
    }

    //========================
    // SECURITY FUNCTIONS
    //========================

    function pause(bool _pauseDeposit, bool _pauseWithdraw, bool _pauseCompound) external
    {
        //check
        requireSecurityMod();

        //pause
        if (_pauseDeposit) 
        {    
            pauseDeposit = true;
        }
        if (_pauseWithdraw)
        {    
            pauseWithdraw = true;
        }
        if (_pauseCompound)
        {    
            pauseCompound = true;
        }

        //event
        emit Pause(msg.sender, _pauseDeposit, _pauseWithdraw, _pauseCompound);
    }
    
    function unpause(bool _unpauseDeposit, bool _unpauseWithdraw, bool _unpauseCompound) external
    {
        //check
        requireSecurityAdmin();

        //unpause
        if (_unpauseDeposit)
        {    
            pauseDeposit = false;
        }
        if (_unpauseWithdraw)
        {    
            pauseWithdraw = false;
        }
        if (_unpauseCompound)
        {    
            pauseCompound = false;
        }

        //event
        emit Unpause(msg.sender, _unpauseDeposit, _unpauseWithdraw, _unpauseCompound);
    }

    //========================
    // EMERGENCY FUNCTIONS
    //========================

    function recoverETH(uint256 _amount, address _to) external
    {
        //check
        requireSecurityAdmin();

        //recover
        _recoverETH(_amount, _to);        
    }

    function recoverToken(IToken _token, uint256 _amount, address _to) external
    {
        //check
        requireSecurityAdmin();

        //recover
        _recoverToken(_token, _amount, _to);
    } 
}