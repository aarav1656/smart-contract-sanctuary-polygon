// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./AssetPool.sol";
import "./Resources.sol";
import "./Crafting.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title Rewards
 * @author Jack Chuma
 * @dev Contract to facilitate reward redemption in the PV Gaming Ecosystem
 */
contract Rewards is Ownable {

    address private pow;
    address private lockedResources;
    uint256 private craftingFee;
    AssetPool private assetPool;
    Resources private resources;
    Crafting private crafting;

    struct ResourceReward {
        uint256 rewardId;
        address user;
        uint256 powIn;
        uint256[] resourceIds;
        uint256[] powSplitUp;
    }

    struct GameItemReward {
        uint256 rewardId;
        address user;
        uint256 powIn;
        uint256[] resourceIds;
        uint256[] powSplitUp;
        uint256 itemId;
    }

    error NoReplay();
    error InvalidFee();
    error ZeroAddress();
    error InvalidSender();
    error InvalidSignature();
    error MustUpdateState();
    error AddressAlreadySet();

    event ResourceRewardClaimed(
        uint256 indexed rewardId,
        address indexed user,
        uint256 powIn,
        uint256[] resourceIds,
        uint256[] amounts
    );

    event GameItemRewardClaimed(
        uint256 indexed rewardId,
        address indexed user,
        uint256 powIn,
        uint256[] resourceIds,
        uint256[] amounts,
        uint256 itemId
    );

    event NewCraftingFee(
        uint256 indexed fee
    );

    event ResourcesAddressSet(
        address indexed resourcesAddress
    );

    event CraftingAddressSet(
        address indexed craftingAddress
    );

    event LockedResourcesAddressUpdated(
        address indexed lockedResourcesAddress
    );

    constructor(
        address _pow, 
        address _lockedResources, 
        uint256 _craftingFee, 
        address _assetPool
    ) {
        if (
            _pow == address(0) || 
            _lockedResources == address(0) || 
            _assetPool == address(0)
        ) revert ZeroAddress();
        if (_craftingFee > 1000000000000000000) revert InvalidFee();
        pow = _pow;
        assetPool = AssetPool(_assetPool);
        lockedResources = _lockedResources;
        craftingFee = _craftingFee;
    }

    /**
     * @notice Called by contract owner to update stored crafting fee
     * @param _fee Number in wei representing a fee percentage
     * @dev _fee must be between 0 and 10^18
     */
    function setCraftingFee(uint256 _fee) external onlyOwner {
        if (_fee > 1000000000000000000) revert InvalidFee();
        if (_fee == craftingFee) revert MustUpdateState();
        craftingFee = _fee;
        emit NewCraftingFee(_fee);
    }

    /**
     * @dev Called by contract owner in deploy script to set stored Resources contract address
     * @dev Can only be called once
     */
    function setResourcesAddress(address _resources) external onlyOwner {
        if (_resources == address(0)) revert ZeroAddress();
        if (address(resources) != address(0)) revert AddressAlreadySet();
        resources = Resources(_resources);
        emit ResourcesAddressSet(_resources);
    }

    /**
     * @dev Called by contract owner in deploy script to set stored Crafting contract address
     * @dev Can only be called once
     */
    function setCraftingAddress(address _crafting) external onlyOwner {
        if (_crafting == address(0)) revert ZeroAddress();
        if (address(crafting) != address(0)) revert AddressAlreadySet();
        crafting = Crafting(_crafting);
        emit CraftingAddressSet(_crafting);
    }

    /**
     * @notice Called by contract owner to update stored address for Locked Resources contract
     * @dev Cannot be zero address and must be different than address already stored
     * @param _lockedResources New address for Locked Resources contract
     */
    function updateLockedResourcesAddress(
        address _lockedResources
    ) external onlyOwner {
        if (_lockedResources == address(0)) revert ZeroAddress();
        if (_lockedResources == lockedResources) revert MustUpdateState();
        lockedResources = _lockedResources;
        emit LockedResourcesAddressUpdated(_lockedResources);
    }

    /**
     * @notice Called by contract owner to withdraw POW from this contract
     * @param _to Address to send POW to
     * @param _amount Amount of POW to send
     */
    function withdrawPOW(address _to, uint256 _amount) external onlyOwner {
        IERC20(pow).transfer(_to, _amount);
    }

    /**
     * @notice Called from PV Gaming backend to claim a Resource reward on behalf of a user
     * @dev Locks POW amount internally and redeems resources directly to user
     * @param _rewards Array of Reward claim requests with ResourceReward structure
     */
    function claimResourceRewards(
        ResourceReward[] calldata _rewards
    ) external onlyOwner {
        uint256 len = _rewards.length;

        for (uint i = 0; i < len; ) {
            ResourceReward calldata _reward = _rewards[i];

            uint256[] memory _amounts = assetPool.calcResourcesOutFromPOWIn(
                _reward.powIn, 
                _reward.resourceIds, 
                _reward.powSplitUp
            );

            IERC20(pow).transfer(address(assetPool), _reward.powIn);

            resources.safeBatchTransferFrom(
                address(assetPool),
                _reward.user,
                _reward.resourceIds,
                _amounts,
                ""
            );

            emit ResourceRewardClaimed(
                _reward.rewardId, 
                _reward.user, 
                _reward.powIn, 
                _reward.resourceIds, 
                _amounts
            );

            unchecked { 
                ++i; 
            }
        }
    }

    /**
     * @notice Called from PV Gaming backend to claim a Game Item reward on behalf of a user
     * @dev Locks POW amount and Resources internally and redeems Game Item directly to user
     * @param _rewards Array of Reward claim requests with GameItemReward structure
     */
    function claimGameItemRewards(
        GameItemReward[] calldata _rewards
    ) external onlyOwner {
        uint256 len = _rewards.length;

        for (uint i = 0; i < len; ) {
            GameItemReward calldata _reward = _rewards[i];

            uint256[] memory _amounts = assetPool.calcResourcesOutFromPOWIn(
                _reward.powIn, 
                _reward.resourceIds, 
                _reward.powSplitUp
            );

            uint256 _powFee = _reward.powIn * craftingFee / 1000000000000000000;
            IERC20(pow).transfer(address(assetPool), _reward.powIn - _powFee);

            crafting.craftGameItem(
                _reward.user, 
                _reward.powIn - _powFee,
                _reward.resourceIds, 
                _amounts, 
                _reward.itemId
            );

            emit GameItemRewardClaimed(
                _reward.rewardId,
                _reward.user, 
                _reward.powIn, 
                _reward.resourceIds, 
                _amounts, 
                _reward.itemId
            );
            unchecked {
                ++i;
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Balancer.sol";
import "./Resources.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

contract AssetPool is Ownable, ERC1155Holder {

    Resources private resources;
    address private pow;
    address private crafting;
    uint256 private powCoefficient;

    event ResourcesAddressSet(
        address indexed resourcesAddress
    );

    event PowCoefficientUpdated(
        uint256 indexed coefficient
    );

    event CraftingAddressSet(
        address indexed craftingAddress
    );

    error LengthMismatch();
    error NonexistantResource();
    error DuplicateFound();
    error RoundingError();
    error POWMismatch();
    error InvalidSender();
    error MustUpdateState();
    error ZeroAddress();
    error AddressAlreadySet();

    constructor(address _pow, uint256 _powCoefficient) {
        if (_pow == address(0)) revert ZeroAddress();
        pow = _pow;
        powCoefficient = _powCoefficient;
    }

    /**
     * @dev Called by contract owner in deploy script to set stored Resources contract address
     * @dev Can only be called once
     */
    function setResourcesAddress(address _resources) external onlyOwner {
        if (_resources == address(0)) revert ZeroAddress();
        if (address(resources) != address(0)) revert AddressAlreadySet();
        resources = Resources(_resources);
        emit ResourcesAddressSet(_resources);
    }

    /**
     * @notice Called by contract owner to update stored POW coefficient
     * @dev powCoefficient is used to set initial value in the Balancer pool
     * @param _newCoeff Value in wei
     */
    function updatePowCoefficient(uint256 _newCoeff) external onlyOwner {
        if (_newCoeff == powCoefficient) revert MustUpdateState();
        powCoefficient = _newCoeff;
        emit PowCoefficientUpdated(_newCoeff);
    }

    /**
     * @notice Called by contract owner to set stored address for Crafting contract
     * @param _crafting Address of Crafting contract
     */
    function setCraftingAddress(address _crafting) external onlyOwner {
        if (_crafting == address(0)) revert ZeroAddress();
        if (_crafting == crafting) revert MustUpdateState();
        crafting = _crafting;
        emit CraftingAddressSet(_crafting);
    }

    /**
     * @notice Called by contract owner to withdraw POW from this contract
     * @param _to Address to send POW to
     * @param _amount Amount of POW to send
     */
    function withdrawPOW(address _to, uint256 _amount) external onlyOwner {
        IERC20(pow).transfer(_to, _amount);
    }

    /**
     * @notice Called by Crafting contract to transfer $POW
     * @param _to Address to transfer $POW to
     * @param _amount Amount of $POW to transfer
     */
    function transfer(address _to, uint256 _amount) external {
        if (msg.sender != crafting) revert InvalidSender();
        IERC20(pow).transfer(_to, _amount);
    }

    /**
     * @notice Utility function to calculate how many units of certain resources can be bought with an amount of $POW
     * @param _powIn Total $POW value of resources earned
     * @param _internalResourceIds Array of resource IDs
     * @param _powSplitUp Individual POW amounts allocated to each resource (must add up to powIn)
     */
    function calcResourcesOutFromPOWIn(
        uint256 _powIn,
        uint256[] memory _internalResourceIds,
        uint256[] memory _powSplitUp
    ) external view returns (uint256[] memory) {
        uint256 len = _internalResourceIds.length;

        if (len != _powSplitUp.length) revert LengthMismatch();

        uint256 totalPOWUsed;
        uint256[] memory amounts = new uint256[](len);
        uint256[] memory idList = new uint256[](len);

        for (uint256 i = 0; i < len; ) {
            uint256 id = _internalResourceIds[i];

            if (
                !resources.exists(id)
            ) revert NonexistantResource();

            if (!idNotDuplicate(idList, id, i)) revert DuplicateFound();

            idList[i] = id;
            uint256 amountI = _powSplitUp[i];

            // Use Balancer equation to calculate how much of this Resource will
            // come out from this amount of POW being traded in
            amounts[i] = Balancer.outGivenIn(
                resources.balanceOf(address(this), id), //balanceO
                IERC20(pow).balanceOf(address(this)) + powCoefficient + totalPOWUsed, //balanceI
                amountI
            );

            if (amounts[i] == 0) revert RoundingError();
            totalPOWUsed += amountI;
            unchecked { ++i; }
        }
        // Check that total POW spent is equal to _powIn value in request
        if (totalPOWUsed != _powIn) revert POWMismatch();
        return amounts;
    }

    /**
     * @notice Utility function to calculate how much POW will be received after turning in a batch of resources
     * @param _internalResourceIds Array of resource IDs
     * @param _amountsIn Array of amounts of each resource being traded in
     */
    function calcPOWOutFromResourcesIn(
        uint256[] calldata _internalResourceIds,
        uint256[] calldata _amountsIn
    ) external view returns (uint256 amountPOW) {
        uint256 len = _internalResourceIds.length;
        if (len != _amountsIn.length) revert LengthMismatch();

        uint256[] memory idList = new uint256[](len);

        for (uint256 i = 0; i < len; ) {
            uint256 id = _internalResourceIds[i];

            if (
                !resources.exists(id)
            ) revert NonexistantResource();

            if (!idNotDuplicate(idList, id, i)) revert DuplicateFound();

            idList[i] = id;

            // Use Balancer equation to calculate how much POW will come out
            // from this Resource being traded in
            uint256 amountO = Balancer.outGivenIn(
                IERC20(pow).balanceOf(address(this)) + powCoefficient - amountPOW, // balanceO
                resources.balanceOf(address(this), id), // balanceI
                _amountsIn[i]
            );
            if (amountO == 0) revert RoundingError();
            amountPOW += amountO;
            unchecked { ++i; }
        }
    }

    /**
     * @notice Private utility function that returns true if no duplicates are found and false if a duplicate is found in an array
     * @param _idList Array of uint256s to check
     * @param _id ID that we are checking for duplicates of
     * @param len Integer representing how many elements to check in _idList
     */
    function idNotDuplicate(
        uint256[] memory _idList,
        uint256 _id,
        uint256 len
    ) private pure returns (bool) {
        for (uint256 i = 0; i < len; ) {
            if (_idList[i] == _id) return false;
            unchecked { 
                ++i; 
            }
        }
        return true;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./PvWhitelist.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

/**
 * @title Resources
 * @author Jack Chuma
 * @dev ERC1155 contract to represent Resources in the PV Gaming Ecosystem
 */
contract Resources is ERC1155, Ownable {

    address private assetPool;
    PVWhitelist private whitelistSource;

    // tokenId => boolean representing if id has been used or not
    mapping(uint256 => bool) public exists;

    struct Resource {
        uint256 id;
        uint256 totalSupply;
    }

    error ZeroAddress();
    error InvalidCaller();
    error LengthMismatch();
    error ResourceExists();
    error ZeroWhitelistSource();
    error MarketplaceNotWhitelisted();
    error MustUpdateState();

    event AssetPoolAddressUpdated(
        address indexed assetPoolAddress
    );

    modifier onlyWhitelisted(address _address) {
        if (!whitelistSource.isWhitelisted(_address))
            revert MarketplaceNotWhitelisted();
        _;
    }

    constructor(
        Resource[] memory _resources,
        string memory _uri,
        address _assetPool,
        address _whitelistSource
    ) ERC1155(_uri) {
        if (
            _assetPool == address(0) || 
            _whitelistSource == address(0)
        ) revert ZeroAddress();

        uint256 len = _resources.length;
        
        for (uint256 i = 0; i < len; ) {
            Resource memory res = _resources[i];
            if (exists[res.id]) revert ResourceExists();
            exists[res.id] = true;
            _mint(_assetPool, res.id, res.totalSupply, "");
            unchecked { ++i; }
        }
        assetPool = _assetPool;
        whitelistSource = PVWhitelist(_whitelistSource);
    }

    /**
     * @notice Called by contract owner to update base URI for Resources
     * @param _uri String representing new base URI
     */
    function setURI(string memory _uri) external onlyOwner {
        _setURI(_uri);
    }

    /**
     * @notice Called by contract owner to updated the stored address for Asset Pool contract
     * @dev Cannot be a zero address and must be different from address already stored in state
     * @param _assetPool New address for AssetPool contract
     */
    function updateAssetPoolAddress(address _assetPool) external onlyOwner {
        if (_assetPool == address(0)) revert ZeroAddress();
        if (_assetPool == assetPool) revert MustUpdateState();
        assetPool = _assetPool;
        emit AssetPoolAddressUpdated(_assetPool);
    }

    /**
     * @param _id ID of Resource
     * @return URI string for a specific token
     */
    function uri(
        uint256 _id
    ) public view override returns (string memory) {
        return string(abi.encodePacked(super.uri(_id), Strings.toString(_id)));
    }

    /**
     * @notice Called by contract owner to add new resources
     * @dev Mints new Resources to AssetPool contract
     * @dev Can only create resources that don't already exist
     * @param _resources Array of resources to add
     */
    function createResources(
        Resource[] calldata _resources
    ) external onlyOwner {
        uint256 len = _resources.length;
        for (uint256 i = 0; i < len; ) {
            Resource calldata res = _resources[i];

            if (exists[res.id]) revert ResourceExists();

            exists[res.id] = true;
            _mint(assetPool, res.id, res.totalSupply, "");

            unchecked { 
                ++i; 
            }
        }
    }

    /**
     * @notice Called by whitelisted address to burn a Resource
     * @param _from Address that owns Resource to burn
     * @param _id ID of Resource
     * @param _amount Amount of resource to burn
     */
    function burn(
        address _from, 
        uint256 _id,
        uint256 _amount
    ) external onlyWhitelisted(msg.sender) {
        _burn(_from, _id, _amount);
    }

    /**
     * @notice Called by whitelisted address to burn a batch of Resources
     * @param _from Address that owns Resources to burn
     * @param _ids Array of Resource IDs
     * @param _amounts Array of amounts of each Resource to burn
     */
    function burnBatch(
        address _from, 
        uint256[] calldata _ids,
        uint256[] calldata _amounts
    ) external onlyWhitelisted(msg.sender) {
        _burnBatch(_from, _ids, _amounts);
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     * @dev Only whitelisted addresses can be approved to transfer assets
     */
    function setApprovalForAll(
        address _operator, 
        bool _approved
    ) public virtual override onlyWhitelisted(_operator) {
        _setApprovalForAll(_msgSender(), _operator, _approved);
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     * @dev Whitelisted addresses are approved for transfers
     */
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _id,
        uint256 _amount,
        bytes memory _data
    ) public virtual override {
        require(
            _from == _msgSender() ||
                whitelistSource.isWhitelisted(_msgSender()) ||
                isApprovedForAll(_from, _msgSender()),
            "Res: invalid caller"
        );
        _safeTransferFrom(_from, _to, _id, _amount, _data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     * @dev Whitelisted addresses are approved for transfers
     */
    function safeBatchTransferFrom(
        address _from,
        address _to,
        uint256[] memory _ids,
        uint256[] memory _amounts,
        bytes memory _data
    ) public virtual override {
        require(
            _from == _msgSender() ||
                whitelistSource.isWhitelisted(_msgSender()) ||
                isApprovedForAll(_from, _msgSender()),
            "Res: invalid caller"
        );
        _safeBatchTransferFrom(_from, _to, _ids, _amounts, _data);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./GameItems.sol";
import "./Resources.sol";
import "./AssetPool.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Crafting
 * @author Jack Chuma
 * @dev Contract to facilitate crafting resources into game items in the PV Gaming Ecosystem
 */
contract Crafting is Ownable {

    uint256 private fee;
    address private rewards;
    address private lockedResources;
    GameItems private gameItems;
    Resources private resources;
    AssetPool private assetPool;

    // mapping from Game Item ID to data structure containing info about locked Resources in each Game Item
    mapping(uint256 => GameItem) private lockedValue;

    struct GameItem {
        uint256 pow;
        uint256[] resourceIds;
        uint256[] amounts;
    }

    struct SubscriptRequest {
        uint256 subscriptId;
        address user;
        uint256[] resourceIds;
        uint256[] amounts;
        uint256 itemId;
    }

    struct DestroyRequest {
        uint256 destroyId;
        address destroyer;
        address prey;
        address to;
        uint256 itemId;
    }

    error ZeroAddress();
    error InvalidCaller();
    error InvalidFee();
    error MustUpdateState();

    event Subscript(
        uint256 indexed subscriptId,
        address indexed user,
        uint256[] internalResourceIds,
        uint256[] resourceAmounts,
        uint256 indexed itemId
    );

    event Destroy(
        uint256 indexed destroyId,
        address indexed destroyer,
        address indexed prey,
        address to,
        uint256 itemId,
        uint256[] internalResourceIds,
        uint256[] amounts
    );

    event FeeUpdated(
        uint256 indexed fee
    );

    event RewardsAddressUpdated(
        address indexed rewardsAddress
    );

    event LockedResourcesAddressUpdated(
        address indexed lockedResourcesAddress
    );

    constructor(
        uint256 _fee, 
        address _rewards, 
        address _lockedResources, 
        address _gameItems, 
        address _resources,
        address _assetPool
    ) {
        if (
            _rewards == address(0) || 
            _lockedResources == address(0) || 
            _gameItems == address(0) || 
            _resources == address(0) || 
            _assetPool == address(0)
        ) revert ZeroAddress();
        if (_fee > 1000000000000000000) revert InvalidFee();

        fee = _fee;
        rewards = _rewards;
        lockedResources = _lockedResources;
        gameItems = GameItems(_gameItems);
        resources = Resources(_resources);
        assetPool = AssetPool(_assetPool);
    }

    /**
     * @notice Called by contract owner to update crafting fee
     * @dev Fee is a number between 0 and 10 ** 18 to be used as a percentage
     * @param _fee New fee value to be stored
     */
    function setFee(uint256 _fee) external onlyOwner {
        if (_fee > 1000000000000000000) revert InvalidFee();
        if (_fee == fee) revert MustUpdateState();
        fee = _fee;
        emit FeeUpdated(_fee);
    }

    /**
     * @notice Called by contract owner to update stored Rewards contract address
     * @param _rewards Address of Rewards contract
     */
    function updateRewardsAddress(address _rewards) external onlyOwner {
        if (_rewards == address(0)) revert ZeroAddress();
        if (_rewards == rewards) revert MustUpdateState();
        rewards = _rewards;
        emit RewardsAddressUpdated(_rewards);
    }

    /**
     * @notice Called by contract owner to update stored Locked Resources contract address
     * @param _lockedResources Address of LockedResources contract
     */
    function updateLockedResources(address _lockedResources) external onlyOwner {
        if (_lockedResources == address(0)) revert ZeroAddress();
        if (_lockedResources == lockedResources) revert MustUpdateState();
        lockedResources = _lockedResources;
        emit LockedResourcesAddressUpdated(_lockedResources);
    }

    /**
     * @notice Called by Rewards contract to fulfill a game item reward
     * @dev Locks resources and sends game item to user
     * @param _user Address of user who earned the reward
     * @param _powInMinusFee Value representing amount of POW locked in system represented by this game item after fee taken out
     * @param _resourceIds Array of resource IDs to be locked in game item
     * @param _amounts Array of amounts of each resource to be locked in game item
     * @param _itemId ID of game item to send to user
     */
    function craftGameItem(
        address _user,
        uint256 _powInMinusFee,
        uint256[] calldata _resourceIds,
        uint256[] calldata _amounts,
        uint256 _itemId
    ) external {
        if (msg.sender != rewards) revert InvalidCaller();

        resources.safeBatchTransferFrom(
            address(assetPool), 
            lockedResources, 
            _resourceIds, 
            _amounts, 
            ""
        );

        // Store how much POW and Resources are locked in Game Item
        GameItem storage item = lockedValue[_itemId];
        item.pow = _powInMinusFee;
        item.resourceIds = _resourceIds;
        item.amounts = _amounts;

        gameItems.safeTransferFrom(address(assetPool), _user, _itemId, 1, "");
    }

    /**
     * @notice Called by contract owner to subscript a game item for a user
     * @dev Locks resources and sends game item to user
     * @param _requests Array of subscript requests containing data in `SubscriptRequest` structure
     */
    function subscript(
        SubscriptRequest[] calldata _requests
    ) external onlyOwner {
        uint256 len = _requests.length;

        for (uint i = 0; i < len; ) {
            SubscriptRequest calldata _request = _requests[i];

            // calc POW out from Resources in
            uint256 powOut = assetPool.calcPOWOutFromResourcesIn(
                _request.resourceIds, 
                _request.amounts
            );

            // burn resources
            resources.safeBatchTransferFrom(
                _request.user, 
                lockedResources, 
                _request.resourceIds, 
                _request.amounts, 
                ""
            );

            // Calc fee using feePercentage
            uint256 powFee = powOut * fee / 1000000000000000000;

            // send POW fee from assetPool to Rewards contract
            assetPool.transfer(rewards, powFee);

            // store info about value locked in game item
            GameItem storage item = lockedValue[_request.itemId];
            item.resourceIds = _request.resourceIds;
            item.amounts = _request.amounts;
            item.pow = powOut - powFee;

            // send game items to user
            gameItems.safeTransferFrom(
                address(assetPool), 
                _request.user, 
                _request.itemId, 
                1, 
                ""
            );

            emit Subscript(
                _request.subscriptId, 
                _request.user, 
                _request.resourceIds, 
                _request.amounts, 
                _request.itemId
            );

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Called by contract owner to destroy a user's Game Item in exchange for the locked resources
     * @dev Burns game item and sends locked resources to `to` address
     * @param _requests Array of destroy for resources requests with `DestroyRequest` structure
     */
    function destroyForResources(
        DestroyRequest[] calldata _requests
    ) external onlyOwner {
        uint256 len = _requests.length;

        for (uint i = 0; i < len; ) {
            DestroyRequest calldata _request = _requests[i];

            // access info for locked resources
            GameItem memory _item = lockedValue[_request.itemId];

            //Burn Game Item
            gameItems.burn(_request.prey, _request.itemId);

            // Send locked resources to _request.destroyer
            resources.safeBatchTransferFrom(
                lockedResources, 
                _request.to, 
                _item.resourceIds, 
                _item.amounts, 
                ""
            );

            // If we're sending the resources back to AssetPool, return locked POW to Rewards contract
            if (_request.to == address(assetPool)) {
                assetPool.transfer(rewards, _item.pow);
            }

            emit Destroy(
                _request.destroyId,
                _request.destroyer, 
                _request.prey, 
                _request.to,
                _request.itemId, 
                _item.resourceIds, 
                _item.amounts
            );

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Called by contract owner to destroy a user's Game Item in exchange for the locked POW
     * @dev Burns game item and sends locked POW to `to` address
     * @param _requests Array of destroy for pow requests with `DestroyRequest` structure
     */
    function destroyForPow(
        DestroyRequest[] calldata _requests
    ) external onlyOwner {
        uint256 len = _requests.length;

        for (uint i = 0; i < len; ) {
            DestroyRequest calldata _request = _requests[i];

            // access info for locked resources
            GameItem memory _item = lockedValue[_request.itemId];

            //Burn Game Item
            gameItems.burn(_request.prey, _request.itemId);

            // If we're sending the POW back to Rewards, return locked Resources to AssetPool contract. Otherwise, burn resources
            if (_request.to == rewards) {
                // Send locked resources to AssetPool
                resources.safeBatchTransferFrom(
                    lockedResources, 
                    address(assetPool), 
                    _item.resourceIds, 
                    _item.amounts, 
                    ""
                );
            } else {
                resources.burnBatch(lockedResources, _item.resourceIds, _item.amounts);
            }

            assetPool.transfer(_request.to, _item.pow);

            emit Destroy(
                _request.destroyId,
                _request.destroyer, 
                _request.prey, 
                _request.to,
                _request.itemId, 
                _item.resourceIds, 
                _item.amounts
            );
            unchecked {
                ++i;
            }
        }
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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/**
 * @title Balancer
 * @author Jack Chuma
 * @dev Computes out-given-in amounts based on balancer trading formulas that maintain a ratio of tokens in a contract
 * @dev wI and wO currently omitted from this implementation since they will always be equal for MHU
 */
library Balancer {
    /*
     * aO - amount of token o being bought by trader
     * bO - balance of token o, the token being bought by the trader
     * bI - balance of token i, the token being sold by the trader
     * aI - amount of token i being sold by the trader
     * wI - the normalized weight of token i
     * wO - the normalized weight of token o
    */
    uint256 public constant BONE = 10 ** 18;

    /**********************************************************************************
    // Out-Given-In                                                                  //
    // aO = amountO                                                                  //
    // bO = balanceO                    /      /     bI        \    (wI / wO) \      //
    // bI = balanceI         aO = bO * |  1 - | --------------  | ^            |     //
    // aI = amountI                     \      \   bI + aI     /              /      //
    // wI = weightI                                                                  //
    // wO = weightO                                                                  //
    **********************************************************************************/
    function outGivenIn(
        uint256 balanceO,
        uint256 balanceI,
        uint256 amountI
    ) internal pure returns (uint256 amountO) {
        uint y = bdiv(balanceI, (balanceI + amountI));
        uint foo = BONE - y;
        amountO = bmul(balanceO, foo);
    }

    function bdiv(uint a, uint b)
        internal pure
        returns (uint)
    {
        uint c0 = a * BONE;
        uint c1 = c0 + (b / 2);
        uint c2 = c1 / b;
        return c2;
    }

    function bmul(uint a, uint b)
        internal pure
        returns (uint)
    {
        uint c0 = a * b;
        uint c1 = c0 + (BONE / 2);
        uint c2 = c1 / BONE;
        return c2;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;

import "./ERC1155Receiver.sol";

/**
 * Simple implementation of `ERC1155Receiver` that will allow a contract to hold ERC1155 tokens.
 *
 * IMPORTANT: When inheriting this contract, you must include a way to use the received tokens, otherwise they will be
 * stuck.
 *
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

contract PVWhitelist is Ownable {

    mapping(address => bool) public isWhitelisted;

    error MustChangeState();

    event ListModified(
        address indexed marketplace,
        bool isWhitelisted
    );

    /**
     * @notice Called by contract owner to modify PV whitelist
     * @param _whitelistAddress Address of marketplace to whitelist
     * @param _isWhitelisted Boolean representing whether or not address should be whitelisted
     */
    function modifyWhitelist(
        address _whitelistAddress, 
        bool _isWhitelisted
    ) external onlyOwner {
        if (isWhitelisted[_whitelistAddress] == _isWhitelisted) {
            revert MustChangeState();
        }
        isWhitelisted[_whitelistAddress] = _isWhitelisted;
        emit ListModified(_whitelistAddress, _isWhitelisted);
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/ERC1155.sol)

pragma solidity ^0.8.0;

import "./IERC1155.sol";
import "./IERC1155Receiver.sol";
import "./extensions/IERC1155MetadataURI.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
    using Address for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    constructor(string memory uri_) {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: address zero is not a valid owner");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not token owner nor approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not token owner nor approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
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
        require(owner != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `ids` and `amounts` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    /**
     * @dev Hook that is called after any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import "../IERC1155.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../IERC1155Receiver.sol";
import "../../../utils/introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./PvWhitelist.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

/**
 * @title Game Items
 * @author Jack Chuma
 * @dev Contract in PV Gaming Ecosystem used to represent in-game assets called Game Items
 */
contract GameItems is ERC1155, Ownable {

    address private assetPool;
    PVWhitelist private whitelistSource;
    uint256 public supply;

    error ZeroAddress();
    error MarketplaceNotWhitelisted();
    error MustUpdateState();

    event AssetPoolAddressUpdated(
        address indexed assetPoolAddress
    );

    /**
     * @dev Reverts if `_address` is not a whitelisted marketplace in the PV ecosystem
     */
    modifier onlyWhitelisted(address _address) {
        if (!whitelistSource.isWhitelisted(_address))
            revert MarketplaceNotWhitelisted();
        _;
    }

    constructor(
        uint256 _totalSupply,
        string memory _uri,
        address _assetPool,
        address _whitelistSource
    ) ERC1155(_uri) {
        if (
            _assetPool == address(0) || 
            _whitelistSource == address(0)
        ) revert ZeroAddress();

        uint256[] memory ids = new uint256[](_totalSupply);
        uint256[] memory amounts = new uint256[](_totalSupply);

        for (uint i = 0; i < _totalSupply; ) {
            ids[i] = i+1;
            amounts[i] = 1;

            unchecked {
                ++i;
            }
        }
        _mintBatch(_assetPool, ids, amounts, "");

        assetPool = _assetPool;
        whitelistSource = PVWhitelist(_whitelistSource);
        supply = _totalSupply;
    }

    /**
     * @notice Called by contract owner to updated the stored address for Asset Pool contract
     * @dev Cannot be a zero address and must be different from address already stored in state
     * @param _assetPool New address for AssetPool contract
     */
    function updateAssetPoolAddress(address _assetPool) external onlyOwner {
        if (_assetPool == address(0)) revert ZeroAddress();
        if (_assetPool == assetPool) revert MustUpdateState();
        assetPool = _assetPool;
        emit AssetPoolAddressUpdated(_assetPool);
    }

    /**
     * @notice Called by contract owner to update base URI for Game Items
     * @param _uri String representing new base URI
     */
    function setURI(string memory _uri) external onlyOwner {
        _setURI(_uri);
    }

    /**
     * @notice Called by contract owner to create new Items
     * @param _amount Amount of items to create and mint to Asset Pool contract
     */
    function createItems(uint256 _amount) external onlyOwner {
        address _assetPool = assetPool;
        uint256 _supply = supply;

        uint256[] memory ids = new uint256[](_amount);
        uint256[] memory amounts = new uint256[](_amount);

        for (uint i = _supply; i < _supply + _amount; ) {
            ids[i - _supply] = i+1;
            amounts[i - _supply] = 1;

            unchecked {
                ++i;
            }
        }
        _mintBatch(_assetPool, ids, amounts, "");
        supply += _amount;
    }

    /**
     * @param _tokenId ID of Game Item
     * @return URI string for a specific token
     */
    function uri(uint256 _tokenId) public view override returns (string memory) {
        return
            string(
                abi.encodePacked(super.uri(_tokenId), Strings.toString(_tokenId))
            );
    }

    /**
     * @notice Called by whitelisted address to burn a specific Game Item
     * @dev Assumes amount of tokens to burn is 1
     * @param _from Address that owns Game Item to burn
     * @param _id ID of Game Item
     */
    function burn(
        address _from, 
        uint256 _id
    ) external onlyWhitelisted(msg.sender) {
        _burn(_from, _id, 1);
    }

    /**
     * @notice Called by whitelisted address to burn a batch of Game Items
     * @param _from Address that owns Game Items to burn
     * @param _ids Array of Game Item IDs
     * @param _amounts Array of amounts of each Game Item to burn - should be an array of 1's
     */
    function burnBatch(
        address _from, 
        uint256[] calldata _ids,
        uint256[] calldata _amounts
    ) external onlyWhitelisted(msg.sender) {
        _burnBatch(_from, _ids, _amounts);
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     * @dev only whitelisted addresses can be approved to transfer assets
     */
    function setApprovalForAll(address _operator, bool _approved)
        public
        virtual
        override
        onlyWhitelisted(_operator)
    {
        _setApprovalForAll(_msgSender(), _operator, _approved);
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     * @dev Whitelisted addresses have ability to transfer assets
     */
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _id,
        uint256 _amount,
        bytes memory _data
    ) public virtual override {
        require(
            _from == _msgSender() ||
                whitelistSource.isWhitelisted(_msgSender()) ||
                isApprovedForAll(_from, _msgSender()),
            "Items: invalid caller"
        );
        _safeTransferFrom(_from, _to, _id, _amount, _data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     * @dev Whitelisted addresses have ability to transfer assets
     */
    function safeBatchTransferFrom(
        address _from,
        address _to,
        uint256[] memory _ids,
        uint256[] memory _amounts,
        bytes memory _data
    ) public virtual override {
        require(
            _from == _msgSender() ||
                whitelistSource.isWhitelisted(_msgSender()) ||
                isApprovedForAll(_from, _msgSender()),
            "Items: invalid caller"
        );
        _safeBatchTransferFrom(_from, _to, _ids, _amounts, _data);
    }
}