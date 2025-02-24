// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract Token {
    string private _name;
    string private _symbol;
    uint256 private _totalSupply;
    address _owner;

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) _allowance;

    event TransferEvent(
        address from,
        address to,
        uint256 amount
    );

    event MintEvent(
        address to,
        uint256 amount
    );

    event BurnEvent(
        address from,
        uint256 amount
    );

    modifier onlyOwner() {
        require(msg.sender == _owner, "Only the owner can call this function");
        _;
    }

    constructor(string memory name_, string memory symbol_){
        _name = name_;
        _symbol = symbol_;
        _totalSupply = 0;
        _owner = msg.sender;
    }

    function symbol() public view returns(string memory){
        return _symbol;
    }

    function name() public view returns(string memory){
        return _name;
    }

    function totalSupply() public view returns(uint256){
        return _totalSupply;
    }

    function balanceOf(address _account) public view returns(uint256){
        return balances[_account];
    }

    function transfer(uint256 _amount,address _to) public {
        require(_to != address(0), "Address can't be zero");
        require(balances[msg.sender] >= _amount, "Not enough balance");
        balances[msg.sender] -= _amount;
        balances[_to] += _amount;
        emit TransferEvent(msg.sender, _to, _amount);
    }

    function getAllowance(address _to) public view returns(uint256){
        return _allowance[msg.sender][_to];
    }

    function addAllowance(uint256 _amount, address _to) public{
        require(balances[msg.sender] >= _amount, "Not enough balance");
        require(_to!=address(0), "Give a valid address");
        _allowance[msg.sender][_to] = _amount;
    }

    function removeAllowance(address _to) public{
        require(_to!=address(0), "Give a valid address");
        _allowance[msg.sender][_to] = 0;
    }

    function transferThirdParty(address _from, address _to, uint256 _amount) public{
        require(_to != address(0), "Address can't be zero");
        require(_from != address(0), "Address can't be zero");
        require(_allowance[_from][_to] >= _amount, "Allowance not enough");
        require(balances[_from] >= _amount, "Balance not enough");
        balances[_from] -= _amount;
        balances[_to] += _amount;
        _allowance[_from][_to] = 0;
        emit TransferEvent(_from, _to, _amount);
    }

    function mint(uint256 _amount, address _to) public onlyOwner{
        balances[_to] += _amount;
        _totalSupply += _amount;
        emit MintEvent(_to, _amount);
    }

    function burn(uint256 _amount) public{
        require(balances[msg.sender] >= _amount, "Not enough balance to burn");
        balances[msg.sender] -= _amount;
        _totalSupply -= _amount;
        emit BurnEvent(msg.sender, _amount);
    }

}