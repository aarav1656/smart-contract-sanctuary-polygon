/**
 *Submitted for verification at polygonscan.com on 2022-09-15
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IBEP20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    function balanceOf(address owner) external view returns (uint balance);
    function ownerOf(uint tokenId) external view returns (address owner);
    function safeTransferFrom(address from, address to, uint tokenId) external;
    function transferFrom(address from, address to, uint tokenId) external;
    function approve(address to, uint tokenId) external;
    function getApproved(uint tokenId) external view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function safeTransferFrom(address from, address to, uint tokenId, bytes calldata data) external;
}

interface IERC721Receiver {
    function onERC721Received(address operator, address from, uint tokenId, bytes calldata data) external returns (bytes4);
}

interface IERC721Metadata is IERC721 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint tokenId) external view returns (string memory);
}

library Address {
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint size;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
}

library Strings {
    bytes16 private constant alphabet = "0123456789abcdef";

    /**
     * @dev Converts a `uint` to its ASCII `string` decimal representation.
     */
    function toString(uint value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint temp = value;
        uint digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}

library Math {
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

abstract contract Context {
    function _msgSender() internal view returns (address payable) {
        return payable(msg.sender);
    }
    function _msgData() internal view returns (bytes memory) {
        this;
        return msg.data;
    }
}

abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override
    returns (bool)
    {
        return interfaceId == type(IERC165).interfaceId;
    }
}

contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint) private _balances;

    // Mapping from token ID to approved address
    mapping(uint => address) private _tokenApprovals;

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
    function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC165, IERC165)
    returns (bool)
    {
        return
        interfaceId == type(IERC721).interfaceId ||
        interfaceId == type(IERC721Metadata).interfaceId ||
        super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner)
    public
    view
    virtual
    override
    returns (uint)
    {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint tokenId)
    public
    view
    virtual
    override
    returns (address)
    {
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
    function tokenURI(uint tokenId)
    public
    view
    virtual
    override
    returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory baseURI = _baseURI();
        return
        bytes(baseURI).length > 0
        ? string(abi.encodePacked(baseURI, tokenId.toString()))
        : "";
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
    function approve(address to, uint tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || ERC721.isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint tokenId)
    public
    view
    virtual
    override
    returns (address)
    {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved)
    public
    virtual
    override
    {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator)
    public
    view
    virtual
    override
    returns (bool)
    {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint tokenId,
        bytes memory _data
    ) public virtual override {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );
        _safeTransfer(from, to, tokenId, _data);
    }

    function _safeTransfer(
        address from,
        address to,
        uint tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(
            _checkOnERC721Received(from, to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    function _exists(uint tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    function _isApprovedOrOwner(address spender, uint tokenId)
    internal
    view
    virtual
    returns (bool)
    {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner ||
        getApproved(tokenId) == spender ||
        ERC721.isApprovedForAll(owner, spender));
    }

    function _safeMint(address to, uint tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    function _safeMint(
        address to,
        uint tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    function _mint(address to, uint tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    function _burn(uint tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    function _transfer(
        address from,
        address to,
        uint tokenId
    ) internal virtual {
        require(
            ERC721.ownerOf(tokenId) == from,
            "ERC721: transfer of token that is not own"
        );
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    function _approve(address to, uint tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    function _checkOnERC721Received(
        address from,
        address to,
        uint tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try
            IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data)
            returns (bytes4 retval) {
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

    function _beforeTokenTransfer(
        address from,
        address to,
        uint tokenId
    ) internal virtual {}
}

interface IERC721Enumerable is IERC721 {
    function totalSupply() external view returns (uint);
    function tokenOfOwnerByIndex(address owner, uint index) external view returns (uint tokenId);
    function tokenByIndex(uint index) external view returns (uint);
}

interface IMisadReflect {
    function registerNewMint(uint tokenId) external;
    function updateBurnedToken(uint tokenId) external;
}

abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint => uint)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint => uint) private _ownedTokensIndex;

    // The current index of the token
    uint currentIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(IERC165, ERC721)
    returns (bool)
    {
        return
        interfaceId == type(IERC721Enumerable).interfaceId ||
        super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint index)
    public
    view
    virtual
    override
    returns (uint)
    {
        require(
            index < ERC721.balanceOf(owner),
            "ERC721Enumerable: owner index out of bounds"
        );
        return _ownedTokens[owner][uint(index)];
    }

    function totalSupply() public view virtual override returns (uint) {
        return currentIndex;
    }

    function tokenByIndex(uint index)
    public
    view
    virtual
    override
    returns (uint)
    {
        require(
            index < currentIndex,
            "ERC721Enumerable: global index out of bounds"
        );
        return index;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint tokenId
    ) internal virtual override {
        require (to != address(0), "Token not burnable");

        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            currentIndex++;
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }

        if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    function _addTokenToOwnerEnumeration(address to, uint tokenId) private {
        uint length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    function _removeTokenFromOwnerEnumeration(address from, uint tokenId)
    private
    {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint lastTokenIndex = uint(ERC721.balanceOf(from) - 1);
        uint tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }
}

enum Permission {
    Authorize,
    Unauthorize,
    LockPermissions,
    AdjustVariables,
    Mint,
    ManagePacks,
    ManageAttributes,
    Withdraw
}

abstract contract MISADAUTH {
    struct PermissionLock {
        bool isLocked;
        uint64 expiryTime;
    }

    address public owner;
    mapping(address => mapping(uint => bool)) private authorizations;

    uint constant NUM_PERMISSIONS = 8; // always has to be adjusted when Permission element is added or removed
    mapping(string => uint) permissionNameToIndex;

    mapping(uint => PermissionLock) lockedPermissions;

    constructor(address owner_) {
        owner = owner_;
        for (uint i; i < NUM_PERMISSIONS; i++) {
            authorizations[owner_][i] = true;
        }

        // a permission name can't be longer than 32 bytes
        permissionNameToIndex["Authorize"] = uint(Permission.Authorize);
        permissionNameToIndex["Unauthorize"] = uint(Permission.Unauthorize);
        permissionNameToIndex["LockPermissions"] = uint(Permission.LockPermissions);
        permissionNameToIndex["AdjustVariables"] = uint(Permission.AdjustVariables);
        permissionNameToIndex["Mint"] = uint(Permission.Mint);
        permissionNameToIndex["ManagePacks"] = uint(Permission.ManagePacks);
        permissionNameToIndex["ManageAttributes"] = uint(Permission.ManageAttributes);
        permissionNameToIndex["Withdraw"] = uint(Permission.Withdraw);
    }

    /**
     * Function modifier to require caller to be contract owner
     */
    modifier onlyOwner() {
        require(isOwner(msg.sender), "onlyOwner"); _;
    }

    /**
     * Function to require caller to be authorized
     */
    function authorizedFor(Permission permission) internal view {
        require(!lockedPermissions[uint(permission)].isLocked, "Locked.");
        require(isAuthorizedFor(msg.sender, permission), "!authorized");
    }

    /**
     * Authorize address for one permission
     */
    function authorizeFor(address adr, string memory permissionName) public {
        authorizedFor(Permission.Authorize);
        uint permIndex = permissionNameToIndex[permissionName];
        authorizations[adr][permIndex] = true;
        emit AuthorizedFor(adr, permissionName, permIndex);
    }

    /**
     * Authorize address for multiple permissions
     */
    function authorizeForMultiplePermissions(address adr, string[] calldata permissionNames) public {
        authorizedFor(Permission.Authorize);
        for (uint i; i < permissionNames.length; i++) {
            uint permIndex = permissionNameToIndex[permissionNames[i]];
            authorizations[adr][permIndex] = true;
            emit AuthorizedFor(adr, permissionNames[i], permIndex);
        }
    }

    /**
     * Remove address' authorization
     */
    function unauthorizeFor(address adr, string memory permissionName) public {
        authorizedFor(Permission.Unauthorize);
        require(adr != owner, "!owner");

        uint permIndex = permissionNameToIndex[permissionName];
        authorizations[adr][permIndex] = false;
        emit UnauthorizedFor(adr, permissionName, permIndex);
    }

    /**
     * Unauthorize address for multiple permissions
     */
    function unauthorizeForMultiplePermissions(address adr, string[] calldata permissionNames) public {
        authorizedFor(Permission.Unauthorize);
        require(adr != owner, "!owner");

        for (uint i; i < permissionNames.length; i++) {
            uint permIndex = permissionNameToIndex[permissionNames[i]];
            authorizations[adr][permIndex] = false;
            emit UnauthorizedFor(adr, permissionNames[i], permIndex);
        }
    }

    /**
     * Check if address is owner
     */
    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    /**
     * Return address' authorization status
     */
    function isAuthorizedFor(address adr, string memory permissionName) public view returns (bool) {
        return authorizations[adr][permissionNameToIndex[permissionName]];
    }

    /**
     * Return address' authorization status
     */
    function isAuthorizedFor(address adr, Permission permission) public view returns (bool) {
        return authorizations[adr][uint(permission)];
    }

    /**
     * Transfer ownership to new address. Caller must be owner.
     */
    function transferOwnership(address payable adr) public onlyOwner {
        address oldOwner = owner;
        owner = adr;
        for (uint i; i < NUM_PERMISSIONS; i++) {
            authorizations[oldOwner][i] = false;
            authorizations[owner][i] = true;
        }
        emit OwnershipTransferred(oldOwner, owner);
    }

    /**
     * Get the index of the permission by its name
     */
    function getPermissionNameToIndex(string memory permissionName) public view returns (uint) {
        return permissionNameToIndex[permissionName];
    }

    /**
     * Get the time the timeLock expires
     */
    function getPermissionUnlockTime(string memory permissionName) public view returns (uint) {
        return lockedPermissions[permissionNameToIndex[permissionName]].expiryTime;
    }

    /**
     * Check if the permission is locked
     */
    function isLocked(string memory permissionName) public view returns (bool) {
        return lockedPermissions[permissionNameToIndex[permissionName]].isLocked;
    }

    /*
     *Locks the permission from being used for the amount of time provided
     */
    function lockPermission(string memory permissionName, uint64 time) public virtual {
        authorizedFor(Permission.LockPermissions);

        uint permIndex = permissionNameToIndex[permissionName];
        uint64 expiryTime = uint64(block.timestamp) + time;
        lockedPermissions[permIndex] = PermissionLock(true, expiryTime);
        emit PermissionLocked(permissionName, permIndex, expiryTime);
    }

    /*
     * Unlocks the permission if the lock has expired
     */
    function unlockPermission(string memory permissionName) public virtual {
        require(block.timestamp > getPermissionUnlockTime(permissionName) , "TimeLock");
        uint permIndex = permissionNameToIndex[permissionName];
        lockedPermissions[permIndex].isLocked = false;
        emit PermissionUnlocked(permissionName, permIndex);
    }

    event PermissionLocked(string permissionName, uint permissionIndex, uint64 expiryTime);
    event PermissionUnlocked(string permissionName, uint permissionIndex);
    event OwnershipTransferred(address from, address to);
    event AuthorizedFor(address adr, string permissionName, uint permissionIndex);
    event UnauthorizedFor(address adr, string permissionName, uint permissionIndex);
}

contract MISADSOUL is ERC721Enumerable, MISADAUTH {
    struct LevelUpPrice {
        uint pair;
        uint misad;
    }

    struct Soul {
        uint8 level;
        uint8 rarity;
    }

    struct Pack {
        uint232 basePrice;
        uint8 numberOfCards;
        bool saleRunning;
        uint8 cardSetId;
        address tokenAddress;
    }

    struct CardSet {
        uint64 minted;
        uint64 mintLimit;
    }

    struct Attribute {
        string name;
    }

    Soul[] private _souls;
    LevelUpPrice[] private levelUpPrices;

    // Attributes
    mapping(uint => mapping(string => string)) public nftAttributes;
    Attribute[] public attributes;
    mapping(string => bool) public attributeExists;
    mapping(string => uint) public attributeIndex;

    // Packs
    Pack[] public packTypes; // index is pack ID
    mapping(uint => uint) public packIdOfToken; // first is token ID, second is pack ID
    CardSet[] public cardSets;

    uint8 public maxRarity = 4;
    uint8 public maxLevel = 1;

    // ADDRESSES
    address deadAddress = 0x000000000000000000000000000000000000dEaD;
    address public feeReceiver = 0x256BCbb7230bd175abc1Ea1f8B24A31BCadBa747;
    address public pairAddress = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
    IBEP20 private PairToken;
    address public misadAddress = 0xB871b2E470576BaF99eBee563472d2468c02b18B;
    IBEP20 private MisadToken;
    address public reflectAddress;

    // Base URI
    string private _baseUriExtended = "https://api.wingofmisadventure.com/api/soul/v1/";

    constructor() ERC721("Wing of Misadventure Soul", "MISADSOUL") MISADAUTH(msg.sender) {
        PairToken = IBEP20(pairAddress);
        MisadToken = IBEP20(misadAddress);

        //Add Genesis Souls (ID: 0)
        addCardSet(1000);

        //Pack Genesis Souls
        addPack(400000 * 10**15, 1, false, 0, pairAddress);

        //LevelUpPrice
        addLevelUpPrice(0, 350000 * 10**14);

        //Add Attribute
        addAttribute("name");
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseUriExtended;
    }

    function purchasePack(uint8 packId) external {
        Pack memory pack = packTypes[packId];
        CardSet memory cardSet = cardSets[pack.cardSetId];

        require(pack.saleRunning == true, "!Sale");
        require(cardSet.minted + pack.numberOfCards <= cardSet.mintLimit, "Mint limit");

        _mintCardsOfPack(msg.sender, packId, pack.numberOfCards);

        cardSets[pack.cardSetId].minted += pack.numberOfCards;

        require(IBEP20(pack.tokenAddress).transferFrom(msg.sender, address(this), getPrice(packId)), "Transfer failed");

        emit PackPurchased(msg.sender, packId);
    }

    function _mintCardsOfPack(address user, uint8 packId, uint8 numOfCards) internal {
        require(_souls.length == currentIndex, "Error length");

        uint soulId = currentIndex;

        for (uint8 i; i < numOfCards; i++) {
            packIdOfToken[soulId] = packId;
            _safeMint(user, soulId);
            _createSoul(0, 0);

            emit CardMinted(user, soulId, packId);
            soulId += 1;
        }
    }

    function levelUp(uint soulId) external {
        require(ownerOf(soulId) == msg.sender, "!owner");

        Soul storage soul = _souls[soulId];
        LevelUpPrice memory levelData = levelUpPrices[soul.level];
        uint8 newLevel = soul.level + 1;

        require(newLevel <= maxLevel, "Max level");
        require(newLevel == 1 || soul.rarity > 0, "Wait for summoned");

        require(
            (
                levelData.pair == 0 ||
                (levelData.pair > 0 && PairToken.balanceOf(msg.sender) >= levelData.pair)
            ) &&
            (
                levelData.misad == 0 ||
                (levelData.misad > 0 && MisadToken.balanceOf(msg.sender) >= levelData.misad)
            )
        ,"Not enough fee");

        if(levelData.pair > 0){
            require(PairToken.transferFrom(msg.sender, address(this), levelData.pair), "Pair transfer failed");
        }

        if(levelData.misad > 0){
            require(MisadToken.transferFrom(msg.sender, address(this), levelData.misad), "Misad transfer failed");
        }

        if(newLevel == 1){
            soul.level = newLevel;

            try IMisadReflect(reflectAddress).registerNewMint( soulId ) {} catch {}

            emit SummonSoul(soulId);
        }else if(newLevel <= 5){
            soul.level = newLevel;
            emit UserLevelUp(soulId, newLevel);
        }else{
            emit WaitingLevelUp(soulId, newLevel);
        }
    }

    function getSoul(uint soulId) external view returns (uint8 level, uint8 rarity) {
        Soul memory soul = _souls[soulId];
        level = soul.level;
        rarity = soul.rarity;
    }

    function getPrice(uint8 packId) public view returns (uint price) {
        Pack memory pack = packTypes[packId];
        price = pack.basePrice;
    }

    function getPacks() external view returns (Pack[] memory) {
        return packTypes;
    }

    function getLevelUpPrices() external view returns (LevelUpPrice[] memory) {
        return levelUpPrices;
    }

    event Received(address sender, uint amount);

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    function setBaseURI(string memory baseURI_) external {
        authorizedFor(Permission.AdjustVariables);

        _baseUriExtended = baseURI_;
    }

    function setPairAddress(address _newAdr) external {
        authorizedFor(Permission.AdjustVariables);

        pairAddress = _newAdr;
        PairToken = IBEP20(_newAdr);
    }

    function setMisadAddress(address _newAdr) external {
        authorizedFor(Permission.AdjustVariables);

        misadAddress = _newAdr;
        MisadToken = IBEP20(_newAdr);
    }

    function setReflectAddress(address _newAdr) external {
        authorizedFor(Permission.AdjustVariables);

        reflectAddress = _newAdr;
    }

    function setMaxLevel(uint8 newMaxLevel) external {
        authorizedFor(Permission.AdjustVariables);

        require(newMaxLevel > maxLevel);
        maxLevel = newMaxLevel;
    }

    function setMaxRarity(uint8 newMaxRarity) external {
        authorizedFor(Permission.AdjustVariables);

        require(newMaxRarity > maxRarity);
        maxRarity = newMaxRarity;
    }

    function addPack(uint232 basePrice, uint8 numberOfCards, bool saleRunning, uint8 cardSetId, address tokenAddress) public {
        authorizedFor(Permission.ManagePacks);

        packTypes.push(Pack(
                basePrice,
                numberOfCards,
                saleRunning,
                cardSetId,
                tokenAddress
            ));

        emit PackAdded(packTypes.length - 1, basePrice, numberOfCards, cardSetId, tokenAddress);
    }

    function editPack(uint8 packId, uint232 basePrice, uint8 numberOfCards, bool saleRunning, uint8 cardSetId, address tokenAddress) external {
        authorizedFor(Permission.ManagePacks);

        packTypes[packId].basePrice = basePrice;
        packTypes[packId].numberOfCards = numberOfCards;
        packTypes[packId].saleRunning = saleRunning;
        packTypes[packId].cardSetId = cardSetId;
        packTypes[packId].tokenAddress = tokenAddress;

        emit PackEdited(packId, basePrice, numberOfCards, saleRunning, cardSetId, tokenAddress);
    }

    function setSaleRunning(uint packId, bool running) public {
        authorizedFor(Permission.ManagePacks);

        packTypes[packId].saleRunning = running;
    }

    function addCardSet(uint64 mintLimit) public {
        authorizedFor(Permission.ManagePacks);

        cardSets.push(CardSet(0, mintLimit));

        emit CardSetAdded(cardSets.length - 1, mintLimit);
    }

    function editCardSet(uint8 setId, uint64 mintLimit) public {
        authorizedFor(Permission.ManagePacks);

        cardSets[setId].mintLimit = mintLimit;

        emit CardSetEdited(setId, mintLimit);
    }

    function addAttribute(string memory name) public {
        authorizedFor(Permission.ManageAttributes);

        attributes.push(Attribute(name));
        attributeIndex[name] = attributes.length - 1;
        attributeExists[name] = true;

        emit AttributeAdded(attributes.length - 1, name);
    }

    function editAttribute(uint8 attrId, string memory name) public {
        authorizedFor(Permission.ManageAttributes);

        Attribute memory old = attributes[attrId];

        if (compareStrings(old.name, name) == false) {
            delete attributeIndex[old.name];
            attributeIndex[name] = attrId;

            delete attributeExists[old.name];
            attributeExists[name] = true;
        }

        attributes[attrId].name = name;

        emit AttributeEdited(attrId, name);
    }

    function addLevelUpPrice(uint _pair, uint _misad) public{
        authorizedFor(Permission.ManageAttributes);

        levelUpPrices.push(LevelUpPrice(_pair, _misad));
    }

    function editLevelUpPrice(uint8 level, uint _pair, uint _misad) public {
        authorizedFor(Permission.ManageAttributes);

        require(level < levelUpPrices.length,"Invalid level");

        levelUpPrices[level].pair = _pair;
        levelUpPrices[level].misad = _misad;
    }

    function compareStrings(string memory a, string memory b) internal pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }

    function adminSetAttribute(uint soulId, string memory attribute, string memory value) public {
        authorizedFor(Permission.ManageAttributes);

        require(attributeExists[attribute], "!Attribute");

        nftAttributes[soulId][attribute] = value;

        emit AttributeChanged(soulId, attribute, value);
    }

    function adminMintPack(uint8 packId, address recipient) external {
        authorizedFor(Permission.Mint);

        if (recipient == address(0)) recipient = msg.sender;
        Pack memory pack = packTypes[packId];

        cardSets[pack.cardSetId].minted += pack.numberOfCards;
        _mintCardsOfPack(recipient, packId, pack.numberOfCards);
    }

    function adminMintSingle(uint8 packId, uint8 level, uint8 rarity, address recipient) external {
        authorizedFor(Permission.Mint);

        if (recipient == address(0)) recipient = msg.sender;

        _singleMint(recipient, packId, level, rarity);
    }

    function adminMintMultiple(uint8[] memory packIds, uint8[] memory levels, uint8[] memory rarities, address[] memory recipients) external {
        authorizedFor(Permission.Mint);

        require(
            recipients.length == packIds.length &&
            recipients.length == levels.length &&
            recipients.length == rarities.length
            , "Error length");

        for (uint256 i = 0; i < recipients.length; i++) {
            _singleMint(recipients[i], packIds[i], levels[i], rarities[i]);
        }
    }

    function adminKillSoul(uint soulId) external {
        authorizedFor(Permission.Mint);

        safeTransferFrom(ownerOf(soulId), deadAddress, soulId);

        try IMisadReflect(reflectAddress).updateBurnedToken( soulId ) {} catch {}

        emit AdminKillSoul(soulId);
    }

    function adminSetLevel(uint soulId, uint8 newLevel) external {
        authorizedFor(Permission.ManageAttributes);

        require(newLevel <= maxLevel, "Max level");
        Soul storage soul = _souls[soulId];
        soul.level = newLevel;

        if(newLevel == 1){
            try IMisadReflect(reflectAddress).registerNewMint( soulId ) {} catch {}
        }

        emit AdminSetLevel(soulId, newLevel);
    }

    function adminSetRarity(uint soulId, uint8 rarity) external {
        authorizedFor(Permission.ManageAttributes);

        Soul storage soul = _souls[soulId];

        require(rarity <= maxRarity, "Max rarity");

        soul.rarity = rarity;
    }

    function withdrawERC20(address token, uint amount) external {
        authorizedFor(Permission.Withdraw);

        uint balance = IBEP20(token).balanceOf(address(this));

        if(amount > balance){
            amount = balance;
        }

        require(IBEP20(token).transfer(msg.sender, amount), "Transfer failed");
    }

    function withdrawWETH(uint amount) external {
        authorizedFor(Permission.Withdraw);

        uint balance = address(this).balance;

        if(amount > balance){
            amount = balance;
        }

        (bool success,) = payable(msg.sender).call{ value: amount }("");
        require(success, "Failed");
    }

    function _createSoul(uint8 level, uint8 rarity) internal {
        _souls.push(Soul(level, rarity));
    }

    function _singleMint(address recipient, uint8 packId, uint8 level, uint8 rarity) internal {
        require(_souls.length == currentIndex, "Error length");
        require(level <= maxLevel && rarity <= maxRarity, "Error level or rarity");

        uint soulId = currentIndex;

        packIdOfToken[soulId] = packId;
        _safeMint(recipient, soulId);
        _createSoul(level, rarity);

        cardSets[packTypes[packId].cardSetId].minted++;
        emit CardMinted(recipient, soulId, packId);
    }

    event CardMinted(address recipient, uint soulId, uint8 packId);
    event CardSetAdded(uint setId, uint64 mintLimit);
    event CardSetEdited(uint setId, uint64 mintLimit);
    event PackPurchased(address user, uint8 packId);
    event PackAdded(uint packId, uint basePrice, uint8 numOfCards, uint8 cardSetId, address tokenAddress);
    event PackEdited(uint packId, uint basePrice, uint8 numOfCards, bool saleRunning, uint8 cardSetId, address tokenAddress);
    event AttributeAdded(uint id, string name);
    event AttributeEdited(uint id, string name);
    event AttributeChanged(uint soulId, string attributeName, string newValue);
    event SummonSoul(uint indexed soulId);
    event AdminKillSoul(uint indexed soulId);
    event AdminSetLevel(uint indexed soulId, uint8 newLevel);
    event UserLevelUp(uint indexed soulId, uint8 newLevel);
    event WaitingLevelUp(uint indexed soulId, uint8 newLevel);
}