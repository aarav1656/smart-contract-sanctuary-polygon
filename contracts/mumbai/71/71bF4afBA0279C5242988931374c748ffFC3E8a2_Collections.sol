/**
 *Submitted for verification at polygonscan.com on 2022-08-18
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

interface IModule {
    function getModule(uint256 module_) external view returns (address);
}

interface IRoles {
    function isVerifiedUser(address user_) external view returns (bool);
    function isModerator(address user_) external view returns (bool);
    function isAdmin(address user_) external view returns (bool);
    function isUser(address user_) external view returns (bool);
}

abstract contract Utilities {

    uint constant LONGEST_STRING = 40;

    function grepLetters(bytes memory array_) internal pure returns (uint256 number) {
        for (uint i = 0; i < array_.length; i++) {
            uint8 char = uint8(array_[i]);
            if ( ((char < 65) || (122 < char)) || ((char > 90) && (char < 97)) ) {
                number++;
            }
        }
    }
    
    function toUppercase(string memory parametro) public pure returns (string memory) {
        bytes memory stringAsArray = bytes(abi.encodePacked(parametro));
        require(stringAsArray.length <= LONGEST_STRING);
        uint invalidChar = grepLetters(stringAsArray);
        uint totalLength = stringAsArray.length - invalidChar;
        bytes memory arr_ = new bytes(totalLength); // byte[]

        uint secondIndex = 0;
        for (uint i = 0; i < stringAsArray.length; i++) {
            uint8 char = uint8(stringAsArray[i]);
            /* 65 <= char <= 90 => es mayuscula */
            if ( (65 <= char) && (char <= 90) ) {
                arr_[secondIndex] = bytes1(char);
                secondIndex++;
            /* 97 <= char <= 122 => es minuscula */
            } else if ( (97 <= char) && (char <= 122) ) {
                char -= 32;
                arr_[secondIndex] = bytes1(char);
                secondIndex++;
            }
        }
        return string(abi.encodePacked(arr_));
    }

    /**
     * @notice Function to return an integer to string
     * @param _i Integer
     * @return _uintAsString The integer as string
     */
    function toString(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) return "0";
        uint j = _i; uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
}

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

abstract contract ERC165 is IERC165 {
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

interface IERC1155Receiver is IERC165 {
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

library Address {
    function isContract(address account) internal view returns (bool) {
        return account.code.length > 0;
    }
}

interface IERC1155 is IERC165 {
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);
    event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values);
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);
    event URI(string value, uint256 indexed id);
    function balanceOf(address account, uint256 id) external view returns (uint256);
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids) external view returns (uint256[] memory);
    function setApprovalForAll(address operator, bool approved) external;
    function isApprovedForAll(address account, address operator) external view returns (bool);
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;
    function safeBatchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external;
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

/**
 * @notice ERC1155 implementation with multiple NFT collections
 */
contract ERC1155 is Context, ERC165, IERC1155 {
    /**
     * @notice To verify if the msg.sender is a contract
     */
    using Address for address;
    
    /**
     * @notice Collection to number of tokens in that collection
     */
    mapping(uint256 => uint256) public totalSupplys;

    /**
     * @notice Owner to collection
     */
    mapping(uint256 => address) public collectionOwners;

    /**
     * @notice Collection ID to address to number of tokens
     */
    mapping(uint256 => mapping(address => uint256)) public balances;

    /**
     * @notice Approval to bool, basically approves a user to move all tokens
     */
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @notice Address to token array of a specific collection
     */
    mapping(address => mapping(uint256 => uint256[])) public ownerToToken;

    /**
     * @notice Token index in the 'owners' array
     */
    mapping(uint256 => mapping(uint256 => uint256)) public tokenIndex;
    
    /**
     * @notice Truly ownership of the token
     */
    mapping(uint256 => mapping(uint256 => address)) private _ownerships;
    
    /**
     * @notice collectionId to collectionName
     */
    mapping(uint256 => string) public collectionName;

    /**
     * @notice collectionId to baseURI
     */
    mapping(uint256 => string) public collectionBaseURI;

    /**
     * @notice collectionId to extension
     */
    mapping(uint256 => string) public collectionExtension;

    /**
     * @notice Supports interface function
     * @param interfaceId interface id
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @notice Ask for balance of the account in certain collection
     * @param account Address to ask
     * @param id Collection to ask
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), 'E805');
        return balances[id][account];
    }

    /**
     * @notice Ask for balances of multiple accounts to collections
     * @param accounts Array of accounts
     * @param ids Array of ids
     */
    function balanceOfBatch(address[] memory accounts, 
                            uint256[] memory ids) public view virtual override returns (uint256[] memory) {
        require(accounts.length == ids.length, 'E806');

        uint256[] memory batchBalances = new uint256[](accounts.length);
        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }
        return batchBalances;
    }

    /**
     * @notice Set approval for all tokens 
     * @param operator Address to approve (or not)
     * @param approved Boolean if approved (or not)
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @notice Function to check if the given address is owner of the token
     * @param collection_ Token's collection
     * @param tokenId_ Token's id
     * @param owner_ address of the owner
     * @return bool is {owner_} has ownership of {tokenId_} from {collection_}
     */
    function hasOwnershipOf(uint collection_, uint tokenId_, address owner_) public view returns (bool) {
        require(totalSupplys[collection_] > tokenId_, 'E801');
        address owner = ownerOf(collection_, tokenId_);
        return (owner == owner_) || (isApprovedForAll(owner, _msgSender()));
    }

    /**
     * @notice If an address is approved to move all tokens from account
     * @param account Address that has the tokens
     * @param operator Address that will be able to move the tokens
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @notice Transfer function (modified for the tokenId transfer)
     * @param from From account
     * @param to To account
     * @param id Collection
     * @param amount -> Token id to transfer
     * @param data Leave in blank
     */
    function safeTransferFrom(address from,
                              address to,
                              uint256 id,
                              uint256 amount,
                              bytes memory data) public virtual override {
        require(from == _msgSender() || isApprovedForAll(from, _msgSender()), 'E802');
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @notice Transfer function from multiple collections (deprecated)
     * @param from From account
     * @param to To account
     * @param ids Collection ids to transfer
     * @param amounts Tokens ids to transfer
     * @param data Leave in blank
     */
    function safeBatchTransferFrom(address from,
                                   address to,
                                   uint256[] memory ids,
                                   uint256[] memory amounts,
                                   bytes memory data) public virtual override {
        require(from == _msgSender() || isApprovedForAll(from, _msgSender()), 'E802');
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @notice Internal function of transfer
     * @param from From account
     * @param to To account
     * @param collection Collection
     * @param tokenId -> Token id to transfer
     * @param data Leave in blank
     */
    function _safeTransferFrom(address from,
                               address to,
                               uint256 collection,
                               uint256 tokenId,
                               bytes memory data) internal virtual {
        require(to != address(0), 'E807');
        uint256[] memory categories = _asSingletonArray(collection);
        uint256[] memory amounts = _asSingletonArray(tokenId);
        _beforeTokenTransfer(_msgSender(), from, to, categories, amounts, data);
        address owner = ownerOf(collection, tokenId);
        require(from == owner);
        unchecked {
            balances[collection][from]--;
        }
        balances[collection][to]++;
        _ownerships[collection][tokenId] = to;
        
        uint256 size = ownerToToken[from][collection].length;
        /* the size is != if 'from' is collection creator
           (at least in the first instance) */
        if (size != 0) {
            _removeTokenFromArray(from, collection, tokenId);
        }
        /* Now, push the token into the 'to' array */
        tokenIndex[collection][tokenId] = ownerToToken[to][collection].length;
        ownerToToken[to][collection].push(tokenId);

        emit TransferSingle(_msgSender(), from, to, collection, tokenId);
        _doSafeTransferAcceptanceCheck(_msgSender(), from, to, collection, tokenId, data);
        _afterTokenTransfer(_msgSender(), from, to, categories, amounts, data);
    }

    /**
     * @notice Removes a token from array
     * @param owner_ Owner of the array
     * @param collection_ Collection
     * @param tokenId_ Token id to remove
     */
    function _removeTokenFromArray(address owner_, uint collection_, uint tokenId_) internal {
        uint256 size = ownerToToken[owner_][collection_].length;
        uint256 lastToken = ownerToToken[owner_][collection_][size - 1];
        uint256 tokenIndex_ = tokenIndex[collection_][tokenId_];
        
        ownerToToken[owner_][collection_][tokenIndex_] = lastToken;
        tokenIndex[collection_][lastToken] = tokenIndex_;
        ownerToToken[owner_][collection_].pop();
    }

    /**
     * @notice Internal function of transfer batch
     * @param from From account
     * @param to To account
     * @param ids Collection
     * @param amounts -> Token id to transfer
     * @param data Leave in blank
     * @notice This implementation is changing
     */
    function _safeBatchTransferFrom(address from,
                                    address to,
                                    uint256[] memory ids,  //collection
                                    uint256[] memory amounts, //token id
                                    bytes memory data) internal virtual {
        require((ids.length != 0) && (ids.length == amounts.length), 'E806');
        require(to != address(0), 'E807');
        _beforeTokenTransfer(_msgSender(), from, to, ids, amounts, data);
        
        // Check ownership of all tokens
        // Increment balance of to, Decrement balance of From
        // Set ownerships
        uint size;
        for (uint i = 0; i < ids.length; ++i) {
            require(from == ownerOf(ids[i], amounts[i]), 'E802');
            unchecked {
                balances[ids[i]][from]--;
            }
            balances[ids[i]][to]++;
            _ownerships[ids[i]][amounts[i]] = to;
            size = ownerToToken[from][ids[i]].length;
            
            if (size != 0) _removeTokenFromArray(from, ids[i], amounts[i]);
            tokenIndex[ids[i]][amounts[i]] = ownerToToken[to][ids[i]].length;
            ownerToToken[to][ids[i]].push(amounts[i]);
        }

        emit TransferBatch(_msgSender(), from, to, ids, amounts);
        _doSafeBatchTransferAcceptanceCheck(_msgSender(), from, to, ids, amounts, data);
        _afterTokenTransfer(_msgSender(), from, to, ids, amounts, data);
    }

    /**
     * @notice Burn function
     * @param from From account
     * @param collection Collection
     * @param tokenId tokenId to burn
     */
    function burn(address from,
                  uint256 collection,
                  uint256 tokenId) public {
        require(from == _msgSender(), 'E803');
        _burn(from, collection, tokenId);
    }

    /**
     * @notice Burn function
     * @param from From account
     * @param collection Collection
     * @param tokenId tokenId to burn
     */
    function burnBatch(address from,
                  uint256[] memory collection,
                  uint256[] memory tokenId) public {
        require(from == _msgSender(), 'E803');
        _burnBatch(from, collection, tokenId);
    }

    /**
     * @notice Internal function of burning tokens
     * @param from From account
     * @param collection Collection
     * @param tokenId -> Token id to burn
     */
    function _burn(address from,
                   uint256 collection,
                   uint256 tokenId) internal virtual {
        uint256[] memory collections = _asSingletonArray(collection);
        uint256[] memory tokenIds = _asSingletonArray(tokenId);

        _beforeTokenTransfer(_msgSender(), from, address(0), collections, tokenIds, "");

        require(from == ownerOf(collection, tokenId), 'E802');
        unchecked {
            balances[collection][from]--;
        }
        _ownerships[collection][tokenId] = 0x000000000000000000000000000000000000dEaD;
        uint size = ownerToToken[from][collection].length;

        if (size != 0) {
            _removeTokenFromArray(from, collection, tokenId);
        }

        emit TransferSingle(_msgSender(), from, address(0), collection, tokenId);
        _afterTokenTransfer(_msgSender(), from, address(0), collections, tokenIds, "");
    }

     /**
     * @notice Internal function of burn batch
     * @param from To account
     * @param ids Collection
     * @param amounts -> Token id to transfer
     * @notice This implementation is deprecated
     */
    function _burnBatch(address from,
                        uint256[] memory ids,
                        uint256[] memory amounts) internal virtual { 
    }

    /**
     * @notice Sets the collection uri
     * @param collection_ Collection to change
     * @param newBase_ New base URI
     */
    function _setCollectionURI(uint256 collection_, string memory newBase_) internal {
        collectionBaseURI[collection_] = newBase_;
    }

    /**
     * @notice Sets the extension uri
     * @param collection_ Collection to change
     * @param newExt_ New extension
     */
    function _setExtensionURI(uint256 collection_, string memory newExt_) internal {
        collectionExtension[collection_] = newExt_;
    }

    /**
     * @notice Sets approval for all tokens to 'operator'
     * @param owner Owner of the tokens
     * @param operator 'Approved' to move tokens
     * @param approved If approved
     */
    function _setApprovalForAll(address owner,
                                address operator,
                                bool approved) internal virtual {
        require(owner != operator, 'E804');
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @notice Internal function of acceptance check
     * @param operator Who calls the function
     * @param from From account
     * @param to To account
     * @param id Collections
     * @param amount -> Tokens id to transfer
     * @param data Leave in blank
     */
    function _doSafeTransferAcceptanceCheck(address operator,
                                            address from,
                                            address to,
                                            uint256 id,
                                            uint256 amount,
                                            bytes memory data) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert('E808'); // not receiver
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert('E809'); // not implementer
            }
        }
    }

    /**
     * @notice Internal function of mint batch
     * @param operator Who calls the function
     * @param from From account
     * @param to To account
     * @param ids Collections
     * @param amounts -> Tokens id to transfer
     * @param data Leave in blank
     * @notice This implementation is deprecated
     */
    function _doSafeBatchTransferAcceptanceCheck(address operator,
                                                 address from,
                                                 address to,
                                                 uint256[] memory ids,
                                                 uint256[] memory amounts,
                                                 bytes memory data) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
                    revert('E808');
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert('E809');
            }
        }
    }

    /**
     * @notice Returns an element as a singleton
     * @param element The element
     * @return array A singleton array
     */
    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory array) {
        array = new uint256[](1);
        array[0] = element;
    }
    
    /**
     * @notice Returns the owner of token id
     * @param collection_ The collection
     * @param tokenId_ The token to ask
     * @return The address
     */
    function ownerOf(uint256 collection_, uint256 tokenId_) public view returns (address) {
        require(tokenId_ < totalSupplys[collection_], 'E801');
        address owner = _ownerships[collection_][tokenId_];
        return owner == address(0) ? collectionOwners[collection_] : owner;
    }

    /**
     * @notice Before token transfer hook
     * @param operator Who calls the function
     * @param from From account
     * @param to To account
     * @param ids Collection
     * @param amounts -> Token id to transfer
     * @param data Leave in blank
     */
    function _beforeTokenTransfer(address operator,
                                  address from,
                                  address to,
                                  uint256[] memory ids,
                                  uint256[] memory amounts,
                                  bytes memory data) internal virtual {
    }

    /**
     * @notice After token transfer hook
     * @param operator Who calls the function
     * @param from From account
     * @param to To account
     * @param ids Collection
     * @param amounts -> Token id to transfer
     * @param data Leave in blank
     */
    function _afterTokenTransfer(address operator,
                                 address from,
                                 address to,
                                 uint256[] memory ids,
                                 uint256[] memory amounts,
                                 bytes memory data) internal virtual {
    }
    
    /**
     * @notice Returns an array of the tokens of this user
     * @param owner Address
     * @param collection Collection
     * @return The array of tokens
     */
    function getTokensOfOwner(address owner, uint collection) public view returns (uint[] memory) {
        return ownerToToken[owner][collection];
    }
}

/**
 * @notice Implementation of collection separated by the ERC1155 id's
 * @dev This contract should keep only the createCollection function
 */
contract Collections is ERC1155, Utilities {
    /**
     * @notice Id of collection
     */
    uint256 public COLLECTION_ID;

    /**
     * @notice Roles contract
     */
    IRoles rolesContract;
    
    /**
     * @notice Roles module
     */
    address public roles;

    /**
     * @notice Saves a bool if the collection is verified
     */
    mapping(uint256 => bool) public isVerifiedCollection;

    /**
     * @notice Saves the collection creator
     */
    mapping(uint256 => address) public collectionCreators;

    /**
     * @notice Saves the names of the collections
     */
    mapping(string => bool) public usedNames;

    /**
     * @notice Fired when a collection changes URI
     * @param collection_ The collection changed
     */
    event ChangedCollectionURI(uint collection_);

    /**
     * @notice Fired when the extension is changed
     * @param collection_ The collection changed
     */
    event ChangedCollectionExtension(uint256 collection_);

    /**
     * @notice Collection created by a user / verified user
     * @param creator_ Who created the collection
     * @param collection_ The collection's id
     * @param id_ The hidden collection's id
     */
    event CreatedCollection(address indexed creator_, uint256 collection_, string id_);
    
    /**
     * @notice Collection verified by a moderator / admin
     * @param creator_ Who created the collection
     * @param collection_ The collection's id
     * @param isVerified_ Is verified ?
     */
    event CollectionVerified(address indexed creator_, uint256 collection_, bool isVerified_);

    /**
     * @notice Collection created by a user / verified user
     * @param collection_ The collection's id
     * @param amount_ Amount of tokens minted
     * @param id_ The hidden collection's id
     */
    event MintedToCollection(uint256 collection_, uint256 amount_, string id_);

    /**
     * @notice Restrict access for only the collection creator as caller
     * @param collection_ The collection id
     */
    modifier onlyCreator(uint256 collection_) {
        require(_msgSender() == collectionOwners[collection_], 'E810');
        _;
    }

    /**
     * @notice Builder
     */
    constructor (address module_) ERC1155() {
        IModule moduleManager = IModule(module_);
        roles = moduleManager.getModule(0);
        rolesContract = IRoles(roles);
    }

    /**
     * @notice Function to create collections (ERC1155 id's)
     * @param royalties_ Royalties for the creator
     * @param newName_ The name of the collection
     * @param newBase_ The base URI for the collection
     * @param newExtension_ The extension for the metadata
     * @param newId_ The hidden id of the collection
     * @dev It validates the name, the amount of tokens and the collection owner
     */
    function createCollection(uint256 royalties_,
                              string memory newName_,
                              string memory newBase_,
                              string memory newExtension_,
                              string memory newId_) public {
        require((rolesContract.isUser(msg.sender)) || (rolesContract.isVerifiedUser(msg.sender)), 'E811');
        require((!rolesContract.isVerifiedUser(msg.sender)) && (royalties_ == 0), 'E812');

        newName_ = Utilities.toUppercase(newName_);
        require(!usedNames[newName_], 'E813');
        
        collectionName     [COLLECTION_ID] = newName_;
        collectionBaseURI  [COLLECTION_ID] = newBase_;
        collectionCreators [COLLECTION_ID] = msg.sender;
        collectionOwners   [COLLECTION_ID] = msg.sender;
        collectionExtension[COLLECTION_ID] = newExtension_;
        usedNames[newName_] = true;

        emit CreatedCollection(msg.sender, COLLECTION_ID, newId_);
        COLLECTION_ID++;
    }

    /**
     * @notice Mints NFTs in existing collection
     * @param collection_ The collection
     * @param amount_ The amount of NFTs to mint
     * @dev Just the collection creator 
     */
    function mintNFTInCollection(uint256 collection_,
                                 uint256 amount_,
                                 string memory id_) public onlyCreator(collection_) {
        require(rolesContract.isUser(msg.sender) || rolesContract.isVerifiedUser(msg.sender), 'E811');
        require((amount_ > 0) && (collection_ < COLLECTION_ID), 'E814');

        balances[collection_][collectionOwners[collection_]] += amount_;
        totalSupplys[collection_] += amount_;

        emit MintedToCollection(collection_, amount_, id_);
    }

    /**
     * @notice Function to verify a collection (or not)
     * @param collection_ The collection id to verify or not
     * @param isVerified_ Bool if the collection is goint to be verified
     * @dev Only moderator function
     */
    function verifyCollection(uint256 collection_, bool isVerified_) public {
        require((rolesContract.isModerator(msg.sender)) && (rolesContract.isVerifiedUser(collectionOwners[collection_])), 'E815');
        isVerifiedCollection[collection_] = isVerified_;
        emit CollectionVerified(collectionOwners[collection_], collection_, isVerified_);
    }

    /**
     * @notice Set collection base URI
     * @param collection_ The collection id
     * @param newBase_ The string base URI to set
     * @dev Only users and verified users can call this function
     * @dev We could restrict this function to modify this one time
     */
    function setCollectionURI(uint256 collection_, string memory newBase_) public onlyCreator(collection_) {
        require(rolesContract.isUser(msg.sender), 'E811');
        _setCollectionURI(collection_, newBase_);
    }

    /**
     * @notice Set collection base URI extension
     * @param collection_ The collection id
     * @param newExt_ The string extension to set
     * @dev Only users and verified users can call this function
     * @dev We could restrict this function to modify this one time
     */
    function setExtensionURI(uint256 collection_, string memory newExt_) public onlyCreator(collection_) {
        require(rolesContract.isUser(msg.sender), 'E811');
        _setExtensionURI(collection_, newExt_);
    }

    /**
     * @notice Function to get token URI
     * @param collection_ The collection id
     * @param id_ The id of the token
     * @return base URI + tokenId + extension
     * @dev This function is public and view
     */
    function getTokenURI(uint256 collection_, uint256 id_) public view returns (string memory) {
        require(id_ < totalSupplys[collection_], 'E801');
        return string(abi.encodePacked(collectionBaseURI[collection_], toString(id_), collectionExtension[collection_]));
    }

}