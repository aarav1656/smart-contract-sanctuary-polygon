// SPDX-License-Identifier: MIT

/**
*
*      ___           ___           ___           ___                    ___           ___                    ___           ___           ___           ___ 
*     /\__\         /\  \         /\  \         /\  \                  /\  \         /\  \                  /\  \         /\  \         /\  \         /\__\
*    /:/  /        /::\  \       /::\  \       /::\  \                 \:\  \       /::\  \                /::\  \       /::\  \       /::\  \       /:/  /
*   /:/__/        /:/\:\  \     /:/\:\  \     /:/\:\  \                 \:\  \     /:/\:\  \              /:/\:\  \     /:/\:\  \     /:/\:\  \     /:/  / 
*  /::\  \ ___   /::\~\:\  \   /::\~\:\  \   /::\~\:\  \                /::\  \   /:/  \:\  \            /:/  \:\  \   /:/  \:\  \   /:/  \:\  \   /:/  /  
* /:/\:\  /\__\ /:/\:\ \:\__\ /:/\:\ \:\__\ /:/\:\ \:\__\              /:/\:\__\ /:/__/ \:\__\          /:/__/ \:\__\ /:/__/ \:\__\ /:/__/ \:\__\ /:/__/   
* \/__\:\/:/  / \:\~\:\ \/__/ \/_|::\/:/  / \:\~\:\ \/__/             /:/  \/__/ \:\  \ /:/  /          \:\  \  \/__/ \:\  \ /:/  / \:\  \ /:/  / \:\  \   
*      \::/  /   \:\ \:\__\      |:|::/  /   \:\ \:\__\              /:/  /       \:\  /:/  /            \:\  \        \:\  /:/  /   \:\  /:/  /   \:\  \  
*      /:/  /     \:\ \/__/      |:|\/__/     \:\ \/__/              \/__/         \:\/:/  /              \:\  \        \:\/:/  /     \:\/:/  /     \:\  \ 
*     /:/  /       \:\__\        |:|  |        \:\__\                               \::/  /                \:\__\        \::/  /       \::/  /       \:\__\
*     \/__/         \/__/         \|__|         \/__/                                \/__/                  \/__/         \/__/         \/__/         \/__/
*
* @title Tres Cool Delegate Polygon
* @authors Tres Cool Labs (www.trescool.xyz)
*/

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

pragma solidity ^0.8.2;

/// @dev Fund forwarding to a delegate address. 
contract TresCoolDelegatePolygon is Ownable, ReentrancyGuard {

    /* Private Variables */

    bool private _automate = true;
    address private _delegate = address(0);

    /* Setters */

    /// @notice Set the contract to automate the distribution of funds or not
    function setAutomate(bool automate) external onlyOwner {
        _automate = automate;
    }

    /// @notice Set the delegate address to receive funds
    function setDelegate(address delegate) external onlyOwner {
        _delegate = delegate;
    }

    /* Getters */

    /// @notice Gets the delegate address to receive funds
    function getDelegate() external view returns(address) {
        return _delegate;
    }

    /// @notice Gets the automate settings which automates the distribution of funds
    function getAutomate() external view returns(bool) {
        return _automate;
    }

    /* Fallbacks */

    /// @notice Handles receiving of funds
    /// @dev Will automate forward of funds if _automate is set to true. Otherwise will hold. 
    receive() payable external {
        if(_automate) _distribute(msg.value);
    }

    /* Distributions */

    /// @notice Internal distribution of funds 
    /// @dev Will send the value passed in to the _delegate address
    function _distribute(uint value) private {
        if(value > 0) {
            (bool sent,) = payable(_delegate).call{value: value}("");
            require(sent, "Failed to distribute eth");
        }
    }

    /// @notice Internal distribution of ERC20 funds 
    /// @dev Will send the ERC20 value passed in to the _delegate address
    function _distributeERC20(uint value, IERC20 tokenContract) private {
        tokenContract.transfer(_delegate, value);
    }

    /// @notice External distribution of funds held by contract
    /// @dev Will distribute the set amount passed in all of the contract balance if amount is zero
    function distribute(uint amount) external onlyOwner nonReentrant {
        uint balance = address(this).balance;
        require(balance > 0, "Must have a balance to distribute.");
        require(balance >= amount, "Must have enough balance to distribute.");
        uint value = amount > 0 ? amount : balance;
        _distribute(value);
    }

    /// @notice External distribution of ERC20 funds held by contract
    /// @dev Will distribute the set amount passed in all of the contract balance if amount is zero
    function distributeERC20(uint amount, address token) external onlyOwner nonReentrant {
        IERC20 tokenContract = IERC20(token);
        uint balance = tokenContract.balanceOf(address(this));
        require(balance > 0, "Must have a balance to distribute ERC20.");
        require(balance >= amount, "Must have enough balance to distribute ERC20.");
        uint value = amount > 0 ? amount : balance;
        _distributeERC20(value, tokenContract);
    }

    /* Ownership */

    /// @notice Prevents ownership renouncement
    /// @dev overrides the internal renounceOwnership() function and does nothing.
    function renounceOwnership() public override onlyOwner {}
    
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
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