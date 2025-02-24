// Copyright (C) 2020-2022 SubQuery Pte Ltd authors & contributors
// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.15;

pragma experimental ABIEncoderV2;

import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import '@openzeppelin/contracts-upgradeable/utils/introspection/ERC165CheckerUpgradeable.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

import './interfaces/IServiceAgreementRegistry.sol';
import './interfaces/ISettings.sol';
import './interfaces/IQueryRegistry.sol';
import './interfaces/IRewardsDistributer.sol';
import './interfaces/IStakingManager.sol';
import './interfaces/IPlanManager.sol';
import './Constants.sol';
import './utils/MathUtil.sol';

/**
 * @title Service Agreement Registry Contract
 * @notice ### Overview
 * This contract tracks all service Agreements for Indexers and Consumers.
 * For now, Consumer can accept the plan created by Indexer from Plan Manager to generate close service agreement.
 * Indexer can also accept Purchase Offer created by Consumer from purchase offer market to generate close service agreement.
 * All generated service agreement need to register in this contract by calling establishServiceAgreement(). After this all SQT Toaken
 * from agreements will be temporary hold in this contract, and approve reward distributor contract to take and distribute these Token.
 */
contract ServiceAgreementRegistry is Initializable, OwnableUpgradeable, IServiceAgreementRegistry, Constants {
    using MathUtil for uint256;

    /// @dev ### STATES
    /// @notice ISettings contract which stores SubQuery network contracts address
    ISettings public settings;

    /// @notice the id for next ServiceAgreement
    uint256 public nextServiceAgreementId;

    /// @notice Multipler used to calculate Indexer reward limit
    uint256 public threshold;

    /// @notice second in a day
    uint256 private constant SECONDS_IN_DAY = 86400;

    /// @notice ServiceAgreementId => AgreementInfo
    mapping(uint256 => ClosedServiceAgreementInfo) private closedServiceAgreements;

    /// @notice serviceAgreement address: Indexer address => index number => serviceAgreement address
    mapping(address => mapping(uint256 => uint256)) public closedServiceAgreementIds;

    /// @notice number of service agreements: Indexer address =>  number of service agreements
    mapping(address => uint256) public indexerCsaLength;

    /// @notice number of service agreements: Indexer address => DeploymentId => number of service agreements
    mapping(address => mapping(bytes32 => uint256)) public indexerDeploymentCsaLength;

    /// @notice address can establishServiceAgreement, for now only PurchaceOfferMarket and PlanManager addresses
    mapping(address => bool) public establisherWhitelist;

    /// @notice calculated sum daily reward: Indexer address => sumDailyReward
    mapping(address => uint256) public sumDailyReward;

    /// @notice users authorised by consumer that can request access token from indexer, for closed agreements only.
    /// consumer address => user address => bool
    /// We are using the statu `consumerAuthAllows` offchain.
    mapping(address => mapping(address => bool)) public consumerAuthAllows;

    // -- Events --

    /**
     * @dev Emitted when closed service agreement established
     */
    event ClosedAgreementCreated(
        address indexed consumer,
        address indexed indexer,
        bytes32 indexed deploymentId,
        uint256 serviceAgreementId
    );
    /**
     * @dev Emitted when expired closed service agreement removed.
     */
    event ClosedAgreementRemoved(
        address indexed consumer,
        address indexed indexer,
        bytes32 indexed deploymentId,
        uint256 serviceAgreementId
    );
    /**
     * @dev Emitted when consumer add new user
     */
    event UserAdded(address indexed consumer, address user);
    /**
     * @dev Emitted when consumer remove user
     */
    event UserRemoved(address indexed consumer, address user);

    /**
     * @dev Initialize this contract. Load establisherWhitelist.
     */
    function initialize(ISettings _settings, address[] calldata _whitelist, uint256 _threshold) external initializer {
        __Ownable_init();

        settings = _settings;

        threshold = _threshold;

        nextServiceAgreementId = 1;

        for (uint256 i; i < _whitelist.length; i++) {
            establisherWhitelist[_whitelist[i]] = true;
        }
    }

    function setSettings(ISettings _settings) external onlyOwner {
        settings = _settings;
    }

    /**
     * @dev We adjust the ratio of Indexer‘s totalStakedAmount and sumDailyRewards by
     * setting the value of threshold.
     * A smaller threshold value means that the Indexer can get higher sumDailyRewards with
     * a smaller totalStakedAmount，vice versa.
     * If the threshold is less than PER_MILL, we will not limit the indexer's sumDailyRewards.
     */
    function setThreshold(uint256 _threshold) external onlyOwner {
        threshold = _threshold >= PER_MILL ? _threshold : 0;
    }

    /**
     * @dev Consumer add users can request access token from indexer.
     * We are using the statu `consumerAuthAllows` offchain.
     */
    function addUser(address consumer, address user) external {
        require(msg.sender == consumer, 'SA002');
        consumerAuthAllows[consumer][user] = true;
        emit UserAdded(consumer, user);
    }

    /**
     * @dev Consumer remove users can request access token from indexer.
     */
    function removeUser(address consumer, address user) external {
        require(msg.sender == consumer, 'SA003');
        delete consumerAuthAllows[consumer][user];
        emit UserRemoved(consumer, user);
    }

    function addEstablisher(address establisher) external onlyOwner {
        establisherWhitelist[establisher] = true;
    }

    function removeEstablisher(address establisher) external onlyOwner {
        establisherWhitelist[establisher] = false;
    }

    function periodInDay(uint256 period) private pure returns (uint256) {
        return period > SECONDS_IN_DAY ? period / SECONDS_IN_DAY : 1;
    }

    function createClosedServiceAgreement(ClosedServiceAgreementInfo memory agreement) external returns (uint256) {
        if (msg.sender != address(this)) {
            require(establisherWhitelist[msg.sender], 'SA004');
        }
        closedServiceAgreements[nextServiceAgreementId] = agreement;
        uint256 agreementId = nextServiceAgreementId;
        nextServiceAgreementId += 1;
        return agreementId;
    }

    /**
     * @dev Establish the generated service agreement.
     * For now only establish the close service agreement generated from PlanManager and PurchsaseOfferMarket.
     * This function is called by PlanManager or PurchsaseOfferMarket when close service agreement generated,
     * it temporary hold the SQT Token from these agreements, approve and nodify reward distributor contract to take and
     * distribute these Token.
     * All agreements register to this contract through this method.
     * When new agreement come we need to track the sumDailyReward of Indexer. In our design there is an upper limit
     * on the rewards indexer can earn every day, and the limit will increase with the increase of the total staked
     * amount of that indexer. This design can ensure our Customer to obtain high quality of service from Indexer，
     * at the same time, it also encourages Indexer to provide better more stable services.
     *
     */
    function establishServiceAgreement(uint256 agreementId) external {
        if (msg.sender != address(this)) {
            require(establisherWhitelist[msg.sender], 'SA004');
        }

        //for now only support closed service agreement
        ClosedServiceAgreementInfo memory agreement = closedServiceAgreements[agreementId];
        require(agreement.consumer != address(0), 'SA001');

        address indexer = agreement.indexer;
        address consumer = agreement.consumer;
        bytes32 deploymentId = agreement.deploymentId;

        require(
            IQueryRegistry(settings.getQueryRegistry()).isIndexingAvailable(deploymentId, indexer),
            'SA005'
        );

        IStakingManager stakingManager = IStakingManager(settings.getStakingManager());
        uint256 totalStake = stakingManager.getTotalStakingAmount(indexer);

        uint256 lockedAmount = agreement.lockedAmount;
        uint256 period = periodInDay(agreement.period);
        sumDailyReward[indexer] += lockedAmount / period;
        require(
            totalStake >= MathUtil.mulDiv(sumDailyReward[indexer], threshold, PER_MILL),
            'SA006'
        );

        closedServiceAgreementIds[indexer][indexerCsaLength[indexer]] = agreementId;
        indexerCsaLength[indexer] += 1;
        indexerDeploymentCsaLength[indexer][deploymentId] += 1;

        // approve token to reward distributor contract
        address SQToken = settings.getSQToken();
        IERC20(SQToken).approve(settings.getRewardsDistributer(), lockedAmount);

        // increase agreement rewards
        IRewardsDistributer rewardsDistributer = IRewardsDistributer(settings.getRewardsDistributer());
        rewardsDistributer.increaseAgreementRewards(agreementId);

        emit ClosedAgreementCreated(consumer, indexer, deploymentId, agreementId);
    }

    /**
     * @dev A function allow Consumer call to renew its unexpired closed service agreement.
     * We only allow the the agreement generated from PlanManager renewable which is created
     * by Indexer and accepted by Consumer. We use the status planId in agreement to determine
     * whether the agreement is renewable, since only the agreement generated from PlanManager
     * come with the PlanId.
     * Indexer can be prevente the agreement rennew by inactive the plan which bound to it.
     * Consumer must renew befor the agreement expired.
     */
    function renewAgreement(uint256 agreementId) external {
        //for now only support closed service agreement
        ClosedServiceAgreementInfo memory agreement = closedServiceAgreements[agreementId];
        require(msg.sender == agreement.consumer, 'SA007');
        require(agreement.startDate < block.timestamp, 'SA008');

        IPlanManager planManager = IPlanManager(settings.getPlanManager());
        Plan memory plan = planManager.getPlan(agreement.planId);
        require(plan.active, 'PM009');
        require((agreement.startDate + agreement.period) > block.timestamp, 'SA009');

        // create closed service agreement
        ClosedServiceAgreementInfo memory newAgreement = ClosedServiceAgreementInfo(
            agreement.consumer,
            agreement.indexer,
            agreement.deploymentId,
            agreement.lockedAmount,
            agreement.startDate + agreement.period,
            agreement.period,
            agreement.planId,
            agreement.planTemplateId
        );
        uint256 newAgreementId = this.createClosedServiceAgreement(newAgreement);

        // deposit SQToken into service agreement registry contract
        IERC20(settings.getSQToken()).transferFrom(msg.sender, address(this), agreement.lockedAmount);
        this.establishServiceAgreement(newAgreementId);
    }

    function clearEndedAgreement(address indexer, uint256 id) public {
        require(id < indexerCsaLength[indexer], 'SA001');

        uint256 agreementId = closedServiceAgreementIds[indexer][id];
        ClosedServiceAgreementInfo memory agreement = closedServiceAgreements[agreementId];
        require(agreement.consumer != address(0), 'SA001');
        require(block.timestamp > (agreement.startDate + agreement.period), 'SA010');

        uint256 lockedAmount = agreement.lockedAmount;
        uint256 period = periodInDay(agreement.period);
        sumDailyReward[indexer] = MathUtil.sub(sumDailyReward[indexer], (lockedAmount / period));

        closedServiceAgreementIds[indexer][id] = closedServiceAgreementIds[indexer][indexerCsaLength[indexer] - 1];
        delete closedServiceAgreementIds[indexer][indexerCsaLength[indexer] - 1];
        indexerCsaLength[indexer] -= 1;
        indexerDeploymentCsaLength[indexer][agreement.deploymentId] -= 1;

        emit ClosedAgreementRemoved(agreement.consumer, agreement.indexer, agreement.deploymentId, agreementId);
    }

    function clearAllEndedAgreements(address indexer) public {
        uint256 count = 0;
        for (uint256 i = indexerCsaLength[indexer]; i >= 1; i--) {
            uint256 agreementId = closedServiceAgreementIds[indexer][i - 1];
            ClosedServiceAgreementInfo memory agreement = closedServiceAgreements[agreementId];
            if (block.timestamp > (agreement.startDate + agreement.period)) {
                clearEndedAgreement(indexer, i - 1);
                count++;
                if (count >= 10) {
                    break;
                }
            }
        }
    }

    function closedServiceAgreementExpired(uint256 agreementId) public view returns (bool) {
        ClosedServiceAgreementInfo memory agreement = closedServiceAgreements[agreementId];
        return block.timestamp > (agreement.startDate + agreement.period);
    }

    function hasOngoingClosedServiceAgreement(address indexer, bytes32 deploymentId) external view returns (bool) {
        return indexerDeploymentCsaLength[indexer][deploymentId] > 0;
    }

    function getClosedServiceAgreement(uint256 agreementId) external view returns (ClosedServiceAgreementInfo memory) {
        return closedServiceAgreements[agreementId];
    }
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165Checker.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";

/**
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
library ERC165CheckerUpgradeable {
    // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

    /**
     * @dev Returns true if `account` supports the {IERC165} interface,
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return
            _supportsERC165Interface(account, type(IERC165Upgradeable).interfaceId) &&
            !_supportsERC165Interface(account, _INTERFACE_ID_INVALID);
    }

    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for {IERC165} itself is queried automatically.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return supportsERC165(account) && _supportsERC165Interface(account, interfaceId);
    }

    /**
     * @dev Returns a boolean array where each value corresponds to the
     * interfaces passed in and whether they're supported or not. This allows
     * you to batch check interfaces for a contract where your expectation
     * is that some interfaces may not be supported.
     *
     * See {IERC165-supportsInterface}.
     *
     * _Available since v3.4._
     */
    function getSupportedInterfaces(address account, bytes4[] memory interfaceIds)
        internal
        view
        returns (bool[] memory)
    {
        // an array of booleans corresponding to interfaceIds and whether they're supported or not
        bool[] memory interfaceIdsSupported = new bool[](interfaceIds.length);

        // query support of ERC165 itself
        if (supportsERC165(account)) {
            // query support of each interface in interfaceIds
            for (uint256 i = 0; i < interfaceIds.length; i++) {
                interfaceIdsSupported[i] = _supportsERC165Interface(account, interfaceIds[i]);
            }
        }

        return interfaceIdsSupported;
    }

    /**
     * @dev Returns true if `account` supports all the interfaces defined in
     * `interfaceIds`. Support for {IERC165} itself is queried automatically.
     *
     * Batch-querying can lead to gas savings by skipping repeated checks for
     * {IERC165} support.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsAllInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool) {
        // query support of ERC165 itself
        if (!supportsERC165(account)) {
            return false;
        }

        // query support of each interface in _interfaceIds
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!_supportsERC165Interface(account, interfaceIds[i])) {
                return false;
            }
        }

        // all interfaces supported
        return true;
    }

    /**
     * @notice Query if a contract implements an interface, does not check ERC165 support
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return true if the contract at account indicates support of the interface with
     * identifier interfaceId, false otherwise
     * @dev Assumes that account contains a contract that supports ERC165, otherwise
     * the behavior of this method is undefined. This precondition can be checked
     * with {supportsERC165}.
     * Interface identification is specified in ERC-165.
     */
    function _supportsERC165Interface(address account, bytes4 interfaceId) private view returns (bool) {
        bytes memory encodedParams = abi.encodeWithSelector(IERC165Upgradeable.supportsInterface.selector, interfaceId);
        (bool success, bytes memory result) = account.staticcall{gas: 30000}(encodedParams);
        if (result.length < 32) return false;
        return success && abi.decode(result, (bool));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

// Copyright (C) 2020-2022 SubQuery Pte Ltd authors & contributors
// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.15;

// -- Data --

/**
 * @dev closed service agreement information
 */
struct ClosedServiceAgreementInfo {
    address consumer;
    address indexer;
    bytes32 deploymentId;
    uint256 lockedAmount;
    uint256 startDate;
    uint256 period;
    uint256 planId;
    uint256 planTemplateId;
}

interface IServiceAgreementRegistry {
    function establishServiceAgreement(uint256 agreementId) external;

    function hasOngoingClosedServiceAgreement(address indexer, bytes32 deploymentId) external view returns (bool);

    function addUser(address consumer, address user) external;

    function removeUser(address consumer, address user) external;

    function getClosedServiceAgreement(uint256 agreementId) external view returns (ClosedServiceAgreementInfo memory);

    function nextServiceAgreementId() external view returns (uint256);

    function createClosedServiceAgreement(ClosedServiceAgreementInfo memory agreement) external returns (uint256);
}

// Copyright (C) 2020-2022 SubQuery Pte Ltd authors & contributors
// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.15;

interface ISettings {
    function setProjectAddresses(
        address _indexerRegistry,
        address _queryRegistry,
        address _eraManager,
        address _planManager,
        address _serviceAgreementRegistry,
        address _disputeManager,
        address _stateChannel
    ) external;

    function setTokenAddresses(
        address _sqToken,
        address _staking,
        address _stakingManager,
        address _rewardsDistributer,
        address _rewardsPool,
        address _rewardsStaking,
        address _rewardsHelper,
        address _inflationController,
        address _vesting,
        address _permissionedExchange
    ) external;

    function setSQToken(address _sqToken) external;

    function getSQToken() external view returns (address);

    function setStaking(address _staking) external;

    function getStaking() external view returns (address);

    function setStakingManager(address _stakingManager) external;

    function getStakingManager() external view returns (address);

    function setIndexerRegistry(address _indexerRegistry) external;

    function getIndexerRegistry() external view returns (address);

    function setQueryRegistry(address _queryRegistry) external;

    function getQueryRegistry() external view returns (address);

    function setEraManager(address _eraManager) external;

    function getEraManager() external view returns (address);

    function setPlanManager(address _planManager) external;

    function getPlanManager() external view returns (address);

    function setServiceAgreementRegistry(address _serviceAgreementRegistry) external;

    function getServiceAgreementRegistry() external view returns (address);

    function setRewardsDistributer(address _rewardsDistributer) external;

    function getRewardsDistributer() external view returns (address);

    function setRewardsPool(address _rewardsPool) external;

    function getRewardsPool() external view returns (address);

    function setRewardsStaking(address _rewardsStaking) external;

    function getRewardsStaking() external view returns (address);

    function setRewardsHelper(address _rewardsHelper) external;

    function getRewardsHelper() external view returns (address);

    function setInflationController(address _inflationController) external;

    function getInflationController() external view returns (address);

    function setVesting(address _vesting) external;

    function getVesting() external view returns (address);

    function setPermissionedExchange(address _permissionedExchange) external;

    function getPermissionedExchange() external view returns (address);

    function setDisputeManager(address _disputeManager) external;

    function getDisputeManager() external view returns (address);

    function setStateChannel(address _stateChannel) external;

    function getStateChannel() external view returns (address);
}

// Copyright (C) 2020-2022 SubQuery Pte Ltd authors & contributors
// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.15;

enum IndexingServiceStatus {
    NOTINDEXING,
    INDEXING,
    READY
}

interface IQueryRegistry {

    function numberOfIndexingDeployments(address _address) external view returns (uint256);

    function isIndexingAvailable(bytes32 deploymentId, address indexer) external view returns (bool);

    function createQueryProject(
        bytes32 metadata,
        bytes32 version,
        bytes32 deploymentId
    ) external;

    function updateQueryProjectMetadata(uint256 queryId, bytes32 metadata) external;

    function updateDeployment(
        uint256 queryId,
        bytes32 deploymentId,
        bytes32 version
    ) external;

    function startIndexing(bytes32 deploymentId) external;

    function updateIndexingStatusToReady(bytes32 deploymentId) external;

    function reportIndexingStatus(
        address indexer,
        bytes32 deploymentId,
        uint256 _blockheight,
        bytes32 _mmrRoot,
        uint256 _timestamp
    ) external;

    function stopIndexing(bytes32 deploymentId) external;

    function isOffline(bytes32 deploymentId, address indexer) external view returns (bool);
}

// Copyright (C) 2020-2022 SubQuery Pte Ltd authors & contributors
// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.15;

import './IServiceAgreementRegistry.sol';

// Reward info for query.
struct IndexerRewardInfo {
    uint256 accSQTPerStake;
    uint256 lastClaimEra;
    uint256 eraReward;
}

interface IRewardsDistributer {
    function setLastClaimEra(address indexer, uint256 era) external;

    function setRewardDebt(address indexer, address delegator, uint256 amount) external;

    function resetEraReward(address indexer, uint256 era) external;

    function collectAndDistributeRewards(address indexer) external;

    function collectAndDistributeEraRewards(uint256 era, address indexer) external returns (uint256);

    function increaseAgreementRewards(uint256 agreementId) external;

    function addInstantRewards(address indexer, address sender, uint256 amount, uint256 era) external;

    function claim(address indexer) external;

    function claimFrom(address indexer, address user) external returns (uint256);

    function userRewards(address indexer, address user) external view returns (uint256);

    function getRewardInfo(address indexer) external view returns (IndexerRewardInfo memory);
}

// Copyright (C) 2020-2022 SubQuery Pte Ltd authors & contributors
// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.15;

interface IStakingManager {
    function stake(address _indexer, uint256 _amount) external;

    function unstake(address _indexer, uint256 _amount) external;

    function slashIndexer(address _indexer, uint256 _amount) external;

    function getTotalStakingAmount(address _indexer) external view returns (uint256);

    function getAfterDelegationAmount(address _delegator, address _indexer) external view returns (uint256);
}

// Copyright (C) 2020-2022 SubQuery Pte Ltd authors & contributors
// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.15;

/**
 * @notice Plan is created by an Indexer,
 * a service agreement will be created once a consumer accept a plan.
 */
struct Plan {
    address indexer;
    uint256 price;
    uint256 templateId;
    bytes32 deploymentId;
    bool active;
}

/**
 * @notice PlanTemplate is created and maintained by the owner,
 * the owner provides a set of PlanTemplates for indexers to choose.
 * For Indexer and Consumer to create the Plan and Purchase Offer.
 */
struct PlanTemplate {
    uint256 period;
    uint256 dailyReqCap;
    uint256 rateLimit;
    bytes32 metadata;
    bool active;
}

interface IPlanManager {
    function getPlan(uint256 planId) external view returns (Plan memory);

    function getPlanTemplate(uint256 templateId) external view returns (PlanTemplate memory);
}

// Copyright (C) 2020-2022 SubQuery Pte Ltd authors & contributors
// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.15;

contract Constants {
    uint256 public constant PER_MILL = 1e6;
    uint256 public constant PER_BILL = 1e9;
    uint256 public constant PER_TRILL = 1e12;
    address public constant ZERO_ADDRESS = address(0);
}

// Copyright (C) 2020-2022 SubQuery Pte Ltd authors & contributors
// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.15;

library MathUtil {
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256) {
        return x > y ? y : x;
    }

    function divUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return (x - 1) / y + 1;
    }

    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 z
    ) internal pure returns (uint256) {
        return (x * y) / z;
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256) {
        if (x < y) {
            return 0;
        }
        return x - y;
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