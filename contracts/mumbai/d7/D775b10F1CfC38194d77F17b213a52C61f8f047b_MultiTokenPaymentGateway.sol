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

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


contract MultiTokenPaymentGateway {
	address owner;
	mapping(address => uint) balances;

	event depositDone(address tokenAddress, uint256 amount);

	// Constructor to set token contract and payment amount
	constructor() {
		owner = msg.sender;
	}

	function depositFunds(IERC20 tokenAddress, uint256 amount) public {
		require(tokenAddress.balanceOf(msg.sender) >= amount, "Your token amount must be greater then you are trying to deposit");
		require(tokenAddress.approve(address(this), amount));
		require(tokenAddress.transferFrom(msg.sender, address(this), amount));

		emit depositDone(address(tokenAddress), amount);
	}

	function returnBalance(IERC20 token, address walletAddress) public view returns (uint256) {
		uint256 tokenAmount = token.balanceOf(address(walletAddress));
		return tokenAmount;
	}

	function withdrawFunds(IERC20 tokenToLock, uint256 amount) public {
		require(msg.sender == owner, "Only owner can withdraw funds");
		require(amount > 0, "Withdraw amount must be greater than 0");
		require(tokenToLock.balanceOf(address(this)) >= amount, "Insufficient funds");
		tokenToLock.transfer(msg.sender, amount);
		// owner.transfer(amount);
	}
}