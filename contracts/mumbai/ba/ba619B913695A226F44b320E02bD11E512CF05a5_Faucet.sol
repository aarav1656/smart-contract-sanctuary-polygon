/**
 *Submitted for verification at polygonscan.com on 2022-10-16
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract Faucet {

    address payable owner;
    bool active = true;
    address lastSender;
    uint256 sendPlus = 0 ether;
    uint256 amount;
    uint256 sendAmount = 0.01 ether;
    mapping (address=>senderControl) private userMap;

    struct senderControl {
        address controlAddress;
        int16 controlCounter;
    }

    constructor () payable {
        owner = payable(msg.sender);
        require( msg.value == 0.5 ether,"Deploy the contract with 0.5 ether");
    }

    modifier onlyOwner() {
        require(owner == msg.sender,"You do not have enougth rights");
        _;
    }

    modifier notFunds() {
        require(getBalance() > 0,"SC without funds");
        _;
    }

    modifier isActive() {
        require(active == true,"Please try later, the system is bussy");
        _;
    }

    function pause() external onlyOwner {
        active = false;
    }

    function resume() external onlyOwner {
        active = true;
    }

    function inject() external payable onlyOwner isActive {
    }

    function emergencyWithdraw() external onlyOwner isActive notFunds {
         owner.transfer(getBalance()); 
    }

    function send() external  isActive  {
        require(msg.sender != owner, "You are the owner, you cant not send ether");
        require(msg.sender != lastSender,"Try later, you must wait your next turn");
        
        lastSender = msg.sender;
        sendPlus = 0 ether;
        userControl();
        amount = sendAmount + sendPlus;

        require(amount <= getBalance(),"Not enough balance in SC to send"); 
        address payable to = payable(msg.sender);
        to.transfer(amount); 
    }

    function setOwner(address payable _newOwner) public onlyOwner isActive {
        require(_newOwner != address(0),"Invalid address");
        owner = _newOwner; 
    }

    function getBalance() public view isActive returns (uint256) {
        uint256 balance = address(this).balance;
        return balance;
    }

    function setAmount(uint256 _newSendAmount) public onlyOwner isActive {
        sendAmount = _newSendAmount;
    }

    function destroy() public onlyOwner isActive {
        owner.transfer(getBalance());
        selfdestruct(owner);
    }
    function getDireccionCounter() view public returns (address, int16) {
        return (userMap[msg.sender].controlAddress, userMap[msg.sender].controlCounter);
    }

    function userControl() private {
        if (userMap[msg.sender].controlAddress == msg.sender) {
             userMap[msg.sender] = senderControl(msg.sender, userMap[msg.sender].controlCounter + 1);
                if (userMap[msg.sender].controlCounter % 5 == 0) sendPlus = 0.005 ether;
         } else {
            userMap[msg.sender] = senderControl(msg.sender, 1);
        }
    }

}