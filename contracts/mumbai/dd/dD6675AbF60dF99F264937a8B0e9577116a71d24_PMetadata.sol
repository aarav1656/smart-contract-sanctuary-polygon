/**
 *Submitted for verification at polygonscan.com on 2022-12-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
pragma abicoder v2;



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
}







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







interface IMetadata {
  function tokenURI(uint256 tokenId) external view returns(string memory);
}







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







interface IRoyaltySplitter {
  // ============ Errors ============

  error InvalidCall();

  // ============ Events ============

  event PaymentReleased(address to, uint256 amount);
  event ERC20PaymentReleased(IERC20 indexed token, address to, uint256 amount);
  event PaymentReceived(address from, uint256 amount);

  // ============ Read Methods ============

  /**
   * @dev Getter for the address of the payee via `tokenId`.
   */
  function payee(uint256 tokenId) external view returns(address);

  /**
   * @dev Determines how much ETH are releaseable for `tokenId`
   */
  function releaseable(uint256 tokenId) external view returns(uint256);

  /**
   * @dev Determines how much ERC20 `token` are releaseable for `tokenId`
   */
  function releaseable(IERC20 token, uint256 tokenId) external view returns(uint256);

  /**
   * @dev Getter for the amount of shares held by an account.
   */
  function shares() external view returns(uint256);

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
}





// Based on Cash Cows sources


//--------------------------------------------------------------
//             __  ___     __            __      __       
//      ____  /  |/  /__  / /_____ _____/ /___ _/ /_____ _
//     / __ \/ /|_/ / _ \/ __/ __ `/ __  / __ `/ __/ __ `/
//    / /_/ / /  / /  __/ /_/ /_/ / /_/ / /_/ / /_/ /_/ / 
//   / .___/_/  /_/\___/\__/\__,_/\__,_/\__,_/\__/\__,_/  
//  /_/                                                   
//
//--------------------------------------------------------------
//



// ============ Contract ============

contract PMetadata is Ownable, IMetadata {
  using Strings for uint256;

  // ============ Errors ============

  error InvalidCall();

  // ============ Storage ============

  //base URI
  string private _baseTokenURI;
  //maps stage # to limit
  //ex. stage 0 -> less than 0.001 eth
  mapping(uint256 => uint256) private _stages;
  //we need the splitter to determine which cow to show
  IRoyaltySplitter private _treasury;
  
  // ============ Read Methods ============

  /**
   * @dev Returns the stage given the token id
   */
  function stage(uint256 tokenId) public view returns(uint256) {
    if (address(_treasury) == address(0)) revert InvalidCall();
    //get releaseable
    uint256 releaseable = _treasury.releaseable(tokenId);
    //loop through stages
    for(uint256 i; true; i++) {
      if (_stages[i] == 0) return i == 0 ? i : i - 1;
      if (releaseable < _stages[i]) return i;
    }

    return 0;
  }

  /**
   * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
   */
  function tokenURI(
    uint256 tokenId
  ) external view returns(string memory) {
    //if no base URI
    if (bytes(_baseTokenURI).length == 0) revert InvalidCall();

    return string(
      abi.encodePacked(
        _baseTokenURI, 
        tokenId.toString(), 
        "_", 
        stage(tokenId).toString(), 
        ".json"
      )
    );
  }
  
  // ============ Write Methods ============

  /**
   * @dev Sets stage limit ex. stage 0 -> less than 1 matic
   */
  function setStage(uint256 number, uint256 limit) external onlyOwner {
    _stages[number] = limit;
  }

  /**
   * @dev Setting base token uri would be acceptable if using IPFS CIDs
   */
  function setBaseURI(string memory uri) external onlyOwner {
    _baseTokenURI = uri;
  }

  /**
   * @dev Sets the royalty splitter so we know what cow to show
   */
  function setTreasury(
    IRoyaltySplitter treasury
  ) external onlyOwner {
    _treasury = treasury;
  }
}