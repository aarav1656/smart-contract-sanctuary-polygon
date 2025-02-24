/**
 *Submitted for verification at polygonscan.com on 2022-08-19
*/

/**
 *Submitted for verification at polygonscan.com on 2022-08-16
*/

/**
 *Submitted for verification at polygonscan.com on 2022-08-12
*/

/**
 *Submitted for verification at polygonscan.com on 2022-08-11
*/

/**
 *Submitted for verification at polygonscan.com on 2022-08-09
*/

/**
 *Submitted for verification at polygonscan.com on 2022-08-05
*/

// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

// import "hardhat/console.sol";

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

// File: @openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;


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

// File: @openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol


// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// File: staek.sol


// File: @openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;


/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

// File: @openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;


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


// File: @openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol


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

// File: @openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;



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

// File: staek.sol

/**
 *Submitted for verification at polygonscan.com on 2022-07-29
*/

/**
 *Submitted for verification at polygonscan.com on 2022-07-16
*/

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol

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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// File: stakePool.sol

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
interface IGovernanceNFT is IERC721 {
    function mintTokens(address _to, uint tokenId, string memory uri) external;
    function burnTokens(uint tokenId) external;
}
interface IPool {
    function DistributePLXR(address _to, uint _amount ) external;
}

contract  MetaplexarGovernance is ReentrancyGuardUpgradeable,OwnableUpgradeable {

        struct nftDetails {
                uint poolId;
                uint termId;
                uint weightageEquivalent;
                uint stakeAmount;
                uint stakeTime;
                uint lastClaimTime;
                address _currentOwner;
                 uint unStakeTime;
        }

        struct getGovernance{
            uint totalWeightagePerPool;
            uint totalPLXRStaked;
        }

        IERC20Upgradeable public token;
        string private note;
        // uint public rewardsTax;
        address public insuranceFundAddress=0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2;
        uint public rebaseTime = 1 minutes;
        uint public UnstakeLockTime;
        address[4] public TreasuryPools;
        address l=0x557014ad7322bb5DfeAC31F5bEFADe462012a4BD;
        address[4] public governanceTokenAddress;
        uint[4] public nftIndexPerPool = [0,0,0,0];
        uint[4] public aprPercent = [0,50,100,150]; //2.5%,5%,10%
        uint[4] public investmentDistribution=[0,40,40,20];

        // tokenId => poolId => nftDetails
        mapping (uint =>  mapping( uint => nftDetails)) public detailsPerNftId;
        mapping (uint => mapping (address => uint)) poolMapper;
        mapping (address => bool) public authorisedCaller;
        // user => tokenAddress => poolId => termId
        mapping (address => mapping(uint => uint)) public currentTermIdForUserPerPool;
        //get invested amount in Each pool
        mapping(uint=>uint) public totalInvestedInEachPool;
        // total funds in treasuryPool
        mapping(uint=>uint) public totalTreasuryFunds;
        // total funds in Rewards
        mapping(uint=>uint) public totalrewardFunds;
        // total funds in marketing
        mapping(uint=>uint) public totalMarketingFunds;
        //track rewards using userAddress and poolId
        mapping(address =>mapping(uint=>uint)) public givenRewards;
        //Rewards giveAway per pool
        mapping(uint=>uint) public totalPoolRewards;
        //user Confirmed Unstaking
        mapping(address=>mapping(uint=>mapping(uint=>bool))) public IsConfirmedUnstaking;
        //Rewards of a user
        mapping(address=>mapping(uint=>mapping(uint=>uint))) public userTotalRewards;
        //Unstake Confirmed Time
        mapping(address=>mapping(uint=>mapping(uint=>uint))) public unStakeConfirmedTime;
        //total unstakeConfirmed users per pool
        mapping(uint=>uint) public totalUnstakeConfirmed;
        // remaining rewards after claim Rewards
        mapping(uint=>mapping(uint=>uint)) public remainningRewards;
        // toal Weightage of user
        mapping(address=>mapping(uint=>uint)) private getUserTotalVotes;
        mapping(address=>mapping(uint=>uint)) private totalStakedAmount;
        // events
        mapping(address=>mapping(uint=>getGovernance)) public totalGovernanceWeightage;
        // get total Rewards per pool
        mapping(uint=>uint) public totalRewardsPerPool;
        //get Total weightage per pool
        mapping(uint=>uint) public totalWeightagePerpool;
       // total number of votes in each  pool
       mapping(uint=>uint) private totalVotesEachPool;
       // user votes details
       mapping(address=>mapping(uint=>bool)) private isVotes;
        event Deposit(address from,  address to, uint amount, uint poolID, uint tokenId);
     
        
        function intialize(address _tokenAddress, address _insuranceFundAddress) external initializer{
            token=IERC20Upgradeable(_tokenAddress);
            insuranceFundAddress=_insuranceFundAddress;
            __Ownable_init();
             __ReentrancyGuard_init();
     
        }
        event Treasury(address _from, address _to,uint amount);
        event Rewards(address _from, address _to,uint amount);
        event Marketing(address _from, address _to,uint amount);
        event Unstake(address _user, uint PoolId,uint TokenId, uint amount);
        event ConfirmUnstake(address userAddress,uint poolId, uint tokenId);


        function deposit(uint poolId, uint amount,string memory __uri)external{
                logic(poolId, amount,true,0, __uri);
        }

        function investBack(uint poolId, uint _nftId,uint desiredPool,uint _amount, string memory __uri) external {
         uint amount= getRewardDetails(poolId, _nftId);// 32600000000000000000
         require(!IsConfirmedUnstaking[msg.sender][poolId][_nftId],"User Confirmed unstaking");
          require(_amount<=amount,"not Enough balance");
          uint remainAmount=amount-_amount;
          require(detailsPerNftId[_nftId][poolId]._currentOwner==msg.sender,"!NFT Owner");
          logic(desiredPool,_amount,false,poolId,__uri);
          detailsPerNftId[_nftId][poolId].lastClaimTime=block.timestamp;
          remainningRewards[poolId][_nftId]=remainAmount;
          totalRewardsPerPool[poolId]-=_amount;
        }

        function logic (uint poolId,uint tokenAmounts,bool status, uint actualOne, string memory _uri) internal nonReentrant {
                require (poolId > 0 && poolId < 4, 'Error: Invalid Pool Ids');
                uint tokenAmount = (tokenAmounts / 1 ether);
                uint termId = ++currentTermIdForUserPerPool[msg.sender][poolId];
               
                uint currentIndexOfPool = nftIndexPerPool[poolId]+1;
                uint weightageEquivalent=tokenAmounts/100;
                ++nftIndexPerPool[poolId];
                uint pool=poolId;
                poolMapper[currentIndexOfPool][governanceTokenAddress[poolId]] = poolId;
                totalStakedAmount[msg.sender][poolId]+=tokenAmount;
                getUserTotalVotes[msg.sender][poolId]+=weightageEquivalent;

                 getGovernance memory users;
                 users.totalWeightagePerPool=getUserTotalVotes[msg.sender][poolId];
                 users.totalPLXRStaked=totalStakedAmount[msg.sender][poolId];
                 totalGovernanceWeightage[msg.sender][pool]=users;
                if(!isVotes[msg.sender][poolId]){
                     totalVotesEachPool[poolId]++;
                }
                isVotes[msg.sender][poolId]=true;

                (uint treasury,uint insuranceAmount,uint rewards, uint  marketing)=getDistributionRate(tokenAmounts);
                if ((poolId== 1) || (actualOne==1)) {
                        treasury -= insuranceAmount;
                        if(status){
                        token.transferFrom(msg.sender, insuranceFundAddress, insuranceAmount);
                        }
                        else{

                          IPool(TreasuryPools[actualOne]).DistributePLXR(insuranceFundAddress,insuranceAmount);  
                        }
                } 

                uint total=tokenAmounts-insuranceAmount;
                totalInvestedInEachPool[pool]+=total; 
                 totalTreasuryFunds[pool]+=treasury;
                 totalrewardFunds[pool]+=rewards;
                 totalMarketingFunds[pool]+=marketing;
                nftDetails storage details = detailsPerNftId[currentIndexOfPool][pool];
                details.poolId =pool;
                details.termId =termId;
                details.weightageEquivalent =weightageEquivalent;
                details.stakeAmount = total;
                details.stakeTime = block.timestamp;
                details.lastClaimTime = block.timestamp;
                details._currentOwner =msg.sender;
                totalWeightagePerpool[pool]+=weightageEquivalent;
                if(status){
               token.transferFrom(msg.sender, TreasuryPools[pool], total);}
               else{
    
                    IPool(TreasuryPools[actualOne]).DistributePLXR(TreasuryPools[pool], total);
               }
                string memory uri=_uri;
               IGovernanceNFT(governanceTokenAddress[pool]).mintTokens(msg.sender, nftIndexPerPool[pool], uri);
               emit Deposit(msg.sender, TreasuryPools[pool],total, pool ,currentIndexOfPool);
        }

        function getDistributionRate(uint amount) public view returns(uint,uint,uint,uint){
              uint treasury= ( amount*investmentDistribution[1])/100;
               uint insuranceAmount = (treasury *1)/100;
              uint rewards= (amount*investmentDistribution[2])/100;
              uint marketing= (amount*investmentDistribution[3])/100;
              return (treasury,insuranceAmount,rewards,marketing);
        }



        function claimFunds (uint[] memory poolIds, uint[] memory _nftIds, uint[] memory _amount) external nonReentrant {
                require(poolIds.length == _nftIds.length,'Error: Array length Not Equal');
                
                for (uint i=0; i< poolIds.length; i++) {
                        require(!IsConfirmedUnstaking[msg.sender][poolIds[i]][_nftIds[i]],"User Confirmed unstaking");
                        require (IGovernanceNFT(governanceTokenAddress[poolIds[i]]).ownerOf(_nftIds[i]) == msg.sender,'Error: Caller Not Owner');
                        uint __amount = (getRewardDetails(poolIds[i], _nftIds[i]));
                        require(_amount[i]<=__amount,"not Enough Rewards");
                        uint amount =_amount[i];
                        if(poolIds[i]==1){
                            uint insure= (amount*5)/100;
                            amount-=insure;
                             IPool(TreasuryPools[poolIds[i]]).DistributePLXR(insuranceFundAddress, insure);
                        }else{
                            amount=amount-((amount*10)/100);
                        }
                        nftDetails storage details = detailsPerNftId[_nftIds[i]][poolIds[i]];
                        details.lastClaimTime = block.timestamp;
                        require(amount > 0 ,'Error: Not Enough Reward Collected');

                        IPool(TreasuryPools[poolIds[i]]).DistributePLXR(msg.sender, amount);

                        remainningRewards[poolIds[i]][_nftIds[i]]=(__amount-amount);
                        givenRewards[msg.sender][poolIds[i]]+=amount;
                        totalPoolRewards[poolIds[i]]+=amount;
                        totalRewardsPerPool[poolIds[i]]-=amount;
                }

        }

        function getTotalVotesDetails(uint poolId) external view returns(uint){
            return totalVotesEachPool[poolId];
        }

        function unstakeTokens (uint[] memory poolIds, uint[] memory _nftIds) external nonReentrant {
                require(poolIds.length == _nftIds.length,'Error: Array length Not Equal');
                for (uint i=0; i< poolIds.length; i++) {
                    require(IsConfirmedUnstaking[msg.sender][poolIds[i]][_nftIds[i]],"Confirm Unstake");
                        require(poolIds[i]!=3,"Meta pool is Locked permanent");
                        require(block.timestamp>unStakeConfirmedTime[msg.sender][_nftIds[i]][poolIds[i]]+UnstakeLockTime,"Funds In Processing");
                        require (IGovernanceNFT(governanceTokenAddress[poolIds[i]]).ownerOf(_nftIds[i])==msg.sender,'Error: Caller Not Owner');
                        uint poolId = poolIds[i];
                        uint amountToReturn = detailsPerNftId[_nftIds[i]][poolId].stakeAmount;
                        uint __amount=userTotalRewards[msg.sender][poolIds[i]][_nftIds[i]];
                        if(poolIds[i]==1){
                            uint insurance= (amountToReturn * 10)/100 ;
                            amountToReturn-=insurance;
                           IPool(TreasuryPools[poolId]).DistributePLXR(insuranceFundAddress,insurance); 
                        }
                        uint finalAmount=amountToReturn+__amount;
                         totalStakedAmount[msg.sender][poolIds[i]]-=amountToReturn/ 1 ether;
                         getUserTotalVotes[msg.sender][poolIds[i]]-=amountToReturn/100;

                            getGovernance memory users;
                            if(isVotes[msg.sender][poolIds[i]]){
                              totalVotesEachPool[poolIds[i]]--;
                               }
                             isVotes[msg.sender][poolIds[i]]=false;
                     users.totalWeightagePerPool=getUserTotalVotes[msg.sender][poolIds[i]];
                     totalWeightagePerpool[poolIds[i]]-=amountToReturn/100;
                     users.totalPLXRStaked=totalStakedAmount[msg.sender][poolIds[i]];
                     totalGovernanceWeightage[msg.sender][poolIds[i]]=users;
                     totalInvestedInEachPool[poolIds[i]]-=amountToReturn; 
                        delete currentTermIdForUserPerPool[msg.sender][poolId];
                        delete poolMapper[_nftIds[i]][governanceTokenAddress[poolId]];
                        delete detailsPerNftId[_nftIds[i]][poolId];
                        IGovernanceNFT(governanceTokenAddress[poolId]).burnTokens(_nftIds[i]);
                        IPool(TreasuryPools[poolId]).DistributePLXR(msg.sender,finalAmount);
                         emit Unstake(msg.sender,poolIds[i],_nftIds[i], finalAmount); 
                }
        }

        function confirmUnstake(uint[] memory poolIds, uint[] memory _nftIds) external {
            require(poolIds.length == _nftIds.length,'Error: Array length Not Equal');
            for(uint i=0;i<poolIds.length;i++){
                require(!IsConfirmedUnstaking[msg.sender][poolIds[i]][_nftIds[i]],"User Confirmed unstaking");
                require (IGovernanceNFT(governanceTokenAddress[poolIds[i]]).ownerOf(_nftIds[i])==msg.sender,'Error: Caller Not Owner');
                uint amount= getRewardDetails(poolIds[i], _nftIds[i]);
                IsConfirmedUnstaking[msg.sender][poolIds[i]][_nftIds[i]]=true;
                userTotalRewards[msg.sender][poolIds[i]][_nftIds[i]]=amount;
                unStakeConfirmedTime[msg.sender][poolIds[i]][_nftIds[i]]=block.timestamp;
                totalUnstakeConfirmed[poolIds[i]]++;
                emit ConfirmUnstake(msg.sender, poolIds[i],_nftIds[i]);
            }
        }

        function setUnstakeLockTime(uint _time) external onlyOwner{
               UnstakeLockTime=_time;
        }

        function getRewardDetails(uint poolId, uint _nftId) public view returns(uint) {
                uint amount = detailsPerNftId[_nftId][poolId].stakeAmount;
                uint lastClaimTime = detailsPerNftId[_nftId][poolId].lastClaimTime;
                uint finalAmount;
                uint time;

                if (block.timestamp > lastClaimTime )
                {
                        finalAmount = ((amount*aprPercent[poolId])/1000)/365;
                        time = (block.timestamp - lastClaimTime )/rebaseTime;

                }
                if(IsConfirmedUnstaking[detailsPerNftId[_nftId][poolId]._currentOwner][poolId][_nftId]){
                    finalAmount= userTotalRewards[detailsPerNftId[_nftId][poolId]._currentOwner][poolId][_nftId];
                    time=1;
                }
                uint _remainningRewards= remainningRewards[poolId][_nftId];

                return (time * finalAmount)+_remainningRewards;
        }
        function viewNftDetails (uint tokenId, uint poolId) external view returns(nftDetails memory) {
                return detailsPerNftId[tokenId][poolId];
        }

        function setTreasuryAddresses (address AlphaTreasury, address BetaTreasury, address MetaTreasury) external onlyOwner {
                TreasuryPools = [address(0),AlphaTreasury,BetaTreasury,MetaTreasury];
        }

        function setGovernanceNFTAddresses (address _alphaNFT, address _betaNFT, address _metaNFT) external onlyOwner {
                governanceTokenAddress = [address(0),_alphaNFT,_betaNFT,_metaNFT];
        }

        function setInsuranceAddress (address _insuranceFundAddress) external onlyOwner {
                insuranceFundAddress = _insuranceFundAddress;
        }

        function calculateVotingWeightage(uint amount) external pure returns(uint, string memory ){
            return (amount/100,"Votes share is 1% of Invested Amount");
        }

        function setRebaseTime(uint time) external onlyOwner {
                rebaseTime= time;
        }
        function setAPR(uint[4] memory apr) external onlyOwner {
                aprPercent = apr;
        }


        function setToken(address _tokenAddress) external onlyOwner{
         token=IERC20Upgradeable(_tokenAddress);
        }

        function setPoolDistributions(uint[4] memory _DistributionPercent) external onlyOwner{
            investmentDistribution=_DistributionPercent;
        }

        function depositRewards(uint poolId, uint amount) external onlyOwner{
              token.transferFrom(msg.sender,TreasuryPools[poolId], amount);
              totalRewardsPerPool[poolId]+=amount;
        }

}