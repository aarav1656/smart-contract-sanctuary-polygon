/**
 *Submitted for verification at polygonscan.com on 2023-04-25
*/

/**
 *Submitted for verification at bscscan.io on 2020-09-11
*/

/**
 *Submitted for verification at bscscan.io on 12-09-2020
*/

// SD

pragma solidity ^0.5.0;
contract Context {
constructor () internal { }
function _msgSender() internal view returns (address payable) {
return msg.sender;
}
function _msgData() internal view returns (bytes memory) {
this;
return msg.data;
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
function mod(uint256 a, uint256 b) internal pure returns (uint256) {
return mod(a, b, "SafeMath: modulo by zero");
}
function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
require(b != 0, errorMessage);
return a % b;
}
}
interface IERC20 {
function totalSupply() external view returns (uint256);
function balanceOf(address account) external view returns (uint256);
function transfer(address recipient, uint256 amount) external returns (bool);
function allowance(address owner, address spender) external view returns (uint256);
function approve(address spender, uint256 amount) external returns (bool);
function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
event Transfer(address indexed from, address indexed to, uint256 value);
event Approval(address indexed owner, address indexed spender, uint256 value);
}
contract SD is Context, IERC20 {
using SafeMath for uint256;
mapping (address => uint256) private _balances;
mapping (address => mapping (address => uint256)) private _allowances;
string public symbol = "SD";
string public name = "Social Detoxify";
uint8 public decimals = 18;
uint256 public _totalSupply;

        
constructor() public {
    _totalSupply = 30400000000000000 * 10**uint(decimals);
    _balances[msg.sender] = _balances[msg.sender].add(_totalSupply);
    emit Transfer(address(0), msg.sender, _totalSupply);
}

function totalSupply() public view returns (uint256) {
return _totalSupply;
}
function balanceOf(address account) public view returns (uint256) {
return _balances[account];
}
function transfer(address recipient, uint256 amount) public returns (bool) {
_transfer(_msgSender(), recipient, amount);
return true;
}
function allowance(address owner, address spender) public view returns (uint256) {
return _allowances[owner][spender];
}
function approve(address spender, uint256 amount) public returns (bool) {
_approve(_msgSender(), spender, amount);
return true;
}
function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
_transfer(sender, recipient, amount);
_approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
return true;
}
function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
_approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
return true;
}
function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
_approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
return true;
}
function isContract(address _addr) private view returns (bool){
  uint32 size;
  assembly { size := extcodesize(_addr) }
  return (size > 0);
}

function _transfer(address sender, address recipient, uint256 amount) internal {
require(!isContract(recipient));
require(sender != address(0), "ERC20: transfer from the zero address");
require(recipient != address(0), "ERC20: transfer to the zero address");
_balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
_balances[recipient] = _balances[recipient].add(amount);
emit Transfer(sender, recipient, amount);
}

function _burn(address account, uint256 amount) internal {
require(account != address(0), "ERC20: burn from the zero address");
_balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
_totalSupply = _totalSupply.sub(amount);
emit Transfer(account, address(0), amount);
}
function _approve(address owner, address spender, uint256 amount) internal {
require(owner != address(0), "ERC20: approve from the zero address");
require(spender != address(0), "ERC20: approve to the zero address");
require(_balances[owner] >= amount, "ERC20: approve amount exceeds owner's balance");
_allowances[owner][spender] = amount;
emit Approval(owner, spender, amount);
}
function _burnFrom(address account, uint256 amount) internal {
_burn(account, amount);
_approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "ERC20: burn amount exceeds allowance"));
}

}