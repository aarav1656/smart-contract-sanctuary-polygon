/**
 *Submitted for verification at polygonscan.com on 2022-08-15
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.14;

// About the rules of interfaces and etc: 
// https://jamesbachini.com/solidity-interface/#uniswap-v3-swap-interface-example
// Can import some interfaces via openzeppelin or just copy paste in the
// code

//Interface for IERC20 token and Uniswap execution --> Swap
//Most of the dex is a folk of UniSwap so this will work in ethereum
//network for most of the dex.

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

interface IUniswapV2Router {
  function getAmountsOut(uint256 amountIn, address[] memory path) external view returns (uint256[] memory amounts);
  function swapExactTokensForTokens(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external returns (uint256[] memory amounts);
}

interface IUniswapV2Pair {
  function token0() external view returns (address);
  function token1() external view returns (address);
  function swap(uint256 amount0Out,	uint256 amount1Out,	address to,	bytes calldata data) external;
}


contract SwapTradeExecution {
    address owner;

    constructor(){
        // Set the owner to the account that deployes the contract
        owner = msg.sender;
    }
    
    modifier onlyOwner() {
        // Only owner can execute some functions
        require(msg.sender==owner,"Only the owner is allowed to execute");
        _;
    }

    function swap(address router, address _tokenIn, address _tokenOut, uint256 _amount) private {
        // Single swap function for uniswap v2 swap.
		IERC20(_tokenIn).approve(router, _amount);
		address[] memory path;
		path = new address[](2);
		path[0] = _tokenIn;
		path[1] = _tokenOut;
		uint deadline = block.timestamp + 300;
		IUniswapV2Router(router).swapExactTokensForTokens(_amount, 1, path, address(this), deadline);
	}

    function getAmountOutMin(address router, address _tokenIn, address _tokenOut, uint256 _amount) public view returns (uint256) {
        // Check, for a specific address, calculate how many _tokenOut
        // can be swapped out by swapping _tokenIn amount of another token
        // path is an array of address, stored in memory 
        address[] memory path;
        path = new address[](2);
        path[0] = _tokenIn;
        path[1] = _tokenOut;
        uint256[] memory amountOutMins = IUniswapV2Router(router).getAmountsOut(_amount, path);
        return amountOutMins[path.length -1];
    }

    function estimateDualDexTrade(address _router1, address _router2, address _token1, address _token2, uint256 _amount) external view returns (uint256) {
        uint256 amtBack1 = getAmountOutMin(_router1, _token1, _token2, _amount);
        uint256 amtBack2 = getAmountOutMin(_router2, _token2, _token1, amtBack1);
        return amtBack2;
    }

    function dualDexTrade(address _router1, address _router2, address _token1, address _token2, uint256 _amount) external onlyOwner {
        uint startBalance = IERC20(_token1).balanceOf(address(this));
        uint token2InitialBalance = IERC20(_token2).balanceOf(address(this));
        swap(_router1,_token1, _token2,_amount);
        uint token2Balance = IERC20(_token2).balanceOf(address(this));
        uint tradeableAmount = token2Balance - token2InitialBalance;
        swap(_router2,_token2, _token1,tradeableAmount);
        uint endBalance = IERC20(_token1).balanceOf(address(this));
        require(endBalance > startBalance, "Zero profit trades checked out.");
    }
    
    function tokenBalance(address token) public view returns (uint256) {
        IERC20 token = IERC20(token);
        return token.balanceOf(address(this));
    }

    function withdrawFunds(address token) external onlyOwner {
        IERC20 token = IERC20(token);
        uint balance = token.balanceOf(address(this));
        require(balance>0,"No avaliable fund to withdraw");
        token.transfer(msg.sender,balance);
    }

  }