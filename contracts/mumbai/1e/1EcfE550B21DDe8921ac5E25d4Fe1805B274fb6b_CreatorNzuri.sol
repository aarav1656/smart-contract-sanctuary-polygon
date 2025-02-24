// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../openzepplin-contracts/access/Ownable.sol";
import "../nzuri/ERC721Nzuri.sol";
import "../nzuri/ERC1155Nzuri.sol";
import "../nzuri/ExchangeNzuri.sol";
import "../nzuri/AuctionFactoryNzuri.sol";
import "../nzuri/DropMinting.sol";
import "./ICreators.sol";

contract CreatorNzuri is Ownable {
  event ContractsCreated(
    address erc721Address,
    address erc1155Address,
    address exchangeAddress,
    address auctionFactoryAddress,
    address dropMintingAddress
  );

  IERC721NzuriCreator private erc721Creator;
  IERC1155NzuriCreator private erc1155Creator;
  IExchangeNzuriCreator private exchangeCreator;
  IAuctionFactoryNzuriCreator private auctionFactoryCreator;
  IDropMintingCreator private dropMintingCreator;

  ERC721Nzuri private erc721Contract;
  ERC1155Nzuri private erc1155Contract;
  ExchangeNzuri private exchangeContract;
  AuctionFactoryNzuri private auctionFactoryContract;
  DropMinting private dropMintingContract;

  address private erc721ContractAddress;
  address private erc1155ContractAddress;
  address private exchangeContractAddress;
  address private auctionFactoryContractAddress;
  address private dropMintingContractAddress;

  constructor(
    address erc721CreatorAddress,
    address erc1155CreatorAddress,
    address exchangeCreatorAddress,
    address auctionFactoryCreatorAddress,
    address dropMintingCreatorAddress
  ) {
    require(erc721CreatorAddress != address(0), "Invalid erc721CreatorAddress");
    require(erc1155CreatorAddress != address(0), "Invalid erc1155CreatorAddress");
    require(exchangeCreatorAddress != address(0), "Invalid exchangeCreatorAddress");
    require(auctionFactoryCreatorAddress != address(0), "Invalid auctionFactoryCreatorAddress");
    require(dropMintingCreatorAddress != address(0), "Invalid dropMintingCreatorAddress");

    erc721Creator = IERC721NzuriCreator(erc721CreatorAddress);
    erc1155Creator = IERC1155NzuriCreator(erc1155CreatorAddress);
    exchangeCreator = IExchangeNzuriCreator(exchangeCreatorAddress);
    auctionFactoryCreator = IAuctionFactoryNzuriCreator(auctionFactoryCreatorAddress);
    dropMintingCreator = IDropMintingCreator(dropMintingCreatorAddress);
  }

  function createContracts(
    address[2] memory addressData,
//  address owner
//  address erc20
    string[3] memory erc721Strings,
//  string erc721Name,
//  string erc721Symbol,
//  string erc721BaseURI,
    uint256[4] memory dropData,
//  uint256 dropStart,
//  uint256 dropEnd,
//  uint256 dropPrice,
//  uint256 dropMintLimitTotal,
    address[] memory dropMintShareholders,
    uint8[] memory dropMintFeeRates,
    address[] memory exchangeShareholders,
    uint8[] memory exchangeFeeRates,
    address[] memory auctionShareholders,
    uint8[] memory auctionFeeRates
  ) external onlyOwner {
    erc721ContractAddress = erc721Creator.createContract(erc721Strings[0], erc721Strings[1], erc721Strings[2]);
    erc1155ContractAddress = erc1155Creator.createContract(erc721Strings[0], erc721Strings[2]);
    exchangeContractAddress = exchangeCreator.createContract(
      addressData[0],
      addressData[1],
      erc721ContractAddress,
      erc1155ContractAddress
    );
    auctionFactoryContractAddress = auctionFactoryCreator.createContract(
      addressData[0],
      addressData[1],
      erc721ContractAddress,
      erc1155ContractAddress
    );
    dropMintingContractAddress = dropMintingCreator.createContract(
      addressData[1],
      erc721ContractAddress,
      dropData[0],
      dropData[1],
      dropData[2],
      dropData[3]
    );

    erc721Contract = ERC721Nzuri(erc721ContractAddress);
    erc1155Contract = ERC1155Nzuri(erc1155ContractAddress);
    exchangeContract = ExchangeNzuri(exchangeContractAddress);
    auctionFactoryContract = AuctionFactoryNzuri(auctionFactoryContractAddress);
    dropMintingContract = DropMinting(dropMintingContractAddress);

    erc721Contract.grantRole(erc721Contract.MINTER_ROLE(), dropMintingContractAddress);

    erc721Contract.grantRole(erc721Contract.DEFAULT_ADMIN_ROLE(), addressData[0]);
    erc721Contract.revokeRole(erc721Contract.DEFAULT_ADMIN_ROLE(), address(this));

    erc1155Contract.grantRole(erc1155Contract.DEFAULT_ADMIN_ROLE(), addressData[0]);
    erc1155Contract.revokeRole(erc1155Contract.DEFAULT_ADMIN_ROLE(), address(this));

    exchangeContract.setShareholders(exchangeShareholders, exchangeFeeRates);
    auctionFactoryContract.setShareholders(auctionShareholders, auctionFeeRates);
    dropMintingContract.setShareholders(dropMintShareholders, dropMintFeeRates);

    exchangeContract.transferOwnership(addressData[0]);
    auctionFactoryContract.transferOwnership(addressData[0]);
    dropMintingContract.transferOwnership(addressData[0]);

    exchangeContract.setFeeCollectorAdmin(addressData[0]);
    auctionFactoryContract.setFeeCollectorAdmin(addressData[0]);
    dropMintingContract.setFeeCollectorAdmin(addressData[0]);


    erc721Contract.setApprovalForAll(dropMintingContractAddress, true);

    emit ContractsCreated(
      erc721ContractAddress,
      erc1155ContractAddress,
      exchangeContractAddress,
      auctionFactoryContractAddress,
      dropMintingContractAddress
    );
  }
}


contract ERC721NzuriCreator is Ownable, IERC721NzuriCreator {
  function createContract(
    string memory name,
    string memory symbol,
    string memory baseURI
  ) external override onlyOwner returns(address contractAddress) {
    ERC721Nzuri erc721Contract = new ERC721Nzuri(name, symbol, baseURI);
    erc721Contract.grantRole(erc721Contract.DEFAULT_ADMIN_ROLE(), msg.sender);
    contractAddress = address(erc721Contract);
  }
}

contract ERC1155NzuriCreator is Ownable, IERC1155NzuriCreator {
  function createContract(
    string memory name,
    string memory baseURI
  ) external override onlyOwner returns(address contractAddress) {
    ERC1155Nzuri erc1155Contract = new ERC1155Nzuri(name, baseURI);
    erc1155Contract.grantRole(erc1155Contract.DEFAULT_ADMIN_ROLE(), msg.sender);
    contractAddress = address(erc1155Contract);
  }
}

contract ExchangeNzuriCreator is Ownable, IExchangeNzuriCreator {
  function createContract(
    address owner,
    address erc20Address,
    address erc721Address,
    address erc1155Address
  ) external override onlyOwner returns(address contractAddress) {
    ExchangeNzuri exchangeContract = new ExchangeNzuri(
      owner,
      erc721Address,
      erc1155Address,
      erc20Address
    );
    exchangeContract.transferOwnership(msg.sender);
    exchangeContract.setFeeCollectorAdmin(msg.sender);
    contractAddress = address(exchangeContract);
  }
}

contract AuctionFactoryNzuriCreator is Ownable, IAuctionFactoryNzuriCreator {
  function createContract(
    address owner,
    address erc20Address,
    address erc721Address,
    address erc1155Address
  ) external override onlyOwner returns(address contractAddress) {
    AuctionFactoryNzuri auctionFactoryContract = new AuctionFactoryNzuri(
      erc20Address,
      erc721Address,
      erc1155Address,
      owner
    );
    auctionFactoryContract.transferOwnership(msg.sender);
    auctionFactoryContract.setFeeCollectorAdmin(msg.sender);
    contractAddress = address(auctionFactoryContract);
  }
}

contract DropMintingCreator is Ownable, IDropMintingCreator {
  function createContract(
    address erc20Address,
    address erc721Address,
    uint256 dropStart,
    uint256 dropEnd,
    uint256 dropPrice,
    uint256 dropMintLimitTotal
  ) external override onlyOwner returns(address contractAddress) {
    DropMinting dropMintingContract = new DropMinting(
      erc721Address,
      erc20Address,
      dropStart,
      dropEnd,
      dropPrice,
      dropMintLimitTotal
    );
    dropMintingContract.transferOwnership(msg.sender);
    dropMintingContract.setFeeCollectorAdmin(msg.sender);
    contractAddress = address(dropMintingContract);
  }
}

// SPDX-License-Identifier: MIT

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
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../openzepplin-contracts/token/ERC721/presets/ERC721PresetMinterPauserAutoId.sol";
import "../openzepplin-contracts/utils/math/SafeMath.sol";
import "../openzepplin-contracts/access/Ownable.sol";

import "../common/ContextMixin.sol";
import "../common/NativeMetaTransaction.sol";

contract ERC721Nzuri is ERC721PresetMinterPauserAutoId, ContextMixin, NativeMetaTransaction, Ownable {
    using Strings for uint256;
    event Create721Token(address indexed to, uint256 indexed tokenId);

    uint public defaultRevealDate;
    string public unrevealedTokenURI;
    mapping(uint256 => uint) private _tokenRevealDates;

    constructor(string memory name, string memory symbol, string memory baseTokenURI) ERC721PresetMinterPauserAutoId(name, symbol, baseTokenURI) {
      defaultRevealDate = block.timestamp;
    }

    /**
 * This is used instead of msg.sender as transactions won't be sent by the original token owner, but by OpenSea.
 */
    function _msgSender() internal override view returns (address sender){
        return ContextMixin.msgSender();
    }

    using Strings for uint256;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    function tokenRevealDate(uint256 tokenId) public view returns(uint256 _revealDate) {
      require(_exists(tokenId), "ERC721URIStorage: revealDate query for nonexistent token");
      _revealDate = _tokenRevealDates[tokenId];
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");

        uint revealDate = _tokenRevealDates[tokenId];
        if (block.timestamp < revealDate) {
          return unrevealedTokenURI;
        }
        return super.tokenURI(tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
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
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }

    function mint(address to) public virtual override returns(uint256 tokenId) {
        tokenId = super.mint(to);
        _tokenRevealDates[tokenId] = defaultRevealDate;

        emit Create721Token(to, tokenId);
    }

    function updateDefaultRevealDate(uint _timestamp) external onlyOwner {
      defaultRevealDate = _timestamp;
    }

    function updateUnrevealedTokenURI(string memory _URI) external onlyOwner {
      unrevealedTokenURI = _URI;
    }

    function updateRevealDate(uint256 _tokenId, uint _timestamp) external onlyOwner {
      require(_exists(_tokenId), "ERC721URIStorage: reveal date set of nonexistent token");
      _tokenRevealDates[_tokenId] = _timestamp;
    }

    function updateRevealDateMultiple(uint256 _tokenIdStart, uint256 _tokenIdEnd, uint _timestamp) external onlyOwner {
      require(_tokenIdStart < _tokenIdEnd, "tokenIdEnd should be greater than tokenIdStart");
      require(_exists(_tokenIdStart), "tokenIdStart is out of bounds");
      require(_exists(_tokenIdEnd), "tokenIdEnd is out of bounds");

      for (uint256 i = _tokenIdStart; i <= _tokenIdEnd; i++) {
        _tokenRevealDates[i] = _timestamp;
      }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../openzepplin-contracts/utils/Context.sol";
import "../openzepplin-contracts/access/AccessControlEnumerable.sol";
import "../openzepplin-contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "../openzepplin-contracts/token/ERC1155/extensions/ERC1155Pausable.sol";
import "../openzepplin-contracts/token/ERC1155/presets/ERC1155PresetMinterPauser.sol";

import "../common/ContextMixin.sol";
import "../common/NativeMetaTransaction.sol";

/**
 * @dev {ERC1155} token, including:
 *
 *  - ability for holders to burn (destroy) their tokens
 *  - a minter role that allows for token minting (creation)
 *  - a pauser role that allows to stop all token transfers
 *
 * This contract uses {AccessControl} to lock permissioned functions using the
 * different roles - head to its documentation for details.
 *
 * The account that deploys the contract will be granted the minter and pauser
 * roles, as well as the default admin role, which will let it grant both minter
 * and pauser roles to other accounts.
 */
contract ERC1155Nzuri is ERC1155PresetMinterPauser, ContextMixin, NativeMetaTransaction {
    // Contract name
    string public name;

    uint256 private _currentTokenID = 0;
    mapping(uint256 => uint256) public tokenSupply;

    mapping(uint256 => string) internal _tokenURIs;

    mapping(uint256 => address) public creators;

    mapping(bytes32 => bool) private _uniqTitleSet;

    event Create1155Token(address indexed to, uint256 indexed tokenId, uint256 quantity);

    constructor (string memory name_, string memory uri_) ERC1155PresetMinterPauser(uri_) {
        name = name_;
        _initializeEIP712(name);
    }

    /**
    * @dev Creates a new token type and assigns _quantity to an creator (i.e. the message sender)
    * @param _title unique art title
    * @param _quantity art's quantity
    * @param _uri token's type metadata uri
    * @param _data Data to pass if receiver is contract
    * @return The newly created token ID
    */
    function mintItem(
        bytes32 _title,
        uint256 _quantity,
        string calldata _uri,
        bytes calldata _data
    ) external returns (uint) {
        bytes32 hash = keccak256(abi.encodePacked(_title));
        require(!_uniqTitleSet[hash], "NzuriERC1155#mintItem: TITLE_NOT_UNIQUE");
        _uniqTitleSet[hash] = true;

        _currentTokenID += 1;
        uint256 _id = _currentTokenID;

        creators[_id] = msg.sender;

        if (bytes(_uri).length > 0) {
            _tokenURIs[_id] = _uri;
            emit URI(_uri, _id);
        }

        _mint(_msgSender(), _id, _quantity, _data);
        tokenSupply[_id] = _quantity;

        emit Create1155Token(_msgSender(), _id, _quantity);
        return _id;
    }


    /**
      * @dev Returns the total quantity for a token ID
      * @param _id uint256 ID of the token to query
      * @return amount of token in existence
      */
    function totalSupply(
        uint256 _id
    ) public view returns (uint256) {
        return tokenSupply[_id];
    }


    function uri(
        uint256 _id
    ) public override view returns (string memory) {
        require(_exists(_id), "ERC721Tradable#uri: NONEXISTENT_TOKEN");

        string memory _tokenURI = _tokenURIs[_id];

        return _tokenURI;
    }

    /**
      * @dev Returns whether the specified token exists by checking to see if it has a creator
      * @param _id uint256 ID of the token to query the existence of
      * @return bool whether the token exists
      */
    function _exists(
        uint256 _id
    ) internal view returns (bool) {
        return creators[_id] != address(0);
    }


    /**
     * This is used instead of msg.sender as transactions won't be sent by the original token owner, but by OpenSea.
     */
    function _msgSender()
    internal
    override
    view
    returns (address sender)
    {
        return ContextMixin.msgSender();
    }

    /**
    * As another option for supporting trading without requiring meta transactions, override isApprovedForAll to whitelist OpenSea proxy accounts on Matic
    */
    function isApprovedForAll(
        address _owner,
        address _operator
    ) public override view returns (bool isOperator) {
        //        if (_operator == address(0x207Fa8Df3a17D96Ca7EA4f2893fcdCb78a304101)) {
        //            return true;
        //        }
        return ERC1155.isApprovedForAll(_owner, _operator);
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.0;

import "../openzepplin-contracts/token/ERC20/IERC20.sol";
import "../openzepplin-contracts/token/ERC721/IERC721.sol";
import "../openzepplin-contracts/token/ERC1155/IERC1155.sol";
import "../openzepplin-contracts/access/Ownable.sol";
import "../common/FeeCollectable.sol";


contract ExchangeNzuri is Ownable, FeeCollectable {
	struct ERC1155Offer {
		uint tokenId;
		uint quantity;
		uint price;
		address seller;
	}

	event TokenPriceListed (uint indexed _tokenId, address indexed _owner, uint _price);
	event TokenPriceDeleted (uint indexed _tokenId);
	event TokenPriceUnlisted (uint indexed _tokenId);
	event TokenSold (uint indexed _tokenId, uint _price, bool _soldForERC20);
	event TokenOwned (uint indexed _tokenId, address indexed _previousOwner, address indexed _newOwner);
	event TokenBought (uint indexed _tokenId, uint _price, address indexed _previousOwner, address indexed _newOwner, bool _soldForERC20);
	event Token1155OfferListed (uint indexed _tokenId, uint indexed _offerId, address indexed _owner, uint _quantity, uint _price);
	event Token1155OfferDeleted (uint indexed _tokenId, uint indexed _offerId);
	event Token1155PriceUnlisted (uint indexed _tokenId, uint indexed _offerId);
	event Token1155Sold(uint indexed _tokenId, uint indexed _offerId, uint _quantity, uint _price, bool _soldForERC20);
	event Token1155Owned (uint indexed _tokenId, address indexed _previousOwner, address indexed _newOwner, uint _quantity);
	event Token1155Bought (uint _tokenId, uint indexed _offerId, uint _quantity, uint _price, address indexed _previousOwner, address indexed _newOwner, bool _soldForERC20);

	address public signerAddress;

	bytes32 public name = "ExchangeNzuri";

	uint public offerIdCounter;
	uint public safeVolatilityPeriod;

	IERC20 public erc20Contract;
	IERC721 public erc721Contract;
	IERC1155 public erc1155Contract;

	mapping(address => uint) public nonces;
	mapping(uint => uint) public ERC721Prices;
	mapping(uint => ERC1155Offer) public ERC1155Offers;
	mapping(address => mapping(uint => uint)) public tokensListed;

	constructor (
		address _signerAddress,
		address _erc721Address,
		address _erc1155Address,
		address _erc20Address
	)
	{
		require(_signerAddress != address(0));
		require(_erc721Address != address(0));
		require(_erc1155Address != address(0));
		require(_erc20Address != address(0));

		signerAddress = _signerAddress;
		erc721Contract = IERC721(_erc721Address);
		erc1155Contract = IERC1155(_erc1155Address);
		erc20Contract = IERC20(_erc20Address);

    address[] memory _shareholders = new address[](1);
    uint8[] memory _feeRates = new uint8[](1);
    _shareholders[0] = msg.sender;
    _feeRates[0] = 5;
    setShareholders(_shareholders, _feeRates);

		safeVolatilityPeriod = 4 hours;
	}

	function listToken(
		uint _tokenId,
		uint _price
	)
	external
	{
		require(_price > 0);
		require(erc721Contract.ownerOf(_tokenId) == msg.sender);
		require(ERC721Prices[_tokenId] == 0);
		ERC721Prices[_tokenId] = _price;
		emit TokenPriceListed(_tokenId, msg.sender, _price);
	}

	function listToken1155(
		uint _tokenId,
		uint _quantity,
		uint _price
	)
	external
	{
		require(_price > 0);
		require(erc1155Contract.balanceOf(msg.sender, _tokenId) >= tokensListed[msg.sender][_tokenId] + _quantity);

		uint offerId = offerIdCounter++;
		ERC1155Offers[offerId] = ERC1155Offer({
			tokenId: _tokenId,
			quantity: _quantity,
			price: _price,
			seller: msg.sender
		});

		tokensListed[msg.sender][_tokenId] += _quantity;
		emit Token1155OfferListed(_tokenId, offerId, msg.sender, _quantity, _price);
	}

	function removeListToken(
		uint _tokenId
	)
	external
	{
		require(erc721Contract.ownerOf(_tokenId) == msg.sender);
		deleteTokenPrice(_tokenId);

		emit TokenPriceUnlisted(_tokenId);
	}

	function removeListToken1155(
		uint _offerId
	)
	external
	{
		require(ERC1155Offers[_offerId].seller == msg.sender);
		ERC1155Offer memory offer = ERC1155Offers[_offerId];
		deleteToken1155Offer(_offerId);

		emit Token1155PriceUnlisted(offer.tokenId, _offerId);
	}

	function deleteTokenPrice(
		uint _tokenId
	)
	internal
	{
		delete ERC721Prices[_tokenId];
		emit TokenPriceDeleted(_tokenId);
	}

	function deleteToken1155Offer(
		uint _offerId
	)
	internal
	{
		ERC1155Offer memory offer = ERC1155Offers[_offerId];
		tokensListed[offer.seller][offer.tokenId] -= offer.quantity;

		delete ERC1155Offers[_offerId];
		emit Token1155OfferDeleted(offer.tokenId, _offerId);
	}

	function buyToken(uint _tokenId) external {
    require(ERC721Prices[_tokenId] > 0, "token is not for sale");
    address tokenOwner = erc721Contract.ownerOf(_tokenId);

    if (totalFeeRate == 0) {
      require(
        erc20Contract.transferFrom(msg.sender, tokenOwner, ERC721Prices[_tokenId]),
        "ExchangeNzuri: couldn't transfer erc20 to buyer"
      );
    } else if (totalFeeRate == 100) {
        depositFeeToken(address(erc20Contract), msg.sender, ERC721Prices[_tokenId]);
    } else {
      uint256 feeAmount = ERC721Prices[_tokenId] / 100 * totalFeeRate;
      depositFeeToken(address(erc20Contract), msg.sender, feeAmount);
      require(
        erc20Contract.transferFrom(msg.sender, tokenOwner, ERC721Prices[_tokenId] - feeAmount),
        "ExchangeNzuri: couldn't transfer erc20 to buyer"
      );
    }

    erc721Contract.safeTransferFrom(tokenOwner, msg.sender, _tokenId);

    emit TokenSold(_tokenId, ERC721Prices[_tokenId], false);
    emit TokenOwned(_tokenId, tokenOwner, msg.sender);
    emit TokenBought(_tokenId, ERC721Prices[_tokenId], tokenOwner, msg.sender, false);

    deleteTokenPrice(_tokenId);
	}

	function buyToken1155(
		uint _offerId,
		uint _quantity
	)
	external
	{
		ERC1155Offer memory offer = ERC1155Offers[_offerId];

		require(offer.price > 0, "offer does not exist");
		require(offer.quantity >= _quantity);

    bool sent = erc20Contract.transferFrom(msg.sender, offer.seller, offer.price * _quantity);
    require(sent);

		erc1155Contract.safeTransferFrom(offer.seller, msg.sender, offer.tokenId, _quantity, "");

		emit Token1155Sold(offer.tokenId, _offerId, _quantity, offer.price, false);
		emit Token1155Owned(offer.tokenId, offer.seller, msg.sender, _quantity);

		emit Token1155Bought(offer.tokenId, _offerId, _quantity, offer.price, offer.seller, msg.sender, false);

		if (offer.quantity == _quantity) {
			deleteToken1155Offer(_offerId);
		} else {
			ERC1155Offers[_offerId].quantity -= _quantity;
		}
	}

	function buyTokenForERC20(
		uint _tokenId,
		uint _priceInERC20,
		uint _nonce,
		bytes calldata _signature,
		uint _timestamp
	)
	external
	{
		bytes32 hash = keccak256(abi.encodePacked(_tokenId, _priceInERC20, _nonce, _timestamp));
		bytes32 ethSignedMessageHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
		require(recoverSignerAddress(ethSignedMessageHash, _signature) == signerAddress, "invalid secret signer");

		require(nonces[msg.sender] < _nonce, "invalid nonce");
		if (safeVolatilityPeriod > 0) {
			require(_timestamp + safeVolatilityPeriod >= block.timestamp, "safe volatility period exceeded");
		}
		require(ERC721Prices[_tokenId] > 0, "token is not for sale");

		nonces[msg.sender] = _nonce;

		address tokenOwner = erc721Contract.ownerOf(_tokenId);

		bool sent = erc20Contract.transferFrom(msg.sender, tokenOwner, _priceInERC20);
		require(sent);

		erc721Contract.safeTransferFrom(tokenOwner, msg.sender, _tokenId);

		emit TokenSold(_tokenId, _priceInERC20, true);
		emit TokenOwned(_tokenId, tokenOwner, msg.sender);

		deleteTokenPrice(_tokenId);
	}

	function buyToken1155ForERC20(
		uint _offerId,
		uint _quantity,
		uint _priceInERC20,
		uint _nonce,
		bytes calldata _signature,
		uint _timestamp
	)
	external
	{
		bytes32 hash = keccak256(abi.encodePacked(_offerId, _quantity, _priceInERC20, _nonce, _timestamp));
		bytes32 ethSignedMessageHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
		require(recoverSignerAddress(ethSignedMessageHash, _signature) == signerAddress, "invalid secret signer");

		ERC1155Offer memory offer = ERC1155Offers[_offerId];

		require(nonces[msg.sender] < _nonce, "invalid nonce");
		if (safeVolatilityPeriod > 0) {
			require(_timestamp + safeVolatilityPeriod >= block.timestamp, "safe volatility period exceeded");
		}
		require(offer.price > 0, "offer does not exist");
		require(offer.quantity >= _quantity);

		nonces[msg.sender] = _nonce;

		erc20Contract.transferFrom(msg.sender, offer.seller, _priceInERC20 * _quantity);
		erc1155Contract.safeTransferFrom(offer.seller, msg.sender, offer.tokenId, _quantity, "");

		emit Token1155Sold(offer.tokenId, _offerId, _quantity, _priceInERC20, true);
		emit Token1155Owned(offer.tokenId, offer.seller, msg.sender, _quantity);

		if (offer.quantity == _quantity) {
			deleteToken1155Offer(_offerId);
		} else {
			ERC1155Offers[_offerId].quantity -= _quantity;
		}
	}

	function setSigner(
		address _newSignerAddress
	)
	external onlyOwner
	{
		signerAddress = _newSignerAddress;
	}

	function setSafeVolatilityPeriod(
		uint _newSafeVolatilityPeriod
	)
	external onlyOwner
	{
		safeVolatilityPeriod = _newSafeVolatilityPeriod;
	}

	function recoverSignerAddress(
		bytes32 _hash,
		bytes memory _signature
	)
	internal
	pure
	returns (address)
	{
		require(_signature.length == 65, "invalid signature length");

		bytes32 r;
		bytes32 s;
		uint8 v;

		assembly {
			r := mload(add(_signature, 32))
			s := mload(add(_signature, 64))
			v := and(mload(add(_signature, 65)), 255)
		}

		if (v < 27) {
			v += 27;
		}

		if (v != 27 && v != 28) {
			return address(0);
		}

		return ecrecover(_hash, v, r, s);
	}
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../openzepplin-contracts/access/Ownable.sol";
import "../openzepplin-contracts/token/ERC20/IERC20.sol";
import "../openzepplin-contracts/token/ERC1155/IERC1155.sol";
import "../openzepplin-contracts/token/ERC721/IERC721.sol";
import "../openzepplin-contracts/utils/structs/EnumerableSet.sol";
import "../openzepplin-contracts/token/ERC721/IERC721Receiver.sol";
import "../openzepplin-contracts/token/ERC1155/IERC1155Receiver.sol";
import "../common/FeeCollectable.sol";

contract AuctionFactoryNzuri is Ownable, FeeCollectable, IERC721Receiver, IERC1155Receiver {
  using EnumerableSet for EnumerableSet.AddressSet;

  struct AuctionParameters {
    uint startingBid;
    uint bidStep;
    uint startTimestamp;
    uint endTimestamp;
    uint overtimeSeconds;
    uint feeRate;
    address owner;
  }

  struct AuctionState {
    address controller;
    address beneficiary;
    address highestBidder;
    uint tokenId;
    uint quantity;
    uint highestBid;
    bool cancelled;
    bool itemClaimed;
    bool controllerClaimedFunds;
    bool beneficiaryClaimedFunds;
    bool acceptERC20;
    bool isErc1155;
  }

  bytes32 public name = "AuctionFactoryNzuri";
  address controller;
  IERC20 public erc20NzuriContract;
  IERC721 public erc721NzuriContract;
  IERC1155 public erc1155NzuriContract;
  mapping(address => AuctionParameters) public auctionParameters;
  mapping(address => AuctionState) public auctionState;
  EnumerableSet.AddressSet private auctionsFeePending;
  // Set for temporary data for fee withdraw, so memory array would not be needed
  EnumerableSet.AddressSet private auctionsFeeResolved;

  // auctionAddress => bidder => funds
  mapping(address => mapping(address => uint256)) public fundsByBidder;

  event AuctionCreated(address indexed auctionContract, address indexed beneficiary, uint indexed tokenId);
  event BidPlaced (address indexed bidder, uint bid, address indexed auctionContract);
  event FundsClaimed (address indexed claimer, address withdrawalAccount, uint withdrawalAmount, address indexed auctionContract);
  event ItemClaimed (address indexed claimer, address indexed auctionContract);
  event AuctionCancelled (address indexed auctionContract);

  constructor(address _erc20NzuriAddress, address _erc721NzuriContract, address _erc1155NzuriContract, address _controller) {
    require(_controller != address(0), "AuctionFactoryNzuri: controller address can't be empty");

    erc20NzuriContract = IERC20(_erc20NzuriAddress);
    erc721NzuriContract = IERC721(_erc721NzuriContract);
    erc1155NzuriContract = IERC1155(_erc1155NzuriContract);
    controller = _controller;

    address[] memory _shareholders = new address[](1);
    uint8[] memory _feeRates = new uint8[](1);
    _shareholders[0] = msg.sender;
    _feeRates[0] = 5;
    setShareholders(_shareholders, _feeRates);
  }

  function createAuction(
    uint tokenId,
    uint bidStep,
    uint startingBid,
    uint startTimestamp,
    uint endTimestamp,
    bool acceptERC20,
    bool isErc1155,
    uint quantity,
    uint overtimeSeconds
  ) external {
    require(bidStep > 0, "AuctionFactoryNzuri: bid step must be more than zero");
    require(startingBid >= 0, "AuctionFactoryNzuri: starting bid must be more than zero");
    require(startTimestamp < endTimestamp, "AuctionFactoryNzuri: start timestamp must be less than end timestamp");
    require(startTimestamp >= block.timestamp, "AuctionFactoryNzuri: start timestamp must be in future time");
    if (isErc1155) {
      require(quantity > 0, "AuctionFactoryNzuri: erc1155 quantity must be more than 0");
    }

    address auctionAddress = address(
      uint160(uint(keccak256(abi.encodePacked(block.difficulty, blockhash(block.number - 1)))))
    );
    auctionParameters[auctionAddress] = AuctionParameters(
      startingBid,
      bidStep,
      startTimestamp,
      endTimestamp,
      overtimeSeconds,
      totalFeeRate,
      msg.sender
    );

    auctionState[auctionAddress] = AuctionState(
      controller,
      msg.sender,
      address(0),
      tokenId,
      quantity,
      0,
      false,
      false,
      false,
      false,
      acceptERC20,
      isErc1155
    );

    if (isErc1155) {
      erc1155NzuriContract.safeTransferFrom(msg.sender, address(this), tokenId, quantity, "");
    } else {
      erc721NzuriContract.safeTransferFrom(msg.sender, address(this), tokenId);
    }

    auctionsFeePending.add(auctionAddress);
    emit AuctionCreated(auctionAddress, msg.sender, tokenId);
  }

  function placeBid(address auctionAddress) payable external {
    AuctionState storage state = auctionState[auctionAddress];
    AuctionParameters memory parameters = auctionParameters[auctionAddress];

    require(block.timestamp >= parameters.startTimestamp, "AuctionFactoryNzuri: auction has not started yet");
    require(block.timestamp < parameters.endTimestamp, "AuctionFactoryNzuri: auction has ended");
    require(!state.cancelled, "AuctionFactoryNzuri: auction was cancelled");
    require(!state.acceptERC20, "AuctionFactoryNzuri: auction doesn't support erc20 tokens");
    require(msg.sender != state.controller, "AuctionFactoryNzuri: controller can't bid on own auction");
    require(msg.sender != state.beneficiary, "AuctionFactoryNzuri: beneficiary can't bid on own auction");
    require(msg.value > 0, "AuctionFactoryNzuri: bid must be more than zero");

    // calculate the user's total bid
    uint totalBid = fundsByBidder[auctionAddress][msg.sender] + msg.value;

    if (state.highestBid == 0) {
      // reject if user did not overbid
      require(totalBid >= parameters.startingBid, "AuctionFactoryNzuri: bid must be more or equal than starting bid");
    } else {
      // reject if user did not overbid
      require(totalBid >= state.highestBid + parameters.bidStep, "AuctionFactoryNzuri: bid must overbid bid step");
    }

    _placeBid(auctionAddress, msg.sender, totalBid);

    // if bid was placed within specified number of blocks before the auction's end
    // extend auction time
    if (parameters.overtimeSeconds > parameters.endTimestamp - block.timestamp) {
      auctionParameters[auctionAddress].endTimestamp += parameters.overtimeSeconds;
    }

    emit BidPlaced(msg.sender, totalBid, auctionAddress);
  }

  function placeBidERC20(address auctionAddress, uint amount) external {
    AuctionState storage state = auctionState[auctionAddress];
    AuctionParameters memory parameters = auctionParameters[auctionAddress];

    require(block.timestamp >= parameters.startTimestamp, "AuctionFactoryNzuri: auction has not started yet");
    require(block.timestamp < parameters.endTimestamp, "AuctionFactoryNzuri: auction has ended");
    require(!state.cancelled, "AuctionFactoryNzuri: auction was cancelled");
    require(state.acceptERC20, "AuctionFactoryNzuri: auction accepts only erc20 tokens");
    require(msg.sender != state.controller, "AuctionFactoryNzuri: controller can't bid on own auction");
    require(msg.sender != state.beneficiary, "AuctionFactoryNzuri: beneficiary can't bid on own auction");
    require(amount > 0, "AuctionFactoryNzuri: bid must be more than zero");

    // calculate the user's total bid
    uint totalBid = fundsByBidder[auctionAddress][msg.sender] + amount;

    if (state.highestBid == 0) {
      // reject if user did not overbid
      require(totalBid >= parameters.startingBid, "AuctionFactoryNzuri: bid must be more or equal than starting bid");
    } else {
      // reject if user did not overbid
      require(totalBid >= state.highestBid + parameters.bidStep, "AuctionFactoryNzuri: bid must overbid bid step");
    }

    require(
      erc20NzuriContract.transferFrom(msg.sender, address(this), amount),
      "AuctionFactoryNzuri: couldn't transfer erc20 bid"
    );
    _placeBid(auctionAddress, msg.sender, totalBid);

    // if bid was placed within specified number of blocks before the auction's end
    // extend auction time
    if (parameters.overtimeSeconds > parameters.endTimestamp - block.timestamp) {
      auctionParameters[auctionAddress].endTimestamp += parameters.overtimeSeconds;
    }

    emit BidPlaced(msg.sender, totalBid, auctionAddress);
  }

  function claimFunds(address auctionAddress) external {
    AuctionState storage state = auctionState[auctionAddress];
    AuctionParameters memory parameters = auctionParameters[auctionAddress];

    require(
      state.cancelled || block.timestamp >= parameters.endTimestamp,
      "AuctionFactoryNzuri: auction is still in progress"
    );

    address withdrawalAccount;
    uint withdrawalAmount;
    bool controllerClaimedFunds;

    if (state.cancelled) {
      // if the auction was cancelled, everyone should be allowed to withdraw their funds
      withdrawalAccount = msg.sender;
      withdrawalAmount = fundsByBidder[auctionAddress][withdrawalAccount];
    } else {
      // the auction finished without being cancelled

      // reject when auction winner claims funds
      require(msg.sender != state.highestBidder, "AuctionFactoryNzuri: auction winner can't withdraw his bid");

      // everyone except auction winner should be allowed to withdraw their funds
      if (msg.sender == state.beneficiary) {
        require(
          parameters.feeRate < 100 && !state.beneficiaryClaimedFunds,
          "AuctionFactoryNzuri: beneficiary already claimed his funds"
        );
        withdrawalAccount = state.highestBidder;
        withdrawalAmount = state.highestBid / 100 * (100 - parameters.feeRate);
        auctionState[auctionAddress].beneficiaryClaimedFunds = true;
      } else if (msg.sender == state.controller) {
        require(
          parameters.feeRate > 0 && !state.controllerClaimedFunds,
          "AuctionFactoryNzuri: controller already claimed his funds"
        );
        withdrawalAccount = state.highestBidder;
        withdrawalAmount = state.highestBid / 100 * parameters.feeRate;
        controllerClaimedFunds = true;
      } else {
        withdrawalAccount = msg.sender;
        withdrawalAmount = fundsByBidder[auctionAddress][withdrawalAccount];
      }
    }

    // reject when there are no funds to claim
    require(withdrawalAmount != 0, "AuctionFactoryNzuri: no funds to withdraw");
    if (controllerClaimedFunds) {
      auctionState[auctionAddress].controllerClaimedFunds = true;
      _withdrawFunds(auctionAddress, address(this), withdrawalAccount, withdrawalAmount);
      if (parameters.feeRate > 0) {
        depositFeeToken(address(erc20NzuriContract), address(this), withdrawalAmount);
      }
    } else {
      _withdrawFunds(auctionAddress, msg.sender, withdrawalAccount, withdrawalAmount);
    }

    emit FundsClaimed(msg.sender, withdrawalAccount, withdrawalAmount, auctionAddress);
  }

  function claimItem(address auctionAddress) external {
    AuctionState storage state = auctionState[auctionAddress];
    AuctionParameters memory parameters = auctionParameters[auctionAddress];

    require(!state.itemClaimed, "AuctionFactoryNzuri: item was already claimed");
    require(
      state.cancelled || block.timestamp >= parameters.endTimestamp,
      "AuctionFactoryNzuri: auction is still in progress"
    );

    if (state.cancelled
      || (state.highestBidder == address(0) && block.timestamp >= parameters.endTimestamp)) {
      require(
        msg.sender == state.beneficiary,
        "AuctionFactoryNzuri: non-beneficiary can't claim item from auction without winner"
      );
    } else {
      require(msg.sender == state.highestBidder, "AuctionFactoryNzuri: only auction winner can claim item");
    }

    _transferItem(auctionAddress, msg.sender);

    emit ItemClaimed(msg.sender, auctionAddress);
  }

  function cancelAuction(address auctionAddress) external {
    AuctionState storage state = auctionState[auctionAddress];
    AuctionParameters memory parameters = auctionParameters[auctionAddress];

    require(msg.sender == parameters.owner, "AuctionFactoryNzuri: only creator can cancel auction");
    require(!state.cancelled, "AuctionFactoryNzuri: auction already cancelled");
    require(block.timestamp < parameters.endTimestamp, "AuctionFactoryNzuri: auction has ended");

    state.cancelled = true;
    auctionsFeePending.remove(auctionAddress);
    emit AuctionCancelled(auctionAddress);
  }

  function setController(address _controller) onlyOwner external {
    require(_controller != address(0), "AuctionFactoryNzuri: controller address can't be empty");
    controller = _controller;
  }

  function _placeBid(address auctionAddress, address bidder, uint totalAmount) private {
    AuctionState storage state = auctionState[auctionAddress];
    fundsByBidder[auctionAddress][bidder] = totalAmount;

    if (bidder != state.highestBidder) {
      state.highestBidder = bidder;
    }

    state.highestBid = totalAmount;
  }

  function _withdrawFunds(
    address auctionAddress,
    address claimer,
    address withdrawalAccount,
    uint withdrawalAmount
  ) private {
    AuctionState storage state = auctionState[auctionAddress];
    fundsByBidder[auctionAddress][withdrawalAccount] -= withdrawalAmount;
    // send the funds
    if (state.acceptERC20) {
      require(erc20NzuriContract.transfer(claimer, withdrawalAmount), "AuctionFactoryNzuri: couldn't withdraw erc20 funds");
    } else {
      (bool sent, ) = claimer.call{value: withdrawalAmount}("");
      require(sent, "AuctionFactoryNzuri: couldn't withdraw eth funds");
    }
  }

  function _transferItem(address auctionAddress, address claimer) private {
    AuctionState storage state = auctionState[auctionAddress];
    if (state.isErc1155) {
      erc1155NzuriContract.safeTransferFrom(address(this), claimer, state.tokenId, state.quantity, "");
    } else {
      erc721NzuriContract.safeTransferFrom(address(this), claimer, state.tokenId);
    }

    state.itemClaimed = true;
  }

  function availableFeeToken(address erc20, address shareholder) override public view returns(uint) {
    uint256 auctionsFeePendingTotal = auctionsFeePending.length();
    uint256 pendingFeeTotal = 0;
    for (uint256 i = 0; i < auctionsFeePendingTotal; i++) {
      address auctionAddress = auctionsFeePending.at(i);
      AuctionState storage state = auctionState[auctionAddress];

      if (state.controllerClaimedFunds) {
        continue;
      }

      bool isAuctionInProgress = block.timestamp < auctionParameters[auctionAddress].endTimestamp;
      if (isAuctionInProgress) {
        continue;
      }

      address highestBidder = state.highestBidder;
      if (highestBidder == address(0)) {
        continue;
      }

      uint256 feeAmount = state.highestBid / 100 * auctionParameters[auctionAddress].feeRate;
      pendingFeeTotal += feeAmount / totalFeeRate * feeRates[shareholder];
    }
    return super.availableFeeToken(erc20, shareholder) + pendingFeeTotal;
  }

  function withdrawAllFeeToken(address erc20) override virtual public {
    _collectFeeTokenFromPendingAuctions();
    super.withdrawAllFeeToken(erc20);
  }

  function _collectFeeTokenFromPendingAuctions() private {
    uint256 auctionsFeePendingTotal = auctionsFeePending.length();
    for (uint256 i = 0; i < auctionsFeePendingTotal; i++) {
      address auctionAddress = auctionsFeePending.at(i);
      AuctionState storage state = auctionState[auctionAddress];

      if (state.controllerClaimedFunds) {
        continue;
      }

      bool isAuctionInProgress = block.timestamp < auctionParameters[auctionAddress].endTimestamp;
      if (isAuctionInProgress) {
        continue;
      }

      address highestBidder = state.highestBidder;
      if (highestBidder == address(0)) {
        auctionsFeeResolved.add(auctionAddress);
        continue;
      }

      uint256 feeAmount = state.highestBid / 100 * auctionParameters[auctionAddress].feeRate;
      _withdrawFunds(auctionAddress, address(this), highestBidder, feeAmount);
      auctionState[auctionAddress].controllerClaimedFunds = true;
      depositFeeToken(address(erc20NzuriContract), address(this), feeAmount);
      auctionsFeeResolved.add(auctionAddress);
    }
    for (uint256 i = 0; i < auctionsFeeResolved.length(); i++) {
      auctionsFeePending.remove(auctionsFeeResolved.at(i));
    }
  }

  function onERC721Received(
    address, address, uint256, bytes calldata
  ) external pure override returns(bytes4) {
    return this.onERC721Received.selector;
  }

  function onERC1155Received(
    address, address, uint256, uint256, bytes calldata
  ) external pure override returns(bytes4) {
    return this.onERC1155Received.selector;
  }

  function onERC1155BatchReceived(
    address, address, uint256[] calldata, uint256[] calldata, bytes calldata
  ) external pure override returns(bytes4) {
    return this.onERC1155BatchReceived.selector;
  }

  /**
 * @dev See {IERC165-supportsInterface}.
 */
  function supportsInterface(bytes4 interfaceId) public view virtual override returns(bool) {
    return interfaceId == type(IERC721Receiver).interfaceId
    || interfaceId == type(IERC1155Receiver).interfaceId;
  }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "../openzepplin-contracts/security/ReentrancyGuard.sol";
import "../openzepplin-contracts/access/Ownable.sol";
import "../openzepplin-contracts/token/ERC721/presets/ERC721PresetMinterPauserAutoId.sol";
import "../common/FeeCollectable.sol";

/**
 * @notice DropMinting contract for Nzuri NFT Marketplace
 */
contract DropMinting is ReentrancyGuard, Ownable, FeeCollectable {
  /// @notice ERC721 NFT
  ERC721PresetMinterPauserAutoId public token;
  address public erc20Address;

  event DropMintingContractDeployed(uint _dropStart, uint _dropEnd);
  event DropMintingFinished(address _to, uint _tokenId, uint _amount);
  event StopDropMinting(uint _dropEnd);

  /// @notice Each wallet can mint up to 100 max
  uint16 public mintLimitAccount = 20;

  /// @notice Limitation of NFT can be minted while dropping
  uint256 public mintLimitTotal;

  /// @notice NFT price ETH
  uint256 public price;

  /// @notice Timestamp of opening drop
  uint256 public dropStart;

  /// @notice Timestamp of ending drop
  uint256 public dropEnd;

  /// @notice Count of NFT minted until now while dropping
  uint256 public count;

  /// @notice token IDs per owner
  mapping (address => uint[]) public tokenIDs;

  /**
   * @dev Constructor Function
  */
  constructor(
    address _erc721Address,
    address _erc20Address,
    uint256 _dropStart,
    uint256 _dropEnd,
    uint256 _price,
    uint256 _mintLimitTotal
  ) {
    require (_erc721Address != address(0), "DropMinting: Invalid erc721Address");
    require(address(_erc20Address) != address(0), "DropMinting: Invalid erc20 address");

    token = ERC721PresetMinterPauserAutoId(_erc721Address);
    erc20Address = _erc20Address;
    dropStart = _dropStart;
    dropEnd = _dropEnd;
    price = _price;
    mintLimitTotal = _mintLimitTotal;

    emit DropMintingContractDeployed(dropStart, dropEnd);
  }

  /**
   * @dev Owner of token can airdrop tokens to recipients
   * @param mintQuantity Quantity of mints
   * @return _tokenIds Token ID's minted
   */
  function dropMint(uint256 mintQuantity) external nonReentrant returns(uint256[] memory) {
    require(mintQuantity > 0, "DropMinting: Mint quantity should be more than zero");
    require(count < mintLimitTotal, "DropMinting: Drop minting has already ended");
    require(count + mintQuantity <= mintLimitTotal, "DropMinting: All NFTs are minted");
    require(tokenIDs[msg.sender].length + mintQuantity <= mintLimitAccount, "DropMinting: Exceeds account minting limitation");

    uint256[] memory _tokenIds = new uint256[](mintQuantity);
    for (uint256 i = 0; i < mintQuantity; i++) {
      uint256 tokenId = token.mint(msg.sender);
      tokenIDs[msg.sender].push(tokenId);
      _tokenIds[i] = tokenId;
      count++;
      if (count == mintLimitTotal) {
        dropEnd = block.timestamp;
        emit StopDropMinting(dropEnd);
      }

      emit DropMintingFinished(msg.sender, tokenId, price);
    }
    depositFeeToken(erc20Address, msg.sender, price * mintQuantity / 100 * totalFeeRate);
    return _tokenIds;
  }

  /**
   * @dev Owner end DropMinting
   */
  function endDrop() external onlyOwner {
    require(block.timestamp >= dropStart,"DropMinting: Drop minting is not started");
    dropEnd = block.timestamp;
    emit StopDropMinting(dropEnd);
  }

  /**
   * @dev Owner update account minting limit
   * @param _limit limit of account minting count
   */
  function updateMintLimitAccount(uint16 _limit) external onlyOwner {
    mintLimitAccount = _limit;
  }

  /**
   * @dev Owner update total minting limit
   * @param _limit limit of total minting count
   */
  function updateMintLimitTotal(uint16 _limit) external onlyOwner {
    mintLimitTotal = _limit;
  }

  /**
   * @dev Owner update drop opening time
   * @param _time timestamp of drop opening time
   */
  function updateDropStart(uint256 _time) external onlyOwner {
    dropStart = _time;
  }

  /**
   * @dev Owner update drop ending time
   * @param _time timestamp of drop ending time
   */
  function updateDropEnd(uint256 _time) external onlyOwner {
    dropEnd = _time;
  }

  /**
   * @dev Owner update NFT price
   * @param _price NFT price
   */
  function updatePrice(uint256 _price) external onlyOwner {
    price = _price;
  }

  function getBalance() public view returns(uint) {
    return address(this).balance;
  }

  /**
   * @dev Owner withdraw all money
   */
  function withdrawMoney() external onlyOwner {
    address payable to = payable(msg.sender);
    to.transfer(getBalance());
  }

  function getAvailableMintCnt(address user) external view returns(uint){
    return mintLimitAccount - tokenIDs[user].length;
  }

  function addTokenId(address tokenOwner, uint tokenId) external onlyOwner {
    tokenIDs[tokenOwner].push(tokenId);
  }

  function setTokenId(address tokenOwner, uint tokenId, uint index) external onlyOwner {
    tokenIDs[tokenOwner][index] = tokenId;
  }

  function deleteTokenIds(address tokenOwner) external onlyOwner {
    delete tokenIDs[tokenOwner];
  }

  function setCount(uint _count) external onlyOwner {
    count = _count;
  }

  function setShareholders(address[] memory shareholders, uint8[] memory feeRates) override public {
    uint16 feeRatesSum = 0;
    for (uint i = 0; i < feeRates.length; i++) {
      feeRatesSum += feeRates[i];
    }
    require(feeRatesSum == 100, "DropMinting: sum of fee rates must equal 100");
    super.setShareholders(shareholders, feeRates);
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IERC721NzuriCreator {
    function createContract(
        string memory name,
        string memory symbol,
        string memory baseURI
    ) external returns(address contractAddress);
}

interface IERC1155NzuriCreator {
    function createContract(
        string memory name,
        string memory baseURI
    ) external returns(address contractAddress);
}

interface IExchangeNzuriCreator {
    function createContract(
        address owner,
        address erc20Address,
        address erc721Address,
        address erc1155Address
    ) external returns(address contractAddress);
}

interface IAuctionFactoryNzuriCreator {
    function createContract(
        address owner,
        address erc20Address,
        address erc721Address,
        address erc1155Address
    ) external returns(address contractAddress);
}

interface IDropMintingCreator {
    function createContract(
        address erc20Address,
        address erc721Address,
        uint256 dropStart,
        uint256 dropEnd,
        uint256 dropPrice,
        uint256 dropMintLimitTotal
    ) external returns(address contractAddress);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "../extensions/ERC721Enumerable.sol";
import "../extensions/ERC721Burnable.sol";
import "../extensions/ERC721Pausable.sol";
import "../../../access/AccessControlEnumerable.sol";
import "../../../utils/Context.sol";
import "../../../utils/Counters.sol";
import "../extensions/ERC721URIStorage.sol";

/**
 * @dev {ERC721} token, including:
 *
 *  - ability for holders to burn (destroy) their tokens
 *  - a minter role that allows for token minting (creation)
 *  - a pauser role that allows to stop all token transfers
 *  - token ID and URI autogeneration
 *
 * This contract uses {AccessControl} to lock permissioned functions using the
 * different roles - head to its documentation for details.
 *
 * The account that deploys the contract will be granted the minter and pauser
 * roles, as well as the default admin role, which will let it grant both minter
 * and pauser roles to other accounts.
 */
contract ERC721PresetMinterPauserAutoId is Context, AccessControlEnumerable, ERC721Enumerable, ERC721Burnable, ERC721Pausable {
    using Counters for Counters.Counter;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    Counters.Counter private _tokenIdTracker;

    string private _baseTokenURI;

    /**
     * @dev Grants `DEFAULT_ADMIN_ROLE`, `MINTER_ROLE` and `PAUSER_ROLE` to the
     * account that deploys the contract.
     *
     * Token URIs will be autogenerated based on `baseURI` and their token IDs.
     * See {ERC721-tokenURI}.
     */
    constructor(string memory name, string memory symbol, string memory baseTokenURI) ERC721(name, symbol) {
        _baseTokenURI = baseTokenURI;
        _tokenIdTracker.increment();

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        _setupRole(MINTER_ROLE, _msgSender());
        _setupRole(PAUSER_ROLE, _msgSender());
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function contractURI() public view returns (string memory) {
        return _baseURI();
    }

    /**
     * @dev Creates a new token for `to`. Its token ID will be automatically
     * assigned (and available on the emitted {IERC721-Transfer} event), and the token
     * URI autogenerated based on the base URI passed at construction.
     *
     * See {ERC721-_mint}.
     *
     * Requirements:
     *
     * - the caller must have the `MINTER_ROLE`.
     */
    function mint(address to) public virtual returns (uint256 tokenId) {
        require(hasRole(MINTER_ROLE, _msgSender()), "ERC721PresetMinterPauserAutoId: must have minter role to mint");

        // We cannot just use balanceOf to create the new tokenId because tokens
        // can be burned (destroyed), so we need a separate counter.
        tokenId = _tokenIdTracker.current();
        _mint(to, tokenId);
        _tokenIdTracker.increment();
    }

    /**
     * @dev Pauses all token transfers.
     *
     * See {ERC721Pausable} and {Pausable-_pause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function pause() public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), "ERC721PresetMinterPauserAutoId: must have pauser role to pause");
        _pause();
    }

    /**
     * @dev Unpauses all token transfers.
     *
     * See {ERC721Pausable} and {Pausable-_unpause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function unpause() public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), "ERC721PresetMinterPauserAutoId: must have pauser role to unpause");
        _unpause();
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override(ERC721, ERC721Enumerable, ERC721Pausable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControlEnumerable, ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
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
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

abstract contract ContextMixin {
  function msgSender()
  internal
  view
  returns (address sender)
  {
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
      sender = msg.sender;
    }
    return sender;
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./EIP712Base.sol";
import "../openzepplin-contracts/utils/math/SafeMath.sol";

/**
 * https://github.com/maticnetwork/pos-portal/blob/master/contracts/common/NativeMetaTransaction.sol
 */
contract NativeMetaTransaction is EIP712Base {
    using SafeMath for uint256;
    bytes32 private constant META_TRANSACTION_TYPEHASH = keccak256(
        bytes(
            "MetaTransaction(uint256 nonce,address from,bytes functionSignature)"
        )
    );

    event MetaTransactionExecuted(
        address userAddress,
        address relayerAddress,
        bytes functionSignature
    );

    mapping(address => uint256) nonces;

    /*
     * Meta transaction structure.
     * No point of including value field here as if user is doing value transfer then he has the funds to pay for gas
     * He should call the desired function directly in that case.
     */
    struct MetaTransaction {
        uint256 nonce;
        address from;
        bytes functionSignature;
    }

    function executeMetaTransaction(
        address userAddress,
        bytes memory functionSignature,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) public payable returns (bytes memory) {
        MetaTransaction memory metaTx = MetaTransaction({
        nonce : nonces[userAddress],
        from : userAddress,
        functionSignature : functionSignature
        });
        require(
            verify(userAddress, metaTx, sigR, sigS, sigV),
            "Signer and signature do not match"
        );

        // increase nonce for user (to avoid re-use)
        nonces[userAddress] = nonces[userAddress].add(1);

        emit MetaTransactionExecuted(
            userAddress,
            msg.sender,
            functionSignature
        );

        // Append userAddress and relayer address at the end to extract it from calling context
        (bool success, bytes memory returnData) = address(this).call(
            abi.encodePacked(functionSignature, userAddress)
        );
        require(success, "Function call not successful");

        return returnData;
    }

    function hashMetaTransaction(MetaTransaction memory metaTx)
    internal
    pure
    returns (bytes32)
    {
        return
        keccak256(
            abi.encode(
                META_TRANSACTION_TYPEHASH,
                metaTx.nonce,
                metaTx.from,
                keccak256(metaTx.functionSignature)
            )
        );
    }

    function getNonce(address user) public view returns (uint256 nonce) {
        nonce = nonces[user];
    }

    function verify(
        address signer,
        MetaTransaction memory metaTx,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) internal view returns (bool) {
        require(signer != address(0), "NativeMetaTransaction: INVALID_SIGNER");
        return
        signer ==
        ecrecover(
            toTypedMessageHash(hashMetaTransaction(metaTx)),
            sigV,
            sigR,
            sigS
        );
    }
}

// SPDX-License-Identifier: MIT

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
    mapping (uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping (address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping (uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping (address => mapping (address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC721).interfaceId
            || interfaceId == type(IERC721Metadata).interfaceId
            || super.supportsInterface(interfaceId);
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
        return bytes(baseURI).length > 0
            ? string(abi.encodePacked(baseURI, tokenId.toString()))
            : '';
    }

    /**
     * @dev Base URI for computing {tokenURI}. Empty by default, can be overriden
     * in child contracts.
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

        require(_msgSender() == owner || isApprovedForAll(owner, _msgSender()),
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
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
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
    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
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
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal virtual {
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
    function _safeMint(address to, uint256 tokenId, bytes memory _data) internal virtual {
        _mint(to, tokenId);
        require(_checkOnERC721Received(address(0), to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
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
    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
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
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data)
        private returns (bool)
    {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver(to).onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    // solhint-disable-next-line no-inline-assembly
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
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual { }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "./IERC721Enumerable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId
            || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
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
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "../../../utils/Context.sol";

/**
 * @title ERC721 Burnable Token
 * @dev ERC721 Token that can be irreversibly burned (destroyed).
 */
abstract contract ERC721Burnable is Context, ERC721 {
    /**
     * @dev Burns `tokenId`. See {ERC721-_burn}.
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator.
     */
    function burn(uint256 tokenId) public virtual {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721Burnable: caller is not owner nor approved");
        _burn(tokenId);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "../../../security/Pausable.sol";

/**
 * @dev ERC721 token with pausable token transfers, minting and burning.
 *
 * Useful for scenarios such as preventing trades until the end of an evaluation
 * period, or having an emergency switch for freezing all token transfers in the
 * event of a large bug.
 */
abstract contract ERC721Pausable is ERC721, Pausable {
    /**
     * @dev See {ERC721-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        require(!paused(), "ERC721Pausable: token transfer while paused");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./AccessControl.sol";
import "../utils/structs/EnumerableSet.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerable {
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}

/**
 * @dev Extension of {AccessControl} that allows enumerating the members of each role.
 */
abstract contract AccessControlEnumerable is IAccessControlEnumerable, AccessControl {
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping (bytes32 => EnumerableSet.AddressSet) private _roleMembers;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlEnumerable).interfaceId
            || super.supportsInterface(interfaceId);
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
    function getRoleMember(bytes32 role, uint256 index) public view override returns (address) {
        return _roleMembers[role].at(index);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view override returns (uint256) {
        return _roleMembers[role].length();
    }

    /**
     * @dev Overload {grantRole} to track enumerable memberships
     */
    function grantRole(bytes32 role, address account) public virtual override {
        super.grantRole(role, account);
        _roleMembers[role].add(account);
    }

    /**
     * @dev Overload {revokeRole} to track enumerable memberships
     */
    function revokeRole(bytes32 role, address account) public virtual override {
        super.revokeRole(role, account);
        _roleMembers[role].remove(account);
    }

    /**
     * @dev Overload {renounceRole} to track enumerable memberships
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        super.renounceRole(role, account);
        _roleMembers[role].remove(account);
    }

    /**
     * @dev Overload {_setupRole} to track enumerable memberships
     */
    function _setupRole(bytes32 role, address account) internal virtual override {
        super._setupRole(role, account);
        _roleMembers[role].add(account);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented or decremented by one. This can be used e.g. to track the number
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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC721.sol";

/**
 * @dev ERC721 token with storage based token URI management.
 */
abstract contract ERC721URIStorage is ERC721 {
    using Strings for uint256;

    // Optional mapping for token URIs
    mapping (uint256 => string) private _tokenURIs;

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return super.tokenURI(tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
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
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }
}

// SPDX-License-Identifier: MIT

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
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

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
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

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

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant alphabet = "0123456789abcdef";

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
            buffer[i] = alphabet[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

}

// SPDX-License-Identifier: MIT

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

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {

    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
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
    constructor () {
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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    function hasRole(bytes32 role, address account) external view returns (bool);
    function getRoleAdmin(bytes32 role) external view returns (bytes32);
    function grantRole(bytes32 role, address account) external;
    function revokeRole(bytes32 role, address account) external;
    function renounceRole(bytes32 role, address account) external;
}

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
        mapping (address => bool) members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

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
     * bearer except when using {_setupRole}.
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
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId
            || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if(!hasRole(role, account)) {
            revert(string(abi.encodePacked(
                "AccessControl: account ",
                Strings.toHexString(uint160(account), 20),
                " is missing role ",
                Strings.toHexString(uint256(role), 32)
            )));
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
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
     * If the calling account had been granted `role`, emits a {RoleRevoked}
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
        emit RoleAdminChanged(role, getRoleAdmin(role), adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT

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
library EnumerableSet {
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
        mapping (bytes32 => uint256) _indexes;
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

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex

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
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
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
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./Initializable.sol";

/**
 * https://github.com/maticnetwork/pos-portal/blob/master/contracts/common/EIP712Base.sol
 */
contract EIP712Base is Initializable {
    struct EIP712Domain {
        string name;
        string version;
        address verifyingContract;
        bytes32 salt;
    }

    string constant public ERC712_VERSION = "1";

    bytes32 internal constant EIP712_DOMAIN_TYPEHASH = keccak256(
        bytes(
            "EIP712Domain(string name,string version,address verifyingContract,bytes32 salt)"
        )
    );
    bytes32 internal domainSeperator;

    // supposed to be called once while initializing.
    // one of the contractsa that inherits this contract follows proxy pattern
    // so it is not possible to do this in a constructor
    function _initializeEIP712(
        string memory name
    )
    internal
    initializer
    {
        _setDomainSeperator(name);
    }

    function _setDomainSeperator(string memory name) internal {
        domainSeperator = keccak256(
            abi.encode(
                EIP712_DOMAIN_TYPEHASH,
                keccak256(bytes(name)),
                keccak256(bytes(ERC712_VERSION)),
                address(this),
                bytes32(getChainId())
            )
        );
    }

    function getDomainSeperator() public view returns (bytes32) {
        return domainSeperator;
    }

    function getChainId() public view returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }

    /**
     * Accept message hash and returns hash message in EIP712 compatible form
     * So that it can be used to recover signer from signature signed using EIP712 formatted data
     * https://eips.ethereum.org/EIPS/eip-712
     * "\\x19" makes the encoding deterministic
     * "\\x01" is the version byte to make it compatible to EIP-191
     */
    function toTypedMessageHash(bytes32 messageHash)
    internal
    view
    returns (bytes32)
    {
        return
        keccak256(
            abi.encodePacked("\x19\x01", getDomainSeperator(), messageHash)
        );
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

/**
 * https://github.com/maticnetwork/pos-portal/blob/master/contracts/common/Initializable.sol
 */
contract Initializable {
    bool inited = false;

    modifier initializer() {
        require(!inited, "already inited");
        _;
        inited = true;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC1155.sol";

/**
 * @dev Extension of {ERC1155} that allows token holders to destroy both their
 * own tokens and those that they have been approved to use.
 *
 * _Available since v3.1._
 */
abstract contract ERC1155Burnable is ERC1155 {
    function burn(address account, uint256 id, uint256 value) public virtual {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );

        _burn(account, id, value);
    }

    function burnBatch(address account, uint256[] memory ids, uint256[] memory values) public virtual {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );

        _burnBatch(account, ids, values);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC1155.sol";
import "../../../security/Pausable.sol";

/**
 * @dev ERC1155 token with pausable token transfers, minting and burning.
 *
 * Useful for scenarios such as preventing trades until the end of an evaluation
 * period, or having an emergency switch for freezing all token transfers in the
 * event of a large bug.
 *
 * _Available since v3.1._
 */
abstract contract ERC1155Pausable is ERC1155, Pausable {
    /**
     * @dev See {ERC1155-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
     */
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
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        require(!paused(), "ERC1155Pausable: token transfer while paused");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC1155.sol";
import "../extensions/ERC1155Burnable.sol";
import "../extensions/ERC1155Pausable.sol";
import "../../../access/AccessControlEnumerable.sol";
import "../../../utils/Context.sol";

/**
 * @dev {ERC1155} token, including:
 *
 *  - ability for holders to burn (destroy) their tokens
 *  - a minter role that allows for token minting (creation)
 *  - a pauser role that allows to stop all token transfers
 *
 * This contract uses {AccessControl} to lock permissioned functions using the
 * different roles - head to its documentation for details.
 *
 * The account that deploys the contract will be granted the minter and pauser
 * roles, as well as the default admin role, which will let it grant both minter
 * and pauser roles to other accounts.
 */
contract ERC1155PresetMinterPauser is Context, AccessControlEnumerable, ERC1155Burnable, ERC1155Pausable {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    /**
     * @dev Grants `DEFAULT_ADMIN_ROLE`, `MINTER_ROLE`, and `PAUSER_ROLE` to the account that
     * deploys the contract.
     */
    constructor(string memory uri) ERC1155(uri) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        _setupRole(MINTER_ROLE, _msgSender());
        _setupRole(PAUSER_ROLE, _msgSender());
    }

    /**
     * @dev Creates `amount` new tokens for `to`, of token type `id`.
     *
     * See {ERC1155-_mint}.
     *
     * Requirements:
     *
     * - the caller must have the `MINTER_ROLE`.
     */
    function mint(address to, uint256 id, uint256 amount, bytes memory data) public virtual {
        require(hasRole(MINTER_ROLE, _msgSender()), "ERC1155PresetMinterPauser: must have minter role to mint");

        _mint(to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] variant of {mint}.
     */
    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) public virtual {
        require(hasRole(MINTER_ROLE, _msgSender()), "ERC1155PresetMinterPauser: must have minter role to mint");

        _mintBatch(to, ids, amounts, data);
    }

    /**
     * @dev Pauses all token transfers.
     *
     * See {ERC1155Pausable} and {Pausable-_pause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function pause() public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), "ERC1155PresetMinterPauser: must have pauser role to pause");
        _pause();
    }

    /**
     * @dev Unpauses all token transfers.
     *
     * See {ERC1155Pausable} and {Pausable-_unpause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function unpause() public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), "ERC1155PresetMinterPauser: must have pauser role to unpause");
        _unpause();
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControlEnumerable, ERC1155) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    )
        internal virtual override(ERC1155, ERC1155Pausable)
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC1155.sol";
import "./IERC1155Receiver.sol";
import "./extensions/IERC1155MetadataURI.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/introspection/ERC165.sol";

/**
 *
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
    using Address for address;

    // Mapping from token ID to account balances
    mapping (uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping (address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    constructor (string memory uri_) {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155).interfaceId
            || interfaceId == type(IERC1155MetadataURI).interfaceId
            || super.supportsInterface(interfaceId);
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
    function balanceOfBatch(
        address[] memory accounts,
        uint256[] memory ids
    )
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
    )
        public
        virtual
        override
    {
        require(to != address(0), "ERC1155: transfer to the zero address");
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, _asSingletonArray(id), _asSingletonArray(amount), data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        _balances[id][from] = fromBalance - amount;
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
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
    )
        public
        virtual
        override
    {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            _balances[id][from] = fromBalance - amount;
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
    function _mint(address account, uint256 id, uint256 amount, bytes memory data) internal virtual {
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
    function _mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint i = 0; i < ids.length; i++) {
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
    function _burn(address account, uint256 id, uint256 amount) internal virtual {
        require(account != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, account, address(0), _asSingletonArray(id), _asSingletonArray(amount), "");

        uint256 accountBalance = _balances[id][account];
        require(accountBalance >= amount, "ERC1155: burn amount exceeds balance");
        _balances[id][account] = accountBalance - amount;

        emit TransferSingle(operator, account, address(0), id, amount);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(address account, uint256[] memory ids, uint256[] memory amounts) internal virtual {
        require(account != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, account, address(0), ids, amounts, "");

        for (uint i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 accountBalance = _balances[id][account];
            require(accountBalance >= amount, "ERC1155: burn amount exceeds balance");
            _balances[id][account] = accountBalance - amount;
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
    )
        internal
        virtual
    { }

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    )
        private
    {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver(to).onERC1155Received.selector) {
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
    )
        private
    {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (bytes4 response) {
                if (response != IERC1155Receiver(to).onERC1155BatchReceived.selector) {
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
}

// SPDX-License-Identifier: MIT

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
    event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values);

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
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids) external view returns (uint256[] memory);

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
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;

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
    function safeBatchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {

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
    )
        external
        returns(bytes4);

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
    )
        external
        returns(bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC1155.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../openzepplin-contracts/token/ERC20/IERC20.sol";

interface IFeeCollectable {
  function feeBalanceToken(address token) external view returns(uint);
  function collectAllFeeToken(address erc20, address to) external;
}

abstract contract FeeCollectable {
  address public feeCollectorAdmin;
  uint16 totalFeeRate = 100;
  mapping(address => uint8) public feeRates;

  // user -> erc20 -> fee amount
  mapping(address => mapping(address => uint256)) private availableERC20Fees;
  address[] private shareholders;

  event FeeTokensDeposited(address erc20, address from, uint256 amount);
  event FeeTokensWithdrawn(address erc20, address to, uint256 amount);
  event FeeCollectorAdminChanged(address oldAddress, address newAddress);
  event FeeShareholdersChanged(address[] shareholders, uint8[] feeRates);

  constructor() {
    feeCollectorAdmin = msg.sender;
    shareholders = [msg.sender];
    feeRates[msg.sender] = 100;
  }

  function availableFeeToken(address erc20, address shareholder) virtual public view returns(uint) {
    return availableERC20Fees[shareholder][erc20];
  }

  function setFeeCollectorAdmin(address user) external {
    require(feeCollectorAdmin == msg.sender, "FeeCollectable: only fee collector admin can pass his rights");
    feeCollectorAdmin = user;
    emit FeeCollectorAdminChanged(msg.sender, user);
  }

  function withdrawAllFeeToken(address erc20) virtual public {
    require(availableERC20Fees[msg.sender][erc20] > 0, "FeeCollectable: available fee must be more than 0");
    IERC20(erc20).transfer(msg.sender, availableERC20Fees[msg.sender][erc20]);
    emit FeeTokensWithdrawn(erc20, msg.sender, availableERC20Fees[msg.sender][erc20]);
    availableERC20Fees[msg.sender][erc20] = 0;
  }

  function setShareholders(address[] memory _shareholders, uint8[] memory _feeRates) virtual public {
    require(feeCollectorAdmin == msg.sender, "FeeCollectable: only fee collector admin can set shareholders");
    require(
      _shareholders.length == _feeRates.length,
      "FeeCollectable: amount of shareholders must be equal to amount of fee rates"
    );
    uint16 feeRatesSum = 0;
    for (uint i = 0; i < _feeRates.length; i++) {
      require(_feeRates[i] > 0 && _feeRates[i] <= 100, "FeeCollectable: all fee rates must be between 1 and 100");
      feeRatesSum += _feeRates[i];
    }
    require(feeRatesSum <= 100, "FeeCollectable: sum of fee rates must be less or equal 100");
    totalFeeRate = feeRatesSum;
    for (uint i = 0; i < shareholders.length; i++) {
      feeRates[shareholders[i]] = 0;
    }
    for (uint i = 0; i < _shareholders.length; i++) {
      feeRates[_shareholders[i]] = _feeRates[i];
    }
    shareholders = _shareholders;
    emit FeeShareholdersChanged(_shareholders, _feeRates);
  }

  function depositFeeToken(address erc20, address from, uint256 amount) internal {
    if (from != address(this)) {
      IERC20(erc20).transferFrom(from, address(this), amount);
    }
    for (uint i = 0; i < shareholders.length; i++) {
      availableERC20Fees[shareholders[i]][erc20] += amount / totalFeeRate * feeRates[shareholders[i]];
    }
    emit FeeTokensDeposited(erc20, from, amount);
  }
}

// SPDX-License-Identifier: MIT

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

    constructor () {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
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