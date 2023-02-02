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
pragma solidity ^0.8.9;

/**
 * @title PriceFeeder Interface
 * @author TicketMe
 */
interface IPriceFeeder {
    /**
     * @dev Setter of MATIC/USD price feed address.
     * @param _maticUsdAddress MATIC/USD price feed address.
     */
    function setMaticUsdAddress(address _maticUsdAddress) external;

    /**
     * @dev Setter of JPY/USD price feed address.
     * @param _jpyUsdAddress JPY/USD price feed address.
     */
    function setJpyUsdAddress(address _jpyUsdAddress) external;

    /**
     * @dev Returns the JPY/MATIC price
     * @param _decimals  dicimals
     */
    function getJpyMaticPrice(uint8 _decimals) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./IPriceFeeder.sol";

/**
 * @title PriceFeeder
 * @author TicketMe
 */
contract PriceFeeder is IPriceFeeder, Ownable {
    address public maticUsdAddress;
    address public jpyUsdAddress;

    /**
     * @dev Constractor of PriceFeeder contract.
     * @param _maticUsdAddress Initial setting of MATIC/USD price feed address.
     * @param _jpyUsdAddress Initial setting of JPY/USD price feed address.
     */
    constructor(address _maticUsdAddress, address _jpyUsdAddress) {
        maticUsdAddress = _maticUsdAddress;
        jpyUsdAddress = _jpyUsdAddress;
    }

    /**
     * @dev Setter of MATIC/USD price feed address.
     * @param _maticUsdAddress MATIC/USD price feed address.
     */
    function setMaticUsdAddress(address _maticUsdAddress) public onlyOwner {
        maticUsdAddress = _maticUsdAddress;
    }

    /**
     * @dev Setter of JPY/USD price feed address.
     * @param _jpyUsdAddress JPY/USD price feed address.
     */
    function setJpyUsdAddress(address _jpyUsdAddress) public onlyOwner {
        jpyUsdAddress = _jpyUsdAddress;
    }

    /**
     * @dev Returns the JPY/MATIC price
     * @param _decimals  dicimals
     */
    function getJpyMaticPrice(uint8 _decimals) external view returns (uint256) {
        require(_decimals > uint8(0) && _decimals <= uint8(18), "Invalid _decimals");
        int256 decimals = int256(10**_decimals);
        (, int256 basePrice, , , ) = AggregatorV3Interface(jpyUsdAddress).latestRoundData();
        uint8 baseDecimals = AggregatorV3Interface(jpyUsdAddress).decimals();
        basePrice = scalePrice(basePrice, baseDecimals, _decimals);

        (, int256 quotePrice, , , ) = AggregatorV3Interface(maticUsdAddress).latestRoundData();
        uint8 quoteDecimals = AggregatorV3Interface(maticUsdAddress).decimals();
        quotePrice = scalePrice(quotePrice, quoteDecimals, _decimals);

        return uint256((basePrice * decimals) / quotePrice);
    }

    /**
     * @dev Returns scale price
     * @param _price price
     * @param _priceDecimals base dicimals
     * @param _decimals new dicimals
     */
    function scalePrice(
        int256 _price,
        uint8 _priceDecimals,
        uint8 _decimals
    ) internal pure returns (int256) {
        if (_priceDecimals < _decimals) {
            return _price * int256(10**uint256(_decimals - _priceDecimals));
        } else if (_priceDecimals > _decimals) {
            return _price / int256(10**uint256(_priceDecimals - _decimals));
        }
        return _price;
    }
}