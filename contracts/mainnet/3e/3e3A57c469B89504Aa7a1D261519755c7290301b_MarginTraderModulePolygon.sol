// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.17;

import {
    MarginSwapTradeType,
    MarginCallbackData,
    ExactInputSingleParamsBase,
    ExactInputMultiParamsBase,
    MarginSwapParamsExactIn,
    ExactOutputSingleParamsBase,
    ExactOutputMultiParamsBase,
    MarginSwapParamsExactOut,
    MarginSwapParamsMultiExactIn,
    MarginSwapParamsMultiExactOut,
    ExactOutputUniswapParams
 } from "../../dataTypes/InputTypes.sol";
import "../../../../external-protocols/uniswapV3/core/interfaces/IUniswapV3Pool.sol";
import "../../../../external-protocols/uniswapV3/periphery/interfaces/ISwapRouter.sol";
import "../../../../external-protocols/uniswapV3/core/interfaces/callback/IUniswapV3SwapCallback.sol";
import "../../../uniswap/libraries/Path.sol";
import "../../../uniswap/libraries/SafeCast.sol";
import {WithStorage, LibStorage} from "../../libraries/LibStorage.sol";
import "../../../uniswap/libraries/TransferHelper.sol";
import {PoolAddress} from "../../../uniswap/libraries/PoolAddress.sol";
import {CallbackData} from "../../../uniswap/DataTypes.sol";
import {OVixHandler, IOErc20, INativeWrapper} from "./utils/OVixHandler.sol";

// solhint-disable max-line-length

/**
 * @title MarginTrader contract
 * @notice Allows users to build large margins positions with one contract interaction
 * @author Achthar
 */
contract MarginTraderModulePolygon is WithStorage, OVixHandler {
    using Path for bytes;
    using SafeCast for uint256;

    /// @dev MIN_SQRT_RATIO + 1 from Uniswap's TickMath
    uint160 private immutable MIN_SQRT_RATIO = 4295128740;
    /// @dev MAX_SQRT_RATIO - 1 from Uniswap's TickMath
    uint160 private immutable MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970341;

    modifier onlyOwner() {
        LibStorage.enforceAccountOwner();
        _;
    }

    // router is unused in this module
    constructor(address _factory, address _weth) OVixHandler(_factory, _weth, address(0)) {}

    /// @dev Returns the pool for the given token pair and fee. The pool contract may or may not exist.
    function getUniswapV3Pool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) private view returns (IUniswapV3Pool) {
        return IUniswapV3Pool(PoolAddress.computeAddress(v3Factory, PoolAddress.getPoolKey(tokenA, tokenB, fee)));
    }

    function swapBorrowExactIn(ExactInputSingleParamsBase memory _uniswapV3params) external onlyOwner returns (uint256) {
        MarginCallbackData memory data = MarginCallbackData({
            path: abi.encodePacked(_uniswapV3params.tokenIn, _uniswapV3params.fee, _uniswapV3params.tokenOut),
            user: msg.sender,
            tradeType: MarginSwapTradeType.SWAP_BORROW_SINGLE,
            amount: 0
        });

        uint160 sqrtPriceLimitX96 = _uniswapV3params.sqrtPriceLimitX96;

        bool zeroForOne = _uniswapV3params.tokenIn < _uniswapV3params.tokenOut;
        (int256 amount0, int256 amount1) = getUniswapV3Pool(_uniswapV3params.tokenIn, _uniswapV3params.tokenOut, _uniswapV3params.fee).swap(
            address(this),
            zeroForOne,
            _uniswapV3params.amountIn.toInt256(),
            sqrtPriceLimitX96 == 0 ? (zeroForOne ? MIN_SQRT_RATIO : MAX_SQRT_RATIO) : sqrtPriceLimitX96,
            abi.encode(data)
        );

        return uint256(-(zeroForOne ? amount1 : amount0));
    }

    function swapBorrowExactInMulti(ExactInputMultiParamsBase memory _uniswapV3params) external onlyOwner returns (uint256) {
        (address tokenIn, address tokenOut, uint24 fee) = _uniswapV3params.path.decodeFirstPool();

        MarginCallbackData memory data = MarginCallbackData({
            path: _uniswapV3params.path,
            tradeType: MarginSwapTradeType.SWAP_BORROW_MULTI_EXACT_IN,
            user: msg.sender,
            amount: _uniswapV3params.amountIn
        });

        uint160 sqrtPriceLimitX96 = _uniswapV3params.sqrtPriceLimitX96;

        bool zeroForOne = tokenIn < tokenOut;

        (int256 amount0, int256 amount1) = getUniswapV3Pool(tokenIn, tokenOut, fee).swap(
            address(this),
            zeroForOne,
            _uniswapV3params.amountIn.toInt256(),
            sqrtPriceLimitX96 == 0 ? (zeroForOne ? MIN_SQRT_RATIO : MAX_SQRT_RATIO) : sqrtPriceLimitX96,
            abi.encode(data)
        );

        return uint256(-(zeroForOne ? amount1 : amount0));
    }

    function swapBorrowExactOut(ExactOutputSingleParamsBase memory _uniswapV3params) external onlyOwner returns (uint256 amountIn) {
        MarginCallbackData memory data = MarginCallbackData({
            path: abi.encodePacked(_uniswapV3params.tokenIn, _uniswapV3params.fee, _uniswapV3params.tokenOut),
            user: msg.sender,
            tradeType: MarginSwapTradeType.SWAP_BORROW_SINGLE,
            amount: 0
        });

        uint160 sqrtPriceLimitX96 = _uniswapV3params.sqrtPriceLimitX96;

        bool zeroForOne = _uniswapV3params.tokenIn < _uniswapV3params.tokenOut;
        (int256 amount0, int256 amount1) = getUniswapV3Pool(_uniswapV3params.tokenIn, _uniswapV3params.tokenOut, _uniswapV3params.fee).swap(
            address(this),
            zeroForOne,
            -_uniswapV3params.amountOut.toInt256(),
            sqrtPriceLimitX96 == 0 ? (zeroForOne ? MIN_SQRT_RATIO : MAX_SQRT_RATIO) : sqrtPriceLimitX96,
            abi.encode(data)
        );
        uint256 amountOutReceived;
        (amountIn, amountOutReceived) = zeroForOne ? (uint256(amount0), uint256(-amount1)) : (uint256(amount1), uint256(-amount0));
        // it's technically possible to not receive the full output amount,
        // so if no price limit has been specified, require this possibility away
        if (sqrtPriceLimitX96 == 0) require(amountOutReceived == _uniswapV3params.amountOut);
    }

    // swaps the loan from one token (tokenIn) to another (tokenOut) provided tokenOut amount
    function swapBorrowExactOutMulti(ExactOutputMultiParamsBase memory _uniswapV3params) external onlyOwner returns (uint256) {
        (address tokenOut, address tokenIn, uint24 fee) = _uniswapV3params.path.decodeFirstPool();

        MarginCallbackData memory data = MarginCallbackData({
            path: _uniswapV3params.path,
            tradeType: MarginSwapTradeType.SWAP_BORROW_MULTI_EXACT_OUT,
            user: msg.sender,
            amount: _uniswapV3params.amountInMaximum
        });

        uint160 sqrtPriceLimitX96 = _uniswapV3params.sqrtPriceLimitX96;

        bool zeroForOne = tokenIn < tokenOut;

        (int256 amount0, int256 amount1) = getUniswapV3Pool(tokenIn, tokenOut, fee).swap(
            address(this),
            zeroForOne,
            -_uniswapV3params.amountOut.toInt256(),
            sqrtPriceLimitX96 == 0 ? (zeroForOne ? MIN_SQRT_RATIO : MAX_SQRT_RATIO) : sqrtPriceLimitX96,
            abi.encode(data)
        );

        return uint256(-(zeroForOne ? amount1 : amount0));
    }

    function swapCollateralExactIn(ExactInputSingleParamsBase memory _uniswapV3params) external onlyOwner returns (uint256) {
        MarginCallbackData memory data = MarginCallbackData({
            path: abi.encodePacked(_uniswapV3params.tokenIn, _uniswapV3params.fee, _uniswapV3params.tokenOut),
            user: msg.sender,
            tradeType: MarginSwapTradeType.SWAP_COLLATERAL_SINGLE,
            amount: 0
        });

        uint160 sqrtPriceLimitX96 = _uniswapV3params.sqrtPriceLimitX96;

        bool zeroForOne = _uniswapV3params.tokenIn < _uniswapV3params.tokenOut;
        (int256 amount0, int256 amount1) = getUniswapV3Pool(_uniswapV3params.tokenIn, _uniswapV3params.tokenOut, _uniswapV3params.fee).swap(
            address(this),
            zeroForOne,
            _uniswapV3params.amountIn.toInt256(),
            sqrtPriceLimitX96 == 0 ? (zeroForOne ? MIN_SQRT_RATIO : MAX_SQRT_RATIO) : sqrtPriceLimitX96,
            abi.encode(data)
        );

        return uint256(-(zeroForOne ? amount1 : amount0));
    }

    // swaps the collateral from one token (tokenIn) to another (tokenOut) provided tokenOut amount
    function swapCollateralExactInMulti(ExactInputMultiParamsBase memory _uniswapV3params) external onlyOwner returns (uint256) {
        (address tokenIn, address tokenOut, uint24 fee) = _uniswapV3params.path.decodeFirstPool();
        MarginCallbackData memory data = MarginCallbackData({
            path: _uniswapV3params.path,
            tradeType: MarginSwapTradeType.SWAP_COLLATERAL_MULTI_EXACT_IN,
            user: msg.sender,
            amount: _uniswapV3params.amountIn
        });

        uint160 sqrtPriceLimitX96 = _uniswapV3params.sqrtPriceLimitX96;

        bool zeroForOne = tokenIn < tokenOut;

        (int256 amount0, int256 amount1) = getUniswapV3Pool(tokenIn, tokenOut, fee).swap(
            address(this),
            zeroForOne,
            _uniswapV3params.amountIn.toInt256(),
            sqrtPriceLimitX96 == 0 ? (zeroForOne ? MIN_SQRT_RATIO : MAX_SQRT_RATIO) : sqrtPriceLimitX96,
            abi.encode(data)
        );

        return uint256(-(zeroForOne ? amount1 : amount0));
    }

    function swapCollateralExactOut(ExactOutputSingleParamsBase memory _uniswapV3params) external payable onlyOwner returns (uint256 amountIn) {
        MarginCallbackData memory data = MarginCallbackData({
            path: abi.encodePacked(_uniswapV3params.tokenIn, _uniswapV3params.fee, _uniswapV3params.tokenOut),
            user: msg.sender,
            tradeType: MarginSwapTradeType.SWAP_COLLATERAL_SINGLE,
            amount: 0
        });

        uint160 sqrtPriceLimitX96 = _uniswapV3params.sqrtPriceLimitX96;

        bool zeroForOne = _uniswapV3params.tokenIn < _uniswapV3params.tokenOut;
        (int256 amount0, int256 amount1) = getUniswapV3Pool(_uniswapV3params.tokenIn, _uniswapV3params.tokenOut, _uniswapV3params.fee).swap(
            address(this),
            zeroForOne,
            -_uniswapV3params.amountOut.toInt256(),
            sqrtPriceLimitX96 == 0 ? (zeroForOne ? MIN_SQRT_RATIO : MAX_SQRT_RATIO) : sqrtPriceLimitX96,
            abi.encode(data)
        );
        uint256 amountOutReceived;
        (amountIn, amountOutReceived) = zeroForOne ? (uint256(amount0), uint256(-amount1)) : (uint256(amount1), uint256(-amount0));
        // it's technically possible to not receive the full output amount,
        // so if no price limit has been specified, require this possibility away
        if (sqrtPriceLimitX96 == 0) require(amountOutReceived == _uniswapV3params.amountOut);
    }

    // swaps the collateral from one token (tokenIn) to another (tokenOut) provided tokenOut amount
    function swapCollateralExactOutMulti(ExactOutputMultiParamsBase memory _uniswapV3params) external onlyOwner returns (uint256) {
        (address tokenOut, address tokenIn, uint24 fee) = _uniswapV3params.path.decodeFirstPool();

        MarginCallbackData memory data = MarginCallbackData({
            path: _uniswapV3params.path,
            tradeType: MarginSwapTradeType.SWAP_COLLATERAL_MULTI_EXACT_OUT,
            user: msg.sender,
            amount: _uniswapV3params.amountInMaximum
        });

        uint160 sqrtPriceLimitX96 = _uniswapV3params.sqrtPriceLimitX96;

        bool zeroForOne = tokenIn < tokenOut;

        (int256 amount0, int256 amount1) = getUniswapV3Pool(tokenIn, tokenOut, fee).swap(
            address(this),
            zeroForOne,
            -_uniswapV3params.amountOut.toInt256(),
            sqrtPriceLimitX96 == 0 ? (zeroForOne ? MIN_SQRT_RATIO : MAX_SQRT_RATIO) : sqrtPriceLimitX96,
            abi.encode(data)
        );

        return uint256(-(zeroForOne ? amount1 : amount0));
    }

    function openMarginPositionExactOut(MarginSwapParamsExactOut memory _marginSwapParams) external onlyOwner returns (uint256 amountIn) {
        TransferHelper.safeTransferFrom(_marginSwapParams.tokenOut, msg.sender, address(this), _marginSwapParams.userAmountProvided);

        MarginCallbackData memory data = MarginCallbackData({
            path: abi.encodePacked(_marginSwapParams.tokenIn, _marginSwapParams.fee, _marginSwapParams.tokenOut),
            user: msg.sender,
            tradeType: MarginSwapTradeType.OPEN_MARGIN_SINGLE,
            amount: _marginSwapParams.userAmountProvided
        });

        uint160 sqrtPriceLimitX96 = _marginSwapParams.sqrtPriceLimitX96;

        bool zeroForOne = _marginSwapParams.tokenIn < _marginSwapParams.tokenOut;
        (int256 amount0, int256 amount1) = getUniswapV3Pool(_marginSwapParams.tokenIn, _marginSwapParams.tokenOut, _marginSwapParams.fee).swap(
            address(this),
            zeroForOne,
            -_marginSwapParams.amountOut.toInt256(),
            sqrtPriceLimitX96 == 0 ? (zeroForOne ? MIN_SQRT_RATIO : MAX_SQRT_RATIO) : sqrtPriceLimitX96,
            abi.encode(data)
        );
        uint256 amountOutReceived;
        (amountIn, amountOutReceived) = zeroForOne ? (uint256(amount0), uint256(-amount1)) : (uint256(amount1), uint256(-amount0));
        // it's technically possible to not receive the full output amount,
        // so if no price limit has been specified, require this possibility away
        if (sqrtPriceLimitX96 == 0) require(amountOutReceived == _marginSwapParams.amountOut);
    }

    function openMarginPositionExactIn(MarginSwapParamsExactIn memory _marginSwapParams) external onlyOwner returns (uint256) {
        TransferHelper.safeTransferFrom(_marginSwapParams.tokenOut, msg.sender, address(this), _marginSwapParams.userAmountProvided);

        MarginCallbackData memory data = MarginCallbackData({
            path: abi.encodePacked(_marginSwapParams.tokenIn, _marginSwapParams.fee, _marginSwapParams.tokenOut),
            user: msg.sender,
            tradeType: MarginSwapTradeType.OPEN_MARGIN_SINGLE,
            amount: _marginSwapParams.userAmountProvided
        });

        uint160 sqrtPriceLimitX96 = _marginSwapParams.sqrtPriceLimitX96;

        bool zeroForOne = _marginSwapParams.tokenIn < _marginSwapParams.tokenOut;
        (int256 amount0, int256 amount1) = getUniswapV3Pool(_marginSwapParams.tokenIn, _marginSwapParams.tokenOut, _marginSwapParams.fee).swap(
            address(this),
            zeroForOne,
            _marginSwapParams.amountIn.toInt256(),
            sqrtPriceLimitX96 == 0 ? (zeroForOne ? MIN_SQRT_RATIO : MAX_SQRT_RATIO) : sqrtPriceLimitX96,
            abi.encode(data)
        );

        return uint256(-(zeroForOne ? amount1 : amount0));
    }

    // ================= Trimming Positions ==========================
    // decrease the margin position - use the collateral (tokenIn) to pay back a borrow (tokenOut)
    function trimMarginPositionExactIn(MarginSwapParamsExactIn memory _marginSwapParams) external onlyOwner returns (uint256) {
        MarginCallbackData memory data = MarginCallbackData({
            path: abi.encodePacked(_marginSwapParams.tokenIn, _marginSwapParams.fee, _marginSwapParams.tokenOut),
            tradeType: MarginSwapTradeType.TRIM_MARGIN_SINGLE,
            user: msg.sender,
            amount: 0
        });

        uint160 sqrtPriceLimitX96 = _marginSwapParams.sqrtPriceLimitX96;

        bool zeroForOne = _marginSwapParams.tokenIn < _marginSwapParams.tokenOut;
        (int256 amount0, int256 amount1) = getUniswapV3Pool(_marginSwapParams.tokenIn, _marginSwapParams.tokenOut, _marginSwapParams.fee).swap(
            address(this),
            zeroForOne,
            _marginSwapParams.amountIn.toInt256(),
            sqrtPriceLimitX96 == 0 ? (zeroForOne ? MIN_SQRT_RATIO : MAX_SQRT_RATIO) : sqrtPriceLimitX96,
            abi.encode(data)
        );

        return uint256(-(zeroForOne ? amount1 : amount0));
    }

    function trimMarginPositionExactOut(MarginSwapParamsExactOut memory _marginSwapParams) external onlyOwner returns (uint256 amountIn) {
        MarginCallbackData memory data = MarginCallbackData({
            path: abi.encodePacked(_marginSwapParams.tokenIn, _marginSwapParams.fee, _marginSwapParams.tokenOut),
            tradeType: MarginSwapTradeType.TRIM_MARGIN_SINGLE,
            user: msg.sender,
            amount: 0
        });

        uint160 sqrtPriceLimitX96 = _marginSwapParams.sqrtPriceLimitX96;

        bool zeroForOne = _marginSwapParams.tokenIn < _marginSwapParams.tokenOut;
        (int256 amount0, int256 amount1) = getUniswapV3Pool(_marginSwapParams.tokenIn, _marginSwapParams.tokenOut, _marginSwapParams.fee).swap(
            address(this),
            zeroForOne,
            -_marginSwapParams.amountOut.toInt256(),
            sqrtPriceLimitX96 == 0 ? (zeroForOne ? MIN_SQRT_RATIO : MAX_SQRT_RATIO) : sqrtPriceLimitX96,
            abi.encode(data)
        );
        uint256 amountOutReceived;
        (amountIn, amountOutReceived) = zeroForOne ? (uint256(amount0), uint256(-amount1)) : (uint256(amount1), uint256(-amount0));
        // it's technically possible to not receive the full output amount,
        // so if no price limit has been specified, require this possibility away
        if (sqrtPriceLimitX96 == 0) require(amountOutReceived == _marginSwapParams.amountOut);
    }

    // increase the margin position - borrow (tokenIn) and sell it against collateral (tokenOut)
    // the user provides the debt amount as input
    function openMarginPositionExactInMulti(MarginSwapParamsMultiExactIn memory _marginSwapParams) external onlyOwner returns (uint256) {
        (address tokenIn, address tokenOut, uint24 fee) = _marginSwapParams.path.decodeFirstPool();

        TransferHelper.safeTransferFrom(_marginSwapParams.path.getLastToken(), msg.sender, address(this), _marginSwapParams.userAmountProvided);

        MarginCallbackData memory data = MarginCallbackData({
            path: _marginSwapParams.path,
            tradeType: MarginSwapTradeType.OPEN_MARGIN_MULTI_EXACT_IN,
            user: msg.sender,
            amount: _marginSwapParams.userAmountProvided
        });

        uint160 sqrtPriceLimitX96 = _marginSwapParams.sqrtPriceLimitX96;

        bool zeroForOne = tokenIn < tokenOut;
        (int256 amount0, int256 amount1) = getUniswapV3Pool(tokenIn, tokenOut, fee).swap(
            address(this),
            zeroForOne,
            _marginSwapParams.amountIn.toInt256(),
            sqrtPriceLimitX96 == 0 ? (zeroForOne ? MIN_SQRT_RATIO : MAX_SQRT_RATIO) : sqrtPriceLimitX96,
            abi.encode(data)
        );

        return uint256(-(zeroForOne ? amount1 : amount0));
    }

    // increase the margin position - borrow (tokenIn) and sell it against collateral (tokenOut)
    // the user provides the collateral amount as input
    function openMarginPositionExactOutMulti(MarginSwapParamsMultiExactOut memory _marginSwapParams) external onlyOwner returns (uint256 amountIn) {
        (address tokenOut, address tokenIn, uint24 fee) = _marginSwapParams.path.decodeFirstPool();

        TransferHelper.safeTransferFrom(tokenOut, msg.sender, address(this), _marginSwapParams.userAmountProvided);

        MarginCallbackData memory data = MarginCallbackData({
            path: _marginSwapParams.path,
            tradeType: MarginSwapTradeType.OPEN_MARGIN_MULTI_EXACT_OUT,
            user: msg.sender,
            amount: _marginSwapParams.userAmountProvided
        });

        uint160 sqrtPriceLimitX96 = _marginSwapParams.sqrtPriceLimitX96;

        bool zeroForOne = tokenIn < tokenOut;
        (int256 amount0, int256 amount1) = getUniswapV3Pool(tokenIn, tokenOut, fee).swap(
            address(this),
            zeroForOne,
            -_marginSwapParams.amountOut.toInt256(),
            sqrtPriceLimitX96 == 0 ? (zeroForOne ? MIN_SQRT_RATIO : MAX_SQRT_RATIO) : sqrtPriceLimitX96,
            abi.encode(data)
        );
        uint256 amountOutReceived;
        (amountIn, amountOutReceived) = zeroForOne ? (uint256(amount0), uint256(-amount1)) : (uint256(amount1), uint256(-amount0));
        // it's technically possible to not receive the full output amount,
        // so if no price limit has been specified, require this possibility away
        if (sqrtPriceLimitX96 == 0) require(amountOutReceived == _marginSwapParams.amountOut);
    }

    // decrease the margin position - use the collateral (tokenIn) to pay back a borrow (tokenOut)
    function trimMarginPositionExactInMulti(MarginSwapParamsMultiExactIn memory _marginSwapParams) external onlyOwner returns (uint256) {
        (address tokenIn, address tokenOut, uint24 fee) = _marginSwapParams.path.decodeFirstPool();

        MarginCallbackData memory data = MarginCallbackData({
            path: _marginSwapParams.path,
            tradeType: MarginSwapTradeType.TRIM_MARGIN_MULTI_EXACT_IN,
            user: msg.sender,
            amount: 0
        });

        uint160 sqrtPriceLimitX96 = _marginSwapParams.sqrtPriceLimitX96;

        bool zeroForOne = tokenIn < tokenOut;
        (int256 amount0, int256 amount1) = getUniswapV3Pool(tokenIn, tokenOut, fee).swap(
            address(this),
            zeroForOne,
            _marginSwapParams.amountIn.toInt256(),
            sqrtPriceLimitX96 == 0 ? (zeroForOne ? MIN_SQRT_RATIO : MAX_SQRT_RATIO) : sqrtPriceLimitX96,
            abi.encode(data)
        );

        return uint256(-(zeroForOne ? amount1 : amount0));
    }

    function trimMarginPositionExactOutMulti(MarginSwapParamsMultiExactOut memory _marginSwapParams) external onlyOwner returns (uint256 amountIn) {
        (address tokenOut, address tokenIn, uint24 fee) = _marginSwapParams.path.decodeFirstPool();

        MarginCallbackData memory data = MarginCallbackData({
            path: _marginSwapParams.path,
            tradeType: MarginSwapTradeType.TRIM_MARGIN_MULTI_EXACT_OUT,
            user: msg.sender,
            amount: type(uint256).max
        });

        uint160 sqrtPriceLimitX96 = _marginSwapParams.sqrtPriceLimitX96;

        bool zeroForOne = tokenIn < tokenOut;
        (int256 amount0, int256 amount1) = getUniswapV3Pool(tokenIn, tokenOut, fee).swap(
            address(this),
            zeroForOne,
            -_marginSwapParams.amountOut.toInt256(),
            sqrtPriceLimitX96 == 0 ? (zeroForOne ? MIN_SQRT_RATIO : MAX_SQRT_RATIO) : sqrtPriceLimitX96,
            abi.encode(data)
        );
        uint256 amountOutReceived;
        (amountIn, amountOutReceived) = zeroForOne ? (uint256(amount0), uint256(-amount1)) : (uint256(amount1), uint256(-amount0));
        // it's technically possible to not receive the full output amount,
        // so if no price limit has been specified, require this possibility away
        if (sqrtPriceLimitX96 == 0) require(amountOutReceived == _marginSwapParams.amountOut);
    }

    // increase the margin position - borrow (tokenIn) and sell it against collateral (tokenOut)
    // the user sends the collateral amount in ETH to this address
    function openMarginPositionExactInMultiToETH(MarginSwapParamsMultiExactIn memory _marginSwapParams) external payable onlyOwner returns (uint256) {
        (address tokenIn, address tokenOut, uint24 fee) = _marginSwapParams.path.decodeFirstPool();
        INativeWrapper(nativeWrapper).deposit{value: msg.value}();
        MarginCallbackData memory data = MarginCallbackData({
            path: _marginSwapParams.path,
            tradeType: MarginSwapTradeType.OPEN_MARGIN_MULTI_EXACT_IN,
            user: msg.sender,
            amount: msg.value
        });

        uint160 sqrtPriceLimitX96 = _marginSwapParams.sqrtPriceLimitX96;

        bool zeroForOne = tokenIn < tokenOut;
        (int256 amount0, int256 amount1) = getUniswapV3Pool(tokenIn, tokenOut, fee).swap(
            address(this),
            zeroForOne,
            _marginSwapParams.amountIn.toInt256(),
            sqrtPriceLimitX96 == 0 ? (zeroForOne ? MIN_SQRT_RATIO : MAX_SQRT_RATIO) : sqrtPriceLimitX96,
            abi.encode(data)
        );

        return uint256(-(zeroForOne ? amount1 : amount0));
    }

    // increase the margin position - borrow (tokenIn) and sell it against collateral (tokenOut)
    // the user sends the collateral amount in ETH to this address
    function openMarginPositionExactOutMultiToETH(MarginSwapParamsMultiExactOut memory _marginSwapParams)
        external
        payable
        onlyOwner
        returns (uint256 amountIn)
    {
        (address tokenOut, address tokenIn, uint24 fee) = _marginSwapParams.path.decodeFirstPool();
        INativeWrapper(nativeWrapper).deposit{value: msg.value}();
        MarginCallbackData memory data = MarginCallbackData({
            path: _marginSwapParams.path,
            tradeType: MarginSwapTradeType.OPEN_MARGIN_MULTI_EXACT_OUT,
            user: msg.sender,
            amount: msg.value
        });

        uint160 sqrtPriceLimitX96 = _marginSwapParams.sqrtPriceLimitX96;

        bool zeroForOne = tokenIn < tokenOut;
        (int256 amount0, int256 amount1) = getUniswapV3Pool(tokenIn, tokenOut, fee).swap(
            address(this),
            zeroForOne,
            -_marginSwapParams.amountOut.toInt256(),
            sqrtPriceLimitX96 == 0 ? (zeroForOne ? MIN_SQRT_RATIO : MAX_SQRT_RATIO) : sqrtPriceLimitX96,
            abi.encode(data)
        );
        uint256 amountOutReceived;
        (amountIn, amountOutReceived) = zeroForOne ? (uint256(amount0), uint256(-amount1)) : (uint256(amount1), uint256(-amount0));
        // it's technically possible to not receive the full output amount,
        // so if no price limit has been specified, require this possibility away
        if (sqrtPriceLimitX96 == 0) require(amountOutReceived == _marginSwapParams.amountOut);
    }

    function openMarginPositionExactOutToETH(MarginSwapParamsExactOut memory _marginSwapParams)
        external
        payable
        onlyOwner
        returns (uint256 amountIn)
    {
        MarginCallbackData memory data = MarginCallbackData({
            path: abi.encodePacked(_marginSwapParams.tokenIn, _marginSwapParams.fee, _marginSwapParams.tokenOut),
            user: msg.sender,
            tradeType: MarginSwapTradeType.OPEN_MARGIN_SINGLE,
            amount: msg.value
        });

        uint160 sqrtPriceLimitX96 = _marginSwapParams.sqrtPriceLimitX96;

        bool zeroForOne = _marginSwapParams.tokenIn < _marginSwapParams.tokenOut;
        (int256 amount0, int256 amount1) = getUniswapV3Pool(_marginSwapParams.tokenIn, _marginSwapParams.tokenOut, _marginSwapParams.fee).swap(
            address(this),
            zeroForOne,
            -_marginSwapParams.amountOut.toInt256(),
            sqrtPriceLimitX96 == 0 ? (zeroForOne ? MIN_SQRT_RATIO : MAX_SQRT_RATIO) : sqrtPriceLimitX96,
            abi.encode(data)
        );
        uint256 amountOutReceived;
        (amountIn, amountOutReceived) = zeroForOne ? (uint256(amount0), uint256(-amount1)) : (uint256(amount1), uint256(-amount0));
        // it's technically possible to not receive the full output amount,
        // so if no price limit has been specified, require this possibility away
        if (sqrtPriceLimitX96 == 0) require(amountOutReceived == _marginSwapParams.amountOut);
    }

    function openMarginPositionExactInToETH(MarginSwapParamsExactIn memory _marginSwapParams) external payable onlyOwner returns (uint256) {
        INativeWrapper(nativeWrapper).deposit{value: msg.value}();
        MarginCallbackData memory data = MarginCallbackData({
            path: abi.encodePacked(_marginSwapParams.tokenIn, _marginSwapParams.fee, _marginSwapParams.tokenOut),
            user: msg.sender,
            tradeType: MarginSwapTradeType.OPEN_MARGIN_SINGLE,
            amount: msg.value
        });

        uint160 sqrtPriceLimitX96 = _marginSwapParams.sqrtPriceLimitX96;

        bool zeroForOne = _marginSwapParams.tokenIn < _marginSwapParams.tokenOut;
        (int256 amount0, int256 amount1) = getUniswapV3Pool(_marginSwapParams.tokenIn, _marginSwapParams.tokenOut, _marginSwapParams.fee).swap(
            address(this),
            zeroForOne,
            _marginSwapParams.amountIn.toInt256(),
            sqrtPriceLimitX96 == 0 ? (zeroForOne ? MIN_SQRT_RATIO : MAX_SQRT_RATIO) : sqrtPriceLimitX96,
            abi.encode(data)
        );

        return uint256(-(zeroForOne ? amount1 : amount0));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// Collection of data sets to be en- and de-coded for uniswapV3 callbacks

struct CallbackData {
    // the second layer data contains the actual data
    bytes data;
    // the trade type determines which trade tye and therefore which data type
    // the data parameter has
    uint256 transactionType;
}

// the standard uniswap input
struct SwapCallbackData {
    bytes path;
    address payer;
}

// margin swap input
struct MarginSwapCallbackData {
    address tokenIn;
    address tokenOut;
    // determines how to interact with the lending protocol
    uint256 tradeType;
    // determines the specific money market protocol
    uint256 moneyMarketProtocolId;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

enum MarginSwapTradeType {
    // One-sided loan and collateral operations
    SWAP_BORROW_SINGLE,
    SWAP_COLLATERAL_SINGLE,
    SWAP_BORROW_MULTI_EXACT_IN,
    SWAP_BORROW_MULTI_EXACT_OUT,
    SWAP_COLLATERAL_MULTI_EXACT_IN,
    SWAP_COLLATERAL_MULTI_EXACT_OUT,
    // Two-sided operations
    OPEN_MARGIN_SINGLE,
    TRIM_MARGIN_SINGLE,
    OPEN_MARGIN_MULTI_EXACT_IN,
    OPEN_MARGIN_MULTI_EXACT_OUT,
    TRIM_MARGIN_MULTI_EXACT_IN,
    TRIM_MARGIN_MULTI_EXACT_OUT,
    // the following are only used internally
    UNISWAP_EXACT_IN,
    UNISWAP_EXACT_OUT,
    UNISWAP_EXACT_OUT_BORROW,
    UNISWAP_EXACT_OUT_WITHDRAW
}

// margin swap input
struct MarginCallbackData {
    bytes path;
    address user;
    // determines how to interact with the lending protocol
    MarginSwapTradeType tradeType;
    // amount variable used for exact out swaps
    uint256 amount;
}

struct ExactInputSingleParamsBase {
    address tokenIn;
    address tokenOut;
    uint24 fee;
    uint256 amountIn;
    uint256 amountOutMinimum;
    uint160 sqrtPriceLimitX96;
}

struct ExactInputMultiParamsBase {
    bytes path;
    uint256 amountIn;
    uint256 amountOutMinimum;
    uint160 sqrtPriceLimitX96;
}

struct MarginSwapParamsExactIn {
    address tokenIn;
    address tokenOut;
    uint24 fee;
    uint256 userAmountProvided;
    uint256 amountIn;
    uint160 sqrtPriceLimitX96;
}

struct ExactOutputSingleParamsBase {
    address tokenIn;
    address tokenOut;
    uint24 fee;
    uint256 amountOut;
    uint256 amountInMaximum;
    uint160 sqrtPriceLimitX96;
}

struct ExactOutputMultiParamsBase {
    bytes path;
    uint256 amountOut;
    uint256 amountInMaximum;
    uint160 sqrtPriceLimitX96;
}

struct MarginSwapParamsExactOut {
    address tokenIn;
    address tokenOut;
    uint24 fee;
    uint256 userAmountProvided;
    uint256 amountOut;
    uint160 sqrtPriceLimitX96;
}

struct MarginSwapParamsMultiExactIn {
    bytes path;
    uint256 userAmountProvided;
    uint256 amountIn;
    uint160 sqrtPriceLimitX96;
}

struct MarginSwapParamsMultiExactOut {
    bytes path;
    uint256 userAmountProvided;
    uint256 amountOut;
    uint160 sqrtPriceLimitX96;
}

struct ExactOutputUniswapParams {
    bytes path;
    address recipient;
    uint256 amountOut;
    address user;
    uint256 maximumInputAmount;
    MarginSwapTradeType tradeType;
}

struct ExactInputUniswapParams {
    bytes path;
    address recipient;
    uint256 amountIn;
    address user;
    uint256 amountOutMinimum;
    MarginSwapTradeType tradeType;
}

// money market input parameters

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0;

/// @title Safe casting methods
/// @notice Contains methods for safely casting between types
library SafeCast {
    /// @notice Cast a uint256 to a uint160, revert on overflow
    /// @param y The uint256 to be downcasted
    /// @return z The downcasted integer, now type uint160
    function toUint160(uint256 y) internal pure returns (uint160 z) {
        require((z = uint160(y)) == y);
    }

    /// @notice Cast a int256 to a int128, revert on overflow or underflow
    /// @param y The int256 to be downcasted
    /// @return z The downcasted integer, now type int128
    function toInt128(int256 y) internal pure returns (int128 z) {
        require((z = int128(y)) == y);
    }

    /// @notice Cast a uint256 to a int256, revert on overflow
    /// @param y The uint256 to be casted
    /// @return z The casted integer, now type int256
    function toInt256(uint256 y) internal pure returns (int256 z) {
        require(y < 2**255);
        z = int256(y);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.17;

import '../../../interfaces/IERC20.sol';

library TransferHelper {
    /// @notice Transfers tokens from the targeted address to the given destination
    /// @notice Errors with 'STF' if transfer fails
    /// @param token The contract address of the token to be transferred
    /// @param from The originating address from which the tokens will be transferred
    /// @param to The destination address of the transfer
    /// @param value The amount to be transferred
    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'STF');
    }

    /// @notice Transfers tokens from msg.sender to a recipient
    /// @dev Errors with ST if transfer fails
    /// @param token The contract address of the token which will be transferred
    /// @param to The recipient of the transfer
    /// @param value The value of the transfer
    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'ST');
    }

    /// @notice Approves the stipulated contract to spend the given allowance in the given token
    /// @dev Errors with 'SA' if transfer fails
    /// @param token The contract address of the token to be approved
    /// @param to The target of the approval
    /// @param value The amount of the given token the target will be allowed to spend
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.approve.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'SA');
    }

    /// @notice Transfers ETH to the recipient address
    /// @dev Fails with `STE`
    /// @param to The destination of the transfer
    /// @param value The value to be transferred
    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'STE');
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

// We do not use an array of stucts to avoid pointer conflicts

struct GeneralStorage {
    address factory;
    address moduleProvider;
}

struct UserAccountStorage {
    address previousAccountOwner;
    address accountOwner;
    mapping(address => bool) managers;
    string accountName;
    uint256 creationTimestamp;
}

struct DataProviderStorage {
    address dataProvider;
}

library LibStorage {
    // Storage are structs where the data gets updated throughout the lifespan of the project
    bytes32 constant DATA_PROVIDER_STORAGE = keccak256("1DeltaAccount.storage.dataProvider");
    bytes32 constant GENERAL_STORAGE = keccak256("1DeltaAccount.storage.general");
    bytes32 constant USER_ACCOUNT_STORAGE = keccak256("1DeltaAccount.storage.user");
    bytes32 constant UNISWAP_STORAGE = keccak256("1DeltaAccount.storage.uniswap");

    function dataProviderStorage() internal pure returns (DataProviderStorage storage ps) {
        bytes32 position = DATA_PROVIDER_STORAGE;
        assembly {
            ps.slot := position
        }
    }

    function generalStorage() internal pure returns (GeneralStorage storage gs) {
        bytes32 position = GENERAL_STORAGE;
        assembly {
            gs.slot := position
        }
    }

    function userAccountStorage() internal pure returns (UserAccountStorage storage us) {
        bytes32 position = USER_ACCOUNT_STORAGE;
        assembly {
            us.slot := position
        }
    }

    function enforceManager() internal view {
        require(userAccountStorage().managers[msg.sender], "Only manager can interact.");
    }

    function enforceAccountOwner() internal view {
        require(msg.sender == userAccountStorage().accountOwner, "Only the account owner can interact.");
    }
}

/**
 * The `WithStorage` contract provides a base contract for Module contracts to inherit.
 *
 * It mainly provides internal helpers to access the storage structs, which reduces
 * calls like `LibStorage.treasuryStorage()` to just `ts()`.
 *
 * To understand why the storage stucts must be accessed using a function instead of a
 * state variable, please refer to the documentation above `LibStorage` in this file.
 */
abstract contract WithStorage {
    function ps() internal pure returns (DataProviderStorage storage) {
        return LibStorage.dataProviderStorage();
    }

    function gs() internal pure returns (GeneralStorage storage) {
        return LibStorage.generalStorage();
    }

    function us() internal pure returns (UserAccountStorage storage) {
        return LibStorage.userAccountStorage();
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.17;

import "./BytesLib.sol";

/// @title Functions for manipulating path data for multihop swaps
library Path {
    using BytesLib for bytes;

    /// @dev The length of the bytes encoded address
    uint256 private constant ADDR_SIZE = 20;
    /// @dev The length of the bytes encoded fee
    uint256 private constant FEE_SIZE = 3;

    /// @dev The offset of a single token address and pool fee
    uint256 private constant NEXT_OFFSET = ADDR_SIZE + FEE_SIZE;
    /// @dev The offset of an encoded pool key
    uint256 private constant POP_OFFSET = NEXT_OFFSET + ADDR_SIZE;
    /// @dev The minimum length of an encoding that contains 2 or more pools
    uint256 private constant MULTIPLE_POOLS_MIN_LENGTH = POP_OFFSET + NEXT_OFFSET;

    /// @notice Returns true iff the path contains two or more pools
    /// @param path The encoded swap path
    /// @return True if path contains two or more pools, otherwise false
    function hasMultiplePools(bytes memory path) internal pure returns (bool) {
        return path.length >= MULTIPLE_POOLS_MIN_LENGTH;
    }

    /// @notice Returns the number of pools in the path
    /// @param path The encoded swap path
    /// @return The number of pools in the path
    function numPools(bytes memory path) internal pure returns (uint256) {
        // Ignore the first token address. From then on every fee and token offset indicates a pool.
        return ((path.length - ADDR_SIZE) / NEXT_OFFSET);
    }

    /// @notice Decodes the first pool in path
    /// @param path The bytes encoded swap path
    /// @return tokenA The first token of the given pool
    /// @return tokenB The second token of the given pool
    /// @return fee The fee level of the pool
    function decodeFirstPool(bytes memory path)
        internal
        pure
        returns (
            address tokenA,
            address tokenB,
            uint24 fee
        )
    {
        tokenA = path.toAddress(0);
        fee = path.toUint24(ADDR_SIZE);
        tokenB = path.toAddress(NEXT_OFFSET);
    }

    /// @notice Gets the segment corresponding to the first pool in the path
    /// @param path The bytes encoded swap path
    /// @return The segment containing all data necessary to target the first pool in the path
    function getFirstPool(bytes memory path) internal pure returns (bytes memory) {
        return path.slice(0, POP_OFFSET);
    }

    /// @notice Skips a token + fee element from the buffer and returns the remainder
    /// @param path The swap path
    /// @return The remaining token + fee elements in the path
    function skipToken(bytes memory path) internal pure returns (bytes memory) {
        return path.slice(NEXT_OFFSET, path.length - NEXT_OFFSET);
    }

    function getLastToken(bytes memory path) internal pure returns (address) {
        return path.toAddress(path.length - ADDR_SIZE);
    }

    function getFirstToken(bytes memory path) internal pure returns (address) {
        return path.toAddress(0);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.17;

/// @title Provides functions for deriving a pool address from the factory, tokens, and the fee
library PoolAddress {
    bytes32 internal constant POOL_INIT_CODE_HASH = 0xe34f199b19b2b4f47f68442619d555527d244f78a3297ea89325f843f87b8b54;

    /// @notice The identifying key of the pool
    struct PoolKey {
        address token0;
        address token1;
        uint24 fee;
    }

    /// @notice Returns PoolKey: the ordered tokens with the matched fee levels
    /// @param tokenA The first token of a pool, unsorted
    /// @param tokenB The second token of a pool, unsorted
    /// @param fee The fee level of the pool
    /// @return Poolkey The pool details with ordered token0 and token1 assignments
    function getPoolKey(
        address tokenA,
        address tokenB,
        uint24 fee
    ) internal pure returns (PoolKey memory) {
        if (tokenA > tokenB) (tokenA, tokenB) = (tokenB, tokenA);
        return PoolKey({token0: tokenA, token1: tokenB, fee: fee});
    }

    /// @notice Deterministically computes the pool address given the factory and PoolKey
    /// @param factory The Uniswap V3 factory contract address
    /// @param key The PoolKey
    /// @return pool The contract address of the V3 pool
    function computeAddress(address factory, PoolKey memory key) internal pure returns (address pool) {
        require(key.token0 < key.token1);
        pool = address(uint160(
            uint256(
                keccak256(
                    abi.encodePacked(
                        hex'ff',
                        factory,
                        keccak256(abi.encode(key.token0, key.token1, key.fee)),
                        POOL_INIT_CODE_HASH
                    )
                )
            ))
        );
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

import './pool/IUniswapV3PoolImmutables.sol';
import './pool/IUniswapV3PoolState.sol';
import './pool/IUniswapV3PoolDerivedState.sol';
import './pool/IUniswapV3PoolActions.sol';
import './pool/IUniswapV3PoolOwnerActions.sol';
import './pool/IUniswapV3PoolEvents.sol';

/// @title The interface for a Uniswap V3 Pool
/// @notice A Uniswap pool facilitates swapping and automated market making between any two assets that strictly conform
/// to the ERC20 specification
/// @dev The pool interface is broken up into many smaller pieces
interface IUniswapV3Pool is
    IUniswapV3PoolImmutables,
    IUniswapV3PoolState,
    IUniswapV3PoolDerivedState,
    IUniswapV3PoolActions,
    IUniswapV3PoolOwnerActions,
    IUniswapV3PoolEvents
{

}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

import '../../core/interfaces/callback/IUniswapV3SwapCallback.sol';

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface ISwapRouter is IUniswapV3SwapCallback {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls IUniswapV3PoolActions#swap must implement this interface
interface IUniswapV3SwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity 0.8.17;

/******************************************************************************\
* Author: Achthar
/******************************************************************************/

import {
    IOErc20, 
    IOMatic, 
    OTokenData
    } from "../../data-holder/polygon/OTokenData.sol";
import {INativeWrapper} from "../../../interfaces/INativeWrapper.sol";
import {TransferHelper} from "../../../../uniswap/libraries/TransferHelper.sol";
import {WithStorage} from "../../../libraries/LibStorage.sol";

// solhint-disable max-line-length

/// @title Module for handling transfers from and to the Compound protocol on Goerli network
abstract contract OVixHandler is OTokenData, WithStorage {
    address internal immutable v3Factory;
    address internal immutable nativeWrapper;
    address internal immutable router;

    constructor(
        address _factory,
        address _weth,
        address _router
    ) OTokenData() {
        v3Factory = _factory;
        nativeWrapper = _weth;
        router = _router;
    }

    /// @param token The token to pay
    /// @param payer The entity that must pay
    /// @param recipient The entity that will receive payment
    /// @param value The amount to pay
    function pay(
        address token,
        address payer,
        address recipient,
        uint256 value
    ) internal {
        address _nativeWrapper = nativeWrapper;
        if (token == _nativeWrapper && address(this).balance >= value) {
            // pay with nativeWrapper
            INativeWrapper(_nativeWrapper).deposit{value: value}(); // wrap only what is needed to pay
            INativeWrapper(_nativeWrapper).transfer(recipient, value);
        } else if (payer == address(this)) {
            // pay with tokens already in the contract (for the exact input multihop case)
            TransferHelper.safeTransfer(token, recipient, value);
        } else {
            // pull payment
            TransferHelper.safeTransferFrom(token, payer, recipient, value);
        }
    }

    /// @notice the Compound protocol uses cETH for ETH deposits
    /// as Uniswap uses only WETH in their interactions, we have to withdraw the ETH from
    /// the WETH contract to then deposit (mint cETH) on Compound
    /// @param token The token to pay
    /// @param valueToDeposit The amount to pay
    function mintPrivate(address token, uint256 valueToDeposit) internal {
        address _nativeWrapper = nativeWrapper;
        if (token == _nativeWrapper) {
            // withdraw WETH
            INativeWrapper(_nativeWrapper).withdraw(valueToDeposit); // unwrap
            // deposit ETH
            cEther().mint{value: valueToDeposit}();
        } else {
            // deposit regular ERC20
            cToken(token).mint(valueToDeposit);
        }
    }

    /// @notice the Compound protocol uses cETH for ETH deposits
    /// as Uniswap uses only WETH in their interactions, we have to withdraw the ETH from
    /// the WETH contract to then deposit (mint cETH) on Compound
    /// @param token The token to pay
    /// @param valueToWithdraw The amount to pay
    function redeemPrivate(
        address token,
        uint256 valueToWithdraw,
        address recipient
    ) internal {
        address _nativeWrapper = nativeWrapper;
        if (token == _nativeWrapper) {
            // withdraw ETH from cETH
            cEther().redeemUnderlying(valueToWithdraw);
            // withdraw WETH
            INativeWrapper(_nativeWrapper).deposit{value: valueToWithdraw}(); // unwrap
            // transfer WETH
            TransferHelper.safeTransfer(_nativeWrapper, recipient, valueToWithdraw);
        } else {
            // deposit regular ERC20
            cToken(token).redeemUnderlying(valueToWithdraw);
            // repay ERC20
            TransferHelper.safeTransfer(token, recipient, valueToWithdraw);
        }
    }

    /// @notice the Compound protocol uses cETH for ETH deposits
    /// as Uniswap uses only WETH in their interactions, we have to withdraw the ETH from
    /// the WETH contract to then deposit (mint cETH) on Compound
    /// @param token The token to pay
    /// @param valueToBorrow The amount to borrow
    function borrowPrivate(
        address token,
        uint256 valueToBorrow,
        address recipient
    ) internal {
        address _nativeWrapper = nativeWrapper;
        if (token == _nativeWrapper) {
            // borrow ETH
            cEther().borrow(valueToBorrow);
            // deposit ETH for wETH
            INativeWrapper(_nativeWrapper).deposit{value: valueToBorrow}();
            // transfer WETH
            TransferHelper.safeTransfer(_nativeWrapper, recipient, valueToBorrow);
        } else {
            // borrow regular ERC20
            cToken(token).borrow(valueToBorrow);
            // transfer ERC20
            TransferHelper.safeTransfer(token, recipient, valueToBorrow);
        }
    }

    /// @notice the Compound protocol uses cETH for ETH deposits
    /// as Uniswap uses only WETH in their interactions, we have to withdraw the ETH from
    /// the WETH contract to then deposit (mint cETH) on Compound
    /// @param token The token to pay
    /// @param valueToRepay The amount to repay
    function repayPrivate(address token, uint256 valueToRepay) internal {
        address _nativeWrapper = nativeWrapper;
        if (token == _nativeWrapper) {
            // withdraw WETH
            INativeWrapper(_nativeWrapper).withdraw(valueToRepay); // unwrap
            // repay ETH
            cEther().repayBorrow{value: valueToRepay}();
        } else {
            // repay  regular ERC20
            cToken(token).repayBorrow(valueToRepay);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

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

// SPDX-License-Identifier: GPL-2.0-or-later
/*
 * @title Solidity Bytes Arrays Utils
 * @author Gonçalo Sá <[email protected]>
 *
 * @dev Bytes tightly packed arrays utility library for ethereum contracts written in Solidity.
 *      The library lets you concatenate, slice and type cast bytes arrays both in memory and storage.
 */
pragma solidity 0.8.17;

library BytesLib {
    function slice(
        bytes memory _bytes,
        uint256 _start,
        uint256 _length
    ) internal pure returns (bytes memory) {
        require(_length + 31 >= _length, 'slice_overflow');
        require(_start + _length >= _start, 'slice_overflow');
        require(_bytes.length >= _start + _length, 'slice_outOfBounds');

        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
                case 0 {
                    // Get a location of some free memory and store it in tempBytes as
                    // Solidity does for memory variables.
                    tempBytes := mload(0x40)

                    // The first word of the slice result is potentially a partial
                    // word read from the original array. To read it, we calculate
                    // the length of that partial word and start copying that many
                    // bytes into the array. The first word we copy will start with
                    // data we don't care about, but the last `lengthmod` bytes will
                    // land at the beginning of the contents of the new array. When
                    // we're done copying, we overwrite the full first word with
                    // the actual length of the slice.
                    let lengthmod := and(_length, 31)

                    // The multiplication in the next line is necessary
                    // because when slicing multiples of 32 bytes (lengthmod == 0)
                    // the following copy loop was copying the origin's length
                    // and then ending prematurely not copying everything it should.
                    let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
                    let end := add(mc, _length)

                    for {
                        // The multiplication in the next line has the same exact purpose
                        // as the one above.
                        let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start)
                    } lt(mc, end) {
                        mc := add(mc, 0x20)
                        cc := add(cc, 0x20)
                    } {
                        mstore(mc, mload(cc))
                    }

                    mstore(tempBytes, _length)

                    //update free-memory pointer
                    //allocating the array padded to 32 bytes like the compiler does now
                    mstore(0x40, and(add(mc, 31), not(31)))
                }
                //if we want a zero-length slice let's just return a zero-length array
                default {
                    tempBytes := mload(0x40)
                    //zero out the 32 bytes slice we are about to return
                    //we need to do it because Solidity does not garbage collect
                    mstore(tempBytes, 0)

                    mstore(0x40, add(tempBytes, 0x20))
                }
        }

        return tempBytes;
    }

    function toAddress(bytes memory _bytes, uint256 _start) internal pure returns (address) {
        require(_start + 20 >= _start, 'toAddress_overflow');
        require(_bytes.length >= _start + 20, 'toAddress_outOfBounds');
        address tempAddress;

        assembly {
            tempAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000)
        }

        return tempAddress;
    }

    function toUint24(bytes memory _bytes, uint256 _start) internal pure returns (uint24) {
        require(_start + 3 >= _start, 'toUint24_overflow');
        require(_bytes.length >= _start + 3, 'toUint24_outOfBounds');
        uint24 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x3), _start))
        }

        return tempUint;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that never changes
/// @notice These parameters are fixed for a pool forever, i.e., the methods will always return the same values
interface IUniswapV3PoolImmutables {
    /// @notice The contract that deployed the pool, which must adhere to the IUniswapV3Factory interface
    /// @return The contract address
    function factory() external view returns (address);

    /// @notice The first of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token0() external view returns (address);

    /// @notice The second of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token1() external view returns (address);

    /// @notice The pool's fee in hundredths of a bip, i.e. 1e-6
    /// @return The fee
    function fee() external view returns (uint24);

    /// @notice The pool tick spacing
    /// @dev Ticks can only be used at multiples of this value, minimum of 1 and always positive
    /// e.g.: a tickSpacing of 3 means ticks can be initialized every 3rd tick, i.e., ..., -6, -3, 0, 3, 6, ...
    /// This value is an int24 to avoid casting even though it is always positive.
    /// @return The tick spacing
    function tickSpacing() external view returns (int24);

    /// @notice The maximum amount of position liquidity that can use any tick in the range
    /// @dev This parameter is enforced per tick to prevent liquidity from overflowing a uint128 at any point, and
    /// also prevents out-of-range liquidity from being used to prevent adding in-range liquidity to a pool
    /// @return The max amount of liquidity per tick
    function maxLiquidityPerTick() external view returns (uint128);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Permissioned pool actions
/// @notice Contains pool methods that may only be called by the factory owner
interface IUniswapV3PoolOwnerActions {
    /// @notice Set the denominator of the protocol's % share of the fees
    /// @param feeProtocol0 new protocol fee for token0 of the pool
    /// @param feeProtocol1 new protocol fee for token1 of the pool
    function setFeeProtocol(uint8 feeProtocol0, uint8 feeProtocol1) external;

    /// @notice Collect the protocol fee accrued to the pool
    /// @param recipient The address to which collected protocol fees should be sent
    /// @param amount0Requested The maximum amount of token0 to send, can be 0 to collect fees in only token1
    /// @param amount1Requested The maximum amount of token1 to send, can be 0 to collect fees in only token0
    /// @return amount0 The protocol fee collected in token0
    /// @return amount1 The protocol fee collected in token1
    function collectProtocol(
        address recipient,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that can change
/// @notice These methods compose the pool's state, and can change with any frequency including multiple times
/// per transaction
interface IUniswapV3PoolState {
    /// @notice The 0th storage slot in the pool stores many values, and is exposed as a single method to save gas
    /// when accessed externally.
    /// @return sqrtPriceX96 The current price of the pool as a sqrt(token1/token0) Q64.96 value
    /// tick The current tick of the pool, i.e. according to the last tick transition that was run.
    /// This value may not always be equal to SqrtTickMath.getTickAtSqrtRatio(sqrtPriceX96) if the price is on a tick
    /// boundary.
    /// observationIndex The index of the last oracle observation that was written,
    /// observationCardinality The current maximum number of observations stored in the pool,
    /// observationCardinalityNext The next maximum number of observations, to be updated when the observation.
    /// feeProtocol The protocol fee for both tokens of the pool.
    /// Encoded as two 4 bit values, where the protocol fee of token1 is shifted 4 bits and the protocol fee of token0
    /// is the lower 4 bits. Used as the denominator of a fraction of the swap fee, e.g. 4 means 1/4th of the swap fee.
    /// unlocked Whether the pool is currently locked to reentrancy
    function slot0()
        external
        view
        returns (
            uint160 sqrtPriceX96,
            int24 tick,
            uint16 observationIndex,
            uint16 observationCardinality,
            uint16 observationCardinalityNext,
            uint8 feeProtocol,
            bool unlocked
        );

    /// @notice The fee growth as a Q128.128 fees of token0 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal0X128() external view returns (uint256);

    /// @notice The fee growth as a Q128.128 fees of token1 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal1X128() external view returns (uint256);

    /// @notice The amounts of token0 and token1 that are owed to the protocol
    /// @dev Protocol fees will never exceed uint128 max in either token
    function protocolFees() external view returns (uint128 token0, uint128 token1);

    /// @notice The currently in range liquidity available to the pool
    /// @dev This value has no relationship to the total liquidity across all ticks
    function liquidity() external view returns (uint128);

    /// @notice Look up information about a specific tick in the pool
    /// @param tick The tick to look up
    /// @return liquidityGross the total amount of position liquidity that uses the pool either as tick lower or
    /// tick upper,
    /// liquidityNet how much liquidity changes when the pool price crosses the tick,
    /// feeGrowthOutside0X128 the fee growth on the other side of the tick from the current tick in token0,
    /// feeGrowthOutside1X128 the fee growth on the other side of the tick from the current tick in token1,
    /// tickCumulativeOutside the cumulative tick value on the other side of the tick from the current tick
    /// secondsPerLiquidityOutsideX128 the seconds spent per liquidity on the other side of the tick from the current tick,
    /// secondsOutside the seconds spent on the other side of the tick from the current tick,
    /// initialized Set to true if the tick is initialized, i.e. liquidityGross is greater than 0, otherwise equal to false.
    /// Outside values can only be used if the tick is initialized, i.e. if liquidityGross is greater than 0.
    /// In addition, these values are only relative and must be used only in comparison to previous snapshots for
    /// a specific position.
    function ticks(int24 tick)
        external
        view
        returns (
            uint128 liquidityGross,
            int128 liquidityNet,
            uint256 feeGrowthOutside0X128,
            uint256 feeGrowthOutside1X128,
            int56 tickCumulativeOutside,
            uint160 secondsPerLiquidityOutsideX128,
            uint32 secondsOutside,
            bool initialized
        );

    /// @notice Returns 256 packed tick initialized boolean values. See TickBitmap for more information
    function tickBitmap(int16 wordPosition) external view returns (uint256);

    /// @notice Returns the information about a position by the position's key
    /// @param key The position's key is a hash of a preimage composed by the owner, tickLower and tickUpper
    /// @return _liquidity The amount of liquidity in the position,
    /// Returns feeGrowthInside0LastX128 fee growth of token0 inside the tick range as of the last mint/burn/poke,
    /// Returns feeGrowthInside1LastX128 fee growth of token1 inside the tick range as of the last mint/burn/poke,
    /// Returns tokensOwed0 the computed amount of token0 owed to the position as of the last mint/burn/poke,
    /// Returns tokensOwed1 the computed amount of token1 owed to the position as of the last mint/burn/poke
    function positions(bytes32 key)
        external
        view
        returns (
            uint128 _liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );

    /// @notice Returns data about a specific observation index
    /// @param index The element of the observations array to fetch
    /// @dev You most likely want to use #observe() instead of this method to get an observation as of some amount of time
    /// ago, rather than at a specific index in the array.
    /// @return blockTimestamp The timestamp of the observation,
    /// Returns tickCumulative the tick multiplied by seconds elapsed for the life of the pool as of the observation timestamp,
    /// Returns secondsPerLiquidityCumulativeX128 the seconds per in range liquidity for the life of the pool as of the observation timestamp,
    /// Returns initialized whether the observation has been initialized and the values are safe to use
    function observations(uint256 index)
        external
        view
        returns (
            uint32 blockTimestamp,
            int56 tickCumulative,
            uint160 secondsPerLiquidityCumulativeX128,
            bool initialized
        );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that is not stored
/// @notice Contains view functions to provide information about the pool that is computed rather than stored on the
/// blockchain. The functions here may have variable gas costs.
interface IUniswapV3PoolDerivedState {
    /// @notice Returns the cumulative tick and liquidity as of each timestamp `secondsAgo` from the current block timestamp
    /// @dev To get a time weighted average tick or liquidity-in-range, you must call this with two values, one representing
    /// the beginning of the period and another for the end of the period. E.g., to get the last hour time-weighted average tick,
    /// you must call it with secondsAgos = [3600, 0].
    /// @dev The time weighted average tick represents the geometric time weighted average price of the pool, in
    /// log base sqrt(1.0001) of token1 / token0. The TickMath library can be used to go from a tick value to a ratio.
    /// @param secondsAgos From how long ago each cumulative tick and liquidity value should be returned
    /// @return tickCumulatives Cumulative tick values as of each `secondsAgos` from the current block timestamp
    /// @return secondsPerLiquidityCumulativeX128s Cumulative seconds per liquidity-in-range value as of each `secondsAgos` from the current block
    /// timestamp
    function observe(uint32[] calldata secondsAgos)
        external
        view
        returns (int56[] memory tickCumulatives, uint160[] memory secondsPerLiquidityCumulativeX128s);

    /// @notice Returns a snapshot of the tick cumulative, seconds per liquidity and seconds inside a tick range
    /// @dev Snapshots must only be compared to other snapshots, taken over a period for which a position existed.
    /// I.e., snapshots cannot be compared if a position is not held for the entire period between when the first
    /// snapshot is taken and the second snapshot is taken.
    /// @param tickLower The lower tick of the range
    /// @param tickUpper The upper tick of the range
    /// @return tickCumulativeInside The snapshot of the tick accumulator for the range
    /// @return secondsPerLiquidityInsideX128 The snapshot of seconds per liquidity for the range
    /// @return secondsInside The snapshot of seconds per liquidity for the range
    function snapshotCumulativesInside(int24 tickLower, int24 tickUpper)
        external
        view
        returns (
            int56 tickCumulativeInside,
            uint160 secondsPerLiquidityInsideX128,
            uint32 secondsInside
        );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Events emitted by a pool
/// @notice Contains all events emitted by the pool
interface IUniswapV3PoolEvents {
    /// @notice Emitted exactly once by a pool when #initialize is first called on the pool
    /// @dev Mint/Burn/Swap cannot be emitted by the pool before Initialize
    /// @param sqrtPriceX96 The initial sqrt price of the pool, as a Q64.96
    /// @param tick The initial tick of the pool, i.e. log base 1.0001 of the starting price of the pool
    event Initialize(uint160 sqrtPriceX96, int24 tick);

    /// @notice Emitted when liquidity is minted for a given position
    /// @param sender The address that minted the liquidity
    /// @param owner The owner of the position and recipient of any minted liquidity
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount The amount of liquidity minted to the position range
    /// @param amount0 How much token0 was required for the minted liquidity
    /// @param amount1 How much token1 was required for the minted liquidity
    event Mint(
        address sender,
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted when fees are collected by the owner of a position
    /// @dev Collect events may be emitted with zero amount0 and amount1 when the caller chooses not to collect fees
    /// @param owner The owner of the position for which fees are collected
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount0 The amount of token0 fees collected
    /// @param amount1 The amount of token1 fees collected
    event Collect(
        address indexed owner,
        address recipient,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount0,
        uint128 amount1
    );

    /// @notice Emitted when a position's liquidity is removed
    /// @dev Does not withdraw any fees earned by the liquidity position, which must be withdrawn via #collect
    /// @param owner The owner of the position for which liquidity is removed
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount The amount of liquidity to remove
    /// @param amount0 The amount of token0 withdrawn
    /// @param amount1 The amount of token1 withdrawn
    event Burn(
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted by the pool for any swaps between token0 and token1
    /// @param sender The address that initiated the swap call, and that received the callback
    /// @param recipient The address that received the output of the swap
    /// @param amount0 The delta of the token0 balance of the pool
    /// @param amount1 The delta of the token1 balance of the pool
    /// @param sqrtPriceX96 The sqrt(price) of the pool after the swap, as a Q64.96
    /// @param liquidity The liquidity of the pool after the swap
    /// @param tick The log base 1.0001 of price of the pool after the swap
    event Swap(
        address indexed sender,
        address indexed recipient,
        int256 amount0,
        int256 amount1,
        uint160 sqrtPriceX96,
        uint128 liquidity,
        int24 tick
    );

    /// @notice Emitted by the pool for any flashes of token0/token1
    /// @param sender The address that initiated the swap call, and that received the callback
    /// @param recipient The address that received the tokens from flash
    /// @param amount0 The amount of token0 that was flashed
    /// @param amount1 The amount of token1 that was flashed
    /// @param paid0 The amount of token0 paid for the flash, which can exceed the amount0 plus the fee
    /// @param paid1 The amount of token1 paid for the flash, which can exceed the amount1 plus the fee
    event Flash(
        address indexed sender,
        address indexed recipient,
        uint256 amount0,
        uint256 amount1,
        uint256 paid0,
        uint256 paid1
    );

    /// @notice Emitted by the pool for increases to the number of observations that can be stored
    /// @dev observationCardinalityNext is not the observation cardinality until an observation is written at the index
    /// just before a mint/swap/burn.
    /// @param observationCardinalityNextOld The previous value of the next observation cardinality
    /// @param observationCardinalityNextNew The updated value of the next observation cardinality
    event IncreaseObservationCardinalityNext(
        uint16 observationCardinalityNextOld,
        uint16 observationCardinalityNextNew
    );

    /// @notice Emitted when the protocol fee is changed by the pool
    /// @param feeProtocol0Old The previous value of the token0 protocol fee
    /// @param feeProtocol1Old The previous value of the token1 protocol fee
    /// @param feeProtocol0New The updated value of the token0 protocol fee
    /// @param feeProtocol1New The updated value of the token1 protocol fee
    event SetFeeProtocol(uint8 feeProtocol0Old, uint8 feeProtocol1Old, uint8 feeProtocol0New, uint8 feeProtocol1New);

    /// @notice Emitted when the collected protocol fees are withdrawn by the factory owner
    /// @param sender The address that collects the protocol fees
    /// @param recipient The address that receives the collected protocol fees
    /// @param amount0 The amount of token0 protocol fees that is withdrawn
    /// @param amount0 The amount of token1 protocol fees that is withdrawn
    event CollectProtocol(address indexed sender, address indexed recipient, uint128 amount0, uint128 amount1);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Permissionless pool actions
/// @notice Contains pool methods that can be called by anyone
interface IUniswapV3PoolActions {
    /// @notice Sets the initial price for the pool
    /// @dev Price is represented as a sqrt(amountToken1/amountToken0) Q64.96 value
    /// @param sqrtPriceX96 the initial sqrt price of the pool as a Q64.96
    function initialize(uint160 sqrtPriceX96) external;

    /// @notice Adds liquidity for the given recipient/tickLower/tickUpper position
    /// @dev The caller of this method receives a callback in the form of IUniswapV3MintCallback#uniswapV3MintCallback
    /// in which they must pay any token0 or token1 owed for the liquidity. The amount of token0/token1 due depends
    /// on tickLower, tickUpper, the amount of liquidity, and the current price.
    /// @param recipient The address for which the liquidity will be created
    /// @param tickLower The lower tick of the position in which to add liquidity
    /// @param tickUpper The upper tick of the position in which to add liquidity
    /// @param amount The amount of liquidity to mint
    /// @param data Any data that should be passed through to the callback
    /// @return amount0 The amount of token0 that was paid to mint the given amount of liquidity. Matches the value in the callback
    /// @return amount1 The amount of token1 that was paid to mint the given amount of liquidity. Matches the value in the callback
    function mint(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount,
        bytes calldata data
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Collects tokens owed to a position
    /// @dev Does not recompute fees earned, which must be done either via mint or burn of any amount of liquidity.
    /// Collect must be called by the position owner. To withdraw only token0 or only token1, amount0Requested or
    /// amount1Requested may be set to zero. To withdraw all tokens owed, caller may pass any value greater than the
    /// actual tokens owed, e.g. type(uint128).max. Tokens owed may be from accumulated swap fees or burned liquidity.
    /// @param recipient The address which should receive the fees collected
    /// @param tickLower The lower tick of the position for which to collect fees
    /// @param tickUpper The upper tick of the position for which to collect fees
    /// @param amount0Requested How much token0 should be withdrawn from the fees owed
    /// @param amount1Requested How much token1 should be withdrawn from the fees owed
    /// @return amount0 The amount of fees collected in token0
    /// @return amount1 The amount of fees collected in token1
    function collect(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);

    /// @notice Burn liquidity from the sender and account tokens owed for the liquidity to the position
    /// @dev Can be used to trigger a recalculation of fees owed to a position by calling with an amount of 0
    /// @dev Fees must be collected separately via a call to #collect
    /// @param tickLower The lower tick of the position for which to burn liquidity
    /// @param tickUpper The upper tick of the position for which to burn liquidity
    /// @param amount How much liquidity to burn
    /// @return amount0 The amount of token0 sent to the recipient
    /// @return amount1 The amount of token1 sent to the recipient
    function burn(
        int24 tickLower,
        int24 tickUpper,
        uint128 amount
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Swap token0 for token1, or token1 for token0
    /// @dev The caller of this method receives a callback in the form of IUniswapV3SwapCallback#uniswapV3SwapCallback
    /// @param recipient The address to receive the output of the swap
    /// @param zeroForOne The direction of the swap, true for token0 to token1, false for token1 to token0
    /// @param amountSpecified The amount of the swap, which implicitly configures the swap as exact input (positive), or exact output (negative)
    /// @param sqrtPriceLimitX96 The Q64.96 sqrt price limit. If zero for one, the price cannot be less than this
    /// value after the swap. If one for zero, the price cannot be greater than this value after the swap
    /// @param data Any data to be passed through to the callback
    /// @return amount0 The delta of the balance of token0 of the pool, exact when negative, minimum when positive
    /// @return amount1 The delta of the balance of token1 of the pool, exact when negative, minimum when positive
    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes calldata data
    ) external returns (int256 amount0, int256 amount1);

    /// @notice Receive token0 and/or token1 and pay it back, plus a fee, in the callback
    /// @dev The caller of this method receives a callback in the form of IUniswapV3FlashCallback#uniswapV3FlashCallback
    /// @dev Can be used to donate underlying tokens pro-rata to currently in-range liquidity providers by calling
    /// with 0 amount{0,1} and sending the donation amount(s) from the callback
    /// @param recipient The address which will receive the token0 and token1 amounts
    /// @param amount0 The amount of token0 to send
    /// @param amount1 The amount of token1 to send
    /// @param data Any data to be passed through to the callback
    function flash(
        address recipient,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external;

    /// @notice Increase the maximum number of price and liquidity observations that this pool will store
    /// @dev This method is no-op if the pool already has an observationCardinalityNext greater than or equal to
    /// the input observationCardinalityNext.
    /// @param observationCardinalityNext The desired minimum number of observations for the pool to store
    function increaseObservationCardinalityNext(uint16 observationCardinalityNext) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

interface INativeWrapper {
    function deposit() external payable;

    function withdraw(uint256 wad) external;

    function totalSupply() external view returns (uint256);

    function approve(address guy, uint256 wad) external returns (bool);

    function transfer(address dst, uint256 wad) external returns (bool);

    function transferFrom(
        address src,
        address dst,
        uint256 wad
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import {IOErc20, IComptroller, IOMatic} from "../../../interfaces/polygon/IDataProviderPolygon.sol";

// solhint-disable max-line-length

/**
 * @title Contract that holds compund data hard-coded to inherit to modules
 * @notice modules that use this data should inherit from this contract to prevent external function calls from data
 * the data is hard coded here and can be upgraded through a diamond cut on the module using it
 */
abstract contract OTokenData {
    // constructor will not conflict with proxies due to immutability
    constructor() {}

    address private immutable oMATIC = 0xE554E874c9c60E45F1Debd479389C76230ae25A8;

    address private immutable WBTC = 0x1BFD67037B42Cf73acF2047067bd4F2C47D9BfD6;
    address private immutable oWBTC = 0x3B9128Ddd834cE06A60B0eC31CCfB11582d8ee18;

    address private immutable oDAI = 0x2175110F2936bf630a278660E9B6E4EFa358490A;
    address private immutable DAI = 0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063;

    address private immutable oWETH = 0xb2D9646A1394bf784E376612136B3686e74A325F;
    address private immutable WETH = 0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619;

    address private immutable oUSDC = 0xEBb865Bf286e6eA8aBf5ac97e1b56A76530F3fBe;
    address private immutable USDC = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;

    address private immutable oUSDT = 0x1372c34acC14F1E8644C72Dad82E3a21C211729f;
    address private immutable USDT = 0xc2132D05D31c914a87C6611C10748AEb04B58e8F;

    address private immutable oMAI = 0xC57E5e261d49Af3026446de3eC381172f17bB799;
    address private immutable MAI = 0xa3Fa99A148fA48D14Ed51d610c367C61876997F1;

    address private immutable oMATICX = 0xAAcc5108419Ae55Bc3588E759E28016d06ce5F40;
    address private immutable MATICX = 0xfa68FB4628DFF1028CFEc22b4162FCcd0d45efb6;
    // unitroller address
    address private immutable comptroller = 0x8849f1a0cB6b5D6076aB150546EddEe193754F1C;

    function cToken(address _underlying) internal view returns (IOErc20) {
        if (_underlying == USDC) return IOErc20(oUSDC);
        if (_underlying == USDT) return IOErc20(oUSDT);
        if (_underlying == DAI) return IOErc20(oDAI);
        if (_underlying == WETH) return IOErc20(oWETH);
        if (_underlying == WBTC) return IOErc20(oWBTC);
        if (_underlying == MAI) return IOErc20(oMAI);
        if (_underlying == MATICX) return IOErc20(oMATICX);

        revert("no cToken for this underlying");
    }

    function cEther() internal view returns (IOMatic) {
        return IOMatic(oMATIC);
    }

    function getComptroller() internal view returns (IComptroller) {
        return IComptroller(comptroller);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {IOErc20} from "../../../../external-protocols/oVix/IOErc20.sol";
import {IComptroller} from "../../../../external-protocols/oVix/IComptroller.sol";
import {IOMatic} from "../../../../external-protocols/oVix/IOMatic.sol";
import {INativeWrapper} from "../INativeWrapper.sol";

// solhint-disable max-line-length

interface IDataProviderPolygon {
    function cToken(address _underlying) external view returns (IOErc20);

    function cEther() external view returns (IOMatic);

    function WETH() external view returns (INativeWrapper);

    function minimalRouter() external view returns (address);

    function cTokens(address _underlyingIn, address _underlyingOut) external view returns (IOErc20, IOErc20);

    function underlying(address _cToken) external view returns (address);

    function getCollateralSwapData(
        address _underlyingFrom,
        address _underlyingTo,
        uint24 _fee
    )
        external
        view
        returns (
            IOErc20 cTokenFrom,
            IOErc20 cTokenTo,
            address swapPool
        );

    function getV3Pool(
        address _underlyingFrom,
        address _underlyingTo,
        uint24 _fee
    ) external view returns (address);

    function validatePoolAndFetchCTokens(
        address _pool,
        address _underlyingIn,
        address _underlyingOut
    ) external view returns (IOErc20, IOErc20);

    function getComptroller() external view returns (IComptroller);

    function allCTokens() external view returns (address[] memory cTokens);

    function allUnderlyings() external view returns (address[] memory underlyings);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./IOToken.sol";
import "./PriceOracle.sol";

interface IComptroller {
    /// @notice Indicator that this is a Comptroller contract (for inspection)
    function isComptroller() external view returns (bool);

    /*** Assets You Are In ***/

    function enterMarkets(address[] calldata oTokens) external returns (uint256[] memory);

    function exitMarket(address oToken) external returns (uint256);

    /*** Policy Hooks ***/

    function mintAllowed(
        address oToken,
        address minter,
        uint256 mintAmount
    ) external returns (uint256);

    function mintVerify(
        address oToken,
        address minter,
        uint256 mintAmount,
        uint256 mintTokens
    ) external;

    function redeemAllowed(
        address oToken,
        address redeemer,
        uint256 redeemTokens
    ) external returns (uint256);

    function redeemVerify(
        address oToken,
        address redeemer,
        uint256 redeemAmount,
        uint256 redeemTokens
    ) external;

    function borrowAllowed(
        address oToken,
        address borrower,
        uint256 borrowAmount
    ) external returns (uint256);

    function borrowVerify(
        address oToken,
        address borrower,
        uint256 borrowAmount
    ) external;

    function repayBorrowAllowed(
        address oToken,
        address payer,
        address borrower,
        uint256 repayAmount
    ) external returns (uint256);

    function liquidateBorrowAllowed(
        address oTokenBorrowed,
        address oTokenCollateral,
        address liquidator,
        address borrower,
        uint256 repayAmount
    ) external returns (uint256);

    function seizeAllowed(
        address oTokenCollateral,
        address oTokenBorrowed,
        address liquidator,
        address borrower,
        uint256 seizeTokens
    ) external returns (uint256);

    function seizeVerify(
        address oTokenCollateral,
        address oTokenBorrowed,
        address liquidator,
        address borrower,
        uint256 seizeTokens
    ) external;

    function transferAllowed(
        address oToken,
        address src,
        address dst,
        uint256 transferTokens
    ) external returns (uint256);

    function transferVerify(
        address oToken,
        address src,
        address dst,
        uint256 transferTokens
    ) external;

    /*** Liquidity/Liquidation Calculations ***/

    function liquidateCalculateSeizeTokens(
        address oTokenBorrowed,
        address oTokenCollateral,
        uint256 repayAmount
    ) external view returns (uint256, uint256);

    function isMarket(address market) external view returns (bool);

    function getBoostManager() external view returns (address);

    function getAllMarkets() external view returns (IOToken[] memory);

    function oracle() external view returns (PriceOracle);

    function updateAndDistributeSupplierRewardsForToken(address oToken, address account) external;

    function updateAndDistributeBorrowerRewardsForToken(address oToken, address borrower) external;

    function _setRewardSpeeds(
        address[] memory oTokens,
        uint256[] memory supplySpeeds,
        uint256[] memory borrowSpeeds
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./IEIP20NonStandard.sol";
import "./IOToken.sol";

interface IOErc20 {
    /*** User Interface ***/

    function mint(uint256 mintAmount) external returns (uint256);

    function redeem(uint256 redeemTokens) external returns (uint256);

    function redeemUnderlying(uint256 redeemAmount) external returns (uint256);

    function borrow(uint256 borrowAmount) external returns (uint256);

    function repayBorrow(uint256 repayAmount) external returns (uint256);

    function repayBorrowBehalf(address borrower, uint256 repayAmount) external returns (uint256);

    function liquidateBorrow(
        address borrower,
        uint256 repayAmount,
        IOToken oTokenCollateral
    ) external returns (uint256);

    function sweepToken(IEIP20NonStandard token) external;

    function underlying() external view returns (address);

    /*** Admin Functions ***/

    function _addReserves(uint256 addAmount) external returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./IOToken.sol";

/**
 * @title 0VIX's OMatic Contract
 * @notice OToken which wraps Matic
 * @author 0VIX
 */
interface IOMatic is IOToken {
    /*** User Interface ***/

    /**
     * @notice Sender supplies assets into the market and receives oTokens in exchange
     * @dev Reverts upon any failure
     */
    function mint() external payable;

    /**
     * @notice Sender redeems oTokens in exchange for the underlying asset
     * @dev Accrues interest whether or not the operation succeeds, unless reverted
     * @param redeemTokens The number of oTokens to redeem into underlying
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function redeem(uint256 redeemTokens) external returns (uint256);

    /**
     * @notice Sender redeems oTokens in exchange for a specified amount of underlying asset
     * @dev Accrues interest whether or not the operation succeeds, unless reverted
     * @param redeemAmount The amount of underlying to redeem
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function redeemUnderlying(uint256 redeemAmount) external returns (uint256);

    /**
     * @notice Sender borrows assets from the protocol to their own address
     * @param borrowAmount The amount of the underlying asset to borrow
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function borrow(uint256 borrowAmount) external returns (uint256);

    /**
     * @notice Sender repays their own borrow
     * @dev Reverts upon any failure
     */
    function repayBorrow() external payable;

    /**
     * @notice Sender repays a borrow belonging to borrower
     * @dev Reverts upon any failure
     * @param borrower the account with the debt being payed off
     */
    function repayBorrowBehalf(address borrower) external payable;

    /**
     * @notice The sender liquidates the borrowers collateral.
     *  The collateral seized is transferred to the liquidator.
     * @dev Reverts upon any failure
     * @param borrower The borrower of this oToken to be liquidated
     * @param oTokenCollateral The market in which to seize collateral from the borrower
     */
    function liquidateBorrow(address borrower, IOToken oTokenCollateral) external payable;

    /**
     * @notice The sender adds to reserves.
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function _addReserves() external payable returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./IComptroller.sol";
import "./IInterestRateModel.sol";
import "./IEIP20NonStandard.sol";
import "./IEIP20.sol";

interface IOToken is IEIP20 {
    /**
     * @notice Indicator that this is a OToken contract (for inspection)
     */
    function isOToken() external view returns (bool);

    function accrualBlockTimestamp() external returns (uint256);

    /*** User Interface ***/
    function balanceOfUnderlying(address owner) external returns (uint256);

    function getAccountSnapshot(address account)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        );

    function borrowRatePerTimestamp() external view returns (uint256);

    function supplyRatePerTimestamp() external view returns (uint256);

    function totalBorrowsCurrent() external returns (uint256);

    function totalReserves() external returns (uint256);

    function borrowBalanceCurrent(address account) external returns (uint256);

    function borrowBalanceStored(address account) external view returns (uint256);

    function exchangeRateCurrent() external returns (uint256);

    function exchangeRateStored() external view returns (uint256);

    function getCash() external view returns (uint256);

    function accrueInterest() external returns (uint256);

    function seize(
        address liquidator,
        address borrower,
        uint256 seizeTokens
    ) external returns (uint256);

    function totalBorrows() external view returns (uint256);

    function comptroller() external view returns (IComptroller);

    function borrowIndex() external view returns (uint256);

    function reserveFactorMantissa() external view returns (uint256);

    /*** Admin Functions ***/

    function _setPendingAdmin(address payable newPendingAdmin) external returns (uint256);

    function _acceptAdmin() external returns (uint256);

    function _setComptroller(IComptroller newComptroller) external returns (uint256);

    function _setReserveFactor(uint256 newReserveFactorMantissa) external returns (uint256);

    function _reduceReserves(uint256 reduceAmount) external returns (uint256);

    function _setInterestRateModel(IInterestRateModel newInterestRateModel) external returns (uint256);

    function _setProtocolSeizeShare(uint256 newProtocolSeizeShareMantissa) external returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./IOToken.sol";

abstract contract PriceOracle {
    /// @notice Indicator that this is a PriceOracle contract (for inspection)
    bool public constant isPriceOracle = true;

    /**
      * @notice Get the underlying price of a oToken asset
      * @param oToken The oToken to get the underlying price of
      * @return The underlying asset price mantissa (scaled by 1e18).
      *  Zero means the price is unavailable.
      */
    function getUnderlyingPrice(IOToken oToken) external virtual view returns (uint);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/**
 * @title 0VIX's IInterestRateModel Interface
 * @author 0VIX
 */
interface IInterestRateModel {
    /// @notice Indicator that this is an InterestRateModel contract (for inspection)
    function isInterestRateModel() external view returns (bool);

    /**
     * @notice Calculates the current borrow interest rate per timestmp
     * @param cash The total amount of cash the market has
     * @param borrows The total amount of borrows the market has outstanding
     * @param reserves The total amount of reserves the market has
     * @return The borrow rate per timestmp (as a percentage, and scaled by 1e18)
     */
    function getBorrowRate(
        uint256 cash,
        uint256 borrows,
        uint256 reserves
    ) external view returns (uint256);

    /**
     * @notice Calculates the current supply interest rate per timestmp
     * @param cash The total amount of cash the market has
     * @param borrows The total amount of borrows the market has outstanding
     * @param reserves The total amount of reserves the market has
     * @param reserveFactorMantissa The current reserve factor the market has
     * @return The supply rate per timestmp (as a percentage, and scaled by 1e18)
     */
    function getSupplyRate(
        uint256 cash,
        uint256 borrows,
        uint256 reserves,
        uint256 reserveFactorMantissa
    ) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/**
 * @title ERC 20 Token Standard Interface
 *  https://eips.ethereum.org/EIPS/eip-20
 */
interface IEIP20 {
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
     * @return balance The balance
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @notice Transfer `amount` tokens from `msg.sender` to `dst`
     * @param dst The address of the destination account
     * @param amount The number of tokens to transfer
     * @return success Whether or not the transfer succeeded
     */
    function transfer(address dst, uint256 amount) external returns (bool success);

    /**
     * @notice Transfer `amount` tokens from `src` to `dst`
     * @param src The address of the source account
     * @param dst The address of the destination account
     * @param amount The number of tokens to transfer
     * @return success Whether or not the transfer succeeded
     */
    function transferFrom(
        address src,
        address dst,
        uint256 amount
    ) external returns (bool success);

    /**
     * @notice Approve `spender` to transfer up to `amount` from `src`
     * @dev This will overwrite the approval amount for `spender`
     *  and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
     * @param spender The address of the account which may transfer tokens
     * @param amount The number of tokens that are approved (-1 means infinite)
     * @return success Whether or not the approval succeeded
     */
    function approve(address spender, uint256 amount) external returns (bool success);

    /**
     * @notice Get the current allowance from `owner` for `spender`
     * @param owner The address of the account which owns the tokens to be spent
     * @param spender The address of the account which may transfer tokens
     * @return remaining The number of tokens allowed to be spent (-1 means infinite)
     */
    function allowance(address owner, address spender) external view returns (uint256 remaining);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/**
 * @title IEIP20NonStandard
 * @dev Version of ERC20 with no return values for `transfer` and `transferFrom`
 *  See https://medium.com/coinmonks/missing-return-value-bug-at-least-130-tokens-affected-d67bf08521ca
 */
interface IEIP20NonStandard {
    /**
     * @notice Get the total number of tokens in circulation
     * @return The supply of tokens
     */
    function totalSupply() external view returns (uint256);

    /**
     * @notice Gets the balance of the specified address
     * @param owner The address from which the balance will be retrieved
     * @return balance The balance
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    ///
    /// !!!!!!!!!!!!!!
    /// !!! NOTICE !!! `transfer` does not return a value, in violation of the ERC-20 specification
    /// !!!!!!!!!!!!!!
    ///

    /**
     * @notice Transfer `amount` tokens from `msg.sender` to `dst`
     * @param dst The address of the destination account
     * @param amount The number of tokens to transfer
     */
    function transfer(address dst, uint256 amount) external;

    ///
    /// !!!!!!!!!!!!!!
    /// !!! NOTICE !!! `transferFrom` does not return a value, in violation of the ERC-20 specification
    /// !!!!!!!!!!!!!!
    ///

    /**
     * @notice Transfer `amount` tokens from `src` to `dst`
     * @param src The address of the source account
     * @param dst The address of the destination account
     * @param amount The number of tokens to transfer
     */
    function transferFrom(
        address src,
        address dst,
        uint256 amount
    ) external;

    /**
     * @notice Approve `spender` to transfer up to `amount` from `src`
     * @dev This will overwrite the approval amount for `spender`
     *  and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
     * @param spender The address of the account which may transfer tokens
     * @param amount The number of tokens that are approved
     * @return success Whether or not the approval succeeded
     */
    function approve(address spender, uint256 amount) external returns (bool success);

    /**
     * @notice Get the current allowance from `owner` for `spender`
     * @param owner The address of the account which owns the tokens to be spent
     * @param spender The address of the account which may transfer tokens
     * @return remaining The number of tokens allowed to be spent
     */
    function allowance(address owner, address spender) external view returns (uint256 remaining);
}