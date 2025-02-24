// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./base/SwapContractV2.sol";

/// @title Swap contract for multisignature bridge
contract SwapContract is SwapContractV2{

    function swapTokensToOtherBlockchain(swapToParams memory params)
        external
        payable
    {
        _swapTokensToOtherBlockchain(params);
    }

    function swapCryptoToOtherBlockchain(swapToParams memory params)
        external
        payable
    {
        _swapCryptoToOtherBlockchain(params);
    }

    function swapTokensToUserWithFee(swapFromParams memory params)
        external
    {
        _swapTokensToUserWithFee(params);
    }

    function swapCryptoToUserWithFee(swapFromParams memory params)
        external
    {
        _swapCryptoToUserWithFee(params);
    }
}

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

pragma solidity >=0.6.2;

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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
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
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.0;

/// @title Contains 512-bit math functions
/// @notice Facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision
/// @dev Handles "phantom overflow" i.e., allows multiplication and division where an intermediate value overflows 256 bits
library FullMath {
    /// @notice Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        // 512-bit multiply [prod1 prod0] = a * b
        // Compute the product mod 2**256 and mod 2**256 - 1
        // then use the Chinese Remainder Theorem to reconstruct
        // the 512 bit result. The result is stored in two 256
        // variables such that product = prod1 * 2**256 + prod0
        uint256 prod0; // Least significant 256 bits of the product
        uint256 prod1; // Most significant 256 bits of the product
        assembly {
            let mm := mulmod(a, b, not(0))
            prod0 := mul(a, b)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        // Handle non-overflow cases, 256 by 256 division
        if (prod1 == 0) {
            require(denominator > 0);
            assembly {
                result := div(prod0, denominator)
            }
            return result;
        }

        // Make sure the result is less than 2**256.
        // Also prevents denominator == 0
        require(denominator > prod1);

        ///////////////////////////////////////////////
        // 512 by 256 division.
        ///////////////////////////////////////////////

        // Make division exact by subtracting the remainder from [prod1 prod0]
        // Compute remainder using mulmod
        uint256 remainder;
        assembly {
            remainder := mulmod(a, b, denominator)
        }
        // Subtract 256 bit number from 512 bit number
        assembly {
            prod1 := sub(prod1, gt(remainder, prod0))
            prod0 := sub(prod0, remainder)
        }

        // Factor powers of two out of denominator
        // Compute largest power of two divisor of denominator.
        // Always >= 1.
        uint256 twos = (type(uint256).max - denominator + 1) & denominator;
        // Divide denominator by power of two
        assembly {
            denominator := div(denominator, twos)
        }

        // Divide [prod1 prod0] by the factors of two
        assembly {
            prod0 := div(prod0, twos)
        }
        // Shift in bits from prod1 into prod0. For this we need
        // to flip `twos` such that it is 2**256 / twos.
        // If twos is zero, then it becomes one
        assembly {
            twos := add(div(sub(0, twos), twos), 1)
        }
        prod0 |= prod1 * twos;

        // Invert denominator mod 2**256
        // Now that denominator is an odd number, it has an inverse
        // modulo 2**256 such that denominator * inv = 1 mod 2**256.
        // Compute the inverse by starting with a seed that is correct
        // correct for four bits. That is, denominator * inv = 1 mod 2**4
        uint256 inv = (3 * denominator) ^ 2;
        // Now use Newton-Raphson iteration to improve the precision.
        // Thanks to Hensel's lifting lemma, this also works in modular
        // arithmetic, doubling the correct bits in each step.
        inv *= 2 - denominator * inv; // inverse mod 2**8
        inv *= 2 - denominator * inv; // inverse mod 2**16
        inv *= 2 - denominator * inv; // inverse mod 2**32
        inv *= 2 - denominator * inv; // inverse mod 2**64
        inv *= 2 - denominator * inv; // inverse mod 2**128
        inv *= 2 - denominator * inv; // inverse mod 2**256

        // Because the division is now exact we can divide by multiplying
        // with the modular inverse of denominator. This will give us the
        // correct result modulo 2**256. Since the precoditions guarantee
        // that the outcome is less than 2**256, this is the final result.
        // We don't need to compute the high bits of the result and prod1
        // is no longer required.
        result = prod0 * inv;
        return result;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

contract ECDSAOffsetRecovery {
    function getHashPacked(
        address user,
        uint256 amountWithFee,
        bytes32 originalTxHash,
        uint256 blockchainNum
    ) public pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    user,
                    amountWithFee,
                    originalTxHash,
                    blockchainNum
                )
            );
    }

    function toEthSignedMessageHash(bytes32 hash)
        public
        pure
        returns (bytes32)
    {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
            );
    }

    function ecOffsetRecover(
        bytes32 hash,
        bytes memory signature,
        uint256 offset
    ) public pure returns (address) {
        bytes32 r;
        bytes32 s;
        uint8 v;

        // Divide the signature in r, s and v variables with inline assembly.
        assembly {
            r := mload(add(signature, add(offset, 0x20)))
            s := mload(add(signature, add(offset, 0x40)))
            v := byte(0, mload(add(signature, add(offset, 0x60))))
        }

        // Version of signature should be 27 or 28, but 0 and 1 are also possible versions
        if (v < 27) {
            v += 27;
        }

        // If the version is correct return the signer address
        if (v != 27 && v != 28) {
            return (address(0));
        }

        // bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        // hash = keccak256(abi.encodePacked(prefix, hash));
        // solium-disable-next-line arg-overflow
        return ecrecover(toEthSignedMessageHash(hash), v, r, s);
    }
}

pragma solidity =0.8.4;

interface ISwapContract {
    /**
     * @param blockchain Number of blockchain
     * @param tokenInAmount Depending on swapExactFor:
     * if _false_ then:
     * The max amount of tokens to sell
     * if _true_ then:
     * The exact amount of tokens to sell
     * @param firstPath Path used for swapping tokens to *RBC (tokenIn address,.., *RBC addres)
     * @param secondPath Path used for swapping *RBC to tokenOut (*RBC address,.., tokenOut address)
     * @param exactRBCtokenOut Depending on swapExactFor:
     * if _false_ then:
     * The exact amount of *RBC to get after first swap
     * if _true_ then:
     * The min amount of *RBC to get after first swap
     * @param tokenOutMin Minimal amount of tokens (or crypto) to get after second swap
     * @param newAddress Address in the blockchain to which the user wants to transfer
     * @param provider The of a provider, for whom to add bonus fees
     * @param swapToCrypto This must be _true_ if swapping tokens to desired blockchain's crypto
     * @param swapExactFor This must be _true_ if willing to use swapExact...ForTokens
     * @param withFee True if the users token has fee on transfers
     * @param signature The signature of function that's needed for backend
     */
    struct swapToParams {
        uint256 blockchain;
        uint256 tokenInAmount;
        address[] firstPath;
        bytes32[] secondPath;
        uint256 exactRBCtokenOut;
        uint256 tokenOutMin;
        bytes32 newAddress;
        address provider;
        bool swapToCrypto;
        bool swapExactFor;
        bool withFee;
        string signature;
    }

    /**
     * @param user User address // "newAddress" from event
     * @param provider The SDK provider's address for whom to calculate fee
     * @param initBlockchainNum The number of an initial blockchain
     * @param amountWithFee Amount of tokens with included fees to transfer from the pool // "RBCAmountIn" from event
     * @param amountOutMin Minimal amount of tokens to get after second swap // "tokenOutMin" from event
     * @param path Path used for a second swap // "secondPath" from event
     * @param originalTxHash Hash of transaction from other network, on which swap was called
     * @param concatSignatures Concatenated string of signature bytes for verification of transaction
     */
    struct swapFromParams {
        address user;
        address provider;
        uint256 initBlockchainNum;
        uint256 amountWithFee;
        uint256 amountOutMin;
        address[] path;
        bytes32 originalTxHash;
        bytes concatSignatures;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./SwapBase.sol";

import "../../node_modules/@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "../interfaces/ISwapContract.sol";

/// @title Swap contract for multisignature bridge
contract SwapContractV2 is ISwapContract, SwapBase {
    using Address for address payable;
    using SafeERC20 for IERC20;

    /**
     * @dev Performs check before swap*ToOtherBlockchain-functions and emits events
     * @param params The swapToParams structure
     * @param value The msg.value
     */
    modifier TransferTo(swapToParams memory params, uint256 value) {
        require(
            params.newAddress != bytes32(0),
            "swapContract: No destination address provided"
        );
        require(
            existingOtherBlockchain[params.blockchain] &&
                params.blockchain != numOfThisBlockchain,
            "swapContract: Wrong choose of blockchain"
        );
        require(
            params.firstPath.length > 0,
            "swapContract: firsPath length must be greater than 1"
        );
        require(
            params.secondPath.length > 0,
            "swapContract: secondPath length must be greater than 1"
        );
        require(
            params.firstPath[params.firstPath.length - 1] ==
                address(uint160(uint256(RubicAddresses[numOfThisBlockchain]))),
            "swapContract: the last address in the firstPath must be Rubic"
        );
        require(
            params.secondPath[0] == RubicAddresses[params.blockchain],
            "swapContract: the first address in the secondPath must be Rubic"
        );
        require(
            params.exactRBCtokenOut >= minTokenAmount,
            "swapContract: Not enough amount of tokens"
        );
        require(
            value >= blockchainCryptoFee[params.blockchain],
            "swapContract: Not enough crypto provided"
        );
        _;
        if (params.swapToCrypto) {
            emit TransferCryptoToOtherBlockchainUser(
                params.exactRBCtokenOut,
                params.tokenInAmount,
                params.provider
            );
        } else {
            emit TransferTokensToOtherBlockchainUser(
                params.exactRBCtokenOut,
                params.tokenInAmount,
                params.provider
            );
        }
    }

    /**
     * @dev Performs check before swap*ToUser-functions
     * @param params The swapFromParams structure
     */
    modifier TransferFrom(swapFromParams memory params) {
        uint256 _numOfThisBlockchain = numOfThisBlockchain; //SLOAD: gas optimization

        require(params.initBlockchainNum != _numOfThisBlockchain,
            "swapContract: init blockchain cant be equal to current"
        );
        require(
            params.amountWithFee >= minTokenAmount,
            "swapContract: Not enough amount of tokens"
        );
        require(
            params.amountWithFee <= maxTokenAmount,
            "swapContract: Too many RBC requested"
        );
        require(
            params.path.length > 0,
            "swapContract: path length must be greater than 1"
        );
        require(
            params.path[0] == address(uint160(uint256(RubicAddresses[_numOfThisBlockchain]))),
            "swapContract: the first address in the path must be Rubic"
        );
        require(
            params.user != address(0),
            "swapContract: Address cannot be zero address"
        );
        require(
            params.concatSignatures.length % SIGNATURE_LENGTH == 0,
            "swapContract: Signatures lengths must be divisible by 65"
        );
        require(
            params.concatSignatures.length / SIGNATURE_LENGTH >=
                minConfirmationSignatures,
            "swapContract: Not enough signatures passed"
        );

        _processTransaction(
            params.user,
            params.amountWithFee,
            params.originalTxHash,
            numOfThisBlockchain,
            params.concatSignatures
        );
        _;
    }

    function _swapTo(swapToParams memory params, IERC20 tokenIn) private{
        uint256 _allowance = tokenIn.allowance(address(this), blockchainRouter);
        if (_allowance < params.tokenInAmount){
            if (_allowance == 0){
                tokenIn.safeApprove(blockchainRouter, type(uint256).max);
            }
            else{
                try tokenIn.approve(blockchainRouter, type(uint256).max) returns (bool res){
                    require(res == true, 'SwapContract: approve failed');
                }
                catch {
                    tokenIn.safeApprove(blockchainRouter, 0);
                    tokenIn.safeApprove(blockchainRouter, type(uint256).max);
                }
            }
        }
        if (params.swapExactFor){
            if (params.withFee){
                IERC20 Rubic = IERC20(address(uint160(uint256(RubicAddresses[numOfThisBlockchain]))));
                uint256 balanceBefore = Rubic.balanceOf(address(this));
                IUniswapV2Router02(blockchainRouter).swapExactTokensForTokensSupportingFeeOnTransferTokens(
                    params.tokenInAmount,
                    params.exactRBCtokenOut,
                    params.firstPath,
                    address(this),
                    block.timestamp
                );
                params.exactRBCtokenOut = Rubic.balanceOf(address(this)) - balanceBefore;
            }else{
                uint[] memory amounts = IUniswapV2Router02(blockchainRouter).swapExactTokensForTokens(
                    params.tokenInAmount,
                    params.exactRBCtokenOut,
                    params.firstPath,
                    address(this),
                    block.timestamp
                );
                params.exactRBCtokenOut = amounts[amounts.length - 1];
            }
            require(
                params.exactRBCtokenOut <= maxTokenAmount,
                "swapContract: Too many RBC requested"
            );
        }
        else{
            require(
                params.exactRBCtokenOut <= maxTokenAmount,
                "swapContract: Too many RBC requested"
            );
            uint256[] memory amounts = IUniswapV2Router02(blockchainRouter)
                .swapTokensForExactTokens(
                    params.exactRBCtokenOut,
                    params.tokenInAmount,
                    params.firstPath,
                    address(this),
                    block.timestamp
            );
            tokenIn.safeTransfer(
                msg.sender,
                params.tokenInAmount - amounts[0]
            );
            params.tokenInAmount = amounts[0];
        }
    }

    /**
     * @dev Transfers tokens from sender to the contract.
     * User calls this function when he wants to transfer tokens to another blockchain.
     * @notice User must have approved tokenInAmount of tokenIn
     */
    function _swapTokensToOtherBlockchain(swapToParams memory params)
        internal
        whenNotPaused
        TransferTo(params, msg.value)
    {
        IERC20 tokenIn = IERC20(params.firstPath[0]);
        if (params.firstPath.length > 1) {
            if (params.withFee){
                uint256 actualBalance = tokenIn.balanceOf(address(this));
                tokenIn.safeTransferFrom(
                    msg.sender,
                    address(this),
                    params.tokenInAmount
                );
                actualBalance = tokenIn.balanceOf(address(this)) - actualBalance;
                params.tokenInAmount = actualBalance;
            }
            else{
                tokenIn.safeTransferFrom(
                    msg.sender,
                    address(this),
                    params.tokenInAmount
                );
            }
            _swapTo(params, tokenIn);
        } else {
            tokenIn.safeTransferFrom(
                msg.sender,
                address(this),
                params.exactRBCtokenOut
            );
        }
    }

    /**
     * @dev Transfers tokens from sender to the contract.
     * User calls this function when he wants to transfer tokens to another blockchain.
     * @notice User must have approved tokenInAmount of tokenIn
     */
    function _swapCryptoToOtherBlockchain(swapToParams memory params)
        internal
        whenNotPaused
        TransferTo(params, msg.value)
    {
        uint256 cryptoWithoutFee = msg.value -
            blockchainCryptoFee[params.blockchain];

        if (params.swapExactFor){
            uint256[] memory amounts = IUniswapV2Router02(blockchainRouter).swapExactETHForTokens{
                value: cryptoWithoutFee
            }(
                params.exactRBCtokenOut,
                params.firstPath,
                address(this),
                block.timestamp
            );
            params.exactRBCtokenOut = amounts[amounts.length - 1];
        }
        else{
            uint256[] memory amounts = IUniswapV2Router02(blockchainRouter).swapETHForExactTokens{
                value: cryptoWithoutFee
            }(
                params.exactRBCtokenOut,
                params.firstPath,
                address(this),
                block.timestamp
            );
            params.tokenInAmount = amounts[0];
            payable(_msgSender()).sendValue(cryptoWithoutFee - amounts[0]);
        }
    }

    /**
     * @dev Transfers tokens to end user in current blockchain
     */
    function _swapTokensToUserWithFee(swapFromParams memory params)
        internal
        onlyRelayer
        whenNotPaused
        TransferFrom(params)
    {
        uint256 amountWithoutFee = _calculateFee(params.provider, params.amountWithFee, params.initBlockchainNum);

        IERC20 RBCToken = IERC20(params.path[0]);

        if (params.path.length == 1) {
            RBCToken.safeTransfer(
                params.user,
                amountWithoutFee
            );
        } else {
            IUniswapV2Router02(blockchainRouter).swapExactTokensForTokens(
                amountWithoutFee,
                params.amountOutMin,
                params.path,
                params.user,
                block.timestamp
            );
        }
        emit TransferFromOtherBlockchain(
            params.user,
            params.amountWithFee,
            amountWithoutFee,
            params.originalTxHash
        );
    }

    /**
     * @dev Transfers tokens to end user in current blockchain
     */
    function _swapCryptoToUserWithFee(swapFromParams memory params)
        internal
        onlyRelayer
        whenNotPaused
        TransferFrom(params)
    {
        uint256 amountWithoutFee = _calculateFee(params.provider, params.amountWithFee, params.initBlockchainNum);

        IUniswapV2Router02(blockchainRouter).swapExactTokensForETH(
            amountWithoutFee,
            params.amountOutMin,
            params.path,
            params.user,
            block.timestamp
        );
        emit TransferFromOtherBlockchain(
            params.user,
            params.amountWithFee,
            amountWithoutFee,
            params.originalTxHash
        );
    }
}

pragma solidity =0.8.4;

import "./Storage.sol";

abstract contract SwapBase is Storage {
    mapping(address => uint256) internal providerFee;
    mapping(address => uint256) internal amountOfProvider;
    mapping(address => uint256) internal platformShare;


    // emitted every time when user gets crypto or tokens after success crossChainSwap
    event TransferFromOtherBlockchain(
        address user,
        uint256 amount,
        uint256 amountWithoutFee,
        bytes32 originalTxHash
    );
    // emitted if the recipient should receive crypto in the target blockchain
    event TransferCryptoToOtherBlockchainUser(
        uint256 RBCAmountIn,
        uint256 amountSpent,
        address provider
    );
    // emitted if the recipient should receive tokens in the target blockchain
    event TransferTokensToOtherBlockchainUser(
        uint256 RBCAmountIn,
        uint256 amountSpent,
        address provider
    );

    /**
     * @dev throws if transaction sender is not in relayer role
     */
    modifier onlyRelayer() {
        require(
            hasRole(RELAYER_ROLE, _msgSender()),
            "swapContract: Caller is not in relayer role"
        );
        _;
    }

    /**
     * @dev Constructor of contract
     */
    constructor() {}

    function _processTransaction(
        address user,
        uint256 amountWithFee,
        bytes32 originalTxHash,
        uint256 blockchainNum,
        bytes memory concatSignatures
    ) internal {
        bytes32 hashedParams = getHashPacked(
            user,
            amountWithFee,
            originalTxHash,
            blockchainNum
        );
        uint256 statusCode = processedTransactions[originalTxHash];
        require(statusCode == 0, "swapContract: Transaction already processed");

        uint256 signaturesCount = concatSignatures.length /
            uint256(SIGNATURE_LENGTH);
        address[] memory validatorAddresses = new address[](signaturesCount);
        for (uint256 i = 0; i < signaturesCount; i++) {
            address validatorAddress = ecOffsetRecover(
                hashedParams,
                concatSignatures,
                i * SIGNATURE_LENGTH
            );
            require(
                isValidator(validatorAddress),
                "swapContract: Validator address not in whitelist"
            );
            for (uint256 j = 0; j < i; j++) {
                require(
                    validatorAddress != validatorAddresses[j],
                    "swapContract: Validator address is duplicated"
                );
            }
            validatorAddresses[i] = validatorAddress;
        }
        processedTransactions[originalTxHash] = 1;
    }
    
    function _calculateFee(address provider, uint256 amountWithFee, uint256 initBlockchainNum) internal returns(uint256 amountWithoutFee) {
        if (provider != address(0)){
            uint256 providerPercent = providerFee[provider];

            if (providerPercent > 0){
                uint256 platformPercent = platformShare[provider];

                uint256 _providerAndProtocolFee = FullMath.mulDiv(
                    amountWithFee,
                    providerPercent,
                    1e6
                );

                uint256 _platformFee = FullMath.mulDiv(
                    _providerAndProtocolFee,
                    platformPercent,
                    1e6
                );

                amountOfProvider[provider] += _providerAndProtocolFee - _platformFee;
                accTokenFee += _platformFee;

                amountWithoutFee = amountWithFee - _providerAndProtocolFee;
            } else {
                amountWithoutFee = amountWithFee;
            }
        } else {
            amountWithoutFee = FullMath.mulDiv(
                amountWithFee,
                1e6 - feeAmountOfBlockchain[initBlockchainNum],
                1e6
            );

            accTokenFee += amountWithFee - amountWithoutFee;
        }
    }

    /**
     * @dev Function to check if address is belongs to relayer role
     * @param account Address to check
     */
    function isRelayer(address account) public view returns (bool) {
        return hasRole(RELAYER_ROLE, account);
    }

    /**
     * @dev Function to check if address is belongs to validator role
     * @param account Address to check
     *
     */
    function isValidator(address account) public view returns (bool) {
        return hasRole(VALIDATOR_ROLE, account);
    }
}

pragma solidity =0.8.4;

import "../../node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../node_modules/@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../../node_modules/@openzeppelin/contracts/access/AccessControl.sol";
import "../../node_modules/@openzeppelin/contracts/security/Pausable.sol";
import "../libraries/ECDSAOffsetRecovery.sol";
import "../libraries/FullMath.sol";

abstract contract Storage is AccessControl, Pausable, ECDSAOffsetRecovery {
    bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    bytes32 public constant RELAYER_ROLE = keccak256("RELAYER_ROLE");
    bytes32 public constant VALIDATOR_ROLE = keccak256("VALIDATOR_ROLE");

    uint128 public numOfThisBlockchain;
    address public blockchainRouter;
    mapping(uint256 => bytes32) public RubicAddresses;
    mapping(uint256 => bool) public existingOtherBlockchain;
    mapping(uint256 => uint256) public feeAmountOfBlockchain;
    mapping(uint256 => uint256) public blockchainCryptoFee;

    uint256 public constant SIGNATURE_LENGTH = 65;

    mapping(bytes32 => uint256) public processedTransactions;
    uint256 public minConfirmationSignatures = 3;

    uint256 public minTokenAmount;
    uint256 public maxTokenAmount;
    uint256 public maxGasPrice;
    uint256 public minConfirmationBlocks;
    uint256 private _refundGap;

    uint256 public accTokenFee = 1;
}