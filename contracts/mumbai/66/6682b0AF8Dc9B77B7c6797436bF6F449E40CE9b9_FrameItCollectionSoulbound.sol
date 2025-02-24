// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

import "./ERC4671.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "../album/IFrameItAlbum.sol";

contract FrameItCollectionSoulbound is ERC4671 {
    using Strings for uint256;
    
    string private uri;
    address private album;
    address private nft;
    bool private initialized = false;

    uint256 private counterAll;
    uint256 private counterRares;
    uint256 private counterUncommons;
    uint256 private counterCommons;

    uint32 private constant MIN_ALL = 1;
    uint32 private constant MAX_ALL = 10000;
    uint32 private constant MIN_COMMONS = 10001;
    uint32 private constant MAX_COMMONS = 20000;
    uint32 private constant MIN_UNCOMMONS = 20001;
    uint32 private constant MAX_UNCOMMONS = 30000;
    uint32 private constant MIN_RARES = 30001;
    uint32 private constant MAX_RARES = 40000;

    mapping(address => bool) private allMapping;
    mapping(address => bool) private raresMapping;
    mapping(address => bool) private uncommonMapping;
    mapping(address => bool) private commonMapping;

    function initialize(string memory name, string memory symbol, address creator, string memory _uri, address _album, address _nft) external {
        require(initialized == false, "InitializedYet");
        
        uri = _uri;
        album = _album;
        nft = _nft;

        _name = name;
        _symbol = symbol;
        _creator = creator;

        counterAll = MIN_ALL;
        counterRares = MIN_RARES;
        counterUncommons = MIN_UNCOMMONS;
        counterCommons = MIN_COMMONS;

        initialized = true;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _getTokenOrRevert(tokenId);
        bytes memory baseURI = bytes(_baseURI());
        if (baseURI.length > 0) {
            uint256 id = 0;
            if (tokenId >= MIN_ALL && tokenId <= MAX_ALL) id = 1;
            else if (tokenId >= MIN_RARES && tokenId <= MAX_RARES) id = 2;
            else if (tokenId >= MIN_UNCOMMONS && tokenId <= MAX_UNCOMMONS) id = 3;
            else if (tokenId >= MIN_COMMONS && tokenId <= MAX_COMMONS) id = 4;
            return string(abi.encodePacked(
                baseURI,
                uint256(id).toString(),
                ".json"
            ));
        }
        return "";
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return uri;
    }

    function mintBadgeAlbumComplete() external {
        require(IFrameItAlbum(album).checkAlbumComplete(nft, msg.sender) == true, "AlbumNoCompleted");
        require(allMapping[msg.sender] == false, "ClaimedYet");

        _mint(msg.sender, counterAll, true);
        allMapping[msg.sender] = true;
        counterAll++;
    }

    function mintBadgeCommonsComplete() external {
        require(IFrameItAlbum(album).checkAlbumCommonsComplete(nft, msg.sender) == true, "CommonsNoCompleted");
        require(commonMapping[msg.sender] == false, "ClaimedYet");

        _mint(msg.sender, counterCommons, true);
        commonMapping[msg.sender] = true;
        counterCommons++;
    }

    function mintBadgeUncommonsComplete() external {
        require(IFrameItAlbum(album).checkAlbumUncommonsComplete(nft, msg.sender) == true, "UncommonsNoCompleted");
        require(uncommonMapping[msg.sender] == false, "ClaimedYet");

        _mint(msg.sender, counterUncommons, true);
        uncommonMapping[msg.sender] = true;
        counterUncommons++;
    }

    function mintBadgeRaresComplete() external {
        require(IFrameItAlbum(album).checkAlbumRaresComplete(nft, msg.sender) == true, "RaresNoCompleted");
        require(raresMapping[msg.sender] == false, "ClaimedYet");

        _mint(msg.sender, counterRares, true);
        raresMapping[msg.sender] = true;
        counterRares++;
    }

    function hasNFTs(address _user) external view returns(bool fullAlbum, bool commonsAlbum, bool uncommonsAlbum, bool raresAlbum) {
        fullAlbum = allMapping[_user];
        commonsAlbum = commonMapping[_user];
        uncommonsAlbum = uncommonMapping[_user];
        raresAlbum = raresMapping[_user];
    }
}

// SPDX-License-Identifier: CC0-1.0

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

// SPDX-License-Identifier: CC0-1.0

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

// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

import "./IERC4671.sol";
import "./IERC4671Metadata.sol";

abstract contract ERC4671 is IERC4671, IERC4671Metadata, ERC165 {
    // Token data
    struct Token {
        address issuer;
        address owner;
        bool valid;
    }

    // Mapping from tokenId to token
    mapping(uint256 => Token) private _tokens;

    // Mapping from owner to token ids
    mapping(address => uint256[]) private _indexedTokenIds;

    // Mapping from token id to index
    mapping(address => mapping(uint256 => uint256)) private _tokenIdIndex;

    // Mapping from owner to number of valid tokens
    mapping(address => uint256) private _numberOfValidTokens;

    // Token name
    string internal _name;

    // Token symbol
    string internal _symbol;

    // Contract creator
    address internal _creator;

    /// @notice Count all tokens assigned to an owner
    /// @param owner Address for whom to query the balance
    /// @return Number of tokens owned by `owner`
    function balanceOf(address owner) public view virtual override returns (uint256) {
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
        _getTokenOrRevert(tokenId);
        bytes memory baseURI = bytes(_baseURI());
        if (baseURI.length > 0) {
            return string(abi.encodePacked(
                baseURI,
                Strings.toHexString(tokenId, 32),
                ".json"
            ));
        }
        return "";
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return 
            interfaceId == type(IERC4671).interfaceId ||
            interfaceId == type(IERC4671Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /// @notice Prefix for all calls to tokenURI
    /// @return Common base URI for all token
    function _baseURI() internal view virtual returns (string memory) {
        return "";
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

    /// @notice Mint a given tokenId
    /// @param owner Address for whom to assign the token
    /// @param tokenId Token identifier to assign to the owner
    /// @param valid Boolean to assert of the validity of the token 
    function _mint(address owner, uint256 tokenId, bool valid) internal {
        require(_tokens[tokenId].owner == address(0), "Cannot mint an assigned token");

        _tokens[tokenId] = Token(msg.sender, owner, valid);
        _tokenIdIndex[owner][tokenId] = _indexedTokenIds[owner].length;
        _indexedTokenIds[owner].push(tokenId);
        if (valid) {
            _numberOfValidTokens[owner] += 1;
        }

        emit Minted(owner, tokenId);
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
        require(token.owner != address(0), "Token does not exist");
        return token;
    }

    /// @notice Remove a token
    /// @param tokenId Token identifier to remove
    function _removeToken(uint256 tokenId) internal virtual {
        Token storage token = _getTokenOrRevert(tokenId);
        _removeFromUnorderedArray(_indexedTokenIds[token.owner], _tokenIdIndex[token.owner][tokenId]);

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
pragma solidity ^0.8.16;

interface IFrameItAlbum {

    function populateAlbum(address _nftContract, uint32[][] calldata _ids, uint256 _startIndex) external;
    function populateCommonsAlbum(address _nftContract, uint32[][] calldata _ids, uint256 _startIndex) external;
    function populateUncommonsAlbum(address _nftContract, uint32[][] calldata _ids, uint256 _startIndex) external;
    function populateRaresAlbum(address _nftContract, uint32[][] calldata _ids, uint256 _startIndex) external;
    function destroyAlbum(address _nftContract) external;
    function checkAlbumComplete(address _nftContract, address _user) external view returns (bool);
    function checkAlbumCommonsComplete(address _nftContract, address _user) external view returns (bool);
    function checkAlbumUncommonsComplete(address _nftContract, address _user) external view returns (bool);
    function checkAlbumRaresComplete(address _nftContract, address _user) external view returns (bool);
    function getUserAlbumIds(address _nftContract, address _user) external view returns (uint256[] memory);
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