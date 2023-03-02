// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "./lib/interface.sol";
import "./lib/SafeMath.sol";
import "./lib/Verify.sol";

contract BlindBoxApe is OwnableUpgradeable, Verify {
    using SafeMath for uint256;
    uint256 public seed;
    IERC721Upgradeable public ERC721;
    IERC20 public tokenFT;
    string public name;
    uint256 public salt;
    mapping(address => bool) public admin;
    // box id => bool
    mapping(uint256 => bool) public canceled;
    // box id => bool
    mapping(uint256 => bool) public deleted;
    // box id => bool
    mapping(uint256 => bool) public histories;
    // box id => uint256
    mapping(uint256 => uint256) public totalSell;
    // user => (box id => uint256)
    mapping(address => mapping(uint256 => uint256)) public userPurchase;
    // box id => Box
    mapping(uint256 => Box) public boxs;
    // box id => token id list
    mapping(uint256 => uint256[]) public tokenByIndex;
    mapping(uint256 => bool) public soldOut;

    struct CreateReq {
      string name;
      uint256 startTime;
      uint256 endTime;
      uint256 totalSupply;
      uint256 price;
      uint256 propsNum;
      uint256 weightProp;
      uint256[] tokenids;
      uint256 tokenNum;
      uint256 purchaseLimit;
      IERC20 token;
    }

    struct Box {
        string name;
        uint256 startTime;
        uint256 endTime;
        uint256 totalSupply;
        uint256 price;
        uint256 propsNum;
        uint256 weightProp;
        uint256[] tokenids;
        uint256 tokenNum;
        uint256 purchaseLimit;
        IERC20 token;
    }

    event CreateBox(uint256 boxId, Box box);
    event Cancel(uint256 boxId, uint256 totalSupply, uint256 unSupply);
    event Delete(uint256 boxId, uint256 totalSupply, uint256 unSupply);
    event BuyBox(address sender, uint256 boxId);
    event BuyBoxes(address sender, uint256 boxId, uint256 quantity);
    event UpdateBox(uint256 boxId, Box _box, Box box);

    function initialize(string memory _name)
        public
        initializer
    {
        name = _name;
        __Ownable_init();
    }

    function createBox(uint256 id, CreateReq memory req) external onlyAdmin {
        //require(bytes(req.name).length <= 15, "CreateBox: length of name is too long");
        require(req.endTime > req.startTime && req.endTime > block.timestamp, "CreateBox: time error");
        require(req.totalSupply > 0, "CreateBox: totalSupply error");
        require(req.totalSupply.mul(req.propsNum) <= req.tokenids.length, "CreateBox: token id not enought");
        require(req.tokenNum > 0, "CreateBox: tokenNum error");
        //require(req.price >= 0, "CreateBox: price error");
        require(!histories[id] || (histories[id] && deleted[id]), "CreateBox: duplicate box id");

        Box memory box;
        box.name = req.name;
        box.startTime = req.startTime;
        box.endTime = req.endTime;
        box.totalSupply = req.totalSupply;
        box.price = req.price.mul(1e16);
        box.propsNum = req.propsNum;
        box.weightProp = req.weightProp;
        box.tokenNum = req.tokenNum.mul(1e16);
        box.purchaseLimit = req.purchaseLimit;
        box.token = req.token;

        delete tokenByIndex[id];
        tokenByIndex[id] = req.tokenids;

        boxs[id] = box;
        histories[id] = true;
        deleted[id] = false;
        emit CreateBox(id, box);
    }

    function buyBoxes(uint256 _id, uint256 _quantity, bytes memory _data) external payable {
        _buyBoxes(_id, _quantity, _data);
    }

    function buyBox(uint256 _id, bytes memory _data) external payable {
        _buyBoxes(_id, 1, _data);
        emit BuyBox(msg.sender, _id);
    }

    function _buyBoxes(uint256 _id, uint256 _quantity, bytes memory _data) internal {
        require(_quantity > 0, "BuyBox: the number of buy box must be greater than 0");
        bytes32 _hash = keccak256(abi.encodePacked(msg.sender, _id, salt));
        require(verify(_hash, _data), "buyBox: Authentication failed");

        require(tx.origin == msg.sender, "BuyBox: invalid caller");
        require(histories[_id] && !deleted[_id], "BuyBox: box is not exist");
        require(!canceled[_id], "BuyBox: box does not to sell");

        Box memory box = boxs[_id];
        require(block.timestamp > box.startTime && block.timestamp < box.endTime, "BuyBox: no this time");
        require(!soldOut[_id], "BuyBox: box is sold out");
        require(box.totalSupply >= totalSell[_id].add(_quantity), "BuyBox: insufficient supply");
        require(box.purchaseLimit == 0 || box.purchaseLimit >= userPurchase[msg.sender][_id].add(_quantity), "BuyBox: not enought quota");
        require(box.price.mul(_quantity) == msg.value, "BuyBox: invalid amount");


        for (uint256 j=0; j<_quantity; j++){
          seed = seed.add(box.propsNum);

          for (uint256 i=0; i<box.propsNum.sub(randomTimes(box.propsNum, box.weightProp)); i++) {
            uint256 _tokenID = randomDraw(_id);
            ERC721.transferFrom(address(this), msg.sender, _tokenID);
          }
        }

        totalSell[_id] = totalSell[_id].add(_quantity);
        userPurchase[msg.sender][_id] = userPurchase[msg.sender][_id].add(_quantity);
        if (box.totalSupply <= totalSell[_id]) {
          soldOut[_id] = true;
        }
        emit BuyBoxes(msg.sender, _id, _quantity);
    }

    function randomTimes(uint256 len, uint256 weight) internal returns(uint256) {
      uint256 times;
      for (uint256 i=0; i<len; i++) {
        if (randomNum(100) >= weight) {
          times = times.add(1);
        }
      }
      return times;
    }

    function randomNum(uint256 range) internal returns(uint256){
      seed = seed.add(1);
      return uint256(keccak256(abi.encodePacked(seed, block.difficulty, block.gaslimit, block.number, block.timestamp))).mod(range);
    }

    function randomDraw(uint256 _id) internal returns(uint256) {
      uint256 _num = randomNum(tokenByIndex[_id].length);
      require(tokenByIndex[_id].length > _num, "random out of range");
      require(tokenByIndex[_id].length > 0, "index out of range");

      uint256 lastIndex = tokenByIndex[_id].length.sub(1);
      uint256 tokenId = tokenByIndex[_id][_num];
      if (_num != lastIndex) {
        tokenByIndex[_id][_num] = tokenByIndex[_id][lastIndex];
      }
      tokenByIndex[_id].pop();
      return tokenId;
    }

    function setBoxOpen(uint256 _id, bool _open) external onlyAdmin {
        require(!deleted[_id], "SetBoxOpen: box has been deleted");
        require(histories[_id], "SetBoxOpen: box is not exist");
        Box memory box = boxs[_id];
        canceled[_id] = _open;
        emit Cancel(_id, box.totalSupply, box.totalSupply.sub(totalSell[_id]));
    }

    function deleteBox(uint256 _id) external onlyAdmin {
        require(!deleted[_id], "DeleteBox: box has been deleted");
        require(histories[_id], "DeleteBox: box is not exist");
        Box memory box = boxs[_id];
        deleted[_id] = true;
        delete tokenByIndex[_id];
        emit Delete(_id, box.totalSupply, box.totalSupply.sub(totalSell[_id]));
    }

    function updateBox(uint256 _id, CreateReq memory req) external onlyAdmin {
        require(histories[_id], "UpdateBox: box id not found");
        //require(bytes(req.name).length <= 15, "UpdateBox: length of name is too long");
        require(req.endTime > req.startTime && req.endTime > block.timestamp, "UpdateBox: time error");
        require(req.tokenNum > 0, "UpdateBox: tokenNum error");
        //require(req.price > 0, "UpdateBox: price error");

        Box memory box = boxs[_id];
        box.name = req.name;
        box.startTime = req.startTime;
        box.endTime = req.endTime;
        box.price = req.price.mul(1e16);
        box.weightProp = req.weightProp;
        box.tokenNum = req.tokenNum.mul(1e16);
        box.purchaseLimit = req.purchaseLimit;
        box.token = req.token;
        boxs[_id] = box;
    }

    function setTokenFT(IERC20 _tokenFT) external onlyAdmin {
      tokenFT = _tokenFT;
    }

    function setToken721(IERC721Upgradeable _erc721) external onlyAdmin {
        ERC721 = _erc721;
    }

    function getAmountFT() external view returns(uint256){
      return tokenFT.balanceOf(address(this));
    }

    function getAmountToken(IERC20 token) external view returns(uint256) {
      return token.balanceOf(address(this));
    }

    function getAvailableToken(uint256 _id) external view returns(uint256[] memory) {
      return tokenByIndex[_id];
    }

    function setAdmin(address user, bool _auth) external onlyOwner {
        admin[user] = _auth;
    }

    function setSalt(uint256 _salt) external onlyOwner {
      salt = _salt;
    }

    function onERC721Received(address, address, uint, bytes calldata) external pure returns (bytes4) {
        return this.onERC721Received.selector;
    }

    modifier onlyAdmin() {
        require(
            admin[msg.sender] || owner() == msg.sender,
            "Admin: caller is not the admin"
        );
        _;
    }
    
    function withdraw(address _to) public onlyOwner {
        payable(_to).transfer(address(this).balance);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721Upgradeable.sol";
import "./IERC721ReceiverUpgradeable.sol";
import "./extensions/IERC721MetadataUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../utils/StringsUpgradeable.sol";
import "../../utils/introspection/ERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721Upgradeable is Initializable, ContextUpgradeable, ERC165Upgradeable, IERC721Upgradeable, IERC721MetadataUpgradeable {
    using AddressUpgradeable for address;
    using StringsUpgradeable for uint256;

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
    function __ERC721_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC721_init_unchained(name_, symbol_);
    }

    function __ERC721_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return
            interfaceId == type(IERC721Upgradeable).interfaceId ||
            interfaceId == type(IERC721MetadataUpgradeable).interfaceId ||
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
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721Upgradeable.ownerOf(tokenId);
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
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
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
        address owner = ERC721Upgradeable.ownerOf(tokenId);

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
        require(ERC721Upgradeable.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
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
        emit Approval(ERC721Upgradeable.ownerOf(tokenId), to, tokenId);
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
            try IERC721ReceiverUpgradeable(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721ReceiverUpgradeable.onERC721Received.selector;
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[44] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

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

pragma solidity ^0.8.0;

interface IERC721 {
    event Mint(address indexed to, uint256 indexed tokenId);

    function adminMintTo(address to, uint256 tokenId) external;
}

interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external;

    function transfer(address recipient, uint256 amount) external;

    function balanceOf(address account) external view returns (uint256);

    function adminMint(address account, uint256 amount) external;
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

library SafeMath {

    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(x >= y, "SafeMath: sub underflow");
        require((z = x - y) <= x, 'ds-math-sub-underflow');
        z = x - y;
        return z;
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";

contract Verify is OwnableUpgradeable {
    using SafeMathUpgradeable for uint256;
    address private publicKey;


    function verify(bytes32 hashMessage, bytes memory _data)internal view returns (bool) {
        bool auth;
        bytes32 _r = bytes2bytes32(slice(_data, 0, 32));
        bytes32 _s = bytes2bytes32(slice(_data, 32, 32));
        bytes1 v = slice(_data, 64, 1)[0];
        uint8 _v = uint8(v) + 27;

        address addr = ecrecover(hashMessage, _v, _r, _s);
        if (publicKey == addr) {
            auth = true;
        }
        return auth;
    }

    function slice(bytes memory data, uint256 start, uint256 len) internal pure returns (bytes memory) {
        bytes memory b = new bytes(len);
        for (uint256 i = 0; i < len; i++) {
            b[i] = data[i + start];
        }
        return b;
    }

    function bytes2bytes32(bytes memory _source) internal pure returns (bytes32 result){
        assembly {
            result := mload(add(_source, 32))
        }
    }

    function setPublicKey(address _key) external onlyOwner {
        publicKey = _key;
    }
    
    function getPublicKey() external view onlyOwner returns (address){
        return publicKey;
    }
}

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
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
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
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = _setInitializedVersion(1);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        bool isTopLevelCall = _setInitializedVersion(version);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(version);
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        _setInitializedVersion(type(uint8).max);
    }

    function _setInitializedVersion(uint8 version) private returns (bool) {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, and for the lowest level
        // of initializers, because in other contexts the contract may have been reentered.
        if (_initializing) {
            require(
                version == 1 && !AddressUpgradeable.isContract(address(this)),
                "Initializable: contract is already initialized"
            );
            return false;
        } else {
            require(_initialized < version, "Initializable: contract is already initialized");
            _initialized = version;
            return true;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
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
library SafeMathUpgradeable {
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./lib/Verify.sol";

interface MintNfter {
    function adminMintTo(address to, uint256 tokenId) external;
}

contract FreeMintAction is OwnableUpgradeable, Verify {
    MintNfter public nftContract;
    struct Config {
        uint128 nonce;
        uint128 price;
    }

    Config public cfg;

    mapping(bytes32 => bool) public claimed;
    event Claimed(
        address to,
        uint256 serverId,
        uint256 payerId,
        uint256 relicsId,
        uint256 tokenId
    );

    function initialize(MintNfter _impl, Config memory _cfg)
        public
        initializer
    {
        nftContract = _impl;
        __Ownable_init();
        setConfig(_cfg);
    }

    /// @dev TokenId for mint nft
    /// @dev Each mint nft, nonce will add 1
    /// @dev mint nft is mint nonce
    /// @dev price: 1000 = 1 ether, 1 = 0.001 ether
    function setConfig(Config memory _cfg) public onlyOwner {
        require(
            _cfg.nonce > cfg.nonce,
            "_nonce must be greater than origin nonce"
        );
        cfg.nonce = _cfg.nonce;
        cfg.price = _cfg.price;
    }

    function setNft(MintNfter _impl) external onlyOwner {
        nftContract = _impl;
    }

    /// @notice Entrance of user mint art nft
    /// @param _data sign data, keccak256(abi.encodePacked(msg.sender, _serverId, _payerId, _relicsId));
    function claim(
        uint256 _serverId,
        uint256 _payerId,
        uint256 _relicsId,
        bytes memory _data
    ) external payable {
        address sender = _msgSender();
        bytes32 _hash = keccak256(
            abi.encodePacked(sender, _serverId, _payerId, _relicsId)
        );
        bytes32 _onlyHash = keccak256(
            abi.encodePacked(_serverId, _payerId, _relicsId)
        );

        require(verify(_hash, _data), "Authentication failed");
        require(!claimed[_onlyHash], "Already minted");
        require(msg.value == cfg.price * 1e15, "Invalid amount");

        nftContract.adminMintTo(sender, cfg.nonce);
        claimed[_onlyHash] = true;
        emit Claimed(sender, _serverId, _payerId, _relicsId, cfg.nonce);
        cfg.nonce++;
    }

    /// @notice Withdraw the balance of the contract
    /// @param _to Withdraw the balance of the contract to `_to`
    function withdraw(address _to) external onlyOwner {
        payable(_to).transfer(address(this).balance);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract Configurable is OwnableUpgradeable {

    mapping (bytes32 => uint256) internal config;
    
    function getConfig(bytes32 key) public view returns (uint256) {
        return config[key];
    }
    function getConfig(bytes32 key, uint256 index) public view returns (uint256) {
        return config[bytes32(uint256(key) ^ index)];
    }
    function getConfig(bytes32 key, address addr) public view returns (uint256) {
        return config[bytes32(uint256(key) ^ uint256(uint160(addr)))];
    }

    function _setConfig(bytes32 key, uint256 value) internal {
        if(config[key] != value)
            config[key] = value;
    }

    function _setConfig(bytes32 key, uint256 index, uint256 value) internal {
        _setConfig(bytes32(uint256(key) ^ index), value);
    }

    function _setConfig(bytes32 key, address addr, uint256 value) internal {
        _setConfig(bytes32(uint256(key) ^ uint256(uint160(addr))), value);
    }
    
    function setConfig(bytes32 key, uint256 value) external onlyOwner {
        _setConfig(key, value);
    }

    function setConfig(bytes32 key, uint256 index, uint256 value) external onlyOwner {
        _setConfig(bytes32(uint256(key) ^ index), value);
    }
    
    function setConfig(bytes32 key, address addr, uint256 value) public onlyOwner {
        _setConfig(bytes32(uint256(key) ^ uint256(uint160(addr))), value);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "./lib/Governable.sol";
import "./lib/interface.sol";


contract SwapAPE is Configurable {
    using SafeMathUpgradeable for uint256;

    mapping(uint256 => uint256) public finished;
    mapping(uint256 => uint256) public totalSwapA;
    mapping(uint256 => uint256) public totalSwapB;
    mapping(address => mapping(uint256 => uint256)) public userTotalSwapA;
    mapping(address => mapping(uint256 => uint256)) public userTotalSwapB;
    mapping(address => mapping(uint256 => bool)) public canceled;
    mapping(uint256 => uint256) public swapTxFee;
    uint256 internal constant PoolTypeSell = 0;
    uint256 internal constant PoolTypeBuy = 1;
    bytes32 internal constant TxFeeRatio            = bytes32("TxFeeRatio");
    bytes32 internal constant MinValueOfBotHolder   = bytes32("MinValueOfBotHolder");

    struct CreateReq {
        // tokenA swap to tokenB
        string name;
        IERC20 tokenA;
        IERC20 tokenB;
        uint256 totalAmountA;
        uint256 totalAmountB;
        uint256 poolType;
    }

    struct Pool {
        string name;
        address creator;
        IERC20 tokenA;
        IERC20 tokenB;
        uint256 totalAmountA;
        uint256 totalAmountB;
        uint256 poolType;
    }

    Pool[] public pools;
    event Created(uint indexed index, address indexed sender, Pool pool);
    event Cancel(uint256 indexed index, address indexed sender, uint256 amountA, uint256 txFee);
    event Swapped(uint256 indexed index, address indexed sender, uint256 amountA, uint256 amountB, uint256 txFee);


    function initialize(uint256 txFeeRatio, uint256 minBotHolder) public initializer {
        super.__Ownable_init();
        config[TxFeeRatio] = txFeeRatio;
        config[MinValueOfBotHolder] = minBotHolder;
    }

    function create(CreateReq memory req) external payable {
        // create pool, transfer tokenA to pool
        uint256 index = pools.length;
        require(tx.origin == msg.sender, "invalid caller");
        require(req.totalAmountA != 0 && req.totalAmountB != 0, "invalid total amount");
        require(req.poolType == PoolTypeSell || req.poolType == PoolTypeBuy, "invalid poolType");
        require(bytes(req.name).length <= 15, "length of name is too long");
        // require(req.tokenA != address(0) && req.tokenB != address(0), "invalid token address");
        uint tokenABalanceBefore = req.tokenA.balanceOf(address(this));
        req.tokenA.transferFrom(msg.sender, address(this), req.totalAmountA);
        require(req.tokenA.balanceOf(address(this)).sub(tokenABalanceBefore) == req.totalAmountA,"not support deflationary token");
        Pool memory pool;
        pool.name = req.name;
        pool.creator = msg.sender;
        pool.tokenA = req.tokenA;
        pool.tokenB = req.tokenB;
        pool.totalAmountA = req.totalAmountA;
        pool.totalAmountB = req.totalAmountB;
        pool.poolType = req.poolType;
        pools.push(pool);
        emit Created(index, msg.sender, pool);
    }

    function swap(uint index, uint amountB) external isPoolExist(index) {
        address sender = msg.sender;
        Pool memory pool = pools[index];
        require(tx.origin == msg.sender, "invalid caller");
        require(!canceled[msg.sender][index], "Swap: pool has been cancel");
        require(pool.totalAmountB > totalSwapB[index], "Swap: amount is zero");

        uint256 spillAmountB = 0;
        uint256 _amountB = pool.totalAmountB.sub(totalSwapB[index]);
        if (_amountB > amountB) {
            _amountB = amountB;
        } else {
            spillAmountB = amountB.sub(_amountB);
        }

        uint256 amountA = _amountB.mul(pool.totalAmountA).div(pool.totalAmountB);
        uint256 _amountA = pool.totalAmountA.sub(totalSwapA[index]);
        if (_amountA > amountA) {
            _amountA = amountA;
        }

        totalSwapA[index] = totalSwapA[index].add(_amountA);
        totalSwapB[index] = totalSwapB[index].add(_amountB);
        userTotalSwapA[sender][index] = userTotalSwapA[sender][index].add(_amountA);
        userTotalSwapB[sender][index] = userTotalSwapB[sender][index].add(_amountB);

        if (pool.totalAmountB == totalSwapB[index]) {
            finished[index] = block.timestamp;
        }

        if (spillAmountB > 0) {
            pool.tokenB.transfer(msg.sender, spillAmountB);
        }

        pool.tokenB.transferFrom(msg.sender, address(this), amountB);
        pool.tokenA.transfer(msg.sender, _amountA);

        uint256 fee = _amountB.mul(getTxFeeRatio()).div(10000);
        swapTxFee[index] = swapTxFee[index].add(fee);
        uint256 _realAmountB = _amountB.sub(fee);
        if (_realAmountB > 0) {
            pool.tokenB.transfer(pool.creator, _realAmountB);
        }
        emit Swapped(index, msg.sender, _amountA, _realAmountB, fee);
    }

    function cancel(uint256 index) external {
        require(index < pools.length, "this pool does not exist");
        Pool memory pool = pools[index];
        require(msg.sender == pool.creator, "Cancel: not creator");
        require(!canceled[msg.sender][index], "Cancel: canceled");
        canceled[msg.sender][index] = true;

        uint256 unSwapAmount = pool.totalAmountA.sub(totalSwapA[index]);
        if (unSwapAmount > 0) {
            pool.tokenA.transfer(pool.creator, unSwapAmount);
        }

        emit Cancel(index, msg.sender, unSwapAmount, 0);
    }

    function getTxFeeRatio() public view returns (uint) {
        return config[TxFeeRatio];
    }

    function getPoolCount() public view returns (uint) {
        return pools.length;
    }

    function setTxFeeRatio(uint256 _txFeeRatio) external onlyOwner {
        config[TxFeeRatio] = _txFeeRatio;
    }

    modifier isPoolExist(uint index) {
        require(index < pools.length, "this pool does not exist");
        _;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "./lib/interface.sol";
import "./lib/SafeMath.sol";
import "./lib/Verify.sol";

contract BlindBox is OwnableUpgradeable, Verify {
    using SafeMath for uint256;
    uint256 public seed;
    IERC721 public ERC721;
    IERC20 public tokenFT;
    string public name;
    uint256 public solt;
    mapping(address => bool) public admin;
    // box id => bool
    mapping(uint256 => bool) public canceled;
    // box id => bool
    mapping(uint256 => bool) public deleted;
    // box id => bool
    mapping(uint256 => bool) public histories;
    // box id => uint256
    mapping(uint256 => uint256) public totalSell;
    // user => (box id => uint256)
    mapping(address => mapping(uint256 => uint256)) public userPurchase;
    // box id => Box
    mapping(uint256 => Box) public boxs;
    // box id => token id list
    mapping(uint256 => uint256[]) public tokenByIndex;
    mapping(uint256 => bool) public soldOut;

    struct CreateReq {
      string name;
      uint256 startTime;
      uint256 endTime;
      uint256 totalSupply;
      uint256 price;
      uint256 propsNum;
      uint256 weightProp;
      uint256[] tokenids;
      uint256 tokenNum;
      uint256 purchaseLimit;
      IERC20 token;
    }

    struct Box {
        string name;
        uint256 startTime;
        uint256 endTime;
        uint256 totalSupply;
        uint256 price;
        uint256 propsNum;
        uint256 weightProp;
        uint256[] tokenids;
        uint256 tokenNum;
        uint256 purchaseLimit;
        IERC20 token;
    }

    event CreateBox(uint256 boxId, Box box);
    event Cancel(uint256 boxId, uint256 totalSupply, uint256 unSupply);
    event Delete(uint256 boxId, uint256 totalSupply, uint256 unSupply);
    event BuyBox(address sender, uint256 boxId);
    event BuyBoxes(address sender, uint256 boxId, uint256 quantity);
    event UpdateBox(uint256 boxId, Box _box, Box box);
    event GetNFTByBox(address indexed to, uint256 indexed boxId, uint256 indexed tokenId);

    function initialize(string memory _name)
        public
        initializer
    {
        name = _name;
        __Ownable_init();
    }

    function createBox(uint256 id, CreateReq memory req) external onlyAdmin {
        //require(bytes(req.name).length <= 15, "CreateBox: length of name is too long");
        require(req.endTime > req.startTime && req.endTime > block.timestamp, "CreateBox: time error");
        require(req.totalSupply > 0, "CreateBox: totalSupply error");
        require(req.totalSupply.mul(req.propsNum) <= req.tokenids.length, "CreateBox: token id not enought");
        require(req.tokenNum > 0, "CreateBox: tokenNum error");
        //require(req.price >= 0, "CreateBox: price error");
        require(!histories[id] || (histories[id] && deleted[id]), "CreateBox: duplicate box id");

        Box memory box;
        box.name = req.name;
        box.startTime = req.startTime;
        box.endTime = req.endTime;
        box.totalSupply = req.totalSupply;
        box.price = req.price.mul(1e16);
        box.propsNum = req.propsNum;
        box.weightProp = req.weightProp;
        box.tokenNum = req.tokenNum.mul(1e16);
        box.purchaseLimit = req.purchaseLimit;
        box.token = req.token;

        delete tokenByIndex[id];
        tokenByIndex[id] = req.tokenids;

        boxs[id] = box;
        histories[id] = true;
        deleted[id] = false;
        emit CreateBox(id, box);
    }

    function buyBoxes(uint256 _id, uint256 _quantity, bytes memory _data) external payable {
        _buyBoxes(_id, _quantity, _data);
    }

    function buyBox(uint256 _id, bytes memory data) external payable {
        _buyBoxes(_id, 1, data);
        emit BuyBox(msg.sender, _id);
    }

    function _buyBoxes(uint256 _id, uint256 _quantity, bytes memory _data) internal {
        require(_quantity > 0, "BuyBox: the number of buy box must be greater than 0");
        bytes32 _hash = keccak256(abi.encodePacked(msg.sender, _id, solt));
        require(verify(_hash, _data), "buyBox: Authentication failed");

        require(tx.origin == msg.sender, "BuyBox: invalid caller");
        require(histories[_id] && !deleted[_id], "BuyBox: box is not exist");
        require(!canceled[_id], "BuyBox: box does not to sell");

        Box memory box = boxs[_id];
        require(block.timestamp > box.startTime && block.timestamp < box.endTime, "BuyBox: no this time");
        require(!soldOut[_id], "BuyBox: box is sold out");
        require(box.totalSupply >= totalSell[_id].add(_quantity), "BuyBox: insufficient supply");
        require(box.purchaseLimit == 0 || box.purchaseLimit >= userPurchase[msg.sender][_id].add(_quantity), "BuyBox: not enought quota");
        require(box.price.mul(_quantity) == msg.value, "BuyBox: invalid amount");

        // 使用ape换成使用eth/bnb
        // box.token.transferFrom(sender, address(this), box.price);

        uint256 ftTimes;
        for (uint256 j=0; j<_quantity; j++){
          ftTimes = randomTimes(box.propsNum, box.weightProp);
          seed = seed.add(box.propsNum);

          for (uint256 i=0; i<box.propsNum.sub(ftTimes); i++) {
            uint256 _tokenID = randomDraw(_id);
            ERC721.adminMintTo(msg.sender, _tokenID);
          }

          if (ftTimes > 0) {
            tokenFT.adminMint(msg.sender, ftTimes.mul(box.tokenNum));
          }
        }

        totalSell[_id] = totalSell[_id].add(_quantity);
        userPurchase[msg.sender][_id] = userPurchase[msg.sender][_id].add(_quantity);
        if (box.totalSupply <= totalSell[_id]) {
          soldOut[_id] = true;
        }
        emit BuyBoxes(msg.sender, _id, _quantity);
    }

    function randomTimes(uint256 len, uint256 weight) internal returns(uint256) {
      uint256 times;
      for (uint256 i=0; i<len; i++) {
        if (randomNum(100) >= weight) {
          times = times.add(1);
        }
      }
      return times;
    }

    function randomNum(uint256 range) internal returns(uint256){
      seed = seed.add(1);
      return uint256(keccak256(abi.encodePacked(seed, block.difficulty, block.gaslimit, block.number, block.timestamp))).mod(range);
    }

    function randomDraw(uint256 _id) internal returns(uint256) {
      uint256 _num = randomNum(tokenByIndex[_id].length);
      require(tokenByIndex[_id].length > _num, "random out of range");
      require(tokenByIndex[_id].length > 0, "index out of range");

      uint256 lastIndex = tokenByIndex[_id].length.sub(1);
      uint256 tokenId = tokenByIndex[_id][_num];
      if (_num != lastIndex) {
        tokenByIndex[_id][_num] = tokenByIndex[_id][lastIndex];
      }
      tokenByIndex[_id].pop();
      return tokenId;
    }

    function setBoxOpen(uint256 _id, bool _open) external onlyAdmin {
        require(!deleted[_id], "SetBoxOpen: box has been deleted");
        require(histories[_id], "SetBoxOpen: box is not exist");
        Box memory box = boxs[_id];
        canceled[_id] = _open;
        emit Cancel(_id, box.totalSupply, box.totalSupply.sub(totalSell[_id]));
    }

    function deleteBox(uint256 _id) external onlyAdmin {
        require(!deleted[_id], "DeleteBox: box has been deleted");
        require(histories[_id], "DeleteBox: box is not exist");
        Box memory box = boxs[_id];
        deleted[_id] = true;
        delete tokenByIndex[_id];
        emit Delete(_id, box.totalSupply, box.totalSupply.sub(totalSell[_id]));
    }

    function updateBox(uint256 _id, CreateReq memory req) external onlyAdmin {
        require(histories[_id], "UpdateBox: box id not found");
        //require(bytes(req.name).length <= 15, "UpdateBox: length of name is too long");
        require(req.endTime > req.startTime && req.endTime > block.timestamp, "UpdateBox: time error");
        require(req.tokenNum > 0, "UpdateBox: tokenNum error");
        //require(req.price > 0, "UpdateBox: price error");

        Box memory box = boxs[_id];
        box.name = req.name;
        box.startTime = req.startTime;
        box.endTime = req.endTime;
        box.price = req.price.mul(1e16);
        box.weightProp = req.weightProp;
        box.tokenNum = req.tokenNum.mul(1e16);
        box.purchaseLimit = req.purchaseLimit;
        box.token = req.token;
        boxs[_id] = box;
    }

    function setTokenFT(IERC20 _tokenFT) external onlyAdmin {
      tokenFT = _tokenFT;
    }

    function setToken721(IERC721 _erc721) external onlyAdmin {
        ERC721 = _erc721;
    }

    function getAmountFT() external view returns(uint256){
      return tokenFT.balanceOf(address(this));
    }

    function getAmountToken(IERC20 token) external view returns(uint256) {
      return token.balanceOf(address(this));
    }

    function getAvailableToken(uint256 _id) external view returns(uint256[] memory) {
      return tokenByIndex[_id];
    }

    function setAdmin(address user, bool _auth) external onlyOwner {
        admin[user] = _auth;
    }

    function setSolt(uint256 _solt) external onlyOwner {
      solt = _solt;
    }

    modifier onlyAdmin() {
        require(
            admin[msg.sender] || owner() == msg.sender,
            "Admin: caller is not the admin"
        );
        _;
    }
    
    function withdraw(address _to) public onlyOwner {
        payable(_to).transfer(address(this).balance);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../lib/SafeMath.sol";

// interface for NFT contract, ERC721 and metadata, only funcs needed by NFTBridge
interface INFT {
    function tokenURI(uint256 tokenId) external view returns (string memory);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    // we do not support NFT that charges transfer fees
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    // impl by NFToken contract, mint an NFT with id and uri to user or burn
    function bridgeMint(
        address to,
        uint256 id,
        string memory uri
    ) external;

    function burn(uint256 id) external;
}

contract NftBridgeMock {
    using SafeMath for uint256;
    uint256 counter;
    event Sent(address sender, address srcNft, uint256 id, uint64 dstChid, address receiver);
    
    function sendTo(address _nft,uint256 _id,uint64 _dstChid,address _receiver) external payable{
        require(msg.sender == INFT(_nft).ownerOf(_id), "not token owner");
        INFT(_nft).tokenURI(_id);
        if (_id.mod(2) == 1) {
            // deposit
            INFT(_nft).transferFrom(msg.sender, address(this), _id);
            require(INFT(_nft).ownerOf(_id) == address(this), "transfer NFT failed");
        } else {
            // burn
            INFT(_nft).burn(_id);
        }
        emit Sent(msg.sender, _nft, _id, _dstChid, _receiver);
    }

    function totalFee(uint64 _dstChid,address _nft,uint256 _id) external view returns(uint256){
        string memory uri_ = INFT(_nft).tokenURI(_id);

        return bytes(uri_).length.mul(1e10).add(uint256(_dstChid));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "./lib/Verify.sol";

contract Erc20FT is ERC20Upgradeable, OwnableUpgradeable, Verify {
    using SafeMathUpgradeable for uint256;
    address[] public users;
    uint256 public ratio;
    address public team;
    uint256 public burnRatio;

    mapping(address => bool) public admin;
    mapping(address => mapping(bytes32 => uint256)) public records;

    string private name_;
    string private symbol_;

    function initialize(string memory _name, string memory _symbol)
        public
        initializer
    {
        __ERC20_init(_name, _symbol);
        __Ownable_init();
        setNameSymbol(_name, _symbol);
    }

    function setNameSymbol(string memory _name, string memory _symbol)
        public
        onlyAdmin
    {
        name_ = _name;
        symbol_ = _symbol;
    }

    function name() public view virtual override returns (string memory) {
        return name_;
    }

    function symbol() public view virtual override returns (string memory) {
        return symbol_;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual override {
        for (uint256 i = 0; i < users.length; i++) {
            if (users[i] == recipient) {
                uint256 fee = amount.mul(ratio).div(10000);
                amount = amount.sub(fee);
                super._transfer(sender, team, fee);
            }
        }
        super._transfer(sender, recipient, amount);
    }

    // function mint(address account, uint256 amount) external onlyAdmin {
    //     return super._mint(account, amount);
    // }

    function adminMint(address account, uint256 amount) external onlyAdmin {
        return super._mint(account, amount);
    }

    function mintTo(address account, uint256 amount) external onlyOwner {
        require(
            super.balanceOf(msg.sender) >= amount,
            "ERC20: mintTo amount exceeds balance"
        );
        return super._mint(account, amount);
    }

    function burn(uint256 amount) external {
        require(
            super.balanceOf(msg.sender) >= amount,
            "ERC20: burn amount exceeds balance"
        );
        super._burn(_msgSender(), amount);
    }

    function insert(address _user) external onlyOwner {
        for (uint256 i = 0; i < users.length; i++) {
            if (users[i] == _user) {
                return;
            }
        }
        users.push(_user);
    }

    function setRatio(uint256 _ratio) external onlyOwner {
        ratio = _ratio;
    }

    function setBurnRatio(uint256 _burnratio) external onlyOwner {
        burnRatio = _burnratio;
    }

    function setTeam(address _user) external onlyOwner {
        team = _user;
    }
    /**
     * @notice withdraw tokens from the game to the chain (Please use the official channel to withdraw)
     * @param _amount withdraw amount(2000 => 20.00).
     * @param timestamp ns.
     * @param data Signature information.
     */
    function withdraw(
        uint256 _amount,
        uint256 timestamp,
        bytes memory data
    ) external {
        uint256 amount = _amount.mul(1e16);
        uint256 second = timestamp.div(1e9);
        uint256 date = second.div(86400); // 24 * 60 * 60
        bytes32 _hash = keccak256(abi.encodePacked(msg.sender, _amount, timestamp));
        require(
            withdrewRecordStatus[_hash] == WithdrawStatus.NotFound,
            "Withdraw: signature has been used"
        );
        
        if(dateAmount[date].add(amount) > withdrawLimit) {
            withdrewRecordStatus[_hash] = WithdrawStatus.ExceedDailyLimit;
            emit Withdrew(msg.sender, amount, timestamp, WithdrawStatus.ExceedDailyLimit);
            return ;
        }

        if(userDailyAmount[msg.sender][date].add(amount) > userDailyWithdrawLimit) {
            withdrewRecordStatus[_hash] = WithdrawStatus.UserDailyLimit;
            emit Withdrew(msg.sender, amount, timestamp, WithdrawStatus.UserDailyLimit);
            return ;
        }
        
        if(second < block.timestamp && block.timestamp.sub(second) > 300) {
            withdrewRecordStatus[_hash] = WithdrawStatus.TimeOut;
            emit Withdrew(msg.sender, amount, timestamp, WithdrawStatus.TimeOut);
            return ;
        }

        if(!verify(_hash, data)) {
            withdrewRecordStatus[_hash] = WithdrawStatus.AuthFailed;
            emit Withdrew(msg.sender, amount, timestamp, WithdrawStatus.AuthFailed);
            return ;
        }

        super._mint(msg.sender, amount);
        dateAmount[date] = dateAmount[date].add(amount);
        userDailyAmount[msg.sender][date] = userDailyAmount[msg.sender][date].add(amount);
        withdrewRecordStatus[_hash] = WithdrawStatus.Successed;
        emit Withdrew(msg.sender, amount, timestamp, WithdrawStatus.Successed);
    }

    function setAdmin(address user, bool _auth) external onlyOwner {
        admin[user] = _auth;
    }

    modifier onlyAdmin() {
        require(
            admin[msg.sender] || owner() == msg.sender,
            "Admin: caller is not the admin"
        );
        _;
    }

    struct Supply {
        uint256 cap;
        uint256 total;
    }
    mapping(address => Supply) public bridges;
    event BridgeSupplyCapUpdated(address bridge, uint256 supplyCap);
    /**
     * @notice Updates the supply cap for a bridge.
     * @param _bridge The bridge address.
     * @param _cap The new supply cap.
     */
    function updateBridgeSupplyCap(address _bridge, uint256 _cap) external onlyOwner {
        // cap == 0 means revoking bridge role
        bridges[_bridge].cap = _cap;
        emit BridgeSupplyCapUpdated(_bridge, _cap);
    }

    function mint(address _to, uint256 _amount) external {
        Supply storage b = bridges[msg.sender];
        require(b.cap > 0, "invalid caller");
        require(b.total.add(_amount) <= b.cap, "exceeds bridge supply cap");
        b.total = b.total.add(_amount);
        _mint(_to, _amount);
    }

    function burn(address _from, uint256 _amount) external  {
        Supply storage b = bridges[msg.sender];
        require(b.cap > 0, "invalid caller");
        require(b.total >= _amount, "exceeds bridge minted amount");
        _spendAllowance(_from, _msgSender(), _amount);
        _burn(_from, _amount);
        b.total = b.total.sub(_amount);
    }

    mapping(uint256=>uint256) public dateAmount;
    uint256 public withdrawLimit;
    function setWithdrawLimit(uint256 amount_) public onlyAdmin {
        withdrawLimit = amount_;
    }

    /**
     * @notice withdraw status
     * NotFound:          0, transaction not found
     * Successed:         1, withdraw successed
     * ExceedDailyLimit:  2, withdraw money exccesd daily limit
     * TimeOut:           3, withdraw timeout
     * AuthFailed:        4, withdrawal signature authentication failed
     * UserDailyLimit:    5, Exceeding the daily withdrawal amount of the user
     */
    enum WithdrawStatus{ NotFound, Successed, ExceedDailyLimit, TimeOut, AuthFailed, UserDailyLimit}
    mapping (bytes32 => WithdrawStatus) withdrewRecordStatus;
   
    event Withdrew(address indexed sender,uint256 indexed amount, uint256 indexed timestamp, WithdrawStatus status);
    event Deposited(address indexed sender, uint256 indexed amount);
    function deposit(uint256 _amount) external{
        super._burn(msg.sender, _amount);
        emit Deposited(msg.sender, _amount);
    }

    function withdrewRecord(address _sender, uint256 _amount,uint256 _timestamp)  external view returns (WithdrawStatus) {
        return withdrewRecordStatus[keccak256(abi.encodePacked(_sender, _amount, _timestamp))];
    }

    mapping(address=>mapping(uint256 => uint256)) public userDailyAmount;
    uint256 public userDailyWithdrawLimit;
    function setUserDailyWithdrawLimit(uint256 _amount) public onlyAdmin {
        userDailyWithdrawLimit = _amount;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";
import "./extensions/IERC20MetadataUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    function __ERC20_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[45] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

abstract contract Admin is OwnableUpgradeable{
    mapping (address => bool) public admins;

    event SetAdmin(address admin, bool auth);

    modifier onlyAdmin() {
        require(
            admins[msg.sender] || owner() == msg.sender,
            "Admin: caller is not the admin"
        );
        _;
    }

    function setAdmin(address _user, bool _auth) external onlyOwner {
        admins[_user] = _auth;
        emit SetAdmin(_user, _auth);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./lib/Admin.sol";

interface nftMinter {
    function setApprovalForAll(address operator, bool _approved) external;
    function adminMintsTo(address[] memory _tos, uint256[] memory _tokenIds) external;
}

interface bridger {
    function sendTo(address _nft,uint256 _id,uint64 _dstChid,address _receiver) external payable;
    function totalFee(uint64 _dstChid,address _nft,uint256 _id) external view returns(uint256);
}

contract NftToBridge is Admin {
    nftMinter public nftMintAddr;
    bridger public bridge;

    function initialize(nftMinter _nftMintAddr, bridger _bridge)public initializer
    {
        nftMintAddr = _nftMintAddr;
        bridge = _bridge;
        nftMintAddr.setApprovalForAll(address(bridge), true);
        __Ownable_init();
    }

    function setNftMinterAndBridger(nftMinter _nftMintAddr, bridger _bridge)  external onlyAdmin {
        nftMintAddr.setApprovalForAll(address(bridge), false);
        nftMintAddr = _nftMintAddr;
        bridge = _bridge;
        nftMintAddr.setApprovalForAll(address(bridge), true);
    }

    function nftMint(uint256[] memory _tokenIds) external onlyAdmin{
        address[] memory tos_ = new address[](_tokenIds.length);
        for(uint256 i =0 ;i<_tokenIds.length; i++){
            tos_[i] = address(this);
        }
        nftMintAddr.adminMintsTo(tos_, _tokenIds);
    }

    function sendTo(uint256[] memory _tokenIds, address _receiver, uint64 _dstChid) external payable onlyAdmin{
        uint256 totalfee_ = totalFee(_tokenIds, _dstChid);
        require(msg.value >= totalfee_, "invalid amount");
        for(uint256 i = 0;i<_tokenIds.length; i++){
            bridge.sendTo{value: bridge.totalFee(_dstChid, address(nftMintAddr), _tokenIds[i])}(address(nftMintAddr), _tokenIds[i], _dstChid, _receiver);
        }
    }

    function totalFee(uint256[] memory _tokenIds, uint64 _dstChid)  public view returns (uint256 total_) {
        for(uint256 i =0 ; i < _tokenIds.length; i++){
            total_ += bridge.totalFee(_dstChid, address(nftMintAddr), _tokenIds[i]);
        }
        return total_;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library ZOSLibAddress {
    function isContract(address account) internal view returns (bool x) {
        assembly { 
          let size := extcodesize(account)
          x := gt(size, 0)
        }
    }
}

abstract contract Proxy{
  constructor(){}
  fallback () payable external {
    _fallback();
  }

  receive() external payable {
    _fallback();
  }

  function _implementation() internal view virtual returns (address);

  function _delegate(address implementation) internal {
    assembly {
      calldatacopy(0, 0, calldatasize())
      let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)
      returndatacopy(0, 0, returndatasize())
      switch result
      case 0 { revert(0, returndatasize()) }
      default { return(0, returndatasize()) }
    }
  }

  function _willFallback() internal virtual {}

  function _fallback() internal {
    _willFallback();
    _delegate(_implementation());
  }
}


contract BaseUpgradeabilityProxy is Proxy {
  event Upgraded(address indexed implementation);
  bytes32 internal constant IMPLEMENTATION_SLOT = 0x7050c9e0f4ca769c69bd3a8ef740bc37934f8e2c036e5a723fd8ee048ed3f8c3;

  function _implementation() override internal view returns (address impl) {
    bytes32 slot = IMPLEMENTATION_SLOT;
    assembly {
      impl := sload(slot)
    }
  }

  function _upgradeTo(address newImplementation) internal {
    _setImplementation(newImplementation);
    emit Upgraded(newImplementation);
  }

  function _setImplementation(address newImplementation) internal {
    require(ZOSLibAddress.isContract(newImplementation), "Cannot set a proxy implementation to a non-contract address");
    bytes32 slot = IMPLEMENTATION_SLOT;
    assembly {
      sstore(slot, newImplementation)
    }
  }
}

contract BaseAdminUpgradeabilityProxy is BaseUpgradeabilityProxy {
  event AdminChanged(address previousAdmin, address newAdmin);
  bytes32 internal constant ADMIN_SLOT = 0x10d6a54a4754c8869d6886b5f5d7fbfa5b4522237ea5c60d11bc4e7a1ff9390b;

  modifier ifAdmin() {
    if (msg.sender == _admin()) {
      _;
    } else {
      _fallback();
    }
  }

  function admin() external ifAdmin returns (address _adminAddr) {
    _adminAddr = _admin();
    return _adminAddr;
  }

  function implementation() external ifAdmin returns (address _imp) {
    _imp = _implementation();
    return _imp;
  }

  function changeAdmin(address newAdmin) external ifAdmin {
    require(newAdmin != address(0), "Cannot change the admin of a proxy to the zero address");
    emit AdminChanged(_admin(), newAdmin);
    _setAdmin(newAdmin);
  }

  function upgradeTo(address newImplementation) external ifAdmin {
    _upgradeTo(newImplementation);
  }

  function upgradeToAndCall(address newImplementation, bytes calldata data) payable external ifAdmin {
    _upgradeTo(newImplementation);
    (bool success,) = newImplementation.delegatecall(data);
    require(success);
  }

  function _admin() internal view returns (address adm) {
    bytes32 slot = ADMIN_SLOT;
    assembly {
      adm := sload(slot)
    }
  }

  function _setAdmin(address newAdmin) internal {
    bytes32 slot = ADMIN_SLOT;

    assembly {
      sstore(slot, newAdmin)
    }
  }

  // function _willFallback() override virtual internal {
  //   require(msg.sender != _admin(), "Cannot call fallback function from the proxy admin");
  //   super._willFallback();
  // }
}

contract UpgradeabilityProxy is BaseUpgradeabilityProxy {
  constructor(address _logic, bytes memory _data) payable {
    assert(IMPLEMENTATION_SLOT == keccak256("org.zeppelinos.proxy.implementation"));
    _setImplementation(_logic);
    if(_data.length > 0) {
      (bool success,) = _logic.delegatecall(_data);
      require(success);
    }
  }
}

contract AdminUpgradeabilityProxy is BaseAdminUpgradeabilityProxy, UpgradeabilityProxy {

  constructor(address _logic, address _admin, bytes memory _data) UpgradeabilityProxy(_logic, _data) payable {
    assert(ADMIN_SLOT == keccak256("org.zeppelinos.proxy.admin"));
    _setAdmin(_admin);
  }

  function _willFallback() override virtual internal {
    require(msg.sender != _admin(), "Cannot call fallback function from the proxy admin");
    super._willFallback();
  }
}