// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;
import "./TradeCoinCompositionContract.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
contract TradeCoinCompositionSales is ReentrancyGuard {
    struct SaleQueue {
        address seller;
        address newOwner;
        uint256 priceInWei;
        bool payInFiat;
        bool isPayed;
    }

    struct Documents {
        bytes32[] docHash;
        bytes32[] docType;
        bytes32 rootHash;
    }

    TradeCoinCompositionContract public tradeCoinComposition;

    uint256 public tradeCoinTokenBalance;
    uint256 public weiBalance;
    
    event InitiateCommercialTxEvent(
        uint256 indexed tokenId,
        address indexed functionCaller,
        address indexed buyer,
        bool payInFiat,
        uint256 priceInWei,
        bool isPayed,
        bytes32[] docHash,
        bytes32[] docType,
        bytes32 rootHash
    );

    event FinishCommercialTxEvent(
        uint256 indexed tokenId,
        address indexed seller, 
        address indexed functionCaller, 
        bytes32[] dochash,
        bytes32[] docType,
        bytes32 rootHash
    );
    
    event CompleteSaleEvent(
        uint256 indexed tokenId,
        address indexed functionCaller,
        bytes32[] dochash,
        bytes32[] docType,
        bytes32 rootHash
    );

    event ReverseSaleEvent(
        uint256 indexed tokenId,
        address indexed functionCaller,
        bytes32[] dochash,
        bytes32[] docType,
        bytes32 rootHash
    );

    event ServicePaymentEvent(
        uint256 indexed tokenId,
        address indexed receiver,
        address indexed sender,
        bytes32 indexedDocHash,
        bytes32[] docHash,
        bytes32[] docType,
        bytes32 rootHash,
        uint256 paymentInWei,
        bool payInFiat
    );

    constructor(address _tradeCoinComposition) {
        tradeCoinComposition = TradeCoinCompositionContract(_tradeCoinComposition);
    }

    mapping(uint256 => SaleQueue) public pendingSales;

    function initiateCommercialTx(
        uint256 _tradeCoinCompositionTokenID,
        uint256 _priceInWei,
        address _newOwner,
        Documents memory _documents,
        bool _payInFiat
    ) external {
        tradeCoinComposition.transferFrom(msg.sender, address(this), _tradeCoinCompositionTokenID);
        pendingSales[_tradeCoinCompositionTokenID] = SaleQueue(
            msg.sender,
            _newOwner,
            _priceInWei,
            _payInFiat,
            _priceInWei == 0
        );
        tradeCoinTokenBalance += 1;
        emit InitiateCommercialTxEvent(
            _tradeCoinCompositionTokenID,
            msg.sender,
            _newOwner,
            _payInFiat,
            _priceInWei,
            _priceInWei == 0,
            _documents.docHash,
            _documents.docType,
            _documents.rootHash
        );
    }

    function finishCommercialTx(
        uint256 _tradeCoinCompositionTokenID,
        Documents memory _documents
    ) external payable {
        if(!pendingSales[_tradeCoinCompositionTokenID].payInFiat){
            require(
                pendingSales[_tradeCoinCompositionTokenID].priceInWei == msg.value,
                "Not the right price"
            );
        }
        address legalOwner = pendingSales[_tradeCoinCompositionTokenID].seller;
        
        pendingSales[_tradeCoinCompositionTokenID].isPayed = true;
        weiBalance += msg.value;
        emit FinishCommercialTxEvent(
            _tradeCoinCompositionTokenID,
            legalOwner,
            msg.sender,
            _documents.docHash,
            _documents.docType,
            _documents.rootHash
        );
        completeSale(_tradeCoinCompositionTokenID, _documents);
    }

    function completeSale(
        uint256 _tradeCoinCompositionTokenID,
        Documents memory _documents
    ) internal nonReentrant {
        require(pendingSales[_tradeCoinCompositionTokenID].isPayed, "Not payed");
        weiBalance -= pendingSales[_tradeCoinCompositionTokenID].priceInWei;
        tradeCoinTokenBalance -= 1;
        tradeCoinComposition.transferFrom(
            address(this),
            pendingSales[_tradeCoinCompositionTokenID].newOwner,
            _tradeCoinCompositionTokenID
        );
        payable(pendingSales[_tradeCoinCompositionTokenID].seller).transfer(
            pendingSales[_tradeCoinCompositionTokenID].priceInWei
        );
        delete pendingSales[_tradeCoinCompositionTokenID];
        emit CompleteSaleEvent(
            _tradeCoinCompositionTokenID,
            msg.sender,
            _documents.docHash,
            _documents.docType,
            _documents.rootHash
        );
    }

    function reverseSale(uint256 _tradeCoinCompositionTokenID, Documents memory _documents) external nonReentrant {
        require(
            pendingSales[_tradeCoinCompositionTokenID].seller == msg.sender ||
                pendingSales[_tradeCoinCompositionTokenID].newOwner == msg.sender,
            "Not the seller or new owner"
        );
        tradeCoinTokenBalance -= 1;
        tradeCoinComposition.transferFrom(
            address(this),
            pendingSales[_tradeCoinCompositionTokenID].seller,
            _tradeCoinCompositionTokenID
        );
        if (
            pendingSales[_tradeCoinCompositionTokenID].isPayed &&
            pendingSales[_tradeCoinCompositionTokenID].priceInWei != 0
        ) {
            weiBalance -= pendingSales[_tradeCoinCompositionTokenID].priceInWei;
            payable(pendingSales[_tradeCoinCompositionTokenID].seller).transfer(
                pendingSales[_tradeCoinCompositionTokenID].priceInWei
            );
        }
        delete pendingSales[_tradeCoinCompositionTokenID];
        emit ReverseSaleEvent(
            _tradeCoinCompositionTokenID,
            msg.sender,
            _documents.docHash,
            _documents.docType,
            _documents.rootHash
        );
    }

    function servicePayment(
        uint256 _tradeCoinCompositionTokenID,
        address _receiver,
        uint256 _paymentInWei,
        bool _payInFiat,
        Documents memory _documents
    ) 
        payable
        external
        nonReentrant
    {
        require(
            _documents.docHash.length == _documents.docType.length && 
                (_documents.docHash.length <= 2 || _documents.docType.length <= 2), 
            "Invalid length"
        );

        // When not paying in Fiat pay but in Eth
        if (!_payInFiat) {
            require(_paymentInWei >= msg.value && _paymentInWei > 0, "Promised to pay in Fiat");
            payable(_receiver).transfer(msg.value);
        }

        emit ServicePaymentEvent(
            _tradeCoinCompositionTokenID,
            _receiver,
            msg.sender,
            _documents.docHash[0],
            _documents.docHash,
            _documents.docType,
            _documents.rootHash,
            _paymentInWei,
            _payInFiat
        );
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./TradeCoinContract.sol";
import "./RoleControl.sol";

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract TradeCoinCompositionContract is ERC721, RoleControl, ReentrancyGuard {
    using Strings for uint256;

    uint256 private _tokenIdCounter;

    TradeCoinContract public tradeCoin;

    // structure of the metadata
    struct TradeCoinComposition {
        uint256[] tokenIdsOfTC;
        string composition;
        uint256 amount;
        bytes32 unit;
        State state;
        address currentHandler;
        string[] transformations;
        bytes32 rootHash;
    }

    struct Documents {
        bytes32[] docHash;
        bytes32[] docType;
        bytes32 rootHash;
    }

    // Enum of state of compNFT
    enum State {
        NonExistent,
        Created,
        Burned,
        EOL //end of life
    }

    // Definition of Events
    event CreateCompositionEvent(
        uint256 indexed tokenId,
        address indexed functionCaller,
        uint256[] productIds,
        bytes32[] docHash,
        bytes32[] docType,
        bytes32 rootHash,
        string geoLocation
    );

    event AddTransformationEvent(
        uint256 indexed tokenId,
        address indexed functionCaller,
        bytes32 indexed docHashIndexed,
        bytes32[] docHash,
        bytes32[] docType,
        bytes32 rootHash,
        uint256 weightLoss,
        string transformationCode,
        string geoLocation
    );

    event ChangeProductHandlerEvent(
        uint256 indexed tokenId,
        address indexed functionCaller,
        bytes32 docHashIndexed,
        bytes32[] docHash,
        bytes32[] docType,
        bytes32 rootHash,
        address newCurrentHandler,
        string geoLocation
    );

    event ChangeProductStateEvent(
        uint256 indexed tokenId,
        address indexed functionCaller,
        bytes32 docHashIndexed,
        bytes32[] docHash,
        bytes32[] docType,
        bytes32 rootHash,
        State newState,
        string geoLocation
    );

    event RemoveProductFromCompositionEvent(
        uint256 indexed tokenId,
        address indexed functionCaller,
        uint256 tokenIdOfProduct,
        bytes32[] docHash,
        bytes32[] docType,
        bytes32 rootHash,
        string geoLocation
    );

    event AppendProductToCompositionEvent(
        uint256 indexed tokenId,
        address indexed functionCaller,
        uint256 tokenIdOfProduct,
        bytes32[] docHash,
        bytes32[] docType,
        bytes32 rootHash,
        string geoLocation
    );

    event AddInformationEvent(
        uint256 indexed tokenId,
        address indexed functionCaller,
        bytes32 indexed docHashIndexed,
        bytes32[] docHash,
        bytes32[] docType,
        bytes32 rootHash
    );

    event DecompositionEvent(
        uint256 indexed tokenId,
        address indexed functionCaller,
        uint256[] productIds,
        bytes32[] docHash,
        bytes32[] docType,
        bytes32 rootHash,
        string geoLocation
    );

    event BurnEvent(
        uint256 indexed tokenId,
        address indexed functionCaller,
        bytes32 indexed docHashIndexed,
        bytes32[] docHash,
        bytes32[] docType,
        bytes32 rootHash,
        string geoLocation
    );

    event UnitConversionEvent(
        uint256 indexed tokenId,
        uint256 indexed amount,
        bytes32 previousAmountUnit,
        bytes32 newAmountUnit
    );

    // Self created modifiers/require
    modifier atState(State _state, uint256 _tokenId) {
        require(
            tradeCoinComposition[_tokenId].state == _state,
            "Invalid State"
        );
        _;
    }

    modifier notAtState(State _state, uint256 _tokenId) {
        require(
            tradeCoinComposition[_tokenId].state != _state,
            "Invalid State"
        );
        _;
    }

    modifier onlyLegalOwner(address _sender, uint256 _tokenId) {
        require(ownerOf(_tokenId) == _sender, "Not NFTOwner");
        _;
    }

    modifier isLegalOwnerOrCurrentHandler(address _sender, uint256 _tokenId) {
        require(
            tradeCoinComposition[_tokenId].currentHandler == _sender ||
                ownerOf(_tokenId) == _sender,
            "Not Owner/Handler"
        );
        _;
    }

    // Mapping for the metadata of the tradecoinComposition
    mapping(uint256 => TradeCoinComposition) public tradeCoinComposition;
    mapping(uint256 => string) private _tokenURIs;

    mapping(uint256 => address) public addressOfNewOwner;
    mapping(uint256 => uint256) public priceForOwnership;
    mapping(uint256 => bool) public paymentInFiat;

    /// block number in which the contract was deployed.
    uint256 public deployedOn;

    constructor(
        string memory _name,
        string memory _symbol,
        address _tradeCoin
    ) ERC721(_name, _symbol) RoleControl(msg.sender) {
        tradeCoin = TradeCoinContract(_tradeCoin);
        deployedOn = block.number;
    }

    function createComposition(
        string memory _compositionName,
        uint256[] memory _tokenIdsOfTC,
        Documents memory _documents,
        string memory _geoLocation
    ) external onlyTokenizerOrAdmin {
        uint256 length = _tokenIdsOfTC.length;
        require(length > 1, "Invalid Length");
        require(
            _documents.docHash.length == _documents.docType.length,
            "Document hash amount must match document type"
        );

        // Get new tokenId by incrementing
        _tokenIdCounter++;
        uint256 id = _tokenIdCounter;

        string[] memory emptyTransformations = new string[](0);

        uint256 totalAmount;
        bytes32 unitOfTC;
        for (uint256 i; i < length; ) {
            tradeCoin.transferFrom(msg.sender, address(this), _tokenIdsOfTC[i]);

            (
                ,
                uint256 amountOfTC,
                bytes32 oldUnitOfTC,
                TradeCoinContract.State stateOfProduct,
                ,

            ) = tradeCoin.tradeCoin(_tokenIdsOfTC[i]);
            require(
                stateOfProduct != TradeCoinContract.State.PendingCreation,
                "Product still pending"
            );
            totalAmount += amountOfTC;
            unitOfTC = oldUnitOfTC;
            unchecked {
                ++i;
            }
        }

        // Mint new token
        _safeMint(msg.sender, id);
        // Store data on-chain
        tradeCoinComposition[id] = TradeCoinComposition(
            _tokenIdsOfTC,
            _compositionName,
            totalAmount,
            unitOfTC,
            State.Created,
            msg.sender,
            emptyTransformations,
            bytes32(0)
        );

        _setTokenURI(id);

        // Fire off the event
        emit CreateCompositionEvent(
            id,
            msg.sender,
            _tokenIdsOfTC,
            _documents.docHash,
            _documents.docType,
            _documents.rootHash,
            _geoLocation
        );
    }

    function unitConversion(
        uint256 _tokenId,
        uint256 _amount,
        bytes32 _previousAmountUnit,
        bytes32 _newAmountUnit
    ) external onlyLegalOwner(msg.sender, _tokenId) {
        require(_amount > 0, "Can't be 0");
        require(_previousAmountUnit != _newAmountUnit, "Invalid Conversion");
        require(
            _previousAmountUnit == tradeCoinComposition[_tokenId].unit,
            "Invalid Match: unit"
        );

        tradeCoinComposition[_tokenId].amount = _amount;
        tradeCoinComposition[_tokenId].unit = _newAmountUnit;

        emit UnitConversionEvent(
            _tokenId,
            _amount,
            _previousAmountUnit,
            _newAmountUnit
        );
    }

    function appendProductToComposition(
        uint256 _tokenIdComposition,
        uint256 _tokenIdTC,
        Documents memory _documents,
        string memory _geoLocation
    ) external onlyTokenizerOrAdmin {
        require(ownerOf(_tokenIdComposition) != address(0));

        tradeCoin.transferFrom(msg.sender, address(this), _tokenIdTC);

        tradeCoinComposition[_tokenIdComposition].tokenIdsOfTC.push(_tokenIdTC);

        (, uint256 amountOfTC, , , , ) = tradeCoin.tradeCoin(_tokenIdTC);
        tradeCoinComposition[_tokenIdComposition].amount += amountOfTC;

        emit AppendProductToCompositionEvent(
            _tokenIdComposition,
            msg.sender,
            _tokenIdTC,
            _documents.docHash,
            _documents.docType,
            _documents.rootHash,
            _geoLocation
        );
    }

    function removeProductFromComposition(
        uint256 _tokenIdComposition,
        uint256 _indexTokenIdTC,
        Documents memory _documents,
        string memory _geoLocation
    ) external onlyTokenizerOrAdmin {
        uint256 lengthTokenIds = tradeCoinComposition[_tokenIdComposition]
            .tokenIdsOfTC
            .length;
        require(lengthTokenIds > 2, "Invalid lengths");
        require((lengthTokenIds - 1) >= _indexTokenIdTC, "Index not in range");

        uint256 tokenIdTC = tradeCoinComposition[_tokenIdComposition]
            .tokenIdsOfTC[_indexTokenIdTC];
        uint256 lastTokenId = tradeCoinComposition[_tokenIdComposition]
            .tokenIdsOfTC[lengthTokenIds - 1];

        tradeCoin.transferFrom(address(this), msg.sender, tokenIdTC);

        tradeCoinComposition[_tokenIdComposition].tokenIdsOfTC[
            _indexTokenIdTC
        ] = lastTokenId;

        tradeCoinComposition[_tokenIdComposition].tokenIdsOfTC.pop();

        (, uint256 amountOfTC, , , , ) = tradeCoin.tradeCoin(tokenIdTC);
        tradeCoinComposition[_tokenIdComposition].amount -= amountOfTC;

        emit RemoveProductFromCompositionEvent(
            _tokenIdComposition,
            msg.sender,
            _indexTokenIdTC,
            _documents.docHash,
            _documents.docType,
            _documents.rootHash,
            _geoLocation
        );
    }

    function decomposition(
        uint256 _tokenId,
        Documents memory _documents,
        string memory _geoLocation
    ) external {
        require(ownerOf(_tokenId) == msg.sender, "Not Owner");

        require(
            _documents.docHash.length == _documents.docType.length,
            "Document hash amount must match document type"
        );

        uint256[] memory productIds = tradeCoinComposition[_tokenId]
            .tokenIdsOfTC;
        uint256 length = productIds.length;
        for (uint256 i; i < length; ) {
            tradeCoin.transferFrom(address(this), msg.sender, productIds[i]);
            unchecked {
                ++i;
            }
        }

        delete tradeCoinComposition[_tokenId];
        _burn(_tokenId);

        emit DecompositionEvent(
            _tokenId,
            msg.sender,
            productIds,
            _documents.docHash,
            _documents.docType,
            _documents.rootHash,
            _geoLocation
        );
    }

    // Can only be called if Owner or approved account
    // In case of being an approved account, this account must be a Minter Role and Burner Role (Admin)
    function addTransformation(
        uint256 _tokenId,
        uint256 _amountLoss,
        string memory _transformationCode,
        Documents memory _documents,
        string memory _geoLocation
    )
        external
        isLegalOwnerOrCurrentHandler(msg.sender, _tokenId)
        notAtState(State.NonExistent, _tokenId)
    {
        require(
            _amountLoss <= tradeCoinComposition[_tokenId].amount,
            "Invalid amount loss"
        );

        require(
            _documents.docHash.length == _documents.docType.length,
            "Document hash amount must match document type"
        );

        tradeCoinComposition[_tokenId].transformations.push(
            _transformationCode
        );
        uint256 newAmount = tradeCoinComposition[_tokenId].amount - _amountLoss;
        tradeCoinComposition[_tokenId].amount = newAmount;
        tradeCoinComposition[_tokenId].rootHash = _documents.rootHash;

        emit AddTransformationEvent(
            _tokenId,
            msg.sender,
            _documents.docHash[0],
            _documents.docHash,
            _documents.docType,
            _documents.rootHash,
            newAmount,
            _transformationCode,
            _geoLocation
        );
    }

    function changeProductHandler(
        uint256 _tokenId,
        address _newCurrentHandler,
        Documents memory _documents,
        string memory _geoLocation
    ) external isLegalOwnerOrCurrentHandler(msg.sender, _tokenId) {
        require(
            _documents.docHash.length == _documents.docType.length,
            "Document hash amount must match document type"
        );

        tradeCoinComposition[_tokenId].currentHandler = _newCurrentHandler;
        tradeCoinComposition[_tokenId].rootHash = _documents.rootHash;

        emit ChangeProductHandlerEvent(
            _tokenId,
            msg.sender,
            _documents.docHash[0],
            _documents.docHash,
            _documents.docType,
            _documents.rootHash,
            _newCurrentHandler,
            _geoLocation
        );
    }

    function changeProductState(
        uint256 _tokenId,
        State _newState,
        Documents memory _documents,
        string memory _geoLocation
    ) external isLegalOwnerOrCurrentHandler(msg.sender, _tokenId) {
        require(
            _documents.docHash.length == _documents.docType.length,
            "Document hash amount must match document type"
        );

        tradeCoinComposition[_tokenId].state = _newState;
        tradeCoinComposition[_tokenId].rootHash = _documents.rootHash;

        emit ChangeProductStateEvent(
            _tokenId,
            msg.sender,
            _documents.docHash[0],
            _documents.docHash,
            _documents.docType,
            _documents.rootHash,
            _newState,
            _geoLocation
        );
    }

    // Function must be overridden as ERC721 and ERC721Enumerable are conflicting

    function addInformation(
        uint256[] memory _tokenIds,
        Documents memory _documents,
        bytes32[] memory _rootHash
    ) external onlyInformationHandlerOrAdmin {
        uint256 length = _tokenIds.length;
        require(length == _rootHash.length, "Invalid Length");

        require(
            _documents.docHash.length == _documents.docType.length,
            "Document hash amount must match document type"
        );

        for (uint256 _tokenId; _tokenId < length; ) {
            tradeCoinComposition[_tokenIds[_tokenId]].rootHash = _rootHash[
                _tokenId
            ];
            emit AddInformationEvent(
                _tokenIds[_tokenId],
                msg.sender,
                _documents.docHash[0],
                _documents.docHash,
                _documents.docType,
                _rootHash[_tokenId]
            );
            unchecked {
                ++_tokenId;
            }
        }
    }

    function massApproval(uint256[] memory _tokenIds, address to) external {
        for (uint256 i; i < _tokenIds.length; i++) {
            require(
                ownerOf(_tokenIds[i]) == msg.sender,
                "You are not the approver"
            );
            approve(to, _tokenIds[i]);
        }
    }

    function burn(
        uint256 _tokenId,
        Documents memory _documents,
        string memory _geoLocation
    ) public virtual onlyLegalOwner(msg.sender, _tokenId) {
        _burn(_tokenId);
        // Remove lingering data to refund gas costs
        delete tradeCoinComposition[_tokenId];
        emit BurnEvent(
            _tokenId,
            msg.sender,
            _documents.docHash[0],
            _documents.docHash,
            _documents.docType,
            _documents.rootHash,
            _geoLocation
        );
    }

    function getIdsOfComposite(uint256 _tokenId)
        public
        view
        returns (uint256[] memory)
    {
        return tradeCoinComposition[_tokenId].tokenIdsOfTC;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function getTransformationsbyIndex(
        uint256 _tokenId,
        uint256 _transformationIndex
    ) public view returns (string memory) {
        return
            tradeCoinComposition[_tokenId].transformations[
                _transformationIndex
            ];
    }

    function getTransformationsLength(uint256 _tokenId)
        public
        view
        returns (uint256)
    {
        return tradeCoinComposition[_tokenId].transformations.length;
    }

    function ConcatenateArrays(
        uint256[] memory Accounts,
        uint256[] memory Accounts2
    ) internal pure returns (uint256[] memory) {
        uint256 length = Accounts.length;
        uint256[] memory returnArr = new uint256[](length + Accounts2.length);

        uint256 i = 0;
        for (; i < length; ) {
            returnArr[i] = Accounts[i];
            unchecked {
                ++i;
            }
        }

        uint256 j = 0;
        while (j < length) {
            returnArr[i++] = Accounts2[j++];
        }

        return returnArr;
    }

    // Set new baseURI
    // TODO: Set vaultURL as custom variable instead of hardcoded value Only for system admin/Contract owner
    function _baseURI()
        internal
        view
        virtual
        override(ERC721)
        returns (string memory)
    {
        return "http://tradecoinComposition.nl/vault/";
    }

    // Set token URI
    function _setTokenURI(uint256 tokenId) internal virtual {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI set of nonexistent token"
        );
        _tokenURIs[tokenId] = tokenId.toString();
    }

    // Function must be overridden as ERC721 and ERC721Enumerable are conflicting
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721) {
        super._beforeTokenTransfer(from, to, tokenId);
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
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
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.3;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./RoleControl.sol";

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract TradeCoinContract is ERC721, RoleControl, ReentrancyGuard {
    // SafeMath and Counters for creating unique ProductNFT identifiers
    // incrementing the tokenID by 1 after each mint
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    using Strings for uint256;

    // structure of the metadata
    struct TradeCoin {
        string product;
        uint256 amount; // can be in grams, liters, etc
        bytes32 unit;
        State state;
        address currentHandler;
        string[] transformations;
        bytes32 rootHash;
    }

    // Enum of state of productNFT
    enum State {
        PendingCreation,
        Created,
        Locked,
        ToBeBurned,
        EOL
    }

    struct Documents {
        bytes32[] docHash;
        bytes32[] docType;
        bytes32 rootHash;
    }

    // Definition of Events
    event InitialTokenizationEvent(
        uint256 indexed tokenId,
        address indexed functionCaller,
        string geoLocation
    );

    event MintAfterSplitOrBatchEvent(
        uint256 indexed tokenId,
        address indexed functionCaller,
        string geoLocation
    );

    event ApproveTokenizationEvent(
        uint256 indexed tokenId,
        address indexed seller,
        address indexed functionCaller,
        bytes32[] docHash,
        bytes32[] docType,
        bytes32 rootHash
    );

    event InitiateCommercialTxEvent(
        uint256 indexed tokenId,
        address indexed functionCaller,
        address indexed buyer,
        bytes32[] docHash,
        bytes32[] docType,
        bytes32 rootHash,
        bool payInFiat
    );

    event AddTransformationEvent(
        uint256 indexed tokenId,
        address indexed functionCaller,
        bytes32 indexed docHashIndexed,
        bytes32[] docHash,
        bytes32[] docType,
        bytes32 rootHash,
        uint256 weightLoss,
        string transformationCode,
        string geoLocation
    );

    event ChangeProductHandlerEvent(
        uint256 indexed tokenId,
        address indexed functionCaller,
        bytes32 docHashIndexed,
        bytes32[] docHash,
        bytes32[] docType,
        bytes32 rootHash,
        address newCurrentHandler,
        string geoLocation
    );

    event ChangeProductStateEvent(
        uint256 indexed tokenId,
        address indexed functionCaller,
        bytes32 docHashIndexed,
        bytes32[] docHash,
        bytes32[] docType,
        bytes32 rootHash,
        State newState,
        string geoLocation
    );

    event SplitProductEvent(
        uint256 indexed tokenId,
        address indexed functionCaller,
        uint256[] notIndexedTokenIds,
        string geoLocation
    );

    event BatchProductEvent(
        address indexed functionCaller,
        uint256[] notIndexedTokenIds,
        string geoLocation
    );

    event FinishCommercialTxEvent(
        uint256 indexed tokenId,
        address indexed seller,
        address indexed functionCaller,
        bytes32[] dochash,
        bytes32[] docType,
        bytes32 rootHash
    );

    event ServicePaymentEvent(
        uint256 indexed tokenId,
        address indexed receiver,
        address indexed sender,
        bytes32 indexedDocHash,
        bytes32[] docHash,
        bytes32[] docType,
        bytes32 rootHash,
        uint256 paymentInWei,
        bool payInFiat
    );

    event BurnEvent(
        uint256 indexed tokenId,
        address indexed functionCaller,
        bytes32 docHashIndexed,
        bytes32[] docHash,
        bytes32[] docType,
        bytes32 rootHash,
        string geoLocation
    );

    event AddInformationEvent(
        uint256 indexed tokenId,
        address indexed functionCaller,
        bytes32 docHashIndexed,
        bytes32[] docHash,
        bytes32[] docType,
        bytes32 rootHash
    );

    event UnitConversionEvent(
        uint256 indexed tokenId,
        uint256 indexed amount,
        bytes32 previousAmountUnit,
        bytes32 newAmountUnit
    );

    // Self created modifiers/require
    modifier atState(State _state, uint256 _tokenId) {
        require(tradeCoin[_tokenId].state == _state, "Incorrect State");
        _;
    }

    modifier notAtState(State _state, uint256 _tokenId) {
        require(tradeCoin[_tokenId].state != _state, "Incorrect State");
        _;
    }

    modifier onlyLegalOwner(address _sender, uint256 _tokenId) {
        require(ownerOf(_tokenId) == _sender, "Not Owner");
        _;
    }

    modifier isLegalOwnerOrCurrentHandler(address _sender, uint256 _tokenId) {
        require(
            tradeCoin[_tokenId].currentHandler == _sender ||
                ownerOf(_tokenId) == _sender,
            "Not the Owner nor current Handler."
        );
        _;
    }

    /// block number in which the contract was deployed.
    uint256 public deployedOn;

    // Mapping for the metadata of the tradecoin
    mapping(uint256 => TradeCoin) public tradeCoin;
    mapping(uint256 => string) private _tokenURIs;

    mapping(uint256 => address) public addressOfNewOwner;
    mapping(uint256 => uint256) public priceForOwnership;
    mapping(uint256 => bool) public paymentInFiat;

    constructor(string memory _name, string memory _symbol)
        ERC721(_name, _symbol)
        RoleControl(msg.sender)
    {
        deployedOn = block.number;
    }

    // We have a seperate tokenization function for the first time minting, we mint this value to the Farmer address
    function initialTokenization(
        string memory _product,
        uint256 _amount,
        bytes32 _unit,
        string memory _geoLocation,
        string memory defaultTransformation
    ) external onlyTokenizerOrAdmin {
        require(_amount > 0, "Weight can't be 0");

        // Set default transformations to raw
        string[] memory firstTransformation = new string[](1);
        firstTransformation[0] = defaultTransformation;

        // Get new tokenId by incrementing
        _tokenIdCounter.increment();
        uint256 id = _tokenIdCounter.current();

        // Mint new token
        _mint(msg.sender, id);
        // Store data on-chain
        tradeCoin[id] = TradeCoin(
            _product,
            _amount,
            _unit,
            State.PendingCreation,
            msg.sender,
            firstTransformation,
            bytes32(0)
        );

        _setTokenURI(id);

        // Fire off the event
        emit InitialTokenizationEvent(id, msg.sender, _geoLocation);
    }

    function unitConversion(
        uint256 _tokenId,
        uint256 _amount,
        bytes32 _previousAmountUnit,
        bytes32 _newAmountUnit
    ) external onlyLegalOwner(msg.sender, _tokenId) {
        require(_amount > 0, "Can't be 0");
        require(_previousAmountUnit != _newAmountUnit, "Invalid Conversion");
        require(
            _previousAmountUnit == tradeCoin[_tokenId].unit,
            "Invalid Match: unit"
        );

        tradeCoin[_tokenId].amount = _amount;
        tradeCoin[_tokenId].unit = _newAmountUnit;

        emit UnitConversionEvent(
            _tokenId,
            _amount,
            _previousAmountUnit,
            _newAmountUnit
        );
    }

    // Set up sale of token to approve the actual creation of the product
    function initiateCommercialTx(
        uint256 _tokenId,
        uint256 _paymentInWei,
        address _newOwner,
        Documents memory _documents,
        bool _payInFiat
    ) external onlyLegalOwner(msg.sender, _tokenId) {
        require(msg.sender != _newOwner, "You can't sell to yourself");
        require(
            _documents.docHash.length == _documents.docType.length,
            "Document hash amount must match document type"
        );
        if (_payInFiat) {
            require(_paymentInWei == 0, "Not eth amount");
        } else {
            require(_paymentInWei != 0, "Not Fiat amount");
        }
        priceForOwnership[_tokenId] = _paymentInWei;
        addressOfNewOwner[_tokenId] = _newOwner;
        paymentInFiat[_tokenId] = _payInFiat;
        tradeCoin[_tokenId].rootHash = _documents.rootHash;

        emit InitiateCommercialTxEvent(
            _tokenId,
            msg.sender,
            _newOwner,
            _documents.docHash,
            _documents.docType,
            _documents.rootHash,
            _payInFiat
        );
    }

    // Changing state from pending to created
    function approveTokenization(uint256 _tokenId, Documents memory _documents)
        external
        payable
        onlyProductHandlerOrAdmin
        atState(State.PendingCreation, _tokenId)
        nonReentrant
    {
        require(
            addressOfNewOwner[_tokenId] == msg.sender,
            "You don't have the right to pay"
        );

        require(
            priceForOwnership[_tokenId] <= msg.value,
            "You did not pay enough"
        );

        require(
            _documents.docHash.length == _documents.docType.length,
            "Document hash amount must match document type"
        );

        address _legalOwner = ownerOf(_tokenId);

        // When not paying in Fiat pay but in Eth
        if (!paymentInFiat[_tokenId]) {
            require(
                priceForOwnership[_tokenId] != 0,
                "This is not listed as an offer"
            );
            payable(_legalOwner).transfer(msg.value);
        }
        // else transfer
        _transfer(_legalOwner, msg.sender, _tokenId);

        // Change state and delete memory
        delete priceForOwnership[_tokenId];
        delete addressOfNewOwner[_tokenId];
        tradeCoin[_tokenId].state = State.Created;

        emit ApproveTokenizationEvent(
            _tokenId,
            _legalOwner,
            msg.sender,
            _documents.docHash,
            _documents.docType,
            _documents.rootHash
        );
    }

    // Can only be called if Owner or approved account
    // In case of being an approved account, this account must be a Minter Role and Burner Role (Admin)
    function addTransformation(
        uint256 _tokenId,
        uint256 _amountLoss,
        string memory _transformationCode,
        Documents memory _documents,
        string memory _geoLocation
    )
        external
        isLegalOwnerOrCurrentHandler(msg.sender, _tokenId)
        notAtState(State.PendingCreation, _tokenId)
    {
        require(
            _amountLoss > 0 && _amountLoss < tradeCoin[_tokenId].amount,
            "Invalid Weightloss"
        );

        require(
            _documents.docHash.length == _documents.docType.length,
            "Document hash amount must match document type"
        );

        tradeCoin[_tokenId].transformations.push(_transformationCode);
        uint256 newAmount = tradeCoin[_tokenId].amount - _amountLoss;
        tradeCoin[_tokenId].amount = newAmount;
        tradeCoin[_tokenId].rootHash = _documents.rootHash;

        emit AddTransformationEvent(
            _tokenId,
            msg.sender,
            _documents.docHash[0],
            _documents.docHash,
            _documents.docType,
            _documents.rootHash,
            newAmount,
            _transformationCode,
            _geoLocation
        );
    }

    function changeProductHandler(
        uint256 _tokenId,
        address _newCurrentHandler,
        Documents memory _documents,
        string memory _geoLocation
    )
        external
        isLegalOwnerOrCurrentHandler(msg.sender, _tokenId)
        notAtState(State.PendingCreation, _tokenId)
    {
        require(
            _documents.docHash.length == _documents.docType.length,
            "Document hash amount must match document type"
        );

        tradeCoin[_tokenId].currentHandler = _newCurrentHandler;
        tradeCoin[_tokenId].rootHash = _documents.rootHash;

        emit ChangeProductHandlerEvent(
            _tokenId,
            msg.sender,
            _documents.docHash[0],
            _documents.docHash,
            _documents.docType,
            _documents.rootHash,
            _newCurrentHandler,
            _geoLocation
        );
    }

    function changeProductState(
        uint256 _tokenId,
        State _newState,
        Documents memory _documents,
        string memory _geoLocation
    )
        external
        isLegalOwnerOrCurrentHandler(msg.sender, _tokenId)
        notAtState(State.PendingCreation, _tokenId)
    {
        require(
            _documents.docHash.length == _documents.docType.length,
            "Document hash amount must match document type"
        );

        tradeCoin[_tokenId].state = _newState;
        tradeCoin[_tokenId].rootHash = _documents.rootHash;

        emit ChangeProductStateEvent(
            _tokenId,
            msg.sender,
            _documents.docHash[0],
            _documents.docHash,
            _documents.docType,
            _documents.rootHash,
            _newState,
            _geoLocation
        );
    }

    function splitProduct(
        uint256 _tokenId,
        uint256[] memory partitions,
        Documents memory _documents,
        string memory _geoLocation
    )
        external
        onlyLegalOwner(msg.sender, _tokenId)
        notAtState(State.PendingCreation, _tokenId)
    {
        require(
            _documents.docHash.length == _documents.docType.length,
            "Document hash amount must match document type"
        );

        // create temp list of tokenIds
        uint256[] memory tempArray = new uint256[](partitions.length + 1);
        tempArray[0] = _tokenId;
        // create temp struct
        TradeCoin memory temporaryStruct = tradeCoin[_tokenId];

        uint256 sumPartitions;
        for (uint256 x; x < partitions.length; x++) {
            require(partitions[x] != 0, "Partitions can't be 0");
            sumPartitions += partitions[x];
        }

        require(
            tradeCoin[_tokenId].amount == sumPartitions,
            "Incorrect sum of amount"
        );

        emit SplitProductEvent(_tokenId, msg.sender, tempArray, _geoLocation);

        burn(_tokenId, _documents, _geoLocation);
        for (uint256 i; i < partitions.length; i++) {
            mintAfterSplitOrBatch(
                temporaryStruct.product,
                partitions[i],
                temporaryStruct.unit,
                temporaryStruct.state,
                temporaryStruct.currentHandler,
                temporaryStruct.transformations,
                _geoLocation
            );
            tempArray[i + 1] = _tokenIdCounter.current();
        }

        delete temporaryStruct;
    }

    function batchProduct(
        uint256[] memory _tokenIds,
        Documents memory _documents,
        string memory _geoLocation
    ) external {
        require(
            _documents.docHash.length == _documents.docType.length,
            "Document hash amount must match document type"
        );

        bytes32 emptyHash;
        uint256 cummulativeAmount;
        TradeCoin memory short = TradeCoin({
            product: tradeCoin[_tokenIds[0]].product,
            state: tradeCoin[_tokenIds[0]].state,
            currentHandler: tradeCoin[_tokenIds[0]].currentHandler,
            transformations: tradeCoin[_tokenIds[0]].transformations,
            amount: 0,
            unit: tradeCoin[_tokenIds[0]].unit,
            rootHash: emptyHash
        });

        bytes32 hashed = keccak256(abi.encode(short));

        uint256[] memory tempArray = new uint256[](_tokenIds.length + 1);

        emit BatchProductEvent(msg.sender, tempArray, _geoLocation);

        for (uint256 tokenId; tokenId < _tokenIds.length; tokenId++) {
            require(ownerOf(_tokenIds[tokenId]) == msg.sender, "Unauthorized");
            require(
                tradeCoin[_tokenIds[tokenId]].state != State.PendingCreation,
                "Invalid State"
            );
            TradeCoin memory short2 = TradeCoin({
                product: tradeCoin[_tokenIds[tokenId]].product,
                state: tradeCoin[_tokenIds[tokenId]].state,
                currentHandler: tradeCoin[_tokenIds[tokenId]].currentHandler,
                transformations: tradeCoin[_tokenIds[tokenId]].transformations,
                amount: 0,
                unit: tradeCoin[_tokenIds[tokenId]].unit,
                rootHash: emptyHash
            });
            require(hashed == keccak256(abi.encode(short2)), "Invalid PNFT");

            tempArray[tokenId] = _tokenIds[tokenId];
            // create temp struct
            cummulativeAmount += tradeCoin[_tokenIds[tokenId]].amount;
            burn(_tokenIds[tokenId], _documents, _geoLocation);
            delete tradeCoin[_tokenIds[tokenId]];
        }
        mintAfterSplitOrBatch(
            short.product,
            cummulativeAmount,
            short.unit,
            short.state,
            short.currentHandler,
            short.transformations,
            _geoLocation
        );
        tempArray[_tokenIds.length] = _tokenIdCounter.current();
    }

    function finishCommercialTx(uint256 _tokenId, Documents memory _documents)
        external
        payable
        notAtState(State.PendingCreation, _tokenId)
        nonReentrant
    {
        require(addressOfNewOwner[_tokenId] == msg.sender, "Unauthorized");

        require(priceForOwnership[_tokenId] <= msg.value, "Insufficient funds");

        require(
            _documents.docHash.length == _documents.docType.length,
            "Document hash amount must match document type"
        );

        address legalOwner = ownerOf(_tokenId);

        // When not paying in Fiat pay but in Eth
        if (!paymentInFiat[_tokenId]) {
            require(priceForOwnership[_tokenId] != 0, "Not for sale");
            payable(legalOwner).transfer(msg.value);
        }
        // else transfer
        _transfer(legalOwner, msg.sender, _tokenId);

        // Change state and delete memory
        delete priceForOwnership[_tokenId];
        delete addressOfNewOwner[_tokenId];

        emit FinishCommercialTxEvent(
            _tokenId,
            legalOwner,
            msg.sender,
            _documents.docHash,
            _documents.docType,
            _documents.rootHash
        );
    }

    function servicePayment(
        uint256 _tokenId,
        address _receiver,
        uint256 _paymentInWei,
        bool _payInFiat,
        Documents memory _documents
    ) external payable nonReentrant {
        require(
            _documents.docHash.length == _documents.docType.length,
            "Document hash amount must match document type"
        );

        // When not paying in Fiat pay but in Eth
        if (!_payInFiat) {
            require(
                _paymentInWei >= msg.value && _paymentInWei > 0,
                "Promised to pay in Fiat"
            );
            payable(_receiver).transfer(msg.value);
        }

        emit ServicePaymentEvent(
            _tokenId,
            _receiver,
            msg.sender,
            _documents.docHash[0],
            _documents.docHash,
            _documents.docType,
            _documents.rootHash,
            _paymentInWei,
            _payInFiat
        );
    }

    function addInformation(
        uint256[] memory _tokenIds,
        Documents memory _documents,
        bytes32[] memory _rootHash
    ) external onlyInformationHandlerOrAdmin {
        require(_tokenIds.length == _rootHash.length, "Invalid Length");

        require(
            _documents.docHash.length == _documents.docType.length,
            "Document hash amount must match document type"
        );

        for (uint256 _tokenId; _tokenId < _tokenIds.length; _tokenId++) {
            tradeCoin[_tokenIds[_tokenId]].rootHash = _rootHash[_tokenId];
            emit AddInformationEvent(
                _tokenIds[_tokenId],
                msg.sender,
                _documents.docHash[0],
                _documents.docHash,
                _documents.docType,
                _rootHash[_tokenId]
            );
        }
    }

    function massApproval(uint256[] memory _tokenIds, address to) external {
        for (uint256 i; i < _tokenIds.length; i++) {
            require(
                ownerOf(_tokenIds[i]) == msg.sender,
                "You are not the approver"
            );
            approve(to, _tokenIds[i]);
        }
    }

    function burn(
        uint256 _tokenId,
        Documents memory _documents,
        string memory _geoLocation
    ) public virtual onlyLegalOwner(msg.sender, _tokenId) {
        require(
            _documents.docHash.length == _documents.docType.length,
            "Document hash amount must match document type"
        );

        _burn(_tokenId);
        // Remove lingering data to refund gas costs
        delete tradeCoin[_tokenId];
        emit BurnEvent(
            _tokenId,
            msg.sender,
            _documents.docHash[0],
            _documents.docHash,
            _documents.docType,
            _documents.rootHash,
            _geoLocation
        );
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function getTransformationsbyIndex(
        uint256 _tokenId,
        uint256 _transformationIndex
    ) public view returns (string memory) {
        return tradeCoin[_tokenId].transformations[_transformationIndex];
    }

    function getTransformationsLength(uint256 _tokenId)
        public
        view
        returns (uint256)
    {
        return tradeCoin[_tokenId].transformations.length;
    }

    // This function will mint a token to
    function mintAfterSplitOrBatch(
        string memory _product,
        uint256 _amount,
        bytes32 _unit,
        State _state,
        address currentHandler,
        string[] memory transformations,
        string memory _geoLocation
    ) internal {
        require(_amount != 0, "Insufficient Amount");

        // Get new tokenId by incrementing
        _tokenIdCounter.increment();
        uint256 id = _tokenIdCounter.current();

        // Mint new token
        _mint(msg.sender, id);
        // Store data on-chain
        tradeCoin[id] = TradeCoin(
            _product,
            _amount,
            _unit,
            _state,
            currentHandler,
            transformations,
            bytes32(0)
        );

        _setTokenURI(id);

        // Fire off the event
        emit MintAfterSplitOrBatchEvent(id, msg.sender, _geoLocation);
    }

    // Set new baseURI
    // TODO: Set vaultURL as custom variable instead of hardcoded value Only for system admin/Contract owner
    function _baseURI()
        internal
        view
        virtual
        override(ERC721)
        returns (string memory)
    {
        return "http://tradecoin.nl/vault/";
    }

    // Set token URI
    function _setTokenURI(uint256 tokenId) internal virtual {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI set of nonexistent token"
        );
        _tokenURIs[tokenId] = tokenId.toString();
    }

    // Function must be overridden as ERC721 are conflicting
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721) {
        super._beforeTokenTransfer(from, to, tokenId);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/access/AccessControl.sol";

contract RoleControl is AccessControl {
    // We use keccak256 to create a hash that identifies this constant in the contract
    bytes32 public constant TOKENIZER_ROLE = keccak256("TOKENIZER_ROLE"); // hash a MINTER_ROLE as a role constant
    bytes32 public constant PRODUCT_HANDLER_ROLE =
        keccak256("PRODUCT_HANDLER_ROLE"); // hash a BURNER_ROLE as a role constant
    bytes32 public constant INFORMATION_HANDLER_ROLE =
        keccak256("INFORMATION_HANDLER_ROLE"); // hash a BURNER_ROLE as a role constant

    // Constructor of the RoleControl contract
    constructor(address root) {
        // NOTE: Other DEFAULT_ADMIN's can remove other admins, give this role with great care
        _setupRole(DEFAULT_ADMIN_ROLE, root); // The creator of the contract is the default admin

        // SETUP role Hierarchy:
        // DEFAULT_ADMIN_ROLE > MINTER_ROLE > BURNER_ROLE > no role
        _setRoleAdmin(TOKENIZER_ROLE, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(PRODUCT_HANDLER_ROLE, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(INFORMATION_HANDLER_ROLE, DEFAULT_ADMIN_ROLE);
    }

    // Create a bool check to see if a account address has the role admin
    function isAdmin(address account) public view virtual returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, account);
    }

    // Create a modifier that can be used in other contract to make a pre-check
    // That makes sure that the sender of the transaction (msg.sender)  is a admin
    modifier onlyAdmin() {
        require(isAdmin(msg.sender), "Restricted to admins.");
        _;
    }

    // Add a user address as a admin
    function addAdmin(address account) public virtual onlyAdmin {
        grantRole(DEFAULT_ADMIN_ROLE, account);
    }

    // Remove a user as a admin
    function removeAdmin(address account) public virtual onlyAdmin {
        revokeRole(DEFAULT_ADMIN_ROLE, account);
    }

    // Create a bool check to see if a account address has the role admin or Tokenizer
    function isTokenizerOrAdmin(address account)
        public
        view
        virtual
        returns (bool)
    {
        return (hasRole(TOKENIZER_ROLE, account) ||
            hasRole(DEFAULT_ADMIN_ROLE, account));
    }

    // Create a modifier that can be used in other contract to make a pre-check
    // That makes sure that the sender of the transaction (msg.sender) is a admin or Tokenizer
    modifier onlyTokenizerOrAdmin() {
        require(
            isTokenizerOrAdmin(msg.sender),
            "Restricted to FTokenizer or admins."
        );
        _;
    }

    // Add a user address as a Tokenizer
    function addTokenizer(address account) public virtual onlyAdmin {
        grantRole(TOKENIZER_ROLE, account);
    }

    // remove a user address as a Tokenizer
    function removeTokenizer(address account) public virtual onlyAdmin {
        revokeRole(TOKENIZER_ROLE, account);
    }

    // Create a bool check to see if a account address has the role admin or ProductHandlers
    function isProductHandlerOrAdmin(address account)
        public
        view
        virtual
        returns (bool)
    {
        return (hasRole(PRODUCT_HANDLER_ROLE, account) ||
            hasRole(DEFAULT_ADMIN_ROLE, account));
    }

    // Create a modifier that can be used in other contract to make a pre-check
    // That makes sure that the sender of the transaction (msg.sender) is a admin or ProductHandlers
    modifier onlyProductHandlerOrAdmin() {
        require(
            isProductHandlerOrAdmin(msg.sender),
            "Restricted to ProductHandlers or admins."
        );
        _;
    }

    // Add a user address as a ProductHandlers
    function addProductHandler(address account) public virtual onlyAdmin {
        grantRole(PRODUCT_HANDLER_ROLE, account);
    }

    // remove a user address as a ProductHandlers
    function removeProductHandler(address account) public virtual onlyAdmin {
        revokeRole(PRODUCT_HANDLER_ROLE, account);
    }

    // Create a bool check to see if a account address has the role admin or InformationHandlers
    function isInformationHandlerOrAdmin(address account)
        public
        view
        virtual
        returns (bool)
    {
        return (hasRole(INFORMATION_HANDLER_ROLE, account) ||
            hasRole(DEFAULT_ADMIN_ROLE, account));
    }

    // Create a modifier that can be used in other contract to make a pre-check
    // That makes sure that the sender of the transaction (msg.sender) is a admin or InformationHandlers
    modifier onlyInformationHandlerOrAdmin() {
        require(
            isInformationHandlerOrAdmin(msg.sender),
            "Restricted to InformationHandlers or admins."
        );
        _;
    }

    // Add a user address as a InformationHandlers
    function addInformationHandler(address account) public virtual onlyAdmin {
        grantRole(INFORMATION_HANDLER_ROLE, account);
    }

    // remove a user address as a InformationHandlers
    function removeInformationHandler(address account)
        public
        virtual
        onlyAdmin
    {
        revokeRole(INFORMATION_HANDLER_ROLE, account);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

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
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
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
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControl.sol)

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
        _checkRole(role, _msgSender());
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
}

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