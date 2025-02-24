//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
contract EventEmitter {
    event newCollection(address collectionAddress, string name, address owner, string symbol);
    event newMint(address collectionAddress, uint256 tokenId, address owner, bool _wantsRoyalty, uint256 _royalty_percentage,bool _lock, string _lockedURI, string _uri);
    
    // event newFixPriceSale (address collectionAddress, uint256 tokenId, uint256 price, address newOwner, bytes32 orderId);
    // event newBid (address collectionAddress, uint256 tokenId, address bidder, uint256 bidAmount);
    // event auctionSettle ( address collectionAddress, uint256 tokenId, address highestBidder, uint256 highestBidAmount, bytes32 orderId);

    // event newNFTOnFixPriceSale (address collectionAddress, uint256 tokenId, address currentOwner, uint256 price,bytes32 orderId);
    // event newNFTOnAuction (address collectionAddress, uint256 tokenId, address currentOwner, uint256 reservePrice, bytes32 orderId);
    //
    // event auctionUpdated(address collectionAddress, uint256 tokenId, uint256 newReservePrice, bytes32 orderId);
    // event fixPriceUpdated(address collectionAddress, uint256 tokenId, uint256 newPrice, bytes32 orderId);
    
    // event auctionCancelled(address collectionAddress, uint256 tokenId, bytes32 orderId);
    // event fixPriceCancelled(address collectionAddress, uint256 tokenId, bytes32 orderId);
    
    // function auctionCancelledEvent(address _collectionAddress, uint256 _tokenId, bytes32 _orderId) internal  {
    //     emit auctionCancelled(_collectionAddress, _tokenId, _orderId);
    // }
    // function fixPriceCancelledEvent(address _collectionAddress, uint256 _tokenId, bytes32 _orderId) internal  {
    //     emit fixPriceCancelled(_collectionAddress, _tokenId, _orderId);
    // }
    // function auctionUpdatedEvent(address _collectionAddress, uint256 _tokenId, uint256 _newReservePrice, bytes32 _orderId) internal  {
    //     emit auctionUpdated(_collectionAddress, _tokenId, _newReservePrice, _orderId);
    // }
    // function fixPriceUpdatedEvent(address _collectionAddress, uint256 _tokenId, uint256 _newPrice, bytes32 _orderId) internal  {
    //     emit fixPriceUpdated(_collectionAddress, _tokenId, _newPrice, _orderId);
    // }
    function newCollectionCreatedEvent(address _collectionAddress, string memory _name, address _owner, string memory _symbol ) internal  {
        emit newCollection(_collectionAddress, _name, _owner, _symbol);
    }

    function newMintEvent(address _collectionAddress, uint256 _tokenId, address _owner, bool _wantsRoyalty, uint256 _royalty_percentage,bool _lock, string memory _lockedURI, string memory _uri) internal
    {
        emit newMint(_collectionAddress, _tokenId, _owner, _wantsRoyalty, _royalty_percentage, _lock, _lockedURI, _uri);
    }

    // function newFixPriceSaleEvent(address _collectionAddress, uint256 _tokenId, uint256 _price, address _newOwner, bytes32 _orderId) internal  {
    //     emit newFixPriceSale(_collectionAddress, _tokenId, _price, _newOwner, _orderId);
    // }

    // function newBidEvent(address _collectionAddress, uint256 _tokenId, address _bidder, uint256 _bidAmount) internal  {
    //     emit newBid(_collectionAddress, _tokenId, _bidder, _bidAmount);
    // }

    // function auctionSettleEvent(address _collectionAddress, uint256 _tokenId, address _highestBidder, uint256 _highestBidAmount, bytes32 _orderId) internal  {
    //     emit auctionSettle(_collectionAddress, _tokenId, _highestBidder, _highestBidAmount, _orderId);
    // }

    // function newNFTOnFixPriceSaleEvent(address _collectionAddress, uint256 _tokenId, address _currentOwner, uint256 _price, bytes32 _directSaleNFTOrderId) internal  {
    //     emit newNFTOnFixPriceSale(_collectionAddress, _tokenId, _currentOwner, _price, _directSaleNFTOrderId);
    // }

    // function newNFTOnAuctionEvent(address _collectionAddress, uint256 _tokenId, address _currentOwner, uint256 _reservePrice, bytes32 _auctionNFTOrderId) internal  {
    //     emit newNFTOnAuction(_collectionAddress, _tokenId, _currentOwner, _reservePrice, _auctionNFTOrderId);
    // }
}

/**
 *Submitted for verification at polygonscan.com on 2022-05-25
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
    function tryMul(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
    function tryDiv(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
    function tryMod(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
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
    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
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
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
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
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
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
    function functionDelegateCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionDelegateCall(
                target,
                data,
                "Address: low-level delegate call failed"
            );
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

interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
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
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(
                oldAllowance >= value,
                "SafeERC20: decreased allowance below zero"
            );
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(
                token,
                abi.encodeWithSelector(
                    token.approve.selector,
                    spender,
                    newAllowance
                )
            );
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

        bytes memory returndata = address(token).functionCall(
            data,
            "SafeERC20: low-level call failed"
        );
        if (returndata.length > 0) {
            // Return data is optional
            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: ERC20 operation did not succeed"
            );
        }
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
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

contract Pausable is Ownable {
    event Pause();
    event Unpause();

    bool public paused = false;

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(paused);
        _;
    }

    /**
     * @dev called by the owner to pause, triggers stopped state
     */
    function pause() public onlyOwner whenNotPaused {
        paused = true;
        emit Pause();
    }

    /**
     * @dev called by the owner to unpause, returns to normal state
     */
    function unpause() public onlyOwner whenPaused {
        paused = false;
        emit Unpause();
    }
}

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

interface IERC721 is IERC165 {
    // struct royalty_struct{
    //     address first_owner;
    //     uint royalty;
    // }
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    function tokenOfOwnerByIndex(address owner, uint256 index)
        external
        view
        returns (uint256);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    function royaltyInfoOwner(uint256 tokenId)
        external
        view
        returns (address payable);

    function royaltyInfoPercentage(uint256 tokenId)
        external
        view
        returns (uint256);

    function royaltyInfoIntention(uint256 tokenId) external view returns (bool);

    function flipContentLockedStatus(uint256 _tokenID) external;

    function isContentLocked(uint256 _tokenID) external view returns (bool);

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
    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);

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
    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);

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

interface IERC721Verifiable is IERC721 {
    function verifyFingerprint(uint256, bytes32) external view returns (bool);
}

// import event emitter
import "./EventEmitter.sol";
contract RareketNFTMarketplace is Pausable, ERC721Holder {
    using Address for address;
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    uint256 feeCut = 5;
    uint256 private marketplaceBalance = 0;

    IERC20 public acceptedToken;
    bytes4 public constant _INTERFACE_ID_ERC721 = 0x80ac58cd;

    constructor() Ownable() {
        // require(_acceptedToken.isContract(), "The accepted token address must be a deployed contract");
        // acceptedToken = IERC20(_acceptedToken); address _acceptedToken
    }

    function setPaused(bool _setPaused) public onlyOwner {
        return (_setPaused) ? pause() : unpause();
    }

    struct Order {
        bytes32 orderId;
        address payable seller;
        uint256 askingPrice;
        uint256 expiryTime;
        address tokenAddress;
    }

    struct DirectOrder {
        bytes32 orderId;
        address payable seller;
        uint256 askingPrice;
        address tokenAddress;
    }

    struct Bid {
        bytes32 bidId;
        address payable bidder;
        uint256 bidPrice;
    }

    //            Events
    event NewAuctionOrder(
        bytes32 orderId,
        address indexed seller,
        address indexed tokenAddress,
        uint256 indexed tokenId,
        uint256 askingPrice
    );

    event FixPriceOrderUpdated(address tokenAddress, uint256 tokenId, uint256 newPrice);

    event NewDirectOrder(
        bytes32 orderId,
        address indexed seller,
        address indexed tokenAddress,
        uint256 indexed tokenId,
        uint256 askingPrice
    );

    event AuctionOrderUpdated(address tokenAddress, uint256 tokenId, bytes32 orderId, uint256 askingPrice);

    event AuctionOrderSuccessful(
        address tokenAddress,
        uint256 tokenId,
        address indexed buyer,
        uint256 askingPrice,
        bytes32 orderId
    );

    event DirectOrderSuccessful(
        bytes32 orderId,
        address _tokenAddress,
        uint256 tokenId,
        address indexed buyer,
        uint256 price
    );

    event AuctionOrderCancelled(address tokenAddress, uint256 tokenId, bytes32 id);

    event DirectOrderCancelled(address tokenAddress, uint256 tokenId, bytes32 id);

    event NewBid(
        address indexed tokenAddress,
        uint256 indexed tokenId,
        address indexed bidder,
        uint256 priceInWei,
        bytes32 id
    );

    // event BidAccepted(bytes32 id);
    // event BidCancelled(bytes32 id);

    //                Mappings
    mapping(address => mapping(uint256 => Order)) public orderByTokenId;
    mapping(address => mapping(uint256 => Bid)) public bidByOrderId;
    mapping(address => mapping(uint256 => DirectOrder))
        public DirectorderByTokenId;

    mapping(uint256 => bool) private secondTransfer;

    function setFeeCut(uint256 _newCut) public onlyOwner {
        // uint256 test = _newCut % 10;
        require(_newCut > 0, "Fee cannot be less than 1%");
        feeCut = _newCut;
    }

    function createOrder(
        address _tokenAddress,
        uint256 _tokenId,
        uint256 _askingPrice
    ) public whenNotPaused {
        _createOrder(_tokenAddress, _tokenId, _askingPrice);
    }

    function newOwner(address _new) public onlyOwner {
        transferOwnership(_new);
    }

    function cancelOrder(address _tokenAddress, uint256 _tokenId)
        public
        whenNotPaused
    {
        Order memory order = orderByTokenId[_tokenAddress][_tokenId];

        require(
            order.seller == msg.sender || msg.sender == owner(),
            "Marketplace: unauthorized sender"
        );

        Bid memory bid = bidByOrderId[_tokenAddress][_tokenId];

        require(bid.bidId == 0, "Marketplace: This auction has active bids");

        _cancelOrder(order.orderId, _tokenAddress, _tokenId, msg.sender);
    }

    function cancelFixPriceOrder(address _tokenAddress, uint256 _tokenId)
        public
        whenNotPaused
    {
        DirectOrder memory order = DirectorderByTokenId[_tokenAddress][
            _tokenId
        ];

        require(
            order.seller == msg.sender || msg.sender == owner(),
            "Marketplace: unauthorized sender"
        );

        _cancelFixPriceOrder(
            order.orderId,
            _tokenAddress,
            _tokenId,
            msg.sender
        );
    }

    function updateOrder(
        address _tokenAddress,
        uint256 _tokenId,
        uint256 _askingPrice
    ) public whenNotPaused {
        Order memory order = orderByTokenId[_tokenAddress][_tokenId];
        require(order.orderId != 0, "Markeplace: Order not yet published");
        require(
            order.seller == msg.sender,
            "Markeplace: sender is not allowed"
        );
        Bid memory bid = bidByOrderId[_tokenAddress][_tokenId];
        require(
            bid.bidId == 0,
            "Marketplace: This auction has active bids on it so it can't be updated"
        );

        require(_askingPrice > 0, "Marketplace: Price should be bigger than 0");

        orderByTokenId[_tokenAddress][_tokenId].askingPrice = _askingPrice;

        emit AuctionOrderUpdated(_tokenAddress, _tokenId, order.orderId, _askingPrice);
        // auctionUpdatedEvent(_tokenAddress, _tokenId, _askingPrice,order.orderId);
    }

    function updateFixPriceOrder(
        address _tokenAddress,
        uint256 _tokenId,
        uint256 _newPrice
    ) public whenNotPaused {
        DirectOrder memory directOrder = DirectorderByTokenId[_tokenAddress][
            _tokenId
        ];
        require(
            directOrder.orderId != 0,
            "Marketplace: This tokenID is not on fix price sale yet"
        );
        require(
            directOrder.seller == msg.sender,
            "Marketplace: sender is not allowed"
        );
        require(
            _newPrice > 0,
            "Marketplace: New price must be greater than zero"
        );
        DirectorderByTokenId[_tokenAddress][_tokenId].askingPrice = _newPrice;
        emit FixPriceOrderUpdated(_tokenAddress, _tokenId, _newPrice);
        // fixPriceUpdatedEvent(_tokenAddress, _tokenId, _newPrice,directOrder.orderId);
    }

    // function getDirectOrderPrice(address _tokenAddress, uint256 _tokenId) public view whenNotPaused returns (uint256)
    // {
    //     DirectOrder memory directorder = DirectorderByTokenId[_tokenAddress][_tokenId];
    //     return directorder.askingPrice;
    // }

    // function safeExecuteOrder(address _tokenAddress, uint256 _tokenId, uint _askingPrice) public  whenNotPaused {

    //     Order memory order = _getValidOrder(_tokenAddress, _tokenId);

    //     require(order.askingPrice == _askingPrice, "Marketplace: invalid price");
    //     require(order.seller != msg.sender, "Marketplace: unauthorized sender");

    //    (order.seller).transfer(_askingPrice);

    //     Bid memory bid = bidByOrderId[_tokenAddress][_tokenId];

    //     if(bid.bidId !=0 ) {
    //         _cancelBid(bid.bidId, _tokenAddress, _tokenId, bid.bidder, bid.bidPrice);
    //     }

    //     _executeOrder(order.orderId, msg.sender,  _tokenAddress,  _tokenId,  _askingPrice);

    // }

    function safePlaceBid(address _tokenAddress, uint256 _tokenId)
        public
        payable
        whenNotPaused
    {
        Order memory order = orderByTokenId[_tokenAddress][_tokenId];
        require(
            order.seller != msg.sender,
            "Marketplace: The owner of NFT cannot place bid itself"
        );
        _createBid(_tokenAddress, _tokenId, msg.value);
    }

    // function cancelBid(address _tokenAddress, uint256 _tokenId) public whenNotPaused {

    //     Bid memory bid = bidByOrderId[_tokenAddress][_tokenId];
    //     require(bid.bidder == msg.sender || msg.sender == owner(), "Marketplace: Unauthorized sender");

    //     _cancelBid(bid.bidId, _tokenAddress, _tokenId, bid.bidder, bid.bidPrice);
    // }

    function acceptDirectSellOrder(address _tokenAddress, uint256 _tokenId)
        public
        payable
        whenNotPaused
    {
        DirectOrder memory directorder = DirectorderByTokenId[_tokenAddress][
            _tokenId
        ];
        require(
            directorder.orderId != 0,
            "Marketplace: This order doesn't exist"
        );
        require(
            directorder.seller != msg.sender,
            "Marketplace: Can't sell to owner"
        );
        require(
            directorder.askingPrice == msg.value,
            "Marketplace: Less amount sent to buy"
        );

        uint256 finalAmountAfterMarketplaceFee = directorder.askingPrice -
            ((directorder.askingPrice * feeCut) / 100);
        marketplaceBalance += ((directorder.askingPrice * feeCut) / 100);

        uint256 amountAfterRoyaltyCut;
        bool royaltyIntention = IERC721(_tokenAddress).royaltyInfoIntention(
            _tokenId
        );

        if (royaltyIntention) // First owner wants Royalties
        {
            if (secondTransfer[_tokenId] == false) {
                // First Transfer
                secondTransfer[_tokenId] = true;

                delete DirectorderByTokenId[_tokenAddress][_tokenId];
                directorder.seller.transfer(finalAmountAfterMarketplaceFee);
            } else {
                address payable firstOwnerAddress = IERC721(_tokenAddress)
                    .royaltyInfoOwner(_tokenId);
                uint256 percentage = IERC721(_tokenAddress)
                    .royaltyInfoPercentage(_tokenId);

                // uint256 percentage = royaltyInformation[_tokenId].royalty;
                uint256 royaltyAmount = ((finalAmountAfterMarketplaceFee *
                    percentage) / 100);
                amountAfterRoyaltyCut =
                    finalAmountAfterMarketplaceFee -
                    ((finalAmountAfterMarketplaceFee * percentage) / 100);

                delete DirectorderByTokenId[_tokenAddress][_tokenId];

                firstOwnerAddress.transfer(royaltyAmount);

                directorder.seller.transfer(amountAfterRoyaltyCut);
            }
        }
        // The first owner doesn't want Royalties
        else {
            delete DirectorderByTokenId[_tokenAddress][_tokenId];
            directorder.seller.transfer(finalAmountAfterMarketplaceFee); // Full amount is sent to seller instead
        }
        IERC721(_tokenAddress).safeTransferFrom(
            address(this),
            msg.sender,
            _tokenId
        );
        bool isLocked = IERC721(_tokenAddress).isContentLocked(_tokenId);
        if (isLocked) {
            IERC721(_tokenAddress).flipContentLockedStatus(_tokenId);
        }
        emit DirectOrderSuccessful(
            directorder.orderId,
            _tokenAddress,
            _tokenId,
            msg.sender,
            msg.value
        );
        // newFixPriceSaleEvent(
        //     _tokenAddress,
        //     _tokenId,
        //     directorder.askingPrice,
        //     msg.sender, // new owner
        //     directorder.orderId
        // );
    }

    /* */
    function acceptBidandExecuteOrder(
        address _tokenAddress,
        uint256 _tokenId,
        uint256 _bidPrice
    ) public whenNotPaused {
        Order memory order = orderByTokenId[_tokenAddress][_tokenId];
        require(
            order.orderId != 0,
            "Marketplace: No order auction exists for this tokenID"
        );
        require(
            order.expiryTime < block.timestamp,
            "Marketplace: Auction hasn't ended yet"
        );

        Bid memory bid = bidByOrderId[_tokenAddress][_tokenId];

        require(
            order.seller == msg.sender || bid.bidder == msg.sender,
            "Marketplace: Unauthorized sender"
        );
        require(bid.bidPrice == _bidPrice, "Markeplace: invalid bid price");

        delete bidByOrderId[_tokenAddress][_tokenId];

        // emit BidAccepted(bid.bidId);
        uint256 finalAmountAfterMarketplaceFee = bid.bidPrice -
            ((bid.bidPrice * feeCut) / 100);
        marketplaceBalance += ((bid.bidPrice * feeCut) / 100);

        bool royaltyIntention = IERC721(_tokenAddress).royaltyInfoIntention(
            _tokenId
        );

        if (royaltyIntention) // Wants royalties
        {
            if (
                secondTransfer[_tokenId] == false
            ) // The first owner is selling it so it's a first sale
            {
                secondTransfer[_tokenId] = true;
                delete orderByTokenId[_tokenAddress][_tokenId];
                order.seller.transfer(finalAmountAfterMarketplaceFee);
            }
            // Re-Sale
            else {
                address payable firstOwnerAddress = IERC721(_tokenAddress)
                    .royaltyInfoOwner(_tokenId);
                uint256 percentage = IERC721(_tokenAddress)
                    .royaltyInfoPercentage(_tokenId);

                uint256 royaltyAmount = ((finalAmountAfterMarketplaceFee *
                    percentage) / 100);
                uint256 amountAfterRoyaltyCut = finalAmountAfterMarketplaceFee -
                    ((finalAmountAfterMarketplaceFee * percentage) / 100);

                firstOwnerAddress.transfer(royaltyAmount);

                order.seller.transfer(amountAfterRoyaltyCut);
            }
        }
        // Doesn't want royalties
        else {
            delete orderByTokenId[_tokenAddress][_tokenId];
            order.seller.transfer(finalAmountAfterMarketplaceFee);
        }
        _executeOrder(
            order.orderId,
            bid.bidder,
            _tokenAddress,
            _tokenId,
            _bidPrice
        );
    }

    function createDirectSellOrder(
        address _tokenAddress,
        uint256 _tokenId,
        uint256 _askingPrice
    ) public whenNotPaused {
        IERC721 tokenRegistry = IERC721(_tokenAddress);

        address tokenOwner = tokenRegistry.ownerOf(_tokenId);

        require(
            tokenOwner == msg.sender,
            "Marketplace: Only the asset owner can create orders"
        );
        require(
            _askingPrice > 0,
            "Marketplace : The price must be greater than zero"
        );

        tokenRegistry.safeTransferFrom(tokenOwner, address(this), _tokenId);

        bytes32 _directOrderId = keccak256(
            abi.encodePacked(
                block.timestamp,
                _tokenAddress,
                _tokenId,
                _askingPrice
            )
        );

        DirectorderByTokenId[_tokenAddress][_tokenId] = DirectOrder({
            orderId: _directOrderId,
            seller: payable(msg.sender),
            tokenAddress: _tokenAddress,
            askingPrice: _askingPrice
        });

        emit NewDirectOrder(
            _directOrderId,
            msg.sender,
            _tokenAddress,
            _tokenId,
            _askingPrice
        );
        // newNFTOnFixPriceSaleEvent(
        //     _tokenAddress,
        //     _tokenId,
        //     msg.sender,
        //     _askingPrice,
        //     _directOrderId
        // );
        // return true;
    }

    function _createOrder(
        address _tokenAddress,
        uint256 _tokenId,
        uint256 _askingPrice
    ) internal {
        IERC721 tokenRegistry = IERC721(_tokenAddress);
        address tokenOwner = tokenRegistry.ownerOf(_tokenId);

        require(
            tokenOwner == msg.sender,
            "Marketplace: Only the asset owner can create orders"
        );
        require(
            _askingPrice > 0,
            "Marketplace: Reserve price must be greater than zero"
        );

        tokenRegistry.safeTransferFrom(tokenOwner, address(this), _tokenId);

        bytes32 _orderId = keccak256(
            abi.encodePacked(
                block.timestamp,
                _tokenAddress,
                _tokenId,
                _askingPrice
            )
        );
        orderByTokenId[_tokenAddress][_tokenId] = Order({
            orderId: _orderId,
            seller: payable(msg.sender),
            tokenAddress: _tokenAddress,
            askingPrice: _askingPrice,
            expiryTime: 0
        });

        emit NewAuctionOrder(
            _orderId,
            msg.sender,
            _tokenAddress,
            _tokenId,
            _askingPrice
        );
        // newNFTOnAuctionEvent(
        //     _tokenAddress,
        //     _tokenId,
        //     msg.sender,
        //     _askingPrice,
        //     _orderId
        // );
    }

    function _createBid(
        address _tokenAddress,
        uint256 _tokenId,
        uint256 value
    ) internal {
        Order memory order = orderByTokenId[_tokenAddress][_tokenId];
        require(order.orderId != 0, "Marketplace: asset not published");

        Bid memory bid = bidByOrderId[_tokenAddress][_tokenId];

        if (bid.bidId != 0) {
            // Not first bid
            require(
                order.expiryTime >= block.timestamp,
                "Marketplace: Auction ended"
            );
            if (
                block.timestamp.add(15 minutes) > order.expiryTime
            ) // If this bid came in last 15 minutes of Auction, reset timer to 15 minutes.
            {
                orderByTokenId[_tokenAddress][_tokenId].expiryTime = block
                    .timestamp
                    .add(15 minutes);
            }

            uint256 validBid = bid.bidPrice + ((bid.bidPrice * 10) / 100);
            require(
                value >= validBid,
                "Marketplace: bid price should be 10% higher than last bid"
            );

            _cancelBid(
                _tokenAddress,
                _tokenId,
                bid.bidder,
                bid.bidPrice
            );
        }
        // First bid
        //
        else {
            require(
                value >= order.askingPrice,
                "Marketplace: bid should be > reserve price"
            );
            orderByTokenId[_tokenAddress][_tokenId].expiryTime = block
                .timestamp
                .add(1 days); // 1 day auction time
        }
        bytes32 bidId = keccak256(
            abi.encodePacked(block.timestamp, msg.sender, order.orderId, value)
        );

        bidByOrderId[_tokenAddress][_tokenId] = Bid({
            bidId: bidId,
            bidder: payable(msg.sender),
            bidPrice: value
            // expiryTime: _expiryTime
        });
        emit NewBid(_tokenAddress, _tokenId, msg.sender, value, bidId );
        // newBidEvent(_tokenAddress, _tokenId, msg.sender, value);
    }

    function _executeOrder(
        bytes32 _orderId,
        address _buyer,
        address _tokenAddress,
        uint256 _tokenId,
        uint256 _soldFor
    ) internal {
        IERC721(_tokenAddress).safeTransferFrom(
            address(this),
            _buyer,
            _tokenId
        );
        emit AuctionOrderSuccessful(_tokenAddress, _tokenId, _buyer, _soldFor, _orderId);
        // auctionSettleEvent(_tokenAddress, _tokenId, _buyer, _askingPrice, _orderId);
    }

    function _getValidOrder(address _tokenAddress, uint256 _tokenId)
        internal
        view
        returns (Order memory order)
    {
        order = orderByTokenId[_tokenAddress][_tokenId];

        require(order.orderId != 0, "Marketplace: asset not published");
        // require(order.expiryTime >= block.timestamp, "Marketplace: order expired");
    }

    function _cancelBid(
        address _tokenAddress,
        uint256 _tokenId,
        address payable _bidder,
        uint256 _escrowAmount
    ) internal {
        delete bidByOrderId[_tokenAddress][_tokenId];

        _bidder.transfer(_escrowAmount);
        // acceptedToken.safeTransfer(_bidder, _escrowAmount);

        // emit BidCancelled(_bidId);
    }

    function _cancelOrder(
        bytes32 _orderId,
        address _tokenAddress,
        uint256 _tokenId,
        address _seller
    ) internal {
        delete orderByTokenId[_tokenAddress][_tokenId];
        IERC721(_tokenAddress).safeTransferFrom(
            address(this),
            _seller,
            _tokenId
        );

        emit AuctionOrderCancelled(_tokenAddress, _tokenId, _orderId);
        // auctionCancelledEvent(_tokenAddress, _tokenId, _orderId);
    }

    function _cancelFixPriceOrder(
        bytes32 _orderId,
        address _tokenAddress,
        uint256 _tokenId,
        address _seller
    ) internal {
        delete DirectorderByTokenId[_tokenAddress][_tokenId];
        IERC721(_tokenAddress).safeTransferFrom(
            address(this),
            _seller,
            _tokenId
        );

        emit DirectOrderCancelled(_tokenAddress , _tokenId,_orderId);

        // fixPriceCancelledEvent(_tokenAddress, _tokenId, _orderId);

    }

    function _requireERC721(address _tokenAddress)
        internal
        view
        returns (IERC721)
    {
        require(
            _tokenAddress.isContract(),
            "The NFT Address should be a contract"
        );
        require(
            IERC721(_tokenAddress).supportsInterface(_INTERFACE_ID_ERC721),
            "The NFT contract has an invalid ERC721 implementation"
        );
        return IERC721(_tokenAddress);
    }

    function balance() public view onlyOwner returns (uint256) {
        return marketplaceBalance;
    }

    function getFunds(address payable _receiverAddress, uint256 _amount)
        public
        onlyOwner
    {
        require(_amount > 0, "Marketplace: Amount must be greater than zero");
        require(
            _amount < marketplaceBalance,
            "Marketplace: Not enough balance"
        );
        // require(_receiverAddress != address(0), "Marketplace: The receiver address is invalid");
        marketplaceBalance = marketplaceBalance - _amount;
        payable(_receiverAddress).transfer(_amount);
    }
}