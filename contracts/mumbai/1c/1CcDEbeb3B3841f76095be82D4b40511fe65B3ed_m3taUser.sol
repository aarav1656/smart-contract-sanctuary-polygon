//SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;
import "@openzeppelin/contracts/utils/Strings.sol";
import "@tableland/evm/contracts/ITablelandTables.sol";
import "@tableland/evm/contracts/utils/TablelandDeployments.sol";
import "./Ownable.sol";
import "./Im3taQuery.sol";
import "./IMockProfileCreationProxy.sol";
import "./ILensHub.sol";
// import "./IHumanCheck.sol";


contract m3taUser is Ownable
{
    // IHumanCheck private humanCheck;
    Im3taQuery private queryContract;
    IMockProfileCreationProxy private MockProfileCreationProxy;
    ILensHub private LensHub;
    ITablelandTables private _tableland;
    address M3taDaoAddress;

    mapping(address => uint256) _profileOwners;
    
    string private _chainID;
    string private _baseURIString;
    string private _profileTable;
    string private _profileTablePrefix;
    
    uint256 private _profileTableId;

    // constructor( Im3taQuery initqueryContract,IHumanCheck humancheckContract)  {
    constructor(Im3taQuery initqueryContract)  {


        queryContract = initqueryContract;
        //  humanCheck = humancheckContract;
        // Initializing the Lens Protocol Profile Creator to interact with
        MockProfileCreationProxy = IMockProfileCreationProxy(0x420f0257D43145bb002E69B14FF2Eb9630Fc4736);
        //  Initializing the main Lens Protocol Contract to get its state
        LensHub = ILensHub(0x60Ae865ee4C725cd04353b5AAb364553f56ceF82);

        // Creating the M3taUser Table
        _chainID = "80001";

        _tableland = TablelandDeployments.get();

        _profileTablePrefix = "M3taUser";

        _profileTableId = _tableland.createTable(
            address(this),
            queryContract.getCreateLensProfileTableStatement(_profileTablePrefix, _chainID)
        );

        _profileTable = string.concat(
            _profileTablePrefix,
            "_",
            _chainID,
            "_",
            Strings.toString(_profileTableId)
        );
        _baseURIString = "https://testnet.tableland.network/query?s=";
        
    }
    

    /**
     * @dev Only M3taDao contract can call
    */
    function onlyM3taDao() public view {
        require(msg.sender == address(M3taDaoAddress),"anothorized");
    }


    // Creates a Lens Profile and adds the Profile Data into M3taUser table for later indexing
    function createProfile(DataTypes.ProfileTableStruct memory vars)  external  {
        // With that modifier as a function we eliminate the callBack attack!
        onlyM3taDao();
        
        require(_profileOwners[vars.profile.to] == 0  , "Only one Profile per Address can get created");

        // calling Lens Proxy Profile Creator to create a new Profile for the User
        MockProfileCreationProxy.proxyCreateProfile(vars.profile);
        // Getting Profile Data
        vars.profile.handle = string.concat(vars.profile.handle,".test");
        // Connect the Profile ID with the ownerAddress to give him acccess in the m3taDao Dapp
        vars.tableData.profID = LensHub.getProfileIdByHandle(vars.profile.handle);
        // Used to index profile data using GraphQL 
        vars.tableData.profHex = Strings.toHexString(vars.tableData.profID);
        
        _profileOwners[vars.profile.to] = vars.tableData.profID;

        vars.tableData.metadataTable = _profileTable;
        
        // Writing the Profile Data into m3taUser Tableland Table to be used as the indexer
        writeTable(vars);
    }

    function writeTable(DataTypes.ProfileTableStruct memory vars) private {
            _tableland.runSQL(
            address(this),
            _profileTableId,
            // Getting the insert Profile statement from the Query Contract to add the profile into the Table
            queryContract.getProfileInsertStatement(vars)
        );    
    }

    function updateProfile(uint256 profileId, string calldata imageURI, string memory profileURI, string memory externalURIs) external {
        string memory imageuri = imageURI;
        require(_profileOwners[msg.sender] == profileId, "Anothorized action only profile owner can update his profile metadata");

        LensHub.setProfileImageURI(profileId, imageURI);

        updateTable(profileId,imageuri,profileURI,externalURIs);

    }

    function updateTable(uint256 profileId, string memory imageURI, string memory profileURI, string memory externalURIs) private {
            _tableland.runSQL(
            address(this),
            _profileTableId,
            queryContract.getUpdateLensProfileStatement(_profileTable,profileId,imageURI,profileURI,externalURIs)        
            );
    }

    function getProfIdByAddress(address owner) public view returns ( uint256){
        return _profileOwners[owner];
    }

    function _baseURI() internal view  returns (string memory) {
        return _baseURIString;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseURIString = baseURI;
    }

    function metadataURI() public view returns (string memory) {
        return queryContract.metadataURI(_profileTable,_baseURI());
    }

    function getTableName() public view returns ( string memory){
        return _profileTable;
    }

    function setM3taDaoAddress(address m3tadao) public onlyOwner{
        M3taDaoAddress = m3tadao; 
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
pragma solidity ^0.8.4;

import "./ITablelandController.sol";

/**
 * @dev Interface of a TablelandTables compliant contract.
 */
interface ITablelandTables {
    /**
     * The caller is not authorized.
     */
    error Unauthorized();

    /**
     * RunSQL was called with a query length greater than maximum allowed.
     */
    error MaxQuerySizeExceeded(uint256 querySize, uint256 maxQuerySize);

    /**
     * @dev Emitted when `owner` creates a new table.
     *
     * owner - the to-be owner of the table
     * tableId - the table id of the new table
     * statement - the SQL statement used to create the table
     */
    event CreateTable(address owner, uint256 tableId, string statement);

    /**
     * @dev Emitted when a table is transferred from `from` to `to`.
     *
     * Not emmitted when a table is created.
     * Also emitted after a table has been burned.
     *
     * from - the address that transfered the table
     * to - the address that received the table
     * tableId - the table id that was transferred
     */
    event TransferTable(address from, address to, uint256 tableId);

    /**
     * @dev Emitted when `caller` runs a SQL statement.
     *
     * caller - the address that is running the SQL statement
     * isOwner - whether or not the caller is the table owner
     * tableId - the id of the target table
     * statement - the SQL statement to run
     * policy - an object describing how `caller` can interact with the table (see {ITablelandController.Policy})
     */
    event RunSQL(
        address caller,
        bool isOwner,
        uint256 tableId,
        string statement,
        ITablelandController.Policy policy
    );

    /**
     * @dev Emitted when a table's controller is set.
     *
     * tableId - the id of the target table
     * controller - the address of the controller (EOA or contract)
     */
    event SetController(uint256 tableId, address controller);

    /**
     * @dev Creates a new table owned by `owner` using `statement` and returns its `tableId`.
     *
     * owner - the to-be owner of the new table
     * statement - the SQL statement used to create the table
     *
     * Requirements:
     *
     * - contract must be unpaused
     */
    function createTable(address owner, string memory statement)
        external
        payable
        returns (uint256);

    /**
     * @dev Runs a SQL statement for `caller` using `statement`.
     *
     * caller - the address that is running the SQL statement
     * tableId - the id of the target table
     * statement - the SQL statement to run
     *
     * Requirements:
     *
     * - contract must be unpaused
     * - `msg.sender` must be `caller` or contract owner
     * - `tableId` must exist
     * - `caller` must be authorized by the table controller
     * - `statement` must be less than or equal to 35000 bytes
     */
    function runSQL(
        address caller,
        uint256 tableId,
        string memory statement
    ) external payable;

    /**
     * @dev Sets the controller for a table. Controller can be an EOA or contract address.
     *
     * When a table is created, it's controller is set to the zero address, which means that the
     * contract will not enforce write access control. In this situation, validators will not accept
     * transactions from non-owners unless explicitly granted access with "GRANT" SQL statements.
     *
     * When a controller address is set for a table, validators assume write access control is
     * handled at the contract level, and will accept all transactions.
     *
     * You can unset a controller address for a table by setting it back to the zero address.
     * This will cause validators to revert back to honoring owner and GRANT bases write access control.
     *
     * caller - the address that is setting the controller
     * tableId - the id of the target table
     * controller - the address of the controller (EOA or contract)
     *
     * Requirements:
     *
     * - contract must be unpaused
     * - `msg.sender` must be `caller` and owner of `tableId`
     * - `tableId` must exist
     * - `tableId` controller must not be locked
     */
    function setController(
        address caller,
        uint256 tableId,
        address controller
    ) external;

    /**
     * @dev Returns the controller for a table.
     *
     * tableId - the id of the target table
     */
    function getController(uint256 tableId) external returns (address);

    /**
     * @dev Locks the controller for a table _forever_. Controller can be an EOA or contract address.
     *
     * Although not very useful, it is possible to lock a table controller that is set to the zero address.
     *
     * caller - the address that is locking the controller
     * tableId - the id of the target table
     *
     * Requirements:
     *
     * - contract must be unpaused
     * - `msg.sender` must be `caller` and owner of `tableId`
     * - `tableId` must exist
     * - `tableId` controller must not be locked
     */
    function lockController(address caller, uint256 tableId) external;

    /**
     * @dev Sets the contract base URI.
     *
     * baseURI - the new base URI
     *
     * Requirements:
     *
     * - `msg.sender` must be contract owner
     */
    function setBaseURI(string memory baseURI) external;

    /**
     * @dev Pauses the contract.
     *
     * Requirements:
     *
     * - `msg.sender` must be contract owner
     * - contract must be unpaused
     */
    function pause() external;

    /**
     * @dev Unpauses the contract.
     *
     * Requirements:
     *
     * - `msg.sender` must be contract owner
     * - contract must be paused
     */
    function unpause() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../ITablelandTables.sol";

/**
 * @dev Helper library for getting an instance of ITablelandTables for the currently executing EVM chain.
 */
library TablelandDeployments {
    /**
     * Current chain does not have a TablelandTables deployment.
     */
    error ChainNotSupported(uint256 chainid);

    // TablelandTables address on Ethereum Goerli.
    address internal constant GOERLI =
        0xDA8EA22d092307874f30A1F277D1388dca0BA97a;
    // TablelandTables address on Optimism Kovan.
    address internal constant OPTIMISTIC_KOVAN =
        0xf2C9Fc73884A9c6e6Db58778176Ab67989139D06;
    // TablelandTables address on Polygon Mumbai.
    address internal constant POLYGON_MUMBAI =
        0x4b48841d4b32C4650E4ABc117A03FE8B51f38F68;
    // TablelandTables address on for use with https://github.com/tablelandnetwork/local-tableland.
    address internal constant LOCAL_TABLELAND =
        0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512;

    /**
     * @dev Returns an interface to Tableland for the currently executing EVM chain.
     *
     * Requirements:
     *
     * - block.chainid must refer to a supported chain.
     */
    function get() internal view returns (ITablelandTables) {
        if (block.chainid == 5) {
            return ITablelandTables(GOERLI);
        } else if (block.chainid == 69) {
            return ITablelandTables(OPTIMISTIC_KOVAN);
        } else if (block.chainid == 80001) {
            return ITablelandTables(POLYGON_MUMBAI);
        } else if (block.chainid == 31337) {
            return ITablelandTables(LOCAL_TABLELAND);
        } else {
            revert ChainNotSupported(block.chainid);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "./utils/Context.sol";

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
pragma solidity ^0.8.12;
import "./DataTypes.sol";

interface Im3taQuery  {

    function getSubProjectInsertStatement(DataTypes.ProjectStruct memory vars)
    external pure returns (string memory);

    function getCreateValistReleaseTableStatement(string memory _tableprefix, string memory chainid) 
    external pure returns (string memory);

    function getReleaseInsertStatement(DataTypes.ReleaseStruct memory vars)
    external pure returns (string memory);

    function getCreateLensProfileTableStatement(string memory _tableprefix, string memory chainid)
    external pure returns (string memory);

    function getProfileInsertStatement(DataTypes.ProfileTableStruct memory vars)
    external pure returns (string memory);

     function getCreateValistSubProjectTableStatement(string memory _tableprefix, string memory chainid) 
     external pure returns (string memory);

    function getAccountInsertStatement(DataTypes.AccountStruct memory vars)
    external pure returns (string memory);

    function metadataURI(string memory metadataTable, string memory base) 
    external pure returns (string memory);
    
    function getCreateValistAccountTableStatement(string memory _tableprefix, string memory chainid) 
    external pure returns (string memory);

    function getPostInsertStatement(DataTypes.PostStruct memory vars)
    external pure returns (string memory);

    function getCreatePostTableStatement(string memory _tableprefix, string memory chainid)
    external pure returns (string memory);

    function getUpdateLensProfileStatement(string memory metadataTable, uint256 profID,  string memory imageURL,string memory profileURI, string memory externalURIs)
    external pure returns (string memory);

    function getUpdateAccountProjectStatement(string memory metadataTable, uint256 projectID,  string memory imageURL,string memory metaURI, string memory description)
    external pure returns (string memory);

    function getUpdateAccountStatement(string memory metadataTable, uint256 projectID,  string memory imageURL, string memory bannerURI, string memory metaURI, string memory description ,string memory requirements)
    external pure returns (string memory);

    function getDeletePostStatement(string memory metadataTable, uint256 postID)
    external pure returns (string memory);


}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "./DataTypes.sol";

/**
 * @title ILensHub
 * @author Lens Protocol
 *
 * @notice This is the interface for the LensHub contract, the main entry point for the Lens Protocol.
 * You'll find all the events and external functions, as well as the reasoning behind them here.
 */
interface IMockProfileCreationProxy {
    function proxyCreateProfile(DataTypes.CreateProfileData memory vars) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

/**
 * @title ILensHub
 * @author Lens Protocol
 *
 * @notice This is the interface for the LensHub contract, the main entry point for the Lens Protocol.
 * You'll find all the events and external functions, as well as the reasoning behind them here.
 */
interface ILensHub {
   
    function getProfileIdByHandle(string calldata handle) external view  returns (uint256);

   
   function setProfileImageURI(uint256 profileId, string calldata imageURI) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * @dev Interface of a TablelandController compliant contract.
 *
 * This interface can be implemented to enabled advanced access control for a table.
 * Call {ITablelandTables-setController} with the address of your implementation.
 *
 * See {test/TestTablelandController} for an example of token-gating table write-access.
 */
interface ITablelandController {
    /**
     * @dev Object defining how a table can be accessed.
     */
    struct Policy {
        // Whether or not the table should allow SQL INSERT statements.
        bool allowInsert;
        // Whether or not the table should allow SQL UPDATE statements.
        bool allowUpdate;
        // Whether or not the table should allow SQL DELETE statements.
        bool allowDelete;
        // A conditional clause used with SQL UPDATE and DELETE statements.
        // For example, a value of "foo > 0" will concatenate all SQL UPDATE
        // and/or DELETE statements with "WHERE foo > 0".
        // This can be useful for limiting how a table can be modified.
        // Use {Policies-joinClauses} to include more than one condition.
        string whereClause;
        // A conditional clause used with SQL INSERT statements.
        // For example, a value of "foo > 0" will concatenate all SQL INSERT
        // statements with a check on the incoming data, i.e., "CHECK (foo > 0)".
        // This can be useful for limiting how table data ban be added.
        // Use {Policies-joinClauses} to include more than one condition.
        string withCheck;
        // A list of SQL column names that can be updated.
        string[] updatableColumns;
    }

    /**
     * @dev Returns a {Policy} struct defining how a table can be accessed by `caller`.
     */
    function getPolicy(address caller) external payable returns (Policy memory);
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
pragma solidity 0.8.12;
/**
 * @title DataTypes
 * @author M3taDao & Lens Protocol
 *
 * @notice A standard library of data types used throughout the M3TADAO Protocol Which Combines Lens - Valist - Tableland - WorldCoin Contracts.
 */
library DataTypes {   

    struct AccountStruct 
    {
        address founderAddress;
        uint256 id;
        uint    accountID;
        string  accountHex;
        string  accountName;
        string  metaURI;
        string  AccountType;
        string  requirements;
        string  imageURI;
        string  bannerURI;
        string  metadataTable;
        string  description;
        address[] members;
    }
    
    struct ProjectStruct {
        address sender;
        uint256 id;
        uint256 accountID;
        uint256 projectID;
        string  metadataTable;
        string  projectHex;
        string  projectName;
        string  metaURI;
        string  projectType;
        string  imageURI;
        string  description;
        address[] members;
    }

    struct ReleaseStruct 
    {
        address sender;
        uint256 id;
        uint256 releaseID;
        uint256 projectID;
        string metadataTable;
        string releaseHex;
        string releaseName;
        string metaURI;
        string releaseType;
        string imageURI;
        string description;
        string releaseURI;
    }

    struct PostStruct
    {
        address posterAddress;
        uint256 postID;
        string  accountID;
        string  metadataTable;
        string  postDescription;    
        string  postTitle; 
        string  postGalery;
    }


    /**
     * @notice A struct containing the parameters required for the `createProfile()` function.
     *
     * @param to The address receiving the profile.
     * @param handle The handle to set for the profile, must be unique and non-empty.
     * @param imageURI The URI to set for the profile image.
     * @param followModule The follow module to use, can be the zero address.
     * @param followModuleInitData The follow module initialization data, if any.
     * @param followNFTURI The URI to use for the follow NFT.
     */
    struct CreateProfileData 
    {
        address to;
        string handle;
        string imageURI;
        address followModule;
        bytes followModuleInitData;
        string followNFTURI;
    }

    struct ProfTableStruct
    {
        string metadataTable;
        uint256 profID;
        string profHex;
        string description;
        string externalURIs;
        string profileURI;
        
    }

    struct ProfileTableStruct
    {
        CreateProfileData profile;
        ProfTableStruct tableData;
    }

    struct ProfileTableStruct2
    {
        CreateProfileData profile;
        ProfTableStruct2 tableData;
    }

    struct ProfTableStruct2{
        string metadataTable;
        uint256 profID;
        string description;
        string groupID;
        string profileURI;
        uint256 root;
        uint256 nullifierHash;
    }
}