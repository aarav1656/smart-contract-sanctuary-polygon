/**
 *Submitted for verification at polygonscan.com on 2023-01-19
*/

// Sources flattened with hardhat v2.12.2 https://hardhat.org

// File contracts/interfaces/external/IPriceSourceAll.sol

pragma solidity 0.8.11;
interface IPriceSource {
    function latestRoundData() external view returns (uint256);
    function latestAnswer() external view returns (uint256);
    function decimals() external view returns (uint8);
}


// File @openzeppelin/contracts/utils/math/[email protected]

// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}


// File @openzeppelin/contracts/utils/[email protected]

// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
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


// File @openzeppelin/contracts/token/ERC721/[email protected]

// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

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
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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


// File @openzeppelin/contracts/token/ERC721/[email protected]

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


// File @openzeppelin/contracts/token/ERC721/extensions/[email protected]

// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

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


// File @openzeppelin/contracts/utils/[email protected]

// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
        (bool success, bytes memory returndata) = target.delegatecall(data);
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


// File @openzeppelin/contracts/token/ERC721/[email protected]

// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;







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
        address owner = _ownerOf(tokenId);
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
            "ERC721: approve caller is not token owner or approved for all"
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
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");

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
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");
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
     * @dev Returns the owner of the `tokenId`. Does NOT revert if token doesn't exist
     */
    function _ownerOf(uint256 tokenId) internal view virtual returns (address) {
        return _owners[tokenId];
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
        return _ownerOf(tokenId) != address(0);
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

        _beforeTokenTransfer(address(0), to, tokenId, 1);

        // Check that tokenId was not minted by `_beforeTokenTransfer` hook
        require(!_exists(tokenId), "ERC721: token already minted");

        unchecked {
            // Will not overflow unless all 2**256 token ids are minted to the same owner.
            // Given that tokens are minted one by one, it is impossible in practice that
            // this ever happens. Might change if we allow batch minting.
            // The ERC fails to describe this case.
            _balances[to] += 1;
        }

        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId, 1);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     * This is an internal function that does not check if the sender is authorized to operate on the token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId, 1);

        // Update ownership in case tokenId was transferred by `_beforeTokenTransfer` hook
        owner = ERC721.ownerOf(tokenId);

        // Clear approvals
        delete _tokenApprovals[tokenId];

        unchecked {
            // Cannot overflow, as that would require more tokens to be burned/transferred
            // out than the owner initially received through minting and transferring in.
            _balances[owner] -= 1;
        }
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId, 1);
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

        _beforeTokenTransfer(from, to, tokenId, 1);

        // Check that tokenId was not transferred by `_beforeTokenTransfer` hook
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");

        // Clear approvals from the previous owner
        delete _tokenApprovals[tokenId];

        unchecked {
            // `_balances[from]` cannot overflow for the same reason as described in `_burn`:
            // `from`'s balance is the number of token held, which is at least one before the current
            // transfer.
            // `_balances[to]` could overflow in the conditions described in `_mint`. That would require
            // all 2**256 token ids to be minted, which in practice is impossible.
            _balances[from] -= 1;
            _balances[to] += 1;
        }
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId, 1);
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
     * @dev Hook that is called before any token transfer. This includes minting and burning. If {ERC721Consecutive} is
     * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s tokens will be transferred to `to`.
     * - When `from` is zero, the tokens will be minted for `to`.
     * - When `to` is zero, ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     * - `batchSize` is non-zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256, /* firstTokenId */
        uint256 batchSize
    ) internal virtual {
        if (batchSize > 1) {
            if (from != address(0)) {
                _balances[from] -= batchSize;
            }
            if (to != address(0)) {
                _balances[to] += batchSize;
            }
        }
    }

    /**
     * @dev Hook that is called after any token transfer. This includes minting and burning. If {ERC721Consecutive} is
     * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s tokens were transferred to `to`.
     * - When `from` is zero, the tokens were minted for `to`.
     * - When `to` is zero, ``from``'s tokens were burned.
     * - `from` and `to` are never both zero.
     * - `batchSize` is non-zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual {}
}


// File @openzeppelin/contracts/token/ERC721/extensions/[email protected]

// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

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
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}


// File @openzeppelin/contracts/token/ERC721/extensions/[email protected]

// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;


/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev See {ERC721-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, firstTokenId, batchSize);

        if (batchSize > 1) {
            // Will only trigger during construction. Batch transferring (minting) is not available afterwards.
            revert("ERC721Enumerable: consecutive transfers not supported");
        }

        uint256 tokenId = firstTokenId;

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}


// File contracts/token/ERC721/MyVaultV5.sol

// contracts/MyVaultNFT.sol
pragma solidity 0.8.11;



contract VaultNFTv5 is ERC721, ERC721Enumerable {

    bool public custom;

    string internal baseURI;

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    constructor(string memory name, string memory symbol, string memory _baseURI)
        ERC721(name, symbol)
    {
        baseURI = _baseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        if(custom){
            return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, Strings.toString(tokenId))) : "";
        } else{
            return baseURI;
        }
    }
}


// File @openzeppelin/contracts/security/[email protected]

// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}


// File @openzeppelin/contracts/token/ERC20/[email protected]

// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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


// File @openzeppelin/contracts/token/ERC20/extensions/[email protected]

// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}


// File @openzeppelin/contracts/token/ERC20/utils/[email protected]

// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;



/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}


// File @openzeppelin/contracts/token/ERC20/extensions/[email protected]

// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}


// File @openzeppelin/contracts/token/ERC20/[email protected]

// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;



/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}


// File contracts/fixedInterestVaults/fixedVault.sol

pragma solidity 0.8.11;




contract fixedVault is ReentrancyGuard, VaultNFTv5 {
    using SafeERC20 for ERC20;

    /// @dev Constants used across the contract.
    uint256 constant TEN_THOUSAND = 10000;
    uint256 constant ONE_YEAR = 31556952;
    uint256 constant THOUSAND = 1000;

    IPriceSource public ethPriceSource;

    uint256 public _minimumCollateralPercentage;

    uint256 public vaultCount;
    
    uint256 public closingFee;
    uint256 public openingFee;

    uint256 public minDebt;
    uint256 public maxDebt;

    uint256 constant public tokenPeg = 1e8; // $1

    uint256 public iR;

    mapping(uint256 => uint256) public vaultCollateral;
    mapping(uint256 => uint256) public accumulatedVaultDebt;

    mapping(uint256 => uint256) public lastInterest;
    mapping(uint256 => uint256) public promoter;

    uint256 public adminFee; // 10% of the earned interest
    uint256 public refFee; // 90% of the earned interest

    uint256 public debtRatio;
    uint256 public gainRatio;

    ERC20 public collateral;
    ERC20 public mai;

    uint256 public decimalDifferenceRaisedToTen;

    uint256 public priceSourceDecimals;
    uint256 public totalBorrowed;

    mapping(address => uint256) public maticDebt;
    uint256 public maiDebt;

    address public stabilityPool;
    address public adm;
    address public ref;
    address public router;
    uint8 public version = 8;

    event CreateVault(uint256 vaultID, address creator);
    event DestroyVault(uint256 vaultID);
    event DepositCollateral(uint256 vaultID, uint256 amount);
    event WithdrawCollateral(uint256 vaultID, uint256 amount);
    event BorrowToken(uint256 vaultID, uint256 amount);
    event PayBackToken(uint256 vaultID, uint256 amount, uint256 closingFee);
    event LiquidateVault(
        uint256 vaultID,
        address owner,
        address buyer,
        uint256 debtRepaid,
        uint256 collateralLiquidated,
        uint256 closingFee
    );
    event BoughtRiskyDebtVault(uint256 riskyVault, uint256 newVault, address riskyVaultBuyer, uint256 amountPaidtoBuy);

    constructor(
        address ethPriceSourceAddress,
        uint256 minimumCollateralPercentage,
        string memory name,
        string memory symbol,
        address _mai,
        address _collateral,
        string memory baseURI
    ) VaultNFTv5(name, symbol, baseURI) {
        
        require(ethPriceSourceAddress != address(0));
        require(minimumCollateralPercentage != 0);

        closingFee = 50; // 0.5%
        openingFee = 0; // 0.0% 

        ethPriceSource = IPriceSource(ethPriceSourceAddress);
        stabilityPool = address(0);
        
        maxDebt = 500000 ether; //Keeping maxDebt at 500K * 10^(18)


        debtRatio = 2; // 1/2, pay back 50%
        gainRatio = 1100; // /10 so 1.1

        _minimumCollateralPercentage = minimumCollateralPercentage;

        collateral = ERC20(_collateral);
        mai = ERC20(_mai);
        priceSourceDecimals = 8;
        
        /*
            This works only for collaterals with decimals < 18
        */
        decimalDifferenceRaisedToTen =
            10**(mai.decimals() - collateral.decimals());
        
        adm = msg.sender;
        ref = msg.sender;
    }

    modifier onlyVaultOwner(uint256 vaultID) {
        require(_exists(vaultID), "Vault does not exist");
        require(ownerOf(vaultID) == msg.sender, "Vault is not owned by you");
        _;
    }

    modifier onlyRouter() {
        require(
            router == address(0) || msg.sender == router,
            "must use router"
        );
        _;
    }

    modifier vaultExists(uint256 vaultID) {
        require(_exists(vaultID), "Vault does not exist");
        _;
    }

    modifier frontExists(uint256 vaultID) {
        require(_exists(vaultID), "front end vault does not exist");
        require(promoter[vaultID] <= TEN_THOUSAND && promoter[vaultID] > 0, "Front end not added");
        _;
    }

    /// @notice Return the current debt available to borrow.
    /// @dev checks the outstanding balance of the borrowable asset within the contract.
    /// @return available balance of borrowable asset.
    function getDebtCeiling() public view returns (uint256) {
        return mai.balanceOf(address(this));
    }

    /// @param vaultID is the token id of the vault being checked.
    /// @notice Returns true if a vault exists
    /// @dev the erc721 spec allows users to burn/destroy their nft
    /// @return boolean if the vault exists
    function exists(uint256 vaultID) external view returns (bool) {
        return _exists(vaultID);
    }

    /// @notice Returns the total value locked in the vault, based on the oracle price.
    /// @return uint256 total value locked in vault
    function getTotalValueLocked() external view returns (uint256) {
        return ( getEthPriceSource() * decimalDifferenceRaisedToTen * collateral.balanceOf(address(this)) ) ; //extra 1e8, to get fraction in ui
                // 1e8 * 1eDelta 
    }

    /// @notice Return the fee charged when repaying a vault.
    /// @return uint256 is the fee charged to a vault when repaying.
    function getClosingFee() external view returns (uint256) {
        return closingFee;
    }

    /// @notice Return the peg maintained by the vault.
    /// @return uint256 is the value with 8 decimals used to calculate borrowable debt.
    function getTokenPriceSource() public view returns (uint256) {
        return tokenPeg;
    }

    /// @notice Return the collateral value
    /// @return uint256 is the value retrieved from the oracle used
    /// to calculate the available borrowable amounts.
    function getEthPriceSource() public view returns (uint256) {
        return ethPriceSource.latestAnswer();
    }

    /// @param vaultID is the token id of the vault being checked.
    /// @notice Returns the debt owned by the vault and the interest accrued over time.
    /// @return uint256 fee earned in the time between updates
    /// @return uint256 debt owed by the vault for further calculation.
    function _vaultDebtAndFee(uint256 vaultID)
        internal
        view
        returns (uint256, uint256)
    {
        uint256 currentTime = block.timestamp;
        uint256 debt = accumulatedVaultDebt[vaultID];
        uint256 fee = 0;
        if (lastInterest[vaultID] != 0 && iR > 0) {
            uint256 timeDelta = currentTime - lastInterest[vaultID];

            uint256 feeAccrued = (((iR * debt) * timeDelta) / ONE_YEAR) / TEN_THOUSAND;
            fee = feeAccrued;
            debt = feeAccrued + debt;
        }
        return (fee, debt);
    }

    /// @param vaultID is the token id of the vault being checked.
    /// @notice Returns the debt owned by the vault without tracking the interest
    /// @return uint256 debt owed by the vault for further calculation.
    function vaultDebt(uint256 vaultID) public view returns (uint256) {
        (, uint256 debt) = _vaultDebtAndFee(vaultID);
        return debt;
    }

    /// @param vaultID is the token id of the vault being checked.
    /// @notice Adds the interest charged to the vault over the previous time called.
    /// @return uint256 latest vault debt
    function updateVaultDebt(uint256 vaultID) public returns (uint256) {
        (uint256 fee, uint256 debt) = _vaultDebtAndFee(vaultID);

        maiDebt = maiDebt + fee;

        totalBorrowed = totalBorrowed + fee;

        if(iR > 0) {
            lastInterest[vaultID] = block.timestamp;
        }

        // we can just update the current vault debt here instead
        accumulatedVaultDebt[vaultID] = debt;

        return debt;
    }

    /// @param _collateral is the amount of collateral tokens to be valued.
    /// @param _debt is the debt owed by the vault.
    /// @notice Returns collateral value and debt based on the oracle prices
    /// @return uint256 coolateral value * 100. used to calculate the CDR
    /// @return uint256 debt value. Uses token price source to derive.
    function calculateCollateralProperties(uint256 _collateral, uint256 _debt)
        private
        view
        returns (uint256, uint256)
    {
        require(getEthPriceSource() != 0);
        require(getTokenPriceSource() != 0);

        uint256 collateralValue = _collateral *
            getEthPriceSource() *
            decimalDifferenceRaisedToTen;

        require(collateralValue >= _collateral);

        uint256 debtValue = _debt * getTokenPriceSource();

        require(debtValue >= _debt);

        uint256 collateralValueTimes100 = collateralValue * 100;
        require(collateralValueTimes100 > collateralValue);

        return (collateralValueTimes100, debtValue);
    }

    
    /// @param _collateral is the amount of collateral tokens held by vault.
    /// @param debt is the debt owed by the vault.
    /// @notice Calculates if the CDR is valid before taking a further action with a user
    /// @return boolean describing if the new CDR is valid.
    function isValidCollateral(uint256 _collateral, uint256 debt)
        public
        view
        returns (bool)
    {
        (
            uint256 collateralValueTimes100,
            uint256 debtValue
        ) = calculateCollateralProperties(_collateral, debt);

        uint256 collateralPercentage = collateralValueTimes100 / debtValue;
        return collateralPercentage >= _minimumCollateralPercentage;
    }

    

    /// @param fee is the amount of basis points (BP) to charge
    /// @param amount is the total value to calculate the BPs from
    /// @param promoFee is the fee charged by the front end
    /// @notice Returns fee to charge based on the collateral amount
    /// @return uint256 fee to charge the collateral.
    /// @dev fee can be called on web app to compare charges.
    function calculateFee(
        uint256 fee,
        uint256 amount,
        uint256 promoFee
    ) public view returns (uint256) {
        uint256 _fee;
        if (promoFee>0) {
            _fee = ((amount * fee * getTokenPriceSource() * promoFee) /
                (getEthPriceSource() * TEN_THOUSAND * TEN_THOUSAND));
        } else {
            _fee = (amount * fee * getTokenPriceSource()) /
                (getEthPriceSource() * TEN_THOUSAND);
        }
        return _fee / decimalDifferenceRaisedToTen;
    }

    /// @notice Creates a new ERC721 Vault NFT
    /// @return uint256 the token id of the vault created.
    function createVault() public returns (uint256) {
        uint256 id = vaultCount;
        vaultCount = vaultCount + 1;
        require(vaultCount >= id);
        _mint(msg.sender, id);
        emit CreateVault(id, msg.sender);
        return id;
    }

    /// @notice Destroys an ERC721 Vault NFT
    /// @param vaultID the vault ID to destroy
    /// @dev vault must not have any debt owed to be able to be destroyed.
    function destroyVault(uint256 vaultID)
        external
        onlyVaultOwner(vaultID)
        nonReentrant
    {
        require(vaultDebt(vaultID) == 0, "Vault has outstanding debt");

        if (vaultCollateral[vaultID] != 0) {
            // withdraw leftover collateral
            collateral.safeTransfer(ownerOf(vaultID), vaultCollateral[vaultID]);
        }

        _burn(vaultID);

        delete vaultCollateral[vaultID];
        delete accumulatedVaultDebt[vaultID];
        delete lastInterest[vaultID];
        emit DestroyVault(vaultID);
    }

    /// @param vaultID is the token id of the vault being interacted with.
    /// @param amount is the amount of collateral to deposit from msg.sender
    /// @notice Adds collateral to a specific vault by token id
    /// @dev Any address can deposit into a vault
    function depositCollateral(uint256 vaultID, uint256 amount)
        external
        vaultExists(vaultID)
        onlyRouter
    {
        uint256 newCollateral = vaultCollateral[vaultID] + (amount);

        require(newCollateral >= vaultCollateral[vaultID]);

        vaultCollateral[vaultID] = newCollateral;

        collateral.safeTransferFrom(msg.sender, address(this), amount);

        emit DepositCollateral(vaultID, amount);
    }

    /// @param vaultID is the token id of the vault being interacted with.
    /// @param amount is the amount of collateral to withdraw
    /// @notice withdraws collateral to a specific vault by token id
    /// @dev If there is debt, then it can only withdraw up to the min CDR.
    function withdrawCollateral(uint256 vaultID, uint256 amount)
        external
        onlyVaultOwner(vaultID)
        nonReentrant
    {
        require(
            vaultCollateral[vaultID] >= amount,
            "Vault does not have enough collateral"
        );

        uint256 newCollateral = vaultCollateral[vaultID] - amount;
        uint256 debt = updateVaultDebt(vaultID);

        if (debt != 0) {
            require(
                isValidCollateral(newCollateral, debt),
                "Withdrawal would put vault below minimum collateral percentage"
            );
        }

        vaultCollateral[vaultID] = newCollateral;
        collateral.safeTransfer(msg.sender, amount);

        emit WithdrawCollateral(vaultID, amount);
    }

    /// @param vaultID is the token id of the vault being interacted with.
    /// @param amount is the amount of borrowable asset to borrow
    /// @notice borrows asset based on the collateral held and the price of the collateral.
    /// @dev Borrowing is limited by the CDR of the vault
    /// If there's opening fee, it will be charged here.
    function borrowToken(
        uint256 vaultID,
        uint256 amount,
        uint256 _front
    ) external 
    frontExists(_front) 
    onlyVaultOwner(vaultID) 
    nonReentrant
    {

        require(amount > 0, "Must borrow non-zero amount");
        require(
            amount <= getDebtCeiling(),
            "borrowToken: Cannot mint over available supply."
        );

        uint256 newDebt = updateVaultDebt(vaultID) + amount;

        require(newDebt<=maxDebt, "borrowToken: max loan cap reached.");

        require(newDebt > vaultDebt(vaultID));


        require(
            isValidCollateral(vaultCollateral[vaultID], newDebt),
            "Borrow would put vault below minimum collateral percentage"
        );

        require(
            ((vaultDebt(vaultID)) + amount) >= minDebt,
            "Vault debt can't be under minDebt"
        );

        accumulatedVaultDebt[vaultID] = newDebt;

        uint256 _openingFee = calculateFee(openingFee, newDebt, promoter[_front]);

        vaultCollateral[vaultID] = vaultCollateral[vaultID] - (_openingFee);
        vaultCollateral[_front] = vaultCollateral[_front] + (_openingFee);
        
        // mai
        mai.safeTransfer(msg.sender, amount);
        totalBorrowed = totalBorrowed + (amount);

        emit BorrowToken(vaultID, amount);
    }

    function paybackTokenAll(
        uint256 vaultID,
        uint256 deadline,
        uint256 _front
    ) external frontExists(_front) vaultExists(vaultID) onlyRouter {
        require(
            deadline >= block.timestamp,
            "paybackTokenAll: deadline expired."
        );

        uint256 _amount = updateVaultDebt(vaultID);
        payBackToken(vaultID, _amount, _front);
    }

    /// @param vaultID is the token id of the vault being interacted with.
    /// @param amount is the amount of borrowable asset to repay
    /// @param _front is the front end that will get the opening
    /// @notice payback asset to close loan.
    /// @dev If there is debt, then it can only withdraw up to the min CDR.
    function payBackToken(
        uint256 vaultID,
        uint256 amount,
        uint256 _front
    ) public frontExists(_front) vaultExists(vaultID) onlyRouter {
        require(mai.balanceOf(msg.sender) >= amount, "Token balance too low");

        uint256 vaultDebtNow = updateVaultDebt(vaultID);

        require(
            vaultDebtNow >= amount,
            "Vault debt less than amount to pay back"
        );

        require(
            ((vaultDebtNow) - amount) >= minDebt || amount == (vaultDebtNow),
            "Vault debt can't be under minDebt"
        );

        uint256 _closingFee = calculateFee(
            closingFee,
            amount,
            promoter[_front]
        );

        accumulatedVaultDebt[vaultID] = vaultDebtNow - amount;

        vaultCollateral[vaultID] = vaultCollateral[vaultID] - _closingFee;
        vaultCollateral[_front] = vaultCollateral[_front] + _closingFee;

        totalBorrowed = totalBorrowed - amount;

        //mai
        mai.safeTransferFrom(msg.sender, address(this), amount);
        
        emit PayBackToken(vaultID, amount, _closingFee);
    }

    /// @notice withdraws liquidator earnings.
    /// @dev reverts if there's no collateral to withdraw.
    function getPaid() external nonReentrant {
        require(maticDebt[msg.sender] != 0, "Don't have anything for you.");
        uint256 amount = maticDebt[msg.sender];
        maticDebt[msg.sender] = 0;
        collateral.safeTransfer(msg.sender, amount);
    }

    /// @param pay is address of the person to getPaid
    /// @notice withdraws liquidator earnings.
    /// @dev reverts if there's no collateral to withdraw.
    function getPaid(address pay) external nonReentrant {
        require(maticDebt[pay] != 0, "Don't have anything for you.");
        uint256 amount = maticDebt[pay];
        maticDebt[pay] = 0;
        collateral.safeTransfer(pay, amount);
    }

    /// @param vaultID is the token id of the vault being interacted with.
    /// @notice Calculates cost to liquidate a vault
    /// @dev Can be used to calculate balance required to liquidate a vault. 
    function checkCost(uint256 vaultID) public view returns (uint256) {
        uint256 vaultDebtNow = vaultDebt(vaultID);

        if (
            vaultCollateral[vaultID] == 0 ||
            vaultDebtNow == 0 ||
            !checkLiquidation(vaultID)
        ) {
            return 0;
        }

        (,
            uint256 debtValue
        ) = calculateCollateralProperties(
                vaultCollateral[vaultID],
                vaultDebtNow
            );

        if (debtValue == 0) {
            return 0;
        }

        debtValue = debtValue / (10**priceSourceDecimals);

        uint256 halfDebt = debtValue / debtRatio; //debtRatio (2)

        if (halfDebt <= minDebt) {
            halfDebt = debtValue;
        }

        return (halfDebt);
    }

    /// @param vaultID is the token id of the vault being interacted with.
    /// @notice Calculates collateral to extract when liquidating a vault
    /// @dev Can be used to calculate earnings from liquidating a vault. 
    function checkExtract(uint256 vaultID) public view returns (uint256) {
        if (vaultCollateral[vaultID] == 0 || !checkLiquidation(vaultID)) {
            return 0;
        }
        uint256 vaultDebtNow = vaultDebt(vaultID);

        (, uint256 debtValue) = calculateCollateralProperties(
            vaultCollateral[vaultID],
            vaultDebtNow
        );

        uint256 halfDebt = debtValue / debtRatio; //debtRatio (2)

        if (halfDebt == 0) {
            return 0;
        }
        if ((halfDebt) / (10**priceSourceDecimals) <= minDebt) {
            // full liquidation if under the min debt.
            return (debtValue * ( gainRatio)) / (THOUSAND) / (getEthPriceSource()) / decimalDifferenceRaisedToTen;
        } else {
            return (halfDebt * (gainRatio)) / THOUSAND / (getEthPriceSource()) / decimalDifferenceRaisedToTen;
        }
    }

    /// @param vaultID is the token id of the vault being interacted with.
    /// @notice Calculates the collateral percentage of a vault.
    function checkCollateralPercentage(uint256 vaultID)
        public
        view
        vaultExists(vaultID)
        returns (uint256)
    {
        uint256 vaultDebtNow = vaultDebt(vaultID);

        if (vaultCollateral[vaultID] == 0 || vaultDebtNow == 0) {
            return 0;
        }
        (
            uint256 collateralValueTimes100,
            uint256 debtValue
        ) = calculateCollateralProperties(
                vaultCollateral[vaultID],
                vaultDebtNow
            );

        return collateralValueTimes100 / (debtValue);
    }

    /// @param vaultID is the token id of the vault being interacted with.
    /// @notice Calculates if a vault is liquidatable.
    /// @return bool if vault is liquidatable or not.
    function checkLiquidation(uint256 vaultID)
        public
        view
        vaultExists(vaultID)
        returns (bool)
    {
        uint256 vaultDebtNow = vaultDebt(vaultID);

        if (vaultCollateral[vaultID] == 0 || vaultDebtNow == 0) {
            return false;
        }

        (
            uint256 collateralValueTimes100,
            uint256 debtValue
        ) = calculateCollateralProperties(
                vaultCollateral[vaultID],
                vaultDebtNow
            );

        uint256 collateralPercentage = collateralValueTimes100 / (debtValue);
        if (collateralPercentage < _minimumCollateralPercentage) {
            return true;
        } else {
            return false;
        }
    }

    /// @param vaultID is the token id of the vault being interacted with.
    /// @notice Calculates if a vault is risky and can be bought.
    /// @return bool if vault is risky or not.
    function checkRiskyVault(uint256 vaultID) public view vaultExists(vaultID) returns (bool) {

        uint256 vaultDebtNow = vaultDebt(vaultID);

        if (vaultCollateral[vaultID] == 0 || vaultDebtNow == 0) {
            return false;
        }

        (
            uint256 collateralValueTimes100,
            uint256 debtValue
        ) = calculateCollateralProperties(
                vaultCollateral[vaultID],
                vaultDebtNow
            );

        uint256 collateralPercentage = collateralValueTimes100 / (debtValue);

        if ((collateralPercentage*10) <= gainRatio) {
            return true;
        } else {
            return false;
        }
    }


    /// @param vaultID is the token id of the vault being interacted with.
    /// @notice Pays back the part of the debt owed by the vault and removes a 
    /// comparable amount of collateral plus bonus
    /// @dev if vault CDR is under the bonus ratio,
    /// then it will only be able to be bought through buy risky.
    /// Amount to pay back is based on debtRatio variable.
    function liquidateVault(uint256 vaultID, uint256 _front)
        external
        frontExists(_front)
        vaultExists(vaultID)
    {
        require(
            stabilityPool == address(0) || msg.sender == stabilityPool,
            "liquidation is disabled for public"
        );

        uint256 vaultDebtNow = updateVaultDebt(vaultID);
        (
            uint256 collateralValueTimes100,
            uint256 debtValue
        ) = calculateCollateralProperties(
                vaultCollateral[vaultID],
                vaultDebtNow
            );
        require(vaultDebtNow != 0, "Vault debt is 0");

        uint256 collateralPercentage = collateralValueTimes100 / (debtValue);

        require(
            collateralPercentage < _minimumCollateralPercentage,
            "Vault is not below minimum collateral percentage"
        );

        require(collateralPercentage * 10 > gainRatio , "Vault is not above gain ratio");

        debtValue = debtValue / (10**priceSourceDecimals);

        uint256 halfDebt = debtValue / (debtRatio); //debtRatio (2)

        if (halfDebt <= minDebt) {
            halfDebt = debtValue;
        }

        require(
            mai.balanceOf(msg.sender) >= halfDebt,
            "Token balance too low to pay off outstanding debt"
        );

        totalBorrowed = totalBorrowed - (halfDebt);

        uint256 maticExtract = checkExtract(vaultID);

        accumulatedVaultDebt[vaultID] = vaultDebtNow - (halfDebt); // we paid back half of its debt.

        uint256 _closingFee = calculateFee(closingFee, halfDebt, promoter[_front]);
        vaultCollateral[vaultID] = vaultCollateral[vaultID] - (_closingFee);
        vaultCollateral[_front] = vaultCollateral[_front] + (_closingFee);

        
        // deduct the amount from the vault's collateral
        vaultCollateral[vaultID] = vaultCollateral[vaultID] - (maticExtract);

        // let liquidator take the collateral
        maticDebt[msg.sender] = maticDebt[msg.sender] + (maticExtract);

        //mai
        mai.safeTransferFrom(msg.sender, address(this), halfDebt);

        emit LiquidateVault(
            vaultID,
            ownerOf(vaultID),
            msg.sender,
            halfDebt,
            maticExtract,
            _closingFee
        );
    }

    /// @param vaultID is the token id of the vault being interacted with.
    /// @notice Pays back the debt owed to bring it back to min CDR. 
    /// And transfers ownership of it to the liquidator with a new vault
    /// @return uint256 new vault created with the debt and collateral.
    /// @dev this function can only be called if vault CDR is under the bonus ratio.
    /// address who calls it will now own the debt and the collateral.
    function buyRiskDebtVault(uint256 vaultID) external vaultExists(vaultID) returns(uint256) {
        require(
            stabilityPool == address(0) || msg.sender == stabilityPool,
            "buy risky is disabled for public"
        );        uint256 vaultDebtNow = updateVaultDebt(vaultID);

        require(vaultDebtNow != 0, "Vault debt is 0");

        (
            uint256 collateralValueTimes100,
            uint256 debtValue
        ) = calculateCollateralProperties(
                vaultCollateral[vaultID],
                vaultDebtNow
            );

        uint256 collateralPercentage = collateralValueTimes100 / (debtValue);
        require(
            (collateralPercentage*10) <= gainRatio,
            "Vault is not below risky collateral percentage" 
        );

        uint256 maiDebtTobePaid = (debtValue / (10**priceSourceDecimals)) - 
                                    (collateralValueTimes100 / 
                                    ( _minimumCollateralPercentage * (10**priceSourceDecimals)));

        //have enough MAI to bring vault to X CDR (presumably min)
        require(mai.balanceOf(msg.sender) >= maiDebtTobePaid, "Not enough mai to buy the risky vault");
        //mai
        mai.safeTransferFrom(msg.sender, address(this), maiDebtTobePaid);
        totalBorrowed = totalBorrowed - (maiDebtTobePaid);
        // newVault for msg.sender
        uint256 newVault = createVault();
        // updating vault collateral and debt details for the transfer of risky vault
        vaultCollateral[newVault] = vaultCollateral[vaultID];
        accumulatedVaultDebt[newVault] = vaultDebtNow - maiDebtTobePaid;
        lastInterest[newVault] = block.timestamp;
        // resetting the vaultID vault info
        delete vaultCollateral[vaultID];
        delete accumulatedVaultDebt[vaultID];
        // lastInterest of vaultID would be block.timestamp, not reseting its timestamp
        emit BoughtRiskyDebtVault(vaultID, newVault, msg.sender, maiDebtTobePaid);
        return newVault;

    }
}


// File @openzeppelin/contracts/access/[email protected]

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


// File contracts/fixedInterestVaults/fixedQiVault.sol

pragma solidity 0.8.11;


/// @title Fixed Interest Vault
/// @notice Single collateral lending manager with fixed rate interest.
contract stableQiVault is fixedVault, Ownable {

    /// @dev Used to restrain the fee. Can only be up to 5% of the amount.
    uint256 constant FEE_MAX = 500;
    
    string private oracleType;
    
    constructor(
        address ethPriceSourceAddress,
        uint256 minimumCollateralPercentage,
        string memory name,
        string memory symbol,
        address _mai,
        address _collateral,
        string memory baseURI
    )
        fixedVault(
            ethPriceSourceAddress,
            minimumCollateralPercentage,
            name,
            symbol,
            _mai,
            _collateral,
            baseURI
        )
    {
        createVault();
        addFrontEnd(0);
    }

    event UpdatedClosingFee(uint256 newFee);
    event UpdatedOpeningFee(uint256 newFee);
    event WithdrawInterest(uint256 earned);
    event UpdatedMinDebt(uint256 newMinDebt);
    event UpdatedMaxDebt(uint256 newMaxDebt);
    event UpdatedDebtRatio(uint256 _debtRatio);
    event UpdatedGainRatio(uint256 _gainRatio);
    event UpdatedEthPriceSource(address _ethPriceSourceAddress);
    
    event AddedFrontEnd(uint256 promoter);
    event RemovedFrontEnd(uint256 promoter);
    event UpdatedFrontEnd(uint256 promoter, uint256 newFee);

    event UpdatedFees(uint256 _adminFee, uint256 _refFee);

    event UpdatedMinCollateralRatio(uint256 newMinCollateralRatio);
    event UpdatedStabilityPool(address pool);
    event UpdatedInterestRate(uint256 interestRate);
    event BurnedToken(uint256 amount);
    event UpdatedTokenURI(string uri);

    event UpdatedAdmin(address newAdmin);
    event UpdatedRef(address newRef);
    event UpdatedOracleName(string oracle);

    event UpdatedRouter(address router);
    event UpdatedCustomURI(bool custom);

    modifier onlyOperators() {
        require(ref == msg.sender || adm == msg.sender || owner() == msg.sender, "Needs to be called by operators");
        _;
    }

    modifier onlyAdmin() {
        require(adm == msg.sender, "Needs to be called by admin");
        _;
    }

    /// @param _oracle name of the oracle used by the contract
    /// @notice sets the oracle name used by the contract. for visual purposes.
    function updateOracleName(string memory _oracle) external onlyOwner {
        oracleType = _oracle;
        emit UpdatedOracleName(_oracle);
    }

    /// @param _gainRatio sets the bonus earned from a liquidator
    /// @notice implements a setter for the bonus earned by a liquidator
    /// @dev fails if the bonus is less than 1
    function setGainRatio(uint256 _gainRatio) external onlyOwner {
        require(_gainRatio >= 1000, "gainRatio cannot be less than or equal to 1000");
        gainRatio = _gainRatio;
        emit UpdatedGainRatio(gainRatio);
    }

    /// @param _debtRatio sets the ratio of debt paid back by a liquidator
    /// @notice sets the ratio of the debt to be paid back
    /// @dev it divides the debt. 1/debtRatio.
    function setDebtRatio(uint256 _debtRatio) external onlyOwner {
        require(_debtRatio != 0, "Debt Ratio cannot be 0");
        debtRatio = _debtRatio;
        emit UpdatedDebtRatio(debtRatio);
    }

        /// @param ethPriceSourceAddress is the address that provides the price of the collateral
    /// @notice sets the address used as oracle
    /// @dev Oracle price feed is used in here. Interface's available in the at /interfaces/IPriceSourceAll.sol
    function changeEthPriceSource(address ethPriceSourceAddress)
        external
        onlyOwner
    {
        require(ethPriceSourceAddress != address(0), "Ethpricesource cannot be zero address" );
        ethPriceSource = IPriceSource(ethPriceSourceAddress);
        emit UpdatedEthPriceSource(ethPriceSourceAddress);
    }

    /// @param _pool is the address that can execute liquidations
    /// @notice sets the address used as stability pool for liquidations
    /// @dev if not set to address(0) then _pool is the only address able to liquidate
    function setStabilityPool(address _pool) external onlyOwner {
        require(_pool != address(0), "StabilityPool cannot be zero address" );
        stabilityPool = _pool;
        emit UpdatedStabilityPool(stabilityPool);
    }

    /// @param _admin is the ratio earned by the address that maintains the market
    /// @param _ref is the ratio earned by the address that provides the borrowable asset
    /// @notice sets the interest rate split between the admin and ref
    /// @dev if not set to address(0) then _pool is the only address able to liquidate
    function setFees(uint256 _admin, uint256 _ref) external onlyOwner {
        require((_admin+_ref)==TEN_THOUSAND, "setFees: must equal 10000.");
        adminFee=_admin;
        refFee=_ref;
        emit UpdatedFees(adminFee, refFee);
    }

    /// @param minimumCollateralPercentage is the CDR that limits the amount borrowed
    /// @notice sets the CDR
    /// @dev only callable by owner of the contract
    function setMinCollateralRatio(uint256 minimumCollateralPercentage)
        external
        onlyOwner
    {
        _minimumCollateralPercentage = minimumCollateralPercentage;
        emit UpdatedMinCollateralRatio(_minimumCollateralPercentage);
    }

    /// @param _minDebt is minimum debt able to be borrowed by a vault.
    /// @notice sets the minimum debt.
    /// @dev dust protection
    function setMinDebt(uint256 _minDebt)
        external
        onlyOwner
    {
        require(_minDebt >=0, "setMinDebt: must be over 0.");
        minDebt = _minDebt;
        emit UpdatedMinDebt(minDebt);
    }

    /// @param _maxDebt is maximum debt able to be borrowed by a vault.
    /// @notice sets the maximum debt.
    /// @dev whale and liquidity protection.
    function setMaxDebt(uint256 _maxDebt)
        external
        onlyOwner
    {
        require(_maxDebt >=0, "setMaxDebt: must be over 0.");
        maxDebt = _maxDebt;
        emit UpdatedMaxDebt(maxDebt);
    }

    /// @param _ref is the address that provides the borrowable asset
    /// @notice sets the address that earns interest for providing a borrowable asset
    /// @dev cannot be address(0)
    function setRef(address _ref) external onlyOwner {
        require(_ref != address(0), "Reference Address cannot be zero");
        ref = _ref;
        emit UpdatedRef(ref);
    }

    /// @param _adm is the ratio earned by the address that maintains the market
    /// @notice sets the address that earns interest for maintaining the market
    /// @dev cannot be address(0)
    function setAdmin(address _adm) external onlyOwner {
        require(_adm != address(0), "Admin Address cannot be zero");
        adm = _adm;
        emit UpdatedAdmin(adm);
    }

    /// @param _openingFee is the fee charged to a vault when borrowing.
    /// @notice sets opening fee.
    /// @dev can only be up to 5% (FEE_MAX) of the amount.
    function setOpeningFee(uint256 _openingFee) external onlyOwner {
        require(_openingFee >= 0 && _openingFee <= FEE_MAX, "setOpeningFee: cannot be more than 5%");
        openingFee = _openingFee;
        // emit event
        emit UpdatedOpeningFee(openingFee);
    }

    /// @param _closingFee is the fee charged to a vault when repaying.
    /// @notice sets closing fee.
    /// @dev can only be up to 5% (FEE_MAX) of the amount.
    function setClosingFee(uint256 _closingFee) external onlyOwner {
        require(_closingFee >= 0 && _closingFee <= FEE_MAX, "setClosingFee: cannot be more than 5%");
        closingFee = _closingFee;
        // emit event
        emit UpdatedClosingFee(closingFee);
    }

    /// @param _promoter is a front end for the contract
    /// @notice adds a front end to earn opening/closing fees from borrowing/repaying.
    /// @dev can only be up to 5% (FEE_MAX) of the amount.
    function addFrontEnd(uint256 _promoter) public onlyOwner {
        require(_exists(_promoter), "addFrontEnd: Vault does not exist");    
        require(promoter[_promoter] == 0, "addFrontEnd: already added");
        promoter[_promoter] = TEN_THOUSAND;
        emit AddedFrontEnd(_promoter);
    }

    /// @param _promoter is a front end for the contract
    /// @param cashback is the amount of fee not taken from a user.
    /// @notice updates the cashback variable for a given front end
    /// @dev can only be updated by the front end vault's owner
    function updateFrontEnd(uint256 _promoter, uint256 cashback) external frontExists(_promoter) onlyVaultOwner(_promoter) {
        require(cashback > 0 && cashback <= TEN_THOUSAND, "updateFrontEnd: cannot be 0");
        promoter[_promoter] = cashback;
        emit UpdatedFrontEnd(_promoter, cashback);
    }

    /// @param _promoter is a front end for the contract
    /// @notice removes the ability for a front end to earn fees
    function removeFrontEnd(uint256 _promoter) external frontExists(_promoter) onlyOwner {
        require(_exists(_promoter), "removeFrontEnd: Vault does not exist");
        require(promoter[_promoter] > 0, "removeFrontEnd: not a front end");
        promoter[_promoter] = 0;
        emit RemovedFrontEnd(_promoter);
    }

    /// @notice withdraws earned interest by vault.
    function withdrawInterest() external onlyOperators nonReentrant {

        uint256 adm_fee = maiDebt*adminFee / TEN_THOUSAND;

        // Transfer
        mai.transfer(ref, (maiDebt-adm_fee) ); // cheaper and equivalent.
        mai.transfer(adm, adm_fee);
        emit WithdrawInterest(maiDebt);
        maiDebt = 0;
    }

    /// @param _iR is the fixed interest charged by a vault
    /// @notice sets the interest charged by a vault.
    function setInterestRate(uint256 _iR) external onlyOwner {
        iR = _iR;
        emit UpdatedInterestRate(iR);
    }

    /// @param amountToken is the amount of borrowable asset that is removed from the debt ceiling.
    /// @notice removes debt ceiling from the vault.
    /// @dev returns the asset to the owner so it can be redeployed at a later time.
    function burn(uint256 amountToken) external onlyAdmin {
        // Burn
        require(amountToken <= mai.balanceOf(address(this)), "burn: Balance not enough");
        mai.transfer(ref, amountToken);
        emit BurnedToken(amountToken);
    }

    /// @param _baseURI is the url for the nft metadata
    /// @notice updates the metadata
    /// @dev it currently uses an ipfs json
    function setTokenURI(string calldata _baseURI) external onlyOwner {
        baseURI = _baseURI;
        emit UpdatedTokenURI(baseURI);
    }

    function setRouter(address _router) external onlyOwner {
        router=_router;
        emit UpdatedRouter(router);
    }

    function setCustomURI(bool _custom) external onlyOwner {
        custom=_custom;
        emit UpdatedCustomURI(custom);
    }
}