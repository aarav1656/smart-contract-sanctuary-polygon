/**
 *Submitted for verification at polygonscan.com on 2023-01-02
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
pragma abicoder v2;



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
     * by making the `nonReentrant` function external, and make it call a
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







interface IRoyaltySplitter {
    // ============ Events ============

    event PaymentReleased(address to, uint256 amount);
    event ERC20PaymentReleased(
        IERC20 indexed token,
        address to,
        uint256 amount
    );
    event PaymentReceived(address from, uint256 amount);

    // ============ Read Methods ============

    /**
     * @dev Getter for the address of the payee via `tokenId`.
     */
    function payee(uint256 tokenId) external view returns (address);

    /**
     * @dev Determines how much ETH are releaseable for `tokenId`
     */
    function releaseable(uint256 tokenId) external view returns (uint256);

    /**
     * @dev Determines how much ERC20 `token` are releaseable for `tokenId`
     */
    function releaseable(
        IERC20 token,
        uint256 tokenId
    ) external view returns (uint256);

    /**
     * @dev Getter for the amount of shares held by an account.
     */
    function shares() external view returns (uint256);

    /**
     * @dev Getter for the amount of shares held by an account.
     */
    function shares(address account) external view returns (uint256);

    /**
     * @dev Getter for the total amount of Ether already released.
     */
    function totalReleased() external view returns (uint256);

    /**
     * @dev Getter for the total amount of `token` already released.
     * `token` should be the address of an IERC20 contract.
     */
    function totalReleased(IERC20 token) external view returns (uint256);
}







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
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}







interface IERC721C is IERC721 {
  /**
   * @dev Returns the address of token id burned
   */
  function burnerOf(uint256 tokenId) external view returns(address);

  /**
   * @dev Returns the last id issued
   */
  function lastId() external view returns(uint256);
  
  /**
   * @dev Returns true if `owner` owns all the `tokenIds`.
   * Will error if one of the token is burnt
   */
  function ownsAll(address owner, uint256[] memory tokenIds) external view returns(bool);

  /**
   * @dev Returns all the owner's tokens. This is an incredibly 
   * ineffecient method and should not be used by other contracts.
   * It's recommended to call this on your dApp then call `ownsAll`
   * from your other contract instead.
   */
  function ownerTokens(address owner) external view returns(uint256[] memory);

  /**
   * @dev Returns the overall amount of tokens burned
   */
  function totalBurned() external view returns(uint256);

  /**
   * @dev Shows the overall amount of tokens generated in the contract
   */
  function totalSupply() external view returns(uint256);
}





// Based on Cash Cows sources


//--------------------------------------------------------------
//             ______
//        ____/_  __/_______  ____ ________  _________  __
//       / __ \/ / / ___/ _ \/ __ `/ ___/ / / / ___/ / / /
//      / /_/ / / / /  /  __/ /_/ (__  ) /_/ / /  / /_/ /
//     / .___/_/ /_/   \___/\__,_/____/\__,_/_/   \__, /
//    /_/                                        /____/
//
//--------------------------------------------------------------
//





// ============ Errors ============

error InvalidCall();

// ============ Contract ============

contract PoTreasury is Context, ReentrancyGuard, IRoyaltySplitter {
    // ============ Constants ============

    //we are going to need this to find out who owns what
    IERC721C public immutable COLLECTION;

    // ============ Storage ============

    //total amount of ETH released
    uint256 private _ethTotalReleased;
    //amount of ETH released per NFT token id
    mapping(uint256 => uint256) private _ethReleased;

    //total amount of ERC20 released
    mapping(IERC20 => uint256) private _erc20TotalReleased;
    //amount of ERC20 released per NFT token id
    mapping(IERC20 => mapping(uint256 => uint256)) private _erc20Released;

    // ============ Deploy ============

    constructor(IERC721C collection) payable {
        //assign the collection
        COLLECTION = collection;
    }

    /**
     * @dev The Ether received will be logged with {PaymentReceived}
     * events. Note that these events are not fully reliable: it's
     * possible for a contract to receive Ether without triggering this
     * function. This only affects the reliability of the events, and not
     * the actual splitting of Ether.
     */
    receive() external payable virtual {
        emit PaymentReceived(_msgSender(), msg.value);
    }

    // ============ Read Methods ============

    /**
     * @dev Determines how much ETH/MATIC/... are releaseable
     */
    function releaseable(uint256 tokenId) public view returns (uint256) {
        return
            _pendingPayment(
                address(this).balance + totalReleased(),
                released(tokenId)
            );
    }

    /**
     * @dev Determines how much ERC20 tokens are releaseable
     */
    function releaseable(
        IERC20 token,
        uint256 tokenId
    ) public view returns (uint256) {
        return
            _pendingPayment(
                token.balanceOf(address(this)) + totalReleased(token),
                released(token, tokenId)
            );
    }

    /**
     * @dev Returns the sum of ETH/MATIC/... releaseable given `tokenIds`
     */
    function releaseableBatch(
        uint256[] memory tokenIds
    ) external view returns (uint256 totalReleaseable) {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            //get payment and should be more than zero
            totalReleaseable += releaseable(tokenIds[i]);
        }
    }

    /**
     * @dev Returns the sum of ERC20 tokens releaseable given `tokenIds`
     */
    function releaseableBatch(
        IERC20 token,
        uint256[] memory tokenIds
    ) external view returns (uint256 totalReleaseable) {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            //get payment and should be more than zero
            totalReleaseable += releaseable(token, tokenIds[i]);
        }
    }

    /**
     * @dev Getter for the total amount of ETH/MATIC/... already released.
     */
    function totalReleased() public view returns (uint256) {
        return _ethTotalReleased;
    }

    /**
     * @dev Getter for the total amount of `token` already released.
     * `token` should be the address of an IERC20 contract.
     */
    function totalReleased(IERC20 token) public view returns (uint256) {
        return _erc20TotalReleased[token];
    }

    /**
     * @dev Getter for the amount of shares held by an account.
     */
    function shares() public view returns (uint256) {
        return COLLECTION.totalSupply();
    }

    /**
     * @dev Getter for the amount of shares held by an account.
     */
    function shares(address account) external view returns (uint256) {
        return COLLECTION.balanceOf(account);
    }

    /**
     * @dev Getter for the amount of ETH/MATIC already released to the `tokenId`.
     */
    function released(uint256 tokenId) public view returns (uint256) {
        return _ethReleased[tokenId];
    }

    /**
     * @dev Getter for the amount of `token` tokens already released to a
     * `tokenId`. `token` should be the address of an IERC20 contract.
     */
    function released(
        IERC20 token,
        uint256 tokenId
    ) public view returns (uint256) {
        return _erc20Released[token][tokenId];
    }

    /**
     * @dev Getter for the address of the payee via `tokenId`.
     */
    function payee(uint256 tokenId) public view returns (address) {
        return COLLECTION.ownerOf(tokenId);
    }

    // ============ Write Methods ============

    /**
     * @dev Triggers a transfer to owner of `tokenId` of the amount of
     * ETH/MATIC they are owed, according to their percentage of the total
     * shares and their previous withdrawals.
     */
    function release(uint256 tokenId) external nonReentrant {
        //get account and should be the sender
        address account = payee(tokenId);
        if (account != _msgSender()) revert InvalidCall();
        //get payment and should be more than zero
        uint256 payment = releaseable(tokenId);
        if (payment == 0) revert InvalidCall();
        //add released payment
        _ethReleased[tokenId] += payment;
        _ethTotalReleased += payment;
        //send it off.. buh bye!
        Address.sendValue(payable(account), payment);
        //let everyone know what happened
        emit PaymentReleased(account, payment);
    }

    /**
     * @dev Triggers a transfer to `account` of the amount of `token`
     * tokens they are owed, according to their percentage of the total
     * shares and their previous withdrawals. `token` must be the address
     * of an IERC20 contract.
     */
    function release(IERC20 token, uint256 tokenId) external nonReentrant {
        //get account and should be the sender
        address account = payee(tokenId);
        if (account != _msgSender()) revert InvalidCall();
        //get payment and should be more than zero
        uint256 payment = releaseable(token, tokenId);
        if (payment == 0) revert InvalidCall();
        //add released payment
        _erc20Released[token][tokenId] += payment;
        _erc20TotalReleased[token] += payment;
        //send it off.. buh bye!
        SafeERC20.safeTransfer(token, payable(account), payment);
        //let everyone know what happened
        emit ERC20PaymentReleased(token, account, payment);
    }

    /**
     * @dev Triggers a batch transfer to owner of `tokenId` of the amount
     * of ETH/MATIC they are owed, according to their percentage of the total
     * shares and their previous withdrawals.
     */
    function releaseBatch(uint256[] memory tokenIds) public virtual {
        //get account and should be the owner
        address account = _msgSender();
        if (!COLLECTION.ownsAll(_msgSender(), tokenIds)) revert InvalidCall();

        uint256 payment;
        uint256 totalPayment;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            //get payment and should be more than zero
            payment = releaseable(tokenIds[i]);
            //skip if noting is releaseable
            if (payment == 0) continue;
            //add released payment
            _ethReleased[tokenIds[i]] += payment;
            //add to total payment
            totalPayment += payment;
        }
        //if no payments are due
        if (totalPayment == 0) revert InvalidCall();
        //add released payment
        _ethTotalReleased += totalPayment;
        //send it off.. buh bye!
        Address.sendValue(payable(account), totalPayment);
        //let everyone know what happened
        emit PaymentReleased(account, totalPayment);
    }

    /**
     * @dev Triggers a batch transfer to `account` of the amount of `token`
     * tokens they are owed, according to their percentage of the total
     * shares and their previous withdrawals. `token` must be the address
     * of an IERC20 contract.
     */
    function releaseBatch(
        IERC20 token,
        uint256[] memory tokenIds
    ) external nonReentrant {
        //get account and should be the owner
        address account = _msgSender();
        if (!COLLECTION.ownsAll(_msgSender(), tokenIds)) revert InvalidCall();

        uint256 payment;
        uint256 totalPayment;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            //get payment and should be more than zero
            payment = releaseable(token, tokenIds[i]);
            //skip if noting is releaseable
            if (payment == 0) continue;
            //add released payment
            _erc20Released[token][tokenIds[i]] += payment;
            //add to total payment
            totalPayment += payment;
        }
        //if no payments are due
        if (totalPayment == 0) revert InvalidCall();
        //add released payment
        _erc20TotalReleased[token] += totalPayment;
        //send it off.. buh bye!
        SafeERC20.safeTransfer(token, payable(account), totalPayment);
        //let everyone know what happened
        emit ERC20PaymentReleased(token, account, payment);
    }

    /**
     * @dev internal logic for computing the pending payment of
     * an `account` given the token historical balances and
     * already released amounts.
     */
    function _pendingPayment(
        uint256 totalReceived,
        uint256 alreadyReleased
    ) private view returns (uint256) {
        uint256 amount = totalReceived / COLLECTION.totalSupply();
        if (amount < alreadyReleased) return 0;
        return amount - alreadyReleased;
    }
}