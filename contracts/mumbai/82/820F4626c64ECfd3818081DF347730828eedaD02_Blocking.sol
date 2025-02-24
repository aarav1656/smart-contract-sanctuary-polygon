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
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

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
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
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

/*
    ./Blocking.sol
    v0.2
*/

//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./interfaces/IKUtils.sol";
import "./interfaces/IGroups.sol";
import "./interfaces/IUserProfiles.sol";

contract Blocking is Initializable, PausableUpgradeable, OwnableUpgradeable {

    // Admins
    mapping (address => bool) admins;

    // Maximum amount of records to return on query
    uint256 public maxItemsReturn;

    // The User data struct
    struct UserData {
        mapping (address => bool) whitelist;
        mapping (address => bool) blacklist;
        address[] whitelistDetails;
        address[] blacklistDetails;
        bool usingWhitelist;
    }

    // Map the User Address => User Data
    mapping (address => UserData) public usrBlockingMap;

    // Link the User Profiles contract
    IUserProfiles public userProfiles;

    // Link the Groups contract
    IGroups public Groups;

    // Link the KUtils contract
    IKUtils public KUtils;

    // Canary
    string public canary;

    function initialize(address _kutils, uint256 _maxItemsReturn) initializer public {
        __Pausable_init();
        __Ownable_init();

        // Setup the default Admin
        admins[msg.sender] = true;

        maxItemsReturn = _maxItemsReturn;

        // Setup link to User Profiles
        KUtils = IKUtils(_kutils);
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }


    /*

    EVENTS

    */

    event toggleWhiteListLog(address indexed usrAddress, bool flipped, uint256 indexed groupID);
    event clearListLog(address indexed usrAddress, bool blacklist, uint256 indexed groupID);
    event logWhitelistUpdate(address indexed profileAddress, bool update, uint256 indexed groupID);
    event logBlacklistUpdate(address indexed profileAddress, bool update, uint256 indexed groupID);



    /*

    MODIFIERS

    */

    modifier onlyAdmins() {
        require(admins[msg.sender], "Only admins can call this function.");
        _;
    }

    modifier checkForGroupOwnership(uint256 groupID) {
        // If this is a group validate that they are the owner
        if (groupID > 0){
            // Validate that they are the owner
            require(msg.sender == Groups.getOwnerOfGroupByID(groupID), "You are not the owner of this group");
        }
        _;
    }


    /*

    ADMIN FUNCTIONS

    */

    function pause() public onlyAdmins {
        _pause();
    }

    function unpause() public onlyAdmins {
        _unpause();
    }

    function updateAdmin(address admin, bool status) public onlyAdmins {
        admins[admin] = status;
    }

    function updateContracts(address _kutils, address _userProfiles, address _groups) public onlyAdmins {
        // Update the Groups contract address
        KUtils = IKUtils(_kutils);

        // Update the User Profiles contract address
        userProfiles = IUserProfiles(_userProfiles);

        // Update the Groups contract address
        Groups = IGroups(_groups);
    }


    /*

    BLACK & WHITE LISTS

    */

    function isAllowed(address requesterAddress, address targetAddress) public view whenNotPaused returns (bool){
        // If they're using the whitelist
        if (usrBlockingMap[targetAddress].usingWhitelist) {
            // Check to make sure they're allowed
            if (usrBlockingMap[targetAddress].whitelist[requesterAddress]){
                return true;
            }
        } else {
            // or not blacklisted if not using the whitelist
            if (!usrBlockingMap[targetAddress].blacklist[requesterAddress]){
                return true;
            }
        }

        return false;
    }


    // usrAddress - the address of the user to get the black or whitelist of users from
    // blackList - true = black list / false = white list
    function getList(address usrAddress, bool blackList, uint256 startFrom) public view whenNotPaused returns(address[] memory) {
        
        uint256 listTotal = blackList ? usrBlockingMap[usrAddress].blacklistDetails.length : usrBlockingMap[usrAddress].whitelistDetails.length;

        // If they pass a 0, then return newest set
        if (startFrom == 0){
            startFrom = listTotal;
            if (startFrom != 0){
                startFrom -= 1;
            } else {
                // It's empty, so end
                address[] memory empty = new address[](0);
                return empty;
            }
        }

        // Initialize the count as empty;
        uint256 returnCount = maxItemsReturn;

        if (startFrom < maxItemsReturn){
            returnCount = startFrom + 1;
        }

        // Start the array
        address[] memory blockList = new address[](returnCount);

        // Counter to keep track of iterations since we're listing in reverse
        uint counter = 0;

        // Loop through all items in the array up to max return amount
        for (uint i=(startFrom + 1); i > (startFrom + 1 - returnCount); i--) {
            blockList[counter] = blackList ? usrBlockingMap[usrAddress].blacklistDetails[i - 1] : usrBlockingMap[usrAddress].whitelistDetails[i - 1];
            counter += 1;
        }

        return blockList;
    }


    // Toggle the using of a whitelist on / off
    // Can pass in optional groupID if this is a group being managed
    function toggleWhiteList(uint256 groupID) public checkForGroupOwnership(groupID) whenNotPaused {

        address profileAddress = msg.sender;

        // If this is a group validate that they are the owner
        if (groupID > 0){
            profileAddress = Groups.getGroupAddressFromID(groupID);
        }

        // If they're using the whitelist
        if (usrBlockingMap[profileAddress].usingWhitelist) {
            // Disable it
            usrBlockingMap[profileAddress].usingWhitelist = false;

            // Log it
            emit toggleWhiteListLog(profileAddress, false, groupID);
        } else {
            // enable it
            usrBlockingMap[profileAddress].usingWhitelist = true;

            // Log it
            emit toggleWhiteListLog(profileAddress, true, groupID);
        }
    }


    // Clear out an entire whitelist or blacklist in one call
    // Can pass in optional groupID if this is a group being managed
    function clearList(bool clearWhitelist, uint256 groupID) public checkForGroupOwnership(groupID) whenNotPaused {

        address profileAddress = msg.sender;

        // If this is a group validate that they are the owner
        if (groupID > 0){
            profileAddress = Groups.getGroupAddressFromID(groupID);
        }

        // Clear the whitelist if flagged true
        if (clearWhitelist) {
            // Wipe it out
            delete usrBlockingMap[profileAddress].whitelistDetails;
        } else {
            // wipe out the blacklist
            delete usrBlockingMap[profileAddress].whitelistDetails;
        }

        // Log it
        emit clearListLog(profileAddress, clearWhitelist, groupID);
    }


    // Whitelist = NO ONE can message owner EXCEPT for addresses explicitly allowed here by the owner
    // Toggle an address to be on / off the whitelist
    // Can pass in optional groupID if this is a group being managed
    function updateWhitelist(address toToggle, uint256 groupID) public checkForGroupOwnership(groupID) whenNotPaused {

        address profileAddress = _getProfileAddress(groupID);
        
        // Stringify the address
        string memory addressString = KUtils._toLower(KUtils.addressToString(toToggle));

        // If it's added, remove it
        if(usrBlockingMap[profileAddress].whitelist[toToggle] == true){
            // Set to false
            usrBlockingMap[profileAddress].whitelist[toToggle] = false;

            // Remove it from the array
            uint256 place = 0;
            for (uint i=0; i < usrBlockingMap[profileAddress].whitelistDetails.length; i++) {
                if (KUtils.stringsEqual(KUtils.addressToString(usrBlockingMap[profileAddress].whitelistDetails[i]), addressString)){
                    place = i;
                    break;
                }
            }

            // Swap the last entry with this one
            usrBlockingMap[profileAddress].whitelistDetails[place] = usrBlockingMap[profileAddress].whitelistDetails[usrBlockingMap[profileAddress].whitelistDetails.length-1];

            // Remove the last element
            usrBlockingMap[profileAddress].whitelistDetails.pop();

            // Log it
            emit logWhitelistUpdate(profileAddress, false, groupID);
        } else {
            // Else it's not added so add it
            usrBlockingMap[profileAddress].whitelist[toToggle] = true;
            usrBlockingMap[profileAddress].whitelistDetails.push(toToggle);

            // Log it
            emit logWhitelistUpdate(profileAddress, true, groupID);
        }
    }


    // Blacklist = EVERYONE can message owner EXCEPT for addresses explicitly denied here by the owner
    // Toggle an address to be on / off the blacklist
    // Can pass in optional groupID if this is a group being managed
    function updateBlacklist(address toToggle, uint256 groupID) public checkForGroupOwnership(groupID) whenNotPaused {

        address profileAddress = _getProfileAddress(groupID);
        
        // Stringify the address
        string memory addressString = KUtils.addressToString(toToggle);

        // If it's added, remove it
        if(usrBlockingMap[profileAddress].blacklist[toToggle] == true){
            // Set to false
            usrBlockingMap[profileAddress].blacklist[toToggle] = false;

            // Remove it from the array
            uint256 place = 0;
            for (uint i=0; i < usrBlockingMap[profileAddress].blacklistDetails.length; i++) {
                if (KUtils.stringsEqual(KUtils.addressToString(usrBlockingMap[profileAddress].blacklistDetails[i]), addressString)){
                    place = i;
                    break;
                }
            }

            // Swap the last entry with this one
            usrBlockingMap[profileAddress].blacklistDetails[place] = usrBlockingMap[profileAddress].blacklistDetails[usrBlockingMap[profileAddress].blacklistDetails.length-1];

            // Remove the last element
            usrBlockingMap[profileAddress].blacklistDetails.pop();

            // Log it
            emit logBlacklistUpdate(profileAddress, true, groupID);
        } else {
            // Else it's not added so add it
            usrBlockingMap[profileAddress].blacklist[toToggle] = true;
            usrBlockingMap[profileAddress].blacklistDetails.push(toToggle);

            // Log it
            emit logBlacklistUpdate(profileAddress, true, groupID);
        }
    }

    function _getProfileAddress(uint256 groupID) internal view whenNotPaused returns (address) {
        // If this is a group validate that they are the owner
        if (groupID > 0){
            return Groups.getGroupAddressFromID(groupID);
        } else {
            return msg.sender;
        }
    }

    function updateCanary(string memory _canary) public onlyAdmins{
        canary = _canary;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IGroups {

    struct GroupDetails {
        address ownerAddress;
        address[] members;
        string groupName;
        address groupAddress;
        string details;
        string uri;
        string[3] colors;
    }

    // Function to set group details on initial mint
    function setInitialDetails(uint256 _groupID, address _owner, string memory groupName, address setInitialDetails) external;

    // Get group owner address by Group ID
    function getOwnerOfGroupByID(uint256 groupID) external view returns (address);

    // Get a list of members of a group
    function getMembersOfGroupByID(uint256 groupID) external view returns (address[] memory);

    // Check if a user is a member of a group
    function isMemberOfGroupByID(uint256 groupID, address member) external view returns (bool);

    // Get a Group ID from the Group Name
    function getGroupID(string calldata groupName) external view returns (uint256);

    // Get a generated Group Address from a Group ID
    function getGroupAddressFromID(uint256 groupID) external view returns (address);

    // Get Group Name from a Group ID
    function getGroupNameFromID(uint256 groupID) external view returns (string memory);

    // Get Group Details from a Group ID
    function getGroupDetailsFromID(uint256 groupID) external view returns (string memory);

    // Get Group URI from a Group ID
    function getGroupURIFromID(uint256 groupID) external view returns (string memory);

    // Get Avatar Colors from a Group ID
    function getGroupColorsFromID(uint256 groupID) external view returns (string[3] memory);

    // Get a group ID from their generated address
    function getGroupIDFromAddress(address groupAddress) external view returns (uint256);

    // Get the owner address of a group by the group address
    function getOwnerOfGroupByAddress(address groupAddress) external view returns (address);

    // Check if a group is available
    function isGroupAvailable(string calldata groupName) external view returns (bool);

    // Get Group Details
    function groupDetails(uint256 groupID) external view returns (GroupDetails memory);

    // Update Group Ownership on Token transfer (only callable from Token contract overrides)
    function onTransfer(address from, address to, uint256 tokenId) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface IKUtils {
    // Append a string
    function append(string memory a, string memory b, string memory c, string memory d, string memory e) external pure returns (string memory);

    // Convert an address to a string
    function addressToString(address addr) external pure returns (string memory);

    // Is a valid URI
    function isValidURI(string memory str) external pure returns (bool);

    // Is a valid string
    function isValidString(string memory str) external pure returns (bool);

    // Is a valid string for group names
    function isValidGroupString(string memory str) external pure returns (bool);

    // Convert a uint to string
    function toString(uint256 value) external pure returns (string memory);

    // Returns a lowercase version of the string provided
    function _toLower(string memory str) external pure returns (string memory);

    // Check if 2 strings are the same
    function stringsEqual(string memory a, string memory b) external pure returns (bool);

    // Check literal string length (10x gas cost)
    function strlen(string memory s) external pure returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IUserProfiles {

    // Update the post count for a user
    function updatePostCount(address posterAddress, bool isComment) external;

    // Log a post to the contract
    function recordPost(address posterAddress, uint256 tipPerTag, address[] calldata tipReceivers, uint256 isCommentOf) external;

    // Update a users tips sent/received
    function updateUserTips(address targetAddress, uint256 tipsReceived, uint256 tipsSent) external;

    // Update a user profile
    function updateProfile(string calldata handle, string calldata location, string calldata avatar, string calldata _uri, string calldata _bio, bool isGroup) external;

    // Get the profile details of a user
    function getUserDetails(address usrAddress) external view returns(string[] memory);

    // Get a list of addresses that a user is following
    function getFollowings(address posterAddress, uint256 startFrom) external view returns(address[] memory);

    // Get a list of addresses that are following a user
    function getFollowers(address usrAddress, uint256 startFrom) external view returns(string memory);

    // Follow a user
    function followUser(address addressRequester, address addressToFollow) external;

    // Unfollow a user
    function unfollowUser(address addressRequester, address addressToUnfollow) external;

    // Update a users handle and verification level
    function updateHandleVerify(address userAddress, string calldata handle, uint256 verified) external;

    // Update a new groups profiles details
    function setupNewGroup(address groupAddress, string memory groupName, uint256 groupID, address _nftContract) external;

    // Update profile token metadata
    function updateMetadata(address _address, string memory _metadata) external;

    // Update a users avatar
    function setAvatar(address profileAddress, string calldata imageURI, address _nftContract, uint256 tokenId, string calldata metadata, uint256 _networkID) external;
}