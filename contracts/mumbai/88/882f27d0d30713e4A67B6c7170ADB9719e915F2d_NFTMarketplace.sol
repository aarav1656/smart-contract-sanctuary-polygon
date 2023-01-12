//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.3;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./interfaces/ITokenRoyalties.sol";
import "./interfaces/ILazyMinting.sol";
import "contracts/helpers/BasicMetaTransaction.sol";

contract NFTMarketplace is
    ERC1155Holder,
    ReentrancyGuard,
    Ownable,
    BasicMetaTransaction
{
    using Counters for Counters.Counter;
    using SafeERC20 for IERC20;

    enum SaleKind {
        FixedPrice,
        Auction
    }
    uint256 private _serviceFee;
    // min percent increment in next bid
    uint256 private _bidRate;
    uint256 private _totalServiceFeeAmount;
    IERC20 public NembusToken;
    SaleKind public saleKind;

    Counters.Counter private _itemIds;

    event List(
        address indexed seller,
        address indexed nftAddress,
        uint256 indexed itemId,
        uint256 tokenId,
        uint256 basePrice,
        uint256 amount,
        uint256 listingDate,
        uint256 expirationDate,
        SaleKind saleKind,
        string voucher,
        string signature
    );

    event Cancel(
        address indexed seller,
        address indexed nftAddress,
        uint256 indexed itemId,
        uint256 tokenId,
        uint256 amount
    );

    event Sold(
        uint256 indexed itemId,
        address indexed seller,
        address indexed buyer,
        address nftAddress,
        uint256 tokenId,
        uint256 amount,
        uint256 nftNumber
    );

    event TransferredRoyaltyToTheCreator(
        address indexed creator,
        uint256 amount
    );

    event TransferredPaymentToTheSeller(
        address indexed seller,
        address indexed buyer,
        uint256 indexed itemId,
        uint256 amount
    );

    event ServiceFeeClaimed(address indexed account, uint256 amount);

    event ServiceFeeUpdated(
        address indexed owner,
        uint256 oldFee,
        uint256 newFee
    );

    event OfferRetracted(
        uint256 indexed itemId,
        uint256 indexed tokenId,
        address indexed bidder,
        address nftAddress,
        uint256 amount
    );

    event BidOffered(
        uint256 indexed itemId,
        uint256 indexed tokenId,
        address indexed bidder,
        address nftAddress,
        uint256 bidAmount
    );

    modifier itemExists(uint256 _id) {
        require(_id <= _itemIds.current(), "itemExists:Item Id out of bounds");
        require(marketItems[_id].basePrice > 0, "itemExists: Item not listed");
        _;
    }

    struct Item {
        uint256 tokenId;
        uint256 basePrice;
        uint256 itemsAvailable;
        uint256 listingTime;
        uint256 expirationTime;
        uint256 reservePrice;
        address nftAddress;
        address seller;
        bool lazyMint;
        SaleKind saleKind;
    }

    struct Bid {
        uint256 maxBid;
        address bidderAddress;
    }

    //itemId => Item
    mapping(uint256 => Item) public marketItems;
    //itemId => Bid
    mapping(uint256 => Bid) public itemBids;

    mapping(uint256 => uint256) private lazyListings;

    constructor(
        uint256 serviceFee_,
        uint256 bidRate_,
        address NembusToken_
    ) {
        _serviceFee = serviceFee_;
        _bidRate = bidRate_;
        require(NembusToken_ != address(0), "constructor: token address zero");
        NembusToken = IERC20(NembusToken_);
    }

    function getItemCount() external view returns (uint256) {
        return _itemIds.current();
    }

    function getServiceFeeRate() external view returns (uint256) {
        return _serviceFee;
    }

    function setServiceFee(uint256 _newFee) external onlyOwner {
        uint256 _oldFee = _serviceFee;
        _serviceFee = _newFee;
        emit ServiceFeeUpdated(_msgSender(), _oldFee, _newFee);
    }

    function _check(
        uint256 _tokenId,
        address _nftAddress,
        uint256 _nftMaxCopies,
        uint256 _nftAmount,
        uint256[] memory royalties,
        address[] memory recipients
    ) internal {
        if (ILazyMinting(_nftAddress).getMaxTokens(_tokenId) == 0) {
            require(
                _nftMaxCopies >= _nftAmount,
                "listItem: invalid nft amount"
            );
            lazyListings[_tokenId] = _nftAmount;
            ILazyMinting(_nftAddress).setMaxTokens(_tokenId, _nftMaxCopies);
            ILazyMinting(_nftAddress).setCreator(_tokenId, _msgSender());
            ILazyMinting(_nftAddress).setTokenRoyalty(
                _tokenId,
                royalties,
                recipients
            );
        } else {
            require(
                lazyListings[_tokenId] +
                    _nftAmount +
                    ILazyMinting(_nftAddress).totalSupply(_tokenId) <=
                    ILazyMinting(_nftAddress).getMaxTokens(_tokenId),
                "listItem: invalid nft amount"
            );
            require(
                ILazyMinting(_nftAddress).getCreator(_tokenId) == _msgSender(),
                "listItem: unauthorised attempt of listing"
            );
            lazyListings[_tokenId] += _nftAmount;
        }
    }

    function listItem(
        uint256 _nftMaxCopies,
        Item calldata listData,
        uint256[] memory royalties,
        address[] calldata recipients,
        string calldata voucher,
        string calldata signature
    ) external nonReentrant {
        _itemIds.increment();
        uint256 itemId = _itemIds.current();

        Item memory item = listData;

        require(item.nftAddress != address(0), "listItem: nft address is zero");
        require(item.itemsAvailable != 0, "listItem: nft amount is zero");

        if (item.lazyMint) {
            _check(
                item.tokenId,
                item.nftAddress,
                _nftMaxCopies,
                item.itemsAvailable,
                royalties,
                recipients
            );
        }

        require(
            item.expirationTime > item.listingTime,
            "listItem: Expiration date invalid"
        );
        require(
            item.listingTime >= block.timestamp - 300,
            "listItem: listing time invalid"
        );
        require(item.basePrice != 0, "listItem: Price cannot be zero");
        require(
            item.itemsAvailable != 0,
            "listItem: cannot list zero numner of items"
        );

        if (item.saleKind == SaleKind.Auction) {
            require(
                item.reservePrice >= item.basePrice,
                "listItem: Reserve price is lower than base price"
            );
            require(
                item.itemsAvailable == 1,
                "listItem: more than one copy for auction"
            );
        }

        marketItems[itemId] = listData;

        emit List(
            _msgSender(),
            item.nftAddress,
            itemId,
            item.tokenId,
            item.basePrice,
            item.itemsAvailable,
            item.listingTime,
            item.expirationTime,
            item.saleKind,
            voucher,
            signature
        );

        if (!item.lazyMint) {
            IERC1155(item.nftAddress).safeTransferFrom(
                _msgSender(),
                address(this),
                item.tokenId,
                item.itemsAvailable,
                ""
            );
        }
    }

    function cancelListing(uint256 _itemId) external itemExists(_itemId) {
        Item memory item_ = marketItems[_itemId];
        IERC1155 nft = IERC1155(item_.nftAddress);
        uint256 bid = itemBids[_itemId].maxBid;
        require(
            item_.seller == _msgSender(),
            "cancelListing: Unauthorized access"
        );
        if (item_.saleKind == SaleKind.Auction) {
            if (bid > 0) {
                _refund(bid, itemBids[_itemId].bidderAddress);
            }
        }

        uint256 id = item_.tokenId;
        uint256 amount = item_.itemsAvailable;
        bool islazyMint = item_.lazyMint;

        delete (marketItems[_itemId]);
        delete (itemBids[_itemId]);

        emit Cancel(_msgSender(), item_.nftAddress, _itemId, id, amount);

        if (islazyMint) {
            lazyListings[item_.tokenId] -= amount;
        } else {
            nft.safeTransferFrom(address(this), _msgSender(), id, amount, "");
        }
    }

    function makeBid(uint256 _itemId, uint256 _bidAmount)
        external
        itemExists(_itemId)
        nonReentrant
    {
        Item memory item_ = marketItems[_itemId];
        uint256 _oldBid = itemBids[_itemId].maxBid;

        require(
            _msgSender() != item_.seller,
            "makeBid: seller itself cannot bid"
        );

        require(
            item_.saleKind == SaleKind.Auction,
            "makeBid: Not listed for Auction"
        );
        require(
            item_.listingTime < block.timestamp,
            "makeBid: Sale not started"
        );
        require(
            item_.expirationTime > block.timestamp,
            "makeBid: Sale expired"
        );

        if (_oldBid == 0) {
            require(
                _bidAmount >= item_.basePrice,
                "makeBid: Bid lower than base price"
            );
        } else {
            require(
                _bidAmount >= _oldBid + (_oldBid * _bidRate) / 10000,
                "makeBid: Bid is not high enough"
            );
            _refund(_oldBid, itemBids[_itemId].bidderAddress);
        }
        emit BidOffered(
            _itemId,
            item_.tokenId,
            _msgSender(),
            item_.nftAddress,
            _bidAmount
        );

        itemBids[_itemId].maxBid = _bidAmount;
        itemBids[_itemId].bidderAddress = _msgSender();

        NembusToken.safeTransferFrom(_msgSender(), address(this), _bidAmount);
    }

    function acceptedOffer(
        uint256 _itemId,
        address _buyer,
        ILazyMinting.NFTVoucher calldata voucher,
        bytes memory signature
    ) external itemExists(_itemId) {
        Item memory item_ = marketItems[_itemId];

        require(
            item_.itemsAvailable >= voucher.nftAmount,
            "acceptedOffer: Not enough tokens on sale"
        );

        address signer = ILazyMinting(item_.nftAddress)._verify(
            voucher,
            signature
        );

        require(
            item_.saleKind == SaleKind.FixedPrice,
            "accetedOffer: not valid for auction sale"
        );

        require(signer == item_.seller, "acceptedOffer: unauthorized signer");

        uint256 _totalPrice = voucher.price * voucher.nftAmount;
        NembusToken.safeTransferFrom(_msgSender(), address(this), _totalPrice);

        emit Sold(
            _itemId,
            item_.seller,
            _msgSender(),
            item_.nftAddress,
            item_.tokenId,
            _totalPrice,
            voucher.nftAmount
        );

        if (item_.lazyMint) {
            _purchaseWithLazyMinting(
                _itemId,
                voucher.nftAmount,
                voucher.price * voucher.nftAmount,
                _buyer,
                voucher,
                signature
            );
        } else {
            _purchase(
                _itemId,
                voucher.price * voucher.nftAmount,
                voucher.nftAmount,
                _buyer
            );
        }
    }

    function buyItem(
        uint256 _itemId,
        uint256 _nftAmount,
        ILazyMinting.NFTVoucher calldata voucher,
        bytes memory signature
    ) external itemExists(_itemId) nonReentrant {
        Item memory item_ = marketItems[_itemId];
        require(
            _msgSender() != item_.seller,
            "buyItem: seller itself cannot buy"
        );
        require(
            item_.saleKind == SaleKind.FixedPrice,
            "buyItem: Not on fixed price sale"
        );
        require(
            item_.expirationTime > block.timestamp,
            "buyItem: Sale expired"
        );
        require(
            block.timestamp >= item_.listingTime,
            "buyItem: Sale not started"
        );
        require(
            item_.itemsAvailable >= _nftAmount,
            "buyItem: Not enough tokens on sale"
        );

        uint256 _totalPrice = item_.basePrice * _nftAmount;
        NembusToken.safeTransferFrom(_msgSender(), address(this), _totalPrice);

        emit Sold(
            _itemId,
            item_.seller,
            _msgSender(),
            item_.nftAddress,
            item_.tokenId,
            _totalPrice,
            _nftAmount
        );

        if (!item_.lazyMint) {
            _purchase(_itemId, _totalPrice, _nftAmount, _msgSender());
        } else {
            _purchaseWithLazyMinting(
                _itemId,
                _nftAmount,
                _totalPrice,
                _msgSender(),
                voucher,
                signature
            );
        }
    }

    function claimNFT(
        uint256 _itemId,
        ILazyMinting.NFTVoucher calldata voucher,
        bytes memory signature
    ) external itemExists(_itemId) {
        Item memory item_ = marketItems[_itemId];
        uint256 price = itemBids[_itemId].maxBid;
        uint256 _nftAmount = item_.itemsAvailable;

        require(
            block.timestamp > item_.expirationTime,
            "claimNFT: Auction process ongoing"
        );

        require(
            _msgSender() == itemBids[_itemId].bidderAddress,
            "claimNFT: Unauthorized access"
        );

        if (price < item_.reservePrice) {
            revert("claimNFT: Reserve price not met");
        }
        emit Sold(
            _itemId,
            item_.seller,
            _msgSender(),
            item_.nftAddress,
            item_.tokenId,
            price,
            _nftAmount
        );

        if (item_.lazyMint) {
            _purchaseWithLazyMinting(
                _itemId,
                _nftAmount,
                price,
                _msgSender(),
                voucher,
                signature
            );
        } else {
            _purchase(_itemId, price, _nftAmount, _msgSender());
        }
    }

    function retractOffer(uint256 _itemId) external itemExists(_itemId) {
        Item memory item_ = marketItems[_itemId];

        require(
            _msgSender() == itemBids[_itemId].bidderAddress,
            "retractOffer: Unauthorized access"
        );
        require(
            block.timestamp > item_.expirationTime,
            "retractOffer: Auction ongoing, cannot retract bid"
        );

        uint256 amount = itemBids[_itemId].maxBid;

        delete (itemBids[_itemId]);

        NembusToken.safeTransfer(_msgSender(), amount);

        emit OfferRetracted(
            _itemId,
            item_.tokenId,
            _msgSender(),
            item_.nftAddress,
            amount
        );
    }

    function withdrawServiceFee(address account) external onlyOwner {
        uint256 amount = _totalServiceFeeAmount;
        require(amount != 0, "withdrawServiceFee: Not sufficient funds");
        _totalServiceFeeAmount -= amount;
        NembusToken.safeTransfer(account, amount);
        emit ServiceFeeClaimed(account, amount);
    }

    function _purchaseWithLazyMinting(
        uint256 _itemId,
        uint256 _nftAmount,
        uint256 _totalPrice,
        address _buyer,
        ILazyMinting.NFTVoucher calldata voucher,
        bytes memory signature
    ) internal {
        Item storage item_ = marketItems[_itemId];

        item_.itemsAvailable -= _nftAmount;
        lazyListings[item_.tokenId] -= _nftAmount;

        ILazyMinting(item_.nftAddress).redeem(
            _buyer,
            voucher,
            _nftAmount,
            signature
        );

        uint256 serviceFee_ = _getServiceFee(_totalPrice);
        _totalServiceFeeAmount += serviceFee_;
        uint256 payment = _totalPrice - serviceFee_;
        NembusToken.safeTransfer(item_.seller, payment);

        if (item_.itemsAvailable == 0) {
            delete (marketItems[_itemId]);
            delete (itemBids[_itemId]);
        }
    }

    function _purchase(
        uint256 _itemId,
        uint256 _totalPrice,
        uint256 _nftAmount,
        address _buyer
    ) internal {
        Item storage item_ = marketItems[_itemId];
        (
            address[] memory _creators,
            uint256[] memory _royalties,
            uint256 _totalRoyalty
        ) = _getRoyalty(item_.nftAddress, item_.tokenId, _totalPrice);

        uint256 serviceFee_ = _getServiceFee(_totalPrice);
        uint256 payment = _totalPrice - _totalRoyalty - serviceFee_;
        item_.itemsAvailable -= _nftAmount;
        _totalServiceFeeAmount += serviceFee_;

        //Transferring payment to the seller
        NembusToken.safeTransfer(item_.seller, payment);

        //Transferring royalties to the recipients
        uint256 _length = _creators.length;
        for (uint256 i = 0; i < _length; i += 1) {
            emit TransferredRoyaltyToTheCreator(_creators[i], _royalties[i]);
            NembusToken.safeTransfer(_creators[i], _royalties[i]);
        }

        //Transferring the NFTs
        IERC1155(item_.nftAddress).safeTransferFrom(
            address(this),
            _buyer,
            item_.tokenId,
            _nftAmount,
            ""
        );

        if (item_.itemsAvailable == 0) {
            delete (marketItems[_itemId]);
            delete (itemBids[_itemId]);
        }
    }

    function _refund(uint256 amount, address receiver) internal {
        NembusToken.safeTransfer(receiver, amount);
    }

    function _getRoyalty(
        address _nftAddress,
        uint256 _tokenId,
        uint256 _amount
    )
        internal
        view
        returns (
            address[] memory recipients,
            uint256[] memory values,
            uint256 total
        )
    {
        (recipients, values, total) = ITokenRoyalties(_nftAddress).royaltyInfo(
            _tokenId,
            _amount
        );
    }

    function _getServiceFee(uint256 _amount) internal view returns (uint256) {
        return (_amount * _serviceFee) / 10000;
    }

    function _msgSender() internal view virtual override returns (address) {
        return msgSender();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

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
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;

import "./ERC1155Receiver.sol";

/**
 * Simple implementation of `ERC1155Receiver` that will allow a contract to hold ERC1155 tokens.
 *
 * IMPORTANT: When inheriting this contract, you must include a way to use the received tokens, otherwise they will be
 * stuck.
 *
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITokenRoyalties {
    function royaltyInfo(
        uint256 tokenId,
        uint256 value
    )
        external
        view
        returns (
            address[] memory receivers,
            uint256[] memory royalties,
            uint256 totalAmount
        );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

interface ILazyMinting {
    //@dev don't change the structure as it is being inherited in other contracts
    struct NFTVoucher {
        uint256 tokenId;
        uint256 nftAmount;
        uint256 price;
        uint256 startDate;
        uint256 endDate;
        address maker;
        address nftAddress;
        string tokenURI;
    }

    function redeem(
        address minter,
        NFTVoucher calldata voucher,
        uint256 nftAmount,
        bytes memory signture
    ) external;

    function setCreator(uint256 id, address _creator) external;

    function setMaxTokens(uint256 tokenId, uint256 amount) external;

    function setTokenRoyalty(
        uint256 id,
        uint256[] memory value,
        address[] memory recipient
    ) external;

    function _verify(NFTVoucher memory voucher, bytes memory _signature)
        external
        view
        returns (address);

    function totalSupply(uint256 tokenId) external view returns (uint256);

    function getCreator(uint256 tokenId) external view returns (address);

    function getMaxTokens(uint256 tokenId) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract BasicMetaTransaction {
    using SafeMath for uint256;

    //overriden emit for mogul
    event MetaTransactionExecuted(
        address userAddress,
        address payable relayerAddress,
        bytes functionSignature,
        bytes returnData
    );
    mapping(address => uint256) private nonces;

    function getChainID() public view returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }

    /**
     * Main function to be called when user wants to execute meta transaction.
     * The actual function to be called should be passed as param with name functionSignature
     * Here the basic signature recovery is being used. Signature is expected to be generated using
     * personal_sign method.
     * @param userAddress Address of user trying to do meta transaction
     * @param functionSignature Signature of the actual function to be called via meta transaction
     * @param sigR R part of the signature
     * @param sigS S part of the signature
     * @param sigV V part of the signature
     */
    function executeMetaTransaction(
        address userAddress,
        bytes memory functionSignature,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) public returns (bytes memory) {
        require(
            verify(
                userAddress,
                nonces[userAddress],
                getChainID(),
                functionSignature,
                sigR,
                sigS,
                sigV
            ),
            "Signer and signature do not match"
        );
        nonces[userAddress] = nonces[userAddress].add(1);

        // Append userAddress at the end to extract it from calling context
        (bool success, bytes memory returnData) = address(this).call(
            abi.encodePacked(functionSignature, userAddress)
        );

        require(success, "Function call not successful");
        emit MetaTransactionExecuted(
            userAddress,
            payable(msg.sender),
            functionSignature,
            returnData
        );
        return returnData;
    }

    function getNonce(address user) external view returns (uint256 nonce) {
        nonce = nonces[user];
    }

    // Builds a prefixed hash to mimic the behavior of eth_sign.
    function prefixed(bytes32 hash) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
            );
    }

    function verify(
        address owner,
        uint256 nonce,
        uint256 chainID,
        bytes memory functionSignature,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) public view returns (bool) {
        bytes32 hash = prefixed(
            keccak256(abi.encodePacked(nonce, this, chainID, functionSignature))
        );
        address signer = ecrecover(hash, sigV, sigR, sigS);
        require(signer != address(0), "Invalid signature");
        return (owner == signer);
    }

    function msgSender() internal view returns (address sender) {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
                // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender := and(
                    mload(add(array, index)),
                    0xffffffffffffffffffffffffffffffffffffffff
                )
            }
        } else {
            return msg.sender;
        }
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../IERC1155Receiver.sol";
import "../../../utils/introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
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
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}