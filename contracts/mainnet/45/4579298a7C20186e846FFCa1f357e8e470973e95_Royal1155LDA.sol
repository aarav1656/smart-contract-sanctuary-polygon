//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import { IRoyal1155LDA } from "./IRoyal1155LDA.sol";
import { IRoyalExtrasToken } from "../extras/IRoyalExtrasToken.sol";
import "../interfaces/ILdaTransferHook.sol";
import "../shared/RoyalUtil.sol";
import "../utils/RoyalPausableUpgradeable.sol";

/**
 * @title Royal1155LDA
 * @author Royal
 *
 * @notice Implementation of Royal.io LDAs (Limited Digital Assets) as ERC-1155 tokens.
 *
 *  See https://eips.ethereum.org/EIPS/eip-1155
 *
 *  LDA token IDs (“LDA IDs”) are made up of three parts:
 *
 *    1. Tier ID: Denotes te tier that this token belongs to (e.g. GOLD, PLATINUM, DIAMOND).
 *       A tier ID is globally unique across all Royal drops.
 *
 *    2. Version: Represents the version, which may change with certain significant events such as
 *       the redemption of token extras. Including the version in the LDA ID ensures that
 *       marketplace bids and asks are invalidated when the token version changes.
 *
 *    3. Token ID: Represents the token number within the specific tier. We generally start
 *       at token #1 and count up to the tier max supply, but that is not strictly necessary.
 *
 *  These parts are laid out in the uint256 LDA token ID (the “LDA ID”) as follows:
 *
 *   MSB                                                 LSB
 *    [ tier_id             | version | token_id          ]
 *    [ **** **** **** **** | **      | ** **** **** **** ]
 *    [ 128 bits            | 16 bits | 112 bits          ]
 */
contract Royal1155LDA is
    ERC1155Upgradeable,
    RoyalPausableUpgradeable,
    IRoyal1155LDA,
    IRoyalExtrasToken
{
    // -------------------- Events -------------------- //

    event NewTier(
        uint128 indexed tierID
    );

    event TierExhausted(
        uint128 indexed tierID
    );

    event SetExtrasContract(
        address extrasContract
    );

    event SetRoyaltiesContract(
        address royaltiesContract
    );

    // -------------------- Storage -------------------- //

    /// @custom:oz-renamed-from _contractMetadataURI
    string internal _CONTRACT_METADATA_URI_;

    /// @dev Mapping (tierId) => max supply for this tier
    mapping(uint128 => uint256) public tierMaxSupply;

    /// @dev Mapping (tierId) => current supply for this tier.
    ///   NOTE: See also the comment below _TIER_ENUMERATION_.
    /// @custom:oz-renamed-from _tierCurrentSupply
    mapping(uint128 => uint256) internal _CURRENT_SUPPLY_;

    // MAPPINGS FOR MAINTAINING ISSUANCE_ID => LIST OF ADDRESSES HOLDING TOKENS (with repeats)
    // NOTE: These structures allow to enumerate the ldaId[] corresponding to a tierId. The
    //       addresses must then be looked up from _OWNERS_.

    /// @dev Mapping (ldaId) => owner address
    /// @custom:oz-renamed-from _owners
    mapping(uint256 => address) internal _OWNERS_;

    /// @dev Mapping (tierId) => (index) => (ldaId)
    ///  Tracks the LDA IDs that belong to a given tier.
    /// @custom:oz-renamed-from _ldasForTier
    mapping(uint128 => mapping(uint256 => uint256)) internal _TIER_ENUMERATION_;

    /// @dev (ldaId) => (index)
    ///  Tracks the index of the LDA ID in the _TIER_ENUMERATION_ list.
    /// @custom:oz-renamed-from _ldaIndexesForTier
    mapping(uint256 => uint256) internal _TIER_ENUMERATION_INDEX_;

    /// @dev Mapping (tierId) => (owner address) => (owned count)
    ///  Tracks the number of LDAs owned by a user within a particular tier.
    mapping(uint256 => mapping(address => uint256)) internal _BALANCES_;

    /// @dev Mapping (tierId) => (owner address) => (owned index) => (ldaId)
    ///  Tracks the LDA IDs owned by a user within a particular tier.
    mapping(uint256 => mapping(address => mapping(uint256 => uint256))) internal _OWNED_TOKENS_;

    /// @dev Mapping (ldaId) => (owned index)
    ///  Tracks the index of the LDA ID in the _OWNED_TOKENS_ list.
    mapping(uint256 => uint256) internal _OWNED_TOKENS_INDEX_;

    /// @dev Indicates whether the backfill of `_OWNED_TOKENS_` was completed.
    bool internal _IS_OWNED_TOKENS_BACKFILL_COMPLETE_;

    /// @dev Address of the extras contract.
    address internal _EXTRAS_CONTRACT_;

    /// @dev Address of the royalties contract.
    address internal _ROYALTIES_CONTRACT_;

    // -------------------- Initializers -------------------- //

    function initialize(
        string memory tokenMetadataUri,
        string memory contractMetadataUri
    )
        public
        initializer
    {
        __Royal1155LDA_init_unchained(tokenMetadataUri, contractMetadataUri);
    }

    function __Royal1155LDA_init_unchained(
        string memory tokenUri,
        string memory contractUri
    )
        internal
        initializer
    {
        __RoyalPausableUpgradeable_init();
        __ERC1155_init(tokenUri);
        _CONTRACT_METADATA_URI_ = contractUri;
    }

    // -------------------- Owner-Only Functions -------------------- //

    /**
     * @notice Setter for {_EXTRAS_CONTRACT_} that defines the address for the extras contract.
     */
    function setExtrasContract(
        address newExtrasContract
    )
        external
        onlyOwner
    {
        _EXTRAS_CONTRACT_ = newExtrasContract;
        emit SetExtrasContract(newExtrasContract);
    }

    /**
     * @notice Setter for {_ROYALTIES_CONTRACT_} that defines the address for the extras contract.
     */
    function setRoyaltiesContract(
        address newRoyaltiesContract
    )
        external
        onlyOwner
    {
        _ROYALTIES_CONTRACT_ = newRoyaltiesContract;
        emit SetRoyaltiesContract(newRoyaltiesContract);
    }

    function updateContractMetadataURI(
        string memory contractUri
    )
        external
        onlyOwner
        whenNotPaused
    {
        _CONTRACT_METADATA_URI_ = contractUri;
    }

    function updateTokenURI(
        string calldata tokenUri
    )
        external
        onlyOwner
    {
        _setURI(tokenUri);
    }

    function completeOwnedTokensBackfill()
        external
        onlyOwner
    {
        _IS_OWNED_TOKENS_BACKFILL_COMPLETE_ = true;
    }

    /**
     * @notice Called by the owner to backfill the mapping of owned token counts by user.
     */
    function setOwnedTokens(
        uint128 tierId,
        address[] calldata owners,
        uint256[][] calldata ownedTokens
    )
        external
        onlyOwner
    {
        require(
            !_IS_OWNED_TOKENS_BACKFILL_COMPLETE_,
            "Backfill is complete"
        );
        require(
            owners.length == ownedTokens.length,
            "Params length mismatch"
        );
        for (uint256 i = 0; i < owners.length; i++) {
            address owner = owners[i];
            uint256[] memory ownerOwnedTokens = ownedTokens[i];

            _BALANCES_[tierId][owner] = ownerOwnedTokens.length;

            for (uint256 j = 0; j < ownerOwnedTokens.length; j++) {
                uint256 ldaId = ownerOwnedTokens[j];
                _OWNED_TOKENS_[tierId][owner][j] = ldaId;
                _OWNED_TOKENS_INDEX_[ldaId] = j;
            }
        }
    }

    /**
     * @notice Create an Tier of an LDA. In order for an LDA to be minted, it must
     *  belong to a valid Tier that has not yet reached it's max supply.
     */
    function createTier(
        uint128 tierId,
        uint256 maxSupply
    )
        external
        onlyOwner
        whenNotPaused
    {
        require(
            !this.tierExists(tierId) && _CURRENT_SUPPLY_[tierId] == 0,
            "Tier already exists"
        );
        require(
            tierId != 0 && maxSupply >= 1,
            "Invalid tier definition"
        );

        tierMaxSupply[tierId] = maxSupply;

        emit NewTier(tierId);
        // NOTE: Default value of current supply is already set to be 0
    }

    function mintLDAToOwner(
        address recipient,
        uint256 ldaId,
        bytes calldata data
    )
        external
        onlyOwner
        whenNotPaused
    {
        require(
            _OWNERS_[ldaId] == address(0),
            "LDA already minted"
        );
        (uint128 tierId,,) = RoyalUtil.decomposeLDA_ID(ldaId);
        // NOTE: This check also implicitly checks that the tier exists as mintable()
        //       is a stricter requirement than exists().
        require(
            this.mintable(tierId),
            "Tier not mintable"
        );

        // Update current supply before minting to prevent reentrancy attacks
        _CURRENT_SUPPLY_[tierId] += 1;
        _mint(recipient, ldaId, 1, data);

        // Emit the big events
        if (_CURRENT_SUPPLY_[tierId] == tierMaxSupply[tierId]) {
            emit TierExhausted(tierId);
        }
    }

    /**
     * @notice Bulk mint a list of LDAs from a given tier.
     */
    function bulkMintTierLDAsToOwner(
        address recipient,
        uint256[] calldata ldaIds,
        bytes calldata data
    )
        external
        onlyOwner
    {
        require(
            ldaIds.length >= 1,
            "empty ldaIDs list"
        );

        // Check this tier is mintable
        (uint128 tierId,,) = RoyalUtil.decomposeLDA_ID(ldaIds[0]);
        require(
            this.tierExists(tierId),
            "Tier not mintable"
        );
        require(
            (_CURRENT_SUPPLY_[tierId] + ldaIds.length) <= tierMaxSupply[tierId],
            "Too many tokens to mint"
        );

        // Check all LDAs are unminted
        for (uint256 i = 0; i < ldaIds.length; i++) {
            require(
                _OWNERS_[ldaIds[i]] == address(0),
                "LDA already minted"
            );
            (uint128 curTierId,,) = RoyalUtil.decomposeLDA_ID(ldaIds[i]);
            require(
                curTierId == tierId,
                "not all tiers are the same"
            );
        }

        // We always just want 1 of each token
        uint256[] memory amounts = new uint256[](ldaIds.length);
        for (uint256 i = 0; i < ldaIds.length; i++) {
            amounts[i] = 1;
        }

        // Update current supply before minting to prevent reentrancy attacks
        _CURRENT_SUPPLY_[tierId] += ldaIds.length;
        // Issue mint
        _mintBatch(recipient, ldaIds, amounts, data);

        // Emit the big events
        if (_CURRENT_SUPPLY_[tierId] == tierMaxSupply[tierId]) {
            emit TierExhausted(tierId);
        }
    }

    // -------------------- Other Access-Controlled Functions -------------------- //

    function onExtraRedeemed(
        uint256 /* extraId */,
        uint256 ldaId,
        address redeemer
    )
        external
        override
    {
        address tokenOwner = _OWNERS_[ldaId];

        require(
            _msgSender() == _EXTRAS_CONTRACT_,
            "redemptions only from extras contract"
        );
        require(
            tokenOwner != address(0),
            "token DNE"
        );
        require(
            (tokenOwner == redeemer) || isApprovedForAll(tokenOwner, redeemer),
            "redemption by approved addresses only"
        );

        // Bump version number
        (uint128 tierId, uint256 version, uint128 tokenId) = RoyalUtil.decomposeLDA_ID(
            ldaId
        );
        uint256 newLdaId = RoyalUtil.composeLDA_ID(tierId, ++version, tokenId);

        // Burn and remint with version += 1
        bytes memory emptyData;
        _burn(tokenOwner, ldaId, 1);
        _mint(tokenOwner, newLdaId, 1, emptyData);
    }

    // -------------------- Other External Functions -------------------- //

    function getExtrasContract()
        external
        view
        returns (address)
    {
        return _EXTRAS_CONTRACT_;
    }

    function getRoyaltiesContract()
        external
        view
        returns (address)
    {
        return _ROYALTIES_CONTRACT_;
    }

    function contractURI()
        external
        view
        returns (string memory)
    {
        return _CONTRACT_METADATA_URI_;
    }

    function getIsOwnedTokensBackfillComplete()
        external
        view
        returns (bool)
    {
        return _IS_OWNED_TOKENS_BACKFILL_COMPLETE_;
    }

    function getTierTotalSupply(
        uint128 tierId
    )
        external
        view
        override
        returns (uint256)
    {
        return tierMaxSupply[tierId];
    }

    /**
     * @notice Has this tier been initialized?
     */
    function tierExists(
        uint128 tierId
    )
        external
        view
        override
        returns (bool)
    {
        // Check that the map has a set value
        return tierMaxSupply[tierId] != 0;
    }

    /**
     * @notice Check if given tier is currently mintable.
     */
    function mintable(
        uint128 tierId
    )
        external
        view
        override
        returns (bool)
    {
        return _CURRENT_SUPPLY_[tierId] < tierMaxSupply[tierId] && this.tierExists(tierId);
    }

    /**
     * @notice Has the given LDA been minted?
     */
    function exists(
        uint256 ldaId
    )
        external
        view
        returns (bool)
    {
        return _OWNERS_[ldaId] != address(0);
    }

    /**
     * @notice What address owns the given ldaID?
     */
    function ownerOf(
        uint256 ldaId
    )
        external
        view
        returns (address)
    {
        require(
            _OWNERS_[ldaId] != address(0),
            "LDA DNE"
        );
        return _OWNERS_[ldaId];
    }

    /**
     * @notice Get the number of LDAs owned by a user within a particular tier.
     *
     *  IMPORTANT: Assumes that the max supply of each LDA ID in the tier is 1.
     */
    function tierBalanceOf(
        uint128 tierId,
        address owner
    )
        external
        view
        override
        returns (uint256)
    {
        return _BALANCES_[tierId][owner];
    }

    function tokenOfOwnerByIndex(
        uint128 tierId,
        address owner,
        uint256 index
    )
        external
        view
        returns (uint256)
    {
        require(
            index < _BALANCES_[tierId][owner],
            "Owner index out of bounds"
        );
        return _OWNED_TOKENS_[tierId][owner][index];
    }

    function getOwnedTokens(
        uint128 tierId,
        address owner
    )
        external
        view
        override
        returns (uint256[] memory)
    {
        uint256 balance = _BALANCES_[tierId][owner];
        uint256[] memory ownedTokens = new uint256[](balance);
        for (uint256 i = 0; i < balance; i++) {
            ownedTokens[i] = _OWNED_TOKENS_[tierId][owner][i];
        }
        return ownedTokens;
    }

    /**
     * @notice Compose a raw ldaID from its two composite parts.
     */
    function composeLDA_ID(
        uint128 tierId,
        uint256 version,
        uint128 tokenId
    )
        external
        pure
        returns (
            uint256 ldaID
        )
    {
        return RoyalUtil.composeLDA_ID(tierId, version, tokenId);
    }

    /**
     * @notice Decompose a raw ldaID into its two composite parts.
     */
    function decomposeLDA_ID(
        uint256 ldaId
    )
        external
        pure
        returns (
            uint128 tierID,
            uint256 version,
            uint128 tokenID
        )
    {
        return RoyalUtil.decomposeLDA_ID(ldaId);
    }

    /**
     * @notice Zeros out the token version and returns a Royal LDA ID V1.
     */
    function getCanonicalTokenId(
        uint256 tokenId
    )
        external
        pure
        override
        returns(
            uint256
        )
    {
        return RoyalUtil.getCanonicalTokenId(tokenId);
    }

    function onExtraRegistered(
        uint256 /* extraId */,
        address /* registerer */,
        uint256 /* startCanonicalTokenId */,
        uint256 /* endCanonicalTokenId */
    )
        external
        pure
        override
    {}

    // -------------------- Internal Functions -------------------- //

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    )
        internal
        virtual
        override
    {
        // Iterate over all LDAs being transferred
        for (uint256 i; i < ids.length; i++) {
            uint256 ldaId = ids[i];

            // Get the tier ID.
            (uint128 tierId, ,) = RoyalUtil.decomposeLDA_ID(ldaId);

            // Call the callback on the Royalties contract.
            //
            // IMPORTANT: This must happen before any bookkeeping like `_OWNED_TOKENS_` is updated.
            if (_ROYALTIES_CONTRACT_ != address(0)) {
                ILdaTransferHook(_ROYALTIES_CONTRACT_).beforeLdaTransfer(from, to, tierId);
            }

            // Self-transfer: skip everything that follows.
            if (from == to) {
                continue;
            }

            // Token leaves a wallet: update balance and remove token from owner enumeration.
            if (from != address(0)) {
                uint256 balance = _BALANCES_[tierId][from];

                // Special case: If backfill is ongoing AND balance is zero, do not update.
                if (_IS_OWNED_TOKENS_BACKFILL_COMPLETE_ || balance != 0) {
                    require(
                        balance != 0,
                        "ERC1155: insufficient balance for transfer"
                    );

                    // Remove from owned tokens list using swap-and-pop method.
                    uint256 lastTokenIndex = balance - 1;
                    uint256 removeTokenIndex = _OWNED_TOKENS_INDEX_[ldaId];

                    if (lastTokenIndex != removeTokenIndex) {
                        uint256 lastTokenId = _OWNED_TOKENS_[tierId][from][lastTokenIndex];
                        _OWNED_TOKENS_[tierId][from][removeTokenIndex] = lastTokenId;
                        _OWNED_TOKENS_INDEX_[lastTokenId] = removeTokenIndex;
                    }

                    delete _OWNED_TOKENS_[tierId][from][lastTokenIndex];
                    delete _OWNED_TOKENS_INDEX_[ldaId]; // NOTE: This deletion is optional.

                    _BALANCES_[tierId][from] = lastTokenIndex;
                }
            }

            // Token enters a wallet: update balance and add token to owner enumeration.
            if (to != address(0)) {
                uint256 oldBalance = _BALANCES_[tierId][to];
                _OWNED_TOKENS_[tierId][to][oldBalance] = ldaId;
                _OWNED_TOKENS_INDEX_[ldaId] = oldBalance;

                _BALANCES_[tierId][to] = oldBalance + 1;
            }

            if (from == address(0)) {
                // This is a mint operation
                // Add this LDA to the `to` address state
                _addTokenToTierTracking(to, ldaId, tierId);

            } else {
                // If this is a transfer to a different address.
                _OWNERS_[ldaId] = to;
            }

            if (to == address(0)) {
                // NOTE: no burn() is currently implemented
                // Remove LDA from being associated with its
                _removeLDAFromTierTracking(from, ldaId, tierId);
            }
        }

        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function _addTokenToTierTracking(
        address to,
        uint256 ldaId,
        uint128 tierId
    )
        internal
    {
        uint256 ldaIndexForThisTier = _CURRENT_SUPPLY_[tierId];
        _TIER_ENUMERATION_[tierId][ldaIndexForThisTier] = ldaId;

        // Track where this ldaId is in the "list"
        _TIER_ENUMERATION_INDEX_[ldaId] = ldaIndexForThisTier;

        _OWNERS_[ldaId] = to;
    }

    /**
     * @dev Inspired by https://github.com/OpenZeppelin/openzeppelin-contracts/blob/6f23efa97056e643cefceedf86fdf1206b6840fb/contracts/token/ERC721/extensions/ERC721Enumerable.sol#L118
     */
    function _removeLDAFromTierTracking(
        address from,
        uint256 ldaId,
        uint128 tierId
    )
        internal
    {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastLdaIndex = _CURRENT_SUPPLY_[tierId] - 1;
        uint256 tokenIndex = _TIER_ENUMERATION_INDEX_[ldaId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastLdaIndex) {
            uint256 lastLdaId = _TIER_ENUMERATION_[tierId][lastLdaIndex];

            _TIER_ENUMERATION_[tierId][tokenIndex] = lastLdaId; // Move the last LDA to the slot of the to-delete LDA
            _TIER_ENUMERATION_INDEX_[lastLdaId] = tokenIndex; // Update the moved LDA's index

        }
        // This also deletes the contents at the last position of the array
        delete _TIER_ENUMERATION_INDEX_[ldaId];
        delete _TIER_ENUMERATION_[tierId][lastLdaIndex];

        _OWNERS_[ldaId] = from;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC1155Upgradeable.sol";
import "./IERC1155ReceiverUpgradeable.sol";
import "./extensions/IERC1155MetadataURIUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../utils/introspection/ERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155Upgradeable is Initializable, ContextUpgradeable, ERC165Upgradeable, IERC1155Upgradeable, IERC1155MetadataURIUpgradeable {
    using AddressUpgradeable for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    function __ERC1155_init(string memory uri_) internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __ERC1155_init_unchained(uri_);
    }

    function __ERC1155_init_unchained(string memory uri_) internal initializer {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return
            interfaceId == type(IERC1155Upgradeable).interfaceId ||
            interfaceId == type(IERC1155MetadataURIUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: balance query for the zero address");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(_msgSender() != operator, "ERC1155: setting approval status for self");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, _asSingletonArray(id), _asSingletonArray(amount), data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `account`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - If `account` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(account != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), account, _asSingletonArray(id), _asSingletonArray(amount), data);

        _balances[id][account] += amount;
        emit TransferSingle(operator, address(0), account, id, amount);

        _doSafeTransferAcceptanceCheck(operator, address(0), account, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `account`
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address account,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(account != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, account, address(0), _asSingletonArray(id), _asSingletonArray(amount), "");

        uint256 accountBalance = _balances[id][account];
        require(accountBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][account] = accountBalance - amount;
        }

        emit TransferSingle(operator, account, address(0), id, amount);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(account != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, account, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 accountBalance = _balances[id][account];
            require(accountBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][account] = accountBalance - amount;
            }
        }

        emit TransferBatch(operator, account, address(0), ids, amounts);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155ReceiverUpgradeable(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155ReceiverUpgradeable(to).onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155ReceiverUpgradeable(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155ReceiverUpgradeable(to).onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
    uint256[47] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s;
        uint8 v;
        assembly {
            s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            v := add(shr(255, vs), 27)
        }
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IRoyal1155LDA {

    function tierBalanceOf(
        uint128 tierId,
        address owner
    )
        external
        view
        returns (uint256);

    function getOwnedTokens(
        uint128 tierId,
        address owner
    )
        external
        view
        returns (uint256[] memory);

    function getTierTotalSupply(
        uint128 tierId
    )
        external
        view
        returns (uint256);

    function tierExists(
        uint128 tierId
    )
        external
        view
        returns (bool);

    function mintable(
        uint128 tierId
    )
        external
        view
        returns (bool);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

/**
 * @title IRoyalExtrasToken
 * @author Royal
 *
 * @notice Specifies the callback functions that a token contract must implement in order to
 *  integrate with the redeemable token extras interface specified by IRoyalExtras.
 */
interface IRoyalExtrasToken {

    /**
     * @notice Callback function to be called when a new extra is registered to a set of tokens.
     */
    function onExtraRegistered(
        uint256 extraId,
        address registerer,
        uint256 startCanonicalTokenId,
        uint256 endCanonicalTokenId
    )
        external;

    /**
     * @notice Callback function to be called when an extra is redeemed.
     */
    function onExtraRedeemed(
        uint256 extraId,
        uint256 tokenId,
        address redeemer
    )
        external;

    /**
     * @notice Returns the “canonical” form of a token ID, which does not change even as extras
     *  are redeemed for a token.
     */
    function getCanonicalTokenId(
        uint256 tokenId
    )
        external
        view
        returns(uint256);
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

/**
 * @dev Interface for a contract with a callback hook to be called upon LDA transfers.
 */
interface ILdaTransferHook {

    function beforeLdaTransfer(
        address from,
        address to,
        uint128 tierId
    )
        external;
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

/**
 * @title RoyalUtil
 * @author Royal
 * @notice Supports common operations on LDA IDs.
 *
 * ROYAL LDA ID FORMAT V2 OVERVIEW
 *
 *  The ID of a royal LDA contains 3 pieces of information:
 *
 *    1. Tier ID: Denotes te tier that this token belongs to (e.g. GOLD, PLATINUM, DIAMOND).
 *       A tier ID is globally unique across all Royal drops.
 *
 *    2. Version: Represents the version, which may change with certain significant events such as
 *       the redemption of token extras. Including the version in the LDA ID ensures that
 *       marketplace bids and asks are invalidated when the token version changes.
 *
 *    3. Token ID: Represents the token number within the specific tier. We generally start
 *       at token #1 and count up to the tier max supply, but that is not strictly necessary.
 *
 *
 *  These parts are laid out in the uint256 LDA ID as follows:
 *
 *   MSB                                                 LSB
 *    [ tier_id             | version | token_id          ]
 *    [ **** **** **** **** | **      | ** **** **** **** ]
 *    [ 128 bits            | 16 bits | 112 bits          ]
 */
library RoyalUtil {

    uint256 constant UPPER_ISSUANCE_ID_MASK = uint256(type(uint128).max) << 128;
    uint256 constant LOWER_TOKEN_ID_MASK = type(uint112).max;
    uint256 constant TOKEN_VERSION_MASK =
        uint256(type(uint128).max) ^ LOWER_TOKEN_ID_MASK;

    /**
     * @dev Compose an LDA ID from its composite parts.
     */
    function composeLDA_ID(
        uint128 tierID,
        uint256 version,
        uint128 tokenID
    )
        internal
        pure
        returns (uint256 ldaID)
    {
        require(
            tierID != 0 && tokenID != 0,
            "Invalid ldaID"
        ); // NOTE: TierID and TokenID > 0

        require(
            version <= type(uint16).max,
            "invalid version"
        );

        return (uint256(tierID) << 128) + (version << 112) + uint256(tokenID);
    }

    /**
     * @dev Decompose a raw LDA ID into its composite parts.
     */
    function decomposeLDA_ID(
        uint256 ldaID
    )
        internal
        pure
        returns (
            uint128 tierID,
            uint256 version,
            uint128 tokenID
        )
    {
        tierID = uint128(ldaID >> 128);
        tokenID = uint128(ldaID & LOWER_TOKEN_ID_MASK);
        version = (ldaID & TOKEN_VERSION_MASK) >> 112;
        require(
            tierID != 0 && tokenID != 0,
            "Invalid ldaID"
        ); // NOTE: TierID and TokenID > 0
    }

    /**
     * @notice Returns the “canonical” form of a token ID, which ignores the version part.
     */
    function getCanonicalTokenId(
        uint256 tokenID
    )
        internal
        pure
        returns (uint256)
    {
        return tokenID & (TOKEN_VERSION_MASK ^ type(uint256).max);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract RoyalPausableUpgradeable is PausableUpgradeable, OwnableUpgradeable {

    function __RoyalPausableUpgradeable_init() internal initializer {
        __RoyalPausableUpgradeable_init_unchained();
    }

    function __RoyalPausableUpgradeable_init_unchained() internal initializer {
        __Pausable_init();
        __Ownable_init();
    }

    function pause() public virtual whenNotPaused onlyOwner {
        super._pause();
    }

    function unpause() public virtual whenPaused onlyOwner {
        super._unpause();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155Upgradeable is IERC165Upgradeable {
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

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155ReceiverUpgradeable is IERC165Upgradeable {
    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
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

pragma solidity ^0.8.0;

import "../IERC1155Upgradeable.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURIUpgradeable is IERC1155Upgradeable {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
        return _verifyCallResult(success, returndata, errorMessage);
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
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
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

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal initializer {
        __ERC165_init_unchained();
    }

    function __ERC165_init_unchained() internal initializer {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal initializer {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal initializer {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    uint256[49] private __gap;
}