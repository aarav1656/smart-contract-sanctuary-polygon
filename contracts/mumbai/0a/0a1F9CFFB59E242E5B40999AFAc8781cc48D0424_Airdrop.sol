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

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Airdrop {
    address payable public owner;
    mapping (address => bool) public claimed;
    mapping (address => bool) public eligible; 
    IERC20 public token; // added variable to track the ERC20 token
    uint256 public airdropAmount;
    

    constructor(address _tokenAddress, uint256 _airdropAmount)  {
        owner = payable(msg.sender);
        token = IERC20(_tokenAddress); 
        airdropAmount = _airdropAmount;
    }

     function setEligible(address[] calldata addresses) public onlyOwner {
        for(uint i = 0; i < addresses.length; i++){
            eligible[addresses[i]] = true;
        }
    }    

    function addEligible(address _user) public onlyOwner {
        eligible[_user] = true;
    }

    function changeEligible(address[] calldata addresses) public onlyOwner {
        for(uint i = 0; i < addresses.length; i++){
            eligible[addresses[i]] = false;
        }
    }

    function removeEligible(address _user) public onlyOwner {
        eligible[_user] = false;
    }


    function claim() public {
        require(eligible[msg.sender], "You are not eligible to claim this airdrop");
        require(!claimed[msg.sender], "You have already claimed your airdrop");
        require(IERC20(token).transfer(msg.sender, airdropAmount), "Airdrop failed"); // transfer the token to the user's address
        claimed[msg.sender] = true;
    }

    function transfer(address _to,uint256 _amount) public {  // create function that you want to use to fund your contract or transfer that token
        require(token.transferFrom(msg.sender,_to,_amount));
     } // call function of your token contract to do the transfer

    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not the owner");
        _;
    }
}