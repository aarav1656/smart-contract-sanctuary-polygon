// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

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
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library CountersUpgradeable {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

/**
 * @dev Interface of Escrow contract
 * This contract whill hold the funds for the marketplace, offer, swap until the transaction is completed
*/

interface IEscrow {
  // view
  function balanceOf(address account) external view returns (uint256);
  function allowance(address owner, address spender) external view returns (uint256);

  // for owner
  function setTrusted(address _trusted, bool _isTrusted) external;
  function trusted(address _trusted) external view returns (bool);

  // for market, offer, swap
  function completePayment(address from, address to, uint256 amount) external;

  // for user
  function withdraw(uint256 amount) external;
  function deposit() external payable;
  function depositAndApprove(address spender) external payable;

  function approve(address spender, uint256 amount) external returns (bool);
  function increaseAllowance(address spender, uint256 addedValue) external returns (bool);
  function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);
}

// SPDX-License-Identifier: MIT
// Creator: letieu
pragma solidity ^0.8.4;

interface ISwap {
    struct ItemNFT {
      address tokenAddress;
      uint256 tokenId;
    }

    struct ItemCoin {
      address tokenAddress;
      uint256 amount;
    }

    struct Items {
      ItemNFT[] nfts;
      ItemCoin[] coins;
      uint256 currency;
    }

    function getCreateFee(address user) external view returns (uint256);
    function setCreateFee(uint256 _fee, uint256 _corgiFee) external;
    function setCorgiAddress(address _corgiAddress) external;

    function create(ItemNFT[] calldata nfts, ItemCoin[] calldata coins, uint256 currency) external payable;
    function update(uint256 swapId, ItemNFT[] calldata nfts, ItemCoin[] calldata coins, uint256 currency) external;
    function remove(uint256 swapId) external;
    function accept(uint256 offerId) external payable;

    function offer(uint256 swapId, ItemNFT[] calldata nfts, ItemCoin[] calldata coins, uint256 currency) external;
    function removeOffer(uint256 offerId) external;

    event Created(uint256 indexed swapId, address indexed owner, ItemNFT[] nfts, ItemCoin[] coins, uint256 currency);
    event Updated(uint256 indexed swapId, address indexed owner, ItemNFT[] nfts, ItemCoin[] coins, uint256 currency);
    event Removed(uint256 indexed swapId);
    event Accepted(uint256 indexed offerId);

    event Offered(uint256 indexed offerId, uint256 indexed swapId, address indexed user, ItemNFT[] nfts, ItemCoin[] coins, uint256 currency);
    event OfferRemoved(uint256 indexed offerId);
}

// SPDX-License-Identifier: MIT
// Creator: letieu
pragma solidity ^0.8.7;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./ISwap.sol";
import "./interfaces/IEscrow.sol";

contract Swap is OwnableUpgradeable, ISwap {
    using CountersUpgradeable for CountersUpgradeable.Counter;
    CountersUpgradeable.Counter private _swapIds;
    CountersUpgradeable.Counter private _offerIds;

    // swapId => some info
    mapping(uint256 => uint256) public idToCurrency;
    mapping(uint256 => uint256[]) public idToOfferIds;
    mapping(uint256 => address) public idToOwner;
    mapping(uint256 => bool) public swapOpened;

    // swap items
    mapping(uint256 => ItemNFT[]) public idToItemNfts;
    mapping(uint256 => ItemCoin[]) public idToItemCoins;

    // offerId => some info
    mapping(uint256 => address) public offerIdToUser;
    mapping(uint256 => uint256) public offerIdToSwapId;
    mapping(uint256 => bool) public offerAccepted;
    mapping(uint256 => bool) public offerOpened;

    // offer items
    mapping(uint256 => ItemNFT[]) public offerIdToItemNfts;
    mapping(uint256 => ItemCoin[]) public offerIdToItemCoins;
    mapping(uint256 => uint256) public offerIdToCurrency;

    // settings
    uint256 public fee;
    uint256 public corgiFee;
    address public corgiAddress;
    address feePayee;

    IEscrow public escrow;

    function initialize(
        address _feePayee,
        address _corgiAddress,
        uint256 _fee,
        uint256 _corgiFee
    ) public initializer {
        __Ownable_init();
        feePayee = _feePayee;
        corgiAddress = _corgiAddress;
        fee = _fee;
        corgiFee = _corgiFee;
    }

    function getCreateFee(address user) public view override returns (uint256) {
        bool isCorgiHolder = IERC721(corgiAddress).balanceOf(user) > 0;
        return isCorgiHolder ? corgiFee : fee;
    }

    function setCreateFee(uint256 _fee, uint256 _corgiFee) public override onlyOwner {
        fee = _fee;
        corgiFee = _corgiFee;
    }

    function setCorgiAddress(address _corgiAddress) public override onlyOwner {
        corgiAddress = _corgiAddress;
    }

    function setEscrow(address _escrow) external onlyOwner {
      escrow = IEscrow(_escrow);
    }

    function create(
        ItemNFT[] calldata nfts,
        ItemCoin[] calldata coins,
        uint256 currency
    ) external payable override escrowSet {
        uint256 createFee = getCreateFee(msg.sender);
        require(msg.value == createFee, "Fee is not enough");
        require(nfts.length > 0, "No nft to swap");
        _swapIds.increment();
        uint256 swapId = _swapIds.current();
        idToOwner[swapId] = msg.sender;
        swapOpened[swapId] = true;

        for (uint256 i = 0; i < nfts.length; i++) {
            require(
                IERC721(nfts[i].tokenAddress).ownerOf(nfts[i].tokenId) ==
                    msg.sender,
                "not own NFT"
            );
            idToItemNfts[swapId].push(nfts[i]);
        }

        for (uint256 i = 0; i < coins.length; i++) {
            require(
                IERC20(coins[i].tokenAddress).balanceOf(msg.sender) >=
                    coins[i].amount,
                "not enough coin"
            );
            idToItemCoins[swapId].push(coins[i]);
        }

        idToCurrency[swapId] = currency;
        payable(feePayee).transfer(createFee);
        emit Created(swapId, msg.sender, nfts, coins, currency);
    }

    function update(
      uint256 swapId,
      ItemNFT[] calldata nfts,
      ItemCoin[] calldata coins,
      uint256 currency
    ) external override escrowSet {
      require(nfts.length > 0, "No nft to swap");
      require(idToOwner[swapId] == msg.sender, "not owner");
      require(idToOfferIds[swapId].length == 0, "There are offers");
      for (uint256 i = 0; i < nfts.length; i++) {
          require(
              IERC721(nfts[i].tokenAddress).ownerOf(nfts[i].tokenId) ==
                  msg.sender,
              "not own NFT"
          );
          idToItemNfts[swapId].push(nfts[i]);
      }

      for (uint256 i = 0; i < coins.length; i++) {
          require(
              IERC20(coins[i].tokenAddress).balanceOf(msg.sender) >=
                  coins[i].amount,
              "not enough coin"
          );
          idToItemCoins[swapId].push(coins[i]);
      }

      idToCurrency[swapId] = currency;
      emit Updated(swapId, msg.sender, nfts, coins, currency);
    }

    function remove(uint256 swapId) external override {
        require(idToOwner[swapId] == msg.sender, "You are not the owner");
        swapOpened[swapId] = false;
        emit Removed(swapId);
    }

    function offer(
        uint256 swapId,
        ItemNFT[] calldata nfts,
        ItemCoin[] calldata coins,
        uint256 currency
    ) external override escrowSet {
        require(idToOwner[swapId] != address(0), "swapId not found");
        require(swapOpened[swapId], "swapId is closed");
        require(idToOwner[swapId] != msg.sender, "cannot offer to yourself");
        require(escrow.allowance(msg.sender, address(this)) >= currency, "escrow allowance not match");
        require(nfts.length > 0, "No nft to offer");

        _offerIds.increment();
        uint256 offerId = _offerIds.current();
        offerIdToUser[offerId] = msg.sender;
        offerIdToSwapId[offerId] = swapId;
        idToOfferIds[swapId].push(offerId);
        offerOpened[offerId] = true;

        for (uint256 i = 0; i < nfts.length; i++) {
            require(
                IERC721(nfts[i].tokenAddress).ownerOf(nfts[i].tokenId) ==
                    msg.sender,
                "not own NFT"
            );
            require(
                IERC721(nfts[i].tokenAddress).getApproved(nfts[i].tokenId) ==
                    address(this) ||
                    IERC721(nfts[i].tokenAddress).isApprovedForAll(
                        msg.sender,
                        address(this)
                    ),
                "not approved nfts"
            );

            offerIdToItemNfts[offerId].push(nfts[i]);
        }
        for (uint256 i = 0; i < coins.length; i++) {
            require(
                IERC20(coins[i].tokenAddress).allowance(
                    msg.sender,
                    address(this)
                ) >= coins[i].amount,
                "not enough allowance coins"
            );
            offerIdToItemCoins[offerId].push(coins[i]);
        }
        offerIdToCurrency[offerId] = currency;
        emit Offered(offerId, swapId, msg.sender, nfts, coins, currency);
    }

    function accept(uint256 offerId) external payable override escrowSet {
        require(offerIdToUser[offerId] != address(0), "offerId not found");
        require(!offerAccepted[offerId], "offer already accepted");
        require(offerOpened[offerId], "offer already closed");
        require(
            idToOwner[offerIdToSwapId[offerId]] == msg.sender,
            "not the swap owner"
        );
        require(
            msg.value == idToCurrency[offerIdToSwapId[offerId]],
            "currency not match"
        );

        // transfer nfts from bidder to swap creator
        for (uint256 i = 0; i < offerIdToItemNfts[offerId].length; i++) {
            IERC721(offerIdToItemNfts[offerId][i].tokenAddress).transferFrom(
                offerIdToUser[offerId],
                idToOwner[offerIdToSwapId[offerId]],
                offerIdToItemNfts[offerId][i].tokenId
            );
        }

        // transfer erc20 from bidder to swap creator
        for (uint256 i = 0; i < offerIdToItemCoins[offerId].length; i++) {
            IERC20(offerIdToItemCoins[offerId][i].tokenAddress).transferFrom(
                offerIdToUser[offerId],
                idToOwner[offerIdToSwapId[offerId]],
                offerIdToItemCoins[offerId][i].amount
            );
        }

        // transfer currency from bidder to swap creator
        escrow.completePayment(offerIdToUser[offerId], idToOwner[offerIdToSwapId[offerId]], offerIdToCurrency[offerId]);

        // transfer nfts from swap creator to bidder
        for (
            uint256 i = 0;
            i < idToItemNfts[offerIdToSwapId[offerId]].length;
            i++
        ) {
            IERC721(idToItemNfts[offerIdToSwapId[offerId]][i].tokenAddress)
                .transferFrom(
                    idToOwner[offerIdToSwapId[offerId]],
                    offerIdToUser[offerId],
                    idToItemNfts[offerIdToSwapId[offerId]][i].tokenId
                );
        }

        // transfer erc20 from swap creator to bidder
        for (
            uint256 i = 0;
            i < idToItemCoins[offerIdToSwapId[offerId]].length;
            i++
        ) {
            IERC20(idToItemCoins[offerIdToSwapId[offerId]][i].tokenAddress)
                .transferFrom(
                    idToOwner[offerIdToSwapId[offerId]],
                    offerIdToUser[offerId],
                    idToItemCoins[offerIdToSwapId[offerId]][i].amount
                );
        }

        // transfer currency from swap creator to bidder
        payable(offerIdToUser[offerId]).transfer(
            idToCurrency[offerIdToSwapId[offerId]]
        );

        offerAccepted[offerId] = true;
        offerOpened[offerId] = false;
        swapOpened[offerIdToSwapId[offerId]] = false;
        emit Accepted(offerId);
    }

    function removeOffer(uint256 offerId) external override escrowSet {
        require(offerIdToUser[offerId] == msg.sender, "You are not the bidder");
        offerOpened[offerId] = false;
        emit OfferRemoved(offerId);
    }

    modifier escrowSet() {
      require(address(escrow) != address(0), "escrow is not set");
      _;
    }
}