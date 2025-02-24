/**
 *Submitted for verification at polygonscan.com on 2022-12-05
*/

/** 
 *  SourceUnit: /Users/michaels/BlockPlot/contracts/BlockPlot/BlockPlotERC1155.sol
*/
//SPDX-License-Identifier: MIT      

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




/** 
 *  SourceUnit: /Users/michaels/BlockPlot/contracts/BlockPlot/BlockPlotERC1155.sol
*/
            

// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

////import "../utils/Context.sol";

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




/** 
 *  SourceUnit: /Users/michaels/BlockPlot/contracts/BlockPlot/BlockPlotERC1155.sol
*/
            

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




/** 
 *  SourceUnit: /Users/michaels/BlockPlot/contracts/BlockPlot/BlockPlotERC1155.sol
*/
            

// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

////import "../../utils/introspection/IERC165.sol";

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
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

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
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

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




/** 
 *  SourceUnit: /Users/michaels/BlockPlot/contracts/BlockPlot/BlockPlotERC1155.sol
*/
            

// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

////import "./IERC165.sol";

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




/** 
 *  SourceUnit: /Users/michaels/BlockPlot/contracts/BlockPlot/BlockPlotERC1155.sol
*/
            


pragma solidity ^0.8.7;

/// @author Michael Amadi
/// @title BlockPlot Identity Contract

////import "@openzeppelin/contracts/access/Ownable.sol";

contract Identity is Ownable {
    // Id counter, starts from 1 so that 0 can be the default value for any unmapped address. Similar to address(0)
    uint256 internal currentId = 1;

    struct reAssignWaitlistInfo {
        address oldAddress;
        uint256 timeOutEnd;
    }

    // mapping that returns the User Id of any address, returns 0 if not currently mapped yet.
    mapping(address => uint256) internal _resolveId;

    // mapping that returns the address that owns a user Id, returns adress(0) if not currently mapped. This doesn't necessarily serve any function except
    // for on chain verification by other contracts and off chain accesibility
    mapping(uint256 => address) internal _resolveAddress;

    // mapping that resolves if an address has been linked anytime in the past even if its access is currently revoked.
    mapping(address => bool) internal _isUsedAddress;

    // mapping that resolves if a user id has been revoked and is yet to be reAssigned, returns address(0) if false and the address it was revoked from if true.
    // once an address is mapped here it can't be unmapped.
    mapping(uint256 => reAssignWaitlistInfo) internal _reAssignWaitlist;

    event Verified(address indexed userAddress, uint256 indexed userId);

    event Revoked(address indexed userAddress, uint256 indexed userId);

    event ReAssigned(address indexed userAddress, uint256 indexed userId);

    /// @notice lets owner verify an address @param user and maps it to an ID.
    /// @param user: address of new user to be mapped
    /// @notice cannot map: a previously verified address (whether currently mapped or revoked)
    function verify(address user) public onlyOwner {
        require(user != address(0), "Cannot verify address 0");
        require(!_isUsedAddress[user], "Address has previously been linked");
        _isUsedAddress[user] = true;
        _resolveId[user] = currentId;
        _resolveAddress[currentId] = user;
        emit Verified(user, currentId);
        unchecked {
            currentId++;
        }
    }

    /// @notice lets owner verify an address @param users.
    /// @param users: address of new user to be mapped
    /// @notice cannot map: a previously verified address (whether currently mapped or revoked)
    function verifyBatch(address[] calldata users) external {
        for (uint256 i = 0; i < users.length; i++) {
            verify(users[i]);
        }
    }

    /// @notice lets owner revoke the ID an address @param user.
    /// @param user: address of user to be revoked
    /// @notice cannot revoke: an unmapped user
    function revoke(address user) public onlyOwner {
        uint256 userId = _resolveId[user];
        require(userId != 0, "Address is not mapped");
        require(
            _reAssignWaitlist[userId].oldAddress == address(0),
            "Id is on waitlist already"
        );
        _resolveId[user] = 0;
        _resolveAddress[userId] = address(0);
        _reAssignWaitlist[userId] = reAssignWaitlistInfo(
            user,
            block.timestamp + 3 days
        );
        emit Revoked(user, userId);
    }

    /// @notice lets owner revoke the ID an address @param users.
    /// @param users: address of user to be revoked
    /// @notice cannot revoke: an unmapped user
    function revokeBatch(address[] calldata users) external {
        for (uint256 i = 0; i < users.length; i++) {
            revoke(users[i]);
        }
    }

    /// @notice lets owner reassigns an Id @param userId to an address @param user.
    /// @param user: address of user to be revoked
    /// @param userId: ID to re assign @param user to
    /// @notice to enable re assignment to its last address it checks if the last
    ///      address is the same as the input @param user and remaps it to its old Id
    ///      else, it reverts if a previously mapped or/and revoked address is being mapped to another Id than its last (and only)

    function reAssign(uint256 userId, address user) public onlyOwner {
        require(user != address(0), "Cannot reAssign ID to address 0");
        reAssignWaitlistInfo memory _reAssignWaitlistInfo = _reAssignWaitlist[
            userId
        ];
        require(
            _reAssignWaitlistInfo.timeOutEnd <= block.timestamp,
            "cool down not elapsed"
        );
        require(
            _reAssignWaitlistInfo.oldAddress != address(0),
            "Id not on reassign waitlist"
        );
        if (user == _reAssignWaitlistInfo.oldAddress) {
            _reAssignWaitlist[userId].oldAddress = address(0);
            _resolveId[user] = userId;
            _resolveAddress[userId] = user;
        } else {
            require(!_isUsedAddress[user], "Address has been linked");
            _isUsedAddress[user] = true;
            _reAssignWaitlist[userId].oldAddress = address(0);
            _reAssignWaitlistInfo.timeOutEnd = 0;
            _resolveId[user] = userId;
            _resolveAddress[userId] = user;
        }
        emit ReAssigned(user, userId);
    }

    /// @notice lets owner reassigns an Id @param userIds to an address @param users.
    /// @param users: address of user to be revoked
    /// @param userIds: ID to re assign @param users to
    /// @notice to enable re assignment to its last address it checks if the last
    ///      address is the same as the input @param users and remaps it to its old Id
    ///      else, it reverts if a previously mapped or/and revoked address is being mapped to another Id than its last (and only)
    function reAssignBatch(
        uint256[] calldata userIds,
        address[] calldata users
    ) external {
        require(
            userIds.length == users.length,
            "UserID and User of different lengths"
        );
        for (uint256 i = 0; i < users.length; i++) {
            reAssign(userIds[i], users[i]);
        }
    }

    function resolveId(address user) external view returns (uint256 userId) {
        userId = _resolveId[user];
    }

    function resolveAddress(
        uint256 userId
    ) external view returns (address user) {
        user = _resolveAddress[userId];
    }

    function reAssignWaitlist(
        uint256 userId
    )
        external
        view
        returns (reAssignWaitlistInfo memory _reAssignWaitlistInfo)
    {
        _reAssignWaitlistInfo = _reAssignWaitlist[userId];
    }

    function isUsedAddress(address user) external view returns (bool isUsed) {
        isUsed = _isUsedAddress[user];
    }
}




/** 
 *  SourceUnit: /Users/michaels/BlockPlot/contracts/BlockPlot/BlockPlotERC1155.sol
*/
            

// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [////IMPORTANT]
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
     * ////IMPORTANT: because control is transferred to `recipient`, care must be
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




/** 
 *  SourceUnit: /Users/michaels/BlockPlot/contracts/BlockPlot/BlockPlotERC1155.sol
*/
            

// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

////import "../IERC1155.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}




/** 
 *  SourceUnit: /Users/michaels/BlockPlot/contracts/BlockPlot/BlockPlotERC1155.sol
*/
            

// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

////import "../../utils/introspection/IERC165.sol";

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





/** 
 *  SourceUnit: /Users/michaels/BlockPlot/contracts/BlockPlot/BlockPlotERC1155.sol
*/
            

// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}




/** 
 *  SourceUnit: /Users/michaels/BlockPlot/contracts/BlockPlot/BlockPlotERC1155.sol
*/
            

// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

////import "../utils/Context.sol";

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
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
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
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
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




/** 
 *  SourceUnit: /Users/michaels/BlockPlot/contracts/BlockPlot/BlockPlotERC1155.sol
*/
            


// Improvised version of OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/ERC1155.sol) for Identity.sol

/// @author Michael Amadi
/// @title BlockPlot Base ERC1155 modified Contract

pragma solidity ^0.8.7;
////import "hardhat/console.sol";
////import {IERC1155Receiver} from "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
////import {IERC1155, IERC1155MetadataURI} from "@openzeppelin/contracts/token/ERC1155/extensions/IERC1155MetadataURI.sol";
////import {Address} from "@openzeppelin/contracts/utils/Address.sol";
////import {Context} from "@openzeppelin/contracts/utils/Context.sol";
////import {Identity} from "./Identity.sol";
////import {ERC165, IERC165} from "@openzeppelin/contracts/utils/introspection/ERC165.sol";

contract ImprovisedERC1155 is Context, ERC165, IERC1155 {
    using Address for address;

    // address of the identity contract.
    address public identityAddress;

    uint256 public constant decimals = 18;

    struct AssetMetadata {
        string name;
        string symbol;
        uint256 totalSupply;
        uint256 vestingPeriod;
        uint256 initialSalePeriod;
        uint256 costToDollar;
        bool initialized; // set to true forever after asset is initialized
        uint256 assetId; // set to the currentAssetId value and never changeable
        address assetIssuer;
    }

    mapping(uint256 => AssetMetadata) public idToMetadata;

    // Mapping from asset id to userId's balance
    mapping(uint256 => mapping(uint256 => uint256)) balances;

    // Mapping from userId to operator approvals
    mapping(uint256 => mapping(uint256 => bool)) private _operatorApprovals;

    mapping(uint256 => bool) isExchange;

    constructor(address _identityAddress) {
        identityAddress = _identityAddress;
        isExchange[1] = true;
        isExchange[2] = true;
    }

    function _idToMetadata(
        uint256 assetId
    ) external view returns (AssetMetadata memory) {
        return idToMetadata[assetId];
    }

    // // change the identity contract's address, overriden to be called by onlyOwner in BlockPlotERC1155 contract.
    // function changeIdentityAddress(
    //     address newIdentityAddress
    // ) external virtual {
    //     require(newIdentityAddress != address(0), "cant set to address 0");
    //     identityAddress = newIdentityAddress;
    // }

    function initialSaleAddress() public view returns (address) {
        return Identity(identityAddress).resolveAddress(1);
    }

    function swapContractAddress() public view returns (address) {
        return Identity(identityAddress).resolveAddress(2);
    }

    // // sets/changes the vesting period for an asset
    // function changeVestingPeriod(
    //     uint256 assetId,
    //     uint256 vestingEnd
    // ) external virtual {
    //     idToMetadata[assetId].vestingPeriod = vestingEnd;
    // }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(
        address account,
        uint256 id
    ) public view virtual override returns (uint256) {
        uint256 userId = Identity(identityAddress).resolveId(account);
        require(userId != 0, "ERC1155: address is not a valid owner");
        return balances[id][userId];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(
        address[] memory accounts,
        uint256[] memory ids
    ) public view virtual override returns (uint256[] memory) {
        require(
            accounts.length == ids.length,
            "ERC1155: accounts and ids length mismatch"
        );
        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(
        address operator,
        bool approved
    ) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(
        address account,
        address operator
    ) public view virtual override returns (bool) {
        uint256 _account = Identity(identityAddress).resolveId(account);
        require(_account != 0, "ERC1155: account is not a valid owner");
        uint256 _operator = Identity(identityAddress).resolveId(operator);
        require(_operator != 0, "ERC1155: operator is not a valid owner");

        return _operatorApprovals[_account][_operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not token owner nor approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not token owner nor approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        uint256 _from = Identity(identityAddress).resolveId(from);
        require(_from != 0, "ERC1155: from is not a valid owner");
        require(
            _from == 1 || idToMetadata[id].initialSalePeriod < block.timestamp,
            "Initial Sale period still on"
        );
        require(
            _from == 1 || idToMetadata[id].vestingPeriod < block.timestamp,
            "Vesting period still on"
        );

        uint256 _to = Identity(identityAddress).resolveId(to);
        require(_to != 0, "ERC1155: to is not a valid owner");

        uint256 fromBalance = balances[id][_from];
        require(
            fromBalance >= amount,
            "ERC1155: insufficient balance for transfer"
        );

        if (!isExchange[_to]) {
            uint256 percentageHoldings = ((balances[id][_to] + amount) * 100) /
                (idToMetadata[id].totalSupply);

            require(percentageHoldings < 10, "Cant own >= 10% of total supply");
        }

        unchecked {
            balances[id][_from] = fromBalance - amount;
        }
        balances[id][_to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(
            ids.length == amounts.length,
            "ERC1155: ids and amounts length mismatch"
        );
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        uint256 _from = Identity(identityAddress).resolveId(from);
        require(_from != 0, "ERC1155: from is not a valid owner");
        uint256 _to = Identity(identityAddress).resolveId(to);
        require(_to != 0, "ERC1155: to is not a valid owner");

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            require(
                _from == 1 ||
                    idToMetadata[id].initialSalePeriod < block.timestamp,
                "Initial Sale period still on"
            );
            require(
                _from == 1 || idToMetadata[id].vestingPeriod < block.timestamp,
                "Vesting period still on"
            );
            uint256 amount = amounts[i];

            uint256 fromBalance = balances[id][_from];
            require(
                fromBalance >= amount,
                "ERC1155: insufficient balance for transfer"
            );

            if (!isExchange[_to]) {
                uint256 percentageHoldings = ((balances[id][_to] + amount) *
                    100) / (idToMetadata[id].totalSupply);
                require(
                    percentageHoldings < 10,
                    "Cant own >= 10% of total supply"
                );
            }
            unchecked {
                balances[id][_from] = fromBalance - amount;
            }
            balances[id][_to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(
            operator,
            from,
            to,
            ids,
            amounts,
            data
        );
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        address to = initialSaleAddress();
        require(to != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        uint256 _to = Identity(identityAddress).resolveId(to);
        require(_to != 0, "ERC1155: to is not a valid owner");

        balances[id][_to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(
            operator,
            address(0),
            to,
            id,
            amount,
            data
        );
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        address to = initialSaleAddress();
        require(to != address(0), "ERC1155: mint to the zero address");
        require(
            ids.length == amounts.length,
            "ERC1155: ids and amounts length mismatch"
        );

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        uint256 _to = Identity(identityAddress).resolveId(to);
        require(_to != 0, "ERC1155: to is not a valid owner");

        for (uint256 i = 0; i < ids.length; i++) {
            balances[ids[i]][_to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(
            operator,
            address(0),
            to,
            ids,
            amounts,
            data
        );
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function _burn(uint256 id, uint256 amount) internal virtual {
        address from = initialSaleAddress();
        require(from != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        uint256 _from = Identity(identityAddress).resolveId(from);
        require(_from != 0, "ERC1155: from is not a valid owner");

        uint256 fromBalance = balances[id][_from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            balances[id][_from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        address from = initialSaleAddress();
        require(from != address(0), "ERC1155: burn from the zero address");
        require(
            ids.length == amounts.length,
            "ERC1155: ids and amounts length mismatch"
        );

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 _from = Identity(identityAddress).resolveId(from);
            require(_from != 0, "ERC1155: from is not a valid owner");

            uint256 fromBalance = balances[id][_from];
            require(
                fromBalance >= amount,
                "ERC1155: burn amount exceeds balance"
            );
            unchecked {
                balances[id][_from] = fromBalance - amount;
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC1155: setting approval status for self");

        uint256 _owner = Identity(identityAddress).resolveId(owner);
        require(_owner != 0, "ERC1155: owner is not a valid owner");
        uint256 _operator = Identity(identityAddress).resolveId(operator);
        require(_operator != 0, "ERC1155: operator is not a valid owner");

        _operatorApprovals[_owner][_operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `ids` and `amounts` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    /**
     * @dev Hook that is called after any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try
                IERC1155Receiver(to).onERC1155Received(
                    operator,
                    from,
                    id,
                    amount,
                    data
                )
            returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try
                IERC1155Receiver(to).onERC1155BatchReceived(
                    operator,
                    from,
                    ids,
                    amounts,
                    data
                )
            returns (bytes4 response) {
                if (
                    response != IERC1155Receiver.onERC1155BatchReceived.selector
                ) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(
        uint256 element
    ) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
}


/** 
 *  SourceUnit: /Users/michaels/BlockPlot/contracts/BlockPlot/BlockPlotERC1155.sol
*/

////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: UNLICENSED
pragma solidity ^0.8.7;

/// @author Michael Amadi
/// @title BlockPlot Asset Contract

////import {ImprovisedERC1155} from "./ImprovisedERC1155.sol";
////import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";
////import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
////import {Identity} from "./Identity.sol";
////import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

contract BlockPlotERC1155 is Ownable, Pausable, ImprovisedERC1155 {
    using Strings for uint256;

    uint256 public currentAssetId = 0;

    constructor(address _identityAddress) ImprovisedERC1155(_identityAddress) {}

    //_______________________________________________________Events___________________________________________________________

    event VestingPeriodChanged(uint256 assetId, uint256 vestingEnd);
    event InitialSalePeriodChanged(uint256 assetId, uint256 InitialSaleEnd);
    event AssetIsserChanged(uint256 assetId, address newAssetIssuer);
    event AssetInitialized(
        uint256 indexed assetId,
        string indexed name,
        string symbol,
        uint256 costToDollar,
        uint256 vestingPeriod,
        uint256 initialSalePeriod,
        address assetIssuer,
        uint256 minted
    );

    //___________________________________________________________________________________________________________________________

    function setExchange(uint256 id, bool _isExchange) external onlyOwner {
        isExchange[id] = _isExchange;
    }

    /// @notice pauses all interactions with functions with 'whenNotPaused' modifier
    function pause() public onlyOwner {
        _pause();
    }

    /// @notice unpauses all interactions with functions with 'whenNotPaused' modifier
    function unPause() public onlyOwner {
        _unpause();
    }

    /// @notice stops approvals if contract is paused
    function setApprovalForAll(
        address operator,
        bool approved
    ) public override {
        require(!paused(), "ERC1155Pausable: token transfer while paused");
        super.setApprovalForAll(operator, approved);
    }

    /// @notice checks to stop transfers if the contract is paused
    /// @notice prevents minting tokens for uninitialized assets
    /// @notice handles increase and decreasing of total supply of assets in each assets AssetMetadata struct
    function _beforeTokenTransfer(
        address,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory
    ) internal virtual override {
        require(!paused(), "ERC1155Pausable: token transfer while paused");

        if (from == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                require(
                    idToMetadata[ids[i]].initialized,
                    "Asset uninitialized"
                );
                idToMetadata[ids[i]].totalSupply += amounts[i];
            }
        }

        if (to == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                uint256 id = ids[i];
                uint256 amount = amounts[i];
                uint256 supply = idToMetadata[id].totalSupply;
                require(
                    supply >= amount,
                    "ERC1155: burn amount exceeds totalSupply"
                );
                unchecked {
                    idToMetadata[id].totalSupply = supply - amount;
                }
            }
        }
    }

    /// @notice changes the identity address to @param newIdentityAddress
    /// @param newIdentityAddress: identity address to change to.
    function changeIdentityAddress(
        address newIdentityAddress
    ) external onlyOwner {
        require(newIdentityAddress != address(0), "cant set to address 0");
        identityAddress = newIdentityAddress;
    }

    /// @notice changes the vesting period for an asset
    /// @param assetId: asset Id of asset to update
    /// @param vestingEnd: new end of vesting period
    function changeVestingPeriod(
        uint256 assetId,
        uint256 vestingEnd
    ) external onlyOwner {
        require(idToMetadata[assetId].initialized, "Asset not initialized");
        idToMetadata[assetId].vestingPeriod = vestingEnd;
        emit VestingPeriodChanged(assetId, vestingEnd);
    }

    /// @notice changes the initial sale period for an asset
    /// @param assetId: asset Id of asset to update
    /// @param initialSaleEnd: new end of initial sale period
    function changeInitialSalePeriod(
        uint256 assetId,
        uint256 initialSaleEnd
    ) external onlyOwner {
        require(idToMetadata[assetId].initialized, "Asset not initialized");
        idToMetadata[assetId].initialSalePeriod = initialSaleEnd;
        emit InitialSalePeriodChanged(assetId, initialSaleEnd);
    }

    /// @notice changes the asset issuer of an asset
    /// @param assetId: asset Id of asset to update
    /// @param newAssetIssuer: new address of the asset issuer
    function setAssetIssuerAddress(
        uint256 assetId,
        address newAssetIssuer
    ) external onlyOwner {
        require(idToMetadata[assetId].initialized, "Asset not initialized");
        idToMetadata[assetId].assetIssuer = newAssetIssuer;
        emit AssetIsserChanged(assetId, newAssetIssuer);
    }

    /// @notice Initializes an asset id
    /// @notice without being initialized, an asset cannot be minted. there's no way to uninitialize an asset
    /// @param _name: name of new asset to be initialized
    /// @param _symbol: symbol of new asset to be initialized
    /// @param _costToDollar: cost in dollars of one asset's token (taking the 18 decimal places into consideration)
    /// @param _vestingPeriod: end of vesting period which prevent user who bought the asset from selling it until the time elapses
    /// @param _initialSalePeriod: when the intial sale will end and users can purchase assets from DeXes and asset issuers can withdraw proceeds
    /// @param _assetIssuer: address of the asset issuer
    /// @param _mintAmount: amount of tokens to mint while initializing the asset, 0 if to be minted later
    function initializeAsset(
        string memory _name,
        string memory _symbol,
        uint256 _costToDollar,
        uint256 _vestingPeriod,
        uint256 _initialSalePeriod,
        address _assetIssuer,
        uint256 _mintAmount
    ) external onlyOwner {
        require(!paused(), "ERC1155Pausable: token transfer while paused");
        uint256 _currentAssetId = currentAssetId;
        require(
            !idToMetadata[_currentAssetId].initialized,
            "Asset initialized"
        );
        idToMetadata[_currentAssetId] = AssetMetadata(
            _name,
            _symbol,
            0,
            _vestingPeriod,
            _initialSalePeriod,
            _costToDollar,
            true,
            _currentAssetId,
            _assetIssuer
        );

        unchecked {
            currentAssetId++;
        }

        // if mint amount is greater than 0, mint the value to the initial sale contract.
        if (_mintAmount > 0) _mint(_currentAssetId, _mintAmount, "");

        emit AssetInitialized(
            _currentAssetId,
            _name,
            _symbol,
            _costToDollar,
            _vestingPeriod,
            _initialSalePeriod,
            _assetIssuer,
            _mintAmount
        );
    }

    /// @notice mints asset, should be minted only to the initial sale contract address and is hardcoded
    /// @param id: asset Id of token to mint
    /// @param amount: amount of tokens to be minted to the initial sale contract
    function mintAsset(uint256 id, uint256 amount) external onlyOwner {
        _mint(id, amount, "");
    }

    /// @notice burn asset, can burn assets on the initial sale contract
    /// @param id: asset id of token to burn
    /// @param amount: amount of tokens to be burned from the initial sale contract
    function burnAsset(uint256 id, uint256 amount) external onlyOwner {
        _burn(id, amount);
    }

    /// @notice batch-mints asset, should be minted only to the initial sale contract address and is hardcoded
    /// @param ids: asset Id of token to mint
    /// @param amounts: amounts of tokens to be minted to the initial sale contract
    /// @dev ids and amounts is ran respectively so should be arranged as so
    function mintBatchAsset(
        uint256[] memory ids,
        uint256[] memory amounts
    ) external onlyOwner {
        _mintBatch(ids, amounts, "0x");
    }

    /// @notice batch-burns asset, should be burned only from the initial sale contract address and is hardcoded
    /// @param ids: asset Id of token to burn
    /// @param amounts: amounts of tokens to be burned from the initial sale contract
    /// @dev ids and amounts is ran respectively so should be arranged as so
    function burnBatchAsset(
        uint256[] memory ids,
        uint256[] memory amounts
    ) external onlyOwner {
        _burnBatch(ids, amounts);
    }
}