// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.12;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// SPDX-License-Identifier: MIT

pragma experimental ABIEncoderV2;
pragma solidity 0.6.12;

import "../libraries/WadRayMath.sol";
import "../interfaces/IConfigProvider.sol";
import "../interfaces/IAddressProvider.sol";

contract ConfigProvider is IConfigProvider {
  IAddressProvider public override a;

  mapping(uint256 => CollateralConfig) private _collateralConfigs; //indexing starts at 1
  mapping(address => uint256) public override collateralIds;

  uint256 public override numCollateralConfigs;
  /// @notice The minimum duration of voting on a proposal, in seconds
  uint256 public override minVotingPeriod = 3 days;
  /// @notice The max duration of voting on a proposal, in seconds
  uint256 public override maxVotingPeriod = 2 weeks;
  /// @notice The percentage of votes in support of a proposal required in order for a quorum to be reached and for a proposal to succeed
  uint256 public override votingQuorum = 1e16; // 1%
  /// @notice The percentage of votes required in order for a voter to become a proposer
  uint256 public override proposalThreshold = 2e14; // 0.02%

  constructor(IAddressProvider _addresses) public {
    require(address(_addresses) != address(0));

    a = _addresses;
  }

  modifier onlyManager() {
    require(a.controller().hasRole(a.controller().MANAGER_ROLE(), msg.sender), "Caller is not a Manager");
    _;
  }

  /**
    Creates or overwrites an existing config for a collateral type
    @param _collateralType address of the collateral type
    @param _debtLimit the debt ceiling for the collateral type
    @param _liquidationRatio the minimum ratio to maintain to avoid liquidation
    @param _minCollateralRatio the minimum ratio to maintain to borrow new money or withdraw collateral
    @param _borrowRate the borrowing rate specified in 1 second interval in RAY accuracy.
    @param _originationFee an optional origination fee for newly created debt. Can be 0.
    @param _liquidationBonus the liquidation bonus to be paid to liquidators.
    @param _liquidationFee an optional fee for liquidation debt. Can be 0.
  */
  function setCollateralConfig(
    address _collateralType,
    uint256 _debtLimit,
    uint256 _liquidationRatio,
    uint256 _minCollateralRatio,
    uint256 _borrowRate,
    uint256 _originationFee,
    uint256 _liquidationBonus,
    uint256 _liquidationFee
  ) public override onlyManager {
    require(address(_collateralType) != address(0));
    require(_minCollateralRatio >= _liquidationRatio);
    if (collateralIds[_collateralType] == 0) {
      // Initialize new collateral
      a.core().state().initializeRates(_collateralType);
      CollateralConfig memory config = CollateralConfig({
        collateralType: _collateralType,
        debtLimit: _debtLimit,
        liquidationRatio: _liquidationRatio,
        minCollateralRatio: _minCollateralRatio,
        borrowRate: _borrowRate,
        originationFee: _originationFee,
        liquidationBonus: _liquidationBonus,
        liquidationFee: _liquidationFee
      });

      numCollateralConfigs++;
      _collateralConfigs[numCollateralConfigs] = config;
      collateralIds[_collateralType] = numCollateralConfigs;
    } else {
      // Update collateral config
      a.core().state().refreshCollateral(_collateralType);
      uint256 id = collateralIds[_collateralType];

      _collateralConfigs[id].collateralType = _collateralType;
      _collateralConfigs[id].debtLimit = _debtLimit;
      _collateralConfigs[id].liquidationRatio = _liquidationRatio;
      _collateralConfigs[id].minCollateralRatio = _minCollateralRatio;
      _collateralConfigs[id].borrowRate = _borrowRate;
      _collateralConfigs[id].originationFee = _originationFee;
      _collateralConfigs[id].liquidationBonus = _liquidationBonus;
      _collateralConfigs[id].liquidationFee = _liquidationFee;
    }
    emit CollateralUpdated(
      _collateralType,
      _debtLimit,
      _liquidationRatio,
      _minCollateralRatio,
      _borrowRate,
      _originationFee,
      _liquidationBonus,
      _liquidationFee
    );
  }

  function _emitUpdateEvent(address _collateralType) internal {
    emit CollateralUpdated(
      _collateralType,
      _collateralConfigs[collateralIds[_collateralType]].debtLimit,
      _collateralConfigs[collateralIds[_collateralType]].liquidationRatio,
      _collateralConfigs[collateralIds[_collateralType]].minCollateralRatio,
      _collateralConfigs[collateralIds[_collateralType]].borrowRate,
      _collateralConfigs[collateralIds[_collateralType]].originationFee,
      _collateralConfigs[collateralIds[_collateralType]].liquidationBonus,
      _collateralConfigs[collateralIds[_collateralType]].liquidationFee
    );
  }

  /**
    Remove the config for a collateral type
    @param _collateralType address of the collateral type
  */
  function removeCollateral(address _collateralType) public override onlyManager {
    uint256 id = collateralIds[_collateralType];
    require(id != 0, "collateral does not exist");

    _collateralConfigs[id] = _collateralConfigs[numCollateralConfigs]; //move last entry forward
    collateralIds[_collateralConfigs[id].collateralType] = id; //update id for last entry
    delete _collateralConfigs[numCollateralConfigs]; // delete last entry
    delete collateralIds[_collateralType];

    numCollateralConfigs--;

    emit CollateralRemoved(_collateralType);
  }

  /**
    Sets the debt limit for a collateral type
    @param _collateralType address of the collateral type
    @param _debtLimit the new debt limit
  */
  function setCollateralDebtLimit(address _collateralType, uint256 _debtLimit) public override onlyManager {
    _collateralConfigs[collateralIds[_collateralType]].debtLimit = _debtLimit;
    _emitUpdateEvent(_collateralType);
  }

  /**
    Sets the minimum liquidation ratio for a collateral type
    @dev this is the liquidation treshold under which a vault is considered open for liquidation.
    @param _collateralType address of the collateral type
    @param _liquidationRatio the new minimum collateralization ratio
  */
  function setCollateralLiquidationRatio(address _collateralType, uint256 _liquidationRatio)
    public
    override
    onlyManager
  {
    require(_liquidationRatio <= _collateralConfigs[collateralIds[_collateralType]].minCollateralRatio);
    _collateralConfigs[collateralIds[_collateralType]].liquidationRatio = _liquidationRatio;
    _emitUpdateEvent(_collateralType);
  }

  /**
    Sets the minimum ratio for a collateral type for new borrowing or collateral withdrawal
    @param _collateralType address of the collateral type
    @param _minCollateralRatio the new minimum open ratio
  */
  function setCollateralMinCollateralRatio(address _collateralType, uint256 _minCollateralRatio)
    public
    override
    onlyManager
  {
    require(_minCollateralRatio >= _collateralConfigs[collateralIds[_collateralType]].liquidationRatio);
    _collateralConfigs[collateralIds[_collateralType]].minCollateralRatio = _minCollateralRatio;
    _emitUpdateEvent(_collateralType);
  }

  /**
    Sets the borrowing rate for a collateral type
    @dev borrowing rate is specified for a 1 sec interval and accurancy is in RAY.
    @param _collateralType address of the collateral type
    @param _borrowRate the new borrowing rate for a 1 sec interval
  */
  function setCollateralBorrowRate(address _collateralType, uint256 _borrowRate) public override onlyManager {
    a.core().state().refreshCollateral(_collateralType);
    _collateralConfigs[collateralIds[_collateralType]].borrowRate = _borrowRate;
    _emitUpdateEvent(_collateralType);
  }

  /**
    Sets the origiation fee for a collateral type
    @dev this rate is applied as a one time fee for new borrowing and is specified in WAD
    @param _collateralType address of the collateral type
    @param _originationFee new origination fee in WAD
  */
  function setCollateralOriginationFee(address _collateralType, uint256 _originationFee) public override onlyManager {
    _collateralConfigs[collateralIds[_collateralType]].originationFee = _originationFee;
    _emitUpdateEvent(_collateralType);
  }

  /**
    Sets the liquidation bonus for a collateral type
    @dev the liquidation bonus is specified in WAD
    @param _collateralType address of the collateral type
    @param _liquidationBonus the liquidation bonus to be paid to liquidators.
  */
  function setCollateralLiquidationBonus(address _collateralType, uint256 _liquidationBonus)
    public
    override
    onlyManager
  {
    _collateralConfigs[collateralIds[_collateralType]].liquidationBonus = _liquidationBonus;
    _emitUpdateEvent(_collateralType);
  }

  /**
    Sets the liquidation fee for a collateral type
    @dev this rate is applied as a fee for liquidation and is specified in WAD
    @param _collateralType address of the collateral type
    @param _liquidationFee new liquidation fee in WAD
  */
  function setCollateralLiquidationFee(address _collateralType, uint256 _liquidationFee) public override onlyManager {
    require(_liquidationFee < 1e18); // fee < 100%
    _collateralConfigs[collateralIds[_collateralType]].liquidationFee = _liquidationFee;
    _emitUpdateEvent(_collateralType);
  }

  /**
    Set the min voting period for a gov proposal.
    @param _minVotingPeriod the min voting period for a gov proposal
  */
  function setMinVotingPeriod(uint256 _minVotingPeriod) public override onlyManager {
    minVotingPeriod = _minVotingPeriod;
  }

  /**
    Set the max voting period for a gov proposal.
    @param _maxVotingPeriod the max voting period for a gov proposal
  */
  function setMaxVotingPeriod(uint256 _maxVotingPeriod) public override onlyManager {
    maxVotingPeriod = _maxVotingPeriod;
  }

  /**
    Set the voting quora for a gov proposal.
    @param _votingQuorum the voting quora for a gov proposal
  */
  function setVotingQuorum(uint256 _votingQuorum) public override onlyManager {
    require(_votingQuorum < 1e18);
    votingQuorum = _votingQuorum;
  }

  /**
    Set the proposal threshold for a gov proposal.
    @param _proposalThreshold the proposal threshold for a gov proposal
  */
  function setProposalThreshold(uint256 _proposalThreshold) public override onlyManager {
    require(_proposalThreshold < 1e18);
    proposalThreshold = _proposalThreshold;
  }

  /**
    Get the debt limit for a collateral type
    @dev this is a platform wide limit for new debt issuance against a specific collateral type
    @param _collateralType address of the collateral type
  */
  function collateralDebtLimit(address _collateralType) public view override returns (uint256) {
    return _collateralConfigs[collateralIds[_collateralType]].debtLimit;
  }

  /**
    Get the liquidation ratio that needs to be maintained for a collateral type to avoid liquidation.
    @param _collateralType address of the collateral type
  */
  function collateralLiquidationRatio(address _collateralType) public view override returns (uint256) {
    return _collateralConfigs[collateralIds[_collateralType]].liquidationRatio;
  }

  /**
    Get the minimum collateralization ratio for a collateral type for new borrowing or collateral withdrawal.
    @param _collateralType address of the collateral type
  */
  function collateralMinCollateralRatio(address _collateralType) public view override returns (uint256) {
    return _collateralConfigs[collateralIds[_collateralType]].minCollateralRatio;
  }

  /**
    Get the borrowing rate for a collateral type
    @dev borrowing rate is specified for a 1 sec interval and accurancy is in RAY.
    @param _collateralType address of the collateral type
  */
  function collateralBorrowRate(address _collateralType) public view override returns (uint256) {
    return _collateralConfigs[collateralIds[_collateralType]].borrowRate;
  }

  /**
    Get the origiation fee for a collateral type
    @dev this rate is applied as a one time fee for new borrowing and is specified in WAD
    @param _collateralType address of the collateral type
  */
  function collateralOriginationFee(address _collateralType) public view override returns (uint256) {
    return _collateralConfigs[collateralIds[_collateralType]].originationFee;
  }

  /**
    Get the liquidation bonus for a collateral type
    @dev this rate is applied as a one time fee for new borrowing and is specified in WAD
    @param _collateralType address of the collateral type
  */
  function collateralLiquidationBonus(address _collateralType) public view override returns (uint256) {
    return _collateralConfigs[collateralIds[_collateralType]].liquidationBonus;
  }

  /**
    Get the liquidation fee for a collateral type
    @dev this rate is applied as a one time fee for new borrowing and is specified in WAD
    @param _collateralType address of the collateral type
  */
  function collateralLiquidationFee(address _collateralType) public view override returns (uint256) {
    return _collateralConfigs[collateralIds[_collateralType]].liquidationFee;
  }

  /**
    Retreives the entire config for a specific config id.
    @param _id the ID of the conifg to be returned
  */
  function collateralConfigs(uint256 _id) public view override returns (CollateralConfig memory) {
    require(_id <= numCollateralConfigs, "Invalid config id");
    return _collateralConfigs[_id];
  }
}

// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;
pragma solidity >=0.6.12;

import "./IGovernorAlpha.sol";
import "./ITimelock.sol";
import "./IVotingEscrow.sol";
import "../../interfaces/IAccessController.sol";
import "../../interfaces/IAddressProvider.sol";
import "../../liquidityMining/interfaces/IMIMO.sol";
import "../../liquidityMining/interfaces/IDebtNotifier.sol";

interface IGovernanceAddressProvider {
  function setParallelAddressProvider(IAddressProvider _parallel) external;

  function setMIMO(IMIMO _mimo) external;

  function setDebtNotifier(IDebtNotifier _debtNotifier) external;

  function setGovernorAlpha(IGovernorAlpha _governorAlpha) external;

  function setTimelock(ITimelock _timelock) external;

  function setVotingEscrow(IVotingEscrow _votingEscrow) external;

  function controller() external view returns (IAccessController);

  function parallel() external view returns (IAddressProvider);

  function mimo() external view returns (IMIMO);

  function debtNotifier() external view returns (IDebtNotifier);

  function governorAlpha() external view returns (IGovernorAlpha);

  function timelock() external view returns (ITimelock);

  function votingEscrow() external view returns (IVotingEscrow);
}

// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;
pragma solidity 0.6.12;

interface IGovernorAlpha {
  /// @notice Possible states that a proposal may be in
  enum ProposalState { Active, Canceled, Defeated, Succeeded, Queued, Expired, Executed }

  struct Proposal {
    // Unique id for looking up a proposal
    uint256 id;
    // Creator of the proposal
    address proposer;
    // The timestamp that the proposal will be available for execution, set once the vote succeeds
    uint256 eta;
    // the ordered list of target addresses for calls to be made
    address[] targets;
    // The ordered list of values (i.e. msg.value) to be passed to the calls to be made
    uint256[] values;
    // The ordered list of function signatures to be called
    string[] signatures;
    // The ordered list of calldata to be passed to each call
    bytes[] calldatas;
    // The timestamp at which voting begins: holders must delegate their votes prior to this timestamp
    uint256 startTime;
    // The timestamp at which voting ends: votes must be cast prior to this timestamp
    uint256 endTime;
    // Current number of votes in favor of this proposal
    uint256 forVotes;
    // Current number of votes in opposition to this proposal
    uint256 againstVotes;
    // Flag marking whether the proposal has been canceled
    bool canceled;
    // Flag marking whether the proposal has been executed
    bool executed;
    // Receipts of ballots for the entire set of voters
    mapping(address => Receipt) receipts;
  }

  /// @notice Ballot receipt record for a voter
  struct Receipt {
    // Whether or not a vote has been cast
    bool hasVoted;
    // Whether or not the voter supports the proposal
    bool support;
    // The number of votes the voter had, which were cast
    uint256 votes;
  }

  /// @notice An event emitted when a new proposal is created
  event ProposalCreated(
    uint256 id,
    address proposer,
    address[] targets,
    uint256[] values,
    string[] signatures,
    bytes[] calldatas,
    uint256 startTime,
    uint256 endTime,
    string description
  );

  /// @notice An event emitted when a vote has been cast on a proposal
  event VoteCast(address voter, uint256 proposalId, bool support, uint256 votes);

  /// @notice An event emitted when a proposal has been canceled
  event ProposalCanceled(uint256 id);

  /// @notice An event emitted when a proposal has been queued in the Timelock
  event ProposalQueued(uint256 id, uint256 eta);

  /// @notice An event emitted when a proposal has been executed in the Timelock
  event ProposalExecuted(uint256 id);

  function propose(
    address[] memory targets,
    uint256[] memory values,
    string[] memory signatures,
    bytes[] memory calldatas,
    string memory description,
    uint256 endTime
  ) external returns (uint256);

  function queue(uint256 proposalId) external;

  function execute(uint256 proposalId) external payable;

  function cancel(uint256 proposalId) external;

  function castVote(uint256 proposalId, bool support) external;

  function getActions(uint256 proposalId)
    external
    view
    returns (
      address[] memory targets,
      uint256[] memory values,
      string[] memory signatures,
      bytes[] memory calldatas
    );

  function getReceipt(uint256 proposalId, address voter) external view returns (Receipt memory);

  function state(uint256 proposalId) external view returns (ProposalState);

  function quorumVotes() external view returns (uint256);

  function proposalThreshold() external view returns (uint256);
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.6.12;

interface ITimelock {
  event NewAdmin(address indexed newAdmin);
  event NewPendingAdmin(address indexed newPendingAdmin);
  event NewDelay(uint256 indexed newDelay);
  event CancelTransaction(
    bytes32 indexed txHash,
    address indexed target,
    uint256 value,
    string signature,
    bytes data,
    uint256 eta
  );
  event ExecuteTransaction(
    bytes32 indexed txHash,
    address indexed target,
    uint256 value,
    string signature,
    bytes data,
    uint256 eta
  );
  event QueueTransaction(
    bytes32 indexed txHash,
    address indexed target,
    uint256 value,
    string signature,
    bytes data,
    uint256 eta
  );

  function acceptAdmin() external;

  function queueTransaction(
    address target,
    uint256 value,
    string calldata signature,
    bytes calldata data,
    uint256 eta
  ) external returns (bytes32);

  function cancelTransaction(
    address target,
    uint256 value,
    string calldata signature,
    bytes calldata data,
    uint256 eta
  ) external;

  function executeTransaction(
    address target,
    uint256 value,
    string calldata signature,
    bytes calldata data,
    uint256 eta
  ) external payable returns (bytes memory);

  function delay() external view returns (uint256);

  function GRACE_PERIOD() external view returns (uint256);

  function queuedTransactions(bytes32 hash) external view returns (bool);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../liquidityMining/interfaces/IGenericMiner.sol";

interface IVotingEscrow {
  enum LockAction { CREATE_LOCK, INCREASE_LOCK_AMOUNT, INCREASE_LOCK_TIME }

  struct LockedBalance {
    uint256 amount;
    uint256 end;
  }

  /** Shared Events */
  event Deposit(address indexed provider, uint256 value, uint256 locktime, LockAction indexed action, uint256 ts);
  event Withdraw(address indexed provider, uint256 value, uint256 ts);
  event Expired();

  function createLock(uint256 _value, uint256 _unlockTime) external;

  function increaseLockAmount(uint256 _value) external;

  function increaseLockLength(uint256 _unlockTime) external;

  function withdraw() external;

  function expireContract() external;

  function setMiner(IGenericMiner _miner) external;

  function setMinimumLockTime(uint256 _minimumLockTime) external;

  function name() external view returns (string memory);

  function symbol() external view returns (string memory);

  function decimals() external view returns (uint256);

  function balanceOf(address _owner) external view returns (uint256);

  function balanceOfAt(address _owner, uint256 _blockTime) external view returns (uint256);

  function stakingToken() external view returns (IERC20);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IAccessController {
  event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);
  event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);
  event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

  function grantRole(bytes32 role, address account) external;

  function revokeRole(bytes32 role, address account) external;

  function renounceRole(bytes32 role, address account) external;

  function MANAGER_ROLE() external view returns (bytes32);

  function MINTER_ROLE() external view returns (bytes32);

  function hasRole(bytes32 role, address account) external view returns (bool);

  function getRoleMemberCount(bytes32 role) external view returns (uint256);

  function getRoleMember(bytes32 role, uint256 index) external view returns (address);

  function getRoleAdmin(bytes32 role) external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;
pragma solidity 0.6.12;

import "./IAccessController.sol";
import "./IConfigProvider.sol";
import "./ISTABLEX.sol";
import "./IPriceFeed.sol";
import "./IRatesManager.sol";
import "./ILiquidationManager.sol";
import "./IVaultsCore.sol";
import "./IVaultsDataProvider.sol";
import "./IFeeDistributor.sol";

interface IAddressProvider {
  function setAccessController(IAccessController _controller) external;

  function setConfigProvider(IConfigProvider _config) external;

  function setVaultsCore(IVaultsCore _core) external;

  function setStableX(ISTABLEX _stablex) external;

  function setRatesManager(IRatesManager _ratesManager) external;

  function setPriceFeed(IPriceFeed _priceFeed) external;

  function setLiquidationManager(ILiquidationManager _liquidationManager) external;

  function setVaultsDataProvider(IVaultsDataProvider _vaultsData) external;

  function setFeeDistributor(IFeeDistributor _feeDistributor) external;

  function controller() external view returns (IAccessController);

  function config() external view returns (IConfigProvider);

  function core() external view returns (IVaultsCore);

  function stablex() external view returns (ISTABLEX);

  function ratesManager() external view returns (IRatesManager);

  function priceFeed() external view returns (IPriceFeed);

  function liquidationManager() external view returns (ILiquidationManager);

  function vaultsData() external view returns (IVaultsDataProvider);

  function feeDistributor() external view returns (IFeeDistributor);
}

// SPDX-License-Identifier: MIT

pragma experimental ABIEncoderV2;
pragma solidity 0.6.12;

import "../interfaces/IAddressProvider.sol";

interface IConfigProvider {
  struct CollateralConfig {
    address collateralType;
    uint256 debtLimit;
    uint256 liquidationRatio;
    uint256 minCollateralRatio;
    uint256 borrowRate;
    uint256 originationFee;
    uint256 liquidationBonus;
    uint256 liquidationFee;
  }

  event CollateralUpdated(
    address indexed collateralType,
    uint256 debtLimit,
    uint256 liquidationRatio,
    uint256 minCollateralRatio,
    uint256 borrowRate,
    uint256 originationFee,
    uint256 liquidationBonus,
    uint256 liquidationFee
  );
  event CollateralRemoved(address indexed collateralType);

  function setCollateralConfig(
    address _collateralType,
    uint256 _debtLimit,
    uint256 _liquidationRatio,
    uint256 _minCollateralRatio,
    uint256 _borrowRate,
    uint256 _originationFee,
    uint256 _liquidationBonus,
    uint256 _liquidationFee
  ) external;

  function removeCollateral(address _collateralType) external;

  function setCollateralDebtLimit(address _collateralType, uint256 _debtLimit) external;

  function setCollateralLiquidationRatio(address _collateralType, uint256 _liquidationRatio) external;

  function setCollateralMinCollateralRatio(address _collateralType, uint256 _minCollateralRatio) external;

  function setCollateralBorrowRate(address _collateralType, uint256 _borrowRate) external;

  function setCollateralOriginationFee(address _collateralType, uint256 _originationFee) external;

  function setCollateralLiquidationBonus(address _collateralType, uint256 _liquidationBonus) external;

  function setCollateralLiquidationFee(address _collateralType, uint256 _liquidationFee) external;

  function setMinVotingPeriod(uint256 _minVotingPeriod) external;

  function setMaxVotingPeriod(uint256 _maxVotingPeriod) external;

  function setVotingQuorum(uint256 _votingQuorum) external;

  function setProposalThreshold(uint256 _proposalThreshold) external;

  function a() external view returns (IAddressProvider);

  function collateralConfigs(uint256 _id) external view returns (CollateralConfig memory);

  function collateralIds(address _collateralType) external view returns (uint256);

  function numCollateralConfigs() external view returns (uint256);

  function minVotingPeriod() external view returns (uint256);

  function maxVotingPeriod() external view returns (uint256);

  function votingQuorum() external view returns (uint256);

  function proposalThreshold() external view returns (uint256);

  function collateralDebtLimit(address _collateralType) external view returns (uint256);

  function collateralLiquidationRatio(address _collateralType) external view returns (uint256);

  function collateralMinCollateralRatio(address _collateralType) external view returns (uint256);

  function collateralBorrowRate(address _collateralType) external view returns (uint256);

  function collateralOriginationFee(address _collateralType) external view returns (uint256);

  function collateralLiquidationBonus(address _collateralType) external view returns (uint256);

  function collateralLiquidationFee(address _collateralType) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "../interfaces/IAddressProvider.sol";

interface IFeeDistributor {
  event PayeeAdded(address indexed account, uint256 shares);
  event FeeReleased(uint256 income, uint256 releasedAt);

  function release() external;

  function changePayees(address[] memory _payees, uint256[] memory _shares) external;

  function a() external view returns (IAddressProvider);

  function lastReleasedAt() external view returns (uint256);

  function getPayees() external view returns (address[] memory);

  function totalShares() external view returns (uint256);

  function shares(address payee) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma experimental ABIEncoderV2;
pragma solidity 0.6.12;

import "../interfaces/IAddressProvider.sol";

interface ILiquidationManager {
  function a() external view returns (IAddressProvider);

  function calculateHealthFactor(
    uint256 _collateralValue,
    uint256 _vaultDebt,
    uint256 _minRatio
  ) external view returns (uint256 healthFactor);

  function liquidationBonus(address _collateralType, uint256 _amount) external view returns (uint256 bonus);

  function applyLiquidationDiscount(address _collateralType, uint256 _amount)
    external
    view
    returns (uint256 discountedAmount);

  function isHealthy(
    uint256 _collateralValue,
    uint256 _vaultDebt,
    uint256 _minRatio
  ) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "../chainlink/AggregatorV3Interface.sol";
import "../interfaces/IAddressProvider.sol";

interface IPriceFeed {
  event OracleUpdated(address indexed asset, address oracle, address sender);
  event EurOracleUpdated(address oracle, address sender);

  function setAssetOracle(address _asset, address _oracle) external;

  function setEurOracle(address _oracle) external;

  function a() external view returns (IAddressProvider);

  function assetOracles(address _asset) external view returns (AggregatorV3Interface);

  function eurOracle() external view returns (AggregatorV3Interface);

  function getAssetPrice(address _asset) external view returns (uint256);

  function convertFrom(address _asset, uint256 _amount) external view returns (uint256);

  function convertTo(address _asset, uint256 _amount) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma experimental ABIEncoderV2;
pragma solidity 0.6.12;

import "../interfaces/IAddressProvider.sol";

interface IRatesManager {
  function a() external view returns (IAddressProvider);

  //current annualized borrow rate
  function annualizedBorrowRate(uint256 _currentBorrowRate) external pure returns (uint256);

  //uses current cumulative rate to calculate totalDebt based on baseDebt at time T0
  function calculateDebt(uint256 _baseDebt, uint256 _cumulativeRate) external pure returns (uint256);

  //uses current cumulative rate to calculate baseDebt at time T0
  function calculateBaseDebt(uint256 _debt, uint256 _cumulativeRate) external pure returns (uint256);

  //calculate a new cumulative rate
  function calculateCumulativeRate(
    uint256 _borrowRate,
    uint256 _cumulativeRate,
    uint256 _timeElapsed
  ) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IAddressProvider.sol";

interface ISTABLEX is IERC20 {
  function mint(address account, uint256 amount) external;

  function burn(address account, uint256 amount) external;

  function a() external view returns (IAddressProvider);
}

// SPDX-License-Identifier: MIT

pragma experimental ABIEncoderV2;
pragma solidity 0.6.12;

import "../interfaces/IAddressProvider.sol";
import "../interfaces/IVaultsCoreState.sol";
import "../interfaces/IWETH.sol";
import "../liquidityMining/interfaces/IDebtNotifier.sol";

interface IVaultsCore {
  event Opened(uint256 indexed vaultId, address indexed collateralType, address indexed owner);
  event Deposited(uint256 indexed vaultId, uint256 amount, address indexed sender);
  event Withdrawn(uint256 indexed vaultId, uint256 amount, address indexed sender);
  event Borrowed(uint256 indexed vaultId, uint256 amount, address indexed sender);
  event Repaid(uint256 indexed vaultId, uint256 amount, address indexed sender);
  event Liquidated(
    uint256 indexed vaultId,
    uint256 debtRepaid,
    uint256 collateralLiquidated,
    address indexed owner,
    address indexed sender
  );

  event InsurancePaid(uint256 indexed vaultId, uint256 insuranceAmount, address indexed sender);

  function deposit(address _collateralType, uint256 _amount) external;

  function depositETH() external payable;

  function depositByVaultId(uint256 _vaultId, uint256 _amount) external;

  function depositETHByVaultId(uint256 _vaultId) external payable;

  function depositAndBorrow(
    address _collateralType,
    uint256 _depositAmount,
    uint256 _borrowAmount
  ) external;

  function depositETHAndBorrow(uint256 _borrowAmount) external payable;

  function withdraw(uint256 _vaultId, uint256 _amount) external;

  function withdrawETH(uint256 _vaultId, uint256 _amount) external;

  function borrow(uint256 _vaultId, uint256 _amount) external;

  function repayAll(uint256 _vaultId) external;

  function repay(uint256 _vaultId, uint256 _amount) external;

  function liquidate(uint256 _vaultId) external;

  function liquidatePartial(uint256 _vaultId, uint256 _amount) external;

  function upgrade(address payable _newVaultsCore) external;

  function acceptUpgrade(address payable _oldVaultsCore) external;

  function setDebtNotifier(IDebtNotifier _debtNotifier) external;

  //Read only
  function a() external view returns (IAddressProvider);

  function WETH() external view returns (IWETH);

  function debtNotifier() external view returns (IDebtNotifier);

  function state() external view returns (IVaultsCoreState);

  function cumulativeRates(address _collateralType) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma experimental ABIEncoderV2;
pragma solidity 0.6.12;
import "./IAddressProvider.sol";
import "../v1/interfaces/IVaultsCoreV1.sol";

interface IVaultsCoreState {
  event CumulativeRateUpdated(address indexed collateralType, uint256 elapsedTime, uint256 newCumulativeRate); //cumulative interest rate from deployment time T0

  function initializeRates(address _collateralType) external;

  function refresh() external;

  function refreshCollateral(address collateralType) external;

  function syncState(IVaultsCoreState _stateAddress) external;

  function syncStateFromV1(IVaultsCoreV1 _core) external;

  //Read only
  function a() external view returns (IAddressProvider);

  function availableIncome() external view returns (uint256);

  function cumulativeRates(address _collateralType) external view returns (uint256);

  function lastRefresh(address _collateralType) external view returns (uint256);

  function synced() external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma experimental ABIEncoderV2;
pragma solidity 0.6.12;
import "../interfaces/IAddressProvider.sol";

interface IVaultsDataProvider {
  struct Vault {
    // borrowedType support USDX / PAR
    address collateralType;
    address owner;
    uint256 collateralBalance;
    uint256 baseDebt;
    uint256 createdAt;
  }

  //Write
  function createVault(address _collateralType, address _owner) external returns (uint256);

  function setCollateralBalance(uint256 _id, uint256 _balance) external;

  function setBaseDebt(uint256 _id, uint256 _newBaseDebt) external;

  // Read
  function a() external view returns (IAddressProvider);

  function baseDebt(address _collateralType) external view returns (uint256);

  function vaultCount() external view returns (uint256);

  function vaults(uint256 _id) external view returns (Vault memory);

  function vaultOwner(uint256 _id) external view returns (address);

  function vaultCollateralType(uint256 _id) external view returns (address);

  function vaultCollateralBalance(uint256 _id) external view returns (uint256);

  function vaultBaseDebt(uint256 _id) external view returns (uint256);

  function vaultId(address _collateralType, address _owner) external view returns (uint256);

  function vaultExists(uint256 _id) external view returns (bool);

  function vaultDebt(uint256 _vaultId) external view returns (uint256);

  function debt() external view returns (uint256);

  function collateralDebt(address _collateralType) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma experimental ABIEncoderV2;
pragma solidity 0.6.12;

interface IWETH {
  function deposit() external payable;

  function transfer(address to, uint256 value) external returns (bool);

  function withdraw(uint256 wad) external;

  function approve(address guy, uint256 wad) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";

/******************
@title WadRayMath library
@author Aave
@dev Provides mul and div function for wads (decimal numbers with 18 digits precision) and rays (decimals with 27 digits)
 */

library WadRayMath {
  using SafeMath for uint256;

  uint256 internal constant _WAD = 1e18;
  uint256 internal constant _HALF_WAD = _WAD / 2;

  uint256 internal constant _RAY = 1e27;
  uint256 internal constant _HALF_RAY = _RAY / 2;

  uint256 internal constant _WAD_RAY_RATIO = 1e9;

  function ray() internal pure returns (uint256) {
    return _RAY;
  }

  function wad() internal pure returns (uint256) {
    return _WAD;
  }

  function halfRay() internal pure returns (uint256) {
    return _HALF_RAY;
  }

  function halfWad() internal pure returns (uint256) {
    return _HALF_WAD;
  }

  function wadMul(uint256 a, uint256 b) internal pure returns (uint256) {
    return _HALF_WAD.add(a.mul(b)).div(_WAD);
  }

  function wadDiv(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 halfB = b / 2;

    return halfB.add(a.mul(_WAD)).div(b);
  }

  function rayMul(uint256 a, uint256 b) internal pure returns (uint256) {
    return _HALF_RAY.add(a.mul(b)).div(_RAY);
  }

  function rayDiv(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 halfB = b / 2;

    return halfB.add(a.mul(_RAY)).div(b);
  }

  function rayToWad(uint256 a) internal pure returns (uint256) {
    uint256 halfRatio = _WAD_RAY_RATIO / 2;

    return halfRatio.add(a).div(_WAD_RAY_RATIO);
  }

  function wadToRay(uint256 a) internal pure returns (uint256) {
    return a.mul(_WAD_RAY_RATIO);
  }

  /**
   * @dev calculates x^n, in ray. The code uses the ModExp precompile
   * @param x base
   * @param n exponent
   * @return z = x^n, in ray
   */
  function rayPow(uint256 x, uint256 n) internal pure returns (uint256 z) {
    z = n % 2 != 0 ? x : _RAY;

    for (n /= 2; n != 0; n /= 2) {
      x = rayMul(x, x);

      if (n % 2 != 0) {
        z = rayMul(z, x);
      }
    }
  }
}

// SPDX-License-Identifier: MIT

pragma experimental ABIEncoderV2;
pragma solidity 0.6.12;

import "../../governance/interfaces/IGovernanceAddressProvider.sol";
import "./ISupplyMiner.sol";

interface IDebtNotifier {
  function debtChanged(uint256 _vaultId) external;

  function setCollateralSupplyMiner(address collateral, ISupplyMiner supplyMiner) external;

  function a() external view returns (IGovernanceAddressProvider);

  function collateralSupplyMinerMapping(address collateral) external view returns (ISupplyMiner);
}

// SPDX-License-Identifier: MIT

pragma experimental ABIEncoderV2;
pragma solidity 0.6.12;

import "../../interfaces/IAddressProvider.sol";
import "../../governance/interfaces/IGovernanceAddressProvider.sol";

interface IGenericMiner {
  struct UserInfo {
    uint256 stake;
    uint256 accAmountPerShare; // User's accAmountPerShare
  }

  /// @dev This emit when a users' productivity has changed
  /// It emits with the user's address and the the value after the change.
  event StakeIncreased(address indexed user, uint256 stake);

  /// @dev This emit when a users' productivity has changed
  /// It emits with the user's address and the the value after the change.
  event StakeDecreased(address indexed user, uint256 stake);

  function releaseMIMO(address _user) external;

  function a() external view returns (IGovernanceAddressProvider);

  function stake(address _user) external view returns (uint256);

  function pendingMIMO(address _user) external view returns (uint256);

  function totalStake() external view returns (uint256);

  function userInfo(address _user) external view returns (UserInfo memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IMIMO is IERC20 {
  function burn(address account, uint256 amount) external;

  function mint(address account, uint256 amount) external;
}

// SPDX-License-Identifier: MIT

pragma experimental ABIEncoderV2;
pragma solidity 0.6.12;

interface ISupplyMiner {
  function baseDebtChanged(address user, uint256 newBaseDebt) external;
}

// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;
pragma solidity 0.6.12;

import "./IConfigProviderV1.sol";
import "./ILiquidationManagerV1.sol";
import "./IVaultsCoreV1.sol";
import "../../interfaces/IVaultsCore.sol";
import "../../interfaces/IAccessController.sol";
import "../../interfaces/ISTABLEX.sol";
import "../../interfaces/IPriceFeed.sol";
import "../../interfaces/IRatesManager.sol";
import "../../interfaces/IVaultsDataProvider.sol";
import "../../interfaces/IFeeDistributor.sol";

interface IAddressProviderV1 {
  function setAccessController(IAccessController _controller) external;

  function setConfigProvider(IConfigProviderV1 _config) external;

  function setVaultsCore(IVaultsCoreV1 _core) external;

  function setStableX(ISTABLEX _stablex) external;

  function setRatesManager(IRatesManager _ratesManager) external;

  function setPriceFeed(IPriceFeed _priceFeed) external;

  function setLiquidationManager(ILiquidationManagerV1 _liquidationManager) external;

  function setVaultsDataProvider(IVaultsDataProvider _vaultsData) external;

  function setFeeDistributor(IFeeDistributor _feeDistributor) external;

  function controller() external view returns (IAccessController);

  function config() external view returns (IConfigProviderV1);

  function core() external view returns (IVaultsCoreV1);

  function stablex() external view returns (ISTABLEX);

  function ratesManager() external view returns (IRatesManager);

  function priceFeed() external view returns (IPriceFeed);

  function liquidationManager() external view returns (ILiquidationManagerV1);

  function vaultsData() external view returns (IVaultsDataProvider);

  function feeDistributor() external view returns (IFeeDistributor);
}

// SPDX-License-Identifier: MIT

pragma experimental ABIEncoderV2;
pragma solidity 0.6.12;

import "./IAddressProviderV1.sol";

interface IConfigProviderV1 {
  struct CollateralConfig {
    address collateralType;
    uint256 debtLimit;
    uint256 minCollateralRatio;
    uint256 borrowRate;
    uint256 originationFee;
  }

  event CollateralUpdated(
    address indexed collateralType,
    uint256 debtLimit,
    uint256 minCollateralRatio,
    uint256 borrowRate,
    uint256 originationFee
  );
  event CollateralRemoved(address indexed collateralType);

  function setCollateralConfig(
    address _collateralType,
    uint256 _debtLimit,
    uint256 _minCollateralRatio,
    uint256 _borrowRate,
    uint256 _originationFee
  ) external;

  function removeCollateral(address _collateralType) external;

  function setCollateralDebtLimit(address _collateralType, uint256 _debtLimit) external;

  function setCollateralMinCollateralRatio(address _collateralType, uint256 _minCollateralRatio) external;

  function setCollateralBorrowRate(address _collateralType, uint256 _borrowRate) external;

  function setCollateralOriginationFee(address _collateralType, uint256 _originationFee) external;

  function setLiquidationBonus(uint256 _bonus) external;

  function a() external view returns (IAddressProviderV1);

  function collateralConfigs(uint256 _id) external view returns (CollateralConfig memory);

  function collateralIds(address _collateralType) external view returns (uint256);

  function numCollateralConfigs() external view returns (uint256);

  function liquidationBonus() external view returns (uint256);

  function collateralDebtLimit(address _collateralType) external view returns (uint256);

  function collateralMinCollateralRatio(address _collateralType) external view returns (uint256);

  function collateralBorrowRate(address _collateralType) external view returns (uint256);

  function collateralOriginationFee(address _collateralType) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma experimental ABIEncoderV2;
pragma solidity 0.6.12;

import "./IAddressProviderV1.sol";

interface ILiquidationManagerV1 {
  function a() external view returns (IAddressProviderV1);

  function calculateHealthFactor(
    address _collateralType,
    uint256 _collateralValue,
    uint256 _vaultDebt
  ) external view returns (uint256 healthFactor);

  function liquidationBonus(uint256 _amount) external view returns (uint256 bonus);

  function applyLiquidationDiscount(uint256 _amount) external view returns (uint256 discountedAmount);

  function isHealthy(
    address _collateralType,
    uint256 _collateralValue,
    uint256 _vaultDebt
  ) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma experimental ABIEncoderV2;
pragma solidity 0.6.12;
import "./IAddressProviderV1.sol";

interface IVaultsCoreV1 {
  event Opened(uint256 indexed vaultId, address indexed collateralType, address indexed owner);
  event Deposited(uint256 indexed vaultId, uint256 amount, address indexed sender);
  event Withdrawn(uint256 indexed vaultId, uint256 amount, address indexed sender);
  event Borrowed(uint256 indexed vaultId, uint256 amount, address indexed sender);
  event Repaid(uint256 indexed vaultId, uint256 amount, address indexed sender);
  event Liquidated(
    uint256 indexed vaultId,
    uint256 debtRepaid,
    uint256 collateralLiquidated,
    address indexed owner,
    address indexed sender
  );

  event CumulativeRateUpdated(address indexed collateralType, uint256 elapsedTime, uint256 newCumulativeRate); //cumulative interest rate from deployment time T0

  event InsurancePaid(uint256 indexed vaultId, uint256 insuranceAmount, address indexed sender);

  function deposit(address _collateralType, uint256 _amount) external;

  function withdraw(uint256 _vaultId, uint256 _amount) external;

  function withdrawAll(uint256 _vaultId) external;

  function borrow(uint256 _vaultId, uint256 _amount) external;

  function repayAll(uint256 _vaultId) external;

  function repay(uint256 _vaultId, uint256 _amount) external;

  function liquidate(uint256 _vaultId) external;

  //Refresh
  function initializeRates(address _collateralType) external;

  function refresh() external;

  function refreshCollateral(address collateralType) external;

  //upgrade
  function upgrade(address _newVaultsCore) external;

  //Read only

  function a() external view returns (IAddressProviderV1);

  function availableIncome() external view returns (uint256);

  function cumulativeRates(address _collateralType) external view returns (uint256);

  function lastRefresh(address _collateralType) external view returns (uint256);
}