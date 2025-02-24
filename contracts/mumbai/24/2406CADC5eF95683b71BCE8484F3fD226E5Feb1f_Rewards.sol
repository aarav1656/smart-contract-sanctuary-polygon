// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./AssetPool.sol";
import "./Resources.sol";
import "./Crafting.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract Rewards is Ownable {
    using ECDSA for bytes32;

    address private pow;
    address private lockedResources;
    uint256 private craftingFee;
    AssetPool public assetPool;
    Resources private resources;
    Crafting private crafting;

    // mapping from address to individual transaction nonce for replay protection
    mapping(address => uint256) public txNonces;

    error NoReplay();
    error InvalidFee();
    error ZeroAddress();
    error InvalidSender();
    error InvalidSignature();

    event ResourceReward(
        address indexed user,
        uint256 indexed nonce,
        uint256 powIn,
        uint256[] resourceIds,
        uint256[] amounts
    );

    event GameItemReward(
        address indexed user,
        uint256 indexed nonce,
        uint256 powIn,
        uint256[] resourceIds,
        uint256[] amounts,
        uint256 itemId
    );

    constructor(address _pow, address _lockedResources, uint256 _craftingFee) {
        if (_pow == address(0) || _lockedResources == address(0)) revert ZeroAddress();
        if (_craftingFee > 1000000000000000000) revert InvalidFee();
        pow = _pow;
        assetPool = new AssetPool(_pow);
        lockedResources = _lockedResources;
        craftingFee = _craftingFee;
    }

    // Function to receive Ether. msg.data must be empty
    // solhint-disable-next-line
    receive() external payable {}

    // Fallback function is called when msg.data is not empty
    fallback() external payable {}

    function setCraftingFee(uint256 _fee) external onlyOwner {
        if (_fee > 1000000000000000000) revert InvalidFee();
        craftingFee = _fee;
    }

    function setResourcesAddress(address _resources) external onlyOwner {
        if (_resources == address(0)) revert ZeroAddress();
        resources = Resources(_resources);
        assetPool.setResourcesAddress(_resources);
    }

    function setCraftingAddress(address _crafting) external onlyOwner {
        if (_crafting == address(0)) revert ZeroAddress();
        crafting = Crafting(_crafting);
        assetPool.setCraftingAddress(_crafting);
    }

    function withdrawPOW(address to, uint256 amount) external onlyOwner {
        IERC20(pow).transfer(to, amount);
    }

    function claimResourceReward(
        bytes calldata signature,
        uint256 nonce,
        address requestor,
        uint256 powIn,
        uint256[] calldata resourceIds,
        uint256[] calldata powSplitUp,
        uint256[] calldata minAmountsOut
    ) external onlyOwner {
        _replayProtection(requestor, nonce);
        // verify that signature is from contract owner
        if (
            !verifyResourceReward(
                signature, 
                nonce, 
                requestor, 
                powIn, 
                resourceIds, 
                powSplitUp
            )
        ) revert InvalidSignature();

        uint256[] memory amounts = assetPool.calcResourcesOutFromPOWIn(
            powIn, 
            resourceIds, 
            powSplitUp, 
            minAmountsOut
        );

        IERC20(pow).transfer(address(assetPool), powIn);

        resources.safeBatchTransferFrom(
            address(assetPool),
            requestor,
            resourceIds,
            amounts,
            ""
        );

        emit ResourceReward(requestor, nonce, powIn, resourceIds, amounts);
    }

    function claimGameItemReward(
        bytes calldata sig,
        uint256 nonce,
        address requestor,
        uint256 powIn,
        uint256[] calldata resourceIds,
        uint256[] calldata powSplitUp,
        uint256[] memory minResourceAmountsOut,
        uint256 itemId
    ) external onlyOwner {
        // EIP-191 validation
        _replayProtection(requestor, nonce);
        // verify that signature is from contract owner
        if (
            !verifyGameItemReward(
                sig, 
                nonce, 
                requestor, 
                powIn, 
                resourceIds, 
                powSplitUp, 
                itemId
            )
        ) revert InvalidSignature();

        uint256[] memory amounts = assetPool.calcResourcesOutFromPOWIn(
            powIn, 
            resourceIds, 
            powSplitUp, 
            minResourceAmountsOut
        );

        uint256 powFee = powIn * craftingFee / 1000000000000000000;
        IERC20(pow).transfer(address(assetPool), powIn - powFee);

        crafting.craftGameItem(
            requestor, 
            powIn-powFee,
            resourceIds, 
            amounts, 
            itemId
        );

        emit GameItemReward(
            requestor, 
            nonce, 
            powIn, 
            resourceIds, 
            amounts, 
            itemId
        );
    }

    /**
     * @dev Private utility function for EIP-191 that protects against replay attacks
     */
    function _replayProtection(address requestor, uint256 nonce) private {
        // protects against a user submitting a valid signature from someone else's reward request
        // if (msg.sender != requestor) revert InvalidSender();
        // protects against a user submitting a valid signature more than once
        if (txNonces[requestor] + 1 != nonce) revert NoReplay();
        // increment nonce for msg.sender
        ++txNonces[requestor];
    }

    /**
     * @dev Utility function to verify that signature is from contract owner
     */
    function verifyResourceReward(
        bytes calldata signature,
        uint256 nonce,
        address requestor,
        uint256 powIn,
        uint256[] calldata internalResourceIds,
        uint256[] calldata powSplitUp
    ) private view returns (bool) {
        bytes32 hash = keccak256(
            abi.encodePacked(
                nonce, 
                requestor, 
                powIn, 
                internalResourceIds, 
                powSplitUp
            )
        );
        return hash.toEthSignedMessageHash().recover(signature) == owner();
    }

    /**
     * @dev Utility function to verify that signature is from contract owner
     */
    function verifyGameItemReward(
        bytes calldata signature,
        uint256 nonce,
        address requestor,
        uint256 powIn,
        uint256[] memory internalResourceIds,
        uint256[] memory powSplitUp,
        uint256 itemId
    ) private view returns (bool) {
        bytes32 hash = keccak256(
            abi.encodePacked(
                nonce, 
                requestor, 
                powIn, 
                internalResourceIds, 
                powSplitUp, 
                itemId
            )
        );
        return hash.toEthSignedMessageHash().recover(signature) == owner();
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

    uint128 private constant POW_CONSTANT = 100 * 10**18;

    Resources private resources;
    address private pow;
    address private crafting;

    error LengthMismatch();
    error NonexistantResource();
    error DuplicateFound();
    error SlippageExceeded();
    error RoundingError();
    error POWMismatch();
    error InvalidSender();

    constructor(address _pow) {
        pow = _pow;
    }

    function setResourcesAddress(address _resources) external onlyOwner {
        resources = Resources(_resources);
    }

    /**
     * @notice Called by contract owner to set stored address for Crafting contract
     * @param _crafting Address of Crafting contract
     */
    function setCraftingAddress(address _crafting) external onlyOwner {
        crafting = _crafting;
    }

    function withdrawPOW(address to, uint256 amount) external onlyOwner {
        IERC20(pow).transfer(to, amount);
    }

    /**
     * @notice Called by Crafting contract to transfer $POW
     * @param to Address to transfer $POW to
     * @param amount Amount of $POW to transfer
     */
    function transfer(address to, uint256 amount) external {
        if (msg.sender != crafting) revert InvalidSender();
        IERC20(pow).transfer(to, amount);
    }

    /**
     * @notice Utility function to calculate how many units of certain resources can be bought with an amount of $POW
     * @param powIn Total $POW value of resources earned
     * @param internalResourceIds Array of resource IDs
     * @param powSplitUp Individual POW amounts allocated to each resource (must add up to powIn)
     * @param minAmountsOut Array of minimum amounts expected out for each Resource to protect against slippage
     */
    function calcResourcesOutFromPOWIn(
        uint256 powIn,
        uint256[] memory internalResourceIds,
        uint256[] memory powSplitUp,
        uint256[] memory minAmountsOut
    ) public view returns (uint256[] memory) {
        uint256 len = internalResourceIds.length;

        if (
            len != powSplitUp.length || 
            len != minAmountsOut.length
        ) revert LengthMismatch();

        uint256 totalPOWUsed;
        uint256[] memory amounts = new uint256[](len);
        uint256[] memory idList = new uint256[](len);

        for (uint256 i = 0; i < len; ) {
            uint256 id = internalResourceIds[i];

            if (
                !resources.exists(id)
            ) revert NonexistantResource();

            if (!idNotDuplicate(idList, id, i)) revert DuplicateFound();

            idList[i] = id;
            uint256 amountI = powSplitUp[i];

            // Use Balancer equation to calculate how much of this Resource will
            // come out from this amount of POW being traded in
            amounts[i] = Balancer.outGivenIn(
                resources.balanceOf(address(this), id), //balanceO
                IERC20(pow).balanceOf(address(this)) + POW_CONSTANT + totalPOWUsed, //balanceI
                amountI
            );

            if (amounts[i] < minAmountsOut[i]) revert SlippageExceeded();
            if (amounts[i] == 0) revert RoundingError();
            totalPOWUsed += amountI;
            unchecked { ++i; }
        }
        // Check that total POW spent is equal to powIn value in request
        if (totalPOWUsed != powIn) revert POWMismatch();
        return amounts;
    }

    /**
     * @notice Utility function to calculate how much $POW will be received after turning in a batch of resources
     * @param internalResourceIds Array of resource IDs
     * @param amountsIn Array of amounts of each resource being traded in
     */
    function calcPOWOutFromResourcesIn(
        uint256[] calldata internalResourceIds,
        uint256[] calldata amountsIn
    ) external view returns (uint256 amountPOW) {
        uint256 len = internalResourceIds.length;
        if (len != amountsIn.length) revert LengthMismatch();

        uint256[] memory idList = new uint256[](len);

        for (uint256 i = 0; i < len; ) {
            uint256 id = internalResourceIds[i];

            if (
                !resources.exists(id)
            ) revert NonexistantResource();

            if (!idNotDuplicate(idList, id, i)) revert DuplicateFound();

            idList[i] = id;

            // Use Balancer equation to calculate how much POW will come out
            // from this Resource being traded in
            uint256 amountO = Balancer.outGivenIn(
                IERC20(pow).balanceOf(address(this)) + POW_CONSTANT - amountPOW, // balanceO
                resources.balanceOf(address(this), id), // balanceI
                amountsIn[i]
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
 * @dev ERC1155 contract to represent $Resources in the PV Gaming Ecosystem
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

    function setURI(string memory _uri) external onlyOwner {
        _setURI(_uri);
    }

    function uri(
        uint256 _id
    ) public view override returns (string memory) {
        return string(abi.encodePacked(super.uri(_id), Strings.toString(_id)));
    }

    /**
     * @notice Called by contract owner to add new resources
     * @dev Assigns new ID to planet / resource combo then mints to ResourcePool contract
     * @dev Can only create resources that don't already exist
     * @param _resources Array of resources to add
     */
    function createResources(
        Resource[] calldata _resources
    ) external onlyOwner {
        uint256 len = _resources.length;
        for (uint256 i = 0; i < len; ) {
            uint256 id;
            Resource calldata res = _resources[i];

            if (exists[res.id]) revert ResourceExists();

            exists[res.id] = true;
            _mint(assetPool, id, res.totalSupply, "");

            unchecked { 
                ++i; 
            }
        }
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     * @dev Only whitelisted addresses can be approved to transfer assets
     */
    function setApprovalForAll(
        address operator, 
        bool approved
    ) public virtual override onlyWhitelisted(operator) {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     * @dev Whitelisted addresses are approved for transfers
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() ||
                whitelistSource.isWhitelisted(_msgSender()) ||
                isApprovedForAll(from, _msgSender()),
            "Res: invalid caller"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     * @dev Whitelisted addresses are approved for transfers
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() ||
                whitelistSource.isWhitelisted(_msgSender()) ||
                isApprovedForAll(from, _msgSender()),
            "Res: invalid caller"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Whitelisted marketplaces have ability to burn Game Items
     * @dev Assumes amount of tokens to burn is 1
     * @param from Address that owns Game Item to burn
     * @param id ID of Game Item
     */
    function burn(
        address from, 
        uint256 id
    ) external onlyWhitelisted(msg.sender) {
        _burn(from, id, 1);
    }

    /**
     * @notice Called by whitelisted address to burn a batch of Game Items
     * @param from Address that owns Game Items to burn
     * @param ids Array of Game Item IDs
     * @param amounts Array of amounts of each Game Item to burn - should be an array of 1's
     */
    function burnBatch(
        address from, 
        uint256[] calldata ids,
        uint256[] calldata amounts
    ) external onlyWhitelisted(msg.sender) {
        _burnBatch(from, ids, amounts);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./GameItems.sol";
import "./Resources.sol";
import "./AssetPool.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract Crafting is Ownable {
    using ECDSA for bytes32;

    uint256 private fee;
    address private rewards;
    address private lockedResources;
    GameItems private gameItems;
    Resources private resources;
    AssetPool private assetPool;

    // mapping from address to individual transaction nonce for replay protection
    mapping(address => uint256) public txNonces;

    // mapping from Game Item ID to data structure containing info about locked Resources in each Game Item
    mapping(uint256 => GameItem) private lockedValue;

    struct GameItem {
        uint256 pow;
        uint256[] resourceIds;
        uint256[] amounts;
    }

    error ZeroAddress();
    error InvalidCaller();
    error InvalidFee();
    error NoReplay();
    error InvalidSignature();

    event Subscript(
        address indexed user,
        uint256 indexed nonce,
        uint256[] internalResourceIds,
        uint256[] resourceAmounts,
        uint256 indexed itemId
    );

    event Destroy(
        address indexed destroyer,
        uint256 indexed nonce,
        address indexed prey,
        address to,
        uint256 itemId,
        uint256[] internalResourceIds,
        uint256[] amounts
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

    function craftGameItem(
        address user,
        uint256 powInMinusFee,
        uint256[] calldata resourceIds,
        uint256[] calldata amounts,
        uint256 itemId
    ) external {
        if (msg.sender != rewards) revert InvalidCaller();

        resources.safeBatchTransferFrom(
            address(assetPool), 
            lockedResources, 
            resourceIds, 
            amounts, 
            ""
        );

        // Store how much POW and Resources are locked in Game Item
        GameItem storage item = lockedValue[itemId];
        item.pow = powInMinusFee;
        item.resourceIds = resourceIds;
        item.amounts = amounts;

        gameItems.safeTransferFrom(address(assetPool), user, itemId, 1, "");
    }

    function subscript(
        bytes calldata signature,
        uint256 nonce,
        address requestor,
        uint256[] calldata resourceIds,
        uint256[] calldata amounts,
        uint256 itemId
    ) external onlyOwner {
        // EIP-191 validataion
        _replayProtection(requestor, nonce);
        // verify that signature is from contract owner
        if (
            !_verifySubscript(
                signature, 
                nonce, 
                requestor, 
                resourceIds, 
                amounts, 
                itemId
            )
        ) revert InvalidSignature();

        // calc POW out from Resources in
        uint256 powOut = assetPool.calcPOWOutFromResourcesIn(
            resourceIds, 
            amounts
        );

        // burn resources
        resources.safeBatchTransferFrom(
            requestor, 
            lockedResources, 
            resourceIds, 
            amounts, 
            ""
        );

        // Calc fee using feePercentage
        uint256 powFee = powOut * fee / 1000000000000000000;

        // send POW fee from assetPool to Rewards contract
        assetPool.transfer(rewards, powFee);

        // store info about value locked in game item
        GameItem storage item = lockedValue[itemId];
        item.resourceIds = resourceIds;
        item.amounts = amounts;
        item.pow = powOut - powFee;

        // send game items to user
        gameItems.safeTransferFrom(
            address(assetPool), 
            requestor, 
            itemId, 
            1, 
            ""
        );

        emit Subscript(requestor, nonce, resourceIds, amounts, itemId);
    }

    /**
     * @notice Called by user during gameplay to destroy another user's Game Item
     * @dev Sends locked Resources from Game Item to the destroyer
     * @param sig Signature on input data from contract owner
     * @param nonce Tx count for `msg.sender`
     * @param destroyer Game ecosystem user that destroyed another user's Game Item
     * @param prey Game ecosystem user that was ATTACKED
     * @param itemId ID of Game Item to be destroyed
     */
    function destroyForResources(
        bytes calldata sig,
        uint256 nonce,
        address destroyer,
        address prey,
        address to,
        uint256 itemId
    ) external onlyOwner {
        // EIP-191 Validation
        _replayProtection(destroyer, nonce);
        // verify that signature is from contract owner
        if (
            !_verifyDestruction(
                sig, 
                nonce, 
                destroyer, 
                prey, 
                to,
                itemId
            )
        ) revert InvalidSignature();

        // access info for locked resources
        GameItem memory item = lockedValue[itemId];

        //Burn Game Item
        gameItems.burn(prey, itemId);

        // Send locked resources to destroyer
        resources.safeBatchTransferFrom(
            lockedResources, 
            to, 
            item.resourceIds, 
            item.amounts, 
            ""
        );

        // If we're sending the resources back to AssetPool, return locked POW to Rewards contract
        if (to == address(assetPool)) {
            assetPool.transfer(rewards, item.pow);
        }

        emit Destroy(
            destroyer, 
            nonce, 
            prey, 
            to,
            itemId, 
            item.resourceIds, 
            item.amounts
        );
    }

    function destroyForPow(
        bytes calldata sig,
        uint256 nonce,
        address destroyer,
        address prey,
        address to,
        uint256 itemId
    ) external onlyOwner {
        // EIP-191 Validation
        _replayProtection(destroyer, nonce);
        // verify that signature is from contract owner
        if (
            !_verifyDestruction(
                sig, 
                nonce, 
                destroyer, 
                prey, 
                to,
                itemId
            )
        ) revert InvalidSignature();

        // access info for locked resources
        GameItem memory item = lockedValue[itemId];

        //Burn Game Item
        gameItems.burn(prey, itemId);

        // If we're sending the POW back to Rewards, return locked Resources to AssetPool contract. Otherwise, burn resources
        if (to == rewards) {
            // Send locked resources to AssetPool
            resources.safeBatchTransferFrom(
                lockedResources, 
                address(assetPool), 
                item.resourceIds, 
                item.amounts, 
                ""
            );
        } else {
            resources.burnBatch(lockedResources, item.resourceIds, item.amounts);
        }

        assetPool.transfer(to, item.pow);

        emit Destroy(
            destroyer, 
            nonce, 
            prey, 
            to,
            itemId, 
            item.resourceIds, 
            item.amounts
        );
    }

    /**
     * @dev Private helper function for EIP-191 that protects against replay attacks
     */
    function _replayProtection(address requestor, uint256 nonce) private {
        // protects against a user submitting a valid signature from someone else's reward request
        // if (msg.sender != requestor) revert InvalidSender();
        // protects against a user submitting a valid signature more than once
        if (txNonces[requestor] + 1 != nonce) revert NoReplay();
        // increment nonce for msg.sender
        ++txNonces[requestor];
    }

    /**
     * @dev Utility function to verify that signature is from contract owner
     */
    function _verifySubscript(
        bytes calldata signature,
        uint256 nonce,
        address requestor,
        uint256[] memory internalResourceIds,
        uint256[] memory amounts,
        uint256 itemId
    ) private view returns (bool) {
        bytes32 hash = keccak256(
            abi.encodePacked(
                nonce, 
                requestor, 
                internalResourceIds, 
                amounts, 
                itemId
            )
        );
        return hash.toEthSignedMessageHash().recover(signature) == owner();
    }

    /**
     * @dev Utility function to verify that signature is from contract owner
     */
    function _verifyDestruction(
        bytes calldata signature,
        uint256 nonce,
        address destroyer,
        address prey,
        address to,
        uint256 itemId
    ) private view returns (bool) {
        bytes32 hash = keccak256(
            abi.encodePacked(
                nonce, 
                destroyer, 
                prey, 
                to,
                itemId
            )
        );
        return hash.toEthSignedMessageHash().recover(signature) == owner();
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

    address private pow;
    address private assetPool;
    PVWhitelist private whitelistSource;
    uint256 public supply;

    error ZeroAddress();
    error MarketplaceNotWhitelisted();

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
        address _pow,
        address _assetPool,
        address _whitelistSource
    ) ERC1155(_uri) {
        if (
            _pow == address(0) || 
            _assetPool == address(0) || 
            _whitelistSource == address(0)
        ) revert ZeroAddress();
        
        for (uint256 i = 0; i < _totalSupply; ) {
            _mint(_assetPool, i+1, 1, "");
            unchecked {
                ++i;
            }
        }
        assetPool = _assetPool;
        pow = _pow;
        whitelistSource = PVWhitelist(_whitelistSource);
        supply = _totalSupply;
    }

    /**
     * @notice Called by contract owner to create new Items
     */
    function createItems(uint256 _amount) external onlyOwner {
        address _assetPool = assetPool;
        for (uint256 i = supply; i < _amount; ) {
            _mint(_assetPool, i+1, 1, "");
            unchecked {
                ++i;
            }
        }
        supply += _amount;
    }

    /**
     * @dev Returns the uri string for a specific token
     * @param tokenId ID of Game Item
     */
    function uri(uint256 tokenId) public view override returns (string memory) {
        return
            string(
                abi.encodePacked(super.uri(tokenId), Strings.toString(tokenId))
            );
    }

    /**
     * @dev Whitelisted marketplaces have ability to burn Game Items
     * @dev Assumes amount of tokens to burn is 1
     * @param from Address that owns Game Item to burn
     * @param id ID of Game Item
     */
    function burn(
        address from, 
        uint256 id
    ) external onlyWhitelisted(msg.sender) {
        _burn(from, id, 1);
    }

    /**
     * @notice Called by whitelisted address to burn a batch of Game Items
     * @param from Address that owns Game Items to burn
     * @param ids Array of Game Item IDs
     * @param amounts Array of amounts of each Game Item to burn - should be an array of 1's
     */
    function burnBatch(
        address from, 
        uint256[] calldata ids,
        uint256[] calldata amounts
    ) external onlyWhitelisted(msg.sender) {
        _burnBatch(from, ids, amounts);
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     * @dev only whitelisted addresses can be approved to transfer assets
     */
    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override
        onlyWhitelisted(operator)
    {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     * @dev Whitelisted addresses have ability to transfer assets
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() ||
                whitelistSource.isWhitelisted(_msgSender()) ||
                isApprovedForAll(from, _msgSender()),
            "Items: invalid caller"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     * @dev Whitelisted addresses have ability to transfer assets
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() ||
                whitelistSource.isWhitelisted(_msgSender()) ||
                isApprovedForAll(from, _msgSender()),
            "Items: invalid caller"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }
}