// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
* @title Interface defining a price-checking oracle
*/
interface IOracle {
    /**
    * @notice Used to check which tokens this oracle is responsible for
    * @return The addresses of the two tokens that this oracle is responsible for
    */
    function tokens() external view returns (address, address);

    /**
    * @notice Used to calculate exchange rates
    * @param token Address of the token to be exchanged // todo double check the token parameter, this interface is ambiguous
    * @param amount The amount of that token to be exchanged
    * @return The resulting amount of tokens
    */
    function getAmountOut(address token, uint256 amount) external returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

/**
* @title Interface defining a contract that should manage multiple exchange-oracles
*/
interface IOracleManager {
    /**
    * @notice Function used to exchange currencies
    * @param srcToken The currency to be exchanged
    * @param dstToken The currency to be exchanged for
    * @param amountIn The amount of currency to be exchanged
    * @return The resulting amount of dstToken
    */
    function getAmountOut(
        address srcToken,
        address dstToken,
        uint256 amountIn
    ) external returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IOracle.sol";
import "../interfaces/IOracleManager.sol";

/**
* @title Implementation of IOracleManager
*/
contract OracleManager is IOracleManager, Ownable {
    /**
    * @notice Event emitted when an oracle is registered
    * @param token0 Address of the first token the oracle is responsible for
    * @param token1 Address of the token the oracle is responsible for
    * @param oracle Address to the oracle
    */
    event OracleRegistered(address indexed token0, address indexed token1, address indexed oracle);
    /**
    * @notice Event emitted when an oracle is removed
    * @param token0 The first token the oracle is responsible for
    * @param token1 The second token the oracle is responsible for
    */
    event OracleRemoved(address indexed token0, address indexed token1);
    /**
    * @notice Event emitted when a stable is registered
    * @param token0 The first token the stable is responsible for
    * @param token1 The second token the stable is responsible for
    */
    event StableRegistered(address indexed token0, address indexed token1);
    /**
    * @notice Event emitted when a stable is removed
    * @param token0 The first token the stable is responsible for
    * @param token1 The second token the stable is responsible for
    */
    event StableRemoved(address indexed token0, address indexed token1);

    mapping(address => mapping(address => address)) public oracles;
    mapping(address => mapping(address => bool)) public stables;

    /**
    * @notice Registers an oracle between the given addresses
    * @param token0 Address of the first token the oracle is responsible for
    * @param token1 Address of the token the oracle is responsible for
    * @param oracle Address to the oracle
    */
    function registerOracle(
        address token0,
        address token1,
        address oracle
    ) external onlyOwner {
        // address(0) => ETH
        require(token0 != token1, "invalid tokens");

        (address tokenA, address tokenB) = IOracle(oracle).tokens();
        if (tokenA == token0) {
            require(tokenB == token1, "token and oracle not match");
        } else if (tokenA == token1) {
            require(tokenB == token0, "token and oracle not match");
        } else {
            revert("token and oracle not match");
        }
        oracles[token0][token1] = oracle;
        oracles[token1][token0] = oracle;

        emit OracleRegistered(token0, token1, oracle);
    }

    /**
    * @notice Removes oracle between tokens
    * @param token0 Address of the first token the oracle is responsible for
    * @param token1 Address of the token the oracle is responsible for
    */
    function removeOracle(address token0, address token1) external onlyOwner {
        require(oracles[token0][token1] != address(0), "no oracle");

        delete oracles[token0][token1];
        delete oracles[token1][token0];

        emit OracleRemoved(token0, token1);
    }

    /// @dev What is this exactly?
    function registerStable(address token0, address token1) external onlyOwner {
        // address(0) => ETH
        require(token0 != token1, "invalid tokens");
        stables[token0][token1] = true;
        stables[token1][token0] = true;

        emit StableRegistered(token0, token1);
    }

    /// @dev What is this exactly?
    function removeStable(address token0, address token1) external onlyOwner {
        require(stables[token0][token1] == true, "no stable");

        delete stables[token0][token1];
        delete stables[token1][token0];

        emit StableRemoved(token0, token1);
    }

    /**
    * @inheritdoc IOracleManager
    */
    function getAmountOut(
        address srcToken,
        address dstToken,
        uint256 amountIn
    ) external override returns (uint256) {
        if (stables[srcToken][dstToken]) {
            return amountIn;
        }
        IOracle oracle = IOracle(oracles[srcToken][dstToken]);

        return oracle.getAmountOut(srcToken, amountIn);
    }
}