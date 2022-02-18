// SPDX-License-Identifier: UNLICENCED
pragma solidity 0.8.4;
pragma abicoder v2;

import {
  IUniswapV2Router02,
  IUniswapV2Factory,
  IUniswapV2Pair,
  IUniswapV2Callee
} from "../../../shared/interfaces/IUniswapV2.sol";
import {AppStore, Storage} from "../../../AppStore.sol";
import {Utils} from "../../../shared/libraries/Utils.sol";

contract UniswapV2HelperFacet is IUniswapV2Callee {
  AppStore internal s;

  // It is extremely highly suggested that you retrieve prices offline or at least and on-chain oracle
  function singleTokenSwap (
    address _router,
    address[] memory _tokenPair,
    uint[] memory _amounts,
    address _to,
    bytes calldata _data
  ) public {
    Storage.UniswapV2Exchange memory exchange = populateExchange(_router);
    Storage.UniswapV2TokenPair memory tokenPair = populateTokenPair(exchange, _tokenPair);
    // IERC20(_tokenPair[0]).transferFrom(msg.sender, address(tokenPair.pair), )
    
    tokenPair.pair.swap(_amounts[0], _amounts[1], _to, _data);
  }

  function wrapETH (address _to, uint amount) public {
    require(amount > 0, "ATTEMPTING TO WRAP ZERO ETH");
    require(address(this).balance >= amount, "OVER ESTIMATED ETH AMOUNT");
    
  }
  function multiTokenSwap (
    address[] memory _routers,
    address[][] memory _tokenPairs,
    uint[][] memory _amounts,
    address _to,
    bytes[] calldata _data

  ) public {
    uint len = _tokenPairs.length;
    require(len == _amounts.length && len == _data.length, "INCONSIST PAIR AND AMOUNT LENGTHS");
    uint i;

    for (i; i < len; i++) {
      singleTokenSwap(_routers[i], _tokenPairs[i], _amounts[i], _to, _data[i]);
    }
  }
  function tokenToLiquiditiy (address _router, address baseToken, address[] memory liquidityTokens, uint amountBaseToken) 
    public view returns(uint amounts) 
  {
    require(baseToken != Utils.ZERO_ADDRESS, "INVALID ADDRESS: ZERO_ADDRESS");
    require(liquidityTokens[0] != Utils.ZERO_ADDRESS, "INVALID ADDRESS: ZERO_ADDRESS");
    require(liquidityTokens[1] != Utils.ZERO_ADDRESS, "INVALID ADDRESS: ZERO_ADDRESS");

    Storage.UniswapV2Exchange memory exchange = populateExchange(_router);
    Storage.UniswapV2TokenPair memory tokenPair = populateTokenPair(exchange, liquidityTokens);

  }

  function populateExchange(address _router) internal pure returns(Storage.UniswapV2Exchange memory exchange){
    exchange.router = IUniswapV2Router02(_router);
    exchange.factory = IUniswapV2Factory(exchange.router.factory());
  }
  function populateTokenPair (Storage.UniswapV2Exchange memory exchange, address[] memory liquidityTokens) 
    internal view returns (Storage.UniswapV2TokenPair memory tokenPair) 
  {

    tokenPair.path = liquidityTokens;

    address tokenPairAddress = exchange.factory.getPair(tokenPair.path[0], tokenPair.path[1]);
    require(tokenPairAddress != Utils.ZERO_ADDRESS, "Token Pair does noe exist");
    tokenPair.pair = IUniswapV2Pair(tokenPairAddress);

  }

  function uniswapV2Call(address sender, uint amount0, uint amount1, bytes calldata data) public override {
    (address _factory) = abi.decode(data, (address));

    address token0 = IUniswapV2Pair(msg.sender).token0(); // fetch the address of token0
    address token1 = IUniswapV2Pair(msg.sender).token1(); // fetch the address of token1
    assert(msg.sender == IUniswapV2Factory(_factory).getPair(token0, token1)); // ensure that msg.sender is a V2 pair
    // rest of the function goes here!
  }
  function _getAmountsOut (address _router, address[] memory path, uint amountIn) internal view returns(uint[] memory amounts) {
    // IUniswapV2Router02(_router)
    // amounts = router.getAmountsOut(amountIn, path);
  }
  function getAmountsOut (address _router, address[] memory path, uint amountIn) external view returns(uint[] memory amounts) {
    amounts = _getAmountsOut(_router, path, amountIn);
  }
  function _getAmountsIn (address _router, address[] memory path, uint amountOut) internal view returns(uint[] memory amounts) {
    // IUniswapV2Router02(_router)
    // amounts = router.getAmountsIn(amountOut, path);
  }
  function getAmountsIn (address _router, address[] memory path, uint amountOut) external view returns(uint[] memory amounts) {
    amounts = _getAmountsIn(_router, path, amountOut);
  }

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IUniswapV2Callee {
  function uniswapV2Call(
    address sender,
    uint256 amount0,
    uint256 amount1,
    bytes calldata data
  ) external;
}

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

interface IUniswapV2Router02 {
  function factory() external pure returns (address);
  function WETH() external pure returns (address);

  function getAmountsOut(uint amountIn, address[] memory path) external view returns (uint[] memory amounts);
  function getAmountsIn(uint amountOut, address[] memory path) external view returns (uint[] memory amounts);
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

  function swapExactTokensForTokens(
    uint amountIn,
    uint amountOutMin,
    address[] calldata path,
    address to,
    uint deadline
  ) external returns (uint[] memory amounts);
  function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);

  function swapExactTokensForETH(
    uint amountIn,
    uint amountOutMin,
    address[] calldata path,
    address to,
    uint deadline
  )
    external
    returns (uint[] memory amounts);
}

interface IUniswapV2Factory  {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;

}

// SPDX-License-Identifier: FRAKTAL-PROTOCOL
pragma solidity ^0.8.4;

import { IUniswapV2Router02, IUniswapV2Factory, IUniswapV2Pair } from "./shared/interfaces/IUniswapV2.sol";
import { IWETH } from "./shared/interfaces/IWETH.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract Storage {
  uint256 MAX_SUPPLY = 60000000000;

  struct Token {
    mapping(address => mapping(address => uint256)) allowances;
    mapping(address => uint256) balances;
    address[] approvedContracts;
    mapping(address => uint256) approvedContractIndexes;
    // bytes32[1000] emptyMapSlots;
    address contractOwner;
    uint256 totalSupply;
    // uint256 maxSupply;
    bool isPaused;
    address pauser;
    address minter;
    mapping(bytes32 => mapping(address => bool)) roles;
    mapping(string => bytes32) nameRoles;

  }

  struct Platform {
    string name;
    string url;
  }
  
  struct ContractInfo {
    address _addr;
    string name;
    Platform platform;
    ContractType[] _types;
    bool active;
  }
  
  struct ContractType {
    string name;
  }

  struct UniswapV2Exchange {
    IUniswapV2Router02 router;
    IUniswapV2Factory factory;
  }

  struct UniswapV2TokenPair {
    address[] path;
    IUniswapV2Pair pair;
  }

  struct UniswapV2TokenPairData {
    UniswapV2TokenPair pair;
    uint reserve0;
    uint reserve1;
  }

  enum FlashLoanExecutionType {ARBITRAGE, LIQUIDATION, SELF_LIQUIDATION, COLLATERAL_SWAP, DEBT_SWAP, MINT_NFT}

  struct PriceFeed {
    AggregatorV3Interface feed;
    string name;
  }

  struct FlashBotsExecutor {
    address owner;
    address executor;
    
  }

  struct TokenIndex {
    string name;
    address[] tokens;
    address creator;
  }

}

struct AppStore {
  string APP_VERSION;
  Storage.Token t;
  Storage.FlashBotsExecutor fbe;
  Storage.ContractType[] contractTypes;
  mapping(uint => Storage.ContractInfo) platformContracts;
  uint platformContractsCount;
  Storage.Platform[] platforms;
  IWETH WETH;

  address flashLoanOperator;
  Storage.PriceFeed[] priceFeeds;
  Storage.TokenIndex[] tokenIndexes;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8;

import "../interfaces/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

library Utils {
  using SafeMath for uint;
  struct TokenInfo {
    string name;
    string symbol;
    address _address;
    uint decimals;
    uint totalSupply;
  }
  struct Token {
    address _address;
    TokenType _type;
    bool isBlacklisted;
  }


  struct Contract {
    string name;
    address _address;
    string[] categories;
  }

  struct User {
    address _address;
    uint startBlock;
  }
  enum TokenType {GENERIC, LP, CUSTOM}

 // import "@uniswap/lib/contracts/libraries/Babylonian.sol";
  function sqrt(uint y) internal pure returns (uint z) {
    if (y > 3) {
      z = y;
      uint x = y / 2 + 1;
      while (x < z) {
        z = x;
        x = (y / x + x) / 2;
      }
    } else if (y != 0) {
      z = 1;
    }
    // else z = 0 (default value)
  }

  address constant ZERO_ADDRESS = address(0);
  function calculateFee1000 (uint amount, uint pct) internal pure returns(uint) {
    uint fee = ((amount * pct) / (1000 - pct)) + 1;
    return fee;
  }

  function calculateFee10000 (uint amount, uint pct) internal pure returns(uint) {
    uint fee = ((amount * pct) / (10000 - pct)) + 1;
    return fee;
  }

  function feeFromBps (uint amount, uint points) internal pure returns(uint fee) {
    // fee = (amount * points) / 10000;
    fee = amount.mul(points).div(10000);
  }
  function _toLower(string memory str) internal pure returns (string memory) {
    bytes memory bStr = bytes(str);
    bytes memory bLower = new bytes(bStr.length);
    for (uint i = 0; i < bStr.length; i++) {
      // Uppercase character...
      if ((uint8(bStr[i]) >= 65) && (uint8(bStr[i]) <= 90)) {
          // So we add 32 to make it lowercase
        bLower[i] = bytes1(uint8(bStr[i]) + 32);
      } else {
          bLower[i] = bStr[i];
      }
    }
    return string(bLower);
  }
  function _toUpper(string memory str) internal pure returns (string memory) {
    bytes memory bStr = bytes(str);
    bytes memory bLower = new bytes(bStr.length);
    for (uint i = 0; i < bStr.length; i++) {
      // Uppercase character...
      if ((uint8(bStr[i]) >= 97) && (uint8(bStr[i]) <= 112)) {
          // So we add 32 to make it lowercase
        bLower[i] = bytes1(uint8(bStr[i]) - 32);
      } else {
          bLower[i] = bStr[i];
      }
    }
    return string(bLower);
  }

  function _stringCompare (string memory str0, string memory str1) internal pure returns(bool) {
    return keccak256(abi.encodePacked(str0)) == keccak256(abi.encodePacked(str1));
  }
  function _stringConcat (string memory str0, string memory str1) internal pure returns(string memory) {
    return string(abi.encodePacked(str0, str1));

  }
  function _stringToBytes32(string memory source) internal pure returns (bytes32 result) {
    // require(bytes(source).length <= 32); // causes error
    // but string have to be max 32 chars
    // https://ethereum.stackexchange.com/questions/9603/understanding-mload-assembly-function
    // http://solidity.readthedocs.io/en/latest/assembly.html
    assembly {
      result := mload(add(source, 32))
    }
  }//

  function toAsciiString(address x) internal pure returns (string memory) {
    bytes memory s = new bytes(40);
    for (uint i = 0; i < 20; i++) {
        bytes1 b = bytes1(uint8(uint(uint160(x)) / (2**(8*(19 - i)))));
        bytes1 hi = bytes1(uint8(b) / 16);
        bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
        s[2*i] = char(hi);
        s[2*i+1] = char(lo);            
    }
    return string(s);
  }
  function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
    if (_i == 0) {
      return "0";
    }
    uint j = _i;
    uint len;
    while (j != 0) {
      len++;
      j /= 10;
    }
    bytes memory bstr = new bytes(len);
    uint k = len;
    while (_i != 0) {
      k = k-1;
      uint8 temp = (48 + uint8(_i - _i / 10 * 10));
      bytes1 b1 = bytes1(temp);
      bstr[k] = b1;
      _i /= 10;
    }
    return string(bstr);
  }


  function char(bytes1 b) internal pure returns (bytes1 c) {
      if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
      else return bytes1(uint8(b) + 0x57);
  }
  function balanceOf (address _user) internal view returns(uint balance) {
    balance = address(_user).balance;
  }
  function balanceOf (address _user, address _token) internal view returns(uint balance) {
    balance = IERC20(_token).balanceOf(_user);
  }
  function _getTokenInfo (IERC20 _token) internal view returns(TokenInfo memory token) {
    token = TokenInfo(_token.name(), _token.symbol(), address(_token), _token.decimals(), _token.totalSupply());
    return token;
  }
  function getTokenInfo (IERC20[] memory _tokens) internal view returns(TokenInfo[] memory tokens) {
    uint tokensLen = _tokens.length;
    tokens = new TokenInfo[](tokensLen);
    IERC20 token;
    uint i;
    for (i = 0; i < tokensLen; i++) {
      token = _tokens[i];
      tokens[i] = TokenInfo(token.name(), token.symbol(), address(token), token.decimals(), token.totalSupply());
    }
  }
  function getMultiBalances (address[] memory _tokens) internal view returns(TokenInfo[] memory tokens, uint[] memory balances, uint ETH_BALANCE) {
    tokens = new TokenInfo[](_tokens.length);
    balances = new uint[](_tokens.length);
    address _user = msg.sender;
    for(uint i = 0; i < _tokens.length; i++) {
      tokens[i] = _getTokenInfo(IERC20(_tokens[i]));
      balances[i] = balanceOf(_user, _tokens[i]);
    }

    ETH_BALANCE = balanceOf(_user);
  }
  function getMultiBalances (address[] memory _tokens, address _user) internal view returns(
    TokenInfo[] memory tokens,
    uint[] memory balances,
    uint ETH_BALANCE
  ) {

    tokens = new TokenInfo[](_tokens.length);
    balances = new uint[](_tokens.length);

    for(uint i = 0; i < _tokens.length; i++) {
      tokens[i] = _getTokenInfo(IERC20(_tokens[i]));
      balances[i] = balanceOf(_user, _tokens[i]);
    }

    ETH_BALANCE = balanceOf(_user);
  }

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;


/**
 * @dev Interface of the ERC2612 standard as defined in the EIP.
 *
 * Adds the {permit} method, which can be used to change one's
 * {IERC20-allowance} without having to send a transaction, by signing a
 * message. This allows users to spend tokens without having to hold Ether.
 *
 * See https://eips.ethereum.org/EIPS/eip-2612.
 */

interface IERC3156FlashBorrower {

    /**
     * @dev Receive a flash loan.
     * @param initiator The initiator of the loan.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @param fee The additional amount of tokens to repay.
     * @param data Arbitrary data structure, intended to contain user-defined parameters.
     * @return The keccak256 hash of "ERC3156FlashBorrower.onFlashLoan"
     */
    function onFlashLoan(
        address initiator,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external returns (bytes32);
}

interface IERC2612 {
    /**
     * @dev Sets `value` as the allowance of `spender` over `owner`'s tokens,
     * given `owner`'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be `address(0)`.
     * - `spender` cannot be `address(0)`.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use `owner`'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;

    /**
     * @dev Returns the current ERC2612 nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases `owner`'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);
    
    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by EIP712.
     */
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}
// import "./IERC3156FlashBorrower.sol";


interface IERC3156FlashLender {

    /**
     * @dev The amount of currency available to be lended.
     * @param token The loan currency.
     * @return The amount of `token` that can be borrowed.
     */
    function maxFlashLoan(
        address token
    ) external view returns (uint256);

    /**
     * @dev The fee to be charged for a given loan.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @return The amount of `token` to be charged for the loan, on top of the returned principal.
     */
    function flashFee(
        address token,
        uint256 amount
    ) external view returns (uint256);

    /**
     * @dev Initiate a flash loan.
     * @param receiver The receiver of the tokens in the loan, and the receiver of the callback.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @param data Arbitrary data structure, intended to contain user-defined parameters.
     */
    function flashLoan(
        IERC3156FlashBorrower receiver,
        address token,
        uint256 amount,
        bytes calldata data
    ) external returns (bool);
}

// Copyright (C) 2015, 2016, 2017 Dapphub
// Adapted by Ethereum Community 2021

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
// import "./IERC2612.sol";
// import "./IERC3156FlashLender.sol";

/// @dev Wrapped Ether v10 (WETH10) is an Ether (ETH) ERC-20 wrapper. You can `deposit` ETH and obtain a WETH10 balance which can then be operated as an ERC-20 token. You can
/// `withdraw` ETH from WETH10, which will then burn WETH10 token in your wallet. The amount of WETH10 token in any wallet is always identical to the
/// balance of ETH deposited minus the ETH withdrawn with that specific wallet.

interface ITransferReceiver {
    function onTokenTransfer(address, uint, bytes calldata) external returns (bool);
}

interface IApprovalReceiver {
    function onTokenApproval(address, uint, bytes calldata) external returns (bool);
}

interface IWETH10 is IERC20, IERC2612, IERC3156FlashLender {

    /// @dev Returns current amount of flash-minted WETH10 token.
    function flashMinted() external view returns(uint256);

    /// @dev `msg.value` of ETH sent to this contract grants caller account a matching increase in WETH10 token balance.
    /// Emits {Transfer} event to reflect WETH10 token mint of `msg.value` from `address(0)` to caller account.
    function deposit() external payable;

    /// @dev `msg.value` of ETH sent to this contract grants `to` account a matching increase in WETH10 token balance.
    /// Emits {Transfer} event to reflect WETH10 token mint of `msg.value` from `address(0)` to `to` account.
    function depositTo(address to) external payable;

    /// @dev Burn `value` WETH10 token from caller account and withdraw matching ETH to the same.
    /// Emits {Transfer} event to reflect WETH10 token burn of `value` to `address(0)` from caller account. 
    /// Requirements:
    ///   - caller account must have at least `value` balance of WETH10 token.
    function withdraw(uint256 value) external;

    /// @dev Burn `value` WETH10 token from caller account and withdraw matching ETH to account (`to`).
    /// Emits {Transfer} event to reflect WETH10 token burn of `value` to `address(0)` from caller account.
    /// Requirements:
    ///   - caller account must have at least `value` balance of WETH10 token.
    function withdrawTo(address payable to, uint256 value) external;

    /// @dev Burn `value` WETH10 token from account (`from`) and withdraw matching ETH to account (`to`).
    /// Emits {Approval} event to reflect reduced allowance `value` for caller account to spend from account (`from`),
    /// unless allowance is set to `type(uint256).max`
    /// Emits {Transfer} event to reflect WETH10 token burn of `value` to `address(0)` from account (`from`).
    /// Requirements:
    ///   - `from` account must have at least `value` balance of WETH10 token.
    ///   - `from` account must have approved caller to spend at least `value` of WETH10 token, unless `from` and caller are the same account.
    function withdrawFrom(address from, address payable to, uint256 value) external;

    /// @dev `msg.value` of ETH sent to this contract grants `to` account a matching increase in WETH10 token balance,
    /// after which a call is executed to an ERC677-compliant contract with the `data` parameter.
    /// Emits {Transfer} event.
    /// Returns boolean value indicating whether operation succeeded.
    /// For more information on {transferAndCall} format, see https://github.com/ethereum/EIPs/issues/677.
    function depositToAndCall(address to, bytes calldata data) external payable returns (bool);

    /// @dev Sets `value` as allowance of `spender` account over caller account's WETH10 token,
    /// after which a call is executed to an ERC677-compliant contract with the `data` parameter.
    /// Emits {Approval} event.
    /// Returns boolean value indicating whether operation succeeded.
    /// For more information on {approveAndCall} format, see https://github.com/ethereum/EIPs/issues/677.
    function approveAndCall(address spender, uint256 value, bytes calldata data) external returns (bool);

    /// @dev Moves `value` WETH10 token from caller's account to account (`to`), 
    /// after which a call is executed to an ERC677-compliant contract with the `data` parameter.
    /// A transfer to `address(0)` triggers an ETH withdraw matching the sent WETH10 token in favor of caller.
    /// Emits {Transfer} event.
    /// Returns boolean value indicating whether operation succeeded.
    /// Requirements:
    ///   - caller account must have at least `value` WETH10 token.
    /// For more information on {transferAndCall} format, see https://github.com/ethereum/EIPs/issues/677.
    function transferAndCall(address to, uint value, bytes calldata data) external returns (bool);
}

interface IWETH is IWETH10 {}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
pragma solidity 0.8.4;

interface IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address _owner) external view returns (uint256 balance);

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external returns (bool success);

    function transfer(address _to, uint256 _value) external returns (bool success);

    function approve(address _spender, uint256 _value) external returns (bool success);

    function allowance(address _owner, address _spender) external view returns (uint256 remaining);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}