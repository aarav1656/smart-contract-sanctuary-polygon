// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./ERC4671.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// Uncomment this line to use console.log
// import "hardhat/console.sol";

/**
 * @notice Identity NTT - Non-Tradable Tokens Standard, aka badges or souldbound NFTs (EIP-4671)
 * A non-tradable token, or NTT, represents inherently personal possessions (material or immaterial),
 * such as university diplomas, online training certificates, government issued documents (national id,
 * driving license, visa, wedding, etc.), labels, and so on.
 *
 * @dev A NTT contract is seen as representing one type of certificate delivered by one authority.
 * For instance, one NTT contract for the French National Id, another for Ethereum EIP creators, and so on…
 *
 */
contract IdentityNTT is AccessControl, ERC4671 {
    // Create a new role identifier for the manager role
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER");
    // Create a new role identifier for the team role
    bytes32 public constant TEAM_ROLE = keccak256("TEAM");

    constructor(
        string memory name_,
        string memory symbol_,
        address manager_
    ) ERC4671(name_, symbol_){
        // Grant the admin role to the publisher account
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        // Grant the manager role to the informed manager account
        _setupRole(MANAGER_ROLE, manager_);
        // Sets MANAGER_ROLE as TEAM_ROLE's admin role.
        _setRoleAdmin(TEAM_ROLE, MANAGER_ROLE);
    }

    /**
     * @notice Mint a new NTT credential
     * @param holder Address for whom to assign the token
     * @param data JSON with credential data in the format {atribute: "issuerSignedData",...}
     * @return tokenId Identifier of the minted token
     */
    function mint(address holder, string calldata data)
        external
        virtual
        onlyRole(TEAM_ROLE) returns (uint256 tokenId)
    {
        return _mint(holder,data);
    }

    /// @notice Mark the credential token as revoked
    /// @param tokenId Identifier of the token
    function revoke(uint256 tokenId) external virtual onlyRole(TEAM_ROLE) {
        _revoke(tokenId);
    }


    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControl, ERC4671)
        returns (bool)
    {
        return
            interfaceId == type(AccessControl).interfaceId ||
            interfaceId == type(ERC4671).interfaceId ||
            super.supportsInterface(interfaceId);
    }


    /**
     * Gets the credential metadata
     *
     * @param tokenId credential ID which metadata will be returned
     */
    function getCredential(uint256 tokenId)
        external
        view
        returns (Token memory)
    {
       return _getTokenOrRevert(tokenId);
    }

    /**
     * Return a list of owner's NTTs crendetial metadata
     *
     * @param owner  Address of owner/holder of NTTs
     * @return array of all owner's NTTs metadata
     */
    function getCredentials(address owner) external view returns(Token[] memory){
      uint256[] memory ownersTokensId = _indexedTokenIds[owner];
      Token[] memory result = new Token[](ownersTokensId.length);
      for(uint256 i = 0; i < ownersTokensId.length;i++){
        result[i] = _tokens[ownersTokensId[i]];
      }
      return result;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

import "./IERC4671.sol";
import "./IERC4671Metadata.sol";
import "./IERC4671Enumerable.sol";

abstract contract ERC4671 is IERC4671, IERC4671Metadata, IERC4671Enumerable, ERC165 {
    // Token data
    struct Token {
        address issuer;
        address owner;
        string data;
        bool valid;
    }

    // Mapping from tokenId to token
    mapping(uint256 => Token) internal _tokens;

    // Mapping from owner to token ids
    mapping(address => uint256[]) internal _indexedTokenIds;

    // Mapping from token id to index
    mapping(address => mapping(uint256 => uint256)) private _tokenIdIndex;

    // Mapping from owner to number of valid tokens
    mapping(address => uint256) private _numberOfValidTokens;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Total number of tokens emitted
    uint256 private _emittedCount;

    // Total number of token holders
    uint256 private _holdersCount;

    // Contract creator
    address private _creator;

    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _creator = msg.sender;
    }

    /// @notice Count all tokens assigned to an owner
    /// @param owner Address for whom to query the balance
    /// @return Number of tokens owned by `owner`
    function balanceOf(address owner) public view virtual override returns (uint256) {
      require(
            owner != address(0),
            "ERC4671: address zero is not a valid owner"
        );
        return _indexedTokenIds[owner].length;
    }

    /// @notice Get owner of a token
    /// @param tokenId Identifier of the token
    /// @return Address of the owner of `tokenId`
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        return _getTokenOrRevert(tokenId).owner;
    }

    /// @notice Check if a token hasn't been revoked
    /// @param tokenId Identifier of the token
    /// @return True if the token is valid, false otherwise
    function isValid(uint256 tokenId) public view virtual override returns (bool) {
        return _getTokenOrRevert(tokenId).valid;
    }

    /// @notice Check if an address owns a valid token in the contract
    /// @param owner Address for whom to check the ownership
    /// @return True if `owner` has a valid token, false otherwise
    function hasValid(address owner) public view virtual override returns (bool) {
        return _numberOfValidTokens[owner] > 0;
    }

    /// @return Descriptive name of the tokens in this contract
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /// @return An abbreviated name of the tokens in this contract
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /// @notice URI to query to get the token's metadata
    /// @param tokenId Identifier of the token
    /// @return URI for the token
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        Token storage token = _getTokenOrRevert(tokenId);
        bytes memory baseURI = bytes(_baseURI());
        if (baseURI.length > 0) {
            return string(abi.encodePacked(
                baseURI,
                token.data
            ));
        }
        return "";
    }

    /// @return emittedCount Number of tokens emitted
    function emittedCount() public view override returns (uint256) {
        return _emittedCount;
    }

    /// @return holdersCount Number of token holders
    function holdersCount() public view override returns (uint256) {
        return _holdersCount;
    }

    /// @notice Get the tokenId of a token using its position in the owner's list
    /// @param owner Address for whom to get the token
    /// @param index Index of the token
    /// @return tokenId of the token
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        uint256[] storage ids = _indexedTokenIds[owner];
        require(index < ids.length, "ERC4671: Token does not exist");
        return ids[index];
    }

    /// @notice Get a tokenId by it's index, where 0 <= index < total()
    /// @param index Index of the token
    /// @return tokenId of the token
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        return index;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC4671).interfaceId ||
            interfaceId == type(IERC4671Metadata).interfaceId ||
            interfaceId == type(IERC4671Enumerable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /// @notice Prefix for all calls to tokenURI
    /// @return Common base URI for all token
    function _baseURI() internal pure virtual returns (string memory) {
        return "data:application/json;base64,";
    }

    /// @notice Mark the token as revoked
    /// @param tokenId Identifier of the token
    function _revoke(uint256 tokenId) internal virtual {
        Token storage token = _getTokenOrRevert(tokenId);
        require(token.valid, "Token is already invalid");
        token.valid = false;
        assert(_numberOfValidTokens[token.owner] > 0);
        _numberOfValidTokens[token.owner] -= 1;
        emit Revoked(token.owner, tokenId);
    }

    /// @notice Mint a new token
    /// @param owner Address for whom to assign the token
    /// @param data JSON with credential data in the format {atribute: "issuerSignedData",...}
    /// @return tokenId Identifier of the minted token
    function _mint(address owner, string calldata data) internal virtual returns (uint256 tokenId) {
        tokenId = _emittedCount;
        _mintUnsafe(owner, tokenId, data, true);
        emit Minted(owner, tokenId);
        _emittedCount += 1;
    }

    /// @notice Mint a given tokenId
    /// @param owner Address for whom to assign the token
    /// @param tokenId Token identifier to assign to the owner
    /// @param data JSON with credential data in the format {atribute: "issuerSignedData",...}
    /// @param valid Boolean to assert of the validity of the token
    function _mintUnsafe(address owner, uint256 tokenId, string calldata data, bool valid) internal {
        require(owner != address(0), "ERC4671: mint to the zero address");
        require(_tokens[tokenId].owner == address(0), "Cannot mint an assigned token");
        if (_indexedTokenIds[owner].length == 0) {
            _holdersCount += 1;
        }
        _tokens[tokenId] = Token({issuer: msg.sender, owner: owner, data: data, valid: valid});
        _tokenIdIndex[owner][tokenId] = _indexedTokenIds[owner].length;
        _indexedTokenIds[owner].push(tokenId);
        if (valid) {
            _numberOfValidTokens[owner] += 1;
        }
    }

    /// @return True if the caller is the contract's creator, false otherwise
    function _isCreator() internal view virtual returns (bool) {
        return msg.sender == _creator;
    }

    /// @notice Retrieve a token or revert if it does not exist
    /// @param tokenId Identifier of the token
    /// @return The Token struct
    function _getTokenOrRevert(uint256 tokenId) internal view virtual returns (Token storage) {
        Token storage token = _tokens[tokenId];
        require(token.owner != address(0), "ERC4671: Token does not exist");
        return token;
    }

    /// @notice Remove a token
    /// @param tokenId Token identifier to remove
    function _removeToken(uint256 tokenId) internal virtual {
        Token storage token = _getTokenOrRevert(tokenId);
        _removeFromUnorderedArray(_indexedTokenIds[token.owner], _tokenIdIndex[token.owner][tokenId]);
        if (_indexedTokenIds[token.owner].length == 0) {
            assert(_holdersCount > 0);
            _holdersCount -= 1;
        }
        if (token.valid) {
            assert(_numberOfValidTokens[token.owner] > 0);
            _numberOfValidTokens[token.owner] -= 1;
        }
        delete _tokens[tokenId];
    }

    /// @notice Removes an entry in an array by its index
    /// @param array Array for which to remove the entry
    /// @param index Index of the entry to remove
    function _removeFromUnorderedArray(uint256[] storage array, uint256 index) internal {
        require(index < array.length, "Trying to delete out of bound index");
        if (index != array.length - 1) {
            array[index] = array[array.length - 1];
        }
        array.pop();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

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
        _checkRole(role);
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
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
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
     *
     * May emit a {RoleGranted} event.
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
     *
     * May emit a {RoleRevoked} event.
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
     *
     * May emit a {RoleRevoked} event.
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
     * May emit a {RoleGranted} event.
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
     *
     * May emit a {RoleGranted} event.
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
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
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

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface IERC4671 is IERC165 {
    /// Event emitted when a token `tokenId` is minted for `owner`
    event Minted(address owner, uint256 tokenId);

    /// Event emitted when token `tokenId` of `owner` is revoked
    event Revoked(address owner, uint256 tokenId);

    /// @notice Count all tokens assigned to an owner
    /// @param owner Address for whom to query the balance
    /// @return Number of tokens owned by `owner`
    function balanceOf(address owner) external view returns (uint256);

    /// @notice Get owner of a token
    /// @param tokenId Identifier of the token
    /// @return Address of the owner of `tokenId`
    function ownerOf(uint256 tokenId) external view returns (address);

    /// @notice Check if a token hasn't been revoked
    /// @param tokenId Identifier of the token
    /// @return True if the token is valid, false otherwise
    function isValid(uint256 tokenId) external view returns (bool);

    /// @notice Check if an address owns a valid token in the contract
    /// @param owner Address for whom to check the ownership
    /// @return True if `owner` has a valid token, false otherwise
    function hasValid(address owner) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC4671.sol";

interface IERC4671Metadata is IERC4671 {
    /// @return Descriptive name of the tokens in this contract
    function name() external view returns (string memory);

    /// @return An abbreviated name of the tokens in this contract
    function symbol() external view returns (string memory);

    /// @notice URI to query to get the token's metadata
    /// @param tokenId Identifier of the token
    /// @return URI for the token
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC4671.sol";

interface IERC4671Enumerable is IERC4671 {
    /// @return emittedCount Number of tokens emitted
    function emittedCount() external view returns (uint256);

    /// @return holdersCount Number of token holders  
    function holdersCount() external view returns (uint256);

    /// @notice Get the tokenId of a token using its position in the owner's list
    /// @param owner Address for whom to get the token
    /// @param index Index of the token
    /// @return tokenId of the token
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /// @notice Get a tokenId by it's index, where 0 <= index < total()
    /// @param index Index of the token
    /// @return tokenId of the token
    function tokenByIndex(uint256 index) external view returns (uint256);
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