// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

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
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
 * ====
 */
library EnumerableSetUpgradeable {
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
// OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/Address.sol";

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
            (isTopLevelCall && _initialized < 1) || (!Address.isContract(address(this)) && _initialized == 1),
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
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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

pragma solidity 0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

import "../plugins/PluginsList.sol";
import "../registry/interfaces/IRegistry.sol";
import "../rules/interfaces/IRule.sol";
import "./interfaces/ICommunityBlank.sol";
import "../libraries/DataTypes.sol";

/// @title Contract of Page.Community.CommunityBlank
/// @author Crypto.Page Team
/// @notice
/// @dev
contract CommunityBlank is
    Initializable,
    Ownable,
    ICommunityBlank
{

    string public name;
    address public creator;
    uint256 public creatingTime;
    uint256 public authorGasCompensationPercent;
    uint256 public ownerGasCompensationPercent;

    IRegistry registry;

    uint256 public constant INITIAL_PLUGINS_VERSION = 1;
    uint256 public constant ALL_PERCENT = 10000;

    mapping(DataTypes.PaymentType => uint256) private price;
    // pluginName -> version -> linked
    mapping(bytes32 => mapping(uint256 => bool)) private linkedPlugins;
    // ruleGroupName -> version -> ruleName -> linked
    mapping(bytes32 => mapping(uint256 => mapping(bytes32 => bool))) private linkedRules;

    event LinkPlugin(address origin, address sender, bytes32 pluginName, uint256 version);
    event UnLinkPlugin(address origin, address sender, bytes32 pluginName, uint256 version);

    event LinkRule(address origin, address sender, bytes32 ruleGroupName, uint256 version, bytes32 ruleName);
    event UnLinkRule(address origin, address sender, bytes32 ruleGroupName, uint256 version, bytes32 ruleName);

    event ClaimERC20Token(address origin, address sender, address token, address receiver, uint256 amount);
    event SetGasCompensationPercent(address origin, address sender, uint256 authorPercent, uint256 ownerPercent);
    event SetPrice(address origin, address sender, DataTypes.PaymentType paymentType, uint256 newPrice);

    function initialize(
        string memory _name,
        address _registry,
        address _creator,
        bool _isInitial
    ) external initializer {
        _transferOwnership(_creator);
        name = _name;
        registry = IRegistry(_registry);
        creator = _creator;
        if (_isInitial) {
            setInitialPlugins();
        }
        creatingTime = block.timestamp;
    }

    function linkPlugin(bytes32 _pluginName, uint256 _version) external override onlyOwner {
        require(registry.isEnablePlugin(_pluginName, _version), "Community: wrong plugin");
        linkedPlugins[_pluginName][_version] = true;
        emit LinkPlugin(tx.origin, _msgSender(), _pluginName, _version);
    }

    function unLinkPlugin(bytes32 _pluginName, uint256 _version) external override onlyOwner {
        linkedPlugins[_pluginName][_version] = false;
        emit UnLinkPlugin(tx.origin, _msgSender(), _pluginName, _version);
    }

    function isLinkedPlugin(bytes32 _pluginName, uint256 _version) external view override returns (bool) {
        return linkedPlugins[_pluginName][_version];
    }

    function claimERC20Token(IERC20 _token, address _receiver, uint256 _amount) external override onlyOwner {
        require(_token.transfer(_receiver, _amount), "Community: token transfer error");
        emit ClaimERC20Token(tx.origin, _msgSender(), address(_token), _receiver, _amount);
    }

    function linkRule(bytes32 _ruleGroupName, uint256 _version, bytes32 _ruleName) external override onlyOwner {
        require(
            IRule(registry.rule()).isSupportedRule(_ruleGroupName, _version, _ruleName),
                "Community: wrong rule"
        );
        linkedRules[_ruleGroupName][_version][_ruleName] = true;
        emit LinkRule(tx.origin, _msgSender(), _ruleGroupName, _version, _ruleName);
    }

    function unLinkRule(bytes32 _ruleGroupName, uint256 _version, bytes32 _ruleName) external override onlyOwner {
        linkedRules[_ruleGroupName][_version][_ruleName] = false;
        emit UnLinkRule(tx.origin, _msgSender(), _ruleGroupName, _version, _ruleName);
    }

    function isLinkedRule(bytes32 _ruleGroupName, uint256 _version, bytes32 _ruleName) external view override returns (bool) {
        return linkedRules[_ruleGroupName][_version][_ruleName];
    }

    function setGasCompensationPercent(uint256 _authorPercent) external override onlyOwner {
        require(_authorPercent <= ALL_PERCENT, "Community: wrong percent");
        authorGasCompensationPercent = _authorPercent;
        ownerGasCompensationPercent = ALL_PERCENT - _authorPercent;
        emit SetGasCompensationPercent(tx.origin, _msgSender(), authorGasCompensationPercent, ownerGasCompensationPercent);
    }

    function setPrice(DataTypes.PaymentType _paymentType, uint256 _newPrice) external override onlyOwner {
        price[_paymentType] = _newPrice;
        emit SetPrice(tx.origin, _msgSender(), _paymentType, _newPrice);
    }

    function getPrice(DataTypes.PaymentType _paymentType) external override view returns (uint256) {
        return price[_paymentType];
    }

    function setInitialPlugins() private {
        linkedPlugins[PluginsList.COMMUNITY_JOIN][INITIAL_PLUGINS_VERSION] = true;
        linkedPlugins[PluginsList.COMMUNITY_QUIT][INITIAL_PLUGINS_VERSION] = true;
        linkedPlugins[PluginsList.COMMUNITY_INFO][INITIAL_PLUGINS_VERSION] = true;
        linkedPlugins[PluginsList.COMMUNITY_READ_POST][INITIAL_PLUGINS_VERSION] = true;
        linkedPlugins[PluginsList.COMMUNITY_WRITE_POST][INITIAL_PLUGINS_VERSION] = true;
        linkedPlugins[PluginsList.COMMUNITY_BURN_POST][INITIAL_PLUGINS_VERSION] = true;
        linkedPlugins[PluginsList.COMMUNITY_READ_COMMENT][INITIAL_PLUGINS_VERSION] = true;
        linkedPlugins[PluginsList.COMMUNITY_WRITE_COMMENT][INITIAL_PLUGINS_VERSION] = true;
        linkedPlugins[PluginsList.COMMUNITY_BURN_COMMENT][INITIAL_PLUGINS_VERSION] = true;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../../libraries/DataTypes.sol";


interface ICommunityBlank {

    function creator() external view returns (address);

    function name() external view returns (string memory);

    function creatingTime() external view returns (uint256);

    function authorGasCompensationPercent() external view returns (uint256);

    function ownerGasCompensationPercent() external view returns (uint256);

    function linkPlugin(bytes32 _pluginName, uint256 _version) external;

    function unLinkPlugin(bytes32 _pluginName, uint256 _version) external;

    function isLinkedPlugin(bytes32 _pluginName, uint256 _version) external view returns (bool);

    function linkRule(bytes32 _ruleGroupName, uint256 _version, bytes32 _ruleName) external;

    function unLinkRule(bytes32 _ruleGroupName, uint256 _version, bytes32 _ruleName) external;

    function isLinkedRule(bytes32 _ruleGroupName, uint256 _version, bytes32 _ruleName) external view returns (bool);

    function claimERC20Token(IERC20 _token, address _receiver, uint256 _amount) external;

    function setGasCompensationPercent(uint256 _authorPercent) external;

    function setPrice(DataTypes.PaymentType _paymentType, uint256 _newPrice) external;

    function getPrice(DataTypes.PaymentType _paymentType) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";


library DataTypes {

    struct PostInfo {
        address creator;
        address currentOwner;
        address communityId;
        address repostFromCommunity;
        uint256 upCount;
        uint256 downCount;
        uint256 commentCount;
        uint256 encodingType;
        uint256 timestamp;
        uint256 gasConsumption;
        bool isView;
        bool isEncrypted;
        bool isGasCompensation;
        string ipfsHash;
        string category;
        string[] tags;
    }

    struct CommentInfo {
        address creator;
        address owner;
        address communityId;
        uint256 timestamp;
        uint256 gasConsumption;
        bool up;
        bool down;
        bool isView;
        bool isEncrypted;
        bool isGasCompensation;
        string ipfsHash;
    }

    struct CommunityInfo {
        string name;
        address creator;
        address owner;
        uint256 creatingTime;
        uint256[] postIds;
        address[] normalUsers;
        address[] bannedUsers;
        address[] moderators;
    }

    enum UserRatesType {
        RESERVE, FOR_POST, FOR_COMMENT, FOR_UP, FOR_DOWN,
        FOR_DEAL_GUARANTOR, FOR_DEAL_SELLER, FOR_DEAL_BUYER
    }

    enum PaymentType {
        RESERVE, FOR_COMMUNITY_JOIN, FOR_PERIODIC_ACCESS, FOR_ADS, FOR_MAKE_CONTENT
    }

    struct MinSimpleVars {
        bytes32 pluginName;
        uint256 version;
        bytes data;
    }

    struct SimpleVars {
        bytes32 executedId;
        bytes32 pluginName;
        uint256 version;
        bytes data;
    }

    struct GeneralVars {
        bytes32 executedId;
        bytes32 pluginName;
        uint256 version;
        address user;
        bytes data;
    }

    struct SoulBoundMint {
        bytes32 executedId;
        bytes32 pluginName;
        uint256 version;
        address user;
        uint256 id;
        uint256 amount;
    }

    struct SoulBoundBatchMint {
        bytes32 executedId;
        bytes32 pluginName;
        uint256 version;
        address user;
        uint256[] ids;
        uint256[] amounts;
    }

    struct UserRateCount {
        uint256 commentCount;
        uint256 postCount;
        uint256 upCount;
        uint256 downCount;
    }

    struct GasCompensationComment {
        bytes32 executedId;
        bytes32 pluginName;
        uint256 version;
        uint256 postId;
        uint256 commentId;
    }

    struct GasCompensationBank {
        bytes32 executedId;
        bytes32 pluginName;
        uint256 version;
        address user;
        uint256 gas;
    }

    struct PaymentInfo {
        uint256 startTime;
        uint256 endTime;
        address communityId;
        address owner;
        DataTypes.PaymentType paymentType;
    }

    struct DealMessage {
        string message;
        address sender;
        uint256 writeTime;
    }

    struct SafeDeal {
        string description;
        address seller;
        address buyer;
        address guarantor;
        uint256 amount;
        uint256 startTime;
        uint256 endTime;
        bool startSellerApprove;
        bool startBuyerApprove;
        bool endSellerApprove;
        bool endBuyerApprove;
        bool isIssue;
        bool isFinished;
        DealMessage[] messages;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

/// @title Contract of Page.PluginsList
/// @notice This contract contains a list of plugin names.
/// @dev Constants from this list are used to access plugins settings.
library PluginsList {

    bytes32 public constant COMMUNITY_CREATE = keccak256(abi.encode("COMMUNITY_CREATE"));
    bytes32 public constant COMMUNITY_JOIN = keccak256(abi.encode("COMMUNITY_JOIN"));
    bytes32 public constant COMMUNITY_QUIT = keccak256(abi.encode("COMMUNITY_QUIT"));
    bytes32 public constant COMMUNITY_INFO = keccak256(abi.encode("COMMUNITY_INFO"));
    bytes32 public constant COMMUNITY_PROFIT = keccak256(abi.encode("COMMUNITY_PROFIT"));

    bytes32 public constant USER_INFO_ONE_COMMUNITY = keccak256(abi.encode("USER_INFO_ONE_COMMUNITY"));
    bytes32 public constant USER_INFO_ALL_COMMUNITIES = keccak256(abi.encode("USER_INFO_ALL_COMMUNITIES"));

    bytes32 public constant COMMUNITY_WRITE_POST = keccak256(abi.encode("COMMUNITY_WRITE_POST"));
    bytes32 public constant COMMUNITY_READ_POST = keccak256(abi.encode("COMMUNITY_READ_POST"));
    bytes32 public constant COMMUNITY_BURN_POST = keccak256(abi.encode("COMMUNITY_BURN_POST"));
    bytes32 public constant COMMUNITY_TRANSFER_POST = keccak256(abi.encode("COMMUNITY_TRANSFER_POST"));
    bytes32 public constant COMMUNITY_CHANGE_VISIBILITY_POST = keccak256(abi.encode("COMMUNITY_CHANGE_VISIBILITY_POST"));
    bytes32 public constant COMMUNITY_POST_GAS_COMPENSATION = keccak256(abi.encode("COMMUNITY_POST_GAS_COMPENSATION"));
    bytes32 public constant COMMUNITY_EDIT_MODERATORS = keccak256(abi.encode("COMMUNITY_EDIT_MODERATORS"));
    bytes32 public constant COMMUNITY_REPOST = keccak256(abi.encode("COMMUNITY_REPOST"));

    bytes32 public constant COMMUNITY_WRITE_COMMENT = keccak256(abi.encode("COMMUNITY_WRITE_COMMENT"));
    bytes32 public constant COMMUNITY_READ_COMMENT = keccak256(abi.encode("COMMUNITY_READ_COMMENT"));
    bytes32 public constant COMMUNITY_BURN_COMMENT = keccak256(abi.encode("COMMUNITY_BURN_COMMENT"));
    bytes32 public constant COMMUNITY_CHANGE_VISIBILITY_COMMENT = keccak256(abi.encode("COMMUNITY_CHANGE_VISIBILITY_COMMENT"));
    bytes32 public constant COMMUNITY_COMMENT_GAS_COMPENSATION = keccak256(abi.encode("COMMUNITY_COMMENT_GAS_COMPENSATION"));

    bytes32 public constant BANK_DEPOSIT = keccak256(abi.encode("BANK_DEPOSIT"));
    bytes32 public constant BANK_WITHDRAW = keccak256(abi.encode("BANK_WITHDRAW"));
    bytes32 public constant BANK_BALANCE_OF = keccak256(abi.encode("BANK_BALANCE_OF"));

    bytes32 public constant SOULBOUND_GENERATE = keccak256(abi.encode("SOULBOUND_GENERATE"));
    bytes32 public constant SOULBOUND_BALANCE_OF = keccak256(abi.encode("SOULBOUND_BALANCE_OF"));

    bytes32 public constant SUBSCRIPTION_BUY = keccak256(abi.encode("SUBSCRIPTION_BUY"));
    bytes32 public constant SUBSCRIPTION_INFO = keccak256(abi.encode("SUBSCRIPTION_INFO"));

    bytes32 public constant SAFE_DEAL_MAKE = keccak256(abi.encode("SAFE_DEAL_MAKE"));
    bytes32 public constant SAFE_DEAL_READ = keccak256(abi.encode("SAFE_DEAL_READ"));
    bytes32 public constant SAFE_DEAL_CANCEL = keccak256(abi.encode("SAFE_DEAL_CANCEL"));
    bytes32 public constant SAFE_DEAL_FINISH = keccak256(abi.encode("SAFE_DEAL_FINISH"));
    bytes32 public constant SAFE_DEAL_ADD_MESSAGE = keccak256(abi.encode("SAFE_DEAL_ADD_MESSAGE"));
    bytes32 public constant SAFE_DEAL_SET_ISSUE = keccak256(abi.encode("SAFE_DEAL_SET_ISSUE"));
    bytes32 public constant SAFE_DEAL_CLEAR_ISSUE = keccak256(abi.encode("SAFE_DEAL_CLEAR_ISSUE"));
    bytes32 public constant SAFE_DEAL_SET_APPROVE = keccak256(abi.encode("SAFE_DEAL_SET_APPROVE"));
    bytes32 public constant SAFE_DEAL_CHANGE_TIME = keccak256(abi.encode("SAFE_DEAL_CHANGE_TIME"));
    bytes32 public constant SAFE_DEAL_CHANGE_DESCRIPTION = keccak256(abi.encode("SAFE_DEAL_CHANGE_DESCRIPTION"));

    function version() external pure returns (string memory) {
        return "1";
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

interface IRegistry {

    function version() external pure returns (string memory);

    function bank() external view returns (address);

    function oracle() external view returns (address);

    function uniV3Pool() external view returns (address);

    function token() external view returns (address);

    function dao() external view returns (address);

    function treasury() external view returns (address);

    function executor() external view returns (address);

    function rule() external view returns (address);

    function communityData() external view returns (address);

    function postData() external view returns (address);

    function commentData() external view returns (address);

    function account() external view returns (address);

    function soulBound() external view returns (address);

    function subscription() external view returns (address);

    function nft() external view returns (address);

    function safeDeal() external view returns (address);

    function profitDistribution() external view returns (address);

    function superAdmin() external view returns (address);

    function setBank(address _contract) external;

    function setToken(address _contract) external;

    function setOracle(address _contract) external;

    function setUniV3Pool(address _contract) external;

    function setExecutor(address _executor) external;

    function setCommunityData(address _contract) external;

    function setPostData(address _contract) external;

    function setCommentData(address _contract) external;

    function setAccount(address _contract) external;

    function setSoulBound(address _contract) external;

    function setSubscription(address _contract) external;

    function setProfitDistribution(address _contract) external;

    function setRule(address _contract) external;

    function setNFT(address _contract) external;

    function setSafeDeal(address _contract) external;

    function setSuperAdmin(address _user) external;

    function setVotingContract(address _contract, bool _status) external;

    function setPlugin(
        bytes32 _pluginName,
        uint256 _version,
        address _pluginContract
    ) external;

    function changePluginStatus(
        bytes32 _pluginName,
        uint256 _version
    ) external;

    function getPlugin(
        bytes32 _pluginName,
        uint256 _version
    ) external view returns (bool enable, address pluginContract);

    function getPluginContract(
        bytes32 _pluginName,
        uint256 _version
    ) external view returns (address pluginContract);

    function isEnablePlugin(
        bytes32 _pluginName,
        uint256 _version
    ) external view returns (bool enable);

    function isVotingContract(
        address _contract
    ) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;


interface IRule {

    function version() external pure returns (string memory);

    function setRuleContract(bytes32 _ruleGroupName, uint256 _version, address _ruleContract) external;

    function enableRule(bytes32 _ruleGroupName, uint256 _version, bytes32 _ruleName) external;

    function disableRule(bytes32 _ruleGroupName, uint256 _version, bytes32 _ruleName) external;

    function isSupportedRule(
        bytes32 _ruleGroupName,
        uint256 _version,
        bytes32 _ruleName
    ) external view returns (bool);

    function getRuleContract(
        bytes32 _ruleGroupName,
        uint256 _version
    ) external view returns (address);

}