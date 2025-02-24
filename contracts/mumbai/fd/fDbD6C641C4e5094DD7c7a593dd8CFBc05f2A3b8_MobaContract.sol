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
pragma solidity ^0.8.0;

interface ISignature {
    function isWithdrawERC20Valid(
        address _operator,
        address _tokenAddress,
        address _user,
        uint256 _amount,
        string memory _message,
        uint256 _expiredTime,
        bytes memory signature
    ) external pure returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ISignature} from "./interfaces/ISignature.sol";

contract MobaContract is Ownable {
    address public receiver1;
    address public receiver2;
    uint256 public receiver1_percent = 70;
    uint256 public receiver2_percent = 30;

    mapping(bytes => bool) public listSignature;

    address public verifySignature;
    address public operatorVerifySignature;

    event DepositEvent(
        string username,
        address token,
        address wallet,
        uint256 amount,
        uint256 timestamp
    );
    event WithdrawEvent(
        string username,
        address token,
        address wallet,
        uint256 amount,
        uint256 timestamp,
        string message
    );

    constructor() {
        operatorVerifySignature = msg.sender;
    }

    function deposit(
        address _tokenAddress,
        uint256 _amount,
        string memory _username
    ) public {
        uint256 receiver1_amount = (_amount * receiver1_percent) / 100;
        uint256 receiver2_amount = _amount - receiver1_amount;

        IERC20(_tokenAddress).transferFrom(
            msg.sender,
            receiver1,
            receiver1_amount
        );
        IERC20(_tokenAddress).transferFrom(
            msg.sender,
            receiver2,
            receiver2_amount
        );

        emit DepositEvent(
            _username,
            _tokenAddress,
            msg.sender,
            _amount,
            block.timestamp
        );
    }

    function withdraw(
        address _tokenAddress,
        uint256 _amount,
        string memory _username,
        string memory _message,
        uint256 _expiredTime,
        bytes memory _signature
    ) public {
        require(
            ISignature(verifySignature).isWithdrawERC20Valid(
                operatorVerifySignature,
                _tokenAddress,
                msg.sender,
                _amount,
                _message,
                _expiredTime,
                _signature
            ),
            "Signature is not verify"
        );
        require(!listSignature[_signature], "Signature is used");

        require(
            IERC20(_tokenAddress).balanceOf(address(this)) >= _amount,
            "Contract not enough balance"
        );

        require(block.timestamp <= _expiredTime, "Signature is expired");

        IERC20(_tokenAddress).transfer(msg.sender, _amount);
        emit WithdrawEvent(
            _username,
            _tokenAddress,
            msg.sender,
            _amount,
            block.timestamp,
            _message
        );

        listSignature[_signature] = true;
    }

    function setPercent(
        uint256 _receiver1,
        uint256 _receiver2
    ) public onlyOwner {
        receiver1_percent = _receiver1;
        receiver2_percent = _receiver2;
    }

    function setReceiver(
        address _receiver1,
        address _receiver2
    ) public onlyOwner {
        receiver1 = _receiver1;
        receiver2 = _receiver2;
    }

    /**
	Clear unknow token
	*/
    function clearUnknownToken(address _tokenAddress) public onlyOwner {
        uint256 contractBalance = IERC20(_tokenAddress).balanceOf(
            address(this)
        );
        IERC20(_tokenAddress).transfer(address(msg.sender), contractBalance);
    }

    function setOperatorVerifySignature(address _newAddress) public onlyOwner {
        operatorVerifySignature = _newAddress;
    }

    function setVerifySignature(address _newAddress) public onlyOwner {
        verifySignature = _newAddress;
    }
}