/**
 *Submitted for verification at polygonscan.com on 2023-03-09
*/

// Sources flattened with hardhat v2.11.2 https://hardhat.org

// File @openzeppelin/contracts/utils/[email protected]4.7.3

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


// File @openzeppelin/contracts/access/[email protected]

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


// File contracts/WalletManagement.sol

pragma solidity ^0.8.0;

contract WalletManagement is Ownable {
    // ========= STRUCT ========= //
    struct WalletConfig {
        address wallet;
        string roundId;
    }

    struct WalletConfigInput {
        string key;
        WalletConfig config;
    }

    // ========= STATE VARIABLE ========= //
    mapping(string => WalletConfig) public wallets;

    // ========= EVENT ========= //
    event WalletAdded(address wallet, string roundId, string key);
    event WalletRemoved(address wallet, string roundId, string key);
    event WalletUpdated(address wallet, string roundId, string key);

    function addWallets(WalletConfigInput[] calldata _walletConfigs)
    external
    onlyOwner
    {
        for (uint256 i = 0; i < _walletConfigs.length; i++) {
            WalletConfigInput memory walletConfig = _walletConfigs[i];
            wallets[walletConfig.key] = walletConfig.config;
            emit WalletAdded(walletConfig.config.wallet, walletConfig.config.roundId, walletConfig.key);
        }
    }

    function removeWallets(string[] calldata _keys, string calldata roundId) external onlyOwner {
        for (uint256 i = 0; i < _keys.length; i++) {
            WalletConfig memory walletConfig = wallets[_keys[i]];
            delete wallets[_keys[i]];
            emit WalletRemoved(walletConfig.wallet, roundId, _keys[i]);
        }
    }

    function updateWallet(string calldata _key, WalletConfig calldata _config)
    external
    onlyOwner
    {
        wallets[_key] = _config;
        emit WalletUpdated(_config.wallet, _config.roundId, _key);
    }
}