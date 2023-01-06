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
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

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
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
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
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
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
pragma solidity ^0.8.17;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/Pausable.sol';

interface ICoolERC721A {
  function mint(address to, uint256 amount) external;
}

contract BaseMinter is Ownable, Pausable {
  address public _tokenAddress;
  ICoolERC721A public _tokenContract;

  event TokenContractSet(address tokenAddress);

  constructor(address tokenAddress) {
    _tokenAddress = tokenAddress;
    _tokenContract = ICoolERC721A(tokenAddress);

    _pause();
  }

  function pause() external onlyOwner {
    _pause();
  }

  function unpause() external onlyOwner {
    _unpause();
  }

  function setTokenContract(address tokenAddress) external onlyOwner {
    _tokenAddress = tokenAddress;
    _tokenContract = ICoolERC721A(tokenAddress);

    emit TokenContractSet(tokenAddress);
  }

  function canUserBeMintedTo(
    address user
  ) public view virtual returns (bool result, string memory reason) {
    if (paused()) return (false, 'Sale is paused');

    return (true, '');
  }

  function _mint(address to, uint256 amount) internal virtual whenNotPaused {
    _tokenContract.mint(to, amount);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import '../LimitedMinter.sol';

contract CappedMinter is LimitedMinter {
  uint256 public _maxMintAmount;
  uint256 public _mintedAmount;

  event MaxMintAmountSet(uint256 maxMintAmount);

  error MintAmountExceedsMax(uint256 amount, uint256 maxAmount);

  constructor(
    address tokenContract,
    uint256 maxPerTx,
    uint256 maxPerWallet,
    uint256 maxMintAmount
  ) LimitedMinter(tokenContract, maxPerTx, maxPerWallet) {
    _maxMintAmount = maxMintAmount;

    emit MaxMintAmountSet(maxMintAmount);
  }

  function _mint(address to, uint256 amount) internal override {
    if (_mintedAmount + amount > _maxMintAmount) {
      revert MintAmountExceedsMax(amount, _maxMintAmount - _mintedAmount);
    }

    _mintedAmount += amount;

    super._mint(to, amount);
  }

  function setMaxMintAmount(uint256 maxMintAmount) external virtual onlyOwner {
    _maxMintAmount = maxMintAmount;

    emit MaxMintAmountSet(maxMintAmount);
  }

  function canUserBeMintedTo(
    address user
  ) public view virtual override returns (bool result, string memory reason) {
    if (_mintedAmount >= _maxMintAmount) return (false, 'Sold out');

    return super.canUserBeMintedTo(user);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import './CappedMinter.sol';
import '../SystemVerified.sol';

contract CappedSystemMinter is CappedMinter, SystemVerified {
  constructor(
    address tokenContract,
    uint256 maxPerTx,
    uint256 maxPerWallet,
    uint256 maxMintAmount,
    address system
  ) CappedMinter(tokenContract, maxPerTx, maxPerWallet, maxMintAmount) SystemVerified(system) {}

  function mint(address to, uint256 amount) external virtual onlySystem {
    _mint(to, amount);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import './BaseMinter.sol';

contract LimitedMinter is BaseMinter {
  uint256 public _maxPerTx;
  uint256 public _maxPerWallet;

  mapping(address => uint256) public _mintedPerWallet;

  event MaxPerTxSet(uint256 maxPerTx);
  event MaxPerWalletSet(uint256 maxPerWallet);

  error MaxPerTxExceeded(uint256 maxPerTx, uint256 amount);
  error MaxPerWalletExceeded(uint256 maxPerWallet, uint256 amount);

  constructor(
    address tokenContract,
    uint256 maxPerTx,
    uint256 maxPerWallet
  ) BaseMinter(tokenContract) {
    _maxPerTx = maxPerTx;
    _maxPerWallet = maxPerWallet;
  }

  function setMaxPerTx(uint256 maxPerTx) external onlyOwner {
    _maxPerTx = maxPerTx;

    emit MaxPerTxSet(maxPerTx);
  }

  function setMaxPerWallet(uint256 maxPerWallet) external onlyOwner {
    _maxPerWallet = maxPerWallet;

    emit MaxPerWalletSet(maxPerWallet);
  }

  function canUserBeMintedTo(
    address user
  ) public view virtual override returns (bool result, string memory reason) {
    if (_mintedPerWallet[user] >= _maxPerWallet) return (false, 'Max per wallet exceeded');

    return super.canUserBeMintedTo(user);
  }

  function _mint(address to, uint256 amount) internal virtual override {
    if (_maxPerTx > 0 && amount > _maxPerTx) {
      revert MaxPerTxExceeded(_maxPerTx, amount);
    }

    uint256 mintedPerWallet = _mintedPerWallet[to];
    if (_maxPerWallet > 0 && mintedPerWallet + amount > _maxPerWallet) {
      revert MaxPerWalletExceeded(_maxPerWallet, amount);
    }

    _mintedPerWallet[to] = mintedPerWallet + amount;

    super._mint(to, amount);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import '@openzeppelin/contracts/access/Ownable.sol';

contract SystemVerified is Ownable {
  address public _systemAddress;

  event SystemAddressSet(address systemAddress);

  error NotSystem();

  modifier onlySystem() {
    if (msg.sender != _systemAddress) {
      revert NotSystem();
    }
    _;
  }

  constructor(address system) {
    _systemAddress = system;

    emit SystemAddressSet(system);
  }

  function setSystemAddress(address system) external onlyOwner {
    _systemAddress = system;

    emit SystemAddressSet(system);
  }
}