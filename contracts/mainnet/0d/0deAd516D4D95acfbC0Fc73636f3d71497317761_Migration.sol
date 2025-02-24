// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "../interfaces/OldContracts/IOldTroll.sol";
import "../interfaces/ITroll.sol";
import "../interfaces/OldContracts/IOldForge.sol";
import "../interfaces/IForge.sol";
import "../interfaces/OldContracts/IOldMine.sol";
import "../interfaces/IMine.sol";

contract Migration is OwnableUpgradeable, PausableUpgradeable {

    //
    // Troll Migration
    //
    bool public trollMigrationComplete;
    mapping(uint256 => bool) internal trollMigratedTokens;
    mapping(address => uint256[]) internal trollMigratedOwners;
    address[] private migratedTrollOwners;
    IOldTroll public oldTrollContract;
    ITroll public trollContract;

    mapping(uint256 => bool) private forgeMigratedTokens;
    mapping(address => uint256[]) private migratedForgesByOwner;
    address[] private migratedForgeOwners;
    IOldForge public oldForgeContract;
    IForge public forgeContract;

    mapping(uint256 => bool) private mineMigratedTokens;
    mapping(address => uint256[]) private migratedMinesByOwner;
    address[] private migratedMineOwners;
    IOldMine public oldMineContract;
    IMine public mineContract;
    
    function initialize() initializer public {
        __Ownable_init();
        __Pausable_init();
    }

    //////////////////////
    // Troll Migrations //
    //////////////////////
    function setOldTrollContract(address _oldTrollContractAddress) external onlyOwner {
        oldTrollContract = IOldTroll(_oldTrollContractAddress);
    }

    function setTrollContract(address _trollContractAddress) external onlyOwner {
        trollContract = ITroll(_trollContractAddress);
    }

    // Migrate from old TG tokens to new ones
    function migrateTroll(uint256 _tokenId) public {
        require(oldTrollContract.ownerOf(_tokenId) == _msgSender(), "You must own the original token!");
        require(oldTrollContract.isApprovedForAll(_msgSender(), address(this)), "You must first grant this contract full approval!");
        require(!trollMigratedTokens[_tokenId], "Hey! That one has already been migrated!");
        require(!trollMigrationComplete, "Sorry the migration is complete now");

        // Transfer old token to this contract
        oldTrollContract.transferFrom(_msgSender(), address(this), _tokenId);

        // Mark token as migrated and add to owners migrated collection
        trollMigratedTokens[_tokenId] = true;
        trollMigratedOwners[_msgSender()].push(_tokenId);
        migratedTrollOwners.push(_msgSender());

        // Mint a new token for the sender
        trollContract.migrationMint(_msgSender(), _tokenId);
    }

    function migrateAllTrolls(uint256[] memory tokenIds) external {
        for(uint8 i = 0; i < tokenIds.length; i++) {
            migrateTroll(tokenIds[i]);
        }
    }

    function getMigratedTrollOwners() private view returns (address[] memory owners) {
        return migratedTrollOwners;
    }

    function transferOldTrollTo(address _to, uint256 _tokenId) external onlyOwner {
        require(oldTrollContract.ownerOf(_tokenId) == address(this), "This contract must be the owner of the token");
        oldTrollContract.transferFrom(address(this), _to, _tokenId);
    }

    function isTokenMigrated(uint256 _tokenId) public view returns (bool) {
        return trollMigratedTokens[_tokenId];
    }

    function getMigratedTrolls(address _owner) public view returns (uint256[] memory) {
        return trollMigratedOwners[_owner];
    }

    function setTrollMigrated(uint256 _tokenId, bool _migrated) public onlyOwner {
        trollMigratedTokens[_tokenId] = _migrated;
    }

    function setTrollMigrationComplete(bool _migrationComplete) external onlyOwner {
        trollMigrationComplete = _migrationComplete;
    }

    //////////////////////
    // Forge Migrations //
    //////////////////////

    function setOldForgeContract(address _oldForgeContractAddress) external onlyOwner {
        oldForgeContract = IOldForge(_oldForgeContractAddress);
    }

    function setForgeContract(address _forgeContractAddress) external onlyOwner {
        forgeContract = IForge(_forgeContractAddress);
    }

        // Migrate from old TG forge tokens to new ones
    function migrateForge(uint256 _tokenId) public {
        require(oldForgeContract.ownerOf(_tokenId) == _msgSender(), "You must own the original token!");
        require(oldForgeContract.isApprovedForAll(_msgSender(), address(this)), "You must first grant this contract full approval!");
        require(!forgeMigratedTokens[_tokenId], "Hey! That one has already been migrated!");

        // Transfer old token to this contract
        oldForgeContract.transferFrom(_msgSender(), address(this), _tokenId);

        // Mark token as migrated and add to owners migrated collection
        forgeMigratedTokens[_tokenId] = true;
        migratedForgesByOwner[_msgSender()].push(_tokenId);
        migratedForgeOwners.push(_msgSender());

        // Mint a new token for the sender
        forgeContract.migrationMint(_msgSender());
    }

    function migrateAllForges(uint256[] memory tokenIds) external {
        for(uint8 i = 0; i < tokenIds.length; i++) {
            migrateForge(tokenIds[i]);
        }
    }

    function getMigratedForgeOwners() private view returns (address[] memory owners) {
        return migratedForgeOwners;
    }

    function transferOldForgeTo(address _to, uint256 _tokenId) external onlyOwner {
        require(oldForgeContract.ownerOf(_tokenId) == address(this), "This contract must be the owner of the token");
        oldForgeContract.transferFrom(address(this), _to, _tokenId);
    }

    function isForgeMigrated(uint256 _tokenId) public view returns (bool) {
        return forgeMigratedTokens[_tokenId];
    }

    function getMigratedForges(address _owner) public view returns (uint256[] memory) {
        return migratedForgesByOwner[_owner];
    }

    function setForgeMigrated(uint256 _tokenId, bool _migrated) public onlyOwner {
        forgeMigratedTokens[_tokenId] = _migrated;
    }

    //////////////////////
    // Mine Migrations //
    //////////////////////

    function setOldMineContract(address _oldMineContractAddress) external onlyOwner {
        oldMineContract = IOldMine(_oldMineContractAddress);
    }

    function setMineContract(address _mineContractAddress) external onlyOwner {
        mineContract = IMine(_mineContractAddress);
    }

        // Migrate from old TG mine tokens to new ones
    function migrateMine(uint256 _tokenId) public {
        // require(oldMineContract.ownerOf(_tokenId) == _msgSender(), "You must own the original token!");
        // require(oldMineContract.isApprovedForAll(_msgSender(), address(this)), "You must first grant this contract full approval!");
        // require(!mineMigratedTokens[_tokenId], "Hey! That one has already been migrated!");

        // Transfer old token to this contract
        // oldMineContract.transferFrom(_msgSender(), address(this), _tokenId);

        // Mark token as migrated and add to owners migrated collection
        mineMigratedTokens[_tokenId] = true;
        migratedMinesByOwner[_msgSender()].push(_tokenId);
        migratedMineOwners.push(_msgSender());

        // Mint a new token for the sender
        mineContract.migrationMint(_msgSender());
    }

    function migrateAllMines(uint256[] memory tokenIds) external {
        for(uint8 i = 0; i < tokenIds.length; i++) {
            migrateMine(tokenIds[i]);
        }
    }

    function getMigratedMineOwners() private view returns (address[] memory owners) {
        return migratedMineOwners;
    }

    function transferOldMineTo(address _to, uint256 _tokenId) external onlyOwner {
        require(oldMineContract.ownerOf(_tokenId) == address(this), "This contract must be the owner of the token");
        oldMineContract.transferFrom(address(this), _to, _tokenId);
    }

    function isMineMigrated(uint256 _tokenId) public view returns (bool) {
        return mineMigratedTokens[_tokenId];
    }

    function getMigratedMines(address _owner) public view returns (uint256[] memory) {
        return migratedMinesByOwner[_owner];
    }

    function setMineMigrated(uint256 _tokenId, bool _migrated) public onlyOwner {
        mineMigratedTokens[_tokenId] = _migrated;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
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
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IOldTroll {
    function transferFrom(address from, address to, uint256 tokenId) external;
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function getTokenIds(address _owner) external view returns (uint256[] memory _tokensOfOwner);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface ITroll {
    function migrationMint(address _receiver, uint256 _tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function ownerOf(uint256 tokenId) external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IOldForge {
    function transferFrom(address from, address to, uint256 tokenId) external;
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function getTokenIds(address _owner) external view returns (uint256[] memory _tokensOfOwner);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IForge {
    function migrationMint(address _to) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IOldMine {
    function transferFrom(address from, address to, uint256 tokenId) external;
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function getTokenIds(address _owner) external view returns (uint256[] memory _tokensOfOwner);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IMine {
    function migrationMint(address _to) external;
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