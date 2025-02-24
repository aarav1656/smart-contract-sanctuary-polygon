// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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

pragma solidity =0.8.14;

import "../interfaces/IUniswapV2Router02.sol";
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IShortcut} from "../interfaces/IShortcut.sol";

interface INCT is IERC20{
    function calculateRedeemFees(
        address[] memory tco2s,
        uint256[] memory amounts
    ) external view returns (uint256);

    function redeemMany(address[] memory tco2s, uint256[] memory amounts) external;

    function checkEligible(address) external view returns(bool eligible);

    function deposit(address erc20Addr, uint256 amount)external;
}

interface IToucanRegistry{
    function checkERC20(address _address)
        external
        view
        returns (bool);
}

contract NCTShortcut is IShortcut{
    using SafeERC20 for IERC20;

    bool public TestDidShortcut;
    // sushi router 2
    IUniswapV2Router02 public immutable dex;
    address public immutable NCT;
    IToucanRegistry public immutable toucanRegistry;
    constructor(        
        address _NCT,
        address _toucanRegistry,
        address _dex
    ){
        dex = IUniswapV2Router02(_dex);
        NCT = _NCT;
        toucanRegistry = IToucanRegistry(_toucanRegistry);
    }

    event ShortcutError(bytes e);
    // event ShortcutValid(Orders.Order _order);
    // event ShortcutInvalid(Orders.Order _order);
    // event ShortcutComplete(Orders.Order _order);

    function checkEligible(address erc20Addr)
        external
        view
        override
        returns (bool){
            return(INCT(NCT).checkEligible(erc20Addr));
        }
    
    function isValid(
        address _fromToken,
        address _toToken,
        uint _amIn,
        uint _amOut
    )
    external
    view
    override
    returns(bool){
        if(_checkTokenTCO2(_toToken)){
            return(_checkBuyShortcutValid(_fromToken, _toToken, _amIn, _amOut));
        }else if(_checkTokenTCO2(_fromToken)){
            return(_checkSellShortcutValid(_fromToken, _toToken, _amIn, _amOut));
        }
    }

    function execute(
        address _maker,
        address _fromToken,
        address _toToken,
        uint _amIn,
        uint _amOut
    )
    external
    override
    returns(uint){
        if(_checkTokenTCO2(_toToken)){
            // if to token is a TCO2 then try and buy
            require(_checkBuyShortcutValid(_fromToken, _toToken, _amIn, _amOut), "Shortcut must pass valid check to be executed");
            // buy NCT
            _buyNCT(_maker, _fromToken, _toToken, _amIn, _amOut);
            // exchange the NCT tokens for TCO2s and send to user
            _exchangeNCTForTCO2(_maker, _fromToken, _toToken, _amIn, _amOut);
            // emit complete event
            return _amOut;
        }else{
            // if from token is TCO2 and eligible for NCT try and sell
            if(_checkTokenTCO2(_fromToken)){
                require(_checkSellShortcutValid(_fromToken, _toToken, _amIn, _amOut), "Shortcut must pass valid check to be executed");
                _exchangeTCO2ForOutToken(_maker, _fromToken, _toToken, _amIn, _amOut);
                return _amOut;
                }
            }
        revert("Tokens are not valid for NCT shortcut");

    }


    function _checkTokenTCO2(address _token) internal view returns(bool){
        // check if token is in fact a TCO2
        try toucanRegistry.checkERC20(_token) returns(bool b){
            if (!b){return false;}
            return true;
        }catch(bytes memory _err){
            return false;
        }
    }
    /**
    * @dev function to check if a sell shortcut will be valid, only returns true if
        the amounts out for the trade can be exchanged for the TCO2 for the right
        amountOut even with fees
     */
    function _checkSellShortcutValid(        
        address _fromToken,
        address _toToken,
        uint _amIn,
        uint _amOut
        ) 
        internal 
        view
        returns(bool){
        // check if token is in fact a TCO2
        try toucanRegistry.checkERC20(_fromToken) returns(bool b){
            if (!b){return false;}
        }catch(bytes memory _err){
            return false;
        }
        
        INCT nct = INCT(NCT);

        try nct.checkEligible(_fromToken) returns(bool eligible){
            address[] memory inTokens = new address[](1);
            uint[] memory inAmount = new uint[](1);
            inTokens[0] = _fromToken;
            inAmount[0] = _amIn;

            uint amNCTBack = _amIn - nct.calculateRedeemFees(inTokens,inAmount);

            address[] memory path = new address[](2);
            path[0] = NCT;
            path[1] = _toToken;

            try dex.getAmountsOut(amNCTBack, path) returns(uint[] memory amounts){
            address[] memory tco2s = new address[](1);
            uint256[] memory amountsIn = new uint256[](1);
            tco2s[0] = _toToken;
            amountsIn[0] = amounts[1];

            // Only return true if this whole process suceeds and the amount out is greater or equal to what's expected
            return(amounts[0] >= _amOut);
            
            }catch(bytes memory _err){
                return false;
            }
        }catch(bytes memory _err) {
            return false;
        }   

    }
    /**
    * @dev function to check if a buy shortcut will be valid, only returns true if
        the amounts out for the trade can be exchanged for the TCO2 for the right
        amountOut even with fees
     */
    function _checkBuyShortcutValid(        
        address _fromToken,
        address _toToken,
        uint _amIn,
        uint _amOut
        ) 
        internal
        view
        returns(bool){
        // check if token is in fact a TCO2
        try toucanRegistry.checkERC20(_toToken) returns(bool b){
            if (!b){return false;}
        }catch(bytes memory _err){
            return false;
        }

        address[] memory path = new address[](2);
        path[0] = _fromToken;
        path[1] = NCT;

        try dex.getAmountsOut(_amIn, path) returns(uint[] memory amounts){
            address[] memory tco2s = new address[](1);
            uint256[] memory amountsIn = new uint256[](1);
            tco2s[0] = _toToken;
            amountsIn[0] = amounts[1];

            try INCT(NCT).calculateRedeemFees(tco2s, amountsIn) returns(uint256 out){
                return(out >= _amOut);
            }catch(bytes memory _err){
                return false;
            }
        }catch(bytes memory _err) {
            return false;
        }
    }

    function _exchangeTCO2ForOutToken(
        address _maker,
        address _fromToken,
        address _toToken,
        uint _amIn,
        uint _amOut
    ) internal returns(bool){
        INCT nctContract = INCT(NCT);

        IERC20(_fromToken).safeTransferFrom(_maker, address(this), _amIn);
        // we approve each time since NCT does not interpret MAXUINT as infinite
        IERC20(_fromToken).approve(address(nctContract), 2**256-1);
        nctContract.approve(address(dex), 2**256-1);

        uint nctBefore = nctContract.balanceOf(address(this));
        nctContract.deposit(_fromToken, _amIn);
        uint nctAfter = nctContract.balanceOf(address(this));

        address[] memory path = new address[](2);
        path[0] = address(nctContract);
        path[1] = _toToken;

        try dex.swapExactTokensForTokens(nctAfter-nctBefore, _amOut, path, address(this), block.timestamp) returns(uint[] memory amounts){
            return _checkOutValid(_amOut, amounts[1]);
        }catch (bytes memory _err){
            emit ShortcutError(_err);
            return false;
        }

    }

    /**
    * @dev helper function to exchange the contracts NCT tokens for TCO2s
     */
    function _exchangeNCTForTCO2(        
        address _maker,
        address _fromToken,
        address _toToken,
        uint _amIn,
        uint _amOut
    ) internal{
        INCT nctContract = INCT(NCT);
        require(nctContract.balanceOf(address(this)) != 0, "trying to redeem with no NCT tokens");

        address[] memory tco2s = new address[](1);
        uint[] memory amounts = new uint[](1);
        tco2s[0] = _toToken;
        amounts[0] = nctContract.balanceOf(address(this));

        nctContract.redeemMany(tco2s, amounts);
        uint amount = IERC20(_toToken).balanceOf(address(this));

        // require enough tokens were received
        require(amount >= _amOut, "Shortcut Error: Order failed to retreive TCO2s");

        // send the user the amount they asked for
        IERC20(_toToken).safeTransfer(_maker, _amOut);

        // take the remainder as the fee
        if(amount > _amOut){
            IERC20(_toToken).safeTransfer(msg.sender, amount - _amOut);
        }
    }

    /**
    * @dev function to buy an Order with NCT
     */
    function _buyNCT(
        address _maker,
        address _fromToken,
        address _toToken,
        uint _amIn,
        uint _amOut

    ) internal returns(bool){
        IERC20(_fromToken).safeTransferFrom(_maker, address(this), _amIn);
        // we approve each time since NCT does not interpret MAXUINT as infinite
        IERC20(_fromToken).approve(address(dex), _amIn);

        address[] memory path = new address[](2);
        path[0] = _fromToken;
        path[1] = NCT;

        try dex.swapExactTokensForTokens(_amIn, _amOut, path, address(this), block.timestamp) returns(uint[] memory amounts){
            return _checkOutValid(_amOut, amounts[1]);
        }catch (bytes memory _err){
            emit ShortcutError(_err);
            return false;
        }
    }

    /**
    * @dev function to return true if amount out is valid. Very simple for now, but could be upgraded with a fee
     */
    function _checkOutValid(uint amountOutMin, uint _amountOut) internal pure returns(bool isValid){
        isValid = (_amountOut >= amountOutMin);
    }

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IShortcut{

    function isValid(
        address _fromToken,
        address _toToken,
        uint _amIn,
        uint _amOut
    )
    external
    view
    returns(bool);

    function execute(
        address _maker,
        address _fromToken,
        address _toToken,
        uint _amIn,
        uint _amOut
    )
    external
    returns(uint);

    function checkEligible(address) external view returns(bool eligible);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
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

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
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