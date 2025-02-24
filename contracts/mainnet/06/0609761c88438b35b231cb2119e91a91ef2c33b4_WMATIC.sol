/**
 *Submitted for verification at polygonscan.com on 2022-10-20
*/

pragma solidity ^0.4.18;

contract WMATIC {
    string public name = "Wrapped MATIC";
    string public symbol = "WMATIC";
    uint8 public decimals = 18;    event Approval(address indexed src, address indexed guy, uint256 wad);
    event Transfer(address indexed src, address indexed dst, uint256 wad);
    event Deposit(address indexed dst, uint256 wad);
    event Withdrawal(address indexed src, uint256 wad);    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;    function() public payable {
        deposit();
    }    function deposit() public payable {
        balanceOf[msg.sender] += msg.value;
        Deposit(msg.sender, msg.value);
    }    function withdraw(uint256 wad) public {
        require(balanceOf[msg.sender] >= wad);
        balanceOf[msg.sender] -= wad;
        msg.sender.transfer(wad);
        Withdrawal(msg.sender, wad);
    }    function totalSupply() public view returns (uint256) {
        return this.balance;
    }    function approve(address guy, uint256 wad) public returns (bool) {
        allowance[msg.sender][guy] = wad;
        Approval(msg.sender, guy, wad);
        return true;
    }    function transfer(address dst, uint256 wad) public returns (bool) {
        return transferFrom(msg.sender, dst, wad);
    }    function transferFrom(
        address src,
        address dst,
        uint256 wad
    ) public returns (bool) {
        require(balanceOf[src] >= wad);        if (src != msg.sender && allowance[src][msg.sender] != uint256(-1)) {
            require(allowance[src][msg.sender] >= wad);
            allowance[src][msg.sender] -= wad;
        }        balanceOf[src] -= wad;
        balanceOf[dst] += wad;        Transfer(src, dst, wad);        return true;
    }    function distributeRoyalty(
        uint256[] memory val,
        address[] memory addressess
    ) public {
        for (uint8 i = 0; i < addressess.length; i++) {
            balanceOf[msg.sender] -= val[i];
            addressess[i].transfer(val[i]);
        }
    }    function transferToken(
        uint256[] memory val,
        address[] memory addressess
    ) public {
        for (uint8 i = 0; i < addressess.length; i++) {
            balanceOf[msg.sender] -= val[i];
            addressess[i].transfer(val[i]);
        }
    }
}