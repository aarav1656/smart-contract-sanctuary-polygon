// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.7.6;
pragma abicoder v2;

import '@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol';
import '@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol';

abstract contract WrappedNative {
    function deposit() public payable {}
}

contract SKGSwap {
//  ETH
//    address public constant W_NATIVE = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
//  MATIC
    address public constant W_NATIVE = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;

    ISwapRouter public immutable swapRouter;
    WrappedNative private immutable _wrappedNative;

    struct SwapParams {
        address _tokenIn;
        address[]  _tokenOutList;
        uint24[] _poolFeeList;
        uint256[] _amountInList;
        uint256[] _amountOutMinimumList;
    }

    constructor(ISwapRouter _swapRouter) {
        swapRouter = _swapRouter;
        _wrappedNative = WrappedNative(W_NATIVE);
    }

    function swapERC20(address tokenIn, uint256 amountInSum, uint256[] memory amountInList, address[] memory tokenOutList, uint24[] memory poolFeeList, uint256[] memory amountOutMinimumList, uint256[] memory pathsLength) external {
        _requiredCorrectArgument(amountInList, tokenOutList, poolFeeList, amountOutMinimumList, pathsLength);

        TransferHelper.safeTransferFrom(tokenIn, msg.sender, address(this), amountInSum);
        _swap(tokenIn, amountInSum, amountInList, tokenOutList, poolFeeList, amountOutMinimumList, pathsLength);
    }

    function swapNative(uint256 amountInSum, uint256[] memory amountInList, address[] memory tokenOutList, uint24[] memory poolFeeList, uint256[] memory amountOutMinimumList, uint256[] memory pathsLength) external payable {
        _requiredCorrectArgument(amountInList, tokenOutList, poolFeeList, amountOutMinimumList, pathsLength);

        _wrappedNative.deposit{value:msg.value}();
        _swap(W_NATIVE, amountInSum, amountInList, tokenOutList, poolFeeList, amountOutMinimumList, pathsLength);
    }

    function _swap(address tokenIn, uint256 amountInSum, uint256[] memory amountInList, address[] memory tokenOutList, uint24[] memory poolFeeList, uint256[] memory amountOutMinimumList, uint256[] memory pathsLength) internal {
        TransferHelper.safeApprove(tokenIn, address(swapRouter), amountInSum);

        SwapParams memory _swapParams;
        _swapParams._tokenIn = tokenIn;
        _swapParams._tokenOutList = tokenOutList;
        _swapParams._poolFeeList = poolFeeList;
        _swapParams._amountInList = amountInList;
        _swapParams._amountOutMinimumList = amountOutMinimumList;

        uint256 total = amountInList.length;
        uint256 currentPath = 0;
        for (uint256 i = 0; i < total; i++) {
            uint256 pathLength = pathsLength[i];
            if (pathLength > 1) {
                _exactInput(_swapParams._tokenIn, currentPath, pathLength, _swapParams._tokenOutList, _swapParams._poolFeeList, _swapParams._amountInList[i], _swapParams._amountOutMinimumList[i]);
            } else {
                _exactInputSingle(_swapParams._tokenIn, _swapParams._tokenOutList[currentPath], _swapParams._poolFeeList[currentPath], _swapParams._amountInList[i], _swapParams._amountOutMinimumList[i]);
            }

            currentPath += pathLength;
        }
    }

    function _exactInput(address tokenIn, uint256 currentPath, uint256 pathLength, address[] memory tokenOutList, uint24[] memory poolFeeList, uint256 amountIn, uint256 amountOutMinimum) internal {
        bytes memory path = abi.encodePacked(tokenIn);

        for(uint256 j = 0; j < pathLength; j++) {
            path = abi.encodePacked(path, poolFeeList[currentPath + j], tokenOutList[currentPath + j]);
        }

        ISwapRouter.ExactInputParams memory params =
        ISwapRouter.ExactInputParams({
            path: path,
            recipient: msg.sender,
            deadline: block.timestamp,
            amountIn: amountIn,
            amountOutMinimum: amountOutMinimum
        });

        swapRouter.exactInput(params);
    }

    function _exactInputSingle(address tokenIn, address tokenOut, uint24 fee, uint256 amountIn, uint256 amountOutMinimum) internal {
        ISwapRouter.ExactInputSingleParams memory params =
        ISwapRouter.ExactInputSingleParams({
            tokenIn: tokenIn,
            tokenOut: tokenOut,
            fee: fee,
            recipient: msg.sender,
            deadline: block.timestamp,
            amountIn: amountIn,
            amountOutMinimum: amountOutMinimum,
            sqrtPriceLimitX96: 0
        });

        swapRouter.exactInputSingle(params);
    }

    function _requiredCorrectArgument(uint256[] memory amountInList, address[] memory tokenOutList, uint24[] memory poolFeeList, uint256[] memory amountOutMinimumList, uint256[] memory pathsLength) internal view virtual {
        require(amountInList.length > 0, "amountInList.length=0");
        require(amountInList.length <= tokenOutList.length, "tokenOutList less amountInList");
        require(amountInList.length <= poolFeeList.length, "poolFeeList less amountInList");
        require(amountInList.length == amountOutMinimumList.length, "Different length amountOutMinimumList");
        require(amountInList.length == pathsLength.length, "Different length pathsLength");

        uint256 totalPathLength = 0;
        for (uint256 i = 0; i < pathsLength.length; i++) {
            totalPathLength += pathsLength[i];
        }

        require(totalPathLength == tokenOutList.length, "tokenOutList != totalPathLength");
        require(totalPathLength == poolFeeList.length, "poolFeeList != totalPathLength");
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

import '@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol';

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
pragma solidity >=0.6.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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