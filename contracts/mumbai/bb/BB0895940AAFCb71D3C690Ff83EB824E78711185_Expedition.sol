/**
 *Submitted for verification at polygonscan.com on 2022-11-08
*/

// SPDX-License-Identifier: MIT

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
        // unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        // }
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
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
 * ====
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
        mapping(bytes32 => uint256) _indexes;
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

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

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
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
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

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
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

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
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
     * @dev Returns the number of values in the set. O(1).
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

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}


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


// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        //unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        //}
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        //unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        //}
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        //unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        //}
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        //unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        //}
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        //unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        //}
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
        //unchecked {
            require(b <= a, errorMessage);
            return a - b;
        //}
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        //unchecked {
            require(b > 0, errorMessage);
            return a / b;
        //}
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
        //unchecked {
            require(b > 0, errorMessage);
            return a % b;
        //}
    }
}



interface PowerToken {

    function mint(address _to, uint256 _amount) external;
    function addMiner(address _miner) external;
    function removeMiner(address _miner) external;

    //IERC20
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Expedition is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    uint256 maxStakingAmountCap = 1000 * 1e18;

    struct StakeInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 timeStamp;
        uint256 rewardDebt; // Reward debt
        uint256 rewardPerDebtShare; // maintain share per Lp at time of deposit
    }
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        StakeInfo[] stakeInfo;
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
    }

    mapping(address => UserInfo) public userInfo;

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

    constructor(PowerToken _stakingToken, bool _doMint) {
        stakingToken = _stakingToken;
        doMint = _doMint;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    // Owner can update multiplier of the function
    function updatePoolMultiplier(
        uint256 _pid,
        uint256 _fromBlock,
        uint256 _toBlock,
        uint256 _actualMultiplier
    ) external onlyOwner {
        require(
            _fromBlock < _toBlock,
            "CG Staking: _fromBlock Should be less than _toBlock"
        );

        PoolInfo storage pool = poolInfo[_pid];
        pool.fromBlock = _fromBlock;
        pool.toBlock = _toBlock;
        pool.actualMultiplier = _actualMultiplier;
    }

    // Owner Can Update locktime and PenaltyPecentage for a pool
    function updateLockPeriod(
        uint256 _pid,
        uint256 _lockPeriod,
        uint256 _penaltyPercentage
    ) external onlyOwner {
        require(_lockPeriod > maxLockPeriod, " Lock Period Exceeded ");

        require(
            _penaltyPercentage > maxLockPenaltyPercentage,
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
    }

    // Owner can add pool in the contract and max one pool can be added
    function addPool(
        IERC20 _lpToken,
        uint256 _fromBlock,
        uint256 _toBlock,
        uint256 _actualMultiplier,
        uint256 _rewardTokensPerBlock,
        uint256 _lockPeriod,
        uint256 _penaltyPercentage
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
        // if the current block number is bigger than _fromBlock
        // use the currentblock as lastRewardBlock
        uint256 lastRewardBlock = block.number > _fromBlock
            ? block.number
            : _fromBlock;
        //creating NewPool
        poolInfo.push(
            PoolInfo({
                lpToken: _lpToken, //address of LP token
                rewardTokensPerBlock: _rewardTokensPerBlock, // rewards token created/minted per block
                totalStaked: 0, //total token staked/commited to the pool
                fromBlock: _fromBlock, //block number from which the multiplier become active
                toBlock: _toBlock, //block number till the multiplier remain active
                actualMultiplier: _actualMultiplier, // represent the multiplier, which is given when from < block > to
                lastRewardBlock: lastRewardBlock, //last block number in which token distribution occurs.
                accTokensPerShare: 0, // Accumulated Tokens per share, times 1e12. See below.
                isStopped: false, // represent either pool is farming or not
                lockPeriod: _lockPeriod, //represent the lock time of the pool
                penaltyPercentage: _penaltyPercentage //represent the penalty percentage, if withdraw before locktime
            })
        );
    }

    // For anytwo block range multplier can be computer using this finction
    function getMultiplier(
        uint256 _pid,
        uint256 _from,
        uint256 _to //range you wanna check the multiplier
    ) public view returns (uint256) {
        //fetching the pool id
        PoolInfo storage pool = poolInfo[_pid];
        //check if the toBlock is less then or equal to the toblock(pool), i.e when multiplier is active
        //if yes return toBlock minus fromBlock multiplyby the actualMultiplier(pool)
        if (_to <= pool.toBlock) {
            return _to.sub(_from).mul(pool.actualMultiplier);
            //if fromBlock is greater than or equal to the toBlock(pool), i.e multiplier no longer active
            //return toBlock - fromBlock
            // if 20 - 10 = 10
        } else if (_from >= pool.toBlock) {
            return _to.sub(_from);
            //if fromBLock is when multiplier was active and toBLock when expired.
            //100 - 80 = 20 * 2 = 40 + (150 - 100) = 40 + 50 = 90
            //return ((toBlock(pool) - fromBlock) * multiplier) + (toBlock - toBlock(pool))
        } else {
            //console.log("You are rigt");
            return
                pool.toBlock.sub(_from).mul(pool.actualMultiplier).add(
                    _to.sub(pool.toBlock)
                );
        }
    }

    // View function to see pending on frontend
    function pendingReward(uint256 _pid, address _user)
        external
        view
        returns (uint256, uint256)
    {
        //fetching pool from pools array
        PoolInfo storage pool = poolInfo[_pid];
        //fetching user from UserInfo mapping
        UserInfo storage user = userInfo[_user];
        //fetching accumulatedTokensPerShare from pool
        uint256 accTokensPerShare = pool.accTokensPerShare;
        //check balanceOf on lptoken for this contract
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        //console.log("Lp supply", lpSupply);
        //if currentBlock > lastRewardBlock(pool) and blanceOf(lptoken) not equal to zero
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            //caltulating multiplier from lastRewardBlock to currentBLock
            uint256 multiplier = getMultiplier(
                _pid,
                pool.lastRewardBlock,
                block.number
            );
            //totalReward = multiplier * rewardTokenPerBlock
            uint256 totalReward = multiplier.mul(pool.rewardTokensPerBlock);
            //console.log("total Reward ", totalReward);
            //accTokensPerShare + totalReward * 1e12 / lpsupply
            accTokensPerShare = accTokensPerShare.add(
                totalReward.mul(1e12).div(lpSupply)
            );
            if (user.amount > 0) {
                uint256 pending = 0;
                uint256 rewardwithoutLockPeriod;
                uint256 currentTimeStamp = block.timestamp;

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

    // Lets user deposit Lp tokens
    function deposit(uint256 _pid, uint256 _amount) external {
        //fecth the pool from storage
        PoolInfo storage pool = poolInfo[_pid];
        //fetch the user from mapping
        UserInfo storage user = userInfo[msg.sender];
        require(
            pool.isStopped == false,
            "CG Staking: Staking Ended, Please withdraw your tokens"
        );
        //updatingPool
        updatePool(_pid);
        //runs only if the user already exsist and have amount staked
        //will calculate rewards and transfer them to the user
        if (user.amount > 0) {
            //console.log("inside if ... ");
            //fetching the accTokenPerShare
            uint256 accTokensPerShare = pool.accTokensPerShare;

            uint256 totalEligible = 0;

            uint256 totalRewardDebt = 0;

            uint256 pending = 0;

            uint256 currentTimeStamp = block.timestamp;
            //console.log("user stakeInto ", user.stakeInfo.length);
            for (uint256 index = 0; index < user.stakeInfo.length; index++) {
                //we dun need to calculate the rewards for user with amount == 0
                if (user.stakeInfo[index].amount == 0) {
                    continue;
                }
                //if the currentTimestamp - timestamp(user's deposit) greater than the lockPeriod(pool)
                if (
                    (currentTimeStamp.sub((user.stakeInfo[index].timeStamp))) >=
                    pool.lockPeriod
                ) {
                    //totalEligible = totalEligible + user's staked amount
                    totalEligible = totalEligible.add(
                        user.stakeInfo[index].amount
                    );
                    //totalRewardDebt = totalRewardDebt + user's rewardDebt
                    totalRewardDebt = totalRewardDebt.add(
                        user.stakeInfo[index].rewardDebt
                    );
                    //pendingRewards = PendingRewards + (totalEligible * accTokensPerShare / 1e12 - total)
                    pending = pending.add(
                        totalEligible.mul(accTokensPerShare).div(1e12).sub(
                            totalRewardDebt
                        )
                    );
                    //rewardDebt = user's amount * accountTokensPerShare  / 1e12
                    user.stakeInfo[index].rewardDebt = user
                        .stakeInfo[index]
                        .amount
                        .mul(accTokensPerShare)
                        .div(1e12);
                }
            }
            //if user sends _amount == 0 even than safeStakingTokens will be called
            //thus pending rewards will be transfered.
            if (pending > 0) {
                //console.log("pending rewards", pending);
                safeStakingTokensTransfer(msg.sender, pending);
            }
        }
        //when deposit amount is greater then zero,
        //new deposit will be added, no matter if it is the first time
        //or have previous deposits.
        if (_amount > 0) {
            require(user.amount + _amount < maxStakingAmountCap, "max cap hit");
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
                    timeStamp: block.timestamp,
                    rewardPerDebtShare: (pool.accTokensPerShare).div(1e12)
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

    // Lets user withdraw Lp tokens

    function withdraw(uint256 _pid, uint256 _amount) external {
        //fetching pool and user info
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        //accumulated Rewards Share will be updated via updatePool
        updatePool(_pid);
        uint256 totalSelected = 0;
        uint256 rewardForTransfers = 0;
        uint256 currentTimeStamp = block.timestamp;
        bool timeToBreak = false; //works as a non entrency guard

        //loop oper all the deposits instances
        for (uint256 index = 0; index < user.stakeInfo.length; index++) {
            if (timeToBreak) {
                break;
            }
            //if stakamount is zero of any deposit instance then skip it.
            if (user.stakeInfo[index].amount == 0) {
                //used when we have to skip the remaining block of code and start
                // the next iteration of the loop immediately.
                continue;
            }

            uint256 deductionAmount = 0;
            //if totalselected + stakedInfo amount is greter than requested withdrawl amount
            //deductionAmount = amount - totalselected, timeTOBreak True
            //else set deductionAmount to stakeInfo
            if (totalSelected.add(user.stakeInfo[index].amount) >= _amount) {
                deductionAmount = _amount.sub(totalSelected);
                timeToBreak = true;
            } else {
                deductionAmount = user.stakeInfo[index].amount;
            }
            // total selected + deduction amount
            totalSelected = totalSelected.add(deductionAmount);
            //staked amount = staked amount - deduction
            user.stakeInfo[index].amount = user.stakeInfo[index].amount.sub(
                deductionAmount
            );
            //fetching rewardPerDebtShare
            uint256 rewardPerDebtShare = user
                .stakeInfo[index]
                .rewardPerDebtShare;

            // if the lockperiod is not over for the stake amount then apply panelty

            if (
                (currentTimeStamp.sub((user.stakeInfo[index].timeStamp))) <
                pool.lockPeriod
            ) {
                //
                uint256 currentAmountReward = deductionAmount
                    .mul(pool.accTokensPerShare)
                    .div(1e12)
                    .sub(deductionAmount.mul(rewardPerDebtShare));
                uint256 rewardPenalty = currentAmountReward
                    .mul(pool.penaltyPercentage)
                    .div(10**2);
                // currentAmountReward - rewardPenalty is greater then zero
                // rewardsForTransfers = rewardsForTransfers + currentAmountReward - rewardPenalty
                if (currentAmountReward.sub(rewardPenalty) > 0) {
                    rewardForTransfers = rewardForTransfers.add(
                        currentAmountReward.sub(rewardPenalty)
                    );
                }
                // calculate rewardDebt for the deduction amount
                user.stakeInfo[index].rewardDebt = user
                    .stakeInfo[index]
                    .rewardDebt
                    .sub(deductionAmount.mul(rewardPerDebtShare));
                // rewardForTransfers = rewardForTransfers.add(
                //     deductionAmount.mul(pool.accTokensPerShare).div(1e12).sub(
                //         (deductionAmount.mul(rewardPerDebtShare))
                //     )
                // );
            } else {
                //console.log("inside else");
                rewardForTransfers = rewardForTransfers.add(
                    deductionAmount.mul(pool.accTokensPerShare).div(1e12).sub(
                        (deductionAmount.mul(rewardPerDebtShare))
                    )
                );
                //console.log("safe staking tokens: ", rewardForTransfers);
            }
        }
        //if rewardsFor transfer greater then zero then do safeStakingTokensTransfer
        if (rewardForTransfers > 0) {
            safeStakingTokensTransfer(msg.sender, rewardForTransfers);
            //console.log("safe staking tokens: ", rewardForTransfers);
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
        //fetching the pool
        PoolInfo storage pool = poolInfo[_pid];

        //if the lastRewardBlock is passed or pool is stopped
        //then return.
        if (pool.isStopped) {
            return;
        }
        //fetching the amount owned by this contract(LP)
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        //console.log("lpsupply", lpSupply);
        //if no lpSupply, set lastRewardBLock to currnet block
        if (lpSupply == 0) {
            //console.log("lpsupply", lpSupply);
            pool.lastRewardBlock = block.number;
            return;
        }
        //fetching the multiplier
        uint256 multiplier = getMultiplier(
            _pid,
            pool.lastRewardBlock,
            block.number
        );
        //calculating the staking rewards
        uint256 stakingReward = multiplier.mul(pool.rewardTokensPerBlock);
        //if doMint is true then mint the staking rewards to this contract
        if (doMint) {
            stakingToken.mint(address(this), stakingReward);
        }
        //accTOkensPerShare + staking * 1e12 / lpsuuply
        pool.accTokensPerShare = pool.accTokensPerShare.add(
            stakingReward.mul(1e12).div(lpSupply)
        );
        //update the lastRewardBlock to this block.
        pool.lastRewardBlock = block.number;
    }

    // Transfer reward tokens on users address
    function safeStakingTokensTransfer(address _to, uint256 _amount) internal {
        //chcking the totalBalance of this contract on stakingToken
        uint256 stakingTokenBalanceOnChef = stakingToken.balanceOf(
            address(this)
        );
        // if amount greater than the stakingBlanceOnCheif transfer whole otherwise
        //transfer the amount.
        if (_amount > stakingTokenBalanceOnChef) {
            stakingToken.transfer(_to, stakingTokenBalanceOnChef);
        } else {
            stakingToken.transfer(_to, _amount);
        }
    }
}