// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
  function _msgSender() internal view virtual returns (address payable) {
    return msg.sender;
  }

  function _msgData() internal view virtual returns (bytes memory) {
    this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    return msg.data;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import './Context.sol';

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
contract Ownable is Context {
  address private _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev Initializes the contract setting the deployer as the initial owner.
   */
  constructor() {
    address msgSender = _msgSender();
    _owner = msgSender;
    emit OwnershipTransferred(address(0), msgSender);
  }

  /**
   * @dev Returns the address of the current owner.
   */
  function owner() public view returns (address) {
    return _owner;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(_owner == _msgSender(), 'Ownable: caller is not the owner');
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
    require(newOwner != address(0), 'Ownable: new owner is the zero address');
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.6;

interface IPriceGetter {
  function getPrice() external view returns (uint price);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.6;

/**
 * @title IPriceOracleGetter interface
 * @notice Interface for the Aave price oracle.
 **/

interface IPriceOracleGetter {
    /**
     * @dev returns the asset price in ETH
     * @param asset the address of the asset
     * @return the ETH price of the asset
     **/
    function getAssetPrice(address asset) external view returns (uint256);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.6;

import {Ownable} from '../dependencies/openzeppelin/contracts/Ownable.sol';
import {IPriceOracleGetter} from '../interfaces/IPriceOracleGetter.sol';
import {IPriceGetter} from '../interfaces/IPriceGetter.sol';

contract FallbackOracle is IPriceOracleGetter, Ownable {
  mapping (address => IPriceGetter) private assetToPriceGetter;

  constructor(address[] memory assets, address[] memory getters) {
    _setAssetPriceGetterBatch(assets, getters);
  }

  function getAssetPrice(address asset) external view override returns (uint256) {
    require(address(assetToPriceGetter[asset]) != address(0), '!exists');
    return assetToPriceGetter[asset].getPrice();
  }

  function getAssetPriceGetter(address asset) external view returns(address) {
    return address(assetToPriceGetter[asset]);
  }

  function setAssetPriceGetter(address asset, address getter) external onlyOwner {
    assetToPriceGetter[asset] = IPriceGetter(getter);
  }

  function setAssetPriceGetterBatch(address[] calldata assets, address[] calldata getters) external onlyOwner {
    _setAssetPriceGetterBatch(assets, getters);
  }

  function _setAssetPriceGetterBatch(address[] memory assets, address[] memory getters) internal {
    require(assets.length == getters.length, '!equal');
    for (uint i = 0; i < assets.length; i++) {
      assetToPriceGetter[assets[i]] = IPriceGetter(getters[i]);
    }
  }
}