/**
 *Submitted for verification at polygonscan.com on 2022-11-04
*/

//SPDX-License-Identifier: MIT

pragma solidity ^ 0.8.7;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() external view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() external virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) external virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


interface IERC20 {
	function totalSupply() external view returns (uint);
	function balanceOf(address account) external view returns (uint);
	function transfer(address recipient, uint amount) external returns (bool);
	function allowance(address owner, address spender) external view returns (uint);
	function approve(address spender, uint amount) external returns (bool);
	function transferFrom(address sender, address recipient, uint amount) external returns (bool);
	event Transfer(address indexed from, address indexed to, uint value);
	event Approval(address indexed owner, address indexed spender, uint value);
}


interface IPool {
    function flashLoanSimple(
    address receiverAddress,
    address asset,
    uint256 amount,
    bytes calldata params,
    uint16 referralCode
  ) external;
}


interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}


interface IUniswapV3SwapCallback {
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}


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

    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

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

    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}

contract FlashLoanAAVE is Ownable {

    address pool;
    address public buyToken; //token to buy with asset
    IUniswapV2Router02 public sellDexRouter; // sell the loan token
    IUniswapV2Router02 public buyDexRouter; // buy the loan token
    ISwapRouter public uniswapRouter;
    uint256 sellAmount;
    bool public sellV3;
    bool public buyV3;
    uint24 public sellFee;
    uint24 public buyFee;

    constructor(address _aaveLendingPool)  {
        require(_aaveLendingPool != address(0), "Invalid Pool Address");
        pool = _aaveLendingPool;
    }
    
    function executeOperation(
        address asset,
        uint256 amount,
        uint256 premium//,
        // address initiator,
        // bytes calldata params
    ) external returns (bool){
        IERC20(asset).approve(msg.sender, amount+premium);

        _sellAsset(asset);
        _buyAsset(asset);
        return true;
    }

    // sell the flash loan asset to buyTokenUsingAsset from sellDexRouter
    function _sellAsset(address asset_) internal {
        IERC20 sellAsset = IERC20(asset_);
        sellAsset.approve(address(sellDexRouter), sellAmount);

        if(sellV3){
            sellAsset.approve(address(uniswapRouter), sellAmount);
            uniswapRouter.exactInputSingle{value: 0}(
                ISwapRouter.ExactInputSingleParams({
                    tokenIn: asset_,
                    tokenOut: buyToken,
                    fee: sellFee,
                    recipient: address(this),
                    deadline: block.timestamp,
                    amountIn: sellAmount,
                    amountOutMinimum: 0,
                    sqrtPriceLimitX96: 0
                })
            );
            
        } else {
            address[] memory path;
            if(asset_ == sellDexRouter.WETH()) {
                path = new address[](2);
                path[0] = asset_;
                path[1] = buyToken;
            } else {
                path = new address[](3);
                path[0] = asset_;
                path[1] = sellDexRouter.WETH();
                path[2] = buyToken;
            }

            sellDexRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                sellAmount,
                0,
                path,
                address(this),
                block.timestamp
            );
        }

    }

    // buy asset using buyTokenUsingAsset from buyDexRouter
    function _buyAsset(address asset_) internal {
        if(buyV3){
            IERC20(buyToken).approve(address(uniswapRouter), IERC20(buyToken).balanceOf(address(this)));
            uniswapRouter.exactInputSingle{value: 0}(
                ISwapRouter.ExactInputSingleParams({
                    tokenIn: buyToken,
                    tokenOut: asset_,
                    fee: buyFee,
                    recipient: address(this),
                    deadline: block.timestamp,
                    amountIn: IERC20(buyToken).balanceOf(address(this)),
                    amountOutMinimum: 0,
                    sqrtPriceLimitX96: 0
                })
            );
        } else {
            IERC20 sellToken = IERC20(buyToken);
            sellToken.approve(address(buyDexRouter), sellToken.balanceOf(address(this)));

            address[] memory path;
            if(asset_ == buyDexRouter.WETH()){
                path = new address[](2);
                path[0] = buyToken;
                path[1] = asset_;
            } else {
                path = new address[](3);
                path[0] = buyToken;
                path[1] = buyDexRouter.WETH();
                path[2] = asset_;
            }

            buyDexRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                sellToken.balanceOf(address(this)), 
                0,
                path,
                address(this),
                block.timestamp
            );
        }

    }


    function flashloan (
        address _flashAsset, 
        uint256 _flashAmount,
        address _buyToken,
        address _sellDexRouter,
        address _buyDexRouter,
        bool _sellUniswapV3,
        bool _buyUniswapV3,
        uint24 _sellFee,
        uint24 _buyFee
    ) external onlyOwner{
        buyToken = _buyToken;
        sellDexRouter = IUniswapV2Router02(_sellDexRouter);
        buyDexRouter = IUniswapV2Router02(_buyDexRouter);
        sellV3 = _sellUniswapV3;
        buyV3 = _buyUniswapV3;
        sellFee = _sellFee;
        buyFee = _buyFee;
        sellAmount = _flashAmount;

        if(sellV3){
            uniswapRouter = ISwapRouter(_sellDexRouter);
        }
        if(buyV3){
            uniswapRouter = ISwapRouter(_buyDexRouter);
        }

        IPool(pool).flashLoanSimple(address(this), _flashAsset, _flashAmount, "0x", 0);
    }

	function recoverEth() external onlyOwner {
		payable(msg.sender).transfer(address(this).balance);
	}

	function recoverTokens(address tokenAddress, uint256 amount) external onlyOwner {
		IERC20 token = IERC20(tokenAddress);
		token.transfer(msg.sender, amount);
	}
    
	receive() external payable{}
}