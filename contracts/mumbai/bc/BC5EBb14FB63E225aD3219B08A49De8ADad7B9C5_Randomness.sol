/**
 *Submitted for verification at polygonscan.com on 2022-11-16
*/

// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.16; 
  
contract Randomness{ 
    uint internal randNonce = 0; 
    address private _owner;
    mapping(address => bool) internal _isAdmin;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor(){
        _owner = msg.sender;
    }
  
  function owner() public view virtual returns (address) {
        return _owner;
    }
    modifier onlyOwner{
      require(owner() == msg.sender, "Accesible limit: caller is not the owner");
      _;
  }
  modifier onlyOwnerAndAdmin() {
      require(owner() == msg.sender || _isAdmin[msg.sender], "Accesible limit: caller is not the owner or admin");
      _;
  }
  function addAdmin(address _address) external onlyOwner{
      _isAdmin[_address] = true;
  }
  function removeAdmin(address _address) external onlyOwner{
    _isAdmin[_address] = false;
  }
  function isAdmin(address _address) external view onlyOwnerAndAdmin returns (bool){
      return _isAdmin[_address];
  }
  function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
         address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

function randMod(uint _modulus) internal returns(uint){ 
   randNonce++;  
   return uint(keccak256(abi.encodePacked(msg.sender,randNonce,block.timestamp))) % _modulus; 
 } 
 function randomNumber(uint256[] calldata _nums, uint256 _randLength) external onlyOwnerAndAdmin returns(uint256[] memory){ 
    uint length = _nums.length; 
    require(length >= _randLength, "_randLength cannot over limit length of input _nums");
    uint[] memory res = new uint[](_randLength); 
    for(uint i=0;i<_randLength;++i){ 
        uint num = randMod(length); 
        res[i] = _nums[num]; 
    } 
    return res; 
 } 
}