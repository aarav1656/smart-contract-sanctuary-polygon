// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
pragma experimental ABIEncoderV2;

import './interfaces/IERC20.sol';
import './interfaces/uniswap/INonfungiblePositionManager.sol';
import './interfaces/IERC721Receiver.sol';
import './interfaces/uniswap/IUniswapV3Factory.sol';
import './interfaces/IUniswapPositionBalancerResolver.sol';
import './interfaces/chainlink/AggregatorV3Interface.sol';
import './libraries/TickAndPriceMath.sol';
import './gelato/OpsReady.sol';
import '@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol';

address constant USDC = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;
address constant WETH = 0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619;

contract PositionBalancer is IERC721Receiver, IUniswapPositionBalancerResolver, OpsReady {
  /// @notice Represents the deposit of an position NFT
  struct Deposit {
    address owner;
    uint128 liquidity;
    address token0;
    address token1;
    uint24 fee;
    int24 tickLower;
    int24 tickUpper;
  }
  /// @notice Represents the request to rebalance a position calculated offchain by the Gelato executor
  struct RebalanceRequest {
    uint256 tokenId;
    int24 newLowerTick;
    int24 newUpperTick;
  }
  /// @dev deposits[tokenId] => Deposit
  mapping(uint256 => Deposit) public deposits;
  uint256 public amountOfDeposits;
  uint256[] public positionTokenIds;
  uint256 public funds;
  address public immutable admin;

  INonfungiblePositionManager public constant nonfungiblePositionManager =
    INonfungiblePositionManager(0xC36442b4a4522E871399CD717aBDD847Ab11FE88);

  IUniswapV3Factory public constant uniswapV3Factory =
    IUniswapV3Factory(0x1F98431c8aD98523631AE4a59f267346ea31F984);

  AggregatorV3Interface public constant priceFeed =
    AggregatorV3Interface(0xF9680D99D6C9589e2a93a78A04A279e509205945);

  ISwapRouter public constant swapRouter =
    ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);

  IERC20 private constant usdc = IERC20(USDC);
  IERC20 private constant weth = IERC20(WETH);

  int24 private constant MIN_TICK = -887272;
  int24 private constant MAX_TICK = -MIN_TICK;
  // 1% fee => 200 tick spacing
  // 0.3% fee => 60 tick spacing
  // 0.05% fee = 10 tick spacing
  int24 private constant TICK_SPACING = 10;

  uint256 public priceWindowUpDown = 50 * 1e6; // 50 USDC up and down from current price => window size of 100 USDC

  event PositionAdded(uint256 indexed tokenId, address indexed owner, Deposit deposit);
  event PositionRemoved(uint256 indexed tokenId, address indexed owner, Deposit deposit);
  event PositionRebalanced(
    uint256 indexed oldTokenId,
    uint256 indexed newTokenId,
    address indexed owner,
    Deposit oldDeposit,
    Deposit newDeposit
  );

  constructor(address automationOps) OpsReady(automationOps) {
    admin = msg.sender;
  }

  receive() external payable {
    _receiveNativeToken();
  }

  fallback() external payable {
    _receiveNativeToken();
  }

  modifier onlyOpsOrOwner(uint256 tokenId) {
    require(
      deposits[tokenId].owner == msg.sender || msg.sender == ops,
      'PositionBalancer: not owner or ops'
    );
    _;
  }

  modifier onlyAdmin() {
    require(msg.sender == admin, 'PositionBalancer: not admin');
    _;
  }

  // *** EXTERNAL ***

  function withdrawNativeToken(uint256 amount) external onlyAdmin {
    require(funds >= amount, 'not enough funds');
    funds -= amount;
    payable(msg.sender).transfer(amount);
  }

  function setPriceWindow(uint256 _priceWindowUpDown) external onlyAdmin {
    require(msg.sender == admin, 'only admin');
    priceWindowUpDown = _priceWindowUpDown;
  }

  function onERC721Received(
    address operator,
    address,
    uint256 tokenId,
    bytes calldata
  ) external override returns (bytes4) {
    _createDeposit(operator, tokenId);

    return IERC721Receiver.onERC721Received.selector;
  }

  function withdrawPosition(uint256 tokenId) external onlyAdmin {
    nonfungiblePositionManager.safeTransferFrom(address(this), msg.sender, tokenId);
    delete deposits[tokenId];
    amountOfDeposits--;

    _findAndRemoveFromTokenIds(tokenId);

    emit PositionRemoved(tokenId, msg.sender, deposits[tokenId]);
  }

  function _findAndRemoveFromTokenIds(uint256 tokenId) internal {
    uint256 tokenIdIndex = 0;
    bool isFound = false;
    for (uint256 i = 0; i < positionTokenIds.length; i++) {
      if (positionTokenIds[i] == tokenId) {
        tokenIdIndex = i;
        isFound = true;
        break;
      }
    }
    if (isFound) {
      _removeFromTokenIds(tokenIdIndex);
    }
  }

  function _removeFromTokenIds(uint256 index) internal {
    uint256 tokenIdsAmount = positionTokenIds.length;
    require(index < tokenIdsAmount, 'Index out of bound');
    for (uint256 i = index; i < tokenIdsAmount - 1; i++) {
      positionTokenIds[i] = positionTokenIds[i + 1];
    }
    positionTokenIds.pop();
  }

  function checkIfShouldRebalanceAnyOfPositions()
    external
    view
    returns (bool canExec, bytes memory execPayload)
  {
    RebalanceRequest[] memory positionsToRebalance = new RebalanceRequest[](
      amountOfDeposits
    );
    uint256 positionsToRebalanceIndex = 0;
    uint256[] memory tokenIds = positionTokenIds;
    uint256 amountOfPositionsOwnedByAddress = tokenIds.length;
    for (uint256 i = 0; i < amountOfPositionsOwnedByAddress; i++) {
      uint256 tokenId = tokenIds[i];
      Deposit memory deposit = deposits[tokenId];
      bool shouldRebalance = shouldRebalancePosition(deposit);
      (int24 newLowerTick, int24 newUpperTick) = calculateNewTicks(deposit);
      if (shouldRebalance) {
        positionsToRebalance[positionsToRebalanceIndex] = RebalanceRequest({
          tokenId: tokenId,
          newLowerTick: newLowerTick,
          newUpperTick: newUpperTick
        });
        positionsToRebalanceIndex++;
      }
    }

    if (positionsToRebalance.length == 0) {
      return (false, '');
    }

    canExec = true;
    execPayload = abi.encodeWithSelector(
      this.rebalancePositions.selector,
      positionsToRebalance
    );
  }

  function mintNewPosition(
    uint256 amount0ToAdd,
    uint256 amount1ToAdd,
    int24 tickLower,
    int24 tickUpper
  )
    external
    onlyAdmin
    returns (
      uint256 tokenId,
      uint128 liquidity,
      uint256 amount0,
      uint256 amount1
    )
  {
    _getCoinsFromDepositor(msg.sender, amount0ToAdd, amount1ToAdd);

    return _mintPosition(msg.sender, amount0ToAdd, amount1ToAdd, tickLower, tickUpper);
  }

  // *** PUBLIC ***

  function shouldRebalancePosition(Deposit memory deposit) public view returns (bool) {
    address pool = uniswapV3Factory.getPool(deposit.token0, deposit.token1, deposit.fee);
    require(pool != address(0), 'pool does not exist');

    int24 currentTick = TickAndPriceMath.getCurrentTick(pool);

    // if it's above or below both ticks, rebalance
    if (
      (currentTick > deposit.tickUpper && currentTick > deposit.tickLower) ||
      (currentTick < deposit.tickUpper && currentTick < deposit.tickLower)
    ) {
      return true;
    }

    return false;
  }

  function rebalancePositions(RebalanceRequest[] calldata rebalanceRequests)
    public
    onlyOps
  {
    for (uint256 i = 0; i < rebalanceRequests.length; i++) {
      rebalancePosition(rebalanceRequests[i]);
    }
    // pay for automation transaction fee
    _payForTx();
  }

  function rebalancePosition(RebalanceRequest memory rebalanceRequest)
    public
    onlyOpsOrOwner(rebalanceRequest.tokenId)
  {
    Deposit memory deposit = deposits[rebalanceRequest.tokenId];

    // decrease liquidity & collect fees
    (uint256 amount0, uint256 amount1) = collectAllFeesAndLiquidityForRebalance(
      rebalanceRequest.tokenId,
      deposit
    );
    // burn the existing position
    nonfungiblePositionManager.burn(rebalanceRequest.tokenId);
    // remove deposit and tokenId from storage
    delete deposits[rebalanceRequest.tokenId];
    amountOfDeposits--;
    _findAndRemoveFromTokenIds(rebalanceRequest.tokenId);
    // get the price of WETH in terms of USDC
    (, int256 price, , , ) = priceFeed.latestRoundData();
    // calculate new amounts
    (
      uint256 amount0ToBuy,
      uint256 amount1ToBuy,
      uint256 optimalAmount0,
      uint256 optimalAmount1
    ) = getAmountsToBuyForNewLiquidityPosition(price, amount0, amount1);

    // swap tokens to get an equal amount of each
    if (amount1ToBuy > 0) {
      // swap USDC for WETH
      usdc.approve(address(swapRouter), type(uint256).max);

      ISwapRouter.ExactOutputSingleParams memory params = ISwapRouter
        .ExactOutputSingleParams({
          tokenIn: USDC,
          tokenOut: WETH,
          fee: 500,
          recipient: address(this),
          deadline: block.timestamp,
          amountOut: amount1ToBuy,
          amountInMaximum: type(uint256).max,
          sqrtPriceLimitX96: 0
        });
      swapRouter.exactOutputSingle(params);
    }
    if (amount0ToBuy > 0) {
      // swap WETH for USDC
      weth.approve(address(swapRouter), type(uint256).max);

      ISwapRouter.ExactOutputSingleParams memory params = ISwapRouter
        .ExactOutputSingleParams({
          tokenIn: WETH,
          tokenOut: USDC,
          fee: 500,
          recipient: address(this),
          deadline: block.timestamp,
          amountOut: amount0ToBuy,
          amountInMaximum: type(uint256).max,
          sqrtPriceLimitX96: 0
        });
      swapRouter.exactOutputSingle(params);
    }

    (uint256 newTokenId, , , ) = _mintPosition(
      deposit.owner,
      optimalAmount0,
      optimalAmount1,
      rebalanceRequest.newLowerTick,
      rebalanceRequest.newUpperTick
    );
    emit PositionRebalanced(
      rebalanceRequest.tokenId,
      newTokenId,
      deposit.owner,
      deposit,
      deposits[newTokenId]
    );
  }

  function collectAllFees(uint256 tokenId)
    public
    onlyAdmin
    returns (uint256 amount0, uint256 amount1)
  {
    return _collectFees(tokenId, msg.sender);
  }

  function getAmountsToBuyForNewLiquidityPosition(
    int256 priceOfToken1InToken0,
    uint256 amount0,
    uint256 amount1
  )
    public
    pure
    returns (
      uint256 amount0ToBuy,
      uint256 amount1ToBuy,
      uint256 optimalAmount0,
      uint256 optimalAmount1
    )
  {
    // ETH/USD oracle returns price with 8 decimals
    uint256 wethPriceInUsdc = uint256(priceOfToken1InToken0) / 10**2; // we want to get 6 decimals so we divide by 10**2
    // get the USDC balance and WETH balance and multiply WETH balance by price to get two values based in USDC
    uint256 valueOfAmount0InUsdc18Decimals = amount0 * 1e12;
    uint256 valueOfAmount1InUsdc18Decimals = (amount1 * wethPriceInUsdc) / 1e6; // divide by 1e6 because of usdc decimals
    // add these values and divide by 2 to get the optimal amount of each token to deposit
    uint256 singleValueInUsdc18Decimals = (valueOfAmount0InUsdc18Decimals +
      valueOfAmount1InUsdc18Decimals) / 2;
    // if the optimal amount of USDC is greater than the current amount of USDC, we need to buy more
    if (singleValueInUsdc18Decimals > valueOfAmount0InUsdc18Decimals) {
      amount0ToBuy =
        (singleValueInUsdc18Decimals - valueOfAmount0InUsdc18Decimals) /
        1e12; // divide by 1e12 to get 6 decimals
    }
    optimalAmount0 = singleValueInUsdc18Decimals / 1e12;
    // if the optimal amount of WETH is greater than the current amount of WETH, we need to buy more
    if (singleValueInUsdc18Decimals > valueOfAmount1InUsdc18Decimals) {
      amount1ToBuy =
        ((singleValueInUsdc18Decimals - valueOfAmount1InUsdc18Decimals) /
          wethPriceInUsdc) *
        1e6;
    }
    optimalAmount1 = (singleValueInUsdc18Decimals / wethPriceInUsdc) * 1e6;
  }

  // *** INTERNAL ***

  function _createDeposit(address owner, uint256 tokenId) internal {
    (
      ,
      ,
      address token0,
      address token1,
      uint24 fee,
      int24 tickLower,
      int24 tickUpper,
      uint128 liquidity,
      ,
      ,
      ,

    ) = nonfungiblePositionManager.positions(tokenId);

    deposits[tokenId] = Deposit({
      owner: owner,
      liquidity: liquidity,
      token0: token0,
      token1: token1,
      fee: fee,
      tickLower: tickLower,
      tickUpper: tickUpper
    });
    amountOfDeposits++;

    positionTokenIds.push(tokenId);

    emit PositionAdded(tokenId, owner, deposits[tokenId]);
  }

  function _receiveNativeToken() internal {
    if (msg.value > 0) {
      funds += msg.value;
    }
  }

  function _getCoinsFromDepositor(
    address depositor,
    uint256 amount0ToAdd,
    uint256 amount1ToAdd
  ) internal {
    usdc.transferFrom(depositor, address(this), amount0ToAdd);
    weth.transferFrom(depositor, address(this), amount1ToAdd);
  }

  function _approveCoinsToPositionManager(uint256 amount0ToAdd, uint256 amount1ToAdd)
    internal
  {
    usdc.approve(address(nonfungiblePositionManager), amount0ToAdd);
    weth.approve(address(nonfungiblePositionManager), amount1ToAdd);
  }

  function _mintPosition(
    address owner,
    uint256 amount0ToAdd,
    uint256 amount1ToAdd,
    int24 tickLower,
    int24 tickUpper
  )
    internal
    returns (
      uint256 tokenId,
      uint128 liquidity,
      uint256 amount0,
      uint256 amount1
    )
  {
    uint256 wethBalance = weth.balanceOf(address(this));
    uint256 usdcBalance = usdc.balanceOf(address(this));
    amount0ToAdd = amount0ToAdd > usdcBalance ? usdcBalance : amount0ToAdd;
    amount1ToAdd = amount1ToAdd > wethBalance ? wethBalance : amount1ToAdd;

    _approveCoinsToPositionManager(amount0ToAdd, amount1ToAdd);

    (tickLower, tickUpper) = tickLower > tickUpper
      ? (tickUpper, tickLower)
      : (tickLower, tickUpper);

    INonfungiblePositionManager.MintParams memory params = INonfungiblePositionManager
      .MintParams({
        token0: USDC,
        token1: WETH,
        fee: 500,
        tickLower: (tickLower / TICK_SPACING) * TICK_SPACING,
        tickUpper: (tickUpper / TICK_SPACING) * TICK_SPACING,
        amount0Desired: amount0ToAdd,
        amount1Desired: amount1ToAdd,
        amount0Min: 0,
        amount1Min: 0,
        recipient: address(this),
        deadline: block.timestamp
      });

    (tokenId, liquidity, amount0, amount1) = nonfungiblePositionManager.mint(params);

    _createDeposit(owner, tokenId);

    if (amount0 < amount0ToAdd) {
      usdc.approve(address(nonfungiblePositionManager), 0);
      uint256 refund0 = amount0ToAdd - amount0;
      usdc.transfer(owner, refund0);
    }
    if (amount1 < amount1ToAdd) {
      weth.approve(address(nonfungiblePositionManager), 0);
      uint256 refund1 = amount1ToAdd - amount1;
      weth.transfer(owner, refund1);
    }
  }

  function collectAllFeesAndLiquidityForRebalance(uint256 tokenId, Deposit memory deposit)
    internal
    returns (uint256 amount0, uint256 amount1)
  {
    decreaseLiquidity(tokenId, deposit.liquidity);
    (amount0, amount1) = _collectFees(tokenId, address(this));
  }

  function _collectFees(uint256 tokenId, address recipient)
    internal
    returns (uint256 amount0, uint256 amount1)
  {
    INonfungiblePositionManager.CollectParams memory params = INonfungiblePositionManager
      .CollectParams({
        tokenId: tokenId,
        recipient: recipient,
        amount0Max: type(uint128).max,
        amount1Max: type(uint128).max
      });

    (amount0, amount1) = nonfungiblePositionManager.collect(params);
  }

  function decreaseLiquidity(uint256 tokenId, uint128 liquidity)
    internal
    returns (uint256 amount0, uint256 amount1)
  {
    INonfungiblePositionManager.DecreaseLiquidityParams
      memory params = INonfungiblePositionManager.DecreaseLiquidityParams({
        tokenId: tokenId,
        liquidity: liquidity,
        amount0Min: 0,
        amount1Min: 0,
        deadline: block.timestamp
      });

    (amount0, amount1) = nonfungiblePositionManager.decreaseLiquidity(params);
  }

  function calculateNewTicks(Deposit memory deposit)
    internal
    view
    returns (int24 newLowerTick, int24 newUpperTick)
  {
    address pool = uniswapV3Factory.getPool(deposit.token0, deposit.token1, deposit.fee);
    require(pool != address(0), 'pool does not exist');
    int24 currentTick = TickAndPriceMath.getCurrentTick(pool);
    // token0 is USDC
    // token1 is WETH
    uint256 ONE_WETH = 1e18;
    // USDC has 6 decimals while WETH has 18
    uint256 currentWethPriceInUSDC = TickAndPriceMath.getPriceAtTick(
      currentTick,
      uint128(ONE_WETH),
      deposit.token1,
      deposit.token0
    );
    // calculate if price is above upper band of liquidity range
    newUpperTick = TickAndPriceMath.getTickFromPrice(
      currentWethPriceInUSDC,
      currentTick,
      currentWethPriceInUSDC + priceWindowUpDown,
      TICK_SPACING,
      uint128(ONE_WETH),
      deposit.token1,
      deposit.token0
    );

    newLowerTick = TickAndPriceMath.getTickFromPrice(
      currentWethPriceInUSDC,
      currentTick,
      currentWethPriceInUSDC - priceWindowUpDown,
      TICK_SPACING,
      uint128(ONE_WETH),
      deposit.token1,
      deposit.token0
    );
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IERC721Receiver {
  function onERC721Received(
    address operator,
    address from,
    uint256 tokenId,
    bytes calldata data
  ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IUniswapPositionBalancerResolver {
  // This function should get the position ticks from the NFT, and then
  // check the price of a pair with Uniswap V3's TWAP oracle. If the price is
  // above the upper or lower tick, it should return true which means that rebalance
  // is needed. If the price is between the ticks, it should return false.
  function checkIfShouldRebalanceAnyOfPositions()
    external
    view
    returns (bool canExec, bytes memory execPayload);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import '@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol';
import './TickMath.sol';
import './FullMath.sol';

library TickAndPriceMath {
  int24 private constant MIN_TICK = -887272;
  int24 private constant MAX_TICK = -MIN_TICK;

  function getCurrentTick(address pool) internal view returns (int24 tick) {
    uint32 secondsAgo = 10; // always calculate the price from the latest block

    uint32[] memory secondsAgos = new uint32[](2);
    secondsAgos[0] = secondsAgo;
    secondsAgos[1] = 0;

    (int56[] memory tickCumulatives, ) = IUniswapV3Pool(pool).observe(secondsAgos);

    int56 tickCumulativesDelta = tickCumulatives[1] - tickCumulatives[0];

    tick = int24(tickCumulativesDelta / int56(uint56(secondsAgo)));
    // Always round to negative infinity
    if (
      tickCumulativesDelta < 0 && (tickCumulativesDelta % int56(uint56(secondsAgo)) != 0)
    ) {
      tick--;
    }
  }

  function getPriceAtTick(
    int24 tick,
    uint128 baseAmount,
    address baseToken,
    address quoteToken
  ) internal pure returns (uint256 quoteAmount) {
    uint160 sqrtRatioX96 = TickMath.getSqrtRatioAtTick(tick);

    // Calculate quoteAmount with better precision if it doesn't overflow when multiplied by itself
    if (sqrtRatioX96 <= type(uint128).max) {
      uint256 ratioX192 = uint256(sqrtRatioX96) * sqrtRatioX96;
      quoteAmount = baseToken < quoteToken
        ? FullMath.mulDiv(ratioX192, baseAmount, 1 << 192)
        : FullMath.mulDiv(1 << 192, baseAmount, ratioX192);
    } else {
      uint256 ratioX128 = FullMath.mulDiv(sqrtRatioX96, sqrtRatioX96, 1 << 64);
      quoteAmount = baseToken < quoteToken
        ? FullMath.mulDiv(ratioX128, baseAmount, 1 << 128)
        : FullMath.mulDiv(1 << 128, baseAmount, ratioX128);
    }
  }

  /// @notice Calculates the tick for a given price. Very primitive approach, but works for now.
  /// It's only called only in a view function so we don't care about gas costs.
  function getTickFromPrice(
    uint256 currentPrice,
    int24 currentTick,
    uint256 desiredPrice,
    int24 tickSpacing,
    uint128 baseAmount,
    address baseToken,
    address quoteToken
  ) internal pure returns (int24 tick) {
    if (currentPrice > desiredPrice) {
      for (int24 i = currentTick; i > MIN_TICK; i += tickSpacing) {
        uint256 price = getPriceAtTick(i, baseAmount, baseToken, quoteToken);
        if (price < desiredPrice) {
          tick = i;
          break;
        }
      }
    } else {
      for (int24 i = currentTick; i < MAX_TICK; i -= tickSpacing) {
        uint256 price = getPriceAtTick(i, baseAmount, baseToken, quoteToken);
        if (price > desiredPrice) {
          tick = i;
          break;
        }
      }
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IERC20 {
  function totalSupply() external view returns (uint256);

  function balanceOf(address account) external view returns (uint256);

  function transfer(address recipient, uint256 amount) external returns (bool);

  function allowance(address owner, address spender) external view returns (uint256);

  function approve(address spender, uint256 amount) external returns (bool);

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from '../interfaces/IERC20.sol';

interface IOps {
  function gelato() external view returns (address payable);

  function getFeeDetails() external view returns (uint256, address);
}

abstract contract OpsReady {
  address public immutable ops;
  address payable public immutable gelato;
  address public constant MATIC = 0x0000000000000000000000000000000000001010;

  modifier onlyOps() {
    require(msg.sender == ops, 'OpsReady: onlyOps');
    _;
  }

  constructor(address _ops) {
    ops = _ops;
    gelato = IOps(_ops).gelato();
  }

  function _payForTx() internal returns (bool success) {
    (uint256 feeAmount, address paymentToken) = IOps(ops).getFeeDetails();

    if (paymentToken == MATIC) {
      (success, ) = gelato.call{value: feeAmount}('');
      require(success, '_payForTx: MATIC transfer failed');
    } else {
      IERC20(paymentToken).transfer(gelato, feeAmount);
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface AggregatorV3Interface {
  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 anwser,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface INonfungiblePositionManager {
  struct MintParams {
    address token0;
    address token1;
    uint24 fee;
    int24 tickLower;
    int24 tickUpper;
    uint256 amount0Desired;
    uint256 amount1Desired;
    uint256 amount0Min;
    uint256 amount1Min;
    address recipient;
    uint256 deadline;
  }

  function mint(MintParams calldata params)
    external
    payable
    returns (
      uint256 tokenId,
      uint128 liquidity,
      uint256 amount0,
      uint256 amount1
    );

  function burn(uint256 tokenId) external payable;

  struct IncreaseLiquidityParams {
    uint256 tokenId;
    uint256 amount0Desired;
    uint256 amount1Desired;
    uint256 amount0Min;
    uint256 amount1Min;
    uint256 deadline;
  }

  function increaseLiquidity(IncreaseLiquidityParams calldata params)
    external
    payable
    returns (
      uint128 liquidity,
      uint256 amount0,
      uint256 amount1
    );

  struct DecreaseLiquidityParams {
    uint256 tokenId;
    uint128 liquidity;
    uint256 amount0Min;
    uint256 amount1Min;
    uint256 deadline;
  }

  function decreaseLiquidity(DecreaseLiquidityParams calldata params)
    external
    payable
    returns (uint256 amount0, uint256 amount1);

  struct CollectParams {
    uint256 tokenId;
    address recipient;
    uint128 amount0Max;
    uint128 amount1Max;
  }

  function collect(CollectParams calldata params)
    external
    payable
    returns (uint256 amount0, uint256 amount1);

  function positions(uint256 tokenId)
    external
    view
    returns (
      uint96 nonce,
      address operator,
      address token0,
      address token1,
      uint24 fee,
      int24 tickLower,
      int24 tickUpper,
      uint128 liquidity,
      uint256 feeGrowthInside0LastX128,
      uint256 feeGrowthInside1LastX128,
      uint128 tokensOwed0,
      uint128 tokensOwed1
    );

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) external;

  function ownerOf(uint256 tokenId) external view returns (address owner);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IUniswapV3Factory {
  function getPool(
    address tokenA,
    address tokenB,
    uint24 fee
  ) external view returns (address pool);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

import '@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol';

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface ISwapRouter is IUniswapV3SwapCallback {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

library TickMath {
  /// @dev The minimum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**-128
  int24 internal constant MIN_TICK = -887272;
  /// @dev The maximum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**128
  int24 internal constant MAX_TICK = -MIN_TICK;

  /// @dev The minimum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MIN_TICK)
  uint160 internal constant MIN_SQRT_RATIO = 4295128739;
  /// @dev The maximum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MAX_TICK)
  uint160 internal constant MAX_SQRT_RATIO =
    1461446703485210103287273052203988822378723970342;

  /// @notice Calculates sqrt(1.0001^tick) * 2^96
  /// @dev Throws if |tick| > max tick
  /// @param tick The input tick for the above formula
  /// @return sqrtPriceX96 A Fixed point Q64.96 number representing the sqrt of the ratio of the two assets (token1/token0)
  /// at the given tick
  function getSqrtRatioAtTick(int24 tick) internal pure returns (uint160 sqrtPriceX96) {
    uint256 absTick = tick < 0 ? uint256(-int256(tick)) : uint256(int256(tick));
    require(absTick <= uint256(uint24(MAX_TICK)), 'T');

    uint256 ratio = absTick & 0x1 != 0
      ? 0xfffcb933bd6fad37aa2d162d1a594001
      : 0x100000000000000000000000000000000;
    if (absTick & 0x2 != 0) ratio = (ratio * 0xfff97272373d413259a46990580e213a) >> 128;
    if (absTick & 0x4 != 0) ratio = (ratio * 0xfff2e50f5f656932ef12357cf3c7fdcc) >> 128;
    if (absTick & 0x8 != 0) ratio = (ratio * 0xffe5caca7e10e4e61c3624eaa0941cd0) >> 128;
    if (absTick & 0x10 != 0) ratio = (ratio * 0xffcb9843d60f6159c9db58835c926644) >> 128;
    if (absTick & 0x20 != 0) ratio = (ratio * 0xff973b41fa98c081472e6896dfb254c0) >> 128;
    if (absTick & 0x40 != 0) ratio = (ratio * 0xff2ea16466c96a3843ec78b326b52861) >> 128;
    if (absTick & 0x80 != 0) ratio = (ratio * 0xfe5dee046a99a2a811c461f1969c3053) >> 128;
    if (absTick & 0x100 != 0) ratio = (ratio * 0xfcbe86c7900a88aedcffc83b479aa3a4) >> 128;
    if (absTick & 0x200 != 0) ratio = (ratio * 0xf987a7253ac413176f2b074cf7815e54) >> 128;
    if (absTick & 0x400 != 0) ratio = (ratio * 0xf3392b0822b70005940c7a398e4b70f3) >> 128;
    if (absTick & 0x800 != 0) ratio = (ratio * 0xe7159475a2c29b7443b29c7fa6e889d9) >> 128;
    if (absTick & 0x1000 != 0)
      ratio = (ratio * 0xd097f3bdfd2022b8845ad8f792aa5825) >> 128;
    if (absTick & 0x2000 != 0)
      ratio = (ratio * 0xa9f746462d870fdf8a65dc1f90e061e5) >> 128;
    if (absTick & 0x4000 != 0)
      ratio = (ratio * 0x70d869a156d2a1b890bb3df62baf32f7) >> 128;
    if (absTick & 0x8000 != 0)
      ratio = (ratio * 0x31be135f97d08fd981231505542fcfa6) >> 128;
    if (absTick & 0x10000 != 0)
      ratio = (ratio * 0x9aa508b5b7a84e1c677de54f3e99bc9) >> 128;
    if (absTick & 0x20000 != 0) ratio = (ratio * 0x5d6af8dedb81196699c329225ee604) >> 128;
    if (absTick & 0x40000 != 0) ratio = (ratio * 0x2216e584f5fa1ea926041bedfe98) >> 128;
    if (absTick & 0x80000 != 0) ratio = (ratio * 0x48a170391f7dc42444e8fa2) >> 128;

    if (tick > 0) ratio = type(uint256).max / ratio;

    // this divides by 1<<32 rounding up to go from a Q128.128 to a Q128.96.
    // we then downcast because we know the result always fits within 160 bits due to our tick input constraint
    // we round up in the division so getTickAtSqrtRatio of the output price is always consistent
    sqrtPriceX96 = uint160((ratio >> 32) + (ratio % (1 << 32) == 0 ? 0 : 1));
  }

  /// @notice Calculates the greatest tick value such that getRatioAtTick(tick) <= ratio
  /// @dev Throws in case sqrtPriceX96 < MIN_SQRT_RATIO, as MIN_SQRT_RATIO is the lowest value getRatioAtTick may
  /// ever return.
  /// @param sqrtPriceX96 The sqrt ratio for which to compute the tick as a Q64.96
  /// @return tick The greatest tick for which the ratio is less than or equal to the input ratio
  function getTickAtSqrtRatio(uint160 sqrtPriceX96) internal pure returns (int24 tick) {
    // second inequality must be < because the price can never reach the price at the max tick
    require(sqrtPriceX96 >= MIN_SQRT_RATIO && sqrtPriceX96 < MAX_SQRT_RATIO, 'R');
    uint256 ratio = uint256(sqrtPriceX96) << 32;

    uint256 r = ratio;
    uint256 msb = 0;

    assembly {
      let f := shl(7, gt(r, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF))
      msb := or(msb, f)
      r := shr(f, r)
    }
    assembly {
      let f := shl(6, gt(r, 0xFFFFFFFFFFFFFFFF))
      msb := or(msb, f)
      r := shr(f, r)
    }
    assembly {
      let f := shl(5, gt(r, 0xFFFFFFFF))
      msb := or(msb, f)
      r := shr(f, r)
    }
    assembly {
      let f := shl(4, gt(r, 0xFFFF))
      msb := or(msb, f)
      r := shr(f, r)
    }
    assembly {
      let f := shl(3, gt(r, 0xFF))
      msb := or(msb, f)
      r := shr(f, r)
    }
    assembly {
      let f := shl(2, gt(r, 0xF))
      msb := or(msb, f)
      r := shr(f, r)
    }
    assembly {
      let f := shl(1, gt(r, 0x3))
      msb := or(msb, f)
      r := shr(f, r)
    }
    assembly {
      let f := gt(r, 0x1)
      msb := or(msb, f)
    }

    if (msb >= 128) r = ratio >> (msb - 127);
    else r = ratio << (127 - msb);

    int256 log_2 = (int256(msb) - 128) << 64;

    assembly {
      r := shr(127, mul(r, r))
      let f := shr(128, r)
      log_2 := or(log_2, shl(63, f))
      r := shr(f, r)
    }
    assembly {
      r := shr(127, mul(r, r))
      let f := shr(128, r)
      log_2 := or(log_2, shl(62, f))
      r := shr(f, r)
    }
    assembly {
      r := shr(127, mul(r, r))
      let f := shr(128, r)
      log_2 := or(log_2, shl(61, f))
      r := shr(f, r)
    }
    assembly {
      r := shr(127, mul(r, r))
      let f := shr(128, r)
      log_2 := or(log_2, shl(60, f))
      r := shr(f, r)
    }
    assembly {
      r := shr(127, mul(r, r))
      let f := shr(128, r)
      log_2 := or(log_2, shl(59, f))
      r := shr(f, r)
    }
    assembly {
      r := shr(127, mul(r, r))
      let f := shr(128, r)
      log_2 := or(log_2, shl(58, f))
      r := shr(f, r)
    }
    assembly {
      r := shr(127, mul(r, r))
      let f := shr(128, r)
      log_2 := or(log_2, shl(57, f))
      r := shr(f, r)
    }
    assembly {
      r := shr(127, mul(r, r))
      let f := shr(128, r)
      log_2 := or(log_2, shl(56, f))
      r := shr(f, r)
    }
    assembly {
      r := shr(127, mul(r, r))
      let f := shr(128, r)
      log_2 := or(log_2, shl(55, f))
      r := shr(f, r)
    }
    assembly {
      r := shr(127, mul(r, r))
      let f := shr(128, r)
      log_2 := or(log_2, shl(54, f))
      r := shr(f, r)
    }
    assembly {
      r := shr(127, mul(r, r))
      let f := shr(128, r)
      log_2 := or(log_2, shl(53, f))
      r := shr(f, r)
    }
    assembly {
      r := shr(127, mul(r, r))
      let f := shr(128, r)
      log_2 := or(log_2, shl(52, f))
      r := shr(f, r)
    }
    assembly {
      r := shr(127, mul(r, r))
      let f := shr(128, r)
      log_2 := or(log_2, shl(51, f))
      r := shr(f, r)
    }
    assembly {
      r := shr(127, mul(r, r))
      let f := shr(128, r)
      log_2 := or(log_2, shl(50, f))
    }

    int256 log_sqrt10001 = log_2 * 255738958999603826347141; // 128.128 number

    int24 tickLow = int24((log_sqrt10001 - 3402992956809132418596140100660247210) >> 128);
    int24 tickHi = int24(
      (log_sqrt10001 + 291339464771989622907027621153398088495) >> 128
    );

    tick = tickLow == tickHi ? tickLow : getSqrtRatioAtTick(tickHi) <= sqrtPriceX96
      ? tickHi
      : tickLow;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @title Contains 512-bit math functions
/// @notice Facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision
/// @dev Handles "phantom overflow" i.e., allows multiplication and division where an intermediate value overflows 256 bits
library FullMath {
  /// @notice Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
  /// @param a The multiplicand
  /// @param b The multiplier
  /// @param denominator The divisor
  /// @return result The 256-bit result
  /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
  function mulDiv(
    uint256 a,
    uint256 b,
    uint256 denominator
  ) internal pure returns (uint256 result) {
    // 512-bit multiply [prod1 prod0] = a * b
    // Compute the product mod 2**256 and mod 2**256 - 1
    // then use the Chinese Remainder Theorem to reconstruct
    // the 512 bit result. The result is stored in two 256
    // variables such that product = prod1 * 2**256 + prod0
    uint256 prod0; // Least significant 256 bits of the product
    uint256 prod1; // Most significant 256 bits of the product
    assembly {
      let mm := mulmod(a, b, not(0))
      prod0 := mul(a, b)
      prod1 := sub(sub(mm, prod0), lt(mm, prod0))
    }

    // Handle non-overflow cases, 256 by 256 division
    if (prod1 == 0) {
      require(denominator > 0);
      assembly {
        result := div(prod0, denominator)
      }
      return result;
    }

    // Make sure the result is less than 2**256.
    // Also prevents denominator == 0
    require(denominator > prod1);

    ///////////////////////////////////////////////
    // 512 by 256 division.
    ///////////////////////////////////////////////

    // Make division exact by subtracting the remainder from [prod1 prod0]
    // Compute remainder using mulmod
    uint256 remainder;
    assembly {
      remainder := mulmod(a, b, denominator)
    }
    // Subtract 256 bit number from 512 bit number
    assembly {
      prod1 := sub(prod1, gt(remainder, prod0))
      prod0 := sub(prod0, remainder)
    }

    // Factor powers of two out of denominator
    // Compute largest power of two divisor of denominator.
    // Always >= 1.
    uint256 twos = denominator & (~denominator + 1);
    // Divide denominator by power of two
    assembly {
      denominator := div(denominator, twos)
    }

    // Divide [prod1 prod0] by the factors of two
    assembly {
      prod0 := div(prod0, twos)
    }
    // Shift in bits from prod1 into prod0. For this we need
    // to flip `twos` such that it is 2**256 / twos.
    // If twos is zero, then it becomes one
    assembly {
      twos := add(div(sub(0, twos), twos), 1)
    }
    prod0 |= prod1 * twos;

    // Invert denominator mod 2**256
    // Now that denominator is an odd number, it has an inverse
    // modulo 2**256 such that denominator * inv = 1 mod 2**256.
    // Compute the inverse by starting with a seed that is correct
    // correct for four bits. That is, denominator * inv = 1 mod 2**4
    uint256 inv = (3 * denominator) ^ 2;
    // Now use Newton-Raphson iteration to improve the precision.
    // Thanks to Hensel's lifting lemma, this also works in modular
    // arithmetic, doubling the correct bits in each step.
    inv *= 2 - denominator * inv; // inverse mod 2**8
    inv *= 2 - denominator * inv; // inverse mod 2**16
    inv *= 2 - denominator * inv; // inverse mod 2**32
    inv *= 2 - denominator * inv; // inverse mod 2**64
    inv *= 2 - denominator * inv; // inverse mod 2**128
    inv *= 2 - denominator * inv; // inverse mod 2**256

    // Because the division is now exact we can divide by multiplying
    // with the modular inverse of denominator. This will give us the
    // correct result modulo 2**256. Since the precoditions guarantee
    // that the outcome is less than 2**256, this is the final result.
    // We don't need to compute the high bits of the result and prod1
    // is no longer required.
    result = prod0 * inv;
    return result;
  }

  /// @notice Calculates ceil(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
  /// @param a The multiplicand
  /// @param b The multiplier
  /// @param denominator The divisor
  /// @return result The 256-bit result
  function mulDivRoundingUp(
    uint256 a,
    uint256 b,
    uint256 denominator
  ) internal pure returns (uint256 result) {
    result = mulDiv(a, b, denominator);
    if (mulmod(a, b, denominator) > 0) {
      require(result < type(uint256).max);
      result++;
    }
  }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

import './pool/IUniswapV3PoolImmutables.sol';
import './pool/IUniswapV3PoolState.sol';
import './pool/IUniswapV3PoolDerivedState.sol';
import './pool/IUniswapV3PoolActions.sol';
import './pool/IUniswapV3PoolOwnerActions.sol';
import './pool/IUniswapV3PoolEvents.sol';

/// @title The interface for a Uniswap V3 Pool
/// @notice A Uniswap pool facilitates swapping and automated market making between any two assets that strictly conform
/// to the ERC20 specification
/// @dev The pool interface is broken up into many smaller pieces
interface IUniswapV3Pool is
    IUniswapV3PoolImmutables,
    IUniswapV3PoolState,
    IUniswapV3PoolDerivedState,
    IUniswapV3PoolActions,
    IUniswapV3PoolOwnerActions,
    IUniswapV3PoolEvents
{

}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that never changes
/// @notice These parameters are fixed for a pool forever, i.e., the methods will always return the same values
interface IUniswapV3PoolImmutables {
    /// @notice The contract that deployed the pool, which must adhere to the IUniswapV3Factory interface
    /// @return The contract address
    function factory() external view returns (address);

    /// @notice The first of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token0() external view returns (address);

    /// @notice The second of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token1() external view returns (address);

    /// @notice The pool's fee in hundredths of a bip, i.e. 1e-6
    /// @return The fee
    function fee() external view returns (uint24);

    /// @notice The pool tick spacing
    /// @dev Ticks can only be used at multiples of this value, minimum of 1 and always positive
    /// e.g.: a tickSpacing of 3 means ticks can be initialized every 3rd tick, i.e., ..., -6, -3, 0, 3, 6, ...
    /// This value is an int24 to avoid casting even though it is always positive.
    /// @return The tick spacing
    function tickSpacing() external view returns (int24);

    /// @notice The maximum amount of position liquidity that can use any tick in the range
    /// @dev This parameter is enforced per tick to prevent liquidity from overflowing a uint128 at any point, and
    /// also prevents out-of-range liquidity from being used to prevent adding in-range liquidity to a pool
    /// @return The max amount of liquidity per tick
    function maxLiquidityPerTick() external view returns (uint128);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that can change
/// @notice These methods compose the pool's state, and can change with any frequency including multiple times
/// per transaction
interface IUniswapV3PoolState {
    /// @notice The 0th storage slot in the pool stores many values, and is exposed as a single method to save gas
    /// when accessed externally.
    /// @return sqrtPriceX96 The current price of the pool as a sqrt(token1/token0) Q64.96 value
    /// tick The current tick of the pool, i.e. according to the last tick transition that was run.
    /// This value may not always be equal to SqrtTickMath.getTickAtSqrtRatio(sqrtPriceX96) if the price is on a tick
    /// boundary.
    /// observationIndex The index of the last oracle observation that was written,
    /// observationCardinality The current maximum number of observations stored in the pool,
    /// observationCardinalityNext The next maximum number of observations, to be updated when the observation.
    /// feeProtocol The protocol fee for both tokens of the pool.
    /// Encoded as two 4 bit values, where the protocol fee of token1 is shifted 4 bits and the protocol fee of token0
    /// is the lower 4 bits. Used as the denominator of a fraction of the swap fee, e.g. 4 means 1/4th of the swap fee.
    /// unlocked Whether the pool is currently locked to reentrancy
    function slot0()
        external
        view
        returns (
            uint160 sqrtPriceX96,
            int24 tick,
            uint16 observationIndex,
            uint16 observationCardinality,
            uint16 observationCardinalityNext,
            uint8 feeProtocol,
            bool unlocked
        );

    /// @notice The fee growth as a Q128.128 fees of token0 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal0X128() external view returns (uint256);

    /// @notice The fee growth as a Q128.128 fees of token1 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal1X128() external view returns (uint256);

    /// @notice The amounts of token0 and token1 that are owed to the protocol
    /// @dev Protocol fees will never exceed uint128 max in either token
    function protocolFees() external view returns (uint128 token0, uint128 token1);

    /// @notice The currently in range liquidity available to the pool
    /// @dev This value has no relationship to the total liquidity across all ticks
    function liquidity() external view returns (uint128);

    /// @notice Look up information about a specific tick in the pool
    /// @param tick The tick to look up
    /// @return liquidityGross the total amount of position liquidity that uses the pool either as tick lower or
    /// tick upper,
    /// liquidityNet how much liquidity changes when the pool price crosses the tick,
    /// feeGrowthOutside0X128 the fee growth on the other side of the tick from the current tick in token0,
    /// feeGrowthOutside1X128 the fee growth on the other side of the tick from the current tick in token1,
    /// tickCumulativeOutside the cumulative tick value on the other side of the tick from the current tick
    /// secondsPerLiquidityOutsideX128 the seconds spent per liquidity on the other side of the tick from the current tick,
    /// secondsOutside the seconds spent on the other side of the tick from the current tick,
    /// initialized Set to true if the tick is initialized, i.e. liquidityGross is greater than 0, otherwise equal to false.
    /// Outside values can only be used if the tick is initialized, i.e. if liquidityGross is greater than 0.
    /// In addition, these values are only relative and must be used only in comparison to previous snapshots for
    /// a specific position.
    function ticks(int24 tick)
        external
        view
        returns (
            uint128 liquidityGross,
            int128 liquidityNet,
            uint256 feeGrowthOutside0X128,
            uint256 feeGrowthOutside1X128,
            int56 tickCumulativeOutside,
            uint160 secondsPerLiquidityOutsideX128,
            uint32 secondsOutside,
            bool initialized
        );

    /// @notice Returns 256 packed tick initialized boolean values. See TickBitmap for more information
    function tickBitmap(int16 wordPosition) external view returns (uint256);

    /// @notice Returns the information about a position by the position's key
    /// @param key The position's key is a hash of a preimage composed by the owner, tickLower and tickUpper
    /// @return _liquidity The amount of liquidity in the position,
    /// Returns feeGrowthInside0LastX128 fee growth of token0 inside the tick range as of the last mint/burn/poke,
    /// Returns feeGrowthInside1LastX128 fee growth of token1 inside the tick range as of the last mint/burn/poke,
    /// Returns tokensOwed0 the computed amount of token0 owed to the position as of the last mint/burn/poke,
    /// Returns tokensOwed1 the computed amount of token1 owed to the position as of the last mint/burn/poke
    function positions(bytes32 key)
        external
        view
        returns (
            uint128 _liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );

    /// @notice Returns data about a specific observation index
    /// @param index The element of the observations array to fetch
    /// @dev You most likely want to use #observe() instead of this method to get an observation as of some amount of time
    /// ago, rather than at a specific index in the array.
    /// @return blockTimestamp The timestamp of the observation,
    /// Returns tickCumulative the tick multiplied by seconds elapsed for the life of the pool as of the observation timestamp,
    /// Returns secondsPerLiquidityCumulativeX128 the seconds per in range liquidity for the life of the pool as of the observation timestamp,
    /// Returns initialized whether the observation has been initialized and the values are safe to use
    function observations(uint256 index)
        external
        view
        returns (
            uint32 blockTimestamp,
            int56 tickCumulative,
            uint160 secondsPerLiquidityCumulativeX128,
            bool initialized
        );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Permissionless pool actions
/// @notice Contains pool methods that can be called by anyone
interface IUniswapV3PoolActions {
    /// @notice Sets the initial price for the pool
    /// @dev Price is represented as a sqrt(amountToken1/amountToken0) Q64.96 value
    /// @param sqrtPriceX96 the initial sqrt price of the pool as a Q64.96
    function initialize(uint160 sqrtPriceX96) external;

    /// @notice Adds liquidity for the given recipient/tickLower/tickUpper position
    /// @dev The caller of this method receives a callback in the form of IUniswapV3MintCallback#uniswapV3MintCallback
    /// in which they must pay any token0 or token1 owed for the liquidity. The amount of token0/token1 due depends
    /// on tickLower, tickUpper, the amount of liquidity, and the current price.
    /// @param recipient The address for which the liquidity will be created
    /// @param tickLower The lower tick of the position in which to add liquidity
    /// @param tickUpper The upper tick of the position in which to add liquidity
    /// @param amount The amount of liquidity to mint
    /// @param data Any data that should be passed through to the callback
    /// @return amount0 The amount of token0 that was paid to mint the given amount of liquidity. Matches the value in the callback
    /// @return amount1 The amount of token1 that was paid to mint the given amount of liquidity. Matches the value in the callback
    function mint(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount,
        bytes calldata data
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Collects tokens owed to a position
    /// @dev Does not recompute fees earned, which must be done either via mint or burn of any amount of liquidity.
    /// Collect must be called by the position owner. To withdraw only token0 or only token1, amount0Requested or
    /// amount1Requested may be set to zero. To withdraw all tokens owed, caller may pass any value greater than the
    /// actual tokens owed, e.g. type(uint128).max. Tokens owed may be from accumulated swap fees or burned liquidity.
    /// @param recipient The address which should receive the fees collected
    /// @param tickLower The lower tick of the position for which to collect fees
    /// @param tickUpper The upper tick of the position for which to collect fees
    /// @param amount0Requested How much token0 should be withdrawn from the fees owed
    /// @param amount1Requested How much token1 should be withdrawn from the fees owed
    /// @return amount0 The amount of fees collected in token0
    /// @return amount1 The amount of fees collected in token1
    function collect(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);

    /// @notice Burn liquidity from the sender and account tokens owed for the liquidity to the position
    /// @dev Can be used to trigger a recalculation of fees owed to a position by calling with an amount of 0
    /// @dev Fees must be collected separately via a call to #collect
    /// @param tickLower The lower tick of the position for which to burn liquidity
    /// @param tickUpper The upper tick of the position for which to burn liquidity
    /// @param amount How much liquidity to burn
    /// @return amount0 The amount of token0 sent to the recipient
    /// @return amount1 The amount of token1 sent to the recipient
    function burn(
        int24 tickLower,
        int24 tickUpper,
        uint128 amount
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Swap token0 for token1, or token1 for token0
    /// @dev The caller of this method receives a callback in the form of IUniswapV3SwapCallback#uniswapV3SwapCallback
    /// @param recipient The address to receive the output of the swap
    /// @param zeroForOne The direction of the swap, true for token0 to token1, false for token1 to token0
    /// @param amountSpecified The amount of the swap, which implicitly configures the swap as exact input (positive), or exact output (negative)
    /// @param sqrtPriceLimitX96 The Q64.96 sqrt price limit. If zero for one, the price cannot be less than this
    /// value after the swap. If one for zero, the price cannot be greater than this value after the swap
    /// @param data Any data to be passed through to the callback
    /// @return amount0 The delta of the balance of token0 of the pool, exact when negative, minimum when positive
    /// @return amount1 The delta of the balance of token1 of the pool, exact when negative, minimum when positive
    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes calldata data
    ) external returns (int256 amount0, int256 amount1);

    /// @notice Receive token0 and/or token1 and pay it back, plus a fee, in the callback
    /// @dev The caller of this method receives a callback in the form of IUniswapV3FlashCallback#uniswapV3FlashCallback
    /// @dev Can be used to donate underlying tokens pro-rata to currently in-range liquidity providers by calling
    /// with 0 amount{0,1} and sending the donation amount(s) from the callback
    /// @param recipient The address which will receive the token0 and token1 amounts
    /// @param amount0 The amount of token0 to send
    /// @param amount1 The amount of token1 to send
    /// @param data Any data to be passed through to the callback
    function flash(
        address recipient,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external;

    /// @notice Increase the maximum number of price and liquidity observations that this pool will store
    /// @dev This method is no-op if the pool already has an observationCardinalityNext greater than or equal to
    /// the input observationCardinalityNext.
    /// @param observationCardinalityNext The desired minimum number of observations for the pool to store
    function increaseObservationCardinalityNext(uint16 observationCardinalityNext) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Events emitted by a pool
/// @notice Contains all events emitted by the pool
interface IUniswapV3PoolEvents {
    /// @notice Emitted exactly once by a pool when #initialize is first called on the pool
    /// @dev Mint/Burn/Swap cannot be emitted by the pool before Initialize
    /// @param sqrtPriceX96 The initial sqrt price of the pool, as a Q64.96
    /// @param tick The initial tick of the pool, i.e. log base 1.0001 of the starting price of the pool
    event Initialize(uint160 sqrtPriceX96, int24 tick);

    /// @notice Emitted when liquidity is minted for a given position
    /// @param sender The address that minted the liquidity
    /// @param owner The owner of the position and recipient of any minted liquidity
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount The amount of liquidity minted to the position range
    /// @param amount0 How much token0 was required for the minted liquidity
    /// @param amount1 How much token1 was required for the minted liquidity
    event Mint(
        address sender,
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted when fees are collected by the owner of a position
    /// @dev Collect events may be emitted with zero amount0 and amount1 when the caller chooses not to collect fees
    /// @param owner The owner of the position for which fees are collected
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount0 The amount of token0 fees collected
    /// @param amount1 The amount of token1 fees collected
    event Collect(
        address indexed owner,
        address recipient,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount0,
        uint128 amount1
    );

    /// @notice Emitted when a position's liquidity is removed
    /// @dev Does not withdraw any fees earned by the liquidity position, which must be withdrawn via #collect
    /// @param owner The owner of the position for which liquidity is removed
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount The amount of liquidity to remove
    /// @param amount0 The amount of token0 withdrawn
    /// @param amount1 The amount of token1 withdrawn
    event Burn(
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted by the pool for any swaps between token0 and token1
    /// @param sender The address that initiated the swap call, and that received the callback
    /// @param recipient The address that received the output of the swap
    /// @param amount0 The delta of the token0 balance of the pool
    /// @param amount1 The delta of the token1 balance of the pool
    /// @param sqrtPriceX96 The sqrt(price) of the pool after the swap, as a Q64.96
    /// @param liquidity The liquidity of the pool after the swap
    /// @param tick The log base 1.0001 of price of the pool after the swap
    event Swap(
        address indexed sender,
        address indexed recipient,
        int256 amount0,
        int256 amount1,
        uint160 sqrtPriceX96,
        uint128 liquidity,
        int24 tick
    );

    /// @notice Emitted by the pool for any flashes of token0/token1
    /// @param sender The address that initiated the swap call, and that received the callback
    /// @param recipient The address that received the tokens from flash
    /// @param amount0 The amount of token0 that was flashed
    /// @param amount1 The amount of token1 that was flashed
    /// @param paid0 The amount of token0 paid for the flash, which can exceed the amount0 plus the fee
    /// @param paid1 The amount of token1 paid for the flash, which can exceed the amount1 plus the fee
    event Flash(
        address indexed sender,
        address indexed recipient,
        uint256 amount0,
        uint256 amount1,
        uint256 paid0,
        uint256 paid1
    );

    /// @notice Emitted by the pool for increases to the number of observations that can be stored
    /// @dev observationCardinalityNext is not the observation cardinality until an observation is written at the index
    /// just before a mint/swap/burn.
    /// @param observationCardinalityNextOld The previous value of the next observation cardinality
    /// @param observationCardinalityNextNew The updated value of the next observation cardinality
    event IncreaseObservationCardinalityNext(
        uint16 observationCardinalityNextOld,
        uint16 observationCardinalityNextNew
    );

    /// @notice Emitted when the protocol fee is changed by the pool
    /// @param feeProtocol0Old The previous value of the token0 protocol fee
    /// @param feeProtocol1Old The previous value of the token1 protocol fee
    /// @param feeProtocol0New The updated value of the token0 protocol fee
    /// @param feeProtocol1New The updated value of the token1 protocol fee
    event SetFeeProtocol(uint8 feeProtocol0Old, uint8 feeProtocol1Old, uint8 feeProtocol0New, uint8 feeProtocol1New);

    /// @notice Emitted when the collected protocol fees are withdrawn by the factory owner
    /// @param sender The address that collects the protocol fees
    /// @param recipient The address that receives the collected protocol fees
    /// @param amount0 The amount of token0 protocol fees that is withdrawn
    /// @param amount0 The amount of token1 protocol fees that is withdrawn
    event CollectProtocol(address indexed sender, address indexed recipient, uint128 amount0, uint128 amount1);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that is not stored
/// @notice Contains view functions to provide information about the pool that is computed rather than stored on the
/// blockchain. The functions here may have variable gas costs.
interface IUniswapV3PoolDerivedState {
    /// @notice Returns the cumulative tick and liquidity as of each timestamp `secondsAgo` from the current block timestamp
    /// @dev To get a time weighted average tick or liquidity-in-range, you must call this with two values, one representing
    /// the beginning of the period and another for the end of the period. E.g., to get the last hour time-weighted average tick,
    /// you must call it with secondsAgos = [3600, 0].
    /// @dev The time weighted average tick represents the geometric time weighted average price of the pool, in
    /// log base sqrt(1.0001) of token1 / token0. The TickMath library can be used to go from a tick value to a ratio.
    /// @param secondsAgos From how long ago each cumulative tick and liquidity value should be returned
    /// @return tickCumulatives Cumulative tick values as of each `secondsAgos` from the current block timestamp
    /// @return secondsPerLiquidityCumulativeX128s Cumulative seconds per liquidity-in-range value as of each `secondsAgos` from the current block
    /// timestamp
    function observe(uint32[] calldata secondsAgos)
        external
        view
        returns (int56[] memory tickCumulatives, uint160[] memory secondsPerLiquidityCumulativeX128s);

    /// @notice Returns a snapshot of the tick cumulative, seconds per liquidity and seconds inside a tick range
    /// @dev Snapshots must only be compared to other snapshots, taken over a period for which a position existed.
    /// I.e., snapshots cannot be compared if a position is not held for the entire period between when the first
    /// snapshot is taken and the second snapshot is taken.
    /// @param tickLower The lower tick of the range
    /// @param tickUpper The upper tick of the range
    /// @return tickCumulativeInside The snapshot of the tick accumulator for the range
    /// @return secondsPerLiquidityInsideX128 The snapshot of seconds per liquidity for the range
    /// @return secondsInside The snapshot of seconds per liquidity for the range
    function snapshotCumulativesInside(int24 tickLower, int24 tickUpper)
        external
        view
        returns (
            int56 tickCumulativeInside,
            uint160 secondsPerLiquidityInsideX128,
            uint32 secondsInside
        );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Permissioned pool actions
/// @notice Contains pool methods that may only be called by the factory owner
interface IUniswapV3PoolOwnerActions {
    /// @notice Set the denominator of the protocol's % share of the fees
    /// @param feeProtocol0 new protocol fee for token0 of the pool
    /// @param feeProtocol1 new protocol fee for token1 of the pool
    function setFeeProtocol(uint8 feeProtocol0, uint8 feeProtocol1) external;

    /// @notice Collect the protocol fee accrued to the pool
    /// @param recipient The address to which collected protocol fees should be sent
    /// @param amount0Requested The maximum amount of token0 to send, can be 0 to collect fees in only token1
    /// @param amount1Requested The maximum amount of token1 to send, can be 0 to collect fees in only token0
    /// @return amount0 The protocol fee collected in token0
    /// @return amount1 The protocol fee collected in token1
    function collectProtocol(
        address recipient,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls IUniswapV3PoolActions#swap must implement this interface
interface IUniswapV3SwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}