// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

// ==================== External Imports ====================

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// ==================== Internal Imports ====================

import { ModuleBase } from "../lib/ModuleBase.sol";
import { PositionUtil } from "../lib/PositionUtil.sol";

import { IController } from "../../interfaces/IController.sol";
import { IWrapAdapter } from "../../interfaces/IWrapAdapter.sol";
import { IMatrixToken } from "../../interfaces/IMatrixToken.sol";
import { IWrapV2Adapter } from "../../interfaces/IWrapV2Adapter.sol";

/**
 * @title WrapModuleV2
 *
 * @dev WrapModuleV2 and WrapV2Adapters enables the wrapping of ERC20 and Ether positions via third party protocols.
 * Some examples of wrap actions include wrapping, DAI to cDAI (Compound) or Dai to aDai (AAVE).
 */
contract WrapModuleV2 is ModuleBase, ReentrancyGuard {
    using SafeCast for int256;
    using PositionUtil for IMatrixToken;

    // ==================== Variables ====================

    address internal _weth;

    // ==================== Events ====================

    event WrapComponent(
        IMatrixToken indexed matrixToken,
        address indexed underlyingToken,
        address indexed wrappedToken,
        uint256 underlyingQuantity,
        uint256 wrappedQuantity,
        string integrationName
    );

    event UnwrapComponent(
        IMatrixToken indexed matrixToken,
        address indexed underlyingToken,
        address indexed wrappedToken,
        uint256 underlyingQuantity,
        uint256 wrappedQuantity,
        string integrationName
    );

    // ==================== Constructor function ====================

    constructor(IController controller, address weth) ModuleBase(controller) {
        _weth = weth;
    }

    // ==================== External functions ====================

    function getWeth() external view returns (address) {
        return _weth;
    }

    /**
     * @dev MANAGER-ONLY: Instructs the MatrixToken to wrap an underlying asset into a wrappedToken via a specified adapter.
     *
     * @param matrixToken        Instance of the MatrixToken
     * @param underlyingToken    Address of the component to be wrapped
     * @param wrappedToken       Address of the desired wrapped token
     * @param underlyingUnits    Quantity of underlying units in Position units
     * @param integrationName    Name of wrap module integration (mapping on integration registry)
     * @param wrapData           Arbitrary bytes to pass into the WrapV2Adapter
     */
    function wrap(
        IMatrixToken matrixToken,
        address underlyingToken,
        address wrappedToken,
        uint256 underlyingUnits,
        string calldata integrationName,
        bytes memory wrapData
    ) external nonReentrant onlyManagerAndValidMatrix(matrixToken) {
        (uint256 notionalUnderlyingWrapped, uint256 notionalWrapped) = _validateWrapAndUpdate(
            integrationName,
            matrixToken,
            underlyingToken,
            wrappedToken,
            underlyingUnits,
            wrapData,
            false // does not use Ether
        );

        emit WrapComponent(matrixToken, underlyingToken, wrappedToken, notionalUnderlyingWrapped, notionalWrapped, integrationName);
    }

    /**
     * @dev MANAGER-ONLY: Instructs the MatrixToken to wrap Ether into a wrappedToken via a specified adapter. Since MatrixToken
     * only hold WETH, in order to support protocols that collateralize with Ether the MatrixToken's WETH must be unwrapped
     * first before sending to the external protocol.
     *
     * @param matrixToken        Instance of the MatrixToken
     * @param wrappedToken       Address of the desired wrapped token
     * @param underlyingUnits    Quantity of underlying units in Position units
     * @param integrationName    Name of wrap module integration (mapping on integration registry)
     * @param wrapData           Arbitrary bytes to pass into the WrapV2Adapter
     */
    function wrapWithEther(
        IMatrixToken matrixToken,
        address wrappedToken,
        uint256 underlyingUnits,
        string calldata integrationName,
        bytes memory wrapData
    ) external nonReentrant onlyManagerAndValidMatrix(matrixToken) {
        (uint256 notionalUnderlyingWrapped, uint256 notionalWrapped) = _validateWrapAndUpdate(
            integrationName,
            matrixToken,
            _weth,
            wrappedToken,
            underlyingUnits,
            wrapData,
            true // uses Ether
        );

        emit WrapComponent(matrixToken, _weth, wrappedToken, notionalUnderlyingWrapped, notionalWrapped, integrationName);
    }

    /**
     * @dev MANAGER-ONLY: Instructs the MatrixToken to unwrap a wrapped asset into its underlying via a specified adapter.
     *
     * @param matrixToken        Instance of the MatrixToken
     * @param underlyingToken    Address of the underlying asset
     * @param wrappedToken       Address of the component to be unwrapped
     * @param wrappedUnits       Quantity of wrapped tokens in Position units
     * @param integrationName    ID of wrap module integration (mapping on integration registry)
     * @param unwrapData         Arbitrary bytes to pass into the WrapV2Adapter
     */
    function unwrap(
        IMatrixToken matrixToken,
        address underlyingToken,
        address wrappedToken,
        uint256 wrappedUnits,
        string calldata integrationName,
        bytes memory unwrapData
    ) external nonReentrant onlyManagerAndValidMatrix(matrixToken) {
        (uint256 notionalUnderlyingUnwrapped, uint256 notionalUnwrapped) = _validateUnwrapAndUpdate(
            integrationName,
            matrixToken,
            underlyingToken,
            wrappedToken,
            wrappedUnits,
            unwrapData,
            false // uses Ether
        );

        emit UnwrapComponent(matrixToken, underlyingToken, wrappedToken, notionalUnderlyingUnwrapped, notionalUnwrapped, integrationName);
    }

    /**
     * @dev MANAGER-ONLY: Instructs the MatrixToken to unwrap a wrapped asset collateralized by Ether into Wrapped Ether. Since
     * external protocol will send back Ether that Ether must be Wrapped into WETH in order to be accounted for by MatrixToken.
     *
     * @param matrixToken        Instance of the MatrixToken
     * @param wrappedToken       Address of the component to be unwrapped
     * @param wrappedUnits       Quantity of wrapped tokens in Position units
     * @param integrationName    ID of wrap module integration (mapping on integration registry)
     * @param unwrapData         Arbitrary bytes to pass into the WrapV2Adapter
     */
    function unwrapWithEther(
        IMatrixToken matrixToken,
        address wrappedToken,
        uint256 wrappedUnits,
        string calldata integrationName,
        bytes memory unwrapData
    ) external nonReentrant onlyManagerAndValidMatrix(matrixToken) {
        (uint256 notionalUnderlyingUnwrapped, uint256 notionalUnwrapped) = _validateUnwrapAndUpdate(
            integrationName,
            matrixToken,
            _weth,
            wrappedToken,
            wrappedUnits,
            unwrapData,
            true // uses Ether
        );

        emit UnwrapComponent(matrixToken, _weth, wrappedToken, notionalUnderlyingUnwrapped, notionalUnwrapped, integrationName);
    }

    /**
     * @dev Initializes this module to the MatrixToken. Only callable by the MatrixToken's manager.
     *
     * @param matrixToken    Instance of the MatrixToken to issue
     */
    function initialize(IMatrixToken matrixToken) external onlyMatrixManager(matrixToken, msg.sender) {
        require(_controller.isMatrix(address(matrixToken)), "WMb0a"); // "Must be controller-enabled MatrixToken"
        require(isMatrixPendingInitialization(matrixToken), "WMb0b"); // "Must be pending initialization"
        matrixToken.initializeModule();
    }

    /**
     * @dev Removes this module from the MatrixToken, via call by the MatrixToken.
     */
    function removeModule() external override {}

    // ==================== Internal functions ====================

    /**
     * @dev Validates the wrap operation is valid. In particular, the following checks are made:
     * - The position is Default
     * - The position has sufficient units given the transact quantity
     * - The transact quantity > 0
     *
     * It is expected that the adapter will check if wrappedToken/underlyingToken are a valid pair for the given
     * integration.
     */
    function _validateInputs(
        IMatrixToken matrixToken,
        address transactPosition,
        uint256 transactPositionUnits
    ) internal view {
        require(transactPositionUnits > 0, "WMb1a"); // "Target position units must be > 0"
        require(matrixToken.hasDefaultPosition(transactPosition), "WMb1b"); // "Target default position must be component"
        require(matrixToken.hasSufficientDefaultUnits(transactPosition, transactPositionUnits), "WMb1c"); // "Unit cant be greater than existing"
    }

    /**
     * @dev The WrapModule calculates the total notional underlying to wrap, approves the underlying to the 3rd party integration contract,
     * then invokes the MatrixToken to call wrap by passing its calldata along. When raw ETH is being used (usesEther = true)
     * WETH position must first be unwrapped and underlyingAddress sent to adapter must be external protocol's ETH representative address.
     *
     * Returns notional amount of underlying tokens and wrapped tokens that were wrapped.
     */
    function _validateWrapAndUpdate(
        string calldata integrationName,
        IMatrixToken matrixToken,
        address underlyingToken,
        address wrappedToken,
        uint256 underlyingUnits,
        bytes memory wrapData,
        bool usesEther
    ) internal returns (uint256, uint256) {
        _validateInputs(matrixToken, underlyingToken, underlyingUnits);

        // Snapshot pre wrap balances
        (uint256 preActionUnderlyingNotional, uint256 preActionWrapNotional) = _snapshotTargetAssetsBalance(matrixToken, underlyingToken, wrappedToken);
        uint256 notionalUnderlying = PositionUtil.getDefaultTotalNotional(matrixToken.totalSupply(), underlyingUnits);

        IWrapV2Adapter wrapAdapter = IWrapV2Adapter(getAndValidateAdapter(integrationName));

        // Execute any pre-wrap actions depending on if using raw ETH or not
        if (usesEther) {
            matrixToken.invokeUnwrapWETH(_weth, notionalUnderlying);
        } else {
            matrixToken.invokeSafeApprove(underlyingToken, wrapAdapter.getSpenderAddress(underlyingToken, wrappedToken), notionalUnderlying);
        }

        // Get function call data and invoke on MatrixToken
        _createWrapDataAndInvoke(
            matrixToken,
            wrapAdapter,
            usesEther ? wrapAdapter.ETH_TOKEN_ADDRESS() : underlyingToken,
            wrappedToken,
            notionalUnderlying,
            wrapData
        );

        // Snapshot post wrap balances
        (uint256 postActionUnderlyingNotional, uint256 postActionWrapNotional) = _snapshotTargetAssetsBalance(matrixToken, underlyingToken, wrappedToken);

        _updatePosition(matrixToken, underlyingToken, preActionUnderlyingNotional, postActionUnderlyingNotional);
        _updatePosition(matrixToken, wrappedToken, preActionWrapNotional, postActionWrapNotional);

        return (preActionUnderlyingNotional - postActionUnderlyingNotional, postActionWrapNotional - preActionWrapNotional);
    }

    /**
     * @dev The WrapModule calculates the total notional wrap token to unwrap, then invokes the MatrixToken to call unwrap
     * by passing its calldata along. When raw ETH is being used (usesEther = true) underlyingAddress sent to adapter must
     * be set to external protocol's ETH representative address and ETH returned from external protocol is wrapped.
     *
     * @return notional amount of underlying tokens and wrapped tokens unwrapped.
     */
    function _validateUnwrapAndUpdate(
        string calldata integrationName,
        IMatrixToken matrixToken,
        address underlyingToken,
        address wrappedToken,
        uint256 wrappedTokenUnits,
        bytes memory unwrapData,
        bool usesEther
    ) internal returns (uint256, uint256) {
        _validateInputs(matrixToken, wrappedToken, wrappedTokenUnits);

        (uint256 preActionUnderlyingNotional, uint256 preActionWrapNotional) = _snapshotTargetAssetsBalance(matrixToken, underlyingToken, wrappedToken);
        uint256 notionalWrappedToken = PositionUtil.getDefaultTotalNotional(matrixToken.totalSupply(), wrappedTokenUnits);

        IWrapV2Adapter wrapAdapter = IWrapV2Adapter(getAndValidateAdapter(integrationName));

        // Approve wrapped token for spending in case protocols require approvals to transfer wrapped tokens
        matrixToken.invokeSafeApprove(wrappedToken, wrapAdapter.getSpenderAddress(underlyingToken, wrappedToken), notionalWrappedToken);

        // Get function call data and invoke on MatrixToken
        _createUnwrapDataAndInvoke(
            matrixToken,
            wrapAdapter,
            usesEther ? wrapAdapter.ETH_TOKEN_ADDRESS() : underlyingToken,
            wrappedToken,
            notionalWrappedToken,
            unwrapData
        );

        if (usesEther) {
            matrixToken.invokeWrapWETH(_weth, address(matrixToken).balance);
        }

        (uint256 postActionUnderlyingNotional, uint256 postActionWrapNotional) = _snapshotTargetAssetsBalance(matrixToken, underlyingToken, wrappedToken);

        _updatePosition(matrixToken, underlyingToken, preActionUnderlyingNotional, postActionUnderlyingNotional);
        _updatePosition(matrixToken, wrappedToken, preActionWrapNotional, postActionWrapNotional);

        return (postActionUnderlyingNotional - preActionUnderlyingNotional, preActionWrapNotional - postActionWrapNotional);
    }

    /**
     * @dev Create the calldata for wrap and then invoke the call on the MatrixToken.
     */
    function _createWrapDataAndInvoke(
        IMatrixToken matrixToken,
        IWrapV2Adapter _wrapAdapter,
        address underlyingToken,
        address wrappedToken,
        uint256 notionalUnderlying,
        bytes memory wrapData
    ) internal {
        (address callTarget, uint256 callValue, bytes memory callByteData) = _wrapAdapter.getWrapCallData(
            underlyingToken,
            wrappedToken,
            notionalUnderlying,
            address(matrixToken),
            wrapData
        );

        matrixToken.invoke(callTarget, callValue, callByteData);
    }

    /**
     * @dev Create the calldata for unwrap and then invoke the call on the MatrixToken.
     */
    function _createUnwrapDataAndInvoke(
        IMatrixToken matrixToken,
        IWrapV2Adapter _wrapAdapter,
        address underlyingToken,
        address wrappedToken,
        uint256 notionalUnderlying,
        bytes memory unwrapData
    ) internal {
        (address callTarget, uint256 callValue, bytes memory callByteData) = _wrapAdapter.getUnwrapCallData(
            underlyingToken,
            wrappedToken,
            notionalUnderlying,
            address(matrixToken),
            unwrapData
        );

        matrixToken.invoke(callTarget, callValue, callByteData);
    }

    /**
     * @dev After a wrap/unwrap operation, check the underlying and wrap token quantities and recalculate the units:
     * (total_tokens - airdrop) / total_supply
     * Then update the position on the MatrixToken.
     */
    function _updatePosition(
        IMatrixToken matrixToken,
        address token,
        uint256 preActionTokenBalance,
        uint256 postActionTokenBalance
    ) internal {
        uint256 newUnit = PositionUtil.calculateDefaultEditPositionUnit(
            matrixToken.totalSupply(),
            preActionTokenBalance,
            postActionTokenBalance,
            matrixToken.getDefaultPositionRealUnit(token).toUint256()
        );

        matrixToken.editDefaultPosition(token, newUnit);
    }

    /**
     * @dev Take snapshot of MatrixToken's balance of underlying and wrapped tokens.
     */
    function _snapshotTargetAssetsBalance(
        IMatrixToken matrixToken,
        address underlyingToken,
        address wrappedToken
    ) internal view returns (uint256, uint256) {
        uint256 underlyingTokenBalance = IERC20(underlyingToken).balanceOf(address(matrixToken));
        uint256 wrapTokenBalance = IERC20(wrappedToken).balanceOf(address(matrixToken));

        return (underlyingTokenBalance, wrapTokenBalance);
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
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeCast.sol)

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= type(int128).min && value <= type(int128).max, "SafeCast: value doesn't fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= type(int64).min && value <= type(int64).max, "SafeCast: value doesn't fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= type(int32).min && value <= type(int32).max, "SafeCast: value doesn't fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= type(int16).min && value <= type(int16).max, "SafeCast: value doesn't fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= type(int8).min && value <= type(int8).max, "SafeCast: value doesn't fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
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

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

// ==================== External Imports ====================

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";

// ==================== Internal Imports ====================

import { ExactSafeErc20 } from "../../lib/ExactSafeErc20.sol";
import { PreciseUnitMath } from "../../lib/PreciseUnitMath.sol";
import { AddressArrayUtil } from "../../lib/AddressArrayUtil.sol";

import { IModule } from "../../interfaces/IModule.sol";
import { IController } from "../../interfaces/IController.sol";
import { IMatrixToken } from "../../interfaces/IMatrixToken.sol";

import { PositionUtil } from "./PositionUtil.sol";

/**
 * @title ModuleBase
 *
 * @dev Abstract class that houses common Module-related state and functions.
 */
abstract contract ModuleBase is IModule {
    using SafeCast for int256;
    using SafeCast for uint256;
    using ExactSafeErc20 for IERC20;
    using PreciseUnitMath for uint256;
    using AddressArrayUtil for address[];
    using PositionUtil for IMatrixToken;

    // ==================== Variables ====================

    IController internal immutable _controller;

    // ==================== Constructor function ====================

    constructor(IController controller) {
        _controller = controller;
    }

    // ==================== Modifier functions ====================

    modifier onlyManagerAndValidMatrix(IMatrixToken matrixToken) {
        _onlyManagerAndValidMatrix(matrixToken);
        _;
    }

    modifier onlyMatrixManager(IMatrixToken matrixToken, address caller) {
        _onlyMatrixManager(matrixToken, caller);
        _;
    }

    modifier onlyValidAndInitializedMatrix(IMatrixToken matrixToken) {
        _onlyValidAndInitializedMatrix(matrixToken);
        _;
    }

    modifier onlyModule(IMatrixToken matrixToken) {
        _onlyModule(matrixToken);
        _;
    }

    /**
     * @dev Utilized during module initializations to check that the module is in pending state and that the MatrixToken is valid.
     */
    modifier onlyValidAndPendingMatrix(IMatrixToken matrixToken) {
        _onlyValidAndPendingMatrix(matrixToken);
        _;
    }

    // ==================== External functions ====================

    function getController() external view returns (address) {
        return address(_controller);
    }

    // ==================== Internal functions ====================

    /**
     * @dev Transfers tokens from an address (that has set allowance on the module).
     *
     * @param token       The address of the ERC20 token
     * @param from        The address to transfer from
     * @param to          The address to transfer to
     * @param quantity    The number of tokens to transfer
     */
    function transferFrom(IERC20 token, address from, address to, uint256 quantity) internal {
        token.exactSafeTransferFrom(from, to, quantity);
    } // prettier-ignore

    /**
     * @dev Hashes the string and returns a bytes32 value.
     */
    function getNameHash(string memory name) internal pure returns (bytes32) {
        return keccak256(bytes(name));
    }

    /**
     * @return The integration for the module with the passed in name.
     */
    function getAndValidateAdapter(string memory integrationName) internal view returns (address) {
        bytes32 integrationHash = getNameHash(integrationName);
        return getAndValidateAdapterWithHash(integrationHash);
    }

    /**
     * @return The integration for the module with the passed in hash.
     */
    function getAndValidateAdapterWithHash(bytes32 integrationHash) internal view returns (address) {
        address adapter = _controller.getIntegrationRegistry().getIntegrationAdapterWithHash(address(this), integrationHash);

        require(adapter != address(0), "M0"); // "Must be valid adapter"

        return adapter;
    }

    /**
     * @return The total fee for this module of the passed in index (fee % * quantity).
     */
    function getModuleFee(uint256 feeIndex, uint256 quantity) internal view returns (uint256) {
        uint256 feePercentage = _controller.getModuleFee(address(this), feeIndex);
        return quantity.preciseMul(feePercentage);
    }

    /**
     * @dev Pays the feeQuantity from the matrixToken denominated in token to the protocol fee recipient.
     */
    function payProtocolFeeFromMatrixToken(IMatrixToken matrixToken, address token, uint256 feeQuantity) internal {
        if (feeQuantity > 0) {
            matrixToken.invokeExactSafeTransfer(token, _controller.getFeeRecipient(), feeQuantity);
        }
    } // prettier-ignore

    /**
     * @return Whether the module is in process of initialization on the MatrixToken.
     */
    function isMatrixPendingInitialization(IMatrixToken matrixToken) internal view returns (bool) {
        return matrixToken.isPendingModule(address(this));
    }

    /**
     * @return Whether the address is the MatrixToken's manager.
     */
    function isMatrixManager(IMatrixToken matrixToken, address addr) internal view returns (bool) {
        return matrixToken.getManager() == addr;
    }

    /**
     * @return Whether MatrixToken must be enabled on the controller and module is registered on the MatrixToken.
     */
    function isMatrixValidAndInitialized(IMatrixToken matrixToken) internal view returns (bool) {
        return _controller.isMatrix(address(matrixToken)) && matrixToken.isInitializedModule(address(this));
    }

    // ==================== Private functions ====================

    /**
     * @notice Caller must be MatrixToken manager and MatrixToken must be valid and initialized.
     */
    function _onlyManagerAndValidMatrix(IMatrixToken matrixToken) private view {
        require(isMatrixManager(matrixToken, msg.sender), "M1a"); // "Must be the MatrixToken manager"
        require(isMatrixValidAndInitialized(matrixToken), "M1b"); // "Must be a valid and initialized MatrixToken"
    }

    /**
     * @notice Caller must be MatrixToken manager.
     */
    function _onlyMatrixManager(IMatrixToken matrixToken, address caller) private view {
        require(isMatrixManager(matrixToken, caller), "M2"); // "Must be the MatrixToken manager"
    }

    /**
     * @notice MatrixToken must be valid and initialized.
     */
    function _onlyValidAndInitializedMatrix(IMatrixToken matrixToken) private view {
        require(isMatrixValidAndInitialized(matrixToken), "M3"); // "Must be a valid and initialized MatrixToken"
    }

    /**
     * @notice Caller must be initialized module and module must be enabled on the controller.
     */
    function _onlyModule(IMatrixToken matrixToken) private view {
        require(matrixToken.getModuleState(msg.sender) == IMatrixToken.ModuleState.INITIALIZED, "M4a"); // "Only the module can call"
        require(_controller.isModule(msg.sender), "M4b"); // "Module must be enabled on controller"
    }

    /**
     * @dev MatrixToken must be in a pending state and module must be in pending state.
     */
    function _onlyValidAndPendingMatrix(IMatrixToken matrixToken) private view {
        require(_controller.isMatrix(address(matrixToken)), "M5a"); // "Must be controller-enabled MatrixToken"
        require(isMatrixPendingInitialization(matrixToken), "M5b"); // "Must be pending initialization"
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

// ==================== External Imports ====================

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";

// ==================== Internal Imports ====================

import { PreciseUnitMath } from "../../lib/PreciseUnitMath.sol";
import { IMatrixToken } from "../../interfaces/IMatrixToken.sol";

/**
 * @title PositionUtil
 *
 * @dev Collection of helper functions for handling and updating MatrixToken Positions.
 */
library PositionUtil {
    using SafeCast for uint256;
    using SafeCast for int256;
    using PreciseUnitMath for uint256;

    // ==================== Internal functions ====================

    /**
     * @return Whether the MatrixToken has a default position for a given component (if the real unit is > 0)
     */
    function hasDefaultPosition(IMatrixToken matrixToken, address component) internal view returns (bool) {
        return matrixToken.getDefaultPositionRealUnit(component) > 0;
    }

    /**
     * @return Whether the MatrixToken has an external position for a given component (if # of position modules is > 0)
     */
    function hasExternalPosition(IMatrixToken matrixToken, address component) internal view returns (bool) {
        return matrixToken.getExternalPositionModules(component).length > 0;
    }

    /**
     * @return Whether the MatrixToken component default position real unit is greater than or equal to units passed in.
     */
    function hasSufficientDefaultUnits(
        IMatrixToken matrixToken,
        address component,
        uint256 unit
    ) internal view returns (bool) {
        return matrixToken.getDefaultPositionRealUnit(component) >= unit.toInt256();
    }

    /**
     * @return Whether the MatrixToken component external position is greater than or equal to the real units passed in.
     */
    function hasSufficientExternalUnits(
        IMatrixToken matrixToken,
        address component,
        address positionModule,
        uint256 unit
    ) internal view returns (bool) {
        return matrixToken.getExternalPositionRealUnit(component, positionModule) >= unit.toInt256();
    }

    /**
     * @dev If the position does not exist, create a new Position and add to the MatrixToken. If it already exists,
     * then set the position units. If the new units is 0, remove the position. Handles adding/removing of
     * components where needed (in light of potential external positions).
     *
     * @param matrixToken    Address of MatrixToken being modified
     * @param component      Address of the component
     * @param newUnit        Quantity of Position units - must be >= 0
     */
    function editDefaultPosition(
        IMatrixToken matrixToken,
        address component,
        uint256 newUnit
    ) internal {
        bool isPositionFound = hasDefaultPosition(matrixToken, component);
        if (!isPositionFound && newUnit > 0) {
            // If there is no Default Position and no External Modules, then component does not exist
            if (!hasExternalPosition(matrixToken, component)) {
                matrixToken.addComponent(component);
            }
        } else if (isPositionFound && newUnit == 0) {
            // If there is a Default Position and no external positions, remove the component
            if (!hasExternalPosition(matrixToken, component)) {
                matrixToken.removeComponent(component);
            }
        }

        matrixToken.editDefaultPositionUnit(component, newUnit.toInt256());
    }

    /**
     * @dev Update an external position and remove and external positions or components if necessary. The logic flows as follows:
     * 1) If component is not already added then add component and external position.
     * 2) If component is added but no existing external position using the passed module exists then add the external position.
     * 3) If the existing position is being added to then just update the unit and data
     * 4) If the position is being closed and no other external positions or default positions are associated with the component then untrack the component and remove external position.
     * 5) If the position is being closed and other existing positions still exist for the component then just remove the external position.
     *
     * @param matrixToken    MatrixToken being updated
     * @param component      Component position being updated
     * @param module         Module external position is associated with
     * @param newUnit        Position units of new external position
     * @param data           Arbitrary data associated with the position
     */
    function editExternalPosition(
        IMatrixToken matrixToken,
        address component,
        address module,
        int256 newUnit,
        bytes memory data
    ) internal {
        if (newUnit != 0) {
            if (!matrixToken.isComponent(component)) {
                matrixToken.addComponent(component);
                matrixToken.addExternalPositionModule(component, module);
            } else if (!matrixToken.isExternalPositionModule(component, module)) {
                matrixToken.addExternalPositionModule(component, module);
            }

            matrixToken.editExternalPositionUnit(component, module, newUnit);
            matrixToken.editExternalPositionData(component, module, data);
        } else {
            require(data.length == 0, "P0a"); // "Passed data must be null"

            // If no default or external position remaining then remove component from components array
            if (matrixToken.getExternalPositionRealUnit(component, module) != 0) {
                address[] memory positionModules = matrixToken.getExternalPositionModules(component);

                if (matrixToken.getDefaultPositionRealUnit(component) == 0 && positionModules.length == 1) {
                    require(positionModules[0] == module, "P0b"); // "External positions must be 0 to remove component")
                    matrixToken.removeComponent(component);
                }

                matrixToken.removeExternalPositionModule(component, module);
            }
        }
    }

    /**
     * @dev Get total notional amount of Default position
     *
     * @param matrixTokenSupply    Supply of MatrixToken in precise units (10^18)
     * @param positionUnit         Quantity of Position units
     *
     * @return uint256             Total notional amount of units
     */
    function getDefaultTotalNotional(uint256 matrixTokenSupply, uint256 positionUnit) internal pure returns (uint256) {
        return matrixTokenSupply.preciseMul(positionUnit);
    }

    /**
     * @dev Get position unit from total notional amount
     *
     * @param matrixTokenSupply    Supply of MatrixToken in precise units (10^18)
     * @param totalNotional        Total notional amount of component prior to
     *
     * @return uint256             Default position unit
     */
    function getDefaultPositionUnit(uint256 matrixTokenSupply, uint256 totalNotional) internal pure returns (uint256) {
        return totalNotional.preciseDiv(matrixTokenSupply);
    }

    /**
     * @dev Get the total tracked balance - total supply * position unit
     *
     * @param matrixToken    Address of the MatrixToken
     * @param component      Address of the component
     *
     * @return uint256       Notional tracked balance
     */
    function getDefaultTrackedBalance(IMatrixToken matrixToken, address component) internal view returns (uint256) {
        int256 positionUnit = matrixToken.getDefaultPositionRealUnit(component);

        return matrixToken.totalSupply().preciseMul(positionUnit.toUint256());
    }

    /**
     * @dev Calculates the new default position unit and performs the edit with the new unit
     *
     * @param matrixToken                 Address of the MatrixToken
     * @param component                   Address of the component
     * @param matrixTotalSupply           Current MatrixToken supply
     * @param componentPreviousBalance    Pre-action component balance
     *
     * @return uint256                    Current component balance
     * @return uint256                    Previous position unit
     * @return uint256                    New position unit
     */
    function calculateAndEditDefaultPosition(
        IMatrixToken matrixToken,
        address component,
        uint256 matrixTotalSupply,
        uint256 componentPreviousBalance
    )
        internal
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 currentBalance = IERC20(component).balanceOf(address(matrixToken));
        uint256 positionUnit = matrixToken.getDefaultPositionRealUnit(component).toUint256();

        uint256 newTokenUnit;
        if (currentBalance > 0) {
            newTokenUnit = calculateDefaultEditPositionUnit(matrixTotalSupply, componentPreviousBalance, currentBalance, positionUnit);
        } else {
            newTokenUnit = 0;
        }

        editDefaultPosition(matrixToken, component, newTokenUnit);

        return (currentBalance, positionUnit, newTokenUnit);
    }

    /**
     * @dev Calculate the new position unit given total notional values pre and post executing an action that changes MatrixToken state.
     * The intention is to make updates to the units without accidentally picking up airdropped assets as well.
     *
     * @param matrixTokenSupply    Supply of MatrixToken in precise units (10^18)
     * @param preTotalNotional     Total notional amount of component prior to executing action
     * @param postTotalNotional    Total notional amount of component after the executing action
     * @param prePositionUnit      Position unit of MatrixToken prior to executing action
     *
     * @return uint256             New position unit
     */
    function calculateDefaultEditPositionUnit(
        uint256 matrixTokenSupply,
        uint256 preTotalNotional,
        uint256 postTotalNotional,
        uint256 prePositionUnit
    ) internal pure returns (uint256) {
        // If pre action total notional amount is greater then subtract post action total notional and calculate new position units
        uint256 airdroppedAmount = preTotalNotional - prePositionUnit.preciseMul(matrixTokenSupply);

        return (postTotalNotional - airdroppedAmount).preciseDiv(matrixTokenSupply);
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

// ==================== Internal Imports ====================

import { IPriceOracle } from "../interfaces/IPriceOracle.sol";
import { IMatrixValuer } from "../interfaces/IMatrixValuer.sol";
import { IIntegrationRegistry } from "../interfaces/IIntegrationRegistry.sol";

/**
 * @title IController
 */
interface IController {
    // ==================== Events ====================

    event AddFactory(address indexed factory);
    event RemoveFactory(address indexed factory);
    event AddFee(address indexed module, uint256 indexed feeType, uint256 feePercentage);
    event EditFee(address indexed module, uint256 indexed feeType, uint256 feePercentage);
    event EditFeeRecipient(address newFeeRecipient);
    event AddModule(address indexed module);
    event RemoveModule(address indexed module);
    event AddResource(address indexed resource, uint256 id);
    event RemoveResource(address indexed resource, uint256 id);
    event AddMatrix(address indexed matrixToken, address indexed factory);
    event RemoveMatrix(address indexed matrixToken);

    // ==================== External functions ====================

    function isMatrix(address matrixToken) external view returns (bool);

    function isFactory(address addr) external view returns (bool);

    function isModule(address addr) external view returns (bool);

    function isResource(address addr) external view returns (bool);

    function isSystemContract(address contractAddress) external view returns (bool);

    function getFeeRecipient() external view returns (address);

    function getModuleFee(address module, uint256 feeType) external view returns (uint256);

    function getFactories() external view returns (address[] memory);

    function getModules() external view returns (address[] memory);

    function getResources() external view returns (address[] memory);

    function getResource(uint256 id) external view returns (address);

    function getMatrixs() external view returns (address[] memory);

    function getIntegrationRegistry() external view returns (IIntegrationRegistry);

    function getPriceOracle() external view returns (IPriceOracle);

    function getMatrixValuer() external view returns (IMatrixValuer);

    function initialize(
        address[] memory factories,
        address[] memory modules,
        address[] memory resources,
        uint256[] memory resourceIds
    ) external;

    function addMatrix(address matrixToken) external;

    function removeMatrix(address matrixToken) external;

    function addFactory(address factory) external;

    function removeFactory(address factory) external;

    function addModule(address module) external;

    function removeModule(address module) external;

    function addResource(address resource, uint256 id) external;

    function removeResource(uint256 id) external;

    function addFee(
        address module,
        uint256 feeType,
        uint256 newFeePercentage
    ) external;

    function editFee(
        address module,
        uint256 feeType,
        uint256 newFeePercentage
    ) external;

    function editFeeRecipient(address newFeeRecipient) external;
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

/**
 * @title IWrapAdapter
 */
interface IWrapAdapter {
    // ==================== External functions ====================

    function ETH_TOKEN_ADDRESS() external view returns (address);

    function getWrapCallData(address underlyingToken, address wrappedToken, uint256 underlyingUnits)
        external view returns (address subject, uint256 value, bytes memory callData); // prettier-ignore

    function getUnwrapCallData(address underlyingToken, address wrappedToken, uint256 wrappedTokenUnits)
        external view returns (address subject, uint256 value, bytes memory callData); // prettier-ignore

    function getSpenderAddress(address underlyingToken, address wrappedToken) external view returns (address);
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

// ==================== External Imports ====================

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title IMatrixToken
 *
 * @dev Interface for operating with MatrixToken.
 */
interface IMatrixToken is IERC20 {
    // ==================== Enums ====================

    enum ModuleState {
        NONE,
        PENDING,
        INITIALIZED
    }

    // ==================== Structs ====================

    /**
     * @dev The base definition of a MatrixToken Position.
     *
     * @param unit             Each unit is the # of components per 10^18 of a MatrixToken
     * @param module           If not in default state, the address of associated module
     * @param component        Address of token in the Position
     * @param positionState    Position ENUM. Default is 0; External is 1
     * @param data             Arbitrary data
     */
    struct Position {
        int256 unit;
        address module;
        address component;
        uint8 positionState;
        bytes data;
    }

    /**
     * @dev A struct that stores a component's external position details including virtual unit and any auxiliary data.
     *
     * @param virtualUnit       Virtual value of a component's EXTERNAL position.
     * @param data              Arbitrary data
     */
    struct ExternalPosition {
        int256 virtualUnit;
        bytes data;
    }

    /**
     * @dev A struct that stores a component's cash position details and external positions
     * This data structure allows O(1) access to a component's cash position units and virtual units.
     *
     * @param virtualUnit               Virtual value of a component's DEFAULT position. Stored as virtual for efficiency updating all units at once
                                            via the positionMultiplier. Virtual units are achieved by dividing a "real" value by the "positionMultiplier"
     * @param externalPositionModules   External modules attached to each external position. Each module maps to an external position
     * @param externalPositions         Mapping of module => ExternalPosition struct for a given component
     */
    struct ComponentPosition {
        int256 virtualUnit;
        address[] externalPositionModules;
        mapping(address => ExternalPosition) externalPositions;
    }

    // ==================== Events ====================

    event Invoke(address indexed target, uint256 indexed value, bytes data, bytes returnValue);
    event AddModule(address indexed module);
    event RemoveModule(address indexed module);
    event InitializeModule(address indexed module);
    event EditManager(address newManager, address oldManager);
    event RemovePendingModule(address indexed module);
    event EditPositionMultiplier(int256 newMultiplier);
    event AddComponent(address indexed component);
    event RemoveComponent(address indexed component);
    event EditDefaultPositionUnit(address indexed component, int256 realUnit);
    event EditExternalPositionUnit(address indexed component, address indexed positionModule, int256 realUnit);
    event EditExternalPositionData(address indexed component, address indexed positionModule, bytes data);
    event AddPositionModule(address indexed component, address indexed positionModule);
    event RemovePositionModule(address indexed component, address indexed positionModule);

    // ==================== External functions ====================

    function getController() external view returns (address);

    function getManager() external view returns (address);

    function getLocker() external view returns (address);

    function getComponents() external view returns (address[] memory);

    function getModules() external view returns (address[] memory);

    function getModuleState(address module) external view returns (ModuleState);

    function getPositionMultiplier() external view returns (int256);

    function getPositions() external view returns (Position[] memory);

    function getTotalComponentRealUnits(address component) external view returns (int256);

    function getDefaultPositionRealUnit(address component) external view returns (int256);

    function getExternalPositionRealUnit(address component, address positionModule) external view returns (int256);

    function getExternalPositionModules(address component) external view returns (address[] memory);

    function getExternalPositionData(address component, address positionModule) external view returns (bytes memory);

    function isExternalPositionModule(address component, address module) external view returns (bool);

    function isComponent(address component) external view returns (bool);

    function isInitializedModule(address module) external view returns (bool);

    function isPendingModule(address module) external view returns (bool);

    function isLocked() external view returns (bool);

    function setManager(address manager) external;

    function addComponent(address component) external;

    function removeComponent(address component) external;

    function editDefaultPositionUnit(address component, int256 realUnit) external;

    function addExternalPositionModule(address component, address positionModule) external;

    function removeExternalPositionModule(address component, address positionModule) external;

    function editExternalPositionUnit(address component, address positionModule, int256 realUnit) external; // prettier-ignore

    function editExternalPositionData(address component, address positionModule, bytes calldata data) external; // prettier-ignore

    function invoke(address target, uint256 value, bytes calldata data) external returns (bytes memory); // prettier-ignore

    function invokeSafeApprove(address token, address spender, uint256 amount) external; // prettier-ignore

    function invokeSafeTransfer(address token, address to, uint256 amount) external; // prettier-ignore

    function invokeExactSafeTransfer(address token, address to, uint256 amount) external; // prettier-ignore

    function invokeWrapWETH(address weth, uint256 amount) external;

    function invokeUnwrapWETH(address weth, uint256 amount) external;

    function editPositionMultiplier(int256 newMultiplier) external;

    function mint(address account, uint256 quantity) external;

    function burn(address account, uint256 quantity) external;

    function lock() external;

    function unlock() external;

    function addModule(address module) external;

    function removeModule(address module) external;

    function initializeModule() external;
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

/**
 * @title IWrapV2Adapter
 */
interface IWrapV2Adapter {
    // ==================== External functions ====================

    function ETH_TOKEN_ADDRESS() external view returns (address);

    function getWrapCallData( address underlyingToken, address wrappedToken, uint256 underlyingUnits, address to, bytes memory wrapData)
        external view returns (address subject, uint256 value, bytes memory callData); // prettier-ignore

    function getUnwrapCallData(address underlyingToken, address wrappedToken, uint256 wrappedTokenUnits, address to, bytes memory unwrapData)
        external view returns (address subject, uint256 value, bytes memory callData); // prettier-ignore

    function getSpenderAddress(address underlyingToken, address wrappedToken) external view returns (address);
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

// ==================== External Imports ====================

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title ExactSafeErc20
 *
 * @dev Utility functions for ERC20 transfers that require the explicit amount to be transferred.
 */
library ExactSafeErc20 {
    using SafeERC20 for IERC20;

    // ==================== Internal functions ====================

    /**
     * @dev This function checks transfer fees, ensure the recipient received the correct amount.
     *
     * @param token     ERC20 token to approve
     * @param to        The account of recipient
     * @param amount    The quantity to transfer
     */
    function exactSafeTransfer(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        if (amount > 0) {
            uint256 oldBalance = token.balanceOf(to);
            token.safeTransfer(to, amount);
            uint256 newBalance = token.balanceOf(to);
            require(newBalance == oldBalance + amount, "ES0"); // "Invalid post transfer balance"
        }
    }

    /**
     * @dev This function checks transfer fees, ensure the recipient received the correct amount.
     *
     * @param token     ERC20 token to approve
     * @param from      The account of sender
     * @param to        The account of recipient
     * @param amount    The quantity to transfer
     */
    function exactSafeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        if (amount > 0) {
            uint256 oldBalance = token.balanceOf(to);
            token.safeTransferFrom(from, to, amount);
            uint256 newBalance = token.balanceOf(to);
            require(newBalance == oldBalance + amount, "ES1"); // "Invalid post transfer balance"
        }
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

/**
 * @title PreciseUnitMath
 */
library PreciseUnitMath {
    // ==================== Constants ====================

    uint256 internal constant PRECISE_UNIT = 10**18;
    int256 internal constant PRECISE_UNIT_INT = 10**18;

    uint256 internal constant MAX_UINT_256 = type(uint256).max;

    int256 internal constant MAX_INT_256 = type(int256).max;
    int256 internal constant MIN_INT_256 = type(int256).min;

    // ==================== Internal functions ====================

    function preciseUnit() internal pure returns (uint256) {
        return PRECISE_UNIT;
    }

    function preciseUnitInt() internal pure returns (int256) {
        return PRECISE_UNIT_INT;
    }

    function maxUint256() internal pure returns (uint256) {
        return MAX_UINT_256;
    }

    function maxInt256() internal pure returns (int256) {
        return MAX_INT_256;
    }

    function minInt256() internal pure returns (int256) {
        return MIN_INT_256;
    }

    function preciseMul(uint256 a, uint256 b) internal pure returns (uint256) {
        return (a * b) / PRECISE_UNIT;
    }

    function preciseMul(int256 a, int256 b) internal pure returns (int256) {
        return (a * b) / PRECISE_UNIT_INT;
    }

    /**
     * @dev rounded up
     */
    function preciseMulCeil(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 product = a * b;
        return (product == 0) ? 0 : ((product - 1) / PRECISE_UNIT + 1);
    }

    /**
     * @dev rounded down
     */
    function preciseDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "PM0");

        return (a * PRECISE_UNIT) / b;
    }

    /**
     * @dev rounded towards 0
     */
    function preciseDiv(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0, "PM1");

        return (a * PRECISE_UNIT_INT) / b;
    }

    /**
     * @dev rounded up or away from 0
     */
    function preciseDivCeil(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "PM2");

        return a > 0 ? ((a * PRECISE_UNIT - 1) / b + 1) : 0;
    }

    /**
     * @dev rounded up or away from 0
     */
    function preciseDivCeil(int256 a, int256 b) internal pure returns (int256 result) {
        require(b != 0, "PM3");

        a *= PRECISE_UNIT_INT;
        result = a / b;

        if (a % b != 0) {
            (a ^ b >= 0) ? ++result : --result;
        }
    }

    /**
     * @dev rounding towards the lesser number, positive values rounded towards zero, negative values rounded away from 0
     */
    function preciseMulFloor(int256 a, int256 b) internal pure returns (int256 result) {
        int256 product = a * b;
        result = product / PRECISE_UNIT_INT;

        if ((product < 0) && (product % PRECISE_UNIT_INT != 0)) {
            --result;
        }
    }

    /**
     * @dev rounding towards the lesser number, positive values rounded towards zero, negative values rounded away from 0
     */
    function preciseDivFloor(int256 a, int256 b) internal pure returns (int256 result) {
        require(b != 0, "PM4");

        int256 numerator = a * PRECISE_UNIT_INT;
        result = numerator / b; // not check overflow: numerator == MIN_INT_256 && b == -1

        if ((numerator ^ b < 0) && (numerator % b != 0)) {
            --result;
        }
    }

    /**
     * @dev Returns if a =~ b within range
     */
    function approximatelyEquals(
        uint256 a,
        uint256 b,
        uint256 range
    ) internal pure returns (bool) {
        if (a >= b) {
            return a - b <= range;
        } else {
            return b - a <= range;
        }
    }

    function abs(int256 n) internal pure returns (uint256) {
        unchecked {
            return uint256(n >= 0 ? n : -n);
        }
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

/**
 * @title AddressArrayUtil
 */
library AddressArrayUtil {
    // ==================== Internal functions ====================

    function hasDuplicate(address[] memory array) internal pure returns (bool) {
        if (array.length > 1) {
            uint256 lastIndex = array.length - 1;
            for (uint256 i = 0; i < lastIndex; i++) {
                address value = array[i];
                for (uint256 j = i + 1; j < array.length; j++) {
                    if (value == array[j]) {
                        return true;
                    }
                }
            }
        }

        return false;
    }

    function indexOf(address[] memory array, address value) internal pure returns (uint256 index, bool found) {
        for (uint256 i = 0; i < array.length; i++) {
            if (array[i] == value) {
                return (i, true);
            }
        }

        return (type(uint256).max, false);
    }

    function contain(address[] memory array, address value) internal pure returns (bool) {
        (, bool found) = indexOf(array, value);
        return found;
    }

    function removeValue(address[] memory array, address value) internal pure returns (address[] memory) {
        (uint256 index, bool found) = indexOf(array, value);
        require(found, "A0");

        address[] memory result = new address[](array.length - 1);
        for (uint256 i = 0; i < index; i++) {
            result[i] = array[i];
        }

        for (uint256 i = index + 1; i < array.length; i++) {
            result[index] = array[i];
            index = i;
        }

        return result;
    }

    function removeItem(address[] storage array, address item) internal {
        (uint256 index, bool found) = indexOf(array, item);
        require(found, "A1");

        for (uint256 right = index + 1; right < array.length; right++) {
            array[index] = array[right];
            index = right;
        }

        array.pop();
    }

    function quickRemoveItem(address[] storage array, address item) internal {
        (uint256 index, bool found) = indexOf(array, item);
        require(found, "A2");

        array[index] = array[array.length - 1]; // to save gas we not check index == array.length - 1
        array.pop();
    }

    function merge(address[] memory array1, address[] memory array2) internal pure returns (address[] memory) {
        address[] memory result = new address[](array1.length + array2.length);
        for (uint256 i = 0; i < array1.length; i++) {
            result[i] = array1[i];
        }

        uint256 index = array1.length;
        for (uint256 j = 0; j < array2.length; j++) {
            result[index++] = array2[j];
        }

        return result;
    }

    function validateArrayPairs(address[] memory array1, uint256[] memory array2) internal pure {
        require(array1.length == array2.length, "A3");
        _validateLengthAndUniqueness(array1);
    }

    function validateArrayPairs(address[] memory array1, bool[] memory array2) internal pure {
        require(array1.length == array2.length, "A4");
        _validateLengthAndUniqueness(array1);
    }

    function validateArrayPairs(address[] memory array1, string[] memory array2) internal pure {
        require(array1.length == array2.length, "A5");
        _validateLengthAndUniqueness(array1);
    }

    function validateArrayPairs(address[] memory array1, address[] memory array2) internal pure {
        require(array1.length == array2.length, "A6");
        _validateLengthAndUniqueness(array1);
    }

    function validateArrayPairs(address[] memory array1, bytes[] memory array2) internal pure {
        require(array1.length == array2.length, "A7");
        _validateLengthAndUniqueness(array1);
    }

    function _validateLengthAndUniqueness(address[] memory array) internal pure {
        require(array.length > 0, "A8a");
        require(!hasDuplicate(array), "A8b");
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

/**
 * @title IModule
 */
interface IModule {
    // ==================== External functions ====================

    /**
     * @dev Called by a MatrixToken to notify that this module was removed.
     * Any logic can be included in case checks need to be made or state needs to be cleared.
     */
    function removeModule() external;
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

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

/**
 * @title IPriceOracle
 */
interface IPriceOracle {
    // ==================== Events ====================

    event AddPair(address indexed asset1, address indexed asset2, address indexed oracle);
    event RemovePair(address indexed asset1, address indexed asset2, address indexed oracle);
    event EditPair(address indexed asset1, address indexed asset2, address indexed newOracle);
    event AddAdapter(address indexed adapter);
    event RemoveAdapter(address indexed adapter);
    event EditMasterQuoteAsset(address indexed newMasterQuote);
    event EditSecondQuoteAsset(address indexed newSecondQuote);

    // ==================== External functions ====================

    function getController() external view returns (address);

    function getOracle(address asset1, address asset2) external view returns (address);

    function getMasterQuoteAsset() external view returns (address);

    function getSecondQuoteAsset() external view returns (address);

    function getAdapters() external view returns (address[] memory);

    function getPrice(address asset1, address asset2) external view returns (uint256);

    function addPair(
        address asset1,
        address asset2,
        address oracle
    ) external;

    function editPair(
        address asset1,
        address asset2,
        address oracle
    ) external;

    function removePair(address asset1, address asset2) external;

    function addAdapter(address adapter) external;

    function removeAdapter(address adapter) external;

    function editMasterQuoteAsset(address newMasterQuoteAsset) external;

    function editSecondQuoteAsset(address newSecondQuoteAsset) external;
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

import { IMatrixToken } from "../interfaces/IMatrixToken.sol";

/**
 * @title IMatrixValuer
 */
interface IMatrixValuer {
    // ==================== External functions ====================

    function calculateMatrixTokenValuation(IMatrixToken matrixToken, address quoteAsset) external view returns (uint256);
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

/*
 * @title IIntegrationRegistry
 */
interface IIntegrationRegistry {
    // ==================== Events ====================

    event AddIntegration(address indexed module, address indexed adapter, string integrationName);
    event RemoveIntegration(address indexed module, address indexed adapter, string integrationName);
    event EditIntegration(address indexed module, address newAdapter, string integrationName);

    // ==================== External functions ====================

    function getIntegrationAdapter(address module, string memory id) external view returns (address);

    function getIntegrationAdapterWithHash(address module, bytes32 id) external view returns (address);

    function isValidIntegration(address module, string memory id) external view returns (bool);

    function addIntegration(address module, string memory id, address wrapper) external; // prettier-ignore

    function batchAddIntegration(address[] memory modules, string[] memory names, address[] memory adapters) external; // prettier-ignore

    function editIntegration(address module, string memory name, address adapter) external; // prettier-ignore

    function batchEditIntegration(address[] memory modules, string[] memory names, address[] memory adapters) external; // prettier-ignore

    function removeIntegration(address module, string memory name) external;
}