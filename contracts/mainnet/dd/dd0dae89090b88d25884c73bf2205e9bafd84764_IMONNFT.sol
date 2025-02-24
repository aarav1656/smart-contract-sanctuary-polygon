/**
 *Submitted for verification at polygonscan.com on 2022-07-03
*/

// Sources flattened with hardhat v2.9.6 https://hardhat.org

// File contracts/library/LibJSONWriter.sol

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

library LibJSONWriter {

    using LibJSONWriter for string;

    struct Json {
        int256 depthBitTracker;
        string value;
    }

    bytes1 constant BACKSLASH = bytes1(uint8(92));
    bytes1 constant BACKSPACE = bytes1(uint8(8));
    bytes1 constant CARRIAGE_RETURN = bytes1(uint8(13));
    bytes1 constant DOUBLE_QUOTE = bytes1(uint8(34));
    bytes1 constant FORM_FEED = bytes1(uint8(12));
    bytes1 constant FRONTSLASH = bytes1(uint8(47));
    bytes1 constant HORIZONTAL_TAB = bytes1(uint8(9));
    bytes1 constant NEWLINE = bytes1(uint8(10));

    string constant TRUE = "true";
    string constant FALSE = "false";
    bytes1 constant OPEN_BRACE = "{";
    bytes1 constant CLOSED_BRACE = "}";
    bytes1 constant OPEN_BRACKET = "[";
    bytes1 constant CLOSED_BRACKET = "]";
    bytes1 constant LIST_SEPARATOR = ",";

int256 constant MAX_INT256 = type(int256).max;

/**
 * @dev Writes the beginning of a JSON array.
     */
function writeStartArray(Json memory json)
internal
pure
returns (Json memory)
{
return writeStart(json, OPEN_BRACKET);
}

/**
 * @dev Writes the beginning of a JSON array with a property name as the key.
     */
function writeStartArray(Json memory json, string memory propertyName)
internal
pure
returns (Json memory)
{
return writeStart(json, propertyName, OPEN_BRACKET);
}

/**
 * @dev Writes the beginning of a JSON object.
     */
function writeStartObject(Json memory json)
internal
pure
returns (Json memory)
{
return writeStart(json, OPEN_BRACE);
}

/**
 * @dev Writes the beginning of a JSON object with a property name as the key.
     */
function writeStartObject(Json memory json, string memory propertyName)
internal
pure
returns (Json memory)
{
return writeStart(json, propertyName, OPEN_BRACE);
}

/**
 * @dev Writes the end of a JSON array.
     */
function writeEndArray(Json memory json)
internal
pure
returns (Json memory)
{
return writeEnd(json, CLOSED_BRACKET);
}

/**
 * @dev Writes the end of a JSON object.
     */
function writeEndObject(Json memory json)
internal
pure
returns (Json memory)
{
return writeEnd(json, CLOSED_BRACE);
}

/**
 * @dev Writes the property name and address value (as a JSON string) as part of a name/value pair of a JSON object.
     */
function writeAddressProperty(
Json memory json,
string memory propertyName,
address value
) internal pure returns (Json memory) {
if (json.depthBitTracker < 0) {
json.value = string(abi.encodePacked(json.value, LIST_SEPARATOR, '"', propertyName, '": "', addressToString(value), '"'));
} else {
json.value = string(abi.encodePacked(json.value, '"', propertyName, '": "', addressToString(value), '"'));
}

json.depthBitTracker = setListSeparatorFlag(json);

return json;
}

/**
 * @dev Writes the address value (as a JSON string) as an element of a JSON array.
     */
function writeAddressValue(Json memory json, address value)
internal
pure
returns (Json memory)
{
if (json.depthBitTracker < 0) {
json.value = string(abi.encodePacked(json.value, LIST_SEPARATOR, '"', addressToString(value), '"'));
} else {
json.value = string(abi.encodePacked(json.value, '"', addressToString(value), '"'));
}

json.depthBitTracker = setListSeparatorFlag(json);

return json;
}

/**
 * @dev Writes the property name and boolean value (as a JSON literal "true" or "false") as part of a name/value pair of a JSON object.
     */
function writeBooleanProperty(
Json memory json,
string memory propertyName,
bool value
) internal pure returns (Json memory) {
string memory strValue;
if (value) {
strValue = TRUE;
} else {
strValue = FALSE;
}

if (json.depthBitTracker < 0) {
json.value = string(abi.encodePacked(json.value, LIST_SEPARATOR, '"', propertyName, '": ', strValue));
} else {
json.value = string(abi.encodePacked(json.value, '"', propertyName, '": ', strValue));
}

json.depthBitTracker = setListSeparatorFlag(json);

return json;
}

/**
 * @dev Writes the boolean value (as a JSON literal "true" or "false") as an element of a JSON array.
     */
function writeBooleanValue(Json memory json, bool value)
internal
pure
returns (Json memory)
{
string memory strValue;
if (value) {
strValue = TRUE;
} else {
strValue = FALSE;
}

if (json.depthBitTracker < 0) {
json.value = string(abi.encodePacked(json.value, LIST_SEPARATOR, strValue));
} else {
json.value = string(abi.encodePacked(json.value, strValue));
}

json.depthBitTracker = setListSeparatorFlag(json);

return json;
}

/**
 * @dev Writes the property name and int value (as a JSON number) as part of a name/value pair of a JSON object.
     */
function writeIntProperty(
Json memory json,
string memory propertyName,
int256 value
) internal pure returns (Json memory) {
if (json.depthBitTracker < 0) {
json.value = string(abi.encodePacked(json.value, LIST_SEPARATOR, '"', propertyName, '": ', intToString(value)));
} else {
json.value = string(abi.encodePacked(json.value, '"', propertyName, '": ', intToString(value)));
}

json.depthBitTracker = setListSeparatorFlag(json);

return json;
}

/**
 * @dev Writes the int value (as a JSON number) as an element of a JSON array.
     */
function writeIntValue(Json memory json, int256 value)
internal
pure
returns (Json memory)
{
if (json.depthBitTracker < 0) {
json.value = string(abi.encodePacked(json.value, LIST_SEPARATOR, intToString(value)));
} else {
json.value = string(abi.encodePacked(json.value, intToString(value)));
}

json.depthBitTracker = setListSeparatorFlag(json);

return json;
}

/**
 * @dev Writes the property name and value of null as part of a name/value pair of a JSON object.
     */
function writeNullProperty(Json memory json, string memory propertyName)
internal
pure
returns (Json memory)
{
if (json.depthBitTracker < 0) {
json.value = string(abi.encodePacked(json.value, LIST_SEPARATOR, '"', propertyName, '": null'));
} else {
json.value = string(abi.encodePacked(json.value, '"', propertyName, '": null'));
}

json.depthBitTracker = setListSeparatorFlag(json);

return json;
}

/**
 * @dev Writes the value of null as an element of a JSON array.
     */
function writeNullValue(Json memory json)
internal
pure
returns (Json memory)
{
if (json.depthBitTracker < 0) {
json.value = string(abi.encodePacked(json.value, LIST_SEPARATOR, "null"));
} else {
json.value = string(abi.encodePacked(json.value, "null"));
}

json.depthBitTracker = setListSeparatorFlag(json);

return json;
}

/**
 * @dev Writes the string text value (as a JSON string) as an element of a JSON array.
     */
function writeStringProperty(
Json memory json,
string memory propertyName,
string memory value
) internal pure returns (Json memory) {
string memory jsonEscapedString = escapeJsonString(value);
if (json.depthBitTracker < 0) {
json.value = string(abi.encodePacked(json.value, LIST_SEPARATOR, '"', propertyName, '": "', jsonEscapedString, '"'));
} else {
json.value = string(abi.encodePacked(json.value, '"', propertyName, '": "', jsonEscapedString, '"'));
}

json.depthBitTracker = setListSeparatorFlag(json);

return json;
}

/**
 * @dev Writes the property name and string text value (as a JSON string) as part of a name/value pair of a JSON object.
     */
function writeStringValue(Json memory json, string memory value)
internal
pure
returns (Json memory)
{
string memory jsonEscapedString = escapeJsonString(value);
if (json.depthBitTracker < 0) {
json.value = string(abi.encodePacked(json.value, LIST_SEPARATOR, '"', jsonEscapedString, '"'));
} else {
json.value = string(abi.encodePacked(json.value, '"', jsonEscapedString, '"'));
}

json.depthBitTracker = setListSeparatorFlag(json);

return json;
}

/**
 * @dev Writes the property name and uint value (as a JSON number) as part of a name/value pair of a JSON object.
     */
function writeUintProperty(
Json memory json,
string memory propertyName,
uint256 value
) internal pure returns (Json memory) {
if (json.depthBitTracker < 0) {
json.value = string(abi.encodePacked(json.value, LIST_SEPARATOR, '"', propertyName, '": ', uintToString(value)));
} else {
json.value = string(abi.encodePacked(json.value, '"', propertyName, '": ', uintToString(value)));
}

json.depthBitTracker = setListSeparatorFlag(json);

return json;
}

/**
 * @dev Writes the uint value (as a JSON number) as an element of a JSON array.
     */
function writeUintValue(Json memory json, uint256 value)
internal
pure
returns (Json memory)
{
if (json.depthBitTracker < 0) {
json.value = string(abi.encodePacked(json.value, LIST_SEPARATOR, uintToString(value)));
} else {
json.value = string(abi.encodePacked(json.value, uintToString(value)));
}

json.depthBitTracker = setListSeparatorFlag(json);

return json;
}

/**
 * @dev Writes the beginning of a JSON array or object based on the token parameter.
     */
function writeStart(Json memory json, bytes1 token)
private
pure
returns (Json memory)
{
if (json.depthBitTracker < 0) {
json.value = string(abi.encodePacked(json.value, LIST_SEPARATOR, token));
} else {
json.value = string(abi.encodePacked(json.value, token));
}

json.depthBitTracker &= MAX_INT256;
json.depthBitTracker++;

return json;
}

/**
 * @dev Writes the beginning of a JSON array or object based on the token parameter with a property name as the key.
     */
function writeStart(
Json memory json,
string memory propertyName,
bytes1 token
) private pure returns (Json memory) {
if (json.depthBitTracker < 0) {
json.value = string(abi.encodePacked(json.value, LIST_SEPARATOR, '"', propertyName, '": ', token));
} else {
json.value = string(abi.encodePacked(json.value, '"', propertyName, '": ', token));
}

json.depthBitTracker &= MAX_INT256;
json.depthBitTracker++;

return json;
}

/**
 * @dev Writes the end of a JSON array or object based on the token parameter.
     */
function writeEnd(Json memory json, bytes1 token)
private
pure
returns (Json memory)
{
json.value = string(abi.encodePacked(json.value, token));
json.depthBitTracker = setListSeparatorFlag(json);

if (getCurrentDepth(json) != 0) {
json.depthBitTracker--;
}

return json;
}

/**
 * @dev Escapes any characters that required by JSON to be escaped.
     */
function escapeJsonString(string memory value)
private
pure
returns (string memory str)
{
bytes memory b = bytes(value);
bool foundEscapeChars;

for (uint256 i; i < b.length; i++) {
if (b[i] == BACKSLASH) {
foundEscapeChars = true;
break;
} else if (b[i] == DOUBLE_QUOTE) {
foundEscapeChars = true;
break;
} else if (b[i] == FRONTSLASH) {
foundEscapeChars = true;
break;
} else if (b[i] == HORIZONTAL_TAB) {
foundEscapeChars = true;
break;
} else if (b[i] == FORM_FEED) {
foundEscapeChars = true;
break;
} else if (b[i] == NEWLINE) {
foundEscapeChars = true;
break;
} else if (b[i] == CARRIAGE_RETURN) {
foundEscapeChars = true;
break;
} else if (b[i] == BACKSPACE) {
foundEscapeChars = true;
break;
}
}

if (!foundEscapeChars) {
return value;
}

for (uint256 i; i < b.length; i++) {
if (b[i] == BACKSLASH) {
str = string(abi.encodePacked(str, "\\\\"));
} else if (b[i] == DOUBLE_QUOTE) {
str = string(abi.encodePacked(str, '\\"'));
} else if (b[i] == FRONTSLASH) {
str = string(abi.encodePacked(str, "\\/"));
} else if (b[i] == HORIZONTAL_TAB) {
str = string(abi.encodePacked(str, "\\t"));
} else if (b[i] == FORM_FEED) {
str = string(abi.encodePacked(str, "\\f"));
} else if (b[i] == NEWLINE) {
str = string(abi.encodePacked(str, "\\n"));
} else if (b[i] == CARRIAGE_RETURN) {
str = string(abi.encodePacked(str, "\\r"));
} else if (b[i] == BACKSPACE) {
str = string(abi.encodePacked(str, "\\b"));
} else {
str = string(abi.encodePacked(str, b[i]));
}
}

return str;
}

/**
 * @dev Tracks the recursive depth of the nested objects / arrays within the JSON text
     * written so far. This provides the depth of the current token.
     */
function getCurrentDepth(Json memory json) private pure returns (int256) {
return json.depthBitTracker & MAX_INT256;
}

/**
 * @dev The highest order bit of json.depthBitTracker is used to discern whether we are writing the first item in a list or not.
     * if (json.depthBitTracker >> 255) == 1, add a list separator before writing the item
     * else, no list separator is needed since we are writing the first item.
     */
function setListSeparatorFlag(Json memory json)
private
pure
returns (int256)
{
return json.depthBitTracker | (int256(1) << 255);
}

/**
* @dev Converts an address to a string.
     */
function addressToString(address _address)
internal
pure
returns (string memory)
{
bytes32 value = bytes32(uint256(uint160(_address)));
bytes16 alphabet = "0123456789abcdef";

bytes memory str = new bytes(42);
str[0] = "0";
str[1] = "x";
for (uint256 i; i < 20; i++) {
str[2 + i * 2] = alphabet[uint8(value[i + 12] >> 4)];
str[3 + i * 2] = alphabet[uint8(value[i + 12] & 0x0f)];
}

return string(str);
}

/**
 * @dev Converts an int to a string.
     */
function intToString(int256 i) internal pure returns (string memory) {
if (i == 0) {
return "0";
}

if (i == type(int256).min) {
// hard-coded since int256 min value can't be converted to unsigned
return "-57896044618658097711785492504343953926634992332820282019728792003956564819968";
}

bool negative = i < 0;
uint256 len;
uint256 j;
if (!negative) {
j = uint256(i);
} else {
j = uint256(- i);
++len; // make room for '-' sign
}

uint256 l = j;
while (j != 0) {
len++;
j /= 10;
}

bytes memory bstr = new bytes(len);
uint256 k = len;
while (l != 0) {
bstr[--k] = bytes1((48 + uint8(l - (l / 10) * 10)));
l /= 10;
}

if (negative) {
bstr[0] = "-"; // prepend '-'
}

return string(bstr);
}

/**
 * @dev Converts a uint to a string.
     */
function uintToString(uint256 _i) internal pure returns (string memory) {
if (_i == 0) {
return "0";
}

uint256 j = _i;
uint256 len;
while (j != 0) {
len++;
j /= 10;
}

bytes memory bstr = new bytes(len);
uint256 k = len;
while (_i != 0) {
bstr[--k] = bytes1((48 + uint8(_i - (_i / 10) * 10)));
_i /= 10;
}

return string(bstr);
}
}


// File contracts/interfaces/IIMONNFT.sol


pragma solidity 0.8.14;

interface IIMONNFT {
    function isBaseNFT() external view returns (bool);
    function mintNFT(address to,uint256 id, uint256 amount, bytes memory data) external returns(bool);
    function checkSubBalances(address _address) external view returns(bool, uint256[] memory,uint256[] memory);
    function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _value, bytes calldata _data) external;
    function safeBatchTransferFrom(address _from, address _to,uint256[] calldata _ids, uint256[] calldata _values, bytes calldata _data) external;
    function balanceOf(address _owner, uint256 _id) external view returns (uint256);
    function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids) external view returns (uint256[] memory);
    function setApprovalForAll(address _operator, bool _approved) external;
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}


// File @openzeppelin/contracts/utils/math/[email protected]


// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}


// File contracts/interfaces/INFTInfoFacet.sol


pragma solidity 0.8.14;



interface INFTInfoFacet {
    function getAssetNameByTokenId(address _contract, uint256 _tokenId) external view returns(string memory);
    function getAssetURI(address _contract, uint256 _tokenId) external view returns(string memory);
    function isBaseAsset(address _contract) external view returns(bool);
    function getBaseImage(address _contract,uint256 _tokenId) external view returns(string memory);
    function getSubImage(uint256 _tokenId) external view returns(string memory);
    function getImage(address _contract, uint256 _tokenId) external view returns(string memory);
    function getHashPowerByTokenId(address _contract, uint256 _tokenId) external view returns(uint256);
    function getAssetPropertiesByTokenId(address _contract, uint256 _tokenId) external view returns(string memory);
    function checkSubBalances(address _address, uint256 catalogId) external view returns(string memory);
    function getTwitterAccount(address _contract, uint256 _tokenId) external view returns(string memory);
    function getHashTags(address _contract, uint256 _tokenId) external view returns(string memory);
    function getTrainingData(address _contract, uint256 _tokenId) external view returns(string memory);

    }


// File @openzeppelin/contracts/utils/introspection/[email protected]

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


// File @openzeppelin/contracts/token/ERC1155/[email protected]

// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}


// File @openzeppelin/contracts/utils/[email protected]

// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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


// File @openzeppelin/contracts/utils/[email protected]

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


// File @openzeppelin/contracts/utils/introspection/[email protected]

// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

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


// File @openzeppelin/contracts/token/ERC1155/[email protected]

// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}


// File @openzeppelin/contracts/token/ERC1155/extensions/[email protected]

// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}


// File contracts/library/LibERC1155.sol

// OpenZeppelin Contracts v4.4.1 (token/ERC1155/ERC1155.sol)

pragma solidity 0.8.14;






/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract LibERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
    using Address for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) public _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.

    constructor(string memory uri_) {
        _setURI(uri_);
    }
*/
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
        interfaceId == type(IERC1155).interfaceId ||
        interfaceId == type(IERC1155MetadataURI).interfaceId ||
        super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: balance query for the zero address");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
    public
    view
    virtual
    override
    returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, _asSingletonArray(id), _asSingletonArray(amount), data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
    unchecked {
        _balances[id][from] = fromBalance - amount;
    }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, _asSingletonArray(id), _asSingletonArray(amount), data);

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), _asSingletonArray(id), _asSingletonArray(amount), "");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
    unchecked {
        _balances[id][from] = fromBalance - amount;
    }

        emit TransferSingle(operator, from, address(0), id, amount);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
}


// File contracts/core/IMONNFT.sol

pragma solidity 0.8.14;



contract IMONNFT is LibERC1155{
    using SafeMath for uint256;

    address private IMONFactory;
    INFTInfoFacet public NFTInfoContract;
    string private _nftName;
    bool private _isBaseNFT;
    uint256 private _nftTotalSupply;
    uint256[] public _tokenIDList;
    mapping(uint256 => bool) _isTokenIDExists;

    modifier onlyOwner {
        require(msg.sender == IMONFactory,"You are not authorized");
        _;
    }

    constructor(string memory _name,uint256 _totalSupply,address _factoryAddress,bool _isBase){
        _nftName = _name;
        _nftTotalSupply = _totalSupply;
        _isBaseNFT = _isBase;
        IMONFactory = _factoryAddress;
        NFTInfoContract = INFTInfoFacet(_factoryAddress);
    }

    function name() public view  returns (string memory) {
        return _nftName;
    }

    function symbol() public view  returns (string memory) {
        return "IMON";
    }

    function totalSupply() public view returns (uint256) {
        return _nftTotalSupply;
    }

    function isBaseNFT() external view returns (bool) {
        return _isBaseNFT;
    }

    function setFactoryAddress(address _address) external onlyOwner{
        IMONFactory = _address;
        NFTInfoContract = INFTInfoFacet(_address);
    }

    function getFactoryAddress() external view returns(address){
        return IMONFactory;
    }

    function mintNFT(address to,uint256 id, uint256 amount, bytes memory data) external onlyOwner returns(bool){
        _mint(to,id,amount,data );
        if(!_isTokenIDExists[id]){
            _tokenIDList.push(id);
            _isTokenIDExists[id] = true;
        }
        return true;
    }

    function getHashPower(uint256 _tokenId) external view returns(uint256){
        return NFTInfoContract.getHashPowerByTokenId(address(this), _tokenId);
    }

    function getAssetName(uint256 _tokenId) external view returns(string memory){
        return NFTInfoContract.getAssetNameByTokenId(address(this), _tokenId);
    }

    function getAssetFeatures(uint256 _tokenId) external view returns(string memory){
        return NFTInfoContract.getAssetPropertiesByTokenId(address(this), _tokenId);
    }

    function getImage(uint256 _tokenId) public view returns(string memory){
        return NFTInfoContract.getImage(address(this),_tokenId);
    }

    function isBaseAsset() external view returns(bool){
        return _isBaseNFT;
    }

    function getTwitterAccount(uint256 _tokenId) external view returns(string memory){
        return NFTInfoContract.getTwitterAccount(address(this),_tokenId);
    }

    function getHashTags(uint256 _tokenId) external view returns(string memory){
        return NFTInfoContract.getHashTags(address(this),_tokenId);
    }

    function uri(uint256 _tokenId) public view override returns (string memory) {
        return getImage(_tokenId);
    }

    function getTrainingData(uint256 _tokenId) external view returns(string memory){
        return NFTInfoContract.getTrainingData(address(this),_tokenId);
    }


    function checkSubBalances(address _address) external view returns(bool,uint256[] memory, uint256[] memory){
        uint256 tokenIdListSize = _tokenIDList.length;
        uint256[] memory  tokenIDList  = new uint256[](tokenIdListSize);
        uint256[] memory  balanceList  = new uint256[](tokenIdListSize);
        uint256 balanceIndex = 0;
        for (uint256 i = 0; i < tokenIdListSize; i++) {
            uint256 tokenID = _tokenIDList[i];
            uint256 balance =  _balances[tokenID][_address];
            if(balance > 0){
                balanceList[balanceIndex] = balance;
                tokenIDList[balanceIndex] = tokenID;
                balanceIndex ++;
            }
        }
        return (_isBaseNFT, tokenIDList,balanceList);
    }

}