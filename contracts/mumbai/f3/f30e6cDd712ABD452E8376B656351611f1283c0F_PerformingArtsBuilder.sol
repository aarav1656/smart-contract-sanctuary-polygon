/**
 *Submitted for verification at polygonscan.com on 2022-11-17
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;



// File: Base64.sol

/**
 * @title Base64
 * @author Brecht Devos - <[email protected]>
 * @notice Provides functions for encoding/decoding base64
 */
library Base64 {
    string internal constant TABLE_ENCODE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
    bytes internal constant TABLE_DECODE =
        hex"0000000000000000000000000000000000000000000000000000000000000000"
        hex"00000000000000000000003e0000003f3435363738393a3b3c3d000000000000"
        hex"00000102030405060708090a0b0c0d0e0f101112131415161718190000000000"
        hex"001a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132330000000000";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return "";

        // load the table into memory
        string memory table = TABLE_ENCODE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 3 bytes at a time
            for {

            } lt(dataPtr, endPtr) {

            } {
                // read 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // write 4 characters
                mstore8(
                    resultPtr,
                    mload(add(tablePtr, and(shr(18, input), 0x3F)))
                )
                resultPtr := add(resultPtr, 1)
                mstore8(
                    resultPtr,
                    mload(add(tablePtr, and(shr(12, input), 0x3F)))
                )
                resultPtr := add(resultPtr, 1)
                mstore8(
                    resultPtr,
                    mload(add(tablePtr, and(shr(6, input), 0x3F)))
                )
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }
        }

        return result;
    }

    function decode(string memory _data) internal pure returns (bytes memory) {
        bytes memory data = bytes(_data);

        if (data.length == 0) return new bytes(0);
        require(data.length % 4 == 0, "invalid base64 decoder input");

        // load the table into memory
        bytes memory table = TABLE_DECODE;

        // every 4 characters represent 3 bytes
        uint256 decodedLen = (data.length / 4) * 3;

        // add some extra buffer at the end required for the writing
        bytes memory result = new bytes(decodedLen + 32);

        assembly {
            // padding with '='
            let lastBytes := mload(add(data, mload(data)))
            if eq(and(lastBytes, 0xFF), 0x3d) {
                decodedLen := sub(decodedLen, 1)
                if eq(and(lastBytes, 0xFFFF), 0x3d3d) {
                    decodedLen := sub(decodedLen, 1)
                }
            }

            // set the actual output length
            mstore(result, decodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 4 characters at a time
            for {

            } lt(dataPtr, endPtr) {

            } {
                // read 4 characters
                dataPtr := add(dataPtr, 4)
                let input := mload(dataPtr)

                // write 3 bytes
                let output := add(
                    add(
                        shl(
                            18,
                            and(
                                mload(add(tablePtr, and(shr(24, input), 0xFF))),
                                0xFF
                            )
                        ),
                        shl(
                            12,
                            and(
                                mload(add(tablePtr, and(shr(16, input), 0xFF))),
                                0xFF
                            )
                        )
                    ),
                    add(
                        shl(
                            6,
                            and(
                                mload(add(tablePtr, and(shr(8, input), 0xFF))),
                                0xFF
                            )
                        ),
                        and(mload(add(tablePtr, and(input, 0xFF))), 0xFF)
                    )
                )
                mstore(resultPtr, shl(232, output))
                resultPtr := add(resultPtr, 3)
            }
        }

        return result;
    }
}

// File: Context.sol

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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

// File: EnumerableSet.sol

// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableSet.sol)

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 *  Trying to delete such a structure from storage will likely result in data corruption, rendering the structure unusable.
 *  See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 *  In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an array of EnumerableSet.
 * ====
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// File: IAccessControl.sol

// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

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

// File: IERC165.sol

// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

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

// File: IERC20.sol

// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// File: INominator.sol

interface INominator {
    function getNFTName(uint256 tokenId) external view returns (string memory);

    function hasNominated(uint256 tokenId) external view returns (bool);
}

// File: IReliefDaoOracle.sol

struct CandidateInfo {
    uint256 candidateId;
    bytes32 candidateName;
    bytes32 candidateName2;
    bytes32 location;
    bytes32 amountRaised;
    uint256 votes;
}

interface IReliefDaoOracle {
    function getCandidateCount() external view returns (uint256);

    function getCandidateAtIndex(uint256 index)
        external
        view
        returns (CandidateInfo memory);

    function getCandidateById(uint256 candidateId)
        external
        view
        returns (CandidateInfo memory);

    function progress() external view returns (string memory);

    function candidateNominatedBy(uint256 tokenId)
        external
        view
        returns (CandidateInfo memory);

    function candidateVotedBy(uint256 tokenId)
        external
        view
        returns (CandidateInfo memory);
}

// File: Strings.sol

// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

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

// File: AccessManagement.sol

interface ChainalysisSanctionsList {
    function isSanctioned(address addr) external view returns (bool);
}

contract EmptySanctionsList is ChainalysisSanctionsList {
    function isSanctioned(address) external pure override returns (bool) {
        return false;
    }
}

/**
 * @dev Library to externalize the access control features to cut down on deployed
 * bytecode in the main contract.
 * @dev see {ViciAccess}
 * @dev Moving all of this code into this library cut the size of ViciAccess, and all of
 * the contracts that extend from it, by about 4kb.
 */
library AccessManagement {
    using Strings for string;
    using EnumerableSet for EnumerableSet.AddressSet;

    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    struct AccessManagementState {
        address contractOwner;
        ChainalysisSanctionsList sanctionsList;
        bool sanctionsComplianceEnabled;
        mapping(bytes32 => EnumerableSet.AddressSet) roleMembers;
        mapping(bytes32 => RoleData) roles;
    }

    /**
     * @dev Emitted when `previousOwner` transfers ownership to `newOwner`.
     */
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(
        bytes32 indexed role,
        bytes32 indexed previousAdminRole,
        bytes32 indexed newAdminRole
    );

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );

    function DEFAULT_ADMIN_ROLE() public pure returns (bytes32) {
        return 0x00;
    }

    function BANNED_ROLE_NAME() public pure returns (bytes32) {
        return "banned";
    }

    function MODERATOR_ROLE_NAME() public pure returns (bytes32) {
        return "moderator";
    }

    function initSanctions(AccessManagementState storage ams) external {
        require(
            address(ams.sanctionsList) == address(0),
            "already initialized"
        );
        // The official contract is deployed at the same address on each of
        // these blockchains.
        if (
            block.chainid == 137 || // Polygon
            block.chainid == 1 || // Ethereum
            block.chainid == 56 || // Binance Smart Chain
            block.chainid == 250 || // Fantom
            block.chainid == 10 || // Optimism
            block.chainid == 42161 || // Arbitrum
            block.chainid == 43114 || // Avalanche
            block.chainid == 25 || // Cronos
            false
        ) {
            _setSanctions(
                ams,
                ChainalysisSanctionsList(
                    address(0x40C57923924B5c5c5455c48D93317139ADDaC8fb)
                )
            );
        } else if (block.chainid == 80001) {
            _setSanctions(
                ams,
                ChainalysisSanctionsList(
                    address(0x07342d7d152dd01325f777f41FeDe5D4ACc4F8EC)
                )
            );
        } else {
            _setSanctions(ams, new EmptySanctionsList());
        }

        ams.sanctionsComplianceEnabled = true;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function setContractOwner(
        AccessManagementState storage ams,
        address _newOwner
    ) external {
        if (ams.contractOwner != address(0)) {
            enforceIsContractOwner(ams, msg.sender);
        }

        enforceIsNotBanned(ams, _newOwner);
        require(_newOwner != ams.contractOwner, "AccessControl: already owner");
        _grantRole(ams, DEFAULT_ADMIN_ROLE(), _newOwner);
        address oldOwner = ams.contractOwner;
        ams.contractOwner = _newOwner;

        if (oldOwner != address(0)) {
            emit OwnershipTransferred(oldOwner, _newOwner);
        }
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function getContractOwner(AccessManagementState storage ams)
        public
        view
        returns (address)
    {
        return ams.contractOwner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    function enforceIsContractOwner(
        AccessManagementState storage ams,
        address account
    ) public view {
        require(account == ams.contractOwner, "AccessControl: not owner");
    }

    /**
     * @dev reverts if called by an account that is not the owner and doesn't 
     *     have the moderator role.
     */
    function enforceIsModerator(
        AccessManagementState storage ams,
        address account
    ) public view {
        require(
            account == ams.contractOwner ||
                hasRole(ams, MODERATOR_ROLE_NAME(), account),
            "AccessControl: not moderator"
        );
    }

    /**
     * @dev Reverts if called by a banned or sanctioned account.
     */
    function enforceIsNotBanned(
        AccessManagementState storage ams,
        address account
    ) public view {
        enforceIsNotSanctioned(ams, account);
        require(!isBanned(ams, account), "AccessControl: banned");
    }

    /**
     * @dev Reverts if called by an account on the OFAC sanctions list.
     */
    function enforceIsNotSanctioned(
        AccessManagementState storage ams,
        address addr
    ) public view {
        if (ams.sanctionsComplianceEnabled) {
            require(
                !ams.sanctionsList.isSanctioned(addr),
                "OFAC sanctioned address"
            );
        }
    }

    /**
     * @dev reverts if called by an account that is not the owner and doesn't 
     *     have the required role.
     */
    function enforceOwnerOrRole(
        AccessManagementState storage ams,
        bytes32 _role,
        address _account
    ) public view {
        if (_account != ams.contractOwner) {
            checkRole(ams, _role, _account);
        }
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(
        AccessManagementState storage ams,
        bytes32 _role,
        address _account
    ) public view returns (bool) {
        return ams.roles[_role].members[_account];
    }

    /**
     * @dev Throws if `_account` does not have `_role`.
     */
    function checkRole(
        AccessManagementState storage ams,
        bytes32 _role,
        address _account
    ) public view {
        if (!hasRole(ams, _role, _account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(_account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(_role), 32)
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
    function getRoleAdmin(AccessManagementState storage ams, bytes32 role)
        public
        view
        returns (bytes32)
    {
        return ams.roles[role].adminRole;
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function setRoleAdmin(
        AccessManagementState storage ams,
        bytes32 role,
        bytes32 adminRole
    ) public {
        enforceOwnerOrRole(ams, getRoleAdmin(ams, role), msg.sender);
        bytes32 previousAdminRole = getRoleAdmin(ams, role);
        ams.roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `_role` to `_account`.
     */
    function grantRole(
        AccessManagementState storage ams,
        bytes32 _role,
        address _account
    ) external {
        enforceIsNotBanned(ams, msg.sender);
        if (_role == BANNED_ROLE_NAME()) {
            enforceIsModerator(ams, msg.sender);
            require(_account != ams.contractOwner, "AccessControl: ban owner");
        } else {
            enforceIsNotBanned(ams, _account);
            if (msg.sender != ams.contractOwner) {
                checkRole(ams, getRoleAdmin(ams, _role), msg.sender);
            }
        }

        _grantRole(ams, _role, _account);
    }

    /**
     * @dev Returns `true` if `_account` is banned.
     */
    function isBanned(AccessManagementState storage ams, address _account)
        public
        view
        returns (bool)
    {
        return hasRole(ams, BANNED_ROLE_NAME(), _account);
    }

    /**
     * @dev Revokes `_role` from `_account`.
     */
    function revokeRole(
        AccessManagementState storage ams,
        bytes32 _role,
        address _account
    ) external {
        enforceIsNotBanned(ams, msg.sender);
        require(
            _role != DEFAULT_ADMIN_ROLE() || _account != ams.contractOwner,
            "AccessControl: revoke admin from owner"
        );
        if (_role == BANNED_ROLE_NAME()) {
            enforceIsModerator(ams, msg.sender);
        } else {
            enforceOwnerOrRole(ams, getRoleAdmin(ams, _role), msg.sender);
        }

        _revokeRole(ams, _role, _account);
    }

    /**
     * @dev Revokes `_role` from the calling account.
     */
    function renounceRole(AccessManagementState storage ams, bytes32 _role)
        external
    {
        require(
            _role != DEFAULT_ADMIN_ROLE() || msg.sender != ams.contractOwner,
            "AccessControl: owner renounce admin"
        );
        require(_role != BANNED_ROLE_NAME(), "AccessControl: self unban");
        checkRole(ams, _role, msg.sender);
        _revokeRole(ams, _role, msg.sender);
    }

    /**
     * @dev Returns one of the accounts that have `_role`. `_index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     */
    function getRoleMember(
        AccessManagementState storage ams,
        bytes32 _role,
        uint256 _index
    ) external view returns (address) {
        return ams.roleMembers[_role].at(_index);
    }

    /**
     * @dev Returns the number of accounts that have `_role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(
        AccessManagementState storage ams,
        bytes32 _role
    ) external view returns (uint256) {
        return ams.roleMembers[_role].length();
    }

    /**
     * @notice returns whether the address is sanctioned.
     */
    function isSanctioned(AccessManagementState storage ams, address addr)
        public
        view
        returns (bool)
    {
        return
            ams.sanctionsComplianceEnabled &&
            ams.sanctionsList.isSanctioned(addr);
    }

    /**
     * @notice Sets the sanction list oracle
     * @notice Reverts unless the contract is running on a local HardHat or
     *      Ganache chain.
     * @param _sanctionsList the oracle address
     */
    function setSanctions(
        AccessManagementState storage ams,
        ChainalysisSanctionsList _sanctionsList
    ) external {
        require(block.chainid == 31337 || block.chainid == 1337, "Not testnet");
        _setSanctions(ams, _sanctionsList);
    }

    /**
     * @notice returns the address of the OFAC sanctions oracle.
     */
    function getSanctionsOracle(AccessManagementState storage ams)
        public
        view
        returns (address)
    {
        return address(ams.sanctionsList);
    }

    /**
     * @notice toggles the sanctions compliance flag
     * @notice this flag should only be turned off during testing or if there
     *     is some problem with the sanctions oracle.
     *
     * Requirements:
     * - Caller must be the contract owner
     */
    function toggleSanctionsCompliance(AccessManagementState storage ams)
        public
    {
        ams.sanctionsComplianceEnabled = !ams.sanctionsComplianceEnabled;
    }

    /**
     * @dev returns true if sanctions compliance is enabled.
     */
    function isSanctionsComplianceEnabled(AccessManagementState storage ams)
        public
        view
        returns (bool)
    {
        return ams.sanctionsComplianceEnabled;
    }

    function _setSanctions(
        AccessManagementState storage ams,
        ChainalysisSanctionsList _sanctionsList
    ) internal {
        ams.sanctionsList = _sanctionsList;
    }

    function _grantRole(
        AccessManagementState storage ams,
        bytes32 _role,
        address _account
    ) private {
        if (!hasRole(ams, _role, _account)) {
            ams.roles[_role].members[_account] = true;
            ams.roleMembers[_role].add(_account);
            emit RoleGranted(_role, _account, msg.sender);
        }
    }

    function _revokeRole(
        AccessManagementState storage ams,
        bytes32 _role,
        address _account
    ) private {
        if (hasRole(ams, _role, _account)) {
            ams.roles[_role].members[_account] = false;
            ams.roleMembers[_role].remove(_account);
            emit RoleRevoked(_role, _account, msg.sender);
        }
    }
}

// File: DynamicURI.sol

interface DynamicURI is IERC165 {
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// File: ERC165.sol

// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

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

// File: IAccessControlEnumerable.sol

// OpenZeppelin Contracts v4.4.1 (access/IAccessControlEnumerable.sol)

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerable is IAccessControl {
    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}

// File: IERC1155.sol

// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

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
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
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

// File: IERC721.sol

// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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

// File: Pausable.sol

// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
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
    constructor() {
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
}

// File: SVGBuilder.sol

// values are string because they can be numbers or percents
struct Box {
    string x;
    string y;
    string width;
    string height;
}

// values are string because they can be numbers or percents
struct Point {
    string x;
    string y;
}

/**
 * @dev generates nft metadata onchain with an SVG image.
 * @dev use it like this:
 * <pre>
    string memory tokenURI = svg.svgElementToTokenURI(
        svg.svgToImageURI(
            svg.buildSVGElement(
                1080,
                1080,
                "white",
                strings.concat(
                    svg.rect(
                        Box("48", "48", "984", "984"),
                        svg.prop(
                            "style", 
                            strings.concat(
                                svg.style("fill", "#fff0e6"),
                                svg.prop("stroke", "black"),
                                svg.prop("stroke-width", "3")
                            )
                        )
                    ),
                    svg.text(
                        string.concat(
                            svg.prop("x", "50%"),
                            svg.prop("y", "50%"),
                            svg.prop("dominant-baseline", "middle"),
                            svg.prop("text-anchor", "middle"),
                            svg.prop(
                                "style", 
                                strings.concat(
                                    svg.style("fill", "#fff0e6"),
                                    svg.prop("font-size", "120px"),
                                    svg.prop("font-family", "Comic Sans MS,Comic Sans,cursive")
                                )
                            )
                        ),
                        "You're Awesome!"
                    )
                )
            )
        ),
        "Onchain NFT #1234",
        "#Super dope NFT"
    );
 * </pre>
 * @dev uses a little code from https://github.com/PatrickAlphaC/all-on-chain-generated-nft/blob/main/contracts/RandomSVG.sol
 * @dev and a lot of code from https://github.com/w1nt3r-eth/hot-chain-svg/blob/main/contracts/SVG.sol
 */
library svg {
    using Strings for string;

    /**
     * @dev builds a token uri for an image. You can paste the result in your
     *     browser and it will show a JSON document.
     * @param imageURI the link to the image. See `svgToImageURI(string)`
     * @param tokenName the name attribute for the token metadata
     * @param externalURL the name attribute for the token metadata
     * @param tokenDescription the description attribute. This can contain
     *     markdown formatting.
     */
    function svgElementToTokenURI(
        string memory imageURI,
        string memory tokenName,
        string memory externalURL,
        string memory tokenDescription
    ) public pure returns (string memory) {
        return
            string.concat(
                "data:application/json;base64,",
                Base64.encode(
                    bytes(
                        string.concat(
                            '{"name":"',
                            tokenName,
                            '","description":"',
                            tokenDescription,
                            '","external_url":"',
                            externalURL,
                            '","attributes":"","image":"',
                            imageURI,
                            '"}'
                        )
                    )
                )
            );
    }

    /**
     * @dev builds a image uri for an SVG element. You can paste the result in
     *     your browser and it will show an SVG image.
     * @param svgElement the <svg ...>...</svg> document.
     */
    function svgToImageURI(string memory svgElement)
        public
        pure
        returns (string memory)
    {
        string memory baseURL = "data:image/svg+xml;base64,";
        string memory svgBase64Encoded = Base64.encode(
            bytes(string(abi.encodePacked(svgElement)))
        );
        return string(abi.encodePacked(baseURL, svgBase64Encoded));
    }

    /* STRUCTURE ELEMENTS */

    /**
     * @dev builds an <svg> element
     * @dev see https://www.w3.org/TR/SVG11/struct.html#NewDocument
     * @param props additional SVG element props
     * - width=the width of the element; 100% if not specified
     * - height=the height of the element; 100% if not specified
     * - x=for embedded SVG, the x position of the upper left corner
     * - y=for embedded SVG, the y position of the upper left corner
     * - preserveAspectRatio=default is 'xMidYMid meet', see
     *      https://www.w3.org/TR/SVG11/coords.html#PreserveAspectRatioAttribute
     * - zoomAndPan=either 'disable' or 'magnify'
     * @param children a concatenated string containing the inner elements.
     */
    function svgDocument(string memory props, string memory children)
        public
        pure
        returns (string memory)
    {
        return
            el(
                "svg",
                string.concat(
                    prop("xmlns", "http://www.w3.org/2000/svg"),
                    prop("xmlns:xlink", "http://www.w3.org/1999/xlink"),
                    prop("version", "1.1"),
                    props
                ),
                children
            );
    }

    /**
     * @dev builds an SVG group.
     * @dev see https://www.w3.org/TR/SVG11/struct.html#Groups
     * @param props the group properties.
     * - id=group name
     * - fill=group fill color
     * - opacity=group opacity
     * @param children a concatenated string containing the inner elements.
     */
    function g(string memory props, string memory children)
        public
        pure
        returns (string memory)
    {
        return el("g", props, children);
    }

    /**
     * @dev builds a defs element to contain referencable elements
     * @dev Child elements should have an "id" property with a unique value.
     * @dev An element with id="foo" can be referenced as "url(#foo)".
     * @dev see https://www.w3.org/TR/SVG11/struct.html#DefsElement
     * @param children a concatenated string containing the child elements.
     */
    function defs(string memory children) public pure returns (string memory) {
        return string.concat("<defs>", children, "</defs>");
    }

    /**
     * @dev builds a defs element to contain referencable elements
     * @dev Child elements should have an "id" property with a unique value.
     * @dev An element with id="foo" can be referenced as "url(#foo)".
     * @dev see https://www.w3.org/TR/SVG11/struct.html#DefsElement
     * @param props any properties
     * @param children a concatenated string containing the child elements.
     */
    function defs(string memory props, string memory children)
        public
        pure
        returns (string memory)
    {
        return el("defs", props, children);
    }

    /* SHAPES */
    /* https://www.w3.org/TR/SVG11/shapes.html */

    /**
     * @dev builds a line element
     * @dev see https://www.w3.org/TR/SVG11/shapes.html#LineElement
     * @param p1 the start of the line
     * @param p2 the end of the line
     * @param props additional line properties
     */
    function line(
        Point memory p1,
        Point memory p2,
        string memory props
    ) public pure returns (string memory) {
        return el("line", _lineProps(p1, p2, props));
    }

    /**
     * @dev builds a line element with children
     * @dev see https://www.w3.org/TR/SVG11/shapes.html#LineElement
     * @param p1 the start of the line
     * @param p2 the end of the line
     * @param props additional line properties
     * @param children a concatenated string containing any inner animation or
     *     descriptive elements
     */
    function line(
        Point memory p1,
        Point memory p2,
        string memory props,
        string memory children
    ) public pure returns (string memory) {
        return el("line", _lineProps(p1, p2, props), children);
    }

    function _lineProps(
        Point memory p1,
        Point memory p2,
        string memory props
    ) internal pure returns (string memory) {
        return
            string.concat(
                prop("x1", p1.x),
                prop("y1", p1.y),
                prop("x2", p2.x),
                prop("y2", p2.y),
                props
            );
    }

    /**
     * @dev builds a circle element
     * @dev see https://www.w3.org/TR/SVG11/shapes.html#CircleElement
     * @param center the circle center point
     * @param radius the circle radius (number or %)
     * @param props additional circle properties
     */
    function circle(
        Point memory center,
        string memory radius,
        string memory props
    ) public pure returns (string memory) {
        return el("circle", _circleProps(center, radius, props));
    }

    /**
     * @dev builds a circle element with children
     * @dev see https://www.w3.org/TR/SVG11/shapes.html#CircleElement
     * @param center the circle center point
     * @param radius the circle radius (number or %)
     * @param props additional circle properties
     * @param children a concatenated string containing any inner animation or
     *     descriptive elements
     */
    function circle(
        Point memory center,
        string memory radius,
        string memory props,
        string memory children
    ) public pure returns (string memory) {
        return el("circle", _circleProps(center, radius, props), children);
    }

    function _circleProps(
        Point memory center,
        string memory radius,
        string memory props
    ) internal pure returns (string memory) {
        return
            string.concat(
                prop("cx", center.x),
                prop("cy", center.y),
                prop("r", radius),
                props
            );
    }

    /**
     * @dev builds an ellipse element
     * @dev see https://www.w3.org/TR/SVG11/shapes.html#EllipseElement
     * @param center the ellipse center point
     * @param rx the x-axis radius (number or %)
     * @param ry the y-axis radius (number or %)
     * @param props additional ellipse properties
     */
    function ellipse(
        Point memory center,
        string memory rx,
        string memory ry,
        string memory props
    ) public pure returns (string memory) {
        return el("ellipse", _ellipseProps(center, rx, ry, props));
    }

    /**
     * @dev builds an ellipse element with children
     * @dev see https://www.w3.org/TR/SVG11/shapes.html#EllipseElement
     * @param center the ellipse center point
     * @param rx the x-axis radius (number or %)
     * @param ry the y-axis radius (number or %)
     * @param props additional ellipse properties
     * @param children a concatenated string containing any inner animation or
     *     descriptive elements
     */
    function ellipse(
        Point memory center,
        string memory rx,
        string memory ry,
        string memory props,
        string memory children
    ) public pure returns (string memory) {
        return el("ellipse", _ellipseProps(center, rx, ry, props), children);
    }

    function _ellipseProps(
        Point memory center,
        string memory rx,
        string memory ry,
        string memory props
    ) internal pure returns (string memory) {
        return
            string.concat(
                prop("cx", center.x),
                prop("cy", center.y),
                prop("rx", rx),
                prop("ry", ry),
                props
            );
    }

    /**
     * @dev builds a rectangle element
     * @dev see https://www.w3.org/TR/SVG11/shapes.html#RectElement
     * @param bounds the rectangle dimensions
     * @param props additional rectangle properties.
     */
    function rect(Box memory bounds, string memory props)
        public
        pure
        returns (string memory)
    {
        return el("rect", _rectProps(bounds, props));
    }

    /**
     * @dev builds a rectangle element with children
     * @dev see https://www.w3.org/TR/SVG11/shapes.html#RectElement
     * @param bounds the rectangle dimensions
     * @param props additional rectangle properties.
     * @param children a concatenated string containing any inner animation or
     *     descriptive elements
     */
    function rect(
        Box memory bounds,
        string memory props,
        string memory children
    ) public pure returns (string memory) {
        return el("rect", _rectProps(bounds, props), children);
    }

    function _rectProps(Box memory bounds, string memory props)
        internal
        pure
        returns (string memory)
    {
        return
            string.concat(
                prop("x", bounds.x),
                prop("y", bounds.y),
                prop("width", bounds.width),
                prop("height", bounds.height),
                props
            );
    }

    /**
     * @dev build a path element.
     * @dev a path is an outline of a shape that can be filled, stroked, or
     *     used as a clipping path.
     * @dev see https://www.w3.org/TR/SVG11/paths.html
     * @param pathData a space-delimited list of path commands
     * @param props additional path properties
     * - pathLength=Scale the path to fit this length
     */
    function path(string memory pathData, string memory props)
        public
        pure
        returns (string memory)
    {
        return el("path", _pathProps(pathData, props));
    }

    /**
     * @dev build a path element with children.
     * @dev a path is an outline of a shape that can be filled, stroked, or
     *     used as a clipping path.
     * @dev see https://www.w3.org/TR/SVG11/paths.html
     * @param pathData a space-delimited list of path commands
     * @param props additional path properties
     * - pathLength=Scale the path to fit this length
     * @param children a concatenated string containing any inner animation or
     *     descriptive elements
     */
    function path(
        string memory pathData,
        string memory props,
        string memory children
    ) public pure returns (string memory) {
        return el("path", _pathProps(pathData, props), children);
    }

    function _pathProps(string memory pathData, string memory props)
        internal
        pure
        returns (string memory)
    {
        return string.concat(prop("d", pathData), props);
    }

    /**
     * @dev builds a polyline element
     * @dev A polyline is a special case of path, with a moveto operation to
     *    the first cooridinate pair, and lineto operations to each subsequent
     *    coordinate pair.
     * @dev https://www.w3.org/TR/SVG11/shapes.html#PolylineElement
     * @param points a space-delimited list of points
     * @param props additional polyline properties.
     */
    function polyline(string memory points, string memory props)
        public
        pure
        returns (string memory)
    {
        return el("polyline", _polylineProps(points, props));
    }

    /**
     * @dev builds a polyline element with children
     * @dev A polyline is a special case of path, with a moveto operation to
     *    the first cooridinate pair, and lineto operations to each subsequent
     *    coordinate pair.
     * @dev https://www.w3.org/TR/SVG11/shapes.html#PolylineElement
     * @param points a space-delimited list of points
     * @param props additional polyline properties.
     * @param children a concatenated string containing any inner animation or
     *     descriptive elements
     */
    function polyline(
        string memory points,
        string memory props,
        string memory children
    ) public pure returns (string memory) {
        return el("polyline", _polylineProps(points, props), children);
    }

    /**
     * @dev builds a polygon element
     * @dev A polygon is a special case of path, with a moveto operation to
     *    the first cooridinate pair, lineto operations to each subsequent
     *    coordinate pair, followed by a closepath command.
     * @dev https://www.w3.org/TR/SVG11/shapes.html#PolygonElement
     * @param points a space-delimited list of points
     * @param props additional polygon properties.
     */
    function polygon(string memory points, string memory props)
        public
        pure
        returns (string memory)
    {
        return el("polygon", _polylineProps(points, props));
    }

    /**
     * @dev builds a polygon element with children
     * @dev A polygon is a special case of path, with a moveto operation to
     *    the first cooridinate pair, lineto operations to each subsequent
     *    coordinate pair, followed by a closepath command.
     * @dev https://www.w3.org/TR/SVG11/shapes.html#PolygonElement
     * @param points a space-delimited list of points
     * @param props additional polygon properties.
     * @param children a concatenated string containing any inner animation or
     *     descriptive elements
     */
    function polygon(
        string memory points,
        string memory props,
        string memory children
    ) public pure returns (string memory) {
        return el("polygon", _polylineProps(points, props), children);
    }

    function _polylineProps(string memory points, string memory props)
        internal
        pure
        returns (string memory)
    {
        return string.concat(prop("points", points), props);
    }

    /* TEXT */
    /* see https://www.w3.org/TR/SVG11/text.html */

    /**
     * @dev builds a text element
     * @dev see https://www.w3.org/TR/SVG11/text.html#TextElement
     * @param props the text element properties
     * - x=a single number or % for the x-axis location of the first letter, or
     *     a list to set the horizontal position of each letter
     * - y=a single number or % for the y-axis location of the first letter, or
     *     a list to set the vertical position of each letter
     * - dx=horizontal spacing between letters if not specified in x
     * - dy=vertical spacing between letters if not specified in y
     * - rotate=a list of rotations
     * - textLength=a target length for the text
     * - lengthAdjust=either 'spacing' or 'spacingAndGlyphs'; what to adjust to
     *     reach the target length.
     * @param children the text, a CDATA element, or a concatenated string
     *      containing tspan elements, animation, or descriptive elements
     */
    function text(string memory props, string memory children)
        public
        pure
        returns (string memory)
    {
        return el("text", props, children);
    }

    /**
     * @dev build a tspan element, embeddable in text or parent tspan elements
     * @dev see https://www.w3.org/TR/SVG11/text.html#TSpanElement
     * @param props see `text`
     * @param children see `text`
     */
    function tspan(string memory props, string memory children)
        public
        pure
        returns (string memory)
    {
        return el("tspan", props, children);
    }

    /**
     * @dev builds a tref element
     * @dev see https://www.w3.org/TR/SVG11/text.html#TRefElement
     * @param link a reference to a previously defined text element
     * @param props additional text properties
     */
    function tref(string memory link, string memory props)
        public
        pure
        returns (string memory)
    {
        return el("tref", _trefProps(link, props));
    }

    /**
     * @dev builds a tref element with children
     * @dev see https://www.w3.org/TR/SVG11/text.html#TRefElement
     * @param link a reference to a previously defined text element
     * @param props additional text properties
     * @param children a concatenated string containing any inner animation or
     *     descriptive elements
     */
    function tref(
        string memory link,
        string memory props,
        string memory children
    ) public pure returns (string memory) {
        return el("tref", _trefProps(link, props), children);
    }

    function _trefProps(string memory link, string memory props)
        internal
        pure
        returns (string memory)
    {
        return string.concat(prop("link", link), props);
    }

    /**
     * @dev builds a CDATA element
     * @param content the text
     */
    function cdata(string memory content) public pure returns (string memory) {
        return string.concat("<![CDATA[", content, "]]>");
    }

    /* FILTERS, GRADIENTS, and PATTERNS */

    /**
     * @dev defines a filter element
     * @dev use `el(primitiveName, props)` to build the primitives.
     * @dev see https://www.w3.org/TR/SVG11/filters.html for primitive attributes.
     * @param id the unique id to reference the filter
     * @param props the properties for the filter
     * - filterUnits=either "userSpaceOnUse" or "objectBoundingBox"; how to
     *     determine the vector point positions. Default is "objectBoundingBox".
     * - x=horizontal start point of the filter clipping region. Default is -10%.
     * - y=vertical start point of the filter clipping region. Default is -10%.
     * - width=horizontal length of the filter clipping region. Default is 120%.
     * - height=vertical length of the filter clipping region. Default is 120%.
     * - xlink:href=reference to another filter to inherit attributes
     * @param children a concatenated string containing the filter primitives.
     */
    function filter(
        string memory id,
        string memory props,
        string memory children
    ) public pure returns (string memory) {
        return el("filter", string.concat(prop("id", id), props), children);
    }

    /**
     * @dev builds a radial gradient
     * @dev this MUST occur within a <defs> element.
     * @dev see https://www.w3.org/TR/SVG11/pservers.html#LinearGradients
     * @param id the unique id to reference the gradient
     * @param props the properties for the gradient
     * - gradientUnits=either "userSpaceOnUse" or "objectBoundingBox"; how to
     *     determine the vector point positions. Default is "objectBoundingBox".
     * - gradientTransform=transformation to apply
     * - cx=horizontal center of gradient. Default is "50%"
     * - cy=vertical center of gradient. Default is "50%"
     * - fx=horizontal focus of gradient. Default is "0%"
     * - fy=vertical focus of gradient. Default is "0%"
     * - spreadMethod="pad", "reflect", or "repeat"
     * - href=reference to another gradient, to inherit values and stops
     * @param children a concatenated string containing <stop> elements.
     */
    function radialGradient(
        string memory id,
        string memory props,
        string memory children
    ) public pure returns (string memory) {
        return
            el(
                "radialGradient",
                string.concat(prop("id", id), props),
                children
            );
    }

    /**
     * @dev builds a linear gradient
     * @dev this MUST occur within a <defs> element.
     * @dev see https://www.w3.org/TR/SVG11/pservers.html#RadialGradients
     * @param id the unique id to reference the gradient
     * @param props the properties for the gradient
     * - gradientUnits=either "userSpaceOnUse" or "objectBoundingBox"; how to
     *     determine the vector point positions. Default is "objectBoundingBox".
     * - gradientTransform=transformation to apply
     * - x1=horizontal start point. Default is 0%.
     * - y1=vertical start point. Default is 0%.
     * - x2=horizontal end point. Default is 100%.
     * - y2=vertical end point. Default is 100%.
     * - spreadMethod="pad", "reflect", or "repeat"
     * - href=reference to another gradient, to inherit values and stops
     * @param children a concatenated string containing <stop> elements.
     */
    function linearGradient(
        string memory id,
        string memory props,
        string memory children
    ) public pure returns (string memory) {
        return
            el(
                "linearGradient",
                string.concat(prop("id", id), props),
                children
            );
    }

    /**
     * @dev builds a stop for a gradient
     * @dev Your gradient needs stops at offsets 0% and 100%.
     * @dev You can put more stops in between to make a fancy gradient.
     * @dev see https://www.w3.org/TR/SVG11/pservers.html#GradientStops
     * @param offset the offset for the stop, 0% to 100%
     * @param stopColor the color of the stop
     * @param props additional properties
     * - stop-opacity=the opacity, 0.0-1.0
     */
    function gradientStop(
        uint256 offset,
        string memory stopColor,
        string memory props
    ) public pure returns (string memory) {
        return
            el(
                "stop",
                string.concat(
                    prop("stop-color", stopColor),
                    " ",
                    prop(
                        "offset",
                        string.concat(Strings.toString(offset), "%")
                    ),
                    " ",
                    props
                )
            );
    }

    /**
     * @dev builds a pattern
     * @dev this should go in a <defs> element and be referenced in a fill
     *     attribute.
     * @dev see https://www.w3.org/TR/SVG11/pservers.html#Patterns
     * @param id the unique id to reference the pattern
     * - patternUnits='userSpaceOnUse' or 'objectBoundingBox', defines the
     *     coordinate space for the bounding box surrounding the pattern
     *     contents. Default is 'objectBoundingBox'.
     * - patternContentUnits=''userSpaceOnUse' or 'objectBoundingBox', defines
     *     the coordinate space for the elements in the pattern content.
     *     Default is 'userSpaceOnUse'.
     * - patternTransform=additional transformations to apply, used for skewing
     *     etc. Default is no transformation (identity matrix).
     * - x=upper left corner of the pattern bounding box
     * - y=upper left corner of the pattern bounding box
     * - width=bounding box width
     * - height=bounding box height
     * - link=reference to another pattern to inherit attributes. If this
     *     pattern has no children, it will inherit children from the
     *     refrerenced pattern.
     * - preserveAspectRatio=default is 'xMidYMid meet', see
     *      https://www.w3.org/TR/SVG11/coords.html#PreserveAspectRatioAttribute
     * @param props the properties for the pattern
     * @param children a concatenated string the elements that make the pattern
     */
    function pattern(
        string memory id,
        string memory props,
        string memory children
    ) public pure returns (string memory) {
        return el("pattern", string.concat(prop("id", id), props), children);
    }

    /**
     * @dev builds an <image> element.
     * @dev see https://www.w3.org/TR/SVG11/struct.html#ImageElement
     * @param href the path to the image, either PNG, JPEG, or 'image/svg+xml'
     * @param bounds the image dimensions
     * @param props additional image properties.
     */
    function image(
        string memory href,
        Box memory bounds,
        string memory props
    ) public pure returns (string memory) {
        return el("image", _imageProps(href, bounds, props));
    }

    /**
     * @dev builds an <image> element.
     * @dev see https://www.w3.org/TR/SVG11/struct.html#ImageElement
     * @param href the path to the image, either PNG, JPEG, or 'image/svg+xml'
     * @param bounds the image dimensions
     * @param props additional image properties.
     * @param children any children
     */
    function image(
        string memory href,
        Box memory bounds,
        string memory props,
        string memory children
    ) public pure returns (string memory) {
        return el("image", _imageProps(href, bounds, props), children);
    }

    function _imageProps(
        string memory href,
        Box memory bounds,
        string memory props
    ) internal pure returns (string memory) {
        return
            string.concat(
                prop("xlink:href", href),
                prop("x", bounds.x),
                prop("y", bounds.y),
                prop("width", bounds.width),
                prop("height", bounds.height),
                props
            );
    }

    /* COMMON */
    /**
     * @dev build any SVG element (or html or xml) with children
     * @param tag the element type
     * @param props the element attributes
     * @param children the concatenated inner elements
     */
    function el(
        string memory tag,
        string memory props,
        string memory children
    ) public pure returns (string memory) {
        return
            string.concat("<", tag, " ", props, ">", children, "</", tag, ">");
    }

    /**
     * @dev build any SVG element (or html or xml) without children
     * @param tag the element type
     * @param props the element attributes
     */
    function el(string memory tag, string memory props)
        public
        pure
        returns (string memory)
    {
        return string.concat("<", tag, " ", props, "/>");
    }

    /**
     * @dev build an element attribute, `key`="`val`"
     * @param key the attribute name
     * @param val the attribute value
     */
    function prop(string memory key, string memory val)
        public
        pure
        returns (string memory)
    {
        return string.concat(key, "=", '"', val, '" ');
    }

    /**
     * @dev build a <style> element.
     * @dev This should be inside a <defs> element.
     * @param css the entire cascading style sheet.
     */
    function styleSheet(string memory css) public pure returns (string memory) {
        return el("style", 'type="text/css"', cdata(css));
    }

    /**
     * @dev builds a css style rule
     * @param selector the css selector
     * @param styles the styles for the selector (i.e. everything inside the
     *     curly brackets)
     */
    function cssRule(string memory selector, string memory styles)
        public
        pure
        returns (string memory)
    {
        return string.concat(selector, " {", styles, "}\n");
    }

    /**
     * @dev build a css style element, `key`:`val`;
     * @dev can be used for an inline style attribute or in a style sheet.
     * @param key the style element name
     * @param val the style value
     */
    function style(string memory key, string memory val)
        public
        pure
        returns (string memory)
    {
        return string.concat(key, ":", val, ";");
    }
}

// File: AbstractDynamicURI.sol

abstract contract AbstractDynamicURI is DynamicURI, ERC165 {
    modifier onlyURIManager() {
        require(_canUpdateURIs(msg.sender), "");
        _;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(DynamicURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev returns true if the account has permission to update URIs
     * @dev you probably want to override this to set your permissions model.
     */
    function _canUpdateURIs(address) internal view virtual returns (bool) {
        return true;
    }
}

// File: ViciAccess.sol

/**
 * @title ViciAccess
 * @author Josh Davis <[email protected]>
 */
abstract contract ViciAccess is IAccessControlEnumerable, Context, ERC165 {
    using AccessManagement for AccessManagement.AccessManagementState;

    AccessManagement.AccessManagementState ams;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    // Role for banned users.
    bytes32 public constant BANNED_ROLE_NAME = "banned";

    // Role for moderator.
    bytes32 public constant MODERATOR_ROLE_NAME = "moderator";

    /**
     * @dev Emitted when `previousOwner` transfers ownership to `newOwner`.
     */
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        ams.setContractOwner(msg.sender);
        ams.initSanctions();
        ams.setRoleAdmin(BANNED_ROLE_NAME, MODERATOR_ROLE_NAME);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceId == type(IAccessControl).interfaceId ||
            interfaceId == type(IAccessControlEnumerable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

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
     * @dev reverts if called by an account that is not the owner and doesn't 
     *     have the required role.
     */
    modifier onlyOwnerOrRole(bytes32 role) {
        if (_msgSender() != owner()) {
            _checkRole(role, _msgSender());
        }
        _;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        ams.enforceIsContractOwner(_msgSender());
        _;
    }

    /**
     * @dev reverts if the caller is banned or on the OFAC sanctions list.
     */
    modifier noBannedAccounts() {
        ams.enforceIsNotBanned(_msgSender());
        _;
    }

    /**
     * @dev reverts if the account is banned or on the OFAC sanctions list.
     */
    modifier notBanned(address account) {
        ams.enforceIsNotBanned(account);
        _;
    }

    /**
     * @dev Revert if the address is on the OFAC sanctions list
     */
    modifier notSanctioned(address addr) {
        ams.enforceIsNotSanctioned(addr);
        _;
    }

    /**
     * @dev returns true if the account is banned.
     */
    function isBanned(address account) public view virtual returns (bool) {
        return hasRole(BANNED_ROLE_NAME, account);
    }

    /**
     * @dev returns true if the account is on the OFAC sanctions list.
     */
    function isSanctioned(address account) public view virtual returns (bool) {
        return ams.isSanctioned(account);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account)
        public
        view
        override
        returns (bool)
    {
        return ams.hasRole(role, account);
    }

    /**
     * @notice toggles the sanctions compliance flag
     * @notice this flag should only be turned off during testing or if there
     *     is some problem with the sanctions oracle.
     *
     * Requirements:
     * - Caller must be the contract owner
     */
    function toggleSanctionsCompliance() public onlyOwner {
        ams.toggleSanctionsCompliance();
    }

    /**
     * @dev returns true if sanctions compliance is enabled.
     */
    function sanctionsComplianceEnabled() public view returns (bool) {
        return ams.isSanctionsComplianceEnabled();
    }

    /**
     * @notice Sets the sanction list oracle
     * @notice Reverts unless the contract is running on a local HardHat or
     *      Ganache chain.
     * @param _sanctionsList the oracle address
     */
    function setSanctions(ChainalysisSanctionsList _sanctionsList) public {
        ams.setSanctions(_sanctionsList);
    }

    /**
     * @notice returns the address of the OFAC sanctions oracle.
     */
    function sanctionsOracle() public view returns (address) {
        return ams.getSanctionsOracle();
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        ams.checkRole(role, account);
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return ams.getRoleAdmin(role);
    }

    /**
     * @dev Sets the admin role that controls a role.
     * 
     * Requirements:
     * - caller MUST be the owner or have the admin role.
     */
    function setRoleAdmin(bytes32 role, bytes32 adminRole)
        public
        onlyOwnerOrRole(DEFAULT_ADMIN_ROLE)
    {
        ams.setRoleAdmin(role, adminRole);
    }

    /**
     *  Requirements:
     *
     * - Calling user MUST have the admin role
     * - If `role` is banned, calling user MUST be the owner
     *   and `address` MUST NOT be the owner.
     * - If `role` is not banned, `account` MUST NOT be under sanctions.
     *
     * @inheritdoc IAccessControl
     */
    function grantRole(bytes32 role, address account) public virtual override {
        ams.grantRole(role, account);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return ams.getContractOwner();
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index)
        public
        view
        override
        returns (address)
    {
        return ams.getRoleMember(role, index);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role)
        public
        view
        override
        returns (uint256)
    {
        return ams.getRoleMemberCount(role);
    }

    /**
     * Make another account the owner of this contract.
     * @param newOwner the new owner.
     *
     * Requirements:
     *
     * - Calling user MUST be owner.
     * - `newOwner` MUST NOT have the banned role.
     */
    function transferOwnership(address newOwner) public virtual {
        ams.setContractOwner(newOwner);
    }

    /**
     * Take the role away from the account. This will throw an exception
     * if you try to take the admin role (0x00) away from the owner.
     *
     * Requirements:
     *
     * - Calling user has admin role.
     * - If `role` is admin, `address` MUST NOT be owner.
     * - if `role` is banned, calling user MUST be owner.
     *
     * @inheritdoc IAccessControl
     */
    function revokeRole(bytes32 role, address account) public virtual override {
        ams.revokeRole(role, account);
    }

    /**
     * Take a role away from yourself. This will throw an exception if you
     * are the contract owner and you are trying to renounce the admin role (0x00).
     *
     * Requirements:
     *
     * - if `role` is admin, calling user MUST NOT be owner.
     * - `account` is ignored.
     * - `role` MUST NOT be banned.
     *
     * @inheritdoc IAccessControl
     */
    function renounceRole(bytes32 role, address) public virtual override {
        ams.renounceRole(role);
    }

    /**
     * Take a role away from yourself. This will throw an exception if you
     * are the contract owner and you are trying to renounce the admin role (0x00).
     *
     * Requirements:
     *
     * - if `role` is admin, calling user MUST NOT be owner.
     * - `role` MUST NOT be banned.
     */
    function renounceRole(bytes32 role) public virtual {
        ams.renounceRole(role);
    }
}

// File: BaseViciContract.sol

abstract contract BaseViciContract is ViciAccess, Pausable {
	constructor() {
	}

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - Calling user MUST be owner.
     * - The contract must not be paused.
     */
	function pause() external onlyOwner {
		_pause();
	}

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - Calling user MUST be owner.
     * - The contract must be paused.
     */
	function unpause() external onlyOwner {
		_unpause();
	}
	
	function _withdrawERC20(
		uint256 amount,
		address payable toAddress,
		IERC20 tokenContract
	) internal virtual {
		tokenContract.transfer(toAddress, amount);
	}
	
	function withdrawERC20(
		uint256 amount,
		address payable toAddress,
		IERC20 tokenContract
	) public onlyOwner virtual {
		_withdrawERC20(amount, toAddress, tokenContract);
	}
	
	function _withdrawERC721(
		uint256 tokenId,
		address payable toAddress,
		IERC721 tokenContract
	) internal virtual {
		tokenContract.safeTransferFrom(address(this), toAddress, tokenId);
	}
	
	function withdrawERC721(
		uint256 tokenId,
		address payable toAddress,
		IERC721 tokenContract
	) public virtual onlyOwner {
		_withdrawERC721(tokenId, toAddress, tokenContract);
	}
	
	function _withdrawERC1155(
		uint256 tokenId,
		uint256 amount,
		address payable toAddress,
        bytes calldata data,
		IERC1155 tokenContract
	) internal virtual {
		tokenContract.safeTransferFrom(
			address(this), toAddress, tokenId, amount, data
		);
	}
	
	function withdrawERC1155(
		uint256 tokenId,
		uint256 amount,
		address payable toAddress,
        bytes calldata data,
		IERC1155 tokenContract
	) public virtual onlyOwner {
		_withdrawERC1155(tokenId, amount, toAddress, data, tokenContract);
	}
	
	function _withdraw(
		address payable toAddress
	) internal virtual {
		toAddress.transfer(address(this).balance);
	}
	
	function withdraw(
		address payable toAddress
	) public virtual onlyOwner {
		_withdraw(toAddress);
	}

	receive() external payable virtual {}
}
// File: ReliefDAOBuilder.sol

/**
 * @title Dynamic Content Builder
 * @dev builds the dynamic content of the Relief DAO NFTs
 */
abstract contract ReliefDAOBuilder is AbstractDynamicURI, BaseViciContract {
    using EnumerableSet for EnumerableSet.AddressSet;

    struct LogoElement {
        string dPath;
        string aPath;
        string oPath;
        string logoTransform;
        string logoTextY;
        string logoTextClass;
        string logoText;
    }

    struct FundingElement {
        string fundAmountY;
        string fundAmountClass;
        string fundNameY;
        string fundNameClass;
        string fundName;
    }

    struct NoNomElement {
        string nomPendingY;
        string nomPendingClass;
        string nomPendingText;
        string nomAskY;
        string nomAskY2;
        string nomAskClass;
        string nomAskPrefix;
        string nomAskLinkText;
        string nomAskSuffix;
        string nomAskLine2;
    }

    struct NomCountElement {
        string largeY;
        string largeClass;
        string smallY;
        string smallClass;
        string singleText;
        string pluralPrefix;
        string pluralSuffix;
    }

    struct NomNameElement {
        string largeY;
        string largeClass;
        string smallY;
        string smallClass;
        uint256 maxLength;
        uint256 smallFontThresholdLength;
    }

    struct RunningMarginal {
        string marginalY;
        string marginalClass;
        string marginalText;
    }

    bytes32 public constant URI_MANAGER = "uri manager";

    string constant NOM_PENDING = "Your nomination will be recorded soon.";
    string constant NOMINATED = "You nominated ";
    string constant VOTING = "You voted for ";

    /**
     * @dev the main part of the NFT description metadata
     */
    string public desc = "";

    /**
     * @dev the link to nominate.
     */
    string public nominationURL = "";

    /**
     * @dev the external_url NFT metadata
     */
    string public regularURL = "";
    string css = "";

    // EnumerableSet.AddressSet sellerAddresses;

    INominator tokens;
    IReliefDaoOracle oracle;

    RunningMarginal headerElement;
    LogoElement logoElement;
    string[] extraLogoPaths;
    FundingElement fundingElement;
    NoNomElement noNomElement;
    NomCountElement nomCountElement;
    NomNameElement nomNameElement;
    RunningMarginal footerElement;

    constructor(INominator _tokens, IReliefDaoOracle _oracle) {
        tokens = _tokens;
        oracle = _oracle;
        _initDefaults();
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AbstractDynamicURI, ViciAccess)
        returns (bool)
    {
        return
            AbstractDynamicURI.supportsInterface(interfaceId) ||
            ViciAccess.supportsInterface(interfaceId);
    }

    function _canUpdateURIs(address account)
        internal
        view
        override
        returns (bool)
    {
        return account == owner() || hasRole(URI_MANAGER, account);
    }

    /**
     * @dev allows changing the oracle contract.
     *
     * Requirements:
     * - caller MUST be the contract owner or have the URI_MANAGER role.
     */
    function setOracle(IReliefDaoOracle _oracle) public onlyURIManager {
        oracle = _oracle;
    }

    /**
     * @dev updates the stylesheet used to format the svg image
     *
     * Requirements:
     * - caller MUST be the contract owner or have the URI_MANAGER role.
     */
    function setCss(string memory newCss) public onlyURIManager {
        css = newCss;
    }

    /**
     * @dev updates the nomination URL
     *
     * Requirements:
     * - caller MUST be the contract owner or have the URI_MANAGER role.
     */
    function setNominationURL(string memory newURL) public onlyURIManager {
        nominationURL = newURL;
    }

    /**
     * @dev updates the external_url
     *
     * Requirements:
     * - caller MUST be the contract owner or have the URI_MANAGER role.
     */
    function setRegularURL(string memory newURL) public onlyURIManager {
        regularURL = newURL;
    }

    /**
     * @dev updates the NFT description metadata.
     *
     * Requirements:
     * - caller MUST be the contract owner or have the URI_MANAGER role.
     */
    function setDesc(string memory newDesc) public onlyURIManager {
        desc = newDesc;
    }

    // function addSellerAddress(address sellerAddress) public onlyURIManager {
    //     sellerAddresses.add(sellerAddress);
    // }

    // function removeSellerAddress(address sellerAddress) public onlyURIManager {
    //     sellerAddresses.remove(sellerAddress);
    // }

    /**
     * @dev returns the base64 encoded application/json URI.
     */
    function tokenURI(uint256 tokenId) public view returns (string memory) {
        CandidateInfo memory candidate = oracle.candidateNominatedBy(tokenId);
        string memory description = buildDescription(tokenId, candidate);
        string memory tokenName = tokens.getNFTName(tokenId);
        string memory image = buildSVG(tokenId, candidate);

        return
            svg.svgElementToTokenURI(
                svg.svgToImageURI(image),
                tokenName,
                regularURL,
                description
            );
    }

    function imageURI(uint256 tokenId) public view returns (string memory) {
        CandidateInfo memory candidate = oracle.candidateNominatedBy(tokenId);

        string memory image = buildSVG(tokenId, candidate);

        return svg.svgToImageURI(image);
    }

    /**
     * @dev returns the description metadata for the token and the candidate.
     */
    function buildDescription(uint256 tokenId, CandidateInfo memory candidate)
        internal
        view
        returns (string memory)
    {
        string memory preliminary;

        if (candidate.candidateId == 0) {
            if (tokens.hasNominated(tokenId)) {
                preliminary = NOM_PENDING;
            } else {
                preliminary = string.concat(
                    "Please go to [",
                    nominationURL,
                    "](",
                    nominationURL,
                    ") to nominate a candidate.\\n\\n"
                );
            }
        } else {
            preliminary = string.concat(
                NOMINATED,
                "**",
                candidateName(candidate),
                "** of ",
                bytes32ToString(candidate.location),
                "."
            );
        }

        return string.concat(preliminary, " ", desc);
    }

    function buildSVG(uint256 tokenId, CandidateInfo memory candidate)
        internal
        view
        returns (string memory)
    {
        return
            svg.svgDocument(
                svg.prop("viewBox", "0 0 1080 1080"),
                string.concat(
                    svg.defs(buildDefs()),
                    svg.rect(
                        Box("0", "0", "1080", "1080"),
                        svg.prop("class", "bg")
                    ),
                    logo(),
                    totalsLabels(tokenId, candidate)
                )
            );
    }

    function buildDefs() internal view virtual returns (string memory) {
        return svg.styleSheet(css);
    }

    function logo() internal view virtual returns (string memory) {
        return
            svg.g(
                svg.prop("id", "full-logo"),
                string.concat(
                    svg.g(
                        string.concat(
                            svg.prop("id", "logo"),
                            svg.prop("transform", logoElement.logoTransform)
                        ),
                        string.concat(
                            svg.path(logoElement.dPath, ""),
                            svg.path(logoElement.aPath, ""),
                            svg.path(logoElement.oPath, ""),
                            getExtraLogoPaths()
                        )
                    ),
                    svg.text(
                        textProps(
                            "logo-text",
                            logoElement.logoTextY,
                            logoElement.logoTextClass
                        ),
                        logoElement.logoText
                    )
                )
            );
    }

    function getExtraLogoPaths()
        internal
        view
        virtual
        returns (string memory paths)
    {
        paths = "";
        for (uint256 i = 0; i < extraLogoPaths.length; i++) {
            paths = string.concat(paths, svg.path(extraLogoPaths[i], ""));
        }
    }

    function totalsLabels(uint256 tokenId, CandidateInfo memory candidate)
        internal
        view
        virtual
        returns (string memory)
    {
        return
            string.concat(
                marginalText("head", headerElement),
                svg.text(
                    textProps(
                        "total",
                        fundingElement.fundAmountY,
                        fundingElement.fundAmountClass
                    ),
                    oracle.progress()
                ),
                svg.text(
                    textProps(
                        "label",
                        fundingElement.fundNameY,
                        fundingElement.fundNameClass
                    ),
                    fundingElement.fundName
                ),
                userSummary(tokenId, candidate),
                marginalText("foot", footerElement)
            );
    }

    function marginalText(string memory id, RunningMarginal storage element)
        internal
        view
        virtual
        returns (string memory)
    {
        if (bytes(element.marginalText).length == 0) {
            return "";
        }
        return
            svg.text(
                textProps(id, element.marginalY, element.marginalClass),
                element.marginalText
            );
    }

    function userSummary(uint256 tokenId, CandidateInfo memory candidate)
        internal
        view
        virtual
        returns (string memory)
    {
        if (candidate.candidateId == 0) {
            if (tokens.hasNominated(tokenId)) {
                return
                    svg.text(
                        textProps(
                            "noms",
                            noNomElement.nomPendingY,
                            noNomElement.nomPendingClass
                        ),
                        noNomElement.nomPendingText
                    );
            } else {
                return
                    string.concat(
                        svg.text(
                            textProps(
                                "noms",
                                noNomElement.nomAskY,
                                noNomElement.nomAskClass
                            ),
                            string.concat(
                                svg.tspan("", noNomElement.nomAskPrefix),
                                svg.el(
                                    "a",
                                    string.concat(
                                        svg.prop("xlink:href", nominationURL),
                                        svg.prop("target", "_blank")
                                    ),
                                    svg.tspan("", noNomElement.nomAskLinkText)
                                ),
                                svg.tspan("", noNomElement.nomAskSuffix)
                            )
                        ),
                        svg.text(
                            textProps(
                                "yours",
                                noNomElement.nomAskY2,
                                noNomElement.nomAskClass
                            ),
                            noNomElement.nomAskLine2
                        )
                    );
            }
        } else {
            string memory rName = ellipsize(
                candidateName(candidate),
                nomNameElement.maxLength
            );
            string memory nomText;
            if (candidate.votes == 1) {
                nomText = nomCountElement.singleText;
            } else {
                nomText = string.concat(
                    nomCountElement.pluralPrefix,
                    Strings.toString(candidate.votes),
                    nomCountElement.pluralSuffix
                );
            }

            if (
                abi.encodePacked(rName).length >=
                nomNameElement.smallFontThresholdLength
            ) {
                return _candidateSmallNomText(nomText, rName);
            }
            return _candidateNomText(nomText, rName);
        }
    }

    function _candidateNomText(string memory nomText, string memory rName)
        internal
        view
        virtual
        returns (string memory)
    {
        return
            string.concat(
                svg.text(
                    textProps(
                        "noms",
                        nomCountElement.largeY,
                        nomCountElement.largeClass
                    ),
                    nomText
                ),
                svg.text(
                    textProps(
                        "yours",
                        nomNameElement.largeY,
                        nomNameElement.largeClass
                    ),
                    rName
                )
            );
    }

    function _candidateSmallNomText(string memory nomText, string memory rName)
        internal
        view
        virtual
        returns (string memory)
    {
        return
            string.concat(
                svg.text(
                    textProps(
                        "noms",
                        nomCountElement.smallY,
                        nomCountElement.smallClass
                    ),
                    nomText
                ),
                svg.text(
                    textProps(
                        "yours",
                        nomNameElement.smallY,
                        nomNameElement.smallClass
                    ),
                    rName
                )
            );
    }

    function candidateName(CandidateInfo memory candidate)
        internal
        pure
        virtual
        returns (string memory)
    {
        return
            string.concat(
                bytes32ToString(candidate.candidateName),
                bytes32ToString(candidate.candidateName2)
            );
    }

    function ellipsize(string memory input, uint256 maxLength)
        public
        pure
        returns (string memory)
    {
        bytes memory inBytes = abi.encodePacked(input);
        if (inBytes.length <= maxLength) {
            return input;
        }

        inBytes[maxLength - 3] = ".";
        inBytes[maxLength - 2] = ".";
        inBytes[maxLength - 1] = ".";

        assembly {
            mstore(inBytes, maxLength)
        }

        return string(inBytes);
    }

    function bytes32ToString(bytes32 input)
        internal
        pure
        returns (string memory)
    {
        bytes memory temp = abi.encodePacked(input);
        uint256 homeslice = 0;
        for (uint256 i = 0; i < temp.length; i++) {
            if (temp[i] == 0) {
                break;
            } else {
                homeslice = i;
            }
        }

        if (homeslice == 0) {
            return "";
        }
        if (homeslice == 31) {
            return string(temp);
        }
        homeslice += 1;

        assembly {
            mstore(temp, homeslice)
        }

        return string(temp);
    }

    function textProps(
        string memory id,
        string memory y,
        string memory class
    ) internal pure virtual returns (string memory) {
        return
            string.concat(
                svg.prop("id", id),
                svg.prop("class", class),
                svg.prop("x", "50%"),
                svg.prop("y", y),
                svg.prop("text-anchor", "middle")
            );
    }

    function _isUpdate(string memory text) internal pure returns (bool) {
        return abi.encodePacked(text).length > 0;
    }

    function setHeaderElement(RunningMarginal memory elem)
        public
        onlyURIManager
    {
        if (_isUpdate(elem.marginalY)) {
            headerElement.marginalY = elem.marginalY;
        }
        if (_isUpdate(elem.marginalClass)) {
            headerElement.marginalClass = elem.marginalClass;
        }
        if (_isUpdate(elem.marginalText)) {
            headerElement.marginalText = elem.marginalText;
        }
    }

    function setLogoElement(LogoElement memory elem) public onlyURIManager {
        if (_isUpdate(elem.dPath)) {
            logoElement.dPath = elem.dPath;
        }
        if (_isUpdate(elem.aPath)) {
            logoElement.aPath = elem.aPath;
        }
        if (_isUpdate(elem.oPath)) {
            logoElement.oPath = elem.oPath;
        }
        if (_isUpdate(elem.logoTransform)) {
            logoElement.logoTransform = elem.logoTransform;
        }
        if (_isUpdate(elem.logoTextY)) {
            logoElement.logoTextY = elem.logoTextY;
        }
        if (_isUpdate(elem.logoTextClass)) {
            logoElement.logoTextClass = elem.logoTextClass;
        }
        if (_isUpdate(elem.logoText)) {
            logoElement.logoText = elem.logoText;
        }
    }

    function setExtraLogoPaths(string[] memory _logoPaths)
        public
        onlyURIManager
    {
        extraLogoPaths = _logoPaths;
    }

    function setFundingElement(FundingElement memory elem)
        public
        onlyURIManager
    {
        if (_isUpdate(elem.fundAmountY)) {
            fundingElement.fundAmountY = elem.fundAmountY;
        }
        if (_isUpdate(elem.fundAmountClass)) {
            fundingElement.fundAmountClass = elem.fundAmountClass;
        }
        if (_isUpdate(elem.fundNameY)) {
            fundingElement.fundNameY = elem.fundNameY;
        }
        if (_isUpdate(elem.fundNameClass)) {
            fundingElement.fundNameClass = elem.fundNameClass;
        }
        if (_isUpdate(elem.fundName)) {
            fundingElement.fundName = elem.fundName;
        }
    }

    function setNoNominationElement(NoNomElement memory elem)
        public
        onlyURIManager
    {
        if (_isUpdate(elem.nomPendingY)) {
            noNomElement.nomPendingY = elem.nomPendingY;
        }
        if (_isUpdate(elem.nomPendingClass)) {
            noNomElement.nomPendingClass = elem.nomPendingClass;
        }
        if (_isUpdate(elem.nomPendingText)) {
            noNomElement.nomPendingText = elem.nomPendingText;
        }
        if (_isUpdate(elem.nomAskClass)) {
            noNomElement.nomAskClass = elem.nomAskClass;
        }
        if (_isUpdate(elem.nomAskY)) {
            noNomElement.nomAskY = elem.nomAskY;
        }
        if (_isUpdate(elem.nomAskY2)) {
            noNomElement.nomAskY2 = elem.nomAskY2;
        }
        if (_isUpdate(elem.nomAskPrefix)) {
            noNomElement.nomAskPrefix = elem.nomAskPrefix;
        }
        if (_isUpdate(elem.nomAskLinkText)) {
            noNomElement.nomAskLinkText = elem.nomAskLinkText;
        }
        if (_isUpdate(elem.nomAskSuffix)) {
            noNomElement.nomAskSuffix = elem.nomAskSuffix;
        }
        if (_isUpdate(elem.nomAskLine2)) {
            noNomElement.nomAskLine2 = elem.nomAskLine2;
        }
    }

    function setNominationCountElement(NomCountElement memory elem)
        public
        onlyURIManager
    {
        if (_isUpdate(elem.largeY)) {
            nomCountElement.largeY = elem.largeY;
        }
        if (_isUpdate(elem.largeClass)) {
            nomCountElement.largeClass = elem.largeClass;
        }
        if (_isUpdate(elem.smallY)) {
            nomCountElement.smallY = elem.smallY;
        }
        if (_isUpdate(elem.smallClass)) {
            nomCountElement.smallClass = elem.smallClass;
        }
        if (_isUpdate(elem.singleText)) {
            nomCountElement.singleText = elem.singleText;
        }
        if (_isUpdate(elem.pluralPrefix)) {
            nomCountElement.pluralPrefix = elem.pluralPrefix;
        }
        if (_isUpdate(elem.pluralSuffix)) {
            nomCountElement.pluralSuffix = elem.pluralSuffix;
        }
    }

    function setNominationNameElement(NomNameElement memory elem)
        public
        onlyURIManager
    {
        if (_isUpdate(elem.largeY)) {
            nomNameElement.largeY = elem.largeY;
        }
        if (_isUpdate(elem.largeClass)) {
            nomNameElement.largeClass = elem.largeClass;
        }
        if (_isUpdate(elem.smallY)) {
            nomNameElement.smallY = elem.smallY;
        }
        if (_isUpdate(elem.smallClass)) {
            nomNameElement.smallClass = elem.smallClass;
        }
        if (elem.maxLength > 0) {
            nomNameElement.maxLength = elem.maxLength;
        }
        if (elem.smallFontThresholdLength > 0) {
            nomNameElement.smallFontThresholdLength = elem
                .smallFontThresholdLength;
        }
    }

    function setFooterElement(RunningMarginal memory elem)
        public
        onlyURIManager
    {
        if (_isUpdate(elem.marginalY)) {
            footerElement.marginalY = elem.marginalY;
        }
        if (_isUpdate(elem.marginalClass)) {
            footerElement.marginalClass = elem.marginalClass;
        }
        if (_isUpdate(elem.marginalText)) {
            footerElement.marginalText = elem.marginalText;
        }
    }

    function _initDefaults() internal virtual {}
}

// File: PerformingArtsBuilder.sol

/**
 * @title Performing Arts DAO Dynamic Content Contract
 */
contract PerformingArtsBuilder is ReliefDAOBuilder {
    string gradientStart;
    string gradientStop;

    constructor(INominator _tokens, IReliefDaoOracle _oracle)
        ReliefDAOBuilder(_tokens, _oracle)
    {}

    function setGradient(
        string memory _gradientStart,
        string memory _gradientStop
    ) public onlyURIManager {
        gradientStart = _gradientStart;
        gradientStop = _gradientStop;
    }

    function buildDefs() internal view override returns (string memory) {
        return
            string.concat(
                super.buildDefs(),
                svg.linearGradient(
                    "gr1",
                    svg.prop("gradientUnits", "objectBoundingBox"),
                    string.concat(
                        svg.gradientStop(0, gradientStart, ""),
                        svg.gradientStop(100, gradientStop, "")
                    )
                )
            );
    }

    function _initDefaults() internal override {
        regularURL = "https://performingartsdao.com/";
        nominationURL = "https://performingartsdao.com/nominate";

        gradientStart = "#c90014";
        gradientStop = "#db8f13";

        logoElement
            .dPath = "M57.721,31.792c0,4.605-.768,8.834-2.302,12.685-1.535,3.852-3.692,7.168-6.473,9.948-2.78,2.78-6.125,4.938-10.035,6.473-3.91,1.535-8.254,2.302-13.032,2.302H1.942V.384H25.878c4.779,0,9.123,.775,13.032,2.324,3.91,1.55,7.255,3.707,10.035,6.473,2.78,2.766,4.937,6.075,6.473,9.926,1.535,3.852,2.302,8.08,2.302,12.685Zm-11.99,0c0-3.446-.456-6.538-1.368-9.275-.912-2.737-2.23-5.053-3.953-6.951-1.723-1.896-3.809-3.352-6.256-4.366-2.448-1.013-5.206-1.52-8.275-1.52H13.671V53.903h12.207c3.069,0,5.828-.506,8.275-1.52,2.447-1.013,4.532-2.469,6.256-4.366,1.723-1.896,3.041-4.214,3.953-6.951,.912-2.737,1.368-5.828,1.368-9.275Z";
        logoElement
            .aPath = "M118.178,63.2h-9.036c-1.014,0-1.84-.253-2.476-.76-.637-.506-1.115-1.136-1.434-1.89l-4.692-12.815h-26.021l-4.692,12.815c-.232,.666-.681,1.275-1.347,1.825-.666,.55-1.492,.825-2.476,.825h-9.123L81.6,.384h11.903l24.675,62.816Zm-20.635-23.719l-7.646-20.895c-.377-.926-.768-2.027-1.173-3.301-.406-1.274-.811-2.65-1.216-4.127-.377,1.477-.768,2.86-1.173,4.149-.406,1.289-.797,2.411-1.173,3.367l-7.602,20.808h19.983Z";
        logoElement
            .oPath = "M154.881,35.253c-1.173,1.393-3.022,2.176-5.004,2.947-1.982,.771-3.87,1.441-5.606,1.18-.068-.01-.119,.067-.079,.127,1.034,1.528,3.991,2.652,6.677,1.607s4.276-3.937,4.148-5.818c-.005-.073-.091-.097-.137-.043Z";
        logoElement.logoTransform = "translate(361 150) scale(2)";
        logoElement.logoTextY = "330";
        logoElement.logoTextClass = "logo";
        logoElement.logoText = "Performing Arts";

        extraLogoPaths.push(
            "M145.571,30.886c-.892-1.191-2.517-2.13-4.33-1.425-1.565,.609-2.264,2.45-2.233,3.975,.001,.067,.075,.105,.126,.068,.452-.328,2.066-1.476,2.995-1.811,1.024-.369,2.863-.607,3.387-.669,.062-.007,.094-.086,.055-.138Z"
        );
        extraLogoPaths.push(
            "M151.237,25.573c-1.815,.706-2.495,2.544-2.46,4.071,.001,.066,.071,.105,.123,.07,.484-.326,2.335-1.562,2.999-1.82,.664-.258,2.825-.583,3.392-.666,.061-.009,.09-.087,.052-.138-.893-1.193-2.538-2.126-4.106-1.517Z"
        );
        extraLogoPaths.push(
            "M146.956,.002C129.463,.002,115.281,14.183,115.281,31.677s14.181,31.675,31.675,31.675,31.675-14.181,31.675-31.675S164.449,.002,146.956,.002Zm13.053,34.33c-.404,3.455-4.303,10.358-7.424,11.548s-10.34-1.47-12.768-3.845c-2.907-2.843-5.476-14.715-5.939-16.953-.04-.192,.098-.365,.282-.367,7.358-.08,13.88-2.569,19.565-7.466,.141-.122,.347-.085,.433,.086,1.007,2.005,6.335,12.853,5.851,16.996Z"
        );

        fundingElement.fundAmountY = "540";
        fundingElement.fundAmountClass = "amt";
        fundingElement.fundNameY = "610";
        fundingElement.fundNameClass = "norm";
        fundingElement.fundName = "Total Amount Raised";

        noNomElement.nomPendingY = "827";
        noNomElement.nomPendingClass = "norm";
        noNomElement.nomPendingText = "Nomination pending review";
        noNomElement.nomAskY = "790";
        noNomElement.nomAskY2 = "864";
        noNomElement.nomAskClass = "norm";
        noNomElement.nomAskPrefix = "Go to ";
        noNomElement.nomAskLinkText = "https://performingartsdao.com/nominate";
        noNomElement.nomAskSuffix = "";
        noNomElement.nomAskLine2 = "to nominate an organization";

        nomCountElement.largeY = "790";
        nomCountElement.largeClass = "norm";
        nomCountElement.smallY = "790";
        nomCountElement.smallClass = "nm-s";
        nomCountElement.singleText = "1 nomination for";
        nomCountElement.pluralPrefix = "";
        nomCountElement.pluralSuffix = " nominations for";

        nomNameElement.largeY = "864";
        nomNameElement.largeClass = "norm";
        nomNameElement.smallY = "864";
        nomNameElement.smallClass = "nm-s";
        nomNameElement.maxLength = 36;
        nomNameElement.smallFontThresholdLength = 0xFF;
    }
}