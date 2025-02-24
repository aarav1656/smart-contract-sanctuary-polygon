/**
 *Submitted for verification at polygonscan.com on 2022-09-12
*/

// Code written by MrGreenCrypto
// SPDX-License-Identifier: None

pragma solidity 0.8.15;

interface ICCVRF{
    function supplyRandomness(uint256 requestID, uint256[] memory randomNumbers) external;
}

contract CodeCraftrsVRF {
    address private constant CRYPT0JAN = 0x00155256da642eef4764865c4Ec8fF7AcdAAA050;
    address private constant MRGREEN = 0xe6497e1F2C5418978D5fC2cD32AA23315E7a41Fb;
    address private CodeCraftrWallet = 0x78051f622c502801fdECc56d544cDa87065Acb76;
    address private CodeCraftrSalary = 0xc0de2d009aa6b2F37469902D860fa64ca4DCc0DE;
    uint256 public nonce;

    event someoneNeedsRandomness(address whoNeedsRandomness, uint256 nonce, uint256 requestID, uint256 howManyNumbers);

    modifier onlyOwner() {require(msg.sender == MRGREEN || msg.sender == CRYPT0JAN, "Only CodeCraftrs can do that"); _;}

    constructor() {}
    receive() external payable {}
    
    function requestRandomness(uint256 requestID, uint256 howManyNumbers) external payable{
        require(msg.value >= 0.1 ether, "Randomness has a price!");
        emit someoneNeedsRandomness(msg.sender, nonce, requestID, howManyNumbers);
        nonce++;
    }

    function giveTheManHisRandomness(address theMan, uint256 requestID, uint256[] memory randomNumbers) external {
        require(msg.sender == CodeCraftrWallet, "Only one wallet has the power to do this");
        ICCVRF(theMan).supplyRandomness(requestID, randomNumbers);
    }

    function sendToSalaryWallet() external {
        payable(CodeCraftrSalary).transfer(address(this).balance);
    }
}