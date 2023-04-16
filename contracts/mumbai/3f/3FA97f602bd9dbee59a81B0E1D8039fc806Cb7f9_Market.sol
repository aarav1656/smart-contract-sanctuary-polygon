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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

enum TokenTypes { Matic, Ft }

interface IMarket {
    /***********
     * STRUCTS *
     ***********/
    
    struct Article {
        TokenTypes method;
        uint256 price;
        string cid;
        address payable author;
    }

    /**********
     * EVENTS *
     **********/ 
    
    event List( uint256 tokenId );
    event Star( address indexed from, address indexed to, uint256 amount );

    /*************
     * FUNCTIONS *
     *************/

    function listArticle (TokenTypes _method, uint256 _price, string memory _cid) external;

    function delistArticle (uint _tokenId) external;

    function purchaseArticle (uint256 tokenId) payable external;

    function sendStar(uint tokenId) external;

    function getArticle(uint tokenId) external view returns (Article memory);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

interface INFT is IERC1155 {
    /*************
     * FUNCTIONS *
     *************/

    function mintAndTransfer(uint256 tokenId, string memory tokenUri, address recipient) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import { TokenTypes } from "./IMarket.sol";

interface ITreasury {
    /*************
     * FUNCTIONS *
     *************/

    function sendReward(address author, address user, uint256 amount) external;

    function setMarketContract(address marketAddress) external;

    function receiveSales(TokenTypes tokenType, uint256 amount) external;

    function burnToken() external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./interface/INFT.sol";
import "./interface/ITreasury.sol";
import "./interface/IMarket.sol";

contract Market is Ownable, IMarket {
    using Counters for Counters.Counter;

    /************
     * CONSTANTS
     ************/

    IERC20    public ft;
    INFT      public nft;
    ITreasury public treasury;

    uint8 commissionPercentage = 5; // 5%
    Counters.Counter private _nextTokenId;

    mapping (address => uint256) public userToStar;
    mapping (uint256 => uint256) public tokenIdToStar;
    mapping (address => mapping( uint256 => bool )) public consumerToSentStars;

    mapping (uint256 => Article) articles;

    /************
     * MODIFIER *
     ************/
    
    modifier nonEmptyCID(string memory _cid) {
        require(bytes(_cid).length > 0, "cid should not be empty");
        _;
    }

    modifier checkDup(string memory _cid) {
        bool valid = true;
        
        for (uint256 i = 1; i < _nextTokenId.current(); i++) {
            if (keccak256(bytes(articles[i].cid)) == keccak256(bytes(_cid))) {
                valid = false;
            }
        }

        require(valid, "the CID has already listerd");
        _;
    }

    /**************
     * CONSTRUCTOR
     **************/

    constructor(IERC20 _ft, INFT _nft, ITreasury _treasury) {
        ft = _ft;
        nft = _nft;
        treasury = _treasury;
        _nextTokenId.increment();
    }

    receive() external payable {}

    fallback() external payable {}

    /******************
     * CORE FUNCTIONS *
     ******************/

    /**
     * @dev add article to article list
     */
    function listArticle (TokenTypes _method, uint256 _price, string memory _cid) external nonEmptyCID(_cid) checkDup(_cid) {
        articles[_nextTokenId.current()] = Article(_method, _price, _cid, payable(msg.sender));
        emit List(_nextTokenId.current());
        _nextTokenId.increment();
    }

    /**
     * @dev remove article to article list
     */
    function delistArticle (uint _tokenId) external {
        require(_tokenIdExists(_tokenId), "the tokenId does not exist");
        require(msg.sender == articles[_tokenId].author, "caller is not the author of this article");
        delete articles[_tokenId];
    }

    /**
     * @dev purchase article
     */
    function purchaseArticle (uint256 tokenId) payable external {
        require(_tokenIdExists(tokenId), "the tokenId does not exist");
        require(articles[tokenId].author != msg.sender, "cannot buy your article yourselves");

        Article memory article = articles[tokenId];
        uint256 priceForCommission =  article.price / 100 * commissionPercentage;
        uint256 priceForAuthor = article.price / 100 * ( 100 - commissionPercentage );
        address payable treasuryAddress = payable(address(treasury));
        if (article.method == TokenTypes.Matic) {
            require(msg.value == article.price, "insufficient value for the price of the article");
            treasuryAddress.transfer(priceForCommission);
            article.author.transfer(priceForAuthor);
            treasury.receiveSales(TokenTypes.Matic, priceForCommission);
        } else if (article.method == TokenTypes.Ft) {
            require(msg.value == 0, "value should be 0");
            require(ft.balanceOf(msg.sender) >= article.price, "insufficient value for the article's price");
            ft.transferFrom(msg.sender, treasuryAddress, priceForCommission);
            ft.transferFrom(msg.sender, article.author, priceForAuthor);
            treasury.receiveSales(TokenTypes.Ft, priceForCommission);
        }
        
        // mint
        nft.mintAndTransfer(tokenId, article.cid, msg.sender);
    }

    /**
     * @dev evaluate the sender's having article & send rewards for its action
     */
    function sendStar(uint tokenId) external {
        require(nft.balanceOf(msg.sender, tokenId) > 0, "caller dose not have the article");
        require(!consumerToSentStars[msg.sender][tokenId], "you've already sent star to this article");
        Article memory _article = articles[tokenId];
        consumerToSentStars[msg.sender][tokenId] = true;
        
        uint256 star = _article.price;
        userToStar[_article.author] += star;
        tokenIdToStar[tokenId] += star;

        treasury.sendReward(_article.author, msg.sender, star);

        emit Star(msg.sender, _article.author, star);
    }

    /******************
     * GET FUNCTIONS *
     ******************/

    function getArticle(uint tokenId) external view returns (Article memory) {
        require(_tokenIdExists(tokenId), "the tokenId does not exist");
        return articles[tokenId];
    }

    function _tokenIdExists(uint256 tokenId) private view returns(bool) {
        Article memory article = articles[tokenId];
        return (
            bytes(article.cid).length > 0 && article.author != address(0)
        );
    }
}