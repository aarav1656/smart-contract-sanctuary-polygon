// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import {ISapphirePool} from "./ISapphirePool.sol";

import {SafeERC20} from "../../lib/SafeERC20.sol";
import {Adminable} from "../../lib/Adminable.sol";
import {Address} from "../../lib/Address.sol";
import {Math} from "../../lib/Math.sol";
import {IERC20Metadata} from "../../token/IERC20Metadata.sol";
import {InitializableBaseERC20} from "../../token/InitializableBaseERC20.sol";

/**
 * @notice A special AMM-like contract where swapping is permitted only by an approved
 * Sapphire Core. A portion of the interest made from the loans by the Cores is deposited
 * into this contract, and shared among the LPs.
 */
contract SapphirePool is ISapphirePool, Adminable, InitializableBaseERC20 {

    /* ========== Libraries ========== */

    using Address for address;

    /* ========== Structs ========== */

    struct AssetUtilization {
        uint256 amountUsed;
        uint256 limit;
    }

    // Used in _getWithdrawAmounts to get around the stack too deep error.
    struct WithdrawAmountInfo {
        uint256 poolValue;
        uint256 totalSupply;
        uint256 withdrawAmt;
        uint256 scaledWithdrawAmt;
        uint256 userDeposit;
        uint256 assetUtilization;
        uint256 scaledAssetUtilization;
    }

    /* ========== Variables ========== */

    IERC20Metadata public credsToken;

    /**
     * @notice Determines the amount of creds the core can swap in. The amounts are stored in
     * 18 decimals.
     */
    mapping (address => AssetUtilization) public override coreSwapUtilization;

    /**
     * @notice Determines the amount of tokens that can be deposited by
     * liquidity providers. The amounts are stored in the asset's native decimals.
     */
    mapping (address => AssetUtilization) public override assetDepositUtilization;

    /**
     * @notice Determines the amount of tokens deposited by liquidity providers. Stored in 18
     * decimals.
     */
    mapping (address => uint256) public override deposits;

    /**
     * @dev Stores the assets that have been historically allowed to be deposited.
     */
    address[] internal _knownDepositAssets;

    /**
     * @dev Stores the cores that have historically been approved to swap in assets.
     */
    address[] internal _knownCores;

    mapping (address => uint8) internal _tokenDecimals;

    /* ========== Events ========== */

    event CoreSwapLimitSet(address _core, uint256 _limit);

    event DepositLimitSet(address _asset, uint256 _limit);

    event TokensDeposited(
        address indexed _user,
        address indexed _token,
        uint256 _depositAmount,
        uint256 _lpTokensAmount
    );

    event TokensWithdrawn(
        address indexed _user,
        address indexed _token,
        uint256 _credsAmount,
        uint256 _withdrawAmount
    );

    event TokensSwapped(
        address indexed _core,
        address _tokenIn,
        address indexed _tokenOut,
        uint256 _amountIn,
        uint256 _amountOut,
        address indexed _receiver
    );

    /* ========== Modifiers ========== */

    modifier checkKnownToken (address _token) {
        require(
            _isKnownToken(_token),
            "SapphirePool: unknown token"
        );
        _;
    }

    /* ========== Restricted functions ========== */

    function init(
        string memory _name,
        string memory _symbol,
        address _credsToken
    )
        external
        onlyAdmin
        initializer
    {
        _init(_name, _symbol, 18);

        require (
            _credsToken.isContract(),
            "SapphirePool: Creds address is not a contract"
        );
        credsToken = IERC20Metadata(_credsToken);
    }

    /**
     * @notice Sets the limit for how many Creds can be swapped in by a Core.
     * The sum of the core limits cannot be greater than the sum of the deposit limits.
     */
    function setCoreSwapLimit(
        address _coreAddress,
        uint256 _limit
    )
        external
        override
        onlyAdmin
    {
        (
            uint256 sumOfDepositLimits,
            uint256 sumOfCoreLimits,
            bool isCoreKnown
        ) = _getSumOfLimits(_coreAddress, _coreAddress, address(0));

        require(
            sumOfCoreLimits + _limit <= sumOfDepositLimits,
            "SapphirePool: swap limit is greater than the sum of the deposit limits"
        );

        require(
            sumOfCoreLimits + _limit > 0,
            "SapphirePool: at least one asset must have a positive swap limit"
        );

        if (!isCoreKnown) {
            _knownCores.push(_coreAddress);
        }

        coreSwapUtilization[_coreAddress].limit = _limit;

        emit CoreSwapLimitSet(_coreAddress, _limit);
    }

    /**
     * @notice Sets the limit for the deposit token. If the limit is > 0, the token is added to
     * the list of the known deposit assets. These assets also become available for being
     * swapped by the Cores, unless their limit is set to 0 later on.
     * The sum of the deposit limits cannot be smaller than the sum of the core limits.
     * @param _tokenAddress The address of the deposit token.
     * @param _limit The limit for the deposit token, in its own native decimals.
     */
    function setDepositLimit(
        address _tokenAddress,
        uint256 _limit
    )
        external
        override
        onlyAdmin
    {
        bool isKnownToken = _isKnownToken(_tokenAddress);

        require(
            _limit > 0 || isKnownToken,
            "SapphirePool: cannot set the limit of an unknown asset to 0"
        );

        (
            uint256 sumOfDepositLimits,
            uint256 sumOfCoreLimits,
        ) = _getSumOfLimits(address(0), address(0), _tokenAddress);

        // Add the token to the known assets array if limit is > 0
        if (_limit > 0 && !isKnownToken) {
            _knownDepositAssets.push(_tokenAddress);

            // Save token decimals to later compute the token scalar
            _tokenDecimals[_tokenAddress] = IERC20Metadata(_tokenAddress).decimals();
        }

        uint256 scaledNewLimit = _getScaledAmount(
            _limit,
            _tokenDecimals[_tokenAddress],
            _decimals
        );

        // The new sum of deposit limits cannot be zero, otherwise the pool will become
        // unusable (deposits will be disabled).
        require(
            sumOfDepositLimits + scaledNewLimit > 0,
            "SapphirePool: at least 1 deposit asset must have a positive limit"
        );

        require(
            sumOfDepositLimits + scaledNewLimit >= sumOfCoreLimits,
            "SapphirePool: sum of deposit limits smaller than the sum of the swap limits"
        );

        assetDepositUtilization[_tokenAddress].limit = _limit;

        emit DepositLimitSet(_tokenAddress, _limit);
    }

    /**
     * @notice Performs a swap between the specified tokens, for the given amount. Assumes
     * a 1:1 conversion. Only approved cores have permission to swap.
     */
    function swap(
        address _tokenIn,
        address _tokenOut,
        uint256 _amountIn,
        address _receiver
    )
        external
        override
    {
        uint256 amountOut;

        require(
            coreSwapUtilization[msg.sender].limit > 0,
            "SapphirePool: caller should be a core with a positive swap limit"
        );

        require(
            _tokenIn != _tokenOut && (
                _tokenIn == address(credsToken) ||
                _tokenOut == address(credsToken)
            ),
            "SapphirePool: invalid swap tokens"
        );

        if (_tokenIn == address(credsToken)) {
            amountOut = _swapCredsForStables(
                _tokenOut,
                _amountIn,
                _receiver
            );
        } else {
            amountOut = _swapStablesForCreds(
                _tokenIn,
                _amountIn,
                _receiver
            );
        }

        emit TokensSwapped(
            msg.sender,
            _tokenIn,
            _tokenOut,
            _amountIn,
            amountOut,
            _receiver
        );
    }

    /* ========== Public functions ========== */

    /**
     * @notice Deposits the given amount of tokens into the pool.
     * The token must have a deposit limit > 0.
     */
    function deposit(
        address _token,
        uint256 _amount
    )
        external
        override
    {
        AssetUtilization storage utilization = assetDepositUtilization[_token];

        require(
            utilization.amountUsed + _amount <= utilization.limit,
            "SapphirePool: cannot deposit more than the limit"
        );

        uint256 scaledAmount = _getScaledAmount(
            _amount,
            _tokenDecimals[_token],
            _decimals
        );
        uint256 poolValue = getPoolValue();

        uint256 lpToMint;
        if (poolValue > 0) {
            lpToMint = Math.roundUpDiv(
                scaledAmount * totalSupply() / 10 ** _decimals,
                poolValue
            );
        } else {
            lpToMint = scaledAmount;
        }

        utilization.amountUsed += _amount;
        deposits[msg.sender] += scaledAmount;

        _mint(msg.sender, lpToMint);

        SafeERC20.safeTransferFrom(
            IERC20Metadata(_token),
            msg.sender,
            address(this),
            _amount
        );

        emit TokensDeposited(
            msg.sender,
            _token,
            _amount,
            lpToMint
        );
    }

    /**
     * @notice Exchanges the given amount of Creds for the equivalent amount of the given token,
     * plus the proportional rewards. The Creds exchanged are burned.
     * @param _lpAmount The amount of Creds to exchange.
     * @param _withdrawToken The token to exchange for.
     */
    function withdraw(
        uint256 _lpAmount,
        address _withdrawToken
    )
        external
        override
        checkKnownToken(_withdrawToken)
    {
        (
            uint256 assetUtilizationReduceAmt,
            uint256 userDepositReduceAmt,
            uint256 scaledWithdrawAmt
        ) = _getWithdrawAmounts(_lpAmount, _withdrawToken);

        assetDepositUtilization[_withdrawToken].amountUsed -= assetUtilizationReduceAmt;
        deposits[msg.sender] -= userDepositReduceAmt;

        _burn(msg.sender, _lpAmount);

        SafeERC20.safeTransfer(
            IERC20Metadata(_withdrawToken),
            msg.sender,
            scaledWithdrawAmt
        );

        emit TokensWithdrawn(
            msg.sender,
            _withdrawToken,
            _lpAmount,
            scaledWithdrawAmt
        );
    }

    /* ========== View functions ========== */

    /**
     * @notice Returns the rewards accumulated into the pool
     */
    function accumulatedRewardAmount()
        external
        override
        view
        returns (uint256)
    {
        uint256 poolValue = getPoolValue();

        uint256 depositValue;

        for (uint8 i = 0; i < _knownDepositAssets.length; i++) {
            address token = _knownDepositAssets[i];
            depositValue += _getScaledAmount(
                assetDepositUtilization[token].amountUsed,
                _tokenDecimals[token],
                18
            );
        }

        return poolValue - depositValue;
    }

    /**
     * @notice Returns the list of the available deposit and swap assets.
     * If an asset has a limit of 0, it will be excluded from the list.
     */
    function getDepositAssets()
        external
        view
        override
        returns (address[] memory)
    {
        uint8 validAssetCount = 0;

        for (uint8 i = 0; i < _knownDepositAssets.length; i++) {
            address token = _knownDepositAssets[i];

            if (assetDepositUtilization[token].limit > 0) {
                validAssetCount++;
            }
        }

        address[] memory result = new address[](validAssetCount);

        uint8 currentIndex = 0;
        for (uint8 i = 0; i < _knownDepositAssets.length; i++) {
            address token = _knownDepositAssets[i];

            if (assetDepositUtilization[token].limit > 0) {
                result[currentIndex] = token;
                currentIndex++;
            }
        }

        return result;
    }

    /**
     * @notice Returns the value of the pool in terms of the deposited stablecoins and creds.
     */
    function getPoolValue()
        public
        view
        override
        returns (uint256)
    {
        uint256 result;

        for (uint8 i = 0; i < _knownDepositAssets.length; i++) {
            address token = _knownDepositAssets[i];
            uint8 decimals = _tokenDecimals[token];

            result += _getScaledAmount(
                IERC20Metadata(token).balanceOf(address(this)),
                decimals,
                18
            );
        }

        result += credsToken.balanceOf(address(this));

        return result;
    }

    /* ========== Private functions ========== */

    /**
     * @dev Used to compute the amount of LP tokens to mint
     */
    function _getScaledAmount(
        uint256 _amount,
        uint8 _decimalsIn,
        uint8 _decimalsOut
    )
        internal
        pure
        returns (uint256)
    {
        if (_decimalsIn == _decimalsOut) {
            return _amount;
        }

        if (_decimalsIn > _decimalsOut) {
            return _amount / 10 ** (_decimalsIn - _decimalsOut);
        } else {
            return _amount * 10 ** (_decimalsOut - _decimalsIn);
        }
    }

    function _swapCredsForStables(
        address _tokenOut,
        uint256 _credsAmount,
        address _receiver
    )
        private
        checkKnownToken(_tokenOut)
        returns (uint256)
    {
        AssetUtilization storage utilization = coreSwapUtilization[msg.sender];

        require(
            utilization.amountUsed + _credsAmount <= utilization.limit,
            "SapphirePool: core swap limit exceeded"
        );

        uint256 expectedOutAmount = _getScaledAmount(
            _credsAmount,
            _decimals,
            _tokenDecimals[_tokenOut]
        );

        // Increase core utilization
        utilization.amountUsed += _credsAmount;

        SafeERC20.safeTransferFrom(
            IERC20Metadata(credsToken),
            msg.sender,
            address(this),
            _credsAmount
        );

        SafeERC20.safeTransfer(
            IERC20Metadata(_tokenOut),
            _receiver,
            expectedOutAmount
        );

        return expectedOutAmount;
    }

    function _swapStablesForCreds(
        address _tokenIn,
        uint256 _stablesAmount,
        address _receiver
    )
        private
        checkKnownToken(_tokenIn)
        returns (uint256)
    {
        require(
            assetDepositUtilization[_tokenIn].limit > 0,
            "SapphirePool: cannot repay with the given token"
        );

        uint8 stableDecimals = _tokenDecimals[_tokenIn];
        uint256 credsOutAmount = _getScaledAmount(
            _stablesAmount,
            stableDecimals,
            _decimals
        );
        AssetUtilization storage utilization = coreSwapUtilization[msg.sender];

        utilization.amountUsed -= credsOutAmount;

        SafeERC20.safeTransferFrom(
            IERC20Metadata(_tokenIn),
            msg.sender,
            address(this),
            _stablesAmount
        );

        SafeERC20.safeTransfer(
            IERC20Metadata(credsToken),
            _receiver,
            credsOutAmount
        );

        return credsOutAmount;
    }

    /**
     * @dev Returns the sum of the deposit limits and the sum of the core swap limits
     * @param _optionalCoreCheck An optional parameter to check if the core has a swap limit > 0
     * @param _excludeCore An optional parameter to exclude the core from the sum
     * @param _excludeDepositToken An optional parameter to exclude the deposit token from the sum
     */
    function _getSumOfLimits(
        address _optionalCoreCheck,
        address _excludeCore,
        address _excludeDepositToken
    )
        private
        view
        returns (uint256, uint256, bool)
    {
        uint256 sumOfDepositLimits;
        uint256 sumOfCoreLimits;
        bool isCoreKnown;
        uint8 decimals;

        for (uint8 i = 0; i < _knownDepositAssets.length; i++) {
            address token = _knownDepositAssets[i];
            if (token == _excludeDepositToken) {
                continue;
            }

            decimals = _tokenDecimals[token];

            sumOfDepositLimits += _getScaledAmount(
                assetDepositUtilization[token].limit,
                decimals,
                18
            );
        }

        for (uint8 i = 0; i < _knownCores.length; i++) {
            address core = _knownCores[i];
            if (core == _excludeCore) {
                continue;
            }

            sumOfCoreLimits += coreSwapUtilization[core].limit;

            if (core == _optionalCoreCheck) {
                isCoreKnown = true;
            }
        }

        return (
            sumOfDepositLimits,
            sumOfCoreLimits,
            isCoreKnown
        );
    }

    /**
     * @dev Returns the amount to be reduced from the user's deposit mapping, token deposit
     * usage and the amount of tokens to be withdrawn, in the withdraw token decimals.
     */
    function _getWithdrawAmounts(
        uint256 _lpAmount,
        address _withdrawToken
    )
        private
        view
        returns (uint256, uint256, uint256)
    {
        WithdrawAmountInfo memory info = _getWithdrawAmountsVars(_lpAmount, _withdrawToken);

        if (info.userDeposit > 0) {
            // User didn't withdraw their initial deposit yet
            if (info.userDeposit > info.withdrawAmt) {
                // Reduce the user's deposit amount and the asset utilization
                // by the amount withdrawn
                return (
                    info.scaledWithdrawAmt,
                    info.withdrawAmt,
                    info.scaledWithdrawAmt
                );
            }

            // The withdraw amount is bigger than the user's initial deposit. This happens when the
            // rewards claimable by the user are greater than the amount of tokens they have
            // deposited.
            if (info.assetUtilization > info.userDeposit) {
                // There's more asset utilization than the user's initial deposit. Reduce it by
                // the amount of the user's initial deposit.
                return (
                    _getScaledAmount(
                        info.userDeposit,
                        _decimals,
                        _tokenDecimals[_withdrawToken]
                    ),
                    info.userDeposit,
                    info.scaledWithdrawAmt
                );
            }

            // The asset utilization is smaller or equal to the user's initial deposit.
            // Set both to 0. The asset utilization can be smaller than the user's initial deposit
            // in the scenario when the user deposited in one token, and withdraws in another.
            return (
                info.assetUtilization,
                info.userDeposit,
                info.scaledWithdrawAmt
            );
        }

        // User deposit is 0, meaning they have withdrawn their initial deposit, and now they're
        // withdrawing pure profit.
        return (
            0,
            0,
            info.scaledWithdrawAmt
        );
    }

    function _getWithdrawAmountsVars(
        uint256 _amount,
        address _withdrawToken
    )
        private
        view
        returns (WithdrawAmountInfo memory)
    {
        WithdrawAmountInfo memory info;

        info.poolValue = getPoolValue();
        info.totalSupply = totalSupply();

        info.withdrawAmt = _amount * info.poolValue / info.totalSupply;
        info.scaledWithdrawAmt = _getScaledAmount(
            info.withdrawAmt,
            _decimals,
            _tokenDecimals[_withdrawToken]
        );

        info.userDeposit = deposits[msg.sender];
        info.assetUtilization = assetDepositUtilization[_withdrawToken].amountUsed;
        info.scaledAssetUtilization = _getScaledAmount(
            info.assetUtilization,
            _tokenDecimals[_withdrawToken],
            _decimals
        );

        return info;
    }

    /**
     * @dev Returns true if the token was historically added as a deposit token
     */
    function _isKnownToken(
        address _token
    )
        private
        view
        returns (bool)
    {
        return _tokenDecimals[_token] > 0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

interface ISapphirePool {
    /* ========== Mutating Functions ========== */

    function setCoreSwapLimit(address _coreAddress, uint256 _limit) external;

    function setDepositLimit(address _tokenAddress, uint256 _limit) external;

    function swap(
        address _tokenIn, 
        address _tokenOut, 
        uint256 _amountIn,
        address _receiver
    ) external;

    function deposit(address _token, uint256 _amount) external;

    function withdraw(uint256 _amount, address _outToken) external;

    /* ========== View Functions ========== */

    function accumulatedRewardAmount() external view returns (uint256);

    function coreSwapUtilization(address _coreAddress) external view returns (uint256, uint256);

    function assetDepositUtilization(address _tokenAddress) external view returns (uint256, uint256);

    function deposits(address _userAddress) external view returns (uint256);

    function getDepositAssets() external view returns (address[] memory);

    function getPoolValue() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.4;

import {IERC20} from "../token/IERC20.sol";

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library SafeERC20 {
    function safeApprove(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        /* solhint-disable-next-line */
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(0x095ea7b3, to, value)
        );

        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "SafeERC20: APPROVE_FAILED"
        );
    }

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        /* solhint-disable-next-line */
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(0xa9059cbb, to, value)
        );

        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "SafeERC20: TRANSFER_FAILED"
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        /* solhint-disable-next-line */
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(
                0x23b872dd,
                from,
                to,
                value
            )
        );

        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "SafeERC20: TRANSFER_FROM_FAILED"
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import { Storage } from "./Storage.sol";

/**
 * @title Adminable
 * @author dYdX
 *
 * @dev EIP-1967 Proxy Admin contract.
 */
contract Adminable {
    /**
     * @dev Storage slot with the admin of the contract.
     *  This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1.
     */
    bytes32 internal constant ADMIN_SLOT =
    0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
    * @dev Modifier to check whether the `msg.sender` is the admin.
    *  If it is, it will run the function. Otherwise, it will revert.
    */
    modifier onlyAdmin() {
        require(
            msg.sender == getAdmin(),
            "Adminable: caller is not admin"
        );
        _;
    }

    /**
     * @return The EIP-1967 proxy admin
     */
    function getAdmin()
        public
        view
        returns (address)
    {
        return address(uint160(uint256(Storage.load(ADMIN_SLOT))));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

/**
 * @dev Collection of functions related to the address type.
 *      Take from OpenZeppelin at
 *      https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Address.sol
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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;


/**
 * @title Math
 *
 * Library for non-standard Math functions
 */
library Math {
    uint256 public constant BASE = 10**18;

    // ============ Library Functions ============

    /*
     * Return target * (numerator / denominator).
     */
    function getPartial(
        uint256 target,
        uint256 numerator,
        uint256 denominator
    )
        internal
        pure
        returns (uint256)
    {
        return target * numerator / denominator;
    }

    function to128(
        uint256 number
    )
        internal
        pure
        returns (uint128)
    {
        uint128 result = uint128(number);
        require(
            result == number,
            "Math: Unsafe cast to uint128"
        );
        return result;
    }

    function min(
        uint256 a,
        uint256 b
    )
        internal
        pure
        returns (uint256)
    {
        return a < b ? a : b;
    }

    function max(
        uint256 a,
        uint256 b
    )
        internal
        pure
        returns (uint256)
    {
        return a > b ? a : b;
    }

    /**
     * @dev Performs a / b, but rounds up instead
     */
    function roundUpDiv(
        uint256 a,
        uint256 b
    )
        internal
        pure
        returns (uint256)
    {
        return (a * BASE + b - 1) / b;
    }

    /**
     * @dev Performs a * b / BASE, but rounds up instead
     */
    function roundUpMul(
        uint256 a,
        uint256 b
    )
        internal
        pure
        returns (uint256)
    {
        return (a * b + BASE - 1) / BASE;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import {IERC20} from "./IERC20.sol";

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import {IERC20Metadata} from "./IERC20Metadata.sol";
import {InitializablePermittable} from "../lib/InitializablePermittable.sol";

/**
 * @title ERC20 Token
 *
 * Basic ERC20 Implementation to be used in a proxy pattern.
 */
contract InitializableBaseERC20 is IERC20Metadata, InitializablePermittable {

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) internal _allowances;

    uint8   internal _decimals;
    uint256 private _totalSupply;

    string  internal _name;
    string  internal _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * All three of these values are immutable: they can only be set once during
     * initialization.
     */
    function _init(
        string memory name_,
        string memory symbol_,
        uint8         decimals_
    )
        internal
        initializer
    {
        _init(name_, "1");
        
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name()
        public
        override
        view
        returns (string memory)
    {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol()
        public
        override
        view
        returns (string memory)
    {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals()
        public
        override
        view
        returns (uint8)
    {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply()
        public
        override
        view
        returns (uint256)
    {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(
        address account
    )
        public
        override
        view
        returns (uint256)
    {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(
        address recipient,
        uint256 amount
    )
        public
        override
        virtual
        returns (bool)
    {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(
        address owner,
        address spender
    )
        public
        override
        view
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(
        address spender,
        uint256 amount
    )
        public
        override
        returns (bool)
    {
        _approve(msg.sender, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    )
        public
        virtual
        override
        returns (bool)
    {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            msg.sender,
            _allowances[sender][msg.sender] - amount
        );

        return true;
    }

    /**
    * @dev Approve by signature.
    *
    * Adapted from Uniswap's UniswapV2ERC20 and MakerDAO's Dai contracts:
    * https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol
    * https://github.com/makerdao/dss/blob/master/src/dai.sol
    */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
        public
    {
        _permit(
            owner,
            spender,
            value,
            deadline,
            v,
            r,
            s
        );
        _approve(owner, spender, value);
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    )
        internal
        virtual
    {
        require(
            sender != address(0),
            "ERC20: transfer from the zero address"
        );

        require(
            recipient != address(0),
            "ERC20: transfer to the zero address"
        );

        _balances[sender] = _balances[sender] - amount;

        _balances[recipient] = _balances[recipient] + amount;
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(
        address account,
        uint256 amount
    )
        internal
    {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply + amount;
        _balances[account] = _balances[account] + amount;
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(
        address account,
        uint256 amount
    )
        internal
    {
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] = _balances[account] - amount;
        _totalSupply = _totalSupply - amount;
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    )
        internal
    {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

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
    function transfer(
        address recipient,
        uint256 amount
    )
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(
        address owner,
        address spender
    )
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
    function approve(
        address spender,
        uint256 amount
    )
        external
        returns (bool);

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
    )
        external
        returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 value
    );

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

library Storage {

    /**
     * @dev Performs an SLOAD and returns the data in the slot.
     */
    function load(
        bytes32 slot
    )
        internal
        view
        returns (bytes32)
    {
        bytes32 result;
        /* solhint-disable-next-line no-inline-assembly */
        assembly {
            result := sload(slot)
        }
        return result;
    }

    /**
     * @dev Performs an SSTORE to save the value to the slot.
     */
    function store(
        bytes32 slot,
        bytes32 value
    )
        internal
    {
        /* solhint-disable-next-line no-inline-assembly */
        assembly {
            sstore(slot, value)
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import {Initializable} from "./Initializable.sol";

contract InitializablePermittable is Initializable {

    /* ============ Variables ============ */

    string public version;

    // solhint-disable-next-line
    bytes32 public DOMAIN_SEPARATOR;

    mapping (address => uint256) public nonces;

    /* ============ Constants ============ */

    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    /* solhint-disable-next-line */
    bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;

    /* ============ Constructor ============ */

    function _init(
        string memory _name,
        string memory _version
    )
        internal
        initializer    
    {
        version = _version;
        DOMAIN_SEPARATOR = _initDomainSeparator(_name, _version);
    }

    /**
     * @dev Initializes EIP712 DOMAIN_SEPARATOR based on the current contract and chain ID.
     */
    function _initDomainSeparator(
        string memory _name,
        string memory _version
    )
        internal
        view
        returns (bytes32)
    {
        uint256 chainID;
        /* solhint-disable-next-line */
        assembly {
            chainID := chainid()
        }

        return keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(_name)),
                keccak256(bytes(_version)),
                chainID,
                address(this)
            )
        );
    }

    /**
    * @dev Approve by signature.
    *      Caution: If an owner signs a permit with no deadline, the corresponding spender
    *      can call permit at any time in the future to mess with the nonce, invalidating
    *      signatures to other spenders, possibly making their transactions fail.
    *
    * Adapted from Uniswap's UniswapV2ERC20 and MakerDAO's Dai contracts:
    * https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol
    * https://github.com/makerdao/dss/blob/master/src/dai.sol
    */
    function _permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
        internal
    {
        require(
            deadline == 0 || deadline >= block.timestamp,
            "Permittable: Permit expired"
        );

        require(
            spender != address(0),
            "Permittable: spender cannot be 0x0"
        );

        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(
                    abi.encode(
                    PERMIT_TYPEHASH,
                    owner,
                    spender,
                    value,
                    nonces[owner]++,
                    deadline
                )
            )
        ));

        address recoveredAddress = ecrecover(
            digest,
            v,
            r,
            s
        );

        require(
            recoveredAddress != address(0) && owner == recoveredAddress,
            "Permittable: Signature invalid"
        );

    }

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

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
 * Taken from OpenZeppelin
 */
contract Initializable {
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