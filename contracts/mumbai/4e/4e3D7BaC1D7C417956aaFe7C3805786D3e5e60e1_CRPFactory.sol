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
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/Proxy.sol)

pragma solidity ^0.8.0;

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /**
     * @dev This is a virtual function that should be overridden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback() external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive() external payable virtual {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overridden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;

import "./ERC1155Receiver.sol";

/**
 * Simple implementation of `ERC1155Receiver` that will allow a contract to hold ERC1155 tokens.
 *
 * IMPORTANT: When inheriting this contract, you must include a way to use the received tokens, otherwise they will be
 * stuck.
 *
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../IERC1155Receiver.sol";
import "../../../utils/introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
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

//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/Context.sol";
import "../interfaces/IAuthorization.sol";

/**
 * @title Authorizable
 * @author Protofire
 * @dev Contract module which provides an authorization mechanism.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyAuthorized`, which can be applied to your functions to restrict their use.
 */
abstract contract Authorizable is Context {
    /// @dev Address of Authorization contract.
    IAuthorization public authorization;

    /**
     * @dev Emitted when `authorization` address is set.
     */
    event AuthorizationSet(address indexed newAuthorization);

    /**
     * @dev Throws if called by any account which is not authorized to execute the transaction.
     */
    modifier onlyAuthorized() {
        require(
            authorization.isAuthorized(_msgSender(), address(this), msg.sig, _msgData()),
            "Authorizable: not authorized"
        );
        _;
    }

    /**
     * @dev Sets authorization.
     *
     */
    function _setAuthorization(address authorization_) internal {
        require(authorization_ != address(0), "Authorizable: authorization is the zero address");
        authorization = IAuthorization(authorization_);
        emit AuthorizationSet(authorization_);
    }
}

//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.17;

/**
 * @title IAuthorization
 * @author Protofire
 * @dev Interface to be implemented by any Authorization logic contract.
 *
 */
interface IAuthorization {
    /**
     * @dev Sets `_permissions` as the new Permissions module.
     *
     * @param _permissions The address of the new Permissions module.
     */
    function setPermissions(address _permissions) external;

    /**
     * @dev Sets `_eurPriceFeed` as the new EUR Price feed module.
     *
     * @param _eurPriceFeed The address of the new EUR Price feed module.
     */
    function setEurPriceFeed(address _eurPriceFeed) external;

    /**
     * @dev Sets `_operationsRegistry` as the new OperationsRegistry module.
     *
     * @param _operationsRegistry The address of the new OperationsRegistry module.
     */
    function setOperationsRegistry(address _operationsRegistry) external;

    /**
     * @dev Sets `_tradingLimit` as the new trading limit.
     *
     * @param _tradingLimit The value of the new trading limit.
     */
    function setTradingLimit(uint256 _tradingLimit) external;

    /**
     * @dev Sets `_poolFactory` as the new BFactory module.
     *
     * @param _poolFactory The address of the new Balancer BFactory module.
     */
    function setPoolFactory(address _poolFactory) external;

    /**
     * @dev Sets `_crpFactory` as the new CRPFactory module.
     *
     * @param _crpFactory The address of the new Balancer CRPFactory module.
     */
    function setCrpFactory(address _crpFactory) external;

    /**
     * @dev Sets `_xTokenWrapper` as the new XTokenWrapper module.
     *
     * @param _xTokenWrapper The address of the new XTokenWrapper module.
     */
    function setXTokenWrapper(address _xTokenWrapper) external;

    /**
     * @dev Determines if a user is allowed to perform an operation.
     *
     * @param _user msg.sender from function using Authorizable `onlyAuthorized` modifier.
     * @param _asset address of the contract using Authorizable `onlyAuthorized` modifier.
     * @param _operation msg.sig from function using Authorizable `onlyAuthorized` modifier.
     * @param _data msg.data from function using Authorizable `onlyAuthorized` modifier.
     * @return a boolean signaling the authorization.
     */
    function isAuthorized(
        address _user,
        address _asset,
        bytes4 _operation,
        bytes calldata _data
    ) external returns (bool);
}

//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title IBPool
 * @author Protofire
 * @dev Balancer BPool contract interface.
 *
 */
interface IBPool is IERC20 {
    // solhint-disable-next-line func-name-mixedcase
    function EXIT_FEE() external view returns (uint256);

    function isPublicSwap() external view returns (bool);

    function isFinalized() external view returns (bool);

    function isBound(address t) external view returns (bool);

    function getNumTokens() external view returns (uint256);

    function getCurrentTokens() external view returns (address[] memory tokens);

    function getFinalTokens() external view returns (address[] memory tokens);

    function getDenormalizedWeight(address token) external view returns (uint256);

    function getTotalDenormalizedWeight() external view returns (uint256);

    function getNormalizedWeight(address token) external view returns (uint256);

    function getBalance(address token) external view returns (uint256);

    function getSwapFee() external view returns (uint256);

    function getController() external view returns (address);

    function setSwapFee(uint256 swapFee) external;

    function setController(address manager) external;

    function setPublicSwap(bool public_) external;

    function finalize() external;

    function bind(
        address token,
        uint256 balance,
        uint256 denorm
    ) external;

    function rebind(
        address token,
        uint256 balance,
        uint256 denorm
    ) external;

    function unbind(address token) external;

    function gulp(address token) external;

    function getSpotPrice(address tokenIn, address tokenOut) external view returns (uint256 spotPrice);

    function getSpotPriceSansFee(address tokenIn, address tokenOut) external view returns (uint256 spotPrice);

    function joinPool(uint256 poolAmountOut, uint256[] calldata maxAmountsIn) external;

    function exitPool(uint256 poolAmountIn, uint256[] calldata minAmountsOut) external;

    function swapExactAmountIn(
        address tokenIn,
        uint256 tokenAmountIn,
        address tokenOut,
        uint256 minAmountOut,
        uint256 maxPrice
    ) external returns (uint256 tokenAmountOut, uint256 spotPriceAfter);

    function swapExactAmountOut(
        address tokenIn,
        uint256 maxAmountIn,
        address tokenOut,
        uint256 tokenAmountOut,
        uint256 maxPrice
    ) external returns (uint256 tokenAmountIn, uint256 spotPriceAfter);

    function joinswapExternAmountIn(
        address tokenIn,
        uint256 tokenAmountIn,
        uint256 minPoolAmountOut
    ) external returns (uint256 poolAmountOut);

    function joinswapPoolAmountOut(
        address tokenIn,
        uint256 poolAmountOut,
        uint256 maxAmountIn
    ) external returns (uint256 tokenAmountIn);

    function exitswapPoolAmountIn(
        address tokenOut,
        uint256 poolAmountIn,
        uint256 minAmountOut
    ) external returns (uint256 tokenAmountOut);

    function exitswapExternAmountOut(
        address tokenOut,
        uint256 tokenAmountOut,
        uint256 maxPoolAmountIn
    ) external returns (uint256 poolAmountIn);

    function calcSpotPrice(
        uint256 tokenBalanceIn,
        uint256 tokenWeightIn,
        uint256 tokenBalanceOut,
        uint256 tokenWeightOut,
        uint256 swapFee
    ) external pure returns (uint256 spotPrice);

    function calcOutGivenIn(
        uint256 tokenBalanceIn,
        uint256 tokenWeightIn,
        uint256 tokenBalanceOut,
        uint256 tokenWeightOut,
        uint256 tokenAmountIn,
        uint256 swapFee
    ) external pure returns (uint256 tokenAmountOut);

    function calcInGivenOut(
        uint256 tokenBalanceIn,
        uint256 tokenWeightIn,
        uint256 tokenBalanceOut,
        uint256 tokenWeightOut,
        uint256 tokenAmountOut,
        uint256 swapFee
    ) external pure returns (uint256 tokenAmountIn);

    function calcPoolOutGivenSingleIn(
        uint256 tokenBalanceIn,
        uint256 tokenWeightIn,
        uint256 poolSupply,
        uint256 totalWeight,
        uint256 tokenAmountIn,
        uint256 swapFee
    ) external pure returns (uint256 poolAmountOut);

    function calcSingleInGivenPoolOut(
        uint256 tokenBalanceIn,
        uint256 tokenWeightIn,
        uint256 poolSupply,
        uint256 totalWeight,
        uint256 poolAmountOut,
        uint256 swapFee
    ) external pure returns (uint256 tokenAmountIn);

    function calcSingleOutGivenPoolIn(
        uint256 tokenBalanceOut,
        uint256 tokenWeightOut,
        uint256 poolSupply,
        uint256 totalWeight,
        uint256 poolAmountIn,
        uint256 swapFee
    ) external pure returns (uint256 tokenAmountOut);

    function calcPoolInGivenSingleOut(
        uint256 tokenBalanceOut,
        uint256 tokenWeightOut,
        uint256 poolSupply,
        uint256 totalWeight,
        uint256 tokenAmountOut,
        uint256 swapFee
    ) external pure returns (uint256 poolAmountIn);
}

//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.17;

/// @author Swarm Markets
/// @title IPermissionManager
/// @notice Provided interface to interact with Swarm Permission Manager
/// @notice authorization to a given address
interface IPermissionManager {
    function hasTier2(address _account) external view returns (bool);

    function isSuspended(address _account) external view returns (bool);

    function isRejected(address _account) external view returns (bool);

    function assignItem(uint256 _itemId, address[] memory _accounts) external;

    function getSecurityTokenId(address _tokenContract) external view returns (uint256);

    function generateSecurityTokenId(address _tokenContract) external returns (uint256);

    function editLastSecurityTokenId(uint256 _newId) external;

    function hasSecurityToken(address _user, uint256 itemId) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";

import "../interfaces/IPermissionManager.sol";

import "../authorization/Authorizable.sol";

import "./interfaces/ICRPool.sol";
import "./interfaces/ICRPFactory.sol";

import "./libraries/BalancerConstants.sol";

import "./CRPoolExtend.sol";

/**
 * @author Swarm
 * @title Configurable Rights Pool Factory - create parameterized smart pools
 * @dev Rights are held in a corresponding struct in CRPool
 *      Index values are as follows:
 *      0: canPauseSwapping - can setPublicSwap back to false after turning it on
 *                            by default, it is off on initialization and can only be turned on
 *      1: canChangeSwapFee - can setSwapFee after initialization (by default, it is fixed at create time)
 *      2: canChangeWeights - can bind new token weights (allowed by default in base pool)
 *      3: canAddRemoveTokens - can bind/unbind tokens (allowed by default in base pool)
 *      4: canWhitelistLPs - if set, only whitelisted addresses can join pools
 *                           (enables private pools with more than one LP)
 *      5: canChangeCap - can change the BSP cap (max # of pool tokens)
 */
contract CRPFactory is ICRPFactory, Authorizable, Ownable {
    address public crpoolProxyImplementation;
    address public permissionManager;
    address public exchangeProxy;

    mapping(address => bool) private _isCrp;

    event CRPoolProxyImplementationUpdated(address indexed caller, address indexed crpoolProxyImplementation);
    event PermissionManagerUpdated(address indexed caller, address indexed permissionManager);
    event ExchangeProxyUpdated(address indexed caller, address indexed exchangeProxy);

    event NewCrpCreated(address indexed caller, address indexed pool);

    constructor(
        address _crpoolProxyImplementation,
        address _permissionManager,
        address _exchangeProxy,
        address _authorization
    ) {
        setCRPoolProxyImplementation(_crpoolProxyImplementation);
        setPermissionManager(_permissionManager);
        setExchangeProxy(_exchangeProxy);
        setAuthorization(_authorization);
    }

    function setCRPoolProxyImplementation(address _crpoolProxyImplementation) public onlyOwner {
        emit CRPoolProxyImplementationUpdated(_msgSender(), _crpoolProxyImplementation);
        crpoolProxyImplementation = _crpoolProxyImplementation;
    }

    function setPermissionManager(address _permissionManager) public onlyOwner {
        emit PermissionManagerUpdated(_msgSender(), _permissionManager);
        permissionManager = _permissionManager;
    }

    function setExchangeProxy(address _exchangeProxy) public onlyOwner {
        emit ExchangeProxyUpdated(_msgSender(), _exchangeProxy);
        exchangeProxy = _exchangeProxy;
    }

    function setAuthorization(address _authorization) public onlyOwner {
        _setAuthorization(_authorization);
    }

    function isCrp(address _address) external view override returns (bool) {
        return _isCrp[_address];
    }

    /**
     * @notice Create a new CRP
     * @dev emits a NewCrpCreated event
     * @param _bFactoryAddress - the BFactory instance used to create the underlying pool
     * @param _poolParams - struct containing the names, tokens, weights, balances, and swap fee
     * @param _rights - struct of permissions, configuring this CRP instance (see above for definitions)
     */
    function newCrp(
        address _bFactoryAddress,
        PoolParams calldata _poolParams,
        RightsManager.Rights calldata _rights
    ) external override onlyAuthorized returns (CRPoolExtend) {
        require(crpoolProxyImplementation != address(0), "ERR_CRPOOL_PROXY_IMPLEMENTATION_NOT_SET");
        require(exchangeProxy != address(0), "ERR_EXCHANGE_PROXY_NOT_SET");
        require(permissionManager != address(0), "ERR_PERM_MAN_NOT_SET");

        require(_poolParams.constituentTokens.length >= BalancerConstants.MIN_ASSET_LIMIT, "ERR_TOO_FEW_TOKENS");

        // Arrays must be of same length
        require(
            _poolParams.tokenBalances.length == _poolParams.constituentTokens.length,
            "ERR_START_BALANCES_MISMATCH"
        );
        require(_poolParams.tokenWeights.length == _poolParams.constituentTokens.length, "ERR_START_WEIGHTS_MISMATCH");

        CRPoolExtend newCRPool = new CRPoolExtend(
            crpoolProxyImplementation,
            exchangeProxy,
            abi.encodeWithSignature(
                // solhint-disable-next-line max-line-length
                "initialize(address,(string,string,address[],uint256[],uint256[],uint256),(bool,bool,bool,bool,bool,bool))",
                _bFactoryAddress,
                _poolParams,
                _rights
            )
        );

        _isCrp[address(newCRPool)] = true;

        address[] memory accounts = new address[](1);
        accounts[0] = address(newCRPool);

        emit NewCrpCreated(_msgSender(), address(newCRPool));

        // The caller is the owner of the CRP
        // The CRP will be the controller of the underlying BPool
        ICRPool(address(newCRPool)).transferOwnership(_msgSender());

        // Assign permissions
        IPermissionManager(permissionManager).assignItem(2, accounts); // Tier 2
        IPermissionManager(permissionManager).assignItem(5, accounts); // POOL_CREATOR

        return newCRPool;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/proxy/Proxy.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

import "./interfaces/ICRPool.sol";

contract CRPoolExtend is Proxy, ERC1155Holder {
    address public immutable implementation;
    address public immutable exchangeProxy;

    constructor(
        address _crpoolProxyImplementation,
        address _exchangeProxy,
        bytes memory _data
    ) {
        implementation = _crpoolProxyImplementation;
        exchangeProxy = _exchangeProxy;

        if (_data.length > 0) {
            Address.functionDelegateCall(_crpoolProxyImplementation, _data);
        }
    }

    function _implementation() internal view override returns (address) {
        return implementation;
    }

    function _beforeFallback() internal view override {
        _onlyExchangeProxy();
    }

    function _onlyExchangeProxy() internal view {
        if (
            // createPool signature has to be written manually because of the overload
            // See: https://github.com/ethereum/solidity/issues/3556
            msg.sig == bytes4(keccak256("createPool(uint256,uint256,uint256)")) ||
            msg.sig == bytes4(keccak256("createPool(uint256)")) ||
            msg.sig == ICRPool.updateWeight.selector ||
            msg.sig == ICRPool.applyAddToken.selector ||
            msg.sig == ICRPool.removeToken.selector ||
            msg.sig == ICRPool.joinPool.selector ||
            msg.sig == ICRPool.exitPool.selector ||
            msg.sig == ICRPool.joinswapExternAmountIn.selector ||
            msg.sig == ICRPool.joinswapPoolAmountOut.selector ||
            msg.sig == ICRPool.exitswapPoolAmountIn.selector ||
            msg.sig == ICRPool.exitswapExternAmountOut.selector
        ) {
            require(msg.sender == exchangeProxy, "ERR_NOT_EXCHANGE_PROXY");
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

// Interface declarations

// Introduce to avoid circularity (otherwise, the CRP and SmartPoolManager include each other)
// Removing circularity allows flattener tools to work, which enables Etherscan verification
interface IConfigurableRightsPool {
    function mintPoolShareFromLib(uint256 amount) external;

    function pushPoolShareFromLib(address to, uint256 amount) external;

    function pullPoolShareFromLib(address from, uint256 amount) external;

    function burnPoolShareFromLib(uint256 amount) external;

    function totalSupply() external view returns (uint256);

    function owner() external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.17;

import "../libraries/RightsManager.sol";

import "../CRPoolExtend.sol";

import "./IPoolParams.sol";

interface ICRPFactory {
    function isCrp(address _address) external view returns (bool);

    function newCrp(
        address _bFactoryAddress,
        PoolParams calldata _poolParams,
        RightsManager.Rights calldata _rights
    ) external returns (CRPoolExtend);
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.17;

// Needed to pass in structs
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../../interfaces/IBPool.sol";

import "../libraries/SmartPoolManager.sol";

interface ICRPool is IERC20 {
    function bPool() external view returns (IBPool);

    function initialTokens() external view returns (address[] calldata);

    function initialBalances() external view returns (uint256[] calldata);

    function newToken() external view returns (SmartPoolManager.NewTokenParams calldata);

    function getDenormalizedWeight(address token) external view returns (uint256);

    function createPool(
        uint256 _initialSupply,
        uint256 _minimumWeightChangeBlockPeriodParam,
        uint256 _addTokenTimeLockInBlocksParam
    ) external;

    function createPool(uint256 _initialSupply) external;

    function updateWeight(address _token, uint256 _newWeight) external;

    function commitAddToken(
        address _token,
        uint256 _balance,
        uint256 _denormalizedWeight
    ) external;

    function applyAddToken() external;

    function removeToken(address _token) external;

    function joinPool(
        uint256 _poolAmountOut,
        uint256[] calldata _maxAmountsIn,
        address sender
    ) external;

    function exitPool(uint256 _poolAmountIn, uint256[] calldata _minAmountsOut) external;

    function joinswapExternAmountIn(
        address _tokenIn,
        uint256 _tokenAmountIn,
        uint256 _minPoolAmountOut,
        address sender
    ) external returns (uint256 _poolAmountOut);

    function joinswapPoolAmountOut(
        address _tokenIn,
        uint256 _poolAmountOut,
        uint256 _maxAmountIn,
        address sender
    ) external returns (uint256 _tokenAmountIn);

    function exitswapPoolAmountIn(
        address _tokenOut,
        uint256 _poolAmountIn,
        uint256 _minAmountOut
    ) external returns (uint256 _tokenAmountOut);

    function exitswapExternAmountOut(
        address _tokenOut,
        uint256 _tokenAmountOut,
        uint256 _maxPoolAmountIn
    ) external returns (uint256 _poolAmountIn);

    // Ownable contract
    function owner() external view returns (address);

    function transferOwnership(address _newOwner) external;
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.17;

struct PoolParams {
    string poolTokenSymbol;
    string poolTokenName;
    address[] constituentTokens;
    uint256[] tokenBalances;
    uint256[] tokenWeights;
    uint256 swapFee;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

/**
 * @author Balancer Labs
 * @title Put all the constants in one place
 */

library BalancerConstants {
    // State variables (must be constant in a library)

    // B "ONE" - all math is in the "realm" of 10 ** 18;
    // where numeric 1 = 10 ** 18
    uint256 public constant BONE = 10**18;
    uint256 public constant MIN_WEIGHT = BONE;
    uint256 public constant MAX_WEIGHT = BONE * 50;
    uint256 public constant MAX_TOTAL_WEIGHT = BONE * 50;
    uint256 public constant MIN_BALANCE = BONE / 10**6;
    uint256 public constant MAX_BALANCE = BONE * 10**12;
    uint256 public constant MIN_POOL_SUPPLY = BONE * 100;
    uint256 public constant MAX_POOL_SUPPLY = BONE * 10**9;
    uint256 public constant MIN_FEE = BONE / 10**6;
    uint256 public constant MAX_FEE = BONE / 10;
    // EXIT_FEE must always be zero, or CRPool._pushUnderlying will fail
    uint256 public constant EXIT_FEE = 0;
    uint256 public constant MAX_IN_RATIO = BONE / 2;
    uint256 public constant MAX_OUT_RATIO = (BONE / 3) + 1 wei;
    // Must match BConst.MIN_BOUND_TOKENS and BConst.MAX_BOUND_TOKENS
    uint256 public constant MIN_ASSET_LIMIT = 2;
    uint256 public constant MAX_ASSET_LIMIT = 8;
    uint256 public constant MAX_UINT = type(uint256).max;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

// Imports

import "./BalancerConstants.sol";

/**
 * @author Balancer Labs
 * @title SafeMath - wrap Solidity operators to prevent underflow/overflow
 * @dev badd and bsub are basically identical to OpenZeppelin SafeMath; mul/div have extra checks
 */
library BalancerSafeMath {
    /**
     * @notice Safe addition
     * @param a - first operand
     * @param b - second operand
     * @dev if we are adding b to a, the resulting sum must be greater than a
     * @return - sum of operands; throws if overflow
     */
    function badd(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "ERR_ADD_OVERFLOW");
        return c;
    }

    /**
     * @notice Safe unsigned subtraction
     * @param a - first operand
     * @param b - second operand
     * @dev Do a signed subtraction, and check that it produces a positive value
     *      (i.e., a - b is valid if b <= a)
     * @return - a - b; throws if underflow
     */
    function bsub(uint256 a, uint256 b) internal pure returns (uint256) {
        (uint256 c, bool negativeResult) = bsubSign(a, b);
        require(!negativeResult, "ERR_SUB_UNDERFLOW");
        return c;
    }

    /**
     * @notice Safe signed subtraction
     * @param a - first operand
     * @param b - second operand
     * @dev Do a signed subtraction
     * @return - difference between a and b, and a flag indicating a negative result
     *           (i.e., a - b if a is greater than or equal to b; otherwise b - a)
     */
    function bsubSign(uint256 a, uint256 b) internal pure returns (uint256, bool) {
        if (b <= a) {
            return (a - b, false);
        } else {
            return (b - a, true);
        }
    }

    /**
     * @notice Safe multiplication
     * @param a - first operand
     * @param b - second operand
     * @dev Multiply safely (and efficiently), rounding down
     * @return - product of operands; throws if overflow or rounding error
     */
    function bmul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization (see github.com/OpenZeppelin/openzeppelin-contracts/pull/522)
        if (a == 0) {
            return 0;
        }

        // Standard overflow check: a/a*b=b
        uint256 c0 = a * b;
        require(c0 / a == b, "ERR_MUL_OVERFLOW");

        // Round to 0 if x*y < BONE/2?
        uint256 c1 = c0 + (BalancerConstants.BONE / 2);
        require(c1 >= c0, "ERR_MUL_OVERFLOW");
        uint256 c2 = c1 / BalancerConstants.BONE;
        return c2;
    }

    /**
     * @notice Safe division
     * @param dividend - first operand
     * @param divisor - second operand
     * @dev Divide safely (and efficiently), rounding down
     * @return - quotient; throws if overflow or rounding error
     */
    function bdiv(uint256 dividend, uint256 divisor) internal pure returns (uint256) {
        require(divisor != 0, "ERR_DIV_ZERO");

        // Gas optimization
        if (dividend == 0) {
            return 0;
        }

        uint256 c0 = dividend * BalancerConstants.BONE;
        require(c0 / dividend == BalancerConstants.BONE, "ERR_DIV_INTERNAL"); // bmul overflow

        uint256 c1 = c0 + (divisor / 2);
        require(c1 >= c0, "ERR_DIV_INTERNAL"); //  badd require

        uint256 c2 = c1 / divisor;
        return c2;
    }

    /**
     * @notice Safe unsigned integer modulo
     * @dev Returns the remainder of dividing two unsigned integers.
     *      Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * @param dividend - first operand
     * @param divisor - second operand -- cannot be zero
     * @return - quotient; throws if overflow or rounding error
     */
    function bmod(uint256 dividend, uint256 divisor) internal pure returns (uint256) {
        require(divisor != 0, "ERR_MODULO_BY_ZERO");

        return dividend % divisor;
    }

    /**
     * @notice Safe unsigned integer max
     * @dev Returns the greater of the two input values
     *
     * @param a - first operand
     * @param b - second operand
     * @return - the maximum of a and b
     */
    function bmax(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @notice Safe unsigned integer min
     * @dev returns b, if b < a; otherwise returns a
     *
     * @param a - first operand
     * @param b - second operand
     * @return - the lesser of the two input values
     */
    function bmin(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @notice Safe unsigned integer average
     * @dev Guard against (a+b) overflow by dividing each operand separately
     *
     * @param a - first operand
     * @param b - second operand
     * @return - the average of the two values
     */
    function baverage(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + (((a % 2) + (b % 2)) / 2);
    }

    /**
     * @notice Babylonian square root implementation
     * @dev (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
     * @param y - operand
     * @return z - the square root result
     */
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

/**
 * @author Balancer Labs
 * @title Manage Configurable Rights for the smart pool
 *      canPauseSwapping - can setPublicSwap back to false after turning it on
 *                         by default, it is off on initialization and can only be turned on
 *      canChangeSwapFee - can setSwapFee after initialization (by default, it is fixed at create time)
 *      canChangeWeights - can bind new token weights (allowed by default in base pool)
 *      canAddRemoveTokens - can bind/unbind tokens (allowed by default in base pool)
 *      canWhitelistLPs - can limit liquidity providers to a given set of addresses
 *      canChangeCap - can change the BSP cap (max # of pool tokens)
 */
library RightsManager {
    // Type declarations

    enum Permissions {
        PAUSE_SWAPPING,
        CHANGE_SWAP_FEE,
        CHANGE_WEIGHTS,
        ADD_REMOVE_TOKENS,
        WHITELIST_LPS,
        CHANGE_CAP
    }

    struct Rights {
        bool canPauseSwapping;
        bool canChangeSwapFee;
        bool canChangeWeights;
        bool canAddRemoveTokens;
        bool canWhitelistLPs;
        bool canChangeCap;
    }

    // State variables (can only be constants in a library)
    bool public constant DEFAULT_CAN_PAUSE_SWAPPING = false;
    bool public constant DEFAULT_CAN_CHANGE_SWAP_FEE = true;
    bool public constant DEFAULT_CAN_CHANGE_WEIGHTS = true;
    bool public constant DEFAULT_CAN_ADD_REMOVE_TOKENS = false;
    bool public constant DEFAULT_CAN_WHITELIST_LPS = false;
    bool public constant DEFAULT_CAN_CHANGE_CAP = false;

    // Functions

    /**
     * @notice create a struct from an array (or return defaults)
     * @dev If you pass an empty array, it will construct it using the defaults
     * @param a - array input
     * @return Rights struct
     */
    function constructRights(bool[] calldata a) external pure returns (Rights memory) {
        if (a.length == 0) {
            return
                Rights(
                    DEFAULT_CAN_PAUSE_SWAPPING,
                    DEFAULT_CAN_CHANGE_SWAP_FEE,
                    DEFAULT_CAN_CHANGE_WEIGHTS,
                    DEFAULT_CAN_ADD_REMOVE_TOKENS,
                    DEFAULT_CAN_WHITELIST_LPS,
                    DEFAULT_CAN_CHANGE_CAP
                );
        } else {
            return Rights(a[0], a[1], a[2], a[3], a[4], a[5]);
        }
    }

    /**
     * @notice Convert rights struct to an array (e.g., for events, GUI)
     * @dev avoids multiple calls to hasPermission
     * @param rights - the rights struct to convert
     * @return boolean array containing the rights settings
     */
    function convertRights(Rights calldata rights) external pure returns (bool[] memory) {
        bool[] memory result = new bool[](6);

        result[0] = rights.canPauseSwapping;
        result[1] = rights.canChangeSwapFee;
        result[2] = rights.canChangeWeights;
        result[3] = rights.canAddRemoveTokens;
        result[4] = rights.canWhitelistLPs;
        result[5] = rights.canChangeCap;

        return result;
    }

    // Though it is actually simple, the number of branches triggers code-complexity
    /* solhint-disable code-complexity */

    /**
     * @notice Externally check permissions using the Enum
     * @param self - Rights struct containing the permissions
     * @param permission - The permission to check
     * @return Boolean true if it has the permission
     */
    function hasPermission(Rights calldata self, Permissions permission) external pure returns (bool) {
        if (Permissions.PAUSE_SWAPPING == permission) {
            return self.canPauseSwapping;
        } else if (Permissions.CHANGE_SWAP_FEE == permission) {
            return self.canChangeSwapFee;
        } else if (Permissions.CHANGE_WEIGHTS == permission) {
            return self.canChangeWeights;
        } else if (Permissions.ADD_REMOVE_TOKENS == permission) {
            return self.canAddRemoveTokens;
        } else if (Permissions.WHITELIST_LPS == permission) {
            return self.canWhitelistLPs;
        } else if (Permissions.CHANGE_CAP == permission) {
            return self.canChangeCap;
        }

        require(false, "PERMISSION_UNKNOWN");

        // At this point we should have reverted already
        return false;
    }

    /* solhint-enable code-complexity */
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

// Imports

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// Libraries

/**
 * @author PieDAO (ported to Balancer Labs)
 * @title SafeApprove - set approval for tokens that require 0 prior approval
 * @dev Perhaps to address the known ERC20 race condition issue
 *      See https://github.com/crytic/not-so-smart-contracts/tree/master/race_condition
 *      Some tokens - notably KNC - only allow approvals to be increased from 0
 */
library SafeApprove {
    /**
     * @notice handle approvals of tokens that require approving from a base of 0
     * @param token - the token we're approving
     * @param spender - entity the owner (sender) is approving to spend his tokens
     * @param amount - number of tokens being approved
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 amount
    ) internal returns (bool) {
        uint256 currentAllowance = token.allowance(address(this), spender);

        // Do nothing if allowance is already set to this value
        if (currentAllowance == amount) {
            return true;
        }

        // If approval is not zero reset it to zero first
        if (currentAllowance != 0) {
            return token.approve(spender, 0);
        }

        // do the actual approval
        return token.approve(spender, amount);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

// Imports
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../../interfaces/IBPool.sol";

import "../interfaces/IConfigurableRightsPool.sol";

import "./BalancerSafeMath.sol";
import "./SafeApprove.sol";

/**
 * @author Balancer Labs
 * @title Factor out the weight updates
 */
library SmartPoolManager {
    // Type declarations

    struct NewTokenParams {
        address addr;
        bool isCommitted;
        uint256 commitBlock;
        uint256 denorm;
        uint256 balance;
    }

    // For blockwise, automated weight updates
    // Move weights linearly from startWeights to endWeights,
    // between startBlock and endBlock
    struct GradualUpdateParams {
        uint256 startBlock;
        uint256 endBlock;
        uint256[] startWeights;
        uint256[] endWeights;
    }

    // updateWeight and pokeWeights are unavoidably long
    /* solhint-disable function-max-lines */

    /**
     * @notice Computes the cost of updating a token to a certain weight.
     * If increasing the weight, it will be a token cost.
     * If decreasing the weight, it will be a pool shares (LPT) cost.
     * @param self - CRPool instance calling the library
     * @param bPool - Core BPool the CRP is wrapping
     * @param token - token to be reweighted
     * @param newWeight - new weight of the token
     */
    function getUpdateWeightCost(
        IConfigurableRightsPool self,
        IBPool bPool,
        address token,
        uint256 newWeight
    ) public view returns (uint256) {
        uint256 currentWeight = bPool.getDenormalizedWeight(token);

        if (currentWeight == newWeight) {
            return 0;
        }

        if (newWeight < currentWeight) {
            uint256 deltaWeight = BalancerSafeMath.bsub(currentWeight, newWeight);

            uint256 totalSupply = self.totalSupply();
            uint256 totalWeight = bPool.getTotalDenormalizedWeight();

            // poolShares = totalSupply * (deltaWeight / totalWeight)
            return BalancerSafeMath.bmul(totalSupply, BalancerSafeMath.bdiv(deltaWeight, totalWeight));
        } else {
            uint256 deltaWeight = BalancerSafeMath.bsub(newWeight, currentWeight);

            uint256 currentBalance = bPool.getBalance(token);

            // deltaBalance = currentBalance * (deltaWeight / currentWeight)
            return BalancerSafeMath.bmul(currentBalance, BalancerSafeMath.bdiv(deltaWeight, currentWeight));
        }
    }

    /**
     * @notice Computes the earning from updating a token to a certain weight.
     * If increasing the weight, it will be a pool shares (LPT) earning.
     * If decreasing the weight, it will be a token earning.
     * @param self - CRPool instance calling the library
     * @param bPool - Core BPool the CRP is wrapping
     * @param token - token to be reweighted
     * @param newWeight - new weight of the token
     */
    function getUpdateWeightEarnings(
        IConfigurableRightsPool self,
        IBPool bPool,
        address token,
        uint256 newWeight
    ) public view returns (uint256) {
        uint256 currentWeight = bPool.getDenormalizedWeight(token);

        if (currentWeight == newWeight) {
            return 0;
        }

        if (newWeight < currentWeight) {
            uint256 deltaWeight = BalancerSafeMath.bsub(currentWeight, newWeight);

            uint256 currentBalance = bPool.getBalance(token);

            // deltaBalance = currentBalance * (deltaWeight / currentWeight)
            return BalancerSafeMath.bmul(currentBalance, BalancerSafeMath.bdiv(deltaWeight, currentWeight));
        } else {
            uint256 deltaWeight = BalancerSafeMath.bsub(newWeight, currentWeight);

            uint256 totalSupply = self.totalSupply();
            uint256 totalWeight = bPool.getTotalDenormalizedWeight();

            // poolShares = totalSupply * (deltaWeight / totalWeight)
            return BalancerSafeMath.bmul(totalSupply, BalancerSafeMath.bdiv(deltaWeight, totalWeight));
        }
    }

    /**
     * @notice Update the weight of an existing token
     * @dev Refactored to library to make CRPFactory deployable
     * @param self - CRPool instance calling the library
     * @param bPool - Core BPool the CRP is wrapping
     * @param token - token to be reweighted
     * @param newWeight - new weight of the token
     */
    function updateWeight(
        IConfigurableRightsPool self,
        IBPool bPool,
        address token,
        uint256 newWeight
    ) external {
        require(newWeight >= BalancerConstants.MIN_WEIGHT, "ERR_MIN_WEIGHT");
        require(newWeight <= BalancerConstants.MAX_WEIGHT, "ERR_MAX_WEIGHT");

        uint256 currentWeight = bPool.getDenormalizedWeight(token);
        // Save gas; return immediately on NOOP
        if (currentWeight == newWeight) {
            return;
        }

        uint256 currentBalance = bPool.getBalance(token);
        uint256 totalWeight = bPool.getTotalDenormalizedWeight();

        if (newWeight < currentWeight) {
            // This means the controller will withdraw tokens to keep price
            // So they need to redeem PCTokens
            uint256 deltaWeight = BalancerSafeMath.bsub(currentWeight, newWeight);

            uint256 deltaBalance = BalancerSafeMath.bmul(
                currentBalance,
                BalancerSafeMath.bdiv(deltaWeight, currentWeight)
            );

            // New balance cannot be lower than MIN_BALANCE
            uint256 newBalance = BalancerSafeMath.bsub(currentBalance, deltaBalance);

            require(newBalance >= BalancerConstants.MIN_BALANCE, "ERR_MIN_BALANCE");

            uint256 poolSharesCost = getUpdateWeightCost(self, bPool, token, newWeight);
            uint256 tokenEarnings = getUpdateWeightEarnings(self, bPool, token, newWeight);

            // First get the tokens from this contract (Pool Controller) to msg.sender
            bPool.rebind(token, newBalance, newWeight);

            // Now with the tokens this contract can send them to msg.sender

            bool xfer = IERC20(token).transfer(msg.sender, tokenEarnings);
            require(xfer, "ERR_ERC20_FALSE");

            self.pullPoolShareFromLib(msg.sender, poolSharesCost);
            self.burnPoolShareFromLib(poolSharesCost);
        } else {
            // This means the controller will deposit tokens to keep the price.
            // They will be minted and given PCTokens
            uint256 deltaWeight = BalancerSafeMath.bsub(newWeight, currentWeight);

            require(
                BalancerSafeMath.badd(totalWeight, deltaWeight) <= BalancerConstants.MAX_TOTAL_WEIGHT,
                "ERR_MAX_TOTAL_WEIGHT"
            );

            uint256 tokenCost = getUpdateWeightCost(self, bPool, token, newWeight);
            uint256 poolSharesEarnings = getUpdateWeightEarnings(self, bPool, token, newWeight);
            // First gets the tokens from msg.sender to this contract (Pool Controller)
            bool xfer = IERC20(token).transferFrom(msg.sender, address(this), tokenCost);
            require(xfer, "ERR_ERC20_FALSE");

            // Now with the tokens this contract can bind them to the pool it controls
            bPool.rebind(token, BalancerSafeMath.badd(currentBalance, tokenCost), newWeight);

            self.mintPoolShareFromLib(poolSharesEarnings);
            self.pushPoolShareFromLib(msg.sender, poolSharesEarnings);
        }
    }

    /**
     * @notice External function called to make the contract update weights according to plan
     * @param bPool - Core BPool the CRP is wrapping
     * @param gradualUpdate - gradual update parameters from the CRP
     */
    function pokeWeights(IBPool bPool, GradualUpdateParams storage gradualUpdate) external returns (bool isFinished) {
        // Do nothing if we call this when there is no update plan
        if (gradualUpdate.startBlock == 0) {
            return false;
        }

        // Error to call it before the start of the plan
        require(block.number >= gradualUpdate.startBlock, "ERR_CANT_POKE_YET");
        // Proposed error message improvement
        // require(block.number >= startBlock, "ERR_NO_HOKEY_POKEY");

        // This allows for pokes after endBlock that get weights to endWeights
        // Get the current block (or the endBlock, if we're already past the end)
        uint256 currentBlock;
        if (block.number > gradualUpdate.endBlock) {
            currentBlock = gradualUpdate.endBlock;
        } else {
            currentBlock = block.number;
        }

        uint256 blockPeriod = BalancerSafeMath.bsub(gradualUpdate.endBlock, gradualUpdate.startBlock);
        uint256 blocksElapsed = BalancerSafeMath.bsub(currentBlock, gradualUpdate.startBlock);
        uint256 weightDelta;
        uint256 deltaPerBlock;
        uint256 newWeight;

        address[] memory tokens = bPool.getCurrentTokens();

        // This loop contains external calls
        // External calls are to math libraries or the underlying pool, so low risk
        for (uint256 i = 0; i < tokens.length; i++) {
            // Make sure it does nothing if the new and old weights are the same (saves gas)
            // It's a degenerate case if they're *all* the same, but you certainly could have
            // a plan where you only change some of the weights in the set
            if (gradualUpdate.startWeights[i] != gradualUpdate.endWeights[i]) {
                if (gradualUpdate.endWeights[i] < gradualUpdate.startWeights[i]) {
                    // We are decreasing the weight

                    // First get the total weight delta
                    weightDelta = BalancerSafeMath.bsub(gradualUpdate.startWeights[i], gradualUpdate.endWeights[i]);
                    // And the amount it should change per block = total change/number of blocks in the period
                    deltaPerBlock = BalancerSafeMath.bdiv(weightDelta, blockPeriod);
                    //deltaPerBlock = bdivx(weightDelta, blockPeriod);

                    // newWeight = startWeight - (blocksElapsed * deltaPerBlock)
                    newWeight = BalancerSafeMath.bsub(
                        gradualUpdate.startWeights[i],
                        BalancerSafeMath.bmul(blocksElapsed, deltaPerBlock)
                    );
                } else {
                    // We are increasing the weight

                    // First get the total weight delta
                    weightDelta = BalancerSafeMath.bsub(gradualUpdate.endWeights[i], gradualUpdate.startWeights[i]);
                    // And the amount it should change per block = total change/number of blocks in the period
                    deltaPerBlock = BalancerSafeMath.bdiv(weightDelta, blockPeriod);
                    //deltaPerBlock = bdivx(weightDelta, blockPeriod);

                    // newWeight = startWeight + (blocksElapsed * deltaPerBlock)
                    newWeight = BalancerSafeMath.badd(
                        gradualUpdate.startWeights[i],
                        BalancerSafeMath.bmul(blocksElapsed, deltaPerBlock)
                    );
                }

                uint256 bal = bPool.getBalance(tokens[i]);

                bPool.rebind(tokens[i], bal, newWeight);
            }
        }

        // Reset to allow add/remove tokens, or manual weight updates
        if (block.number >= gradualUpdate.endBlock) {
            gradualUpdate.startBlock = 0;
            return true;
        }

        return false;
    }

    /* solhint-enable function-max-lines */

    /**
     * @notice Schedule (commit) a token to be added; must call applyAddToken after a fixed
     *         number of blocks to actually add the token
     * @param bPool - Core BPool the CRP is wrapping
     * @param token - the token to be added
     * @param balance - how much to be added
     * @param denormalizedWeight - the desired token weight
     * @param newToken - NewTokenParams struct used to hold the token data (in CRP storage)
     */
    function commitAddToken(
        IBPool bPool,
        address token,
        uint256 balance,
        uint256 denormalizedWeight,
        NewTokenParams storage newToken
    ) external {
        require(!bPool.isBound(token), "ERR_IS_BOUND");

        require(denormalizedWeight <= BalancerConstants.MAX_WEIGHT, "ERR_WEIGHT_ABOVE_MAX");
        require(denormalizedWeight >= BalancerConstants.MIN_WEIGHT, "ERR_WEIGHT_BELOW_MIN");
        require(
            BalancerSafeMath.badd(bPool.getTotalDenormalizedWeight(), denormalizedWeight) <=
                BalancerConstants.MAX_TOTAL_WEIGHT,
            "ERR_MAX_TOTAL_WEIGHT"
        );
        require(balance >= BalancerConstants.MIN_BALANCE, "ERR_BALANCE_BELOW_MIN");

        newToken.addr = token;
        newToken.balance = balance;
        newToken.denorm = denormalizedWeight;
        newToken.commitBlock = block.number;
        newToken.isCommitted = true;
    }

    /**
     * @notice Add the token previously committed (in commitAddToken) to the pool
     * @param self - CRPool instance calling the library
     * @param bPool - Core BPool the CRP is wrapping
     * @param addTokenTimeLockInBlocks -  Wait time between committing and applying a new token
     * @param newToken - NewTokenParams struct used to hold the token data (in CRP storage)
     */
    function applyAddToken(
        IConfigurableRightsPool self,
        IBPool bPool,
        uint256 addTokenTimeLockInBlocks,
        NewTokenParams storage newToken
    ) external {
        require(newToken.isCommitted, "ERR_NO_TOKEN_COMMIT");
        require(
            BalancerSafeMath.bsub(block.number, newToken.commitBlock) >= addTokenTimeLockInBlocks,
            "ERR_TIMELOCK_STILL_COUNTING"
        );

        uint256 totalSupply = self.totalSupply();

        // poolShares = totalSupply * newTokenWeight / totalWeight
        uint256 poolShares = BalancerSafeMath.bdiv(
            BalancerSafeMath.bmul(totalSupply, newToken.denorm),
            bPool.getTotalDenormalizedWeight()
        );

        // Clear this to allow adding more tokens
        newToken.isCommitted = false;

        // First gets the tokens from msg.sender to this contract (Pool Controller)
        bool returnValue = IERC20(newToken.addr).transferFrom(msg.sender, address(self), newToken.balance);
        require(returnValue, "ERR_ERC20_FALSE");

        // Now with the tokens this contract can bind them to the pool it controls
        // Approves bPool to pull from this controller
        // Approve unlimited, same as when creating the pool, so they can join pools later
        returnValue = SafeApprove.safeApprove(IERC20(newToken.addr), address(bPool), BalancerConstants.MAX_UINT);
        require(returnValue, "ERR_ERC20_FALSE");

        bPool.bind(newToken.addr, newToken.balance, newToken.denorm);

        self.mintPoolShareFromLib(poolShares);
        self.pushPoolShareFromLib(msg.sender, poolShares);
    }

    /**
     * @notice Computes the cost of remove a token from the pool
     * @param self - CRPool instance calling the library
     * @param bPool - Core BPool the CRP is wrapping
     * @param token - token to be removed
     */
    function getRemoveTokenCost(
        IConfigurableRightsPool self,
        IBPool bPool,
        address token
    ) public view returns (uint256) {
        uint256 totalSupply = self.totalSupply();

        return
            BalancerSafeMath.bdiv(
                BalancerSafeMath.bmul(totalSupply, bPool.getDenormalizedWeight(token)),
                bPool.getTotalDenormalizedWeight()
            );
    }

    /**
     * @notice Computes the earnings from removing a token from the pool
     * @param - CRPool instance calling the library
     * @param bPool - Core BPool the CRP is wrapping
     * @param token - token to be removed
     */
    function getRemoveTokenEarnings(
        IConfigurableRightsPool,
        IBPool bPool,
        address token
    ) public view returns (uint256) {
        return bPool.getBalance(token);
    }

    /**
     * @notice Remove a token from the pool
     * @dev Logic in the CRP controls when ths can be called. There are two related permissions:
     *      AddRemoveTokens - which allows removing down to the underlying BPool limit of two
     *      RemoveAllTokens - which allows completely draining the pool by removing all tokens
     *                        This can result in a non-viable pool with 0 or 1 tokens (by design),
     *                        meaning all swapping or binding operations would fail in this state
     * @param self - CRPool instance calling the library
     * @param bPool - Core BPool the CRP is wrapping
     * @param token - token to remove
     */
    function removeToken(
        IConfigurableRightsPool self,
        IBPool bPool,
        address token
    ) external {
        uint256 poolSharesCost = getRemoveTokenCost(self, bPool, token);
        uint256 tokenEarnings = getRemoveTokenEarnings(self, bPool, token);

        // Unbind and get the tokens out of balancer pool
        bPool.unbind(token);

        // Now with the tokens this contract can send them to msg.sender
        bool xfer = IERC20(token).transfer(msg.sender, tokenEarnings);
        require(xfer, "ERR_ERC20_FALSE");

        self.pullPoolShareFromLib(msg.sender, poolSharesCost);
        self.burnPoolShareFromLib(poolSharesCost);
    }

    /**
     * @notice Non ERC20-conforming tokens are problematic; don't allow them in pools
     * @dev Will revert if invalid
     * @param token - The prospective token to verify
     */
    function verifyTokenCompliance(address token) external {
        verifyTokenComplianceInternal(token);
    }

    /**
     * @notice Non ERC20-conforming tokens are problematic; don't allow them in pools
     * @dev Will revert if invalid - overloaded to save space in the main contract
     * @param tokens - The prospective tokens to verify
     */
    function verifyTokenCompliance(address[] calldata tokens) external {
        for (uint256 i = 0; i < tokens.length; i++) {
            verifyTokenComplianceInternal(tokens[i]);
        }
    }

    /**
     * @notice Update weights in a predetermined way, between startBlock and endBlock,
     *         through external cals to pokeWeights
     * @param bPool - Core BPool the CRP is wrapping
     * @param newWeights - final weights we want to get to
     * @param startBlock - when weights should start to change
     * @param endBlock - when weights will be at their final values
     * @param minimumWeightChangeBlockPeriod - needed to validate the block period
     */
    function updateWeightsGradually(
        IBPool bPool,
        GradualUpdateParams storage gradualUpdate,
        uint256[] calldata newWeights,
        uint256 startBlock,
        uint256 endBlock,
        uint256 minimumWeightChangeBlockPeriod
    ) external {
        require(block.number < endBlock, "ERR_GRADUAL_UPDATE_TIME_TRAVEL");

        if (block.number > startBlock) {
            // This means the weight update should start ASAP
            // Moving the start block up prevents a big jump/discontinuity in the weights
            gradualUpdate.startBlock = block.number;
        } else {
            gradualUpdate.startBlock = startBlock;
        }

        // Enforce a minimum time over which to make the changes
        // The also prevents endBlock <= startBlock
        require(
            BalancerSafeMath.bsub(endBlock, gradualUpdate.startBlock) >= minimumWeightChangeBlockPeriod,
            "ERR_WEIGHT_CHANGE_TIME_BELOW_MIN"
        );

        address[] memory tokens = bPool.getCurrentTokens();

        // Must specify weights for all tokens
        require(newWeights.length == tokens.length, "ERR_START_WEIGHTS_MISMATCH");

        uint256 weightsSum = 0;
        gradualUpdate.startWeights = new uint256[](tokens.length);

        // Check that endWeights are valid now to avoid reverting in a future pokeWeights call
        //
        // This loop contains external calls
        // External calls are to math libraries or the underlying pool, so low risk
        for (uint256 i = 0; i < tokens.length; i++) {
            require(newWeights[i] <= BalancerConstants.MAX_WEIGHT, "ERR_WEIGHT_ABOVE_MAX");
            require(newWeights[i] >= BalancerConstants.MIN_WEIGHT, "ERR_WEIGHT_BELOW_MIN");

            weightsSum = BalancerSafeMath.badd(weightsSum, newWeights[i]);
            gradualUpdate.startWeights[i] = bPool.getDenormalizedWeight(tokens[i]);
        }
        require(weightsSum <= BalancerConstants.MAX_TOTAL_WEIGHT, "ERR_MAX_TOTAL_WEIGHT");

        gradualUpdate.endBlock = endBlock;
        gradualUpdate.endWeights = newWeights;
    }

    /**
     * @notice Join a pool
     * @param self - CRPool instance calling the library
     * @param bPool - Core BPool the CRP is wrapping
     * @param poolAmountOut - number of pool tokens to receive
     * @param maxAmountsIn - Max amount of asset tokens to spend
     * @return actualAmountsIn - calculated values of the tokens to pull in
     */
    function joinPool(
        IConfigurableRightsPool self,
        IBPool bPool,
        uint256 poolAmountOut,
        uint256[] calldata maxAmountsIn
    ) external view returns (uint256[] memory actualAmountsIn) {
        address[] memory tokens = bPool.getCurrentTokens();

        require(maxAmountsIn.length == tokens.length, "ERR_AMOUNTS_MISMATCH");

        uint256 poolTotal = self.totalSupply();
        // Subtract  1 to ensure any rounding errors favor the pool
        uint256 ratio = BalancerSafeMath.bdiv(poolAmountOut, BalancerSafeMath.bsub(poolTotal, 1));

        require(ratio != 0, "ERR_MATH_APPROX");

        // We know the length of the array; initialize it, and fill it below
        // Cannot do "push" in memory
        actualAmountsIn = new uint256[](tokens.length);

        // This loop contains external calls
        // External calls are to math libraries or the underlying pool, so low risk
        for (uint256 i = 0; i < tokens.length; i++) {
            address t = tokens[i];
            uint256 bal = bPool.getBalance(t);
            // Add 1 to ensure any rounding errors favor the pool
            uint256 tokenAmountIn = BalancerSafeMath.bmul(ratio, BalancerSafeMath.badd(bal, 1));

            require(tokenAmountIn != 0, "ERR_MATH_APPROX");
            require(tokenAmountIn <= maxAmountsIn[i], "ERR_LIMIT_IN");

            actualAmountsIn[i] = tokenAmountIn;
        }
    }

    /**
     * @notice Exit a pool - redeem pool tokens for underlying assets
     * @param self - CRPool instance calling the library
     * @param bPool - Core BPool the CRP is wrapping
     * @param poolAmountIn - amount of pool tokens to redeem
     * @param minAmountsOut - minimum amount of asset tokens to receive
     * @return exitFee - calculated exit fee
     * @return pAiAfterExitFee - final amount in (after accounting for exit fee)
     * @return actualAmountsOut - calculated amounts of each token to pull
     */
    function exitPool(
        IConfigurableRightsPool self,
        IBPool bPool,
        uint256 poolAmountIn,
        uint256[] calldata minAmountsOut
    )
        external
        view
        returns (
            uint256 exitFee,
            uint256 pAiAfterExitFee,
            uint256[] memory actualAmountsOut
        )
    {
        address[] memory tokens = bPool.getCurrentTokens();

        require(minAmountsOut.length == tokens.length, "ERR_AMOUNTS_MISMATCH");

        uint256 poolTotal = self.totalSupply();

        // Calculate exit fee and the final amount in
        exitFee = BalancerSafeMath.bmul(poolAmountIn, BalancerConstants.EXIT_FEE);
        pAiAfterExitFee = BalancerSafeMath.bsub(poolAmountIn, exitFee);

        uint256 ratio = BalancerSafeMath.bdiv(pAiAfterExitFee, BalancerSafeMath.badd(poolTotal, 1));

        require(ratio != 0, "ERR_MATH_APPROX");

        actualAmountsOut = new uint256[](tokens.length);

        // This loop contains external calls
        // External calls are to math libraries or the underlying pool, so low risk
        for (uint256 i = 0; i < tokens.length; i++) {
            address t = tokens[i];
            uint256 bal = bPool.getBalance(t);
            // Subtract 1 to ensure any rounding errors favor the pool
            uint256 tokenAmountOut = BalancerSafeMath.bmul(ratio, BalancerSafeMath.bsub(bal, 1));

            require(tokenAmountOut != 0, "ERR_MATH_APPROX");
            require(tokenAmountOut >= minAmountsOut[i], "ERR_LIMIT_OUT");

            actualAmountsOut[i] = tokenAmountOut;
        }
    }

    /**
     * @notice Join by swapping a fixed amount of an external token in (must be present in the pool)
     *         System calculates the pool token amount
     * @param self - CRPool instance calling the library
     * @param bPool - Core BPool the CRP is wrapping
     * @param tokenIn - which token we're transferring in
     * @param tokenAmountIn - amount of deposit
     * @param minPoolAmountOut - minimum of pool tokens to receive
     * @return poolAmountOut - amount of pool tokens minted and transferred
     */
    function joinswapExternAmountIn(
        IConfigurableRightsPool self,
        IBPool bPool,
        address tokenIn,
        uint256 tokenAmountIn,
        uint256 minPoolAmountOut
    ) external view returns (uint256 poolAmountOut) {
        require(bPool.isBound(tokenIn), "ERR_NOT_BOUND");
        require(
            tokenAmountIn <= BalancerSafeMath.bmul(bPool.getBalance(tokenIn), BalancerConstants.MAX_IN_RATIO),
            "ERR_MAX_IN_RATIO"
        );

        poolAmountOut = bPool.calcPoolOutGivenSingleIn(
            bPool.getBalance(tokenIn),
            bPool.getDenormalizedWeight(tokenIn),
            self.totalSupply(),
            bPool.getTotalDenormalizedWeight(),
            tokenAmountIn,
            bPool.getSwapFee()
        );

        require(poolAmountOut >= minPoolAmountOut, "ERR_LIMIT_OUT");
    }

    /**
     * @notice Join by swapping an external token in (must be present in the pool)
     *         To receive an exact amount of pool tokens out. System calculates the deposit amount
     * @param self - CRPool instance calling the library
     * @param bPool - Core BPool the CRP is wrapping
     * @param tokenIn - which token we're transferring in (system calculates amount required)
     * @param poolAmountOut - amount of pool tokens to be received
     * @param maxAmountIn - Maximum asset tokens that can be pulled to pay for the pool tokens
     * @return tokenAmountIn - amount of asset tokens transferred in to purchase the pool tokens
     */
    function joinswapPoolAmountOut(
        IConfigurableRightsPool self,
        IBPool bPool,
        address tokenIn,
        uint256 poolAmountOut,
        uint256 maxAmountIn
    ) external view returns (uint256 tokenAmountIn) {
        require(bPool.isBound(tokenIn), "ERR_NOT_BOUND");

        tokenAmountIn = bPool.calcSingleInGivenPoolOut(
            bPool.getBalance(tokenIn),
            bPool.getDenormalizedWeight(tokenIn),
            self.totalSupply(),
            bPool.getTotalDenormalizedWeight(),
            poolAmountOut,
            bPool.getSwapFee()
        );

        require(tokenAmountIn != 0, "ERR_MATH_APPROX");
        require(tokenAmountIn <= maxAmountIn, "ERR_LIMIT_IN");

        require(
            tokenAmountIn <= BalancerSafeMath.bmul(bPool.getBalance(tokenIn), BalancerConstants.MAX_IN_RATIO),
            "ERR_MAX_IN_RATIO"
        );
    }

    /**
     * @notice Exit a pool - redeem a specific number of pool tokens for an underlying asset
     *         Asset must be present in the pool, and will incur an EXIT_FEE (if set to non-zero)
     * @param self - CRPool instance calling the library
     * @param bPool - Core BPool the CRP is wrapping
     * @param tokenOut - which token the caller wants to receive
     * @param poolAmountIn - amount of pool tokens to redeem
     * @param minAmountOut - minimum asset tokens to receive
     * @return exitFee - calculated exit fee
     * @return tokenAmountOut - amount of asset tokens returned
     */
    function exitswapPoolAmountIn(
        IConfigurableRightsPool self,
        IBPool bPool,
        address tokenOut,
        uint256 poolAmountIn,
        uint256 minAmountOut
    ) external view returns (uint256 exitFee, uint256 tokenAmountOut) {
        require(bPool.isBound(tokenOut), "ERR_NOT_BOUND");

        tokenAmountOut = bPool.calcSingleOutGivenPoolIn(
            bPool.getBalance(tokenOut),
            bPool.getDenormalizedWeight(tokenOut),
            self.totalSupply(),
            bPool.getTotalDenormalizedWeight(),
            poolAmountIn,
            bPool.getSwapFee()
        );

        require(tokenAmountOut >= minAmountOut, "ERR_LIMIT_OUT");
        require(
            tokenAmountOut <= BalancerSafeMath.bmul(bPool.getBalance(tokenOut), BalancerConstants.MAX_OUT_RATIO),
            "ERR_MAX_OUT_RATIO"
        );

        exitFee = BalancerSafeMath.bmul(poolAmountIn, BalancerConstants.EXIT_FEE);
    }

    /**
     * @notice Exit a pool - redeem pool tokens for a specific amount of underlying assets
     *         Asset must be present in the pool
     * @param self - CRPool instance calling the library
     * @param bPool - Core BPool the CRP is wrapping
     * @param tokenOut - which token the caller wants to receive
     * @param tokenAmountOut - amount of underlying asset tokens to receive
     * @param maxPoolAmountIn - maximum pool tokens to be redeemed
     * @return exitFee - calculated exit fee
     * @return poolAmountIn - amount of pool tokens redeemed
     */
    function exitswapExternAmountOut(
        IConfigurableRightsPool self,
        IBPool bPool,
        address tokenOut,
        uint256 tokenAmountOut,
        uint256 maxPoolAmountIn
    ) external view returns (uint256 exitFee, uint256 poolAmountIn) {
        require(bPool.isBound(tokenOut), "ERR_NOT_BOUND");
        require(
            tokenAmountOut <= BalancerSafeMath.bmul(bPool.getBalance(tokenOut), BalancerConstants.MAX_OUT_RATIO),
            "ERR_MAX_OUT_RATIO"
        );
        poolAmountIn = bPool.calcPoolInGivenSingleOut(
            bPool.getBalance(tokenOut),
            bPool.getDenormalizedWeight(tokenOut),
            self.totalSupply(),
            bPool.getTotalDenormalizedWeight(),
            tokenAmountOut,
            bPool.getSwapFee()
        );

        require(poolAmountIn != 0, "ERR_MATH_APPROX");
        require(poolAmountIn <= maxPoolAmountIn, "ERR_LIMIT_IN");

        exitFee = BalancerSafeMath.bmul(poolAmountIn, BalancerConstants.EXIT_FEE);
    }

    // Internal functions

    // Check for zero transfer, and make sure it returns true to returnValue
    function verifyTokenComplianceInternal(address token) internal {
        bool returnValue = IERC20(token).transfer(msg.sender, 0);
        require(returnValue, "ERR_NONCONFORMING_TOKEN");
    }
}