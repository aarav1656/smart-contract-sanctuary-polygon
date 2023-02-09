// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import { IERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import { SafeERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import { EnumerableSetUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { ReentrancyGuardUpgradeable } from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import { PausableUpgradeable } from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

import { ILP } from "./interfaces/ILP.sol";
import { ISwapPool } from "../ceros/interfaces/ISwapPool.sol";
import { IMaticPool } from "./interfaces/IMaticPool.sol";
import { ICerosToken } from "./interfaces/ICerosToken.sol";
import { INativeERC20 } from "./interfaces/INativeERC20.sol";

enum UserType {
  MANAGER,
  LIQUIDITY_PROVIDER,
  INTEGRATOR
}

enum FeeType {
  OWNER,
  MANAGER,
  INTEGRATOR,
  STAKE,
  UNSTAKE
}

struct FeeAmounts {
  uint128 nativeFee;
  uint128 cerosFee;
}

// solhint-disable max-states-count
contract SwapPool is
  ISwapPool,
  OwnableUpgradeable,
  PausableUpgradeable,
  ReentrancyGuardUpgradeable
{
  using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
  using SafeERC20Upgradeable for IERC20Upgradeable;

  event UserTypeChanged(address indexed user, UserType indexed utype, bool indexed added);
  event FeeChanged(FeeType indexed utype, uint24 oldFee, uint24 newFee);
  event IntegratorLockEnabled(bool indexed enabled);
  event ProviderLockEnabled(bool indexed enabled);
  event ExcludedFromFee(address indexed user, bool indexed excluded);
  event LiquidityChange(
    address indexed user,
    uint256 nativeAmount,
    uint256 stakingAmount,
    uint256 nativeReserve,
    uint256 stakingReserve,
    bool indexed added
  );
  event Swap(
    address indexed sender,
    address indexed receiver,
    bool indexed nativeToCeros,
    uint256 amountIn,
    uint256 amountOut
  );
  event ThresholdChanged(uint256 newThreshold);
  event MaticPoolChanged(address newMaticPool);

  uint24 public constant FEE_MAX = 100000;

  EnumerableSetUpgradeable.AddressSet internal managers_;
  EnumerableSetUpgradeable.AddressSet internal integrators_;
  EnumerableSetUpgradeable.AddressSet internal liquidityProviders_;

  address public nativeToken;
  address public cerosToken;
  address public lpToken;

  uint256 public nativeTokenAmount;
  uint256 public cerosTokenAmount;

  uint24 public ownerFee;
  uint24 public managerFee;
  uint24 public integratorFee;
  uint24 public stakeFee;
  uint24 public unstakeFee;
  uint24 public threshold;

  bool public integratorLockEnabled;
  bool public providerLockEnabled;

  FeeAmounts public ownerFeeCollected;

  FeeAmounts public managerFeeCollected;
  FeeAmounts internal _accFeePerManager;
  FeeAmounts internal _alreadyUpdatedFees;
  FeeAmounts internal _claimedManagerFees;

  mapping(address => FeeAmounts) public managerRewardDebt;
  mapping(address => bool) public excludedFromFee;

  IMaticPool public maticPool;

  modifier onlyOwnerOrManager() {
    require(
      msg.sender == owner() || managers_.contains(msg.sender),
      "only owner or manager can call this function"
    );
    _;
  }

  modifier onlyManager() {
    require(managers_.contains(msg.sender), "only manager can call this function");
    _;
  }

  modifier onlyIntegrator() {
    if (integratorLockEnabled) {
      require(integrators_.contains(msg.sender), "only integrators can call this function");
    }
    _;
  }

  modifier onlyProvider() {
    if (providerLockEnabled) {
      require(
        liquidityProviders_.contains(msg.sender),
        "only liquidity providers can call this function"
      );
    }
    _;
  }

  function initialize(
    address _nativeToken,
    address _cerosToken,
    address _lpToken,
    bool _integratorLockEnabled,
    bool _providerLockEnabled
  ) public initializer {
    __Ownable_init();
    __Pausable_init();
    __ReentrancyGuard_init();
    nativeToken = _nativeToken;
    cerosToken = _cerosToken;
    lpToken = _lpToken;
    integratorLockEnabled = _integratorLockEnabled;
    providerLockEnabled = _providerLockEnabled;
  }

  /**
   * @notice adds liquidity to the pool with native coin. See - {_addLiquidity}
   */
  function addLiquidityEth(uint256 amount1) external payable virtual onlyProvider nonReentrant {
    _addLiquidity(msg.value, amount1, true);
  }

  /**
   * @notice adds liquidity to the pool. See - {_addLiquidity}
   */
  function addLiquidity(uint256 amount0, uint256 amount1)
    external
    virtual
    onlyProvider
    nonReentrant
  {
    _addLiquidity(amount0, amount1, false);
  }

  /**
   * @notice adds liquidity of nativeToken and cerosToken by 50/50
   * @param amount0 - the amount of nativeToken
   * @param amount1 - the amount of cerosToken
   * @param useEth - if 'true', then it will get nativeToken as native else it will get ERC20 wrapped token
   */
  function _addLiquidity(
    uint256 amount0,
    uint256 amount1,
    bool useEth
  ) internal virtual {
    uint256 ratio = ICerosToken(cerosToken).ratio();
    uint256 value = (amount0 * ratio) / 1e18;
    if (amount1 < value) {
      amount0 = (amount1 * 1e18) / ratio;
    } else {
      amount1 = value;
    }
    if (useEth) {
      INativeERC20(nativeToken).deposit{ value: amount0 }();
      uint256 diff = msg.value - amount0;
      if (diff != 0) {
        _sendValue(msg.sender, diff);
      }
    } else {
      IERC20Upgradeable(nativeToken).safeTransferFrom(msg.sender, address(this), amount0);
    }
    IERC20Upgradeable(cerosToken).safeTransferFrom(msg.sender, address(this), amount1);
    if (nativeTokenAmount == 0 && cerosTokenAmount == 0) {
      require(amount0 > 1e18, "cannot add first time less than 1 token");
      nativeTokenAmount = amount0;
      cerosTokenAmount = amount1;

      ILP(lpToken).mint(msg.sender, (2 * amount0) / 10**8);
    } else {
      uint256 allInNative = nativeTokenAmount + (cerosTokenAmount * 1e18) / ratio;
      uint256 mintAmount = (2 * amount0 * ILP(lpToken).totalSupply()) / allInNative;
      nativeTokenAmount += amount0;
      cerosTokenAmount += amount1;

      ILP(lpToken).mint(msg.sender, mintAmount);
    }
    emit LiquidityChange(msg.sender, amount0, amount1, nativeTokenAmount, cerosTokenAmount, true);
  }

  /**
   * @notice removes liquidity from pool by lp amount. See - {_removeliquidityLp}
   */
  function removeLiquidity(uint256 lpAmount) external virtual nonReentrant {
    _removeLiquidityLp(lpAmount, false);
  }

  /**
   * @notice removes liquidity from pool by lp amount. See - {_removeliquidityLp}
   */
  function removeLiquidityEth(uint256 lpAmount) external virtual nonReentrant {
    _removeLiquidityLp(lpAmount, true);
  }

  /**
   * @notice removes liquidity from pool by percent. See - {_removeliquidityPercent}
   */
  function removeLiquidityPercent(uint256 percent) external virtual nonReentrant {
    _removeLiquidityPercent(percent, false);
  }

  /**
   * @notice removes liquidity from pool by percent. See - {_removeliquidityPercent}
   */
  function removeLiquidityPercentEth(uint256 percent) external virtual nonReentrant {
    _removeLiquidityPercent(percent, true);
  }

  /**
   * @notice removes liquidity from pool by percent.
   * @param percent - the percent of your provided liquidity that you want to remove
   * @param useEth - if 'true' then transfer native token amount by native coin else by wrapped
   */
  function _removeLiquidityPercent(uint256 percent, bool useEth) internal virtual {
    require(percent > 0 && percent <= 1e18, "percent should be more than 0 and less than 1e18"); // max percnet(100%) is -> 10 ** 18
    uint256 balance = ILP(lpToken).balanceOf(msg.sender);
    uint256 removedLp = (balance * percent) / 1e18;
    _removeLiquidity(removedLp, useEth);
  }

  /**
   * @notice removes liquidity from pool by lp amount.
   * @param removedLp - the amount of your lp tokens that you want to remove.
   * @param useEth - if 'true' then transfer native token amount by native coin else by wrapped
   */
  function _removeLiquidityLp(uint256 removedLp, bool useEth) internal virtual {
    uint256 balance = ILP(lpToken).balanceOf(msg.sender);
    if (removedLp == type(uint256).max) {
      removedLp = balance;
    } else {
      require(removedLp <= balance, "you want to remove more than your lp balance");
    }
    require(removedLp > 0, "lp amount should be more than 0");
    _removeLiquidity(removedLp, useEth);
  }

  /**
   * @notice removes liquidity from pool by lp amount.
   * @param removedLp - the amount of your lp tokens that you want to remove.
   * @param useEth - if 'true' then transfer native token amount by native coin else by wrapped
   */
  function _removeLiquidity(uint256 removedLp, bool useEth) internal virtual {
    uint256 totalSupply = ILP(lpToken).totalSupply();
    ILP(lpToken).burn(msg.sender, removedLp);
    uint256 amount0Removed = (removedLp * nativeTokenAmount) / totalSupply;
    uint256 amount1Removed = (removedLp * cerosTokenAmount) / totalSupply;

    nativeTokenAmount -= amount0Removed;
    cerosTokenAmount -= amount1Removed;

    if (useEth) {
      INativeERC20(nativeToken).withdraw(amount0Removed);
      _sendValue(msg.sender, amount0Removed);
    } else {
      IERC20Upgradeable(nativeToken).safeTransfer(msg.sender, amount0Removed);
    }
    IERC20Upgradeable(cerosToken).safeTransfer(msg.sender, amount1Removed);
    emit LiquidityChange(
      msg.sender,
      amount0Removed,
      amount1Removed,
      nativeTokenAmount,
      cerosTokenAmount,
      false
    );
  }

  /**
   * @notice swaps the native coin to ceros or vise versa. See - {_swap}
   */
  function swapEth(
    bool nativeToCeros,
    uint256 amountIn,
    address receiver
  ) external payable virtual onlyIntegrator nonReentrant returns (uint256 amountOut) {
    if (nativeToCeros) {
      require(msg.value == amountIn, "You should send the amountIn coin to the cointract");
    } else {
      require(msg.value == 0, "no need to send value if swapping ceros to Native");
    }
    return _swap(nativeToCeros, amountIn, receiver, true);
  }

  /**
   * @notice swaps the native wrapped token to ceros or vise versa. See - {_swap}
   */
  function swap(
    bool nativeToCeros,
    uint256 amountIn,
    address receiver
  ) external virtual onlyIntegrator nonReentrant returns (uint256 amountOut) {
    return _swap(nativeToCeros, amountIn, receiver, false);
  }

  /**
   * @notice swaps native token to ceros or ceros token to native.
   * @param nativeToCeros - if 'true' then will swap native token to ceros, else ceros-native
   * @param amountIn - the amount of tokens that you want to swap
   * @param receiver - the address of swap receiver
   * @param useEth - if 'true' then transfer native token amount by native coin else by wrapped
   */
  function _swap(
    bool nativeToCeros,
    uint256 amountIn,
    address receiver,
    bool useEth
  ) internal virtual returns (uint256 amountOut) {
    require(receiver != address(0), "invaid receiver address");
    uint256 ratio = ICerosToken(cerosToken).ratio();
    if (nativeToCeros) {
      if (useEth) {
        INativeERC20(nativeToken).deposit{ value: amountIn }();
      } else {
        IERC20Upgradeable(nativeToken).safeTransferFrom(msg.sender, address(this), amountIn);
      }
      if (!excludedFromFee[msg.sender]) {
        uint256 stakeFeeAmt = (amountIn * stakeFee) / FEE_MAX;
        amountIn -= stakeFeeAmt;
        uint256 managerFeeAmt = (stakeFeeAmt * managerFee) / FEE_MAX;
        uint256 ownerFeeAmt = (stakeFeeAmt * ownerFee) / FEE_MAX;
        uint256 integratorFeeAmt;
        if (integratorLockEnabled) {
          integratorFeeAmt = (stakeFeeAmt * integratorFee) / FEE_MAX;
          if (integratorFeeAmt > 0) {
            IERC20Upgradeable(nativeToken).safeTransfer(msg.sender, integratorFeeAmt);
          }
        }
        nativeTokenAmount +=
          amountIn +
          (stakeFeeAmt - managerFeeAmt - ownerFeeAmt - integratorFeeAmt);

        ownerFeeCollected.nativeFee += uint128(ownerFeeAmt);
        managerFeeCollected.nativeFee += uint128(managerFeeAmt);
      } else {
        nativeTokenAmount += amountIn;
      }
      amountOut = (amountIn * ratio) / 1e18;
      require(cerosTokenAmount >= amountOut, "Not enough liquidity");
      cerosTokenAmount -= amountOut;
      IERC20Upgradeable(cerosToken).safeTransfer(receiver, amountOut);
      emit Swap(msg.sender, receiver, nativeToCeros, amountIn, amountOut);
    } else {
      IERC20Upgradeable(cerosToken).safeTransferFrom(msg.sender, address(this), amountIn);
      if (!excludedFromFee[msg.sender]) {
        uint256 unstakeFeeAmt = (amountIn * unstakeFee) / FEE_MAX;
        amountIn -= unstakeFeeAmt;
        uint256 managerFeeAmt = (unstakeFeeAmt * managerFee) / FEE_MAX;
        uint256 ownerFeeAmt = (unstakeFeeAmt * ownerFee) / FEE_MAX;
        uint256 integratorFeeAmt;
        if (integratorLockEnabled) {
          integratorFeeAmt = (unstakeFeeAmt * integratorFee) / FEE_MAX;
          if (integratorFeeAmt > 0) {
            IERC20Upgradeable(cerosToken).safeTransfer(msg.sender, integratorFeeAmt);
          }
        }
        cerosTokenAmount +=
          amountIn +
          (unstakeFeeAmt - managerFeeAmt - ownerFeeAmt - integratorFeeAmt);

        ownerFeeCollected.cerosFee += uint128(ownerFeeAmt);
        managerFeeCollected.cerosFee += uint128(managerFeeAmt);
      } else {
        cerosTokenAmount += amountIn;
      }
      amountOut = (amountIn * 1e18) / ratio;
      require(nativeTokenAmount >= amountOut, "Not enough liquidity");
      nativeTokenAmount -= amountOut;
      if (useEth) {
        INativeERC20(nativeToken).withdraw(amountOut);
        _sendValue(receiver, amountOut);
      } else {
        IERC20Upgradeable(nativeToken).safeTransfer(receiver, amountOut);
      }
      emit Swap(msg.sender, receiver, nativeToCeros, amountIn, amountOut);
    }
  }

  /**
   * @notice view function which retruns amount out by amount in
   * @param nativeToCeros - if 'true' then will show native token to ceros, else ceros-native
   * @param amountIn - the amount of tokens that you want to swap
   * @param isExcludedFromFee - if 'true' will calculate amount out without fees
   */
  function getAmountOut(
    bool nativeToCeros,
    uint256 amountIn,
    bool isExcludedFromFee
  ) external view virtual returns (uint256 amountOut, bool enoughLiquidity) {
    uint256 ratio = ICerosToken(cerosToken).ratio();
    if (nativeToCeros) {
      if (!isExcludedFromFee) {
        uint256 stakeFeeAmt = (amountIn * stakeFee) / FEE_MAX;
        amountIn -= stakeFeeAmt;
      }
      amountOut = (amountIn * ratio) / 1e18;
      enoughLiquidity = cerosTokenAmount >= amountOut;
    } else {
      if (!isExcludedFromFee) {
        uint256 unstakeFeeAmt = (amountIn * unstakeFee) / FEE_MAX;
        amountIn -= unstakeFeeAmt;
      }
      amountOut = (amountIn * 1e18) / ratio;
      enoughLiquidity = nativeTokenAmount >= amountOut;
    }
  }

  /**
   * @notice view function which retruns amount in by amount out
   * @param nativeToCeros - if 'true' then will show native token to ceros, else ceros-native
   * @param amountOut - the amount of tokens that you want to get
   * @param isExcludedFromFee - if 'true' will calculate amount out without fees
   */
  function getAmountIn(
    bool nativeToCeros,
    uint256 amountOut,
    bool isExcludedFromFee
  ) external view virtual returns (uint256 amountIn, bool enoughLiquidity) {
    uint256 dust = 1;
    dust = amountOut == 0 ? 0 : 1;
    uint256 ratio = ICerosToken(cerosToken).ratio();
    if (nativeToCeros) {
      amountIn = ((amountOut * 1e18) / ratio) + dust;
      if (!isExcludedFromFee) {
        amountIn = (amountIn * FEE_MAX) / (FEE_MAX - stakeFee); // amountIn with Fee
      }
      enoughLiquidity = cerosTokenAmount >= amountOut;
    } else {
      amountIn = ((amountOut * ratio) / 1e18) + dust;
      if (!isExcludedFromFee) {
        amountIn = (amountIn * FEE_MAX) / (FEE_MAX - unstakeFee); // amountIn with Fee
      }
      enoughLiquidity = nativeTokenAmount >= amountOut;
    }
  }

  /// sends the amount to the receiver address
  function _sendValue(address receiver, uint256 amount) internal virtual {
    payable(receiver).transfer(amount);
  }

  /**
   * @notice See - {_withdrawOwnerFee}
   */
  function withdrawOwnerFeeEth(uint256 amount0, uint256 amount1)
    external
    virtual
    onlyOwner
    nonReentrant
  {
    _withdrawOwnerFee(amount0, amount1, true);
  }

  /**
   * @notice See - {_withdrawOwnerFee}
   */
  function withdrawOwnerFee(uint256 amount0, uint256 amount1)
    external
    virtual
    onlyOwner
    nonReentrant
  {
    _withdrawOwnerFee(amount0, amount1, false);
  }

  /**
   * @notice withdraws fees for owner
   * @param amount0Raw - amount of native to receve. use MAX_UINT256 to get all available amount.
   * @param amount1Raw - amount of ceros token to receve. use MAX_UINT256 to get all available amount.
   * @param useEth - if 'true' then transfer native token amount by native coin else by wrapped
   */
  function _withdrawOwnerFee(
    uint256 amount0Raw,
    uint256 amount1Raw,
    bool useEth
  ) internal virtual {
    uint128 amount0;
    uint128 amount1;
    if (amount0Raw == type(uint256).max) {
      amount0 = ownerFeeCollected.nativeFee;
    } else {
      require(amount0Raw <= type(uint128).max, "unsafe typecasting");
      amount0 = uint128(amount0Raw);
    }
    if (amount1Raw == type(uint256).max) {
      amount1 = ownerFeeCollected.cerosFee;
    } else {
      require(amount1Raw <= type(uint128).max, "unsafe typecasting");
      amount1 = uint128(amount1Raw);
    }
    if (amount0 > 0) {
      ownerFeeCollected.nativeFee -= amount0;
      if (useEth) {
        INativeERC20(nativeToken).withdraw(amount0);
        _sendValue(msg.sender, amount0);
      } else {
        IERC20Upgradeable(nativeToken).safeTransfer(msg.sender, amount0);
      }
    }
    if (amount1 > 0) {
      ownerFeeCollected.cerosFee -= amount1;
      IERC20Upgradeable(cerosToken).safeTransfer(msg.sender, amount1);
    }
  }

  function getRemainingManagerFee(address managerAddress)
    external
    view
    virtual
    returns (FeeAmounts memory feeRewards)
  {
    if (managers_.contains(managerAddress)) {
      uint256 managersLength = managers_.length();
      FeeAmounts memory currentManagerRewardDebt = managerRewardDebt[managerAddress];
      FeeAmounts memory accFee;
      accFee.nativeFee =
        _accFeePerManager.nativeFee +
        (managerFeeCollected.nativeFee - _alreadyUpdatedFees.nativeFee) /
        uint128(managersLength);
      accFee.cerosFee =
        _accFeePerManager.cerosFee +
        (managerFeeCollected.cerosFee - _alreadyUpdatedFees.cerosFee) /
        uint128(managersLength);
      feeRewards.nativeFee = accFee.nativeFee - currentManagerRewardDebt.nativeFee;
      feeRewards.cerosFee = accFee.cerosFee - currentManagerRewardDebt.cerosFee;
    }
  }

  /**
   * @notice See - {_withdrawManagerFee}
   */
  function withdrawManagerFee() external virtual onlyManager nonReentrant {
    _withdrawManagerFee(msg.sender, false);
  }

  /**
   * @notice See - {_withdrawManagerFee}
   */
  function withdrawManagerFeeEth() external virtual onlyManager nonReentrant {
    _withdrawManagerFee(msg.sender, true);
  }

  /**
   * @notice withdraws fees for manager
   * @param managerAddress - manager address to transfer the whole fees
   * @param useNative - if 'true' then transfer native token amount by native coin else by wrapped
   */
  function _withdrawManagerFee(address managerAddress, bool useNative) internal virtual {
    FeeAmounts memory feeRewards;
    FeeAmounts storage currentManagerRewardDebt = managerRewardDebt[managerAddress];
    _updateManagerFees();
    feeRewards.nativeFee = _accFeePerManager.nativeFee - currentManagerRewardDebt.nativeFee;
    feeRewards.cerosFee = _accFeePerManager.cerosFee - currentManagerRewardDebt.cerosFee;
    if (feeRewards.nativeFee > 0) {
      currentManagerRewardDebt.nativeFee += feeRewards.nativeFee;
      _claimedManagerFees.nativeFee += feeRewards.nativeFee;
      if (useNative) {
        INativeERC20(nativeToken).withdraw(feeRewards.nativeFee);
        _sendValue(managerAddress, feeRewards.nativeFee);
      } else {
        IERC20Upgradeable(nativeToken).safeTransfer(managerAddress, feeRewards.nativeFee);
      }
    }
    if (feeRewards.cerosFee > 0) {
      currentManagerRewardDebt.cerosFee += feeRewards.cerosFee;
      _claimedManagerFees.cerosFee += feeRewards.cerosFee;
      IERC20Upgradeable(cerosToken).safeTransfer(managerAddress, feeRewards.cerosFee);
    }
  }

  function _updateManagerFees() internal virtual {
    uint256 managersLength = managers_.length();
    _accFeePerManager.nativeFee +=
      (managerFeeCollected.nativeFee - _alreadyUpdatedFees.nativeFee) /
      uint128(managersLength);
    _accFeePerManager.cerosFee +=
      (managerFeeCollected.cerosFee - _alreadyUpdatedFees.cerosFee) /
      uint128(managersLength);
    _alreadyUpdatedFees.nativeFee = managerFeeCollected.nativeFee;
    _alreadyUpdatedFees.cerosFee = managerFeeCollected.cerosFee;
  }

  function add(address value, UserType utype) public virtual returns (bool) {
    require(value != address(0), "cannot add address(0)");
    bool success = false;
    if (utype == UserType.MANAGER) {
      require(msg.sender == owner(), "Only owner can add manager");
      if (!managers_.contains(value)) {
        uint256 managersLength = managers_.length();
        if (managersLength != 0) {
          _updateManagerFees();
          managerRewardDebt[value].nativeFee = _accFeePerManager.nativeFee;
          managerRewardDebt[value].cerosFee = _accFeePerManager.cerosFee;
        }
        success = managers_.add(value);
      }
    } else if (utype == UserType.LIQUIDITY_PROVIDER) {
      require(managers_.contains(msg.sender), "Only manager can add liquidity provider");
      success = liquidityProviders_.add(value);
    } else {
      require(managers_.contains(msg.sender), "Only manager can add integrator");
      success = integrators_.add(value);
    }
    if (success) {
      emit UserTypeChanged(value, utype, true);
    }
    return success;
  }

  function setFee(uint24 newFee, FeeType feeType) external virtual onlyOwnerOrManager {
    require(newFee < FEE_MAX, "Unsupported size of fee!");
    if (feeType == FeeType.OWNER) {
      require(msg.sender == owner(), "only owner can call this function");
      require(newFee + managerFee + integratorFee < FEE_MAX, "fee sum is more than 100%");
      emit FeeChanged(feeType, ownerFee, newFee);
      ownerFee = newFee;
    } else if (feeType == FeeType.MANAGER) {
      require(newFee + ownerFee + integratorFee < FEE_MAX, "fee sum is more than 100%");
      emit FeeChanged(feeType, managerFee, newFee);
      managerFee = newFee;
    } else if (feeType == FeeType.INTEGRATOR) {
      require(newFee + ownerFee + managerFee < FEE_MAX, "fee sum is more than 100%");
      emit FeeChanged(feeType, integratorFee, newFee);
      integratorFee = newFee;
    } else if (feeType == FeeType.STAKE) {
      emit FeeChanged(feeType, stakeFee, newFee);
      stakeFee = newFee;
    } else {
      emit FeeChanged(feeType, unstakeFee, newFee);
      unstakeFee = newFee;
    }
  }

  function setThreshold(uint24 newThreshold) external virtual onlyManager {
    require(newThreshold < FEE_MAX / 2, "threshold shuold be less than 50%");
    threshold = newThreshold;
    emit ThresholdChanged(newThreshold);
  }

  function setMaticPool(address newMaticPool) external virtual onlyOwner {
    maticPool = IMaticPool(newMaticPool);
    emit MaticPoolChanged(newMaticPool);
  }

  function enableIntegratorLock(bool enable) external virtual onlyOwnerOrManager {
    integratorLockEnabled = enable;
    emit IntegratorLockEnabled(enable);
  }

  function enableProviderLock(bool enable) external virtual onlyOwnerOrManager {
    providerLockEnabled = enable;
    emit ProviderLockEnabled(enable);
  }

  function excludeFromFee(address value, bool exclude) external virtual onlyOwnerOrManager {
    excludedFromFee[value] = exclude;
    emit ExcludedFromFee(value, exclude);
  }

  /**
   * @notice triggers the rebalance and stakes/unstakes the amounts of tokens to balance the pool(50/50)
   */
  function triggerRebalanceAnkr() external virtual nonReentrant onlyManager {
    skim();
    uint256 ratio = ICerosToken(cerosToken).ratio();
    uint256 amountAInNative = nativeTokenAmount;
    uint256 amountBInNative = (cerosTokenAmount * 1e18) / ratio;
    uint256 wholeAmount = amountAInNative + amountBInNative;
    bool isStake = amountAInNative > amountBInNative;
    if (!isStake) {
      uint256 temp = amountAInNative;
      amountAInNative = amountBInNative;
      amountBInNative = temp;
    }
    require(
      (amountBInNative * FEE_MAX) / wholeAmount < threshold,
      "the proportions are not less than threshold"
    );
    uint256 amount = (amountAInNative - amountBInNative) / 2;
    if (isStake) {
      nativeTokenAmount -= amount;
      INativeERC20(nativeToken).withdraw(amount);
      maticPool.stake{ value: amount }(false);
    } else {
      uint256 cerosAmt = (amount * ratio) / 1e18;
      uint256 commission = maticPool.unstakeCommission();
      cerosTokenAmount -= cerosAmt;
      nativeTokenAmount -= commission;
      INativeERC20(nativeToken).withdraw(commission);
      maticPool.unstake{ value: commission }(cerosAmt, false);
    }
  }

  /**
   * @notice triggers the rebalance and stakes/unstakes the amounts of tokens to balance the pool MATIC balance with given percent
   * @dev ignore threshold
   */
  function triggerRebalanceAnkrWithPercent(uint16 percent) external virtual nonReentrant onlyManager {
    require(percent >= 0 && percent <= 10000, "percent should be in range 0-100.00");

    skim();
    uint256 ratio = ICerosToken(cerosToken).ratio();

    // MATIC balance of pool
    uint256 amountAInNative = nativeTokenAmount;
    // ankrMATIC balance of pool in MATIC
    uint256 amountBInNative = (cerosTokenAmount * 1e18) / ratio;
    // total pool balance
    uint256 wholeAmount = amountAInNative + amountBInNative;

    uint256 expectedNative = wholeAmount * percent / 10000;

    uint256 amount;
    if (expectedNative < amountAInNative) {
      // we need stake to decrease MATIC amount
      amount = amountAInNative - expectedNative;

      require(nativeTokenAmount >= amount, "not enough MATIC to stake");
      nativeTokenAmount -= amount;
      INativeERC20(nativeToken).withdraw(amount);
      maticPool.stake{ value: amount }(false);
    } else if (expectedNative > amountAInNative) {
      // we need unstake to increase MATIC amount
      // set diff as amount to unstake
      amount = expectedNative - amountAInNative;

      uint256 cerosAmt = (amount * ratio) / 1e18;
      uint256 commission = maticPool.unstakeCommission();

      require(cerosTokenAmount >= cerosAmt, "not enough to pay ankrMATIC commission");
      require(nativeTokenAmount >= commission, "not enough to pay MATIC commission");

      cerosTokenAmount -= cerosAmt;
      nativeTokenAmount -= commission;

      INativeERC20(nativeToken).withdraw(commission);
      maticPool.unstake{ value: commission }(cerosAmt, false);
    } else {
      revert("already balanced");
    }
  }

  function approveToMaticPool() external virtual {
    IERC20Upgradeable(cerosToken).safeApprove(address(maticPool), type(uint256).max);
  }

  /**
   * @notice adds the not registered tokens to the liquidity pool
   */
  function skim() public virtual {
    uint256 contractBal = address(this).balance;
    uint256 contractWNativeBal = INativeERC20(nativeToken).balanceOf(address(this)) -
      ownerFeeCollected.nativeFee -
      (managerFeeCollected.nativeFee - _claimedManagerFees.nativeFee);
    uint256 contractCerosBal = ICerosToken(cerosToken).balanceOf(address(this)) -
      ownerFeeCollected.cerosFee -
      (managerFeeCollected.cerosFee - _claimedManagerFees.cerosFee);

    if (contractWNativeBal > nativeTokenAmount) {
      nativeTokenAmount = contractWNativeBal;
    }
    if (contractCerosBal > cerosTokenAmount) {
      cerosTokenAmount = contractCerosBal;
    }

    if (contractBal > nativeTokenAmount) {
      INativeERC20(nativeToken).deposit{ value: contractBal }();
      nativeTokenAmount += contractBal;
    }
  }

  function remove(address value, UserType utype) public virtual nonReentrant returns (bool) {
    require(value != address(0), "cannot remove address(0)");
    bool success = false;
    if (utype == UserType.MANAGER) {
      require(msg.sender == owner(), "Only owner can remove manager");
      if (managers_.contains(value)) {
        _withdrawManagerFee(value, false);
        success = managers_.remove(value);
        require(success, "cannot remove manager");
        delete managerRewardDebt[value];
      }
    } else if (utype == UserType.LIQUIDITY_PROVIDER) {
      require(managers_.contains(msg.sender), "Only manager can remove liquidity provider");
      success = liquidityProviders_.remove(value);
    } else {
      require(managers_.contains(msg.sender), "Only manager can remove integrator");
      success = integrators_.remove(value);
    }
    if (success) {
      emit UserTypeChanged(value, utype, false);
    }
    return success;
  }

  function contains(address value, UserType utype) external view virtual returns (bool) {
    if (utype == UserType.MANAGER) {
      return managers_.contains(value);
    } else if (utype == UserType.LIQUIDITY_PROVIDER) {
      return liquidityProviders_.contains(value);
    } else {
      return integrators_.contains(value);
    }
  }

  function length(UserType utype) external view virtual returns (uint256) {
    if (utype == UserType.MANAGER) {
      return managers_.length();
    } else if (utype == UserType.LIQUIDITY_PROVIDER) {
      return liquidityProviders_.length();
    } else {
      return integrators_.length();
    }
  }

  function at(uint256 index, UserType utype) external view virtual returns (address) {
    if (utype == UserType.MANAGER) {
      return managers_.at(index);
    } else if (utype == UserType.LIQUIDITY_PROVIDER) {
      return liquidityProviders_.at(index);
    } else {
      return integrators_.at(index);
    }
  }

  // solhint-disable-next-line no-empty-blocks
  receive() external payable virtual {}
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 *  Trying to delete such a structure from storage will likely result in data corruption, rendering the structure unusable.
 *  See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 *  In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an array of EnumerableSet.
 * ====
 */
library EnumerableSetUpgradeable {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

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
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
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
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
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
pragma solidity ^0.8.15;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface ILP is IERC20Upgradeable {
  function mint(address, uint256) external;

  function burn(address, uint256) external;
}

// SPDX-License-Identifier: Unliscensed
pragma solidity ^0.8.0;

interface ISwapPool {
    function swap(
        bool nativeToCeros,
        uint256 amountIn,
        address receiver
    ) external returns (uint256 amountOut);
    
    function getAmountOut(
        bool nativeToCeros,
        uint amountIn,
        bool isExcludedFromFee) 
        external view returns(uint amountOut, bool enoughLiquidity);

    function getAmountIn(
        bool nativeToCeros,
        uint amountOut,
        bool isExcludedFromFee)
        external view returns(uint amountIn, bool enoughLiquidity);
    
    function unstakeFee() external view returns (uint24 unstakeFee);
    function stakeFee() external view returns (uint24 stakeFee);

    function FEE_MAX() external view returns (uint24 feeMax);

    function cerosTokenAmount() external view returns(uint256);

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

interface IMaticPool {
  function stake(bool isRebasing) external payable;

  function unstake(uint256 amount, bool isRebasing) external payable;

  function stakeCommission() external view returns (uint256);

  function unstakeCommission() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ICerosToken is IERC20 {
  function ratio() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface INativeERC20 is IERC20 {
  function deposit() external payable;

  function withdraw(uint256) external;
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