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
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Tree proofs.
 *
 * The tree and the proofs can be generated using our
 * https://github.com/OpenZeppelin/merkle-tree[JavaScript library].
 * You will find a quickstart guide in the readme.
 *
 * WARNING: You should avoid using leaf values that are 64 bytes long prior to
 * hashing, or use a hash function other than keccak256 for hashing leaves.
 * This is because the concatenation of a sorted pair of internal nodes in
 * the merkle tree could be reinterpreted as a leaf value.
 * OpenZeppelin's JavaScript library generates merkle trees that are safe
 * against this attack out of the box.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Calldata version of {verify}
     *
     * _Available since v4.7._
     */
    function verifyCalldata(
        bytes32[] calldata proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProofCalldata(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merkle tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Calldata version of {processProof}
     *
     * _Available since v4.7._
     */
    function processProofCalldata(bytes32[] calldata proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Returns true if the `leaves` can be simultaneously proven to be a part of a merkle tree defined by
     * `root`, according to `proof` and `proofFlags` as described in {processMultiProof}.
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function multiProofVerify(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProof(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Calldata version of {multiProofVerify}
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function multiProofVerifyCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProofCalldata(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Returns the root of a tree reconstructed from `leaves` and sibling nodes in `proof`. The reconstruction
     * proceeds by incrementally reconstructing all inner nodes by combining a leaf/inner node with either another
     * leaf/inner node or a proof sibling node, depending on whether each `proofFlags` item is true or false
     * respectively.
     *
     * CAUTION: Not all merkle trees admit multiproofs. To use multiproofs, it is sufficient to ensure that: 1) the tree
     * is complete (but not necessarily perfect), 2) the leaves to be proven are in the opposite order they are in the
     * tree (i.e., as seen from right to left starting at the deepest layer and continuing at the next layer).
     *
     * _Available since v4.7._
     */
    function processMultiProof(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    /**
     * @dev Calldata version of {processMultiProof}.
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function processMultiProofCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    function _hashPair(bytes32 a, bytes32 b) private pure returns (bytes32) {
        return a < b ? _efficientHash(a, b) : _efficientHash(b, a);
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract EIP712BaseUpgradeable is Initializable {
    struct EIP712Domain {
        string name;
        string version;
        address verifyingContract;
        bytes32 salt;
    }

    bytes32 internal constant EIP712_DOMAIN_TYPEHASH =
        keccak256(bytes("EIP712Domain(string name,string version,address verifyingContract,bytes32 salt)"));

    bytes32 internal domainSeparator;

    function _initialize(string memory name, string memory version) internal virtual onlyInitializing {
        domainSeparator = keccak256(
            abi.encode(
                EIP712_DOMAIN_TYPEHASH,
                keccak256(bytes(name)),
                keccak256(bytes(version)),
                address(this),
                bytes32(getChainID())
            )
        );
    }

    function getChainID() internal view returns (uint256 id) {
        assembly {
            id := chainid()
        }
    }

    function getDomainSeparator() public view returns (bytes32) {
        return domainSeparator;
    }

    /**
     * Accept message hash and returns hash message in EIP712 compatible form
     * So that it can be used to recover signer from signature signed using EIP712 formatted data
     * https://eips.ethereum.org/EIPS/eip-712
     * "\\x19" makes the encoding deterministic
     * "\\x01" is the version byte to make it compatible to EIP-191
     */
    function toTypedMessageHash(bytes32 messageHash) internal view returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", getDomainSeparator(), messageHash));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {EIP712BaseUpgradeable} from "./EIP712BaseUpgradeable.sol";

/**
@title Interface to enable MetaTransactions
 */
contract EIP712MetaTransactionUpgradeable is Initializable, EIP712BaseUpgradeable {
    bytes32 private constant META_TRANSACTION_TYPEHASH =
        keccak256(bytes("MetaTransaction(uint256 nonce,address from,bytes functionSignature)"));

    event MetaTransactionExecuted(address userAddress, address payable relayerAddress, bytes functionSignature);
    mapping(address => uint256) private nonces;

    /*
     * Meta transaction structure.
     * No point of including value field here as if user is doing value transfer then he has the funds to pay for gas
     * He should call the desired function directly in that case.
     */
    struct MetaTransaction {
        uint256 nonce;
        address from;
        bytes functionSignature;
    }

    function __EIP712MetaTransactionUpgradeable_init(string memory name_, string memory version)
        internal
        onlyInitializing
    {
        __EIP712MetaTransactionUpgradeable_init_unchained(name_, version);
    }

    function __EIP712MetaTransactionUpgradeable_init_unchained(string memory name_, string memory version)
        internal
        onlyInitializing
    {
        EIP712BaseUpgradeable._initialize(name_, version);
    }

    function convertBytesToBytes4(bytes memory inBytes) internal pure returns (bytes4 outBytes4) {
        if (inBytes.length == 0) {
            return 0x0;
        }

        assembly {
            outBytes4 := mload(add(inBytes, 32))
        }
    }

    function executeMetaTransaction(
        address userAddress,
        bytes memory functionSignature,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) external payable returns (bytes memory) {
        MetaTransaction memory metaTx = MetaTransaction(nonces[userAddress], userAddress, functionSignature);

        require(
            verify(userAddress, metaTx, sigR, sigS, sigV),
            "EIP712MetaTransaction: Signer and signature do not match"
        );

        // increase nonce for user (to avoid re-use)
        nonces[userAddress]++;

        // Append userAddress and relayer address at the end to extract it from calling context
        (bool success, bytes memory returnData) = address(this).call(abi.encodePacked(functionSignature, userAddress));
        
        require(success, "Function call not successful");

        emit MetaTransactionExecuted(userAddress, payable(msg.sender), functionSignature);
        
        return returnData;
    }

    function hashMetaTransaction(MetaTransaction memory metaTx) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(META_TRANSACTION_TYPEHASH, metaTx.nonce, metaTx.from, keccak256(metaTx.functionSignature))
            );
    }

    function getNonce(address user) external view returns (uint256 nonce) {
        nonce = nonces[user];
    }

    function verify(
        address user,
        MetaTransaction memory metaTx,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) internal view returns (bool) {
        address signer = ecrecover(toTypedMessageHash(hashMetaTransaction(metaTx)), sigV, sigR, sigS);
        require(signer != address(0), "Invalid signature");
        return signer == user;
    }

    function msgSender() internal view returns (address sender) {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
                // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender := and(mload(add(array, index)), 0xffffffffffffffffffffffffffffffffffffffff)
            }
        } else {
            sender = msg.sender;
        }
        return sender;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

import { MerkleProof } from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import { IMerkleVerifier } from "../interfaces/IMerkleVerifier.sol";

/**
 * @dev Contract module which allows children to implement a merkle tree
 * verification system.
 *
 * This module is used through inheritance. 
 *  
 */
abstract contract MerkleVerifier is IMerkleVerifier {
    bytes32 public merkleRoot;

    /**
     * @dev Modifier to check proof and value validity
     */
    modifier validMerkleProof(
        bytes32[] calldata proof,
        bytes32 valueToProve
    ) {
        require(merkleRoot != "", "Root not set");
        require(
            verifyMerkleProof(
                proof,
                valueToProve
            ),
            "Not approved"
        );
        _;
    }

    /**
    @notice Sets the Merkle Tree root value
    @param _merkleRoot The merkle tree root
    */
    function _setMerkleRoot(bytes32 _merkleRoot) internal virtual {
        merkleRoot = _merkleRoot;
    }

    /**
    @notice Verifies the proof is valid for the current root
    @param proof The generated proof for the current merkle tree
    @param valueToProve The value to verifiy exists in the tree
    */
    function verifyMerkleProof(bytes32[] calldata proof, bytes32 valueToProve)
        public
        virtual
        view
        returns (bool)
    {
        bool verified = MerkleProof.verifyCalldata(proof, merkleRoot, valueToProve);
        return verified;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

import { IPausable } from "../interfaces/IPausable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`
 * 
 * This is a modified version of the the OpenZeppelin Pausable.sol contract
 * 
 */
abstract contract Pausable is IPausable {
    bool internal _paused;

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!_paused, "Execution is paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(_paused, "Execution is not paused");
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() external view virtual returns (bool) {
        return _paused;
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import { IMintable } from "../IMintable.sol";
import { IPriceWithERC20 } from "../IPriceWithERC20.sol";

/**
 *  Public NFT minting with ERC20 token 
 *  Must obatin token spending approval before mintWithErc20 execution.
 */
interface IMintableWithERC20 is IMintable, IPriceWithERC20 {
    /**
    @notice Implements ERC721 token minting.
    @param erc20Address ERC20 contract address.
    */
    function mintWithErc20(address erc20Address) external;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/**
 *  ERC20 token transfer to a specified address.
 */
interface IPriceWithERC20Payer {
    /* 
    @notice Emitted when ERC20 tokens are withdrawn to an address.
    @param erc20Address ERC20 contract address.
    @param recipient The recpient address to receive the ERC20 tokens.
    @param amount The amount to withdraw.
    */
    event WithdrawERC20ToAddress(address indexed erc20Address, address indexed recipient, uint256 amount);
    
    /**
    @notice Withdraws ERC20 tokens to an address.
    @notice MUST be a secured function. 
    @param erc20Address ERC20 contract address.
    @param amount The amount to withdraw.
    */
    function withdrawErc20ToPayee(address erc20Address, uint256 amount) external;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/**
 *  Merkle tree verifier contract.  
 */
interface IMerkleVerifier { 
    /**
     * @dev Virifies a value given a proof
     *
     */
    function verifyMerkleProof(bytes32[] calldata proof, bytes32 valueToProve) external returns (bool);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/**
 *  Public NFT minting with native token 
 */
interface IMintable {
    /// @dev Emitted when tokens are minted via `mint`
    event Mint(address indexed receiver, uint256 indexed tokenId, string data);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/**
 *  Pauseable contract.  
 */
interface IPausable { 
    /**
     * @dev Triggers stopped state.
     *
     */
    function pause() external;

    /**
     * @dev Returns to normal state.
     *
     */
    function unpause() external;

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() external view returns (bool);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/**
 *  Public NFT minting with ERC20 token 
 *  Common functions for contracts minting with ERC20 tokens
 */
interface IPriceWithERC20 {
    /* 
    @notice Emitted when ERC20 tokens are withdrawn to an address.
    @param erc20Address ERC20 contract address.
    @param recipient The recpient address to receive the ERC20 tokens.
    @param amount The amount to withdraw.
    */
    event WithdrawERC20(address indexed erc20Address, address indexed recipient, uint256 amount);
    
    /**
    @notice Gets the ERC20 mint price
    @param erc20Address The ERC20 contract address
    */
    function getErc20MintPrice(address erc20Address) external view returns (uint256); 

    /**
    @notice Sets the ERC20 price we charge for mints 
    @notice MUST be a secured function. 
    @param erc20Address ERC20 contract address.
    @param price_ Representing the new price.
    */
    function setErc20MintPrice(address erc20Address, uint256 price_) external;

    /**
    @notice Withdraws ERC20 tokens to the executing account
    @notice MUST be a secured function. 
    @param erc20Address ERC20 contract address.
    @param amount The amount to withdraw.
    */
    function withdrawErc20(address erc20Address, uint256 amount) external;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import { IMintable } from "./IMintable.sol";
import { IPriceWithERC20 } from "./IPriceWithERC20.sol";
import { IMerkleVerifier } from "./IMerkleVerifier.sol";

/**
 *  Public NFT minting with ERC20 token 
 *  Must obatin token spending approval before mintWithErc20 execution.
 */
interface IWhiteListMintableWithERC20 is IMintable, IPriceWithERC20, IMerkleVerifier {
    /**
    @notice Implements ERC721 token minting.
    @param erc20Address ERC20 contract address.
    @param proof The generated proof for the current merkle tree
    */
    function whiteListMintWithErc20(address erc20Address, bytes32[] calldata proof) external;
}

// SPDX-FileCopyrightText: © 2022 Virtually Human Studio

// SPDX-License-Identifier: No-license

pragma solidity 0.8.11;

interface ISkin {
    function names(uint256 tokenId) external view returns (string calldata);
    function ownerOf(uint256 tokenId) external view returns (address);
    function mint(address to, string calldata skinName) external;
}

// SPDX-FileCopyrightText: © 2023 Virtually Human Studio

// SPDX-License-Identifier: No-license

pragma solidity 0.8.11;

import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { ReentrancyGuardUpgradeable } from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { EIP712MetaTransactionUpgradeable } from "../base/EIP712/EIP712MetaTransactionUpgradeable.sol";

import { ISkin } from "../VHS/cryptofield-core/contracts/interfaces/ISkin.sol";

import { MerkleVerifier } from "../base/MerkleVerifier.sol" ;
import { Pausable } from "../base/Pausable.sol";
import { IWhiteListMintableWithERC20 } from "../interfaces/IWhiteListMintableWithERC20.sol";
import { IMintableWithERC20 } from "../interfaces/extensions/IMintableWithERC20.sol";
import { IPriceWithERC20Payer } from "../interfaces/extensions/IPriceWithERC20Payer.sol";

contract ZedSkinMinter is 
    Initializable, 
    EIP712MetaTransactionUpgradeable,
    OwnableUpgradeable, 
    ReentrancyGuardUpgradeable,
    MerkleVerifier, 
    Pausable,
    IWhiteListMintableWithERC20,
    IMintableWithERC20,
    IPriceWithERC20Payer
{
    /// @notice ZED Skin Contract
    ISkin private _skin;

    /// @notice Allow list sale open flag
    bool public allowListSaleOpen;

    /// @notice Public sale open flag
    bool public publicSaleOpen;

    /// @notice Is the allow list a free mint
    bool public isAllowListSaleFreeMint;

    /// @notice Is the public sale a free mint
    bool public isPublicSaleFreeMint;

    /// @notice Alow list maximum supply
    uint256 public allowListSaleMaxSupply;
    
    /// @notice Public sale maximum supply
    uint256 public publicSaleMaxSupply;

    /// @notice Maximum tokens per wallet for the allow list sale
    uint256 public allowListSaleAddressMax;

    /// @notice Maximum tokens per wallet for the public sale
    uint256 public publicSaleAddressMax;

    /// @notice The number of skins minted from the alow list
    uint256 public allowListMintCount;

    /// @notice The number of skins minted from the public sale
    uint256 public publicSaleMintCount;

    /// @notice The address of the payee for non owner withdrawals
    address public payee;

    /// @notice The Skin name
    string public skinName;

    /// @notice Mapping from price to an ERC20 address
    mapping(address => uint256) private _prices;

    /// @notice Number of allow list tokens minted to an address
    mapping(address => uint256) public addressToAllowListMintCount;

    /// @notice Number of public list tokens minted to an address
    mapping(address => uint256) public addressToPublicSaleMintCount;

    /// @notice Emitted when the skin name is set
    event SetSkinName(address indexed settor, string name);

    /// @notice Emitted when an ERC20 price is set
    event SetErc20MintPrice(address indexed settor, address erc20Address, uint256 price);

    /// @notice Emitted when allow list sale open state is set
    event SetAllowListSaleOpen(address indexed settor, bool isOpen);

    /// @notice Emitted when public sale open state is set
    event SetPublicSaleOpen(address indexed settor, bool isOpen);

    /// @notice Emitted when allow list sale free mint valule set
    event SetIsAllowListSaleFreeMint(address indexed settor, bool isAllowListSaleFreeMint);

    /// @notice Emitted when public sale free mint valule set
    event SetIsPublicSaleFreeMint(address indexed settor, bool isAllowListSaleFreeMint);

    /// @notice Emitted when the allow list sale mint count has been set
    event SetAllowListMintCount(address indexed settor, uint256 oldMintCount, uint256 newMintCount);

    /// @notice Emitted when the public sale mint count has been set
    event SetPublicSaleMintCount(address indexed settor, uint256 oldMintCount, uint256 newMintCount);

    /// @notice Emitted when the payee is set
    event SetPayee(address indexed settor, address payee);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address skinContractAddress) initializer external {
        __EIP712MetaTransactionUpgradeable_init("ZED Skin Minter", "1");
        __Ownable_init();

        _skin = ISkin(skinContractAddress);

        // default values
        allowListSaleAddressMax = 1;
        publicSaleAddressMax = 1;
    }

    /**
     * @dev We want to support meta transactions so we need to make sure that the logic applied by the
     * EIP712MetaTransactionUpgradeable.msgSender() function is used instead of the _msgSender() one.
     */
    function _msgSender() internal view override returns (address sender) {
        return EIP712MetaTransactionUpgradeable.msgSender();
    }

    /**
     * @dev Sets the skin name.
     * @param skinName_ The skin name.
     */
    function setSkinName(string calldata skinName_) external onlyOwner {
        skinName = skinName_;

        emit SetSkinName(_msgSender(), skinName);
    }

    /**
     * @dev Sets the merkle tree root for the allow list.
     * @param merkleRoot_ The merkle tree root.
     */
    function setMerkleRoot(bytes32 merkleRoot_) external onlyOwner {
        _setMerkleRoot(merkleRoot_);
    }

    /**
     * @dev Sets the maximum supply for the allow list mint.
     * @param maxSupply The maximum supply.
     */
    function setAllowListSaleMaxSupply(uint256 maxSupply) external onlyOwner {
        require(maxSupply > allowListMintCount, "Max supply must be greater than mint count");

        allowListSaleMaxSupply = maxSupply;
    }

    /**
     * @dev Sets the maximum supply for the public sale mint.
     * @param maxSupply The maximum supply.
     */
    function setPublicSaleMaxSupply(uint256 maxSupply) external onlyOwner {
        require(maxSupply > publicSaleMintCount, "Max supply must be greater than mint count");

        publicSaleMaxSupply = maxSupply;
    }

    /**
     * @dev Sets allow list sale open flag.
     * @param isOpen The open flag.
     */
    function setAllowListSaleOpen(bool isOpen) external onlyOwner {
        allowListSaleOpen = isOpen;

        emit SetAllowListSaleOpen(_msgSender(), isOpen);
    }

    /**
     * @dev Sets the public sale open flag.
     * @param isOpen The open flag.     
     */
    function setPublicSaleOpen(bool isOpen) external onlyOwner {
        publicSaleOpen = isOpen;

        emit SetPublicSaleOpen(_msgSender(), isOpen);
    }

    /**
     * @dev Allows resetting the allow list mint count for new skins.
     * @param mintCount The new mint count.
     */
    function setAllowListMintCount(uint256 mintCount) external onlyOwner {
        require(_paused, "Contract must be paused");
        require(!allowListSaleOpen, "Allow list sale must be closed");

        uint256 currentMintCount = allowListMintCount;
        allowListMintCount = mintCount;

        emit SetAllowListMintCount(_msgSender(), currentMintCount, mintCount);
    }

    /**
     * @dev Allows resetting the public sale mint count for new skins.
     * @param mintCount The new mint count.
     */
    function setPublicSaleMintCount(uint256 mintCount) external onlyOwner {
        require(_paused, "Contract must be paused");
        require(!publicSaleOpen, "Public sale must be closed");

        uint256 currentMintCount = publicSaleMintCount;
        publicSaleMintCount = mintCount;

        emit SetPublicSaleMintCount(_msgSender(), currentMintCount, mintCount);
    }

    /**
     * @dev Sets the payee for wthdrawals to an address.
     * @param payee_ The payee address.
     */
    function setPayee(address payee_) external onlyOwner {
        payee = payee_;

        emit SetPayee(_msgSender(), payee_);
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function pause() external onlyOwner {
        _paused = true;
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function unpause() external onlyOwner {
        _paused = false;
    }

    /**
     * @dev Sets the maximum number of tokens that can be minted per adddress in the alow list sale.
     * @param maxTokens The maximum number of tokens.
     */
    function setAllowListSaleAddressMax(uint256 maxTokens) external onlyOwner {
        allowListSaleAddressMax = maxTokens;
    }

    /**
     * @dev Sets the maximum number of tokens that can be minted per address in the public sale.
     * @param maxTokens The maximum number of tokens.
     */
    function setPublicSaleAddressMax(uint256 maxTokens) external onlyOwner {
        publicSaleAddressMax = maxTokens;
    }

    /**
    @notice Gets the ERC20 mint price
    @param erc20Address The ERC20 contract address
    */
    function getErc20MintPrice(address erc20Address) external virtual view returns (uint256) {
        return _prices[erc20Address];
    } 

    /**
    @dev Sets the ERC20 price we charge for mints
    @param erc20Address The ERC20 contract address
    @param price Representing the new price
    */
    function setErc20MintPrice(address erc20Address, uint256 price) external virtual onlyOwner {
        _prices[erc20Address] = price;

        emit SetErc20MintPrice(_msgSender(), erc20Address, price);
    }

    /**
    @dev Sets the allow list mint count for a wallet
    @param owner_ The token owner address
    @param count The new mint count value
    */
    function setAddressAllowListMintCount(address owner_, uint256 count) external onlyOwner {
        addressToAllowListMintCount[owner_] = count;
    }

    /**
    @dev Sets the public mint count for a wallet
    @param owner_ The token owner address
    @param count The new mint count value
    */
    function setAddressPublicSaleMintCount(address owner_, uint256 count) external onlyOwner {
        addressToPublicSaleMintCount[owner_] = count;
    }

    /**
    @dev Sets whether the allow list sale is a free mint
    @param isFreeMint Is it a free mint
    */
    function setIsAllowListSaleFreeMint(bool isFreeMint) external onlyOwner {
        isAllowListSaleFreeMint = isFreeMint;

        emit SetIsAllowListSaleFreeMint(_msgSender(), isFreeMint);
    }

    /**
    @dev Sets whether the public sale is a free mint
    @param isFreeMint Is it a free mint
    */
    function setIsPublicSaleFreeMint(bool isFreeMint) external onlyOwner {
        isPublicSaleFreeMint = isFreeMint;

        emit SetIsPublicSaleFreeMint(_msgSender(), isFreeMint);
    }

    /**
     * @dev Gets the total number of skins minted by this contract
     */
    function totalSupply() external view returns(uint256){
        return allowListMintCount + publicSaleMintCount;
    }

    /**
    @notice Implements ERC721 token minting verifying from the allow list.
    @param erc20Address ERC20 contract address. Pass address(0) for free minting.
    @param allowListProof The generated proof for the current merkle tree.
    */
    function whiteListMintWithErc20(address erc20Address, bytes32[] calldata allowListProof) 
        external 
        whenNotPaused
        nonReentrant        
        validMerkleProof(allowListProof, keccak256(abi.encodePacked(_msgSender())))
    {   
        require(allowListSaleOpen, "Allow list sale not open");

        uint256 newCount = allowListMintCount;
        require(allowListSaleMaxSupply == 0 || newCount < allowListSaleMaxSupply, "Allow list sold out");
        
        uint256 addressMintCount = addressToAllowListMintCount[_msgSender()];
        require(allowListSaleAddressMax == 0 || addressMintCount < allowListSaleAddressMax, "Allow list maximum purchases reached");

        // Overflow unrealistic
        unchecked {
            // Set new values before minting
            newCount++;
            allowListMintCount = newCount;

            addressMintCount++;
            addressToAllowListMintCount[_msgSender()] = addressMintCount;

            _mint(erc20Address, isAllowListSaleFreeMint);
        }
    }

    /**
    @notice Implements ERC721 token minting for the public sale.
    @param erc20Address ERC20 contract address. Pass address(0) for free minting.
    */
    function mintWithErc20(address erc20Address) 
        external 
        whenNotPaused 
        nonReentrant 
    {
        require(publicSaleOpen, "Public sale not open");

        uint256 newCount = publicSaleMintCount;
        require(publicSaleMaxSupply == 0 || (newCount + allowListMintCount) < publicSaleMaxSupply, "Public sale sold out");

        uint256 mintCount = addressToPublicSaleMintCount[_msgSender()];
        require(publicSaleAddressMax == 0 || mintCount < publicSaleAddressMax, "Public sale maximum purchases reached");

        // Overflow unrealistic
        unchecked {
            // Set new values before minting
            newCount++;
            publicSaleMintCount = newCount;

            mintCount++;
            addressToPublicSaleMintCount[_msgSender()] = mintCount;

            _mint(erc20Address, isPublicSaleFreeMint);
        }
    }

    /**
    @dev Mints a new token for an address with registered erc20 token
    @param erc20Address The ERC20 contract address
    */
    function _mint(address erc20Address, bool isFreeMint)
        internal
        virtual
    {
        if (!isFreeMint) {
            uint256 price = _prices[erc20Address];

            require(price != 0, "Price not set");

            // Paid mint
            if (_msgSender() != owner()) {
                require(
                    IERC20(erc20Address).transferFrom(
                        _msgSender(),
                        address(this),
                        price
                    )
                );
            }   
        } 

        require(bytes(skinName).length != 0, "Skin name not set");    

        // address to, string memory skinName
        _skin.mint(_msgSender(), skinName);

        // Mint event - token ID unknown
        emit Mint(_msgSender(), 0, skinName);
    }

    /**
    @notice Withdraws ERC20 tokens to the owner.
    @param erc20Address The ERC20 contract address
    @param amount The amount to withdraw
    */
    function withdrawErc20(address erc20Address, uint256 amount) external virtual onlyOwner {
        require(amount <= IERC20(erc20Address).balanceOf(address(this)), "Insufficient balance");
        
        require(IERC20(erc20Address).transfer(_msgSender(), amount));

        // WithdrawERC20 event
        emit WithdrawERC20(erc20Address, _msgSender(), amount);
    }

    /**
    @notice Withdraws ERC20 tokens to an address.
    @param erc20Address ERC20 contract address.
    @param amount The amount to withdraw.
    */
    function withdrawErc20ToPayee(address erc20Address, uint256 amount) external virtual onlyOwner {
        require(payee != address(0), "Payee not set");
        require(amount <= IERC20(erc20Address).balanceOf(address(this)), "Insufficient balance");
        
        require(IERC20(erc20Address).transfer(payee, amount));

        // WithdrawERC20ToAddress event
        emit WithdrawERC20ToAddress(erc20Address, payee, amount);
    }
}