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
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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
// OpenZeppelin Contracts (last updated v4.8.0) (access/Ownable2Step.sol)

pragma solidity ^0.8.0;

import "./Ownable.sol";

/**
 * @dev Contract module which provides access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership} and {acceptOwnership}.
 *
 * This module is used through inheritance. It will make available all functions
 * from parent (Ownable).
 */
abstract contract Ownable2Step is Ownable {
    address private _pendingOwner;

    event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Returns the address of the pending owner.
     */
    function pendingOwner() public view virtual returns (address) {
        return _pendingOwner;
    }

    /**
     * @dev Starts the ownership transfer of the contract to a new account. Replaces the pending transfer if there is one.
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual override onlyOwner {
        _pendingOwner = newOwner;
        emit OwnershipTransferStarted(owner(), newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`) and deletes any pending owner.
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual override {
        delete _pendingOwner;
        super._transferOwnership(newOwner);
    }

    /**
     * @dev The new owner accepts the ownership transfer.
     */
    function acceptOwnership() public virtual {
        address sender = _msgSender();
        require(pendingOwner() == sender, "Ownable2Step: caller is not the new owner");
        _transferOwnership(sender);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(
        address[] calldata accounts,
        uint256[] calldata ids
    ) external view returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Permit.sol)

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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/IERC20Permit.sol";
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

    /**
     * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    /**
     * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
     * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
     */
    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    /**
     * @dev Increase the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance + value));
    }

    /**
     * @dev Decrease the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance - value));
        }
    }

    /**
     * @dev Set the calling contract's allowance toward `spender` to `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful. Compatible with tokens that require the approval to be set to
     * 0 before setting it to a non-zero value.
     */
    function forceApprove(IERC20 token, address spender, uint256 value) internal {
        bytes memory approvalCall = abi.encodeWithSelector(token.approve.selector, spender, value);

        if (!_callOptionalReturnBool(token, approvalCall)) {
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, 0));
            _callOptionalReturn(token, approvalCall);
        }
    }

    /**
     * @dev Use a ERC-2612 signature to set the `owner` approval toward `spender` on `token`.
     * Revert on invalid signature.
     */
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
        require(returndata.length == 0 || abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     *
     * This is a variant of {_callOptionalReturn} that silents catches all reverts and returns a bool instead.
     */
    function _callOptionalReturnBool(IERC20 token, bytes memory data) private returns (bool) {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We cannot use {Address-functionCall} here since this should return false
        // and not revert is the subcall reverts.

        (bool success, bytes memory returndata) = address(token).call(data);
        return
            success && (returndata.length == 0 || abi.decode(returndata, (bool))) && Address.isContract(address(token));
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
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
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
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable2Step.sol";
import "../interfaces/ICollectionFactory.sol";
import "../interfaces/ITreasury.sol";

/**
 * @title Smart contract that is responsible for selling Bullion Collections (ERC1155)
 * @author Linum Labs
 * @dev Only collections created by Bullion can be used in sales
 */
contract Sale is Ownable2Step {
    /*//////////////////////////////////////////////////////////////
                           STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    using SafeERC20 for IERC20;

    /// The stablecoin used to purchase and receive fractionalized nft price
    IERC20 private immutable _USDC;

    /// The CollectionFactory contract that is responsible for creating new ERC1155 collections
    ICollectionFactory private immutable _FACTORY;

    /// The Treasury contract
    ITreasury private immutable _TREASURY;

    /// Bullion wallet address
    address private _BULLIONWALLET;

    /// System fee = (payment * fee)/_DIVISOR
    uint32 private constant _DIVISOR = 100;

    /// The addresses of the price setting accounts
    address private _approvedAccount;

    /// The number of sales that have been created.
    uint128 public saleIdCounter;

    uint32 public fee;

    /*//////////////////////////////////////////////////////////////
                    MAPPINGS/ARRAYS/STRUCTS/ENUMS
    //////////////////////////////////////////////////////////////*/

    /// The sale info of a particular sale
    mapping(uint256 saleId => SaleInfo saleInfo) public saleIdToSaleInfo;

    struct SaleInfo {
        SaleStatus saleStatus;
        bool isForBullion;
        address seller;
        address collectionAddress;
        uint64 nftId;
        uint64 nftAmountToSell;
        uint64 nftAmountSold;
        uint256 nftPrice;
    }

    enum SaleStatus {
        ACTIVE,
        SOLD_OUT,
        CANCELLED,
        REJECTED
    }

    /*//////////////////////////////////////////////////////////////
                             CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        address USDCAddress,
        address factory,
        address treasury,
        address approvedAccount,
        uint256 fee_
    ) {
        _USDC = IERC20(USDCAddress);
        _FACTORY = ICollectionFactory(factory);
        _TREASURY = ITreasury(treasury);
        _approvedAccount = approvedAccount;
        fee = uint32(fee_);
    }

    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Emit when a sale is successfully created
     * @param isForBullion If the sale is only for Bullion to buy
     * @param saleId The id of a sale
     * @param collectionAddress The address of the collection that holds fractionalized nfts to sell
     * @param nftId The nft id to sell in the abovementioned collection
     * @param nftAmountToSell The amount of nfts in to sell
     * @param seller The seller of the sale
     */
    event SaleCreated(
        bool isForBullion,
        uint256 indexed saleId,
        address indexed collectionAddress,
        uint256 indexed nftId,
        uint256 nftAmountToSell,
        address seller
    );

    /**
     * @notice Emit when a buyer successfuly buys fractionalized nfts from a given sale
     * @param buyer The buyer
     * @param saleId The id of the sale
     * @param collectionAddress The address of the collection that holds fractionalized nfts to buy
     * @param nftId The nft id to buy in the abovementioned collection
     * @param nftPrice The price for each fractionalized nft
     * @param nftAmountBought The amount of fractionalized nfts to buy
     */
    event Bought(
        bool isForBullion,
        address indexed buyer,
        uint256 indexed saleId,
        address indexed collectionAddress,
        uint256 nftId,
        uint256 nftPrice,
        uint256 nftAmountBought
    );

    /**
     * @notice Emit when the owner successfuly sets price for each fractionalized nft of a give sale id
     * @param saleId The id of the sale
     * @param nftPrice The price to set to
     */
    event PriceSet(uint256 indexed saleId, uint256 indexed nftPrice);

    /**
     * @notice Emit when the seller successfuly cancels a sale
     * @param saleId The id of the sale
     */
    event SaleCancelled(uint256 indexed saleId);

    /**
     * @notice Emit when Bullion successfuly rejects a sale
     * @param saleId The id of the sale
     */
    event SaleRejected(uint256 indexed saleId);

    /**
     * @notice Emit when the owner updates the fee successfully
     * @param newFee The new fee
     */
    event FeeUpdated(uint256 indexed newFee);

    /**
     * @notice Emit when the sale status changes
     * @param newStatus The updated sale status
     */
    event SaleStatusUpdated(SaleStatus indexed newStatus);

    /*//////////////////////////////////////////////////////////////
                                MODIFIERS
    //////////////////////////////////////////////////////////////*/

    modifier onlyApproved() {
        if (msg.sender != _approvedAccount) revert NotApprovedAccount();
        _;
    }

    modifier saleActive(uint256 saleId) {
        if (saleIdToSaleInfo[saleId].saleStatus != SaleStatus.ACTIVE)
            revert SaleIsNotActive();
        _;
    }

    modifier saleExists(uint256 saleId) {
        if (saleId >= saleIdCounter) revert SaleDoesNotExsit();
        _;
    }

    /*//////////////////////////////////////////////////////////////
                                ERRORS
    //////////////////////////////////////////////////////////////*/

    error NotApprovedAccount();
    error NotBullionCollection();
    error NftAmountMustBeGreaterThan0();
    error PriceMustBeGreaterThan0();
    error SaleDoesNotExsit();
    error NotEnoughNftsToBuy();
    error OnlyBullion();
    error SaleIsNotActive();
    error SaleIsNotForBullion();
    error PriceIsNotSet();
    error PriceCanNotBe0();
    error CallerMustBeSaleCreator();
    error SaleIsSoldOut();

    /*//////////////////////////////////////////////////////////////
                       STATE-CHANGING FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Create a sale for a given nft
     * @dev Only nfts within a collection created by Bullion can be traded in sales
     * @param isForBullion If the sale is only for Bullion to buy
     * @param collectionAddress The address of the collection that holds nfts to sell
     * @param nftId The nft id in the abovementioned collection
     * @param nftAmount The number of fractions of the nft to sell
     */
    function createSale(
        bool isForBullion,
        address collectionAddress,
        uint256 nftId,
        uint256 nftAmount
    ) external {
        if (!_FACTORY.isBullionCollection(collectionAddress))
            revert NotBullionCollection();
        if (nftAmount == 0) revert NftAmountMustBeGreaterThan0();

        /// Save sale info
        uint256 saleId = saleIdCounter;
        saleIdToSaleInfo[saleId].isForBullion = isForBullion;
        saleIdToSaleInfo[saleId].seller = msg.sender;
        saleIdToSaleInfo[saleId].collectionAddress = collectionAddress;
        saleIdToSaleInfo[saleId].nftId = uint64(nftId);
        saleIdToSaleInfo[saleId].nftAmountToSell = uint64(nftAmount);

        unchecked {
            ++saleIdCounter;
        }

        /// Transfer fractionalized nfts from the seller to the Bullion treasury
        IERC1155(collectionAddress).safeTransferFrom(
            msg.sender,
            address(_TREASURY),
            nftId,
            nftAmount,
            ""
        );

        /// Update the sale status
        saleIdToSaleInfo[saleId].saleStatus = SaleStatus.ACTIVE;

        emit SaleStatusUpdated(saleIdToSaleInfo[saleId].saleStatus);

        emit SaleCreated(
            isForBullion,
            saleId,
            collectionAddress,
            nftId,
            nftAmount,
            msg.sender
        );
    }

    /**
     * @notice Cancel a particular sale
     * @notice Will transfer unsold nfts from the treasury back to the seller on success
     * @param saleId The id of the sale to be cancelled
     */
    function cancelSale(
        uint256 saleId
    ) external saleExists(saleId) saleActive(saleId) {
        SaleInfo storage saleIdToSaleInfo_ = saleIdToSaleInfo[saleId];
        if (msg.sender != saleIdToSaleInfo_.seller)
            revert CallerMustBeSaleCreator();

        /// Update the sale status
        saleIdToSaleInfo[saleId].saleStatus = SaleStatus.CANCELLED;

        emit SaleStatusUpdated(saleIdToSaleInfo[saleId].saleStatus);

        /// Transfer unsold fractionalized nfts from the Treasury back to the seller
        _TREASURY.transferFractionalizedNFTs(
            saleIdToSaleInfo_.collectionAddress,
            msg.sender,
            saleIdToSaleInfo_.nftId,
            saleIdToSaleInfo_.nftAmountToSell - saleIdToSaleInfo_.nftAmountSold
        );

        emit SaleCancelled(saleId);
    }

    /**
     * @notice Buy fractionalized nfts from a particular sale id
     * @param saleId The id of the sale to buy fractionalized nfts from
     * @param nftAmountToBuy The amount of fractionalized nfts to buy
     */
    function buy(
        uint256 saleId,
        uint256 nftAmountToBuy
    ) external saleExists(saleId) saleActive(saleId) {
        SaleInfo storage saleIdToSaleInfo_ = saleIdToSaleInfo[saleId];
        bool isForBullion = saleIdToSaleInfo_.isForBullion;

        if (isForBullion) {
            if (msg.sender != owner()) revert OnlyBullion();
        }

        uint256 nftPrice = saleIdToSaleInfo_.nftPrice;
        if (nftPrice == 0) revert PriceIsNotSet();

        uint256 available;
        unchecked {
            available =
                saleIdToSaleInfo_.nftAmountToSell -
                saleIdToSaleInfo_.nftAmountSold;
        }

        if (nftAmountToBuy > available) revert NotEnoughNftsToBuy();

        if (nftAmountToBuy == available) {
            saleIdToSaleInfo_.saleStatus = SaleStatus.SOLD_OUT;
            emit SaleStatusUpdated(saleIdToSaleInfo[saleId].saleStatus);
        }

        uint256 payment = nftPrice * nftAmountToBuy;
        /// Note: Solidity will round down in divisions. e.g. 2/3 will result in 0
        uint256 systemFee = (payment * fee) / _DIVISOR;

        /// Update the amount of nfts that have been sold
        unchecked {
            saleIdToSaleInfo_.nftAmountSold += uint64(nftAmountToBuy);
        }

        /// Reset the nft price
        delete saleIdToSaleInfo_.nftPrice;

        if (isForBullion) {
            /// Keep system fee in the treasury, transfer the rest to the seller from the treasury
            _USDC.safeTransferFrom(
                address(_TREASURY),
                saleIdToSaleInfo_.seller,
                payment - systemFee
            );
        } else {
            /// Transfer system fee to the treasury, the rest to the seller
            _USDC.safeTransferFrom(msg.sender, address(_TREASURY), systemFee);
            _USDC.safeTransferFrom(
                msg.sender,
                saleIdToSaleInfo_.seller,
                payment - systemFee
            );
        }

        /// Transfer nfts from the Treasury to the buyer/Bullion
        _TREASURY.transferFractionalizedNFTs(
            saleIdToSaleInfo_.collectionAddress,
            msg.sender,
            saleIdToSaleInfo_.nftId,
            nftAmountToBuy
        );
        
        emit Bought(
            isForBullion,
            msg.sender,
            saleId,
            saleIdToSaleInfo_.collectionAddress,
            saleIdToSaleInfo_.nftId,
            nftPrice,
            nftAmountToBuy
        );
    }

    /**
     * @notice Reject a particular sale
     * @notice Bullion can reject the sale after buying a portion of the fractionlized nfts the seller offers
     * @notice Will transfer unsold nfts from the treasury back to the seller on success
     * @dev Only Bullion can call this function
     * @param saleId The id of the sale to be rejected
     */
    function rejectSale(
        uint256 saleId
    ) external saleExists(saleId) saleActive(saleId) {
        if (msg.sender != owner()) revert OnlyBullion();

        SaleInfo storage saleIdToSaleInfo_ = saleIdToSaleInfo[saleId];
        if (!saleIdToSaleInfo_.isForBullion) revert SaleIsNotForBullion();

        /// Update the sale status
        saleIdToSaleInfo[saleId].saleStatus = SaleStatus.REJECTED;

        emit SaleStatusUpdated(saleIdToSaleInfo[saleId].saleStatus);

        /// Transfer unsold fractionalized nfts from the Treasury back to the seller
        _TREASURY.transferFractionalizedNFTs(
            saleIdToSaleInfo_.collectionAddress,
            saleIdToSaleInfo_.seller,
            saleIdToSaleInfo_.nftId,
            saleIdToSaleInfo_.nftAmountToSell - saleIdToSaleInfo_.nftAmountSold
        );

        emit SaleRejected(saleId);
    }

    /**
     * @notice Set the price for each fractionalized nft of a given sale
     * @dev Only the contract owner can call this function
     * @param saleId The id of the sale to set fractionalized nft price
     * @param nftPrice The price for each fractionalized nft
     */
    function setPrice(
        uint256 saleId,
        uint256 nftPrice
    ) external saleExists(saleId) saleActive(saleId) onlyApproved {
        if (nftPrice == 0) revert PriceCanNotBe0();

        saleIdToSaleInfo[saleId].nftPrice = nftPrice;

        emit PriceSet(saleId, nftPrice);
    }

    /**
     * @notice Update the Bullion fee
     * System fee = (payment * fee)/_DIVISOR
     * @dev Only the contract owner can call this function
     * @param fee_ The new fee
     */
    function updateFee(uint256 fee_) external onlyOwner {
        fee = uint32(fee_);

        emit FeeUpdated(fee_);
    }

    /** @notice Switches approvedContract access to the input address
     *  @dev Only the contract owner can call this function
     * @param _toApprove The address to give admin access to
     */
    function updateApprovedAccount(address _toApprove) external onlyOwner {
        _approvedAccount = _toApprove;
    }

    /*//////////////////////////////////////////////////////////////
                       VIEW/PURE FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice View function that returns the approved price setter address.
     * @return _approvedAccount
     */
    function getApprovedAccountAddress()
        external
        view
        onlyOwner
        returns (address)
    {
        return _approvedAccount;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface ICollectionFactory {
    function collectionAddresses() external view returns (address[] memory);

    function isBullionCollection(address) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface ITreasury {
    function transferFractionalizedNFTs(
        address _collectionAddress,
        address _toAddress,
        uint256 _nftId,
        uint256 _nftAmount
    ) external;
}