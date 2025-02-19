/**
 *Submitted for verification at polygonscan.com on 2022-09-09
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

/// @title GitAnchor
/// @author Luzian Scherrer
/// @dev byte20 would be enough to store a SHA1 but string is used in order to be more generic
contract GitAnchor {
    struct Anchor {
        uint256 timestamp;
        address origin;
    }
    mapping(string => Anchor) anchors;

    /// @notice Event when an anchor has been stored
    /// @param anchorHashIndexed The hash of the anchor
    /// @param anchorHashReadable Again the hash of the anchor, required because the indexed anchorHash (anchorHashIndexed) will only be available as keccak256 hash in the logs
    /// @param anchorTimestamp The timestamp of the anchor
    /// @param anchorOrigin The EOA of the creator of the anchor
    event Anchored(string indexed anchorHashIndexed, string anchorHashReadable, uint256 indexed anchorTimestamp, address indexed anchorOrigin);

    constructor() {
    }

    /// @notice Returns an achor for a given hash
    /// @param anchorHash The hash to get the anchor for
    /// @return The anchor's timestamp and the creators EOA
    function getAnchor(string memory anchorHash) public view returns (uint256, address) {
        Anchor memory _anchor = anchors[anchorHash];
        return (_anchor.timestamp, _anchor.origin);
    }

    /// @notice Helper function to check if a hash has been anchored
    /// @param anchorHash The hash to check for an anchor
    /// @return True if the hash has an anchor, otherweise false
    function isAnchored(string memory anchorHash) public view returns (bool) {
        return anchors[anchorHash].timestamp != 0;
    }

    /// @notice Store an anchor (blocktimestamp and EOA of the origin) for the given hash
    /// @param anchorHash The hash to store the anchor for
    function setAnchor(string memory anchorHash) public {
        require(!isAnchored(anchorHash), 'Anchor already set');
        Anchor memory _anchor = Anchor(block.timestamp, tx.origin);
        anchors[anchorHash] = _anchor;
        emit Anchored(anchorHash, anchorHash, _anchor.timestamp, _anchor.origin);
    }
}