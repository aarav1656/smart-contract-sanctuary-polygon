// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

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
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.4;

import "./PriceConsumerV3.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title OracleSolver
 * @dev Given two tokens it solves address of the chainlink oracle
 * @custom:dev-run-script ./scripts/deploy_with_ethers.ts
 */
contract OracleSolver is Ownable {
  mapping(bytes32 => PriceConsumerV3) private tokensPricer;

  error IdenticalAddress(address);
  error PairExist(address, address, address);
  error ZeroAddress(address);
  error PairNotExist(address, address);

  event PairAdded(address token0, address token1, address pricer);

  function addContract(
    address tokenA,
    address tokenB,
    address solver
  ) public onlyOwner {
    PriceConsumerV3 pc = getContractConsumer(tokenA, tokenB);
    if (address(pc) != address(0)) revert PairExist(tokenA, tokenB, solver);

    bytes32 tokens = generateTokensBytes(tokenA, tokenB);

    tokensPricer[tokens] = new PriceConsumerV3(solver);

    emit PairAdded(tokenA, tokenB, address(tokensPricer[tokens]));
  }

  function getContractConsumer(address tokenA, address tokenB) private view returns (PriceConsumerV3) {
    if (tokenA == tokenB) revert IdenticalAddress(tokenA);

    bytes32 tokens = generateTokensBytes(tokenA, tokenB);
    return tokensPricer[tokens];
  }

  function getPrice(address tokenA, address tokenB) public view returns (int256) {
    PriceConsumerV3 pc = getContractConsumer(tokenA, tokenB);
    if (address(pc) == address(0)) revert PairNotExist(tokenA, tokenB);

    return pc.getLatestPrice();
  }

  function orderAddress(address tokenA, address tokenB) private pure returns (address, address) {
    return tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
  }

  function generateTokensBytes(address tokenA, address tokenB) private pure returns (bytes32) {
    (address token0, address token1) = orderAddress(tokenA, tokenB);
    if (token0 == address(0)) revert ZeroAddress(token0);

    return keccak256(abi.encodePacked(token0, token1));
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract PriceConsumerV3 {

    AggregatorV3Interface internal priceFeed;

    constructor(address solver) {
        priceFeed = AggregatorV3Interface(solver);
    }

    /**
     * Returns the latest price
     */
    function getLatestPrice() public view returns (int) {
        (
            /*uint80 roundID*/,
            int price,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = priceFeed.latestRoundData();
        return price;
    }
}