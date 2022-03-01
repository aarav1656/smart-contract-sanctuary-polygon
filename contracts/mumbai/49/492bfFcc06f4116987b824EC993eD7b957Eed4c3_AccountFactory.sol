// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Account.sol";

contract AccountFactory is OwnerOperator {

  // ============ Storage ============

  //mapping of account id to accounts
  mapping(uint256 => IAccount) private _accounts;

  // ============ Deploy ============

  /**
   * @dev Sets owner
   */
  constructor(address owner_) {
    _transferOwnership(owner_);
  }

  // ============ Read Methods ============

  /**
   * Returns an account contract address
   */
  function accountAddress(uint256 accountId) 
    public view virtual returns(address) 
  {
    return address(_accounts[accountId]);
  }

  // ============ Factory Methods ============

  /**
   * Creates an account
   */
  function createAccount(
    uint256 accountId,
    string memory name, 
    string memory symbol, 
    string memory uri
  ) public virtual onlyOwnerOperator {
    addAccount(accountId, new Account(
      name, 
      symbol, 
      uri, 
      owner(),
      operator()
    ));
  }

  /**
   * Creates an account
   */
  function addAccount(
    uint256 accountId, 
    IAccount account
  ) public virtual onlyOwnerOperator {
    //make new contract
    _accounts[accountId] = account;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

//........................................................................................
//..####...######..#####...######..##..##...####...#####...######...........####....####..
//.##......##......##..##..##......###.##..##..##..##..##..##..............##..##..##..##.
//..####...####....#####...####....##.###..######..##..##..####............##......##..##.
//.....##..##......##..##..##......##..##..##..##..##..##..##........##....##..##..##..##.
//..####...######..##..##..######..##..##..##..##..#####...######....##.....####....####..
//........................................................................................
//
// Hello from Serenade!
//
// DIGITAL COLLECTIBLES MADE BY ROCKSTARS
// COLLECT YOUR FAVOURITE ARTISTS
//
// https://serenade.co/
//

import "../ERC721/ERC721Base.sol";
import "../Royalty/RoyaltySplitter.sol";

import "./IAccount.sol";

error InvalidProof();
error RoyaltyToZeroAddress();

contract Account is ERC721Base, OwnerOperator, IAccount {
  // ============ Constants ============

  //where 10000 = 100.00%
  uint16 public constant MAX_PERCENT = 10000; 

  //bytes4(keccak256("royaltyInfo(uint256,uint256)")) == 0x2a55205a
  bytes4 internal constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

  // ============ Storage ============

  mapping(uint256 => IRoyaltySplitter) private _royalties;
  mapping(uint256 => uint16) private _percents;

  // ============ Deploy ============

  /**
   * @dev Sets up ERC721Base. Sets contract URI
   */
  constructor(
    string memory _name, 
    string memory _symbol, 
    string memory _uri,
    address _owner,
    address _operator
  ) ERC721Base(_name, _symbol) {
    _transferOwnership(_owner);
    _transferOperator(_operator);
    _setContractURI(_uri);
  }

  // ============ Read Methods ============

  /**
   * @dev Returns true if product exists
   */
  function productExists(uint256 productId) public view returns(bool) {
    return _productExists(productId);
  }

  /**
   * @dev Returns a royalty splitter contract address
   */
  function royaltyAddress(uint256 productId) public view returns(address) {
    return address(_royalties[productId]);
  }

  /**
   * @dev implements ERC2981 `royaltyInfo()`
   */
  function royaltyInfo(uint256 productId, uint256 salePrice) 
    public 
    view 
    virtual 
    returns(address receiver, uint256 royaltyAmount) 
  {
    //if no royalty percent
    if (_percents[productId] == 0) {
      //return default nothing
      return (address(0), 0);
    }

    return (
      payable(address(_royalties[productId])), 
      (salePrice * _percents[productId]) / MAX_PERCENT
    );
  }

  /** 
   * @dev Returns the royalty percent of `productId`
   */
  function royaltyPercent(uint256 productId) public view returns(uint16) {
    return _percents[productId];
  }

  // ============ Minting Methods ============

  /**
   * @dev Allows admin to mint a token for someone
   */
  function mint(uint256 productId, uint256 tokenId, address recipient) 
    public 
    virtual 
    onlyOwnerOperator
  {
    //mint first and wait for errors
    _safeMint(recipient, tokenId);
    //then make a copy of the product
    _makeEdition(tokenId, productId);
  }

  // ============ Product Methods ============

  /**
   * @dev Sets a fixed `uri` and max supply `size` for a `productId`
   *      Will not add `uri` if empty string. Use `setProductURI` instead
   *      Will not add `size` if zero. Use `setProductSize` instead
   */
  function setProduct(uint256 productId, uint256 size, string memory uri) 
    public virtual onlyOwnerOperator 
  {
    if (bytes(uri).length > 0) {
      setProductSize(productId, size);
    }

    if (size > 0) {
      setProductURI(productId, uri);
    }
  }

  /**
   * @dev Sets a max supply `size` for a `productId`
   */
  function setProductSize(uint256 productId, uint256 size) 
    public virtual onlyOwnerOperator
  {
    _setProductSize(productId, size);
  }

  /**
   * @dev Sets a fixed `uri` for a `productId`
   */
  function setProductURI(uint256 productId, string memory uri) 
    public virtual onlyOwnerOperator 
  {
    _setProductURI(productId, uri);
  }

  // ============ Royalty Methods ============

  /**
   * @dev Adds a royalty splitter
   */
  function addRoyalty(
    uint256 productId, 
    uint16 percent, 
    IRoyaltySplitter royalty
  ) public virtual onlyOwnerOperator {
    //make new contract
    _royalties[productId] = royalty;
    _percents[productId] = percent;
  }

  /**
   * @dev Creates a royalty splitter
   */
  function createRoyalty(
    uint256 productId,
    uint16 percent,
    address[] memory payees,
    uint256[] memory shares
  ) public virtual onlyOwnerOperator {
    addRoyalty(
      productId, 
      percent, 
      new RoyaltySplitter(payees, shares, owner(), operator())
    );
  }

  // ============ Admin Methods ============

  /**
   * @dev Pauses all token transfers.
   */
  function pause() public virtual onlyOwnerOperator {
    _pause();
  }

  /**
   * @dev Unpauses all token transfers.
   */
  function unpause() public virtual onlyOwnerOperator {
    _unpause();
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";

import "./extensions/ERC721Burnable.sol";
import "./extensions/ERC721Pausable.sol";
import "./extensions/ERC721Products.sol";
import "./extensions/ERC721URIContract.sol";

contract ERC721Base is
  Context,
  ERC721Burnable,
  ERC721Pausable,
  ERC721Products,
  ERC721URIContract
{
  // ============ Deploy ============

  /**
   * @dev Grants `DEFAULT_ADMIN_ROLE` and `PAUSER_ROLE` to the
   * account that deploys the contract. Sets the contract's URI. 
   */
  constructor(string memory name_, string memory symbol_) ERC721(name_, symbol_) {}

  // ============ Overrides ============

  /**
   * @dev Describes linear override for `_beforeTokenTransfer` used in 
   * both `ERC721` and `ERC721Pausable`
   */
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal virtual override(ERC721, ERC721Pausable) {
    super._beforeTokenTransfer(from, to, tokenId);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "../Operator/OwnerOperator.sol";

import "./IRoyaltySplitter.sol";

error InvalidRecipients();
error InvalidRecipient();
error InvalidShares();
error ZeroPaymentDue();
error RecipientZeroShares();
error RecipientExistingShares();
error TokenAlreadyAccepted();

contract RoyaltySplitter is 
  Context, 
  ReentrancyGuard, 
  OwnerOperator, 
  IRoyaltySplitter 
{ 
  // ============ Storage ============

  IERC20[] private _erc20Accepted;

  uint256 private _totalShares;
  mapping(address => uint256) private _shares;
  address[] private _recipients;

  uint256 private _ethTotalAccountedFor;
  uint256 private _ethTotalUnaccountedReleased;
  mapping(address => uint256) private _ethAccountedFor;
  mapping(address => uint256) private _ethAccountedReleased;
  mapping(address => uint256) private _ethUnaccountedReleased;

  mapping(IERC20 => uint256) private _erc20TotalAccountedFor;
  mapping(IERC20 => uint256) private _erc20TotalUnaccountedReleased;
  mapping(IERC20 => mapping(address => uint256)) private _erc20AccountedFor;
  mapping(IERC20 => mapping(address => uint256)) private _erc20UnaccountedReleased;
  mapping(IERC20 => mapping(address => uint256)) private _erc20AccountedReleased;

  // ============ Modifiers ============

  modifier validRecipients(
    address[] memory recipients, 
    uint256[] memory shares_
  ) {
    if (recipients.length == 0 || recipients.length != shares_.length) 
      revert InvalidRecipients();
    _;
  }

  // ============ Deploy ============

  /**
   * @dev Creates an instance of `RoyalySplitter` where each account 
   * in `recipients` is assigned the number of shares at the matching 
   * position in the `shares` array.
   *
   * All addresses in `recipients` must be non-zero. Both arrays must 
   * have the same non-zero length, and there must be no duplicates in 
   * `recipients`.
   */
  constructor(
    address[] memory recipients_, 
    uint256[] memory shares_,
    address owner_,
    address operator_
  ) payable validRecipients(recipients_, shares_) {
    _transferOwnership(owner_);
    _transferOperator(operator_);
    for (uint256 i = 0; i < recipients_.length; i++) {
      _addRecipient(recipients_[i], shares_[i]);
    }
  }

  /**
   * @dev The Ether received will be logged with {PaymentReceived} 
   * events. Note that these events are not fully reliable: it's 
   * possible for a contract to receive Ether without triggering this 
   * function. This only affects the reliability of the events, and not 
   * the actual splitting of Ether.
   *
   * To learn more about this see the Solidity documentation for
   * https://solidity.readthedocs.io/en/latest/contracts.html#fallback-function[fallback
   * functions].
   */
  receive() external payable virtual {
    emit PaymentReceived(_msgSender(), msg.value);
  }

  // ============ Read Methods ============

  /**
   * @dev Getter for the address of the recipient number `index`.
   */
  function recipient(uint256 index) public view returns(address) {
    return _recipients[index];
  }
  
  /**
   * @dev Calculates the eth that can be releasable to `account`
   */
  function releasable(address account) public view returns(uint256) {
    return _accountedFor(account) + _unaccountedFor(account);
  }

  /**
   * @dev Calculates the ERC20 that can be releasable to `account`
   */
  function releasable(IERC20 token, address account) 
    public view returns(uint256)
  {
    return _accountedFor(token, account) + _unaccountedFor(token, account);
  }

  /**
   * @dev Getter for the amount of Ether already released to a payee.
   */
  function released(address account) public view returns(uint256) {
    return _ethUnaccountedReleased[account] + _ethAccountedReleased[account];
  }

  /**
   * @dev Getter for the amount of `token` tokens already released to a 
   * payee. `token` should be the address of an IERC20 contract.
   */
  function released(IERC20 token, address account) 
    public view returns(uint256) 
  {
    return _erc20UnaccountedReleased[token][account] + _erc20AccountedReleased[token][account];
  }

  /**
   * @dev Getter for the amount of shares held by an account.
   */
  function shares(address account) public view returns(uint256) {
    return _shares[account];
  }

  /**
   * @dev Getter for the total amount of Ether already released.
   */
  function totalReleased() public view returns(uint256) {
    return _ethTotalUnaccountedReleased;
  }

  /**
   * @dev Getter for the total amount of `token` already released. 
   * `token` should be the address of an IERC20 contract.
   */
  function totalReleased(IERC20 token) public view returns(uint256) {
    return _erc20TotalUnaccountedReleased[token];
  }

  /**
   * @dev Getter for the total shares held by recipients.
   */
  function totalShares() public view returns(uint256) {
    return _totalShares;
  }

  // ============ Write Methods ============

  /**
   * @dev Triggers a transfer to `account` of the amount of Ether they 
   * are owed, according to their percentage of the total shares and 
   * their previous withdrawals.
   */
  function release(address payable account) 
    public virtual nonReentrant 
  {
    uint256 accountedFor = _accountedFor(account);
    uint256 unaccountedFor = _unaccountedFor(account);
    uint256 payment = accountedFor + unaccountedFor;
    if (payment == 0) revert ZeroPaymentDue();

    _ethUnaccountedReleased[account] += unaccountedFor;
    _ethTotalUnaccountedReleased += unaccountedFor;

    _ethAccountedReleased[account] += accountedFor;
    _ethTotalAccountedFor -= accountedFor;
    _ethAccountedFor[account] = 0;
    
    Address.sendValue(account, payment);
    emit PaymentReleased(account, payment);
  }

  /**
   * @dev Triggers a transfer to `account` of the amount of `token` 
   * tokens they are owed, according to their percentage of the total 
   * shares and their previous withdrawals. `token` must be the address 
   * of an IERC20 contract.
   */
  function release(IERC20 token, address account) 
    public virtual nonReentrant
  {
    uint256 accountedFor = _accountedFor(token, account);
    uint256 unaccountedFor = _unaccountedFor(token, account);
    uint256 payment = accountedFor + unaccountedFor;
    if (payment == 0) revert ZeroPaymentDue();

    _erc20UnaccountedReleased[token][account] += unaccountedFor;
    _erc20TotalUnaccountedReleased[token] += unaccountedFor;

    _erc20AccountedReleased[token][account] += accountedFor;
    _erc20TotalAccountedFor[token] -= accountedFor;
    _erc20AccountedFor[token][account] = 0;

    SafeERC20.safeTransfer(token, account, payment);
    emit ERC20PaymentReleased(token, account, payment);
  }

  // ============ Admin Methods ============

  /**
   * @dev Considers tokens that can be vaulted
   */
  function accept(IERC20 token) public virtual onlyOwnerOperator {
    for (uint256 i = 0; i < _erc20Accepted.length; i++) {
      if(_erc20Accepted[i] == token) revert TokenAlreadyAccepted();
    }

    _erc20Accepted.push(token);
  }

  /**
   * @dev Add a new `account` to the contract.
   */
  function addRecipient(address account, uint256 shares_) 
    public virtual onlyOwnerOperator
  {
    _accountFor();
    _addRecipient(account, shares_);
  }

  /**
   * @dev Replaces the `recipients` with a new set
   */
  function batchUpdate(
    address[] memory recipients, 
    uint256[] memory shares_
  ) 
    public 
    virtual 
    validRecipients(recipients, shares_) 
    onlyOwnerOperator 
  {
    _accountFor();
    //make sure total shares and payees are zeroed out
    _totalShares = 0;
    //reset the payees array
    delete _recipients;
    emit RecipientsPurged();
    //now add recipients
    for (uint256 i = 0; i < recipients.length; i++) {
      _addRecipient(recipients[i], shares_[i]);
    }
  }

  /**
   * @dev Removes a `account`
   */
  function removeRecipient(uint256 index) 
    public virtual onlyOwnerOperator 
  {
    if (index >= _recipients.length) revert InvalidRecipient();

    _accountFor();

    address account = _recipients[index];

    //make the index the last account
    _recipients[index] = _recipients[_recipients.length - 1];
    //pop the last
    _recipients.pop();

    //now we need to less the total shares
    _totalShares -= _shares[account];
    //and zero out the account shares
    _shares[account] = 0;

    //emit that payee was removed
    emit RecipientRemoved(account);
  }

  /**
   * @dev Update a `account`
   */
  function updateRecipient(address account, uint256 shares_) 
    public virtual onlyOwnerOperator 
  {
    _accountFor();

    //now we need to adjust the total shares
    _totalShares = (_totalShares + shares_) - _shares[account];
    //update account shares
    _shares[account] = shares_;

    //emit that payee was updated
    emit RecipientUpdated(account, shares_);
  }

  // ============ Internal Methods ============

  /**
   * @dev Add a new payee to the contract.
   */
  function _addRecipient(address account, uint256 shares_) internal virtual {
    if (account == address(0)) revert InvalidRecipient();
    if (shares_ == 0) revert InvalidShares();
    if (_shares[account] > 0) revert RecipientExistingShares();

    _recipients.push(account);
    _shares[account] = shares_;
    _totalShares = _totalShares + shares_;
    emit RecipientAdded(account, shares_);
  }

  /**
   * @dev Returns the eth for an `account` that is already accounted for
   */
  function _accountedFor(address account) internal virtual view returns(uint256) {
    return _ethAccountedFor[account];
  }

  /**
   * @dev Returns the erc20 `token` for an `account` that is already accounted for
   */
  function _accountedFor(IERC20 token, address account) internal virtual view returns(uint256) {
    return _erc20AccountedFor[token][account];
  }

  /**
   * @dev Returns the eth for an `account` that is unaccounted for
   */
  function _unaccountedFor(address account) internal virtual view returns(uint256) {
    uint256 balance = _totalUnaccountedFor() + _ethTotalUnaccountedReleased;
    return _account(balance, _shares[account], _totalShares) - _ethUnaccountedReleased[account];
  }

  /**
   * @dev Returns the erc20 `token` for an `account` that is unaccounted for
   */
  function _unaccountedFor(IERC20 token, address account) internal virtual view returns(uint256) {
    uint256 balance = _totalUnaccountedFor(token) + _erc20TotalUnaccountedReleased[token];
    return _account(balance, _shares[account], _totalShares) - _erc20UnaccountedReleased[token][account];
  }

  /**
   * @dev Returns the total amount of accounted for eth
   */
  function _totalAccountedFor() internal virtual view returns(uint256) {
    return _ethTotalAccountedFor;
  }

  /**
   * @dev Returns the total amount of accounted for an erc20 `token`
   */
  function _totalAccountedFor(IERC20 token) internal virtual view returns(uint256) {
    return _erc20TotalAccountedFor[token];
  }

  /**
   * @dev Returns the total amount of unaccounted eth
   */
  function _totalUnaccountedFor() internal virtual view returns(uint256) {
    return address(this).balance - _totalAccountedFor();
  }

  /**
   * @dev Returns the total amount of unaccounted erc20 `token`
   */
  function _totalUnaccountedFor(IERC20 token) internal virtual view returns(uint256) {
    return token.balanceOf(address(this)) - _totalAccountedFor(token);
  }

  /**
   * @dev Stores the amounts due to all the recipients from the 
   * unaccounted balance to an account vault
   */
  function _accountFor() internal virtual {
    //get eth balance
    uint256 balance = (
      address(this).balance + _ethTotalUnaccountedReleased
    ) -  _totalAccountedFor();
    //first lets account for the eth
    for (uint256 i = 0; i < _recipients.length; i++) {
      _accountFor(_recipients[i], balance);
    }

    //loop through the accepted erc20 tokens
    for (uint256 j = 0; j < _erc20Accepted.length; j++) {
      //get erc20 token
      IERC20 token = _erc20Accepted[j];
      //get erc20 balance
      balance = (
        token.balanceOf(address(this)) + _erc20TotalUnaccountedReleased[token]
      ) - _totalAccountedFor(token);
      //account for the erc20
      for (uint256 i = 0; i < _recipients.length; i++) {
        _accountFor(token, _recipients[i], balance);
      }
    }
  }

  /**
   * @dev Stores the eth due to the `account` from the unaccounted 
   * balance to an account vault
   */
  function _accountFor(address account, uint256 balance) internal virtual {
    uint256 unaccounted = _account(
      balance,
      _shares[account],
      _totalShares
    );
    
    _ethAccountedFor[account] += unaccounted;
    _ethTotalAccountedFor += unaccounted;
  }

  /**
   * @dev Stores the erc20 `token` due to the `account` from the 
   * unaccounted balance to an account vault
   */
  function _accountFor(IERC20 token, address account, uint256 balance) internal virtual {
    uint256 unaccounted = _account(
      balance,
      _shares[account],
      _totalShares
    );

    _erc20AccountedFor[token][account] += unaccounted;
    _erc20TotalAccountedFor[token] += unaccounted;
  }

  /**
   * @dev The formula to account stuff
   */
  function _account(
    uint256 balance,
    uint256 currentShares,
    uint256 totalCurrentShares
  ) internal virtual pure returns(uint256) {
    return (balance  * currentShares) / totalCurrentShares;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";

import "../Royalty/IRoyaltySplitter.sol";

interface IAccount is IERC721, IERC721Metadata {
  // ============ Read Methods ============

  /**
   * @dev Returns true if product exists
   */
  function productExists(uint256 productId) external view returns(bool);

  /**
   * Returns a royalty splitter contract address
   */
  function royaltyAddress(uint256 productId) external view returns(address);

  /**
   * @dev implements ERC2981 `royaltyInfo()`
   */
  function royaltyInfo(uint256 productId, uint256 salePrice) 
    external 
    view 
    returns(address receiver, uint256 royaltyAmount);

  /** 
   * @dev Returns the royalty percent of `productId`
   */
  function royaltyPercent(uint256 productId) 
    external view returns(uint16);

  // ============ Minting Methods ============

  /**
   * @dev Allows admin to mint a token for someone
   */
  function mint(
    uint256 productId, 
    uint256 tokenId, 
    address recipient
  ) external;

  // ============ Product Methods ============

  /**
   * @dev Sets a fixed `uri` and max supply `size` for a `productId`
   *      Will not add `uri` if empty string. Use `setProductURI` instead
   *      Will not add `size` if zero. Use `setProductSize` instead
   */
  function setProduct(
    uint256 productId, 
    uint256 size, 
    string memory uri
  ) external;

  /**
   * @dev Sets a max supply `size` for a `productId`
   */
  function setProductSize(uint256 productId, uint256 size) external;

  /**
   * @dev Sets a fixed `uri` for a `productId`
   */
  function setProductURI(uint256 productId, string memory uri) external;

  // ============ Royalty Methods ============

  /**
   * @dev Adds a royalty splitter
   */
  function addRoyalty(
    uint256 productId, 
    uint16 percent, 
    IRoyaltySplitter royalty
  ) external;

  /**
   * @dev Creates a royalty splitter
   */
  function createRoyalty(
    uint256 productId,
    uint16 percent,
    address[] memory payees,
    uint256[] memory shares
  ) external;

  // ============ Admin Methods ============

  /**
   * @dev Pauses all token transfers.
   */
  function pause() external;

  /**
   * @dev Unpauses all token transfers.
   */
  function unpause() external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "@openzeppelin/contracts/utils/Context.sol";

/**
 * @title ERC721 Burnable Token
 * @dev ERC721 Token that can be irreversibly burned (destroyed).
 */
abstract contract ERC721Burnable is Context, ERC721 {
  /**
   * @dev Burns `tokenId`. See {ERC721B-_burn}.
   *
   * Requirements:
   *
   * - The caller must own `tokenId` or be an approved operator.
   */
  function burn(uint256 tokenId) public virtual {
    _burn(tokenId);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

error TransferWhilePaused();

/**
 * @dev ERC721 token with pausable token transfers, minting and burning.
 *
 * Useful for scenarios such as preventing trades until the end of an evaluation
 * period, or having an emergency switch for freezing all token transfers in the
 * event of a large bug.
 */
abstract contract ERC721Pausable is Pausable, ERC721 {
  /**
   * @dev See {ERC721B-_beforeTokenTransfer}.
   *
   * Requirements:
   *
   * - the contract must not be paused.
   */
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal virtual override {
    if (paused()) revert TransferWhilePaused();
    super._beforeTokenTransfer(from, to, tokenId);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC721.sol";

error TokenEditionExists();
error TokenEditionNotExists();
error ProductExists();
error ProductNotExists();
error MaxEditionsReached();

abstract contract ERC721Products is ERC721 {

  // ============ Constants ============

  //mapping of token id to product id
  mapping(uint256 => uint256) public productOf;
  //index mapping of product id to current supply size (editions)
  mapping(uint256 => uint256) public productSupply;
  //index mapping of product id to max supply size
  mapping(uint256 => uint256) public productSize;
  //mapping of product id to fixed uri
  mapping(uint256 => string) public productURI;

  // ============ Modifiers ============

  modifier isEdition(uint256 tokenId) {
    //make sure there is a product
    if (productOf[tokenId] == 0) revert TokenEditionNotExists();
    _;
  }

  modifier isNotEdition(uint256 tokenId) {
    //make sure there is a product
    if (productOf[tokenId] > 0) revert TokenEditionExists();
    _;
  }

  modifier isProduct(uint256 productId) {
    //make sure there is a product
    if (!_productExists(productId)) revert ProductNotExists();
    _;
  }

  modifier isNotProduct(uint256 productId) {
    //make sure there is a product
    if (_productExists(productId)) revert ProductExists();
    _;
  }

  // ============ Read Methods ============

  /**
   * @dev Returns the token URI by using the base uri and index
   */
  function tokenURI(uint256 tokenId) 
    public 
    view 
    virtual 
    override 
    isToken(tokenId) 
    isEdition(tokenId) 
    returns(string memory) 
  {
    //get product id
    uint256 productId = productOf[tokenId];
    if (!_productExists(productId)) revert ProductNotExists();
    return productURI[productId];
  }

  // ============ Internal Methods ============

  /**
   * @dev Makes a copy of a product. Maps `tokenId` to `productId`
   */
  function _makeEdition(uint256 tokenId, uint256 productId) 
    internal 
    virtual 
    isToken(tokenId) 
    isProduct(productId) 
    isNotEdition(tokenId) 
  {
    //check size
    if (productSize[productId] > 0 
      && productSupply[productId] >= productSize[productId]
    ) revert MaxEditionsReached();
    //add token to product
    productOf[tokenId] = productId;
    //add to the supply
    productSupply[productId] += 1;
  }

  /**
   * @dev Returns true if product exists
   */
  function _productExists(uint256 productId) 
    internal view virtual returns(bool) 
  {
    return bytes(productURI[productId]).length > 0;
  }

  /**
   * @dev Sets a max supply `size` for a `productId`
   */
  function _setProductSize(uint256 productId, uint256 size) 
    internal virtual
  {
    productSize[productId] = size;
  }

  /**
   * @dev Sets a fixed `uri` for a `productId`
   */
  function _setProductURI(uint256 productId, string memory uri) 
    internal virtual
  {
    productURI[productId] = uri;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC721.sol";

/**
 * @dev ERC721 contract with a URI descriptor
 */
abstract contract ERC721URIContract is ERC721 {
  //immutable contract uri
  string private _contractURI;

  /**
   * @dev The URI for contract data ex. https://creatures-api.opensea.io/contract/opensea-creatures/contract.json
   * Example Format:
   * {
   *   "name": "OpenSea Creatures",
   *   "description": "OpenSea Creatures are adorable aquatic beings primarily for demonstrating what can be done using the OpenSea platform. Adopt one today to try out all the OpenSea buying, selling, and bidding feature set.",
   *   "image": "https://openseacreatures.io/image.png",
   *   "external_link": "https://openseacreatures.io",
   *   "seller_fee_basis_points": 100, # Indicates a 1% seller fee.
   *   "fee_recipient": "0xA97F337c39cccE66adfeCB2BF99C1DdC54C2D721" # Where seller fees will be paid to.
   * }
   */
  function contractURI() external view returns (string memory) {
    return _contractURI;
  }

  /**
   * @dev Sets contract uri
   */
  function _setContractURI(string memory uri) internal virtual {
    _contractURI = uri;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

error BalanceQueryZeroAddress();
error ExistentToken();
error NonExistentToken();
error ApprovalToCurrentOwner();
error ApprovalOwnerIsOperator();
error NotOwnerOrApproved();
error NotERC721Receiver();
error TransferToZeroAddress();
error InvalidAmount();
error ERC721ReceiverNotReceived();
error TransferFromNotOwner();

abstract contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
  using Address for address;
  using Strings for uint256;

  // ============ Storage ============

  // Token name
  string private _name;
  // Token symbol
  string private _symbol;
  // Total supply
  uint256 private _totalSupply;

  // Mapping from token ID to owner address
  mapping(uint256 => address) private _owners;
  // Mapping owner address to token count
  mapping(address => uint256) private _balances;

  // Mapping from token ID to approved address
  mapping(uint256 => address) private _tokenApprovals;
  // Mapping from owner to operator approvals
  mapping(address => mapping(address => bool)) private _operatorApprovals;

  // ============ Modifiers ============

  modifier isToken(uint256 tokenId) {
    //make sure there is a product
    if (!_exists(tokenId)) revert NonExistentToken();
    _;
  }

  modifier isNotToken(uint256 tokenId) {
    //make sure there is a product
    if (_exists(tokenId)) revert ExistentToken();
    _;
  }

  // ============ Deploy ============

  /**
   * @dev Initializes the contract by setting a `name` and a `symbol` 
   * to the token collection.
   */
  constructor(string memory name_, string memory symbol_) {
    _name = name_;
    _symbol = symbol_;
  }

  // ============ Read Methods ============

  /**
   * @dev See {IERC721-balanceOf}.
   */
  function balanceOf(address owner) 
    public view virtual override returns(uint256) 
  {
    if (owner == address(0)) revert BalanceQueryZeroAddress();
    return _balances[owner];
  }

  /**
   * @dev See {IERC721Metadata-name}.
   */
  function name() public view virtual override returns(string memory) {
    return _name;
  }

  /**
   * @dev See {IERC721-ownerOf}.
   */
  function ownerOf(uint256 tokenId) 
    public view virtual override isToken(tokenId) returns(address) 
  {
    return _owners[tokenId];
  }

  /**
   * @dev See {IERC165-supportsInterface}.
   */
  function supportsInterface(bytes4 interfaceId) 
    public view virtual override(ERC165, IERC165) returns(bool) 
  {
    return
      interfaceId == type(IERC721).interfaceId ||
      interfaceId == type(IERC721Metadata).interfaceId ||
      super.supportsInterface(interfaceId);
  }

  /**
   * @dev See {IERC721Metadata-symbol}.
   */
  function symbol() public view virtual override returns(string memory) {
    return _symbol;
  }
  
  /**
   * @dev Shows the overall amount of tokens generated in the contract
   */
  function totalSupply() public virtual view returns (uint256) {
    return _totalSupply;
  }

  // ============ Approval Methods ============

  /**
   * @dev See {IERC721-approve}.
   */
  function approve(address to, uint256 tokenId) public virtual override {
    address owner = ERC721.ownerOf(tokenId);
    if (to == owner) revert ApprovalToCurrentOwner();

    address sender = _msgSender();
    if (sender != owner && !isApprovedForAll(owner, sender)) 
      revert ApprovalToCurrentOwner();

    _approve(to, tokenId, owner);
  }

  /**
   * @dev See {IERC721-getApproved}.
   */
  function getApproved(uint256 tokenId) 
    public view virtual override isToken(tokenId) returns(address) 
  {
    return _tokenApprovals[tokenId];
  }

  /**
   * @dev See {IERC721-isApprovedForAll}.
   */
  function isApprovedForAll(address owner, address operator) 
    public view virtual override returns (bool) 
  {
    return _operatorApprovals[owner][operator];
  }

  /**
   * @dev See {IERC721-setApprovalForAll}.
   */
  function setApprovalForAll(address operator, bool approved) 
    public virtual override 
  {
    _setApprovalForAll(_msgSender(), operator, approved);
  }

  /**
   * @dev Approve `to` to operate on `tokenId`
   *
   * Emits a {Approval} event.
   */
  function _approve(address to, uint256 tokenId, address owner) 
    internal virtual 
  {
    _tokenApprovals[tokenId] = to;
    emit Approval(owner, to, tokenId);
  }

  /**
   * @dev Returns whether `spender` is allowed to manage `tokenId`.
   *
   * Requirements:
   *
   * - `tokenId` must exist.
   */
  function _isApprovedOrOwner(
      address spender, 
      uint256 tokenId, 
      address owner
  ) internal view virtual returns(bool) {
    return spender == owner 
      || getApproved(tokenId) == spender 
      || isApprovedForAll(owner, spender);
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
    if (owner == operator) revert ApprovalOwnerIsOperator();
    _operatorApprovals[owner][operator] = approved;
    emit ApprovalForAll(owner, operator, approved);
  }

  // ============ Transfer Methods ============

  /**
   * @dev See {IERC721-transferFrom}.
   */
  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public virtual override {
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
    _safeTransfer(from, to, tokenId, _data);
  }
  
  /**
   * @dev Burns `tokenId`. See {ERC721B-_burn}.
   *
   * Requirements:
   *
   * - The caller must own `tokenId` or be an approved operator.
   */
  function _burn(uint256 tokenId) internal virtual {
    address owner = ERC721.ownerOf(tokenId);

    if (!_isApprovedOrOwner(_msgSender(), tokenId, owner)) 
      revert NotOwnerOrApproved();

    _beforeTokenTransfer(owner, address(0), tokenId);

    // Clear approvals
    _approve(address(0), tokenId, owner);

    unchecked {
      _owners[tokenId] = address(0);
      _balances[owner] -= 1;
      _totalSupply--;
    }

    emit Transfer(owner, address(0), tokenId);
  }

  /**
   * @dev Internal function to invoke {IERC721Receiver-onERC721Received} 
   * on a target address. The call is not executed if the target address 
   * is not a contract.
   */
  function _checkOnERC721Received(
    address from,
    address to,
    uint256 tokenId,
    bytes memory _data
  ) private returns (bool) {
    try IERC721Receiver(to).onERC721Received(
      _msgSender(), from, tokenId, _data
    ) returns (bytes4 retval) {
      return retval == IERC721Receiver.onERC721Received.selector;
    } catch (bytes memory reason) {
      if (reason.length == 0) {
        revert NotERC721Receiver();
      } else {
        assembly {
          revert(add(32, reason), mload(reason))
        }
      }
    }
  }

  /**
   * @dev Returns whether `tokenId` exists.
   *
   * Tokens can be managed by their owner or approved accounts via 
   * {approve} or {setApprovalForAll}.
   *
   * Tokens start existing when they are minted (`_mint`),
   * and stop existing when they are burned (`_burn`).
   */
  function _exists(uint256 tokenId) internal view virtual returns (bool) {
    return _owners[tokenId] != address(0);
  }

  /**
   * @dev Mints `tokenId` and transfers it to `to`.
   *
   * WARNING: Usage of this method is discouraged, use {_safeMint} 
   * whenever possible
   *
   * Requirements:
   *
   * - `tokenId` must not exist.
   * - `to` cannot be the zero address.
   *
   * Emits a {Transfer} event.
   */
  function _mint(
    address to,
    uint256 tokenId,
    bytes memory _data,
    bool safeCheck
  ) internal virtual isNotToken(tokenId) {
    if (to == address(0)) revert TransferToZeroAddress();

    _beforeTokenTransfer(address(0), to, tokenId);

    _balances[to] += 1;
    _owners[tokenId] = to;
    _totalSupply++;

    //if do safe check
    if (safeCheck 
      && to.isContract() 
      && !_checkOnERC721Received(address(0), to, tokenId, _data)
    ) revert ERC721ReceiverNotReceived();

    emit Transfer(address(0), to, tokenId);
  }

  /**
   * @dev Safely mints `tokenId` and transfers it to `to`.
   *
   * Requirements:
   *
   * - `tokenId` must not exist.
   * - If `to` refers to a smart contract, it must implement 
   *   {IERC721Receiver-onERC721Received}, which is called upon a 
   *   safe transfer.
   *
   * Emits a {Transfer} event.
   */
  function _safeMint(address to, uint256 amount) internal virtual {
    _safeMint(to, amount, "");
  }

  /**
   * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], 
   * with an additional `data` parameter which is forwarded in 
   * {IERC721Receiver-onERC721Received} to contract recipients.
   */
  function _safeMint(
    address to,
    uint256 amount,
    bytes memory _data
  ) internal virtual {
    _mint(to, amount, _data, true);
  }

  /**
   * @dev Safely transfers `tokenId` token from `from` to `to`, checking 
   * first that contract recipients are aware of the ERC721 protocol to 
   * prevent tokens from being forever locked.
   *
   * `_data` is additional data, it has no specified format and it is 
   * sent in call to `to`.
   *
   * This internal function is equivalent to {safeTransferFrom}, and can 
   * be used to e.g.
   * implement alternative mechanisms to perform token transfer, such as 
   * signature-based.
   *
   * Requirements:
   *
   * - `from` cannot be the zero address.
   * - `to` cannot be the zero address.
   * - `tokenId` token must exist and be owned by `from`.
   * - If `to` refers to a smart contract, it must implement 
   *   {IERC721Receiver-onERC721Received}, which is called upon a 
   *   safe transfer.
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
    if (to.isContract() 
      && !_checkOnERC721Received(from, to, tokenId, _data)
    ) {
        revert ERC721ReceiverNotReceived();
    }
  }

  /**
   * @dev Transfers `tokenId` from `from` to `to`. As opposed to 
   * {transferFrom}, this imposes no restrictions on msg.sender.
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
    if (to == address(0)) revert TransferToZeroAddress();
    //get owner
    address owner = ERC721.ownerOf(tokenId);
    //owner should be the `from`
    if (from != owner) revert TransferFromNotOwner();
    if (!_isApprovedOrOwner(_msgSender(), tokenId, owner)) 
      revert NotOwnerOrApproved();

    _beforeTokenTransfer(from, to, tokenId);

    // Clear approvals from the previous owner
    _approve(address(0), tokenId, from);

    unchecked {
      //this is the situation when _owners are normalized
      _balances[to] += 1;
      _balances[from] -= 1;
      _owners[tokenId] = to;
    }

    emit Transfer(from, to, tokenId);
  }

  // ============ TODO Methods ============

  /**
   * @dev Hook that is called before a set of serially-ordered token ids 
   * are about to be transferred. This includes minting.
   *
   * startTokenId - the first token id to be transferred
   * amount - the amount to be transferred
   *
   * Calling conditions:
   *
   * - When `from` and `to` are both non-zero, ``from``'s `tokenId` 
   *   will be transferred to `to`.
   * - When `from` is zero, `tokenId` will be minted for `to`.
   */
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/introspection/ERC165.sol)

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
// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721.sol)

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
// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721Receiver.sol)

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
// OpenZeppelin Contracts v4.4.0 (token/ERC721/extensions/IERC721Metadata.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/Address.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/Strings.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/introspection/IERC165.sol)

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
// OpenZeppelin Contracts v4.4.0 (security/Pausable.sol)

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
    constructor() {
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
// OpenZeppelin Contracts v4.4.0 (token/ERC20/utils/SafeERC20.sol)

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
// OpenZeppelin Contracts v4.4.0 (security/ReentrancyGuard.sol)

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

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";

error AssignmentToZeroAddress();
error CallerNotOwner();
error CallerNotOperator();
error CallerNotOwnerOperator();

abstract contract OwnerOperator is Context {
  // ============ Events ============

  event OwnershipTransferred(address indexed previous, address indexed next);
  event OperatorTransferred(address indexed previous, address indexed next);

  // ============ Storage ============

  address public _owner;
  address public _operator;

  // ============ Modifiers ============

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner {
    if (_owner != _msgSender()) revert CallerNotOwner();
    _;
  }

  /**
   * @dev Throws if called by any account other than the operator.
   */
  modifier onlyOperator {
    if (_operator != _msgSender()) revert CallerNotOwner();
    _;
  }

  /**
   * @dev Throws if called by any account other than the owner or operator.
   */
  modifier onlyOwnerOperator {
    address sender = _msgSender();
    if (sender != _owner && sender != _operator) 
      revert CallerNotOwnerOperator();
    _;
  }

  // ============ Read Methods ============

  function owner() public virtual view returns(address) {
    return _owner;
  }

  function operator() public virtual view returns(address) {
    return _operator;
  }

  // ============ Write Methods ============

  /**
   * @dev Transfers operator of the contract to `newOperator`.
   */
  function transferOperator(address newOperator) public virtual onlyOwnerOperator {
    if (newOperator == address(0)) revert AssignmentToZeroAddress();
    _transferOperator(newOperator);
  }

  /**
   * @dev Transfers owner of the contract to `newOwner`.
   */
  function transferOwnership(address newOwner) public virtual onlyOwnerOperator {
    if (newOwner == address(0)) revert AssignmentToZeroAddress();
    _transferOwnership(newOwner);
  }

  // ============ Internal Methods ============

  /**
   * @dev Transfers operator of the contract to `newOperator`.
   */
  function _transferOperator(address newOperator) internal virtual {
    address oldOperator = _operator;
    _operator = newOperator;
    emit OperatorTransferred(oldOperator, newOperator);
  }

  /**
   * @dev Transfers owner of the contract to `newOwner`.
   */
  function _transferOwnership(address newOwner) internal virtual {
    address oldOwner = _owner;
    _owner = newOwner;
    emit OwnershipTransferred(oldOwner, newOwner);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IRoyaltySplitter {
  // ============ Events ============

  event RecipientAdded(address account, uint256 shares);
  event RecipientUpdated(address account, uint256 shares);
  event RecipientRemoved(address account);
  event RecipientsPurged();
  event PaymentReleased(address to, uint256 amount);
  event ERC20PaymentReleased(IERC20 indexed token, address to, uint256 amount);
  event PaymentReceived(address from, uint256 amount);

  // ============ Read Methods ============

  /**
   * @dev Getter for the address of the payee number `index`.
   */
  function recipient(uint256 index) external view returns(address);

  /**
   * @dev Getter for the amount of Ether already released to a payee.
   */
  function released(address account) external view returns(uint256);

  /**
   * @dev Getter for the amount of `token` tokens already released to a 
   * payee. `token` should be the address of an IERC20 contract.
   */
  function released(IERC20 token, address account) 
    external view returns(uint256);

  /**
   * @dev Getter for the amount of shares held by an account.
   */
  function shares(address account) external view returns(uint256);

  /**
   * @dev Getter for the total amount of Ether already released.
   */
  function totalReleased() external view returns(uint256);

  /**
   * @dev Getter for the total amount of `token` already released. 
   * `token` should be the address of an IERC20 contract.
   */
  function totalReleased(IERC20 token) external view returns(uint256);

  /**
   * @dev Getter for the total shares held by recipients.
   */
  function totalShares() external view returns(uint256);

  // ============ Write Methods ============

  /**
   * @dev Triggers a transfer to `account` of the amount of Ether they 
   * are owed, according to their percentage of the total shares and 
   * their previous withdrawals.
   */
  function release(address payable account) 
    external;

  /**
   * @dev Triggers a transfer to `account` of the amount of `token` 
   * tokens they are owed, according to their percentage of the total 
   * shares and their previous withdrawals. `token` must be the address 
   * of an IERC20 contract.
   */
  function release(IERC20 token, address account) 
    external;

  // ============ Admin Methods ============

  /**
   * @dev Considers tokens that can be vaulted
   */
  function accept(IERC20 token) 
    external;

  /**
   * @dev Add a new `account` to the contract.
   */
  function addRecipient(address account, uint256 shares_) 
    external;

  function batchUpdate(
    address[] memory recipients_, 
    uint256[] memory shares_
  ) external;

  /**
   * @dev Removes a `recipient`
   */
  function removeRecipient(uint256 index) 
    external;

  /**
   * @dev Update a `recipient`
   */
  function updateRecipient(address account, uint256 shares_) 
    external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

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
    function transferFrom(
        address sender,
        address recipient,
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