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

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "./IBAWhitelist.sol";

contract BAWhitelist is Ownable, ERC165, IBAWhitelist {
    uint256 constant VERIFIED_FLAG = 0x01;
    uint256 constant CO_OWNER_FLAG = 0x02;
    uint256 constant PUBLISHER_FLAG = 0x04;

    event AddressSetAsVerified(address);
    event AddressUnsetAsVerified(address);
    event AddressSetAsCoOwner(address);
    event AddressUnsetAsCoOwner(address);
    event AddressSetAsPublisher(address);
    event AddressUnsetAsPublisher(address);

    mapping(address => uint256) private _walletFlags;

    function isVerified(address _address) public view returns (bool) {
        return (VERIFIED_FLAG & _walletFlags[_address]) == VERIFIED_FLAG;
    }

    function isCoOwner(address _address) public view returns (bool) {
        return (CO_OWNER_FLAG & _walletFlags[_address]) == CO_OWNER_FLAG;
    }

    function isPublisher(address _address) public view returns (bool) {
        return (PUBLISHER_FLAG & _walletFlags[_address]) == PUBLISHER_FLAG;
    }

    function setVerified(address _address) onlyOwner public {
        require(_address != address(0x0));
        _walletFlags[_address] |= VERIFIED_FLAG;

        emit AddressSetAsVerified(_address);
    }

    function unsetVerified(address _address) onlyOwner public {
        require(_address != address(0x0));
        _walletFlags[_address] &= ~VERIFIED_FLAG;

        emit AddressUnsetAsVerified(_address);
    }

    function setCoOwner(address _address) onlyOwner public {
        require(_address != address(0x0));
        _walletFlags[_address] |= CO_OWNER_FLAG;

        emit AddressSetAsCoOwner(_address);
    }

    function unsetCoOwner(address _address) onlyOwner public {
        require(_address != address(0x0));
        _walletFlags[_address] &= ~CO_OWNER_FLAG;

        emit AddressUnsetAsCoOwner(_address);
    }

    function setPublisher(address _address) onlyOwner public {
        require(_address != address(0x0));
        _walletFlags[_address] |= PUBLISHER_FLAG;

        emit AddressSetAsPublisher(_address);
    }

    function unsetPublisher(address _address) onlyOwner public {
        require(_address != address(0x0));
        _walletFlags[_address] &= ~PUBLISHER_FLAG;

        emit AddressUnsetAsPublisher(_address);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IBAWhitelist).interfaceId || super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0 <0.9.0;

interface IBAWhitelist {
    function isVerified(address _address) external view returns (bool);

    function isCoOwner(address _address) external view returns (bool);

    function isPublisher(address _address) external view returns (bool);

    function setVerified(address _address) external;

    function unsetVerified(address _address) external;

    function setCoOwner(address _address) external;

    function unsetCoOwner(address _address) external;

    function setPublisher(address _address) external;

    function unsetPublisher(address _address) external;
}