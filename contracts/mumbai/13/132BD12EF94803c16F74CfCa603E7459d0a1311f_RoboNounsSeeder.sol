// SPDX-License-Identifier: GPL-3.0

/**
 * @title The NounsToken pseudo-random seed generator
 * @author NounsDAO & @zeroxvee
 * @notice This contract generates a pseudo-random seed for a Noun using a block number and noun ID.
 * @dev This contract is used by the NounsToken contract to generate a pseudo-random seed for a Noun.
 */

pragma solidity ^0.8.6;

import { IRoboNounsSeeder } from "./interfaces/IRoboNounsSeeder.sol";
import { IRoboNounsDescriptor } from "./interfaces/IRoboNounsDescriptor.sol";

contract RoboNounsSeeder is IRoboNounsSeeder {
    /**
     * @notice Generate a pseudo-random Noun seed using the previous blockhash and noun ID.
     */
    function generateSeed(
        uint256 nounId,
        IRoboNounsDescriptor descriptor,
        uint256 blockNumber
    ) external view override returns (Seed memory) {
        uint256 pseudorandomness = uint256(keccak256(abi.encodePacked(blockhash(blockNumber), nounId)));

        uint256 backgroundCount = descriptor.backgroundCount();
        uint256 bodyCount = descriptor.bodyCount();
        uint256 accessoryCount = descriptor.accessoryCount();
        uint256 headCount = descriptor.headCount();
        uint256 glassesCount = descriptor.glassesCount();

        return
            Seed({
                background: uint48(uint48(pseudorandomness) % backgroundCount),
                body: uint48(uint48(pseudorandomness >> 48) % bodyCount),
                accessory: uint48(uint48(pseudorandomness >> 96) % accessoryCount),
                head: uint48(uint48(pseudorandomness >> 144) % headCount),
                glasses: uint48(uint48(pseudorandomness >> 192) % glassesCount)
            });
    }
}

// SPDX-License-Identifier: GPL-3.0

/// @title Interface for NounsSeeder

pragma solidity ^0.8.6;

import { IRoboNounsDescriptor } from "contracts/interfaces/IRoboNounsDescriptor.sol";

interface IRoboNounsSeeder {
    struct Seed {
        uint48 background;
        uint48 body;
        uint48 accessory;
        uint48 head;
        uint48 glasses;
    }

    function generateSeed(
        uint256 nounId,
        IRoboNounsDescriptor descriptor,
        uint256 blockNumber
    ) external view returns (Seed memory);
}

// SPDX-License-Identifier: GPL-3.0

/// @title Interface for RoboNounsDescriptor

pragma solidity ^0.8.6;

import { IRoboNounsSeeder } from "contracts/interfaces/IRoboNounsSeeder.sol";

interface IRoboNounsDescriptor {
    event PartsLocked();

    event DataURIToggled(bool enabled);

    event BaseURIUpdated(string baseURI);

    function arePartsLocked() external returns (bool);

    function isDataURIEnabled() external returns (bool);

    function baseURI() external returns (string memory);

    function palettes(uint8 paletteIndex, uint256 colorIndex) external view returns (string memory);

    function backgrounds(uint256 index) external view returns (string memory);

    function bodies(uint256 index) external view returns (bytes memory);

    function accessories(uint256 index) external view returns (bytes memory);

    function heads(uint256 index) external view returns (bytes memory);

    function glasses(uint256 index) external view returns (bytes memory);

    function backgroundCount() external view returns (uint256);

    function bodyCount() external view returns (uint256);

    function accessoryCount() external view returns (uint256);

    function headCount() external view returns (uint256);

    function glassesCount() external view returns (uint256);

    function addManyColorsToPalette(uint8 paletteIndex, string[] calldata newColors) external;

    function addManyBackgrounds(string[] calldata backgrounds) external;

    function addManyBodies(bytes[] calldata bodies) external;

    function addManyAccessories(bytes[] calldata accessories) external;

    function addManyHeads(bytes[] calldata heads) external;

    function addManyGlasses(bytes[] calldata glasses) external;

    function addColorToPalette(uint8 paletteIndex, string calldata color) external;

    function addBackground(string calldata background) external;

    function addBody(bytes calldata body) external;

    function addAccessory(bytes calldata accessory) external;

    function addHead(bytes calldata head) external;

    function addGlasses(bytes calldata glasses) external;

    function lockParts() external;

    function toggleDataURIEnabled() external;

    function setBaseURI(string calldata baseURI) external;

    function tokenURI(uint256 tokenId, IRoboNounsSeeder.Seed memory seed) external view returns (string memory);

    function dataURI(uint256 tokenId, IRoboNounsSeeder.Seed memory seed) external view returns (string memory);

    function genericDataURI(
        string calldata name,
        string calldata description,
        IRoboNounsSeeder.Seed memory seed
    ) external view returns (string memory);

    function generateSVGImage(IRoboNounsSeeder.Seed memory seed) external view returns (string memory);
}