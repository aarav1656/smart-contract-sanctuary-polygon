// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)

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
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

interface IShinoViPlatform {

    struct PlatformFee {
        address recipientA;
        uint256 feeA;
        address recipientB;
        uint256 feeB;
    }

    function getDefaultFees() external returns (PlatformFee memory);

    function getCustomFees(address _address) external returns (PlatformFee memory);

    function isShinoViAdmin() external view returns (bool);

    function isShinoViNFT(address _nft) external view returns (bool);

    function getPlatformFees(address _nft, uint256 _tokenId, address _seller) external returns (PlatformFee memory);

    function getRoyaltyFee(address _nft) external returns (uint256);

    function getRoyaltyRecipient(address _nft) external returns (address);

}

struct Auction {
    address nft;
    uint256 tokenId;
    uint256 amount;
    address creator;
    address payableToken;
    uint256 initialPrice;
    uint256 minBid;
    uint256 startTime;
    uint256 endTime;
    uint256 bidPrice;
    address winningBidder;
    bool success;
}

struct Listing {
    address nft;
    uint256 tokenId;
    uint256 amount;
    address owner;
    uint256 price;
    uint256 chainId;
    address payableToken;
    bool sold;
}

struct Offer {
    address nft;
    uint256 tokenId;
    uint256 amount;
    address offerer;
    uint256 offerPrice;
    address payableToken;
    bool accepted;
}

struct Transaction {
    address nft;
    uint256 tokenId;
    uint256 amount;
    uint256 price;
    address payableToken;
    address seller;
    address buyer;
    bool transferFrom;
}

contract ShinoViMarketplace is Initializable, ReentrancyGuardUpgradeable  {

    event ListedNFT(
        address indexed nft,
        uint256 indexed tokenId,
        uint256 amount,
        address payableToken,
        uint256 price,
        address indexed owner
    );

    event SoldNFT(
        address indexed nft,
        uint256 indexed tokenId,
        uint256 amount,
        address payableToken,
        uint256 price,
        address owner,
        address indexed buyer
    );

    event OfferredNFT(
        address indexed nft,
        uint256 indexed tokenId,
        uint256 amount,
        address payableToken,
        uint256 offerPrice,
        address indexed offerer
    );

    event CanceledOffer(
        address indexed nft,
        uint256 indexed tokenId,
        uint256 amount,
        address payableToken,
        uint256 offerPrice,
        address indexed offerer
    );

    event AcceptedOffer(
        address indexed nft,
        uint256 indexed tokenId,
        uint256 amount,
        address payableToken,
        uint256 offerPrice,
        address offerer,
        address indexed nftOwner
    );

    event CreatedAuction(
        address indexed nft,
        uint256 indexed tokenId,
        uint256 amount,
        address payableToken,
        uint256 price,
        uint256 minBid,
        uint256 startTime,
        uint256 endTime,
        address indexed creator
    );

    event PlacedBid(
        address indexed nft,
        uint256 indexed tokenId,
        uint256 amount,
        address payableToken,
        uint256 bidPrice,
        address indexed bidder
    );

    event AuctionResult(
        address indexed nft,
        uint256 indexed tokenId,
        uint256 amount,
        address creator,
        address indexed winner,
        uint256 price,
        address caller
    );


    // token => isPayable
    mapping(address => bool) private payableTokens;
    // nft => tokenId => listing 
    mapping(address => mapping(uint256 => Listing)) private listings;
    // nft => tokenId => auction 
    mapping(address => mapping(uint256 => Auction)) private auctions;
    // nft => tokenId => offer array
    mapping(address => mapping(uint256 => Offer[])) private offers;


    IShinoViPlatform private shinoViPlatform;
    function initialize(address _shinoViPlatform) public initializer {
        shinoViPlatform = IShinoViPlatform(_shinoViPlatform);
        payableTokens[0x0000000000000000000000000000000000001010] = true;
    }

   /*
    IShinoViPlatform private immutable shinoViPlatform;

    constructor(
        IShinoViPlatform _shinoViPlatform
    ) {
        shinoViPlatform = _shinoViPlatform;
    }
   */

    modifier isAdmin() {
        require(shinoViPlatform.isShinoViAdmin() == true, "access denied");
        _;
    }

    modifier isShinoViNFT(address _nft) {
        require(shinoViPlatform.isShinoViNFT(_nft) == true, "unrecognized NFT collection");
        _;
    }

    modifier isListed(address _nft, uint256 _tokenId) {
        require(
             listings[_nft][_tokenId].owner != address(0) &&  listings[_nft][_tokenId].sold == false,
            "not listed"
        );
        _;
    }

    modifier isPayableToken(address _payableToken) {
        require(
            _payableToken != address(0) && payableTokens[_payableToken],
            "invalid pay token"
        );
        _;
    }

    modifier isAuction(address _nft, uint256 _tokenId) {
        require(
            auctions[_nft][_tokenId].nft != address(0) && auctions[_nft][_tokenId].success == false,
            "auction already created"
        );
        _;
    }

    modifier isNotAuction(address _nft, uint256 _tokenId) {
        require(
            auctions[_nft][_tokenId].nft == address(0) || auctions[_nft][_tokenId].success,
            "auction already created"
        );
        _;
    }

    modifier isOfferred(
        address _nft,
        uint256 _tokenId,
        address _offerer,
        uint256 _index
    ) {
        require(
            offers[_nft][_tokenId][_index].offerPrice > 0 && offers[_nft][_tokenId][_index].offerer != address(0),
            "not on offer"
        );
        _;
    }

    function listNFT(
        address _nft,
        uint256 _tokenId,
        uint256 _amount,
        uint256 _price,
        uint256 _chainId,
        address _payableToken)
        external
        isShinoViNFT(_nft)
        isPayableToken(_payableToken)
        nonReentrant
    {

        require(_amount > 0, "access denied");

        safeTransferFrom(_nft, msg.sender, address(this), _tokenId, _amount);

        listings[_nft][_tokenId] = Listing({
            nft: _nft,
            tokenId: _tokenId,
            amount: _amount,
            owner: msg.sender,
            price: _price,
            chainId: _chainId,
            payableToken: _payableToken,
            sold: false
        });

        emit ListedNFT(_nft, _tokenId, _amount, _payableToken, _price, msg.sender);

    }

    // delist the nft
    function deListing(address _nft, uint256 _tokenId)
        external
        isListed(_nft, _tokenId)
        nonReentrant
    {

        Listing memory thisNFT = listings[_nft][_tokenId];
        require(thisNFT.owner == msg.sender, "access denied");
        require(thisNFT.sold == false, "nft has already been sold");

        delete listings[_nft][_tokenId];
        // IERC721(_nft).transferFrom(address(this), msg.sender, _tokenId);
        safeTransferFrom(_nft, address(this), msg.sender, _tokenId, thisNFT.amount);

    }

    // purchase listing
    function purchaseNFT(
        address _nft,
        uint256 _tokenId,
        uint256 _amount,
        address _payableToken,
        uint256 _price)
        external
        isListed(_nft, _tokenId)
        nonReentrant
    {
        Listing storage thisNFT = listings[_nft][_tokenId];
        require(
            _payableToken != address(0) && _payableToken == thisNFT.payableToken,
            "invalid pay token"
        );
        require(thisNFT.sold == false, "nft has already been sold");
        require(_price >= thisNFT.price, "invalid price");
        thisNFT.sold = true; 

        Transaction memory t = Transaction({
            nft: _nft,
            tokenId: _tokenId,
            amount: _amount,
            price: _price,
            payableToken: _payableToken,
            seller: thisNFT.owner,
            buyer: msg.sender,
            transferFrom: true
        });
        processTransaction(t);

        emit SoldNFT(
            thisNFT.nft,
            thisNFT.tokenId,
            thisNFT.amount,
            thisNFT.payableToken,
            _price,
            thisNFT.owner,
            msg.sender
        );

    }

    function createOffer(
        address _nft,
        uint256 _tokenId,
        uint256 _amount,
        address _payableToken,
        uint256 _offerPrice
    ) external
        isListed(_nft, _tokenId)
        nonReentrant
    {
        require(_offerPrice > 0, "price must be greater than zero.");

        Listing memory nft = listings[_nft][_tokenId];

        IERC20(nft.payableToken).transferFrom(
            msg.sender,
            address(this),
            _offerPrice
        );

        offers[_nft][_tokenId].push(Offer({
            nft: _nft,
            tokenId: _tokenId,
            amount: _amount,
            offerer: msg.sender,
            payableToken: _payableToken,
            offerPrice: _offerPrice,
            accepted: false
        }));

        emit OfferredNFT(
            _nft,
            _tokenId,
            _amount,
            _payableToken,
            _offerPrice,
            msg.sender
        );
        
    }

    function cancelOffer(address _nft, uint256 _tokenId, uint _index)
        external
        isOfferred(_nft, _tokenId, msg.sender, _index)
        nonReentrant
    {
        Offer memory offer = offers[_nft][_tokenId][_index];
        require(offer.offerer == msg.sender, "not offerer");
        require(offer.accepted == false, "offer already accepted");
        delete offers[_nft][_tokenId][_index];
        IERC20(offer.payableToken).transfer(offer.offerer, offer.offerPrice);
        
        emit CanceledOffer(
            offer.nft,
            offer.tokenId,
            offer.amount,
            offer.payableToken,
            offer.offerPrice,
            msg.sender
        );

    }

    function acceptOffer(
        address _nft,
        uint256 _tokenId,
        uint256 _amount,
        address _offerer,
        uint256 _index
    )
        external
        isOfferred(_nft, _tokenId, _offerer, _index)
        isListed(_nft, _tokenId)
        nonReentrant
    {
        require(
            listings[_nft][_tokenId].owner == msg.sender,
            "not listed owner"
        );
        Offer storage offer = offers[_nft][_tokenId][_index];
        Listing storage list = listings[offer.nft][offer.tokenId];
        require(list.sold == false, "item already sold");
        require(offer.accepted == false, "offer already accepted");

        list.sold = true;
        offer.accepted = true;

        Transaction memory t = Transaction({
            nft: _nft,
            tokenId: _tokenId,
            amount: _amount,
            price: offer.offerPrice,
            payableToken: offer.payableToken,
            seller: msg.sender,
            buyer: offer.offerer,
            transferFrom: false
        });
        processTransaction(t);

        emit AcceptedOffer(
            offer.nft,
            offer.tokenId,
            offer.amount,
            offer.payableToken,
            offer.offerPrice,
            offer.offerer,
            list.owner
        );
       
    }

    //
    function createAuction(
        address _nft,
        uint256 _tokenId,
        uint256 _amount,
        address _payableToken,
        uint256 _price,
        uint256 _minBid,
        uint256 _startTime,
        uint256 _endTime)
        external isPayableToken(_payableToken)
        isNotAuction(_nft, _tokenId)
        nonReentrant
    {
        //IERC721 nft = IERC721(_nft);
        //require(nft.ownerOf(_tokenId) == msg.sender, "not nft owner");
        require(_endTime > _startTime, "invalid end time");

        // nft.transferFrom(msg.sender, address(this), _tokenId);
        safeTransferFrom(_nft, msg.sender, address(this), _tokenId, _amount);

        auctions[_nft][_tokenId] = Auction({
            nft: _nft,
            tokenId: _tokenId,
            amount: _amount,
            creator: msg.sender,
            payableToken: _payableToken,
            initialPrice: _price,
            minBid: _minBid,
            startTime: _startTime,
            endTime: _endTime,
            winningBidder: address(0),
            bidPrice: _price,
            success: false
        });

        emit CreatedAuction(
            _nft,
            _tokenId,
            _amount,
            _payableToken,
            _price,
            _minBid,
            _startTime,
            _endTime,
            msg.sender
        );
       
    }

    /*
    // this function is dangerous,
    function cancelAuction(address _nft, uint256 _tokenId)
        external
        isAuction(_nft, _tokenId)
        nonReentrant
    {
        Auction memory auction = auctions[_nft][_tokenId];
        require(auction.creator == msg.sender, "not auction creator");
        require(block.timestamp < auction.startTime, "auction already started");
        require(auction.winningBidder == address(0), "already have bidder");

        delete auctions[_nft][_tokenId];
        //IERC721 nft = IERC721(_nft);
        //nft.transferFrom(address(this), msg.sender, _tokenId);
        safeTransferFrom(_nft, address(this), msg.sender, _tokenId, auction.amount);
    }
    */

    function placeBid(
        address _nft,
        uint256 _tokenId,
        uint256 _bidPrice
    ) external
        isAuction(_nft, _tokenId)
        nonReentrant
    {
        require(
            block.timestamp >= auctions[_nft][_tokenId].startTime,
            "auction not started"
        );
        require(
            block.timestamp <= auctions[_nft][_tokenId].endTime,
            "auction has ended"
        );
        require(
            _bidPrice >=
                 auctions[_nft][_tokenId].minBid,
            "bid price less than minimum"
        );
        require(
            _bidPrice >
                auctions[_nft][_tokenId].bidPrice,
            "bid price less than current"
        );
        Auction storage auction = auctions[_nft][_tokenId];
        IERC20 payableToken = IERC20(auction.payableToken);
        payableToken.transferFrom(msg.sender, address(this), _bidPrice);

        if (auction.winningBidder != address(0)) {
            address previousBidder = auction.winningBidder;
            uint256 previousBidPrice = auction.bidPrice;

            // Set new winning bid 
            auction.winningBidder = msg.sender;
            auction.bidPrice = _bidPrice;

            // Return funds to previous bidder
            payableToken.transfer(previousBidder, previousBidPrice);
        }

        emit PlacedBid(_nft, _tokenId, auction.amount, auction.payableToken, _bidPrice, msg.sender);
    }

    function finalizeAuction(address _nft, uint256 _tokenId)
        external
        nonReentrant
    {

        Auction storage auction = auctions[_nft][_tokenId];
        require(auction.success == false, "auction already finished");
        require(
        //    msg.sender == owner ||
                msg.sender == auction.creator ||
                msg.sender == auction.winningBidder,
            "access denied"
        );
        require(
            block.timestamp > auction.endTime,
            "auction still in progress"
        );

        auction.success = true;

        Transaction memory t = Transaction({
            nft: _nft,
            tokenId: _tokenId,
            amount: auction.amount,
            price: auction.bidPrice,
            payableToken: auction.payableToken,
            seller: auction.creator,
            buyer: auction.winningBidder,
            transferFrom: false
        });
        processTransaction(t);

        emit AuctionResult(
            _nft,
            _tokenId,
            auction.amount,
            auction.creator,
            auction.winningBidder,
            auction.bidPrice,
            msg.sender
        );

    }

    function processTransaction(Transaction memory t) private {

        uint256 totalAmount = t.price;
        address royaltyRecipient = shinoViPlatform.getRoyaltyRecipient(t.nft);
        uint256 royaltyFee = shinoViPlatform.getRoyaltyFee(t.nft);

        if (royaltyFee > 0) {

            uint256 royaltyAmount = (t.price * royaltyFee) / 10000;

            // Process royalty
            if (t.transferFrom == true) {

                IERC20(t.payableToken).transferFrom(
                    t.buyer,
                    royaltyRecipient,
                    royaltyAmount
                );

            } else {

                IERC20(t.payableToken).transfer(
                    royaltyRecipient,
                    royaltyAmount
                );

            }
            totalAmount -= royaltyAmount;

        }

        IShinoViPlatform.PlatformFee memory platformFees = shinoViPlatform.getPlatformFees(t.nft, t.tokenId, t.seller);

        // process platform fees

        uint256 platformFeeA = (t.price * platformFees.feeA) / 10000;
        uint256 platformFeeB = (t.price * platformFees.feeB) / 10000;

        if (t.transferFrom == true) {

            IERC20(t.payableToken).transferFrom(
                t.buyer,
                platformFees.recipientA,
                platformFeeA
            );
            totalAmount -= platformFeeA;

            IERC20(t.payableToken).transferFrom(
                t.buyer,
                platformFees.recipientB,
                platformFeeB
            );
            totalAmount -= platformFeeB;

            // pay seller
            IERC20(t.payableToken).transferFrom(
                t.buyer,
                t.seller,
                totalAmount
            );

            // finally transfer NFT
            safeTransferFrom(t.nft, t.seller, t.buyer, t.tokenId, t.amount);

        } else {

            IERC20(t.payableToken).transfer(
                platformFees.recipientA,
                platformFeeA
            );
            totalAmount -= platformFeeA;

            IERC20(t.payableToken).transfer(
                platformFees.recipientB,
                platformFeeB
            );
            totalAmount -= platformFeeB;

            // pay seller
            IERC20(t.payableToken).transfer(
                t.seller,
                totalAmount
            );

            // finally transfer NFT
            safeTransferFrom(t.nft, address(this), t.buyer, t.tokenId, t.amount);

        }

    }

    function safeTransferFrom(address _nft, address _from, address _to, uint256 _tokenId, uint256 _amount) internal {

        if (IERC165(_nft).supportsInterface(type(IERC721).interfaceId)) {

            IERC721 nft = IERC721(_nft);
            require(_amount == 1, "amount must be one");
            require(nft.ownerOf(_tokenId) == _from, "access denied");
            nft.transferFrom(_from, _to, _tokenId);

        } else if (IERC165(_nft).supportsInterface(type(IERC1155).interfaceId)) {

            IERC1155 nft = IERC1155(_nft);
            require(_amount > 0, "amount must be positive");
            require(nft.balanceOf(_from, _tokenId) >= _amount, "access denied");
            nft.safeTransferFrom(_from, _to, _tokenId, _amount, "");

        } else {

            revert();

        }

    }

    function getListedNFT(address _nft, uint256 _tokenId)
        external
        view
        returns (Listing memory)
    {
        return listings[_nft][_tokenId];
    }

    function setPayableToken(address _token, bool _enable) external isAdmin {
        require(_token != address(0), "invalid token");
        payableTokens[_token] = _enable;
    }

}