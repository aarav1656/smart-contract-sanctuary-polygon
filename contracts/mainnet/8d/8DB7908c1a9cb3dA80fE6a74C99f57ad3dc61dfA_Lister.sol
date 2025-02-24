// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

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
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
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

pragma solidity ^0.8.17;

interface ISeaport {


 function validate(Order[] calldata orders)
 external
 returns (bool validated);

struct OrderComponents {
 address offerer;
 address zone;
 OfferItem[] offer;
 ConsiderationItem[] consideration;
 OrderType orderType;
 uint256 startTime;
 uint256 endTime;
 bytes32 zoneHash;
 uint256 salt;
 bytes32 conduitKey;
 uint256 counter;
}

/**
 * @dev An offer item has five components: an item type (ETH or other native
 * tokens, ERC20, ERC721, and ERC1155, as well as criteria-based ERC721 and
 * ERC1155), a token address, a dual-purpose "identifierOrCriteria"
 * component that will either represent a tokenId or a merkle root
 * depending on the item type, and a start and end amount that support
 * increasing or decreasing amounts over the duration of the respective
 * order.
 */
struct OfferItem {
 ItemType itemType;
 address token;
 uint256 identifierOrCriteria;
 uint256 startAmount;
 uint256 endAmount;
}

/**
 * @dev A consideration item has the same five components as an offer item and
 * an additional sixth component designating the required recipient of the
 * item.
 */
struct ConsiderationItem {
 ItemType itemType;
 address token;
 uint256 identifierOrCriteria;
 uint256 startAmount;
 uint256 endAmount;
 address payable recipient;
}

/**
 * @dev A spent item is translated from a utilized offer item and has four
 * components: an item type (ETH or other native tokens, ERC20, ERC721, and
 * ERC1155), a token address, a tokenId, and an amount.
 */
struct SpentItem {
 ItemType itemType;
 address token;
 uint256 identifier;
 uint256 amount;
}

/**
 * @dev A received item is translated from a utilized consideration item and has
 * the same four components as a spent item, as well as an additional fifth
 * component designating the required recipient of the item.
 */
struct ReceivedItem {
 ItemType itemType;
 address token;
 uint256 identifier;
 uint256 amount;
 address payable recipient;
}

/**
 * @dev For basic orders involving ETH / native / ERC20 <=> ERC721 / ERC1155
 * matching, a group of six functions may be called that only requires a
 * subset of the usual order arguments. Note the use of a "basicOrderType"
 * enum; this represents both the usual order type as well as the "route"
 * of the basic order (a simple derivation function for the basic order
 * type is `basicOrderType = orderType + (4 * basicOrderRoute)`.)
 */
struct BasicOrderParameters {
 // calldata offset
 address considerationToken; // 0x24
 uint256 considerationIdentifier; // 0x44
 uint256 considerationAmount; // 0x64
 address payable offerer; // 0x84
 address zone; // 0xa4
 address offerToken; // 0xc4
 uint256 offerIdentifier; // 0xe4
 uint256 offerAmount; // 0x104
 BasicOrderType basicOrderType; // 0x124
 uint256 startTime; // 0x144
 uint256 endTime; // 0x164
 bytes32 zoneHash; // 0x184
 uint256 salt; // 0x1a4
 bytes32 offererConduitKey; // 0x1c4
 bytes32 fulfillerConduitKey; // 0x1e4
 uint256 totalOriginalAdditionalRecipients; // 0x204
 AdditionalRecipient[] additionalRecipients; // 0x224
 bytes signature; // 0x244
 // Total length, excluding dynamic array data: 0x264 (580)
}

/**
 * @dev Basic orders can supply any number of additional recipients, with the
 * implied assumption that they are supplied from the offered ETH (or other
 * native token) or ERC20 token for the order.
 */
struct AdditionalRecipient {
 uint256 amount;
 address payable recipient;
}

/**
 * @dev The full set of order components, with the exception of the counter,
 * must be supplied when fulfilling more sophisticated orders or groups of
 * orders. The total number of original consideration items must also be
 * supplied, as the caller may specify additional consideration items.
 */
struct OrderParameters {
 address offerer; // 0x00
 address zone; // 0x20
 OfferItem[] offer; // 0x40
 ConsiderationItem[] consideration; // 0x60
 OrderType orderType; // 0x80
 uint256 startTime; // 0xa0
 uint256 endTime; // 0xc0
 bytes32 zoneHash; // 0xe0
 uint256 salt; // 0x100
 bytes32 conduitKey; // 0x120
 uint256 totalOriginalConsiderationItems; // 0x140
 // offer.length // 0x160
}

/**
 * @dev Orders require a signature in addition to the other order parameters.
 */
struct Order {
 OrderParameters parameters;
 bytes signature;
}

/**
 * @dev Advanced orders include a numerator (i.e. a fraction to attempt to fill)
 * and a denominator (the total size of the order) in addition to the
 * signature and other order parameters. It also supports an optional field
 * for supplying extra data; this data will be included in a staticcall to
 * `isValidOrderIncludingExtraData` on the zone for the order if the order
 * type is restricted and the offerer or zone are not the caller.
 */
struct AdvancedOrder {
 OrderParameters parameters;
 uint120 numerator;
 uint120 denominator;
 bytes signature;
 bytes extraData;
}

/**
 * @dev Orders can be validated (either explicitly via `validate`, or as a
 * consequence of a full or partial fill), specifically cancelled (they can
 * also be cancelled in bulk via incrementing a per-zone counter), and
 * partially or fully filled (with the fraction filled represented by a
 * numerator and denominator).
 */
struct OrderStatus {
 bool isValidated;
 bool isCancelled;
 uint120 numerator;
 uint120 denominator;
}

/**
 * @dev A criteria resolver specifies an order, side (offer vs. consideration),
 * and item index. It then provides a chosen identifier (i.e. tokenId)
 * alongside a merkle proof demonstrating the identifier meets the required
 * criteria.
 */
struct CriteriaResolver {
 uint256 orderIndex;
 Side side;
 uint256 index;
 uint256 identifier;
 bytes32[] criteriaProof;
}

/**
 * @dev A fulfillment is applied to a group of orders. It decrements a series of
 * offer and consideration items, then generates a single execution
 * element. A given fulfillment can be applied to as many offer and
 * consideration items as desired, but must contain at least one offer and
 * at least one consideration that match. The fulfillment must also remain
 * consistent on all key parameters across all offer items (same offerer,
 * token, type, tokenId, and conduit preference) as well as across all
 * consideration items (token, type, tokenId, and recipient).
 */
struct Fulfillment {
 FulfillmentComponent[] offerComponents;
 FulfillmentComponent[] considerationComponents;
}

/**
 * @dev Each fulfillment component contains one index referencing a specific
 * order and another referencing a specific offer or consideration item.
 */
struct FulfillmentComponent {
 uint256 orderIndex;
 uint256 itemIndex;
}

/**
 * @dev An execution is triggered once all consideration items have been zeroed
 * out. It sends the item in question from the offerer to the item's
 * recipient, optionally sourcing approvals from either this contract
 * directly or from the offerer's chosen conduit if one is specified. An
 * execution is not provided as an argument, but rather is derived via
 * orders, criteria resolvers, and fulfillments (where the total number of
 * executions will be less than or equal to the total number of indicated
 * fulfillments) and returned as part of `matchOrders`.
 */
struct Execution {
 ReceivedItem item;
 address offerer;
 bytes32 conduitKey;
}

enum OrderType {
 // 0: no partial fills, anyone can execute
 FULL_OPEN,

 // 1: partial fills supported, anyone can execute
 PARTIAL_OPEN,

 // 2: no partial fills, only offerer or zone can execute
 FULL_RESTRICTED,

 // 3: partial fills supported, only offerer or zone can execute
 PARTIAL_RESTRICTED
}

// prettier-ignore
enum BasicOrderType {
 // 0: no partial fills, anyone can execute
 ETH_TO_ERC721_FULL_OPEN,

 // 1: partial fills supported, anyone can execute
 ETH_TO_ERC721_PARTIAL_OPEN,

 // 2: no partial fills, only offerer or zone can execute
 ETH_TO_ERC721_FULL_RESTRICTED,

 // 3: partial fills supported, only offerer or zone can execute
 ETH_TO_ERC721_PARTIAL_RESTRICTED,

 // 4: no partial fills, anyone can execute
 ETH_TO_ERC1155_FULL_OPEN,

 // 5: partial fills supported, anyone can execute
 ETH_TO_ERC1155_PARTIAL_OPEN,

 // 6: no partial fills, only offerer or zone can execute
 ETH_TO_ERC1155_FULL_RESTRICTED,

 // 7: partial fills supported, only offerer or zone can execute
 ETH_TO_ERC1155_PARTIAL_RESTRICTED,

 // 8: no partial fills, anyone can execute
 ERC20_TO_ERC721_FULL_OPEN,

 // 9: partial fills supported, anyone can execute
 ERC20_TO_ERC721_PARTIAL_OPEN,

 // 10: no partial fills, only offerer or zone can execute
 ERC20_TO_ERC721_FULL_RESTRICTED,

 // 11: partial fills supported, only offerer or zone can execute
 ERC20_TO_ERC721_PARTIAL_RESTRICTED,

 // 12: no partial fills, anyone can execute
 ERC20_TO_ERC1155_FULL_OPEN,

 // 13: partial fills supported, anyone can execute
 ERC20_TO_ERC1155_PARTIAL_OPEN,

 // 14: no partial fills, only offerer or zone can execute
 ERC20_TO_ERC1155_FULL_RESTRICTED,

 // 15: partial fills supported, only offerer or zone can execute
 ERC20_TO_ERC1155_PARTIAL_RESTRICTED,

 // 16: no partial fills, anyone can execute
 ERC721_TO_ERC20_FULL_OPEN,

 // 17: partial fills supported, anyone can execute
 ERC721_TO_ERC20_PARTIAL_OPEN,

 // 18: no partial fills, only offerer or zone can execute
 ERC721_TO_ERC20_FULL_RESTRICTED,

 // 19: partial fills supported, only offerer or zone can execute
 ERC721_TO_ERC20_PARTIAL_RESTRICTED,

 // 20: no partial fills, anyone can execute
 ERC1155_TO_ERC20_FULL_OPEN,

 // 21: partial fills supported, anyone can execute
 ERC1155_TO_ERC20_PARTIAL_OPEN,

 // 22: no partial fills, only offerer or zone can execute
 ERC1155_TO_ERC20_FULL_RESTRICTED,

 // 23: partial fills supported, only offerer or zone can execute
 ERC1155_TO_ERC20_PARTIAL_RESTRICTED
}

// prettier-ignore
enum BasicOrderRouteType {
 // 0: provide Ether (or other native token) to receive offered ERC721 item.
 ETH_TO_ERC721,

 // 1: provide Ether (or other native token) to receive offered ERC1155 item.
 ETH_TO_ERC1155,

 // 2: provide ERC20 item to receive offered ERC721 item.
 ERC20_TO_ERC721,

 // 3: provide ERC20 item to receive offered ERC1155 item.
 ERC20_TO_ERC1155,

 // 4: provide ERC721 item to receive offered ERC20 item.
 ERC721_TO_ERC20,

 // 5: provide ERC1155 item to receive offered ERC20 item.
 ERC1155_TO_ERC20
}

// prettier-ignore
enum ItemType {
 // 0: ETH on mainnet, MATIC on polygon, etc.
 NATIVE,

 // 1: ERC20 items (ERC777 and ERC20 analogues could also technically work)
 ERC20,

 // 2: ERC721 items
 ERC721,

 // 3: ERC1155 items
 ERC1155,

 // 4: ERC721 items where a number of tokenIds are supported
 ERC721_WITH_CRITERIA,

 // 5: ERC1155 items where a number of ids are supported
 ERC1155_WITH_CRITERIA
}

// prettier-ignore
enum Side {
 // 0: Items that can be spent
 OFFER,

 // 1: Items that must be received
 CONSIDERATION
}

}

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "./interfaces/ISeaport.sol";
//0x0000007b02230091a7ed01230072f7006a004d60a8d4e71d599b8104250f0000
//0x0000007b02230091a7ed01230072f7006a004d60a8d4e71d599b8104250f0000



//seaport 1.4 0x00000000000001ad428e4906aE43D8F9852d0dD6
//potentially old seaport 0x00000000006c3852cbEf3e08E8dF289169EdE581
contract Lister {
    ISeaport public seaport;
    IERC721 public nft;
    address constant ZERO_ADDRESS = 0x0000000000000000000000000000000000000000;
    address constant _seaport = 0x00000000000001ad428e4906aE43D8F9852d0dD6;
    uint256 public deployCheck = 1;
    
    constructor()  {
        seaport = ISeaport(_seaport);
    }


    function setNFT(address _nft) external {
        nft = IERC721(_nft);
    }

    function listFuture(uint256 _tokenId, bytes32 _conduitKey) external {
        nft.setApprovalForAll(address(seaport), true);
        nft.setApprovalForAll(0x1E0049783F008A0085193E00003D00cd54003c71, true);
        ISeaport.OrderType ordertype1 = ISeaport.OrderType.FULL_OPEN;
    


    ISeaport.Order[] memory orders = new ISeaport.Order[](1);
    ISeaport.Order memory order = orders[0];
    ISeaport.OrderParameters memory orderParams = order.parameters;


    orderParams.offerer = address(this);
    orderParams.startTime = block.timestamp;
    orderParams.endTime = block.timestamp + 1 weeks;
    orderParams.zone = ZERO_ADDRESS;
    orderParams.orderType = ordertype1;
    orderParams.salt = 123456;
    orderParams.conduitKey = _conduitKey;
    orderParams.totalOriginalConsiderationItems = 2;
    //we are sellling
    orderParams.offer = new ISeaport.OfferItem[](1);
    ISeaport.OfferItem memory offer = orderParams.offer[0];
    offer.itemType = ISeaport.ItemType.ERC721;
    offer.token = address(nft);
    offer.identifierOrCriteria = _tokenId;
    offer.startAmount = 1;
    offer.endAmount = 1;
    //we are buying
    orderParams.consideration = new ISeaport.ConsiderationItem[](2);
    ISeaport.ConsiderationItem memory consideration = orderParams.consideration[0];
    consideration.itemType = ISeaport.ItemType.NATIVE;
    consideration.token = ZERO_ADDRESS;
    consideration.identifierOrCriteria = 0;
    consideration.startAmount = 1000000000000000000;
    consideration.endAmount = 1000000000000000000;
    consideration.recipient = payable(address(this));

    consideration = orderParams.consideration[1];
    consideration.itemType = ISeaport.ItemType.NATIVE;
    consideration.token = ZERO_ADDRESS;
    consideration.identifierOrCriteria = 0;
    consideration.startAmount = 100000000000000000 * 25 / 1000;
    consideration.endAmount = 100000000000000000 * 25 / 1000;
    consideration.recipient = payable(0x0000a26b00c1F0DF003000390027140000fAa719);
    order.signature = "0x";

    assert(seaport.validate(orders));


    }

}