// SPDX-License-Identifier: Apache-2.0

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                           //
//                      _'                    AAA                                                                                            //
//                    !jz_                   A:::A                                                                                           //
//                 ;Lzzzz-                  A:::::A                                                                                          //
//              '1zzzzxzz'                 A:::::::A                                                                                         //
//            !xzzzzzzi~                  A:::::::::A             ssssssssss   ppppp   ppppppppp       eeeeeeeeeeee    nnnn  nnnnnnnn        //
//         ;izzzzzzj^`                   A:::::A:::::A          ss::::::::::s  p::::ppp:::::::::p    ee::::::::::::ee  n:::nn::::::::nn      //
//              `;^.`````               A:::::A A:::::A       ss:::::::::::::s p:::::::::::::::::p  e::::::eeeee:::::een::::::::::::::nn     //
//              -;;;;;;;-              A:::::A   A:::::A      s::::::ssss:::::spp::::::ppppp::::::pe::::::e     e:::::enn:::::::::::::::n    //
//           .;;;;;;;_                A:::::A     A:::::A      s:::::s  ssssss  p:::::p     p:::::pe:::::::eeeee::::::e  n:::::nnnn:::::n    //
//         ;;;;;;;;`                 A:::::AAAAAAAAA:::::A       s::::::s       p:::::p     p:::::pe:::::::::::::::::e   n::::n    n::::n    //
//      _;;;;;;;'                   A:::::::::::::::::::::A         s::::::s    p:::::p     p:::::pe::::::eeeeeeeeeee    n::::n    n::::n    //
//            ;{jjjjjjjjj          A:::::AAAAAAAAAAAAA:::::A  ssssss   s:::::s  p:::::p    p::::::pe:::::::e             n::::n    n::::n    //
//         `+IIIVVVVVVVVI`        A:::::A             A:::::A s:::::ssss::::::s p:::::ppppp:::::::pe::::::::e            n::::n    n::::n    //
//       ^sIVVVVVVVVVVVVI`       A:::::A               A:::::As::::::::::::::s  p::::::::::::::::p  e::::::::eeeeeeee    n::::n    n::::n    //
//    ~xIIIVVVVVVVVVVVVVI`      A:::::A                 A:::::As:::::::::::ss   p::::::::::::::pp    ee:::::::::::::e    n::::n    n::::n    //
//  -~~~;;;;;;;;;;;;;;;;;      AAAAAAA                   AAAAAAAsssssssssss     p::::::pppppppp        eeeeeeeeeeeeee    nnnnnn    nnnnnn    //
//                                                                              p:::::p                                                      //
//                                                                              p:::::p                                                      //
//                                                                             p:::::::p                                                     //
//                                                                             p:::::::p                                                     //
//                                                                             p:::::::p                                                     //
//                                                                             ppppppppp                                                     //
//                                                                                                                                           //
//  Website: https://aspenft.io/                                                                                                             //
//  Twitter: https://twitter.com/aspenft                                                                                                     //
//                                                                                                                                           //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

pragma solidity ^0.8;

//  ==========  External imports    ==========
import "@openzeppelin/contracts/utils/Address.sol";

/// ========== Features ==========
import "./openzeppelin-presets/metatx/ERC2771ContextUpgradeable.sol";
import "../generated/impl/BaseAspenERC1155DropV1.sol";

import "./lib/FeeType.sol";
import "./lib/MerkleProof.sol";

import "./errors/IErrors.sol";

import "./types/DropERC1155DataTypes.sol";
import "./AspenERC1155DropLogic.sol";

import "../terms/types/TermsDataTypes.sol";
import "../terms/lib/TermsLogic.sol";

import "./AspenERC1155DropStorage.sol";
import "../api/issuance/IDropClaimCondition.sol";

/// @title The AspenERC1155Drop contract
contract AspenERC1155Drop is AspenERC1155DropStorage, BaseAspenERC1155DropV1 {
    /// ================================
    /// =========== Libraries ==========
    /// ================================
    using StringsUpgradeable for uint256;
    using TermsLogic for TermsDataTypes.Terms;
    using AspenERC1155DropLogic for DropERC1155DataTypes.ClaimData;

    /// ====================================================
    /// ========== Constructor + initializer logic =========
    /// ====================================================
    constructor() {}

    /// @dev Initializes the contract, like a constructor.
    function initialize(
        address _defaultAdmin,
        string memory _name,
        string memory _symbol,
        string memory _contractURI,
        address[] memory _trustedForwarders,
        address _saleRecipient,
        address _royaltyRecipient,
        uint128 _royaltyBps,
        string memory _userAgreement,
        uint128 _platformFeeBps,
        address _platformFeeRecipient,
        address _drop1155DelegateLogic
    ) external initializer {
        // Initialize inherited contracts, most base-like -> most derived.
        __ReentrancyGuard_init();
        __ERC2771Context_init_unchained(_trustedForwarders);
        __ERC1155_init_unchained("");
        __DefaultOperatorFilterer_init();
        __EIP712_init(_name, "1.0.0");

        // Initialize this contract's state.
        __name = _name;
        __symbol = _symbol;
        claimData.royaltyRecipient = _royaltyRecipient;
        claimData.royaltyBps = uint16(_royaltyBps);
        _primarySaleRecipient = _saleRecipient;
        _owner = _defaultAdmin;
        _contractUri = _contractURI;
        claimData.platformFeeRecipient = _platformFeeRecipient;
        claimData.platformFeeBps = uint16(_platformFeeBps);
        claimData.nextTokenIdToMint = TOKEN_INDEX_OFFSET;
        // Agreement initialize
        termsData.termsURI = _userAgreement;
        // We set the terms version to 1 if there is an actual termsURL
        if (bytes(_userAgreement).length > 0) {
            termsData.termsVersion = 1;
            termsData.termsActivated = true;
        }
        delegateLogicContract = _drop1155DelegateLogic;
        operatorFiltererEnabled = true;

        _setupRole(DEFAULT_ADMIN_ROLE, _defaultAdmin);
        _setupRole(MINTER_ROLE, _defaultAdmin);
        _setupRole(TRANSFER_ROLE, _defaultAdmin);
        _setupRole(TRANSFER_ROLE, address(0));
        _setupRole(ISSUER_ROLE, _defaultAdmin);

        emit OwnershipTransferred(address(0), _defaultAdmin);
    }

    fallback() external {
        // get facet from function selector
        address logic = delegateLogicContract;
        require(logic != address(0));
        // Execute external function from delegate logic contract using delegatecall and return any value.
        assembly {
            // copy function selector and any arguments
            calldatacopy(0, 0, calldatasize())
            // execute function call using the facet
            let result := delegatecall(gas(), logic, 0, calldatasize(), 0, 0)
            // get any return value
            returndatacopy(0, 0, returndatasize())
            // return any return value or error back to the caller
            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /// ============================================
    /// ========== Generic contract logic ==========
    /// ============================================
    /// @dev Returns the address of the current owner.
    function owner() public view override returns (address) {
        return _owner;
    }

    /// @dev Returns the name of the token.
    function name() public view override returns (string memory) {
        return __name;
    }

    /// @dev Returns the symbol of the token.
    function symbol() public view override returns (string memory) {
        return __symbol;
    }

    /// @dev See ERC 1155 - Returns the URI for a given tokenId.
    function uri(uint256 _tokenId)
        public
        view
        virtual
        override(ERC1155Upgradeable, IAspenSFTMetadataV1)
        isValidTokenId(_tokenId)
        returns (string memory _tokenURI)
    {
        return AspenERC1155DropLogic.tokenURI(claimData, _tokenId);
    }

    /// @dev See ERC-2891 - Returns the royalty recipient and amount, given a tokenId and sale price.
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        virtual
        override
        isValidTokenId(tokenId)
        returns (address receiver, uint256 royaltyAmount)
    {
        return AspenERC1155DropLogic.royaltyInfo(claimData, tokenId, salePrice);
    }

    /// @dev See ERC 165
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(BaseAspenERC1155DropV1, AspenERC1155DropStorage)
        returns (bool)
    {
        return
            AspenERC1155DropStorage.supportsInterface(interfaceId) ||
            BaseAspenERC1155DropV1.supportsInterface(interfaceId) ||
            // Support ERC4906
            interfaceId == bytes4(0x49064906);
    }

    // More pointless yet required overrides
    function totalSupply(uint256 _tokenId) public view override isValidTokenId(_tokenId) returns (uint256) {
        return claimData.totalSupply[_tokenId];
    }

    function exists(uint256 _tokenId) public view override isValidTokenId(_tokenId) returns (bool) {
        return claimData.totalSupply[_tokenId] > 0;
    }

    /// @dev returns the total number of unique tokens in existence.
    function getLargestTokenId() public view override returns (uint256) {
        return claimData.nextTokenIdToMint - TOKEN_INDEX_OFFSET;
    }

    /// @dev Returns the offset for token IDs.
    function getSmallestTokenId() external pure override returns (uint8) {
        return TOKEN_INDEX_OFFSET;
    }

    /// ======================================
    /// ============= Claim logic ============
    /// ======================================
    /// @dev Lets an account claim a given quantity of NFTs, of a single tokenId.
    function claim(
        address _receiver,
        uint256 _tokenId,
        uint256 _quantity,
        address _currency,
        uint256 _pricePerToken,
        bytes32[] calldata _proofs,
        uint256 _proofMaxQuantityPerTransaction
    ) external payable override nonReentrant isValidTokenId(_tokenId) {
        address msgSender = _msgSender();
        if (!(isTrustedForwarder(msg.sender) || msgSender == tx.origin)) revert Bot();
        if (claimIsPaused) revert ClaimPaused();

        AspenERC1155DropLogic.InternalClaim memory internalClaim = AspenERC1155DropLogic.executeClaim(
            claimData,
            _tokenId,
            _quantity,
            _currency,
            _pricePerToken,
            _proofs,
            _proofMaxQuantityPerTransaction,
            msgSender,
            _primarySaleRecipient
        );
        _mint(_receiver, _tokenId, _quantity, "");
        emit TokensClaimed(
            internalClaim.activeConditionId,
            _tokenId,
            msgSender,
            _receiver,
            _quantity,
            internalClaim.phaseId
        );
    }

    /// @dev Checks a request to claim NFTs against the active claim condition's criteria.
    function verifyClaim(
        uint256 _conditionId,
        address _claimer,
        uint256 _tokenId,
        uint256 _quantity,
        address _currency,
        uint256 _pricePerToken,
        bool verifyMaxQuantityPerTransaction
    ) public view override isValidTokenId(_tokenId) {
        AspenERC1155DropLogic.verifyClaim(
            claimData,
            _conditionId,
            _claimer,
            _tokenId,
            _quantity,
            _currency,
            _pricePerToken,
            verifyMaxQuantityPerTransaction
        );
    }

    /// ======================================
    /// ============ Agreement ===============
    /// ======================================
    /// @notice by signing this transaction, you are confirming that you have read and agreed to the terms of use at `termsUrl`
    function acceptTerms() external override {
        termsData.acceptTerms(_msgSender());
        emit TermsAccepted(termsData.termsURI, termsData.termsVersion, _msgSender());
    }

    /// @notice returns the details of the terms
    /// @return termsURI - the URI of the terms
    /// @return termsVersion - the version of the terms
    /// @return termsActivated - the status of the terms
    function getTermsDetails()
        external
        view
        override
        returns (
            string memory termsURI,
            uint8 termsVersion,
            bool termsActivated
        )
    {
        return termsData.getTermsDetails();
    }

    /// @notice returns true if an address has accepted the terms
    function hasAcceptedTerms(address _address) external view override returns (bool hasAccepted) {
        hasAccepted = termsData.hasAcceptedTerms(_address);
    }

    /// @notice returns true if an address has accepted the terms
    function hasAcceptedTerms(address _address, uint8 _termsVersion) external view override returns (bool hasAccepted) {
        hasAccepted = termsData.hasAcceptedTerms(_address, _termsVersion);
    }

    /// ======================================
    /// ========== Getter functions ==========
    /// ======================================
    /// @dev Contract level metadata.
    function contractURI() external view override(IPublicMetadataV0) returns (string memory) {
        return _contractUri;
    }

    /// @dev Returns the sale recipient address.
    function primarySaleRecipient() external view override returns (address) {
        return _primarySaleRecipient;
    }

    /// @dev Returns the platform fee recipient and bps.
    function getPlatformFeeInfo() external view override returns (address, uint16) {
        return (claimData.platformFeeRecipient, uint16(claimData.platformFeeBps));
    }

    /// @dev Returns the default royalty recipient and bps.
    function getDefaultRoyaltyInfo() external view override returns (address, uint16) {
        return (claimData.royaltyRecipient, uint16(claimData.royaltyBps));
    }

    /// @dev Returns the royalty recipient and bps for a particular token Id.
    function getRoyaltyInfoForToken(uint256 _tokenId)
        public
        view
        override
        isValidTokenId(_tokenId)
        returns (address, uint16)
    {
        return AspenERC1155DropLogic.getRoyaltyInfoForToken(claimData, _tokenId);
    }

    /// @dev Returns the claim condition at the given uid.
    function getClaimConditionById(uint256 _tokenId, uint256 _conditionId)
        external
        view
        isValidTokenId(_tokenId)
        returns (ClaimCondition memory condition)
    {
        condition = AspenERC1155DropLogic.getClaimConditionById(claimData, _tokenId, _conditionId);
    }

    /// @dev Expose the current active claim condition including claim limits
    function getActiveClaimConditions(uint256 _tokenId)
        external
        view
        override
        isValidTokenId(_tokenId)
        returns (
            ClaimCondition memory condition,
            uint256 conditionId,
            uint256 walletMaxClaimCount,
            uint256 tokenSupply,
            uint256 maxTotalSupply,
            bool isClaimPaused
        )
    {
        (condition, conditionId, walletMaxClaimCount, maxTotalSupply) = AspenERC1155DropLogic.getActiveClaimConditions(
            claimData,
            _tokenId
        );
        isClaimPaused = claimIsPaused;
        tokenSupply = totalSupply(_tokenId);
    }

    /// @dev Expose the user specific limits related to the current active claim condition
    function getUserClaimConditions(uint256 _tokenId, address _claimer)
        external
        view
        override
        isValidTokenId(_tokenId)
        returns (
            uint256 conditionId,
            uint256 walletClaimedCount,
            uint256 walletClaimedCountInPhase,
            uint256 lastClaimTimestamp,
            uint256 nextValidClaimTimestamp
        )
    {
        return AspenERC1155DropLogic.getUserClaimConditions(claimData, _tokenId, _claimer);
    }

    /// @dev Gets the base URI indices
    function getBaseURIIndices() external view override returns (uint256[] memory) {
        return claimData.baseURIIndices;
    }

    /// ======================================
    /// ==== OS Default Operator Filterer ====
    /// ======================================
    modifier onlyAllowedOperator(address from) override {
        if (operatorFiltererEnabled) {
            // Check registry code length to facilitate testing in environments without a deployed registry.
            if (address(operatorFilterRegistry).code.length > 0) {
                // Allow spending tokens from addresses with balance
                // Note that this still allows listings and marketplaces with escrow to transfer tokens if transferred
                // from an EOA.
                if (from == msg.sender) {
                    _;
                    return;
                }
                if (!operatorFilterRegistry.isOperatorAllowed(address(this), msg.sender)) {
                    revert OperatorNotAllowed(msg.sender);
                }
            }
        }
        _;
    }

    modifier onlyAllowedOperatorApproval(address operator) override {
        if (operatorFiltererEnabled) {
            // Check registry code length to facilitate testing in environments without a deployed registry.
            if (address(operatorFilterRegistry).code.length > 0) {
                if (!operatorFilterRegistry.isOperatorAllowed(address(this), operator)) {
                    revert OperatorNotAllowed(operator);
                }
            }
        }
        _;
    }

    function setApprovalForAll(address operator, bool approved)
        public
        override(ERC1155Upgradeable, IERC1155Upgradeable)
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        uint256 amount,
        bytes memory data
    ) public override(ERC1155Upgradeable, IERC1155Upgradeable) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, amount, data);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override(ERC1155Upgradeable, IERC1155Upgradeable) onlyAllowedOperator(from) {
        super.safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /// ======================================
    /// =========== Miscellaneous ============
    /// ======================================
    /// @dev Concrete implementation semantic version -
    ///         provided for completeness but not designed to be the point of dispatch
    function minorVersion() public pure override returns (uint256 minor, uint256 patch) {
        minor = 0;
        patch = 0;
    }

    /// @dev Lets a token owner burn the tokens they own (i.e. destroy for good)
    function burn(
        address account,
        uint256 id,
        uint256 value
    ) public virtual {
        if (!(account == _msgSender() || isApprovedForAll(account, _msgSender()))) revert InvalidPermission();
        _burn(account, id, value);
    }

    /// @dev Lets a token owner burn multiple tokens they own at once (i.e. destroy for good)
    function burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory values
    ) public virtual {
        if (!(account == _msgSender() || isApprovedForAll(account, _msgSender()))) revert InvalidPermission();
        _burnBatch(account, ids, values);
    }

    /// @dev Provides a function to batch together multiple calls in a single external call.
    function multicall(bytes[] calldata data) external override returns (bytes[] memory results) {
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            results[i] = Address.functionDelegateCall(address(this), data[i]);
        }
        return results;
    }

    function _msgSender() internal view virtual override returns (address sender) {
        return ERC2771ContextUpgradeable._msgSender();
    }

    function _msgData() internal view virtual override returns (bytes calldata) {
        return ERC2771ContextUpgradeable._msgData();
    }

    // FIXME: well, fix solc, this is a horrible hack to make these library-emitted events appear in the ABI for this
    //   contract
    function __termsNotAccepted() external pure {
        revert TermsNotAccepted(address(0), "", uint8(0));
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8;

import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/IAccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "./errors/IErrors.sol";
import "./lib/CurrencyTransferLib.sol";
import "./lib/MerkleProof.sol";
import "./types/DropERC1155DataTypes.sol";
import "./../api/issuance/IDropClaimCondition.sol";
import "./../api/royalties/IRoyalty.sol";
import "../terms/types/TermsDataTypes.sol";

library AspenERC1155DropLogic {
    using StringsUpgradeable for uint256;
    using AspenERC1155DropLogic for DropERC1155DataTypes.ClaimData;
    using CountersUpgradeable for CountersUpgradeable.Counter;

    uint256 public constant MAX_UINT256 = 2**256 - 1;
    /// @dev Max basis points (bps) in Aspen system.
    uint256 public constant MAX_BPS = 10_000;
    /// @dev Offset for token IDs.
    uint8 public constant TOKEN_INDEX_OFFSET = 1;
    /// @dev Only transfers to or from TRANSFER_ROLE holders are valid, when transfers are restricted.
    bytes32 public constant TRANSFER_ROLE = keccak256("TRANSFER_ROLE");

    struct InternalClaim {
        bool validMerkleProof;
        uint256 merkleProofIndex;
        bool toVerifyMaxQuantityPerTransaction;
        uint256 activeConditionId;
        uint256 tokenIdToClaim;
        bytes32 phaseId;
    }

    function setClaimConditions(
        DropERC1155DataTypes.ClaimData storage claimData,
        uint256 _tokenId,
        IDropClaimConditionV1.ClaimCondition[] calldata _phases,
        bool _resetClaimEligibility
    ) external {
        if ((claimData.nextTokenIdToMint <= _tokenId)) revert InvalidTokenId(_tokenId);
        IDropClaimConditionV1.ClaimConditionList storage condition = claimData.claimCondition[_tokenId];
        uint256 existingStartIndex = condition.currentStartId;
        uint256 existingPhaseCount = condition.count;

        /**
         *  `limitLastClaimTimestamp` and `limitMerkleProofClaim` are mappings that use a
         *  claim condition's UID as a key.
         *
         *  If `_resetClaimEligibility == true`, we assign completely new UIDs to the claim
         *  conditions in `_phases`, effectively resetting the restrictions on claims expressed
         *  by `limitLastClaimTimestamp` and `limitMerkleProofClaim`.
         */
        uint256 newStartIndex = existingStartIndex;
        if (_resetClaimEligibility) {
            newStartIndex = existingStartIndex + existingPhaseCount;
        }

        condition.count = _phases.length;
        condition.currentStartId = newStartIndex;

        uint256 lastConditionStartTimestamp;
        bytes32[] memory phaseIds = new bytes32[](_phases.length);
        for (uint256 i = 0; i < _phases.length; i++) {
            if (!(i == 0 || lastConditionStartTimestamp < _phases[i].startTimestamp)) revert InvalidTime();

            for (uint256 j = 0; j < phaseIds.length; j++) {
                if (phaseIds[j] == _phases[i].phaseId) revert InvalidPhaseId(_phases[i].phaseId);
                if (i == j) phaseIds[i] = _phases[i].phaseId;
            }

            uint256 supplyClaimedAlready = condition.phases[newStartIndex + i].supplyClaimed;

            if (_isOutOfLimits(_phases[i].maxClaimableSupply, supplyClaimedAlready))
                revert CrossedLimitMaxClaimableSupply();

            condition.phases[newStartIndex + i] = _phases[i];
            condition.phases[newStartIndex + i].supplyClaimed = supplyClaimedAlready;
            if (_phases[i].maxClaimableSupply == 0)
                condition.phases[newStartIndex + i].maxClaimableSupply = MAX_UINT256;

            lastConditionStartTimestamp = _phases[i].startTimestamp;
        }

        /**
         *  Gas refunds (as much as possible)
         *
         *  If `_resetClaimEligibility == true`, we assign completely new UIDs to the claim
         *  conditions in `_phases`. So, we delete claim conditions with UID < `newStartIndex`.
         *
         *  If `_resetClaimEligibility == false`, and there are more existing claim conditions
         *  than in `_phases`, we delete the existing claim conditions that don't get replaced
         *  by the conditions in `_phases`.
         */
        if (_resetClaimEligibility) {
            for (uint256 i = existingStartIndex; i < newStartIndex; i++) {
                delete condition.phases[i];
            }
        } else {
            if (existingPhaseCount > _phases.length) {
                for (uint256 i = _phases.length; i < existingPhaseCount; i++) {
                    delete condition.phases[newStartIndex + i];
                }
            }
        }
    }

    function executeClaim(
        DropERC1155DataTypes.ClaimData storage claimData,
        uint256 _tokenId,
        uint256 _quantity,
        address _currency,
        uint256 _pricePerToken,
        bytes32[] calldata _proofs,
        uint256 _proofMaxQuantityPerTransaction,
        address msgSender,
        address primarySaleRecipient
    ) public returns (InternalClaim memory internalData) {
        if ((claimData.nextTokenIdToMint <= _tokenId)) revert InvalidTokenId(_tokenId);
        // Get the active claim condition index.
        internalData.activeConditionId = getActiveClaimConditionId(claimData, _tokenId);
        internalData.phaseId = claimData.claimCondition[_tokenId].phases[internalData.activeConditionId].phaseId;

        /**
         *  We make allowlist checks (i.e. verifyClaimMerkleProof) before verifying the claim's general
         *  validity (i.e. verifyClaim) because we give precedence to the check of allow list quantity
         *  restriction over the check of the general claim condition's quantityLimitPerTransaction
         *  restriction.
         */
        (internalData.validMerkleProof, internalData.merkleProofIndex) = verifyClaimMerkleProof(
            claimData,
            internalData.activeConditionId,
            msgSender,
            _tokenId,
            _quantity,
            _proofs,
            _proofMaxQuantityPerTransaction
        );

        // Verify claim validity. If not valid, revert.
        // when there's allowlist present --> verifyClaimMerkleProof will verify the _proofMaxQuantityPerTransaction value with hashed leaf in the allowlist
        // when there's no allowlist, this check is true --> verifyClaim will check for _quantity being less/equal than the limit
        internalData.toVerifyMaxQuantityPerTransaction =
            _proofMaxQuantityPerTransaction == 0 ||
            claimData.claimCondition[_tokenId].phases[internalData.activeConditionId].merkleRoot == bytes32(0);

        verifyClaim(
            claimData,
            internalData.activeConditionId,
            msgSender,
            _tokenId,
            _quantity,
            _currency,
            _pricePerToken,
            internalData.toVerifyMaxQuantityPerTransaction
        );

        // If there's a price, collect price.
        collectClaimPrice(claimData, _quantity, _currency, _pricePerToken, _tokenId, msgSender, primarySaleRecipient);

        // Book-keeping before the calling contract does the actual transfer and mint the relevant NFTs to claimer.
        recordTransferClaimedTokens(claimData, internalData.activeConditionId, _tokenId, _quantity, msgSender);
    }

    /// @dev Verify inclusion in allow-list.
    function verifyClaimMerkleProof(
        DropERC1155DataTypes.ClaimData storage claimData,
        uint256 _conditionId,
        address _claimer,
        uint256 _tokenId,
        uint256 _quantity,
        bytes32[] calldata _proofs,
        uint256 _proofMaxQuantityPerTransaction
    ) public view returns (bool validMerkleProof, uint256 merkleProofIndex) {
        IDropClaimConditionV1.ClaimCondition memory currentClaimPhase = claimData.claimCondition[_tokenId].phases[
            _conditionId
        ];

        if (currentClaimPhase.merkleRoot != bytes32(0)) {
            (validMerkleProof, merkleProofIndex) = MerkleProof.verify(
                _proofs,
                currentClaimPhase.merkleRoot,
                keccak256(abi.encodePacked(_claimer, _proofMaxQuantityPerTransaction))
            );

            if (!validMerkleProof) revert InvalidMerkleProof();
            if (
                !(_proofMaxQuantityPerTransaction == 0 ||
                    _quantity <=
                    _proofMaxQuantityPerTransaction -
                        claimData.claimCondition[_tokenId].userClaims[_conditionId][_claimer].claimedBalance)
            ) revert InvalidMaxQuantityProof();
        }
    }

    /// @dev Checks a request to claim NFTs against the active claim condition's criteria.
    function verifyClaim(
        DropERC1155DataTypes.ClaimData storage claimData,
        uint256 _conditionId,
        address _claimer,
        uint256 _tokenId,
        uint256 _quantity,
        address _currency,
        uint256 _pricePerToken,
        bool verifyMaxQuantityPerTransaction
    ) public view {
        IDropClaimConditionV1.ClaimCondition memory currentClaimPhase = claimData.claimCondition[_tokenId].phases[
            _conditionId
        ];

        if (!(_currency == currentClaimPhase.currency && _pricePerToken == currentClaimPhase.pricePerToken)) {
            revert InvalidPrice();
        }
        if (
            !(_quantity > 0 &&
                (!verifyMaxQuantityPerTransaction || _quantity <= currentClaimPhase.quantityLimitPerTransaction))
        ) {
            revert CrossedLimitQuantityPerTransaction();
        }

        if (!(currentClaimPhase.supplyClaimed + _quantity <= currentClaimPhase.maxClaimableSupply)) {
            revert CrossedLimitMaxClaimableSupply();
        }
        if (_isOutOfLimits(claimData.maxTotalSupply[_tokenId], claimData.totalSupply[_tokenId] + _quantity)) {
            revert CrossedLimitMaxTotalSupply();
        }
        if (
            _isOutOfLimits(
                claimData.maxWalletClaimCount[_tokenId],
                claimData.walletClaimCount[_tokenId][_claimer] + _quantity
            )
        ) {
            revert CrossedLimitMaxWalletClaimCount();
        }

        (uint256 lastClaimTimestamp, uint256 nextValidClaimTimestamp) = getClaimTimestamp(
            claimData,
            _tokenId,
            _conditionId,
            _claimer
        );

        if (!(lastClaimTimestamp == 0 || block.timestamp >= nextValidClaimTimestamp)) revert InvalidTime();
    }

    /// @dev Collects and distributes the primary sale value of NFTs being claimed.
    function collectClaimPrice(
        DropERC1155DataTypes.ClaimData storage claimData,
        uint256 _quantityToClaim,
        address _currency,
        uint256 _pricePerToken,
        uint256 _tokenId,
        address msgSender,
        address primarySaleRecipient
    ) internal {
        if (_pricePerToken == 0) {
            return;
        }

        uint256 totalPrice = _quantityToClaim * _pricePerToken;
        uint256 platformFees = (totalPrice * claimData.platformFeeBps) / MAX_BPS;

        if (_currency == CurrencyTransferLib.NATIVE_TOKEN && !(msg.value == totalPrice)) revert InvalidPaymentAmount();

        address recipient = claimData.saleRecipient[_tokenId] == address(0)
            ? primarySaleRecipient
            : claimData.saleRecipient[_tokenId];

        CurrencyTransferLib.transferCurrency(_currency, msgSender, claimData.platformFeeRecipient, platformFees);
        CurrencyTransferLib.transferCurrency(_currency, msgSender, recipient, totalPrice - platformFees);
    }

    /// @dev Book-keeping before the calling contract does the actual transfer and mint the relevant NFTs to claimer.
    function recordTransferClaimedTokens(
        DropERC1155DataTypes.ClaimData storage claimData,
        uint256 _conditionId,
        uint256 _tokenId,
        uint256 _quantityBeingClaimed,
        address msgSender
    ) public {
        // Update the supply minted under mint condition.
        claimData.claimCondition[_tokenId].phases[_conditionId].supplyClaimed += _quantityBeingClaimed;

        // if transfer claimed tokens is called when to != msg.sender, it'd use msg.sender's limits.
        // behavior would be similar to msg.sender mint for itself, then transfer to `to`.
        claimData.claimCondition[_tokenId].userClaims[_conditionId][msgSender].lastClaimTimestamp = block.timestamp;
        claimData.claimCondition[_tokenId].userClaims[_conditionId][msgSender].claimedBalance += _quantityBeingClaimed;
        claimData.walletClaimCount[_tokenId][msgSender] += _quantityBeingClaimed;
    }

    function verifyIssue(
        DropERC1155DataTypes.ClaimData storage claimData,
        uint256 _tokenId,
        uint256 _quantity
    ) external view {
        if (_quantity == 0) {
            revert InvalidQuantity();
        }

        if (_isOutOfLimits(claimData.maxTotalSupply[_tokenId], claimData.totalSupply[_tokenId] + _quantity)) {
            revert CrossedLimitMaxTotalSupply();
        }
    }

    function setTokenURI(
        DropERC1155DataTypes.ClaimData storage claimData,
        uint256 _tokenId,
        string memory _tokenURI,
        bool _isPermanent
    ) public {
        // Interpret empty string as unsetting tokenURI
        if (bytes(_tokenURI).length == 0) {
            claimData.tokenURIs[_tokenId].sequenceNumber = 0;
            return;
        }
        // Bump the sequence first
        claimData.uriSequenceCounter.increment();
        claimData.tokenURIs[_tokenId].uri = _tokenURI;
        claimData.tokenURIs[_tokenId].sequenceNumber = claimData.uriSequenceCounter.current();
        claimData.tokenURIs[_tokenId].isPermanent = _isPermanent;
    }

    function tokenURI(DropERC1155DataTypes.ClaimData storage claimData, uint256 _tokenId)
        public
        view
        returns (string memory)
    {
        // Try to fetch possibly overridden tokenURI
        DropERC1155DataTypes.SequencedURI storage _tokenURI = claimData.tokenURIs[_tokenId];

        for (uint256 i = 0; i < claimData.baseURIIndices.length; i += 1) {
            if (_tokenId < claimData.baseURIIndices[i] + TOKEN_INDEX_OFFSET) {
                DropERC1155DataTypes.SequencedURI storage _baseURI = claimData.baseURI[
                    claimData.baseURIIndices[i] + TOKEN_INDEX_OFFSET
                ];
                if (_tokenURI.sequenceNumber > _baseURI.sequenceNumber || _tokenURI.isPermanent) {
                    // If the specifically set tokenURI is fresher than the baseURI OR
                    // if the tokenURI is permanet then return that (it is in-force)
                    return _tokenURI.uri;
                }
                // Otherwise either there is no override (sequenceNumber == 0) or the baseURI is fresher, so return the
                // baseURI-derived tokenURI
                return string(abi.encodePacked(_baseURI.uri, _tokenId.toString()));
            }
        }
        return "";
    }

    function lazyMint(
        DropERC1155DataTypes.ClaimData storage claimData,
        uint256 _amount,
        string calldata _baseURIForTokens
    ) public returns (uint256 startId, uint256 baseURIIndex) {
        if (_amount == 0) revert InvalidNoOfTokenIds();
        claimData.uriSequenceCounter.increment();
        startId = claimData.nextTokenIdToMint;
        baseURIIndex = startId + _amount;

        claimData.nextTokenIdToMint = baseURIIndex;
        claimData.baseURI[baseURIIndex].uri = _baseURIForTokens;
        claimData.baseURI[baseURIIndex].sequenceNumber = claimData.uriSequenceCounter.current();
        claimData.baseURI[baseURIIndex].amountOfTokens = _amount;
        claimData.baseURIIndices.push(baseURIIndex - TOKEN_INDEX_OFFSET);
    }

    /// @dev Expose the current active claim condition including claim limits
    function getActiveClaimConditions(DropERC1155DataTypes.ClaimData storage claimData, uint256 _tokenId)
        public
        view
        returns (
            IDropClaimConditionV1.ClaimCondition memory condition,
            uint256 conditionId,
            uint256 walletMaxClaimCount,
            uint256 maxTotalSupply
        )
    {
        conditionId = getActiveClaimConditionId(claimData, _tokenId);
        condition = claimData.claimCondition[_tokenId].phases[conditionId];
        walletMaxClaimCount = claimData.maxWalletClaimCount[_tokenId];
        maxTotalSupply = claimData.maxTotalSupply[_tokenId];
    }

    /// @dev Returns the user specific limits related to the current active claim condition
    function getUserClaimConditions(
        DropERC1155DataTypes.ClaimData storage claimData,
        uint256 _tokenId,
        address _claimer
    )
        public
        view
        returns (
            uint256 conditionId,
            uint256 walletClaimedCount,
            uint256 walletClaimedCountInPhase,
            uint256 lastClaimTimestamp,
            uint256 nextValidClaimTimestamp
        )
    {
        conditionId = getActiveClaimConditionId(claimData, _tokenId);
        (lastClaimTimestamp, nextValidClaimTimestamp) = getClaimTimestamp(claimData, _tokenId, conditionId, _claimer);
        walletClaimedCount = claimData.walletClaimCount[_tokenId][_claimer];
        walletClaimedCountInPhase = claimData.claimCondition[_tokenId].userClaims[conditionId][_claimer].claimedBalance;
    }

    /// @dev Returns the current active claim condition ID.
    function getActiveClaimConditionId(DropERC1155DataTypes.ClaimData storage claimData, uint256 _tokenId)
        public
        view
        returns (uint256)
    {
        IDropClaimConditionV1.ClaimConditionList storage conditionList = claimData.claimCondition[_tokenId];
        for (uint256 i = conditionList.currentStartId + conditionList.count; i > conditionList.currentStartId; i--) {
            if (block.timestamp >= conditionList.phases[i - 1].startTimestamp) {
                return i - 1;
            }
        }

        revert NoActiveMintCondition();
    }

    /// @dev Returns the claim condition at the given uid.
    function getClaimConditionById(
        DropERC1155DataTypes.ClaimData storage claimData,
        uint256 _tokenId,
        uint256 _conditionId
    ) external view returns (IDropClaimConditionV1.ClaimCondition memory condition) {
        condition = claimData.claimCondition[_tokenId].phases[_conditionId];
    }

    /// @dev Returns the timestamp for when a claimer is eligible for claiming NFTs again.
    function getClaimTimestamp(
        DropERC1155DataTypes.ClaimData storage claimData,
        uint256 _tokenId,
        uint256 _conditionId,
        address _claimer
    ) public view returns (uint256 lastClaimTimestamp, uint256 nextValidClaimTimestamp) {
        lastClaimTimestamp = claimData.claimCondition[_tokenId].userClaims[_conditionId][_claimer].lastClaimTimestamp;

        unchecked {
            nextValidClaimTimestamp =
                lastClaimTimestamp +
                claimData.claimCondition[_tokenId].phases[_conditionId].waitTimeInSecondsBetweenClaims;

            if (nextValidClaimTimestamp < lastClaimTimestamp) {
                nextValidClaimTimestamp = type(uint256).max;
            }
        }
    }

    /// @dev Returns the royalty recipient and bps for a particular token Id.
    function getRoyaltyInfoForToken(DropERC1155DataTypes.ClaimData storage claimData, uint256 _tokenId)
        public
        view
        returns (address, uint16)
    {
        IRoyaltyV0.RoyaltyInfo memory royaltyForToken = claimData.royaltyInfoForToken[_tokenId];

        return
            royaltyForToken.recipient == address(0)
                ? (claimData.royaltyRecipient, uint16(claimData.royaltyBps))
                : (royaltyForToken.recipient, uint16(royaltyForToken.bps));
    }

    /// @dev See ERC-2891 - Returns the royalty recipient and amount, given a tokenId and sale price.
    function royaltyInfo(
        DropERC1155DataTypes.ClaimData storage claimData,
        uint256 tokenId,
        uint256 salePrice
    ) external view returns (address receiver, uint256 royaltyAmount) {
        (address recipient, uint256 bps) = getRoyaltyInfoForToken(claimData, tokenId);
        receiver = recipient;
        royaltyAmount = (salePrice * bps) / MAX_BPS;
    }

    function setDefaultRoyaltyInfo(
        DropERC1155DataTypes.ClaimData storage claimData,
        address _royaltyRecipient,
        uint256 _royaltyBps
    ) external {
        if (!(_royaltyBps <= MAX_BPS)) revert MaxBps();

        claimData.royaltyRecipient = _royaltyRecipient;
        claimData.royaltyBps = uint16(_royaltyBps);
    }

    function setRoyaltyInfoForToken(
        DropERC1155DataTypes.ClaimData storage claimData,
        uint256 _tokenId,
        address _recipient,
        uint256 _bps
    ) external {
        if (!(_bps <= MAX_BPS)) revert MaxBps();

        claimData.royaltyInfoForToken[_tokenId] = IRoyaltyV0.RoyaltyInfo({recipient: _recipient, bps: _bps});
    }

    /// @dev See {ERC1155-_beforeTokenTransfer}.
    function beforeTokenTransfer(
        DropERC1155DataTypes.ClaimData storage claimData,
        TermsDataTypes.Terms storage termsData,
        IAccessControlUpgradeable accessControl,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts
    ) external {
        // if transfer is restricted on the contract, we still want to allow burning and minting
        if (!accessControl.hasRole(TRANSFER_ROLE, address(0)) && from != address(0) && to != address(0)) {
            if (!(accessControl.hasRole(TRANSFER_ROLE, from) || accessControl.hasRole(TRANSFER_ROLE, to)))
                revert InvalidPermission();
        }

        if (to != address(this)) {
            if (termsData.termsActivated) {
                if (!termsData.termsAccepted[to] || termsData.termsVersion != termsData.acceptedVersion[to])
                    revert TermsNotAccepted(to, termsData.termsURI, termsData.termsVersion);
            }
        }

        if (from == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                claimData.totalSupply[ids[i]] += amounts[i];
            }
        }

        if (to == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                claimData.totalSupply[ids[i]] -= amounts[i];
            }
        }
    }

    /// @dev Checks if a value is outside of a limit.
    /// @param _limit The limit to check against.
    /// @param _value The value to check.
    /// @return True if the value is there is a limit and it's outside of that limit.
    function _isOutOfLimits(uint256 _limit, uint256 _value) internal pure returns (bool) {
        return _limit != 0 && !(_value <= _limit);
    }
}

// SPDX-License-Identifier: MIT
// Modified from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.3.0/contracts/utils/cryptography/MerkleProof.sol
// Copied from https://github.com/ensdomains/governance/blob/master/contracts/MerkleProof.sol

pragma solidity ^0.8;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 *
 * Source: https://github.com/ensdomains/governance/blob/master/contracts/MerkleProof.sol
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool, uint256) {
        bytes32 computedHash = leaf;
        uint256 index = 0;

        for (uint256 i = 0; i < proof.length; i++) {
            index *= 2;
            bytes32 proofElement = proof[i];

            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
                index += 1;
            }
        }

        // Check if the computed hash (root) is equal to the provided root
        return (computedHash == root, index);
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8;

//  ==========  External imports    ==========
import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC2981Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/draft-EIP712Upgradeable.sol";
import "operator-filter-registry/src/upgradeable/DefaultOperatorFiltererUpgradeable.sol";

/// ========== Features ==========
import "./openzeppelin-presets/metatx/ERC2771ContextUpgradeable.sol";

import "./types/DropERC1155DataTypes.sol";
import "../terms/types/TermsDataTypes.sol";

import "./errors/IErrors.sol";

import "./AspenERC1155DropLogic.sol";
import "../terms/lib/TermsLogic.sol";
import "../api/issuance/IDropClaimCondition.sol";

abstract contract AspenERC1155DropStorage is
    Initializable,
    ReentrancyGuardUpgradeable,
    ERC2771ContextUpgradeable,
    AccessControlEnumerableUpgradeable,
    ERC1155Upgradeable,
    EIP712Upgradeable,
    DefaultOperatorFiltererUpgradeable
{
    /// ================================
    /// =========== Libraries ==========
    /// ================================
    using StringsUpgradeable for uint256;
    using TermsLogic for TermsDataTypes.Terms;
    using AspenERC1155DropLogic for DropERC1155DataTypes.ClaimData;

    /// =============================
    /// =========== Events ==========
    /// =============================
    /// @dev Emitted when the wallet claim count for a given tokenId and address is updated.
    event WalletClaimCountUpdated(uint256 tokenId, address indexed wallet, uint256 count);
    /// @dev Emitted when the max wallet claim count for a given tokenId is updated.
    event MaxWalletClaimCountUpdated(uint256 tokenId, uint256 count);
    /// @dev Emitted when the sale recipient for a particular tokenId is updated.
    event SaleRecipientForTokenUpdated(uint256 indexed tokenId, address saleRecipient);

    /// ===============================================
    /// =========== State variables - public ==========
    /// ===============================================
    /// @dev If true, users cannot claim.
    bool public claimIsPaused = false;
    // FIXME: TRANSFER_ROLE is duplicated on AspenERC1155DropLogic (since we wish to access it from this contract externally)
    /// @dev Only transfers to or from TRANSFER_ROLE holders are valid, when transfers are restricted.
    bytes32 public constant TRANSFER_ROLE = keccak256("TRANSFER_ROLE");
    /// @dev Only MINTER_ROLE holders can lazy mint NFTs.
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    /// @dev Only ISSUER_ROLE holders can issue NFTs.
    bytes32 public constant ISSUER_ROLE = keccak256("ISSUER_ROLE");
    /// @dev Offset for token IDs.
    uint8 public constant TOKEN_INDEX_OFFSET = 1;
    /// @dev The address that receives all primary sales value.
    address public _primarySaleRecipient;
    /// @dev Token name
    string public  __name;
    /// @dev Token symbol
    string public __symbol;
    /// @dev Owner of the contract (purpose: OpenSea compatibility)
    address public _owner;
    /// @dev Contract level metadata.
    string public _contractUri;
    /// @dev Mapping from 'Largest tokenId of a batch of tokens with the same baseURI'
    ///         to base URI for the respective batch of tokens.
    mapping(uint256 => string) public baseURI;
    /// @dev address of delegate logic contract
    address public delegateLogicContract;
    /// @dev enable/disable operator filterer.
    bool public operatorFiltererEnabled;

    bytes32 public constant MESSAGE_HASH =
        keccak256("AcceptTerms(address acceptor,string termsURI,uint8 termsVersion)");

    struct AcceptTerms {
        address acceptor;
        string termsURI;
        uint8 termsVersion;
    }

    DropERC1155DataTypes.ClaimData claimData;
    TermsDataTypes.Terms termsData;

    modifier isValidTokenId(uint256 _tokenId) {
        if (_tokenId <= 0) revert InvalidTokenId(_tokenId);
        _;
    }

    /// @dev See ERC 165
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155Upgradeable, AccessControlEnumerableUpgradeable)
        returns (bool)
    {
        return
            ERC1155Upgradeable.supportsInterface(interfaceId) ||
            AccessControlEnumerableUpgradeable.supportsInterface(interfaceId);
    }

    /// @dev See {ERC1155-_beforeTokenTransfer}.
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
        AspenERC1155DropLogic.beforeTokenTransfer(claimData, termsData, this, from, to, ids, amounts);
    }

    /// ======================================
    /// =========== Miscellaneous ============
    /// ======================================
    function _msgSender()
        internal
        view
        virtual
        override(ContextUpgradeable, ERC2771ContextUpgradeable)
        returns (address sender)
    {
        return ERC2771ContextUpgradeable._msgSender();
    }

    function _msgData()
        internal
        view
        virtual
        override(ContextUpgradeable, ERC2771ContextUpgradeable)
        returns (bytes calldata)
    {
        return ERC2771ContextUpgradeable._msgData();
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8;

library FeeType {
    uint256 internal constant PRIMARY_SALE = 0;
    uint256 internal constant MARKET_SALE = 1;
    uint256 internal constant SPLIT = 2;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8;

import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "../../api/issuance/IDropClaimCondition.sol";
import "../../api/royalties/IRoyalty.sol";

interface DropERC1155DataTypes {
    struct SequencedURI {
        /// @dev The URI with the token metadata.
        string uri;
        /// @dev The high-watermark sequence number a URI - used to tell if one URI is fresher than a another
        /// taken from the current value of uriSequenceCounter after it is incremented.
        uint256 sequenceNumber;
        /// @dev Indicates if a uri is permanent or not.
        bool isPermanent;
        /// @dev Indicates the number of tokens in this batch.
        uint256 amountOfTokens;
    }
    struct ClaimData {
        /// @dev The set of all claim conditions, at any given moment.
        mapping(uint256 => IDropClaimConditionV1.ClaimConditionList) claimCondition;
        /// @dev Mapping from token ID => claimer wallet address => total number of NFTs of the token ID a wallet has claimed.
        mapping(uint256 => mapping(address => uint256)) walletClaimCount;
        /// @dev The next token ID of the NFT to "lazy mint".
        uint256 nextTokenIdToMint;
        /// @dev Mapping from token ID => maximum possible total circulating supply of tokens with that ID.
        mapping(uint256 => uint256) maxTotalSupply;
        /// @dev Mapping from token ID => the max number of NFTs of the token ID a wallet can claim.
        mapping(uint256 => uint256) maxWalletClaimCount;
        /// @dev The address that receives all platform fees from all sales.
        address platformFeeRecipient;
        /// @dev The % of primary sales collected as platform fees.
        uint16 platformFeeBps;
        /// @dev Mapping from token ID => total circulating supply of tokens with that ID.
        mapping(uint256 => uint256) totalSupply;
        /// @dev Mapping from token ID => the address of the recipient of primary sales.
        mapping(uint256 => address) saleRecipient;
        /// @dev The recipient of who gets the royalty.
        address royaltyRecipient;
        /// @dev The (default) address that receives all royalty value.
        uint16 royaltyBps;
        /// @dev Mapping from token ID => royalty recipient and bps for tokens of the token ID.
        mapping(uint256 => IRoyaltyV0.RoyaltyInfo) royaltyInfoForToken;
        /// @dev Sequence number counter for the synchronisation of per-token URIs and baseURIs relative base on which
        /// was set most recently. Incremented on each URI-mutating action.
        CountersUpgradeable.Counter uriSequenceCounter;
        /// @dev One more than the Largest tokenId of each batch of tokens with the same baseURI
        uint256[] baseURIIndices;
        /// @dev Mapping from the 'base URI index' defined as the tokenId one more than the largest tokenId a batch of
        /// tokens which all same the same baseURI.
        /// Suppose we have two batches (and two baseURIs), with 3 and 4 tokens respectively, then in pictures we have:
        /// [baseURI1 | baseURI2]
        /// [ 0, 1, 2 | 3, 4, 5, 6]
        /// The baseURIIndices would be:
        /// [ 3, 7]
        mapping(uint256 => SequencedURI) baseURI;
        // Optional mapping for token URIs
        mapping(uint256 => SequencedURI) tokenURIs;
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8;

import "../errors/ITermsErrors.sol";
import "../types/TermsDataTypes.sol";

library TermsLogic {
    using TermsLogic for TermsDataTypes.Terms;

    event TermsActivationStatusUpdated(bool isActivated);
    event TermsUpdated(string termsURI, uint8 termsVersion);
    event TermsAccepted(string termsURI, uint8 termsVersion, address indexed acceptor);

    /// @notice activates / deactivates the terms of use.
    function setTermsActivation(TermsDataTypes.Terms storage termsData, bool _active) external {
        if (_active) {
            _activateTerms(termsData);
        } else {
            _deactivateTerms(termsData);
        }
    }

    /// @notice updates the term URI and pumps the terms version
    function setTermsURI(TermsDataTypes.Terms storage termsData, string calldata _termsURI) external {
        if (keccak256(abi.encodePacked(termsData.termsURI)) == keccak256(abi.encodePacked(_termsURI)))
            revert TermsUriAlreadySet();
        if (bytes(_termsURI).length > 0) {
            termsData.termsVersion = termsData.termsVersion + 1;
            termsData.termsActivated = true;
        } else {
            termsData.termsActivated = false;
        }
        termsData.termsURI = _termsURI;
    }

    /// @notice by signing this transaction, you are confirming that you have read and agreed to the terms of use at `termsURI`
    function acceptTerms(TermsDataTypes.Terms storage termsData, address _acceptor) external {
        if (!termsData.termsActivated) revert TermsNotActivated();
        if (termsData.termsAccepted[_acceptor] && termsData.acceptedVersion[_acceptor] == termsData.termsVersion)
            revert TermsAlreadyAccepted(termsData.termsVersion);
        termsData.termsAccepted[_acceptor] = true;
        termsData.acceptedVersion[_acceptor] = termsData.termsVersion;
    }

    /// @notice returns the details of the terms
    /// @return termsURI - the URI of the terms
    /// @return termsVersion - the version of the terms
    /// @return termsActivated - the status of the terms
    function getTermsDetails(TermsDataTypes.Terms storage termsData)
        external
        view
        returns (
            string memory termsURI,
            uint8 termsVersion,
            bool termsActivated
        )
    {
        return (termsData.termsURI, termsData.termsVersion, termsData.termsActivated);
    }

    /// @notice returns true / false for whether the account owner accepted terms
    function hasAcceptedTerms(TermsDataTypes.Terms storage termsData, address _address) external view returns (bool) {
        return termsData.termsAccepted[_address] && termsData.acceptedVersion[_address] == termsData.termsVersion;
    }

    /// @notice returns true / false for whether the account owner accepted terms
    function hasAcceptedTerms(
        TermsDataTypes.Terms storage termsData,
        address _address,
        uint8 _version
    ) external view returns (bool) {
        return termsData.termsAccepted[_address] && termsData.acceptedVersion[_address] == _version;
    }

    /// @notice activates the terms
    function _activateTerms(TermsDataTypes.Terms storage termsData) internal {
        if (bytes(termsData.termsURI).length == 0) revert TermsURINotSet();
        if (termsData.termsActivated) revert TermsStatusAlreadySet();
        termsData.termsActivated = true;
    }

    /// @notice deactivates the terms
    function _deactivateTerms(TermsDataTypes.Terms storage termsData) internal {
        if (!termsData.termsActivated) revert TermsStatusAlreadySet();
        termsData.termsActivated = false;
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8;

interface TermsDataTypes {
    /**
     *  @notice The criteria that make up terms.
     *
     *  @param termsActivated       Indicates whether the terms are activated or not.
     *
     *  @param termsVersion         The version of the terms.
     *
     *  @param termsURI             The URI of the terms.
     *
     *  @param acceptedVersion      Mapping with the address of the acceptor and the version of the terms accepted.
     *
     *  @param termsAccepted        Mapping with the address of the acceptor and the status of the terms accepted.
     *
     */
    struct Terms {
        bool termsActivated;
        uint8 termsVersion;
        string termsURI;
        mapping(address => uint8) acceptedVersion;
        mapping(address => bool) termsAccepted;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (metatx/ERC2771Context.sol)

pragma solidity ^0.8;

import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @dev Context variant with ERC2771 support.
 */
abstract contract ERC2771ContextUpgradeable is Initializable, ContextUpgradeable {
    mapping(address => bool) private _trustedForwarder;

    function __ERC2771Context_init(address[] memory trustedForwarder) internal onlyInitializing {
        __Context_init_unchained();
        __ERC2771Context_init_unchained(trustedForwarder);
    }

    function __ERC2771Context_init_unchained(address[] memory trustedForwarder) internal onlyInitializing {
        for (uint256 i = 0; i < trustedForwarder.length; i++) {
            _trustedForwarder[trustedForwarder[i]] = true;
        }
    }

    function isTrustedForwarder(address forwarder) public view virtual returns (bool) {
        return _trustedForwarder[forwarder];
    }

    function _msgSender() internal view virtual override returns (address sender) {
        if (isTrustedForwarder(msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return super._msgSender();
        }
    }

    function _msgData() internal view virtual override returns (bytes calldata) {
        if (isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length - 20];
        } else {
            return super._msgData();
        }
    }

    uint256[49] private __gap;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8;

error InvalidPermission();
error InvalidIndex();
error NothingToReveal();
error Bot();
error ST();
error CrossedLimitLazyMintedTokens();
error CrossedLimitMinTokenIdGreaterThanMaxTotalSupply();
error CrossedLimitQuantityPerTransaction();
error CrossedLimitMaxClaimableSupply();
error CrossedLimitMaxTotalSupply();
error CrossedLimitMaxWalletClaimCount();
error InvalidPrice();
error InvalidPaymentAmount();
error InvalidQuantity();
error InvalidTime();
error InvalidGating();
error InvalidMerkleProof();
error InvalidMaxQuantityProof();
error MaxBps();
error ClaimPaused();
error NoActiveMintCondition();
error TermsNotAccepted(address caller, string termsURI, uint8 acceptedVersion);
error BaseURIEmpty();
error FrozenTokenMetadata(uint256 tokenId);
error InvalidTokenId(uint256 tokenId);
error InvalidNoOfTokenIds();
error InvalidPhaseId(bytes32 phaseId);

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8;

import "@openzeppelin/contracts-upgradeable/utils/structs/BitMapsUpgradeable.sol";

/**
 *  Cedar's 'Drop' contracts are distribution mechanisms for tokens.
 *
 *  A contract admin (i.e. a holder of `DEFAULT_ADMIN_ROLE`) can set a series of claim conditions,
 *  ordered by their respective `startTimestamp`. A claim condition defines criteria under which
 *  accounts can mint tokens. Claim conditions can be overwritten or added to by the contract admin.
 *  At any moment, there is only one active claim condition.
 */

interface IDropClaimConditionV0 {
    /**
     *  @notice The criteria that make up a claim condition.
     *
     *  @param startTimestamp                 The unix timestamp after which the claim condition applies.
     *                                        The same claim condition applies until the `startTimestamp`
     *                                        of the next claim condition.
     *
     *  @param maxClaimableSupply             The maximum total number of tokens that can be claimed under
     *                                        the claim condition.
     *
     *  @param supplyClaimed                  At any given point, the number of tokens that have been claimed
     *                                        under the claim condition.
     *
     *  @param quantityLimitPerTransaction    The maximum number of tokens that can be claimed in a single
     *                                        transaction.
     *
     *  @param waitTimeInSecondsBetweenClaims The least number of seconds an account must wait after claiming
     *                                        tokens, to be able to claim tokens again.
     *
     *  @param merkleRoot                     The allowlist of addresses that can claim tokens under the claim
     *                                        condition.
     *
     *  @param pricePerToken                  The price required to pay per token claimed.
     *
     *  @param currency                       The currency in which the `pricePerToken` must be paid.
     */
    struct ClaimCondition {
        uint256 startTimestamp;
        uint256 maxClaimableSupply;
        uint256 supplyClaimed;
        uint256 quantityLimitPerTransaction;
        uint256 waitTimeInSecondsBetweenClaims;
        bytes32 merkleRoot;
        uint256 pricePerToken;
        address currency;
    }

    /**
     *  @notice The set of all claim conditions, at any given moment.
     *  Claim Phase ID = [currentStartId, currentStartId + length - 1];
     *
     *  @param currentStartId           The uid for the first claim condition amongst the current set of
     *                                  claim conditions. The uid for each next claim condition is one
     *                                  more than the previous claim condition's uid.
     *
     *  @param count                    The total number of phases / claim conditions in the list
     *                                  of claim conditions.
     *
     *  @param phases                   The claim conditions at a given uid. Claim conditions
     *                                  are ordered in an ascending order by their `startTimestamp`.
     *
     *  @param claimDetails             Map from an account and uid for a claim condition, to the claim
     *                                  records an account has done.
     *
     */
    struct ClaimConditionList {
        uint256 currentStartId;
        uint256 count;
        mapping(uint256 => ClaimCondition) phases;
        mapping(uint256 => mapping(address => ClaimDetails)) userClaims;
    }

    /**
     *  @notice Claim detail for a user claim.
     *
     *  @param lastClaimTimestamp    The timestamp at which the last token was claimed.
     *
     *  @param claimedBalance        The number of tokens claimed.
     *
     */
    struct ClaimDetails {
        uint256 lastClaimTimestamp;
        uint256 claimedBalance;
    }
}

interface IDropClaimConditionV1 {
    /**
     *  @notice The criteria that make up a claim condition.
     *
     *  @param startTimestamp                 The unix timestamp after which the claim condition applies.
     *                                        The same claim condition applies until the `startTimestamp`
     *                                        of the next claim condition.
     *
     *  @param maxClaimableSupply             The maximum total number of tokens that can be claimed under
     *                                        the claim condition.
     *
     *  @param supplyClaimed                  At any given point, the number of tokens that have been claimed
     *                                        under the claim condition.
     *
     *  @param quantityLimitPerTransaction    The maximum number of tokens that can be claimed in a single
     *                                        transaction.
     *
     *  @param waitTimeInSecondsBetweenClaims The least number of seconds an account must wait after claiming
     *                                        tokens, to be able to claim tokens again.
     *
     *  @param merkleRoot                     The allowlist of addresses that can claim tokens under the claim
     *                                        condition.
     *
     *  @param pricePerToken                  The price required to pay per token claimed.
     *
     *  @param currency                       The currency in which the `pricePerToken` must be paid.
     */
    struct ClaimCondition {
        uint256 startTimestamp;
        uint256 maxClaimableSupply;
        uint256 supplyClaimed;
        uint256 quantityLimitPerTransaction;
        uint256 waitTimeInSecondsBetweenClaims;
        bytes32 merkleRoot;
        uint256 pricePerToken;
        address currency;
        bytes32 phaseId;
    }

    /**
     *  @notice The set of all claim conditions, at any given moment.
     *  Claim Phase ID = [currentStartId, currentStartId + length - 1];
     *
     *  @param currentStartId           The uid for the first claim condition amongst the current set of
     *                                  claim conditions. The uid for each next claim condition is one
     *                                  more than the previous claim condition's uid.
     *
     *  @param count                    The total number of phases / claim conditions in the list
     *                                  of claim conditions.
     *
     *  @param phases                   The claim conditions at a given uid. Claim conditions
     *                                  are ordered in an ascending order by their `startTimestamp`.
     *
     *  @param claimDetails             Map from an account and uid for a claim condition, to the claim
     *                                  records an account has done.
     *
     */
    struct ClaimConditionList {
        uint256 currentStartId;
        uint256 count;
        mapping(uint256 => ClaimCondition) phases;
        mapping(uint256 => mapping(address => ClaimDetails)) userClaims;
    }

    /**
     *  @notice Claim detail for a user claim.
     *
     *  @param lastClaimTimestamp    The timestamp at which the last token was claimed.
     *
     *  @param claimedBalance        The number of tokens claimed.
     *
     */
    struct ClaimDetails {
        uint256 lastClaimTimestamp;
        uint256 claimedBalance;
    }
}

// SPDX-License-Identifier: Apache-2.0

// Generated by impl.ts. Will be overwritten.
// Filename: './BaseAspenERC1155DropV1.sol'

pragma solidity ^0.8.4;

import "../../api/impl/IAspenERC1155Drop.sol";
import "../../api/IAspenFeatures.sol";
import "../../api/IAspenVersioned.sol";
import "../../api/IMulticallable.sol";
import "../../api/issuance/ICedarSFTIssuance.sol";
import "../../api/issuance/ISFTSupply.sol";
import "../../api/standard/IERC1155.sol";
import "../../api/standard/IERC2981.sol";
import "../../api/standard/IERC4906.sol";
import "../../api/royalties/IRoyalty.sol";
import "../../api/baseURI/IUpdateBaseURI.sol";
import "../../api/metadata/IContractMetadata.sol";
import "../../api/ownable/IOwnable.sol";
import "../../api/metadata/ISFTMetadata.sol";
import "../../api/agreement/IAgreement.sol";
import "../../api/primarysale/IPrimarySale.sol";
import "../../api/royalties/IPlatformFee.sol";
import "../../api/agreement/IAgreement.sol";
import "../../api/agreement/IAgreement.sol";
import "../../api/issuance/ICedarSFTIssuance.sol";
import "../../api/lazymint/ILazyMint.sol";
import "../../api/pausable/IPausable.sol";
import "../../api/metadata/IContractMetadata.sol";
import "../../api/baseURI/IUpdateBaseURI.sol";
import "../../api/royalties/IRoyalty.sol";
import "../../api/primarysale/IPrimarySale.sol";
import "../../api/issuance/ISFTLimitSupply.sol";
import "../../api/ownable/IOwnable.sol";
import "../../api/royalties/IPlatformFee.sol";

/// Delegate features
interface IDelegateBaseAspenERC1155DropV1 is IRestrictedERC4906V0, IRestrictedAgreementV1, IDelegatedAgreementV0, IRestrictedSFTIssuanceV3, IRestrictedLazyMintV1, IRestrictedPausableV1, IRestrictedMetadataV2, IRestrictedUpdateBaseURIV1, IRestrictedRoyaltyV2, IRestrictedPrimarySaleV2, IRestrictedSFTLimitSupplyV1, IRestrictedOwnableV0, IRestrictedPlatformFeeV0 {}

/// Inherit from this base to implement introspection
abstract contract BaseAspenERC1155DropV1 is IAspenFeaturesV0, IAspenVersionedV2, IMulticallableV0, IPublicSFTIssuanceV2, ISFTSupplyV1, IERC1155V2, IERC2981V0, IPublicRoyaltyV0, IPublicUpdateBaseURIV0, IPublicMetadataV0, IPublicOwnableV0, IAspenSFTMetadataV1, IPublicAgreementV1, IPublicPrimarySaleV1, IPublicPlatformFeeV0 {
    function supportedFeatures() override public pure returns (string[] memory features) {
        features = new string[](25);
        features[0] = "IAspenFeatures.sol:IAspenFeaturesV0";
        features[1] = "IAspenVersioned.sol:IAspenVersionedV2";
        features[2] = "IMulticallable.sol:IMulticallableV0";
        features[3] = "issuance/ICedarSFTIssuance.sol:IPublicSFTIssuanceV2";
        features[4] = "issuance/ISFTSupply.sol:ISFTSupplyV1";
        features[5] = "royalties/IRoyalty.sol:IPublicRoyaltyV0";
        features[6] = "baseURI/IUpdateBaseURI.sol:IPublicUpdateBaseURIV0";
        features[7] = "metadata/IContractMetadata.sol:IPublicMetadataV0";
        features[8] = "ownable/IOwnable.sol:IPublicOwnableV0";
        features[9] = "metadata/ISFTMetadata.sol:IAspenSFTMetadataV1";
        features[10] = "agreement/IAgreement.sol:IPublicAgreementV1";
        features[11] = "primarysale/IPrimarySale.sol:IPublicPrimarySaleV1";
        features[12] = "royalties/IPlatformFee.sol:IPublicPlatformFeeV0";
        features[13] = "agreement/IAgreement.sol:IRestrictedAgreementV1";
        features[14] = "agreement/IAgreement.sol:IDelegatedAgreementV0";
        features[15] = "issuance/ICedarSFTIssuance.sol:IRestrictedSFTIssuanceV3";
        features[16] = "lazymint/ILazyMint.sol:IRestrictedLazyMintV1";
        features[17] = "pausable/IPausable.sol:IRestrictedPausableV1";
        features[18] = "metadata/IContractMetadata.sol:IRestrictedMetadataV2";
        features[19] = "baseURI/IUpdateBaseURI.sol:IRestrictedUpdateBaseURIV1";
        features[20] = "royalties/IRoyalty.sol:IRestrictedRoyaltyV2";
        features[21] = "primarysale/IPrimarySale.sol:IRestrictedPrimarySaleV2";
        features[22] = "issuance/ISFTLimitSupply.sol:IRestrictedSFTLimitSupplyV1";
        features[23] = "ownable/IOwnable.sol:IRestrictedOwnableV0";
        features[24] = "royalties/IPlatformFee.sol:IRestrictedPlatformFeeV0";
    }

    /// This needs to be public to be callable from initialize via delegatecall
    function minorVersion() virtual override public pure returns (uint256 minor, uint256 patch);

    function implementationVersion() override public pure returns (uint256 major, uint256 minor, uint256 patch) {
        (minor, patch) = minorVersion();
        major = 1;
    }

    function implementationInterfaceId() virtual override public pure returns (string memory interfaceId) {
        interfaceId = "impl/IAspenERC1155Drop.sol:IAspenERC1155DropV1";
    }

    function supportsInterface(bytes4 interfaceID) virtual override public view returns (bool) {
        return (interfaceID == type(IERC165Upgradeable).interfaceId) || ((interfaceID == type(IAspenFeaturesV0).interfaceId) || ((interfaceID == type(IAspenVersionedV2).interfaceId) || ((interfaceID == type(IMulticallableV0).interfaceId) || ((interfaceID == type(IPublicSFTIssuanceV2).interfaceId) || ((interfaceID == type(ISFTSupplyV1).interfaceId) || ((interfaceID == type(IERC1155V2).interfaceId) || ((interfaceID == type(IERC2981V0).interfaceId) || ((interfaceID == type(IRestrictedERC4906V0).interfaceId) || ((interfaceID == type(IPublicRoyaltyV0).interfaceId) || ((interfaceID == type(IPublicUpdateBaseURIV0).interfaceId) || ((interfaceID == type(IPublicMetadataV0).interfaceId) || ((interfaceID == type(IPublicOwnableV0).interfaceId) || ((interfaceID == type(IAspenSFTMetadataV1).interfaceId) || ((interfaceID == type(IPublicAgreementV1).interfaceId) || ((interfaceID == type(IPublicPrimarySaleV1).interfaceId) || ((interfaceID == type(IPublicPlatformFeeV0).interfaceId) || ((interfaceID == type(IRestrictedAgreementV1).interfaceId) || ((interfaceID == type(IDelegatedAgreementV0).interfaceId) || ((interfaceID == type(IRestrictedSFTIssuanceV3).interfaceId) || ((interfaceID == type(IRestrictedLazyMintV1).interfaceId) || ((interfaceID == type(IRestrictedPausableV1).interfaceId) || ((interfaceID == type(IRestrictedMetadataV2).interfaceId) || ((interfaceID == type(IRestrictedUpdateBaseURIV1).interfaceId) || ((interfaceID == type(IRestrictedRoyaltyV2).interfaceId) || ((interfaceID == type(IRestrictedPrimarySaleV2).interfaceId) || ((interfaceID == type(IRestrictedSFTLimitSupplyV1).interfaceId) || ((interfaceID == type(IRestrictedOwnableV0).interfaceId) || ((interfaceID == type(IRestrictedPlatformFeeV0).interfaceId) || (interfaceID == type(IAspenERC1155DropV1).interfaceId)))))))))))))))))))))))))))));
    }

    function isIAspenFeaturesV0() override public pure returns (bool) {
        return true;
    }
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

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8;

// Helper interfaces
import {IWETH} from "../interfaces/IWETH.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

library CurrencyTransferLib {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /// @dev The address interpreted as native token of the chain.
    address public constant NATIVE_TOKEN = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    /// @dev Transfers a given amount of currency.
    function transferCurrency(
        address _currency,
        address _from,
        address _to,
        uint256 _amount
    ) internal {
        if (_amount == 0) {
            return;
        }

        if (_currency == NATIVE_TOKEN) {
            safeTransferNativeToken(_to, _amount);
        } else {
            safeTransferERC20(_currency, _from, _to, _amount);
        }
    }

    /// @dev Transfers a given amount of currency. (With native token wrapping)
    function transferCurrencyWithWrapper(
        address _currency,
        address _from,
        address _to,
        uint256 _amount,
        address _nativeTokenWrapper
    ) internal {
        if (_amount == 0) {
            return;
        }

        if (_currency == NATIVE_TOKEN) {
            if (_from == address(this)) {
                // withdraw from weth then transfer withdrawn native token to recipient
                IWETH(_nativeTokenWrapper).withdraw(_amount);
                safeTransferNativeTokenWithWrapper(_to, _amount, _nativeTokenWrapper);
            } else if (_to == address(this)) {
                // store native currency in weth
                require(_amount == msg.value, "msg.value != amount");
                IWETH(_nativeTokenWrapper).deposit{value: _amount}();
            } else {
                safeTransferNativeTokenWithWrapper(_to, _amount, _nativeTokenWrapper);
            }
        } else {
            safeTransferERC20(_currency, _from, _to, _amount);
        }
    }

    /// @dev Transfer `amount` of ERC20 token from `from` to `to`.
    function safeTransferERC20(
        address _currency,
        address _from,
        address _to,
        uint256 _amount
    ) internal {
        if (_from == _to) {
            return;
        }

        if (_from == address(this)) {
            IERC20Upgradeable(_currency).safeTransfer(_to, _amount);
        } else {
            IERC20Upgradeable(_currency).safeTransferFrom(_from, _to, _amount);
        }
    }

    /// @dev Transfers `amount` of native token to `to`.
    function safeTransferNativeToken(address to, uint256 value) internal {
        // solhint-disable avoid-low-level-calls
        // slither-disable-next-line low-level-calls
        (bool success, ) = to.call{value: value}("");
        require(success, "native token transfer failed");
    }

    /// @dev Transfers `amount` of native token to `to`. (With native token wrapping)
    function safeTransferNativeTokenWithWrapper(
        address to,
        uint256 value,
        address _nativeTokenWrapper
    ) internal {
        // solhint-disable avoid-low-level-calls
        // slither-disable-next-line low-level-calls
        (bool success, ) = to.call{value: value}("");
        if (!success) {
            IWETH(_nativeTokenWrapper).deposit{value: value}();
            IERC20Upgradeable(_nativeTokenWrapper).safeTransfer(to, value);
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8;

import "../standard/IERC2981.sol";

interface IRoyaltyV0 is IERC2981V0 {
    struct RoyaltyInfo {
        address recipient;
        uint256 bps;
    }

    /// @dev Returns the royalty recipient and fee bps.
    function getDefaultRoyaltyInfo() external view returns (address, uint16);

    /// @dev Lets a module admin update the royalty bps and recipient.
    function setDefaultRoyaltyInfo(address _royaltyRecipient, uint256 _royaltyBps) external;

    /// @dev Lets a module admin set the royalty recipient for a particular token Id.
    function setRoyaltyInfoForToken(
        uint256 tokenId,
        address recipient,
        uint256 bps
    ) external;

    /// @dev Returns the royalty recipient for a particular token Id.
    function getRoyaltyInfoForToken(uint256 tokenId) external view returns (address, uint16);

    /// @dev Emitted when royalty info is updated.
    event DefaultRoyalty(address newRoyaltyRecipient, uint256 newRoyaltyBps);

    /// @dev Emitted when royalty recipient for tokenId is set
    event RoyaltyForToken(uint256 indexed tokenId, address royaltyRecipient, uint256 royaltyBps);
}

interface IPublicRoyaltyV0 is IERC2981V0 {
    struct RoyaltyInfo {
        address recipient;
        uint256 bps;
    }

    /// @dev Returns the royalty recipient and fee bps.
    function getDefaultRoyaltyInfo() external view returns (address, uint16);

    /// @dev Returns the royalty recipient for a particular token Id.
    function getRoyaltyInfoForToken(uint256 tokenId) external view returns (address, uint16);
}

interface IRestrictedRoyaltyV0 {
    /// @dev Lets a module admin update the royalty bps and recipient.
    function setDefaultRoyaltyInfo(address _royaltyRecipient, uint256 _royaltyBps) external;

    /// @dev Lets a module admin set the royalty recipient for a particular token Id.
    function setRoyaltyInfoForToken(
        uint256 tokenId,
        address recipient,
        uint256 bps
    ) external;
}

interface IRestrictedRoyaltyV1 is IRestrictedRoyaltyV0 {
    /// @dev Emitted when royalty info is updated.
    event DefaultRoyalty(address newRoyaltyRecipient, uint256 newRoyaltyBps);
    /// @dev Emitted when royalty recipient for tokenId is set
    event RoyaltyForToken(uint256 indexed tokenId, address royaltyRecipient, uint256 royaltyBps);
}

interface IRestrictedRoyaltyV2 is IRestrictedRoyaltyV1 {
    /// @dev Emitted when the operator filter is updated.
    event OperatorFilterStatusUpdated(bool enabled);

    /// @dev allows an admin to enable / disable the operator filterer.
    function setOperatorFiltererStatus(bool _enabled) external;
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
library CountersUpgradeable {
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
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
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

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8;

interface IWETH {
    function deposit() external payable;

    function withdraw(uint256 amount) external;

    function transfer(address to, uint256 value) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
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
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8;

interface IERC2981V0 {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be payed in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/structs/BitMaps.sol)
pragma solidity ^0.8.0;

/**
 * @dev Library for managing uint256 to bool mapping in a compact and efficient way, providing the keys are sequential.
 * Largelly inspired by Uniswap's https://github.com/Uniswap/merkle-distributor/blob/master/contracts/MerkleDistributor.sol[merkle-distributor].
 */
library BitMapsUpgradeable {
    struct BitMap {
        mapping(uint256 => uint256) _data;
    }

    /**
     * @dev Returns whether the bit at `index` is set.
     */
    function get(BitMap storage bitmap, uint256 index) internal view returns (bool) {
        uint256 bucket = index >> 8;
        uint256 mask = 1 << (index & 0xff);
        return bitmap._data[bucket] & mask != 0;
    }

    /**
     * @dev Sets the bit at `index` to the boolean `value`.
     */
    function setTo(
        BitMap storage bitmap,
        uint256 index,
        bool value
    ) internal {
        if (value) {
            set(bitmap, index);
        } else {
            unset(bitmap, index);
        }
    }

    /**
     * @dev Sets the bit at `index`.
     */
    function set(BitMap storage bitmap, uint256 index) internal {
        uint256 bucket = index >> 8;
        uint256 mask = 1 << (index & 0xff);
        bitmap._data[bucket] |= mask;
    }

    /**
     * @dev Unsets the bit at `index`.
     */
    function unset(BitMap storage bitmap, uint256 index) internal {
        uint256 bucket = index >> 8;
        uint256 mask = 1 << (index & 0xff);
        bitmap._data[bucket] &= ~mask;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981Upgradeable is IERC165Upgradeable {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be payed in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControlEnumerableUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "../utils/structs/EnumerableSetUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Extension of {AccessControl} that allows enumerating the members of each role.
 */
abstract contract AccessControlEnumerableUpgradeable is Initializable, IAccessControlEnumerableUpgradeable, AccessControlUpgradeable {
    function __AccessControlEnumerable_init() internal onlyInitializing {
    }

    function __AccessControlEnumerable_init_unchained() internal onlyInitializing {
    }
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    mapping(bytes32 => EnumerableSetUpgradeable.AddressSet) private _roleMembers;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlEnumerableUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view virtual override returns (address) {
        return _roleMembers[role].at(index);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view virtual override returns (uint256) {
        return _roleMembers[role].length();
    }

    /**
     * @dev Overload {_grantRole} to track enumerable memberships
     */
    function _grantRole(bytes32 role, address account) internal virtual override {
        super._grantRole(role, account);
        _roleMembers[role].add(account);
    }

    /**
     * @dev Overload {_revokeRole} to track enumerable memberships
     */
    function _revokeRole(bytes32 role, address account) internal virtual override {
        super._revokeRole(role, account);
        _roleMembers[role].remove(account);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {OperatorFiltererUpgradeable} from "./OperatorFiltererUpgradeable.sol";

abstract contract DefaultOperatorFiltererUpgradeable is OperatorFiltererUpgradeable {
    address constant DEFAULT_SUBSCRIPTION = address(0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6);

    function __DefaultOperatorFilterer_init() internal onlyInitializing {
        OperatorFiltererUpgradeable.__OperatorFilterer_init(DEFAULT_SUBSCRIPTION, true);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/ERC1155.sol)

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
    function __ERC1155_init(string memory uri_) internal onlyInitializing {
        __ERC1155_init_unchained(uri_);
    }

    function __ERC1155_init_unchained(string memory uri_) internal onlyInitializing {
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
        _setApprovalForAll(_msgSender(), operator, approved);
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
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, _asSingletonArray(id), _asSingletonArray(amount), data);

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
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
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), _asSingletonArray(id), _asSingletonArray(amount), "");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
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
                if (response != IERC1155ReceiverUpgradeable.onERC1155Received.selector) {
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
                if (response != IERC1155ReceiverUpgradeable.onERC1155BatchReceived.selector) {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[47] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/draft-EIP712.sol)

pragma solidity ^0.8.0;

import "./ECDSAUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 */
abstract contract EIP712Upgradeable is Initializable {
    /* solhint-disable var-name-mixedcase */
    bytes32 private _HASHED_NAME;
    bytes32 private _HASHED_VERSION;
    bytes32 private constant _TYPE_HASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    function __EIP712_init(string memory name, string memory version) internal onlyInitializing {
        __EIP712_init_unchained(name, version);
    }

    function __EIP712_init_unchained(string memory name, string memory version) internal onlyInitializing {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        return _buildDomainSeparator(_TYPE_HASH, _EIP712NameHash(), _EIP712VersionHash());
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSAUpgradeable.toTypedDataHash(_domainSeparatorV4(), structHash);
    }

    /**
     * @dev The hash of the name parameter for the EIP712 domain.
     *
     * NOTE: This function reads from storage by default, but can be redefined to return a constant value if gas costs
     * are a concern.
     */
    function _EIP712NameHash() internal virtual view returns (bytes32) {
        return _HASHED_NAME;
    }

    /**
     * @dev The hash of the version parameter for the EIP712 domain.
     *
     * NOTE: This function reads from storage by default, but can be redefined to return a constant value if gas costs
     * are a concern.
     */
    function _EIP712VersionHash() internal virtual view returns (bytes32) {
        return _HASHED_VERSION;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../StringsUpgradeable.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSAUpgradeable {
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
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
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
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", StringsUpgradeable.toString(s.length), s));
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

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8;

error TermsNotActivated();
error TermsStatusAlreadySet();
error TermsURINotSet();
error TermsUriAlreadySet();
error TermsAlreadyAccepted(uint8 acceptedVersion);
error SignatureVerificationFailed();
error TermsCanOnlyBeSetByOwner(address token);
error TermsNotActivatedForToken(address token);
error TermsStatusAlreadySetForToken(address token);
error TermsURINotSetForToken(address token);
error TermsUriAlreadySetForToken(address token);
error TermsAlreadyAcceptedForToken(address token, uint8 acceptedVersion);

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
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
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

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

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165Upgradeable.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerableUpgradeable is IAccessControlUpgradeable {
    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal onlyInitializing {
    }

    function __AccessControl_init_unchained() internal onlyInitializing {
    }
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
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
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
                        StringsUpgradeable.toHexString(uint160(account), 20),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
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
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSetUpgradeable {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

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
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {IOperatorFilterRegistry} from "../IOperatorFilterRegistry.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

abstract contract OperatorFiltererUpgradeable is Initializable {
    error OperatorNotAllowed(address operator);

    IOperatorFilterRegistry constant operatorFilterRegistry =
        IOperatorFilterRegistry(0x000000000000AAeB6D7670E522A718067333cd4E);

    function __OperatorFilterer_init(address subscriptionOrRegistrantToCopy, bool subscribe)
        internal
        onlyInitializing
    {
        // If an inheriting token contract is deployed to a network without the registry deployed, the modifier
        // will not revert, but the contract will need to be registered with the registry once it is deployed in
        // order for the modifier to filter addresses.
        if (address(operatorFilterRegistry).code.length > 0) {
            if (!operatorFilterRegistry.isRegistered(address(this))) {
                if (subscribe) {
                    operatorFilterRegistry.registerAndSubscribe(address(this), subscriptionOrRegistrantToCopy);
                } else {
                    if (subscriptionOrRegistrantToCopy != address(0)) {
                        operatorFilterRegistry.registerAndCopyEntries(address(this), subscriptionOrRegistrantToCopy);
                    } else {
                        operatorFilterRegistry.register(address(this));
                    }
                }
            }
        }
    }

    modifier onlyAllowedOperator(address from) virtual {
        // Check registry code length to facilitate testing in environments without a deployed registry.
        if (address(operatorFilterRegistry).code.length > 0) {
            // Allow spending tokens from addresses with balance
            // Note that this still allows listings and marketplaces with escrow to transfer tokens if transferred
            // from an EOA.
            if (from == msg.sender) {
                _;
                return;
            }
            if (!operatorFilterRegistry.isOperatorAllowed(address(this), msg.sender)) {
                revert OperatorNotAllowed(msg.sender);
            }
        }
        _;
    }

    modifier onlyAllowedOperatorApproval(address operator) virtual {
        // Check registry code length to facilitate testing in environments without a deployed registry.
        if (address(operatorFilterRegistry).code.length > 0) {
            if (!operatorFilterRegistry.isOperatorAllowed(address(this), operator)) {
                revert OperatorNotAllowed(operator);
            }
        }
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IOperatorFilterRegistry {
    function isOperatorAllowed(address registrant, address operator) external view returns (bool);
    function register(address registrant) external;
    function registerAndSubscribe(address registrant, address subscription) external;
    function registerAndCopyEntries(address registrant, address registrantToCopy) external;
    function unregister(address addr) external;
    function updateOperator(address registrant, address operator, bool filtered) external;
    function updateOperators(address registrant, address[] calldata operators, bool filtered) external;
    function updateCodeHash(address registrant, bytes32 codehash, bool filtered) external;
    function updateCodeHashes(address registrant, bytes32[] calldata codeHashes, bool filtered) external;
    function subscribe(address registrant, address registrantToSubscribe) external;
    function unsubscribe(address registrant, bool copyExistingEntries) external;
    function subscriptionOf(address addr) external returns (address registrant);
    function subscribers(address registrant) external returns (address[] memory);
    function subscriberAt(address registrant, uint256 index) external returns (address);
    function copyEntriesOf(address registrant, address registrantToCopy) external;
    function isOperatorFiltered(address registrant, address operator) external returns (bool);
    function isCodeHashOfFiltered(address registrant, address operatorWithCode) external returns (bool);
    function isCodeHashFiltered(address registrant, bytes32 codeHash) external returns (bool);
    function filteredOperators(address addr) external returns (address[] memory);
    function filteredCodeHashes(address addr) external returns (bytes32[] memory);
    function filteredOperatorAt(address registrant, uint256 index) external returns (address);
    function filteredCodeHashAt(address registrant, uint256 index) external returns (bytes32);
    function isRegistered(address addr) external returns (bool);
    function codeHashOf(address addr) external returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155ReceiverUpgradeable is IERC165Upgradeable {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

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

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8;

import "@openzeppelin/contracts-upgradeable/utils/introspection/IERC165Upgradeable.sol";

interface ICedarMinorVersionedV0 {
    function minorVersion() external view returns (uint256 minor, uint256 patch);
}

interface ICedarImplementationVersionedV0 {
    /// @dev Concrete implementation semantic version - provided for completeness but not designed to be the point of dispatch
    function implementationVersion()
        external
        view
        returns (
            uint256 major,
            uint256 minor,
            uint256 patch
        );
}

interface ICedarImplementationVersionedV1 is ICedarImplementationVersionedV0 {
    /// @dev returns the name of the implementation interface such as IAspenERC721DropV3
    /// allows us to reliably emit the correct events
    function implementationInterfaceName() external view returns (string memory interfaceName);
}

interface ICedarImplementationVersionedV2 is ICedarImplementationVersionedV0 {
    /// @dev returns the name of the implementation interface such as impl/IAspenERC721Drop.sol:IAspenERC721DropV3
    function implementationInterfaceId() external view returns (string memory interfaceId);
}

interface ICedarVersionedV0 is ICedarImplementationVersionedV0, ICedarMinorVersionedV0, IERC165Upgradeable {}

interface ICedarVersionedV1 is ICedarImplementationVersionedV1, ICedarMinorVersionedV0, IERC165Upgradeable {}

interface ICedarVersionedV2 is ICedarImplementationVersionedV2, ICedarMinorVersionedV0, IERC165Upgradeable {}

interface IAspenVersionedV2 is IERC165Upgradeable {
    function minorVersion() external view returns (uint256 minor, uint256 patch);

    /// @dev Concrete implementation semantic version - provided for completeness but not designed to be the point of dispatch
    function implementationVersion()
        external
        view
        returns (
            uint256 major,
            uint256 minor,
            uint256 patch
        );

    /// @dev returns the name of the implementation interface such as impl/IAspenERC721Drop.sol:IAspenERC721DropV3
    function implementationInterfaceId() external view returns (string memory interfaceId);
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8;

import "@openzeppelin/contracts-upgradeable/utils/introspection/IERC165Upgradeable.sol";

interface ICedarFeaturesV0 is IERC165Upgradeable {
    // Marker interface to make an ERC165 clash less likely
    function isICedarFeaturesV0() external pure returns (bool);

    // List of features that contract supports and may be passed to featureVersion
    function supportedFeatures() external pure returns (string[] memory features);
}

interface IAspenFeaturesV0 is IERC165Upgradeable {
    // Marker interface to make an ERC165 clash less likely
    function isIAspenFeaturesV0() external pure returns (bool);

    // List of features that contract supports and may be passed to featureVersion
    function supportedFeatures() external pure returns (string[] memory features);
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8;

// See https://docs.openzeppelin.com/contracts/4.x/utilities#multicall
interface IMulticallableV0 {
    function multicall(bytes[] calldata data) external returns (bytes[] memory results);
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8;

interface ISFTSupplyV0 {
    /**
     * @dev Total amount of tokens in with a given id.
     */
    function totalSupply(uint256 id) external view returns (uint256);

    /**
     * @dev Indicates whether any token exist with a given id, or not.
     */
    function exists(uint256 id) external view returns (bool);

    /**
     * @dev Amount of unique tokens minted.
     */
    function getLargestTokenId() external view returns (uint256);
}

interface ISFTSupplyV1 is ISFTSupplyV0 {
    /// @dev Offset for token IDs.
    function getSmallestTokenId() external view returns (uint8);
}

// SPDX-License-Identifier: Apache 2.0

pragma solidity ^0.8;

import "../IAspenFeatures.sol";
import "../IMulticallable.sol";
import "../IAspenVersioned.sol";
import "../issuance/ICedarSFTIssuance.sol";
import "../issuance/ISFTLimitSupply.sol";
import "../issuance/ISFTSupply.sol";
import "../baseURI/IUpdateBaseURI.sol";
import "../standard/IERC1155.sol";
import "../standard/IERC2981.sol";
import "../standard/IERC4906.sol";
import "../royalties/IRoyalty.sol";
import "../metadata/ISFTMetadata.sol";
import "../metadata/IContractMetadata.sol";
import "../agreement/IAgreement.sol";
import "../primarysale/IPrimarySale.sol";
import "../lazymint/ILazyMint.sol";
import "../pausable/IPausable.sol";
import "../ownable/IOwnable.sol";
import "../royalties/IPlatformFee.sol";

interface IAspenERC1155DropV1 is
    IAspenFeaturesV0,
    IAspenVersionedV2,
    IMulticallableV0,
    IPublicSFTIssuanceV2,
    ISFTSupplyV1,
    // NOTE: keep this standard interfaces around to generate supportsInterface
    IERC1155V2,
    IERC2981V0,
    IRestrictedERC4906V0,
    // NOTE: keep this standard interfaces around to generate supportsInterface ˆˆ
    IPublicRoyaltyV0,
    IPublicUpdateBaseURIV0,
    IPublicMetadataV0,
    IPublicOwnableV0,
    IAspenSFTMetadataV1,
    IPublicAgreementV1,
    IPublicPrimarySaleV1,
    IPublicPlatformFeeV0,
    IRestrictedAgreementV1,
    IDelegatedAgreementV0,
    IRestrictedSFTIssuanceV3,
    IRestrictedLazyMintV1,
    IRestrictedPausableV1,
    IRestrictedMetadataV2,
    IRestrictedUpdateBaseURIV1,
    IRestrictedRoyaltyV2,
    IRestrictedPrimarySaleV2,
    IRestrictedSFTLimitSupplyV1,
    IRestrictedOwnableV0,
    IRestrictedPlatformFeeV0
{}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8;

import "./IDropClaimCondition.sol";

/**
 *  Cedar's 'Drop' contracts are distribution mechanisms for tokens. The
 *  `DropERC721` contract is a distribution mechanism for ERC721 tokens.
 *
 *  A minter wallet (i.e. holder of `MINTER_ROLE`) can (lazy)mint 'n' tokens
 *  at once by providing a single base URI for all tokens being lazy minted.
 *  The URI for each of the 'n' tokens lazy minted is the provided base URI +
 *  `{tokenId}` of the respective token. (e.g. "ipsf://Qmece.../1").
 *
 *  A contract admin (i.e. holder of `DEFAULT_ADMIN_ROLE`) can create claim conditions
 *  with non-overlapping time windows, and accounts can claim the tokens according to
 *  restrictions defined in the claim condition that is active at the time of the transaction.
 */

interface ICedarSFTIssuanceV0 is IDropClaimConditionV0 {
    /// @dev Emitted when tokens are claimed.
    event TokensClaimed(
        uint256 indexed claimConditionIndex,
        uint256 indexed tokenId,
        address indexed claimer,
        address receiver,
        uint256 quantityClaimed
    );

    /// @dev Emitted when tokens are issued.
    event TokensIssued(uint256 indexed tokenId, address indexed claimer, address receiver, uint256 quantityClaimed);

    /// @dev Emitted when new claim conditions are set for a token.
    event ClaimConditionsUpdated(uint256 indexed tokenId, ClaimCondition[] claimConditions);

    /**
     *  @notice Lets a contract admin (account with `DEFAULT_ADMIN_ROLE`) set claim conditions.
     *
     *  @param tokenId               The token ID for which to set mint conditions.
     *  @param phases                Claim conditions in ascending order by `startTimestamp`.
     *  @param resetClaimEligibility Whether to reset `limitLastClaimTimestamp` and
     *                               `limitMerkleProofClaim` values when setting new
     *                               claim conditions.
     */
    function setClaimConditions(
        uint256 tokenId,
        ClaimCondition[] calldata phases,
        bool resetClaimEligibility
    ) external;

    /**
     *  @notice Lets an account claim a given quantity of NFTs.
     *
     *  @param receiver                       The receiver of the NFTs to claim.
     *  @param tokenId                       The unique ID of the token to claim.
     *  @param quantity                       The quantity of NFTs to claim.
     *  @param currency                       The currency in which to pay for the claim.
     *  @param pricePerToken                  The price per token to pay for the claim.
     *  @param proofs                         The proof of the claimer's inclusion in the merkle root allowlist
     *                                        of the claim conditions that apply.
     *  @param proofMaxQuantityPerTransaction (Optional) The maximum number of NFTs an address included in an
     *                                        allowlist can claim.
     */
    function claim(
        address receiver,
        uint256 tokenId,
        uint256 quantity,
        address currency,
        uint256 pricePerToken,
        bytes32[] calldata proofs,
        uint256 proofMaxQuantityPerTransaction
    ) external payable;

    /**
     *  @notice Lets an account with ISSUER_ROLE issue NFTs.
     *
     *  @param receiver                       The receiver of the NFTs to claim.
     *  @param tokenId                       The unique ID of the token to claim.
     *  @param quantity                       The quantity of NFTs to claim.
     */
    function issue(
        address receiver,
        uint256 tokenId,
        uint256 quantity
    ) external;
}

interface ICedarSFTIssuanceV1 is ICedarSFTIssuanceV0 {
    /// @dev Expose the current active claim condition including claim limits
    function getActiveClaimConditions(uint256 _tokenId)
        external
        view
        returns (
            ClaimCondition memory condition,
            uint256 conditionId,
            uint256 walletMaxClaimCount,
            uint256 remainingSupply
        );

    /// @dev Expose the user specific limits related to the current active claim condition
    function getUserClaimConditions(uint256 _tokenId, address _claimer)
        external
        view
        returns (
            uint256 conditionId,
            uint256 walletClaimedCount,
            uint256 lastClaimTimestamp,
            uint256 nextValidClaimTimestamp
        );

    /// @dev Checks a request to claim NFTs against the active claim condition's criteria.
    function verifyClaim(
        uint256 _conditionId,
        address _claimer,
        uint256 _tokenId,
        uint256 _quantity,
        address _currency,
        uint256 _pricePerToken,
        bool verifyMaxQuantityPerTransaction
    ) external view;
}

interface ICedarSFTIssuanceV2 is ICedarSFTIssuanceV0 {
    /// @dev Expose the current active claim condition including claim limits
    function getActiveClaimConditions(uint256 _tokenId)
        external
        view
        returns (
            ClaimCondition memory condition,
            uint256 conditionId,
            uint256 walletMaxClaimCount,
            uint256 remainingSupply,
            bool isClaimPaused
        );

    /// @dev Expose the user specific limits related to the current active claim condition
    function getUserClaimConditions(uint256 _tokenId, address _claimer)
        external
        view
        returns (
            uint256 conditionId,
            uint256 walletClaimedCount,
            uint256 walletClaimedCountInPhase,
            uint256 lastClaimTimestamp,
            uint256 nextValidClaimTimestamp
        );

    /// @dev Checks a request to claim NFTs against the active claim condition's criteria.
    function verifyClaim(
        uint256 _conditionId,
        address _claimer,
        uint256 _tokenId,
        uint256 _quantity,
        address _currency,
        uint256 _pricePerToken,
        bool verifyMaxQuantityPerTransaction
    ) external view;
}

interface ICedarSFTIssuanceV3 is ICedarSFTIssuanceV0 {
    /// @dev Expose the current active claim condition including claim limits
    function getActiveClaimConditions(uint256 _tokenId)
        external
        view
        returns (
            ClaimCondition memory condition,
            uint256 conditionId,
            uint256 walletMaxClaimCount,
            uint256 tokenSupply,
            uint256 maxTotalSupply,
            bool isClaimPaused
        );

    /// @dev Expose the user specific limits related to the current active claim condition
    function getUserClaimConditions(uint256 _tokenId, address _claimer)
        external
        view
        returns (
            uint256 conditionId,
            uint256 walletClaimedCount,
            uint256 walletClaimedCountInPhase,
            uint256 lastClaimTimestamp,
            uint256 nextValidClaimTimestamp
        );

    /// @dev Checks a request to claim NFTs against the active claim condition's criteria.
    function verifyClaim(
        uint256 _conditionId,
        address _claimer,
        uint256 _tokenId,
        uint256 _quantity,
        address _currency,
        uint256 _pricePerToken,
        bool verifyMaxQuantityPerTransaction
    ) external view;
}

interface IPublicSFTIssuanceV0 is IDropClaimConditionV0 {
    /**
     *  @notice Lets an account claim a given quantity of NFTs.
     *
     *  @param receiver                       The receiver of the NFTs to claim.
     *  @param tokenId                       The unique ID of the token to claim.
     *  @param quantity                       The quantity of NFTs to claim.
     *  @param currency                       The currency in which to pay for the claim.
     *  @param pricePerToken                  The price per token to pay for the claim.
     *  @param proofs                         The proof of the claimer's inclusion in the merkle root allowlist
     *                                        of the claim conditions that apply.
     *  @param proofMaxQuantityPerTransaction (Optional) The maximum number of NFTs an address included in an
     *                                        allowlist can claim.
     */
    function claim(
        address receiver,
        uint256 tokenId,
        uint256 quantity,
        address currency,
        uint256 pricePerToken,
        bytes32[] calldata proofs,
        uint256 proofMaxQuantityPerTransaction
    ) external payable;

    /// @dev Expose the current active claim condition including claim limits
    function getActiveClaimConditions(uint256 _tokenId)
        external
        view
        returns (
            ClaimCondition memory condition,
            uint256 conditionId,
            uint256 walletMaxClaimCount,
            uint256 tokenSupply,
            uint256 maxTotalSupply,
            bool isClaimPaused
        );

    /// @dev Expose the user specific limits related to the current active claim condition
    function getUserClaimConditions(uint256 _tokenId, address _claimer)
        external
        view
        returns (
            uint256 conditionId,
            uint256 walletClaimedCount,
            uint256 walletClaimedCountInPhase,
            uint256 lastClaimTimestamp,
            uint256 nextValidClaimTimestamp
        );

    /// @dev Checks a request to claim NFTs against the active claim condition's criteria.
    function verifyClaim(
        uint256 _conditionId,
        address _claimer,
        uint256 _tokenId,
        uint256 _quantity,
        address _currency,
        uint256 _pricePerToken,
        bool verifyMaxQuantityPerTransaction
    ) external view;
}

interface IPublicSFTIssuanceV1 is IPublicSFTIssuanceV0 {
    /// @dev Emitted when tokens are claimed.
    event TokensClaimed(
        uint256 indexed claimConditionIndex,
        uint256 indexed tokenId,
        address indexed claimer,
        address receiver,
        uint256 quantityClaimed
    );
}

interface IPublicSFTIssuanceV2 is IDropClaimConditionV1 {
    /// @dev Emitted when tokens are claimed.
    event TokensClaimed(
        uint256 indexed claimConditionIndex,
        uint256 indexed tokenId,
        address indexed claimer,
        address receiver,
        uint256 quantityClaimed,
        bytes32 phaseId
    );

    /**
     *  @notice Lets an account claim a given quantity of NFTs.
     *
     *  @param receiver                       The receiver of the NFTs to claim.
     *  @param tokenId                       The unique ID of the token to claim.
     *  @param quantity                       The quantity of NFTs to claim.
     *  @param currency                       The currency in which to pay for the claim.
     *  @param pricePerToken                  The price per token to pay for the claim.
     *  @param proofs                         The proof of the claimer's inclusion in the merkle root allowlist
     *                                        of the claim conditions that apply.
     *  @param proofMaxQuantityPerTransaction (Optional) The maximum number of NFTs an address included in an
     *                                        allowlist can claim.
     */
    function claim(
        address receiver,
        uint256 tokenId,
        uint256 quantity,
        address currency,
        uint256 pricePerToken,
        bytes32[] calldata proofs,
        uint256 proofMaxQuantityPerTransaction
    ) external payable;

    /// @dev Expose the current active claim condition including claim limits
    function getActiveClaimConditions(uint256 _tokenId)
        external
        view
        returns (
            ClaimCondition memory condition,
            uint256 conditionId,
            uint256 walletMaxClaimCount,
            uint256 tokenSupply,
            uint256 maxTotalSupply,
            bool isClaimPaused
        );

    /// @dev Expose the user specific limits related to the current active claim condition
    function getUserClaimConditions(uint256 _tokenId, address _claimer)
        external
        view
        returns (
            uint256 conditionId,
            uint256 walletClaimedCount,
            uint256 walletClaimedCountInPhase,
            uint256 lastClaimTimestamp,
            uint256 nextValidClaimTimestamp
        );

    /// @dev Returns the claim condition at the given uid.
    function getClaimConditionById(uint256 _tokenId, uint256 _conditionId)
        external
        view
        returns (ClaimCondition memory condition);

    /// @dev Checks a request to claim NFTs against the active claim condition's criteria.
    function verifyClaim(
        uint256 _conditionId,
        address _claimer,
        uint256 _tokenId,
        uint256 _quantity,
        address _currency,
        uint256 _pricePerToken,
        bool verifyMaxQuantityPerTransaction
    ) external view;
}

interface IRestrictedSFTIssuanceV0 is IDropClaimConditionV0 {
    /**
     *  @notice Lets a contract admin (account with `DEFAULT_ADMIN_ROLE`) set claim conditions.
     *
     *  @param tokenId               The token ID for which to set mint conditions.
     *  @param phases                Claim conditions in ascending order by `startTimestamp`.
     *  @param resetClaimEligibility Whether to reset `limitLastClaimTimestamp` and
     *                               `limitMerkleProofClaim` values when setting new
     *                               claim conditions.
     */
    function setClaimConditions(
        uint256 tokenId,
        ClaimCondition[] calldata phases,
        bool resetClaimEligibility
    ) external;

    /**
     *  @notice Lets an account with ISSUER_ROLE issue NFTs.
     *
     *  @param receiver                       The receiver of the NFTs to claim.
     *  @param tokenId                       The unique ID of the token to claim.
     *  @param quantity                       The quantity of NFTs to claim.
     */
    function issue(
        address receiver,
        uint256 tokenId,
        uint256 quantity
    ) external;
}

interface IRestrictedSFTIssuanceV1 is IRestrictedSFTIssuanceV0 {
    /// @dev Emitted when tokens are issued.
    event TokensIssued(uint256 indexed tokenId, address indexed claimer, address receiver, uint256 quantityClaimed);

    /// @dev Emitted when new claim conditions are set for a token.
    event ClaimConditionsUpdated(uint256 indexed tokenId, ClaimCondition[] claimConditions);
}

interface IRestrictedSFTIssuanceV2 is IDropClaimConditionV1 {
    /// @dev Emitted when tokens are issued.
    event TokensIssued(uint256 indexed tokenId, address indexed claimer, address receiver, uint256 quantityClaimed);

    /// @dev Emitted when new claim conditions are set for a token.
    event ClaimConditionsUpdated(uint256 indexed tokenId, ClaimCondition[] claimConditions);

    /**
     *  @notice Lets a contract admin (account with `DEFAULT_ADMIN_ROLE`) set claim conditions.
     *
     *  @param tokenId               The token ID for which to set mint conditions.
     *  @param phases                Claim conditions in ascending order by `startTimestamp`.
     *  @param resetClaimEligibility Whether to reset `limitLastClaimTimestamp` and
     *                               `limitMerkleProofClaim` values when setting new
     *                               claim conditions.
     */
    function setClaimConditions(
        uint256 tokenId,
        ClaimCondition[] calldata phases,
        bool resetClaimEligibility
    ) external;

    /**
     *  @notice Lets an account with ISSUER_ROLE issue NFTs.
     *
     *  @param receiver                       The receiver of the NFTs to claim.
     *  @param tokenId                       The unique ID of the token to claim.
     *  @param quantity                       The quantity of NFTs to claim.
     */
    function issue(
        address receiver,
        uint256 tokenId,
        uint256 quantity
    ) external;
}

interface IRestrictedSFTIssuanceV3 is IRestrictedSFTIssuanceV2 {
    /// @dev Sets and Freezes the tokenURI of a specific token which overrides the one that would otherwise
    /// be generated from the baseURI. This function keeps tracks of whether the tokenURI or baseURI is fresher for a
    /// particular token. Emits a "TokenURIUpdated" and a "PermanentURI" event.
    function setPermantentTokenURI(uint256 tokenId, string memory _tokenURI) external;

    /// @dev Event emitted when permanent token uri is set
    event PermanentURI(string _value, uint256 indexed _id);

    /// @dev Sets the tokenURI of a specific token which overrides the one that would otherwise
    /// be generated from the baseURI. This function keeps tracks of whether the tokenURI or baseURI is fresher for a
    /// particular token. Emits TokenURIUpdated event.
    function setTokenURI(uint256 tokenId, string memory _tokenURI) external;

    /// @dev Event emitted when a token uri is update
    event TokenURIUpdated(uint256 indexed tokenId, address indexed updater, string tokenURI);
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";

interface IERC1155V0 is IERC1155Upgradeable {}

interface IERC1155V1 is IERC1155Upgradeable {
    function burn(
        address account,
        uint256 id,
        uint256 value
    ) external;

    function burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory values
    ) external;
}

interface IERC1155V2 is IERC1155V1 {
    function name() external returns (string memory);

    function symbol() external returns (string memory);
}

interface IERC1155SupplyV0 is IERC1155V0 {
    /**
     * @dev Total amount of tokens in with a given id.
     */
    function totalSupply(uint256 id) external view returns (uint256);

    /**
     * @dev Indicates whether any token exist with a given id, or not.
     */
    function exists(uint256 id) external view returns (bool);
}

interface IERC1155SupplyV1 is IERC1155SupplyV0 {
    /**
     * @dev Amount of unique tokens minted.
     */
    function getLargestTokenId() external view returns (uint256);
}

interface IERC1155SupplyV2 is IERC1155V1 {
    /**
     * @dev Total amount of tokens in with a given id.
     */
    function totalSupply(uint256 id) external view returns (uint256);

    /**
     * @dev Indicates whether any token exist with a given id, or not.
     */
    function exists(uint256 id) external view returns (bool);

    /**
     * @dev Amount of unique tokens minted.
     */
    function getLargestTokenId() external view returns (uint256);
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8;

// Note: So that it can be included in Delegated logic contract
interface IRestrictedERC4906V0 {
    /// @dev This event emits when the metadata of a token is changed.
    /// So that the third-party platforms such as NFT market could
    /// timely update the images and related attributes of the NFT.
    event MetadataUpdate(uint256 _tokenId);

    /// @dev This event emits when the metadata of a range of tokens is changed.
    /// So that the third-party platforms such as NFT market could
    /// timely update the images and related attributes of the NFTs.
    event BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId);
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8;

interface ICedarUpdateBaseURIV0 {
    /// @dev Emitted when base URI is updated.
    event BaseURIUpdated(uint256 baseURIIndex, string baseURI);

    /**
     *  @notice Lets a minter (account with `MINTER_ROLE`) update base URI
     */
    function updateBaseURI(uint256 baseURIIndex, string calldata _baseURIForTokens) external;

    /**
     *  @dev Gets the base URI indices
     */
    function getBaseURIIndices() external view returns (uint256[] memory);
}

interface IPublicUpdateBaseURIV0 {
    /**
     *  @dev Gets the base URI indices
     */
    function getBaseURIIndices() external view returns (uint256[] memory);
}

interface IRestrictedUpdateBaseURIV0 {
    /**
     *  @notice Lets a minter (account with `MINTER_ROLE`) update base URI
     */
    function updateBaseURI(uint256 baseURIIndex, string calldata _baseURIForTokens) external;
}

interface IRestrictedUpdateBaseURIV1 is IRestrictedUpdateBaseURIV0 {
    /// @dev Emitted when base URI is updated.
    event BaseURIUpdated(uint256 baseURIIndex, string baseURI);
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8;

interface ICedarAgreementV0 {
    // Accept legal terms associated with transfer of this NFT
    function acceptTerms() external;

    function userAgreement() external view returns (string memory);

    function termsActivated() external view returns (bool);

    function setTermsStatus(bool _status) external;

    function getAgreementStatus(address _address) external view returns (bool sig);

    function storeTermsAccepted(address _acceptor, bytes calldata _signature) external;
}

interface ICedarAgreementV1 {
    // Accept legal terms associated with transfer of this NFT
    event TermsActivationStatusUpdated(bool isActivated);
    event TermsUpdated(string termsURI, uint8 termsVersion);
    event TermsAccepted(string termsURI, uint8 termsVersion, address indexed acceptor);

    function acceptTerms() external;

    function acceptTerms(address _acceptor) external;

    function setTermsActivation(bool _active) external;

    function setTermsURI(string calldata _termsURI) external;

    function getTermsDetails()
        external
        view
        returns (
            string memory termsURI,
            uint8 termsVersion,
            bool termsActivated
        );

    function hasAcceptedTerms(address _address) external view returns (bool hasAccepted);

    //    function hasAcceptedTerms(address _address, uint8 _termsVersion) external view returns (bool hasAccepted);
}

interface IPublicAgreementV0 {
    function acceptTerms() external;

    function getTermsDetails()
        external
        view
        returns (
            string memory termsURI,
            uint8 termsVersion,
            bool termsActivated
        );

    function hasAcceptedTerms(address _address) external view returns (bool hasAccepted);

    function hasAcceptedTerms(address _address, uint8 _termsVersion) external view returns (bool hasAccepted);
}

interface IPublicAgreementV1 is IPublicAgreementV0 {
    /// @dev Emitted when the terms are accepted.
    event TermsAccepted(string termsURI, uint8 termsVersion, address indexed acceptor);
}

interface IRestrictedAgreementV0 {
    function acceptTerms(address _acceptor) external;

    function setTermsActivation(bool _active) external;

    function setTermsURI(string calldata _termsURI) external;
}

interface IRestrictedAgreementV1 is IRestrictedAgreementV0 {
    /// @dev Emitted when the terms are accepted by an issuer.
    event TermsAcceptedForAddress(string termsURI, uint8 termsVersion, address indexed acceptor, address caller);
    /// @dev Emitted when the terms are activated/deactivated.
    event TermsActivationStatusUpdated(bool isActivated);
    /// @dev Emitted when the terms URI is updated.
    event TermsUpdated(string termsURI, uint8 termsVersion);
}

interface IDelegatedAgreementV0 {
    /// @dev Emitted when the terms are accepted using singature of acceptor.
    event TermsWithSignatureAccepted(string termsURI, uint8 termsVersion, address indexed acceptor, bytes signature);

    function acceptTerms(address _acceptor, bytes calldata _signature) external;

    function batchAcceptTerms(address[] calldata _acceptors) external;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8;

interface IOwnableV0 {
    /// @dev Returns the owner of the contract.
    function owner() external view returns (address);

    /// @dev Lets a module admin set a new owner for the contract. The new owner must be a module admin.
    function setOwner(address _newOwner) external;

    /// @dev Emitted when a new Owner is set.
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
}

interface IOwnableEventV0 {
    /// @dev Emitted when a new Owner is set.
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
}

interface IPublicOwnableV0 is IOwnableEventV0 {
    /// @dev Returns the owner of the contract.
    function owner() external view returns (address);
}

interface IRestrictedOwnableV0 is IOwnableEventV0 {
    /// @dev Lets a module admin set a new owner for the contract. The new owner must be a module admin.
    function setOwner(address _newOwner) external;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8;

interface ICedarSFTMetadataV1 {
    /// @dev Returns the URI for a given tokenId.
    function uri(uint256 _tokenId) external view returns (string memory);
}

interface IAspenSFTMetadataV1 {
    /// @dev Returns the URI for a given tokenId.
    function uri(uint256 _tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

interface IPrimarySaleV0 {
    /// @dev The address that receives all primary sales value.
    function primarySaleRecipient() external view returns (address);

    /// @dev Lets a module admin set the default recipient of all primary sales.
    function setPrimarySaleRecipient(address _saleRecipient) external;

    /// @dev Emitted when a new sale recipient is set.
    event PrimarySaleRecipientUpdated(address indexed recipient);
}

interface IPrimarySaleV1 {
    /// @dev The address that receives all primary sales value.
    function primarySaleRecipient() external view returns (address);

    /// @dev Lets a module admin set the default recipient of all primary sales.
    function setPrimarySaleRecipient(address _saleRecipient) external;

    /// @dev Emitted when a new sale recipient is set.
    event PrimarySaleRecipientUpdated(address indexed recipient, bool frogs);
}

interface IPublicPrimarySaleV1 {
    /// @dev The address that receives all primary sales value.
    function primarySaleRecipient() external view returns (address);
}

interface IRestrictedPrimarySaleV1 {
    /// @dev Lets a module admin set the default recipient of all primary sales.
    function setPrimarySaleRecipient(address _saleRecipient) external;
}

interface IRestrictedPrimarySaleV2 is IRestrictedPrimarySaleV1 {
    /// @dev Emitted when a new sale recipient is set.
    event PrimarySaleRecipientUpdated(address indexed recipient);
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.4;

interface ICedarLazyMintV0 {
    /// @dev Emitted when tokens are lazy minted.
    event TokensLazyMinted(uint256 startTokenId, uint256 endTokenId, string baseURI);

    /**
     *  @notice Lets an account with `MINTER_ROLE` lazy mint 'n' NFTs.
     *          The URIs for each token is the provided `_baseURIForTokens` + `{tokenId}`.
     *
     *  @param amount           The amount of NFTs to lazy mint.
     *  @param baseURIForTokens The URI for the NFTs to lazy mint. If lazy minting
     *                           'delayed-reveal' NFTs, the is a URI for NFTs in the
     *                           un-revealed state.
     */
    function lazyMint(uint256 amount, string calldata baseURIForTokens) external;
}

interface IRestrictedLazyMintV0 {
    /**
     *  @notice Lets an account with `MINTER_ROLE` lazy mint 'n' NFTs.
     *          The URIs for each token is the provided `_baseURIForTokens` + `{tokenId}`.
     *
     *  @param amount           The amount of NFTs to lazy mint.
     *  @param baseURIForTokens The URI for the NFTs to lazy mint. If lazy minting
     *                           'delayed-reveal' NFTs, the is a URI for NFTs in the
     *                           un-revealed state.
     */
    function lazyMint(uint256 amount, string calldata baseURIForTokens) external;
}

interface IRestrictedLazyMintV1 is IRestrictedLazyMintV0 {
    /// @dev Emitted when tokens are lazy minted.
    event TokensLazyMinted(uint256 startTokenId, uint256 endTokenId, string baseURI);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8;

interface ICedarPausableV0 {
    /// @dev Pause claim functionality.
    function pauseClaims() external;

    /// @dev Un-pause claim functionality.
    function unpauseClaims() external;

    /// @dev Event emitted when claim functionality is paused/un-paused.
    event ClaimPauseStatusUpdated(bool pauseStatus);
}

interface ICedarPausableV1 {
    /// @dev Pause / Un-pause claim functionality.
    function setClaimPauseStatus(bool _pause) external;

    /// @dev Event emitted when claim functionality is paused/un-paused.
    event ClaimPauseStatusUpdated(bool pauseStatus);
}

interface IRestrictedPausableV0 {
    /// @dev Pause / Un-pause claim functionality.
    function setClaimPauseStatus(bool _pause) external;
}

interface IRestrictedPausableV1 is IRestrictedPausableV0 {
    /// @dev Event emitted when claim functionality is paused/un-paused.
    event ClaimPauseStatusUpdated(bool pauseStatus);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8;

interface IRestrictedSFTLimitSupplyV0 {
    function setMaxTotalSupply(uint256 _tokenId, uint256 _maxTotalSupply) external;
}

interface IRestrictedSFTLimitSupplyV1 is IRestrictedSFTLimitSupplyV0 {
    /// @dev Emitted when the global max supply of tokens is updated.
    event MaxTotalSupplyUpdated(uint256 tokenId, uint256 maxTotalSupply);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8;

interface ICedarMetadataV1 {
    /// @dev Contract level metadata.
    function contractURI() external view returns (string memory);

    /// @dev Lets a contract admin set the URI for contract-level metadata.
    function setContractURI(string calldata _uri) external;

    /// @dev Emitted when contractURI is updated
    event ContractURIUpdated(address indexed updater, string uri);
}

interface IPublicMetadataV0 {
    /// @dev Contract level metadata.
    function contractURI() external view returns (string memory);
}

interface IRestrictedMetadataV0 {
    /// @dev Lets a contract admin set the URI for contract-level metadata.
    function setContractURI(string calldata _uri) external;
}

interface IRestrictedMetadataV1 is IRestrictedMetadataV0 {
    /// @dev Emitted when contractURI is updated
    event ContractURIUpdated(address indexed updater, string uri);
}

interface IRestrictedMetadataV2 is IRestrictedMetadataV1 {
    /// @dev Lets a contract admin set the token name and symbol
    function setTokenNameAndSymbol(string calldata _name, string calldata _symbol) external;

    /// @dev Emitted when token name and symbol are updated
    event TokenNameAndSymbolUpdated(address indexed updater, string name, string symbol);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8;

interface IPublicPlatformFeeV0 {
    /// @dev Returns the platform fee bps and recipient.
    function getPlatformFeeInfo() external view returns (address, uint16);
}

interface IRestrictedPlatformFeeV0 {
    /// @dev Emitted when fee on primary sales is updated.
    event PlatformFeeInfoUpdated(address platformFeeRecipient, uint256 platformFeeBps);

    /// @dev Lets a module admin update the fees on primary sales.
    function setPlatformFeeInfo(address _platformFeeRecipient, uint256 _platformFeeBps) external;
}