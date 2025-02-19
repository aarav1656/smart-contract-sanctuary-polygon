/**
 *Submitted for verification at polygonscan.com on 2023-04-18
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 * @custom:dev-run-script ./scripts/deploy_with_ethers.ts
 */

//  contract Test {
//      event Deploy(address addr);
//      function deploy() external {
//          Storage _s = new Storage{
//              salt: bytes32(uint(12))
//          }();
//         emit Deploy(address(_s));
//      }
//  }

contract Storage2 {

    uint256 number;
    string s;

    /**
     * @dev Store value in variable
     * @param num value to store
     */
    function store(uint256 num) public {
        number = num;
    }

    function a(string memory _a) public pure returns(bytes32){
        // return bytes4(keccak256(bytes(_a)));
        return keccak256(bytes(_a));
    }

    function s2(string memory _s) public {
        s = _s;
    }
    /**
     * @dev Return value 
     * @return value of 'number'
     */
    function retrieve() public view returns (uint256){
        return number;
    }
}