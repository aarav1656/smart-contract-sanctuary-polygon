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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV // Deprecated in v4.8
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

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

pragma solidity 0.8.13;

interface IBridge {
    function send(address _receiver, address _token, uint256 _amount, uint64 _dstChainId, uint64 _nonce, uint32 _maxSilippage) external;
    function sendNative(address _receiver, uint256 _amount, uint64 _dstChainId, uint64 _nonce, uint32 _maxSlippage) external payable ;
    function withdraw(bytes calldata _wdmsg, bytes[] memory _sigs, address[] memory _signers, uint256[] memory _powers) external;
    function transfers(bytes32 transferId) external view returns(bool);
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.13;

interface ISigsVerifier {
    /**
     * @notice Verifies that a message is signed by a quorum among the signers.
     * @param _msg signed message
     * @param _sigs list of signatures sorted by signer addresses
     * @param _signers sorted list of current signers
     * @param _powers powers of current signers
     */
    function verifySigs(
        bytes memory _msg,
        bytes[] calldata _sigs,
        address[] calldata _signers,
        uint256[] calldata _powers
    ) external view;
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.13;

// runtime proto sol library
library Pb {
    enum WireType {
        Varint,
        Fixed64,
        LengthDelim,
        StartGroup,
        EndGroup,
        Fixed32
    }

    struct Buffer {
        uint256 idx; // the start index of next read. when idx=b.length, we're done
        bytes b; // hold serialized proto msg, readonly
    }

    // create a new in-memory Buffer object from raw msg bytes
    function fromBytes(bytes memory raw) internal pure returns (Buffer memory buf) {
        buf.b = raw;
        buf.idx = 0;
    }

    // whether there are unread bytes
    function hasMore(Buffer memory buf) internal pure returns (bool) {
        return buf.idx < buf.b.length;
    }

    // decode current field number and wiretype
    function decKey(Buffer memory buf) internal pure returns (uint256 tag, WireType wiretype) {
        uint256 v = decVarint(buf);
        tag = v / 8;
        wiretype = WireType(v & 7);
    }

    // count tag occurrences, return an array due to no memory map support
    // have to create array for (maxtag+1) size. cnts[tag] = occurrences
    // should keep buf.idx unchanged because this is only a count function
    function cntTags(Buffer memory buf, uint256 maxtag) internal pure returns (uint256[] memory cnts) {
        uint256 originalIdx = buf.idx;
        cnts = new uint256[](maxtag + 1); // protobuf's tags are from 1 rather than 0
        uint256 tag;
        WireType wire;
        while (hasMore(buf)) {
            (tag, wire) = decKey(buf);
            cnts[tag] += 1;
            skipValue(buf, wire);
        }
        buf.idx = originalIdx;
    }

    // read varint from current buf idx, move buf.idx to next read, return the int value
    function decVarint(Buffer memory buf) internal pure returns (uint256 v) {
        bytes10 tmp; // proto int is at most 10 bytes (7 bits can be used per byte)
        bytes memory bb = buf.b; // get buf.b mem addr to use in assembly
        v = buf.idx; // use v to save one additional uint variable
        assembly {
            tmp := mload(add(add(bb, 32), v)) // load 10 bytes from buf.b[buf.idx] to tmp
        }
        uint256 b; // store current byte content
        v = 0; // reset to 0 for return value
        for (uint256 i = 0; i < 10; i++) {
            assembly {
                b := byte(i, tmp) // don't use tmp[i] because it does bound check and costs extra
            }
            v |= (b & 0x7F) << (i * 7);
            if (b & 0x80 == 0) {
                buf.idx += i + 1;
                return v;
            }
        }
        revert(); // i=10, invalid varint stream
    }

    // read length delimited field and return bytes
    function decBytes(Buffer memory buf) internal pure returns (bytes memory b) {
        uint256 len = decVarint(buf);
        uint256 end = buf.idx + len;
        require(end <= buf.b.length); // avoid overflow
        b = new bytes(len);
        bytes memory bufB = buf.b; // get buf.b mem addr to use in assembly
        uint256 bStart;
        uint256 bufBStart = buf.idx;
        assembly {
            bStart := add(b, 32)
            bufBStart := add(add(bufB, 32), bufBStart)
        }
        for (uint256 i = 0; i < len; i += 32) {
            assembly {
                mstore(add(bStart, i), mload(add(bufBStart, i)))
            }
        }
        buf.idx = end;
    }

    // return packed ints
    function decPacked(Buffer memory buf) internal pure returns (uint256[] memory t) {
        uint256 len = decVarint(buf);
        uint256 end = buf.idx + len;
        require(end <= buf.b.length); // avoid overflow
        // array in memory must be init w/ known length
        // so we have to create a tmp array w/ max possible len first
        uint256[] memory tmp = new uint256[](len);
        uint256 i = 0; // count how many ints are there
        while (buf.idx < end) {
            tmp[i] = decVarint(buf);
            i++;
        }
        t = new uint256[](i); // init t with correct length
        for (uint256 j = 0; j < i; j++) {
            t[j] = tmp[j];
        }
        return t;
    }

    // move idx pass current value field, to beginning of next tag or msg end
    function skipValue(Buffer memory buf, WireType wire) internal pure {
        if (wire == WireType.Varint) {
            decVarint(buf);
        } else if (wire == WireType.LengthDelim) {
            uint256 len = decVarint(buf);
            buf.idx += len; // skip len bytes value data
            require(buf.idx <= buf.b.length); // avoid overflow
        } else {
            revert();
        } // unsupported wiretype
    }

    // type conversion help utils
    function _bool(uint256 x) internal pure returns (bool v) {
        return x != 0;
    }

    function _uint256(bytes memory b) internal pure returns (uint256 v) {
        require(b.length <= 32); // b's length must be smaller than or equal to 32
        assembly {
            v := mload(add(b, 32))
        } // load all 32bytes to v
        v = v >> (8 * (32 - b.length)); // only first b.length is valid
    }

    function _address(bytes memory b) internal pure returns (address v) {
        v = _addressPayable(b);
    }

    function _addressPayable(bytes memory b) internal pure returns (address payable v) {
        require(b.length == 20);
        //load 32bytes then shift right 12 bytes
        assembly {
            v := div(mload(add(b, 32)), 0x1000000000000000000000000)
        }
    }

    function _bytes32(bytes memory b) internal pure returns (bytes32 v) {
        require(b.length == 32);
        assembly {
            v := mload(add(b, 32))
        }
    }

    // uint[] to uint8[]
    function uint8s(uint256[] memory arr) internal pure returns (uint8[] memory t) {
        t = new uint8[](arr.length);
        for (uint256 i = 0; i < t.length; i++) {
            t[i] = uint8(arr[i]);
        }
    }

    function uint32s(uint256[] memory arr) internal pure returns (uint32[] memory t) {
        t = new uint32[](arr.length);
        for (uint256 i = 0; i < t.length; i++) {
            t[i] = uint32(arr[i]);
        }
    }

    function uint64s(uint256[] memory arr) internal pure returns (uint64[] memory t) {
        t = new uint64[](arr.length);
        for (uint256 i = 0; i < t.length; i++) {
            t[i] = uint64(arr[i]);
        }
    }

    function bools(uint256[] memory arr) internal pure returns (bool[] memory t) {
        t = new bool[](arr.length);
        for (uint256 i = 0; i < t.length; i++) {
            t[i] = arr[i] != 0;
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-only

// Code generated by protoc-gen-sol. DO NOT EDIT.
// source: contracts/libraries/proto/pool.proto
pragma solidity 0.8.13;
import "./Pb.sol";

library PbPool {
    using Pb for Pb.Buffer; // so we can call Pb funcs on Buffer obj

    struct WithdrawMsg {
        uint64 chainid; // tag: 1
        uint64 seqnum; // tag: 2
        address receiver; // tag: 3
        address token; // tag: 4
        uint256 amount; // tag: 5
        bytes32 refid; // tag: 6
    } // end struct WithdrawMsg

    function decWithdrawMsg(bytes memory raw) internal pure returns (WithdrawMsg memory m) {
        Pb.Buffer memory buf = Pb.fromBytes(raw);

        uint256 tag;
        Pb.WireType wire;
        while (buf.hasMore()) {
            (tag, wire) = buf.decKey();
            if (false) {}
            // solidity has no switch/case
            else if (tag == 1) {
                m.chainid = uint64(buf.decVarint());
            } else if (tag == 2) {
                m.seqnum = uint64(buf.decVarint());
            } else if (tag == 3) {
                m.receiver = Pb._address(buf.decBytes());
            } else if (tag == 4) {
                m.token = Pb._address(buf.decBytes());
            } else if (tag == 5) {
                m.amount = Pb._uint256(buf.decBytes());
            } else if (tag == 6) {
                m.refid = Pb._bytes32(buf.decBytes());
            } else {
                buf.skipValue(wire);
            } // skip value of unknown tag
        }
    } // end decoder WithdrawMsg
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.13;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/ISigsVerifier.sol";

contract Signers is Ownable, ISigsVerifier {
    using ECDSA for bytes32;

    bytes32 public ssHash;
    uint256 public triggerTime; // timestamp when last update was triggered
    // reset can be called by the owner address for emergency recovery
    uint256 public resetTime;
    uint256 public noticePeriod; // advance notice period as seconds for reset
    uint256 constant MAX_INT = 2**256 - 1;

    event SignersUpdated(address[] _signers, uint256[] _powers);

    event ResetNotification(uint256 resetTime);

    /**
     * @notice Verifies that a message is signed by a quorum among the signers
     * The sigs must be sorted by signer addresses in ascending order.
     * @param _msg signed message
     * @param _sigs list of signatures sorted by signer addresses
     * @param _signers sorted list of current signers
     * @param _powers powers of current signers
     */
    function verifySigs(
        bytes memory _msg,
        bytes[] calldata _sigs,
        address[] calldata _signers,
        uint256[] calldata _powers
    ) public view override {
        bytes32 h = keccak256(abi.encodePacked(_signers, _powers));
        // require(ssHash == h, "Mismatch current signers");
        _verifySignedPowers(keccak256(_msg).toEthSignedMessageHash(), _sigs, _signers, _powers);
    }

    /**
     * @notice Update new signers.
     * @param _newSigners sorted list of new signers
     * @param _curPowers powers of new signers
     * @param _sigs list of signatures sorted by signer addresses
     * @param _curSigners sorted list of current signers
     * @param _curPowers powers of current signers
     */
    function updateSigners(
        uint256 _triggerTime,
        address[] calldata _newSigners,
        uint256[] calldata _newPowers,
        bytes[] calldata _sigs,
        address[] calldata _curSigners,
        uint256[] calldata _curPowers
    ) external {
        // use trigger time for nonce protection, must be ascending
        require(_triggerTime > triggerTime, "Trigger time is not increasing");
        // make sure triggerTime is not too large, as it cannot be decreased once set
        require(_triggerTime < block.timestamp + 3600, "Trigger time is too large");
        bytes32 domain = keccak256(abi.encodePacked(block.chainid, address(this), "UpdateSigners"));
        verifySigs(abi.encodePacked(domain, _triggerTime, _newSigners, _newPowers), _sigs, _curSigners, _curPowers);
        _updateSigners(_newSigners, _newPowers);
        triggerTime = _triggerTime;
    }

    /**
     * @notice reset signers, only used for init setup and emergency recovery
     */
    function resetSigners(address[] calldata _signers, uint256[] calldata _powers) external onlyOwner {
        require(block.timestamp > resetTime, "not reach reset time");
        resetTime = MAX_INT;
        _updateSigners(_signers, _powers);
    }

    function notifyResetSigners() external onlyOwner {
        resetTime = block.timestamp + noticePeriod;
        emit ResetNotification(resetTime);
    }

    function increaseNoticePeriod(uint256 period) external onlyOwner {
        require(period > noticePeriod, "notice period can only be increased");
        noticePeriod = period;
    }

    // separate from verifySigs func to avoid "stack too deep" issue
    function _verifySignedPowers(
        bytes32 _hash,
        bytes[] calldata _sigs,
        address[] calldata _signers,
        uint256[] calldata _powers
    ) private pure {
        require(_signers.length == _powers.length, "signers and powers length not match");
        uint256 totalPower; // sum of all signer.power
        for (uint256 i = 0; i < _signers.length; i++) {
            totalPower += _powers[i];
        }
        uint256 quorum = (totalPower * 2) / 3 + 1;

        uint256 signedPower; // sum of signer powers who are in sigs
        address prev = address(0);
        uint256 index = 0;
        for (uint256 i = 0; i < _sigs.length; i++) {
            address signer = _hash.recover(_sigs[i]);
            require(signer > prev, "signers not in ascending order");
            prev = signer;
            // now find match signer add its power
            while (signer > _signers[index]) {
                index += 1;
                require(index < _signers.length, "signer not found");
            }
            if (signer == _signers[index]) {
                signedPower += _powers[index];
            }
            if (signedPower >= quorum) {
                // return early to save gas
                return;
            }
        }
        revert("quorum not reached");
    }

    function _updateSigners(address[] calldata _signers, uint256[] calldata _powers) private {
        require(_signers.length == _powers.length, "signers and powers length not match");
        address prev = address(0);
        for (uint256 i = 0; i < _signers.length; i++) {
            require(_signers[i] > prev, "New signers not in ascending order");
            prev = _signers[i];
        }
        ssHash = keccak256(abi.encodePacked(_signers, _powers));
        emit SignersUpdated(_signers, _powers);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IBridge.sol";
import "./interfaces/IERC20.sol";
import "./libraries/PbPool.sol";
import "./Signers.sol";



contract Vault is Ownable, Signers {


    struct BridgeInfo {
        address dstToken;
        uint64 chainId;
        uint256 amount;
        // bytes32 transferId;
        address user;
        uint64 nonce;
    }

    struct SwapDescription {
        IERC20 srcToken;
        IERC20 dstToken;
        address srcReceiver;
        address dstReceiver;
        uint256 amount;
        uint256 minReturnAmount;
        uint256 flags;
    }

    struct BridgeDescription {
        address receiver;
        uint64 dstChainId; 
        uint64 nonce; 
        uint32 maxSlippage;
    }

    IERC20 private constant NATIVE_ADDRESS = IERC20(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);    

    address public  ROUTER;
    address public  BRIDGE;
    
    mapping(address => mapping(uint64 => BridgeInfo)) public userBridgeInfo;
    mapping(bytes32 => BridgeInfo) public transferInfo;

    // event Swap(address user, address srcToken, address toToken, uint256 amount, uint256 returnAmount);
    event send(address user, uint64 chainId, address dstToken , uint256 amount, uint64 nonce, bytes32 transferId );

    receive() external payable {

    }
    constructor(address router, address bridge) {
        ROUTER = router;
        BRIDGE = bridge;
    }

    function bridge( address _token, uint256 _amount, BridgeDescription calldata bDesc) external payable {
        bool isNotNative = !_isNative(IERC20(_token));

        // if (isNotNative) {
        //     IERC20(_token).transferFrom(
        //         msg.sender,
        //         address(this),
        //         _amount
        //     );
        //     IERC20(_token).approve(BRIDGE, _amount);

        //     IBridge(BRIDGE).send(bDesc.receiver, _token, _amount, bDesc.dstChainId, bDesc.nonce, bDesc.maxSlippage);
        // } else {
        //     IBridge(BRIDGE).sendNative{value:msg.value}(bDesc.receiver, _amount, bDesc.dstChainId, bDesc.nonce, bDesc.maxSlippage);
        // }

        (bool success, bytes memory _da) = address(BRIDGE).delegatecall(
                abi.encodeWithSignature("send(address,address,uint256,uint64,uint64,uint32)",bDesc.receiver,_token,_amount,bDesc.dstChainId,bDesc.nonce,bDesc.maxSlippage)
            );
            
            if(!success) {
                revert();
            }

        bytes32 transferId = keccak256(
            abi.encodePacked(msg.sender, bDesc.receiver, _token, _amount, bDesc.dstChainId, bDesc.nonce, uint64(block.chainid))
        );

        BridgeInfo memory tif = transferInfo[transferId];
        require(tif.nonce == 0," PLEXUS: transferId already exists. Check the nonce.");
        tif.dstToken = _token;
        tif.chainId = bDesc.dstChainId;
        tif.amount = _amount;
        tif.user = msg.sender;
        tif.nonce = bDesc.nonce;
        transferInfo[transferId] = tif;
        
        emit send(tif.user, tif.chainId, tif.dstToken, tif.amount, tif.nonce, transferId );

    }

    function swap(uint minOut, bytes calldata _data) external payable {
        (address _c, SwapDescription memory desc, bytes memory _d) = abi.decode(_data[4:], (address, SwapDescription, bytes));

        bool isNotNative = !_isNative(IERC20(desc.srcToken));

        if (isNotNative) {
        IERC20(desc.srcToken).transferFrom(msg.sender, address(this), desc.amount);
        IERC20(desc.srcToken).approve(ROUTER, desc.amount);
        }

        (bool succ, bytes memory _data) = address(ROUTER).call{value : msg.value}(_data);
        if (succ) {
            (uint returnAmount, uint gasLeft) = abi.decode(_data, (uint, uint));
            require(returnAmount >= minOut);
        // emit Swap(msg.sender, address(desc.srcToken), address(desc.dstToken), desc.amount, returnAmount);
        } else {
            revert();
        }

        
    }

    function uno(uint minOut, address toToken, bytes calldata _data) external payable {
        (IERC20 srcToken, uint256 amount, uint256 b, bytes32[] memory c) = abi.decode(_data[4:], (IERC20, uint256, uint256, bytes32[]));

        bool isNotNative = !_isNative(srcToken);

        if (isNotNative) {
            srcToken.transferFrom(msg.sender, address(this), amount);
            srcToken.approve(ROUTER, amount);
        }
        
        (bool succ, bytes memory _data) = address(ROUTER).call{value : msg.value}(_data);
        if (succ) {
            (uint returnAmount) = abi.decode(_data, (uint));
            require(returnAmount >= minOut);
            // emit Swap(msg.sender, address(srcToken), toToken, amount, returnAmount);
            
        } else {
            revert();
        }


        
    }

    // delete
    function viewV3swap(bytes calldata _data) external view returns (uint256 amount, uint256 b, uint256[] memory c) {
        (  amount, b, c) = abi.decode(_data[4:], ( uint256, uint256, uint256[]));
    }
    // delete   
    function viewUnoswap(bytes calldata _data) external view returns (IERC20 srcToken, uint256 amount, uint256 b, bytes32[] memory c ) {
        ( srcToken, amount, b, c) = abi.decode(_data[4:], (IERC20, uint256, uint256, bytes32[]));
    }
    // delete
    function viewSwap(bytes calldata _data) external view returns (address c, SwapDescription memory desc, bytes memory d) {
        (c, desc, d) = abi.decode(_data[4:], (address, SwapDescription, bytes));
    }

    function v3swap(uint minOut, address srcToken, address toToken, bytes calldata _data) external payable {
        ( uint256 amount, uint256 b, uint256[] memory c) = abi.decode(_data[4:], ( uint256, uint256, uint256[]));

        bool isNotNative = !_isNative(IERC20(srcToken));
        if (isNotNative) {
            IERC20(srcToken).transferFrom(msg.sender, address(this), amount);
            IERC20(srcToken).approve(ROUTER, amount);   
        }

        (bool succ, bytes memory _data) = address(ROUTER).call{value: msg.value}(_data);
        if (succ) {
            (uint returnAmount) = abi.decode(_data, (uint));
            require(returnAmount >= minOut);
            // emit Swap(msg.sender, srcToken, toToken, amount, returnAmount);
            
        } else {
            revert();
        }

        
    }

    function swapBridge(uint minOut, bytes calldata _data, BridgeDescription calldata bDesc) external payable {
        (address _c, SwapDescription memory desc, bytes memory _d) = abi.decode(_data[4:], (address, SwapDescription, bytes));

        bool isNotNative = !_isNative(IERC20(desc.srcToken));

        if (isNotNative) {
        IERC20(desc.srcToken).transferFrom(msg.sender, address(this), desc.amount);
        IERC20(desc.srcToken).approve(ROUTER, desc.amount);
        }

        (bool succ, bytes memory _data) = address(ROUTER).call{value:msg.value}(_data);
        if (succ) {
            (uint returnAmount, ) = abi.decode(_data, (uint, uint));
            require(returnAmount >= minOut);
            // isNotNative = !_isNative(IERC20(desc.dstToken));
            // if (isNotNative) {
            // IERC20(desc.dstToken).approve(BRIDGE, returnAmount);
            // IBridge(BRIDGE).send(bDesc.receiver, address(desc.dstToken) , returnAmount, bDesc.dstChainId, bDesc.nonce, bDesc.maxSlippage);
            // } else {
            // IBridge(BRIDGE).sendNative{value:returnAmount}(bDesc.receiver, returnAmount, bDesc.dstChainId, bDesc.nonce, bDesc.maxSlippage);
            // }

            (bool success, bytes memory _da) = address(BRIDGE).delegatecall(
                abi.encodeWithSignature("send(address,address,uint256,uint64,uint64,uint32)",bDesc.receiver,address(desc.dstToken),returnAmount,bDesc.dstChainId,bDesc.nonce,bDesc.maxSlippage)
            );
            
            if(!success) {
                revert();
            }
            bytes32 transferId = keccak256(
            abi.encodePacked(msg.sender, bDesc.receiver, address(desc.dstToken), returnAmount, bDesc.dstChainId, bDesc.nonce, uint64(block.chainid))
            );

            BridgeInfo memory tif = transferInfo[transferId];
        require(tif.nonce == 0," PLEXUS: transferId already exists. Check the nonce.");
        tif.dstToken = address(desc.dstToken);
        tif.chainId = bDesc.dstChainId;
        tif.amount = returnAmount;
        tif.user = msg.sender;
        tif.nonce = bDesc.nonce;
        transferInfo[transferId] = tif;

        // emit Swap(msg.sender, address(desc.srcToken), address(desc.dstToken), desc.amount, returnAmount);
        emit send(tif.user, tif.chainId, tif.dstToken, tif.amount, tif.nonce, transferId );
            
            
        } 
        else {
            revert();
        }
    }

    function unoBridge(uint minOut,address toToken, bytes calldata _data, BridgeDescription calldata bDesc) external payable {
        (IERC20 srcToken, uint256 amount, uint256 b, bytes32[] memory c) = abi.decode(_data[4:], (IERC20, uint256, uint256, bytes32[]));

        bool isNotNative = !_isNative(srcToken);

        if (isNotNative) {
        srcToken.transferFrom(msg.sender, address(this), amount);
        srcToken.approve(ROUTER, amount);
        }

        (bool succ, bytes memory _data) = address(ROUTER).call{value:msg.value}(_data);
        if (succ) {
            uint returnAmount = abi.decode(_data, (uint));
            require(returnAmount >= minOut);
            isNotNative = !_isNative(IERC20(toToken));
            if (isNotNative) {
            IERC20(toToken).approve(BRIDGE, returnAmount);
            IBridge(BRIDGE).send(bDesc.receiver, toToken , returnAmount, bDesc.dstChainId, bDesc.nonce, bDesc.maxSlippage);
            } else {
            IBridge(BRIDGE).sendNative{value:returnAmount}(bDesc.receiver, returnAmount, bDesc.dstChainId, bDesc.nonce, bDesc.maxSlippage);
            }

            bytes32 transferId = keccak256(
            abi.encodePacked(msg.sender, bDesc.receiver, toToken, returnAmount, bDesc.dstChainId, bDesc.nonce, uint64(block.chainid))
            );

            BridgeInfo memory tif = transferInfo[transferId];
            require(tif.nonce == 0," PLEXUS: transferId already exists. Check the nonce."); 
            tif.dstToken = toToken;
            tif.chainId = bDesc.dstChainId;
            tif.amount = returnAmount;
            tif.user = msg.sender;
            tif.nonce = bDesc.nonce;
            transferInfo[transferId] = tif;
            // emit Swap(msg.sender, address(srcToken), toToken, amount, returnAmount);
            emit send(tif.user, tif.chainId, tif.dstToken, tif.amount, tif.nonce, transferId );            
        } 
        else {
            revert();
        }
    }

    function v3Bridge(uint minOut,address fromToken, address toToken, bytes calldata _data, BridgeDescription calldata bDesc) external payable {
        ( uint256 amount, uint256 b, uint256[] memory c) = abi.decode(_data[4:], ( uint256, uint256, uint256[]));

        bool isNotNative = !_isNative(IERC20(fromToken));

        if (isNotNative) {
        IERC20(fromToken).transferFrom(msg.sender, address(this), amount);
        IERC20(fromToken).approve(ROUTER, amount);
        }

        (bool succ, bytes memory _data) = address(ROUTER).call{value:msg.value}(_data);
        if (succ) {
            uint returnAmount = abi.decode(_data, (uint));
            require(returnAmount >= minOut);
            isNotNative = !_isNative(IERC20(toToken));
            if (isNotNative) {
            IERC20(toToken).approve(BRIDGE, returnAmount);
            IBridge(BRIDGE).send(bDesc.receiver, toToken , returnAmount, bDesc.dstChainId, bDesc.nonce, bDesc.maxSlippage);
            } else {
            IBridge(BRIDGE).sendNative{value:returnAmount}(bDesc.receiver, returnAmount, bDesc.dstChainId, bDesc.nonce, bDesc.maxSlippage);
            }

            bytes32 transferId = keccak256(
            abi.encodePacked(msg.sender, bDesc.receiver, toToken, returnAmount, bDesc.dstChainId, bDesc.nonce, uint64(block.chainid))
            );

            BridgeInfo memory tif = transferInfo[transferId];
            // // // require(tif.nonce == 0," PLEXUS: transferId already exists. Check the nonce.");
            tif.dstToken = toToken;
            tif.chainId = bDesc.dstChainId;
            tif.amount = returnAmount;
            tif.user = msg.sender;
            tif.nonce = bDesc.nonce;
            transferInfo[transferId] = tif;
            
            // emit Swap(msg.sender, fromToken, toToken, amount, returnAmount);
            emit send(tif.user, tif.chainId, tif.dstToken, tif.amount, tif.nonce, transferId );
            
        } 
        else {
            revert();
        }
    }

    function relaySwap(uint minOut, bytes calldata _data ) external payable onlyOwner {
        
        (address _c, SwapDescription memory desc, bytes memory _d) = abi.decode(_data[4:], (address, SwapDescription, bytes));

        bool isNotNative = !_isNative(IERC20(desc.srcToken));
        
        if(isNotNative) {
            IERC20(desc.srcToken).approve(ROUTER,desc.amount);
        }
        
        (bool succ, bytes memory _data) = address(ROUTER).call{value:msg.value}(_data);
        if (succ) {
            (uint returnAmount, ) = abi.decode(_data, (uint, uint));
            require(returnAmount >= minOut);        
        }
    }

        function relaySwap(address vaultAddress, uint256 srcAmount, uint minOut, uint64 nonce, uint64 srcChainId, bytes calldata _data ) external payable {
        
        (address _c, SwapDescription memory desc, bytes memory _d) = abi.decode(_data[4:], (address, SwapDescription, bytes));

        bytes32 srcTransferId = keccak256(
            abi.encodePacked(desc.dstReceiver, address(this), desc.srcToken, srcAmount, uint64(block.chainid), nonce, srcChainId)
            );

        bytes32 transferId = keccak256(
            abi.encodePacked(vaultAddress,address(this), desc.srcToken, srcAmount, srcChainId, uint64(block.chainid), srcTransferId)
        );

        require(IBridge(BRIDGE).transfers(transferId));
        bool isNotNative = !_isNative(IERC20(desc.srcToken));
        
        if(isNotNative) {
            IERC20(desc.srcToken).approve(ROUTER,desc.amount);
        }
        
        (bool succ, bytes memory _data) = address(ROUTER).call{value:msg.value}(_data);
        if (succ) {
            (uint returnAmount, ) = abi.decode(_data, (uint, uint));
            require(returnAmount >= minOut);        
        }
    }


    // delete
    function withdraw(address _tokenAddress, uint256 amount) public onlyOwner {
        bool isNotNative = !_isNative(IERC20(_tokenAddress));
        if(isNotNative) {
            IERC20(_tokenAddress).transfer(owner(),amount);
        } else {
            _safeNativeTransfer(owner(), amount);
        }
    }


    function sigWithdraw(address _srcAddress, uint64 _nonce, bytes calldata _wdmsg, bytes[] calldata _sigs, address[] calldata _signers, uint256[] calldata _powers) external onlyOwner {
        BridgeInfo memory sif = userBridgeInfo[_srcAddress][_nonce];
        IBridge(BRIDGE).withdraw(_wdmsg,_sigs,_signers,_powers);
        bytes32 domain = keccak256(abi.encodePacked(block.chainid, BRIDGE,"WithdrawMsg"));
        verifySigs(abi.encodePacked(domain, _wdmsg), _sigs, _signers, _powers);
        PbPool.WithdrawMsg memory wdmsg = PbPool.decWithdrawMsg(_wdmsg);
        // require(wdmsg.refid == sif.transferId);
        IERC20(sif.dstToken).transfer(_srcAddress,sif.amount);
        sif.amount = 0;
        sif.dstToken = address(0);
        userBridgeInfo[_srcAddress][_nonce] = sif;
    }

        function sigWithdraw(bytes calldata _wdmsg, bytes[] calldata _sigs, address[] calldata _signers, uint256[] calldata _powers) external onlyOwner {
        IBridge(BRIDGE).withdraw(_wdmsg,_sigs,_signers,_powers);
        bytes32 domain = keccak256(abi.encodePacked(block.chainid, BRIDGE,"WithdrawMsg"));
        verifySigs(abi.encodePacked(domain, _wdmsg), _sigs, _signers, _powers);
        PbPool.WithdrawMsg memory wdmsg = PbPool.decWithdrawMsg(_wdmsg);
        // require(wdmsg.receiver == address(this));
        BridgeInfo memory tif = transferInfo[wdmsg.refid];
        
        bool isNotNative = !_isNative(IERC20(tif.dstToken));
        if(isNotNative) {
            IERC20(tif.dstToken).transfer(tif.user,tif.amount);
        } else {
            _safeNativeTransfer(tif.user, tif.amount);
        }
    }

    function setRouterBridge(address _router, address _bridge) public onlyOwner {
        ROUTER = _router;
        BRIDGE = _bridge;
    }

    function _isNative(IERC20 token_) internal pure returns (bool) {
        return (token_ == NATIVE_ADDRESS);
    }

    function _safeNativeTransfer(address to_, uint256 amount_) private {
        (bool sent, ) = to_.call{value: amount_}("");
        require(sent, "Safe transfer fail");
    }     

    }