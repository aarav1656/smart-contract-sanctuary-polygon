/**
 *Submitted for verification at polygonscan.com on 2022-08-10
*/

// SPDX-License-Identifier: MIT
// Developed by t.me/LinksUltima

pragma solidity ^0.8.14;

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
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

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

interface IBEP20 {
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
 * @title SafeBEP20
 * @dev Wrappers around BEP20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeBEP20 for IBEP20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeBEP20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(
        IBEP20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IBEP20 token,
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
     * {IBEP20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeBEP20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IBEP20 token,
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
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(
            value,
            "SafeBEP20: decreased allowance below zero"
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
    function _callOptionalReturn(IBEP20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(
            data,
            "SafeBEP20: low-level call failed"
        );
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(
                abi.decode(returndata, (bool)),
                "SafeBEP20: BEP20 operation did not succeed"
            );
        }
    }
}

contract p2pTradeOnChain is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;
    using Address for address;

    uint256 public fee = 1500; // 1.5 %

    mapping(address => OrdersByAsset0) private ordersByAsset0;

    struct OrdersByAsset0 {
        uint256[] openOrders;
    }

    mapping(address => OrdersByAsset1) private ordersByAsset1;

    struct OrdersByAsset1 {
        uint256[] openOrders;
    }

    mapping(address => SellerInfo) private sellerInfo;

    struct SellerInfo {
        uint256[] openOrders;
    }

    mapping(address => uint256) public userLastDeal;

    mapping(uint256 => OrderInfo) public orderInfo;

    struct OrderInfo {
        address Asset0;
        address Asset1;
        uint256 mintoBuy;
        uint256 ratio;
        uint256 amountAsset0;
        uint256 leftAsset0;
        address owner;
    }

    mapping(uint256 => DealInfo) public dealInfo;

    struct DealInfo {
        uint256 orderId;
        uint256 amount0;
        uint256 amount1;
        address buyer;
        address seller;
        uint256 timestampStart;
    }

    uint256 public nextOrder;
    uint256 public nextDeal = 1;

    address public FeeRecipient = 0x9c8Ee34c1DCD8B4893C933212fDa8e7e51F892A5;

    constructor(address _owner) payable {
        transferOwnership(_owner);
    }

    receive() external payable {}

    function getOrdersByAsset0(address Asset0)
        public
        view
        returns (uint256[] memory)
    {
        return ordersByAsset0[Asset0].openOrders;
    }

    function getOrdersByAsset1(address Asset1)
        public
        view
        returns (uint256[] memory)
    {
        return ordersByAsset1[Asset1].openOrders;
    }

    function getSellerInfo(address account)
        public
        view
        returns (uint256[] memory)
    {
        return sellerInfo[account].openOrders;
    }

    function updateMinimumToBuyOrder(uint256 orderId, uint256 minToBuy)
        external
    {
        OrderInfo storage order = orderInfo[orderId];
        require(order.owner == msg.sender, "not Owner!");
        require(
            minToBuy <= order.leftAsset0,
            "Min To Buy must be <= leftAsset0"
        );
        order.mintoBuy = minToBuy;
    }

    function fastChangeOrder(
        uint256 orderId,
        uint256 AddedAmountAsset0,
        uint256 ratio,
        uint256 minToBuy
    ) external {
        OrderInfo storage order = orderInfo[orderId];
        require(order.owner == msg.sender, "not Owner!");

        uint256 newAmount0 = order.leftAsset0.add(AddedAmountAsset0);
        cancellOrder(orderId);
        if (order.Asset1 != address(0)) {
            createOrder(
                order.Asset0,
                order.Asset1,
                minToBuy,
                ratio,
                newAmount0
            );
        } else {
            createOrder_ETH(order.Asset0, minToBuy, ratio, newAmount0);
        }
    }

    function cancellOrder(uint256 orderId) public {
        OrderInfo storage order = orderInfo[orderId];
        require(order.owner == msg.sender, "not Owner!");

        IBEP20(order.Asset0).safeTransfer(order.owner, order.leftAsset0);

        order.leftAsset0 = 0;

        deleteOrder(orderId);
    }

    /*
    ratio: if I give 1 Asset0 , how many Asset1 will I get?
    Asset0 = BTC
    Asset1 = USDT
    ratio = 100'000 * 10 ** 18
    1 BTC = 100'000 USDT
    */
    function createOrder(
        address Asset0,
        address Asset1,
        uint256 mintoBuy,
        uint256 ratio,
        uint256 amountAsset0
    ) public nonReentrant {
        require(amountAsset0 > 0, "Specify a larger amount");
        require(mintoBuy <= amountAsset0, "Min To Buy must be <= amount0");
        require(ratio > 0, "Ratio Must Be > 0");
        require(isContract(Asset0) && isContract(Asset1), "Not contract");
        OrderInfo storage order = orderInfo[nextOrder];

        order.Asset0 = Asset0;
        OrdersByAsset0 storage byAsset0 = ordersByAsset0[Asset0];
        byAsset0.openOrders.push(nextOrder);

        order.Asset1 = Asset1;
        OrdersByAsset1 storage byAsset1 = ordersByAsset1[Asset1];
        byAsset1.openOrders.push(nextOrder);

        order.ratio = ratio;

        order.amountAsset0 = amountAsset0;
        order.mintoBuy = mintoBuy;

        order.leftAsset0 = amountAsset0;

        safeTransferFromSupportingFee(
            msg.sender,
            address(this),
            Asset0,
            amountAsset0
        );

        sellerInfo[msg.sender].openOrders.push(nextOrder);

        order.owner = msg.sender;
        nextOrder++;
    }

    /*
    ratio: if I give 1 Asset0 , how many ETH will I get?
    Asset0 = BTC
    Asset1 = ETH
    ratio = 3 * 10 ** 18
    1 BTC = 3 ETH
    */
    function createOrder_ETH(
        address Asset0,
        uint256 mintoBuy,
        uint256 ratio,
        uint256 amountAsset0
    ) public nonReentrant {
        require(amountAsset0 > 0, "Specify a larger amount");
        require(mintoBuy <= amountAsset0, "Min To Buy must be <= amount0");
        require(ratio > 0, "Ratio Must Be > 0");
        require(isContract(Asset0), "Not contract");

        OrderInfo storage order = orderInfo[nextOrder];

        order.Asset0 = Asset0;
        OrdersByAsset0 storage byAsset0 = ordersByAsset0[Asset0];
        byAsset0.openOrders.push(nextOrder);

        order.Asset1 = address(0);
        OrdersByAsset1 storage byAsset1 = ordersByAsset1[order.Asset1];
        byAsset1.openOrders.push(nextOrder);

        order.ratio = ratio;

        order.amountAsset0 = amountAsset0;
        order.mintoBuy = mintoBuy;

        order.leftAsset0 = amountAsset0;

        safeTransferFromSupportingFee(
            msg.sender,
            address(this),
            Asset0,
            amountAsset0
        );

        sellerInfo[msg.sender].openOrders.push(nextOrder);

        order.owner = msg.sender;
        nextOrder++;
    }

    function createDeal_ETH(uint256 orderId, uint256 amount0)
        public
        payable
        nonReentrant
    {
        require(amount0 >= 0, "Specify a larger amount");
        OrderInfo storage order = orderInfo[orderId];

        require(
            order.owner != address(0),
            "Such an order is closed or does not exist"
        );
        require(order.Asset1 == address(0), "Use createDeal");

        require(amount0 >= order.mintoBuy, "Specify amount >= minToBuy");
        require(order.leftAsset0 >= amount0, "Specify a smaller amount");

        require(
            msg.sender != order.owner,
            "The owner of the order cannot buy from himself"
        );

        DealInfo storage deal = dealInfo[nextDeal];

        deal.orderId = orderId;

        deal.buyer = msg.sender;
        deal.seller = order.owner;

        userLastDeal[msg.sender] == nextDeal;
        userLastDeal[order.owner] == nextDeal;

        deal.amount0 = amount0;

        deal.amount1 = getAmountForDeal(orderId, amount0);

        require(deal.amount1 > 0, "Specify a larger amount");
        require(msg.value == deal.amount1, "Send amount ETH == deal.amount1");

        safeTransferETH(deal.seller, deal.amount1);

        (uint256 tAmount, uint256 feeAmount) = getAmountsTransfer(deal.amount0);

        IBEP20(order.Asset0).safeTransfer(deal.buyer, tAmount);
        IBEP20(order.Asset0).safeTransfer(FeeRecipient, feeAmount);

        order.leftAsset0 = order.leftAsset0.sub(deal.amount0);

        deal.timestampStart = block.timestamp;

        if (order.leftAsset0 == 0) {
            deleteOrder(deal.orderId);
        }

        nextDeal++;
    }

    function createDeal(uint256 orderId, uint256 amount0) public nonReentrant {
        require(amount0 >= 0, "Specify a larger amount");
        OrderInfo storage order = orderInfo[orderId];

        require(
            order.owner != address(0),
            "Such an order is closed or does not exist"
        );
        require(order.Asset1 != address(0), "Use createDeal_ETH");

        require(amount0 >= order.mintoBuy, "Specify amount >= minToBuy");
        require(order.leftAsset0 >= amount0, "Specify a smaller amount");

        require(
            msg.sender != order.owner,
            "The owner of the order cannot buy from himself"
        );

        DealInfo storage deal = dealInfo[nextDeal];

        deal.orderId = orderId;

        deal.buyer = msg.sender;
        deal.seller = order.owner;

        userLastDeal[msg.sender] == nextDeal;
        userLastDeal[order.owner] == nextDeal;

        deal.amount0 = amount0;

        deal.amount1 = getAmountForDeal(orderId, amount0);

        require(deal.amount1 > 0, "Specify a larger amount");

        IBEP20(order.Asset1).safeTransferFrom(
            deal.buyer,
            deal.seller,
            deal.amount1
        );

        (uint256 tAmount, uint256 feeAmount) = getAmountsTransfer(deal.amount0);

        IBEP20(order.Asset0).safeTransfer(deal.buyer, tAmount);
        IBEP20(order.Asset0).safeTransfer(FeeRecipient, feeAmount);

        order.leftAsset0 = order.leftAsset0.sub(deal.amount0);

        deal.timestampStart = block.timestamp;

        if (order.leftAsset0 == 0) {
            deleteOrder(deal.orderId);
        }

        nextDeal++;
    }

    function deleteOrder(uint256 orderId) private {
        OrderInfo storage order = orderInfo[orderId];

        OrdersByAsset0 storage byAsset0 = ordersByAsset0[order.Asset0];
        uint256[] storage arraybyAsset0 = byAsset0.openOrders;
        for (uint256 i = 0; i < arraybyAsset0.length; i++) {
            if (arraybyAsset0[i] == orderId) {
                arraybyAsset0[i] = arraybyAsset0[arraybyAsset0.length - 1];
                arraybyAsset0.pop();
                break;
            }
        }
        byAsset0.openOrders = arraybyAsset0;

        OrdersByAsset1 storage byAsset1 = ordersByAsset1[order.Asset1];
        uint256[] storage arraybyAsset1 = byAsset1.openOrders;
        for (uint256 i = 0; i < arraybyAsset1.length; i++) {
            if (arraybyAsset1[i] == orderId) {
                arraybyAsset1[i] = arraybyAsset1[arraybyAsset1.length - 1];
                arraybyAsset1.pop();
                break;
            }
        }
        byAsset1.openOrders = arraybyAsset1;

        uint256[] storage arrayOrders = sellerInfo[orderInfo[orderId].owner]
            .openOrders;
        for (uint256 i = 0; i < arrayOrders.length; i++) {
            if (arrayOrders[i] == orderId) {
                arrayOrders[i] = arrayOrders[arrayOrders.length - 1];
                arrayOrders.pop();
                break;
            }
        }
        sellerInfo[orderInfo[orderId].owner].openOrders = arrayOrders;
    }

    function getAmountForDeal(uint256 orderId, uint256 amount0)
        public
        view
        returns (uint256)
    {
        OrderInfo storage order = orderInfo[orderId];
        require(
            order.owner != address(0),
            "Such an order is closed or does not exist"
        );
        uint256 amount1 = order.ratio.mul(amount0).div(10**18);
        return (amount1);
    }

    // 15 = 1,5 %
    function updateFee(uint256 _fee) external onlyOwner {
        fee = _fee * 100;
    }

    function getAmountsTransfer(uint256 amount)
        private
        view
        returns (uint256, uint256)
    {
        uint256 feeAmount = amount.mul(fee).div(100000);
        uint256 tAmount = amount.sub(feeAmount);
        return (tAmount, feeAmount);
    }

    function updateFeeRecipient(address _FeeRecipient) external onlyOwner {
        FeeRecipient = _FeeRecipient;
    }

    function Withdraw_ETH(uint256 amount) external onlyOwner {
        payable(msg.sender).transfer(amount);
    }

    function isContract(address _address) private view returns (bool) {
        uint32 size;
        assembly {
            size := extcodesize(_address)
        }
        return (size > 0);
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "safeTransferETH: ETH transfer failed");
    }

    function safeTransferFromSupportingFee(
        address sender,
        address recipient,
        address token,
        uint256 amount
    ) private returns (uint256) {
        require(isContract(token), "Not contract");
        uint256 balanceBefore = IBEP20(token).balanceOf(recipient);

        IBEP20(token).safeTransferFrom(sender, recipient, amount);

        uint256 balanceAfter = IBEP20(token).balanceOf(recipient);
        require(balanceAfter > balanceBefore, "Balance has not changed");
        uint256 tAmount = balanceAfter.sub(balanceBefore);
        require(tAmount == amount, "Turn off fees!");
        return (tAmount);
    }
}