/**
 *Submitted for verification at polygonscan.com on 2022-08-29
*/

// Sources flattened with hardhat v2.9.9 https://hardhat.org

// File @openzeppelin/contracts-upgradeable/utils/[email protected]

// SPDX-License-Identifier: UNLICENSED

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


// File @openzeppelin/contracts-upgradeable/proxy/utils/[email protected]


// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

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


// File @openzeppelin/contracts-upgradeable/utils/[email protected]


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


// File contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;
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
abstract contract Ownable is ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
     function ownable_init() internal initializer {
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
    // function renounceOwnership() public virtual onlyOwner {
    //     _transferOwnership(address(0));
    // }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
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


// File contracts/interface/IEvents.sol

pragma solidity ^0.8.0;

interface IEvents {
    function _exists(uint256 eventTokenId) external view returns(bool);
    function getEventDetails(uint256 tokenId) external view returns(uint256, uint256, address, bool, uint256, uint256);
    function burn(uint256 tokenId) external;
    function getConversionContract() external view returns (address);
    function getVenueContract() external view returns (address);
    function getDeviationPercentage() external view returns (uint256);
    function getTreasuryContract() external view returns (address);
    function checKVenueFees(uint256 venueTokenId, uint256 startTime, uint256 endTime, address eventOrganiser, uint256 eventTokenId,
    address tokenAddress, uint256 feeAmount) external;
    
}


// File contracts/interface/IVenue.sol


pragma solidity ^0.8.0;

interface IVenue {
    //function bookVenue(address eventOrganiser, uint256 eventTokenId, uint256 tokenId, address tokenAddress, uint256 feeAmount, string memory _type, uint256 startTime, uint256 endTime) external payable;
    function getRentalFees(uint256 tokenId) external view returns(uint256 _rentalFees);
    function getTotalCapacity(uint256 tokenId) external view returns(uint256 _totalCapacity);
    function getVenueRentalCommission() external view returns(uint256 _venueRentalCommission);
    function getRentalFeesPerBlock(uint256 tokenId) external view returns(uint256 rentPerBlock);
    function getVenueOwner(uint256 tokenId) external view returns(address payable owner);
    function _exists(uint256 tokenId) external view returns (bool);
}


// File contracts/manageEvent.sol



pragma solidity ^0.8.0;
///@title Manage the events
///@author Prabal Srivastav
///@notice Event owner can start event or can cancel event

contract ManageEvent is Ownable {

    using AddressUpgradeable for address;

    //Details of the agenda
    struct agendaDetails {
        uint256 agendaId;
        uint256 agendaStartTime;
        uint256 agendaEndTime;
        string agenda;
        string[] guestName;
        address[] guestAddress;
        uint8 initiateStatus;
    }

    //mapping for getting agenda details
    mapping(uint256 => agendaDetails[]) public getAgendaInfo;

    //mapping for getting number of agendas
    mapping(uint256 => uint256) public noOfAgendas;

    //mapping for event start status
    mapping(uint256 => bool) public eventStartedStatus;

    //mapping for event cancel status
    mapping(uint256 => bool) public eventCanceledStatus;

    //Event contract address
    address private eventContract;

    ///@param eventTokenId event Token Id
    ///@param agendaId agendaId
    ///@param agendaStartTime agendaStartTime
    ///@param agendaEndTime agendaEndTime
    ///@param agenda agenda
    ///@param guestName[] guest Name 
    ///@param guestAddress[] guest Address
    ///@param initiateStatus Auto(1) or Manual(2)
    event AgendaAdded(uint256 indexed eventTokenId,uint256 agendaId, uint256 agendaStartTime, uint256 agendaEndTime, string agenda, string[] guestName, address[] guestAddress, uint8 initiateStatus);

    ///@param eventTokenId event Token Id
    ///@param payNow pay venue fees now if(didn't pay earlier)
    event EventStarted(uint256 indexed eventTokenId, bool payNow);

    ///@param eventTokenId event Token Id
    event EventCanceled(uint256 indexed eventTokenId);

    ///@param eventTokenId event Token Id
    ///@param agendaId agendaId
    event AgendaStarted(uint256 indexed eventTokenId, uint256 agendaId);

    ///@param eventContract eventContractAddress
    event EventContractUpdated(address eventContract);

    //modifier for checking valid time
    modifier isValidTime(uint256 startTime, uint256 endTime) {
        require(
            startTime < endTime && startTime >= block.timestamp,
            "invalid time input"
        );
        _;
    }

    // modifier for checking event organiser address
    modifier isEventOrganiser(uint256 eventTokenId) {
        (, ,
        address eventOrganiser,
        , ,
        ) = IEvents(getEventContract()).getEventDetails(eventTokenId);
        require(msg.sender == eventOrganiser ,"ManageEvent: Invalid Address");
        _;
    }

     function initialize() public initializer {
        Ownable.ownable_init();
    }

    ///@notice updates eventContract address
    ///@param _eventContract eventContract address
    function updateEventContract(address _eventContract) external onlyOwner {
        require(_eventContract.isContract(),"ManageEvent: Address is not a contract");
        eventContract = _eventContract;
        emit EventContractUpdated(_eventContract);
    }

    ///@notice Add the event guests
    ///@param eventTokenId event Token Id
    ///@param agendaStartTime agendaStartTime
    ///@param agendaEndTime agendaEndTime
    ///@param agenda agenda of the event
    ///@param guestName[] guest Name 
    ///@param guestAddress[] guest Address
    ///@param initiateStatus Auto(1) or Manual(2)
    function addAgenda(uint256 eventTokenId, uint256 agendaStartTime, uint256 agendaEndTime, string memory agenda, string[] memory guestName, address[] memory guestAddress, uint8 initiateStatus) isValidTime(agendaStartTime, agendaEndTime) isEventOrganiser(eventTokenId) external {
        require((IEvents(getEventContract())._exists(eventTokenId)), "ManageEvent: TokenId does not exist");
        (uint256 eventStartTime,
        uint256 eventEndTime,
        , , ,) = IEvents(getEventContract()).getEventDetails(eventTokenId);
        require(agendaStartTime >= eventStartTime && agendaEndTime <= eventEndTime, "ManageEvent: Invalid agenda time" );
        noOfAgendas[eventTokenId]++;
        uint256 agendaId = noOfAgendas[eventTokenId];
        getAgendaInfo[eventTokenId].push(agendaDetails(agendaId,
            agendaStartTime,
            agendaEndTime,
            agenda,
            guestName,
            guestAddress,
            initiateStatus
        ));
        emit AgendaAdded(eventTokenId, agendaId, agendaStartTime, agendaEndTime, agenda, guestName, guestAddress, initiateStatus);
    }

    ///@notice Start the event
    ///@param eventTokenId event Token Id
    ///@param feeToken erc20 tokenAddress
    ///@param venueFeeAmount fee of the venue
    function startEvent(uint256 eventTokenId, address feeToken, uint256 venueFeeAmount) isEventOrganiser(eventTokenId) external payable{
        require((IEvents(getEventContract())._exists(eventTokenId)), "ManageEvent: TokenId does not exist");
        (uint256 startTime,
        uint256 endTime,
        ,
        bool payNow,
        uint256 venueTokenId,) = IEvents(getEventContract()).getEventDetails(eventTokenId);
        require(block.timestamp >= startTime && endTime > block.timestamp, "ManageEvent: Event not live");
        require(eventStartedStatus[eventTokenId] == false, "ManageEvent: Event already started");
        if(payNow == false) {
            IEvents(getEventContract()).checKVenueFees(venueTokenId,
                startTime,
                endTime,
                msg.sender,
                eventTokenId,
                feeToken,
                venueFeeAmount);
            payNow = true;
        }
        eventStartedStatus[eventTokenId] = true;
        emit EventStarted(eventTokenId, payNow);
    }

    ///@notice Cancel the event
    ///@param eventTokenId event Token Id
    function cancelEvent(uint256 eventTokenId) isEventOrganiser(eventTokenId) external {
        require((IEvents(getEventContract())._exists(eventTokenId)), "ManageEvent: TokenId does not exist");
        (uint256 startTime,
        ,
        , , ,) = IEvents(getEventContract()).getEventDetails(eventTokenId);
        require(block.timestamp > startTime, "ManageEvent: Event started");
        require(eventCanceledStatus[eventTokenId] == false, "ManageEvent: Event already canceled");
        //Return amount 
        IEvents(getEventContract()).burn(eventTokenId);
        eventCanceledStatus[eventTokenId] = true;
        emit EventCanceled(eventTokenId);

    }

    ///@notice To initiate a session
    ///@param eventTokenId event Token Id
    ///@param agendaId agendaId
    function initiateSession(uint256 eventTokenId, uint256 agendaId) isEventOrganiser(eventTokenId) external {
        require((IEvents(getEventContract())._exists(eventTokenId)), "ManageEvent: TokenId does not exist");
        require(getAgendaInfo[eventTokenId][agendaId - 1].initiateStatus == 2, "ManageEvent: Auto Session");
        require(block.timestamp >= getAgendaInfo[eventTokenId][agendaId - 1].agendaStartTime, "ManageEvent: Invalid Time");
        emit AgendaStarted(eventTokenId, agendaId);
    }

    ///@notice Returns event contract address
    function getEventContract() public view returns(address){
        return eventContract;
    }

    function isEventCanceled(uint256 eventId) public view returns(bool) {
        return eventCanceledStatus[eventId];
    }

    function isEventStarted(uint256 eventId) public view returns(bool) {
        return eventStartedStatus[eventId];
    }

}
//Event organiser first has to start the event then user can join

// manageContract => addGuest,addAgenda,
// Graph for addGuest, addAgenda
// Web3 for addGuest, addAge
// Graph for event Contract buy, join and //favourite
// Web3 for buy, join and favourite