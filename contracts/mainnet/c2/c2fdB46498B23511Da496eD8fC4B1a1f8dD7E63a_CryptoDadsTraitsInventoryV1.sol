// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract CryptoDadsTraitsInventoryV1 is Initializable, OwnableUpgradeable {
    using StringsUpgradeable for string;

    enum DadOrMoms {
        NEITHER,
        DAD,
        MOM
    }

    struct CustomizeItem {
        address owner;
        uint256 marketItemId;
        DadOrMoms dadOrMom;
        bool redeemed;
        uint16 tokenIDSelected;
        bool applied;
        uint256 datetimePurchased;
        uint256 customizationID;
        string redeemAdditionalInfo;
        uint256 datetimeApplied;
    }

    address public marketplaceContract;

    /// @notice moderators (mainly backend) to handle unlisting
    mapping(address => bool) public moderators;

    mapping(address => uint256) public lastCustomizationIDByAddress;
    mapping(address => mapping(uint256 => CustomizeItem))
        public customizationsByAddress;

    struct CustomizationRedemptionRequest {
        address owner;
        uint256 customizationID;
        uint16 tokenIDSelected;
        string redeemAdditionalInfo;
    }
    uint256 public lastCustomizationNeedingApplied;
    uint256 public numberOfCustomizationsApplied;
    mapping(uint256 => CustomizationRedemptionRequest)
        public customizationRedeemQueue;

    bool public redeemsAndResetsPaused;

    /// @notice event emitted when a customization is redeemed
    event CustomizationRedeemed(
        address indexed owner,
        uint256 indexed customizationID,
        uint16 indexed tokenIDSelected,
        string redeemAdditionalInfo
    );

    /// @notice event emitted when a customization is actually approved and applied
    event CustomizationApplied(
        address indexed owner,
        uint256 indexed customizationID,
        uint16 indexed tokenIDSelected,
        string redeemAdditionalInfo
    );

    /// @notice event emitted when a customization that is in redeemed state is reset
    event RedemptionReset(
        address indexed owner,
        uint256 indexed customizationID
    );

    /// @notice event emitted when a customization that is in redeemed state is reset
    event CustomizationDeclined(
        address indexed owner,
        uint256 indexed customizationID,
        uint16 indexed tokenIDSelected,
        string declinedReason
    );

    /// @notice event emitted when the contract is paused or unpaused
    event ContractPause(bool indexed paused);

    modifier onlyModerator() {
        require(moderators[msg.sender], "CryptoDadsMarketplace: NON_MODERATOR");
        _;
    }

    function initialize(address _marketplaceContract) public initializer {
        OwnableUpgradeable.__Ownable_init();
        marketplaceContract = _marketplaceContract;
    }

    function getCustomizationsByAddress(address addressToQuery)
        external
        view
        returns (CustomizeItem[] memory)
    {
        // Return only a user's customizations purchased
        CustomizeItem[] memory items = new CustomizeItem[](
            lastCustomizationIDByAddress[addressToQuery]
        );
        uint256 index = 0;
        // starting at 1 because lastCustomizationIDByAddress gets incremented before the first item is ever added to
        // a person's customization inventory
        for (
            uint256 i = 1;
            i <= lastCustomizationIDByAddress[addressToQuery];
            i++
        ) {
            CustomizeItem storage item = customizationsByAddress[
                addressToQuery
            ][i];
            items[index++] = item;
        }
        return items;
    }

    function redeemCustomization(
        uint256 customizationIndex,
        uint16 tokenToApply,
        string calldata additionalInfo
    ) external {
        require(
            customizationsByAddress[msg.sender][customizationIndex].owner ==
                msg.sender,
            "Not Owner"
        );
        require(
            customizationsByAddress[msg.sender][customizationIndex].redeemed ==
                false,
            "Customization Already Redeemed"
        );
        require(
            customizationsByAddress[msg.sender][customizationIndex].applied ==
                false,
            "Customization Already Applied"
        );
        require(
            redeemsAndResetsPaused == false,
            "Contract is currently paused for redeeming trait redemptions"
        );
        customizationsByAddress[msg.sender][customizationIndex].redeemed = true;
        customizationsByAddress[msg.sender][customizationIndex]
            .tokenIDSelected = tokenToApply;
        customizationsByAddress[msg.sender][customizationIndex]
            .redeemAdditionalInfo = additionalInfo;

        customizationRedeemQueue[
            lastCustomizationNeedingApplied++
        ] = CustomizationRedemptionRequest(
            msg.sender,
            customizationIndex,
            tokenToApply,
            additionalInfo
        );

        emit CustomizationRedeemed(
            msg.sender,
            customizationIndex,
            tokenToApply,
            additionalInfo
        );
    }

    function resetRedemption(uint256 customizationIndex) external {
        require(
            customizationsByAddress[msg.sender][customizationIndex].redeemed &&
                !customizationsByAddress[msg.sender][customizationIndex]
                    .applied,
            "Customization cannot be reset"
        );
        require(
            customizationsByAddress[msg.sender][customizationIndex].owner ==
                msg.sender,
            "Not Owner"
        );
        require(
            redeemsAndResetsPaused == false,
            "Contract is currently paused for resetting trait redemptions"
        );
        customizationsByAddress[msg.sender][customizationIndex]
            .redeemAdditionalInfo = "";
        customizationsByAddress[msg.sender][customizationIndex]
            .tokenIDSelected = 0;
        customizationsByAddress[msg.sender][customizationIndex]
            .redeemed = false;

        for (uint256 i = 0; i <= lastCustomizationNeedingApplied; i++) {
            if (
                customizationRedeemQueue[i].owner == msg.sender &&
                customizationRedeemQueue[i].customizationID ==
                customizationIndex
            ) {
                delete customizationRedeemQueue[i];
                emit RedemptionReset(msg.sender, customizationIndex);
            }
        }
    }

    function applyCustomizations(uint256[] memory customizationQueueIDs)
        external
        onlyModerator
    {
        for (uint256 i; i < customizationQueueIDs.length; i++) {
            CustomizationRedemptionRequest
                storage request = customizationRedeemQueue[i];
            CustomizeItem storage customization = customizationsByAddress[
                request.owner
            ][request.customizationID];
            require(customization.owner == request.owner, "Not Owner");
            require(
                customization.redeemed == true,
                "Customization Not Redeemed by User Yet"
            );
            require(
                customization.applied == false,
                "Customization Already Applied"
            );
            customization.applied = true;
            customization.datetimeApplied = block.timestamp;
            numberOfCustomizationsApplied++;
            delete customizationRedeemQueue[i];

            emit CustomizationApplied(
                request.owner,
                request.customizationID,
                request.tokenIDSelected,
                request.redeemAdditionalInfo
            );
        }
    }

    function declineCustomizations(
        uint256[] memory customizationQueueIDs,
        string[] calldata declineComments
    ) external onlyModerator {
        for (uint256 i; i < customizationQueueIDs.length; i++) {
            CustomizationRedemptionRequest
                storage request = customizationRedeemQueue[i];
            CustomizeItem storage customization = customizationsByAddress[
                request.owner
            ][request.customizationID];
            require(
                customization.redeemed == true,
                "Customization Not Redeemed by User Yet"
            );
            require(
                customization.applied == false,
                "Customization Already Applied"
            );
            customization.redeemed = false;
            customization.tokenIDSelected = 0;
            customization.redeemAdditionalInfo = "";
            delete customizationRedeemQueue[i];
            emit CustomizationDeclined(
                request.owner,
                request.customizationID,
                request.tokenIDSelected,
                declineComments[i]
            );
        }
    }

    function getAllCustomizationsToApply()
        public
        view
        returns (uint256[] memory)
    {
        // There seems to be an issue with the math being off on lastItemId - itemsSold
        // so this pads our array by 6 so there isn't array overrun
        uint256 redeemedItemsCount = lastCustomizationNeedingApplied -
            numberOfCustomizationsApplied;
        uint256[] memory customizationRedemptions = new uint256[](
            redeemedItemsCount
        );
        uint256 index = 0;
        // starting at 1 because lastItemID gets incremented before the first item is ever added to
        // marketItems
        for (uint256 i = 0; i < lastCustomizationNeedingApplied; i++) {
            if (customizationRedeemQueue[i].owner != address(0)) {
                customizationRedemptions[index++] = i;
            }
        }
        return customizationRedemptions;
    }

    function addCustomizationToAddress(
        address owner,
        uint256 marketItemID,
        DadOrMoms dadOrMom
    ) external onlyModerator {
        uint256 lastCustomID = ++lastCustomizationIDByAddress[owner];
        customizationsByAddress[owner][lastCustomID] = CustomizeItem(
            owner,
            marketItemID,
            dadOrMom,
            false,
            0,
            false,
            block.timestamp,
            lastCustomID,
            "",
            0
        );
    }

    /**
     * @dev set moderator address by owner
     * @param moderator address of moderator
     * @param approved true to add, false to remove
     */
    function setModerator(address moderator, bool approved) external onlyOwner {
        require(
            moderator != address(0),
            "CryptoDadsMInventory: INVALID_MODERATOR"
        );
        moderators[moderator] = approved;
    }

    function setPaused(bool paused) external onlyModerator {
        require(
            paused != redeemsAndResetsPaused,
            "Contract already in designated state"
        );
        redeemsAndResetsPaused = paused;
        emit ContractPause(paused);
    }
}

interface IMarketplace {
    /// @notice Marketplace items structure
    struct MarketItem {
        address seller;
        address nftToken;
        uint256 tokenId;
        uint256 amount;
        string name;
        string description;
        string externalURL;
        string itemType; /* ERC721, ERC1155, RAFFLE, ALLOWLIST, EXPERIENCES, etc */
        uint256 price;
        string imageURI;
        bool stakingWalletRequired; // added in V3_0
        uint16 maxPurchasePerWallet; // added in V3_0
    }

    function marketItems(uint256) external view returns (MarketItem memory);
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
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