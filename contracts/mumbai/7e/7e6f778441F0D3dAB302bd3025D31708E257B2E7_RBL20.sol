/**
 *Submitted for verification at polygonscan.com on 2022-11-26
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

interface IERC20 {
  function totalSupply() external view returns (uint256);
  function decimals() external pure returns (uint8);
  function balanceOf(address account) external view returns (uint256);
  function transfer(address recipient, uint256 amount) external returns (bool);
  function allowance(address owner, address spender) external view returns (uint256);
  function approve(address spender, uint256 amount) external returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IEXTERNAL {
  function externalBuyEvent(uint256 amount) external returns (bool);
  function externalSellEvent(uint256 amount) external returns (bool);
}

abstract contract Context {
  function _msgSender() internal view virtual returns (address) {
    return msg.sender;
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

  function owner() public view returns (address) {
    return _owner;
  }

  modifier onlyOwner() {
    require(_owner == _msgSender(), "Ownable: caller is not the owner");
    _;
  }

  function transferOwnership(address _newOwner) public virtual onlyOwner {
    emit OwnershipTransferred(_owner, _newOwner);
    _owner = _newOwner;
  }

}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
}

contract RBL20 is Context, IERC20, Ownable {
  using SafeMath for uint256;

  event Updated_Price(address indexed buyer, uint256 buyamount, uint256 tokenout, uint256 fromprice, uint256 toprice, uint256 wasrebalance,uint256 usdremain,uint256 soldprice);

  string constant _name = "RebalanceToken V1";
  string constant _symbol = "RBL20";
  uint8 constant _decimals = 18;
  uint256 constant _maxint = type(uint256).max;
  uint256 _totalSupply;
  uint256 _circularSupply;

  address public usdAddress;
  IERC20 public usdToken;

  uint256 public CURRENT_PRICE = 1*(10**_decimals)/1000;

  uint256 public INCREASE_RATE = 1;
  uint256 public INCREASE_ExRATE = 10;
  uint256 public INCREASE_CAP = 30;
  uint256 public INCREASE_FORCE = 100;
  uint256 public DENOMINATOR = 1000;

  uint256 public TOKEN_USD_REMAINING;
  uint256 public TOKEN_USD_RANGE = 100;

  uint256 public buy_fee;
  uint256 public sell_fee;

  address public receiver_burn;
  address public receiver_reserve;
  address public receiver_treasury;

  bool public isPublicBuy;

  address public ext_buy_address;
  address public ext_sell_address;

  mapping (address => uint256) private _balances;
  mapping (address => mapping (address => uint256)) private _allowances;

  mapping (address => bool) public _isBypassBuy;

  constructor(address _tokenAddress) {
    usdAddress = _tokenAddress;
    usdToken = IERC20(_tokenAddress);
    TOKEN_USD_REMAINING = TOKEN_USD_RANGE.mul(10**usdToken.decimals());
    _balances[msg.sender] = _circularSupply;
    emit Transfer(address(0), msg.sender, _circularSupply);
  }

  function changePublicBuyState() public onlyOwner returns (bool) {
    isPublicBuy = !isPublicBuy;
    return true;
  }

  function flagBypassBuy(address account,bool flag) public onlyOwner returns (bool) {
    _isBypassBuy[account] = flag;
    return true;
  }

  function getBuyPrice() public view returns(uint256) {
    return CURRENT_PRICE;
  }

  function getSoldPrice() public view returns(uint256) {
    if(_circularSupply>0){
      return usdToken.balanceOf(address(this)).mul(10**usdToken.decimals()).div(_circularSupply);
    }else{
      return 0;
    }
  }

  function BuyToken(uint256 _amountUSD) public returns (bool) {
    if(!_isBypassBuy[msg.sender]){
      require(isPublicBuy,"ERROR: PUBLIC BUY STATE WAS PAUSE");
    }
    uint256[] memory tokenout = tryBuyToken(_amountUSD);
    uint256 beforeprice = CURRENT_PRICE;
    usdToken.transferFrom(msg.sender,address(this),_amountUSD);
    _mint(msg.sender,tokenout[0].mul(10**usdToken.decimals()));
    CURRENT_PRICE = tokenout[1];
    TOKEN_USD_REMAINING = tokenout[3];
    if(ext_buy_address!=address(0)){
      IEXTERNAL e = IEXTERNAL(ext_buy_address);
      e.externalBuyEvent(_amountUSD);
    }
    emit Updated_Price(msg.sender,_amountUSD,beforeprice,tokenout[0],tokenout[1],tokenout[2],tokenout[3],tokenout[4]);
    return true;
  }

  function tryBuyToken(uint256 _amountUSD) public view returns (uint256[] memory) {
    uint256 tokenout = 0;
    uint256 usd_remain = TOKEN_USD_REMAINING; 
    uint256 cur_price = CURRENT_PRICE;
    uint256 was_rebalance = 0;
    uint256 usd_left = 0;
    uint256[] memory result = new uint256[](5);
    uint256 early_price = getSimmulatePrice(0,0);
    uint256 sold_price;
    do{
      if(_amountUSD>=usd_remain){
        tokenout = tokenout.add(usd_remain.div(cur_price));
        usd_left = usd_left.add(usd_remain);
        _amountUSD = _amountUSD.sub(usd_remain);
        usd_remain = TOKEN_USD_RANGE.mul(10**usdToken.decimals());
        sold_price = getSimmulatePrice(usd_left,tokenout);
        if(sold_price<early_price.mul(INCREASE_FORCE.add(DENOMINATOR)).div(DENOMINATOR)){
          cur_price = cur_price.add(cur_price.mul(INCREASE_ExRATE).div(DENOMINATOR));
        }else{
          cur_price = cur_price.add(cur_price.mul(INCREASE_RATE).div(DENOMINATOR)); 
        }
      }else{
        tokenout = tokenout.add(_amountUSD.div(cur_price));
        usd_left = usd_left.add(_amountUSD);
        usd_remain = usd_remain.sub(_amountUSD);
        _amountUSD = 0;
      }
      sold_price = getSimmulatePrice(usd_left,tokenout);
      result[4] = sold_price;
      if(sold_price>0){
        if(cur_price.mul(1000).div(sold_price)>=INCREASE_CAP.add(1000)){
          uint256 rebalanceprice = cur_price.sub(sold_price).div(2);
          cur_price = sold_price.add(rebalanceprice);
          was_rebalance = was_rebalance.add(1);
        }
      }
    }while(_amountUSD>0);
    result[0] = tokenout;
    result[1] = cur_price;
    result[2] = was_rebalance;
    result[3] = usd_remain;
    return result;
  }

  function getSimmulatePrice(uint256 usd_left,uint256 tokenout) internal view returns (uint256) {
    uint256 afterbalance = usdToken.balanceOf(address(this)).add(usd_left);
    uint256 sold_price = afterbalance.mul(10**usdToken.decimals()).div(_circularSupply.add(tokenout.mul(10**usdToken.decimals())));
    return sold_price;
  }

  function SellToken(uint256 _amountToken) public returns (bool) {
    uint256 outputusd = trySellToken(_amountToken);
    usdToken.transfer(msg.sender,outputusd);
    _burn(msg.sender,_amountToken);
    if(ext_sell_address!=address(0)){
      IEXTERNAL e = IEXTERNAL(ext_sell_address);
      e.externalSellEvent(_amountToken);
    }
    return true;
  }

  function trySellToken(uint256 _amountToken) public view returns (uint256) {
    uint256 sold_price = getSoldPrice();
    uint256 usdamount = _amountToken.mul(sold_price).div(10**18);
    if(sold_price>0){
      return usdamount;
    }else{
      return 0;
    }
  }

  function adjustMintingFee(uint256[] memory _feeamount,address[] memory _accounts) public onlyOwner returns(bool) {
    require(_feeamount[0]<=30,"ERROR: BUY FEE MUST NOT HIGHER THAN 3%");
    require(_feeamount[1]<=30,"ERROR: SELL FEE MUST NOT HIGHER THAN 3%");
    buy_fee = _feeamount[0];
    sell_fee = _feeamount[1];
    receiver_burn = _accounts[0];
    receiver_reserve = _accounts[1];
    receiver_treasury = _accounts[2];
    return true;
  }

  function symbol() public pure returns (string memory) { return _symbol; }
  function name() public pure returns (string memory) { return _name; }
  function maxint() public pure returns (uint256) { return _maxint; }
  function circularSupply() external view returns (uint256) { return _circularSupply; }
  function totalSupply() external view override returns (uint256) { return _totalSupply; }
  function decimals() external pure override returns (uint8) { return _decimals; }
  function balanceOf(address account) external view override returns (uint256) { return _balances[account]; }

  function transfer(address recipient, uint256 amount) external override returns (bool) {
    _transfer(msg.sender, recipient, amount);
    return true;
  }

  function allowance(address owner, address spender) external view override returns (uint256) {
    return _allowances[owner][spender];
  }

  function approve(address spender, uint256 amount) external override returns (bool) {
    _approve(msg.sender, spender, amount);
    return true;
  }

  function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
    if(_allowances[sender][msg.sender] != type(uint256).max){
    _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount);
    }
    _transfer(sender, recipient, amount);
    return true;
  }

  function _transfer(address sender, address recipient, uint256 amount) internal {
    require(sender != address(0));
    require(recipient != address(0));
    _balances[sender] = _balances[sender].sub(amount);
    _balances[recipient] = _balances[recipient].add(amount);
    emit Transfer(sender, recipient, amount);
  }

  function _approve(address owner, address spender, uint256 amount) internal {
    require(owner != address(0));
    require(spender != address(0));
    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }

  function _mint(address account, uint256 amount) internal {
    require(account != address(0));
    _totalSupply = _totalSupply.add(amount);
    _circularSupply = _circularSupply.add(amount);
    _balances[account] = _balances[account].add(amount);
    emit Transfer(address(0), account, amount);
  }

  function _burn(address account, uint256 amount) internal {
    require(account != address(0));
    _circularSupply = _circularSupply.sub(amount);
    _balances[account] = _balances[account].sub(amount);
    emit Transfer(account, address(0), amount);
  }

}