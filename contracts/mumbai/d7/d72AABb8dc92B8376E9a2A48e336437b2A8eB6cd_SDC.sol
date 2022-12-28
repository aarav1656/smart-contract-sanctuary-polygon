// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./TempContract.sol";

contract SDC {

    address payable private sdcAddress;
    address private usdtAddress;

    event WaletConect(string json, uint256 amount);
    event LotsNewContracts(address[], uint256);
    event SubContract(uint256 amount, address sender);
    event USDTWalletConnect(string json);

    constructor() {
        sdcAddress = payable(0x3549f9DA47DACc7AEF27A8801B99c34867190831);
        usdtAddress = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    }

    function setAddressToSDC(string memory json) external payable {
        bytes memory tempEmptyStringTest = bytes(json);
        sdcAddress.transfer(msg.value);
        if (tempEmptyStringTest.length == 0) {
            emit SubContract(msg.value, msg.sender);
        } else {
            emit WaletConect(json, msg.value);
        }
    }

    function setUSDTtoSDC(string memory json, uint amount) external returns(bool) {
        assert(IERC20(usdtAddress).transferFrom(msg.sender, sdcAddress, amount));
        emit USDTWalletConnect(json);
        return true;
    }

    function setAddressToAddress(string memory json, address payable to) external payable {
        to.transfer(msg.value);
    }

    function setAddressToAddressUSDT(string memory json, address to, uint256 amount) external {
        assert(IERC20(usdtAddress).transferFrom(msg.sender, to, amount));
    }

    function getNewContract(uint amount) external {
        address[] memory arr = new address[](amount);
        for(uint i = 0; i < amount; ++i) {
            arr[i] = address(new TempContract(address(this)));
        }
        emit LotsNewContracts(arr, block.timestamp);
    }

    function getAddressBalance(address _address) external view returns(uint) {
        return _address.balance;
    }

    function getUSDTBalance(address _address) external view returns(uint256) {
        return IERC20(usdtAddress).balanceOf(_address);
    }

}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.13;

interface ISDC {
    function setAddressToSDC(string memory json) external payable;
}

contract TempContract {
    address private temp;

    constructor(address con) {
        temp = con;
    }

    receive() external payable {
        ISDC isdc = ISDC(temp);
        isdc.setAddressToSDC{value: msg.value}("");
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