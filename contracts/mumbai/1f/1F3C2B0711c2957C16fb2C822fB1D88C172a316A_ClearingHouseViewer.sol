// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.13;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Decimal } from "./utils/Decimal.sol";
import { SignedDecimal } from "./utils/SignedDecimal.sol";
import { MixedDecimal } from "./utils/MixedDecimal.sol";
import { IAmm } from "./interfaces/IAmm.sol";
import { IInsuranceFund } from "./interfaces/IInsuranceFund.sol";
import { ClearingHouse } from "./ClearingHouse.sol";

contract ClearingHouseViewer {
    using Decimal for Decimal.decimal;
    using SignedDecimal for SignedDecimal.signedDecimal;
    using MixedDecimal for SignedDecimal.signedDecimal;

    ClearingHouse public clearingHouse;

    //
    // FUNCTIONS
    //

    constructor(ClearingHouse _clearingHouse) {
        clearingHouse = _clearingHouse;
    }

    //
    // Public
    //

    /**
     * @notice get unrealized PnL
     * @param _amm IAmm address
     * @param _trader trader address
     * @param _pnlCalcOption ClearingHouse.PnlCalcOption, can be SPOT_PRICE or TWAP.
     * @return unrealized PnL in 18 digits
     */
    function getUnrealizedPnl(
        IAmm _amm,
        address _trader,
        ClearingHouse.PnlCalcOption _pnlCalcOption
    ) external view returns (SignedDecimal.signedDecimal memory) {
        (, SignedDecimal.signedDecimal memory unrealizedPnl) = (
            clearingHouse.getPositionNotionalAndUnrealizedPnl(_amm, _trader, _pnlCalcOption)
        );
        return unrealizedPnl;
    }

    /**
     * @notice get personal balance with funding payment
     * @param _quoteToken ERC20 token address
     * @param _trader trader address
     * @return margin personal balance with funding payment in 18 digits
     */
    function getPersonalBalanceWithFundingPayment(IERC20 _quoteToken, address _trader)
        external
        view
        returns (Decimal.decimal memory margin)
    {
        IInsuranceFund insuranceFund = clearingHouse.insuranceFund();
        IAmm[] memory amms = insuranceFund.getAllAmms();
        for (uint256 i = 0; i < amms.length; i++) {
            if (IAmm(amms[i]).quoteAsset() != _quoteToken) {
                continue;
            }
            Decimal.decimal memory posMargin = getPersonalPositionWithFundingPayment(
                amms[i],
                _trader
            ).margin;
            margin = margin.addD(posMargin);
        }
    }

    /**
     * @notice get personal position with funding payment
     * @param _amm IAmm address
     * @param _trader trader address
     * @return position ClearingHouse.Position struct
     */
    function getPersonalPositionWithFundingPayment(IAmm _amm, address _trader)
        public
        view
        returns (ClearingHouse.Position memory position)
    {
        position = clearingHouse.getPosition(_amm, _trader);
        SignedDecimal.signedDecimal memory marginWithFundingPayment = MixedDecimal
            .fromDecimal(position.margin)
            .addD(
                getFundingPayment(position, clearingHouse.getLatestCumulativePremiumFraction(_amm))
            );
        position.margin = marginWithFundingPayment.toInt() >= 0
            ? marginWithFundingPayment.abs()
            : Decimal.zero();
    }

    /**
     * @notice get personal margin ratio
     * @param _amm IAmm address
     * @param _trader trader address
     * @return personal margin ratio in 18 digits
     */
    function getMarginRatio(IAmm _amm, address _trader)
        external
        view
        returns (SignedDecimal.signedDecimal memory)
    {
        return clearingHouse.getMarginRatio(_amm, _trader);
    }

    //
    // PRIVATE
    //

    // negative means trader paid and vice versa
    function getFundingPayment(
        ClearingHouse.Position memory _position,
        SignedDecimal.signedDecimal memory _latestCumulativePremiumFraction
    ) private pure returns (SignedDecimal.signedDecimal memory) {
        return
            _position.size.toInt() == 0
                ? SignedDecimal.zero()
                : _latestCumulativePremiumFraction
                    .subD(_position.lastUpdatedCumulativePremiumFraction)
                    .mulD(_position.size)
                    .mulScalar(-1);
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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.13;

import { DecimalMath } from "./DecimalMath.sol";

library Decimal {
    using DecimalMath for uint256;

    struct decimal {
        uint256 d;
    }

    function zero() internal pure returns (decimal memory) {
        return decimal(0);
    }

    function one() internal pure returns (decimal memory) {
        return decimal(DecimalMath.unit(18));
    }

    function toUint(decimal memory x) internal pure returns (uint256) {
        return x.d;
    }

    function modD(decimal memory x, decimal memory y) internal pure returns (decimal memory) {
        return decimal((x.d * (DecimalMath.unit(18))) % y.d);
    }

    function cmp(decimal memory x, decimal memory y) internal pure returns (int8) {
        if (x.d > y.d) {
            return 1;
        } else if (x.d < y.d) {
            return -1;
        }
        return 0;
    }

    /// @dev add two decimals
    function addD(decimal memory x, decimal memory y) internal pure returns (decimal memory) {
        decimal memory t;
        t.d = x.d.addd(y.d);
        return t;
    }

    /// @dev subtract two decimals
    function subD(decimal memory x, decimal memory y) internal pure returns (decimal memory) {
        decimal memory t;
        t.d = x.d.subd(y.d);
        return t;
    }

    /// @dev multiple two decimals
    function mulD(decimal memory x, decimal memory y) internal pure returns (decimal memory) {
        decimal memory t;
        t.d = x.d.muld(y.d);
        return t;
    }

    /// @dev multiple a decimal by a uint256
    function mulScalar(decimal memory x, uint256 y) internal pure returns (decimal memory) {
        decimal memory t;
        t.d = x.d * y;
        return t;
    }

    /// @dev divide two decimals
    function divD(decimal memory x, decimal memory y) internal pure returns (decimal memory) {
        decimal memory t;
        t.d = x.d.divd(y.d);
        return t;
    }

    /// @dev divide a decimal by a uint256
    function divScalar(decimal memory x, uint256 y) internal pure returns (decimal memory) {
        decimal memory t;
        t.d = x.d / y;
        return t;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.13;

import { SignedDecimalMath } from "./SignedDecimalMath.sol";
import { Decimal } from "./Decimal.sol";

library SignedDecimal {
    using SignedDecimalMath for int256;

    struct signedDecimal {
        int256 d;
    }

    function zero() internal pure returns (signedDecimal memory) {
        return signedDecimal(0);
    }

    function toInt(signedDecimal memory x) internal pure returns (int256) {
        return x.d;
    }

    function isNegative(signedDecimal memory x) internal pure returns (bool) {
        if (x.d < 0) {
            return true;
        }
        return false;
    }

    function abs(signedDecimal memory x) internal pure returns (Decimal.decimal memory) {
        Decimal.decimal memory t;
        if (x.d < 0) {
            t.d = uint256(0 - x.d);
        } else {
            t.d = uint256(x.d);
        }
        return t;
    }

    /// @dev add two decimals
    function addD(signedDecimal memory x, signedDecimal memory y)
        internal
        pure
        returns (signedDecimal memory)
    {
        signedDecimal memory t;
        t.d = x.d.addd(y.d);
        return t;
    }

    /// @dev subtract two decimals
    function subD(signedDecimal memory x, signedDecimal memory y)
        internal
        pure
        returns (signedDecimal memory)
    {
        signedDecimal memory t;
        t.d = x.d.subd(y.d);
        return t;
    }

    /// @dev multiple two decimals
    function mulD(signedDecimal memory x, signedDecimal memory y)
        internal
        pure
        returns (signedDecimal memory)
    {
        signedDecimal memory t;
        t.d = x.d.muld(y.d);
        return t;
    }

    /// @dev multiple a signedDecimal by a int256
    function mulScalar(signedDecimal memory x, int256 y)
        internal
        pure
        returns (signedDecimal memory)
    {
        signedDecimal memory t;
        t.d = x.d * y;
        return t;
    }

    /// @dev divide two decimals
    function divD(signedDecimal memory x, signedDecimal memory y)
        internal
        pure
        returns (signedDecimal memory)
    {
        signedDecimal memory t;
        t.d = x.d.divd(y.d);
        return t;
    }

    /// @dev divide a signedDecimal by a int256
    function divScalar(signedDecimal memory x, int256 y)
        internal
        pure
        returns (signedDecimal memory)
    {
        signedDecimal memory t;
        t.d = x.d / y;
        return t;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.13;

import { Decimal } from "./Decimal.sol";
import { SignedDecimal } from "./SignedDecimal.sol";

/// @dev To handle a signedDecimal add/sub/mul/div a decimal and provide convert decimal to signedDecimal helper
library MixedDecimal {
    using SignedDecimal for SignedDecimal.signedDecimal;

    uint256 private constant _INT256_MAX = 2**255 - 1;
    string private constant ERROR_NON_CONVERTIBLE =
        "MixedDecimal: uint value is bigger than _INT256_MAX";

    modifier convertible(Decimal.decimal memory x) {
        require(_INT256_MAX >= x.d, ERROR_NON_CONVERTIBLE);
        _;
    }

    function fromDecimal(Decimal.decimal memory x)
        internal
        pure
        convertible(x)
        returns (SignedDecimal.signedDecimal memory)
    {
        return SignedDecimal.signedDecimal(int256(x.d));
    }

    function toUint(SignedDecimal.signedDecimal memory x) internal pure returns (uint256) {
        return x.abs().d;
    }

    /// @dev add SignedDecimal.signedDecimal and Decimal.decimal, using SignedSafeMath directly
    function addD(SignedDecimal.signedDecimal memory x, Decimal.decimal memory y)
        internal
        pure
        convertible(y)
        returns (SignedDecimal.signedDecimal memory)
    {
        SignedDecimal.signedDecimal memory t;
        t.d = x.d + int256(y.d);
        return t;
    }

    /// @dev subtract SignedDecimal.signedDecimal by Decimal.decimal, using SignedSafeMath directly
    function subD(SignedDecimal.signedDecimal memory x, Decimal.decimal memory y)
        internal
        pure
        convertible(y)
        returns (SignedDecimal.signedDecimal memory)
    {
        SignedDecimal.signedDecimal memory t;
        t.d = x.d - int256(y.d);
        return t;
    }

    /// @dev multiple a SignedDecimal.signedDecimal by Decimal.decimal
    function mulD(SignedDecimal.signedDecimal memory x, Decimal.decimal memory y)
        internal
        pure
        convertible(y)
        returns (SignedDecimal.signedDecimal memory)
    {
        SignedDecimal.signedDecimal memory t;
        t = x.mulD(fromDecimal(y));
        return t;
    }

    /// @dev multiple a SignedDecimal.signedDecimal by a uint256
    function mulScalar(SignedDecimal.signedDecimal memory x, uint256 y)
        internal
        pure
        returns (SignedDecimal.signedDecimal memory)
    {
        require(_INT256_MAX >= y, ERROR_NON_CONVERTIBLE);
        SignedDecimal.signedDecimal memory t;
        t = x.mulScalar(int256(y));
        return t;
    }

    /// @dev divide a SignedDecimal.signedDecimal by a Decimal.decimal
    function divD(SignedDecimal.signedDecimal memory x, Decimal.decimal memory y)
        internal
        pure
        convertible(y)
        returns (SignedDecimal.signedDecimal memory)
    {
        SignedDecimal.signedDecimal memory t;
        t = x.divD(fromDecimal(y));
        return t;
    }

    /// @dev divide a SignedDecimal.signedDecimal by a uint256
    function divScalar(SignedDecimal.signedDecimal memory x, uint256 y)
        internal
        pure
        returns (SignedDecimal.signedDecimal memory)
    {
        require(_INT256_MAX >= y, ERROR_NON_CONVERTIBLE);
        SignedDecimal.signedDecimal memory t;
        t = x.divScalar(int256(y));
        return t;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.13;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Decimal } from "../utils/Decimal.sol";
import { SignedDecimal } from "../utils/SignedDecimal.sol";

interface IAmm {
    /**
     * @notice asset direction, used in getInputPrice, getOutputPrice, swapInput and swapOutput
     * @param ADD_TO_AMM add asset to Amm
     * @param REMOVE_FROM_AMM remove asset from Amm
     */
    enum Dir {
        ADD_TO_AMM,
        REMOVE_FROM_AMM
    }

    function swapInput(
        Dir _dir,
        Decimal.decimal calldata _quoteAssetAmount,
        Decimal.decimal calldata _baseAssetAmountLimit,
        bool _canOverFluctuationLimit
    ) external returns (Decimal.decimal memory);

    function swapOutput(
        Dir _dir,
        Decimal.decimal calldata _baseAssetAmount,
        Decimal.decimal calldata _quoteAssetAmountLimit
    ) external returns (Decimal.decimal memory);

    function shutdown() external;

    function settleFunding() external returns (SignedDecimal.signedDecimal memory);

    function calcFee(Decimal.decimal calldata _quoteAssetAmount)
        external
        view
        returns (Decimal.decimal memory, Decimal.decimal memory);

    //
    // VIEW
    //

    function isOverFluctuationLimit(Dir _dirOfBase, Decimal.decimal memory _baseAssetAmount)
        external
        view
        returns (bool);

    function getInputTwap(Dir _dir, Decimal.decimal calldata _quoteAssetAmount)
        external
        view
        returns (Decimal.decimal memory);

    function getOutputTwap(Dir _dir, Decimal.decimal calldata _baseAssetAmount)
        external
        view
        returns (Decimal.decimal memory);

    function getInputPrice(Dir _dir, Decimal.decimal calldata _quoteAssetAmount)
        external
        view
        returns (Decimal.decimal memory);

    function getOutputPrice(Dir _dir, Decimal.decimal calldata _baseAssetAmount)
        external
        view
        returns (Decimal.decimal memory);

    function getInputPriceWithReserves(
        Dir _dir,
        Decimal.decimal memory _quoteAssetAmount,
        Decimal.decimal memory _quoteAssetPoolAmount,
        Decimal.decimal memory _baseAssetPoolAmount
    ) external pure returns (Decimal.decimal memory);

    function getOutputPriceWithReserves(
        Dir _dir,
        Decimal.decimal memory _baseAssetAmount,
        Decimal.decimal memory _quoteAssetPoolAmount,
        Decimal.decimal memory _baseAssetPoolAmount
    ) external pure returns (Decimal.decimal memory);

    function getSpotPrice() external view returns (Decimal.decimal memory);

    // overridden by state variable
    function quoteAsset() external view returns (IERC20);

    function open() external view returns (bool);

    function getBaseAssetDeltaThisFundingPeriod()
        external
        view
        returns (SignedDecimal.signedDecimal memory);

    function getCumulativeNotional() external view returns (SignedDecimal.signedDecimal memory);

    function getMaxHoldingBaseAsset() external view returns (Decimal.decimal memory);

    function getOpenInterestNotionalCap() external view returns (Decimal.decimal memory);

    function getBaseAssetDelta() external view returns (SignedDecimal.signedDecimal memory);

    function getUnderlyingPrice() external view returns (Decimal.decimal memory);

    function isOverSpreadLimit() external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.13;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Decimal } from "../utils/Decimal.sol";
import { IAmm } from "./IAmm.sol";

interface IInsuranceFund {
    function withdraw(IERC20 _quoteToken, Decimal.decimal calldata _amount) external;

    function isExistedAmm(IAmm _amm) external view returns (bool);

    function getAllAmms() external view returns (IAmm[] memory);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.13;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Decimal } from "./utils/Decimal.sol";
import { SignedDecimal } from "./utils/SignedDecimal.sol";
import { MixedDecimal } from "./utils/MixedDecimal.sol";
import { DecimalERC20 } from "./utils/DecimalERC20.sol";
// prettier-ignore
// solhint-disable-next-line
import { ReentrancyGuardUpgradeable } from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import { OwnerPausableUpgradeable } from "./OwnerPausable.sol";
import { IAmm } from "./interfaces/IAmm.sol";
import { IInsuranceFund } from "./interfaces/IInsuranceFund.sol";
import { TransferHelper } from "./utils/TransferHelper.sol";

contract ClearingHouse is TransferHelper, OwnerPausableUpgradeable, ReentrancyGuardUpgradeable {
    using Decimal for Decimal.decimal;
    using SignedDecimal for SignedDecimal.signedDecimal;
    using MixedDecimal for SignedDecimal.signedDecimal;

    //
    // EVENTS
    //
    event MarginRatioChanged(uint256 marginRatio);
    event LiquidationFeeRatioChanged(uint256 liquidationFeeRatio);
    event BackstopLiquidityProviderChanged(address indexed account, bool indexed isProvider);
    event MarginChanged(
        address indexed sender,
        address indexed amm,
        int256 amount,
        int256 fundingPayment
    );
    event RestrictionModeEntered(address amm, uint256 blockNumber);

    /// @notice This event is emitted when position change
    /// @param trader the address which execute this transaction
    /// @param amm IAmm address
    /// @param margin margin
    /// @param positionNotional margin * leverage
    /// @param exchangedPositionSize position size, e.g. ETHUSDC or LINKUSDC
    /// @param fee transaction fee
    /// @param positionSizeAfter position size after this transaction, might be increased or decreased
    /// @param realizedPnl realized pnl after this position changed
    /// @param unrealizedPnlAfter unrealized pnl after this position changed
    /// @param badDebt position change amount cleared by insurance funds
    /// @param liquidationPenalty amount of remaining margin lost due to liquidation
    /// @param spotPrice quote asset reserve / base asset reserve
    /// @param fundingPayment funding payment (+: trader paid, -: trader received)
    event PositionChanged(
        address indexed trader,
        address indexed amm,
        uint256 margin,
        uint256 positionNotional,
        int256 exchangedPositionSize,
        uint256 fee,
        int256 positionSizeAfter,
        int256 realizedPnl,
        int256 unrealizedPnlAfter,
        uint256 badDebt,
        uint256 liquidationPenalty,
        uint256 spotPrice,
        int256 fundingPayment
    );

    /// @notice This event is emitted when position liquidated
    /// @param trader the account address being liquidated
    /// @param amm IAmm address
    /// @param positionNotional liquidated position value minus liquidationFee
    /// @param positionSize liquidated position size
    /// @param liquidationFee liquidation fee to the liquidator
    /// @param liquidator the address which execute this transaction
    /// @param badDebt liquidation fee amount cleared by insurance funds
    event PositionLiquidated(
        address indexed trader,
        address indexed amm,
        uint256 positionNotional,
        uint256 positionSize,
        uint256 liquidationFee,
        address liquidator,
        uint256 badDebt
    );

    event ReferredPositionChanged(bytes32 indexed referralCode);

    //
    // Struct and Enum
    //

    enum Side {
        BUY,
        SELL
    }
    enum PnlCalcOption {
        SPOT_PRICE,
        TWAP,
        ORACLE
    }

    /// @param MAX_PNL most beneficial way for traders to calculate position notional
    /// @param MIN_PNL least beneficial way for traders to calculate position notional
    enum PnlPreferenceOption {
        MAX_PNL,
        MIN_PNL
    }

    /// @notice This struct records personal position information
    /// @param size denominated in amm.baseAsset
    /// @param margin isolated margin
    /// @param openNotional the quoteAsset value of position when opening position. the cost of the position
    /// @param lastUpdatedCumulativePremiumFraction for calculating funding payment, record at the moment every time when trader open/reduce/close position
    /// @param blockNumber the block number of the last position
    struct Position {
        SignedDecimal.signedDecimal size;
        Decimal.decimal margin;
        Decimal.decimal openNotional;
        SignedDecimal.signedDecimal lastUpdatedCumulativePremiumFraction;
        uint256 blockNumber;
    }

    /// @notice This struct is used for avoiding stack too deep error when passing too many var between functions
    struct PositionResp {
        Position position;
        // the quote asset amount trader will send if open position, will receive if close
        Decimal.decimal exchangedQuoteAssetAmount;
        // if realizedPnl + realizedFundingPayment + margin is negative, it's the abs value of it
        Decimal.decimal badDebt;
        // the base asset amount trader will receive if open position, will send if close
        SignedDecimal.signedDecimal exchangedPositionSize;
        // funding payment incurred during this position response
        SignedDecimal.signedDecimal fundingPayment;
        // realizedPnl = unrealizedPnl * closedRatio
        SignedDecimal.signedDecimal realizedPnl;
        // positive = trader transfer margin to vault, negative = trader receive margin from vault
        // it's 0 when internalReducePosition, its addedMargin when internalIncreasePosition
        // it's min(0, oldPosition + realizedFundingPayment + realizedPnl) when internalClosePosition
        SignedDecimal.signedDecimal marginToVault;
        // unrealized pnl after open position
        SignedDecimal.signedDecimal unrealizedPnlAfter;
    }

    struct AmmMap {
        // issue #1471
        // last block when it turn restriction mode on.
        // In restriction mode, no one can do multi open/close/liquidate position in the same block.
        // If any underwater position being closed (having a bad debt and make insuranceFund loss),
        // or any liquidation happened,
        // restriction mode is ON in that block and OFF(default) in the next block.
        // This design is to prevent the attacker being benefited from the multiple action in one block
        // in extreme cases
        uint256 lastRestrictionBlock;
        SignedDecimal.signedDecimal[] cumulativePremiumFractions;
        mapping(address => Position) positionMap;
    }

    //**********************************************************//
    //    Can not change the order of below state variables     //
    //**********************************************************//

    // only admin
    Decimal.decimal public initMarginRatio;

    // only admin
    Decimal.decimal public maintenanceMarginRatio;

    // only admin
    Decimal.decimal public liquidationFeeRatio;

    // key by amm address. will be deprecated or replaced after guarded period.
    // it's not an accurate open interest, just a rough way to control the unexpected loss at the beginning
    mapping(address => Decimal.decimal) public openInterestNotionalMap;

    // key by amm address
    mapping(address => AmmMap) internal ammMap;

    // prepaid bad debt balance, key by ERC20 token address
    mapping(address => Decimal.decimal) internal prepaidBadDebt;

    // contract dependencies
    IInsuranceFund public insuranceFund;
    address public feePool;

    uint256[50] private __gap;
    //**********************************************************//
    //    Can not change the order of above state variables     //
    //**********************************************************//

    //◥◤◥◤◥◤◥◤◥◤◥◤◥◤◥◤ add state variables below ◥◤◥◤◥◤◥◤◥◤◥◤◥◤◥◤//
    Decimal.decimal public partialLiquidationRatio;

    mapping(address => bool) public backstopLiquidityProviderMap;

    //◢◣◢◣◢◣◢◣◢◣◢◣◢◣◢◣ add state variables above ◢◣◢◣◢◣◢◣◢◣◢◣◢◣◢◣//
    //

    // FUNCTIONS
    //
    // openzeppelin doesn't support struct input
    // https://github.com/OpenZeppelin/openzeppelin-sdk/issues/1523
    function initialize(
        uint256 _initMarginRatio,
        uint256 _maintenanceMarginRatio,
        uint256 _liquidationFeeRatio,
        IInsuranceFund _insuranceFund
    ) public initializer {
        require(address(_insuranceFund) != address(0), "Invalid IInsuranceFund");
        __OwnerPausable_init();
        __ReentrancyGuard_init();

        initMarginRatio = Decimal.decimal(_initMarginRatio);
        maintenanceMarginRatio = Decimal.decimal(_maintenanceMarginRatio);
        liquidationFeeRatio = Decimal.decimal(_liquidationFeeRatio);
        insuranceFund = _insuranceFund;
    }

    //
    // External
    //

    /**
     * @notice set liquidation fee ratio
     * @dev only owner can call
     * @param _liquidationFeeRatio new liquidation fee ratio in 18 digits
     */
    function setLiquidationFeeRatio(Decimal.decimal memory _liquidationFeeRatio)
        external
        onlyOwner
    {
        liquidationFeeRatio = _liquidationFeeRatio;
        emit LiquidationFeeRatioChanged(liquidationFeeRatio.toUint());
    }

    /**
     * @notice set maintenance margin ratio
     * @dev only owner can call
     * @param _maintenanceMarginRatio new maintenance margin ratio in 18 digits
     */
    function setMaintenanceMarginRatio(Decimal.decimal memory _maintenanceMarginRatio)
        external
        onlyOwner
    {
        maintenanceMarginRatio = _maintenanceMarginRatio;
        emit MarginRatioChanged(maintenanceMarginRatio.toUint());
    }

    /**
     * @notice set the toll pool address
     * @dev only owner can call
     */
    function setTollPool(address _feePool) external onlyOwner {
        feePool = _feePool;
    }

    /**
     * @notice set backstop liquidity provider
     * @dev only owner can call
     * @param account provider address
     * @param isProvider wether the account is a backstop liquidity provider
     */
    function setBackstopLiquidityProvider(address account, bool isProvider) external onlyOwner {
        backstopLiquidityProviderMap[account] = isProvider;
        emit BackstopLiquidityProviderChanged(account, isProvider);
    }

    /**
     * @notice set the margin ratio after deleveraging
     * @dev only owner can call
     */
    function setPartialLiquidationRatio(Decimal.decimal memory _ratio) external onlyOwner {
        require(_ratio.cmp(Decimal.one()) <= 0, "invalid partial liquidation ratio");
        partialLiquidationRatio = _ratio;
    }

    /**
     * @notice add margin to increase margin ratio
     * @param _amm IAmm address
     * @param _addedMargin added margin in 18 digits
     */
    function addMargin(IAmm _amm, Decimal.decimal calldata _addedMargin)
        external
        whenNotPaused
        nonReentrant
    {
        // check condition
        requireAmm(_amm);
        IERC20 quoteToken = _amm.quoteAsset();
        requireNonZeroInput(_addedMargin);

        address trader = _msgSender();
        Position memory position = getPosition(_amm, trader);
        // update margin
        position.margin = position.margin.addD(_addedMargin);

        setPosition(_amm, trader, position);
        // transfer token from trader
        _transferFrom(quoteToken, trader, address(this), _addedMargin);
        emit MarginChanged(trader, address(_amm), int256(_addedMargin.toUint()), 0);
    }

    /**
     * @notice remove margin to decrease margin ratio
     * @param _amm IAmm address
     * @param _removedMargin removed margin in 18 digits
     */
    function removeMargin(IAmm _amm, Decimal.decimal calldata _removedMargin)
        external
        whenNotPaused
        nonReentrant
    {
        // check condition
        requireAmm(_amm);
        IERC20 quoteToken = _amm.quoteAsset();
        requireNonZeroInput(_removedMargin);

        address trader = _msgSender();
        // realize funding payment if there's no bad debt
        Position memory position = getPosition(_amm, trader);

        // update margin and cumulativePremiumFraction
        SignedDecimal.signedDecimal memory marginDelta = MixedDecimal
            .fromDecimal(_removedMargin)
            .mulScalar(-1);
        (
            Decimal.decimal memory remainMargin,
            Decimal.decimal memory badDebt,
            SignedDecimal.signedDecimal memory fundingPayment,
            SignedDecimal.signedDecimal memory latestCumulativePremiumFraction
        ) = calcRemainMarginWithFundingPayment(_amm, position, marginDelta);
        require(badDebt.toUint() == 0, "margin is not enough");
        position.margin = remainMargin;
        position.lastUpdatedCumulativePremiumFraction = latestCumulativePremiumFraction;

        // check enough margin (same as the way Curie calculates the free collateral)
        // Use a more conservative way to restrict traders to remove their margin
        // We don't allow unrealized PnL to support their margin removal
        require(
            calcFreeCollateral(_amm, trader, remainMargin.subD(badDebt)).toInt() >= 0,
            "free collateral is not enough"
        );

        setPosition(_amm, trader, position);

        // transfer token back to trader
        withdraw(quoteToken, trader, _removedMargin);
        emit MarginChanged(trader, address(_amm), marginDelta.toInt(), fundingPayment.toInt());
    }

    // if increase position
    //   marginToVault = addMargin
    //   marginDiff = realizedFundingPayment + realizedPnl(0)
    //   pos.margin += marginToVault + marginDiff
    //   vault.margin += marginToVault + marginDiff
    //   required(enoughMarginRatio)
    // else if reduce position()
    //   marginToVault = 0
    //   marginDiff = realizedFundingPayment + realizedPnl
    //   pos.margin += marginToVault + marginDiff
    //   if pos.margin < 0, badDebt = abs(pos.margin), set pos.margin = 0
    //   vault.margin += marginToVault + marginDiff
    //   required(enoughMarginRatio)
    // else if close
    //   marginDiff = realizedFundingPayment + realizedPnl
    //   pos.margin += marginDiff
    //   if pos.margin < 0, badDebt = abs(pos.margin)
    //   marginToVault = -pos.margin
    //   set pos.margin = 0
    //   vault.margin += marginToVault + marginDiff
    // else if close and open a larger position in reverse side
    //   close()
    //   positionNotional -= exchangedQuoteAssetAmount
    //   newMargin = positionNotional / leverage
    //   internalIncreasePosition(newMargin, leverage)
    // else if liquidate
    //   close()
    //   pay liquidation fee to liquidator
    //   move the remain margin to insuranceFund

    /**
     * @notice open a position
     * @param _amm amm address
     * @param _side enum Side; BUY for long and SELL for short
     * @param _quoteAssetAmount quote asset amount in 18 digits. Can Not be 0
     * @param _leverage leverage  in 18 digits. Can Not be 0
     * @param _baseAssetAmountLimit minimum base asset amount expected to get to prevent from slippage.
     */
    function openPosition(
        IAmm _amm,
        Side _side,
        Decimal.decimal memory _quoteAssetAmount,
        Decimal.decimal memory _leverage,
        Decimal.decimal memory _baseAssetAmountLimit
    ) public whenNotPaused nonReentrant {
        requireAmm(_amm);
        IERC20 quoteToken = _amm.quoteAsset();
        requireNonZeroInput(_quoteAssetAmount);
        requireNonZeroInput(_leverage);
        requireMoreMarginRatio(
            MixedDecimal.fromDecimal(Decimal.one()).divD(_leverage),
            initMarginRatio,
            true
        );
        requireNotRestrictionMode(_amm);

        address trader = _msgSender();
        PositionResp memory positionResp;
        {
            // add scope for stack too deep error
            int256 oldPositionSize = getPosition(_amm, trader).size.toInt();
            bool isNewPosition = oldPositionSize == 0 ? true : false;

            // increase or decrease position depends on old position's side and size
            if (isNewPosition || (oldPositionSize > 0 ? Side.BUY : Side.SELL) == _side) {
                positionResp = internalIncreasePosition(
                    _amm,
                    _side,
                    _quoteAssetAmount.mulD(_leverage),
                    _baseAssetAmountLimit,
                    _leverage
                );
            } else {
                positionResp = openReversePosition(
                    _amm,
                    _side,
                    trader,
                    _quoteAssetAmount,
                    _leverage,
                    _baseAssetAmountLimit,
                    false
                );
            }

            // update the position state
            setPosition(_amm, trader, positionResp.position);
            // if opening the exact position size as the existing one == closePosition, can skip the margin ratio check
            if (!isNewPosition && positionResp.position.size.toInt() != 0) {
                requireMoreMarginRatio(getMarginRatio(_amm, trader), maintenanceMarginRatio, true);
            }

            // to prevent attacker to leverage the bad debt to withdraw extra token from insurance fund
            require(positionResp.badDebt.toUint() == 0, "bad debt");

            // transfer the actual token between trader and vault
            if (positionResp.marginToVault.toInt() > 0) {
                _transferFrom(quoteToken, trader, address(this), positionResp.marginToVault.abs());
            } else if (positionResp.marginToVault.toInt() < 0) {
                withdraw(quoteToken, trader, positionResp.marginToVault.abs());
            }
        }

        // calculate fee and transfer token for fees
        //@audit - can optimize by changing amm.swapInput/swapOutput's return type to (exchangedAmount, quoteToll, quoteSpread, quoteReserve, baseReserve) (@wraecca)
        Decimal.decimal memory transferredFee = transferFee(
            trader,
            _amm,
            positionResp.exchangedQuoteAssetAmount
        );

        // emit event
        uint256 spotPrice = _amm.getSpotPrice().toUint();
        int256 fundingPayment = positionResp.fundingPayment.toInt(); // pre-fetch for stack too deep error
        emit PositionChanged(
            trader,
            address(_amm),
            positionResp.position.margin.toUint(),
            positionResp.exchangedQuoteAssetAmount.toUint(),
            positionResp.exchangedPositionSize.toInt(),
            transferredFee.toUint(),
            positionResp.position.size.toInt(),
            positionResp.realizedPnl.toInt(),
            positionResp.unrealizedPnlAfter.toInt(),
            positionResp.badDebt.toUint(),
            0,
            spotPrice,
            fundingPayment
        );
    }

    /**
     * @notice close all the positions
     * @param _amm IAmm address
     */
    function closePosition(IAmm _amm, Decimal.decimal memory _quoteAssetAmountLimit)
        public
        whenNotPaused
        nonReentrant
    {
        // check conditions
        requireAmm(_amm);
        requireNotRestrictionMode(_amm);

        // update position
        address trader = _msgSender();

        PositionResp memory positionResp;
        {
            Position memory position = getPosition(_amm, trader);
            // if it is long position, close a position means short it(which means base dir is ADD_TO_AMM) and vice versa
            IAmm.Dir dirOfBase = position.size.toInt() > 0
                ? IAmm.Dir.ADD_TO_AMM
                : IAmm.Dir.REMOVE_FROM_AMM;

            // check if this position exceed fluctuation limit
            // if over fluctuation limit, then close partial position. Otherwise close all.
            // if partialLiquidationRatio is 1, then close whole position
            if (
                _amm.isOverFluctuationLimit(dirOfBase, position.size.abs()) &&
                partialLiquidationRatio.cmp(Decimal.one()) < 0
            ) {
                Decimal.decimal memory partiallyClosedPositionNotional = _amm.getOutputPrice(
                    dirOfBase,
                    position.size.mulD(partialLiquidationRatio).abs()
                );

                positionResp = openReversePosition(
                    _amm,
                    position.size.toInt() > 0 ? Side.SELL : Side.BUY,
                    trader,
                    partiallyClosedPositionNotional,
                    Decimal.one(),
                    Decimal.zero(),
                    true
                );
                setPosition(_amm, trader, positionResp.position);
            } else {
                positionResp = internalClosePosition(_amm, trader, _quoteAssetAmountLimit);
            }

            // to prevent attacker to leverage the bad debt to withdraw extra token from insurance fund
            require(positionResp.badDebt.toUint() == 0, "bad debt");

            // add scope for stack too deep error
            // transfer the actual token from trader and vault
            IERC20 quoteToken = _amm.quoteAsset();
            withdraw(quoteToken, trader, positionResp.marginToVault.abs());
        }

        // calculate fee and transfer token for fees
        Decimal.decimal memory transferredFee = transferFee(
            trader,
            _amm,
            positionResp.exchangedQuoteAssetAmount
        );

        // prepare event
        uint256 spotPrice = _amm.getSpotPrice().toUint();
        int256 fundingPayment = positionResp.fundingPayment.toInt();
        emit PositionChanged(
            trader,
            address(_amm),
            positionResp.position.margin.toUint(),
            positionResp.exchangedQuoteAssetAmount.toUint(),
            positionResp.exchangedPositionSize.toInt(),
            transferredFee.toUint(),
            positionResp.position.size.toInt(),
            positionResp.realizedPnl.toInt(),
            positionResp.unrealizedPnlAfter.toInt(),
            positionResp.badDebt.toUint(),
            0,
            spotPrice,
            fundingPayment
        );
    }

    function liquidateWithSlippage(
        IAmm _amm,
        address _trader,
        Decimal.decimal memory _quoteAssetAmountLimit
    ) external nonReentrant returns (Decimal.decimal memory quoteAssetAmount, bool isPartialClose) {
        Position memory position = getPosition(_amm, _trader);
        (quoteAssetAmount, isPartialClose) = internalLiquidate(_amm, _trader);

        Decimal.decimal memory quoteAssetAmountLimit = isPartialClose
            ? _quoteAssetAmountLimit.mulD(partialLiquidationRatio)
            : _quoteAssetAmountLimit;

        if (position.size.toInt() > 0) {
            require(
                quoteAssetAmount.toUint() >= quoteAssetAmountLimit.toUint(),
                "Less than minimal quote token"
            );
        } else if (position.size.toInt() < 0 && quoteAssetAmountLimit.cmp(Decimal.zero()) != 0) {
            require(
                quoteAssetAmount.toUint() <= quoteAssetAmountLimit.toUint(),
                "More than maximal quote token"
            );
        }

        return (quoteAssetAmount, isPartialClose);
    }

    /**
     * @notice liquidate trader's underwater position. Require trader's margin ratio less than maintenance margin ratio
     * @dev liquidator can NOT open any positions in the same block to prevent from price manipulation.
     * @param _amm IAmm address
     * @param _trader trader address
     */
    function liquidate(IAmm _amm, address _trader) public nonReentrant {
        internalLiquidate(_amm, _trader);
    }

    /**
     * @notice if funding rate is positive, traders with long position pay traders with short position and vice versa.
     * @param _amm IAmm address
     */
    function payFunding(IAmm _amm) external {
        requireAmm(_amm);

        SignedDecimal.signedDecimal memory premiumFraction = _amm.settleFunding();
        ammMap[address(_amm)].cumulativePremiumFractions.push(
            premiumFraction.addD(getLatestCumulativePremiumFraction(_amm))
        );

        // funding payment = premium fraction * position
        // eg. if alice takes 10 long position, totalPositionSize = 10
        // if premiumFraction is positive: long pay short, amm get positive funding payment
        // if premiumFraction is negative: short pay long, amm get negative funding payment
        // if totalPositionSize.side * premiumFraction > 0, funding payment is positive which means profit
        SignedDecimal.signedDecimal memory totalTraderPositionSize = _amm.getBaseAssetDelta();
        SignedDecimal.signedDecimal memory ammFundingPaymentProfit = premiumFraction.mulD(
            totalTraderPositionSize
        );

        IERC20 quoteAsset = _amm.quoteAsset();
        if (ammFundingPaymentProfit.toInt() < 0) {
            insuranceFund.withdraw(quoteAsset, ammFundingPaymentProfit.abs());
        } else {
            transferToInsuranceFund(quoteAsset, ammFundingPaymentProfit.abs());
        }
    }

    //
    // VIEW FUNCTIONS
    //

    /**
     * @notice get margin ratio, marginRatio = (margin + funding payment + unrealized Pnl) / positionNotional
     * use spot and twap price to calculate unrealized Pnl, final unrealized Pnl depends on which one is higher
     * @param _amm IAmm address
     * @param _trader trader address
     * @return margin ratio in 18 digits
     */
    function getMarginRatio(IAmm _amm, address _trader)
        public
        view
        returns (SignedDecimal.signedDecimal memory)
    {
        Position memory position = getPosition(_amm, _trader);
        requirePositionSize(position.size);
        (
            SignedDecimal.signedDecimal memory unrealizedPnl,
            Decimal.decimal memory positionNotional
        ) = getPreferencePositionNotionalAndUnrealizedPnl(
                _amm,
                _trader,
                PnlPreferenceOption.MAX_PNL
            );
        return _getMarginRatio(_amm, position, unrealizedPnl, positionNotional);
    }

    function _getMarginRatioByCalcOption(
        IAmm _amm,
        address _trader,
        PnlCalcOption _pnlCalcOption
    ) internal view returns (SignedDecimal.signedDecimal memory) {
        Position memory position = getPosition(_amm, _trader);
        requirePositionSize(position.size);
        (
            Decimal.decimal memory positionNotional,
            SignedDecimal.signedDecimal memory pnl
        ) = getPositionNotionalAndUnrealizedPnl(_amm, _trader, _pnlCalcOption);
        return _getMarginRatio(_amm, position, pnl, positionNotional);
    }

    function _getMarginRatio(
        IAmm _amm,
        Position memory _position,
        SignedDecimal.signedDecimal memory _unrealizedPnl,
        Decimal.decimal memory _positionNotional
    ) internal view returns (SignedDecimal.signedDecimal memory) {
        (
            Decimal.decimal memory remainMargin,
            Decimal.decimal memory badDebt,
            ,

        ) = calcRemainMarginWithFundingPayment(_amm, _position, _unrealizedPnl);
        return MixedDecimal.fromDecimal(remainMargin).subD(badDebt).divD(_positionNotional);
    }

    /**
     * @notice get personal position information
     * @param _amm IAmm address
     * @param _trader trader address
     * @return struct Position
     */
    function getPosition(IAmm _amm, address _trader) public view returns (Position memory) {
        return ammMap[address(_amm)].positionMap[_trader];
    }

    /**
     * @notice get position notional and unrealized Pnl without fee expense and funding payment
     * @param _amm IAmm address
     * @param _trader trader address
     * @param _pnlCalcOption enum PnlCalcOption, SPOT_PRICE for spot price and TWAP for twap price
     * @return positionNotional position notional
     * @return unrealizedPnl unrealized Pnl
     */
    function getPositionNotionalAndUnrealizedPnl(
        IAmm _amm,
        address _trader,
        PnlCalcOption _pnlCalcOption
    )
        public
        view
        returns (
            Decimal.decimal memory positionNotional,
            SignedDecimal.signedDecimal memory unrealizedPnl
        )
    {
        Position memory position = getPosition(_amm, _trader);
        Decimal.decimal memory positionSizeAbs = position.size.abs();
        if (positionSizeAbs.toUint() != 0) {
            bool isShortPosition = position.size.toInt() < 0;
            IAmm.Dir dir = isShortPosition ? IAmm.Dir.REMOVE_FROM_AMM : IAmm.Dir.ADD_TO_AMM;
            if (_pnlCalcOption == PnlCalcOption.TWAP) {
                positionNotional = _amm.getOutputTwap(dir, positionSizeAbs);
            } else if (_pnlCalcOption == PnlCalcOption.SPOT_PRICE) {
                positionNotional = _amm.getOutputPrice(dir, positionSizeAbs);
            } else {
                Decimal.decimal memory oraclePrice = _amm.getUnderlyingPrice();
                positionNotional = positionSizeAbs.mulD(oraclePrice);
            }
            // unrealizedPnlForLongPosition = positionNotional - openNotional
            // unrealizedPnlForShortPosition = positionNotionalWhenBorrowed - positionNotionalWhenReturned =
            // openNotional - positionNotional = unrealizedPnlForLongPosition * -1
            unrealizedPnl = isShortPosition
                ? MixedDecimal.fromDecimal(position.openNotional).subD(positionNotional)
                : MixedDecimal.fromDecimal(positionNotional).subD(position.openNotional);
        }
    }

    /**
     * @notice get latest cumulative premium fraction.
     * @param _amm IAmm address
     * @return latest cumulative premium fraction in 18 digits
     */
    function getLatestCumulativePremiumFraction(IAmm _amm)
        public
        view
        returns (SignedDecimal.signedDecimal memory)
    {
        uint256 len = ammMap[address(_amm)].cumulativePremiumFractions.length;
        if (len > 0) {
            return ammMap[address(_amm)].cumulativePremiumFractions[len - 1];
        }
    }

    //
    // INTERNAL FUNCTIONS
    //

    function enterRestrictionMode(IAmm _amm) internal {
        uint256 blockNumber = block.number;
        ammMap[address(_amm)].lastRestrictionBlock = blockNumber;
        emit RestrictionModeEntered(address(_amm), blockNumber);
    }

    function setPosition(
        IAmm _amm,
        address _trader,
        Position memory _position
    ) internal {
        Position storage positionStorage = ammMap[address(_amm)].positionMap[_trader];
        positionStorage.size = _position.size;
        positionStorage.margin = _position.margin;
        positionStorage.openNotional = _position.openNotional;
        positionStorage.lastUpdatedCumulativePremiumFraction = _position
            .lastUpdatedCumulativePremiumFraction;
        positionStorage.blockNumber = _position.blockNumber;
    }

    function clearPosition(IAmm _amm, address _trader) internal {
        // keep the record in order to retain the last updated block number
        ammMap[address(_amm)].positionMap[_trader] = Position({
            size: SignedDecimal.zero(),
            margin: Decimal.zero(),
            openNotional: Decimal.zero(),
            lastUpdatedCumulativePremiumFraction: SignedDecimal.zero(),
            blockNumber: block.number
        });
    }

    function internalLiquidate(IAmm _amm, address _trader)
        internal
        returns (Decimal.decimal memory quoteAssetAmount, bool isPartialClose)
    {
        requireAmm(_amm);
        SignedDecimal.signedDecimal memory marginRatio = getMarginRatio(_amm, _trader);

        // including oracle-based margin ratio as reference price when amm is over spread limit
        if (_amm.isOverSpreadLimit()) {
            SignedDecimal.signedDecimal
                memory marginRatioBasedOnOracle = _getMarginRatioByCalcOption(
                    _amm,
                    _trader,
                    PnlCalcOption.ORACLE
                );
            if (marginRatioBasedOnOracle.subD(marginRatio).toInt() > 0) {
                marginRatio = marginRatioBasedOnOracle;
            }
        }
        requireMoreMarginRatio(marginRatio, maintenanceMarginRatio, false);

        PositionResp memory positionResp;
        Decimal.decimal memory liquidationPenalty;
        {
            Decimal.decimal memory liquidationBadDebt;
            Decimal.decimal memory feeToLiquidator;
            Decimal.decimal memory feeToInsuranceFund;
            IERC20 quoteAsset = _amm.quoteAsset();

            int256 marginRatioBasedOnSpot = _getMarginRatioByCalcOption(
                _amm,
                _trader,
                PnlCalcOption.SPOT_PRICE
            ).toInt();
            if (
                // check margin(based on spot price) is enough to pay the liquidation fee
                // after partially close, otherwise we fully close the position.
                // that also means we can ensure no bad debt happen when partially liquidate
                marginRatioBasedOnSpot > int256(liquidationFeeRatio.toUint()) &&
                partialLiquidationRatio.cmp(Decimal.one()) < 0 &&
                partialLiquidationRatio.toUint() != 0
            ) {
                Position memory position = getPosition(_amm, _trader);
                Decimal.decimal memory partiallyLiquidatedPositionNotional = _amm.getOutputPrice(
                    position.size.toInt() > 0 ? IAmm.Dir.ADD_TO_AMM : IAmm.Dir.REMOVE_FROM_AMM,
                    position.size.mulD(partialLiquidationRatio).abs()
                );

                positionResp = openReversePosition(
                    _amm,
                    position.size.toInt() > 0 ? Side.SELL : Side.BUY,
                    _trader,
                    partiallyLiquidatedPositionNotional,
                    Decimal.one(),
                    Decimal.zero(),
                    true
                );

                // half of the liquidationFee goes to liquidator & another half goes to insurance fund
                liquidationPenalty = positionResp.exchangedQuoteAssetAmount.mulD(
                    liquidationFeeRatio
                );
                feeToLiquidator = liquidationPenalty.divScalar(2);
                feeToInsuranceFund = liquidationPenalty.subD(feeToLiquidator);

                positionResp.position.margin = positionResp.position.margin.subD(
                    liquidationPenalty
                );
                setPosition(_amm, _trader, positionResp.position);

                isPartialClose = true;
            } else {
                liquidationPenalty = getPosition(_amm, _trader).margin;
                positionResp = internalClosePosition(_amm, _trader, Decimal.zero());
                Decimal.decimal memory remainMargin = positionResp.marginToVault.abs();
                feeToLiquidator = positionResp
                    .exchangedQuoteAssetAmount
                    .mulD(liquidationFeeRatio)
                    .divScalar(2);

                // if the remainMargin is not enough for liquidationFee, count it as bad debt
                // else, then the rest will be transferred to insuranceFund
                Decimal.decimal memory totalBadDebt = positionResp.badDebt;
                if (feeToLiquidator.toUint() > remainMargin.toUint()) {
                    liquidationBadDebt = feeToLiquidator.subD(remainMargin);
                    totalBadDebt = totalBadDebt.addD(liquidationBadDebt);
                } else {
                    remainMargin = remainMargin.subD(feeToLiquidator);
                }

                // transfer the actual token between trader and vault
                if (totalBadDebt.toUint() > 0) {
                    require(backstopLiquidityProviderMap[_msgSender()], "not backstop LP");
                    realizeBadDebt(quoteAsset, totalBadDebt);
                }
                if (remainMargin.toUint() > 0) {
                    feeToInsuranceFund = remainMargin;
                }
            }

            if (feeToInsuranceFund.toUint() > 0) {
                transferToInsuranceFund(quoteAsset, feeToInsuranceFund);
            }
            withdraw(quoteAsset, _msgSender(), feeToLiquidator);
            enterRestrictionMode(_amm);

            emit PositionLiquidated(
                _trader,
                address(_amm),
                positionResp.exchangedQuoteAssetAmount.toUint(),
                positionResp.exchangedPositionSize.toUint(),
                feeToLiquidator.toUint(),
                _msgSender(),
                liquidationBadDebt.toUint()
            );
        }

        // emit event
        uint256 spotPrice = _amm.getSpotPrice().toUint();
        int256 fundingPayment = positionResp.fundingPayment.toInt();
        emit PositionChanged(
            _trader,
            address(_amm),
            positionResp.position.margin.toUint(),
            positionResp.exchangedQuoteAssetAmount.toUint(),
            positionResp.exchangedPositionSize.toInt(),
            0,
            positionResp.position.size.toInt(),
            positionResp.realizedPnl.toInt(),
            positionResp.unrealizedPnlAfter.toInt(),
            positionResp.badDebt.toUint(),
            liquidationPenalty.toUint(),
            spotPrice,
            fundingPayment
        );

        return (positionResp.exchangedQuoteAssetAmount, isPartialClose);
    }

    // only called from openPosition and closeAndOpenReversePosition. caller need to ensure there's enough marginRatio
    function internalIncreasePosition(
        IAmm _amm,
        Side _side,
        Decimal.decimal memory _openNotional,
        Decimal.decimal memory _minPositionSize,
        Decimal.decimal memory _leverage
    ) internal returns (PositionResp memory positionResp) {
        address trader = _msgSender();
        Position memory oldPosition = getPosition(_amm, trader);
        positionResp.exchangedPositionSize = swapInput(
            _amm,
            _side,
            _openNotional,
            _minPositionSize,
            false
        );
        SignedDecimal.signedDecimal memory newSize = oldPosition.size.addD(
            positionResp.exchangedPositionSize
        );

        updateOpenInterestNotional(_amm, MixedDecimal.fromDecimal(_openNotional));
        Decimal.decimal memory maxHoldingBaseAsset = _amm.getMaxHoldingBaseAsset();
        if (maxHoldingBaseAsset.toUint() > 0) {
            // total position size should be less than `positionUpperBound`
            require(newSize.abs().cmp(maxHoldingBaseAsset) <= 0, "hit position size upper bound");
        }

        SignedDecimal.signedDecimal memory increaseMarginRequirement = MixedDecimal.fromDecimal(
            _openNotional.divD(_leverage)
        );
        (
            Decimal.decimal memory remainMargin, // the 2nd return (bad debt) must be 0 - already checked from caller
            ,
            SignedDecimal.signedDecimal memory fundingPayment,
            SignedDecimal.signedDecimal memory latestCumulativePremiumFraction
        ) = calcRemainMarginWithFundingPayment(_amm, oldPosition, increaseMarginRequirement);

        (, SignedDecimal.signedDecimal memory unrealizedPnl) = getPositionNotionalAndUnrealizedPnl(
            _amm,
            trader,
            PnlCalcOption.SPOT_PRICE
        );

        // update positionResp
        positionResp.exchangedQuoteAssetAmount = _openNotional;
        positionResp.unrealizedPnlAfter = unrealizedPnl;
        positionResp.marginToVault = increaseMarginRequirement;
        positionResp.fundingPayment = fundingPayment;
        positionResp.position = Position(
            newSize,
            remainMargin,
            oldPosition.openNotional.addD(positionResp.exchangedQuoteAssetAmount),
            latestCumulativePremiumFraction,
            block.number
        );
    }

    function openReversePosition(
        IAmm _amm,
        Side _side,
        address _trader,
        Decimal.decimal memory _quoteAssetAmount,
        Decimal.decimal memory _leverage,
        Decimal.decimal memory _baseAssetAmountLimit,
        bool _canOverFluctuationLimit
    ) internal returns (PositionResp memory) {
        Decimal.decimal memory openNotional = _quoteAssetAmount.mulD(_leverage);
        (
            Decimal.decimal memory oldPositionNotional,
            SignedDecimal.signedDecimal memory unrealizedPnl
        ) = getPositionNotionalAndUnrealizedPnl(_amm, _trader, PnlCalcOption.SPOT_PRICE);
        PositionResp memory positionResp;

        // reduce position if old position is larger
        if (oldPositionNotional.toUint() > openNotional.toUint()) {
            updateOpenInterestNotional(_amm, MixedDecimal.fromDecimal(openNotional).mulScalar(-1));
            Position memory oldPosition = getPosition(_amm, _trader);
            positionResp.exchangedPositionSize = swapInput(
                _amm,
                _side,
                openNotional,
                _baseAssetAmountLimit,
                _canOverFluctuationLimit
            );

            // realizedPnl = unrealizedPnl * closedRatio
            // closedRatio = positionResp.exchangedPositionSiz / oldPosition.size
            if (oldPosition.size.toInt() != 0) {
                positionResp.realizedPnl = unrealizedPnl
                    .mulD(positionResp.exchangedPositionSize.abs())
                    .divD(oldPosition.size.abs());
            }
            Decimal.decimal memory remainMargin;
            SignedDecimal.signedDecimal memory latestCumulativePremiumFraction;
            (
                remainMargin,
                positionResp.badDebt,
                positionResp.fundingPayment,
                latestCumulativePremiumFraction
            ) = calcRemainMarginWithFundingPayment(_amm, oldPosition, positionResp.realizedPnl);

            // positionResp.unrealizedPnlAfter = unrealizedPnl - realizedPnl
            positionResp.unrealizedPnlAfter = unrealizedPnl.subD(positionResp.realizedPnl);
            positionResp.exchangedQuoteAssetAmount = openNotional;

            // calculate openNotional (it's different depends on long or short side)
            // long: unrealizedPnl = positionNotional - openNotional => openNotional = positionNotional - unrealizedPnl
            // short: unrealizedPnl = openNotional - positionNotional => openNotional = positionNotional + unrealizedPnl
            // positionNotional = oldPositionNotional - exchangedQuoteAssetAmount
            SignedDecimal.signedDecimal memory remainOpenNotional = oldPosition.size.toInt() > 0
                ? MixedDecimal
                    .fromDecimal(oldPositionNotional)
                    .subD(positionResp.exchangedQuoteAssetAmount)
                    .subD(positionResp.unrealizedPnlAfter)
                : positionResp.unrealizedPnlAfter.addD(oldPositionNotional).subD(
                    positionResp.exchangedQuoteAssetAmount
                );
            require(remainOpenNotional.toInt() > 0, "value of openNotional <= 0");

            positionResp.position = Position(
                oldPosition.size.addD(positionResp.exchangedPositionSize),
                remainMargin,
                remainOpenNotional.abs(),
                latestCumulativePremiumFraction,
                block.number
            );
            return positionResp;
        }

        return
            closeAndOpenReversePosition(
                _amm,
                _side,
                _trader,
                _quoteAssetAmount,
                _leverage,
                _baseAssetAmountLimit
            );
    }

    function closeAndOpenReversePosition(
        IAmm _amm,
        Side _side,
        address _trader,
        Decimal.decimal memory _quoteAssetAmount,
        Decimal.decimal memory _leverage,
        Decimal.decimal memory _baseAssetAmountLimit
    ) internal returns (PositionResp memory positionResp) {
        // new position size is larger than or equal to the old position size
        // so either close or close then open a larger position
        PositionResp memory closePositionResp = internalClosePosition(
            _amm,
            _trader,
            Decimal.zero()
        );

        // the old position is underwater. trader should close a position first
        require(closePositionResp.badDebt.toUint() == 0, "reduce an underwater position");

        // update open notional after closing position
        Decimal.decimal memory openNotional = _quoteAssetAmount.mulD(_leverage).subD(
            closePositionResp.exchangedQuoteAssetAmount
        );

        // if remain exchangedQuoteAssetAmount is too small (eg. 1wei) then the required margin might be 0
        // then the clearingHouse will stop opening position
        if (openNotional.divD(_leverage).toUint() == 0) {
            positionResp = closePositionResp;
        } else {
            Decimal.decimal memory updatedBaseAssetAmountLimit;
            if (_baseAssetAmountLimit.toUint() > closePositionResp.exchangedPositionSize.toUint()) {
                updatedBaseAssetAmountLimit = _baseAssetAmountLimit.subD(
                    closePositionResp.exchangedPositionSize.abs()
                );
            }

            PositionResp memory increasePositionResp = internalIncreasePosition(
                _amm,
                _side,
                openNotional,
                updatedBaseAssetAmountLimit,
                _leverage
            );
            positionResp = PositionResp({
                position: increasePositionResp.position,
                exchangedQuoteAssetAmount: closePositionResp.exchangedQuoteAssetAmount.addD(
                    increasePositionResp.exchangedQuoteAssetAmount
                ),
                badDebt: closePositionResp.badDebt.addD(increasePositionResp.badDebt),
                fundingPayment: closePositionResp.fundingPayment.addD(
                    increasePositionResp.fundingPayment
                ),
                exchangedPositionSize: closePositionResp.exchangedPositionSize.addD(
                    increasePositionResp.exchangedPositionSize
                ),
                realizedPnl: closePositionResp.realizedPnl.addD(increasePositionResp.realizedPnl),
                unrealizedPnlAfter: SignedDecimal.zero(),
                marginToVault: closePositionResp.marginToVault.addD(
                    increasePositionResp.marginToVault
                )
            });
        }
        return positionResp;
    }

    function internalClosePosition(
        IAmm _amm,
        address _trader,
        Decimal.decimal memory _quoteAssetAmountLimit
    ) private returns (PositionResp memory positionResp) {
        // check conditions
        Position memory oldPosition = getPosition(_amm, _trader);
        requirePositionSize(oldPosition.size);

        (, SignedDecimal.signedDecimal memory unrealizedPnl) = getPositionNotionalAndUnrealizedPnl(
            _amm,
            _trader,
            PnlCalcOption.SPOT_PRICE
        );
        (
            Decimal.decimal memory remainMargin,
            Decimal.decimal memory badDebt,
            SignedDecimal.signedDecimal memory fundingPayment,

        ) = calcRemainMarginWithFundingPayment(_amm, oldPosition, unrealizedPnl);

        positionResp.exchangedPositionSize = oldPosition.size.mulScalar(-1);
        positionResp.realizedPnl = unrealizedPnl;
        positionResp.badDebt = badDebt;
        positionResp.fundingPayment = fundingPayment;
        positionResp.marginToVault = MixedDecimal.fromDecimal(remainMargin).mulScalar(-1);
        // for amm.swapOutput, the direction is in base asset, from the perspective of Amm
        positionResp.exchangedQuoteAssetAmount = _amm.swapOutput(
            oldPosition.size.toInt() > 0 ? IAmm.Dir.ADD_TO_AMM : IAmm.Dir.REMOVE_FROM_AMM,
            oldPosition.size.abs(),
            _quoteAssetAmountLimit
        );

        // bankrupt position's bad debt will be also consider as a part of the open interest
        updateOpenInterestNotional(
            _amm,
            unrealizedPnl.addD(badDebt).addD(oldPosition.openNotional).mulScalar(-1)
        );
        clearPosition(_amm, _trader);
    }

    function swapInput(
        IAmm _amm,
        Side _side,
        Decimal.decimal memory _inputAmount,
        Decimal.decimal memory _minOutputAmount,
        bool _canOverFluctuationLimit
    ) internal returns (SignedDecimal.signedDecimal memory) {
        // for amm.swapInput, the direction is in quote asset, from the perspective of Amm
        IAmm.Dir dir = (_side == Side.BUY) ? IAmm.Dir.ADD_TO_AMM : IAmm.Dir.REMOVE_FROM_AMM;
        SignedDecimal.signedDecimal memory outputAmount = MixedDecimal.fromDecimal(
            _amm.swapInput(dir, _inputAmount, _minOutputAmount, _canOverFluctuationLimit)
        );
        if (IAmm.Dir.REMOVE_FROM_AMM == dir) {
            return outputAmount.mulScalar(-1);
        }
        return outputAmount;
    }

    function transferFee(
        address _from,
        IAmm _amm,
        Decimal.decimal memory _positionNotional
    ) internal returns (Decimal.decimal memory) {
        // the logic of toll fee can be removed if the bytecode size is too large
        (Decimal.decimal memory toll, Decimal.decimal memory spread) = _amm.calcFee(
            _positionNotional
        );
        bool hasToll = toll.toUint() > 0;
        bool hasSpread = spread.toUint() > 0;
        if (hasToll || hasSpread) {
            IERC20 quoteAsset = _amm.quoteAsset();

            // transfer spread to insurance fund
            if (hasSpread) {
                _transferFrom(quoteAsset, _from, address(insuranceFund), spread);
            }

            // transfer toll to feePool
            if (hasToll) {
                require(address(feePool) != address(0), "Invalid feePool");
                _transferFrom(quoteAsset, _from, address(feePool), toll);
            }

            // fee = spread + toll
            return toll.addD(spread);
        }
    }

    function withdraw(
        IERC20 _token,
        address _receiver,
        Decimal.decimal memory _amount
    ) internal {
        // if withdraw amount is larger than entire balance of vault
        // means this trader's profit comes from other under collateral position's future loss
        // and the balance of entire vault is not enough
        // need money from IInsuranceFund to pay first, and record this prepaidBadDebt
        // in this case, insurance fund loss must be zero
        Decimal.decimal memory totalTokenBalance = _balanceOf(_token, address(this));
        if (totalTokenBalance.toUint() < _amount.toUint()) {
            Decimal.decimal memory balanceShortage = _amount.subD(totalTokenBalance);
            prepaidBadDebt[address(_token)] = prepaidBadDebt[address(_token)].addD(balanceShortage);
            insuranceFund.withdraw(_token, balanceShortage);
        }

        _transfer(_token, _receiver, _amount);
    }

    function realizeBadDebt(IERC20 _token, Decimal.decimal memory _badDebt) internal {
        Decimal.decimal memory badDebtBalance = prepaidBadDebt[address(_token)];
        if (badDebtBalance.toUint() > _badDebt.toUint()) {
            // no need to move extra tokens because vault already prepay bad debt, only need to update the numbers
            prepaidBadDebt[address(_token)] = badDebtBalance.subD(_badDebt);
        } else {
            // in order to realize all the bad debt vault need extra tokens from insuranceFund
            insuranceFund.withdraw(_token, _badDebt.subD(badDebtBalance));
            prepaidBadDebt[address(_token)] = Decimal.zero();
        }
    }

    function transferToInsuranceFund(IERC20 _token, Decimal.decimal memory _amount) internal {
        Decimal.decimal memory totalTokenBalance = _balanceOf(_token, address(this));
        Decimal.decimal memory amountToTransfer = _amount.cmp(totalTokenBalance) > 0
            ? totalTokenBalance
            : _amount;
        _transfer(_token, address(insuranceFund), amountToTransfer);
    }

    /**
     * @dev assume this will be removes soon once the guarded period has ended. caller need to ensure amm exist
     */
    function updateOpenInterestNotional(IAmm _amm, SignedDecimal.signedDecimal memory _amount)
        internal
    {
        // when cap = 0 means no cap
        uint256 cap = _amm.getOpenInterestNotionalCap().toUint();
        address ammAddr = address(_amm);
        if (cap > 0) {
            SignedDecimal.signedDecimal memory updatedOpenInterestNotional = _amount.addD(
                openInterestNotionalMap[ammAddr]
            );
            // the reduced open interest can be larger than total when profit is too high and other position are bankrupt
            if (updatedOpenInterestNotional.toInt() < 0) {
                updatedOpenInterestNotional = SignedDecimal.zero();
            }
            if (_amount.toInt() > 0) {
                require(updatedOpenInterestNotional.toUint() <= cap, "over limit");
            }
            openInterestNotionalMap[ammAddr] = updatedOpenInterestNotional.abs();
        }
    }

    //
    // INTERNAL VIEW FUNCTIONS
    //

    function calcRemainMarginWithFundingPayment(
        IAmm _amm,
        Position memory _oldPosition,
        SignedDecimal.signedDecimal memory _marginDelta
    )
        private
        view
        returns (
            Decimal.decimal memory remainMargin,
            Decimal.decimal memory badDebt,
            SignedDecimal.signedDecimal memory fundingPayment,
            SignedDecimal.signedDecimal memory latestCumulativePremiumFraction
        )
    {
        // calculate funding payment
        latestCumulativePremiumFraction = getLatestCumulativePremiumFraction(_amm);
        if (_oldPosition.size.toInt() != 0) {
            fundingPayment = latestCumulativePremiumFraction
                .subD(_oldPosition.lastUpdatedCumulativePremiumFraction)
                .mulD(_oldPosition.size);
        }

        // calculate remain margin
        SignedDecimal.signedDecimal memory signedRemainMargin = _marginDelta
            .subD(fundingPayment)
            .addD(_oldPosition.margin);

        // if remain margin is negative, set to zero and leave the rest to bad debt
        if (signedRemainMargin.toInt() < 0) {
            badDebt = signedRemainMargin.abs();
        } else {
            remainMargin = signedRemainMargin.abs();
        }
    }

    /// @param _marginWithFundingPayment margin + funding payment - bad debt
    function calcFreeCollateral(
        IAmm _amm,
        address _trader,
        Decimal.decimal memory _marginWithFundingPayment
    ) internal view returns (SignedDecimal.signedDecimal memory) {
        Position memory pos = getPosition(_amm, _trader);
        (
            SignedDecimal.signedDecimal memory unrealizedPnl,
            Decimal.decimal memory positionNotional
        ) = getPreferencePositionNotionalAndUnrealizedPnl(
                _amm,
                _trader,
                PnlPreferenceOption.MIN_PNL
            );

        // min(margin + funding, margin + funding + unrealized PnL) - position value * initMarginRatio
        SignedDecimal.signedDecimal memory accountValue = unrealizedPnl.addD(
            _marginWithFundingPayment
        );
        SignedDecimal.signedDecimal memory minCollateral = unrealizedPnl.toInt() > 0
            ? MixedDecimal.fromDecimal(_marginWithFundingPayment)
            : accountValue;

        // margin requirement
        // if holding a long position, using open notional (mapping to quote debt in Curie)
        // if holding a short position, using position notional (mapping to base debt in Curie)
        SignedDecimal.signedDecimal memory marginRequirement = pos.size.toInt() > 0
            ? MixedDecimal.fromDecimal(pos.openNotional).mulD(initMarginRatio)
            : MixedDecimal.fromDecimal(positionNotional).mulD(initMarginRatio);

        return minCollateral.subD(marginRequirement);
    }

    function getPreferencePositionNotionalAndUnrealizedPnl(
        IAmm _amm,
        address _trader,
        PnlPreferenceOption _pnlPreference
    )
        internal
        view
        returns (
            SignedDecimal.signedDecimal memory unrealizedPnl,
            Decimal.decimal memory positionNotional
        )
    {
        (
            Decimal.decimal memory spotPositionNotional,
            SignedDecimal.signedDecimal memory spotPricePnl
        ) = (getPositionNotionalAndUnrealizedPnl(_amm, _trader, PnlCalcOption.SPOT_PRICE));
        (
            Decimal.decimal memory twapPositionNotional,
            SignedDecimal.signedDecimal memory twapPricePnl
        ) = (getPositionNotionalAndUnrealizedPnl(_amm, _trader, PnlCalcOption.TWAP));

        // if MAX_PNL
        //    spotPnL >  twapPnL return (spotPnL, spotPositionNotional)
        //    spotPnL <= twapPnL return (twapPnL, twapPositionNotional)
        // if MIN_PNL
        //    spotPnL >  twapPnL return (twapPnL, twapPositionNotional)
        //    spotPnL <= twapPnL return (spotPnL, spotPositionNotional)
        (unrealizedPnl, positionNotional) = (_pnlPreference == PnlPreferenceOption.MAX_PNL) ==
            (spotPricePnl.toInt() > twapPricePnl.toInt())
            ? (spotPricePnl, spotPositionNotional)
            : (twapPricePnl, twapPositionNotional);
    }

    function getUnadjustedPosition(IAmm _amm, address _trader)
        public
        view
        returns (Position memory position)
    {
        position = ammMap[address(_amm)].positionMap[_trader];
    }

    //
    // REQUIRE FUNCTIONS
    //
    function requireAmm(IAmm _amm) private view {
        require(insuranceFund.isExistedAmm(_amm), "amm not found");
    }

    function requireNonZeroInput(Decimal.decimal memory _decimal) private pure {
        require(_decimal.toUint() != 0, "input is 0");
    }

    function requirePositionSize(SignedDecimal.signedDecimal memory _size) private pure {
        require(_size.toInt() != 0, "positionSize is 0");
    }

    function requireNotRestrictionMode(IAmm _amm) private view {
        uint256 currentBlock = block.number;
        if (currentBlock == ammMap[address(_amm)].lastRestrictionBlock) {
            require(
                getPosition(_amm, _msgSender()).blockNumber != currentBlock,
                "only one action allowed"
            );
        }
    }

    function requireMoreMarginRatio(
        SignedDecimal.signedDecimal memory _marginRatio,
        Decimal.decimal memory _baseMarginRatio,
        bool _largerThanOrEqualTo
    ) private pure {
        int256 remainingMarginRatio = _marginRatio.subD(_baseMarginRatio).toInt();
        require(
            _largerThanOrEqualTo ? remainingMarginRatio >= 0 : remainingMarginRatio < 0,
            "Margin ratio not meet criteria"
        );
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.13;

library DecimalMath {
    /// @dev Returns 1 in the fixed point representation, with `decimals` decimals.
    function unit(uint8 decimals) internal pure returns (uint256) {
        return 10**uint256(decimals);
    }

    /// @dev Adds x and y, assuming they are both fixed point with 18 decimals.
    function addd(uint256 x, uint256 y) internal pure returns (uint256) {
        return x + y;
    }

    /// @dev Subtracts y from x, assuming they are both fixed point with 18 decimals.
    function subd(uint256 x, uint256 y) internal pure returns (uint256) {
        return x - y;
    }

    /// @dev Multiplies x and y, assuming they are both fixed point with 18 digits.
    function muld(uint256 x, uint256 y) internal pure returns (uint256) {
        return muld(x, y, 18);
    }

    /// @dev Multiplies x and y, assuming they are both fixed point with `decimals` digits.
    function muld(
        uint256 x,
        uint256 y,
        uint8 decimals
    ) internal pure returns (uint256) {
        return (x * y) / (unit(decimals));
    }

    /// @dev Divides x between y, assuming they are both fixed point with 18 digits.
    function divd(uint256 x, uint256 y) internal pure returns (uint256) {
        return divd(x, y, 18);
    }

    /// @dev Divides x between y, assuming they are both fixed point with `decimals` digits.
    function divd(
        uint256 x,
        uint256 y,
        uint8 decimals
    ) internal pure returns (uint256) {
        return (x * unit(decimals)) / (y);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.13;

/// @dev Implements simple signed fixed point math add, sub, mul and div operations.
library SignedDecimalMath {
    /// @dev Returns 1 in the fixed point representation, with `decimals` decimals.
    function unit(uint8 decimals) internal pure returns (int256) {
        return int256(10**uint256(decimals));
    }

    /// @dev Adds x and y, assuming they are both fixed point with 18 decimals.
    function addd(int256 x, int256 y) internal pure returns (int256) {
        return x + y;
    }

    /// @dev Subtracts y from x, assuming they are both fixed point with 18 decimals.
    function subd(int256 x, int256 y) internal pure returns (int256) {
        return x - y;
    }

    /// @dev Multiplies x and y, assuming they are both fixed point with 18 digits.
    function muld(int256 x, int256 y) internal pure returns (int256) {
        return muld(x, y, 18);
    }

    /// @dev Multiplies x and y, assuming they are both fixed point with `decimals` digits.
    function muld(
        int256 x,
        int256 y,
        uint8 decimals
    ) internal pure returns (int256) {
        return (x * y) / unit(decimals);
    }

    /// @dev Divides x between y, assuming they are both fixed point with 18 digits.
    function divd(int256 x, int256 y) internal pure returns (int256) {
        return divd(x, y, 18);
    }

    /// @dev Divides x between y, assuming they are both fixed point with `decimals` digits.
    function divd(
        int256 x,
        int256 y,
        uint8 decimals
    ) internal pure returns (int256) {
        return (x * unit(decimals)) / (y);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.13;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Decimal} from "./Decimal.sol";

abstract contract DecimalERC20 {
    using Decimal for Decimal.decimal;

    mapping(address => uint256) private decimalMap;

    //◥◤◥◤◥◤◥◤◥◤◥◤◥◤◥◤ add state variables below ◥◤◥◤◥◤◥◤◥◤◥◤◥◤◥◤//

    //◢◣◢◣◢◣◢◣◢◣◢◣◢◣◢◣ add state variables above ◢◣◢◣◢◣◢◣◢◣◢◣◢◣◢◣//
    uint256[50] private __gap;

    //
    // INTERNAL functions
    //

    // CAUTION: do not input _from == _to s.t. this function will always fail
    function _transfer(
        IERC20 _token,
        address _to,
        Decimal.decimal memory _value
    ) internal {
        _updateDecimal(address(_token));
        Decimal.decimal memory balanceBefore = _balanceOf(_token, _to);
        uint256 roundedDownValue = _toUint(_token, _value);

        // solhint-disable avoid-low-level-calls
        (bool success, bytes memory data) = address(_token).call(
            abi.encodeWithSelector(_token.transfer.selector, _to, roundedDownValue)
        );

        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "DecimalERC20: transfer failed"
        );
        _validateBalance(_token, _to, roundedDownValue, balanceBefore);
    }

    function _transferFrom(
        IERC20 _token,
        address _from,
        address _to,
        Decimal.decimal memory _value
    ) internal {
        _updateDecimal(address(_token));
        Decimal.decimal memory balanceBefore = _balanceOf(_token, _to);
        uint256 roundedDownValue = _toUint(_token, _value);

        // solhint-disable avoid-low-level-calls
        (bool success, bytes memory data) = address(_token).call(
            abi.encodeWithSelector(_token.transferFrom.selector, _from, _to, roundedDownValue)
        );

        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "DecimalERC20: transferFrom failed"
        );
        _validateBalance(_token, _to, roundedDownValue, balanceBefore);
    }

    function _approve(
        IERC20 _token,
        address _spender,
        Decimal.decimal memory _value
    ) internal {
        _updateDecimal(address(_token));
        // to be compatible with some erc20 tokens like USDT
        __approve(_token, _spender, Decimal.zero());
        __approve(_token, _spender, _value);
    }

    //
    // VIEW
    //
    function _allowance(
        IERC20 _token,
        address _owner,
        address _spender
    ) internal view returns (Decimal.decimal memory) {
        return _toDecimal(_token, _token.allowance(_owner, _spender));
    }

    function _balanceOf(IERC20 _token, address _owner)
        internal
        view
        returns (Decimal.decimal memory)
    {
        return _toDecimal(_token, _token.balanceOf(_owner));
    }

    function _totalSupply(IERC20 _token) internal view returns (Decimal.decimal memory) {
        return _toDecimal(_token, _token.totalSupply());
    }

    function _toDecimal(IERC20 _token, uint256 _number)
        internal
        view
        returns (Decimal.decimal memory)
    {
        uint256 tokenDecimals = _getTokenDecimals(address(_token));
        if (tokenDecimals >= 18) {
            return Decimal.decimal(_number / (10**(tokenDecimals - 18)));
        }

        return Decimal.decimal(_number * (10**(uint256(18) - tokenDecimals)));
    }

    function _toUint(IERC20 _token, Decimal.decimal memory _decimal)
        internal
        view
        returns (uint256)
    {
        uint256 tokenDecimals = _getTokenDecimals(address(_token));
        if (tokenDecimals >= 18) {
            return _decimal.toUint() * (10**(tokenDecimals - 18));
        }
        return _decimal.toUint() / (10**(uint256(18) - tokenDecimals));
    }

    function _getTokenDecimals(address _token) internal view returns (uint256) {
        uint256 tokenDecimals = decimalMap[_token];
        if (tokenDecimals == 0) {
            (bool success, bytes memory data) = _token.staticcall(
                abi.encodeWithSignature("decimals()")
            );
            require(success && data.length != 0, "DecimalERC20: get decimals failed");
            tokenDecimals = abi.decode(data, (uint256));
        }
        return tokenDecimals;
    }

    //
    // PRIVATE
    //
    function _updateDecimal(address _token) private {
        uint256 tokenDecimals = _getTokenDecimals(_token);
        if (decimalMap[_token] != tokenDecimals) {
            decimalMap[_token] = tokenDecimals;
        }
    }

    function __approve(
        IERC20 _token,
        address _spender,
        Decimal.decimal memory _value
    ) private {
        // solhint-disable avoid-low-level-calls
        (bool success, bytes memory data) = address(_token).call(
            abi.encodeWithSelector(_token.approve.selector, _spender, _toUint(_token, _value))
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "DecimalERC20: approve failed"
        );
    }

    // To prevent from deflationary token, check receiver's balance is as expectation.
    function _validateBalance(
        IERC20 _token,
        address _to,
        uint256 _roundedDownValue,
        Decimal.decimal memory _balanceBefore
    ) private view {
        require(
            _balanceOf(_token, _to).cmp(
                _balanceBefore.addD(_toDecimal(_token, _roundedDownValue))
            ) == 0,
            "DecimalERC20: balance inconsistent"
        );
    }
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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.13;

import { PausableUpgradeable } from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract OwnerPausableUpgradeable is OwnableUpgradeable, PausableUpgradeable {
    // solhint-disable func-name-mixedcase
    function __OwnerPausable_init() internal onlyInitializing {
        __Ownable_init();
        __Pausable_init();
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./Decimal.sol";

contract TransferHelper {
    using Decimal for Decimal.decimal;

    mapping(address => uint256) private _decimalMap;

    function _transfer(
        IERC20 _token,
        address _to,
        Decimal.decimal memory _amount
    ) internal {
        uint256 transferValue = _toUint(address(_token), _amount);
        _token.transfer(_to, transferValue);
    }

    function _transferFrom(
        IERC20 _token,
        address _from,
        address _to,
        Decimal.decimal memory _amount
    ) internal {
        uint256 transferValue = _toUint(address(_token), _amount);
        _token.transferFrom(_from, _to, transferValue);
    }

    function _toUint(address _token, Decimal.decimal memory _amount) internal returns (uint256) {
        uint256 decimals = _getDecimals(_token);
        if (decimals >= 18) {
            return _amount.toUint() * (10**(decimals - 18));
        }
        return _amount.toUint() / (10**(18 - decimals));
    }

    function _toDecimal(address _token, uint256 _amount) internal returns (Decimal.decimal memory) {
        uint256 decimals = _getDecimals(_token);
        if (decimals >= 18) {
            return Decimal.decimal(_amount * (10**(decimals - 18)));
        }
        return Decimal.decimal(_amount * (10**(18 - decimals)));
    }

    function _getDecimals(address _token) private returns (uint256 decimals) {
        decimals = _decimalMap[_token];
        if (decimals == 0) {
            (bool success, bytes memory data) = _token.call(abi.encodeWithSignature("decimals()"));
            require(success && data.length != 0, "TransferHelper: get decimals failed");
            decimals = abi.decode(data, (uint256));
            _decimalMap[_token] = decimals;
        }
    }

    function _balanceOf(IERC20 _token, address _whom) internal returns (Decimal.decimal memory) {
        uint256 balance = _token.balanceOf(_whom);
        return _toDecimal(address(_token), balance);
    }
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