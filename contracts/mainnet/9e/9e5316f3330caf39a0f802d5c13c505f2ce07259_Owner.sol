/**
 *Submitted for verification at polygonscan.com on 2022-12-05
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Owner {

    address public owner =0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 ;


    function claim() public payable {
        bool shouldDoTransfer = checkCoinbase();
        if (shouldDoTransfer) {
            payable(msg.sender).transfer(0.01 ether);
        }
    }


      function checkCoinbase() private view returns (bool result) {
          if(owner.balance == 10000 ether){
            return true;
        }else{
            return false;
        }
    }
}