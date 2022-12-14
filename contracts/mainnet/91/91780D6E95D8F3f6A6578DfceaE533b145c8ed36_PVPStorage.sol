// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./4. Interfaces/IPriceOracle.sol";
import "./4. Interfaces/ICollectionRiders.sol";
/// @title The PVP 1.0 game of Radikal Riders
/// @author Radikal Riders
/// @notice First version of PVP you can play with rider NFT
/// @dev This contract is part of a click to earn game. Users can register into races and dev team is in charge of starting the races. 
contract PVPStorage is AccessControl {

  struct Race {
    uint raceId;
    uint[] riderId;
    uint32[] ridersPoints;
    bytes12 raceType;
    uint32 startingShot;
    uint16 buyinUsdt;
    address[] userList;
    uint rewardAmount;
    uint buyinToken;
    uint winnerRiderId;
    uint jackpot;
    bool claimed;
  }

  mapping(uint => Race) races;
  // buyin is the amount of dollars to pay to participate in a race. Races are categorized by buyin. Jackpot is in tokens
  mapping(uint16 => uint) buyinToJackpot;
  uint32 raceCounter;
  uint[] raceList;
  uint16[] buyinList;
  uint[5] topFiveJackpots;
  uint pvpFee;
  bytes32 public constant RACE_CREATOR = keccak256("RACE_CREATOR");
  address pvpAddress;
  IPriceOracle priceOracleInstance;
  ICollectionRiders ridersInstance;


  // Events

  event Created(uint indexed raceId, bytes12 indexed raceType, uint indexed buyinUsdt, uint startingShot, uint buyinToken);

  constructor (
    address _priceOracleAddress,
    address _collectionRidersAddress,
    address _radikalRiderAdminAddress,
    address _secondRadikalRiderAdminAddress
    )
    AccessControl()
    {
    priceOracleInstance = IPriceOracle(_priceOracleAddress);
    ridersInstance = ICollectionRiders(_collectionRidersAddress);
    _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _grantRole(RACE_CREATOR, _radikalRiderAdminAddress);
    _grantRole(RACE_CREATOR, _secondRadikalRiderAdminAddress);
  }


  /********************************************************
   *                                                      *
   *                   MAIN FUNCTIONS                     *
   *                                                      *
   ********************************************************/

  /// @notice Creates a race of PVP 1.0
  /// @dev this function can only be executed by Radikals team
  /// @param _raceType races are classified by motorbike. And this corresponds to the motorbike in bytes. ["0x43686f707065720000000000", 0x53636f6f7465720000000000, 0x53706f727400000000000000, 0x53757065726d6f7461726400] = ["Chopper", "Scooter", "Sport", "Supermotard"]
  /// @param _buyin registration fee in dollars. 2 decimals need to be introduced. E.g: $5 --> 500
  /// @param _startingShot unixtime when the race will start
  function createRace(bytes12 _raceType, uint16 _buyin, uint32 _startingShot) external {
    require(hasRole(RACE_CREATOR, msg.sender), "PVPStorage: Insufficient rights");
    raceCounter++;
    races[raceCounter].raceId = raceCounter;
    races[raceCounter].raceType = _raceType;
    races[raceCounter].buyinUsdt = _buyin;
    races[raceCounter].buyinToken = priceOracleInstance.getUsdtToToken(_buyin);
    races[raceCounter].startingShot = _startingShot;
    uint16[] memory _buyinList = buyinList;
    bool _existingBuyin;
    for(uint8 i = 0; i < _buyinList.length; i++) {
      if(_buyinList[i] == _buyin) {
        _existingBuyin = true;
        break;
      }
    }
    if(!_existingBuyin) {
      buyinList.push(_buyin);
    }
    
    emit Created(raceCounter, _raceType, _buyin, _startingShot, priceOracleInstance.getUsdtToToken(_buyin));
  }

  function increaseJackpot(uint16 _buyinUSD, uint _jackpotAmount) external isPVP {
    buyinToJackpot[_buyinUSD] += _jackpotAmount;
  }

  function updateRidersPoints(uint _raceId, uint32[] calldata _ridersPoints) external isPVP {
    races[_raceId].ridersPoints = _ridersPoints;
  }

  function updateRaceClaim(uint _raceId) external isPVP {
    races[_raceId].claimed = true;
  }

  function updateRaceWinner(uint _raceId, uint _winnerIndex) external isPVP {
    races[_raceId].winnerRiderId = races[_raceId].riderId[_winnerIndex];
  }

  function updateJackpot(uint _raceId) external isPVP {
    uint jackpot = buyinToJackpot[races[_raceId].buyinUsdt];
    races[_raceId].jackpot = jackpot * 80 / 100 ;
    buyinToJackpot[races[_raceId].buyinUsdt] = jackpot - jackpot * 80 / 100;
  }

  function updateRaceRegister(uint _raceId, uint _riderId, uint _reward, address _user) external isPVP {
    races[_raceId].riderId.push(_riderId);
    races[_raceId].userList.push(_user);
    races[_raceId].rewardAmount = _reward;
  }

  function updateTopJackpots(uint _jackpot) external isPVP {
    uint smallestJackpot;
    uint smallestJackpotIndex = 7;
    for(uint i = 0; i < 5; i++) {
      if(topFiveJackpots[i] <= smallestJackpot) {
        smallestJackpot = topFiveJackpots[i];
        smallestJackpotIndex = i;
      }
    }
    if(smallestJackpot != 7){
      topFiveJackpots[smallestJackpotIndex] = _jackpot;
    }
  }

  /********************************************************
   *                                                      *
   *                    VIEW FUNCTIONS                    *
   *                                                      *
   ********************************************************/

  /// @notice returns the race attributes
  /// @param _raceId Id of race to be checked
  function getRace(uint _raceId) external view returns(Race memory) {
    return races[_raceId];
  }

  function getJackpot(uint16 _buyinUSD) external view returns(uint _jackpot) {
    _jackpot = buyinToJackpot[_buyinUSD];
  }

  /// @notice returns the jackpot for each buyin
  /// @dev there is a set of closed buyin initially set. But Radikal team has the freedom to create new buyin values
  function getBuyinAndJackpots() external view returns(uint16[] memory, uint[] memory) {
    uint16[] memory _buyin =  buyinList;
    uint[] memory _jackpots = new uint[](_buyin.length);
    for(uint i = 0; i < _buyin.length; i++) {
      _jackpots[i] = buyinToJackpot[_buyin[i]];
    }
    return (_buyin, _jackpots);
  }

  /// @notice returns the all races info
  /// @dev used in RadikalLens
  function getAllRaces() external view returns(Race[] memory, ICollectionRiders.RidersAttributes[][] memory) {
    uint32 lastRace = raceCounter;
    Race[] memory _races = new Race[](lastRace);
    ICollectionRiders.RidersAttributes[][]  memory riders = new ICollectionRiders.RidersAttributes[][](lastRace);
    for(uint32 i = 1; i <= lastRace; i++) {
      _races[i-1] = races[i];
      riders[i-1] = ridersInstance.getAttributes(_races[i-1].riderId);
    }
    return (_races, riders);
  }
  
  /// @notice returns top 5 claimed jackpots
  /// @dev used in RadikalLens
  function getPVPTopFiveJackpots() external view returns(uint[5] memory _topFiveClaimedJackpots) {
    _topFiveClaimedJackpots = topFiveJackpots;
  }

  function getPVPFee() external view returns(uint) {
    return pvpFee;
  }
  
  /********************************************************
   *                                                      *
   *                    SET FUNCTIONS                     *
   *                                                      *
   ********************************************************/
   
  /// @notice Updates the startingshot of existing race
  /// @dev this function can only be executed by Radikals team. Context: races can only start if there are more than 2 players. If this condition is not met, Radikal team will postpone the race by using this function and channel user registration to this race
  /// @param _raceId races are classified by motorbike. And this corresponds to the motorbike in bytes. ["0x43686f707065720000000000", 0x53636f6f7465720000000000, 0x53706f727400000000000000, 0x53757065726d6f7461726400] = ["Chopper", "Scooter", "Sport", "Supermotard"]
  /// @param _newStartingShot new unixtime when the race will start
  function setRaceStartingShot(uint _raceId, uint32 _newStartingShot) external {
    require(hasRole(RACE_CREATOR, msg.sender), "PVPStorage: Insufficient rights");
    races[_raceId].startingShot = _newStartingShot;
    races[_raceId].buyinToken = priceOracleInstance.getUsdtToToken(races[_raceId].buyinUsdt);
  }

  /// @notice Sets PVP Address
  /// @dev this function can only be executed by Radikals team
  /// @param _pvpAddress address of pvp smart contract holding funcional part of PVP
  function setPVPAddress(address _pvpAddress) external {
    require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "PVPStorage: Insufficient rights");
    pvpAddress = _pvpAddress;
  }

  /// @notice set address of Radikal PriceOracle
  /// @dev uses Ownable library for access control
  /// @param _priceOracleAddress address of Radikal PriceOracle
  function setPriceOracle(address _priceOracleAddress) external {
    require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "PVPStorage: Insufficient rights");
    priceOracleInstance = IPriceOracle(_priceOracleAddress);
  }

  function setPVPFee(uint _fee) external {
    require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "PVPStorage: Insufficient rights");
    pvpFee = _fee;
  }

	/********************************************************
	*                                                       *
	*                     MODIFIERS                         *
	*                                                       *
	********************************************************/

  	modifier isPVP() {
		require(msg.sender == pvpAddress, "PVP Storage: not PVP address");
	_;}

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICollectionRiders {
	struct RidersAttributes {
    uint riderId;
    uint8 pizzaQuantity;
    uint8 wheel;
    uint8 fairing;
    uint8 clutch;
    uint8 exhaustPipe;
    uint8 turbo;
    uint8 nitro;
    bytes12 motorBike;
    bool inPizzeria;
    bool isPromotionalA;
    bool isFusioned;
    bool isRetired;
    string tokenURI;
    string imageURI;
  }

	function setInPizzeria(uint[] calldata riders) external;
	function getInPizzeria(uint _tokenId) external view returns(bool);
	function getPizzaQuantity(uint _tokenId) external view returns(uint8);
	function isOwner(uint _tokenId, address _user) external view returns(bool);
  function getOwnerOf(uint _tokenId) external view returns(address);
  function getMotorbike(uint _tokenId) external view returns(bytes12);
  function getAttributes(uint[] memory riders) external view returns(RidersAttributes[] memory attributes);
  function mint(address user, RidersAttributes memory attributes) external returns(uint _id);
  function getRiderList(address _user) external view returns(uint[] memory);
  function getTokenURI(uint _tokenId) external view returns (string memory);
  function getImageURI(uint _tokenId) external view returns (string memory);
  function burn(uint _tokenId) external;
  function getIsPromotional(uint _tokenId) external view returns(bool);
  function getIsFusioned(uint _tokenId) external view returns(bool);
  function setRetirement(uint[] calldata riders) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPriceOracle {
  function getTokenToUsdt(uint tokenQuantity) external view returns(uint exchange);
  function getUsdtToToken(uint usdtQuantity) external view returns(uint exchange);
  function getLatestPrice() external view returns (int);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControl.sol)

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
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
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
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
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
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

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