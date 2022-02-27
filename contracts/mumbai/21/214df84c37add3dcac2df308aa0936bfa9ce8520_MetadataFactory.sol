// SPDX-License-Identifier: GPL-3.0
import '../base/IZombieMetadata.sol';
import '../base/ISurvivorFactory.sol';
import '../base/IMetadataBuilder.sol';
import '../base/IMetadataFactory.sol';
import "../base/IVRF.sol";
import '../base/Strings.sol';
import "../main/ProxyTarget.sol";

pragma solidity ^0.8.0;

/// @title MetadataFactory
/// @notice Provides metadata utility functions for creation
contract MetadataFactory is IMetadataFactory, ProxyTarget {

	bool public initialized;
    IZombieMetadata zombieMetadata;
    ISurvivorFactory survivorFactory;
    IMetadataBuilder metadataBuilder;
    IVRF randomNumberGenerator;

    function initialize(address _zombieMetadata, address _survivorFactory, address _metadataBuilder, address _randomNumberGenerator) external {
        require(msg.sender == _getAddress(ADMIN_SLOT), "not admin");
        require(!initialized);
        initialized = true;

        zombieMetadata = IZombieMetadata(_zombieMetadata);
        survivorFactory = ISurvivorFactory(_survivorFactory);
        metadataBuilder = IMetadataBuilder(_metadataBuilder);
        randomNumberGenerator = IVRF(_randomNumberGenerator);
    }

    function constructNft(uint8 nftType, uint8[] memory traits, uint8 level) public pure override returns(nftMetadata memory) {
        nftMetadata memory nft;
        nft.nftType = nftType;
        nft.traits = traits;
        nft.level = level;
        return nft;
    }

    function buildMetadata(nftMetadata memory nft, bool survivor,uint id) public view override returns(string memory) {
        return metadataBuilder.buildMetadata(nft, survivor, id);
    }

    function levelUpMetadata(nftMetadata memory nft,uint nonce) public view override returns (nftMetadata memory) {
        
        if(nft.nftType == 0) {
            return createRandomMetadata(nft.level + 1, nft.nftType,nonce);
        } else {
            //So basically the rule is that if an item availability ends at a set level it persists. If the availability continues it re-rolls for non base traits
            return levelUpSurvivor(nft,nonce);
        }
    }

    function levelUpSurvivor(nftMetadata memory nft,uint nonce) public view returns (nftMetadata memory) {
        
        //increment level here
        nft.level++;
        uint8[] memory traits = new uint8[](12);

        { //Base traits remain consistent through leveling up
            traits[0] = nft.traits[0];
            traits[1] = nft.traits[1];
            traits[2] = nft.traits[2];
            traits[3] = nft.traits[3];
            traits[4] = nft.traits[4];
            traits[5] = nft.traits[5];
            traits[6] = nft.traits[6];
        }

        {
            //re roll this
            uint8 chestArmorTrait = uint8(randomNumberGenerator.getRange(1, survivorFactory.survivorChestArmorTraitCount(nft.level),uint256(keccak256(abi.encode(nonce, "chestArmor")))));
            traits[7] = chestArmorTrait;
            //re roll this
            uint8 shoulderArmorTrait = uint8(randomNumberGenerator.getRange(1, survivorFactory.survivorShoulderArmorTraitCount(nft.level),uint256(keccak256(abi.encode(nonce, "shoulderArmor"))))); 
            traits[8] = shoulderArmorTrait;
            
            //persist - if it's already set
            if(nft.traits[9] == 0) {
                uint8 legArmorTrait = uint8(randomNumberGenerator.getRange(1, survivorFactory.survivorLegArmorTraitCount(nft.level),uint256(keccak256(abi.encode(nonce, "legArmor"))))); 
                traits[9] = legArmorTrait > 0 ? legArmorTrait : nft.traits[9];
            } else traits[9] = nft.traits[9];
    
            //persist - if level is > 2
            if(nft.level <= 2) {
                uint8 rightWeaponTrait = uint8(randomNumberGenerator.getRange(1, survivorFactory.survivorRightWeaponTraitCount(nft.level),uint256(keccak256(abi.encode(nonce, "rightWeapon")))));
                traits[10] = rightWeaponTrait;
            } else traits[10] = nft.traits[10];

            //re roll this
            uint8 leftWeaponTrait = uint8(randomNumberGenerator.getRange(1, survivorFactory.survivorLeftWeaponTraitCount(nft.level),uint256(keccak256(abi.encode(nonce, "leftWeapon")))));
            traits[11] = leftWeaponTrait;
        }
        
        return constructNft(nft.nftType, traits, nft.level);
    }

    function createRandomMetadata(uint8 level, uint8 tokenType,uint nonce) public view override returns(nftMetadata memory) {

        uint8[] memory traits;
        // bool canClaim;
        // uint stakedTime;
        // uint lastClaimTime;
        //uint8 nftType = 0;//implement random here between 0 and 1

        if(tokenType == 0) {
            (traits, level) = createRandomZombie(level,nonce);
        } else {
            (traits, level) = createRandomSurvivor(level,nonce);
        }

        return constructNft(tokenType, traits, level);
    }

    function createRandomZombie(uint8 level,uint nonce) public view override returns(uint8[] memory, uint8) {
        return (
            randomZombieTraits(level,nonce),
            level
        );
    }

    function randomZombieTraits(uint8 level,uint nonce) public view returns(uint8[] memory) {
        uint8[] memory traits = new uint8[](5);

        uint8 torsoTrait = uint8(randomNumberGenerator.getRange(1, zombieMetadata.zombieTorsoTraitCount(level),uint256(keccak256(abi.encode(nonce, "torso")))));
        traits[0] = torsoTrait;
        uint8 leftArmTrait = uint8(randomNumberGenerator.getRange(1, zombieMetadata.zombieLeftArmTraitCount(level),uint256(keccak256(abi.encode(nonce, "leftArm"))))); 
        traits[1] = leftArmTrait;
        uint8 rightArmTrait = uint8(randomNumberGenerator.getRange(1, zombieMetadata.zombieRightArmTraitCount(level),uint256(keccak256(abi.encode(nonce, "rightArm")))));
        traits[2] = rightArmTrait;
        uint8 legsTrait = uint8(randomNumberGenerator.getRange(1, zombieMetadata.zombieLegsTraitCount(level),uint256(keccak256(abi.encode(nonce, "legs"))))); 
        traits[3] = legsTrait;
        uint8 headTrait = uint8(randomNumberGenerator.getRange(1, zombieMetadata.zombieHeadTraitCount(level),uint256(keccak256(abi.encode(nonce, "head"))))); 
        traits[4] = headTrait;

        return traits;
    }

    function createRandomSurvivor(uint8 level,uint nonce) public view override returns(uint8[] memory, uint8) {
        return (
            randomSurvivorTraits(level, nonce),
            level
        );
    }

    function randomSurvivorTraits(uint8 level,uint nonce) public view returns(uint8[] memory) {
        uint8[] memory traits = new uint8[](12);

            {
                uint8 shoesTrait = uint8(randomNumberGenerator.getRange(1, survivorFactory.survivorShoesTraitCount(),uint256(keccak256(abi.encode(nonce, "shoes"))))); 
                traits[0] = shoesTrait;
                uint8 pantsTrait = uint8(randomNumberGenerator.getRange(1, survivorFactory.survivorPantsTraitCount(),uint256(keccak256(abi.encode(nonce, "pants")))));
                traits[1] = pantsTrait;
                uint8 bodyTrait = uint8(randomNumberGenerator.getRange(1, survivorFactory.survivorBodyTraitCount(),uint256(keccak256(abi.encode(nonce, "body"))))); 
                traits[2] = bodyTrait;
                uint8 beardTrait = uint8(randomNumberGenerator.getRange(1, survivorFactory.survivorBeardTraitCount(),uint256(keccak256(abi.encode(nonce, "beard"))))); 
                traits[3] = beardTrait;
                uint8 hairTrait = uint8(randomNumberGenerator.getRange(1, survivorFactory.survivorHairTraitCount(),uint256(keccak256(abi.encode(nonce, "hair"))))); 
                traits[4] = hairTrait;
                uint8 headTrait = uint8(randomNumberGenerator.getRange(1, survivorFactory.survivorHeadTraitCount(),uint256(keccak256(abi.encode(nonce, "head2"))))); 
                traits[5] = headTrait;
                uint8 shirtTrait = uint8(randomNumberGenerator.getRange(1, survivorFactory.survivorShirtTraitCount(),uint256(keccak256(abi.encode(nonce, "shirt"))))); 
                traits[6] = shirtTrait;
            }

            {
                uint8 chestArmorTrait = uint8(randomNumberGenerator.getRange(1, survivorFactory.survivorChestArmorTraitCount(level),uint256(keccak256(abi.encode(nonce, "chestArmor2")))));
                traits[7] = chestArmorTrait;
                uint8 shoulderArmorTrait = uint8(randomNumberGenerator.getRange(1, survivorFactory.survivorShoulderArmorTraitCount(level),uint256(keccak256(abi.encode(nonce, "shoulderArmor2"))))); 
                traits[8] = shoulderArmorTrait;
                uint8 legArmorTrait = uint8(randomNumberGenerator.getRange(1, survivorFactory.survivorLegArmorTraitCount(level),uint256(keccak256(abi.encode(nonce, "legArmor2"))))); 
                traits[9] = legArmorTrait;
                uint8 rightWeaponTrait = uint8(randomNumberGenerator.getRange(1, survivorFactory.survivorRightWeaponTraitCount(level),uint256(keccak256(abi.encode(nonce, "rightWeapon2")))));
                traits[10] = rightWeaponTrait;
                uint8 leftWeaponTrait = uint8(randomNumberGenerator.getRange(1, survivorFactory.survivorLeftWeaponTraitCount(level),uint256(keccak256(abi.encode(nonce, "leftWeapon2")))));
                traits[11] = leftWeaponTrait;
            }
            return traits;
    }


    function survivorMetadataBytes(nftMetadata memory survivor,uint id) public view returns(bytes memory) {
        return metadataBuilder.survivorMetadataBytes(survivor, id);
    }

    function survivorTraitsMetadata(nftMetadata memory survivor) public view returns(string memory) {

        string memory traits1;
        string memory traits2;

        {
            traits1 = string(abi.encodePacked(
                '", "shoes":"',
                survivorFactory.survivorTrait(ISurvivorFactory.SurvivorTrait.Shoes, survivor.level, survivor.traits[0]),
                '", "pants":"',
                survivorFactory.survivorTrait(ISurvivorFactory.SurvivorTrait.Pants, survivor.level, survivor.traits[1]),
                '", "body":"',
                survivorFactory.survivorTrait(ISurvivorFactory.SurvivorTrait.Body, survivor.level, survivor.traits[2]),
                '", "beard":"',
                survivorFactory.survivorTrait(ISurvivorFactory.SurvivorTrait.Beard, survivor.level, survivor.traits[3]),
                '", "hair":"',
                survivorFactory.survivorTrait(ISurvivorFactory.SurvivorTrait.Hair, survivor.level, survivor.traits[4]),
                '", "head":"',
                survivorFactory.survivorTrait(ISurvivorFactory.SurvivorTrait.Head, survivor.level, survivor.traits[5])
            ));
        }

        {
            traits2 = string(abi.encodePacked(
                '", "shirt":"',
                survivorFactory.survivorTrait(ISurvivorFactory.SurvivorTrait.Shirt, survivor.level, survivor.traits[6]),
                '", "chest armor":"',
                survivorFactory.survivorTrait(ISurvivorFactory.SurvivorTrait.ChestArmor, survivor.level, survivor.traits[7]),
                '", "shoulder armor":"',
                survivorFactory.survivorTrait(ISurvivorFactory.SurvivorTrait.ShoulderArmor, survivor.level, survivor.traits[8]),
                '", "leg armor":"',
                survivorFactory.survivorTrait(ISurvivorFactory.SurvivorTrait.LegArmor, survivor.level, survivor.traits[9]),
                '", "right weapon":"',
                survivorFactory.survivorTrait(ISurvivorFactory.SurvivorTrait.RightWeapon, survivor.level, survivor.traits[10]),
                '", "left weapon":"',
                survivorFactory.survivorTrait(ISurvivorFactory.SurvivorTrait.LeftWeapon, survivor.level, survivor.traits[11])
            ));
        }

        return string(abi.encodePacked(traits1, traits2));
    }

    function zombieMetadataBytes(nftMetadata memory zombie,uint id) public view returns(bytes memory) {
        return metadataBuilder.zombieMetadataBytes(zombie, id);
    }
    
}

pragma solidity ^0.8.0;

interface IZombieMetadata {
    enum ZombieTrait { Torso, LeftArm, RightArm, Legs, Head }

    function zombieTorsoTraitCount(uint8 level) external view returns (uint8);
    function zombieLeftArmTraitCount(uint8 level) external view returns (uint8);
    function zombieRightArmTraitCount(uint8 level) external view returns (uint8);
    function zombieLegsTraitCount(uint8 level) external view returns (uint8);
    function zombieHeadTraitCount(uint8 level) external view returns (uint8);
    function zombieSVG(uint8 level, uint8[] memory traits) external view returns (bytes memory);
    function zombieTrait(ZombieTrait trait, uint8 level, uint8 traitNumber) external view returns (string memory);
}

pragma solidity ^0.8.0;

interface ISurvivorFactory {
    enum SurvivorTrait { Shoes, Pants, Body, Beard, Hair, Head, Shirt, ChestArmor, ShoulderArmor, LegArmor, RightWeapon, LeftWeapon }

    function survivorChestArmorTraitCount(uint8 level) external view returns (uint8);
    function survivorShoulderArmorTraitCount(uint8 level) external view returns (uint8);
    function survivorLegArmorTraitCount(uint8 level) external view returns (uint8);
    function survivorRightWeaponTraitCount(uint8 level) external view returns (uint8);
    function survivorLeftWeaponTraitCount(uint8 level) external view returns (uint8);
    function survivorShoesTraitCount() external view returns (uint8);
    function survivorPantsTraitCount() external view returns (uint8);
    function survivorBodyTraitCount() external view returns (uint8);
    function survivorBeardTraitCount() external view returns (uint8);
    function survivorHairTraitCount() external view returns (uint8);
    function survivorHeadTraitCount() external view returns (uint8);
    function survivorShirtTraitCount() external view returns (uint8);
    function survivorSVG(uint8 level, uint8[] memory traits) external view returns (bytes memory);
    function survivorTrait(SurvivorTrait trait, uint8 level, uint8 traitNumber) external view returns (string memory);
}

pragma solidity ^0.8.0;

import './IMetadataFactory.sol';

interface IMetadataBuilder{
    function buildMetadata(IMetadataFactory.nftMetadata memory nft, bool survivor,uint id) external view returns(string memory);
    function survivorMetadataBytes(IMetadataFactory.nftMetadata memory survivor,uint id) external view returns(bytes memory);
    function zombieMetadataBytes(IMetadataFactory.nftMetadata memory zombie,uint id) external view returns(bytes memory);
}

pragma solidity ^0.8.0;

interface IMetadataFactory{
    struct nftMetadata {
        uint8 nftType;//0->Zombie 1->Survivor
        uint8[] traits;
        uint8 level;
        // uint nftCreationTime;
        // bool canClaim;
        // uint stakedTime;
        // uint lastClaimTime;
    }

    function createRandomMetadata(uint8 level, uint8 tokenType,uint nonce) external view returns(nftMetadata memory);
    function createRandomZombie(uint8 level,uint nonce) external view returns(uint8[] memory, uint8);
    function createRandomSurvivor(uint8 level,uint nonce) external view returns(uint8[] memory, uint8);
    function constructNft(uint8 nftType, uint8[] memory traits, uint8 level) external view returns(nftMetadata memory);
    function buildMetadata(nftMetadata memory nft, bool survivor,uint id) external view returns(string memory);
    function levelUpMetadata(nftMetadata memory nft,uint nonce) external view returns (nftMetadata memory);
}

//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface IVRF{

    // function initiateRandomness(uint _tokenId,uint _timestamp) external view returns(uint);
    // function stealRandomness() external view returns(uint);
    // function getCurrentIndex() external view returns(uint);
    function getRandom(uint256 seed) external returns (uint256);
    function getRand(uint256 nonce) external view returns (uint256);
    function getRange(uint min, uint max,uint nonce) external view returns(uint);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;
/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint` to its ASCII `string` decimal representation.
     */
    function toString(uint value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint temp = value;
        uint digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint temp = value;
        uint length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint value, uint length)
    internal
    pure
    returns (string memory)
    {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

pragma solidity ^0.8.0;

/// @dev Proxy for NFT Factory
contract ProxyTarget {

    // Storage for this proxy
    bytes32 internal constant IMPLEMENTATION_SLOT = bytes32(0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc);
    bytes32 internal constant ADMIN_SLOT          = bytes32(0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103);

    function _getAddress(bytes32 key) internal view returns (address add) {
        add = address(uint160(uint256(_getSlotValue(key))));
    }

    function _getSlotValue(bytes32 slot_) internal view returns (bytes32 value_) {
        assembly {
            value_ := sload(slot_)
        }
    }

    function _setSlotValue(bytes32 slot_, bytes32 value_) internal {
        assembly {
            sstore(slot_, value_)
        }
    }

}