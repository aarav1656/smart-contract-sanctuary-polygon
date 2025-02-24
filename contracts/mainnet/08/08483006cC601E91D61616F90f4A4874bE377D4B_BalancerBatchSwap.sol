// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;


import "./interfaces/IVault.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IBalancerBatchSwap.sol";


contract BalancerBatchSwap is IBalancerBatchSwap {
    address constant balancerV2Address = 0xBA12222222228d8Ba445958a75a0704d566BF2C8;    
    IVault constant _balancerVault = IVault(balancerV2Address);  

    function batchSwap(
        bytes32 poolId, 
        uint256 percentageIn,    
        address[] calldata assets,
        uint256 minAmountOut
    ) external override {
        uint256 amountIn = IERC20(assets[0]).balanceOf(address(this)) * percentageIn / 100000;

        IERC20(assets[0]).approve(balancerV2Address, 0);
        IERC20(assets[0]).approve(balancerV2Address, amountIn);

        IVault.BatchSwapStep[] memory batchSwapSteps = new IVault.BatchSwapStep[](1);
        batchSwapSteps[0] = IVault.BatchSwapStep(
            poolId, // poolId
            0, // assetInIndex
            1, // assetOutIndex
            amountIn, // amount
            "0x" // userData
        );   

        IVault.FundManagement memory funds = IVault.FundManagement(
            address(this), // sender
            false, // fromInternalBalance
            payable(address(this)), // recipient
            false // toInternalBalance
        );

        int256[] memory limits = new int256[](2);
        limits[0] = int(amountIn);
        limits[1] = -int(minAmountOut);

        _balancerVault.batchSwap(
            IVault.SwapKind.GIVEN_IN,
            batchSwapSteps,
            assets,
            funds,
            limits,
            block.timestamp + 100000
        );  
    }
    }

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

/* Interface based on 
   https://github.com/balancer-labs/balancer-v2-monorepo/blob/6cca6c74e26d9e78b8e086fbdcf90075f99d8e76/pkg/vault/contracts/interfaces/IVault.sol
*/
interface IVault {

    function getPoolTokens(bytes32 poolId) external view returns (address[] memory tokens, uint256[] memory balances, uint256 lastChangeBlock);

    /* Join/Exit interface */
    
    enum JoinKind { 
        INIT, 
        EXACT_TOKENS_IN_FOR_BPT_OUT, 
        TOKEN_IN_FOR_EXACT_BPT_OUT, 
        ALL_TOKENS_IN_FOR_EXACT_BPT_OUT 
    }    

    function joinPool(
        bytes32 poolId,
        address sender,
        address recipient,
        JoinPoolRequest memory request
    ) external payable;

    struct JoinPoolRequest {
        address[] assets;
        uint256[] maxAmountsIn;
        bytes userData;
        bool fromInternalBalance;
    }

    enum ExitKind {
        EXACT_BPT_IN_FOR_ONE_TOKEN_OUT,
        EXACT_BPT_IN_FOR_TOKENS_OUT,
        BPT_IN_FOR_EXACT_TOKENS_OUT,
        MANAGEMENT_FEE_TOKENS_OUT // for InvestmentPool
    }    

    function exitPool(
        bytes32 poolId,
        address sender,
        address payable recipient,
        ExitPoolRequest memory request
    ) external;

    struct ExitPoolRequest {
        address[] assets;
        uint256[] minAmountsOut;
        bytes userData;
        bool toInternalBalance;
    }   

    /* Swap interface */

        enum SwapKind { 
        GIVEN_IN,
        GIVEN_OUT
    }    

    struct SingleSwap {
        bytes32 poolId;
        SwapKind kind;
        address assetIn;
        address assetOut;
        uint256 amount;
        bytes userData;
    }

    struct FundManagement {
        address sender;
        bool fromInternalBalance;
        address payable recipient;
        bool toInternalBalance;
    }

    function swap(
        SingleSwap memory singleSwap,
        FundManagement memory funds,
        uint256 limit,
        uint256 deadline
    ) external returns (uint256 amountCalculated);

    struct BatchSwapStep {
        bytes32 poolId;
        uint256 assetInIndex;
        uint256 assetOutIndex;
        uint256 amount;
        bytes userData;
    }

    function batchSwap(
        SwapKind kind,
        BatchSwapStep[] memory swaps,
        address[] memory assets,
        FundManagement memory funds,
        int256[] memory limits,
        uint256 deadline
    ) external payable returns (int256[] memory);
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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.6;

interface IBalancerBatchSwap {

    event DEFIBASKET_BALANCER_ADD_LIQUIDITY(
        bytes32 poolId,
        uint256[] amountsIn,
        uint256 liquidity
    );

    event DEFIBASKET_BALANCER_REMOVE_LIQUIDITY(
        bytes32 poolId,
        address[] tokens,
        uint256[] tokenAmountsOut,
        uint256 liquidity
    );

    function batchSwap(
        bytes32 poolId, 
        uint256 percentageIn,    
        address[] calldata assets,
        uint256 minAmountOut
    ) external;
}