// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "../../lib/Math.sol";
import "../../interface/IVeDist.sol";
import "../../interface/IVe.sol";
import "../../interface/IVoter.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract VeDist is IVeDist, Initializable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    event CheckpointToken(uint time, uint tokens);

    event Claimed(uint tokenId, uint amount, uint claimEpoch, uint maxEpoch);

    struct ClaimCalculationResult {
        uint toDistribute;
        uint userEpoch;
        uint weekCursor;
        uint maxUserEpoch;
        bool success;
    }

    struct EmissionsCalculationResult {
        uint cashToDistribute;
        uint tokenToDistribute;
        uint userEpoch;
        uint weekCursor;
        uint maxUserEpoch;
        bool success;
    }

    uint constant WEEK = 7 * 86400;

    uint public startTime;
    uint public timeCursor;
    uint public minLockDurationForReward;
    mapping(uint => uint) public timeCursorOf;
    mapping(uint => uint) public emissionTimeCursorOf;
    mapping(uint => uint) public userEpochOf;
    mapping(uint => uint) public emissionUserEpochOf;

    uint public lastTokenTime;
    uint[1000000000000000] public tokensPerWeek;

    address public votingEscrow;
    address public token;
    address public voter;
    uint public tokenLastBalance;

    uint[1000000000000000] public veSupply;

    address public depositor;
    address public owner;

    mapping(address => uint[1000000000000000]) public tokenEmissionPerWeek;

    address cash;
    uint lastEmissionsTime;
    uint cashLastBalance;

    // constructor(address _votingEscrow, address token_) {
    // uint _t = (block.timestamp / WEEK) * WEEK;
    // startTime = _t;
    // lastTokenTime = _t;
    // timeCursor = _t;
    // address _token = token_;
    // token = _token;
    // votingEscrow = _votingEscrow;
    // depositor = msg.sender;
    // IERC20Upgradeable(_token).safeIncreaseAllowance(_votingEscrow, type(uint).max);
    // }

    function initialize(address _votingEscrow, address token_, address _cash) public initializer {
        uint _t = (block.timestamp / WEEK) * WEEK;
        startTime = _t;
        lastTokenTime = _t;
        lastEmissionsTime = _t;
        timeCursor = _t;
        address _token = token_;
        token = _token;
        cash = _cash;
        votingEscrow = _votingEscrow;
        depositor = msg.sender;
        owner = msg.sender;
        minLockDurationForReward = 6 * 30 * 86400;
        IERC20Upgradeable(_token).safeIncreaseAllowance(_votingEscrow, type(uint).max);
    }

    function setVoter(address _voter) external {
        require(msg.sender == owner, "!owner");
        voter = _voter;
    }

    function timestamp() external view returns (uint) {
        return (block.timestamp / WEEK) * WEEK;
    }

    function setMinLockDurationForReward(uint _minLockDurationForReward) external {
        require(msg.sender == owner);
        minLockDurationForReward = _minLockDurationForReward;
    }

    function _checkpointEmissions() internal {
        IVoter(voter).getVeShare();
        uint cashBalance = IERC20Upgradeable(cash).balanceOf(address(this));
        uint tokenBalance = IERC20Upgradeable(token).balanceOf(address(this));
        uint tokenToDistribute = tokenBalance - tokenLastBalance;
        uint cashToDistribute = cashBalance - cashLastBalance;
        tokenLastBalance = tokenBalance;
        cashLastBalance = cashBalance;

        uint t = lastEmissionsTime;
        uint sinceLast = block.timestamp - t;
        lastEmissionsTime = block.timestamp;
        uint thisWeek = (t / WEEK) * WEEK;
        uint nextWeek = 0;

        for (uint i = 0; i < 20; i++) {
            nextWeek = thisWeek + WEEK;
            if (block.timestamp < nextWeek) {
                tokenEmissionPerWeek[token][thisWeek] += _adjustToDistribute(tokenToDistribute, block.timestamp, t, sinceLast);
                tokenEmissionPerWeek[cash][thisWeek] += _adjustToDistribute(cashToDistribute, block.timestamp, t, sinceLast);
                break;
            } else {
                tokenEmissionPerWeek[token][thisWeek] += _adjustToDistribute(tokenToDistribute, nextWeek, t, sinceLast);
                tokenEmissionPerWeek[cash][thisWeek] += _adjustToDistribute(cashToDistribute, nextWeek, t, sinceLast);
            }
            t = nextWeek;
            thisWeek = nextWeek;
        }
    }

    function _checkpointToken() internal {
        uint tokenBalance = IERC20Upgradeable(token).balanceOf(address(this));
        uint toDistribute = tokenBalance - tokenLastBalance;
        tokenLastBalance = tokenBalance;

        uint t = lastTokenTime;
        uint sinceLast = block.timestamp - t;
        lastTokenTime = block.timestamp;
        uint thisWeek = (t / WEEK) * WEEK;
        uint nextWeek = 0;

        for (uint i = 0; i < 20; i++) {
            nextWeek = thisWeek + WEEK;
            if (block.timestamp < nextWeek) {
                tokensPerWeek[thisWeek] += _adjustToDistribute(toDistribute, block.timestamp, t, sinceLast);
                break;
            } else {
                tokensPerWeek[thisWeek] += _adjustToDistribute(toDistribute, nextWeek, t, sinceLast);
            }
            t = nextWeek;
            thisWeek = nextWeek;
        }
        emit CheckpointToken(block.timestamp, toDistribute);
    }

    /// @dev For testing purposes.
    function adjustToDistribute(uint toDistribute, uint t0, uint t1, uint sinceLastCall) external pure returns (uint) {
        return _adjustToDistribute(toDistribute, t0, t1, sinceLastCall);
    }

    function _adjustToDistribute(uint toDistribute, uint t0, uint t1, uint sinceLast) internal pure returns (uint) {
        if (t0 <= t1 || t0 - t1 == 0 || sinceLast == 0) {
            return toDistribute;
        }
        return (toDistribute * (t0 - t1)) / sinceLast;
    }

    function checkpointToken() external override {
        require(msg.sender == depositor, "!depositor");
        _checkpointToken();
    }

    function checkpointEmissions() external override {
        require(msg.sender == depositor, "!depositor");
        _checkpointEmissions();
    }

    function _findTimestampEpoch(address ve, uint _timestamp) internal view returns (uint) {
        uint _min = 0;
        uint _max = IVe(ve).epoch();
        for (uint i = 0; i < 128; i++) {
            if (_min >= _max) break;
            uint _mid = (_min + _max + 2) / 2;
            IVe.Point memory pt = IVe(ve).pointHistory(_mid);
            if (pt.ts <= _timestamp) {
                _min = _mid;
            } else {
                _max = _mid - 1;
            }
        }
        return _min;
    }

    function findTimestampUserEpoch(address ve, uint tokenId, uint _timestamp, uint maxUserEpoch) external view returns (uint) {
        return _findTimestampUserEpoch(ve, tokenId, _timestamp, maxUserEpoch);
    }

    function _findTimestampUserEpoch(address ve, uint tokenId, uint _timestamp, uint maxUserEpoch) internal view returns (uint) {
        uint _min = 0;
        uint _max = maxUserEpoch;
        for (uint i = 0; i < 128; i++) {
            if (_min >= _max) break;
            uint _mid = (_min + _max + 2) / 2;
            IVe.Point memory pt = IVe(ve).userPointHistory(tokenId, _mid);
            if (pt.ts <= _timestamp) {
                _min = _mid;
            } else {
                _max = _mid - 1;
            }
        }
        return _min;
    }

    function veForAt(uint _tokenId, uint _timestamp) external view returns (uint) {
        address ve = votingEscrow;
        uint maxUserEpoch = IVe(ve).userPointEpoch(_tokenId);
        uint epoch = _findTimestampUserEpoch(ve, _tokenId, _timestamp, maxUserEpoch);
        IVe.Point memory pt = IVe(ve).userPointHistory(_tokenId, epoch);
        return uint(int256(Math.positiveInt128(pt.bias - pt.slope * (int128(int256(_timestamp - pt.ts))))));
    }

    function _checkpointTotalSupply() internal {
        address ve = votingEscrow;
        uint t = timeCursor;
        uint roundedTimestamp = (block.timestamp / WEEK) * WEEK;
        IVe(ve).checkpoint();

        // assume will be called more frequently than 20 weeks
        for (uint i = 0; i < 20; i++) {
            if (t > roundedTimestamp) {
                break;
            } else {
                uint epoch = _findTimestampEpoch(ve, t);
                IVe.Point memory pt = IVe(ve).pointHistory(epoch);
                veSupply[t] = _adjustVeSupply(t, pt.ts, pt.bias, pt.slope);
            }
            t += WEEK;
        }
        timeCursor = t;
    }

    function adjustVeSupply(uint t, uint ptTs, int128 ptBias, int128 ptSlope) external pure returns (uint) {
        return _adjustVeSupply(t, ptTs, ptBias, ptSlope);
    }

    function _adjustVeSupply(uint t, uint ptTs, int128 ptBias, int128 ptSlope) internal pure returns (uint) {
        if (t < ptTs) {
            return 0;
        }
        int128 dt = int128(int256(t - ptTs));
        if (ptBias < ptSlope * dt) {
            return 0;
        }
        return uint(int256(Math.positiveInt128(ptBias - ptSlope * dt)));
    }

    function checkpointTotalSupply() external override {
        _checkpointTotalSupply();
    }

    function _claim(uint _tokenId, address ve, uint _lastTokenTime) internal returns (uint) {
        ClaimCalculationResult memory result = _calculateClaim(_tokenId, ve, _lastTokenTime);
        if (result.success) {
            userEpochOf[_tokenId] = result.userEpoch;
            timeCursorOf[_tokenId] = result.weekCursor;
            emit Claimed(_tokenId, result.toDistribute, result.userEpoch, result.maxUserEpoch);
        }
        return result.toDistribute;
    }

    function _claimEmissions(uint _tokenId, address ve, uint _lastEmissionsTime) internal returns (uint, uint) {
        EmissionsCalculationResult memory result = _calculateEmissionsClaim(_tokenId, ve, _lastEmissionsTime);
        if (result.success) {
            emissionUserEpochOf[_tokenId] = result.userEpoch;
            emissionTimeCursorOf[_tokenId] = result.weekCursor;
            // emit Claimed(_tokenId, result.toDistribute, result.userEpoch, result.maxUserEpoch);
        }
        return (result.cashToDistribute, result.tokenToDistribute);
    }

    function _calculateClaim(uint _tokenId, address ve, uint _lastTokenTime) internal view returns (ClaimCalculationResult memory) {
        uint userEpoch;
        uint toDistribute;
        uint maxUserEpoch = IVe(ve).userPointEpoch(_tokenId);
        uint lockEndTime = IVe(ve).lockedEnd(_tokenId);
        uint _startTime = startTime;

        if (maxUserEpoch == 0) {
            return ClaimCalculationResult(0, 0, 0, 0, false);
        }

        uint weekCursor = timeCursorOf[_tokenId];

        if (weekCursor == 0) {
            userEpoch = _findTimestampUserEpoch(ve, _tokenId, _startTime, maxUserEpoch);
        } else {
            userEpoch = userEpochOf[_tokenId];
        }

        if (userEpoch == 0) userEpoch = 1;

        IVe.Point memory userPoint = IVe(ve).userPointHistory(_tokenId, userEpoch);
        if (weekCursor == 0) {
            weekCursor = ((userPoint.ts + WEEK - 1) / WEEK) * WEEK;
        }
        if (weekCursor >= lastTokenTime) {
            return ClaimCalculationResult(0, 0, 0, 0, false);
        }
        if (weekCursor < _startTime) {
            weekCursor = _startTime;
        }

        IVe.Point memory oldUserPoint;
        {
            for (uint i = 0; i < 50; i++) {
                if (weekCursor >= _lastTokenTime) {
                    break;
                }
                if (weekCursor >= userPoint.ts && userEpoch <= maxUserEpoch) {
                    userEpoch += 1;
                    oldUserPoint = userPoint;
                    if (userEpoch > maxUserEpoch) {
                        userPoint = IVe.Point(0, 0, 0, 0);
                    } else {
                        userPoint = IVe(ve).userPointHistory(_tokenId, userEpoch);
                    }
                } else {
                    int128 dt = int128(int256(weekCursor - oldUserPoint.ts));
                    uint balanceOf = uint(int256(Math.positiveInt128(oldUserPoint.bias - dt * oldUserPoint.slope)));
                    if (balanceOf == 0 && userEpoch > maxUserEpoch) {
                        break;
                    }
                    if ((lockEndTime - weekCursor) > (minLockDurationForReward)) {
                        if (veSupply[weekCursor] > 0) {
                            toDistribute += (balanceOf * tokensPerWeek[weekCursor]) / veSupply[weekCursor];
                        }
                        weekCursor += WEEK;
                    } else {
                        break;
                    }
                }
            }
        }
        return ClaimCalculationResult(toDistribute, Math.min(maxUserEpoch, userEpoch - 1), weekCursor, maxUserEpoch, true);
    }

    function _calculateEmissionsClaim(uint _tokenId, address ve, uint _lastTokenTime) internal view returns (EmissionsCalculationResult memory) {
        uint userEpoch;
        uint cashToDistribute;
        uint tokenToDistribute;
        uint maxUserEpoch = IVe(ve).userPointEpoch(_tokenId);
        uint _startTime = startTime;

        if (maxUserEpoch == 0) {
            return EmissionsCalculationResult(0, 0, 0, 0, 0, false);
        }

        uint weekCursor = emissionTimeCursorOf[_tokenId];

        if (weekCursor == 0) {
            userEpoch = _findTimestampUserEpoch(ve, _tokenId, _startTime, maxUserEpoch);
        } else {
            userEpoch = emissionUserEpochOf[_tokenId];
        }

        if (userEpoch == 0) userEpoch = 1;

        IVe.Point memory userPoint = IVe(ve).userPointHistory(_tokenId, userEpoch);
        if (weekCursor == 0) {
            weekCursor = ((userPoint.ts + WEEK - 1) / WEEK) * WEEK;
        }
        if (weekCursor >= lastTokenTime) {
            return EmissionsCalculationResult(0, 0, 0, 0, 0, false);
        }
        if (weekCursor < _startTime) {
            weekCursor = _startTime;
        }

        IVe.Point memory oldUserPoint;
        {
            for (uint i = 0; i < 50; i++) {
                if (weekCursor >= _lastTokenTime) {
                    break;
                }
                if (weekCursor >= userPoint.ts && userEpoch <= maxUserEpoch) {
                    userEpoch += 1;
                    oldUserPoint = userPoint;
                    if (userEpoch > maxUserEpoch) {
                        userPoint = IVe.Point(0, 0, 0, 0);
                    } else {
                        userPoint = IVe(ve).userPointHistory(_tokenId, userEpoch);
                    }
                } else {
                    int128 dt = int128(int256(weekCursor - oldUserPoint.ts));
                    uint balanceOf = uint(int256(Math.positiveInt128(oldUserPoint.bias - dt * oldUserPoint.slope)));
                    if (balanceOf == 0 && userEpoch > maxUserEpoch) {
                        break;
                    }
                    if (veSupply[weekCursor] > 0) {
                        cashToDistribute += (balanceOf * tokenEmissionPerWeek[cash][weekCursor]) / veSupply[weekCursor];
                        tokenToDistribute += (balanceOf * tokenEmissionPerWeek[token][weekCursor]) / veSupply[weekCursor];
                    }
                    weekCursor += WEEK;
                }
            }
        }
        return EmissionsCalculationResult(cashToDistribute, tokenToDistribute, Math.min(maxUserEpoch, userEpoch - 1), weekCursor, maxUserEpoch, true);
    }

    function claimable(uint _tokenId) external view returns (uint) {
        uint _lastTokenTime = (lastTokenTime / WEEK) * WEEK;
        ClaimCalculationResult memory result = _calculateClaim(_tokenId, votingEscrow, _lastTokenTime);
        return result.toDistribute;
    }

    function emissionsClaimable(uint _tokenId) external view returns (uint, uint) {
        uint _lastEmissionsTime = (lastEmissionsTime / WEEK) * WEEK;
        EmissionsCalculationResult memory result = _calculateEmissionsClaim(_tokenId, votingEscrow, _lastEmissionsTime);
        return (result.cashToDistribute, result.tokenToDistribute);
    }

    function claim(uint _tokenId) external returns (uint) {
        if (block.timestamp >= timeCursor) _checkpointTotalSupply();
        uint _lastTokenTime = lastTokenTime;
        _lastTokenTime = (_lastTokenTime / WEEK) * WEEK;
        uint amount = _claim(_tokenId, votingEscrow, _lastTokenTime);
        if (amount != 0) {
            IERC20Upgradeable(token).safeTransfer(IVe(votingEscrow).ownerOf(_tokenId), amount);
            tokenLastBalance -= amount;
        }
        return amount;
    }

    function claimEmissions(uint _tokenId) external returns (uint, uint) {
        if (block.timestamp >= timeCursor) _checkpointTotalSupply();
        uint _lastEmissionsTime = lastEmissionsTime;
        _lastEmissionsTime = (_lastEmissionsTime / WEEK) * WEEK;
        (uint cashAmount, uint tokenAmount) = _claimEmissions(_tokenId, votingEscrow, _lastEmissionsTime);

        if (cashAmount != 0) {
            IERC20Upgradeable(cash).safeTransfer(IVe(votingEscrow).ownerOf(_tokenId), cashAmount);
            cashLastBalance -= cashAmount;
        }
        if (tokenAmount != 0) {
            IERC20Upgradeable(token).safeTransfer(IVe(votingEscrow).ownerOf(_tokenId), tokenAmount);
            tokenLastBalance -= tokenAmount;
        }
        return (cashAmount, tokenAmount);
    }

    function claimMany(uint[] memory _tokenIds) external returns (bool) {
        if (block.timestamp >= timeCursor) _checkpointTotalSupply();
        uint _lastTokenTime = lastTokenTime;
        _lastTokenTime = (_lastTokenTime / WEEK) * WEEK;
        address _votingEscrow = votingEscrow;
        uint total = 0;

        for (uint i = 0; i < _tokenIds.length; i++) {
            uint _tokenId = _tokenIds[i];
            if (_tokenId == 0) break;
            uint amount = _claim(_tokenId, _votingEscrow, _lastTokenTime);
            if (amount != 0) {
                IERC20Upgradeable(token).safeTransfer(IVe(_votingEscrow).ownerOf(_tokenId), amount);
                total += amount;
            }
        }
        if (total != 0) {
            tokenLastBalance -= total;
        }

        return true;
    }

    // Once off event on contract initialize
    function setDepositor(address _depositor) external {
        require(msg.sender == depositor, "!depositor");
        depositor = _depositor;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface IVeDist {
    function checkpointToken() external;

    function checkpointTotalSupply() external;

    function claim(uint _tokenId) external returns (uint);

    function checkpointEmissions() external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

library Math {
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function positiveInt128(int128 value) internal pure returns (int128) {
        return value < 0 ? int128(0) : value;
    }

    function closeTo(
        uint256 a,
        uint256 b,
        uint256 target
    ) internal pure returns (bool) {
        if (a > b) {
            if (a - b <= target) {
                return true;
            }
        } else {
            if (b - a <= target) {
                return true;
            }
        }
        return false;
    }

    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface IVoter {
    function ve() external view returns (address);

    function attachTokenToGauge(uint _tokenId, address account) external;

    function detachTokenFromGauge(uint _tokenId, address account) external;

    function emitDeposit(uint _tokenId, address account, uint amount) external;

    function emitWithdraw(uint _tokenId, address account, uint amount) external;

    function distribute(address _gauge) external;

    function notifyRewardAmount(uint amount) external;

    function gauges(address _pool) external view returns (address);

    function isWhitelisted(address _token) external view returns (bool);

    function internal_bribes(address _gauge) external view returns (address);

    function external_bribes(address _gauge) external view returns (address);

    function getVeShare() external;

    function viewSatinCashLPGaugeAddress() external view returns (address);

    function distributeAll() external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface IVe {
    enum DepositType {
        DEPOSIT_FOR_TYPE,
        CREATE_LOCK_TYPE,
        INCREASE_LOCK_AMOUNT,
        INCREASE_UNLOCK_TIME,
        MERGE_TYPE
    }

    struct Point {
        int128 bias;
        int128 slope; // # -dweight / dt
        uint ts;
        uint blk; // block
    }
    /* We cannot really do block numbers per se b/c slope is per time, not per block
     * and per block could be fairly bad b/c Ethereum changes blocktimes.
     * What we can do is to extrapolate ***At functions */

    struct LockedBalance {
        int128 amount;
        uint end;
    }

    function token() external view returns (address);

    function ownerOf(uint) external view returns (address);

    function balanceOfNFT(uint) external view returns (uint);

    function isApprovedOrOwner(address, uint) external view returns (bool);

    function createLockFor(uint, uint, address) external returns (uint);

    function userPointEpoch(uint tokenId) external view returns (uint);

    function epoch() external view returns (uint);

    function userPointHistory(uint tokenId, uint loc) external view returns (Point memory);

    function lockedEnd(uint _tokenId) external view returns (uint);

    function pointHistory(uint loc) external view returns (Point memory);

    function checkpoint() external;

    function depositFor(uint tokenId, uint value) external;

    function attachToken(uint tokenId) external;

    function detachToken(uint tokenId) external;

    function voting(uint tokenId) external;

    function abstain(uint tokenId) external;

    function totalSupply() external view returns (uint);

    function VeOwner() external view returns (address);

    function isOwnerNFTID(uint _tokenID) external view returns (bool);
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../extensions/draft-IERC20PermitUpgradeable.sol";
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

    function safePermit(
        IERC20PermitUpgradeable token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20PermitUpgradeable {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}