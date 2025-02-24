// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC20.sol";
import "./Ownable.sol";

contract WYD is ERC20, Ownable {
    constructor() ERC20("Wyd", "WYD") {}

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}