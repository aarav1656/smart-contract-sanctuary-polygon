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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
        /$$$$$$            /$$$$$$$  /$$$$$$$$ /$$$$$$        /$$$$$$$  /$$        /$$$$$$   /$$$$$$  /$$$$$$$$
        /$$$_  $$          | $$__  $$|__  $$__//$$__  $$      | $$__  $$| $$       /$$__  $$ /$$__  $$| $$_____/
        | $$$$\ $$ /$$   /$$| $$  \ $$   | $$  | $$  \__/      | $$  \ $$| $$      | $$  \ $$| $$  \__/| $$      
        | $$ $$ $$|  $$ /$$/| $$$$$$$    | $$  | $$            | $$$$$$$/| $$      | $$$$$$$$| $$      | $$$$$   
        | $$\ $$$$ \  $$$$/ | $$__  $$   | $$  | $$            | $$____/ | $$      | $$__  $$| $$      | $$__/   
        | $$ \ $$$  >$$  $$ | $$  \ $$   | $$  | $$    $$      | $$      | $$      | $$  | $$| $$    $$| $$      
        |  $$$$$$/ /$$/\  $$| $$$$$$$/   | $$  |  $$$$$$/      | $$      | $$$$$$$$| $$  | $$|  $$$$$$/| $$$$$$$$
        \______/ |__/  \__/|_______/    |__/   \______/       |__/      |________/|__/  |__/ \______/ |________/


        Built and opensourced by Fappablo#8171
        https://github.com/fappablo/0xbitcoin-space
        https://github.com/fappablo/0xbitcoin-place-backend
        https://github.com/fappablo/0xbitcoin-space-contract        

        DISCLAIMER: I take no responsability for the content displayed on the canvas                                                                                                                                                                                                                                                                                                                                                            
*/

contract The0xBitcoinSpace is Ownable {
    address internal acceptedCurrency = 0x71B821aa52a49F32EEd535fCA6Eb5aa130085978;
    address internal devWallet = 0x995e3e70f983D231a212c2A7210FC36a5B70CC39;
    uint256 internal pricePerPixel = 1000000;

    constructor() {}

    event PixelsPlaced(uint256[] x, uint256[] y, uint256[] color);

    function placePixels(
        uint256[] calldata x,
        uint256[] calldata y,
        uint256[] calldata color
    ) public {
        uint256 len = x.length;

        require(
            y.length == len && color.length == len,
            "Different argument dimensions"
        );

        require(
            IERC20(acceptedCurrency).transferFrom(
                _msgSender(),
                devWallet,
                pricePerPixel * len
            ),
            "User must have paid"
        );

        emit PixelsPlaced(x, y, color);
    }

    function updatePrice(uint256 newPrice) external onlyOwner {
        require(newPrice > 0);
        pricePerPixel = newPrice;
    }

    //Got to get hacked every now and then
    function updateDevWallet(address newWallet) external onlyOwner {
        devWallet = newWallet;
    }

    //0xBTC V2?
    function updateAcceptedCurrency(address newAcceptedCurrency)
        external
        onlyOwner
    {
        acceptedCurrency = newAcceptedCurrency;
    }
}