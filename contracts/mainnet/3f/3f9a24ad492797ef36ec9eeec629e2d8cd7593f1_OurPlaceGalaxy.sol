// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ERC721} from "ERC721.sol";
import {DefaultOperatorFilterer} from "DefaultOperatorFilterer.sol";
import {Ownable} from "Ownable.sol";
import "Strings.sol";
import "ERC2981.sol";

/**
 * @title  ExampleERC721
 * @notice This example contract is configured to use the DefaultOperatorFilterer, which automatically registers the
 *         token and subscribes it to OpenSea's curated filters.
 *         Adding the onlyAllowedOperator modifier to the transferFrom and both safeTransferFrom methods ensures that
 *         the msg.sender (operator) is allowed by the OperatorFilterRegistry. Adding the onlyAllowedOperatorApproval
 *         modifier to the approval methods ensures that owners do not approve operators that are not allowed.
 */
contract OurPlaceGalaxy is ERC721, DefaultOperatorFilterer, Ownable, ERC2981 {
    using Strings for uint256;

    string public baseURI;
    uint96 royaltyFeesInBips;
    address royaltyAddress;

    string public baseExtension = ".json";

    bool public paused = false;

    bool public public_mint_status = true;

    string public notRevealedUri;

    bool public revealed = true;

    uint256 MAX_SUPPLY = 1125;
    uint256 public publicSaleCost = 0 ether;
    uint256 public max_per_wallet = 10;
    string public contractURI;   
    
    uint256 public totalSupply;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI,
        string memory _initNotRevealedUri,
        string memory _contractURI
      //  uint96 _royaltyFeesInBips
    ) ERC721(_name, _symbol) {
        setBaseURI(_initBaseURI);
        setNotRevealedURI(_initNotRevealedUri);
        contractURI = _contractURI;
        royaltyAddress = owner();
    }

     function mint(uint256 tokenId) public payable  {
        require(totalSupply + 1 <= MAX_SUPPLY,"No More NFTs to Mint");

        if (msg.sender != owner()) {

            require(!paused, "The contract is paused");
            uint256 nft_value = 0;          
           								
								if (tokenId >= 0 && tokenId <= 230) {
									nft_value = 20;
								} else if (tokenId >= 231 && tokenId <= 407) {
									nft_value = 30;
								} else if (tokenId >= 408 && tokenId <= 568) {
									nft_value = 40;
								} else if (tokenId >= 569 && tokenId <= 691) {
									nft_value = 60;
								} else if (tokenId >= 692 && tokenId <= 912) {
									nft_value = 80;
								} else if (tokenId >= 913 && tokenId <= 922) {
									nft_value = 100;
								} else if (tokenId >= 923 && tokenId <= 1053) {
									nft_value = 120;
								} else if (tokenId >= 1054 && tokenId <= 1080) {
									nft_value = 140;
								} else if (tokenId >= 1081 && tokenId <= 1101) {
									nft_value = 160;
								} else if (tokenId >= 1102 && tokenId <= 1117) {
									nft_value = 200;
								} else if (tokenId >= 1118 && tokenId <= 1124) {
									nft_value = 320;
			
			}

            publicSaleCost = nft_value;
            require(msg.value >= (publicSaleCost * 1), "Not Enough ETH Sent");  
                      
        }
        totalSupply++;
        _safeMint(msg.sender, tokenId);
        
    }

    function withdraw() public payable onlyOwner {
        (bool main, ) = payable(owner()).call{value: address(this).balance}("");
        require(main);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        _requireMinted(tokenId);

        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        if (revealed == false) {
            return notRevealedUri;
        }

        return
            bytes(baseURI).length > 0
                ? string(
                    abi.encodePacked(baseURI, tokenId.toString(), baseExtension)
                )
                : "";
    }

    function setApprovalForAll(address operator, bool approved)
        public
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function setRoyaltyInfo(address _receiver, uint96 _royaltyFeesInBips)
        public
        onlyOwner
    {
        royaltyAddress = _receiver;
        royaltyFeesInBips = _royaltyFeesInBips;
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        public
        view
        virtual
        override
        returns (address, uint256)
    {
        return (royaltyAddress, calculateRoyalty(_salePrice));
    }



    function calculateRoyalty(uint256 _salePrice)
        public
        view
        returns (uint256)
    {
        return (_salePrice / 10000) * royaltyFeesInBips;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function pause(bool _state) public onlyOwner {
        paused = _state;
    }

    function setBaseExtension(string memory _newBaseExtension)
        public
        onlyOwner
    {
        baseExtension = _newBaseExtension;
    }

    function setPublic_mint_status(bool _public_mint_status) public onlyOwner {
        public_mint_status = _public_mint_status;
    }

    function toggleReveal() public onlyOwner {
        if (revealed == false) {
            revealed = true;
        } else {
            revealed = false;
        }
    }

    function setMAX_SUPPLY(uint256 _MAX_SUPPLY) public onlyOwner {
        MAX_SUPPLY = _MAX_SUPPLY;
    }

    function setPublicSaleCost(uint256 _publicSaleCost) public onlyOwner {
        publicSaleCost = _publicSaleCost;
    }

    function setMax_per_wallet(uint256 _max_per_wallet) public onlyOwner {
        max_per_wallet = _max_per_wallet;
    }

    function setRoyaltyAddress(address _royaltyAddress) public onlyOwner {
        royaltyAddress = _royaltyAddress;
    }
    
    function setContractURI(string calldata _contractURI) public onlyOwner {
        contractURI = _contractURI;
    }
}