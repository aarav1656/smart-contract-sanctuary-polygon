/**
 *Submitted for verification at polygonscan.com on 2023-01-22
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

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

interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address _owner, address spender)
        external
        view
        returns (uint256);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

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
        // solhint-disable-next-line no-inline-assembly
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
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
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
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
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
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
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

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionDelegateCall(
                target,
                data,
                "Address: low-level delegate call failed"
            );
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

        // solhint-disable-next-line avoid-low-level-calls
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

                // solhint-disable-next-line no-inline-assembly
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
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
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
        // solhint-disable-next-line max-line-length
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(
            value
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(
            value,
            "SafeERC20: decreased allowance below zero"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
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

        bytes memory returndata = address(token).functionCall(
            data,
            "SafeERC20: low-level call failed"
        );
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: ERC20 operation did not succeed"
            );
        }
    }
}

contract p2pTrade is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Address for address;

    mapping(address => bool) private _isOperator;

    mapping(string => uint256[]) private ordersByMethod;
    mapping(address => uint256[]) private sellerInfo;

    mapping(address => UserInfo) private userInfo;
    struct UserInfo {
        uint256[] openDeals;
        uint256[] conflictDeals;
    }

    mapping(uint256 => OrderInfo) private orderInfo;
    struct OrderInfo {
        string[] methods;
        string asset0;
        string asset1;
        uint256 ratio0;
        uint256 ratio1;
        uint256 ratio;
        uint256 amountAsset0;
        uint256 usdLock;
        uint256 leftAsset0;
        uint256 asset0InLock;
        uint256 minToBuy;
        uint256 maxToBuy;
        address owner;
    }

    mapping(uint256 => DealInfo) private dealInfo;
    struct DealInfo {
        uint256 orderId;
        uint256 amount0;
        uint256 amount1;
        uint256 amountUsd;
        uint256 sign;
        bool buyerSigned;
        bool sellerSigned;
        address buyer;
        address seller;
        bool isConflict;
        uint256 timeStart;
        uint256 timeEnd;
    }

    address public constant USD = 0xc2132D05D31c914a87C6611C10748AEb04B58e8F;
    address public FeeRecipient;

    uint256 public fee = 1500; // 1,5%
    uint256 public constant DECIMALS = 6; // USD Decimals
    uint256 private constant MINIMUM_ASSET = 1;
    uint256 private constant RATIO_FACTOR = 10**DECIMALS;

    uint256 public nextOrder;
    uint256 public nextDeal;

    uint256 public timestampToConflict;
    uint256 public minimumUsdOrder;

    modifier onlyOperator() {
        require(_isOperator[msg.sender], "Not operator");
        _;
    }

    constructor(
        address _owner,
        address _FeeRecipient,
        uint256 _minimumUsdOrder
    ) payable {
        transferOwnership(_owner);
        minimumUsdOrder = _minimumUsdOrder;
        FeeRecipient = _FeeRecipient;
    }

    // view

    function isOperator(address account) external view returns (bool) {
        return _isOperator[account];
    }

    function getDealData(uint256 id)
        external
        view
        returns (
            uint256 orderId,
            uint256[2] memory amounts,
            uint256 amountUsd,
            uint256 sign,
            bool buyerSigned,
            bool sellerSigned,
            address buyer,
            address seller,
            bool isConflict,
            uint256[2] memory times
        )
    {
        DealInfo storage deal = dealInfo[id];
        return (
            deal.orderId,
            [deal.amount0, deal.amount1],
            deal.amountUsd,
            deal.sign,
            deal.buyerSigned,
            deal.sellerSigned,
            deal.buyer,
            deal.seller,
            deal.isConflict,
            [deal.timeStart, deal.timeEnd]
        );
    }

    function getOrderData(uint256 id)
        external
        view
        returns (
            string[] memory methods,
            string[2] memory assets,
            uint256[2] memory ratios,
            uint256 ratio,
            uint256[3] memory amounts,
            uint256 usdLock,
            uint256[2] memory limits,
            address orderOwner
        )
    {
        OrderInfo storage order = orderInfo[id];
        return (
            order.methods,
            [order.asset0, order.asset1],
            [order.ratio0, order.ratio1],
            order.ratio,
            [order.amountAsset0, order.leftAsset0, order.asset0InLock],
            order.usdLock,
            [order.minToBuy, order.maxToBuy],
            order.owner
        );
    }

    function getOrdersByMethod(string memory method)
        external
        view
        returns (uint256[] memory)
    {
        return ordersByMethod[method];
    }

    function getUserInfo(address account)
        external
        view
        returns (uint256[] memory, uint256[] memory)
    {
        UserInfo storage user = userInfo[account];
        return (user.openDeals, user.conflictDeals);
    }

    function getSellerInfo(address account)
        external
        view
        returns (uint256[] memory)
    {
        return sellerInfo[account];
    }

    function getAmountForDeal(uint256 orderId, uint256 amount0)
        public
        view
        returns (uint256 amount1)
    {
        OrderInfo storage order = orderInfo[orderId];
        require(order.owner != address(0), "Order does not exist");
        amount1 = order.ratio0.mul(amount0).div(RATIO_FACTOR);
        return amount1;
    }

    function canConflict(uint256 dealId) public view returns (bool) {
        DealInfo storage deal = dealInfo[dealId];
        if (deal.timeStart == 0 || deal.timeEnd > 0 || deal.isConflict) {
            return false;
        }
        if (deal.timeStart.add(timestampToConflict) <= block.timestamp) {
            return true;
        }
        return false;
    }

    function getTransferAmounts(uint256 amount)
        private
        view
        returns (uint256, uint256)
    {
        uint256 feeAmount = amount.mul(fee).div(100000);
        uint256 tAmount = amount.sub(feeAmount);
        return (tAmount, feeAmount);
    }

    // external

    function createOrder(
        string[] memory methods,
        string memory asset0,
        string memory asset1,
        uint256 ratio0,
        uint256 ratio1,
        uint256 amountAsset0,
        uint256 minToBuy,
        uint256 maxToBuy
    ) public nonReentrant {
        require(amountAsset0 >= MINIMUM_ASSET, "Specify a larger amountAsset0");
        require(
            minToBuy <= amountAsset0 && maxToBuy <= amountAsset0,
            "Check the limits of your order"
        );
        if (maxToBuy > 0) {
            require(maxToBuy >= minToBuy, "Check the limits of your order");
        }

        OrderInfo storage order = orderInfo[nextOrder];

        order.methods = methods;
        for (uint8 i = 0; i < methods.length; i++) {
            ordersByMethod[methods[i]].push(nextOrder);
        }

        order.asset0 = asset0;
        order.asset1 = asset1;

        order.ratio0 = ratio0;
        order.ratio1 = ratio1;
        order.ratio = ratio0.mul(ratio1).div(RATIO_FACTOR);
        require(order.ratio > 0, "Ratio must be more than 0");

        order.usdLock = order.ratio.mul(amountAsset0).div(RATIO_FACTOR);
        require(
            order.usdLock >= minimumUsdOrder,
            "Order USD Lock must be greater than or equal to Minimum Usd Order"
        );

        IERC20(USD).safeTransferFrom(msg.sender, address(this), order.usdLock);

        order.amountAsset0 = amountAsset0;
        order.minToBuy = minToBuy;
        order.maxToBuy = maxToBuy;
        order.leftAsset0 = amountAsset0;

        sellerInfo[msg.sender].push(nextOrder);
        order.owner = msg.sender;

        nextOrder++;
    }

    function createDeal(uint256 orderId, uint256 amount0)
        external
        nonReentrant
    {
        OrderInfo storage order = orderInfo[orderId];
        require(order.owner != address(0), "Such order does not exist");
        require(
            amount0 >= MINIMUM_ASSET && amount0 >= order.minToBuy,
            "Specify a larger amount"
        );
        require(
            order.leftAsset0.sub(order.asset0InLock) >= amount0,
            "Specify a smaller amount"
        );
        if (order.maxToBuy > 0) {
            require(amount0 <= order.maxToBuy, "Specify a smaller amount");
        }
        require(
            msg.sender != order.owner,
            "The owner of the order cannot buy from himself"
        );

        DealInfo storage deal = dealInfo[nextDeal];

        deal.orderId = orderId;

        deal.buyer = msg.sender;
        deal.seller = order.owner;

        deal.amount0 = amount0;
        deal.amountUsd = order.ratio.mul(amount0).div(RATIO_FACTOR);
        deal.amount1 = getAmountForDeal(orderId, amount0);
        require(
            deal.amount1 > 0 && deal.amountUsd > 0,
            "Specify a larger amount"
        );
        order.asset0InLock = order.asset0InLock.add(amount0);

        userInfo[msg.sender].openDeals.push(nextDeal);
        userInfo[order.owner].openDeals.push(nextDeal);

        deal.timeStart = block.timestamp;

        nextDeal++;
    }

    function cancellOrder(uint256 orderId) public {
        OrderInfo storage order = orderInfo[orderId];
        require(order.owner == msg.sender, "not Owner!");

        uint256 amountUsd = order
            .ratio
            .mul(order.leftAsset0.sub(order.asset0InLock))
            .div(RATIO_FACTOR);
        require(amountUsd > 0, "There are no free USD to cancel the order.");

        order.usdLock = order.usdLock.sub(amountUsd);
        order.leftAsset0 = order.asset0InLock;
        IERC20(USD).safeTransfer(order.owner, amountUsd);
        if (order.leftAsset0 == 0) {
            deleteOrder(orderId);
        }
    }

    function setConflict(uint256 dealId) external nonReentrant {
        DealInfo storage deal = dealInfo[dealId];
        require(
            deal.seller == msg.sender || deal.buyer == msg.sender,
            "Not seller or buyer"
        );
        require(deal.sign < 2, "Deal already close");
        require(canConflict(dealId), "Please wait or Conflict is Open!");

        deal.isConflict = true;

        UserInfo storage buyer = userInfo[deal.buyer];
        buyer.conflictDeals.push(dealId);

        UserInfo storage seller = userInfo[deal.seller];
        seller.conflictDeals.push(dealId);
    }

    function updateOrderLimits(
        uint256 orderId,
        uint256 minToBuy,
        uint256 maxToBuy
    ) external nonReentrant {
        OrderInfo storage order = orderInfo[orderId];
        require(order.owner == msg.sender, "Not Order Owner!");
        require(order.usdLock > 0, "The order was completely closed.");
        require(
            minToBuy <= order.amountAsset0 && maxToBuy <= order.amountAsset0,
            "Check the limits of your order"
        );
        if (maxToBuy > 0) {
            require(maxToBuy >= minToBuy, "Check the limits of your order");
        }

        order.minToBuy = minToBuy;
        order.maxToBuy = maxToBuy;
    }

    function fastChangeOrder(
        uint256 orderId,
        uint256 addedAmountAsset0,
        uint256 ratio0,
        uint256 ratio1,
        uint256 minToBuy,
        uint256 maxToBuy
    ) external {
        OrderInfo storage order = orderInfo[orderId];
        require(order.owner == msg.sender, "Not Order Owner!");
        require(order.usdLock > 0, "The order was completely closed.");
        uint256 newAmount0 = order.leftAsset0.sub(order.asset0InLock).add(
            addedAmountAsset0
        );
        cancellOrder(orderId);
        createOrder(
            order.methods,
            order.asset0,
            order.asset1,
            ratio0,
            ratio1,
            newAmount0,
            minToBuy,
            maxToBuy
        );
    }

    function putSignBuyer(uint256 dealId) external nonReentrant {
        DealInfo storage deal = dealInfo[dealId];
        require(deal.buyer == msg.sender, "Not buyer");
        require(deal.sign < 2, "Deal already close");
        require(!deal.buyerSigned, "You have already signed");
        deal.sign++;
        deal.buyerSigned = true;
        if (deal.sign == 2) {
            confirmDeal(dealId);
        }
    }

    function putSignSeller(uint256 dealId) external nonReentrant {
        DealInfo storage deal = dealInfo[dealId];
        require(deal.seller == msg.sender, "Not seller");
        require(deal.sign < 2, "Deal already close");
        require(!deal.sellerSigned, "You have already signed");
        deal.sign++;
        deal.sellerSigned = true;
        if (deal.sign == 2) {
            confirmDeal(dealId);
        }
    }

    // private

    function confirmDeal(uint256 dealId) private {
        DealInfo storage deal = dealInfo[dealId];
        (uint256 tAmount, uint256 feeAmount) = getTransferAmounts(
            deal.amountUsd
        );
        IERC20(USD).safeTransfer(FeeRecipient, feeAmount);
        IERC20(USD).safeTransfer(deal.seller, tAmount);

        OrderInfo storage order = orderInfo[deal.orderId];
        order.asset0InLock = order.asset0InLock.sub(deal.amount0);
        order.usdLock = order.usdLock.sub(deal.amountUsd);
        order.leftAsset0 = order.leftAsset0.sub(deal.amount0);

        if (order.leftAsset0 == 0) {
            deleteOrder(deal.orderId);
        }

        deleteOpenDeal(dealId);

        if (deal.isConflict) {
            closeConflict(dealId);
        }
    }

    function deleteOpenDeal(uint256 dealId) private {
        DealInfo storage deal = dealInfo[dealId];
        UserInfo storage user = userInfo[deal.buyer];
        UserInfo storage seller = userInfo[deal.seller];

        uint256[] storage array0 = user.openDeals;
        for (uint256 i = 0; i < array0.length; i++) {
            if (array0[i] == dealId) {
                array0[i] = array0[array0.length - 1];
                array0.pop();
                break;
            }
        }
        user.openDeals = array0;

        uint256[] storage array1 = seller.openDeals;
        for (uint256 i = 0; i < array1.length; i++) {
            if (array1[i] == dealId) {
                array1[i] = array1[array1.length - 1];
                array1.pop();
                break;
            }
        }
        seller.openDeals = array1;

        deal.timeEnd = block.timestamp;
    }

    function deleteOrder(uint256 orderId) private {
        OrderInfo storage order = orderInfo[orderId];

        for (uint8 i = 0; i < order.methods.length; i++) {
            uint256[] storage arrayByMethod = ordersByMethod[order.methods[i]];
            for (uint256 y = 0; y < arrayByMethod.length; y++) {
                if (arrayByMethod[y] == orderId) {
                    arrayByMethod[y] = arrayByMethod[arrayByMethod.length - 1];
                    arrayByMethod.pop();
                    break;
                }
            }
            ordersByMethod[order.methods[i]] = arrayByMethod;
        }

        uint256[] storage arrayOrders = sellerInfo[order.owner];
        for (uint256 i = 0; i < arrayOrders.length; i++) {
            if (arrayOrders[i] == orderId) {
                arrayOrders[i] = arrayOrders[arrayOrders.length - 1];
                arrayOrders.pop();
                break;
            }
        }
        sellerInfo[order.owner] = arrayOrders;
    }

    function closeConflict(uint256 dealId) private {
        DealInfo storage deal = dealInfo[dealId];

        if (deal.isConflict) {
            UserInfo storage buyer = userInfo[deal.buyer];
            UserInfo storage seller = userInfo[deal.seller];
            deal.isConflict = false;

            uint256[] storage ConflictArray0 = buyer.conflictDeals;
            for (uint256 i = 0; i < ConflictArray0.length; i++) {
                if (ConflictArray0[i] == dealId) {
                    ConflictArray0[i] = ConflictArray0[
                        ConflictArray0.length - 1
                    ];
                    ConflictArray0.pop();
                    break;
                }
            }
            buyer.conflictDeals = ConflictArray0;

            uint256[] storage ConflictArray1 = seller.conflictDeals;
            for (uint256 i = 0; i < ConflictArray1.length; i++) {
                if (ConflictArray1[i] == dealId) {
                    ConflictArray1[i] = ConflictArray1[
                        ConflictArray1.length - 1
                    ];
                    ConflictArray1.pop();
                    break;
                }
            }
            seller.conflictDeals = ConflictArray1;
        }
    }

    // onlyOperator

    function confirmDealByOperator(uint256 dealId, uint8 whoRight)
        external
        onlyOperator
    {
        require(whoRight == 0 || whoRight == 1, "0 - buyer, 1 - seller");
        DealInfo storage deal = dealInfo[dealId];
        require(deal.isConflict, "Not conflict");
        require(deal.sign < 2, "Deal already close");

        address account = whoRight == 0 ? deal.buyer : deal.seller;

        (uint256 tAmount, uint256 feeAmount) = getTransferAmounts(
            deal.amountUsd
        );
        IERC20(USD).safeTransfer(FeeRecipient, feeAmount);
        IERC20(USD).safeTransfer(account, tAmount);

        deal.sign = 2;
        closeConflict(dealId);
        deleteOpenDeal(dealId);

        OrderInfo storage order = orderInfo[deal.orderId];
        order.asset0InLock = order.asset0InLock.sub(deal.amount0);
        order.usdLock = order.usdLock.sub(deal.amountUsd);
        order.leftAsset0 = order.leftAsset0.sub(deal.amount0);

        if (order.leftAsset0 == 0) {
            deleteOrder(deal.orderId);
        }
    }

    // onlyOwner

    // 1505 = 1,505 %
    function updateFee(uint256 _fee) external onlyOwner {
        require(_fee <= 10000, "fee must be <= 10%");
        fee = _fee;
    }

    function setIsOperator(address account, bool _is) external onlyOwner {
        _isOperator[account] = _is;
    }

    function updateTimestampToConflict(uint256 _minutes) external onlyOwner {
        require(_minutes <= 120, "_minutes must be <= 120");
        timestampToConflict = _minutes * 60;
    }

    function updateMinimumUsdOrder(uint256 newMinimumUsdOrder)
        external
        onlyOwner
    {
        minimumUsdOrder = newMinimumUsdOrder;
    }

    function updateFeeRecipient(address _FeeRecipient) external onlyOwner {
        FeeRecipient = _FeeRecipient;
    }

    function WithdrawWrongTokens(address token, uint256 amount)
        external
        onlyOwner
    {
        require(token != USD, "Cant Withdraw USD");
        IERC20(token).safeTransfer(msg.sender, amount);
    }
}