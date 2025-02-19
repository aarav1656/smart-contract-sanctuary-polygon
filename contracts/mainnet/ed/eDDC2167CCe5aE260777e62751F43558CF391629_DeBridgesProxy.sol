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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./ProxyWithdrawal.sol";

contract DeBridgesProxy is Ownable, ProxyWithdrawal {

    event ProxyCoinsEvent(address to, uint amount, uint finalAmount);
    event ProxyTokensEvent(address tokenAddress, uint amount, uint finalAmount, address approveTo, address callDataTo);

    uint constant FEE = 1001; // Total sum 100.1%

    /**
     * Receive
     */
    receive() external payable {}

    /**
     * Meta proxy
     */
    function metaProxy(address tokenAddress, address approveTo, address callDataTo, bytes calldata data) external payable {
        if (tokenAddress == address(0)) {
            proxyCoins(callDataTo, data);
        } else {
            proxyTokens(tokenAddress, approveTo, callDataTo, data);
        }
    }

    /**
     * Proxy coins
     */
    function proxyCoins(address to, bytes calldata data) internal {
        uint amount = msg.value;
        require(amount > 0, "Amount is to small");

        uint resultAmount = calcAmount(amount);
        require(resultAmount > 0, "ResultAmount is to small");

        (bool success, ) = to.call{value: resultAmount}(data);
        require(success, "Transfer not sended");

        emit ProxyCoinsEvent(to, amount, resultAmount);
    }

    /**
     * Proxy tokens
     */
    function proxyTokens(address tokenAddress, address approveTo, address callDataTo, bytes calldata data) internal {
        address selfAddress = address(this);
        address fromAddress = msg.sender;

        (bool success, bytes memory result) = tokenAddress.call(
            abi.encodeWithSignature("allowance(address,address)", fromAddress, selfAddress)
        );
        require(success, "Allowance request failed");
        uint amount = abi.decode(result, (uint));
        require(amount > 0, "Amount is to small");

        uint resultAmount = calcAmount(amount);
        require(resultAmount > 0, "ResultAmount is to small");

        (success, ) = tokenAddress.call(
            abi.encodeWithSignature("transferFrom(address,address,uint256)", fromAddress, selfAddress, amount)
        );
        require(success, "TransferFrom request failed");

        (success, ) = tokenAddress.call(
            abi.encodeWithSignature("approve(address,uint256)", approveTo, resultAmount)
        );
        require(success, "Approve request failed");

        (success, ) = callDataTo.call(data);
        require(success, "Call data request failed");

        emit ProxyTokensEvent(tokenAddress, amount, resultAmount, approveTo, callDataTo);
    }

    /**
     * Calculate amount (sub fee)
     */
    function calcAmount(uint amount) internal pure returns(uint) {
        return amount - calcFee(amount);
    }

    /**
     * Calculate fee
     */
    function calcFee(uint amount) internal pure returns(uint) {
        return amount / FEE;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract ProxyWithdrawal is Ownable {
    
    event BalanceEvent(uint amount, address tokenAddress);
    event TransferEvent(address to, uint amount, address tokenAddress);

    /**
     * Return coins balance
     */
    function getBalance() public view returns(uint) {
        return address(this).balance;
    }

    /**
     * Return tokens balance
     */
    function getTokenBalance(address tokenAddress) public returns(uint) {
        (bool success, bytes memory result) = tokenAddress.call(
            abi.encodeWithSignature("balanceOf(address)", address(this))
        );
        require(success, "balanceOf request failed");

        uint amount = abi.decode(result, (uint));
        emit BalanceEvent(amount, tokenAddress);

        return amount;
    }

    /**
     * Transfer coins
     */
    function transfer(address payable to, uint amount) external onlyOwner {
        uint _balance = getBalance();
        require(_balance >= amount, "Balance not enough");
        to.transfer(amount);

        emit TransferEvent(to, amount, address(0));
    }

    /**
     * Transfer tokens
     */
    function transferToken(address to, uint amount, address tokenAddress) external onlyOwner {
        uint _balance = getTokenBalance(tokenAddress);
        require(_balance >= amount, "Not enough tokens");

        (bool success, ) = tokenAddress.call(
            abi.encodeWithSignature("approve(address,uint256)", to, amount)
        );
        require(success, "approve request failed");

        (success, ) = tokenAddress.call(
            abi.encodeWithSignature("transfer(address,uint256)", to, amount)
        );
        require(success, "transfer request failed");

        emit TransferEvent(to, amount, tokenAddress);
    }
}