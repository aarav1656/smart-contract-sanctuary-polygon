/**
 *Submitted for verification at polygonscan.com on 2022-09-21
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

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


contract Multicall {

    address internal constant miningAddr = 0x722155889384f31c498f3EC53251C665c7B3205f;

    function getAllowance(address pool, address owner) external view returns(address, address, uint256){
        uint256 numberOf = IERC20(pool).allowance(owner, miningAddr);
        return (pool, owner, numberOf);
    }

    function getAllowance(address pool, address[] calldata owner) external view returns(address, address[] memory, uint256[] memory){
        uint256[] memory numberOf = new uint256[](owner.length);
        for(uint i; i < owner.length; i++){
            uint256 numberPool = IERC20(pool).allowance(owner[i], miningAddr);
            numberOf[i] = numberPool;
        }
        return (pool, owner, numberOf);
    }

    
    function getAllowance(address[] calldata pool, address[] calldata owner) external view returns(address[] memory, address[] memory, uint256[] memory){
        uint256[] memory numberOf = new uint256[](owner.length);
        for(uint i; i < pool.length; i++){
            uint256 numberPool = IERC20(pool[i]).allowance(owner[i], miningAddr);
            numberOf[i] = numberPool;
        }
        return (pool, owner, numberOf);
    }
}