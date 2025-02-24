// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
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
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initialized`
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initializing`
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165Upgradeable {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMathUpgradeable {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
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
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165Upgradeable {
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

    function mint(address to) external returns(uint newTokenId);

    function getCurrentTokenId() external view returns(uint);

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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

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
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

interface IRegistration {
    struct SubnetAttributes {
        uint256 subnetType;
        bool sovereignStatus;
        uint256 cloudProviderType;
        bool subnetStatusListed;
        uint256[] unitPrices;
        uint256[] otherAttributes; // eg. [1,2]
        uint256 maxClusters;
        uint256 supportFeeRate; // 1000 = 1%
        uint256 stackFeesReqd;
    }

    struct Cluster {
        address ClusterDAO;
        string DNSIP;
        uint8 listed;
        uint NFTidLocked;
    }

    struct PriceChangeRequest {
        uint256 timestamp;
        uint256[] unitPrices;
    }


    function totalSubnets() external view returns (uint256);

    function subnetAttributes(uint256 _subnetId) external view returns(SubnetAttributes memory);

    function subnetClusters(uint256 _subnetId, uint256 _clusterId) external view returns(Cluster memory);

    function getSubnetAttributes(uint256 _subnetId) external view returns(uint256 subnetType, bool sovereignStatus, uint256 cloudProviderType, bool subnetStatusListed, uint256[] memory unitPrices, uint256[] memory otherAttributes, uint256 maxClusters, uint256 supportFeeRate, uint256 stackFeeReqd);

    function getClusterAttributes(uint256 _subnetId, uint256 _clusterId) external view returns(address ClusterDAO, string memory DNSIP, uint8 listed, uint NFTIdLocked);

    function subnetLocalDAO(uint256 subnetId) external view returns (address);

    function daoRate() external view returns (uint256);

    function hasPermissionToClusterList(uint256 subnetId, address user) external view returns (bool);

    function GLOBAL_DAO_ADDRESS() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

interface ISubnetDAODistributor {

    function commitAssignedFor(uint subnetId, uint revenue) external;
    function addWeight(
        uint256 subnetId,
        address _revenueAddress,
        uint256 _weight
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

interface ISubscription {

    function getComputesOfSubnet(uint256 NFTid, uint256 subnetId) external view returns(uint256[] memory);
    function hasRole(bytes32 role, address account) external view returns(bool);

    function r_licenseFee(uint256 _nftId, uint256 _subnetId) external view returns (uint256);
    function getReferralAddress(uint256 _nftId, uint256 _subnetId)
        external
        view
        returns (address);
        
    function GLOBAL_DAO_ADDRESS() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

interface ISubscriptionBalance {
    struct NFTBalance {
        uint256 lastBalanceUpdateTime;
        uint256[3] prevBalance; // prevBalance[0] = Credit wallet, prevBalance[1] = External Deposit, prevBalance[3] = Owner wallet
        uint256[] subnetIds; // cannot be changed unless delisted
        address NFTMinter;
        uint256 mintTime;
        uint256 endOfXCTBalance;
    }

    function nftBalances(uint256 nftId)
        external
        view
        returns (NFTBalance memory);

    function totalSubnets(uint256 nftId) external view returns (uint256);

    function dripRatePerSec(uint256 NFTid)
        external
        view
        returns (uint256 totalDripRate);

    function dripRatePerSecOfSubnet(uint256 NFTid, uint256 subnetId)
        external
        view
        returns (uint256);

    function ReferralPercent() external view returns (uint256);

    function ReferralRevExpirySecs() external view returns (uint256);

    function subscribeNew(
        uint256 _nftId,
        uint256 _balanceToAdd,
        uint256 _subnetId,
        address _minter
    ) external returns (bool);

    function refreshEndOfBalance(uint256 _nftId) external returns (bool);

    function settleAccountBalance(uint256 _nftId) external returns (bool);

    function addSubnetToNFT(uint256 _nftId, uint256 _subnetId)
        external
        returns (bool);

    function changeSubnet(
        uint256 _nftId,
        uint256 _currentSubnetId,
        uint256 _newSubnetId
    ) external returns (bool);

    function isBalancePresent(uint256 _nftId) external view returns (bool);

    function getRealtimeBalances(uint256 NFTid)
        external
        view
        returns (uint256[3] memory);

    function getRealtimeCostIncurredUnsettled(uint256 NFTid)
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.2;

import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "./interfaces/ISubscriptionBalance.sol";
import "./interfaces/ISubnetDAODistributor.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "./interfaces/IRegistration.sol";
import "./interfaces/ISubscription.sol";
import "./interfaces/IERC721.sol";

contract SubscriptionBalanceCalculator is OwnableUpgradeable {
    using SafeMathUpgradeable for uint256;

    IRegistration public RegistrationContract;
    IERC721 public ApplicationNFT;
    ISubscription public SubscriptionContract;
    ISubscriptionBalance public SubscriptionBalance;
    IERC20Upgradeable public XCTToken;
    ISubnetDAODistributor public SubnetDAODistributor;

    mapping(address => uint256) public balanceOfRev;

    event ReceivedRevenue(address benficiary, uint256 bal);

    function initialize(
        IRegistration _RegistrationContract,
        IERC721 _ApplicationNFT,
        IERC20Upgradeable _XCTToken
    ) public initializer {
        __Ownable_init_unchained();
        RegistrationContract = _RegistrationContract;
        ApplicationNFT = _ApplicationNFT;
        XCTToken = _XCTToken;
    }

    function setSubscriptionContract(address _Subscription) external onlyOwner {
        require(address(SubscriptionContract) == address(0), "Already set");
        SubscriptionContract = ISubscription(_Subscription);
    }

    function setSubscriptionBalanceContract(address _SubscriptionBalance)
        external
        onlyOwner
    {
        require(address(SubscriptionBalance) == address(0), "Already set");
        SubscriptionBalance = ISubscriptionBalance(_SubscriptionBalance);
    }

    function setSubnetDAODistributor(
        ISubnetDAODistributor _SubnetDAODistributor
    ) external onlyOwner {
        require(address(SubnetDAODistributor) == address(0), "Already set");
        SubnetDAODistributor = _SubnetDAODistributor;
    }

    function t_supportFeeAddress(uint256 _tokenId)
        public
        view
        returns (address)
    {
        return ApplicationNFT.ownerOf(_tokenId);
    }

    function s_GlobalDAOAddress() public view returns (address) {
        return RegistrationContract.GLOBAL_DAO_ADDRESS();
    }

    // 1 part is SubnetDAODistributor smart contract
    // r address is NFT minter address => nftBalances[_nftId].nftMinter

    function r_licenseFee(uint256 _nftId, uint256 _subnetId)
        public
        view
        returns (uint256)
    {
        return SubscriptionContract.r_licenseFee(_nftId, _subnetId);
    }

    function s_GlobalDAORate() public view returns (uint256) {
        return RegistrationContract.daoRate();
    }

    function t_SupportFeeRate(uint256 _subnetId)
        public
        view
        returns (uint256 fee)
    {
        (, , , , , , , fee, ) = RegistrationContract.getSubnetAttributes(
            _subnetId
        );
    }

    function u_ReferralPercent() public view returns (uint256) {
        return SubscriptionBalance.ReferralPercent();
    }

    function u_ReferralExpiry() public view returns (uint256) {
        return SubscriptionBalance.ReferralRevExpirySecs();
    }

    function calculateUpdatedPrevBal(
        uint256 totalCostIncurred,
        uint256[3] memory prevBalance
    ) internal pure returns (uint256[3] memory prevBalanceUpdated) {
        uint256 balCostLeft = 0;
        prevBalanceUpdated = [prevBalance[0], prevBalance[1], prevBalance[2]];
        if (totalCostIncurred < prevBalance[0])
            prevBalanceUpdated[0] = prevBalance[0].sub(totalCostIncurred);
        else {
            balCostLeft = totalCostIncurred.sub(prevBalance[0]);
            prevBalanceUpdated[0] = 0;
            if (balCostLeft < prevBalance[1]) {
                prevBalanceUpdated[1] = prevBalance[1].sub(balCostLeft);
                balCostLeft = 0;
            } else {
                balCostLeft = balCostLeft.sub(prevBalance[1]);
                prevBalanceUpdated[1] = 0;
                if (balCostLeft < prevBalance[2]) {
                    prevBalanceUpdated[2] = prevBalance[2].sub(balCostLeft);
                    balCostLeft = 0;
                } else {
                    prevBalanceUpdated[2] = 0;
                }
            }
        }
    }

    function getComputeCosts(
        uint256 nftId,
        uint256[] memory subnetIds,
        uint256 lastBalanceUpdatedTime
    ) internal view returns (uint256 computeCost) {
        uint256 computeCostPerSec = 0;
        for (uint256 i = 0; i < subnetIds.length; i++) {
            uint256[] memory computeRequired = SubscriptionContract
                .getComputesOfSubnet(nftId, subnetIds[i]);
            (, , , , uint256[] memory unitPrices, , , , ) = RegistrationContract
                .getSubnetAttributes(subnetIds[i]);
            for (uint256 j = 0; j < computeRequired.length; j++) {
                computeCostPerSec = computeCostPerSec.add(
                    computeRequired[j].mul(unitPrices[j])
                );
            }
        }
        computeCost = computeCostPerSec.mul(
            block.timestamp.sub(lastBalanceUpdatedTime)
        );
    }

    function receiveRevenue() external {
        receiveRevenueForAddress(_msgSender());
    }

    function receiveRevenueForAddressBulk(address[] memory _userAddresses)
        external
    {
        for (uint256 i = 0; i < _userAddresses.length; i++)
            receiveRevenueForAddress(_userAddresses[i]);
    }

    function receiveRevenueForAddress(address _userAddress) public {
        uint256 bal = balanceOfRev[_userAddress];
        XCTToken.transfer(_userAddress, bal);
        balanceOfRev[_userAddress] = 0;
        emit ReceivedRevenue(_userAddress, bal);
    }

    function getRealtimeBalance(
        uint256 nftId,
        uint256[] memory subnetIds,
        uint256[3] memory prevBalance,
        uint256 lastBalanceUpdatedTime
    ) external view returns (uint256[3] memory) {
        uint256 computeCost = getComputeCosts(
            nftId,
            subnetIds,
            lastBalanceUpdatedTime
        );

        uint256[4] memory costIncurredArr = [
            uint256(0),
            s_GlobalDAORate().mul(computeCost).div(100000),
            0,
            u_ReferralPercent().mul(computeCost).div(100000)
        ]; //r,s,t,u

        for (uint256 i = 0; i < subnetIds.length; i++) {
            costIncurredArr[0] = costIncurredArr[0].add(
                r_licenseFee(nftId, subnetIds[i]).mul(computeCost).div(100000)
            );
            costIncurredArr[2] = costIncurredArr[2].add(
                t_SupportFeeRate(subnetIds[i]).mul(computeCost).div(100000)
            );
        }

        return
            calculateUpdatedPrevBal(
                (
                    costIncurredArr[0] // r
                    .add(costIncurredArr[1]) // s
                        .add(costIncurredArr[2])
                        .add(costIncurredArr[3])
                        .add(computeCost) // t // u
                ), // 1
                prevBalance
            );
    }

    function getRealtimeCostIncurred(
        uint256 nftId,
        uint256[] memory subnetIds,
        uint256 lastBalanceUpdatedTime
    ) external view returns (uint256) {
        uint256 computeCost = getComputeCosts(
            nftId,
            subnetIds,
            lastBalanceUpdatedTime
        );

        uint256[4] memory costIncurredArr = [
            uint256(0),
            s_GlobalDAORate().mul(computeCost).div(100000),
            0,
            u_ReferralPercent().mul(computeCost).div(100000)
        ]; //r,s,t,u

        for (uint256 i = 0; i < subnetIds.length; i++) {
            costIncurredArr[0] = costIncurredArr[0].add(
                r_licenseFee(nftId, subnetIds[i]).mul(computeCost).div(100000)
            );
            costIncurredArr[2] = costIncurredArr[2].add(
                t_SupportFeeRate(subnetIds[i]).mul(computeCost).div(100000)
            );
        }

        return (
            costIncurredArr[0] // r
            .add(costIncurredArr[1]) // s
                .add(costIncurredArr[2])
                .add(costIncurredArr[3])
                .add(computeCost) // t // u
        );
    }

    function getUpdatedBalance(
        uint256 nftId,
        uint256[] memory subnetIds,
        address nftMinter,
        uint256 mintTime,
        uint256[3] memory prevBalance,
        uint256 lastBalanceUpdatedTime
    ) external returns (uint256[3] memory) {
        uint256 computeCost = getComputeCosts(
            nftId,
            subnetIds,
            lastBalanceUpdatedTime
        );

        if (computeCost > 100000) {
            uint256[4] memory costIncurredArr = [
                uint256(0),
                s_GlobalDAORate().mul(computeCost).div(100000),
                0,
                u_ReferralPercent().mul(computeCost).div(100000)
            ]; //r,s,t,u

            // update S revenue of (1+R+S+T+U) revenue
            balanceOfRev[s_GlobalDAOAddress()] = balanceOfRev[
                s_GlobalDAOAddress()
            ].add(costIncurredArr[1]);

            uint256 nftIdCopy = nftId;
            uint256[] memory subnetIdsCopy = subnetIds;
            address nftMinterCopy = nftMinter;
            uint256 mintTimeCopy = mintTime;

            for (uint256 i = 0; i < subnetIdsCopy.length; i++) {
                costIncurredArr[0] = costIncurredArr[0].add(
                    r_licenseFee(nftIdCopy, subnetIdsCopy[i])
                        .mul(computeCost)
                        .div(100000)
                );
                costIncurredArr[2] = costIncurredArr[2].add(
                    t_SupportFeeRate(subnetIdsCopy[i]).mul(computeCost).div(
                        100000
                    )
                );

                // LOGIC removed, now using SubnetDAODistributor contract
                // balanceOfRev[
                //     subnetDAOWalletFor1(subnetIdsCopy[i])
                // ] = balanceOfRev[subnetDAOWalletFor1(subnetIdsCopy[i])].add(
                //     computeCost
                // );

                // update (1)(for subnetDAOWallet to SubnetDAODistributor contract) of (1+R+S+T+U) revenue
                balanceOfRev[address(SubnetDAODistributor)] = balanceOfRev[
                    address(SubnetDAODistributor)
                ].add(computeCost);
                SubnetDAODistributor.commitAssignedFor(
                    subnetIdsCopy[i],
                    computeCost
                );

                // update (u) of of (1+R+S+T+U) revenue
                if (mintTimeCopy.add(u_ReferralExpiry()) > block.timestamp) {
                    address ReferrerAddress = SubscriptionContract
                        .getReferralAddress(nftIdCopy, subnetIdsCopy[i]);

                    balanceOfRev[ReferrerAddress] = balanceOfRev[
                        ReferrerAddress
                    ].add(costIncurredArr[3]);
                }
                // add to Global DAO
                else {
                    balanceOfRev[s_GlobalDAOAddress()] = balanceOfRev[
                        s_GlobalDAOAddress()
                    ].add(costIncurredArr[3]);
                }
            }
            // update R revenue of (1+R+S+T+U) revenue
            balanceOfRev[nftMinterCopy] = balanceOfRev[nftMinterCopy].add(
                costIncurredArr[0]
            );

            // update T revenue of (1+R+S+T+U) revenue
            balanceOfRev[t_supportFeeAddress(nftIdCopy)] = balanceOfRev[
                t_supportFeeAddress(nftIdCopy)
            ].add(costIncurredArr[2]);

            return
                calculateUpdatedPrevBal(
                    (
                        costIncurredArr[0] // r
                        .add(costIncurredArr[1]) // s
                            .add(costIncurredArr[2])
                            .add(costIncurredArr[3])
                            .add(computeCost) // t // u
                    ), // 1
                    prevBalance
                );
        }
        return prevBalance;
    }
}