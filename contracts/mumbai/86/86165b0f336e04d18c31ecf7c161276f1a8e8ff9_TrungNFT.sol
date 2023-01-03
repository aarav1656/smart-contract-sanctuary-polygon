//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import './ERC721.sol';

contract TrungNFT is ERC721 {
    string public name;  // ERC721 metadata
    string public symbol; // ERC721 metadata 

    uint256 public tokenCount;

    mapping(uint256 => string) private _tokenURIs;

    constructor (string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    function tokenURI(uint256 tokenId) public view returns (string memory) { // ERC721 metadata 
        address owner =  _owners[tokenId];
        require(owner != address(0), "Token ID does not exist");
        return _tokenURIs[tokenId];
    }

    function mint(string memory _tokenURI) public {
        tokenCount += 1; // tokenID
        _balances[msg.sender] += 1;
        _owners[tokenCount] = msg.sender;
        _tokenURIs[tokenCount] = _tokenURI;

        emit Transfer(address(0), msg.sender, tokenCount);
    }   

    // virtual giong nhu la abstract, co the implement sau.
    // EIP165 proposal: query if a contract implements another interface.
    function supportInterface(bytes4 interfaceID) public pure override returns (bool) {
        return interfaceID == 0x80ac58cd || interfaceID == 0x5b5e139f;
    }

}