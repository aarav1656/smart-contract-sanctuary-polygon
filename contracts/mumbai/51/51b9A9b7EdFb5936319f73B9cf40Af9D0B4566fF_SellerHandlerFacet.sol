// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "../../domain/BosonConstants.sol";
import { IBosonVoucher } from "../../interfaces/clients/IBosonVoucher.sol";
import { SellerBase } from "../bases/SellerBase.sol";
import { ProtocolLib } from "../libs/ProtocolLib.sol";
import { IERC721 } from "../../interfaces/IERC721.sol";

contract SellerHandlerFacet is SellerBase {
    /**
     * @notice Facet Initializer
     */
    function initialize() public {
        // No-op initializer.
        // - needed by the deployment script, which expects a no-args initializer on facets other than the config handler
        // - exception here because IBosonAccountHandler is contributed to by multiple facets which do not have their own individual interfaces
    }

    /**
     * @notice Creates a seller
     *
     * Emits a SellerCreated event if successful.
     *
     * Reverts if:
     * - Address values are zero address
     * - Addresses are not unique to this seller
     * - Seller is not active (if active == false)
     * - Admin address is zero address and AuthTokenType == None
     * - AuthTokenType is not unique to this seller
     *
     * @param _seller - the fully populated struct with seller id set to 0x0
     * @param _authToken - optional AuthToken struct that specifies an AuthToken type and tokenId that the user can use to do admin functions
     * @param _voucherInitValues - the fully populated BosonTypes.VoucherInitValues struct
     */
    function createSeller(
        Seller memory _seller,
        AuthToken calldata _authToken,
        VoucherInitValues calldata _voucherInitValues
    ) external {
        // create seller and update structs values to represent true state
        createSellerInternal(_seller, _authToken, _voucherInitValues);
    }

    /**
     * @notice Updates a seller. All fields should be filled, even those staying the same.
     *
     * Emits a SellerUpdated event if successful.
     *
     * Reverts if:
     * - Address values are zero address
     * - Addresses are not unique to this seller
     * - Caller is not the admin address of the seller
     * - Seller does not exist
     * - Admin address is zero address and AuthTokenType == None
     * - AuthTokenType is not unique to this seller
     *
     * @param _seller - the fully populated seller struct
     * @param _authToken - optional AuthToken struct that specifies an AuthToken type and tokenId that the user can use to do admin functions
     */
    function updateSeller(Seller memory _seller, AuthToken calldata _authToken) external {
        bool exists;
        Seller storage seller;
        AuthToken storage authToken;

        //Admin address or AuthToken data must be present. A seller can have one or the other
        require(
            (_seller.admin == address(0) && _authToken.tokenType != AuthTokenType.None) ||
                (_seller.admin != address(0) && _authToken.tokenType == AuthTokenType.None),
            ADMIN_OR_AUTH_TOKEN
        );

        //Check Seller exists in sellers mapping
        (exists, seller, authToken) = fetchSeller(_seller.id);

        //Seller must already exist
        require(exists, NO_SUCH_SELLER);

        //Check that caller is authorized to call this function
        if (seller.admin == address(0)) {
            address authTokenContract = protocolLookups().authTokenContracts[authToken.tokenType];
            address tokenIdOwner = IERC721(authTokenContract).ownerOf(authToken.tokenId);
            require(tokenIdOwner == msgSender(), NOT_ADMIN);
        } else {
            require(seller.admin == msgSender(), NOT_ADMIN);
        }

        //Check that the passed in addresses are unique to one seller Id across all roles -- not used or are used by this seller id.
        //Checking this seller id is necessary because one or more addresses may not change
        require(
            (protocolLookups().sellerIdByOperator[_seller.operator] == 0 ||
                protocolLookups().sellerIdByOperator[_seller.operator] == _seller.id) &&
                (protocolLookups().sellerIdByOperator[_seller.clerk] == 0 ||
                    protocolLookups().sellerIdByOperator[_seller.clerk] == _seller.id) &&
                (protocolLookups().sellerIdByAdmin[_seller.operator] == 0 ||
                    protocolLookups().sellerIdByAdmin[_seller.operator] == _seller.id) &&
                (protocolLookups().sellerIdByAdmin[_seller.clerk] == 0 ||
                    protocolLookups().sellerIdByAdmin[_seller.clerk] == _seller.id) &&
                (protocolLookups().sellerIdByClerk[_seller.operator] == 0 ||
                    protocolLookups().sellerIdByClerk[_seller.operator] == _seller.id) &&
                (protocolLookups().sellerIdByClerk[_seller.clerk] == 0 ||
                    protocolLookups().sellerIdByClerk[_seller.clerk] == _seller.id),
            SELLER_ADDRESS_MUST_BE_UNIQUE
        );

        //Admin address or AuthToken data must be present in parameters. A seller can have one or the other. Check passed in parameters
        if (_seller.admin == address(0)) {
            //Check that auth token is unique to this seller
            require(
                protocolLookups().sellerIdByAuthToken[_authToken.tokenType][_authToken.tokenId] == 0 ||
                    protocolLookups().sellerIdByAuthToken[_authToken.tokenType][_authToken.tokenId] == _seller.id,
                AUTH_TOKEN_MUST_BE_UNIQUE
            );
        } else {
            //Check that the admin address is unique to one seller Id across all roles -- not used or is used by this seller id.

            require(
                (protocolLookups().sellerIdByOperator[_seller.admin] == 0 ||
                    protocolLookups().sellerIdByOperator[_seller.admin] == _seller.id) &&
                    (protocolLookups().sellerIdByAdmin[_seller.admin] == 0 ||
                        protocolLookups().sellerIdByAdmin[_seller.admin] == _seller.id) &&
                    (protocolLookups().sellerIdByClerk[_seller.admin] == 0 ||
                        protocolLookups().sellerIdByClerk[_seller.admin] == _seller.id),
                SELLER_ADDRESS_MUST_BE_UNIQUE
            );
        }

        //Delete current mappings
        delete protocolLookups().sellerIdByOperator[seller.operator];
        delete protocolLookups().sellerIdByAdmin[seller.admin];
        delete protocolLookups().sellerIdByClerk[seller.clerk];
        delete protocolLookups().sellerIdByAuthToken[authToken.tokenType][authToken.tokenId];
        delete protocolEntities().authTokens[seller.id];

        // store this address of existing seller operator to check if you have to transfer the ownership later
        address oldSellerOperator = seller.operator;

        storeSeller(_seller, _authToken);

        // If operator changed, transfer the ownership of NFT voucher
        if (oldSellerOperator != _seller.operator) {
            IBosonVoucher(protocolLookups().cloneAddress[seller.id]).transferOwnership(_seller.operator);
        }

        // Notify watchers of state change
        emit SellerUpdated(_seller.id, _seller, _authToken, msgSender());
    }

    /**
     * @notice Gets the details about a seller.
     *
     * @param _sellerId - the id of the seller to check
     * @return exists - the seller was found
     * @return seller - the seller details. See {BosonTypes.Seller}
     * @return authToken - optional AuthToken struct that specifies an AuthToken type and tokenId that the user can use to do admin functions
     */
    function getSeller(uint256 _sellerId)
        external
        view
        returns (
            bool exists,
            Seller memory seller,
            AuthToken memory authToken
        )
    {
        return fetchSeller(_sellerId);
    }

    /**
     * @notice Gets the details about a seller by an address associated with that seller: operator, admin, or clerk address.
     *         N.B.: If seller's admin uses NFT Auth they should call `getSellerByAuthToken` instead.
     *
     * @param _associatedAddress - the address associated with the seller. Must be an operator, admin, or clerk address.
     * @return exists - the seller was found
     * @return seller - the seller details. See {BosonTypes.Seller}
     * @return authToken - optional AuthToken struct that specifies an AuthToken type and tokenId that the user can use to do admin functions
     *                     See {BosonTypes.AuthToken}
     */
    function getSellerByAddress(address _associatedAddress)
        external
        view
        returns (
            bool exists,
            Seller memory seller,
            AuthToken memory authToken
        )
    {
        uint256 sellerId;

        (exists, sellerId) = getSellerIdByOperator(_associatedAddress);
        if (exists) {
            return fetchSeller(sellerId);
        }

        (exists, sellerId) = getSellerIdByAdmin(_associatedAddress);
        if (exists) {
            return fetchSeller(sellerId);
        }

        (exists, sellerId) = getSellerIdByClerk(_associatedAddress);
        if (exists) {
            return fetchSeller(sellerId);
        }
    }

    /**
     * @notice Gets the details about a seller by an auth token associated with that seller.
     *         A seller will have either an admin address or an auth token
     *
     * @param _associatedAuthToken - the auth token that may be associated with the seller.
     * @return exists - the seller was found
     * @return seller - the seller details. See {BosonTypes.Seller}
     * @return authToken - optional AuthToken struct that specifies an AuthToken type and tokenId that the user can use to do admin functions
     *                     See {BosonTypes.AuthToken}
     */
    function getSellerByAuthToken(AuthToken calldata _associatedAuthToken)
        external
        view
        returns (
            bool exists,
            Seller memory seller,
            AuthToken memory authToken
        )
    {
        uint256 sellerId;

        (exists, sellerId) = getSellerIdByAuthToken(_associatedAuthToken);
        if (exists) {
            return fetchSeller(sellerId);
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

// Access Control Roles
bytes32 constant ADMIN = keccak256("ADMIN"); // Role Admin
bytes32 constant PROTOCOL = keccak256("PROTOCOL"); // Role for facets of the ProtocolDiamond
bytes32 constant CLIENT = keccak256("CLIENT"); // Role for clients of the ProtocolDiamond
bytes32 constant UPGRADER = keccak256("UPGRADER"); // Role for performing contract and config upgrades
bytes32 constant FEE_COLLECTOR = keccak256("FEE_COLLECTOR"); // Role for collecting fees from the protocol

// Revert Reasons: General
string constant INVALID_ADDRESS = "Invalid address";
string constant INVALID_STATE = "Invalid state";
string constant ARRAY_LENGTH_MISMATCH = "Array length mismatch";

// Revert Reasons: Facet initializer related
string constant ALREADY_INITIALIZED = "Already initialized";

// Revert Reasons: Access related
string constant ACCESS_DENIED = "Access denied, caller doesn't have role";
string constant NOT_OPERATOR = "Not seller's operator";
string constant NOT_ADMIN = "Not admin";
string constant NOT_BUYER_OR_SELLER = "Not buyer or seller";
string constant NOT_VOUCHER_HOLDER = "Not current voucher holder";
string constant NOT_BUYER_WALLET = "Not buyer's wallet address";
string constant NOT_AGENT_WALLET = "Not agent's wallet address";
string constant NOT_DISPUTE_RESOLVER_OPERATOR = "Not dispute resolver's operator address";

// Revert Reasons: Account-related
string constant NO_SUCH_SELLER = "No such seller";
string constant MUST_BE_ACTIVE = "Account must be active";
string constant SELLER_ADDRESS_MUST_BE_UNIQUE = "Seller address cannot be assigned to another seller Id";
string constant BUYER_ADDRESS_MUST_BE_UNIQUE = "Buyer address cannot be assigned to another buyer Id";
string constant DISPUTE_RESOLVER_ADDRESS_MUST_BE_UNIQUE = "Dispute Resolver address cannot be assigned to another dispute resolver Id";
string constant AGENT_ADDRESS_MUST_BE_UNIQUE = "Agent address cannot be assigned to another agent Id";
string constant NO_SUCH_BUYER = "No such buyer";
string constant NO_SUCH_AGENT = "No such agent";
string constant WALLET_OWNS_VOUCHERS = "Wallet address owns vouchers";
string constant NO_SUCH_DISPUTE_RESOLVER = "No such dispute resolver";
string constant INVALID_ESCALATION_PERIOD = "Invalid escalation period";
string constant INVALID_AMOUNT_DISPUTE_RESOLVER_FEES = "Dispute resolver fees are not present or exceeds maximum dispute resolver fees in a single transaction";
string constant DUPLICATE_DISPUTE_RESOLVER_FEES = "Duplicate dispute resolver fee";
string constant DISPUTE_RESOLVER_FEE_NOT_FOUND = "Dispute resolver fee not found";
string constant SELLER_ALREADY_APPROVED = "Seller id is approved already";
string constant SELLER_NOT_APPROVED = "Seller id is not approved";
string constant INVALID_AMOUNT_ALLOWED_SELLERS = "Allowed sellers not present or exceeds maximum allowed sellers in a single transaction";
string constant INVALID_AUTH_TOKEN_TYPE = "Invalid AuthTokenType";
string constant ADMIN_OR_AUTH_TOKEN = "An admin address or an auth token is required";
string constant AUTH_TOKEN_MUST_BE_UNIQUE = "Auth token cannot be assigned to another entity of the same type";

// Revert Reasons: Offer related
string constant NO_SUCH_OFFER = "No such offer";
string constant OFFER_PERIOD_INVALID = "Offer period invalid";
string constant OFFER_PENALTY_INVALID = "Offer penalty invalid";
string constant OFFER_MUST_BE_ACTIVE = "Offer must be active";
string constant OFFER_NOT_UPDATEABLE = "Offer not updateable";
string constant OFFER_MUST_BE_UNIQUE = "Offer must be unique to a group";
string constant OFFER_HAS_BEEN_VOIDED = "Offer has been voided";
string constant OFFER_HAS_EXPIRED = "Offer has expired";
string constant OFFER_NOT_AVAILABLE = "Offer is not yet available";
string constant OFFER_SOLD_OUT = "Offer has sold out";
string constant CANNOT_COMMIT = "Caller cannot commit";
string constant EXCHANGE_FOR_OFFER_EXISTS = "Exchange for offer exists";
string constant AMBIGUOUS_VOUCHER_EXPIRY = "Exactly one of voucherRedeemableUntil and voucherValid must be non zero";
string constant REDEMPTION_PERIOD_INVALID = "Redemption period invalid";
string constant INVALID_FULFILLMENT_PERIOD = "Invalid fulfillemnt period";
string constant INVALID_DISPUTE_DURATION = "Invalid dispute duration";
string constant INVALID_DISPUTE_RESOLVER = "Invalid dispute resolver";
string constant INVALID_QUANTITY_AVAILABLE = "Invalid quantity available";
string constant DR_UNSUPPORTED_FEE = "Dispute resolver does not accept this token";
string constant AGENT_FEE_AMOUNT_TOO_HIGH = "Sum of Agent fee amount and protocol fee amount should be <= offer fee limit";

// Revert Reasons: Group related
string constant NO_SUCH_GROUP = "No such group";
string constant OFFER_NOT_IN_GROUP = "Offer not part of the group";
string constant TOO_MANY_OFFERS = "Exceeded maximum offers in a single transaction";
string constant NOTHING_UPDATED = "Nothing updated";
string constant INVALID_CONDITION_PARAMETERS = "Invalid condition parameters";

// Revert Reasons: Exchange related
string constant NO_SUCH_EXCHANGE = "No such exchange";
string constant FULFILLMENT_PERIOD_NOT_ELAPSED = "Fulfillment period has not yet elapsed";
string constant VOUCHER_NOT_REDEEMABLE = "Voucher not yet valid or already expired";
string constant VOUCHER_EXTENSION_NOT_VALID = "Proposed date is not later than the current one";
string constant VOUCHER_STILL_VALID = "Voucher still valid";
string constant VOUCHER_HAS_EXPIRED = "Voucher has expired";
string constant TOO_MANY_EXCHANGES = "Exceeded maximum exchanges in a single transaction";

// Revert Reasons: Twin related
string constant NO_SUCH_TWIN = "No such twin";
string constant NO_TRANSFER_APPROVED = "No transfer approved";
string constant TWIN_TRANSFER_FAILED = "Twin could not be transferred";
string constant UNSUPPORTED_TOKEN = "Unsupported token";
string constant BUNDLE_FOR_TWIN_EXISTS = "Bundle for twin exists";
string constant INVALID_SUPPLY_AVAILABLE = "supplyAvailable can't be zero";
string constant INVALID_AMOUNT = "Amount must be greater than zero if token is ERC20 or ERC1155";
string constant INVALID_TWIN_PROPERTY = "Invalid property for selected token type";
string constant INVALID_TWIN_TOKEN_RANGE = "Token range is already being used in another Twin";
string constant INVALID_TOKEN_ADDRESS = "Token address is a contract that doesn't implement the interface for selected token type";

// Revert Reasons: Bundle related
string constant NO_SUCH_BUNDLE = "No such bundle";
string constant TWIN_NOT_IN_BUNDLE = "Twin not part of the bundle";
string constant OFFER_NOT_IN_BUNDLE = "Offer not part of the bundle";
string constant TOO_MANY_TWINS = "Exceeded maximum twins in a single transaction";
string constant BUNDLE_OFFER_MUST_BE_UNIQUE = "Offer must be unique to a bundle";
string constant BUNDLE_TWIN_MUST_BE_UNIQUE = "Twin must be unique to a bundle";
string constant EXCHANGE_FOR_BUNDLED_OFFERS_EXISTS = "Exchange for the bundled offers exists";
string constant INSUFFICIENT_TWIN_SUPPLY_TO_COVER_BUNDLE_OFFERS = "Insufficient twin supplyAvailable to cover total quantity of bundle offers";

// Revert Reasons: Funds related
string constant NATIVE_WRONG_ADDRESS = "Native token address must be 0";
string constant NATIVE_WRONG_AMOUNT = "Transferred value must match amount";
string constant TOKEN_NAME_UNSPECIFIED = "Token name unspecified";
string constant NATIVE_CURRENCY = "Native currency";
string constant TOO_MANY_TOKENS = "Too many tokens";
string constant TOKEN_AMOUNT_MISMATCH = "Number of amounts should match number of tokens";
string constant NOTHING_TO_WITHDRAW = "Nothing to withdraw";
string constant NOT_AUTHORIZED = "Not authorized to withdraw";
string constant TOKEN_TRANSFER_FAILED = "Token transfer failed";
string constant INSUFFICIENT_VALUE_SENT = "Insufficient value sent";
string constant INSUFFICIENT_AVAILABLE_FUNDS = "Insufficient available funds";
string constant NATIVE_NOT_ALLOWED = "Transfer of native currency not allowed";

// Revert Reasons: Meta-Transactions related
string constant NONCE_USED_ALREADY = "Nonce used already";
string constant FUNCTION_CALL_NOT_SUCCESSFUL = "Function call not successful";
string constant INVALID_FUNCTION_SIGNATURE = "functionSignature can not be of executeMetaTransaction method";
string constant SIGNER_AND_SIGNATURE_DO_NOT_MATCH = "Signer and signature do not match";
string constant INVALID_FUNCTION_NAME = "Invalid function name";
string constant INVALID_SIGNATURE = "Invalid signature";

// Revert Reasons: Dispute related
string constant COMPLAINT_MISSING = "Complaint missing";
string constant FULFILLMENT_PERIOD_HAS_ELAPSED = "Fulfillment period has already elapsed";
string constant DISPUTE_HAS_EXPIRED = "Dispute has expired";
string constant INVALID_BUYER_PERCENT = "Invalid buyer percent";
string constant DISPUTE_STILL_VALID = "Dispute still valid";
string constant INVALID_DISPUTE_TIMEOUT = "Invalid dispute timeout";
string constant TOO_MANY_DISPUTES = "Exceeded maximum disputes in a single transaction";
string constant ESCALATION_NOT_ALLOWED = "Disputes without dispute resolver cannot be escalated";

// Revert Reasons: Config related
string constant FEE_PERCENTAGE_INVALID = "Percentage representation must be less than 10000";

// EIP712Lib
bytes32 constant EIP712_DOMAIN_TYPEHASH = keccak256(
    bytes("EIP712Domain(string name,string version,address verifyingContract,bytes32 salt)")
);

// BosonVoucher
string constant VOUCHER_NAME = "Boson Voucher";
string constant VOUCHER_SYMBOL = "BOSON_VOUCHER";

// Meta Transations - Structs
bytes32 constant META_TRANSACTION_TYPEHASH = keccak256(
    bytes(
        "MetaTransaction(uint256 nonce,address from,address contractAddress,string functionName,bytes functionSignature)"
    )
);
bytes32 constant OFFER_DETAILS_TYPEHASH = keccak256("MetaTxOfferDetails(address buyer,uint256 offerId)");
bytes32 constant META_TX_COMMIT_TO_OFFER_TYPEHASH = keccak256(
    "MetaTxCommitToOffer(uint256 nonce,address from,address contractAddress,string functionName,MetaTxOfferDetails offerDetails)MetaTxOfferDetails(address buyer,uint256 offerId)"
);
bytes32 constant EXCHANGE_DETAILS_TYPEHASH = keccak256("MetaTxExchangeDetails(uint256 exchangeId)");
bytes32 constant META_TX_EXCHANGE_TYPEHASH = keccak256(
    "MetaTxExchange(uint256 nonce,address from,address contractAddress,string functionName,MetaTxExchangeDetails exchangeDetails)MetaTxExchangeDetails(uint256 exchangeId)"
);
bytes32 constant FUND_DETAILS_TYPEHASH = keccak256(
    "MetaTxFundDetails(uint256 entityId,address[] tokenList,uint256[] tokenAmounts)"
);
bytes32 constant META_TX_FUNDS_TYPEHASH = keccak256(
    "MetaTxFund(uint256 nonce,address from,address contractAddress,string functionName,MetaTxFundDetails fundDetails)MetaTxFundDetails(uint256 entityId,address[] tokenList,uint256[] tokenAmounts)"
);
bytes32 constant DISPUTE_DETAILS_TYPEHASH = keccak256("MetaTxDisputeDetails(uint256 exchangeId,string complaint)");
bytes32 constant META_TX_DISPUTES_TYPEHASH = keccak256(
    "MetaTxDispute(uint256 nonce,address from,address contractAddress,string functionName,MetaTxDisputeDetails disputeDetails)MetaTxDisputeDetails(uint256 exchangeId,string complaint)"
);
bytes32 constant DISPUTE_RESOLUTION_DETAILS_TYPEHASH = keccak256(
    "MetaTxDisputeResolutionDetails(uint256 exchangeId,uint256 buyerPercent,bytes32 sigR,bytes32 sigS,uint8 sigV)"
);
bytes32 constant META_TX_DISPUTE_RESOLUTIONS_TYPEHASH = keccak256(
    "MetaTxDisputeResolution(uint256 nonce,address from,address contractAddress,string functionName,MetaTxDisputeResolutionDetails disputeResolutionDetails)MetaTxDisputeResolutionDetails(uint256 exchangeId,uint256 buyerPercent,bytes32 sigR,bytes32 sigS,uint8 sigV)"
);

// Function names
string constant COMMIT_TO_OFFER = "commitToOffer(address,uint256)";
string constant CANCEL_VOUCHER = "cancelVoucher(uint256)";
string constant REDEEM_VOUCHER = "redeemVoucher(uint256)";
string constant COMPLETE_EXCHANGE = "completeExchange(uint256)";
string constant WITHDRAW_FUNDS = "withdrawFunds(uint256,address[],uint256[])";
string constant RETRACT_DISPUTE = "retractDispute(uint256)";
string constant RAISE_DISPUTE = "raiseDispute(uint256,string)";
string constant ESCALATE_DISPUTE = "escalateDispute(uint256)";
string constant RESOLVE_DISPUTE = "resolveDispute(uint256,uint256,bytes32,bytes32,uint8)";

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import { IERC721Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import { IERC721MetadataUpgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721MetadataUpgradeable.sol";
import { BosonTypes } from "../../domain/BosonTypes.sol";

/**
 * @title IBosonVoucher
 *
 * @notice This is the interface for the Boson Protocol ERC-721 Voucher NFT contract.
 *
 * The ERC-165 identifier for this interface is: 0x2b2ac434
 */
interface IBosonVoucher is IERC721Upgradeable, IERC721MetadataUpgradeable {
    event ContractURIChanged(string contractURI);
    event RoyaltyPercentageChanged(uint96 royaltyPercentage);

    /**
     * @notice Issue a voucher to a buyer
     *
     * Minted voucher supply is sent to the buyer.
     * Caller must have PROTOCOL role.
     *
     * @param _exchangeId - the id of the exchange (corresponds to the ERC-721 token id)
     * @param _buyer - the buyer of the vouchers
     */
    function issueVoucher(uint256 _exchangeId, BosonTypes.Buyer calldata _buyer) external;

    /**
     * @notice Burn a voucher
     *
     * Caller must have PROTOCOL role.
     *
     * @param _exchangeId - the id of the exchange (corresponds to the ERC-721 token id)
     */
    function burnVoucher(uint256 _exchangeId) external;

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the protocol. Change is done by calling `updateSeller` on the protocol
     */
    function transferOwnership(address newOwner) external;

    /**
     * @notice Returns storefront-level metadata used by OpenSea
     *
     * @return Contract metadata URI
     */
    function contractURI() external view returns (string memory);

    /**
     * @notice Sets new contract URI
     * Can only be called by the owner or during the initialization
     *
     * @param _newContractURI new contract metadata URI
     */
    function setContractURI(string calldata _newContractURI) external;

    /**
     * @notice Called with the sale price to determine how much royalty
     *  is owed and to whom.
     *
     * @param _tokenId - the NFT asset queried for royalty information
     * @param _salePrice - the sale price of the NFT asset specified by _tokenId
     *
     * @return receiver - address of who should be sent the royalty payment
     * @return royaltyAmount - the royalty payment amount for the given sale price
     */
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);

    /**
     * @notice Sets the royalty percentage.
     * Can only be called by the owner or during the initialization
     *
     * Reverts if:
     * - caller is not the owner.
     * - `royaltyPercentage` is greater than 100%.
     *
     * @param _newRoyaltyPercentage fee in percentage. e.g. 500 = 5%
     */
    function setRoyaltyPercentage(uint96 _newRoyaltyPercentage) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./../../domain/BosonConstants.sol";
import { IBosonAccountEvents } from "../../interfaces/events/IBosonAccountEvents.sol";
import { ProtocolBase } from "./ProtocolBase.sol";
import { ProtocolLib } from "./../libs/ProtocolLib.sol";
import { BosonTypes } from "../../domain/BosonTypes.sol";

/**
 * @title SellerBase
 *
 * @dev Provides methods for seller creation that can be shared accross facets
 */
contract SellerBase is ProtocolBase, IBosonAccountEvents {
    /**
     * @notice Creates a seller
     *
     * Emits a SellerCreated event if successful.
     *
     * Reverts if:
     * - Address values are zero address
     * - Addresses are not unique to this seller
     * - Seller is not active (if active == false)
     * - Admin address is zero address and AuthTokenType == None
     * - AuthTokenType is not unique to this seller
     *
     * @param _seller - the fully populated struct with seller id set to 0x0
     * @param _authToken - optional AuthToken struct that specifies an AuthToken type and tokenId that the user can use to do admin functions
     * @param _voucherInitValues - the fully populated BosonTypes.VoucherInitValues struct
     */
    function createSellerInternal(
        Seller memory _seller,
        AuthToken calldata _authToken,
        VoucherInitValues calldata _voucherInitValues
    ) internal {
        //Check active is not set to false
        require(_seller.active, MUST_BE_ACTIVE);

        //Admin address or AuthToken data must be present. A seller can have one or the other
        require(
            (_seller.admin == address(0) && _authToken.tokenType != AuthTokenType.None) ||
                (_seller.admin != address(0) && _authToken.tokenType == AuthTokenType.None),
            ADMIN_OR_AUTH_TOKEN
        );

        //Check that the addresses are unique to one seller Id, accross all roles. These addresses should always be checked. Treasury is not checked
        require(
            protocolLookups().sellerIdByOperator[_seller.operator] == 0 &&
                protocolLookups().sellerIdByOperator[_seller.clerk] == 0 &&
                protocolLookups().sellerIdByAdmin[_seller.operator] == 0 &&
                protocolLookups().sellerIdByAdmin[_seller.clerk] == 0 &&
                protocolLookups().sellerIdByClerk[_seller.operator] == 0 &&
                protocolLookups().sellerIdByClerk[_seller.clerk] == 0,
            SELLER_ADDRESS_MUST_BE_UNIQUE
        );

        //Do other uniqueness checks based on auth type
        if (_seller.admin == address(0)) {
            //Check that auth token is unique to this seller
            require(
                protocolLookups().sellerIdByAuthToken[_authToken.tokenType][_authToken.tokenId] == 0,
                AUTH_TOKEN_MUST_BE_UNIQUE
            );
        } else {
            //check that the admin address is unique to one seller Id, accross all roles
            require(
                protocolLookups().sellerIdByOperator[_seller.admin] == 0 &&
                    protocolLookups().sellerIdByAdmin[_seller.admin] == 0 &&
                    protocolLookups().sellerIdByClerk[_seller.admin] == 0,
                SELLER_ADDRESS_MUST_BE_UNIQUE
            );
        }

        // Get the next account Id and increment the counter
        uint256 sellerId = protocolCounters().nextAccountId++;
        _seller.id = sellerId;
        storeSeller(_seller, _authToken);

        // create clone and store its address cloneAddress
        address voucherCloneAddress = cloneBosonVoucher(sellerId, _seller.operator, _voucherInitValues);
        protocolLookups().cloneAddress[sellerId] = voucherCloneAddress;

        // Notify watchers of state change
        emit SellerCreated(sellerId, _seller, voucherCloneAddress, _authToken, msgSender());
    }

    /**
     * @notice Validates seller struct and stores it to storage, along with auth token if present
     *
     * Reverts if:
     * - Address values are zero address
     * - Addresses are not unique to this seller
     *
     * @param _seller - the fully populated struct with seller id set
     * @param _authToken - optional AuthToken struct that specifies an AuthToken type and tokenId that the user can use to do admin functions
     */

    function storeSeller(Seller memory _seller, AuthToken calldata _authToken) internal {
        //Check for zero address
        require(
            _seller.operator != address(0) && _seller.clerk != address(0) && _seller.treasury != address(0),
            INVALID_ADDRESS
        );

        // Get storage location for seller
        (, Seller storage seller, AuthToken storage authToken) = fetchSeller(_seller.id);

        // Set seller props individually since memory structs can't be copied to storage
        seller.id = _seller.id;
        seller.operator = _seller.operator;
        seller.admin = _seller.admin;
        seller.clerk = _seller.clerk;
        seller.treasury = _seller.treasury;
        seller.active = _seller.active;

        // Auth token passed in
        if (_authToken.tokenType != AuthTokenType.None) {
            // Store auth token
            authToken.tokenId = _authToken.tokenId;
            authToken.tokenType = _authToken.tokenType;

            // Store seller by auth token reference
            protocolLookups().sellerIdByAuthToken[_authToken.tokenType][_authToken.tokenId] = _seller.id;
        } else {
            // Empty auth token passed in
            // Store admin address reference
            protocolLookups().sellerIdByAdmin[_seller.admin] = _seller.id;
        }

        //Map the seller's other addresses to the seller Id. It's not necessary to map the treasury address, as it only receives funds
        protocolLookups().sellerIdByOperator[_seller.operator] = _seller.id;
        protocolLookups().sellerIdByClerk[_seller.clerk] = _seller.id;
    }

    /**
     * @notice Creates a minimal clone of the Boson Voucher Contract
     *
     * @param _sellerId - id of the seller
     * @param _operator - address of the operator
     * @param _voucherInitValues - the fully populated BosonTypes.VoucherInitValues struct
     * @return cloneAddress - the address of newly created clone
     */
    function cloneBosonVoucher(
        uint256 _sellerId,
        address _operator,
        VoucherInitValues calldata _voucherInitValues
    ) internal returns (address cloneAddress) {
        // Pointer to stored addresses
        ProtocolLib.ProtocolAddresses storage pa = protocolAddresses();

        // Load beacon proxy contract address
        bytes20 targetBytes = bytes20(pa.beaconProxy);

        // create a minimal clone
        assembly {
            let clone := mload(0x40)
            mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(clone, 0x14), targetBytes)
            mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            cloneAddress := create(0, clone, 0x37)
        }

        // Initialize the clone
        IInitializableClone(cloneAddress).initialize(pa.voucherBeacon);
        IInitializableClone(cloneAddress).initializeVoucher(_sellerId, _operator, _voucherInitValues);
    }
}

interface IInitializableClone {
    function initialize(address _beaconAddress) external;

    function initializeVoucher(
        uint256 _sellerId,
        address _newOwner,
        BosonTypes.VoucherInitValues calldata _voucherInitValues
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { BosonTypes } from "../../domain/BosonTypes.sol";

/**
 * @title ProtocolLib
 *
 * @dev Provides access to the Protocol Storage, Counters, and Initializer slots for Facets
 */
library ProtocolLib {
    bytes32 internal constant PROTOCOL_ADDRESSES_POSITION = keccak256("boson.protocol.addresses");
    bytes32 internal constant PROTOCOL_LIMITS_POSITION = keccak256("boson.protocol.limits");
    bytes32 internal constant PROTOCOL_ENTITIES_POSITION = keccak256("boson.protocol.entities");
    bytes32 internal constant PROTOCOL_LOOKUPS_POSITION = keccak256("boson.protocol.lookups");
    bytes32 internal constant PROTOCOL_FEES_POSITION = keccak256("boson.protocol.fees");
    bytes32 internal constant PROTOCOL_COUNTERS_POSITION = keccak256("boson.protocol.counters");
    bytes32 internal constant PROTOCOL_INITIALIZERS_POSITION = keccak256("boson.protocol.initializers");
    bytes32 internal constant PROTOCOL_META_TX_POSITION = keccak256("boson.protocol.metaTransactions");

    // Protocol addresses storage
    struct ProtocolAddresses {
        // Address of the Boson Protocol treasury
        address payable treasury;
        // Address of the Boson Token (ERC-20 contract)
        address payable token;
        // Address of the Boson Protocol Voucher beacon
        address voucherBeacon;
        // Address of the Boson Beacon proxy implementation
        address beaconProxy;
    }

    // Protocol limits storage
    struct ProtocolLimits {
        // limit how many exchanges can be processed in single batch transaction
        uint16 maxExchangesPerBatch;
        // limit how many offers can be added to the group
        uint16 maxOffersPerGroup;
        // limit how many offers can be added to the bundle
        uint16 maxOffersPerBundle;
        // limit how many twins can be added to the bundle
        uint16 maxTwinsPerBundle;
        // limit how many offers can be processed in single batch transaction
        uint16 maxOffersPerBatch;
        // limit how many different tokens can be withdrawn in a single transaction
        uint16 maxTokensPerWithdrawal;
        // limit how many dispute resolver fee structs can be processed in a single transaction
        uint16 maxFeesPerDisputeResolver;
        // limit on the escalation response period that a dispute resolver can specify
        uint256 maxEscalationResponsePeriod;
        // limit how many disputes can be processed in single batch transaction
        uint16 maxDisputesPerBatch;
        // limit how many sellers can be added to or removed from an allow list in a single transaction
        uint16 maxAllowedSellers;
        // limit the sum of (Protocol Fee percentage + Agent Fee perpercentagecent) of an offer fee
        uint16 maxTotalOfferFeePercentage;
    }

    // Protocol fees storage
    struct ProtocolFees {
        // Percentage that will be taken as a fee from the net of a Boson Protocol exchange
        uint16 percentage; // 1.75% = 175, 100% = 10000
        // Flat fee taken for exchanges in $BOSON
        uint256 flatBoson;
    }

    // Protocol entities storage
    struct ProtocolEntities {
        // offer id => offer
        mapping(uint256 => BosonTypes.Offer) offers;
        // offer id => offer dates
        mapping(uint256 => BosonTypes.OfferDates) offerDates;
        // offer id => offer fees
        mapping(uint256 => BosonTypes.OfferFees) offerFees;
        // offer id => offer durations
        mapping(uint256 => BosonTypes.OfferDurations) offerDurations;
        // offer id => dispute resolution terms
        mapping(uint256 => BosonTypes.DisputeResolutionTerms) disputeResolutionTerms;
        // exchange id => exchange
        mapping(uint256 => BosonTypes.Exchange) exchanges;
        // exchange id => dispute
        mapping(uint256 => BosonTypes.Dispute) disputes;
        // exchange id => dispute dates
        mapping(uint256 => BosonTypes.DisputeDates) disputeDates;
        // seller id => seller
        mapping(uint256 => BosonTypes.Seller) sellers;
        // buyer id => buyer
        mapping(uint256 => BosonTypes.Buyer) buyers;
        // dispute resolver id => dispute resolver
        mapping(uint256 => BosonTypes.DisputeResolver) disputeResolvers;
        // dispute resolver id => dispute resolver fee array
        mapping(uint256 => BosonTypes.DisputeResolverFee[]) disputeResolverFees;
        // agent id => agent
        mapping(uint256 => BosonTypes.Agent) agents;
        // group id => group
        mapping(uint256 => BosonTypes.Group) groups;
        // bundle id => bundle
        mapping(uint256 => BosonTypes.Bundle) bundles;
        // twin id => twin
        mapping(uint256 => BosonTypes.Twin) twins;
        //entity id => auth token
        mapping(uint256 => BosonTypes.AuthToken) authTokens;
    }

    // Protocol lookups storage
    struct ProtocolLookups {
        // offer id => exchange ids
        mapping(uint256 => uint256[]) exchangeIdsByOffer;
        // offer id => bundle id
        mapping(uint256 => uint256) bundleIdByOffer;
        // twin id => bundle id
        mapping(uint256 => uint256) bundleIdByTwin;
        // offer id => group id
        mapping(uint256 => uint256) groupIdByOffer;
        // offer id => agent id
        mapping(uint256 => uint256) agentIdByOffer;
        // seller operator address => sellerId
        mapping(address => uint256) sellerIdByOperator;
        // seller admin address => sellerId
        mapping(address => uint256) sellerIdByAdmin;
        // seller clerk address => sellerId
        mapping(address => uint256) sellerIdByClerk;
        // buyer wallet address => buyerId
        mapping(address => uint256) buyerIdByWallet;
        // dispute resolver operator address => disputeResolverId
        mapping(address => uint256) disputeResolverIdByOperator;
        // dispute resolver admin address => disputeResolverId
        mapping(address => uint256) disputeResolverIdByAdmin;
        // dispute resolver clerk address => disputeResolverId
        mapping(address => uint256) disputeResolverIdByClerk;
        // dispute resolver id to fee token address => index of the token address
        mapping(uint256 => mapping(address => uint256)) disputeResolverFeeTokenIndex;
        // agent wallet address => agentId
        mapping(address => uint256) agentIdByWallet;
        // seller/buyer id => token address => amount
        mapping(uint256 => mapping(address => uint256)) availableFunds;
        // seller/buyer id => all tokens with balance > 0
        mapping(uint256 => address[]) tokenList;
        // seller id => cloneAddress
        mapping(uint256 => address) cloneAddress;
        // buyer id => number of active vouchers
        mapping(uint256 => uint256) voucherCount;
        // buyer address => groupId => commit count (addresses that have committed to conditional offers)
        mapping(address => mapping(uint256 => uint256)) conditionalCommitsByAddress;
        // buyer escalation deposit percentage
        uint16 buyerEscalationDepositPercentage;
        //AuthTokenType => Auth NFT contract address.
        //Would normally be in ProtocolAddresses but can't be because the ProtocolAddresses struct is passed into the initialize function
        mapping(BosonTypes.AuthTokenType => address) authTokenContracts;
        // AuthTokenType => tokenId => sellerId
        mapping(BosonTypes.AuthTokenType => mapping(uint256 => uint256)) sellerIdByAuthToken;
        // seller id => token address (only ERC721) => start and end of token ids range
        mapping(uint256 => mapping(address => BosonTypes.TokenRange[])) twinRangesBySeller;
        // seller id => token address (only ERC721) => twin ids
        mapping(uint256 => mapping(address => uint256[])) twinIdsByTokenAddressAndBySeller;
        // dispute resolver id => list of allowed sellers
        mapping(uint256 => uint256[]) allowedSellers;
        // dispute resolver id => seller id => index of allowed seller in allowedSellers
        mapping(uint256 => mapping(uint256 => uint256)) allowedSellerIndex;
    }

    // Incrementing ID counters
    struct ProtocolCounters {
        // Next account id
        uint256 nextAccountId;
        // Next offer id
        uint256 nextOfferId;
        // Next exchange id
        uint256 nextExchangeId;
        // Next twin id
        uint256 nextTwinId;
        // Next group id
        uint256 nextGroupId;
        // Next twin id
        uint256 nextBundleId;
    }

    // Storage related to Meta Transactions
    struct ProtocolMetaTxInfo {
        // The current sender address associated with the transaction
        address currentSenderAddress;
        // A flag that tells us whether the current transaction is a meta-transaction or a regular transaction.
        bool isMetaTransaction;
        // The domain Separator of the protocol
        bytes32 domainSeparator;
        // nonce => existance of nonce in the mapping
        mapping(uint256 => bool) usedNonce;
        // map function name to input type
        mapping(string => BosonTypes.MetaTxInputType) inputType;
        // map input type => hash info
        mapping(BosonTypes.MetaTxInputType => BosonTypes.HashInfo) hashInfo;
    }

    // Individual facet initialization states
    struct ProtocolInitializers {
        // interface id => initialized?
        mapping(bytes4 => bool) initializedInterfaces;
    }

    /**
     * @dev Get the protocol addresses slot
     *
     * @return pa the protocol addresses slot
     */
    function protocolAddresses() internal pure returns (ProtocolAddresses storage pa) {
        bytes32 position = PROTOCOL_ADDRESSES_POSITION;
        assembly {
            pa.slot := position
        }
    }

    /**
     * @dev Get the protocol limits slot
     *
     * @return pl the protocol limits slot
     */
    function protocolLimits() internal pure returns (ProtocolLimits storage pl) {
        bytes32 position = PROTOCOL_LIMITS_POSITION;
        assembly {
            pl.slot := position
        }
    }

    /**
     * @dev Get the protocol entities slot
     *
     * @return pe the protocol entities slot
     */
    function protocolEntities() internal pure returns (ProtocolEntities storage pe) {
        bytes32 position = PROTOCOL_ENTITIES_POSITION;
        assembly {
            pe.slot := position
        }
    }

    /**
     * @dev Get the protocol lookups slot
     *
     * @return pl the protocol lookups slot
     */
    function protocolLookups() internal pure returns (ProtocolLookups storage pl) {
        bytes32 position = PROTOCOL_LOOKUPS_POSITION;
        assembly {
            pl.slot := position
        }
    }

    /**
     * @dev Get the protocol fees slot
     *
     * @return pf the protocol fees slot
     */
    function protocolFees() internal pure returns (ProtocolFees storage pf) {
        bytes32 position = PROTOCOL_FEES_POSITION;
        assembly {
            pf.slot := position
        }
    }

    /**
     * @dev Get the protocol counters slot
     *
     * @return pc the protocol counters slot
     */
    function protocolCounters() internal pure returns (ProtocolCounters storage pc) {
        bytes32 position = PROTOCOL_COUNTERS_POSITION;
        assembly {
            pc.slot := position
        }
    }

    /**
     * @dev Get the protocol meta-transactions storage slot
     *
     * @return pmti the protocol meta-transactions storage slot
     */
    function protocolMetaTxInfo() internal pure returns (ProtocolMetaTxInfo storage pmti) {
        bytes32 position = PROTOCOL_META_TX_POSITION;
        assembly {
            pmti.slot := position
        }
    }

    /**
     * @dev Get the protocol initializers slot
     *
     * @return pi the the protocol initializers slot
     */
    function protocolInitializers() internal pure returns (ProtocolInitializers storage pi) {
        bytes32 position = PROTOCOL_INITIALIZERS_POSITION;
        assembly {
            pi.slot := position
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

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
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721MetadataUpgradeable is IERC721Upgradeable {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

/**
 * @title BosonTypes
 *
 * @notice Enums and structs used by the Boson Protocol contract ecosystem.
 */

contract BosonTypes {
    enum EvaluationMethod {
        None,
        Threshold,
        SpecificToken
    }

    enum ExchangeState {
        Committed,
        Revoked,
        Canceled,
        Redeemed,
        Completed,
        Disputed
    }

    enum DisputeState {
        Resolving,
        Retracted,
        Resolved,
        Escalated,
        Decided,
        Refused
    }

    enum TokenType {
        FungibleToken,
        NonFungibleToken,
        MultiToken
    } // ERC20, ERC721, ERC1155

    enum MetaTxInputType {
        Generic,
        CommitToOffer,
        Exchange,
        Funds,
        RaiseDispute,
        ResolveDispute
    }

    enum AuthTokenType {
        None,
        Lens,
        ENS
    }

    struct AuthToken {
        uint256 tokenId;
        AuthTokenType tokenType;
    }

    struct Seller {
        uint256 id;
        address operator;
        address admin;
        address clerk;
        address payable treasury;
        bool active;
    }

    struct Buyer {
        uint256 id;
        address payable wallet;
        bool active;
    }

    struct DisputeResolver {
        uint256 id;
        uint256 escalationResponsePeriod;
        address operator;
        address admin;
        address clerk;
        address payable treasury;
        string metadataUri;
        bool active;
    }

    struct DisputeResolverFee {
        address tokenAddress;
        string tokenName;
        uint256 feeAmount;
    }

    struct Agent {
        uint256 id;
        uint256 feePercentage;
        address payable wallet;
        bool active;
    }

    struct DisputeResolutionTerms {
        uint256 disputeResolverId;
        uint256 escalationResponsePeriod;
        uint256 feeAmount;
        uint256 buyerEscalationDeposit;
    }

    struct Offer {
        uint256 id;
        uint256 sellerId;
        uint256 price;
        uint256 sellerDeposit;
        uint256 buyerCancelPenalty;
        uint256 quantityAvailable;
        address exchangeToken;
        string metadataUri;
        string metadataHash;
        bool voided;
    }

    struct OfferDates {
        uint256 validFrom;
        uint256 validUntil;
        uint256 voucherRedeemableFrom;
        uint256 voucherRedeemableUntil;
    }

    struct OfferDurations {
        uint256 fulfillmentPeriod;
        uint256 voucherValid;
        uint256 resolutionPeriod;
    }

    struct Group {
        uint256 id;
        uint256 sellerId;
        uint256[] offerIds;
        Condition condition;
    }

    struct Condition {
        EvaluationMethod method;
        TokenType tokenType;
        address tokenAddress;
        uint256 tokenId;
        uint256 threshold;
        uint256 maxCommits;
    }

    struct Exchange {
        uint256 id;
        uint256 offerId;
        uint256 buyerId;
        uint256 finalizedDate;
        Voucher voucher;
        ExchangeState state;
    }

    struct Voucher {
        uint256 committedDate;
        uint256 validUntilDate;
        uint256 redeemedDate;
        bool expired;
    }

    struct Dispute {
        uint256 exchangeId;
        string complaint;
        DisputeState state;
        uint256 buyerPercent;
    }

    struct DisputeDates {
        uint256 disputed;
        uint256 escalated;
        uint256 finalized;
        uint256 timeout;
    }

    struct Receipt {
        Offer offer;
        Exchange exchange;
        Dispute dispute;
    }

    struct TokenRange {
        uint256 start;
        uint256 end;
    }

    struct Twin {
        uint256 id;
        uint256 sellerId;
        uint256 amount; // ERC-1155 / ERC-20 (amount to be transferred to each buyer on redemption)
        uint256 supplyAvailable; // all
        uint256 tokenId; // ERC-1155 / ERC-721 (must be initialized with the initial pointer position of the ERC-721 ids available range)
        address tokenAddress; // all
        TokenType tokenType;
    }

    struct Bundle {
        uint256 id;
        uint256 sellerId;
        uint256[] offerIds;
        uint256[] twinIds;
    }

    struct Funds {
        address tokenAddress;
        string tokenName;
        uint256 availableAmount;
    }

    struct MetaTransaction {
        uint256 nonce;
        address from;
        address contractAddress;
        string functionName;
        bytes functionSignature;
    }

    struct HashInfo {
        bytes32 typeHash;
        function(bytes memory) internal pure returns (bytes32) hashFunction;
    }

    struct OfferFees {
        uint256 protocolFee;
        uint256 agentFee;
    }

    struct VoucherInitValues {
        string contractURI;
        uint96 royaltyPercentage;
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
interface IERC165Upgradeable {
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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import { BosonTypes } from "../../domain/BosonTypes.sol";

/**
 * @title IBosonAccountEvents
 *
 * @notice Events related to management of accounts within the protocol.
 */
interface IBosonAccountEvents {
    event SellerCreated(
        uint256 indexed sellerId,
        BosonTypes.Seller seller,
        address voucherCloneAddress,
        BosonTypes.AuthToken authToken,
        address indexed executedBy
    );
    event SellerUpdated(
        uint256 indexed sellerId,
        BosonTypes.Seller seller,
        BosonTypes.AuthToken authToken,
        address indexed executedBy
    );
    event BuyerCreated(uint256 indexed buyerId, BosonTypes.Buyer buyer, address indexed executedBy);
    event BuyerUpdated(uint256 indexed buyerId, BosonTypes.Buyer buyer, address indexed executedBy);
    event AgentUpdated(uint256 indexed agentId, BosonTypes.Agent agent, address indexed executedBy);
    event DisputeResolverCreated(
        uint256 indexed disputeResolverId,
        BosonTypes.DisputeResolver disputeResolver,
        BosonTypes.DisputeResolverFee[] disputeResolverFees,
        uint256[] sellerAllowList,
        address indexed executedBy
    );
    event DisputeResolverUpdated(
        uint256 indexed disputeResolverId,
        BosonTypes.DisputeResolver disputeResolver,
        address indexed executedBy
    );
    event DisputeResolverFeesAdded(
        uint256 indexed disputeResolverId,
        BosonTypes.DisputeResolverFee[] disputeResolverFees,
        address indexed executedBy
    );
    event DisputeResolverFeesRemoved(
        uint256 indexed disputeResolverId,
        address[] feeTokensRemoved,
        address indexed executedBy
    );
    event AllowedSellersAdded(uint256 indexed disputeResolverId, uint256[] addedSellers, address indexed executedBy);
    event AllowedSellersRemoved(
        uint256 indexed disputeResolverId,
        uint256[] removedSellers,
        address indexed executedBy
    );
    event DisputeResolverActivated(
        uint256 indexed disputeResolverId,
        BosonTypes.DisputeResolver disputeResolver,
        address indexed executedBy
    );

    event AgentCreated(uint256 indexed agentId, BosonTypes.Agent agent, address indexed executedBy);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "../../domain/BosonConstants.sol";
import { ProtocolLib } from "../libs/ProtocolLib.sol";
import { DiamondLib } from "../../diamond/DiamondLib.sol";
import { BosonTypes } from "../../domain/BosonTypes.sol";
import { EIP712Lib } from "../libs/EIP712Lib.sol";

/**
 * @title ProtocolBase
 *
 * @notice Provides domain and common modifiers to Protocol facets
 */
abstract contract ProtocolBase is BosonTypes {
    /**
     * @dev Modifier to protect initializer function from being invoked twice.
     */
    modifier onlyUnInitialized(bytes4 interfaceId) {
        ProtocolLib.ProtocolInitializers storage pi = protocolInitializers();
        require(!pi.initializedInterfaces[interfaceId], ALREADY_INITIALIZED);
        pi.initializedInterfaces[interfaceId] = true;
        _;
    }

    /**
     * @dev Modifier that checks that an offer exists
     *
     * Reverts if the offer does not exist
     */
    modifier offerExists(uint256 _offerId) {
        // Make sure the offer exists TODO: remove me, not used and not the way to check
        require(_offerId > 0 && _offerId < protocolCounters().nextOfferId, "Offer does not exist");
        _;
    }

    /**
     * @dev Modifier that checks that the caller has a specific role.
     *
     * Reverts if caller doesn't have role.
     *
     * See: {AccessController.hasRole}
     */
    modifier onlyRole(bytes32 _role) {
        DiamondLib.DiamondStorage storage ds = DiamondLib.diamondStorage();
        require(ds.accessController.hasRole(_role, msgSender()), ACCESS_DENIED);
        _;
    }

    /**
     * @dev Get the Protocol Addresses slot
     *
     * @return pa the Protocol Addresses slot
     */
    function protocolAddresses() internal pure returns (ProtocolLib.ProtocolAddresses storage pa) {
        pa = ProtocolLib.protocolAddresses();
    }

    /**
     * @dev Get the Protocol Limits slot
     *
     * @return pl the Protocol Limits slot
     */
    function protocolLimits() internal pure returns (ProtocolLib.ProtocolLimits storage pl) {
        pl = ProtocolLib.protocolLimits();
    }

    /**
     * @dev Get the Protocol Entities slot
     *
     * @return pe the Protocol Entities slot
     */
    function protocolEntities() internal pure returns (ProtocolLib.ProtocolEntities storage pe) {
        pe = ProtocolLib.protocolEntities();
    }

    /**
     * @dev Get the Protocol Lookups slot
     *
     * @return pl the Protocol Lookups slot
     */
    function protocolLookups() internal pure returns (ProtocolLib.ProtocolLookups storage pl) {
        pl = ProtocolLib.protocolLookups();
    }

    /**
     * @dev Get the Protocol Fees slot
     *
     * @return pf the Protocol Fees slot
     */
    function protocolFees() internal pure returns (ProtocolLib.ProtocolFees storage pf) {
        pf = ProtocolLib.protocolFees();
    }

    /**
     * @dev Get the Protocol Counters slot
     *
     * @return pc the Protocol Counters slot
     */
    function protocolCounters() internal pure returns (ProtocolLib.ProtocolCounters storage pc) {
        pc = ProtocolLib.protocolCounters();
    }

    /**
     * @dev Get the Protocol meta-transactions storage slot
     *
     * @return pmti the Protocol meta-transactions storage slot
     */
    function protocolMetaTxInfo() internal pure returns (ProtocolLib.ProtocolMetaTxInfo storage pmti) {
        pmti = ProtocolLib.protocolMetaTxInfo();
    }

    /**
     * @dev Get the Protocol Initializers slot
     *
     * @return pi the Protocol Initializers slot
     */
    function protocolInitializers() internal pure returns (ProtocolLib.ProtocolInitializers storage pi) {
        pi = ProtocolLib.protocolInitializers();
    }

    /**
     * @notice Gets a seller Id from storage by operator address
     *
     * @param _operator - the operator address of the seller
     * @return exists - whether the seller Id exists
     * @return sellerId  - the seller Id
     */
    function getSellerIdByOperator(address _operator) internal view returns (bool exists, uint256 sellerId) {
        // Get the seller Id
        sellerId = protocolLookups().sellerIdByOperator[_operator];

        // Determine existence
        exists = (sellerId > 0);
    }

    /**
     * @notice Gets a seller Id from storage by admin address
     *
     * @param _admin - the admin address of the seller
     * @return exists - whether the seller Id exists
     * @return sellerId  - the seller Id
     */
    function getSellerIdByAdmin(address _admin) internal view returns (bool exists, uint256 sellerId) {
        // Get the seller Id
        sellerId = protocolLookups().sellerIdByAdmin[_admin];

        // Determine existence
        exists = (sellerId > 0);
    }

    /**
     * @notice Gets a seller Id from storage by clerk address
     *
     * @param _clerk - the clerk address of the seller
     * @return exists - whether the seller Id exists
     * @return sellerId  - the seller Id
     */
    function getSellerIdByClerk(address _clerk) internal view returns (bool exists, uint256 sellerId) {
        // Get the seller Id
        sellerId = protocolLookups().sellerIdByClerk[_clerk];

        // Determine existence
        exists = (sellerId > 0);
    }

    /**
     * @notice Gets a seller Id from storage by auth token.  A seller will have either an admin address or an auth token
     *
     * @param _authToken - the potential _authToken of the seller.
     * @return exists - whether the seller Id exists
     * @return sellerId  - the seller Id
     */
    function getSellerIdByAuthToken(AuthToken calldata _authToken)
        internal
        view
        returns (bool exists, uint256 sellerId)
    {
        // Get the seller Id
        sellerId = protocolLookups().sellerIdByAuthToken[_authToken.tokenType][_authToken.tokenId];

        // Determine existence
        exists = (sellerId > 0);
    }

    /**
     * @notice Gets a buyer id from storage by wallet address
     *
     * @param _wallet - the wallet address of the buyer
     * @return exists - whether the buyer Id exists
     * @return buyerId  - the buyer Id
     */
    function getBuyerIdByWallet(address _wallet) internal view returns (bool exists, uint256 buyerId) {
        // Get the buyer Id
        buyerId = protocolLookups().buyerIdByWallet[_wallet];

        // Determine existence
        exists = (buyerId > 0);
    }

    /**
     * @notice Gets a agent id from storage by wallet address
     *
     * @param _wallet - the wallet address of the buyer
     * @return exists - whether the buyer Id exists
     * @return agentId  - the buyer Id
     */
    function getAgentIdByWallet(address _wallet) internal view returns (bool exists, uint256 agentId) {
        // Get the buyer Id
        agentId = protocolLookups().agentIdByWallet[_wallet];

        // Determine existence
        exists = (agentId > 0);
    }

    /**
     * @notice Gets a dispute resolver Id from storage by operator address
     *
     * @param _operator - the operator address of the dispute resolver
     * @return exists - whether the dispute resolver Id exists
     * @return disputeResolverId  - the dispute resolver  Id
     */
    function getDisputeResolverIdByOperator(address _operator)
        internal
        view
        returns (bool exists, uint256 disputeResolverId)
    {
        // Get the dispute resolver Id
        disputeResolverId = protocolLookups().disputeResolverIdByOperator[_operator];

        // Determine existence
        exists = (disputeResolverId > 0);
    }

    /**
     * @notice Gets a dispute resolver Id from storage by admin address
     *
     * @param _admin - the admin address of the dispute resolver
     * @return exists - whether the dispute resolver Id exists
     * @return disputeResolverId  - the dispute resolver Id
     */
    function getDisputeResolverIdByAdmin(address _admin)
        internal
        view
        returns (bool exists, uint256 disputeResolverId)
    {
        // Get the dispute resolver Id
        disputeResolverId = protocolLookups().disputeResolverIdByAdmin[_admin];

        // Determine existence
        exists = (disputeResolverId > 0);
    }

    /**
     * @notice Gets a dispute resolver Id from storage by clerk address
     *
     * @param _clerk - the clerk address of the dispute resolver
     * @return exists - whether the dispute resolver Id exists
     * @return disputeResolverId  - the dispute resolver Id
     */
    function getDisputeResolverIdByClerk(address _clerk)
        internal
        view
        returns (bool exists, uint256 disputeResolverId)
    {
        // Get the dispute resolver Id
        disputeResolverId = protocolLookups().disputeResolverIdByClerk[_clerk];

        // Determine existence
        exists = (disputeResolverId > 0);
    }

    /**
     * @notice Gets a group id from storage by offer id
     *
     * @param _offerId - the offer id
     * @return exists - whether the group id exists
     * @return groupId  - the group id.
     */
    function getGroupIdByOffer(uint256 _offerId) internal view returns (bool exists, uint256 groupId) {
        // Get the group Id
        groupId = protocolLookups().groupIdByOffer[_offerId];

        // Determine existence
        exists = (groupId > 0);
    }

    /**
     * @notice Fetches a given seller from storage by id
     *
     * @param _sellerId - the id of the seller
     * @return exists - whether the seller exists
     * @return seller - the seller details. See {BosonTypes.Seller}
     * @return authToken - optional AuthToken struct that specifies an AuthToken type and tokenId that the user can use to do admin functions
     */
    function fetchSeller(uint256 _sellerId)
        internal
        view
        returns (
            bool exists,
            Seller storage seller,
            AuthToken storage authToken
        )
    {
        // Get the seller's slot
        seller = protocolEntities().sellers[_sellerId];

        //Get the seller's auth token's slot
        authToken = protocolEntities().authTokens[_sellerId];

        // Determine existence
        exists = (_sellerId > 0 && seller.id == _sellerId);
    }

    /**
     * @notice Fetches a given buyer from storage by id
     *
     * @param _buyerId - the id of the buyer
     * @return exists - whether the buyer exists
     * @return buyer - the buyer details. See {BosonTypes.Buyer}
     */
    function fetchBuyer(uint256 _buyerId) internal view returns (bool exists, BosonTypes.Buyer storage buyer) {
        // Get the buyer's slot
        buyer = protocolEntities().buyers[_buyerId];

        // Determine existence
        exists = (_buyerId > 0 && buyer.id == _buyerId);
    }

    /**
     * @notice Fetches a given dispute resolver from storage by id
     *
     * @param _disputeResolverId - the id of the dispute resolver
     * @return exists - whether the dispute resolver exists
     * @return disputeResolver - the dispute resolver details. See {BosonTypes.DisputeResolver}
     * @return disputeResolverFees - list of fees dispute resolver charges per token type. Zero address is native currency. See {BosonTypes.DisputeResolverFee}
     */
    function fetchDisputeResolver(uint256 _disputeResolverId)
        internal
        view
        returns (
            bool exists,
            BosonTypes.DisputeResolver storage disputeResolver,
            BosonTypes.DisputeResolverFee[] storage disputeResolverFees
        )
    {
        // Get the dispute resolver's slot
        disputeResolver = protocolEntities().disputeResolvers[_disputeResolverId];

        //Get dispute resolver's fee list slot
        disputeResolverFees = protocolEntities().disputeResolverFees[_disputeResolverId];

        // Determine existence
        exists = (_disputeResolverId > 0 && disputeResolver.id == _disputeResolverId);
    }

    /**
     * @notice Fetches a given agent from storage by id
     *
     * @param _agentId - the id of the agent
     * @return exists - whether the agent exists
     * @return agent - the agent details. See {BosonTypes.Agent}
     */
    function fetchAgent(uint256 _agentId) internal view returns (bool exists, BosonTypes.Agent storage agent) {
        // Get the agent's slot
        agent = protocolEntities().agents[_agentId];

        // Determine existence
        exists = (_agentId > 0 && agent.id == _agentId);
    }

    /**
     * @notice Fetches a given offer from storage by id
     *
     * @param _offerId - the id of the offer
     * @return exists - whether the offer exists
     * @return offer - the offer details. See {BosonTypes.Offer}
     */
    function fetchOffer(uint256 _offerId) internal view returns (bool exists, Offer storage offer) {
        // Get the offer's slot
        offer = protocolEntities().offers[_offerId];

        // Determine existence
        exists = (_offerId > 0 && offer.id == _offerId);
    }

    /**
     * @notice Fetches the offer dates from storage by offer id
     *
     * @param _offerId - the id of the offer
     * @return offerDates - the offer dates details. See {BosonTypes.OfferDates}
     */
    function fetchOfferDates(uint256 _offerId) internal view returns (BosonTypes.OfferDates storage offerDates) {
        // Get the offerDates's slot
        offerDates = protocolEntities().offerDates[_offerId];
    }

    /**
     * @notice Fetches the offer durations from storage by offer id
     *
     * @param _offerId - the id of the offer
     * @return offerDurations - the offer durations details. See {BosonTypes.OfferDurations}
     */
    function fetchOfferDurations(uint256 _offerId)
        internal
        view
        returns (BosonTypes.OfferDurations storage offerDurations)
    {
        // Get the offer's slot
        offerDurations = protocolEntities().offerDurations[_offerId];
    }

    /**
     * @notice Fetches the dispute resolution terms from storage by offer id
     *
     * @param _offerId - the id of the offer
     * @return disputeResolutionTerms - the details about the dispute resolution terms. See {BosonTypes.DisputeResolutionTerms}
     */
    function fetchDisputeResolutionTerms(uint256 _offerId)
        internal
        view
        returns (BosonTypes.DisputeResolutionTerms storage disputeResolutionTerms)
    {
        // Get the disputeResolutionTerms's slot
        disputeResolutionTerms = protocolEntities().disputeResolutionTerms[_offerId];
    }

    /**
     * @notice Fetches a given group from storage by id
     *
     * @param _groupId - the id of the group
     * @return exists - whether the group exists
     * @return group - the group details. See {BosonTypes.Group}
     */
    function fetchGroup(uint256 _groupId) internal view returns (bool exists, Group storage group) {
        // Get the group's slot
        group = protocolEntities().groups[_groupId];

        // Determine existence
        exists = (_groupId > 0 && group.id == _groupId);
    }

    /**
     * @notice Fetches a given exchange from storage by id
     *
     * @param _exchangeId - the id of the exchange
     * @return exists - whether the exchange exists
     * @return exchange - the exchange details. See {BosonTypes.Exchange}
     */
    function fetchExchange(uint256 _exchangeId) internal view returns (bool exists, Exchange storage exchange) {
        // Get the exchange's slot
        exchange = protocolEntities().exchanges[_exchangeId];

        // Determine existence
        exists = (_exchangeId > 0 && exchange.id == _exchangeId);
    }

    /**
     * @notice Fetches a given dispute from storage by exchange id
     *
     * @param _exchangeId - the id of the exchange associated with the dispute
     * @return exists - whether the dispute exists
     * @return dispute - the dispute details. See {BosonTypes.Dispute}
     */
    function fetchDispute(uint256 _exchangeId)
        internal
        view
        returns (
            bool exists,
            Dispute storage dispute,
            DisputeDates storage disputeDates
        )
    {
        // Get the dispute's slot
        dispute = protocolEntities().disputes[_exchangeId];

        // Get the disputeDates's slot
        disputeDates = protocolEntities().disputeDates[_exchangeId];

        // Determine existence
        exists = (_exchangeId > 0 && dispute.exchangeId == _exchangeId);
    }

    /**
     * @notice Fetches a given twin from storage by id
     *
     * @param _twinId - the id of the twin
     * @return exists - whether the twin exists
     * @return twin - the twin details. See {BosonTypes.Twin}
     */
    function fetchTwin(uint256 _twinId) internal view returns (bool exists, Twin storage twin) {
        // Get the twin's slot
        twin = protocolEntities().twins[_twinId];

        // Determine existence
        exists = (_twinId > 0 && twin.id == _twinId);
    }

    /**
     * @notice Fetches a given bundle from storage by id
     *
     * @param _bundleId - the id of the bundle
     * @return exists - whether the bundle exists
     * @return bundle - the bundle details. See {BosonTypes.Bundle}
     */
    function fetchBundle(uint256 _bundleId) internal view returns (bool exists, Bundle storage bundle) {
        // Get the bundle's slot
        bundle = protocolEntities().bundles[_bundleId];

        // Determine existence
        exists = (_bundleId > 0 && bundle.id == _bundleId);
    }

    /**
     * @notice Gets offer from protocol storage, makes sure it exist and not voided
     *
     * Reverts if:
     * - Offer does not exist
     * - Offer already voided
     * - Caller is not the seller
     *
     *  @param _offerId - the id of the offer to check
     */
    function getValidOffer(uint256 _offerId) internal view returns (Offer storage offer) {
        bool exists;
        Seller storage seller;

        // Get offer
        (exists, offer) = fetchOffer(_offerId);

        // Offer must already exist
        require(exists, NO_SUCH_OFFER);

        // Offer must not already be voided
        require(!offer.voided, OFFER_HAS_BEEN_VOIDED);

        // Get seller, we assume seller exists if offer exists
        (, seller, ) = fetchSeller(offer.sellerId);

        // Caller must be seller's operator address
        require(seller.operator == msgSender(), NOT_OPERATOR);
    }

    /**
     * @notice Gets the bundle id for a given offer id.
     *
     * @param _offerId - the offer Id.
     * @return exists - whether the bundle Id exists
     * @return bundleId  - the bundle Id.
     */
    function fetchBundleIdByOffer(uint256 _offerId) internal view returns (bool exists, uint256 bundleId) {
        // Get the bundle Id
        bundleId = protocolLookups().bundleIdByOffer[_offerId];

        // Determine existence
        exists = (bundleId > 0);
    }

    /**
     * @notice Gets the bundle id for a given twin id.
     *
     * @param _twinId - the twin Id.
     * @return exists - whether the bundle Id exist
     * @return bundleId  - the bundle Id.
     */
    function fetchBundleIdByTwin(uint256 _twinId) internal view returns (bool exists, uint256 bundleId) {
        // Get the bundle Id
        bundleId = protocolLookups().bundleIdByTwin[_twinId];

        // Determine existence
        exists = (bundleId > 0);
    }

    /**
     * @notice Gets the exchange ids for a given offer id.
     *
     * @param _offerId - the offer Id.
     * @return exists - whether the exchange Ids exist
     * @return exchangeIds  - the exchange Ids.
     */
    function getExchangeIdsByOffer(uint256 _offerId) internal view returns (bool exists, uint256[] memory exchangeIds) {
        // Get the exchange Ids
        exchangeIds = protocolLookups().exchangeIdsByOffer[_offerId];

        // Determine existence
        exists = (exchangeIds.length > 0);
    }

    /**
     * @notice Make sure the caller is buyer associated with the exchange
     *
     * Reverts if
     * - caller is not the buyer associated with exchange
     *
     * @param _currentBuyer - id of current buyer associated with the exchange
     */
    function checkBuyer(uint256 _currentBuyer) internal view {
        // Get the caller's buyer account id
        (, uint256 buyerId) = getBuyerIdByWallet(msgSender());

        // Must be the buyer associated with the exchange (which is always voucher holder)
        require(buyerId == _currentBuyer, NOT_VOUCHER_HOLDER);
    }

    /**
     * @notice Get a valid exchange
     *
     * Reverts if
     * - Exchange does not exist
     * - Exchange is not in the expected state
     *
     * @param _exchangeId - the id of the exchange to complete
     * @param _expectedState - the state the exchange should be in
     * @return exchange - the exchange
     */
    function getValidExchange(uint256 _exchangeId, ExchangeState _expectedState)
        internal
        view
        returns (Exchange storage exchange)
    {
        // Get the exchange
        bool exchangeExists;
        (exchangeExists, exchange) = fetchExchange(_exchangeId);

        // Make sure the exchange exists
        require(exchangeExists, NO_SUCH_EXCHANGE);
        // Make sure the exchange is in expected state
        require(exchange.state == _expectedState, INVALID_STATE);
    }

    /**
     * @notice Returns the current sender address.
     */
    function msgSender() internal view returns (address) {
        return EIP712Lib.msgSender();
    }

    /**
     * @notice Gets the agent id for a given offer id.
     *
     * @param _offerId - the offer Id.
     * @return exists - whether the exchange Ids exist
     * @return agentId - the agent Id.
     */
    function fetchAgentIdByOffer(uint256 _offerId) internal view returns (bool exists, uint256 agentId) {
        // Get the exchange Ids
        agentId = protocolLookups().agentIdByOffer[_offerId];

        // Determine existence
        exists = (agentId > 0);
    }

    /**
     * @notice Fetches the offer fees from storage by offer id
     *
     * @param _offerId - the id of the offer
     * @return offerFees - the offer fees details. See {BosonTypes.OfferFees}
     */
    function fetchOfferFees(uint256 _offerId) internal view returns (BosonTypes.OfferFees storage offerFees) {
        // Get the offerFees's slot
        offerFees = protocolEntities().offerFees[_offerId];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IAccessControlUpgradeable } from "@openzeppelin/contracts-upgradeable/access/IAccessControlUpgradeable.sol";
import { IDiamondCut } from "../interfaces/diamond/IDiamondCut.sol";

/**
 * @title DiamondLib
 *
 * @notice Diamond storage slot and supported interfaces
 *
 * @notice Based on Nick Mudge's gas-optimized diamond-2 reference,
 * with modifications to support role-based access and management of
 * supported interfaces. Also added copious code comments throughout.
 *
 * Reference Implementation  : https://github.com/mudgen/diamond-2-hardhat
 * EIP-2535 Diamond Standard : https://eips.ethereum.org/EIPS/eip-2535
 *
 * N.B. Facet management functions from original `DiamondLib` were refactor/extracted
 * to JewelerLib, since business facets also use this library for access control and
 * managing supported interfaces.
 *
 * @author Nick Mudge <[email protected]> (https://twitter.com/mudgen)
 * @author Cliff Hall <[email protected]> (https://twitter.com/seaofarrows)
 */
library DiamondLib {
    bytes32 internal constant DIAMOND_STORAGE_POSITION = keccak256("diamond.standard.diamond.storage");

    struct DiamondStorage {
        // maps function selectors to the facets that execute the functions.
        // and maps the selectors to their position in the selectorSlots array.
        // func selector => address facet, selector position
        mapping(bytes4 => bytes32) facets;
        // array of slots of function selectors.
        // each slot holds 8 function selectors.
        mapping(uint256 => bytes32) selectorSlots;
        // The number of function selectors in selectorSlots
        uint16 selectorCount;
        // Used to query if a contract implements an interface.
        // Used to implement ERC-165.
        mapping(bytes4 => bool) supportedInterfaces;
        // The Boson Protocol AccessController
        IAccessControlUpgradeable accessController;
    }

    /**
     * @notice Get the Diamond storage slot
     *
     * @return ds - Diamond storage slot cast to DiamondStorage
     */
    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    /**
     * @notice Add a supported interface to the Diamond
     *
     * @param _interfaceId - the interface to add
     */
    function addSupportedInterface(bytes4 _interfaceId) internal {
        // Get the DiamondStorage struct
        DiamondStorage storage ds = diamondStorage();

        // Flag the interfaces as supported
        ds.supportedInterfaces[_interfaceId] = true;
    }

    /**
     * @notice Implementation of ERC-165 interface detection standard.
     *
     * @param _interfaceId - the sighash of the given interface
     */
    function supportsInterface(bytes4 _interfaceId) internal view returns (bool) {
        // Get the DiamondStorage struct
        DiamondStorage storage ds = diamondStorage();

        // Return the value
        return ds.supportedInterfaces[_interfaceId] || false;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../domain/BosonConstants.sol";
import { ProtocolLib } from "../libs/ProtocolLib.sol";

/**
 * @title EIP712Lib
 *
 * @dev Provides the domain seperator and chain id.
 */
library EIP712Lib {
    /**
     * @notice Get the domain separator
     *
     * @param _name - the name of the protocol.
     * @param _version -  The version of the protocol.
     */
    function domainSeparator(string memory _name, string memory _version) internal view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    EIP712_DOMAIN_TYPEHASH,
                    keccak256(bytes(_name)),
                    keccak256(bytes(_version)),
                    address(this),
                    getChainID()
                )
            );
    }

    /**
     * @notice Get the chain id
     *
     * @return id - the chain id, 1 for Ethereum mainnet, > 1 for public testnets.
     */
    function getChainID() internal view returns (uint256 id) {
        assembly {
            id := chainid()
        }
    }

    /**
     * @notice Recovers the Signer from the Signature components.
     *
     * Reverts if:
     * - signer is a zero address
     *
     * @param _user  - the sender of the transaction.
     * @param _hashedMetaTx - hashed meta transaction.
     * @param _sigR - r part of the signer's signature.
     * @param _sigS - s part of the signer's signature.
     * @param _sigV - v part of the signer's signature.
     */
    function verify(
        address _user,
        bytes32 _hashedMetaTx,
        bytes32 _sigR,
        bytes32 _sigS,
        uint8 _sigV
    ) internal view returns (bool) {
        address signer = ecrecover(toTypedMessageHash(_hashedMetaTx), _sigV, _sigR, _sigS);
        require(signer != address(0), INVALID_SIGNATURE);
        return signer == _user;
    }

    /**
     * @notice Get the domain separator.
     */
    function getDomainSeparator() private view returns (bytes32) {
        return ProtocolLib.protocolMetaTxInfo().domainSeparator;
    }

    /**
     * @dev Accept message hash and returns hash message in EIP712 compatible form
     * So that it can be used to recover signer from signature signed using EIP712 formatted data
     * https://eips.ethereum.org/EIPS/eip-712
     * "\\x19" makes the encoding deterministic
     * "\\x01" is the version byte to make it compatible to EIP-191
     *
     * @param _messageHash  - the message hash.
     */
    function toTypedMessageHash(bytes32 _messageHash) internal view returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", getDomainSeparator(), _messageHash));
    }

    /**
     * @notice Get the current sender address from storage.
     */
    function getCurrentSenderAddress() internal view returns (address) {
        return ProtocolLib.protocolMetaTxInfo().currentSenderAddress;
    }

    /**
     * @notice Returns the current sender address.
     */
    function msgSender() internal view returns (address) {
        bool isItAMetaTransaction = ProtocolLib.protocolMetaTxInfo().isMetaTransaction;

        // Get sender from the storage if this is a meta transaction
        if (isItAMetaTransaction) {
            return getCurrentSenderAddress();
        } else {
            return msg.sender;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
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
pragma solidity ^0.8.0;

/**
 * @title IDiamondCut
 *
 * @notice Diamond Facet management
 *
 * Reference Implementation  : https://github.com/mudgen/diamond-2-hardhat
 * EIP-2535 Diamond Standard : https://eips.ethereum.org/EIPS/eip-2535
 *
 * The ERC-165 identifier for this interface is: 0x1f931c1c
 *
 * @author Nick Mudge <[email protected]> (https://twitter.com/mudgen)
 */
interface IDiamondCut {
    event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);

    enum FacetCutAction {
        Add,
        Replace,
        Remove
    }

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

    /**
     * @notice Add/replace/remove any number of functions and
     * optionally execute a function with delegatecall
     *
     * _calldata is executed with delegatecall on _init
     *
     * @param _diamondCut Contains the facet addresses and function selectors
     * @param _init The address of the contract or facet to execute _calldata
     * @param _calldata A function call, including function selector and arguments
     */
    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external;
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