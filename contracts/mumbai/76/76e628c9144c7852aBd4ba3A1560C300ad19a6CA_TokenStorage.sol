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
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract TokenStorage {
    uint256 public constant NUM_SLABS = 5;

    // Token decimal is 6
    uint256 public constant MAX_CAPACITY = 1500000000;
    uint256[5] private slabMax = [
        1500000000,
        1400000000,
        1200000000,
        900000000,
        500000000
    ];

    // depositer => token address => deposited amount
    mapping(address => mapping(address => uint256)) public deposited;

    function deposit(address token, uint256 amount) external {
        // Transfer the token from the depositor to this contract
        require(
            deposited[msg.sender][token] + amount <= MAX_CAPACITY,
            "transfer exceeds capacity"
        );

        IERC20(token).transferFrom(msg.sender, address(this), amount);
        deposited[msg.sender][token] += amount;
    }

    function withdraw(address token, uint256 amount) external {
        require(deposited[msg.sender][token] >= amount, "insufficient balance");
        deposited[msg.sender][token] -= amount;

        // Transfer the token from this contract to the depositor
        IERC20(token).transfer(msg.sender, amount);
    }

    function getSlab(address token) external view returns (uint256) {
        require(deposited[msg.sender][token] != 0, "no slab found");
        uint256 slab;
        for (uint256 i = NUM_SLABS - 1; i >= 0; i--) {
            if (deposited[msg.sender][token] <= slabMax[i]) {
                slab = i;
                break;
            }
        }
        return slab;
    }
}