// SPDX-License-Identifier:UNLICENSED
pragma solidity 0.8.13;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./interface/IRoyaltyInfo.sol";
import "./interface/ITransferProxy.sol";

contract Trade is AccessControl {

    //@notice BuyingAssetType is an enumeration.
    //@param ERC1155 - value is 0.
    //@param ERC721 - value is 1.
    //@param LazyERC1155 - value is 2.
    //@param LazyERC721 - value is 3.

    enum BuyingAssetType {
        ERC1155,
        ERC721, 
        LazyERC1155,
        LazyERC721
    }

    //@notice OwnershipTransferred the event is emited at the time of transferownership function invoke. 
    //@param previousOwner address of the previous contract owner.
    //@param newOwner address of the new contract owner.

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    //@notice SignerAddressTransferred the event is emited at the time of transferSignerAddress function invoke. 
    //@param previousSigner address of the previous contract signer.
    //@param newSigner address of the new contract signer.

    event SignerAddressTransferred(
        address indexed previousSigner,
        address indexed newSigner
    );

    //@notice SellerFee the event is emited at the time of {setSellerFee} function invoke.
    //@param sellerFee sellerFee permile 
    event SellerFee(uint8 sellerFee);

    //@notice BuyerFee the event is emited at the time of {setBuyerFee} function invoke. 
    //@param buyerFee buyerFee permile 

    event BuyerFee(uint8 buyerFee);

    //@notice BuyAsset the event is emitted at the time of {buyAsset, mintAndBuyAsset} functions invoke.
    // the function invoked by asset buyer.
    //@param assetOwner - nft seller wallet address.
    //@param tokenId - unique tokenId.
    //@param quantity - no.of copies to be transfer.
    //@param buyer - nft buyer wallet address.

    event BuyAsset( 
        address nftAddress,
        address indexed assetOwner,
        uint256 indexed tokenId,
        uint256 quantity,
        address indexed buyer
    );
    
    //@notice ExecuteBid the event is emitted at the time of {executeBid, mintAndExecuteBid} functions invoke.
    // the function invoked by asset owner.
    //@param assetOwner - nft seller wallet address.
    //@param tokenId - unique tokenId.
    //@param quantity - no.of copies to be transfer.
    //@param buyer - nft buyer wallet address.

    event ExecuteBid(
        address nftAddress,
        address indexed assetOwner,
        uint256 indexed tokenId,
        uint256 quantity,
        address indexed buyer
    );
    // buyer platformFee
    uint8 private buyerFeePermille;
    //seller platformFee
    uint8 private sellerFeePermille;
    // Transferproxy contract address assciated with ITransfer Proxy interface.
    ITransferProxy public transferProxy;
    //contract owner
    address public owner;
    //contract signer
    address public signer;

    //@notice usedNonce is an array value used for duplicate sign restriction.

    mapping(uint256 => bool) private usedNonce;


    /** Fee Struct
        @param platformFee  uint256 (buyerFee + sellerFee) value which is transferred to current contract owner.
        @param assetFee  uint256  assetvalue which is transferred to current seller of the NFT.
        @param royaltyFee  uint256 value, transferred to Minter of the NFT.
        @param price  uint256 value, the combination of buyerFee and assetValue.
        @param tokenCreator address value, it's store the creator of NFT.
     */
    struct Fee {
        uint256 platformFee;
        uint256 assetFee;
        uint96[] royaltyFee;
        uint256 price;
        address[] tokenCreator;
    }

    //@notice Sign struct stores the sign bytes
    //@param v it holds(129-130) from sign value length always 27/28.
    //@param r it holds(0-66) from sign value length.
    //@param s it holds(67-128) from sign value length.
    //@param nonce unique value.

    struct Sign {
        uint8 v;
        bytes32 r;
        bytes32 s;
        uint256 nonce;
    }
    /** Order Params
        @param seller address of user,who's selling the NFT.
        @param buyer address of user, who's buying the NFT.
        @param erc20Address address of the token, which is used as payment token(WETH/WBNB/WMATIC...)
        @param nftAddress address of NFT contract where the NFT token is created/Minted.
        @param nftType an enum value, if the type is ERC721/ERC1155 the enum value is 0/1.
        @param uintprice the Price Each NFT it's not including the buyerFee.
        @param amout the price of NFT(assetFee + buyerFee).
        @param tokenId 
        @param qty number of quantity to be transfer.
     */
    struct Order {
        address seller;
        address buyer;
        address erc20Address;
        address nftAddress;
        BuyingAssetType nftType;
        uint256 unitPrice;
        bool skipRoyalty;
        uint256 amount;
        uint256 tokenId;
        string tokenURI;
        uint256 supply;
        uint96[] royaltyFee;
        address[] receivers;
        uint256 qty;
    }


    constructor(
        uint8 _buyerFee,
        uint8 _sellerFee,
        ITransferProxy _transferProxy
    ) {
        buyerFeePermille = _buyerFee;
        sellerFeePermille = _sellerFee;
        transferProxy = _transferProxy;
        owner = msg.sender;
        signer = msg.sender;
        _setupRole("ADMIN_ROLE", msg.sender);
        _setupRole("SIGNER_ROLE", msg.sender);
    }

    /**
        @notice buyerServiceFee returns the platform's buyerservice Fee
        returns the buyerservice Fee in multiply of 1000.
     */

    function buyerServiceFee() external view virtual returns (uint8) {
        return buyerFeePermille;
    }

    /**
        @notice sellerServiceFee returns the platform's sellerServiceFee Fee
        returns the sellerServiceFee Fee in multiply of 1000.
     */

    function sellerServiceFee() external view virtual returns (uint8) {
        return sellerFeePermille;
    }

    //@notice setBuyerServiceFee sets platform's buyerservice Fee.
    //@param _buyerFee  buyerserviceFee in multiply of 1000.
    /**
        restriction only the admin has role to set Fees.
     */

    function setBuyerServiceFee(uint8 _buyerFee)
        external
        onlyRole("ADMIN_ROLE")
        returns (bool)
    {
        buyerFeePermille = _buyerFee;
        emit BuyerFee(buyerFeePermille);
        return true;
    }

    //@notice setSellerServiceFee sets platform's ServiceFee Fee.
    //@param _buyerFee  ServiceFee in multiply of 1000.
    /**
        restriction only the admin has role to set Fees.
     */

    function setSellerServiceFee(uint8 _sellerFee)
        external
        onlyRole("ADMIN_ROLE")
        returns (bool)
    {
        sellerFeePermille = _sellerFee;
        emit SellerFee(sellerFeePermille);
        return true;
    }

    //@notice transferOwnership for transferring contract ownership to new owner address.
    //@param newOwner address of new owner.
    //@return bool value always true. 
    /** restriction: the ADMIN_ROLE address only has the permission to 
    transfer the contract ownership to new wallet address.*/
    //@dev see{Accesscontrol}.
    // emits {OwnershipTransferred} event.

    function transferOwnership(address newOwner)
        external
        onlyRole("ADMIN_ROLE")
        returns (bool)
    {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _revokeRole("ADMIN_ROLE", owner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        _setupRole("ADMIN_ROLE", newOwner);
        return true;
    }

        //@notice transferSignerAddress for transferring contract oldSigner to new signer address.
        //@param newSigner address of new signer.
        //@return bool value always true. 
        /** restriction: the SIGNER_ROLE address only has the permission to 
        transfer the contract oldSigner to new wallet address.*/
        //@dev see{Accesscontrol}.
        // emits {SignerAddressTransferred} event.

    function transferSignerAddress(address newSigner)
        external
        onlyRole("SIGNER_ROLE")
        returns (bool)
    {
        require(
            newSigner != address(0),
            "Ownable: new signer is the zero address"
        );
        _revokeRole("SIGNER_ROLE", signer);
        emit SignerAddressTransferred(signer, newSigner);
        signer = newSigner;
        _setupRole("SIGNER_ROLE", newSigner);
        return true;
    }

        //@notice excuting the NFT buyAsset order.
        //@param order see {Order}.
        //@param sign see {Sign}.
        /**
            restriction: 
                - Nonce should be unique.
                - Paid invalid amount.
                - seller sign should be valid
         */
        // returns the bool value always true.

    function buyAsset(Order calldata order, Sign calldata sign)
        external
        returns (bool)
    {
        require(!usedNonce[sign.nonce], "Nonce : Invalid Nonce");
        usedNonce[sign.nonce] = true;
        Fee memory fee = getFees(
            order
        );
        require(
            (fee.price >= order.unitPrice * order.qty),
            "Paid invalid amount"
        );
        verifySellerSign(
            order.seller,
            order.tokenId,
            order.unitPrice,
            order.erc20Address,
            order.nftAddress,
            sign
        );
        address buyer = msg.sender;
        tradeAsset(order, fee, buyer, order.seller);
        emit BuyAsset(order.nftAddress, order.seller, order.tokenId, order.qty, msg.sender);
        return true;
    }

        //@notice excuting the NFT executeBid order.
        //@param order see {Order}.
        //@param sign see {Sign}.
        /**
            restriction: 
                - Nonce should be unique.
                - Paid invalid amount.
                - buyer sign should be valid
         */
        // returns the bool value always true.

    function executeBid(Order calldata order, Sign calldata sign)
        external
        returns (bool)
    {
        require(!usedNonce[sign.nonce], "Nonce : Invalid Nonce");
        usedNonce[sign.nonce] = true;
        Fee memory fee = getFees(
            order
        );
        verifyBuyerSign(
            order.buyer,
            order.tokenId,
            order.amount,
            order.erc20Address,
            order.nftAddress,
            order.qty,
            sign
        );
        address seller = msg.sender;
        tradeAsset(order, fee, order.buyer, seller);
        emit ExecuteBid(order.nftAddress, msg.sender, order.tokenId, order.qty, order.buyer);
        return true;
    }

        //@notice excuting the NFT mintAndBuyAsset order.
        //@param order see {Order}.
        //@param sign see {Sign}.
        //@param ownerSign {Sign}
        /**
            restriction: 
                - Nonce should be unique.
                - Paid invalid amount.
                - seller sign should be valid
                - owner sign should be valid
         */
        // returns the bool value always true.

    function mintAndBuyAsset(Order calldata order, Sign calldata sign, Sign calldata ownerSign)
        external
        returns (bool)
    {
        require(!usedNonce[sign.nonce], "Nonce : Invalid Nonce");
        usedNonce[sign.nonce] = true;
        Fee memory fee = getFees(
            order
        );
        require(
            (fee.price >= order.unitPrice * order.qty),
            "Paid invalid amount"
        );
        verifyOwnerSign(
            order.seller,
            order.tokenURI,
            order.nftAddress,
            ownerSign
        );
        verifySellerSign(
            order.seller,
            order.tokenId,
            order.unitPrice,
            order.erc20Address,
            order.nftAddress,
            sign
        );
        address buyer = msg.sender;
        tradeAsset(order, fee, buyer, order.seller);
        emit BuyAsset(order.nftAddress, order.seller, order.tokenId, order.qty, msg.sender);
        return true;
    }
        //@notice excuting the NFT mintAndExecuteBid order.
        //@param order see {Order}.
        //@param sign see {Sign}.
        //@param ownerSign {Sign}
        /**
            restriction: 
                - Nonce should be unique.
                - Paid invalid amount.
                - buyer sign should be valid
                - owner sign should be valid
         */
        // returns the bool value always true.

    function mintAndExecuteBid(Order calldata order, Sign calldata sign, Sign calldata ownerSign)
        external
        returns (bool)
    {
        require(!usedNonce[sign.nonce], "Nonce : Invalid Nonce");
        usedNonce[sign.nonce] = true;
        Fee memory fee = getFees(
            order
        );
        verifyOwnerSign(
            order.seller,
            order.tokenURI,
            order.nftAddress,
            ownerSign
        );
        verifyBuyerSign(
            order.buyer,
            order.tokenId,
            order.amount,
            order.erc20Address,
            order.nftAddress,
            order.qty,
            sign
        );
        address seller = msg.sender;
        tradeAsset(order, fee, order.buyer, seller);
        emit ExecuteBid(order.nftAddress, msg.sender, order.tokenId, order.qty, order.buyer);
        return true;
    }

    //@notice function returns the signer address from signed hash.
    //@param hash generated from sign parameters.
    //@returns the signer of given signature.
    //@dev see {Sign}.


    function getSigner(bytes32 hash, Sign memory sign)
        internal
        pure
        returns (address)
    {
        return
            ecrecover(
                keccak256(
                    abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
                ),
                sign.v,
                sign.r,
                sign.s
            );
    }

    //@notice function verifies the singer address from the signed hash.
    //@param buyer address of the asset buyer.
    //@param tokenId unique id of NFT
    //@param amount sale price of asset
    //@param paymentAssetAddress address of payment token(WETH, WBNB, WMATIC,...)
    //@param assetAddress NFT contract address(ERC721, ERC1155)
    //@param qty no.of units to be tranfer.
    //@param sign @dev see{Sign}.
    /**
        * Requirements- buyer sign verification failed when signture was mismatched.
     */

    function verifySellerSign(
        address seller,
        uint256 tokenId,
        uint256 amount,
        address paymentAssetAddress,
        address assetAddress,
        Sign memory sign
    ) internal pure {
        bytes32 hash = keccak256(
            abi.encodePacked(
                assetAddress,
                tokenId,
                paymentAssetAddress,
                amount,
                sign.nonce
            )
        );
        require(
            seller == getSigner(hash, sign),
            "seller sign verification failed"
        );
    }
    //@notice function verifies the singer address from the signed hash.
    //@param _tokenURI IPFS metatdata URI.
    //@param caller address of the caller.
    //@param sign @dev see{Sign}.
    /**
        * Requirements- owner sign verification failed when signture was mismatched.
     */
    function verifyOwnerSign(
        address seller,
        string memory tokenURI,
        address assetAddress,
        Sign memory sign
    ) internal view {
        bytes32 hash = keccak256(
            abi.encodePacked(
                this,
                assetAddress,
                seller,
                tokenURI,
                sign.nonce
            )
        );
        require(
            signer == getSigner(hash, sign),
            "owner sign verification failed"
        );
    }

    //@notice function verifies the singer address from the signed hash.
    //@param buyer address of the asset buyer.
    //@param tokenId unique id of NFT
    //@param amount sale price of asset
    //@param paymentAssetAddress address of payment token(WETH, WBNB, WMATIC,...)
    //@param assetAddress NFT contract address(ERC721, ERC1155)
    //@param qty no.of units to be tranfer.
    //@param sign @dev see{Sign}.
    /**
        * Requirements- buyer sign verification failed when signture was mismatched.
     */

    function verifyBuyerSign(
        address buyer,
        uint256 tokenId,
        uint256 amount,
        address paymentAssetAddress,
        address assetAddress,
        uint256 qty,
        Sign memory sign
    ) internal pure {
        bytes32 hash = keccak256(
            abi.encodePacked(
                assetAddress,
                tokenId,
                paymentAssetAddress,
                amount,
                qty,
                sign.nonce
            )
        );
        require(
            buyer == getSigner(hash, sign),
            "buyer sign verification failed"
        );
    }

    //@notice the function calculates platform Fee, assetFee, royaltyFee from the NFT token SalePrice.
    //@param see order {Order}
    //retuns platformFee, assetFee, royaltyFee, price and tokencreator.

    function getFees(
        Order calldata order
    ) internal view returns (Fee memory) {
        uint256 platformFee;
        uint256 assetFee;
        uint256 royalty;
        uint96[] memory _royaltyFee;
        address[] memory _tokenCreator;
        uint256 price = (order.amount * 1000) / (1000 + buyerFeePermille);
        uint256 buyerFee = order.amount - price;
        uint256 sellerFee = (price * sellerFeePermille) / 1000;
        platformFee = buyerFee + sellerFee;
        if(!order.skipRoyalty &&((order.nftType == BuyingAssetType.ERC721) || (order.nftType == BuyingAssetType.ERC1155))) {
            (_royaltyFee, _tokenCreator, royalty) = IRoyaltyInfo(order.nftAddress)
                    .royaltyInfo(order.tokenId, price);        }
        if(!order.skipRoyalty &&((order.nftType == BuyingAssetType.LazyERC721) || (order.nftType == BuyingAssetType.LazyERC1155))) {
                _royaltyFee = new uint96[](order.royaltyFee.length);
                _tokenCreator = new address[](order.receivers.length);
                for( uint256 i =0; i< order.receivers.length; i++) {
                    royalty += uint96(price * order.royaltyFee[i] / 1000) ;
                    (_tokenCreator[i], _royaltyFee[i]) = (order.receivers[i], uint96(price * order.royaltyFee[i] / 1000));
                }     
        }
        assetFee = price - royalty - sellerFee;
        return Fee(platformFee, assetFee, _royaltyFee, price, _tokenCreator);
    }

    /** 
        @notice transfer and Mint the NFTs(ERC721, ERC1155) and tokens through the transferproxy.
        @param order @dev see {Order}.
        @param fee @dev see {Fee}.
        @param buyer asset buuyer.

    */

    function tradeAsset(
        Order calldata order,
        Fee memory fee,
        address buyer,
        address seller
    ) internal virtual {
        if (order.nftType == BuyingAssetType.ERC721) {
            transferProxy.erc721safeTransferFrom(
                IERC721(order.nftAddress),
                seller,
                buyer,
                order.tokenId
            );
        }

        if (order.nftType == BuyingAssetType.ERC1155) {
            transferProxy.erc1155safeTransferFrom(
                IERC1155(order.nftAddress),
                seller,
                buyer,
                order.tokenId,
                order.qty,
                ""
            );
        }

        if (order.nftType == BuyingAssetType.LazyERC721) {
            transferProxy.mintAndSafe721Transfer(
                ILazyMint(order.nftAddress),
                seller,
                buyer,
                order.tokenURI,
                order.royaltyFee,
                order.receivers
            );
        }

        if (order.nftType == BuyingAssetType.LazyERC1155) {
            transferProxy.mintAndSafe1155Transfer(
                ILazyMint(order.nftAddress),
                seller,
                buyer,
                order.tokenURI,
                order.royaltyFee,
                order.receivers,
                order.supply,
                order.qty
            );
        }

        if (fee.platformFee > 0) {
            transferProxy.erc20safeTransferFrom(
                IERC20(order.erc20Address),
                buyer,
                owner,
                fee.platformFee
            );
        }

        for(uint96 i = 0; i < fee.tokenCreator.length; i++) {
            if (fee.royaltyFee[i] > 0 && (!order.skipRoyalty)) {
                transferProxy.erc20safeTransferFrom(
                    IERC20(order.erc20Address),
                    buyer,
                    fee.tokenCreator[i],
                    fee.royaltyFee[i]
                );
            }
        }

        transferProxy.erc20safeTransferFrom(
            IERC20(order.erc20Address),
            buyer,
            seller,
            fee.assetFee
        );
    }
}

// SPDX-License-Identifier:UNLICENSED
pragma solidity 0.8.13;

import "./ILazyMint.sol";

//@title ITransferProxy is used for communicating with ERC721, ERC1155, tokens(WETH, WBNB, WMATIC,...).
//@notice the interface used for transferring NFTs from sender wallet address to receiver wallet address.
//@notice andalso transfers the assetFee, royaltyFee, platform fee from users.

interface ITransferProxy {

    //@notice the function transfers ERC721 NFTs to users.
    //@param token, ERC721 address @dev see {IERC721}.
    //@param from, seller address, NFTs to be transferrred from this address.
    //@param to, buyer address, NFTs to be received to this address.
    //@param tokenId, unique NFT id to be transfer.

    function erc721safeTransferFrom(
        IERC721 token,
        address from,
        address to,
        uint256 tokenId
    ) external;

    //@notice the function transfers ERC721 NFTs to users.
    //@param token, ERC1155 @dev see {IERC1155}.
    //@param from, seller address, NFTs to be transferrred from this address.
    //@param to, buyer address, NFTs to be received to this address.
    //@param tokenId, unique NFT id to be transfer.

    function erc1155safeTransferFrom(
        IERC1155 token,
        address from,
        address to,
        uint256 tokenId,
        uint256 value,
        bytes calldata data
    ) external;

    //@notice function used for ERC1155Lazymint, it does NFT minting and NFT transfer.
    //@param nftAddress, ERC1155 @dev see {IERC1155}.
    //@param from, NFT to be minted on this address.
    //@param to, NFT to be transffered 'from' address to this address.
    //@param _tokenURI, IPFS URI of NFT to be Minted.
    //@param _royaltyFee, fee permiles for secondary sale.
    //@param _receivers, fee receivers for secondary sale.
    //@param supply, copies to minted to creator 'from' address.
    //@param qty, copies to be transfer to receiver 'to' address.
    //@return _tokenId, NFT unique id.
    //@dev see {ERC1155}.
    
    function mintAndSafe1155Transfer(
        ILazyMint nftAddress,
        address from,
        address to,
        string memory _tokenURI,
        uint96[] calldata _royaltyFee,
        address[] calldata _receivers,
        uint256 supply,
        uint256 qty
    ) external ;

    //@notice function used for ERC721Lazymint, it does NFT minting and NFT transfer.
    //@param nftAddress, ERC721 address @dev see {IERC721}.
    //@param from, NFT to be minted on this address.
    //@param to, NFT to be transffered from address to this address.
    //@param _tokenURI, IPFS URI of NFT to be Minted.
    //@param _royaltyFee, fee permiles for secondary sale.
    //@param _receivers, fee receivers for secondary sale.
    //@return _tokenId, NFT unique id.
    //@dev see {ERC721}.

    function mintAndSafe721Transfer(
        ILazyMint nftAddress,
        address from,
        address to,
        string memory _tokenURI,
        uint96[] calldata _royaltyFee,
        address[] calldata _receivers    
    ) external;

    //@notice the, function used for transferring token from 'from' address to 'to' address.
    //@param token, ERC20 address(WETH, WBNB, WMATIC) @dev see {IERC20}.
    //@param from, NFT to be minted on this address.
    //@param to, NFT to be transffered 'from' address to this address.
    //@param value, amount of tokens to transfer(Royalty, assetFee, platformFee...).

    function erc20safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

//@title IRoyaltyInfo is used for communicating with Davinci contracts for getting royalty info.
//@dev see{ERC721, ERC1155}
interface IRoyaltyInfo {
    //@notice function used for getting royalty info. for the given tokenId and calculates the royalty Fee for the given sale price.
    //@param _tokenId unique id of NFT.
    //@param price sale price of the NFT.
    //@returns royalty receivers,royalty value ,it can be calculated from the royaltyFee permiles.
    //dev see {ERC2981}
    function royaltyInfo(
        uint256 _tokenId, 
        uint256 price) 
        external 
        view 
        returns(uint96[] memory, address[] memory, uint256);
}

// SPDX-License-Identifier:UNLICENSED
pragma solidity 0.8.13;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC1155.sol";

//@title ILazyMint interface used for communicating with ERC721, ERC1155.
//@dev see{ERC721, ERC1155}.

interface ILazyMint {
    //@notice function used for ERC721Lazymint, it does NFT minting and NFT transfer.
    //@param from NFT to be minted on this address.
    //@param to NFT to be transffered from address to this address.
    //@param _tokenURI IPFS URI of NFT to be Minted.
    //@param _royaltyFee fee permiles for secondary sale.
    //@param _receivers fee receivers for secondary sale.
    //@dev see {ERC721}.
    
    function mintAndTransfer(
        address from,
        address to,
        string memory _tokenURI,
        uint96[] calldata _royaltyFee,
        address[] calldata _receivers
    ) external returns(uint256 _tokenId);

    //@notice function used for ERC1155Lazymint, it does NFT minting and NFT transfer.
    //@param from NFT to be minted on this address.
    //@param to NFT to be transffered from address to this address.
    //@param _tokenURI IPFS URI of NFT to be Minted.
    //@param _royaltyFee fee permiles for secondary sale.
    //@param _receivers fee receivers for secondary sale.
    //@param supply copies to minted to creator 'from' address.
    //@param qty copies to be transfer to receiver 'to' address.
    //@dev see {ERC1155}.
    
    function mintAndTransfer(
        address from,
        address to,
        string memory _tokenURI,
        uint96[] calldata _royaltyFee,
        address[] calldata _receivers,
        uint256 supply,
        uint256 qty
    ) external returns(uint256 _tokenId);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721.sol)

pragma solidity ^0.8.0;

import "../token/ERC721/IERC721.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1155.sol)

pragma solidity ^0.8.0;

import "../token/ERC1155/IERC1155.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}