// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "../common/CommonLib.sol";

contract Vesting is
    Initializable,
    UUPSUpgradeable,
    OwnableUpgradeable,
    PausableUpgradeable
{
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using AddressUpgradeable for address;
    using CountersUpgradeable for CountersUpgradeable.Counter;

    enum SchemeType {
        investor,
        member
    }

    struct Scheme {
        string schemeName;
        uint256 vestingDuration;
        uint256 vestingFrequency;
        SchemeType schemeType;
        bool schemeExist;
    }

    struct Subscription {
        uint256 schemeId;
        address wallet;
        uint256 startTime;
        uint256 cliffTime;
        uint256 vestingStartTime;
        uint256 vestingEndTime;
        uint256 vestedAmount;
        uint256 numberOfClaimed;
        uint256 nextClaimTime;
        uint256 depositAmount;
        bool isActive;
    }

    IERC20Upgradeable public erc20Token;
    CountersUpgradeable.Counter private schemeCount;
    CountersUpgradeable.Counter private subscriptionCount;
    CountersUpgradeable.Counter private roundCount;
    //@dev epoch time and in seconds
    address public emergencyWallet;
    uint256 public secondsOfDay;
    uint256 public tge;
    uint256 public contractDeploymentTime;
    uint256[] private activeSubscriptions;

    mapping(uint256 => Scheme) private _schemes;
    mapping(uint256 => Subscription) private _subscriptions;
    mapping(address => bool) private _operators;
    mapping(address => bool) private _upgrades;
    mapping(address => bool) private _wallets;
    mapping(address => uint256[]) private _totalSubscriptionsByWallet;

    function initialize(
        address gameStateToken,
        address upgradeWallet,
        uint256 secondsOfDay_,
        address _emergencyWallet
    ) public initializer {
        __UUPSUpgradeable_init();
        __Ownable_init();
        __Pausable_init();
        secondsOfDay = secondsOfDay_;
        erc20Token = IERC20Upgradeable(gameStateToken);
        setOperator(_msgSender(), true);
        setUpgradeWallet(upgradeWallet, true);
        emergencyWallet = _emergencyWallet;
        contractDeploymentTime =
            (block.timestamp / secondsOfDay) *
            secondsOfDay;
        tge = (block.timestamp / secondsOfDay) * secondsOfDay;
    }

    event SchemeCreated(
        uint256 schemeId,
        string schemeName,
        uint256 vestingDuration,
        uint256 vestingFrequency,
        SchemeType SchemeType,
        bool schemeExist
    );

    event SubscriptionAdded(
        uint256 subscriptionId,
        uint256 schemeId,
        address wallet,
        uint256 startTimeVesting,
        uint256 cliffTime,
        uint256 endTimeVesting,
        uint256 depositAmount
    );

    event Deposit(uint256 subscriptionId, uint256 amount, uint256 timeDeposit);
    event EmergencyWithdraw(
        address emergencyWallet,
        address erc20Contract,
        uint256 balanceOfThis
    );

    event ClaimSucceeded(
        uint256 subscriptionId,
        address wallet,
        uint256 claimableAmount,
        uint256 vestedAmount,
        uint256 depositAmount,
        uint256 timeClaim,
        uint256 nextTimeClaim
    );
    event VestingContractConfigured(address erc20Contract);
    event OperatorAdded(address operator, bool isOperator);
    event UpgraderAdded(address upgrader, bool isUpgrader);
    event TokenGenerationEventConfigured(uint256 time);

    modifier onlyOperator() {
        _onlyOperator();
        _;
    }

    modifier onlyUpgradeWalletOrOwner() {
        _onlyUpgradeWalletOrOwner();
        _;
    }

    modifier schemeExist(uint256 schemeId) {
        _schemeExist(schemeId);
        _;
    }

    modifier subcriptionExist(uint256 subscriptionId) {
        _subscriptionExist(subscriptionId);
        _;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function setERC20Token(address erc20Contract) external onlyOwner {
        require(
            erc20Contract.isContract() && erc20Contract != address(0),
            "ERC20 address must be a smart contract"
        );
        erc20Token = IERC20Upgradeable(erc20Contract);
        emit VestingContractConfigured(erc20Contract);
    }

    //! for test
    function setSecondsOfDay(uint256 secondsOfDay_) external onlyOwner {
        secondsOfDay = secondsOfDay_;
    }

    function setTGE(uint256 time) external onlyOwner {
        require(tge == 0, "Can only be initialized once");
        require(time > 0, "Time must be greater than zero");
        tge = time;
        emit TokenGenerationEventConfigured(tge);
    }

    function addScheme(
        string memory schemeName,
        uint256 vestingDuration,
        uint256 vestingFrequency,
        SchemeType schemeType
    ) external onlyOperator {
        require(bytes(schemeName).length > 0, "scheme name must not be empty");

        require(
            vestingFrequency > 0 && vestingFrequency < vestingDuration,
            "vestingFrequency must be greater than zero and less than duration"
        );
        require(
            vestingDuration % vestingFrequency == 0,
            "Duration must be divisible by vestingFrequency"
        );
        require(vestingDuration > 0, "Duration must be greater than zero");

        schemeCount.increment();
        uint256 schemeId = schemeCount.current();
        Scheme storage scheme = _schemes[schemeId];
        scheme.schemeName = schemeName;
        scheme.vestingDuration = vestingDuration * secondsOfDay;
        scheme.vestingFrequency = vestingFrequency * secondsOfDay;
        scheme.schemeType = schemeType;
        scheme.schemeExist = true;

        emit SchemeCreated(
            schemeId,
            scheme.schemeName,
            scheme.vestingDuration,
            scheme.vestingFrequency,
            scheme.schemeType,
            scheme.schemeExist
        );
    }

    function addSubscription(
        uint256 schemeId,
        address wallet,
        uint256 cliffTime,
        uint256 depositAmount
    ) external whenNotPaused onlyOperator schemeExist(schemeId) {
        Scheme memory scheme = _schemes[schemeId];
        require(wallet != address(0), "invalid address");
        require(cliffTime > 0, "invalid cliff time");
        subscriptionCount.increment();

        uint256 subscriptionId = subscriptionCount.current();
        Subscription storage subscription = _subscriptions[subscriptionId];
        subscription.schemeId = schemeId;
        subscription.wallet = wallet;
        subscription.startTime = block.timestamp;
        subscription.cliffTime = cliffTime * secondsOfDay;

        if (scheme.schemeType == SchemeType.investor) {
            subscription.vestingStartTime =
                ((subscription.startTime + subscription.cliffTime) /
                    secondsOfDay) *
                secondsOfDay;
        } else if (scheme.schemeType == SchemeType.member) {
            if (
                contractDeploymentTime + subscription.cliffTime >
                block.timestamp
            ) {
                subscription.vestingStartTime =
                    ((contractDeploymentTime + subscription.cliffTime) /
                        secondsOfDay) *
                    secondsOfDay;
            } else {
                subscription.vestingStartTime =
                    (subscription.startTime / secondsOfDay) *
                    secondsOfDay;
            }
        }
        subscription.depositAmount = depositAmount;
        subscription.vestingEndTime =
            subscription.vestingStartTime +
            scheme.vestingDuration;
        subscription.vestedAmount = 0;
        subscription.numberOfClaimed = 0;
        subscription.nextClaimTime = subscription.vestingStartTime;

        subscription.isActive = true;
        activeSubscriptions.push(subscriptionId);
        _wallets[subscription.wallet] = true;

        _totalSubscriptionsByWallet[subscription.wallet].push(subscriptionId);
        erc20Token.safeTransferFrom(_msgSender(), address(this), depositAmount);

        emit SubscriptionAdded(
            subscriptionId,
            subscription.schemeId,
            subscription.wallet,
            subscription.vestingStartTime,
            subscription.cliffTime,
            subscription.vestingEndTime,
            subscription.depositAmount
        );
    }

    function deposit(uint256 subscriptionId, uint256 amount)
        external
        whenNotPaused
        onlyOperator
        subcriptionExist(subscriptionId)
    {
        Subscription storage subscription = _subscriptions[subscriptionId];
        Scheme memory scheme = _schemes[subscription.schemeId];

        require(
            scheme.schemeType == SchemeType.member,
            "deposit only for member"
        );
        require(
            block.timestamp < subscription.vestingEndTime,
            "vesting was ended"
        );

        subscription.depositAmount += amount;
        erc20Token.safeTransferFrom(_msgSender(), address(this), amount);
        emit Deposit(subscriptionId, amount, block.timestamp);
    }

    function claim(uint256 subscriptionId)
        external
        whenNotPaused
        subcriptionExist(subscriptionId)
    {
        Subscription storage subscription = _subscriptions[subscriptionId];
        require(
            _msgSender() == subscription.wallet,
            "you're not owner of subscription"
        );

        require(subscription.isActive == true, "vesting is unavailable");
        require(
            block.timestamp >= subscription.nextClaimTime,
            "It's not time to claim"
        );

        uint256 _completedSub = _claim(subscriptionId, block.timestamp);

        if (_completedSub > 0) {
            uint256[] memory completedSub = new uint256[](1);
            completedSub[0] = _completedSub;
            _removeCompletedSub(completedSub);
        }
    }

    function autoClaim() external whenNotPaused onlyOperator {
        require(activeSubscriptions.length != 0, "no active subscriptions");
        uint256[] memory completedSubs = new uint256[](
            activeSubscriptions.length
        );
        uint256 completedSubCount = 0;
        for (uint256 index = 0; index < activeSubscriptions.length; index++) {
            Subscription storage subscription = _subscriptions[
                activeSubscriptions[index]
            ];

            if (
                block.timestamp >= subscription.nextClaimTime &&
                subscription.isActive
            ) {
                uint256 _completedSub = _claim(
                    activeSubscriptions[index],
                    block.timestamp
                );

                if (_completedSub > 0) {
                    completedSubs[completedSubCount] = _completedSub;
                    completedSubCount++;
                }
            }
        }
        _removeCompletedSub(completedSubs);
    }

    function emergencyWithdraw(address erc20Contract) external onlyOwner {
        require(
            erc20Contract.isContract() && erc20Contract != address(0),
            "invalid address of erc20Contract"
        );

        uint256 balanceOfThis = IERC20Upgradeable(erc20Contract).balanceOf(
            address(this)
        );

        if (balanceOfThis > 0) {
            IERC20Upgradeable(erc20Contract).safeTransfer(
                emergencyWallet,
                balanceOfThis
            );
        }
        emit EmergencyWithdraw(emergencyWallet, erc20Contract, balanceOfThis);
    }

    function getNumberOfActiveSubscriptions() public view returns (uint256) {
        return activeSubscriptions.length;
    }

    function isOperator(address operator) public view returns (bool) {
        return _operators[operator];
    }

    function isUpgradeWallet(address wallet) public view returns (bool) {
        return _upgrades[wallet];
    }

    function isWalletOnVesting(address wallet) public view returns (bool) {
        return _wallets[wallet];
    }

    function getAllActiveSubscriptions()
        public
        view
        returns (uint256[] memory)
    {
        return activeSubscriptions;
    }

    function getScheme(uint256 schemeId)
        public
        view
        returns (
            string memory name,
            uint256 vestingDuration,
            uint256 vestingFrequency,
            SchemeType schemeType,
            bool isExist
        )
    {
        Scheme memory scheme = _schemes[schemeId];
        name = scheme.schemeName;
        vestingDuration = scheme.vestingDuration / secondsOfDay;
        vestingFrequency = scheme.vestingFrequency / secondsOfDay;
        schemeType = scheme.schemeType;
        isExist = scheme.schemeExist;
    }

    function getSubscription(uint256 subscriptionId)
        public
        view
        returns (
            uint256 schemeId,
            uint256 startTimeVesting,
            uint256 cliffTime,
            uint256 endTimeVesting,
            address wallet,
            uint256 vestedAmount,
            uint256 depositAmount,
            uint256 nextTimeClaim,
            uint256 numberOfClaimed,
            bool isActive
        )
    {
        Subscription storage subScription = _subscriptions[subscriptionId];
        schemeId = subScription.schemeId;
        startTimeVesting = subScription.vestingStartTime;
        endTimeVesting = subScription.vestingEndTime;
        wallet = subScription.wallet;
        vestedAmount = subScription.vestedAmount;
        depositAmount = subScription.depositAmount;
        nextTimeClaim = subScription.nextClaimTime;
        numberOfClaimed = subScription.numberOfClaimed;
        isActive = subScription.isActive;
        cliffTime = subScription.cliffTime / secondsOfDay;
    }

    function getClaimableAmount(
        uint256 depositAmount,
        uint256 totalsecondsOfDays
    ) public pure returns (uint256 claimableAmount) {
        claimableAmount = _calculateClaimableAmount(
            depositAmount,
            totalsecondsOfDays
        );
    }

    function getAllSubscriptionsByWallet(address _wallet)
        public
        view
        returns (uint256[] memory)
    {
        return _totalSubscriptionsByWallet[_wallet];
    }

    function setOperator(address operator, bool isOperator_) public onlyOwner {
        _operators[operator] = isOperator_;
        emit OperatorAdded(operator, isOperator_);
    }

    function setEmergencyWallet(address _emergencyWallet) public onlyOwner {
        emergencyWallet = _emergencyWallet;
    }

    function setUpgradeWallet(address wallet, bool _isUpgradeWallet)
        public
        onlyOwner
    {
        _upgrades[wallet] = _isUpgradeWallet;
    }

    //! test
    function testABC() public view {}

    // calculate internal function
    function _removeCompletedSub(uint256[] memory completedSubs_) internal {
        if (completedSubs_.length > 0) {
            for (uint256 i = 0; i < completedSubs_.length; i++) {
                if (completedSubs_[i] > 0) {
                    uint256 positionToRemove = CommonLib._findIndexArray(
                        activeSubscriptions,
                        completedSubs_[i]
                    );
                    CommonLib._remove(activeSubscriptions, positionToRemove);
                }
            }
        }
    }

    function _calculateClaimableAmount(
        uint256 depositAmount,
        uint256 totalsecondsOfDays
    ) internal pure returns (uint256 claimableAmount) {
        claimableAmount = (depositAmount / totalsecondsOfDays);
    }

    function _calculateRemainingsecondsOfDays(uint256 endTime, uint256 nowTime)
        internal
        view
        returns (uint256 currentRemainingsecondsOfDays)
    {
        currentRemainingsecondsOfDays = (endTime - nowTime) / secondsOfDay + 1;
    }

    function _claim(uint256 subscriptionId, uint256 blockTime)
        internal
        returns (uint256 completedSub)
    {
        Subscription storage subscription = _subscriptions[subscriptionId];
        Scheme memory scheme = _schemes[subscription.schemeId];

        uint256 claimableAmount;

        if (blockTime >= subscription.vestingEndTime) {
            claimableAmount = subscription.depositAmount;
            subscription.vestedAmount += claimableAmount;
            subscription.depositAmount -= claimableAmount;
            subscription.numberOfClaimed += 1;
            subscription.nextClaimTime = 0;
            subscription.isActive = false;
            completedSub = subscriptionId;
        } else {
            uint256 currentRemainingsecondsOfDays = _calculateRemainingsecondsOfDays(
                    subscription.vestingEndTime,
                    block.timestamp
                );
            claimableAmount = _calculateClaimableAmount(
                subscription.depositAmount,
                currentRemainingsecondsOfDays
            );

            subscription.vestedAmount += claimableAmount;
            subscription.depositAmount -= claimableAmount;
            subscription.nextClaimTime =
                ((block.timestamp + scheme.vestingFrequency) / secondsOfDay) *
                secondsOfDay;

            if (subscription.depositAmount == 0) {
                subscription.nextClaimTime = 0;
                subscription.isActive = false;
                completedSub = subscriptionId;
            }
            subscription.numberOfClaimed += 1;
        }

        erc20Token.safeTransfer(subscription.wallet, claimableAmount);

        emit ClaimSucceeded(
            subscriptionId,
            subscription.wallet,
            claimableAmount,
            subscription.vestedAmount,
            subscription.depositAmount,
            block.timestamp,
            subscription.nextClaimTime
        );
    }

    function _onlyOperator() private view {
        require(_operators[_msgSender()], "Vesting: Sender is not operator");
    }

    function _onlyUpgradeWalletOrOwner() private view {
        require(
            _upgrades[_msgSender()] || owner() == _msgSender(),
            "Vesting : require owner or upgrade wallet"
        );
    }

    function _subscriptionExist(uint256 subscriptionId) private view {
        require(
            _subscriptions[subscriptionId].isActive,
            "Subscription does not exist"
        );
    }

    function _schemeExist(uint256 schemeId) private view {
        require(_schemes[schemeId].schemeExist, "Scheme does not exist");
    }

    function _authorizeUpgrade(address)
        internal
        override
        onlyUpgradeWalletOrOwner
    {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
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
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
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
library CountersUpgradeable {
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

/* SPDX-License-Identifier: MIT */
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

library CommonLib {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    // function _checkExistsInArray(address[] memory arr, address _address)
    //     internal
    //     pure
    //     returns (bool isExist, uint256 index)
    // {
    //     for (uint256 i = 0; i < arr.length; i++) {
    //         if (arr[i] == _address) {
    //             isExist = true;
    //             index = i;
    //             break;
    //         }
    //     }
    // }

    // function removeOutOfArray(address[] storage arr, uint256 index) internal {
    //     arr[index] = arr[arr.length - 1];
    //     arr.pop();
    // }

    function _findIndexArray(uint256[] memory arr, uint256 value)
        internal
        pure
        returns (uint256 index)
    {
        for (uint256 i = 0; i < arr.length; i++) {
            if (arr[i] == value) {
                index = i;
                break;
            }
        }
    }

    function _remove(uint256[] storage arr, uint256 index) internal {
        uint256 temp = arr[index];
        arr[index] = arr[arr.length - 1];
        arr[arr.length - 1] = temp;
        arr.pop();
    }

    function random(
        address addr,
        uint256 maxNumber,
        uint256 seedRandom
    ) internal view returns (uint256) {
        uint256 seed = uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp +
                        block.difficulty +
                        ((
                            uint256(keccak256(abi.encodePacked(block.coinbase)))
                        ) / (block.timestamp)) +
                        block.gaslimit +
                        ((uint256(keccak256(abi.encodePacked(addr)))) /
                            (block.timestamp)) +
                        block.number +
                        uint256(
                            keccak256(
                                abi.encodePacked(blockhash(block.number - 1))
                            )
                        ) +
                        gasleft() +
                        seedRandom
                )
            )
        );

        uint256 randomNumber = seed % maxNumber;
        randomNumber = randomNumber < maxNumber
            ? randomNumber + 1
            : randomNumber;

        return randomNumber;
    }

    function safeTransfer(
        address token,
        address from,
        address to,
        uint256 amount
    ) internal {
        if (token == address(0)) {
            require(from.balance >= amount, "Insufficient balance");

            if (from == address(this)) {
                (bool success, ) = to.call{value: amount}("");
                require(success, "Transfer failed");
            }
        } else {
            if (from == address(this)) {
                IERC20Upgradeable(token).safeTransfer(to, amount);
            } else {
                IERC20Upgradeable(token).safeTransferFrom(from, to, amount);
            }
        }
    }

    function calculateSystemFee(
        uint256 amount,
        uint256 feeRate,
        uint256 zoom
    ) internal pure returns (uint256 feeAmount) {
        feeAmount = (amount * feeRate) / (zoom * 100);
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
// OpenZeppelin Contracts v4.4.1 (utils/StorageSlot.sol)

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
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
        }
    }
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
}