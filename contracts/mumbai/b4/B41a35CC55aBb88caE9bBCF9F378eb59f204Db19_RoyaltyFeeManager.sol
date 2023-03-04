// SPDX-License-Identifier: None
pragma solidity ^0.8.0;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC165, IERC2981} from "@openzeppelin/contracts/interfaces/IERC2981.sol";
import {IRoyaltyFeeManager} from "./interfaces/IRoyaltyFeeManager.sol";
import {IEIP998} from "./interfaces/IEIP998.sol";
import {IRoyaltyFeeRegistry} from "./interfaces/IRoyaltyFeeRegistry.sol";

/**
 * @title RoyaltyFeeManager
 * @notice It handles the logic to check and transfer royalty fees (if any).
 */
contract RoyaltyFeeManager is IRoyaltyFeeManager, Ownable {
    // https://eips.ethereum.org/EIPS/eip-2981
    bytes4 public constant INTERFACE_ID_ERC2981 = 0x2a55205a;

    IRoyaltyFeeRegistry public royaltyFeeRegistry;

    //events
    event SetRoyaltyRegistry(address _address);

    /**
     * @notice Constructor
     * @param _royaltyFeeRegistry address of the RoyaltyFeeRegistry
     */
    constructor(address _royaltyFeeRegistry) {
        royaltyFeeRegistry = IRoyaltyFeeRegistry(_royaltyFeeRegistry);
    }

    /**
     * @dev change the royalty registory address.
     * @param _address royalty registry address
     */
    function setRoyaltyRegistry(address _address) external onlyOwner {
        require(_address != address(0), "invalid address");
        require(
            IRoyaltyFeeRegistry(_address) != royaltyFeeRegistry,
            "same address already"
        );
        royaltyFeeRegistry = IRoyaltyFeeRegistry(_address);
        emit SetRoyaltyRegistry(_address);
    }

    /**
     * @notice Calculate royalty fee and get recipient for ERC998
     * @param collection address of the NFT contract
     * @param tokenId tokenId
     * @param amount amount to transfer
     */
    function calculateRoyaltyForBundle(
        address collection,
        uint256 tokenId,
        uint256 amount
    )
        external
        view
        returns (
            address[] memory allReceivers,
            uint256[] memory allRoyaltyAmount
        )
    {
        require(
            IERC165(collection).supportsInterface(INTERFACE_ID_ERC2981),
            "collection not support 2981"
        );
        (, uint256 maxRoyaltyAmount) = IERC2981(collection).royaltyInfo(
            tokenId,
            amount
        );
        uint allReceiversLength;
        uint256 totalRoyaltyPercentage;
        for (
            uint256 i = 0;
            i < IEIP998(collection).totalChildContracts(tokenId);
            i++
        ) {
            address childContract = IEIP998(collection).childContractByIndex(
                tokenId,
                i
            );

            for (
                uint256 j = 0;
                j <
                IEIP998(collection).totalChildTokens(tokenId, childContract);
                j++
            ) {
                uint256 childTokenId = IEIP998(collection).childTokenByIndex(
                    tokenId,
                    childContract,
                    j
                );
                (, uint[] memory fees) = royaltyFeeRegistry
                    .royaltyFeeInfoCollection(childContract, childTokenId);

                for (uint256 k = 0; k < fees.length; k++) {
                    totalRoyaltyPercentage = totalRoyaltyPercentage + fees[k];
                    allReceiversLength++;
                }
            }
        }

        allReceivers = new address[](allReceiversLength);
        allRoyaltyAmount = new uint256[](allReceiversLength);
        uint256 index;
        for (
            uint256 i = 0;
            i < IEIP998(collection).totalChildContracts(tokenId);
            i++
        ) {
            address childContract = IEIP998(collection).childContractByIndex(
                tokenId,
                i
            );
            for (
                uint256 j = 0;
                j <
                IEIP998(collection).totalChildTokens(tokenId, childContract);
                j++
            ) {
                uint256 childTokenId = IEIP998(collection).childTokenByIndex(
                    tokenId,
                    childContract,
                    j
                );
                (
                    address[] memory receivers,
                    uint[] memory fees
                ) = royaltyFeeRegistry.royaltyFeeInfoCollection(
                        childContract,
                        childTokenId
                    );
                for (uint256 k = 0; k < receivers.length; k++) {
                    allReceivers[index] = (receivers[k]);
                    allRoyaltyAmount[index] =
                        ((maxRoyaltyAmount * _feeDenominator() * fees[k]) /
                            totalRoyaltyPercentage) /
                        _feeDenominator();
                    index++;
                }
            }
        }
    }

    /**
     * @notice Calculate royalty fee and get recipient
     * @param collection address of the NFT contract
     * @param tokenId tokenId
     * @param amount amount to transfer
     */
    function calculateRoyaltyFeeAndGetRecipient(
        address collection,
        uint256 tokenId,
        uint256 amount
    ) external view override returns (address[] memory, uint256[] memory) {
        (address[] memory receivers, uint256[] memory fees) = royaltyFeeRegistry
            .royaltyFeeInfoCollection(collection, tokenId);

        if (receivers.length > 0) {
            uint256[] memory royaltyAmount = new uint256[](receivers.length);
            for (uint256 i = 0; i < receivers.length; i++) {
                royaltyAmount[i] = (amount * fees[i]) / 10000;
            }
            return (receivers, royaltyAmount);
        }
        address[] memory _receivers = new address[](1);
        uint256[] memory _royaltyAmounts = new uint256[](1);
        // 1. Check if there is a royalty info in the system
        (address _receiver, uint256 fee) = royaltyFeeRegistry
            .royaltyFeeInfoCollection(collection);

        uint256 _royaltyAmount;
        // 2. If the receiver is address(0), fee is null, check if it supports the ERC2981 interface
        if (_receiver != address(0) || (fee != 0)) {
            _receivers[0] = _receiver;
            _royaltyAmount = (amount * fee) / 10000;
            _royaltyAmounts[0] = _royaltyAmount;
            return (_receivers, _royaltyAmounts);
        }
        if (IERC165(collection).supportsInterface(INTERFACE_ID_ERC2981)) {
            (_receiver, _royaltyAmount) = IERC2981(collection).royaltyInfo(
                tokenId,
                amount
            );
            _receivers[0] = _receiver;
            _royaltyAmounts[0] = _royaltyAmount;
            return (_receivers, _royaltyAmounts);
        }
        return (_receivers, _royaltyAmounts);
    }

    /**
     * @dev The denominator with which to interpret the fee set in {_setTokenRoyalty} and {_setDefaultRoyalty} as a
     * fraction of the sale price. Defaults to 10000 so fees are expressed in basis points, but may be customized by an
     * override.
     */
    function _feeDenominator() internal pure virtual returns (uint96) {
        return 10000;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IRoyaltyFeeManager {
    function calculateRoyaltyFeeAndGetRecipient(
        address collection,
        uint256 tokenId,
        uint256 amount
    ) external returns (address[] memory, uint256[] memory);

    function calculateRoyaltyForBundle(
        address collection,
        uint256 tokenId,
        uint256 amount
    ) external returns (address[] memory, uint256[] memory);
}

// SPDX-License-Identifier: None
pragma solidity ^0.8.0;

interface IEIP998 {

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external;

    function totalChildTokens(uint256 _tokenId, address _childContract)
        external
        view
        returns (uint256);

    function totalChildContracts(uint256 _tokenId)
        external
        view
        returns (uint256);

    function childContractByIndex(uint256 _tokenId, uint256 _index)
        external
        view
        returns (address childContract);

    function childTokenByIndex(
        uint256 _tokenId,
        address _childContract,
        uint256 _index
    ) external view returns (uint256 childTokenId);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IRoyaltyFeeRegistry {
    function updateRoyaltyFeeLimitForERC721(uint256 _royaltyFeeLimit) external;
    function updateRoyaltyFeeLimitForERC1155(uint256 _royaltyFeeLimit) external;

    function updateRoyaltyReceiverLimit(uint256 newMaxNumberOfReceivers)
        external;

    function updateRoyaltyInfoForNFT(
        address collection,
        uint256 tokenId,
        address[] memory receivers,
        uint256[] memory fees
    ) external;

    function royaltyFeeInfoCollection(address collection)
        external
        view
        returns (address, uint256);

    function royaltyFeeInfoCollection(address collection, uint256 tokenId)
        external
        view
        returns (address[] memory, uint256[] memory);

    function removeRoyaltyInfoForNFT(address collection, uint256 tokenId)
        external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

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