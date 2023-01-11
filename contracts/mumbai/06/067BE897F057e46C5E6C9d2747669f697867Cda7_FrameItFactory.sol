// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "./IFrameItFactory.sol";
import "../nfts/IFrameItNFT.sol";
import "../nfts/IFrameItLootBox.sol";
import "../royalties/IFrameItSalesSplitter.sol";
import "../utils/Ownable.sol";

contract FrameItFactory is IFrameItFactory, Ownable {

    address public nftTemplate;
    address public lootBoxTemplate;
    address public salesSplitterTemplate;
    address public packsMarketplace;
    address public marketplace;
    address public auctionMarketplace;
    address public moonpayWallet;
   
    event FrameItCollectionCreated(address indexed _nft, address indexed _lootBox, address indexed _salesPrimarySplitter, address _salesSecondarySplitter, address _owner, string _nftUri, string _lootBoxUri);
    event FrameItSoulboundCreated(address indexed _soulbound, string _soulboundUri, address _owner);
    event NFTTemplateUpdated(address _nftTemplate);
    event LootBoxTemplateUpdated(address _lootBoxTemplate);
    event SalesSplitterTemplateUpdated(address _salesSplitterTemplate);
    event PacksMarketplaceTemplateUpdated(address _packsMarketplace);
    event MarketplaceTemplateUpdated(address _marketplace);
    event AuctionMarketplaceTemplateUpdated(address _auctionMarketplace);
    event MoonpayWalletUpdated(address _moonpayWallet);

    constructor (
        address _nftTemplate, 
        address _lootBoxTemplate, 
        address _salesSplitterTemplate, 
        address _packsMarketplace,
        address _marketplace, 
        address _auctionMarketplace, 
        address _moonpayWallet
    ) {
        nftTemplate = _nftTemplate;
        lootBoxTemplate = _lootBoxTemplate;
        salesSplitterTemplate = _salesSplitterTemplate;
        packsMarketplace = _packsMarketplace;
        marketplace = _marketplace;
        auctionMarketplace = _auctionMarketplace;
        moonpayWallet = _moonpayWallet;
    }

    function updateNFTTemplate(address _nftTemplate) external onlyOwner {
        require(_nftTemplate != address(0), "NullAddress");

        nftTemplate = _nftTemplate;
        emit NFTTemplateUpdated(_nftTemplate);
    }

    function updateLootBoxTemplate(address _lootBoxTemplate) external onlyOwner {
        require(_lootBoxTemplate != address(0), "NullAddress");

        lootBoxTemplate = _lootBoxTemplate;
        emit LootBoxTemplateUpdated(_lootBoxTemplate);
    }

    function updateSalesSplitterTemplate(address _salesSplitterTemplate) external onlyOwner {
        require(_salesSplitterTemplate != address(0), "NullAddress");

        salesSplitterTemplate = _salesSplitterTemplate;
        emit SalesSplitterTemplateUpdated(_salesSplitterTemplate);
    }

    function updatePacksMarketplace(address _packsMarketplace) external onlyOwner {
        require(_packsMarketplace != address(0), "NullAddress");

        packsMarketplace = _packsMarketplace;
        emit PacksMarketplaceTemplateUpdated(_packsMarketplace);
    }

    function updateMarketplace(address _marketplace) external onlyOwner {
        require(_marketplace != address(0), "NullAddress");

        marketplace = _marketplace;
        emit MarketplaceTemplateUpdated(_marketplace);
    }

    function updateAuctionMarketplace(address _auctionMarketplace) external onlyOwner {
        require(_auctionMarketplace != address(0), "NullAddress");

        auctionMarketplace = _auctionMarketplace;
        emit AuctionMarketplaceTemplateUpdated(_auctionMarketplace);
    }

    function updateMoonpayWallet(address _moonpayWallet) external onlyOwner {
        require(_moonpayWallet != address(0), "NullAddress");

        moonpayWallet = _moonpayWallet;
        emit MoonpayWalletUpdated(_moonpayWallet);
    }

    function createCollection(
        string memory _name,
        string memory _symbol,
        string memory _nftUri,
        string memory _lootBoxUri,
        uint48 _minimumTimeToOpen,
        uint48 _royaltiesFeeInBips
    ) external {
        address nft = Clones.clone(nftTemplate);
        address lootBox = Clones.clone(lootBoxTemplate);
        address salesPrimarySplitter = Clones.clone(salesSplitterTemplate);
        address salesSecondarySplitter = Clones.clone(salesSplitterTemplate);

        IFrameItNFT(nft).initialize(_name, _symbol, _nftUri, msg.sender, _royaltiesFeeInBips, salesSecondarySplitter, lootBox);
        IFrameItLootBox(lootBox).initialize(_name, _symbol, nft, msg.sender, _lootBoxUri, _royaltiesFeeInBips, _minimumTimeToOpen);
        IFrameItLootBox(lootBox).setSalesWallet(salesPrimarySplitter);

        emit FrameItCollectionCreated(nft, lootBox, salesPrimarySplitter, salesSecondarySplitter, msg.sender, _nftUri, _lootBoxUri);
    }

    function createWallets(
        address _lootBox,
        address salesPrimarySplitter,
        address salesSecondarySplitter,
        uint256[] calldata _splitPercentagesPrimarySaleInBips,
        uint256[] calldata _splitPercentagesSecondarySaleInBips,
        address[] calldata _splitWallets
    ) external {
        require(IFrameItLootBox(_lootBox).owner() == msg.sender, "BadOwner");
        require(IFrameItLootBox(_lootBox).salesWallet() == salesPrimarySplitter, "BadAddress");

        IFrameItSalesSplitter(salesPrimarySplitter).initialize(owner, _splitPercentagesPrimarySaleInBips, _splitWallets, true);
        IFrameItSalesSplitter(salesSecondarySplitter).initialize(owner, _splitPercentagesSecondarySaleInBips, _splitWallets, false);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

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
abstract contract Ownable {
    address public owner;
    address public ownerPendingClaim;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event NewOwnershipProposed(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(msg.sender);
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "OnlyOwner");
        _;
    }

    function proposeChangeOwner(address newOwner) external onlyOwner {
        require(newOwner != address(0), "ZeroAddress");
        ownerPendingClaim = newOwner;

        emit NewOwnershipProposed(msg.sender, newOwner);
    }

    function claimOwnership() external {
        require(msg.sender == ownerPendingClaim, "OnlyProposedOwner");

        ownerPendingClaim = address(0);
        _transferOwnership(msg.sender);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = owner;
        owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface IFrameItSalesSplitter {

    function initialize(address _owner, uint256[] memory _royaltyFeesInBips, address[] memory _royaltyWallets, bool _isPrimary) external;
    function setWallets(uint256[] calldata _royaltyFeesInBips, address[] calldata _royaltyWallets) external;
    function withdraw(address[] memory _tokens) external;
    function withdrawNative() external;
    function paymentWallets() external view returns (uint256[] memory fees, address[] memory wallets);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface IFrameItNFTCommons {

    function salesWallet() external view returns(address);
    function owner() external view returns(address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "./IFrameItNFTCommons.sol";

interface IFrameItNFT is IFrameItNFTCommons {

    function initialize(string memory _newname, string memory _newsymbol, string memory _newuri, address _owner, uint256 _royaltyFeeInBips, address _salesWallet, address _lootBox) external;
    function mint(address _to, uint256[] calldata _ids) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "./IFrameItNFTCommons.sol";

interface IFrameItLootBox is IFrameItNFTCommons {

    function initialize(string memory _newname, string memory _newsymbol, address _nftContract, address _owner, string memory _newuri, uint256 _royaltiesFeeInBips, uint256 _minimumTimeToOpen) external;
    function setSalesWallet(address _salesWallet) external;
    function mintLootBoxes(bytes32[] calldata _signatures, address _signer, address _opener) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface IFrameItFactory {
    function packsMarketplace() external view returns(address);
    function marketplace() external view returns(address);
    function auctionMarketplace() external view returns(address);
    function moonpayWallet() external view returns(address);

    function createCollection(
        string memory _name,
        string memory _symbol,
        string memory _nftUri,
        string memory _lootBoxUri,
        uint48 _minimumTimeToOpen,
        uint48 _royaltiesFeeInBips
        //uint256[] calldata _splitPercentagesPrimarySaleInBips,
        //address[] calldata _splitWallets
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}