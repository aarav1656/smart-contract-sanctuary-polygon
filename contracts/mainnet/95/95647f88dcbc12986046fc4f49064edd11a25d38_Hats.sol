/**
 *Submitted for verification at polygonscan.com on 2022-12-08
*/

// Copyright (C) 2022 Hats Protocol
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

pragma solidity >=0.8.13;

/// @notice Minimalist and gas efficient standard ERC1155 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC1155.sol)
abstract contract ERC1155 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 amount
    );

    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] amounts
    );

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    event URI(string value, uint256 indexed id);

    /*//////////////////////////////////////////////////////////////
                             ERC1155 STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(address => mapping(uint256 => uint256)) internal _balanceOf;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*//////////////////////////////////////////////////////////////
                             METADATA LOGIC
    //////////////////////////////////////////////////////////////*/

    function uri(uint256 id) public view virtual returns (string memory);

    /*//////////////////////////////////////////////////////////////
                              ERC1155 LOGIC
    //////////////////////////////////////////////////////////////*/

    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) public virtual {
        require(msg.sender == from || isApprovedForAll[from][msg.sender], "NOT_AUTHORIZED");

        _balanceOf[from][id] -= amount;
        _balanceOf[to][id] += amount;

        emit TransferSingle(msg.sender, from, to, id, amount);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155Received(msg.sender, from, id, amount, data) ==
                    ERC1155TokenReceiver.onERC1155Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) public virtual {
        require(ids.length == amounts.length, "LENGTH_MISMATCH");

        require(msg.sender == from || isApprovedForAll[from][msg.sender], "NOT_AUTHORIZED");

        // Storing these outside the loop saves ~15 gas per iteration.
        uint256 id;
        uint256 amount;

        for (uint256 i = 0; i < ids.length; ) {
            id = ids[i];
            amount = amounts[i];

            _balanceOf[from][id] -= amount;
            _balanceOf[to][id] += amount;

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, from, to, ids, amounts);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155BatchReceived(msg.sender, from, ids, amounts, data) ==
                    ERC1155TokenReceiver.onERC1155BatchReceived.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function balanceOf(address owner, uint256 id) public view virtual returns (uint256 balance) {
        balance = _balanceOf[owner][id];
    }

    function balanceOfBatch(address[] calldata owners, uint256[] calldata ids)
        public
        view
        virtual
        returns (uint256[] memory balances)
    {
        require(owners.length == ids.length, "LENGTH_MISMATCH");

        balances = new uint256[](owners.length);

        // Unchecked because the only math done is incrementing
        // the array index counter which cannot possibly overflow.
        unchecked {
            for (uint256 i = 0; i < owners.length; ++i) {
                balances[i] = _balanceOf[owners[i]][ids[i]];
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0xd9b67a26 || // ERC165 Interface ID for ERC1155
            interfaceId == 0x0e89341c; // ERC165 Interface ID for ERC1155MetadataURI
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        _balanceOf[to][id] += amount;

        emit TransferSingle(msg.sender, address(0), to, id, amount);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155Received(msg.sender, address(0), id, amount, data) ==
                    ERC1155TokenReceiver.onERC1155Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _batchMint(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        uint256 idsLength = ids.length; // Saves MLOADs.

        require(idsLength == amounts.length, "LENGTH_MISMATCH");

        for (uint256 i = 0; i < idsLength; ) {
            _balanceOf[to][ids[i]] += amounts[i];

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, address(0), to, ids, amounts);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155BatchReceived(msg.sender, address(0), ids, amounts, data) ==
                    ERC1155TokenReceiver.onERC1155BatchReceived.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _batchBurn(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        uint256 idsLength = ids.length; // Saves MLOADs.

        require(idsLength == amounts.length, "LENGTH_MISMATCH");

        for (uint256 i = 0; i < idsLength; ) {
            _balanceOf[from][ids[i]] -= amounts[i];

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, from, address(0), ids, amounts);
    }

    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        _balanceOf[from][id] -= amount;

        emit TransferSingle(msg.sender, from, address(0), id, amount);
    }
}

/// @notice A generic interface for a contract which properly accepts ERC1155 tokens.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC1155.sol)
abstract contract ERC1155TokenReceiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC1155TokenReceiver.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC1155TokenReceiver.onERC1155BatchReceived.selector;
    }
}

// import "forge-std/Test.sol"; //remove after testing
// Copyright (C) 2022 Hats Protocol
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

// Copyright (C) 2022 Hats Protocol
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

interface IHatsIdUtilities {
    function buildHatId(uint256 _admin, uint8 _newHat)
        external
        pure
        returns (uint256 id);

    function getHatLevel(uint256 _hatId) external pure returns (uint8);

    function isTopHat(uint256 _hatId) external pure returns (bool);

    function getAdminAtLevel(uint256 _hatId, uint8 _level)
        external
        pure
        returns (uint256);

    function getTophatDomain(uint256 _hatId) external pure returns (uint256);
}

// Copyright (C) 2022 Hats Protocol
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

interface HatsErrors {
    error NotAdmin(address _user, uint256 _hatId);
    error AllHatsWorn(uint256 _hatId);
    error AlreadyWearingHat(address _wearer, uint256 _hatId);
    error HatDoesNotExist(uint256 _hatId);
    error NotEligible(address _wearer, uint256 _hatId);
    // error NoApprovalsNeeded();
    // error OnlyAdminsCanTransfer();
    error NotHatWearer();
    error NotHatsToggle();
    error NotHatsEligibility();
    // error NotIHatsToggleContract();
    // error NotIHatsEligibilityContract();
    error BatchArrayLengthMismatch();
    // error SafeTransfersNotNecessary();
    error MaxLevelsReached();
    error Immutable();
    error NewMaxSupplyTooLow();
}

// Copyright (C) 2022 Hats Protocol
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

interface HatsEvents {
    event HatCreated(
        uint256 id,
        string details,
        uint32 maxSupply,
        address eligibility,
        address toggle,
        bool mutable_,
        string imageURI
    );

    // event HatRenounced(uint256 hatId, address wearer);

    // event WearerStatus(
    //     uint256 hatId,
    //     address wearer,
    //     bool eligible,
    //     bool wearerStanding
    // );

    event HatStatusChanged(uint256 hatId, bool newStatus);

    event HatDetailsChanged(uint256 hatId, string newDetails);

    event HatEligibilityChanged(uint256 hatId, address newEligibility);

    event HatToggleChanged(uint256 hatId, address newToggle);

    event HatMutabilityChanged(uint256 hatId);

    event HatMaxSupplyChanged(uint256 hatId, uint32 newMaxSupply);

    event HatImageURIChanged(uint256 hatId, string newImageURI);
}

interface IHats is IHatsIdUtilities, HatsErrors, HatsEvents {
    function mintTopHat(
        address _target,
        string memory _details,
        string memory _imageURI
    ) external returns (uint256 topHatId);

    // function createTopHatAndHat(
    //     string memory _details,
    //     uint32 _maxSupply,
    //     address _eligibility,
    //     address _toggle,
    //     bool _mutable,
    //     string memory _topHatImageURI,
    //     string memory _firstHatImageURI
    // ) external returns (uint256 topHatId, uint256 firstHatId);

    function createHat(
        uint256 _admin,
        string memory _details,
        uint32 _maxSupply,
        address _eligibility,
        address _toggle,
        bool _mutable,
        string memory _imageURI
    ) external returns (uint256 newHatId);

    function batchCreateHats(
        uint256[] memory _admins,
        string[] memory _details,
        uint32[] memory _maxSupplies,
        address[] memory _eligibilityModules,
        address[] memory _toggleModules,
        bool[] memory _mutables,
        string[] memory _imageURIs
    ) external returns (bool);

    function getNextId(uint256 _admin) external view returns (uint256);

    function mintHat(uint256 _hatId, address _wearer) external returns (bool);

    function batchMintHats(uint256[] memory _hatIds, address[] memory _wearers)
        external
        returns (bool);

    function setHatStatus(uint256 _hatId, bool _newStatus)
        external
        returns (bool);

    function checkHatStatus(uint256 _hatId) external returns (bool);

    function setHatWearerStatus(
        uint256 _hatId,
        address _wearer,
        bool _eligible,
        bool _standing
    ) external returns (bool);

    function checkHatWearerStatus(uint256 _hatId, address _wearer)
        external
        returns (bool);

    function renounceHat(uint256 _hatId) external;

    function transferHat(
        uint256 _hatId,
        address _from,
        address _to
    ) external;

    /*//////////////////////////////////////////////////////////////
                              HATS ADMIN FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function makeHatImmutable(uint256 _hatId) external;

    function changeHatDetails(uint256 _hatId, string memory _newDetails)
        external;

    function changeHatEligibility(uint256 _hatId, address _newEligibility)
        external;

    function changeHatToggle(uint256 _hatId, address _newToggle) external;

    function changeHatImageURI(uint256 _hatId, string memory _newImageURI)
        external;

    function changeHatMaxSupply(uint256 _hatId, uint32 _newMaxSupply) external;

    /*//////////////////////////////////////////////////////////////
                              VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function viewHat(uint256 _hatId)
        external
        view
        returns (
            string memory details,
            uint32 maxSupply,
            uint32 supply,
            address eligibility,
            address toggle,
            string memory imageURI,
            uint8 lastHatId,
            bool mutable_,
            bool active
        );

    function isWearerOfHat(address _user, uint256 _hatId)
        external
        view
        returns (bool);

    function isAdminOfHat(address _user, uint256 _hatId)
        external
        view
        returns (bool);

    // function isActive(uint256 _hatId) external view returns (bool);

    function isInGoodStanding(address _wearer, uint256 _hatId)
        external
        view
        returns (bool);

    function isEligible(address _wearer, uint256 _hatId)
        external
        view
        returns (bool);

    function getImageURIForHat(uint256 _hatId)
        external
        view
        returns (string memory);

    function balanceOf(address wearer, uint256 hatId)
        external
        view
        returns (uint256 balance);

    function uri(uint256 id) external view returns (string memory);
}

// Copyright (C) 2022 Hats Protocol
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

/// @title Hats Id Utilities
/// @dev Functions for working with Hat Ids from Hats Protocol. Factored out of Hats.sol
/// for easier use by other contracts.
/// @author Hats Protocol
contract HatsIdUtilities is IHatsIdUtilities {
    /**
     * Hat Ids serve as addresses. A given Hat's Id represents its location in its
     * hat tree: its level, its admin, its admin's admin (etc, all the way up to the
     * tophat).
     *
     * The top level consists of 4 bytes and references all tophats.
     *
     * Each level below consists of 1 byte, and contains up to 255 child hats.
     *
     * A uint256 contains 4 bytes of space for tophat addresses and 28 additional bytes
     * of space, giving room for 28 levels of delegation, with the admin at each level
     * having space for 255 different child hats.
     *
     * A hat tree consists of a single tophat and has a max depth of 28 levels.
     */

    uint256 internal constant TOPHAT_ADDRESS_SPACE = 32; // 32 bits (4 bytes) of space for tophats, aka the "domain"
    uint256 internal constant LOWER_LEVEL_ADDRESS_SPACE = 8; // 8 bits (1 byte) of space for each of the levels below the tophat
    uint256 internal constant MAX_LEVELS = 28; // 28 levels below the tophat

    /// @notice Constructs a valid hat id for a new hat underneath a given admin
    /// @dev Check hats[_admin].lastHatId for the previous hat created underneath _admin
    /// @param _admin the id of the admin for the new hat
    /// @param _newHat the uint8 id of the new hat
    /// @return id The constructed hat id
    function buildHatId(uint256 _admin, uint8 _newHat)
        public
        pure
        returns (uint256 id)
    {
        uint256 mask;
        // TODO: remove this loop
        for (uint256 i = 0; i < MAX_LEVELS; ++i) {
            mask = uint256(
                type(uint256).max >>
                    (TOPHAT_ADDRESS_SPACE + (LOWER_LEVEL_ADDRESS_SPACE * i))
            );
            if (_admin & mask == 0) {
                id =
                    _admin |
                    (uint256(_newHat) <<
                        (LOWER_LEVEL_ADDRESS_SPACE * (MAX_LEVELS - 1 - i)));
                return id;
            }
        }
    }

    /// @notice Identifies the level a given hat in its hat tree
    /// @param _hatId the id of the hat in question
    /// @return level (0 to 28)
    function getHatLevel(uint256 _hatId) public pure returns (uint8) {
        uint256 mask;
        uint256 i;
        // TODO: get rid of this for loop and possibly use the YUL switch/case
        // syntax. Otherwise, return to the original syntax
        for (i = 0; i < MAX_LEVELS; ++i) {
            mask = uint256(
                type(uint256).max >>
                    (TOPHAT_ADDRESS_SPACE + (LOWER_LEVEL_ADDRESS_SPACE * i))
            );

            if (_hatId & mask == 0) return uint8(i);
        }

        return uint8(MAX_LEVELS);
    }

    /// @notice Checks whether a hat is a topHat
    /// @dev For use when passing a Hat object is not appropriate
    /// @param _hatId The hat in question
    /// @return bool Whether the hat is a topHat
    function isTopHat(uint256 _hatId) public pure returns (bool) {
        return _hatId > 0 && uint224(_hatId) == 0;
    }

    /// @notice Gets the hat id of the admin at a given level of a given hat
    /// @param _hatId the id of the hat in question
    /// @param _level the admin level of interest
    /// @return uint256 The hat id of the resulting admin
    function getAdminAtLevel(uint256 _hatId, uint8 _level)
        public
        pure
        returns (uint256)
    {
        uint256 mask = type(uint256).max <<
            (LOWER_LEVEL_ADDRESS_SPACE * (MAX_LEVELS - _level));

        return _hatId & mask;
    }

    /// @notice Gets the tophat domain of a given hat
    /// @dev A domain is the identifier for a given hat tree, stored in the first 4 bytes of a hat's id
    /// @param _hatId the id of the hat in question
    /// @return uint256 The domain
    function getTophatDomain(uint256 _hatId) public pure returns (uint256) {
        return
            getAdminAtLevel(_hatId, 0) >>
            (LOWER_LEVEL_ADDRESS_SPACE * MAX_LEVELS);
    }
}

// Copyright (C) 2022 Hats Protocol
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

interface IHatsToggle {
    function getHatStatus(uint256 _hatId) external view returns (bool);
}

// Copyright (C) 2022 Hats Protocol
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

interface IHatsEligibility {
    /// @notice Returns the status of a wearer for a given hat
    /// @dev If standing is false, eligibility MUST also be false
    /// @param _wearer The address of the current or prospective Hat wearer
    /// @param _hatId The id of the hat in question
    /// @return eligible Whether the _wearer is eligible to wear the hat
    /// @return standing Whether the _wearer is in goog standing
    function getWearerStatus(address _wearer, uint256 _hatId)
        external
        view
        returns (bool eligible, bool standing);
}

/// @notice Library to encode and decode strings in Base64.
/// @author SolDAO (https://github.com/Sol-DAO/solbase/blob/main/src/utils/Base64.sol)
/// @author Modified from Solady (https://github.com/vectorized/solady/blob/main/src/utils/Base64.sol)
library Base64 {
    /// @dev Encodes `data` using the base64 encoding described in RFC 4648.
    /// See: https://datatracker.ietf.org/doc/html/rfc4648
    /// @param fileSafe  Whether to replace '+' with '-' and '/' with '_'.
    /// @param noPadding Whether to strip away the padding.
    function encode(bytes memory data, bool fileSafe, bool noPadding) internal pure returns (string memory result) {
        assembly {
            let dataLength := mload(data)

            if dataLength {
                // Multiply by 4/3 rounded up.
                // The `shl(2, ...)` is equivalent to multiplying by 4.
                let encodedLength := shl(2, div(add(dataLength, 2), 3))

                // Set `result` to point to the start of the free memory.
                result := mload(0x40)

                // Store the table into the scratch space.
                // Offsetted by -1 byte so that the `mload` will load the character.
                // We will rewrite the free memory pointer at `0x40` later with
                // the allocated size.
                // The magic constant 0x0230 will translate "-_" + "+/".
                mstore(0x1f, "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdef")
                mstore(0x3f, sub("ghijklmnopqrstuvwxyz0123456789-_", mul(iszero(fileSafe), 0x0230)))

                // Skip the first slot, which stores the length.
                let ptr := add(result, 0x20)
                let end := add(ptr, encodedLength)

                // Run over the input, 3 bytes at a time.
                // prettier-ignore
                for {} 1 {} {
                    data := add(data, 3) // Advance 3 bytes.
                    let input := mload(data)

                    // Write 4 bytes. Optimized for fewer stack operations.
                    mstore8(    ptr    , mload(and(shr(18, input), 0x3F)))
                    mstore8(add(ptr, 1), mload(and(shr(12, input), 0x3F)))
                    mstore8(add(ptr, 2), mload(and(shr( 6, input), 0x3F)))
                    mstore8(add(ptr, 3), mload(and(        input , 0x3F)))
                    
                    ptr := add(ptr, 4) // Advance 4 bytes.
                    // prettier-ignore
                    if iszero(lt(ptr, end)) { break }
                }

                let r := mod(dataLength, 3)

                switch noPadding
                case 0 {
                    // Offset `ptr` and pad with '='. We can simply write over the end.
                    mstore8(sub(ptr, iszero(iszero(r))), 0x3d) // Pad at `ptr - 1` if `r > 0`.
                    mstore8(sub(ptr, shl(1, eq(r, 1))), 0x3d) // Pad at `ptr - 2` if `r == 1`.
                    // Write the length of the string.
                    mstore(result, encodedLength)
                }
                default {
                    // Write the length of the string.
                    mstore(result, sub(encodedLength, add(iszero(iszero(r)), eq(r, 1))))
                }

                // Allocate the memory for the string.
                // Add 31 and mask with `not(31)` to round the
                // free memory pointer up the next multiple of 32.
                mstore(0x40, and(add(end, 31), not(31)))
            }
        }
    }

    /// @dev Encodes `data` using the base64 encoding described in RFC 4648.
    /// Equivalent to `encode(data, false, false)`.
    function encode(bytes memory data) internal pure returns (string memory result) {
        result = encode(data, false, false);
    }

    /// @dev Encodes `data` using the base64 encoding described in RFC 4648.
    /// Equivalent to `encode(data, fileSafe, false)`.
    function encode(bytes memory data, bool fileSafe) internal pure returns (string memory result) {
        result = encode(data, fileSafe, false);
    }

    /// @dev Decodes base64 encoded `data`.
    ///
    /// Supports:
    /// - RFC 4648 (both standard and file-safe mode).
    /// - RFC 3501 (63: ',').
    ///
    /// Does not support:
    /// - Line breaks.
    ///
    /// Note: For performance reasons,
    /// this function will NOT revert on invalid `data` inputs.
    /// Outputs for invalid inputs will simply be undefined behaviour.
    /// It is the user's responsibility to ensure that the `data`
    /// is a valid base64 encoded string.
    function decode(string memory data) internal pure returns (bytes memory result) {
        assembly {
            let dataLength := mload(data)

            if dataLength {
                let end := add(data, dataLength)
                let decodedLength := mul(shr(2, dataLength), 3)

                switch and(dataLength, 3)
                case 0 {
                    // If padded.
                    decodedLength := sub(
                        decodedLength,
                        add(eq(and(mload(end), 0xFF), 0x3d), eq(and(mload(end), 0xFFFF), 0x3d3d))
                    )
                }
                default {
                    // If non-padded.
                    decodedLength := add(decodedLength, sub(and(dataLength, 3), 1))
                }

                result := mload(0x40)

                // Write the length of the string.
                mstore(result, decodedLength)

                // Skip the first slot, which stores the length.
                let ptr := add(result, 0x20)

                // Load the table into the scratch space.
                // Constants are optimized for smaller bytecode with zero gas overhead.
                // `m` also doubles as the mask of the upper 6 bits.
                let m := 0xfc000000fc00686c7074787c8084888c9094989ca0a4a8acb0b4b8bcc0c4c8cc
                mstore(0x5b, m)
                mstore(0x3b, 0x04080c1014181c2024282c3034383c4044484c5054585c6064)
                mstore(0x1a, 0xf8fcf800fcd0d4d8dce0e4e8ecf0f4)

                // prettier-ignore
                for {} 1 {} {
                    // Read 4 bytes.
                    data := add(data, 4)
                    let input := mload(data)

                    // Write 3 bytes.
                    mstore(ptr, or(
                        and(m, mload(byte(28, input))),
                        shr(6, or(
                            and(m, mload(byte(29, input))),
                            shr(6, or(
                                and(m, mload(byte(30, input))),
                                shr(6, mload(byte(31, input)))
                            ))
                        ))
                    ))

                    ptr := add(ptr, 3)
                    
                    // prettier-ignore
                    if iszero(lt(data, end)) { break }
                }

                // Allocate the memory for the string.
                // Add 32 + 31 and mask with `not(31)` to round the
                // free memory pointer up the next multiple of 32.
                mstore(0x40, and(add(add(result, decodedLength), 63), not(31)))

                // Restore the zero slot.
                mstore(0x60, 0)
            }
        }
    }
}

/// @notice Library for converting numbers into strings and other string operations.
/// @author SolDAO (https://github.com/Sol-DAO/solbase/blob/main/src/utils/LibString.sol)
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/LibString.sol)
library LibString {
    /// -----------------------------------------------------------------------
    /// Custom Errors
    /// -----------------------------------------------------------------------

    /// @dev The `length` of the output is too small to contain all the hex digits.
    error HexLengthInsufficient();

    /// -----------------------------------------------------------------------
    /// Constants
    /// -----------------------------------------------------------------------

    /// @dev The constant returned when the `search` is not found in the string.
    uint256 internal constant NOT_FOUND = uint256(int256(-1));

    /// -----------------------------------------------------------------------
    /// Decimal Operations
    /// -----------------------------------------------------------------------

    /// @dev Returns the base 10 decimal representation of `value`.
    function toString(uint256 value) internal pure returns (string memory str) {
        assembly {
            // The maximum value of a uint256 contains 78 digits (1 byte per digit), but
            // we allocate 0xa0 bytes to keep the free memory pointer 32-byte word aligned.
            // We will need 1 word for the trailing zeros padding, 1 word for the length,
            // and 3 words for a maximum of 78 digits. Total: 5 * 0x20 = 0xa0.
            let m := add(mload(0x40), 0xa0)
            // Update the free memory pointer to allocate.
            mstore(0x40, m)
            // Assign the `str` to the end.
            str := sub(m, 0x20)
            // Zeroize the slot after the string.
            mstore(str, 0)

            // Cache the end of the memory to calculate the length later.
            let end := str

            // We write the string from rightmost digit to leftmost digit.
            // The following is essentially a do-while loop that also handles the zero case.
            // prettier-ignore
            for { let temp := value } 1 {} {
                str := sub(str, 1)
                // Write the character to the pointer.
                // The ASCII index of the '0' character is 48.
                mstore8(str, add(48, mod(temp, 10)))
                // Keep dividing `temp` until zero.
                temp := div(temp, 10)
                // prettier-ignore
                if iszero(temp) { break }
            }

            let length := sub(end, str)
            // Move the pointer 32 bytes leftwards to make room for the length.
            str := sub(str, 0x20)
            // Store the length.
            mstore(str, length)
        }
    }

    /// -----------------------------------------------------------------------
    /// Hexadecimal Operations
    /// -----------------------------------------------------------------------

    /// @dev Returns the hexadecimal representation of `value`,
    /// left-padded to an input length of `length` bytes.
    /// The output is prefixed with "0x" encoded using 2 hexadecimal digits per byte,
    /// giving a total length of `length * 2 + 2` bytes.
    /// Reverts if `length` is too small for the output to contain all the digits.
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory str) {
        assembly {
            let start := mload(0x40)
            // We need 0x20 bytes for the trailing zeros padding, `length * 2` bytes
            // for the digits, 0x02 bytes for the prefix, and 0x20 bytes for the length.
            // We add 0x20 to the total and round down to a multiple of 0x20.
            // (0x20 + 0x20 + 0x02 + 0x20) = 0x62.
            let m := add(start, and(add(shl(1, length), 0x62), not(0x1f)))
            // Allocate the memory.
            mstore(0x40, m)
            // Assign the `str` to the end.
            str := sub(m, 0x20)
            // Zeroize the slot after the string.
            mstore(str, 0)

            // Cache the end to calculate the length later.
            let end := str
            // Store "0123456789abcdef" in scratch space.
            mstore(0x0f, 0x30313233343536373839616263646566)

            let temp := value
            // We write the string from rightmost digit to leftmost digit.
            // The following is essentially a do-while loop that also handles the zero case.
            // prettier-ignore
            for {} 1 {} {
                str := sub(str, 2)
                mstore8(add(str, 1), mload(and(temp, 15)))
                mstore8(str, mload(and(shr(4, temp), 15)))
                temp := shr(8, temp)
                length := sub(length, 1)
                // prettier-ignore
                if iszero(length) { break }
            }

            if temp {
                // Store the function selector of `HexLengthInsufficient()`.
                mstore(0x00, 0x2194895a)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }

            // Compute the string's length.
            let strLength := add(sub(end, str), 2)
            // Move the pointer and write the "0x" prefix.
            str := sub(str, 0x20)
            mstore(str, 0x3078)
            // Move the pointer and write the length.
            str := sub(str, 2)
            mstore(str, strLength)
        }
    }

    /// @dev Returns the hexadecimal representation of `value`.
    /// The output is prefixed with "0x" and encoded using 2 hexadecimal digits per byte.
    /// As address are 20 bytes long, the output will left-padded to have
    /// a length of `20 * 2 + 2` bytes.
    function toHexString(uint256 value) internal pure returns (string memory str) {
        assembly {
            let start := mload(0x40)
            // We need 0x20 bytes for the trailing zeros padding, 0x20 bytes for the length,
            // 0x02 bytes for the prefix, and 0x40 bytes for the digits.
            // The next multiple of 0x20 above (0x20 + 0x20 + 0x02 + 0x40) is 0xa0.
            let m := add(start, 0xa0)
            // Allocate the memory.
            mstore(0x40, m)
            // Assign the `str` to the end.
            str := sub(m, 0x20)
            // Zeroize the slot after the string.
            mstore(str, 0)

            // Cache the end to calculate the length later.
            let end := str
            // Store "0123456789abcdef" in scratch space.
            mstore(0x0f, 0x30313233343536373839616263646566)

            // We write the string from rightmost digit to leftmost digit.
            // The following is essentially a do-while loop that also handles the zero case.
            // prettier-ignore
            for { let temp := value } 1 {} {
                str := sub(str, 2)
                mstore8(add(str, 1), mload(and(temp, 15)))
                mstore8(str, mload(and(shr(4, temp), 15)))
                temp := shr(8, temp)
                // prettier-ignore
                if iszero(temp) { break }
            }

            // Compute the string's length.
            let strLength := add(sub(end, str), 2)
            // Move the pointer and write the "0x" prefix.
            str := sub(str, 0x20)
            mstore(str, 0x3078)
            // Move the pointer and write the length.
            str := sub(str, 2)
            mstore(str, strLength)
        }
    }

    /// @dev Returns the hexadecimal representation of `value`.
    /// The output is prefixed with "0x" and encoded using 2 hexadecimal digits per byte.
    function toHexString(address value) internal pure returns (string memory str) {
        assembly {
            let start := mload(0x40)
            // We need 0x20 bytes for the length, 0x02 bytes for the prefix,
            // and 0x28 bytes for the digits.
            // The next multiple of 0x20 above (0x20 + 0x02 + 0x28) is 0x60.
            str := add(start, 0x60)

            // Allocate the memory.
            mstore(0x40, str)
            // Store "0123456789abcdef" in scratch space.
            mstore(0x0f, 0x30313233343536373839616263646566)

            let length := 20
            // We write the string from rightmost digit to leftmost digit.
            // The following is essentially a do-while loop that also handles the zero case.
            // prettier-ignore
            for { let temp := value } 1 {} {
                str := sub(str, 2)
                mstore8(add(str, 1), mload(and(temp, 15)))
                mstore8(str, mload(and(shr(4, temp), 15)))
                temp := shr(8, temp)
                length := sub(length, 1)
                // prettier-ignore
                if iszero(length) { break }
            }

            // Move the pointer and write the "0x" prefix.
            str := sub(str, 32)
            mstore(str, 0x3078)
            // Move the pointer and write the length.
            str := sub(str, 2)
            mstore(str, 42)
        }
    }

    /// -----------------------------------------------------------------------
    /// Other String Operations
    /// -----------------------------------------------------------------------

    // For performance and bytecode compactness, all indices of the following operations
    // are byte (ASCII) offsets, not UTF character offsets.

    /// @dev Returns `subject` all occurances of `search` replaced with `replacement`.
    function replace(
        string memory subject,
        string memory search,
        string memory replacement
    ) internal pure returns (string memory result) {
        assembly {
            let subjectLength := mload(subject)
            let searchLength := mload(search)
            let replacementLength := mload(replacement)

            subject := add(subject, 0x20)
            search := add(search, 0x20)
            replacement := add(replacement, 0x20)
            result := add(mload(0x40), 0x20)

            let subjectEnd := add(subject, subjectLength)
            if iszero(gt(searchLength, subjectLength)) {
                let subjectSearchEnd := add(sub(subjectEnd, searchLength), 1)
                let h := 0
                if iszero(lt(searchLength, 32)) {
                    h := keccak256(search, searchLength)
                }
                let m := shl(3, sub(32, and(searchLength, 31)))
                let s := mload(search)
                // prettier-ignore
                for {} 1 {} {
                    let t := mload(subject)
                    // Whether the first `searchLength % 32` bytes of 
                    // `subject` and `search` matches.
                    if iszero(shr(m, xor(t, s))) {
                        if h {
                            if iszero(eq(keccak256(subject, searchLength), h)) {
                                mstore(result, t)
                                result := add(result, 1)
                                subject := add(subject, 1)
                                // prettier-ignore
                                if iszero(lt(subject, subjectSearchEnd)) { break }
                                continue
                            }
                        }
                        // Copy the `replacement` one word at a time.
                        // prettier-ignore
                        for { let o := 0 } 1 {} {
                            mstore(add(result, o), mload(add(replacement, o)))
                            o := add(o, 0x20)
                            // prettier-ignore
                            if iszero(lt(o, replacementLength)) { break }
                        }
                        result := add(result, replacementLength)
                        subject := add(subject, searchLength)
                        if searchLength {
                            // prettier-ignore
                            if iszero(lt(subject, subjectSearchEnd)) { break }
                            continue
                        }
                    }
                    mstore(result, t)
                    result := add(result, 1)
                    subject := add(subject, 1)
                    // prettier-ignore
                    if iszero(lt(subject, subjectSearchEnd)) { break }
                }
            }

            let resultRemainder := result
            result := add(mload(0x40), 0x20)
            let k := add(sub(resultRemainder, result), sub(subjectEnd, subject))
            // Copy the rest of the string one word at a time.
            // prettier-ignore
            for {} lt(subject, subjectEnd) {} {
                mstore(resultRemainder, mload(subject))
                resultRemainder := add(resultRemainder, 0x20)
                subject := add(subject, 0x20)
            }
            result := sub(result, 0x20)
            // Zeroize the slot after the string.
            let last := add(add(result, 0x20), k)
            mstore(last, 0)
            // Allocate memory for the length and the bytes,
            // rounded up to a multiple of 32.
            mstore(0x40, and(add(last, 31), not(31)))
            // Store the length of the result.
            mstore(result, k)
        }
    }

    /// @dev Returns the byte index of the first location of `search` in `subject`,
    /// searching from left to right, starting from `from`.
    /// Returns `NOT_FOUND` (i.e. `type(uint256).max`) if the `search` is not found.
    function indexOf(string memory subject, string memory search, uint256 from) internal pure returns (uint256 result) {
        assembly {
            // prettier-ignore
            for { let subjectLength := mload(subject) } 1 {} {
                if iszero(mload(search)) {
                    // `result = min(from, subjectLength)`.
                    result := xor(from, mul(xor(from, subjectLength), lt(subjectLength, from)))
                    break
                }
                let searchLength := mload(search)
                let subjectStart := add(subject, 0x20)    
                
                result := not(0) // Initialize to `NOT_FOUND`.

                subject := add(subjectStart, from)
                let subjectSearchEnd := add(sub(add(subjectStart, subjectLength), searchLength), 1)

                let m := shl(3, sub(32, and(searchLength, 31)))
                let s := mload(add(search, 0x20))

                // prettier-ignore
                if iszero(lt(subject, subjectSearchEnd)) { break }

                if iszero(lt(searchLength, 32)) {
                    // prettier-ignore
                    for { let h := keccak256(add(search, 0x20), searchLength) } 1 {} {
                        if iszero(shr(m, xor(mload(subject), s))) {
                            if eq(keccak256(subject, searchLength), h) {
                                result := sub(subject, subjectStart)
                                break
                            }
                        }
                        subject := add(subject, 1)
                        // prettier-ignore
                        if iszero(lt(subject, subjectSearchEnd)) { break }
                    }
                    break
                }
                // prettier-ignore
                for {} 1 {} {
                    if iszero(shr(m, xor(mload(subject), s))) {
                        result := sub(subject, subjectStart)
                        break
                    }
                    subject := add(subject, 1)
                    // prettier-ignore
                    if iszero(lt(subject, subjectSearchEnd)) { break }
                }
                break
            }
        }
    }

    /// @dev Returns the byte index of the first location of `search` in `subject`,
    /// searching from left to right.
    /// Returns `NOT_FOUND` (i.e. `type(uint256).max`) if the `search` is not found.
    function indexOf(string memory subject, string memory search) internal pure returns (uint256 result) {
        result = indexOf(subject, search, 0);
    }

    /// @dev Returns the byte index of the first location of `search` in `subject`,
    /// searching from right to left, starting from `from`.
    /// Returns `NOT_FOUND` (i.e. `type(uint256).max`) if the `search` is not found.
    function lastIndexOf(
        string memory subject,
        string memory search,
        uint256 from
    ) internal pure returns (uint256 result) {
        assembly {
            // prettier-ignore
            for {} 1 {} {
                let searchLength := mload(search)
                let fromMax := sub(mload(subject), searchLength)
                if iszero(gt(fromMax, from)) {
                    from := fromMax
                }
                if iszero(mload(search)) {
                    result := from
                    break
                }
                result := not(0) // Initialize to `NOT_FOUND`.

                let subjectSearchEnd := sub(add(subject, 0x20), 1)

                subject := add(add(subject, 0x20), from)
                // prettier-ignore
                if iszero(gt(subject, subjectSearchEnd)) { break }
                // As this function is not too often used,
                // we shall simply use keccak256 for smaller bytecode size.
                // prettier-ignore
                for { let h := keccak256(add(search, 0x20), searchLength) } 1 {} {
                    if eq(keccak256(subject, searchLength), h) {
                        result := sub(subject, add(subjectSearchEnd, 1))
                        break
                    }
                    subject := sub(subject, 1)
                    // prettier-ignore
                    if iszero(gt(subject, subjectSearchEnd)) { break }
                }
                break
            }
        }
    }

    /// @dev Returns the index of the first location of `search` in `subject`,
    /// searching from right to left.
    /// Returns `NOT_FOUND` (i.e. `type(uint256).max`) if the `search` is not found.
    function lastIndexOf(string memory subject, string memory search) internal pure returns (uint256 result) {
        result = lastIndexOf(subject, search, uint256(int256(-1)));
    }

    /// @dev Returns whether `subject` starts with `search`.
    function startsWith(string memory subject, string memory search) internal pure returns (bool result) {
        assembly {
            let searchLength := mload(search)
            // Just using keccak256 directly is actually cheaper.
            result := and(
                iszero(gt(searchLength, mload(subject))),
                eq(keccak256(add(subject, 0x20), searchLength), keccak256(add(search, 0x20), searchLength))
            )
        }
    }

    /// @dev Returns whether `subject` ends with `search`.
    function endsWith(string memory subject, string memory search) internal pure returns (bool result) {
        assembly {
            let searchLength := mload(search)
            let subjectLength := mload(subject)
            // Whether `search` is not longer than `subject`.
            let withinRange := iszero(gt(searchLength, subjectLength))
            // Just using keccak256 directly is actually cheaper.
            result := and(
                withinRange,
                eq(
                    keccak256(
                        // `subject + 0x20 + max(subjectLength - searchLength, 0)`.
                        add(add(subject, 0x20), mul(withinRange, sub(subjectLength, searchLength))),
                        searchLength
                    ),
                    keccak256(add(search, 0x20), searchLength)
                )
            )
        }
    }

    /// @dev Returns `subject` repeated `times`.
    function repeat(string memory subject, uint256 times) internal pure returns (string memory result) {
        assembly {
            let subjectLength := mload(subject)
            if iszero(or(iszero(times), iszero(subjectLength))) {
                subject := add(subject, 0x20)
                result := mload(0x40)
                let output := add(result, 0x20)
                // prettier-ignore
                for {} 1 {} {
                    // Copy the `subject` one word at a time.
                    // prettier-ignore
                    for { let o := 0 } 1 {} {
                        mstore(add(output, o), mload(add(subject, o)))
                        o := add(o, 0x20)
                        // prettier-ignore
                        if iszero(lt(o, subjectLength)) { break }
                    }
                    output := add(output, subjectLength)
                    times := sub(times, 1)
                    // prettier-ignore
                    if iszero(times) { break }
                }
                // Zeroize the slot after the string.
                mstore(output, 0)
                // Store the length.
                let resultLength := sub(output, add(result, 0x20))
                mstore(result, resultLength)
                // Allocate memory for the length and the bytes,
                // rounded up to a multiple of 32.
                mstore(0x40, add(result, and(add(resultLength, 63), not(31))))
            }
        }
    }

    /// @dev Returns a copy of `subject` sliced from `start` to `end` (exclusive).
    /// `start` and `end` are byte offsets.
    function slice(string memory subject, uint256 start, uint256 end) internal pure returns (string memory result) {
        assembly {
            let subjectLength := mload(subject)
            if iszero(gt(subjectLength, end)) {
                end := subjectLength
            }
            if iszero(gt(subjectLength, start)) {
                start := subjectLength
            }
            if lt(start, end) {
                result := mload(0x40)
                let resultLength := sub(end, start)
                mstore(result, resultLength)
                subject := add(subject, start)
                // Copy the `subject` one word at a time, backwards.
                // prettier-ignore
                for { let o := and(add(resultLength, 31), not(31)) } 1 {} {
                    mstore(add(result, o), mload(add(subject, o)))
                    o := sub(o, 0x20)
                    // prettier-ignore
                    if iszero(o) { break }
                }
                // Zeroize the slot after the string.
                mstore(add(add(result, 0x20), resultLength), 0)
                // Allocate memory for the length and the bytes,
                // rounded up to a multiple of 32.
                mstore(0x40, add(result, and(add(resultLength, 63), not(31))))
            }
        }
    }

    /// @dev Returns a copy of `subject` sliced from `start` to the end of the string.
    /// `start` is a byte offset.
    function slice(string memory subject, uint256 start) internal pure returns (string memory result) {
        result = slice(subject, start, uint256(int256(-1)));
    }

    /// @dev Returns all the indices of `search` in `subject`.
    /// The indices are byte offsets.
    function indicesOf(string memory subject, string memory search) internal pure returns (uint256[] memory result) {
        assembly {
            let subjectLength := mload(subject)
            let searchLength := mload(search)

            if iszero(gt(searchLength, subjectLength)) {
                subject := add(subject, 0x20)
                search := add(search, 0x20)
                result := add(mload(0x40), 0x20)

                let subjectStart := subject
                let subjectSearchEnd := add(sub(add(subject, subjectLength), searchLength), 1)
                let h := 0
                if iszero(lt(searchLength, 32)) {
                    h := keccak256(search, searchLength)
                }
                let m := shl(3, sub(32, and(searchLength, 31)))
                let s := mload(search)
                // prettier-ignore
                for {} 1 {} {
                    let t := mload(subject)
                    // Whether the first `searchLength % 32` bytes of 
                    // `subject` and `search` matches.
                    if iszero(shr(m, xor(t, s))) {
                        if h {
                            if iszero(eq(keccak256(subject, searchLength), h)) {
                                subject := add(subject, 1)
                                // prettier-ignore
                                if iszero(lt(subject, subjectSearchEnd)) { break }
                                continue
                            }
                        }
                        // Append to `result`.
                        mstore(result, sub(subject, subjectStart))
                        result := add(result, 0x20)
                        // Advance `subject` by `searchLength`.
                        subject := add(subject, searchLength)
                        if searchLength {
                            // prettier-ignore
                            if iszero(lt(subject, subjectSearchEnd)) { break }
                            continue
                        }
                    }
                    subject := add(subject, 1)
                    // prettier-ignore
                    if iszero(lt(subject, subjectSearchEnd)) { break }
                }
                let resultEnd := result
                // Assign `result` to the free memory pointer.
                result := mload(0x40)
                // Store the length of `result`.
                mstore(result, shr(5, sub(resultEnd, add(result, 0x20))))
                // Allocate memory for result.
                // We allocate one more word, so this array can be recycled for {split}.
                mstore(0x40, add(resultEnd, 0x20))
            }
        }
    }

    /// @dev Returns a arrays of strings based on the `delimiter` inside of the `subject` string.
    function split(string memory subject, string memory delimiter) internal pure returns (string[] memory result) {
        uint256[] memory indices = indicesOf(subject, delimiter);
        assembly {
            if mload(indices) {
                let indexPtr := add(indices, 0x20)
                let indicesEnd := add(indexPtr, shl(5, add(mload(indices), 1)))
                mstore(sub(indicesEnd, 0x20), mload(subject))
                mstore(indices, add(mload(indices), 1))
                let prevIndex := 0
                // prettier-ignore
                for {} 1 {} {
                    let index := mload(indexPtr)
                    mstore(indexPtr, 0x60)                        
                    if iszero(eq(index, prevIndex)) {
                        let element := mload(0x40)
                        let elementLength := sub(index, prevIndex)
                        mstore(element, elementLength)
                        // Copy the `subject` one word at a time, backwards.
                        // prettier-ignore
                        for { let o := and(add(elementLength, 31), not(31)) } 1 {} {
                            mstore(add(element, o), mload(add(add(subject, prevIndex), o)))
                            o := sub(o, 0x20)
                            // prettier-ignore
                            if iszero(o) { break }
                        }
                        // Zeroize the slot after the string.
                        mstore(add(add(element, 0x20), elementLength), 0)
                        // Allocate memory for the length and the bytes,
                        // rounded up to a multiple of 32.
                        mstore(0x40, add(element, and(add(elementLength, 63), not(31))))
                        // Store the `element` into the array.
                        mstore(indexPtr, element)                        
                    }
                    prevIndex := add(index, mload(delimiter))
                    indexPtr := add(indexPtr, 0x20)
                    // prettier-ignore
                    if iszero(lt(indexPtr, indicesEnd)) { break }
                }
                result := indices
                if iszero(mload(delimiter)) {
                    result := add(indices, 0x20)
                    mstore(result, sub(mload(indices), 2))
                }
            }
        }
    }

    /// @dev Returns a concatenated string of `a` and `b`.
    /// Cheaper than `string.concat()` and does not de-align the free memory pointer.
    function concat(string memory a, string memory b) internal pure returns (string memory result) {
        assembly {
            result := mload(0x40)
            let aLength := mload(a)
            // Copy `a` one word at a time, backwards.
            // prettier-ignore
            for { let o := and(add(mload(a), 32), not(31)) } 1 {} {
                mstore(add(result, o), mload(add(a, o)))
                o := sub(o, 0x20)
                // prettier-ignore
                if iszero(o) { break }
            }
            let bLength := mload(b)
            let output := add(result, mload(a))
            // Copy `b` one word at a time, backwards.
            // prettier-ignore
            for { let o := and(add(bLength, 32), not(31)) } 1 {} {
                mstore(add(output, o), mload(add(b, o)))
                o := sub(o, 0x20)
                // prettier-ignore
                if iszero(o) { break }
            }
            let totalLength := add(aLength, bLength)
            let last := add(add(result, 0x20), totalLength)
            // Zeroize the slot after the string.
            mstore(last, 0)
            // Stores the length.
            mstore(result, totalLength)
            // Allocate memory for the length and the bytes,
            // rounded up to a multiple of 32.
            mstore(0x40, and(add(last, 31), not(31)))
        }
    }

    /// @dev Packs a single string with its length into a single word.
    /// Returns `bytes32(0)` if the length is zero or greater than 31.
    function packOne(string memory a) internal pure returns (bytes32 result) {
        assembly {
            // We don't need to zero right pad the string,
            // since this is our own custom non-standard packing scheme.
            result := mul(
                // Load the length and the bytes.
                mload(add(a, 0x1f)),
                // `length != 0 && length < 32`. Abuses underflow.
                // Assumes that the length is valid and within the block gas limit.
                lt(sub(mload(a), 1), 0x1f)
            )
        }
    }

    /// @dev Unpacks a string packed using {packOne}.
    /// Returns the empty string if `packed` is `bytes32(0)`.
    /// If `packed` is not an output of {packOne}, the output behaviour is undefined.
    function unpackOne(bytes32 packed) internal pure returns (string memory result) {
        assembly {
            // Grab the free memory pointer.
            result := mload(0x40)
            // Allocate 2 words (1 for the length, 1 for the bytes).
            mstore(0x40, add(result, 0x40))
            // Zeroize the length slot.
            mstore(result, 0)
            // Store the length and bytes.
            mstore(add(result, 0x1f), packed)
            // Right pad with zeroes.
            mstore(add(add(result, 0x20), mload(result)), 0)
        }
    }

    /// @dev Packs two strings with their lengths into a single word.
    /// Returns `bytes32(0)` if combined length is zero or greater than 30.
    function packTwo(string memory a, string memory b) internal pure returns (bytes32 result) {
        assembly {
            let aLength := mload(a)
            // We don't need to zero right pad the strings,
            // since this is our own custom non-standard packing scheme.
            result := mul(
                // Load the length and the bytes of `a` and `b`.
                or(shl(shl(3, sub(0x1f, aLength)), mload(add(a, aLength))), mload(sub(add(b, 0x1e), aLength))),
                // `totalLength != 0 && totalLength < 31`. Abuses underflow.
                // Assumes that the lengths are valid and within the block gas limit.
                lt(sub(add(aLength, mload(b)), 1), 0x1e)
            )
        }
    }

    /// @dev Unpacks strings packed using {packTwo}.
    /// Returns the empty strings if `packed` is `bytes32(0)`.
    /// If `packed` is not an output of {packTwo}, the output behaviour is undefined.
    function unpackTwo(bytes32 packed) internal pure returns (string memory resultA, string memory resultB) {
        assembly {
            // Grab the free memory pointer.
            resultA := mload(0x40)
            resultB := add(resultA, 0x40)
            // Allocate 2 words for each string (1 for the length, 1 for the byte). Total 4 words.
            mstore(0x40, add(resultB, 0x40))
            // Zeroize the length slots.
            mstore(resultA, 0)
            mstore(resultB, 0)
            // Store the lengths and bytes.
            mstore(add(resultA, 0x1f), packed)
            mstore(add(resultB, 0x1f), mload(add(add(resultA, 0x20), mload(resultA))))
            // Right pad with zeroes.
            mstore(add(add(resultA, 0x20), mload(resultA)), 0)
            mstore(add(add(resultB, 0x20), mload(resultB)), 0)
        }
    }

    /// @dev Directly returns `a` without copying.
    function directReturn(string memory a) internal pure {
        assembly {
            // Right pad with zeroes. Just in case the string is produced
            // by a method that doesn't zero right pad.
            mstore(add(add(a, 0x20), mload(a)), 0)
            // Store the return offset.
            // Assumes that the string does not start from the scratch space.
            mstore(sub(a, 0x20), 0x20)
            // End the transaction, returning the string.
            return(sub(a, 0x20), add(mload(a), 0x40))
        }
    }
}

/// @title Hats Protocol
/// @notice Hats are DAO-native revocable roles that are represented as semi-fungable tokens for composability
/// @dev This is a multitenant contract that can manage all Hats for a given chain
/// @author Hats Protocol
contract Hats is IHats, ERC1155, HatsIdUtilities {
    /*//////////////////////////////////////////////////////////////
                              HATS DATA MODELS
    //////////////////////////////////////////////////////////////*/

    struct Hat {
        // 1st storage slot
        address eligibility; // ─┐ can revoke Hat based on ruling | 20
        uint32 maxSupply; //  │ the max number of identical hats that can exist | 4
        uint8 lastHatId; // ─┘ indexes how many different hats an admin is holding | 1
        // 2nd slot
        address toggle; // ─┐ controls when Hat is active | 20
        uint96 config; // ─┘ active status & other settings (see schema below) | 12
        // 3rd+ slot (optional)
        string details;
        string imageURI;
    }

    /* Hat.config schema (by bit)
     *  0th bit  | `active` status; can be altered by toggle, via setHatStatus()
     *  1        | `mutable` option
     *  2 - 95   | unassigned
     */

    /*//////////////////////////////////////////////////////////////
                              HATS STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    uint32 public lastTopHatId; // initialized at 0

    string public baseImageURI;

    // see HatsIdUtilities.sol for more info on how Hat Ids work
    mapping(uint256 => Hat) internal _hats; // key: hatId => value: Hat struct

    mapping(uint256 => uint32) public hatSupply; // key: hatId => value: supply

    // for external contracts to check if Hat was revoked because the wearer is in bad standing
    mapping(uint256 => mapping(address => bool)) public badStandings; // key: hatId => value: (key: wearer => value: badStanding?)

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(string memory _name, string memory _baseImageURI) {
        name = _name;
        baseImageURI = _baseImageURI;
    }

    /*//////////////////////////////////////////////////////////////
                              HATS LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Creates and mints a Hat that is its own admin, i.e. a "topHat"
    /// @dev A topHat has no eligibility and no toggle
    /// @param _target The address to which the newly created topHat is minted
    /// @param _imageURI The image uri for this top hat and the fallback for its
    ///                  downstream hats [optional]
    /// @return topHatId The id of the newly created topHat
    function mintTopHat(
        address _target,
        string memory _details,
        string memory _imageURI
    ) public returns (uint256 topHatId) {
        // create hat

        topHatId = uint256(++lastTopHatId) << 224;

        _createHat(
            topHatId,
            _details, // details
            1, // maxSupply = 1
            address(0), // there is no eligibility
            address(0), // it has no toggle
            false, // its immutable
            _imageURI
        );

        _mint(_target, topHatId, 1, "");
    }

    // /// @notice Mints a topHat to the msg.sender and creates another Hat admin'd by the topHat
    // /// @param _details A description of the hat
    // /// @param _maxSupply The total instances of the Hat that can be worn at once
    // /// @param _eligibility The address that can report on the Hat wearer's standing
    // /// @param _toggle The address that can deactivate the hat [optional]
    // /// @param _mutable Whether the hat's properties are changeable after creation
    // /// @param _topHatImageURI The image uri for this top hat and the fallback for its
    // ///                        downstream hats [optional]
    // /// @param _firstHatImageURI The image uri for the first hat and the fallback for its
    // ///                        downstream hats [optional]
    // /// @return topHatId The id of the newly created topHat
    // /// @return firstHatId The id of the other newly created hat
    // function createTopHatAndHat(
    //     string memory _details, // encode as bytes32 ??
    //     uint32 _maxSupply,
    //     address _eligibility,
    //     address _toggle,
    //     bool _mutable,
    //     string memory _topHatImageURI,
    //     string memory _firstHatImageURI
    // ) public returns (uint256 topHatId, uint256 firstHatId) {
    //     topHatId = mintTopHat(msg.sender, _topHatImageURI);

    //     firstHatId = createHat(
    //         topHatId,
    //         _details,
    //         _maxSupply,
    //         _eligibility,
    //         _toggle,
    //         _mutable,
    //         _firstHatImageURI
    //     );
    // }

    /// @notice Creates a new hat. The msg.sender must wear the `_admin` hat.
    /// @dev Initializes a new Hat struct, but does not mint any tokens.
    /// @param _details A description of the Hat
    /// @param _maxSupply The total instances of the Hat that can be worn at once
    /// @param _admin The id of the Hat that will control who wears the newly created hat
    /// @param _eligibility The address that can report on the Hat wearer's status
    /// @param _toggle The address that can deactivate the Hat
    /// @param _mutable Whether the hat's properties are changeable after creation
    /// @param _imageURI The image uri for this hat and the fallback for its
    ///                  downstream hats [optional]
    /// @return newHatId The id of the newly created Hat
    function createHat(
        uint256 _admin,
        string memory _details, // encode as bytes32 ??
        uint32 _maxSupply,
        address _eligibility,
        address _toggle,
        bool _mutable,
        string memory _imageURI
    ) public returns (uint256 newHatId) {
        if (uint8(_admin) > 0) {
            revert MaxLevelsReached();
        }

        newHatId = getNextId(_admin);

        // to create a hat, you must be wearing one of its admin hats
        _checkAdmin(newHatId);

        // create the new hat
        _createHat(
            newHatId,
            _details,
            _maxSupply,
            _eligibility,
            _toggle,
            _mutable,
            _imageURI
        );

        // increment _admin.lastHatId
        ++_hats[_admin].lastHatId;
    }

    /// @notice Creates new hats in batch. The msg.sender must be an admin of each hat.
    /// @dev This is a convenience function that loops through the arrays and calls `createHat`.
    /// @param _admins Array of ids of admins for each hat to create
    /// @param _details Array of details for each hat to create
    /// @param _maxSupplies Array of supply caps for each hat to create
    /// @param _eligibilityModules Array of eligibility module addresses for each hat to
    /// create
    /// @param _toggleModules Array of toggle module addresses for each hat to create
    /// @param _imageURIs Array of imageURIs for each hat to create
    /// @return bool True if all createHat calls succeeded
    function batchCreateHats(
        uint256[] memory _admins,
        string[] memory _details,
        uint32[] memory _maxSupplies,
        address[] memory _eligibilityModules,
        address[] memory _toggleModules,
        bool[] memory _mutables,
        string[] memory _imageURIs
    ) public returns (bool) {
        // check if array lengths are the same
        uint256 length = _admins.length; // save an MLOAD

        bool sameLengths = (length == _details.length &&
            length == _maxSupplies.length &&
            length == _eligibilityModules.length &&
            length == _toggleModules.length &&
            length == _mutables.length &&
            length == _imageURIs.length);

        if (!sameLengths) revert BatchArrayLengthMismatch();

        // loop through and create each hat
        for (uint256 i = 0; i < length; ++i) {
            createHat(
                _admins[i],
                _details[i],
                _maxSupplies[i],
                _eligibilityModules[i],
                _toggleModules[i],
                _mutables[i],
                _imageURIs[i]
            );
        }

        return true;
    }

    function getNextId(uint256 _admin) public view returns (uint256) {
        uint8 nextHatId = _hats[_admin].lastHatId + 1;
        return buildHatId(_admin, nextHatId);
    }

    /// @notice Mints an ERC1155 token of the Hat to a recipient, who then "wears" the hat
    /// @dev The msg.sender must wear the admin Hat of `_hatId`
    /// @param _hatId The id of the Hat to mint
    /// @param _wearer The address to which the Hat is minted
    /// @return bool Whether the mint succeeded
    function mintHat(uint256 _hatId, address _wearer) public returns (bool) {
        Hat memory hat = _hats[_hatId];
        if (hat.maxSupply == 0) revert HatDoesNotExist(_hatId);

        // only the wearer of a hat's admin Hat can mint it
        _checkAdmin(_hatId);

        if (hatSupply[_hatId] >= hat.maxSupply) {
            revert AllHatsWorn(_hatId);
        }

        if (isWearerOfHat(_wearer, _hatId)) {
            revert AlreadyWearingHat(_wearer, _hatId);
        }

        _mint(_wearer, uint256(_hatId), 1, "");

        return true;
    }

    function batchMintHats(uint256[] memory _hatIds, address[] memory _wearers)
        public
        returns (bool)
    {
        uint256 length = _hatIds.length;
        if (length != _wearers.length) revert BatchArrayLengthMismatch();

        for (uint256 i = 0; i < length; ++i) {
            mintHat(_hatIds[i], _wearers[i]);
        }

        return true;
    }

    /// @notice Toggles a Hat's status from active to deactive, or vice versa
    /// @dev The msg.sender must be set as the hat's toggle
    /// @param _hatId The id of the Hat for which to adjust status
    /// @return bool Whether the status was toggled
    function setHatStatus(uint256 _hatId, bool newStatus)
        external
        returns (bool)
    {
        Hat storage hat = _hats[_hatId];

        if (msg.sender != hat.toggle) {
            revert NotHatsToggle();
        }

        return _processHatStatus(_hatId, newStatus);
    }

    /// @notice Checks a hat's toggle and, if new, toggle's the hat's status
    /// @dev // TODO
    /// @param _hatId The id of the Hat whose toggle we are checking
    /// @return bool Whether there was a new status
    function checkHatStatus(uint256 _hatId) external returns (bool) {
        Hat memory hat = _hats[_hatId];
        bool newStatus;

        bytes memory data = abi.encodeWithSignature(
            "getHatStatus(uint256)",
            _hatId
        );

        (bool success, bytes memory returndata) = hat.toggle.staticcall(data);

        // if function call succeeds with data of length > 0
        // then we know the contract exists and has the getWearerStatus function
        if (success && returndata.length > 0) {
            newStatus = abi.decode(returndata, (bool));
        } else {
            revert NotHatsToggle();
        }

        return _processHatStatus(_hatId, newStatus);
    }

    /// @notice Report from a hat's eligibility on the status of one of its wearers and, if `false`, revoke their hat
    /// @dev Burns the wearer's hat, if revoked
    /// @param _hatId The id of the hat
    /// @param _wearer The address of the hat wearer whose status is being reported
    /// @param _eligible Whether the wearer is eligible for the hat (will be revoked if
    /// false)
    /// @param _standing False if the wearer is no longer in good standing (and potentially should be penalized)
    /// @return bool Whether the report succeeded
    function setHatWearerStatus(
        uint256 _hatId,
        address _wearer,
        bool _eligible,
        bool _standing
    ) external returns (bool) {
        Hat memory hat = _hats[_hatId];

        if (msg.sender != hat.eligibility) {
            revert NotHatsEligibility();
        }

        _processHatWearerStatus(_hatId, _wearer, _eligible, _standing);

        return true;
    }

    /// @notice Check a hat's eligibility for a report on the status of one of the hat's wearers and, if `false`, revoke their hat
    /// @dev Burns the wearer's hat, if revoked
    /// @param _hatId The id of the hat
    /// @param _wearer The address of the Hat wearer whose status report is being requested
    function checkHatWearerStatus(uint256 _hatId, address _wearer)
        public
        returns (bool)
    {
        Hat memory hat = _hats[_hatId];
        bool eligible;
        bool standing;

        bytes memory data = abi.encodeWithSignature(
            "getWearerStatus(address,uint256)",
            _wearer,
            _hatId
        );

        (bool success, bytes memory returndata) = hat.eligibility.staticcall(
            data
        );

        // if function call succeeds with data of length > 0
        // then we know the contract exists and has the getWearerStatus function
        if (success && returndata.length > 0) {
            (eligible, standing) = abi.decode(returndata, (bool, bool));
        } else {
            revert NotHatsEligibility();
        }

        return _processHatWearerStatus(_hatId, _wearer, eligible, standing);
    }

    /// @notice Stop wearing a hat, aka "renounce" it
    /// @dev Burns the msg.sender's hat
    /// @param _hatId The id of the Hat being renounced
    function renounceHat(uint256 _hatId) external {
        if (!isWearerOfHat(msg.sender, _hatId)) {
            revert NotHatWearer();
        }
        // remove the hat
        _burn(msg.sender, _hatId, 1);

        // emit HatRenounced(_hatId, msg.sender);
    }

    /*//////////////////////////////////////////////////////////////
                              HATS INTERNAL LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Internal call for creating a new hat
    /// @dev Initializes a new Hat struct, but does not mint any tokens
    /// @param _id ID of the hat to be stored
    /// @param _details A description of the hat
    /// @param _maxSupply The total instances of the Hat that can be worn at once
    /// @param _eligibility The address that can report on the Hat wearer's status
    /// @param _toggle The address that can deactivate the hat [optional]
    /// @param _mutable Whether the hat's properties are changeable after creation
    /// @param _imageURI The image uri for this top hat and the fallback for its
    ///                  downstream hats [optional]
    /// @return hat The contents of the newly created hat
    function _createHat(
        uint256 _id,
        string memory _details, // encode as bytes32 ??
        uint32 _maxSupply,
        address _eligibility,
        address _toggle,
        bool _mutable,
        string memory _imageURI
    ) internal returns (Hat memory hat) {
        hat.details = _details;
        hat.maxSupply = _maxSupply;
        hat.eligibility = _eligibility;
        hat.toggle = _toggle;
        hat.imageURI = _imageURI;
        hat.config = _mutable ? uint96(3 << 94) : uint96(1 << 95);
        _hats[_id] = hat;

        emit HatCreated(
            _id,
            _details,
            _maxSupply,
            _eligibility,
            _toggle,
            _mutable,
            _imageURI
        );
    }

    // TODO write comment
    function _processHatStatus(uint256 _hatId, bool _newStatus)
        internal
        returns (bool updated)
    {
        // optimize later
        Hat storage hat = _hats[_hatId];

        if (_newStatus != _getHatStatus(hat)) {
            _setHatStatus(hat, _newStatus);
            emit HatStatusChanged(_hatId, _newStatus);
            updated = true;
        }
    }

    /// @notice Internal call to process wearer status from the eligibility module
    /// @dev Burns the wearer's Hat token if _eligible is false, and updates badStandings
    /// state if necessary
    /// @param _hatId The id of the Hat to revoke
    /// @param _wearer The address of the wearer in question
    /// @param _eligible Whether _wearer is eligible for the Hat (if false, this function
    /// will revoke their Hat)
    /// @param _standing Whether _wearer is in good standing (to be recorded in storage)
    function _processHatWearerStatus(
        uint256 _hatId,
        address _wearer,
        bool _eligible,
        bool _standing
    ) internal returns (bool updated) {
        // always ineligible if in bad standing
        if (!_eligible || !_standing) {
            // revoke the Hat by burning it
            _burn(_wearer, _hatId, 1);
        }

        // record standing for use by other contracts
        // note: here, standing and badStandings are opposite
        // i.e. if standing (true = good standing)
        // then badStandings[_hatId][wearer] will be false
        // if they are different, then something has changed, and we need to update
        // badStandings marker
        if (_standing == badStandings[_hatId][_wearer]) {
            badStandings[_hatId][_wearer] = !_standing;
            updated = true;
        }

        // emit WearerStatus(_hatId, _wearer, _eligible, _standing);
    }

    function transferHat(
        uint256 _hatId,
        address _from,
        address _to
    ) public {
        _checkAdmin(_hatId);

        // Checks storage instead of `isWearerOfHat` since admins may want to transfer revoked Hats to new wearers
        if (_balanceOf[_from][_hatId] < 1) {
            revert NotHatWearer();
        }

        //Adjust balances
        --_balanceOf[_from][_hatId];
        ++_balanceOf[_to][_hatId];

        emit TransferSingle(msg.sender, _from, _to, _hatId, 1);
    }

    /*//////////////////////////////////////////////////////////////
                              HATS ADMIN FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function _checkAdmin(uint256 _hatId) internal {
        if (!isAdminOfHat(msg.sender, _hatId)) {
            revert NotAdmin(msg.sender, _hatId);
        }
    }

    /// @notice Set a mutable hat to immutable
    /// @dev Sets the second bit of hat.config to 0
    /// @param _hatId The id of the Hat to make immutable
    function makeHatImmutable(uint256 _hatId) external {
        _checkAdmin(_hatId);

        Hat storage hat = _hats[_hatId];

        if (!_isMutable(hat)) {
            revert Immutable();
        }

        hat.config &= ~uint96(1 << 94);

        emit HatMutabilityChanged(_hatId);
    }

    /// @notice Change a hat's details
    /// @dev Hat must be mutable
    /// @param _hatId The id of the Hat to change
    /// @param _newDetails The new details
    function changeHatDetails(uint256 _hatId, string memory _newDetails)
        external
    {
        _checkAdmin(_hatId);
        Hat storage hat = _hats[_hatId];

        if (!_isMutable(hat)) {
            revert Immutable();
        }

        hat.details = _newDetails;

        emit HatDetailsChanged(_hatId, _newDetails);
    }

    /// @notice Change a hat's details
    /// @dev Hat must be mutable
    /// @param _hatId The id of the Hat to change
    /// @param _newEligibility The new eligibility module
    function changeHatEligibility(uint256 _hatId, address _newEligibility)
        external
    {
        _checkAdmin(_hatId);
        Hat storage hat = _hats[_hatId];

        if (!_isMutable(hat)) {
            revert Immutable();
        }

        hat.eligibility = _newEligibility;

        emit HatEligibilityChanged(_hatId, _newEligibility);
    }

    /// @notice Change a hat's details
    /// @dev Hat must be mutable
    /// @param _hatId The id of the Hat to change
    /// @param _newToggle The new toggle module
    function changeHatToggle(uint256 _hatId, address _newToggle) external {
        _checkAdmin(_hatId);
        Hat storage hat = _hats[_hatId];

        if (!_isMutable(hat)) {
            revert Immutable();
        }

        hat.toggle = _newToggle;

        emit HatToggleChanged(_hatId, _newToggle);
    }

    /// @notice Change a hat's details
    /// @dev Hat must be mutable
    /// @param _hatId The id of the Hat to change
    /// @param _newImageURI The new imageURI
    function changeHatImageURI(uint256 _hatId, string memory _newImageURI)
        external
    {
        _checkAdmin(_hatId);
        Hat storage hat = _hats[_hatId];

        if (!_isMutable(hat)) {
            revert Immutable();
        }

        hat.imageURI = _newImageURI;

        emit HatImageURIChanged(_hatId, _newImageURI);
    }

    /// @notice Change a hat's details
    /// @dev Hat must be mutable; new max supply cannot be greater than current supply
    /// @param _hatId The id of the Hat to change
    /// @param _newMaxSupply The new max supply
    function changeHatMaxSupply(uint256 _hatId, uint32 _newMaxSupply) external {
        _checkAdmin(_hatId);
        Hat storage hat = _hats[_hatId];

        if (!_isMutable(hat)) {
            revert Immutable();
        }

        if (_newMaxSupply < hatSupply[_hatId]) {
            revert NewMaxSupplyTooLow();
        }

        hat.maxSupply = _newMaxSupply;

        emit HatMaxSupplyChanged(_hatId, _newMaxSupply);
    }

    /*//////////////////////////////////////////////////////////////
                              HATS VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice View the properties of a given Hat
    /// @param _hatId The id of the Hat
    /// @return details The details of the Hat
    /// @return maxSupply The max supply of tokens for this Hat
    /// @return supply The number of current wearers of this Hat
    /// @return eligibility The eligibility address for this Hat
    /// @return toggle The toggle address for this Hat
    /// @return imageURI The image URI used for this Hat
    /// @return lastHatId The most recently created Hat with this Hat as admin; also the count of Hats with this Hat as admin
    /// @return mutable_ Whether this hat's properties can be changed
    /// @return active Whether the Hat is current active, as read from `_isActive`
    function viewHat(uint256 _hatId)
        public
        view
        returns (
            string memory details,
            uint32 maxSupply,
            uint32 supply,
            address eligibility,
            address toggle,
            string memory imageURI,
            uint8 lastHatId,
            bool mutable_,
            bool active
        )
    {
        Hat memory hat = _hats[_hatId];
        details = hat.details;
        maxSupply = hat.maxSupply;
        supply = hatSupply[_hatId];
        eligibility = hat.eligibility;
        toggle = hat.toggle;
        imageURI = getImageURIForHat(_hatId);
        lastHatId = hat.lastHatId;
        mutable_ = _isMutable(hat);
        active = _isActive(hat, _hatId);
    }

    /// @notice Checks whether a given address wears a given Hat
    /// @dev Convenience function that wraps `balanceOf`
    /// @param _user The address in question
    /// @param _hatId The id of the Hat that the `_user` might wear
    /// @return bool Whether the `_user` wears the Hat.
    function isWearerOfHat(address _user, uint256 _hatId)
        public
        view
        returns (bool)
    {
        return (balanceOf(_user, _hatId) >= 1);
    }

    /// @notice Checks whether a given address serves as the admin of a given Hat
    /// @dev Recursively checks if `_user` wears the admin Hat of the Hat in question. This is recursive since there may be a string of Hats as admins of Hats.
    /// @param _user The address in question
    /// @param _hatId The id of the Hat for which the `_user` might be the admin
    /// @return bool Whether the `_user` has admin rights for the Hat
    function isAdminOfHat(address _user, uint256 _hatId)
        public
        view
        returns (bool)
    {
        if (isTopHat(_hatId)) {
            return (isWearerOfHat(_user, _hatId));
        }

        uint8 adminHatLevel = getHatLevel(_hatId) - 1;

        while (adminHatLevel > 0) {
            if (isWearerOfHat(_user, getAdminAtLevel(_hatId, adminHatLevel))) {
                return true;
            }

            adminHatLevel--;
        }

        return isWearerOfHat(_user, getAdminAtLevel(_hatId, 0));
    }

    /// @notice Checks the active status of a hat
    /// @dev For internal use instead of `isActive` when passing Hat as param is preferable
    /// @param _hat The Hat struct
    /// @param _hatId The id of the hat
    /// @return active The active status of the hat
    function _isActive(Hat memory _hat, uint256 _hatId)
        internal
        view
        returns (bool)
    {
        bytes memory data = abi.encodeWithSignature(
            "getHatStatus(uint256)",
            _hatId
        );

        (bool success, bytes memory returndata) = _hat.toggle.staticcall(data);

        if (success && returndata.length > 0) {
            return abi.decode(returndata, (bool));
        } else {
            return _getHatStatus(_hat);
        }
    }

    // /// @notice Checks the active status of a hat
    // /// @dev Use `_isActive` for internal calls that can take a Hat as a param
    // /// @param _hatId The id of the hat
    // /// @return bool The active status of the hat
    // function isActive(uint256 _hatId) public view returns (bool) {
    //     return _isActive(_hats[_hatId], _hatId);
    // }

    function _getHatStatus(Hat memory _hat) internal view returns (bool) {
        return (_hat.config >> 95 != 0);
    }

    function _setHatStatus(Hat storage _hat, bool _status) internal {
        if (_status) {
            _hat.config |= uint96(1 << 95);
        } else {
            _hat.config &= ~uint96(1 << 95);
        }
    }

    function _isMutable(Hat memory _hat) internal view returns (bool) {
        return (_hat.config & uint96(1 << 94) != 0);
    }

    // function isMutable(uint256 _hatId) public view returns (bool) {
    //     return _isMutable(_hats[_hatId]);
    // }

    /// @notice Checks whether a wearer of a Hat is in good standing
    /// @dev Public function for use when pa    ssing a Hat object is not possible or preferable
    /// @param _wearer The address of the Hat wearer
    /// @param _hatId The id of the Hat
    /// @return standing Whether the wearer is in good standing
    function isInGoodStanding(address _wearer, uint256 _hatId)
        public
        view
        returns (bool standing)
    {
        (bool success, bytes memory returndata) = _hats[_hatId]
            .eligibility
            .staticcall(
                abi.encodeWithSignature(
                    "getWearerStatus(address,uint256)",
                    _wearer,
                    _hatId
                )
            );

        if (success && returndata.length > 0) {
            (, standing) = abi.decode(returndata, (bool, bool));
        } else {
            standing = !badStandings[_hatId][_wearer];
        }
    }

    /// @notice Internal call to check whether an address is eligible for a given Hat
    /// @dev Tries an external call to the Hat's eligibility module, defaulting to existing badStandings state if the call fails (ie if the eligibility module address does not conform to the IHatsEligibility interface)
    /// @param _wearer The address of the Hat wearer
    /// @param _hat The Hat object
    /// @param _hatId The id of the Hat
    /// @return eligible Whether the wearer is eligible for the Hat
    function _isEligible(
        address _wearer,
        Hat memory _hat,
        uint256 _hatId
    ) internal view returns (bool eligible) {
        (bool success, bytes memory returndata) = _hat.eligibility.staticcall(
            abi.encodeWithSignature(
                "getWearerStatus(address,uint256)",
                _wearer,
                _hatId
            )
        );

        if (success && returndata.length > 0) {
            bool standing;
            (eligible, standing) = abi.decode(returndata, (bool, bool));
            // never eligible if in bad standing
            if (eligible && !standing) eligible = false;
        } else {
            eligible = !badStandings[_hatId][_wearer];
        }
    }

    /// @notice Checks whether an address is eligible for a given Hat
    /// @dev Public function for use when passing a Hat object is not possible or preferable
    /// @param _hatId The id of the Hat
    /// @param _wearer The address to check
    /// @return bool
    function isEligible(address _wearer, uint256 _hatId)
        public
        view
        returns (bool)
    {
        // Hat memory hat = _hats[_hatId];
        return _isEligible(_wearer, _hats[_hatId], _hatId);
    }

    /// @notice Gets the imageURI for a given hat
    /// @dev If this hat does not have an imageURI set, recursively get the imageURI from
    ///      its admin
    /// @param _hatId The hat whose imageURI we're looking for
    /// @return imageURI The imageURI of this hat or, if empty, its admin
    function getImageURIForHat(uint256 _hatId)
        public
        view
        returns (string memory)
    {
        // check _hatId first to potentially avoid the `getHatLevel` call
        Hat memory hat = _hats[_hatId];

        string memory imageURI = hat.imageURI; // save 1 SLOAD

        // if _hatId has an imageURI, we return it
        if (bytes(imageURI).length > 0) {
            return imageURI;

            /// TODO bring back the following in a way that actually works
            // since there's only one hat with this imageURI at this level, by convention
            // we refer to it with `id = 0`
            // return string.concat(imageURI, "0");
        }

        // otherwise, we check its branch of admins
        uint256 level = getHatLevel(_hatId);

        // but first we check if _hatId is a tophat, in which case we fall back to the global image uri
        if (level == 0) return baseImageURI;

        // otherwise, we check each of its admins for a valid imageURI
        uint256 id;

        // already checked at `level` above, so we start the loop at `level - 1`
        for (uint256 i = level - 1; i > 0; --i) {
            id = getAdminAtLevel(_hatId, uint8(i));
            hat = _hats[id];
            imageURI = hat.imageURI;

            if (bytes(imageURI).length > 0) {
                return imageURI;

                /// TODO bring back the following in a way that actually works
                // since there are multiple hats with this imageURI at _hatId's level,
                // we need to use _hatId to disambiguate
                // return string.concat(imageURI, LibString.toString(_hatId));
            }
        }

        // if none of _hatId's admins has an imageURI of its own, we again fall back to the global image uri
        return baseImageURI;

        /// TODO bring back the following in a way that actually works
        // return string.concat(baseImageURI, LibString.toString(_hatId));
    }

    /// @notice Constructs the URI for a Hat, using data from the Hat struct
    /// @param _hatId The id of the Hat
    /// @return An ERC1155-compatible JSON string
    function _constructURI(uint256 _hatId)
        internal
        view
        returns (string memory)
    {
        Hat memory hat = _hats[_hatId];

        uint256 hatAdmin;

        if (isTopHat(_hatId)) {
            hatAdmin = _hatId;
        } else {
            hatAdmin = getAdminAtLevel(_hatId, getHatLevel(_hatId) - 1);
        }

        // split into two objects to avoid stack too deep error
        string memory idProperties = string.concat(
            '"domain": "',
            LibString.toString(getTophatDomain(_hatId)),
            '", "id": "',
            LibString.toString(_hatId),
            '", "pretty id": "',
            "{id}",
            '",'
        );

        string memory otherProperties = string.concat(
            '"status": "',
            (_isActive(hat, _hatId) ? "active" : "inactive"),
            '", "current supply": "',
            LibString.toString(hatSupply[_hatId]),
            '", "supply cap": "',
            LibString.toString(hat.maxSupply),
            '", "admin (id)": "',
            LibString.toString(hatAdmin),
            '", "admin (pretty id)": "',
            LibString.toHexString(hatAdmin, 32),
            '", "eligibility module": "',
            LibString.toHexString(hat.eligibility),
            '", "toggle module": "',
            LibString.toHexString(hat.toggle),
            '", "mutable": "',
            _isMutable(hat) ? "true" : "false",
            '"'
        );

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            string.concat(
                                '{"name": "',
                                "Hat",
                                '", "description": "',
                                hat.details, // alternatively, could point to a URI for offchain flexibility
                                '", "image": "',
                                getImageURIForHat(_hatId),
                                '",',
                                '"properties": ',
                                "{",
                                idProperties,
                                otherProperties,
                                "}",
                                "}"
                            )
                        )
                    )
                )
            );
    }

    /*//////////////////////////////////////////////////////////////
                              ERC1155 OVERRIDES
    //////////////////////////////////////////////////////////////*/

    /// @notice Gets the Hat token balance of a user for a given Hat
    /// @param wearer The address whose balance is being checked
    /// @param hatId The id of the Hat
    /// @return balance The `_user`'s balance of the Hat tokens. Will typically not be greater than 1.
    function balanceOf(address wearer, uint256 hatId)
        public
        view
        override(ERC1155, IHats)
        returns (uint256 balance)
    {
        Hat memory hat = _hats[hatId];

        balance = 0;

        if (_isActive(hat, hatId) && _isEligible(wearer, hat, hatId)) {
            balance = super.balanceOf(wearer, hatId);
        }
    }

    /// @notice Mints a Hat token to `to`
    /// @dev Overrides ERC1155._mint: skips the typical 1155TokenReceiver hook since Hat wearers don't control their own Hat, and adds Hats-specific state changes
    /// @param to The wearer of the Hat and the recipient of the newly minted token
    /// @param id The id of the Hat to mint, cast to uint256
    /// @param amount Must always be 1, since it's not possible wear >1 Hat
    /// @param data Can be empty since we skip the 1155TokenReceiver hook
    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal override {
        _balanceOf[to][id] += amount;

        // increment Hat supply counter
        ++hatSupply[uint256(id)];

        emit TransferSingle(msg.sender, address(0), to, id, amount);
    }

    /// @notice Burns a wearer's (`from`'s) Hat token
    /// @dev Overrides ERC1155._burn: adds Hats-specific state change
    /// @param from The wearer from which to burn the Hat token
    /// @param id The id of the Hat to burn, cast to uint256
    /// @param amount Must always be 1, since it's not possible wear >1 Hat
    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal override {
        _balanceOf[from][id] -= amount;

        // decrement Hat supply counter
        --hatSupply[uint256(id)];

        emit TransferSingle(msg.sender, from, address(0), id, amount);
    }

    function setApprovalForAll(address operator, bool approved)
        public
        pure
        override
    {
        revert();
    }

    /// @notice Safe transfers are not necessary for Hats since transfers are not handled by the wearer
    /// @dev Use `Hats.TransferHat()` instead
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) public pure override {
        revert();
    }

    /// @notice Safe transfers are not necessary for Hats since transfers are not handled by the wearer
    /// @dev Use `Hats.BatchTransferHats()` instead
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) public pure override {
        revert();
    }

    /// @notice View the uri for a Hat
    /// @param id The id of the Hat
    /// @return string An 1155-compatible JSON object
    function uri(uint256 id)
        public
        view
        override(ERC1155, IHats)
        returns (string memory)
    {
        return _constructURI(uint256(id));
    }
}