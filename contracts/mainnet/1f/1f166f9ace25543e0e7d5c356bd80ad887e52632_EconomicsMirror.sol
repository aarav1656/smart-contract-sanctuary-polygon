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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
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
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IChamberOfCommerce.sol";
import "./SafeERC20.sol";
import { IEconomicsDataTypes } from "./interfaces/IDataTypes.sol";

/**
 * @title The EconomicsMirror contract mimicks the behaviour of the Economics.sol contract of core. 
 * @author https://github.com/kasper-keunen
 */
contract EconomicsMirror is Ownable, IEconomicsDataTypes {
    using SafeERC20 for IERC20;
    address public chamberOfCommerce;
    address public bondCouncil;
    IERC20 public fuelToken;
    uint32 public integratorCount = 8000;
    // relayerAddress => RelayerDataStruct
    mapping(address => RelayerData) public relayerData;
    // integratorIndex => IntegratorDataStruct
    mapping(uint32 => IntegratorData) public integratorData;
    // integratorIndex = DynamicRatesStruct
    mapping(uint32 => DynamicRates) public integratorRates;
    mapping(address => bool) public isRegistered;
    mapping(address => uint32) public addressToIndex;

    constructor() {}

     // check if caller is a DAOController
    modifier isDAOController() {
        require(
            IChamberOfCommerce(chamberOfCommerce).isDAOController(msg.sender),
            "EconomicsMirror:Caller not a DAO controller"
        );
        _;
    }

    modifier isBondCouncil() {
        require(
            bondCouncil == msg.sender,
            "EconomicsMirror:Caller not a bondcouncil"
        );
        _;
    }

    function configureContract(
        address _bondCouncil,
        address _chamberOfCommerce,
        address _fuelToken
    ) external onlyOwner {
        bondCouncil = _bondCouncil;
        chamberOfCommerce = _chamberOfCommerce;
        fuelToken = IERC20(_fuelToken);
    }

    function setupIntegrator(
        string calldata _name,
        address _relayerAddress
    ) external returns(uint32){
        require(
            !isRegistered[msg.sender],
            "EconomicsMirror:Integrator Already registerd"
        );
        IntegratorData storage integrator = integratorData[integratorCount];
        integrator.index = integratorCount;
        integrator.name = _name;
        relayerData[_relayerAddress] = RelayerData(integrator.index);
        isRegistered[msg.sender] = true;
        addressToIndex[msg.sender] = integratorCount;
        integratorCount++;
        return integrator.index;
    }

    /** 
    @notice topup that transfer GET from the _sender
    @param _integratorIndex index of the integrator to top up
    @param _sender account that GET should be transferred from
    @param _total amount of fuel tokens that will be topped up, inclusive of sales tax
    @param _price USD price per GET that is paid and will be locked
     */
    function topUpIntegrator(
        uint32 _integratorIndex,
        address _sender,
        uint256 _total,
        uint256 _price
    ) external returns(uint256) {
        IntegratorData storage integrator = integratorData[_integratorIndex];
        integrator.isBillingEnabled = true;
        integrator.isConfigured = true;
        require(_total > 0, "Economics: zero amount");
        require(_price > 0, "Economics: incorrect price");
        require(
            fuelToken.allowance(_sender, address(this)) >= _total, 
            "Economics: sender lacks allowance"
        );
        bool topUpFuel = fuelToken.transferFrom(
            _sender, 
            address(this), 
            _total
        );
        require(
            topUpFuel, 
            "Economics: transfer failed! Perhaps balance might be too low"
        );
        uint256 _newAveragePrice = _calculateAveragePrice(
            _total,
            _price,
            integrator.availableFuel,
            integrator.price
        );
        integrator.availableFuel += _total;
        integrator.price = _newAveragePrice;
        return integrator.availableFuel;
    }

    function setRates(
        uint32 _integratorIndex, 
        DynamicRates memory _rates) external isDAOController {
            integratorRates[_integratorIndex] = _rates;
    }

    function setIntegratorPrice(
        uint32 _integratorIndex, 
        uint256 _price) external isDAOController {
            integratorData[_integratorIndex].price = _price;
    }

    /**  calculates weighted average GET price for relayer during a top up.
    @param _incomingFuelAmount amount of GET that is to be topped x10^18
    @param _incomingPrice USD price per GET that is being topped up x10^4
    @param _currentFuelBalance amount of reservedFuel for a relayer x10^18
    @param _currentPrice current USD price per GET for a relayer x10^18
    */
    function _calculateAveragePrice(
        uint256 _incomingFuelAmount,
        uint256 _incomingPrice,
        uint256 _currentFuelBalance,
        uint256 _currentPrice
    ) internal pure returns (uint256) {
        uint256 _currentUsdValue = _currentFuelBalance * _currentPrice;
        uint256 _incomingUsdValue = _incomingFuelAmount * _incomingPrice;
        uint256 _totalUSDValue = _currentUsdValue + _incomingUsdValue;
        uint256 _totalFuelBalance = _currentFuelBalance + _incomingFuelAmount;
        uint256 _newPrice = _totalUSDValue / _totalFuelBalance;
        return _newPrice;
    }

    // CUSTOM FUNCTION THAT WE NEED TO ADD TO ECONOMICS (in the future)
    function withdrawBalanceFromIntegrator(
        uint32 _integratorIndex, 
        uint256 _amountOfGET,
        address _bucketAddress) external isDAOController {
        integratorData[_integratorIndex].availableFuel -= _amountOfGET;
        fuelToken.transfer(_bucketAddress, _amountOfGET);
    }

    function withdrawAnyTokenEmergency(
        address _tokenAddress,
        uint256 _amountToWithdraw,
        address _withdrawRecipient
    ) external isDAOController {
        IERC20(_tokenAddress).transfer(_withdrawRecipient, _amountToWithdraw);
    }

    function changeBalanceOfIntegrator(
        uint32 _integratorIndex,
        uint256 _balanceToSet
    ) external isDAOController {
        integratorData[_integratorIndex].availableFuel = _balanceToSet;
    }

    // VIEW FUNCTIONS
    function viewIntegratorUSDBalance(uint32 _integratorIndex) external view returns (uint256) {
        IntegratorData storage integrator = integratorData[_integratorIndex];
        return (integrator.availableFuel * integrator.price) / 1e18;
    }

    function returnIntegratorData(uint32 _integratorIndex) external view returns(IntegratorData memory data_) {
        data_ = integratorData[_integratorIndex];
    }

    function returnIntegratorIndexByRelayer(
        address _relayerAddress
    ) external view returns(uint32 integratorIndex_) {
        integratorIndex_ = relayerData[_relayerAddress].integratorIndex;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";

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
pragma solidity ^0.8.4;

import { ITellerV2DataTypes, IEconomicsDataTypes } from "./IDataTypes.sol";

interface IChamberOfCommerce is ITellerV2DataTypes, IEconomicsDataTypes {
    function bondCouncil() external view returns(address);
    function fuelToken() external returns(address);
    function depositToken() external returns(address);
    function tellerContract() external returns(address);
    function clearingHouse() external returns(address);
    function ticketSaleOracle() external returns(address);
    function economics() external returns(address);
    function palletRegistry() external returns(address);
    function palletMinter() external returns(address);
    function tellerKeeper() external returns(address);
    function returnPalletLocker(address _safeAddress) external view returns(address _palletLocker);
    function isChamberPaused() external view returns (bool);

    function returnIntegratorData(
        uint32 _integratorIndex
    )  external view returns(IntegratorData memory data_);

    function isAddressBorrower(
        address _addressSafeBorrower
    ) external view returns(bool);

    function isAccountWhitelisted(
        address _addressAccount
    ) external view returns(bool);

    function isAccountBlacklisted(
        address _addressAccount
    ) external view returns(bool);

    function returnPalletEvent(
        uint256 _palletIndex
    ) external view returns(address eventAddress_);

    function viewIntegratorUSDBalance(
        uint32 _integratorIndex
    ) external view returns (uint256 balance_);

    function emergencyMultisig() external view returns(address);

    function returnIntegratorIndexByRelayer(
        address _relayerAddress
    ) external view returns(uint32 integratorIndex_);

    function isDAOController(
        address _challenedController
    ) external view returns(bool);

    function isFuelAndCollateralSufficient(
        address _palletIssuerAddress, 
        uint64 _maxAmountInventory, 
        uint64 _averagePriceInventory,
        uint256 _amountPallet) external view returns(bool judgement_);


    function getIntegratorFuelPrice(
        uint32 _integratorIndex
    ) external view returns(uint256 _price);

    function palletIndexToBid(
        uint256 _palletIndex
    ) external view returns(uint256 _bidId);

    // EXTERNALCALL TO ORACLE
    function nftsIssuedForEvent(
        address _eventAddress
    ) external view returns(uint32 _ticketCount);

    // EXTERNALCALL TO ORACLE
    function isCountFinalized(
        address _eventAddress
    ) external view returns(bool _isFinalized);

    function returnIntegratorIndex(address _addressAccount) external view returns(uint32 index_);

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface IChamberOfCommerceDataTypes {

    // ChamberOfCommerce
    enum AccountType {
        NOT_SET,
        BORROWER,
        LENDER
    }

    enum AccountStatus {
        NONE,
        REGISTERED,
        WHITELISTED,
        BLACKLIST
    }

    struct ActorAccount {
        uint32 integratorIndex;
        AccountStatus status;
        AccountType accountType;
        address palletLocker;
        address relayerAddress;
        string nickName;
        string uriGeneral;
        string uriTerms;
    }

    struct CreditScore {
        uint256 minimumDeposit;
        uint24 fuelRequirement; // 100% = 1_000_000 = 1e6
    }
}

interface IEventImplementationDataTypes {

    enum TicketFlags {
        SCANNED, // 0
        CHECKED_IN, // 1
        INVALIDATED, // 2
        CLAIMED // 3
    }

    struct BalanceUpdates {
        address owner;
        uint64 quantity;
    }

    struct TokenData {
        address owner;
        uint40 basePrice;
        uint8 booleanFlags;
    }

    struct AddressData {
        uint64 balance;
    }

    struct EventData {
        uint32 index;
        uint64 startTime;
        uint64 endTime;
        int32 latitude;
        int32 longitude;
        string currency;
        string name;
        string shopUrl;
        string imageUrl;
    }

    struct TicketAction {
        uint256 tokenId;
        bytes32 externalId; // sha256 hashed, emitted in event only.
        address to;
        uint64 orderTime;
        uint40 basePrice;
    }

    struct EventFinancing {
        uint64 palletIndex;
        address bondCouncil;
        bool inventoryRegistered;
        bool financingActive;
        bool primaryBlocked;
        bool secondaryBlocked;
        bool scanBlocked;
        bool claimBlocked;
    }
}


interface IBondCouncilDataTypes is IEventImplementationDataTypes {
    /**
     * @notice What happens to the collateral after a certain 'bond state' is a Policy. The Policy struct defines the consequence on the actions of the collateral
     * @param isPolicy bool that tracks 'if a policy exists'. Should always be set to True if a Policy is set
     * @param primaryBlocked if the NFTs can be sold on the primary market if the Policy is active. True means that the NFTs cannot be sold on the primary market.
     * Same principle of True/False relation to possible ticket-actions is the case for the other bools in this struct.
     */
    struct Policy {
        bool isPolicy;
        bool primaryBlocked;
        bool secondaryBlocked;
        bool scanBlocked;
        bool claimBlocked;
    }

    /**
     * @param verified bool indicating if the TB is verified by the DAO
     * @param eventAddress address of the Event (EventImplementation proxy) 
     * @param policyDuringLoan integer of the Policy that will be executed after the offering is ACCEPTED (so during the duration of the loan/bond)
     * @param policyAfterLiquidation integer of the Policy that will be executed if the offering is LIQUIDATED (so this is the consequence of not repaying the loan/bond)
     * @param flushstruct this is a copy of the EventFinancing struct in EventImplementation. 
     * @dev when a configuration is 'flushed' this means that the flushstruct is pushed to the EventImplementation contract. 
     */
    struct InventoryProcedure {
        bool verified;
        address eventAddress;
        uint256 policyDuringLoan;
        uint256 policyAfterLiquidation;
        EventFinancing flushstruct;
    }

    /**
     * @param INACTIVE TellerLoan does not exist, or is in PENDING state
     * @param DURING TellerLoan is ongoing - collatearization is active
     * @param LIQUIDATED TellerLoan is liquidated - collatearlization should be settled or has been settled
     * @param REPAID TellerLoan is repaid - collatearlization should be settled or has been settled
     */
    enum CollateralizationStage {
        INACTIVE,
        DURING,
        LIQUIDATED,
        REPAID
    }
}

interface IClearingHouseDataTypes {

    /**
     * Struct encoding the status of the collateral/loan/bid offering.
     * @param NONE offering isn't registered at all (doesn't exist)
     * @param READY the pallet is ready to be used as collateral
     * @param ACTIVE the pallet is being used as collateral
     * @param COMPLETED the pallet is returned to the bond issuer (the offering is completed, loan has been repaid)
     * @param DEFAULTED the pallet is sent to the lender because the loan/bond wasn't repaid. The offering isn't active anymore
     */
    enum OfferingStatus {
        NONE,
        READY,
        ACTIVE,
        COMPLETED,
        DEFAULTED
    }
}

interface IEconomicsDataTypes {
    struct IntegratorData {
        uint32 index;
        uint32 activeTicketCount;
        bool isBillingEnabled;
        bool isConfigured;
        uint256 price;
        uint256 availableFuel;
        uint256 reservedFuel;
        uint256 reservedFuelProtocol;
        string name;
    }

    struct RelayerData {
        uint32 integratorIndex;
    }

    struct DynamicRates {
        uint24 minFeePrimary;
        uint24 maxFeePrimary;
        uint24 primaryRate;
        uint24 minFeeSecondary;
        uint24 maxFeeSecondary;
        uint24 secondaryRate;
        uint24 salesTaxRate;
    }
}

interface PalletRegistryDataTypes {

    enum PalletState {
        NON_EXISTANT,
        UN_REGISTERED, // 'pallet is unregistered to an event'
        REGISTERED, // 'pallet is registered to an event'
        VERIFIED, // pallet is now sealed
        DISCARDED // end state
    }

    struct PalletStruct {
        address depositTokenAddress;
        uint64 maxAmountInventory;
        uint64 averagePriceInventory;
        bool fuelAndCollateralCheck;
        address safeAddressIssuer;
        address palletLocker;
        uint256 depositedDepositTokens;
        PalletState palletState;
        address eventAddress;
    }
}

interface ITellerV2DataTypes {
    enum BidState {
        NONEXISTENT,
        PENDING,
        CANCELLED,
        ACCEPTED,
        PAID,
        LIQUIDATED
    }
    
    struct Payment {
        uint256 principal;
        uint256 interest;
    }

    struct Terms {
        uint256 paymentCycleAmount;
        uint32 paymentCycle;
        uint16 APR;
    }
    
    struct LoanDetails {
        ERC20 lendingToken;
        uint256 principal;
        Payment totalRepaid;
        uint32 timestamp;
        uint32 acceptedTimestamp;
        uint32 lastRepaidTimestamp;
        uint32 loanDuration;
    }

    struct Bid {
        address borrower;
        address receiver;
        address lender;
        uint256 marketplaceId;
        bytes32 _metadataURI; // DEPRECIATED
        LoanDetails loanDetails;
        Terms terms;
        BidState state;
    }
}

interface ITrancheBucketFactoryDataTypes {

    enum BucketType {
        NONE,
        BACKED,
        UN_BACKED
    }
}

interface ITrancheBucketDataTypes is IEconomicsDataTypes {

    /**
     * @param NONE config doesn't exist
     * @param CONFIGURABLE BUCKET IS CONFIGURABLE. it is possible to change the inv range and the kickback per NFT sold (so the bucket is still configuratable)
     * @param BUCKET_ACTIVE BUCKET IS ACTIVE. the bucket is active / in use (the loan/bond has been issued). The bucket CANNOT be configured anymore
     * @param AT_CHECKOUT BUCKET DEBT IS BEING CALCULATED AND PAID. The bond/loan has been repaid / the ticket sale is completed. In a sense the bucket backer is at the checkout of the process (the total bill is made up, and the payment request/process is being run). Look of it as it as the contract being at the checkout at the supermarket, items bought are scanned, creditbard(Economics contract) is charged.
     * @param REDEEMABLE the proceeds/kickback collected in the bucket can now be claimed from the bucket contract. 
     * @param INVALID_CANCELLED_VOID the bucket is invalid. this can have several reasons. The different reasons are listed below.
     * 
     * We have collapsed all these different reasons in a single state because the purpose of this struct is to tell the market what the shares are worth anything. If the bucket is in this state, the value of the shares are 0 (and they are unmovable).
     */

    // stored in: bucketState
    enum BucketConfiguration {
        NONE,
        CONFIGURABLE,
        BUCKET_ACTIVE,
        AT_CHECKOUT,
        REDEEMABLE,
        INVALID_CANCELLED_VOID
    }

    // stored in backing.verification
    enum BackingVerification {
        NONE,
        INVALIDATED,
        VERIFIED
    }

    // stored in tranche
    struct InventoryTranche {
        uint32 startIndexTranche;
        uint32 stopIndexTranche;
        uint32 averagePriceNFT;
        uint32 totalNFTInventory;
        uint32 usdKickbackPerNft; // 10000 = 1e4 = $1,00 = 1 dollar 
    }

    struct BackingStruct {
        bool relayerAttestation;
        BackingVerification verification;
        IntegratorData integratorData;
        uint32 integratorIndex;
        uint256 timestampBacking; // the moment the bucket was deployed and the backing was configured 
    }
}