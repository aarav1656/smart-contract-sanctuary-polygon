// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "./ContextMixin.sol";
import "./CounterWithLimits.sol";

contract MGC is ERC721URIStorage, Ownable, ContextMixin  {
    enum TokenType {MASTER, RARE, PREMIUM, STANDARD, BASIC}

    struct Properties {
        string name;
        TokenType tokenType;
        uint256 balance;
        bool isActive;
        string activePlan;
        uint256[] referralIds;
        uint256 distributorId;
        uint256 reward;
        string imageUri;
        uint256 tokenId;
        string description;
    }

    using CountersWithLimits for CountersWithLimits.Counter;
    using Strings for uint256;
    using Strings for uint8;

    uint256 public constant MAX_MASTER = 500;
    uint256 public constant MAX_RARE = 2000;
    uint256 public constant MAX_PREMIUM = 5000;
    uint256 public constant MAX_STANDARD = 10000;
    string public constant NAME_PREFIX = "Masterwork #";

    string[5] private tokenTypeNames = ["Master", "Rare", "Premium", "Standard", "Basic"];
    mapping(TokenType => CountersWithLimits.Counter) private tokenCounters;
    mapping(TokenType => mapping(TokenType => uint256)) private salesRewards;
    mapping(uint256 => Properties) private tokenIdToProperties;

    /// @dev Base token URI used as a prefix by tokenURI().
    string public baseTokenURI;
    string public baseImageURI;
    string public baseRefLink1URI;
    string public baseRefLink2URI;
    string public imageFormat = 'jpg';

    string public contractDescription;
    string public contractName;
    string public contractLink;

    constructor(string memory _baseImageURI) ERC721("Maxwell Masterworks", "MGC") {
        baseTokenURI = "";
        baseImageURI = _baseImageURI;
        baseRefLink1URI = "https://opensea.io/collection/maxwell-masterworks?search[stringTraits][0][name]=Distributor&search[stringTraits][0][values][0]=";
        baseRefLink2URI = "https://rarible.com/maxwell-masterworks/items?filter[filter][traits][Distributor][key]=Distributor&filter[filter][traits][Distributor][values][]=";
        tokenCounters[TokenType.MASTER].setMaxValue(MAX_MASTER);
        tokenCounters[TokenType.RARE].setValue(MAX_MASTER);
        tokenCounters[TokenType.RARE].setMaxValue(MAX_RARE);
        tokenCounters[TokenType.PREMIUM].setValue(MAX_RARE);
        tokenCounters[TokenType.PREMIUM].setMaxValue(MAX_PREMIUM);
        tokenCounters[TokenType.STANDARD].setValue(MAX_PREMIUM);
        tokenCounters[TokenType.STANDARD].setMaxValue(MAX_STANDARD);
        tokenCounters[TokenType.BASIC].setValue(MAX_STANDARD);

        salesRewards[TokenType.MASTER][TokenType.RARE] = 100;
        salesRewards[TokenType.MASTER][TokenType.PREMIUM] = 50;
        salesRewards[TokenType.MASTER][TokenType.STANDARD] = 25;

        salesRewards[TokenType.RARE][TokenType.RARE] = 50;
        salesRewards[TokenType.RARE][TokenType.PREMIUM] = 25;
        salesRewards[TokenType.RARE][TokenType.STANDARD] = 10;

        salesRewards[TokenType.PREMIUM][TokenType.PREMIUM] = 10;
        salesRewards[TokenType.PREMIUM][TokenType.STANDARD] = 5;

        salesRewards[TokenType.STANDARD][TokenType.STANDARD] = 2;

        contractDescription = "Each NFT token in this collection has two values. On the one hand this is a unique artwork made by Maxwell Studio and on the other hand it servers as a digital voucher bound to one or more business positions in Maxwell Capital Earning Programs.";
        contractName = "Maxwell Masterworks";
        contractLink = "https://capital.mgc24.com";
    }

    function setMasterRewards(uint256 rareReward, uint256 premiumReward, uint256 standardReward) external onlyOwner {
        salesRewards[TokenType.MASTER][TokenType.RARE] = rareReward;
        salesRewards[TokenType.MASTER][TokenType.PREMIUM] = premiumReward;
        salesRewards[TokenType.MASTER][TokenType.STANDARD] = standardReward;
    }

    function setRareRewards(uint256 rareReward, uint256 premiumReward, uint256 standardReward) external onlyOwner {
        salesRewards[TokenType.RARE][TokenType.RARE] = rareReward;
        salesRewards[TokenType.RARE][TokenType.PREMIUM] = premiumReward;
        salesRewards[TokenType.RARE][TokenType.STANDARD] = standardReward;
    }

    function setPremiumRewards(uint256 premiumReward, uint256 standardReward) external onlyOwner {
        salesRewards[TokenType.PREMIUM][TokenType.PREMIUM] = premiumReward;
        salesRewards[TokenType.PREMIUM][TokenType.STANDARD] = standardReward;
    }

    function setStandardRewards(uint256 standardReward) external onlyOwner {
        salesRewards[TokenType.STANDARD][TokenType.STANDARD] = standardReward;
    }

    function isApprovedForAll(address _owner, address _operator) public override view returns (bool isOperator) {
        // if OpenSea's ERC721 Proxy Address is detected, auto-return true
        if (_operator == address(0x58807baD0B376efc12F5AD86aAc70E78ed67deaE)) {
            return true;
        }

        // otherwise, use the default ERC721.isApprovedForAll()
        return ERC721.isApprovedForAll(_owner, _operator);
    }

    function _msgSender() internal override view returns (address sender) {
        return ContextMixin.msgSender();
    }

    function getTokenURI(Properties memory tokenProperties, bool replaceDescription) internal view returns (string memory) {
        string memory referrals;
        for (uint256 i=0; i < tokenProperties.referralIds.length; i++) {
            bytes memory previousText = bytes(referrals);
            referrals = string(abi.encodePacked(previousText.length == 0 ? '' : string(abi.encodePacked(referrals,', ')), '#', tokenProperties.referralIds[i].toString()));
        }
        bytes memory attributes = abi.encodePacked(
            '{',
                '"trait_type": "Type",',
                '"value": "', tokenTypeNames[(uint256)(tokenProperties.tokenType)], '",',
                '"order": 1',
            '},',
            '{',
                '"trait_type": "Balance",',
                '"value": "', tokenProperties.balance.toString(),' \u20AC",',
                '"order": 0',
            '},',
            '{',
                '"trait_type": "Status",',
                '"value": "', tokenProperties.isActive ? 'Active",' : 'Not active",',
                '"order": 2',
            '},',
            '{',
                '"trait_type": "Active Plan",',
                '"value": "', tokenProperties.activePlan,'",',
                '"order": 3',
            '},',
            '{',
                '"trait_type": "Distributor",',
                '"value": "', tokenProperties.distributorId == 0 ? '-' : string(abi.encodePacked('', tokenProperties.distributorId.toString())),'",',
                '"order": 4',
            '},',
            '{',
                '"trait_type": "Referrals",',
                '"value": "', tokenProperties.referralIds.length == 0 ? '-' : referrals,'",',
                '"order": 5',
            '},',
            '{',
                '"trait_type": "Plan Reward",',
                '"value": "', tokenProperties.reward.toString(),' \u20AC",',
                '"order": 7',
            '}'
        );

        if (tokenProperties.tokenType != TokenType.BASIC) {
            attributes = abi.encodePacked(attributes,',',getRewardAttributes(tokenProperties.tokenType));
        }

        bytes memory dataURI = abi.encodePacked(
            '{',
                '"name": "', tokenProperties.name, '",',
                '"description": "', buildTokenDescription(tokenProperties, replaceDescription), '",',
                '"external_url": "', buildTokenExternalLink(tokenProperties.tokenId), '",',
                '"image": "', tokenProperties.imageUri, '",',
                '"attributes" : [', attributes, ']',
            '}'
        );

        return string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(dataURI)
            )
        );
    }

    function getTokenURI(Properties memory tokenProperties) internal view returns (string memory) {
        return getTokenURI(tokenProperties, false);
    }

    function buildTokenDescription(Properties memory tokenProperties, bool replaceDescription) internal view returns (bytes memory) {
        if (replaceDescription) {
            return bytes(tokenProperties.description);
        }

        bytes memory reflink1 = abi.encodePacked(baseRefLink1URI, tokenProperties.tokenId.toString());
        bytes memory reflink2 = abi.encodePacked(baseRefLink2URI, tokenProperties.tokenId.toString());

        bytes memory propDescription = bytes(tokenProperties.description);
        bytes memory resultDescription = abi.encodePacked('Balance: ',tokenProperties.balance.toString(),' \u20AC | Plan: ',tokenProperties.activePlan,' | Type: ',tokenTypeNames[(uint256)(tokenProperties.tokenType)],'\\n\\nInfo: ',buildTokenExternalLink(tokenProperties.tokenId));
        if (propDescription.length > 0) {
            resultDescription = abi.encodePacked(resultDescription, '\\n\\n__________', propDescription);
        }

        resultDescription = abi.encodePacked(resultDescription, '\\n\\nReferral Links:\\n', reflink1, '\\n\\n', reflink2, '\\n\\nThe referral collection becomes active once you buy this token.');

        return resultDescription;
    }

    function buildTokenExternalLink(uint256 tokenId) internal view returns (bytes memory) {
        return abi.encodePacked(contractLink,'/nft/',Strings.toHexString(uint160(address(this)), 20),'/', tokenId.toString());
    }

    function updateTokenDescription(uint256 itemId, string calldata description, bool fullReplace) external onlyOwner {
        require(
            tokenIdToProperties[itemId].tokenId != 0,
            string(abi.encodePacked("Token does not exist, you should mint it at first. Not found Token ID: ", itemId.toString()))
        );
        Properties storage properties = tokenIdToProperties[itemId];
        properties.description = description;

        _setTokenURI(itemId, getTokenURI(properties, fullReplace));
    }

    function getRewardAttributes(TokenType tokenType) internal view returns (bytes memory) {
        bytes memory rewards;
        if (tokenType == TokenType.STANDARD) {
            rewards = abi.encodePacked(
                '{',
                    '"trait_type": "Standard Sales Reward",',
                    '"value": "', salesRewards[tokenType][tokenType].toString(),'%"',
                '}'
            );
        } else if (tokenType == TokenType.PREMIUM) {
            rewards = abi.encodePacked(
                '{',
                    '"trait_type": "Premium Sales Reward",',
                    '"value": "', salesRewards[tokenType][tokenType].toString(),'%"',
                '},',
                '{',
                    '"trait_type": "Standard Sales Reward",',
                    '"value": "', salesRewards[tokenType][TokenType.STANDARD].toString(),'%"',
                '}'
            );
        } else {
            rewards = abi.encodePacked(
                '{',
                    '"trait_type": "Rare Sales Reward",',
                    '"value": "', salesRewards[tokenType][TokenType.RARE].toString(),'%"',
                '},',
                '{',
                    '"trait_type": "Premium Sales Reward",',
                    '"value": "', salesRewards[tokenType][TokenType.PREMIUM].toString(),'%"',
                '},',
                '{',
                    '"trait_type": "Standard Sales Reward",',
                    '"value": "', salesRewards[tokenType][TokenType.STANDARD].toString(),'%"',
                '}'
            );
        }

        return rewards;
    }

    function setTokenCounterValue(TokenType tokenType, uint256 value) external onlyOwner returns (uint256) {
        tokenCounters[tokenType].setValue(value);

        return value;
    }

    function setReferralLinkBaseUri(string memory link1, string memory link2) external onlyOwner {
        baseRefLink1URI = link1;
        baseRefLink2URI = link2;
    }

    function initTokenProperties(uint256 itemId, TokenType tokenType, uint256 balance, string calldata plan, uint256 distributorId, string memory description) internal onlyOwner {
        tokenIdToProperties[itemId] = Properties ({
            name: string(abi.encodePacked(NAME_PREFIX, itemId.toString())),
            tokenType: tokenType,
            balance: balance,
            isActive: false,
            activePlan: plan,
            referralIds: new uint256[](0),
            distributorId: distributorId,
            reward: 0,
            imageUri: string(abi.encodePacked(baseImageURI, itemId.toString(), '.', imageFormat)),
            tokenId: itemId,
            description : description
        });

        _setTokenURI(itemId, getTokenURI(tokenIdToProperties[itemId]));
    }

    function updateTokenProperties(Properties memory _properties) external onlyOwner {
        require(
            tokenIdToProperties[_properties.tokenId].tokenId != 0,
            string(abi.encodePacked("Token does not exist, you should mint it at first. Not found Token ID: ", _properties.tokenId.toString()))
        );
        tokenIdToProperties[_properties.tokenId] = _properties;
        _setTokenURI(_properties.tokenId, getTokenURI(_properties));
    }

    function updateTokenName(uint256 itemId, string calldata name) external onlyOwner {
        require(
            tokenIdToProperties[itemId].tokenId != 0,
            string(abi.encodePacked("Token does not exist, you should mint it at first. Not found Token ID: ", itemId.toString()))
        );
        Properties storage properties = tokenIdToProperties[itemId];
        properties.name = name;

        _setTokenURI(itemId, getTokenURI(properties));
    }

    function updateTokenBalance(uint256 itemId, uint256 balance) external onlyOwner {
        require(
            tokenIdToProperties[itemId].tokenId != 0,
            string(abi.encodePacked("Token does not exist, you should mint it at first. Not found Token ID: ", itemId.toString()))
        );
        Properties storage properties = tokenIdToProperties[itemId];
        properties.balance = balance;

        _setTokenURI(itemId, getTokenURI(properties));
    }

    function updateTokenStatus(uint256 itemId, bool isActive) external onlyOwner {
        require(
            tokenIdToProperties[itemId].tokenId != 0,
            string(abi.encodePacked("Token does not exist, you should mint it at first. Not found Token ID: ", itemId.toString()))
        );
        Properties storage properties = tokenIdToProperties[itemId];
        properties.isActive = isActive;

        _setTokenURI(itemId, getTokenURI(properties));
    }

    function updateTokenActivePlan(uint256 itemId, string calldata plan) external onlyOwner {
        require(
            tokenIdToProperties[itemId].tokenId != 0,
            string(abi.encodePacked("Token does not exist, you should mint it at first. Not found Token ID: ", itemId.toString()))
        );
        Properties storage properties = tokenIdToProperties[itemId];
        properties.activePlan = plan;

        _setTokenURI(itemId, getTokenURI(properties));
    }

    function updateTokenReferrals(uint256 itemId, uint256[] calldata referralIds) external onlyOwner {
        require(
            tokenIdToProperties[itemId].tokenId != 0,
            string(abi.encodePacked("Token does not exist, you should mint it at first. Not found Token ID: ", itemId.toString()))
        );
        Properties storage properties = tokenIdToProperties[itemId];
        properties.referralIds = referralIds;

        _setTokenURI(itemId, getTokenURI(properties));
    }

    function updateTokenDistributor(uint256 itemId, uint256 distributorId) external onlyOwner {
        require(
            tokenIdToProperties[itemId].tokenId != 0,
            string(abi.encodePacked("Token does not exist, you should mint it at first. Not found Token ID: ", itemId.toString()))
        );
        Properties storage properties = tokenIdToProperties[itemId];
        properties.distributorId = distributorId;

        _setTokenURI(itemId, getTokenURI(properties));
    }

    function updateTokenReward(uint256 itemId, uint256 reward) external onlyOwner {
        require(
            tokenIdToProperties[itemId].tokenId != 0,
            string(abi.encodePacked("Token does not exist, you should mint it at first. Not found Token ID: ", itemId.toString()))
        );
        Properties storage properties = tokenIdToProperties[itemId];
        properties.reward = reward;

        _setTokenURI(itemId, getTokenURI(properties));
    }

    function updateTokenImage(uint256 itemId, string calldata imageUri) external onlyOwner {
        require(
            tokenIdToProperties[itemId].tokenId != 0,
            string(abi.encodePacked("Token does not exist, you should mint it at first. Not found Token ID: ", itemId.toString()))
        );
        Properties storage properties = tokenIdToProperties[itemId];
        properties.imageUri = imageUri;

        _setTokenURI(itemId, getTokenURI(properties));
    }

    function basicMint(address recipient, TokenType tokenType) internal returns (uint256) {
        require(tokenCounters[tokenType]._maxValue == 0 || (tokenCounters[tokenType].current() + 1) < tokenCounters[tokenType]._maxValue, string(abi.encodePacked("Total number of tokens for this type exceeds its maximum. Current ID: ", tokenCounters[tokenType].current().toString())));
        tokenCounters[tokenType].increment();
        uint256 newItemId = tokenCounters[tokenType].current();
        _safeMint(recipient, newItemId);

        return newItemId;
    }

    function mintTo(address recipient, TokenType tokenType, uint256 balance, string calldata plan) external onlyOwner returns (uint256) {
        uint256 newItemId = basicMint(recipient, tokenType);
        initTokenProperties(newItemId, tokenType, balance, plan, 0, '');

        return newItemId;
    }

    function mintTo(address recipient, TokenType tokenType, uint256 balance, string calldata plan, uint256 distributorId) external onlyOwner returns (uint256) {
        uint256 newItemId = basicMint(recipient, tokenType);
        initTokenProperties(newItemId, tokenType, balance, plan, distributorId, '');

        return newItemId;
    }

    function mintTo(address recipient, TokenType tokenType, uint256 balance, string calldata plan, uint256 distributorId, string calldata description) external onlyOwner returns (uint256) {
        uint256 newItemId = basicMint(recipient, tokenType);
        initTokenProperties(newItemId, tokenType, balance, plan, distributorId, description);

        return newItemId;
    }

    /// @dev Returns an URI for a given token ID
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    /// @dev Sets the base token URI prefix.
    function setBaseTokenURI(string memory _baseTokenURI) external onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function setBaseImageURI(string memory _baseImageURI) external onlyOwner {
        baseImageURI = _baseImageURI;
    }

    function getBaseImageURI() external view returns (string memory) {
        return baseImageURI;
    }

    function setImageFormat(string memory _baseFormat) external onlyOwner {
        imageFormat = _baseFormat;
    }

    function getImageFormat() external view returns (string memory) {
        return imageFormat;
    }

    function setContractData(string memory _name, string memory _description, string memory _link) external onlyOwner {
        contractName = _name;
        contractDescription = _description;
        contractLink = _link;
    }

    function setContractLink(string memory _link) external onlyOwner {
        contractLink = _link;
    }

    function setContractName(string memory _name) external onlyOwner {
        contractName = _name;
    }

    function contractURI() external view returns (string memory) {
        bytes memory dataURI = abi.encodePacked(
            '{',
            '"name": "',contractName,'",',
            '"description": "',contractDescription,'",',
            '"image": "', string(abi.encodePacked(baseImageURI, 'cover.png')), '",',
            '"external_link": "',contractLink,'"',
            '}'
        );
        return string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(dataURI)
            )
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

library CountersWithLimits {
    struct Counter {
        uint256 _value; // default: 0
        uint256 _maxValue;
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function getMaxValue(Counter storage counter) internal view returns (uint256) {
        return counter._maxValue;
    }

    function increment(Counter storage counter) internal {
        require(counter._maxValue == 0 || counter._value + 1 <= counter._maxValue, "Counter: increment overflow");
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
        counter._maxValue = 0;
    }

    function setValue(Counter storage counter, uint256 newValue) internal {
        counter._value = newValue;
    }
    function setMaxValue(Counter storage counter, uint256 newValue) internal {
        counter._maxValue = newValue;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

abstract contract ContextMixin {
    function msgSender() internal view returns (address payable sender)
    {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
            // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender := and(
                mload(add(array, index)),
                0xffffffffffffffffffffffffffffffffffffffff
                )
            }
        } else {
            sender = payable(msg.sender);
        }
        return sender;
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Base64.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides a set of functions to operate with Base64 strings.
 *
 * _Available since v4.5._
 */
library Base64 {
    /**
     * @dev Base64 Encoding/Decoding Table
     */
    string internal constant _TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /**
     * @dev Converts a `bytes` to its Bytes64 `string` representation.
     */
    function encode(bytes memory data) internal pure returns (string memory) {
        /**
         * Inspired by Brecht Devos (Brechtpd) implementation - MIT licence
         * https://github.com/Brechtpd/base64/blob/e78d9fd951e7b0977ddca77d92dc85183770daf4/base64.sol
         */
        if (data.length == 0) return "";

        // Loads the table into memory
        string memory table = _TABLE;

        // Encoding takes 3 bytes chunks of binary data from `bytes` data parameter
        // and split into 4 numbers of 6 bits.
        // The final Base64 length should be `bytes` data length multiplied by 4/3 rounded up
        // - `data.length + 2`  -> Round up
        // - `/ 3`              -> Number of 3-bytes chunks
        // - `4 *`              -> 4 characters for each chunk
        string memory result = new string(4 * ((data.length + 2) / 3));

        /// @solidity memory-safe-assembly
        assembly {
            // Prepare the lookup table (skip the first "length" byte)
            let tablePtr := add(table, 1)

            // Prepare result pointer, jump over length
            let resultPtr := add(result, 32)

            // Run over the input, 3 bytes at a time
            for {
                let dataPtr := data
                let endPtr := add(data, mload(data))
            } lt(dataPtr, endPtr) {

            } {
                // Advance 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // To write each character, shift the 3 bytes (18 bits) chunk
                // 4 times in blocks of 6 bits for each character (18, 12, 6, 0)
                // and apply logical AND with 0x3F which is the number of
                // the previous character in the ASCII table prior to the Base64 Table
                // The result is then added to the table to get the character to write,
                // and finally write it in the result pointer but with a left shift
                // of 256 (1 byte) - 8 (1 ASCII char) = 248 bits

                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance
            }

            // When data `bytes` is not exactly 3 bytes long
            // it is padded with `=` characters at the end
            switch mod(mload(data), 3)
            case 1 {
                mstore8(sub(resultPtr, 1), 0x3d)
                mstore8(sub(resultPtr, 2), 0x3d)
            }
            case 2 {
                mstore8(sub(resultPtr, 1), 0x3d)
            }
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/extensions/ERC721URIStorage.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";

/**
 * @dev ERC721 token with storage based token URI management.
 */
abstract contract ERC721URIStorage is ERC721 {
    using Strings for uint256;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return super.tokenURI(tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev See {ERC721-_burn}. This override additionally checks to see if a
     * token-specific URI was set for the token, and if so, it deletes the token URI from
     * the storage mapping.
     */
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

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