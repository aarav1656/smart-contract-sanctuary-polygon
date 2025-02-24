// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";



contract Poster {
	address tokenAddress;
	uint256 threshold;
	address public owner;
	
	event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
	event NewPost(address indexed user, string content, string indexed tag);
	
	
	event ThresholdUp(uint256 _newThreshold);
    	event TokenUp(address _newTokenAddress);
	
	constructor(address _tokenAddress, uint256 _threshold) {
		tokenAddress = _tokenAddress;
		threshold = _threshold;
		owner = msg.sender;
		emit OwnershipTransferred(address(0x0), owner);
 	}
 	modifier onlyOwner() {
		require(owner == msg.sender, "Ownable: caller is not the owner");
		_;
	}

	function transferOwnership(address _newOwner) public virtual onlyOwner {
		address oldOwner = owner;
		owner = _newOwner;
		emit OwnershipTransferred(oldOwner, _newOwner);
	}
	
	function setTokenAddress(address _newTokenAddress) public onlyOwner {
		tokenAddress = _newTokenAddress;
		emit TokenUp(_newTokenAddress);
		
	}
	
	function setThreshold(uint256 _newThreshold) public onlyOwner {
		threshold = _newThreshold;
		emit ThresholdUp(_newThreshold);
	}



	function post(string memory content, string memory tag) public {
		IERC20 token = IERC20(tokenAddress);
		uint256 balance = token.balanceOf(msg.sender);
		if (balance < threshold) revert("Not enough tokens");
		emit NewPost(msg.sender, content, tag);
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