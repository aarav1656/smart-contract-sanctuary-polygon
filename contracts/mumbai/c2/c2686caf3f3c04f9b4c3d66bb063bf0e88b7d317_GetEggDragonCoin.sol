/**
 *Submitted for verification at polygonscan.com on 2022-08-13
*/

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


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

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: contracts/getcoin.sol





pragma solidity ^0.8.15;

interface IEDC {
    function mint(address to_, uint256 amount_) external;
}

interface IFED {
    function totalSupply() external view returns (uint256);
    function balanceOf(address owner_) external view returns (uint256);
    function ownerOf(uint256 tokenId_) external view returns (address);
}


contract GetEggDragonCoin is ReentrancyGuard,Ownable {
    IEDC public coinAddress;
    IFED public NFTAddress;

    uint256 private constant NUMBER_FALSE = 1;
    uint256 private constant NUMBER_TRUE = 2;

    mapping(uint256 => uint256) public treatedTokenIds;

    constructor(address _coinAddress,address _NFTAddress) {
        coinAddress = IEDC(_coinAddress);
        NFTAddress = IFED(_NFTAddress);
    }

//main function
    function getCoin() public nonReentrant payable {
        uint256[] memory _tokenIds = walletOfOwner(msg.sender);
        uint256 numberOfToken;

        require(_tokenIds.length != 0,"Bad joke!!!(not have NFT)");
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            if(treatedTokenIds[_tokenIds[i]] != NUMBER_FALSE){
                numberOfToken++;
            }
            treatedTokenIds[_tokenIds[i]] = NUMBER_FALSE;
        }
        require(numberOfToken != 0,"Too greedy!!!(nothing to get)");
        coinAddress.mint(msg.sender, numberOfToken);
    }


//get function
    function walletOfOwner(address _owner) 
        public
        view
        returns (uint256[] memory) 
    {
        uint256 ts = NFTAddress.totalSupply();
        uint256 tokenCount = NFTAddress.balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](tokenCount);
        uint256 _index;
        for (uint256 i = 1; i < ts + 1; i++) {
            address _ownerOf = NFTAddress.ownerOf(i);
            if(_ownerOf == _owner) {
                tokenIds[_index++] = i;
            }
        }

        return tokenIds; 
    }


    function numberOfGetCoin(address _owner) public view returns(uint256){
        uint256[] memory _tokenIds = walletOfOwner(_owner);
        uint256 _numberOfToken;
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            if(treatedTokenIds[_tokenIds[i]] != NUMBER_FALSE){
                _numberOfToken++;
            }
        }
        return _numberOfToken;
    }

//set function
    function setCoinAddress(address newCoinAddress) external onlyOwner {
        coinAddress = IEDC(newCoinAddress);
    }

    function settokenIDs(address newNFTAddress) external onlyOwner {
        NFTAddress = IFED(newNFTAddress);
    }

    function setTreatedTokenIds(uint256[] memory tokenIds_) external onlyOwner {
        for (uint256 i = 0; i < tokenIds_.length; i++) {
            treatedTokenIds[tokenIds_[i]] = NUMBER_TRUE;
        }
    }
}