// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interfaces/balancer-v2/IVault.sol";
import "./interfaces/uniswap-v2/IUniswapV2Router02.sol";
import "./lib/LibAsset.sol";
import "./lib/LibBytes.sol";
import "./lib/LibSwap.sol";


contract MagpieRouter is ReentrancyGuard, Ownable, IMagpieRouter {
    using LibSwap for IMagpieRouter.SwapArgs;
    using LibAsset for address;
    using LibBytes for bytes;

    mapping(uint16 => Amm) private amms;

    function updateAmms(Amm[] calldata _amms) external override onlyOwner {
        require(_amms.length > 0, "MagpieRouter: invalid amms");
        for (uint256 i = 0; i < _amms.length; i++) {
            Amm memory amm = Amm({
                id: _amms[i].id,
                index: _amms[i].index,
                protocolIndex: _amms[i].protocolIndex
            });

            require(amm.id != address(0), "MagpieRouter: invalid amm address");
            require(amm.index > 0, "MagpieRouter: invalid amm index");
            require(
                amm.protocolIndex > 0,
                "MagpieRouter: invalid amm protocolIndex"
            );

            amms[amm.index] = amm;
        }

        emit AmmsUpdated(_amms, msg.sender);
    }

    function swap(SwapArgs memory swapArgs)
        external
        override
        returns (uint256[] memory amountOuts)
    {
        amountOuts = new uint256[](swapArgs.routes.length);
        address fromAssetAddress = swapArgs.getFromAssetAddress();
        address toAssetAddress = swapArgs.getToAssetAddress();
        uint256 startingBalance = toAssetAddress.getBalance();

        for (uint256 i = 0; i < swapArgs.routes.length; i++) {
            Route memory route = swapArgs.routes[i];
            Hop memory firstHop = route.hops[0];
            Hop memory lastHop = route.hops[route.hops.length - 1];
            require(
                fromAssetAddress == swapArgs.assets[firstHop.path[0]],
                "MagpieRouter: invalid fromAssetAddress"
            );
            require(
                toAssetAddress ==
                    swapArgs.assets[lastHop.path[lastHop.path.length - 1]],
                "MagpieRouter: invalid toAssetAddress"
            );

            amountOuts[i] = _swapRoute(
                route,
                swapArgs.assets,
                swapArgs.deadline
            );
        }

        uint256 amountOut = 0;
        for (uint256 i = 0; i < amountOuts.length; i++) {
            amountOut += amountOuts[i];
        }

        require(
            toAssetAddress.getBalance() == startingBalance + amountOut,
            "MagpieRouter: invalid amountOut"
        );

        for (uint256 j = 0; j < swapArgs.assets.length; j++) {
            require(
                swapArgs.assets[j] != address(0),
                "MagpieRouter: invalid asset - address0"
            );
        }

        require(
            amountOut >= swapArgs.amountOutMin,
            "MagpieRouter: insufficient output amount"
        );

        toAssetAddress.transfer(payable(msg.sender), amountOut);
    }

    function _swapRoute(
        Route memory route,
        address[] memory assets,
        uint256 deadline
    ) private returns (uint256) {
        require(route.hops.length > 0, "MagpieRouter: invalid hop size");
        uint256 lastAmountOut = 0;

        for (uint256 i = 0; i < route.hops.length; i++) {
            uint256 amountIn = i == 0 ? route.amountIn : lastAmountOut;
            Hop memory hop = route.hops[i];
            address toAssetAddress = assets[hop.path[hop.path.length - 1]];
            uint256 beforeSwapBalance = toAssetAddress.getBalance();
            _swapHop(amountIn, hop, assets, deadline);
            uint256 afterSwapBalance = toAssetAddress.getBalance();
            lastAmountOut = afterSwapBalance - beforeSwapBalance;
        }

        return lastAmountOut;
    }

    function _swapHop(
        uint256 amountIn,
        Hop memory hop,
        address[] memory assets,
        uint256 deadline
    ) private {
        Amm memory amm = amms[hop.ammIndex];

        require(amm.id != address(0), "MagpieRouter: invalid amm");
        require(hop.path.length > 1, "MagpieRouter: invalid path size");
        address fromAssetAddress = assets[hop.path[0]];

        if (fromAssetAddress.getAllowance(address(this), amm.id) < amountIn) {
            fromAssetAddress.approve(amm.id, type(uint256).max);
        }

        if (amm.protocolIndex == 1) {
            _swapUniswapV2(amountIn, hop, assets, deadline);
        } else if (amm.protocolIndex == 2 || amm.protocolIndex == 3) {
            _swapBalancerV2(amountIn, hop, assets, deadline);
        }
    }

    function _swapUniswapV2(
        uint256 amountIn,
        Hop memory hop,
        address[] memory assets,
        uint256 deadline
    ) private {
        Amm memory amm = amms[hop.ammIndex];
        address[] memory path = new address[](hop.path.length);
        for (uint256 i = 0; i < hop.path.length; i++) {
            path[i] = assets[hop.path[i]];
        }
        IUniswapV2Router02(amm.id)
            .swapExactTokensForTokens(
                amountIn,
                0,
                path,
                address(this),
                deadline
            );
    }

    function _swapBalancerV2(
        uint256 amountIn,
        Hop memory hop,
        address[] memory assets,
        uint256 deadline
    ) private {
        Amm memory amm = amms[hop.ammIndex];
        IVault.BatchSwapStep[] memory swaps = new IVault.BatchSwapStep[](
            hop.path.length - 1
        );
        uint256 poolIdIndex = 0;
        IAsset[] memory balancerAssets = new IAsset[](hop.path.length);
        int256[] memory limits = new int256[](hop.path.length);
        for (uint256 i = 0; i < hop.path.length - 1; i++) {
            swaps[i] = IVault.BatchSwapStep({
                poolId: hop.poolData.toBytes32(poolIdIndex),
                assetInIndex: i,
                assetOutIndex: i + 1,
                amount: i == 0 ? amountIn : 0,
                userData: "0x"
            });
            poolIdIndex += 32;
            balancerAssets[i] = IAsset(assets[hop.path[i]]);
            limits[i] = i == 0 ? int256(amountIn) : int256(0);

            if (i == hop.path.length - 2) {
                balancerAssets[i + 1] = IAsset(assets[hop.path[i + 1]]);
                limits[i + 1] = int256(0);
            }
        }
        require(
            hop.poolData.length == poolIdIndex,
            "MagpieRouter: poolData is invalid"
        );
        IVault.FundManagement memory funds = IVault.FundManagement({
            sender: address(this),
            fromInternalBalance: false,
            recipient: payable(address(this)),
            toInternalBalance: false
        });

        IVault(amm.id).batchSwap(
            IVault.SwapKind.GIVEN_IN,
            swaps,
            balancerAssets,
            funds,
            limits,
            deadline
        );
    }
}

// SPDX-License-Identifier: MIT

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

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
     * by making the `nonReentrant` function external, and make it call a
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

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./IAsset.sol";

interface IVault {

  enum SwapKind { GIVEN_IN, GIVEN_OUT }

  function swap(
    SingleSwap memory singleSwap,
    FundManagement memory funds,
    uint256 limit,
    uint256 deadline
  ) external payable returns (uint256);

  struct SingleSwap {
    bytes32 poolId;
    SwapKind kind;
    IAsset assetIn;
    IAsset assetOut;
    uint256 amount;
    bytes userData;
  }

  function batchSwap(
    SwapKind kind,
    BatchSwapStep[] memory swaps,
    IAsset[] memory assets,
    FundManagement memory funds,
    int256[] memory limits,
    uint256 deadline
  ) external payable returns (int256[] memory);

  struct BatchSwapStep {
    bytes32 poolId;
    uint256 assetInIndex;
    uint256 assetOutIndex;
    uint256 amount;
    bytes userData;
  }

  struct FundManagement {
    address sender;
    bool fromInternalBalance;
    address payable recipient;
    bool toInternalBalance;
  }

  function queryBatchSwap(
    SwapKind kind,
    BatchSwapStep[] memory swaps,
    IAsset[] memory assets,
    FundManagement memory funds
  ) external returns (int256[] memory assetDeltas);

}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.6.2;

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

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

library LibAsset {
    using LibAsset for address;

    address constant NATIVE_ASSETID = address(0);

    function isNative(address self) internal pure returns (bool) {
        return self == NATIVE_ASSETID;
    }

    function getBalance(address self) internal view returns (uint256) {
        return
            self.isNative()
                ? address(this).balance
                : IERC20(self).balanceOf(address(this));
    }

    function transferFrom(
        address self,
        address from,
        address to,
        uint256 amount
    ) internal {
        SafeERC20.safeTransferFrom(IERC20(self), from, to, amount);
    }

    function increaseAllowance(
        address self,
        address spender,
        uint256 amount
    ) internal {
        require(
            !self.isNative(),
            "LibAsset: Allowance can't be increased for native asset"
        );
        SafeERC20.safeIncreaseAllowance(IERC20(self), spender, amount);
    }

    function decreaseAllowance(
        address self,
        address spender,
        uint256 amount
    ) internal {
        require(
            !self.isNative(),
            "LibAsset: Allowance can't be decreased for native asset"
        );
        SafeERC20.safeDecreaseAllowance(IERC20(self), spender, amount);
    }

    function transfer(
        address self,
        address payable recipient,
        uint256 amount
    ) internal {
        self.isNative()
            ? Address.sendValue(recipient, amount)
            : SafeERC20.safeTransfer(IERC20(self), recipient, amount);
    }

    function approve(
        address self,
        address spender,
        uint256 amount
    ) internal {
        require(
            !self.isNative(),
            "LibAsset: Allowance can't be increased for native asset"
        );
        SafeERC20.safeApprove(IERC20(self), spender, amount);
    }

    function getAllowance(
        address self,
        address owner,
        address spender
    ) internal view returns (uint256) {
        return IERC20(self).allowance(owner, spender);
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0 <0.9.0;
import "../interfaces/IMagpieBridge.sol";

library LibBytes {
    using LibBytes for bytes;

    function toAddress(bytes memory self, uint256 start)
        internal
        pure
        returns (address)
    {
        return address(uint160(uint256(self.toBytes32(start))));
    }

    function toBool(bytes memory self, uint256 start)
        internal
        pure
        returns (bool)
    {
        return self.toUint8(start) == 1 ? true : false;
    }

    function toUint8(bytes memory self, uint256 start)
        internal
        pure
        returns (uint8)
    {
        require(self.length >= start + 1, "LibBytes: toUint8 outOfBounds");
        uint8 tempUint;

        assembly {
            tempUint := mload(add(add(self, 0x1), start))
        }

        return tempUint;
    }

    function toUint16(bytes memory self, uint256 start)
        internal
        pure
        returns (uint16)
    {
        require(self.length >= start + 2, "LibBytes: toUint16 outOfBounds");
        uint16 tempUint;

        assembly {
            tempUint := mload(add(add(self, 0x2), start))
        }

        return tempUint;
    }

    function toUint256(bytes memory self, uint256 start)
        internal
        pure
        returns (uint256)
    {
        require(self.length >= start + 32, "LibBytes: toUint256 outOfBounds");
        uint256 tempUint;

        assembly {
            tempUint := mload(add(add(self, 0x20), start))
        }

        return tempUint;
    }

    function toBytes32(bytes memory self, uint256 start)
        internal
        pure
        returns (bytes32)
    {
        require(self.length >= start + 32, "LibBytes: toBytes32 outOfBounds");
        bytes32 tempBytes32;

        assembly {
            tempBytes32 := mload(add(add(self, 0x20), start))
        }

        return tempBytes32;
    }

    function toBridgeType(bytes memory self, uint256 start)
        internal
        pure
        returns (IMagpieBridge.BridgeType)
    {
        require(self.length >= start + 1, "LibBytes: toBridgeType outOfBounds");
        IMagpieBridge.BridgeType tempBridgeType;

        assembly {
            tempBridgeType := mload(add(add(self, 0x1), start))
        }

        return tempBridgeType;
    }

    function parse(bytes memory self)
        internal
        pure
        returns (IMagpieBridge.ValidationOutPayload memory payload)
    {
        uint256 i = 0;

        payload.fromAssetAddress = self.toAddress(i);
        i += 32;

        payload.toAssetAddress = self.toAddress(i);
        i += 32;

        payload.to = self.toAddress(i);
        i += 32;

        payload.recipientCoreAddress = self.toAddress(i);
        i += 32;

        payload.amountOutMin = self.toUint256(i);
        i += 32;

        payload.swapOutGasFee = self.toUint256(i);
        i += 32;

        payload.destGasTokenAmount = self.toUint256(i);
        i += 32;

        payload.destGasTokenAmountOutMin = self.toUint256(i);
        i += 32;

        payload.amountIn = self.toUint256(i);
        i += 32;

        payload.senderIntermediaryDecimals = self.toUint8(i);
        i += 1;

        payload.senderNetworkId = self.toUint8(i);
        i += 1;

        payload.recipientNetworkId = self.toUint8(i);
        i += 1;

        payload.bridgeType = self.toBridgeType(i);
        i += 1;

        
        require(self.length == i, "LibBytes: payload is invalid");
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0 <0.9.0;

import "../interfaces/IMagpieCore.sol";
import "../interfaces/IMagpieRouter.sol";
import "../interfaces/IWETH.sol";
import "./LibAsset.sol";

library LibSwap {
    using LibAsset for address;
    using LibSwap for IMagpieRouter.SwapArgs;

    function getFromAssetAddress(IMagpieRouter.SwapArgs memory self)
        internal
        pure
        returns (address)
    {
        return self.assets[self.routes[0].hops[0].path[0]];
    }

    function getToAssetAddress(IMagpieRouter.SwapArgs memory self)
        internal
        pure
        returns (address)
    {
        IMagpieRouter.Hop memory hop = self.routes[0].hops[
            self.routes[0].hops.length - 1
        ];
        return self.assets[hop.path[hop.path.length - 1]];
    }

    function getAmountIn(IMagpieRouter.SwapArgs memory self)
        internal
        pure
        returns (uint256)
    {
        uint256 amountIn = 0;

        for (uint256 i = 0; i < self.routes.length; i++) {
            amountIn += self.routes[i].amountIn;
        }

        return amountIn;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
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

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0 <0.9.0;

/**
 * @dev This is an empty interface used to represent either ERC20-conforming token contracts or ETH (using the zero
 * address sentinel value). We're just relying on the fact that `interface` can be used to declare new address-like
 * types.
 *
 * This concept is unrelated to a Pool's Asset Managers.
 */
interface IAsset {
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.6.2;

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

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
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
    ) external returns (uint256 amountToken, uint256 amountETH);

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

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
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
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
        return _verifyCallResult(success, returndata, errorMessage);
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
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
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

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0 <0.9.0;

interface IMagpieBridge {
    enum BridgeType {
        Wormhole,
        Hyphen
    }

    enum DepositHashStatus {
      Pending,
      Approved,
      Successful
    }

    struct ValidationInPayload {
        bytes32 fromAssetAddress;
        bytes32 toAssetAddress;
        bytes32 to;
        uint256 amountOutMin;
        bytes32 recipientCoreAddress;
        uint256 recipientChainId;
        uint16 recipientBridgeChainId;
        uint256 swapOutGasFee;
        uint256 destGasTokenAmount;
        uint256 destGasTokenAmountOutMin;
        uint8 recipientNetworkId;
    }

    struct ValidationOutPayload {
        address fromAssetAddress;
        address toAssetAddress;
        address to;
        address recipientCoreAddress;
        uint256 amountOutMin;
        uint256 swapOutGasFee;
        uint256 destGasTokenAmount;
        uint256 destGasTokenAmountOutMin;
        uint256 amountIn;
        uint8 senderIntermediaryDecimals;
        uint8 senderNetworkId;
        uint8 recipientNetworkId;
        BridgeType bridgeType;
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0 <0.9.0;

import "./IMagpieRouter.sol";
import "./IMagpieBridge.sol";

interface IMagpieCore {
    struct Config {
        address weth;
        address pauserAddress;
        address relayerAddress;
        address magpieRouterAddress;
        address hyphenLiquidityPoolAddress;
        address tokenBridgeAddress;
        address coreBridgeAddress;
        address[] senderIntermediaries;
        address[] receiverIntermediaries;
        uint256 hyphenBaseDivisor;
        uint8 consistencyLevel;
        uint8 networkId;
    }

    struct SwapInArgs {
        IMagpieRouter.SwapArgs swapArgs;
        IMagpieBridge.ValidationInPayload payload;
        IMagpieBridge.BridgeType bridgeType;
    }

    struct SwapOutArgs {
        IMagpieRouter.SwapArgs swapArgs;
        IMagpieRouter.SwapArgs gasTokenSwapArgs;
        bytes encodedVmBridge;
        bytes encodedVmCore;
        bytes depositHash;
    }

    struct WrapSwapConfig {
        bool transferFromSender;
        bool prepareFromAsset;
        bool prepareToAsset;
        bool unwrapToAsset;
        bool swap;
    }

    function updateConfig(Config calldata config) external;

    function swap(IMagpieRouter.SwapArgs calldata args)
        external
        payable
        returns (uint256[] memory amountOuts, uint256 estimatedGas);

    function swapIn(SwapInArgs calldata swapArgs)
        external
        payable
        returns (
            uint256[] memory amountOuts,
            uint64,
            uint64
        );

    function swapOut(SwapOutArgs calldata args)
        external
        returns (uint256[] memory amountOuts);

    event ConfigUpdated(Config config, address caller);

    event Swapped(uint256[] amountOuts);

    event SwappedIn(
        SwapInArgs args,
        uint256[] amountOuts,
        uint8 receipientNetworkId,
        uint64 coreSequence,
        uint64 tokenSequence,
        address caller
    );

    event SwappedOut(
        SwapOutArgs args,
        uint256[] amountOuts,
        uint8 senderNetworkId,
        uint64 coreSequence,
        address caller
    );

    event GasFeeWithdraw(
        address indexed tokenAddress,
        address indexed owner,
        uint256 indexed amount
    );
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0 <0.9.0;

interface IMagpieRouter {
    struct Amm {
        address id;
        uint16 index;
        uint8 protocolIndex;
    }

    struct Hop {
        uint16 ammIndex;
        uint8[] path;
        bytes poolData;
    }

    struct Route {
        uint256 amountIn;
        Hop[] hops;
    }

    struct SwapArgs {
        Route[] routes;
        address[] assets;
        address payable to;
        uint256 amountOutMin;
        uint256 deadline;
    }

    function updateAmms(Amm[] calldata amms) external;

    function swap(SwapArgs memory swapArgs) external returns (uint256[] memory amountOuts);

    event AmmsUpdated(Amm[] amms, address caller);
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.5.0;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}