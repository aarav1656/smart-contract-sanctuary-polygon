// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.7;
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import { IERC1155ReceiverUpgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155ReceiverUpgradeable.sol";
import { IObject } from "./interfaces/IObject.sol";
import "./utils/Strings.sol";

contract PhiMap is AccessControlUpgradeable, IERC1155ReceiverUpgradeable {
    /* --------------------------------- ****** --------------------------------- */

    /* -------------------------------------------------------------------------- */
    /*                                   CONFIG                                   */
    /* -------------------------------------------------------------------------- */
    /* ---------------------------------- Map ----------------------------------- */
    MapSettings public mapSettings;
    struct MapSettings {
        uint256 minX;
        uint256 maxX;
        uint256 minY;
        uint256 maxY;
    }
    /* --------------------------------- WallPaper ------------------------------ */
    struct WallPaper {
        address contractAddress;
        uint256 tokenId;
        uint256 timestamp;
    }
    /* --------------------------------- OBJECT --------------------------------- */
    struct Size {
        uint8 x;
        uint8 y;
        uint8 z;
    }
    struct Object {
        address contractAddress;
        uint256 tokenId;
        uint256 xStart;
        uint256 yStart;
    }
    struct ObjectInfo {
        address contractAddress;
        uint256 tokenId;
        uint256 xStart;
        uint256 yStart;
        uint256 xEnd;
        uint256 yEnd;
        Link link;
    }
    /* --------------------------------- DEPOSIT -------------------------------- */
    struct Deposit {
        address contractAddress;
        uint256 tokenId;
    }
    struct DepositInfo {
        address contractAddress;
        uint256 tokenId;
        uint256 amount;
        uint256 used;
        uint256 timestamp;
    }
    /* --------------------------------- LINK ----------------------------------- */
    struct Link {
        string title;
        string url;
    }
    /* --------------------------------- ****** --------------------------------- */

    /* -------------------------------------------------------------------------- */
    /*                                   STORAGE                                  */
    /* -------------------------------------------------------------------------- */
    /* ---------------------------------- Map ----------------------------------- */
    uint256 public numberOfLand;
    mapping(string => address) public ownerLists;
    /* --------------------------------- WallPaper ------------------------------ */
    /* --------------------------------- OBJECT --------------------------------- */
    uint256 public numberOfObject;
    mapping(string => ObjectInfo[]) public userObject;
    /* --------------------------------- WallPaper ------------------------------ */
    mapping(string => WallPaper) public wallPaper;
    /* --------------------------------- DEPOSIT -------------------------------- */
    mapping(string => Deposit[]) public userObjectDeposit;
    mapping(string => mapping(address => mapping(uint256 => DepositInfo))) public depositInfo;
    mapping(string => mapping(address => mapping(uint256 => uint256))) public depositTime;
    /* --------------------------------- LINK ----------------------------------- */

    /* --------------------------------- ****** --------------------------------- */

    /* -------------------------------------------------------------------------- */
    /*                                   EVENTS                                   */
    /* -------------------------------------------------------------------------- */
    event Hello();
    /* ---------------------------------- Map ----------------------------------- */
    event CreatedMap(string name, address indexed sender, uint256 numberOfLand);
    event ChangePhilandOwner(string name, address indexed sender);
    /* --------------------------------- WallPaper ------------------------------ */
    event ChangeWallPaper(string name, address contractAddress, uint256 tokenId);
    /* --------------------------------- OBJECT --------------------------------- */
    event WriteObject(string name, address contractAddress, uint256 tokenId, uint256 xStart, uint256 yStart);
    event RemoveObject(string name, uint256 index);
    event MapInitialization(string iname, address indexed sender);
    event Save(string name, address indexed sender);
    /* --------------------------------- DEPOSIT -------------------------------- */
    event DepositSuccess(address indexed sender, string name, address contractAddress, uint256 tokenId, uint256 amount);
    event WithdrawSuccess(
        address indexed sender,
        string name,
        address contractAddress,
        uint256 tokenId,
        uint256 amount
    );
    /* ---------------------------------- LINK ---------------------------------- */
    event WriteLink(string name, address contractAddress, uint256 tokenId, string title, string url);
    event RemoveLink(string name, uint256 index);
    /* --------------------------------- ****** --------------------------------- */

    /* -------------------------------------------------------------------------- */
    /*                                   ERRORS                                   */
    /* -------------------------------------------------------------------------- */
    error NotAdminCall(address sender);
    /* ---------------------------------- Map ----------------------------------- */
    error NotReadyPhiland(address sender, address owner);
    error NotPhilandOwner(address sender, address owner);
    error NotDepositEnough(string name, address contractAddress, uint256 tokenId, uint256 used, uint256 amount);
    error OutofMapRange(uint256 a, string error_boader);
    error ObjectCollision(ObjectInfo writeObjectInfo, ObjectInfo userObjectInfo, string error_boader);
    /* --------------------------------- WallPaper ------------------------------ */
    error NotFitWallPaper(address sender, uint256 sizeX, uint256 sizeY, uint256 mapSizeX, uint256 mapSizeY);
    error NotBalanceWallPaper(string name, address sender, address contractAddress, uint256 tokenId);
    /* --------------------------------- OBJECT --------------------------------- */
    error NotReadyObject(address sender, uint256 object_index);
    /* --------------------------------- DEPOSIT -------------------------------- */
    error NotDeposit(address sender, address owner, uint256 token_id);
    error NotBalanceEnough(
        string name,
        address sender,
        address contractAddress,
        uint256 tokenId,
        uint256 currentDepositAmount,
        uint256 currentDepositUsed,
        uint256 updateDepositAmount,
        uint256 userBalance
    );
    error withdrawError(uint256 amount, uint256 mapUnUsedBalance);

    /* ---------------------------------- LINK ---------------------------------- */

    /* --------------------------------- ****** --------------------------------- */

    /* -------------------------------------------------------------------------- */
    /*                               INITIALIZATION                               */
    /* -------------------------------------------------------------------------- */
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize(address admin) public initializer {
        numberOfLand = 0;
        numberOfObject = 0;
        mapSettings = MapSettings(0, 16, 0, 16);
        __AccessControl_init();
        _setupRole(DEFAULT_ADMIN_ROLE, admin);
    }

    /* --------------------------------- ****** --------------------------------- */

    /* -------------------------------------------------------------------------- */
    /*                                  MODIFIERS                                 */
    /* -------------------------------------------------------------------------- */
    modifier onlyIfNotOnwer() {
        if (!hasRole(DEFAULT_ADMIN_ROLE, msg.sender)) {
            revert NotAdminCall({ sender: msg.sender });
        }
        _;
    }

    modifier onlyIfNotPhilandCreated(string memory name) {
        address owner = ownerOfPhiland(name);
        if (owner == address(0)) {
            revert NotReadyPhiland({ sender: msg.sender, owner: owner });
        }
        _;
    }

    modifier onlyIfNotPhilandOwner(string memory name) {
        address owner = ownerOfPhiland(name);
        if (owner != msg.sender) {
            revert NotPhilandOwner({ sender: msg.sender, owner: owner });
        }
        _;
    }

    modifier onlyIfNotDepositObject(string memory name, Object memory objectData) {
        address owner = ownerOfPhiland(name);
        if (depositInfo[name][objectData.contractAddress][objectData.tokenId].amount == 0) {
            revert NotDeposit({ sender: msg.sender, owner: owner, token_id: objectData.tokenId });
        }
        _;
    }

    modifier onlyIfNotReadyObject(string memory name, uint256 object_index) {
        address owner = ownerOfPhiland(name);
        if (userObject[name][object_index].contractAddress == address(0)) {
            revert NotReadyObject({ sender: msg.sender, object_index: object_index });
        }
        _;
    }

    /* --------------------------------- ****** --------------------------------- */

    /* -------------------------------------------------------------------------- */
    /*                                     Map                                    */
    /* -------------------------------------------------------------------------- */
    /* ---------------------------------- ADMIN --------------------------------- */
    /*
     * @title create
     * @notice Receive create map Message from PhiRegistry
     * @param name : ens name
     * @param caller : Address of the owner of the ens
     * @dev Basically only execution from phi registry contract
     */
    function create(string memory name, address caller) external onlyIfNotOnwer {
        ownerLists[name] = caller;
        unchecked {
            numberOfLand++;
        }
        emit CreatedMap(name, caller, numberOfLand);
    }

    /*
     * @title changePhilandOwner
     * @notice Receive change map owner message from PhiRegistry
     * @param name : Ens name
     * @param caller : Address of the owner of the ens
     * @dev Basically only execution from phi registry contract
     */
    function changePhilandOwner(string memory name, address caller)
        external
        onlyIfNotOnwer
        onlyIfNotPhilandCreated(name)
    {
        ownerLists[name] = caller;
        emit ChangePhilandOwner(name, caller);
    }

    /* --------------------------------- WallPaper ------------------------------ */
    /*
     * @title checkWallPaper
     * @notice Functions for check WallPaper status for specific token
     * @param name : Ens name
     * @dev Check WallPaper information
     */
    function checkWallPaper(string memory name) external view returns (WallPaper memory) {
        return wallPaper[name];
    }

    /*
     * @title withdrawWallPaper
     * @notice withdrawWallPaper
     * @param name : Ens name
     * @param _contractAddress : Address of Wallpaper
     * @param _tokenId : _tokenId
     */
    function withdrawWallPaper(string memory name) public onlyIfNotPhilandOwner(name) onlyIfNotPhilandCreated(name) {
        address lastWallPaperContractAddress = wallPaper[name].contractAddress;
        uint256 lastWallPaperTokenId = wallPaper[name].tokenId;
        if (lastWallPaperContractAddress != address(0)) {
            IObject _lastWallPaper = IObject(lastWallPaperContractAddress);
            _lastWallPaper.safeTransferFrom(address(this), msg.sender, lastWallPaperTokenId, 1, "0x00");
        }
        wallPaper[name] = WallPaper(address(0), 0, block.timestamp);
    }

    /*
     * @title changeWallPaper
     * @notice Receive changeWallPaper
     * @param name : Ens name
     * @param _contractAddress : Address of Wallpaper
     * @param _tokenId : _tokenId
     */
    function changeWallPaper(
        string memory name,
        address contractAddress,
        uint256 tokenId
    ) public onlyIfNotPhilandOwner(name) onlyIfNotPhilandCreated(name) {
        address lastWallPaperContractAddress = wallPaper[name].contractAddress;
        uint256 lastWallPaperTokenId = wallPaper[name].tokenId;
        if (lastWallPaperContractAddress != address(0)) {
            IObject _lastWallPaper = IObject(lastWallPaperContractAddress);
            _lastWallPaper.safeTransferFrom(address(this), msg.sender, lastWallPaperTokenId, 1, "0x00");
        }
        IObject _object = IObject(contractAddress);
        IObject.Size memory size = _object.getSize(tokenId);
        if ((size.x != mapSettings.maxX) || (size.y != mapSettings.maxY)) {
            revert NotFitWallPaper(msg.sender, size.x, size.y, mapSettings.maxX, mapSettings.maxY);
        }

        uint256 userBalance = _object.balanceOf(msg.sender, tokenId);
        if (userBalance < 1) {
            revert NotBalanceWallPaper({
                name: name,
                sender: msg.sender,
                contractAddress: contractAddress,
                tokenId: tokenId
            });
        }
        wallPaper[name] = WallPaper(contractAddress, tokenId, block.timestamp);

        _object.safeTransferFrom(msg.sender, address(this), tokenId, 1, "0x00");
        emit ChangeWallPaper(name, contractAddress, tokenId);
    }

    /* ----------------------------------- VIEW --------------------------------- */
    /*
     * @title ownerOfPhiland
     * @notice Return philand owner address
     * @param name : Ens name
     * @dev check that the user has already claimed Philand
     */
    function ownerOfPhiland(string memory name) public view returns (address) {
        if (ownerLists[name] != address(0)) return ownerLists[name];
        else return address(0);
    }

    /*
     * @title viewPhiland
     * @notice Return philand object
     * @param name : Ens name
     * @dev List of objects written to map contract. Deleted Object is contract address == 0
     */
    function viewPhiland(string memory name) external view returns (ObjectInfo[] memory) {
        return userObject[name];
    }

    /*
     * @title viewNumberOfPhiland
     * @notice Return number of philand
     */
    function viewNumberOfPhiland() external view returns (uint256) {
        return numberOfLand;
    }

    /*
     * @title viewNumberOfObject
     * @notice Return number of philand
     */
    function viewNumberOfObject() external view returns (uint256) {
        return numberOfObject;
    }

    /*
     * @title viewviewPhilandArray
     * @notice Return array of philand
     */
    function viewPhilandArray(string memory name)
        external
        view
        onlyIfNotPhilandCreated(name)
        returns (uint256[] memory)
    {
        uint256 sizeX = mapSettings.maxX;
        uint256 sizeY = mapSettings.maxY;
        uint256[] memory philandArray = new uint256[](sizeX * sizeY);
        for (uint256 i = 0; i < userObject[name].length; i++) {
            if (userObject[name][i].contractAddress != address(0)) {
                uint256 xStart = userObject[name][i].xStart;
                uint256 xEnd = userObject[name][i].xEnd;
                uint256 yStart = userObject[name][i].yStart;
                uint256 yEnd = userObject[name][i].yEnd;

                for (uint256 x = xStart; x < xEnd; x++) {
                    for (uint256 y = yStart; y < yEnd; y++) {
                        philandArray[x + 16 * y] = 1;
                    }
                }
            }
        }
        return philandArray;
    }

    /* ----------------------------------- WRITE -------------------------------- */
    /*
     * @title writeObjectToLand
     * @notice Return philand object
     * @param name : Ens name
     * @param objectData : Object (address contractAddress,uint256 tokenId, uint256 xStart, uint256 yStart)
     * @param link : Link (stirng title, string url)
     * @dev NFT must be deposited in the contract before writing.
     */
    function writeObjectToLand(
        string memory name,
        Object memory objectData,
        Link memory link
    ) public onlyIfNotPhilandOwner(name) onlyIfNotDepositObject(name, objectData) {
        // Check the number of deposit NFTs to write object
        checkDepositAvailable(name, objectData.contractAddress, objectData.tokenId);
        depositInfo[name][objectData.contractAddress][objectData.tokenId].used++;

        IObject _object = IObject(objectData.contractAddress);
        // Object contract requires getSize functions for x,y,z
        IObject.Size memory size = _object.getSize(objectData.tokenId);
        ObjectInfo memory writeObjectInfo = ObjectInfo(
            objectData.contractAddress,
            objectData.tokenId,
            objectData.xStart,
            objectData.yStart,
            objectData.xStart + size.x,
            objectData.yStart + size.y,
            link
        );

        // Check the write Object do not collide with previous written objects
        checkCollision(name, writeObjectInfo);
        userObject[name].push(writeObjectInfo);

        unchecked {
            numberOfObject++;
        }
        emit WriteObject(name, objectData.contractAddress, objectData.tokenId, objectData.xStart, objectData.yStart);
        emit WriteLink(name, objectData.contractAddress, objectData.tokenId, link.title, link.url);
    }

    /*
     * @title batchWriteObjectToLand
     * @notice batch write function
     * @param name : Ens name
     * @param objectData : Array of Object struct (address contractAddress, uint256 tokenId, uint256 xStart, uint256 yStart)
     * @param links : Array of Link struct(stirng title, string url)
     * @dev NFT must be deposited in the contract before writing. Object contract requires getSize functions for x,y,z
     */
    function batchWriteObjectToLand(
        string memory name,
        Object[] memory objectData,
        Link[] memory link
    ) public {
        for (uint256 i = 0; i < objectData.length; i++) {
            writeObjectToLand(name, objectData[i], link[i]);
        }
    }

    /* ----------------------------------- REMOVE -------------------------------- */
    /*
     * @title removeObjectFromLand
     * @notice remove object from philand
     * @param name : Ens name
     * @param index : Object index
     * @dev When deleting an object, link information is deleted at the same time.
     */
    function removeObjectFromLand(string memory name, uint256 index)
        public
        onlyIfNotPhilandCreated(name)
        onlyIfNotPhilandOwner(name)
    {
        ObjectInfo memory depositItem = userObject[name][index];
        depositInfo[name][depositItem.contractAddress][depositItem.tokenId].used =
            depositInfo[name][depositItem.contractAddress][depositItem.tokenId].used -
            1;
        delete userObject[name][index];
        emit RemoveObject(name, index);
        unchecked {
            numberOfObject--;
        }
    }

    /*
     * @title batchRemoveObjectFromLand
     * @notice batch remove objects from philand
     * @param name : Ens name
     * @param index : Array of Object index
     * @dev When deleting an object, link information is deleted at the same time.
     */
    function batchRemoveObjectFromLand(string memory name, uint256[] memory indexArray) public {
        for (uint256 i = 0; i < indexArray.length; i++) {
            removeObjectFromLand(name, indexArray[i]);
        }
    }

    /* -------------------------------- WRITE/REMOVE ----------------------------- */
    /*
     * @title batchRemoveAndWrite
     * @notice Function for save to be executed after editing
     * @param name : Ens name
     * @param remove_index_array : Array of Object index
     * @param objectDatas : Array of Object struct (address contractAddress, uint256 tokenId, uint256 xStart, uint256 yStart)
     * @param links : Array of Link (stirng title, string url)
     * @dev This function cannot set links at the same time.
     */
    function batchRemoveAndWrite(
        string memory name,
        uint256[] memory removeIndexArray,
        bool removeCheck,
        Object[] memory objectDatas,
        Link[] memory links
    ) public {
        if (removeCheck) {
            batchRemoveObjectFromLand(name, removeIndexArray);
        }
        batchWriteObjectToLand(name, objectDatas, links);
    }

    /* -------------------------------- INITIALIZATION -------------------------- */
    /*
     * @title initialization
     * @notice Function for clear users map objects and links
     * @param name : Ens name
     * @dev [Carefully] This function init objects and links
     */
    function mapInitialization(string memory name) external onlyIfNotPhilandCreated(name) onlyIfNotPhilandOwner(name) {
        uint256 objectLength = userObject[name].length;
        for (uint256 i = 0; i < objectLength; i++) {
            if (userObject[name][i].contractAddress != address(0)) {
                removeObjectFromLand(name, i);
            }
        }
        for (uint256 i = 0; i < objectLength; i++) {
            userObject[name].pop();
        }
        emit MapInitialization(name, msg.sender);
    }

    /* ------------------------------------ SAVE -------------------------------- */
    /*
     * @title initialization
     * @notice Function for clear users map objects and links
     * @param name : Ens name
     * @param remove_check : if remove_check == 0 then remove is skipped
     * @param remove_index_array : Array of Object index
     * @param objectData : Array of Object struct (address contractAddress, uint256 tokenId, uint256 xStart, uint256 yStart)
     * @param link : Array of Link struct(stirng title, string url)
     * @param change_wall_check : if change_wall_check ==  o then wallchange is skipped
     * @param _contractAddress : if you dont use, should be 0
     * @param _tokenId : if you dont use, should be 0
     * @dev  Write Link method can also usefull for remove link
     */
    function save(
        string memory name,
        uint256[] memory removeIndexArray,
        bool removeCheck,
        Object[] memory objectDatas,
        Link[] memory links,
        bool changeWallCheck,
        address contractAddress,
        uint256 tokenId
    ) external onlyIfNotPhilandCreated(name) onlyIfNotPhilandOwner(name) {
        batchRemoveAndWrite(name, removeIndexArray, removeCheck, objectDatas, links);
        if (changeWallCheck) {
            changeWallPaper(name, contractAddress, tokenId);
        }
        emit Save(name, msg.sender);
    }

    /* ----------------------------------- INTERNAL ------------------------------ */
    /*
     * @title checkCollision
     * @notice Functions for collision detection
     * @param name : Ens name
     * @param writeObjectInfo : Information about the object you want to write.
     * @dev execute when writing an object.
     */
    function checkCollision(string memory name, ObjectInfo memory writeObjectInfo) private view {
        // fails if writing object is out of range of map
        if (writeObjectInfo.xStart < mapSettings.minX || writeObjectInfo.xStart > mapSettings.maxX) {
            revert OutofMapRange({ a: writeObjectInfo.xStart, error_boader: "invalid xStart" });
        }
        if (writeObjectInfo.xEnd < mapSettings.minX || writeObjectInfo.xEnd > mapSettings.maxX) {
            revert OutofMapRange({ a: writeObjectInfo.xEnd, error_boader: "invalid xEnd" });
        }
        if (writeObjectInfo.yStart < mapSettings.minY || writeObjectInfo.yStart > mapSettings.maxY) {
            revert OutofMapRange({ a: writeObjectInfo.yStart, error_boader: "invalid yStart" });
        }
        if (writeObjectInfo.yEnd < mapSettings.minY || writeObjectInfo.yEnd > mapSettings.maxY) {
            revert OutofMapRange({ a: writeObjectInfo.yEnd, error_boader: "invalid yEnd" });
        }

        if (userObject[name].length == 0) {
            return;
        }

        for (uint256 i = 0; i < userObject[name].length; i++) {
            // Skip if already deleted
            if (userObject[name][i].contractAddress == address(0)) {
                continue;
            }
            // Rectangular objects do not collide when any of the following four conditions are satisfied
            if (
                writeObjectInfo.xEnd <= userObject[name][i].xStart ||
                userObject[name][i].xEnd <= writeObjectInfo.xStart ||
                writeObjectInfo.yEnd <= userObject[name][i].yStart ||
                userObject[name][i].yEnd <= writeObjectInfo.yStart
            ) {
                continue;
            } else {
                revert ObjectCollision({
                    writeObjectInfo: writeObjectInfo,
                    userObjectInfo: userObject[name][i],
                    error_boader: "invalid objectInfo"
                });
            }
        }
        return;
    }

    /* -------------------------------------------------------------------------- */
    /*                                   DEPOSIT                                  */
    /* -------------------------------------------------------------------------- */
    /* ---------------------------------- VIEW ---------------------------------- */
    /*
     * @title checkDepositAvailable
     * @notice Functions for collision detection
     * @param name : Ens name
     * @param contractAddress : contractAddress
     * @paramtokenId : tokenId
     * @dev Check the number of deposit NFTs to write object
     */
    function checkDepositAvailable(
        string memory name,
        address contractAddress,
        uint256 tokenId
    ) private view {
        if (depositInfo[name][contractAddress][tokenId].used + 1 > depositInfo[name][contractAddress][tokenId].amount) {
            revert NotDepositEnough(
                name,
                contractAddress,
                tokenId,
                depositInfo[name][contractAddress][tokenId].used,
                depositInfo[name][contractAddress][tokenId].amount
            );
        }
        return;
    }

    /*
     * @title checkDepositStatus
     * @notice Functions for check deposit status for specific token
     * @param name : Ens name
     * @param _contractAddress : contract address you want to check
     * @param _tokenId : token id you want to check
     * @dev Check deposit information
     */
    function checkDepositStatus(
        string memory name,
        address contractAddress,
        uint256 tokenId
    ) public view returns (DepositInfo memory) {
        return depositInfo[name][contractAddress][tokenId];
    }

    /*
     * @title checkAllDepositStatus
     * @notice Functions for check deposit status for all token
     * @param name : Ens name
     * @dev Check users' all deposit information
     */
    function checkAllDepositStatus(string memory name) public view returns (DepositInfo[] memory) {
        DepositInfo[] memory deposits = new DepositInfo[](userObjectDeposit[name].length);
        for (uint256 i = 0; i < userObjectDeposit[name].length; i++) {
            Deposit memory depositObjectInfo = userObjectDeposit[name][i];
            DepositInfo memory tempItem = depositInfo[name][depositObjectInfo.contractAddress][
                depositObjectInfo.tokenId
            ];
            deposits[i] = tempItem;
        }
        return deposits;
    }

    /* --------------------------------- DEPOSIT -------------------------------- */
    /*
     * @title deposit
     * @notice Functions for deposit token to this(map) contract
     * @param name : Ens name
     * @param _contractAddress : deposit contract address
     * @param _tokenId : deposit token id
     * @param _amount : deposit amount
     * @dev Need approve. With deposit, ENS transfer allows user to transfer philand with token.
     */
    function deposit(
        string memory name,
        address contractAddress,
        uint256 tokenId,
        uint256 amount
    ) public onlyIfNotPhilandOwner(name) {
        uint256 currentDepositAmount = depositInfo[name][contractAddress][tokenId].amount;
        uint256 updateDepositAmount = currentDepositAmount + amount;
        uint256 currentDepositUsed = depositInfo[name][contractAddress][tokenId].used;

        IObject _object = IObject(contractAddress);
        uint256 userBalance = _object.balanceOf(msg.sender, tokenId);
        if (userBalance < updateDepositAmount - currentDepositAmount) {
            revert NotBalanceEnough({
                name: name,
                sender: msg.sender,
                contractAddress: contractAddress,
                tokenId: tokenId,
                currentDepositAmount: currentDepositAmount,
                currentDepositUsed: currentDepositUsed,
                updateDepositAmount: updateDepositAmount,
                userBalance: userBalance
            });
        }
        depositInfo[name][contractAddress][tokenId] = DepositInfo(
            contractAddress,
            tokenId,
            updateDepositAmount,
            currentDepositUsed,
            block.timestamp
        );

        // Maintain a list of deposited contract addresses and token ids for checkAllDepositStatus.
        Deposit memory depositObjectInfo = Deposit(contractAddress, tokenId);
        bool check = false;
        for (uint256 i = 0; i < userObjectDeposit[name].length; i++) {
            Deposit memory depositObjectToken = userObjectDeposit[name][i];
            if (depositObjectToken.contractAddress == contractAddress && depositObjectToken.tokenId == tokenId) {
                check = true;
                break;
            }
        }
        if (!check) {
            userObjectDeposit[name].push(depositObjectInfo);
        }

        _object.safeTransferFrom(msg.sender, address(this), tokenId, amount, "0x00");
        emit DepositSuccess(msg.sender, name, contractAddress, tokenId, amount);
    }

    /*
     * @title batchDeposit
     * @notice Functions for batch deposit tokens to this(map) contract
     * @param name : Ens name
     * @param _contractAddresses : array of deposit contract addresses
     * @param _tokenIds :  array of deposit token ids
     * @param _amounts :  array of deposit amounts
     */
    function batchDeposit(
        string memory name,
        address[] memory contractAddresses,
        uint256[] memory tokenIds,
        uint256[] memory amounts
    ) public onlyIfNotPhilandOwner(name) {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            deposit(name, contractAddresses[i], tokenIds[i], amounts[i]);
        }
    }

    /* --------------------------------- withdraw ------------------------------ */
    /*
     * @title withdraw
     * @notice Functions for deposit token from this(map) contract
     * @param name : Ens name
     * @param _contractAddress : deposit contract address
     * @param _tokenId : deposit token id
     * @param _amount : deposit amount
     * @dev Return ERROR when attempting to withdraw over unused
     */
    function withdraw(
        string memory name,
        address contractAddress,
        uint256 tokenId,
        uint256 amount
    ) public onlyIfNotPhilandOwner(name) {
        uint256 used = depositInfo[name][contractAddress][tokenId].used;
        uint256 mapUnusedAmount = depositInfo[name][contractAddress][tokenId].amount - used;
        if (amount > mapUnusedAmount) {
            revert withdrawError(amount, mapUnusedAmount);
        }
        IObject _object = IObject(contractAddress);

        depositTime[name][contractAddress][tokenId] += (block.timestamp -
            depositInfo[name][contractAddress][tokenId].timestamp);
        depositInfo[name][contractAddress][tokenId].amount =
            depositInfo[name][contractAddress][tokenId].amount -
            amount;
        _object.safeTransferFrom(address(this), msg.sender, tokenId, amount, "0x00");
        emit WithdrawSuccess(msg.sender, name, contractAddress, tokenId, amount);
    }

    /*
     * @title batchWithdraw
     * @notice Functions for batch withdraw tokens from this(map) contract
     * @param name : Ens name
     * @param _contractAddresses : array of deposit contract addresses
     * @param _tokenIds :  array of deposit token ids
     * @param _amounts :  array of deposit amounts
     */
    function batchWithdraw(
        string memory name,
        address[] memory contractAddresses,
        uint256[] memory tokenIds,
        uint256[] memory amounts
    ) public onlyIfNotPhilandOwner(name) {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            withdraw(name, contractAddresses[i], tokenIds[i], amounts[i]);
        }
    }

    /* ----------------------------------- RECEIVE ------------------------------ */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external pure returns (bytes4) {
        return bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));
    }

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] memory ids,
        uint256[] memory values,
        bytes calldata data
    ) external pure returns (bytes4) {
        return bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"));
    }

    /* -------------------------------------------------------------------------- */
    /*                                    LINK                                    */
    /* -------------------------------------------------------------------------- */
    /* ---------------------------------- VIEW ---------------------------------- */
    /*
     * @title viewObjectLink
     * @notice Functions for check link status for specificed object
     * @param name : Ens name
     * @param object_index : object_index you want to check
     * @dev Check link information
     */
    function viewObjectLink(string memory name, uint256 objectIndex) external view returns (Link memory) {
        return userObject[name][objectIndex].link;
    }

    /*
     * @title viewLinks
     * @notice Functions for check all link status
     * @param name : Ens name
     * @dev Check all link information
     */
    function viewLinks(string memory name) external view returns (Link[] memory) {
        Link[] memory links = new Link[](userObject[name].length);
        for (uint256 i = 0; i < userObject[name].length; i++) {
            links[i] = userObject[name][i].link;
        }
        return links;
    }

    /* ---------------------------------- WRITE --------------------------------- */
    /*
     * @title writeLinkToObject
     * @notice Functions for write link
     * @param name : Ens name
     * @param object_index : object index
     * @param link : Link struct(stirng title, string url)
     * @dev Check all link information
     */
    function writeLinkToObject(
        string memory name,
        uint256 objectIndex,
        Link memory link
    ) public onlyIfNotPhilandCreated(name) onlyIfNotPhilandOwner(name) onlyIfNotReadyObject(name, objectIndex) {
        userObject[name][objectIndex].link = link;
        emit WriteLink(
            name,
            userObject[name][objectIndex].contractAddress,
            userObject[name][objectIndex].tokenId,
            link.title,
            link.url
        );
    }

    /*
     * @title batchWriteLinkToObject
     * @notice Functions for write link
     * @param name : Ens name
     * @param object_indexes : array of object index
     * @param links : Array of Link struct(stirng title, string url)
     * @dev Check all link information
     */
    function batchWriteLinkToObject(
        string memory name,
        uint256[] memory objectIndexes,
        Link[] memory links
    ) public onlyIfNotPhilandCreated(name) onlyIfNotPhilandOwner(name) {
        for (uint256 i = 0; i < objectIndexes.length; i++) {
            writeLinkToObject(name, objectIndexes[i], links[i]);
        }
    }

    /* ---------------------------------- REMOVE --------------------------------- */
    /*
     * @title removeLinkFromObject
     * @notice Functions for remove link
     * @param name : Ens name
     * @param object_index : object index
     * @dev delete link information
     */
    function removeLinkFromObject(string memory name, uint256 objectIndex) external onlyIfNotPhilandOwner(name) {
        userObject[name][objectIndex].link = Link("", "");
        emit RemoveLink(name, objectIndex);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal onlyInitializing {
    }

    function __AccessControl_init_unchained() internal onlyInitializing {
    }
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

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
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        StringsUpgradeable.toHexString(uint160(account), 20),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
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
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

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
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155ReceiverUpgradeable is IERC165Upgradeable {
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.7;

interface IObject {
    struct Size {
        uint8 x;
        uint8 y;
        uint8 z;
    }
    // define object struct
    struct Objects {
        string tokenURI;
        Size size;
        address payable creator;
        uint256 maxClaimed;
        uint256 price;
        bool forSale;
    }

    function getSize(uint256 tokenId) external view returns (Size memory);

    function balanceOf(address account, uint256 id) external view returns (uint256);

    function setOwner(address newOwner) external;

    function isApprovedForAll(address account, address operator) external returns (bool);

    function setApprovalForAll(address operator, bool approved) external;

    function mintBatchObject(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external;
}

/*
 * @title String & slice utility library for Solidity contracts.
 * @author Nick Johnson <[email protected]>
 *
 * @dev Functionality in this library is largely implemented using an
 *      abstraction called a 'slice'. A slice represents a part of a string -
 *      anything from the entire string to a single character, or even no
 *      characters at all (a 0-length slice). Since a slice only has to specify
 *      an offset and a length, copying and manipulating slices is a lot less
 *      expensive than copying and manipulating the strings they reference.
 *
 *      To further reduce gas costs, most functions on slice that need to return
 *      a slice modify the original one instead of allocating a new one; for
 *      instance, `s.split(".")` will return the text up to the first '.',
 *      modifying s to only contain the remainder of the string after the '.'.
 *      In situations where you do not want to modify the original slice, you
 *      can make a copy first with `.copy()`, for example:
 *      `s.copy().split(".")`. Try and avoid using this idiom in loops; since
 *      Solidity has no memory management, it will result in allocating many
 *      short-lived slices that are later discarded.
 *
 *      Functions that return two slices come in two versions: a non-allocating
 *      version that takes the second slice as an argument, modifying it in
 *      place, and an allocating version that allocates and returns the second
 *      slice; see `nextRune` for example.
 *
 *      Functions that have to copy string data will return strings rather than
 *      slices; these can be cast back to slices for further processing if
 *      required.
 *
 *      For convenience, some functions are provided with non-modifying
 *      variants that create a new slice and return both; for instance,
 *      `s.splitNew('.')` leaves s unmodified, and returns two values
 *      corresponding to the left and right parts of the string.
 */

pragma solidity >=0.8.7;

library strings {
    struct slice {
        uint256 _len;
        uint256 _ptr;
    }

    function memcpy(
        uint256 dest,
        uint256 src,
        uint256 len
    ) private pure {
        // Copy word-length chunks while possible
        for (; len >= 32; len -= 32) {
            assembly {
                mstore(dest, mload(src))
            }
            dest += 32;
            src += 32;
        }

        // Copy remaining bytes
        uint256 mask = type(uint256).max;
        if (len > 0) {
            mask = 256**(32 - len) - 1;
        }
        assembly {
            let srcpart := and(mload(src), not(mask))
            let destpart := and(mload(dest), mask)
            mstore(dest, or(destpart, srcpart))
        }
    }

    /*
     * @dev Returns a slice containing the entire string.
     * @param self The string to make a slice from.
     * @return A newly allocated slice containing the entire string.
     */
    function toSlice(string memory self) internal pure returns (slice memory) {
        uint256 ptr;
        assembly {
            ptr := add(self, 0x20)
        }
        return slice(bytes(self).length, ptr);
    }

    /*
     * @dev Returns the length of a null-terminated bytes32 string.
     * @param self The value to find the length of.
     * @return The length of the string, from 0 to 32.
     */
    function len(bytes32 self) internal pure returns (uint256) {
        uint256 ret;
        if (self == 0) return 0;
        if (uint256(self) & type(uint128).max == 0) {
            ret += 16;
            self = bytes32(uint256(self) / 0x100000000000000000000000000000000);
        }
        if (uint256(self) & type(uint64).max == 0) {
            ret += 8;
            self = bytes32(uint256(self) / 0x10000000000000000);
        }
        if (uint256(self) & type(uint32).max == 0) {
            ret += 4;
            self = bytes32(uint256(self) / 0x100000000);
        }
        if (uint256(self) & type(uint16).max == 0) {
            ret += 2;
            self = bytes32(uint256(self) / 0x10000);
        }
        if (uint256(self) & type(uint8).max == 0) {
            ret += 1;
        }
        return 32 - ret;
    }

    /*
     * @dev Returns a slice containing the entire bytes32, interpreted as a
     *      null-terminated utf-8 string.
     * @param self The bytes32 value to convert to a slice.
     * @return A new slice containing the value of the input argument up to the
     *         first null.
     */
    function toSliceB32(bytes32 self) internal pure returns (slice memory ret) {
        // Allocate space for `self` in memory, copy it there, and point ret at it
        assembly {
            let ptr := mload(0x40)
            mstore(0x40, add(ptr, 0x20))
            mstore(ptr, self)
            mstore(add(ret, 0x20), ptr)
        }
        ret._len = len(self);
    }

    /*
     * @dev Returns a new slice containing the same data as the current slice.
     * @param self The slice to copy.
     * @return A new slice containing the same data as `self`.
     */
    function copy(slice memory self) internal pure returns (slice memory) {
        return slice(self._len, self._ptr);
    }

    /*
     * @dev Copies a slice to a new string.
     * @param self The slice to copy.
     * @return A newly allocated string containing the slice's text.
     */
    function toString(slice memory self) internal pure returns (string memory) {
        string memory ret = new string(self._len);
        uint256 retptr;
        assembly {
            retptr := add(ret, 32)
        }

        memcpy(retptr, self._ptr, self._len);
        return ret;
    }

    /*
     * @dev Returns the length in runes of the slice. Note that this operation
     *      takes time proportional to the length of the slice; avoid using it
     *      in loops, and call `slice.empty()` if you only need to know whether
     *      the slice is empty or not.
     * @param self The slice to operate on.
     * @return The length of the slice in runes.
     */
    function len(slice memory self) internal pure returns (uint256 l) {
        // Starting at ptr-31 means the LSB will be the byte we care about
        uint256 ptr = self._ptr - 31;
        uint256 end = ptr + self._len;
        for (l = 0; ptr < end; l++) {
            uint8 b;
            assembly {
                b := and(mload(ptr), 0xFF)
            }
            if (b < 0x80) {
                ptr += 1;
            } else if (b < 0xE0) {
                ptr += 2;
            } else if (b < 0xF0) {
                ptr += 3;
            } else if (b < 0xF8) {
                ptr += 4;
            } else if (b < 0xFC) {
                ptr += 5;
            } else {
                ptr += 6;
            }
        }
    }

    /*
     * @dev Returns true if the slice is empty (has a length of 0).
     * @param self The slice to operate on.
     * @return True if the slice is empty, False otherwise.
     */
    function empty(slice memory self) internal pure returns (bool) {
        return self._len == 0;
    }

    /*
     * @dev Returns a positive number if `other` comes lexicographically after
     *      `self`, a negative number if it comes before, or zero if the
     *      contents of the two slices are equal. Comparison is done per-rune,
     *      on unicode codepoints.
     * @param self The first slice to compare.
     * @param other The second slice to compare.
     * @return The result of the comparison.
     */
    function compare(slice memory self, slice memory other) internal pure returns (int256) {
        uint256 shortest = self._len;
        if (other._len < self._len) shortest = other._len;

        uint256 selfptr = self._ptr;
        uint256 otherptr = other._ptr;
        for (uint256 idx = 0; idx < shortest; idx += 32) {
            uint256 a;
            uint256 b;
            assembly {
                a := mload(selfptr)
                b := mload(otherptr)
            }
            if (a != b) {
                // Mask out irrelevant bytes and check again
                uint256 mask = type(uint256).max; // 0xffff...
                if (shortest < 32) {
                    mask = ~(2**(8 * (32 - shortest + idx)) - 1);
                }
                unchecked {
                    uint256 diff = (a & mask) - (b & mask);
                    if (diff != 0) return int256(diff);
                }
            }
            selfptr += 32;
            otherptr += 32;
        }
        return int256(self._len) - int256(other._len);
    }

    /*
     * @dev Returns true if the two slices contain the same text.
     * @param self The first slice to compare.
     * @param self The second slice to compare.
     * @return True if the slices are equal, false otherwise.
     */
    function equals(slice memory self, slice memory other) internal pure returns (bool) {
        return compare(self, other) == 0;
    }

    /*
     * @dev Extracts the first rune in the slice into `rune`, advancing the
     *      slice to point to the next rune and returning `self`.
     * @param self The slice to operate on.
     * @param rune The slice that will contain the first rune.
     * @return `rune`.
     */
    function nextRune(slice memory self, slice memory rune) internal pure returns (slice memory) {
        rune._ptr = self._ptr;

        if (self._len == 0) {
            rune._len = 0;
            return rune;
        }

        uint256 l;
        uint256 b;
        // Load the first byte of the rune into the LSBs of b
        assembly {
            b := and(mload(sub(mload(add(self, 32)), 31)), 0xFF)
        }
        if (b < 0x80) {
            l = 1;
        } else if (b < 0xE0) {
            l = 2;
        } else if (b < 0xF0) {
            l = 3;
        } else {
            l = 4;
        }

        // Check for truncated codepoints
        if (l > self._len) {
            rune._len = self._len;
            self._ptr += self._len;
            self._len = 0;
            return rune;
        }

        self._ptr += l;
        self._len -= l;
        rune._len = l;
        return rune;
    }

    /*
     * @dev Returns the first rune in the slice, advancing the slice to point
     *      to the next rune.
     * @param self The slice to operate on.
     * @return A slice containing only the first rune from `self`.
     */
    function nextRune(slice memory self) internal pure returns (slice memory ret) {
        nextRune(self, ret);
    }

    /*
     * @dev Returns the number of the first codepoint in the slice.
     * @param self The slice to operate on.
     * @return The number of the first codepoint in the slice.
     */
    function ord(slice memory self) internal pure returns (uint256 ret) {
        if (self._len == 0) {
            return 0;
        }

        uint256 word;
        uint256 length;
        uint256 divisor = 2**248;

        // Load the rune into the MSBs of b
        assembly {
            word := mload(mload(add(self, 32)))
        }
        uint256 b = word / divisor;
        if (b < 0x80) {
            ret = b;
            length = 1;
        } else if (b < 0xE0) {
            ret = b & 0x1F;
            length = 2;
        } else if (b < 0xF0) {
            ret = b & 0x0F;
            length = 3;
        } else {
            ret = b & 0x07;
            length = 4;
        }

        // Check for truncated codepoints
        if (length > self._len) {
            return 0;
        }

        for (uint256 i = 1; i < length; i++) {
            divisor = divisor / 256;
            b = (word / divisor) & 0xFF;
            if (b & 0xC0 != 0x80) {
                // Invalid UTF-8 sequence
                return 0;
            }
            ret = (ret * 64) | (b & 0x3F);
        }

        return ret;
    }

    /*
     * @dev Returns the keccak-256 hash of the slice.
     * @param self The slice to hash.
     * @return The hash of the slice.
     */
    function keccak(slice memory self) internal pure returns (bytes32 ret) {
        assembly {
            ret := keccak256(mload(add(self, 32)), mload(self))
        }
    }

    /*
     * @dev Returns true if `self` starts with `needle`.
     * @param self The slice to operate on.
     * @param needle The slice to search for.
     * @return True if the slice starts with the provided text, false otherwise.
     */
    function startsWith(slice memory self, slice memory needle) internal pure returns (bool) {
        if (self._len < needle._len) {
            return false;
        }

        if (self._ptr == needle._ptr) {
            return true;
        }

        bool equal;
        assembly {
            let length := mload(needle)
            let selfptr := mload(add(self, 0x20))
            let needleptr := mload(add(needle, 0x20))
            equal := eq(keccak256(selfptr, length), keccak256(needleptr, length))
        }
        return equal;
    }

    /*
     * @dev If `self` starts with `needle`, `needle` is removed from the
     *      beginning of `self`. Otherwise, `self` is unmodified.
     * @param self The slice to operate on.
     * @param needle The slice to search for.
     * @return `self`
     */
    function beyond(slice memory self, slice memory needle) internal pure returns (slice memory) {
        if (self._len < needle._len) {
            return self;
        }

        bool equal = true;
        if (self._ptr != needle._ptr) {
            assembly {
                let length := mload(needle)
                let selfptr := mload(add(self, 0x20))
                let needleptr := mload(add(needle, 0x20))
                equal := eq(keccak256(selfptr, length), keccak256(needleptr, length))
            }
        }

        if (equal) {
            self._len -= needle._len;
            self._ptr += needle._len;
        }

        return self;
    }

    /*
     * @dev Returns true if the slice ends with `needle`.
     * @param self The slice to operate on.
     * @param needle The slice to search for.
     * @return True if the slice starts with the provided text, false otherwise.
     */
    function endsWith(slice memory self, slice memory needle) internal pure returns (bool) {
        if (self._len < needle._len) {
            return false;
        }

        uint256 selfptr = self._ptr + self._len - needle._len;

        if (selfptr == needle._ptr) {
            return true;
        }

        bool equal;
        assembly {
            let length := mload(needle)
            let needleptr := mload(add(needle, 0x20))
            equal := eq(keccak256(selfptr, length), keccak256(needleptr, length))
        }

        return equal;
    }

    /*
     * @dev If `self` ends with `needle`, `needle` is removed from the
     *      end of `self`. Otherwise, `self` is unmodified.
     * @param self The slice to operate on.
     * @param needle The slice to search for.
     * @return `self`
     */
    function until(slice memory self, slice memory needle) internal pure returns (slice memory) {
        if (self._len < needle._len) {
            return self;
        }

        uint256 selfptr = self._ptr + self._len - needle._len;
        bool equal = true;
        if (selfptr != needle._ptr) {
            assembly {
                let length := mload(needle)
                let needleptr := mload(add(needle, 0x20))
                equal := eq(keccak256(selfptr, length), keccak256(needleptr, length))
            }
        }

        if (equal) {
            self._len -= needle._len;
        }

        return self;
    }

    // Returns the memory address of the first byte of the first occurrence of
    // `needle` in `self`, or the first byte after `self` if not found.
    function findPtr(
        uint256 selflen,
        uint256 selfptr,
        uint256 needlelen,
        uint256 needleptr
    ) private pure returns (uint256) {
        uint256 ptr = selfptr;
        uint256 idx;

        if (needlelen <= selflen) {
            if (needlelen <= 32) {
                bytes32 mask;
                if (needlelen > 0) {
                    mask = bytes32(~(2**(8 * (32 - needlelen)) - 1));
                }

                bytes32 needledata;
                assembly {
                    needledata := and(mload(needleptr), mask)
                }

                uint256 end = selfptr + selflen - needlelen;
                bytes32 ptrdata;
                assembly {
                    ptrdata := and(mload(ptr), mask)
                }

                while (ptrdata != needledata) {
                    if (ptr >= end) return selfptr + selflen;
                    ptr++;
                    assembly {
                        ptrdata := and(mload(ptr), mask)
                    }
                }
                return ptr;
            } else {
                // For long needles, use hashing
                bytes32 hash;
                assembly {
                    hash := keccak256(needleptr, needlelen)
                }

                for (idx = 0; idx <= selflen - needlelen; idx++) {
                    bytes32 testHash;
                    assembly {
                        testHash := keccak256(ptr, needlelen)
                    }
                    if (hash == testHash) return ptr;
                    ptr += 1;
                }
            }
        }
        return selfptr + selflen;
    }

    // Returns the memory address of the first byte after the last occurrence of
    // `needle` in `self`, or the address of `self` if not found.
    function rfindPtr(
        uint256 selflen,
        uint256 selfptr,
        uint256 needlelen,
        uint256 needleptr
    ) private pure returns (uint256) {
        uint256 ptr;

        if (needlelen <= selflen) {
            if (needlelen <= 32) {
                bytes32 mask;
                if (needlelen > 0) {
                    mask = bytes32(~(2**(8 * (32 - needlelen)) - 1));
                }

                bytes32 needledata;
                assembly {
                    needledata := and(mload(needleptr), mask)
                }

                ptr = selfptr + selflen - needlelen;
                bytes32 ptrdata;
                assembly {
                    ptrdata := and(mload(ptr), mask)
                }

                while (ptrdata != needledata) {
                    if (ptr <= selfptr) return selfptr;
                    ptr--;
                    assembly {
                        ptrdata := and(mload(ptr), mask)
                    }
                }
                return ptr + needlelen;
            } else {
                // For long needles, use hashing
                bytes32 hash;
                assembly {
                    hash := keccak256(needleptr, needlelen)
                }
                ptr = selfptr + (selflen - needlelen);
                while (ptr >= selfptr) {
                    bytes32 testHash;
                    assembly {
                        testHash := keccak256(ptr, needlelen)
                    }
                    if (hash == testHash) return ptr + needlelen;
                    ptr -= 1;
                }
            }
        }
        return selfptr;
    }

    /*
     * @dev Modifies `self` to contain everything from the first occurrence of
     *      `needle` to the end of the slice. `self` is set to the empty slice
     *      if `needle` is not found.
     * @param self The slice to search and modify.
     * @param needle The text to search for.
     * @return `self`.
     */
    function find(slice memory self, slice memory needle) internal pure returns (slice memory) {
        uint256 ptr = findPtr(self._len, self._ptr, needle._len, needle._ptr);
        self._len -= ptr - self._ptr;
        self._ptr = ptr;
        return self;
    }

    /*
     * @dev Modifies `self` to contain the part of the string from the start of
     *      `self` to the end of the first occurrence of `needle`. If `needle`
     *      is not found, `self` is set to the empty slice.
     * @param self The slice to search and modify.
     * @param needle The text to search for.
     * @return `self`.
     */
    function rfind(slice memory self, slice memory needle) internal pure returns (slice memory) {
        uint256 ptr = rfindPtr(self._len, self._ptr, needle._len, needle._ptr);
        self._len = ptr - self._ptr;
        return self;
    }

    /*
     * @dev Splits the slice, setting `self` to everything after the first
     *      occurrence of `needle`, and `token` to everything before it. If
     *      `needle` does not occur in `self`, `self` is set to the empty slice,
     *      and `token` is set to the entirety of `self`.
     * @param self The slice to split.
     * @param needle The text to search for in `self`.
     * @param token An output parameter to which the first token is written.
     * @return `token`.
     */
    function split(
        slice memory self,
        slice memory needle,
        slice memory token
    ) internal pure returns (slice memory) {
        uint256 ptr = findPtr(self._len, self._ptr, needle._len, needle._ptr);
        token._ptr = self._ptr;
        token._len = ptr - self._ptr;
        if (ptr == self._ptr + self._len) {
            // Not found
            self._len = 0;
        } else {
            self._len -= token._len + needle._len;
            self._ptr = ptr + needle._len;
        }
        return token;
    }

    /*
     * @dev Splits the slice, setting `self` to everything after the first
     *      occurrence of `needle`, and returning everything before it. If
     *      `needle` does not occur in `self`, `self` is set to the empty slice,
     *      and the entirety of `self` is returned.
     * @param self The slice to split.
     * @param needle The text to search for in `self`.
     * @return The part of `self` up to the first occurrence of `delim`.
     */
    function split(slice memory self, slice memory needle) internal pure returns (slice memory token) {
        split(self, needle, token);
    }

    /*
     * @dev Splits the slice, setting `self` to everything before the last
     *      occurrence of `needle`, and `token` to everything after it. If
     *      `needle` does not occur in `self`, `self` is set to the empty slice,
     *      and `token` is set to the entirety of `self`.
     * @param self The slice to split.
     * @param needle The text to search for in `self`.
     * @param token An output parameter to which the first token is written.
     * @return `token`.
     */
    function rsplit(
        slice memory self,
        slice memory needle,
        slice memory token
    ) internal pure returns (slice memory) {
        uint256 ptr = rfindPtr(self._len, self._ptr, needle._len, needle._ptr);
        token._ptr = ptr;
        token._len = self._len - (ptr - self._ptr);
        if (ptr == self._ptr) {
            // Not found
            self._len = 0;
        } else {
            self._len -= token._len + needle._len;
        }
        return token;
    }

    /*
     * @dev Splits the slice, setting `self` to everything before the last
     *      occurrence of `needle`, and returning everything after it. If
     *      `needle` does not occur in `self`, `self` is set to the empty slice,
     *      and the entirety of `self` is returned.
     * @param self The slice to split.
     * @param needle The text to search for in `self`.
     * @return The part of `self` after the last occurrence of `delim`.
     */
    function rsplit(slice memory self, slice memory needle) internal pure returns (slice memory token) {
        rsplit(self, needle, token);
    }

    /*
     * @dev Counts the number of nonoverlapping occurrences of `needle` in `self`.
     * @param self The slice to search.
     * @param needle The text to search for in `self`.
     * @return The number of occurrences of `needle` found in `self`.
     */
    function count(slice memory self, slice memory needle) internal pure returns (uint256 cnt) {
        uint256 ptr = findPtr(self._len, self._ptr, needle._len, needle._ptr) + needle._len;
        while (ptr <= self._ptr + self._len) {
            cnt++;
            ptr = findPtr(self._len - (ptr - self._ptr), ptr, needle._len, needle._ptr) + needle._len;
        }
    }

    /*
     * @dev Returns True if `self` contains `needle`.
     * @param self The slice to search.
     * @param needle The text to search for in `self`.
     * @return True if `needle` is found in `self`, false otherwise.
     */
    function contains(slice memory self, slice memory needle) internal pure returns (bool) {
        return rfindPtr(self._len, self._ptr, needle._len, needle._ptr) != self._ptr;
    }

    /*
     * @dev Returns a newly allocated string containing the concatenation of
     *      `self` and `other`.
     * @param self The first slice to concatenate.
     * @param other The second slice to concatenate.
     * @return The concatenation of the two strings.
     */
    function concat(slice memory self, slice memory other) internal pure returns (string memory) {
        string memory ret = new string(self._len + other._len);
        uint256 retptr;
        assembly {
            retptr := add(ret, 32)
        }
        memcpy(retptr, self._ptr, self._len);
        memcpy(retptr + self._len, other._ptr, other._len);
        return ret;
    }

    /*
     * @dev Joins an array of slices, using `self` as a delimiter, returning a
     *      newly allocated string.
     * @param self The delimiter to use.
     * @param parts A list of slices to join.
     * @return A newly allocated string containing all the slices in `parts`,
     *         joined with `self`.
     */
    function join(slice memory self, slice[] memory parts) internal pure returns (string memory) {
        if (parts.length == 0) return "";

        uint256 length = self._len * (parts.length - 1);
        for (uint256 i = 0; i < parts.length; i++) length += parts[i]._len;

        string memory ret = new string(length);
        uint256 retptr;
        assembly {
            retptr := add(ret, 32)
        }

        for (uint256 i = 0; i < parts.length; i++) {
            memcpy(retptr, parts[i]._ptr, parts[i]._len);
            retptr += parts[i]._len;
            if (i < parts.length - 1) {
                memcpy(retptr, self._ptr, self._len);
                retptr += self._len;
            }
        }

        return ret;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = _setInitializedVersion(1);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        bool isTopLevelCall = _setInitializedVersion(version);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(version);
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        _setInitializedVersion(type(uint8).max);
    }

    function _setInitializedVersion(uint8 version) private returns (bool) {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, and for the lowest level
        // of initializers, because in other contexts the contract may have been reentered.
        if (_initializing) {
            require(
                version == 1 && !AddressUpgradeable.isContract(address(this)),
                "Initializable: contract is already initialized"
            );
            return false;
        } else {
            require(_initialized < version, "Initializable: contract is already initialized");
            _initialized = version;
            return true;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
interface IERC165Upgradeable {
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