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
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

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
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
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
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./../interfaces/IMultiAssetTreasury.sol";
import "./../interfaces/IOracle.sol";
import "./../interfaces/IAsset.sol";
import "./../interfaces/IAssetController.sol";
import "./../interfaces/IMultiAssetPool.sol";
import "./../interfaces/IUniswapV2Router01.sol";
import "../Operator.sol";

contract MultiAssetPoolV2 is Operator, ReentrancyGuard, IMultiAssetPool {
    using SafeMath for uint256;
    using SafeERC20 for ERC20;

    /* ========== STATE VARIABLES ========== */

    struct AssetStat {
        uint256 netMinted;
        uint256 netRedeemed;
        uint256 totalUnclaimedCollateral;
        uint256 missing_decimals;
        uint256 uncollectedFee;
        uint256 pool_ceiling;
        address collat_main_liq_pair;
        bool mint_paused;
        bool redeem_paused;
    }

    mapping(uint256 => AssetStat) public assetStat; //Map AssetStat to assetId

    address public shareToken;
    address public assetController;
    address public treasury; // MultiAssetTreasury Address
    address public feeCollector;
    address public router;

    uint256 public netShareBurned;
    uint256 public netShareMinted;

    mapping(address => uint256) public redeem_share_balances; // Unclaimed shareToken of User
    mapping(uint256 => mapping(address => uint256))  public redeem_collateral_balances; // Unclaimed collateral of User
    uint256 public unclaimed_pool_share; // Total Unclaimed share

    mapping(address => uint256) public last_redeemed; // Last claim of User => prevent flash loan attack

    // Constants for various precisions
    uint256 private constant PRICE_PRECISION = 1e6;
    uint256 private constant COLLATERAL_RATIO_PRECISION = 1e6;
    uint256 private constant COLLATERAL_RATIO_MAX = 1e6;

    // Number of blocks to wait before being able to collectRedemption()
    uint256 public redemption_delay = 1;

    address public usdc = address(0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174);

    /* ========== MODIFIERS ========== */

    modifier onlyAssetControllerOrOperator() {
        require(msg.sender == assetController || msg.sender == operator(), "!assetController");
        _;
    }

    modifier onlyTreasury() {
        require(msg.sender == treasury, "!treasury");
        _;
    }

    modifier onlyFeeCollector() {
        require(msg.sender == feeCollector, "!feeCollector");
        _;
    }

    /* ========== CONSTRUCTOR ========== */

    constructor(
        address _shareToken,
        address _treasury,
        address _assetController
    ) public {
        require(_shareToken != address(0), "Invalid address");
        require(_treasury != address(0), "Invalid address");
        require(_assetController != address(0), "Invalid address");
        feeCollector = msg.sender;
        shareToken = _shareToken;
        treasury = _treasury;
        assetController = _assetController;
    }

    /* ========== VIEWS ========== */

    function getMissingDecimals(uint256 _assetId) public view returns (uint256) {
        return assetStat[_assetId].missing_decimals;
    }

    function getNetMinted(uint256 _assetId) public view returns (uint256) {
        return assetStat[_assetId].netMinted;
    }

    function getNetRedeemed(uint256 _assetId) public view returns (uint256) {
        return assetStat[_assetId].netRedeemed;
    }

    function getPoolCeiling(uint256 _assetId) public view returns (uint256) {
        return assetStat[_assetId].pool_ceiling;
    }

    function getCollateralPrice(uint256 _assetId) public view returns (uint256) {
        return IAssetController(assetController).getAssetPrice(_assetId);
    }

    function getCollateralToken(uint256 _assetId) public view override returns (address) {
        return IAssetController(assetController).getCollateral(_assetId);
    }

    function netSupplyMinted(uint256 _assetId) public view override returns (uint256) {
        uint256 _netMinted = getNetMinted(_assetId);
        uint256 _netRedeemed = getNetRedeemed(_assetId);
        if (_netMinted > _netRedeemed)
            return _netMinted.sub(_netRedeemed);
        return 0;
    }

    function getUnclaimedCollateral(uint256 _assetId) public view override returns (uint256) {
        return assetStat[_assetId].totalUnclaimedCollateral;
    }

    // Returns alpha value of collateral held in collateralFund
    function collateralBalance(uint256 _assetId) public view override returns (uint256) {
        return (ERC20(getCollateralToken(_assetId)).balanceOf(collateralFund()).sub(getUnclaimedCollateral(_assetId))).mul(10 ** getMissingDecimals(_assetId));
    }

    function collateralFund() public view returns (address) {
        return IMultiAssetTreasury(treasury).collateralFund();
    }

    function info(uint256 _assetId)
    external
    view
    returns (
        uint256,
        uint256,
        uint256,
        uint256,
        uint256,
        bool,
        bool
    )
    {
        return (
        getPoolCeiling(_assetId), // Ceiling of pool - collateral-amount
        collateralBalance(_assetId), // amount of COLLATERAL locked
        assetStat[_assetId].totalUnclaimedCollateral, // unclaimed amount of COLLATERAL
        unclaimed_pool_share, // unclaimed amount of SHARE
        getCollateralPrice(_assetId), // collateral price
        assetStat[_assetId].mint_paused,
        assetStat[_assetId].redeem_paused
        );
    }

    /* ========== MINT V2 FUNCTIONS ========== */

    // Calculate Minting output variables
    function calcMintV2(
        uint256 _collateral_amount,
        uint256 _assetId,
        uint256 _missing_decimals
    ) public view returns (
        uint256 _asset_out,
        uint256 _collateral_to_buy_share,
        uint256 _fee_collect,
        uint256 _collateral_to_reserve
    ) {
        (, , , uint256 _tcr, , , uint256 _minting_fee,) = IMultiAssetTreasury(treasury).info(_assetId);
        _fee_collect = _collateral_amount.mul(_minting_fee).div(COLLATERAL_RATIO_PRECISION);
        _collateral_to_reserve = (_collateral_amount.sub(_fee_collect)).mul(_tcr).div(COLLATERAL_RATIO_PRECISION);
        _asset_out = (_collateral_amount.sub(_fee_collect)).mul(10 ** _missing_decimals);
        _collateral_to_buy_share = _collateral_amount.sub(_fee_collect).sub(_collateral_to_reserve);
    }

    function mintV2(
        uint256 _collateral_amount,
        uint256 _assetId
    ) external nonReentrant {
        require(_collateral_amount > 0, "Invalid amount");
        require(assetStat[_assetId].mint_paused == false, "Minting is paused");
        require(_assetId <= IAssetController(assetController).assetCount(), "Not Exsited Asset");

        AssetStat storage _assetStat = assetStat[_assetId];
        (, , , uint256 _tcr, , , uint256 _minting_fee,) = IMultiAssetTreasury(treasury).info(_assetId);
        (address _asset, address _collateral, , bool isStable) = IAssetController(assetController).getAssetInfo(_assetId);

        require(ERC20(_collateral).balanceOf(collateralFund()).sub(getUnclaimedCollateral(_assetId)).add(_collateral_amount) <= getPoolCeiling(_assetId), ">poolCeiling");
        (uint256 _asset_out, uint256 _collateral_to_buy_share, uint256 _fee_collect, uint256 _collateral_to_reserve) = calcMintV2(_collateral_amount, _assetId, _assetStat.missing_decimals);

        ERC20(_collateral).safeTransferFrom(msg.sender, feeCollector, _fee_collect);
        if (_collateral_to_reserve > 0) {
            ERC20(_collateral).safeTransferFrom(msg.sender, collateralFund(), _collateral_to_reserve);
        }

        uint256 shareBought = 0;

        if (_collateral_to_buy_share > 0) {
            shareBought = _swapToShare(_collateral, _assetStat.collat_main_liq_pair, _collateral_to_buy_share);
            IAsset(shareToken).burn(shareBought);
            netShareBurned = netShareBurned.add(shareBought);
        }

        _assetStat.netMinted = _assetStat.netMinted.add(_asset_out);

        IAsset(_asset).poolMint(msg.sender, _asset_out);

        emit Minted(msg.sender, _collateral_amount, shareBought, _asset_out);
    }

    /* ========== MINT V1 FUNCTIONS ========== */


    // Calculate Minting output variables
    function calcMint(uint256 _collateralAmount,
        uint256 _share_amount,
        uint256 _assetId,
        uint256 _missing_decimals
    ) public view returns (
        uint256 _actual_asset_amount,
        uint256 _required_share_amount,
        uint256 _fee_collect
    ) {
        (uint256 _assetPrice, uint256 _share_price, , uint256 _tcr, , , uint256 _minting_fee,) = IMultiAssetTreasury(treasury).info(_assetId);
        // Calculate fee based on input collateral amount
        _fee_collect = _collateralAmount.mul(_minting_fee).div(PRICE_PRECISION);
        uint256 _collateral_amount_post_fee = (_collateralAmount.sub(_fee_collect)).mul(10 ** _missing_decimals);

        if (_tcr > 0) {
            _actual_asset_amount = _collateral_amount_post_fee.mul(COLLATERAL_RATIO_PRECISION).div(_tcr);
            uint256 _collateral_price = IAssetController(assetController).getCollateralPriceInDollar(_assetId);
            uint256 _require_share_value = (_actual_asset_amount.sub(_collateral_amount_post_fee)).mul(_collateral_price).div(PRICE_PRECISION);
            _required_share_amount = _require_share_value.mul(PRICE_PRECISION).div(_share_price);
        } else {
            _required_share_amount = _share_amount;
            _actual_asset_amount = _share_amount.mul(_share_price).div(PRICE_PRECISION);
        }
    }

    function mint(
        uint256 _collateral_amount,
        uint256 _share_amount,
        uint256 _alpha_out_min,
        uint256 _assetId
    ) external nonReentrant {
        require(assetStat[_assetId].mint_paused == false, "Minting is paused");
        require(_assetId <= IAssetController(assetController).assetCount(), "Not Exsited Asset");

        AssetStat storage _assetStat = assetStat[_assetId];

        (address _asset, address _collateral, , bool isStable) = IAssetController(assetController).getAssetInfo(_assetId);
        (uint256 _actual_asset_amount, uint256 _required_share_amount, uint256 _fee_collect) = calcMint(_collateral_amount, _share_amount, _assetId, _assetStat.missing_decimals);

        require(ERC20(_collateral).balanceOf(collateralFund()).sub(getUnclaimedCollateral(_assetId)).add(_collateral_amount) <= getPoolCeiling(_assetId), ">poolCeiling");
        require(_alpha_out_min <= _actual_asset_amount, ">slippage");


        if (_required_share_amount > 0) {
            require(_required_share_amount <= _share_amount, "<shareBalance");
            IAsset(shareToken).poolBurnFrom(msg.sender, _required_share_amount);
            netShareBurned = netShareBurned.add(_required_share_amount);
        }

        if (_collateral_amount > 0) {
            ERC20(_collateral).safeTransferFrom(msg.sender, collateralFund(), _collateral_amount.sub(_fee_collect));
            ERC20(_collateral).safeTransferFrom(msg.sender, feeCollector, _fee_collect);

            //        _transferCollateralToReserve(_collateral_amount, _assetId);
            //            _assetStat.uncollectedFee = _assetStat.uncollectedFee.add(_fee_collect);
        }

        _assetStat.netMinted = _assetStat.netMinted.add(_actual_asset_amount);

        IAsset(_asset).poolMint(msg.sender, _actual_asset_amount);

        emit Minted(msg.sender, _collateral_amount, _required_share_amount, _actual_asset_amount);
    }

    /* ========== REDEEM FUNCTIONS ========== */

    function calcRedeem(
        uint256 _asset_amount,
        uint256 _assetId,
        uint256 _missing_decimals
    ) public view returns (
        uint256 _collateral_output_amount,
        uint256 _share_output_amount,
        uint256 _fee_collect
    ) {
        (, uint256 _share_price, , , uint256 _ecr, , , uint256 _redemption_fee) = IMultiAssetTreasury(treasury).info(_assetId);
        uint256 _fee = _asset_amount.mul(_redemption_fee).div(PRICE_PRECISION).div(10 ** _missing_decimals);
        _fee_collect = _fee.mul(_ecr).div(PRICE_PRECISION);
        uint256 _asset_amount_post_fee = _asset_amount.sub(_fee.mul(10 ** _missing_decimals));
        _collateral_output_amount = 0;
        _share_output_amount = 0;
        if (_ecr < COLLATERAL_RATIO_MAX && _ecr >= 0) {
            _collateral_output_amount = _asset_amount_post_fee.mul(_ecr).div(10 ** _missing_decimals).div(PRICE_PRECISION);

            uint256 _collateral_output_value = _collateral_output_amount.mul(10 ** _missing_decimals);
            uint256 _collateral_price = IAssetController(assetController).getCollateralPriceInDollar(_assetId);
            uint256 _share_output_value = (_asset_amount_post_fee.sub(_collateral_output_value)).mul(_collateral_price).div(PRICE_PRECISION);
            _share_output_amount = _share_output_value.mul(PRICE_PRECISION).div(_share_price);
        } else if (_ecr == COLLATERAL_RATIO_MAX) {
            _collateral_output_amount = _asset_amount_post_fee.div(10 ** _missing_decimals);
        }
    }

    function redeem(
        uint256 _asset_amount,
        uint256 _share_out_min,
        uint256 _collateral_out_min,
        uint256 _assetId
    ) external nonReentrant {
        require(assetStat[_assetId].redeem_paused == false, "Redeeming is paused");
        AssetStat storage _assetStat = assetStat[_assetId];
        (uint256 _collateral_output_amount, uint256 _share_output_amount, uint256 _fee_collect) = calcRedeem(_asset_amount, _assetId, _assetStat.missing_decimals);
        (address _asset, address _collateral, ,) = IAssetController(assetController).getAssetInfo(_assetId);
        //Get Fee
        _requestTransferCollateral(feeCollector, _fee_collect, _assetId);
        // Transfer fee

        // Check if collateral balance meets and meet output expectation
        require(_collateral_output_amount <= ERC20(_collateral).balanceOf(collateralFund()).sub(_assetStat.totalUnclaimedCollateral), "<collateralBlanace");
        require(_collateral_out_min <= _collateral_output_amount && _share_out_min <= _share_output_amount, ">slippage");

        if (_collateral_output_amount > 0) {
            redeem_collateral_balances[_assetId][msg.sender] = redeem_collateral_balances[_assetId][msg.sender].add(_collateral_output_amount);
            _assetStat.totalUnclaimedCollateral = _assetStat.totalUnclaimedCollateral.add(_collateral_output_amount);
        }

        if (_share_output_amount > 0) {
            redeem_share_balances[msg.sender] = redeem_share_balances[msg.sender].add(_share_output_amount);
            unclaimed_pool_share = unclaimed_pool_share.add(_share_output_amount);
            netShareMinted = netShareMinted.add(_share_output_amount);
        }

        last_redeemed[msg.sender] = block.number;

        _assetStat.netRedeemed = _assetStat.netRedeemed.add(_asset_amount);

        // Move all external functions to the end
        IAsset(_asset).poolBurnFrom(msg.sender, _asset_amount);

        if (_share_output_amount > 0) {
            _mintShareToCollateralReserve(_share_output_amount);
        }

        emit Redeemed(msg.sender, _asset_amount, _collateral_output_amount, _share_output_amount);
    }

    // Collect all pending collateral and shareToken of msg.sender
    function collectRedemption() external nonReentrant {
        // Redeem and Collect cannot happen in the same transaction to avoid flash loan attack
        require((last_redeemed[msg.sender].add(redemption_delay)) <= block.number, "<redemption_delay");
        uint256 _asset_count = IAssetController(assetController).assetCount();

        bool _send_share = false;
        uint256 _share_amount;

        // Use Checks-Effects-Interactions pattern
        if (redeem_share_balances[msg.sender] > 0) {
            _share_amount = redeem_share_balances[msg.sender];
            redeem_share_balances[msg.sender] = 0;
            unclaimed_pool_share = unclaimed_pool_share.sub(_share_amount);
            _send_share = true;
        }

        if (_send_share) {
            _requestTransferShare(msg.sender, _share_amount);
        }

        // Run a loop to collect all collateral that need to be collected
        for (uint256 aid = 0; aid < _asset_count; aid++) {
            bool _send_collateral = false;
            uint256 _collateral_amount;

            if (redeem_collateral_balances[aid][msg.sender] > 0) {
                _collateral_amount = redeem_collateral_balances[aid][msg.sender];
                redeem_collateral_balances[aid][msg.sender] = 0;
                assetStat[aid].totalUnclaimedCollateral = assetStat[aid].totalUnclaimedCollateral.sub(_collateral_amount);
                _send_collateral = true;
            }

            if (_send_collateral) {
                _requestTransferCollateral(msg.sender, _collateral_amount, aid);
            }
        }

        emit RedeemCollected(msg.sender);
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    function _swapToShare(address input_token, address bridgeToken, uint256 inputAmount) internal returns (uint256) {
        IERC20(input_token).approve(router, 0);
        IERC20(input_token).approve(router, inputAmount);

        address[] memory _path;

        if (input_token != bridgeToken) {
            _path = new address[](3);
            _path[0] = input_token;
            _path[1] = bridgeToken;
            _path[2] = shareToken;
        } else {
            _path = new address[](2);
            _path[0] = input_token;
            _path[1] = shareToken;
        }

        uint256[] memory estimate_amounts_out = IUniswapV2Router01(router).getAmountsOut(inputAmount, _path);
        uint256 estimate_amount_out = estimate_amounts_out[estimate_amounts_out.length - 1];
        uint256 amount_out_min = estimate_amount_out.mul(9500).div(10000);
        uint256[] memory out_amounts = IUniswapV2Router01(router).swapExactTokensForTokens(inputAmount, 0, _path, address(this), block.timestamp.add(1800));
        return out_amounts[out_amounts.length - 1];
    }


    // Transfer collateral to collateralFund when user mint new asset
    function _transferCollateralToReserve(uint256 _amount, uint256 _assetId) internal {
        address _reserve = collateralFund();
        address _collateral = IAssetController(assetController).getCollateral(_assetId);
        require(_reserve != address(0), "Invalid reserve address");
        ERC20(_collateral).safeTransfer(_reserve, _amount);
    }

    // Mint new Share to collateral for user to collect when Redeem asset
    function _mintShareToCollateralReserve(uint256 _amount) internal {
        address _reserve = collateralFund();
        require(_reserve != address(0), "Invalid reserve address");
        IAsset(shareToken).poolMint(_reserve, _amount);
    }

    // Request transfer collateral when user Redeem asset
    function _requestTransferCollateral(address _receiver, uint256 _amount, uint256 _assetId) internal {
        address _collateral = IAssetController(assetController).getCollateral(_assetId);
        IMultiAssetTreasury(treasury).requestTransfer(_collateral, _receiver, _amount);
    }

    // Request transfer shareToken when collect redemption
    function _requestTransferShare(address _receiver, uint256 _amount) internal {
        IMultiAssetTreasury(treasury).requestTransfer(shareToken, _receiver, _amount);
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function addAssetStat(uint256 _aid, uint256 _missingDecimals) external override onlyAssetControllerOrOperator {
        AssetStat storage _assetStat = assetStat[_aid];
        _assetStat.missing_decimals = _missingDecimals;
        _assetStat.pool_ceiling = 999999999999999999999 ether;
        _assetStat.collat_main_liq_pair = usdc;
    }

    function setCollatMainLiq(address token, uint256 _aid) external onlyOperator {
        AssetStat storage _assetStat = assetStat[_aid];
        _assetStat.collat_main_liq_pair = token;
    }

    function setFeeCollected(address _feeCollecter) external onlyOperator {
        require(_feeCollecter != address(0), "Invalid address");
        feeCollector = _feeCollecter;
    }

    function toggleMinting(uint256 _assetId) external onlyOperator {
        assetStat[_assetId].mint_paused = !assetStat[_assetId].mint_paused;
    }

    function toggleRedeeming(uint256 _assetId) external onlyOperator {
        assetStat[_assetId].redeem_paused = !assetStat[_assetId].redeem_paused;
    }

    function setPoolCeiling(uint256 _pool_ceiling, uint256 _assetId) external onlyOperator {
        assetStat[_assetId].pool_ceiling = _pool_ceiling;
    }

    function setRedemptionDelay(uint256 _redemption_delay) external onlyOperator {
        redemption_delay = _redemption_delay;
    }

    function setTreasury(address _treasury) external onlyOperator {
        emit TreasuryTransferred(treasury, _treasury);
        treasury = _treasury;
    }

    function setRouter(address _router) external onlyOperator {
        router = _router;
    }

    // EVENTS
    event TreasuryTransferred(address indexed previousTreasury, address indexed newTreasury);
    event Minted(address indexed user, uint256 usdtAmountIn, uint256 _shareTokenAmountIn, uint256 _alphaAmountOut);
    event Redeemed(address indexed user, uint256 _alphaAmountIn, uint256 usdtAmountOut, uint256 _shareTokenAmountOut);
    event RedeemCollected(address indexed user);
    event CollectFee(address indexed collector);
}

pragma solidity >=0.6.12;

abstract contract IAsset {
    function mint(address _to, uint256 _amount) external virtual;
    function burn(uint256 _amount) external virtual;

    function balanceOf(address account) external view virtual returns (uint256);

    function transfer(address recipient, uint256 amount) external virtual returns (bool);

    function poolBurnFrom(address _address, uint256 _amount) external virtual;

    function poolMint(address _address, uint256 _amount) external virtual;

    function circulatingSupply() external view virtual returns (uint256) ;
}

pragma solidity >=0.6.12;

interface IAssetController {
    function assetCount() external view returns(uint256);

    function getAssetInfo(uint256 _assetId) external view returns (
        address _asset,
        address _collateral,
        address _oracle,
        bool _isStable
    );

    function getAsset(uint256 _assetId) external view returns(address);

    function getCollateral(uint256 _assetId) external view returns(address);

    function getOracle(uint256 _assetId) external view returns (address);

    function isAssetStable(uint256 _assetId) external view returns(bool);

    function getAssetPrice(uint256 _assetId) external view returns (uint256);

    function getXSharePrice() external view returns (uint256);

    function getAssetTotalSupply(uint256 _assetId) external view returns (uint256);

    function getCollateralPriceInDollar(uint256 _assetId) external view returns (uint);

    function updateOracle(uint256 _assetId) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.12;
pragma experimental ABIEncoderV2;

interface IMultiAssetPool {
    function addAssetStat(uint256 _aid, uint256 _missingDecimals) external;

    function collateralBalance(uint256 _assetId) external view returns (uint256);

    function getUnclaimedCollateral(uint256 _assetId) external view returns (uint256);

    function netSupplyMinted(uint256 _assetId) external view returns (uint256);

    function getCollateralToken(uint256 _assetId) external view returns (address);

}

pragma solidity >=0.6.12;

interface IMultiAssetTreasury {
//    function addCollateralPolicy(uint256 _aid, uint256 _price_band, uint256 _missing_decimals, uint256 _init_tcr, uint256 _init_ecr) external;

    function hasPool(address _address) external view returns (bool);

    function collateralFund() external view returns (address);

    function globalCollateralBalance(uint256 _assetId) external view returns (uint256);

    function collateralValue(uint256 _assetId) external view returns (uint256);

//    function buyback(
//        uint256 _assetId,
//        uint256 _collateral_amount,
//        uint256 _min_share_amount,
//        uint256 _min_asset_out,
//        address[] calldata path
//    ) external;
//
//    function reCollateralize(uint256 _assetId, uint256 _share_amount, uint256 _min_collateral_amount, address[] calldata path) external;

    function requestTransfer(
        address token,
        address receiver,
        uint256 amount
    ) external;

    function info(uint256 _assetId)
    external
    view
    returns (
        uint256,
        uint256,
        uint256,
        uint256,
        uint256,
        uint256,
        uint256,
        uint256
    );
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.12;

interface IOracle {
    function update() external;

    function consult(address _token, uint256 _amountIn) external view returns (uint144 amountOut);

    function twap(address _token, uint256 _amountIn) external view returns (uint144 _amountOut);

    function sync() external;
}

pragma solidity >=0.6.12;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.12;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Operator is Context, Ownable {
    address private _operator;

    event OperatorTransferred(address indexed previousOperator, address indexed newOperator);

    constructor() {
        _operator = _msgSender();
        emit OperatorTransferred(address(0), _operator);
    }

    function operator() public view returns (address) {
        return _operator;
    }

    modifier onlyOperator() {
        require(_operator == msg.sender, "operator: caller is not the operator");
        _;
    }

    function isOperator() public view returns (bool) {
        return _msgSender() == _operator;
    }

    function transferOperator(address newOperator_) public onlyOperator {
        _transferOperator(newOperator_);
    }

    function _transferOperator(address newOperator_) internal {
        require(newOperator_ != address(0) && newOperator_ != _operator, "operator: zero address given for new operator");
        emit OperatorTransferred(address(0), newOperator_);
        _operator = newOperator_;
    }
}