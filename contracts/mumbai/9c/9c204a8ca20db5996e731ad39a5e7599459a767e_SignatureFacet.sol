// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.14;

import {Base} from "../base/Base.sol";
import {SignatureChecker} from "../libraries/LibSignatureChecker.sol";

/// @title Signature Module
/// @author Kfish n Chips
/// @notice Check a valid a signature
/// @dev revert with InvalidSignature
/// @custom:security-contact [email protected]
contract SignatureFacet is Base {

    /// @notice Verify that signer do a valid signature 
    /// @dev revert with InvalidSignature
    /// @param signer the signer
    /// @param hash of siganture
    /// @param signature to validated
    function isValidSignature(
        address signer,
        bytes32 hash,
        bytes memory signature
    ) external pure {
        if(!SignatureChecker.verifySignature(signer, hash, signature)) revert InvalidSignature();
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.14;

import {AppStorage} from "../libraries/LibAppStorage.sol";
import {IBase} from "../interfaces/IBase.sol";

/// @title Base Contract for Facets
/// @author Kfish n Chips
/// @notice Check that caller is a EoA
/// @dev revert with CallerNotEoA
/// @custom:security-contact [email protected]
abstract contract Base is IBase {
    AppStorage internal s;

    /// @notice Check that caller is a EoA
    /// @dev revert with CallerNotEoA
    modifier onlyEoA() {
        if(tx.origin != msg.sender) revert CallerNotEoA();      // solhint-disable-line avoid-tx-origin
        _;
    }

    /// @notice Check that a project with projectId_  is active
    /// @dev revert with ProjectNotActive
    modifier projectIsActive(uint256 projectId_) {
        if (!(projectId_ > 0 && projectId_ <= s.projectsCount)) revert QueryNonExistentProject();
        if (!s.projects[projectId_].active) revert ProjectNotActive();
        _;
    }

    /// @notice Check that a project Exist
    /// @dev revert with QueryNonExistentProject
    modifier projectExist(uint256 projectId_) {
        if (!(projectId_ > 0 && projectId_ <= s.projectsCount)) revert QueryNonExistentProject();
        _;
    }

    /// @notice Check that category is Active Exist
    /// @dev 
    ///     revert with QueryNonExistentCategory
    ///     revert with CategoryNotActive
    modifier categoryIsActive(uint256 categoryId_) {
        if (!(categoryId_ > 0 && categoryId_ <= s.categoryCount)) revert QueryNonExistentCategory();
        if (!s.categories[categoryId_].active) revert CategoryNotActive();
        _;
    }

    /// @notice Check that a project Exist
    /// @dev revert with QueryNonExistentProject
    modifier categoryExist(uint256 categoryId_) {
        if (categoryId_ < 1 ||  categoryId_ > s.categoryCount) revert QueryNonExistentCategory();
        _;
    }
    
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

library SignatureChecker {
    using ECDSA for bytes32;
    
    function verifySignature(
        address signer,
        bytes32 hash,
        bytes memory signature
    ) internal pure returns (bool) {
        return signer == keccak256(abi.encodePacked(
            "\x19Ethereum Signed Message:\n32",
            hash
        )).recover(signature);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.14;

import {IERC20Metadata} from "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";

import {RaffleStorage} from "../facets/Raffle/RaffleStorage.sol";
import {ProjectStorage} from "../facets/Project/ProjectStorage.sol";
import {AllowlistStorage} from "../facets/Allowlist/AllowlistStorage.sol";
import {CategoryStorage} from "../facets/Category/CategoryStorage.sol";
import {UserInventoryStorage} from "../facets/UserInventory/UserInventoryStorage.sol";


import {UserStorage} from "./LibUserStorage.sol";


/* AppStorage Pattern
 *
 * @dev A nicer and more convenient way to access application specific state variables that are shared among facets.
 * 
 * Keep State Variables Safe
 *   DOES
 *      1 To add new state variables to an AppStorage struct, add them to the end of the struct. This makes sense 
 *          because it is not possible for existing facets to overwrite state variables at new storage locations.
 *      2 New state variables can be added to the ends of structs that are stored in mappings.
 *      3 A trick to use inner structs and still enable them to be extended is to put them in mappings. A struct 
 *          stored in a mapping can be extended in upgrades.
 *   DONT
 *      1 If you are using AppStorage then do not declare and use state variables outside the AppStorage struct. 
 *          Except Diamond Storage can be used.
 *      2 Do not add new state variables to the beginning or middle of structs. Doing this makes the new state 
 *          variable overwrite existing state variable data and all state variables after the new state variable 
 *          reference the wrong storage location.
 *      3 Do not put structs directly in structs unless you don’t plan on ever adding more state variables to the 
 *          inner structs. You won't be able to add new state variables to inner structs in upgrades.
 *      4 Do not add new state variables to structs that are used in arrays.
 *      5 Do not allow any facet to be able to call `selfdestruct`. This is easy. Simply don’t allow the `selfdestruct` 
 *          command to exist in any facet source code and don’t allow that command to be called via a delegatecall. Because 
 *          `selfdestruct` could delete a facet that is used by a diamond, or `selfdestruct` could be used to delete a 
 *          diamond proxy contract.
 */ 
 
struct AppStorage {
    uint256 allowlistsCount;
    uint256 rafflesCount;
    uint256 usersCount;
    uint256 projectsCount;
    uint256 categoryCount;
    uint256 activeCategoryCount;
    address createUserSigner;
    IERC20Metadata tokenContract;
    address collector;
    // wallet => User
    mapping(address => UserStorage) users;
    // project id => Project
    mapping(uint256 => ProjectStorage) projects;
    // listing id => Allowlist
    mapping(uint256 => AllowlistStorage) allowlists; 
    // raffle id => Raffle
    mapping(uint256 => RaffleStorage) raffles;
    // raffle id => address => bool)
    mapping(uint256 => mapping (address => bool)) rafflesWinners;
    // address => User Inventory
    mapping(address => UserInventoryStorage) userInventory;
    // category id => Category
    mapping(uint256 => CategoryStorage) categories;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

interface IBase {
    error EndTimeBeforeStartTime();
    error CallerNotEoA();
    error InvalidSignature();
    error QueryNonExistentCategory();
    error CategoryNotActive();
    error UserWalletNotMatch();
    error MaxPerWalletReached();
    
    /**
        STOCK
    */
    error TotalStockLessThanSoldStock();
    error NotEnoughStock();
    error NoStockLeft();
    error CreateWithZeroStock();
    error PurchasedGreaterStock();
    /**
        USERS
    */
    error UserAlreadyExists();
    error CreateUserSignerZero();
    error AlreadyIsCreateUserSigner();
    error QueryNonExistentUser();
    error UserIsFrozen();
    
    
    /**
        PROJECTS
    */
    error QueryNonExistentProject();
    error ProjectNotActive();
    error MaxPerWalletZero();
    error ProjectAlreadyInState();
    /**
        RBAC
    */
    error CallerNotAuthorized();
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/cryptography/ECDSA.sol)

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
        InvalidSignatureV
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
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
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
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
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
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
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
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/extensions/IERC20Metadata.sol";

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.14;

/// @title  Raffle AppStorage
/// @author Kfish n Chips
/// @dev New state variables can be added to the ends of structs that are stored in mappings.
/// @custom:security-contact [email protected]
struct RaffleStorage {
    uint256 id;
    uint256 stock;
    uint256 purchased;
    uint256 price;
    uint256 startTime;
    uint256 endTime;
    uint256 maxWinners;
    uint256 winnersCount;
    uint256 projectId;
    string  raffleMetadataUrl;
    bool active;
    bool raffled;
    address[] participants;
    address[] winners;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

/// @title  Project AppStorage
/// @author Kfish n Chips
/// @dev New state variables can be added to the ends of structs that are stored in mappings.
/// @custom:security-contact [email protected]
struct ProjectStorage {
    uint256 id;
    uint256 maxPerWallet;
    bool active;
    uint256 categoryId;
    string metadataUrl;
    uint256 allowlistsCount;
    uint256 raffleCount;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

struct AllowlistStorage {
    uint256 id;
    uint256 stock;
    uint256 purchased;
    uint256 price;
    uint256 startTime;
    uint256 endTime;
    uint256 projectId;
    string  allowlistMetadataUrl;
    bool active;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

/// @title Category AppStorage
/// @author Kfish n Chips
/// @dev New state variables can be added to the ends of structs that are stored in mappings.
/// @custom:security-contact [email protected]
struct CategoryStorage {
    uint256 id;
    string name;
    bool active;
    string metadataUrl;
    uint256 projectsCount;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

struct UserInventoryStorage {
    uint256[] allowlistsIds;
    uint256[] raffleIds;
    uint256[] raffleWonIds;
    // project id => count of allowlist + raffle won
    mapping(uint256 => uint256) projectBalance;
    // allowlist id => count of allowlist 
    mapping(uint256 => uint256) allowlistsBalance;
    // raffke id => count of raffle 
    mapping(uint256 => uint256) raffleBalance;
    // raffke id => count of raffle won
    mapping(uint256 => uint256) raffleWonBalance;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

/// @notice Data Storage for User
/// wallet: address of the user
/// discordID: ID of the user on Discord
/// frozen: enable/disable user

struct UserStorage {
    address wallet;
    string discordId;
    uint256 purchaseCount;
    bool frozen;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

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