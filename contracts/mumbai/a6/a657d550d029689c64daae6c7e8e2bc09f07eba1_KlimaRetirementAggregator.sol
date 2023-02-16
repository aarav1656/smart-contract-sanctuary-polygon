/**
 *Submitted for verification at polygonscan.com on 2023-02-16
*/

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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


// File @openzeppelin/contracts-upgradeable/proxy/utils/[email protected]

// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}


// File @openzeppelin/contracts-upgradeable/utils/[email protected]

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}


// File @openzeppelin/contracts-upgradeable/access/[email protected]

// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}


// File @openzeppelin/contracts-upgradeable/token/ERC20/[email protected]
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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


// File @openzeppelin/contracts-upgradeable/token/ERC20/utils/[email protected]
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
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
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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


// File contracts/retirement_v1/interfaces/IUniswapV2Router01.sol
interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}


// File contracts/retirement_v1/interfaces/IUniswapV2Router02.sol
interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}


// File contracts/retirement_v1/interfaces/IRetireBridgeCommon.sol

interface IRetireBridgeCommon {
    function getNeededBuyAmount(
        address _sourceToken,
        address _poolToken,
        uint256 _poolAmount,
        bool _retireSpecific
    ) external view returns (uint256, uint256);

    function getSwapPath(address _sourceToken, address _poolToken)
        external
        view
        returns (address[] memory);

    function poolRouter(address _poolToken) external view returns (address);
}


// File contracts/retirement_v1/interfaces/IRetireMossCarbon.sol

interface IRetireMossCarbon {
    function retireMoss(
        address _sourceToken,
        address _poolToken,
        uint256 _amount,
        bool _amountInCarbon,
        address _beneficiaryAddress,
        string memory _beneficiaryString,
        string memory _retirementMessage,
        address _retiree
    ) external;

    function getNeededBuyAmount(
        address _sourceToken,
        address _poolToken,
        uint256 _poolAmount,
        bool _retireSpecific
    ) external view returns (uint256, uint256);
}


// File contracts/retirement_v1/interfaces/IRetireToucanCarbon.sol

interface IRetireToucanCarbon {
    function retireToucan(
        address _sourceToken,
        address _poolToken,
        uint256 _amount,
        bool _amountInCarbon,
        address _beneficiaryAddress,
        string memory _beneficiaryString,
        string memory _retirementMessage,
        address _retiree
    ) external;

    function retireToucanSpecific(
        address _sourceToken,
        address _poolToken,
        uint256 _amount,
        bool _amountInCarbon,
        address _beneficiaryAddress,
        string memory _beneficiaryString,
        string memory _retirementMessage,
        address _retiree,
        address[] memory _carbonList
    ) external;

    function getNeededBuyAmount(
        address _sourceToken,
        address _poolToken,
        uint256 _poolAmount,
        bool _retireSpecific
    ) external view returns (uint256, uint256);
}


// File contracts/retirement_v1/interfaces/IwsKLIMA.sol

interface IwsKLIMA {
    function sKLIMA() external returns (address);

    function wrap(uint256 _amount) external returns (uint256);

    function unwrap(uint256 _amount) external returns (uint256);

    function wKLIMATosKLIMA(uint256 _amount) external view returns (uint256);

    function sKLIMATowKLIMA(uint256 _amount) external view returns (uint256);
}


// File contracts/retirement_v1/KlimaRetirementAggregator.sol

/**
 * @title KlimaRetirementAggregator
 * @author KlimaDAO
 *
 * @notice This is the master aggregator contract for the Klima retirement utility.
 *
 * This allows a user to provide a source token and an approved carbon pool token to retire.
 * If the source is different than the pool, it will attempt to swap to that pool then retire.
 */
contract KlimaRetirementAggregator is
    Initializable,
    ContextUpgradeable,
    OwnableUpgradeable
{
    using SafeERC20Upgradeable for IERC20Upgradeable;

    function initialize() public initializer {
        __Ownable_init();
        __Context_init();
    }

    /** === State Variables and Mappings === */
    address public KLIMA;
    address public sKLIMA;
    address public wsKLIMA;
    address public USDC;
    address public staking;
    address public stakingHelper;
    address public treasury;
    address public klimaRetirementStorage;

    mapping(address => bool) public isPoolToken;
    mapping(address => uint256) public poolBridge;
    mapping(uint256 => address) public bridgeHelper;

    /** === Event Setup === */
    event AddressUpdated(
        uint256 addressIndex,
        address indexed oldAddress,
        address indexed newAddress
    );
    event PoolAdded(address poolToken, uint256 bridge);
    event PoolRemoved(address poolToken);
    event BridgeHelperUpdated(uint256 bridgeID, address helper);

    /** === Non Specific Auto Retirements */

    /**
     * @notice This function will retire a carbon pool token that is held
     * in the caller's wallet. Depending on the pool provided the appropriate
     * retirement helper will be used as defined in the bridgeHelper mapping.
     * If a token other than the pool is provided then the helper will attempt
     * to swap to the appropriate pool and then retire.
     *
     * @param _sourceToken The contract address of the token being supplied.
     * @param _poolToken The contract address of the pool token being retired.
     * @param _amount The amount being supplied. Expressed in either the total
     *          carbon to offset or the total source to spend. See _amountInCarbon.
     * @param _amountInCarbon Bool indicating if _amount is in carbon or source.
     * @param _beneficiaryAddress Address of the beneficiary of the retirement.
     * @param _beneficiaryString String representing the beneficiary. A name perhaps.
     * @param _retirementMessage Specific message relating to this retirement event.
     */
    function retireCarbon(
        address _sourceToken,
        address _poolToken,
        uint256 _amount,
        bool _amountInCarbon,
        address _beneficiaryAddress,
        string memory _beneficiaryString,
        string memory _retirementMessage
    ) public {
        require(isPoolToken[_poolToken], "Pool Token Not Accepted.");

        (uint256 sourceAmount, ) = getSourceAmount(
            _sourceToken,
            _poolToken,
            _amount,
            _amountInCarbon
        );

        IERC20Upgradeable(_sourceToken).safeTransferFrom(
            _msgSender(),
            address(this),
            sourceAmount
        );

        _retireCarbon(
            _sourceToken,
            _poolToken,
            _amount,
            _amountInCarbon,
            _beneficiaryAddress,
            _beneficiaryString,
            _retirementMessage,
            _msgSender()
        );
    }

    /**
     * @notice This function will retire a carbon pool token that has been
     * transferred to this contract. Useful when an intermediary contract has
     * approval to transfer the source tokens from the initiator.
     * Depending on the pool provided the appropriate retirement helper will
     * be used as defined in the bridgeHelper mapping. If a token other than
     * the pool is provided then the helper will attempt to swap to the
     * appropriate pool and then retire.
     *
     * @param _initiator The original sender of the transaction.
     * @param _sourceToken The contract address of the token being supplied.
     * @param _poolToken The contract address of the pool token being retired.
     * @param _amount The amount being supplied. Expressed in either the total
     *          carbon to offset or the total source to spend. See _amountInCarbon.
     * @param _amountInCarbon Bool indicating if _amount is in carbon or source.
     * @param _beneficiaryAddress Address of the beneficiary of the retirement.
     * @param _beneficiaryString String representing the beneficiary. A name perhaps.
     * @param _retirementMessage Specific message relating to this retirement event.
     */
    function retireCarbonFrom(
        address _initiator,
        address _sourceToken,
        address _poolToken,
        uint256 _amount,
        bool _amountInCarbon,
        address _beneficiaryAddress,
        string memory _beneficiaryString,
        string memory _retirementMessage
    ) public {
        require(isPoolToken[_poolToken], "Pool Token Not Accepted.");

        _retireCarbon(
            _sourceToken,
            _poolToken,
            _amount,
            _amountInCarbon,
            _beneficiaryAddress,
            _beneficiaryString,
            _retirementMessage,
            _initiator
        );
    }

    /**
     * @notice Internal function that checks to make sure the needed source tokens
     * have been transferred to this contract, then calls the retirement function
     * on the bridge's specific helper contract.
     *
     * @param _sourceToken The contract address of the token being supplied.
     * @param _poolToken The contract address of the pool token being retired.
     * @param _amount The amount being supplied. Expressed in either the total
     *          carbon to offset or the total source to spend. See _amountInCarbon.
     * @param _amountInCarbon Bool indicating if _amount is in carbon or source.
     * @param _beneficiaryAddress Address of the beneficiary of the retirement.
     * @param _beneficiaryString String representing the beneficiary. A name perhaps.
     * @param _retirementMessage Specific message relating to this retirement event.
     * @param _retiree Address of the initiator where source tokens originated.
     */
    function _retireCarbon(
        address _sourceToken,
        address _poolToken,
        uint256 _amount,
        bool _amountInCarbon,
        address _beneficiaryAddress,
        string memory _beneficiaryString,
        string memory _retirementMessage,
        address _retiree
    ) internal {
        (uint256 sourceAmount, ) = getSourceAmount(
            _sourceToken,
            _poolToken,
            _amount,
            _amountInCarbon
        );

        require(
            IERC20Upgradeable(_sourceToken).balanceOf(address(this)) ==
                sourceAmount,
            "Source tokens not transferred."
        );

        IERC20Upgradeable(_sourceToken).safeIncreaseAllowance(
            bridgeHelper[poolBridge[_poolToken]],
            sourceAmount
        );

        if (poolBridge[_poolToken] == 0) {
            IRetireMossCarbon(bridgeHelper[0]).retireMoss(
                _sourceToken,
                _poolToken,
                _amount,
                _amountInCarbon,
                _beneficiaryAddress,
                _beneficiaryString,
                _retirementMessage,
                _retiree
            );
        } else if (poolBridge[_poolToken] == 1) {
            IRetireToucanCarbon(bridgeHelper[1]).retireToucan(
                _sourceToken,
                _poolToken,
                _amount,
                _amountInCarbon,
                _beneficiaryAddress,
                _beneficiaryString,
                _retirementMessage,
                _retiree
            );
        }
    }

    /** === Specific offset selection retirements === */

    /**
     * @notice This function will retire a carbon pool token that is held
     * in the caller's wallet. Depending on the pool provided the appropriate
     * retirement helper will be used as defined in the bridgeHelper mapping.
     * If a token other than the pool is provided then the helper will attempt
     * to swap to the appropriate pool and then retire.
     *
     * @param _sourceToken The contract address of the token being supplied.
     * @param _poolToken The contract address of the pool token being retired.
     * @param _amount The amount being supplied. Expressed in either the total
     *          carbon to offset or the total source to spend. See _amountInCarbon.
     * @param _amountInCarbon Bool indicating if _amount is in carbon or source.
     * @param _beneficiaryAddress Address of the beneficiary of the retirement.
     * @param _beneficiaryString String representing the beneficiary. A name perhaps.
     * @param _retirementMessage Specific message relating to this retirement event.
     */
    function retireCarbonSpecific(
        address _sourceToken,
        address _poolToken,
        uint256 _amount,
        bool _amountInCarbon,
        address _beneficiaryAddress,
        string memory _beneficiaryString,
        string memory _retirementMessage,
        address[] memory _carbonList
    ) public {
        //require(isPoolToken[_poolToken], "Pool Token Not Accepted.");

        (uint256 sourceAmount, ) = getSourceAmountSpecific(
            _sourceToken,
            _poolToken,
            _amount,
            _amountInCarbon
        );

        IERC20Upgradeable(_sourceToken).safeTransferFrom(
            _msgSender(),
            address(this),
            sourceAmount
        );

        _retireCarbonSpecific(
            _sourceToken,
            _poolToken,
            _amount,
            _amountInCarbon,
            _beneficiaryAddress,
            _beneficiaryString,
            _retirementMessage,
            _msgSender(),
            _carbonList
        );
    }

    function retireCarbonSpecificFrom(
        address _initiator,
        address _sourceToken,
        address _poolToken,
        uint256 _amount,
        bool _amountInCarbon,
        address _beneficiaryAddress,
        string memory _beneficiaryString,
        string memory _retirementMessage,
        address[] memory _carbonList
    ) public {
        address retiree = _initiator;

        _retireCarbonSpecific(
            _sourceToken,
            _poolToken,
            _amount,
            _amountInCarbon,
            _beneficiaryAddress,
            _beneficiaryString,
            _retirementMessage,
            retiree,
            _carbonList
        );
    }

    /**
     * @notice Internal function that checks to make sure the needed source tokens
     * have been transferred to this contract, then calls the retirement function
     * on the bridge's specific helper contract.
     *
     * @param _sourceToken The contract address of the token being supplied.
     * @param _poolToken The contract address of the pool token being retired.
     * @param _amount The amount being supplied. Expressed in either the total
     *          carbon to offset or the total source to spend. See _amountInCarbon.
     * @param _amountInCarbon Bool indicating if _amount is in carbon or source.
     * @param _beneficiaryAddress Address of the beneficiary of the retirement.
     * @param _beneficiaryString String representing the beneficiary. A name perhaps.
     * @param _retirementMessage Specific message relating to this retirement event.
     * @param _retiree Address of the initiator where source tokens originated.
     */
    function _retireCarbonSpecific(
        address _sourceToken,
        address _poolToken,
        uint256 _amount,
        bool _amountInCarbon,
        address _beneficiaryAddress,
        string memory _beneficiaryString,
        string memory _retirementMessage,
        address _retiree,
        address[] memory _carbonList
    ) internal {
        require(isPoolToken[_poolToken], "Pool Token Not Accepted.");
        // Only Toucan and C3 currently allow specific retirement.
        require(
            poolBridge[_poolToken] == 1 || poolBridge[_poolToken] == 2,
            "Pool does not allow specific."
        );

        _prepareRetireSpecific(
            _sourceToken,
            _poolToken,
            _amount,
            _amountInCarbon
        );

        if (poolBridge[_poolToken] == 0) {
            // Reserve for possible future use.
        } else if (poolBridge[_poolToken] == 1) {
            IRetireToucanCarbon(bridgeHelper[1]).retireToucanSpecific(
                _sourceToken,
                _poolToken,
                _amount,
                _amountInCarbon,
                _beneficiaryAddress,
                _beneficiaryString,
                _retirementMessage,
                _retiree,
                _carbonList
            );
        }
    }

    function _prepareRetireSpecific(
        address _sourceToken,
        address _poolToken,
        uint256 _amount,
        bool _amountInCarbon
    ) internal {
        (uint256 sourceAmount, ) = getSourceAmountSpecific(
            _sourceToken,
            _poolToken,
            _amount,
            _amountInCarbon
        );

        require(
            IERC20Upgradeable(_sourceToken).balanceOf(address(this)) ==
                sourceAmount,
            "Source tokens not transferred."
        );

        IERC20Upgradeable(_sourceToken).safeIncreaseAllowance(
            bridgeHelper[poolBridge[_poolToken]],
            sourceAmount
        );
    }

    /** === External views and helpful functions === */

    /**
     * @notice This function calls the appropriate helper for a pool token and
     * returns the total amount in source tokens needed to perform the transaction.
     * Any swap slippage buffers and fees are included in the return value.
     *
     * @param _sourceToken The contract address of the token being supplied.
     * @param _poolToken The contract address of the pool token being retired.
     * @param _amount The amount being supplied. Expressed in either the total
     *          carbon to offset or the total source to spend. See _amountInCarbon.
     * @param _amountInCarbon Bool indicating if _amount is in carbon or source.
     * @return Returns both the source amount and carbon amount as a result of swaps.
     */
    function getSourceAmount(
        address _sourceToken,
        address _poolToken,
        uint256 _amount,
        bool _amountInCarbon
    ) public view returns (uint256, uint256) {
        uint256 sourceAmount;
        uint256 carbonAmount = _amount;

        if (_amountInCarbon) {
            (sourceAmount, ) = IRetireBridgeCommon(
                bridgeHelper[poolBridge[_poolToken]]
            ).getNeededBuyAmount(_sourceToken, _poolToken, _amount, false);
            if (_sourceToken == wsKLIMA) {
                sourceAmount = IwsKLIMA(wsKLIMA).sKLIMATowKLIMA(sourceAmount);
            }
        } else {
            sourceAmount = _amount;

            address poolRouter = IRetireBridgeCommon(
                bridgeHelper[poolBridge[_poolToken]]
            ).poolRouter(_poolToken);

            address[] memory path = IRetireBridgeCommon(
                bridgeHelper[poolBridge[_poolToken]]
            ).getSwapPath(_sourceToken, _poolToken);

            uint256[] memory amountsOut = IUniswapV2Router02(poolRouter)
                .getAmountsOut(_amount, path);

            carbonAmount = amountsOut[path.length - 1];
        }

        return (sourceAmount, carbonAmount);
    }

    /**
     * @notice Same as getSourceAmount, but factors in the redemption fee
     * for specific retirements.
     *
     * @param _sourceToken The contract address of the token being supplied.
     * @param _poolToken The contract address of the pool token being retired.
     * @param _amount The amount being supplied. Expressed in either the total
     *          carbon to offset or the total source to spend. See _amountInCarbon.
     * @param _amountInCarbon Bool indicating if _amount is in carbon or source.
     * @return Returns both the source amount and carbon amount as a result of swaps.
     */
    function getSourceAmountSpecific(
        address _sourceToken,
        address _poolToken,
        uint256 _amount,
        bool _amountInCarbon
    ) public view returns (uint256, uint256) {
        uint256 sourceAmount;
        uint256 carbonAmount = _amount;

        if (_amountInCarbon) {
            (sourceAmount, ) = IRetireBridgeCommon(
                bridgeHelper[poolBridge[_poolToken]]
            ).getNeededBuyAmount(_sourceToken, _poolToken, _amount, true);
            if (_sourceToken == wsKLIMA) {
                sourceAmount = IwsKLIMA(wsKLIMA).sKLIMATowKLIMA(sourceAmount);
            }
        } else {
            sourceAmount = _amount;

            address poolRouter = IRetireBridgeCommon(
                bridgeHelper[poolBridge[_poolToken]]
            ).poolRouter(_poolToken);

            address[] memory path = IRetireBridgeCommon(
                bridgeHelper[poolBridge[_poolToken]]
            ).getSwapPath(_sourceToken, _poolToken);

            uint256[] memory amountsOut = IUniswapV2Router02(poolRouter)
                .getAmountsOut(_amount, path);

            carbonAmount = amountsOut[path.length - 1];
        }

        return (sourceAmount, carbonAmount);
    }

    /**
     * @notice Allow the contract owner to update Klima protocol addresses
     * resulting from possible migrations.
     * @param _selection Int to indicate which address is being updated.
     * @param _newAddress New address for contract needing to be updated.
     * @return bool
     */
    function setAddress(uint256 _selection, address _newAddress)
        external
        onlyOwner
        returns (bool)
    {
        address oldAddress;
        if (_selection == 0) {
            oldAddress = KLIMA;
            KLIMA = _newAddress; // 0; Set new KLIMA address
        } else if (_selection == 1) {
            oldAddress = sKLIMA;
            sKLIMA = _newAddress; // 1; Set new sKLIMA address
        } else if (_selection == 2) {
            oldAddress = wsKLIMA;
            wsKLIMA = _newAddress; // 2; Set new wsKLIMA address
        } else if (_selection == 3) {
            oldAddress = USDC;
            USDC = _newAddress; // 3; Set new USDC address
        } else if (_selection == 4) {
            oldAddress = staking;
            staking = _newAddress; // 4; Set new staking address
        } else if (_selection == 5) {
            oldAddress = stakingHelper;
            stakingHelper = _newAddress; // 5; Set new stakingHelper address
        } else if (_selection == 6) {
            oldAddress = treasury;
            treasury = _newAddress; // 6; Set new treasury address
        } else if (_selection == 7) {
            oldAddress = klimaRetirementStorage;
            klimaRetirementStorage = _newAddress; // 7; Set new storage address
        } else {
            return false;
        }

        emit AddressUpdated(_selection, oldAddress, _newAddress);

        return true;
    }

    /**
     * @notice Add a new carbon pool to retire with helper contract.
     * @param _poolToken Pool being added.
     * @param _poolBridge Int ID of the bridge used for this token.
     * @return bool
     */
    function addPool(address _poolToken, uint256 _poolBridge)
        external
        onlyOwner
        returns (bool)
    {
        require(!isPoolToken[_poolToken], "Pool already added");
        require(_poolToken != address(0), "Pool cannot be zero address");

        isPoolToken[_poolToken] = true;
        poolBridge[_poolToken] = _poolBridge;

        emit PoolAdded(_poolToken, _poolBridge);
        return true;
    }

    /**
        @notice Remove a carbon pool to retire.
        @param _poolToken Pool being removed.
        @return bool
     */
    function removePool(address _poolToken) external onlyOwner returns (bool) {
        require(isPoolToken[_poolToken], "Pool not added");

        isPoolToken[_poolToken] = false;

        emit PoolRemoved(_poolToken);
        return true;
    }

    /**
        @notice Set the helper contract to be used with a carbon bridge.
        @param _bridgeID Int ID of the bridge.
        @param _helper Helper contract to use with this bridge.
        @return bool
     */
    function setBridgeHelper(uint256 _bridgeID, address _helper)
        external
        onlyOwner
        returns (bool)
    {
        require(_helper != address(0), "Helper cannot be zero address");

        bridgeHelper[_bridgeID] = _helper;

        emit BridgeHelperUpdated(_bridgeID, _helper);
        return true;
    }

    /**
        @notice Allow withdrawal of any tokens sent in error
        @param _token Address of token to transfer
     */
    function feeWithdraw(address _token, address _recipient)
        external
        onlyOwner
        returns (bool)
    {
        IERC20Upgradeable(_token).safeTransfer(
            _recipient,
            IERC20Upgradeable(_token).balanceOf(address(this))
        );

        return true;
    }
}