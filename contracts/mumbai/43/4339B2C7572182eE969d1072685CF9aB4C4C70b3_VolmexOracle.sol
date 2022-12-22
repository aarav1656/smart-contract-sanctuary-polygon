// SPDX-License-Identifier: BUSL-1.1

pragma solidity =0.8.11;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165StorageUpgradeable.sol";

import "../interfaces/IVolmexProtocol.sol";
import "../interfaces/IVolmexOracle.sol";
import "./VolmexTWAP.sol";

/**
 * @title Volmex Oracle contract
 * @author volmex.finance [[email protected]]
 */
contract VolmexOracle is OwnableUpgradeable, ERC165StorageUpgradeable, VolmexTWAP, IVolmexOracle {
    // price precision constant upto 6 decimal places
    uint256 private constant _VOLATILITY_PRICE_PRECISION = 1000000;
    // maximum allowed number of index volatility datapoints for calculating twap
    uint256 private constant _MAX_ALLOWED_TWAP_DATAPOINTS = 6;
    // Interface ID of VolmexOracle contract, hashId = 0xf9fffc9f
    bytes4 private constant _IVOLMEX_ORACLE_ID = type(IVolmexOracle).interfaceId;

    // Store the price of volatility by indexes { 0 - ETHV, 1 = BTCV }
    mapping(uint256 => uint256) private _volatilityTokenPriceByIndex;

    // Store the volatilitycapratio by index
    mapping(uint256 => uint256) public volatilityCapRatioByIndex;
    // Store the proof of hash of the current volatility token price
    mapping(uint256 => bytes32) public volatilityTokenPriceProofHash;
    // Store the index of volatility by symbol
    mapping(string => uint256) public volatilityIndexBySymbol;
    // Store the leverage on volatility by index
    mapping(uint256 => uint256) public volatilityLeverageByIndex;
    // Store the base volatility index by leverage volatility index
    mapping(uint256 => uint256) public baseVolatilityIndex;
    // Store the number of indexes
    uint256 public indexCount;
    // Store the timestamp of volatility price update by index
    mapping(uint256 => uint256) public volatilityLastUpdateTimestamp;

    /**
     * @notice Initializes the contract setting the deployer as the initial owner.
     */
    function initialize(address _owner) external initializer {
        _updateTwapMaxDatapoints(_MAX_ALLOWED_TWAP_DATAPOINTS);

        _updateVolatilityMeta(indexCount, 200000000, "");
        volatilityIndexBySymbol["EVIV"] = indexCount;
        volatilityCapRatioByIndex[indexCount] = 400000000;

        indexCount++;

        _updateVolatilityMeta(indexCount, 200000000, "");
        volatilityIndexBySymbol["BVIV"] = indexCount;
        volatilityCapRatioByIndex[indexCount] = 400000000;

        __Ownable_init();
        __ERC165Storage_init();
        _registerInterface(_IVOLMEX_ORACLE_ID);
        _transferOwnership(_owner);
    }

    /**
     * @notice Update the volatility token index by symbol
     * @param _index Number value of the index. { eg. 0 }
     * @param _tokenSymbol Symbol of the adding volatility token
     */
    function updateIndexBySymbol(string calldata _tokenSymbol, uint256 _index) external onlyOwner {
        volatilityIndexBySymbol[_tokenSymbol] = _index;

        emit SymbolIndexUpdated(_index);
    }

    /**
     * @notice Update the baseVolatilityIndex of leverage token
     * @param _leverageVolatilityIndex Index of the leverage volatility token
     * @param _newBaseVolatilityIndex Index of the base volatility token
     */
    function updateBaseVolatilityIndex(
        uint256 _leverageVolatilityIndex,
        uint256 _newBaseVolatilityIndex
    ) external onlyOwner {
        baseVolatilityIndex[_leverageVolatilityIndex] = _newBaseVolatilityIndex;

        emit BaseVolatilityIndexUpdated(_newBaseVolatilityIndex);
    }

    /**
     * @notice Add volatility token price by index
     * @param _volatilityTokenPrice Price of the adding volatility token
     * @param _protocol Address of the VolmexProtocol of which the price is added
     * @param _volatilityTokenSymbol Symbol of the adding volatility token
     * @param _leverage Value of leverage on token {2X: 2, 5X: 5}
     * @param _baseVolatilityIndex Index of the base volatility {0: ETHV, 1: BTCV}
     * @param _proofHash Bytes32 value of token price proof of hash
     */
    function addVolatilityIndex(
        uint256 _volatilityTokenPrice,
        IVolmexProtocol _protocol,
        string calldata _volatilityTokenSymbol,
        uint256 _leverage,
        uint256 _baseVolatilityIndex,
        bytes32 _proofHash
    ) external onlyOwner {
        require(address(_protocol) != address(0), "VolmexOracle: protocol address can't be zero");
        uint256 _volatilityCapRatio = _protocol.volatilityCapRatio() * _VOLATILITY_PRICE_PRECISION;
        require(
            _volatilityCapRatio >= 1000000,
            "VolmexOracle: volatility cap ratio should be greater than 1000000"
        );
        uint256 _index = ++indexCount;
        volatilityCapRatioByIndex[_index] = _volatilityCapRatio;
        volatilityIndexBySymbol[_volatilityTokenSymbol] = _index;

        if (_leverage != 0) {
            // This will also check the base volatilities are present
            if (_leverage > 1) {
                require(
                    volatilityCapRatioByIndex[_baseVolatilityIndex] / _leverage == _volatilityCapRatio,
                    "VolmexOracle: Invalid _baseVolatilityIndex provided"
                );
            }
            volatilityLeverageByIndex[_index] = _leverage;
            baseVolatilityIndex[_index] = _baseVolatilityIndex;
            _addIndexDataPoint(
                _index,
                _volatilityTokenPriceByIndex[_baseVolatilityIndex] / _leverage
            );
            // TODO: Add if condition inside here for _baseVolatilityIndex, to store volatility cap ratio for 
            // derived pools of 100 or 150 capped collateral
            // 
            // keep logic non-redundant

            emit LeveragedVolatilityIndexAdded(
                _index,
                _volatilityCapRatio,
                _volatilityTokenSymbol,
                _leverage,
                _baseVolatilityIndex
            );
        } else {
            require(
                _volatilityTokenPrice <= _volatilityCapRatio,
                "VolmexOracle: _volatilityTokenPrice should be smaller than VolatilityCapRatio"
            );
            _updateVolatilityMeta(_index, _volatilityTokenPrice, _proofHash);

            emit VolatilityIndexAdded(
                _index,
                _volatilityCapRatio,
                _volatilityTokenSymbol,
                _volatilityTokenPrice
            );
        }
    }

    /**
     * @notice Updates the volatility token price by index
     *
     * @dev Check if volatility token price is greater than zero (0)
     * @dev Update the volatility token price corresponding to the volatility token symbol
     * @dev Store the volatility token price corresponding to the block number
     * @dev Update the proof of hash for the volatility token price
     *
     * @param _volatilityIndexes Number array of values of the volatility index. { eg. 0 }
     * @param _volatilityTokenPrices array of prices of volatility token, between {0, 250000000}
     * @param _proofHashes arrau of Bytes32 values of token prices proof of hash
     *
     * NOTE: Make sure the volatility token price are with 6 decimals, eg. 125000000
     */
    function updateBatchVolatilityTokenPrice(
        uint256[] memory _volatilityIndexes,
        uint256[] memory _volatilityTokenPrices,
        bytes32[] memory _proofHashes
    ) external onlyOwner {
        require(
            _volatilityIndexes.length == _volatilityTokenPrices.length &&
                _volatilityIndexes.length == _proofHashes.length,
            "VolmexOracle: length of input arrays are not equal"
        );
        for (uint256 i = 0; i < _volatilityIndexes.length; i++) {
            require(
                _volatilityTokenPrices[i] <= volatilityCapRatioByIndex[_volatilityIndexes[i]],
                "VolmexOracle: _volatilityTokenPrice should be smaller than VolatilityCapRatio"
            );

            _updateVolatilityMeta(
                _volatilityIndexes[i],
                _volatilityTokenPrices[i],
                _proofHashes[i]
            );
        }

        emit BatchVolatilityTokenPriceUpdated(
            _volatilityIndexes,
            _volatilityTokenPrices,
            _proofHashes
        );
    }

    /**
     * @notice Adds a new datapoint to the datapoints storage array
     *
     * @param _index Datapoints volatility index id {0}
     * @param _value Datapoint value to add {250000000}
     */
    function addIndexDataPoint(uint256 _index, uint256 _value) external onlyOwner {
        _addIndexDataPoint(_index, _value);
    }

    /**
     * @notice Get the volatility token price by symbol
     * @param _volatilityTokenSymbol Symbol of the volatility token
     */
    function getVolatilityPriceBySymbol(string calldata _volatilityTokenSymbol)
        external
        view
        returns (
            uint256 volatilityTokenPrice,
            uint256 iVolatilityTokenPrice,
            uint256 lastUpdateTimestamp
        )
    {
        uint256 volatilityIndex = volatilityIndexBySymbol[_volatilityTokenSymbol];
        (
            volatilityTokenPrice,
            iVolatilityTokenPrice,
            lastUpdateTimestamp
        ) = _getVolatilityTokenPrice(volatilityIndex);
    }

    /**
     * @notice Get the volatility token price by index
     * @param _index index of the volatility token
     */
    function getVolatilityTokenPriceByIndex(uint256 _index)
        external
        view
        returns (
            uint256 volatilityTokenPrice,
            uint256 iVolatilityTokenPrice,
            uint256 lastUpdateTimestamp
        )
    {
        (
            volatilityTokenPrice,
            iVolatilityTokenPrice,
            lastUpdateTimestamp
        ) = _getVolatilityTokenPrice(_index);
    }

    /**
     * @notice Get the TWAP value from current available datapoints
     * @param _index Datapoints volatility index id {0}
     *
     * @dev This method is a replica of `getVolatilityTokenPriceByIndex(_index)`
     */
    function getIndexTwap(uint256 _index)
        external
        view
        returns (
            uint256 volatilityTokenTwap,
            uint256 iVolatilityTokenTwap,
            uint256 lastUpdateTimestamp
        )
    {
        (
            volatilityTokenTwap,
            iVolatilityTokenTwap,
            lastUpdateTimestamp
        ) = _getVolatilityTokenPrice(_index);
    }

    /**
     * @notice Get all datapoints available for a specific volatility index
     * @param _index Datapoints volatility index id {0}
     */
    function getIndexDataPoints(uint256 _index) external view returns (uint256[] memory dp) {
        dp = _getIndexDataPoints(_index);
    }

    /**
     * @notice Update maximum amount of volatility index datapoints for calculating the TWAP
     *
     * @param _value Max datapoints value {180}
     */
    function updateTwapMaxDatapoints(uint256 _value) external onlyOwner {
        _updateTwapMaxDatapoints(_value);
    }

    /**
     * @notice Emulate the Chainlink Oracle interface for retrieving Volmex TWAP volatility index
     * @param _index Datapoints volatility index id {0}
     * @return answer is the answer for the given round
     */
    function latestRoundData(uint256 _index)
        external
        view
        virtual
        override
        returns (uint256 answer, uint256 lastUpdateTimestamp)
    {
        answer = _getIndexTwap(_index) * 100;
        lastUpdateTimestamp = volatilityLeverageByIndex[_index] > 0
            ? volatilityLastUpdateTimestamp[baseVolatilityIndex[_index]]
            : volatilityLastUpdateTimestamp[_index];
    }

    function _updateVolatilityMeta(
        uint256 _index,
        uint256 _volatilityTokenPrice,
        bytes32 _proofHash
    ) private {
        _addIndexDataPoint(_index, _volatilityTokenPrice);
        _volatilityTokenPriceByIndex[_index] = _getIndexTwap(_index);
        volatilityLastUpdateTimestamp[_index] = block.timestamp;
        volatilityTokenPriceProofHash[_index] = _proofHash;
    }

    function _getVolatilityTokenPrice(uint256 _index)
        private
        view
        returns (
            uint256 volatilityTokenTwap,
            uint256 iVolatilityTokenTwap,
            uint256 lastUpdateTimestamp
        )
    {
        // add check for _baseVolatilityIndex for fetching the price of both side of tokens
        // with subtraction of correct cap ratio
        // move the current else part out of if-else condition with efficiency
        if (volatilityLeverageByIndex[_index] != 0) {
            uint256 baseIndex = baseVolatilityIndex[_index];
            volatilityTokenTwap = (_getIndexTwap(baseIndex)) / volatilityLeverageByIndex[_index];
            lastUpdateTimestamp = volatilityLastUpdateTimestamp[baseIndex];
        } else {
            volatilityTokenTwap = _getIndexTwap(_index);
            lastUpdateTimestamp = volatilityLastUpdateTimestamp[_index];
        }
        iVolatilityTokenTwap = volatilityCapRatioByIndex[_index] - volatilityTokenTwap;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

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
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/introspection/ERC165Storage.sol)

pragma solidity ^0.8.0;

import "./ERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Storage based implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
abstract contract ERC165StorageUpgradeable is Initializable, ERC165Upgradeable {
    function __ERC165Storage_init() internal initializer {
        __ERC165_init_unchained();
        __ERC165Storage_init_unchained();
    }

    function __ERC165Storage_init_unchained() internal initializer {
    }
    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return super.supportsInterface(interfaceId) || _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See {IERC165-supportsInterface}.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity =0.8.11;

import "./IERC20Modified.sol";

interface IVolmexProtocol {
    //getter methods
    function minimumCollateralQty() external view returns (uint256);
    function active() external view returns (bool);
    function isSettled() external view returns (bool);
    function volatilityToken() external view returns (IERC20Modified);
    function inverseVolatilityToken() external view returns (IERC20Modified);
    function collateral() external view returns (IERC20Modified);
    function issuanceFees() external view returns (uint256);
    function redeemFees() external view returns (uint256);
    function accumulatedFees() external view returns (uint256);
    function volatilityCapRatio() external view returns (uint256);
    function settlementPrice() external view returns (uint256);
    function precisionRatio() external view returns (uint256);

    //setter methods
    function toggleActive() external;
    function updateMinimumCollQty(uint256 _newMinimumCollQty) external;
    function updatePositionToken(address _positionToken, bool _isVolatilityIndex) external;
    function collateralize(uint256 _collateralQty) external returns (uint256, uint256);
    function redeem(uint256 _positionTokenQty) external returns (uint256, uint256);
    function redeemSettled(
        uint256 _volatilityIndexTokenQty,
        uint256 _inverseVolatilityIndexTokenQty
    ) external returns (uint256, uint256);
    function settle(uint256 _settlementPrice) external;
    function recoverTokens(
        address _token,
        address _toWhom,
        uint256 _howMuch
    ) external;
    function updateFees(uint256 _issuanceFees, uint256 _redeemFees) external;
    function claimAccumulatedFees() external;
    function togglePause(bool _isPause) external;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity =0.8.11;

import "./IVolmexProtocol.sol";

interface IVolmexOracle {
    event SymbolIndexUpdated(uint256 indexed _index);
    event BaseVolatilityIndexUpdated(uint256 indexed baseVolatilityIndex);
    event BatchVolatilityTokenPriceUpdated(
        uint256[] _volatilityIndexes,
        uint256[] _volatilityTokenPrices,
        bytes32[] _proofHashes
    );
    event VolatilityIndexAdded(
        uint256 indexed volatilityTokenIndex,
        uint256 volatilityCapRatio,
        string volatilityTokenSymbol,
        uint256 volatilityTokenPrice
    );
    event LeveragedVolatilityIndexAdded(
        uint256 indexed volatilityTokenIndex,
        uint256 volatilityCapRatio,
        string volatilityTokenSymbol,
        uint256 leverage,
        uint256 baseVolatilityIndex
    );

    // Getter  methods
    function volatilityCapRatioByIndex(uint256 _index) external view returns (uint256);
    function volatilityTokenPriceProofHash(uint256 _index) external view returns (bytes32);
    function volatilityIndexBySymbol(string calldata _tokenSymbol) external view returns (uint256);
    function volatilityLastUpdateTimestamp(uint256 _index) external view returns (uint256);
    function volatilityLeverageByIndex(uint256 _index) external view returns (uint256);
    function baseVolatilityIndex(uint256 _index) external view returns (uint256);
    function indexCount() external view returns (uint256);
    function latestRoundData(uint256 _index)
        external
        view
        returns (uint256 answer, uint256 lastUpdateTimestamp);
    function getIndexTwap(uint256 _index)
        external
        view
        returns (
            uint256 volatilityTokenTwap,
            uint256 iVolatilityTokenTwap,
            uint256 lastUpdateTimestamp
        );
    function getVolatilityTokenPriceByIndex(uint256 _index)
        external
        view
        returns (
            uint256 volatilityTokenPrice,
            uint256 iVolatilityTokenPrice,
            uint256 lastUpdateTimestamp
        );
    function getVolatilityPriceBySymbol(string calldata _volatilityTokenSymbol)
        external
        view
        returns (
            uint256 volatilityTokenPrice,
            uint256 iVolatilityTokenPrice,
            uint256 lastUpdateTimestamp
        );

    // Setter methods
    function updateIndexBySymbol(string calldata _tokenSymbol, uint256 _index) external;
    function updateBaseVolatilityIndex(
        uint256 _leverageVolatilityIndex,
        uint256 _newBaseVolatilityIndex
    ) external;
    function updateBatchVolatilityTokenPrice(
        uint256[] memory _volatilityIndexes,
        uint256[] memory _volatilityTokenPrices,
        bytes32[] memory _proofHashes
    ) external;
    function addVolatilityIndex(
        uint256 _volatilityTokenPrice,
        IVolmexProtocol _protocol,
        string calldata _volatilityTokenSymbol,
        uint256 _leverage,
        uint256 _baseVolatilityIndex,
        bytes32 _proofHash
    ) external;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity =0.8.11;

/**
 * @title Volmex Oracle TWAP library
 * @author volmex.finance [[email protected]]
 */
contract VolmexTWAP {
    // Max datapoints allowed to store in
    uint256 private _MAX_DATAPOINTS;

    // Emit new event when new datapoint is added
    event IndexDataPointAdded(uint256 indexed_index, uint256 _value);

    // Emit an event when max allowed twap datapoints value it's updated
    event MaxTwapDatapointsUpdated(uint256 _value);

    // Store index datapoints into multidimensional arrays
    mapping(uint256 => uint256[]) private _datapoints;

    // In order to maintain low gas fees and storage efficiency we use cursors to store datapoints
    mapping(uint256 => uint256) private _datapointsCursor;

    /**
     * @notice Adds a new datapoint to the datapoints storage array
     *
     * @param _index Datapoints volatility index id {0}
     * @param _value Datapoint value to add {250000000}
     */
    function _addIndexDataPoint(uint256 _index, uint256 _value) internal {
        if (_datapoints[_index].length < _MAX_DATAPOINTS) {
            // initially populate available datapoint storage slots with index data
            _datapoints[_index].push(_value);
        } else {
            if (
                // reset the cursor has reached the maximum allowed storage datapoints 
                // or max allowed datapoints values changed by the owner it's lower than current cursor
                _datapointsCursor[_index] >= _MAX_DATAPOINTS
            ) {
                // reset cursor
                _datapointsCursor[_index] = 0;
            }

            _datapoints[_index][_datapointsCursor[_index]] = _value;
            _datapointsCursor[_index]++;
        }

        emit IndexDataPointAdded(_index, _value);
    }

    /**
     * @notice Get the TWAP value from current available datapoints
     * @param _index Datapoints volatility index id {0}
     */
    function _getIndexTwap(uint256 _index) internal view returns (uint256 twap) {
        uint256 _datapointsSum;

        uint256 _datapointsLen = _datapoints[_index].length;

        for (uint256 i = 0; i < _datapointsLen; i++) {
            _datapointsSum += _datapoints[_index][i];
        }

        twap = _datapointsSum / _datapointsLen;
    }

    /**
     * @notice Get all datapoints available for a specific volatility index
     * @param _index Datapoints volatility index id {0}
     */
    function _getIndexDataPoints(uint256 _index)
        internal
        view
        returns (uint256[] memory datapoints)
    {
        datapoints = _datapoints[_index];
    }

    /**
     * @notice Update maximum amount of volatility index datapoints for calculating the TWAP
     *
     * @param _value Max datapoints value {180}
     */
    function _updateTwapMaxDatapoints(uint256 _value) internal {
        require(_value > 0, "Minimum amount of index datapoints needs to be greater than zero");

        _MAX_DATAPOINTS = _value;

        emit MaxTwapDatapointsUpdated(_value);
    }

    uint256[10] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
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
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal initializer {
        __ERC165_init_unchained();
    }

    function __ERC165_init_unchained() internal initializer {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/introspection/IERC165.sol)

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
interface IERC165Upgradeable {
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

// SPDX-License-Identifier: BUSL-1.1

pragma solidity =0.8.11;

interface IERC20Modified {
    // IERC20 Methods
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    // Custom Methods
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function decimals() external view returns (uint8);
    function mint(address _toWhom, uint256 amount) external;
    function burn(address _whose, uint256 amount) external;
    function grantRole(bytes32 role, address account) external;
    function renounceRole(bytes32 role, address account) external;
    function pause() external;
    function unpause() external;
}