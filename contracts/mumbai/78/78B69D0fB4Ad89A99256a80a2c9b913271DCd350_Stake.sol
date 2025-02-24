// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.8.0;

import '@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol';
import '../libraries/SignedSafeMath.sol';
import '../interfaces/IStake.sol';
import './CandidateRegistry.sol';
import './Pools.sol';

/// @dev Stake contract
/// @author Alexandas
contract Stake is IStake, CandidateRegistry, Pools, ReentrancyGuardUpgradeable {

	using SignedSafeMath for int256;

	/// @dev return `Election` contract
	IElection public override election;

	/// @dev return `MajorCandidates` contract
	IMajorCandidates public override majorCandidates;

	/// @dev return `Slasher` contract
	ISlasher public override slasher;

	/// @dev return minimum stake for registering a candidate
	uint256 public minStake;

	/// @dev return stake frozen period
	uint256 public stakeFrozenPeriod;

	/// @dev return last stake timestamp for a candidate
	mapping(address => Types.CandidateApplyInfo) public candidateApplyInfo;

	/// @dev return vote reward coefficient for a candidate
	mapping(address => uint256) internal voteRewardCoefs;

	modifier onlyElection() {
		require(msg.sender == address(election), 'Stake: caller must be Election contract');
		_;
	}

	modifier onlyMajorCandidates() {
		require(msg.sender == address(majorCandidates), 'Stake: caller must be MajorCandidates contract');
		_;
	}

	modifier onlySlasher() {
		require(msg.sender == address(slasher), 'Stake: caller must be Slasher contract');
		_;
	}

	/// @dev proxy initialize function
	/// @param token ERC20 token address
	/// @param rewarder `Rewarder` contract
	/// @param _election `Election` contract 
	/// @param _majorCandidates `MajorCandidates` contract
	/// @param _slasher `Slasher` contract
	/// @param _stakeFrozenPeriod stake frozen period
	/// @param _minStake minimum stake for candidate
	/// @param rewardPerSecond reward generated per second
	function initialize(
		IERC20 token,
		IRewarder rewarder,
		IElection _election,
		IMajorCandidates _majorCandidates,
		ISlasher _slasher,
		uint256 _stakeFrozenPeriod,
		uint256 _minStake,
		uint256 rewardPerSecond
	) external initializer {
		_setToken(token);
		_setRewarder(rewarder);
		_setElection(_election);
		_setMajorCandidates(_majorCandidates);
		_setSlasher(_slasher);
		_setStakeFrozenPeriod(_stakeFrozenPeriod);
		_setMinStake(_minStake);
		_setRewardPerSecond(rewardPerSecond);
		_setMaxCoef(1e6);
		_setAccPrecision(1e12);
		_addPool(Types.Grade.Major, 750);
		_addPool(Types.Grade.Secondary, 250);
	}

	/// @dev candidate stake tokens
	/// @param amount token amount
	function stake(uint256 amount) external override  {
		_stake(msg.sender, msg.sender, amount);
	}

	/// @dev register a candidate and stake tokens
	/// @param amount token amount
	/// @param manifest node manifest
	function registerAndStake(uint256 amount, string memory manifest) external override  {
		_register(msg.sender, manifest);
		_stake(msg.sender, msg.sender, amount);
	}

	function _stake(
		address user,
		address _candidate,
		uint256 amount
	) internal {
		require(!isCandidateWaitingQuit(_candidate), 'Stake: candidate is waiting to quit');
		require(isCandidateRegistered(_candidate), 'Stake: candidate is not registered');
		Types.CandidateInfo storage candidate = candidates[_candidate];
		Types.PoolInfo memory pool = updatePool(candidate.grade);
		require(amount + candidate.amount >= minStake, 'Stake: total amount is less than minimum stake');
		token.transferFrom(user, address(this), amount);
		candidate.amount += amount;
		candidate.rewardDebt += int256(amount * pool.accPerShare / ACC_PRECISION);
		lpSupplies[candidate.grade] += amount;

		emit Stake(user, _candidate, amount);
	}

	function isCandidateWaitingQuit(address candidate) public view returns(bool) {
		return candidateApplyInfo[candidate].waitQuit;
	}

	/// @dev candidate apply to quit from the protocol
	function applyQuit() external override nonReentrant {
		_applyQuit(msg.sender);
	}

	function _applyQuit(address _candidate) internal {
		require(!slasher.slashExists(_candidate), 'Stake: slash exists on candidate');
		require(!isCandidateWaitingQuit(_candidate), 'Stake: candidate is waiting quit');
		Types.CandidateInfo storage candidate = candidates[_candidate];
		uint256 amount = candidate.amount;
		if (amount > 0) {
			_allocate(_candidate);
			candidate.rewardDebt = 0;
			candidate.amount = 0;
			lpSupplies[candidate.grade] -= amount;
			Types.CandidateApplyInfo storage applyInfo = candidateApplyInfo[_candidate];
			applyInfo.waitQuit = true;
			applyInfo.amount += amount;
			applyInfo.endTime = block.timestamp + stakeFrozenPeriod;
			if (majorCandidates.exists(_candidate)) {
				majorCandidates.remove(_candidate);
			}
		}
		emit ApplyWithdrawn(_candidate, amount);
		emit ApplyQuit(_candidate);
	}

	/// @dev candidate quit from the protocol
	/// @param to token receiver
	function quit(address to) external override nonReentrant  {
		address candidate = msg.sender;
		require(isQuitUnfrozen(candidate), 'Stake: quit is frozen');
		uint256 amount = candidateApplyInfo[candidate].amount;
		Types.CandidateInfo memory candidateInfo = candidates[candidate];
		delete candidates[candidate];
		delete manifestMap[candidateInfo.manifest];
		delete candidateApplyInfo[candidate];
		token.transfer(to, amount);
		emit Withdrawn(candidate, to, amount);
	}

	/// @dev candidate claim reward from the protocol
	/// @param to token receiver
	function claim(address to) external override nonReentrant {
		_allocate(msg.sender);
		uint allocation = candidates[msg.sender].allocation;
		candidates[msg.sender].allocation = 0;
		rewarder.mint(to, allocation);
		emit Claimed(msg.sender, to, allocation);
	}

	function isQuitUnfrozen(address candidate) public view returns(bool) {
		if (candidateApplyInfo[candidate].endTime == 0) {
			return false;
		}
		return block.timestamp >= candidateApplyInfo[candidate].endTime;
	}

	function _setMinStake(uint256 amount) internal {
		minStake = amount;
		emit MinStakeUpdated(amount);
	}

	function _setStakeFrozenPeriod(uint256 period) internal {
		stakeFrozenPeriod = period;
		emit StakeFrozenPeriodUpdated(period);
	}

	function _setMajorCandidates(IMajorCandidates _majorCandidates) internal {
		majorCandidates = _majorCandidates;
		emit IMajorCandidatesUpdated(_majorCandidates);
	}

	/// @dev upgrade a candidate
	/// @param candidate candidate address
	function upgrade(address candidate) external override onlyMajorCandidates {
		_onCandidateGradeChanged(candidate, Types.Grade.Major);
		emit Upgrade(candidate, Types.Grade.Secondary, Types.Grade.Major);
	}

	/// @dev downgrade a candidate
	/// @param candidate candidate address
	function downgrade(address candidate) external override onlyMajorCandidates {
		_onCandidateGradeChanged(candidate, Types.Grade.Secondary);
		emit Downgrade(candidate, Types.Grade.Major, Types.Grade.Secondary);
	}

	// make sure pool updated and reward allocated
	function _onCandidateGradeChanged(address _candidate, Types.Grade grade) internal {
		_allocate(_candidate);
		Types.CandidateInfo storage candidate = candidates[_candidate];
		lpSupplies[candidate.grade] -= candidate.amount;
		Types.PoolInfo memory pool = updatePool(grade);
		candidate.rewardDebt = int256(candidate.amount * pool.accPerShare / ACC_PRECISION);
		candidate.grade = grade;
		lpSupplies[grade] += candidate.amount;
	}

	/// @dev set allocate the reward to voters from the candidate
	/// @param candidate candidate address
	function voterAllocate(address candidate) external override onlyElection  {
		_allocate(candidate);
	}

	function _allocate(address _candidate) internal {
		if (isCandidateRegistered(_candidate)) {
			Types.CandidateInfo storage candidate = candidates[_candidate];
			Types.PoolInfo memory pool = updatePool(candidate.grade);
			int256 accumulated = int256(candidate.amount * pool.accPerShare / ACC_PRECISION);
			uint256 _pending = (accumulated - candidate.rewardDebt).toUInt256();
			candidate.rewardDebt = accumulated;
			uint256 allocation = _allocateReward(_candidate, _pending);
			if (allocation > 0) {
				candidate.allocation = candidate.allocation + allocation;
				emit CandidateAllocated(_candidate, allocation);
			}
		}
	}

	function _allocateReward(
		address _candidate,
		uint256 _pending
	) internal returns(uint256 pendingAllocation) {
		if (_pending > 0) {
			pendingAllocation = _pending;
			if (voteRewardCoef(_candidate) > 0 && election.voteSupply(_candidate) > 0) {
				uint256 allocation = _pending * voteRewardCoef(_candidate) / MAXCOEF;
				election.onAllocate(_candidate, allocation);
				pendingAllocation = _pending - allocation;
				emit VoterAllocated(_candidate, allocation);
			}
		}
	}

	/// @dev set voter slash reward coefficient
	/// @param coef voter reward coefficient
	function setVoteRewardCoef(uint256 coef) external override  {
		_setVoteRewardCoef(msg.sender, coef);
	}

	function _setVoteRewardCoef(address candidate, uint256 coef) internal {
		require(coef > 0 && coef <= MAXCOEF, 'Stake: invalid coef');
		require(isCandidateRegistered(candidate), 'Stake: candidate is not registered');
		_allocate(candidate);
		voteRewardCoefs[candidate] = coef;
		emit VoteRewardCoefUpdated(coef);
	}

	function _setElection(IElection _election) internal {
		election = _election;
		emit ElectionUpdated(_election);
	}

	function _pendingReward(address _candidate) internal view returns (uint256 pending) { 
		Types.CandidateInfo storage candidate = candidates[_candidate];
		Types.PoolInfo memory pool = pools[candidate.grade];
		uint256 accPerShare = pool.accPerShare;
		uint256 lpSupply = token.balanceOf(address(this));
		if (block.timestamp > pool.lastRewardTime && lpSupply != 0) {
			uint256 time = block.timestamp - pool.lastRewardTime;
			uint256 reward = time * rewardPerSecond * pool.allocPoint / totalAllocPoint;
			accPerShare = accPerShare + (reward * ACC_PRECISION / lpSupply);
		}
		pending = int256(int256(candidate.amount * accPerShare / ACC_PRECISION) - candidate.rewardDebt).toUInt256();
	}

	/// @dev return pending candidate allocation
	/// @param _candidate candidate address
	/// @return pendingAllocation pending candidate allocation
	function pendingCandidateAllocation(address _candidate) public view override returns (uint256 pendingAllocation) {
		pendingAllocation = _pendingReward(_candidate);
		if (voteRewardCoef(_candidate) == 0) {
			return pendingAllocation;
		}
		if (election.voteSupply(_candidate) == 0) {
			return pendingAllocation;
		}
		pendingAllocation = pendingAllocation * (MAXCOEF - voteRewardCoef(_candidate)) / MAXCOEF;
	}

	/// @dev return pending voters allocation for a specific candidate
	/// @param _candidate candidate address
	/// @return pendingAllocation pending voters allocation
	function pendingVoterAllocation(address _candidate) public view override returns (uint256 pendingAllocation) {
		if (voteRewardCoef(_candidate) > 0 && election.voteSupply(_candidate) > 0) {
			uint256 pending = _pendingReward(_candidate);
			pendingAllocation = pending * voteRewardCoef(_candidate) / MAXCOEF;
		}
	}

	/// @dev return pending reward for a specific candidate
	/// @param _candidate candidate address
	/// @return pending reward for the candidate
	function pendingReward(address _candidate) public view override returns (uint256 pending) {
		pending = pendingCandidateAllocation(_candidate) + candidates[_candidate].allocation;
	}

	/// @dev return voter reward coefficient for a specific candidate
	/// @param candidate candidate address
	/// @return coef voter reward coefficient
	function voteRewardCoef(address candidate) public view override returns (uint256) {
		return voteRewardCoefs[candidate];
	}

	function _setSlasher(ISlasher _slasher) internal {
		slasher = _slasher;
		emit SlasherUpdated(_slasher);
	}

	/// @dev draft a slash for a candidate
	/// @param _candidate candidate address
	/// @param amount slash amount
	function draftSlash(address _candidate, uint256 amount) external override onlySlasher  {
		Types.CandidateInfo storage candidate = candidates[_candidate];
		require(candidate.locked == 0, 'Stake: candidate has locked tokens');
		Types.CandidateApplyInfo storage applyInfo = candidateApplyInfo[_candidate];
		if (applyInfo.waitQuit) {
			applyInfo.amount -= amount;
			candidate.slash += amount;
			candidate.locked = candidate.amount;
		} else {
			_allocate(_candidate);
			lpSupplies[candidate.grade] -= amount;
			candidate.slash += amount;
			candidate.locked = candidate.amount - amount;
			candidate.rewardDebt = 0;
		}
		candidate.amount = 0;
		emit DraftSlash(_candidate, amount);
	}

	/// @dev reject a slash for a candidate
	/// @param _candidate candidate address
	/// @param pendingSlash real slash amount
	function rejectSlash(address _candidate, uint256 pendingSlash) external override onlySlasher  {
		Types.CandidateInfo storage candidate = candidates[_candidate];
		Types.PoolInfo memory pool = updatePool(candidate.grade);
		Types.CandidateApplyInfo storage applyInfo = candidateApplyInfo[_candidate];
		if (applyInfo.waitQuit) {
			applyInfo.amount += pendingSlash;
			candidate.amount += candidate.locked;
		} else {
			uint256 totalLocked = candidate.locked + pendingSlash;
			candidate.rewardDebt = candidate.rewardDebt + int256(totalLocked * pool.accPerShare / ACC_PRECISION);
			candidate.amount = candidate.amount + totalLocked;
			lpSupplies[candidate.grade] += totalLocked;
		}
		candidate.locked = 0;
		candidate.slash -= pendingSlash;
		emit RejectSlash(_candidate, pendingSlash);
	}

	/// @dev executed a slash for a candiate
	/// @param _candidate candidate address
	/// @param slash slash amount
	/// @param beneficiaries slash reward beneficiaries
	/// @param amounts slash reward amounts
	/// @param burned burned amount
	function executeSlash(
		address _candidate,
		uint256 slash,
		address[] memory beneficiaries,
		uint256[] memory amounts,
		uint256 burned
	) external override onlySlasher nonReentrant  {
		require(beneficiaries.length == amounts.length, 'Stake: invalid params');
		Types.CandidateInfo storage candidate = candidates[_candidate];
		Types.PoolInfo memory pool = updatePool(candidate.grade);
		candidate.rewardDebt = candidate.rewardDebt + int256(candidate.locked * pool.accPerShare / ACC_PRECISION);
		candidate.amount = candidate.amount + candidate.locked;
		candidate.slash -= slash;
		candidate.locked = 0;
		if (candidate.amount < minStake) {
			if (!isCandidateWaitingQuit(_candidate)) {
				_applyQuit(_candidate);
			}
		}
		for (uint8 i = 0; i < beneficiaries.length; i++) {
			token.transfer(beneficiaries[i], amounts[i]);
		}
		token.burn(burned);
		emit ExcuteSlash(_candidate, slash, beneficiaries, amounts, burned);
	}

	function totalStake(address _candidate) public view returns(uint256) {
		Types.CandidateInfo memory candidate = candidates[_candidate];
		return candidate.amount + candidate.locked;
	}

	function majorCandidateManifests() external view returns(string[] memory manifests) {
		address[] memory candidates = majorCandidates.majorCandidateList();
		manifests = new string[](candidates.length);
		for (uint256 i = 0; i < candidates.length; i++) {
			Types.CandidateInfo memory candidate = candidateInfo(candidates[i]);
			manifests[i] = candidate.manifest;
		}
	}

}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.8.0;

library SignedSafeMath {
    int256 constant private _INT256_MIN = -2**255;

    /**
     * @dev Returns the multiplication of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        require(!(a == -1 && b == _INT256_MIN), 'SignedSafeMath: multiplication overflow');

        int256 c = a * b;
        require(c / a == b, 'SignedSafeMath: multiplication overflow');

        return c;
    }

    /**
     * @dev Returns the integer division of two signed integers. Reverts on
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
    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0, 'SignedSafeMath: division by zero');
        require(!(b == -1 && a == _INT256_MIN), 'SignedSafeMath: division overflow');

        int256 c = a / b;

        return c;
    }

    /**
     * @dev Returns the subtraction of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a), 'SignedSafeMath: subtraction overflow');

        return c;
    }

    /**
     * @dev Returns the addition of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a), 'SignedSafeMath: addition overflow');

        return c;
    }

    function toUInt256(int256 a) internal pure returns (uint256) {
        require(a >= 0, 'Integer < 0');
        return uint256(a);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.8.0;

import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '../interfaces/IPools.sol';

/// @dev Pools contract
/// @author Alexandas
contract Pools is IPools {

	/// @dev return ERC20 token address
	IERC20 public override token;

	/// @dev return `Rewarder` contract address
	IRewarder public override rewarder;

	/// @dev return precision for shares
	uint256 public override ACC_PRECISION;

	/// @dev return max coefficient
	uint256 public override MAXCOEF;

	/// @dev return total pools allocation points
	uint256 public override totalAllocPoint;

	/// @dev return reward generated for per second
	uint256 public override rewardPerSecond;

	mapping(Types.Grade => Types.PoolInfo) internal pools;

	mapping(Types.Grade => uint256) internal lpSupplies;

	function _addPool(
		Types.Grade grade,
		uint256 allocPoint
	) internal {
		require(pools[grade].allocPoint == 0, 'Pools: pool exists');
		totalAllocPoint = totalAllocPoint + allocPoint;
		pools[grade] = Types.PoolInfo({ allocPoint: allocPoint, lastRewardTime: block.timestamp, accPerShare: 0 });
		emit AddPool(grade);
	}

	/// @dev update a specific pool
	/// @param grade pool grade
	/// @return pool pool info
	function updatePool(Types.Grade grade) public override returns (Types.PoolInfo memory pool) {
		require(poolExists(grade), 'Pools: nonexistent pool');
		pool = pools[grade];
		if (block.timestamp > pool.lastRewardTime) {
			uint256 lpSupply = lpSupplies[grade];
			if (lpSupply > 0) {
				uint256 time = block.timestamp - pool.lastRewardTime;
				uint256 reward = time * rewardPerSecond * pool.allocPoint / totalAllocPoint;
				pool.accPerShare = pool.accPerShare + (reward * ACC_PRECISION / lpSupply);
			}
			pool.lastRewardTime = block.timestamp;
			pools[grade] = pool;
		}
		emit PoolUpdated(grade);
	}

	/// @dev return a specific pool
	/// @param grade pool grade
	/// @return pool pool info
	function poolInfo(Types.Grade grade) public view override returns (Types.PoolInfo memory) {
		return pools[grade];
	}

	function poolExists(Types.Grade grade) public view returns (bool) {
		return pools[grade].allocPoint != 0;
	}

	function _setRewardPerSecond(uint256 _rewardPerSecond) internal {
		rewardPerSecond = _rewardPerSecond;
		emit RewardPerSecondUpdated(_rewardPerSecond);
	}

	function _setToken(IERC20 _token) internal {
		token = _token;
		emit TokenUpdated(_token);
	}

	function _setRewarder(IRewarder _rewarder) internal {
		rewarder = _rewarder;
		emit RewarderUpdated(_rewarder);
	}

	function _setMaxCoef(uint256 _maxCoef) internal {
		MAXCOEF = _maxCoef;
		emit MaxCoefUpdated(_maxCoef);
	}

	function _setAccPrecision(uint256 _precision) internal {
		ACC_PRECISION = _precision;
		emit PrecisionUpdated(_precision);
	}

}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.8.0;

import '../interfaces/ICandidateRegistry.sol';

/// @dev Candidate registry contract
/// @author Alexandas
contract CandidateRegistry is ICandidateRegistry {

	mapping(address => Types.CandidateInfo) internal candidates;

	/// @dev return a candidate address for a specific node manifest
	mapping(string => address) public override manifestMap;

	/// @dev register a candidate with node manifest
	/// @param manifest node manifest
	function register(string memory manifest) external override {
		_register(msg.sender, manifest);
	}

	function _register(address candidate, string memory manifest) internal {
		require(candidates[candidate].grade == Types.Grade.Null, 'CandidateRegistry: candidate exists');
		require(manifestMap[manifest] == address(0), 'CandidateRegistry: manifest exists');
		manifestMap[manifest] = candidate;
		candidates[candidate].grade = Types.Grade.Secondary;
		candidates[candidate].manifest = manifest;
		emit Register(candidate);
	}

	/// @dev return a candidate
	/// @param candidate candidate address
	/// @return candidate information
	function candidateInfo(address candidate) public view override returns (Types.CandidateInfo memory) {
		return candidates[candidate];
	}

	/// @dev return whether a candidate is registered
	/// @param candidate candidate address
	/// @return whether the candidate is registered
	function isCandidateRegistered(address candidate) public view override returns (bool) {
		return candidates[candidate].grade != Types.Grade.Null;
	}

	/// @dev return grade of a candidate
	/// @param candidate candidate address
	/// @return candidate grade
	function gradeOf(address candidate) public view override returns (Types.Grade) {
		return candidates[candidate].grade;
	}

}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.8.0;

import './IElection.sol';
import './IMajorCandidates.sol';
import './ISlasher.sol';
import './IPools.sol';
import './ICandidateRegistry.sol';

/// @dev Stake interface
/// @author Alexandas
interface IStake is IPools, ICandidateRegistry {

	/// @dev emit when `Election` contract changed
	/// @param election `Election` contract address
	event ElectionUpdated(IElection election);

	/// @dev emit when `MajorCandidates` contract updated
	/// @param majorCandidates `MajorCandidates` contract 
	event IMajorCandidatesUpdated(IMajorCandidates majorCandidates);

	/// @dev emit when `Slasher` contract updated
	/// @param slasher `Slasher` contract 
	event SlasherUpdated(ISlasher slasher);

	/// @dev emit when minimum stake updated
	/// @param amount minimum stake
	event MinStakeUpdated(uint256 amount);

	/// @dev emit when stake frozen period updated
	/// @param period stake frozen period
	event StakeFrozenPeriodUpdated(uint256 period);

	/// @dev emit when a candidate upgraded
	/// @param candidate candidate address
	/// @param fromGrade from grade
	/// @param toGrade to grade
	event Upgrade(address candidate, Types.Grade fromGrade, Types.Grade toGrade);

	/// @dev emit when a candidate downgraded
	/// @param candidate candidate address
	/// @param fromGrade from grade
	/// @param toGrade to grade
	event Downgrade(address candidate, Types.Grade fromGrade, Types.Grade toGrade);

	/// @dev emit when a candidate staked tokens
	/// @param from token consumer
	/// @param candidate candidate address
	/// @param amount token amount
	event Stake(address from, address candidate, uint256 amount);

	event ApplyWithdrawn(address candidate, uint256 amount);

	event ApplyQuit(address candidate);

	/// @dev emit when a candidate withdraw tokens
	/// @param candidate candidate address
	/// @param to token receiver
	/// @param amount token amount
	event Withdrawn(address candidate, address to, uint256 amount);

	/// @dev emit when a candidate claimed reward
	/// @param candidate candidate address
	/// @param to token receiver
	/// @param amount token amount
	event Claimed(address candidate, address to, uint256 amount);

	/// @dev emit when a candidate allocate reward for the voters
	/// @param candidate candidate address
	/// @param amount token amount
	event VoterAllocated(address candidate, uint256 amount);

	/// @dev emit when the reward for a candidate
	/// @param candidate candidate address
	/// @param amount token amount
	event CandidateAllocated(address candidate, uint256 amount);

	/// @dev emit when the vote reward coefficient updated
	/// @param coef vote reward coefficient
	event VoteRewardCoefUpdated(uint256 coef);

	/// @dev emit when drafted a slash
	/// @param candidate candidate address
	/// @param pendingSlash pending slash amount
	event DraftSlash(address candidate, uint256 pendingSlash);

	/// @dev emit when rejected a slash
	/// @param candidate candidate address
	/// @param pendingSlash pending slash amount
	event RejectSlash(address candidate, uint256 pendingSlash);

	/// @dev emit when executed a slash
	/// @param candidate candidate address
	/// @param pendingSlash pending slash amount
	/// @param beneficiaries slash reward beneficiaries
	/// @param amounts slash reward amounts
	/// @param burned burned amount
	event ExcuteSlash(address candidate, uint256 pendingSlash, address[] beneficiaries, uint256[] amounts, uint256 burned);

	/// @dev return `Election` contract
	function election() external view returns(IElection);

	/// @dev return `MajorCandidates` contract
	function majorCandidates() external view returns(IMajorCandidates);

	/// @dev return `Slasher` contract
	function slasher() external returns(ISlasher);

	/// @dev candidate stake tokens
	/// @param amount token amount
	function stake(uint256 amount) external;

	/// @dev candidate apply to quit
	function applyQuit() external;

	/// @dev register a candidate and stake tokens
	/// @param amount token amount
	/// @param manifest node manifest
	function registerAndStake(uint256 amount, string memory manifest) external;

	/// @dev candidate quit from the protocol
	/// @param to token receiver
	function quit(address to) external;

	/// @dev candidate claim reward from the protocol
	/// @param to token receiver
	function claim(address to) external;

	/// @dev candidate withdraw the tokens and claim reward from the protocol
	/// @param amount token amount
	/// @param to token receiver
	// function withdrawAndClaim(uint256 amount, address to) external;

	/// @dev return pending reward for a specific candidate
	/// @param candidate candidate address
	/// @return pending reward for the candidate
	function pendingReward(address candidate) external view returns (uint256 pending);

	/// @dev set voter slash reward coefficient
	/// @param coef voter reward coefficient
	function setVoteRewardCoef(uint256 coef) external;

	/// @dev set allocate the reward to voters from the candidate
	/// @param candidate candidate address
	function voterAllocate(address candidate) external;

	/// @dev return voter reward coefficient for a specific candidate
	/// @param candidate candidate address
	/// @return coef voter reward coefficient
	function voteRewardCoef(address candidate) external view returns (uint256 coef);

	/// @dev return pending voters allocation for a specific candidate
	/// @param candidate candidate address
	/// @return pending pending voters allocation
	function pendingVoterAllocation(address candidate) external view returns (uint256 pending);

	/// @dev return pending candidate allocation
	/// @param candidate candidate address
	/// @return pending pending candidate allocation
	function pendingCandidateAllocation(address candidate) external view returns (uint256 pending);

	/// @dev upgrade a candidate
	/// @param candidate candidate address
	function upgrade(address candidate) external;

	/// @dev downgrade a candidate
	/// @param candidate candidate address
	function downgrade(address candidate) external;

	/// @dev draft a slash for a candidate
	/// @param candidate candidate address
	/// @param amount slash amount
	function draftSlash(address candidate, uint256 amount) external;

	/// @dev reject a slash for a candidate
	/// @param candidate candidate address
	/// @param pendingSlash real slash amount
	function rejectSlash(address candidate, uint256 pendingSlash) external;

	/// @dev executed a slash for a candiate
	/// @param candidate candidate address
	/// @param slash slash amount
	/// @param beneficiaries slash reward beneficiaries
	/// @param amounts slash reward amounts
	/// @param burned burned amount
	function executeSlash(
		address candidate, 
		uint256 slash,
		address[] memory beneficiaries, 
		uint256[] memory amounts,
		uint256 burned
	) external;
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

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.8.0;

import './IERC20.sol';
import './IRewarder.sol';
import '../libraries/Types.sol';

/// @dev Pools interface
/// @author Alexandas
interface IPools {

	/// @dev emit when ERC20 Token contract updated
	/// @param token ERC20 Token contract
	event TokenUpdated(IERC20 token);

	/// @dev emit when `Rewarder` contract updated
	/// @param rewarder `Rewarder` contract 
	event RewarderUpdated(IRewarder rewarder);

	/// @dev emit when `rewardPerSecond` updated
	/// @param rewardPerSecond reward generated for per second
	event RewardPerSecondUpdated(uint256 rewardPerSecond);

	/// @dev emit when shares precision updated
	/// @param precision shares precision
	event PrecisionUpdated(uint256 precision);

	/// @dev emit when max coefficient updated
	/// @param maxCoef max coefficient
	event MaxCoefUpdated(uint256 maxCoef);

	/// @dev emit when add a pool
	/// @param grade pool grade
	event AddPool(Types.Grade grade);

	/// @dev emit when pool updated
	/// @param grade pool grade
	event PoolUpdated(Types.Grade grade);

	/// @dev return ERC20 token address
	function token() external view returns(IERC20);

	/// @dev return `Rewarder` contract address
	function rewarder() external view returns(IRewarder);

	/// @dev return precision for shares
	function ACC_PRECISION() external view returns(uint256);

	/// @dev return max coefficient
	function MAXCOEF() external view returns(uint256);

	/// @dev return total pools allocation points
	function totalAllocPoint() external view returns(uint256);

	/// @dev return reward generated for per second
	function rewardPerSecond() external view returns(uint256);

	/// @dev update a specific pool
	/// @param grade pool grade
	/// @return pool pool info
	function updatePool(Types.Grade grade) external returns (Types.PoolInfo memory pool);

	/// @dev return a specific pool
	/// @param grade pool grade
	/// @return pool pool info
	function poolInfo(Types.Grade grade) external view returns(Types.PoolInfo memory);

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.8.0;

library Types {

	enum Grade {
		Null,
		Major,
		Secondary
	}

	struct CandidateApplyInfo {
		bool waitQuit;
		uint256 amount;
		uint256 endTime;
	}

	struct CandidateInfo {
		Grade grade;
		uint256 amount;
		int256 rewardDebt;
		uint256 allocation;
		uint256 locked;
		uint256 slash;
		string manifest;
	}

	struct PoolInfo {
		uint256 accPerShare;
		uint256 lastRewardTime;
		uint256 allocPoint;
	}

	enum SlashStatus {
		Drafted,
		Rejected,
		Executed
	}

	struct SlashInfo {
		address candidate;
		address drafter;
		address[] validators;
		uint256 amount;
		uint256 timestamp;
		SlashStatus status;
	}

}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.8.0;

import '@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol';

/// @dev Burnable ERC20 Token interface
/// @author Alexandas
interface IERC20 is IERC20Upgradeable {

	/// @dev burn tokens
	/// @param amount token amount
	function burn(uint256 amount) external;

	/// @dev burn tokens
	/// @param account user address
	/// @param amount token amount
	function burnFrom(address account, uint256 amount) external;

}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.8.0;

import '@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol';
import './IERC20.sol';

/// @dev Rewarder interface
/// @author Alexandas
interface IRewarder {

	/// @dev emit when ERC20 token address updated
	/// @param token ERC20 token address
	event TokenUpdated(IERC20 token);

	/// @dev emit when auth address updated
	/// @param auth authorized address
	event AuthUpdated(address auth);

	/// @dev emit when reward minted
	/// @param from authorized address
	/// @param to receiver address
	/// @param amount token amount
	event Minted(address from, address to, uint256 amount);

	/// @dev return ERC20 token address
	function token() external view returns(IERC20);

	/// @dev mint reward to receiver
	/// @param to receiver address
	/// @param amount token amount
	function mint(address to, uint256 amount) external;

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

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.8.0;

import '../libraries/Types.sol';

/// @dev Candidate registry interface
/// @author Alexandas
interface ICandidateRegistry {

	/// @dev emit when candidate registered
	/// @param candidate candidate address
	event Register(address candidate);

	/// @dev register a candidate with node manifest
	/// @param manifest node manifest
	function register(string memory manifest) external;

	/// @dev return a candidate
	/// @param candidate candidate address
	/// @return candidate information
	function candidateInfo(address candidate) external view returns(Types.CandidateInfo memory);

	/// @dev return a candidate address for a specific node manifest
	/// @param manifest node manifest
	/// @return candidate address
	function manifestMap(string memory manifest) external view returns(address);

	/// @dev return whether a candidate is registered
	/// @param candidate candidate address
	/// @return whether the candidate is registered
	function isCandidateRegistered(address candidate) external view returns (bool);

	/// @dev return grade of a candidate
	/// @param candidate candidate address
	/// @return candidate grade
	function gradeOf(address candidate) external view returns (Types.Grade);

}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.8.0;

import './IRewarder.sol';
import './IStake.sol';
import './IMajorCandidates.sol';
import './IERC20.sol';

/// @dev Election contract interface
/// @author Alexandas
interface IElection {

	/// @dev emit when ERC20 token address updated
	/// @param token ERC20 token address
	event TokenUpdated(IERC20 token);

	/// @dev emit when `Rewarder` contract updated
	/// @param rewarder `Rewarder` contract 
	event RewarderUpdated(IRewarder rewarder);

	/// @dev emit when `Stake` contract updated
	/// @param stake `Stake` contract 
	event StakeUpdated(IStake stake);

	/// @dev emit when `MajorCandidates` contract updated
	/// @param majorCandidates `MajorCandidates` contract 
	event MajorCandidatesUpdated(IMajorCandidates majorCandidates);

	/// @dev emit when vote frozen period updated
	/// @param period vote frozen period
	event VoteFrozenPeriodUpdated(uint256 period);

	/// @dev emit when shares updated for a specific candidate
	/// @param candidate candidate address
	event ShareUpdated(address candidate);

	/// @dev emit when voter voted for a candidate
	/// @param candidate candidate address
	/// @param voter voter address
	/// @param amount token amount
	event Vote(address candidate, address voter, uint256 amount);

	/// @dev emit when voter claimed the reward
	/// @param candidate candidate address
	/// @param voter voter address
	/// @param to receiver address
	/// @param amount reward amount
	event Claimed(address candidate, address voter, address to, uint256 amount);

	/// @dev emit when voter apply withdrawn the votes
	/// @param candidate candidate address
	/// @param voter voter address
	/// @param nonce withdraw nonce
	/// @param amount reward amount
	event ApplyWithdrawn(uint256 nonce, address candidate, address voter, uint256 amount);

	/// @dev emit when voter withdrawn the votes
	/// @param nonce withdraw nonce
	/// @param voter voter address
	/// @param to receiver address
	/// @param amount reward amount
	event Withdrawn( uint256 nonce, address voter, address to, uint256 amount);

	/// @dev voter vote a specific candidate
	/// @param candidate candidate address
	/// @param voter voter address
	/// @param amount reward amount
	/// @param anchor anchor candidate address
	/// @param maxSlippage maximum rank change value for the candidate from the anchor candidate
	function vote(
		address candidate,
		address voter,
		uint256 amount,
		address anchor,
		uint256 maxSlippage
	) external;

	/// @dev voter claim reward for a specific candidate
	/// @param candidate candidate address
	/// @param to receiver address
	function claim(address candidate, address to) external;

	/// @dev voter apply withdraw reward for a specific candidate
	/// @param candidate candidate address
	/// @param amount reward amount
	/// @param anchor anchor candidate address
	/// @param maxSlippage maximum rank change value for the candidate from the anchor candidate
	function applyWithdraw(
		address candidate,
		uint256 amount,
		address anchor,
		uint256 maxSlippage
	) external;

	/// @dev voter withdraw votes and reward
	/// @param nonce withdraw nonce
	/// @param to receiver address
	/// @param amount reward amount
	function withdraw(uint256 nonce, address to, uint256 amount) external;

	/// @dev candidate allocate reward for the voters
	/// @param candidate candidate address
	/// @param amount reward amount
	function onAllocate(address candidate, uint256 amount) external;

	/// @dev return ERC20 token address
	function token() external view returns(IERC20);

	/// @dev return `Rewarder` contract address
	function rewarder() external view returns(IRewarder);

	/// @dev return `Stake` contract address
	function stake() external view returns(IStake);

	/// @dev return `MajorCandidates` contract address
	function majorCandidates() external view returns(IMajorCandidates);

	/// @dev return precision for shares
	function ACC_PRECISION() external view returns(uint256);

	/// @dev return votes for a specific candidate
	/// @param candidate candidate address
	/// @return votes for a specific candidate
	function voteSupply(address candidate) external view returns(uint256);

	/// @dev pending reward for a voter given a candidate
	/// @param candidate candidate address
	/// @param voter voter address
	/// @return pending pending reward
	function pendingReward(address candidate, address voter) external view returns (uint256 pending);

}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.8.0;

import './IElection.sol';
import './IStake.sol';

/// @dev MajorCandidates interface
/// @author Alexandas
interface IMajorCandidates {

	/// @dev emit when max major candidates changed
	/// @param max max major candidates
	event MaxMajorCandidateUpdated(uint256 max);

	/// @dev emit when `Election` contract changed
	/// @param election `Election` contract address
	event ElectionUpdated(IElection election);

	/// @dev emit when `Stake` contract updated
	/// @param stake `Stake` contract 
	event StakeUpdated(IStake stake);

	/// @dev emit when a candidate insert or update in the sorted list
	/// @param candidate candidate address
	/// @param amount candidate votes
	event UpsetCandidate(address candidate, uint256 amount);

	/// @dev emit when a candidate removed from the sorted list
	/// @param candidate candidate address
	event RemoveCandidate(address candidate);

	/// @dev insert or update a candidate in the sorted list
	/// @param candidate candidate address
	/// @param amount candidate votes
	/// @param anchor anchor candidate address
	/// @param maxSlippage maximum rank change value for the candidate from the anchor candidate
	function upsetCandidateWithAnchor(
		address candidate,
		uint256 amount,
		address anchor,
		uint256 maxSlippage
	) external;

	/// @dev emit removed a candidate from the sorted list
	/// @param candidate candidate address
	function remove(address candidate) external;

	/// @dev return max major candidates
	function MAX_MAJOR_CANDIDATES() external view returns(uint256);

	/// @dev return `Election` contract address
	function election() external view returns(IElection);

	/// @dev return `Stake` contract address
	function stake() external view returns(IStake);

	/// @dev return whether a candidate is existed in the sorted list
	/// @param candidate candidate address
	/// @return whether the candidate is existed in the sorted list
	function exists(address candidate) external view returns (bool);

	/// @dev return whether a candidate is a major candidate
	/// @param candidate candidate address
	/// @return existed the candidate is a major candidate
	function isMajor(address candidate) external view returns(bool existed);

	/// @dev return all major candidates
	/// @return majors all major candidates
	function majorCandidateList() external view returns(address[] memory majors);


}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.8.0;

import '../libraries/Types.sol';
import './IMajorCandidates.sol';
import './IStake.sol';

/// @dev Slasher interface
/// @author Alexandas
interface ISlasher {

	/// @dev emit when governance address updated
	/// @param governance governance address
	event GovernanceUpdated(address governance);

	/// @dev emit when `Stake` contract updated
	/// @param stake `Stake` contract 
	event StakeUpdated(IStake stake);

	/// @dev emit when `MajorCandidates` contract updated
	/// @param majorCandidates `MajorCandidates` contract 
	event MajorCandidatesUpdated(IMajorCandidates majorCandidates);

	/// @dev emit when default slash amount updated
	/// @param amount slash amount
	event DefaultSlashAmountUpdated(uint256 amount);

	/// @dev emit when public notice period updated
	/// @param period public notice period
	event PublicNoticePeriodUpdated(uint256 period);

	/// @dev emit when max coefficient updated
	/// @param maxCoef max coefficient
	event MaxCoefUpdated(uint256 maxCoef);

	/// @dev emit when drafter slash reward coefficient updated
	/// @param drafterCoef drafter slash reward coefficient
	event DrafterCoefUpdated(uint64 drafterCoef);

	/// @dev emit when validator slash reward coefficient updated
	/// @param validatorCoef validator slash reward coefficient
	event ValidatorCoefUpdated(uint256 validatorCoef);

	/// @dev emit when executor slash reward coefficient updated
	/// @param executorCoef executor slash reward coefficient
	event ExecutorCoefUpdated(uint256 executorCoef);

	/// @dev emit when slash drafted
	/// @param nonce slash number
	/// @param candidate candidate address
	/// @param slashBlock slashed block in posc
	/// @param manifest node manifest
	/// @param accuracy posc accuracy
	event DraftSlash(uint256 nonce, address candidate, uint64 slashBlock, string manifest, uint64 accuracy);

	/// @dev emit when slash drafted
	/// @param nonce slash number
	event RejectSlash(uint256 nonce);

	/// @dev emit when slash drafted
	/// @param nonce slash number
	event ExecuteSlash(uint256 nonce, address executor);

	/// @dev return `Stake` contract address
	function stake() external view returns(IStake);

	/// @dev return `MajorCandidates` contract address
	function majorCandidates() external view returns(IMajorCandidates);

	/// @dev return default slash amount
	function defaultSlashAmount() external view returns(uint256);

	/// @dev return public notice period
	function publicNoticePeriod() external view returns(uint256);

	/// @dev return current slash nonce
	function nonce() external view returns(uint256);

	/// @dev return max coefficient
	function MAXCOEF() external view returns(uint64);

	/// @dev return drafter slash reward coefficient
	function drafterCoef() external view returns(uint64);

	/// @dev return validator slash reward coefficient
	function validatorCoef() external view returns(uint64);

	/// @dev return executor slash reward coefficient
	function executorCoef() external view returns(uint64);

	/// @dev return slash information at a specific nonce
	/// @param _nonce nonce number
	/// @return slash information
	function getSlashAt(uint256 _nonce) external view returns(Types.SlashInfo memory);

	/// @dev return nonce given a candidate if the candidate is in slashing
	/// @param candidate candidate address
	/// @return nonce number
	function nonceOf(address candidate) external view returns(uint256);

	/// @dev set drafter slash reward coefficient
	/// @param _drafterCoef drafter slash reward coefficient
	function setDrafterCoef(uint64 _drafterCoef) external;

	/// @dev set validator slash reward coefficient
	/// @param _validatorCoef validator slash reward coefficient
	function setValidatorCoef(uint64 _validatorCoef) external;

	/// @dev set executor slash reward coefficient
	/// @param _executorCoef executor slash reward coefficient
	function setExecutorCoef(uint64 _executorCoef) external;

	/// @dev draft a slash
	/// @param slashBlock slashed block in posc
	/// @param manifest node manifest
	/// @param accuracy posc accuracy
	/// @param signatures major candidates signatures
	function draft(uint64 slashBlock, string memory manifest, uint64 accuracy, bytes[] memory signatures) external;

	/// @dev reject a slash
	/// @param manifest node manifest
	function reject(string memory manifest) external;

	/// @dev execute a slash
	/// @param manifest node manifest
	function execute(string memory manifest) external;

	/// @dev return whether candidate is in slashing
	/// @param candidate candidate address
	/// @return whether candidate is in slashing
	function slashExists(address candidate) external view returns(bool);

	/// @dev check whether signatures is valid
	/// @param hash message hash
	/// @param signatures signatures for major candidates
	/// @param signers major candidate signers
	function checkNSignatures(bytes32 hash, bytes[] memory signatures) external view returns(address[] memory signers);

}