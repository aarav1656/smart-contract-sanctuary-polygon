// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;
 
import "./nf-token-metadata.sol";
 
contract newNFT is NFTokenMetadata {
 
  constructor() {
    nftName = "AFFI NFT";
    nftSymbol = "AFFI";
  }
 
  function mint(address _to, uint256 _tokenId, string calldata _uri) external  {
    super._mint(_to, _tokenId);
    super._setTokenUri(_tokenId, _uri);
  }
 
}