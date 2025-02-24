// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**
 * @title Datatrust Anchoring system
 * @author Blockchain Partner by kpmg
 * @author https://blockchainpartner.fr
 */
contract Datatrust {
    // Event emitted when saving a new anchor
    event NewAnchor(bytes32 merkleRoot);

    /**
     * @dev Save a new anchor for a given Merkle tree root hash
     * @dev Use events as a form of storage
     * @param _merkleRoot bytes32 hash to anchor
     */
    function saveNewAnchor(bytes32 _merkleRoot) public {
        emit NewAnchor(_merkleRoot);
    }
}