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
pragma solidity 0.8.1;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract BloomTreasure {
    address private DAI;
    address private USDC;
    address private USDT;
    IERC20 private dai;
    IERC20 private usdc;
    IERC20 private usdt;
    struct Token {
        uint256 balance;
    }
    struct Treasure {
        Token native;
        Token dai;
        Token usdt;
        Token usdc;
    }
    string[] private tokens = ["NATIVE", "DAI", "USDC", "USDT"];
    address[] private owners;
    uint256 private percentage = 100; // 1% in basis points
    Treasure treasure;

    constructor(
        address[] memory _owners,
        address _dai,
        address _usdc,
        address _usdt
    ) {
        //Set an array of owners that can withdrawl the balance
        owners = _owners;
        DAI = _dai;
        dai = IERC20(DAI);
        USDT = _usdt;
        usdt = IERC20(USDT);
        USDC = _usdc;
        usdc = IERC20(USDC);
    }

    function addOwner(address newOwner) public {
        bool isOwner = checkOwnership(owners, msg.sender);
        if (!isOwner) {
            revert("You are not an owner");
        } else {
            owners.push(newOwner);
        }
    }

    function deleteOwner(address ownerToDelete) public {
        bool isOwner = checkOwnership(owners, msg.sender);
        if (!isOwner) {
            revert("You are not an owner");
        } else {
            for (uint256 i = 0; i < owners.length; i++) {
                if (owners[i] == ownerToDelete) {
                    owners[i] = owners[owners.length - 1];
                    owners.pop();
                }
            }
        }
    }

    function amIAnOwner(address addressToCheck) public view returns (bool) {
        //Check if the caller is an owner
        bool ownership = checkOwnership(owners, addressToCheck);
        return ownership;
    }

    function calculateFee(uint256 amount) public view returns (uint256) {
        return (amount * percentage) / 10000;
    }

    function fundTreasureWithNativeCurrency() external payable {
        treasure.native.balance += msg.value;
    }

    function updateInternalBalanceOfTokens() public {
        treasure.dai.balance = dai.balanceOf(address(this));
        treasure.usdc.balance = usdc.balanceOf(address(this));
        treasure.usdt.balance = usdt.balanceOf(address(this));
    }

    function getPublicBalanceOfNativeCurrency() public view returns (uint256) {
        return treasure.native.balance;
    }

    function getPublicBalanceOfDAI() public view returns (uint256) {
        return treasure.dai.balance;
    }

    function getPublicBalanceOfUSDT() public view returns (uint256) {
        return treasure.usdt.balance;
    }

    function getPublicBalanceOfUSDC() public view returns (uint256) {
        return treasure.usdc.balance;
    }

    function withdrawl(
        string memory tokenToRetrieve,
        uint256 amountToRetrieve
    ) public {
        bool isOwner = false;
        isOwner = checkOwnership(owners, msg.sender);
        require(isOwner, "You are not an owner");
        if (compareStrings(tokenToRetrieve, "NATIVE")) {
            require(
                amountToRetrieve < treasure.native.balance,
                "Not enough Native Currency in the treasure"
            );
            payable(msg.sender).transfer(amountToRetrieve);
            treasure.native.balance -= amountToRetrieve;
        }
        if (compareStrings(tokenToRetrieve, "DAI")) {
            require(
                amountToRetrieve <= treasure.dai.balance,
                "Not enough DAI in the treasure"
            );
            require(
                dai.transfer(msg.sender, amountToRetrieve),
                "DAI transfer failed"
            );
            treasure.dai.balance -= amountToRetrieve;
        }
        if (compareStrings(tokenToRetrieve, "USDC")) {
            require(
                amountToRetrieve <= treasure.usdc.balance,
                "Not enough USDC in the treasure"
            );
            require(
                usdc.transfer(msg.sender, amountToRetrieve),
                "USDC transfer failed"
            );
            treasure.usdc.balance -= amountToRetrieve;
        }
        if (compareStrings(tokenToRetrieve, "USDT")) {
            require(
                amountToRetrieve <= treasure.usdt.balance,
                "Not enough USDT in the treasure"
            );
            require(
                usdt.transfer(msg.sender, amountToRetrieve),
                "USDT transfer failed"
            );
            treasure.usdt.balance -= amountToRetrieve;
        }
    }

    function checkOwnership(
        address[] memory _owners,
        address sender
    ) internal pure returns (bool) {
        bool isOwner = false;
        for (uint256 j = 0; j < _owners.length; j++) {
            if (_owners[j] == sender) {
                isOwner = true;
            }
        }
        return isOwner;
    }

    function compareStrings(
        string memory a,
        string memory b
    ) internal pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) ==
            keccak256(abi.encodePacked((b))));
    }
}