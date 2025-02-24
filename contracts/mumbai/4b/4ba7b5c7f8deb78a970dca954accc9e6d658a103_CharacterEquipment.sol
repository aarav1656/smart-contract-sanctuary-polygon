// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./GameBase.sol";
import "../Character.sol";
import "../interfaces/ICharacterEquipment.sol";

contract CharacterEquipment is ICharacterEquipment, GameBase {
    constructor(address game)
    GameBase(game) {
    }

    function canEquip(uint256 worldId, uint256 tokenId, uint256[] calldata itemIds) external view override returns(bool) {
        Character character = getCharacter(worldId, tokenId);
        CharacterDefinition characterDefinition = character.characterDefinition();
        uint256 characterDefinitionId = character.characterDefinitionId();
        uint256[] memory equipments = character.getEquipments();

        for (uint256 equipmentSlotIndex; equipmentSlotIndex < itemIds.length; equipmentSlotIndex++) {
            uint256 itemId = itemIds[equipmentSlotIndex];
            int64 itemCount = character.items(itemId);
            uint256 oldItemId = equipments[equipmentSlotIndex];

            if (!characterDefinition.isValidEquipmentSlot(characterDefinitionId, equipmentSlotIndex) ||
            (itemCount < 1 && itemId != 0 && oldItemId != itemId) || !characterDefinition.canEquip(characterDefinitionId, itemId, equipmentSlotIndex)) {
                return false;
            }
        }

        return true;
    }

    // TODO: add access control modifier
    function equip(uint256 worldId, uint256 tokenId, uint256[] calldata itemIds) external override {
        require(this.canEquip(worldId, tokenId, itemIds), "Cannot equip item");

        Character character = getCharacter(worldId, tokenId);
        character.setEquipments(itemIds);

        emit Equip(worldId, tokenId, itemIds);
    }

    function getEquipments(uint256 worldId, uint256 tokenId) external view override returns(uint256[] memory) {
        Character character = getCharacter(worldId, tokenId);

        return character.getEquipments();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../Game.sol";
import "../World.sol";
import "../Character.sol";

contract GameBase {
    Game internal _game;

    constructor(address game) {
        _game = Game(game);
    }

    function getWorld(uint256 worldId) internal view virtual returns(World) {
        return _game.worlds(worldId);
    }

    function getCharacter(uint256 worldId, uint256 tokenId) internal view virtual returns(Character) {
        World world = getWorld(worldId);
        return world.characters(tokenId);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./CharacterDefinition.sol";

contract Character {
    uint256 public worldId;
    uint256 public tokenId;
    uint256 public characterDefinitionId;
    // key: statusSlotIndex, value: itemId
    mapping(uint256 => int64) public statuses;
    // key: equipmentSlotIndex, value: itemId
    mapping(uint256 => uint256) public equipments;
    // key: itemId, value: itemCount
    mapping(uint256 => int64) public items;
    CharacterDefinition public characterDefinition;

    constructor(uint256 worldId_, uint256 tokenId_, uint256 characterDefinitionId_, address characterDefinition_) {
        worldId = worldId_;
        tokenId = tokenId_;
        characterDefinitionId = characterDefinitionId_;
        characterDefinition = CharacterDefinition(characterDefinition_);
    }

    function addItem(uint256 itemId, int64 value) public virtual {
        // TODO: check itemId
        items[itemId] += value;
    }

    function setEquipments(uint256[] memory itemIds) public virtual {
        for (uint256 equipmentSlotIndex; equipmentSlotIndex < itemIds.length; equipmentSlotIndex++) {
            uint256 itemId = itemIds[equipmentSlotIndex];
            uint256 oldItemId = equipments[equipmentSlotIndex];

            require(characterDefinition.isValidEquipmentSlot(characterDefinitionId, equipmentSlotIndex), "invalid propertyId");
            require(itemId == 0 || items[itemId] > 0, "No items");
            require(itemId == 0 || characterDefinition.canEquip(characterDefinitionId, itemId, equipmentSlotIndex), "Cannot equip");

            if (itemId > 0) {
                items[itemId] -= 1;
            }
            equipments[equipmentSlotIndex] = itemId;
            if (oldItemId > 0) {
                items[oldItemId] += 1;
            }
        }
    }

    function getEquipments() public virtual view returns(uint256[] memory) {
        CharacterDefinition.EquipmentSlot[] memory propertyTypes = characterDefinition.getEquipmentSlots(characterDefinitionId);
        uint256[] memory result = new uint256[](propertyTypes.length);
        for (uint256 i; i < propertyTypes.length; i++) {
            result[i] = equipments[i];
        }

        return result;
    }

    function setStatus(uint256 statusSlotIndex, int64 value) public virtual {
        uint256[] memory statusSlots = characterDefinition.getStatusSlots(characterDefinitionId);
        uint256 itemId = statusSlots[statusSlotIndex];

        require(characterDefinition.isValidStatusSlot(characterDefinitionId, statusSlotIndex, itemId), "invalid statusSlotIndex");
        require(itemId != 0 || items[itemId] > value, "No items");

        items[itemId] -= value;
        statuses[statusSlotIndex] += value;
    }

    function getStatuses() public virtual view returns(int64[] memory) {
        uint256[] memory statusSlots = characterDefinition.getStatusSlots(characterDefinitionId);

        int64[] memory result = new int64[](statusSlots.length);
        for (uint256 i; i < statusSlots.length; i++) {
            result[i] = statuses[i];
        }

        return result;
    }

    function getItems(uint256[] memory itemIds) public virtual view returns(int64[] memory) {
        int64[] memory result = new int64[](itemIds.length);
        for (uint256 i; i < itemIds.length; i++) {
            result[i] = items[itemIds[i]];
        }

        return result;
    }

    function hasItem(uint256 itemId, int64 amount) public virtual view returns(bool) {
        return items[itemId] >= amount;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface ICharacterEquipment {
    event Equip(uint256 indexed worldId, uint256 indexed tokenId, uint256[] itemIds);

    function equip(uint256 worldId, uint256 tokenId, uint256[] calldata itemIds) external;

    function canEquip(uint256 worldId, uint256 tokenId, uint256[] calldata itemIds) external view returns(bool);

    // Returns an array of Equipment ItemId
    function getEquipments(uint256 worldId, uint256 tokenId) external view returns(uint256[] memory);
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

import "@openzeppelin/contracts/access/Ownable.sol";
import "./World.sol";
import "./interfaces/ICharacterEquipment.sol";
import "./interfaces/ICharacterItem.sol";
import "./interfaces/ICharacterReveal.sol";
import "./interfaces/ICharacterStatus.sol";
import "./interfaces/IItemTransfer.sol";
import "./interfaces/IItemPackReveal.sol";

contract Game is Ownable {
    mapping(uint256 => World) public worlds;

    uint256 public _worldIndex;

    ICharacterEquipment public characterEquipment;
    ICharacterItem public characterItem;
    ICharacterReveal public characterReveal;
    ICharacterStatus public characterStatus;
    IItemTransfer public itemTransfer;
    IEventCheckin public eventCheckin;
    IItemPackReveal public itemPackReveal;

    constructor() {
    }

    function setCharacterEquipment(address characterEquipment_) public onlyOwner {
        characterEquipment = ICharacterEquipment(characterEquipment_);
    }

    function setCharacterItem(address characterItem_) public onlyOwner {
        characterItem = ICharacterItem(characterItem_);
    }

    function setCharacterReveal(address characterReveal_) public onlyOwner {
        characterReveal = ICharacterReveal(characterReveal_);
    }

    function setCharacterStatus(address characterStatus_) public onlyOwner {
        characterStatus = ICharacterStatus(characterStatus_);
    }

    function setItemTransfer(address itemTransfer_) public onlyOwner {
        itemTransfer = IItemTransfer(itemTransfer_);
    }

    function setEventCheckin(address eventCheckin_) public onlyOwner {
        eventCheckin = IEventCheckin(eventCheckin_);
    }

    function setItemPackReveal(address itemPackReveal_) public onlyOwner {
        itemPackReveal = IItemPackReveal(itemPackReveal_);
    }

    function addWorld() public onlyOwner {
        _worldIndex++;
        worlds[_worldIndex] = new World(address(this), _worldIndex);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "./access/GameOnly.sol";

import "./Game.sol";
import "./Character.sol";
import "./CharacterDefinition.sol";
import "./ItemDefinition.sol";
import "./EventDefinition.sol";
import "./ItemPack.sol";
import "./CommandDefinition.sol";
import "./ItemPackDefinition.sol";
import "./game/EventCheckin.sol";

contract World is GameOnly, Ownable {
    IERC721 private _l1Nft;
    IERC721[] private _l2Nfts;

    uint256 public worldId;

    uint256 private _characterIndex;
    uint256 private _characterDefinitionIndex;
    uint256 private _ItemDefinitionIndex;

    // key: tokenId
    mapping(uint256 => Character) public characters;

    CharacterDefinition public characterDefinition;

    // key: itemDefinitionId
    mapping(uint256 => ItemDefinition) public itemDefinitions;

    ItemPack public itemPack;
    ItemPackDefinition public itemPackDefinition;
    EventDefinition public eventDefinition;

    // key: commandDefinitionId
    mapping(uint256 => CommandDefinition) public commandDefinitions;

    constructor(address game, uint256 worldId_)
    GameOnly(game) {
        worldId = worldId_;
        characterDefinition = new CharacterDefinition(worldId_);
        itemPack = new ItemPack(worldId_);
        itemPackDefinition = new ItemPackDefinition(worldId_);
        eventDefinition = new EventDefinition(worldId_);
    }

    // TODO: add access control modifier
    function setCharacterDefinition(address characterDefinition_) public {
        characterDefinition = CharacterDefinition(characterDefinition_);
    }

    // TODO: add access control modifier
    function addCharacter(uint256 tokenId, uint256 characterDefinitionId) public returns(uint256) {
        _characterIndex++;
        characters[_characterIndex] = new Character(worldId, tokenId, characterDefinitionId, address(characterDefinition));
        return _characterIndex;
    }

    // TODO: add access control modifier
    function addItemDefinition(uint256 itemId_, string memory symbol_, ItemDefinition.ItemType itemType_, uint256[] memory layers_) public {
        itemDefinitions[itemId_] = new ItemDefinition(worldId, itemId_, symbol_, itemType_, layers_);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface ICharacterItem {
    event AddItem(uint256 indexed worldId, uint256 indexed tokenId, uint256 itemId);

    function addItem(uint256 worldId, uint256 tokenId, uint256 itemId, int64 value) external;

    function getItems(uint256 worldId, uint256 tokenId, uint256[] memory itemIds) external view returns(int64[] memory);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface ICharacterReveal {
    event Reveal(uint256 indexed worldId, address indexed tokenId, address indexed characterDefinitionId);

    function reveal(uint256 worldId, uint256 tokenId) external;

    function isRevealed(uint256 worldId, uint256 tokenId) external view;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface ICharacterStatus {
    event UpdateStatus(uint256 indexed worldId, uint256 indexed tokenId, uint256 statusSlotIndex, int64 value);

    function setStatus(uint256 worldId, uint256 tokenId, uint256 statusSlotIndex, int64 value) external;

    function getStatuses(uint256 worldId, uint256 tokenId) external view returns(int64[] memory);

    function getStatusSlots(uint256 worldId, uint256 tokenId) external view returns(uint256[] memory);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IItemTransfer {
    event TransferItem(uint256 indexed worldId, uint256 indexed tokenId, uint256 indexed targetTokenId, uint256 itemId, int64 value);

    function transfer(uint256 worldId, uint256 tokenId, uint256 targetTokenId, uint256 itemId, int64 amount) external;

    function canTransfer(uint256 worldId, uint256 tokenId, uint256 targetTokenId, uint256 itemId, int64 amount) external view returns(bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IItemPackReveal {
    event RevealItemPack(uint256 indexed worldId, uint256 indexed tokenId, uint256 indexed itemPackId);

    function reveal(uint256 worldId, uint256 tokenId, uint256 itemPackId) external;

    function isRevealed(uint256 worldId, uint256 itemPackId) external view returns(bool);

    // returns: array of ItemPackId, array of ItemPackDefinitionId, array of IsRevealed
    function getItemPacks(uint256 worldId, address playerWallet) external view returns(uint256[] memory, uint256[] memory, bool[] memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract GameOnly {
    address private _gameAddress;

    constructor(address gameAddress) {
        _gameAddress = gameAddress;
    }

    modifier onlyGame() {
        require(_gameAddress == msg.sender, "GameOnly: caller is not Game");
        _;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract CharacterDefinition {
    uint256 public worldId;

    enum EquipmentSlot { Invalid, Normal }
    enum ItemType { Invalid, Normal, Status }

    // key: characterDefinitionId
    mapping(uint256 => bool) characters;

    // key: characterDefinitionId
    mapping(uint256 => EquipmentSlot[]) public equipmentSlots;

    // key: characterDefinitionId, value: itemId[]
    mapping(uint256 => uint256[]) public statusSlots;

    // key: characterDefinitionId, value: (key: itemId, value: equipmentSlotIndex)
    mapping(uint256 => mapping(uint256 => uint256)) public equipableItems;

    constructor(uint256 worldId_) {
        worldId = worldId_;
    }

    // TODO: add access control modifier
    function setCharacter(uint256 characterDefinitionId, bool enabled) public virtual {
        require(characterDefinitionId > 0);

        characters[characterDefinitionId] = enabled;
    }

    // TODO: add access control modifier
    function setEquipmentSlots(uint256 characterDefinitionId, EquipmentSlot[] memory equipmentSlots_) public virtual {
        require(characters[characterDefinitionId] == true, "character disabled");
        require(equipmentSlots_.length > 0);

        equipmentSlots[characterDefinitionId] = equipmentSlots_;
    }

    function getEquipmentSlots(uint256 characterDefinitionId) public view virtual returns(EquipmentSlot[] memory) {
        return equipmentSlots[characterDefinitionId];
    }

    function isValidEquipmentSlot(uint256 characterDefinitionId, uint256 equipmentSlotIndex) public view virtual returns(bool) {
        return equipmentSlotIndex >= 0 && equipmentSlotIndex < equipmentSlots[characterDefinitionId].length && equipmentSlots[characterDefinitionId][equipmentSlotIndex] != EquipmentSlot.Invalid;
    }

    // TODO: add access control modifier
    function setStatusSlots(uint256 characterDefinitionId, uint256[] memory statusSlots_) public virtual {
        require(characters[characterDefinitionId] == true);
        require(statusSlots_.length > 0);

        statusSlots[characterDefinitionId] = statusSlots_;
    }

    function getStatusSlots(uint256 characterDefinitionId) public view virtual returns(uint256[] memory) {
        return statusSlots[characterDefinitionId];
    }

    function isValidStatusSlot(uint256 characterDefinitionId, uint256 statusSlotIndex, uint256 itemId) public view virtual returns(bool) {
        return statusSlotIndex >= 0 && statusSlotIndex < statusSlots[characterDefinitionId].length && statusSlots[characterDefinitionId][statusSlotIndex] == itemId;
    }

    // TODO: add access control modifier
    function setEquipable(uint256 characterDefinitionId, uint256 itemId, uint256 equipmentSlotIndex) public virtual {
        require(characters[characterDefinitionId] == true);

        equipableItems[characterDefinitionId][itemId] = equipmentSlotIndex;
    }

    function canEquip(uint256 characterDefinitionId, uint256 itemId, uint256 equipmentSlotIndex) public virtual view returns(bool) {
        return equipableItems[characterDefinitionId][itemId] == equipmentSlotIndex || itemId == 0;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract ItemDefinition {
    enum ItemType { Invalid, Normal, SoulBound, Status }

    uint256 public worldId;
    uint256 public itemId;
    string public category;
    ItemType public itemType;
    uint256[] layers;

    constructor(uint256 worldId_, uint256 itemId_, string memory category_, ItemType itemType_, uint256[] memory layers_) {
        worldId = worldId_;
        itemId = itemId_;
        category = category_;
        itemType = itemType_;
        layers = layers_;
    }

    // TODO: add access control modifier
    function setSymbol(string calldata symbol_) external virtual {
        category = symbol_;
    }

    // TODO: add access control modifier
    function setItemType(ItemType itemType_) external virtual {
        itemType = itemType_;
    }

    // TODO: add access control modifier
    function setLayers(uint256[] calldata layers_) external virtual {
        layers = layers_;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract EventDefinition {
    struct EventDefinitionRecord {
        uint256 eventDefinitionId;
        address eventNftAddress;
        address itemPackNftAddress;
        uint256 itemPackDefinitionId;

        uint256 executableTimes;
        uint256 executableTimesPerUser;
    }

    uint256 public worldId;
    uint256 public _currentIndex;
    mapping(uint256 => EventDefinitionRecord) private _eventDefinitions;

    constructor(uint256 worldId_) {
        worldId = worldId_;
    }

    function getEventDefinition(uint256 eventDefinitionId) public virtual view returns(uint256, address, address, uint256, uint256, uint256) {
        EventDefinitionRecord memory record = _eventDefinitions[eventDefinitionId];

        return (record.eventDefinitionId, record.eventNftAddress, record.itemPackNftAddress, record.itemPackDefinitionId, record.executableTimes, record.executableTimesPerUser);
    }

    function getItemPackDefinitionId(uint256 eventDefinitionId) public virtual view returns(uint256) {
        EventDefinitionRecord memory record = _eventDefinitions[eventDefinitionId];

        return record.itemPackDefinitionId;
    }


    // TODO: add access control modifier
    function addEventDefinitions(EventDefinitionRecord[] memory eventDefinitions_) public virtual {
        for (uint256 i; i < eventDefinitions_.length; i++) {
            EventDefinitionRecord memory record = eventDefinitions_[i];
            _addEventDefinition(
                record.eventNftAddress,
                record.itemPackNftAddress,
                record.itemPackDefinitionId,
                record.executableTimes,
                record.executableTimesPerUser
            );
        }
    }

    function _addEventDefinition(
        address eventNftAddress_,
        address itemPackNftAddress_,
        uint256 itemPackDefinitionId_,
        uint256 executableTimes_,
        uint256 executableTimesPerUser_
    ) private {
        _currentIndex++;
        _eventDefinitions[_currentIndex] = EventDefinitionRecord(
            _currentIndex,
            eventNftAddress_,
            itemPackNftAddress_,
            itemPackDefinitionId_,
            executableTimes_,
            executableTimesPerUser_
        );
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract ItemPack {
    uint256 public worldId;
    uint256 private _currentIndex;

    struct ItemPackRecord {
        uint256 itemPackId;
        uint256 itemPackDefinitionId;
        bool isRevealed;
    }

    // key: itemPackId, value: array of ItemPackRecord
    mapping(uint256 => ItemPackRecord) private _itemPackRecords;

    // key: NFT contract address, value: (key: tokenId, value: itemPackId)
    mapping(address => mapping(uint256 => uint256)) private _itemPackIdsByNft;

    // key: Wallet address, array of itemPackId
    mapping(address => uint256[]) private _itemPackIdsByWallet;

    constructor(uint256 worldId_) {
        worldId = worldId_;
    }

    // TODO: add access control modifier
    function addItemPack(address playerWallet, address nftAddress, uint256 nftTokenId, uint256 itemPackDefinitionId_) public virtual {
        _currentIndex++;

        _itemPackRecords[_currentIndex] = ItemPackRecord(_currentIndex, itemPackDefinitionId_, false);
        _itemPackIdsByNft[nftAddress][nftTokenId] = _currentIndex;

        // TODO: should not use wallet address
        _itemPackIdsByWallet[playerWallet].push(_currentIndex);
    }

    function getItemPackIds(address playerWallet) public virtual view returns(uint256[] memory) {
        // TODO: should not use wallet address
        return _itemPackIdsByWallet[playerWallet];
    }

    function itemPackDefinitionId(uint256 itemPackId) public virtual view returns (uint256) {
        return _itemPackRecords[itemPackId].itemPackDefinitionId;
    }

    function isRevealed(uint256 itemPackId) public virtual view returns (bool) {
        return _itemPackRecords[itemPackId].isRevealed;
    }

    // TODO: add access control modifier
    function updateItemPack(uint256 itemPackId_, uint256 itemPackDefinitionId_, bool isRevealed_) public virtual {
        _itemPackRecords[itemPackId_] = ItemPackRecord(itemPackId_, itemPackDefinitionId_, isRevealed_);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract CommandDefinition {
    uint256 public commandDefinitionId;
    address private _mintNftAddress;

    uint256[] public costItemIds;
    // key: ItemId, value: amount
    mapping(uint256 => int64) public costItemAmounts;

    uint256[] public itemIds;
    // key: ItemId, value: amount
    mapping(uint256 => int64) public itemAmounts;

    uint256[] public conditionItemIds;
    // key: ItemId, value: amount
    mapping(uint256 => int64) public conditionItemAmounts;

    uint256 public executableTimes;
    uint256 public executableTimesPerUser;

    constructor(address mintNftAddress_) {
        _mintNftAddress = mintNftAddress_;
    }

    function getConditionItemIds() public virtual view returns(uint256[] memory) {
        return conditionItemIds;
    }

    function getCostItemIds() public virtual view returns(uint256[] memory) {
        return costItemIds;
    }

    function getItemIds() public virtual view returns(uint256[] memory) {
        return itemIds;
    }

    // TODO: add access control modifier
    function setItems(uint256[] calldata itemIds_, int64[] calldata amounts_) public virtual {
        require(itemIds_.length == amounts_.length, 'array length mismatch');

        itemIds = itemIds_;
        for (uint256 i; i < itemIds.length; i++) {
            uint256 itemId = itemIds[i];
            int64 amount = amounts_[i];
            itemAmounts[itemId] = amount;
        }
    }

    // TODO: add access control modifier
    function setConditionItems(uint256[] calldata itemIds_, int64[] calldata amounts_) public virtual {
        require(itemIds_.length == amounts_.length, 'array length mismatch');

        conditionItemIds = itemIds_;
        for (uint256 i; i < itemIds.length; i++) {
            uint256 itemId = itemIds[i];
            int64 amount = amounts_[i];
            conditionItemAmounts[itemId] = amount;
        }
    }

    // TODO: add access control modifier
    function setCostItems(uint256[] calldata itemIds_, int64[] calldata amounts_) public virtual {
        require(itemIds_.length == amounts_.length, 'array length mismatch');

        costItemIds = itemIds_;
        for (uint256 i; i < itemIds.length; i++) {
            uint256 itemId = itemIds[i];
            int64 amount = amounts_[i];
            costItemAmounts[itemId] = amount;
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract ItemPackDefinition {
    struct ItemPackDefinitionRecord {
        uint256 itemPackDefinitionId;
        address nftAddress;
        uint256[] itemDefinitionIds;
        int64[] amounts;
    }

    uint256 public worldId;
    uint256 private _currentIdIndex;

    // key: itemPackDefinitionId
    mapping(uint256 => ItemPackDefinitionRecord) private _itemPackDefinitionRecords;

    constructor(uint256 worldId_) {
        worldId = worldId_;
    }

    function getItemPackDefinition(uint256 itemPackDefinitionId) public virtual view returns(address, uint256[] memory, int64[] memory) {
        ItemPackDefinitionRecord memory record = _itemPackDefinitionRecords[itemPackDefinitionId];

        return (record.nftAddress, record.itemDefinitionIds, record.amounts);
    }

    function addItemPackDefinitions(ItemPackDefinitionRecord[] memory itemPacks) public virtual {
        for (uint256 i; i < itemPacks.length; i++) {
            _currentIdIndex++;
            ItemPackDefinitionRecord memory itemPack = itemPacks[i];
            itemPack.itemPackDefinitionId = _currentIdIndex;

            // TODO: check itemId
            require(itemPack.itemDefinitionIds.length == itemPack.amounts.length, "wrong ItemPack");

            _itemPackDefinitionRecords[_currentIdIndex] = itemPack;
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../interfaces/IEventCheckin.sol";
import "../Character.sol";
import "./GameBase.sol";
import "../EventDefinition.sol";
import "../ItemPackDefinition.sol";
import "../ItemPack.sol";

contract EventCheckin is IEventCheckin, GameBase {
    uint256 public checkinCount;

    // key: eventDefinitionId, value: count
    mapping(uint256 => uint256) public checkinCountsPerEvent;

    // key: Player Wallet, value: (key: eventDefinitionId, value: count)
    mapping(address => mapping(uint256 => uint256)) public checkinCountsPerPlayer;

    constructor(address game)
    GameBase(game) {
    }

    function canCheckin(uint256 worldId, uint256 eventId) external override view returns(bool) {
        // TODO: implement
        return true;
    }

    // TODO: add access control modifier
    function checkin(address playerWallet, uint256 worldId, uint256 eventDefinitionId) external virtual override {
        // TODO: check record number of executions(whole, per user)

        checkinCount++;
        checkinCountsPerEvent[eventDefinitionId]++;
        checkinCountsPerPlayer[playerWallet][eventDefinitionId]++;
        _mintItemPack(playerWallet, worldId, eventDefinitionId);

        // TODO: Emit Event
        emit Checkin(playerWallet, worldId, eventDefinitionId);
    }

    function _mintItemPack(address playerWallet, uint256 worldId, uint256 eventDefinitionId) private {
        World world = getWorld(worldId);
        EventDefinition eventDefinition = world.eventDefinition();
        uint256 itemPackDefinitionId = eventDefinition.getItemPackDefinitionId(eventDefinitionId);

        // TODO: check eventDefinitionId, itemPackDefinitionId;
        ItemPack itemPack = world.itemPack();

        // TODO: mint Event / ItemPack NFT
        // TODO: set NFT address/tokenId
        itemPack.addItemPack(playerWallet, address(0), 0, itemPackDefinitionId);
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
pragma solidity ^0.8.0;

interface IEventCheckin {
    event Checkin(address indexed playerWallet, uint256 indexed worldId, uint256 eventDefinitionId);

    function checkin(address playerWallet, uint256 worldId, uint256 eventDefinitionId) external;

    function canCheckin(uint256 worldId, uint256 eventId) external view returns(bool);
}