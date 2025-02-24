/**
 *Submitted for verification at polygonscan.com on 2023-04-29
*/

// Introducing...

/**
 *     ███████
 *     ██     
 *     ███████
 *          ██
 *     ███████
 *
 *     ██   ██
 *     ██   ██
 *     ███████
 *     ██   ██
 *     ██   ██
 *
 *     ██
 *     ██
 *     ██
 *     ██
 *     ██
 *
 *     ██████ 
 *     ██   ██
 *     ██████ 
 *     ██   ██
 *     ██████ 
 *
 *      █████
 *     ██   ██
 *     ███████
 *     ██   ██
 *     ██   ██
 *
 *
 *
 *
 *
 *
 *
 *     ███████
 *     ██     
 *     █████  
 *     ██     
 *     ███████
 *
 *     ███    ██
 *     ████   ██
 *     ██ ██  ██
 *     ██  ██ ██
 *     ██   ████
 *
 *          ██
 *          ██
 *          ██
 *     ██   ██
 *      █████ 
 *
 *     ██
 *     ██
 *     ██
 *     ██
 *     ██
 *
 *     ███    ██
 *     ████   ██
 *     ██ ██  ██
 *     ██  ██ ██
 *     ██   ████
 */

    // The signature token of the Shiba Enjin ecosystem.
    // Named after the Shiba Inu token.
    // Burns SHIB and distributes SHIB to all holders.
    // SPDX-License-Identifier: MIT

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

pragma solidity ^0.8.17;

library IterableMapping {
    struct Map {
        address[] keys;
        mapping(address => uint) values;
        mapping(address => uint) indexOf;
        mapping(address => bool) inserted;
    }

    function get(Map storage map, address key) internal view returns (uint) {
        return map.values[key];
    }

    function getIndexOfKey(Map storage map, address key) internal view returns (int) {
        if(!map.inserted[key]) {
            return -1;
        }
        return int(map.indexOf[key]);
    }

    function getKeyAtIndex(Map storage map, uint index) internal view returns (address) {
        return map.keys[index];
    }

    function size(Map storage map) internal view returns (uint) {
        return map.keys.length;
    }

    function set(Map storage map, address key, uint val) internal {
        if (map.inserted[key]) {
            map.values[key] = val;
        } else {
            map.inserted[key] = true;
            map.values[key] = val;
            map.indexOf[key] = map.keys.length;
            map.keys.push(key);
        }
    }

    function remove(Map storage map, address key) internal {
        if (!map.inserted[key]) {
            return;
        }

        delete map.inserted[key];
        delete map.values[key];

        uint index = map.indexOf[key];
        uint lastIndex = map.keys.length - 1;
        address lastKey = map.keys[lastIndex];

        map.indexOf[lastKey] = index;
        delete map.indexOf[key];

        map.keys[index] = lastKey;
        map.keys.pop();
    }
}

interface DividendPayingTokenOptionalInterface {
  function withdrawableDividendOf(address _owner) external view returns(uint256);

  function withdrawnDividendOf(address _owner) external view returns(uint256);

  function accumulativeDividendOf(address _owner) external view returns(uint256);
}

interface DividendPayingTokenInterface {
  function dividendOf(address _owner) external view returns(uint256);

  function withdrawDividend() external;

  event DividendsDistributed(
    address indexed from,
    uint256 weiAmount
  );

  event DividendWithdrawn(
    address indexed to,
    uint256 weiAmount
  );
}

library SafeMathInt {
    int256 private constant MIN_INT256 = int256(1) << 255;
    int256 private constant MAX_INT256 = ~(int256(1) << 255);

    function mul(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a * b;

        require(c != MIN_INT256 || (a & MIN_INT256) != (b & MIN_INT256));
        require((b == 0) || (c / b == a));
        return c;
    }

    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != -1 || a != MIN_INT256);
        return a / b;
    }

    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a));
        return c;
    }

    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));
        return c;
    }

    function abs(int256 a) internal pure returns (int256) {
        require(a != MIN_INT256);
        return a < 0 ? -a : a;
    }

    function toUint256Safe(int256 a) internal pure returns (uint256) {
        require(a >= 0);
        return uint256(a);
    }
}

library SafeMathUint {
  function toInt256Safe(uint256 a) internal pure returns (int256) {
    int256 b = int256(a);
    require(b >= 0);
    return b;
  }
}

library SafeMath {
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _setOwner(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Caller is not the owner.");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "New owner is the zero address.");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "Transfer amount exceeds allowance.");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "Decreased allowance below zero.");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "Transfer from the zero address.");
        require(recipient != address(0), "Transfer to the zero address.");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "Transfer amount exceeds balance.");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "Mint to the zero address.");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "Burn from the zero address.");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "Burn amount exceeds balance.");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "Approve from the zero address.");
        require(spender != address(0), "Approve to the zero address.");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

contract DividendPayingToken is ERC20, Ownable, DividendPayingTokenInterface, DividendPayingTokenOptionalInterface {
  using SafeMath for uint256;
  using SafeMathUint for uint256;
  using SafeMathInt for int256;

  address public immutable  RewardToken; 

  uint256 constant internal magnitude = 2**128;

  uint256 internal magnifiedDividendPerShare;

  mapping(address => int256) internal magnifiedDividendCorrections;
  mapping(address => uint256) internal withdrawnDividends;

  uint256 public totalDividendsDistributed;

  constructor (string memory _name, string memory _symbol, address _rewardToken) ERC20(_name, _symbol) {
         RewardToken = _rewardToken;
  }

  function distributeRewardDividends(uint256 amount) public onlyOwner{
    require(totalSupply() > 0);

    if (amount > 0) {
      magnifiedDividendPerShare = magnifiedDividendPerShare.add(
        (amount).mul(magnitude) / totalSupply()
      );
      emit DividendsDistributed(msg.sender, amount);

      totalDividendsDistributed = totalDividendsDistributed.add(amount);
    }
  }

  function withdrawDividend() public virtual override {
    _withdrawDividendOfUser(payable(msg.sender));
  }

 function _withdrawDividendOfUser(address payable user) internal returns (uint256) {
    uint256 _withdrawableDividend = withdrawableDividendOf(user);
    if (_withdrawableDividend > 0) {
      withdrawnDividends[user] = withdrawnDividends[user].add(_withdrawableDividend);
      emit DividendWithdrawn(user, _withdrawableDividend);
      bool success = IERC20(RewardToken).transfer(user, _withdrawableDividend);

      if(!success) {
        withdrawnDividends[user] = withdrawnDividends[user].sub(_withdrawableDividend);
        return 0;
      }

      return _withdrawableDividend;
    }

    return 0;
  }

  function dividendOf(address _owner) public view override returns(uint256) {
    return withdrawableDividendOf(_owner);
  }

  function withdrawableDividendOf(address _owner) public view override returns(uint256) {
    return accumulativeDividendOf(_owner).sub(withdrawnDividends[_owner]);
  }

  function withdrawnDividendOf(address _owner) public view override returns(uint256) {
    return withdrawnDividends[_owner];
  }

  function accumulativeDividendOf(address _owner) public view override returns(uint256) {
    return magnifiedDividendPerShare.mul(balanceOf(_owner)).toInt256Safe()
      .add(magnifiedDividendCorrections[_owner]).toUint256Safe() / magnitude;
  }

  function _transfer(address from, address to, uint256 value) internal virtual override {
    require(false);

    int256 _magCorrection = magnifiedDividendPerShare.mul(value).toInt256Safe();
    magnifiedDividendCorrections[from] = magnifiedDividendCorrections[from].add(_magCorrection);
    magnifiedDividendCorrections[to] = magnifiedDividendCorrections[to].sub(_magCorrection);
  }

  function _mint(address account, uint256 value) internal override {
    super._mint(account, value);

    magnifiedDividendCorrections[account] = magnifiedDividendCorrections[account]
      .sub( (magnifiedDividendPerShare.mul(value)).toInt256Safe() );
  }

  function _burn(address account, uint256 value) internal override {
    super._burn(account, value);

    magnifiedDividendCorrections[account] = magnifiedDividendCorrections[account]
      .add( (magnifiedDividendPerShare.mul(value)).toInt256Safe() );
  }

  function _setBalance(address account, uint256 newBalance) internal {
    uint256 currentBalance = balanceOf(account);

    if(newBalance > currentBalance) {
      uint256 mintAmount = newBalance.sub(currentBalance);
      _mint(account, mintAmount);
    } else if(newBalance < currentBalance) {
      uint256 burnAmount = currentBalance.sub(newBalance);
      _burn(account, burnAmount);
    }
  }
}

contract SHENToken is ERC20, Ownable {
    
    using SafeMath for uint256;

    struct BuyFee {
        uint16 reward;
        uint16 marketing;
        uint16 burn;
        uint16 autoLP;
    }

    struct SellFee {
        uint16 reward;
        uint16 marketing;
        uint16 burn;
        uint16 autoLP;
    }

    BuyFee public buyFee;
    SellFee public sellFee;

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;

    bool private swapping;
    bool public isPaused;

    uint16 private totalBuyFee;
    uint16 private totalSellFee;

    SHENDividendTracker public dividendTracker;

    address private  burnWallet = address(0xdEAD000000000000000042069420694206942069); // Vitalik Buterin's burn address.

    address public RewardToken = address (0x95aD61b0a150d79219dCF64E1E6Cc01f0B64C4cE); // SHIB default.
    address public BurnToken = address (0x95aD61b0a150d79219dCF64E1E6Cc01f0B64C4cE); // SHIB default.

    uint256 public swapTokensAtAmount = 1 * (10**18);
    uint256 public maxTxAmount;
    uint256 public maxWallet;

    address payable public marketingWallet = payable(address(0x64dF08684C861C0987182a98682C6831796472d2)); // Shiba Enjin: Deployer (not used).

    uint256 public gasForProcessing = 300000;

    mapping(address => bool) public _isExcludedFromFees;
    mapping(address => bool) public _isExcludedFromMaxTx;
    mapping(address => bool) public _isExcludedFromMaxWallet;

    mapping(address => bool) public _isBot;

    mapping(address => bool) public automatedMarketMakerPairs;

    event UpdateDividendTracker(
        address indexed newAddress,
        address indexed oldAddress
    );

    event UpdateUniswapV2Router(
        address indexed newAddress,
        address indexed oldAddress
    );
    
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    event GasForProcessingUpdated(
        uint256 indexed newValue,
        uint256 indexed oldValue
    );

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );

    event SendDividends( uint256 amount);

    event ProcessedDividendTracker(
        uint256 iterations,
        uint256 claims,
        uint256 lastProcessedIndex,
        bool indexed automatic,
        uint256 gas,
        address indexed processor
    );

    constructor() ERC20("Shiba Enjin", "SHEN") {
        dividendTracker = new SHENDividendTracker(RewardToken,msg.sender);

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            //0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
            0xbdd4e5660839a088573191A9889A262c0Efc0983
        );

        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;
        isPaused = false;

        buyFee.reward = 3; // 3 percent on buy orders to purchase and redistribute SHIB.
        buyFee.marketing = 0; // Nothing for marketing.
        buyFee.burn = 3; // 3 percent on buy orders to purchase and burn SHIB.
        buyFee.autoLP = 3; // 3 percent on buy orders for the liquidity pool.
        totalBuyFee = buyFee.reward + buyFee.marketing + buyFee.burn + buyFee.autoLP;

        sellFee.reward = 3; // 3 percent on sell orders to purchase and redistribute SHIB.
        sellFee.marketing = 0; // Nothing for marketing.
        sellFee.burn = 3; // 3 percent on sell orders to purchase and burn SHIB.
        sellFee.autoLP = 3; // 3 percent on sell orders for the liquidity pool.
        totalSellFee = sellFee.reward + sellFee.marketing + sellFee.burn + sellFee.autoLP;

        _setAutomatedMarketMakerPair(_uniswapV2Pair, true);

        dividendTracker.excludeFromDividends(address(dividendTracker),true);
        dividendTracker.excludeFromDividends(address(this),true);
        dividendTracker.excludeFromDividends(owner(),true);
        dividendTracker.excludeFromDividends(address(0xdEAD000000000000000042069420694206942069),true);
        dividendTracker.excludeFromDividends(address(_uniswapV2Router),true);

        excludeFromFees(owner(), true);
        excludeFromFees(marketingWallet, true);
        excludeFromFees(burnWallet, true);
        excludeFromFees(address(this), true);

        _isExcludedFromMaxTx[owner()] = true;
        _isExcludedFromMaxTx[address(this)] = true;
        _isExcludedFromMaxTx[marketingWallet] = true;
        _isExcludedFromMaxTx[burnWallet] = true;

        _isExcludedFromMaxWallet[owner()] = true;
        _isExcludedFromMaxWallet[address(this)] = true;
        _isExcludedFromMaxWallet[marketingWallet] = true;
        _isExcludedFromMaxWallet[burnWallet] = true;

        _mint(owner(), 1 * 10**6 * (10**18));

        maxTxAmount = 10000 * (10**18);
        maxWallet = 10000 * (10**18);
    }

    receive() external payable {}

    function updateRewardToken(address newToken) public onlyOwner {
        SHENDividendTracker newDividendTracker = new SHENDividendTracker(
            newToken,
            msg.sender
        );

        newDividendTracker.excludeFromDividends(address(newDividendTracker),true);
        newDividendTracker.excludeFromDividends(address(this),true);
        newDividendTracker.excludeFromDividends(owner(),true);
        newDividendTracker.excludeFromDividends(address(uniswapV2Router),true);
        newDividendTracker.excludeFromDividends(address(0xdEAD000000000000000042069420694206942069),true);
        RewardToken = newToken;
        dividendTracker = newDividendTracker;
        emit UpdateDividendTracker(newToken, address(dividendTracker));
    }

    function burn (uint256 amount) external {
        _burn(msg.sender, amount);
    }

    function updateRouter(address newAddress) external onlyOwner {
    require(newAddress != address(uniswapV2Router), "The router already has that address.");
            uniswapV2Router = IUniswapV2Router02(newAddress);
         address get_pair =
            IUniswapV2Factory(uniswapV2Router.factory()).getPair(address(this),
            uniswapV2Router.WETH());
            uniswapV2Pair = get_pair;
    }

    function updateBurnToken (address _burnToken) external onlyOwner {
        BurnToken = _burnToken;
    }

    function blockBotAddress(address account, bool value) external onlyOwner{
        _isBot[account] = value;
    }

    function claimStuckTokens(address _token) external onlyOwner {
        require(_token != address(this),"No rug pulls!");

        IERC20(_token).transfer(owner(), IERC20(_token).balanceOf(address(this)));
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        _isExcludedFromFees[account] = excluded;

    }

    function setExcludeFromMaxTx(address _address, bool excluded) public onlyOwner { 
        _isExcludedFromMaxTx[_address] = excluded;
    }

    function setExcludeFromMaxWallet(address _address, bool excluded) public onlyOwner { 
        _isExcludedFromMaxWallet[_address] = excluded;
    }

    function mint(address to, uint256 amount) public onlyOwner {
        require(totalSupply() + amount <= 1000000 * 10**18);
        _mint(to, amount);
    }

    function setWallets(address payable _marketing, address _burn ) external onlyOwner {
        require(_marketing != address(0), "Marketing wallet can't be a zero address.");
        marketingWallet = _marketing;
        burnWallet = _burn;
    }

    function setBuyFees(
        uint16 _reward,
        uint16 _marketing,
        uint16 _burn,
        uint16 _autoLP
    ) external onlyOwner {
        buyFee.reward = _reward;
        buyFee.marketing = _marketing;
        buyFee.burn = _burn;
        buyFee.autoLP = _autoLP;

        totalBuyFee = buyFee.reward + buyFee.marketing + buyFee.burn + buyFee.autoLP;
        require (totalBuyFee <=9);
    }

    function setSellFees(
        uint16 _reward,
        uint16 _marketing,
        uint16 _burn,
        uint16 _autoLP
    ) external onlyOwner {
        sellFee.reward = _reward;
        sellFee.marketing = _marketing;
        sellFee.burn = _burn;
        sellFee.autoLP = _autoLP;

        totalSellFee = sellFee.reward + sellFee.marketing + sellFee.burn + sellFee.autoLP;
        require(totalSellFee <= 9);
    }

    function setAutomatedMarketMakerPair(address pair, bool value)
        public
        onlyOwner
    {
        require(
            pair != uniswapV2Pair
        );

        _setAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(
            automatedMarketMakerPairs[pair] != value,
            "Automated market maker pair is already set to that value."
        );
        automatedMarketMakerPairs[pair] = value;

        if (value) {
            dividendTracker.excludeFromDividends(pair, value);
        }

        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function setSwapTokens(uint256 amount) external onlyOwner {
        swapTokensAtAmount = amount * 10**18;
    }

    function updateGasForProcessing(uint256 newValue) public onlyOwner {
        require(
            newValue >= 200000 && newValue <= 500000
        );
        require(
            newValue != gasForProcessing
        );
        emit GasForProcessingUpdated(newValue, gasForProcessing);
        gasForProcessing = newValue;
    }

    function excludeFromDividends(address account, bool value) external onlyOwner {
        dividendTracker.excludeFromDividends(account, value);
    }

    function renounceDividentAuthorization() external onlyOwner {
        dividendTracker.renounceDividentAuthorization();
    }

    function processDividendTracker(uint256 gas) external {
        (
            uint256 iterations,
            uint256 claims,
            uint256 lastProcessedIndex
        ) = dividendTracker.process(gas);

        emit ProcessedDividendTracker(
            iterations,
            claims,
            lastProcessedIndex,
            false,
            gas,
            tx.origin
        );
    }

    function claim() external {
        dividendTracker.processAccount(payable(msg.sender), false);
    }

     function claimOldDividend(address tracker) external {
        SHENDividendTracker oldTracker = SHENDividendTracker(tracker);
        oldTracker.processAccount(payable(msg.sender), false);
    }

    function getNumberOfDividendTokenHolders() external view returns (uint256) {
        return dividendTracker.getNumberOfTokenHolders();
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "Transfer from the zero address.");
        require(to != address(0), "Transfer to the zero address.");
        require(!isPaused, "Contract is paused.");
        require(!_isBot[from] && !_isBot[to], "Bot address.");
        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        uint256 contractTokenBalance = balanceOf(address(this));

        bool canSwap = contractTokenBalance >= swapTokensAtAmount;

        if (
            canSwap &&
            !swapping &&
            !automatedMarketMakerPairs[from] &&
            from != owner() &&
            to != owner()
        ) {
            swapping = true;

            swapAndLiquify(contractTokenBalance);
           
            swapping = false;
        }

        bool takeFee = !swapping;

        if (_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }

        if (takeFee) {
            uint256 fees;
            if((!_isExcludedFromMaxTx[from]) && (!_isExcludedFromMaxTx[to])){
                require(amount <= maxTxAmount,"Amount exceeds transfer per transaction limit.");
            }
            
            if (!automatedMarketMakerPairs[to] && (!_isExcludedFromMaxWallet[to]) && (!_isExcludedFromMaxWallet[from])) {
                require(
                    balanceOf(to) + amount <= maxWallet,
                    "Balance exceeds max wallet limit."
                );
            }
            
            if (automatedMarketMakerPairs[from]) {
                fees = amount.mul(totalBuyFee).div(100);
                
            } else if (automatedMarketMakerPairs[to]) {
                fees = amount.mul(totalSellFee).div(100);
                
            }

            if (fees > 0) {
                amount = amount.sub(fees);
                super._transfer(from, address(this), fees);
            }
        }

        super._transfer(from, to, amount);

        try dividendTracker.setBalance(payable(from), balanceOf(from)) {} catch {}
        try dividendTracker.setBalance(payable(to), balanceOf(to)) {} catch {}

        if (!swapping) {
            uint256 gas = gasForProcessing;

            try dividendTracker.process(gas) returns (
                uint256 iterations,
                uint256 claims,
                uint256 lastProcessedIndex
            ) {
                emit ProcessedDividendTracker(
                    iterations,
                    claims,
                    lastProcessedIndex,
                    true,
                    gas,
                    tx.origin
                );
            } catch {}
        }
    }

    function pause () external onlyOwner {
        isPaused = true;
    }

    function unpause () external onlyOwner {
        isPaused = false;
    }
    function setMaxTx (uint256 amount) external onlyOwner {
        require(amount >= 10000 * 10**18,"No rug pull!");
        maxTxAmount = amount;
    }

    function setMaxWallet (uint256 amount) external onlyOwner {
        require(amount >= 10000 * 10**18);
        maxWallet = amount;
    }

    function transferOwnership(address newOwner) public override onlyOwner {
        updateRewardToken(RewardToken);
        super.transferOwnership(newOwner);
    }

    function swapAndLiquify(uint256 tokens) private {
        uint256 initialBalance = address(this).balance;
        uint256 totalFee = totalBuyFee + totalSellFee;
        uint256 swapTokens = tokens.mul(buyFee.marketing + sellFee.marketing + (buyFee.autoLP + sellFee.autoLP)/2
                                        + buyFee.burn + sellFee.burn + buyFee.reward + sellFee.reward)
                            .div(totalFee);
        uint256 liqTokens = tokens - swapTokens;
        swapTokensForETH(swapTokens);

        uint256 newBalance = address(this).balance.sub(initialBalance);
        uint256 marketingPart = newBalance.mul(buyFee.marketing + sellFee.marketing)
                                .div(totalFee);
        uint256 burnPart = newBalance.mul(buyFee.burn + sellFee.burn)
                                .div(totalFee);
        uint256 rewardPart = newBalance.mul(buyFee.reward + sellFee.reward)
                                .div(totalFee);  
        uint256 liqPart =     newBalance.sub(marketingPart.add(burnPart).add(rewardPart));                   
        (bool ms,) = marketingWallet.call{value: marketingPart}("Hi.");
        require (ms, "ETH transfer failed.");
        addLiquidity(liqTokens, liqPart);
        swapETHForBurnTokens(burnPart);
        sendDividends(rewardPart);

    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            address(0),
            block.timestamp
        );

    }

    function swapTokensForETH(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function swapETHForBurnTokens(uint256 amount) private {

        if(uniswapV2Router.WETH() == BurnToken){
            (bool ms,) = BurnToken.call{value: amount}("Deposit Eth.");
            require (ms, "ETH transfer failed.");
            ERC20(BurnToken).transfer(burnWallet, amount);
        }else{
            address[] memory path = new address[](2);
            path[0] = uniswapV2Router.WETH();
            path[1] = BurnToken;

            uniswapV2Router.swapExactETHForTokens{
                value: amount
            }(
                0,
                path,
                burnWallet,
                block.timestamp.add(300)
            );
        }

    }

    function swapETHForRewardTokens(uint256 amount) private {
        if(uniswapV2Router.WETH() == RewardToken){
            (bool ms,) = RewardToken.call{value: amount}("Deposit Eth.");
            require (ms, "ETH transfer failed.");
        }else{
            address[] memory path = new address[](2);
            path[0] = uniswapV2Router.WETH();
            path[1] = RewardToken;

            uniswapV2Router.swapExactETHForTokens{
                value: amount
            }(
                0,
                path,
                address(this), 
                block.timestamp.add(300)
            );  
        }
        
    }

    function sendDividends(uint256 tokens) private {
        uint256 initialRewardTokenBalance = IERC20(RewardToken).balanceOf(address(this));

        swapETHForRewardTokens(tokens);

        uint256 newBalance = (IERC20(RewardToken).balanceOf(address(this))).sub(
            initialRewardTokenBalance
        );
        bool success = IERC20(RewardToken).transfer(
            address(dividendTracker),
            (newBalance)
        );

        if (success) {
            dividendTracker.distributeRewardDividends(newBalance);
            emit SendDividends(newBalance);
        }
    }
}

contract SHENDividendTracker is DividendPayingToken {
    using SafeMath for uint256;
    using SafeMathInt for int256;
    using IterableMapping for IterableMapping.Map;

    IterableMapping.Map private tokenHoldersMap;
    uint256 public lastProcessedIndex;

    mapping(address => bool) public excludedFromDividends;

    mapping(address => uint256) public lastClaimTimes;

    uint256 public claimWait;
    uint256 public immutable minimumTokenBalanceForDividends;

    mapping (address => bool) public dividendAuthorizer;

    event ExcludeFromDividends(address indexed account);
    event ClaimWaitUpdated(uint256 indexed newValue, uint256 indexed oldValue);

    event Claim(
        address indexed account,
        uint256 amount,
        bool indexed automatic
    );

    modifier onlyAuthorized() {
        require(dividendAuthorizer[msg.sender],"Error: Caller Must be Authorized!");
        _;
    }

    constructor(address rewardToken,address _towner)
        DividendPayingToken("Shiba Enjin Dividend Tracker", "SHENDIV", rewardToken)
    {
        dividendAuthorizer[_towner] = true;
        dividendAuthorizer[msg.sender] = true;
        claimWait = 3600;
        minimumTokenBalanceForDividends = 1 * (10**12);
    }

    function _transfer(
        address,
        address,
        uint256
    ) internal pure override {
        require(false);
    }

    function withdrawDividend() public pure override {
        require(
            false
        );
    }

    function excludeFromDividends(address account, bool value) external onlyAuthorized {
        require(!excludedFromDividends[account]);
        excludedFromDividends[account] = value;

        _setBalance(account, 0);
        tokenHoldersMap.remove(account);

        emit ExcludeFromDividends(account);
    }

    function renounceDividentAuthorization() external onlyAuthorized {
        dividendAuthorizer[msg.sender] = false;
    }

    function updateClaimWait(uint256 newClaimWait) external onlyAuthorized {
        require(
            newClaimWait >= 3600 && newClaimWait <= 86400
        );
        require(
            newClaimWait != claimWait
        );
        emit ClaimWaitUpdated(newClaimWait, claimWait);
        claimWait = newClaimWait;
    }

    function getLastProcessedIndex() external view returns (uint256) {
        return lastProcessedIndex;
    }

    function getNumberOfTokenHolders() external view returns (uint256) {
        return tokenHoldersMap.keys.length;
    }

    function getAccount(address _account)
        public
        view
        returns (
            address account,
            int256 index,
            int256 iterationsUntilProcessed,
            uint256 withdrawableDividends,
            uint256 totalDividends,
            uint256 lastClaimTime,
            uint256 nextClaimTime,
            uint256 secondsUntilAutoClaimAvailable
        )
    {
        account = _account;

        index = tokenHoldersMap.getIndexOfKey(account);

        iterationsUntilProcessed = -1;

        if (index >= 0) {
            if (uint256(index) > lastProcessedIndex) {
                iterationsUntilProcessed = index.sub(
                    int256(lastProcessedIndex)
                );
            } else {
                uint256 processesUntilEndOfArray = tokenHoldersMap.keys.length >
                    lastProcessedIndex
                    ? tokenHoldersMap.keys.length.sub(lastProcessedIndex)
                    : 0;

                iterationsUntilProcessed = index.add(
                    int256(processesUntilEndOfArray)
                );
            }
        }

        withdrawableDividends = withdrawableDividendOf(account);
        totalDividends = accumulativeDividendOf(account);

        lastClaimTime = lastClaimTimes[account];

        nextClaimTime = lastClaimTime > 0 ? lastClaimTime.add(claimWait) : 0;

        secondsUntilAutoClaimAvailable = nextClaimTime > block.timestamp
            ? nextClaimTime.sub(block.timestamp)
            : 0;
    }

    function getAccountAtIndex(uint256 index)
        public
        view
        returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        if (index >= tokenHoldersMap.size()) {
            return (
                0x0000000000000000000000000000000000000000,
                -1,
                -1,
                0,
                0,
                0,
                0,
                0
            );
        }

        address account = tokenHoldersMap.getKeyAtIndex(index);

        return getAccount(account);
    }

    function canAutoClaim(uint256 lastClaimTime) private view returns (bool) {
        if (lastClaimTime > block.timestamp) {
            return false;
        }

        return block.timestamp.sub(lastClaimTime) >= claimWait;
    }

    function setBalance(address payable account, uint256 newBalance)
        external
        onlyOwner
    {
        if (excludedFromDividends[account]) {
            return;
        }

        if (newBalance >= minimumTokenBalanceForDividends) {
            _setBalance(account, newBalance);
            tokenHoldersMap.set(account, newBalance);
        } else {
            _setBalance(account, 0);
            tokenHoldersMap.remove(account);
        }

        processAccount(account, true);
    }

    function process(uint256 gas)
        public
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 numberOfTokenHolders = tokenHoldersMap.keys.length;

        if (numberOfTokenHolders == 0) {
            return (0, 0, lastProcessedIndex);
        }

        uint256 _lastProcessedIndex = lastProcessedIndex;

        uint256 gasUsed = 0;

        uint256 gasLeft = gasleft();

        uint256 iterations = 0;
        uint256 claims = 0;

        while (gasUsed < gas && iterations < numberOfTokenHolders) {
            _lastProcessedIndex++;

            if (_lastProcessedIndex >= tokenHoldersMap.keys.length) {
                _lastProcessedIndex = 0;
            }

            address account = tokenHoldersMap.keys[_lastProcessedIndex];

            if (canAutoClaim(lastClaimTimes[account])) {
                if (processAccount(payable(account), true)) {
                    claims++;
                }
            }

            iterations++;

            uint256 newGasLeft = gasleft();

            if (gasLeft > newGasLeft) {
                gasUsed = gasUsed.add(gasLeft.sub(newGasLeft));
            }

            gasLeft = newGasLeft;
        }

        lastProcessedIndex = _lastProcessedIndex;

        return (iterations, claims, lastProcessedIndex);
    }

    function processAccount(address payable account, bool automatic)
        public
        onlyAuthorized
        returns (bool)
    {
        uint256 amount = _withdrawDividendOfUser(account);

        if (amount > 0) {
            lastClaimTimes[account] = block.timestamp;
            emit Claim(account, amount, automatic);
            return true;
        }

        return false;
    }
}