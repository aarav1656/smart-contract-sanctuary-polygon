/**
 *Submitted for verification at polygonscan.com on 2022-07-26
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

library AddressUpgradeable {
   
    function isContract(address account) internal view returns (bool) {
     

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }


    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }


    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }


    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }


    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }


    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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
abstract contract Initializable {


    bool private _initialized;


    bool private _initializing;

 
    modifier initializer() {
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}


abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address ) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    uint256[49] private __gap;
}

 contract ReentrancyGuardUpgradeable is Initializable {
    
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
        _status = _NOT_ENTERED;
    }


    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

      
        _status = _NOT_ENTERED;
    }
    uint256[49] private __gap;
}

interface ISuperMarketplace {
   
    function offer(
        address _originContract,
        uint256 _tokenId,
        address _currencyAddress,
        uint256 _amount,
        bool _convertible
    ) external payable;

    
    function buy(
        address _originContract,
        uint256 _tokenId,
        address _currencyAddress,
        uint256 _amount
    ) external payable;

    
    function cancelOffer(
        address _originContract,
        uint256 _tokenId,
        address _currencyAddress
    ) external;

   
    function setSalePrice(
        address _originContract,
        uint256 _tokenId,
        address _currencyAddress,
        uint256 _listPrice,
        address _target,
        address payable[] calldata _splitAddresses,
        uint8[] calldata _splitRatios
    ) external;

   
    function removeSalePrice(
        address _originContract,
        uint256 _tokenId,
        address _target
    ) external;


    function acceptOffer(
        address _originContract,
        uint256 _tokenId,
        address _currencyAddress,
        uint256 _amount,
        address payable[] calldata _splitAddresses,
        uint8[] calldata _splitRatios
    ) external;
}


interface IERC165 {

    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}


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

    function ownerOf(uint256 tokenId) external view returns (address owner);


    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    function transferFrom(address from, address to, uint256 tokenId) external;


    function approve(address to, uint256 tokenId) external;

    function getApproved(uint256 tokenId) external view returns (address operator);


    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);


    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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


library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

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
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

interface IMarketplaceSettings {
    /////////////////////////////////////////////////////////////////////////
    // Marketplace Min and Max Values
    /////////////////////////////////////////////////////////////////////////
    /**
     * @dev Get the max value to be used with the marketplace.
     * @return uint256 wei value.
     */
    function getMarketplaceMaxValue() external view returns (uint256);

    /**
     * @dev Get the max value to be used with the marketplace.
     * @return uint256 wei value.
     */
    function getMarketplaceMinValue() external view returns (uint256);

    /////////////////////////////////////////////////////////////////////////
    // Marketplace Fee
    /////////////////////////////////////////////////////////////////////////
    /**
     * @dev Get the marketplace fee percentage.
     * @return uint8 wei fee.
     */
    function getMarketplaceFeePercentage() external view returns (uint8);

    /**
     * @dev Utility function for calculating the marketplace fee for given amount of wei.
     * @param _amount uint256 wei amount.
     * @return uint256 wei fee.
     */
    function calculateMarketplaceFee(uint256 _amount)
        external
        view
        returns (uint256);

    /////////////////////////////////////////////////////////////////////////
    // Primary Sale Fee
    /////////////////////////////////////////////////////////////////////////
    /**
     * @dev Get the primary sale fee percentage for a specific ERC721 contract.
     * @param _contractAddress address ERC721Contract address.
     * @return uint8 wei primary sale fee.
     */
    function getERC721ContractPrimarySaleFeePercentage(address _contractAddress)
        external
        view
        returns (uint8);

    /**
     * @dev Utility function for calculating the primary sale fee for given amount of wei
     * @param _contractAddress address ERC721Contract address.
     * @param _amount uint256 wei amount.
     * @return uint256 wei fee.
     */
    function calculatePrimarySaleFee(address _contractAddress, uint256 _amount)
        external
        view
        returns (uint256);

    /**
     * @dev Check whether the ERC721 token has sold at least once.
     * @param _contractAddress address ERC721Contract address.
     * @param _tokenId uint256 token ID.
     * @return bool of whether the token has sold.
     */
    function hasERC721TokenSold(address _contractAddress, uint256 _tokenId)
        external
        view
        returns (bool);

    /**
     * @dev Mark a token as sold.
     * Requirements:
     *
     * - `_contractAddress` cannot be the zero address.
     * @param _contractAddress address ERC721Contract address.
     * @param _tokenId uint256 token ID.
     * @param _hasSold bool of whether the token should be marked sold or not.
     */
    function markERC721Token(
        address _contractAddress,
        uint256 _tokenId,
        bool _hasSold
    ) external;

    function setERC721ContractPrimarySaleFeePercentage(
        address _contractAddress,
        uint8 _percentage
    ) external;
}

interface IERC721TokenCreator {
    function tokenCreator(address _contractAddress, uint256 _tokenId)
        external
        view
        returns (address payable);
}

interface IERC721CreatorRoyalty is IERC721TokenCreator {
    /**
     * @dev Get the royalty fee percentage for a specific ERC721 contract.
     * @param _contractAddress address ERC721Contract address.
     * @param _tokenId uint256 token ID.
     * @return uint8 wei royalty fee.
     */
    function getERC721TokenRoyaltyPercentage(
        address _contractAddress,
        uint256 _tokenId
    ) external view returns (uint8);

    /**
     * @dev Utililty function to calculate the royalty fee for a token.
     * @param _contractAddress address ERC721Contract address.
     * @param _tokenId uint256 token ID.
     * @param _amount uint256 wei amount.
     * @return uint256 wei fee.
     */
    function calculateRoyaltyFee(
        address _contractAddress,
        uint256 _tokenId,
        uint256 _amount
    ) external view returns (uint256);

    /**
     * @dev Utililty function to set the royalty percentage for a specific ERC721 contract.
     * @param _contractAddress address ERC721Contract address.
     * @param _percentage percentage for royalty
     */
    function setPercentageForSetERC721ContractRoyalty(
        address _contractAddress,
        uint8 _percentage
    ) external;
}


interface IPayments {
    function refund(address _payee, uint256 _amount) external payable;

    function payout(address[] calldata _splits, uint256[] calldata _amounts)
        external
        payable;
}

interface ISpaceOperatorRegistry {
    function getPlatformCommission(address _operator)
        external
        view
        returns (uint8);

    function setPlatformCommission(address _operator, uint8 _commission)
        external;

    function isApprovedSpaceOperator(address _operator)
        external
        view
        returns (bool);

    function setSpaceOperatorApproved(address _operator, bool _approved)
        external;
}


interface IApprovedTokenRegistry {
    /// @notice Returns if a token has been approved or not.
    /// @param _tokenContract Contract of token being checked.
    /// @return True if the token is allowed, false otherwise.
    function isApprovedToken(address _tokenContract)
        external
        view
        returns (bool);

    /// @notice Adds a token to the list of approved tokens.
    /// @param _tokenContract Contract of token being approved.
    function addApprovedToken(address _tokenContract) external;

    /// @notice Removes a token from the approved tokens list.
    /// @param _tokenContract Contract of token being approved.
    function removeApprovedToken(address _tokenContract) external;

    /// @notice Sets whether all token contracts should be approved.
    /// @param _allTokensApproved Bool denoting if all tokens should be approved.
    function setAllTokensApproved(bool _allTokensApproved) external;
}

interface IRoyaltyEngineV1 {
    /**
     * Get the royalty for a given token (address, id) and value amount.  Does not cache the bps/amounts.  Caches the spec for a given token address
     *
     * @param tokenAddress - The address of the token
     * @param tokenId      - The id of the token
     * @param value        - The value you wish to get the royalty of
     *
     * returns Two arrays of equal length, royalty recipients and the corresponding amount each recipient should get
     */
    function getRoyalty(
        address tokenAddress,
        uint256 tokenId,
        uint256 value
    )
        external
        returns (address payable[] memory recipients, uint256[] memory amounts);

    /**
     * View only version of getRoyalty
     *
     * @param tokenAddress - The address of the token
     * @param tokenId      - The id of the token
     * @param value        - The value you wish to get the royalty of
     *
     * returns Two arrays of equal length, royalty recipients and the corresponding amount each recipient should get
     */
    function getRoyaltyView(
        address tokenAddress,
        uint256 tokenId,
        uint256 value
    )
        external
        view
        returns (address payable[] memory recipients, uint256[] memory amounts);
}

/// @author koloz
/// @title SuperRareBazaar Storage Contract
/// @dev STORAGE CAN ONLY BE APPENDED NOT INSERTED OR MODIFIED
contract SuperRareBazaarStorage {
    /////////////////////////////////////////////////////////////////////////
    // Constants
    /////////////////////////////////////////////////////////////////////////

    // Auction Types
    bytes32 public constant COLDIE_AUCTION = "COLDIE_AUCTION";
    bytes32 public constant SCHEDULED_AUCTION = "SCHEDULED_AUCTION";
    bytes32 public constant NO_AUCTION = bytes32(0);

    /////////////////////////////////////////////////////////////////////////
    // Structs
    /////////////////////////////////////////////////////////////////////////

    // The Offer truct for a given token:
    // buyer - address of person making the offer
    // currencyAddress - address of the erc20 token used for an offer
    //                   or the zero address for eth
    // amount - offer in wei/full erc20 value
    // marketplaceFee - the amount that is taken by the network on offer acceptance.
    struct Offer {
        address payable buyer;
        uint256 amount;
        uint256 timestamp;
        uint8 marketplaceFee;
        bool convertible;
    }

    // The Sale Price struct for a given token:
    // seller - address of the person selling the token
    // currencyAddress - address of the erc20 token used for an offer
    //                   or the zero address for eth
    // amount - offer in wei/full erc20 value
    struct SalePrice {
        address payable seller;
        address currencyAddress;
        uint256 amount;
        address payable[] splitRecipients;
        uint8[] splitRatios;
    }

    // Structure of an Auction:
    // auctionCreator - creator of the auction
    // creationBlock - time that the auction was created/configured
    // startingBlock - time that the auction starts on
    // lengthOfAuction - how long the auction is
    // currencyAddress - address of the erc20 token used for an offer
    //                   or the zero address for eth
    // minimumBid - min amount a bidder can bid at the start of an auction.
    // auctionType - type of auction, represented as the formatted bytes 32 string
    struct Auction {
        address payable auctionCreator;
        uint256 creationBlock;
        uint256 startingTime;
        uint256 lengthOfAuction;
        address currencyAddress;
        uint256 minimumBid;
        bytes32 auctionType;
        address payable[] splitRecipients;
        uint8[] splitRatios;
    }

    struct Bid {
        address payable bidder;
        address currencyAddress;
        uint256 amount;
        uint8 marketplaceFee;
    }

    /////////////////////////////////////////////////////////////////////////
    // Events
    /////////////////////////////////////////////////////////////////////////
    event Sold(
        address indexed _originContract,
        address indexed _buyer,
        address indexed _seller,
        address _currencyAddress,
        uint256 _amount,
        uint256 _tokenId
    );

    event SetSalePrice(
        address indexed _originContract,
        address indexed _currencyAddress,
        address _target,
        uint256 _amount,
        uint256 _tokenId,
        address payable[] _splitRecipients,
        uint8[] _splitRatios
    );

    event OfferPlaced(
        address indexed _originContract,
        address indexed _bidder,
        address indexed _currencyAddress,
        uint256 _amount,
        uint256 _tokenId,
        bool _convertible
    );

    event AcceptOffer(
        address indexed _originContract,
        address indexed _bidder,
        address indexed _seller,
        address _currencyAddress,
        uint256 _amount,
        uint256 _tokenId,
        address payable[] _splitAddresses,
        uint8[] _splitRatios
    );

    event CancelOffer(
        address indexed _originContract,
        address indexed _bidder,
        address indexed _currencyAddress,
        uint256 _amount,
        uint256 _tokenId
    );

    event NewAuction(
        address indexed _contractAddress,
        uint256 indexed _tokenId,
        address indexed _auctionCreator,
        address _currencyAddress,
        uint256 _startingTime,
        uint256 _minimumBid,
        uint256 _lengthOfAuction
    );

    event CancelAuction(
        address indexed _contractAddress,
        uint256 indexed _tokenId,
        address indexed _auctionCreator
    );

    event AuctionBid(
        address indexed _contractAddress,
        address indexed _bidder,
        uint256 indexed _tokenId,
        address _currencyAddress,
        uint256 _amount,
        bool _startedAuction,
        uint256 _newAuctionLength,
        address _previousBidder
    );

    event AuctionSettled(
        address indexed _contractAddress,
        address indexed _bidder,
        address _seller,
        uint256 indexed _tokenId,
        address _currencyAddress,
        uint256 _amount
    );

    /////////////////////////////////////////////////////////////////////////
    // State Variables
    /////////////////////////////////////////////////////////////////////////

    // Current marketplace settings implementation to be used
    IMarketplaceSettings public marketplaceSettings;

    // Current creator royalty implementation to be used
    IERC721CreatorRoyalty public royaltyRegistry;

    // Address of the global royalty engine being used.
    IRoyaltyEngineV1 public royaltyEngine;

    // Current SuperRareMarketplace implementation to be used
    address public superRareMarketplace;

    // Current SuperRareAuctionHouse implementation to be used
    address public superRareAuctionHouse;

    // Current SpaceOperatorRegistry implementation to be used.
    ISpaceOperatorRegistry public spaceOperatorRegistry;

    // Current ApprovedTokenRegistry implementation being used for currencies.
    IApprovedTokenRegistry public approvedTokenRegistry;

    // Current payments contract to use
    IPayments public payments;

    // Address to be used for staking registry.
    address public stakingRegistry;

    // Address of the network beneficiary
    address public networkBeneficiary;

    // A minimum increase in bid amount when out bidding someone.
    uint8 public minimumBidIncreasePercentage; // 10 = 10%

    // Maximum length that an auction can be.
    uint256 public maxAuctionLength;

    // Extension length for an auction
    uint256 public auctionLengthExtension;

    // Offer cancellation delay
    uint256 public offerCancelationDelay;

    // Mapping from contract to mapping of tokenId to mapping of target to sale price.
    mapping(address => mapping(uint256 => mapping(address => SalePrice)))
        public tokenSalePrices;

    // Mapping from contract to mapping of tokenId to mapping of currency address to Current Offer.
    mapping(address => mapping(uint256 => mapping(address => Offer)))
        public tokenCurrentOffers;

    // Mapping from contract to mapping of tokenId to Auction.
    mapping(address => mapping(uint256 => Auction)) public tokenAuctions;

    // Mapping from contract to mapping of tokenId to Bid.
    mapping(address => mapping(uint256 => Bid)) public auctionBids;

    uint256[50] private __gap;
    /// ALL NEW STORAGE MUST COME AFTER THIS
}

/// @author koloz
/// @title SuperRareBazaarBase
/// @notice Base contract containing the internal functions for the SuperRareBazaar.
 contract SuperRareBazaarBase is SuperRareBazaarStorage {
    using SafeMath for uint256;
    using SafeMath for uint8;
    using SafeERC20 for IERC20;

    /////////////////////////////////////////////////////////////////////////
    // Internal Functions
    /////////////////////////////////////////////////////////////////////////

    /// @notice Checks to see if the currenccy address is eth or an approved erc20 token.
    /// @param _currencyAddress Address of currency (Zero address if eth).
    function _checkIfCurrencyIsApproved(address _currencyAddress)
        internal
        view
    {
        require(
            _currencyAddress == address(0) ||
                approvedTokenRegistry.isApprovedToken(_currencyAddress),
            "Not approved currency"
        );
    }

    /// @notice Checks to see if the owner of the token has the marketplace approved.
    /// @param _originContract Contract address of the token being checked.
    /// @param _tokenId Token Id of the asset.
    function _ownerMustHaveMarketplaceApprovedForNFT(
        address _originContract,
        uint256 _tokenId
    ) internal view {
        IERC721 erc721 = IERC721(_originContract);
        address owner = erc721.ownerOf(_tokenId);
        require(
            erc721.isApprovedForAll(owner, address(this)),
            "owner must have approved contract"
        );
    }

    /// @notice Checks to see if the msg sender owns the token.
    /// @param _originContract Contract address of the token being checked.
    /// @param _tokenId Token Id of the asset.
    function _senderMustBeTokenOwner(address _originContract, uint256 _tokenId)
        internal
        view
    {
        IERC721 erc721 = IERC721(_originContract);
        require(
            erc721.ownerOf(_tokenId) == msg.sender,
            "sender must be the token owner"
        );
    }

    /// @notice Verifies that the splits supplied are valid.
    /// @dev A valid split has the same number of splits and ratios.
    /// @dev There can only be a max of 5 parties split with.
    /// @dev Total of the ratios should be 100 which is relative.
    /// @param _splits The addresses the amount is being split with.
    /// @param _ratios The ratios each address in _splits is getting.
    function _checkSplits(
        address payable[] calldata _splits,
        uint8[] calldata _ratios
    ) internal pure {
        require(_splits.length > 0, "checkSplits::Must have at least 1 split");
        require(_splits.length <= 5, "checkSplits::Split exceeded max size");
        require(
            _splits.length == _ratios.length,
            "checkSplits::Splits and ratios must be equal"
        );
        uint256 totalRatio = 0;

        for (uint256 i = 0; i < _ratios.length; i++) {
            totalRatio += _ratios[i];
        }

        require(totalRatio == 100, "checkSplits::Total must be equal to 100");
    }

    /// @notice Checks to see if the sender has approved the marketplace to move tokens.
    /// @dev This is for offers/buys/bids and the allowance of erc20 tokens.
    /// @dev Returns on zero address because no allowance is needed for eth.
    /// @param _contract The address of the currency being checked.
    /// @param _amount The total amount being checked.
    function _senderMustHaveMarketplaceApproved(
        address _contract,
        uint256 _amount
    ) internal view {
        if (_contract == address(0)) {
            return;
        }

        IERC20 erc20 = IERC20(_contract);

        require(
            erc20.allowance(msg.sender, address(this)) >= _amount,
            "sender needs to approve marketplace for currency"
        );
    }

    /// @notice Checks the user has the correct amount and transfers to the marketplace.
    /// @dev If the currency used is eth (zero address) the msg value is checked.
    /// @dev If eth isnt used and eth is sent we revert the txn.
    /// @dev We need to check this contracts balance before and after the transfer to ensure no fee.
    /// @param _currencyAddress Currency address being checked and transfered.
    /// @param _amount Total amount of currency.
    function _checkAmountAndTransfer(address _currencyAddress, uint256 _amount)
        internal
    {
        if (_currencyAddress == address(0)) {
            require(msg.value == _amount, "not enough eth sent");
            return;
        }

        require(msg.value == 0, "msg.value should be 0 when not using eth");

        IERC20 erc20 = IERC20(_currencyAddress);
        uint256 balanceBefore = erc20.balanceOf(address(this));

        erc20.safeTransferFrom(msg.sender, address(this), _amount);

        uint256 balanceAfter = erc20.balanceOf(address(this));

        require(
            balanceAfter.sub(balanceBefore) == _amount,
            "not enough tokens transfered"
        );
    }

    /// @notice Refunds an address the designated amount.
    /// @dev Return if amount being refunded is zero.
    /// @dev Forwards to payment contract if eth is being refunded.
    /// @param _currencyAddress Address of currency being refunded.
    /// @param _amount Amount being refunded.
    /// @param _marketplaceFee Marketplace Fee (percentage) paid by _recipient.
    /// @param _recipient Address amount is being refunded to.
    function _refund(
        address _currencyAddress,
        uint256 _amount,
        uint256 _marketplaceFee,
        address _recipient
    ) internal {
        if (_amount == 0) {
            return;
        }

        uint256 requiredAmount = _amount.add(
            _amount.mul(_marketplaceFee).div(100)
        );

        if (_currencyAddress == address(0)) {
            (bool success, bytes memory data) = address(payments).call{
                value: requiredAmount
            }(
                abi.encodeWithSignature(
                    "refund(address,uint256)",
                    _recipient,
                    requiredAmount
                )
            );

            require(success, string(data));
            return;
        }

        IERC20 erc20 = IERC20(_currencyAddress);
        erc20.safeTransfer(_recipient, requiredAmount);
    }

    /// @notice Sends a payout to all the necessary parties.
    /// @dev Sends payments to the network, royalty if applicable, and splits for the rest.
    /// @dev Forwards payments to the payment contract if payout is happening in eth.
    /// @dev Total amount of ratios should be 100 and is relative to the total ratio left.
    /// @param _originContract Contract address of asset triggering a payout.
    /// @param _tokenId Token Id of the asset.
    /// @param _currencyAddress Address of currency being paid out.
    /// @param _amount Total amount to be paid out.
    /// @param _seller Address of the person selling the asset.
    /// @param _splitAddrs Addresses that funds need to be split against.
    /// @param _splitRatios Ratios for split pertaining to each address.
    function _payout(
        address _originContract,
        uint256 _tokenId,
        address _currencyAddress,
        uint256 _amount,
        address _seller,
        address payable[] memory _splitAddrs,
        uint8[] memory _splitRatios
    ) internal {
        require(
            _splitAddrs.length == _splitRatios.length,
            "Number of split addresses and ratios must be equal."
        );

        /*
        The overall flow for payouts is:
            1. Payout marketplace fee
            2. Primary/Secondary Payouts
                a. Primary -> If space sale, query space operator registry for platform comission and payout
                              Else query marketplace setting for primary sale comission and payout
                b. Secondary -> Query global royalty registry for recipients and amounts and payout
            3. Calculate the amount for each _splitAddr based on remaining amount and payout
         */

        uint256 remainingAmount = _amount;

        // Marketplace fee
        uint256 marketplaceFee = marketplaceSettings.calculateMarketplaceFee(
            _amount
        );

        address payable[] memory mktFeeRecip = new address payable[](1);
        mktFeeRecip[0] = payable(networkBeneficiary);
        uint256[] memory mktFee = new uint256[](1);
        mktFee[0] = marketplaceFee;

        _performPayouts(_currencyAddress, marketplaceFee, mktFeeRecip, mktFee);

        if (
            !marketplaceSettings.hasERC721TokenSold(_originContract, _tokenId)
        ) {
            uint256[] memory platformFee = new uint256[](1);

            if (spaceOperatorRegistry.isApprovedSpaceOperator(_seller)) {
                uint256 platformCommission = spaceOperatorRegistry
                    .getPlatformCommission(_seller);

                remainingAmount = remainingAmount.sub(
                    _amount.mul(platformCommission).div(100)
                );

                platformFee[0] = _amount.mul(platformCommission).div(100);

                _performPayouts(
                    _currencyAddress,
                    platformFee[0],
                    mktFeeRecip,
                    platformFee
                );
            } else {
                uint256 platformCommission = marketplaceSettings
                    .getERC721ContractPrimarySaleFeePercentage(_originContract);

                remainingAmount = remainingAmount.sub(
                    _amount.mul(platformCommission).div(100)
                );

                platformFee[0] = _amount.mul(platformCommission).div(100);

                _performPayouts(
                    _currencyAddress,
                    platformFee[0],
                    mktFeeRecip,
                    platformFee
                );
            }
        } else {
            (
                address payable[] memory receivers,
                uint256[] memory royalties
            ) = royaltyEngine.getRoyalty(_originContract, _tokenId, _amount);

            uint256 totalRoyalties = 0;

            for (uint256 i = 0; i < royalties.length; i++) {
                totalRoyalties = totalRoyalties.add(royalties[i]);
            }

            remainingAmount = remainingAmount.sub(totalRoyalties);
            _performPayouts(
                _currencyAddress,
                totalRoyalties,
                receivers,
                royalties
            );
        }

        uint256[] memory remainingAmts = new uint256[](_splitAddrs.length);

        uint256 totalSplit = 0;

        for (uint256 i = 0; i < _splitAddrs.length; i++) {
            remainingAmts[i] = remainingAmount.mul(_splitRatios[i]).div(100);
            totalSplit = totalSplit.add(
                remainingAmount.mul(_splitRatios[i]).div(100)
            );
        }
        _performPayouts(
            _currencyAddress,
            totalSplit,
            _splitAddrs,
            remainingAmts
        );
    }

    function _performPayouts(
        address _currencyAddress,
        uint256 _amount,
        address payable[] memory _recipients,
        uint256[] memory _amounts
    ) internal {
        if (_currencyAddress == address(0)) {
            (bool success, bytes memory data) = address(payments).call{
                value: _amount
            }(
                abi.encodeWithSelector(
                    IPayments.payout.selector,
                    _recipients,
                    _amounts
                )
            );

            require(success, string(data));
        } else {
            IERC20 erc20 = IERC20(_currencyAddress);

            for (uint256 i = 0; i < _recipients.length; i++) {
                erc20.safeTransfer(_recipients[i], _amounts[i]);
            }
        }
    }
}


contract SuperRareMarketplace is
    ISuperMarketplace,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    SuperRareBazaarBase
{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /////////////////////////////////////////////////////////////////////////
    // Initializer
    /////////////////////////////////////////////////////////////////////////
    function initialize(
        address _marketplaceSettings,
      //  address _royaltyEngine,
      //  address _royaltyRegistry,
        address _spaceOperatorRegistry,
        address _approvedTokenRegistry,
        address _payments,
       // address _stakingRegistry,
        address _networkBeneficiary
    ) public initializer {
        require(_marketplaceSettings != address(0));
     //   require(_royaltyRegistry != address(0));
     // require(_royaltyEngine != address(0));
        require(_spaceOperatorRegistry != address(0));
        require(_approvedTokenRegistry != address(0));
        require(_payments != address(0));
        require(_networkBeneficiary != address(0));

        marketplaceSettings = IMarketplaceSettings(_marketplaceSettings);
     //   royaltyRegistry = IERC721CreatorRoyalty(_royaltyRegistry);
      //  royaltyEngine = IRoyaltyEngineV1(_royaltyEngine);
        spaceOperatorRegistry = ISpaceOperatorRegistry(_spaceOperatorRegistry);
        approvedTokenRegistry = IApprovedTokenRegistry(_approvedTokenRegistry);
        payments = IPayments(_payments);
    //    stakingRegistry = _stakingRegistry;
        networkBeneficiary = _networkBeneficiary;

        minimumBidIncreasePercentage = 10;
        maxAuctionLength = 7 days;
        auctionLengthExtension = 15 minutes;
        offerCancelationDelay = 5 minutes;

        __Ownable_init();
        __ReentrancyGuard_init();
    }

    
    function offer(
        address _originContract,
        uint256 _tokenId,
        address _currencyAddress,
        uint256 _amount,
        bool _convertible
    ) external payable override nonReentrant {
        _checkIfCurrencyIsApproved(_currencyAddress);
        require(_amount > 0, "offer::Amount cannot be 0");

        Offer memory currOffer = tokenCurrentOffers[_originContract][_tokenId][
            _currencyAddress
        ];

        require(
            _amount >=
                currOffer.amount.add(
                    currOffer.amount.mul(minimumBidIncreasePercentage).div(100)
                ),
            "offer::Must be greater than prev offer + min increase"
        );

        uint256 requiredAmount = _amount.add(
            marketplaceSettings.calculateMarketplaceFee(_amount)
        );

        _senderMustHaveMarketplaceApproved(_currencyAddress, requiredAmount);

        _checkAmountAndTransfer(_currencyAddress, requiredAmount);

        IERC721 erc721 = IERC721(_originContract);
        require(
            erc721.ownerOf(_tokenId) != msg.sender,
            "offer::Offer cannot come from owner"
        );

        _refund(
            _currencyAddress,
            currOffer.amount,
            currOffer.marketplaceFee,
            currOffer.buyer
        );

        tokenCurrentOffers[_originContract][_tokenId][_currencyAddress] = Offer(
            payable(msg.sender)  ,
            _amount,
            block.timestamp,
            marketplaceSettings.getMarketplaceFeePercentage(),
            _convertible
        );

        emit OfferPlaced(
            _originContract,
            msg.sender,
            _currencyAddress,
            _amount,
            _tokenId,
            _convertible
        );
    }

   
    function buy(
        address _originContract,
        uint256 _tokenId,
        address _currencyAddress,
        uint256 _amount
    ) external payable override nonReentrant {
        _ownerMustHaveMarketplaceApprovedForNFT(_originContract, _tokenId);

        uint256 requiredAmount = _amount.add(
            marketplaceSettings.calculateMarketplaceFee(_amount)
        );

        mapping(address => SalePrice) storage salePrices = tokenSalePrices[
            _originContract
        ][_tokenId];

        SalePrice memory sp = salePrices[msg.sender].amount != 0
            ? salePrices[msg.sender]
            : salePrices[address(0)];

        require(sp.amount > 0, "buy::Token has no buy now price");

        IERC721 erc721 = IERC721(_originContract);
        address tokenOwner = erc721.ownerOf(_tokenId);

        require(tokenOwner == sp.seller, "buy::Price setter not owner");

        require(_amount == sp.amount, "buy::Insufficient amount");

        delete tokenSalePrices[_originContract][_tokenId][msg.sender];
        delete tokenSalePrices[_originContract][_tokenId][address(0)];

        _checkAmountAndTransfer(_currencyAddress, requiredAmount);

        Offer memory currOffer = tokenCurrentOffers[_originContract][_tokenId][
            _currencyAddress
        ];

        if (currOffer.buyer == msg.sender) {
            delete tokenCurrentOffers[_originContract][_tokenId][
                _currencyAddress
            ];

            _refund(
                _currencyAddress,
                currOffer.amount,
                currOffer.marketplaceFee,
                msg.sender
            );
        }

        erc721.safeTransferFrom(tokenOwner, msg.sender, _tokenId);

        _payout(
            _originContract,
            _tokenId,
            _currencyAddress,
            _amount,
            sp.seller,
            sp.splitRecipients,
            sp.splitRatios
        );

        marketplaceSettings.markERC721Token(_originContract, _tokenId, true);

        emit Sold(
            _originContract,
            msg.sender,
            sp.seller,
            _currencyAddress,
            _amount,
            _tokenId
        );
    }


    function cancelOffer(
        address _originContract,
        uint256 _tokenId,
        address _currencyAddress
    ) external override nonReentrant {
        Offer memory currOffer = tokenCurrentOffers[_originContract][_tokenId][
            _currencyAddress
        ];

        require(
            currOffer.amount != 0,
            "cancelOffer::No offer for currency exists."
        );

        require(
            currOffer.buyer == msg.sender,
            "cancelOffer::Sender must have placed the offer."
        );

        require(
            block.timestamp - currOffer.timestamp > offerCancelationDelay,
            "Offer placed too recently."
        );

        delete tokenCurrentOffers[_originContract][_tokenId][_currencyAddress];

        _refund(
            _currencyAddress,
            currOffer.amount,
            currOffer.marketplaceFee,
            currOffer.buyer
        );

        emit CancelOffer(
            _originContract,
            msg.sender,
            _currencyAddress,
            currOffer.amount,
            _tokenId
        );
    }

    function setSalePrice(
        address _originContract,
        uint256 _tokenId,
        address _currencyAddress,
        uint256 _listPrice,
        address _target,
        address payable[] calldata _splitAddresses,
        uint8[] calldata _splitRatios
    ) external override {
        _checkIfCurrencyIsApproved(_currencyAddress);
        _senderMustBeTokenOwner(_originContract, _tokenId);
        _ownerMustHaveMarketplaceApprovedForNFT(_originContract, _tokenId);
        _checkSplits(_splitAddresses, _splitRatios);

        tokenSalePrices[_originContract][_tokenId][_target] = SalePrice(
            payable(msg.sender),
            _currencyAddress,
            _listPrice,
            _splitAddresses,
            _splitRatios
        );

        emit SetSalePrice(
            _originContract,
            _currencyAddress,
            _target,
            _listPrice,
            _tokenId,
            _splitAddresses,
            _splitRatios
        );
    }

    function removeSalePrice(
        address _originContract,
        uint256 _tokenId,
        address _target
    ) external override {
        IERC721 erc721 = IERC721(_originContract);
        address tokenOwner = erc721.ownerOf(_tokenId);

        require(
            msg.sender == tokenOwner,
            "removeSalePrice::Must be tokenOwner."
        );

        delete tokenSalePrices[_originContract][_tokenId][_target];

        emit SetSalePrice(
            _originContract,
            address(0),
            address(0),
            0,
            _tokenId,
            new address payable[](0),
            new uint8[](0)
        );
    }


    function acceptOffer(
        address _originContract,
        uint256 _tokenId,
        address _currencyAddress,
        uint256 _amount,
        address payable[] calldata _splitAddresses,
        uint8[] calldata _splitRatios
    ) external override nonReentrant {
        _senderMustBeTokenOwner(_originContract, _tokenId);
        _ownerMustHaveMarketplaceApprovedForNFT(_originContract, _tokenId);
        _checkSplits(_splitAddresses, _splitRatios);

        Offer memory currOffer = tokenCurrentOffers[_originContract][_tokenId][
            _currencyAddress
        ];

        require(currOffer.amount != 0, "acceptOffer::No offer exists");

        require(
            currOffer.amount == _amount,
            "acceptOffer::Offer amount or currency not equal"
        );

        delete tokenSalePrices[_originContract][_tokenId][address(0)];

        delete tokenCurrentOffers[_originContract][_tokenId][_currencyAddress];

        IERC721 erc721 = IERC721(_originContract);
        erc721.safeTransferFrom(msg.sender, currOffer.buyer, _tokenId);

        _payout(
            _originContract,
            _tokenId,
            _currencyAddress,
            _amount,
            msg.sender,
            _splitAddresses,
            _splitRatios
        );

        marketplaceSettings.markERC721Token(_originContract, _tokenId, true);

        emit AcceptOffer(
            _originContract,
            currOffer.buyer,
            msg.sender,
            _currencyAddress,
            _amount,
            _tokenId,
            _splitAddresses,
            _splitRatios
        );
    }
}