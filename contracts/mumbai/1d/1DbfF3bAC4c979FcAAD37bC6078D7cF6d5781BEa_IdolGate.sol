/**
 *Submitted for verification at polygonscan.com on 2022-02-26
*/

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
}

abstract contract nftInterface {
    function mint (uint256 _buyTokenID, address _msgsender) public virtual;
    function getStock (uint256 _tokenNum) public virtual returns(uint256);
}

contract IdolGate is Ownable {
    address public nftaAddress;
    address public nftbAddress;
    address public nftcAddress;
    nftInterface public nftinterfaceA;
    nftInterface public nftinterfaceB;
    nftInterface public nftinterfaceC;
    uint256 public priceNFTa = 0.1 ether;
    address public recipient;
    uint256 public shareFee;
    bool public isOpenNftA = false;
    bool public isOpenNftB = false;
    bool public isOpenNftC = false;

    
    event MintingDone(
        address minter,
        uint256 mintTokenID
    );

    constructor (
        address _nftaAddress, 
        uint256 _shareFee,
        address _recipient
        ) 
    {
        nftinterfaceA = nftInterface(_nftaAddress);
        shareFee = _shareFee;
        recipient = _recipient;

    }

    function GroupAMint (
        uint256 buyTokenID
    ) 
    public 
    payable 
    {
        require(isOpenNftA, "This collection is not open");
        require(nftinterfaceA.getStock(buyTokenID) > 0, "Out of Stock");
        require(msg.value == priceNFTa);
        
        nftinterfaceA.mint(buyTokenID, msg.sender);
    }

    function GroupBMint (
        uint256 buyTokenID
    ) 
    public 
    payable 
    {
        require(isOpenNftB, "This collection is not open");
        require(nftinterfaceB.getStock(buyTokenID) > 0, "Out of Stock");
        require(msg.value == priceNFTa);

        nftinterfaceB.mint(buyTokenID, msg.sender);
    }

    function GroupCMint (
        uint256 buyTokenID
    ) 
    public 
    payable 
    {
        require(isOpenNftC, "This collection is not open");
        require(nftinterfaceC.getStock(buyTokenID) > 0, "Out of Stock");
        require(msg.value == priceNFTa);

        nftinterfaceC.mint(buyTokenID, msg.sender);
    }

    

    

    function setNftInterfaceA (
        address _address
    )
    public 
    onlyOwner
    {
        nftinterfaceA = nftInterface(_address);
    }

    function setNftInterfaceB (
        address _address
    )
    public 
    onlyOwner
    {
        nftinterfaceB = nftInterface(_address);
    }

    function setNftInterfaceC (
        address _address
    )
    public 
    onlyOwner
    {
        nftinterfaceC = nftInterface(_address);
    }

    function _payShare(
        uint256 _shareFee
    ) 
    internal 
    {
      (bool success1, ) = payable(recipient).call{value: _shareFee}("");
      require(success1);
    }

    function withDraw ()
    public 
    payable
    onlyOwner
    {
      uint256 share = (address(this).balance * shareFee) / 100;
      _payShare(share);

      (bool success2, ) = payable(msg.sender).call{value: address(this).balance - share}("");
      require(success2);
    }

    function setShareFee(uint256 _sharefee) public onlyOwner{
        require(_sharefee >= 0);
        shareFee = _sharefee;
    }

    function setRecipient(address _address) public onlyOwner {
        recipient = _address;
    }

    function setIsOpenNftA(bool _isOpen) public onlyOwner {
        isOpenNftA = _isOpen;
    }

    function setIsOpenNftB(bool _isOpen) public onlyOwner {
        isOpenNftB = _isOpen;
    }

    function setIsOpenNftC(bool _isOpen) public onlyOwner {
        isOpenNftC = _isOpen;
    }
}