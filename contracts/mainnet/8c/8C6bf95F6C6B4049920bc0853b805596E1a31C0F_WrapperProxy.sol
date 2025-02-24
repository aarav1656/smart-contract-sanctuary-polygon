// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/utils/introspection/IERC165.sol';

import './components/AbstractBase.sol';
import './components/AbstractWrapper.sol';
import './interfaces/IProxy.sol';
import './interfaces/IVerifier.sol';
import './interfaces/IWrapper.sol';

contract WrapperProxy is AbstractBase, IERC165, IProxy {
  error BAD_CREDENTIAL();
  error INVALID_CALLER();
  error WITHDRAWAL_FAILED();
  error OPERATION_FAILED(address target, bytes reason);
  error PROXY_MISMATCH();
  error INVALID_INTERFACE();

  IVerifier public verifier;

  mapping(address => IWrapper) public wrapperRegistry;
  mapping(address => bool) public approvedCallers;

  /**
   * @notice Initializer
   *
   * @param _owner Admin account address for Ownable.
   * @param _verifier Verifiable credentials contract.
   * @param _trustedForwarder ERC2771 fowarderd address.
   */
  function initialize(
    address _owner,
    IVerifier _verifier,
    address _trustedForwarder
  ) external initializer {
    _transferOwnership(_owner);
    verifier = _verifier;
    trustedForwarder = _trustedForwarder;
  }

  /**
   * @notice Primary entry point into this system of contracts. This method will forward the call to a wrapper registered to a given target contract after verifying the provided credentials.
   *
   * @dev This method is expected to be called by an ERC2771 forwarder contract.
   */
  function performAction(
    address _target,
    string memory _action,
    bytes memory _params,
    OnChainVerifiablePresentation memory _presentation
  ) external verifyAccess(_presentation) confirmForwarder {
    IWrapper wrapper = wrapperRegistry[_target];
    if (address(wrapper) == address(0)) {
      revert OPERATION_FAILED(_target, bytes('no wrapper'));
    }

    wrapper.performAction(_action, _params);
  }

  /**
   * @notice Approves token balance owned by the wrapper for a given spender.
   *
   * @dev The method will only execute if it comes from a known sender, a wrapper for a defi contract, that is part of this system.
   */
  function approveBalance(
    IERC20 _token,
    uint256 _amount,
    address _spender
  ) external verifyCaller(msg.sender) {
    _token.approve(_spender, _amount);
  }

  /**
   * @notice forwards a call to the target address. This function is used by the contract wrappers to change the sender as the Wrapper is expected to hold various balances. The call happens blindly, meaning this function knows nothing of the parameters it is sending to the call.
   *
   * @dev The method will only execute if it comes from a known sender, a wrapper for a defi contract, that is part of this system.
   *
   * @param _target Contract address to call.
   * @param _params Parameters to pass to the `call` function.
   */
  function forward(address _target, bytes calldata _params) external verifyCaller(msg.sender) {
    (bool success, bytes memory result) = _target.call(_params);
    if (!success) {
      revert OPERATION_FAILED(_target, result);
    }
  }

  ///
  /// Admin functions
  ///

  function registerWrapper(address _target, IWrapper _wrapper) external onlyOwner confirmForwarder {
    if (!_wrapper.supportsInterface(type(AbstractWrapper).interfaceId)) {
      revert INVALID_INTERFACE();
    }

    if (address(_wrapper.proxy()) != address(this)) {
      revert PROXY_MISMATCH();
    }

    wrapperRegistry[_target] = _wrapper;
    approvedCallers[address(_wrapper)] = true;
  }

  function removeWrapper(address _target) external onlyOwner confirmForwarder {
    delete approvedCallers[address(wrapperRegistry[_target])];
    delete wrapperRegistry[_target];
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
    return interfaceId == type(IWrapper).interfaceId;
  }

  /**
   * @notice Validate permissions against the verifiable credential contracts
   */
  modifier verifyAccess(OnChainVerifiablePresentation memory _presentation) {
    if (isPaused) {
      revert CONTRACT_SUSPENDED();
    }

    if (!verifier.verifyChain(_presentation, _msgSender())) {
      revert BAD_CREDENTIAL();
    }

    _;
  }

  /**
   * @notice Only allow calls from registred proxies.
   */
  modifier verifyCaller(address _caller) {
    if (!approvedCallers[_caller]) {
      revert INVALID_CALLER();
    }

    _;
  }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';

abstract contract AbstractBase is Initializable, OwnableUpgradeable {
  error CONTRACT_SUSPENDED();
  error TRANSFER_FAILED();
  error INVALID_FORWARDER();

  bool public isPaused;
  address public trustedForwarder;

  /**
   * @notice Allows updating the trusted forwarder to another for this contract
   */
  function setTrustedForwarder(address _trustedForwarder) external virtual onlyOwner confirmForwarder {
    trustedForwarder = _trustedForwarder;
  }

  /**
   * @notice Allows pausing of the operation of this contract.
   */
  function setPause(bool _pause) external virtual onlyOwner confirmForwarder {
    isPaused = _pause;
  }

  /**
   * @notice Transfers contract Ether balance to a given address.
   */
  function recoverBalance(address payable _destination) external virtual onlyOwner confirmForwarder {
    (bool success, ) = _destination.call{value: address(this).balance}('');

    if (!success) {
      revert TRANSFER_FAILED();
    }
  }

  /**
   * @notice Transfers ERC20 balance owned by the contract to a given address.
   */
  function recoverTokenBalance(
    IERC20 _token,
    uint256 _amount,
    address _destination
  ) external virtual onlyOwner confirmForwarder {
    bool success = _token.transfer(_destination, _amount);

    if (!success) {
      revert TRANSFER_FAILED();
    }
  }

  /**
   * @notice ERC2771 support. Taken from openzeppelin/ERC2771Context 4.7.3.
   */
  function isTrustedForwarder(address forwarder) public view virtual returns (bool) {
    return forwarder == trustedForwarder;
  }

  /**
   * @notice ERC2771 support. Taken from openzeppelin/ERC2771Context 4.7.3.
   */
  function _msgSender() internal view virtual override returns (address sender) {
    if (isTrustedForwarder(msg.sender)) {
      // The assembly code is more direct than the Solidity version using `abi.decode`.
      /// @solidity memory-safe-assembly
      assembly {
        sender := shr(96, calldataload(sub(calldatasize(), 20)))
      }
    } else {
      return super._msgSender();
    }
  }

  /**
   * @notice ERC2771 support. Taken from openzeppelin/ERC2771Context 4.7.3.
   */
  function _msgData() internal view virtual override returns (bytes calldata) {
    if (isTrustedForwarder(msg.sender)) {
      return msg.data[:msg.data.length - 20];
    } else {
      return super._msgData();
    }
  }

  /**
   * @notice Check that contract is not paused.
   */
  modifier whileActive() virtual {
    if (isPaused) {
      revert CONTRACT_SUSPENDED();
    }

    _;
  }

  /**
   * @notice Support for ERC2771. This method only does rudimentary address checking against a known-good sender address that is expected to be set in a constructor or initializer of the implementing contract.
   */
  modifier confirmForwarder() virtual {
    if (trustedForwarder != address(0) && msg.sender != trustedForwarder) {
      revert INVALID_FORWARDER();
    }

    _;
  }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IProxy {
    function approveBalance(IERC20 _token, uint256 _amount, address _spender) external;
    function forward(address _target, bytes calldata _params) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import '../interfaces/IProxy.sol';
import '../interfaces/IWrapper.sol';
import './AbstractBase.sol';

abstract contract AbstractWrapper is AbstractBase, IWrapper {
  error INVALID_CALLER();
  error OPERATION_FAILED(address target, string action, string reason);

  IProxy public proxy;

  function performAction(string calldata _action, bytes calldata _params) external virtual;

  function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
    return interfaceId == type(AbstractWrapper).interfaceId;
  }

  /**
   * @notice Only allow calls from the proxy contract.
   */
  modifier verifyCaller(address _caller) virtual {
    if (address(proxy) != _caller) {
      revert INVALID_CALLER();
    }

    _;
  }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.9;

import '@openzeppelin/contracts/utils/introspection/IERC165.sol';

import './IProxy.sol';

interface IWrapper is IERC165 {
    function proxy() external view returns (IProxy);
    function performAction(string calldata _action, bytes calldata _params) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

/// Various structs for representing a W3C credential as close to spec as possible given contraints
struct OnChainCredentialSubject {
  bytes32 id;
  bytes data;
}

struct OnChainProof {
  bytes types;
  bytes verificationMethod;
  bytes proofValue;
}

struct OnChainPresentationProof {
  bytes types;
  bytes verificationMethod;
  bytes proofValue;
  uint256 nonce;
}

struct OnChainVerifiableCredential {
  bytes32 id;
  OnChainCredentialSubject credentialSubject;
  bytes32 issuer;
  uint256 expirationDate;
  uint256 issuanceDate;
  bytes types;
  OnChainProof proof;
}

struct OnChainVerifiablePresentation {
  bytes32 id;
  OnChainVerifiableCredential[] verifiableCredential;
  OnChainPresentationProof proof;
}

/// @notice Interface for Verifier smart contract
interface IVerifier {
  event VerificationResult(bytes32 indexed id, bool result, string reason);

  function getNonce(bytes32 _did) external view returns (uint256);

  function verifyChain(OnChainVerifiablePresentation memory presentation, address _presentationSender) external returns (bool);
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