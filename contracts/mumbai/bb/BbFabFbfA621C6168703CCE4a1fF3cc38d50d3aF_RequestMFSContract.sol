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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

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
 *  Trying to delete such a structure from storage will likely result in data corruption, rendering the structure unusable.
 *  See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 *  In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an array of EnumerableSet.
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
        return _values(set._inner);
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

enum Workflow {
    Preparatory,
    Presale,
    SaleHold,
    SaleOpen
}

uint256 constant PRICE_PACK_LEVEL1_IN_USD = 50e18;
uint256 constant PRICE_PACK_LEVEL1_IN_MFS_FIRST_BB = 200e18;
uint256 constant OVERRLAP_TIME_ACTIVITY = 3 days;
uint256 constant PACK_ACTIVITY_PERIOD = 30 days;
uint256 constant PURCHASE_TIME_LIMIT_PERIOD = 30 days;
uint256 constant SHARE_OF_MARKETING = 60e16;
uint256 constant SHARE_OF_REWARDS = 10e16;
uint256 constant SHARE_OF_LIQUIDITY_POOL = 10e16;
uint256 constant SHARE_OF_FORSAGE_PARTICIPANTS = 5e16;
uint256 constant SHARE_OF_META_DEVELOPMENT_AND_INCENTIVE = 5e16;
uint256 constant SHARE_OF_TEAM = 5e16;
uint256 constant SHARE_OF_LIQUIDITY_LISTING = 5e16;
uint256 constant LEVELS_COUNT = 9;
uint256 constant HMFS_COUNT = 8;
uint256 constant TRANSITION_PHASE_PERIOD = 30 days;
uint256 constant ACTIVATION_COST_RATIO_TO_RENEWAL = 5e18;
uint256 constant COEFF_INCREASE_COST_PACK_FOR_NEXT_LEVEL = 2e18;
uint256 constant COEFF_DECREASE_NEXT_BB = 2e18; //2
uint256 constant COEFF_DECREASE_COST_PACK_NEXT_BB = 2e18; //2
uint256 constant COEFF_DECREASE_COST_PACK_NEXT_MB = 6e16; //0.06
uint256 constant MB_COUNT = 10;
uint256 constant COEFF_FIRST_MB = 127e16; //1.27
uint256 constant START_COEFF_DECREASE_MICROBLOCK = 124e16;
uint256 constant MARKETING_REFERRALS_TREE_ARITY = 2;
uint256 constant ROOT_ID = 1;

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./interfaces/IRequestMFSContract.sol";
import "./interfaces/IRegistryContract.sol";
import "./interfaces/ICoreContract.sol";
import "./interfaces/IMetaForceContract.sol";
import "./interfaces/IMetaCore.sol";
import "./interfaces/IMetaPayment.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./libraries/FixedPointMath.sol";

contract RequestMFSContract is Ownable, ReentrancyGuard, IRequestMFSContract {
    using SafeERC20 for IERC20;
    using FixedPointMath for uint256;

    struct Queue {
        mapping(uint256 => uint256) data;
        uint256 front;
        uint256 back;
    }

    struct Request {
        uint256 requesterId;
        uint256 amountUSD;
    }

    struct PlaceInQueue {
        uint8 level;
        uint248 number;
    }

    IRegistryContract internal registry;

    mapping(uint256 => Queue) public queues;
    mapping(uint256 => Request) public requests;
    mapping(uint256 => uint256[]) public ownersRequests;
    mapping(uint256 => PlaceInQueue) public requestInQueue;
    uint256 public minimumRequestUSD;
    uint256 internal counter;

    modifier onlyMetaForceContract() {
        if (msg.sender != registry.getMetaForceContract()) {
            revert RMFSCSenderIsNotMetaForceContract();
        }
        _;
    }

    constructor(IRegistryContract _registry) {
        registry = _registry;
        minimumRequestUSD = 50 * SCALE;
        counter = 1;
    }

    function setMinimumRequestUSD(uint256 _minimumRequestUSD) external onlyOwner {
        minimumRequestUSD = _minimumRequestUSD;
    }

    function createRequestMFS(uint256 _amountUSD) external override nonReentrant returns (uint256 requestId) {
        if (_amountUSD < minimumRequestUSD) {
            revert RMFSCAmountUSDIsSmall();
        }
        IRegistryContract tempRegistry = registry;
        ICoreContract core = ICoreContract(tempRegistry.getCoreContract());
        IERC20 stableCoin = IERC20(tempRegistry.getStableCoin());
        uint256 senderId = getUserId(msg.sender);
        requestId = counter;
        requests[requestId].requesterId = senderId;
        requests[requestId].amountUSD = _amountUSD;
        ownersRequests[senderId].push(requestId);
        IMetaPayment metaPayment = IMetaPayment(tempRegistry.getMetaPayment());
        address metaPool = tempRegistry.getMetaPool();
        uint256 amountBefore = stableCoin.balanceOf(metaPool);
        metaPayment.decreaseBalance(address(stableCoin), senderId, metaPool, _amountUSD);
        if (stableCoin.balanceOf(metaPool) - amountBefore != _amountUSD) {
            revert MFCStableCoinFactorIsNotCorrect();
        }
        pushQueue(queues[core.getUserLevel(senderId) - 1], requestId);
        requestInQueue[requestId].level = uint8(core.getUserLevel(senderId));
        requestInQueue[requestId].number = uint248(lengthQueue(queues[core.getUserLevel(senderId) - 1]));
        unchecked {
            ++counter;
        }
    }

    function deleteRequestMFS(uint256 _requestId) external override nonReentrant {
        ICoreContract core = ICoreContract(registry.getCoreContract());
        uint256 senderId = getUserId(msg.sender);
        if (requests[_requestId].requesterId != senderId) {
            revert RMFSCSenderIsNotOwner();
        }
        core.giveStableFromPool(senderId, requests[_requestId].amountUSD);
        requests[_requestId].amountUSD = 0;
    }

    function realizeMFS(uint256 amountMFS) external override onlyMetaForceContract returns (uint256) {
        uint256 userId;
        uint256 levelQueue;
        uint256 requestId;
        uint256 amountUSD;
        uint256 amountUSDinMFS;
        uint256 priceMFS;
        ICoreContract core = ICoreContract(registry.getCoreContract());
        priceMFS = core.priceMFSInUSD();
        levelQueue = getNextLevel();
        requestId = getNextRequestId();
        while (amountMFS != 0 && requestId != 0) {
            userId = requests[requestId].requesterId;
            amountUSD = requests[requestId].amountUSD;
            amountUSDinMFS = amountUSD.div(priceMFS);
            if (amountUSDinMFS <= amountMFS) {
                core.giveMFSFromPool(userId, amountUSDinMFS);
                amountMFS -= amountUSDinMFS;
                requests[requestId].amountUSD = 0;
                deleteFirstElementInQueue(queues[levelQueue - 1]);
                requestId = getNextRequestId();
            } else {
                core.giveMFSFromPool(userId, amountMFS);
                amountUSDinMFS -= amountMFS;
                amountMFS = 0;
                requests[requestId].amountUSD = amountUSDinMFS.mul(priceMFS);
            }
        }
        return amountMFS;
    }

    function getRequestsIdsForUser(uint256 userId) external view override returns (uint256[] memory) {
        return ownersRequests[userId];
    }

    function getNumberInQueue(uint256 _requestId) external view override returns (uint256 numberInQueue) {
        uint256 level = requestInQueue[_requestId].level;
        uint256 number = uint256(requestInQueue[_requestId].number);
        for (uint256 i = LEVELS_COUNT; i > level; i--) {
            numberInQueue = numberInQueue + lengthQueue(queues[i - 1]);
        }
        numberInQueue = numberInQueue + number;
    }

    function getIdRequester(uint256 requestId) external view override returns (uint256 requesterId) {
        requesterId = requests[requestId].requesterId;
    }

    function getAmountUSDRequest(uint256 requestId) external view override returns (uint256 amount) {
        amount = requests[requestId].amountUSD;
    }

    function getNextLevel() public view override returns (uint256 levelQueue) {
        levelQueue = LEVELS_COUNT;
        while (levelQueue != 0 && lengthQueue(queues[levelQueue - 1]) == 0) {
            levelQueue--;
        }
    }

    function getNextRequestId() public view override returns (uint256 requestId) {
        uint256 levelQueue = getNextLevel();
        if (levelQueue == 0) {
            return 0;
        }
        requestId = searchNextInQueue(queues[levelQueue - 1]);
    }

    /// @dev push a new element to the back of the queue
    function pushQueue(Queue storage q, uint256 data) internal {
        q.data[q.back] = data;
        q.back = q.back + 1;
    }

    /// @dev remove and return the element at the front of the queue
    function deleteFirstElementInQueue(Queue storage q) internal {
        if (q.back == q.front) revert RMFSCQueueIsEmpty(); // throw;
        delete q.data[q.front];
        q.front = q.front + 1;
    }

    /// @dev the number of elements stored in the queue.
    function lengthQueue(Queue storage q) internal view returns (uint256) {
        return q.back - q.front;
    }

    function searchNextInQueue(Queue storage q) internal view returns (uint256) {
        if (q.back == q.front) return 0; // throw;
        return q.data[q.front];
    }

    function getUserId(address user) internal view returns (uint256 userId) {
        IMetaCore metaCore = IMetaCore(registry.getMetaCore());
        userId = metaCore.checkRegistration(user);
    }
}

// SPDX-License-Identifier:  MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "../Constants.sol";
import "./IRegistryContract.sol";

error MetaForceSpaceCoreSenderIsNotMetaContract();
error MetaForceSpaceCoreNoMoreSpaceInTree();
error MetaForceSpaceCoreActiveUser();
error MetaForceSpaceCoreSaleOpenIsLastWorkflowStep();
error MetaForceSpaceCoreSumRewardsMustBeHundred();
error MetaForceSpaceCoreRewardsIsNotChange();
error MetaForceSpaceCoreMarketingReferralRemovalFailed();
error MetaForceSpaceCoreMarketingReferralAdditionFailed();
error MetaForceSpaceCoreEmissionCommitted();
error MetaForceSpaceCoreReferrerIsNotRegistredInMarketing();

struct User {
    TypeReward rewardType;
    uint256 marketingReferrer;
    uint256 mfsFrozenAmount;
    mapping(uint256 => uint256) packs;
    EnumerableSet.UintSet marketingReferrals;
}

enum TypeReward {
    ONLY_MFS,
    MFS_AND_USD,
    ONLY_USD
}

interface ICoreContract {
    event MarketingReferrerChanged(uint256 indexed accountId, uint256 indexed marketingReferrer);
    event TimestampEndPackSet(uint256 indexed accountId, uint256 level, uint256 timestamp);
    event WorkflowStageMove(Workflow workflowstage);
    event RewardsReferrerSetted();
    event PoolMFSBurned();
    event SmallBlockMove(uint256 nowNumberSmallBlock);
    event BigBlockMove(uint256 nowNumberBigBlock);

    //Set referrer in Marketing tree
    function setMarketingReferrer(uint256 userId, uint256 marketingReferrerId) external;

    //Set users type reward
    function setTypeReward(TypeReward typeReward) external;

    //Increase timestamp end pack of the corresponding level
    function increaseTimestampEndPack(
        uint256 userId,
        uint256 level,
        uint256 time
    ) external;

    //Set timestamp end pack of the corresponding level
    function setTimestampEndPack(
        uint256 userId,
        uint256 level,
        uint256 timestamp
    ) external;

    //delete user in marketing tree
    function clearInfo(uint256 userId) external;

    //replace user in marketing tree(refer and all referrals)
    function replaceUserInMarketingTree(uint256 from, uint256 to) external;

    function nextWorkflowStage() external;

    function setEnergyConversionFactor(uint256 _energyConversionFactor) external;

    function setRewardsDirectReferrers(uint256[] calldata _rewardsRefers) external;

    function setRewardsMarketingReferrers(uint256[] calldata _rewardsMarketingRefers) external;

    function setRewardsReferrers(uint256[] calldata _rewardsRefers, uint256[] calldata _rewardsMarketingRefers)
        external;

    function distibuteMFSEmission() external;

    function burnMFSPool() external;

    function giveMFSFromPool(uint256 userId, uint256 amount) external;

    function giveStableFromPool(uint256 userId, uint256 amount) external;

    function increaseTotalEmission(uint256 amount) external;

    // Check have referrer in referral tree
    function checkRegistrationInMarketing(uint256 userId) external view returns (bool);

    // Request user type reward
    function getTypeReward(uint256 userId) external view returns (TypeReward);

    // Request timestamp end pack of the corresponding level
    function getTimestampEndPack(uint256 userId, uint256 level) external view returns (uint256);

    // Request user referrer in referral tree
    function getReferrer(uint256 userId) external view returns (uint256);

    // Request user referrer in marketing tree
    function getMarketingReferrer(uint256 userId) external view returns (uint256);

    //Request user referrals starting from indexStart in marketing tree
    function getMarketingReferrals(uint256 userId) external view returns (uint256[] memory);

    //get user level (maximum active level)
    function getUserLevel(uint256 userId) external view returns (uint256);

    function isPackActive(uint256 userId, uint256 level) external view returns (bool);

    function getWorkflowStage() external view returns (Workflow);

    function getRewardsDirectReferrers() external view returns (uint256[] memory);

    function getRewardsMarketingReferrers() external view returns (uint256[] memory);

    function getDateStartSaleOpen() external view returns (uint256);

    function getEnergyConversionFactor() external view returns (uint256);

    function getRegistrationDate(uint256 userId) external view returns (uint256);

    function getLevelForNFT(uint256 userId) external view returns (uint256);

    function bigBlockSize() external view returns (uint256);

    function meanSmallBlock() external view returns (uint256);

    function nowNumberSmallBlock() external view returns (uint256);

    function nowNumberBigBlock() external view returns (uint256);

    function endBigBlock() external view returns (uint256);

    function endSmallBlock() external view returns (uint256);

    function nowCoeffDecreaseMicroBlock() external view returns (uint256);

    function meanDecreaseMicroBlock() external view returns (uint256);

    function nowPriceFirstPackInMFS() external view returns (uint256);

    function priceMFSInUSD() external view returns (uint256);

    function totalEmissionMFS() external view returns (uint256);

    function calcMFSAmountForUSD(uint256 amountUSD) external view returns (uint256 amount);

    function calcUSDAmountForMFS(uint256 amountMFS) external view returns (uint256 amountUSD);
}

// SPDX-License-Identifier:  MIT
pragma solidity ^0.8.17;

interface IMetaCore {
    function setPaymentChannelAddress(address newAddress) external;

    function registration(uint256 referrerId) external returns (uint256);

    function setAllowAdminControl(bool allowance) external;

    function setAlias(uint256 id, string memory al) external;

    function adminSetAlias(uint256 id, string memory al) external;

    function setHashKey(bytes32 newHashKey) external;

    function changeHashKey(
        string[] memory seed,
        uint256 id,
        bytes32 newHashKey
    ) external;

    function adminChangeHashKey(uint256 id, bytes32 newHashKey) external;

    function changeIdAddress(address newAddress) external;

    function adminChangeIdAddress(uint256 id, address newAddress) external;

    function retrieveMyIdAddress(string[] memory seed, uint256 id) external;

    function getPaymentChannelAddress() external view returns (address);

    function root() external view returns (address);

    function getUserAddress(uint256 id) external view returns (address);

    function getUserId(address userAddress) external view returns (uint256);

    function getUserIdByAlias(string memory al) external view returns (uint256);

    function nextId() external view returns (uint256);

    function getReferralPage(
        uint256 id,
        uint256 amountElementsOnPage,
        uint256 pageNumber
    ) external view returns (uint256[] memory);

    function getReferralAmount(uint256 id) external view returns (uint256);

    function getReferrer(uint256 id) external view returns (uint256);

    function getReferrers(uint256 id, uint256 amount) external view returns (uint256[] memory);

    function getRegistrationDate(uint256 id) external view returns (uint256);

    function getAlias(uint256 id) external view returns (string memory);

    function getHashKey(uint256 id) external view returns (bytes32);

    function getAllowAdminControl(uint256 id) external view returns (bool);

    function checkRegistration(address userAddress) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

error MFCUserNotRegisteredYet();
error MFCLevelMoreMaxPackLevel();
error MFCPackLevelIs0();
error MFCEarlyStageForActivatePack();
error MFCNeedActivatePack(uint256 level);
error MFCNeedRenewalPack(uint256 level);
error MFCPackIsActive(uint256 level);
error MFCNotFirstActivationPack();
error MFCBuyLimitOfMFSExceeded(uint256 shortage);
error MFCUserIsNotRegistredInMarketing();
error MFCEarlyStageForRenewalPackInHMFS();
error MFCRenewalPaymentIsOnlyPossibleInHMFS();
error MFCRenewalInThisStageOnlyForMFS();
error MFCLateForBuyMFS();
error MFCSizeArrayDifferentFromExpected();
error MFCNotEnoughHMFSNeedLevel();
error MFCRenewalAmountIs0();
error MFCStableCoinFactorIsNotCorrect();

enum TypeRenewalCurrency {
    MFS,
    hMFS1,
    hMFS2,
    hMFS3,
    hMFS4,
    hMFS5,
    hMFS6,
    hMFS7,
    hMFS8
}

struct DatesBuyingMFS {
    uint256 date;
    uint256 amount;
}

interface IMetaForceContract {
    event MFCPackIsRenewed(uint256 indexed user, uint256 level, uint256 timestampEndPack);
    event MFCPackIsActivated(uint256 indexed user, uint256 level, uint256 timestampEndPack);
    event MFCRegistryContractAddressSetted(address registry);
    event RevenueMFS(uint256 indexed accountId, uint256 indexed fromId, uint256 amount);
    event RevenueStable(uint256 indexed accountId, uint256 indexed fromId, uint256 amount);
    event LostMoney(uint256 indexed accountId, uint256 indexed fromId, uint256 amount);

    function buyMFS(uint256 amount) external;

    function activationPack(uint256 level) external;

    function firstActivationPack(uint256 marketinReferrer) external;

    function firstActivationPackWithReplace(uint256 replace) external;

    function renewalPackForMFS(uint256 level, uint256 amount) external;

    function renewalPack(
        uint256 level,
        uint256 amount,
        uint256[] memory amountCurrency
    ) external;
}

// SPDX-License-Identifier:  MIT
pragma solidity ^0.8.17;

interface IMetaPayment {
    function claim(address erc20) external;

    function claim(address erc20, uint256 amount) external;

    function add(address erc20, uint256 amount) external;

    function setFreezeStatus(address erc20, bool freeze) external; //onlyContractsRole

    function getFreezeStatusToken(address erc20) external returns (bool);

    function setDirectPayment(bool directPayment) external;

    function getDirectPaymentStatus(uint256 userId) external returns (bool);

    function getBalance(address erc20, uint256 userId) external returns (uint256);

    function setBalance(
        address erc20,
        uint256 idUser,
        uint256 amount
    ) external; //onlyContractsRole

    function increaseBalance(
        address erc20,
        uint256 idUser,
        uint256 amount
    ) external returns (uint256); //onlyContractsRole

    function decreaseBalance(
        address erc20,
        uint256 idUser,
        address principal,
        uint256 amount
    ) external returns (uint256); //onlyContractsRole

    function transferFrom(
        address erc20,
        uint256 idFrom,
        uint256 idTo,
        uint256 amount
    ) external; //onlyContractsRole

    function transfer(
        address erc20,
        uint256 idTo,
        uint256 amount
    ) external;
}

// SPDX-License-Identifier:  MIT
pragma solidity ^0.8.15;

interface IRegistryContract {
    function setMetaCore(address _metaCore) external;

    function setMetaPayment(address _metaPayment) external;

    function setHoldingContract(address _holdingContract) external;

    function setMetaForceContract(address _metaForceContract) external;

    function setCoreContract(address _coreContract) external;

    function setMFS(address _mfs) external;

    function setHMFS(uint256 level, address _hMFS) external;

    function setStableCoin(address _stableCoin) external;

    function setRequestMFSContract(address _requestMFSContract) external;

    function setEnergyCoin(address _energyCoin) external;

    function setRewardsFund(address addressFund) external;

    function setLiquidityPool(address addressPool) external;

    function setForsageParticipants(address addressPool) external;

    function setMetaDevelopmentAndIncentiveFund(address addressFund) external;

    function setTeamFund(address addressFund) external;

    function setLiquidityListingFund(address addressFund) external;

    function setMetaPool(address addressPool) external;

    function getMetaCore() external view returns (address);

    function getMetaPayment() external view returns (address);

    function getHoldingContract() external view returns (address);

    function getMetaForceContract() external view returns (address);

    function getCoreContract() external view returns (address);

    function getMFS() external view returns (address);

    function getHMFS(uint256 level) external view returns (address);

    function getStableCoin() external view returns (address);

    function getEnergyCoin() external view returns (address);

    function getRequestMFSContract() external view returns (address);

    function getRewardsFund() external view returns (address);

    function getLiquidityPool() external view returns (address);

    function getForsageParticipants() external view returns (address);

    function getMetaDevelopmentAndIncentiveFund() external view returns (address);

    function getTeamFund() external view returns (address);

    function getLiquidityListingFund() external view returns (address);

    function getMetaPool() external view returns (address);
}

// SPDX-License-Identifier:  MIT
pragma solidity ^0.8.15;

error RMFSCAmountUSDIsSmall();
error RMFSCSenderIsNotOwner();
error RMFSCQueueIsEmpty();
error RMFSCSenderIsNotMetaForceContract();

interface IRequestMFSContract {
    function createRequestMFS(uint256 _amountUSD) external returns (uint256 requestId);

    function deleteRequestMFS(uint256 _requestId) external;

    function getNextLevel() external returns (uint256 levelQueue);

    function getNextRequestId() external returns (uint256 requestId);

    function getNumberInQueue(uint256 _requestId) external returns (uint256 numberInQueue);

    function getIdRequester(uint256 _requestId) external returns (uint256 requesterId);

    function getAmountUSDRequest(uint256 _requestId) external returns (uint256 amount);

    function realizeMFS(uint256 _amountMFS) external returns (uint256 amount);

    function getRequestsIdsForUser(uint256 _userId) external returns (uint256[] memory requestsIds);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./Math.sol";

error FixedPointMathMulDivOverflow(uint256 prod1, uint256 denominator);
error FixedPointMathExpArgumentTooBig(uint256 a);
error FixedPointMathExp2ArgumentTooBig(uint256 a);
error FixedPointMathLog2ArgumentTooBig(uint256 a);

uint256 constant SCALE = 1e18;

/// @title Fixed point math implementation
library FixedPointMath {
    uint256 internal constant HALF_SCALE = 5e17;
    /// @dev Largest power of two divisor of scale.
    uint256 internal constant SCALE_LPOTD = 262144;
    /// @dev Scale inverted mod 2**256.
    uint256 internal constant SCALE_INVERSE =
        78156646155174841979727994598816262306175212592076161876661508869554232690281;

    function mul(uint256 a, uint256 b) internal pure returns (uint256 result) {
        uint256 prod0;
        uint256 prod1;
        assembly {
            let mm := mulmod(a, b, not(0))
            prod0 := mul(a, b)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        if (prod1 >= SCALE) {
            revert FixedPointMathMulDivOverflow(prod1, SCALE);
        }

        uint256 remainder;
        uint256 roundUpUnit;
        assembly {
            remainder := mulmod(a, b, SCALE)
            roundUpUnit := gt(remainder, 499999999999999999)
        }

        if (prod1 == 0) {
            assembly {
                result := add(div(prod0, SCALE), roundUpUnit)
            }
            return result;
        }

        assembly {
            result := add(
                mul(
                    or(
                        div(sub(prod0, remainder), SCALE_LPOTD),
                        mul(sub(prod1, gt(remainder, prod0)), add(div(sub(0, SCALE_LPOTD), SCALE_LPOTD), 1))
                    ),
                    SCALE_INVERSE
                ),
                roundUpUnit
            )
        }
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256 result) {
        result = mulDiv(a, SCALE, b);
    }

    /// @notice Calculates ⌊a × b ÷ denominator⌋ with full precision.
    /// @dev Credit to Remco Bloemen under MIT license https://2π.com/21/muldiv.
    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        uint256 prod0;
        uint256 prod1;
        assembly {
            let mm := mulmod(a, b, not(0))
            prod0 := mul(a, b)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        if (prod1 >= denominator) {
            revert FixedPointMathMulDivOverflow(prod1, denominator);
        }

        if (prod1 == 0) {
            assembly {
                result := div(prod0, denominator)
            }
            return result;
        }

        uint256 remainder;
        assembly {
            remainder := mulmod(a, b, denominator)

            prod1 := sub(prod1, gt(remainder, prod0))
            prod0 := sub(prod0, remainder)
        }

        unchecked {
            uint256 lpotdod = denominator & (~denominator + 1);
            assembly {
                denominator := div(denominator, lpotdod)
                prod0 := div(prod0, lpotdod)
                lpotdod := add(div(sub(0, lpotdod), lpotdod), 1)
            }
            prod0 |= prod1 * lpotdod;

            uint256 inverse = (3 * denominator) ^ 2;
            inverse *= 2 - denominator * inverse;
            inverse *= 2 - denominator * inverse;
            inverse *= 2 - denominator * inverse;
            inverse *= 2 - denominator * inverse;
            inverse *= 2 - denominator * inverse;
            inverse *= 2 - denominator * inverse;

            result = prod0 * inverse;
        }
    }

    function exp2(uint256 x) internal pure returns (uint256 result) {
        if (x >= 192e18) {
            revert FixedPointMathExp2ArgumentTooBig(x);
        }

        unchecked {
            x = (x << 64) / SCALE;

            result = 0x800000000000000000000000000000000000000000000000;
            if (x & 0x8000000000000000 != 0) {
                result = (result * 0x16A09E667F3BCC909) >> 64;
            }
            if (x & 0x4000000000000000 != 0) {
                result = (result * 0x1306FE0A31B7152DF) >> 64;
            }
            if (x & 0x2000000000000000 != 0) {
                result = (result * 0x1172B83C7D517ADCE) >> 64;
            }
            if (x & 0x1000000000000000 != 0) {
                result = (result * 0x10B5586CF9890F62A) >> 64;
            }
            if (x & 0x800000000000000 != 0) {
                result = (result * 0x1059B0D31585743AE) >> 64;
            }
            if (x & 0x400000000000000 != 0) {
                result = (result * 0x102C9A3E778060EE7) >> 64;
            }
            if (x & 0x200000000000000 != 0) {
                result = (result * 0x10163DA9FB33356D8) >> 64;
            }
            if (x & 0x100000000000000 != 0) {
                result = (result * 0x100B1AFA5ABCBED61) >> 64;
            }
            if (x & 0x80000000000000 != 0) {
                result = (result * 0x10058C86DA1C09EA2) >> 64;
            }
            if (x & 0x40000000000000 != 0) {
                result = (result * 0x1002C605E2E8CEC50) >> 64;
            }
            if (x & 0x20000000000000 != 0) {
                result = (result * 0x100162F3904051FA1) >> 64;
            }
            if (x & 0x10000000000000 != 0) {
                result = (result * 0x1000B175EFFDC76BA) >> 64;
            }
            if (x & 0x8000000000000 != 0) {
                result = (result * 0x100058BA01FB9F96D) >> 64;
            }
            if (x & 0x4000000000000 != 0) {
                result = (result * 0x10002C5CC37DA9492) >> 64;
            }
            if (x & 0x2000000000000 != 0) {
                result = (result * 0x1000162E525EE0547) >> 64;
            }
            if (x & 0x1000000000000 != 0) {
                result = (result * 0x10000B17255775C04) >> 64;
            }
            if (x & 0x800000000000 != 0) {
                result = (result * 0x1000058B91B5BC9AE) >> 64;
            }
            if (x & 0x400000000000 != 0) {
                result = (result * 0x100002C5C89D5EC6D) >> 64;
            }
            if (x & 0x200000000000 != 0) {
                result = (result * 0x10000162E43F4F831) >> 64;
            }
            if (x & 0x100000000000 != 0) {
                result = (result * 0x100000B1721BCFC9A) >> 64;
            }
            if (x & 0x80000000000 != 0) {
                result = (result * 0x10000058B90CF1E6E) >> 64;
            }
            if (x & 0x40000000000 != 0) {
                result = (result * 0x1000002C5C863B73F) >> 64;
            }
            if (x & 0x20000000000 != 0) {
                result = (result * 0x100000162E430E5A2) >> 64;
            }
            if (x & 0x10000000000 != 0) {
                result = (result * 0x1000000B172183551) >> 64;
            }
            if (x & 0x8000000000 != 0) {
                result = (result * 0x100000058B90C0B49) >> 64;
            }
            if (x & 0x4000000000 != 0) {
                result = (result * 0x10000002C5C8601CC) >> 64;
            }
            if (x & 0x2000000000 != 0) {
                result = (result * 0x1000000162E42FFF0) >> 64;
            }
            if (x & 0x1000000000 != 0) {
                result = (result * 0x10000000B17217FBB) >> 64;
            }
            if (x & 0x800000000 != 0) {
                result = (result * 0x1000000058B90BFCE) >> 64;
            }
            if (x & 0x400000000 != 0) {
                result = (result * 0x100000002C5C85FE3) >> 64;
            }
            if (x & 0x200000000 != 0) {
                result = (result * 0x10000000162E42FF1) >> 64;
            }
            if (x & 0x100000000 != 0) {
                result = (result * 0x100000000B17217F8) >> 64;
            }
            if (x & 0x80000000 != 0) {
                result = (result * 0x10000000058B90BFC) >> 64;
            }
            if (x & 0x40000000 != 0) {
                result = (result * 0x1000000002C5C85FE) >> 64;
            }
            if (x & 0x20000000 != 0) {
                result = (result * 0x100000000162E42FF) >> 64;
            }
            if (x & 0x10000000 != 0) {
                result = (result * 0x1000000000B17217F) >> 64;
            }
            if (x & 0x8000000 != 0) {
                result = (result * 0x100000000058B90C0) >> 64;
            }
            if (x & 0x4000000 != 0) {
                result = (result * 0x10000000002C5C860) >> 64;
            }
            if (x & 0x2000000 != 0) {
                result = (result * 0x1000000000162E430) >> 64;
            }
            if (x & 0x1000000 != 0) {
                result = (result * 0x10000000000B17218) >> 64;
            }
            if (x & 0x800000 != 0) {
                result = (result * 0x1000000000058B90C) >> 64;
            }
            if (x & 0x400000 != 0) {
                result = (result * 0x100000000002C5C86) >> 64;
            }
            if (x & 0x200000 != 0) {
                result = (result * 0x10000000000162E43) >> 64;
            }
            if (x & 0x100000 != 0) {
                result = (result * 0x100000000000B1721) >> 64;
            }
            if (x & 0x80000 != 0) {
                result = (result * 0x10000000000058B91) >> 64;
            }
            if (x & 0x40000 != 0) {
                result = (result * 0x1000000000002C5C8) >> 64;
            }
            if (x & 0x20000 != 0) {
                result = (result * 0x100000000000162E4) >> 64;
            }
            if (x & 0x10000 != 0) {
                result = (result * 0x1000000000000B172) >> 64;
            }
            if (x & 0x8000 != 0) {
                result = (result * 0x100000000000058B9) >> 64;
            }
            if (x & 0x4000 != 0) {
                result = (result * 0x10000000000002C5D) >> 64;
            }
            if (x & 0x2000 != 0) {
                result = (result * 0x1000000000000162E) >> 64;
            }
            if (x & 0x1000 != 0) {
                result = (result * 0x10000000000000B17) >> 64;
            }
            if (x & 0x800 != 0) {
                result = (result * 0x1000000000000058C) >> 64;
            }
            if (x & 0x400 != 0) {
                result = (result * 0x100000000000002C6) >> 64;
            }
            if (x & 0x200 != 0) {
                result = (result * 0x10000000000000163) >> 64;
            }
            if (x & 0x100 != 0) {
                result = (result * 0x100000000000000B1) >> 64;
            }
            if (x & 0x80 != 0) {
                result = (result * 0x10000000000000059) >> 64;
            }
            if (x & 0x40 != 0) {
                result = (result * 0x1000000000000002C) >> 64;
            }
            if (x & 0x20 != 0) {
                result = (result * 0x10000000000000016) >> 64;
            }
            if (x & 0x10 != 0) {
                result = (result * 0x1000000000000000B) >> 64;
            }
            if (x & 0x8 != 0) {
                result = (result * 0x10000000000000006) >> 64;
            }
            if (x & 0x4 != 0) {
                result = (result * 0x10000000000000003) >> 64;
            }
            if (x & 0x2 != 0) {
                result = (result * 0x10000000000000001) >> 64;
            }
            if (x & 0x1 != 0) {
                result = (result * 0x10000000000000001) >> 64;
            }

            result *= SCALE;
            result >>= (191 - (x >> 64));
        }
    }

    function pow(uint256 x, uint256 y) internal pure returns (uint256 result) {
        if (x == 0) {
            result = y == 0 ? SCALE : uint256(0);
        } else {
            result = exp2(mul(log2(x), y));
        }
    }

    function log2(uint256 x) internal pure returns (uint256 result) {
        if (x < SCALE) {
            revert FixedPointMathLog2ArgumentTooBig(x);
        }
        unchecked {
            uint256 n = Math.mostSignificantBit(x / SCALE);

            result = n * SCALE;

            uint256 y = x >> n;

            if (y == SCALE) {
                return result;
            }

            for (uint256 delta = HALF_SCALE; delta != 0; delta >>= 1) {
                y = (y * y) / SCALE;

                if (y >= 2 * SCALE) {
                    result += delta;

                    y >>= 1;
                }
            }
        }
    }

    function convertIntToFixPoint(uint256 integer) internal pure returns (uint256 result) {
        result = integer * SCALE;
    }

    function convertFixPointToInt(uint256 integer) internal pure returns (uint256 result) {
        result = integer / SCALE;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

library Math {
    function mostSignificantBit(uint256 x) internal pure returns (uint256 msb) {
        if (x >= 2**128) {
            x >>= 128;
            msb += 128;
        }
        if (x >= 2**64) {
            x >>= 64;
            msb += 64;
        }
        if (x >= 2**32) {
            x >>= 32;
            msb += 32;
        }
        if (x >= 2**16) {
            x >>= 16;
            msb += 16;
        }
        if (x >= 2**8) {
            x >>= 8;
            msb += 8;
        }
        if (x >= 2**4) {
            x >>= 4;
            msb += 4;
        }
        if (x >= 2**2) {
            x >>= 2;
            msb += 2;
        }
        if (x >= 2**1) {
            // No need to shift x any more.
            msb += 1;
        }
    }
}