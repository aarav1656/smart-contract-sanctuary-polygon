//SPDX-License-Identifier: UNLICENSED
//llydia cross 2021
pragma solidity ^0.8.0;

import "./RandomNumber.sol";

abstract contract Asset {
    struct PartialStruct {
        uint32 pathId;
        uint32 pathSize;
        uint32[] assets;
        string[] names;
        uint32[] colours;
        bytes mintData;
    }

    function getColours(uint32 pathId, RandomNumber randomNumberController)
        public
        virtual
        returns (uint32[] memory result);

    function getDefaultName() internal virtual returns (string memory);

    function getNextPath() external view virtual returns (uint32);

    function pickPath(
        uint32 currentTokenId,
        RandomNumber randomNumberController
    ) public virtual returns (PartialStruct memory);

    function isValidPath(uint32 pathId) external view virtual returns (bool);

    function pickPath(
        uint32 pathId,
        uint32 currentTokenId,
        RandomNumber randomNumberController
    ) public virtual returns (PartialStruct memory);

    function setLastAssets(uint32[] memory assets) public virtual;

    function getNames(uint256 nameCount, RandomNumber randomNumberController)
        public
        virtual
        returns (string[] memory results);

    function getRandomAsset(uint32 pathId, RandomNumber randomNumberController)
        external
        virtual
        returns (uint32[] memory assetsId);

    function getMintData(
        uint32 pathId,
        uint32 tokenId,
        RandomNumber randomNumberController
    ) public virtual returns (bytes memory);

    function addAsset(uint256 rarity) public virtual;

    function setNextPathId(uint32 pathId) public virtual;

    function setLastPathId(uint32 pathId) public virtual;

    function getPathSize(uint32 pathId) public view virtual returns (uint32);

    function getNextPathId(RandomNumber randomNumberController)
        public
        virtual
        returns (uint32);
}

//SPDX-License-Identifier: UNLICENSED
//llydia cross 2021
pragma solidity ^0.8.0;

import "./InfinityMintObject.sol";

abstract contract Authentication {
    address public deployer;
    /// @notice for re-entry prevention, keeps track of a methods execution count
    uint256 private executionCount;

    mapping(address => bool) public approved;

    constructor() {
        deployer = msg.sender;
        approved[msg.sender] = true;
        executionCount = 0;
    }

    event PermissionChange(
        address indexed sender,
        address indexed changee,
        bool value
    );

    event TransferedOwnership(address indexed from, address indexed to);

    /// @notice Limits execution of a method to once in the given context.
    /// @dev prevents re-entry attack
    modifier onlyOnce() {
        executionCount += 1;
        uint256 localCounter = executionCount;
        _;
        require(localCounter == executionCount);
    }

    modifier onlyDeployer() {
        require(deployer == msg.sender, "not deployer");
        _;
    }

    modifier onlyApproved() {
        require(deployer == msg.sender || approved[msg.sender], "not approved");
        _;
    }

    function setPrivilages(address addr, bool value) public onlyDeployer {
        require(addr != deployer, "cannot modify deployer");
        approved[addr] = value;

        emit PermissionChange(msg.sender, addr, value);
    }

    function multiApprove(address[] memory addrs) public onlyDeployer {
        require(addrs.length != 0);
        for (uint256 i = 0; i < addrs.length; ) {
            approved[addrs[i]] = true;
            unchecked {
                ++i;
            }
        }
    }

    function isAuthenticated(address addr) external view returns (bool) {
        return addr == deployer || approved[addr];
    }

    function transferOwnership(address addr) public onlyDeployer {
        approved[deployer] = false;
        deployer = addr;
        approved[addr] = true;

        emit TransferedOwnership(msg.sender, addr);
    }
}

//SPDX-License-Identifier: UNLICENSED
//llydia cross 2021
pragma solidity ^0.8.0;

import "./Asset.sol";
import "./Authentication.sol";

abstract contract InfinityMintAsset is Asset, Authentication {
    mapping(uint256 => bool) internal disabledPaths; //disabled paths which are not picked
    mapping(uint256 => uint256[]) internal pathSections; //what sections are to what path

    //user values
    InfinityMintValues internal valuesController;

    //the token name
    string internal tokenName = "asset";
    string public assetsType = "default"; //the type of assetId is default

    //path stuff
    uint256 internal pathCount;
    uint32[] internal pathSizes; //the amount of points in a path (used in random colour generation with SVG things)
    uint256 internal safeDefaultReturnPath; //used in the case we cannot decide what path to randomly select we will return the value of this

    uint256 internal assetId; //
    uint256[][] internal assetsSections; //the sections to an asset
    uint256[] internal assetRarity; //a list of asset rarity
    uint32[] internal lastAssets; //the last selection of assets
    uint32 internal nextPath = 0; //the next path to be minted
    uint32 internal lastPath = 0;

    //the names to pick from when generating
    string[] internal names;

    //if all paths are for all sections
    bool private flatSections = false;

    constructor(address valuesContract) {
        valuesController = InfinityMintValues(valuesContract);
        assetRarity.push(0); //so assetId start at 1 not zero so zero can be treat as a
    }

    function setNames(string[] memory newNames) public onlyApproved {
        names = newNames;
    }

    function resetNames() public onlyApproved {
        delete names;
    }

    function resetAssets() public onlyApproved {
        delete assetRarity;
        delete assetsSections;
        assetRarity.push(0);
        assetId = 0;
        flatSections = false;
    }

    function resetPaths() public onlyApproved {
        delete pathSizes;
        pathCount = 0;
        safeDefaultReturnPath = 0;
    }

    function combineNames(string[] memory newNames) public onlyApproved {
        require(newNames.length < 100);

        for (uint256 i = 0; i < newNames.length; ) {
            names.push(newNames[i]);

            unchecked {
                ++i;
            }
        }
    }

    function addName(string memory name) public onlyApproved {
        names.push(name);
    }

    function setNextPathId(uint32 pathId) public virtual override onlyApproved {
        nextPath = pathId;
    }

    function setLastPathId(uint32 pathId) public virtual override onlyApproved {
        lastPath = pathId;
    }

    function getNextPath() external view virtual override returns (uint32) {
        return nextPath;
    }

    function setLastAssets(uint32[] memory assets)
        public
        virtual
        override
        onlyApproved
    {
        lastAssets = assets;
    }

    function getPathSections(uint256 pathId)
        external
        view
        virtual
        returns (uint256[] memory)
    {
        return pathSections[pathId];
    }

    function getSectionAssets(uint256 sectionId)
        external
        view
        returns (uint256[] memory)
    {
        return assetsSections[sectionId];
    }

    function setPathSize(uint32 pathId, uint32 pathSize) public onlyApproved {
        pathSizes[pathId] = pathSize;
    }

    function setPathSizes(uint32[] memory newPathSizes) public onlyApproved {
        pathSizes = newPathSizes;
    }

    function getPathSize(uint32 pathId) public view override returns (uint32) {
        if (pathId >= pathSizes.length) return 1;

        return pathSizes[pathId];
    }

    function getNextPathId(RandomNumber randomNumberController)
        public
        virtual
        override
        returns (uint32)
    {
        uint256 result = randomNumberController.getMaxNumber(pathCount);

        //path is greather than token Paths
        if (result >= pathCount) return uint32(safeDefaultReturnPath);

        //count up until a non disabled path is found
        while (disabledPaths[result]) {
            if (result + 1 >= pathCount) result = 0;
            result++;
        }

        return uint32(result);
    }

    function getNames(uint256 nameCount, RandomNumber randomNumberController)
        public
        virtual
        override
        returns (string[] memory results)
    {
        string memory defaultName = getDefaultName();

        // matched and incremental use nextPath to get their name
        if (
            !valuesController.isTrue("matchedMode") &&
            !valuesController.isTrue("incrementalMode")
        ) {
            if (nameCount <= 0 && valuesController.isTrue("mustGenerateName"))
                nameCount = 1;

            if (nameCount <= 0 || names.length == 0) {
                results = new string[](1);
                results[0] = defaultName;
                return results;
            }

            results = new string[](nameCount + 1);

            for (uint32 i = 0; i < nameCount; ) {
                uint256 result = randomNumberController.getMaxNumber(
                    names.length
                );

                if (result >= names.length) result = 0;
                results[i] = names[result];

                unchecked {
                    ++i;
                }
            }
            results[nameCount] = defaultName;
        } else {
            results = new string[](2);

            if (names.length == 0) results[0] = "";
            else if (nextPath < names.length) results[0] = names[nextPath];
            else results[0] = names[0];
            results[1] = defaultName;
        }
    }

    function getMintData(
        uint32,
        uint32,
        RandomNumber
    ) public virtual override returns (bytes memory) {
        return "{}"; //returns a blank json array
    }

    function getDefaultName()
        internal
        virtual
        override
        returns (string memory)
    {
        return tokenName;
    }

    function isValidPath(uint32 pathId) public view override returns (bool) {
        return (pathId >= 0 && pathId < pathCount && !disabledPaths[pathId]);
    }

    function pickPath(
        uint32 pathId,
        uint32 currentTokenId,
        RandomNumber randomNumberController
    ) public virtual override returns (PartialStruct memory) {
        setNextPathId(pathId);
        setLastAssets(getRandomAsset(pathId, randomNumberController));

        return
            PartialStruct(
                pathId,
                getPathSize(pathId),
                lastAssets,
                getNames(
                    randomNumberController.getMaxNumber(
                        valuesController.tryGetValue("nameCount")
                    ),
                    randomNumberController
                ),
                getColours(pathId, randomNumberController),
                getMintData(pathId, currentTokenId, randomNumberController)
            );
    }

    function pickPath(
        uint32 currentTokenId,
        RandomNumber randomNumberController
    ) public virtual override returns (PartialStruct memory) {
        return
            pickPath(
                getNextPathId(randomNumberController),
                currentTokenId,
                randomNumberController
            );
    }

    function getRandomAsset(uint32 pathId, RandomNumber randomNumberController)
        public
        view
        virtual
        override
        returns (uint32[] memory assetsId)
    {
        if (assetId == 0) {
            return assetsId;
        }

        uint256[] memory sections;
        if (flatSections) sections = pathSections[0];
        else sections = pathSections[pathId];

        //index position of sections
        uint256 indexPosition = 0;
        //current random number salt
        uint256 salt = randomNumberController.salt();

        if (sections.length == 0) {
            return assetsId;
        } else {
            assetsId = new uint32[](sections.length);
            uint32[] memory selectedPaths;
            uint256[] memory section;
            for (uint256 i = 0; i < sections.length; ) {
                section = assetsSections[sections[i]];

                if (section.length == 0) {
                    assetsId[indexPosition++] = 0;
                    unchecked {
                        ++i;
                    }
                    continue;
                }

                if (section.length == 1 && assetRarity[section[0]] == 100) {
                    assetsId[indexPosition++] = uint32(section[0]);
                    unchecked {
                        ++i;
                    }
                    continue;
                }

                selectedPaths = new uint32[](section.length);
                //repeat filling array with found values
                uint256 count = 0;

                for (uint256 index = 0; index < section.length; ) {
                    if (count == selectedPaths.length) break;
                    if (section[index] == 0) {
                        unchecked {
                            ++index;
                        }
                        continue;
                    }

                    uint256 rarity = 0;

                    if (assetRarity.length > section[index])
                        rarity = assetRarity[section[index]];

                    if (
                        (rarity == 100 ||
                            rarity >
                            randomNumberController.returnNumber(
                                100,
                                i +
                                    index +
                                    rarity +
                                    count +
                                    salt +
                                    indexPosition
                            ))
                    ) selectedPaths[count++] = uint32(section[index]);

                    unchecked {
                        ++index;
                    }
                }

                //pick an asset
                uint256 result = 0;

                if (count <= 1) assetsId[indexPosition++] = selectedPaths[0];
                else if (count >= 2) {
                    result = randomNumberController.returnNumber(
                        count,
                        selectedPaths.length + count + indexPosition + salt
                    );
                    if (result < selectedPaths.length)
                        assetsId[indexPosition++] = selectedPaths[result];
                    else assetsId[indexPosition++] = 0;
                }

                unchecked {
                    ++i;
                }
            }
        }
    }

    function setSectionAssets(uint32 sectionId, uint256[] memory _assets)
        public
        onlyDeployer
    {
        assetsSections[sectionId] = _assets;
    }

    function pushSectionAssets(uint256[] memory _assets) public onlyDeployer {
        assetsSections.push(_assets);
    }

    function flatPathSections(uint32[] memory pathIds) public onlyDeployer {
        pathSections[0] = pathIds;
        flatSections = true;
    }

    function setPathSections(
        uint32[] memory pathIds,
        uint256[][] memory _sections
    ) public onlyDeployer {
        require(pathIds.length == _sections.length);

        for (uint256 i = 0; i < pathIds.length; i++) {
            pathSections[pathIds[i]] = _sections[i];
        }
    }

    function addAssets(uint256[] memory rarities) public onlyDeployer {
        for (uint256 i = 0; i < rarities.length; ) {
            if (rarities[i] > 100) revert("one of more rarities are above 100");
            assetRarity.push(rarities[i]);
            //increment asset counter
            assetId += 1;
            unchecked {
                ++i;
            }
        }
    }

    function addAsset(uint256 rarity) public virtual override onlyDeployer {
        if (rarity > 100) revert();

        //increment asset counter
        assetRarity.push(rarity);
        assetId += 1;
    }

    //returns randomised colours for SVG Paths
    function getColours(uint32 pathId, RandomNumber randomNumberController)
        public
        virtual
        override
        returns (uint32[] memory result)
    {
        uint32 pathSize = getPathSize(pathId);
        uint256 div = valuesController.tryGetValue("colourChunkSize");

        if (div <= 0) div = 4;

        if (pathSize <= div) {
            result = new uint32[](4);
            result[0] = uint32(randomNumberController.getMaxNumber(0xFFFFFF));
            result[1] = pathSize;
            result[2] = uint32(randomNumberController.getMaxNumber(0xFFFFFFFF));
            result[3] = uint32(valuesController.tryGetValue("extraColours"));
            return result;
        }

        uint32 groups = uint32(1 + (pathSize / div));
        uint32 size = (groups * 2);
        uint32 tempPathSize = (pathSize);
        uint256 count = 0;
        result = new uint32[](size + 2);
        for (uint256 i = 0; i < size; ) {
            if (i == 0 || i % 2 == 0)
                result[i] = uint32(
                    randomNumberController.getMaxNumber(0xFFFFFF)
                );
            else {
                uint256 tempResult = tempPathSize - (div * count++);
                result[i] = uint32(tempResult > div ? div : tempResult);
            }

            unchecked {
                ++i;
            }
        }

        result[result.length - 2] = uint32(
            randomNumberController.getMaxNumber(0xFFFFFFFF)
        );
        result[result.length - 1] = uint32(
            valuesController.tryGetValue("extraColours")
        );
    }

    function setPathDisabled(uint32 pathId, bool value) public onlyApproved {
        //if path zero is suddenly disabled, we need a new safe path to return
        if (pathId == safeDefaultReturnPath && value) {
            uint256 val = (safeDefaultReturnPath);
            while (disabledPaths[val]) {
                if (val >= pathCount) val = safeDefaultReturnPath;
                val++;
            }
            safeDefaultReturnPath = val;
        }

        //if we enable zero again then its safe to return 0
        if (pathId <= safeDefaultReturnPath && value)
            safeDefaultReturnPath = pathId;

        disabledPaths[pathId] = value;
    }

    function setPathCount(uint256 newPathCount) public onlyApproved {
        pathCount = newPathCount;
    }
}

//SPDX-License-Identifier: UNLICENSED
//llydia cross 2021
pragma solidity ^0.8.0;

//this is implemented by every contract in our system
import "./InfinityMintUtil.sol";
import "./InfinityMintValues.sol";

abstract contract InfinityMintObject {
    /// @notice The main InfinityMint object, TODO: Work out a way for this to easily be modified
    struct InfinityObject {
        uint32 pathId;
        uint32 pathSize;
        uint32 currentTokenId;
        address owner;
        uint32[] colours;
        bytes mintData;
        uint32[] assets;
        string[] names;
        address[] destinations;
    }

    /// @notice Creates a new struct from arguments
    /// @dev Stickers are not set through this, structs cannot be made with sticker contracts already set and have to be set manually
    /// @param currentTokenId the tokenId,
    /// @param pathId the infinity mint paths id
    /// @param pathSize the size of the path (only for vectors)
    /// @param assets the assets which make up the token
    /// @param names the names of the token, its just the name but split by the splaces.
    /// @param colours decimal colours which will be convered to hexadecimal colours
    /// @param mintData variable dynamic field which is passed to ERC721 Implementor contracts and used in a lot of dynamic stuff
    /// @param _sender aka the owner of the token
    /// @param destinations a list of contracts associated with this token
    function createInfinityObject(
        uint32 currentTokenId,
        uint32 pathId,
        uint32 pathSize,
        uint32[] memory assets,
        string[] memory names,
        uint32[] memory colours,
        bytes memory mintData,
        address _sender,
        address[] memory destinations
    ) internal pure returns (InfinityObject memory) {
        return
            InfinityObject(
                pathId,
                pathSize,
                currentTokenId,
                _sender, //the sender aka owner
                colours,
                mintData,
                assets,
                names,
                destinations
            );
    }

    /// @notice basically unpacks a return object into bytes.
    function encode(InfinityObject memory data)
        internal
        pure
        returns (bytes memory)
    {
        return
            abi.encode(
                data.pathId,
                data.pathSize,
                data.currentTokenId,
                data.owner,
                abi.encode(data.colours),
                data.mintData,
                data.assets,
                data.names,
                data.destinations
            );
    }

    /// @notice Copied behavours of the open zeppelin content due to prevent msg.sender rewrite through assembly
    function sender() internal view returns (address) {
        return (msg.sender);
    }

    /// @notice Copied behavours of the open zeppelin content due to prevent msg.sender rewrite through assembly
    function value() internal view returns (uint256) {
        return (msg.value);
    }
}

//SPDX-License-Identifier: UNLICENSED
//llydia cross 2021
pragma solidity ^0.8.0;

library InfinityMintUtil {
    function toString(uint256 _i)
        internal
        pure
        returns (string memory _uintAsString)
    {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    function filepath(
        string memory directory,
        string memory file,
        string memory extension
    ) internal pure returns (string memory) {
        return
            abi.decode(abi.encodePacked(directory, file, extension), (string));
    }

    //checks if two strings (or bytes) are equal
    function isEqual(bytes memory s1, bytes memory s2)
        internal
        pure
        returns (bool)
    {
        bytes memory b1 = bytes(s1);
        bytes memory b2 = bytes(s2);
        uint256 l1 = b1.length;
        if (l1 != b2.length) return false;
        for (uint256 i = 0; i < l1; i++) {
            //check each byte
            if (b1[i] != b2[i]) return false;
        }
        return true;
    }
}

//SPDX-License-Identifier: UNLICENSED
//llydia cross 2021
pragma solidity ^0.8.0;

contract InfinityMintValues {
    mapping(string => uint256) private values;
    mapping(string => bool) private booleanValues;
    mapping(string => bool) private registeredValues;

    address deployer;

    constructor() {
        deployer = msg.sender;
    }

    modifier onlyDeployer() {
        if (msg.sender != deployer) revert();
        _;
    }

    function setValue(string memory key, uint256 value) public onlyDeployer {
        values[key] = value;
        registeredValues[key] = true;
    }

    function setupValues(
        string[] memory keys,
        uint256[] memory _values,
        string[] memory booleanKeys,
        bool[] memory _booleanValues
    ) public onlyDeployer {
        require(keys.length == _values.length);
        require(booleanKeys.length == _booleanValues.length);
        for (uint256 i = 0; i < keys.length; i++) {
            setValue(keys[i], _values[i]);
        }

        for (uint256 i = 0; i < booleanKeys.length; i++) {
            setBooleanValue(booleanKeys[i], _booleanValues[i]);
        }
    }

    function setBooleanValue(string memory key, bool value)
        public
        onlyDeployer
    {
        booleanValues[key] = value;
        registeredValues[key] = true;
    }

    function isTrue(string memory key) external view returns (bool) {
        return booleanValues[key];
    }

    function getValue(string memory key) external view returns (uint256) {
        if (!registeredValues[key]) revert("Invalid Value");

        return values[key];
    }

    /// @dev Default value it returns is zero
    function tryGetValue(string memory key) external view returns (uint256) {
        if (!registeredValues[key]) return 0;

        return values[key];
    }
}

//SPDX-License-Identifier: UNLICENSED
//llydia cross 2021
pragma solidity ^0.8.0;

import "./InfinityMintValues.sol";

/// @title InfinityMint Random Number Abstract Contract
/// @author Llydia Cross
abstract contract RandomNumber {
    uint256 public randomnessFactor;
    bool public hasDeployed = false;
    uint256 public salt = 1;

    InfinityMintValues internal valuesController;

    constructor(address valuesContract) {
        valuesController = InfinityMintValues(valuesContract);
        randomnessFactor = valuesController.getValue("randomessFactor");
    }

    function getNumber() external returns (uint256) {
        unchecked {
            ++salt;
        }

        return returnNumber(valuesController.getValue("maxRandomNumber"), salt);
    }

    function getMaxNumber(uint256 maxNumber) external returns (uint256) {
        unchecked {
            ++salt;
        }

        return returnNumber(maxNumber, salt);
    }

    /// @notice cheap return number
    function returnNumber(uint256 maxNumber, uint256 _salt)
        public
        view
        virtual
        returns (uint256)
    {
        if (maxNumber <= 0) maxNumber = 1;
        return (_salt + 3) % maxNumber;
    }
}

//SPDX-License-Identifier: UNLICENSED
//llydia cross 2021
pragma solidity ^0.8.0;

import "../InfinityMintAsset.sol";

contract SimpleImage is InfinityMintAsset {
    /**

	 */
    constructor(string memory _tokenName, address valuesContract)
        InfinityMintAsset(valuesContract)
    {
        tokenName = _tokenName;
        assetsType = "image";
    }

    function getNextPathId(RandomNumber randomNumberController)
        public
        virtual
        override
        returns (uint32)
    {
        if (pathCount == 1 && disabledPaths[safeDefaultReturnPath])
            revert("No valid paths");

        if (valuesController.isTrue("incrementalMode")) {
            nextPath = lastPath++;
            if (nextPath >= pathCount) {
                lastPath = uint32(safeDefaultReturnPath);
                nextPath = uint32(safeDefaultReturnPath);
            }
            while (disabledPaths[nextPath]) {
                if (nextPath >= pathCount)
                    nextPath = uint32(safeDefaultReturnPath);
                nextPath++;
            }
            return nextPath;
        } else {
            uint32 pathId = uint32(
                randomNumberController.getMaxNumber(pathCount)
            );

            if (disabledPaths[pathId] || pathId >= pathCount)
                pathId = uint32(safeDefaultReturnPath);

            return pathId;
        }
    }
}