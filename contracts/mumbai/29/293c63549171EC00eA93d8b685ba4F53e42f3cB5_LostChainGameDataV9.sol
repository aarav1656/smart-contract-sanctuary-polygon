// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol';

import './LostChainForwarder.sol';
import './interface/ILostChainRBA.sol';
import './lib/CustomERC2771ContextUpgradeable.sol';

import './interface/ILostChainNFT.sol';
import './interface/ILostWorldData.sol';
import './interface/ILostChainUserData.sol';
import './interface/ILostChainToken.sol';
import './interface/ILostWorldNFT.sol';

contract LostChainGameDataV9 is CustomERC2771ContextUpgradeable, UUPSUpgradeable, ReentrancyGuardUpgradeable {
    // Lost Chain RBA Linker
    ILostChainRBA private LCRBALinker;
    modifier onlyRole(string memory name, address account) {
        require(LCRBALinker.checkAccountRole(name, account), 'LCGD: Unauthorized');
        _;
    }

    function setRBALinker(address rbaLinkerAddress) public onlyRole('DEFAULT_ADMIN_ROLE', _msgSender()) nonReentrant {
        require(rbaLinkerAddress != address(0x0), 'LCGD: RBA linker is zero address');
        LCRBALinker = ILostChainRBA(rbaLinkerAddress);
    }

    // End of Lost Chain RBA Linker
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        LostChainForwarder forwarder,
        address rbaLinkerAddress,
        address nftAddress,
        address userDataAddress,
        address worldDataAddress,
        address tokenAddress,
        address worldNftAddress,
        address vaultAddress
    ) public initializer {
        require(address(forwarder) != address(0x0), 'LCGD: Forwarder is zero address');
        require(rbaLinkerAddress != address(0x0), 'LCGD: RBA linker is zero address');
        require(nftAddress != address(0x0), 'LCGD: NFT is zero address');
        require(userDataAddress != address(0x0), 'LCGD: User data is zero address');
        require(worldDataAddress != address(0x0), 'LCGD: World data is zero address');
        require(tokenAddress != address(0x0), 'LCGD: Token is zero address');
        require(worldNftAddress != address(0x0), 'LCGD: World NFT is zero address');
        require(vaultAddress != address(0x0), 'LCGD: Vault Address is zero address');
        LCRBALinker = ILostChainRBA(rbaLinkerAddress);
        LCNFT = ILostChainNFT(nftAddress);
        LCUD = ILostChainUserData(userDataAddress);
        LWD = ILostWorldData(worldDataAddress);
        LCT = ILostChainToken(tokenAddress);
        LWNFT = ILostWorldNFT(worldNftAddress);
        vault = vaultAddress;

        initializeERC2771(address(forwarder));
        __UUPSUpgradeable_init();
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyRole('DEFAULT_ADMIN_ROLE', _msgSender())
    {}

    // End of UUPS
    ILostChainNFT private LCNFT;
    ILostChainUserData private LCUD;
    ILostWorldData private LWD;
    ILostChainToken private LCT;
    ILostWorldNFT private LWNFT;
    address private vault;

    // Crafting
    struct Crafting {
        bool active;
        uint256 entityDataId;
        uint256 completedTime;
        string outputType;
    }
    mapping(address => Crafting) craftingList;

    // Adventuring
    struct Adventure {
        bool isAdventuring;
        uint8[] rewardAmount;
        uint8[] maxRewardAmount;
        uint256 landId;
        uint256[] enemyList;
        uint256[] heroIds;
        uint256[] rewardList;
    }
    mapping(address => Adventure) adventuring;

    event StartCrafting(address crafter, uint256 respectiveEntityId);
    event ClaimCrafting(address crafter, uint256 nftId);
    event Paid(address payer, address payee, uint256 amount);
    event AdventureComplete(address adventurer, uint256 landId, bool win);

    function setLCNFT(address nftAddress) public onlyRole('DEFAULT_ADMIN_ROLE', msg.sender) {
        require(nftAddress != address(0x0), 'LCGD: NFT is zero address');
        LCNFT = ILostChainNFT(nftAddress);
    }

    function setLWD(address lwdAddress) public onlyRole('DEFAULT_ADMIN_ROLE', msg.sender) {
        require(lwdAddress != address(0x0), 'LCGD: LWD is zero address');
        LWD = ILostWorldData(lwdAddress);
    }

    function setLCUD(address lcudAddress) public onlyRole('DEFAULT_ADMIN_ROLE', msg.sender) {
        require(lcudAddress != address(0x0), 'LCGD: LCUD is zero address');
        LCUD = ILostChainUserData(lcudAddress);
    }

    function setLCT(address lctAddress) public onlyRole('DEFAULT_ADMIN_ROLE', msg.sender) {
        require(lctAddress != address(0x0), 'LCGD: LCT is zero address');
        LCT = ILostChainToken(lctAddress);
    }

    function setLWNFT(address lwNFTAddress) public onlyRole('DEFAULT_ADMIN_ROLE', msg.sender) {
        require(lwNFTAddress != address(0x0), 'LCGD: LWNFTAddress is zero address');
        LWNFT = ILostWorldNFT(lwNFTAddress);
    }

    function setVault(address vaultAddress) public onlyRole('DEFAULT_ADMIN_ROLE', msg.sender) {
        require(vaultAddress != address(0x0), 'LCGD: NFT is zero address');
        vault = vaultAddress;
    }

    function addCrafting(
        address user,
        uint256[] calldata materialIds,
        uint256[] calldata amount,
        uint256 entityDataId,
        uint32 duration,
        string memory outputType
    ) public onlyRole('TRUSTED_FORWARDER', msg.sender) nonReentrant {
        require(address(LCNFT) != address(0x0), 'LCGD: LCNFT address not set');
        require(user != address(0x0), 'LCGD: Crafter is zero address');
        require(materialIds.length > 0, 'LCGD: Materials ID is empty');
        require(materialIds.length == amount.length, 'LCGD: Material id & amount length mismatch');
        require(duration > 0, 'LCGD: Duration is zero');
        require(entityDataId >= 0, 'LCGD: Entity Data ID is zero');
        require(bytes(outputType).length > 0, 'LCGD: Output type is empty');
        require(!craftingList[user].active, 'LCGD: Max crafting reached');

        // Check user requirement
        uint256[] memory balances = LCNFT.userNFTBalances(user, materialIds);
        for (uint256 i = 0; i < balances.length; i++) {
            require(balances[i] >= amount[i], 'LCGD: Insufficient requirement');
        }

        LCNFT.gameDataBurnNFT(msg.sender, _msgSender(), materialIds, amount);
        craftingList[user].active = true;
        craftingList[user].entityDataId = entityDataId;
        craftingList[user].completedTime = block.timestamp + duration;
        craftingList[user].outputType = outputType;

        emit StartCrafting(user, entityDataId);
    }

    function checkCrafting(address user) public view returns (Crafting memory) {
        require(craftingList[user].active, 'LCGD: User has no active crafting');
        return craftingList[user];
    }

    function checkCraftingEmpty(address user) public view returns (bool) {
        require(!craftingList[user].active, 'LCGD: User has an active crafting');
        return true;
    }

    function claimCrafting(
        address user,
        uint256 nftId,
        string memory tokenURI
    ) public onlyRole('TRUSTED_FORWARDER', msg.sender) nonReentrant {
        require(craftingList[user].active, 'LCGD: User has no active crafting');
        require(block.timestamp >= craftingList[user].completedTime, 'LCGD: Crafting not completed yet');
        craftingList[user].active = false;
        craftingList[user].entityDataId = 0;
        craftingList[user].completedTime = 0;
        craftingList[user].outputType = '';

        uint256[] memory id = new uint256[](1);
        id[0] = craftingList[user].entityDataId;

        uint256[] memory amount = new uint256[](1);
        amount[0] = 1;

        LCNFT.gameDataMint(msg.sender, user, nftId, false, tokenURI);

        emit ClaimCrafting(user, nftId);
    }

    struct LandData {
        bool playable;
        address owner;
        uint8[] rewardAmount;
        uint8[] maxRewardAmount;
        uint16 x;
        uint16 y;
        uint256 landId;
        uint256 dungeonId;
        uint256 landPrice;
        uint256[] enemyIdList;
        uint256[] rewardIdList;
    }

    function adventure(
        uint256 landId,
        bytes32 requestedHash,
        uint256[] memory heroIds
    ) public onlyRole('TRUSTED_FORWARDER', msg.sender) nonReentrant {
        address player = _msgSender();
        (
            uint8[] memory rewardAmount,
            uint8[] memory maxRewardAmount,
            uint256[] memory enemyList,
            uint256[] memory rewardList,
            uint256 landPrice,
            address landOwner
        ) = LWNFT.getLandData(landId);
        require(landOwner != player, 'LCGD: Player are not allowed to play at their own land');
        require(LCT.getUserBalance(player) > landPrice, 'LCGD: Insufficient fund');
        require(requestedHash == LWNFT.getLandHash(landId), 'LCGD: Land hash has changed');
        require(heroIds.length > 0, 'LCGD: No hero selected');
        uint256[] memory nftOwned = LCNFT.userNFTBalances(_msgSender(), heroIds);
        for (uint256 i = 0; i < heroIds.length; i++) {
            require(LCNFT.checkNFTHero(heroIds[i]), 'LCGD: Selected hero id is not a hero');
            for (uint256 j = 0; j < heroIds.length; j++) {
                require(nftOwned[j] > 0, 'LCGD: User dont own that NFT');
            }
        }

        LWD.decreaseCharge(msg.sender, landId, maxRewardAmount, rewardList);

        uint256 correctedPrice = landPrice * 10**LCT.getDecimal();
        LCT.gameDataTokenTransfer(msg.sender, _msgSender(), landOwner, correctedPrice);
        adventuring[player].isAdventuring = true;
        adventuring[player].landId = landId;
        adventuring[player].heroIds = heroIds;
        adventuring[player].enemyList = enemyList;
        adventuring[player].rewardList = rewardList;
        adventuring[player].rewardAmount = rewardAmount;
        adventuring[player].maxRewardAmount = maxRewardAmount;

        emit Paid(_msgSender(), landOwner, landPrice);
    }

    function adventureComplete(
        bool result,
        uint256 landId,
        uint256[] memory rewardAmounts,
        uint256[] memory xpAmount
    ) public onlyRole('TRUSTED_FORWARDER', msg.sender) nonReentrant {
        address player = _msgSender();
        require(adventuring[player].isAdventuring, 'LCGD: User is not adventuring');
        require(adventuring[player].landId == landId, 'LCGD: Land id is not the same');
        Adventure memory curAdventure = adventuring[player];

        require(adventuring[player].rewardList.length == rewardAmounts.length, 'LCGD: Rewards mismatch');
        require(adventuring[player].heroIds.length == xpAmount.length, 'LCGD: XP mismatch');

        adventuring[player].isAdventuring = false;
        adventuring[player].landId = 0;
        adventuring[player].rewardAmount = new uint8[](0);
        adventuring[player].maxRewardAmount = new uint8[](0);
        adventuring[player].heroIds = new uint256[](0);
        adventuring[player].enemyList = new uint256[](0);
        adventuring[player].rewardList = new uint256[](0);

        for (uint256 i = 0; i < rewardAmounts.length; i++) {
            require(rewardAmounts[i] > 0, 'LCGD: Reward must be 0 or more');
        }
        uint256[] memory vaultBalances = LCNFT.userNFTBalances(vault, adventuring[player].rewardList);
        for (uint256 i = 0; i < vaultBalances.length; i++) {
            require(vaultBalances[i] >= rewardAmounts[i], 'LCGD: Vault has insufficient NFT');
        }

        // Give xp
        for (uint256 i = 0; i < rewardAmounts.length; i++) {
            LCNFT.addHeroExperience(msg.sender, curAdventure.heroIds, xpAmount);
        }

        // Give reward
        if (result)
            LCNFT.gameDataSendNFT(msg.sender, vault, _msgSender(), adventuring[player].rewardList, rewardAmounts);

        emit AdventureComplete(player, curAdventure.landId, result);
    }

    function getAdventure(address user) public view returns (Adventure memory) {
        require(adventuring[user].isAdventuring, 'LCGD: User has no active adventure');
        return adventuring[user];
    }

    function isAdventuring(address user) public view returns (bool) {
        return adventuring[user].isAdventuring;
    }

    // TEST FUNCTION TO ALTER BYTECODE (RE-VERIFY)
    function TESTING61() external pure returns (bool) {
        return true;
    }
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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// solhint-disable not-rely-on-time
// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.17;
pragma abicoder v2;

import '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';
import '@openzeppelin/contracts/utils/introspection/ERC165.sol';

import './interface/IForwarder.sol';
import './interface/ILostChainRBA.sol';

/**
 * @title The Forwarder Implementation
 * @notice This implementation of the `IForwarder` interface uses ERC-712 signatures and stored nonces for verification.
 */
contract LostChainForwarder is IForwarder, ERC165 {
    using ECDSA for bytes32;

    address private constant DRY_RUN_ADDRESS = 0x0000000000000000000000000000000000000000;

    string public constant GENERIC_PARAMS =
        'address from,address to,uint256 value,uint256 gas,uint256 nonce,bytes data,uint256 validUntilTime';

    string public constant EIP712_DOMAIN_TYPE =
        'EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)';

    mapping(bytes32 => bool) public typeHashes;
    mapping(bytes32 => bool) public domains;

    // Nonces of senders, used to prevent replay attacks
    mapping(address => uint256) private nonces;

    event TxRelayed(bool success, bytes returnData);

    // solhint-disable-next-line no-empty-blocks
    receive() external payable {}

    // Lost Chain RBA Linker
    ILostChainRBA private LCRBALinker;
    modifier onlyRole(string memory name, address account) {
        require(LCRBALinker.checkAccountRole(name, account), 'LCF: Unauthorized');
        _;
    }

    function setRBALinker(address rbaLinkerAddress) public onlyRole('DEFAULT_ADMIN_ROLE', msg.sender) {
        require(rbaLinkerAddress != address(0x0), 'LCF: RBA linker is zero address');
        LCRBALinker = ILostChainRBA(rbaLinkerAddress);
    }

    // End of Lost Chain RBA Linker

    /// @inheritdoc IForwarder
    function getNonce(address from) public view override returns (uint256) {
        return nonces[from];
    }

    constructor(address rbaLinkerAddress) {
        string memory requestType = string(abi.encodePacked('ForwardRequest(', GENERIC_PARAMS, ')'));
        registerRequestTypeInternal(requestType);

        LCRBALinker = ILostChainRBA(rbaLinkerAddress);
    }

    /// @inheritdoc IForwarder
    function verify(
        ForwardRequest calldata req,
        bytes32 domainSeparator,
        bytes32 requestTypeHash,
        bytes calldata sig
    ) external view override onlyRole('RELAYER', msg.sender) {
        _verifyNonce(req);
        _verifySig(req, domainSeparator, requestTypeHash, sig);
    }

    /// @inheritdoc IForwarder
    function execute(
        ForwardRequest calldata req,
        bytes32 domainSeparator,
        bytes32 requestTypeHash,
        bytes calldata sig
    ) external payable override onlyRole('RELAYER', msg.sender) returns (bool success, bytes memory ret) {
        _verifySig(req, domainSeparator, requestTypeHash, sig);
        _verifyAndUpdateNonce(req);

        require(req.validUntilTime == 0 || req.validUntilTime > block.timestamp, 'FWD: request expired');

        uint256 gasForTransfer = 0;
        if (req.value != 0) {
            gasForTransfer = 40000; //buffer in case we need to move eth after the transaction.
        }
        bytes memory callData = abi.encodePacked(req.data, req.from);
        require((gasleft() * 63) / 64 >= req.gas + gasForTransfer, 'FWD: insufficient gas');
        // solhint-disable-next-line avoid-low-level-calls
        (success, ret) = req.to.call{gas: req.gas, value: req.value}(callData);

        if (req.value != 0 && address(this).balance > 0) {
            // can't fail: req.from signed (off-chain) the request, so it must be an EOA...
            payable(req.from).transfer(address(this).balance);
        }

        if (success == false) {
            assembly {
                let ptr := mload(0x40)
                let size := returndatasize()
                returndatacopy(ptr, 0, size)
                revert(ptr, size)
            }
        }

        emit TxRelayed(success, ret);
        return (success, ret);
    }

    function _verifyNonce(ForwardRequest calldata req) internal view {
        require(nonces[req.from] == req.nonce, 'FWD: nonce mismatch');
    }

    function _verifyAndUpdateNonce(ForwardRequest calldata req) internal {
        require(nonces[req.from]++ == req.nonce, 'FWD: nonce mismatch');
    }

    /// @inheritdoc IForwarder
    function registerRequestType(string calldata typeName, string calldata typeSuffix)
        public
        onlyRole('DEFAULT_ADMIN_ROLE', msg.sender)
    {
        for (uint256 i = 0; i < bytes(typeName).length; i++) {
            bytes1 c = bytes(typeName)[i];
            require(c != '(' && c != ')', 'FWD: invalid typename');
        }

        string memory requestType = string(abi.encodePacked(typeName, '(', GENERIC_PARAMS, ',', typeSuffix));
        registerRequestTypeInternal(requestType);
    }

    /// @inheritdoc IForwarder
    function registerDomainSeparator(string calldata name, string calldata version)
        public
        onlyRole('DEFAULT_ADMIN_ROLE', msg.sender)
    {
        uint256 chainId;
        /* solhint-disable-next-line no-inline-assembly */
        assembly {
            chainId := chainid()
        }

        bytes memory domainValue = abi.encode(
            keccak256(bytes(EIP712_DOMAIN_TYPE)),
            keccak256(bytes(name)),
            keccak256(bytes(version)),
            chainId,
            address(this)
        );

        bytes32 domainHash = keccak256(domainValue);

        domains[domainHash] = true;
        emit DomainRegistered(domainHash, domainValue);
    }

    function registerRequestTypeInternal(string memory requestType) internal {
        bytes32 requestTypehash = keccak256(bytes(requestType));
        typeHashes[requestTypehash] = true;
        emit RequestTypeRegistered(requestTypehash, requestType);
    }

    function _verifySig(
        ForwardRequest calldata req,
        bytes32 domainSeparator,
        bytes32 requestTypeHash,
        bytes calldata sig
    ) internal view virtual {
        require(domains[domainSeparator], 'FWD: unregistered domain sep.');
        require(typeHashes[requestTypeHash], 'FWD: unregistered typehash');
        bytes32 digest = _hashTypedDataV4(
            domainSeparator,
            keccak256(
                abi.encode(
                    requestTypeHash,
                    req.from,
                    req.to,
                    req.value,
                    req.gas,
                    req.nonce,
                    keccak256(req.data),
                    req.validUntilTime
                )
            )
        );

        // solhint-disable-next-line avoid-tx-origin
        require(tx.origin == DRY_RUN_ADDRESS || digest.recover(sig) == req.from, 'FWD: signature mismatch');
    }

    function _hashTypedDataV4(bytes32 domainSeparator, bytes32 structHash) private pure returns (bytes32) {
        return keccak256(abi.encodePacked('\x19\x01', domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

interface ILostChainRBA {
    function checkAccountRole(string memory name, address account) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (metatx/ERC2771Context.sol)

pragma solidity ^0.8.17;

import '@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';

/**
 * @dev Context variant with ERC2771 support.
 */
abstract contract CustomERC2771ContextUpgradeable is Initializable, ContextUpgradeable {
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    address private _trustedForwarder;

    function initializeERC2771(address trustedForwarder) internal {
        _trustedForwarder = trustedForwarder;
    }

    function isTrustedForwarder(address forwarder) internal view returns (bool) {
        return forwarder == _trustedForwarder;
    }

    function _msgSender() internal view virtual override returns (address sender) {
        if (isTrustedForwarder(msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            /// @solidity memory-safe-assembly
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return super._msgSender();
        }
    }

    function _msgData() internal view virtual override returns (bytes calldata) {
        if (isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length - 20];
        } else {
            return super._msgData();
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

interface ILostChainNFT {
    function userNFTBalances(address account, uint256[] memory ids) external view returns (uint256[] memory);

    function userNFTBalance(address account, uint256 id) external view returns (uint256);

    function gameDataSendNFT(
        address operator,
        address from,
        address to,
        uint256[] memory id,
        uint256[] memory amount
    ) external;

    function gameDataBurnNFT(
        address operator,
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) external;

    function gameDataMint(
        address operator,
        address to,
        uint256 id,
        bool isHero,
        string memory tokenURI
    ) external;

    function checkNFTRewardable(uint256 nftId) external view returns (bool);

    function checkNFTHero(uint256 nftIds) external view returns (bool);

    function checkNFTRecharger(uint256 nftId) external view returns (bool);

    function getRechargeAmount(uint256 nftId) external view returns (uint8);

    function addHeroExperience(
        address operator,
        uint256[] memory ids,
        uint256[] memory xpAmount
    ) external;

    function getRewardableRarity(uint256 nftId) external view returns (string memory);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

interface ILostWorldData {
    struct Enemy {
        bool exists;
        bool disabled;
        string name;
        string image;
        uint256 enemyId;
        uint256 health;
        uint256 damage;
        uint256 defense;
        uint256 criticalChance;
        uint256 attackSpeed;
        uint256 cleaveChance;
    }

    function checkEnemyAvailable(uint256 enemyId) external view returns (bool);

    function getEnemyById(uint256[] memory ids) external view returns (Enemy[] memory);

    function initRecharge(address operator, uint256 landId) external;

    function decreaseCharge(
        address operator,
        uint256 landId,
        uint8[] memory maxRewardAmount,
        uint256[] memory rewardList
    ) external;

    function getEnemyRarity(uint256 enemyId) external view returns (uint8, string memory);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

interface ILostChainUserData {
    function consumeEnergy(address operator, address playerAddress) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

interface ILostChainToken {
    function gameDataTokenTransfer(
        address operator,
        address from,
        address to,
        uint256 amount
    ) external;

    function getUserBalance(address playerAddreess) external view returns (uint256);

    function getDecimal() external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

interface ILostWorldNFT {
    function getLandData(uint256 landId)
        external
        view
        returns (
            uint8[] memory,
            uint8[] memory,
            uint256[] memory,
            uint256[] memory,
            uint256,
            address
        );

    function getLandHash(uint256 landId) external view returns (bytes32);
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

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.17;
pragma abicoder v2;

import '@openzeppelin/contracts/interfaces/IERC165.sol';

/**
 * @title The Forwarder Interface
 * @notice The contracts implementing this interface take a role of authorization, authentication and replay protection
 * for contracts that choose to trust a `Forwarder`, instead of relying on a mechanism built into the Ethereum protocol.
 *
 * @notice if the `Forwarder` contract decides that an incoming `ForwardRequest` is valid, it must append 20 bytes that
 * represent the caller to the `data` field of the request and send this new data to the target address (the `to` field)
 *
 * :warning: **Warning** :warning: The Forwarder can have a full control over a `Recipient` contract.
 * Any vulnerability in a `Forwarder` implementation can make all of its `Recipient` contracts susceptible!
 * Recipient contracts should only trust forwarders that passed through security audit,
 * otherwise they are susceptible to identity theft.
 */
interface IForwarder is IERC165 {
    /**
     * @notice A representation of a request for a `Forwarder` to send `data` on behalf of a `from` to a target (`to`).
     */
    struct ForwardRequest {
        address from;
        address to;
        uint256 value;
        uint256 gas;
        uint256 nonce;
        uint256 validUntilTime;
        bytes data;
    }

    event DomainRegistered(bytes32 indexed domainSeparator, bytes domainValue);

    event RequestTypeRegistered(bytes32 indexed typeHash, string typeStr);

    /**
     * @param from The address of a sender.
     * @return The nonce for this address.
     */
    function getNonce(address from) external view returns (uint256);

    /**
     * @notice Verify the transaction is valid and can be executed.
     * Implementations must validate the signature and the nonce of the request are correct.
     * Does not revert and returns successfully if the input is valid.
     * Reverts if any validation has failed. For instance, if either signature or nonce are incorrect.
     * Reverts if `domainSeparator` or `requestTypeHash` are not registered as well.
     */
    function verify(
        ForwardRequest calldata forwardRequest,
        bytes32 domainSeparator,
        bytes32 requestTypeHash,
        bytes calldata signature
    ) external view;

    /**
     * @notice Executes a transaction specified by the `ForwardRequest`.
     * The transaction is first verified and then executed.
     * The success flag and returned bytes array of the `CALL` are returned as-is.
     *
     * This method would revert only in case of a verification error.
     *
     * All the target errors are reported using the returned success flag and returned bytes array.
     *
     * @param forwardRequest All requested transaction parameters.
     * @param domainSeparator The domain used when signing this request.
     * @param requestTypeHash The request type used when signing this request.
     * @param signature The client signature to be validated.
     *
     * @return success The success flag of the underlying `CALL` to the target address.
     * @return ret The byte array returned by the underlying `CALL` to the target address.
     */
    function execute(
        ForwardRequest calldata forwardRequest,
        bytes32 domainSeparator,
        bytes32 requestTypeHash,
        bytes calldata signature
    ) external payable returns (bool success, bytes memory ret);

    /**
     * @notice Register a new Request typehash.
     *
     * @notice This is necessary for the Forwarder to be able to verify the signatures conforming to the ERC-712.
     *
     * @param typeName The name of the request type.
     * @param typeSuffix Any extra data after the generic params. Must contain add at least one param.
     * The generic ForwardRequest type is always registered by the constructor.
     */
    function registerRequestType(string calldata typeName, string calldata typeSuffix) external;

    /**
     * @notice Register a new domain separator.
     *
     * @notice This is necessary for the Forwarder to be able to verify the signatures conforming to the ERC-712.
     *
     * @notice The domain separator must have the following fields: `name`, `version`, `chainId`, `verifyingContract`.
     * The `chainId` is the current network's `chainId`, and the `verifyingContract` is this Forwarder's address.
     * This method accepts the domain name and version to create and register the domain separator value.
     * @param name The domain's display name.
     * @param version The domain/protocol version.
     */
    function registerDomainSeparator(string calldata name, string calldata version) external;
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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

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