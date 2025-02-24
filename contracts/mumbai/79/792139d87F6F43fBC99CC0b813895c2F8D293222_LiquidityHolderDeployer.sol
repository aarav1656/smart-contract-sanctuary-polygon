// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity >=0.6.12;

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

    constructor() public {
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.12;

interface IBetLiquidityHolder {
    function receiveLiquidityCreator(
        uint256 tokenLiquidity_,
        address tokenAddress_,
        address betCreator_,
        address betTrendSetter_,
        uint256 lossSimulationPercentage
    ) external;

    function receiveLiquidityTaker(
        uint256 tokenLiquidity_,
        address betTaker_,
        address registry_,
        bool forwarderFlag_
    ) external;

    function withdrawLiquidity(address user_) external payable;

    function claimReward(
        address betWinnerAddress_,
        address betLooserAddress_,
        address registry_,
        address agreegatorAddress_,
        bool lossSimulationFlag_
    ) external payable returns (bool);

    function processDrawMatch(address registry_, bool lossSimulationFlag_)
        external
        payable
        returns (bool);

    function processBan(address registry_, bool lossSimulationFlag_)
        external
        payable
        returns (bool);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.6.12;

interface IConfig {

    function getLatestVersion() external view returns (uint);

    function getAdmin() external view returns (address);

    function getAaveTimeThresold() external view returns (uint256);

    function getBlacklistedAsset(address asset_) external view returns (bool);

    function setDisputeConfig(
        uint256 escrowAmount_,
        uint256 requirePaymentForJury_
    ) external returns (bool);

    function getDisputeConfig() external view returns (uint256, uint256);

    function setWalletAddress(address developer_, address escrow_)
        external
        returns (bool);

    function getWalletAddress() external view returns (address, address);

    function getTokensPerStrike(uint256 strike_)
        external
        view
        returns (uint256);

    function getJuryTokensShare(uint256 strike_, uint256 version_)
        external
        view
        returns (uint256);

    function setFeeDeductionConfig(
        uint256 platformFees_,
        uint256 after_full_swap_treasury_wallet_transfer_,
        uint256 after_full_swap_without_trend_setter_treasury_wallet_transfer_,
        uint256 dbeth_swap_amount_with_trend_setter_,
        uint256 dbeth_swap_amount_without_trend_setter_,
        uint256 bet_trend_setter_reward_,
        uint256 pool_distribution_amount_,
        uint256 burn_amount_,
        uint256 pool_distribution_amount_without_trendsetter_,
        uint256 burn_amount_without_trendsetter
    ) external returns (bool);

    function setAaveFeeConfig(
        uint256 aave_apy_bet_winner_distrubution_,
        uint256 aave_apy_bet_looser_distrubution_
    ) external returns (bool);

    function getFeeDeductionConfig()
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        );

    function getAaveConfig() external view returns (uint256, uint256);

    function setAddresses(
        address lendingPoolAddressProvider_,
        address wethGateway_,
        address aWMATIC_,
        address aDAI_,
        address uniswapV2Factory,
        address uniswapV2Router
    )
        external
        returns (
            address,
            address,
            address,
            address
        );

    function getAddresses()
        external
        view
        returns (
            address,
            address,
            address,
            address,
            address,
            address
        );

    function setPairAddresses(address tokenA_, address tokenB_)
        external
        returns (bool);

    function getPairAddress(address tokenA_)
        external
        view
        returns (address, address);

    function getUniswapRouterAddress() external view returns (address);

    function getAaveRecovery()
        external
        view
        returns (
            address,
            address,
            address
        );
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity >=0.6.12;

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

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
    function allowance(address owner, address spender)
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

// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.6.12;

interface IFeeAgreegator {
    function calculateAaveDistribution(uint256 amount_, address configAddress_)
        external
        view
        returns (
            uint256 calculatedAmountForWiner_,
            uint256 calculatedAmountForLooser_
        );

    function calculatePlatformFeeDeduction(
        uint256 amount_,
        address configAddress_
    ) external view returns (uint256 calculatedAmount_);

    function calculateAfterFullSwapFeeDistribution(
        uint256 receivedSwappedAmount_,
        bool isTrendSetterAvailable,
        address configAddress_
    ) external view returns (uint256 calculatedAmountForTreasury_);

    function calculateAfterDBETHSwapFeeDistribution(
        uint256 receivedSwappedDBETHAmount_,
        bool isTrendSetterAvailable,
        address configAddress_
    )
        external
        view
        returns (
            uint256 calculatedAmountForTrendSetter_,
            uint256 calculatedAmountForPoolDistribution_,
            uint256 calculatedAmountForBurn_
        );
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.6.12;

interface ILendingPool {
    /**
     * @dev Deposits an `amount` of underlying asset into the reserve, receiving in return overlying aTokens.
     * - E.g. User deposits 100 USDC and gets in return 100 aUSDC
     * @param asset The address of the underlying asset to deposit
     * @param amount The amount to be deposited
     * @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
     *   wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
     *   is a different wallet
     * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     **/
    function deposit(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external;

    /**
     * @dev Withdraws an `amount` of underlying asset from the reserve, burning the equivalent aTokens owned
     * E.g. User has 100 aUSDC, calls withdraw() and receives 100 USDC, burning the 100 aUSDC
     * @param asset The address of the underlying asset to withdraw
     * @param amount The underlying amount to be withdrawn
     *   - Send the value type(uint256).max in order to withdraw the whole aToken balance
     * @param to Address that will receive the underlying, same as msg.sender if the user
     *   wants to receive it on his own wallet, or a different address if the beneficiary is a
     *   different wallet
     * @return The final amount withdrawn
     **/
    function withdraw(
        address asset,
        uint256 amount,
        address to
    ) external returns (uint256);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.6.12;

/**
 * @title LendingPoolAddressesProvider contract
 * @dev Main registry of addresses part of or connected to the protocol, including permissioned roles
 * - Acting also as factory of proxies and admin of those, so with right to change its implementations
 * - Owned by the Aave Governance
 * @author Aave
 **/
interface ILendingPoolAddressesProvider {
    function getLendingPool() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;

interface ILiquidityHolderDeployer {
    function deployHolder() external returns (address);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.12;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.12;

import "./IUniswapV2Router01.sol";

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.6.12;

interface IWETHGateway {
    function depositETH(
        address lendingPool,
        address onBehalfOf,
        uint16 referralCode
    ) external payable;

    function withdrawETH(
        address lendingPool,
        uint256 amount,
        address onBehalfOf
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;

import "../Interfaces/IUniswapV2Router02.sol";
import "../Interfaces/IERC20.sol";

library ProcessData {
    function rsvExtracotr(bytes32 hash_, bytes memory sig_)
        public
        pure
        returns (address)
    {
        require(sig_.length == 65, "Require correct length");

        bytes32 r;
        bytes32 s;
        uint8 v;

        // Divide the signature in r, s and v variables
        assembly {
            r := mload(add(sig_, 32))
            s := mload(add(sig_, 64))
            v := byte(0, mload(add(sig_, 96)))
        }

        // Version of signature should be 27 or 28, but 0 and 1 are also possible versions
        if (v < 27) {
            v += 27;
        }

        require(v == 27 || v == 28, "Signature version not match");
        return recoverSigner(hash_, v, r, s);
    }

    function recoverSigner(
        bytes32 h,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public pure returns (address) {
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 prefixedHash = keccak256(abi.encodePacked(prefix, h));
        address addr = ecrecover(prefixedHash, v, r, s);

        return addr;
    }

    function getProofStatus(
        bytes32[] memory hash_,
        bytes memory maker_,
        bytes memory taker_,
        address betInitiator_,
        address betTaker_
    ) public pure returns (bool _makerProof, bool _takerProof) {
        address[] memory a = new address[](hash_.length);
        a[0] = rsvExtracotr(hash_[0], maker_);
        a[1] = rsvExtracotr(hash_[1], taker_);
        for (uint256 i = 0; i < a.length; i++) {
            if (a[i] == betInitiator_) {
                _makerProof = true;
            }
        }
        for (uint256 i = 0; i < a.length; i++) {
            if (a[i] == betTaker_) {
                _takerProof = true;
            }
        }
    }

    function resolutionClearance(
        bytes32[] memory hash_,
        bytes memory maker_,
        bytes memory taker_,
        address betInitiator,
        address betTaker
    ) public pure returns (bool status_) {
        bool _makerProof;
        bool _takerProof;
        (_makerProof, _takerProof) = getProofStatus(
            hash_,
            maker_,
            taker_,
            betInitiator,
            betTaker
        );
        if (_makerProof || _takerProof) status_ = true;
    }

    function swapping(
        address uniswapV2Router_,
        address tokenA_,
        address tokenB_
    ) public view returns (uint256) {
        //IERC20(tokenB_).approve(uniswapV2Router_,address(this).balance);
        address[] memory t = new address[](2);
        t[0] = tokenA_;
        t[1] = tokenB_;
        uint256[] memory amount = new uint256[](2);
        amount = tokenA_ == 0x5B67676a984807a212b1c59eBFc9B3568a474F0a
            ? IUniswapV2Router02(uniswapV2Router_).getAmountsOut(
                address(this).balance,
                t
            )
            : IUniswapV2Router02(uniswapV2Router_).getAmountsOut(
                IERC20(tokenA_).balanceOf(address(this)),
                t
            );
        return amount[1];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;

import "../Helper/ReentrancyGuard.sol";
import "../Interfaces/IBetLiquidityHolder.sol";
import "../Interfaces/IERC20.sol";
import "../Interfaces/ILendingPoolAddressesProvider.sol";
import "../Interfaces/ILendingPool.sol";
import "../Interfaces/IWETHGateway.sol";
import "../Interfaces/IUniswapV2Router02.sol";
import "../Interfaces/IConfig.sol";
import "../Interfaces/IFeeAgreegator.sol";
import "../Libraries/ProcessData.sol";

contract BetLiquidityHolder is IBetLiquidityHolder, ReentrancyGuard {
    uint256 public totalAvailableLiquidity;
    uint256 public receivedYeild;
    address internal tokenAddress;
    address internal betCreator;
    address internal betTaker;
    address internal betWinner;
    address internal betTrendSetter;

    bool internal forwarderFlag;

    uint256 internal lossSimulationPercentage;

    mapping(address => uint256) internal userLiquidity;

    receive() external payable {}

    function receiveLiquidityCreator(
        uint256 tokenLiquidity_,
        address tokenAddress_,
        address betCreator_,
        address betTrendSetter_,
        uint256 lossSimulationPercentage_
    ) external override nonReentrant {
        totalAvailableLiquidity += tokenLiquidity_;
        tokenAddress = tokenAddress_;
        betCreator = betCreator_;
        betTrendSetter = betTrendSetter_;
        userLiquidity[betCreator_] = tokenLiquidity_;
        lossSimulationPercentage = lossSimulationPercentage_;
    }

    function receiveLiquidityTaker(
        uint256 tokenLiquidity_,
        address betTaker_,
        address registry_,
        bool forwarderFlag_
    ) external override nonReentrant {
        totalAvailableLiquidity += tokenLiquidity_;
        betTaker = betTaker_;
        userLiquidity[betTaker_] = tokenLiquidity_;
        forwarderFlag = forwarderFlag_;
        if (forwarderFlag_) {
            if (!IConfig(registry_).getBlacklistedAsset(tokenAddress)) {
                address _LendingPoolAddressProvider;
                address _WETHGateway;
                (_LendingPoolAddressProvider, _WETHGateway, ) = IConfig(
                    registry_
                ).getAaveRecovery();
                address _poolAddress = ILendingPoolAddressesProvider(
                    _LendingPoolAddressProvider
                ).getLendingPool();
                if (tokenAddress == address(0)) {
                    IWETHGateway(_WETHGateway).depositETH{
                        value: address(this).balance
                    }(_poolAddress, address(this), 0);
                } else {
                    IERC20(tokenAddress).approve(
                        _poolAddress,
                        totalAvailableLiquidity
                    );
                    ILendingPool(_poolAddress).deposit(
                        tokenAddress,
                        totalAvailableLiquidity,
                        address(this),
                        0
                    );
                }
            }
        }
    }

    function processUSDTTransfer(address registry_, address agreegatorAddress_)
        internal
        returns (bool)
    {
        uint256 _balance = IERC20(0xBD21A10F619BE90d6066c941b04e340841F1F989)
            .balanceOf(address(this));
        if (betTrendSetter != address(0)) {
            uint256 _trasury = IFeeAgreegator(agreegatorAddress_)
                .calculateAfterFullSwapFeeDistribution(
                    _balance,
                    true,
                    registry_
                );
            // Transfer To Treasury
            IERC20(0xBD21A10F619BE90d6066c941b04e340841F1F989).transfer(
                0x54EFD825a665D5e968BF3659d24A9Cd847F102C3,
                _trasury
            );
        } else {
            uint256 _trasury = IFeeAgreegator(agreegatorAddress_)
                .calculateAfterFullSwapFeeDistribution(
                    _balance,
                    false,
                    registry_
                );
            // Transfer To Treasury
            IERC20(0xBD21A10F619BE90d6066c941b04e340841F1F989).transfer(
                0x54EFD825a665D5e968BF3659d24A9Cd847F102C3,
                _trasury
            );
        }
        //require(processDBETHSwap(registry_,agreegatorAddress_),"DBETH Swap Failed");
        return true;
    }

    function processDBETHSwap(address registry_) internal returns (bool) {
        address _UniswapV2Router = IConfig(registry_).getUniswapRouterAddress();
        (address tokenA_, address tokenB_) = IConfig(registry_).getPairAddress(
            0xBD21A10F619BE90d6066c941b04e340841F1F989
        );
        uint256 _balance = IERC20(tokenA_).balanceOf(address(this));
        IERC20(tokenA_).approve(_UniswapV2Router, _balance);
        IERC20(tokenB_).approve(_UniswapV2Router, _balance);
        address[] memory t = new address[](2);
        t[0] = tokenA_;
        t[1] = tokenB_;
        uint256 amount = ProcessData.swapping(
            _UniswapV2Router,
            tokenA_,
            tokenB_
        );
        IUniswapV2Router02(_UniswapV2Router).swapExactTokensForTokens(
            _balance,
            amount,
            t,
            address(this),
            block.timestamp + 1000
        );

        return true;
    }

    function processFinalLiquidityDistribution(
        address registry_,
        address agreegatorAddress_
    ) internal returns (bool) {
        uint256 calculatedAmountForTrendSetter_;
        uint256 calculatedAmountForPoolDistribution_;
        uint256 calculatedAmountForBurn_;
        if (betTrendSetter != address(0)) {
            (
                calculatedAmountForTrendSetter_,
                calculatedAmountForPoolDistribution_,
                calculatedAmountForBurn_
            ) = IFeeAgreegator(agreegatorAddress_)
                .calculateAfterDBETHSwapFeeDistribution(
                    IERC20(0xf04A870D9124c4bBE1b2C2B80eb6020A11B22499)
                        .balanceOf(address(this)),
                    true,
                    registry_
                );
            IERC20(0xf04A870D9124c4bBE1b2C2B80eb6020A11B22499).transfer(
                betTrendSetter,
                calculatedAmountForTrendSetter_
            );
            // Transfer To Pool
            IERC20(0xf04A870D9124c4bBE1b2C2B80eb6020A11B22499).transfer(
                0x98D7576Ed7cb73f095cA418a1DA71401dE23a4C0,
                calculatedAmountForPoolDistribution_
            );
            IERC20(0xf04A870D9124c4bBE1b2C2B80eb6020A11B22499).transfer(
                0x98D7576Ed7cb73f095cA418a1DA71401dE23a4C0,
                calculatedAmountForBurn_
            );
        } else {
            (
                ,
                calculatedAmountForPoolDistribution_,
                calculatedAmountForBurn_
            ) = IFeeAgreegator(agreegatorAddress_)
                .calculateAfterDBETHSwapFeeDistribution(
                    IERC20(0xf04A870D9124c4bBE1b2C2B80eb6020A11B22499)
                        .balanceOf(address(this)),
                    false,
                    registry_
                );
            IERC20(0xf04A870D9124c4bBE1b2C2B80eb6020A11B22499).transfer(
                0x98D7576Ed7cb73f095cA418a1DA71401dE23a4C0,
                calculatedAmountForPoolDistribution_
            );
            IERC20(0xf04A870D9124c4bBE1b2C2B80eb6020A11B22499).transfer(
                0x98D7576Ed7cb73f095cA418a1DA71401dE23a4C0,
                calculatedAmountForBurn_
            );
        }

        return true;
    }

    function processAaveRecovery(address registry_)
        public
        payable
        nonReentrant
        returns (bool)
    {
        (
            address _LendingPoolAddressProvider,
            address _WETHGateway,
            address _aWMATIC
        ) = IConfig(registry_).getAaveRecovery();
        address _poolAddress = ILendingPoolAddressesProvider(
            _LendingPoolAddressProvider
        ).getLendingPool();
        if (tokenAddress == address(0)) {
            IERC20(_aWMATIC).approve(_WETHGateway, type(uint256).max);
            IWETHGateway(_WETHGateway).withdrawETH(
                _poolAddress,
                type(uint256).max,
                address(this)
            );
            receivedYeild += address(this).balance;
        } else {
            ILendingPool(_poolAddress).withdraw(
                tokenAddress,
                type(uint256).max,
                address(this)
            );
            receivedYeild += IERC20(tokenAddress).balanceOf(address(this));
        }

        return true;
    }

    function payReward(
        address winner_,
        address looser_,
        uint256 winnerAmount_,
        uint256 looserAmount_,
        uint256 treasury_
    ) public payable returns (bool) {
        payable(winner_).transfer(winnerAmount_);
        payable(looser_).transfer(looserAmount_);
        payable(0x98D7576Ed7cb73f095cA418a1DA71401dE23a4C0).transfer(treasury_);

        emit PostUserLiquidity(
            address(this),
            winner_,
            looser_,
            winnerAmount_,
            looserAmount_
        );

        return true;
    }

    event PostUserLiquidity(
        address indexed betId_,
        address winner_,
        address looser_,
        uint256 winnerAmount_,
        uint256 looserAmount_
    );

    function processAaveDistribution(
        address betWinnerAddress_,
        address betLooserAddress_,
        address agreegatorAddress_,
        address registry_,
        bool lossSimulationFlag
    ) public payable nonReentrant returns (bool) {
        uint256 platformFee;
        uint256 winnigAmount;
        uint256 aave_yeild;
        uint256 _winner;
        uint256 _looser;
        uint256 _currentBal;

        if (tokenAddress == address(0)) {
            if (address(this).balance > totalAvailableLiquidity) {
                if (!lossSimulationFlag) {
                    aave_yeild =
                        address(this).balance -
                        totalAvailableLiquidity;
                    (_winner, _looser) = IFeeAgreegator(agreegatorAddress_)
                        .calculateAaveDistribution(aave_yeild, registry_);
                    platformFee = IFeeAgreegator(agreegatorAddress_)
                        .calculatePlatformFeeDeduction(
                            totalAvailableLiquidity,
                            registry_
                        );
                    winnigAmount = totalAvailableLiquidity - platformFee;
                    winnigAmount += _winner / 2;
                    payReward(
                        betWinnerAddress_,
                        betLooserAddress_,
                        winnigAmount,
                        _winner / 2,
                        _looser
                    );
                } else {
                    aave_yeild =
                        address(this).balance -
                        totalAvailableLiquidity;
                    aave_yeild +=
                        uint256(
                            totalAvailableLiquidity * lossSimulationPercentage
                        ) /
                        100;
                    platformFee = IFeeAgreegator(agreegatorAddress_)
                        .calculatePlatformFeeDeduction(
                            totalAvailableLiquidity - aave_yeild,
                            registry_
                        );
                    aave_yeild += platformFee;
                    //(_winner,_looser) = IFeeAgreegator(agreegatorAddress_).calculateAaveDistribution(uint(aave_yeild/2),registry_);
                    //winnigAmount = (totalAvailableLiquidity/2) - platformFee;
                    winnigAmount = totalAvailableLiquidity - aave_yeild;
                    winnigAmount -= platformFee;
                    //winnigAmount += _winner/2;
                    // Transfer to dead address to simulate loss scenario
                    payReward(
                        betWinnerAddress_,
                        betLooserAddress_,
                        winnigAmount,
                        0,
                        aave_yeild
                    );
                    //payable(0x98D7576Ed7cb73f095cA418a1DA71401dE23a4C0).transfer(aave_yeild);
                }
                // payable(betWinnerAddress_).transfer(winnigAmount);
                // payable(betLooserAddress_).transfer(_looser);
                // payable(0x98D7576Ed7cb73f095cA418a1DA71401dE23a4C0).transfer(10000);
            } else if (totalAvailableLiquidity - address(this).balance > 0) {
                uint256 deflation = totalAvailableLiquidity -
                    address(this).balance;
                platformFee = IFeeAgreegator(agreegatorAddress_)
                    .calculatePlatformFeeDeduction(deflation, registry_);
                payReward(
                    betWinnerAddress_,
                    betLooserAddress_,
                    address(this).balance - platformFee,
                    0,
                    platformFee
                );
            } else {
                platformFee = IFeeAgreegator(agreegatorAddress_)
                    .calculatePlatformFeeDeduction(
                        address(this).balance,
                        registry_
                    );
                winnigAmount = address(this).balance - platformFee;
                payable(betWinnerAddress_).transfer(winnigAmount);
                emit PostUserLiquidity(
                    address(this),
                    betWinnerAddress_,
                    address(0),
                    winnigAmount,
                    0
                );
            }
        } else {
            _currentBal = IERC20(tokenAddress).balanceOf(address(this));
            if (_currentBal > totalAvailableLiquidity) {
                if (!lossSimulationFlag) {
                    aave_yeild = _currentBal - totalAvailableLiquidity;
                    (_winner, _looser) = IFeeAgreegator(agreegatorAddress_)
                        .calculateAaveDistribution(aave_yeild, registry_);
                    platformFee = IFeeAgreegator(agreegatorAddress_)
                        .calculatePlatformFeeDeduction(
                            totalAvailableLiquidity,
                            registry_
                        );
                    winnigAmount = totalAvailableLiquidity - platformFee;
                    winnigAmount += _winner / 2;
                    IERC20(tokenAddress).transfer(
                        betWinnerAddress_,
                        winnigAmount
                    );
                    IERC20(tokenAddress).transfer(
                        betLooserAddress_,
                        _winner / 2
                    );
                    PostUserLiquidity(
                        address(this),
                        betWinnerAddress_,
                        betLooserAddress_,
                        winnigAmount,
                        _winner / 2
                    );
                } else {
                    aave_yeild = _currentBal - totalAvailableLiquidity;
                    aave_yeild +=
                        uint256(
                            totalAvailableLiquidity * lossSimulationPercentage
                        ) /
                        100;
                    platformFee = IFeeAgreegator(agreegatorAddress_)
                        .calculatePlatformFeeDeduction(
                            totalAvailableLiquidity - aave_yeild,
                            registry_
                        );
                    winnigAmount = totalAvailableLiquidity - aave_yeild;
                    winnigAmount -= platformFee;
                    IERC20(tokenAddress).transfer(
                        betWinnerAddress_,
                        winnigAmount
                    );
                    PostUserLiquidity(
                        address(this),
                        betWinnerAddress_,
                        betLooserAddress_,
                        winnigAmount,
                        0
                    );
                }
            } else if (totalAvailableLiquidity - _currentBal > 0) {
                uint256 deflation = totalAvailableLiquidity - _currentBal;
                platformFee = IFeeAgreegator(agreegatorAddress_)
                    .calculatePlatformFeeDeduction(deflation, registry_);
                payReward(
                    betWinnerAddress_,
                    betLooserAddress_,
                    _currentBal - platformFee,
                    0,
                    platformFee
                );
            } else {
                platformFee = IFeeAgreegator(agreegatorAddress_)
                    .calculatePlatformFeeDeduction(_currentBal, registry_);
                winnigAmount = _currentBal - platformFee;
                IERC20(tokenAddress).transfer(betWinnerAddress_, winnigAmount);
                PostUserLiquidity(
                    address(this),
                    betWinnerAddress_,
                    address(0),
                    winnigAmount,
                    0
                );
            }
        }

        return true;
    }

    function processUSDTSwap(address registry_)
        public
        payable
        nonReentrant
        returns (bool)
    {
        address _UniswapV2Router = IConfig(registry_).getUniswapRouterAddress();
        (address tokenA_, address tokenB_) = tokenAddress == address(0)
            ? IConfig(registry_).getPairAddress(
                0x5B67676a984807a212b1c59eBFc9B3568a474F0a
            )
            : IConfig(registry_).getPairAddress(tokenAddress);
        address[] memory t = new address[](2);
        t[0] = tokenA_;
        t[1] = tokenB_;
        uint256 amount = ProcessData.swapping(
            _UniswapV2Router,
            tokenA_,
            tokenB_
        );
        if (tokenAddress == address(0))
            IUniswapV2Router02(_UniswapV2Router).swapExactETHForTokens{
                value: address(this).balance
            }(amount, t, address(this), block.timestamp + 1000);
        else {
            uint256 _bal = IERC20(tokenA_).balanceOf(address(this));
            IERC20(tokenA_).approve(_UniswapV2Router, _bal);
            IUniswapV2Router02(_UniswapV2Router).swapExactTokensForTokens(
                IERC20(tokenAddress).balanceOf(address(this)),
                amount,
                t,
                address(this),
                block.timestamp + 1000
            );
        }

        return true;
    }

    function claimReward(
        address betWinnerAddress_,
        address betLosserAddress_,
        address registry_,
        address agreegatorAddress_,
        bool lossSimulationFlag_
    ) external payable override nonReentrant returns (bool) {
        if (
            forwarderFlag &&
            !IConfig(registry_).getBlacklistedAsset(tokenAddress)
        ) processAaveRecovery(registry_);
        processAaveDistribution(
            betWinnerAddress_,
            betLosserAddress_,
            agreegatorAddress_,
            registry_,
            lossSimulationFlag_
        );
        if (tokenAddress != 0xBD21A10F619BE90d6066c941b04e340841F1F989)
            processUSDTSwap(registry_);
        processUSDTTransfer(registry_, agreegatorAddress_);
        processDBETHSwap(registry_);
        processFinalLiquidityDistribution(registry_, agreegatorAddress_);
        collectDeveloperFee(registry_);

        return true;
    }

    function withdrawLiquidity(address user_) external payable override {
        require(betCreator != address(0), "Invalid Bet");
        require(betTaker == address(0), "Bet Is Ongoing");
        if (tokenAddress == address(0))
            payable(user_).transfer(totalAvailableLiquidity);
        else IERC20(tokenAddress).transfer(user_, totalAvailableLiquidity);
    }

    event PostDrawDistribution(
        address indexed betId_,
        address betMaker_,
        address betTaker_,
        address admin_,
        uint256 betMakerAmount_,
        uint256 betTakerAmount_,
        uint256 adminAmount_
    );

    function calculateDefletion(uint256 a_, uint256 b_)
        internal
        pure
        returns (uint256)
    {
        uint256 a = a_ / 100;
        uint256 temp = uint256(b_ / a);

        return temp;
    }

    function processAaveDistributionForDraw(
        address registry_,
        bool lossSimulationFlag_
    ) public payable nonReentrant returns (bool) {
        if (tokenAddress == address(0)) {
            if (address(this).balance > totalAvailableLiquidity) {
                if (!lossSimulationFlag_) {
                    uint256 _adminAmount = address(this).balance -
                        totalAvailableLiquidity;
                    payable(IConfig(registry_).getAdmin()).transfer(
                        _adminAmount
                    );
                    payable(betCreator).transfer(userLiquidity[betCreator]);
                    if (userLiquidity[betTaker] > 0)
                        payable(betTaker).transfer(userLiquidity[betTaker]);
                    emit PostDrawDistribution(
                        address(this),
                        betCreator,
                        betTaker,
                        IConfig(registry_).getAdmin(),
                        userLiquidity[betCreator],
                        userLiquidity[betTaker],
                        _adminAmount
                    );
                } else {
                    uint256 _adminAmount = address(this).balance -
                        totalAvailableLiquidity;
                    _adminAmount +=
                        uint256(
                            totalAvailableLiquidity * lossSimulationPercentage
                        ) /
                        100;
                    payable(IConfig(registry_).getAdmin()).transfer(
                        _adminAmount
                    );
                    uint256 defletionPercentage = calculateDefletion(
                        totalAvailableLiquidity,
                        uint256(
                            totalAvailableLiquidity * lossSimulationPercentage
                        ) / 100
                    );
                    payable(betCreator).transfer(
                        userLiquidity[betCreator] -
                            uint256(
                                userLiquidity[betCreator] * defletionPercentage
                            ) /
                            100
                    );
                    if (userLiquidity[betTaker] > 0)
                        payable(betTaker).transfer(
                            userLiquidity[betTaker] -
                                uint256(
                                    userLiquidity[betTaker] *
                                        defletionPercentage
                                ) /
                                100
                        );
                    emit PostDrawDistribution(
                        address(this),
                        betCreator,
                        betTaker,
                        IConfig(registry_).getAdmin(),
                        userLiquidity[betCreator] -
                            uint256(
                                userLiquidity[betCreator] * defletionPercentage
                            ) /
                            100,
                        userLiquidity[betTaker] -
                            uint256(
                                userLiquidity[betTaker] * defletionPercentage
                            ) /
                            100,
                        _adminAmount
                    );
                }
            } else if (totalAvailableLiquidity - address(this).balance > 0) {
                uint256 defletionPercentage = calculateDefletion(
                    totalAvailableLiquidity,
                    address(this).balance
                );
                payable(betCreator).transfer(
                    userLiquidity[betCreator] -
                        uint256(
                            userLiquidity[betCreator] * defletionPercentage
                        ) /
                        100
                );
                if (userLiquidity[betTaker] > 0)
                    payable(betTaker).transfer(
                        userLiquidity[betTaker] -
                            uint256(
                                userLiquidity[betTaker] * defletionPercentage
                            ) /
                            100
                    );
                emit PostDrawDistribution(
                    address(this),
                    betCreator,
                    betTaker,
                    IConfig(registry_).getAdmin(),
                    userLiquidity[betCreator] -
                        uint256(
                            userLiquidity[betCreator] * defletionPercentage
                        ) /
                        100,
                    userLiquidity[betTaker] -
                        uint256(userLiquidity[betTaker] * defletionPercentage) /
                        100,
                    0
                );
            } else {
                payable(betCreator).transfer(userLiquidity[betCreator]);
                if (userLiquidity[betTaker] > 0)
                    payable(betTaker).transfer(userLiquidity[betTaker]);
                emit PostDrawDistribution(
                    address(this),
                    betCreator,
                    betTaker,
                    IConfig(registry_).getAdmin(),
                    userLiquidity[betCreator],
                    userLiquidity[betTaker],
                    0
                );
            }
        } else {
            uint256 _currentBal = IERC20(tokenAddress).balanceOf(address(this));
            if (_currentBal > totalAvailableLiquidity) {
                if (!lossSimulationFlag_) {
                    uint256 _adminAmount = _currentBal -
                        totalAvailableLiquidity;
                    IERC20(tokenAddress).transfer(
                        IConfig(registry_).getAdmin(),
                        _adminAmount
                    );
                    IERC20(tokenAddress).transfer(
                        betCreator,
                        userLiquidity[betCreator]
                    );
                    if (userLiquidity[betTaker] > 0)
                        IERC20(tokenAddress).transfer(
                            betTaker,
                            userLiquidity[betTaker]
                        );
                    emit PostDrawDistribution(
                        address(this),
                        betCreator,
                        betTaker,
                        IConfig(registry_).getAdmin(),
                        userLiquidity[betCreator],
                        userLiquidity[betTaker],
                        _adminAmount
                    );
                } else {
                    uint256 _adminAmount = _currentBal -
                        totalAvailableLiquidity;
                    _adminAmount +=
                        uint256(
                            totalAvailableLiquidity * lossSimulationPercentage
                        ) /
                        100;
                    uint256 defletionPercentage = calculateDefletion(
                        totalAvailableLiquidity,
                        uint256(
                            totalAvailableLiquidity * lossSimulationPercentage
                        ) / 100
                    );
                    IERC20(tokenAddress).transfer(
                        betCreator,
                        userLiquidity[betCreator] -
                            uint256(
                                userLiquidity[betCreator] * defletionPercentage
                            ) /
                            100
                    );
                    if (userLiquidity[betTaker] > 0)
                        IERC20(tokenAddress).transfer(
                            betTaker,
                            userLiquidity[betTaker] -
                                uint256(
                                    userLiquidity[betTaker] *
                                        defletionPercentage
                                ) /
                                100
                        );
                    IERC20(tokenAddress).transfer(
                        IConfig(registry_).getAdmin(),
                        _adminAmount
                    );
                    emit PostDrawDistribution(
                        address(this),
                        betCreator,
                        betTaker,
                        IConfig(registry_).getAdmin(),
                        userLiquidity[betTaker] -
                            uint256(
                                userLiquidity[betTaker] * defletionPercentage
                            ) /
                            100,
                        userLiquidity[betTaker] -
                            uint256(
                                userLiquidity[betTaker] * defletionPercentage
                            ) /
                            100,
                        0
                    );
                }
            } else if (totalAvailableLiquidity - _currentBal > 0) {
                uint256 defletionPercentage = calculateDefletion(
                    totalAvailableLiquidity,
                    _currentBal
                );
                IERC20(tokenAddress).transfer(
                    betCreator,
                    userLiquidity[betCreator] -
                        uint256(
                            userLiquidity[betCreator] * defletionPercentage
                        ) /
                        100
                );
                if (userLiquidity[betTaker] > 0)
                    IERC20(tokenAddress).transfer(
                        betTaker,
                        userLiquidity[betTaker] -
                            uint256(
                                userLiquidity[betTaker] * defletionPercentage
                            ) /
                            100
                    );
                emit PostDrawDistribution(
                    address(this),
                    betCreator,
                    betTaker,
                    IConfig(registry_).getAdmin(),
                    userLiquidity[betTaker] -
                        uint256(userLiquidity[betTaker] * defletionPercentage) /
                        100,
                    userLiquidity[betTaker] -
                        uint256(userLiquidity[betTaker] * defletionPercentage) /
                        100,
                    0
                );
            } else {
                IERC20(tokenAddress).transfer(
                    betCreator,
                    userLiquidity[betCreator]
                );
                if (userLiquidity[betTaker] > 0)
                    IERC20(tokenAddress).transfer(
                        betTaker,
                        userLiquidity[betTaker]
                    );
                emit PostDrawDistribution(
                    address(this),
                    betCreator,
                    betTaker,
                    IConfig(registry_).getAdmin(),
                    userLiquidity[betCreator],
                    userLiquidity[betTaker],
                    0
                );
            }
        }

        return true;
    }

    function processDrawMatch(address registry_, bool lossSimulationFlag_)
        public
        payable
        override
        nonReentrant
        returns (bool)
    {
        if (
            forwarderFlag &&
            !IConfig(registry_).getBlacklistedAsset(tokenAddress)
        ) processAaveRecovery(registry_);
        processAaveDistributionForDraw(registry_, lossSimulationFlag_);
        collectDeveloperFee(registry_);

        return true;
    }

    function processBan(address registry_, bool lossSimulationFlag_)
        public
        payable
        override
        nonReentrant
        returns (bool)
    {
        processDrawMatch(registry_, lossSimulationFlag_);

        return true;
    }

    function collectDeveloperFee(address registry_)
        public
        payable
        nonReentrant
        returns (bool)
    {
        if (tokenAddress == address(0)) {
            payable(IConfig(registry_).getAdmin()).transfer(
                address(this).balance
            );
        } else {
            uint256 _bal = IERC20(tokenAddress).balanceOf(address(this));
            IERC20(tokenAddress).transfer(IConfig(registry_).getAdmin(), _bal);
        }

        return true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;

import "./BetLiquidityHolder.sol";
import "../Interfaces/ILiquidityHolderDeployer.sol";

contract LiquidityHolderDeployer is ILiquidityHolderDeployer {
    function deployHolder() external override returns (address __holder) {
        BetLiquidityHolder _holder = new BetLiquidityHolder();
        __holder = address(_holder);
    }
}