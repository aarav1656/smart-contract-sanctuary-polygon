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
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/Initializable.sol)

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
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
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
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
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
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initialized`
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initializing`
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.13;

import {IPriceFeed} from "./interfaces/IPriceFeed.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Decimal} from "./utils/Decimal.sol";
import {SignedDecimal} from "./utils/SignedDecimal.sol";
import {MixedDecimal} from "./utils/MixedDecimal.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {IAmm} from "./interfaces/IAmm.sol";

// solhint-disable-next-line max-states-count
contract Amm is IAmm, OwnableUpgradeable {
    using Decimal for Decimal.decimal;
    using SignedDecimal for SignedDecimal.signedDecimal;
    using MixedDecimal for SignedDecimal.signedDecimal;

    enum QuoteAssetDir {
        QUOTE_IN,
        QUOTE_OUT
    }

    enum TwapCalcOption {
        RESERVE_ASSET,
        INPUT_ASSET
    }

    struct ReserveSnapshot {
        Decimal.decimal quoteAssetReserve;
        Decimal.decimal baseAssetReserve;
        uint256 timestamp;
        uint256 blockNumber;
    }

    struct TwapInputAsset {
        Dir dir;
        Decimal.decimal assetAmount;
        QuoteAssetDir inOrOut;
    }

    struct TwapPriceCalcParams {
        TwapCalcOption opt;
        uint256 snapshotIndex;
        TwapInputAsset asset;
    }

    struct DynamicFeeSettings {
        Decimal.decimal divergenceThresholdRatio;
        Decimal.decimal feeRatio;
        Decimal.decimal feeInFavorRatio;
    }

    struct FundingRate {
        SignedDecimal.signedDecimal fundingRateLong;
        SignedDecimal.signedDecimal fundingRateShort;
    }

    /**
     * below state variables cannot change their order
     */

    // ratios
    Decimal.decimal internal feeRatio;
    Decimal.decimal public tradeLimitRatio;
    Decimal.decimal public fluctuationLimitRatio;
    Decimal.decimal internal initMarginRatio;
    Decimal.decimal internal maintenanceMarginRatio;
    Decimal.decimal internal partialLiquidationRatio;
    Decimal.decimal internal liquidationFeeRatio;

    // dynamic fees
    DynamicFeeSettings public level1DynamicFeeSettings;
    DynamicFeeSettings public level2DynamicFeeSettings;

    // funding rate
    FundingRate public fundingRate;

    // x and y
    Decimal.decimal public quoteAssetReserve;
    Decimal.decimal public baseAssetReserve;
    Decimal.decimal public k;

    // caps
    Decimal.decimal internal maxHoldingBaseAsset;
    Decimal.decimal internal openInterestNotionalCap;

    SignedDecimal.signedDecimal public totalPositionSize;
    SignedDecimal.signedDecimal public cumulativeNotional;
    SignedDecimal.signedDecimal public baseAssetDeltaThisFundingPeriod;
    Decimal.decimal public _x0;
    Decimal.decimal public _y0;

    uint256 public override fundingPeriod;
    uint256 public markPriceTwapInterval;
    uint256 public nextFundingTime;
    uint256 public fundingBufferPeriod;
    uint256 public lastRepegTimestamp;
    uint256 public repegBufferPeriod;
    IPriceFeed public priceFeed;
    bytes32 public priceFeedKey;
    address public counterParty;
    IERC20 public override quoteAsset;
    bool public override open;

    ReserveSnapshot[] public reserveSnapshots;

    // events
    event Open(bool indexed open);
    event SwapInput(Dir dir, uint256 quoteAssetAmount, uint256 baseAssetAmount);
    event SwapOutput(
        Dir dir,
        uint256 quoteAssetAmount,
        uint256 baseAssetAmount
    );
    event FundingRateUpdated(
        int256 fundingRateLong,
        int256 fundingRateShort,
        uint256 underlyingPrice
    );
    event ReserveSnapshotted(
        uint256 quoteAssetReserve,
        uint256 baseAssetReserve,
        uint256 timestamp
    );
    event FeeRatioChanged(uint256 ratio);
    event TradeLimitRatioChanged(uint256 ratio);
    event FluctuationLimitRatioChanged(uint256 ratio);
    event InitMarginRatioChanged(uint256 ratio);
    event MaintenanceMarginRatioChanged(uint256 ratio);
    event PartialLiquidationRatioChanged(uint256 ratio);
    event LiquidationFeeRatioChanged(uint256 ratio);
    event Level1DynamicFeeSettingsChanged(
        uint256 divergenceThresholdRatio,
        uint256 feeRatio,
        uint256 feeInFavorRatio
    );
    event Level2DynamicFeeSettingsChanged(
        uint256 divergenceThresholdRatio,
        uint256 feeRatio,
        uint256 feeInFavorRatio
    );
    event FundingPeriodChanged(uint256 fundingPeriod);
    event CapChanged(
        uint256 maxHoldingBaseAsset,
        uint256 openInterestNotionalCap
    );
    event PriceFeedUpdated(address indexed priceFeed);
    event Repeg(
        uint256 quoteAssetReserveBefore,
        uint256 baseAssetReserveBefore,
        uint256 quoteAssetReserveAfter,
        uint256 baseAssetReserveAfter,
        int256 repegPnl
    );

    modifier onlyOpen() {
        require(open, "amm was closed");
        _;
    }

    modifier onlyCounterParty() {
        require(counterParty == _msgSender(), "caller is not counterParty");
        _;
    }

    //
    // EXTERNAL
    //

    /**
     * upgradeable constructor, can only be inited once
     */
    function initialize(
        uint256 _quoteAssetReserve,
        uint256 _baseAssetReserve,
        uint256 _tradeLimitRatio,
        uint256 _fundingPeriod,
        IPriceFeed _priceFeed,
        bytes32 _priceFeedKey,
        address _quoteAsset,
        uint256 _fluctuationLimitRatio,
        uint256 _feeRatio
    ) public initializer {
        require(
            _quoteAssetReserve != 0 &&
                _tradeLimitRatio != 0 &&
                _baseAssetReserve != 0 &&
                _fundingPeriod != 0 &&
                address(_priceFeed) != address(0) &&
                _quoteAsset != address(0),
            "invalid input"
        );
        __Ownable_init();

        quoteAssetReserve = Decimal.decimal(_quoteAssetReserve);
        baseAssetReserve = Decimal.decimal(_baseAssetReserve);
        k = quoteAssetReserve.mulD(baseAssetReserve);
        tradeLimitRatio = Decimal.decimal(_tradeLimitRatio);
        feeRatio = Decimal.decimal(_feeRatio);
        fluctuationLimitRatio = Decimal.decimal(_fluctuationLimitRatio);
        fundingPeriod = _fundingPeriod;
        fundingBufferPeriod = _fundingPeriod / 2;
        repegBufferPeriod = 12 hours;
        markPriceTwapInterval = fundingPeriod;
        priceFeedKey = _priceFeedKey;
        quoteAsset = IERC20(_quoteAsset);
        priceFeed = _priceFeed;
        reserveSnapshots.push(
            ReserveSnapshot(
                quoteAssetReserve,
                baseAssetReserve,
                block.timestamp,
                block.number
            )
        );
        emit ReserveSnapshotted(
            quoteAssetReserve.toUint(),
            baseAssetReserve.toUint(),
            block.timestamp
        );
        _x0 = Decimal.decimal(_baseAssetReserve);
        _y0 = Decimal.decimal(_quoteAssetReserve);
    }

    /**
     * @notice Swap your quote asset to base asset, the impact of the price MUST be less than `fluctuationLimitRatio`
     * @dev Only clearingHouse can call this function
     * @param _dirOfQuote ADD_TO_AMM for long, REMOVE_FROM_AMM for short
     * @param _quoteAssetAmount quote asset amount
     * @param _baseAssetAmountLimit minimum base asset amount expected to get to prevent front running
     * @param _canOverFluctuationLimit if tx can go over fluctuation limit once; for partial liquidation
     * @return base asset amount
     */
    function swapInput(
        Dir _dirOfQuote,
        Decimal.decimal calldata _quoteAssetAmount,
        Decimal.decimal calldata _baseAssetAmountLimit,
        bool _canOverFluctuationLimit
    )
        external
        override
        onlyOpen
        onlyCounterParty
        returns (Decimal.decimal memory)
    {
        if (_quoteAssetAmount.toUint() == 0) {
            return Decimal.zero();
        }
        if (_dirOfQuote == Dir.REMOVE_FROM_AMM) {
            require(
                quoteAssetReserve.mulD(tradeLimitRatio).toUint() >=
                    _quoteAssetAmount.toUint(),
                "over trading limit"
            );
        }

        Decimal.decimal memory baseAssetAmount = getInputPrice(
            _dirOfQuote,
            _quoteAssetAmount
        );
        // If LONG, exchanged base amount should be more than _baseAssetAmountLimit,
        // otherwise(SHORT), exchanged base amount should be less than _baseAssetAmountLimit.
        // In SHORT case, more position means more debt so should not be larger than _baseAssetAmountLimit
        if (_baseAssetAmountLimit.toUint() != 0) {
            if (_dirOfQuote == Dir.ADD_TO_AMM) {
                require(
                    baseAssetAmount.toUint() >= _baseAssetAmountLimit.toUint(),
                    "Less than minimal base token"
                );
            } else {
                require(
                    baseAssetAmount.toUint() <= _baseAssetAmountLimit.toUint(),
                    "More than maximal base token"
                );
            }
        }

        _updateReserve(
            _dirOfQuote,
            _quoteAssetAmount,
            baseAssetAmount,
            _canOverFluctuationLimit
        );
        emit SwapInput(
            _dirOfQuote,
            _quoteAssetAmount.toUint(),
            baseAssetAmount.toUint()
        );
        return baseAssetAmount;
    }

    /**
     * @notice swap your base asset to quote asset; NOTE it is only used during close/liquidate positions so it always allows going over fluctuation limit
     * @dev only clearingHouse can call this function
     * @param _dirOfBase ADD_TO_AMM for short, REMOVE_FROM_AMM for long, opposite direction from swapInput
     * @param _baseAssetAmount base asset amount
     * @param _quoteAssetAmountLimit limit of quote asset amount; for slippage protection
     * @return quote asset amount
     */
    function swapOutput(
        Dir _dirOfBase,
        Decimal.decimal calldata _baseAssetAmount,
        Decimal.decimal calldata _quoteAssetAmountLimit
    )
        external
        override
        onlyOpen
        onlyCounterParty
        returns (Decimal.decimal memory)
    {
        return
            implSwapOutput(
                _dirOfBase,
                _baseAssetAmount,
                _quoteAssetAmountLimit
            );
    }

    /**
     * @notice update funding rate
     * @dev only allow to update while reaching `nextFundingTime`
     * @return premiumFraction of this period in 18 digits
     * @return markPrice of this period in 18 digits
     * @return indexPrice of this period in 18 digits
     */
    function settleFunding()
        external
        override
        onlyOpen
        onlyCounterParty
        returns (
            SignedDecimal.signedDecimal memory premiumFraction,
            Decimal.decimal memory markPrice,
            Decimal.decimal memory indexPrice
        )
    {
        require(block.timestamp >= nextFundingTime, "settle funding too early");

        // premium = twapMarketPrice - twapIndexPrice
        // timeFraction = fundingPeriod(1 hour) / 1 day
        // premiumFraction = premium * timeFraction
        markPrice = getTwapPrice(markPriceTwapInterval);
        indexPrice = getIndexPrice();

        SignedDecimal.signedDecimal memory premium = MixedDecimal
            .fromDecimal(markPrice)
            .subD(indexPrice);

        premiumFraction = premium.mulScalar(fundingPeriod).divScalar(
            int256(1 days)
        );

        // in order to prevent multiple funding settlement during very short time after network congestion
        uint256 minNextValidFundingTime = block.timestamp + fundingBufferPeriod;

        // floor((nextFundingTime + fundingPeriod) / 3600) * 3600
        uint256 nextFundingTimeOnHourStart = ((nextFundingTime +
            fundingPeriod) / 1 hours) * 1 hours;

        // max(nextFundingTimeOnHourStart, minNextValidFundingTime)
        nextFundingTime = nextFundingTimeOnHourStart > minNextValidFundingTime
            ? nextFundingTimeOnHourStart
            : minNextValidFundingTime;

        // DEPRECATED only for backward compatibility before we upgrade ClearingHouse
        // reset funding related states
        baseAssetDeltaThisFundingPeriod = SignedDecimal.zero();
    }

    /**
     * @notice repeg mark price to index price
     * @dev only clearing house can call
     */
    function repegPrice()
        external
        override
        onlyOpen
        onlyCounterParty
        returns (
            Decimal.decimal memory,
            Decimal.decimal memory,
            Decimal.decimal memory,
            Decimal.decimal memory,
            SignedDecimal.signedDecimal memory
        )
    {
        require(
            block.timestamp >= lastRepegTimestamp + repegBufferPeriod,
            "repeg interval too small"
        );
        Decimal.decimal memory indexPrice = getIndexPrice();

        // calculation must be done before repeg
        SignedDecimal.signedDecimal memory repegPnl = calcPriceRepegPnl(
            indexPrice
        );

        // REPEG, y / x = price, y = price * x
        Decimal.decimal memory quoteAssetReserveBefore = quoteAssetReserve;
        quoteAssetReserve = indexPrice.mulD(baseAssetReserve);
        k = quoteAssetReserve.mulD(baseAssetReserve);
        lastRepegTimestamp = block.timestamp;

        // update repeg checkpoints
        _y0 = quoteAssetReserve;
        _x0 = baseAssetReserve;

        // add reserve snapshot, should be only after updating reserves
        _addReserveSnapshot();

        emit Repeg(
            quoteAssetReserveBefore.toUint(),
            baseAssetReserve.toUint(),
            quoteAssetReserve.toUint(),
            baseAssetReserve.toUint(),
            repegPnl.toInt()
        );
        return (
            quoteAssetReserveBefore,
            baseAssetReserve,
            quoteAssetReserve,
            baseAssetReserve,
            repegPnl
        );
    }

    /**
     * @notice adjust liquidity depth
     * @dev only clearing house can call
     */
    function repegK(
        Decimal.decimal memory _multiplier
    )
        external
        override
        onlyOpen
        onlyCounterParty
        returns (
            Decimal.decimal memory,
            Decimal.decimal memory,
            Decimal.decimal memory,
            Decimal.decimal memory,
            SignedDecimal.signedDecimal memory
        )
    {
        require(
            block.timestamp >= lastRepegTimestamp + repegBufferPeriod,
            "repeg interval too small"
        );

        Decimal.decimal memory multiplierSqrt = _multiplier.sqrt();

        Decimal.decimal memory quoteAssetReserveBefore = quoteAssetReserve;
        Decimal.decimal memory baseAssetReserveBefore = baseAssetReserve;

        Decimal.decimal memory quoteAssetReserveAfter = quoteAssetReserveBefore
            .mulD(multiplierSqrt);
        Decimal.decimal memory baseAssetReserveAfter = baseAssetReserveBefore
            .mulD(multiplierSqrt);
        Decimal.decimal memory _k = quoteAssetReserveAfter.mulD(
            baseAssetReserveAfter
        );

        // calculation must be done before repeg
        SignedDecimal.signedDecimal memory repegPnl = calcKRepegPnl(_k);

        // REPEG
        quoteAssetReserve = quoteAssetReserveAfter;
        baseAssetReserve = baseAssetReserveAfter;
        k = _k;
        lastRepegTimestamp = block.timestamp;

        // update repeg checkpoints
        _y0 = quoteAssetReserveAfter;
        _x0 = baseAssetReserveAfter;

        // add reserve snapshot, should be only after updating reserves
        _addReserveSnapshot();

        emit Repeg(
            quoteAssetReserveBefore.toUint(),
            baseAssetReserveBefore.toUint(),
            quoteAssetReserveAfter.toUint(),
            baseAssetReserveAfter.toUint(),
            repegPnl.toInt()
        );

        return (
            quoteAssetReserveBefore,
            baseAssetReserveBefore,
            quoteAssetReserveAfter,
            baseAssetReserveAfter,
            repegPnl
        );
    }

    // update funding rate = premiumFraction / twapIndexPrice
    function updateFundingRate(
        SignedDecimal.signedDecimal memory _premiumFractionLong,
        SignedDecimal.signedDecimal memory _premiumFractionShort,
        Decimal.decimal memory _underlyingPrice
    ) external override onlyOpen onlyCounterParty {
        fundingRate.fundingRateLong = _premiumFractionLong.divD(
            _underlyingPrice
        );
        fundingRate.fundingRateShort = _premiumFractionShort.divD(
            _underlyingPrice
        );
        emit FundingRateUpdated(
            fundingRate.fundingRateLong.toInt(),
            fundingRate.fundingRateShort.toInt(),
            _underlyingPrice.toUint()
        );
    }

    /**
     * @notice set counter party
     * @dev only owner can call this function
     * @param _counterParty address of counter party
     */
    function setCounterParty(address _counterParty) external onlyOwner {
        counterParty = _counterParty;
    }

    /**
     * @notice set `open` flag. Amm is open to trade if `open` is true. Default is false.
     * @dev only owner can call this function
     * @param _open open to trade is true, otherwise is false.
     */
    function setOpen(bool _open) external onlyOwner {
        if (open == _open) return;

        open = _open;
        if (_open) {
            nextFundingTime =
                ((block.timestamp + fundingPeriod) / 1 hours) *
                1 hours;
        }
        emit Open(_open);
    }

    /**
     * @notice set new fee ratio
     * @dev only owner can call
     * @param _feeRatio new ratio
     */
    function setFeeRatio(Decimal.decimal memory _feeRatio) external onlyOwner {
        feeRatio = _feeRatio;
        emit FeeRatioChanged(feeRatio.toUint());
    }

    /**
     * @notice set new trade limit ratio
     * @dev only owner
     * @param _tradeLimitRatio new ratio
     */
    function setTradeLimitRatio(
        Decimal.decimal memory _tradeLimitRatio
    ) external onlyOwner {
        _requireValidRatio(_tradeLimitRatio);
        tradeLimitRatio = _tradeLimitRatio;
        emit TradeLimitRatioChanged(tradeLimitRatio.toUint());
    }

    /**
     * @notice set fluctuation limit rate. Default value is `1 / max leverage`
     * @dev only owner can call this function
     * @param _fluctuationLimitRatio fluctuation limit rate in 18 digits, 0 means skip the checking
     */
    function setFluctuationLimitRatio(
        Decimal.decimal memory _fluctuationLimitRatio
    ) external onlyOwner {
        fluctuationLimitRatio = _fluctuationLimitRatio;
        emit FluctuationLimitRatioChanged(fluctuationLimitRatio.toUint());
    }

    /**
     * @notice set init margin ratio
     * @dev only owner can call
     * @param _initMarginRatio new maintenance margin ratio in 18 digits
     */
    function setInitMarginRatio(
        Decimal.decimal memory _initMarginRatio
    ) external onlyOwner {
        _requireValidRatio(_initMarginRatio);
        initMarginRatio = _initMarginRatio;
        emit InitMarginRatioChanged(initMarginRatio.toUint());
    }

    /**
     * @notice set maintenance margin ratio
     * @dev only owner can call
     * @param _maintenanceMarginRatio new maintenance margin ratio in 18 digits
     */
    function setMaintenanceMarginRatio(
        Decimal.decimal memory _maintenanceMarginRatio
    ) external onlyOwner {
        _requireValidRatio(_maintenanceMarginRatio);
        maintenanceMarginRatio = _maintenanceMarginRatio;
        emit MaintenanceMarginRatioChanged(maintenanceMarginRatio.toUint());
    }

    /**
     * @notice set the margin ratio after deleveraging
     * @dev only owner can call
     * @param _partialLiquidationRatio new ratio
     */
    function setPartialLiquidationRatio(
        Decimal.decimal memory _partialLiquidationRatio
    ) external onlyOwner {
        _requireValidRatio(_partialLiquidationRatio);
        // solhint-disable-next-line reason-string
        require(
            _partialLiquidationRatio.cmp(Decimal.one()) < 0,
            "partial liq ratio should be less than 1"
        );
        partialLiquidationRatio = _partialLiquidationRatio;
        emit PartialLiquidationRatioChanged(partialLiquidationRatio.toUint());
    }

    /**
     * @notice set liquidation fee ratio
     * @dev if margin ratio falls below liquidation fee ratio, entire position is liquidated
     * @dev only owner can call
     * @param _liquidationFeeRatio new ratio
     */
    function setLiquidationFeeRatio(
        Decimal.decimal memory _liquidationFeeRatio
    ) external onlyOwner {
        _requireValidRatio(_liquidationFeeRatio);
        liquidationFeeRatio = _liquidationFeeRatio;
        emit LiquidationFeeRatioChanged(liquidationFeeRatio.toUint());
    }

    /**
     * Set level 1 dynamic fee settings
     * only owner
     * @dev set threshold as 0 to disable
     */
    function setLevel1DynamicFeeSettings(
        Decimal.decimal memory _divergenceThresholdRatio,
        Decimal.decimal memory _feeRatio,
        Decimal.decimal memory _feeInFavorRatio
    ) external onlyOwner {
        level1DynamicFeeSettings = DynamicFeeSettings(
            _divergenceThresholdRatio,
            _feeRatio,
            _feeInFavorRatio
        );
        emit Level1DynamicFeeSettingsChanged(
            _divergenceThresholdRatio.toUint(),
            _feeRatio.toUint(),
            _feeInFavorRatio.toUint()
        );
    }

    /**
     * Set level 2 dynamic fee settings
     * only owner
     * @dev set threshold as 0 to disable
     */
    function setLevel2DynamicFeeSettings(
        Decimal.decimal memory _divergenceThresholdRatio,
        Decimal.decimal memory _feeRatio,
        Decimal.decimal memory _feeInFavorRatio
    ) external onlyOwner {
        level2DynamicFeeSettings = DynamicFeeSettings(
            _divergenceThresholdRatio,
            _feeRatio,
            _feeInFavorRatio
        );
        emit Level2DynamicFeeSettingsChanged(
            _divergenceThresholdRatio.toUint(),
            _feeRatio.toUint(),
            _feeInFavorRatio.toUint()
        );
    }

    /**
     * @notice set new cap during guarded period, which is max position size that traders can hold
     * @dev only owner can call. assume this will be removes soon once the guarded period has ended. must be set before opening amm
     * @param _maxHoldingBaseAsset max position size that traders can hold in 18 digits
     * @param _openInterestNotionalCap open interest cap, denominated in quoteToken
     */
    function setCap(
        Decimal.decimal memory _maxHoldingBaseAsset,
        Decimal.decimal memory _openInterestNotionalCap
    ) external onlyOwner {
        maxHoldingBaseAsset = _maxHoldingBaseAsset;
        openInterestNotionalCap = _openInterestNotionalCap;
        emit CapChanged(
            maxHoldingBaseAsset.toUint(),
            openInterestNotionalCap.toUint()
        );
    }

    /**
     * @notice set funding period
     * @dev only owner
     * @param _fundingPeriod new funding period
     */
    function setFundingPeriod(uint256 _fundingPeriod) external onlyOwner {
        fundingPeriod = _fundingPeriod;
        fundingBufferPeriod = _fundingPeriod / 2;
        emit FundingPeriodChanged(_fundingPeriod);
    }

    /**
     * @notice set repeg buffer period
     * @dev only owner
     * @param _repegBufferPeriod new repeg buffer period
     */
    function setRepegBufferPeriod(
        uint256 _repegBufferPeriod
    ) external onlyOwner {
        repegBufferPeriod = _repegBufferPeriod;
    }

    /**
     * @notice set time interval for twap calculation, default is 1 hour
     * @dev only owner can call this function
     * @param _interval time interval in seconds
     */
    function setMarkPriceTwapInterval(uint256 _interval) external onlyOwner {
        require(_interval != 0, "can not set interval to 0");
        markPriceTwapInterval = _interval;
    }

    /**
     * @notice set priceFeed address
     * @dev only owner can call
     * @param _priceFeed new price feed for this AMM
     */
    function setPriceFeed(IPriceFeed _priceFeed) external onlyOwner {
        require(address(_priceFeed) != address(0), "invalid PriceFeed address");
        priceFeed = _priceFeed;
        emit PriceFeedUpdated(address(priceFeed));
    }

    /**
     * @notice dynamic fee mechanism (only on open position, not on close)
     * - if trade leaves mark price to be within 2.5% range of index price, then fee percent = 0.3% (standard)
     * - if trade leaves mark price to be over 2.5% range of index price, then fee percent = 1% (surged)
     * - if trade leaves mark price to be over 5.0% range of index price, then fee percent = 5% (surged)
     * - this ensures that traders act towards maintaining peg
     * @notice calculate fees to be levied on the trade
     * @param _dirOfQuote ADD_TO_AMM for long, REMOVE_FROM_AMM for short
     * @param _quoteAssetAmount quoteAssetAmount
     * @param _isOpenPos whether is opening a new position
     * @return fees fees to be levied on trade
     */
    function calcFee(
        Dir _dirOfQuote,
        Decimal.decimal calldata _quoteAssetAmount,
        bool _isOpenPos
    ) external view override returns (Decimal.decimal memory fees) {
        if (_quoteAssetAmount.toUint() == 0) {
            return Decimal.zero();
        }
        Decimal.decimal memory indexPrice = getIndexPrice();
        Decimal.decimal memory markPrice = getMarkPrice();

        uint256 divergenceRatio = MixedDecimal
            .fromDecimal(indexPrice)
            .subD(markPrice)
            .abs()
            .divD(indexPrice)
            .toUint();

        bool isConvergingTrade = (
            markPrice.toUint() < indexPrice.toUint()
                ? Dir.ADD_TO_AMM
                : Dir.REMOVE_FROM_AMM
        ) == _dirOfQuote;

        Decimal.decimal memory _feeRatio = feeRatio;

        // implying surge fee pricing only on open position
        if (_isOpenPos) {
            if (
                level2DynamicFeeSettings.divergenceThresholdRatio.toUint() !=
                0 && // 0 means unset/disabled
                divergenceRatio >
                level2DynamicFeeSettings.divergenceThresholdRatio.toUint()
            ) {
                if (isConvergingTrade)
                    _feeRatio = level2DynamicFeeSettings.feeInFavorRatio;
                else _feeRatio = level2DynamicFeeSettings.feeRatio;
            } else if (
                level1DynamicFeeSettings.divergenceThresholdRatio.toUint() !=
                0 &&
                divergenceRatio >
                level1DynamicFeeSettings.divergenceThresholdRatio.toUint()
            ) {
                if (isConvergingTrade)
                    _feeRatio = level1DynamicFeeSettings.feeInFavorRatio;
                else _feeRatio = level1DynamicFeeSettings.feeRatio;
            }
        }
        fees = _quoteAssetAmount.mulD(_feeRatio);
    }

    /**
     * @notice get input twap amount.
     * returns how many base asset you will get with the input quote amount based on twap price.
     * @param _dirOfQuote ADD_TO_AMM for long, REMOVE_FROM_AMM for short.
     * @param _quoteAssetAmount quote asset amount
     * @return base asset amount
     */
    function getInputTwap(
        Dir _dirOfQuote,
        Decimal.decimal memory _quoteAssetAmount
    ) external view override returns (Decimal.decimal memory) {
        return
            _implGetInputAssetTwapPrice(
                _dirOfQuote,
                _quoteAssetAmount,
                QuoteAssetDir.QUOTE_IN,
                15 minutes
            );
    }

    /**
     * @notice calculate repeg pnl
     * @param _repegTo price to repeg to
     * @return repegPnl total pnl incurred on vault positions after repeg
     */
    function calcPriceRepegPnl(
        Decimal.decimal memory _repegTo
    ) public view returns (SignedDecimal.signedDecimal memory repegPnl) {
        SignedDecimal.signedDecimal memory y0 = MixedDecimal.fromDecimal(_y0);
        SignedDecimal.signedDecimal memory x0 = MixedDecimal.fromDecimal(_x0);
        SignedDecimal.signedDecimal memory p0 = y0.divD(x0);
        SignedDecimal.signedDecimal memory p1 = MixedDecimal.fromDecimal(
            getMarkPrice()
        );
        SignedDecimal.signedDecimal memory p2 = MixedDecimal.fromDecimal(
            _repegTo
        );
        repegPnl = y0.mulD(
            p2
                .divD(p1)
                .addD(p1.divD(p0).sqrt())
                .subD(p2.divD(p1.mulD(p0).sqrt()))
                .subD(Decimal.one())
        );
    }

    function calcKRepegPnl(
        Decimal.decimal memory _k
    ) public view returns (SignedDecimal.signedDecimal memory repegPnl) {
        SignedDecimal.signedDecimal memory x0 = MixedDecimal.fromDecimal(_x0);
        SignedDecimal.signedDecimal memory y0 = MixedDecimal.fromDecimal(_y0);
        SignedDecimal.signedDecimal memory p0 = y0.divD(x0);
        SignedDecimal.signedDecimal memory k0 = y0.mulD(x0);
        SignedDecimal.signedDecimal memory p1 = MixedDecimal.fromDecimal(
            getMarkPrice()
        );
        SignedDecimal.signedDecimal memory k1 = MixedDecimal.fromDecimal(_k);
        SignedDecimal.signedDecimal memory firstDenom = k1
            .divD(p1)
            .sqrt()
            .subD(k0.divD(p1).sqrt())
            .addD(k0.divD(p0).sqrt());
        repegPnl = k1
            .divD(firstDenom)
            .subD(k1.mulD(p1).sqrt())
            .subD(k0.mulD(p0).sqrt())
            .addD(k0.mulD(p1).sqrt());
    }

    /**
     * @notice get output twap amount.
     * return how many quote asset you will get with the input base amount on twap price.
     * @param _dirOfBase ADD_TO_AMM for short, REMOVE_FROM_AMM for long, opposite direction from `getInputTwap`.
     * @param _baseAssetAmount base asset amount
     * @return quote asset amount
     */
    function getOutputTwap(
        Dir _dirOfBase,
        Decimal.decimal memory _baseAssetAmount
    ) external view override returns (Decimal.decimal memory) {
        return
            _implGetInputAssetTwapPrice(
                _dirOfBase,
                _baseAssetAmount,
                QuoteAssetDir.QUOTE_OUT,
                15 minutes
            );
    }

    /**
     * @notice check if close trade goes over fluctuation limit
     * @param _dirOfBase ADD_TO_AMM for closing long, REMOVE_FROM_AMM for closing short
     */
    function isOverFluctuationLimit(
        Dir _dirOfBase,
        Decimal.decimal memory _baseAssetAmount
    ) external view override returns (bool) {
        // Skip the check if the limit is 0
        if (fluctuationLimitRatio.toUint() == 0) {
            return false;
        }

        (
            Decimal.decimal memory upperLimit,
            Decimal.decimal memory lowerLimit
        ) = _getPriceBoundariesOfLastBlock();

        Decimal.decimal memory quoteAssetExchanged = getOutputPrice(
            _dirOfBase,
            _baseAssetAmount
        );
        Decimal.decimal memory price = (_dirOfBase == Dir.REMOVE_FROM_AMM)
            ? quoteAssetReserve.addD(quoteAssetExchanged).divD(
                baseAssetReserve.subD(_baseAssetAmount)
            )
            : quoteAssetReserve.subD(quoteAssetExchanged).divD(
                baseAssetReserve.addD(_baseAssetAmount)
            );

        if (price.cmp(upperLimit) <= 0 && price.cmp(lowerLimit) >= 0) {
            return false;
        }
        return true;
    }

    function isOverSpreadLimit() external view override returns (bool) {
        Decimal.decimal memory oraclePrice = getIndexPrice();
        require(oraclePrice.toUint() > 0, "index price is 0");
        Decimal.decimal memory marketPrice = getMarkPrice();
        Decimal.decimal memory oracleSpreadRatioAbs = MixedDecimal
            .fromDecimal(marketPrice)
            .subD(oraclePrice)
            .divD(oraclePrice)
            .abs();
        // TODO move to variable
        return oracleSpreadRatioAbs.toUint() >= 1e17; // 10%
    }

    function getSnapshotLen() external view returns (uint256) {
        return reserveSnapshots.length;
    }

    function getFeeRatio()
        external
        view
        override
        returns (Decimal.decimal memory)
    {
        return feeRatio;
    }

    function getInitMarginRatio()
        external
        view
        override
        returns (Decimal.decimal memory)
    {
        return initMarginRatio;
    }

    function getMaintenanceMarginRatio()
        external
        view
        override
        returns (Decimal.decimal memory)
    {
        return maintenanceMarginRatio;
    }

    function getPartialLiquidationRatio()
        external
        view
        override
        returns (Decimal.decimal memory)
    {
        return partialLiquidationRatio;
    }

    function getLiquidationFeeRatio()
        external
        view
        override
        returns (Decimal.decimal memory)
    {
        return liquidationFeeRatio;
    }

    /**
     * too avoid too many ratio calls in clearing house
     */
    function getRatios() external view override returns (Ratios memory) {
        return
            Ratios(
                feeRatio,
                initMarginRatio,
                maintenanceMarginRatio,
                partialLiquidationRatio,
                liquidationFeeRatio
            );
    }

    /**
     * @notice get current quote/base asset reserve.
     * @return (quote asset reserve, base asset reserve)
     */
    function getReserves()
        external
        view
        returns (Decimal.decimal memory, Decimal.decimal memory)
    {
        return (quoteAssetReserve, baseAssetReserve);
    }

    function getMaxHoldingBaseAsset()
        external
        view
        override
        returns (Decimal.decimal memory)
    {
        return maxHoldingBaseAsset;
    }

    function getOpenInterestNotionalCap()
        external
        view
        override
        returns (Decimal.decimal memory)
    {
        return openInterestNotionalCap;
    }

    function getBaseAssetDelta()
        external
        view
        override
        returns (SignedDecimal.signedDecimal memory)
    {
        return totalPositionSize;
    }

    function getCumulativeNotional()
        external
        view
        override
        returns (SignedDecimal.signedDecimal memory)
    {
        return cumulativeNotional;
    }

    //
    // PUBLIC
    //

    /**
     * @notice get input amount. returns how many base asset you will get with the input quote amount.
     * @param _dirOfQuote ADD_TO_AMM for long, REMOVE_FROM_AMM for short.
     * @param _quoteAssetAmount quote asset amount
     * @return base asset amount
     */
    function getInputPrice(
        Dir _dirOfQuote,
        Decimal.decimal memory _quoteAssetAmount
    ) public view override returns (Decimal.decimal memory) {
        return
            getInputPriceWithReserves(
                _dirOfQuote,
                _quoteAssetAmount,
                quoteAssetReserve,
                baseAssetReserve
            );
    }

    /**
     * @notice get output price. return how many quote asset you will get with the input base amount
     * @param _dirOfBase ADD_TO_AMM for short, REMOVE_FROM_AMM for long, opposite direction from `getInput`.
     * @param _baseAssetAmount base asset amount
     * @return quote asset amount
     */
    function getOutputPrice(
        Dir _dirOfBase,
        Decimal.decimal memory _baseAssetAmount
    ) public view override returns (Decimal.decimal memory) {
        return
            getOutputPriceWithReserves(
                _dirOfBase,
                _baseAssetAmount,
                quoteAssetReserve,
                baseAssetReserve
            );
    }

    /**
     * @notice get mark price based on current quote/base asset reserve.
     * @return mark price
     */
    function getMarkPrice()
        public
        view
        override
        returns (Decimal.decimal memory)
    {
        return quoteAssetReserve.divD(baseAssetReserve);
    }

    /**
     * @notice get index price provided by oracle
     * @return index price
     */
    function getIndexPrice()
        public
        view
        override
        returns (Decimal.decimal memory)
    {
        return Decimal.decimal(priceFeed.getPrice(priceFeedKey));
    }

    /**
     * @notice get twap price
     */
    function getTwapPrice(
        uint256 _intervalInSeconds
    ) public view returns (Decimal.decimal memory) {
        return _implGetReserveTwapPrice(_intervalInSeconds);
    }

    /*       plus/minus 1 while the amount is not dividable
     *
     *        getInputPrice                         getOutputPrice
     *
     *     ＡＤＤ      (amount - 1)              (amount + 1)   ＲＥＭＯＶＥ
     *      ◥◤            ▲                         |             ◢◣
     *      ◥◤  ------->  |                         ▼  <--------  ◢◣
     *    -------      -------                   -------        -------
     *    |  Q  |      |  B  |                   |  Q  |        |  B  |
     *    -------      -------                   -------        -------
     *      ◥◤  ------->  ▲                         |  <--------  ◢◣
     *      ◥◤            |                         ▼             ◢◣
     *   ＲＥＭＯＶＥ  (amount + 1)              (amount + 1)      ＡＤＤ
     **/

    function getInputPriceWithReserves(
        Dir _dirOfQuote,
        Decimal.decimal memory _quoteAssetAmount,
        Decimal.decimal memory _quoteAssetPoolAmount,
        Decimal.decimal memory _baseAssetPoolAmount
    ) public view override returns (Decimal.decimal memory) {
        if (_quoteAssetAmount.toUint() == 0) {
            return Decimal.zero();
        }

        bool isAddToAmm = _dirOfQuote == Dir.ADD_TO_AMM;

        SignedDecimal.signedDecimal memory baseAssetAfter;
        Decimal.decimal memory quoteAssetAfter;
        Decimal.decimal memory baseAssetBought;

        if (isAddToAmm) {
            quoteAssetAfter = _quoteAssetPoolAmount.addD(_quoteAssetAmount);
        } else {
            quoteAssetAfter = _quoteAssetPoolAmount.subD(_quoteAssetAmount);
        }
        require(quoteAssetAfter.toUint() != 0, "quote asset after is 0");

        baseAssetAfter = MixedDecimal.fromDecimal(k).divD(quoteAssetAfter);
        baseAssetBought = baseAssetAfter.subD(_baseAssetPoolAmount).abs();

        return baseAssetBought;
    }

    function getOutputPriceWithReserves(
        Dir _dirOfBase,
        Decimal.decimal memory _baseAssetAmount,
        Decimal.decimal memory _quoteAssetPoolAmount,
        Decimal.decimal memory _baseAssetPoolAmount
    ) public view override returns (Decimal.decimal memory) {
        if (_baseAssetAmount.toUint() == 0) {
            return Decimal.zero();
        }

        bool isAddToAmm = _dirOfBase == Dir.ADD_TO_AMM;

        SignedDecimal.signedDecimal memory quoteAssetAfter;
        Decimal.decimal memory baseAssetAfter;
        Decimal.decimal memory quoteAssetSold;

        if (isAddToAmm) {
            baseAssetAfter = _baseAssetPoolAmount.addD(_baseAssetAmount);
        } else {
            baseAssetAfter = _baseAssetPoolAmount.subD(_baseAssetAmount);
        }
        require(baseAssetAfter.toUint() != 0, "base asset after is 0");

        quoteAssetAfter = MixedDecimal.fromDecimal(k).divD(baseAssetAfter);
        quoteAssetSold = quoteAssetAfter.subD(_quoteAssetPoolAmount).abs();

        return quoteAssetSold;
    }

    //
    // INTERNAL
    //

    function _addReserveSnapshot() internal {
        uint256 currentBlock = block.number;
        ReserveSnapshot storage latestSnapshot = reserveSnapshots[
            reserveSnapshots.length - 1
        ];
        // update values in snapshot if in the same block
        if (currentBlock == latestSnapshot.blockNumber) {
            latestSnapshot.quoteAssetReserve = quoteAssetReserve;
            latestSnapshot.baseAssetReserve = baseAssetReserve;
        } else {
            reserveSnapshots.push(
                ReserveSnapshot(
                    quoteAssetReserve,
                    baseAssetReserve,
                    block.timestamp,
                    currentBlock
                )
            );
        }
        emit ReserveSnapshotted(
            quoteAssetReserve.toUint(),
            baseAssetReserve.toUint(),
            block.timestamp
        );
    }

    function implSwapOutput(
        Dir _dirOfBase,
        Decimal.decimal memory _baseAssetAmount,
        Decimal.decimal memory _quoteAssetAmountLimit
    ) internal returns (Decimal.decimal memory) {
        if (_baseAssetAmount.toUint() == 0) {
            return Decimal.zero();
        }
        if (_dirOfBase == Dir.REMOVE_FROM_AMM) {
            require(
                baseAssetReserve.mulD(tradeLimitRatio).toUint() >=
                    _baseAssetAmount.toUint(),
                "over trading limit"
            );
        }

        Decimal.decimal memory quoteAssetAmount = getOutputPrice(
            _dirOfBase,
            _baseAssetAmount
        );
        Dir dirOfQuote = _dirOfBase == Dir.ADD_TO_AMM
            ? Dir.REMOVE_FROM_AMM
            : Dir.ADD_TO_AMM;
        // If SHORT, exchanged quote amount should be less than _quoteAssetAmountLimit,
        // otherwise(LONG), exchanged base amount should be more than _quoteAssetAmountLimit.
        // In the SHORT case, more quote assets means more payment so should not be more than _quoteAssetAmountLimit
        if (_quoteAssetAmountLimit.toUint() != 0) {
            if (dirOfQuote == Dir.REMOVE_FROM_AMM) {
                // SHORT
                require(
                    quoteAssetAmount.toUint() >=
                        _quoteAssetAmountLimit.toUint(),
                    "Less than minimal quote token"
                );
            } else {
                // LONG
                require(
                    quoteAssetAmount.toUint() <=
                        _quoteAssetAmountLimit.toUint(),
                    "More than maximal quote token"
                );
            }
        }

        // as mentioned in swapOutput(), it always allows going over fluctuation limit because
        // it is only used by close/liquidate positions
        _updateReserve(dirOfQuote, quoteAssetAmount, _baseAssetAmount, true);
        emit SwapOutput(
            _dirOfBase,
            quoteAssetAmount.toUint(),
            _baseAssetAmount.toUint()
        );
        return quoteAssetAmount;
    }

    // the direction is in quote asset
    function _updateReserve(
        Dir _dirOfQuote,
        Decimal.decimal memory _quoteAssetAmount,
        Decimal.decimal memory _baseAssetAmount,
        bool _canOverFluctuationLimit
    ) internal {
        // check if it's over fluctuationLimitRatio
        // this check should be before reserves being updated
        _checkIsOverBlockFluctuationLimit(
            _dirOfQuote,
            _quoteAssetAmount,
            _baseAssetAmount,
            _canOverFluctuationLimit
        );

        if (_dirOfQuote == Dir.ADD_TO_AMM) {
            quoteAssetReserve = quoteAssetReserve.addD(_quoteAssetAmount);
            baseAssetReserve = baseAssetReserve.subD(_baseAssetAmount);
            baseAssetDeltaThisFundingPeriod = baseAssetDeltaThisFundingPeriod
                .subD(_baseAssetAmount);
            totalPositionSize = totalPositionSize.addD(_baseAssetAmount);
            cumulativeNotional = cumulativeNotional.addD(_quoteAssetAmount);
        } else {
            quoteAssetReserve = quoteAssetReserve.subD(_quoteAssetAmount);
            baseAssetReserve = baseAssetReserve.addD(_baseAssetAmount);
            baseAssetDeltaThisFundingPeriod = baseAssetDeltaThisFundingPeriod
                .addD(_baseAssetAmount);
            totalPositionSize = totalPositionSize.subD(_baseAssetAmount);
            cumulativeNotional = cumulativeNotional.subD(_quoteAssetAmount);
        }

        // _addReserveSnapshot must be after checking price fluctuation
        _addReserveSnapshot();
    }

    function _implGetInputAssetTwapPrice(
        Dir _dirOfQuote,
        Decimal.decimal memory _assetAmount,
        QuoteAssetDir _inOut,
        uint256 _interval
    ) internal view returns (Decimal.decimal memory) {
        TwapPriceCalcParams memory params;
        params.opt = TwapCalcOption.INPUT_ASSET;
        params.snapshotIndex = reserveSnapshots.length - 1;
        params.asset.dir = _dirOfQuote;
        params.asset.assetAmount = _assetAmount;
        params.asset.inOrOut = _inOut;
        return _calcTwap(params, _interval);
    }

    function _implGetReserveTwapPrice(
        uint256 _interval
    ) internal view returns (Decimal.decimal memory) {
        TwapPriceCalcParams memory params;
        params.opt = TwapCalcOption.RESERVE_ASSET;
        params.snapshotIndex = reserveSnapshots.length - 1;
        return _calcTwap(params, _interval);
    }

    function _calcTwap(
        TwapPriceCalcParams memory _params,
        uint256 _interval
    ) internal view returns (Decimal.decimal memory) {
        Decimal.decimal memory currentPrice = _getPriceWithSpecificSnapshot(
            _params
        );
        if (_interval == 0) {
            return currentPrice;
        }

        uint256 baseTimestamp = block.timestamp - _interval;
        ReserveSnapshot memory currentSnapshot = reserveSnapshots[
            _params.snapshotIndex
        ];
        // return the latest snapshot price directly
        // if only one snapshot or the timestamp of latest snapshot is earlier than asking for
        if (
            reserveSnapshots.length == 1 ||
            currentSnapshot.timestamp <= baseTimestamp
        ) {
            return currentPrice;
        }

        uint256 previousTimestamp = currentSnapshot.timestamp;
        uint256 period = block.timestamp - previousTimestamp;
        Decimal.decimal memory weightedPrice = currentPrice.mulScalar(period);
        while (true) {
            // if snapshot history is too short
            if (_params.snapshotIndex == 0) {
                return weightedPrice.divScalar(period);
            }

            _params.snapshotIndex = _params.snapshotIndex - 1;
            currentSnapshot = reserveSnapshots[_params.snapshotIndex];
            currentPrice = _getPriceWithSpecificSnapshot(_params);

            // check if current round timestamp is earlier than target timestamp
            if (currentSnapshot.timestamp <= baseTimestamp) {
                // weighted time period will be (target timestamp - previous timestamp). For example,
                // now is 1000, _interval is 100, then target timestamp is 900. If timestamp of current round is 970,
                // and timestamp of NEXT round is 880, then the weighted time period will be (970 - 900) = 70,
                // instead of (970 - 880)
                weightedPrice = weightedPrice.addD(
                    currentPrice.mulScalar(previousTimestamp - baseTimestamp)
                );
                break;
            }

            uint256 timeFraction = previousTimestamp -
                currentSnapshot.timestamp;
            weightedPrice = weightedPrice.addD(
                currentPrice.mulScalar(timeFraction)
            );
            period = period + timeFraction;
            previousTimestamp = currentSnapshot.timestamp;
        }
        return weightedPrice.divScalar(_interval);
    }

    function _getPriceWithSpecificSnapshot(
        TwapPriceCalcParams memory params
    ) internal view virtual returns (Decimal.decimal memory) {
        ReserveSnapshot memory snapshot = reserveSnapshots[
            params.snapshotIndex
        ];

        // RESERVE_ASSET means price comes from quoteAssetReserve/baseAssetReserve
        // INPUT_ASSET means getInput/Output price with snapshot's reserve
        if (params.opt == TwapCalcOption.RESERVE_ASSET) {
            return snapshot.quoteAssetReserve.divD(snapshot.baseAssetReserve);
        } else if (params.opt == TwapCalcOption.INPUT_ASSET) {
            if (params.asset.assetAmount.toUint() == 0) {
                return Decimal.zero();
            }
            if (params.asset.inOrOut == QuoteAssetDir.QUOTE_IN) {
                return
                    getInputPriceWithReserves(
                        params.asset.dir,
                        params.asset.assetAmount,
                        snapshot.quoteAssetReserve,
                        snapshot.baseAssetReserve
                    );
            } else if (params.asset.inOrOut == QuoteAssetDir.QUOTE_OUT) {
                return
                    getOutputPriceWithReserves(
                        params.asset.dir,
                        params.asset.assetAmount,
                        snapshot.quoteAssetReserve,
                        snapshot.baseAssetReserve
                    );
            }
        }
        revert("not supported option");
    }

    function _getPriceBoundariesOfLastBlock()
        internal
        view
        returns (Decimal.decimal memory, Decimal.decimal memory)
    {
        uint256 len = reserveSnapshots.length;
        ReserveSnapshot memory latestSnapshot = reserveSnapshots[len - 1];
        // if the latest snapshot is the same as current block, get the previous one
        if (latestSnapshot.blockNumber == block.number && len > 1) {
            latestSnapshot = reserveSnapshots[len - 2];
        }

        Decimal.decimal memory lastPrice = latestSnapshot
            .quoteAssetReserve
            .divD(latestSnapshot.baseAssetReserve);
        Decimal.decimal memory upperLimit = lastPrice.mulD(
            Decimal.one().addD(fluctuationLimitRatio)
        );
        Decimal.decimal memory lowerLimit = lastPrice.mulD(
            Decimal.one().subD(fluctuationLimitRatio)
        );
        return (upperLimit, lowerLimit);
    }

    /**
     * @notice there can only be one tx in a block can skip the fluctuation check
     *         otherwise, some positions can never be closed or liquidated
     * @param _canOverFluctuationLimit if true, can skip fluctuation check for once; else, can never skip
     */
    function _checkIsOverBlockFluctuationLimit(
        Dir _dirOfQuote,
        Decimal.decimal memory _quoteAssetAmount,
        Decimal.decimal memory _baseAssetAmount,
        bool _canOverFluctuationLimit
    ) internal view {
        // Skip the check if the limit is 0
        if (fluctuationLimitRatio.toUint() == 0) {
            return;
        }

        //
        // assume the price of the last block is 10, fluctuation limit ratio is 5%, then
        //
        //          current price
        //  --+---------+-----------+---
        //   9.5        10         10.5
        // lower limit           upper limit
        //
        // when `openPosition`, the price can only be between 9.5 - 10.5
        // when `liquidate` and `closePosition`, the price can exceed the boundary once
        // (either lower than 9.5 or higher than 10.5)
        // once it exceeds the boundary, all the rest txs in this block fail
        //

        (
            Decimal.decimal memory upperLimit,
            Decimal.decimal memory lowerLimit
        ) = _getPriceBoundariesOfLastBlock();

        Decimal.decimal memory price = quoteAssetReserve.divD(baseAssetReserve);
        // solhint-disable-next-line reason-string
        require(
            price.cmp(upperLimit) <= 0 && price.cmp(lowerLimit) >= 0,
            "price is already over fluctuation limit"
        );

        if (!_canOverFluctuationLimit) {
            price = (_dirOfQuote == Dir.ADD_TO_AMM)
                ? quoteAssetReserve.addD(_quoteAssetAmount).divD(
                    baseAssetReserve.subD(_baseAssetAmount)
                )
                : quoteAssetReserve.subD(_quoteAssetAmount).divD(
                    baseAssetReserve.addD(_baseAssetAmount)
                );
            require(
                price.cmp(upperLimit) <= 0 && price.cmp(lowerLimit) >= 0,
                "price is over fluctuation limit"
            );
        }
    }

    function _requireValidRatio(Decimal.decimal memory _ratio) internal pure {
        require(_ratio.cmp(Decimal.one()) <= 0, "invalid ratio");
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.13;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Decimal} from "../utils/Decimal.sol";
import {SignedDecimal} from "../utils/SignedDecimal.sol";

interface IAmm {
    /**
     * @notice asset direction, used in getInputPrice, getOutputPrice, swapInput and swapOutput
     * @param ADD_TO_AMM add asset to Amm
     * @param REMOVE_FROM_AMM remove asset from Amm
     */
    enum Dir {
        ADD_TO_AMM,
        REMOVE_FROM_AMM
    }

    struct Ratios {
        Decimal.decimal feeRatio;
        Decimal.decimal initMarginRatio;
        Decimal.decimal maintenanceMarginRatio;
        Decimal.decimal partialLiquidationRatio;
        Decimal.decimal liquidationFeeRatio;
    }

    function swapInput(
        Dir _dirOfQuote,
        Decimal.decimal calldata _quoteAssetAmount,
        Decimal.decimal calldata _baseAssetAmountLimit,
        bool _canOverFluctuationLimit
    ) external returns (Decimal.decimal memory);

    function swapOutput(
        Dir _dirOfBase,
        Decimal.decimal calldata _baseAssetAmount,
        Decimal.decimal calldata _quoteAssetAmountLimit
    ) external returns (Decimal.decimal memory);

    function settleFunding()
        external
        returns (
            SignedDecimal.signedDecimal memory premiumFraction,
            Decimal.decimal memory markPrice,
            Decimal.decimal memory indexPrice
        );

    function repegPrice()
        external
        returns (
            Decimal.decimal memory,
            Decimal.decimal memory,
            Decimal.decimal memory,
            Decimal.decimal memory,
            SignedDecimal.signedDecimal memory
        );

    function repegK(
        Decimal.decimal memory _multiplier
    )
        external
        returns (
            Decimal.decimal memory,
            Decimal.decimal memory,
            Decimal.decimal memory,
            Decimal.decimal memory,
            SignedDecimal.signedDecimal memory
        );

    function updateFundingRate(
        SignedDecimal.signedDecimal memory,
        SignedDecimal.signedDecimal memory,
        Decimal.decimal memory
    ) external;

    //
    // VIEW
    //

    function calcFee(
        Dir _dirOfQuote,
        Decimal.decimal calldata _quoteAssetAmount,
        bool _isOpenPos
    ) external view returns (Decimal.decimal memory fees);

    function getMarkPrice() external view returns (Decimal.decimal memory);

    function getIndexPrice() external view returns (Decimal.decimal memory);

    function getReserves()
        external
        view
        returns (Decimal.decimal memory, Decimal.decimal memory);

    function getFeeRatio() external view returns (Decimal.decimal memory);

    function getInitMarginRatio()
        external
        view
        returns (Decimal.decimal memory);

    function getMaintenanceMarginRatio()
        external
        view
        returns (Decimal.decimal memory);

    function getPartialLiquidationRatio()
        external
        view
        returns (Decimal.decimal memory);

    function getLiquidationFeeRatio()
        external
        view
        returns (Decimal.decimal memory);

    function getMaxHoldingBaseAsset()
        external
        view
        returns (Decimal.decimal memory);

    function getOpenInterestNotionalCap()
        external
        view
        returns (Decimal.decimal memory);

    function getBaseAssetDelta()
        external
        view
        returns (SignedDecimal.signedDecimal memory);

    function getCumulativeNotional()
        external
        view
        returns (SignedDecimal.signedDecimal memory);

    function fundingPeriod() external view returns (uint256);

    function quoteAsset() external view returns (IERC20);

    function open() external view returns (bool);

    function getRatios() external view returns (Ratios memory);

    function calcPriceRepegPnl(
        Decimal.decimal memory _repegTo
    ) external view returns (SignedDecimal.signedDecimal memory repegPnl);

    function calcKRepegPnl(
        Decimal.decimal memory _k
    ) external view returns (SignedDecimal.signedDecimal memory repegPnl);

    function isOverFluctuationLimit(
        Dir _dirOfBase,
        Decimal.decimal memory _baseAssetAmount
    ) external view returns (bool);

    function isOverSpreadLimit() external view returns (bool);

    function getInputTwap(
        Dir _dir,
        Decimal.decimal calldata _quoteAssetAmount
    ) external view returns (Decimal.decimal memory);

    function getOutputTwap(
        Dir _dir,
        Decimal.decimal calldata _baseAssetAmount
    ) external view returns (Decimal.decimal memory);

    function getInputPrice(
        Dir _dir,
        Decimal.decimal calldata _quoteAssetAmount
    ) external view returns (Decimal.decimal memory);

    function getOutputPrice(
        Dir _dir,
        Decimal.decimal calldata _baseAssetAmount
    ) external view returns (Decimal.decimal memory);

    function getInputPriceWithReserves(
        Dir _dir,
        Decimal.decimal memory _quoteAssetAmount,
        Decimal.decimal memory _quoteAssetPoolAmount,
        Decimal.decimal memory _baseAssetPoolAmount
    ) external view returns (Decimal.decimal memory);

    function getOutputPriceWithReserves(
        Dir _dir,
        Decimal.decimal memory _baseAssetAmount,
        Decimal.decimal memory _quoteAssetPoolAmount,
        Decimal.decimal memory _baseAssetPoolAmount
    ) external view returns (Decimal.decimal memory);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.13;

interface IPriceFeed {
    // get latest price
    function getPrice(bytes32 _priceFeedKey) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.13;

import {DecimalMath} from "./DecimalMath.sol";

library Decimal {
    using DecimalMath for uint256;

    struct decimal {
        uint256 d;
    }

    function zero() internal pure returns (decimal memory) {
        return decimal(0);
    }

    function one() internal pure returns (decimal memory) {
        return decimal(DecimalMath.unit(18));
    }

    function toUint(decimal memory x) internal pure returns (uint256) {
        return x.d;
    }

    function modD(
        decimal memory x,
        decimal memory y
    ) internal pure returns (decimal memory) {
        return decimal((x.d * (DecimalMath.unit(18))) % y.d);
    }

    function cmp(
        decimal memory x,
        decimal memory y
    ) internal pure returns (int8) {
        if (x.d > y.d) {
            return 1;
        } else if (x.d < y.d) {
            return -1;
        }
        return 0;
    }

    /// @dev add two decimals
    function addD(
        decimal memory x,
        decimal memory y
    ) internal pure returns (decimal memory) {
        decimal memory t;
        t.d = x.d.addd(y.d);
        return t;
    }

    /// @dev subtract two decimals
    function subD(
        decimal memory x,
        decimal memory y
    ) internal pure returns (decimal memory) {
        decimal memory t;
        t.d = x.d.subd(y.d);
        return t;
    }

    /// @dev multiple two decimals
    function mulD(
        decimal memory x,
        decimal memory y
    ) internal pure returns (decimal memory) {
        decimal memory t;
        t.d = x.d.muld(y.d);
        return t;
    }

    /// @dev multiple a decimal by a uint256
    function mulScalar(
        decimal memory x,
        uint256 y
    ) internal pure returns (decimal memory) {
        decimal memory t;
        t.d = x.d * y;
        return t;
    }

    /// @dev divide two decimals
    function divD(
        decimal memory x,
        decimal memory y
    ) internal pure returns (decimal memory) {
        decimal memory t;
        t.d = x.d.divd(y.d);
        return t;
    }

    /// @dev divide a decimal by a uint256
    function divScalar(
        decimal memory x,
        uint256 y
    ) internal pure returns (decimal memory) {
        decimal memory t;
        t.d = x.d / y;
        return t;
    }

    /// @dev square root
    function sqrt(decimal memory _y) internal pure returns (decimal memory) {
        uint256 y = _y.d * 1e18;
        uint256 z;
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
        return decimal(z);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.13;

library DecimalMath {
    /// @dev Returns 1 in the fixed point representation, with `decimals` decimals.
    function unit(uint8 decimals) internal pure returns (uint256) {
        return 10 ** uint256(decimals);
    }

    /// @dev Adds x and y, assuming they are both fixed point with 18 decimals.
    function addd(uint256 x, uint256 y) internal pure returns (uint256) {
        return x + y;
    }

    /// @dev Subtracts y from x, assuming they are both fixed point with 18 decimals.
    function subd(uint256 x, uint256 y) internal pure returns (uint256) {
        return x - y;
    }

    /// @dev Multiplies x and y, assuming they are both fixed point with 18 digits.
    function muld(uint256 x, uint256 y) internal pure returns (uint256) {
        return muld(x, y, 18);
    }

    /// @dev Multiplies x and y, assuming they are both fixed point with `decimals` digits.
    function muld(
        uint256 x,
        uint256 y,
        uint8 decimals
    ) internal pure returns (uint256) {
        return (x * y) / (unit(decimals));
    }

    /// @dev Divides x between y, assuming they are both fixed point with 18 digits.
    function divd(uint256 x, uint256 y) internal pure returns (uint256) {
        return divd(x, y, 18);
    }

    /// @dev Divides x between y, assuming they are both fixed point with `decimals` digits.
    function divd(
        uint256 x,
        uint256 y,
        uint8 decimals
    ) internal pure returns (uint256) {
        return (x * unit(decimals)) / (y);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.13;

import {Decimal} from "./Decimal.sol";
import {SignedDecimal} from "./SignedDecimal.sol";

/// @dev To handle a signedDecimal add/sub/mul/div a decimal and provide convert decimal to signedDecimal helper
library MixedDecimal {
    using SignedDecimal for SignedDecimal.signedDecimal;

    uint256 private constant _INT256_MAX = 2 ** 255 - 1;
    string private constant ERROR_NON_CONVERTIBLE =
        "MixedDecimal: uint value is bigger than _INT256_MAX";

    modifier convertible(Decimal.decimal memory x) {
        require(_INT256_MAX >= x.d, ERROR_NON_CONVERTIBLE);
        _;
    }

    function fromDecimal(
        Decimal.decimal memory x
    )
        internal
        pure
        convertible(x)
        returns (SignedDecimal.signedDecimal memory)
    {
        return SignedDecimal.signedDecimal(int256(x.d));
    }

    function toUint(
        SignedDecimal.signedDecimal memory x
    ) internal pure returns (uint256) {
        return x.abs().d;
    }

    /// @dev add SignedDecimal.signedDecimal and Decimal.decimal, using SignedSafeMath directly
    function addD(
        SignedDecimal.signedDecimal memory x,
        Decimal.decimal memory y
    )
        internal
        pure
        convertible(y)
        returns (SignedDecimal.signedDecimal memory)
    {
        SignedDecimal.signedDecimal memory t;
        t.d = x.d + int256(y.d);
        return t;
    }

    /// @dev subtract SignedDecimal.signedDecimal by Decimal.decimal, using SignedSafeMath directly
    function subD(
        SignedDecimal.signedDecimal memory x,
        Decimal.decimal memory y
    )
        internal
        pure
        convertible(y)
        returns (SignedDecimal.signedDecimal memory)
    {
        SignedDecimal.signedDecimal memory t;
        t.d = x.d - int256(y.d);
        return t;
    }

    /// @dev multiple a SignedDecimal.signedDecimal by Decimal.decimal
    function mulD(
        SignedDecimal.signedDecimal memory x,
        Decimal.decimal memory y
    )
        internal
        pure
        convertible(y)
        returns (SignedDecimal.signedDecimal memory)
    {
        SignedDecimal.signedDecimal memory t;
        t = x.mulD(fromDecimal(y));
        return t;
    }

    /// @dev multiple a SignedDecimal.signedDecimal by a uint256
    function mulScalar(
        SignedDecimal.signedDecimal memory x,
        uint256 y
    ) internal pure returns (SignedDecimal.signedDecimal memory) {
        require(_INT256_MAX >= y, ERROR_NON_CONVERTIBLE);
        SignedDecimal.signedDecimal memory t;
        t = x.mulScalar(int256(y));
        return t;
    }

    /// @dev divide a SignedDecimal.signedDecimal by a Decimal.decimal
    function divD(
        SignedDecimal.signedDecimal memory x,
        Decimal.decimal memory y
    )
        internal
        pure
        convertible(y)
        returns (SignedDecimal.signedDecimal memory)
    {
        SignedDecimal.signedDecimal memory t;
        t = x.divD(fromDecimal(y));
        return t;
    }

    /// @dev divide a SignedDecimal.signedDecimal by a uint256
    function divScalar(
        SignedDecimal.signedDecimal memory x,
        uint256 y
    ) internal pure returns (SignedDecimal.signedDecimal memory) {
        require(_INT256_MAX >= y, ERROR_NON_CONVERTIBLE);
        SignedDecimal.signedDecimal memory t;
        t = x.divScalar(int256(y));
        return t;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.13;

import {SignedDecimalMath} from "./SignedDecimalMath.sol";
import {Decimal} from "./Decimal.sol";

library SignedDecimal {
    using SignedDecimalMath for int256;

    struct signedDecimal {
        int256 d;
    }

    function zero() internal pure returns (signedDecimal memory) {
        return signedDecimal(0);
    }

    function toInt(signedDecimal memory x) internal pure returns (int256) {
        return x.d;
    }

    function isNegative(signedDecimal memory x) internal pure returns (bool) {
        if (x.d < 0) {
            return true;
        }
        return false;
    }

    function abs(
        signedDecimal memory x
    ) internal pure returns (Decimal.decimal memory) {
        Decimal.decimal memory t;
        if (x.d < 0) {
            t.d = uint256(0 - x.d);
        } else {
            t.d = uint256(x.d);
        }
        return t;
    }

    /// @dev add two decimals
    function addD(
        signedDecimal memory x,
        signedDecimal memory y
    ) internal pure returns (signedDecimal memory) {
        signedDecimal memory t;
        t.d = x.d.addd(y.d);
        return t;
    }

    /// @dev subtract two decimals
    function subD(
        signedDecimal memory x,
        signedDecimal memory y
    ) internal pure returns (signedDecimal memory) {
        signedDecimal memory t;
        t.d = x.d.subd(y.d);
        return t;
    }

    /// @dev multiple two decimals
    function mulD(
        signedDecimal memory x,
        signedDecimal memory y
    ) internal pure returns (signedDecimal memory) {
        signedDecimal memory t;
        t.d = x.d.muld(y.d);
        return t;
    }

    /// @dev multiple a signedDecimal by a int256
    function mulScalar(
        signedDecimal memory x,
        int256 y
    ) internal pure returns (signedDecimal memory) {
        signedDecimal memory t;
        t.d = x.d * y;
        return t;
    }

    /// @dev divide two decimals
    function divD(
        signedDecimal memory x,
        signedDecimal memory y
    ) internal pure returns (signedDecimal memory) {
        signedDecimal memory t;
        t.d = x.d.divd(y.d);
        return t;
    }

    /// @dev divide a signedDecimal by a int256
    function divScalar(
        signedDecimal memory x,
        int256 y
    ) internal pure returns (signedDecimal memory) {
        signedDecimal memory t;
        t.d = x.d / y;
        return t;
    }

    /// @dev square root
    function sqrt(
        signedDecimal memory _y
    ) internal pure returns (signedDecimal memory) {
        int256 y = _y.d * 1e18;
        int256 z;
        if (y > 3) {
            z = y;
            int256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
        return signedDecimal(z);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.13;

/// @dev Implements simple signed fixed point math add, sub, mul and div operations.
library SignedDecimalMath {
    /// @dev Returns 1 in the fixed point representation, with `decimals` decimals.
    function unit(uint8 decimals) internal pure returns (int256) {
        return int256(10 ** uint256(decimals));
    }

    /// @dev Adds x and y, assuming they are both fixed point with 18 decimals.
    function addd(int256 x, int256 y) internal pure returns (int256) {
        return x + y;
    }

    /// @dev Subtracts y from x, assuming they are both fixed point with 18 decimals.
    function subd(int256 x, int256 y) internal pure returns (int256) {
        return x - y;
    }

    /// @dev Multiplies x and y, assuming they are both fixed point with 18 digits.
    function muld(int256 x, int256 y) internal pure returns (int256) {
        return muld(x, y, 18);
    }

    /// @dev Multiplies x and y, assuming they are both fixed point with `decimals` digits.
    function muld(
        int256 x,
        int256 y,
        uint8 decimals
    ) internal pure returns (int256) {
        return (x * y) / unit(decimals);
    }

    /// @dev Divides x between y, assuming they are both fixed point with 18 digits.
    function divd(int256 x, int256 y) internal pure returns (int256) {
        return divd(x, y, 18);
    }

    /// @dev Divides x between y, assuming they are both fixed point with `decimals` digits.
    function divd(
        int256 x,
        int256 y,
        uint8 decimals
    ) internal pure returns (int256) {
        return (x * unit(decimals)) / (y);
    }
}