// SPDX-License-Identifier: NONE

pragma solidity 0.8.11;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./ProxyImplementation.sol";
import "./GovernableImplementation.sol";

import "./interfaces/IPenPool.sol";
import "./interfaces/IVoterProxy.sol";
import "./interfaces/IPenPoolFactory.sol";
import "./interfaces/IPenLens.sol";
import "./interfaces/IPenDyst.sol";
import "./interfaces/IMultiRewards.sol";
import "./interfaces/ICvlPen.sol";
import "./interfaces/IGauge.sol";
import "./interfaces/IPen.sol";

contract RewardsDistributor is GovernableImplementation, ProxyImplementation {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  address public voterProxy;

  address public penLockPool;

  address public penDystRewardsPoolAddress;

  address public penroseTeamAddress;

  address public treasuryAddress;

  uint256 public basis = 10000;

  uint256 public penRate = 500;

  uint256 public penDystRate = 1000;

  uint256 public treasuryRate = 1200;

  uint256 public treasuryDystRate = 300;

  // For PEN/FTM & penDYST/DYST LPs
  uint256 public ecosystemLPRate = 0;

  uint256 public penroseTeamRate = 800;

  uint256 public penroseTeamDystRate = 200;

  address[] public incentivizedPools;

  mapping(address => uint256) public incentivizedPoolWeights;

  uint256 incentivizedPoolWeightTotal;

  bool public partnersReceiveCvlPEN;

  address public penLensAddress;

  mapping(address => bool) public operator;

  event OperatorStatus(address candidate, bool status);

  modifier onlyGovernanceOrOperator() {
    require(
      operator[msg.sender] || msg.sender == governanceAddress() || msg.sender == voterProxy,
      "Only the governance or operator may perform this action"
    );
    _;
  }

  struct StakerStreams {
    uint256 penAmount;
    uint256 penDystAmount;
    uint256 treasuryAmount;
    uint256 LPAmount;
    uint256 partnerAmount;
    uint256 ecosystemLPAmount;
    uint256 penroseTeamAmount;
  }

  struct EcosystemLPWeights {
    address stakingAddress;
    uint256 weight;
  }

  address public bribesReceiverAddress;

  /**
   * @notice Initialize proxy storage
   */
  function initializeProxyStorage(address _voterProxy) public checkProxyInitialized {
    voterProxy = _voterProxy;
    basis = 10000;

    penRate = 500;

    penDystRate = 1000;

    treasuryRate = 1200;

    penroseTeamRate = 800;

    treasuryDystRate = 300;

    penroseTeamDystRate = 200;
  }

  // Don't need name change since the one in proxy takes different inputs
  function initialize(
    address _penLockPool,
    address _penDystRewardsPoolAddress,
    address _penLensAddress
  ) external onlyGovernance {
    require(penLockPool == address(0), "Already initialized");

    penLockPool = _penLockPool;
    penDystRewardsPoolAddress = _penDystRewardsPoolAddress;

    penLensAddress = _penLensAddress;
  }

  /* ========== Admin Actions ========== */

  function setOperator(address candidate, bool status) external onlyGovernance {
    operator[candidate] = status;
    emit OperatorStatus(candidate, status);
  }

  function setPenLockPool(address _penLockPool) external onlyGovernance {
    penLockPool = _penLockPool;
  }

  function setPenDystRewardsPool(address _penDystRewardsPoolAddress) external onlyGovernance {
    penDystRewardsPoolAddress = _penDystRewardsPoolAddress;
  }

  function setTreasuryRate(uint256 _treasuryRate) external onlyGovernance {
    treasuryRate = _treasuryRate;
  }

  function setTreasuryDystRate(uint256 _treasuryDystRate) external onlyGovernance {
    treasuryDystRate = _treasuryDystRate;
  }

  function setPenroseTeamRate(uint256 _penroseTeamRate) external onlyGovernance {
    penroseTeamRate = _penroseTeamRate;
  }

  function setPenroseTeamDystRate(uint256 _penroseTeamDystRate) external onlyGovernance {
    penroseTeamDystRate = _penroseTeamDystRate;
  }

  function setTreasuryAddress(address _treasuryAddress) external onlyGovernance {
    treasuryAddress = _treasuryAddress;
  }

  function setPenroseTeamAddress(address _penroseTeamAddress) external {
    if (penroseTeamAddress != address(0)) {
      require(msg.sender == penroseTeamAddress, "Only Penrose Team");
    } else {
      require(msg.sender == governanceAddress(), "Only Governance");
    }
    penroseTeamAddress = _penroseTeamAddress;
  }

  function setPartnersReceiveCvlPEN(bool _partnersReceiveCvlPEN) external onlyGovernance {
    partnersReceiveCvlPEN = _partnersReceiveCvlPEN;
  }

  function setEcosystemLPRewards(
    uint256 _ecosystemLPRate,
    address[] calldata _incentivizedPools,
    uint256[] calldata _incentivizedPoolWeights
  ) external onlyGovernance {
    require(
      _incentivizedPools.length == _incentivizedPoolWeights.length,
      "Different amounts of pools and weights"
    );
    ecosystemLPRate = _ecosystemLPRate;
    incentivizedPools = _incentivizedPools;
    uint256 _incentivizedPoolWeightTotal;
    for (uint256 i; i < _incentivizedPools.length; i++) {
      incentivizedPoolWeights[_incentivizedPools[i]] = _incentivizedPoolWeights[i];
      _incentivizedPoolWeightTotal += _incentivizedPoolWeights[i];
    }
    incentivizedPoolWeightTotal = _incentivizedPoolWeightTotal;
  }

  /* ========== Staking Pool Actions ========== */

  function setRewardPoolOwner(address stakingAddress, address _owner) external onlyGovernance {
    IMultiRewards(stakingAddress).nominateNewOwner(_owner);
  }

  function setBribeReceiverAddress(address _bribesReceiverAddress) external onlyGovernance {
    bribesReceiverAddress = _bribesReceiverAddress;
  }

  function addReward(
    address stakingAddress,
    address _rewardsToken,
    uint256 _rewardsDuration
  ) external onlyGovernanceOrOperator {
    IMultiRewards(stakingAddress).addReward(_rewardsToken, address(this), _rewardsDuration);
  }

  function notifyRewardAmount(
    address stakingAddress,
    address rewardTokenAddress,
    uint256 amount
  ) external onlyGovernanceOrOperator {
    if (amount == 0) {
      return;
    }
    address dystAddress = IPenLens(penLensAddress).dystAddress(); //gas savings on ssload

    StakerStreams memory rewardStreams; //to avoid stack too deep

    // All bribes and fees go to penDYST stakers and partners who stake penDYST if it's whitelisted in tokensAllowlist
    // stored in rewardsDistributor if not whitelist (just so we don't transfer weird tokens down the line)
    // this also handles DYST rebases that's passed here as penDYST
    if (rewardTokenAddress != dystAddress) {
      if (IPenLens(penLensAddress).tokensAllowlist().tokenIsAllowedInPools(rewardTokenAddress)) {
        if (bribesReceiverAddress == address(0)) {
          (rewardStreams.penDystAmount, rewardStreams.partnerAmount) = calculatePartnerSlice(
            amount
          );
          _notifyRewardAmount(
            penDystRewardsPoolAddress,
            rewardTokenAddress,
            rewardStreams.penDystAmount
          );

          _notifyRewardAmount(
            partnersRewardsPoolAddress(),
            rewardTokenAddress,
            rewardStreams.partnerAmount
          );
        } else {
          IERC20(rewardTokenAddress).approve(bribesReceiverAddress, amount);
          IERC20(rewardTokenAddress).transfer(bribesReceiverAddress, amount);
        }
      }

      return;
    }

    // If it's DYST, distribute DYST at 10% to penDYST stakers (and partners), 5% to PEN stakers, 3% to treasury and 2% to penrose team
    // x% to PEN/FTM & penDYST/DYST LPs, and rest to LP (84%)
    address penDystAddress = IPenLens(penLensAddress).penDystAddress();
    address penAddress = IPenLens(penLensAddress).penAddress();
    IPenDyst penDyst = IPenDyst(penDystAddress);

    rewardStreams.penAmount = amount.mul(penRate).div(basis); //5%
    rewardStreams.penDystAmount = amount.mul(penDystRate).div(basis); //10%
    rewardStreams.treasuryAmount = amount.mul(treasuryDystRate).div(basis); //3%
    rewardStreams.penroseTeamAmount = amount.mul(penroseTeamDystRate).div(basis); //2%
    rewardStreams.ecosystemLPAmount = amount.mul(ecosystemLPRate).div(basis); //x%

    rewardStreams.LPAmount = amount
      .sub(rewardStreams.penAmount)
      .sub(rewardStreams.penDystAmount)
      .sub(rewardStreams.treasuryAmount)
      .sub(rewardStreams.penroseTeamAmount)
      .sub(rewardStreams.ecosystemLPAmount);

    // Distribute DYST claimed
    _notifyRewardAmount(stakingAddress, dystAddress, rewardStreams.LPAmount);

    // Ecosystem LP and penDYST stakers and Partners get DYST emission in penDYST
    uint256 amountToLock = rewardStreams.ecosystemLPAmount.add(rewardStreams.penAmount);
    IERC20(dystAddress).approve(voterProxy, amountToLock);
    IVoterProxy(voterProxy).lockDyst(amountToLock);

    //distribute penDYST to vlPEN
    _notifyRewardAmount(penLockPool, penDystAddress, rewardStreams.penAmount);

    // Distribute ecosystem LP amount in penDYST according to set weights
    if (rewardStreams.ecosystemLPAmount > 0) {
      uint256 incentivizedPoolAmount;
      for (uint256 i; i < incentivizedPools.length; i++) {
        incentivizedPoolAmount = rewardStreams
          .ecosystemLPAmount
          .mul(basis)
          .mul(incentivizedPoolWeights[incentivizedPools[i]])
          .div(incentivizedPoolWeightTotal)
          .div(basis);
        _notifyRewardAmount(incentivizedPools[i], penDystAddress, incentivizedPoolAmount);
      }
    }

    IERC20(dystAddress).safeTransfer(treasuryAddress, rewardStreams.treasuryAmount);

    IERC20(dystAddress).safeTransfer(penroseTeamAddress, rewardStreams.penroseTeamAmount);

    // For penDYST stakers, distribute DYST emission as DYST
    (rewardStreams.penDystAmount, rewardStreams.partnerAmount) = calculatePartnerSlice(
      rewardStreams.penDystAmount
    );
    _notifyRewardAmount(penDystRewardsPoolAddress, dystAddress, rewardStreams.penDystAmount);
    _notifyRewardAmount(partnersRewardsPoolAddress(), dystAddress, rewardStreams.partnerAmount);

    // Mint PEN and distribute according to tokenomics
    // penDYST lockers get PEN = minted * (PENyst.totalSupply()/DYST.totalSupply())
    // this ensures penDYST lockers are not diluted against other DYST stakers
    // and prevents the %PEN emission penDYST stakers get isn't diluted below penDYST/DYST.totalSupply()
    // partners get theirs with at a floor ratio of 2*penDYST/DYST, until 25%, which reverts back to normal
    // penDYST lockers altogether are guaranteed a 5% floor in emissions
    // partners get their PEN in locked form, this is acheived with vlPEN coupons (cvlPEN) since vlPEN itself isn't transferrable
    IPen(penAddress).mint(address(this), amount);

    rewardStreams.penroseTeamAmount = amount.mul(penroseTeamRate).div(basis);
    IERC20(penAddress).safeTransfer(penroseTeamAddress, rewardStreams.penroseTeamAmount);

    rewardStreams.treasuryAmount = amount.mul(treasuryRate).div(basis);
    IERC20(penAddress).safeTransfer(treasuryAddress, rewardStreams.treasuryAmount);

    amount = amount.sub(rewardStreams.penroseTeamAmount);
    amount = amount.sub(rewardStreams.treasuryAmount);
    {
      uint256 penDystRatioOfDYST = penDyst.totalSupply().mul(1e18).div(
        IERC20(dystAddress).totalSupply()
      ); // basis is not precise enough here, using 1e18

      (uint256 nonpartnerRatioOfDYST, uint256 partnersRatioOfDYST) = calculatePartnerSlice(
        penDystRatioOfDYST
      );
      partnersRatioOfDYST = partnersRatioOfDYST.mul(2); //partners get minted*(partner penDYST/DYST)*2 as a floor until 25%
      if (partnersRatioOfDYST.mul(basis).div(1e18) > 2500) {
        partnersRatioOfDYST = (partnersRatioOfDYST.div(2).sub((uint256(1250).mul(1e18)).div(basis)))
          .mul(7500)
          .div(8750)
          .add(uint256(2500).mul(1e18).div(basis)); // if above 25%, partnersRatioOfDYST = ((partner penDYST/DYST supply) - 0.125) * 0.75/0.875 + 0.25
      } else if (
        // penDYST stakers always get at least 5% of PEN emissions
        (nonpartnerRatioOfDYST.add(partnersRatioOfDYST)).mul(basis).div(1e18) < 500
      ) {
        nonpartnerRatioOfDYST = uint256(500).mul(1e18).div(basis).div(3); // Partners always have 2x weight against nonpartners if they're only getting 5% (5% < 25%)
        partnersRatioOfDYST = nonpartnerRatioOfDYST.mul(2);
      }

      rewardStreams.penDystAmount = amount.mul(nonpartnerRatioOfDYST).div(1e18);
      rewardStreams.partnerAmount = amount.mul(partnersRatioOfDYST).div(1e18);
    }

    _notifyRewardAmount(penDystRewardsPoolAddress, penAddress, rewardStreams.penDystAmount);

    if (partnersReceiveCvlPEN) {
      // Mint cvlPEN and distribute to partnersRewardsPool
      address _cvlPenAddress = cvlPenAddress();
      IERC20(penAddress).approve(_cvlPenAddress, rewardStreams.partnerAmount);
      ICvlPen(_cvlPenAddress).mint(address(this), rewardStreams.partnerAmount);
      _notifyRewardAmount(
        partnersRewardsPoolAddress(),
        _cvlPenAddress,
        rewardStreams.partnerAmount
      );
    } else {
      _notifyRewardAmount(partnersRewardsPoolAddress(), penAddress, rewardStreams.partnerAmount);
    }

    rewardStreams.LPAmount = amount.sub(rewardStreams.penDystAmount).sub(
      rewardStreams.partnerAmount
    );
    _notifyRewardAmount(stakingAddress, penAddress, rewardStreams.LPAmount);
  }

  /**
   * @notice To distribute stored bribed tokens that's newly whitelisted to penDYST stakers and Partners
   * @param  rewardTokenAddress reward token address
   * @dev no auth needed since it only transfers whitelisted addresses
   */
  function notifyStoredRewardAmount(address rewardTokenAddress) external {
    require(
      IPenLens(penLensAddress).tokensAllowlist().tokenIsAllowedInPools(rewardTokenAddress),
      "Token is not allowed in reward pools"
    );
    // Get amount of rewards stored in this address
    uint256 amount = IERC20(rewardTokenAddress).balanceOf(address(this));

    StakerStreams memory rewardStreams;

    (rewardStreams.penDystAmount, rewardStreams.partnerAmount) = calculatePartnerSlice(amount);

    _notifyRewardAmount(penDystRewardsPoolAddress, rewardTokenAddress, rewardStreams.penDystAmount);

    _notifyRewardAmount(
      partnersRewardsPoolAddress(),
      rewardTokenAddress,
      rewardStreams.partnerAmount
    );
  }

  function _notifyRewardAmount(
    address stakingAddress,
    address rewardToken,
    uint256 amount
  ) internal {
    if (amount == 0) {
      return;
    }
    address rewardsDistributorAddress = IMultiRewards(stakingAddress)
      .rewardData(rewardToken)
      .rewardsDistributor;
    bool rewardExists = rewardsDistributorAddress != address(0);
    if (!rewardExists) {
      IMultiRewards(stakingAddress).addReward(
        rewardToken,
        address(this),
        604800 // 1 week
      );
    }

    IERC20(rewardToken).approve(stakingAddress, amount);
    IMultiRewards(stakingAddress).notifyRewardAmount(rewardToken, amount);
  }

  function setRewardsDuration(
    address stakingAddress,
    address _rewardsToken,
    uint256 _rewardsDuration
  ) external onlyGovernanceOrOperator {
    IMultiRewards(stakingAddress).setRewardsDuration(_rewardsToken, _rewardsDuration);
  }

  function harvestAndDistributeLPRewards(address[] calldata penPools)
    external
    onlyGovernanceOrOperator
  {
    address gauge;
    address staking;

    for (uint256 i; i < penPools.length; i++) {
      gauge = IPenPool(penPools[i]).gaugeAddress();
      staking = IPenPool(penPools[i]).stakingAddress();
      uint256 rewardsLength = IGauge(gauge).rewardTokensLength();
      address[] memory rewards = new address[](rewardsLength);

      for (uint256 j; j < rewardsLength; j++) {
        rewards[j] = IGauge(gauge).rewardTokens(j);
      }

      IVoterProxy(voterProxy).getRewardFromGauge(penPools[i], rewards);
    }
  }

  /* ========== Token Recovery ========== */

  function recoverERC20FromStaking(address stakingAddress, address tokenAddress)
    external
    onlyGovernanceOrOperator
  {
    uint256 amount = IERC20(tokenAddress).balanceOf(stakingAddress);
    IMultiRewards(stakingAddress).recoverERC20(tokenAddress, amount);
    recoverERC20(tokenAddress);
  }

  function recoverERC20(address tokenAddress) public onlyGovernanceOrOperator {
    uint256 amount = IERC20(tokenAddress).balanceOf(address(this));
    IERC20(tokenAddress).safeTransfer(msg.sender, amount);
  }

  /* ========== Helper View Functions ========== */

  function penLens() internal view returns (IPenLens) {
    return IPenLens(penLensAddress);
  }

  function partnersRewardsPoolAddress() internal view returns (address) {
    return penLens().partnersRewardsPoolAddress();
  }

  function cvlPenAddress() internal view returns (address) {
    return penLens().cvlPenAddress();
  }

  function calculatePartnerSlice(uint256 amount)
    internal
    view
    returns (uint256 penDystAmount, uint256 partnerAmount)
  {
    uint256 stakedSpenDyst = IMultiRewards(penDystRewardsPoolAddress).totalSupply();
    uint256 stakedPpenDyst = IMultiRewards(partnersRewardsPoolAddress()).totalSupply();

    uint256 totalStakedPenDyst = stakedSpenDyst.add(stakedPpenDyst);
    totalStakedPenDyst = (totalStakedPenDyst != 0 ? totalStakedPenDyst : 1); //no divide by 0

    penDystAmount = amount.mul(basis).mul(stakedSpenDyst).div(totalStakedPenDyst).div(basis);

    partnerAmount = amount - penDystAmount;
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
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
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
pragma solidity 0.8.11||0.6.12;

/**
 * @title Implementation meant to be used with a proxy
 * @author Penrose
 */
contract ProxyImplementation {
    bool public proxyStorageInitialized;

    /**
     * @notice Nothing in constructor, since it only affects the logic address, not the storage address
     * @dev public visibility so it compiles for 0.6.12
     */
    constructor() public {}

    /**
     * @notice Only allow proxy's storage to be initialized once
     */
    modifier checkProxyInitialized() {
        require(
            !proxyStorageInitialized,
            "Can only initialize proxy storage once"
        );
        proxyStorageInitialized = true;
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11||0.6.12;

/**
 * @title Ownable contract which allows governance to be killed, adapted to be used under a proxy
 * @author Penrose
 */
contract GovernableImplementation {
    address internal doNotUseThisSlot; // used to be governanceAddress, but there's a hash collision with the proxy's governanceAddress
    bool public governanceIsKilled;

    /**
     * @notice legacy
     * @dev public visibility so it compiles for 0.6.12
     */
    constructor() public {
        doNotUseThisSlot = msg.sender;
    }

    /**
     * @notice Only allow governance to perform certain actions
     */
    modifier onlyGovernance() {
        require(msg.sender == governanceAddress(), "Only governance");
        _;
    }

    /**
     * @notice Set governance address
     * @param _governanceAddress The address of new governance
     */
    function setGovernanceAddress(address _governanceAddress)
        public
        onlyGovernance
    {
        require(msg.sender == governanceAddress(), "Only governance");
        assembly {
            sstore(
                0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103,
                _governanceAddress
            ) // keccak256('eip1967.proxy.admin')
        }
    }

    /**
     * @notice Allow governance to be killed
     */
    function killGovernance() external onlyGovernance {
        setGovernanceAddress(address(0));
        governanceIsKilled = true;
    }

    /**
     * @notice Fetch current governance address
     * @return _governanceAddress Returns current governance address
     * @dev directing to the slot that the proxy would use
     */
    function governanceAddress()
        public
        view
        returns (address _governanceAddress)
    {
        assembly {
            _governanceAddress := sload(
                0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103
            ) // keccak256('eip1967.proxy.admin')
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;
import "./IDystopiaLens.sol";

interface IPenPool {
    function stakingAddress() external view returns (address);

    function dystPoolAddress() external view returns (address);

    function dystPoolInfo() external view returns (IDystopiaLens.Pool memory);

    function depositLpAndStake(uint256) external;

    function depositLp(uint256) external;

    function withdrawLp(uint256) external;

    function syncBribeTokens() external;

    function notifyBribeOrFees() external;

    function initialize(
        address,
        address,
        address,
        string memory,
        string memory,
        address,
        address
    ) external;

    function gaugeAddress() external view returns (address);

    function balanceOf(address) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function totalSupply() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface IVoterProxy {
    function depositInGauge(address, uint256) external;

    function withdrawFromGauge(address, uint256) external;

    function getRewardFromGauge(address _penPool, address[] memory _tokens)
        external;

    function depositNft(uint256) external;

    function veAddress() external returns (address);

    function veDistAddress() external returns (address);

    function lockDyst(uint256 amount) external;

    function primaryTokenId() external view returns (uint256);

    function vote(address[] memory, int256[] memory) external;

    function votingSnapshotAddress() external view returns (address);

    function dystInflationSinceInception() external view returns (uint256);

    function getRewardFromBribe(
        address penPoolAddress,
        address[] memory _tokensAddresses
    ) external returns (bool allClaimed, bool[] memory claimed);

    function getFeeTokensFromBribe(address penPoolAddress)
        external
        returns (bool allClaimed);

    function claimDyst(address penPoolAddress)
        external
        returns (bool _claimDyst);

    function setVoterProxyAssetsAddress(address _voterProxyAssetsAddress)
        external;

    function detachNFT(uint256 startingIndex, uint256 range) external;

    function claim() external;

    function whitelist(address tokenAddress) external;

    function whitelistingFee() external view returns (uint256);

    function reset() external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface IPenPoolFactory {
    function penPoolsLength() external view returns (uint256);

    function isPenPool(address) external view returns (bool);

    function isPenPoolOrLegacyPenPool(address) external view returns (bool);

    function PEN() external view returns (address);

    function syncPools(uint256) external;

    function penPools(uint256) external view returns (address);

    function penPoolByDystPool(address) external view returns (address);

    function vlPenAddress() external view returns (address);

    function dystPoolByPenPool(address) external view returns (address);

    function syncedPoolsLength() external returns (uint256);

    function dystopiaLensAddress() external view returns (address);

    function voterProxyAddress() external view returns (address);

    function rewardsDistributorAddress() external view returns (address);

    function tokensAllowlist() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;
import "./IPen.sol";
import "./IVlPen.sol";
import "./IPenPoolFactory.sol";
import "./IPenDyst.sol";
import "./IDyst.sol";
import "./IDystopiaLens.sol";
import "./IUserProxy.sol";
import "./IVe.sol";
import "./IVotingSnapshot.sol";
import "./IVoterProxy.sol";
import "./IPenV1Rewards.sol";
import "./ITokensAllowlist.sol";

interface IPenLens {
    struct ProtocolAddresses {
        address penPoolFactoryAddress;
        address DystopiaLensAddress;
        address PenAddress;
        address vlPenAddress;
        address penDystAddress;
        address voterProxyAddress;
        address dystAddress;
        address voterAddress;
        address poolsFactoryAddress;
        address gaugesFactoryAddress;
        address minterAddress;
        address veAddress;
        address userProxyInterfaceAddress;
        address votingSnapshotAddress;
    }

    struct UserPosition {
        address userProxyAddress;
        uint256 veTotalBalanceOf;
        IDystopiaLens.PositionVe[] vePositions;
        IDystopiaLens.PositionPool[] poolsPositions;
        IUserProxy.PositionStakingPool[] stakingPools;
        uint256 penDystBalanceOf;
        uint256 penBalanceOf;
        uint256 dystBalanceOf;
        uint256 vlPenBalanceOf;
    }

    struct TokenMetadata {
        address id;
        string name;
        string symbol;
        uint8 decimals;
        uint256 priceUsdc;
    }

    struct PenPoolData {
        address id;
        address stakingAddress;
        uint256 stakedTotalSupply;
        uint256 totalSupply;
        IDystopiaLens.Pool poolData;
    }

    struct Pool {
        address id;
        string symbol;
        bool stable;
        address token0Address;
        address token1Address;
        address gaugeAddress;
        address bribeAddress;
        address[] bribeTokensAddresses;
        address fees;
    }

    struct RewardTokenData {
        address id;
        uint256 rewardRate;
        uint256 periodFinish;
    }

    /* ========== PUBLIC VARS ========== */

    function penPoolFactoryAddress() external view returns (address);

    function rewardsDistributorAddress() external view returns (address);

    function userProxyFactoryAddress() external view returns (address);

    function dystopiaLensAddress() external view returns (address);

    function penAddress() external view returns (address);

    function vlPenAddress() external view returns (address);

    function penDystAddress() external view returns (address);

    function voterProxyAddress() external view returns (address);

    function veAddress() external view returns (address);

    function dystAddress() external view returns (address);

    function penDystRewardsPoolAddress() external view returns (address);

    function partnersRewardsPoolAddress() external view returns (address);

    function treasuryAddress() external view returns (address);

    function cvlPenAddress() external view returns (address);

    function penV1RewardsAddress() external view returns (address);

    function penV1RedeemAddress() external view returns (address);

    function penV1Address() external view returns (address);

    function tokensAllowlistAddress() external view returns (address);

    /* ========== PUBLIC VIEW FUNCTIONS ========== */

    function voterAddress() external view returns (address);

    function poolsFactoryAddress() external view returns (address);

    function gaugesFactoryAddress() external view returns (address);

    function minterAddress() external view returns (address);

    function protocolAddresses()
        external
        view
        returns (ProtocolAddresses memory);

    function positionsOf(address accountAddress)
        external
        view
        returns (UserPosition memory);

    function rewardTokensPositionsOf(address, address)
        external
        view
        returns (IUserProxy.RewardToken[] memory);

    function veTotalBalanceOf(IDystopiaLens.PositionVe[] memory positions)
        external
        pure
        returns (uint256);

    function penPoolsLength() external view returns (uint256);

    function userProxiesLength() external view returns (uint256);

    function userProxyByAccount(address accountAddress)
        external
        view
        returns (address);

    function userProxyByIndex(uint256 index) external view returns (address);

    function gaugeByDystPool(address) external view returns (address);

    function dystPoolByPenPool(address penPoolAddress)
        external
        view
        returns (address);

    function penPoolByDystPool(address dystPoolAddress)
        external
        view
        returns (address);

    function stakingRewardsByDystPool(address dystPoolAddress)
        external
        view
        returns (address);

    function stakingRewardsByPenPool(address dystPoolAddress)
        external
        view
        returns (address);

    function isPenPool(address penPoolAddress) external view returns (bool);

    function penPoolsAddresses() external view returns (address[] memory);

    function penPoolData(address penPoolAddress)
        external
        view
        returns (PenPoolData memory);

    function penPoolsData(address[] memory _penPoolsAddresses)
        external
        view
        returns (PenPoolData[] memory);

    function penPoolsData() external view returns (PenPoolData[] memory);

    function penDyst() external view returns (IPenDyst);

    function pen() external view returns (IPen);

    function vlPen() external view returns (IVlPen);

    function penPoolFactory() external view returns (IPenPoolFactory);

    function dyst() external view returns (IDyst);

    function ve() external view returns (IVe);

    function voterProxy() external view returns (IVoterProxy);

    function votingSnapshot() external view returns (IVotingSnapshot);

    function tokensAllowlist() external view returns (ITokensAllowlist);

    function isPartner(address userProxyAddress) external view returns (bool);

    function stakedPenDystBalanceOf(address accountAddress)
        external
        view
        returns (uint256 stakedBalance);

    function dystInflationSinceInception() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IPenDyst is IERC20 {
    function mint(address, uint256) external;

    function convertNftToPenDyst(uint256) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface IMultiRewards {
    struct Reward {
        address rewardsDistributor;
        uint256 rewardsDuration;
        uint256 periodFinish;
        uint256 rewardRate;
        uint256 lastUpdateTime;
        uint256 rewardPerTokenStored;
    }

    function stake(uint256) external;

    function withdraw(uint256) external;

    function getReward() external;

    function stakingToken() external view returns (address);

    function balanceOf(address) external view returns (uint256);

    function earned(address, address) external view returns (uint256);

    function initialize(address, address) external;

    function rewardRate(address) external view returns (uint256);

    function getRewardForDuration(address) external view returns (uint256);

    function rewardPerToken(address) external view returns (uint256);

    function rewardData(address) external view returns (Reward memory);

    function rewardTokensLength() external view returns (uint256);

    function rewardTokens(uint256) external view returns (address);

    function totalSupply() external view returns (uint256);

    function addReward(
        address _rewardsToken,
        address _rewardsDistributor,
        uint256 _rewardsDuration
    ) external;

    function notifyRewardAmount(address, uint256) external;

    function recoverERC20(address tokenAddress, uint256 tokenAmount) external;

    function setRewardsDuration(address _rewardsToken, uint256 _rewardsDuration)
        external;

    function exit() external;

    function nominateNewOwner(address _owner) external;

    function acceptOwnership() external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./IPenLens.sol";

interface ICvlPen is IERC20 {
    function minterAddress() external view returns (address);

    function penLens() external view returns (IPenLens);

    function whitelist(address) external view returns (bool);

    function setMinter(address _minterAddress) external;

    function mint(address to, uint256 amount) external;

    function redeem() external;

    function redeem(uint256 amount) external;

    function redeem(address to, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface IGauge {
    function rewardTokens(uint256) external returns (address);

    function rewardTokensLength() external view returns (uint256);

    function earned(address, address) external view returns (uint256);

    function getReward(address account, address[] memory tokens) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IPen is IERC20 {
    function mint(address to, uint256 amount) external;
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
pragma solidity 0.8.11;

interface IDystopiaLens {
    struct Pool {
        address id;
        string symbol;
        bool stable;
        address token0Address;
        address token1Address;
        address gaugeAddress;
        address bribeAddress;
        address[] bribeTokensAddresses;
        address fees;
        uint256 totalSupply;
    }

    struct PoolReserveData {
        address id;
        address token0Address;
        address token1Address;
        uint256 token0Reserve;
        uint256 token1Reserve;
        uint8 token0Decimals;
        uint8 token1Decimals;
    }

    struct PositionVe {
        uint256 tokenId;
        uint256 balanceOf;
        uint256 locked;
    }

    struct PositionBribesByTokenId {
        uint256 tokenId;
        PositionBribe[] bribes;
    }

    struct PositionBribe {
        address bribeTokenAddress;
        uint256 earned;
    }

    struct PositionPool {
        address id;
        uint256 balanceOf;
    }

    function poolsLength() external view returns (uint256);

    function voterAddress() external view returns (address);

    function veAddress() external view returns (address);

    function poolsFactoryAddress() external view returns (address);

    function gaugesFactoryAddress() external view returns (address);

    function minterAddress() external view returns (address);

    function dystAddress() external view returns (address);

    function vePositionsOf(address) external view returns (PositionVe[] memory);

    function bribeAddresByPoolAddress(address) external view returns (address);

    function gaugeAddressByPoolAddress(address) external view returns (address);

    function poolsPositionsOf(address)
        external
        view
        returns (PositionPool[] memory);

    function poolsPositionsOf(
        address,
        uint256,
        uint256
    ) external view returns (PositionPool[] memory);

    function poolInfo(address) external view returns (Pool memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface IVlPen {
    struct LocksData {
        uint256 total;
        uint256 unlockable;
        uint256 locked;
        LockedBalance[] locks;
    }

    struct LockedBalance {
        uint112 amount;
        uint112 boosted;
        uint32 unlockTime;
    }

    struct EarnedData {
        address token;
        uint256 amount;
    }

    struct Reward {
        bool useBoost;
        uint40 periodFinish;
        uint208 rewardRate;
        uint40 lastUpdateTime;
        uint208 rewardPerTokenStored;
        address rewardsDistributor;
    }

    function lock(
        address _account,
        uint256 _amount,
        uint256 _spendRatio
    ) external;

    function processExpiredLocks(
        bool _relock,
        uint256 _spendRatio,
        address _withdrawTo
    ) external;

    function lockedBalanceOf(address) external view returns (uint256 amount);

    function lockedBalances(address)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            LockedBalance[] memory
        );

    function claimableRewards(address _account)
        external
        view
        returns (EarnedData[] memory userRewards);

    function rewardTokensLength() external view returns (uint256);

    function rewardTokens(uint256) external view returns (address);

    function rewardData(address) external view returns (Reward memory);

    function rewardPerToken(address) external view returns (uint256);

    function getRewardForDuration(address) external view returns (uint256);

    function getReward() external;

    function checkpointEpoch() external;

    function updateRewards() external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface IDyst {
    function transferFrom(
        address,
        address,
        uint256
    ) external;

    function allowance(address, address) external view returns (uint256);

    function approve(address, uint256) external;

    function balanceOf(address) external view returns (uint256);

    function router() external view returns (address);

    function minter() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface IUserProxy {
    struct PositionStakingPool {
        address stakingPoolAddress;
        address penPoolAddress;
        address dystPoolAddress;
        uint256 balanceOf;
        RewardToken[] rewardTokens;
    }

    function initialize(
        address,
        address,
        address,
        address[] memory
    ) external;

    struct RewardToken {
        address rewardTokenAddress;
        uint256 rewardRate;
        uint256 rewardPerToken;
        uint256 getRewardForDuration;
        uint256 earned;
    }

    struct Vote {
        address poolAddress;
        int256 weight;
    }

    function convertNftToPenDyst(uint256) external;

    function convertDystToPenDyst(uint256) external;

    function depositLpAndStake(address, uint256) external;

    function depositLp(address, uint256) external;

    function stakingAddresses() external view returns (address[] memory);

    function initialize(address, address) external;

    function stakingPoolsLength() external view returns (uint256);

    function unstakeLpAndWithdraw(
        address,
        uint256,
        bool
    ) external;

    function unstakeLpAndWithdraw(address, uint256) external;

    function unstakeLpWithdrawAndClaim(address) external;

    function unstakeLpWithdrawAndClaim(address, uint256) external;

    function withdrawLp(address, uint256) external;

    function stakePenLp(address, uint256) external;

    function unstakePenLp(address, uint256) external;

    function ownerAddress() external view returns (address);

    function stakingPoolsPositions()
        external
        view
        returns (PositionStakingPool[] memory);

    function stakePenDyst(uint256) external;

    function unstakePenDyst(uint256) external;

    function unstakePenDyst(address, uint256) external;

    function convertDystToPenDystAndStake(uint256) external;

    function convertNftToPenDystAndStake(uint256) external;

    function claimPenDystStakingRewards() external;

    function claimPartnerStakingRewards() external;

    function claimStakingRewards(address) external;

    function claimStakingRewards(address[] memory) external;

    function claimStakingRewards() external;

    function claimVlPenRewards() external;

    function depositPen(uint256, uint256) external;

    function withdrawPen(bool, uint256) external;

    function voteLockPen(uint256, uint256) external;

    function withdrawVoteLockedPen(uint256, bool) external;

    function relockVoteLockedPen(uint256) external;

    function removeVote(address) external;

    function registerStake(address) external;

    function registerUnstake(address) external;

    function resetVotes() external;

    function setVoteDelegate(address) external;

    function clearVoteDelegate() external;

    function vote(address, int256) external;

    function vote(Vote[] memory) external;

    function votesByAccount(address) external view returns (Vote[] memory);

    function migratePenDystToPartner() external;

    function stakePenDystInPenV1(uint256) external;

    function unstakePenDystInPenV1(uint256) external;

    function redeemPenV1(uint256) external;

    function redeemAndStakePenV1(uint256) external;

    function whitelist(address) external;

    function implementationsAddresses()
        external
        view
        returns (address[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface IVe {
    function safeTransferFrom(
        address,
        address,
        uint256
    ) external;

    function ownerOf(uint256) external view returns (address);

    function balanceOf(address) external view returns (uint256);

    function balanceOfNFT(uint256) external view returns (uint256);

    function balanceOfNFTAt(uint256, uint256) external view returns (uint256);

    function balanceOfAtNFT(uint256, uint256) external view returns (uint256);

    function locked(uint256) external view returns (uint256);

    function createLock(uint256, uint256) external returns (uint256);

    function approve(address, uint256) external;

    function merge(uint256, uint256) external;

    function token() external view returns (address);

    function controller() external view returns (address);

    function voted(uint256) external view returns (bool);

    function tokenOfOwnerByIndex(address, uint256)
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11||0.6.12;
pragma experimental ABIEncoderV2;

interface IVotingSnapshot {
    struct Vote {
        address poolAddress;
        int256 weight;
    }

    function vote(address, int256) external;

    function vote(Vote[] memory) external;

    function removeVote(address) external;

    function resetVotes() external;

    function resetVotes(address) external;

    function setVoteDelegate(address) external;

    function clearVoteDelegate() external;

    function voteDelegateByAccount(address) external view returns (address);

    function votesByAccount(address) external view returns (Vote[] memory);

    function voteWeightTotalByAccount(address) external view returns (uint256);

    function voteWeightUsedByAccount(address) external view returns (uint256);

    function voteWeightAvailableByAccount(address)
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./IMultiRewards.sol";

interface IPenV1Rewards is IMultiRewards {
    function stakingCap(address account) external view returns (uint256 cap);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface ITokensAllowlist {
    function tokenIsAllowed(address) external view returns (bool);

    function bribeTokensSyncPageSize() external view returns (uint256);

    function bribeTokensNotifyPageSize() external view returns (uint256);

    function bribeSyncLagLimit() external view returns (uint256);

    function notifyFrequency()
        external
        view
        returns (uint256 bribeFrequency, uint256 feeFrequency);

    function feeClaimingDisabled(address) external view returns (bool);

    function periodBetweenClaimDyst() external view returns (uint256);

    function periodBetweenClaimFee() external view returns (uint256);

    function periodBetweenClaimBribe() external view returns (uint256);

    function tokenIsAllowedInPools(address) external view returns (bool);

    function setTokenIsAllowedInPools(
        address[] memory tokensAddresses,
        bool allowed
    ) external;

    function oogLoopLimit() external view returns (uint256);

    function notifyDystThreshold() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

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