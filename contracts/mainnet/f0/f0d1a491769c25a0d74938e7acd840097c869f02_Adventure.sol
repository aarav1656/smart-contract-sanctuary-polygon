// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.9;

import '@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155ReceiverUpgradeable.sol';
import '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';
import '../core/BaseContractV2.sol';
import '../interfaces/IERC1155.sol';
import '../interfaces/IERC20.sol';
import '../interfaces/IOtto.sol';
import '../interfaces/IRand.sol';
import '../interfaces/IOttopiaStore.sol';
import '../interfaces/IAdventure.sol';

contract Adventure is
    BaseContractV2,
    IERC721ReceiverUpgradeable,
    IERC1155ReceiverUpgradeable
{
    using ECDSA for bytes32;
    bytes32 public constant POTION_EFFECT_MANAGER_ROLE =
        keccak256('POTION_EFFECT_MANAGER_ROLE');
    uint256 public constant ONE_HUNDRED_PERCENT = 10000;
    uint256 public constant MAX_OTTOS_PER_WALLET = 5;
    uint256 public constant TREASURE_CHEST_ITEM_ID = 16646388;
    string public constant REVIVE_PAYMENT_KEY = 'adventure_revive';
    string public constant FINISH_IMMEDIATELY_PAYMENT_KEY =
        'adventure_finish_immediately';

    struct Pass {
        uint256 locId;
        uint256 ottoId;
        uint256 departureAt;
        uint256 canFinishAt;
        uint256 finishedAt;
        uint256 seed;
        bool success;
        bool revived;
        Rewards rewards;
        uint32 expMultiplier;
        uint32 itemAmountMultiplier;
    }

    struct Signature {
        string nonce;
        bytes32 digest;
        bytes signed;
    }

    struct Rewards {
        uint32 exp;
        uint32 ap;
        uint32 tcp;
        uint256[] items;
        uint256[] bonuses;
    }

    event Departure(uint256 indexed passId, uint256 indexed ottoId);

    event Finish(uint256 indexed passId, uint256 indexed ottoId, bool success);

    event Revive(uint256 indexed passId, uint256 indexed ottoId);

    event TcpChanged(address indexed wallet, uint256 from, uint256 to);

    event PotionsUsed(
        uint256 indexed passId,
        uint256 indexed ottoId,
        uint256[] potions
    );

    event PassUpdated(uint256 indexed passId, uint256 indexed ottoId);

    event RestingUntilUpdated(
        uint256 indexed ottoId,
        uint256 restingUntil,
        uint256 delta
    );

    event TreasureChestsGot(address indexed wallet, uint256[] chests);

    event LevelUpChestsGot(
        address indexed wallet,
        uint256 indexed passId,
        uint256 indexed ottoId,
        uint32 lv,
        uint256[] chests
    );

    IRand public RAND;
    IAdventurePassERC721 public PASS;
    IOttoDiamondERC721 public OTTO;
    IERC1155Preset public ITEM;
    IERC20 public CLAM;
    IOttopiaStore public STORE;
    address public signer;
    mapping(bytes => bool) public usedSignatures;
    // ottoId -> passId
    mapping(uint256 => uint256) private _ottoPass;
    // passId -> pass
    mapping(uint256 => Pass) private _passes;
    // ottoId -> resting until
    mapping(uint256 => uint256) public restingUntil;
    // wallet -> tcp
    mapping(address => uint256) public accumulativeTcp;
    // itemId -> allowed
    mapping(uint256 => bool) public allowedPotions;
    uint256 public reviveProduct;
    uint256 public finishImmediatelyProduct;
    // address -> locId -> otto count
    mapping(address => mapping(uint256 => uint256)) public ottoCount;
    bool paused;
    mapping(uint32 => uint256[]) public levelUpChests;

    function _onlyEOA() private view {
        require(tx.origin == msg.sender, 'not EOA');
    }

    function _onlyPotionEffectManager() private view {
        require(
            hasRole(POTION_EFFECT_MANAGER_ROLE, msg.sender),
            'not potion mgr'
        );
    }

    function _onlyOttoOwner(uint256 ottoId_) private view {
        require(msg.sender == OTTO.ownerOf(ottoId_), 'not otto owner');
    }

    function _onlyPassOwner(uint256 ottoId_) private view {
        require(
            msg.sender == PASS.ownerOf(_ottoPass[ottoId_]),
            'not pass owner'
        );
    }

    function _validPercentage(uint256 percentage_) private pure {
        require(percentage_ <= ONE_HUNDRED_PERCENT, 'invalid percentage');
    }

    function _ottoIsReady(uint256 ottoId_) private view {
        require(
            OTTO.portalStatusOf(ottoId_) == PortalStatus.SUMMONED,
            'otto not summoned'
        );
        require(block.timestamp >= restingUntil[ottoId_], 'otto is resting');
    }

    function _ottoInAdventure(uint256 ottoId_) private view {
        require(OTTO.ownerOf(ottoId_) == address(this), 'not in adventure');
    }

    function _ottoIsResting(uint256 ottoId_) private view {
        require(block.timestamp < restingUntil[ottoId_], 'not resting');
    }

    function _ottoCanRevive(uint256 ottoId_) private view {
        require(
            _passes[_ottoPass[ottoId_]].finishedAt != 0,
            'not finished yet'
        );
        require(!_passes[_ottoPass[ottoId_]].success, 'not failed');
        require(!_passes[_ottoPass[ottoId_]].revived, 'already revived');
    }

    function initialize(
        address rand_,
        address pass_,
        address otto_,
        address item_,
        address clam_,
        address store_,
        address signer_,
        uint256 reviveProduct_,
        uint256 finishImmediatelyProduct_,
        uint256[] calldata potions_
    ) public initializer {
        __BaseContract_init();
        RAND = IRand(rand_);
        PASS = IAdventurePassERC721(pass_);
        OTTO = IOttoDiamondERC721(otto_);
        ITEM = IERC1155Preset(item_);
        CLAM = IERC20(clam_);
        STORE = IOttopiaStore(store_);
        signer = signer_;
        ITEM.setApprovalForAll(address(OTTO), true);
        allowPotions(potions_);
        reviveProduct = reviveProduct_;
        finishImmediatelyProduct = finishImmediatelyProduct_;
    }

    function pause() external onlyAdmin {
        paused = true;
    }

    function resume() external onlyAdmin {
        paused = false;
    }

    function setSigner(address signer_) public onlyAdmin {
        signer = signer_;
    }

    function allowPotions(uint256[] calldata potions_) public onlyAdmin {
        for (uint256 i = 0; i < potions_.length; i++) {
            allowedPotions[potions_[i]] = true;
        }
    }

    function upgradeForLevelUpChests() public onlyAdmin {
        levelUpChests[5].push(16646144);
        levelUpChests[10].push(16646144);
        levelUpChests[10].push(16646144);
        levelUpChests[15].push(16646208);
        levelUpChests[20].push(16646208);
        levelUpChests[25].push(16646208);
        levelUpChests[25].push(16646208);
    }

    function _verify(bytes32 hash_, Signature calldata sig_) private {
        require(!usedSignatures[sig_.signed], 'sig used');
        usedSignatures[sig_.signed] = true;
        require(
            signer == hash_.toEthSignedMessageHash().recover(sig_.signed),
            'sig mismatch'
        );
        require(hash_ == sig_.digest, 'hash mismatch');
    }

    function _transferEquipmentIn(
        IOttoDiamondERC721.ItemActionInput[] memory inputs_
    ) private {
        for (uint256 i = 0; i < inputs_.length; i++) {
            if (inputs_[i].typ == ItemActionType.EQUIP) {
                ITEM.safeTransferFrom(
                    msg.sender,
                    address(this),
                    inputs_[i].itemId,
                    1,
                    ''
                );
            }
        }
    }

    function _separatePotions(
        IOttoDiamondERC721.ItemActionInput[] calldata inputs_
    )
        private
        pure
        returns (IOttoDiamondERC721.ItemActionInput[] memory, uint256[] memory)
    {
        uint256 potionCount_ = 0;
        for (uint256 i = 0; i < inputs_.length; i++) {
            if (inputs_[i].typ == ItemActionType.USE) {
                potionCount_++;
            }
        }
        uint256[] memory potions_ = new uint256[](potionCount_);
        IOttoDiamondERC721.ItemActionInput[]
            memory dressUp_ = new IOttoDiamondERC721.ItemActionInput[](
                inputs_.length - potionCount_
            );
        uint256 potionIndex_ = 0;
        uint256 dressUpIndex_ = 0;
        for (uint256 i = 0; i < inputs_.length; i++) {
            if (inputs_[i].typ == ItemActionType.USE) {
                potions_[potionIndex_] = inputs_[i].itemId;
                potionIndex_++;
            } else {
                dressUp_[dressUpIndex_] = inputs_[i];
                dressUpIndex_++;
            }
        }
        return (dressUp_, potions_);
    }

    function explore(
        uint256 ottoId_,
        uint256 locId_,
        uint256 duration_,
        IOttoDiamondERC721.ItemActionInput[] calldata inputs_,
        Signature calldata sig_
    ) external {
        _onlyEOA();
        _onlyOttoOwner(ottoId_);
        _ottoIsReady(ottoId_);
        require(!paused, 'paused');
        bytes32 hash_ = keccak256(
            abi.encodePacked(
                msg.sender,
                address(this),
                ottoId_,
                locId_,
                duration_,
                abi.encode(inputs_),
                sig_.nonce
            )
        );
        _verify(hash_, sig_);
        require(
            ottoCount[msg.sender][locId_] < MAX_OTTOS_PER_WALLET,
            'crowded'
        );
        ottoCount[msg.sender][locId_]++;

        IOttoDiamondERC721.ItemActionInput[] memory dressUp_;
        uint256[] memory potions_;
        if (inputs_.length > 0) {
            (dressUp_, potions_) = _separatePotions(inputs_);
        }
        if (dressUp_.length > 0) {
            _transferEquipmentIn(dressUp_);
            OTTO.doItemBatchActions(ottoId_, dressUp_);
        }
        OTTO.safeTransferFrom(msg.sender, address(this), ottoId_);
        uint256 passId = PASS.issuePass(msg.sender);
        _ottoPass[ottoId_] = passId;
        Pass storage p = _passes[passId];

        p.locId = locId_;
        p.ottoId = ottoId_;
        p.departureAt = block.timestamp;
        p.canFinishAt = block.timestamp + duration_;
        p.seed = uint256(bytes32(bytes(sig_.nonce)));
        p.expMultiplier = 1;
        p.itemAmountMultiplier = 1;
        emit Departure(passId, ottoId_);
        if (potions_.length > 0) {
            usePotions(ottoId_, potions_);
        }
    }

    function _finishProductAmount(uint256 passId_)
        private
        view
        returns (uint256)
    {
        Pass memory p = _passes[passId_];
        uint256 amount = 15;
        uint256 remain = p.canFinishAt - block.timestamp;
        if (remain <= 9 hours) {
            if (remain % 1 hours == 0) {
                amount = remain / 1 hours;
            } else {
                amount = remain / 1 hours + 1;
            }
        } else if (remain <= 10 hours) {
            amount = 11;
        } else if (remain <= 11 hours) {
            amount = 13;
        }
        return amount;
    }

    function finishFee(uint256 passId_) public view returns (uint256) {
        return
            STORE.totalPayment(
                FINISH_IMMEDIATELY_PAYMENT_KEY,
                _finishProductAmount(passId_)
            );
    }

    function _handleFinishImmediately(uint256 passId_) private {
        uint256 amount_ = _finishProductAmount(passId_);
        uint256 fee_ = finishFee(passId_);
        require(msg.value == fee_, 'invalid finish fee');
        STORE.payWithMatic{value: fee_}(
            FINISH_IMMEDIATELY_PAYMENT_KEY,
            amount_
        );
    }

    function usePotions(uint256 ottoId_, uint256[] memory potions_) public {
        _onlyPassOwner(ottoId_);
        IOttoDiamondERC721.ItemActionInput[]
            memory inputs_ = new IOttoDiamondERC721.ItemActionInput[](
                potions_.length
            );
        for (uint256 i = 0; i < potions_.length; i++) {
            require(allowedPotions[potions_[i]], 'not allowed potion');
            ITEM.safeTransferFrom(
                msg.sender,
                address(this),
                potions_[i],
                1,
                ''
            );
            inputs_[i].typ = ItemActionType.USE;
            inputs_[i].itemId = potions_[i];
        }
        OTTO.doItemBatchActions(ottoId_, inputs_);
        emit PotionsUsed(_ottoPass[ottoId_], ottoId_, potions_);
    }

    function finish(
        uint256 ottoId_,
        uint256 cooldown_,
        uint256 sr_,
        Rewards calldata rewards_,
        bool immediately_,
        uint256[] calldata potions_,
        Signature calldata sig_
    ) external payable {
        _onlyEOA();
        _validPercentage(sr_);
        _onlyPassOwner(ottoId_);
        _verify(
            keccak256(
                abi.encodePacked(
                    msg.value,
                    msg.sender,
                    address(this),
                    ottoId_,
                    cooldown_,
                    sr_,
                    abi.encode(rewards_),
                    immediately_,
                    potions_,
                    sig_.nonce
                )
            ),
            sig_
        );
        uint256 passId = _ottoPass[ottoId_];
        Pass storage p = _passes[passId];

        if (immediately_) {
            _handleFinishImmediately(passId);
            p.canFinishAt = block.timestamp;
        } else if (potions_.length > 0) {
            usePotions(ottoId_, potions_);
        }

        require(block.timestamp >= p.canFinishAt, 'not finished');

        PASS.revokePass(passId);

        uint256 rnd = RAND.rand(
            p.seed,
            uint256(bytes32(bytes(sig_.nonce))),
            ONE_HUNDRED_PERCENT
        );
        bool success = rnd < sr_;
        p.success = success;
        p.finishedAt = block.timestamp;
        p.rewards.exp = rewards_.exp;
        p.rewards.ap = rewards_.ap;
        p.rewards.tcp = rewards_.tcp;
        p.rewards.items = rewards_.items;
        p.rewards.bonuses = rewards_.bonuses;
        if (success) {
            if (OTTO.willLevelUp(ottoId_, rewards_.exp)) {
                cooldown_ = 0;
            }
            _setSuccessResults(ottoId_);
        }
        _updateRestingUntil(ottoId_, cooldown_);
        OTTO.safeTransferFrom(address(this), msg.sender, p.ottoId);
        ottoCount[msg.sender][p.locId]--;
        emit Finish(passId, p.ottoId, success);
    }

    function reviveFee() public view returns (uint256) {
        return STORE.totalPayment(REVIVE_PAYMENT_KEY, 1);
    }

    function revive(uint256 ottoId_) external payable {
        _onlyEOA();
        _onlyOttoOwner(ottoId_);
        _ottoCanRevive(ottoId_);
        uint256 passId = _ottoPass[ottoId_];
        Pass storage p = _passes[passId];
        uint256 price = reviveFee();
        require(msg.value == price, 'invalid revive fee');
        STORE.payWithMatic{value: price}(REVIVE_PAYMENT_KEY, 1);
        p.revived = true;
        _giveItems(msg.sender, p.rewards.items);
        emit Revive(passId, p.ottoId);
    }

    function _updateRestingUntil(uint256 ottoId_, uint256 cooldown_) private {
        restingUntil[ottoId_] = block.timestamp + cooldown_;
        emit RestingUntilUpdated(ottoId_, restingUntil[ottoId_], cooldown_);
    }

    function _setSuccessResults(uint256 ottoId_) private {
        uint256 passId = _ottoPass[ottoId_];
        Pass storage p = _passes[passId];

        uint256 fromTcp_ = accumulativeTcp[msg.sender];
        accumulativeTcp[msg.sender] += p.rewards.tcp;
        uint256 treasureChestsAmount = ((fromTcp_ % 100) + p.rewards.tcp) / 100;
        uint256[] memory treasureChests = new uint256[](treasureChestsAmount);
        for (uint256 i = 0; i < treasureChestsAmount; i++) {
            treasureChests[i] = TREASURE_CHEST_ITEM_ID;
        }
        if (treasureChestsAmount > 0) {
            _giveItems(msg.sender, treasureChests);
            emit TreasureChestsGot(msg.sender, treasureChests);
        }

        uint32 fromLv_ = OTTO.levelOf(ottoId_);
        OTTO.increaseExp(ottoId_, p.rewards.exp);
        uint32 toLv_ = OTTO.levelOf(ottoId_);
        for (uint32 i = fromLv_ + 1; i <= toLv_; i++) {
            if (levelUpChests[i].length > 0) {
                _giveItems(msg.sender, levelUpChests[i]);
                emit LevelUpChestsGot(
                    msg.sender,
                    passId,
                    ottoId_,
                    i,
                    levelUpChests[i]
                );
            }
        }

        OTTO.increaseAp(ottoId_, p.rewards.ap);
        _giveItems(msg.sender, p.rewards.items);
        _giveItems(msg.sender, p.rewards.bonuses);
        emit TcpChanged(msg.sender, fromTcp_, accumulativeTcp[msg.sender]);
    }

    function _giveItems(address to_, uint256[] memory items_) private {
        if (items_.length <= 0) {
            return;
        }
        uint256[] memory values = new uint256[](items_.length);
        for (uint256 i = 0; i < items_.length; i++) {
            values[i] = 1;
        }
        ITEM.mintBatch(to_, items_, values, '');
    }

    function pass(uint256 passId_) public view returns (Pass memory) {
        return _passes[passId_];
    }

    function latestPassIdOf(uint256 ottoId_) public view returns (uint256) {
        return _ottoPass[ottoId_];
    }

    function latestPassOf(uint256 ottoId_) public view returns (Pass memory) {
        return pass(_ottoPass[ottoId_]);
    }

    function ottoOwnerOf(uint256 ottoId_) public view returns (address) {
        _ottoInAdventure(ottoId_);
        return PASS.ownerOf(_ottoPass[ottoId_]);
    }

    function canFinishAt(uint256 ottoId_) public view returns (uint256) {
        return latestPassOf(ottoId_).canFinishAt;
    }

    function expMultiplierOf(uint256 ottoId_) public view returns (uint32) {
        return latestPassOf(ottoId_).expMultiplier;
    }

    function itemAmountMultiplierOf(uint256 ottoId_)
        public
        view
        returns (uint32)
    {
        return latestPassOf(ottoId_).itemAmountMultiplier;
    }

    function shortenDuration(uint256 ottoId, uint256 sec) external {
        _onlyPotionEffectManager();
        _ottoInAdventure(ottoId);
        require(block.timestamp < canFinishAt(ottoId), 'already finished');
        uint256 passId = _ottoPass[ottoId];
        _passes[passId].canFinishAt -= sec;
        emit PassUpdated(passId, ottoId);
    }

    function shortenCooldown(uint256 ottoId, uint256 sec) external {
        _onlyPotionEffectManager();
        _ottoIsResting(ottoId);
        restingUntil[ottoId] = restingUntil[ottoId] - sec;
        emit RestingUntilUpdated(ottoId, restingUntil[ottoId], sec);
    }

    function setExpMultiplier(uint256 ottoId, uint32 multiplier) external {
        _onlyPotionEffectManager();
        _ottoInAdventure(ottoId);
        uint256 passId = _ottoPass[ottoId];
        _passes[passId].expMultiplier = multiplier;
        emit PassUpdated(passId, ottoId);
    }

    function setItemAmountMultiplier(uint256 ottoId, uint32 multiplier)
        external
    {
        _onlyPotionEffectManager();
        _ottoInAdventure(ottoId);
        uint256 passId = _ottoPass[ottoId];
        _passes[passId].itemAmountMultiplier = multiplier;
        emit PassUpdated(passId, ottoId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControlUpgradeable, IERC165Upgradeable)
        returns (bool)
    {
        return
            interfaceId == type(IERC1155ReceiverUpgradeable).interfaceId ||
            interfaceId == type(IERC721ReceiverUpgradeable).interfaceId ||
            interfaceId == type(IAdventure).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return this.onERC721Received.selector;
    }

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
        if (msg.sender == address(ITEM)) {
            revert('not implemented');
        }
        return this.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.9;

import '@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol';
import {IERC20} from '../interfaces/IERC20.sol';

abstract contract BaseContractV2 is AccessControlUpgradeable, UUPSUpgradeable {
    bytes32 public constant MANAGER_ROLE = keccak256('MANAGER_ROLE');

    modifier onlyAdmin() {
        _checkRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _;
    }

    modifier onlyManager() {
        _checkRole(MANAGER_ROLE, _msgSender());
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function __BaseContract_init() internal onlyInitializing {
        __AccessControl_init();
        __UUPSUpgradeable_init();
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MANAGER_ROLE, _msgSender());
    }

    function emgerencyWithdraw(address token_, address to_) external onlyAdmin {
        IERC20(token_).transfer(to_, IERC20(token_).balanceOf(address(this)));
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyAdmin
    {}

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >=0.5.0;

interface IERC20 {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
}

interface IERC20Mintable is IERC20 {
    function mint(uint256 amount_) external;

    function mint(address account_, uint256 ammount_) external;
}

interface IERC20Burnable is IERC20 {
    function burn(uint256 ammount_) external;

    function burnFrom(address account_, uint256 amount_) external;
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.9;

interface IERC1155 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 value
    );

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
    event ApprovalForAll(
        address indexed account,
        address indexed operator,
        bool approved
    );

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
    function balanceOf(address account, uint256 id)
        external
        view
        returns (uint256);

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
    function isApprovedForAll(address account, address operator)
        external
        view
        returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
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

interface IERC1155Preset is IERC1155MetadataURI {
    function mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external;

    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) external;

    function burn(
        address account,
        uint256 id,
        uint256 value
    ) external;

    function burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory values
    ) external;
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.9;

import '../interfaces/IERC721.sol';

interface IOtto {
    function setBaseURI(string calldata baseURI) external;

    function mint(address to_, uint256 quantity_) external;

    function totalMintable() external view returns (uint256);

    function maxBatch() external view returns (uint256);
}

interface IOttoV2 is IOtto {
    event BaseURIChanged(address indexed sender_, string baseURI_);

    event OpenPortal(
        address indexed sender_,
        uint256 indexed tokenId_,
        bool legendary_
    );

    event SummonOtto(
        address indexed sender_,
        uint256 indexed tokenId_,
        bool legendary_
    );

    event TraitsChanged(uint256 indexed tokenId_, uint16[16] arr_);

    function exists(uint256 tokenId_) external view returns (bool);

    function openPortal(
        uint256 tokenId_,
        uint256[] memory candidates_,
        bool legendary_
    ) external;

    function summon(
        uint256 tokenId_,
        uint256 candidateIndex,
        uint256 birthday_
    ) external;

    function portalStatusOf(uint256 tokenId_)
        external
        view
        returns (PortalStatus);

    function legendary(uint256 tokenId_) external view returns (bool);

    function candidatesOf(uint256 tokenId_)
        external
        view
        returns (uint256[] memory);

    function traitsOf(uint256 tokenId_)
        external
        view
        returns (uint16[16] memory);

    function canOpenAt(uint256 tokenId_) external view returns (uint256);
}

// legecy, don't add new functions here
interface IOttoV3 is IOttoV2 {
    event ItemEquipped(uint256 indexed ottoId_, uint256 indexed itemId_);

    event ItemTookOff(uint256 indexed ottoId_, uint256 indexed itemId_);

    event ItemUsed(uint256 indexed ottoId_, uint256 indexed itemId_);

    event BaseAttributesChanged(uint256 indexed ottoId_, int16[8] attrs_);

    event BaseAttributesUpdated(uint256 indexed ottoId_, int16[8] delta_);

    event EpochBoostsChanged(
        uint256 indexed ottoId_,
        uint32 indexed epoch_,
        int16[9] attrs_
    );

    event EpochBoostsUpdated(
        uint256 indexed ottoId_,
        uint32 indexed epoch_,
        int16[8] delta_
    );

    function numericTraitsOf(uint256 tokenId_) external view returns (uint256);

    function ownedItemsOf(uint256 tokenId_)
        external
        view
        returns (uint256[] memory itemIds_);

    function baseAttributesOf(uint256 tokenId_)
        external
        view
        returns (int16[8] memory);

    function toNumericTraits(uint16[16] memory arr_)
        external
        pure
        returns (uint256);

    function rawTraitsOf(uint256 tokenId_)
        external
        view
        returns (uint16[16] memory);

    function genderOf(uint256 tokenId_) external view returns (Gender);

    function setTraitCode(
        uint256 tokenId_,
        uint8 slot_,
        uint16 code_
    ) external;

    /// @notice Transfer child token from top-down composable to address.
    function transferChild(
        uint256 _fromTokenId,
        address _to,
        address _childContract,
        uint256 _childTokenId
    ) external;

    function updateBaseAttributes(uint256 ottoId_, int16[8] memory delta_)
        external;
}

enum PortalStatus {
    UNOPENED,
    OPENED,
    SUMMONED
}

enum Gender {
    OTTO,
    LOTTIE,
    CLEO
}

interface IOttoLegacyFacet {
    function setBaseURI(string calldata baseURI) external;

    function mint(address to_, uint256 quantity_) external;

    function totalMintable() external view returns (uint256);

    function maxBatch() external view returns (uint256);

    function numericTraitsOf(uint256 tokenId_) external view returns (uint256);

    function exists(uint256 tokenId_) external view returns (bool);

    function openPortal(
        uint256 tokenId_,
        uint256[] memory candidates_,
        bool legendary_
    ) external;

    function summon(
        uint256 tokenId_,
        uint256 candidateIndex,
        uint256 birthday_
    ) external;

    function portalStatusOf(uint256 tokenId_)
        external
        view
        returns (PortalStatus);

    function legendary(uint256 tokenId_) external view returns (bool);

    function candidatesOf(uint256 tokenId_)
        external
        view
        returns (uint256[] memory);

    function traitsOf(uint256 tokenId_)
        external
        view
        returns (uint16[16] memory);

    function canOpenAt(uint256 tokenId_) external view returns (uint256);

    function baseAttributesOf(uint256 tokenId_)
        external
        view
        returns (int16[8] memory);

    function toNumericTraits(uint16[16] memory arr_)
        external
        pure
        returns (uint256);

    function rawTraitsOf(uint256 tokenId_)
        external
        view
        returns (uint16[16] memory);

    function genderOf(uint256 tokenId_) external view returns (Gender);

    function setTraitCode(
        uint256 tokenId_,
        uint8 slot_,
        uint16 code_
    ) external;

    function updateBaseAttributes(uint256 ottoId_, int16[8] memory delta_)
        external;
}

enum ItemActionType {
    EQUIP,
    USE,
    TAKEOFF,
    EQUIP_FROM_OTTO
}

interface IOttoWearingFacet {
    struct ItemActionInput {
        ItemActionType typ;
        uint256 itemId;
        uint256 fromOttoId;
    }
    struct ItemActionOutput {
        bool returned;
        uint256 returnedItemId;
    }

    function equipWillReturn(uint256 ottoId_, uint256 itemId_)
        external
        view
        returns (uint256, bool);

    function equipable(uint256 ottoId_, uint256 itemId_)
        external
        view
        returns (bool);

    function ownedItemsOf(uint256 tokenId_)
        external
        view
        returns (uint256[] memory itemIds_);

    /// @notice Transfer child token from top-down composable to address.
    function transferChild(
        uint256 _fromTokenId,
        address _to,
        address _childContract,
        uint256 _childTokenId
    ) external;

    function transferChildToParent(
        uint256 _fromTokenId,
        address _toContract,
        uint256 _toTokenId,
        address _childContract,
        uint256 _childTokenId,
        bytes memory _data
    ) external;

    function doItemBatchActions(
        uint256 ottoId_,
        ItemActionInput[] calldata inputs_
    ) external returns (ItemActionOutput[] memory outputs_);

    function correctTraits(uint256 tokenId_, uint256 traits) external;

    function correctCandidates(uint256 tokenId_, uint256[] memory traits)
        external;

    function numericRawTraitsOf(uint256 tokenId_)
        external
        view
        returns (uint256);
}

interface IOttoAttributeFacet {
    function willLevelUp(uint256 ottoId_, uint32 inc_)
        external
        view
        returns (bool);

    function increaseExp(uint256 ottoId_, uint32 inc_) external;

    function increaseAp(uint256 ottoId_, uint32 inc_) external;

    function useAttributePoints(uint256 ottoId_, int16[7] calldata values_)
        external;

    function nextLevelExp(uint32 n) external pure returns (uint32);

    function totalLevelExp(uint32 n) external pure returns (uint32);

    function calcExp(
        uint32 fromLv_,
        uint32 fromExp_,
        uint32 inc_
    ) external pure returns (uint32 lv_, uint32 exp_);

    function levelOf(uint256 ottoId_) external view returns (uint32);

    function expOf(uint256 ottoId_) external view returns (uint32);
}

interface IOttoDiamond is
    IOttoLegacyFacet,
    IOttoWearingFacet,
    IOttoAttributeFacet
{}

interface IOttoDiamondERC721 is IOttoDiamond, IERC721 {}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.9;

interface IOttopiaStore {
    function buy(
        address to_,
        uint256 id_,
        uint256 amount_
    ) external;

    function uri(uint256 id_) external view returns (string memory);

    function amountOf(uint256 id_) external view returns (uint256);

    function discountPriceOf(uint256 id_) external view returns (uint256);

    function payWithMatic(string calldata key_, uint256 amount_)
        external
        payable;

    function totalPayment(string calldata key_, uint256 amont_)
        external
        view
        returns (uint256);

    function distributeMatic() external payable;
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.9;

import '../interfaces/IERC721.sol';

interface IAdventure {
    function shortenDuration(uint256 ottoId, uint256 sec) external;

    function shortenCooldown(uint256 ottoId, uint256 sec) external;

    function setExpMultiplier(uint256 ottoId, uint32 multiplier) external;

    function setItemAmountMultiplier(uint256 ottoId, uint32 multiplier)
        external;

    function canFinishAt(uint256 ottoId) external view returns (uint256);

    function restingUntil(uint256 ottoId) external view returns (uint256);

    function expMultiplierOf(uint256 ottoId) external view returns (uint32);

    function itemAmountMultiplierOf(uint256 ottoId)
        external
        view
        returns (uint32);

    function ottoOwnerOf(uint256 ottoId_) external view returns (address);
}

interface IAdventurePass {
    function issuePass(address to_) external returns (uint256);

    function revokePass(uint256 id) external;
}

interface IAdventurePassERC721 is IERC721 {
    function issuePass(address to_) external returns (uint256);

    function revokePass(uint256 id) external;
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.9;

interface IRand {
    function rand(
        uint256 seed_,
        uint256 salt_,
        uint256 n_
    ) external view returns (uint256);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.3) (utils/cryptography/ECDSA.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

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
     *
     * May emit a {RoleGranted} event.
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
     *
     * May emit a {RoleRevoked} event.
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
     *
     * May emit a {RoleRevoked} event.
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
     * May emit a {RoleGranted} event.
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
     *
     * May emit a {RoleGranted} event.
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
     *
     * May emit a {RoleRevoked} event.
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
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../ERC1967/ERC1967UpgradeUpgradeable.sol";
import "./Initializable.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is Initializable, IERC1822ProxiableUpgradeable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal onlyInitializing {
    }

    function __UUPSUpgradeable_init_unchained() internal onlyInitializing {
    }
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        require(address(this) == __self, "UUPSUpgradeable: must not be called through delegatecall");
        _;
    }

    /**
     * @dev Implementation of the ERC1822 {proxiableUUID} function. This returns the storage slot used by the
     * implementation. It is used to validate that the this implementation remains valid after an upgrade.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy. This is guaranteed by the `notDelegated` modifier.
     */
    function proxiableUUID() external view virtual override notDelegated returns (bytes32) {
        return _IMPLEMENTATION_SLOT;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
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
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

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
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
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
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
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
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822ProxiableUpgradeable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeaconUpgradeable.sol";
import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/StorageSlotUpgradeable.sol";
import "../utils/Initializable.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable {
    function __ERC1967Upgrade_init() internal onlyInitializing {
    }

    function __ERC1967Upgrade_init_unchained() internal onlyInitializing {
    }
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822ProxiableUpgradeable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlotUpgradeable {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

interface IERC721 {
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );

    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function balanceOf(address owner) external view returns (uint256 balance);

    function tokenOfOwnerByIndex(address owner, uint256 index)
        external
        view
        returns (uint256 tokenId);

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function approve(address to, uint256 tokenId) external;

    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);

    function setApprovalForAll(address operator, bool _approved) external;

    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    function burn(uint256 tokenId) external;

    function mint(address to) external;

    function totalSupply() external view returns (uint256);
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