// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import './VotingEscrowStorage.sol';
import "../ErrorReporter.sol";
import '../RegistryInterface.sol';
import "./VotingEscrow.sol";

contract VotingEscrowProxy is VotingEscrowStorageV1, VotingEscrowErrorReporter {
    /**
      * @notice Emitted when implementation is changed
      */
    event NewImplementation(address oldImplementation, address newImplementation);

    constructor(
        address _implementation,
        address _registry,
        address _token,
        string memory _name,
        string memory _symbol,
        uint _interval,
        uint _minDuration,
        uint _maxDuration,
        uint _minLockAmount,
        address _governor
    ) {
        implementation = _implementation;

        delegateTo(implementation, abi.encodeWithSignature("initialize(address,address,string,string,uint256,uint256,uint256,uint256,address)",
            _registry,
            _token,
            _name,
            _symbol,
            _interval,
            _minDuration,
            _maxDuration,
            _minLockAmount,
            _governor
        ));
    }

    function _setImplementation(address newImplementation) external returns(uint) {
        if (msg.sender != RegistryInterface(registry).admin()) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SET_NEW_IMPLEMENTATION);
        }

        address oldImplementation = implementation;
        implementation = newImplementation;

        emit NewImplementation(oldImplementation, implementation);

        return(uint(Error.NO_ERROR));
    }

    /**
     * @notice Internal method to delegate execution to another contract
     * @dev It returns to the external caller whatever the implementation returns or forwards reverts
     * @param callee The contract to delegatecall
     * @param data The raw data to delegatecall
     * @return The returned bytes from the delegatecall
     */
    function delegateTo(address callee, bytes memory data) internal returns (bytes memory) {
        (bool success, bytes memory returnData) = callee.delegatecall(data);
        assembly {
            if eq(success, 0) {
                revert(add(returnData, 0x20), returndatasize())
            }
        }
        return returnData;
    }

    function delegateAndReturn() internal returns (bytes memory) {
        (bool success, ) = implementation.delegatecall(msg.data);

        assembly {
            let free_mem_ptr := mload(0x40)
            returndatacopy(free_mem_ptr, 0, returndatasize())

            switch success
            case 0 { revert(free_mem_ptr, returndatasize()) }
            default { return(free_mem_ptr, returndatasize()) }
        }
    }

    /**
     * @notice Delegates execution to an implementation contract
     * @dev It returns to the external caller whatever the implementation returns or forwards reverts
     */
    fallback() external {
        // delegate all other functions to current implementation
        delegateAndReturn();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "../RegistryInterface.sol";
import "./Governor.sol";

contract VotingEscrowStorage {
    address public implementation;
    RegistryInterface public registry;
}

contract VotingEscrowStorageV1 is VotingEscrowStorage {
    struct Point {
        int128 bias;
        int128 slope; // - dweight / dt
        uint ts;
        uint blk; // block
    }

    struct LockedBalance {
        int128 amount;
        uint start;
        uint end;
    }

    int128 public constant DEPOSIT_FOR_TYPE = 0;
    int128 public constant CREATE_LOCK_TYPE = 1;
    int128 public constant INCREASE_LOCK_AMOUNT = 2;
    int128 public constant INCREASE_UNLOCK_TIME = 3;
    uint internal constant MULTIPLIER = 1e18;

    uint public interval;
    uint public minDuration;
    uint public maxDuration;
    address public token;
    string public name;
    string public symbol;
    uint8 public decimals;
    uint public supply;
    uint public minLockAmount;

    mapping(address => address[]) public delegateAt;
    mapping(address => LockedBalance) public locked;
    mapping(address => address) public delegateOf;

    uint public epoch;
    mapping(uint => Point) public pointHistory; // epoch -> unsigned point
    mapping(address => mapping(uint => Point)) public userPointHistory; // user -> Point[user_epoch]
    mapping(address => uint) public userPointEpoch;
    mapping(uint => int128) public slopeChanges; // time -> signed slope change

    Governor public governor;
    mapping(address => bool) public isWhiteListed;

    address public controller;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

contract ControllerErrorReporter {
    enum Error {
        NO_ERROR,
        UNAUTHORIZED,
        CONTROLLER_MISMATCH,
        INSUFFICIENT_SHORTFALL,
        INSUFFICIENT_LIQUIDITY,
        INVALID_CLOSE_FACTOR,
        INVALID_COLLATERAL_FACTOR,
        INVALID_LIQUIDATION_INCENTIVE,
        MARKET_NOT_LISTED,
        MARKET_ALREADY_LISTED,
        MATH_ERROR,
        NONZERO_BORROW_BALANCE,
        PRICE_ERROR,
        REJECTION,
        GUARDIAN_REJECTION,
        SNAPSHOT_ERROR,
        TOO_MANY_ASSETS,
        TOO_MUCH_REPAY
    }

    enum FailureInfo {
        ACCEPT_ADMIN_PENDING_ADMIN_CHECK,
        ACCEPT_PENDING_IMPLEMENTATION_ADDRESS_CHECK,
        EXIT_MARKET_BALANCE_OWED,
        EXIT_MARKET_REJECTION,
        SET_CLOSE_FACTOR_OWNER_CHECK,
        SET_CLOSE_FACTOR_VALIDATION,
        SET_COLLATERAL_FACTOR_OWNER_CHECK,
        SET_COLLATERAL_FACTOR_NO_EXISTS,
        SET_COLLATERAL_FACTOR_VALIDATION,
        SET_COLLATERAL_FACTOR_WITHOUT_PRICE,
        SET_LIQUIDATION_INCENTIVE_OWNER_CHECK,
        SET_LIQUIDATION_INCENTIVE_VALIDATION,
        SET_MAX_ASSETS_OWNER_CHECK,
        SET_GUARDIAN_OWNER_CHECK,
        SET_PENDING_ADMIN_OWNER_CHECK,
        SET_PENDING_IMPLEMENTATION_OWNER_CHECK,
        SUPPORT_MARKET_EXISTS,
        SUPPORT_MARKET_OWNER_CHECK,
        SET_FEE_FACTOR,
        SET_MAX_FEE_FACTOR,
        SET_BORROW_DELAY_OWNER_CHECK
    }

    /**
      * @dev `error` corresponds to enum Error; `info` corresponds to enum FailureInfo, and `detail` is an arbitrary
      * contract-specific code that enables us to report opaque error codes from upgradeable contracts.
      **/
    event Failure(uint error, uint info, uint detail);

    /**
      * @dev use this when reporting a known error from the money market or a non-upgradeable collaborator
      */
    function fail(Error err, FailureInfo info) internal returns (uint) {
        emit Failure(uint(err), uint(info), 0);

        return uint(err);
    }

    /**
      * @dev use this when reporting an opaque error from an upgradeable collaborator contract
      */
    function failOpaque(Error err, FailureInfo info, uint opaqueError) internal returns (uint) {
        emit Failure(uint(err), uint(info), opaqueError);

        return uint(err);
    }
}

contract TokenErrorReporter {
    enum Error {
        NO_ERROR,
        UNAUTHORIZED,
        BAD_INPUT,
        CONTROLLER_REJECTION,
        INVALID_ACCOUNT_PAIR,
        INVALID_CLOSE_AMOUNT_REQUESTED,
        MATH_ERROR,
        MARKET_NOT_FRESH,
        TOKEN_INSUFFICIENT_CASH
    }

    /*
     * Note: FailureInfo (but not Error) is kept in alphabetical order
     *       This is because FailureInfo grows significantly faster, and
     *       the order of Error has some meaning, while the order of FailureInfo
     *       is entirely arbitrary.
     */
    enum FailureInfo {
        ACCRUE_INTEREST_ACCUMULATED_INTEREST_CALCULATION_FAILED,
        ACCRUE_INTEREST_NEW_BORROW_INDEX_CALCULATION_FAILED,
        ACCRUE_INTEREST_NEW_TOTAL_BORROWS_CALCULATION_FAILED,
        ACCRUE_INTEREST_NEW_TOTAL_RESERVES_CALCULATION_FAILED,
        ACCRUE_INTEREST_SIMPLE_INTEREST_FACTOR_CALCULATION_FAILED,
        BORROW_ACCUMULATED_BALANCE_CALCULATION_FAILED,
        BORROW_ACCRUE_INTEREST_FAILED,
        BORROW_CASH_NOT_AVAILABLE,
        BORROW_FRESHNESS_CHECK,
        BORROW_NEW_TOTAL_BALANCE_CALCULATION_FAILED,
        BORROW_NEW_ACCOUNT_BORROW_BALANCE_CALCULATION_FAILED,
        BORROW_CONTROLLER_REJECTION,
        LIQUIDATE_ACCRUE_BORROW_INTEREST_FAILED,
        LIQUIDATE_ACCRUE_COLLATERAL_INTEREST_FAILED,
        LIQUIDATE_COLLATERAL_FRESHNESS_CHECK,
        LIQUIDATE_CONTROLLER_REJECTION,
        LIQUIDATE_CONTROLLER_CALCULATE_AMOUNT_SEIZE_FAILED,
        LIQUIDATE_CLOSE_AMOUNT_IS_UINT_MAX,
        LIQUIDATE_CLOSE_AMOUNT_IS_ZERO,
        LIQUIDATE_FRESHNESS_CHECK,
        LIQUIDATE_LIQUIDATOR_IS_BORROWER,
        LIQUIDATE_REPAY_BORROW_FRESH_FAILED,
        LIQUIDATE_SEIZE_BALANCE_INCREMENT_FAILED,
        LIQUIDATE_SEIZE_BALANCE_DECREMENT_FAILED,
        LIQUIDATE_SEIZE_CONTROLLER_REJECTION,
        LIQUIDATE_SEIZE_LIQUIDATOR_IS_BORROWER,
        LIQUIDATE_SEIZE_TOO_MUCH,
        MINT_ACCRUE_INTEREST_FAILED,
        MINT_CONTROLLER_REJECTION,
        MINT_EXCHANGE_CALCULATION_FAILED,
        MINT_EXCHANGE_RATE_READ_FAILED,
        MINT_FRESHNESS_CHECK,
        MINT_NEW_ACCOUNT_BALANCE_CALCULATION_FAILED,
        MINT_NEW_TOTAL_SUPPLY_CALCULATION_FAILED,
        REDEEM_ACCRUE_INTEREST_FAILED,
        REDEEM_CONTROLLER_REJECTION,
        REDEEM_EXCHANGE_TOKENS_CALCULATION_FAILED,
        REDEEM_EXCHANGE_AMOUNT_CALCULATION_FAILED,
        REDEEM_EXCHANGE_RATE_READ_FAILED,
        REDEEM_FRESHNESS_CHECK,
        REDEEM_NEW_ACCOUNT_BALANCE_CALCULATION_FAILED,
        REDEEM_NEW_TOTAL_SUPPLY_CALCULATION_FAILED,
        REDEEM_TRANSFER_OUT_NOT_POSSIBLE,
        REDUCE_RESERVES_ACCRUE_INTEREST_FAILED,
        REDUCE_RESERVES_ADMIN_CHECK,
        REDUCE_RESERVES_CASH_NOT_AVAILABLE,
        REDUCE_RESERVES_FRESH_CHECK,
        REDUCE_RESERVES_VALIDATION,
        REPAY_BEHALF_ACCRUE_INTEREST_FAILED,
        REPAY_BORROW_ACCRUE_INTEREST_FAILED,
        REPAY_BORROW_ACCUMULATED_BALANCE_CALCULATION_FAILED,
        REPAY_BORROW_CONTROLLER_REJECTION,
        REPAY_BORROW_FRESHNESS_CHECK,
        REPAY_BORROW_NEW_ACCOUNT_BORROW_BALANCE_CALCULATION_FAILED,
        REPAY_BORROW_NEW_TOTAL_BALANCE_CALCULATION_FAILED,
        SET_CONTROLLER_OWNER_CHECK,
        SET_INTEREST_RATE_MODEL_ACCRUE_INTEREST_FAILED,
        SET_INTEREST_RATE_MODEL_FRESH_CHECK,
        SET_INTEREST_RATE_MODEL_OWNER_CHECK,
        SET_RESERVE_FACTOR_ACCRUE_INTEREST_FAILED,
        SET_RESERVE_FACTOR_ADMIN_CHECK,
        SET_RESERVE_FACTOR_FRESH_CHECK,
        SET_RESERVE_FACTOR_BOUNDS_CHECK,
        TRANSFER_CONTROLLER_REJECTION,
        TRANSFER_NOT_ALLOWED,
        TRANSFER_NOT_ENOUGH,
        TRANSFER_TOO_MUCH,
        ADD_RESERVES_ACCRUE_INTEREST_FAILED,
        ADD_RESERVES_FRESH_CHECK,
        SET_NEW_IMPLEMENTATION
    }

    /**
      * @dev `error` corresponds to enum Error; `info` corresponds to enum FailureInfo, and `detail` is an arbitrary
      * contract-specific code that enables us to report opaque error codes from upgradeable contracts.
      **/
    event Failure(uint error, uint info, uint detail);

    /**
      * @dev use this when reporting a known error from the money market or a non-upgradeable collaborator
      */
    function fail(Error err, FailureInfo info) internal returns (uint) {
        emit Failure(uint(err), uint(info), 0);

        return uint(err);
    }

    /**
      * @dev use this when reporting an opaque error from an upgradeable collaborator contract
      */
    function failOpaque(Error err, FailureInfo info, uint opaqueError) internal returns (uint) {
        emit Failure(uint(err), uint(info), opaqueError);

        return uint(err);
    }
}

contract OracleErrorReporter {
    enum Error {
        NO_ERROR,
        POOL_OR_COIN_EXIST,
        ORACLE_EXIST,
        UNAUTHORIZED,
        UPDATE_PRICE
    }

    enum FailureInfo {
        ADD_ORACLE,
        ADD_POOL_OR_COIN,
        NO_PAIR,
        NO_RESERVES,
        PERIOD_NOT_ELAPSED,
        SET_NEW_IMPLEMENTATION,
        UPDATE_DATA
    }

    /**
      * @dev `error` corresponds to enum Error; `info` corresponds to enum FailureInfo, and `detail` is an arbitrary
      * contract-specific code that enables us to report opaque error codes from upgradeable contracts.
      **/
    event Failure(uint error, uint info, uint detail);

    /**
      * @dev use this when reporting a known error from the money market or a non-upgradeable collaborator
      */
    function fail(Error err, FailureInfo info) internal returns (uint) {
        emit Failure(uint(err), uint(info), 0);

        return uint(err);
    }
}

contract FactoryErrorReporter {
    enum Error {
        NO_ERROR,
        INVALID_POOL,
        INVALID_UNDERLYING,
        MARKET_NOT_LISTED,
        UNAUTHORIZED
    }

    enum FailureInfo {
        ADD_PTOKEN_BAD_RESULT,
        CREATE_PETH_POOL,
        CREATE_PPIE_POOL,
        DEFICIENCY_LIQUIDITY,
        SET_MIN_LIQUIDITY_OWNER_CHECK,
        SET_NEW_CONTROLLER,
        SET_NEW_CREATE_POOL_FEE_AMOUNT,
        SET_NEW_DECIMALS,
        SET_NEW_EXCHANGE_RATE,
        SET_NEW_INTEREST_RATE_MODEL,
        SET_NEW_IMPLEMENTATION,
        SET_NEW_RESERVE_FACTOR,
        SUPPORT_MARKET_BAD_RESULT,
        ADD_UNDERLYING_TO_BLACKLIST,
        REMOVE_UNDERLYING_FROM_BLACKLIST,
        UNDERLYING_IN_BLACKLIST,
        UPDATE_PRICE_BAD_RESULT,
        WITHDRAW_ERC20
    }

    /**
      * @dev `error` corresponds to enum Error; `info` corresponds to enum FailureInfo, and `detail` is an arbitrary
      * contract-specific code that enables us to report opaque error codes from upgradeable contracts.
      **/
    event Failure(uint error, uint info, uint detail);

    /**
      * @dev use this when reporting a known error from the money market or a non-upgradeable collaborator
      */
    function fail(Error err, FailureInfo info) internal returns (uint) {
        emit Failure(uint(err), uint(info), 0);

        return uint(err);
    }
}

contract RegistryErrorReporter {
    enum Error {
        NO_ERROR,
        UNAUTHORIZED
    }

    enum FailureInfo {
        ACCEPT_ADMIN_PENDING_ADMIN_CHECK,
        SET_NEW_IMPLEMENTATION,
        SET_PENDING_ADMIN_OWNER_CHECK,
        SET_NEW_FACTORY,
        SET_NEW_ORACLE
    }

    /**
      * @dev `error` corresponds to enum Error; `info` corresponds to enum FailureInfo, and `detail` is an arbitrary
      * contract-specific code that enables us to report opaque error codes from upgradeable contracts.
      **/
    event Failure(uint error, uint info, uint detail);

    /**
      * @dev use this when reporting a known error from the money market or a non-upgradeable collaborator
      */
    function fail(Error err, FailureInfo info) internal returns (uint) {
        emit Failure(uint(err), uint(info), 0);

        return uint(err);
    }
}

contract VotingEscrowErrorReporter {
    enum Error {
        NO_ERROR,
        UNAUTHORIZED
    }

    enum FailureInfo {
        SET_NEW_IMPLEMENTATION
    }

    /**
      * @dev `error` corresponds to enum Error; `info` corresponds to enum FailureInfo, and `detail` is an arbitrary
      * contract-specific code that enables us to report opaque error codes from upgradeable contracts.
      **/
    event Failure(uint error, uint info, uint detail);

    /**
      * @dev use this when reporting a known error from the money market or a non-upgradeable collaborator
      */
    function fail(Error err, FailureInfo info) internal returns (uint) {
        emit Failure(uint(err), uint(info), 0);

        return uint(err);
    }
}

contract DistributorErrorReporter {
    enum Error {
        NO_ERROR,
        UNAUTHORIZED
    }

    enum FailureInfo {
        SET_NEW_IMPLEMENTATION
    }

    /**
      * @dev `error` corresponds to enum Error; `info` corresponds to enum FailureInfo, and `detail` is an arbitrary
      * contract-specific code that enables us to report opaque error codes from upgradeable contracts.
      **/
    event Failure(uint error, uint info, uint detail);

    /**
      * @dev use this when reporting a known error from the money market or a non-upgradeable collaborator
      */
    function fail(Error err, FailureInfo info) internal returns (uint) {
        emit Failure(uint(err), uint(info), 0);

        return uint(err);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

interface RegistryInterface {

    /**
     *  Returns admin address for pToken contracts
     *  @return admin address
     */
    function admin() external view returns (address);

    /**
     *  Returns pToken factory address of protocol
     *  @return factory address
     */
    function factory() external view returns (address);

    /**
     *  Returns oracle address for protocol
     *  @return oracle address
     */
    function oracle() external view returns (address);

    /**
     *  Returns address of actual pToken implementation contract
     *  @return Address of contract
     */
    function pTokenImplementation() external view returns (address);

    /**
     *  Returns address of actual pPIE token
     *  @return Address of contract
     */
    function pPIE() external view returns (address);

    /**
     *  Returns address of actual pETH token
     *  @return Address of contract
     */
    function pETH() external view returns (address);

    function addPToken(address underlying, address pToken) external returns(uint);
    function addPETH(address pETH_) external returns(uint);
    function addPPIE(address pPIE_) external returns(uint);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./VotingEscrowImports/SafeERC20.sol";
import "./VotingEscrowImports/IERC20Metadata.sol";
import "./VotingEscrowImports/ReentrancyGuard.sol";
import "./VotingEscrowImports/IVotingEscrow.sol";
import "./VotingEscrowImports/Integers.sol";
import "./VotingEscrowStorage.sol";
import "../Tokens/PTokenInterfaces.sol";

/**
 * @title Voting Escrow
 * @notice Votes have a weight depending on time, so that users are
 *         committed to the future of (whatever they are voting for)
 * @dev Vote weight decays linearly over time. Lock time cannot be
 *      more than `MAXTIME`.
 */

// Voting escrow to have time-weighted votes
// Votes have a weight depending on time, so that users are committed
// to the future of (whatever they are voting for).
// The weight in this implementation is linear, and lock cannot be more than maxtime:
// w ^
// 1 +        /
//   |      /
//   |    /
//   |  /
//   |/
// 0 +--------+------> time
//       maxtime

contract VotingEscrow is VotingEscrowStorageV1, ReentrancyGuard, IVotingEscrow {
    using SafeERC20 for IERC20;
    using Integers for int128;
    using Integers for uint;

    function initialize(
        RegistryInterface _registry,
        address _token,
        string memory _name,
        string memory _symbol,
        uint _interval,
        uint _minDuration,
        uint _maxDuration,
        uint _minLockAmount,
        address _governor
    ) public {
        require(registry == RegistryInterface(address(0)), "VE: only once");

        registry = _registry;
        token = _token;
        name = _name;
        symbol = _symbol;
        decimals = IERC20Metadata(_token).decimals();

        interval = _interval;
        minDuration = (_minDuration / _interval) * _interval; // rounded down to a multiple of interval
        maxDuration = (_maxDuration / _interval) * _interval; // rounded down to a multiple of interval

        pointHistory[0].blk = block.number;
        pointHistory[0].ts = block.timestamp;

        minLockAmount = _minLockAmount;

        governor = Governor(_governor);

        emit NewMinLockAmount(0, _minLockAmount);
        emit NewMinDuration(0, minDuration);
        emit NewMaxDuration(0, maxDuration);
    }

    /**
     * @notice Get the delegate length for user
     * @param user User wallet address
     * @return Value of the delegate length
     */
    function delegateLength(address user) external view returns (uint) {
        return delegateAt[user].length;
    }

    /**
     * @notice Get the most recently recorded rate of voting power decrease for user
     * @param user User wallet address
     * @return Value of the slope
     */
    function getLastUserSlope(address user) external view override returns (int128) {
        uint uepoch = userPointEpoch[user];

        return userPointHistory[user][uepoch].slope;
    }

    /**
     * @notice Get the timestamp for checkpoint `id` for user
     * @param user User wallet address
     * @param id User epoch number
     * @return Epoch time of the checkpoint
     */
    function getCheckpointTime(address user, uint id) external view override returns (uint) {
        return userPointHistory[user][id].ts;
    }

    /**
     * @notice Get timestamp when user's lock finishes
     * @param user User wallet address
     * @return Epoch time of the lock end
     */
    function getUnlockTime(address user) external view override returns (uint) {
        return locked[user].end;
    }

    /**
     * @notice Get timestamp when user's lock starts
     * @param user User wallet address
     * @return Epoch time of the lock start
     */
    function getStartTime(address user) external view override returns (uint) {
        return locked[user].start;
    }

    /**
     * @notice Get amount user's lock
     * @param user User wallet address
     * @return Amount of lock
     */
    function getAmount(address user) external view override returns (int128) {
        return locked[user].amount;
    }

    /**
     * @notice Record global and per-user data to checkpoint
     * @param user User's wallet address. No user checkpoint if 0x0
     * @param old_locked Previous locked amount / end lock time for the user
     * @param new_locked New locked amount / end lock time for the user
     */
    function _checkpoint(
        address user,
        LockedBalance memory old_locked,
        LockedBalance memory new_locked
    ) internal {
        Point memory u_old;
        Point memory u_new;
        int128 old_dslope;
        int128 new_dslope;
        uint _epoch = epoch;

        if (user != address(0)) {
            // Calculate slopes and biases
            // Kept at zero when they have to
            if (old_locked.end > block.timestamp && old_locked.amount > 0) {
                u_old.slope = old_locked.amount / maxDuration.toInt128();
                u_old.bias = u_old.slope * (old_locked.end - block.timestamp).toInt128();
            }
            if (new_locked.end > block.timestamp && new_locked.amount > 0) {
                u_new.slope = new_locked.amount / maxDuration.toInt128();
                u_new.bias = u_new.slope * (new_locked.end - block.timestamp).toInt128();
            }

            // Read values of scheduled changes in the slope
            // old_locked.end can be in the past and in the future
            // new_locked.end can ONLY by in the FUTURE unless everything expired: than zeros
            old_dslope = slopeChanges[old_locked.end];
            if (new_locked.end != 0) {
                if (new_locked.end == old_locked.end) {
                    new_dslope = old_dslope;
                } else {
                    new_dslope = slopeChanges[new_locked.end];
                }
            }
        }

        Point memory last_point = Point({bias: 0, slope: 0, ts: block.timestamp, blk: block.number});
        if (_epoch > 0) {
            last_point = pointHistory[_epoch];
        }
        uint last_checkpoint = last_point.ts;

        // initial_last_point is used for extrapolation to calculate block number
        // (approximately, for *At methods) and save them
        // as we cannot figure that out exactly from inside the contract
        Point memory initial_last_point = Point(last_point.bias, last_point.slope, last_point.ts, last_point.blk);
        uint block_slope; // dblock/dt
        if (block.timestamp > last_point.ts) {
            block_slope = (MULTIPLIER * (block.number - last_point.blk)) / (block.timestamp - last_point.ts);
        }

        // If last point is already recorded in this block, slope=0
        // But that's ok b/c we know the block in such case
        {
            // Go over weeks to fill history and calculate what the current point is
            uint t_i = (last_checkpoint / interval) * interval;
            for(uint i = 0; i < 255; i++) {
                // Hopefully it won't happen that this won't get used in 5 years!
                // If it does, users will be able to withdraw but vote weight will be broken
                t_i += interval;
                int128 d_slope;
                if (t_i > block.timestamp) {
                    t_i = block.timestamp;
                } else {
                    d_slope = slopeChanges[t_i];
                }
                last_point.bias -= last_point.slope * (t_i - last_checkpoint).toInt128();
                last_point.slope += d_slope;
                if (last_point.bias < 0) {
                    // This can happen
                    last_point.bias = 0;
                }

                if (last_point.slope < 0) {
                    // This cannot happen - just in case
                    last_point.slope = 0;
                }

                last_checkpoint = t_i;
                last_point.ts = t_i;
                last_point.blk = initial_last_point.blk + (block_slope * (t_i - initial_last_point.ts)) / MULTIPLIER;
                _epoch += 1;
                if (t_i == block.timestamp) {
                    last_point.blk = block.number;
                    break;
                } else {
                    pointHistory[_epoch] = last_point;
                }
            }
        }

        epoch = _epoch;

        // Now point_history is filled until t=now
        if (user != address(0)) {
            // If last point was in this block, the slope change has been applied already
            // But in such case we have 0 slope(s)
            last_point.slope += (u_new.slope - u_old.slope);
            last_point.bias += (u_new.bias - u_old.bias);
            if (last_point.slope < 0) {
                last_point.slope = 0;
            }
            if (last_point.bias < 0) {
                last_point.bias = 0;
            }
        }

        // Record the changed point into history
        pointHistory[_epoch] = last_point;

        if (user != address(0)) {
            // Schedule the slope changes (slope is going down)
            // We subtract new_user_slope from [new_locked.end]
            // and add old_user_slope to [old_locked.end]
            if (old_locked.end > block.timestamp) {
                // old_dslope was <something> - u_old.slope, so we cancel that
                old_dslope += u_old.slope;
                if (new_locked.end == old_locked.end) {
                    old_dslope -= u_new.slope; // It was a new deposit, not extension
                }
                slopeChanges[old_locked.end] = old_dslope;
            }

            if (new_locked.end > block.timestamp) {
                if (new_locked.end > old_locked.end) {
                    new_dslope -= u_new.slope; // old slope disappeared at this point
                    slopeChanges[new_locked.end] = new_dslope;
                }
                // else: we recorded it already in old_dslope
            }

            // Now handle user history
            uint user_epoch = userPointEpoch[user] + 1;

            userPointEpoch[user] = user_epoch;
            u_new.ts = block.timestamp;
            u_new.blk = block.number;
            userPointHistory[user][user_epoch] = u_new;
        }
    }

    /**
     * @notice Deposit and lock tokens for a user
     * @param user User's wallet address
     * @param amount Amount to deposit
     * @param unlock_time New time when to unlock the tokens, or 0 if unchanged
     * @param locked_balance Previous locked amount / timestamp
     */
    function _depositFor(
        address user,
        uint amount,
        uint unlock_time,
        LockedBalance memory locked_balance,
        int128 depositType
    ) internal {
        LockedBalance memory _locked = locked_balance;
        uint supply_before = supply;

        supply = supply_before + amount;
        LockedBalance memory old_locked;
        (old_locked.amount, old_locked.start, old_locked.end) = (
            _locked.amount,
            _locked.start,
            _locked.end
        );
        // Adding to existing lock, or if a lock is expired - creating a new one
        _locked.amount += (amount).toInt128();
        if (unlock_time != 0) {
            if (_locked.start == 0) {
                _locked.start = block.timestamp;
            }
            _locked.end = unlock_time;
        }
        locked[user] = _locked;

        // Possibilities:
        // Both old_locked.end could be current or expired (>/< block.timestamp)
        // value == 0 (extend lock) or value > 0 (add to lock or extend lock)
        // _locked.end > block.timestamp (always)
        _checkpoint(user, old_locked, _locked);

        if (amount > 0) {
            IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
            PErc20Interface(registry.pPIE()).mint(amount);
        }

        emit Deposit(user, amount, _locked.end, depositType, block.timestamp);
        emit Supply(supply_before, supply_before + amount);
    }

    /**
     * @notice First delegate for 'msg.sender' to user
     * @param user User's address
     */
    function delegate(address user) external {
        require(delegateOf[msg.sender] == address(0), "VE: Old delegator found");
        require(user != address(0), "VE: delegatee must not be zero address");
        delegateOf[msg.sender] = user;

        _pushDelegate(user, msg.sender);
    }

    /**
     * @notice Change delegator for 'msg.sender' to user
     * @param user User's address
     */
    function changeDelegator(address user) external {
        require(delegateOf[msg.sender] != address(0), "VE: Old delegator is not found");
        require(user != address(0), "VE: delegatee must not be zero address");

        _popDelegate(delegateOf[msg.sender], msg.sender);
        _pushDelegate(user, msg.sender);

        delegateOf[msg.sender] = user;
    }

    /**
     * @notice Remove delegator for 'msg.sender'
     */
    function removeDelegator() external {
        require(delegateOf[msg.sender] != address(0), "VE: Old delegator is not found");

        _popDelegate(delegateOf[msg.sender], msg.sender);

        delegateOf[msg.sender] = address(0);
    }

    /**
     * @notice Add the delegate for user
     * @param user User address
     * @param _delegate Delegate address
     */
    function _pushDelegate(address user, address _delegate) internal {
        bool found;
        address[] storage delegates = delegateAt[user];
        for (uint i = 0; i < delegates.length; ) {
            if (delegates[i] == _delegate) {
                found = true;
            }
            unchecked {
                ++i;
            }
        }
        if (!found) {
            delegateAt[user].push(_delegate);
        }
    }

    /**
     * @notice Remove the delegate for user
     * @param user User address
     * @param _delegate Delegate address
     */
    function _popDelegate(address user, address _delegate) internal {
        address[] storage delegates = delegateAt[user];

        uint lastId = delegates.length - 1;
        address lastDelegate = delegates[lastId];

        for (uint i = 0; i < delegates.length; ) {
            if (delegates[i] == _delegate) {
                delegates[i] = lastDelegate;
                break;
            }
            unchecked {
                ++i;
            }
        }

        delegates.pop();
    }

    /**
     * @notice Deposit `amount` tokens for user and add to the lock
     * @dev Anyone (even a smart contract) can deposit for someone else, but
     *      cannot extend their locktime and deposit for a brand new user
     * @param user User's wallet address
     * @param amount Amount to add to user's lock
     */
    function depositFor(address user, uint amount) external override nonReentrant {
        require(amount > minLockAmount, "VE: INVALID_VALUE");

        LockedBalance memory _locked = locked[user];
        require(_locked.amount > 0, "VE: LOCK_NOT_FOUND");
        require(_locked.end > block.timestamp, "VE: LOCK_EXPIRED");

        _depositFor(user, amount, 0, _locked, DEPOSIT_FOR_TYPE);
    }

    /**
     * @notice Deposit `amount` tokens for `msg.sender` and lock for `_duration`
     * @param amount Amount to deposit
     * @param duration Epoch time until tokens unlock from now
     */
    function createLock(uint amount, uint duration)
        external
        override
        nonReentrant
    {
        createLockForInternal(msg.sender, amount, duration);
    }

    /**
     * @notice Deposit `_value` tokens for user and lock for `_duration`
     * @dev Only delegates can creat a lock for someone else
     * @param user User's wallet address
     * @param amount Amount to add to user's lock
     * @param duration Epoch time until tokens unlock from now
     */
    function createLockFor(
        address user,
        uint amount,
        uint duration
    ) external override nonReentrant {
        createLockForInternal(user, amount, duration);
    }

    /**
     * @notice Check msg.sender (contract or not) and check in whitelist
     */
    function assertNotContract() internal view {
        if (msg.sender != tx.origin) {
            if (getWhiteListStatus(msg.sender)) {
                return;
            }

            revert("Smart contract depositors not allowed");
        }
    }

    function createLockForInternal(
        address user,
        uint amount,
        uint duration
    ) internal {
        assertNotContract();
        require(amount > minLockAmount, "VE: INVALID_VALUE");

        uint unlock_time = ((block.timestamp + duration) / interval) * interval; // Locktime is rounded down to a multiple of interval
        require(unlock_time >= block.timestamp + minDuration, "VE: UNLOCK_TIME_TOO_EARLY");
        require(unlock_time <= block.timestamp + maxDuration, "VE: UNLOCK_TIME_TOO_LATE");

        LockedBalance memory _locked = locked[user];
        require(_locked.amount == 0, "VE: EXISTING_LOCK_FOUND");

        _depositFor(user, amount, unlock_time, _locked, CREATE_LOCK_TYPE);
    }

    /**
     * @notice Deposit `amount` additional tokens for `msg.sender`
     *          without modifying the unlock time
     * @param user User's wallet address
     * @param amount Amount of tokens to deposit and add to the lock
     */
    function increaseAmountFor(
        address user,
        uint amount
    ) external override nonReentrant {
        increaseAmountInternal(user, amount);
    }

    /**
     * @notice Deposit `amount` additional tokens for `msg.sender`
     *          without modifying the unlock time
     * @param amount Amount of tokens to deposit and add to the lock
     */
    function increaseAmount(uint amount) external override nonReentrant {
        increaseAmountInternal(msg.sender, amount);
    }

    function increaseAmountInternal(address user, uint amount) internal {
        require(amount > 0, "VE: INVALID_VALUE");

        LockedBalance memory _locked = locked[msg.sender];
        require(_locked.amount > 0, "VE: LOCK_NOT_FOUND");
        require(_locked.end > block.timestamp, "VE: LOCK_EXPIRED");

        _depositFor(user, amount, 0, _locked, INCREASE_LOCK_AMOUNT);
    }

    /**
     * @notice Extend the unlock time for `msg.sender` to `duration`
     * @param duration Increased epoch time for unlocking
     */
    function increaseUnlockTime(uint duration)
        external
        override
        nonReentrant
    {
        LockedBalance memory _locked = locked[msg.sender];
        require(_locked.amount > 0, "VE: LOCK_NOT_FOUND");
        require(_locked.end > block.timestamp, "VE: LOCK_EXPIRED");

        uint unlock_time = ((_locked.end + duration) / interval) * interval; // Locktime is rounded down to a multiple of interval
        require(unlock_time >= _locked.end + interval, "VE: UNLOCK_TIME_TOO_EARLY");
        require(unlock_time <= block.timestamp + maxDuration, "VE: UNLOCK_TIME_TOO_LATE");

        _depositFor(msg.sender, 0, unlock_time, _locked, INCREASE_UNLOCK_TIME);
    }

    /**
     * @notice Withdraw all tokens for `msg.sender`
     * @dev Only possible if the lock has expired
     */
    function withdraw() external override nonReentrant {
        LockedBalance memory _locked = locked[msg.sender];
        require(block.timestamp >= _locked.end, "VE: LOCK_NOT_EXPIRED");

        uint supply_before = _clear(_locked);

        uint amount = _locked.amount.toUint256();

        if (amount > 0) {
            uint ppieAmount = PTokenInterface(registry.pPIE()).balanceOf(address(this)) * amount / supply_before;
            IERC20(registry.pPIE()).safeTransfer(msg.sender, ppieAmount);
        }

        emit Withdraw(msg.sender, amount, block.timestamp);
        emit Supply(supply_before, supply_before - amount);
    }

    function _clear(LockedBalance memory _locked) internal returns (uint) {
        uint amount = _locked.amount.toUint256();

        locked[msg.sender] = LockedBalance(0, 0, 0);
        uint supply_before = supply;
        supply = supply_before - amount;

        // old_locked can have either expired <= timestamp or zero end
        // _locked has only 0 end
        // Both can have >= 0 amount
        _checkpoint(msg.sender, _locked, LockedBalance(0, 0, 0));

        delete delegateAt[msg.sender];

        return supply_before;
    }

    // The following ERC20/min-compatible methods are not real balanceOf and supply!
    // They measure the weights for the purpose of voting, so they don't represent
    // real coins.

    /**
     * @notice Binary search to estimate timestamp for block number
     * @param blockNumber Block to find
     * @param max_epoch Don't go beyond this epoch
     * @return Approximate timestamp for block
     */
    function _findBlockEpoch(uint blockNumber, uint max_epoch) internal view returns (uint) {
        uint _min;
        uint _max = max_epoch;
        for (uint i = 0; i < 128; i++) {
            if (_min >= _max) {
                break;
            }
            uint _mid = (_min + _max + 1) / 2;
            if (pointHistory[_mid].blk <= blockNumber) {
                _min = _mid;
            } else {
                _max = _mid - 1;
            }
        }

        return _min;
    }

    function balanceOf(address user) public view override returns (uint) {
        return balanceOf(user, block.timestamp);
    }

    /**
     * @notice Get the current voting power for `msg.sender`
     * @dev Adheres to the ERC20 `balanceOf` interface for Aragon compatibility
     * @param user User wallet address
     * @param _t Epoch time to return voting power at
     * @return User voting power
     */
    function balanceOf(address user, uint _t) public view override returns (uint) {
        uint _epoch = userPointEpoch[user];
        if (_epoch == 0) {
            return 0;
        } else {
            Point memory last_point = userPointHistory[user][_epoch];
            last_point.bias -= last_point.slope * (_t - last_point.ts).toInt128();
            if (last_point.bias < 0) {
                last_point.bias = 0;
            }

            return last_point.bias.toUint256();
        }
    }

    /**
     * @notice Measure voting power of user at block height `_block`
     * @dev Adheres to MiniMe `balanceOfAt` interface: https://github.com/Giveth/minime
     * @param user User's wallet address
     * @param blockNumber Block to calculate the voting power at
     * @return Voting power
     */
    function balanceOfAt(address user, uint blockNumber) external view override returns (uint) {
        require(blockNumber <= block.number, "VE: INVALID_VALUE");

        return balanceOfAtInternal(user, blockNumber);
    }

    function balanceOfAtInternal(address user, uint blockNumber) internal view returns (uint) {
        // Binary search
        uint _min;
        uint _max = userPointEpoch[user];
        for (uint i = 0; i < 128; i++) {
            if (_min >= _max) {
                break;
            }
            uint _mid = (_min + _max + 1) / 2;
            if (userPointHistory[user][_mid].blk <= blockNumber) {
                _min = _mid;
            } else {
                _max = _mid - 1;
            }
        }

        Point memory upoint = userPointHistory[user][_min];

        uint max_epoch = epoch;
        uint _epoch = _findBlockEpoch(blockNumber, max_epoch);
        Point memory point_0 = pointHistory[_epoch];
        uint d_block;
        uint d_t;
        if (_epoch < max_epoch) {
            Point memory point_1 = pointHistory[_epoch + 1];
            d_block = point_1.blk - point_0.blk;
            d_t = point_1.ts - point_0.ts;
        } else {
            d_block = block.number - point_0.blk;
            d_t = block.timestamp - point_0.ts;
        }
        uint block_time = point_0.ts;
        if (d_block != 0) {
            block_time += ((d_t * (blockNumber - point_0.blk)) / d_block);
        }

        upoint.bias -= upoint.slope * (block_time - upoint.ts).toInt128();
        if (upoint.bias >= 0) {
            return upoint.bias.toUint256();
        } else {
            return 0;
        }
    }

    /**
     * @notice Calculate total voting power at some point in the past
     * @param point The point (bias/slope) to start search from
     * @param t Time to calculate the total voting power at
     * @return Total voting power at that time
     */
    function _supplyAt(Point memory point, uint t) internal view returns (uint) {
        Point memory last_point = point;
        uint t_i = (last_point.ts / interval) * interval;
        for (uint i = 0; i < 255; i++) {
            t_i += interval;
            int128 d_slope;
            if (t_i > t) {
                t_i = t;
            } else {
                d_slope = slopeChanges[t_i];
            }
            last_point.bias -= last_point.slope * (t_i - last_point.ts).toInt128();
            if (t_i == t) {
                break;
            }
            last_point.slope += d_slope;
            last_point.ts = t_i;
        }

        if (last_point.bias < 0) {
            last_point.bias = 0;
        }

        return last_point.bias.toUint256();
    }

    function totalSupply() public view override returns (uint) {
        return totalSupply(block.timestamp);
    }

    /**
     * @notice Calculate total voting power
     * @dev Adheres to the ERC20 `totalSupply` interface for Aragon compatibility
     * @return Total voting power
     */
    function totalSupply(uint t) public view override returns (uint) {
        Point memory last_point = pointHistory[epoch];

        return _supplyAt(last_point, t);
    }

    /**
     * @notice Calculate total voting power at some point in the past
     * @param blockNumber Block to calculate the total voting power at
     * @return Total voting power at `_block`
     */
    function totalSupplyAt(uint blockNumber) external view override returns (uint) {
        require(blockNumber <= block.number, "VE: INVALID_VALUE");

        uint _epoch = epoch;
        uint target_epoch = _findBlockEpoch(blockNumber, _epoch);

        Point memory point = pointHistory[target_epoch];
        uint dt;
        if (target_epoch < _epoch) {
            Point memory point_next = pointHistory[target_epoch + 1];
            if (point.blk != point_next.blk) {
                dt = ((blockNumber - point.blk) * (point_next.ts - point.ts)) / (point_next.blk - point.blk);
            }
        } else if (point.blk != block.number) {
            dt = ((blockNumber - point.blk) * (block.timestamp - point.ts)) / (block.number - point.blk);
        }

        // Now dt contains info on how far are we beyond point
        return _supplyAt(point, point.ts + dt);
    }

    /**
     * @notice Determine the prior number of votes for an user as of a block number
     * @dev Block number must be a finalized block or else this function will revert to prevent misinformation.
     * @param user The address of the user to check
     * @param blockNumber The block number to get the vote balance at
     * @return The number of votes the account had as of the given block
     */
    function getPriorVotes(address user, uint blockNumber) external view returns (uint) {
        require(blockNumber < block.number, "VE: INVALID_VALUE");


        uint votesAmount = 0;
        if(delegateOf[user] == address(0)) {
            votesAmount = balanceOfAtInternal(user, blockNumber);
        }

        for(uint i = 0; i < delegateAt[user].length;) {
            votesAmount += balanceOfAtInternal(delegateAt[user][i], blockNumber);

            unchecked {
                ++i;
            }
        }

        return votesAmount;
    }

    /**
     * @notice Set max duration (admin only)
     * @param newMaxDuration New max duration in sec (rounded down to a multiple of interval)
     */
    function setMaxDuration(uint newMaxDuration) external {
        require(msg.sender == getAdmin(), "VE: Only admin");
        require(newMaxDuration >= minDuration, "VE: Cannot be less than min time");
        require(newMaxDuration <= maxDuration, "VE: Cannot exceed max time");
        
        uint oldMaxDuration = maxDuration;
        maxDuration = (newMaxDuration / interval) * interval;

        emit NewMaxDuration(oldMaxDuration, maxDuration);
    }

    /**
     * @notice Set min duration (admin only)
     * @param newMinDuration New max duration in sec (rounded down to a multiple of interval)
     */
    function setMinDuration(uint newMinDuration) external {
        require(msg.sender == getAdmin(), "VE: Only admin");

        uint oldMinDuration = minDuration;
        minDuration = (newMinDuration / interval) * interval;

        emit NewMinDuration(oldMinDuration, minDuration);
    }

    /**
     * @notice Set min lock amount for users (admin only)
     * @param newMinLockAmount Min token amount for create lock
     */
    function setMinLockAmount(uint newMinLockAmount) external {
        require(msg.sender == getAdmin(), "VE: Only admin");

        uint oldMinLockAmount = minLockAmount;
        minLockAmount = newMinLockAmount;

        emit NewMinLockAmount(oldMinLockAmount, newMinLockAmount);
    }

    /**
     * @notice Get admin address from registry
     * @return Admin address from registry
     */
    function getAdmin() public view virtual returns (address) {
        return registry.admin();
    }

    /**
     * @notice Add address to whitelist
     * @param account Address (user or contract)
     */
    function addWhiteList(address account) public {
        require(msg.sender == getAdmin() || msg.sender == governor.guardian(), "VE: Only admin or governance guardian");

        isWhiteListed[account] = true;

        emit AddedWhiteList(account);
    }

    /**
     * @notice Remove address from whitelist
     * @param account Address (user or contract)
     */
    function removeWhiteList(address account) public {
        require(msg.sender == getAdmin() || msg.sender == governor.guardian(), "VE: Only admin or governance guardian");

        isWhiteListed[account] = false;

        emit RemovedWhiteList(account);
    }

    /**
     * @notice Check whitelist for address
     * @param account Account address (user or contract)
     * @return Bool Result (true or false)
     */
    function getWhiteListStatus(address account) public view returns (bool) {
        return isWhiteListed[account];
    }

    function getDelegators(address user) public view returns (address[] memory) {
        return delegateAt[user];
    }

    function getDelegate(address delegator) public view returns (address) {
        return delegateOf[delegator];
    }

    function depositPie(uint amount) external {
        require(msg.sender == getAdmin() || msg.sender == controller, "VE: Only admin or controller");

        PErc20Interface(registry.pPIE()).mint(amount);
    }

    function _setController(address newController) external {
        require(msg.sender == getAdmin(), "VE: Only admin");

        controller = newController;
    }

    function _approvePIE() external {
        require(msg.sender == getAdmin(), "VE: Only admin");

        IERC20(token).approve(registry.pPIE(), type(uint256).max);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import '../Registry.sol';
import './VotingEscrow.sol';

contract Governor {
    /// @notice The name of this contract
    string public constant name = "DeFiPie Governor";

    uint public threshold = 600_000e18; // 600K PIE
    uint public quorum = 6_000_000e18; // 6M PIE
    uint public delay = 1; // 1 block

    uint public period;

    /// @notice The number of votes in support of a proposal required in order for a quorum to be reached and for a vote to succeed
    function quorumVotes() public view returns (uint) { return quorum; }

    /// @notice The number of votes required in order for a voter to become a proposer
    function proposalThreshold() public view returns (uint) { return threshold; }

    /// @notice The maximum number of actions that can be included in a proposal
    function proposalMaxOperations() public pure returns (uint) { return 10; } // 10 actions

    /// @notice The delay before voting on a proposal may take place, once proposed
    function votingDelay() public view returns (uint) { return delay; }

    /// @notice The duration of voting on a proposal, in blocks
    function votingPeriod() public view virtual returns (uint) { return period; }

    /// @notice The address of the DeFiPie Protocol Timelock
    TimelockInterface public timelock;

    /// @notice The address of the Registry
    Registry public registry;

    /// @notice The address of the VotingEscrow
    VotingEscrow public votingEscrow;

    /// @notice The address of the Governor Guardian
    address public guardian;

    /// @notice The total number of proposals
    uint public proposalCount;

    /// @notice id Unique id for looking up a proposal
    /// @notice proposer Creator of the proposal
    /// @notice eta The timestamp that the proposal will be available for execution, set once the vote succeeds
    /// @notice targets the ordered list of target addresses for calls to be made
    /// @notice values The ordered list of values (i.e. msg.value) to be passed to the calls to be made
    /// @notice signatures The ordered list of function signatures to be called
    /// @notice calldatas The ordered list of calldata to be passed to each call
    /// @notice startBlock The block at which voting begins: holders must delegate their votes prior to this block
    /// @notice endBlock The block at which voting ends: votes must be cast prior to this block
    /// @notice forVotes Current number of votes in favor of this proposal
    /// @notice againstVotes Current number of votes in opposition to this proposal
    /// @notice canceled Flag marking whether the proposal has been canceled
    /// @notice executed Flag marking whether the proposal has been executed
    /// @notice receipts Receipts of ballots for the entire set of voters

    struct Proposal {
        uint id;
        address proposer;
        uint eta;
        address[] targets;
        uint[] values;
        string[] signatures;
        bytes[] calldatas;
        uint startBlock;
        uint endBlock;
        uint forVotes;
        uint againstVotes;
        bool canceled;
        bool executed;
        mapping (address => Receipt) receipts;
    }

    /// @notice Ballot receipt record for a voter
    /// @notice hasVoted Whether or not a vote has been cast
    /// @notice support Whether or not the voter supports the proposal
    /// @notice votes The number of votes the voter had, which were cast

    struct Receipt {
        bool hasVoted;
        bool support;
        uint96 votes;
    }

    /// @notice Possible states that a proposal may be in
    enum ProposalState {
        Pending,
        Active,
        Canceled,
        Defeated,
        Succeeded,
        Queued,
        Expired,
        Executed
    }

    /// @notice The official record of all proposals ever proposed
    mapping (uint => Proposal) public proposals;

    /// @notice The latest proposal for each proposer
    mapping (address => uint) public latestProposalIds;

    /// @notice The EIP-712 typehash for the contract's domain
    bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");

    /// @notice The EIP-712 typehash for the ballot struct used by the contract
    bytes32 public constant BALLOT_TYPEHASH = keccak256("Ballot(uint256 proposalId,bool support)");

    /// @notice An event emitted when a new proposal is created
    event ProposalCreated(
        uint id,
        address proposer,
        address[] targets,
        uint[] values,
        string[] signatures,
        bytes[] calldatas,
        uint startBlock,
        uint endBlock,
        string description
    );

    /// @notice An event emitted when a vote has been cast on a proposal
    event VoteCast(address voter, uint proposalId, bool support, uint votes);

    /// @notice An event emitted when a proposal has been canceled
    event ProposalCanceled(uint id);

    /// @notice An event emitted when a proposal has been queued in the Timelock
    event ProposalQueued(uint id, uint eta);

    /// @notice An event emitted when a proposal has been executed in the Timelock
    event ProposalExecuted(uint id);

    event NewQuorum(uint indexed newQuorum);
    event NewThreshold(uint indexed newThreshold);
    event NewVotingDelay(uint indexed newVotingDelay);
    event NewVotingPeriod(uint indexed newVotingPeriod);

    constructor(address timelock_, address registry_, address guardian_, uint period_) {
        timelock = TimelockInterface(timelock_);
        registry = Registry(registry_);
        guardian = guardian_;
        period = period_;
    }

    function setVotingEscrow(address _votingEscrow) public {
        require(msg.sender == guardian, "Governor::setVotingEscrow: only guardian");

        votingEscrow = VotingEscrow(_votingEscrow);
    }

    function propose(
        address[] memory targets,
        uint[] memory values,
        string[] memory signatures,
        bytes[] memory calldatas,
        string memory description
    ) public returns (uint) {
        require(votingEscrow.getPriorVotes(msg.sender, sub256(block.number, 1)) > proposalThreshold(), "Governor::propose: proposer votes below proposal threshold");
        require(targets.length == values.length && targets.length == signatures.length && targets.length == calldatas.length, "Governor::propose: proposal function information parity mismatch");
        require(targets.length != 0, "Governor::propose: must provide actions");
        require(targets.length <= proposalMaxOperations(), "Governor::propose: too many actions");
        

        uint latestProposalId = latestProposalIds[msg.sender];
        if (latestProposalId != 0) {
            ProposalState proposersLatestProposalState = state(latestProposalId);
            require(proposersLatestProposalState != ProposalState.Active, "Governor::propose: one live proposal per proposer, found an already active proposal");
            require(proposersLatestProposalState != ProposalState.Pending, "Governor::propose: one live proposal per proposer, found an already pending proposal");
        }

        uint startBlock = add256(block.number, votingDelay());
        uint endBlock = add256(startBlock, votingPeriod());

        proposalCount++;
        Proposal storage newProposal = proposals[proposalCount];
        newProposal.id = proposalCount;
        newProposal.proposer = msg.sender;
        newProposal.targets = targets;
        newProposal.values = values;
        newProposal.signatures = signatures;
        newProposal.calldatas = calldatas;
        newProposal.startBlock = startBlock;
        newProposal.endBlock = endBlock;

        latestProposalIds[newProposal.proposer] = newProposal.id;

        emit ProposalCreated(newProposal.id, msg.sender, targets, values, signatures, calldatas, startBlock, endBlock, description);
        return newProposal.id;
    }

    function queue(uint proposalId) public {
        require(state(proposalId) == ProposalState.Succeeded, "Governor::queue: proposal can only be queued if it is succeeded");
        Proposal storage proposal = proposals[proposalId];
        uint eta = add256(block.timestamp, timelock.delay());
        for (uint i = 0; i < proposal.targets.length; i++) {
            _queueOrRevert(proposal.targets[i], proposal.values[i], proposal.signatures[i], proposal.calldatas[i], eta);
        }
        proposal.eta = eta;
        emit ProposalQueued(proposalId, eta);
    }

    function _queueOrRevert(address target, uint value, string memory signature, bytes memory data, uint eta) internal {
        require(!timelock.queuedTransactions(keccak256(abi.encode(target, value, signature, data, eta))), "Governor::_queueOrRevert: proposal action already queued at eta");
        timelock.queueTransaction(target, value, signature, data, eta);
    }

    function execute(uint proposalId) public payable {
        require(state(proposalId) == ProposalState.Queued, "Governor::execute: proposal can only be executed if it is queued");
        Proposal storage proposal = proposals[proposalId];
        proposal.executed = true;
        for (uint i = 0; i < proposal.targets.length; i++) {
            timelock.executeTransaction{value: proposal.values[i]}(proposal.targets[i], proposal.values[i], proposal.signatures[i], proposal.calldatas[i], proposal.eta);
        }
        emit ProposalExecuted(proposalId);
    }

    function cancel(uint proposalId) public {
        ProposalState state_ = state(proposalId);
        require(state_ != ProposalState.Executed, "Governor::cancel: cannot cancel executed proposal");

        Proposal storage proposal = proposals[proposalId];
        require(msg.sender == guardian || votingEscrow.getPriorVotes(proposal.proposer, sub256(block.number, 1)) < proposalThreshold(), "Governor::cancel: proposer above threshold");

        proposal.canceled = true;
        for (uint i = 0; i < proposal.targets.length; i++) {
            timelock.cancelTransaction(proposal.targets[i], proposal.values[i], proposal.signatures[i], proposal.calldatas[i], proposal.eta);
        }

        emit ProposalCanceled(proposalId);
    }

    function getActions(
        uint proposalId
    ) public view returns (
        address[] memory targets,
        uint[] memory values,
        string[] memory signatures,
        bytes[] memory calldatas
    ) {
        Proposal storage p = proposals[proposalId];
        return (p.targets, p.values, p.signatures, p.calldatas);
    }

    function getReceipt(uint proposalId, address voter) public view returns (Receipt memory) {
        return proposals[proposalId].receipts[voter];
    }

    function getForVotes(uint proposalId) public view returns (uint) {
        return proposals[proposalId].forVotes;
    }

    function state(uint proposalId) public view returns (ProposalState) {
        require(proposalCount >= proposalId && proposalId > 0, "Governor::state: invalid proposal id");
        Proposal storage proposal = proposals[proposalId];
        if (proposal.canceled) {
            return ProposalState.Canceled;
        } else if (block.number <= proposal.startBlock) {
            return ProposalState.Pending;
        } else if (block.number <= proposal.endBlock) {
            return ProposalState.Active;
        } else if (proposal.forVotes <= proposal.againstVotes || proposal.forVotes < quorumVotes()) {
            return ProposalState.Defeated;
        } else if (proposal.eta == 0) {
            return ProposalState.Succeeded;
        } else if (proposal.executed) {
            return ProposalState.Executed;
        } else if (block.timestamp >= add256(proposal.eta, timelock.GRACE_PERIOD())) {
            return ProposalState.Expired;
        } else {
            return ProposalState.Queued;
        }
    }

    function castVote(uint proposalId, bool support) public {
        _castVote(msg.sender, proposalId, support);
    }

    function castVoteBySig(uint proposalId, bool support, uint8 v, bytes32 r, bytes32 s) public {
        bytes32 domainSeparator = keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name)), getChainId(), address(this)));
        bytes32 structHash = keccak256(abi.encode(BALLOT_TYPEHASH, proposalId, support));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
        address signatory = ecrecover(digest, v, r, s);
        require(signatory != address(0), "Governor::castVoteBySig: invalid signature");
        _castVote(signatory, proposalId, support);
    }

    function _castVote(address voter, uint proposalId, bool support) internal {
        require(state(proposalId) == ProposalState.Active, "Governor::_castVote: voting is closed");
        Proposal storage proposal = proposals[proposalId];
        Receipt storage receipt = proposal.receipts[voter];
        require(receipt.hasVoted == false, "Governor::_castVote: voter already voted");
        uint96 votes = uint96(votingEscrow.getPriorVotes(voter, proposal.startBlock));

        if (support) {
            proposal.forVotes = add256(proposal.forVotes, votes);
        } else {
            proposal.againstVotes = add256(proposal.againstVotes, votes);
        }

        receipt.hasVoted = true;
        receipt.support = support;
        receipt.votes = votes;

        emit VoteCast(voter, proposalId, support, votes);
    }

    function setQuorum(uint newQuorum) external {
        require(msg.sender == guardian, "Governor::setQuorum: sender must be gov guardian");
        quorum = newQuorum;

        emit NewQuorum(newQuorum);
    }

    function setThreshold(uint newThreshold) external {
        require(msg.sender == guardian, "Governor::setThreshold: sender must be gov guardian");
        threshold = newThreshold;

        emit NewThreshold(newThreshold);
    }

    function setVotingDelay(uint newVotingDelay) external {
        require(msg.sender == guardian, "Governor::setVotingDelay: sender must be gov guardian");
        delay = newVotingDelay;

        emit NewVotingDelay(newVotingDelay);
    }

    function setVotingPeriod(uint newVotingPeriod) external {
        require(msg.sender == guardian, "Governor::setVotingPeriod: sender must be gov guardian");
        period = newVotingPeriod;

        emit NewVotingPeriod(newVotingPeriod);
    }

    function __acceptAdmin() public {
        require(msg.sender == guardian, "Governor::__acceptAdmin: sender must be gov guardian");
        timelock.acceptAdmin();
    }

    function __abdicate() public {
        require(msg.sender == guardian, "Governor::__abdicate: sender must be gov guardian");
        guardian = address(0);
    }

    function __queueSetTimelockPendingAdmin(address newPendingAdmin, uint eta) public {
        require(msg.sender == guardian, "Governor::__queueSetTimelockPendingAdmin: sender must be gov guardian");
        timelock.queueTransaction(address(timelock), 0, "setPendingAdmin(address)", abi.encode(newPendingAdmin), eta);
    }

    function __executeSetTimelockPendingAdmin(address newPendingAdmin, uint eta) public {
        require(msg.sender == guardian, "Governor::__executeSetTimelockPendingAdmin: sender must be gov guardian");
        timelock.executeTransaction(address(timelock), 0, "setPendingAdmin(address)", abi.encode(newPendingAdmin), eta);
    }

    function add256(uint256 a, uint256 b) internal pure returns (uint) {
        unchecked {
            uint c = a + b;
            require(c >= a, "addition overflow");
            return c;
        }
    }

    function sub256(uint256 a, uint256 b) internal pure returns (uint) {
        require(b <= a, "subtraction underflow");
        return a - b;
    }

    function getChainId() internal view returns (uint) {
        uint chainId;
        assembly { chainId := chainid() }
        return chainId;
    }
}

interface TimelockInterface {
    function delay() external view returns (uint);
    function GRACE_PERIOD() external view returns (uint);
    function acceptAdmin() external;
    function queuedTransactions(bytes32 hash) external view returns (bool);
    function queueTransaction(address target, uint value, string calldata signature, bytes calldata data, uint eta) external returns (bytes32);
    function cancelTransaction(address target, uint value, string calldata signature, bytes calldata data, uint eta) external;
    function executeTransaction(address target, uint value, string calldata signature, bytes calldata data, uint eta) external payable returns (bytes memory);
}

interface PPieInterface {
    function getPriorVotes(address account, uint blockNumber) external view returns (uint96);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./Tokens/PTokenInterfaces.sol";
import './RegistryStorage.sol';
import "./ErrorReporter.sol";
import "./Control/Controller.sol";
import "./PTokenFactory.sol";

contract Registry is RegistryStorage, RegistryErrorReporter {

    address public factory;
    address public pTokenImplementation;
    address public oracle;

    mapping (address => address) public pTokens;
    address public pETH;
    address public pPIE;

    /*** Admin Events ***/

    /**
      * @notice Emitted when PTokenImplementation is changed
      */
    event NewPTokenImplementation(address oldImplementation, address newImplementation);

    /**
      * @notice Emitted when Factory address is changed
      */
    event NewFactory(address oldFactory, address newFactory);

    /**
      * @notice Emitted when Oracle address is changed
      */
    event NewOracle(address oldOracle, address newOracle);

    /**
      * @notice Emitted when admin remove pToken
      */
    event RemovePToken(address pToken);

    constructor() {}

    function initialize(address _pTokenImplementation) public {
        require(pTokenImplementation == address(0), "Registry may only be initialized once");

        pTokenImplementation = _pTokenImplementation;
    }

    /**
     *  Sets address of actual pToken implementation contract
     *  @return uint 0 = success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function _setPTokenImplementation(address newImplementation) external returns (uint) {
        if (msg.sender != admin) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SET_NEW_IMPLEMENTATION);
        }

        address oldImplementation = pTokenImplementation;
        pTokenImplementation = newImplementation;

        emit NewPTokenImplementation(oldImplementation, pTokenImplementation);

        return(uint(Error.NO_ERROR));
    }

    function _setFactoryContract(address _factory) external returns (uint) {
        if (msg.sender != admin) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SET_NEW_FACTORY);
        }

        address oldFactory = factory;
        factory = _factory;

        emit NewFactory(oldFactory, factory);

        return uint(Error.NO_ERROR);
    }

    function _setOracle(address _oracle) public returns (uint) {
        if (msg.sender != admin) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SET_NEW_ORACLE);
        }

        address oldOracle = oracle;
        oracle = _oracle;

        emit NewOracle(oldOracle, oracle);

        return uint(Error.NO_ERROR);
    }

    function addPToken(address underlying, address pToken) public returns (uint) {
        require(msg.sender == admin || msg.sender == factory, "Only admin or factory can add PTokens");

        PTokenInterface(pToken).isPToken(); // Sanity check to make sure its really a PToken

        require(pTokens[underlying] == address(0), "Token already added");
        pTokens[underlying] = pToken;

        return uint(Error.NO_ERROR);
    }

    function addPETH(address pETH_) public returns (uint) {
        require(msg.sender == admin || msg.sender == factory, "Only admin or factory can add PETH");

        PTokenInterface(pETH_).isPToken(); // Sanity check to make sure its really a PToken

        require(pETH == address(0), "ETH already added");
        pETH = pETH_;

        return uint(Error.NO_ERROR);
    }

    function addPPIE(address pPIE_) public returns (uint) {
        require(msg.sender == admin || msg.sender == factory, "Only admin or factory can add PPIE");

        PTokenInterface(pPIE_).isPToken(); // Sanity check to make sure its really a PToken

        require(pPIE == address(0), "PIE already added");
        pPIE = pPIE_;

        address underlying = PErc20Storage(pPIE).underlying();
        pTokens[underlying] = pPIE;

        return uint(Error.NO_ERROR);
    }

    function _removePToken(address pToken) public returns (uint) {
        require(msg.sender == admin, "Only admin can remove PTokens");

        PTokenInterface(pToken).isPToken(); // Sanity check to make sure its really a PToken

        address underlying = PErc20Storage(pToken).underlying();
        require(pTokens[underlying] != address(0), "Token not added");
        delete pTokens[underlying];

        emit RemovePToken(pToken);

        return uint(Error.NO_ERROR);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "../Control/ControllerInterface.sol";
import "../Models/InterestRateModel.sol";
import "../ProxyWithRegistry.sol";

contract PTokenStorage is ProxyWithRegistryStorage {
    /**
     * @dev Guard variable for re-entrancy checks
     */
    bool internal _notEntered;

    /**
     * @notice EIP-20 token name for this token
     */
    string public name;

    /**
     * @notice EIP-20 token symbol for this token
     */
    string public symbol;

    /**
     * @notice EIP-20 token decimals for this token
     */
    uint8 public decimals;

    /**
     * @dev Maximum borrow rate that can ever be applied (.0005% / block)
     */

    uint internal constant borrowRateMaxMantissa = 0.0005e16;

    /**
     * @dev Maximum fraction of interest that can be set aside for reserves
     */
    uint internal constant reserveFactorMaxMantissa = 1e18;

    /**
     * @notice Contract which oversees inter-pToken operations
     */
    ControllerInterface public controller;

    /**
     * @notice Model which tells what the current interest rate should be
     */
    InterestRateModel public interestRateModel;

    /**
     * @dev Initial exchange rate used when minting the first PTokens (used when totalSupply = 0)
     */
    uint internal initialExchangeRateMantissa;

    /**
     * @notice Fraction of interest currently set aside for reserves
     */
    uint public reserveFactorMantissa;

    /**
     * @notice Block number that interest was last accrued at
     */
    uint public accrualBlockNumber;

    /**
     * @notice Accumulator of the total earned interest rate since the opening of the market
     */
    uint public borrowIndex;

    /**
     * @notice Total amount of outstanding borrows of the underlying in this market
     */
    uint public totalBorrows;

    /**
     * @notice Total amount of reserves of the underlying held in this market
     */
    uint public totalReserves;

    /**
     * @notice Total number of tokens in circulation
     */
    uint public totalSupply;

    /**
     * @dev Official record of token balances for each account
     */
    mapping (address => uint) internal accountTokens;

    /**
     * @dev Approved token transfer amounts on behalf of others
     */
    mapping (address => mapping (address => uint)) internal transferAllowances;

    /**
     * @notice Container for borrow balance information
     * @member principal Total balance (with accrued interest), after applying the most recent balance-changing action
     * @member interestIndex Global borrowIndex as of the most recent balance-changing action
     */
    struct BorrowSnapshot {
        uint principal;
        uint interestIndex;
    }

    /**
     * @dev Mapping of account addresses to outstanding borrow balances
     */
    mapping(address => BorrowSnapshot) internal accountBorrows;
}

abstract contract PTokenInterface is PTokenStorage {
    /**
     * @notice Indicator that this is a PToken contract (for inspection)
     */
    bool public constant isPToken = true;


    /*** Market Events ***/

    /**
     * @notice Event emitted when interest is accrued
     */
    event AccrueInterest(uint cashPrior, uint interestAccumulated, uint borrowIndex, uint totalBorrows, uint totalReserves);

    /**
     * @notice Event emitted when tokens are minted
     */
    event Mint(address minter, uint mintAmount, uint mintTokens);

    /**
     * @notice Event emitted when tokens are redeemed
     */
    event Redeem(address redeemer, uint redeemAmount, uint redeemTokens);

    /**
     * @notice Event emitted when underlying is borrowed
     */
    event Borrow(address borrower, uint borrowAmount, uint accountBorrows, uint totalBorrows);

    /**
     * @notice Event emitted when a borrow is repaid
     */
    event RepayBorrow(address payer, address borrower, uint repayAmount, uint accountBorrows, uint totalBorrows);

    /**
     * @notice Event emitted when a borrow is liquidated
     */
    event LiquidateBorrow(address liquidator, address borrower, uint repayAmount, address pTokenCollateral, uint seizeTokens);


    /*** Admin Events ***/

    /**
     * @notice Event emitted when controller is changed
     */
    event NewController(ControllerInterface oldController, ControllerInterface newController);

    /**
     * @notice Event emitted when interestRateModel is changed
     */
    event NewMarketInterestRateModel(InterestRateModel oldInterestRateModel, InterestRateModel newInterestRateModel);

    /**
     * @notice Event emitted when the reserve factor is changed
     */
    event NewReserveFactor(uint oldReserveFactorMantissa, uint newReserveFactorMantissa);

    /**
     * @notice Event emitted when the reserves are added
     */
    event ReservesAdded(address benefactor, uint addAmount, uint newTotalReserves);

    /**
     * @notice Event emitted when the reserves are reduced
     */
    event ReservesReduced(address admin, uint reduceAmount, uint newTotalReserves);

    /**
     * @notice EIP20 Transfer event
     */
    event Transfer(address indexed from, address indexed to, uint amount);

    /**
     * @notice EIP20 Approval event
     */
    event Approval(address indexed owner, address indexed spender, uint amount);

    /*** User Interface ***/

    function transfer(address dst, uint amount) external virtual returns (bool);
    function transferFrom(address src, address dst, uint amount) external virtual returns (bool);
    function approve(address spender, uint amount) external virtual returns (bool);
    function allowance(address owner, address spender) external view virtual returns (uint);
    function balanceOf(address owner) external view virtual returns (uint);
    function balanceOfUnderlying(address owner) external virtual returns (uint);
    function getAccountSnapshot(address account) external view virtual returns (uint, uint, uint, uint);
    function borrowRatePerBlock() external view virtual returns (uint);
    function supplyRatePerBlock() external view virtual returns (uint);
    function totalBorrowsCurrent() external virtual returns (uint);
    function borrowBalanceCurrent(address account) external virtual returns (uint);
    function borrowBalanceStored(address account) public view virtual returns (uint);
    function exchangeRateCurrent() public virtual returns (uint);
    function exchangeRateStored() public view virtual returns (uint);
    function getCash() external view virtual returns (uint);
    function accrueInterest() public virtual returns (uint);
    function seize(address liquidator, address borrower, uint seizeTokens) external virtual returns (uint);

    /*** Admin Functions ***/

    function _setController(ControllerInterface newController) public virtual returns (uint);
    function _setReserveFactor(uint newReserveFactorMantissa) external virtual returns (uint);
    function _reduceReserves(uint reduceAmount) external virtual returns (uint);
    function _setInterestRateModel(InterestRateModel newInterestRateModel) public virtual returns (uint);
}

contract PErc20Storage {
    /**
     * @notice Underlying asset for this PToken
     */
    address public underlying;
}

abstract contract PErc20Interface is PErc20Storage {

    /*** User Interface ***/

    function mint(uint mintAmount) external virtual returns (uint);
    function redeem(uint redeemTokens) external virtual returns (uint);
    function redeemUnderlying(uint redeemAmount) external virtual returns (uint);
    function borrow(uint borrowAmount) external virtual returns (uint);
    function repayBorrow(uint repayAmount) external virtual returns (uint);
    function repayBorrowBehalf(address borrower, uint repayAmount) external virtual returns (uint);
    function liquidateBorrow(address borrower, uint repayAmount, PTokenInterface pTokenCollateral) external virtual returns (uint);

    /*** Admin Functions ***/

    function _addReserves(uint addAmount) external virtual returns (uint);
}

contract PEer20ExtStorage {
    /**
     * @notice start borrow timestamp
     */
    uint public startBorrowTimestamp;
}

abstract contract PErc20ExtInterface is PEer20ExtStorage {

}


contract PPIEStorage {
    /// @notice A record of each accounts delegate
    mapping (address => address) public delegates;

    /// @notice A checkpoint for marking number of votes from a given block
    struct Checkpoint {
        uint32 fromBlock;
        uint96 votes;
    }

    /// @notice A record of votes checkpoints for each account, by index
    mapping (address => mapping (uint32 => Checkpoint)) public checkpoints;

    /// @notice The number of checkpoints for each account
    mapping (address => uint32) public numCheckpoints;

    /// @notice The EIP-712 typehash for the contract's domain
    bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");

    /// @notice The EIP-712 typehash for the delegation struct used by the contract
    bytes32 public constant DELEGATION_TYPEHASH = keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");

    /// @notice A record of states for signing / validating signatures
    mapping (address => uint) public nonces;
}

abstract contract PPIEInterface is PPIEStorage {
    /// @notice An event thats emitted when an account changes its delegate
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

    /// @notice An event thats emitted when a delegate account's vote balance changes
    event DelegateVotesChanged(address indexed delegate, uint previousBalance, uint newBalance);

    function delegate(address delegatee) external virtual;
    function delegateBySig(address delegatee, uint nonce, uint expiry, uint8 v, bytes32 r, bytes32 s) external virtual;
    function getCurrentVotes(address account) external view virtual returns (uint96);
    function getPriorVotes(address account, uint blockNumber) external view virtual returns (uint96);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

contract RegistryStorage {
    address public implementation;
    address public admin;
    address public pendingAdmin;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "../ErrorReporter.sol";
import "../Exponential.sol";
import "../Oracles/PriceOracle.sol";
import "./ControllerInterface.sol";
import "./ControllerStorage.sol";
import "../Tokens/PTokenInterfaces.sol";
import "../Tokens/EIP20Interface.sol";
import "./Unitroller.sol";
import '../Governance/VotingEscrowImports/IVotingEscrow.sol';

/**
 * @title DeFiPie's Controller Contract
 * @author DeFiPie
 */
contract Controller is ControllerStorage, ControllerInterface, ControllerErrorReporter, Exponential {
    /// @notice Emitted when an admin supports a market
    event MarketListed(address pToken);

    /// @notice Emitted when an account enters a market
    event MarketEntered(address pToken, address account);

    /// @notice Emitted when an account exits a market
    event MarketExited(address pToken, address account);

    /// @notice Emitted when close factor is changed by admin
    event NewCloseFactor(uint oldCloseFactorMantissa, uint newCloseFactorMantissa);

    /// @notice Emitted when a collateral factor is changed by admin
    event NewCollateralFactor(address pToken, uint oldCollateralFactorMantissa, uint newCollateralFactorMantissa);

    /// @notice Event emitted when the fee factor max is changed
    event NewFeeFactorMaxMantissa(uint oldFeeFactorMaxMantissa, uint newFeeFactorMaxMantissa);

    /// @notice Event emitted when the fee factor is changed
    event NewFeeFactor(address pToken, uint oldFeeFactorMantissa, uint newFeeFactorMantissa);

    /// @notice Event emitted when the borrow delay is changed
    event NewBorrowDelay(uint oldBorrowDelay, uint newBorrowDelay);

    /// @notice Emitted when liquidation incentive is changed by admin
    event NewLiquidationIncentive(uint oldLiquidationIncentiveMantissa, uint newLiquidationIncentiveMantissa);

    /// @notice Emitted when maxAssets is changed by admin
    event NewMaxAssets(uint oldMaxAssets, uint newMaxAssets);

    /// @notice Emitted when price oracle is changed
    event NewPriceOracle(PriceOracle oldPriceOracle, PriceOracle newPriceOracle);

    /// @notice Emitted when pause guardian is changed
    event NewPauseGuardian(address oldPauseGuardian, address newPauseGuardian);

    /// @notice Emitted when distributor is changed
    event NewDistributor(address oldDistributor, address newDistributor);

    /// @notice Emitted when pause guardian is changed
    event NewLiquidateGuardian(address oldLiquidateGuardian, address newLiquidateGuardian);

    /// @notice Emitted when an action is paused globally
    event ActionPaused(string action, bool pauseState);

    /// @notice Emitted when an action is paused on a market
    event ActionPaused(address pToken, string action, bool pauseState);

    /// @notice Emitted when an action is transferred moderate reward to pool moderator
    event ModerateUserReward(address pToken, address user, uint unfreezeAmount);

    /// @notice Emitted when an action is transferred moderate amounts to pie pool
    event ModeratePoolReward(uint poolReward);

    /// @notice Emitted when an action is created pool and freeze pool create amount
    event FreezePoolAmount(address pToken, uint createPoolFeeAmount);

    /// @notice Emitted when an action is unfreeze pool create amount
    event UnfreezePoolAmount(address pToken, uint freezePoolAmount);

    /// @notice Event emitted when the moderate data is changed
    event NewUserModeratePoolData(uint oldUserPauseDepositAmount, uint newUserPauseDepositAmount_, uint oldGuardianModerateTime, uint newGuardianModerateTime_);

    // closeFactorMantissa must be strictly greater than this value
    uint internal constant closeFactorMinMantissa = 0.05e18; // 0.05

    // closeFactorMantissa must not exceed this value
    uint internal constant closeFactorMaxMantissa = 0.9e18; // 0.9

    // No collateralFactorMantissa may exceed this value
    uint internal constant collateralFactorMaxMantissa = 0.9e18; // 0.9

    // liquidationIncentiveMantissa must be no less than this value
    uint internal constant liquidationIncentiveMinMantissa = 1.0e18; // 1.0

    // liquidationIncentiveMantissa must be no greater than this value
    uint internal constant liquidationIncentiveMaxMantissa = 1.5e18; // 1.5

    constructor() {}

    /*** Assets You Are In ***/

    /**
     * @notice Returns the assets an account has entered
     * @param account The address of the account to pull assets for
     * @return A dynamic list with the assets the account has entered
     */
    function getAssetsIn(address account) external view returns (address[] memory) {
        address[] memory assetsIn = accountAssets[account];

        return assetsIn;
    }

    /**
     * @notice Returns whether the given account is entered in the given asset
     * @param account The address of the account to check
     * @param pToken The pToken to check
     * @return True if the account is in the asset, otherwise false.
     */
    function checkMembership(address account, address pToken) external view returns (bool) {
        return markets[pToken].accountMembership[account];
    }

    /**
    * @notice Returns whether the market is listed
     * @param pToken The pToken to check
     * @return True if the market is listed, otherwise false.
     */
    function checkIsListed(address pToken) external view override returns (bool) {
        return markets[pToken].isListed;
    }

    /**
     * @notice Add assets to be included in account liquidity calculation
     * @param pTokens The list of addresses of the pToken markets to be enabled
     * @return Success indicator for whether each corresponding market was entered
     */
    function enterMarkets(address[] memory pTokens) public override returns (uint[] memory) {
        uint len = pTokens.length;

        uint[] memory results = new uint[](len);
        for (uint i = 0; i < len; i++) {
            address pToken = pTokens[i];

            results[i] = uint(addToMarketInternal(pToken, msg.sender));
        }

        return results;
    }

    /**
     * @notice Add the market to the borrower's "assets in" for liquidity calculations
     * @param pToken The market to enter
     * @param borrower The address of the account to modify
     * @return Success indicator for whether the market was entered
     */
    function addToMarketInternal(address pToken, address borrower) internal returns (Error) {
        Market storage marketToJoin = markets[pToken];

        if (!marketToJoin.isListed) {
            // market is not listed, cannot join
            return Error.MARKET_NOT_LISTED;
        }

        if (marketToJoin.accountMembership[borrower] == true) {
            // already joined
            return Error.NO_ERROR;
        }

        if (accountAssets[borrower].length >= maxAssets)  {
            // no space, cannot join
            return Error.TOO_MANY_ASSETS;
        }

        // survived the gauntlet, add to list
        // NOTE: we store these somewhat redundantly as a significant optimization
        //  this avoids having to iterate through the list for the most common use cases
        //  that is, only when we need to perform liquidity checks
        //  and not whenever we want to check if an account is in a particular market
        marketToJoin.accountMembership[borrower] = true;
        accountAssets[borrower].push(pToken);

        emit MarketEntered(pToken, borrower);

        return Error.NO_ERROR;
    }

    /**
     * @notice Removes asset from sender's account liquidity calculation
     * @dev Sender must not have an outstanding borrow balance in the asset,
     *  or be providing neccessary collateral for an outstanding borrow.
     * @param pTokenAddress The address of the asset to be removed
     * @return Whether or not the account successfully exited the market
     */
    function exitMarket(address pTokenAddress) external override returns (uint) {
        address pToken = pTokenAddress;
        /* Get sender tokensHeld and amountOwed underlying from the pToken */
        (uint oErr, uint tokensHeld, uint amountOwed, ) = PTokenInterface(pToken).getAccountSnapshot(msg.sender);
        require(oErr == 0, "exitMarket: getAccountSnapshot failed"); // semi-opaque error code

        /* Fail if the sender has a borrow balance */
        if (amountOwed != 0) {
            return fail(Error.NONZERO_BORROW_BALANCE, FailureInfo.EXIT_MARKET_BALANCE_OWED);
        }

        /* Fail if the sender is not permitted to redeem all of their tokens */
        uint allowed = redeemAllowedInternal(pTokenAddress, msg.sender, tokensHeld);
        if (allowed != 0) {
            return failOpaque(Error.REJECTION, FailureInfo.EXIT_MARKET_REJECTION, allowed);
        }

        Market storage marketToExit = markets[pToken];

        /* Return true if the sender is not already ‘in’ the market */
        if (!marketToExit.accountMembership[msg.sender]) {
            return uint(Error.NO_ERROR);
        }

        /* Set pToken account membership to false */
        delete marketToExit.accountMembership[msg.sender];

        /* Delete pToken from the account’s list of assets */
        // load into memory for faster iteration
        address[] memory userAssetList = accountAssets[msg.sender];
        uint len = userAssetList.length;
        uint assetIndex = len;
        for (uint i = 0; i < len; i++) {
            if (userAssetList[i] == pToken) {
                assetIndex = i;
                break;
            }
        }

        // We *must* have found the asset in the list or our redundant data structure is broken
        assert(assetIndex < len);

        // copy last item in list to location of item to be removed, reduce length by 1
        address[] storage storedList = accountAssets[msg.sender];
        storedList[assetIndex] = storedList[storedList.length - 1];
        storedList.pop(); //storedList.length--;

        emit MarketExited(pToken, msg.sender);

        return uint(Error.NO_ERROR);
    }

    /*** Policy Hooks ***/

    /**
     * @notice Checks if the account should be allowed to mint tokens in the given market
     * @param pToken The market to verify the mint against
     * @param minter The account which would get the minted tokens
     * @param mintAmount The amount of underlying being supplied to the market in exchange for tokens
     * @return 0 if the mint is allowed, otherwise a semi-opaque error code (See ErrorReporter.sol)
     */
    function mintAllowed(address pToken, address minter, uint mintAmount) external override returns (uint) {
        // Pausing is a very serious situation - we revert to sound the alarms
        require(!mintGuardianPaused[pToken], "mint is paused");

        // Shh - currently unused
        minter;
        mintAmount;

        if (!markets[pToken].isListed) {
            return uint(Error.MARKET_NOT_LISTED);
        }

        // Keep the flywheel moving
        distributor.updatePieSupplyIndex(pToken);
        distributor.distributeSupplierPie(pToken, minter, false);

        return uint(Error.NO_ERROR);
    }

    /**
     * @notice Checks if the account should be allowed to redeem tokens in the given market
     * @param pToken The market to verify the redeem against
     * @param redeemer The account which would redeem the tokens
     * @param redeemTokens The number of pTokens to exchange for the underlying asset in the market
     * @return 0 if the redeem is allowed, otherwise a semi-opaque error code (See ErrorReporter.sol)
     */
    function redeemAllowed(address pToken, address redeemer, uint redeemTokens) external override returns (uint) {
        uint allowed = redeemAllowedInternal(pToken, redeemer, redeemTokens);
        if (allowed != uint(Error.NO_ERROR)) {
            return allowed;
        }

        // Keep the flywheel moving
        distributor.updatePieSupplyIndex(pToken);
        distributor.distributeSupplierPie(pToken, redeemer, false);

        return uint(Error.NO_ERROR);
    }

    function redeemAllowedInternal(address pToken, address redeemer, uint redeemTokens) internal view returns (uint) {
        if (!markets[pToken].isListed) {
            return uint(Error.MARKET_NOT_LISTED);
        }

        /* If the redeemer is not 'in' the market, then we can bypass the liquidity check */
        if (!markets[pToken].accountMembership[redeemer]) {
            return uint(Error.NO_ERROR);
        }

        /* Otherwise, perform a hypothetical liquidity check to guard against shortfall */
        (Error err, , uint shortfall) = getHypotheticalAccountLiquidityInternal(redeemer, pToken, redeemTokens, 0);
        if (err != Error.NO_ERROR) {
            return uint(err);
        }
        if (shortfall > 0) {
            return uint(Error.INSUFFICIENT_LIQUIDITY);
        }

        return uint(Error.NO_ERROR);
    }

    /**
     * @notice Validates redeem and reverts on rejection. May emit logs.
     * @param pToken Asset being redeemed
     * @param redeemer The address redeeming the tokens
     * @param redeemAmount The amount of the underlying asset being redeemed
     * @param redeemTokens The number of tokens being redeemed
     */
    function redeemVerify(address pToken, address redeemer, uint redeemAmount, uint redeemTokens) external override {
        // Shh - currently unused
        pToken;
        redeemer;

        // Require tokens is zero or amount is also zero
        if (redeemTokens == 0 && redeemAmount > 0) {
            revert("redeemTokens zero");
        }
    }

    /**
     * @notice Checks if the account should be allowed to borrow the underlying asset of the given market
     * @param pToken The market to verify the borrow against
     * @param borrower The account which would borrow the asset
     * @param borrowAmount The amount of underlying the account would borrow
     * @return 0 if the borrow is allowed, otherwise a semi-opaque error code (See ErrorReporter.sol)
     */
    function borrowAllowed(address pToken, address borrower, uint borrowAmount) external override returns (uint) {
        // Pausing is a very serious situation - we revert to sound the alarms
        require(!borrowGuardianPaused[pToken], "borrow is paused");

        if (!markets[pToken].isListed) {
            return uint(Error.MARKET_NOT_LISTED);
        }

        Error err;

        if (!markets[pToken].accountMembership[borrower]) {
            // only pTokens may call borrowAllowed if borrower not in market
            require(msg.sender == pToken, "sender must be pToken");

            // attempt to add borrower to the market
            err = addToMarketInternal(msg.sender, borrower);
            if (err != Error.NO_ERROR) {
                return uint(err);
            }

            // it should be impossible to break the important invariant
            assert(markets[pToken].accountMembership[borrower]);
        }

        if (getOracle().getUnderlyingPrice(pToken) == 0) {
            return uint(Error.PRICE_ERROR);
        }

        uint shortfall;

        (err, , shortfall) = getHypotheticalAccountLiquidityInternal(borrower, pToken, 0, borrowAmount);
        if (err != Error.NO_ERROR) {
            return uint(err);
        }
        if (shortfall > 0) {
            return uint(Error.INSUFFICIENT_LIQUIDITY);
        }

        // Keep the flywheel moving
        Exp memory borrowIndex = Exp({mantissa: PTokenInterface(pToken).borrowIndex()});
        distributor.updatePieBorrowIndex(pToken, borrowIndex);
        distributor.distributeBorrowerPie(pToken, borrower, borrowIndex, false);

        return uint(Error.NO_ERROR);
    }

    /**
     * @notice Checks if the account should be allowed to repay a borrow in the given market
     * @param pToken The market to verify the repay against
     * @param payer The account which would repay the asset
     * @param borrower The account which would borrowed the asset
     * @param repayAmount The amount of the underlying asset the account would repay
     * @return 0 if the repay is allowed, otherwise a semi-opaque error code (See ErrorReporter.sol)
     */
    function repayBorrowAllowed(
        address pToken,
        address payer,
        address borrower,
        uint repayAmount
    ) external override returns (uint) {
        // Shh - currently unused
        payer;
        borrower;
        repayAmount;

        if (!markets[pToken].isListed) {
            return uint(Error.MARKET_NOT_LISTED);
        }

        // Keep the flywheel moving
        Exp memory borrowIndex = Exp({mantissa: PTokenInterface(pToken).borrowIndex()});
        distributor.updatePieBorrowIndex(pToken, borrowIndex);
        distributor.distributeBorrowerPie(pToken, borrower, borrowIndex, false);

        return uint(Error.NO_ERROR);
    }

    /**
     * @notice Checks if the liquidation should be allowed to occur
     * @param pTokenBorrowed Asset which was borrowed by the borrower
     * @param pTokenCollateral Asset which was used as collateral and will be seized
     * @param liquidator The address repaying the borrow and seizing the collateral
     * @param borrower The address of the borrower
     * @param repayAmount The amount of underlying being repaid
     */
    function liquidateBorrowAllowed(
        address pTokenBorrowed,
        address pTokenCollateral,
        address liquidator,
        address borrower,
        uint repayAmount
    ) external override returns (uint) {
        if (!markets[pTokenBorrowed].isListed || !markets[pTokenCollateral].isListed) {
            return uint(Error.MARKET_NOT_LISTED);
        }

        /* The borrower must have shortfall(sumCollateral < sumBorrowPlusEffects) in order to be liquidatable */
        (Error err, uint sumCollateral, uint sumBorrowPlusEffects, uint sumDeposit) = calcHypotheticalAccountLiquidityInternal(borrower, address(0), 0, 0);
        if (err != Error.NO_ERROR) {
            return uint(err);
        }
        if (sumCollateral >= sumBorrowPlusEffects) {
            return uint(Error.INSUFFICIENT_SHORTFALL);
        }

        /* The liquidator may not repay more than what is allowed by the closeFactor */
        uint borrowBalance = PTokenInterface(pTokenBorrowed).borrowBalanceStored(borrower);
        (MathError mathErr, uint maxClose) = mulScalarTruncate(Exp({mantissa: closeFactorMantissa}), borrowBalance);
        if (mathErr != MathError.NO_ERROR) {
            return uint(Error.MATH_ERROR);
        }
        if (repayAmount > maxClose) {
            return uint(Error.TOO_MUCH_REPAY);
        }

        // res = sumBorrowPlusEffects * liquidationIncentiveMantissa / 1e18
        uint result = div_(mul_(sumBorrowPlusEffects, liquidationIncentiveMantissa), 1e18);
        if (result > sumDeposit
            && liquidator != liquidateGuardian
        ) {
            return uint(Error.GUARDIAN_REJECTION);
        }

        return uint(Error.NO_ERROR);
    }

    /**
     * @notice Checks if the seizing of assets should be allowed to occur
     * @param pTokenCollateral Asset which was used as collateral and will be seized
     * @param pTokenBorrowed Asset which was borrowed by the borrower
     * @param liquidator The address repaying the borrow and seizing the collateral
     * @param borrower The address of the borrower
     * @param seizeTokens The number of collateral tokens to seize
     */
    function seizeAllowed(
        address pTokenCollateral,
        address pTokenBorrowed,
        address liquidator,
        address borrower,
        uint seizeTokens
    ) external override returns (uint) {
        // Pausing is a very serious situation - we revert to sound the alarms
        require(!seizeGuardianPaused, "seize is paused");

        // Shh - currently unused
        seizeTokens;

        if (!markets[pTokenCollateral].isListed || !markets[pTokenBorrowed].isListed) {
            return uint(Error.MARKET_NOT_LISTED);
        }

        if (PTokenInterface(pTokenCollateral).controller() != PTokenInterface(pTokenBorrowed).controller()) {
            return uint(Error.CONTROLLER_MISMATCH);
        }

        // Keep the flywheel moving
        distributor.updatePieSupplyIndex(pTokenCollateral);
        distributor.distributeSupplierPie(pTokenCollateral, borrower, false);
        distributor.distributeSupplierPie(pTokenCollateral, liquidator, false);

        return uint(Error.NO_ERROR);
    }

    /**
     * @notice Checks if the account should be allowed to transfer tokens in the given market
     * @param pToken The market to verify the transfer against
     * @param src The account which sources the tokens
     * @param dst The account which receives the tokens
     * @param transferTokens The number of pTokens to transfer
     * @return 0 if the transfer is allowed, otherwise a semi-opaque error code (See ErrorReporter.sol)
     */
    function transferAllowed(
        address pToken,
        address src,
        address dst,
        uint transferTokens
    ) external override returns (uint) {
        // Pausing is a very serious situation - we revert to sound the alarms
        require(!transferGuardianPaused, "transfer is paused");

        // Currently the only consideration is whether or not
        //  the src is allowed to redeem this many tokens
        uint allowed = redeemAllowedInternal(pToken, src, transferTokens);
        if (allowed != uint(Error.NO_ERROR)) {
            return allowed;
        }

        // Keep the flywheel moving
        distributor.updatePieSupplyIndex(pToken);
        distributor.distributeSupplierPie(pToken, src, false);
        distributor.distributeSupplierPie(pToken, dst, false);

        return uint(Error.NO_ERROR);
    }

    /*** Liquidity/Liquidation Calculations ***/

    /**
     * @dev Local vars for avoiding stack-depth limits in calculating account liquidity.
     *  Note that `pTokenBalance` is the number of pTokens the account owns in the market,
     *  whereas `borrowBalance` is the amount of underlying that the account has borrowed.
     */
    struct AccountLiquidityLocalVars {
        uint sumCollateral;
        uint sumBorrowPlusEffects;
        uint pTokenBalance;
        uint borrowBalance;
        uint exchangeRateMantissa;
        uint oraclePriceMantissa;
        uint sumDeposit;
        Exp collateralFactor;
        Exp exchangeRate;
        Exp oraclePrice;
        Exp tokensToDenom;
    }

    /**
     * @notice Determine the current account liquidity wrt collateral requirements
     * @return (possible error code (semi-opaque),
                account liquidity in excess of collateral requirements,
     *          account shortfall below collateral requirements)
     */
    function getAccountLiquidity(address account) public view returns (uint, uint, uint) {
        (Error err, uint liquidity, uint shortfall) = getHypotheticalAccountLiquidityInternal(account, address(0), 0, 0);

        return (uint(err), liquidity, shortfall);
    }

    /**
     * @notice Determine the current account liquidity wrt collateral requirements
     * @return (possible error code,
                account liquidity in excess of collateral requirements,
     *          account shortfall below collateral requirements)
     */
    function getAccountLiquidityInternal(address account) internal view returns (Error, uint, uint) {
        return getHypotheticalAccountLiquidityInternal(account, address(0), 0, 0);
    }

    /**
     * @notice Determine what the account liquidity would be if the given amounts were redeemed/borrowed
     * @param pTokenModify The market to hypothetically redeem/borrow in
     * @param account The account to determine liquidity for
     * @param redeemTokens The number of tokens to hypothetically redeem
     * @param borrowAmount The amount of underlying to hypothetically borrow
     * @return (possible error code (semi-opaque),
                hypothetical account liquidity in excess of collateral requirements,
     *          hypothetical account shortfall below collateral requirements)
     */
    function getHypotheticalAccountLiquidity(
        address account,
        address pTokenModify,
        uint redeemTokens,
        uint borrowAmount
    ) public view virtual returns (uint, uint, uint) {
        (Error err, uint liquidity, uint shortfall) = getHypotheticalAccountLiquidityInternal(account, pTokenModify, redeemTokens, borrowAmount);
        return (uint(err), liquidity, shortfall);
    }

    /**
     * @notice Determine what the account liquidity would be if the given amounts were redeemed/borrowed
     * @param pTokenModify The market to hypothetically redeem/borrow in
     * @param account The account to determine liquidity for
     * @param redeemTokens The number of tokens to hypothetically redeem
     * @param borrowAmount The amount of underlying to hypothetically borrow
     * @dev Note that we calculate the exchangeRateStored for each collateral pToken using stored data,
     *  without calculating accumulated interest.
     * @return (possible error code,
                hypothetical account liquidity in excess of collateral requirements,
     *          hypothetical account shortfall below collateral requirements)
     */
    function getHypotheticalAccountLiquidityInternal(
        address account,
        address pTokenModify,
        uint redeemTokens,
        uint borrowAmount
    ) internal view returns (Error, uint, uint) {

        (Error err, uint sumCollateral, uint sumBorrowPlusEffects, ) = calcHypotheticalAccountLiquidityInternal(account, pTokenModify, redeemTokens, borrowAmount);
        if (err != Error.NO_ERROR) {
            return (err, sumCollateral, sumBorrowPlusEffects);
        }

        // These are safe, as the underflow condition is checked first
        if (sumCollateral > sumBorrowPlusEffects) {
            return (Error.NO_ERROR, sumCollateral - sumBorrowPlusEffects, 0);
        } else {
            return (Error.NO_ERROR, 0, sumBorrowPlusEffects - sumCollateral);
        }
    }

    function calcHypotheticalAccountLiquidityInternal(
        address account,
        address pTokenModify,
        uint redeemTokens,
        uint borrowAmount
    ) internal view returns (Error, uint, uint, uint) {

        AccountLiquidityLocalVars memory vars; // Holds all our calculation results
        uint oErr;
        MathError mErr;

        // For each asset the account is in
        address[] memory assets = accountAssets[account];
        for (uint i = 0; i < assets.length; i++) {
            address asset = assets[i];

            // Read the balances and exchange rate from the pToken
            (oErr, vars.pTokenBalance, vars.borrowBalance, vars.exchangeRateMantissa) = PTokenInterface(asset).getAccountSnapshot(account);
            if (oErr != 0) { // semi-opaque error code, we assume NO_ERROR == 0 is invariant between upgrades
                return (Error.SNAPSHOT_ERROR, 0, 0, 0);
            }
            vars.collateralFactor = Exp({mantissa: markets[address(asset)].collateralFactorMantissa});
            vars.exchangeRate = Exp({mantissa: vars.exchangeRateMantissa});

            // Get the normalized price of the asset
            vars.oraclePriceMantissa = getOracle().getUnderlyingPrice(asset);
            if (vars.oraclePriceMantissa == 0) {
                return (Error.PRICE_ERROR, 0, 0, 0);
            }

            vars.oraclePrice = Exp({mantissa: vars.oraclePriceMantissa});

            // Pre-compute a conversion factor from tokens -> ether (normalized price value)
            (mErr, vars.tokensToDenom) = mulExp(vars.exchangeRate, vars.oraclePrice);
            if (mErr != MathError.NO_ERROR) {
                return (Error.MATH_ERROR, 0, 0, 0);
            }

            (mErr, vars.sumDeposit) = mulScalarTruncateAddUInt(vars.tokensToDenom, vars.pTokenBalance, vars.sumDeposit);
            if (mErr != MathError.NO_ERROR) {
                return (Error.MATH_ERROR, 0, 0, 0);
            }

            (mErr, vars.tokensToDenom) = mulExp(vars.collateralFactor, vars.tokensToDenom);
            if (mErr != MathError.NO_ERROR) {
                return (Error.MATH_ERROR, 0, 0, 0);
            }

            // sumCollateral += tokensToDenom * pTokenBalance
            (mErr, vars.sumCollateral) = mulScalarTruncateAddUInt(vars.tokensToDenom, vars.pTokenBalance, vars.sumCollateral);
            if (mErr != MathError.NO_ERROR) {
                return (Error.MATH_ERROR, 0, 0, 0);
            }

            // for feeToken
            if (asset != registry.pETH()
                && asset != registry.pPIE()
                && feeFactorMantissa[asset] > 0
            ) {
                // vars.oraclePriceMantissa * (1e18 + feeFactorMantissa[asset] * 3) / 1e18
                vars.oraclePrice = Exp({mantissa: div_(mul_(vars.oraclePriceMantissa, (add_(1e18, mul_(feeFactorMantissa[asset], 3)))), 1e18)});
            }

            // sumBorrowPlusEffects += oraclePrice * borrowBalance
            (mErr, vars.sumBorrowPlusEffects) = mulScalarTruncateAddUInt(vars.oraclePrice, vars.borrowBalance, vars.sumBorrowPlusEffects);
            if (mErr != MathError.NO_ERROR) {
                return (Error.MATH_ERROR, 0, 0, 0);
            }

            // Calculate effects of interacting with pTokenModify
            if (asset == pTokenModify) {
                // redeem effect
                // sumBorrowPlusEffects += tokensToDenom * redeemTokens
                (mErr, vars.sumBorrowPlusEffects) = mulScalarTruncateAddUInt(vars.tokensToDenom, redeemTokens, vars.sumBorrowPlusEffects);
                if (mErr != MathError.NO_ERROR) {
                    return (Error.MATH_ERROR, 0, 0, 0);
                }

                // borrow effect
                // sumBorrowPlusEffects += oraclePrice * borrowAmount
                (mErr, vars.sumBorrowPlusEffects) = mulScalarTruncateAddUInt(vars.oraclePrice, borrowAmount, vars.sumBorrowPlusEffects);
                if (mErr != MathError.NO_ERROR) {
                    return (Error.MATH_ERROR, 0, 0, 0);
                }
            }
        }

        return (Error.NO_ERROR, vars.sumCollateral, vars.sumBorrowPlusEffects, vars.sumDeposit);
    }

    /**
     * @notice Calculate number of tokens of collateral asset to seize given an underlying amount
     * @dev Used in liquidation (called in pToken.liquidateBorrowFresh)
     * @param pTokenBorrowed The address of the borrowed pToken
     * @param pTokenCollateral The address of the collateral pToken
     * @param actualRepayAmount The amount of pTokenBorrowed underlying to convert into pTokenCollateral tokens
     * @return (errorCode, number of pTokenCollateral tokens to be seized in a liquidation)
     */
    function liquidateCalculateSeizeTokens(
        address pTokenBorrowed,
        address pTokenCollateral,
        uint actualRepayAmount
    ) external view override returns (uint, uint) {
        /* Read oracle prices for borrowed and collateral markets */
        uint priceBorrowedMantissa = getOracle().getUnderlyingPrice(pTokenBorrowed);
        uint priceCollateralMantissa = getOracle().getUnderlyingPrice(pTokenCollateral);
        if (priceBorrowedMantissa == 0 || priceCollateralMantissa == 0) {
            return (uint(Error.PRICE_ERROR), 0);
        }

        /*
         * Get the exchange rate and calculate the number of collateral tokens to seize:
         *  seizeAmount = actualRepayAmount * liquidationIncentive * priceBorrowed / priceCollateral
         *  seizeTokens = seizeAmount / exchangeRate
         *   = actualRepayAmount * (liquidationIncentive * priceBorrowed) / (priceCollateral * exchangeRate)
         */
        uint seizeTokens;
        Exp memory numerator;
        Exp memory denominator;
        Exp memory ratio;
        MathError mathErr;

        (mathErr, numerator) = mulExp(liquidationIncentiveMantissa, priceBorrowedMantissa);
        if (mathErr != MathError.NO_ERROR) {
            return (uint(Error.MATH_ERROR), 0);
        }

        // uint exchangeRateMantissa = PTokenInterface(pTokenCollateral).exchangeRateStored(); // Note: reverts on error
        (mathErr, denominator) = mulExp(priceCollateralMantissa, PTokenInterface(pTokenCollateral).exchangeRateStored());
        if (mathErr != MathError.NO_ERROR) {
            return (uint(Error.MATH_ERROR), 0);
        }

        (mathErr, ratio) = divExp(numerator, denominator);
        if (mathErr != MathError.NO_ERROR) {
            return (uint(Error.MATH_ERROR), 0);
        }

        (mathErr, seizeTokens) = mulScalarTruncate(ratio, actualRepayAmount);
        if (mathErr != MathError.NO_ERROR) {
            return (uint(Error.MATH_ERROR), 0);
        }

        uint feeFactor = feeFactorMantissa[pTokenBorrowed];
        if (feeFactor > 0) {
            // seizeTokens * 1e36 / ((1e18 - feeFactorMantissa[pTokenBorrowed]) ** 2)
            uint res = sub_(1e18, feeFactor);
            seizeTokens = div_(mul_(seizeTokens, 1e36), mul_(res, res));
        }

        return (uint(Error.NO_ERROR), seizeTokens);
    }

    /*** Admin Functions ***/

    function setVotingEscrow(address _votingEscrow) public {
        require(msg.sender == getAdmin(), "Controller::setVotingEscrow: only admin");

        votingEscrow = _votingEscrow;
    }

    /**
      * @notice Sets the closeFactor used when liquidating borrows
      * @dev Admin function to set closeFactor
      * @param newCloseFactorMantissa New close factor, scaled by 1e18
      * @return uint 0=success, otherwise a failure. (See ErrorReporter for details)
      */
    function _setCloseFactor(uint newCloseFactorMantissa) external returns (uint) {
        // Check caller is admin
        if (msg.sender != getAdmin()) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SET_CLOSE_FACTOR_OWNER_CHECK);
        }

        Exp memory newCloseFactorExp = Exp({mantissa: newCloseFactorMantissa});
        Exp memory lowLimit = Exp({mantissa: closeFactorMinMantissa});
        if (lessThanOrEqualExp(newCloseFactorExp, lowLimit)) {
            return fail(Error.INVALID_CLOSE_FACTOR, FailureInfo.SET_CLOSE_FACTOR_VALIDATION);
        }

        Exp memory highLimit = Exp({mantissa: closeFactorMaxMantissa});
        if (lessThanExp(highLimit, newCloseFactorExp)) {
            return fail(Error.INVALID_CLOSE_FACTOR, FailureInfo.SET_CLOSE_FACTOR_VALIDATION);
        }

        uint oldCloseFactorMantissa = closeFactorMantissa;
        closeFactorMantissa = newCloseFactorMantissa;
        emit NewCloseFactor(oldCloseFactorMantissa, closeFactorMantissa);

        return uint(Error.NO_ERROR);
    }

    /**
      * @notice Sets the collateralFactor for a market
      * @dev Admin function to set per-market collateralFactor
      * @param pToken The market to set the factor on
      * @param newCollateralFactorMantissa The new collateral factor, scaled by 1e18
      * @return uint 0=success, otherwise a failure. (See ErrorReporter for details)
      */
    function _setCollateralFactor(address pToken, uint newCollateralFactorMantissa) external returns (uint) {
        // Check caller is admin
        if (msg.sender != getAdmin()) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SET_COLLATERAL_FACTOR_OWNER_CHECK);
        }

        // Verify market is listed
        Market storage market = markets[pToken];
        if (!market.isListed) {
            return fail(Error.MARKET_NOT_LISTED, FailureInfo.SET_COLLATERAL_FACTOR_NO_EXISTS);
        }

        Exp memory newCollateralFactorExp = Exp({mantissa: newCollateralFactorMantissa});

        // Check collateral factor <= 0.9
        Exp memory highLimit = Exp({mantissa: collateralFactorMaxMantissa});
        if (lessThanExp(highLimit, newCollateralFactorExp)) {
            return fail(Error.INVALID_COLLATERAL_FACTOR, FailureInfo.SET_COLLATERAL_FACTOR_VALIDATION);
        }

        getOracle().updateUnderlyingPrice(pToken);
        // If collateral factor != 0, fail if price == 0
        if (newCollateralFactorMantissa != 0 && getOracle().getUnderlyingPrice(pToken) == 0) {
            return fail(Error.PRICE_ERROR, FailureInfo.SET_COLLATERAL_FACTOR_WITHOUT_PRICE);
        }

        // Set market's collateral factor to new collateral factor, remember old value
        uint oldCollateralFactorMantissa = market.collateralFactorMantissa;
        market.collateralFactorMantissa = newCollateralFactorMantissa;

        // Emit event with asset, old collateral factor, and new collateral factor
        emit NewCollateralFactor(pToken, oldCollateralFactorMantissa, newCollateralFactorMantissa);

        return uint(Error.NO_ERROR);
    }

    /**
      * @notice Sets the max fee factor for a markets
      * @dev Admin function to set max fee factor
      * @param newFeeFactorMaxMantissa The new max fee factor, scaled by 1e18
      * @return uint 0=success, otherwise a failure. (See ErrorReporter for details)
      */
    function _setFeeFactorMaxMantissa(uint newFeeFactorMaxMantissa) external returns (uint) {
        if (msg.sender != getAdmin()) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SET_MAX_FEE_FACTOR);
        }

        uint oldFeeFactorMaxMantissa = feeFactorMaxMantissa;
        feeFactorMaxMantissa = newFeeFactorMaxMantissa;

        emit NewFeeFactorMaxMantissa(oldFeeFactorMaxMantissa, newFeeFactorMaxMantissa);

        return uint(Error.NO_ERROR);
    }

    /**
      * @notice Sets the feeFactor for a market
      * @dev Admin function to set per-market fee factor (also market can set fee factor after calc)
      * @param pToken The market to set the factor on
      * @param newFeeFactorMantissa The new fee factor, scaled by 1e18
      * @return uint 0=success, otherwise a failure. (See ErrorReporter for details)
      */
    function _setFeeFactor(address pToken, uint newFeeFactorMantissa) public override returns (uint) {
        if (msg.sender != getAdmin() && !markets[msg.sender].isListed) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SET_FEE_FACTOR);
        }

        require(newFeeFactorMantissa <= feeFactorMaxMantissa, 'SET_FEE_FACTOR_FAILED');
        require(markets[pToken].isListed, 'market is not listed');

        uint oldFeeFactorMantissa = feeFactorMantissa[pToken];
        feeFactorMantissa[pToken] = newFeeFactorMantissa;

        emit NewFeeFactor(pToken, oldFeeFactorMantissa, newFeeFactorMantissa);

        return uint(Error.NO_ERROR);
    }

    /**
      * @notice Sets the feeFactors for a markets
      * @dev Admin function to set per-market fee factors (also market can set fee factor after calc)
      * @param pTokens Markets to set the factor on
      * @param newFeeFactors The new fee factors for markets, scaled by 1e18
      * @return uint 0=success, otherwise a failure. (See ErrorReporter for details)
      */
    function _setFeeFactors(address[] calldata pTokens, uint[] calldata newFeeFactors) external returns (uint) {
        require(pTokens.length != 0 && newFeeFactors.length == pTokens.length, "invalid input");

        uint result;
        for(uint i = 0; i < pTokens.length; i++ ) {
            result = _setFeeFactor(pTokens[i], newFeeFactors[i]);

            if (result != uint(Error.NO_ERROR)) {
                return fail(Error.REJECTION, FailureInfo.SET_FEE_FACTOR);
            }
        }

        return uint(Error.NO_ERROR);
    }

    /**
      * @notice Sets maxAssets which controls how many markets can be entered
      * @dev Admin function to set maxAssets
      * @param newMaxAssets New max assets
      * @return uint 0=success, otherwise a failure. (See ErrorReporter for details)
      */
    function _setMaxAssets(uint newMaxAssets) external returns (uint) {
        // Check caller is admin
        if (msg.sender != getAdmin()) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SET_MAX_ASSETS_OWNER_CHECK);
        }

        uint oldMaxAssets = maxAssets;
        maxAssets = newMaxAssets;
        emit NewMaxAssets(oldMaxAssets, newMaxAssets);

        return uint(Error.NO_ERROR);
    }

    /**
      * @notice Sets liquidationIncentive
      * @dev Admin function to set liquidationIncentive
      * @param newLiquidationIncentiveMantissa New liquidationIncentive scaled by 1e18
      * @return uint 0=success, otherwise a failure. (See ErrorReporter for details)
      */
    function _setLiquidationIncentive(uint newLiquidationIncentiveMantissa) external returns (uint) {
        // Check caller is admin
        if (msg.sender != getAdmin()) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SET_LIQUIDATION_INCENTIVE_OWNER_CHECK);
        }

        // Check de-scaled min <= newLiquidationIncentive <= max
        Exp memory newLiquidationIncentive = Exp({mantissa: newLiquidationIncentiveMantissa});
        Exp memory minLiquidationIncentive = Exp({mantissa: liquidationIncentiveMinMantissa});
        if (lessThanExp(newLiquidationIncentive, minLiquidationIncentive)) {
            return fail(Error.INVALID_LIQUIDATION_INCENTIVE, FailureInfo.SET_LIQUIDATION_INCENTIVE_VALIDATION);
        }

        Exp memory maxLiquidationIncentive = Exp({mantissa: liquidationIncentiveMaxMantissa});
        if (lessThanExp(maxLiquidationIncentive, newLiquidationIncentive)) {
            return fail(Error.INVALID_LIQUIDATION_INCENTIVE, FailureInfo.SET_LIQUIDATION_INCENTIVE_VALIDATION);
        }

        // Save current value for use in log
        uint oldLiquidationIncentiveMantissa = liquidationIncentiveMantissa;

        // Set liquidation incentive to new incentive
        liquidationIncentiveMantissa = newLiquidationIncentiveMantissa;

        // Emit event with old incentive, new incentive
        emit NewLiquidationIncentive(oldLiquidationIncentiveMantissa, newLiquidationIncentiveMantissa);

        return uint(Error.NO_ERROR);
    }

    /**
      * @notice Add the market to the markets mapping and set it as listed
      * @dev Admin function to set isListed and add support for the market
      * @param pToken The address of the market (token) to list
      * @return uint 0=success, otherwise a failure. (See enum Error for details)
      */
    function _supportMarket(address pToken) external returns (uint) {
        if (msg.sender != getAdmin() && msg.sender != registry.factory()) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SUPPORT_MARKET_OWNER_CHECK);
        }

        if (markets[pToken].isListed) {
            return fail(Error.MARKET_ALREADY_LISTED, FailureInfo.SUPPORT_MARKET_EXISTS);
        }

        PTokenInterface(pToken).isPToken(); // Sanity check to make sure its really a PToken

        _addMarketInternal(pToken);

        Market storage newMarket = markets[pToken];
        newMarket.isListed = true;

        emit MarketListed(pToken);

        return uint(Error.NO_ERROR);
    }

    function _addMarketInternal(address pToken) internal {
        require(markets[pToken].isListed == false, "market already added");
        allMarkets.push(pToken);
    }

    /**
     * @notice Admin function to change the Pause Guardian
     * @param newPauseGuardian The address of the new Pause Guardian
     * @return uint 0=success, otherwise a failure. (See enum Error for details)
     */
    function _setPauseGuardian(address newPauseGuardian) public returns (uint) {
        if (msg.sender != getAdmin()) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SET_GUARDIAN_OWNER_CHECK);
        }

        // Save current value for inclusion in log
        address oldPauseGuardian = pauseGuardian;

        // Store pauseGuardian with value newPauseGuardian
        pauseGuardian = newPauseGuardian;

        // Emit NewPauseGuardian(OldPauseGuardian, NewPauseGuardian)
        emit NewPauseGuardian(oldPauseGuardian, pauseGuardian);

        return uint(Error.NO_ERROR);
    }

    /**
     * @notice Admin function to change the Liquidate Guardian
     * @param newLiquidateGuardian The address of the new Liquidate Guardian
     * @return uint 0=success, otherwise a failure. (See enum Error for details)
     */
    function _setLiquidateGuardian(address newLiquidateGuardian) public returns (uint) {
        if (msg.sender != getAdmin()) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SET_GUARDIAN_OWNER_CHECK);
        }

        // Save current value for inclusion in log
        address oldLiquidateGuardian = liquidateGuardian;

        // Store pauseGuardian with value newLiquidateGuardian
        liquidateGuardian = newLiquidateGuardian;

        // Emit newLiquidateGuardian(OldPauseGuardian, NewLiquidateGuardian)
        emit NewLiquidateGuardian(oldLiquidateGuardian, liquidateGuardian);

        return uint(Error.NO_ERROR);
    }

    /**
     * @notice Admin function to change the Distributor
     * @param newDistributor The address of the new Distributor
     * @return uint 0=success, otherwise a failure. (See enum Error for details)
     */
    function _setDistributor(address newDistributor) public returns (uint) {
        if (msg.sender != getAdmin()) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SET_GUARDIAN_OWNER_CHECK);
        }

        // Save current value for inclusion in log
        address oldDistributor = address(distributor);

        // Store distributor with value newDistributor
        distributor = DistributorInterface(newDistributor);

        // Emit NewDistributor(OldDistributor, NewDistributor)
        emit NewDistributor(oldDistributor, address(distributor));

        return uint(Error.NO_ERROR);
    }

    /**
     * @notice Admin function to change the mint status for market
     * @param pToken The address of the market
     * @param state The flag of the mint status for market
     * @return uint 0=success, otherwise a failure. (See enum Error for details)
     */
    function _setMintPaused(address pToken, bool state) public returns (bool) {
        require(markets[pToken].isListed, "cannot pause a market that is not listed");
        require(msg.sender == pauseGuardian || msg.sender == getAdmin(), "only pause guardian and admin can pause");
        require(msg.sender == getAdmin() || state == true, "only admin can unpause");

        mintGuardianPaused[pToken] = state;

        emit ActionPaused(pToken, "Mint", state);

        return state;
    }

    /**
     * @notice Factory function to get reward for moderate pool
     * @param pToken The address of the market
     * @param createPoolFeeAmount The token amount for freeze
     */
    function setFreezePoolAmount(address pToken, uint createPoolFeeAmount) public override {
        require(msg.sender == registry.factory(), "only factory can set freeze");
        moderatePools[pToken].freezePoolAmount = createPoolFeeAmount;
        totalFreeze = add_(totalFreeze, createPoolFeeAmount);

        emit FreezePoolAmount(pToken, createPoolFeeAmount);
    }

    /**
     * @notice Admin function to change the borrow status for market
     * @param pToken The address of the market
     * @param state The flag of the borrow status for market
     * @return uint 0=success, otherwise a failure. (See enum Error for details)
     */
    function _setBorrowPaused(address pToken, bool state) public returns (bool) {
        require(markets[pToken].isListed, "cannot pause a market that is not listed");

        if (msg.sender == getAdmin()) {
            // nothing
        } else if (msg.sender == pauseGuardian) {
            if (state == true) {
                // nothing
            } else {
                ModerateData storage pool = moderatePools[pToken];
                if (pool.rewardState == RewardState.PENDING) {
                    pool.rewardState = RewardState.REJECTED;
                }
            }
        } else {
            require(!borrowGuardianPaused[pToken] && state == true, "only pause");

            uint startBorrowTimestamp = PErc20ExtInterface(pToken).startBorrowTimestamp();
            require(block.timestamp < startBorrowTimestamp, "only before startBorrow");

            EIP20Interface(distributor.getPieAddress()).transferFrom(msg.sender, address(this), userPauseDepositAmount);

            ModerateData storage pool = moderatePools[pToken];
            require(pool.rewardState == RewardState.CREATED, "bad reward state");

            pool.userModerate = msg.sender;
            pool.freezePoolAmount += userPauseDepositAmount;
            pool.rewardState = RewardState.PENDING;

            totalFreeze = add_(totalFreeze, userPauseDepositAmount);
        }

        borrowGuardianPaused[pToken] = state;

        emit ActionPaused(pToken, "Borrow", state);

        return state;
    }

    /**
     * @notice User function to get reward for moderate pool
     * @param pToken The address of the market
     * @return uint 0=success, otherwise a failure. (See enum Error for details)
     */
    function getModerateUserReward(address pToken) public returns(uint) {
        uint startBorrowTimestamp = PErc20ExtInterface(pToken).startBorrowTimestamp();
        require(block.timestamp > startBorrowTimestamp + guardianModerateTime, "only after start borrow and guardian time");

        ModerateData storage pool = moderatePools[pToken];
        require(msg.sender == pool.userModerate, "only moderate pool user can get reward");
        require(pool.rewardState == RewardState.PENDING, "only once");

        pool.rewardState = RewardState.CONFIRMED;

        uint unfreezeAmount = pool.freezePoolAmount;
        totalFreeze = sub_(totalFreeze, unfreezeAmount);

        EIP20Interface(distributor.getPieAddress()).transfer(msg.sender, unfreezeAmount);

        emit ModerateUserReward(pToken, msg.sender, unfreezeAmount);

        return uint(Error.NO_ERROR);
    }

    /**
     * @notice Function to harvest unused reward
     * @param pToken The address of the market
     */
    function harvestUnusedReward(address pToken) public {
        uint startBorrowTimestamp = PErc20ExtInterface(pToken).startBorrowTimestamp();
        require(block.timestamp > startBorrowTimestamp + guardianModerateTime, "current time is less than user end moderate pool time");

        ModerateData storage pool = moderatePools[pToken];
        require(pool.rewardState == RewardState.CREATED || pool.rewardState == RewardState.REJECTED, "reward must be unused");

        pool.rewardState = RewardState.HARVESTED;

        uint freezePoolAmount = pool.freezePoolAmount;
        totalFreeze = sub_(totalFreeze, freezePoolAmount);

        emit UnfreezePoolAmount(pToken, freezePoolAmount);
    }

    function harvestUnusedRewards(address[] calldata pTokens) public {
        for(uint i = 0; i < pTokens.length; i++) {
            harvestUnusedReward(pTokens[i]);
        }
    }

    /**
     * @notice Function to transfer all not freeze tokens to ppie pool
     */
    function transferModeratePoolReward() public {
        address ppieAddress = RegistryInterface(registry).pPIE();
        address pieAddress = distributor.getPieAddress();
        uint balance = EIP20Interface(pieAddress).balanceOf(address(this));

        uint poolReward = sub_(balance, totalFreeze);

        if (poolReward > 0 ) {
            EIP20Interface(pieAddress).transfer(votingEscrow, poolReward);
            IVotingEscrow(votingEscrow).depositPie(poolReward);

            emit ModeratePoolReward(poolReward);
        }
    }

    /**
     * @notice Admin function to change the Borrow Delay
     * @param newBorrowDelay The value of the new Borrow Delay in seconds
     * @return uint 0=success, otherwise a failure. (See enum Error for details)
     */
    function _setBorrowDelay(uint newBorrowDelay) public returns (uint) {
        if (msg.sender != getAdmin()) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SET_BORROW_DELAY_OWNER_CHECK);
        }

        // Save current value for inclusion in log
        uint oldBorrowDelay = borrowDelay;

        // Store dorrowDelay with value newBorrowDelay
        borrowDelay = newBorrowDelay;

        // Emit newBorrowDelay(OldBorrowDelay, NewBorrowDelay)
        emit NewBorrowDelay(oldBorrowDelay, borrowDelay);

        return uint(Error.NO_ERROR);
    }

    /**
     * @notice Admin function to change the transfer status for markets
     * @param state The flag of the transfer status
     * @return uint 0=success, otherwise a failure. (See enum Error for details)
     */
    function _setTransferPaused(bool state) public returns (bool) {
        require(msg.sender == pauseGuardian || msg.sender == getAdmin(), "only pause guardian and admin can pause");
        require(msg.sender == getAdmin() || state == true, "only admin can unpause");

        transferGuardianPaused = state;

        emit ActionPaused("Transfer", state);

        return state;
    }

    /**
     * @notice Admin function to change the seize status for markets
     * @param state The flag of the transfer status
     * @return uint 0=success, otherwise a failure. (See enum Error for details)
     */
    function _setSeizePaused(bool state) public returns (bool) {
        require(msg.sender == pauseGuardian || msg.sender == getAdmin(), "only pause guardian and admin can pause");
        require(msg.sender == getAdmin() || state == true, "only admin can unpause");

        seizeGuardianPaused = state;

        emit ActionPaused("Seize", state);

        return state;
    }

    /**
     * @notice Admin function to change the user moderate data
     * @param userPauseDepositAmount_ The Pie amount for pause from user
     * @param guardianModerateTime_ The time for guardian check pool
     * @return uint 0=success, otherwise a failure. (See enum Error for details)
     */
    function _setUserModeratePoolData(uint userPauseDepositAmount_, uint guardianModerateTime_) public returns(uint) {
        require(msg.sender == getAdmin(), "only admin can change");

        uint oldUserPauseDepositAmount = userPauseDepositAmount;
        uint oldGuardianModerateTime = guardianModerateTime;

        userPauseDepositAmount = userPauseDepositAmount_;
        guardianModerateTime = guardianModerateTime_;

        emit NewUserModeratePoolData(oldUserPauseDepositAmount, userPauseDepositAmount_, oldGuardianModerateTime, guardianModerateTime_);

        return uint(Error.NO_ERROR);
    }

    function _become(address unitroller) public {
        require(msg.sender == Unitroller(payable(unitroller)).getAdmin(), "only unitroller admin can change brains");
        require(Unitroller(payable(unitroller))._acceptImplementation() == 0, "change not authorized");
    }

    /**
     * @notice Return all of the markets
     * @dev The automatic getter may be used to access an individual market.
     * @return The list of market addresses
     */
    function getAllMarkets() public view override returns (address[] memory) {
        return allMarkets;
    }

    /**
     * @notice Return the number of current block
     * @return The block number
     */
    function getBlockNumber() public view virtual returns (uint) {
        return block.number;
    }

    /**
     * @notice Return the address of the oracle
     * @return The interface (address) of oracle
     */
    function getOracle() public view override returns (PriceOracle) {
        return PriceOracle(registry.oracle());
    }

    /**
     * @notice Return the address of the admin
     * @return The address of admin
     */
    function getAdmin() public view virtual returns (address) {
        return registry.admin();
    }

    /**
     * @notice Return the fee factor of the pToken
     * @param pToken PToken address
     * @return The address of admin
     */
    function getFeeFactorMantissa(address pToken) public view override returns (uint) {
        return feeFactorMantissa[pToken];
    }

    /**
     * @notice Return the borrow delay for markets
     * @return The borrow delay
     */
    function getBorrowDelay() public view override returns (uint) {
        return borrowDelay;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import './Tokens/PErc20Delegator.sol';
import './RegistryInterface.sol';
import './Tokens/EIP20Interface.sol';
import "./Oracles/Interfaces/IPriceFeeds.sol";
import "./ErrorReporter.sol";
import "./SafeMath.sol";
import "./Tokens/PEtherDelegator.sol";
import "./Tokens/PPIEDelegator.sol";
import "./Control/Controller.sol";
import "./Oracles/Interfaces/IPriceOracle.sol";
import "./Tokens/PTokenInterfaces.sol";
import "./PTokenFactoryStorage.sol";

contract PTokenFactory is PTokenFactoryStorageV1, FactoryErrorReporter {
    using SafeMath for uint;

    /**
     * Fired on creation new pToken proxy
     * @param newPToken Address of new PToken proxy contract
     * @param startBorrowTimestamp Timestamp for borrow start
     */
    event PTokenCreated(address newPToken, uint startBorrowTimestamp, uint underlyingType);

    event AddedBlackList(address _underlying);
    event RemovedBlackList(address _underlying);

    function initialize(
        address registry_,
        address controller_,
        address interestRateModel_,
        uint256 initialExchangeRateMantissa_,
        uint256 initialReserveFactorMantissa_,
        uint256 minOracleLiquidity_
    ) public {
        registry = registry_;
        controller = controller_;
        interestRateModel = interestRateModel_;
        initialExchangeRateMantissa = initialExchangeRateMantissa_;
        initialReserveFactorMantissa = initialReserveFactorMantissa_;
        minOracleLiquidity = minOracleLiquidity_;

        decimals = 8;
    }

    /**
     * Creates new pToken proxy contract and adds pToken to the controller
     * @param underlying_ The address of the underlying asset
     */
    function createPToken(address underlying_, uint type_) external returns (uint) {
        if (getBlackListStatus(underlying_)) {
            return fail(Error.INVALID_POOL, FailureInfo.UNDERLYING_IN_BLACKLIST);
        }
        require(type_ == uint(IPriceOracle.UnderlyingType.RegularAsset) || type_ == uint(IPriceOracle.UnderlyingType.UniswapV2LP), 'PTokenFactory: invalid underlying type');

        getOracle().setUnderlyingType(underlying_, type_);

        uint112 liquidity = getOracle().getLiquidity(underlying_);

        if (liquidity < minOracleLiquidity) {
            return fail(Error.INVALID_UNDERLYING, FailureInfo.DEFICIENCY_LIQUIDITY);
        }

        uint256 result = getOracle().update(underlying_);
        if (result != 0 && result != 4) {
            revert('PTokenFactory: failure updating price');
        }

        (string memory name, string memory symbol) = _createPTokenNameAndSymbol(underlying_, type_);

        uint power = EIP20Interface(underlying_).decimals();
        uint exchangeRateMantissa = calcExchangeRate(power);

        PErc20Delegator newPToken = new PErc20Delegator(underlying_, controller, interestRateModel, exchangeRateMantissa, initialReserveFactorMantissa, name, symbol, decimals, registry);

        result = Controller(controller)._supportMarket(address(newPToken));
        if (result != 0) {
            return fail(Error.MARKET_NOT_LISTED, FailureInfo.SUPPORT_MARKET_BAD_RESULT);
        }

        result = RegistryInterface(registry).addPToken(underlying_, address(newPToken));
        if (result != 0) {
            return fail(Error.MARKET_NOT_LISTED, FailureInfo.ADD_PTOKEN_BAD_RESULT);
        }

        uint startBorrowTimestamp = PErc20ExtInterface(address(newPToken)).startBorrowTimestamp();
        
        if (createPoolFeeAmount > 0) {
            EIP20Interface(PErc20Interface(RegistryInterface(registry).pPIE()).underlying()).transferFrom(msg.sender, controller, createPoolFeeAmount);
            ControllerInterface(controller).setFreezePoolAmount(address(newPToken), createPoolFeeAmount);
        }

        emit PTokenCreated(address(newPToken), startBorrowTimestamp, type_);

        return uint(Error.NO_ERROR);
    }

    function _createPETH(address pETHImplementation_, string memory symbol_) external virtual returns (uint) {
        if (msg.sender != getAdmin()) {
            return fail(Error.UNAUTHORIZED, FailureInfo.CREATE_PETH_POOL);
        }

        string memory name = string(abi.encodePacked("DeFiPie ", symbol_));
        string memory symbol = string(abi.encodePacked("p", symbol_));

        uint power = 18;
        uint exchangeRateMantissa = calcExchangeRate(power);

        PETHDelegator newPETH = new PETHDelegator(pETHImplementation_, controller, interestRateModel, exchangeRateMantissa, initialReserveFactorMantissa, name, symbol, decimals, address(registry));

        uint256 result = Controller(controller)._supportMarket(address(newPETH));
        if (result != 0) {
            return fail(Error.MARKET_NOT_LISTED, FailureInfo.SUPPORT_MARKET_BAD_RESULT);
        }

        result = RegistryInterface(registry).addPETH(address(newPETH));
        if (result != 0) {
            return fail(Error.MARKET_NOT_LISTED, FailureInfo.ADD_PTOKEN_BAD_RESULT);
        }

        emit PTokenCreated(address(newPETH), block.timestamp, uint(IPriceOracle.UnderlyingType.RegularAsset));

        return uint(Error.NO_ERROR);
    }

    function _createPPIE(address underlying_, address pPIEImplementation_) external virtual returns (uint) {
        if (msg.sender != getAdmin()) {
            return fail(Error.UNAUTHORIZED, FailureInfo.CREATE_PPIE_POOL);
        }

        getOracle().setUnderlyingType(underlying_, uint(IPriceOracle.UnderlyingType.RegularAsset));

        uint112 liquidity = getOracle().getLiquidity(underlying_);

        if (liquidity < minOracleLiquidity) {
            return fail(Error.INVALID_UNDERLYING, FailureInfo.DEFICIENCY_LIQUIDITY);
        }

        string memory name = "DeFiPie PIE";
        string memory symbol = "pPIE";

        uint power = EIP20Interface(underlying_).decimals();
        uint exchangeRateMantissa = calcExchangeRate(power);

        uint256 result = getOracle().update(underlying_);
        if (result != 0 && result != 4) {
            revert('PTokenFactory: failure updating price');
        }

        PPIEDelegator newPPIE = new PPIEDelegator(underlying_, pPIEImplementation_, controller, interestRateModel, exchangeRateMantissa, initialReserveFactorMantissa, name, symbol, decimals, address(registry));

        result = Controller(controller)._supportMarket(address(newPPIE));
        if (result != 0) {
            return fail(Error.MARKET_NOT_LISTED, FailureInfo.SUPPORT_MARKET_BAD_RESULT);
        }

        result = RegistryInterface(registry).addPPIE(address(newPPIE));
        if (result != 0) {
            return fail(Error.MARKET_NOT_LISTED, FailureInfo.ADD_PTOKEN_BAD_RESULT);
        }

        emit PTokenCreated(address(newPPIE), block.timestamp, uint(IPriceOracle.UnderlyingType.RegularAsset));

        return uint(Error.NO_ERROR);
    }

    function _setMinOracleLiquidity(uint minOracleLiquidity_) public returns (uint) {
        if (msg.sender != getAdmin()) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SET_MIN_LIQUIDITY_OWNER_CHECK);
        }

        minOracleLiquidity = minOracleLiquidity_;

        return uint(Error.NO_ERROR);
    }

    /**
     *  Sets address of actual controller contract
     *  @return uint 0 = success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function _setController(address newController) external returns (uint) {
        if (msg.sender != getAdmin()) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SET_NEW_CONTROLLER);
        }
        controller = newController;

        return(uint(Error.NO_ERROR));
    }

    /**
     *  Sets address of actual interestRateModel contract
     *  @return uint 0 = success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function _setInterestRateModel(address newInterestRateModel) external returns (uint) {
        if (msg.sender != getAdmin()) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SET_NEW_INTEREST_RATE_MODEL);
        }

        interestRateModel = newInterestRateModel;

        return(uint(Error.NO_ERROR));
    }

    /**
     *  Sets initial exchange rate
     *  @return uint 0 = success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function _setInitialExchangeRateMantissa(uint _initialExchangeRateMantissa) external returns (uint) {
        if (msg.sender != getAdmin()) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SET_NEW_EXCHANGE_RATE);
        }

        initialExchangeRateMantissa = _initialExchangeRateMantissa;

        return(uint(Error.NO_ERROR));
    }

    function _setInitialReserveFactorMantissa(uint _initialReserveFactorMantissa) external returns (uint) {
        if (msg.sender != getAdmin()) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SET_NEW_RESERVE_FACTOR);
        }

        initialReserveFactorMantissa = _initialReserveFactorMantissa;

        return(uint(Error.NO_ERROR));
    }

    function _setPTokenDecimals(uint _decimals) external returns (uint) {
        if (msg.sender != getAdmin()) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SET_NEW_DECIMALS);
        }

        decimals = uint8(_decimals);

        return(uint(Error.NO_ERROR));
    }

    function _addBlackList(address _underlying) public returns (uint) {
        if (msg.sender != getAdmin()) {
            return fail(Error.UNAUTHORIZED, FailureInfo.ADD_UNDERLYING_TO_BLACKLIST);
        }

        isUnderlyingBlackListed[_underlying] = true;

        emit AddedBlackList(_underlying);

        return(uint(Error.NO_ERROR));
    }

    function _removeBlackList(address _underlying) public returns (uint) {
        if (msg.sender != getAdmin()) {
            return fail(Error.UNAUTHORIZED, FailureInfo.REMOVE_UNDERLYING_FROM_BLACKLIST);
        }

        isUnderlyingBlackListed[_underlying] = false;

        emit RemovedBlackList(_underlying);

        return(uint(Error.NO_ERROR));
    }

    function getBlackListStatus(address underlying_) public view returns (bool) {
        return isUnderlyingBlackListed[underlying_];
    }

    /**
     *  Sets fee for create pool in pies
     *  @return uint 0 = success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function _setCreatePoolFeeAmount(uint createPoolFeeAmount_) external returns(uint) {
        if (msg.sender != getAdmin()) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SET_NEW_CREATE_POOL_FEE_AMOUNT);
        }
        createPoolFeeAmount = createPoolFeeAmount_;

        return(uint(Error.NO_ERROR));
    }

    function _withdrawERC20(address token_, address recipient_) external returns(uint) {
        if (msg.sender != getAdmin()) {
            return fail(Error.UNAUTHORIZED, FailureInfo.WITHDRAW_ERC20);
        }

        EIP20Interface(token_).transfer(recipient_, EIP20Interface(token_).balanceOf(address(this)));

        return(uint(Error.NO_ERROR));
    }

    function getAdmin() public view returns(address) {
        return RegistryInterface(registry).admin();
    }

    function getOracle() public view returns (PriceOracle) {
        return PriceOracle(RegistryInterface(registry).oracle());
    }

    function _createPTokenNameAndSymbol(address underlying_, uint underlyingType_) internal view returns (string memory, string memory) {
        if (underlyingType_ == uint(IPriceOracle.UnderlyingType.RegularAsset)) {
            return _createPTokenNameAndSymbolForAsset(underlying_);
        } else if (underlyingType_ == uint(IPriceOracle.UnderlyingType.UniswapV2LP)) {
            return _createPTokenNameAndSymbolForUniswapV2LP(underlying_);
        } else {
            return ("","");
        }
    }

    function _createPTokenNameAndSymbolForAsset(address underlying_) internal view returns (string memory, string memory) {
        string memory name = string(abi.encodePacked("DeFiPie ", EIP20Interface(underlying_).name()));
        string memory symbol = string(abi.encodePacked("p", EIP20Interface(underlying_).symbol()));
        return (name, symbol);
    }

    function _createPTokenNameAndSymbolForUniswapV2LP(address underlying_) internal view returns (string memory, string memory) {
        IUniswapV2Pair pool = IUniswapV2Pair(underlying_);

        address token0 = pool.token0();
        address token1 = pool.token1();

        string memory symbol0 = EIP20Interface(token0).symbol();
        string memory symbol1 = EIP20Interface(token1).symbol();

        string memory name = string(abi.encodePacked("DeFiPie uniLP ", symbol0, "-", symbol1));
        string memory symbol = string(abi.encodePacked("pUniLP", symbol0, "-", symbol1));
        return (name, symbol);
    }

    function calcExchangeRate(uint power) internal view returns (uint) {
        uint factor;

        if (decimals >= power) {
            factor = 10**(decimals - power);
            return initialExchangeRateMantissa.div(factor);
        } else {
            factor = 10**(power - decimals);
            return initialExchangeRateMantissa.mul(factor);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "../Oracles/PriceOracle.sol";

abstract contract ControllerInterface {
    /// @notice Indicator that this is a Controller contract (for inspection)
    bool public constant isController = true;

    /*** Assets You Are In ***/

    function enterMarkets(address[] calldata pTokens) external virtual returns (uint[] memory);
    function exitMarket(address pToken) external virtual returns (uint);

    /*** Policy Hooks ***/

    function mintAllowed(address pToken, address minter, uint mintAmount) external virtual returns (uint);
    function redeemAllowed(address pToken, address redeemer, uint redeemTokens) external virtual returns (uint);
    function redeemVerify(address pToken, address redeemer, uint redeemAmount, uint redeemTokens) external virtual;
    function borrowAllowed(address pToken, address borrower, uint borrowAmount) external virtual returns (uint);

    function repayBorrowAllowed(
        address pToken,
        address payer,
        address borrower,
        uint repayAmount) external virtual returns (uint);

    function liquidateBorrowAllowed(
        address pTokenBorrowed,
        address pTokenCollateral,
        address liquidator,
        address borrower,
        uint repayAmount) external virtual returns (uint);

    function seizeAllowed(
        address pTokenCollateral,
        address pTokenBorrowed,
        address liquidator,
        address borrower,
        uint seizeTokens) external virtual returns (uint);

    function transferAllowed(address pToken, address src, address dst, uint transferTokens) external virtual returns (uint);

    /*** Liquidity/Liquidation Calculations ***/

    function liquidateCalculateSeizeTokens(
        address pTokenBorrowed,
        address pTokenCollateral,
        uint repayAmount) external view virtual returns (uint, uint);

    function getOracle() external view virtual returns (PriceOracle);
    function _setFeeFactor(address pToken, uint newFeeFactorMantissa) external virtual returns (uint);
    function getFeeFactorMantissa(address pToken) public view virtual returns (uint);
    function getBorrowDelay() public view virtual returns (uint);
    function checkIsListed(address pToken) external view virtual returns (bool);
    function getAllMarkets() public view virtual returns (address[] memory);
    function setFreezePoolAmount(address pToken, uint amount) public virtual;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

/**
  * @title DeFiPie's InterestRateModel Interface
  * @author DeFiPie
  */
abstract contract InterestRateModel {
    /// @notice Indicator that this is an InterestRateModel contract (for inspection)
    bool public constant isInterestRateModel = true;

    /**
      * @notice Calculates the current borrow interest rate per block
      * @param cash The total amount of cash the market has
      * @param borrows The total amount of borrows the market has outstanding
      * @param reserves The total amount of reserves the market has
      * @return The borrow rate per block (as a percentage, and scaled by 1e18)
      */
    function getBorrowRate(uint cash, uint borrows, uint reserves) external view virtual returns (uint);

    /**
      * @notice Calculates the current supply interest rate per block
      * @param cash The total amount of cash the market has
      * @param borrows The total amount of borrows the market has outstanding
      * @param reserves The total amount of reserves the market has
      * @param reserveFactorMantissa The current reserve factor the market has
      * @return The supply rate per block (as a percentage, and scaled by 1e18)
      */
    function getSupplyRate(uint cash, uint borrows, uint reserves, uint reserveFactorMantissa) external view virtual returns (uint);

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./RegistryInterface.sol";

contract ProxyWithRegistryStorage {

    /**
     * @notice Address of the registry contract
     */
    address public registry;
}

abstract contract ProxyWithRegistryInterface is ProxyWithRegistryStorage {
    function _setRegistry(address _registry) internal virtual;
    function _pTokenImplementation() internal view virtual returns (address);
}

contract ProxyWithRegistry is ProxyWithRegistryInterface {
    /**
     *  Returns actual address of the implementation contract from current registry
     *  @return registry Address of the registry
     */
    function _pTokenImplementation() internal view override returns (address) {
        return RegistryInterface(registry).pTokenImplementation();
    }

    function _setRegistry(address _registry) internal override {
        registry = _registry;
    }
}

contract ImplementationStorage {

    address public implementation;

    function _setImplementationInternal(address implementation_) internal {
        implementation = implementation_;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import '../RegistryInterface.sol';
import "../ErrorReporter.sol";
import "./Interfaces/IPriceFeeds.sol";
import "./Interfaces/IPriceOracle.sol";
import "../Tokens/PTokenInterfaces.sol";
import "../Tokens/EIP20Interface.sol";
import "../SafeMath.sol";
import "./UniswapCommon.sol";
import "./PriceOracleProxy.sol";
import "../Control/Controller.sol";
import "../PTokenFactory.sol";

contract PriceOracle is PriceOracleProxyStorage, IPriceOracle, OracleErrorReporter {
    using SafeMath for uint;

    address public ETHUSDPriceFeed;

    address[] public priceOracles;

    mapping(address => address) public assetOracle;

    mapping(address => uint) public underlyingType;

    event OracleAdded(uint oracleId, address oracle);
    event OracleRemoved(uint oracleId, address oracle);
    event OracleUpdated(uint oracleId, address oracle);

    event PriceUpdated(address oracle, address asset, uint price);
    event AssetOracleUpdated(address oracle, address asset);

    function initialize(
        address ETHUSDPriceFeed_
    ) public {
        require(
            ETHUSDPriceFeed == address(0),
            "Oracle: may only be initialized once"
        );

        require(
            ETHUSDPriceFeed_ != address(0),
            "Oracle: address is not correct"
        );

        ETHUSDPriceFeed = ETHUSDPriceFeed_;
    }

    function updateUnderlyingPrice(address pToken) external override returns (uint) {
        if (pToken == RegistryInterface(registry).pETH()) {
            return uint(Error.NO_ERROR);
        }

        address asset = PErc20Interface(pToken).underlying();

        return update(asset);
    }

    function update(address asset) public returns (uint) {
        address oracle = assetOracle[asset];

        if (oracle == address(0)) {
            (oracle,,) = searchPair(asset);
        }

        if (oracle != address(0)) {
            if (assetOracle[asset] == address(0)) {
                assetOracle[asset] = oracle;
                emit AssetOracleUpdated(oracle, asset);
            }

            uint result = UniswapCommon(oracle).update(asset);

            if (result == uint(Error.NO_ERROR)) {
                emit PriceUpdated(oracle, asset, UniswapCommon(oracle).getCourseInETH(asset));
            }

            return result;
        }

        return fail(Error.UPDATE_PRICE, FailureInfo.NO_PAIR);
    }

    function reSearchPair(address asset) public returns (uint) {
        (address oracle,,) = searchPair(asset);

        if (oracle != address(0) && oracle != assetOracle[asset]) {
            assetOracle[asset] = oracle;
        }

        UniswapCommon(oracle).reSearchPair(asset);

        return update(asset);
    }

    function getPriceInUSD(address asset) public view virtual returns (uint) {
        uint ETHUSDPrice = uint(AggregatorInterface(ETHUSDPriceFeed).latestAnswer());
        uint AssetETHCourse = getPriceInETH(asset);

        // div 1e8 is chainlink precision for ETH
        return ETHUSDPrice.mul(AssetETHCourse).div(1e8);
    }

    function getPriceInETH(address asset) public view returns(uint) {
        if (asset == RegistryInterface(registry).pETH()) {
            // ether always worth 1
            return 1e18;
        }

        address oracle = assetOracle[asset];
        if (oracle == address(0)) {
            return 0;
        }

        return UniswapCommon(oracle).getCourseInETH(asset);
    }

    function getUnderlyingPrice(address pToken) public view override virtual returns (uint) {
        if (pToken == RegistryInterface(registry).pETH()) {
            return getPriceInUSD(pToken);
        }

        address asset = PErc20Interface(pToken).underlying();
        uint price = getPriceInUSD(asset);
        uint decimals = EIP20Interface(asset).decimals();

        return price.mul(10 ** (36 - decimals)).div(1e18);
    }

    function searchPair(address asset) public view returns (address, address, uint112) {
        address pair;
        uint112 liquidity;
        address maxLiquidityPair;
        uint112 maxLiquidity;
        address oracle;

        for(uint i = 0; i < priceOracles.length; i++) {
            (pair, liquidity) = UniswapCommon(priceOracles[i]).searchPair(asset);

            if (pair != address(0) && liquidity > maxLiquidity) {
                maxLiquidityPair = pair;
                maxLiquidity = liquidity;
                oracle = priceOracles[i];
            }
        }

        return (oracle, maxLiquidityPair, maxLiquidity);
    }

    function getMyAdmin() public view returns (address) {
        return RegistryInterface(registry).admin();
    }

    function isPeriodElapsed(address asset) public view returns (bool) {
        if (isNewAsset(asset)) {
            return true;
        }

        return UniswapCommon(assetOracle[asset]).isPeriodElapsed(asset);
    }

    function _addOracle(address oracle_) public returns (uint) {
        // Check caller = admin
        if (msg.sender != getMyAdmin()) {
            return fail(Error.UNAUTHORIZED, FailureInfo.ADD_ORACLE);
        }

        require(
            oracle_ != address(0)
            , 'PriceOracle: invalid address for oracle'
        );

        for (uint i = 0; i < priceOracles.length; i++) {
            if (priceOracles[i] == oracle_) {
                return fail(Error.ORACLE_EXIST, FailureInfo.ADD_ORACLE);
            }
        }

        priceOracles.push(oracle_);

        emit OracleAdded(priceOracles.length - 1, oracle_);

        return uint(Error.NO_ERROR);
    }

    function _removeOracle(uint oracleId) public returns (uint) {
        // Check caller = admin
        if (msg.sender != getMyAdmin()) {
            return fail(Error.UNAUTHORIZED, FailureInfo.UPDATE_DATA);
        }

        require(
            priceOracles.length > oracleId
            , 'PriceOracle: oracleId is not correct'
        );

        uint lastId = priceOracles.length - 1;

        address lastOracle = priceOracles[lastId];
        priceOracles.pop();
        emit OracleRemoved(oracleId, lastOracle);

        if (lastId != oracleId) {
            priceOracles[oracleId] = lastOracle;
            emit OracleUpdated(oracleId, lastOracle);
        }

        return uint(Error.NO_ERROR);
    }

    function _updateOracle(uint oracleId, address oracle_) public returns (uint) {
        // Check caller = admin
        if (msg.sender != getMyAdmin()) {
            return fail(Error.UNAUTHORIZED, FailureInfo.UPDATE_DATA);
        }

        require(
            oracle_ != address(0)
            , 'PriceOracle: invalid address for oracle_'
        );

        for (uint i = 0; i < priceOracles.length; i++) {
            if (priceOracles[i] == oracle_) {
                return fail(Error.ORACLE_EXIST, FailureInfo.ADD_ORACLE);
            }
        }

        priceOracles[oracleId] = oracle_;

        emit OracleUpdated(oracleId, oracle_);

        return uint(Error.NO_ERROR);
    }

    function _updateAssetOracle(address oracle, address asset) public returns (uint) {
        // Check caller = admin
        if (msg.sender != getMyAdmin()) {
            return fail(Error.UNAUTHORIZED, FailureInfo.UPDATE_DATA);
        }

        require(
            oracle != address(0)
            && asset != address(0)
            , 'Oracle: invalid address oracle or asset'
        );

        assetOracle[asset] = oracle;

        emit AssetOracleUpdated(oracle, asset);

        return update(asset);
    }

    function checkAndUpdateAllNewAssets() public {
        PTokenFactory factory = PTokenFactory(RegistryInterface(registry).factory());
        Controller controller = Controller(factory.controller());

        address[] memory allMarkets = Controller(controller).getAllMarkets();

        updateNewAssets(allMarkets);
    }

    function updateNewAssets(address[] memory pTokens) public {
        address asset;

        for(uint i = 0; i < pTokens.length; i++) {
            if (pTokens[i] == RegistryInterface(registry).pETH()) {
                continue;
            }

            asset = PErc20Interface(pTokens[i]).underlying();

            if (isNewAsset(asset)) {
                update(asset);
            }
        }
    }

    function isNewAsset(address asset) public view returns (bool) {
        return bool(assetOracle[asset] == address(0));
    }

    function getAllPriceOracles() public view returns (address[] memory) {
        return priceOracles;
    }

    function getPriceOraclesLength() public view returns (uint) {
        return priceOracles.length;
    }

    /**
     * @notice Returns the type of the asset with maximum liquidity
     * @param asset Address of the underlying asset
     * @return uint112 Liquidity of the asset
     */
    function getLiquidity(address asset) public view returns (uint112) {
        uint112 liquidity;
        uint112 maxLiquidity;

        for(uint i = 0; i < priceOracles.length; i++) {
            
            liquidity = UniswapCommon(priceOracles[i]).getLiquidity(asset);

            if (liquidity > maxLiquidity) {
                maxLiquidity = liquidity;
            }
        }

        return (maxLiquidity);
    }

    function setUnderlyingType(address asset, uint type_) public {
        require(msg.sender == RegistryInterface(registry).factory() || msg.sender == getMyAdmin(), 'PriceOracle: only factory or admin');

        underlyingType[asset] = type_;
    }

    function getUnderlyingType(address asset) public view returns (uint) {
        if (asset == RegistryInterface(registry).pETH()) {
            return uint(UnderlyingType.RegularAsset);
        }

        return underlyingType[asset];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

library SafeCast {
    /// @notice Cast a uint256 to a uint128, revert on overflow
    /// @param y The uint256 to be downcasted
    /// @return z The downcasted integer, now type uint128
    function toUint128(uint256 y) internal pure returns (uint128 z) {
        require((z = uint128(y)) == y);
    }

    /// @notice Cast a uint256 to a uint32, revert on overflow
    /// @param y The uint256 to be downcasted
    /// @return z The downcasted integer, now type uint32
    function toUint32(uint256 y) internal pure returns (uint32 z) {
        require((z = uint32(y)) == y);
    }
}

interface AggregatorInterface {
    function latestAnswer() external view returns (int256);
}

library UQ112x112 {
    uint224 constant Q112 = 2**112;

    // encode a uint112 as a UQ112x112
    function encode(uint112 y) internal pure returns (uint224 z) {
        z = uint224(y) * Q112; // never overflows
    }

    // divide a UQ112x112 by a uint112, returning a UQ112x112
    function uqdiv(uint224 x, uint112 y) internal pure returns (uint224 z) {
        z = x / uint224(y);
    }
}

library FixedPoint {
    // range: [0, 2**112 - 1]
    // resolution: 1 / 2**112
    struct uq112x112 {
        uint224 _x;
    }

    // range: [0, 2**144 - 1]
    // resolution: 1 / 2**112
    struct uq144x112 {
        uint _x;
    }

    uint8 private constant RESOLUTION = 112;

    // multiply a UQ112x112 by a uint, returning a UQ144x112
    // reverts on overflow
    function mul(uq112x112 memory self, uint y) internal pure returns (uq144x112 memory) {
        uint z;
        require(y == 0 || (z = uint(self._x) * y) / y == uint(self._x), "FixedPoint: MULTIPLICATION_OVERFLOW");
        return uq144x112(z);
    }

    // decode a UQ144x112 into a uint144 by truncating after the radix point
    function decode144(uq144x112 memory self) internal pure returns (uint144) {
        return uint144(self._x >> RESOLUTION);
    }
}

interface IUniswapV2Pair {
    function token0() external view returns (address);
    function token1() external view returns (address);
    function factory() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function totalSupply() external view returns (uint);
}

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

/**
 * @title PriceOracle's Interface
 */
interface IPriceOracle {

    /// @notice Possible underlying types of an asset
    enum UnderlyingType {
        BadUnderlying,
        RegularAsset,
        UniswapV2LP
    }

    /**
     * @notice Get the underlying price of a pToken asset
     * @param pToken The pToken to get the underlying price of
     * @return The underlying asset price mantissa (scaled by 1e18).
     *  Zero means the price is unavailable.
     */
    function getUnderlyingPrice(address pToken) external view returns (uint);

    function updateUnderlyingPrice(address pToken) external returns (uint);

    function getUnderlyingType(address asset) external view returns (uint);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

/**
 * @title ERC 20 Token Standard Interface
 *  https://eips.ethereum.org/EIPS/eip-20
 */
interface EIP20Interface {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);

    /**
      * @notice Get the total number of tokens in circulation
      * @return The supply of tokens
      */
    function totalSupply() external view returns (uint256);

    /**
     * @notice Gets the balance of the specified address
     * @param owner The address from which the balance will be retrieved
     * @return The balance
     */
    function balanceOf(address owner) external view returns (uint256);

    /**
      * @notice Transfer `amount` tokens from `msg.sender` to `dst`
      * @param dst The address of the destination account
      * @param amount The number of tokens to transfer
      * @return Whether or not the transfer succeeded
      */
    function transfer(address dst, uint256 amount) external returns (bool);

    /**
      * @notice Transfer `amount` tokens from `src` to `dst`
      * @param src The address of the source account
      * @param dst The address of the destination account
      * @param amount The number of tokens to transfer
      * @return Whether or not the transfer succeeded
      */
    function transferFrom(address src, address dst, uint256 amount) external returns (bool);

    /**
      * @notice Approve `spender` to transfer up to `amount` from `src`
      * @dev This will overwrite the approval amount for `spender`
      *  and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
      * @param spender The address of the account which may transfer tokens
      * @param amount The number of tokens that are approved (-1 means infinite)
      * @return Whether or not the approval succeeded
      */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
      * @notice Get the current allowance from `owner` for `spender`
      * @param owner The address of the account which owns the tokens to be spent
      * @param spender The address of the account which may transfer tokens
      * @return The number of tokens allowed to be spent (-1 means infinite)
      */
    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

// From https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/math/Math.sol
// Subject to the MIT license.

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        unchecked {
            uint256 c = a + b;
            require(c >= a, "SafeMath: addition overflow");

            return c;
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting with custom message on overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            uint256 c = a + b;
            require(c >= a, errorMessage);

            return c;
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on underflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot underflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction underflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on underflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot underflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            uint256 c = a - b;

            return c;
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        unchecked {
            if (a == 0) {
                return 0;
            }

            uint256 c = a * b;
            require(c / a == b, "SafeMath: multiplication overflow");

            return c;
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        unchecked { 
            if (a == 0) {
                return 0;
            }

            uint256 c = a * b;
            require(c / a == b, errorMessage);

            return c;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers.
     * Reverts on division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        unchecked {
            return div(a, b, "SafeMath: division by zero");
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers.
     * Reverts with custom message on division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        unchecked {
            require(b > 0, errorMessage);
            uint256 c = a / b;
            // assert(a == b * c + a % b); // There is no case in which this doesn't hold

            return c;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }

    // implementation from https://github.com/Uniswap/uniswap-lib/commit/99f3f28770640ba1bb1ff460ac7c5292fb8291a0
    // original implementation: https://github.com/abdk-consulting/abdk-libraries-solidity/blob/master/ABDKMath64x64.sol#L687
    function sqrt(uint256 x) internal pure returns (uint256) {
        if (x == 0) return 0;
        uint256 xx = x;
        uint256 r = 1;

        if (xx >= 0x100000000000000000000000000000000) {
            xx >>= 128;
            r <<= 64;
        }
        if (xx >= 0x10000000000000000) {
            xx >>= 64;
            r <<= 32;
        }
        if (xx >= 0x100000000) {
            xx >>= 32;
            r <<= 16;
        }
        if (xx >= 0x10000) {
            xx >>= 16;
            r <<= 8;
        }
        if (xx >= 0x100) {
            xx >>= 8;
            r <<= 4;
        }
        if (xx >= 0x10) {
            xx >>= 4;
            r <<= 2;
        }
        if (xx >= 0x8) {
            r <<= 1;
        }

        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1; // Seven iterations should be enough
        uint256 r1 = x / r;
        return (r < r1 ? r : r1);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "../ErrorReporter.sol";
import "../RegistryInterface.sol";
import "../Tokens/PTokenInterfaces.sol";

contract UniswapProxyStorage {
    address public implementation;
    address public registry;
}

contract UniswapCommonStorage {
    address public WETHToken;
    address public priceOracle;
    
    uint public period;

    // asset => pair with reserves
    mapping(address => address) public assetPair;

    address[] public poolFactories;
    address[] public stableCoins;

    uint public minReserveLiquidity;
}

abstract contract UniswapCommon is UniswapProxyStorage, UniswapCommonStorage, OracleErrorReporter  {
    event PoolAdded(uint id, address poolFactory);
    event PoolRemoved(uint id, address poolFactory);
    event PoolUpdated(uint id, address poolFactory);

    event StableCoinAdded(uint id, address coin);
    event StableCoinRemoved(uint id, address coin);
    event StableCoinUpdated(uint id, address coin);

    event PriceUpdated(address asset, uint price); // price in eth

    function getCourseInETH(address asset) public view virtual returns (uint);

    function update(address asset) public virtual returns(uint);

    function searchPair(address asset) public view virtual returns (address, uint112);

    function reSearchPair(address asset) public virtual returns (uint);

    function isPeriodElapsed(address asset) public view virtual returns (bool);

    function getLiquidity(address asset) public view virtual returns (uint112);

    function getMyAdmin() public view returns (address) {
        return RegistryInterface(registry).admin();
    }

    function _setNewWETHAddress(address WETHToken_) external returns (uint) {
        // Check caller = admin
        if (msg.sender != getMyAdmin()) {
            return fail(Error.UNAUTHORIZED, FailureInfo.UPDATE_DATA);
        }

        WETHToken = WETHToken_;

        return uint(Error.NO_ERROR);
    }

    function _setNewRegistry(address registry_) external returns (uint) {
        // Check caller = admin
        if (msg.sender != getMyAdmin()) {
            return fail(Error.UNAUTHORIZED, FailureInfo.UPDATE_DATA);
        }

        registry = registry_;

        return uint(Error.NO_ERROR);
    }

    function _setNewPriceOracle(address priceOracle_) external returns (uint) {
        // Check caller = admin
        if (msg.sender != getMyAdmin()) {
            return fail(Error.UNAUTHORIZED, FailureInfo.UPDATE_DATA);
        }

        priceOracle = priceOracle_;

        return uint(Error.NO_ERROR);
    }

    function _setPeriod(uint period_) public returns (uint) {
        // Check caller = admin
        if (msg.sender != getMyAdmin()) {
            return fail(Error.UNAUTHORIZED, FailureInfo.UPDATE_DATA);
        }

        period = period_;

        return uint(Error.NO_ERROR);
    }

    function _setMinReserveLiquidity(uint minReserveLiquidity_) public returns (uint) {
        if (msg.sender != getMyAdmin()) {
            return fail(Error.UNAUTHORIZED, FailureInfo.UPDATE_DATA);
        }

        minReserveLiquidity = minReserveLiquidity_;

        return uint(Error.NO_ERROR);
    }

    function _addPool(address poolFactory_) public returns (uint) {
        // Check caller = admin
        if (msg.sender != getMyAdmin()) {
            return fail(Error.UNAUTHORIZED, FailureInfo.ADD_POOL_OR_COIN);
        }

        require(
            poolFactory_ != address(0)
        , 'Oracle: invalid address for factory'
        );

        for (uint i = 0; i < poolFactories.length; i++) {
            if (poolFactories[i] == poolFactory_) {
                return fail(Error.POOL_OR_COIN_EXIST, FailureInfo.ADD_POOL_OR_COIN);
            }
        }

        poolFactories.push(poolFactory_);
        uint poolId = poolFactories.length - 1;

        emit PoolAdded(poolId, poolFactory_);

        return uint(Error.NO_ERROR);
    }

    function _removePool(uint poolId) public returns (uint) {
        // Check caller = admin
        if (msg.sender != getMyAdmin()) {
            return fail(Error.UNAUTHORIZED, FailureInfo.UPDATE_DATA);
        }

        require(
            poolFactories.length > 1
        , 'Oracle: must have one pool'
        );

        uint lastId = poolFactories.length - 1;

        address factory = poolFactories[lastId];
        poolFactories.pop();
        emit PoolRemoved(lastId, factory);

        if (lastId != poolId) {
            poolFactories[poolId] = factory;
            emit PoolUpdated(poolId, factory);
        }

        return uint(Error.NO_ERROR);
    }

    function _updatePool(uint poolId, address poolFactory_) public returns (uint) {
        // Check caller = admin
        if (msg.sender != getMyAdmin()) {
            return fail(Error.UNAUTHORIZED, FailureInfo.UPDATE_DATA);
        }

        require(
            poolFactory_ != address(0)
            , 'Oracle: invalid address for factory'
        );

        for (uint i = 0; i < poolFactories.length; i++) {
            if (poolFactories[i] == poolFactory_) {
                return fail(Error.POOL_OR_COIN_EXIST, FailureInfo.UPDATE_DATA);
            }
        }

        poolFactories[poolId] = poolFactory_;

        emit PoolUpdated(poolId, poolFactory_);

        return uint(Error.NO_ERROR);
    }

    function _addStableCoin(address stableCoin_) public returns (uint) {
        // Check caller = admin
        if (msg.sender != getMyAdmin()) {
            return fail(Error.UNAUTHORIZED, FailureInfo.ADD_POOL_OR_COIN);
        }

        require(
            stableCoin_ != address(0)
            , 'Oracle: invalid address for stable coin'
        );

        for (uint i = 0; i < stableCoins.length; i++) {
            if (stableCoins[i] == stableCoin_) {
                return fail(Error.POOL_OR_COIN_EXIST, FailureInfo.ADD_POOL_OR_COIN);
            }
        }

        stableCoins.push(stableCoin_);

        emit StableCoinAdded(stableCoins.length - 1, stableCoin_);

        return uint(Error.NO_ERROR);
    }

    function _removeStableCoin(uint coinId) public returns (uint) {
        // Check caller = admin
        if (msg.sender != getMyAdmin()) {
            return fail(Error.UNAUTHORIZED, FailureInfo.UPDATE_DATA);
        }

        require(
            stableCoins.length > coinId
        , 'Oracle: stable coins are empty'
        );


        uint lastId = stableCoins.length - 1;

        address stableCoin = stableCoins[lastId];
        stableCoins.pop();
        emit StableCoinRemoved(lastId, stableCoin);

        if (lastId != coinId) {
            stableCoins[coinId] = stableCoin;
            emit StableCoinUpdated(coinId, stableCoin);
        }

        return uint(Error.NO_ERROR);
    }

    function _updateStableCoin(uint coinId, address stableCoin_) public returns (uint) {
        // Check caller = admin
        if (msg.sender != getMyAdmin()) {
            return fail(Error.UNAUTHORIZED, FailureInfo.UPDATE_DATA);
        }

        require(
            stableCoin_ != address(0)
        , 'Oracle: invalid address for stable coin'
        );

        for (uint i = 0; i < stableCoins.length; i++) {
            if (stableCoins[i] == stableCoin_) {
                return fail(Error.POOL_OR_COIN_EXIST, FailureInfo.UPDATE_DATA);
            }
        }

        stableCoins[coinId] = stableCoin_;

        emit StableCoinUpdated(coinId, stableCoin_);

        return uint(Error.NO_ERROR);
    }

    function getAllPoolFactories() public view returns (address[] memory) {
        return poolFactories;
    }

    function getAllStableCoins() public view returns (address[] memory) {
        return stableCoins;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "../ErrorReporter.sol";
import "../RegistryInterface.sol";
import "./PriceOracle.sol";

contract PriceOracleProxyStorage {
    address public implementation;
    address public registry;
}

contract PriceOracleProxy is PriceOracleProxyStorage, OracleErrorReporter {

    /**
      * @notice Emitted when implementation is changed
      */
    event NewImplementation(address oldImplementation, address newImplementation);

    constructor(
        address implementation_,
        address registry_,
        address ethPriceFeed_
    ) {
        implementation = implementation_;
        registry = registry_;

        delegateTo(implementation, abi.encodeWithSignature("initialize(address)", ethPriceFeed_));
    }

    function _setOracleImplementation(address newImplementation) external returns(uint256) {
        if (msg.sender != RegistryInterface(registry).admin()) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SET_NEW_IMPLEMENTATION);
        }

        address oldImplementation = implementation;
        implementation = newImplementation;

        emit NewImplementation(oldImplementation, implementation);

        return(uint(Error.NO_ERROR));
    }

    /**
     * @notice Internal method to delegate execution to another contract
     * @dev It returns to the external caller whatever the implementation returns or forwards reverts
     * @param callee The contract to delegatecall
     * @param data The raw data to delegatecall
     * @return The returned bytes from the delegatecall
     */
    function delegateTo(address callee, bytes memory data) internal returns (bytes memory) {
        (bool success, bytes memory returnData) = callee.delegatecall(data);
        assembly {
            if eq(success, 0) {
                revert(add(returnData, 0x20), returndatasize())
            }
        }
        return returnData;
    }

    function delegateAndReturn() internal returns (bytes memory) {
        (bool success, ) = implementation.delegatecall(msg.data);

        assembly {
            let free_mem_ptr := mload(0x40)
            returndatacopy(free_mem_ptr, 0, returndatasize())

            switch success
            case 0 { revert(free_mem_ptr, returndatasize()) }
            default { return(free_mem_ptr, returndatasize()) }
        }
    }

    /**
     * @notice Delegates execution to an implementation contract
     * @dev It returns to the external caller whatever the implementation returns or forwards reverts
     */
    fallback() external {
        // delegate all other functions to current implementation
        delegateAndReturn();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./CarefulMath.sol";

/**
 * @title Exponential module for storing fixed-precision decimals
 * @author DeFiPie
 * @notice Exp is a struct which stores decimals with a fixed precision of 18 decimal places.
 *         Thus, if we wanted to store the 5.1, mantissa would store 5.1e18. That is:
 *         `Exp({mantissa: 5100000000000000000})`.
 */
contract Exponential is CarefulMath {
    uint constant expScale = 1e18;
    uint constant doubleScale = 1e36;
    uint constant halfExpScale = expScale/2;
    uint constant mantissaOne = expScale;

    struct Exp {
        uint mantissa;
    }

    struct Double {
        uint mantissa;
    }

    /**
     * @dev Creates an exponential from numerator and denominator values.
     *      Note: Returns an error if (`num` * 10e18) > MAX_INT,
     *            or if `denom` is zero.
     */
    function getExp(uint num, uint denom) pure internal returns (MathError, Exp memory) {
        (MathError err0, uint scaledNumerator) = mulUInt(num, expScale);
        if (err0 != MathError.NO_ERROR) {
            return (err0, Exp({mantissa: 0}));
        }

        (MathError err1, uint rational) = divUInt(scaledNumerator, denom);
        if (err1 != MathError.NO_ERROR) {
            return (err1, Exp({mantissa: 0}));
        }

        return (MathError.NO_ERROR, Exp({mantissa: rational}));
    }

    /**
     * @dev Adds two exponentials, returning a new exponential.
     */
    function addExp(Exp memory a, Exp memory b) pure internal returns (MathError, Exp memory) {
        (MathError error, uint result) = addUInt(a.mantissa, b.mantissa);

        return (error, Exp({mantissa: result}));
    }

    /**
     * @dev Subtracts two exponentials, returning a new exponential.
     */
    function subExp(Exp memory a, Exp memory b) pure internal returns (MathError, Exp memory) {
        (MathError error, uint result) = subUInt(a.mantissa, b.mantissa);

        return (error, Exp({mantissa: result}));
    }

    /**
     * @dev Multiply an Exp by a scalar, returning a new Exp.
     */
    function mulScalar(Exp memory a, uint scalar) pure internal returns (MathError, Exp memory) {
        (MathError err0, uint scaledMantissa) = mulUInt(a.mantissa, scalar);
        if (err0 != MathError.NO_ERROR) {
            return (err0, Exp({mantissa: 0}));
        }

        return (MathError.NO_ERROR, Exp({mantissa: scaledMantissa}));
    }

    /**
     * @dev Multiply an Exp by a scalar, then truncate to return an unsigned integer.
     */
    function mulScalarTruncate(Exp memory a, uint scalar) pure internal returns (MathError, uint) {
        (MathError err, Exp memory product) = mulScalar(a, scalar);
        if (err != MathError.NO_ERROR) {
            return (err, 0);
        }

        return (MathError.NO_ERROR, truncate(product));
    }

    /**
     * @dev Multiply an Exp by a scalar, truncate, then add an to an unsigned integer, returning an unsigned integer.
     */
    function mulScalarTruncateAddUInt(Exp memory a, uint scalar, uint addend) pure internal returns (MathError, uint) {
        (MathError err, Exp memory product) = mulScalar(a, scalar);
        if (err != MathError.NO_ERROR) {
            return (err, 0);
        }

        return addUInt(truncate(product), addend);
    }

    /**
     * @dev Divide an Exp by a scalar, returning a new Exp.
     */
    function divScalar(Exp memory a, uint scalar) pure internal returns (MathError, Exp memory) {
        (MathError err0, uint descaledMantissa) = divUInt(a.mantissa, scalar);
        if (err0 != MathError.NO_ERROR) {
            return (err0, Exp({mantissa: 0}));
        }

        return (MathError.NO_ERROR, Exp({mantissa: descaledMantissa}));
    }

    /**
     * @dev Divide a scalar by an Exp, returning a new Exp.
     */
    function divScalarByExp(uint scalar, Exp memory divisor) pure internal returns (MathError, Exp memory) {
        /*
          We are doing this as:
          getExp(mulUInt(expScale, scalar), divisor.mantissa)

          How it works:
          Exp = a / b;
          Scalar = s;
          `s / (a / b)` = `b * s / a` and since for an Exp `a = mantissa, b = expScale`
        */
        (MathError err0, uint numerator) = mulUInt(expScale, scalar);
        if (err0 != MathError.NO_ERROR) {
            return (err0, Exp({mantissa: 0}));
        }
        return getExp(numerator, divisor.mantissa);
    }

    /**
     * @dev Divide a scalar by an Exp, then truncate to return an unsigned integer.
     */
    function divScalarByExpTruncate(uint scalar, Exp memory divisor) pure internal returns (MathError, uint) {
        (MathError err, Exp memory fraction_) = divScalarByExp(scalar, divisor);
        if (err != MathError.NO_ERROR) {
            return (err, 0);
        }

        return (MathError.NO_ERROR, truncate(fraction_));
    }

    /**
     * @dev Multiplies two exponentials, returning a new exponential.
     */
    function mulExp(Exp memory a, Exp memory b) pure internal returns (MathError, Exp memory) {

        (MathError err0, uint doubleScaledProduct) = mulUInt(a.mantissa, b.mantissa);
        if (err0 != MathError.NO_ERROR) {
            return (err0, Exp({mantissa: 0}));
        }

        // We add half the scale before dividing so that we get rounding instead of truncation.
        //  See "Listing 6" and text above it at https://accu.org/index.php/journals/1717
        // Without this change, a result like 6.6...e-19 will be truncated to 0 instead of being rounded to 1e-18.
        (MathError err1, uint doubleScaledProductWithHalfScale) = addUInt(halfExpScale, doubleScaledProduct);
        if (err1 != MathError.NO_ERROR) {
            return (err1, Exp({mantissa: 0}));
        }

        (MathError err2, uint product) = divUInt(doubleScaledProductWithHalfScale, expScale);
        // The only error `div` can return is MathError.DIVISION_BY_ZERO but we control `expScale` and it is not zero.
        assert(err2 == MathError.NO_ERROR);

        return (MathError.NO_ERROR, Exp({mantissa: product}));
    }

    /**
     * @dev Multiplies two exponentials given their mantissas, returning a new exponential.
     */
    function mulExp(uint a, uint b) pure internal returns (MathError, Exp memory) {
        return mulExp(Exp({mantissa: a}), Exp({mantissa: b}));
    }

    /**
     * @dev Multiplies three exponentials, returning a new exponential.
     */
    function mulExp3(Exp memory a, Exp memory b, Exp memory c) pure internal returns (MathError, Exp memory) {
        (MathError err, Exp memory ab) = mulExp(a, b);
        if (err != MathError.NO_ERROR) {
            return (err, ab);
        }
        return mulExp(ab, c);
    }

    /**
     * @dev Divides two exponentials, returning a new exponential.
     *     (a/scale) / (b/scale) = (a/scale) * (scale/b) = a/b,
     *  which we can scale as an Exp by calling getExp(a.mantissa, b.mantissa)
     */
    function divExp(Exp memory a, Exp memory b) pure internal returns (MathError, Exp memory) {
        return getExp(a.mantissa, b.mantissa);
    }

    /**
     * @dev Truncates the given exp to a whole number value.
     *      For example, truncate(Exp{mantissa: 15 * expScale}) = 15
     */
    function truncate(Exp memory exp) pure internal returns (uint) {
        // Note: We are not using careful math here as we're performing a division that cannot fail
        return exp.mantissa / expScale;
    }

    /**
     * @dev Checks if first Exp is less than second Exp.
     */
    function lessThanExp(Exp memory left, Exp memory right) pure internal returns (bool) {
        return left.mantissa < right.mantissa;
    }

    /**
     * @dev Checks if left Exp <= right Exp.
     */
    function lessThanOrEqualExp(Exp memory left, Exp memory right) pure internal returns (bool) {
        return left.mantissa <= right.mantissa;
    }

    /**
     * @dev Checks if left Exp > right Exp.
     */
    function greaterThanExp(Exp memory left, Exp memory right) pure internal returns (bool) {
        return left.mantissa > right.mantissa;
    }

    /**
     * @dev returns true if Exp is exactly zero
     */
    function isZeroExp(Exp memory value) pure internal returns (bool) {
        return value.mantissa == 0;
    }

    function safe224(uint n, string memory errorMessage) pure internal returns (uint224) {
        require(n < 2**224, errorMessage);
        return uint224(n);
    }

    function safe32(uint n, string memory errorMessage) pure internal returns (uint32) {
        require(n < 2**32, errorMessage);
        return uint32(n);
    }

    function add_(Exp memory a, Exp memory b) pure internal returns (Exp memory) {
        return Exp({mantissa: add_(a.mantissa, b.mantissa)});
    }

    function add_(Double memory a, Double memory b) pure internal returns (Double memory) {
        return Double({mantissa: add_(a.mantissa, b.mantissa)});
    }

    function add_(uint a, uint b) pure internal returns (uint) {
        return add_(a, b, "addition overflow");
    }

    function add_(uint a, uint b, string memory errorMessage) pure internal returns (uint) {
        uint c = a + b;
        require(c >= a, errorMessage);
        return c;
    }

    function sub_(Exp memory a, Exp memory b) pure internal returns (Exp memory) {
        return Exp({mantissa: sub_(a.mantissa, b.mantissa)});
    }

    function sub_(Double memory a, Double memory b) pure internal returns (Double memory) {
        return Double({mantissa: sub_(a.mantissa, b.mantissa)});
    }

    function sub_(uint a, uint b) pure internal returns (uint) {
        return sub_(a, b, "subtraction underflow");
    }

    function sub_(uint a, uint b, string memory errorMessage) pure internal returns (uint) {
        require(b <= a, errorMessage);
        return a - b;
    }

    function mul_(Exp memory a, Exp memory b) pure internal returns (Exp memory) {
        return Exp({mantissa: mul_(a.mantissa, b.mantissa) / expScale});
    }

    function mul_(Exp memory a, uint b) pure internal returns (Exp memory) {
        return Exp({mantissa: mul_(a.mantissa, b)});
    }

    function mul_(uint a, Exp memory b) pure internal returns (uint) {
        return mul_(a, b.mantissa) / expScale;
    }

    function mul_(Double memory a, Double memory b) pure internal returns (Double memory) {
        return Double({mantissa: mul_(a.mantissa, b.mantissa) / doubleScale});
    }

    function mul_(Double memory a, uint b) pure internal returns (Double memory) {
        return Double({mantissa: mul_(a.mantissa, b)});
    }

    function mul_(uint a, Double memory b) pure internal returns (uint) {
        return mul_(a, b.mantissa) / doubleScale;
    }

    function mul_(uint a, uint b) pure internal returns (uint) {
        return mul_(a, b, "multiplication overflow");
    }

    function mul_(uint a, uint b, string memory errorMessage) pure internal returns (uint) {
        if (a == 0 || b == 0) {
            return 0;
        }
        uint c = a * b;
        require(c / a == b, errorMessage);
        return c;
    }

    function div_(Exp memory a, Exp memory b) pure internal returns (Exp memory) {
        return Exp({mantissa: div_(mul_(a.mantissa, expScale), b.mantissa)});
    }

    function div_(Exp memory a, uint b) pure internal returns (Exp memory) {
        return Exp({mantissa: div_(a.mantissa, b)});
    }

    function div_(uint a, Exp memory b) pure internal returns (uint) {
        return div_(mul_(a, expScale), b.mantissa);
    }

    function div_(Double memory a, Double memory b) pure internal returns (Double memory) {
        return Double({mantissa: div_(mul_(a.mantissa, doubleScale), b.mantissa)});
    }

    function div_(Double memory a, uint b) pure internal returns (Double memory) {
        return Double({mantissa: div_(a.mantissa, b)});
    }

    function div_(uint a, Double memory b) pure internal returns (uint) {
        return div_(mul_(a, doubleScale), b.mantissa);
    }

    function div_(uint a, uint b) pure internal returns (uint) {
        return div_(a, b, "divide by zero");
    }

    function div_(uint a, uint b, string memory errorMessage) pure internal returns (uint) {
        require(b > 0, errorMessage);
        return a / b;
    }

    function fraction(uint a, uint b) pure internal returns (Double memory) {
        return Double({mantissa: div_(mul_(a, doubleScale), b)});
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "../Oracles/PriceOracle.sol";
import '../RegistryInterface.sol';
import './DistributorInterface.sol';

contract UnitrollerAdminStorage {
    /**
    * @notice Administrator for this contract in registry
    */
    RegistryInterface public registry;

    /**
    * @notice Active brains of Unitroller
    */
    address public controllerImplementation;

    /**
    * @notice Pending brains of Unitroller
    */
    address public pendingControllerImplementation;
}

contract ControllerStorage is UnitrollerAdminStorage {
    /**
    * @notice Administrator for this contract in registry
    */
    DistributorInterface public distributor;

    /**
     * @notice Oracle which gives the price of any given asset
     */
    PriceOracle public oracle;

    /**
     * @notice Multiplier used to calculate the maximum repayAmount when liquidating a borrow
     */
    uint public closeFactorMantissa;

    /**
     * @notice Multiplier representing the discount on collateral that a liquidator receives
     */
    uint public liquidationIncentiveMantissa;

    /**
     * @notice Max number of assets a single account can participate in (borrow or use as collateral)
     */
    uint public maxAssets;

    /**
     * @notice Per-account mapping of "assets you are in", capped by maxAssets
     */
    mapping(address => address[]) public accountAssets;

    /// @notice isListed Whether or not this market is listed
    /**
     * @notice collateralFactorMantissa Multiplier representing the most one can borrow against their collateral in this market.
     *  For instance, 0.9 to allow borrowing 90% of collateral value.
     *  Must be between 0 and 1, and stored as a mantissa.
     */
    /// @notice accountMembership Per-market mapping of "accounts in this asset"
    /// @notice isPied Whether or not this market receives PIE
    struct Market {
        bool isListed;
        uint collateralFactorMantissa;
        mapping(address => bool) accountMembership;
        bool isPied;
    }

    /**
     * @notice Official mapping of pTokens -> Market metadata
     * @dev Used e.g. to determine if a market is supported
     */
    mapping(address => Market) public markets;

    /**
     * @notice The Pause Guardian can pause certain actions as a safety mechanism.
     *  Actions which allow users to remove their own assets cannot be paused.
     *  Liquidation / seizing / transfer can only be paused globally, not by market.
     */
    address public pauseGuardian;
    bool public _mintGuardianPaused;
    bool public _borrowGuardianPaused;
    bool public transferGuardianPaused;
    bool public seizeGuardianPaused;
    mapping(address => bool) public mintGuardianPaused;
    mapping(address => bool) public borrowGuardianPaused;

    /// @notice A list of all markets
    address[] public allMarkets;

    /// @notice Only the Liquidate guardian can liquidate loans with collateral below the loan amount
    address public liquidateGuardian;

    /// @notice Multiplier representing the bonus on collateral that a liquidator receives for fee tokens
    mapping(address => uint) public feeFactorMantissa;

    // Max value of fee factor can be set for fee factor
    uint public feeFactorMaxMantissa;

    // Value of borrow delay for markets
    uint public borrowDelay;

    // Values for user moderate pool
    uint public userPauseDepositAmount;

    struct ModerateData {
        RewardState rewardState;
        uint freezePoolAmount;
        address userModerate;
    }

    enum RewardState {
        CREATED,
        PENDING,
        REJECTED,
        CONFIRMED,
        HARVESTED
    }

    mapping(address => ModerateData) public moderatePools;
    uint public guardianModerateTime;
    uint public totalFreeze;

    address public votingEscrow;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "../ErrorReporter.sol";
import "./ControllerStorage.sol";

/**
 * @title ControllerCore
 * @dev Storage for the controller is at this address, while execution is delegated to the `controllerImplementation`.
 * PTokens should reference this contract as their controller.
 */
contract Unitroller is UnitrollerAdminStorage, ControllerErrorReporter {

    /**
      * @notice Emitted when pendingControllerImplementation is changed
      */
    event NewPendingImplementation(address oldPendingImplementation, address newPendingImplementation);

    /**
      * @notice Emitted when pendingControllerImplementation is accepted, which means controller implementation is updated
      */
    event NewImplementation(address oldImplementation, address newImplementation);

    constructor(address registry_) {
        registry = RegistryInterface(registry_);
    }

    /*** Admin Functions ***/
    function _setPendingImplementation(address newPendingImplementation) public returns (uint) {
        if (msg.sender != getAdmin()) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SET_PENDING_IMPLEMENTATION_OWNER_CHECK);
        }

        address oldPendingImplementation = pendingControllerImplementation;

        pendingControllerImplementation = newPendingImplementation;

        emit NewPendingImplementation(oldPendingImplementation, pendingControllerImplementation);

        return uint(Error.NO_ERROR);
    }

    /**
    * @notice Accepts new implementation of controller. msg.sender must be pendingImplementation
    * @dev Admin function for new implementation to accept it's role as implementation
    * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
    */
    function _acceptImplementation() public returns (uint) {
        // Check caller is pendingImplementation and pendingImplementation ≠ address(0)
        if (msg.sender != pendingControllerImplementation || pendingControllerImplementation == address(0)) {
            return fail(Error.UNAUTHORIZED, FailureInfo.ACCEPT_PENDING_IMPLEMENTATION_ADDRESS_CHECK);
        }

        // Save current values for inclusion in log
        address oldImplementation = controllerImplementation;
        address oldPendingImplementation = pendingControllerImplementation;

        controllerImplementation = pendingControllerImplementation;

        pendingControllerImplementation = address(0);

        emit NewImplementation(oldImplementation, controllerImplementation);
        emit NewPendingImplementation(oldPendingImplementation, pendingControllerImplementation);

        return uint(Error.NO_ERROR);
    }

    function getAdmin() public view returns(address) {
        return registry.admin();
    }

    /**
     * @dev Delegates execution to an implementation contract.
     * It returns to the external caller whatever the implementation returns
     * or forwards reverts.
     */
    fallback() payable external {
        // delegate all other functions to current implementation
        (bool success, ) = controllerImplementation.delegatecall(msg.data);

        assembly {
        let free_mem_ptr := mload(0x40)
            returndatacopy(free_mem_ptr, 0, returndatasize())

            switch success
            case 0 { revert(free_mem_ptr, returndatasize()) }
            default { return(free_mem_ptr, returndatasize()) }
        }
    }

    receive() payable external {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

interface IVotingEscrow {
    event Deposit(
        address indexed provider,
        uint value,
        uint indexed unlockTime,
        int128 indexed depositType,
        uint ts
    );

    event Withdraw(address indexed provider, uint value, uint ts);

    event Supply(uint prevSupply, uint supply);

    event NewMinLockAmount(uint oldMinLockAmount, uint newMinLockAmount);

    event NewMinDuration(uint oldMinDuration, uint newMinDuration);

    event NewMaxDuration(uint oldMaxDuration, uint newMaxDuration);

    event AddedWhiteList(address user);

    event RemovedWhiteList(address user);

    function delegateLength(address user) external view returns (uint);

    function getLastUserSlope(address user) external view returns (int128);

    function getCheckpointTime(address user, uint id) external view returns (uint);

    function getUnlockTime(address user) external view returns (uint);
    function getStartTime(address user) external view returns (uint);
    function getAmount(address user) external view returns (int128);

    function createLockFor(
        address user,
        uint value,
        uint duration
    ) external;
    function createLock(uint _value, uint _duration) external;

    function depositFor(address user, uint value) external;

    function increaseAmountFor(address user, uint value) external;
    function increaseAmount(uint value) external;
    function increaseUnlockTime(uint duration) external;

    function withdraw() external;

    function balanceOf(address user) external view returns (uint);
    function balanceOf(address user, uint t) external view returns (uint);
    function balanceOfAt(address user, uint block) external view returns (uint);

    function totalSupply() external view returns (uint);
    function totalSupply(uint t) external view returns (uint);
    function totalSupplyAt(uint block) external view returns (uint);

    function depositPie(uint amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

/**
  * @title Careful Math
  * @author DeFiPie
  * @notice Derived from OpenZeppelin's SafeMath library
  *         https://github.com/OpenZeppelin/openzeppelin-solidity/blob/master/contracts/math/SafeMath.sol
  */
contract CarefulMath {

    /**
     * @dev Possible error codes that we can return
     */
    enum MathError {
        NO_ERROR,
        DIVISION_BY_ZERO,
        INTEGER_OVERFLOW,
        INTEGER_UNDERFLOW
    }

    /**
    * @dev Multiplies two numbers, returns an error on overflow.
    */
    function mulUInt(uint a, uint b) internal pure returns (MathError, uint) {
        unchecked {
            if (a == 0) {
                return (MathError.NO_ERROR, 0);
            }

            uint c = a * b;
            if (c / a != b) {
                return (MathError.INTEGER_OVERFLOW, 0);
            }

            return (MathError.NO_ERROR, c);
        }
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function divUInt(uint a, uint b) internal pure returns (MathError, uint) {
        if (b == 0) {
            return (MathError.DIVISION_BY_ZERO, 0);
        }

        return (MathError.NO_ERROR, a / b);
    }

    /**
    * @dev Subtracts two numbers, returns an error on overflow (i.e. if subtrahend is greater than minuend).
    */
    function subUInt(uint a, uint b) internal pure returns (MathError, uint) {
        if (b <= a) {
            return (MathError.NO_ERROR, a - b);
        } else {
            return (MathError.INTEGER_UNDERFLOW, 0);
        }
    }

    /**
    * @dev Adds two numbers, returns an error on overflow.
    */
    function addUInt(uint a, uint b) internal pure returns (MathError, uint) {
        unchecked {
            uint c = a + b;
            if (c >= a) {
                return (MathError.NO_ERROR, c);
            }

            return (MathError.INTEGER_OVERFLOW, 0);
        }
    }

    /**
    * @dev add a and b and then subtract c
    */
    function addThenSubUInt(uint a, uint b, uint c) internal pure returns (MathError, uint) {
        (MathError err0, uint sum) = addUInt(a, b);

        if (err0 != MathError.NO_ERROR) {
            return (err0, 0);
        }

        return subUInt(sum, c);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "../ProxyWithRegistry.sol";
import "../RegistryInterface.sol";

/**
 * @title DeFiPie's PErc20Delegator Contract
 * @notice PTokens which wrap an EIP-20 underlying and delegate to an implementation
 * @author DeFiPie
 */
contract PErc20Delegator is ProxyWithRegistry {

    /**
     * @notice Construct a new money market
     * @param underlying_ The address of the underlying asset
     * @param controller_ The address of the Controller
     * @param interestRateModel_ The address of the interest rate model
     * @param initialExchangeRateMantissa_ The initial exchange rate, scaled by 1e18
     * @param initialReserveFactorMantissa_ The initial reserve factor, scaled by 1e18
     * @param name_ ERC-20 name of this token
     * @param symbol_ ERC-20 symbol of this token
     * @param decimals_ ERC-20 decimal precision of this token
     * @param registry_ The address of the registry contract
     */
    constructor(
        address underlying_,
        address controller_,
        address interestRateModel_,
        uint initialExchangeRateMantissa_,
        uint initialReserveFactorMantissa_,
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        address registry_
    ) {
        // Set registry
        _setRegistry(registry_);

        // First delegate gets to initialize the delegator (i.e. storage contract)
        delegateTo(_pTokenImplementation(), abi.encodeWithSignature("initialize(address,address,address,address,uint256,uint256,string,string,uint8)",
                                                            underlying_,
                                                            registry_,
                                                            controller_,
                                                            interestRateModel_,
                                                            initialExchangeRateMantissa_,
                                                            initialReserveFactorMantissa_,
                                                            name_,
                                                            symbol_,
                                                            decimals_));
    }

    /**
     * @notice Internal method to delegate execution to another contract
     * @dev It returns to the external caller whatever the implementation returns or forwards reverts
     * @param callee The contract to delegatecall
     * @param data The raw data to delegatecall
     * @return The returned bytes from the delegatecall
     */
    function delegateTo(address callee, bytes memory data) internal returns (bytes memory) {
        (bool success, bytes memory returnData) = callee.delegatecall(data);
        assembly {
            if eq(success, 0) {
                revert(add(returnData, 0x20), returndatasize())
            }
        }
        return returnData;
    }

    function delegateAndReturn() internal returns (bytes memory) {
        (bool success, ) = _pTokenImplementation().delegatecall(msg.data);

        assembly {
            let free_mem_ptr := mload(0x40)
            returndatacopy(free_mem_ptr, 0, returndatasize())

            switch success
            case 0 { revert(free_mem_ptr, returndatasize()) }
            default { return(free_mem_ptr, returndatasize()) }
        }
    }

    /**
     * @notice Delegates execution to an implementation contract
     * @dev It returns to the external caller whatever the implementation returns or forwards reverts
     */
    fallback() external {
        // delegate all other functions to current implementation
        delegateAndReturn();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "../ProxyWithRegistry.sol";
import "../RegistryInterface.sol";
import "../ErrorReporter.sol";

/**
 * @title DeFiPie's PETHDelegator Contract
 * @notice PETH which wrap a delegate to an implementation
 * @author DeFiPie
 */
contract PETHDelegator is ImplementationStorage, ProxyWithRegistry, TokenErrorReporter {

    /**
      * @notice Emitted when implementation is changed
      */
    event NewImplementation(address oldImplementation, address newImplementation);

    /**
     * @notice Construct a new money market
     * @param pETHImplementation_ The address of the PEthImplementation
     * @param controller_ The address of the Controller
     * @param interestRateModel_ The address of the interest rate model
     * @param initialExchangeRateMantissa_ The initial exchange rate, scaled by 1e18
     * @param initialReserveFactorMantissa_ The initial reserve factor, scaled by 1e18
     * @param name_ ERC-20 name of this token
     * @param symbol_ ERC-20 symbol of this token
     * @param decimals_ ERC-20 decimal precision of this token
     * @param registry_ The address of the registry contract
     */
    constructor(
        address pETHImplementation_,
        address controller_,
        address interestRateModel_,
        uint initialExchangeRateMantissa_,
        uint initialReserveFactorMantissa_,
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        address registry_
    ) {
        // Set registry
        _setRegistry(registry_);
        _setImplementationInternal(pETHImplementation_);

        // First delegate gets to initialize the delegator (i.e. storage contract)
        delegateTo(implementation, abi.encodeWithSignature("initialize(address,address,address,uint256,uint256,string,string,uint8)",
                                                            registry_,
                                                            controller_,
                                                            interestRateModel_,
                                                            initialExchangeRateMantissa_,
                                                            initialReserveFactorMantissa_,
                                                            name_,
                                                            symbol_,
                                                            decimals_));
    }

    /**
     * @notice Internal method to delegate execution to another contract
     * @dev It returns to the external caller whatever the implementation returns or forwards reverts
     * @param callee The contract to delegatecall
     * @param data The raw data to delegatecall
     * @return The returned bytes from the delegatecall
     */
    function delegateTo(address callee, bytes memory data) internal returns (bytes memory) {
        (bool success, bytes memory returnData) = callee.delegatecall(data);
        assembly {
            if eq(success, 0) {
                revert(add(returnData, 0x20), returndatasize())
            }
        }
        return returnData;
    }

    function delegateAndReturn() private returns (bytes memory) {
        (bool success, ) = implementation.delegatecall(msg.data);

        assembly {
            let free_mem_ptr := mload(0x40)
            returndatacopy(free_mem_ptr, 0, returndatasize())

            switch success
            case 0 { revert(free_mem_ptr, returndatasize()) }
            default { return(free_mem_ptr, returndatasize()) }
        }
    }

    /**
     * @notice Delegates execution to an implementation contract
     * @dev It returns to the external caller whatever the implementation returns or forwards reverts
     */
    fallback() external payable {
        // delegate all other functions to current implementation
        delegateAndReturn();
    }

    receive() external payable {
        // delegate all other functions to current implementation
        delegateAndReturn();
    }

    function _setImplementation(address newImplementation) external returns(uint) {
        if (msg.sender != RegistryInterface(registry).admin()) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SET_NEW_IMPLEMENTATION);
        }

        address oldImplementation = implementation;
        _setImplementationInternal(newImplementation);

        emit NewImplementation(oldImplementation, implementation);

        return(uint(Error.NO_ERROR));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "../ProxyWithRegistry.sol";
import "../RegistryInterface.sol";
import "../ErrorReporter.sol";

/**
 * @title DeFiPie's PPIEDelegator Contract
 * @notice PPIE which wrap an EIP-20 underlying and delegate to an implementation
 * @author DeFiPie
 */
contract PPIEDelegator is ImplementationStorage, ProxyWithRegistry, TokenErrorReporter {

    /**
      * @notice Emitted when implementation is changed
      */
    event NewImplementation(address oldImplementation, address newImplementation);

    /**
     * @notice Construct a new money market
     * @param underlying_ The address of the underlying asset
     * @param pPIEImplementation_ The address of the PPIEImplementation
     * @param controller_ The address of the Controller
     * @param interestRateModel_ The address of the interest rate model
     * @param initialExchangeRateMantissa_ The initial exchange rate, scaled by 1e18
     * @param initialReserveFactorMantissa_ The initial reserve factor, scaled by 1e18
     * @param name_ ERC-20 name of this token
     * @param symbol_ ERC-20 symbol of this token
     * @param decimals_ ERC-20 decimal precision of this token
     * @param registry_ The address of the registry contract
     */
    constructor(
        address underlying_,
        address pPIEImplementation_,
        address controller_,
        address interestRateModel_,
        uint initialExchangeRateMantissa_,
        uint initialReserveFactorMantissa_,
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        address registry_
    ) {
        // Set registry
        _setRegistry(registry_);
        _setImplementationInternal(pPIEImplementation_);

        // First delegate gets to initialize the delegator (i.e. storage contract)
        delegateTo(implementation, abi.encodeWithSignature("initialize(address,address,address,address,uint256,uint256,string,string,uint8)",
                                                        underlying_,
                                                        registry_,
                                                        controller_,
                                                        interestRateModel_,
                                                        initialExchangeRateMantissa_,
                                                        initialReserveFactorMantissa_,
                                                        name_,
                                                        symbol_,
                                                        decimals_));
    }

    /**
     * @notice Internal method to delegate execution to another contract
     * @dev It returns to the external caller whatever the implementation returns or forwards reverts
     * @param callee The contract to delegatecall
     * @param data The raw data to delegatecall
     * @return The returned bytes from the delegatecall
     */
    function delegateTo(address callee, bytes memory data) internal returns (bytes memory) {
        (bool success, bytes memory returnData) = callee.delegatecall(data);
        assembly {
            if eq(success, 0) {
                revert(add(returnData, 0x20), returndatasize())
            }
        }
        return returnData;
    }

    function delegateAndReturn() internal returns (bytes memory) {
        (bool success, ) = implementation.delegatecall(msg.data);

        assembly {
            let free_mem_ptr := mload(0x40)
            returndatacopy(free_mem_ptr, 0, returndatasize())

            switch success
            case 0 { revert(free_mem_ptr, returndatasize()) }
            default { return(free_mem_ptr, returndatasize()) }
        }
    }

    /**
     * @notice Delegates execution to an implementation contract
     * @dev It returns to the external caller whatever the implementation returns or forwards reverts
     */
    fallback() external {
        // delegate all other functions to current implementation
        delegateAndReturn();
    }

    function _setImplementation(address newImplementation) external returns (uint) {
        if (msg.sender != RegistryInterface(registry).admin()) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SET_NEW_IMPLEMENTATION);
        }

        address oldImplementation = implementation;
        _setImplementationInternal(newImplementation);

        emit NewImplementation(oldImplementation, implementation);

        return(uint(Error.NO_ERROR));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import './Tokens/PErc20Delegator.sol';
import './RegistryInterface.sol';
import './Tokens/EIP20Interface.sol';
import "./Oracles/Interfaces/IPriceFeeds.sol";
import "./ErrorReporter.sol";
import "./SafeMath.sol";
import "./Tokens/PEtherDelegator.sol";
import "./Tokens/PPIEDelegator.sol";
import "./Control/Controller.sol";
import "./Oracles/PriceOracle.sol";
import "./Tokens/PTokenInterfaces.sol";

contract PTokenFactoryStorage {
    address public implementation;
    address public registry;
}

contract PTokenFactoryStorageV1 is PTokenFactoryStorage {
    // default parameters for pToken
    address public controller;
    address public interestRateModel;
    uint256 public initialExchangeRateMantissa;
    uint256 public initialReserveFactorMantissa;
    uint256 public minOracleLiquidity;

    // decimals for pToken
    uint8 public decimals;

    mapping (address => bool) public isUnderlyingBlackListed;

    uint public createPoolFeeAmount;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "../Oracles/PriceOracle.sol";
import "../Exponential.sol";

abstract contract DistributorInterface {
    function getPieAddress() public view virtual returns (address);

    function updatePieSupplyIndex(address pToken) public virtual;
    function distributeSupplierPie(address pToken, address supplier, bool distributeAll) public virtual;

    function updatePieBorrowIndex(address pToken, Exponential.Exp memory marketBorrowIndex) public virtual;
    function distributeBorrowerPie(
        address pToken,
        address borrower,
        Exponential.Exp memory marketBorrowIndex,
        bool distributeAll
    ) public virtual;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./Address.sol";

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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
abstract contract ReentrancyGuard {
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

    constructor() {
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
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

library Integers {
    function toInt128(uint256 u) internal pure returns (int128) {
        return int128(int256(u));
    }

    function toUint256(int128 i) internal pure returns (uint256) {
        return uint256(uint128(i));
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