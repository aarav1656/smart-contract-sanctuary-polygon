// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.7;

import "../abstract/AdminAccess.sol";
import "../interfaces/IPriceOracle.sol";
import "../abstract/PriceConverter.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

// import "hardhat/console.sol";

contract GoldOracleTangible is AdminAccess, IPriceOracle, PriceConverter {
    AggregatorV3Interface internal priceFeed;
    struct GoldBar {
        ITangibleNFT gbNft;
        uint256 grams;
        uint256 premiumPercentage; //in percentage: 1234 -> 1.234 %;  50 -> 0.005 USD
        uint256 premiumFixed; // in usdc 60$ -> 60000000
        uint256 weSellAtStock;
        uint256 weBuyAtStock;
    }

    event GoldBarAdded(
        address nft,
        string barName,
        uint256 fingerprint,
        uint256 grams,
        uint256 premiumPrice
    );

    mapping(uint256 => GoldBar) public goldBars;

    uint256 public unz = 311034768; // 7 decimals 31.1034768gr

    constructor(address goldOracle) {
        require(goldOracle != address(0), "Empty address");
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        priceFeed = AggregatorV3Interface(goldOracle);
    }

    function _latestAnswer(uint256 fingerprint)
        internal
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        require(goldBars[fingerprint].grams > 0, "No data for tnft");
        (, int256 price, , , ) = priceFeed.latestRoundData();
        if (price < 0) {
            price = 0;
        }

        uint256 priceForGrams = ((convertToOracleDecimals(
            goldBars[fingerprint].grams,
            0
        ) * uint256(price)) / convertToOracleDecimals(unz, uint8(7)));

        uint256 premium = attachPremium(priceForGrams, fingerprint);

        uint256 lockAmount = ((priceForGrams + premium) *
            goldBars[fingerprint].gbNft.lockPercent(fingerprint)) / 100000;

        return (priceForGrams, premium, lockAmount);
    }

    /// @inheritdoc IPriceOracle
    function latestTimeStamp(uint256 fingerprint)
        external
        view
        override
        returns (uint256)
    {
        require(goldBars[fingerprint].grams > 0, "No data for tnft");
        (, , , uint256 timeStamp, ) = priceFeed.latestRoundData();
        return timeStamp;
    }

    /// @inheritdoc IPriceOracle
    function decimals() external view override returns (uint8) {
        return _decimals();
    }

    function _decimals() internal view returns (uint8) {
        return priceFeed.decimals();
    }

    /// @inheritdoc IPriceOracle
    function description() external view override returns (string memory desc) {
        return priceFeed.description();
    }

    function version() external view override returns (uint256) {
        return priceFeed.version();
    }

    function attachPremium(uint256 priceForGrams, uint256 fingerprint)
        internal
        view
        returns (uint256)
    {
        if (goldBars[fingerprint].premiumFixed > 0) {
            return goldBars[fingerprint].premiumFixed;
        } else {
            return
                calculatePremium(
                    priceForGrams,
                    goldBars[fingerprint].premiumPercentage
                );
        }
    }

    function calculatePremium(uint256 price, uint256 percentage)
        internal
        pure
        returns (uint256)
    {
        //percentage can have 3 decimal places
        //for example 1234 is 1.234%
        return (price * percentage) / 100000;
    }

    function convertToOracleDecimals(uint256 price, uint8 priceDecimals)
        internal
        view
        returns (uint256)
    {
        uint8 localDecimals = _decimals();
        if (uint256(priceDecimals) > localDecimals) {
            return price / (10**(uint256(priceDecimals) - localDecimals));
        } else if (uint256(priceDecimals) < localDecimals) {
            return price * (10**(localDecimals - uint256(priceDecimals)));
        }
        return price;
    }

    // function pricePerGram(uint256 price) internal view returns (uint256) {
    //     uint256 alignedUnz = convertToOracleDecimals(unz, uint8(7));
    //     return price / 31;
    // }

    function decrementSellStock(uint256 fingerprint)
        external
        override
        onlyFactory
    {
        require(goldBars[fingerprint].weSellAtStock > 0, "Already zero sell");
        goldBars[fingerprint].weSellAtStock--;
    }

    function decrementBuyStock(uint256 fingerprint)
        external
        override
        onlyFactory
    {
        require(goldBars[fingerprint].weBuyAtStock > 0, "Already zero buy");
        goldBars[fingerprint].weBuyAtStock--;
    }

    function availableInStock(uint256 fingerprint)
        external
        view
        override
        returns (uint256, uint256)
    {
        return (
            goldBars[fingerprint].weSellAtStock,
            goldBars[fingerprint].weBuyAtStock
        );
    }

    function usdcPrice(
        ITangibleNFT nft,
        uint256 fingerprint,
        uint256 tokenId
    )
        external
        view
        override
        returns (
            uint256 weSellAt,
            uint256 weSellAtStock,
            uint256 weBuyAt,
            uint256 weBuyAtStock,
            uint256 lockedAmount
        )
    {
        require(
            (address(nft) != address(0) && tokenId != 0) || (fingerprint != 0),
            "Must provide fingerpeint or tokenId"
        );
        uint256 localFingerprint = fingerprint;

        if (localFingerprint == 0) {
            localFingerprint = nft.tokensFingerprint(tokenId);
        }
        (
            uint256 _priceOracle,
            uint256 _premium,
            uint256 _lockedAmount
        ) = _latestAnswer(localFingerprint);
        uint8 decimalsLocal = _decimals();
        weSellAt = convertPriceToUSDC(_priceOracle + _premium, decimalsLocal); //plus premium to add
        weBuyAt = convertPriceToUSDC((_priceOracle - _premium), decimalsLocal);
        lockedAmount = convertPriceToUSDC(_lockedAmount, decimalsLocal);
        weSellAtStock = goldBars[localFingerprint].weSellAtStock;
        weBuyAtStock = goldBars[localFingerprint].weBuyAtStock;

        return (weSellAt, weSellAtStock, weBuyAt, weBuyAtStock, lockedAmount);
    }

    function addGoldBar(
        ITangibleNFT nft,
        uint256 fingerprint,
        uint256 grams,
        uint256 premiumPercentage,
        uint256 premiumFixed
    ) external onlyAdmin {
        require(address(nft) != address(0), "Zero nft");
        require(grams > 0, "Zero grams");
        require(
            (premiumPercentage > 0) || (premiumFixed > 0),
            "premium not set"
        );

        if (goldBars[fingerprint].grams > 0) {
            //we update
            goldBars[fingerprint].gbNft = nft;
            goldBars[fingerprint].grams = grams;
            goldBars[fingerprint].premiumPercentage = premiumPercentage;
            goldBars[fingerprint].premiumFixed = premiumFixed;
        } else {
            //we add new
            GoldBar memory gb = GoldBar({
                gbNft: nft,
                grams: grams,
                premiumPercentage: premiumPercentage,
                premiumFixed: premiumFixed,
                weSellAtStock: 0,
                weBuyAtStock: 0
            });
            goldBars[fingerprint] = gb;
        }

        emit GoldBarAdded(
            address(nft),
            nft.name(),
            fingerprint,
            grams,
            premiumPercentage
        );
    }

    function addGoldBarStock(
        uint256 fingerprint,
        uint256 weSellAtStock,
        uint256 weBuyAtStock
    ) external onlyAdmin {
        goldBars[fingerprint].weSellAtStock = weSellAtStock;
        goldBars[fingerprint].weBuyAtStock = weBuyAtStock;
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.7;

import "@openzeppelin/contracts/access/AccessControl.sol";

abstract contract AdminAccess is AccessControl {
    bytes32 public constant FACTORY_ROLE = keccak256("FACTORY");
    /// @dev Restricted to members of the admin role.
    modifier onlyAdmin() {
        require(isAdmin(msg.sender), "Not admin");
        _;
    }

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /// @dev Return `true` if the account belongs to the admin role.
    function isAdmin(address account) internal view returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, account);
    }

    /// @dev Restricted to members of the factory role.
    modifier onlyFactory() {
        require(isFactory(msg.sender), "Not in Factory role!");
        _;
    }

    /// @dev Return `true` if the account belongs to the factory role.
    function isFactory(address account) internal view returns (bool) {
        return hasRole(FACTORY_ROLE, account);
    }

    /// @dev Return `true` if the account belongs to the factory role or admin role.
    function isAdminOrFactory(address account) internal view returns (bool) {
        return isFactory(account) || isAdmin(account);
    }

    modifier onlyFactoryOrAdmin() {
        require(isAdminOrFactory(msg.sender), "NFAR");
        _;
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./ITangibleNFT.sol";

/// @title ITangiblePriceManager interface gives prices for categories added in TangiblePriceManager.
interface IPriceOracle {
    /// @dev The function latest price and latest timestamp when price was updated from oracle.
    function latestTimeStamp(uint256 fingerprint)
        external
        view
        returns (uint256);

    /// @dev The function that returns price decimals from oracle.
    function decimals() external view returns (uint8);

    /// @dev The function that returns rescription for oracle.
    function description() external view returns (string memory desc);

    /// @dev The function that returns version of the oracle.
    function version() external view returns (uint256);

    /// @dev The function that reduces sell stock when token is bought.
    function decrementSellStock(uint256 fingerprint) external;

    /// @dev The function reduces buy stock when we buy token.
    function decrementBuyStock(uint256 fingerprint) external;

    /// @dev The function reduces buy stock when we buy token.
    function availableInStock(uint256 fingerprint)
        external
        returns (uint256 weSellAtStock, uint256 weBuyAtStock);

    /// @dev The function that returns item price.
    function usdcPrice(
        ITangibleNFT nft,
        uint256 fingerprint,
        uint256 tokenId
    )
        external
        view
        returns (
            uint256 weSellAt,
            uint256 weSellAtStock,
            uint256 weBuyAt,
            uint256 weBuyAtStock,
            uint256 lockedAmount
        );
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.7;

abstract contract PriceConverter {
    function convertPriceToUSDC(uint256 price, uint8 decimals)
        internal
        pure
        returns (uint256)
    {
        require(
            decimals > uint8(0) && decimals <= uint8(18),
            "Invalid _decimals"
        );
        if (uint256(decimals) > 6) {
            return price / (10**(uint256(decimals) - 6));
        } else if (uint256(decimals) < 6) {
            return price * (10**(6 - uint256(decimals)));
        }
        return price;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

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
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/introspection/IERC165.sol)

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
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

/// @title ITangibleNFT interface defines the interface of the TangibleNFT
interface ITangibleNFT is IERC721, IERC721Metadata, IERC721Enumerable {
    struct FingerprintData {
        uint256 fingerprint;
        string productId;
    }
    event StoragePricePerYearSet(uint256 oldPrice, uint256 newPrice);
    event StoragePercentagePricePerYearSet(
        uint256 oldPercentage,
        uint256 newPercentage
    );
    event StorageFeeToPay(
        uint256 indexed tokenId,
        uint256 _years,
        uint256 amount
    );
    event ProducedTNFTs(uint256[] tokenId);

    // /// @dev Function allows a Factory to mint tokenId for provided vendorId to the given address(stock storage, usualy marketplace).
    // function produceTNFTtoStock(uint128 vendorId, address toStock, string calldata brandName) external returns (uint256);

    /// @dev Function allows a Factory to mint multiple tokenIds for provided vendorId to the given address(stock storage, usualy marketplace)
    /// with provided count.
    function produceMultipleTNFTtoStock(
        uint128 vendorId,
        uint256 count,
        uint256 fingerprint,
        address toStock
    ) external returns (uint256[] memory);

    /// @dev Function that provides info of how much TNFTs has the vendor produced(minted)
    function vendorProducedTNFTs(uint128 vendorId)
        external
        view
        returns (uint256);

    /// @dev Function that provides lists all TNFTs that vendor ever produced for this category
    function listTNFTsByVendor(uint128 vendorId)
        external
        view
        returns (uint256[] memory);

    /// @dev Function allows the Factory to burn all requested token IDs.
    function destroyTNFTs(uint256[] memory tokenId, address burningFrom)
        external;

    /// @dev The function sets new factory.
    function setFactory(address factory) external;

    /// @dev The function returns whether storage fee is paid for the current time.
    function isStorageFeePaid(uint256 tokenId) external view returns (bool);

    /// @dev The function returns what is the last timestamp of the paid storage.
    function storageEndTime(uint256 tokenId) external view returns (uint256);

    /// @dev The function returns the price per year for storage.
    function storagePricePerYear() external view returns (uint256);

    /// @dev The function returns the percentage of item price that is used for calculating storage.
    function storagePercentagePricePerYear() external view returns (uint256);

    /// @dev The function returns whether storage for the TNFT is paid in fixed amount or in percentage from price
    function storagePriceFixed() external view returns (bool);

    /// @dev The function returns whether storage for the TNFT is required. For example houses don't have storage
    function storageRequired() external view returns (bool);

    /// @dev The function returns the token fingerprint - used in oracle
    function tokensFingerprint(uint256 tokenId) external view returns (uint256);

    /// @dev The function returns the token string id which is tied to fingerprint
    function fingerprintToProductId(uint256 fingerprint)
        external
        view
        returns (string memory);

    /// @dev The function returns the token string id which is tied to fingerprint
    function tokenIdToFingerprintData(uint256 tokenId)
        external
        view
        returns (FingerprintData memory);

    /// @dev The function returns the token string id which is tied to fingerprint
    function addFingerprintsIds(
        uint256[] memory fingerprint,
        string[] memory ids
    ) external;

    /// @dev The function returns lockable percentage of tngbl token e.g. 5000 - 5% 500 - 0.5% 50 - 0.05%.
    function lockPercent(uint256 tokenId) external view returns (uint256);

    ///@dev The function which sets global tnft percentage
    function setTnftPercentage(uint16 percent) external;

    ///@dev The function which sets tnft percentage for specific fingerprint
    function setTnftFingerprintPercentage(uint256 fingerprint, uint16 percent)
        external;

    /// @dev The function accepts takes tokenId, its price and years sets storage and returns amount to pay for.
    function adjustStorageAndGetAmount(
        uint256 tokenId,
        uint256 _years,
        uint256 tokenPrice
    ) external returns (uint256);

    function getFingerprints() external view returns (uint256[] memory);

    function getProductIds() external view returns (string[] memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721.sol)

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
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}