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
// OpenZeppelin Contracts (last updated v4.8.0-rc.1) (proxy/utils/Initializable.sol)

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
// OpenZeppelin Contracts (last updated v4.8.0-rc.1) (utils/Address.sol)

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

pragma solidity ^0.8.16;

interface BadgerOrganizationInterface { 
    /*//////////////////////////////////////////////////////////////
                                SETTERS
    //////////////////////////////////////////////////////////////*/
    
    /**
     * @notice Initialize the Organization with the starting state needed.
     * @param _owner The owner of the Organization. (Ideally a multi-sig).
     * @param _uri The base URI for the Organization.
     * @param _contractURI The URI for the contract metadata.
     * @param _name The name of the Organization.
     * @param _symbol The symbol of the Organization.
     */
    function initialize(
          address _owner
        , string memory _uri
        , string memory _contractURI
        , string memory _name
        , string memory _symbol
    )
        external;

    /**
     * @dev Allows the leader of a badge to mint the badge they are leading.
     * @param _to The address to mint the badge to.
     * @param _id The id of the badge to mint.
     * @param _amount The amount of the badge to mint.
     * @param _data The data to pass to the receiver.
     * 
     * Requirements:
     * - `_msgSender` must be the leader of the badge.
     */
    function leaderMint(
          address _to
        , uint256 _id 
        , uint256 _amount 
        , bytes memory _data
    )
        external;

    /**
     * @notice Allows a leader of a badge to mint a batch of recipients in a single transaction.
     *         Enabling the ability to seamlessly roll out a new "season" with a single batch
     *         instead of needing hundreds of individual events. Because of this common use case,
     *         the constant is designed around the _id rather than the _to address.
     * @param _tos The addresses to mint the badge to.
     * @param _id The id of the badge to mint.
     * @param _amounts The amounts of the badge to mint.
     * @param _data The data to pass to the receiver.
     */
    function leaderMintBatch(
          address[] memory _tos
        , uint256 _id
        , uint256[] memory _amounts
        , bytes memory _data
    )
        external;

    /**
     * @notice Allows a user to mint a claim that has been designated to them.
     * @dev This function is only used when the mint is being paid with ETH or has no payment at all.
     *      To use this with no payment, the `tokenType` of NATIVE with `quantity` of 0 must be used.
     * @param _signature The signature that is being used to verify the authenticity of claim.
     * @param _id The id of the badge being claimed.
     * @param _amount The amount of the badge being claimed.
     * @param _data Any data that is being passed to the mint function.
     * 
     * Requirements:
     * - `_id` must corresponding to an existing Badge config.
     * - `_signature` must be a valid signature of the claim.
     */
    function claimMint(
          bytes calldata _signature
        , uint256 _id 
        , uint256 _amount 
        , bytes memory _data
    )
        external
        payable;

    /**
     * @notice Allows the owner and leader of a contract to revoke a badge from a user.
     * @param _from The address to revoke the badge from.
     * @param _id The id of the badge to revoke.
     * @param _amount The amount of the badge to revoke.
     *
     * Requirements:
     * - `_msgSender` must be the owner or leader of the badge.
     */
    function revoke(
          address _from
        , uint256 _id
        , uint256 _amount
    )
        external;

    /**
     * @notice Allows the owner and leaders of a contract to revoke badges from a user.
     * @param _froms The addresses to revoke the badge from.
     * @param _id The id of the badge to revoke.
     * @param _amounts The amount of the badge to revoke.
     *
     * Requirements:
     * - `_msgSender` must be the owner or leader of the badge.
     */
    function revokeBatch(
          address[] memory _froms
        , uint256 _id
        , uint256[] memory _amounts 
    )
        external;

    /**
     * @notice Allows the owner of a badge to forfeit their ownership.
     * @param _id The id of the badge to forfeit.
     * @param _amount The amount of the badge to forfeit.
     * @param _data The data to pass to the receiver.
     */
    function forfeit(
          uint256 _id
        , uint256 _amount
        , bytes memory _data
    )
        external;

    /**
     * @notice Allows the owner of a badge to deposit ETH to fund the claiming of a badge.
     * @param _id The id of the badge to deposit ETH for.
     */
    function depositETH(
        uint256 _id
    )
        external
        payable;

    /**
     * @notice Allows the owner of a badge to deposit an ERC20 into the contract.
     * @param _id The id of the badge to deposit for.
     * @param _token The address of the token to deposit.
     * @param _amount The amount of the token to deposit.
     */
    function depositERC20(
          uint256 _id
        , address _token
        , uint256 _amount
    )
        external;
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.17;

/// @dev Core dependencies.
import { ReputationModuleInterface } from "./interfaces/ReputationModuleInterface.sol";
import { BadgerOrganizationInterface } from "../Badger/interfaces/BadgerOrganizationInterface.sol";

/// @dev Helper interfaces.
import { IERC1155 } from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import { ContextUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract ReputationModule is 
    ReputationModuleInterface,
    ContextUpgradeable
{
    /// @dev The Labor Market Network permissioned to make actions.
    address public network;

    /// @dev The decay configuration of a given reputation token.
    mapping(address => mapping(uint256 => DecayConfig)) public decayConfig;

    /// @dev The configuration for a given Labor Market.
    mapping(address => MarketReputationConfig) public marketRepConfig;

    /// @dev The decay and freezing state for an account for a given reputation token.
    mapping(address => mapping(uint256 => mapping(address => ReputationAccountInfo))) public accountInfo;

    /// @dev When the reputation implementation of a market is changed.
    event MarketReputationConfigured (
          address indexed market
        , address indexed reputationToken
        , uint256 indexed reputationTokenId
    );

    /// @dev When the decay configuration of a reputation token is changed.
    event ReputationDecayConfigured (
          address indexed reputationToken
        , uint256 indexed reputationTokenId
        , uint256 decayRate
        , uint256 decayInterval
        , uint256 decayStartEpoch
    );

    /// @dev When the balance of an account is changed.
    event ReputationBalanceChange (
        address indexed account,
        address indexed reputationToken,
        uint256 indexed reputationTokenId,
        int256 amount
    );

    constructor(
        address _network
    ) {
        network = _network;
    }

    /**
     * @notice Initialize a new Labor Market as using Reputation.
     * @param _laborMarket The address of the new Labor Market.
     * @param _reputationToken The address of the reputation token.
     * @param _reputationTokenId The ID of the reputation token.
     * Requirements:
     * - Only the network can call this function when creating a new market.
     */
    function useReputationModule(
          address _laborMarket
        , address _reputationToken
        , uint256 _reputationTokenId
    )
        override
        external
    {
        require(
            _msgSender() == network, 
            "ReputationModule: Only network can call this."
        );

        marketRepConfig[_laborMarket] = MarketReputationConfig({
              reputationToken: _reputationToken
            , reputationTokenId: _reputationTokenId
        });

        emit MarketReputationConfigured(
              _laborMarket
            , _reputationToken
            , _reputationTokenId
        );
    }

     /**
     * @notice Utilize and burn reputation.
     * @param _account The account to burn reputation from.
     * @param _amount The amount of reputation to burn.
     */
    function useReputation(
          address _account
        , uint256 _amount
    )
        external
        override
    {
        _revokeReputation(
            marketRepConfig[_msgSender()].reputationToken,
            marketRepConfig[_msgSender()].reputationTokenId,
            _account,
            _amount
        );
    }

    /**
     * @notice Lock and freeze reputation for an account, avoiding decay.
     * @param _account The account to freeze reputation for.
     * @param _reputationToken The address of the reputation token.
     * @param _reputationTokenId The ID of the reputation token.
     * @param _frozenUntilEpoch The epoch until which the reputation is frozen.
     * Requirements:
     * - The frozenUntilEpoch must be in the future.
     */
    function freezeReputation(
          address _account
        , address _reputationToken
        , uint256 _reputationTokenId
        , uint256 _frozenUntilEpoch
    )
        external
        override
    {   
        require(
            _frozenUntilEpoch > block.timestamp,
            "ReputationModule: Cannot retroactively freeze reputation."
        );

        _revokeReputation(
            _reputationToken,
            _reputationTokenId,
            _account,
            0
        );

        accountInfo[_reputationToken][_reputationTokenId][_account].frozenUntilEpoch = _frozenUntilEpoch;
    }

    /**
     * @notice Mint reputation for a given account.
     * @param _account The account to mint reputation for.
     * @param _amount The amount of reputation to mint.
     * Requirements:
     * - The sender must be a Labor Market.
     * - The Labor Market must have been initialized with the Reputation Module.
     */
    function mintReputation(
          address _account
        , uint256 _amount
    )
        external
        override
    {
        MarketReputationConfig memory config = marketRepConfig[_msgSender()];

        require(
            config.reputationToken != address(0), 
            "ReputationModule: This Labor Market has not been initialized."
        );

        BadgerOrganizationInterface(config.reputationToken).leaderMint(
            _account,
            config.reputationTokenId,
            _amount,
            ""
        );

        emit ReputationBalanceChange(
            _account,
            config.reputationToken,
            config.reputationTokenId,
            int256(_amount)
        );
    }

    /**
     * @notice Set the decay configuration for a reputation token.
     * @param _reputationToken The address of the reputation token.
     * @param _reputationTokenId The ID of the reputation token.
     * @param _decayRate The rate of decay.
     * @param _decayInterval The interval of decay.
     * @param _decayStartEpoch The epoch at which decay starts.
     * Requirements:
     * - Only the network can call this function.
     * - The network function caller must be a Governor.
     */
    function setDecayConfig(
          address _reputationToken
        , uint256 _reputationTokenId
        , uint256 _decayRate
        , uint256 _decayInterval
        , uint256 _decayStartEpoch
    )
        external
        override
    {
        require(_msgSender() == network, "ReputationModule: Only network can call this.");

        decayConfig[_reputationToken][_reputationTokenId] = DecayConfig({
              decayRate: _decayRate
            , decayInterval: _decayInterval
            , decayStartEpoch: _decayStartEpoch
        });

        emit ReputationDecayConfigured(
            _reputationToken
            , _reputationTokenId
            , _decayRate
            , _decayInterval
            , _decayStartEpoch
        );
    }

    /**
     * @notice Get the amount of reputation that is available to use.
     * @dev This function takes into account non-applied decay and the frozen state.
     * @param _laborMarket The Labor Market context.
     * @param _account The account to check.
     * @return _availableReputation The amount of reputation that is available to use.
     */
    function getAvailableReputation(
        address _laborMarket,
        address _account
    )
        external
        view
        override
        returns (
            uint256 _availableReputation
        )
    {
        MarketReputationConfig memory config = marketRepConfig[_laborMarket];
        ReputationAccountInfo memory info = accountInfo[config.reputationToken][config.reputationTokenId][_account];

        if (info.frozenUntilEpoch > block.timestamp) return 0;

        uint256 decayed = _getReputationDecay(
            config.reputationToken,
            config.reputationTokenId,
            info.frozenUntilEpoch,
            info.lastDecayEpoch
        );

        _availableReputation = IERC1155(config.reputationToken).balanceOf(
            _account,
            config.reputationTokenId
        );

        return _availableReputation > decayed ? _availableReputation - decayed : 0;
    }

    /**
     * @notice Get the amount of reputation that is pending decay.
     * @param _laborMarket The Labor Market context.
     * @param _account The account to check.
     * @return The amount of reputation that is pending decay.
     */
    function getPendingDecay(
          address _laborMarket
        , address _account
    )
        external
        view
        override
        returns (
            uint256
        )
    {
        MarketReputationConfig memory config = marketRepConfig[_laborMarket];

        return _getReputationDecay(
            config.reputationToken,
            config.reputationTokenId,
            accountInfo[config.reputationToken][config.reputationTokenId][_account].frozenUntilEpoch,
            accountInfo[config.reputationToken][config.reputationTokenId][_account].lastDecayEpoch
        );
    }

    /**
     * @notice Get the ERC1155 token address and ID for a given Labor Market.
     * @param _laborMarket The Labor Market to check.
     * @return The ERC1155 token address and ID for a given Labor Market.
     */
    function getMarketReputationConfig(
        address _laborMarket
    )
        external
        view
        override
        returns (
            MarketReputationConfig memory
        )
    {
        return marketRepConfig[_laborMarket];
    }

    /**
     * @notice Manage the revoking of reputation and the decay application.
     * @param _reputationToken The address of the reputation token.
     * @param _reputationTokenId The ID of the reputation token.
     * @param _account The account to revoke reputation from.
     * @param _amount The amount of reputation to revoke.
     */
    function _revokeReputation(
          address _reputationToken
        , uint256 _reputationTokenId
        , address _account
        , uint256 _amount
    )
        internal
    {
        uint256 balance = IERC1155(_reputationToken).balanceOf(
            _account,
            _reputationTokenId
        );

        require(
            balance >= _amount,
            "ReputationModule: Not enough reputation to use."
        );

        ReputationAccountInfo storage info = accountInfo[_reputationToken][_reputationTokenId][_account];

        uint256 decay = _getReputationDecay(
            _reputationToken, 
            _reputationTokenId,
            info.frozenUntilEpoch,
            info.lastDecayEpoch
        );

        // If decay is more than the balance, just take all balance.
        uint256 amount = _amount + decay;
        if (amount > balance) amount = balance;

        info.lastDecayEpoch = block.timestamp;

        BadgerOrganizationInterface(_reputationToken).revoke(
            _account,
            _reputationTokenId,
            amount
        );

        emit ReputationBalanceChange(
            _account,
            _reputationToken,
            _reputationTokenId,
            int256(amount) * -1
        );
    }

    /**
     * @notice Get the amount of reputation that has decayed.
     * @param _reputationToken The reputation token to check.
     * @param _reputationTokenId The reputation token ID to check.
     * @param _frozenUntilEpoch The epoch that the reputation is frozen until.
     * @param _lastDecayEpoch The epoch that the reputation was last decayed.
     * @return The amount of reputation that has decayed.
     */
    function _getReputationDecay(
          address _reputationToken
        , uint256 _reputationTokenId
        , uint256 _frozenUntilEpoch
        , uint256 _lastDecayEpoch
    )
        internal
        view
        returns (
            uint256
        )
    {
        DecayConfig memory decay = decayConfig[_reputationToken][_reputationTokenId];

        if (
            _frozenUntilEpoch > block.timestamp || 
            decay.decayRate == 0
        ) {
            return 0;
        }

        // If the last decay epoch is greater than the decay start epoch, use that.
        uint256 startEpoch = _lastDecayEpoch > decay.decayStartEpoch ? 
            _lastDecayEpoch : decay.decayStartEpoch;

        return (((block.timestamp - startEpoch - _frozenUntilEpoch) /
            decay.decayInterval) * decay.decayRate);
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.17;

interface ReputationModuleInterface {
    struct MarketReputationConfig {
        address reputationToken;
        uint256 reputationTokenId;
    }

    struct DecayConfig {
        uint256 decayRate;
        uint256 decayInterval;
        uint256 decayStartEpoch;
    }

    struct ReputationAccountInfo {
        uint256 lastDecayEpoch;
        uint256 frozenUntilEpoch;
    }

    function useReputationModule(
          address _laborMarket
        , address _reputationToken
        , uint256 _reputationTokenId
    )
        external;
        
    function useReputation(
          address _account
        , uint256 _amount
    )
        external;

    function mintReputation(
          address _account
        , uint256 _amount
    )
        external;

    function freezeReputation(
          address _account
        , address _reputationToken
        , uint256 _reputationTokenId
        , uint256 _frozenUntilEpoch
    )
        external; 


    function setDecayConfig(
          address _reputationToken
        , uint256 _reputationTokenId
        , uint256 _decayRate
        , uint256 _decayInterval
        , uint256 _decayStartEpoch
    )
        external;

    function getAvailableReputation(
          address _laborMarket
        , address _account
    )
        external
        view
        returns (
            uint256
        );

    function getPendingDecay(
          address _laborMarket
        , address _account
    )
        external
        view
        returns (
            uint256
        );

    function getMarketReputationConfig(
        address _laborMarket
    )
        external
        view
        returns (
            MarketReputationConfig memory
        );
}