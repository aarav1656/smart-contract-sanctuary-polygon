// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

contract SummoningDeployer is Ownable {
  // 0 -> access control
  // 1 -> ca state
  // 2 -> erc721 summoning champion // new
  // 3 -> summoning state // new
  // 4 -> champion utils // new
  // 5 -> summoning service // new
  // 6 -> summoning route // new
  // 7 -> zoo keeper
  mapping(uint256 => address) public elements;

  constructor() {
    // replace deployed contract here.
    elements[0] = 0x0bF8b07D3A0C83C5DDe4e12143A4203897f55F90;

    elements[1] = 0x5A06c52A8B4eF58173A91A8fFE342A09AaF4Fc9D;
    elements[2] = 0x874fB0dfe9FcD11B41CeFdd134454581768f7F49; // new
    elements[3] = 0x4373b478f888f01Ce0a455968178dbD3533425ce; // new

    elements[4] = 0x755a6C0F5a0EbD8Dae7fCb5594441bF3A542a167; // new
    elements[5] = 0xe74152309Dd5eB053D5970485C4139968122895D; // new
    elements[6] = 0xA359a74624E7A3b99969F4f8fE73638Bf6584Fa6; // new
    elements[7] = 0x50509eCacA1665129280B5eaBFd5E93a8e5F58de;
  }

  function setContracts(uint256[] memory _ids, address[] memory _contracts) external onlyOwner {
    require(_ids.length == _contracts.length, "Input mismatch");

    for (uint256 i = 0; i < _ids.length; i++) {
      elements[_ids[i]] = _contracts[i];
    }
  }

  function setupRouterRolesForAdmin(address[] memory _contracts) external onlyOwner {
    for (uint256 i = 0; i < _contracts.length; i++) {
      IAll(elements[0]).grantMaster(_contracts[i], elements[6]);
    }
  }

  function init() external onlyOwner {
    IAll(elements[0]).grantMaster(address(this), elements[1]);
    IAll(elements[0]).grantMaster(address(this), elements[2]);
    IAll(elements[0]).grantMaster(address(this), elements[3]);

    IAll(elements[0]).grantMaster(address(this), elements[4]);
    IAll(elements[0]).grantMaster(address(this), elements[5]);
    IAll(elements[0]).grantMaster(address(this), elements[6]);
    IAll(elements[0]).grantMaster(address(this), elements[7]);
  }

  function setup() external onlyOwner {
    IAll(elements[0]).setAccessControlProvider(elements[0]);
    IAll(elements[1]).setAccessControlProvider(elements[0]);
    IAll(elements[2]).setAccessControlProvider(elements[0]);
    IAll(elements[3]).setAccessControlProvider(elements[0]);
    IAll(elements[4]).setAccessControlProvider(elements[0]);
    IAll(elements[5]).setAccessControlProvider(elements[0]);
    IAll(elements[6]).setAccessControlProvider(elements[0]);
    IAll(elements[7]).setAccessControlProvider(elements[0]);
  }

  function bindingService() external onlyOwner {
    IAll(elements[0]).grantMaster(elements[5], elements[1]);
    IAll(elements[0]).grantMaster(elements[5], elements[2]);
    IAll(elements[0]).grantMaster(elements[5], elements[3]);
    IAll(elements[0]).grantMaster(elements[5], elements[7]);

    IAll(elements[5]).bindChampionAttributesState(elements[1]);
    IAll(elements[5]).bindSummoningChampionContract(elements[2]);
    IAll(elements[5]).bindSummoningState(elements[3]);
    IAll(elements[5]).bindChampionUtils(elements[4]);
    IAll(elements[5]).bindZooKeeper(elements[7]);
  }

  function bindingServiceForRoute() external onlyOwner {
    IAll(elements[0]).grantMaster(elements[6], elements[5]);
    IAll(elements[6]).bindService(elements[5]);
  }
}

interface IAll {
  function setAccessControlProvider(address) external;

  function grantMaster(address, address) external;

  function bindChampionAttributesState(address) external;

  function bindSummoningChampionContract(address) external;

  function bindSummoningState(address) external;

  function bindChampionUtils(address) external;

  function bindZooKeeper(address) external;

  function bindService(address) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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