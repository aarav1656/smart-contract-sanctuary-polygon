/**
 *Submitted for verification at polygonscan.com on 2022-11-29
*/

pragma solidity ^0.8.11;

interface IMintyDAONFTFullFactory {
  function create(
    string memory name,
    string memory symbol,
    uint _maxSupply,
    uint _initialPrice,
    address _config,
    string memory _uri,
    string memory _format,
    string memory _ipfsHash,
    uint minLD,
    address creator
   )
    external
    returns(address);
}

interface IMintyDAONFTLightFactory {
  function createLight(
    string memory name,
    string memory symbol,
    uint _maxSupply,
    uint _initialPrice,
    address _config,
    string memory _uri,
    string memory _format,
    string memory _ipfsHash,
    address creator
   )
    external
    returns(address);
}

interface IMintyDAONFTUnlimitedFactory {
  function createUnlimited(
    string memory name,
    string memory symbol,
    address _config,
    uint minLD,
    address creator
   )
    external
    returns (address);
}

contract MintyDAONFTFactory {
  address public platformToken;
  IMintyDAONFTFullFactory public nftFullFactory;
  IMintyDAONFTLightFactory public nftLightFactory;
  IMintyDAONFTUnlimitedFactory public nftUnlimitedFactory;

  mapping(address => address) public latestCollectionPerSender;
  address[] public collections;
  event NewCollection(address indexed creator, address collection);

  constructor(
    address _platformToken,
    address _nftFullFactory,
    address _nftLightFactory,
    address _nftUnlimitedFactory
    )
  {
    platformToken = _platformToken;
    nftFullFactory = IMintyDAONFTFullFactory(_nftFullFactory);
    nftLightFactory = IMintyDAONFTLightFactory(_nftLightFactory);
    nftUnlimitedFactory = IMintyDAONFTUnlimitedFactory(_nftUnlimitedFactory);
  }

  // CREATE STANDARD FULL NFT Collection
  function create(
    string memory name,
    string memory symbol,
    uint _maxSupply,
    uint _initialPrice,
    address _config,
    string memory _uri,
    string memory _format,
    string memory _ipfsHash,
    uint minLD
   )
    external
   {
     address newCollection = nftFullFactory.create(
       name,
       symbol,
       _maxSupply,
       _initialPrice,
       _config,
       _uri,
       _format,
       _ipfsHash,
       minLD,
       msg.sender
     );

     latestCollectionPerSender[msg.sender] = newCollection;
     collections.push(newCollection);
     emit NewCollection(msg.sender, newCollection);
   }

   // CREATE LIGHT NFT Collection
   function createLight(
     string memory name,
     string memory symbol,
     uint _maxSupply,
     uint _initialPrice,
     address _config,
     string memory _uri,
     string memory _format,
     string memory _ipfsHash
    )
     external
    {
      // create NFT collection
      address newCollection = nftLightFactory.createLight(
        name,
        symbol,
        _maxSupply,
        _initialPrice,
        _config,
        _uri,
        _format,
        _ipfsHash,
        msg.sender
      );

      latestCollectionPerSender[msg.sender] = newCollection;
      collections.push(newCollection);
      emit NewCollection(msg.sender, newCollection);
   }

   // CREATE UNLIMITED NFT Collection
   // Where any user can create NFT with unique link
   function createUnlimited(
     string memory name,
     string memory symbol,
     address _config,
     uint minLD
    )
     external
    {
      address newCollection = nftUnlimitedFactory.createUnlimited(
        name,
        symbol,
        _config,
        minLD,
        msg.sender
      );

      latestCollectionPerSender[msg.sender] = newCollection;
      collections.push(newCollection);
      emit NewCollection(msg.sender, newCollection);
    }

   function totalCollections() external view returns (uint) {
     return collections.length;
   }
}