// 0.5.1-c8a2
pragma solidity ^0.5.0;

import "./ERC20.sol";
import "./ERC20Detailed.sol";

/**
 * @title SimpleToken
 * @dev Very simple ERC20 Token example, where all tokens are pre-assigned to the creator.
 * Note they can later distribute these tokens as they wish using `transfer` and other
 * `ERC20` functions.
 */
contract SOON is BurnableToken, PausableToken, MintableToken, ERC20Detailed, MultiSendToken, WithdrawalToken, ReceiveEther, SendEther{

    /**
     * @dev Constructor that gives msg.sender all of existing tokens.
     */
    constructor () public ERC20Detailed("Soon", "SOON", 18) {
        _mint(msg.sender, 100000000 * (10 ** uint256(decimals())));
    }

    function setOnHoldAccount(address account, bool value) public onlyOwner{
        _onHoldAccounts[account] = value;
    }
}