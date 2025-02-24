// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import {DataTypes} from "./DataTypes.sol";

interface ERC721Interface {
    function ownerOf(uint256 _tokenId) external view returns (address);
    function name() external view returns (string memory);
    function tokenURI(uint256 _tokenId) external view returns (string memory);
}

contract NFP is Ownable {
    mapping(string => DataTypes.NFTInfo) public nfcsRegistered;
    uint public printingCost = 0.0001 ether;

    using Counters for Counters.Counter;
    Counters.Counter private _nfcId;

    event NFCPrinted(string nfcTag, DataTypes.NFTInfo nftInfo, address nftOwnerAddress);
    event NFCStatusChanged(string nfcTag, DataTypes.NFTInfo nftInfo);
    event NFCDestroyed(string nfcTag, DataTypes.NFTInfo nftInfo);
    event NFCPriceChanged(uint newPrice, uint256 updateTime);

    constructor() {
    }

    modifier isOwnerOfNft(address _nftAddress, uint256 _nftId) {
        ERC721Interface collectionToCheck = ERC721Interface(_nftAddress);
        require(collectionToCheck.ownerOf(_nftId) == msg.sender, "You are not the owner of the NFT");
        _;
    }

    function withdraw() public onlyOwner {
        uint amount = address(this).balance;
        address platformOwner = owner();

        (bool success, ) = platformOwner.call{value: amount}("");
        require(success, "Failed to send Ether");
    }

    function printNFC(address _nftAddress, uint256 _nftId)
        public payable isOwnerOfNft(_nftAddress, _nftId)
    {
        require(msg.value >= printingCost, "Value is not correct"); 
        ERC721Interface collectionToCheck = ERC721Interface(_nftAddress);
        uint256 newNfcId = _nfcId.current();
        string memory titleOfNft = collectionToCheck.name();
        string memory uriOfNft = collectionToCheck.tokenURI(_nftId);
        string memory nfcTag = string(abi.encodePacked(Strings.toString(newNfcId),"-",titleOfNft,"-",Strings.toString(_nftId)));
    
        DataTypes.NFTInfo memory newNFT = DataTypes.NFTInfo({
            nftAddress: _nftAddress,
            nftId: _nftId,
            isActive: false,
            isDestroyed: false,
            nftName: titleOfNft,
            nftUri: uriOfNft,
            lastUpdated: block.timestamp
        });
        nfcsRegistered[nfcTag] = newNFT;
        emit NFCPrinted(nfcTag, newNFT, msg.sender);
        _nfcId.increment();
    }

    function getNFCStatus(string memory _nfcTag) public view returns(bool) {
        return nfcsRegistered[_nfcTag].isActive;
    }

    function changeNFCState(string memory _nfcTag, address _nftAddress, uint256 _nftId)
        public isOwnerOfNft(_nftAddress, _nftId) {
            require(nfcsRegistered[_nfcTag].isDestroyed == false, "NFC is destroyed");
            bool currentNFCState = nfcsRegistered[_nfcTag].isActive;
            
            if (currentNFCState == true) {
                nfcsRegistered[_nfcTag].isActive = false;
            }

            if (currentNFCState == false) {
                nfcsRegistered[_nfcTag].isActive = true;
            }
            
            nfcsRegistered[_nfcTag].lastUpdated = block.timestamp;
            emit NFCStatusChanged(_nfcTag, nfcsRegistered[_nfcTag]);
        }

    function destroyNFC(string memory _nfcTag, address _nftAddress, uint256 _nftId)
        public isOwnerOfNft(_nftAddress, _nftId) {
            if (nfcsRegistered[_nfcTag].isDestroyed == true) {
                revert("NFC already destroyed!");
            }
            nfcsRegistered[_nfcTag].isDestroyed = false;
            nfcsRegistered[_nfcTag].lastUpdated = block.timestamp;
            emit NFCDestroyed(_nfcTag, nfcsRegistered[_nfcTag]);
        }

        function setPrintingCost(uint _newPritingCost) public onlyOwner {
            printingCost = _newPritingCost;
            emit NFCPriceChanged(printingCost, block.timestamp);
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
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
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

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.0;

library DataTypes {
    struct NFTInfo {
        address nftAddress;
        uint256 nftId;
        bool isActive;
        bool isDestroyed;
        string nftName;
        string nftUri;
        uint256 lastUpdated;
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