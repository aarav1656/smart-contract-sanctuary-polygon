// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";

contract CipherPunkWhitelist is Ownable {

  bool public paused = false;
  uint256 public totalAddresses = 0;
  uint256 public totalAmount = 0;
  
  mapping (address => bool) public whitelisted;
  mapping (address => uint256) public expectedAmount;

  address[] public whitelistedAddresses;

  // EVENTS
  event UserJoinWhitelist(address user, uint256 amount);

  // READ
  function isWhitelisted(address _user) external view returns(bool) {
    return whitelisted[_user];
  }

  // WRITE
  function joinWhitelist(uint256 _amount) external {
    require(!paused || msg.sender == owner(), "Whitelisting is paused.");
    require(_amount <= 50_000, "Amount is too high.");

    _addToWhitelist(msg.sender, _amount);
  }

  function _addToWhitelist(address _addr, uint256 _amount) internal {
    if (whitelisted[_addr]) {
      // if user already whitelisted
      totalAmount -= expectedAmount[_addr]; // subtract the previous amount from total
      expectedAmount[_addr] = _amount; // store new amount
      totalAmount += _amount; // add new amount to total
    } else {
      // if not yet whitelisted
      whitelisted[_addr] = true;
      expectedAmount[_addr] = _amount;
      whitelistedAddresses.push(_addr);
      ++totalAddresses;
      totalAmount += _amount;
    }

    emit UserJoinWhitelist(_addr, _amount);
  }

  // OWNER
  function ownerAddToWhitelist(address[] calldata _addresses, uint256[] calldata _amounts) external onlyOwner {
    uint256 length = _addresses.length;

    for (uint256 i = 0; i < length;) {
      _addToWhitelist(_addresses[i], _amounts[i]);
      unchecked { ++i; }
    }
  }

  function togglePaused() external onlyOwner {
    paused = !paused;
  }

}

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