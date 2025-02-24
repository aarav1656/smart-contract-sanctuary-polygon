/**
 *Submitted for verification at polygonscan.com on 2022-09-18
*/

// File: contracts/uniswap/IUniswapV2Callee.sol


pragma solidity >=0.5.0;

interface IUniswapV2Callee {
    function uniswapV2Call(address sender, uint amount0, uint amount1, bytes calldata data) external;
}
// File: contracts/uniswap/IUniswapV2Pair.sol


pragma solidity >=0.5.0;

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

// File: contracts/uniswap/IUniswapV2Factory.sol


pragma solidity >=0.5.0;

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

// File: contracts/uniswap/IUniswapV2Router01.sol


pragma solidity >=0.6.2;

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

// File: contracts/uniswap/IUniswapV2Router02.sol


pragma solidity >=0.6.2;


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

// File: @openzeppelin/contracts/utils/Strings.sol


// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


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
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: contracts/Arbitrage.sol


pragma solidity ^0.8.0;








interface IArbitrage {
    /**
     * @dev Emitted when a trade is executed
     */
    event trade_copmleted(TradeInstruction[] instructions, uint input, uint output);
    /**
     * @dev Emitted when a deposit occures
     */
    event deposit_copmleted(uint deposited, uint total_deposited);
    /**
     * @dev Emitted when a withdrawl occures
     */
    event withdrawl_copmleted(uint withdrawl, uint total_deposited);
}

struct TradeInstruction {
  address exchange;
  address[] path;
  uint input;
  uint output;
}

struct TradingPair {
  address token0;
  address token1;
  uint reserve0;
  uint reserve1;
  address pair;
}

contract Arbitrage is Ownable, IArbitrage, IUniswapV2Callee {
  IERC20 base_token;
  address private _permissionedPairAddress = address(0);   
  
  uint private unlocked = 1;
  modifier lock() {
      require(unlocked == 1, 'Arbitrage: LOCKED');
      unlocked = 0;
      _;
      unlocked = 1;
  }

  constructor(
    address base_token_address
  ) {
    base_token = IERC20(base_token_address);
  }

  function updateBaseToken(
    address base_token_address
  ) public onlyOwner {
    base_token = IERC20(base_token_address);
  }

  function getBaseToken() public view returns (address){
    return address(base_token);
  }


  function deposit(uint256 amount) public {
    address addr = _msgSender();
    require(amount > 0, "Error insufficeint deposit amount");
    require(
      base_token.transferFrom(addr, address(this), amount),
      "Error insufficient funds to pay fee"
    );
    emit deposit_copmleted(amount, getTradeBalance());
  }

  function getTradeBalance() public view returns (uint256) {
    address addr = address(this);
    return base_token.balanceOf(addr);
  }

  function withdraw(uint256 amount) public onlyOwner {
    address addr = _msgSender();
    require(amount > 0, "Error insufficeint withdrawl amount");
    require(amount <= getTradeBalance(), "Error withdrawl is too large");
    require(base_token.transfer(addr, amount), "Error occured withdrawing tokens");
    emit withdrawl_copmleted(amount, getTradeBalance());
  }

  function withdraw_other_token(address token_address, uint256 amount) public onlyOwner {
    address addr = _msgSender();
    IERC20 token = IERC20(token_address);
    require(amount > 0, "Error insufficeint withdrawl amount");
    require(amount <= token.balanceOf(address(this)), "Error withdrawl is too large");
    token.transfer(addr, amount);
  }

  function get_pairs_in_path(TradeInstruction[] calldata instructions) public onlyOwner view returns (TradingPair[] memory) {
    uint path_length = 0;
    for (uint i = 0; i < instructions.length; i++) {
      path_length += instructions[i].path.length - 1;
    }
    TradingPair[] memory pairs = new TradingPair[](path_length);

    uint current_path_position = 0;
    for (uint i = 0; i < instructions.length; i++) {
      IUniswapV2Router02 router = IUniswapV2Router02(instructions[i].exchange);
      IUniswapV2Factory factory = IUniswapV2Factory(router.factory());
      for(uint j = 0; j < instructions[i].path.length - 1; j++) {
        address current_pair_address = factory.getPair(instructions[i].path[j], instructions[i].path[j + 1]);
        require(current_pair_address != address(0), "Error: get_pairs_in_path: token pair does not exist");
        IUniswapV2Pair current_pair = IUniswapV2Pair(current_pair_address);
        (uint112 reserve0, uint112 reserve1,) = current_pair.getReserves();
        pairs[current_path_position] = TradingPair(
          current_pair.token0(),
          current_pair.token1(),
          reserve0,
          reserve1,
          current_pair_address
        );
        current_path_position += 1;
      }
    }

    return pairs;
  }

  function get_expected_output(TradeInstruction[] calldata instructions) public onlyOwner view returns (uint[][] memory) {
    uint instruction_count = instructions.length;
    uint[][] memory output = new uint256[][](instruction_count);
    uint out = instructions[0].input;
    for (uint i = 0; i < instructions.length; i++) {
      IUniswapV2Router02 router = IUniswapV2Router02(instructions[i].exchange);
      uint[] memory amountsOut = router.getAmountsOut(out, instructions[i].path);
      out = amountsOut[amountsOut.length - 1];
      output[i] = amountsOut;
    }
    return output;
  }

  function execute_trade(TradeInstruction[] calldata instructions) public onlyOwner lock {
    uint instruction_count = instructions.length;
    uint[][] memory output = new uint256[][](instruction_count);
    for (uint i = 0; i < instructions.length; i++) {
      TradeInstruction memory instruction = instructions[i];
      IUniswapV2Router02 router = IUniswapV2Router02(instruction.exchange);
      IERC20 token = IERC20(instruction.path[0]);
      require(instruction.input > 0, "Error insufficeint trade amount");
      require(instruction.input <= token.balanceOf(address(this)), "Error trade size is too large");
      require(
        token.approve(instruction.exchange, instruction.input),
        "Error token: approval failed"
      );
      output[i] = router.swapExactTokensForTokens(
        instruction.input,
        instruction.output,
        instruction.path, 
        address(this),
        block.timestamp + 20);
    }
    emit trade_copmleted(
      instructions,
      output[0][0],
      output[output.length - 1][output[output.length - 1].length - 1]
    );
  }

  function execute_flashloan_trade(TradeInstruction[] memory instructions) public onlyOwner lock {
    IUniswapV2Router02 router = IUniswapV2Router02(instructions[0].exchange);
    _permissionedPairAddress = IUniswapV2Factory(
      router.factory()
      ).getPair(
        instructions[0].path[0],
        instructions[0].path[1]
      );
    address pairAddress = _permissionedPairAddress; // gas efficiency
    require(pairAddress != address(0), "Requested _token is not available.");
    address token0 = IUniswapV2Pair(pairAddress).token0();
    address token1 = IUniswapV2Pair(pairAddress).token1();
    (uint256 reserve0, uint256 reserve1, ) = IUniswapV2Pair(pairAddress).getReserves();
    (uint256 reserveIn, uint256 reserveOut) = instructions[0].path[0] == token0 ? (reserve0, reserve1) : (reserve1, reserve0);

    uint amountIn = instructions[0].input;
    uint amountOut = router.getAmountOut(amountIn, reserveIn, reserveOut);

    uint256 amount0Out = instructions[0].path[0] == token0 ? 0 : amountOut;
    uint256 amount1Out = instructions[0].path[0] == token1 ? 0 : amountOut;

    instructions[0].input = amountOut;
    bytes memory data = abi.encode(
        instructions,
        amountIn
    );
    IUniswapV2Pair(pairAddress).swap(amount0Out, amount1Out, address(this), data);
  }

  // @notice Function is called by the Uniswap V2 pair's `swap` function
  // This occurs after tokens are paid to this contract, but this call needs to pay tokens
  // Back to Uniswap V2 Pair contract
  function uniswapV2Call(address sender, uint /*amount0*/, uint /*amount1*/, bytes calldata data) external override {
    address pairAddress = _permissionedPairAddress; // gas efficiency
    require(sender == address(this), "Error: uniswapV2Call: only this contract may initiate");
    require(msg.sender == pairAddress, "Error: uniswapV2Call: Only the IUniswapV2Pair specified in start_flashloan may call");
    // decode data
    (
        TradeInstruction[] memory instructions,
        uint amountToPayToPair
    ) = abi.decode(data, (TradeInstruction[], uint));

    require(amountToPayToPair > 0, "Error: uniswapV2Call: No amountToPayToPair was specified");
    require(instructions.length > 0, "Error: uniswapV2Call: No trade instructions were specified");

    IERC20 token = IERC20(instructions[0].path[1]);
    uint ballance = token.balanceOf(address(this));

    require(instructions[0].input <= ballance, "Error: uniswapV2Call: flashloan unsuccessful");
    address borrowed_token = instructions[0].path[0];
    uint instruction_count = instructions.length;
    uint[][] memory output = new uint256[][](instruction_count);
    for (uint i = 0; i < instructions.length; i++) {
      TradeInstruction memory instruction = instructions[i];
      IUniswapV2Router02 router = IUniswapV2Router02(instruction.exchange);
      if (i > 0) {
        token = IERC20(instruction.path[1]);
      }
      require(instruction.input > 0, "Error insufficeint trade amount");
      require(
        token.approve(instruction.exchange, instruction.input),
        "Error token: approval failed"
      );
      if (i == 0) {
        address[] memory new_path = new address[](instruction.path.length - 1);
        for (uint j = 0; j < instruction.path.length - 1; j += 1) {
          new_path[j] = instruction.path[j + 1];
        }
        instruction.path = new_path;
      }
      // if after flash swap we no longer need to trade on this exchange, then lets not
      // try to trade with a path length of 1
      if (instruction.path.length > 1) {
        output[i] = router.swapExactTokensForTokens(
          instruction.input,
          instruction.output,
          instruction.path, 
          address(this),
          block.timestamp + 20);
      }
    }
    IERC20(borrowed_token).transfer(pairAddress, amountToPayToPair);
  }
}