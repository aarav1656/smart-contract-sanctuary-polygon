// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * @title TopUp Contract
 * @author GET Protocol
 * @notice Contract responsible for integrator fuel top ups
 * @dev Supports two integrator top ups; Custodian and Non-Custodial
 */

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "./interfaces/IPriceOracle.sol";
import "./interfaces/IEconomics.sol";
import "./interfaces/IRegistry.sol";
import "./interfaces/ITopUp.sol";
import "./abstract/AuthModifiers.sol";

contract TopUp is ITopUp, OwnableUpgradeable, PausableUpgradeable, AuthModifiers, UUPSUpgradeable {
    using AddressUpgradeable for address;

    IRegistry private registry;
    IERC20Metadata public baseToken;
    IERC20 public weth;
    IUniswapV2Router02 public router;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    /**
     * @dev Initialization function for proxy contract
     * @param _registry Registry contract address
     * @param _baseToken Topup base token address; typically USDC
     * @param _weth Wrapped Ether token address
     * @param _router UniswapV2Router02 contract address
     */
    // solhint-disable-next-line func-name-mixedcase
    function __TopUp_init(
        address _registry,
        address _baseToken,
        address _weth,
        address _router
    ) public initializer {
        __Context_init();
        __Ownable_init();
        __AuthModifiers_init(_registry);
        __TopUp_init_unchained(_registry, _baseToken, _weth, _router);
    }

    // solhint-disable-next-line func-name-mixedcase
    function __TopUp_init_unchained(
        address _registry,
        address _baseToken,
        address _weth,
        address _router
    ) public initializer {
        registry = IRegistry(_registry);
        baseToken = IERC20Metadata(_baseToken);
        weth = IERC20(_weth);
        router = IUniswapV2Router02(_router);
    }

    function _calculatePrice(uint256 _amountA, uint256 _amountB) internal view returns (uint256 _swapPrice) {
        _swapPrice = (_amountA * 1e18 * 10**(18 - baseToken.decimals())) / _amountB;
    }

    /**
     * @notice Internal function to swap tokens via the UniswapV2Router02 contract
     * @dev called by the topUpCustodial function
     * @param _amountIn amount of the token to be swapped for another
     * @param _amountOutMin minimum output of swapped token
     * @return _swapInfo amount of swapped tokens and swap price normalised to 18 decimal places
     */
    function _swapFromPair(uint256 _amountIn, uint256 _amountOutMin) internal whenNotPaused returns (uint256, uint256) {
        require(baseToken.transferFrom(msg.sender, address(this), _amountIn), "TopUp: transferFrom failed");
        require(baseToken.approve(address(router), _amountIn), "TopUp: approval failed");

        address[] memory _path = new address[](3);
        _path[0] = address(baseToken);
        _path[1] = address(weth);
        _path[2] = address(registry.economics().fuelToken());

        uint256[] memory _amounts = router.swapExactTokensForTokens(
            _amountIn,
            _amountOutMin,
            _path,
            address(this),
            block.timestamp + 15 minutes
        );

        /// Normalise swap price to 18dp
        uint256 _swapPrice = _calculatePrice(_amounts[0], _amounts[2]);
        return (_amounts[2], _swapPrice);
    }

    /**
     * @dev  Swaps ERC20->ERC20 tokens held by this contract using a 0x-API quote.
     * @param _sellToken The `sellTokenAddress` field from the API response.
     * @param _buyToken The `buyTokenAddress` field from the API response.
     * @param _spender The `allowanceTarget` field from the API response.
     * @param _swapTarget The `to` field from the API response.
     * @param _swapCallData The `data` field from the API response.
     * @return _boughtAmount Amount of token bought
     * @return _swapPrice Price of token swap
     */
    // solhint-disable-next-line max-line-length
    /// Actual implementation by 0x can be found here: https://github.com/0xProject/0x-api-starter-guide-code/blob/900a3264847c81aa75070fc43c996b2012402597/contracts/SimpleTokenSwap.sol#L65
    function _fillQuote(
        IERC20 _sellToken,
        IERC20 _buyToken,
        address _spender,
        address payable _swapTarget,
        bytes calldata _swapCallData
    ) internal returns (uint256, uint256) {
        uint256 _boughtAmount = _buyToken.balanceOf(address(this));
        uint256 _soldAmount = _sellToken.balanceOf(address(this));

        require(_sellToken.approve(_spender, type(uint256).max), "TopUp: approve call failed");

        // solhint-disable-next-line avoid-low-level-calls
        (bool _success, ) = _swapTarget.call{ value: msg.value }(_swapCallData);
        require(_success, "TopUp: swap call failed");
        payable(msg.sender).transfer(address(this).balance);
        _boughtAmount = _buyToken.balanceOf(address(this)) - _boughtAmount;
        _soldAmount = _soldAmount - _sellToken.balanceOf(address(this));
        uint256 _swapPrice = _calculatePrice(_soldAmount, _boughtAmount);
        return (_boughtAmount, _swapPrice);
    }

    /**
     * @notice Custodial integrator top up
     * @dev tops up an integrator on-ramp
     *
     * @dev Fiat USD is swapped for USDC which is eventually swapped for $GET
     * @param _integratorIndex integrator index in question
     * @param _amountIn amount of USDC to be swapped for $GET
     * @param _amountOutMin minimum expected $GET
     * @param _externalId transaction identification
     */
    function topUpCustodial(
        uint32 _integratorIndex,
        uint256 _amountIn,
        uint256 _amountOutMin,
        bytes32 _externalId
    ) external whenNotPaused onlyCustodialTopUp {
        (uint256 _amountFuel, uint256 _swapPrice) = _swapFromPair(_amountIn, _amountOutMin);

        uint256 _availableFuel = registry.economics().topUpIntegrator(
            _integratorIndex,
            address(this),
            _amountFuel,
            _swapPrice
        );
        emit ToppedUpCustodial(_integratorIndex, msg.sender, _availableFuel, _amountFuel, _swapPrice, _externalId);
    }

    /**
     * @notice Custodial topup using 0x Protocol for token swaps
     * @dev Swaps ERC20->ERC20 tokens held by this contract using a 0x-API quote.
     *
     * @dev Must attach ETH equal to the `value` field from the API response.
     * @param _integratorIndex integrator index in question
     * @param _externalId transaction identification
     * @param _spender The `allowanceTarget` field from the API response.
     * @param _swapTarget The `to` field from the API response.
     * @param _swapCallData The `data` field from the API response.
     */
    function topUpCustodial0x(
        uint32 _integratorIndex,
        bytes32 _externalId,
        address _spender,
        address payable _swapTarget,
        bytes calldata _swapCallData
    ) external payable whenNotPaused onlyCustodialTopUp {
        (uint256 _amountFuel, uint256 _swapPrice) = _fillQuote(
            IERC20(baseToken),
            IERC20(registry.economics().fuelToken()),
            _spender,
            _swapTarget,
            _swapCallData
        );

        uint256 _availableFuel = registry.economics().topUpIntegrator(
            _integratorIndex,
            address(this),
            _amountFuel,
            _swapPrice
        );

        emit ToppedUpCustodial0x(_integratorIndex, msg.sender, _availableFuel, _amountFuel, _swapPrice, _externalId);
    }

    /**
     * @notice Non-Custodial integrator top up
     * @dev tops up an integrator directly with $GET
     * @param _integratorIndex integrator index in question
     * @param _amountFuel amount of $GET for top up
     */
    function topUpNonCustodial(uint32 _integratorIndex, uint256 _amountFuel) external whenNotPaused {
        uint256 _price = registry.priceOracle().price();
        uint256 _availableFuel = registry.economics().topUpIntegrator(
            _integratorIndex,
            msg.sender,
            _amountFuel,
            _price
        );
        emit ToppedUpNonCustodial(_integratorIndex, msg.sender, _availableFuel, _amountFuel, _price);
    }

    /** @notice This pauses the contract
     */
    function pause() external onlyOwner {
        _pause();
    }

    /** @notice This halts the pause
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @notice Set's the address of the base token used in topUpCustodial
     * @dev this most likely is USDC
     * @param _baseToken contract address for the token
     */
    function setBaseToken(address _baseToken) external isContract(_baseToken) onlyOwner {
        emit UpdateBaseToken(address(baseToken), _baseToken);
        baseToken = IERC20Metadata(_baseToken);
    }

    /**
     * @notice Set's the address for WETH used in topUpCustodial
     * @dev the base token is swapped for WETH and WETH for $GET in a custodial top up
     * @param _weth WETH contract address
     */
    function setWeth(address _weth) external isContract(_weth) onlyOwner {
        emit UpdateWeth(address(weth), _weth);
        weth = IERC20(_weth);
    }

    /**
     * @notice Set's the address for UniswapV2Router02 contract
     * @dev The router performs the USDC to $GET swap in a custodial top up
     * @param _router router contract address
     */
    function setRouter(address _router) external isContract(_router) onlyOwner {
        emit UpdateRouter(address(router), _router);
        router = IUniswapV2Router02(_router);
    }

    /**
     * @notice Gives maximum allowance for $GET on the Economics contract
     */
    function setApprovals() external onlyOwner {
        registry.economics().fuelToken().approve(address(registry.economics()), type(uint256).max);
    }

    /**
     * @dev Filters out non-contract addresses
     */
    modifier isContract(address _account) {
        require(_account.isContract(), "TopUp: address is not a contract");
        _;
    }

    /**
     * @notice  A internal function to authorize a contract upgrade
     * @dev The function is a requirement for Openzeppelin's UUPS upgradeable contracts
     *
     * @dev can only be called by the contract owner
     */
    function _authorizeUpgrade(address) internal override onlyOwner {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../ERC1967/ERC1967UpgradeUpgradeable.sol";
import "./Initializable.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is Initializable, IERC1822ProxiableUpgradeable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal onlyInitializing {
    }

    function __UUPSUpgradeable_init_unchained() internal onlyInitializing {
    }
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        require(address(this) == __self, "UUPSUpgradeable: must not be called through delegatecall");
        _;
    }

    /**
     * @dev Implementation of the ERC1822 {proxiableUUID} function. This returns the storage slot used by the
     * implementation. It is used to validate that the this implementation remains valid after an upgrade.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy. This is guaranteed by the `notDelegated` modifier.
     */
    function proxiableUUID() external view virtual override notDelegated returns (bytes32) {
        return _IMPLEMENTATION_SLOT;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
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
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.4;

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IPriceOracle {
    event UpdatePrice(uint256 old, uint256 updated);

    function price() external view returns (uint256);

    function lastUpdateTimestamp() external view returns (uint32);

    function setPrice(uint256 _price) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IEventImplementation.sol";

interface IEconomics {
    // Data structure containing all the different rates for a particular relayer.
    //   100% (1) 1_000_000,
    //   10% (0.1) = 100_000,
    //   1% (0.01) = 10_000,
    //   0.1% (0.001) = 1_000,
    //   0.01% (0.0001) = 100,
    //   0.001% (0,00001) = 10,
    //   0.0001% = (0.000001) = 1
    // All scaled by 1_000_000.
    //
    // USD values (e.g. minFee, maxFee) are scaled by 1_000 (tenth of a cent).
    struct DynamicRates {
        uint24 minFeePrimary;
        uint24 maxFeePrimary;
        uint24 primaryRate;
        uint24 minFeeSecondary;
        uint24 maxFeeSecondary;
        uint24 secondaryRate;
        uint24 salesTaxRate;
    }

    // Largely unnecesary to define separately but helps avoid stack too deep errors within reserved fuel calculations.
    struct Rate {
        uint24 minFee;
        uint24 maxFee;
        uint24 rate;
    }

    struct IntegratorData {
        uint32 index;
        uint32 activeTicketCount;
        bool isBillingEnabled;
        bool isConfigured;
        uint256 price;
        uint256 availableFuel;
        uint256 reservedFuel;
        uint256 reservedFuelProtocol;
        string name;
    }

    struct RelayerData {
        uint32 integratorIndex;
    }

    struct SpentFuel {
        uint256 total;
        uint256 protocol;
        uint32 ticketCount;
    }

    event IntegratorToppedUp(
        uint32 indexed integratorIndex,
        uint256 indexed total,
        uint256 price,
        uint256 indexed newAveragePrice,
        uint256 salesTax
    );
    event FuelReservedPrimary(uint32 integratorIndex, uint32 ticketCount, uint256 fuel, uint256 fuelProtocol);
    event FuelReservedSecondary(uint32 integratorIndex, uint32 ticketCount, uint256 fuel, uint256 fuelProtocol);
    event BasicTaxCharged(uint32 integratorIndex, uint32 actionCount, uint256 fuel, uint256 fuelProtocol);
    event TicketFuelEmptied(uint32 integratorIndex, uint32 ticketCount, uint256 fuel, uint256 fuelProtocol);
    event SpentFuelCollected(SpentFuel spentFuel);
    event SalesTaxFuelCollected(address salesTaxFuelDesintation, uint256 salesTaxFuel);
    event AccountBalanceCorrected(
        uint32 integratorIndex,
        uint256 oldAvailableFuel,
        uint256 newAvailableFuel,
        uint256 oldReservedBalance,
        uint256 newReservedBalance,
        uint256 oldReservedBalanceProtocol,
        uint256 newReservedBalanceProtocol
    );
    event UpdateBasicTaxRate(uint24 old, uint24 updated);
    event UpdateFuelToken(address old, address updated);
    event UpdateSpentFuel(SpentFuel spentFuel);
    event UpdateDynamicRates(uint32 integratorIndex, DynamicRates dynamicRates);
    event UpdateProtocolRates(DynamicRates protocolRates);
    event UpdateSalesTaxFuelDestination(address salesTaxFuelDestination);
    event IntegratorConfigured(uint32 integratorIndex, string name, address relayerAddress, DynamicRates dynamicRates);
    event IntegratorActivated(uint32 integratorIndex);
    event IntegratorDisabled(uint32 integratorIndex);
    event RelayerAdded(address relayerAddress, uint32 integratorIndex);
    event RelayerRemoved(address relayerAddress, uint32 integratorIndex);
    event BillingStatusUpdated(uint32 integeratorIndex, bool status);
    event ConfigurationStatusUpdated(uint32 integratorIndex, bool status);
    event EnableIntegratorBilling(uint32 integratorIndex);
    event DisableIntegratorBilling(uint32 integratorIndex);
    event UpdateIntegratorTicketCount(uint32 integratorIndex, uint256 activeTicketCount);
    event UpdateIntegratorPrice(uint32 integratorIndex, uint256 price);
    event UpdateIntegratorName(uint32 integratorIndex, string name);

    function fuelToken() external returns (IERC20);

    function basicTaxRate() external returns (uint24);

    function spentFuel()
        external
        returns (
            uint256,
            uint256,
            uint32
        );

    function integratorCount() external returns (uint32);

    function topUpIntegrator(
        uint32 _integratorIndex,
        address _sender,
        uint256 _amount,
        uint256 _price
    ) external returns (uint256);

    function reserveFuelPrimarySale(address _relayerAddress, IEventImplementation.TicketAction[] memory _ticketActions)
        external
        returns (uint256, uint256);

    function reserveFuelSecondarySale(
        address _relayerAddress,
        IEventImplementation.TicketAction[] memory _ticketActions
    ) external returns (uint256, uint256);

    function spendBasicAction(address _relayerAddress, uint32 _actionCount) external returns (uint256, uint256);

    function spendTicketReserved(address _relayerAddress, uint32 _ticketCount) external returns (uint256, uint256);

    function collectSpentFuel() external returns (uint256, uint256);

    function collectSalesTaxFuel() external;

    function correctAccountBalance(
        uint32 _integratorIndex,
        uint256 _newAvailableFuel,
        uint256 _newReservedFuel
    ) external;

    function setupIntegrator(
        string calldata _name,
        address _relayerAddress,
        DynamicRates calldata _dynamicRates,
        uint256 _price
    ) external;

    function activateIntegrator(uint32 _integratorIndex) external;

    function disableIntegrator(uint32 _integratorIndex) external;

    function addRelayer(address _relayerAddress, uint32 _integratorIndex) external;

    function removeRelayer(address _relayerAddress) external;

    function setDynamicRates(uint32 _integratorIndex, DynamicRates memory dynamicRates) external;

    function setProtocolRates(DynamicRates memory dynamicRates) external;

    function setSalesTaxFuelDestination(address _salesTaxFuelDestination) external;

    function enableIntegratorBilling(uint32 _integratorIndex) external;

    function disableIntegratorBilling(uint32 _integratorIndex) external;

    function setBasicTaxRate(uint24 _basicTaxRate) external;

    function setFuelToken(address _fuelToken) external;

    function setSpentFuel(SpentFuel calldata _spentFuel) external;

    function emergencyWithdraw(
        address _asset,
        address _to,
        uint256 _amount
    ) external;

    function setBillingStatus(uint32 _integratorIndex, bool status) external;

    function setConfigurationStatus(uint32 _integratorIndex, bool status) external;

    function setIntegratorTicketCount(uint32 _integratorIndex, uint32 _activeTicketCount) external;

    function setIntegratorPrice(uint32 _integratorIndex, uint256 _price) external;

    function setIntegratorName(uint32 _integratorIndex, string calldata _name) external;

    function viewIntegratorUSDBalance(uint32 _integratorIndex) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./IAuth.sol";
import "./IEconomics.sol";
import "./IEventFactory.sol";
import "./IPriceOracle.sol";
import "./ITopUp.sol";

interface IRegistry {
    event UpdateAuth(address old, address updated);
    event UpdateEconomics(address old, address updated);
    event UpdateEventFactory(address old, address updated);
    event UpdatePriceOracle(address old, address updated);
    event UpdateFuelDistributor(address old, address updated);
    event UpdateTopUp(address old, address updated);
    event UpdateBaseURI(string old, string updated);

    function auth() external view returns (IAuth);

    function economics() external view returns (IEconomics);

    function eventFactory() external view returns (IEventFactory);

    function priceOracle() external view returns (IPriceOracle);

    function topUp() external view returns (ITopUp);

    function baseURI() external view returns (string memory);

    function setAuth(address _auth) external;

    function setEconomics(address _economics) external;

    function setEventFactory(address _eventFactory) external;

    function setPriceOracle(address _priceOracle) external;

    function setFuelDistributor(address _fuelDistributor) external;

    function setTopUp(address _topUp) external;

    function setBaseURI(string memory _baseURI) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

interface ITopUp {
    event ToppedUpCustodial(
        uint32 indexed integratorIndex,
        address indexed debitedAccount,
        uint256 availableFuel,
        uint256 amountFuel,
        uint256 price,
        bytes32 externalId
    );

    event ToppedUpCustodial0x(
        uint32 indexed integratorIndex,
        address indexed debitedAccount,
        uint256 availableFuel,
        uint256 amountFuel,
        uint256 price,
        bytes32 externalId
    );

    event ToppedUpNonCustodial(
        uint32 indexed integratorIndex,
        address indexed debitedAccount,
        uint256 availableFuel,
        uint256 amountFuel,
        uint256 price
    );
    event UpdateBaseToken(address old, address updated);
    event UpdateWeth(address old, address updated);
    event UpdateRouter(address old, address updated);
    event UpdateOracle(address old, address updated);

    function baseToken() external returns (IERC20Metadata);

    function weth() external returns (IERC20);

    function router() external returns (IUniswapV2Router02);

    function topUpCustodial(
        uint32 _integratorIndex,
        uint256 _amountIn,
        uint256 _amountOutMin,
        bytes32 _externalId
    ) external;

    function topUpNonCustodial(uint32 _integratorIndex, uint256 _amountFuel) external;

    function pause() external;

    function unpause() external;

    function setBaseToken(address _baseToken) external;

    function setWeth(address _weth) external;

    function setRouter(address _router) external;

    function setApprovals() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../interfaces/IRegistry.sol";

/**
 * @title AuthModifiers Contract
 * @author GET Protocol
 * @notice This contract provides access control modifiers to the Auth contract
 * @dev It's implemented as an abstract contract
 */

abstract contract AuthModifiers is Initializable {
    IRegistry private registry;

    // solhint-disable-next-line func-name-mixedcase
    function __AuthModifiers_init_unchained(address _registry) internal initializer {
        registry = IRegistry(_registry);
    }

    /**
     * @dev initialization function for proxy contract
     * @param _registry the Registry contract address
     */

    // solhint-disable-next-line func-name-mixedcase
    function __AuthModifiers_init(address _registry) public initializer {
        __AuthModifiers_init_unchained(_registry);
    }

    /**
     * @dev Throws if called by any account other than a GET Protocol Relayer admin account.
     */
    modifier onlyIntegratorAdmin() {
        registry.auth().hasIntegratorAdminRole(msg.sender);
        _;
    }

    /**
     * @dev Throws if called by any account other than a GET Protocol Relayer account.
     */
    modifier onlyRelayer() {
        registry.auth().hasRelayerRole(msg.sender);
        _;
    }

    /**
     * @dev Throws if called by any contract other than a GET Protocol Factory contract.
     */
    modifier onlyFactory() {
        registry.auth().hasFactoryRole(msg.sender);
        _;
    }

    /**
     * @dev Throws if called by any contract different from an instance of a GET protocol Event Contract
     */
    modifier onlyEvent() {
        registry.auth().hasEventRole(msg.sender);
        _;
    }

    /**
     * @dev Throws if called by any contract other than the GET Protocol FuelDistributor Contract.
     */
    modifier onlyFuelDistributor() {
        registry.auth().hasFuelDistributorRole(msg.sender);
        _;
    }

    /**
     * @dev Throws if called by any contract other than the GET Protocol TopUp Contract.
     */
    modifier onlyTopUp() {
        registry.auth().hasTopUpRole(msg.sender);
        _;
    }

    /**
     * @dev Throws if called by any account other than the GET Protocol EOA(S) designated for TopUps.
     */
    modifier onlyCustodialTopUp() {
        registry.auth().hasCustodialTopUpRole(msg.sender);
        _;
    }

    /**
     * @dev Throws if called by any contract other than the PriceOracle update EOA.
     */
    modifier onlyPriceOracle() {
        registry.auth().hasPriceOracleRole(msg.sender);
        _;
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
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
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
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

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

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822ProxiableUpgradeable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeaconUpgradeable.sol";
import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/StorageSlotUpgradeable.sol";
import "../utils/Initializable.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable {
    function __ERC1967Upgrade_init() internal onlyInitializing {
    }

    function __ERC1967Upgrade_init_unchained() internal onlyInitializing {
    }
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822ProxiableUpgradeable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlotUpgradeable {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.4;

interface IUniswapV2Router01 {
    function factory() external view returns (address);
    function WETH() external view returns (address);

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
pragma solidity ^0.8.4;

interface IEventImplementation {
    enum TicketFlags {
        SCANNED, // 0
        CHECKED_IN, // 1
        INVALIDATED, // 2
        UNLOCKED // 3
    }

    struct BalanceUpdates {
        address owner;
        uint64 quantity;
    }

    struct TokenData {
        address owner;
        uint40 basePrice;
        uint8 booleanFlags;
    }

    struct AddressData {
        // uint64 more than enough
        uint64 balance;
    }

    struct EventData {
        uint32 index;
        uint64 startTime;
        uint64 endTime;
        int32 latitude;
        int32 longitude;
        string currency;
        string name;
        string shopUrl;
        string imageUrl;
    }

    struct TicketAction {
        uint256 tokenId;
        bytes32 externalId; // sha256 hashed, emitted in event only.
        address to;
        uint64 orderTime;
        uint40 basePrice;
    }

    struct EventFinancing {
        uint64 palletIndex;
        address bondCouncil;
        bool inventoryRegistered;
        bool financingActive;
        bool primaryBlocked;
        bool secondaryBlocked;
        bool scanBlocked;
        bool claimBlocked;
    }

    event PrimarySale(TicketAction[] ticketActions, uint256 getUsed, uint256 getUsedProtocol);

    event SecondarySale(TicketAction[] ticketActions, uint256 getUsed, uint256 getUsedProtocol);

    event Scanned(TicketAction[] ticketActions, uint256 getUsed, uint256 getUsedProtocol);

    event CheckedIn(TicketAction[] ticketActions, uint256 getUsed, uint256 getUsedProtocol);

    event Invalidated(TicketAction[] ticketActions, uint256 getUsed, uint256 getUsedProtocol);

    event Claimed(TicketAction[] ticketActions, uint256 getUsed, uint256 getUsedProtocol);

    event EventDataSet(EventData eventData);

    event EventDataUpdated(EventData eventData);

    event UpdateFinancing(EventFinancing financing);

    function batchActions(
        TicketAction[] calldata _ticketActions,
        uint8[] memory _actionCounts,
        BalanceUpdates[] calldata _balanceUpdates
    ) external;

    function isScanned(uint256 _tokenId) external returns (bool _status);

    function isCheckedIn(uint256 _tokenId) external returns (bool _status);

    function isInvalidated(uint256 _tokenId) external returns (bool _status);

    function isUnlocked(uint256 _tokenId) external returns (bool _status);

    function isCustodial(uint256 _tokenId) external returns (bool _status);

    function setEventData(EventData memory _eventData) external;

    function updateEventData(EventData memory _eventData) external;

    function setFinancing(EventFinancing memory _financing) external;

    function owner() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/access/IAccessControlUpgradeable.sol";

interface IAuth is IAccessControlUpgradeable {
    function hasIntegratorAdminRole(address) external view;

    function hasFactoryRole(address) external view;

    function hasEventRole(address) external view;

    function hasFuelDistributorRole(address) external view;

    function hasRelayerRole(address) external view;

    function hasTopUpRole(address) external view;

    function hasCustodialTopUpRole(address) external view;

    function hasPriceOracleRole(address) external view;

    function grantEventRole(address) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IEventFactory {
    event EventCreated(uint256 indexed eventIndex, address indexed eventImplementationProxy);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
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