/**
 *Submitted for verification at polygonscan.com on 2023-02-03
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
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
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
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
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
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
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
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
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
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

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}


/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}


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
        return msg.sender;
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

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}



/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
      * @dev Safely transfers `tokenId` token from `from` to `to`.
      *
      * Requirements:
      *
      * - `from` cannot be the zero address.
      * - `to` cannot be the zero address.
      * - `tokenId` token must exist and be owned by `from`.
      * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
      * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
      *
      * Emits a {Transfer} event.
      */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

//import './PowerToken.sol';


interface PowerToken {
    function mint(address _to, uint256 _amount) external;

    function addMiner(address _miner) external;

    function removeMiner(address _miner) external;

    //IERC20
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract Expedition is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct StakeInfo {
        uint256 amount; // How many LP tokens the user has provided.
        // uint256 userAccShare; // not used yet
        uint256 timeStamp;
        uint256 rewardDebt; // how much reward debt pending on user end
    }
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        StakeInfo[] stakeInfo; // this array hold all the stakes enteries for each user
    }
    struct PoolInfo {
        IERC20 lpToken; // Address of LP token contract.
        uint256 lastRewardBlock; // Last block number that Tokens distribution occurs.
        uint256 rewardTokensPerBlock; //  Reward tokens created per block.
        uint256 totalStaked; // total Staked For one pool
        uint256 accTokensPerShare; // Accumulated Tokens per share, times 1e12. See below.
        bool isStopped; // represent either pool is farming or not
        uint256 fromBlock; // fromBlock represent block number from which reward is going to be governed
        uint256 toBlock; // fromBlock represent block number till which multplier remain active
        uint256 actualMultiplier; // represent the mutiplier value that will reamin active until fromBlock and toBlock,
        uint256 lockPeriod; // represent the locktime of pool
        uint256 penaltyPercentage; // represent the penalty percentage incured before withdrawing locktime
        uint256 poolEndTime; // poolEndTime represent block number when the pool ends. Note: its just for reading purpose over frontend
    }

    mapping(address => UserInfo) public userInfo;

    address public lockWallet;

    PowerToken public stakingToken;

    uint256 public constant maxLockPeriod = 63072000;

    uint256 public constant maxLockPenaltyPercentage = 100;

    bool public doMint;
    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user stakes.

    event Deposit(
        address indexed user,
        uint256 indexed pid,
        uint256 amount,
        uint256 accTokensPerShare
    );
    event Withdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount,
        uint256 accTokensPerShare
    );
    event EmergencyWithdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );

    constructor(
        PowerToken _stakingToken,
        bool _doMint,
        address _lockWallet
    ) public {
        stakingToken = _stakingToken;
        doMint = _doMint;
        lockWallet = _lockWallet;
    }

    function updateMintStatus(bool _doMint) external onlyOwner {
        doMint = _doMint;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    // Owner can update multiplier of the function
    function updatePoolMultiplier(
        uint256 _pid,
        uint256 _fromBlock, // removed in v2 why?
        uint256 _toBlock,
        uint256 _actualMultiplier
    ) external onlyOwner {
        require(
            _fromBlock < _toBlock,
            "CG Staking: _fromBlock Should be less than _toBlock"
        );
        PoolInfo storage pool = poolInfo[_pid];
        // PoolMultiplier storage poolMulti = poolMultipliers[_index];
        pool.fromBlock = _fromBlock;
        pool.toBlock = _toBlock;
        pool.actualMultiplier = _actualMultiplier;
        updatePool(_pid);
    }

    // Owner Can Update locktime and PenaltyPecentage for a pool
    function updateLockPeriod(
        uint256 _pid,
        uint256 _lockPeriod,
        uint256 _penaltyPercentage
    ) external onlyOwner {
        require(_lockPeriod < maxLockPeriod, " Lock Period Exceeded ");

        require(
            _penaltyPercentage < maxLockPenaltyPercentage,
            " Lock Percentage Exceeded"
        );

        PoolInfo storage pool = poolInfo[_pid];
        pool.lockPeriod = _lockPeriod;
        pool.penaltyPercentage = _penaltyPercentage;
    }

    // Owner can stop farming at anypoint of time
    function stopFarming(uint256 _pid) external onlyOwner {
        PoolInfo storage pool = poolInfo[_pid];
        pool.isStopped = true;
        //pool.toBlock = block.number; // from v2 version, not verified
        // this increases reward by one block, and doesnt effect the reward increases
        //updatePool(_pid);// v3
    }

    // from v2 version, not verified
    function startFarming(uint256 _pid, uint256 _toBlock) external onlyOwner {
        PoolInfo storage pool = poolInfo[_pid];
        require(pool.isStopped, "Already Started");
        require(
            _toBlock <= pool.poolEndTime && block.number <= pool.poolEndTime,
            "Cannot Extend Pool"
        );
        pool.isStopped = false;
        pool.lastRewardBlock = block.number;
        pool.toBlock = _toBlock;
        //updatePool(_pid);// v3
    }

    // Owner can change lockWallet address
    function changeLockWalletAddress(address _lockWallet) external onlyOwner {
        lockWallet = _lockWallet;
    }

    // Owner can add pool in the contract and max one pool can be added
    function addPool(
        IERC20 _lpToken,
        uint256 _fromBlock,
        uint256 _toBlock,
        uint256 _actualMultiplier,
        uint256 _rewardTokensPerBlock,
        uint256 _lockPeriod,
        uint256 _penaltyPercentage,
        uint256 _poolEndTime
    ) external onlyOwner {
        require(
            _fromBlock < _toBlock,
            "CG Staking: _fromBlock Should be less than _toBlock"
        );
        require(poolInfo.length < 1, "CG Staking: Pool Already Added");
        require(
            address(_lpToken) != address(0),
            "CG Staking: _lpToken should not be address zero"
        );

        uint256 lastRewardBlock = block.number > _fromBlock
            ? block.number
            : _fromBlock;
        poolInfo.push(
            PoolInfo({
                lpToken: _lpToken,
                rewardTokensPerBlock: _rewardTokensPerBlock,
                totalStaked: 0,
                fromBlock: _fromBlock,
                toBlock: _toBlock,
                actualMultiplier: _actualMultiplier,
                lastRewardBlock: lastRewardBlock,
                accTokensPerShare: 0,
                isStopped: false,
                lockPeriod: _lockPeriod,
                penaltyPercentage: _penaltyPercentage,
                poolEndTime: _poolEndTime
            })
        );
    }

    uint256 public debug_getmultiplier_alt1;
    uint256 public debug_getmultiplier_alt2;
    uint256 public debug_getmultiplier_alt3;

    function getMultiplier_debug(
        uint256 _pid,
        uint256 _from, // pool.lastRewardBlock
        uint256 _to // block.number
    ) public returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];

        debug_getmultiplier_alt1 = _to.sub(_from).mul(pool.actualMultiplier);
        debug_getmultiplier_alt2 = _to.sub(_from);
        
        //increases after pool end
        // debug_getmultiplier_alt3 = pool.toBlock
        //         .sub(_from)
        //         .mul(pool.actualMultiplier)
        //         .add(
        //             _to.sub(pool.toBlock)
        //         );
        //
        debug_getmultiplier_alt3 = pool.toBlock
                .sub(_from)
                .mul(pool.actualMultiplier);
                // .add(
                //     _to.sub(pool.toBlock)
                // );
        
        // current block is less than end block
        if (_to <= pool.toBlock) {
            return debug_getmultiplier_alt1;
        }
        // last reward block has past end block
        //else if (_from >= pool.toBlock) {
        //    return debug_getmultiplier_alt2;
        //}
        else {
            return debug_getmultiplier_alt3;
        }
    }

    // For anytwo block range multplier can be computer using this finction
    function getMultiplier(
        uint256 _pid,
        uint256 _from, // pool.lastRewardBlock
        uint256 _to // block.number
    ) public view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];

        if (_to <= pool.toBlock) {
            return _to
            .sub(_from)
            .mul(pool.actualMultiplier);
        } 
        // else if (_from >= pool.toBlock) {
        //    return _to
        //    .sub(_from);
        //}
        else {
            return
                pool.toBlock
                .sub(_from)
                .mul(pool.actualMultiplier)
                //.add(
                //    _to.sub(pool.toBlock)
                //)
                ;
        }
    }

    function getLpSupply(IERC20 _lpToken)
        internal
        view
        returns (uint256 _lpSupply)
    {
        _lpSupply = 0;

        if (address(stakingToken) == address(_lpToken)) {
            if (
                (_lpToken.balanceOf(address(this)) -
                    lpSupplyTotalDepositedReward) >= 0
            ) {
                _lpSupply =
                    _lpToken.balanceOf(address(this)) -
                    lpSupplyTotalDepositedReward;
            }
            // else {
            //     lpSupply = 0;
            // }
        } else {
            _lpSupply = _lpToken.balanceOf(address(this));
        }

        return _lpSupply;

        // case 1: balance 10, reward 0, deposit 10
        // = balance - reward = deposit
        // = 10 - 0 = 10

        // case 2: balance 10, reward 10, deposit 0
        // = 10 - 10 = 0

        // case 3: balance 20, reward 10, deposit 10
        // = 20 - 10 = 10
    }

    uint256 public debug_accTokensPerShare;
    uint256 public debug_lpSupply;
    uint256 public debug_multiplier;
    uint256 public debug_totalReward;
    uint256 public debug_accTokensPerShare2;

    function pendingRewardDebug(uint256 _pid, address _user)
        public
        returns (uint256, uint256)
    {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_user];
        uint256 accTokensPerShare = pool.accTokensPerShare;
        //debug
        debug_accTokensPerShare = accTokensPerShare;

        uint256 lpSupply = getLpSupply(pool.lpToken);
        //debug
        debug_lpSupply = lpSupply;

        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(
                _pid,
                pool.lastRewardBlock,
                block.number
            );
            //debug
            debug_multiplier = multiplier;

            uint256 totalReward = multiplier.mul(pool.rewardTokensPerBlock);
            //debug
            debug_totalReward = totalReward;

            accTokensPerShare = accTokensPerShare.add(
                totalReward.mul(1e12).div(lpSupply)
            );
            // debug
            debug_accTokensPerShare2 = accTokensPerShare;

            if (user.amount > 0) {
                uint256 pending = 0;
                uint256 rewardwithoutLockPeriod;
                uint256 currentTimeStamp = now;

                for (
                    uint256 index = 0;
                    index < user.stakeInfo.length;
                    index++
                ) {
                    if (user.stakeInfo[index].amount == 0) {
                        continue;
                    }

                    if (
                        (
                            currentTimeStamp.sub(
                                user.stakeInfo[index].timeStamp
                            )
                        ) >= pool.lockPeriod
                    ) {
                        uint256 currentReward = user
                            .stakeInfo[index]
                            .amount
                            .mul(accTokensPerShare)
                            .div(1e12)
                            .sub(user.stakeInfo[index].rewardDebt);
                        pending = pending.add(currentReward);
                        rewardwithoutLockPeriod = rewardwithoutLockPeriod.add(
                            currentReward
                        );
                    } else {
                        uint256 reward = user
                            .stakeInfo[index]
                            .amount
                            .mul(accTokensPerShare)
                            .div(1e12)
                            .sub(user.stakeInfo[index].rewardDebt);
                        rewardwithoutLockPeriod = rewardwithoutLockPeriod.add(
                            reward
                        );
                    }
                }
                return (pending, rewardwithoutLockPeriod);
            }
        }
        return (0, 0);
    }

    function pendingReward(uint256 _pid, address _user)
        external
        view
        returns (uint256, uint256)
    {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_user];
        uint256 accTokensPerShare = pool.accTokensPerShare;
        //debug
        //debug_accTokensPerShare = accTokensPerShare;

        uint256 lpSupply = getLpSupply(pool.lpToken);
        //debug
        //debug_lpSupply = lpSupply;

        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(
                _pid,
                pool.lastRewardBlock,
                block.number
            );
            // debug_multiplier = multiplier;

            uint256 totalReward = multiplier.mul(pool.rewardTokensPerBlock);
            // debug_totalReward = totalReward;

            accTokensPerShare = accTokensPerShare.add(
                totalReward.mul(1e12).div(lpSupply)
            );
            // debug_accTokensPerShare2 = accTokensPerShare;

            if (user.amount > 0) {
                uint256 pending = 0;
                uint256 rewardwithoutLockPeriod;
                uint256 currentTimeStamp = now;

                for (
                    uint256 index = 0;
                    index < user.stakeInfo.length;
                    index++
                ) {
                    if (user.stakeInfo[index].amount == 0) {
                        continue;
                    }

                    if (
                        (
                            currentTimeStamp.sub(
                                user.stakeInfo[index].timeStamp
                            )
                        ) >= pool.lockPeriod
                    ) {
                        uint256 currentReward = user
                            .stakeInfo[index]
                            .amount
                            .mul(accTokensPerShare)
                            .div(1e12)
                            .sub(user.stakeInfo[index].rewardDebt);
                        pending = pending.add(currentReward);
                        rewardwithoutLockPeriod = rewardwithoutLockPeriod.add(
                            currentReward
                        );
                    } else {
                        uint256 reward = user
                            .stakeInfo[index]
                            .amount
                            .mul(accTokensPerShare)
                            .div(1e12)
                            .sub(user.stakeInfo[index].rewardDebt);
                        rewardwithoutLockPeriod = rewardwithoutLockPeriod.add(
                            reward
                        );
                    }
                }
                return (pending, rewardwithoutLockPeriod);
            }
        }
        return (0, 0);
    }

    // v1.2 User need X Min balance to stake
    uint256 public min_balance_to_stake = 0;

    function setMinBalanceToStake(uint256 _amount) public onlyOwner {
        min_balance_to_stake = _amount;
    }

    // v 1.2 User can only stake Y Max amount
    uint256 public max_balance_to_stake = 1000 * 10**18;

    function setMaxBalanceToStake(uint256 _amount) public onlyOwner {
        max_balance_to_stake = _amount;
    }

    // v 1.2 User need a specific enablement NFT to stake (can be set as false = do not yet)
    address public nft_needed_to_stake_address = address(0);
    bool public nft_needed_to_stake_enabled = false;

    function setNFTNeededtoStake(
        address _nftAddress,
        bool _nft_needed_to_stake_enabled
    ) public onlyOwner {
        nft_needed_to_stake_address = _nftAddress;
        nft_needed_to_stake_enabled = _nft_needed_to_stake_enabled;
    }

    uint256 public lpSupplyTotalDepositedReward = 0;

    function depositReward(uint256 _pid, uint256 _amount) external onlyOwner {
        PoolInfo storage pool = poolInfo[_pid];
        lpSupplyTotalDepositedReward += _amount;
        pool.lpToken.safeTransferFrom(
            address(msg.sender),
            address(this),
            _amount
        );
    }

    function withdrawReward(uint256 _pid, uint256 _amount) public onlyOwner {
        PoolInfo storage pool = poolInfo[_pid];
        lpSupplyTotalDepositedReward -= _amount;
        pool.lpToken.safeTransferFrom(
            address(this),
            address(msg.sender),
            _amount
        );
    }

    // function() public payable
    // {
    //     //require(false, 'Fallback function not supported as deposits must ue the depositReward function');

    //     require(isContract(msg.sender), 'Fallback function not supported as deposits must ue the depositReward function');

    // }

    // function isContract(address _addr) private returns (bool isContract){
    //     uint32 size;
    //     assembly {
    //         size := extcodesize(_addr)
    //     }
    //     return (size > 0);
    // }

    // Lets user deposit any amount of Lp tokens
    // 0 amount represent that user is only interested in claiming the reward
    function deposit(uint256 _pid, uint256 _amount) external {
        // v1.2 User need X Min balance to stake
        require(
            _amount >= min_balance_to_stake,
            "Staking amount is below minimum balance to stake "
        );
        // v 1.2 User can only stake Y Max amount
        require(
            _amount <= max_balance_to_stake,
            "Staking amount is above max balance to stake "
        );
        // v 1.2 User need a specific enablement NFT to stake (can be set as false = do not yet)
        if (nft_needed_to_stake_enabled) {
            // todo: check balance of NFT at nft_needed_to_stake_address
            uint256 balance = IERC721(nft_needed_to_stake_address).balanceOf(
                msg.sender
            );
            require(
                balance > 0,
                "NFT required to stake is enabled and user does not hold any NFTs"
            );
        }

        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[msg.sender];
        require(
            pool.isStopped == false,
            "Staking Ended, Please withdraw your tokens"
        );
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pending = 0;

            uint256 currentTimeStamp = now;

            for (uint256 index = 0; index < user.stakeInfo.length; index++) {
                if (user.stakeInfo[index].amount == 0) {
                    continue;
                }

                if (
                    (currentTimeStamp.sub((user.stakeInfo[index].timeStamp))) >=
                    pool.lockPeriod
                ) {
                    pending = pending.add(
                        user
                            .stakeInfo[index]
                            .amount
                            .mul(pool.accTokensPerShare)
                            .div(1e12)
                            .sub(user.stakeInfo[index].rewardDebt)
                    );
                    user.stakeInfo[index].rewardDebt = user
                        .stakeInfo[index]
                        .amount
                        .mul(pool.accTokensPerShare)
                        .div(1e12);
                }
            }

            if (pending > 0) {
                safeStakingTokensTransfer(msg.sender, pending);
            }
        }
        if (_amount > 0) {
            pool.lpToken.safeTransferFrom(
                address(msg.sender),
                address(this),
                _amount
            );
            user.amount = user.amount.add(_amount);
            pool.totalStaked = pool.totalStaked.add(_amount);

            user.stakeInfo.push(
                StakeInfo({
                    amount: _amount,
                    rewardDebt: _amount.mul(pool.accTokensPerShare).div(1e12),
                    timeStamp: now
                })
            );
            emit Deposit(
                msg.sender,
                _pid,
                _amount,
                (pool.accTokensPerShare).div(1e12)
            );
        }
    }

    // Lets user withdraw any amount of LPs user needs
    function withdraw(uint256 _pid, uint256 _amount) external {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[msg.sender];
        require(
            user.amount >= _amount,
            "withdraw amount higher than the deposited amount"
        );
        updatePool(_pid);

        uint256 totalSelected = 0;
        uint256 rewardForTransfers = 0;
        uint256 totalPenalty = 0;
        uint256 currentTimeStamp = now;
        bool timeToBreak = false;

        for (uint256 index = 0; index < user.stakeInfo.length; index++) {
            if (timeToBreak) {
                break;
            }

            if (user.stakeInfo[index].amount == 0) {
                continue;
            }

            uint256 deductionAmount = 0;
            if (totalSelected.add(user.stakeInfo[index].amount) >= _amount) {
                deductionAmount = _amount.sub(totalSelected);
                timeToBreak = true;
            } else {
                deductionAmount = user.stakeInfo[index].amount;
            }

            totalSelected = totalSelected.add(deductionAmount);

            // if the lockperiod is not over for the stake amount then apply panelty

            uint256 currentAmountReward = user
                .stakeInfo[index]
                .amount
                .mul(pool.accTokensPerShare)
                .div(1e12)
                .sub(user.stakeInfo[index].rewardDebt);
            user.stakeInfo[index].amount = user.stakeInfo[index].amount.sub(
                deductionAmount
            );
            uint256 rewardPenalty = (
                currentTimeStamp.sub((user.stakeInfo[index].timeStamp))
            ) < pool.lockPeriod
                ? currentAmountReward.mul(pool.penaltyPercentage).div(10**2)
                : 0;

            rewardForTransfers = rewardForTransfers.add(
                currentAmountReward.sub(rewardPenalty)
            );
            // accumulating penalty amount on each staked withdrawal to be sent to lockwallet
            totalPenalty = totalPenalty.add(rewardPenalty);
            // calculate rewardDebt for the deduction amount
            user.stakeInfo[index].rewardDebt = user
                .stakeInfo[index]
                .amount
                .mul(pool.accTokensPerShare)
                .div(1e12);
        }

        if (rewardForTransfers > 0) {
            safeStakingTokensTransfer(msg.sender, rewardForTransfers);
        }
        // penalty amount transfered to lockwallet.
        if (totalPenalty > 0) {
            safeStakingTokensTransfer(lockWallet, totalPenalty);
        }

        if (_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.totalStaked = pool.totalStaked.sub(_amount);
            pool.lpToken.safeTransfer(address(msg.sender), _amount);
        }
        emit Withdraw(
            msg.sender,
            _pid,
            _amount,
            (pool.accTokensPerShare).div(1e12)
        );
    }

    // Let the user see stake info for any of deposited LP for frontend
    function getStakeInfo(uint256 index)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        UserInfo storage user = userInfo[msg.sender];
        return (
            user.stakeInfo[index].amount,
            user.stakeInfo[index].rewardDebt,
            user.stakeInfo[index].timeStamp
        );
    }

    // Let user see total deposits
    function getUserStakesLength() external view returns (uint256) {
        return userInfo[msg.sender].stakeInfo.length;
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) external {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[msg.sender];
        uint256 totalLps = 0;
        for (uint256 index = 0; index < user.stakeInfo.length; index++) {
            if (user.stakeInfo[index].amount > 0) {
                totalLps = totalLps.add(user.stakeInfo[index].amount);
                user.stakeInfo[index].amount = 0;
                user.stakeInfo[index].rewardDebt = 0;
            }
        }
        pool.totalStaked = pool.totalStaked.sub(totalLps);
        pool.lpToken.safeTransfer(address(msg.sender), totalLps);
        emit EmergencyWithdraw(msg.sender, _pid, totalLps);
        user.amount = 0;
    }

    // Update reward variables for all pools. Be careful of gas spending!

    function massUpdatePools() external {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];

        if (block.number <= pool.lastRewardBlock || pool.isStopped) {
            return;
        }

        // uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        uint256 lpSupply = getLpSupply(pool.lpToken);

        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }

        uint256 multiplier = getMultiplier(
            _pid,
            pool.lastRewardBlock,
            block.number
        );

        uint256 stakingReward = multiplier.mul(pool.rewardTokensPerBlock);

        if (doMint) {
            stakingToken.mint(address(this), stakingReward);
        }

        pool.accTokensPerShare = pool.accTokensPerShare.add(
            stakingReward.mul(1e12).div(lpSupply)
        );

        pool.lastRewardBlock = block.number;
    }

    // Transfer reward tokens on users address
    function safeStakingTokensTransfer(address _to, uint256 _amount) internal {
        uint256 stakingTokenBalanceOnChef = stakingToken.balanceOf(
            address(this)
        );

        if (_amount > stakingTokenBalanceOnChef) {
            stakingToken.transfer(_to, stakingTokenBalanceOnChef);
        } else {
            stakingToken.transfer(_to, _amount);
        }
    }

    function adminWithdrawERC20(
        uint256 _pid,
        address token,
        uint256 amount
    ) external onlyOwner {
        PoolInfo storage pool = poolInfo[_pid];

        if (address(stakingToken) == address(pool.lpToken)) {
            withdrawReward(_pid, amount);
        } else {
            IERC20(token).transfer(msg.sender, amount);
        }
    }
}