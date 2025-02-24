// SPDX-License-Identifier: MIT

/*
 ________         __        __           
/        |       /  |      /  |          
$$$$$$$$/______  $$ |   __ $$ | __    __ 
   $$ | /      \ $$ |  /  |$$ |/  |  /  |
   $$ |/$$$$$$  |$$ |_/$$/ $$ |$$ |  $$ |
   $$ |$$ |  $$ |$$   $$<  $$ |$$ |  $$ |
   $$ |$$ \__$$ |$$$$$$  \ $$ |$$ \__$$ |
   $$ |$$    $$/ $$ | $$  |$$ |$$    $$ |
   $$/  $$$$$$/  $$/   $$/ $$/  $$$$$$$ |
                               /  \__$$ |
                               $$    $$/ 
                                $$$$$$/  
*/

pragma solidity ^0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../utils/Pausable.sol";
import "../utils/Withdrawable.sol";
import "../utils/TolkyAllowlist.sol";
import "../utils/TimeLock.sol";
import "../utils/ReleaseLock.sol";
import "../utils/AmountLimits.sol";
import "../interfaces/IToklyContract.sol";

/**
 * @title ToklyTokenSale
 * @author Khiza DAO
 * @dev ToklyTokenSale is a base contract for a token sale. It's created using the TolkyFactory.
 */
contract ToklyTokenSale is
    IToklyContract,
    Ownable,
    ReentrancyGuard,
    Pausable,
    Withdrawable,
    TolkyAllowlist,
    TimeLock,
    ReleaseLock,
    AmountLimits
{
    using SafeERC20 for IERC20;

    // === Vars ===

    uint public pricePerToken;
    address public tokenToPay;
    IERC20 public tokenToSell;

    uint8 public tokenToSellDecimals;
    string public constant tolkyVersion = "v0.1.0";

    // === Events ===

    event BuyTokens(address buyer, uint price, uint amount);

    // === Errors ===

    error NotEnoughBuyerBalance(uint currentBalance, uint requiredBalance);
    error NotEnoughContractBalance(uint currentBalance, uint requiredBalance);
    error NotEnoughAllowance(uint currentAllowance, uint requiredAllowance);
    /// @dev Thrown when amount to pay is zero
    error NoFreeLunch();
    /// @dev Thrown when msg.value is not zero but _tokenToPay is not network's native token
    error NotPayable();

    constructor() initializer {}

    /// @dev Initiliazes the contract, like a constructor.
    function initialize(
        address _owner,
        uint _pricePerToken,
        address _tokenToPay,
        IERC20 _tokenToSell,
        uint _releasesAt,
        uint _startsAt,
        uint _endsAt,
        uint _minAmount,
        uint _maxAmount,
        uint8 _tokenToSellDecimals,
        bool _allowlistEnabled
    ) external initializer {
        _transferOwnership(_owner);
        pricePerToken = _pricePerToken;
        tokenToPay = _tokenToPay;
        tokenToSell = _tokenToSell;
        releasesAt = _releasesAt;
        startsAt = _startsAt;
        endsAt = _endsAt;
        _minAmount = minAmount;
        _maxAmount = maxAmount;
        tokenToSellDecimals = _tokenToSellDecimals;
        allowlistEnabled = _allowlistEnabled;
    }

    // === Modifiers ===

    /**
     * @dev Updates the decimals of the token to sell
     * @param _tokenToSellDecimals The decimals of the token to sell
     */
    function setTokenToSellDecimals(
        uint8 _tokenToSellDecimals
    ) public onlyOwner {
        tokenToSellDecimals = _tokenToSellDecimals;
    }

    // === Public functions ===

    /**
     * @dev Returns the amount of tokens to pay for the amount of tokens
     * @return amountToPay The amount of tokens to pay for the amount of tokens
     */
    function valueToPay(
        uint amountToBuy
    ) public view returns (uint amountToPay) {
        amountToPay =
            (amountToBuy * pricePerToken) /
            (10 ** tokenToSellDecimals);
    }

    /**
     * @dev Buys tokens. It assumes the caller has already approved the token to pay.
     * @dev Can only be called by allowlisted addresses if allowlist is enabled
     * @dev Can only be called when contract is not paused and time is within the time window
     */
    function buyTokens(
        uint _amountToBuy
    )
        public
        payable
        nonReentrant
        notPaused
        allowlistCompliance(_amountToBuy)
        timeCompliance
        amountCompliance(_amountToBuy)
    {
        uint _amountToPay = _checkTokenToSell(_amountToBuy);

        _checkTokenToPay(_amountToPay);

        // Updates allowlist limits
        if (allowlistEnabled) {
            allowlistLimits[_msgSender()] -= _amountToBuy;
        }

        // Transfer tokens or register as claimable
        if (isReleaseCompliant()) {
            _transferBothTokens(_amountToBuy, _amountToPay);
        } else {
            _transferTokenToPay(_amountToPay);
            _addReservedClaims(_msgSender(), _amountToBuy);
        }

        // Emit the event
        emit BuyTokens(_msgSender(), _amountToPay, _amountToBuy);
    }

    function claim(
        uint _amount
    )
        public
        releaseCompliance
        claimCompliance(_msgSender(), _amount)
        nonReentrant
    {
        // Transfer tokens to sell to the msg.sender
        tokenToSell.safeTransfer(_msgSender(), _amount);
    }

    /**
     * @dev Returns the amount of tokens available to buy
     * @return amountAvaiableToBuy The amount of tokens available to buy
     */
    function amountAvaiableToBuy() public view returns (uint) {
        return tokenToSell.balanceOf(address(this)) - totalReservedAmount;
    }

    // === Private functions ===

    /**
     * @dev Transfers both tokens.
     */
    function _transferBothTokens(uint _amountToBuy, uint _amountToPay) private {
        _transferTokenToPay(_amountToPay);

        // Transfer tokens to sell to the msg.sender
        tokenToSell.safeTransfer(_msgSender(), _amountToBuy);
    }

    /**
     * @dev Transfers tokens to pay.
     */
    function _transferTokenToPay(uint _amountToPay) private {
        // If token to pay is not native token
        if (tokenToPay != address(0)) {
            IERC20 _tokenToPay = IERC20(tokenToPay);

            // Transfer ERC20 tokens to the contract
            _tokenToPay.safeTransferFrom(
                _msgSender(),
                address(this),
                _amountToPay
            );
        }
    }

    /**
     *
     */
    function _checkTokenToSell(uint _amountToBuy) private view returns (uint) {
        require(_amountToBuy > 0);

        uint _amountToPay = (_amountToBuy * pricePerToken) /
            (10 ** tokenToSellDecimals);
        if (_amountToPay == 0) revert NoFreeLunch();

        // check if the Vendor Contract has enough tokens for the transaction
        uint vendorBalance = tokenToSell.balanceOf(address(this));
        if (vendorBalance < _amountToBuy)
            revert NotEnoughContractBalance(vendorBalance, _amountToBuy);

        return _amountToPay;
    }

    /**
     * @dev Checks if the msg.sender has enough tokenToPay to pay for the amount of tokens
     */
    function _checkTokenToPay(uint _amountToPay) private view {
        // If token to pay is 0x0, it's the network's native token (eg. ETH)
        if (tokenToPay == address(0)) {
            if (msg.value < _amountToPay)
                revert NotEnoughBuyerBalance(msg.value, _amountToPay);
            return;
        } else {
            // If token to pay is not native token, msg.value must be zero
            if (msg.value > 0) {
                revert NotPayable();
            }
        }

        // Else, it's a ERC20 token
        IERC20 _tokenToPay = IERC20(tokenToPay);

        // Check if the buyer has enough allowance
        uint _currentAllowance = _tokenToPay.allowance(
            _msgSender(),
            address(this)
        );
        if (_currentAllowance < _amountToPay)
            revert NotEnoughAllowance(_currentAllowance, _amountToPay);

        // Check if the buyer has enough balance
        uint _currentBuyerBalance = _tokenToPay.balanceOf(_msgSender());
        if (_currentBuyerBalance < _amountToPay)
            revert NotEnoughBuyerBalance(_currentBuyerBalance, _amountToPay);
    }

    // === Contract identifiers ===

    function contractType() external pure override returns (bytes32) {
        return keccak256("TOKEN_SALE");
    }

    function contractVersion() external pure override returns (uint8) {
        return 2;
    }
}

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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Pausable is Ownable {
    bool public paused = true;

    error ContractPaused();

    modifier notPaused() {
        if (paused)
            revert ContractPaused();
        _;
    }

    function setPaused(bool _paused) public onlyOwner {
        paused = _paused;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract Withdrawable is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    event Withdrawal(uint amount, uint when);
    event WithdrawalERC20(uint amount, uint when, IERC20 token);

    function withdraw() public onlyOwner nonReentrant {
        emit Withdrawal(address(this).balance, block.timestamp);
        payable(owner()).transfer(address(this).balance);
    }

    function withdrawERC20(IERC20 token) public onlyOwner nonReentrant {
        emit WithdrawalERC20(token.balanceOf(address(this)), block.timestamp, token);
        token.safeTransfer(owner(), token.balanceOf(address(this)));
    }

    receive() external payable {
        // do nothing
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";

contract TolkyAllowlist is Ownable {
    error Unauthorized();

    event AllowlistAdded(address _address, uint _limit);

    mapping(address => uint) public allowlistLimits;
    bool public allowlistEnabled = true;
    address[] public allowlistAddresses;

    modifier allowlistCompliance(uint amountToBuy) {
        if (allowlistEnabled && allowlistLimits[_msgSender()] < amountToBuy)
            revert Unauthorized();
        _;
    }

    function setAllowlistEnabled(bool _allowlistEnabled) onlyOwner public {
        allowlistEnabled = _allowlistEnabled;
    }

    function setAllowlistAddress(address _address, uint _limit) onlyOwner public {
        emit AllowlistAdded(_address, _limit);
        allowlistLimits[_address] = _limit;
        allowlistAddresses.push(_address);
    }

    function getAllowlistAddresses() public view returns(address[] memory) {
        return allowlistAddresses;
    }

    function setMultiAllowlist(address[] memory _addresses, uint[] memory _limits) onlyOwner public {
        for (uint i=0; i<_addresses.length; i++) {
            setAllowlistAddress(_addresses[i], _limits[i]);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";

contract TimeLock is Ownable {
    uint public endsAt;
    uint public startsAt;

    event EndsAtChanged(uint newEndsAt);
    event StartsAtChanged(uint newStartsAt);

    error TimeLocked(uint _now, uint _startsAt, uint _endsAt);

    function setEndsAt(uint _endsAt) public onlyOwner {
        endsAt = _endsAt;
        emit EndsAtChanged(_endsAt);
    }

    function setStartsAt(uint _startsAt) public onlyOwner {
        startsAt = _startsAt;
        emit StartsAtChanged(_startsAt);
    }

    modifier timeCompliance() {
        if (!isTimeCompliant())
            revert TimeLocked(block.timestamp, startsAt, endsAt);
        _;
    }

    function isTimeCompliant() public view returns (bool) {
        return (startsAt == 0 || block.timestamp >= startsAt) && (endsAt == 0 || block.timestamp <= endsAt);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";

contract ReleaseLock is Ownable {
    uint public releasesAt;
    uint public totalReservedAmount;
    mapping(address => uint) public reservedClaims;

    event ReleasesAtChanged(uint releasesAt);
    event Claimed(address indexed _address, uint _amount);
    event Reserved(address indexed _address, uint _amount);

    error NotReleased(address _address, uint _now, uint _releasesAt);
    error NotEnoughReserved(address _address, uint _amount, uint _reserved);

    function _setReservedClaims(address _address, uint _amount) internal {
        totalReservedAmount -= reservedClaims[_address];
        reservedClaims[_address] = 0;
        _addReservedClaims(_address, _amount);
    }

    function _addReservedClaims(address _address, uint _amount) internal {
        reservedClaims[_address] += _amount;
        totalReservedAmount += _amount;
        emit Reserved(_address, _amount);
    }

    function setReleasesAt(uint _releasesAt) public onlyOwner {
        releasesAt = _releasesAt;
        emit ReleasesAtChanged(_releasesAt);
    }

    modifier releaseCompliance() {
        if (!isReleaseCompliant())
            revert NotReleased(_msgSender(), block.timestamp, releasesAt);
        _;
    }

    modifier claimCompliance(address _address, uint _amount) {
        if (!isClaimCompliant(_address, _amount))
            revert NotEnoughReserved(_address, _amount, reservedClaims[_address]);
        reservedClaims[_address] -= _amount;
        totalReservedAmount -= _amount;
        emit Claimed(_address, _amount);
        _;
    }

    function isReleaseCompliant() public view returns (bool) {
        return (releasesAt == 0 || block.timestamp >= releasesAt);
    }

    function isClaimCompliant(address _address, uint _amount) public view returns (bool) {
        return (reservedClaims[_address] >= _amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";

contract AmountLimits is Ownable {
    uint256 public minAmount;
    uint256 public maxAmount;

    event MinAmountChanged(uint256 newMinAmount);
    event MaxAmountChanged(uint256 newMaxAmount);

    error AmountNotInRange(
        uint256 _amount,
        uint256 _minAmount,
        uint256 _maxAmount
    );

    function setMinAmount(uint256 _minAmount) public onlyOwner {
        minAmount = _minAmount;
        emit MinAmountChanged(_minAmount);
    }

    function setMaxAmount(uint256 _maxAmount) public onlyOwner {
        maxAmount = _maxAmount;
        emit MaxAmountChanged(_maxAmount);
    }

    modifier amountCompliance(uint256 _amount) {
        if (!isAmountInRange(_amount))
            revert AmountNotInRange(_amount, minAmount, maxAmount);
        _;
    }

    function isAmountInRange(uint256 _amount) public view returns (bool) {
        return
            (minAmount == 0 || _amount >= minAmount) &&
            (maxAmount == 0 || _amount <= maxAmount);
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

abstract contract IToklyContract is Initializable {
    function contractType() external virtual returns (bytes32);
    function contractVersion() external virtual returns (uint8);
    // function initialize() external virtual; // and must have the `initializer` modifier
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/Address.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!Address.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}