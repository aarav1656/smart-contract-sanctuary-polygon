// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

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
 * /// @custom:oz-upgrades-unsafe-allow constructor
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeCast.sol)

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= type(int128).min && value <= type(int128).max, "SafeCast: value doesn't fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= type(int64).min && value <= type(int64).max, "SafeCast: value doesn't fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= type(int32).min && value <= type(int32).max, "SafeCast: value doesn't fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= type(int16).min && value <= type(int16).max, "SafeCast: value doesn't fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= type(int8).min && value <= type(int8).max, "SafeCast: value doesn't fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

//SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

import "../Permissions/IRoleManager.sol";
import "../Parameters/IParameterManager.sol";
import "../Maker/IMakerRegistrar.sol";
import "../Token/IStandard1155.sol";
import "../Reactions/IReactionVault.sol";
import "../CuratorVault/ICuratorVault.sol";

interface IAddressManager {
    /// @dev Getter for the role manager address
    function roleManager() external returns (IRoleManager);

    /// @dev Setter for the role manager address
    function setRoleManager(IRoleManager _roleManager) external;

    /// @dev Getter for the role manager address
    function parameterManager() external returns (IParameterManager);

    /// @dev Setter for the role manager address
    function setParameterManager(IParameterManager _parameterManager) external;

    /// @dev Getter for the maker registrar address
    function makerRegistrar() external returns (IMakerRegistrar);

    /// @dev Setter for the maker registrar address
    function setMakerRegistrar(IMakerRegistrar _makerRegistrar) external;

    /// @dev Getter for the reaction NFT contract address
    function reactionNftContract() external returns (IStandard1155);

    /// @dev Setter for the reaction NFT contract address
    function setReactionNftContract(IStandard1155 _reactionNftContract)
        external;

    /// @dev Getter for the default Curator Vault contract address
    function defaultCuratorVault() external returns (ICuratorVault);

    /// @dev Setter for the default Curator Vault contract address
    function setDefaultCuratorVault(ICuratorVault _defaultCuratorVault)
        external;

    /// @dev Getter for the L2 bridge registrar
    function childRegistrar() external returns (address);

    /// @dev Setter for the L2 bridge registrar
    function setChildRegistrar(address _childRegistrar) external;

    /// @dev Getter for the address of the royalty registry
    function royaltyRegistry() external returns (address);

    /// @dev Setter for the address of the royalty registry
    function setRoyaltyRegistry(address _royaltyRegistry) external;

    /// @dev Getter for the address of the Like Token Factory
    function likeTokenFactory() external returns (address);

    /// @dev Setter for the address of the Like Token Factory
    function setLikeTokenFactory(address _likeTokenFactory) external;
}

//SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

import "../Token/IStandard1155.sol";
import "../Token/IWMATIC.sol";

/// @dev Interface for the curator vault
interface ICuratorVault {
    function getTokenId(
        uint256 nftChainId,
        address nftAddress,
        uint256 nftId,
        IWMATIC paymentToken
    ) external returns (uint256);

    function buyCuratorTokens(
        uint256 nftChainId,
        address nftAddress,
        uint256 nftId,
        IWMATIC paymentToken,
        uint256 paymentAmount,
        address mintToAddress,
        bool isTakerPosition
    ) external returns (uint256);

    function sellCuratorTokens(
        uint256 nftChainId,
        address nftAddress,
        uint256 nftId,
        IWMATIC paymentToken,
        uint256 tokensToBurn,
        address refundToAddress
    ) external returns (uint256);

    function curatorTokens() external returns (IStandard1155);
}

//SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

/// @dev Interface for the maker registrar that supports registering and de-registering NFTs
interface IMakerRegistrar {
    /// @dev struct for storing details about a registered NFT
    struct NftDetails {
        bool registered;
        address owner;
        address[] creators;
        uint256[] creatorSaleBasisPoints;
    }

    function transformToSourceLookup(uint256 metaId) external returns (uint256);

    function deriveSourceId(
        uint256 nftChainId,
        address nftAddress,
        uint256 nftId
    ) external returns (uint256);

    /// @dev lookup for NftDetails from source ID
    function sourceToDetailsLookup(uint256)
        external
        returns (NftDetails memory);

    function verifyOwnership(
        address nftContractAddress,
        uint256 nftId,
        address potentialOwner
    ) external returns (bool);

    function registerNftFromBridge(
        address owner,
        uint256 chainId,
        address nftContractAddress,
        uint256 nftId,
        address[] memory nftCreatorAddresses,
        uint256[] memory creatorSaleBasisPoints,
        uint256 optionBits,
        string memory ipfsMetadataHash
    ) external;

    function deRegisterNftFromBridge(
        address owner,
        uint256 chainId,
        address nftContractAddress,
        uint256 nftId
    ) external;
}

//SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

import "../Permissions/IRoleManager.sol";
import "../Token/IWMATIC.sol";

interface IParameterManager {
    /// @dev Getter for the payment token
    function paymentToken() external returns (IWMATIC);

    /// @dev Setter for the payment token
    function setPaymentToken(IWMATIC _paymentToken) external;

    /// @dev Getter for the reaction price
    function reactionPrice() external returns (uint256);

    /// @dev Setter for the reaction price
    function setReactionPrice(uint256 _reactionPrice) external;

    /// @dev Getter for the cut of purchase price going to the curator liability
    function saleCuratorLiabilityBasisPoints() external returns (uint256);

    /// @dev Setter for the cut of purchase price going to the curator liability
    function setSaleCuratorLiabilityBasisPoints(
        uint256 _saleCuratorLiabilityBasisPoints
    ) external;

    /// @dev Getter for the cut of purchase price going to the referrer
    function saleReferrerBasisPoints() external returns (uint256);

    /// @dev Setter for the cut of purchase price going to the referrer
    function setSaleReferrerBasisPoints(uint256 _saleReferrerBasisPoints)
        external;

    /// @dev Getter for the cut of spend curator liability going to the taker
    function spendTakerBasisPoints() external returns (uint256);

    /// @dev Setter for the cut of spend curator liability going to the taker
    function setSpendTakerBasisPoints(uint256 _spendTakerBasisPoints) external;

    /// @dev Getter for the cut of spend curator liability going to the taker
    function spendReferrerBasisPoints() external returns (uint256);

    /// @dev Setter for the cut of spend curator liability going to the referrer
    function setSpendReferrerBasisPoints(uint256 _spendReferrerBasisPoints)
        external;

    /// @dev Getter for the check to see if a curator vault is allowed to be used
    function approvedCuratorVaults(address potentialVault)
        external
        returns (bool);

    /// @dev Setter for the list of curator vaults allowed to be used
    function setApprovedCuratorVaults(address vault, bool approved) external;

    /// @dev Getter for the native wrapped ERC20 token (e.g. WMATIC)
    function nativeWrappedToken() external returns (IERC20Upgradeable);

    /// @dev Setter for the native wrapped ERC20 token (e.g. WMATIC)
    function setNativeWrappedToken(IERC20Upgradeable _nativeWrappedToken)
        external;

    /// @dev Setter for free reaction limit
    function freeReactionLimit() external returns (uint256);

    /// @dev Setter for free reaction limit
    function setFreeReactionLimit(uint256 limit) external;
}

//SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

interface IRoleManager {
    /// @dev Determines if the specified address has capability to mint and burn reaction NFTs
    /// @param potentialAddress Address to check
    function isAdmin(address potentialAddress) external view returns (bool);

    /// @dev Determines if the specified address has permission to udpate addresses in the protocol
    /// @param potentialAddress Address to check
    function isAddressManagerAdmin(address potentialAddress)
        external
        view
        returns (bool);

    /// @dev Determines if the specified address has permission to update parameters in the protocol
    /// @param potentialAddress Address to check
    function isParameterManagerAdmin(address potentialAddress)
        external
        view
        returns (bool);

    /// @dev Determines if the specified address has permission to to mint and burn reaction NFTs
    /// @param potentialAddress Address to check
    function isReactionNftAdmin(address potentialAddress)
        external
        view
        returns (bool);

    /// @dev Determines if the specified address has permission to purchase curator vault tokens
    /// @param potentialAddress Address to check
    function isCuratorVaultPurchaser(address potentialAddress)
        external
        view
        returns (bool);

    /// @dev Determines if the specified address has permission to mint and burn curator tokens
    /// @param potentialAddress Address to check
    function isCuratorTokenAdmin(address potentialAddress)
        external
        view
        returns (bool);
}

//SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;
import "../Token/IWMATIC.sol";

/// @dev Interface for the ReactionVault that supports buying and spending reactions
interface IReactionVault {
    struct ReactionPriceDetails {
        IWMATIC paymentToken;
        uint256 reactionPrice;
        uint256 saleCuratorLiabilityBasisPoints;
    }
}

//SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

/// @dev ^2, ^3, and sqrt functions
/// Solidity 0.8+ should catch any overflows on multiplications
library ExtendedMath {
    /**
     * @return The given number raised to the power of 2
     */
    function pow2(int256 a) internal pure returns (int256) {
        return a * a;
    }

    function pow3(int256 a) internal pure returns (int256) {
        return a * a * a;
    }

    /**
     * @return z The square root of the given positive number
     */
    function sqrt(int256 y) internal pure returns (int256 z) {
        require(y >= 0, "Negative sqrt");
        if (y > 3) {
            z = y;
            int256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

//SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

import "./ExtendedMath.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";

/// @dev This is a sigmoid bonding curve implementation to calculate buying and selling amounts
/// Formulas are inspired from https://medium.com/molecule-blog/designing-different-fundraising-scenarios-with-sigmoidal-token-bonding-curves-ceafc734ed97
contract Sigmoid {
    using ExtendedMath for int256;

    function n1(
        int256 a,
        int256 b,
        int256 c,
        int256 newReserves
    ) internal pure returns (int256) {
        return 2 * a.pow2() * b * newReserves * (b.pow2() + c).sqrt();
    }

    function n2(
        int256 a,
        int256 b,
        int256,
        int256 newReserves
    ) internal pure returns (int256) {
        return 2 * a.pow2() * b.pow2() * newReserves;
    }

    function n3(
        int256 a,
        int256,
        int256 c,
        int256 newReserves
    ) internal pure returns (int256) {
        return 2 * a.pow2() * c * newReserves;
    }

    function n4(
        int256 a,
        int256 b,
        int256 c,
        int256 newReserves
    ) internal pure returns (int256) {
        return a * newReserves.pow2() * (b.pow2() + c).sqrt();
    }

    function n5(
        int256 a,
        int256 b,
        int256,
        int256 newReserves
    ) internal pure returns (int256) {
        return 1 * a * b * newReserves.pow2();
    }

    function n6(
        int256,
        int256,
        int256,
        int256 newReserves
    ) internal pure returns (int256) {
        return newReserves.pow3();
    }

    function d1(
        int256 a,
        int256 b,
        int256 c,
        int256 newReserves
    ) internal pure returns (int256) {
        return
            a *
            (-2 *
                a.pow2() *
                c -
                4 *
                a *
                b *
                newReserves +
                2 *
                newReserves.pow2());
    }

    /// @dev Buying into the curve with payment tokens will return Tokens amount to be bought
    /// @param a maxPrice of the curve / 2
    /// @param b inflectionPoint of the curve
    /// @param c slope steepness of the curve
    /// @param currentTokensSupply current amount of Tokens in the curve
    /// @param paymentReserves current mount of payment reserves in the curve
    /// @param paymentToSpend amount the of payment tokens to buy Tokens with
    function calculateTokensBoughtFromPayment(
        int256 a,
        int256 b,
        int256 c,
        int256 currentTokensSupply,
        int256 paymentReserves,
        int256 paymentToSpend
    ) public pure returns (uint256) {
        // The amount of reserves after payment is made
        int256 newReserves = paymentReserves + paymentToSpend;

        // Calculations cause "stack too deep" so are broken into individual numerator and denominator functions
        int256 newSupply = (n6(a, b, c, newReserves) +
            n4(a, b, c, newReserves) -
            n1(a, b, c, newReserves) -
            n2(a, b, c, newReserves) -
            n3(a, b, c, newReserves) -
            n5(a, b, c, newReserves)) / (d1(a, b, c, newReserves));

        // Return the difference
        return SafeCast.toUint256(newSupply - currentTokensSupply);
    }

    /// @dev Selling Tokens into the curve will return payment tokens to be refunded
    /// @param a maxPrice of the curve / 2
    /// @param b inflectionPoint of the curve
    /// @param c slope steepness of the curve
    /// @param currentTokenSupply current amount of Tokens in the curve
    /// @param paymentReserves current mount of payment reserves in the curve
    /// @param tokensToSell amount the of Tokens the user wants to sell
    function calculatePaymentReturnedFromTokens(
        int256 a,
        int256 b,
        int256 c,
        int256 currentTokenSupply,
        int256 paymentReserves,
        int256 tokensToSell
    ) public pure returns (uint256) {
        // Supply after Tokens are sold
        int256 newSupply = currentTokenSupply - tokensToSell;

        // Calc the constant at supply = 0
        int256 constantVal = a * ((b.pow2() + c).sqrt());

        // Calculate the new reserve amount
        int256 newReserves = (a *
            (((b - newSupply).pow2() + c).sqrt() + newSupply)) - constantVal;

        // Return the difference
        return SafeCast.toUint256(paymentReserves - newReserves);
    }
}

//SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "../Token/IStandard1155.sol";
import "../Config/IAddressManager.sol";
import "./SigmoidCuratorVaultStorage.sol";
import "./Curve/Sigmoid.sol";
import "../Token/IWMATIC.sol";

/// @title SigmoidCuratorVault
/// @dev This contract tracks tokens in a sigmoid bonding curve per Taker NFT.
/// When users spend reactions against a Taker NFT, it will use the Curator Liability
/// to buy curator tokens against that Taker NFT and allocate to various parties.
/// The curator tokens will be priced via the sigmoid curve.  The params that control
/// the shape of the sigmoid are set in the parameter manager.
/// At any point in time the owners of the curator tokens can sell them back to the
/// bonding curve.
/// Note: This contract is protected via a permissioned account set in the role manager.  Caution should
/// be used as the role owner could renounce the role leaving all future actions disabled.  Additionally,
/// if a malicious account was able to obtain the role, they could use it to set values to malicious values.
/// See the public documentation website for more details.
contract SigmoidCuratorVault is
    ReentrancyGuardUpgradeable,
    Sigmoid,
    SigmoidCuratorVaultStorageV1
{
    /// @dev Use the safe methods when interacting with transfers with outside ERC20s
    using SafeERC20Upgradeable for IWMATIC;

    /// @dev verifies that the calling address is the reaction vault
    modifier onlyCuratorVaultPurchaser() {
        require(
            addressManager.roleManager().isCuratorVaultPurchaser(msg.sender),
            "Not Admin"
        );
        _;
    }

    /// @dev Event triggered when curator tokens are purchased
    event CuratorTokensBought(
        uint256 indexed curatorTokenId,
        uint256 nftChainId,
        address nftAddress,
        uint256 nftId,
        IERC20Upgradeable paymentToken,
        uint256 paymentTokenPaid,
        uint256 curatorTokensBought,
        bool isTakerPosition
    );

    /// @dev Event triggered when curator tokens are sold
    event CuratorTokensSold(
        uint256 indexed curatorTokenId,
        uint256 paymentTokenRefunded,
        uint256 curatorTokensSold
    );

    /// @notice initializer to call after deployment,
    /// @dev can only be called once
    /// @param _addressManager - address manager in the protocol
    /// @param _curatorTokens - curator token contract address
    /// @param _a - bonding curve param a
    /// @param _b - bonding curve param b
    /// @param _c - bonding curve param c
    function initialize(
        address _addressManager,
        IStandard1155 _curatorTokens,
        uint256 _a,
        uint256 _b,
        uint256 _c
    ) public initializer {
        require(address(_addressManager) != address(0x0), ZERO_INPUT);
        require(address(_curatorTokens) != address(0x0), ZERO_INPUT);

        // Save the address manager
        addressManager = IAddressManager(_addressManager);

        // Save the curator token contract
        curatorTokens = _curatorTokens;

        // Save the curve parameters
        a = _a;
        b = _b;
        c = _c;
    }

    /// @dev get a unique token ID for a given nft address and nft ID
    function getTokenId(
        uint256 nftChainId,
        address nftAddress,
        uint256 nftId,
        IWMATIC paymentToken
    ) external pure returns (uint256) {
        return _getTokenId(nftChainId, nftAddress, nftId, paymentToken);
    }

    function _getTokenId(
        uint256 nftChainId,
        address nftAddress,
        uint256 nftId,
        IERC20Upgradeable paymentToken
    ) internal pure returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encode(nftChainId, nftAddress, nftId, paymentToken)
                )
            );
    }

    /// @dev Buy curator Tokens when reactions are spent.
    /// The reaction vault is the only account allowed to call this.
    /// @return Returns the amount of curator tokens purchased.
    function buyCuratorTokens(
        uint256 nftChainId,
        address nftAddress,
        uint256 nftId,
        IWMATIC paymentToken,
        uint256 paymentAmount,
        address mintToAddress,
        bool isTakerPosition
    ) external onlyCuratorVaultPurchaser returns (uint256) {
        // Get the curator token token ID
        uint256 curatorTokenId = _getTokenId(
            nftChainId,
            nftAddress,
            nftId,
            paymentToken
        );

        // Calculate the amount of tokens that will be minted based on the price
        uint256 curatorTokenAmount = calculateTokensBoughtFromPayment(
            SafeCast.toInt256(a),
            SafeCast.toInt256(b),
            SafeCast.toInt256(c),
            SafeCast.toInt256(curatorTokenSupply[curatorTokenId]),
            SafeCast.toInt256(reserves[curatorTokenId]),
            SafeCast.toInt256(paymentAmount)
        );

        // Update the amounts
        reserves[curatorTokenId] += paymentAmount;
        curatorTokenSupply[curatorTokenId] += curatorTokenAmount;

        //
        // Pull value from ReactionVault as payment - will always be wrapped as ERC20 in the reaction vault
        //
        paymentToken.safeTransferFrom(msg.sender, address(this), paymentAmount);

        // Mint the tokens
        curatorTokens.mint(
            mintToAddress,
            curatorTokenId,
            curatorTokenAmount,
            new bytes(0)
        );

        // Emit the event
        emit CuratorTokensBought(
            curatorTokenId,
            nftChainId,
            nftAddress,
            nftId,
            paymentToken,
            paymentAmount,
            curatorTokenAmount,
            isTakerPosition
        );

        return curatorTokenAmount;
    }

    /// @dev Sell curator tokens back into the bonding curve.
    /// Any holder who owns tokens can sell them back
    /// @return Returns the amount of payment tokens received for the curator tokens.
    function sellCuratorTokens(
        uint256 nftChainId,
        address nftAddress,
        uint256 nftId,
        IWMATIC paymentToken,
        uint256 tokensToBurn,
        address refundToAddress
    ) external nonReentrant returns (uint256) {
        require(tokensToBurn > 0, "Invalid 0 input");

        // Get the curator token token ID
        uint256 curatorTokenId = _getTokenId(
            nftChainId,
            nftAddress,
            nftId,
            paymentToken
        );

        // Burn the curator tokens
        curatorTokens.burn(msg.sender, curatorTokenId, tokensToBurn);

        // Calculate the amount of tokens that will be minted based on the price
        uint256 refundAmount = calculatePaymentReturnedFromTokens(
            SafeCast.toInt256(a),
            SafeCast.toInt256(b),
            SafeCast.toInt256(c),
            SafeCast.toInt256(curatorTokenSupply[curatorTokenId]),
            SafeCast.toInt256(reserves[curatorTokenId]),
            SafeCast.toInt256(tokensToBurn)
        );

        // Update the amounts
        reserves[curatorTokenId] -= refundAmount;
        curatorTokenSupply[curatorTokenId] -= tokensToBurn;

        // Determine whether to send back ERC20 or native asset
        if (
            address(paymentToken) ==
            address(addressManager.parameterManager().nativeWrappedToken())
        ) {
            // First, unwrap the sale amount into this address
            paymentToken.withdraw(refundAmount);

            // Send the unwrapped payment token back (native MATIC)
            payable(refundToAddress).transfer(refundAmount);
        } else {
            // Send payment token back
            paymentToken.safeTransfer(refundToAddress, refundAmount);
        }

        // Emit the event
        emit CuratorTokensSold(curatorTokenId, refundAmount, tokensToBurn);

        return refundAmount;
    }

    /// @dev Allows WMATIC to be unwrapped to this address
    receive() external payable {}

    /// @dev Allows the admin account to sweep any MATIC that was accidentally sent
    function sweep() external {
        require(addressManager.roleManager().isAdmin(msg.sender), "Not Admin");
        payable(msg.sender).transfer(address(this).balance);
    }
}

//SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

import "../Config/IAddressManager.sol";
import "../CuratorVault/ICuratorVault.sol";

/// @title SigmoidCuratorVaultStorage
/// @dev This contract will hold all local variables for the SigmoidCuratorVault Contract
/// When upgrading the protocol, inherit from this contract on the V2 version and change the
/// CuratorVault to inherit from the later version.  This ensures there are no storage layout
/// corruptions when upgrading.
abstract contract SigmoidCuratorVaultStorageV1 is ICuratorVault {
    /// @dev Input error for 0 value param
    string internal constant ZERO_INPUT = "Invalid 0 input";

    /// @dev local reference to the address manager contract
    IAddressManager public addressManager;

    /// @dev tracks the total supply for each curator Token token ID
    mapping(uint256 => uint256) public curatorTokenSupply;

    /// @dev tracks the total payment amount held for each curator Token token ID
    mapping(uint256 => uint256) public reserves;

    /// @dev the 1155 contract to track curator Tokens
    IStandard1155 public curatorTokens;

    /// @dev Curve parameters
    uint256 public a;
    uint256 public b;
    uint256 public c;
}

/// On the next version of the protocol, if new variables are added, put them in the below
/// contract and use this as the inheritance chain.
/**
contract SigmoidCuratorVaultStorageV2 is SigmoidCuratorVaultStorageV1 {
  address newVariable;
}
 */

//SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

/// @dev Interface for the Standard1155 toke contract.
interface IStandard1155 {
    /// @dev Allows a priviledged account to mint tokens to the specified address
    function mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external;

    function burn(
        address from,
        uint256 id,
        uint256 amount
    ) external;
}

//SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

/// @dev Interface for interacting with the wrapped matic token contract
interface IWMATIC is IERC20Upgradeable {
    // Send MATIC directly to contract
    receive() external payable;

    // Call deposit directly
    function deposit() external payable;

    // Withdraw wrapped tokens into MATIC
    function withdraw(uint256 wad) external;
}