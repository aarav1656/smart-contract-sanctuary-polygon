//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol';

import './interfaces/IStaking.sol';
import './interfaces/IStakingFactory.sol';
import './Errors.sol';

contract StakingFactory is Ownable, IStakingFactory {
    using SafeERC20 for IERC20;

    struct Pool {
        uint256 tvl;
        uint256 weight;
        bool isPool;
        bool ufoPool;
        uint256 allocPoint;
        uint256 lastRewardUfoTimeStamp;
        uint256 lastRewardPlasmaTimeStamp;
        uint256 accRewardUfoPerShare;
        uint256 accRewardPlasmaPerShare;
    }

    /**
     * @notice Total Weight of UFO tokens
     */
    uint256 public totalUfoWeight;

    /**
     * @notice Total Weight of LP tokens
     */
    uint256 public totalLpWeight;

    /**
     * @notice Total UFO tokens locked in all pools
     */
    uint256 public totalUfoLocked;

    /**
     * @notice Total Lp tokens locked in all pools
     */
    uint256 public totalLpLocked;

    /**
     * @notice Total allocation points.
     */
    uint256 public totalAllocPoint;

    /**
     * @notice ufo reward per second of ufo pools. so ufoRewardPerSecondOfUfoPool * one year =  _ufoRewardsForUfoPoolsPools
     */
    uint256 public ufoRewardPerSecondOfUfoPool;

    /**
     * @notice ufo reward per second of lp pool. so ufoRewardPerSecondOfLpPool * one year =  _ufoRewardsForLpPoolsPools
     */
    uint256 public ufoRewardPerSecondOfLpPool;

    /**
     * @notice plasma reward per second of ufo pools. so plasmaRewardPerSecondOfUfoPool * one year =  _plasmaRewardsForUfoPoolsPools
     */
    uint256 public plasmaRewardPerSecondOfUfoPool;

    /**
     * @notice plasma reward per second of lp pools. so plasmaRewardPerSecondOfLpPool * one year =  _plasmaRewardsForUfoPoolsPools
     */
    uint256 public plasmaRewardPerSecondOfLpPool;

    /**
     * @notice platform start time stamp;
     */
    uint256 public startTimeStamp;

    /**
     * @notice Weight is scaled by 1e12
     */
    uint256 public constant WEIGHT_SCALE = 1e18;

    /**
     * @notice event when pool is created
     * @param poolIndex Index of the pool
     * @param pool address of the pool
     */
    event CreatePool(uint256 indexed poolIndex, address indexed pool);

    /**
     * @notice event when whole pools are created
     *
     */
    event FinishCreatePool();

    /**
     * @notice event reward and plasma per second is changed
     *
     */
    event RewardAmountPerSecondIsChanged(uint256 perSecondValue, uint256 rewardType);

    /**
     * @notice event when tvl is updated
     * @param pool address of the pool
     */
    event UpdateTvl(address indexed pool, uint256 tvl);

    /**
     * @notice event when the pool's information is updated
     * @param pool address of the pool
     */
    event UpdatePool(address indexed pool);

    event UpdateAllocPoint(address indexed pool, uint256 allocPoint);

    /**
     * @notice pool params
     */
    mapping(address => Pool) public pools;

    /**
     * @notice pool number to pool address
     */
    mapping(uint256 => address) public poolNumberToPoolAddress;

    /**
     * @notice total number of pools
     */
    uint256 public constant totalPools = 54;

    /**
     * @notice total timestamps of one year
     */
    uint256 public totalBlocksPerYear = 364 * 24 * 60 * 60;

    /**
     * @notice address of the reward token
     */
    address public immutable rewardToken;

    /**
     * @notice Constructor
     * @param _admin Address of the admin
     * @param _ufoRewardsForUfoPoolsPools Ufo Rewards to be distributed for the locked pools
     * @param _ufoRewardsForLpPoolsPools Ufo Rewards to be distributed for the unlocked pools
     * @param _rewardToken Address of the reward token,
     */
    constructor(address _admin, uint256 _ufoRewardsForUfoPoolsPools, uint256 _ufoRewardsForLpPoolsPools, address _rewardToken ) {
        uint256 totalSecondsInYear = 364 * 24 * 60 * 60;
        Ownable.transferOwnership(_admin);
        ufoRewardPerSecondOfUfoPool = _ufoRewardsForUfoPoolsPools / totalSecondsInYear;
        ufoRewardPerSecondOfLpPool = _ufoRewardsForLpPoolsPools / totalSecondsInYear;

        rewardToken = _rewardToken;
        startTimeStamp = block.timestamp;
    }

    /**
     * @notice setup Factory
     * @param _beacon address of the beacon contract
     * @param _ufoToken Address of the ufo token
     * @param _lpToken Address of the lp token
     */

    function setup(address _beacon, address _ufoToken, address _lpToken, uint256 index ) external onlyOwner {
        uint256 totalSecondsInYear = 364 * 24 * 60 * 60;
        uint256 timeStampsPerWeek = totalSecondsInYear / 52; //timestamps per week (1 year is 52 weeks)
        uint256 totalWeight;

        totalWeight += 1e18 + (index * 19230769230769230);
        _createUfoAndLpPools(_beacon, index, index + 1, _lpToken, _ufoToken, owner(), timeStampsPerWeek * index + 1, 1e18 + (index * 19230769230769230));
        totalAllocPoint += totalWeight;
        if (index == 52) emit FinishCreatePool(); //last loop            
    }

    function _createUfoAndLpPools(address _beacon, uint256 ufoPoolIndex, uint256 lpPoolIndex, address _lpToken, address _ufoToken, address _admin, uint256 lockInBlocks, uint256 weight) internal {
        _createPool(_beacon, ufoPoolIndex, _ufoToken, lockInBlocks, _admin, weight);
        _createPool(_beacon, lpPoolIndex, _lpToken, lockInBlocks, _admin, weight);
    }

    /**
     * @notice internal function called in the constructor
     * @param poolIndex Index number of the pool
     * @param _stakingToken Address of the token to be staked
     * @param lockinBlocks Number of blocks the deposit is locked
     * @param _poolWeight Reward weight of the pool. Higher weight, higher rewards
     */
    function _createPool(address _beacon, uint256 poolIndex, address _stakingToken, uint256 lockinBlocks, address _admin, uint256 _poolWeight ) internal {
        require(_poolWeight != 0, Errors.SHOULD_BE_NON_ZERO);
        require(lockinBlocks != 0, Errors.SHOULD_BE_NON_ZERO);

        bytes memory empty;
        address _pool = address(new BeaconProxy(_beacon, empty));
        IStaking(_pool).initialize(_stakingToken, lockinBlocks, _admin, poolIndex == 0 || poolIndex == 1);

        pools[_pool] = Pool({tvl: 0, weight: _poolWeight, isPool: true, ufoPool: poolIndex % 2 == 0, allocPoint: 0, lastRewardUfoTimeStamp: 0, lastRewardPlasmaTimeStamp: 0, accRewardUfoPerShare: 0, accRewardPlasmaPerShare: 0});
        poolNumberToPoolAddress[poolIndex] = _pool;
        emit CreatePool(poolIndex, _pool);
    }

    /**
     * @notice Update the TVL. Only a pool can call
     * @param tvl New TVL of the pool
     */
    function updateTVL(uint256 tvl) external override onlyPool {
        Pool storage pool = pools[msg.sender];
        if (pool.ufoPool) {
            totalUfoWeight = totalUfoWeight - ((pool.tvl * (pool.weight)) / (WEIGHT_SCALE)) + ((tvl * (pool.weight)) / (WEIGHT_SCALE));
            totalUfoLocked = totalUfoLocked - pool.tvl + tvl;
        } else {
            totalLpWeight = totalLpWeight - ((pool.tvl * (pool.weight)) / (WEIGHT_SCALE)) + ((tvl * (pool.weight)) / (WEIGHT_SCALE));
            totalLpLocked = totalLpLocked - pool.tvl + tvl;
        }
        pool.tvl = tvl;
        emit UpdateTvl(msg.sender, tvl);
    }

    /**
     * @notice Update all pools
     */
    function updateAllPools() external override onlyPool {
        Pool storage pool = pools[msg.sender];
        for (uint256 i = 0; i < 54; i++) {
            if (pools[poolNumberToPoolAddress[i]].ufoPool == pool.ufoPool) {
                _updatePool(poolNumberToPoolAddress[i]);
            }
        }
    }

    function updateAllocPoint() external override onlyPool {
        Pool storage pool = pools[msg.sender];
        uint256 totalAmountWeight = pool.ufoPool ? totalUfoWeight : totalLpWeight;
        if (totalAmountWeight == 0) return;
        for (uint256 i = 0; i < 54; i++) {
            if (pools[poolNumberToPoolAddress[i]].ufoPool == pool.ufoPool) {
                Pool storage itemPool = pools[poolNumberToPoolAddress[i]];
                itemPool.allocPoint = ((itemPool.tvl * itemPool.weight) * totalAllocPoint) / WEIGHT_SCALE / totalAmountWeight;
                emit UpdateAllocPoint(poolNumberToPoolAddress[i], itemPool.allocPoint);
            }
        }
    }

    function _updatePool(address poolAddr) private {
        Pool storage pool = pools[poolAddr];
        uint256 currentTimestamp = block.timestamp;
        if (currentTimestamp <= pool.lastRewardUfoTimeStamp || currentTimestamp <= pool.lastRewardPlasmaTimeStamp) {
            return;
        }

        if (pool.tvl == 0) {
            pool.lastRewardUfoTimeStamp = currentTimestamp;
            pool.lastRewardPlasmaTimeStamp = currentTimestamp;
            emit UpdatePool(poolAddr);
            return;
        }

        uint256 multiplier = currentTimestamp - pool.lastRewardUfoTimeStamp;

        //for ufo reward update
        uint256 rewardPerSecond = pool.ufoPool ? ufoRewardPerSecondOfUfoPool : ufoRewardPerSecondOfLpPool;
        uint256 rewardAmount = ((multiplier * rewardPerSecond * pool.allocPoint) / totalAllocPoint);
        pool.accRewardUfoPerShare = pool.accRewardUfoPerShare + (rewardAmount * WEIGHT_SCALE) / pool.tvl;
        pool.lastRewardUfoTimeStamp = currentTimestamp;

        //for plasma reward update
        rewardPerSecond = pool.ufoPool ? plasmaRewardPerSecondOfUfoPool : plasmaRewardPerSecondOfLpPool;
        rewardAmount = ((multiplier * rewardPerSecond * pool.allocPoint) / totalAllocPoint);
        pool.accRewardPlasmaPerShare = pool.accRewardPlasmaPerShare + (rewardAmount * WEIGHT_SCALE) / pool.tvl;
        pool.lastRewardPlasmaTimeStamp = currentTimestamp;
        emit UpdatePool(poolAddr);
    }

    /**
     * @notice get individual pool's info
     */
    function getPoolInfo() external view override onlyPool returns (uint256 accRewardUfoPerShare, uint256 accRewardPlasmaPerShare, uint256 lastRewardUfoTimeStamp, uint256 lastRewardPlasmaTimeStamp, uint256 allocPoint, uint256 totalAllocPoints, uint256 rewardPerSecondUfo, uint256 rewardPerSecondPlasma ){
        Pool storage pool = pools[msg.sender];
        rewardPerSecondUfo = pool.ufoPool ? ufoRewardPerSecondOfUfoPool : ufoRewardPerSecondOfLpPool;
        rewardPerSecondPlasma = pool.ufoPool ? plasmaRewardPerSecondOfUfoPool : plasmaRewardPerSecondOfLpPool;
        return (pool.accRewardUfoPerShare, pool.accRewardPlasmaPerShare, pool.lastRewardUfoTimeStamp, pool.lastRewardPlasmaTimeStamp, pool.allocPoint, totalAllocPoint, rewardPerSecondUfo, rewardPerSecondPlasma );
    }

    /**
     * @notice Send ufo token rewards user. Only a pool can call
     * @param user Address of the user to send reward to
     * @param amount Amount of tokens to send
     */
    function flushReward(address user, uint256 amount) external override onlyPool {
        IERC20(rewardToken).safeTransfer(user, amount);
    }

    /**
     * @notice Change Ufo Rewards to be distributed for UFO pools
     * @param amount New Amount
     */
    function changeUfoRewardsPerSecondForUfoPools(uint256 amount) external onlyOwner {
        ufoRewardPerSecondOfUfoPool = amount;
        emit RewardAmountPerSecondIsChanged(ufoRewardPerSecondOfUfoPool, 1);
    }

    /**
     * @notice Change Ufo Rewards to be distributed for LP pools
     * @param amount New Amount
     */
    function changeUfoRewardsPerSecondForLpPools(uint256 amount) external onlyOwner {
        ufoRewardPerSecondOfLpPool = amount;
        emit RewardAmountPerSecondIsChanged(ufoRewardPerSecondOfLpPool, 2);
    }

    /**
     * @notice Withdraw UFO tokens available in case of any emergency
     * @param recipient Address to receive the emergency deposit
     */
    function emergencyWithdrawRewardBalance(address recipient) external onlyOwner {
        uint256 rewardBalance = IERC20(rewardToken).balanceOf(address(this));
        IERC20(rewardToken).safeTransfer(recipient, rewardBalance);
    }

    /**
     * @notice claim plasma from multiple pools
     * @param poolIndexes Pool Indexed to claim from
     * @param depositNumbers Deposit Numbers to claim
     */
    function claimPlasmaFromPools(uint256[] calldata poolIndexes, uint256[][] calldata depositNumbers, address plasmaRecipient) external {
        require(poolIndexes.length == depositNumbers.length, Errors.ARITY_MISMATCH);
        for (uint256 index = 0; index < poolIndexes.length; index++) {
            claimPlasmaFromPool(poolIndexes[index], depositNumbers[index], plasmaRecipient);
        }
    }

    /**
     * @notice Change the reward rate of UFO pools
     * @param newValue new plasma reward
     */
    function changeUfoPoolPlasmaRewardsPerSecond(uint256 newValue) external onlyOwner {
        plasmaRewardPerSecondOfUfoPool = newValue;
        emit RewardAmountPerSecondIsChanged(plasmaRewardPerSecondOfUfoPool, 3);
    }

    /**
     * @notice Change the reward rate of LP pools
     * @param newValue new plasma reward
     */
    function changeLpPoolPlasmaRewardsPerScond(uint256 newValue) external onlyOwner {
        plasmaRewardPerSecondOfLpPool = newValue;
        emit RewardAmountPerSecondIsChanged(plasmaRewardPerSecondOfLpPool, 4);
    }

    /**
     * @notice claim plasma from multiple pools
     * @param poolIndex Pool Index
     * @param depositNumbers Deposit Numbers to claim
     */
    function claimPlasmaFromPool(uint256 poolIndex, uint256[] calldata depositNumbers, address plasmaRecipient) public {
        address pool = poolNumberToPoolAddress[poolIndex];
        require(pool != address(0), Errors.SHOULD_BE_NON_ZERO);
        IStaking(pool).claimPlasmaFromFactory(depositNumbers, msg.sender, plasmaRecipient);
    }

    /**
     * @notice ensures that sender is a registered pool
     */
    modifier onlyPool() {
        require(pools[msg.sender].isPool, Errors.ONLY_POOLS_CAN_CALL);_;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
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
        IERC20 token,
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
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
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
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
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
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/BeaconProxy.sol)

pragma solidity ^0.8.0;

import "./IBeacon.sol";
import "../Proxy.sol";
import "../ERC1967/ERC1967Upgrade.sol";

/**
 * @dev This contract implements a proxy that gets the implementation address for each call from a {UpgradeableBeacon}.
 *
 * The beacon address is stored in storage slot `uint256(keccak256('eip1967.proxy.beacon')) - 1`, so that it doesn't
 * conflict with the storage layout of the implementation behind the proxy.
 *
 * _Available since v3.4._
 */
contract BeaconProxy is Proxy, ERC1967Upgrade {
    /**
     * @dev Initializes the proxy with `beacon`.
     *
     * If `data` is nonempty, it's used as data in a delegate call to the implementation returned by the beacon. This
     * will typically be an encoded function call, and allows initializating the storage of the proxy like a Solidity
     * constructor.
     *
     * Requirements:
     *
     * - `beacon` must be a contract with the interface {IBeacon}.
     */
    constructor(address beacon, bytes memory data) payable {
        assert(_BEACON_SLOT == bytes32(uint256(keccak256("eip1967.proxy.beacon")) - 1));
        _upgradeBeaconToAndCall(beacon, data, false);
    }

    /**
     * @dev Returns the current beacon address.
     */
    function _beacon() internal view virtual returns (address) {
        return _getBeacon();
    }

    /**
     * @dev Returns the current implementation address of the associated beacon.
     */
    function _implementation() internal view virtual override returns (address) {
        return IBeacon(_getBeacon()).implementation();
    }

    /**
     * @dev Changes the proxy to use a new beacon. Deprecated: see {_upgradeBeaconToAndCall}.
     *
     * If `data` is nonempty, it's used as data in a delegate call to the implementation returned by the beacon.
     *
     * Requirements:
     *
     * - `beacon` must be a contract.
     * - The implementation returned by `beacon` must be a contract.
     */
    function _setBeacon(address beacon, bytes memory data) internal virtual {
        _upgradeBeaconToAndCall(beacon, data, false);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IStaking {
    function initialize(
        address _stakingToken,
        uint256 _lockinBlocks,
        address _operator,
        bool _isFlexiPool
    ) external;

    function claimPlasmaFromFactory(
        uint256[] calldata depositNumbers,
        address depositor,
        address plasmaRecipient
    ) external;

    function deposit(uint256 amount) external;

    function depositTo(address _to, uint256 amount) external;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IStakingFactory {
    function updateTVL(uint256 tvl) external;

    function flushReward(address user, uint256 amount) external;

    function updateAllPools() external;

    function updateAllocPoint() external;

    function getPoolInfo()
        external
        view
        returns (
            uint256 accRewardUfoPerShare,
            uint256 accRewardPlasmaPerShare,
            uint256 lastRewardUfoTimeStamp,
            uint256 lastRewardPlasmaTimeStamp,
            uint256 allocPoint,
            uint256 totalAllocPoints,
            uint256 rewardPerSecondUfo,
            uint256 rewardPerSecondPlasma
        );
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

library Errors {
    string public constant ONLY_WHEN_DEPOSITED = '1';
    string public constant ONLY_DEPOSITOR = '2';
    string public constant VESTED_TIME_NOT_REACHED = '3';
    string public constant ONLY_AFTER_END_BLOCK = '4';
    string public constant ONLY_BEFORE_STAKING_ENDS = '5';
    string public constant ONLY_FACTORY_CAN_CALL = '6';
    string public constant DEFENCE = '7';
    string public constant ONLY_WHEN_WITHDRAWN = '8';
    string public constant SHOULD_BE_NON_ZERO = '9';
    string public constant SHOULD_BE_MORE_THAN_CLAIMED = 'A';
    string public constant ONLY_POOLS_CAN_CALL = 'B';
    string public constant LOCK_IN_BLOCK_LESS_THAN_MIN = 'C';
    string public constant EXCEEDS_MAX_ITERATION = 'D';
    string public constant SHOULD_BE_ZERO = 'E';
    string public constant ARITY_MISMATCH = 'F';
    string public constant APPROVAL_UNSUCCESSFUL = '10';
    string public constant MORE_THAN_FRACTION = '11';
    string public constant ONLY_FEATURE_OF_FLEXI_POOLS = '12';
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeacon {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/Proxy.sol)

pragma solidity ^0.8.0;

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /**
     * @dev This is a virtual function that should be overriden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback() external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive() external payable virtual {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overriden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeacon.sol";
import "../../interfaces/draft-IERC1822.sol";
import "../../utils/Address.sol";
import "../../utils/StorageSlot.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967Upgrade {
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
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
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
            Address.functionDelegateCall(newImplementation, data);
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
        if (StorageSlot.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822Proxiable(newImplementation).proxiableUUID() returns (bytes32 slot) {
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
        return StorageSlot.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlot.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
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
        return StorageSlot.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(Address.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            Address.isContract(IBeacon(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlot.getAddressSlot(_BEACON_SLOT).value = newBeacon;
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
            Address.functionDelegateCall(IBeacon(newBeacon).implementation(), data);
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
interface IERC1822Proxiable {
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
library StorageSlot {
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