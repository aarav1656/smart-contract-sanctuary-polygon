// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

//
//   +-+ +-+ +-+   +-+ +-+ +-+   +-+ +-+ +-+ +-+ +-+ +-+ +-+
//   |T| |h| |e|   |R| |e| |d|   |V| |i| |l| |l| |a| |g| |e|
//   +-+ +-+ +-+   +-+ +-+ +-+   +-+ +-+ +-+ +-+ +-+ +-+ +-+
//
//
//   The Red Village + Pellar 2022
//

contract TRVDeployer is Ownable {
  // 0 -> access control
  // 1 -> ca state
  // 2 -> cf state
  // 3 -> tournament state
  // 4 -> champion utils // new
  // 5 -> blooding service // new
  // 6 -> bloodbath service // new
  // 7 -> blood elo service // new
  // 8 -> solo service
  // 9 -> tournament route
  // 10 -> zoo keeper
  // 11 -> summoning restriction
  mapping(uint256 => address) public elements;

  constructor() {
    // replace deployed contract here.
    elements[0] = 0x3f0B50B7A270de536D5De35C11C2613284C4304e;

    elements[1] = 0x54a5Bd715f60931627B8d67C4B7b82758F3B8a16;
    elements[2] = 0x2f6FC934242583A96Ef6ACBF933132eBba094E1a;
    elements[3] = 0x4c856111387B2cb179c841680e403D4dd27601de;

    elements[4] = 0xcF1552c0627C68F6AeD99911baa2529C6c1C289D; // new
    elements[5] = 0xf679FEa37783e5B7a11a2d6FF2BEA4651F35c372; // new
    elements[6] = 0x1f02D4483A54fF54FC4d3eEC186C44AFCE304A9d; // new
    elements[7] = 0xa397c0e45723633EC465Ea64F02a3785f6cab68b; // new
    elements[8] = 0x97729e51A6d04bae2Db3cA5127183963AE6efCE6;

    elements[9] = 0xF681C909C16a0c5AA10308075144DC5666e936BE;

    elements[10] = 0x426d27190A2DdB87f1C6235F710e159a0A3774D4;

    // summoning
    elements[11] = 0x2d2481188Ff7452876E44D2a0dC8AFd0a8d89C14; // new
  }

  function setContracts(uint256[] memory _ids, address[] memory _contracts) external onlyOwner {
    require(_ids.length == _contracts.length, "Input mismatch");

    for (uint256 i = 0; i < _ids.length; i++) {
      elements[_ids[i]] = _contracts[i];
    }
  }

  function setupRouterRolesForAdmin(address[] memory _contracts) external onlyOwner {

    for (uint256 i = 0; i < _contracts.length; i++) {
      IAll(elements[0]).grantMaster(_contracts[i], elements[9]);
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
    IAll(elements[0]).grantMaster(address(this), elements[8]);

    IAll(elements[0]).grantMaster(address(this), elements[9]);
    IAll(elements[0]).grantMaster(address(this), elements[10]);
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
    IAll(elements[8]).setAccessControlProvider(elements[0]);
    IAll(elements[9]).setAccessControlProvider(elements[0]);
    IAll(elements[10]).setAccessControlProvider(elements[0]);
  }

  function bindingService() external onlyOwner {
    bindingRoleForService(elements[5]);
    bindingRoleForService(elements[6]);
    bindingRoleForService(elements[7]);
    bindingRoleForService(elements[8]);

    IAll(elements[5]).bindSummoningRestriction(elements[11]);
    IAll(elements[6]).bindSummoningRestriction(elements[11]);
    IAll(elements[7]).bindSummoningRestriction(elements[11]);
  }

  function bindingRoleForService(address _service) internal {
    IAll(elements[0]).grantMaster(_service, elements[1]);
    IAll(elements[0]).grantMaster(_service, elements[2]);
    IAll(elements[0]).grantMaster(_service, elements[3]);
    IAll(elements[0]).grantMaster(_service, elements[10]);
    IAll(elements[0]).grantMaster(_service, elements[11]);

    IAll(_service).bindChampionAttributesState(elements[1]);
    IAll(_service).bindChampionFightingState(elements[2]);
    IAll(_service).bindTournamentState(elements[3]);
    IAll(_service).bindChampionUtils(elements[4]);
    IAll(_service).bindZooKeeper(elements[10]);
  }

  function bindingRoleForRoute() external onlyOwner {
    IAll(elements[0]).grantMaster(elements[9], elements[5]);
    IAll(elements[0]).grantMaster(elements[9], elements[6]);
    IAll(elements[0]).grantMaster(elements[9], elements[7]);
    IAll(elements[0]).grantMaster(elements[9], elements[8]);
  }

  function bindingServiceForRoute() external onlyOwner {
    IAll(elements[9]).bindService(0, elements[8]);
    IAll(elements[9]).bindService(1, elements[5]);
    IAll(elements[9]).bindService(2, elements[6]);
    IAll(elements[9]).bindService(3, elements[7]);
  }
}

interface IAll {
  function setAccessControlProvider(address) external;

  function grantMaster(address, address) external;

  function bindChampionAttributesState(address) external;

  function bindChampionFightingState(address) external;

  function bindTournamentState(address) external;

  function bindChampionUtils(address) external;

  function bindSummoningRestriction(address) external;

  function bindZooKeeper(address) external;

  function bindService(uint64, address) external;
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