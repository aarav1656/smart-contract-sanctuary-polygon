// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Openzeppelin
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
// Callback
import "../Callback/AmberfiCallbackUpgradeable.sol";

/**
 * This smart contract is proprietary and not to be copied or
 * reproduced without the express permission of the Amberfi
 * Platform.
 */
contract AmberfiStorage is Initializable, OwnableUpgradeable {
    enum Status {
        Pending,
        InProgress,
        Cancelled,
        Failed,
        Finalized
    }

    struct StorageRecord {
        uint256 itemId;
        address owner;
        Status status;
        string tempCid; // Identifying info for content (e.g. CID, "DNA", etc)
        string cidType; // Is this a metadata JSON type or DATA
        string cid; // This will be the final CID of optional content post minting.
        string cidProof; // This will be the block it was minted at
        uint8 storageLocationId; // This will be the final location of  content (arweave, nfts for nft.storage, infura)
    }

    uint8[] private _storageLocationIds;

    mapping(address => mapping(uint256 => mapping(string => StorageRecord)))
        public record;

    event Encrypt(
        address indexed from,
        uint256 indexed itemId,
        uint8 status,
        string tempCid,
        string encryptCid,
        uint256 locationId
    );

    event Store(
        address indexed from,
        uint256 indexed itemId,
        uint8 status,
        string tempCid,
        uint256 locationId
    );

    function initialize() public initializer {
        __Ownable_init();
    }

    function getStorageRecord(
        address account_,
        uint256 itemId_,
        string calldata tempCid_,
        Status status_
    ) public onlyOwner returns (Status) {
        // You can get values from a nested mapping
        // even when it is not initialized
        record[account_][itemId_][tempCid_].status = status_;
        return record[account_][itemId_][tempCid_].status;
    }

    function removeStorageRecord(uint256 itemId_, string calldata tempCid_)
        public
        onlyOwner
    {
        delete record[_msgSender()][itemId_][tempCid_];
    }

    function removeStorageRecord(
        address account_,
        uint256 itemId_,
        string calldata tempCid_
    ) public onlyOwner {
        delete record[account_][itemId_][tempCid_];
    }

    function registerStorage(
        uint256 itemId_,
        string calldata tempCid_,
        uint8 storageLocationId_
    ) public {
        bytes memory strBytes = bytes(tempCid_);
        require(
            strBytes.length > 0,
            "AmberfiStorage: temporary CID is invalid "
        );
        StorageRecord storage srecord = record[_msgSender()][itemId_][tempCid_];
        require(
            keccak256(bytes(tempCid_)) != keccak256(bytes(srecord.tempCid)),
            "AmberfiStorage: Collision of tempCid - already used.  Delete first."
        );
        srecord.status = Status.Pending;
        srecord.tempCid = tempCid_; // Identifying info for content (e.g. CID, "DNA", etc)
        srecord.storageLocationId = storageLocationId_;
        emit Store(
            _msgSender(),
            itemId_,
            uint8(Status.Pending),
            tempCid_,
            storageLocationId_
        );
    }

    function registerEncryptedStorage(
        uint256 itemId_,
        string calldata tempCid_,
        string calldata encryptCid_,
        uint8 storageLocationId_
    ) public {
        bytes memory strBytes = bytes(tempCid_);
        require(
            strBytes.length > 0,
            "AmberfiStorage: temporary CID is invalid "
        );
        StorageRecord storage srecord = record[_msgSender()][itemId_][tempCid_];
        //require( keccak256(bytes(tempCid_)) == keccak256(bytes(srecord.tempCid)), "AmberfiStorage: Collision of tempCid - already used.  Delete first.");
        srecord.status = Status.Pending;
        srecord.tempCid = tempCid_; // Identifying info for content (e.g. CID, "DNA", etc)
        srecord.storageLocationId = storageLocationId_;
        emit Encrypt(
            _msgSender(),
            itemId_,
            uint8(Status.Pending),
            tempCid_,
            encryptCid_,
            storageLocationId_
        );
    }

    function setImageStorage(
        address account_,
        uint256 itemId_,
        string calldata tempCid_,
        string calldata cid_,
        string calldata cidProof_,
        uint8 status_
    ) public onlyOwner {
        require(
            status_ > 0,
            "AmberfiStorage: Only pending transactions can be updated with final storage."
        );
        bytes memory strBytes = bytes(tempCid_);
        require(
            strBytes.length > 0,
            "AmberfiStorage: temporary CID is invalid "
        );
        StorageRecord storage srecord = record[_msgSender()][itemId_][tempCid_];
        srecord.cid = cid_;
        srecord.cidProof = cidProof_;
        AmberfiCallbackUpgradeable.Status status = AmberfiCallbackUpgradeable
            .Status
            .Pending;
        if (AmberfiCallbackUpgradeable.Status.Cancelled == status) {
            status = AmberfiCallbackUpgradeable.Status.Cancelled;
            srecord.status = Status.Cancelled;
        }
        if (AmberfiCallbackUpgradeable.Status.InProgress == status) {
            status = AmberfiCallbackUpgradeable.Status.InProgress;
            srecord.status = Status.InProgress;
        }
        if (AmberfiCallbackUpgradeable.Status.Failed == status) {
            status = AmberfiCallbackUpgradeable.Status.Failed;
            srecord.status = Status.Failed;
        }
        if (AmberfiCallbackUpgradeable.Status.Finalized == status) {
            status = AmberfiCallbackUpgradeable.Status.Finalized;
            srecord.status = Status.Finalized;
        }
        AmberfiCallbackUpgradeable a = AmberfiCallbackUpgradeable(account_);
        a.setContent(
            itemId_,
            srecord.tempCid,
            srecord.cid,
            srecord.cidProof,
            status
        );
    }

    function setStorageRecord(
        address account_,
        uint256 _itemId_,
        string calldata _tempCid_,
        StorageRecord calldata storageRecord_
    ) public onlyOwner {
        record[account_][_itemId_][_tempCid_] = storageRecord_;
    }

    function setStorageStatus(
        address account_,
        uint256 itemId_,
        string calldata _tempCid_,
        Status status_
    ) public {
        record[account_][itemId_][_tempCid_].status = status_;
    }

    function getNewImageLocation(
        address account_,
        uint256 itemId_,
        string calldata tempCid_
    ) public view returns (string memory) {
        // You can get values from a nested mapping
        // even when it is not initialized
        return record[account_][itemId_][tempCid_].cid;
    }

    function getStorageRecord(uint256 itemId_, string calldata tempCid_)
        public
        view
        returns (StorageRecord memory)
    {
        // You can get values from a nested mapping
        // even when it is not initialized
        return record[_msgSender()][itemId_][tempCid_];
    }

    function getStorageStatus(uint256 itemId_, string calldata tempCid_)
        public
        view
        returns (AmberfiCallbackUpgradeable.Status)
    {
        return getStorageStatusforContract(_msgSender(), itemId_, tempCid_);
    }

    function getStorageStatusforContract(
        address account_,
        uint256 itemId_,
        string calldata tempCid_
    ) public view returns (AmberfiCallbackUpgradeable.Status) {
        // You can get values from a nested mapping
        // even when it is not initialized
        Status status = record[account_][itemId_][tempCid_].status;
        if (Status.Pending == status) {
            return AmberfiCallbackUpgradeable.Status.Pending;
        }
        if (Status.InProgress == status) {
            return AmberfiCallbackUpgradeable.Status.InProgress;
        }
        if (Status.Cancelled == status) {
            return AmberfiCallbackUpgradeable.Status.Cancelled;
        }
        if (Status.Failed == status) {
            return AmberfiCallbackUpgradeable.Status.Failed;
        }
        return AmberfiCallbackUpgradeable.Status.Finalized;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Openzeppelin
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";

/**
 * This smart contract is proprietary and not to be copied or
 * reproduced without the express permission of the Amberfi
 * Platform.
 */
abstract contract AmberfiCallbackUpgradeable is
    Initializable,
    ERC165Upgradeable
{
    uint256[49] private __gap;

    enum Status {
        Pending,
        InProgress,
        Cancelled,
        Failed,
        Finalized
    }

    function __AmberfiCallback_init() internal onlyInitializing {
        __AmberfiCallback_init_unchained();
    }

    function __AmberfiCallback_init_unchained() internal onlyInitializing {
    }

    function encryptContent(
        uint256 itemId_,
        string calldata encryptCid_,
        uint8 storageLocationId_
    ) public virtual {}

    function setContent(
        uint256 itemId_,
        string calldata tempCid_,
        string calldata cid_,
        string calldata cidProof_,
        Status status_
    ) public virtual {}

    /**
     * @inheritdoc ERC165Upgradeable
     */
    function supportsInterface(bytes4 interfaceId_)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceId_ == type(AmberfiCallbackUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId_);
    }
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

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
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
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
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
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
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
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