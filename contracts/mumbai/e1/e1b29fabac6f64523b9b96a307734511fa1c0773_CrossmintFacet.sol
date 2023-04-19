/*
 * This file is part of the Qomet Technologies contracts (https://github.com/qomet-tech/contracts).
 * Copyright (c) 2022 Qomet Technologies (https://qomet.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

import "../../../diamond/IDiamondFacet.sol";
import "./CrossmintInternal.sol";

contract CrossmintFacet is IDiamondFacet {

    function getFacetName()
      external pure override returns (string memory) {
        return "crossmint";
    }

    // CAUTION: Don't forget to update the version when adding new functionality
    function getFacetVersion()
      external pure override returns (string memory) {
        return "3.0.1";
    }

    function getFacetPI()
      external pure override returns (string[] memory) {
        string[] memory pi = new string[](3);
        pi[0] = "getCrossmintSettings()";
        pi[1] = "setCrossmintSettings(bool,address)";
        pi[2] = "crossmintReserve(address,uint256)";
        return pi;
    }

    function getFacetProtectedPI()
      external pure override returns (string[] memory) {
        string[] memory pi = new string[](1);
        pi[0] = "setCrossmintSettings(bool,address)";
        return pi;
    }

    function supportsInterface(bytes4 interfaceId)
      external pure override returns (bool) {
        return interfaceId == type(IDiamondFacet).interfaceId;
    }

    function getCrossmintSettings() external view returns (bool, address) {
        return CrossmintInternal._getCrossmintSettings();
    }

    function setCrossmintSettings(
        bool crossmintEnabled,
        address crossmintTrustedAddress
    ) external {
        CrossmintInternal._setCrossmintSettings(
            crossmintEnabled,
            crossmintTrustedAddress
        );
    }

    function crossmintReserve(address to, uint256 nrOfTokens) external payable {
        CrossmintInternal._crossmintReserve(to, nrOfTokens);
    }
}

/*
 * This file is part of the Qomet Technologies contracts (https://github.com/qomet-tech/contracts).
 * Copyright (c) 2022 Qomet Technologies (https://qomet.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

import "@openzeppelin/contracts/interfaces/IERC165.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
interface IDiamondFacet is IERC165 {

    // NOTE: The override MUST remain 'pure'.
    function getFacetName() external pure returns (string memory);

    // NOTE: The override MUST remain 'pure'.
    function getFacetVersion() external pure returns (string memory);

    // NOTE: The override MUST remain 'pure'.
    function getFacetPI() external pure returns (string[] memory);

    // NOTE: The override MUST remain 'pure'.
    function getFacetProtectedPI() external pure returns (string[] memory);
}

/*
 * This file is part of the Qomet Technologies contracts (https://github.com/qomet-tech/contracts).
 * Copyright (c) 2022 Qomet Technologies (https://qomet.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

import "../reserve-manager/ReserveManagerLib.sol";
import "./CrossmintStorage.sol";

library CrossmintInternal {

    function _getCrossmintSettings() internal view returns (bool, address) {
        return (__s().crossmintEnabled, __s().crossmintTrustedAddress);
    }

    function _setCrossmintSettings(
        bool crossmintEnabled,
        address crossmintTrustedAddress
    ) internal {
        __s().crossmintEnabled = crossmintEnabled;
        __s().crossmintTrustedAddress = crossmintTrustedAddress;
    }

    function _crossmintReserve(address to, uint256 nrOfTokens) internal {
        require(__s().crossmintEnabled, "CMI:NE");
        require(msg.sender == __s().crossmintTrustedAddress, "CMI:IC");
        ReserveManagerLib._reserveForAccount(to, nrOfTokens, "WEI");
    }

    function __s() private pure returns (CrossmintStorage.Layout storage) {
        return CrossmintStorage.layout();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

/*
 * This file is part of the Qomet Technologies contracts (https://github.com/qomet-tech/contracts).
 * Copyright (c) 2022 Qomet Technologies (https://qomet.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

import "./ReserveManagerInternal.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
library ReserveManagerLib {

    function _initReserveManager() internal {
        ReserveManagerInternal._initReserveManager();
    }

    function _reserveForAccount(
        address account,
        uint256 nrOfTokens,
        string memory paymentMethodName
    ) internal {
        ReserveManagerInternal._reserveForAccount(
            account,
            nrOfTokens,
            paymentMethodName
        );
    }
}

/*
 * This file is part of the Qomet Technologies contracts (https://github.com/qomet-tech/contracts).
 * Copyright (c) 2022 Qomet Technologies (https://qomet.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk. Just got the basic
///         idea from: https://github.com/solidstate-network/solidstate-solidity
library CrossmintStorage {

    struct Layout {
        bool crossmintEnabled;
        address crossmintTrustedAddress;
        mapping(bytes32 => bytes) extra;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256("qomet-tech.contracts.facets.collection.crossmint.storage");

    function layout() internal pure returns (Layout storage s) {
        bytes32 slot = STORAGE_SLOT;
        /* solhint-disable no-inline-assembly */
        assembly {
            s.slot := slot
        }
        /* solhint-enable no-inline-assembly */
    }
}

/*
 * This file is part of the Qomet Technologies contracts (https://github.com/qomet-tech/contracts).
 * Copyright (c) 2022 Qomet Technologies (https://qomet.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

import "../erc721/ERC721Lib.sol";
import "../minter/MinterLib.sol";
import "../whitelist-manager/WhitelistManagerLib.sol";
import "../payment-handler/PaymentHandlerLib.sol";
import "./ReserveManagerStorage.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
library ReserveManagerInternal {

    event ReserveToken(address account, uint256 tokenId);

    function _initReserveManager() internal {
        // We always keep the token #0 reserved for the contract
        __s().reservedTokenIdCounter = 1;
        __s().totalNrOfReservedTokens = 0;
    }

    function _getReservationSettings()
      internal view returns (bool, bool, uint256, uint256, uint256) {
        return (
            __s().reservationAllowed,
            __s().reservationAllowedWithoutWhitelisting,
            __s().reservationFeeWei,
            __s().reservePriceWeiPerToken,
            __s().totalNrOfReservedTokens
        );
    }

    function _setReservationSettings(
        bool reservationAllowed,
        bool reservationAllowedWithoutWhitelisting,
        uint256 reservationFeeWei,
        uint256 reservePriceWeiPerToken
    ) internal {
        __s().reservationAllowed = reservationAllowed;
        __s().reservationAllowedWithoutWhitelisting = reservationAllowedWithoutWhitelisting;
        __s().reservationFeeWei = reservationFeeWei;
        __s().reservePriceWeiPerToken = reservePriceWeiPerToken;
    }

    function _reserveForAccount(
        address account,
        uint256 nrOfTokens,
        string memory paymentMethodName
    ) internal {
        require(__s().reservationAllowed, "RM:NA");
        if (!__s().reservationAllowedWithoutWhitelisting) {
            uint256 nrOfWhitelistedTokens = WhitelistManagerLib._getWhitelistEntry(account);
            uint256 nrOfReservedTokens = __s().nrOfReservedTokens[account];
            require(nrOfReservedTokens < nrOfWhitelistedTokens, "RM:EMAX");
            require(nrOfTokens <= (nrOfWhitelistedTokens - nrOfReservedTokens), "RM:EMAX2");
        }
        PaymentHandlerLib._handlePayment(
            1, __s().reservationFeeWei,
            nrOfTokens, __s().reservePriceWeiPerToken,
            paymentMethodName
        );
        _reserve(account, nrOfTokens);
    }

    // NOTE: This is always allowed
    function _reserveForAccounts(
        address[] memory accounts,
        uint256[] memory nrOfTokensArray
    ) internal {
        require(accounts.length == nrOfTokensArray.length, "RM:II");
        for (uint256 i = 0; i < accounts.length; i++) {
            _reserve(accounts[i], nrOfTokensArray[i]);
        }
    }

    function _reserve(
        address account,
        uint256 nrOfTokens
    ) private {
        require(account != address(this), "RM:IA");
        for (uint256 i = 0; i < nrOfTokens; i++) {
            bool found = false;
            while (__s().reservedTokenIdCounter < MinterLib._getTokenIdCounter()) {
                if (ERC721Lib._ownerOf(__s().reservedTokenIdCounter) == address(this)) {
                    found = true;
                    break;
                }
                __s().reservedTokenIdCounter += 1;
            }
            if (found) {
                ERC721Lib._transfer(address(this), account, __s().reservedTokenIdCounter);
                emit ReserveToken(account, __s().reservedTokenIdCounter);
            } else {
                MinterLib._justMintTo(account);
                emit ReserveToken(account, MinterLib._getTokenIdCounter() - 1);
            }
            __s().reservedTokenIdCounter += 1;
        }
        __s().nrOfReservedTokens[account] += nrOfTokens;
        __s().totalNrOfReservedTokens += nrOfTokens;
    }

    function __s() private pure returns (ReserveManagerStorage.Layout storage) {
        return ReserveManagerStorage.layout();
    }
}

/*
 * This file is part of the Qomet Technologies contracts (https://github.com/qomet-tech/contracts).
 * Copyright (c) 2022 Qomet Technologies (https://qomet.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

import "./ERC721Internal.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
library ERC721Lib {

    function _setName(string memory name) internal {
        ERC721Internal._setName(name);
    }

    function _setSymbol(string memory symbol) internal {
        ERC721Internal._setSymbol(symbol);
    }

    function _exists(uint256 tokenId) internal view returns (bool) {
        return ERC721Internal._exists(tokenId);
    }

    function _ownerOf(uint256 tokenId) internal view returns (address) {
        return ERC721Internal._ownerOf(tokenId);
    }

    function _burn(uint256 tokenId) internal {
        ERC721Internal._burn(tokenId);
    }

    function _safeMint(address account, uint256 tokenId) internal {
        // TODO(kam): We don't have any safe mint in ERC721Internal
        ERC721Internal._mint(account, tokenId);
    }

    function _transfer(address from, address to, uint256 tokenId) internal {
        ERC721Internal._transfer(from, to, tokenId);
    }
}

/*
 * This file is part of the Qomet Technologies contracts (https://github.com/qomet-tech/contracts).
 * Copyright (c) 2022 Qomet Technologies (https://qomet.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

import "./MinterInternal.sol";

library MinterLib {

    function _justMintTo(
        address owner
    ) internal returns (uint256) {
        return MinterInternal._justMintTo(owner);
    }

    function _getTokenIdCounter() internal view returns (uint256) {
        return MinterInternal._getTokenIdCounter();
    }
}

/*
 * This file is part of the Qomet Technologies contracts (https://github.com/qomet-tech/contracts).
 * Copyright (c) 2022 Qomet Technologies (https://qomet.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

import "./WhitelistManagerInternal.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
library WhitelistManagerLib {

    function _getWhitelistEntry(address account) internal view returns (uint256) {
        return WhitelistManagerInternal._getWhitelistEntry(account);
    }
}

/*
 * This file is part of the Qomet Technologies contracts (https://github.com/qomet-tech/contracts).
 * Copyright (c) 2022 Qomet Technologies (https://qomet.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

import "./PaymentHandlerInternal.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
library PaymentHandlerLib {

    function _handlePayment(
        uint256 nrOfItems1, uint256 priceWeiPerItem1,
        uint256 nrOfItems2, uint256 priceWeiPerItem2,
        string memory paymentMethodName
    ) internal {
        PaymentHandlerInternal._handlePayment(
            nrOfItems1, priceWeiPerItem1,
            nrOfItems2, priceWeiPerItem2,
            paymentMethodName
        );
    }
}

/*
 * This file is part of the Qomet Technologies contracts (https://github.com/qomet-tech/contracts).
 * Copyright (c) 2022 Qomet Technologies (https://qomet.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk. Just got the basic
///         idea from: https://github.com/solidstate-network/solidstate-solidity
library ReserveManagerStorage {

    struct Layout {
        bool reservationAllowed;
        bool reservationAllowedWithoutWhitelisting;
        uint256 reservationFeeWei;
        uint256 reservePriceWeiPerToken;
        uint256 reservedTokenIdCounter;
        mapping(address => uint256) nrOfReservedTokens;
        uint256 totalNrOfReservedTokens;
        mapping(bytes32 => bytes) extra;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256("qomet-tech.contracts.facets.collection.reserve-manager.storage");

    function layout() internal pure returns (Layout storage s) {
        bytes32 slot = STORAGE_SLOT;
        /* solhint-disable no-inline-assembly */
        assembly {
            s.slot := slot
        }
        /* solhint-enable no-inline-assembly */
    }
}

/*
 * This file is part of the Qomet Technologies contracts (https://github.com/qomet-tech/contracts).
 * Copyright (c) 2022 Qomet Technologies (https://qomet.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

import "../token-store/TokenStoreLib.sol";
import "../minter/MinterLib.sol";
import "../reserve-manager/ReserveManagerLib.sol";
import "./ERC721Storage.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
library ERC721Internal {

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    function _setERC721Settings(
        string memory name_,
        string memory symbol_,
        bool reserveZeroToken
    ) internal {
        _setName(name_);
        _setSymbol(symbol_);
        if (reserveZeroToken && !_exists(0)) {
            MinterLib._justMintTo(address(this));
            ReserveManagerLib._initReserveManager();
        }
    }

    function _getName() internal view returns (string memory) {
        return __s().name;
    }

    function _setName(string memory name) internal {
        __s().name = name;
    }

    function _getSymbol() internal view returns (string memory) {
        return __s().symbol;
    }

    function _setSymbol(string memory symbol) internal {
        __s().symbol = symbol;
    }

    function _balanceOf(address owner) internal view returns (uint256) {
        require(owner != address(0), "ERC721I:ZA");
        return __s().balances[owner];
    }

    function _ownerOf(uint256 tokenId) internal view returns (address) {
        address owner = __s().owners[tokenId];
        require(owner != address(0), "ERC721I:NET");
        return owner;
    }

    function _exists(uint256 tokenId) internal view returns (bool) {
        return __s().owners[tokenId] != address(0);
    }

    function _mint(address to, uint256 tokenId) internal {
        require(to != address(0), "ERC721I:MZA");
        require(!_exists(tokenId), "ERC721I:TAM");
        __s().balances[to] += 1;
        __s().owners[tokenId] = to;
        emit Transfer(address(0), to, tokenId);
        TokenStoreLib._addToRelatedTokens(to, tokenId);
    }

    function _burn(uint256 tokenId) internal {
        address owner = _ownerOf(tokenId);
        // Clear approvals
        delete __s().tokenApprovals[tokenId];
        __s().balances[owner] -= 1;
        delete __s().owners[tokenId];
        emit Transfer(owner, address(0), tokenId);
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal {
        require(_ownerOf(tokenId) == from, "ERC721I:IO");
        require(to != address(0), "ERC721I:ZA");
        _unsafeTransfer(from, to, tokenId);
    }

    function _transferFromMe(
        address to,
        uint256 tokenId
    ) internal {
        require(_ownerOf(tokenId) == address(this), "ERC721I:IO");
        require(to != address(0), "ERC721I:ZA");
        _unsafeTransfer(address(this), to, tokenId);
    }

    function _unsafeTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal {
        // Clear approvals from the previous owner
        delete __s().tokenApprovals[tokenId];
        __s().balances[from] -= 1;
        __s().balances[to] += 1;
        __s().owners[tokenId] = to;
        emit Transfer(from, to, tokenId);
        TokenStoreLib._addToRelatedTokens(to, tokenId);
    }

    function _getApproved(uint256 tokenId) internal view returns (address) {
        require(_ownerOf(tokenId) != address(0), "ERC721I:NET");
        return __s().tokenApprovals[tokenId];
    }

    function _isApprovedForAll(address owner, address operator) internal view returns (bool) {
        return __s().operatorApprovals[owner][operator];
    }

    function _isApprovedOrOwner(
        address spender,
        uint256 tokenId
    ) internal view returns (bool) {
        address owner = _ownerOf(tokenId);
        return (
            spender == owner ||
            __s().operatorApprovals[owner][spender] ||
            __s().tokenApprovals[tokenId] == spender
        );
    }

    function _approve(address to, uint256 tokenId) internal {
        __s().tokenApprovals[tokenId] = to;
        emit Approval(_ownerOf(tokenId), to, tokenId);
    }

    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal {
        require(owner != operator, "ERC721I:ATC");
        __s().operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    function __s() private pure returns (ERC721Storage.Layout storage) {
        return ERC721Storage.layout();
    }
}

/*
 * This file is part of the Qomet Technologies contracts (https://github.com/qomet-tech/contracts).
 * Copyright (c) 2022 Qomet Technologies (https://qomet.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

import "./TokenStoreInternal.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
library TokenStoreLib {

    function _getTokenURI(uint256 tokenId)
      internal view returns (string memory) {
        return TokenStoreInternal._getTokenURI(tokenId);
    }

    function _setTokenURI(
        uint256 tokenId,
        string memory tokenURI_
    ) internal {
        TokenStoreInternal._setTokenURI(tokenId, tokenURI_);
    }

    function _setTokenData(uint256 tokenId, string memory data) internal {
        TokenStoreInternal._setTokenData(tokenId, data);
    }

    function _addToRelatedTokens(address account, uint256 tokenId) internal {
        TokenStoreInternal._addToRelatedTokens(account, tokenId);
    }

    function _deleteTokenInfo(
        uint256 tokenId
    ) internal {
        TokenStoreInternal._deleteTokenInfo(tokenId);
    }
}

/*
 * This file is part of the Qomet Technologies contracts (https://github.com/qomet-tech/contracts).
 * Copyright (c) 2022 Qomet Technologies (https://qomet.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk. Just got the basic
///         idea from: https://github.com/solidstate-network/solidstate-solidity
library ERC721Storage {

    // Members are copied from:
    //   https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/ERC721.sol
    struct Layout {
        // Token name
        string name;
        // Token symbol
        string symbol;
        // Mapping from token ID to owner address
        mapping(uint256 => address) owners;
        // Mapping owner address to token count
        mapping(address => uint256) balances;
        // Mapping from token ID to approved address
        mapping(uint256 => address) tokenApprovals;
        // Mapping from owner to operator approvals
        mapping(address => mapping(address => bool)) operatorApprovals;
        mapping(bytes32 => bytes) extra;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256("qomet-tech.contracts.facets.collection.erc721.storage");

    function layout() internal pure returns (Layout storage s) {
        bytes32 slot = STORAGE_SLOT;
        /* solhint-disable no-inline-assembly */
        assembly {
            s.slot := slot
        }
        /* solhint-enable no-inline-assembly */
    }
}

/*
 * This file is part of the Qomet Technologies contracts (https://github.com/qomet-tech/contracts).
 * Copyright (c) 2022 Qomet Technologies (https://qomet.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

import "@openzeppelin/contracts/utils/Strings.sol";
import "../erc721/ERC721Lib.sol";
import "./TokenStoreStorage.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
library TokenStoreInternal {

    event TokenURIChange(uint256 tokenId, string tokenURI);
    event TokenDataChange(uint256 tokenId, string data);

    function _getTokenStoreSettings()
    internal view returns (
        string memory,
        string memory,
        bool,
        string memory,
        string memory
    ) {
        return (
            __s().baseTokenURI,
            __s().defaultTokenURI,
            __s().useIdempotentTokenURIs,
            __s().idempotentTokenURIBase,
            __s().idempotentTokenURIExtension
        );
    }

    function _setTokenStoreSettings(
        string memory baseTokenURI,
        string memory defaultTokenURI,
        bool useIdempotentTokenURIs,
        string memory idempotentTokenURIBase,
        string memory idempotentTokenURIExtension
    ) internal {
        __s().baseTokenURI = baseTokenURI;
        __s().defaultTokenURI = defaultTokenURI;
        __s().useIdempotentTokenURIs = useIdempotentTokenURIs;
        __s().idempotentTokenURIBase = idempotentTokenURIBase;
        __s().idempotentTokenURIExtension = idempotentTokenURIExtension;
    }

    function _getTokenURI(uint256 tokenId)
      internal view returns (string memory) {
        require(ERC721Lib._exists(tokenId), "TSI:NET");
        if (__s().useIdempotentTokenURIs) {
            return string(
                abi.encodePacked(
                    __s().idempotentTokenURIBase,
                    Strings.toString(tokenId),
                    __s().idempotentTokenURIExtension
                )
            );
        }
        string memory vTokenURI = __s().tokenInfos[tokenId].uri;
        if (bytes(vTokenURI).length == 0) {
            return __s().defaultTokenURI;
        }
        if (bytes(__s().baseTokenURI).length == 0) {
            return vTokenURI;
        }
        return string(abi.encodePacked(__s().baseTokenURI, vTokenURI));
    }

    function _setTokenURI(
        uint256 tokenId,
        string memory tokenURI_
    ) internal {
        require(ERC721Lib._exists(tokenId), "TSI:NET");
        __s().tokenInfos[tokenId].uri = tokenURI_;
        emit TokenURIChange(tokenId, tokenURI_);
        // WARN: This will override the previous token if the same
        //       uri is being used twice.
        __s().tokenIndex[keccak256(bytes(tokenURI_))] = tokenId;
    }

    function _getTokenData(uint256 tokenId)
      internal view returns (string memory) {
        require(ERC721Lib._exists(tokenId), "TSI:NET");
        return __s().tokenInfos[tokenId].data;
    }

    function _setTokenData(
        uint256 tokenId,
        string memory data
    ) internal {
        require(ERC721Lib._exists(tokenId), "TSF:NET");
        __s().tokenInfos[tokenId].data = data;
        emit TokenDataChange(tokenId, data);
        // WARN: This will override the previous token if the same
        //       data is being used twice.
        __s().tokenIndex[keccak256(bytes(data))] = tokenId;
    }

    function _updateTokens(
        uint256[] memory tokenIds,
        string[] memory uris,
        string[] memory datas
    ) internal {
        require(tokenIds.length > 0, "M:NTU");
        require(tokenIds.length == uris.length, "M:IL");
        require(tokenIds.length == datas.length, "M:IL2");
        for (uint256 i = 0; i < uris.length; i++) {
            _setTokenURI(tokenIds[i], uris[i]);
            _setTokenData(tokenIds[i], datas[i]);
        }
    }

    function _getRelatedTokens(address account) internal view returns (uint256[] memory) {
        return __s().relatedTokens[account];
    }

    function _addToRelatedTokens(address account, uint256 tokenId) internal {
        __s().relatedTokens[account].push(tokenId);
    }

    function _ownedTokens(address account)
      internal view returns (uint256[] memory) {
        uint256 length = 0;
        if (account != address(0)) {
            for (uint256 i = 0; i < _getRelatedTokens(account).length; i++) {
                uint256 tokenId = _getRelatedTokens(account)[i];
                if (ERC721Lib._exists(tokenId) && ERC721Lib._ownerOf(tokenId) == account) {
                    length += 1;
                }
            }
        }
        uint256[] memory tokens = new uint256[](length);
        if (account != address(0)) {
            uint256 index = 0;
            for (uint256 i = 0; i < _getRelatedTokens(account).length; i++) {
                uint256 tokenId = _getRelatedTokens(account)[i];
                if (ERC721Lib._exists(tokenId) && ERC721Lib._ownerOf(tokenId) == account) {
                    tokens[index] = tokenId;
                    index += 1;
                }
            }
        }
        return tokens;
    }

    function _deleteTokenInfo(
        uint256 tokenId
    ) internal {
        if (bytes(__s().tokenInfos[tokenId].uri).length != 0) {
            delete __s().tokenInfos[tokenId];
        }
    }

    function _findToken(string memory evidence) internal view returns (uint256) {
        return __s().tokenIndex[keccak256(bytes(evidence))];
    }

    function __s() private pure returns (TokenStoreStorage.Layout storage) {
        return TokenStoreStorage.layout();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

/*
 * This file is part of the Qomet Technologies contracts (https://github.com/qomet-tech/contracts).
 * Copyright (c) 2022 Qomet Technologies (https://qomet.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk. Just got the basic
///         idea from: https://github.com/solidstate-network/solidstate-solidity
library TokenStoreStorage {

    struct TokenInfo {
        string uri;
        string data;
    }

    struct Layout {
        string baseTokenURI;
        string defaultTokenURI;

        bool useIdempotentTokenURIs;
        string idempotentTokenURIBase;
        string idempotentTokenURIExtension;

        mapping(uint256 => TokenInfo) tokenInfos;
        mapping(address => uint256[]) relatedTokens;
        // Mapping from hash(uri) and hash(data) to token ID
        mapping(bytes32 => uint256) tokenIndex;

        mapping(bytes32 => bytes) extra;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256("qomet-tech.contracts.facets.collection.token-store.storage");

    function layout() internal pure returns (Layout storage s) {
        bytes32 slot = STORAGE_SLOT;
        /* solhint-disable no-inline-assembly */
        assembly {
            s.slot := slot
        }
        /* solhint-enable no-inline-assembly */
    }
}

/*
 * This file is part of the Qomet Technologies contracts (https://github.com/qomet-tech/contracts).
 * Copyright (c) 2022 Qomet Technologies (https://qomet.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

import "../token-store/TokenStoreLib.sol";
import "../royalty-manager/RoyaltyManagerLib.sol";
import "../payment-handler/PaymentHandlerLib.sol";
import "./MinterStorage.sol";

library MinterInternal {

    event PreMint(uint256 nrOfTokens);

    function _getMintSettings()
      internal view returns (bool, bool, uint256, uint256, uint256, uint256, uint256) {
        return (
            __s().publicMinting,
            __s().directMintingAllowed,
            __s().mintFeeWei,
            __s().mintPriceWeiPerToken,
            __s().maxTokenId,
            __s().nrOfMints,
            __s().nrOfBurns
        );
    }

    function _setMintSettings(
        bool publicMinting,
        bool directMintingAllowed,
        uint256 mintFeeWei,
        uint256 mintPriceWeiPerToken,
        uint256 maxTokenId
    ) internal {
        __s().publicMinting = publicMinting;
        __s().directMintingAllowed = directMintingAllowed;
        __s().mintFeeWei = mintFeeWei;
        __s().mintPriceWeiPerToken = mintPriceWeiPerToken;
        __s().maxTokenId = maxTokenId;
    }

    function _burn(uint256 tokenId) internal {
        ERC721Lib._burn(tokenId);
        TokenStoreLib._deleteTokenInfo(tokenId);
        __s().nrOfBurns += 1;
    }

    function _getTokenIdCounter() internal view returns (uint256) {
        return __s().tokenIdCounter;
    }

    function _justMintTo(
        address owner
    ) internal returns (uint256) {
        uint256 tokenId = __s().tokenIdCounter;
        require(__s().maxTokenId == 0 ||
                tokenId <= __s().maxTokenId, "MI:MAX");
        __s().tokenIdCounter += 1;
        if (owner == address(this)) {
            ERC721Lib._safeMint(msg.sender, tokenId);
            ERC721Lib._transfer(msg.sender, address(this), tokenId);
        } else {
            ERC721Lib._safeMint(address(this), tokenId);
            ERC721Lib._transfer(address(this), owner, tokenId);
        }
        __s().nrOfMints += 1;
        return tokenId;
    }

    function _preMint(uint256 nrOfTokens) internal {
        require(nrOfTokens > 0, "MI:ZT");
        for (uint256 i = 1; i <= nrOfTokens; i++) {
            _justMintTo(address(this));
        }
        emit PreMint(nrOfTokens);
    }

    function _mint(
        address[] memory owners,
        string[] memory uris,
        string[] memory datas,
        address[] memory royaltyWallets,
        uint256[] memory royaltyPercentages,
        bool handlePayment,
        string memory paymentMethodName
    ) internal {
        require(__s().directMintingAllowed, "MI:DMNA");
        require(uris.length > 0, "MI:NTM");
        require(datas.length == 0 ||
                uris.length == datas.length, "MI:IL");
        require(royaltyWallets.length == 0 ||
                uris.length == royaltyWallets.length, "MI:IL2");
        require(royaltyPercentages.length == 0 ||
                uris.length == royaltyPercentages.length, "MI:IL3");
        require(uris.length == owners.length, "MI:IL4");
        if (handlePayment) {
            PaymentHandlerLib._handlePayment(
                1, __s().mintFeeWei,
                uris.length, __s().mintPriceWeiPerToken,
                paymentMethodName
            );
        }
        for (uint256 i = 0; i < uris.length; i++) {
            uint256 tokenId = __mintTo(owners[i], uris[i]);
            // Both royalty wallet and percentage must have sane values otherwise
            // the operator can always call other methods to set them.
            if (
                royaltyWallets.length > 0 &&
                royaltyPercentages.length > 0 &&
                royaltyWallets[i] != address(0) &&
                royaltyPercentages[i] > 0
            ) {
                RoyaltyManagerLib._setTokenRoyaltyInfo(
                    tokenId, royaltyWallets[i], royaltyPercentages[i]);
            }
            if (datas.length > 0) {
                TokenStoreLib._setTokenData(tokenId, datas[i]);
            }
        }
    }

    function __mintTo(
        address owner,
        string memory uri
    ) private returns (uint256) {
        uint256 tokenId = _justMintTo(owner);
        TokenStoreLib._setTokenURI(tokenId, uri);
        return tokenId;
    }

    function __s() private pure returns (MinterStorage.Layout storage) {
        return MinterStorage.layout();
    }
}

/*
 * This file is part of the Qomet Technologies contracts (https://github.com/qomet-tech/contracts).
 * Copyright (c) 2022 Qomet Technologies (https://qomet.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

import "./RoyaltyManagerInternal.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
library RoyaltyManagerLib {

    function _setTokenRoyaltyInfo(
        uint256 tokenId,
        address royaltyWallet,
        uint256 royaltyPercentage
    ) internal {
        RoyaltyManagerInternal._setTokenRoyaltyInfo(
            tokenId,
            royaltyWallet,
            royaltyPercentage
        );
    }
}

/*
 * This file is part of the Qomet Technologies contracts (https://github.com/qomet-tech/contracts).
 * Copyright (c) 2022 Qomet Technologies (https://qomet.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk. Just got the basic
///         idea from: https://github.com/solidstate-network/solidstate-solidity
library MinterStorage {

    struct Layout {
        uint256 tokenIdCounter;
        bool publicMinting;
        bool directMintingAllowed;
        uint256 mintFeeWei;
        uint256 mintPriceWeiPerToken;
        uint256 maxTokenId;
        uint256 nrOfMints;
        uint256 nrOfBurns;
        mapping(bytes32 => bytes) extra;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256("qomet-tech.contracts.facets.collection.minter.storage");

    function layout() internal pure returns (Layout storage s) {
        bytes32 slot = STORAGE_SLOT;
        /* solhint-disable no-inline-assembly */
        assembly {
            s.slot := slot
        }
        /* solhint-enable no-inline-assembly */
    }
}

/*
 * This file is part of the Qomet Technologies contracts (https://github.com/qomet-tech/contracts).
 * Copyright (c) 2022 Qomet Technologies (https://qomet.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

import "../erc721/ERC721Lib.sol";
import "./RoyaltyManagerStorage.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
library RoyaltyManagerInternal {

    event TokenRoyaltyInfoChanged(
        uint256 tokenId,
        address royaltyWallet,
        uint256 royaltyPercentage
    );
    event TokenRoyaltyExempt(
        uint256 tokenId,
        bool exempt
    );

    function _getDefaultRoyaltySettings() internal view returns (address, uint256) {
        return (__s().defaultRoyaltyWallet, __s().defaultRoyaltyPercentage);
    }

    // Either set address to zero or set percentage to zero to disable
    // default royalties. Still, royalties set per token work.
    function _setDefaultRoyaltySettings(
        address newDefaultRoyaltyWallet,
        uint256 newDefaultRoyaltyPercentage
    ) internal {
        __s().defaultRoyaltyWallet = newDefaultRoyaltyWallet;
        require(
            newDefaultRoyaltyPercentage >= 0 &&
            newDefaultRoyaltyPercentage <= 100,
            "ROMI:WP"
        );
        __s().defaultRoyaltyPercentage = newDefaultRoyaltyPercentage;
    }

    function _getTokenRoyaltyInfo(uint256 tokenId)
      internal view returns (address, uint256, bool) {
        require(ERC721Lib._exists(tokenId), "ROMI:NET");
        return (
            __s().tokenRoyalties[tokenId].royaltyWallet,
            __s().tokenRoyalties[tokenId].royaltyPercentage,
            __s().tokenRoyalties[tokenId].exempt
        );
    }

    function _setTokenRoyaltyInfo(
        uint256 tokenId,
        address royaltyWallet,
        uint256 royaltyPercentage
    ) internal {
        require(ERC721Lib._exists(tokenId), "ROMI:NET");
        require(royaltyPercentage >= 0 && royaltyPercentage <= 100, "ROMI:WP");
        __s().tokenRoyalties[tokenId].royaltyWallet = royaltyWallet;
        __s().tokenRoyalties[tokenId].royaltyPercentage = royaltyPercentage;
        __s().tokenRoyalties[tokenId].exempt = false;
        emit TokenRoyaltyInfoChanged(tokenId, royaltyWallet, royaltyPercentage);
    }

    function _exemptTokenRoyalty(uint256 tokenId, bool exempt) internal {
        require(ERC721Lib._exists(tokenId), "ROMI:NET");
        __s().tokenRoyalties[tokenId].exempt = exempt;
        emit TokenRoyaltyExempt(tokenId, exempt);
    }

    function _getRoyaltyInfo(
        uint256 tokenId,
        uint256 salePrice
    ) internal view returns (address, uint256) {
        require(ERC721Lib._exists(tokenId), "ROMI:NET");
        RoyaltyManagerStorage.TokenRoyaltyInfo memory tokenRoyaltyInfo =
            __s().tokenRoyalties[tokenId];
        if (tokenRoyaltyInfo.exempt) {
            return (address(0), 0);
        }
        address royaltyWallet = tokenRoyaltyInfo.royaltyWallet;
        uint256 royaltyPercentage = tokenRoyaltyInfo.royaltyPercentage;
        if (royaltyWallet == address(0) || royaltyPercentage == 0) {
            royaltyWallet = __s().defaultRoyaltyWallet;
            royaltyPercentage = __s().defaultRoyaltyPercentage;
        }
        if (royaltyWallet == address(0) || royaltyPercentage == 0) {
            return (address(0), 0);
        }
        uint256 royalty = (salePrice * royaltyPercentage) / 100;
        return (royaltyWallet, royalty);
    }

    function __s() private pure returns (RoyaltyManagerStorage.Layout storage) {
        return RoyaltyManagerStorage.layout();
    }
}

/*
 * This file is part of the Qomet Technologies contracts (https://github.com/qomet-tech/contracts).
 * Copyright (c) 2022 Qomet Technologies (https://qomet.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk. Just got the basic
///         idea from: https://github.com/solidstate-network/solidstate-solidity
library RoyaltyManagerStorage {

    struct TokenRoyaltyInfo {
        address royaltyWallet;
        uint256 royaltyPercentage;
        bool exempt;
    }

    struct Layout {
        address defaultRoyaltyWallet;
        uint256 defaultRoyaltyPercentage;
        mapping(uint256 => TokenRoyaltyInfo) tokenRoyalties;
        mapping(bytes32 => bytes) extra;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256("qomet-tech.contracts.facets.collection.royalty-manager.storage");

    function layout() internal pure returns (Layout storage s) {
        bytes32 slot = STORAGE_SLOT;
        /* solhint-disable no-inline-assembly */
        assembly {
            s.slot := slot
        }
        /* solhint-enable no-inline-assembly */
    }
}

/*
 * This file is part of the Qomet Technologies contracts (https://github.com/qomet-tech/contracts).
 * Copyright (c) 2022 Qomet Technologies (https://qomet.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "../../IUniswapV2Pair.sol";
import "../payment-method-manager/PaymentMethodManagerLib.sol";
import "./PaymentHandlerStorage.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
library PaymentHandlerInternal {

    bytes32 constant public WEI_PAYMENT_METHOD_HASH = keccak256(abi.encode("WEI"));

    event TransferTo(
        address to,
        uint256 amount,
        string data
    );
    event TransferETH20To(
        string paymentMethodName,
        address to,
        uint256 amount,
        string data
    );

    function _getPaymentHandlerSettings() internal view returns (address) {
        return __s().payoutAddress;
    }

    function _setPaymentHandlerSettings(
        address payoutAddress
    ) internal {
        __s().payoutAddress = payoutAddress;
    }

    function _transferTo(
        string memory paymentMethodName,
        address to,
        uint256 amount,
        string memory data
    ) internal {
        require(to != address(0), "PH:TTZ");
        require(amount > 0, "PH:ZAM");
        bytes32 nameHash = keccak256(abi.encode(paymentMethodName));
        require(nameHash == WEI_PAYMENT_METHOD_HASH ||
                PaymentMethodManagerLib._paymentMethodExists(nameHash), "PH:MNS");
        if (nameHash == WEI_PAYMENT_METHOD_HASH) {
            require(amount <= address(this).balance, "PH:MTB");
            /* solhint-disable avoid-low-level-calls */
            (bool success, ) = to.call{value: amount}(new bytes(0));
            /* solhint-enable avoid-low-level-calls */
            require(success, "PH:TF");
            emit TransferTo(to, amount, data);
        } else {
            address erc20 =
                PaymentMethodManagerLib._getERC20PaymentMethodAddress(nameHash);
            require(amount <= IERC20(erc20).balanceOf(address(this)), "PH:MTB");
            IERC20(erc20).transfer(to, amount);
            emit TransferETH20To(paymentMethodName, to, amount, data);
        }
    }

    function _handlePayment(
        uint256 nrOfItems1, uint256 priceWeiPerItem1,
        uint256 nrOfItems2, uint256 priceWeiPerItem2,
        string memory paymentMethodName
    ) internal {
        uint256 totalWei =
            nrOfItems1 * priceWeiPerItem1 +
            nrOfItems2 * priceWeiPerItem2;
        if (totalWei == 0) {
            return;
        }
        bytes32 nameHash = keccak256(abi.encode(paymentMethodName));
        require(nameHash == WEI_PAYMENT_METHOD_HASH ||
                PaymentMethodManagerLib._paymentMethodExists(nameHash), "PH:MNS");
        if (nameHash == WEI_PAYMENT_METHOD_HASH) {
            PaymentMethodManagerLib._handleWeiPayment(
                msg.sender, __s().payoutAddress, msg.value, totalWei, "");
        } else {
            PaymentMethodManagerLib.
                _handleERC20Payment(
                    paymentMethodName, msg.sender, __s().payoutAddress, totalWei, "");
        }
    }

    function __s() private pure returns (PaymentHandlerStorage.Layout storage) {
        return PaymentHandlerStorage.layout();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

/*
 * This file is part of the Qomet Technologies contracts (https://github.com/qomet-tech/contracts).
 * Copyright (c) 2022 Qomet Technologies (https://qomet.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

/*
 * This file is part of the Qomet Technologies contracts (https://github.com/qomet-tech/contracts).
 * Copyright (c) 2022 Qomet Technologies (https://qomet.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

import "./PaymentMethodManagerInternal.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
library PaymentMethodManagerLib {

    function _handleWeiPayment(
        address payer,
        address dest,
        uint256 paidPriceWei, // could be the msg.value
        uint256 priceWeiToPay,
        string memory data
    ) internal {
        PaymentMethodManagerInternal._handleWeiPayment(
            payer,
            dest,
            paidPriceWei,
            priceWeiToPay,
            data
        );
    }

    function _handleERC20Payment(
        string memory paymentMethodName,
        address payer,
        address dest,
        uint256 priceWeiToPay,
        string memory data
    ) internal {
        PaymentMethodManagerInternal._handleERC20Payment(
            paymentMethodName,
            payer,
            dest,
            priceWeiToPay,
            data
        );
    }

    function _paymentMethodExists(
        bytes32 paymentMethodNameHash
    ) internal view returns (bool) {
        return PaymentMethodManagerLib._paymentMethodExists(paymentMethodNameHash);
    }

    function _paymentMethodEnabled(
        bytes32 paymentMethodNameHash
    ) internal view returns (bool) {
        return PaymentMethodManagerLib._paymentMethodEnabled(paymentMethodNameHash);
    }

    function _getERC20PaymentMethodAddress(
        bytes32 paymentMethodNameHash
    ) internal view returns (address) {
        return PaymentMethodManagerLib._getERC20PaymentMethodAddress(paymentMethodNameHash);
    }
}

/*
 * This file is part of the Qomet Technologies contracts (https://github.com/qomet-tech/contracts).
 * Copyright (c) 2022 Qomet Technologies (https://qomet.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk. Just got the basic
///         idea from: https://github.com/solidstate-network/solidstate-solidity
library PaymentHandlerStorage {

    struct Layout {
        address payoutAddress;
        mapping(bytes32 => bytes) extra;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256("qomet-tech.contracts.facets.collection.payment-handler.storage");

    function layout() internal pure returns (Layout storage s) {
        bytes32 slot = STORAGE_SLOT;
        /* solhint-disable no-inline-assembly */
        assembly {
            s.slot := slot
        }
        /* solhint-enable no-inline-assembly */
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/*
 * This file is part of the Qomet Technologies contracts (https://github.com/qomet-tech/contracts).
 * Copyright (c) 2022 Qomet Technologies (https://qomet.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "../../IUniswapV2Pair.sol";
import "./PaymentMethodManagerStorage.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
library PaymentMethodManagerInternal {

    event ERC20PaymentMethodUpdate(
        string paymentMethodName,
        address erc20,
        address wethPair,
        bool enabled,
        string data
    );
    event WeiPayment(
        address payer,
        address dest,
        uint256 paidPriceWei,
        uint256 priceWeiToPay,
        string data
    );
    event ERC20Payment(
        string paymentMethodName,
        address payer,
        address dest,
        uint256 amountWei,
        uint256 amountTokens,
        string data
    );

    function _getPaymentMethodManagerSettings() internal view returns (address) {
        return __s().wethAddress;
    }

    function _setPaymentMethodManagerSettings(
        address wethAddress
    ) internal {
        __s().wethAddress = wethAddress;
    }

    function _getERC20PaymentMethods() internal view returns (string[] memory) {
        return __s().erc20PaymentMethodNames;
    }

    function _getERC20PaymentMethod(
        string memory paymentMethodName
    ) internal view returns (address, address, bool) {
        bytes32 nameHash = keccak256(abi.encode(paymentMethodName));
        require(_paymentMethodExists(nameHash), "PMM:NEM");
        return (
            __s().erc20PaymentMethods[nameHash].erc20,
            __s().erc20PaymentMethods[nameHash].wethPair,
            __s().erc20PaymentMethods[nameHash].enabled
        );
    }

    function _addOrUpdateERC20PaymentMethod(
        string memory paymentMethodName,
        address erc20,
        address wethPair,
        bool enabled,
        string memory data
    ) internal {
        bytes32 nameHash = keccak256(abi.encode(paymentMethodName));
        __s().erc20PaymentMethods[nameHash].erc20 = erc20;
        __s().erc20PaymentMethods[nameHash].wethPair = wethPair;
        __s().erc20PaymentMethods[nameHash].enabled = enabled;
        address token0 = IUniswapV2Pair(wethPair).token0();
        address token1 = IUniswapV2Pair(wethPair).token1();
        require(token0 == __s().wethAddress || token1 == __s().wethAddress, "PMM:IPC");
        bool reverseIndices = (token1 == __s().wethAddress);
        __s().erc20PaymentMethods[nameHash].reverseIndices = reverseIndices;
        if (__s().erc20PaymentMethodNamesIndex[paymentMethodName] == 0) {
            __s().erc20PaymentMethodNames.push(paymentMethodName);
            __s().erc20PaymentMethodNamesIndex[paymentMethodName] =
                __s().erc20PaymentMethodNames.length;
        }
        emit ERC20PaymentMethodUpdate(
            paymentMethodName, erc20, wethPair, enabled, data);
    }

    function _enableERC20TokenPayment(
        string memory paymentMethodName,
        bool enabled
    ) internal {
        bytes32 nameHash = keccak256(abi.encode(paymentMethodName));
        require(_paymentMethodExists(nameHash), "PMM:NEM");
        __s().erc20PaymentMethods[nameHash].enabled = enabled;
        emit ERC20PaymentMethodUpdate(
            paymentMethodName,
            __s().erc20PaymentMethods[nameHash].erc20,
            __s().erc20PaymentMethods[nameHash].wethPair,
            enabled,
            ""
        );
    }

    function _handleWeiPayment(
        address payer,
        address dest,
        uint256 paidPriceWei, // could be the msg.value
        uint256 priceWeiToPay,
        string memory data
    ) internal {
        require(paidPriceWei >= priceWeiToPay, "PMM:IF");
        uint256 remainder = paidPriceWei - priceWeiToPay;
        if (dest != address(0)) {
            /* solhint-disable avoid-low-level-calls */
            (bool success, ) = dest.call{value: priceWeiToPay}(new bytes(0));
            /* solhint-enable avoid-low-level-calls */
            require(success, "PMM:TF");
            emit WeiPayment(payer, dest, paidPriceWei, priceWeiToPay, data);
        } else {
            emit WeiPayment(
                payer, address(this), paidPriceWei, priceWeiToPay, data);
        }
        if (remainder > 0) {
            /* solhint-disable avoid-low-level-calls */
            (bool success, ) = payer.call{value: remainder}(new bytes(0));
            /* solhint-enable avoid-low-level-calls */
            require(success, "PMM:RTF");
        }
    }

    function _handleERC20Payment(
        string memory paymentMethodName,
        address payer,
        address dest,
        uint256 priceWeiToPay,
        string memory data
    ) internal {
        bytes32 nameHash = keccak256(abi.encode(paymentMethodName));
        require(_paymentMethodExists(nameHash), "PMM:NEM");
        require(_paymentMethodEnabled(nameHash), "PMM:NENM");
        PaymentMethodManagerStorage.ERC20PaymentMethod memory paymentMethod =
            __s().erc20PaymentMethods[nameHash];
        (uint112 amount0, uint112 amount1,) = IUniswapV2Pair(paymentMethod.wethPair).getReserves();
        uint256 reserveWei = amount0;
        uint256 reserveTokens = amount1;
        if (paymentMethod.reverseIndices) {
            reserveWei = amount1;
            reserveTokens = amount0;
        }
        require(reserveWei > 0, "PMM:NWR");
        // TODO(kam): check if this is OK
        uint256 amountTokens = (priceWeiToPay * reserveTokens) / reserveWei;
        if (dest == address(0)) {
            dest = address(this);
        }
        // this contract must have already been approved by the msg.sender
        IERC20(paymentMethod.erc20).transferFrom(payer, dest, amountTokens);
        emit ERC20Payment(
            paymentMethodName, payer, dest, priceWeiToPay, amountTokens, data);
    }

    function _paymentMethodExists(
        bytes32 paymentMethodNameHash
    ) internal view returns (bool) {
        return __s().erc20PaymentMethods[paymentMethodNameHash].erc20 != address(0) &&
               __s().erc20PaymentMethods[paymentMethodNameHash].wethPair != address(0);
    }

    function _paymentMethodEnabled(
        bytes32 paymentMethodNameHash
    ) internal view returns (bool) {
        return __s().erc20PaymentMethods[paymentMethodNameHash].enabled;
    }

    function _getERC20PaymentMethodAddress(
        bytes32 paymentMethodNameHash
    ) internal view returns (address) {
        require(_paymentMethodExists(paymentMethodNameHash), "PMM:NEM");
        return __s().erc20PaymentMethods[paymentMethodNameHash].erc20;
    }

    function __s() private pure returns (PaymentMethodManagerStorage.Layout storage) {
        return PaymentMethodManagerStorage.layout();
    }
}

/*
 * This file is part of the Qomet Technologies contracts (https://github.com/qomet-tech/contracts).
 * Copyright (c) 2022 Qomet Technologies (https://qomet.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk. Just got the basic
///         idea from: https://github.com/solidstate-network/solidstate-solidity
library PaymentMethodManagerStorage {

    struct ERC20PaymentMethod {
        // The internal unique name of the ERC-20 payment method
        string name;
        // The ERC-20 contract
        address erc20;
        // Uniswap V2 Pair with WETH
        address wethPair;
        // True if the read pair from Uniswap has a reverse ordering
        // for contract addresses
        bool reverseIndices;
        // If the payment method is enabled
        bool enabled;
    }

    struct Layout {
        // The WETH ERC-20 contract address.
        //   On mainnet, it is: 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2
        address wethAddress;
        // The list of the existing ERC20 payment method names
        string[] erc20PaymentMethodNames;
        mapping(string => uint256)  erc20PaymentMethodNamesIndex;
        // name > erc20 payment method
        mapping(bytes32 => ERC20PaymentMethod) erc20PaymentMethods;
        // Reserved for future upgrades
        mapping(bytes32 => bytes) extra;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256("qomet-tech.contracts.facets.collection.payment-method-manager.storage");

    function layout() internal pure returns (Layout storage s) {
        bytes32 slot = STORAGE_SLOT;
        /* solhint-disable no-inline-assembly */
        assembly {
            s.slot := slot
        }
        /* solhint-enable no-inline-assembly */
    }
}

/*
 * This file is part of the Qomet Technologies contracts (https://github.com/qomet-tech/contracts).
 * Copyright (c) 2022 Qomet Technologies (https://qomet.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

import "../payment-handler/PaymentHandlerLib.sol";
import "./WhitelistManagerStorage.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
library WhitelistManagerInternal {

    event Whitelist(address account, uint256 nrOfTokens);

    function _getWhitelistingSettings()
      internal view returns (bool, uint256, uint256, uint256, uint256) {
        return (
            __s().whitelistingAllowed,
            __s().whitelistingFeeWei,
            __s().whitelistingPriceWeiPerToken,
            __s().maxNrOfWhitelistedTokensPerAccount,
            __s().totalNrOfWhitelists
        );
    }

    function _setWhitelistingSettings(
        bool whitelistingAllowed,
        uint256 whitelistingFeeWei,
        uint256 whitelistingPriceWeiPerToken,
        uint256 maxNrOfWhitelistedTokensPerAccount
    ) internal {
        __s().whitelistingAllowed = whitelistingAllowed;
        __s().whitelistingFeeWei = whitelistingFeeWei;
        __s().whitelistingPriceWeiPerToken = whitelistingPriceWeiPerToken;
        __s().maxNrOfWhitelistedTokensPerAccount = maxNrOfWhitelistedTokensPerAccount;
    }

    // NOTE: Send 0 for nrOfTokens to de-list the address
    function _whitelistAccount(
        address account,
        uint256 nrOfTokens,
        string memory paymentMethodName
    ) internal {
        require(__s().whitelistingAllowed, "WM:NA");
        PaymentHandlerLib._handlePayment(
            1, __s().whitelistingFeeWei,
            nrOfTokens, __s().whitelistingPriceWeiPerToken,
            paymentMethodName
        );
        _whitelist(account, nrOfTokens);
    }

    // NOTE: Send 0 for nrOfTokens to de-list an address
    // NOTE: This is always allowed
    function _whitelistAccounts(
        address[] memory accounts,
        uint256[] memory nrOfTokensArray
    ) internal {
        require(accounts.length == nrOfTokensArray.length, "WM:IL");
        for (uint256 i = 0; i < accounts.length; i++) {
            _whitelist(accounts[i], nrOfTokensArray[i]);
        }
    }

    function _getWhitelistEntry(address account) internal view returns (uint256) {
        return __s().whitelistEntries[account];
    }

    function _whitelist(
        address account,
        uint256 nrOfTokens
    ) private {
        require(__s().maxNrOfWhitelistedTokensPerAccount == 0 ||
                nrOfTokens <= __s().maxNrOfWhitelistedTokensPerAccount,
                "WM:EMAX");
        if (nrOfTokens == 0){
            // de-list the account
            uint256 nrOfTokensToBeRemoved = __s().whitelistEntries[account];
            __s().whitelistEntries[account] = 0;
            __s().totalNrOfWhitelists -= nrOfTokensToBeRemoved;
        }
        else{
            __s().whitelistEntries[account] = nrOfTokens;
            __s().totalNrOfWhitelists += nrOfTokens;
        }
        emit Whitelist(account, nrOfTokens);
    }

    function __s() private pure returns (WhitelistManagerStorage.Layout storage) {
        return WhitelistManagerStorage.layout();
    }
}

/*
 * This file is part of the Qomet Technologies contracts (https://github.com/qomet-tech/contracts).
 * Copyright (c) 2022 Qomet Technologies (https://qomet.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk. Just got the basic
///         idea from: https://github.com/solidstate-network/solidstate-solidity
library WhitelistManagerStorage {

    struct Layout {
        bool whitelistingAllowed;
        uint256 whitelistingFeeWei;
        uint256 whitelistingPriceWeiPerToken;
        uint256 maxNrOfWhitelistedTokensPerAccount;
        mapping(address => uint256) whitelistEntries;
        uint256 totalNrOfWhitelists;
        mapping(bytes32 => bytes) extra;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256("qomet-tech.contracts.facets.collection.whitelist-manager.storage");

    function layout() internal pure returns (Layout storage s) {
        bytes32 slot = STORAGE_SLOT;
        /* solhint-disable no-inline-assembly */
        assembly {
            s.slot := slot
        }
        /* solhint-enable no-inline-assembly */
    }
}