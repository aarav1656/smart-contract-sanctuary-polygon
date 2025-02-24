// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";
import {DLFactoryPair} from "./DLFactoryPair.sol";
import {IDLPair} from "../../interfaces/IDLPair.sol";

/// @title Discretized Liquidity Factory
/// @author Bentoswap
/// @notice Contract used to deploy and register new DLPairs, and modify pair/protocol settings.
contract DLFactory is DLFactoryPair {

    /// @notice Constructor
    /// @param _feeRecipient The address of the fee recipient
    /// @param _flashLoanFee The value of the fee for flash loan
    constructor(address _feeRecipient, uint256 _flashLoanFee) DLFactoryPair(_feeRecipient, _flashLoanFee) { }

    // <<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>>
    //      -'~'-.,__,.-'~'-.,__,.- PAIRS -.,__,.-'~'-.,__,.-'~'-
    // <<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>>

    function createDLPair(
        IERC20 _tokenX,
        IERC20 _tokenY,
        uint24 _activeId,
        uint16 _binStep
    ) external override returns (IDLPair _DLPair) {
        return _createDLPair(_tokenX, _tokenY, _activeId, _binStep);
    }

    function setFeesParametersOnPair(
        IERC20 _tokenX,
        IERC20 _tokenY,
        FactoryFeeParams calldata _feeParams
    ) external override onlyOwner {
        _setFeesParametersOnPair(_tokenX, _tokenY, _feeParams);
    }

    function setDLPairIgnored(
        IERC20 _tokenX,
        IERC20 _tokenY,
        uint256 _binStep,
        bool _ignored
    ) external override onlyOwner {
        _setDLPairIgnored(_tokenX, _tokenY, _binStep, _ignored);
    }

    function getDLPairInformation(
        IERC20 _tokenA,
        IERC20 _tokenB,
        uint256 _binStep
    ) external view override returns (DLPairInformation memory) {
        return _getDLPairInformation(_tokenA, _tokenB, _binStep);
    }

    function getAllDLPairs(IERC20 _tokenX, IERC20 _tokenY)
        external
        view
        override
        returns (DLPairInformation[] memory DLPairsAvailable)
    {
        return _getAllDLPairs(_tokenX, _tokenY);
    }

    // <<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>>
    //     -'~'-.,__,.-'~'-.,__,.- PRESETS -.,__,.-'~'-.,__,.-'~'-
    // <<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>>

    function setPreset(
        FactoryFeeParamsPreset calldata _preset
    ) external override onlyOwner {
        _setPreset(_preset);
    }

    function removePreset(uint16 _binStep) external override onlyOwner {
        _removePreset(_binStep);
    }

    function getPreset(uint16 _binStep)
        external
        view
        override
        returns (FactoryFeeParamsPreset memory preset_)
    {
        preset_ = _getPreset(_binStep);
    }

    function getAllBinStepsFromPresets() external view override returns (uint256[] memory presetsBinStep) {
        return _getAllBinStepsFromPresets();
    }

    // <<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>>
    //     -'~'-.,__,.-'~'-.,__,.- FACTORY -.,__,.-'~'-.,__,.-'~'-
    // <<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>>

    function setFeeRecipient(address _feeRecipient) external override onlyOwner {
        _setFeeRecipient(_feeRecipient);
    }

    function setFactoryLockedState(bool _locked) external override onlyOwner {
        _setFactoryLockedState(_locked);
    }

    function setFactoryQuoteAssetRestrictedState(bool _restricted) external override onlyOwner {
        _setFactoryQuoteAssetRestrictedState(_restricted);
    }

    function setFlashLoanFee(uint256 _flashLoanFee) external override onlyOwner {
        _setFlashLoanFee(_flashLoanFee);
    }

    function setDLPairImplementation(address _dlPairImplementation) external override onlyOwner {
        _setDLPairImplementation(_dlPairImplementation);
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

pragma solidity 0.8.17;

import {Clones} from "openzeppelin/proxy/Clones.sol";
import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";
import {EnumerableSet} from "openzeppelin/utils/structs/EnumerableSet.sol";

import {
    DLFactory__AddressZero,
    DLFactory__BinStepHasNoPreset,
    DLFactory__DLPairAlreadyExists,
    DLFactory__DLPairIgnoredIsAlreadyInTheSameState,
    DLFactory__DLPairNotCreated,
    DLFactory__FunctionIsLockedForUsers,
    DLFactory__IdenticalAddresses,
    DLFactory__ImplementationNotSet,
    DLFactory__QuoteAssetNotWhitelisted
} from "../../DLErrors.sol";
import {BinHelper} from "../../libraries/BinHelper.sol";
import {Decoder} from "../../libraries/Decoder.sol";
import {SafeCast} from "../../libraries/SafeCast.sol";
import {DLFactoryQuoteAssets} from "./DLFactoryQuoteAssets.sol";
import {IDLPair} from "../../interfaces/IDLPair.sol";

/// @title Discretized Liquidity Factory DLPair Handling
/// @author Bentoswap
/// @notice Contract used to manage DLPairs.
abstract contract DLFactoryPair is DLFactoryQuoteAssets {
    using SafeCast for uint256;
    using Decoder for bytes32;
    using EnumerableSet for EnumerableSet.AddressSet;

    constructor(address _feeRecipient, uint256 _flashLoanFee) DLFactoryQuoteAssets(_feeRecipient, _flashLoanFee) { }

    // <<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>>
    //     -'~'-.,__,.-'~'-.,__,.- EXTERNAL -.,__,.-'~'-.,__,.-'~'-
    // <<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>>

    /// @notice View function to return the number of DLPairs created
    /// @return The number of DLPair
    function getNumberOfDLPairs() external view override returns (uint256) {
        return allDLPairs.length;
    }

    function forceDecayOnPair(IDLPair _DLPair) external override onlyOwner {
        _DLPair.forceDecay();
    }

    // <<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>>
    //     -'~'-.,__,.-'~'-.,__,.- INTERNAL -.,__,.-'~'-.,__,.-'~'-
    // <<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>>

    /// @notice Create a liquidity bin DLPair for _tokenX and _tokenY
    /// @param _tokenX The address of the first token
    /// @param _tokenY The address of the second token
    /// @param _activeId The active id of the pair
    /// @param _binStep The bin step in basis point, used to calculate log(1 + binStep)
    /// @return _DLPair The address of the newly created DLPair
    function _createDLPair(
        IERC20 _tokenX,
        IERC20 _tokenY,
        uint24 _activeId,
        uint16 _binStep
    ) internal returns (IDLPair _DLPair) {
        address _owner = owner();
        if (isCreationLocked && msg.sender != _owner) revert DLFactory__FunctionIsLockedForUsers(msg.sender);

        address _DLPairImplementation = dlPairImplementation;

        if (_DLPairImplementation == address(0)) revert DLFactory__ImplementationNotSet();

        if (isQuoteAssetRestricted && !_allowedQuoteAssets.contains(address(_tokenY))) revert DLFactory__QuoteAssetNotWhitelisted(_tokenY);

        if (_tokenX == _tokenY) revert DLFactory__IdenticalAddresses(_tokenX);

        // safety check, making sure that the price can be calculated
        BinHelper.getPriceFromId(_activeId, _binStep);

        // We sort token for storage efficiency, only one input needs to be stored because they are sorted
        (IERC20 _tokenA, IERC20 _tokenB) = _sortTokens(_tokenX, _tokenY);
        // single check is sufficient
        if (address(_tokenA) == address(0)) revert DLFactory__AddressZero();
        if (address(_dlPairsInfo[_tokenA][_tokenB][_binStep].dlPair) != address(0))
            revert DLFactory__DLPairAlreadyExists(_tokenX, _tokenY, _binStep);

        bytes32 _preset = _presets[_binStep];
        if (_preset == bytes32(0)) revert DLFactory__BinStepHasNoPreset(_binStep);

        uint256 _sampleLifetime = _preset.decode(type(uint16).max, 240);
        // We remove the bits that are not part of the feeParameters
        _preset &= bytes32(uint256(type(uint144).max));

        bytes32 _salt = keccak256(abi.encode(_tokenA, _tokenB, _binStep));
        _DLPair = IDLPair(Clones.cloneDeterministic(_DLPairImplementation, _salt));

        _DLPair.initialize(_tokenX, _tokenY, _activeId, uint16(_sampleLifetime), _preset);

        _dlPairsInfo[_tokenA][_tokenB][_binStep] = DLPairInformation({
            binStep: _binStep,
            dlPair: _DLPair,
            createdByOwner: msg.sender == _owner,
            ignoredForRouting: false
        });

        allDLPairs.push(_DLPair);

        {
            bytes32 _avDLPairBinSteps = _availableDLPairBinSteps[_tokenA][_tokenB];
            // We add a 1 at bit `_binStep` as this binStep is now set
            _avDLPairBinSteps = bytes32(uint256(_avDLPairBinSteps) | (1 << _binStep));

            // Increase the number of lb pairs by 1
            _avDLPairBinSteps = bytes32(uint256(_avDLPairBinSteps) + (1 << 248));

            // Save the changes
            _availableDLPairBinSteps[_tokenA][_tokenB] = _avDLPairBinSteps;
        }

        emit DLPairCreated(_tokenX, _tokenY, _binStep, _DLPair, allDLPairs.length - 1);

        emit FeeParametersSet(
            msg.sender,
            _DLPair,
            FactoryFeeParams(
                _binStep,
                uint16(_preset.decode(type(uint16).max, 16)),
                uint16(_preset.decode(type(uint16).max, 32)),
                uint16(_preset.decode(type(uint16).max, 48)),
                uint16(_preset.decode(type(uint16).max, 64)),
                uint24(_preset.decode(type(uint24).max, 80)),
                uint16(_preset.decode(type(uint16).max, 104)),
                uint24(_preset.decode(type(uint24).max, 120))
            )
        );
    }

    /// @notice Function to set the fee parameter of a DLPair
    /// @param _tokenX The address of the first token
    /// @param _tokenY The address of the second token
    /// @param _feeParams the FactoryFeeParams to pack and save
    function _setFeesParametersOnPair(
        IERC20 _tokenX,
        IERC20 _tokenY,
        FactoryFeeParams calldata _feeParams
    ) internal {
        IDLPair _DLPair = _getDLPairInformation(_tokenX, _tokenY, _feeParams.binStep).dlPair;

        if (address(_DLPair) == address(0)) revert DLFactory__DLPairNotCreated(_tokenX, _tokenY, _feeParams.binStep);

        bytes32 _packedFeeParameters = _getPackedFeeParameters(
            _feeParams.binStep,
            _feeParams.baseFactor,
            _feeParams.filterPeriod,
            _feeParams.decayPeriod,
            _feeParams.reductionFactor,
            _feeParams.variableFeeControl,
            _feeParams.protocolShare,
            _feeParams.maxVolatilityAccumulated
        );

        _DLPair.setFeesParameters(_packedFeeParameters);

        emit FeeParametersSet(
            msg.sender,
            _DLPair,
            _feeParams
        );
    }

    /// @notice Function to set whether the pair is ignored or not for routing, it will make the pair unusable by the router
    /// @param _tokenX The address of the first token of the pair
    /// @param _tokenY The address of the second token of the pair
    /// @param _binStep The bin step in basis point of the pair
    /// @param _ignored Whether to ignore (true) or not (false) the pair for routing
    function _setDLPairIgnored(
        IERC20 _tokenX,
        IERC20 _tokenY,
        uint256 _binStep,
        bool _ignored
    ) internal {
        (IERC20 _tokenA, IERC20 _tokenB) = _sortTokens(_tokenX, _tokenY);

        DLPairInformation memory _dlPairInformation = _dlPairsInfo[_tokenA][_tokenB][_binStep];
        if (address(_dlPairInformation.dlPair) == address(0)) revert DLFactory__AddressZero();

        if (_dlPairInformation.ignoredForRouting == _ignored) revert DLFactory__DLPairIgnoredIsAlreadyInTheSameState();

        _dlPairsInfo[_tokenA][_tokenB][_binStep].ignoredForRouting = _ignored;

        emit DLPairIgnoredStateChanged(_dlPairInformation.dlPair, _ignored);
    }

    /// @notice Returns the DLPairInformation if it exists,
    /// if not, then the address 0 is returned. The order doesn't matter
    /// @param _tokenA The address of the first token of the pair
    /// @param _tokenB The address of the second token of the pair
    /// @param _binStep The bin step of the DLPair
    /// @return The DLPairInformation
    function _getDLPairInformation(
        IERC20 _tokenA,
        IERC20 _tokenB,
        uint256 _binStep
    ) internal view returns (DLPairInformation memory) {
        (_tokenA, _tokenB) = _sortTokens(_tokenA, _tokenB);
        return _dlPairsInfo[_tokenA][_tokenB][_binStep];
    }

    /// @notice View function to return all the DLPair of a pair of tokens
    /// @param _tokenX The first token of the pair
    /// @param _tokenY The second token of the pair
    /// @return DLPairsAvailable The list of available DLPairs
    function _getAllDLPairs(IERC20 _tokenX, IERC20 _tokenY)
        internal
        view
        returns (DLPairInformation[] memory DLPairsAvailable)
    {
        unchecked {
            (IERC20 _tokenA, IERC20 _tokenB) = _sortTokens(_tokenX, _tokenY);

            bytes32 _avDLPairBinSteps = _availableDLPairBinSteps[_tokenA][_tokenB];
            uint256 _nbAvailable = _avDLPairBinSteps.decode(type(uint8).max, 248);

            if (_nbAvailable > 0) {
                DLPairsAvailable = new DLPairInformation[](_nbAvailable);

                uint256 _index;
                for (uint256 i = MIN_BIN_STEP; i <= MAX_BIN_STEP; ++i) {
                    if (_avDLPairBinSteps.decode(1, i) == 1) {
                        DLPairInformation memory _dlPairInformation = _dlPairsInfo[_tokenA][_tokenB][i];

                        DLPairsAvailable[_index] = DLPairInformation({
                            binStep: i.safe16(),
                            dlPair: _dlPairInformation.dlPair,
                            createdByOwner: _dlPairInformation.createdByOwner,
                            ignoredForRouting: _dlPairInformation.ignoredForRouting
                        });
                        if (++_index == _nbAvailable) break;
                    }
                }
            }
        }
    }

    /// @notice Private view function to sort 2 tokens in ascending order
    /// @param _tokenA The first token
    /// @param _tokenB The second token
    /// @return The sorted first token
    /// @return The sorted second token
    function _sortTokens(IERC20 _tokenA, IERC20 _tokenB) internal pure returns (IERC20, IERC20) {
        if (_tokenA > _tokenB) (_tokenA, _tokenB) = (_tokenB, _tokenA);
        return (_tokenA, _tokenB);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";

import {FeeHelper} from "../libraries/FeeHelper.sol";
import {IDLFactory} from "./IDLFactory.sol";
import {IDLFlashLoanCallback} from "./IDLFlashLoanCallback.sol";

/// @title Discretized Liquidity Pair Interface
/// @author Bentoswap
/// @notice Required interface of DLPair contract
interface IDLPair {
    /// @dev Structure to store the reserves of bins:
    /// - reserveX: The current reserve of tokenX of the bin
    /// - reserveY: The current reserve of tokenY of the bin
    struct Bin {
        uint112 reserveX;
        uint112 reserveY;
        uint256 accTokenXPerShare;
        uint256 accTokenYPerShare;
    }

    /// @dev Structure to store the information of the pair such as:
    /// slot0:
    /// - activeId: The current id used for swaps, this is also linked with the price
    /// - reserveX: The sum of amounts of tokenX across all bins
    /// slot1:
    /// - reserveY: The sum of amounts of tokenY across all bins
    /// - oracleSampleLifetime: The lifetime of an oracle sample
    /// - oracleSize: The current size of the oracle, can be increase by users
    /// - oracleActiveSize: The current active size of the oracle, composed only from non empty data sample
    /// - oracleLastTimestamp: The current last timestamp at which a sample was added to the circular buffer
    /// - oracleId: The current id of the oracle
    /// slot2:
    /// - feesX: The current amount of fees to distribute in tokenX (total, protocol)
    /// slot3:
    /// - feesY: The current amount of fees to distribute in tokenY (total, protocol)
    struct PairInformation {
        uint24 activeId;
        uint136 reserveX;
        uint136 reserveY;
        uint16 oracleSampleLifetime;
        uint16 oracleSize;
        uint16 oracleActiveSize;
        uint40 oracleLastTimestamp;
        uint16 oracleId;
        FeeHelper.FeesDistribution feesX;
        FeeHelper.FeesDistribution feesY;
    }

    /// @dev Structure to store the debts of users
    /// - debtX: The tokenX's debt
    /// - debtY: The tokenY's debt
    struct Debts {
        uint256 debtX;
        uint256 debtY;
    }

    /// @dev Structure to store fees:
    /// - tokenX: The amount of fees of token X
    /// - tokenY: The amount of fees of token Y
    struct Fees {
        uint128 tokenX;
        uint128 tokenY;
    }

    /// @dev Structure to minting informations:
    /// - amountXIn: The amount of token X sent
    /// - amountYIn: The amount of token Y sent
    /// - amountXAddedToPair: The amount of token X that have been actually added to the pair
    /// - amountYAddedToPair: The amount of token Y that have been actually added to the pair
    /// - activeFeeX: Fees X currently generated
    /// - activeFeeY: Fees Y currently generated
    /// - totalDistributionX: Total distribution of token X. Should be 1e18 (100%) or 0 (0%)
    /// - totalDistributionY: Total distribution of token Y. Should be 1e18 (100%) or 0 (0%)
    /// - id: Id of the current working bin when looping on the distribution array
    /// - amountX: The amount of token X deposited in the current bin
    /// - amountY: The amount of token Y deposited in the current bin
    /// - distributionX: Distribution of token X for the current working bin
    /// - distributionY: Distribution of token Y for the current working bin
    struct MintInfo {
        uint256 amountXIn;
        uint256 amountYIn;
        uint256 amountXAddedToPair;
        uint256 amountYAddedToPair;
        uint256 activeFeeX;
        uint256 activeFeeY;
        uint256 totalDistributionX;
        uint256 totalDistributionY;
        uint256 id;
        uint256 amountX;
        uint256 amountY;
        uint256 distributionX;
        uint256 distributionY;
    }

    event Swap(
        address indexed sender,
        address indexed recipient,
        uint24 indexed id,
        uint256 amountXIn,
        uint256 amountYIn,
        uint256 amountXOut,
        uint256 amountYOut,
        uint256 volatilityAccumulated,
        uint256 feesX,
        uint256 feesY
    );

    event FlashLoan(
        address indexed sender,
        IDLFlashLoanCallback indexed receiver,
        IERC20 token,
        uint256 amount,
        uint256 fee
    );

    event LiquidityAdded(
        address indexed sender,
        address indexed recipient,
        uint256 indexed id,
        uint256 minted,
        uint256 amountX,
        uint256 amountY,
        uint256 distributionX,
        uint256 distributionY
    );

    event CompositionFee(
        address indexed sender,
        address indexed recipient,
        uint256 indexed id,
        uint256 feesX,
        uint256 feesY
    );

    event LiquidityRemoved(
        address indexed sender,
        address indexed recipient,
        uint256 indexed id,
        uint256 burned,
        uint256 amountX,
        uint256 amountY
    );

    event FeesCollected(address indexed sender, address indexed recipient, uint256 amountX, uint256 amountY);

    event ProtocolFeesCollected(address indexed sender, address indexed recipient, uint256 amountX, uint256 amountY);

    event OracleSizeIncreased(uint256 previousSize, uint256 newSize);

    function tokenX() external view returns (IERC20);

    function tokenY() external view returns (IERC20);

    function factory() external view returns (IDLFactory);

    function getReservesAndId()
        external
        view
        returns (
            uint256 reserveX,
            uint256 reserveY,
            uint256 activeId
        );

    function getGlobalFees()
        external
        view
        returns (
            uint128 feesXTotal,
            uint128 feesYTotal,
            uint128 feesXProtocol,
            uint128 feesYProtocol
        );

    function getOracleParameters()
        external
        view
        returns (
            uint256 oracleSampleLifetime,
            uint256 oracleSize,
            uint256 oracleActiveSize,
            uint256 oracleLastTimestamp,
            uint256 oracleId,
            uint256 min,
            uint256 max
        );

    function getOracleSampleFrom(uint256 timeDelta)
        external
        view
        returns (
            uint256 cumulativeId,
            uint256 cumulativeAccumulator,
            uint256 cumulativeBinCrossed
        );

    function feeParameters() external view returns (FeeHelper.FeeParameters memory);

    function findFirstNonEmptyBinId(uint24 id_, bool sentTokenY) external view returns (uint24 id);

    function getBin(uint24 id) external view returns (uint256 reserveX, uint256 reserveY);

    function pendingFees(address account, uint256[] memory ids)
        external
        view
        returns (uint256 amountX, uint256 amountY);

    function swap(bool sentTokenY, address to) external returns (uint256 amountXOut, uint256 amountYOut);

    function flashLoan(
        IDLFlashLoanCallback receiver,
        IERC20 token,
        uint256 amount,
        bytes calldata data
    ) external;

    function mint(
        uint256[] calldata ids,
        uint256[] calldata distributionX,
        uint256[] calldata distributionY,
        address to
    )
        external
        returns (
            uint256 amountXAddedToPair,
            uint256 amountYAddedToPair,
            uint256[] memory liquidityMinted
        );

    function burn(
        uint256[] calldata ids,
        uint256[] calldata amounts,
        address to
    ) external returns (uint256 amountX, uint256 amountY);

    function increaseOracleLength(uint16 newSize) external;

    function collectFees(address account, uint256[] calldata ids) external returns (uint256 amountX, uint256 amountY);

    function collectProtocolFees() external returns (uint128 amountX, uint128 amountY);

    function setFeesParameters(bytes32 packedFeeParameters) external;

    function forceDecay() external;

    function initialize(
        IERC20 tokenX,
        IERC20 tokenY,
        uint24 activeId,
        uint16 sampleLifetime,
        bytes32 packedFeeParameters
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create(0, 0x09, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create2(0, 0x09, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(add(ptr, 0x38), deployer)
            mstore(add(ptr, 0x24), 0x5af43d82803e903d91602b57fd5bf3ff)
            mstore(add(ptr, 0x14), implementation)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73)
            mstore(add(ptr, 0x58), salt)
            mstore(add(ptr, 0x78), keccak256(add(ptr, 0x0c), 0x37))
            predicted := keccak256(add(ptr, 0x43), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
 * ====
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";

/** DLRouter errors */

error DLRouter__SenderIsNotWCT();
error DLRouter__PairNotCreated(address tokenX, address tokenY, uint256 binStep);
error DLRouter__WrongAmounts(uint256 amount, uint256 reserve);
error DLRouter__SwapOverflows(uint256 id);
error DLRouter__BrokenSwapSafetyCheck();
error DLRouter__NotFactoryOwner();
error DLRouter__TooMuchTokensIn(uint256 excess);
error DLRouter__BinReserveOverflows(uint256 id);
error DLRouter__MissingBinStepForPair(address tokenX, address tokenY);
error DLRouter__IdOverflows(int256 id);
error DLRouter__LengthsMismatch();
error DLRouter__WrongTokenOrder();
error DLRouter__IdSlippageCaught(uint256 activeIdDesired, uint256 idSlippage, uint256 activeId);
error DLRouter__AmountSlippageCaught(uint256 amountXMin, uint256 amountX, uint256 amountYMin, uint256 amountY);
error DLRouter__IdDesiredOverflows(uint256 idDesired, uint256 idSlippage);
error DLRouter__FailedToSendCT(address recipient, uint256 amount);
error DLRouter__DeadlineExceeded(uint256 deadline, uint256 currentTimestamp);
error DLRouter__AmountSlippageBPTooBig(uint256 amountSlippage);
error DLRouter__InsufficientAmountOut(uint256 amountOutMin, uint256 amountOut);
error DLRouter__MaxAmountInExceeded(uint256 amountInMax, uint256 amountIn);
error DLRouter__InvalidTokenPath(address wrongToken);
error DLRouter__InvalidVersion(uint256 version);
error DLRouter__WrongWCTLiquidityParameters(
    address tokenX,
    address tokenY,
    uint256 amountX,
    uint256 amountY,
    uint256 msgValue
);

/** DLToken errors */

error DLToken__SpenderNotApproved(address owner, address spender);
error DLToken__TransferFromOrToAddress0();
error DLToken__MintToAddress0();
error DLToken__BurnFromAddress0();
error DLToken__BurnExceedsBalance(address from, uint256 id, uint256 amount);
error DLToken__LengthMismatch(uint256 accountsLength, uint256 idsLength);
error DLToken__SelfApproval(address owner);
error DLToken__TransferExceedsBalance(address from, uint256 id, uint256 amount);
error DLToken__TransferToSelf();
error DLToken__NotSupported();

/** DLFactory errors */

error DLFactory__IdenticalAddresses(IERC20 token_);
error DLFactory__QuoteAssetNotWhitelisted(IERC20 quoteAsset_);
error DLFactory__QuoteAssetAlreadyWhitelisted(IERC20 quoteAsset_);
error DLFactory__AddressZero();
error DLFactory__DLPairAlreadyExists(IERC20 tokenX_, IERC20 tokenY_, uint256 binStep_);
error DLFactory__DLPairNotCreated(IERC20 tokenX_, IERC20 tokenY_, uint256 binStep_);
error DLFactory__DecreasingPeriods(uint16 filterPeriod_, uint16 decayPeriod_);
error DLFactory__ReductionFactorOverflows(uint16 reductionFactor_, uint256 max_);
error DLFactory__VariableFeeControlOverflows(uint16 variableFeeControl, uint256 max_);
error DLFactory__BaseFeesBelowMin(uint256 baseFees_, uint256 minBaseFees_);
error DLFactory__FeesAboveMax(uint256 fees_, uint256 maxFees_);
error DLFactory__FlashLoanFeeAboveMax(uint256 fees_, uint256 maxFees_);
error DLFactory__BinStepRequirementsBreached(uint256 lowerBound_, uint16 binStep_, uint256 higherBound_);
error DLFactory__ProtocolShareOverflows(uint16 protocolShare_, uint256 max_);
error DLFactory__FunctionIsLockedForUsers(address user_);
error DLFactory__FactoryLockIsAlreadyInTheSameState();
error DLFactory__FactoryQuoteAssetRestrictedIsAlreadyInTheSameState();
error DLFactory__DLPairIgnoredIsAlreadyInTheSameState();
error DLFactory__BinStepHasNoPreset(uint256 binStep_);
error DLFactory__SameFeeRecipient(address feeRecipient_);
error DLFactory__SameFlashLoanFee(uint256 flashLoanFee_);
error DLFactory__DLPairSafetyCheckFailed(address DLPairImplementation_);
error DLFactory__SameImplementation(address DLPairImplementation_);
error DLFactory__ImplementationNotSet();

/** DLPair errors */

error DLPair__InsufficientAmounts();
error DLPair__AddressZero();
error DLPair__AddressZeroOrThis();
error DLPair__BrokenSwapSafetyCheck();
error DLPair__CompositionFactorFlawed(uint256 id_);
error DLPair__InsufficientLiquidityMinted(uint256 id_);
error DLPair__InsufficientLiquidityBurned(uint256 id_);
error DLPair__WrongLengths();
error DLPair__OnlyStrictlyIncreasingId();
error DLPair__OnlyFactory();
error DLPair__DistributionsOverflow();
error DLPair__OnlyFeeRecipient(address feeRecipient_, address sender_);
error DLPair__OracleNotEnoughSample();
error DLPair__FlashLoanCallbackFailed();
error DLPair__FlashLoanInvalidBalance();
error DLPair__FlashLoanInvalidToken();
error DLPair__AlreadyInitialized();
error DLPair__NewSizeTooSmall(uint256 newSize_, uint256 oracleSize_);

/** BinHelper errors */

error BinHelper__BinStepOverflows(uint256 bp_);
error BinHelper__IdOverflows();

/** FeeDistributionHelper errors */

error FeeDistributionHelper__FlashLoanWrongFee(uint256 receivedFee_, uint256 expectedFee_);

/** Math128x128 errors */

error Math128x128__PowerUnderflow(uint256 x_, int256 y_);
error Math128x128__LogUnderflow();

/** Math512Bits errors */

error Math512Bits__MulDivOverflow(uint256 prod1_, uint256 denominator_);
error Math512Bits__ShiftDivOverflow(uint256 prod1_, uint256 denominator_);
error Math512Bits__MulShiftOverflow(uint256 prod1_, uint256 offset_);
error Math512Bits__OffsetOverflows(uint256 offset_);

/** Oracle errors */

error Oracle__AlreadyInitialized(uint256 index_);
error Oracle__LookUpTimestampTooOld(uint256 minTimestamp_, uint256 lookUpTimestamp_);
error Oracle__NotInitialized();

/** PendingOwnable errors */

error PendingOwnable__NotOwner();
error PendingOwnable__NotPendingOwner();
error PendingOwnable__PendingOwnerAlreadySet();
error PendingOwnable__NoPendingOwner();
error PendingOwnable__AddressZero();

/** ReentrancyGuardUpgradeable errors */

error ReentrancyGuardUpgradeable__ReentrantCall();
error ReentrancyGuardUpgradeable__AlreadyInitialized();

/** SafeCast errors */

error SafeCast__Exceeds256Bits(uint256 x_);
error SafeCast__Exceeds248Bits(uint256 x_);
error SafeCast__Exceeds240Bits(uint256 x_);
error SafeCast__Exceeds232Bits(uint256 x_);
error SafeCast__Exceeds224Bits(uint256 x_);
error SafeCast__Exceeds216Bits(uint256 x_);
error SafeCast__Exceeds208Bits(uint256 x_);
error SafeCast__Exceeds200Bits(uint256 x_);
error SafeCast__Exceeds192Bits(uint256 x_);
error SafeCast__Exceeds184Bits(uint256 x_);
error SafeCast__Exceeds176Bits(uint256 x_);
error SafeCast__Exceeds168Bits(uint256 x_);
error SafeCast__Exceeds160Bits(uint256 x_);
error SafeCast__Exceeds152Bits(uint256 x_);
error SafeCast__Exceeds144Bits(uint256 x_);
error SafeCast__Exceeds136Bits(uint256 x_);
error SafeCast__Exceeds128Bits(uint256 x_);
error SafeCast__Exceeds120Bits(uint256 x_);
error SafeCast__Exceeds112Bits(uint256 x_);
error SafeCast__Exceeds104Bits(uint256 x_);
error SafeCast__Exceeds96Bits(uint256 x_);
error SafeCast__Exceeds88Bits(uint256 x_);
error SafeCast__Exceeds80Bits(uint256 x_);
error SafeCast__Exceeds72Bits(uint256 x_);
error SafeCast__Exceeds64Bits(uint256 x_);
error SafeCast__Exceeds56Bits(uint256 x_);
error SafeCast__Exceeds48Bits(uint256 x_);
error SafeCast__Exceeds40Bits(uint256 x_);
error SafeCast__Exceeds32Bits(uint256 x_);
error SafeCast__Exceeds24Bits(uint256 x_);
error SafeCast__Exceeds16Bits(uint256 x_);
error SafeCast__Exceeds8Bits(uint256 x_);

/** TreeMath errors */

error TreeMath__ErrorDepthSearch();

/** TokenHelper errors */

error TokenHelper__NonContract();
error TokenHelper__CallFailed();
error TokenHelper__TransferFailed();

/** DLQuoter errors */

error DLQuoter_InvalidLength();

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import {Constants} from "./Constants.sol";
import {
    BinHelper__BinStepOverflows,
    BinHelper__IdOverflows
} from "../DLErrors.sol";
import {Math128x128} from "./Math128x128.sol";

/// @title Discretized Liquidity Bin Helper Library
/// @author Bentoswap
/// @notice Contract used to convert bin ID to price and back
library BinHelper {
    using Math128x128 for uint256;

    int256 private constant REAL_ID_SHIFT = 1 << 23;

    /// @notice Returns the id corresponding to the given price
    /// @dev The id may be inaccurate due to rounding issues, always trust getPriceFromId rather than
    /// getIdFromPrice
    /// @param _price The price of y per x as a 128.128-binary fixed-point number
    /// @param _binStep The bin step
    /// @return The id corresponding to this price
    function getIdFromPrice(uint256 _price, uint256 _binStep) internal pure returns (uint24) {
        unchecked {
            uint256 _binStepValue = _getBPValue(_binStep);

            // can't overflow as `2**23 + log2(price) < 2**23 + 2**128 < max(uint256)`
            int256 _id = REAL_ID_SHIFT + _price.log2() / _binStepValue.log2();

            if (_id < 0 || uint256(_id) > type(uint24).max) revert BinHelper__IdOverflows();
            return uint24(uint256(_id));
        }
    }

    /// @notice Returns the price corresponding to the given ID, as a 128.128-binary fixed-point number
    /// @dev This is the trusted function to link id to price, the other way may be inaccurate
    /// @param _id The id
    /// @param _binStep The bin step
    /// @return The price corresponding to this id, as a 128.128-binary fixed-point number
    function getPriceFromId(uint256 _id, uint256 _binStep) internal pure returns (uint256) {
        if (_id > uint256(type(uint24).max)) revert BinHelper__IdOverflows();
        unchecked {
            int256 _realId = int256(_id) - REAL_ID_SHIFT;

            return _getBPValue(_binStep).power(_realId);
        }
    }

    /// @notice Returns the (1 + bp) value as a 128.128-decimal fixed-point number
    /// @param _binStep The bp value in [1; 100] (referring to 0.01% to 1%)
    /// @return The (1+bp) value as a 128.128-decimal fixed-point number
    /// Example: SCALE = 340282366920938463463374607431768211456, _binStep = 25 (0.25%)
    /// _binStepFP = _binStep << Constants.SCALE_OFFSET = 8507059173023461586584365185794205286400 (25 in 128.128 FP)
    /// SCALE + (_binStepFP / 10_000) = 341133072838240809622033043950347631984 = 1.0025 in 128.128 FP
    function _getBPValue(uint256 _binStep) internal pure returns (uint256) {
        if (_binStep == 0 || _binStep > Constants.BASIS_POINT_MAX) revert BinHelper__BinStepOverflows(_binStep);

        unchecked {
            // can't overflow as `max(result) = 2**128 + 10_000 << 128 / 10_000 < max(uint256)`
            return Constants.SCALE + (_binStep << Constants.SCALE_OFFSET) / Constants.BASIS_POINT_MAX;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

/// @title Discretized Liquidity Decoder Library
/// @author Bentoswap
/// @notice Helper contract used for decoding bytes32 sample
library Decoder {
    /// @notice Internal function to decode a bytes32 sample using a mask and offset
    /// @dev This function can overflow
    /// @param _sample The sample as a bytes32
    /// @param _mask The mask
    /// @param _offset The offset
    /// @return value The decoded value
    function decode(
        bytes32 _sample,
        uint256 _mask,
        uint256 _offset
    ) internal pure returns (uint256 value) {
        assembly {
            value := and(shr(_offset, _sample), _mask)
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import {
    SafeCast__Exceeds248Bits,
    SafeCast__Exceeds240Bits,
    SafeCast__Exceeds232Bits,
    SafeCast__Exceeds224Bits,
    SafeCast__Exceeds216Bits,
    SafeCast__Exceeds208Bits,
    SafeCast__Exceeds200Bits,
    SafeCast__Exceeds192Bits,
    SafeCast__Exceeds184Bits,
    SafeCast__Exceeds176Bits,
    SafeCast__Exceeds168Bits,
    SafeCast__Exceeds160Bits,
    SafeCast__Exceeds152Bits,
    SafeCast__Exceeds144Bits,
    SafeCast__Exceeds136Bits,
    SafeCast__Exceeds128Bits,
    SafeCast__Exceeds120Bits,
    SafeCast__Exceeds112Bits,
    SafeCast__Exceeds104Bits,
    SafeCast__Exceeds96Bits,
    SafeCast__Exceeds88Bits,
    SafeCast__Exceeds80Bits,
    SafeCast__Exceeds72Bits,
    SafeCast__Exceeds64Bits,
    SafeCast__Exceeds56Bits,
    SafeCast__Exceeds48Bits,
    SafeCast__Exceeds40Bits,
    SafeCast__Exceeds32Bits,
    SafeCast__Exceeds24Bits,
    SafeCast__Exceeds16Bits,
    SafeCast__Exceeds8Bits
} from "../DLErrors.sol";

/// @title Discretized Liquidity Safe Cast Library
/// @author Bentoswap
/// @notice Helper contract used for converting uint values safely
library SafeCast {
    /// @notice Returns x on uint248 and check that it does not overflow
    /// @param x The value as an uint256
    /// @return y The value as an uint248
    function safe248(uint256 x) internal pure returns (uint248 y) {
        if ((y = uint248(x)) != x) revert SafeCast__Exceeds248Bits(x);
    }

    /// @notice Returns x on uint240 and check that it does not overflow
    /// @param x The value as an uint256
    /// @return y The value as an uint240
    function safe240(uint256 x) internal pure returns (uint240 y) {
        if ((y = uint240(x)) != x) revert SafeCast__Exceeds240Bits(x);
    }

    /// @notice Returns x on uint232 and check that it does not overflow
    /// @param x The value as an uint256
    /// @return y The value as an uint232
    function safe232(uint256 x) internal pure returns (uint232 y) {
        if ((y = uint232(x)) != x) revert SafeCast__Exceeds232Bits(x);
    }

    /// @notice Returns x on uint224 and check that it does not overflow
    /// @param x The value as an uint256
    /// @return y The value as an uint224
    function safe224(uint256 x) internal pure returns (uint224 y) {
        if ((y = uint224(x)) != x) revert SafeCast__Exceeds224Bits(x);
    }

    /// @notice Returns x on uint216 and check that it does not overflow
    /// @param x The value as an uint256
    /// @return y The value as an uint216
    function safe216(uint256 x) internal pure returns (uint216 y) {
        if ((y = uint216(x)) != x) revert SafeCast__Exceeds216Bits(x);
    }

    /// @notice Returns x on uint208 and check that it does not overflow
    /// @param x The value as an uint256
    /// @return y The value as an uint208
    function safe208(uint256 x) internal pure returns (uint208 y) {
        if ((y = uint208(x)) != x) revert SafeCast__Exceeds208Bits(x);
    }

    /// @notice Returns x on uint200 and check that it does not overflow
    /// @param x The value as an uint256
    /// @return y The value as an uint200
    function safe200(uint256 x) internal pure returns (uint200 y) {
        if ((y = uint200(x)) != x) revert SafeCast__Exceeds200Bits(x);
    }

    /// @notice Returns x on uint192 and check that it does not overflow
    /// @param x The value as an uint256
    /// @return y The value as an uint192
    function safe192(uint256 x) internal pure returns (uint192 y) {
        if ((y = uint192(x)) != x) revert SafeCast__Exceeds192Bits(x);
    }

    /// @notice Returns x on uint184 and check that it does not overflow
    /// @param x The value as an uint256
    /// @return y The value as an uint184
    function safe184(uint256 x) internal pure returns (uint184 y) {
        if ((y = uint184(x)) != x) revert SafeCast__Exceeds184Bits(x);
    }

    /// @notice Returns x on uint176 and check that it does not overflow
    /// @param x The value as an uint256
    /// @return y The value as an uint176
    function safe176(uint256 x) internal pure returns (uint176 y) {
        if ((y = uint176(x)) != x) revert SafeCast__Exceeds176Bits(x);
    }

    /// @notice Returns x on uint168 and check that it does not overflow
    /// @param x The value as an uint256
    /// @return y The value as an uint168
    function safe168(uint256 x) internal pure returns (uint168 y) {
        if ((y = uint168(x)) != x) revert SafeCast__Exceeds168Bits(x);
    }

    /// @notice Returns x on uint160 and check that it does not overflow
    /// @param x The value as an uint256
    /// @return y The value as an uint160
    function safe160(uint256 x) internal pure returns (uint160 y) {
        if ((y = uint160(x)) != x) revert SafeCast__Exceeds160Bits(x);
    }

    /// @notice Returns x on uint152 and check that it does not overflow
    /// @param x The value as an uint256
    /// @return y The value as an uint152
    function safe152(uint256 x) internal pure returns (uint152 y) {
        if ((y = uint152(x)) != x) revert SafeCast__Exceeds152Bits(x);
    }

    /// @notice Returns x on uint144 and check that it does not overflow
    /// @param x The value as an uint256
    /// @return y The value as an uint144
    function safe144(uint256 x) internal pure returns (uint144 y) {
        if ((y = uint144(x)) != x) revert SafeCast__Exceeds144Bits(x);
    }

    /// @notice Returns x on uint136 and check that it does not overflow
    /// @param x The value as an uint256
    /// @return y The value as an uint136
    function safe136(uint256 x) internal pure returns (uint136 y) {
        if ((y = uint136(x)) != x) revert SafeCast__Exceeds136Bits(x);
    }

    /// @notice Returns x on uint128 and check that it does not overflow
    /// @param x The value as an uint256
    /// @return y The value as an uint128
    function safe128(uint256 x) internal pure returns (uint128 y) {
        if ((y = uint128(x)) != x) revert SafeCast__Exceeds128Bits(x);
    }

    /// @notice Returns x on uint120 and check that it does not overflow
    /// @param x The value as an uint256
    /// @return y The value as an uint120
    function safe120(uint256 x) internal pure returns (uint120 y) {
        if ((y = uint120(x)) != x) revert SafeCast__Exceeds120Bits(x);
    }

    /// @notice Returns x on uint112 and check that it does not overflow
    /// @param x The value as an uint256
    /// @return y The value as an uint112
    function safe112(uint256 x) internal pure returns (uint112 y) {
        if ((y = uint112(x)) != x) revert SafeCast__Exceeds112Bits(x);
    }

    /// @notice Returns x on uint104 and check that it does not overflow
    /// @param x The value as an uint256
    /// @return y The value as an uint104
    function safe104(uint256 x) internal pure returns (uint104 y) {
        if ((y = uint104(x)) != x) revert SafeCast__Exceeds104Bits(x);
    }

    /// @notice Returns x on uint96 and check that it does not overflow
    /// @param x The value as an uint256
    /// @return y The value as an uint96
    function safe96(uint256 x) internal pure returns (uint96 y) {
        if ((y = uint96(x)) != x) revert SafeCast__Exceeds96Bits(x);
    }

    /// @notice Returns x on uint88 and check that it does not overflow
    /// @param x The value as an uint256
    /// @return y The value as an uint88
    function safe88(uint256 x) internal pure returns (uint88 y) {
        if ((y = uint88(x)) != x) revert SafeCast__Exceeds88Bits(x);
    }

    /// @notice Returns x on uint80 and check that it does not overflow
    /// @param x The value as an uint256
    /// @return y The value as an uint80
    function safe80(uint256 x) internal pure returns (uint80 y) {
        if ((y = uint80(x)) != x) revert SafeCast__Exceeds80Bits(x);
    }

    /// @notice Returns x on uint72 and check that it does not overflow
    /// @param x The value as an uint256
    /// @return y The value as an uint72
    function safe72(uint256 x) internal pure returns (uint72 y) {
        if ((y = uint72(x)) != x) revert SafeCast__Exceeds72Bits(x);
    }

    /// @notice Returns x on uint64 and check that it does not overflow
    /// @param x The value as an uint256
    /// @return y The value as an uint64
    function safe64(uint256 x) internal pure returns (uint64 y) {
        if ((y = uint64(x)) != x) revert SafeCast__Exceeds64Bits(x);
    }

    /// @notice Returns x on uint56 and check that it does not overflow
    /// @param x The value as an uint256
    /// @return y The value as an uint56
    function safe56(uint256 x) internal pure returns (uint56 y) {
        if ((y = uint56(x)) != x) revert SafeCast__Exceeds56Bits(x);
    }

    /// @notice Returns x on uint48 and check that it does not overflow
    /// @param x The value as an uint256
    /// @return y The value as an uint48
    function safe48(uint256 x) internal pure returns (uint48 y) {
        if ((y = uint48(x)) != x) revert SafeCast__Exceeds48Bits(x);
    }

    /// @notice Returns x on uint40 and check that it does not overflow
    /// @param x The value as an uint256
    /// @return y The value as an uint40
    function safe40(uint256 x) internal pure returns (uint40 y) {
        if ((y = uint40(x)) != x) revert SafeCast__Exceeds40Bits(x);
    }

    /// @notice Returns x on uint32 and check that it does not overflow
    /// @param x The value as an uint256
    /// @return y The value as an uint32
    function safe32(uint256 x) internal pure returns (uint32 y) {
        if ((y = uint32(x)) != x) revert SafeCast__Exceeds32Bits(x);
    }

    /// @notice Returns x on uint24 and check that it does not overflow
    /// @param x The value as an uint256
    /// @return y The value as an uint24
    function safe24(uint256 x) internal pure returns (uint24 y) {
        if ((y = uint24(x)) != x) revert SafeCast__Exceeds24Bits(x);
    }

    /// @notice Returns x on uint16 and check that it does not overflow
    /// @param x The value as an uint256
    /// @return y The value as an uint16
    function safe16(uint256 x) internal pure returns (uint16 y) {
        if ((y = uint16(x)) != x) revert SafeCast__Exceeds16Bits(x);
    }

    /// @notice Returns x on uint8 and check that it does not overflow
    /// @param x The value as an uint256
    /// @return y The value as an uint8
    function safe8(uint256 x) internal pure returns (uint8 y) {
        if ((y = uint8(x)) != x) revert SafeCast__Exceeds8Bits(x);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";
import {EnumerableSet} from "openzeppelin/utils/structs/EnumerableSet.sol";

import {
    DLFactory__QuoteAssetAlreadyWhitelisted,
    DLFactory__QuoteAssetNotWhitelisted
} from "../../DLErrors.sol";
import {DLFactoryPresets} from "./DLFactoryPresets.sol";

/// @title Discretized Liquidity Factory QuoteAsset Handling
/// @author Bentoswap
/// @notice Contract used to manage the list of allowed quote assets while the factory is being curated
abstract contract DLFactoryQuoteAssets is DLFactoryPresets {
    using EnumerableSet for EnumerableSet.AddressSet;

    constructor(address _feeRecipient, uint256 _flashLoanFee) DLFactoryPresets(_feeRecipient, _flashLoanFee) { }

    // <<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>>
    //     -'~'-.,__,.-'~'-.,__,.- EXTERNAL -.,__,.-'~'-.,__,.-'~'-
    // <<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>>

    /// @notice View function to return the quote asset whitelisted at index `index`
    /// @param _index The index
    /// @return The address of the _quoteAsset at index `index`
    function getQuoteAsset(uint256 _index) external view override returns (IERC20) {
        return IERC20(_allowedQuoteAssets.at(_index));
    }

    /// @notice View function to return the number of quote assets whitelisted
    /// @return The number of quote assets
    function getNumberOfQuoteAssets() external view override returns (uint256) {
        return _allowedQuoteAssets.length();
    }

    /// @notice View function to return whether a token is a quotedAsset (true) or not (false)
    /// @param _token The address of the asset
    /// @return Whether the token is a quote asset or not
    function isQuoteAsset(IERC20 _token) external view override returns (bool) {
        return _allowedQuoteAssets.contains(address(_token));
    }

    /// @notice Function to add an asset to the whitelist of quote assets
    /// @param _quoteAsset The quote asset (e.g: AVAX, USDC...)
    function addQuoteAsset(IERC20 _quoteAsset) external override onlyOwner {
        if (!_allowedQuoteAssets.add(address(_quoteAsset)))
            revert DLFactory__QuoteAssetAlreadyWhitelisted(_quoteAsset);

        emit QuoteAssetAdded(_quoteAsset);
    }

    /// @notice Function to remove an asset from the whitelist of quote assets
    /// @param _quoteAsset The quote asset (e.g: AVAX, USDC...)
    function removeQuoteAsset(IERC20 _quoteAsset) external override onlyOwner {
        if (!_allowedQuoteAssets.remove(address(_quoteAsset))) revert DLFactory__QuoteAssetNotWhitelisted(_quoteAsset);

        emit QuoteAssetRemoved(_quoteAsset);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import {Constants} from "./Constants.sol";
import {SafeCast} from "./SafeCast.sol";
import {SafeMath} from "./SafeMath.sol";

/// @title Discretized Liquidity Fee Helper Library
/// @author Bentoswap
/// @notice Helper contract used for fees calculation
library FeeHelper {
    using SafeCast for uint256;
    using SafeMath for uint256;

    /// @dev Structure to store the protocol fees:
    /// - binStep: The bin step
    /// - baseFactor: The base factor
    /// - filterPeriod: The filter period, where the fees stays constant
    /// - decayPeriod: The decay period, where the fees are halved
    /// - reductionFactor: The reduction factor, used to calculate the reduction of the accumulator
    /// - variableFeeControl: The variable fee control, used to control the variable fee, can be 0 to disable them
    /// - protocolShare: The share of fees sent to protocol
    /// - maxVolatilityAccumulated: The max value of volatility accumulated
    /// - volatilityAccumulated: The value of volatility accumulated
    /// - volatilityReference: The value of volatility reference
    /// - indexRef: The index reference
    /// - time: The last time the accumulator was called
    struct FeeParameters {
        // 144 lowest bits in slot
        uint16 binStep;
        uint16 baseFactor;
        uint16 filterPeriod;
        uint16 decayPeriod;
        uint16 reductionFactor;
        uint24 variableFeeControl;
        uint16 protocolShare;
        uint24 maxVolatilityAccumulated;
        // 112 highest bits in slot
        uint24 volatilityAccumulated;
        uint24 volatilityReference;
        uint24 indexRef;
        uint40 time;
    }

    /// @dev Structure used during swaps to distributes the fees:
    /// - total: The total amount of fees
    /// - protocol: The amount of fees reserved for protocol
    struct FeesDistribution {
        uint128 total;
        uint128 protocol;
    }

    /// @notice Update the value of the volatility accumulated
    /// @param _fp The current fee parameters
    /// @param _activeId The current active id
    function updateVariableFeeParameters(FeeParameters memory _fp, uint256 _activeId) internal view {
        uint256 _deltaT = block.timestamp - _fp.time;

        if (_deltaT >= _fp.filterPeriod || _fp.time == 0) {
            _fp.indexRef = uint24(_activeId);
            if (_deltaT < _fp.decayPeriod) {
                unchecked {
                    // This can't overflow as `reductionFactor <= BASIS_POINT_MAX`
                    _fp.volatilityReference = uint24(
                        (uint256(_fp.reductionFactor) * _fp.volatilityAccumulated) / Constants.BASIS_POINT_MAX
                    );
                }
            } else {
                _fp.volatilityReference = 0;
            }
        }

        _fp.time = (block.timestamp).safe40();

        updateVolatilityAccumulated(_fp, _activeId);
    }

    /// @notice Update the volatility accumulated
    /// @param _fp The fee parameter
    /// @param _activeId The current active id
    function updateVolatilityAccumulated(FeeParameters memory _fp, uint256 _activeId) internal pure {
        uint256 volatilityAccumulated = (_activeId.absSub(_fp.indexRef) * Constants.BASIS_POINT_MAX) +
            _fp.volatilityReference;
        _fp.volatilityAccumulated = volatilityAccumulated > _fp.maxVolatilityAccumulated
            ? _fp.maxVolatilityAccumulated
            : uint24(volatilityAccumulated);
    }

    /// @notice Returns the base fee added to a swap, with 18 decimals
    /// @param _fp The current fee parameters
    /// @return The fee with 18 decimals precision
    function getBaseFee(FeeParameters memory _fp) internal pure returns (uint256) {
        unchecked {
            return uint256(_fp.baseFactor) * _fp.binStep * 1e10;
        }
    }

    /// @notice Returns the variable fee added to a swap, with 18 decimals
    /// @param _fp The current fee parameters
    /// @return variableFee The variable fee with 18 decimals precision
    function getVariableFee(FeeParameters memory _fp) internal pure returns (uint256 variableFee) {
        if (_fp.variableFeeControl != 0) {
            // Can't overflow as the max value is `max(uint24) * (max(uint24) * max(uint16)) ** 2 < max(uint104)`
            // It returns 18 decimals as:
            // decimals(variableFeeControl * (volatilityAccumulated * binStep)**2 / 100) = 4 + (4 + 4) * 2 - 2 = 18
            unchecked {
                uint256 _prod = uint256(_fp.volatilityAccumulated) * _fp.binStep;
                variableFee = (_prod * _prod * _fp.variableFeeControl + 99) / 100;
            }
        }
    }

    /// @notice Return the amount of fees from an amount
    /// @dev Rounds amount up, follows `amount = amountWithFees - getFeeAmountFrom(fp, amountWithFees)`
    /// @param _fp The current fee parameter
    /// @param _amountWithFees The amount of token sent
    /// @return The fee amount from the amount sent
    function getFeeAmountFrom(FeeParameters memory _fp, uint256 _amountWithFees) internal pure returns (uint256) {
        return (_amountWithFees * getTotalFee(_fp) + Constants.PRECISION - 1) / (Constants.PRECISION);
    }

    /// @notice Return the fees to add to an amount
    /// @dev Rounds amount up, follows `amountWithFees = amount + getFeeAmount(fp, amount)`
    /// @param _fp The current fee parameter
    /// @param _amount The amount of token sent
    /// @return The fee amount to add to the amount
    function getFeeAmount(FeeParameters memory _fp, uint256 _amount) internal pure returns (uint256) {
        uint256 _fee = getTotalFee(_fp);
        uint256 _denominator = Constants.PRECISION - _fee;
        return (_amount * _fee + _denominator - 1) / _denominator;
    }

    /// @notice Return the fees added when an user adds liquidity and change the ratio in the active bin
    /// @dev Rounds amount up
    /// @param _fp The current fee parameter
    /// @param _amountWithFees The amount of token sent
    /// @return The fee amount
    function getFeeAmountForC(FeeParameters memory _fp, uint256 _amountWithFees) internal pure returns (uint256) {
        uint256 _fee = getTotalFee(_fp);
        uint256 _denominator = Constants.PRECISION * Constants.PRECISION;
        return (_amountWithFees * _fee * (_fee + Constants.PRECISION) + _denominator - 1) / _denominator;
    }

    /// @notice Return the fees distribution added to an amount
    /// @param _fp The current fee parameter
    /// @param _fees The fee amount
    /// @return fees The fee distribution
    function getFeeAmountDistribution(FeeParameters memory _fp, uint256 _fees)
        internal
        pure
        returns (FeesDistribution memory fees)
    {
        fees.total = _fees.safe128();
        // unsafe math is fine because total >= protocol
        unchecked {
            fees.protocol = uint128((_fees * _fp.protocolShare) / Constants.BASIS_POINT_MAX);
        }
    }

    /// @notice Return the total fee, i.e. baseFee + variableFee
    /// @param _fp The current fee parameter
    /// @return The total fee, with 18 decimals
    function getTotalFee(FeeParameters memory _fp) private pure returns (uint256) {
        unchecked {
            return getBaseFee(_fp) + getVariableFee(_fp);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";

import {IDLPair} from "./IDLPair.sol";
import {IPendingOwnable} from "./IPendingOwnable.sol";

/// @title Discretized Liquidity Factory Interface
/// @author Bentoswap
/// @notice Required interface of DLFactory contract
interface IDLFactory is IPendingOwnable {

    // <<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>>
    //   -'~'-.,__,.-'~'-.,__,.- STRUCTS -.,__,.-'~'-.,__,.-'~'-
    // <<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>>

    /// @dev Structure to store the DLPair information, such as:
    /// - binStep: The bin step of the DLPair
    /// - dlPair: The address of the DLPair
    /// - createdByOwner: Whether the pair was created by the owner of the factory
    /// - ignoredForRouting: Whether the pair is ignored for routing or not. An ignored pair will not be explored during routes finding
    struct DLPairInformation {
        uint16 binStep;
        IDLPair dlPair;
        bool createdByOwner;
        bool ignoredForRouting;
    }

    /// @dev Structure of the packed factory preset information for each binStep
    /// @param binStep The bin step in basis point, used to calculate log(1 + binStep)
    /// @param baseFactor The base factor, used to calculate the base fee, baseFee = baseFactor * binStep
    /// @param filterPeriod The period where the accumulator value is untouched, prevent spam
    /// @param decayPeriod The period where the accumulator value is halved
    /// @param reductionFactor The reduction factor, used to calculate the reduction of the accumulator
    /// @param variableFeeControl The variable fee control, used to control the variable fee, can be 0 to disable it
    /// @param protocolShare The share of the fees received by the protocol
    /// @param maxVolatilityAccumulated The max value of the volatility accumulated
    /// @param sampleLifetime The lifetime of an oracle's sample
    struct FactoryFeeParamsPreset {
        uint16 binStep;
        uint16 baseFactor;
        uint16 filterPeriod;
        uint16 decayPeriod;
        uint16 reductionFactor;
        uint24 variableFeeControl;
        uint16 protocolShare;
        uint24 maxVolatilityAccumulated;
        uint16 sampleLifetime;
    }

    /// @dev Structure of the packed factory preset information for each binStep
    /// @param binStep The bin step in basis point, used to calculate log(1 + binStep)
    /// @param baseFactor The base factor, used to calculate the base fee, baseFee = baseFactor * binStep
    /// @param filterPeriod The period where the accumulator value is untouched, prevent spam
    /// @param decayPeriod The period where the accumulator value is halved
    /// @param reductionFactor The reduction factor, used to calculate the reduction of the accumulator
    /// @param variableFeeControl The variable fee control, used to control the variable fee, can be 0 to disable it
    /// @param protocolShare The share of the fees received by the protocol
    /// @param maxVolatilityAccumulated The max value of the volatility accumulated
    struct FactoryFeeParams {
        uint16 binStep;
        uint16 baseFactor;
        uint16 filterPeriod;
        uint16 decayPeriod;
        uint16 reductionFactor;
        uint24 variableFeeControl;
        uint16 protocolShare;
        uint24 maxVolatilityAccumulated;
    }

    // <<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>>
    //    -'~'-.,__,.-'~'-.,__,.- EVENTS -.,__,.-'~'-.,__,.-'~'-
    // <<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>>

    event DLPairCreated(
        IERC20 indexed _tokenX,
        IERC20 indexed _tokenY,
        uint256 indexed binStep,
        IDLPair _dlPair,
        uint256 _pid
    );

    event FeeRecipientSet(address _oldRecipient, address _newRecipient);

    event FlashLoanFeeSet(uint256 _oldFlashLoanFee, uint256 _newFlashLoanFee);

    event FeeParametersSet(
        address indexed _sender,
        IDLPair indexed _dlPair,
        FactoryFeeParams _feeParams
    );

    event FactoryLockedStatusUpdated(bool _locked);

    event FactoryQuoteAssetRestrictedStatusUpdated(bool _restricted);

    event DLPairImplementationSet(address _oldDLPairImplementation, address _dlPairImplementation);

    event DLPairIgnoredStateChanged(IDLPair indexed _dlPair, bool _ignored);

    event PresetSet(
        uint256 indexed _binStep,
        FactoryFeeParamsPreset _preset
    );

    event PresetRemoved(uint256 indexed _binStep);

    event QuoteAssetAdded(IERC20 indexed _quoteAsset);

    event QuoteAssetRemoved(IERC20 indexed _quoteAsset);

    // <<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>>
    //  -'~'-.,__,.-'~'-.,__,.- CONSTANTS -.,__,.-'~'-.,__,.-'~'-
    // <<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>>

    function MAX_FEE() external pure returns (uint256);

    function MIN_BIN_STEP() external pure returns (uint256);

    function MAX_BIN_STEP() external pure returns (uint256);

    function MAX_PROTOCOL_SHARE() external pure returns (uint256);

    // <<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>>
    //     -'~'-.,__,.-'~'-.,__,.- VARS -.,__,.-'~'-.,__,.-'~'-
    // <<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>>

    function dlPairImplementation() external view returns (address);

    function feeRecipient() external view returns (address);

    function flashLoanFee() external view returns (uint256);

    function isCreationLocked() external view returns (bool);

    function isQuoteAssetRestricted() external view returns (bool);

    function allDLPairs(uint256 idx) external returns (IDLPair);

    function isQuoteAsset(IERC20 token) external view returns (bool);

    // <<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>>
    //      -'~'-.,__,.-'~'-.,__,.- CREATE -.,__,.-'~'-.,__,.-'~'-
    // <<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>>

    function createDLPair(
        IERC20 _tokenX,
        IERC20 _tokenY,
        uint24 _activeId,
        uint16 _binStep
    ) external returns (IDLPair pair_);

    function addQuoteAsset(IERC20 _quoteAsset) external;

    // <<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>>
    //      -'~'-.,__,.-'~'-.,__,.- DELETE -.,__,.-'~'-.,__,.-'~'-
    // <<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>>

    function removePreset(uint16 _binStep) external;

    function removeQuoteAsset(IERC20 _quoteAsset) external;

    // <<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>>
    //       -'~'-.,__,.-'~'-.,__,.- MISC -.,__,.-'~'-.,__,.-'~'-
    // <<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>>

    function forceDecayOnPair(IDLPair _dlPair) external;

    // <<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>>
    //      -'~'-.,__,.-'~'-.,__,.- GETTER -.,__,.-'~'-.,__,.-'~'-
    // <<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>>

    function getNumberOfQuoteAssets() external view returns (uint256);

    function getQuoteAsset(uint256 _index) external view returns (IERC20);

    function getNumberOfDLPairs() external view returns (uint256);

    function getDLPairInformation(
        IERC20 _tokenX,
        IERC20 _tokenY,
        uint256 _binStep
    ) external view returns (DLPairInformation memory);

    function getPreset(uint16 _binStep)
        external
        view
        returns (
            FactoryFeeParamsPreset memory preset_
        );

    function getAllBinStepsFromPresets() external view returns (uint256[] memory presetsBinStep_);

    function getAllDLPairs(IERC20 _tokenX, IERC20 _tokenY)
        external
        view
        returns (DLPairInformation[] memory dlPairsBinStep_);

    // <<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>>
    //      -'~'-.,__,.-'~'-.,__,.- SETTER -.,__,.-'~'-.,__,.-'~'-
    // <<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>>

    function setDLPairImplementation(address _dlPairImplementation) external;

    function setDLPairIgnored(
        IERC20 _tokenX,
        IERC20 _tokenY,
        uint256 _binStep,
        bool _ignored
    ) external;

    function setPreset(
        FactoryFeeParamsPreset calldata _preset
    ) external;

    function setFeesParametersOnPair(
        IERC20 _tokenX,
        IERC20 _tokenY,
        FactoryFeeParams calldata _feeParams
    ) external;

    function setFeeRecipient(address _feeRecipient) external;

    function setFlashLoanFee(uint256 _flashLoanFee) external;

    function setFactoryLockedState(bool _locked) external;

    function setFactoryQuoteAssetRestrictedState(bool _restricted) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";

/// @title Discretized Liquidity Flashloan Callback Interface
/// @author Bentoswap
/// @notice Required interface to interact with DL flashloans
interface IDLFlashLoanCallback {
    function DLFlashLoanCallback(
        address sender,
        IERC20 token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external returns (bytes32);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

/// @title Discretized Liquidity Constants Library
/// @author Bentoswap
/// @notice Set of constants for Discretized Liquidity contracts
library Constants {
    uint256 internal constant SCALE_OFFSET = 128;
    uint256 internal constant SCALE = 1 << SCALE_OFFSET; // type(uint128).max + 1

    uint256 internal constant PRECISION = 1e18;
    uint256 internal constant BASIS_POINT_MAX = 10_000;

    /// @dev The expected return after a successful flash loan
    bytes32 internal constant CALLBACK_SUCCESS = keccak256("ERC3156FlashBorrower.onFlashLoan");
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import {
    Math128x128__LogUnderflow,
    Math128x128__PowerUnderflow
} from "../DLErrors.sol";
import {BitMath} from "./BitMath.sol";
import {Constants} from "./Constants.sol";
import {Math512Bits} from "./Math512Bits.sol";

/// @title Discretized Liquidity Math Helper Library
/// @author Bentoswap
/// @notice Helper contract used for power and log calculations
library Math128x128 {
    using Math512Bits for uint256;
    using BitMath for uint256;

    uint256 constant LOG_SCALE_OFFSET = 127;
    uint256 constant LOG_SCALE = 1 << LOG_SCALE_OFFSET;
    uint256 constant LOG_SCALE_SQUARED = LOG_SCALE * LOG_SCALE;

    /// @notice Calculates the binary logarithm of x.
    ///
    /// @dev Based on the iterative approximation algorithm.
    /// https://en.wikipedia.org/wiki/Binary_logarithm#Iterative_approximation
    ///
    /// Requirements:
    /// - x must be greater than zero.
    ///
    /// Caveats:
    /// - The results are not perfectly accurate to the last decimal, due to the lossy precision of the iterative approximation
    /// Also because x is converted to an unsigned 129.127-binary fixed-point number during the operation to optimize the multiplication
    ///
    /// @param x The unsigned 128.128-binary fixed-point number for which to calculate the binary logarithm.
    /// @return result The binary logarithm as a signed 128.128-binary fixed-point number.
    function log2(uint256 x) internal pure returns (int256 result) {
        // Convert x to a unsigned 129.127-binary fixed-point number to optimize the multiplication.
        // If we use an offset of 128 bits, y would need 129 bits and y**2 would would overflow and we would have to
        // use mulDiv, by reducing x to 129.127-binary fixed-point number we assert that y will use 128 bits, and we
        // can use the regular multiplication

        if (x == 1) return -128;
        if (x == 0) revert Math128x128__LogUnderflow();

        x >>= 1;

        unchecked {
            // This works because log2(x) = -log2(1/x).
            int256 sign;
            if (x >= LOG_SCALE) {
                sign = 1;
            } else {
                sign = -1;
                // Do the fixed-point inversion inline to save gas
                x = LOG_SCALE_SQUARED / x;
            }

            // Calculate the integer part of the logarithm and add it to the result and finally calculate y = x * 2^(-n).
            uint256 n = (x >> LOG_SCALE_OFFSET).mostSignificantBit();

            // The integer part of the logarithm as a signed 129.127-binary fixed-point number. The operation can't overflow
            // because n is maximum 255, LOG_SCALE_OFFSET is 127 bits and sign is either 1 or -1.
            result = int256(n) << LOG_SCALE_OFFSET;

            // This is y = x * 2^(-n).
            uint256 y = x >> n;

            // If y = 1, the fractional part is zero.
            if (y != LOG_SCALE) {
                // Calculate the fractional part via the iterative approximation.
                // The "delta >>= 1" part is equivalent to "delta /= 2", but shifting bits is faster.
                for (int256 delta = int256(1 << (LOG_SCALE_OFFSET - 1)); delta > 0; delta >>= 1) {
                    y = (y * y) >> LOG_SCALE_OFFSET;

                    // Is y^2 > 2 and so in the range [2,4)?
                    if (y >= 1 << (LOG_SCALE_OFFSET + 1)) {
                        // Add the 2^(-m) factor to the logarithm.
                        result += delta;

                        // Corresponds to z/2 on Wikipedia.
                        y >>= 1;
                    }
                }
            }
            // Convert x back to unsigned 128.128-binary fixed-point number
            result = (result * sign) << 1;
        }
    }

    /// @notice Returns the value of x^y. It calculates `1 / x^abs(y)` if x is bigger than 2^128.
    /// At the end of the operations, we invert the result if needed.
    /// @param x The unsigned 128.128-binary fixed-point number for which to calculate the power
    /// @param y A relative number without any decimals, needs to be between ]2^20; 2^20[
    /// @return result The result of `x^y`
    function power(uint256 x, int256 y) internal pure returns (uint256 result) {
        bool invert;
        uint256 absY;

        if (y == 0) return Constants.SCALE;

        assembly {
            absY := y
            if slt(absY, 0) {
                absY := sub(0, absY)
                invert := iszero(invert)
            }
        }

        if (absY < 0x100000) {
            result = Constants.SCALE;
            assembly {
                let pow := x
                if gt(x, 0xffffffffffffffffffffffffffffffff) {
                    pow := div(not(0), pow)
                    invert := iszero(invert)
                }

                if and(absY, 0x1) {
                    result := shr(128, mul(result, pow))
                }
                pow := shr(128, mul(pow, pow))
                if and(absY, 0x2) {
                    result := shr(128, mul(result, pow))
                }
                pow := shr(128, mul(pow, pow))
                if and(absY, 0x4) {
                    result := shr(128, mul(result, pow))
                }
                pow := shr(128, mul(pow, pow))
                if and(absY, 0x8) {
                    result := shr(128, mul(result, pow))
                }
                pow := shr(128, mul(pow, pow))
                if and(absY, 0x10) {
                    result := shr(128, mul(result, pow))
                }
                pow := shr(128, mul(pow, pow))
                if and(absY, 0x20) {
                    result := shr(128, mul(result, pow))
                }
                pow := shr(128, mul(pow, pow))
                if and(absY, 0x40) {
                    result := shr(128, mul(result, pow))
                }
                pow := shr(128, mul(pow, pow))
                if and(absY, 0x80) {
                    result := shr(128, mul(result, pow))
                }
                pow := shr(128, mul(pow, pow))
                if and(absY, 0x100) {
                    result := shr(128, mul(result, pow))
                }
                pow := shr(128, mul(pow, pow))
                if and(absY, 0x200) {
                    result := shr(128, mul(result, pow))
                }
                pow := shr(128, mul(pow, pow))
                if and(absY, 0x400) {
                    result := shr(128, mul(result, pow))
                }
                pow := shr(128, mul(pow, pow))
                if and(absY, 0x800) {
                    result := shr(128, mul(result, pow))
                }
                pow := shr(128, mul(pow, pow))
                if and(absY, 0x1000) {
                    result := shr(128, mul(result, pow))
                }
                pow := shr(128, mul(pow, pow))
                if and(absY, 0x2000) {
                    result := shr(128, mul(result, pow))
                }
                pow := shr(128, mul(pow, pow))
                if and(absY, 0x4000) {
                    result := shr(128, mul(result, pow))
                }
                pow := shr(128, mul(pow, pow))
                if and(absY, 0x8000) {
                    result := shr(128, mul(result, pow))
                }
                pow := shr(128, mul(pow, pow))
                if and(absY, 0x10000) {
                    result := shr(128, mul(result, pow))
                }
                pow := shr(128, mul(pow, pow))
                if and(absY, 0x20000) {
                    result := shr(128, mul(result, pow))
                }
                pow := shr(128, mul(pow, pow))
                if and(absY, 0x40000) {
                    result := shr(128, mul(result, pow))
                }
                pow := shr(128, mul(pow, pow))
                if and(absY, 0x80000) {
                    result := shr(128, mul(result, pow))
                }
            }
        }

        // revert if y is too big or if x^y underflowed
        if (result == 0) revert Math128x128__PowerUnderflow(x, y);

        return invert ? type(uint256).max / result : result;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import {DLFactory__BinStepHasNoPreset} from "../../DLErrors.sol";
import {Decoder} from "../../libraries/Decoder.sol";
import {DLFactoryState} from "./DLFactoryState.sol";

/// @title Discretized Liquidity Factory Presets Handling
/// @author Bentoswap
/// @notice Contract used to manage factory bin step presets
abstract contract DLFactoryPresets is DLFactoryState {
    using Decoder for bytes32;

    constructor(address _feeRecipient, uint256 _flashLoanFee) DLFactoryState(_feeRecipient, _flashLoanFee) { }

    // <<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>>
    //     -'~'-.,__,.-'~'-.,__,.- INTERNAL -.,__,.-'~'-.,__,.-'~'-
    // <<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>>

    /// @notice Sets the preset parameters of a bin step
    /// @param _preset the FactoryFeeParamsPreset to pack and save
    function _setPreset(
        FactoryFeeParamsPreset calldata _preset
    ) internal {
        uint16 _binStep = _preset.binStep;
        bytes32 _packedFeeParameters = _getPackedFeeParameters(
            _binStep,
            _preset.baseFactor,
            _preset.filterPeriod,
            _preset.decayPeriod,
            _preset.reductionFactor,
            _preset.variableFeeControl,
            _preset.protocolShare,
            _preset.maxVolatilityAccumulated
        );

        // The last 16 bits are reserved for sampleLifetime
        bytes32 _presetPacked = bytes32(
            (uint256(_packedFeeParameters) & type(uint144).max) | (uint256(_preset.sampleLifetime) << 240)
        );

        _presets[_binStep] = _presetPacked;

        bytes32 _avPresets = _availablePresets;
        if (_avPresets.decode(1, _binStep) == 0) {
            // We add a 1 at bit `_binStep` as this binStep is now set
            _avPresets = bytes32(uint256(_avPresets) | (1 << _binStep));

            // Increase the number of preset by 1
            _avPresets = bytes32(uint256(_avPresets) + (1 << 248));

            // Save the changes
            _availablePresets = _avPresets;
        }

        emit PresetSet(
            _binStep,
            _preset
        );
    }

    /// @notice View function to return the different parameters of the preset
    /// @param preset_ The saved preset for the given binStep
    function _getPreset(uint16 _binStep)
        internal
        view
        returns (FactoryFeeParamsPreset memory preset_)
    {
        bytes32 _preset = _presets[_binStep];
        if (_preset == bytes32(0)) revert DLFactory__BinStepHasNoPreset(_binStep);

        uint256 _shift;

        // Safety check
        require(_binStep == _preset.decode(type(uint16).max, _shift));

        preset_ = FactoryFeeParamsPreset({
            binStep: _binStep,
            baseFactor: uint16(_preset.decode(type(uint16).max, _shift += 16)),
            filterPeriod: uint16(_preset.decode(type(uint16).max, _shift += 16)),
            decayPeriod: uint16(_preset.decode(type(uint16).max, _shift += 16)),
            reductionFactor: uint16(_preset.decode(type(uint16).max, _shift += 16)),
            variableFeeControl: uint24(_preset.decode(type(uint24).max, _shift += 16)),
            protocolShare: uint16(_preset.decode(type(uint16).max, _shift += 24)),
            maxVolatilityAccumulated: uint24(_preset.decode(type(uint24).max, _shift += 16)),
            sampleLifetime: uint16(_preset.decode(type(uint16).max, 240))
        });
    }

    /// @notice Remove the preset linked to a binStep
    /// @param _binStep The bin step to remove
    function _removePreset(uint16 _binStep) internal {
        if (_presets[_binStep] == bytes32(0)) revert DLFactory__BinStepHasNoPreset(_binStep);

        // Set the bit `_binStep` to 0
        bytes32 _avPresets = _availablePresets;

        _avPresets &= bytes32(type(uint256).max - (1 << _binStep));
        _avPresets = bytes32(uint256(_avPresets) - (1 << 248));

        // Save the changes
        _availablePresets = _avPresets;
        delete _presets[_binStep];

        emit PresetRemoved(_binStep);
    }

    /// @notice View function to return the list of available binStep with a preset
    /// @return presetsBinStep The list of binStep
    function _getAllBinStepsFromPresets() internal view returns (uint256[] memory presetsBinStep) {
        unchecked {
            bytes32 _avPresets = _availablePresets;
            uint256 _nbPresets = _avPresets.decode(type(uint8).max, 248);

            if (_nbPresets > 0) {
                presetsBinStep = new uint256[](_nbPresets);

                uint256 _index;
                for (uint256 i = MIN_BIN_STEP; i <= MAX_BIN_STEP; ++i) {
                    if (_avPresets.decode(1, i) == 1) {
                        presetsBinStep[_index] = i;
                        if (++_index == _nbPresets) break;
                    }
                }
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

/// @title Discretized Liquidity Safe Math Helper Library
/// @author Bentoswap
/// @notice Helper contract used for calculating absolute value safely
library SafeMath {
    /// @notice absSub, can't underflow or overflow
    /// @param x The first value
    /// @param y The second value
    /// @return The result of abs(x - y)
    function absSub(uint256 x, uint256 y) internal pure returns (uint256) {
        unchecked {
            return x > y ? x - y : y - x;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

/// @title Discretized Liquidity Pending Ownable Interface
/// @author Bentoswap
/// @notice Required interface of Pending Ownable contract used for DLFactory
interface IPendingOwnable {
    event PendingOwnerSet(address indexed pendingOwner);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function owner() external view returns (address);

    function pendingOwner() external view returns (address);

    function setPendingOwner(address pendingOwner) external;

    function revokePendingOwner() external;

    function becomeOwner() external;

    function renounceOwnership() external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

/// @title Discretized Liquidity Bit Math Library
/// @author Bentoswap
/// @notice Helper contract used for bit calculations
library BitMath {
    /// @notice Returns the closest non-zero bit of `integer` to the right (of left) of the `bit` bits that is not `bit`
    /// @param _integer The integer as a uint256
    /// @param _bit The bit index
    /// @param _rightSide Whether we're searching in the right side of the tree (true) or the left side (false)
    /// @return The index of the closest non-zero bit. If there is no closest bit, it returns max(uint256)
    function closestBit(
        uint256 _integer,
        uint8 _bit,
        bool _rightSide
    ) internal pure returns (uint256) {
        return _rightSide ? closestBitRight(_integer, _bit - 1) : closestBitLeft(_integer, _bit + 1);
    }

    /// @notice Returns the most (or least) significant bit of `_integer`
    /// @param _integer The integer
    /// @param _isMostSignificant Whether we want the most (true) or the least (false) significant bit
    /// @return The index of the most (or least) significant bit
    function significantBit(uint256 _integer, bool _isMostSignificant) internal pure returns (uint8) {
        return _isMostSignificant ? mostSignificantBit(_integer) : leastSignificantBit(_integer);
    }

    /// @notice Returns the index of the closest bit on the right of x that is non null
    /// @param x The value as a uint256
    /// @param bit The index of the bit to start searching at
    /// @return id The index of the closest non null bit on the right of x.
    /// If there is no closest bit, it returns max(uint256)
    function closestBitRight(uint256 x, uint8 bit) internal pure returns (uint256 id) {
        unchecked {
            uint256 _shift = 255 - bit;
            x <<= _shift;

            // can't overflow as it's non-zero and we shifted it by `_shift`
            return (x == 0) ? type(uint256).max : mostSignificantBit(x) - _shift;
        }
    }

    /// @notice Returns the index of the closest bit on the left of x that is non null
    /// @param x The value as a uint256
    /// @param bit The index of the bit to start searching at
    /// @return id The index of the closest non null bit on the left of x.
    /// If there is no closest bit, it returns max(uint256)
    function closestBitLeft(uint256 x, uint8 bit) internal pure returns (uint256 id) {
        unchecked {
            x >>= bit;

            return (x == 0) ? type(uint256).max : leastSignificantBit(x) + bit;
        }
    }

    /// @notice Returns the index of the most significant bit of x
    /// @param x The value as a uint256
    /// @return msb The index of the most significant bit of x
    function mostSignificantBit(uint256 x) internal pure returns (uint8 msb) {
        unchecked {
            if (x >= 1 << 128) {
                x >>= 128;
                msb = 128;
            }
            if (x >= 1 << 64) {
                x >>= 64;
                msb += 64;
            }
            if (x >= 1 << 32) {
                x >>= 32;
                msb += 32;
            }
            if (x >= 1 << 16) {
                x >>= 16;
                msb += 16;
            }
            if (x >= 1 << 8) {
                x >>= 8;
                msb += 8;
            }
            if (x >= 1 << 4) {
                x >>= 4;
                msb += 4;
            }
            if (x >= 1 << 2) {
                x >>= 2;
                msb += 2;
            }
            if (x >= 1 << 1) {
                msb += 1;
            }
        }
    }

    /// @notice Returns the index of the least significant bit of x
    /// @param x The value as a uint256
    /// @return lsb The index of the least significant bit of x
    function leastSignificantBit(uint256 x) internal pure returns (uint8 lsb) {
        unchecked {
            if (x << 128 != 0) {
                x <<= 128;
                lsb = 128;
            }
            if (x << 64 != 0) {
                x <<= 64;
                lsb += 64;
            }
            if (x << 32 != 0) {
                x <<= 32;
                lsb += 32;
            }
            if (x << 16 != 0) {
                x <<= 16;
                lsb += 16;
            }
            if (x << 8 != 0) {
                x <<= 8;
                lsb += 8;
            }
            if (x << 4 != 0) {
                x <<= 4;
                lsb += 4;
            }
            if (x << 2 != 0) {
                x <<= 2;
                lsb += 2;
            }
            if (x << 1 != 0) {
                lsb += 1;
            }

            return 255 - lsb;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import {
    Math512Bits__MulDivOverflow,
    Math512Bits__MulShiftOverflow,
    Math512Bits__OffsetOverflows
} from "../DLErrors.sol";
import {BitMath} from "./BitMath.sol";

/// @title Discretized Liquidity Math Helper Library
/// @author Bentoswap
/// @notice Helper contract used for full precision calculations
library Math512Bits {
    using BitMath for uint256;

    /// @notice Calculates floor(x*y÷denominator) with full precision
    /// The result will be rounded down
    ///
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
    ///
    /// Requirements:
    /// - The denominator cannot be zero
    /// - The result must fit within uint256
    ///
    /// Caveats:
    /// - This function does not work with fixed-point numbers
    ///
    /// @param x The multiplicand as an uint256
    /// @param y The multiplier as an uint256
    /// @param denominator The divisor as an uint256
    /// @return result The result as an uint256
    function mulDivRoundDown(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        (uint256 prod0, uint256 prod1) = _getMulProds(x, y);

        return _getEndOfDivRoundDown(x, y, denominator, prod0, prod1);
    }

    /// @notice Calculates x * y >> offset with full precision
    /// The result will be rounded down
    ///
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
    ///
    /// Requirements:
    /// - The offset needs to be strictly lower than 256
    /// - The result must fit within uint256
    ///
    /// Caveats:
    /// - This function does not work with fixed-point numbers
    ///
    /// @param x The multiplicand as an uint256
    /// @param y The multiplier as an uint256
    /// @param offset The offset as an uint256, can't be greater than 256
    /// @return result The result as an uint256
    function mulShiftRoundDown(
        uint256 x,
        uint256 y,
        uint256 offset
    ) internal pure returns (uint256 result) {
        if (offset > 255) revert Math512Bits__OffsetOverflows(offset);

        (uint256 prod0, uint256 prod1) = _getMulProds(x, y);

        if (prod0 != 0) result = prod0 >> offset;
        if (prod1 != 0) {
            // Make sure the result is less than 2^256.
            if (prod1 >= 1 << offset) revert Math512Bits__MulShiftOverflow(prod1, offset);

            unchecked {
                result += prod1 << (256 - offset);
            }
        }
    }

    /// @notice Calculates x * y >> offset with full precision
    /// The result will be rounded up
    ///
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
    ///
    /// Requirements:
    /// - The offset needs to be strictly lower than 256
    /// - The result must fit within uint256
    ///
    /// Caveats:
    /// - This function does not work with fixed-point numbers
    ///
    /// @param x The multiplicand as an uint256
    /// @param y The multiplier as an uint256
    /// @param offset The offset as an uint256, can't be greater than 256
    /// @return result The result as an uint256
    function mulShiftRoundUp(
        uint256 x,
        uint256 y,
        uint256 offset
    ) internal pure returns (uint256 result) {
        unchecked {
            result = mulShiftRoundDown(x, y, offset);
            if (mulmod(x, y, 1 << offset) != 0) result += 1;
        }
    }

    /// @notice Calculates x << offset / y with full precision
    /// The result will be rounded down
    ///
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
    ///
    /// Requirements:
    /// - The offset needs to be strictly lower than 256
    /// - The result must fit within uint256
    ///
    /// Caveats:
    /// - This function does not work with fixed-point numbers
    ///
    /// @param x The multiplicand as an uint256
    /// @param offset The number of bit to shift x as an uint256
    /// @param denominator The divisor as an uint256
    /// @return result The result as an uint256
    function shiftDivRoundDown(
        uint256 x,
        uint256 offset,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        if (offset > 255) revert Math512Bits__OffsetOverflows(offset);
        uint256 prod0;
        uint256 prod1;

        prod0 = x << offset; // Least significant 256 bits of the product
        unchecked {
            prod1 = x >> (256 - offset); // Most significant 256 bits of the product
        }

        return _getEndOfDivRoundDown(x, 1 << offset, denominator, prod0, prod1);
    }

    /// @notice Calculates x << offset / y with full precision
    /// The result will be rounded up
    ///
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
    ///
    /// Requirements:
    /// - The offset needs to be strictly lower than 256
    /// - The result must fit within uint256
    ///
    /// Caveats:
    /// - This function does not work with fixed-point numbers
    ///
    /// @param x The multiplicand as an uint256
    /// @param offset The number of bit to shift x as an uint256
    /// @param denominator The divisor as an uint256
    /// @return result The result as an uint256
    function shiftDivRoundUp(
        uint256 x,
        uint256 offset,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        result = shiftDivRoundDown(x, offset, denominator);
        unchecked {
            if (mulmod(x, 1 << offset, denominator) != 0) result += 1;
        }
    }

    /// @notice Helper function to return the result of `x * y` as 2 uint256
    /// @param x The multiplicand as an uint256
    /// @param y The multiplier as an uint256
    /// @return prod0 The least significant 256 bits of the product
    /// @return prod1 The most significant 256 bits of the product
    function _getMulProds(uint256 x, uint256 y) private pure returns (uint256 prod0, uint256 prod1) {
        // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
        // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
        // variables such that product = prod1 * 2^256 + prod0.
        assembly {
            let mm := mulmod(x, y, not(0))
            prod0 := mul(x, y)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }
    }

    /// @notice Helper function to return the result of `x * y / denominator` with full precision
    /// @param x The multiplicand as an uint256
    /// @param y The multiplier as an uint256
    /// @param denominator The divisor as an uint256
    /// @param prod0 The least significant 256 bits of the product
    /// @param prod1 The most significant 256 bits of the product
    /// @return result The result as an uint256
    function _getEndOfDivRoundDown(
        uint256 x,
        uint256 y,
        uint256 denominator,
        uint256 prod0,
        uint256 prod1
    ) private pure returns (uint256 result) {
        // Handle non-overflow cases, 256 by 256 division
        if (prod1 == 0) {
            unchecked {
                result = prod0 / denominator;
            }
        } else {
            // Make sure the result is less than 2^256. Also prevents denominator == 0
            if (prod1 >= denominator) revert Math512Bits__MulDivOverflow(prod1, denominator);

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1
            // See https://cs.stackexchange.com/q/138556/92363
            unchecked {
                // Does not overflow because the denominator cannot be zero at this stage in the function
                uint256 lpotdod = denominator & (~denominator + 1);
                assembly {
                    // Divide denominator by lpotdod.
                    denominator := div(denominator, lpotdod)

                    // Divide [prod1 prod0] by lpotdod.
                    prod0 := div(prod0, lpotdod)

                    // Flip lpotdod such that it is 2^256 / lpotdod. If lpotdod is zero, then it becomes one
                    lpotdod := add(div(sub(0, lpotdod), lpotdod), 1)
                }

                // Shift in bits from prod1 into prod0
                prod0 |= prod1 * lpotdod;

                // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
                // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
                // four bits. That is, denominator * inv = 1 mod 2^4
                uint256 inverse = (3 * denominator) ^ 2;

                // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
                // in modular arithmetic, doubling the correct bits in each step
                inverse *= 2 - denominator * inverse; // inverse mod 2^8
                inverse *= 2 - denominator * inverse; // inverse mod 2^16
                inverse *= 2 - denominator * inverse; // inverse mod 2^32
                inverse *= 2 - denominator * inverse; // inverse mod 2^64
                inverse *= 2 - denominator * inverse; // inverse mod 2^128
                inverse *= 2 - denominator * inverse; // inverse mod 2^256

                // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
                // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
                // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
                // is no longer required.
                result = prod0 * inverse;
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";
import {EnumerableSet} from "openzeppelin/utils/structs/EnumerableSet.sol";

import {
    DLFactory__AddressZero,
    DLFactory__BinStepRequirementsBreached,
    DLFactory__DecreasingPeriods,
    DLFactory__DLPairSafetyCheckFailed,
    DLFactory__FactoryLockIsAlreadyInTheSameState,
    DLFactory__FactoryQuoteAssetRestrictedIsAlreadyInTheSameState,
    DLFactory__FeesAboveMax,
    DLFactory__FlashLoanFeeAboveMax,
    DLFactory__ProtocolShareOverflows,
    DLFactory__ReductionFactorOverflows,
    DLFactory__SameFlashLoanFee,
    DLFactory__SameFeeRecipient,
    DLFactory__SameImplementation
} from "../../DLErrors.sol";
import {BinHelper} from "../../libraries/BinHelper.sol";
import {Constants} from "../../libraries/Constants.sol";
import {PendingOwnable} from "../../libraries/PendingOwnable.sol";
import {IDLFactory} from "../../interfaces/IDLFactory.sol";
import {IDLPair} from "../../interfaces/IDLPair.sol";

/// @title Discretized Liquidity Factory State
/// @author Bentoswap
/// @notice Contract used to hold the contract state and shared functions that read/write state
abstract contract DLFactoryState is PendingOwnable, IDLFactory {
    using EnumerableSet for EnumerableSet.AddressSet;

    // <<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>>
    //    -'~'-.,__,.-'~'-.,__,.- CONSTANTS -.,__,.-'~'-.,__,.-'~'-
    // <<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>>

    uint256 public constant override MAX_FEE = 0.1e18; // 10%

    uint256 public constant override MIN_BIN_STEP = 1; // 0.01%
    uint256 public constant override MAX_BIN_STEP = 100; // 1%, can't be greater than 247 for indexing reasons

    uint256 public constant override MAX_PROTOCOL_SHARE = 2_500; // 25%

    // <<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>>
    //       -'~'-.,__,.-'~'-.,__,.- VARS -.,__,.-'~'-.,__,.-'~'-
    // <<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>>

    // The address of the DLPair implementation that will be cloned to create new DLPairs
    address public override dlPairImplementation;

    // The address to receive all protocol earned fees
    address public override feeRecipient;

    /// @notice Whether the createDLPair function is locked and can be called only by owner (true) or by anyone (false)
    bool public override isCreationLocked;

    /// @notice Whether the Quote asset is restricted to the allowed quote assets
    bool public override isQuoteAssetRestricted;

    // The fee amount for providing flash loans, represented as basis points
    uint256 public override flashLoanFee;

    // Every DLPair that was deployed by this factory 
    IDLPair[] public override allDLPairs;

    // Whether a preset was set or not, if the bit at `index` is 1, it means that the binStep `index` was set
    // The max binStep set is 247. We use this method instead of an array to keep it ordered and to reduce gas
    bytes32 internal _availablePresets;

    // Array of quote assets that can be used when creating a DL Pair
    //  when isQuoteAssetRestricted is true
    EnumerableSet.AddressSet internal _allowedQuoteAssets;

    /// @dev Mapping from a (tokenA, tokenB, binStep) to a DLPair. The tokens are ordered to save gas, but they can be
    /// in the reverse order in the actual pair. Always query one of the 2 tokens of the pair to assert the order of the 2 tokens
    mapping(IERC20 => mapping(IERC20 => mapping(uint256 => DLPairInformation))) internal _dlPairsInfo;

    // The parameters presets
    mapping(uint256 => bytes32) internal _presets;

    // Whether a DLPair was created with a bin step, if the bit at `index` is 1, it means that the DLPair with binStep `index` exists
    // The max binStep set is 247. We use this method instead of an array to keep it ordered and to reduce gas
    mapping(IERC20 => mapping(IERC20 => bytes32)) internal _availableDLPairBinSteps;

    /// @notice Constructor
    /// @param _feeRecipient The address of the fee recipient
    /// @param _flashLoanFee The value of the fee for flash loan
    constructor(address _feeRecipient, uint256 _flashLoanFee) {
        if (_flashLoanFee > MAX_FEE) revert DLFactory__FlashLoanFeeAboveMax(_flashLoanFee, MAX_FEE);
        isCreationLocked = true;
        isQuoteAssetRestricted = true;

        _setFeeRecipient(_feeRecipient);

        flashLoanFee = _flashLoanFee;
        emit FlashLoanFeeSet(0, _flashLoanFee);
    }

    // <<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>>
    //     -'~'-.,__,.-'~'-.,__,.- INTERNAL -.,__,.-'~'-.,__,.-'~'-
    // <<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>>

    /// @notice Internal function to set the recipient of the fee
    /// @param _feeRecipient The address of the recipient
    function _setFeeRecipient(address _feeRecipient) internal {
        if (_feeRecipient == address(0)) revert DLFactory__AddressZero();

        address _oldFeeRecipient = feeRecipient;
        if (_oldFeeRecipient == _feeRecipient) revert DLFactory__SameFeeRecipient(_feeRecipient);

        feeRecipient = _feeRecipient;
        emit FeeRecipientSet(_oldFeeRecipient, _feeRecipient);
    }

    /// @notice Function to set the creation restriction of the Factory
    /// @param _locked If the creation is restricted (true) or not (false)
    function _setFactoryLockedState(bool _locked) internal {
        if (isCreationLocked == _locked) revert DLFactory__FactoryLockIsAlreadyInTheSameState();
        isCreationLocked = _locked;
        emit FactoryLockedStatusUpdated(_locked);
    }

    /// @notice Function to set the creation restriction of the Factory
    /// @param _restricted If the creation is restricted (true) or not (false)
    function _setFactoryQuoteAssetRestrictedState(bool _restricted) internal {
        if (isQuoteAssetRestricted == _restricted) revert DLFactory__FactoryQuoteAssetRestrictedIsAlreadyInTheSameState();
        isQuoteAssetRestricted = _restricted;
        emit FactoryQuoteAssetRestrictedStatusUpdated(_restricted);
    }

    /// @notice Function to set the flash loan fee
    /// @param _flashLoanFee The value of the fee for flash loan
    function _setFlashLoanFee(uint256 _flashLoanFee) internal {
        uint256 _oldFlashLoanFee = flashLoanFee;

        if (_oldFlashLoanFee == _flashLoanFee) revert DLFactory__SameFlashLoanFee(_flashLoanFee);
        if (_flashLoanFee > MAX_FEE) revert DLFactory__FlashLoanFeeAboveMax(_flashLoanFee, MAX_FEE);

        flashLoanFee = _flashLoanFee;
        emit FlashLoanFeeSet(_oldFlashLoanFee, _flashLoanFee);
    }

    /// @notice Set the DLPair implementation address
    /// @dev Needs to be called by the owner
    /// @param _DLPairImplementation The address of the implementation
    function _setDLPairImplementation(address _DLPairImplementation) internal {
        if (IDLPair(_DLPairImplementation).factory() != this)
            revert DLFactory__DLPairSafetyCheckFailed(_DLPairImplementation);

        address _oldDLPairImplementation = dlPairImplementation;
        if (_oldDLPairImplementation == _DLPairImplementation)
            revert DLFactory__SameImplementation(_DLPairImplementation);

        dlPairImplementation = _DLPairImplementation;

        emit DLPairImplementationSet(_oldDLPairImplementation, _DLPairImplementation);
    }

    /// @notice Internal function to set the fee parameter of a DLPair
    /// @param _binStep The bin step in basis point, used to calculate log(1 + binStep)
    /// @param _baseFactor The base factor, used to calculate the base fee, baseFee = baseFactor * binStep
    /// @param _filterPeriod The period where the accumulator value is untouched, prevent spam
    /// @param _decayPeriod The period where the accumulator value is halved
    /// @param _reductionFactor The reduction factor, used to calculate the reduction of the accumulator
    /// @param _variableFeeControl The variable fee control, used to control the variable fee, can be 0 to disable it
    /// @param _protocolShare The share of the fees received by the protocol
    /// @param _maxVolatilityAccumulated The max value of volatility accumulated
    function _getPackedFeeParameters(
        uint16 _binStep,
        uint16 _baseFactor,
        uint16 _filterPeriod,
        uint16 _decayPeriod,
        uint16 _reductionFactor,
        uint24 _variableFeeControl,
        uint16 _protocolShare,
        uint24 _maxVolatilityAccumulated
    ) internal pure returns (bytes32) {
        if (_binStep < MIN_BIN_STEP || _binStep > MAX_BIN_STEP)
            revert DLFactory__BinStepRequirementsBreached(MIN_BIN_STEP, _binStep, MAX_BIN_STEP);

        if (_filterPeriod >= _decayPeriod) revert DLFactory__DecreasingPeriods(_filterPeriod, _decayPeriod);

        if (_reductionFactor > Constants.BASIS_POINT_MAX)
            revert DLFactory__ReductionFactorOverflows(_reductionFactor, Constants.BASIS_POINT_MAX);

        if (_protocolShare > MAX_PROTOCOL_SHARE)
            revert DLFactory__ProtocolShareOverflows(_protocolShare, MAX_PROTOCOL_SHARE);

        {
            uint256 _baseFee = (uint256(_baseFactor) * _binStep) * 1e10;

            // Can't overflow as the max value is `max(uint24) * (max(uint24) * max(uint16)) ** 2 < max(uint104)`
            // It returns 18 decimals as:
            // decimals(variableFeeControl * (volatilityAccumulated * binStep)**2 / 100) = 4 + (4 + 4) * 2 - 2 = 18
            uint256 _prod = uint256(_maxVolatilityAccumulated) * _binStep;
            uint256 _maxVariableFee = (_prod * _prod * _variableFeeControl) / 100;

            if (_baseFee + _maxVariableFee > MAX_FEE)
                revert DLFactory__FeesAboveMax(_baseFee + _maxVariableFee, MAX_FEE);
        }

        /// @dev It's very important that the sum of the sizes of those values is exactly 256 bits
        /// here, (112 + 24) + 16 + 24 + 16 + 16 + 16 + 16 + 16 = 256
        return
            bytes32(
                abi.encodePacked(
                    uint136(_maxVolatilityAccumulated), // The first 112 bits are reserved for the dynamic parameters
                    _protocolShare,
                    _variableFeeControl,
                    _reductionFactor,
                    _decayPeriod,
                    _filterPeriod,
                    _baseFactor,
                    _binStep
                )
            );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import {
    PendingOwnable__AddressZero,
    PendingOwnable__NoPendingOwner,
    PendingOwnable__NotOwner,
    PendingOwnable__NotPendingOwner,
    PendingOwnable__PendingOwnerAlreadySet
} from "../DLErrors.sol";
import {IPendingOwnable} from "../interfaces/IPendingOwnable.sol";

/// @title Pending Ownable
/// @author Bentoswap
/// @notice Contract module which provides a basic access control mechanism, where
/// there is an account (an owner) that can be granted exclusive access to
/// specific functions. The ownership of this contract is transferred using the
/// push and pull pattern, the current owner set a `pendingOwner` using
/// {setPendingOwner} and that address can then call {becomeOwner} to become the
/// owner of that contract. The main logic and comments comes from OpenZeppelin's
/// Ownable contract.
///
/// By default, the owner account will be the one that deploys the contract. This
/// can later be changed with {setPendingOwner} and {becomeOwner}.
///
/// This module is used through inheritance. It will make available the modifier
/// `onlyOwner`, which can be applied to your functions to restrict their use to
/// the owner
contract PendingOwnable is IPendingOwnable {
    address private _owner;
    address private _pendingOwner;

    /// @notice Throws if called by any account other than the owner.
    modifier onlyOwner() {
        if (msg.sender != _owner) revert PendingOwnable__NotOwner();
        _;
    }

    /// @notice Throws if called by any account other than the pending owner.
    modifier onlyPendingOwner() {
        if (msg.sender != _pendingOwner || msg.sender == address(0)) revert PendingOwnable__NotPendingOwner();
        _;
    }

    /// @notice Initializes the contract setting the deployer as the initial owner
    constructor() {
        _transferOwnership(msg.sender);
    }

    /// @notice Returns the address of the current owner
    /// @return The address of the current owner
    function owner() public view override returns (address) {
        return _owner;
    }

    /// @notice Returns the address of the current pending owner
    /// @return The address of the current pending owner
    function pendingOwner() public view override returns (address) {
        return _pendingOwner;
    }

    /// @notice Sets the pending owner address. This address will be able to become
    /// the owner of this contract by calling {becomeOwner}
    function setPendingOwner(address pendingOwner_) public override onlyOwner {
        if (pendingOwner_ == address(0)) revert PendingOwnable__AddressZero();
        if (_pendingOwner != address(0)) revert PendingOwnable__PendingOwnerAlreadySet();
        _setPendingOwner(pendingOwner_);
    }

    /// @notice Revoke the pending owner address. This address will not be able to
    /// call {becomeOwner} to become the owner anymore.
    /// Can only be called by the owner
    function revokePendingOwner() public override onlyOwner {
        if (_pendingOwner == address(0)) revert PendingOwnable__NoPendingOwner();
        _setPendingOwner(address(0));
    }

    /// @notice Transfers the ownership to the new owner (`pendingOwner).
    /// Can only be called by the pending owner
    function becomeOwner() public override onlyPendingOwner {
        _transferOwnership(msg.sender);
    }

    /// @notice Leaves the contract without owner. It will not be possible to call
    /// `onlyOwner` functions anymore. Can only be called by the current owner.
    ///
    /// NOTE: Renouncing ownership will leave the contract without an owner,
    /// thereby removing any functionality that is only available to the owner.
    function renounceOwnership() public override onlyOwner {
        _transferOwnership(address(0));
    }

    /// @notice Transfers ownership of the contract to a new account (`newOwner`).
    /// Internal function without access restriction.
    /// @param _newOwner The address of the new owner
    function _transferOwnership(address _newOwner) internal virtual {
        address _oldOwner = _owner;
        _owner = _newOwner;
        _pendingOwner = address(0);
        emit OwnershipTransferred(_oldOwner, _newOwner);
    }

    /// @notice Push the new owner, it needs to be pulled to be effective.
    /// Internal function without access restriction.
    /// @param pendingOwner_ The address of the new pending owner
    function _setPendingOwner(address pendingOwner_) internal virtual {
        _pendingOwner = pendingOwner_;
        emit PendingOwnerSet(pendingOwner_);
    }
}