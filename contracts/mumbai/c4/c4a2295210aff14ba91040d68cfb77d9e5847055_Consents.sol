// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "./IConsents.sol";
import "./ConsentRegistry.sol";
import "./access/Managers.sol";

import {ArraysUint32, ArraysBytes32} from "./lib/ArrayUtils.sol";

contract Consents is IConsents, ConsentRegistry, Managers {

    using ArraysUint32 for uint32[];
    using ArraysBytes32 for bytes32[];

    enum ConsentState {NOT_AGREED, PREVIOUSLY_AGREED, AGREED}

    mapping(bytes32 => uint32[]) internal _personConsents;
    mapping(uint32 => mapping(bytes32 => ConsentState)) internal _consentPersonsMap;
    mapping(uint32 => bytes32[]) internal _consentPersonsArr;


    function updatePersonConsents(bytes32 id, uint32[] memory agreedConsents) external override {
        for (uint32 i = 0; i < agreedConsents.length; i++) {
            require(consents[agreedConsents[i]].id > 0, "Consents: consent doesn't exist");
        }

        uint32[] memory currentConsents = _personConsents[id];
        uint32[] memory newConsents = agreedConsents.filterNotContained(currentConsents);


        for (uint32 i = 0; i < newConsents.length; i++) {
            require(consents[newConsents[i]].active, "Consents: it is not possible to accept an inactive consent");
        }

        if (newConsents.length > 0) {
            require(_isManagerAllowedToChangeConsents(newConsents) || _isOwner(), "Only contract owner or consents manager can add person consents");

            emit PersonConsentsAgreed(id, newConsents);
        }

        uint32[] memory withdrawnConsents = currentConsents.filterNotContained(agreedConsents);

        if (withdrawnConsents.length > 0) {
            require(_isManagerAllowedToChangeConsents(withdrawnConsents) || _isOwner(), "Only contract owner or consents manager can remove person consents");

            emit PersonConsentsWithdrawn(id, withdrawnConsents);
        }

        _personConsents[id] = agreedConsents;

        for (uint32 i = 0; i < newConsents.length; i++) {
            uint32 consentId = newConsents[i];

            if (_consentPersonsMap[consentId][id] == ConsentState.PREVIOUSLY_AGREED) {
                _consentPersonsMap[consentId][id] = ConsentState.AGREED;
            }

            if (_consentPersonsMap[consentId][id] == ConsentState.NOT_AGREED) {
                _consentPersonsMap[consentId][id] = ConsentState.AGREED;
                _consentPersonsArr[consentId].push(id);
            }
        }

        for (uint32 i = 0; i < withdrawnConsents.length; i++) {
            uint32 consentId = withdrawnConsents[i];

            _consentPersonsMap[consentId][id] = ConsentState.PREVIOUSLY_AGREED;
        }
    }

    function personConsents(bytes32 id) external view returns (uint32[] memory) {
        return _personConsents[id];
    }

    function consentPersons(uint32 id) external view returns (bytes32[] memory) {
        bytes32[] memory ids = new bytes32[](_consentPersonsArr[id].length);
        uint32 count = 0;

        for (uint32 i = 0; i < ids.length; i++) {
            bytes32 hash = _consentPersonsArr[id][i];

            if (_consentPersonsMap[id][hash] == ConsentState.AGREED) {
                ids[count] = hash;
                count++;
            }
        }

        return ids.take(count);
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

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

library ConsentStruct {

    struct Consent {
        uint32 id;
        string name;
        string label;
        bool active;
        bytes32 contentHash;
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import {ConsentStruct as c} from "./ConsentStruct.sol";

library ArraysUint32 {

    function filterNotContained(uint32[] memory a, uint32[] memory b) internal pure returns (uint32[] memory) {
        uint32[] memory filtered = new uint32[](a.length);
        uint32 count = 0;

        for (uint32 i = 0; i < a.length; i++) {
            bool isContained = false;

            for (uint32 j = 0; j < b.length; j++) {
                if (a[i] == b[j]) {
                    isContained = true;
                    break;
                }
            }

            if (!isContained) {
                filtered[count] = a[i];
                count++;
            }
        }

        return take(filtered, count);
    }

    function take(uint32[] memory arr, uint32 amount) internal pure returns (uint32[] memory) {
        uint32[] memory tmp = new uint32[](amount);

        for (uint32 i = 0; i < amount; i++) {
            tmp[i] = arr[i];
        }

        return tmp;
    }
}

library ArraysConsent {

    function take(c.Consent[] memory arr, uint32 amount) internal pure returns (c.Consent[] memory) {
        c.Consent[] memory tmp = new c.Consent[](amount);

        for (uint32 i = 0; i < amount; i++) {
            tmp[i] = arr[i];
        }

        return tmp;
    }
}

library ArraysBytes32 {

    function take(bytes32[] memory arr, uint32 amount) internal pure returns (bytes32[] memory) {
        bytes32[] memory tmp = new bytes32[](amount);

        for (uint32 i = 0; i < amount; i++) {
            tmp[i] = arr[i];
        }

        return tmp;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.7.3 (access/Ownable.sol)

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
    *   @dev Returins if the sender is ther owner
    */
    function _isOwner() internal view returns (bool) {
        return owner() == _msgSender();
    }


    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     * "public -> external" diff from OpenZeppelin version
     */
    function transferOwnership(address newOwner) external virtual onlyOwner {
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

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "./IManagers.sol";
import "./Ownable.sol";

contract Managers is IManagers, Ownable {

    mapping(address => uint32[]) private _managersToConsents;
    address[] private _managers;

    function updateManager(address manager, uint32[] memory consentsIds) external onlyOwner override {
        if (consentsIds.length > 0 && _managersToConsents[manager].length == 0) {
            _managers.push(manager);
        }
        _managersToConsents[manager] = consentsIds;
        emit ManagerWithConsentsChanged(manager, consentsIds, _msgSender());
    }

    function getManagers() external view override returns (address[] memory) {
        return _managers;
    }

    function isManager(address manager) external view override returns (bool) {
        return _managersToConsents[manager].length > 0;
    }

    function getManagerConsents(address manager) external view override returns (uint32[] memory) {
        return _managersToConsents[manager];
    }

    function _isManagerAllowedToChangeConsents(uint32[] memory consentsIds) internal view returns (bool) {
        uint32 [] memory managerConsents = _managersToConsents[_msgSender()];
        bool result = false;
        if (managerConsents.length > 0 && managerConsents.length >= consentsIds.length) {
            for (uint32 i = 0; i < consentsIds.length; i++) {
                bool found = false;
                for (uint32 mi = 0; mi < managerConsents.length; mi++) {
                    if (consentsIds[i] == managerConsents[mi]) {
                        found = true;
                    }
                }
                if (found == false) {
                    return false;
                }
            }
            result = true;
        }
        return result;
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "./Ownable.sol";

interface IManagers {
    function updateManager(address manager, uint32[] memory consentsIds) external;

    function isManager(address manager) external view returns (bool);

    function getManagerConsents(address manager) external view returns (uint32[] memory);

    function getManagers() external view returns (address[] memory);

    event ManagerWithConsentsChanged(address indexed manager, uint32[] consentsIds, address changedBy);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface IConsents {

    function updatePersonConsents(bytes32 id, uint32[] memory agreedConsents) external;

    function personConsents(bytes32 id) external view returns (uint32[] memory);

    function consentPersons(uint32 id) external view returns (bytes32[] memory);

    event PersonConsentsAgreed(bytes32 indexed id, uint32[] consents);

    event PersonConsentsWithdrawn(bytes32 indexed id, uint32[] consents);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import {ConsentStruct as c} from "./lib/ConsentStruct.sol";

interface IConsentRegistry {

    function addConsent(string memory _name, string memory _label, bytes32 _contentHash) external;

    function deactivateConsent(uint32 _id) external;

    function activateConsent(uint32 _id) external;

    function updateContentHash(uint32 _id, bytes32 _contentHash) external;

    function getConsents() external view returns (c.Consent[] memory);

    function getActiveConsents() external view returns (c.Consent[] memory);
    
    event ConsentAdded(uint32 indexed id, string name, string label, bytes32 contentHash);

    event ConsentDeactivated(uint32 indexed id);

    event ConsentActivated(uint32 indexed id);

    event ConsentUpdated(uint32 indexed id, bytes32 contentHash);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "./IConsentRegistry.sol";
import "./access/Ownable.sol";

import {ArraysConsent} from "./lib/ArrayUtils.sol";

contract ConsentRegistry is IConsentRegistry, Ownable {

    using ArraysConsent for c.Consent[];

    mapping(uint32 => c.Consent) public consents;
    uint32 internal _consentsCount = 0;

    function addConsent(string memory name, string memory label, bytes32 contentHash) external onlyOwner override {
        _consentsCount++;
        consents[_consentsCount] = c.Consent(_consentsCount, name, label, false, contentHash);

        emit ConsentAdded(_consentsCount, name, label, contentHash);

    }

    function deactivateConsent(uint32 id) external onlyOwner override {
        require(consents[id].active, "ConsentRegistry: cannot update - consent is inactive");

        consents[id].active = false;

        emit ConsentDeactivated(id);
    }

    function activateConsent(uint32 id) external onlyOwner override {
        require(!consents[id].active, "ConsentRegistry: cannot update - consent is active");

        consents[id].active = true;

        emit ConsentActivated(id);
    }

    function updateContentHash(uint32 id, bytes32 contentHash) external onlyOwner override {
        require(consents[id].active, "ConsentRegistry: cannot update - consent is inactive");

        consents[id].contentHash = contentHash;

        emit ConsentUpdated(id, contentHash);
    }

    function getConsents() external view override returns (c.Consent[] memory) {
        return _getConsents();
    }

    function getActiveConsents() external view override returns (c.Consent[] memory) {
        return _getActiveConsents();
    }

    function _getConsents() internal view returns (c.Consent[] memory) {
        c.Consent[] memory tmp = new c.Consent[](_consentsCount);
        uint32 count = 0;

        for (uint32 i = 1; i <= _consentsCount; i++) {
            tmp[count] = consents[i];
            count++;
        }

        return tmp;
    }

    function _getActiveConsents() internal view returns (c.Consent[] memory) {
        c.Consent[] memory filtered = new c.Consent[](_consentsCount);
        uint32 count = 0;

        for (uint32 i = 1; i <= _consentsCount; i++) {
            if (consents[i].active) {
                filtered[count] = consents[i];
                count++;
            }
        }

        return filtered.take(count);
    }
}